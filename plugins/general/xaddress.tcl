# xaddress.tcl --
#
#       Implementation of XEP-0033: Extended Stanza Addressing
#
#       The sender address is rewritten, but the original address is stored
#       in an additional <x/> element:
#
#       <x xmlns='tkabber:xaddress:store' from='JID' reason='type'/>

set ::NS(xaddress) "http://jabber.org/protocol/address"
set ::NS(xaddress_store) "tkabber:xaddress:store"

namespace eval ::xaddress {
    variable xaddrinfoid 0
    variable names

    array set names [list \
                         ofrom     [::msgcat::mc "Original from"]     \
                         oto       [::msgcat::mc "Original to"]       \
                         replyto   [::msgcat::mc "Reply to"]          \
                         replyroom [::msgcat::mc "Reply to room"]     \
                         noreply   [::msgcat::mc "No reply"]          \
                         to        [::msgcat::mc "To"]                \
                         cc        [::msgcat::mc "Carbon copy"]       \
                         bcc       [::msgcat::mc "Blind carbon copy"] \
                        ]
}

#######################################################
# Common procs

proc ::xaddress::parse_xaddress_fields {xe {elems {}}} {

    ::xmpp::xml::split $xe tag xmlns attrs cdata subels

    if {![string equal $xmlns $::NS(xaddress)]} {
        return {}
    }
    if {![string equal $tag addresses]} {
        return {}
    }

    set res {}

    foreach subel $subels {
        ::xmpp::xml::split $subel stag sxmlns sattrs scdata ssubels

        if {![string equal $stag address]} continue

        set type [::xmpp::xml::getAttr $sattrs type]
        if {[llength $elems] > 0 && $type ni $elems} continue

        set params {}
        foreach elem {jid node uri descr delivered} {
            set value [::xmpp::xml::getAttr $sattrs $elem]
            if {![string equal $value ""]} {
                lappend params $elem $value
            }
        }

        lappend res $type $params
    }
    return $res
}

proc ::xaddress::format_addressinfo_tooltip {type from real_from reason fields} {
    variable names
    set lines {}

    switch -- $reason {
        ofrom {
            lappend lines \
                    [::msgcat::mc "This message was forwarded by %s\n" \
                                  $real_from]
        }
        #replyto -
        #replyroom {
        #    lappend lines \
        #            [::msgcat::mc "This message was sent by %s\n" $real_from]
        #}
    }

    lappend lines [::msgcat::mc "Extended addressing fields:"]
    foreach {type params} $fields {
        array set arparams $params

        if {[info exists names($type)]} {
            set line " $names($type):"
        } else {
            set line " $type:"
        }

        if {[info exists arparams(descr)]} {
            append line " <$arparams(descr)>"
        }

        if {[info exists arparams(jid)]} {
            append line " $arparams(jid)"
            if {[info exists arparams(node)]} {
                append line " [$arparams(node)]"
            }
        } elseif {[info exists arparams(uri)]} {
            append line " $arparams(uri)"
        }

        lappend lines $line
        array unset arparams
    }
    return [join $lines "\n"]
}

######################################################
# Replace original jid. Read README.xaddress
proc ::xaddress::modify_from \
     {vxlib vfrom vid vtype vis_subject vsubject \
      vbody verr vthread vpriority vx} {
    upvar 2 $vxlib xlib
    upvar 2 $vfrom from
    upvar 2 $vtype type
    upvar 2 $vx x

    # those types are supported at now.
    if {$type ni {chat normal groupchat ""}} return

    # Rewrite the from address only if forwarding happens to be from my own JID
    # (from another resource).

    if {![::xmpp::jid::equal [::xmpp::jid::removeResource $from] \
                [::xmpp::jid::removeResource [connection_jid $xlib]]]} {
        return
    }

    foreach xe $x {
        ::xmpp::xml::split $xe tag xmlns attrs cdata subels

        if {[llength [set res [parse_xaddress_fields $xe {ofrom}]]] == 0} continue

        # FIX: now we get only first but what if there are several ofrom fields?
        lassign $res reason attrs1
        set ofrom [::xmpp::xml::getAttr $attrs1 jid]
        if {[string equal $ofrom ""]} return

        # Use the empty tag which can't be received from the outside
        set x [linsert $x 0 [::xmpp::xml::create "" \
                                    -xmlns $::NS(xaddress_store) \
                                    -attrs [list from $from \
                                                 reason $reason]]]
        set from $ofrom
        return
    }
}

