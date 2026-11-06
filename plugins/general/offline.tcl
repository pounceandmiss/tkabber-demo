# offline.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which implements retrieving oflline messages using a special
#       POP3-like protocol (XEP-0013).

namespace eval offline {
    set ::NS(offline) "http://jabber.org/protocol/offline"

    custom::defvar options(flexible_retrieval) 0 \
        [::msgcat::mc "Retrieve offline messages using POP3-like protocol."] \
        -type boolean -group Messages

}

proc offline::request_headers {xlib} {
    variable options

    if {$options(flexible_retrieval)} {
        ::xmpp::sendIQ $xlib get \
            -query [::xmpp::xml::create offline \
                            -xmlns $::NS(offline)] \
            -command [list [namespace current]::receive_headers $xlib]
    }
}

hook::add connected_hook [namespace current]::offline::request_headers 9

proc offline::receive_headers {xlib res child} {
    if {$res != "ok"} {
        return
    }

    fill_tree $xlib $child
}

proc offline::open_window {} {
    global tcl_platform

    set w .offline_messages

    if {[winfo exists $w]} {
        return
    }

    add_win $w -title [::msgcat::mc "Offline Messages"] \
        -tabtitle [::msgcat::mc "Offline Messages"] \
        -raisecmd [list focus $w.tree] \
        -class JDisco

    if {$tcl_platform(platform) eq "unix" && \
            ![string equal [option get $w disabledForeground JDisco] ""]} {
        set config(seencolor) [option get $w disabledForeground JDisco]
    } else {
        set config(seencolor) [option get $w featurecolor JDisco]
    }
    set config(unseencolor) [option get $w fill JDisco]

    set sw [ScrolledWindow $w.sw]
    set tw [MyTree $w.tree]
    $sw setwidget $tw

    pack $sw -side top -expand yes -fill both

    $tw tag configure seen -foreground $config(seencolor)
    $tw tag configure unseen -foreground $config(unseencolor)

    $tw tag bind Text <<ContextMenu>> \
                [list [namespace current]::message_popup [double% $tw] %x %y]
    $tw tag bind Text <Double-ButtonPress-1> \
                [double% "[namespace current]::message_action fetch $tw \[$tw selection\]"]

    if {[winfo exists $tw.c]} {
        # HACK
        bind $tw.c <Return> \
             [double% "[namespace current]::message_action fetch $tw \[$tw selection\]"]
    } else {
        $tw tag bind Text <Return> \
             [double% "[namespace current]::message_action fetch $tw \[$tw selection\]"]
    }
}

proc offline::fill_tree {xlib xml} {
    ::xmpp::xml::split $xml tag xmlns attrs cdata subels

    if {[llength $subels] == 0} {
        return
    }

    set w .offline_messages

    if {![winfo exists $w]} {
        open_window
    }

    set tw $w.tree

    foreach subel $subels {
        ::xmpp::xml::split $subel stag sxmlns sattrs scdata ssubels

        switch -- $stag {
            item {
                set node     [::xmpp::xml::getAttr $sattrs node]
                set from     [::xmpp::xml::getAttr $sattrs from]
                set category [::xmpp::xml::getAttr $sattrs category]
                set type     [::xmpp::xml::getAttr $sattrs type]
                add_message $tw $xlib $node $from $category $type
            }
        }
    }
}

package require md5

proc offline::add_message {tw xlib node from category type} {
    set jid [connection_jid $xlib]

    set fnode [str2node $jid]
    if {![$tw exists $fnode]} {
        $tw insert {} end -id $fnode -text $jid -open 1 \
            -tags {Text unseen} -image browser/user \
            -values [list nodetype jid xlib $xlib jid $jid unseen 1]
    }

    set snode [str2node $node]
    if {![$tw exists $snode]} {
        if {$type == ""} {
            set t ""
        } else {
            set t " ($type)"
        }
        $tw insert $fnode end -id $snode -text "$category$t from $from \[$node\]" -open 1 \
            -tags {Text unseen} \
            -values [list nodetype node xlib $xlib jid $jid node $node \
                          from $from category $category type $type unseen 1]
        message_update $tw $snode
    }
}

