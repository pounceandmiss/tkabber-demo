# iqibb.tcl --
#
#       IQ-based In-Band Bytestreams (XEP is to be submitted) transport for SI

namespace eval iqibb {}

set ::NS(iqibb) http://jabber.org/protocol/iqibb

###############################################################################

proc iqibb::connect {stream chunk_size command} {
    upvar #0 $stream state

    set_status [::msgcat::mc "Opening IQ-IBB connection"]

    ::xmpp::sendIQ $state(xlib) set \
        -query [::xmpp::xml::create open \
                        -xmlns $::NS(iqibb) \
                        -attrs [list sid $state(id) \
                                     block-size $chunk_size]] \
        -to $state(jid) \
        -command [list [namespace current]::recv_connect_response \
                      $stream $command]
}

proc iqibb::recv_connect_response {stream command status xml} {
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

proc iqibb::send_data {stream data command} {
    upvar #0 $stream state

    ::xmpp::sendIQ $state(xlib) set \
        -query [::xmpp::xml::create data \
                        -xmlns $::NS(iqibb) \
                        -attrs [list sid $state(id) \
                                     seq $state(seq)] \
                        -cdata [base64::encode $data]] \
        -to $state(jid) \
        -command [list [namespace current]::send_data_ack $stream $command]

    set state(seq) [expr {($state(seq) + 1) % 65536}]
}

proc iqibb::send_data_ack {stream command status xml} {
    if {$status != "ok"} {
        uplevel #0 $command [list [list 0 [error_to_string $xml]]]
    } else {
        uplevel #0 $command 1
    }
}

###############################################################################

proc iqibb::close {stream} {
    upvar #0 $stream state

    ::xmpp::sendIQ $state(xlib) set \
        -query [::xmpp::xml::create close \
                        -xmlns $::NS(iqibb) \
                        -attrs [list sid $state(id)]] \
        -to $state(jid)
}

###############################################################################

proc iqibb::iq_set_handler {xlib from query args} {
    ::xmpp::xml::split $query tag xmlns attrs cdata subels

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
                debugmsg si "IQIBB: WRONG DATA"
                si::closed $stream
                return [list error modify bad-request \
                             -text [::trans::trans $lang \
                                        "Cannot decode received data"]]
            } else {
                debugmsg si "IQIBB: RECV DATA [list $data]"
                if {![si::recv_data $stream $decoded]} {
                    si::closed $stream
                    return [list error cancel not-allowed \
                                 -text [::trans::trans $lang \
                                            "File transfer is aborted"]]
                }
            }
        }
    }

    return [list result ""]
}

::xmpp::iq::register set * $::NS(iqibb) \
                     [namespace current]::iqibb::iq_set_handler

###############################################################################

si::register_transport $::NS(iqibb) $::NS(iqibb) 70 enabled \
                       [namespace current]::iqibb::connect \
                       [namespace current]::iqibb::send_data \
                       [namespace current]::iqibb::close

# vim:ft=tcl:ts=8:sw=4:sts=4:et
