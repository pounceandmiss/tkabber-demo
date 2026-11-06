# rawxml.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which shows all communications between the client and servers
#       in a special window or tab. The XML stanzas syntax is highlighted.

if {$::darktheme} {
    option add *RawXML.inforeground       #f99393     widgetDefault
    option add *RawXML.outforeground      #add8cc     widgetDefault
    option add *RawXML.intagforeground    #f99393     widgetDefault
    option add *RawXML.inattrforeground   #f99393     widgetDefault
    option add *RawXML.invalueforeground  #e899b5     widgetDefault
    option add *RawXML.incdataforeground  #add8cc     widgetDefault
    option add *RawXML.outtagforeground   #e899b5     widgetDefault
    option add *RawXML.outattrforeground  #e899b5     widgetDefault
    option add *RawXML.outvalueforeground #bbe8bb     widgetDefault
    option add *RawXML.outcdataforeground #add8cc     widgetDefault
} else {
    option add *RawXML.inforeground       DarkRed     widgetDefault
    option add *RawXML.outforeground      DarkBlue    widgetDefault
    option add *RawXML.intagforeground    DarkRed     widgetDefault
    option add *RawXML.inattrforeground   DarkRed     widgetDefault
    option add *RawXML.invalueforeground  Purple4     widgetDefault
    option add *RawXML.incdataforeground  SteelBlue   widgetDefault
    option add *RawXML.outtagforeground   DarkMagenta widgetDefault
    option add *RawXML.outattrforeground  DarkMagenta widgetDefault
    option add *RawXML.outvalueforeground DarkGreen   widgetDefault
    option add *RawXML.outcdataforeground DarkBlue    widgetDefault
}

option add *RawXML.inputheight        4           widgetDefault

namespace eval rawxml {
    custom::defgroup Plugins [::msgcat::mc "Plugins options."] -group Tkabber
    custom::defgroup RawXML \
        [::msgcat::mc "Options for Raw XML Input module,\
                       which allows you to monitor\
                       incoming/outgoing traffic from connection to server\
                       and send custom XML stanzas."] \
        -group Plugins -tag "Raw XML Input"

    custom::defvar options(pretty_print) 1 \
        [::msgcat::mc "Pretty print incoming and outgoing XML stanzas."] \
        -group RawXML -type boolean
    custom::defvar options(indent) 2 \
        [::msgcat::mc "Indentation for pretty-printed XML subtags."] \
        -group RawXML -type integer
    custom::defvar options(view_all_xlibs) 1 \
        [::msgcat::mc "Show stanzas for all (current and past) connections\
                       in Raw XML window."] \
        -group RawXML -type boolean

    variable tabs
    variable rawxml_xlib_jid
    variable rawxml_xlib
}


if {![catch {clock milliseconds}]} {
    proc rawxml::timestamp {} {
        set ms [clock milliseconds]
        set seconds [expr {$ms/1000}]
        set fraction [format %03d [expr {$ms%1000}]]
        return [clock format $seconds -format %T].$fraction
    }
} else {
    proc rawxml::timestamp {} {
        clock format [clock seconds] -format %T
    }
}


