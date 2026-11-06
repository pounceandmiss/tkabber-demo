# disco.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements an
#       interface part for the Service Discovery mechanism (XEP-0030).

option add *JDisco.fill $::defaultforeground         widgetDefault

if {$::darktheme} {
    option add *JDisco.featurecolor  LightSteelBlue3 widgetDefault
    option add *JDisco.identitycolor darkseagreen3   widgetDefault
    option add *JDisco.optioncolor   mediumorchid3   widgetDefault
} else {
    option add *JDisco.featurecolor  MidnightBlue    widgetDefault
    option add *JDisco.identitycolor DarkGreen       widgetDefault
    option add *JDisco.optioncolor   DarkViolet      widgetDefault
}

# Disco Browser

namespace eval ::disco::browser {
    variable winid 0

    image create photo ""

    variable options

    # Do not show items number in node title if this number
    # is not greater than 20
    # (It is questionnable whether to add this option to Customize).
    set options(upper_items_bound) 20

    custom::defvar disco_list {} [::msgcat::mc "List of discovered JIDs."] \
            -group Hidden
    custom::defvar node_list {} [::msgcat::mc "List of discovered JID nodes."] \
            -group Hidden
}

###############################################################################

proc ::disco::browser::open_win {xlib jid args} {
    variable winid
    variable curjid
    variable disco_list
    variable node_list
    variable browser

    if {[llength [connections]] == 0} return

    if {$xlib == ""} {
        set xlib [lindex [connections] 0]
    }

    if {$jid == ""} {
        set curjid($winid) [connection_server $xlib]
    } else {
        set curjid($winid) $jid
    }

    set w .disco_$winid
    set wid $winid
    incr winid
    set browser(xlib,$w) $xlib

    add_win $w -title [::msgcat::mc "Service Discovery"] \
               -tabtitle [::msgcat::mc "Discovery"] \
               -raisecmd [list focus $w.tree] \
               -class JDisco \
               -raise 1

    set config(fill)               [option get $w fill          JDisco]
    set config(featurecolor)  [option get $w featurecolor  JDisco]
    set config(identitycolor) [option get $w identitycolor JDisco]
    set config(optioncolor)   [option get $w optioncolor   JDisco]

    bind $w <Destroy> [list [namespace current]::destroy_state %W [double% $w]]

    Frame $w.navigate
    Button $w.navigate.back \
           -text <- \
           -width 3 \
           -command [list [namespace current]::history_move $w 1]
    Button $w.navigate.forward \
           -text -> \
           -width 3 \
           -command [list [namespace current]::history_move $w -1]
    Label $w.navigate.lentry -text [::msgcat::mc "JID:"]
    set c [Combobox $w.navigate.entry \
                -textvariable [namespace current]::curjid($wid) \
                -command [list [namespace current]::go $w] \
                -values $disco_list]
    if {[winfo exists $c.e]} {
        #HACK: For BWidget combobox
        set c $c.e
    }
    DropSite::register $c -droptypes {JID {}} \
             -dropcmd [list [namespace current]::entrydropcmd $w]
    Label $w.navigate.lnode -text [::msgcat::mc "Node:"]
    Combobox $w.navigate.node \
             -textvariable [namespace current]::curnode($wid) \
             -values $node_list \
             -width 20
    Button $w.navigate.browse \
           -text [::msgcat::mc "Browse"] \
           -command [list [namespace current]::go $w]

    bind $w.navigate.entry <Return> [list [namespace current]::go [double% $w]]
    bind $w.navigate.node <Return> [list [namespace current]::go [double% $w]]

    pack $w.navigate.back $w.navigate.forward $w.navigate.lentry -side left
    pack $w.navigate.browse -side right
    pack $w.navigate.entry -side left -expand yes -fill x
    pack $w.navigate.lnode -side left
    pack $w.navigate.node -side left -expand no -fill x
    pack $w.navigate -fill x

    set sw [ScrolledWindow $w.sw]
    set tw [MyTree $w.tree]
    $sw setwidget $tw
    if {[winfo exists $tw.c]} {
        DragSite::register $tw.c \
                -draginitcmd [list [namespace current]::draginitcmd $w]
    } else {
        DragSite::register $tw \
                -draginitcmd [list [namespace current]::draginitcmd $w]
    }

    $tw tag configure feature -foreground $config(featurecolor)
    $tw tag configure identity -foreground $config(identitycolor)
    $tw tag configure option -foreground $config(optioncolor)

    pack $sw -side top -expand yes -fill both
    $tw tag bind Text <Double-ButtonPress-1> [list [namespace current]::activate_node [double% $w] [double% $tw]]
    $tw tag bind Text <<ContextMenu>> [list [namespace current]::textpopup [double% $w] [double% $tw] %x %y]
    # Override the default action which toggles the non-leaf nodes
    bind $tw <Double-ButtonPress-1> break

    # Disable balloons until we'll fine something useful to show in them
    #balloon::setup $tw -command [list [namespace current]::textballoon $w]

    if {[winfo exists $tw.c]} {
        bind $tw.c <Return> [list [namespace current]::activate_node [double% $w] [double% $tw]]
        bind $tw.c <Delete> [list [namespace current]::delete_node [double% $w] [double% $tw]]
    } else {
        $tw tag bind Text <Return> [list [namespace current]::activate_node [double% $w] [double% $tw]]
        $tw tag bind Text <Delete> [list [namespace current]::delete_node [double% $w] [double% $tw]]
        # Override the default action which toggles the non-leaf nodes
        bind $tw <Return> break
    }

    lappend browser(opened) $w
    set browser(opened) [lsort -unique $browser(opened)]
    set browser(required,$w) {}
    set browser(tree,$w) $tw

    set browser(hist,$w) {}
    set browser(histpos,$w) 0

    hook::run open_disco_post_hook $w $sw $tw

    go $w
}

