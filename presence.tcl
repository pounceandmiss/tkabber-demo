# presence.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements
#       general routines for working with presence (receiving presence,
#       sending presence).

array set long_statusdesc [list \
    available   [::msgcat::mc "is available"] \
    chat        [::msgcat::mc "is free to chat"] \
    away        [::msgcat::mc "is away"] \
    xa          [::msgcat::mc "is extended away"] \
    dnd         [::msgcat::mc "doesn't want to be disturbed"] \
    invisible   [::msgcat::mc "is invisible"] \
    unavailable [::msgcat::mc "is unavailable"]]

proc get_long_status_desc {status} {
    set ::long_statusdesc($status)
}

###############################################################################
#
# client:presence --
#
#   A precence callback which is called from the tclxmpp presence parsing
#   routine
#
#   xlib    XMPP token
#   from    NORMALIZED JID of the sender
#   type    Type of the presence
#   x       Attachments
#   args    -status, -priority, -show, -lang

proc client:presence {xlib from type x args} {
    global presence
    global processed_presence

    debugmsg presence "PRESENCE: $from; $type; $x; $args"

    switch -- $type {
        error -
        unavailable {
            catch { unset presence(type,$xlib,$from) }
            catch { unset presence(status,$xlib,$from) }
            catch { unset presence(priority,$xlib,$from) }
            catch { unset presence(show,$xlib,$from) }
            catch { unset presence(x,$xlib,$from) }
            catch { unset presence(error,$xlib,$from) }

            set user [::xmpp::jid::removeResource $from]
            if {[info exists presence(user_jids,$xlib,$user)]} {
                set idx [lsearch -exact $presence(user_jids,$xlib,$user) $from]
                set presence(user_jids,$xlib,$user) \
                    [lreplace $presence(user_jids,$xlib,$user) $idx $idx]
            }
            cache_preferred_jid_on_unavailable $xlib $from $user
            cache_user_status $xlib $user

            foreach {attr val} $args {
                switch -- $attr {
                    -status {
                        set presence(status,$xlib,$from) $val
                        if {[get_user_status $xlib $user] == "unavailable"} {
                            set presence(status,$xlib,$user) $val
                        }
                    }
                    -error {
                        set presence(error,$xlib,$from) $val
                    }
                    -lang {
                        set presence(lang,$xlib,$from) $val
                    }
                }
            }

            debugmsg presence "$xlib $from unavailable"
        }
        subscribe {}
        subscribed {}
        unsubscribe {}
        unsubscribed {}
        probe {}
        default {
            set type available
            set presence(type,$xlib,$from)     available
            set presence(status,$xlib,$from)   ""
            set presence(priority,$xlib,$from) 0
            set presence(show,$xlib,$from)     available
            set presence(x,$xlib,$from)        $x
            catch { unset presence(error,$xlib,$from) }

            foreach {attr val} $args {
                switch -- $attr {
                    -status   {set presence(status,$xlib,$from)   $val}
                    -priority {set presence(priority,$xlib,$from) $val}
                    -show     {set presence(show,$xlib,$from)     $val}
                    -lang     {set presence(lang,$xlib,$from)     $val}
                }
            }

            set presence(show,$xlib,$from) \
                [normalize_show $presence(show,$xlib,$from)]

            set user [::xmpp::jid::removeResource $from]
            if {![info exists presence(user_jids,$xlib,$user)] || \
                    $from ni $presence(user_jids,$xlib,$user)} {
                lappend presence(user_jids,$xlib,$user) $from
            }

            cache_preferred_jid_on_available $xlib $from $user
            cache_user_status $xlib $user
        }
    }

    hook::run client_presence_hook $xlib $from $type $x {*}$args
}

###############################################################################

proc get_jids_of_user {xlib user} {
    global presence

    if {[info exists presence(user_jids,$xlib,$user)]} {
        return $presence(user_jids,$xlib,$user)
    } elseif {[::xmpp::jid::resource $user] ne ""} {
        if {[info exists presence(type,$xlib,$user)]} {
            return [list $user]
        }
    }
    return {}
}

