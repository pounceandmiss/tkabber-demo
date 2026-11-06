# browse.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       replies to the obsolete Jabber browser protocol (XEP-0011) requests.

proc iq_browse_reply {xlib from child args} {
    set restags {}
    foreach ns [::xmpp::iq::registered $xlib] {
        lappend restags [::xmpp::xml::create ns -cdata $ns]
    }

    set res [::xmpp::xml::create query \
                    -xmlns jabber:iq:browse \
                    -attrs {category user \
                            type     client \
                            name     Tkabber} \
                    -subelements $restags]

    return [list result $res]
}

::xmpp::iq::register get * jabber:iq:browse \
                     [namespace current]::iq_browse_reply

# vim:ft=tcl:ts=8:sw=4:sts=4:et
