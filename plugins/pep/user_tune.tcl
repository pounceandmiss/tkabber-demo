# user_tune.tcl --
#
#       Implementation of XEP-0118 "User Tune"

package require xmpp::pep

namespace eval tune {
    variable node http://jabber.org/protocol/tune
    variable substatus
    variable tune

    custom::defvar options(auto-subscribe) 0 \
        [::msgcat::mc "Auto-subscribe to other's user tune notifications."] \
        -command [namespace current]::register_in_disco \
        -group PEP -type boolean

    pubsub::register_event_notification_handler $node \
            [namespace current]::process_tune_notification
    hook::add user_tune_notification_hook \
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

proc tune::get {xlib jid what {default ""}} {
    variable tune

    upvar 0 tune($what,$xlib,$jid) v
    if {[info exists v]} {
        return $v
    } else {
        return $default
    }
}

proc tune::get_all {xlib jid arrayVar} {
    variable tune

    upvar 1 $arrayVar a
    foreach tag {artist length source title track uri rating} {
        if {[info exists tune($tag,$xlib,$jid)]} {
            set a($tag) $tune($tag,$xlib,$jid)
        }
    }
}

proc tune::register_in_disco {args} {
    variable options
    variable node

    if {$options(auto-subscribe)} {
       disco::register_feature $node+notify
    } else {
       disco::unregister_feature $node+notify
    }
}

proc tune::add_roster_pep_menu_item {m xlib jid} {
    set rjid [roster::find_jid $xlib $jid]

    if {$rjid == ""} {
        set rjid [::xmpp::jid::removeResource $jid]
    }

    set pm [pep::get_roster_menu_pep_submenu $m $xlib $rjid]

    set mm [menu $pm.tune -tearoff no]
    $pm add cascade -menu $mm \
            -label [::msgcat::mc "User tune"]

    $mm add command \
            -label [::msgcat::mc "Subscribe"] \
            -command [list [namespace current]::subscribe $xlib $rjid]
    $mm add command \
            -label [::msgcat::mc "Unsubscribe"] \
            -command [list [namespace current]::unsubscribe $xlib $rjid]

    hook::run roster_pep_user_tune_menu_hook $mm $xlib $rjid
}

proc tune::subscribe {xlib jid args} {
    variable node
    variable substatus

    set to [::xmpp::jid::removeResource $jid]
    set cmd [linsert $args 0 [namespace current]::subscribe_result $xlib $to]
    ::xmpp::pep::subscribe $xlib $to $node -command $cmd
    set substatus($xlib,$to) sent-subscribe
}

proc tune::unsubscribe {xlib jid args} {
    variable node
    variable substatus

    set to [::xmpp::jid::removeResource $jid]
    set cmd [linsert $args 0 [namespace current]::unsubscribe_result $xlib $to]
    ::xmpp::pep::unsubscribe $xlib $to $node -command $cmd
    set substatus($xlib,$to) sent-unsubscribe
}

# Err may be one of: ok, error and abort
proc tune::subscribe_result {xlib jid res child args} {
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

    if {$cmd ne ""} {
        {*}$cmd $jid $res $child
    }
}

proc tune::unsubscribe_result {xlib jid res child args} {
    variable substatus
    variable tune

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
        forget_user_tune $xlib $jid
    }

    if {$cmd ne ""} {
        {*}$cmd $jid $res $child
    }
}

proc tune::provide_roster_popup_info {var xlib user} {
    variable substatus
    variable tune

    upvar 0 $var info

    set jid [::xmpp::jid::removeResource $user]

    if {[info exists tune(available,$xlib,$jid)]} {
        append info [::msgcat::mc "\n\tTune: %s - %s" \
                                  [get $xlib $jid artist ?] \
                                  [get $xlib $jid title ?]]
    } elseif {[info exists substatus($xlib,$jid)]} {
        append info [::msgcat::mc "\n\tUser tune subscription: %s" \
                                  $substatus($xlib,$jid)]
    } else {
        return
    }

}

