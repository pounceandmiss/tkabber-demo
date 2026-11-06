# time.tcl --
#
#       This file is a part of the Tkabber XMPP client. It provides the
#       replies to the jabber:iq:time (XEP-0090) queries.

custom::defvar options(reply_iq_time) 1 \
    [::msgcat::mc "Reply to current time (jabber:iq:time) requests."] \
    -group IQ -type boolean

proc iq_time {xlib from child args} {
    variable options

    if {!$options(reply_iq_time)} {
        return {error cancel service-unavailable}
    }

    set curtime [clock seconds]
    set restags \
        [list [::xmpp::xml::create utc \
                    -cdata [clock format $curtime \
                                    -format "%Y%m%dT%T" -gmt true]] \
             [::xmpp::xml::create tz \
                    -cdata [timezone $curtime]] \
             [::xmpp::xml::create display \
                    -cdata [displaytime $curtime]]]

    set res [::xmpp::xml::create query \
                    -xmlns jabber:iq:time \
                    -subelements $restags]

    list result $res
}

proc timezone {time} {
    clock format $time -format %Z
}

proc displaytime {time} {
    clock format $time
}

::xmpp::iq::register get query jabber:iq:time [namespace current]::iq_time

# vim:ft=tcl:ts=8:sw=4:sts=4:et
