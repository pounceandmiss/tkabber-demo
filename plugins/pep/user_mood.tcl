# user_mood.tcl --
#
#       Implementation of XEP-0107 "User mood"
#       Based on Version 1.1 (2007-06-04).

package require xmpp::pep

namespace eval mood {
    variable node http://jabber.org/protocol/mood
    variable substatus
    variable mood

    variable options

    custom::defvar options(auto-subscribe) 0 \
        [::msgcat::mc "Auto-subscribe to other's user mood notifications."] \
        -command [namespace current]::register_in_disco \
        -group PEP -type boolean

    variable m2d
    variable d2m

    array set m2d [list \
        afraid       [::msgcat::mc "afraid"] \
        amazed       [::msgcat::mc "amazed"] \
        angry        [::msgcat::mc "angry"] \
        annoyed      [::msgcat::mc "annoyed"] \
        anxious      [::msgcat::mc "anxious"] \
        aroused      [::msgcat::mc "aroused"] \
        ashamed      [::msgcat::mc "ashamed"] \
        bored        [::msgcat::mc "bored"] \
        brave        [::msgcat::mc "brave"] \
        calm         [::msgcat::mc "calm"] \
        cold         [::msgcat::mc "cold"] \
        confused     [::msgcat::mc "confused"] \
        contented    [::msgcat::mc "contented"] \
        cranky       [::msgcat::mc "cranky"] \
        curious      [::msgcat::mc "curious"] \
        depressed    [::msgcat::mc "depressed"] \
        disappointed [::msgcat::mc "disappointed"] \
        disgusted    [::msgcat::mc "disgusted"] \
        distracted   [::msgcat::mc "distracted"] \
        embarrassed  [::msgcat::mc "embarrassed"] \
        excited      [::msgcat::mc "excited"] \
        flirtatious  [::msgcat::mc "flirtatious"] \
        frustrated   [::msgcat::mc "frustrated"] \
        grumpy       [::msgcat::mc "grumpy"] \
        guilty       [::msgcat::mc "guilty"] \
        happy        [::msgcat::mc "happy"] \
        hot          [::msgcat::mc "hot"] \
        humbled      [::msgcat::mc "humbled"] \
        humiliated   [::msgcat::mc "humiliated"] \
        hungry       [::msgcat::mc "hungry"] \
        hurt         [::msgcat::mc "hurt"] \
        impressed    [::msgcat::mc "impressed"] \
        in_awe       [::msgcat::mc "in_awe"] \
        in_love      [::msgcat::mc "in_love"] \
        indignant    [::msgcat::mc "indignant"] \
        interested   [::msgcat::mc "interested"] \
        intoxicated  [::msgcat::mc "intoxicated"] \
        invincible   [::msgcat::mc "invincible"] \
        jealous      [::msgcat::mc "jealous"] \
        lonely       [::msgcat::mc "lonely"] \
        mean         [::msgcat::mc "mean"] \
        moody        [::msgcat::mc "moody"] \
        nervous      [::msgcat::mc "nervous"] \
        neutral      [::msgcat::mc "neutral"] \
        offended     [::msgcat::mc "offended"] \
        playful      [::msgcat::mc "playful"] \
        proud        [::msgcat::mc "proud"] \
        relieved     [::msgcat::mc "relieved"] \
        remorseful   [::msgcat::mc "remorseful"] \
        restless     [::msgcat::mc "restless"] \
        sad          [::msgcat::mc "sad"] \
        sarcastic    [::msgcat::mc "sarcastic"] \
        serious      [::msgcat::mc "serious"] \
        shocked      [::msgcat::mc "shocked"] \
        shy          [::msgcat::mc "shy"] \
        sick         [::msgcat::mc "sick"] \
        sleepy       [::msgcat::mc "sleepy"] \
        stressed     [::msgcat::mc "stressed"] \
        surprised    [::msgcat::mc "surprised"] \
        thirsty      [::msgcat::mc "thirsty"] \
        worried      [::msgcat::mc "worried"] \
    ]