proc ::disco::browser::go {bw} {
    variable browser
    variable disco_list
    variable node_list

    if {[winfo exists $bw]} {
        set jid [$bw.navigate.entry get]
        set node [$bw.navigate.node get]

        history_add $bw [list $jid $node]

        set disco_list [update_combo_list $disco_list $jid 20]
        set node_list [update_combo_list $node_list $node 20]
        $bw.navigate.entry configure -values $disco_list
        $bw.navigate.node configure -values $node_list

        lappend browser(required,$bw) $jid
        set browser(required,$bw) [lsort -unique $browser(required,$bw)]

        disco::request_info $browser(xlib,$bw) $jid -node $node
        disco::request_items $browser(xlib,$bw) $jid -node $node
    }
}

proc ::disco::browser::info_receive \
     {xlib jid node res identities features extras featured_nodes} {
    variable browser

    if {![info exists browser(opened)]} return

    foreach w $browser(opened) {
        if {[winfo exists $w] && $jid in $browser(required,$w)} {
            draw_info $w $xlib $jid $node $res $identities \
                      $features $extras $featured_nodes
        }
    }
}

hook::add disco_info_hook \
          ::disco::browser::info_receive

proc ::disco::browser::draw_info \
     {w xlib jid node res identities features extras featured_nodes} {
    variable browser

    set tw $browser(tree,$w)

    set parent_tag [jid_to_tag [list $jid $node]]
    set tnode [jid_to_tag [list $jid $node]]
    if {[$tw exists $tnode]} {
        lassign [$tw item $tnode -values] type _ _ _ name _ _ nitems
    } else {
        set type item
        set name ""
        set nitems 0
    }
    set data [list $type $xlib $jid $node $name $identities $features $nitems]
    set desc [item_desc $jid $node $name $nitems]
    set icon ""

    add_line $tw $parent_tag $tnode $icon $desc $data -tags {Text}

    if {$res != "ok"} {
        set tnode [jid_to_tag "error info $jid $node"]
        set data [list error_info $xlib $jid]
        set desc [::msgcat::mc "Error getting info: %s" \
                      [error_to_string $identities]]
        set icon ""

        add_line $tw $parent_tag $tnode $icon $desc $data -tags {Text identity}

        remove_old $tw $parent_tag identity   [list $tnode]
        remove_old $tw $parent_tag feature    [list $tnode]
        remove_old $tw $parent_tag extra      [list $tnode]
        remove_old $tw $parent_tag item2      [list $tnode]
        remove_old $tw $parent_tag error_info [list $tnode]
        reorder_node $tw $parent_tag
        return
    }

    set identitynodes {}

    set category ""
    set type ""
    foreach identity $identities {
        set tnode [jid_to_tag "identity $identity $jid $node"]
        lappend identitynodes $tnode
        set name     [get_prop $identity name]
        set category [get_prop $identity category]
        set type     [get_prop $identity type]
        set data [list identity $xlib $jid $node $category $type $name]
        set desc "$name ($category/$type)"
        set icon [item_icon $category $type]

        add_line $tw $parent_tag $tnode $icon $desc $data -tags {Text identity}
    }

    set extranodes {}

    foreach eform $extras {
        foreach {etag extra} $eform {
            lassign $extra var type label values
            if {$type == "hidden"} continue
            set tnode [jid_to_tag "extra $var $jid $node"]
            lappend extranodes $tnode
            set data [list extra $var $xlib $jid $node]
            set value [join $values ", "]
            if {$label != ""} {
                set desc "$label ($var): $value"
            } else {
                set desc "$var: $value"
            }
            set icon ""

            add_line $tw $parent_tag $tnode $icon $desc $data -tags {Text identity}
        }
    }

    set featurenodes {}

    foreach feature $features {
        set tnode [jid_to_tag "feature $feature $jid $node"]
        lappend featurenodes $tnode

        set data [list feature $xlib $jid $node $feature $category $type]
        set desc $feature
        if {[info exists browser(feature_handler_desc,$feature)]} {
            catch { array unset tmp }
            array set tmp $browser(feature_handler_desc,$feature)
            if {[info exists tmp($category)]} {
                set desc "$tmp($category) ($feature)"
            } elseif {[info exists tmp(*)]} {
                set desc "$tmp(*) ($feature)"
            }
        }
        set icon ""

        add_line $tw $parent_tag $tnode $icon $desc $data -tags {Text feature}
    }

    set item2nodes {}

    # Draw all implicit item nodes, which are not received explicitly
    # (don't overwrite node because it can have different name)
    foreach item $featured_nodes {
        set ijid [get_prop $item jid]
        set node [get_prop $item node]
        set name [get_prop $item name]

        set tnode [jid_to_tag [list $ijid $node]]
        lappend item2nodes $tnode

        if {[$tw exists $tnode]} {
            lassign [$tw item $tnode -values] type _ _ _ _ identities features nitems
        } else {
            set type item2
            set identities {}
            set features {}
            set nitems 0
        }
        set data [list item2 $xlib $ijid $node $name $identities $features $nitems]
        set desc [item_desc $ijid $node $name $nitems]
        set icon ""

        if {![$tw exists $tnode] || \
                [lindex [$tw item $tnode -values] 0] != "item"} {
            add_line $tw $parent_tag $tnode $icon $desc $data -tags {Text}
        }
    }

    remove_old $tw $parent_tag identity $identitynodes
    remove_old $tw $parent_tag extra    $extranodes
    remove_old $tw $parent_tag feature  $featurenodes
    remove_old $tw $parent_tag item2    $item2nodes
    remove_old $tw $parent_tag error_info {}
    reorder_node $tw $parent_tag
}