proc rawxml::format_comment {xlib prefix} {
    set id "($xlib)"
    catch {set id "($xlib, [connection_jid $xlib])"}
    set safe_id [string map { -- -&#0045; } $id]

    return "<!-- [timestamp] $prefix $safe_id -->"
}


proc rawxml::handle_inout {xlib dir type msg} {
    variable options

    set w .rawxml
    if {![winfo exists $w]} return

    if {$options(pretty_print) && $type == "xml"} {
        handle_inout_x $xlib $dir $msg
        return
    } elseif {$type == "xml"} {
        set msg [::xmpp::xml::toText $msg]
    }

    switch -- $dir {
        output {
            set prefix OUT
            set tag out
        }
        default {
            set prefix IN
            set tag in
        }
    }

    set dump $w.dump
    $dump configure -state normal

    set scroll [expr {[lindex [$dump yview] 1] == 1}]

    $dump insert end \
        [format_comment $xlib $prefix]\n [list xlib$xlib] \
        $msg [list $tag xlib$xlib]

    if {![$dump compare "end -1 chars linestart" == "end -1 chars"]} {
        $dump insert end "\n" [list xlib$xlib]
    }

    if {$scroll} {
        after idle [list $dump yview moveto 1]
    }

    $dump configure -state disabled
}

proc rawxml::handle_inout_x {xlib dir xml} {
    variable options

    set w .rawxml
    if {![winfo exists $w]} return
    if {!$options(pretty_print)} return

    switch -- $dir {
        output {
            set prefix OUT
            set tag out
        }
        default {
            set prefix IN
            set tag in
        }
    }

    set dump $w.dump
    $dump configure -state normal

    set scroll [expr {[lindex [$dump yview] 1] == 1}]

    $dump insert end [format_comment $xlib $prefix]\n [list xlib$xlib]

    pretty_print $dump $xml "" $tag $xlib

    if {![$dump compare "end -1 chars linestart" == "end -1 chars"]} {
        $dump insert end "\n" [list xlib$xlib]
    }

    if {$scroll} {
        $dump see end
    }

    $dump configure -state disabled
}

proc rawxml::pretty_print {t xmldata prefix tag {xlib {}} {pxmlns jabber:client}
            {prefixes {xml xml http://etherx.jabber.org/streams stream}}} {
    variable options
    variable tabs
    variable rawxml_xlib

    ::xmpp::xml::split $xmldata stag xmlns attrs cdata subels

    array set p $prefixes
    set ps {}
    foreach ns [array names p] {
        lappend ps $p($ns)
    }
    set attrs1 {}
    foreach {attr value} $attrs {
        set l [::split $attr :]
        if {[llength $l] > 1} {
            set axmlns [join [lrange $l 0 end-1] :]
            set aattr [lindex $l end]

            if {[string equal $axmlns $xmlns]} {
                lappend attrs1 $aattr $value
            } elseif {[info exists p($axmlns)]} {
                lappend attrs1 $p($axmlns):$aattr $value
            } else {
                set p($axmlns) [::xmpp::xml::FindNewPrefix $ps]
                lappend attrs1 xmlns:$p($axmlns) $axmlns $p($axmlns):$aattr $value
            }
        } else {
            lappend attrs1 $attr $value
        }
    }

    if {$pxmlns != $xmlns && $xmlns != ""} {
        if {![info exists p($xmlns)]} {
            lappend attrs1 xmlns $xmlns
            set pxmlns $xmlns
        } else {
            set stag $p($xmlns):$stag
        }
    }

    $t insert end "$prefix<" [list xlib$xlib] $stag [list ${tag}tag xlib$xlib]
    if {[llength $attrs1] != 0} {
        set arr_index "$prefix<$stag "
        if {![info exists tabs($arr_index)]} {
            set tabs($arr_index) [font measure [$t cget -font] $arr_index]
        }
        $t tag configure $arr_index -tabs [list $tabs($arr_index)]

        set attrs2 [lassign $attrs1 attr value]
        if {$tag == "template" && $attr == "id" && $value == "" && $rawxml_xlib!=""} {
            set value [::xmpp::packetID $rawxml_xlib]
        }
        $t insert end \
            " $attr" [list ${tag}attr xlib$xlib] \
            "=" [list xlib$xlib] \
            "'[::xmpp::xml::Escape $value]'" [list ${tag}value xlib$xlib]
        foreach {attr value} $attrs2 {
            if {$tag == "template" && $attr == "id" && $value == "" && $rawxml_xlib!=""} {
                set value [::xmpp::packetID $rawxml_xlib]
            }
            $t insert end \
                "\n\t$attr" [list ${tag}attr $arr_index xlib$xlib]\
                "=" [list xlib$xlib] \
                "'[::xmpp::xml::Escape $value]'" [list ${tag}value xlib$xlib]
        }
    }
    if {$cdata == "" && [llength $subels] == 0} {
        $t insert end "/>\n" [list xlib$xlib]
        return
    } else {
        $t insert end ">" [list xlib$xlib]
    }

    if {[llength $subels] == 0} {
        $t insert end [::xmpp::xml::Escape $cdata] [list ${tag}cdata xlib$xlib]
        $t insert end "</" [list xlib$xlib] $stag [list ${tag}tag xlib$xlib] ">\n" [list xlib$xlib]
    } else {
        $t insert end "\n" [list xlib$xlib]
        foreach subdata $subels {
            pretty_print $t $subdata \
                $prefix[string repeat " " $options(indent)] $tag $xlib \
                $pxmlns [array get p]
        }
        $t insert end "$prefix</" [list xlib$xlib] $stag [list ${tag}tag xlib$xlib] ">\n" [list xlib$xlib]
    }
}

hook::add log_hook [namespace current]::rawxml::handle_inout

proc rawxml::raisecmd {} {
    focus [Wrapped .rawxml.input]
}

proc rawxml::open_window {} {
    variable rawxml_xlib
    variable rawxml_xlib_jid
    set w .rawxml
    if {[winfo exists $w]} {
        return
    }

    add_win $w -title [::msgcat::mc "Raw XML"] \
               -tabtitle [::msgcat::mc "Raw XML"] \
               -class RawXML \
               -raisecmd [list [namespace current]::raisecmd] \
               -raise 1


    set tools [Frame $w.tools]
    pack $tools -side top -anchor w -fill x

    #Checkbutton $tools.pp -text [::msgcat::mc "Pretty print XML"] \
    #        -variable [namespace current]::options(pretty_print)
    #pack $tools.pp -side left -anchor w

    Menubutton $tools.templates -text [::msgcat::mc "Templates"] \
                                -menu .rawxml.tools.templates.root
    pack $tools.templates -side left -anchor w

    create_template_menu

    Button $tools.clear -text [::msgcat::mc "Clear"] \
        -command "
                [list $w.dump] configure -state normal
                [list $w.dump] delete 0.0 end
                [list $w.dump] configure -state disabled
        "
    pack $tools.clear -side left -anchor w

    set connection_jids {}
    foreach c [connections] {
        lappend connection_jids [connection_jid $c]
    }
    set rawxml_xlib [lindex [connections] 0]
    set rawxml_xlib_jid [lindex $connection_jids 0]
    Label $tools.lconnection -text [::msgcat::mc "Connection:"]
    Combobox $tools.connection -textvariable [namespace current]::rawxml_xlib_jid \
                               -values $connection_jids \
                               -editable false \
                               -modifycmd [namespace current]::select_xlib

    Checkbutton $tools.allxlibs -variable [namespace current]::options(view_all_xlibs) \
                                -command [namespace current]::select_xlib \
                                -text [::msgcat::mc "Show all connections"]

    if {[llength $connection_jids] > 1} {
        pack $tools.lconnection -side left -anchor w
        pack $tools.connection -side left -anchor w
    }

    pack $tools.allxlibs -side left -anchor w

    PanedWin $w.pw -orient vertical
    pack $w.pw -fill both -expand yes

    set uw [PanedWinAdd $w.pw -weight 1]
    set dw [PanedWinAdd $w.pw -weight 0]

    set isw [ScrolledWindow $w.isw -scrollbar vertical]
    pack $isw -side bottom -fill both -expand yes -in $dw
    set input [textUndoable $w.input \
                   -height [option get $w inputheight RawXML]]
    $isw setwidget $input
    [winfo parent $dw] configure -height [winfo reqheight $input]

    set sw [ScrolledWindow $w.sw -scrollbar vertical]
    pack $sw -side top -fill both -expand yes -in $uw
    set dump [Text $w.dump]
    $sw setwidget $dump

    $dump configure -state disabled

    bind [Wrapped $input] <Control-Key-Return> "
        [namespace current]::send_xml
        break"

    $dump tag configure in \
        -foreground [option get $w inforeground RawXML]
    $dump tag configure out \
        -foreground [option get $w outforeground RawXML]

    $dump tag configure intag \
        -foreground [option get $w intagforeground RawXML]
    $dump tag configure inattr \
        -foreground [option get $w inattrforeground RawXML]
    $dump tag configure invalue \
        -foreground [option get $w invalueforeground RawXML]
    $dump tag configure incdata \
        -foreground [option get $w incdataforeground RawXML]

    $dump tag configure outtag \
        -foreground [option get $w outtagforeground RawXML]
    $dump tag configure outattr \
        -foreground [option get $w outattrforeground RawXML]
    $dump tag configure outvalue \
        -foreground [option get $w outvalueforeground RawXML]
    $dump tag configure outcdata \
        -foreground [option get $w outcdataforeground RawXML]

    variable history
    bind [Wrapped $input] <Control-Key-Up> \
        [list [namespace current]::history_move 1]
    bind [Wrapped $input] <Control-Key-Down> \
        [list [namespace current]::history_move -1]

    set history(stack) [list {}]
    set history(pos) 0

    regsub -all %W [bind Text <Prior>] [double% [Wrapped $dump]] prior_binding
    regsub -all %W [bind Text <Next>]  [double% [Wrapped $dump]] next_binding
    bind [Wrapped $input] <Meta-Prior> $prior_binding
    bind [Wrapped $input] <Meta-Next> $next_binding
    bind [Wrapped $input] <Alt-Prior> $prior_binding
    bind [Wrapped $input] <Alt-Next> $next_binding

    hook::run open_rawxml_post_hook $w
}

proc rawxml::select_xlib {} {
    variable rawxml_xlib_jid
    variable rawxml_xlib
    variable options
    set w .rawxml.dump

    set rawxml_xlib {}
    foreach c [connections] {
        if {[connection_jid $c] == $rawxml_xlib_jid} {
            set rawxml_xlib $c
            break
        }
    }

    foreach tag [lsearch -all -glob -inline [$w tag names] xlib*] {
        set elide [expr {"xlib$rawxml_xlib" != $tag && !$options(view_all_xlibs) \
                   && $rawxml_xlib != ""}]
        $w tag configure $tag -elide $elide
    }
}

proc rawxml::update_xlib_choice {action xlib} {
    variable rawxml_xlib_jid
    variable rawxml_xlib

    set tools .rawxml.tools
    set combobox $tools.connection
    if {![winfo exists $combobox]} return

    set connection_jids [lindex [$combobox configure -values] 4]
    set connection_jid [connection_jid $xlib]
    switch $action {
        add {
            lappend connection_jids $connection_jid
            if {[llength $connection_jids] == 1} {
                set rawxml_xlib_jid $connection_jid
                set rawxml_xlib $xlib
            }
        }
        remove {
            set idx [lsearch -exact $connection_jids $connection_jid]
            set connection_jids [lreplace $connection_jids $idx $idx]
            if {$rawxml_xlib == $xlib} {
                set rawxml_xlib [lindex [connections] 0]
                if {$rawxml_xlib != ""} {
                    set rawxml_xlib_jid [connection_jid $rawxml_xlib]
                } else {
                    set rawxml_xlib_jid ""
                }
                select_xlib
            }
        }
    }
    $combobox configure -values $connection_jids

    if {[llength $connection_jids] > 1} {
        pack $tools.lconnection -side left -anchor w -before $tools.allxlibs
        pack $combobox -side left -anchor w -before $tools.allxlibs
    } else {
        pack forget $tools.lconnection $combobox
    }
}

hook::add connected_hook [list [namespace current]::rawxml::update_xlib_choice add]
hook::add disconnected_hook [list [namespace current]::rawxml::update_xlib_choice remove]

proc rawxml::history_move {shift} {
    variable history

    set newpos [expr $history(pos) + $shift]

    if {!($newpos < 0 || $newpos >= [llength $history(stack)])} {
        set iw .rawxml.input
        set body [$iw get 1.0 "end -1 chars"]

        if {$history(pos) == 0} {
            set history(stack) \
                [lreplace $history(stack) 0 0 $body]
        }

        set history(pos) $newpos
        set newbody [lindex $history(stack) $newpos]
        $iw delete 1.0 end
        $iw insert 0.0 $newbody
    }
}

proc rawxml::send_xml {} {
    variable history
    variable rawxml_xlib

    set input .rawxml.input
    set xml [$input get 0.0 "end - 1c"]

    set history(stack) [linsert $history(stack) 1 $xml]
    set history(pos) 0

    if {[llength [connections]] == 0} {
        return -code error [::msgcat::mc "Not connected"]
    } else {
        ::xmpp::outText $rawxml_xlib $xml
    }
    $input delete 1.0 end
}


proc rawxml::setup_menu {} {
    catch {
        set m [.mainframe getmenu debug]

        $m add command -label [::msgcat::mc "Open raw XML window"] \
            -command [namespace current]::open_window
    }
}
hook::add finload_hook [namespace current]::rawxml::setup_menu


proc rawxml::add_template_group {parent group name} {
    set m .rawxml.tools.templates.$group
    set mparent .rawxml.tools.templates.$parent

    if {![winfo exists $m]} {
        menu $m -tearoff 0
    }

    $mparent add cascade -label $name -menu $m
}

proc rawxml::add_template {group name xmldata} {
    set m .rawxml.tools.templates.$group
    set input .rawxml.input

    $m add command -label $name \
        -command [list [namespace current]::pretty_print \
                      $input $xmldata "" template]
}


proc rawxml::create_template_menu {} {
    if {[winfo exists .rawxml.tools.templates.root]} {
        destroy .rawxml.tools.templates.root
    } else {
        menu .rawxml.tools.templates.root -tearoff 0
    }

    add_template_group root message [::msgcat::mc "Message"]

    add_template message [::msgcat::mc "Normal message"] \
        [::xmpp::xml::create message \
             -attrs {to "" type normal} \
             -subelement [::xmpp::xml::create body -cdata " "]]

    add_template message [::msgcat::mc "Chat message"] \
        [::xmpp::xml::create message \
             -attrs {to "" type chat} \
             -subelement [::xmpp::xml::create body -cdata " "]]

    add_template message [::msgcat::mc "Headline message"] \
        [::xmpp::xml::create message \
             -attrs {to "" type headline} \
             -subelement [::xmpp::xml::create subject -cdata " "] \
             -subelement [::xmpp::xml::create body -cdata " "] \
             -subelement [::xmpp::xml::create x \
                                -xmlns jabber:x:oob \
                                -subelement [::xmpp::xml::create url -cdata " "] \
                                -subelement [::xmpp::xml::create desc -cdata " "]]]

    add_template_group root presence [::msgcat::mc "Presence"]

    add_template presence [::msgcat::mc "Available presence"] \
        [::xmpp::xml::create presence \
             -attrs {to ""} \
             -subelement [::xmpp::xml::create status -cdata " "] \
             -subelement [::xmpp::xml::create show -cdata " "]]

    add_template presence [::msgcat::mc "Unavailable presence"] \
        [::xmpp::xml::create presence \
             -attrs {to "" type unavailable} \
             -subelement [::xmpp::xml::create status -cdata " "]]

    add_template_group root iq [::msgcat::mc "IQ"]

    add_template iq [::msgcat::mc "Generic IQ"] \
        [::xmpp::xml::create iq \
             -attrs {to "" type "" id ""} \
             -subelement [::xmpp::xml::create query \
                                -xmlns ""]]

    add_template iq "jabber:iq:time get" \
        [::xmpp::xml::create iq \
             -attrs {to "" type get id ""} \
             -subelement [::xmpp::xml::create query \
                                -xmlns jabber:iq:time]]

    add_template iq "jabber:iq:version get" \
        [::xmpp::xml::create iq \
             -attrs {to "" type get id ""} \
             -subelement [::xmpp::xml::create query \
                                -xmlns jabber:iq:version]]

    add_template iq "jabber:iq:last get" \
        [::xmpp::xml::create iq \
             -attrs {to "" type get id ""} \
             -subelement [::xmpp::xml::create query \
                                -xmlns jabber:iq:last]]

    add_template_group iq pubsub [::msgcat::mc "Pub/sub"]

    pubsub_template [::msgcat::mc "Create node"] set \
        [::xmpp::xml::create create \
             -attrs {node ""}]
    pubsub_template [::msgcat::mc "Publish node"] set \
        [::xmpp::xml::create publish \
             -attrs {node ""} \
             -subelement [::xmpp::xml::create item]]
    pubsub_template [::msgcat::mc "Retract node"] set \
        [::xmpp::xml::create retract \
             -attrs {node ""} \
             -subelement [::xmpp::xml::create item]]
    pubsub_template [::msgcat::mc "Subscribe to a node"] set \
        [::xmpp::xml::create subscribe \
             -attrs {node "" jid ""}]
    pubsub_template [::msgcat::mc "Unsubscribe from a node"] set \
        [::xmpp::xml::create unsubscribe \
             -attrs {node "" jid ""}]
    pubsub_template [::msgcat::mc "Get items"] get \
        [::xmpp::xml::create items \
             -attrs {node ""}]
}

proc rawxml::pubsub_template {name type subtag} {
    add_template pubsub $name \
        [::xmpp::xml::create iq \
             -attrs [list to "" type $type id ""] \
             -subelement [::xmpp::xml::create pubsub \
                                -xmlns http://jabber.org/protocol/pubsub \
                                -subelement $subtag]]
}

##############################################################################

proc rawxml::restore_window {args} {
    open_window
}

proc rawxml::save_session {vsession} {
    upvar 2 $vsession session
    global usetabbar

    # We don't need JID at all, so make it empty (special case)
    set user     ""
    set server   ""
    set resource ""

    # TODO
    if {!$usetabbar} return

    set prio 0
    foreach page [.nb pages] {
        set path [ifacetk::nbpath $page]

        if {[string equal $path .rawxml]} {
            lappend session [list $prio $user $server $resource \
                [list [namespace current]::restore_window] \
            ]
        }
        incr prio
    }
}

hook::add save_session_hook [namespace current]::rawxml::save_session

# vim:ft=tcl:ts=8:sw=4:sts=4:et