proc get_jid_of_user {xlib user} {
    global presence

    if {[info exists presence(preferred_jid,$xlib,$user)]} {
        return $presence(preferred_jid,$xlib,$user)
    } else {
        return $user
    }
}

proc cache_preferred_jid_on_available {xlib jid user} {
    global presence

    set pri $presence(priority,$xlib,$jid)

    if {![info exists presence(maxpriority,$xlib,$user)]} {
        cache_preferred_jid $xlib $user
        return
    } elseif {$presence(preferred_jid,$xlib,$user) == $jid && \
              $pri < $presence(maxpriority,$xlib,$user)} {
        unset presence(preferred_jid,$xlib,$user)
        unset presence(maxpriority,$xlib,$user)
        cache_preferred_jid $xlib $user
        return
    } else {
        set maxpri $presence(maxpriority,$xlib,$user)
        if {$pri > $maxpri} {
            set presence(maxpriority,$xlib,$user) $pri
            set presence(preferred_jid,$xlib,$user) $jid
        }
    }
}

proc cache_preferred_jid_on_unavailable {xlib jid user} {
    global presence

    if {![info exists presence(maxpriority,$xlib,$user)]} {
        cache_preferred_jid $xlib $user
        return
    }

    if {$presence(preferred_jid,$xlib,$user) == $jid} {
        unset presence(preferred_jid,$xlib,$user)
        unset presence(maxpriority,$xlib,$user)
        cache_preferred_jid $xlib $user
    }
}

proc cache_preferred_jid {xlib user} {
    global presence

    set jids [get_jids_of_user $xlib $user]

    if {$jids != {}} {
        set rjid [lindex $jids 0]
        set pri $presence(priority,$xlib,$rjid)

        foreach jid $jids {
            if {$presence(priority,$xlib,$jid) > $pri} {
                set pri $presence(priority,$xlib,$jid)
                set rjid $jid
            }
        }

        set presence(maxpriority,$xlib,$user) $pri
        set presence(preferred_jid,$xlib,$user) $rjid
    }
}


proc get_jid_status {xlib jid} {
    global presence

    set j $jid
    if {[info exists presence(show,$xlib,$j)]} {
        return $presence(show,$xlib,$j)
    } else {
        return unavailable
    }
}

proc get_jid_presence_info {param xlib jid} {
    global presence

    if {[info exists presence($param,$xlib,$jid)]} {
        return $presence($param,$xlib,$jid)
    } else {
        return ""
    }
}

proc get_user_status {xlib user} {
    global presence

    if {[info exists presence(cachedstatus,$xlib,$user)]} {
        return $presence(cachedstatus,$xlib,$user)
    } elseif {[info exists presence(show,$xlib,$user)]} {
        return $presence(show,$xlib,$user)
    } else {
        return unavailable
    }
}

proc cache_user_status {xlib user} {
    global presence

    set jid [get_jid_of_user $xlib $user]
    if {[info exists presence(show,$xlib,$jid)]} {
        set presence(cachedstatus,$xlib,$user) $presence(show,$xlib,$jid)
    } else {
        set presence(cachedstatus,$xlib,$user) unavailable
    }
}

proc get_user_status_desc {xlib user} {
    global presence

    set jid [get_jid_of_user $xlib $user]
    if {[info exists presence(error,$xlib,$jid)]} {
        return [::xmpp::stanzaerror::message $presence(error,$xlib,$jid)]
    } elseif {[info exists presence(status,$xlib,$jid)]} {
        return $presence(status,$xlib,$jid)
    } else {
        return ""
    }
}

array set status_priority {
    unavailable 1
    xa          2
    away        3
    dnd         4
    available   5
    chat        6
}

proc compare_status {s1 s2} {
    global status_priority
    set p1 $status_priority($s1)
    set p2 $status_priority($s2)
    if {$p1 > $p2} {
        return 1
    } elseif {$p1 == $p2} {
        return 0
    } else {
        return -1
    }
}