proc ::disco::browser::items_receive {xlib jid node res items} {
    variable browser

    if {![info exists browser(opened)]} return

    foreach w $browser(opened) {
        if {[winfo exists $w] && $jid in $browser(required,$w)} {
            draw_items $w $xlib $jid $node $res $items
        }
    }
}

hook::add disco_items_hook \
          ::disco::browser::items_receive

proc ::disco::browser::draw_items {w xlib jid node res items} {
    variable browser

    set tw $browser(tree,$w)

    set parent_tag [jid_to_tag [list $jid $node]]
    set tnode [jid_to_tag [list $jid $node]]

    if {[$tw exists $tnode]} {
        lassign [$tw item $tnode -values] type _ _ _ name identities features
    } else {
        set type item
        set name ""
        set identities {}
        set features {}
    }
    set nitems [llength $items]
    set data [list $type $xlib $jid $node $name $identities $features $nitems]
    set desc [item_desc $jid $node $name $nitems]
    set icon ""

    add_line $tw $parent_tag $tnode $icon $desc $data -tags {Text}

    if {$res != "ok"} {
        set tnode [jid_to_tag "error items $jid $node"]
        set data [list error_items $xlib $jid]
        set desc [::msgcat::mc "Error getting items: %s" \
                               [error_to_string $items]]
        set icon ""

        add_line $tw $parent_tag $tnode $icon $desc $data -tags {Text}

        remove_old $tw $parent_tag item [list $tnode]
        remove_old $tw $parent_tag error_items [list $tnode]
        reorder_node $tw $parent_tag
        return
    }

    set itemnodes {}

    foreach item $items {
        set ijid [get_prop $item jid]
        set node [get_prop $item node]
        set name [get_prop $item name]

        set tnode [jid_to_tag [list $ijid $node]]

        if {[$tw exists $tnode]} {
            lassign [$tw item $tnode -values] type _ _ _ _ identities features nitems
        } else {
            set type item
            set identities {}
            set features {}
            set nitems 0
        }
        set data [list item $xlib $ijid $node $name $identities $features $nitems]
        set desc [item_desc $ijid $node $name $nitems]
        set icon ""

        lappend itemnodes $tnode

        add_line $tw $parent_tag $tnode $icon $desc $data -tags {Text}
    }
    remove_old $tw $parent_tag item $itemnodes
    remove_old $tw $parent_tag error_items {}

    if {![info exists browser(sort,$w,$parent_tag)]} {
        set browser(sort,$w,$parent_tag) sort
    }
    browser_action $browser(sort,$w,$parent_tag) $w $parent_tag
}