proc tune::process_tune_notification {xlib jid items} {
    variable node
    variable tune

    set retract 0
    set parsed  0
    set nelems  0

    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        switch -- $tag {
            retract {
                set retract true
            }
            default {
                foreach itune $subels {
                    ::xmpp::xml::split $itune stag sxmlns sattrs scdata ssubels

                    if {![string equal $stag tune]} continue
                    if {![string equal $sxmlns $node]} continue

                    set parsed true

                    foreach i $ssubels {
                        ::xmpp::xml::split $i sstag ssxmlns ssattrs sscdata sssubels

                        switch -- $sstag {
                            artist - length - source -
                            title - track - uri - rating {
                                set $sstag $sscdata
                                incr nelems
                            }
                        }
                    }
                }
            }
        }
    }

    if {$parsed} {
        if {$nelems > 0} {
            foreach tag {artist length source title track uri rating} {
                if {[info exists $tag]} {
                    set tune($tag,$xlib,$jid) [set $tag]
                } else {
                    catch {unset tune($tag,$xlib,$jid)}
                }
            }
            set tune(available,$xlib,$jid) ""
            hook::run user_tune_notification_hook $xlib $jid published
        } else { # "stop" command
            forget_user_tune $xlib $jid
            hook::run user_tune_notification_hook $xlib $jid stopped
        }
    } elseif {$retract} {
        forget_user_tune $xlib $jid
        hook::run user_tune_notification_hook $xlib $jid retracted
    }
}

proc tune::forget_user_tune {xlib jid} {
    variable tune

    foreach tag {artist length source title track uri rating} {
        catch {unset tune($tag,$xlib,$jid)}
    }
    catch {unset tune(available,$xlib,$jid)}
}

proc tune::notify_via_status_message {xlib jid event} {
    variable tune

    set contact [::roster::itemconfig $xlib $jid -name]
    if {$contact == ""} {
        set contact $jid
    }

    switch -- $event {
        published {
            set msg [::msgcat::mc "%s's tune changed to %s - %s" \
                                  $contact \
                                  [get $xlib $jid artist ?] \
                                  [get $xlib $jid title ?]]
        }
        retracted {
            set msg [::msgcat::mc "%s's tune is unset" $contact]
        }
        stopped {
            set msg [::msgcat::mc "%s's tune has stopped playing" $contact]
        }
    }

    set_status $msg
}

proc tune::publish {xlib args} {
    variable node

    set seen 0
    set stop 0
    set callback ""
    while {[llength $args] > 0} {
        set opt [lpop args]
        switch -- $opt {
            -artist - -title - -track - -length - -source - -uri - -rating {
                set [string trimleft $opt -] [lpop args]
                incr seen
            }
            -stop {
                set stop 1
            }
            -command {
                set callback [lpop args]
            }
            default {
                return -code error "Bad option \"$opt\":\
                    must be one of -artist, -title, -track, -length,\
                    -source, -uri, -rating, -stop or -command"
            }
        }
    }

    if {$stop} {
        if {$seen > 0} {
            return -code error "-stop cannot be combined with options\
                other than -command"
        }
        set content [list]
    } else {
        set content [list]
        foreach tag {artist length source title track uri rating} {
            if {[info exists $tag] && [set $tag] != ""} {
                lappend content [::xmpp::xml::create $tag \
                                            -cdata [set $tag]]
            }
        }
    }

    set args {}
    if {$callback ne ""} {
        lappend args -command $callback
    }

    ::xmpp::pep::publishItem $xlib $node tune \
            -payload [list [::xmpp::xml::create tune \
                                    -xmlns $node \
                                    -subelements $content]] \
            {*}$args
}

proc tune::unpublish {xlib args} {
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

    ::xmpp::pep::deleteItem $xlib $node tune -notify true {*}$args
}

