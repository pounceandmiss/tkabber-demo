# socks5.tcl --
#
#       SOCKS5 Bytestreams (XEP-0065) transport for SI

namespace eval socks5 {}
namespace eval socks5::target {}
namespace eval socks5::initiator {

    custom::defvar options(enable_mediated_connection) 1 \
        [::msgcat::mc "Use mediated SOCKS5 connection if proxy is available."] \
        -group {Stream Initiation} -type boolean

    custom::defvar options(proxy_servers) "" \
        [::msgcat::mc "List of proxy servers for SOCKS5 bytestreams (all\
                       available servers will be tried for mediated connection)."] \
        -group {Stream Initiation} -type string
}

set ::NS(bytestreams) http://jabber.org/protocol/bytestreams

###############################################################################

proc socks5::target::sock_connect {stream iqid hosts lang} {
    upvar #0 $stream state

    if {![info exists state(id)] || [llength $hosts] == 0} {
        sock_finish $stream $iqid $lang error ""
        return
    }

    set tail [lassign $hosts host]
    lassign $host addr port streamhost
    debugmsg si "CONNECTING TO $addr:$port..."

    set token [::pconnect::socket $addr $port \
                    -proxyfilter ::proxy::proxyfilter \
                    -command [namespace code [list sock_writable \
                                                   $stream $iqid $lang \
                                                   $streamhost $tail]]]
    return
}

proc socks5::target::sock_writable {stream iqid lang streamhost hosts status sock} {
    upvar #0 $stream state

    if {$status != "ok"} {
        sock_connect $stream $iqid $hosts $lang
        return
    }

    fconfigure $sock -translation binary -blocking no

    if {![info exists state(id)]} {
        ::close $sock
        sock_finish $stream $iqid $lang error ""
        return
    }

    if {[catch {fconfigure $sock -peername}]} {
        ::close $sock
        sock_connect $stream $iqid $hosts $lang
        return
    }

    puts -nonewline $sock "\x05\x01\x00"
    if {[catch {flush $sock}]} {
        ::close $sock
        sock_connect $stream $iqid $hosts $lang
        return
    }

    set state(sock) $sock

    fileevent $sock readable \
              [namespace code [list wait_for_method $sock $stream $iqid \
                                                    $lang $streamhost $hosts]]
    return
}

proc socks5::target::sock_finish {stream iqid lang status streamhost} {
    upvar #0 $stream state

    if {$status == "ok"} {
        debugmsg si "SUCCEDED ($streamhost)"

        ::xmpp::sendIQ $state(xlib) result \
                -query [::xmpp::xml::create query \
                            -xmlns $::NS(bytestreams) \
                            -subelement [::xmpp::xml::create streamhost-used \
                                                -attrs [list jid \
                                                             $streamhost]]] \
                -id $iqid \
                -to $state(jid)
    } else {
        debugmsg si "FAILED"

        ::xmpp::sendIQ $state(xlib) error \
                -error [::xmpp::stanzaerror::error cancel item-not-found \
                                -text [::trans::trans \
                                            $lang \
                                            "Cannot connect to any\
                                             of the streamhosts"]] \
                -id $iqid \
                -to $state(jid)
    }
    return
}

###############################################################################

proc socks5::target::wait_for_method {sock stream iqid lang streamhost hosts} {
    upvar #0 $stream state

    if {![info exists state(id)]} {
        ::close $sock
        sock_finish $stream $iqid $lang error ""
        return
    }

    if {[catch {set data [read $sock]}]} {
        ::close $sock
        sock_connect $stream $iqid $hosts $lang
        return
    }

    if {[eof $sock]} {
        ::close $sock
        sock_connect $stream $iqid $hosts $lang
        return
    }

    binary scan $data cc ver method

    if {$ver != 5 || $method != 0} {
        ::close $sock
        sock_connect $stream $iqid $hosts $lang
        return
    }

    set myjid [encoding convertto utf-8 \
                   [::xmpp::jid::normalize [my_jid $state(xlib) $state(jid)]]]
    set hisjid [encoding convertto utf-8 [::xmpp::jid::normalize $state(jid)]]
    set hash [::sha1::sha1 $state(id)$hisjid$myjid]

    set len [binary format c [string length $hash]]

    puts -nonewline $sock "\x05\x01\x00\x03$len$hash\x00\x00"
    flush $sock

    fileevent $sock readable \
        [list [namespace current]::wait_for_reply $sock $stream $iqid \
                                                  $lang $streamhost $hosts]
}

