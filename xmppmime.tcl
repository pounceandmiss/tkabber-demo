# xmppmime.tcl --
#
#       Support for XMPP/Jabber MIME Type (XEP-0081)

namespace eval ::xmppmime {
    variable used 0
    variable handle 0
    variable loaded 0
    variable connected 0
    variable queue {}
}

package require xmpp

proc ::xmppmime::load {path} {
    # TODO: catch file errors
    set f [open $path]
    set content [read $f]
    close $f

    ::xmpp::xml::parseData $content ::xmppmime::parse
}

proc ::xmppmime::parse {xmldata} {
    ::xmpp::xml::split $xmldata tag xmlns attrs cdata subels

    set jid [::xmpp::xml::getAttr $attrs jid]

    switch -- $tag {
        message {
            send_event [list message $jid]
        }

        chat {
            send_event [list chat $jid]
        }

        groupchat {
            send_event [list groupchat $jid]
        }

        subscribe {
            send_event [list subscribe $jid]
        }

        vcard {
            send_event [list vcard $jid]
        }

        register {
            send_event [list register $jid]
        }

        disco {
            send_event [list groupchat $jid]
        }
    }
}

proc ::xmppmime::send_event {event} {
    variable handle
    variable used

    set used 1

    if {!$handle} {
        if {[tk appname] == "tkabber"} {
            set handle 1
        }
    }

    if {$handle} {
        recv_event $event
    } else {
        if {[catch {send tkabber [list ::xmppmime::recv_event $event]}]} {
            set handle 1
            recv_event $event
        }
    }
}

proc ::xmppmime::recv_event {event} {
    variable queue
    variable loaded

    if {$loaded} {
        process_event $event
    } else {
        lappend queue $event
    }
}

proc ::xmppmime::process_event {event} {
    variable queue
    variable connected
    set rest [lassign $event type jid]

    set xlib [lindex [connections] 0]

    switch -- $type {
        message {
            message::send_dialog -to $jid
        }

        chat {
            chat::open_window [chat::chatid $xlib $jid] chat
        }

        groupchat {
            if {$connected} {
                muc::join $jid
            } else {
                lappend queue $event
            }
        }

        subscribe {
            message::send_subscribe_dialog $jid
        }

        vcard {
            if {$connected} {
                userinfo::open $xlib $jid
            } else {
                lappend queue $event
            }
        }

        register {
            if {$connected} {
                register::open $xlib $jid
            } else {
                lappend queue $event
            }
        }

        disco {
            if {$connected} {
                disco::browser::open_win $xlib $jid
            } else {
                lappend queue $event
            }
        }
    }
}

proc ::xmppmime::is_done {} {
    variable handle
    variable used
    return [expr {$used && !$handle}]
}

proc ::xmppmime::process_queue {} {
    variable queue
    variable loaded

    set loaded 1
    set oldqueue $queue
    set queue {}
    foreach event $oldqueue {
        process_event $event
    }
}

hook::add finload_hook ::xmppmime::process_queue

proc ::xmppmime::connected {xlib} {
    variable connected
    set connected 1
    process_queue
}

hook::add connected_hook ::xmppmime::connected

proc ::xmppmime::disconnected {xlib} {
    variable connected
    set connected [expr {[connections] != {}}]
}

hook::add disconnected_hook ::xmppmime::disconnected

# vim:ft=tcl:ts=8:sw=4:sts=4:et
