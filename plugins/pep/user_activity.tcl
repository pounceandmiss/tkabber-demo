# user_activity.tcl --
#
#       Implementation of XEP-0107 "User activity"

package require xmpp::pep

namespace eval activity {
    variable node http://jabber.org/protocol/activity
    variable substatus
    variable activity

    variable options

    custom::defvar options(auto-subscribe) 0 \
        [::msgcat::mc "Auto-subscribe to other's user activity notifications."] \
        -command [namespace current]::register_in_disco \
        -group PEP -type boolean

    variable m2d
    variable d2m

    array set m2d [list \
            doing_chores        [::msgcat::mc "doing chores"] \
            buying_groceries    [::msgcat::mc "buying groceries"] \
            cleaning            [::msgcat::mc "cleaning"] \
            cooking             [::msgcat::mc "cooking"] \
            doing_maintenance   [::msgcat::mc "doing maintenance"] \
            doing_the_dishes    [::msgcat::mc "doing the dishes"] \
            doing_the_laundry   [::msgcat::mc "doing the laundry"] \
            gardening           [::msgcat::mc "gardening"] \
            running_an_errand   [::msgcat::mc "running an errand"] \
            walking_the_dog     [::msgcat::mc "walking the dog"] \
            drinking            [::msgcat::mc "drinking"] \
            having_a_beer       [::msgcat::mc "having a beer"] \
            having_coffee       [::msgcat::mc "having coffee"] \
            having_tea          [::msgcat::mc "having tea"] \
            eating              [::msgcat::mc "eating"] \
            having_a_snack      [::msgcat::mc "having a snack"] \
            having_breakfast    [::msgcat::mc "having breakfast"] \
            having_dinner       [::msgcat::mc "having dinner"] \
            having_lunch        [::msgcat::mc "having lunch"] \
            exercising          [::msgcat::mc "exercising"] \
            cycling             [::msgcat::mc "cycling"] \
            hiking              [::msgcat::mc "hiking"] \
            jogging             [::msgcat::mc "jogging"] \
            playing_sports      [::msgcat::mc "playing sports"] \
            running             [::msgcat::mc "running"] \
            skiing              [::msgcat::mc "skiing"] \
            swimming            [::msgcat::mc "swimming"] \
            working_out         [::msgcat::mc "working out"] \
            grooming            [::msgcat::mc "grooming"] \
            at_the_spa          [::msgcat::mc "at the spa"] \
            brushing_teeth      [::msgcat::mc "brushing teeth"] \
            getting_a_haircut   [::msgcat::mc "getting a haircut"] \
            shaving             [::msgcat::mc "shaving"] \
            taking_a_bath       [::msgcat::mc "taking a bath"] \
            taking_a_shower     [::msgcat::mc "taking a shower"] \
            having_appointment  [::msgcat::mc "having appointment"] \
            inactive            [::msgcat::mc "inactive"] \
            day_off             [::msgcat::mc "day off"] \
            hanging_out         [::msgcat::mc "hanging out"] \
            on_vacation         [::msgcat::mc "on vacation"] \
            scheduled_holiday   [::msgcat::mc "scheduled holiday"] \
            sleeping            [::msgcat::mc "sleeping"] \
            relaxing            [::msgcat::mc "relaxing"] \
            gaming              [::msgcat::mc "gaming"] \
            going_out           [::msgcat::mc "going out"] \
            partying            [::msgcat::mc "partying"] \
            reading             [::msgcat::mc "reading"] \
            rehearsing          [::msgcat::mc "rehearsing"] \
            shopping            [::msgcat::mc "shopping"] \
            socializing         [::msgcat::mc "socializing"] \
            sunbathing          [::msgcat::mc "sunbathing"] \
            watching_tv         [::msgcat::mc "watching tv"] \
            watching_a_movie    [::msgcat::mc "watching a movie"] \
            talking             [::msgcat::mc "talking"] \
            in_real_life        [::msgcat::mc "in real life"] \
            on_the_phone        [::msgcat::mc "on the phone"] \
            on_video_phone      [::msgcat::mc "on video phone"] \
            traveling           [::msgcat::mc "traveling"] \
            commuting           [::msgcat::mc "commuting"] \
            cycling             [::msgcat::mc "cycling"] \
            driving             [::msgcat::mc "driving"] \
            in_a_car            [::msgcat::mc "in a car"] \
            on_a_bus            [::msgcat::mc "on a bus"] \
            on_a_plane          [::msgcat::mc "on a plane"] \
            on_a_train          [::msgcat::mc "on a train"] \
            on_a_trip           [::msgcat::mc "on a trip"] \
            walking             [::msgcat::mc "walking"] \
            working             [::msgcat::mc "working"] \
            coding              [::msgcat::mc "coding"] \
            in_a_meeting        [::msgcat::mc "in a meeting"] \
            studying            [::msgcat::mc "studying"] \
            writing             [::msgcat::mc "writing"] \
    ]

