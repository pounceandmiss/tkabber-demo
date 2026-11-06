# info_commands.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements
#       commands /time, /last, /vcard, /version, /ping in chat and groupchat
#       windows.

package require xmpp::ping

namespace eval chatinfo {

    custom::defgroup VCard \
        [::msgcat::mc "vCard display options in chat windows."] \
        -group Chat

    variable vcard_defs \
                   [list fn        [::msgcat::mc "Full name"]               1 \
                         family    [::msgcat::mc "Family name"]             1 \
                         name      [::msgcat::mc "First name"]              1 \
                         middle    [::msgcat::mc "Middle name"]             0 \
                         prefix    [::msgcat::mc "Prefix"]                  0 \
                         suffix    [::msgcat::mc "Suffix"]                  0 \
                         nickname  [::msgcat::mc "Nickname"]                1 \
                         email     [::msgcat::mc "E-mail"]                  1 \
                         url       [::msgcat::mc "Web site"]                1 \
                         jabberid  [::msgcat::mc "JID"]                     1 \
                         uid       [::msgcat::mc "UID"]                     1 \
                         tel_home  [::msgcat::mc "Phone home"]              1 \
                         tel_work  [::msgcat::mc "Phone work"]              1 \
                         tel_voice [::msgcat::mc "Phone voice"]             1 \
                         tel_fax   [::msgcat::mc "Phone fax"]               0 \
                         tel_pager [::msgcat::mc "Phone pager"]             0 \
                         tel_msg   [::msgcat::mc "Phone message recorder"]  0 \
                         tel_cell  [::msgcat::mc "Phone cell"]              1 \
                         tel_video [::msgcat::mc "Phone video"]             0 \
                         tel_bbs   [::msgcat::mc "Phone BBS"]               0 \
                         tel_modem [::msgcat::mc "Phone modem"]             0 \
                         tel_isdn  [::msgcat::mc "Phone ISDN"]              0 \
                         tel_pcs   [::msgcat::mc "Phone PCS"]               0 \
                         tel_pref  [::msgcat::mc "Phone preferred"]         1 \
                         address   [::msgcat::mc "Address"]                 1 \
                         address2  [::msgcat::mc "Address 2"]               0 \
                         city      [::msgcat::mc "City"]                    1 \
                         state     [string trim [::msgcat::mc "State "]]    1 \
                         pcode     [::msgcat::mc "Postal code"]             0 \
                         country   [::msgcat::mc "Country"]                 1 \
                         geo_lat   [::msgcat::mc "Latitude"]                0 \
                         geo_lon   [::msgcat::mc "Longitude"]               0 \
                         orgname   [::msgcat::mc "Organization name"]       1 \
                         orgunit   [::msgcat::mc "Organization unit"]       1 \
                         title     [::msgcat::mc "Title"]                   1 \
                         role      [::msgcat::mc "Role"]                    1 \
                         bday      [::msgcat::mc "Birthday"]                1 \
                         desc      [string trim [::msgcat::mc "About "]]    0]

    variable opt
    variable name
    variable default
    foreach {opt name default} $vcard_defs {
        custom::defvar options($opt) $default \
            [::msgcat::mc "Display %s in chat window when using /vcard command." \
                 $name] \
            -type boolean -group VCard
    }
}

##############################################################################

proc chatinfo::handle_info_commands {chatid user body type} {

    if {[string equal -length 6 "$body " "/time "]} {
        set name [string range $body 6 end]
        set command time
    } elseif {[string equal -length 6 "$body " "/last "]} {
        set name [string range $body 6 end]
        set command last
    } elseif {[string equal -length 7 "$body " "/vcard "]} {
        set name [string range $body 7 end]
        set command vcard
    } elseif {[string equal -length 9 "$body " "/version "]} {
        set name [string range $body 9 end]
        set command version
    } elseif {[string equal -length 6 "$body " "/ping "]} {
        set name [string range $body 6 end]
        set command ping
    } else {
        return
    }

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]
    set jids {}
    set vcard_jids {}

    if {$type eq "groupchat"} {
        if {$name eq ""} {
            set jids [list $jid]
        } else {
            set jids [list "$jid/$name"]
        }

        set vcard_jids $jids
    } else {
        if {$name eq ""} {
            set bare_jid [::xmpp::jid::removeResource $jid]
            set full_jids [::get_jids_of_user $xlib $bare_jid]

            if {[lsearch $full_jids $jid] >= 0} {
                set jids [list $jid]
            } elseif {[llength $full_jids] == 0} {
                set jids [list $jid]
            } else {
                set jids $full_jids
            }

            set vcard_jids [list $bare_jid]
        }
    }

    if {[llength $jids] == 0} {
        lassign [roster_lookup $xlib $name] jids vcard_jids

        if {[llength $jids] == 0} {
            set jids [list $name]
        }
    }

    if {[llength $vcard_jids] == 0} {
        set vcard_jids $jids
    }

    if {$command eq "vcard"} {
        foreach jid $vcard_jids {
            request_vcard $xlib $chatid $jid
        }
    } elseif {$command eq "ping"} {
        foreach jid $jids {
            request_ping $xlib $chatid $jid
        }
    } else {
        foreach jid $jids {
            request_iq $command $xlib $chatid $jid
        }
    }

    return stop
}

