# nickname.tcl --
#
#       XEP-0172: User Nickname

namespace eval nick {}

proc nick::process_presence {xlib from type x args} {
    variable names

    set newname ""

    switch -- $type {
    subscribe -
    subscribed -
        available {
            foreach xs $x {
                ::xmpp::xml::split $xs tag xmlns attrs cdata subels
                if {[string equal $xmlns $::NS(nick)]} {
                    set newname $cdata
                }
            }
        }
    }


    if {$type == "subscribed"} {
        # JIT workaround: when receving <presence/> stanza with name attribute and
        # roster item doesn't have name, fill the name
        foreach {opt val} $args {
               switch -- $opt {
                   -name { set newname $val }
               }
        }
    }

    if {$newname == ""} return

    set jid [roster::find_jid $xlib $from]

    if {$jid == ""} {
        set names($xlib,$from) $newname
    } elseif {[roster::itemconfig $xlib $jid -name] == ""} {
        roster::itemconfig $xlib $jid -name $newname
        roster::send_item $xlib $jid
        ::redraw_roster
    }
}

hook::add client_presence_hook \
          [namespace current]::nick::process_presence

###############################################################################

proc nick::set_received_name {xlib jid name groups subsc ask} {
    variable names

    if {$subsc == "remove"} return

    if {[info exists names($xlib,$jid)]} {
        if {[roster::itemconfig $xlib $jid -name] == ""} {
            roster::itemconfig $xlib $jid -name $names($xlib,$jid)
            roster::send_item $xlib $jid
        }
        unset names($xlib,$jid)
    }
}

hook::add roster_push_hook \
          [namespace current]::nick::set_received_name 60

# vim:ft=tcl:ts=8:sw=4:sts=4:et