proc max_status {s1 s2} {
    global status_priority
    set p1 $status_priority($s1)
    set p2 $status_priority($s2)
    if {$p1 >= $p2} {
        return $s1
    } else {
        return $s2
    }
}

###############################################################################

set curpriority   0
set curuserstatus unavailable
set curtextstatus ""

custom::defvar userpriority 0 [::msgcat::mc "Stored user priority."] \
    -type integer -group Hidden
custom::defvar userstatus available [::msgcat::mc "Stored user status."] \
    -type string -group Hidden
custom::defvar textstatus "" [::msgcat::mc "Stored user text status."] \
    -type string -group Hidden

set userstatusdesc [::msgcat::mc "Not logged in"]

set statusdesc(available)   [::msgcat::mc "Available"]
set statusdesc(chat)        [::msgcat::mc "Free to chat"]
set statusdesc(away)        [::msgcat::mc "Away"]
set statusdesc(xa)          [::msgcat::mc "Extended away"]
set statusdesc(dnd)         [::msgcat::mc "Do not disturb"]
set statusdesc(invisible)   [::msgcat::mc "Invisible"]
set statusdesc(unavailable) [::msgcat::mc "Unavailable"]

###############################################################################

proc change_priority_dialog {} {
    global tmppriority
    global userpriority

    set tmppriority $userpriority

    set w .change_priority
    if {[winfo exists $w]} {
        focus -force $w
        return
    }

    Dialog $w -title [::msgcat::mc "Change Presence Priority"] \
              -modal none \
              -anchor e \
              -default 0 \
              -cancel 1

    $w add -text [::msgcat::mc "OK"] \
           -command [list do_change_priority $w]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set f [$w getframe]
    Label $f.lpriority -text [::msgcat::mc "Priority:"]
    Spinbox $f.priority -1000 1000 1 tmppriority

    grid $f.lpriority -row 0 -column 0 -sticky e
    grid $f.priority  -row 0 -column 1 -sticky ew

    grid columnconfigure $f 0 -weight 1
    grid columnconfigure $f 1 -weight 1

    $w draw
}

###############################################################################

proc do_change_priority {w} {
    global userstatus
    global tmppriority
    global userpriority

    destroy $w
    if {$userpriority ne $tmppriority} {
        set userpriority $tmppriority
        set userstatus $userstatus
    }
}

###############################################################################

trace add variable userstatus write change_our_presence
trace add variable logoutuserstatus write change_our_presence

###############################################################################

proc change_our_presence {name1 name2 op} {
    global userstatus logoutuserstatus curuserstatus
    global textstatus logouttextstatus curtextstatus
    global userpriority logoutpriority curpriority
    global statusdesc userstatusdesc

    switch -- $name1 {
        logoutuserstatus {
            set newstatus $logoutuserstatus
            set newtextstatus $logouttextstatus
            set newpriority $logoutpriority
        }
        default {
            if {[llength [connections]] == 0} return
            set newstatus $userstatus
            set newtextstatus $textstatus
            set newpriority $userpriority
        }
    }

    if {$newstatus eq $curuserstatus && \
            $newtextstatus eq $curtextstatus && \
            $newpriority eq $curpriority} {
        return
    }

    if {$newstatus ni [array names statusdesc]} {
        error [::msgcat::mc "Invalid userstatus value %s" $newstatus]
    }

    set userstatusdesc $statusdesc($newstatus)
    set status $newtextstatus

    foreach xlib [connections] {
        send_presence $xlib $newstatus \
                      -status $status \
                      -priority $newpriority
    }

    foreach chatid [lfilter chat::is_groupchat [chat::opened]] {
        set xlib [chat::get_xlib $chatid]
        set group [chat::get_jid $chatid]
        set nick [get_our_groupchat_nick $chatid]

        if {$newstatus == "invisible"} {
            set newst available
        } else {
            set newst $newstatus
        }

        send_presence $xlib $newst \
                      -to $group/$nick \
                      -status $status \
                      -priority $userpriority
    }

    set curuserstatus $newstatus
    set curtextstatus $newtextstatus
    set curpriority $newpriority

    hook::run change_our_presence_post_hook $newstatus
}

