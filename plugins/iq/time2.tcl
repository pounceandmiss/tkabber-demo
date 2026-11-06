# time2.tcl --
#
#       This file is a part of the Tkabber XMPP client. It provides the
#       replies to the Entity Time (XEP-0202) queries.

custom::defvar options(reply_xmpp_time) 1 \
    [::msgcat::mc "Reply to entity time (urn:xmpp:time) requests."] \
    -group IQ -type boolean

proc xmpp_time {xlib from child args} {
    variable options

    if {!$options(reply_xmpp_time)} {
        return {error cancel service-unavailable}
    }

    set curtime [clock seconds]
    set restags \
        [list [::xmpp::xml::create utc \
                    -cdata [clock format $curtime \
                                  -format "%Y-%m-%dT%TZ" -gmt true]] \
              [::xmpp::xml::create tzo \
                    -cdata [timezone_offset $curtime]]]

    set res [::xmpp::xml::create time \
                    -xmlns urn:xmpp:time \
                    -subelements $restags]

    return [list result $res]
}

proc timezone_offset {curtime} {
    # Doesn't work with Tcl 8.4 on MS Windows
    set tz [clock format $curtime -format %z]
    regsub {[+-]0000} $tz {Z} tz1
    regsub {(\d\d)(\d\d)} $tz1 {\1:\2} tz2

    return $tz2
}

::xmpp::iq::register get time urn:xmpp:time [namespace current]::xmpp_time

# vim:ft=tcl:ts=8:sw=4:sts=4:et