hook::add chat_send_message_hook \
    [namespace current]::chatinfo::handle_info_commands 15

##############################################################################

proc chatinfo::roster_lookup {xlib name} {
    set ret {}
    set ret1 {}
    foreach jid [roster::get_jids $xlib] {
        set rname [roster::get_label $xlib $jid]
        if {$rname eq $name} {
            set bare_jid [::xmpp::jid::removeResource $jid]
            set full_jids [::get_jids_of_user $xlib $bare_jid]
            if {[llength $full_jids] > 0} {
                set ret [concat $ret $full_jids]
            } else {
                lappend ret $bare_jid
            }
            lappend ret1 $bare_jid
        }
    }
    return [list [lsort -unique $ret] [lsort -unique $ret1]]
}

##############################################################################

proc chatinfo::info_commands_comps {chatid compsvar wordstart line} {
    upvar 0 $compsvar comps

    set commands [list "/time " "/last " "/vcard " "/version " "/ping "]

    if {!$wordstart} {
        set comps [concat $comps $commands]
    } elseif {![chat::is_groupchat $chatid]} {
        set q 0
        foreach cmd $commands {
            if {[string equal -length [string length $cmd] $cmd $line]} {
                set q 1
                break
            }
        }
        if {!$q} return

        set xlib [chat::get_xlib $chatid]
        set names {}
        foreach jid [roster::get_jids $xlib] {
            lappend names "[roster::get_label $xlib $jid] "
        }
        set comps [concat $comps [lsort -unique $names]]
    }
}

hook::add generate_completions_hook \
    [namespace current]::chatinfo::info_commands_comps

##############################################################################

proc chatinfo::request_iq {type xlib chatid jid} {
    ::xmpp::sendIQ $xlib get \
        -query [::xmpp::xml::create query \
                        -xmlns jabber:iq:$type] \
        -to $jid \
        -command [list [namespace current]::parse_info_iq$type $chatid $jid]
}

##############################################################################

proc chatinfo::request_vcard {xlib chatid jid} {
    ::xmpp::sendIQ $xlib get \
        -query [::xmpp::xml::create vCard \
                        -xmlns vcard-temp] \
        -to $jid \
        -command [list [namespace current]::parse_info_vcard $chatid $jid]
}

##############################################################################

proc chatinfo::get_secs {} {
    return [expr {[clock milliseconds]/1000.0}]
}

proc chatinfo::request_ping {xlib chatid jid} {
    package require xmpp::ping

    set secs [get_secs]

    ::xmpp::ping::ping $xlib \
        -to $jid \
        -command [list [namespace current]::parse_info_ping $chatid $jid $secs]
}

##############################################################################

proc chatinfo::whois {chatid jid} {
    set xlib [chat::get_xlib $chatid]
    set real_jid [muc::get_real_jid $xlib $jid]
    if {$real_jid != ""} {
        return " ($real_jid)"
    } else {
        return ""
    }
}

##############################################################################

proc chatinfo::parse_info_ping {chatid jid secs res child} {

    if {![winfo exists [chat::chat_win $chatid]]} {
        return
    }

    set rjid [whois $chatid $jid]

    if {$res != "ok"} {
        lassign [error_type_condition $child] type condition

        if {$res == "abort" || ($type == "cancel" && \
                                $condition != "feature-not-implemented")} {
            chat::add_message $chatid $jid error \
                [::msgcat::mc "Pong from %s%s: %s" $jid $rjid \
                              [error_to_string $child]] {}

            return
        }
    }

    set csecs [get_secs]
    set psecs [expr {$csecs-$secs}]
    set message [::msgcat::mc "Pong from %s%s: %.2f seconds" $jid $rjid $psecs]
    chat::add_message $chatid $jid info $message {}
}