###############################################################################

proc send_first_presence {xlib} {
    global userstatus curuserstatus statusdesc userstatusdesc
    global textstatus curtextstatus
    global userpriority curpriority
    global loginconf

    if {$userstatus ni [array names statusdesc]} {
        error [::msgcat::mc "Invalid userstatus value %s" $userstatus]
    }

    set userstatusdesc $statusdesc($userstatus)
    set status $textstatus

    set curuserstatus $userstatus
    set curtextstatus $textstatus
    set curpriority [set userpriority $loginconf(priority)]

    send_presence $xlib $userstatus \
                  -status $status \
                  -priority $userpriority

    hook::run change_our_presence_post_hook $userstatus
}

hook::add connected_hook [namespace current]::send_first_presence 15

###############################################################################

proc send_custom_presence {xlib jid status args} {
    global userpriority
    global statusdesc

    set type jid
    set stat ""
    foreach {key val} $args {
        switch -- $key {
            -type   { set type $val }
            -status { set stat $val }
        }
    }

    switch -- $type {
        group   {
            set to $jid/[get_our_groupchat_nick [chat::chatid $xlib $jid]]
        }
        default {
            set to $jid
        }
    }

    send_presence $xlib $status {*}$args \
                  -to $to -status $stat -priority $userpriority
}

###############################################################################

proc send_presence {xlib status args} {
    set newargs [presence_args $xlib $status {*}$args]
    ::xmpp::sendPresence $xlib {*}$newargs
}

###############################################################################

proc presence_args {xlib status args} {
    switch -- $status {
        available   {
            set newargs {}
        }
        unavailable {
            set newargs [list -type $status]
        }
        default     {
            set newargs [list -show $status]
        }
    }

    set xlist {}
    set to ""
    set stat ""
    foreach {opt val} $args {
        switch -- $opt {
            -id       { lappend newargs -id $val }
            -to       {
                set to $val
                lappend newargs -to $val
            }
            -priority { lappend newargs -priority $val }
            -xlist    { set xlist $val }
            -status   { set stat $val }
        }
    }

    hook::run rewrite_presence_status_hook stat $xlib

    if {$stat != ""} {
        lappend newargs -status $stat
    }

    hook::run presence_xlist_hook xlist $xlib $stat
    lappend newargs -xlist $xlist

    debugmsg presence "$newargs"
    return $newargs
}

###############################################################################

proc normalize_show {show} {
    set res $show

    switch -- $show {
        away        {}
        chat        {}
            dnd         {}
        xa          {}
        unavailable {}
        default     {set res available}
    }
    return $res
}

###############################################################################

proc add_presence_to_popup_info {infovar xlib jid} {
    upvar 0 $infovar info

    set bjid [::xmpp::jid::removeResource $jid]
    if {[chat::is_groupchat [chat::chatid $xlib $bjid]]} return

    set priority [get_jid_presence_info priority $xlib $jid]
    if {$priority != ""} {
        append info "\n\t[::msgcat::mc {Priority:}] $priority"
    }
}

hook::add roster_user_popup_info_hook add_presence_to_popup_info 20

###############################################################################

proc clear_presence_info {xlib} {
    global curuserstatus
    global userstatusdesc
    global presence

    array unset presence type,$xlib,*
    array unset presence status,$xlib,*
    array unset presence priority,$xlib,*
    array unset presence show,$xlib,*
    array unset presence error,$xlib,*
    array unset presence x,$xlib,*
    array unset presence user_jids,$xlib,*
    array unset presence preferred_jid,$xlib,*
    array unset presence cachedstatus,$xlib,*
    array unset presence maxpriority,$xlib,*

    if {[connections] == {}} {
        set_status "Disconnected"

        set curuserstatus unavailable
        set userstatusdesc [::msgcat::mc "Not logged in"]
        hook::run change_our_presence_post_hook unavailable
    }
}