    variable m
    foreach m [array names m2d] {
        set d2m($m2d($m)) $m
    }

    pubsub::register_event_notification_handler $node \
            [namespace current]::process_mood_notification
    hook::add user_mood_notification_hook \
            [namespace current]::notify_via_status_message

    hook::add finload_hook \
            [namespace current]::on_init 60
    hook::add connected_hook \
            [namespace current]::on_connect_disconnect
    hook::add disconnected_hook \
            [namespace current]::on_connect_disconnect
    hook::add roster_jid_popup_menu_hook \
            [namespace current]::add_roster_pep_menu_item
    hook::add roster_user_popup_info_hook \
            [namespace current]::provide_roster_popup_info
    hook::add userinfo_hook \
            [namespace current]::provide_userinfo

    disco::register_feature $node
}

proc mood::register_in_disco {args} {
    variable options
    variable node

    if {$options(auto-subscribe)} {
        disco::register_feature $node+notify
    } else {
        disco::unregister_feature $node+notify
    }
}

proc mood::add_roster_pep_menu_item {m xlib jid} {
    set rjid [roster::find_jid $xlib $jid]

    if {$rjid == ""} {
         set rjid [::xmpp::jid::removeResource $jid]
    }

    set pm [pep::get_roster_menu_pep_submenu $m $xlib $rjid]

    set mm [menu $pm.mood -tearoff no]
    $pm add cascade -menu $mm \
            -label [::msgcat::mc "User mood"]

    $mm add command \
            -label [::msgcat::mc "Subscribe"] \
            -command [list [namespace current]::subscribe $xlib $rjid]
    $mm add command \
            -label [::msgcat::mc "Unsubscribe"] \
            -command [list [namespace current]::unsubscribe $xlib $rjid]

    hook::run roster_pep_user_mood_menu_hook $mm $xlib $rjid
}

proc mood::subscribe {xlib jid args} {
    variable node
    variable substatus

    set to [::xmpp::jid::removeResource $jid]
    set cmd [linsert $args 0 [namespace current]::subscribe_result $xlib $to]
    ::xmpp::pep::subscribe $xlib $to $node -command $cmd
    set substatus($xlib,$to) sent-subscribe
}

proc mood::unsubscribe {xlib jid args} {
    variable node
    variable substatus

    set to [::xmpp::jid::removeResource $jid]
    set cmd [linsert $args 0 [namespace current]::unsubscribe_result $xlib $to]
    ::xmpp::pep::unsubscribe $xlib $to $node -command $cmd
    set substatus($xlib,$to) sent-unsubscribe
}

# Err may be one of: ok, error and abort
proc mood::subscribe_result {xlib jid res child args} {
    variable substatus

    set cmd ""
    foreach {opt val} $args {
        switch -- $opt {
            -command {
                set cmd $val
            }
            default {
                return -code error "unknown option: $opt"
            }
        }
    }

    switch -- $res {
        ok {
            set substatus($xlib,$jid) from
        }
        error {
            set substatus($xlib,$jid) error
        }
        default {
            return
        }
    }

    if {$cmd != ""} {
        {*}$cmd $jid $res $child
    }
}

proc mood::unsubscribe_result {xlib jid res child args} {
    variable substatus
    variable mood

    set cmd ""
    foreach {opt val} $args {
        switch -- $opt {
            -command {
                set cmd $val
            }
            default {
                return -code error "unknown option: $opt"
            }
        }
    }

    if {[string equal $res ok]} {
        set substatus($xlib,$jid) none
        catch {unset mood(mood,$xlib,$jid)}
        catch {unset mood(text,$xlib,$jid)}
    }

    if {$cmd != ""} {
        {*}$cmd $jid $res $child
    }
}