proc offline::str2node {string} {
    set utf8str [encoding convertto utf-8 $string]
    if {[catch { ::md5::md5 -hex $utf8str } ret]} {
        return [::md5::md5 $utf8str]
    } else {
        return $ret
    }
}

proc offline::message_popup {tw x y} {
    $tw selection set [list [$tw identify item $x $y]]
    set node [lindex [$tw selection] 0]

    if {[catch {array set props [$tw item $node -values]}]} {
        return
    }

    set m .offline_popup_menu

    if {[winfo exists $m]} {
        destroy $m
    }

    menu $m -tearoff 0

    switch -- $props(nodetype) {
        jid {
            $m add command -label [::msgcat::mc "Sort by from"] \
                -command [list [namespace current]::message_action sortfrom $tw $node]
            $m add command -label [::msgcat::mc "Sort by node"] \
                -command [list [namespace current]::message_action sortnode $tw $node]
            $m add command -label [::msgcat::mc "Sort by type"] \
                -command [list [namespace current]::message_action sorttype $tw $node]
            $m add command -label [::msgcat::mc "Fetch unseen messages"] \
                -command [list [namespace current]::message_action fetchunseen $tw $node]
            $m add command -label [::msgcat::mc "Fetch all messages"] \
                -command [list [namespace current]::message_action fetch $tw $node]
            $m add command -label [::msgcat::mc "Purge seen messages"] \
                -command [list [namespace current]::message_action purgeseen $tw $node]
            $m add command -label [::msgcat::mc "Purge all messages"] \
                -command [list [namespace current]::message_action purge $tw $node]
        }
        node {
            $m add command -label [::msgcat::mc "Fetch message"] \
                -command [list [namespace current]::message_action fetch $tw $node]
            $m add command -label [::msgcat::mc "Purge message"] \
                -command [list [namespace current]::message_action purge $tw $node]
        }
        default {
            return
        }
    }

    tk_popup $m [winfo pointerx .] [winfo pointery .]
}

proc offline::message_action {action tw node} {
    if {[catch {array set props [$tw item $node -values]}]} {
        return
    }

    switch -glob -- $props(nodetype)/$action {
        node/fetch {
            ::xmpp::sendIQ $props(xlib) get \
                -query [::xmpp::xml::create offline \
                            -xmlns $::NS(offline) \
                            -subelement [::xmpp::xml::create item \
                                            -attrs [list action view \
                                                         node $props(node)]]] \
                -command [list [namespace current]::action_result $action $tw $node]
        }

        node/purge {
            ::xmpp::sendIQ $props(xlib) set \
                -query [::xmpp::xml::create offline \
                            -xmlns $::NS(offline) \
                            -subelement [::xmpp::xml::create item \
                                            -attrs [list action remove \
                                                         node $props(node)]]]] \
                -command [list [namespace current]::action_result $action $tw $node]
        }

        jid/fetch {
            ::xmpp::sendIQ $props(xlib) get \
                -query [::xmpp::xml::create offline \
                            -xmlns $::NS(offline) \
                            -subelement [::xmpp::xml::create fetch]] \
                -command [list [namespace current]::action_result $action $tw $node]
        }

        jid/purge {
            ::xmpp::sendIQ $props(xlib) set \
                -query [::xmpp::xml::create offline \
                            -xmlns $::NS(offline) \
                            -subelement [::xmpp::xml::create purge]] \
                -command [list [namespace current]::action_result $action $tw $node]
        }

        jid/fetchunseen {
            set q 0
            set items {}
            foreach child [$tw children $node] {
                catch {array unset props1}
                if {![catch {array set props1 [$tw item $child -values]}] && \
                        $props1(unseen) > 0} {
                    lappend items [::xmpp::xml::create item \
                                       -attrs [list action view \
                                                    node $props1(node)]]
                } else {
                    set q 1
                }
            }
            if {$q} {
                if {[llength $items] > 0} {
                    ::xmpp::sendIQ $props(xlib) get \
                        -query [::xmpp::xml::create offline \
                                    -xmlns $::NS(offline) \
                                    -subelements $items] \
                        -command [list [namespace current]::action_result $action $tw $node]
                }
            } else {
                message_action fetch $tw $node
            }
        }

        jid/purgeseen {
            if {$props(unseen) > 0} {
                set items {}
                foreach child [$tw children $node] {
                    catch {array unset props1}
                    if {![catch {array set props1 [$tw item $child -values]}]} {
                        if {$props1(unseen) == 0} {
                            lappend items [::xmpp::xml::create item \
                                             -attrs [list action remove \
                                                          node $props1(node)]]
                        }
                    }
                }
                if {[llength $items] > 0} {
                    ::xmpp::sendIQ $props(xlib) set \
                        -query [::xmpp::xml::create offline \
                                    -xmlns $::NS(offline) \
                                    -subelements $items] \
                        -command [list [namespace current]::action_result $action $tw $node]
                }
            } else {
                message_action purge $tw $node
            }
        }

        jid/sortfrom {
            sort_nodes $tw $node from
        }

        jid/sortnode {
            sort_nodes $tw $node node
        }

        jid/sorttype {
            sort_nodes $tw $node category type
        }

        default {
        }
    }
}

