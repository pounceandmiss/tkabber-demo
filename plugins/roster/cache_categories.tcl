# cache_categories.tcl
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       implements caching servers' categories and type (using service
#       discovery, XEP-0030). It's useful for displaying transports and
#       their contacts in roster.

namespace eval cache_categories {
#   {server1 {category1 type1} server2 {category2 type2}}
    custom::defvar category_and_subtype_list {} \
        [::msgcat::mc "Cached service categories and types (from disco#info)."] \
        -type string -group Hidden

    variable requested_categories
}

##############################################################################

proc cache_categories::fill_cached_categories_and_subtypes {xlib} {
    variable category_and_subtype_list
    variable requested_categories

    catch { array set tmp $category_and_subtype_list }
    set requested_categories($xlib) [array names tmp]
    foreach jid [array names tmp] {
        lassign $tmp($jid) category subtype
        roster::override_category_and_subtype $xlib $jid \
                                              $category $subtype
    }
}

hook::add connected_hook \
    [namespace current]::cache_categories::fill_cached_categories_and_subtypes 5

##############################################################################

proc cache_categories::free_cached_categories_and_subtypes {xlib} {
    variable category_and_subtype_list
    variable requested_categories

    catch { unset requested_categories($xlib) }
}

hook::add disconnected_hook \
    [namespace current]::cache_categories::free_cached_categories_and_subtypes

##############################################################################

proc cache_categories::request_category_and_subtype {xlib jid} {
    variable category_and_subtype_list
    variable requested_categories

    set server [::xmpp::jid::server $jid]
    if {$server in $requested_categories($xlib)} {
        return
    }

    lappend requested_categories($xlib) $server

    ::disco::request_info $xlib $server \
            -cache yes \
            -command [namespace code [list parse_requested_categories \
                                           $xlib $server]]
}

##############################################################################

proc cache_categories::parse_requested_categories \
     {xlib server status identities features extras} {
    variable category_and_subtype_list

    if {$status != "ok"} return

    foreach identity $identities {
        set category [::xmpp::xml::getAttr $identity category]
        set type     [::xmpp::xml::getAttr $identity type]

        roster::override_category_and_subtype $xlib $server $category $type
        lappend category_and_subtype_list $server [list $category $type]

        ::redraw_roster
        break
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
