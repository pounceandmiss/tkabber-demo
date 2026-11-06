# clientinfo.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       asks any user which precence packet is just received for his/her
#       client version.

namespace eval clientinfo {
    custom::defgroup ClientInfo \
        [::msgcat::mc "Options for Client Info module, which allows you to\
                       automatically retrieve client names and versions for\
                       contacts in your roster."] \
        -group Plugins \
        -tag "Client Info"

    custom::defvar options(autoask) 0 \
        [::msgcat::mc "Use this module"] -group ClientInfo -type boolean
}

# TODO: xlib
proc clientinfo::add_user_popup_info {infovar xlib jid} {
    variable users
    upvar 0 $infovar info

    if {[info exists ::userinfo::userinfo(fn,$jid)] && \
            $::userinfo::userinfo(fn,$jid) != ""} {
        append info [::msgcat::mc "\n\tName: %s" \
                         $::userinfo::userinfo(fn,$jid)]
    } elseif {[info exists ::userinfo::userinfo(name,$jid)] && \
                  $::userinfo::userinfo(name,$jid) != ""} {
        append info [::msgcat::mc "\n\tName: %s" \
                         $::userinfo::userinfo(name,$jid)]

        if {[info exists ::userinfo::userinfo(family,$jid)] && \
                $::userinfo::userinfo(family,$jid) != ""} {
            append info " $::userinfo::userinfo(family,$jid)"
        }
    }

    if {[info exists ::userinfo::userinfo(clientname,$jid)] && \
            $::userinfo::userinfo(clientname,$jid) != ""} {
        append info [::msgcat::mc "\n\tClient: %s" \
                         $::userinfo::userinfo(clientname,$jid)]
        if {[info exists ::userinfo::userinfo(clientversion,$jid)]} {
            append info " $::userinfo::userinfo(clientversion,$jid)"
        }
    }
    if {[info exists ::userinfo::userinfo(os,$jid)] && \
            $::userinfo::userinfo(os,$jid) != ""} {
        append info [::msgcat::mc "\n\tOS: %s" \
                         $::userinfo::userinfo(os,$jid)]
    }
}

hook::add roster_user_popup_info_hook \
          [namespace current]::clientinfo::add_user_popup_info


proc clientinfo::on_presence {xlib from type x args} {
    variable options
    variable asked

    if {!$options(autoask)} return

    switch -- $type {
        available {
            if {![info exists ::userinfo::userinfo(clientname,$from)] && \
                    ![info exists asked($from)]} {
                set asked($from) ""
                userinfo::request_iq version $xlib $from
            }
        }
    }
}

hook::add client_presence_hook \
          [namespace current]::clientinfo::on_presence

# vim:ft=tcl:ts=8:sw=4:sts=4:et