proc socks5::target::wait_for_reply {sock stream iqid lang streamhost hosts} {
    upvar #0 $stream state

    if {![info exists state(id)]} {
        ::close $sock
        sock_finish $stream $iqid $lang error ""
        return
    }

    if {[catch {set data [read $sock]}]} {
        ::close $sock
        sock_connect $stream $iqid $hosts $lang
        return
    }

    if {[eof $sock]} {
        ::close $sock
        sock_connect $stream $iqid $hosts $lang
        return
    }

    binary scan $data cc ver rep

    if {$ver != 5 || $rep != 0} {
        ::close $sock
        sock_connect $stream $iqid $hosts $lang
        return
    }

    fileevent $sock readable \
        [list [namespace parent]::readable $stream $sock]

    sock_finish $stream $iqid $lang ok $streamhost
}

###############################################################################

proc socks5::target::send_data {stream data} {
    upvar #0 $stream state

    puts -nonewline $state(sock) $data
    flush $state(sock)

    return 1
}

###############################################################################

proc socks5::target::close {stream} {
    upvar #0 $stream state

    ::close $state(sock)
}

###############################################################################
###############################################################################

proc socks5::initiator::connect {stream chunk_size command} {
    variable options
    variable hash_sid
    upvar #0 $stream state

    set_status [::msgcat::mc "Opening SOCKS5 listening socket"]

    set servsock [socket -server [list [namespace current]::accept $stream] 0]
    set state(servsock) $servsock
    lassign [fconfigure $servsock -sockname] addr hostname port
    set ip [::xmpp::ip $state(xlib)]
    set myjid [encoding convertto utf-8 \
                   [::xmpp::jid::normalize [my_jid $state(xlib) $state(jid)]]]
    set hisjid [encoding convertto utf-8 [::xmpp::jid::normalize $state(jid)]]
    set hash [::sha1::sha1 $state(id)$myjid$hisjid]
    set hash_sid($hash) $state(id)

    set streamhosts [list [::xmpp::xml::create streamhost \
                               -attrs [list jid [my_jid $state(xlib) $state(jid)] \
                                            host $ip \
                                            port $port]]]

    if {!$options(enable_mediated_connection)} {
        request $stream $streamhosts $command
    } else {
        set proxies [split $options(proxy_servers)]
        set proxies1 {}
        foreach p $proxies {
            if {$p != ""} {
                lappend proxies1 $p
            }
        }
        request_proxy $stream $streamhosts $proxies1 $command
    }
}

###############################################################################

proc socks5::initiator::request_proxy \
                    {stream streamhosts proxies command} {
    upvar #0 $stream state

    if {[llength $proxies] == 0} {
        request $stream $streamhosts $command
    } else {
        ::xmpp::sendIQ $state(xlib) get \
            -query [::xmpp::xml::create query \
                            -xmlns $::NS(bytestreams)] \
            -to [lindex $proxies 0] \
            -command [list [namespace current]::recv_request_proxy_response \
                           $stream $streamhosts [lrange $proxies 1 end] \
                           $command]
    }
}