proc offline::sort_nodes {tw node type {subtype ""}} {
    set children {}
    foreach child [$tw children $node] {
        catch {unset props}
        array set props [$tw item $child -values]

        if {$subtype == ""} {
            lappend children [list $child $props($type)]
        } else {
            lappend children \
                [list $child [list $props($type) $props($subtype)]]
        }
    }
    set neworder {}
    foreach child [lsort -index 1 $children] {
        lappend neworder [lindex $child 0]
    }
    $tw children $node $neworder
}

proc offline::action_result {action tw node res child} {
    if {$res != "ok"} {
        return
    }

    if {[catch {array set props [$tw item $node -values]}]} {
        return
    }

    switch -glob -- $props(nodetype)/$action {
        node/fetch -
        node/fetchunseen {
            if {$props(unseen)} {
                set props(unseen) 0
                $tw item $node -tags {Text seen} -values [array get props]
                message_update $tw $node
            }
        }

        node/purge {
            set props(unseen) 0
            $tw item $node -tags {Text seen} -values [array get props]
            message_update $tw $node

            $tw delete [list $node]
        }

        node/purgeseen {
            if {!$props(unseen)} {
                action_result purge $tw $node ok {}
            }
        }

        jid/fetch -
        jid/fetchunseen {
            foreach child [$tw children $node] {
                action_result $action $tw $child ok {}
            }
        }

        jid/purge -
        jid/purgeseen {
            foreach child [$tw children $node] {
                action_result $action $tw $child ok {}
            }
            if {[llength [$tw children $node]] == 0} {
                $tw delete [list $node]
            }
        }

        default {
        }
    }
}

proc offline::message_update {tw node} {
    for {set parent [$tw parent $node]} \
            {$parent ne {}} \
            {set parent [$tw parent $parent]} {
        set unseen 0

        foreach child [$tw children $parent] {
            catch {unset props}
            array set props [$tw item $child -values]

            incr unseen $props(unseen)
        }

        catch {unset props}
        array set props [$tw item $parent -values]
        set props(unseen) $unseen

        set text $props(jid)
        set tag seen
        if {$unseen > 0} {
            append text " ($unseen)"
            set tag unseen
        }
        $tw item $parent -text $text -tags [list Text $tag] \
                         -values [array get props]
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