proc ::disco::browser::add_line {tw parent node icon desc data args} {
    if {[$tw exists $node]} {
        if {[$tw parent $node] != $parent && [$tw exists $parent] && \
                $parent != $node} {
            if {[catch {$tw move $node $parent end}]} {
                debugmsg disco "MOVE FAILED: $parent $node"
            } else {
                debugmsg disco "MOVE: $parent $node"
            }
        }
        if {[$tw item $node -values] != $data || [$tw item $node -text] != $desc} {
            debugmsg disco RECONF
            $tw item $node -text $desc -values $data -open 1 -image $icon {*}$args
        }
    } elseif {[$tw exists $parent]} {
        $tw insert $parent end -id $node -text $desc -open 1 -image $icon -values $data {*}$args
    } else {
        $tw insert {} end -id $node -text $desc -open 1 -image $icon -values $data {*}$args
    }
}

proc ::disco::browser::reorder_node {tw node {order {}}} {
    set subnodes [$tw children $node]

    set identities {}
    set features {}
    set extras {}
    set items {}
    foreach sn $subnodes {
        lassign [$tw item $sn -values] kind
        switch -- $kind {
            error_items -
            item        -
            item2       {lappend items      $sn}
            error_info  -
            identity    {lappend identities $sn}
            feature     {lappend features   $sn}
            extra       {lappend extras     $sn}
        }
    }
    if {$order == {}} {
        $tw children $node [concat $identities $extras $features $items]
    } else {
        $tw children $node [concat $identities $extras $features $order]
    }
}

proc ::disco::browser::remove_old {tw node kind newnodes} {
    set subnodes [$tw children $node]

    set items {}
    foreach sn $subnodes {
        lassign [$tw item $sn -values] kind1
        if {$kind == $kind1 && $sn ni $newnodes} {
            $tw delete [list $sn]
        }
    }
}

proc ::disco::browser::item_desc {jid node name nitems} {
    variable options

    if {$node != ""} {
        set snode " \[$node\]"
    } else {
        set snode ""
    }
    if {$nitems > $options(upper_items_bound)} {
        set sitems " - $nitems"
    } else {
        set sitems ""
    }
    if {![string equal $name ""]} {
        return "$name$snode ($jid)$sitems"
    } else {
        return "$jid$snode$sitems"
    }
}

