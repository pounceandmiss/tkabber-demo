# si.tcl --
#
#       Stream Initiation (XEP-0095) implementation

namespace eval si {
    variable transport

    set transport(list) {}
}

set ::NS(si) http://jabber.org/protocol/si

###############################################################################
###############################################################################

proc si::newout {xlib jid} {
    variable streams

    set id [rand 1000000000]
    while {[info exists streams(out,$xlib,$jid,$id)]} {
        set id [rand 1000000000]
    }
    set streamid 0
    set stream [namespace current]::0
    while {[info exists $stream]} {
        set stream [namespace current]::[incr streamid]
    }
    upvar #0 $stream state

    set state(xlib) $xlib
    set state(jid) $jid
    set state(id) $id
    set streams(out,$xlib,$jid,$id) $stream

    return $stream
}

proc si::freeout {stream} {
    variable streams
    upvar #0 $stream state

    catch {
        set xlib $state(xlib)
        set jid $state(jid)
        set id $state(id)

        unset state
        unset streams(out,$xlib,$jid,$id)
    }
}

###############################################################################

proc si::newin {xlib jid id} {
    variable streams

    if {[info exists streams(in,$xlib,$jid,$id)]} {
        return -code error
    }

    set streamid 0
    set stream [namespace current]::0
    while {[info exists $stream]} {
        set stream [namespace current]::[incr streamid]
    }
    upvar #0 $stream state

    set state(xlib) $xlib
    set state(jid) $jid
    set state(id) $id
    set streams(in,$xlib,$jid,$id) $stream

    return $stream
}

proc si::in {xlib jid id} {
    variable streams

    return $streams(in,$xlib,$jid,$id)
}

proc si::freein {stream} {
    variable streams
    upvar #0 $stream state

    catch {
        set xlib $state(xlib)
        set jid $state(jid)
        set id $state(id)

        unset state
        unset streams(in,$xlib,$jid,$id)
    }
}

###############################################################################
###############################################################################

proc si::connect {stream chunk_size mimetype profile profile_el command} {
    variable transport
    upvar #0 $stream state

    set trans [lsort -unique -index 1 $transport(list)]
    set options {}
    foreach t $trans {
        set name [lindex $t 0]
        if {![info exists transport(allowed,$name)] || \
                $transport(allowed,$name)} {
            lappend options "" $transport(oppos,$name)
        }
    }

    set fields [::xmpp::data::formField field \
                        -var stream-method \
                        -type list-single \
                        -options $options]

    set feature \
        [::xmpp::xml::create feature \
             -xmlns http://jabber.org/protocol/feature-neg \
             -subelement [::xmpp::data::form $fields]]

    set_status [::msgcat::mc "Opening SI connection"]

    ::xmpp::sendIQ $state(xlib) set \
        -query [::xmpp::xml::create si \
                    -xmlns $::NS(si) \
                    -attrs [list id $state(id) \
                                 mime-type $mimetype \
                                 profile $profile] \
                    -subelement $profile_el \
                    -subelement $feature] \
        -to $state(jid) \
        -command [list si::connect_response $stream $chunk_size \
                                            $profile $command]
}

###############################################################################

