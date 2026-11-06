# iq.tcl --
#
#       This file is a part of the Tkabber XMPP client. It provides very
#       general command client:iq which takes the IQ packet from the
#       TclXMPP library and runs an appropriate hook for it.

namespace eval ::iq {
    variable options

    custom::defgroup IQ [::msgcat::mc "Info/Query options."] \
        -group Tkabber

    custom::defvar options(show_iq_requests) 0 \
        [::msgcat::mc "Show IQ requests in the status line."] \
        -group IQ \
        -type boolean

    custom::defvar options(shorten_iq_namespaces) 1 \
        [::msgcat::mc "Strip leading \"http://jabber.org/protocol/\"\
                       from IQ namespaces in the status line."] \
        -group IQ \
        -type boolean
}

proc client:iq {xlib from type queries args} {
    debugmsg iq "$xlib $from $type $queries $args"

    hook::run client_iq_hook $xlib $from $type $queries {*}$args
}

proc ::iq::show_iq_in_status {xlib from type queries args} {
    variable options

    if {$type != "set" && $type != "get"} return

    ::xmpp::xml::split [lindex $queries 0] tag xmlns attrs cdata subels

    if {$options(show_iq_requests) && \
            ($from != "" && \
            !([::xmpp::jid::equal $from [connection_server $xlib]] || \
              [::xmpp::jid::equal $from [connection_bare_jid $xlib]] || \
              [::xmpp::jid::equal $from [connection_jid $xlib]]))} {

        set xmlns_short $xmlns
        if {$options(shorten_iq_namespaces)} {
            regexp "^http://jabber.org/protocol/(.*)" $xmlns -> xmlns
        }

        set_status [::msgcat::mc "%s request from %s" $xmlns $from]
    }
}

hook::add client_iq_hook ::iq::show_iq_in_status

plugins::load [file join plugins iq]

# vim:ft=tcl:ts=8:sw=4:sts=4:et
