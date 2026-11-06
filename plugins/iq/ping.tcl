# ping.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which implements XMPP Ping (XEP-0199) support.

package require xmpp::ping

namespace eval ping {
    custom::defvar options(ping) 1 \
        [::msgcat::mc "Ping server using XMPP ping requests."] \
        -group IQ \
        -type options \
        -values [list 0 [::msgcat::mc "No"] \
                      1 [::msgcat::mc "Only TCP based connections"] \
                      2 [::msgcat::mc "Both TCP based and HTTP based connections"]] \
        -command [namespace code start_all]

    custom::defvar options(timeout) 30 \
        [::msgcat::mc "Reconnect to server if it does not reply (with result\
                       or with error) to XMPP ping request in\
                       specified time interval (in seconds)."] \
        -group IQ \
        -type integer \
        -command [namespace code start_all]

    custom::defvar options(pong) 0 \
        [::msgcat::mc "Reply to XMPP ping requests."] \
        -group IQ \
        -type boolean

    variable sequence

    ::xmpp::ping::register -command [namespace code reply]
    hook::add connected_hook [namespace code start]
}

proc ping::reply {xlib from args} {
    variable options

    if {$options(pong)} {
        return [list result {}]
    } else {
        return [list error cancel service-unavailable]
    }
}

proc ping::start_all {args} {
    foreach xlib [connections] {
        start $xlib
    }
}

proc ping::start {xlib} {
    variable options
    variable sequence
    global xmppTransport

    after cancel [namespace code [list start $xlib]]

    if {$options(ping) == 0 || ($options(timeout) <= 0)} return

    if {$options(ping) < 2 && [info exists xmppTransport($xlib)] && \
            ($xmppTransport($xlib) == "bosh" || $xmppTransport($xlib) == "poll")} return

    if {![info exists sequence($xlib)]} {
        set sequence($xlib) 0
    }

    ::xmpp::ping::ping $xlib \
            -timeout [expr {$options(timeout)*1000}] \
            -command [namespace code [list result $xlib [incr sequence($xlib)]]]
}

proc ping::result {xlib seq status xml} {
    variable options
    variable sequence

    if {$options(ping) == 0 || ($options(timeout) <= 0)} return

    if {$options(ping) < 2 && [info exists xmppTransport($xlib)] && \
            ($xmppTransport($xlib) == "bosh" || $xmppTransport($xlib) == "poll")} return

    if {$xlib ni [connections]} return

    if {$status eq "abort"} return

    if {$seq < $sequence($xlib)} return

    if {$status eq "timeout"} {
        ::xmpp::EndOfFile $xlib
        return
    }

    after [expr {$options(timeout)*1000}] [namespace code [list start $xlib]]
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
