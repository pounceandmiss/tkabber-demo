# conferenceinfo.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       periodically requests the participants lists for the conference in
#       roster to show them in the conference popup info balloon.

namespace eval conferenceinfo {
    custom::defgroup ConferenceInfo \
        [::msgcat::mc "Options for Conference Info module, that allows you\
                       to see list of participants in roster popup,\
                       regardless of whether you are currently joined\
                       with the conference."] \
        -group Plugins \
        -tag "Conference Info"

    custom::defvar options(autoask) 0 \
        [::msgcat::mc "Use this module"] -group ConferenceInfo -type boolean \
        -command [namespace current]::ask
    custom::defvar options(interval) 2 \
        [::msgcat::mc "Interval (in minutes) between requests of participants list."] \
        -type integer -group ConferenceInfo
    custom::defvar options(err_interval) 60 \
        [::msgcat::mc "Interval (in minutes) after error reply on request of participants list."] \
        -type integer -group ConferenceInfo
}


# TODO: xlib
proc conferenceinfo::add_user_popup_info {infovar xlib jid} {
    variable data
    variable options
    upvar 0 $infovar info

    if {!$options(autoask)} return
    if {[chat::is_opened [chat::chatid $xlib $jid]]} return

    if {![info exists data(error_browse,$jid)] || \
            ![info exists data(error_disco,$jid)]} return

    if {$data(error_disco,$jid) != "" && $data(error_browse,$jid) != ""} {
        if {$data(error_browse_code,$jid) != "feature-not-implemented" && \
                $data(error_browse_code,$jid) != "service-unavailable"} {
            set errstr $data(error_browse,$jid)
        } else {
            set errstr $data(error_disco,$jid)
        }
        append info [::msgcat::mc "\n\tCan't browse: %s" $errstr]
    } else {
        if {$data(error_browse,$jid) == ""} {
            set mech browse
        } else {
            set mech disco
        }
        if {$data(users_$mech,$jid) != {}} {
            append info \
                [::msgcat::mc "\nRoom participants at %s:" \
                     [clock format $data(time_$mech,$jid) -format %R]]
            foreach name $data(users_$mech,$jid) {
                append info "\n\t$name"
            }
        } else {
            append info \
                [::msgcat::mc "\nRoom is empty at %s" \
                     [clock format $data(time_$mech,$jid) -format %R]]
        }
    }
}

hook::add roster_user_popup_info_hook \
    [namespace current]::conferenceinfo::add_user_popup_info

proc conferenceinfo::ask {args} {
    variable options
    variable data

    if {!$options(autoask)} return

    foreach xlib [connections] {
        if {[catch { set ::roster::roster(jids,$xlib) } jids]} {
            continue
        }
        foreach jid $jids {
            lassign [roster::get_category_and_subtype $xlib $jid] \
                category type
            if {$category == "conference" && [::xmpp::jid::node $jid] != "" && \
                    ![chat::is_opened [chat::chatid $xlib $jid]]} {

                set sec [clock seconds]

                if {![info exists data(error_browse,$jid)] || \
                        $data(error_browse,$jid) == "" || \
                        $sec - $data(time_browse,$jid) >= $options(err_interval) * 60} {

                    ::xmpp::sendIQ $xlib get \
                        -query [::xmpp::xml::create query \
                                        -xmlns jabber:iq:browse] \
                        -to $jid \
                        -command [list [namespace current]::receive $jid browse]
                }

                if {![info exists data(error_disco,$jid)] || \
                        $data(error_disco,$jid) == "" || \
                        $sec - $data(time_disco,$jid) >= $options(err_interval) * 60} {

                    ::disco::request_items $xlib $jid \
                        -command [list [namespace current]::receive $jid disco]
                }
            }
        }
    }

    after cancel [list [namespace current]::ask]
    after [expr {$options(interval) * 60 * 1000}] [list [namespace current]::ask]
}

proc conferenceinfo::receive {jid mech status xml} {
    variable options
    variable data

    set data(error_$mech,$jid) ""
    set data(error_${mech}_code,$jid) ""
    set data(time_$mech,$jid) [clock seconds]
    set data(users_$mech,$jid) {}

    if {$status != "ok"} {
        set data(error_${mech}_code,$jid) [lindex [error_type_condition $xml] 1]
        set data(error_$mech,$jid) [error_to_string $xml]
        return
    }

    switch -- $mech {
        browse {
            ::xmpp::xml::split $xml tag xmlns attrs cdata subels

            foreach item $subels {
                ::xmpp::xml::split $item stag sxmlns sattrs scdata ssubels
                set category [::xmpp::xml::getAttr $sattrs category]
                set name [::xmpp::xml::getAttr $sattrs name]
                if {$stag == "user" || ($stag == "item" && $category == "user")} {
                    if {$name != ""} {
                        lappend data(users_browse,$jid) $name
                    }
                }
            }
        }
        disco {
            foreach item $xml {
                set name [::xmpp::xml::getAttr $item name]
                set node [::xmpp::xml::getAttr $item node]
                if {$name != "" && $node == ""} {
                    lappend data(users_disco,$jid) $name
                }
            }
        }
    }
    set data(users_$mech,$jid) [lsort -dictionary $data(users_$mech,$jid)]
}

proc conferenceinfo::stop {args} {
    if {[llength [connections]] == 0} {
        after cancel [list [namespace current]::ask]
    }
}

hook::add roster_end_hook [namespace current]::conferenceinfo::ask
hook::add disconnected_hook [namespace current]::conferenceinfo::stop

proc conferenceinfo::setup_menu {} {
    set m [.mainframe getmenu roster]

    $m add checkbutton \
        -label [::msgcat::mc "Periodically browse roster conferences"] \
        -variable [namespace current]::options(autoask)
}

hook::add finload_hook [namespace current]::conferenceinfo::setup_menu

# vim:ft=tcl:ts=8:sw=4:sts=4:et