proc ::disco::browser::item_icon {category type} {
    switch -- $category {
        service -
        gateway -
        application {
            if {"browser/$type" in [image names]} {
                return browser/$type
            } else {
                return ""
            }
        }
        default {
            if {"browser/$category" in [image names]} {
                return browser/$category
            } else {
                return ""
            }
        }
    }
}

proc ::disco::browser::textaction {bw tnode} {
    variable disco
    variable browser

    set tw $browser(tree,$bw)
    set data [$tw item $tnode -values]
    set data2 [lassign $data type]
    switch -- $type {
        item -
        item2 {
            lassign $data2 xlib jid node
            goto $bw $jid $node
        }
        feature {
            lassign $data2 xlib jid node feature category subtype
            debugmsg disco $jid
            if {$feature != ""} {
                if {[info exists browser(feature_handler,$feature)]} {
                    if {$browser(feature_handler_node,$feature)} {
                        {*}$browser(feature_handler,$feature) $xlib $jid $node \
                            -category $category -type $subtype
                    } else {
                        {*}$browser(feature_handler,$feature) $xlib $jid \
                            -category $category -type $subtype
                    }
                }
            }
        }
    }
}

proc ::disco::browser::textpopup {bw tw x y} {
    variable browser

    set m .discopopupmenu
    if {[winfo exists $m]} {
        destroy $m
    }
    menu $m -tearoff 0

    $tw selection set [list [$tw identify item $x $y]]
    set tnode [lindex [$tw selection] 0]
    set data [$tw item $tnode -values]

    # Parent node category shouldn't impact node action in theory,
    # but sometimes (e.g. when joining MUC group) it's useful.
    set tparentnode [$tw parent $tnode]
    set parentdata {}
    catch {set parentdata [$tw item $tparentnode -values]}

    hook::run disco_node_menu_hook $m $bw $tnode $data $parentdata

    tk_popup $m [winfo pointerx .] [winfo pointery .]
}

proc ::disco::browser::textpopup_menu_setup {m bw tnode data parentdata} {
    variable browser
    set tw $browser(tree,$bw)

    if {[$m index end] ni {"" none}} {
        $m add separator
    }

    set tparentnode [$tw parent $tnode]

    set data2 [lassign $data type]
    switch -- $type {
        feature {
            $m add command -label [::msgcat::mc "Browse"] \
                -command [list [namespace current]::browser_action browse $bw $tnode]
            $m add separator
        }
        item -
        item2 {
            $m add command -label [::msgcat::mc "Browse"] \
                -command [list [namespace current]::browser_action browse $bw $tnode]
            $m add command -label [::msgcat::mc "Sort items by name"] \
                -command [list [namespace current]::browser_action sort $bw $tnode]
            $m add command -label [::msgcat::mc "Sort items by JID/node"] \
                -command [list [namespace current]::browser_action sortjid $bw $tnode]

            $m add separator
            if {$tparentnode eq {}} {
                set label [::msgcat::mc "Delete current node and subnodes"]
            } else {
                set label [::msgcat::mc "Delete subnodes"]
            }
            $m add command -label $label \
                -command [list [namespace current]::clear $bw $tnode]
        }
        default {
        }
    }

    $m add command -label [::msgcat::mc "Clear window"] \
        -command [list [namespace current]::clearall $bw]
}

hook::add disco_node_menu_hook \
          ::disco::browser::textpopup_menu_setup 100

proc ::disco::browser::clearall {bw} {
    variable browser
    set tw $browser(tree,$bw)

    $tw delete [$tw children {}]
}

proc ::disco::browser::clear {bw tnode} {
    variable browser
    set tw $browser(tree,$bw)

    set tparentnode [$tw parent $tnode]

    set type [lindex [$tw item $tnode -values] 0]

    if {$tparentnode ne {}} {
        if {$type != "item" && $type != "item2"} {
            set tnode $tparentnode
        }
        $tw delete [$tw children $tnode]

        lassign [$tw item $tnode -values] type xlib jid node name
        if {$type == "item" || $type == "item2"} {
            set desc [item_desc $jid $node $name 0]
            $tw item $tnode -text $desc
        }
    } else {
        $tw delete [list $tnode]
    }
}

proc ::disco::browser::activate_node {bw tw} {
    set tnode [lindex [$tw selection] 0]
    if {$tnode != ""} {
        textaction $bw $tnode
    }
}