proc socks5::initiator::recv_request_proxy_response \
                    {stream streamhosts proxies command res child} {
    upvar #0 $stream state

    if {![info exists state(id)]} {
        return
    }

    if {$res == "abort"} {
        uplevel #0 $command [list [list 0 [::msgcat::mc "Aborted"]]]
        return
    }

    if {$res != "ok"} {
        request_proxy $stream $streamhosts $proxies $command
        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    foreach subel $subels {
        ::xmpp::xml::split $subel stag sxmlns sattrs scdata ssubels
        if {$stag == "streamhost"} {
            lappend streamhosts $subel
        }
    }
    request_proxy $stream $streamhosts $proxies $command
}

###############################################################################

proc socks5::initiator::request {stream streamhosts command} {
    upvar #0 $stream state

    ::xmpp::sendIQ $state(xlib) set \
        -query [::xmpp::xml::create query \
                        -xmlns $::NS(bytestreams) \
                        -attrs [list sid $state(id)] \
                        -subelements $streamhosts] \
        -to $state(jid) \
        -command [list [namespace current]::recv_request_response \
                       $stream $streamhosts $command]
}

proc socks5::initiator::recv_request_response \
                        {stream streamhosts command res child} {
    upvar #0 $stream state

    if {![info exists state(id)]} {
        return
    }

    if {$res != "ok"} {
        uplevel #0 $command [list [list 0 [error_to_string $child]]]
        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels
    ::xmpp::xml::split [lindex $subels 0] stag sxmlns sattrs scdata ssubels
    if {$stag != "streamhost-used"} {
        uplevel #0 $command [list [list 0 [::msgcat::mc "Illegal result"]]]
        return
    }

    set jid [::xmpp::xml::getAttr $sattrs jid]
    set idx 0
    foreach streamhost $streamhosts {
        ::xmpp::xml::split $streamhost sstag ssxmlns ssattrs sscdata sssubels
        if {[::xmpp::xml::getAttr $ssattrs jid] == $jid} {
            break
        }
        incr idx
    }

    if {$idx == 0} {
        # Target uses nonmediated connection
        uplevel #0 $command 1
    } elseif {$idx == [llength $streamhosts]} {
        # Target has reported missing JID
        uplevel #0 $command [list [list 0 [::msgcat::mc "Illegal result"]]]
    } else {
        # TODO: zeroconf support
        set jid  [::xmpp::xml::getAttr $ssattrs jid]
        set host [::xmpp::xml::getAttr $ssattrs host]
        set port [::xmpp::xml::getAttr $ssattrs port]

        # Target uses proxy, so closing server socket
        ::close $state(servsock)
        proxy_connect $stream $jid $host $port $command
    }
}

###############################################################################

proc socks5::initiator::proxy_connect {stream jid host port command} {
    upvar #0 $stream state

    debugmsg si "CONNECTING TO SOCKS5 PROXY $host:$port..."

    set token [::pconnect::socket $host $port \
                    -proxyfilter ::proxy::proxyfilter \
                    -command [namespace code [list sock_writable $stream $jid $command]]]
    return
}

proc socks5::initiator::sock_writable {stream jid command status sock} {
    upvar #0 $stream state

    if {$status != "ok"} {
        debugmsg si "CONNECTION FAILED"
        uplevel #0 $command [list [list 0 [::msgcat::mc \
                                               "Cannot connect to proxy"]]]
        return
    }

    debugmsg si "CONNECTED"

    fconfigure $sock -translation binary -blocking no
    set state(sock) $sock

    puts -nonewline $sock "\x05\x01\x00"
    flush $sock
    fileevent $sock readable \
        [list [namespace current]::proxy_wait_for_method $sock $stream $jid $command]
    return
}

proc socks5::initiator::sock_finish {sock stream jid command status} {
    upvar #0 $stream state

    if {$status != "ok"} {
        debugmsg si "SOCKS5 NEGOTIATION FAILED"
        ::close $sock
        uplevel #0 $command \
                [list [list 0 [::msgcat::mc \
                                   "Cannot negotiate proxy connection"]]]
        return
    }

    # Activate mediated connection
    ::xmpp::sendIQ $state(xlib) set \
        -query [::xmpp::xml::create query \
                        -xmlns $::NS(bytestreams) \
                        -attrs [list sid $state(id)] \
                        -subelement [::xmpp::xml::create activate \
                                            -cdata $state(jid)]] \
        -to $jid \
        -command [list [namespace current]::proxy_activate_response \
                       $stream $command]
}

###############################################################################

proc socks5::initiator::proxy_activate_response {stream command res child} {
    upvar #0 $stream state

    if {![info exists state(id)]} {
        return
    }

    if {$res != "ok"} {
        uplevel #0 $command [list [list 0 [error_to_string $child]]]
        return
    }

    uplevel #0 $command 1
}

###############################################################################

proc socks5::initiator::proxy_wait_for_method {sock stream jid command} {
    upvar #0 $stream state

    if {![info exists state(id)]} {
        return
    }

    if {[catch {set data [read $sock]}]} {
        sock_finish $sock $stream $jid $command error
        return
    }

    if {[eof $sock]} {
        sock_finish $sock $stream $jid $command error
        return
    }

    binary scan $data cc ver method

    if {$ver != 5 || $method != 0} {
        sock_finish $sock $stream $jid $command error
        return
    }

    set myjid [encoding convertto utf-8 \
                   [::xmpp::jid::normalize [my_jid $state(xlib) $state(jid)]]]
    set hisjid [encoding convertto utf-8 [::xmpp::jid::normalize $state(jid)]]
    set hash [::sha1::sha1 $state(id)$myjid$hisjid]

    set len [binary format c [string length $hash]]

    puts -nonewline $sock "\x05\x01\x00\x03$len$hash\x00\x00"
    flush $sock

    fileevent $sock readable \
        [list [namespace current]::proxy_wait_for_reply $sock $stream $jid $command]
}