proc tune::on_init {} {
    set m [pep::get_main_menu_pep_submenu]
    set mm [menu $m.tune -tearoff $::ifacetk::options(show_tearoffs)]
    $m add cascade -menu $mm \
           -label [::msgcat::mc "User tune"]
    $mm add command -label [::msgcat::mc "Publish user tune..."] \
            -state disabled \
            -command [namespace current]::show_publish_dialog
    $mm add command -label [::msgcat::mc "Unpublish user tune"] \
            -state disabled \
            -command [namespace current]::show_unpublish_dialog
    $mm add checkbutton -label [::msgcat::mc "Auto-subscribe to other's user tune"] \
            -variable [namespace current]::options(auto-subscribe)
}

proc tune::on_connect_disconnect {args} {
    set mm [pep::get_main_menu_pep_submenu].tune
    set idx [expr {$::ifacetk::options(show_tearoffs) ? 1 : 0}]

    switch -- [llength [connections]] {
        0 {
            $mm entryconfigure $idx -state disabled
            $mm entryconfigure [incr idx] \
                -label [::msgcat::mc "Unpublish user tune"] \
                -state disabled
        }
        1 {
            $mm entryconfigure $idx -state normal
            $mm entryconfigure [incr idx] \
                -label [::msgcat::mc "Unpublish user tune"] \
                -state normal
        }
        default {
            $mm entryconfigure $idx -state normal
            $mm entryconfigure [incr idx] \
                -label [::msgcat::mc "Unpublish user tune..."] \
                -state normal
        }
    }
}

proc tune::show_publish_dialog {} {
    variable tuneartist ""
    variable tunetitle ""
    variable tunetrack ""
    variable tunelength ""
    variable tunesource ""
    variable tuneuri ""
    variable tunerating 1
    variable tunestop 0
    variable myjid

    set w .user_tune
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

    Dialog $w -title [::msgcat::mc "User tune"] \
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
    Label $f.lartist -text [::msgcat::mc "Artist:"]
    Entry $f.artist -textvariable [namespace current]::tuneartist
    Label $f.ltitle -text [::msgcat::mc "Title:"]
    Entry $f.title -textvariable [namespace current]::tunetitle
    Label $f.ltrack -text [::msgcat::mc "Track:"]
    Entry $f.track -textvariable [namespace current]::tunetrack
    Label $f.llength -text [::msgcat::mc "Length:"]
    Entry $f.length -textvariable [namespace current]::tunelength
    Label $f.lsource -text [::msgcat::mc "Source:"]
    Entry $f.source -textvariable [namespace current]::tunesource
    Label $f.luri -text [::msgcat::mc "URI:"]
    Entry $f.uri -textvariable [namespace current]::tuneuri
    Label $f.lrating -text [::msgcat::mc "Rating:"]
    Spinbox $f.rating 1 10 1 [namespace current]::tunerating \
        -validate all -validatecommand [namespace code {validate_rating %P}]
    set tunerating "" ;# otherwise spinbox forces it to be 1
    Checkbutton $f.stop \
        -variable [namespace current]::tunestop \
        -text [::msgcat::mc "Publish \"playback stopped\" instead"] \
        -command [list [namespace current]::adjust_publish_controls $f]

    if {[llength $connjids] > 1} {
        grid $f.ccap   -row 0 -column 0 -sticky e
        grid $f.conn   -row 0 -column 1 -sticky ew
    }
    grid $f.lartist $f.artist
    grid $f.ltitle  $f.title
    grid $f.ltrack  $f.track
    grid $f.llength $f.length
    grid $f.lsource $f.source
    grid $f.luri    $f.uri
    grid $f.lrating $f.rating
    grid $f.stop - -sticky w

    grid $f.lartist $f.ltitle $f.ltrack $f.llength \
        $f.lsource $f.luri $f.lrating -sticky e
    grid $f.artist $f.title $f.track $f.length \
        $f.source $f.uri $f.rating -sticky ew

    grid columnconfigure $f 1 -weight 1

    bind $f <Destroy> [list [namespace current]::cleanup_publish_dialog]
    $w draw
}