hook::add disconnected_hook clear_presence_info

###############################################################################

proc custom_presence_menu {m xlib jid} {
    set chatid [chat::chatid $xlib $jid]
    set chatid1 [chat::chatid $xlib [::xmpp::jid::removeResource $jid]]

    if {![chat::is_groupchat $chatid] && [chat::is_groupchat $chatid1]} {
        return
    }

    if {[chat::is_groupchat $chatid]} {
        set jid [::xmpp::jid::replaceResource $jid \
                                              [get_our_groupchat_nick $chatid]]
    }

    set mm [menu $m.custom_presence -tearoff 0]

    $mm add command -label [::msgcat::mc "Available"] \
                    -command [list send_custom_presence $xlib $jid available]
    $mm add command -label [::msgcat::mc "Free to chat"] \
                    -command [list send_custom_presence $xlib $jid chat]
    $mm add command -label [::msgcat::mc "Away"] \
                    -command [list send_custom_presence $xlib $jid away]
    $mm add command -label [::msgcat::mc "Extended away"] \
                    -command [list send_custom_presence $xlib $jid xa]
    $mm add command -label [::msgcat::mc "Do not disturb"] \
                    -command [list send_custom_presence $xlib $jid dnd]
    $mm add command -label [::msgcat::mc "Unavailable"] \
                    -command [list send_custom_presence $xlib $jid unavailable]

    $m add cascade -label [::msgcat::mc "Send custom presence"] \
                   -menu $mm
}

hook::add chat_create_user_menu_hook custom_presence_menu 43
hook::add roster_jid_popup_menu_hook custom_presence_menu 43
hook::add roster_service_popup_menu_hook custom_presence_menu 43
hook::add chat_create_conference_menu_hook custom_presence_menu 43

###############################################################################

proc service_login {xlib jid} {
    global userstatus curtextstatus

    set newargs {}

    if {$curtextstatus ne ""} {
        lappend newargs -status $curtextstatus
    }

    switch -- $userstatus {
        available {}
        invisible {
            lappend newargs -type $userstatus
        }
        default {
            lappend newargs -show $userstatus
        }
    }

    ::xmpp::sendPresence $xlib -to $jid {*}$newargs
}

proc service_logout {xlib jid} {
    global curtextstatus

    set newargs {}

    if {$curtextstatus ne ""} {
        lappend newargs -status $curtextstatus
    }

    ::xmpp::sendPresence $xlib -to $jid -type unavailable {*}$newargs
}

proc service_login_logout_menu_item {m xlib jid} {
    # TODO
    $m add command -label [::msgcat::mc "Log in"] \
                   -command [list service_login $xlib $jid]
    $m add command -label [::msgcat::mc "Log out"] \
                   -command [list service_logout $xlib $jid]
}

hook::add roster_service_popup_menu_hook service_login_logout_menu_item 20

###############################################################################

proc systray_presence_menu_item {m} {
    set mp [menu $m.presence -title [::msgcat::mc "Presence"] \
                             -tearoff $::ifacetk::options(show_tearoffs)]

    $mp add command -label [::msgcat::mc "Available"] \
                    -command {set userstatus available}
    $mp add command -label [::msgcat::mc "Free to chat"] \
                    -command {set userstatus chat}
    $mp add command -label [::msgcat::mc "Away"] \
                    -command {set userstatus away}
    $mp add command -label [::msgcat::mc "Extended away"] \
                    -command {set userstatus xa}
    $mp add command -label [::msgcat::mc "Do not disturb"] \
                    -command {set userstatus dnd}
    $mp add separator
    $mp add command -label [::msgcat::mc "Change priority..."] \
                    -command change_priority_dialog

    $m add cascade -label [::msgcat::mc "Presence"] -menu $mp

}

hook::add systray_menu_hook systray_presence_menu_item 40

# vim:ft=tcl:ts=8:sw=4:sts=4:et
