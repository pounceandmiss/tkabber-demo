# bob.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       searches for the Bits-of-Binary data in the received messages, IQs
#       and presence updates (XEP-0231).

package require xmpp::bob

namespace eval bob {
    hook::add process_message_hook [namespace current]::find_bob_in_message 1
    hook::add client_presence_hook [namespace current]::find_bob_in_presence 1
    hook::add client_iq_hook [namespace current]::find_bob_in_iq 1
}

proc bob::find_bob_in_message {xlib from id type is_subject
                               subject body err thread priority x} {
    ::xmpp::bob::cache $x
}

proc bob::find_bob_in_presence {xlib from type x args} {
    ::xmpp::bob::cache $x
}

proc bob::find_bob_in_iq {xlib from type queries args} {
    if {[string equal $type error]} return

    foreach xml $queries {
        ::xmpp::xml::split $xml tag xmlns attrs cdata subels
        ::xmpp::bob::cache $subels
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