proc tune::validate_rating {newvalue} {
    expr {$newvalue == "" ||
        ([string is integer $newvalue] && 1 <= $newvalue && $newvalue <= 10)}
}

proc tune::adjust_publish_controls {f} {
    variable tunestop

    if {$tunestop} {
        set state disabled
    } else {
        set state normal
    }
    foreach control [list \
            $f.lartist $f.artist \
            $f.ltitle  $f.title \
            $f.ltrack  $f.track \
            $f.llength $f.length \
            $f.lsource $f.source \
            $f.luri    $f.uri \
            $f.lrating $f.rating] {
        $control configure -state $state
    }
}

proc tune::do_publish {w} {
    variable tuneartist
    variable tunetitle
    variable tunetrack
    variable tunelength
    variable tunesource
    variable tuneuri
    variable tunerating
    variable tunestop
    variable myjid

    foreach xlib [connections] {
        if {[string equal $myjid [connection_jid $xlib]] || \
                [string equal $myjid [::msgcat::mc "All"]]} {
            if {$tunestop} {
                publish $xlib \
                        -stop \
                        -command [namespace current]::publish_result
            } else {
                publish $xlib \
                        -artist $tuneartist \
                        -title $tunetitle \
                        -track $tunetrack \
                        -length $tunelength \
                        -source $tunesource \
                        -uri $tuneuri \
                        -rating $tunerating \
                        -command [namespace current]::publish_result
            }
            break
        }
    }

    destroy $w
}

proc tune::cleanup_publish_dialog {} {
    variable tuneartist
    variable tunetitle
    variable tunetrack
    variable tunelength
    variable tunesource
    variable tuneuri
    variable tunerating
    variable tunestop
    variable myjid

    foreach v [info vars] { unset $v }
}

# $res is one of: ok, error, abort
proc tune::publish_result {res child} {
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
            -message [::msgcat::mc "User tune publishing failed: %s" $error]
}

proc tune::show_unpublish_dialog {} {
    variable myjid

    set w .user_tune
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

    Dialog $w -title [::msgcat::mc "User tune"] \
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

proc tune::do_unpublish {w} {
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
proc tune::unpublish_result {res child} {
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
            -message [::msgcat::mc "User tune unpublishing failed: %s" $error]
}

proc tune::provide_userinfo {notebook xlib jid editable} {
    variable tune
    variable m2d
    variable ::userinfo::userinfo

    if {$editable} return

    set barejid [::xmpp::jid::removeResource $jid]
    if {![info exists tune(available,$xlib,$barejid)]} return

    foreach tag {artist length source title track uri rating} {
        if {[info exists tune($tag,$xlib,$barejid)]} {
            set userinfo(tune$tag,$jid) $tune($tag,$xlib,$barejid)
        } else {
            set userinfo(tune$tag,$jid) ""
        }
    }

    set f [pep::get_userinfo_dialog_pep_frame $notebook]
    set mf [userinfo::pack_frame $f.tune [::msgcat::mc "User tune"]]

    userinfo::pack_entry $jid $mf 0 tuneartist [::msgcat::mc "Artist:"]
    userinfo::pack_entry $jid $mf 1 tunetitle [::msgcat::mc "Title:"]
    userinfo::pack_entry $jid $mf 2 tunetrack [::msgcat::mc "Track:"]
    userinfo::pack_entry $jid $mf 3 tunelength [::msgcat::mc "Length:"]
    userinfo::pack_entry $jid $mf 4 tunesource [::msgcat::mc "Source:"]
    userinfo::pack_entry $jid $mf 5 tuneuri [::msgcat::mc "URI:"]
    userinfo::pack_entry $jid $mf 6 tunerating [::msgcat::mc "Rating:"]
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