proc si::connect_response {stream chunk_size profile command status xml} {
    variable transport
    upvar #0 $stream state

    if {![info exists state(id)]} {
        # TODO: It would be good to send some error message to a receiver
        # (but it is not supported by the protocol).
        uplevel #0 $command \
                [list [list 0 [::msgcat::mc "File transfer aborted"]]]
        return
    }

    if {$status != "ok"} {
        uplevel #0 $command [list [list 0 [error_to_string $xml]]]
        return
    }

    ::xmpp::xml::split $xml tag xmlns attrs cdata subels

    set trans [lsort -unique -index 1 $transport(list)]
    set options {}
    foreach t $trans {
        set name [lindex $t 0]
        if {![info exists transport(allowed,$name)] || \
                $transport(allowed,$name)} {
            lappend options $transport(oppos,$name)
        }
    }

    set opts {}

    foreach item $subels {
        ::xmpp::xml::split $item stag sxmlns sattrs scdata ssubels
        if {[string equal $sxmlns $profile]} {
            # TODO
        } elseif {[string equal $sxmlns \
                                http://jabber.org/protocol/feature-neg]} {
            set opts [parse_negotiation_res $item]
        }
    }

    if {[llength $opts] == 1 && [lindex $opts 0] in $options} {
        set name [lindex $opts 0]
        set state(transport) $name
        {*}$transport(connect,$name) $stream $chunk_size $command
        return
    }
    uplevel #0 $command \
            [list [list 0 [::msgcat::mc "Stream method negotiation failed"]]]
}

###############################################################################

proc si::send_data {stream data command} {
    variable transport
    upvar #0 $stream state

    {*}$transport(send,$state(transport)) $stream $data $command
}

###############################################################################

proc si::close {stream} {
    variable transport
    upvar #0 $stream state

    {*}$transport(close,$state(transport)) $stream
    set_status [::msgcat::mc "SI connection closed"]
}

###############################################################################
###############################################################################

proc si::set_readable_handler {stream handler} {
    upvar #0 $stream state

    set state(readable_handler) $handler
}

proc si::set_closed_handler {stream handler} {
    upvar #0 $stream state

    set state(closed_handler) $handler
}

###############################################################################

proc si::recv_data {stream data} {
    upvar #0 $stream state

    debugmsg si "RECV_DATA [list $state(id) $data]"

    append state(data) $data
    {*}$state(readable_handler) $stream
}

###############################################################################

proc si::read_data {stream} {
    upvar #0 $stream state

    set data $state(data)
    set state(data) {}
    return $data
}

###############################################################################

proc si::closed {stream} {
    upvar #0 $stream state

    if {[info exists state(closed_handler)]} {
        {*}$state(closed_handler) $stream
    }
}

###############################################################################

proc si::parse_negotiation {xml} {
    ::xmpp::xml::split $xml tag xmlns attrs cdata subels

    lassign [::xmpp::data::findForm $subels] type form
    set fields [::xmpp::data::parseForm $form]

    foreach {tag field} $fields {
        switch -- $tag {
            field {
                lassign $field \
                        var type label desc required options values media
                if {[string equal $var stream-method]} {
                    set soptions {}
                    foreach {olabel ovalue} $options {
                        lappend soptions $ovalue
                    }
                    return $soptions
                }
            }
        }
    }

    return {}
}

proc si::parse_negotiation_res {xml} {
    ::xmpp::xml::split $xml tag xmlns attrs cdata subels

    lassign [::xmpp::data::findForm $subels] type form
    set fields [::xmpp::data::parseSubmit $form]

    foreach {tag field} $fields {
        switch -- $tag {
            field {
                lassign $field var type label values
                if {[string equal $var stream-method]} {
                    return $values
                }
            }
        }
    }

    return {}
}

###############################################################################

proc si::set_handler {xlib from xml args} {
    variable profiledata
    variable transport

    ::xmpp::xml::split $xml tag xmlns attrs cdata subels

    set iqid [::xmpp::xml::getAttr $args -id]
    set id [::xmpp::xml::getAttr $attrs id]
    set mimetype [::xmpp::xml::getAttr $attrs mime-type]
    set profile [::xmpp::xml::getAttr $attrs profile]
    set stream {}
    set profile_res {}

    set lang [::xmpp::xml::getAttr $args -lang en]

    if {[info exists profiledata($profile)]} {
        foreach item $subels {
            ::xmpp::xml::split $item stag sxmlns sattrs scdata ssubels

            if {[string equal $sxmlns $profile]} {
                return [$profiledata($profile) \
                            $xlib $from $lang $id $mimetype $item \
                            [namespace code [list set_handler_cont $xlib \
                                                  $from $iqid $lang $id \
                                                  $subels]]]
            }
        }
    } else {
        # bad-profile
        return [list error modify bad-request]
    }
}

proc si::set_handler_cont {xlib from iqid lang id subels status xml} {
    variable transport

    if {$status == "error"} {
        ::xmpp::sendIQ $xlib error \
                       -error $xml \
                       -to $from \
                       -id $iqid
        return
    }

    foreach item $subels {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        if {[string equal $xmlns http://jabber.org/protocol/feature-neg]} {
            set options [parse_negotiation $item]

            set trans [lsort -unique -index 1 $transport(list)]
            set myoptions {}
            foreach t $trans {
                set name [lindex $t 0]
                if {![info exists transport(allowed,$name)] || \
                        $transport(allowed,$name)} {
                    lappend myoptions $transport(oppos,$name)
                }
            }

            foreach opt $options {
                if {$opt in $myoptions} {
                    set stream $opt
                    break
                }
            }
        }
    }

    if {![info exists stream]} {
        ::xmpp::sendIQ $xlib error \
                       -error [::xmpp::stanzaerror::error modify bad-request] \
                       -to $from \
                       -id $iqid
        return
    }

    set res_elements {}
    if {$xml != {}} {
        lappend res_elements $xml
    }

    set fields [list stream-method [list $opt]]
    lappend res_elements \
            [::xmpp::xml::create feature \
                    -xmlns http://jabber.org/protocol/feature-neg \
                    -subelement [::xmpp::data::submitForm $fields]]

    set res [::xmpp::xml::create si \
                    -xmlns $::NS(si) \
                    -subelements $res_elements]

    ::xmpp::sendIQ $xlib result \
                   -query $res \
                   -to $from \
                   -id $iqid
}

::xmpp::iq::register set * $::NS(si) si::set_handler

###############################################################################
###############################################################################

proc si::register_transport {name oppos prio default connect send close} {
    variable transport

    lappend transport(list) [list $name $prio]
    set transport(oppos,$name) $oppos
    set transport(connect,$name) $connect
    set transport(send,$name) $send
    set transport(close,$name) $close
    if {$default == "enabled"} {
        set transport(default,$name) 1
    } else {
        set transport(default,$name) 0
    }
}

###############################################################################

proc si::register_profile {profile handler} {
    variable profiledata
    set profiledata($profile) $handler
}

###############################################################################

proc si::setup_customize {} {
    variable transport

    set trans [lsort -unique -index 1 $transport(list)]

    foreach t $trans {
        lassign $t name prio

        custom::defvar transport(allowed,$name) $transport(default,$name) \
        [::msgcat::mc "Enable SI transport %s." $name] \
        -type boolean -group {Stream Initiation}
    }
}

hook::add postload_hook si::setup_customize

###############################################################################

namespace eval si {
    plugins::load [file join plugins si] -uplevel 1
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
