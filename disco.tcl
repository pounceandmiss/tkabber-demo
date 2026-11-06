# disco.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements an
#       interface part for the Service Discovery mechanism (XEP-0030).

package require xmpp::disco

namespace eval disco {
    variable supported_nodes
    variable supported_features {}
    variable root_nodes {}
    variable additional_items
}

proc disco::new {xlib} {
    variable tokens

    if {![info exists tokens($xlib)]} {
        set tokens($xlib) \
            [::xmpp::disco::new $xlib \
                    -infocommand [namespace code info_query_get_handler] \
                    -itemscommand [namespace code items_query_get_handler]]
    }
}

##############################################################################

proc disco::request_items {xlib jid args} {
    variable tokens

    set node ""
    set handler {}
    set cache no

    foreach {attr val} $args {
        switch -- $attr {
            -node    {set node $val}
            -command {set handler $val}
            -cache   {set cache $val}
        }
    }

    ::xmpp::disco::requestItems $tokens($xlib) $jid \
            -node $node \
            -cache $cache \
            -command [namespace code [list parse_items \
                                           $xlib $jid $node $handler]]
}

proc disco::parse_items {xlib jid node handler status items} {
    if {![string equal $status ok]} {
        if {$handler != ""} {
            {*}$handler status $items
        }
        hook::run disco_items_hook $xlib $jid $node $status $items
        return
    }

    debugmsg disco "ITEMS: [list $items]"

    if {$handler != ""} {
        {*}$handler ok $items
    }
    hook::run disco_items_hook $xlib $jid $node ok $items
    return
}

##############################################################################

proc disco::request_info {xlib jid args} {
    variable tokens

    set node ""
    set handler {}
    set cache no

    foreach {attr val} $args {
        switch -- $attr {
            -node    {set node $val}
            -command {set handler $val}
            -cache   {set cache $val}
        }
    }

    ::xmpp::disco::requestInfo $tokens($xlib) $jid \
            -node $node \
            -cache $cache \
            -command [namespace code [list parse_info \
                                           $xlib $jid $node $handler]]
}

proc disco::parse_info {xlib jid node handler status info} {
    variable additional_nodes

    if {![string equal $status ok]} {
        if {$handler != ""} {
            {*}$handler $status $info {} {}
        }
        hook::run disco_info_hook $xlib $jid $node $status $info {} {} {}
        return
    }

    lassign $info identities features extras
    set featured_nodes {}

    foreach feature $features {
        if {($node == "") && [info exists additional_nodes($feature)]} {
            lappend featured_nodes \
                    [concat [list jid $jid] $additional_nodes($feature)]
        }
    }

    set featured_nodes [lsort -unique $featured_nodes]

    debugmsg disco \
        "INFO: IDENTITIES [list $identities] FEATURES [list $features]\
         EXTRAS [list $extras] FEATURED NODES [list $featured_nodes]"

    if {$handler != ""} {
        {*}$handler ok $identities $features $extras
    }
    hook::run disco_info_hook $xlib $jid $node ok $identities $features \
                              $extras $featured_nodes
    return
}

###############################################################################

proc disco::register_featured_node {feature node name} {
    variable additional_nodes

    set additional_nodes($feature) [list node $node name $name]
}

###############################################################################

proc disco::info_query_get_handler {xlib from node lang} {
    variable supported_nodes
    variable node_handlers
    variable supported_features
    variable feature_handlers
    variable extra_handlers

    if {![string equal $node ""]} {
        if {![info exists supported_nodes($node)]} {
            # Probably temporary node
            set res {error cancel not-allowed}
            hook::run disco_node_reply_hook \
                      res info $node $xlib $from $lang
            return $res
        } else {
            # Permanent node
            return [{*}$node_handlers($node) info $xlib $from $lang]
        }
    } else {
        set identities [list [list category client \
                                   type     pc \
                                   name     Tkabber]]

        set features [lsort -unique [concat [::xmpp::iq::registered $xlib] \
                                            $supported_features]]
        set extras {}

        if {[info exists extra_handlers]} {
            foreach h $extra_handlers {
                set res [{*}$h $xlib $from $lang]
                if {[llength $res] > 0} {
                    lappend extras $res
                }
            }
        }

        return [list result $identities $features $extras]
    }
}

###############################################################################

proc disco::items_query_get_handler {xlib from node lang} {
    variable supported_nodes
    variable node_handlers
    variable root_nodes

    if {![string equal $node ""]} {
        if {![info exists supported_nodes($node)]} {
            # Probably temporary node
            set res {error cancel not-allowed}
            hook::run disco_node_reply_hook \
                      res items $node $xlib $from $lang
            return $res
        } else {
            # Permanent node
            return [{*}$node_handlers($node) items $xlib $from $lang]
        }
    } else {
        set items {}

        set myjid [my_jid $xlib $from]

        foreach node $root_nodes {
            set item [list jid $myjid]
            if {![string equal $supported_nodes($node) ""]} {
                lappend item name \
                        [::trans::trans $lang $supported_nodes($node)]
            }
            if {![string equal $node ""]} {
                lappend item node $node
            }
            lappend items $item
        }

        return [list result $items]
    }
}

###############################################################################

proc disco::register_feature {feature {handler ""}} {
    variable supported_features
    variable feature_handlers

    if {[lsearch $supported_features $feature] < 0} {
        lappend supported_features $feature
    }
    set feature_handlers($feature) $handler
}

###############################################################################

proc disco::unregister_feature {feature} {
    variable supported_features
    variable feature_handlers

    if {[set idx [lsearch $supported_features $feature]] >= 0} {
        set supported_features [lreplace $supported_features $idx $idx]
        unset feature_handlers($feature)
    }
}

###############################################################################

proc disco::register_node {node handler {name ""}} {
    variable root_nodes

    lappend root_nodes $node
    register_subnode $node $handler $name
}

###############################################################################

proc disco::register_subnode {node handler {name ""}} {
    variable supported_nodes
    variable node_handlers

    set supported_nodes($node) $name
    set node_handlers($node) $handler
}

###############################################################################

proc disco::register_extra {handler} {
    variable extra_handlers

    lappend extra_handlers $handler
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