##############################################################################

proc chatinfo::parse_info_iqtime {chatid jid res child} {

    if {![winfo exists [chat::chat_win $chatid]]} {
        return
    }

    set rjid [whois $chatid $jid]
    if {$res ne "ok"} {
        chat::add_message $chatid $jid error \
            [::msgcat::mc "time %s%s: %s" $jid $rjid \
                          [error_to_string $child]] {}
        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    if {[string equal $xmlns jabber:iq:time]} {
        userinfo::parse_iqtime_item $jid $subels
    }
    set message [::msgcat::mc "time %s%s:" $jid $rjid]
    foreach {i j} [list time [::msgcat::mc "Time:"] \
                    tz   [::msgcat::mc "Time Zone:"] \
                    utc  [::msgcat::mc "UTC:"]] {
        if {[info exists ::userinfo::userinfo($i,$jid)] && \
                 $::userinfo::userinfo($i,$jid) ne ""} {
            append message "\n     $j $::userinfo::userinfo($i,$jid)"
        }
    }
    chat::add_message $chatid $jid info $message {}
}

##############################################################################

proc chatinfo::parse_info_iqlast {chatid jid res child} {

    if {![winfo exists [chat::chat_win $chatid]]} {
        return
    }

    set rjid [whois $chatid $jid]
    if {$res ne "ok"} {
        chat::add_message $chatid $jid error \
            [::msgcat::mc "last %s%s: %s" $jid $rjid [error_to_string $child]] {}
        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    if {[string equal $xmlns jabber:iq:last]} {
        set ::userinfo::userinfo(lastseconds,$jid) \
            [format_time [::xmpp::xml::getAttr $attrs seconds]]
        set ::userinfo::userinfo(lastdesc,$jid) $cdata
    }
    set message [::msgcat::mc "last %s%s:" $jid $rjid]
    foreach {i j} [list lastseconds [::msgcat::mc "Interval:"] \
                    lastdesc    [::msgcat::mc "Description:"]] {
        if {[info exists ::userinfo::userinfo($i,$jid)] && \
                 $::userinfo::userinfo($i,$jid) ne ""} {
            append message "\n     $j $::userinfo::userinfo($i,$jid)"
        }
    }
    chat::add_message $chatid $jid info $message {}
}

##############################################################################

proc chatinfo::parse_info_iqversion {chatid jid res child} {

    if {![winfo exists [chat::chat_win $chatid]]} {
        return
    }

    set rjid [whois $chatid $jid]
    if {$res ne "ok"} {
        chat::add_message $chatid $jid error \
            [::msgcat::mc "version %s%s: %s" $jid $rjid [error_to_string $child]] {}
        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    if {[string equal $xmlns jabber:iq:version]} {
        userinfo::parse_iqversion_item $jid $subels
    }

    set message [::msgcat::mc "version %s%s:" $jid $rjid]
    foreach {i j} [list clientname    [::msgcat::mc "Client:"] \
                    clientversion [::msgcat::mc "Version:"] \
                    os            [::msgcat::mc "OS:"]] {
        if {[info exists ::userinfo::userinfo($i,$jid)] && \
                 $::userinfo::userinfo($i,$jid) ne ""} {
            append message "\n     $j $::userinfo::userinfo($i,$jid)"
        }
    }
    chat::add_message $chatid $jid info $message {}
}

##############################################################################

proc chatinfo::parse_info_vcard {chatid jid res child} {
    variable options
    variable vcard_defs

    if {![winfo exists [chat::chat_win $chatid]]} {
        return
    }

    set rjid [whois $chatid $jid]
    if {$res ne "ok"} {
        chat::add_message $chatid $jid error \
            [::msgcat::mc "vcard %s%s: %s" $jid $rjid [error_to_string $child]] {}
        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    foreach item $subels {
        userinfo::parse_vcard_item $jid $item
    }
    set message [::msgcat::mc "vcard %s%s:" $jid $rjid]
    foreach {def name ignore} $vcard_defs) {
        if {$options($def) && \
                [info exists ::userinfo::userinfo($def,$jid)] && \
                $::userinfo::userinfo($def,$jid) ne ""} {
            append message "\n     $name: $::userinfo::userinfo($def,$jid)"
        }
    }
    chat::add_message $chatid $jid info $message {}
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