proc ::disco::browser::delete_node {bw tw} {
    set tnode [lindex [$tw selection] 0]
    if {$tnode != ""} {
        clear $bw $tnode
    }
}

proc ::disco::browser::browser_action {action bw tnode} {
    variable browser

    set tw $browser(tree,$bw)
    set data [$tw item $tnode -values]
    set data2 [lassign $data type]

    switch -glob -- $type/$action {
        item/browse -
        item2/browse -
        feature/browse {
            textaction $bw $tnode
        }

        item/sort -
        item2/sort {
            set browser(sort,$bw,$tnode) sort
            set items {}
            foreach child [$tw children $tnode] {
                set data [lassign [$tw item $child -values] type]
                switch -- $type {
                    item -
                    item2 {
                        lassign $data xlib jid node name
                        lappend items [list $child $name]
                    }
                }
            }
            set neworder {}
            foreach item [lsort -dictionary -index 1 $items] {
                lappend neworder [lindex $item 0]
            }
            reorder_node $tw $tnode $neworder

            foreach child [$tw children $tnode] {
                browser_action $action $bw $child
            }
        }

        item/sortjid -
        item2/sortjid {
            set browser(sort,$bw,$tnode) sortjid
            set items {}
            set items_with_nodes {}
            foreach child [$tw children $tnode] {
                set data [lassign [$tw item $child -values] type]
                switch -- $type {
                    item -
                    item2 {
                        lassign $data xlib jid node
                        if {$node != {}} {
                            lappend items_with_nodes \
                                [list $child "$jid\u0000$node"]
                        } else {
                            lappend items [list $child $jid]
                        }
                    }
                }
            }
            set neworder {}
            foreach item [concat [lsort -dictionary -index 1 $items] \
                                 [lsort -dictionary -index 1 $items_with_nodes]] {
                lappend neworder [lindex $item 0]
            }
            reorder_node $tw $tnode $neworder

            foreach child [$tw children $tnode] {
                browser_action $action $bw $child
            }
        }

        default {
        }
    }
}

# TODO
proc ::disco::browser::textballoon {bw args} {
    variable browser

    set tw $browser(tree,$bw)

    if {[llength $args] == 1} {
        set node [lindex $args 0]
    } else {
        set bd [ttk::style lookup Treeview -borderwidth {} 1]
        set x [expr {[winfo pointerx $tw] - [winfo rootx $tw] - $bd}]
        set y [expr {[winfo pointery $tw] - [winfo rooty $tw] - $bd}]
        set node [$tw identify item $x $y]
        if {$node eq ""} {
            return [list $bw:$node ""]
        }
    }

    if {[catch {set data [$tw item $node -values]}]} {
        return [list $bw:$node ""]
    }

    lassign $data type xlib jid category subtype name version
    lassign $data type xlib jid node name identities features nitems
    if {$type eq "item" || $type eq "item2"} {
        return [list $bw:$node \
                     [item_balloon_text $jid $node $name $nitems]]
    } else {
        return [list $bw:$node ""]
    }
}

proc ::disco::browser::goto {bw jid node} {
    $bw.navigate.entry set $jid
    $bw.navigate.node set $node
    go $bw
}

proc ::disco::browser::get_parent_identities {bw tnode} {
    variable browser

    set tw $browser(tree,$bw)
    return [get_identities $bw [$tw parent $tnode]]
}

proc ::disco::browser::get_identities {bw tnode} {
    variable browser

    set tw $browser(tree,$bw)

    lassign [$tw item $tnode -values] type _ _ _ _ identities
    switch -- $type {
        item -
        item2 {
            return $identities
        }
        default {
            return {}
        }
    }
}

proc ::disco::browser::get_parent_features {bw tnode} {
    variable browser

    set t $browser(tree,$bw)
    return [get_features $bw [$t parent $tnode]]
}

proc ::disco::browser::get_features {bw tnode} {
    variable browser

    set tw $browser(tree,$bw)

    lassign [$tw item $tnode -values] type _ _ _ _ _ features
    switch -- $type {
        item -
        item2 {
            return $features
        }
        default {
            return {}
        }
    }
}