hook::add rewrite_message_hook ::xaddress::modify_from

#####################################################################
# Draw special icon and tooltip for xaddress messages in the chat.

proc ::xaddress::draw_xaddress {chatid from type body x} {
    variable xaddrinfoid

    set chatw [chat::chat_win $chatid]

    set real_from ""
    set reason ""
    set image xaddress/info/blue

    foreach xe $x {
        ::xmpp::xml::split $xe tag xmlns attrs cdata subels

        if {$xmlns eq $::NS(xaddress_store) && $tag eq ""} {
            # This auxiliary element was inserted into yhe very beginning of
            # the 'x' list, so we don't have to use a separate loop to
            # extract it

            set real_from [::xmpp::xml::getAttr $attrs from]
            set reason [::xmpp::xml::getAttr $attrs reason]
            set image xaddress/info/green
            continue
        }

        if {[llength [set fields [parse_xaddress_fields $xe]]] == 0} continue

        incr xaddrinfoid
        set label \
            [Label $chatw.xaddrinfo$xaddrinfoid \
                   -image $image \
                   -helptext [format_addressinfo_tooltip \
                                  $type $from $real_from $reason $fields] \
                   -helptype balloon \
                   -bg [$chatw cget -background]]
        $chatw window create end -window $label

        break
    }
}

hook::add draw_message_hook ::xaddress::draw_xaddress 4

##########################################################
# Draw xaddress fields in the new message dialog

proc ::xaddress::process_x_data {rowvar bodyvar f x xlib from id type replyP} {
    upvar 2 $rowvar row
    upvar 2 $bodyvar body
    variable names

    if {!$replyP || [string equal $type error]} {
        return
    }

    set title [join [lrange [split $f .] 0 end-1] .].title

    foreach xe $x {
        ::xmpp::xml::split $xe tag xmlns attrs cdata subels

        # if "from" was modified draw reason and real_from
        if {[string equal $xmlns $::NS(xaddress_store)] && [string equal $tag x]} {
            set real_from [::xmpp::xml::getAttr $attrs from]
            set reason [::xmpp::xml::getAttr $attrs reason]

            switch -- $reason {
                ofrom {
                    grid [Label $title.flabel \
                                -text [::msgcat::mc "Forwarded by:"]] \
                         -column 0 -row 2 -sticky e
                    grid [Label $title.fjid -text $real_from] \
                         -column 1 -row 2 -sticky w
                }
            }
            continue
        }

        if {[llength [set fields [parse_xaddress_fields $xe]]] == 0} continue

        # draw most important xaddress fields
        set other_fields {}
        foreach {type params} $fields {
            array unset aparams
            array set aparams $params
            switch -- $type {
                noreply -
                replyroom -
                replyto {
                    if {![info exist aparams(jid)]} {
                        lappend other_fields $type $params
                        continue
                    }

                    set text ""
                    if {[info exists aparams(descr)]} {
                        append text "<$aparams(descr)> "
                    }
                    append text $aparams(jid)
                    if {[info exists aparams(node)]} {
                        append text " [$aparams(node)]"
                    }

                    grid [Label $f.lxaddr${row} \
                                -text $names($type):] \
                        -column 0 -row $row -sticky e
                    grid [Label $f.xaddr${row} -text $text] \
                        -column 1 -row $row -sticky w

                    incr row
                }
                default {
                    lappend other_fields $type $params
                }
            }
        }

        # draw rest in tooltip
        if {[llength $other_fields] > 0} {

            set label \
                [Label $title.xaddrinfo \
                       -image xaddress/info/green \
                       -helptext [format_addressinfo_tooltip \
                                      $type $from "" "" $other_fields] \
                       -helptype balloon \
                       -bg [$title cget -background]]
            grid $label -row 1 -column 4 -sticky e

        }
    }
    return
}

hook::add message_process_x_hook ::xaddress::process_x_data

# vim:ft=tcl:ts=8:sw=4:sts=4:et