proc socks5::initiator::proxy_wait_for_reply {sock stream jid command} {
    upvar #0 $stream state

    if {![info exists state(id)]} {
        return
    }

    if {[catch {set data [read $sock]}]} {
        sock_finish $sock $stream $jid $command error
        return
    }

    if {[eof $sock]} {
        sock_finish $sock $stream $jid $command error
        return
    }

    binary scan $data cc ver rep

    if {$ver != 5 || $rep != 0} {
        sock_finish $sock $stream $jid $command error
        return
    }

    sock_finish $sock $stream $jid $command ok
    return
}

###############################################################################

proc socks5::initiator::send_data {stream data command} {
    upvar #0 $stream state

    puts -nonewline $state(sock) $data
    flush $state(sock)

    after idle [list uplevel #0 $command 1]
}

###############################################################################

proc socks5::initiator::close {stream} {
    upvar #0 $stream state

    ::close $state(sock)
    catch {::close $state(servsock)}
}

###############################################################################

proc socks5::initiator::accept {stream sock addr port} {
    upvar #0 $stream state

    debugmsg si "CONNECT FROM $addr:$port"

    set state(sock) $sock
    fconfigure $sock -translation binary -blocking no

    fileevent $sock readable \
        [list [namespace current]::wait_for_methods $sock $stream]
}

proc socks5::initiator::wait_for_methods {sock stream} {
    upvar #0 $stream state

    if {[catch {set data [read $sock]}]} {
        ::close $sock
        return
    }

    if {[eof $sock]} {
        ::close $sock
        return
    }

    binary scan $data ccc* ver nmethods methods

    if {$ver != 5 || 0 ni $methods} {
        puts -nonewline $sock "\x05\xff"
        ::close $sock
        return
    }

    puts -nonewline $sock "\x05\x00"
    flush $sock

    fileevent $sock readable \
        [list [namespace current]::wait_for_request $sock $stream]
}

proc socks5::initiator::wait_for_request {sock stream} {
    variable hash_sid
    upvar #0 $stream state

    if {[catch {set data [read $sock]}]} {
        ::close $sock
        return
    }

    if {[eof $sock]} {
        ::close $sock
        return
    }

    binary scan $data ccccc ver cmd rsv atyp len

    if {$ver != 5 || $cmd != 1 || $atyp != 3} {
        set reply [string replace $data 1 1 \x07]
        puts -nonewline $sock $reply
        ::close $sock
        return
    }

    binary scan $data @5a${len} hash

    debugmsg si "RECV HASH: $hash"

    if {[info exists hash_sid($hash)] && \
            [string equal $hash_sid($hash) $state(id)]} {
        set reply [string replace $data 1 1 \x00]
        puts -nonewline $sock $reply
        flush $sock

        fileevent $sock readable {}
    } else {
        set reply [string replace $data 1 1 \x02]
        puts -nonewline $sock $reply
        ::close $sock
    }
}

###############################################################################

proc socks5::readable {stream chan} {
    if {![eof $chan]} {
        set buf [read $chan 4096]
        si::recv_data $stream $buf
    } else {
        fileevent $chan readable {}
        si::closed $stream
    }
}

###############################################################################

proc socks5::iq_set_handler {xlib from child args} {
    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    set iqid [::xmpp::xml::getAttr $args -id]
    set lang [::xmpp::xml::getAttr $args -lang en]

    if {$tag != "query"} {
        return [list error modify bad-request]
    }

    set id [::xmpp::xml::getAttr $attrs sid]
    if {[catch {si::in $xlib $from $id} stream]} {
        return [list error modify bad-request \
                     -text [::trans::trans $lang \
                                           "Stream ID has not been negotiated"]]
    }

    set hosts {}
    foreach item $subels {
        ::xmpp::xml::split $item stag sxmlns sattrs scdata1 ssubels
        switch -- $stag {
            streamhost {
                lappend hosts [list [::xmpp::xml::getAttr $sattrs host] \
                                    [::xmpp::xml::getAttr $sattrs port] \
                                    [::xmpp::xml::getAttr $sattrs jid]]
            }
        }
    }

    debugmsg si [list $hosts]
    [namespace current]::target::sock_connect $stream $iqid $hosts $lang
}

::xmpp::iq::register set * $::NS(bytestreams) \
                     [namespace current]::socks5::iq_set_handler

si::register_transport $::NS(bytestreams) $::NS(bytestreams) 50 disabled \
                       [namespace current]::socks5::initiator::connect \
                       [namespace current]::socks5::initiator::send_data \
                       [namespace current]::socks5::initiator::close

# vim:ft=tcl:ts=8:sw=4:sts=4:et