proc mood::provide_roster_popup_info {var xlib user} {
    variable substatus
    variable mood
    variable m2d

    upvar 0 $var info

    set jid [::xmpp::jid::removeResource $user]

    if {[info exists mood(mood,$xlib,$jid)]} {
        set m $mood(mood,$xlib,$jid)
        if {[info exists m2d($m)]} {
            set status $m2d($m)
        } else {
            set status $m
            debugmsg pubsub "Failed to found description for user mood \"$m\"\
                             -- discrepancies with XEP-0107?"
        }
        if {[info exists mood(text,$xlib,$jid)] && $mood(text,$xlib,$jid) != ""} {
            append status ": " $mood(text,$xlib,$jid)
        }
        append info [::msgcat::mc "\n\tMood: %s" $status]
    } elseif {[info exists substatus($xlib,$jid)]} {
        append info [::msgcat::mc "\n\tUser mood subscription: %s" \
                            $substatus($xlib,$jid)]
    } else {
        return
    }

}

proc mood::process_mood_notification {xlib jid items} {
    variable node
    variable mood

    set newmood ""
    set newtext ""
    set retract false
    set parsed  false

    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        switch -- $tag {
            retract {
                set retract true
            }
            default {
                foreach imood $subels {
                    ::xmpp::xml::split $imood stag sxmlns sattrs scdata ssubels

                    if {![string equal $stag mood]} continue
                    if {![string equal $sxmlns $node]} continue

                    set parsed true

                    foreach i $ssubels {
                        ::xmpp::xml::split $i sstag ssxmlns ssattrs sscdata sssubels

                        switch -- $sstag {
                            text {
                                set newtext $sscdata
                            }
                            default {
                                set newmood $sstag
                            }
                        }
                    }
                }
            }
        }
    }

    if {$parsed} {
        set mood(mood,$xlib,$jid) $newmood
        set mood(text,$xlib,$jid) $newtext

        hook::run user_mood_notification_hook $xlib $jid $newmood $newtext
    } elseif {$retract} {
        catch {unset mood(mood,$xlib,$jid)}
        catch {unset mood(text,$xlib,$jid)}

        hook::run user_mood_notification_hook $xlib $jid "" ""
    }
}

proc mood::notify_via_status_message {xlib jid mood text} {
    variable m2d

    set contact [::roster::itemconfig $xlib $jid -name]
    if {$contact == ""} {
        set contact $jid
    }

    if {$mood == ""} {
        set msg [::msgcat::mc "%s's mood is unset" $contact]
    } elseif {[info exists m2d($mood)]} {
        set msg [::msgcat::mc "%s's mood changed to %s" $contact $m2d($mood)]
        if {$text != ""} {
            append msg ": $text"
        }
    } else {
        set msg [::msgcat::mc "%s's mood changed to %s" $contact $mood]
        if {$text != ""} {
            append msg ": $text"
        }
    }

    set_status $msg
}

proc mood::publish {xlib mood args} {
    variable node

    set text ""
    set callback ""
    foreach {opt val} $args {
        switch -- $opt {
            -reason  { set text $val }
            -command { set callback $val }
        }
    }

    set content [list [::xmpp::xml::create $mood]]
    if {$text ne ""} {
        lappend content [::xmpp::xml::create text -cdata $text]
    }

    set args {}
    if {$callback ne ""} {
        lappend args -command $callback
    }

    ::xmpp::pep::publishItem $xlib $node mood \
            -payload [list [::xmpp::xml::create mood \
                                    -xmlns $node \
                                    -subelements $content]] \
            {*}$args
}

proc mood::unpublish {xlib args} {
    variable node

    set callback ""
    foreach {opt val} $args {
        switch -- $opt {
            -command { set callback $val }
        }
    }

    set args {}
    if {$callback ne ""} {
        lappend args -command $callback
    }

    ::xmpp::pep::deleteItem $xlib $node mood -notify true {*}$args
}

