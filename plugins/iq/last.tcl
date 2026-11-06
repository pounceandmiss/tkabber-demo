# last.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which replies to the jabber:iq:last (XEP-0012) requests.

custom::defvar options(reply_iq_last) 1 \
    [::msgcat::mc "Reply to idle time (jabber:iq:last) requests."] \
    -group IQ -type boolean

proc iq_last {xlib from child args} {
    global userstatus statusdesc textstatus
    variable options

    if {$options(reply_iq_last) && ![catch {tk inactive} ms] && $ms >= 0} {
        set seconds [expr {$ms/1000}]
        set status $statusdesc($userstatus)
        if {$textstatus eq ""} {
            set status "$statusdesc($userstatus)"
        } else {
            set status "$textstatus ($statusdesc($userstatus))"
        }
        return [list result [::xmpp::xml::create query \
                                    -xmlns jabber:iq:last \
                                    -attrs [list seconds $seconds] \
                                    -cdata $status]]
    } else {
        return [list error cancel service-unavailable]
    }
}

::xmpp::iq::register get query jabber:iq:last [namespace current]::iq_last

# vim:ft=tcl:ts=8:sw=4:sts=4:et
