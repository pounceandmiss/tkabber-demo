# fetch_nicknames.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       fetches roster item nickname(s) from vCard and set roster label(s).

namespace eval fetch_nickname {}

proc fetch_nickname::service_request {xlib service} {
    foreach jid [::roster::get_jids $xlib] {
        if {[::xmpp::jid::server $jid] eq [::xmpp::jid::server $service]} {
            user_request $xlib $jid
        }
    }
}

proc fetch_nickname::request_group_nicks {xlib group args} {
    foreach jid [::roster::get_group_jids $xlib $group {*}$args] {
        if {[string equal [::roster::itemconfig $xlib $jid -category] user]} {
            user_request $xlib $jid
        }
    }
}

proc fetch_nickname::user_request {xlib jid} {
    ::xmpp::sendIQ $xlib get \
        -query [::xmpp::xml::create vCard -xmlns vcard-temp] \
        -to $jid \
        -command [list [namespace current]::parse_result $xlib $jid]
}

proc fetch_nickname::parse_result {xlib jid status xml} {
    if {$status ne "ok"} return

    ::xmpp::xml::split $xml tag xmlns attrs cdata subels

    foreach item $subels {
        userinfo::parse_vcard_item $jid $item
    }

    if {[info exists ::userinfo::userinfo(nickname,$jid)] && \
            ![string equal $::userinfo::userinfo(nickname,$jid) ""]} {
        roster::itemconfig $xlib $jid \
                           -name $::userinfo::userinfo(nickname,$jid)
        roster::send_item $xlib $jid
    }
}

proc fetch_nickname::extend_user_menu {m xlib jid} {
    set rjid [roster::find_jid $xlib $jid]
    if {$rjid == ""} {
        set state disabled
    } else {
        set state normal
    }
    $m add command -label [::msgcat::mc "Fetch nickname"] \
        -command [list [namespace current]::user_request $xlib $rjid] \
        -state $state
}

hook::add chat_create_user_menu_hook \
    [namespace current]::fetch_nickname::extend_user_menu 73
hook::add roster_jid_popup_menu_hook \
    [namespace current]::fetch_nickname::extend_user_menu 73

proc fetch_nickname::extend_service_menu {m xlib jid} {
    set rjid [roster::find_jid $xlib $jid]
    if {$rjid == ""} {
        set state disabled
    } else {
        set state normal
    }
    $m add command -label [::msgcat::mc "Fetch user nicknames"] \
        -command [list [namespace current]::service_request $xlib $rjid] \
        -state $state
}

hook::add roster_service_popup_menu_hook \
    [namespace current]::fetch_nickname::extend_service_menu 73

proc fetch_nickname::extend_group_menu {m xlib name} {
    $m add command \
        -label [::msgcat::mc "Fetch nicknames of all users in group"] \
        -command [list [namespace current]::request_group_nicks $xlib $name \
            -nested $::ifacetk::roster::options(nested) \
            -delimiter $::ifacetk::roster::options(nested_delimiter)]
}

hook::add roster_group_popup_menu_hook \
    [namespace current]::fetch_nickname::extend_group_menu

# vim:ft=tcl:ts=8:sw=4:sts=4:et