proc mood::on_init {} {
    set m [pep::get_main_menu_pep_submenu]
    set mm [menu $m.mood -tearoff $::ifacetk::options(show_tearoffs)]
    $m add cascade -menu $mm \
           -label [::msgcat::mc "User mood"]
    $mm add command -label [::msgcat::mc "Publish user mood..."] \
            -state disabled \
            -command [namespace current]::show_publish_dialog
    $mm add command -label [::msgcat::mc "Unpublish user mood"] \
            -state disabled \
            -command [namespace current]::show_unpublish_dialog
    $mm add checkbutton -label [::msgcat::mc "Auto-subscribe to other's user mood"] \
            -variable [namespace current]::options(auto-subscribe)
}

proc mood::on_connect_disconnect {args} {
    set mm [pep::get_main_menu_pep_submenu].mood
    set idx [expr {$::ifacetk::options(show_tearoffs) ? 1 : 0}]

    switch -- [llength [connections]] {
        0 {
            $mm entryconfigure $idx -state disabled
            $mm entryconfigure [incr idx] \
                -label [::msgcat::mc "Unpublish user mood"] \
                -state disabled
        }
        1 {
            $mm entryconfigure $idx -state normal
            $mm entryconfigure [incr idx] \
                -label [::msgcat::mc "Unpublish user mood"] \
                -state normal
        }
        default {
            $mm entryconfigure $idx -state normal
            $mm entryconfigure [incr idx] \
                -label [::msgcat::mc "Unpublish user mood..."] \
                -state normal
        }
    }
}

proc mood::show_publish_dialog {} {
    variable d2m
    variable moodvalue ""
    variable moodreason ""
    variable myjid

    set w .user_mood
    if {[winfo exists $w]} {
        destroy $w
    }

    set xlibs [connections]
    if {[llength $xlibs] == 0} {
        NonmodalMessageDlg [epath] \
                -aspect 50000 \
                -icon error \
                -title [::msgcat::mc "Error"] \
                -message [::msgcat::mc "Publishing is only possible\
                                        while being online"]
        return
    }

    Dialog $w -title [::msgcat::mc "User mood"] \
            -modal none -anchor e -default 0 -cancel 1 -parent .
    $w add -text [::msgcat::mc "Publish"] \
           -command [list [namespace current]::do_publish $w]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set f [$w getframe]

    set connjids [list [::msgcat::mc "All"]]
    foreach xlib $xlibs {
        lappend connjids [connection_jid $xlib]
    }
    set myjid [lindex $connjids 0]

    Label $f.ccap -text [::msgcat::mc "Use connection:"]
    Combobox $f.conn -editable false \
            -values $connjids \
            -textvariable [namespace current]::myjid
    Label $f.mcap -text [::msgcat::mc "Mood:"]
    Combobox $f.mood -editable false \
            -values [lsort [array names d2m]] \
            -textvariable [namespace current]::moodvalue
    Label $f.rcap -text [::msgcat::mc "Reason:"]
    Entry $f.reason -textvariable [namespace current]::moodreason

    if {[llength $connjids] > 1} {
        grid $f.ccap   -row 0 -column 0 -sticky e
        grid $f.conn   -row 0 -column 1 -sticky ew
    }
    grid $f.mcap   -row 1 -column 0 -sticky e
    grid $f.mood   -row 1 -column 1 -sticky ew
    grid $f.rcap   -row 2 -column 0 -sticky e
    grid $f.reason -row 2 -column 1 -sticky ew

    grid columnconfigure $f 1 -weight 1

    $w draw
}

proc mood::do_publish {w} {
    variable d2m
    variable moodvalue
    variable moodreason
    variable myjid

    if {$moodvalue == ""} {
        NonmodalMessageDlg [epath] \
                -aspect 50000 \
                -icon error \
                -title [::msgcat::mc "Error"] \
                -message [::msgcat::mc "Cannot publish empty mood"]
        return
    }

    foreach xlib [connections] {
        if {[string equal $myjid [connection_jid $xlib]] || \
                [string equal $myjid [::msgcat::mc "All"]]} {
            publish $xlib $d2m($moodvalue) \
                    -reason $moodreason \
                    -command [namespace current]::publish_result
            break
        }
    }

    unset moodvalue moodreason myjid
    destroy $w
}