proc ::disco::browser::draginitcmd {bw tw x y top} {
    if {[winfo exists [winfo parent $tw].c]} {
        # HACK for BWidget Tree
        set tw [winfo parent $tw]
    }

    set tnode [lindex [$tw identify item [expr {$x-[winfo rootx $tw]}] \
                                         [expr {$y-[winfo rooty $tw]}]] 0]
    set data [$tw item $tnode -values]
    set data2 [lassign $data type xlib jid node]

    if {$type == "item" || $type == "item2"} {
        if {[set img [$tw item $tnode -image]] != ""} {
            pack [label $top.l -image $img -padx 0 -pady 0]
        }

        set identities [get_identities $bw $tnode]
        if {[llength $identities] > 0} {
            lassign [lindex $identities 0] category type
        }

        if {![info exists category]} {
            # Using parent tag to get conference category.
            # ??? Which else category could be got from parent?
            set identities [get_identities $bw [$tw parent $tnode]]
            if {[llength $identities] > 0} {
                lassign [lindex $identities 0] category type
            }

            if {![info exists category] || ($category != "conference")} {
                # For other JIDs use heuristics from roster code.
                lassign [roster::get_category_and_subtype $xlib $jid] category type
            }
        }

        return [list JID {copy} [list $xlib $jid $category $type "" ""]]
    } else {
        return {}
    }
}

proc ::disco::browser::entrydropcmd {bw target source x y op type data} {
    set jid [lindex $data 1]
    after idle [list [namespace current]::goto $bw $jid ""]
}

proc ::disco::browser::history_move {bw shift} {
    variable browser

    set newpos [expr {$browser(histpos,$bw) + $shift}]

    if {$newpos < 0} {
        return
    }

    if {$newpos >= [llength $browser(hist,$bw)]} {
        return
    }

    set newjidnode [lindex $browser(hist,$bw) $newpos]
    set browser(histpos,$bw) $newpos

    lassign $newjidnode newjid newnode
    $bw.navigate.entry set $newjid
    $bw.navigate.node set $newnode

    disco::request_info $browser(xlib,$bw) $newjid -node $newnode
    disco::request_items $browser(xlib,$bw) $newjid -node $newnode
}

proc ::disco::browser::history_add {bw jid} {
    variable browser

    set browser(hist,$bw) [lreplace $browser(hist,$bw) 0 \
                               [expr {$browser(histpos,$bw) - 1}]]

    set browser(hist,$bw) [linsert $browser(hist,$bw) 0 $jid]
    set browser(histpos,$bw) 0
    debugmsg disco $browser(hist,$bw)
}

proc ::disco::browser::item_balloon_text {jid node name children} {
    variable browser

    set text "$jid"
    set delim ": "
    if {$node ne ""} {
        append text " \[$node\]"
        set delim ": "
    }
    if {$name ne ""} {
        append text "$delim[::msgcat::mc Description:] $name"
        set delim ", "
    }
    append text "\n[::msgcat::mc {Number of children:}] $children"
    return $text
}

proc ::disco::browser::register_feature_handler {feature handler args} {
    variable browser

    set node 0
    set desc ""

    foreach {attr val} $args {
        switch -- $attr {
            -node {set node $val}
            -desc {set desc $val}
        }
    }

    set browser(feature_handler,$feature) $handler
    set browser(feature_handler_node,$feature) $node
    if {$desc != ""} {
        set browser(feature_handler_desc,$feature) $desc
    }
}

proc ::disco::browser::unregister_feature_handler {feature} {
    variable browser

    catch {unset browser(feature_handler,$feature)}
    catch {unset feature_handler_node,$feature)}
    catch {unset browser(feature_handler_desc,$feature)}
}

# Destroy all (global) state assotiated with the given browser window.
# Intended to be bound to a <Destroy> event handler for browser windows.
proc ::disco::browser::destroy_state {bw bw1} {
    variable browser

    if {$bw != $bw1} return

    array unset browser *,$bw
    array unset browser *,$bw,*

    set idx [lsearch -exact $browser(opened) $bw]
    set browser(opened) [lreplace $browser(opened) $idx $idx]
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
