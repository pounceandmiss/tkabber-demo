# ibb.tcl --
#
#       In-Band Bytestreams (XEP-0047) transport for SI

namespace eval ibb {}

set ::NS(ibb) http://jabber.org/protocol/ibb

###############################################################################

proc ibb::connect {stream chunk_size command} {
    upvar #0 $stream state

    set_status [::msgcat::mc "Opening IBB connection"]

    ::xmpp::sendIQ $state(xlib) set \
        -query [::xmpp::xml::create open \
                        -xmlns $::NS(ibb) \
                        -attrs [list sid $state(id) \
                                     block-size $chunk_size]] \
        -to $state(jid) \
        -command [list [namespace current]::recv_connect_response \
                       $stream $command]
}

proc ibb::recv_connect_response {stream command status xml} {
    upvar #0 $stream state

    if {$status != "ok"} {
        uplevel #0 $command [list [list 0 [error_to_string $xml]]]
        return
    }

    set state(seq) 0
    uplevel #0 $command 1
}

###############################################################################

package require base64

proc ibb::send_data {stream data command} {
    upvar #0 $stream state

    ::xmpp::sendMessage $state(xlib) $state(jid) \
        -xlist [list [::xmpp::xml::create data \
                            -xmlns $::NS(ibb) \
                            -attrs [list sid $state(id) \
                                         seq $state(seq)] \
                            -cdata [base64::encode $data]]]

    set state(seq) [expr {($state(seq) + 1) % 65536}]

    after 2000 [list uplevel #0 $command 1]
}

###############################################################################

proc ibb::close {stream} {
    upvar #0 $stream state

    ::xmpp::sendIQ $state(xlib) set \
        -query [::xmpp::xml::create close \
                        -xmlns $::NS(ibb) \
                        -attrs [list sid $state(id)]] \
        -to $state(jid)
}

###############################################################################

proc ibb::iq_set_handler {xlib from xml args} {
    ::xmpp::xml::split $xml tag xmlns attrs cdata subels

    set lang [::xmpp::xml::getAttr $args -lang en]

    set id [::xmpp::xml::getAttr $attrs sid]
    if {[catch {si::in $xlib $from $id} stream]} {
        return [list error modify bad-request \
                     -text [::trans::trans $lang \
                                           "Stream ID has not been negotiated"]]
    }
    upvar #0 $stream state

    switch -- $tag {
        open {
            set state(block-size) [::xmpp::xml::getAttr $attrs block-size]
            set state(seq) 0
        }
        close {
            si::closed $stream
        }
        data {
            set seq [::xmpp::xml::getAttr $attrs seq]
            if {$seq != $state(seq)} {
                si::closed $stream
                return [list error modify bad-request \
                             -text [::trans::trans $lang \
                                        "Unexpected packet sequence number"]]
            } else {
                set state(seq) [expr {($state(seq) + 1) % 65536}]
            }
            set data $cdata

            if {[catch {set decoded [base64::decode $data]}]} {
                debugmsg si "IBB: WRONG DATA"
                si::closed $stream
                return [list error modify bad-request \
                             -text [::trans::trans $lang \
                                        "Cannot decode received data"]]
            } else {
                debugmsg si "IBB: RECV DATA [list $data]"
                if {![si::recv_data $stream $decoded]} {
                    si::closed $stream
                    return [list error cancel not-allowed \
                                 -text [::trans::trans $lang \
                                            "File transfer is aborted"]]
                }
            }
        }
        default {
            return [list error modify bad-request]
        }
    }

    return [list result ""]
}

::xmpp::iq::register set * $::NS(ibb) [namespace current]::ibb::iq_set_handler

###############################################################################

proc ibb::return_error {xlib jid id error} {
    if {$id == ""} return

    ::xmpp::sendMessage $xlib $jid \
        -type error \
        -id $id \
        -error [::xmpp::stanzaerror::error {*}$error]
}

###############################################################################

proc ibb::message_handler {xlib from mid type is_subject subject body \
                                 err thread priority x} {
    if {$type == "error"} return

    foreach item $x {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        if {[string equal $xmlns $::NS(ibb)]} {
            set id [::xmpp::xml::getAttr $attrs sid]
            if {[catch {si::in $xlib $from $id} stream]} {
                # Unknown Stream ID
                return_error $xlib $from $mid \
                             [list modify bad-request \
                                   -text [::trans::trans \
                                              "Stream ID has not been negotiated"]]
                return stop
            }

            upvar #0 $stream state
            set seq [::xmpp::xml::getAttr $attrs seq]

            if {$seq != $state(seq)} {
                # Incorrect sequence number
                si::closed $stream
                return_error $xlib $from $mid \
                             [list modify bad-request \
                                   -text [::trans::trans \
                                              "Unexpected packet sequence number"]]
                return stop
            }

            set state(seq) [expr {($state(seq) + 1) % 65536}]
            set data $cdata

            if {[catch {set decoded [base64::decode $data]}]} {
                debugmsg si "IBB: WRONG DATA"
                si::closed $stream
                return_error $xlib $from $mid \
                             [list modify bad-request \
                                   -text [::trans::trans \
                                              "Cannot decode received data"]]
            } else {
                debugmsg si "IBB: RECV DATA [list $data]"
                if {![si::recv_data $stream $decoded]} {
                    si::closed $stream
                    return_error $xlib $from $mid \
                                 [list cancel not-allowed \
                                       -text [::trans::trans \
                                                  "File transfer is aborted"]]
                }
            }
            return stop
        }
    }
}

hook::add process_message_hook [namespace current]::ibb::message_handler 50

###############################################################################

si::register_transport $::NS(ibb) $::NS(ibb) 75 enabled \
    [namespace current]::ibb::connect \
    [namespace current]::ibb::send_data \
    [namespace current]::ibb::close

# vim:ft=tcl:ts=8:sw=4:sts=4:et