# $res is one of: ok, error, abort
proc mood::publish_result {res child} {
    switch -- $res {
        error {
            set error [error_to_string $child]
        }
        default {
            return
        }
    }

    NonmodalMessageDlg [epath] \
            -aspect 50000 \
            -icon error \
            -title [::msgcat::mc "Error"] \
            -message [::msgcat::mc "User mood publishing failed: %s" $error]
}

proc mood::show_unpublish_dialog {} {
    variable myjid

    set w .user_mood
    if {[winfo exists $w]} {
        destroy $w
    }

    set xlibs [connections]
    if {[llength $xlibs] == 0} {
        NonmodalMessageDlg [epath] \
                -aspect 50000 \
                -icon error \
                -title [::msgcat::mc "Error"] \
                -message [::msgcat::mc "Unpublishing is only possible\
                                        while being online"]
        return
    }

    Dialog $w -title [::msgcat::mc "User mood"] \
            -modal none -anchor e -default 0 -cancel 1 -parent .
    $w add -text [::msgcat::mc "Unpublish"] \
           -command [list [namespace current]::do_unpublish $w]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set f [$w getframe]

    set connjids [list [::msgcat::mc "All"]]
    foreach xlib $xlibs {
        lappend connjids [connection_jid $xlib]
    }
    set myjid [lindex $connjids 0]

    Label $f.ccap -text [::msgcat::mc "Use connection:"]
    Combobox $f.conn -editable false \
            -values $connjids \
            -textvariable [namespace current]::myjid

    if {[llength $connjids] > 1} {
        grid $f.ccap   -row 0 -column 0 -sticky e
        grid $f.conn   -row 0 -column 1 -sticky ew
    }

    grid columnconfigure $f 1 -weight 1

    if {[llength $xlibs] == 1} {
        do_unpublish $w
    } else {
        $w draw
    }
}

proc mood::do_unpublish {w} {
    variable myjid

    foreach xlib [connections] {
        if {[string equal $myjid [connection_jid $xlib]] || \
                [string equal $myjid [::msgcat::mc "All"]]} {
            unpublish $xlib \
                    -command [namespace current]::unpublish_result
            break
        }
    }

    unset myjid
    destroy $w
}

# $res is one of: ok, error, abort
proc mood::unpublish_result {res child} {
    switch -- $res {
        error {
            if {[lindex [error_type_condition $child] 1] == "item-not-found"} {
                return
            }
            set error [error_to_string $child]
        }
        default {
            return
        }
    }

    NonmodalMessageDlg [epath] \
            -aspect 50000 \
            -icon error \
            -title [::msgcat::mc "Error"] \
            -message [::msgcat::mc "User mood unpublishing failed: %s" $error]
}

proc mood::provide_userinfo {notebook xlib jid editable} {
    variable mood
    variable m2d
    variable ::userinfo::userinfo

    if {$editable} return

    set barejid [::xmpp::jid::removeResource $jid]
    if {![info exists mood(mood,$xlib,$barejid)]} return
    if {[string equal $mood(mood,$xlib,$barejid) ""]} return

    if {[info exists m2d($mood(mood,$xlib,$barejid))]} {
        set userinfo(mood,$jid) $m2d($mood(mood,$xlib,$barejid))
    } else {
        set userinfo(mood,$jid) $mood(mood,$xlib,$barejid)
    }
    if {[info exists mood(text,$xlib,$barejid)]} {
        set userinfo(moodreason,$jid) $mood(text,$xlib,$barejid)
    } else {
        set userinfo(moodreason,$jid) ""
    }

    set f [pep::get_userinfo_dialog_pep_frame $notebook]
    set mf [userinfo::pack_frame $f.mood [::msgcat::mc "User mood"]]

    userinfo::pack_entry $jid $mf 0 mood [::msgcat::mc "Mood"]:
    userinfo::pack_entry $jid $mf 1 moodreason [::msgcat::mc "Reason"]:
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
