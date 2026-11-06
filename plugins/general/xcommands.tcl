# xcommands.tcl --
#
#       Ad-Hoc Commands support (XEP-0050)

##########################################################################

namespace eval xcommands {
    variable winid 0
}

##########################################################################

proc xcommands::execute {xlib jid node args} {
    set category automation
    foreach {key val} $args {
        switch -- $key {
            -category { set category $val }
        }
    }
    if {$category != "automation"} return

    set vars [list action execute]
    if {$node != ""} {
        lappend vars node $node
    }

    ::xmpp::sendIQ $xlib set \
        -query [::xmpp::xml::create command \
                        -xmlns $::NS(commands) \
                        -attrs $vars] \
        -command [list [namespace current]::execute_result $xlib $jid $node] \
        -to $jid
}

##########################################################################

proc xcommands::execute_result {xlib jid node res child} {
    variable winid

    if {[string equal $res error]} {
        incr winid
        set w .xcommands_err$winid

        if {[winfo exists $w]} {
            destroy $w
        }

        MessageDlg $w -aspect 50000 -icon error \
            -message [format \
                          [::msgcat::mc "Error executing command: %s"] \
                          [error_to_string $child]] \
            -type user -buttons ok -default 0 -cancel 0
        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    set node [::xmpp::xml::getAttr $attrs node]
    set sessionid [::xmpp::xml::getAttr $attrs sessionid]
    set status [::xmpp::xml::getAttr $attrs status]

    draw_window $xlib $jid $node $sessionid $status $subels
}

##########################################################################

proc xcommands::draw_window {xlib jid node sessionid status xmldata} {
    variable winid

    lassign [find_note $xmldata] type note
    lassign [find_actions $xmldata] actions execute

    # Only jabber:x:data payloads are supported
    lassign [::xmpp::data::findForm $xmldata] type form
    set xdata [::xmpp::data::parseForm $form]

    switch -- $status {
        executing -
        completed { }
        canceled -
        default { return }
    }

    incr winid
    set w .xcommands$winid

    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -transient 0 \
              -modal none  \
              -anchor e    \
              -class XData \
              -default 0   \
              -cancel 1
    set geometry [option get $w geometry XData]
    if {$geometry != ""} {
        wm geometry $w $geometry
    }

    set sw [ScrolledWindow $w.sw]
    set sf [ScrollableFrame $w.fields -constrainedwidth yes]
    set f [$sf getframe]
    $sw setwidget $sf

    set nf [Frame $w.note]

    pack_note $nf $type $note
    set focus [data::fill_fields_x $f $xdata]

    switch -- $status {
        executing {
            if {[llength $actions] == 0 || \
                    ([llength $actions] == 1 && "complete" in $actions)} {
                $w add -text [::msgcat::mc "Submit"] \
                    -command [list [namespace current]::execute_window \
                                   $w $xlib $jid $node $sessionid complete \
                                   [list [namespace current]::complete_result]]
                $w add -text [::msgcat::mc "Cancel"] \
                    -command [list [namespace current]::cancel_window \
                                   $w $xlib $jid $node $sessionid]
                $w configure -default 0
                set cancel 1
            } else {
                $w add -text [::msgcat::mc "Prev"] \
                    -state disabled \
                    -command [list [namespace current]::execute_window \
                                   $w $xlib $jid $node $sessionid prev \
                                   [list [namespace current]::next_result]]
                $w add -text [::msgcat::mc "Next"] \
                    -state disabled \
                    -command [list [namespace current]::execute_window \
                                   $w $xlib $jid $node $sessionid next \
                                   [list [namespace current]::next_result]]
                $w add -text [::msgcat::mc "Finish"] \
                    -state disabled \
                    -command [list [namespace current]::execute_window \
                                   $w $xlib $jid $node $sessionid complete \
                                   [list [namespace current]::complete_result]]
                $w add -text [::msgcat::mc "Cancel"] \
                    -command [list [namespace current]::cancel_window \
                                   $w $xlib $jid $node $sessionid]
                set_default_button $w $actions $execute
                set cancel 3

            }
        }
        completed {
            $w add -text [::msgcat::mc "Close"] \
                -command [list [namespace current]::close_window $w]
            $w configure -default 0
            set cancel 0
        }
    }
    # Can't configure -cancel option because of bug in BWidget
    # $w configure -cancel $cancel
    bind $w <Escape> [list $w.bbox invoke $cancel]
    bind $f <Destroy> [list data::cleanup %W]

    bindscroll $f $sf

    pack $nf -side top -expand no -fill x -padx 2m -pady 0m -in [$w getframe]
    pack $sw -side top -expand yes -fill both -padx 2m -pady 2m -in [$w getframe]

    update idletasks
    $nf configure -width [expr {[winfo reqwidth $f] + [winfo pixels $f 1c]}]

    if {$focus != ""} {
        $w draw $focus
    } else {
        $w draw
    }

    return $w
}

##########################################################################

proc xcommands::execute_window {w xlib jid node sessionid action cmd} {
    # Send requested data and wait for result

    set vars [list sessionid $sessionid action $action]
    if {$node != ""} {
        lappend vars node $node
    }

    set f [$w.fields getframe]

    ::xmpp::sendIQ $xlib set \
        -query [::xmpp::xml::create command \
                        -xmlns $::NS(commands) \
                        -attrs $vars \
                        -subelement [::xmpp::data::submitForm [data::get_fields $f]]] \
        -command [list $cmd $w $xlib $jid $node $sessionid] \
        -to $jid
}

##########################################################################

proc xcommands::pack_note {fr type note} {
    set mf $fr.msg
    if {[winfo exists $mf]} {
        destroy $mf
    }

    if {$note == ""} return

    switch -- $type {
        warn {
            set msg [::msgcat::mc "Warning:"]
        }
        error {
            set msg [::msgcat::mc "Error:"]
        }
        default {
            set msg [::msgcat::mc "Info:"]
        }
    }
    Message $mf -text "$msg $note" -aspect 50000 -width 0
    pack $mf
}

##########################################################################

proc xcommands::set_default_button {bbox actions execute} {
    set default -1
    foreach action $actions {
        switch -- $action {
            prev {
                $bbox itemconfigure 0 -state normal
                if {$default == -1} {
                    set default 0
                }
            }
            next {
                $bbox itemconfigure 1 -state normal
                set default 1
            }
            complete {
                $bbox itemconfigure 2 -state normal
                if {$default == -1 || $default == 0} {
                    set default 2
                }
            }
        }
    }
    if {$default != -1} {
        $bbox configure -default $default
    } else {
        $bbox itemconfigure 1 -state normal
        $bbox configure -default 1
    }
    switch -- $execute {
        prev {
            $bbox itemconfigure 0 -state normal
            $bbox configure -default 0
        }
        next {
            $bbox itemconfigure 1 -state normal
            $bbox configure -default 1
        }
        complete {
            $bbox itemconfigure 2 -state normal
            $bbox configure -default 2
        }
    }
}

##########################################################################

proc xcommands::next_result {w xlib jid node sessionid res child} {
    variable winid

    set f [$w.fields getframe]

    foreach cw [winfo children $f] {
        destroy $cw
    }

    data::cleanup $f

    if {[string equal $res error]} {
        incr winid
        set w .xcommands_err$winid

        if {[winfo exists $w]} {
            destroy $w
        }

        MessageDlg $w -aspect 50000 -icon error \
            -message [format \
                          [::msgcat::mc "Error executing command: %s"] \
                          [error_to_string $child]] \
            -type user -buttons ok -default 0 -cancel 0
        return
    }

    # TODO
    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    set node [::xmpp::xml::getAttr $attrs node]
    set sessionid [::xmpp::xml::getAttr $attrs sessionid]
    set status [::xmpp::xml::getAttr $attrs status]

    destroy $w
    draw_window $xlib $jid $node $sessionid $status $subels
}

##########################################################################

proc xcommands::complete_result {w xlib jid node sessionid res child} {
    variable winid

    if {[string equal $res err]} {
        incr winid
        set w .xcommands_err$winid

        if {[winfo exists $w]} {
            destroy $w
        }

        MessageDlg $w -aspect 50000 -icon error \
            -message [format \
                          [::msgcat::mc "Error completing command: %s"] \
                          [error_to_string $child]] \
            -type user -buttons ok -default 0 -cancel 0
        return
    }

    # TODO
    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    set node [::xmpp::xml::getAttr $attrs node]
    set sessionid [::xmpp::xml::getAttr $attrs sessionid]
    set status [::xmpp::xml::getAttr $attrs status]

    switch -- $status {
        executing -
        completed { }
        canceled -
        default { return }
    }

    lassign [find_note $subels] type note
    lassign [find_actions $subels] actions execute

    # Only jabber:x:data payloads are supported
    lassign [::xmpp::data::findForm $subels] type form
    set xdata [::xmpp::data::parseForm $form]

    set f [$w.fields getframe]

    foreach cw [winfo children $f] {
        destroy $cw
    }

    data::cleanup $f

    set nf $w.note

    pack_note $nf $type $note
    set focus [data::fill_fields_x $f $xdata]

    destroy $w
    draw_window $xlib $jid $node $sessionid $status $subels
}

##########################################################################

proc xcommands::cancel_window {w xlib jid node sessionid} {
    # Send cancelling stanza and ignore reply or error

    set vars [list sessionid $sessionid action cancel]
    if {$node != ""} {
        lappend vars node $node
    }

    ::xmpp::sendIQ $xlib set \
        -query [::xmpp::xml::create command \
                        -xmlns $::NS(commands) \
                        -attrs $vars] \
        -command [namespace code cancel_result] \
        -to $jid

    close_window $w
}

proc xcommands::cancel_result {args} {}

##########################################################################

proc xcommands::close_window {w} {
    set f [$w.fields getframe]
    data::cleanup $f

    destroy $w
}

##########################################################################

proc xcommands::find_actions {xmldata} {
    set actions {}
    set execute next
    foreach child $xmldata {
        ::xmpp::xml::split $child tag xmlns attrs cdata subels
        if {$tag == "actions"} {
            if {[::xmpp::xml::isAttr $attrs execute]} {
                set execute [::xmpp::xml::getAttr $attrs execute]
            }
            foreach subel $subels {
                ::xmpp::xml::split $subel stag sxmlns sattrs scdata ssubels
                switch -- $stag {
                    prev -
                    next -
                    complete { lappend actions $stag }
                }
            }
            if {$execute ni $actions} {
                set execute next
            }
        }
    }
    return [list $actions $execute]
}

##########################################################################

proc xcommands::find_note {xmldata} {
    set note ""
    set type info
    foreach child $xmldata {
        ::xmpp::xml::split $child tag xmlns attrs cdata subels
        if {$tag == "note"} {
            set note [string trim $cdata]
            set type [::xmpp::xml::getAttr $attrs type]
            switch -- $type {
                info -
                warn -
                error { }
                default { set type info }
            }
        }
    }
    return [list $type $note]
}

##########################################################################

proc xcommands::register_namespace {} {
    disco::browser::register_feature_handler $::NS(commands) \
        [namespace current]::execute -node 1 \
        -desc [list automation [::msgcat::mc "Execute command"]]
    disco::register_featured_node $::NS(commands) $::NS(commands) \
                                  [::msgcat::mc "Commands"]
}

hook::add postload_hook [namespace current]::xcommands::register_namespace

##########################################################################

proc xcommands::disco_node_menu_setup {m bw tnode data parentdata} {
    lassign $data type xlib jid node
    lassign $parentdata ptype pxlib pjid pnode

    if {$pnode eq $::NS(commands)} {
        $m add command -label [::msgcat::mc "Execute command"] \
            -command [namespace code [list execute $xlib $jid $node]]
    }
}

hook::add disco_node_menu_hook \
          [namespace current]::xcommands::disco_node_menu_setup 50

##########################################################################

proc xcommands::add_menu_item {m xlib jid} {
    set mm [menu $m.commands -tearoff 0]

    $m add cascade -label [::msgcat::mc "Commands"] \
                   -menu $mm \
                   -state disabled

    disco::request_items $xlib $jid \
        -node $::NS(commands) \
        -cache yes \
        -command [namespace code [list recv_commands $m $xlib $jid $mm]]
}

proc xcommands::recv_commands {m xlib jid mm status items} {
    if {![string equal $status ok]} return
    if {![winfo exists $m] || ![winfo exists $mm]} return

    set q 0
    foreach item $items {
        set jid [::xmpp::xml::getAttr $item jid]
        if {[string equal $jid ""]} continue

        set node [::xmpp::xml::getAttr $item node]
        if {[string equal $node ""]} continue

        set name [::xmpp::xml::getAttr $item name]
        if {[string equal $name ""]} {
            set name $node
        }

        $mm add command -label $name \
                        -command [namespace code [list execute $xlib $jid $node]]
        set q 1
    }

    if {$q} {
        $m entryconfigure [::msgcat::mc "Commands"] -state normal
    }
}

hook::add chat_create_user_menu_hook [namespace current]::xcommands::add_menu_item 43.5
hook::add chat_create_conference_menu_hook [namespace current]::xcommands::add_menu_item 43.5
hook::add roster_create_groupchat_user_menu_hook [namespace current]::xcommands::add_menu_item 43.5
hook::add roster_conference_popup_menu_hook [namespace current]::xcommands::add_menu_item 43.5
hook::add roster_service_popup_menu_hook [namespace current]::xcommands::add_menu_item 43.5
hook::add roster_jid_popup_menu_hook [namespace current]::xcommands::add_menu_item 43.5
hook::add message_dialog_menu_hook [namespace current]::xcommands::add_menu_item 43.5
hook::add search_popup_menu_hook [namespace current]::xcommands::add_menu_item 43.5

# vim:ft=tcl:ts=8:sw=4:sts=4:et