    variable m
    foreach m [array names m2d] {
        set d2m($m2d($m)) $m
    }

    variable subtypes
    array set subtypes [list \
            doing_chores \
                {buying_groceries cleaning cooking doing_maintenance
                doing_the_dishes doing_the_laundry gardening running_an_errand
                walking_the_dog} \
            drinking \
                {having_a_beer having_coffee having_tea} \
            eating \
                {having_a_snack having_breakfast having_dinner having_lunch} \
            exercising \
                {cycling hiking jogging playing_sports running skiing
                swimming working_out} \
            grooming \
                {at_the_spa brushing_teeth getting_a_haircut shaving
                taking_a_bath taking_a_shower} \
            having_appointment {} \
            inactive \
                {day_off hanging_out on_vacation scheduled_holiday sleeping} \
            relaxing \
                {gaming going_out partying reading rehearsing shopping socializing
                sunbathing watching_tv watching_a_movie} \
            talking \
                {in_real_life on_the_phone on_video_phone} \
            traveling \
                {commuting cycling driving in_a_car on_a_bus on_a_plane
                on_a_train on_a_trip walking} \
            working \
                {coding in_a_meeting studying writing} \
    ]

    pubsub::register_event_notification_handler $node \
            [namespace current]::process_activity_notification
    hook::add user_activity_notification_hook \
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

proc activity::register_in_disco {args} {
    variable options
    variable node

    if {$options(auto-subscribe)} {
        disco::register_feature $node+notify
    } else {
        disco::unregister_feature $node+notify
    }
}

proc activity::add_roster_pep_menu_item {m xlib jid} {
    set rjid [roster::find_jid $xlib $jid]

    if {$rjid == ""} {
         set rjid [::xmpp::jid::removeResource $jid]
    }

    set pm [pep::get_roster_menu_pep_submenu $m $xlib $rjid]

    set mm [menu $pm.activity -tearoff no]
    $pm add cascade -menu $mm \
            -label [::msgcat::mc "User activity"]

    $mm add command \
            -label [::msgcat::mc "Subscribe"] \
            -command [list [namespace current]::subscribe $xlib $rjid]
    $mm add command \
            -label [::msgcat::mc "Unsubscribe"] \
            -command [list [namespace current]::unsubscribe $xlib $rjid]

    hook::run roster_pep_user_activity_menu_hook $mm $xlib $rjid
}

proc activity::subscribe {xlib jid args} {
    variable node
    variable substatus

    set to [::xmpp::jid::removeResource $jid]
    set cmd [linsert $args 0 [namespace current]::subscribe_result $xlib $to]
    ::xmpp::pep::subscribe $xlib $to $node -command $cmd
    set substatus($xlib,$to) sent-subscribe
}

proc activity::unsubscribe {xlib jid args} {
    variable node
    variable substatus

    set to [::xmpp::jid::removeResource $jid]
    set cmd [linsert $args 0 [namespace current]::unsubscribe_result $xlib $to]
    ::xmpp::pep::unsubscribe $xlib $to $node -command $cmd
    set substatus($xlib,$to) sent-unsubscribe
}

# Err may be one of: ok, error and abort
proc activity::subscribe_result {xlib jid res child args} {
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

proc activity::unsubscribe_result {xlib jid res child args} {
    variable substatus
    variable activity

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
        array unset activity *,$jid
    }

    if {$cmd != ""} {
        {*}$cmd $jid $res $child
    }
}

proc activity::provide_roster_popup_info {var xlib user} {
    variable substatus
    variable activity
    variable m2d

    upvar 0 $var info

    set jid [::xmpp::jid::removeResource $user]

    if {[info exists activity(activity,$xlib,$jid)]} {
        set m $activity(activity,$xlib,$jid)
        if {[info exists m2d($m)]} {
            set status $m2d($m)
        } else {
            set status $m
            debugmsg pubsub "Failed to found description for user activity \"$m\"\
                             -- discrepancies with XEP-0108?"
        }
        set m $activity(subactivity,$xlib,$jid)
        if {[info exists m2d($m)]} {
            append status [format " (%s)" $m2d($m)]
        } elseif {$m != ""} {
            append status [format " (%s)" $m]
            debugmsg pubsub "Failed to found description for user subactivity \"$m\"\
                             -- discrepancies with XEP-0108?"
        }
        if {[info exists activity(text,$xlib,$jid)] && $activity(text,$xlib,$jid) != ""} {
            append status ": " $activity(text,$xlib,$jid)
        }
        append info [::msgcat::mc "\n\tActivity: %s" $status]
    } elseif {[info exists substatus($xlib,$jid)]} {
        append info [::msgcat::mc "\n\tUser activity subscription: %s" \
                            $substatus($xlib,$jid)]
    } else {
        return
    }

}

proc activity::process_activity_notification {xlib jid items} {
    variable node
    variable activity

    set newactivity ""
    set newsubactivity ""
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
                foreach iactivity $subels {
                    ::xmpp::xml::split $iactivity stag sxmlns sattrs scdata ssubels

                    if {![string equal $stag activity]} continue
                    if {![string equal $sxmlns $node]} continue

                    set parsed true

                    foreach i $ssubels {
                        ::xmpp::xml::split $i sstag ssxmlns ssattrs sscdata sssubels

                        switch -- $sstag {
                            text {
                                set newtext $sscdata
                            }
                            default {
                                set newactivity $sstag

                                foreach i2 $sssubels {
                                    ::xmpp::xml::split $i2 s3tag s3xmlns s3attrs s3cdata s3subels

                                    set newsubactivity $s3tag
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    if {$parsed} {
        set activity(activity,$xlib,$jid) $newactivity
        set activity(subactivity,$xlib,$jid) $newsubactivity
        set activity(text,$xlib,$jid) $newtext

        hook::run user_activity_notification_hook \
                $xlib $jid $newactivity $newsubactivity $newtext
    } elseif {$retract} {
        catch {unset activity(activity,$xlib,$jid)}
        catch {unset activity(subactivity,$xlib,$jid)}
        catch {unset activity(text,$xlib,$jid)}

        hook::run user_activity_notification_hook $xlib $jid "" "" ""
    }
}

proc activity::notify_via_status_message {xlib jid activity subactivity text} {
    variable m2d

    set contact [::roster::itemconfig $xlib $jid -name]
    if {$contact == ""} {
        set contact $jid
    }

    if {$activity == ""} {
        set msg [::msgcat::mc "%s's activity is unset" $contact]
    } elseif {[info exists m2d($activity)]} {
        set msg [::msgcat::mc "%s's activity changed to %s" $contact $m2d($activity)]
        if {$text != ""} {
            append msg ": $text"
        }
    } else {
        set msg [::msgcat::mc "%s's activity changed to %s" $contact $activity]
        if {$text != ""} {
            append msg ": $text"
        }
    }

    set_status $msg
}

proc activity::publish {xlib activity subactivity args} {
    variable node

    set text ""
    set callback ""
    foreach {opt val} $args {
        switch -- $opt {
            -reason  { set text $val }
            -command { set callback $val }
        }
    }

    if {$subactivity eq ""} {
        set content [list [::xmpp::xml::create $activity]]
    } else {
        set content [list [::xmpp::xml::create $activity \
                                -subelement [::xmpp::xml::create \
                                                    $subactivity]]]
    }
    if {$text ne ""} {
        lappend content [::xmpp::xml::create text -cdata $text]
    }

    set args {}
    if {$callback ne ""} {
        lappend args -command $callback
    }

    ::xmpp::pep::publishItem $xlib $node activity \
            -payload [list [::xmpp::xml::create activity \
                                    -xmlns $node \
                                    -subelements $content]] \
            {*}$args
}

proc activity::unpublish {xlib args} {
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

    ::xmpp::pep::deleteItem $xlib $node activity -notify true {*}$args
}

proc activity::on_init {} {
    set m [pep::get_main_menu_pep_submenu]
    set mm [menu $m.activity -tearoff $::ifacetk::options(show_tearoffs)]
    $m add cascade -menu $mm \
           -label [::msgcat::mc "User activity"]
    $mm add command -label [::msgcat::mc "Publish user activity..."] \
            -state disabled \
            -command [namespace current]::show_publish_dialog
    $mm add command -label [::msgcat::mc "Unpublish user activity"] \
            -state disabled \
            -command [namespace current]::show_unpublish_dialog
    $mm add checkbutton -label [::msgcat::mc "Auto-subscribe to other's user activity"] \
            -variable [namespace current]::options(auto-subscribe)
}

proc activity::on_connect_disconnect {args} {
    set mm [pep::get_main_menu_pep_submenu].activity
    set idx [expr {$::ifacetk::options(show_tearoffs) ? 1 : 0}]

    switch -- [llength [connections]] {
        0 {
            $mm entryconfigure $idx -state disabled
            $mm entryconfigure [incr idx] \
                -label [::msgcat::mc "Unpublish user activity"] \
                -state disabled
        }
        1 {
            $mm entryconfigure $idx -state normal
            $mm entryconfigure [incr idx] \
                -label [::msgcat::mc "Unpublish user activity"] \
                -state normal
        }
        default {
            $mm entryconfigure $idx -state normal
            $mm entryconfigure [incr idx] \
                -label [::msgcat::mc "Unpublish user activity..."] \
                -state normal
        }
    }
}

proc activity::show_publish_dialog {} {
    variable d2m
    variable activityvalue ""
    variable subactivityvalue ""
    variable activityreason ""
    variable myjid

    set w .user_activity
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

    Dialog $w -title [::msgcat::mc "User activity"] \
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
    Label $f.acap -text [::msgcat::mc "Activity:"]
    Combobox $f.activity -editable false \
            -values [lsort [major_activities]] \
            -textvariable [namespace current]::activityvalue \
            -modifycmd [list [namespace current]::update_combobox $f.sactivity]
    Label $f.sacap -text [::msgcat::mc "Subactivity:"]
    Combobox $f.sactivity -editable false \
            -values {} \
            -textvariable [namespace current]::subactivityvalue
    Label $f.rcap -text [::msgcat::mc "Reason:"]
    Entry $f.reason -textvariable [namespace current]::activityreason

    update_combobox $f.sactivity

    if {[llength $connjids] > 1} {
        grid $f.ccap   -row 0 -column 0 -sticky e
        grid $f.conn   -row 0 -column 1 -sticky ew
    }
    grid $f.acap      -row 1 -column 0 -sticky e
    grid $f.activity  -row 1 -column 1 -sticky ew
    grid $f.sacap     -row 2 -column 0 -sticky e
    grid $f.sactivity -row 2 -column 1 -sticky ew
    grid $f.rcap      -row 3 -column 0 -sticky e
    grid $f.reason    -row 3 -column 1 -sticky ew

    grid columnconfigure $f 1 -weight 1

    $w draw
}

proc activity::major_activities {} {
    variable m2d
    variable subtypes

    set res {}
    foreach activity [array names subtypes] {
        lappend res $m2d($activity)
    }
    return $res
}

proc activity::update_combobox {combo} {
    variable m2d
    variable d2m
    variable subtypes
    variable activityvalue
    variable subactivityvalue

    set subactivityvalue ""

    set res [list ""]
    if {[info exists d2m($activityvalue)] && \
            [info exists subtypes($d2m($activityvalue))]} {
        foreach activity $subtypes($d2m($activityvalue)) {
            lappend res $m2d($activity)
        }
    }
    $combo configure -values $res
}

proc activity::do_publish {w} {
    variable d2m
    variable activityvalue
    variable subactivityvalue
    variable activityreason
    variable myjid

    if {$activityvalue == ""} {
        NonmodalMessageDlg [epath] \
                -aspect 50000 \
                -icon error \
                -title [::msgcat::mc "Error"] \
                -message [::msgcat::mc "Cannot publish empty activity"]
        return
    }

    if {$subactivityvalue == ""} {
        set sub ""
    } else {
        set sub $d2m($subactivityvalue)
    }

    foreach xlib [connections] {
        if {[string equal $myjid [connection_jid $xlib]] || \
                [string equal $myjid [::msgcat::mc "All"]]} {
            publish $xlib $d2m($activityvalue) $sub \
                    -reason $activityreason \
                    -command [namespace current]::publish_result
            break
        }
    }

    unset activityvalue subactivityvalue activityreason myjid
    destroy $w
}

# $res is one of: ok, error, abort
proc activity::publish_result {res child} {
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
            -message [::msgcat::mc "User activity publishing failed: %s" $error]
}

proc activity::show_unpublish_dialog {} {
    variable myjid

    set w .user_activity
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

    Dialog $w -title [::msgcat::mc "User activity"] \
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

proc activity::do_unpublish {w} {
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
proc activity::unpublish_result {res child} {
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
            -message [::msgcat::mc "User activity unpublishing failed: %s" $error]
}

proc activity::provide_userinfo {notebook xlib jid editable} {
    variable activity
    variable m2d
    variable ::userinfo::userinfo

    if {$editable} return

    set barejid [::xmpp::jid::removeResource $jid]
    if {![info exists activity(activity,$xlib,$barejid)]} return
    if {[string equal $activity(activity,$xlib,$barejid) ""]} return

    if {[info exists m2d($activity(activity,$xlib,$barejid))]} {
        set userinfo(activity,$jid) $m2d($activity(activity,$xlib,$barejid))
    } else {
        set userinfo(activity,$jid) $activity(activity,$xlib,$barejid)
    }

    if {[info exists m2d($activity(subactivity,$xlib,$barejid))]} {
        set userinfo(subactivity,$jid) $m2d($activity(subactivity,$xlib,$barejid))
    } else {
        set userinfo(subactivity,$jid) $activity(subactivity,$xlib,$barejid)
    }

    if {[info exists activity(text,$xlib,$barejid)]} {
        set userinfo(activityreason,$jid) $activity(text,$xlib,$barejid)
    } else {
        set userinfo(activityreason,$jid) ""
    }

    set f [pep::get_userinfo_dialog_pep_frame $notebook]
    set mf [userinfo::pack_frame $f.activity [::msgcat::mc "User activity"]]

    userinfo::pack_entry $jid $mf 0 activity [::msgcat::mc "Activity"]:
    userinfo::pack_entry $jid $mf 1 subactivity [::msgcat::mc "Subactivity"]:
    userinfo::pack_entry $jid $mf 2 activityreason [::msgcat::mc "Reason"]:
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
