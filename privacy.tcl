# privacy.tcl --
#
#       Privacy lists support (XEP-0016)

package require xmpp::privacy

namespace eval privacy {
    variable options

    variable req_messages
    variable send_messages
    variable edit_messages
    variable menu_messages

    array set req_messages \
        [list ignore     [::msgcat::mc "Requesting ignore list: %s"] \
              invisible  [::msgcat::mc "Requesting invisible list: %s"] \
              visible    [::msgcat::mc "Requesting visible list: %s"] \
              conference [::msgcat::mc "Requesting conference list: %s"]]

    array set send_messages \
        [list ignore       [::msgcat::mc "Sending ignore list: %s"] \
              invisible    [::msgcat::mc "Sending invisible list: %s"] \
              visible      [::msgcat::mc "Sending visible list: %s"] \
              conference   [::msgcat::mc "Sending conference list: %s"] \
              subscription [::msgcat::mc "Changing accept messages from\
                                          roster only: %s"]]

    array set edit_messages \
        [list ignore     [::msgcat::mc "Edit ignore list"] \
              invisible  [::msgcat::mc "Edit invisible list"] \
              visible    [::msgcat::mc "Edit visible list"] \
              conference [::msgcat::mc "Edit conference list"]]

    array set menu_messages \
        [list ignore     [::msgcat::mc "Ignore list"] \
              invisible  [::msgcat::mc "Invisible list"] \
              visible    [::msgcat::mc "Visible list"]]

    variable accept_from_roster 0

    custom::defgroup Privacy \
        [::msgcat::mc "Blocking communication (XMPP privacy lists) options."] \
        -group Tkabber

    custom::defvar options(activate_at_startup) 1 \
        [::msgcat::mc "Activate visible/invisible/ignore/conference lists\
                       before sending initial presence."] \
        -type boolean -group Privacy
}

###############################################################################
#
# Manual rules editing block
#

proc privacy::request_lists {xlib} {
    if {$xlib eq ""} {
        set xlib [first_supported]
    }
    if {$xlib eq ""} return

    ::xmpp::privacy::requestLists $xlib \
            -command [namespace code [list open_dialog $xlib]]
}

proc privacy::on_destroy_dialog {} {
    variable data

    catch { array unset data }
}

proc privacy::open_dialog {xlib res child} {
    if {[string equal $res error]} {
        MessageDlg .privacy_err -aspect 50000 -icon error \
            -message [::msgcat::mc "Requesting privacy rules: %s" \
                          [error_to_string $child]] \
            -type user -buttons ok -default 0 -cancel 0
        return
    }

    set w .privacy

    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -title [::msgcat::mc "Privacy lists"] \
        -modal none -anchor e \
        -default 0 -cancel 1

    set f [$w getframe]

    bind $f <Destroy> [namespace code on_destroy_dialog]

    $w add -text [::msgcat::mc "Send"] \
           -command [namespace code [list send_lists $xlib $w]]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set f [$w getframe]

    set hf [Frame $w.hf]
    pack $hf -side bottom

    set tools [Frame $f.tools]
    pack $tools -side bottom -fill x -padx 1m

    set sw [ScrolledWindow $w.sw -scrollbar vertical]
    set sf [ScrollableFrame $w.fields -constrainedwidth yes]
    pack $sw -side bottom -expand yes -fill both -in $f -pady 1m -padx 1m
    set lf [$sf getframe]
    $sw setwidget $sf

    set addlist [Button $tools.addlist \
                     -text [::msgcat::mc "Add list"] \
                     -command [namespace code [list add_list \
                                   $xlib $tools $lf ""]]]
    pack $addlist -side right -padx 1m

    set default [Radiobutton $tools.default \
                     -text [::msgcat::mc "No default list"] \
                     -variable [namespace current]::data(default) \
                     -value "\u0000"]
    pack $default -side left -padx 1m

    set active [Radiobutton $tools.active \
                    -text [::msgcat::mc "No active list"] \
                    -variable [namespace current]::data(active) \
                    -value "\u0000"]
    pack $active -side left -padx 1m

    fill_lists $xlib $hf $lf $child

    $w draw
}

proc privacy::fill_lists {xlib hf f items} {
    variable data

    grid [Label $f.n -text [::msgcat::mc "List name"] -width 20] \
        -row 0 -column 0 -sticky we -padx 1m
    grid [Label $f.d -text [::msgcat::mc "Default"]] \
        -row 0 -column 1 -sticky we -padx 1m
    grid [Label $f.a -text [::msgcat::mc "Active"]] \
        -row 0 -column 2 -sticky we -padx 1m

    grid columnconfigure $f 0 -weight 1
    grid columnconfigure $f 1 -weight 1
    grid columnconfigure $f 2 -weight 1
    grid columnconfigure $f 3 -weight 1
    grid columnconfigure $f 4 -weight 1

    array set tmp $items

    if {[info exists tmp(default)]} {
        set data(default) $tmp(default)
    } else {
        set data(default) "\u0000"
    }
    if {[info exists tmp(active)]} {
        set data(active) $tmp(active)
    } else {
        set data(active) "\u0000"
    }
    set data(nlists) 0

    foreach name $tmp(items) {
        add_list $xlib $hf $f $name
    }
}

proc privacy::remove_list {lf ln} {
    variable data

    destroy $lf.name$ln
    destroy $lf.active$ln
    destroy $lf.default$ln
    destroy $lf.edit$ln
    destroy $lf.remove$ln
    set data(nitems,$ln) 0
    set data(newname,$ln) ""
}

proc privacy::on_change_list_name {lf i args} {
    variable data

    set name $data(newname,$i)

    if {$data(default) eq $data(name,$i)} {
        set data(default) $name
    }
    if {$data(active) eq $data(name,$i)} {
        set data(active) $name
    }

    if {[winfo exists $lf.default$i] && [winfo exists $lf.active$i]} {
        $lf.default$i configure -value $name
        $lf.active$i configure -value $name
    }
    if {$name ne ""} {
        set data(name,$i) $name
    }
}

proc privacy::add_list {xlib hf lf name} {
    variable data

    set i $data(nlists)

    if {$name eq ""} {
        set name "list$i"
        send_new_list $xlib $name
    }

    set data(name,$i) $name
    set data(newname,$i) $name

    trace add variable [namespace current]::data(newname,$i) write \
        [list [namespace current]::on_change_list_name $lf $i]

    set lname [Label $lf.name$i \
                   -text $name \
                   -textvariable [namespace current]::data(name,$i)]
    set default [Radiobutton $lf.default$i \
                     -variable [namespace current]::data(default) \
                     -value $name]
    set active [Radiobutton $lf.active$i \
                    -variable [namespace current]::data(active) \
                    -value $name]
    set remove [Button $lf.remove$i \
                    -text [::msgcat::mc "Remove list"] \
                    -command [list [namespace current]::remove_list $lf $i]]
    set edit [Button $lf.edit$i \
                  -text [::msgcat::mc "Edit list"] \
                  -command [list [namespace current]::edit_list $xlib $lf $i]]

    set row [expr {$i + 1}]
    grid $lname   -row $row -column 0 -stick w  -padx 1m
    grid $default -row $row -column 1 -stick we -padx 1m
    grid $active  -row $row -column 2 -stick we -padx 1m
    grid $edit    -row $row -column 3 -stick we -padx 1m
    grid $remove  -row $row -column 4 -stick we -padx 1m

    update idletasks
    $hf configure \
        -width [expr {[winfo reqwidth $lf] + [winfo pixels $lf 1c]}]

    incr data(nlists)
}

proc privacy::edit_list {xlib lf ln} {
    variable data

    set name $data(name,$ln)

    ::xmpp::privacy::requestItems $xlib $name \
            -command [namespace code [list edit_list_dialog $xlib $ln $name]]
}

proc privacy::edit_list_dialog {xlib ln name res child} {
    if {[string equal $res error]} {
        MessageDlg .privacy_list_err -aspect 50000 -icon error \
            -message [::msgcat::mc "Requesting privacy list: %s" \
                          [error_to_string $child]] \
            -type user -buttons ok -default 0 -cancel 0
        set child {}
    }

    set w .privacy_list

    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -title [::msgcat::mc "Edit privacy list"] \
        -anchor e \
        -default 0 -cancel 1

    $w add -text [::msgcat::mc "Send"] \
        -command [namespace code [list send_list $xlib $ln $w]]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set f [$w getframe]

    set tools [Frame $f.tools]
    pack $tools -side bottom -fill x

    set hf [Frame $w.hf]
    pack $hf -side bottom

    set sw [ScrolledWindow $w.sw -scrollbar vertical]
    set sf [ScrollableFrame $w.fields -constrainedwidth yes]
    set lf [$sf getframe]
    pack $sw -side top -expand yes -fill both -in $f -pady 1m
    $sw setwidget $sf

    set additem [Button $tools.aditem \
                     -text [::msgcat::mc "Add item"] \
                     -command \
                     [namespace code [list add_item \
                          $lf.items "none" "" "allow" 1 1 1 1]]]
    pack $additem -side right -padx 1m

    fill_edit_list $lf $name $child

    update idletasks
    $hf configure \
        -width [expr {[winfo reqwidth $lf] + [winfo pixels $lf 1c]}]

    $w draw
}

proc privacy::fill_edit_list {fr name items} {
    variable data

    set data(listname) $name
    set data(listnewname) $name

    set fname [Frame $fr.name]
    pack $fname -side top -fill x
    Label $fname.lname -text [string trimright [::msgcat::mc "Name: "]]
    Entry $fname.name \
        -textvariable [namespace current]::data(listnewname)
    pack $fname.lname -side left -anchor w
    pack $fname.name -side left -fill x -expand yes

    set f [Frame $fr.items]
    pack $f -side top -fill both -expand yes

    Label $f.ltype        -text [::msgcat::mc "Type"]
    Label $f.lvalue       -text [::msgcat::mc "Value"]
    Label $f.laction      -text [::msgcat::mc "Action"]
    Label $f.lmessage     -text [::msgcat::mc "Message"]
    Label $f.lpresencein  -text [::msgcat::mc "Presence-in"]
    Label $f.lpresenceout -text [::msgcat::mc "Presence-out"]
    Label $f.liq          -text [::msgcat::mc "IQ"]
    grid $f.ltype        -row 0 -column 0 -sticky we -padx 0.5m
    grid $f.lvalue       -row 0 -column 1 -sticky we -padx 0.5m
    grid $f.laction      -row 0 -column 2 -sticky we -padx 0.5m
    grid $f.lmessage     -row 0 -column 3 -sticky we -padx 0.5m
    grid $f.lpresencein  -row 0 -column 4 -sticky we -padx 0.5m
    grid $f.lpresenceout -row 0 -column 5 -sticky we -padx 0.5m
    grid $f.liq          -row 0 -column 6 -sticky we -padx 0.5m
    grid columnconfig $f 1 -weight 1

    set data(listnitems) 0
    foreach item $items {
        set type [::xmpp::xml::getAttr $item type]
        if {$type eq ""} {
            set type none
        }
        set value [::xmpp::xml::getAttr $item value]
        set action [::xmpp::xml::getAttr $item action]

        set stanzas [::xmpp::xml::getAttr $item stanzas]
        if {[llength $stanzas] == 0} {
            array set tmp [list message 1 presence-in 1 presence-out 1 iq 1]
        } else {
            array set tmp [list message 0 presence-in 0 presence-out 0 iq 0]
            foreach tag $stanzas {
                set tmp($tag) 1
            }
        }

        add_item $f $type $value $action \
                 $tmp(message) $tmp(presence-in) $tmp(presence-out) $tmp(iq)
    }
}

proc privacy::add_item \
     {f type value action message presencein presenceout iq} {
    variable data

    set i $data(listnitems)

    Entry $f.value$i \
        -textvariable [namespace current]::data(value,$i)
    Combobox $f.type$i \
        -values {none jid group subscription} \
        -editable no \
        -width 12 \
        -textvariable [namespace current]::data(type,$i)
    Combobox $f.action$i \
        -values {allow deny} \
        -editable no \
        -width 5 \
        -textvariable [namespace current]::data(action,$i)
    Checkbutton $f.message$i \
        -variable [namespace current]::data(message,$i) \
        -command [list [namespace current]::update_checkbuttons $i]
    Checkbutton $f.presencein$i \
        -variable [namespace current]::data(presencein,$i) \
        -command [list [namespace current]::update_checkbuttons $i]
    Checkbutton $f.presenceout$i \
        -variable [namespace current]::data(presenceout,$i) \
        -command [list [namespace current]::update_checkbuttons $i]
    Checkbutton $f.iq$i \
        -variable [namespace current]::data(iq,$i) \
        -command [list [namespace current]::update_checkbuttons $i]
    Button $f.moveup$i -text [::msgcat::mc "Up"] \
        -command [list [namespace current]::move_item_up $f $i]
    Button $f.movedown$i -text [::msgcat::mc "Down"] \
        -command [list [namespace current]::move_item_down $f $i]
    Button $f.remove$i -text [::msgcat::mc "Remove"] \
        -command [list [namespace current]::remove_item $f $i]

    set data(type,$i)        $type
    set data(value,$i)       $value
    set data(action,$i)      $action
    set data(message,$i)     $message
    set data(presencein,$i)  $presencein
    set data(presenceout,$i) $presenceout
    set data(iq,$i)          $iq

    set row [expr {$i + 1}]
    grid $f.type$i        -row $row -column 0 -sticky ew -padx 0.5m
    grid $f.value$i       -row $row -column 1 -sticky ew -padx 0.5m
    grid $f.action$i      -row $row -column 2 -sticky ew -padx 0.5m
    grid $f.message$i     -row $row -column 3 -sticky ew -padx 0.5m
    grid $f.presencein$i  -row $row -column 4 -sticky ew -padx 0.5m
    grid $f.presenceout$i -row $row -column 5 -sticky ew -padx 0.5m
    grid $f.iq$i          -row $row -column 6 -sticky ew -padx 0.5m
    grid $f.moveup$i      -row $row -column 7 -sticky ew -padx 0.5m
    grid $f.movedown$i    -row $row -column 8 -sticky ew -padx 0.5m
    grid $f.remove$i      -row $row -column 9 -sticky ew -padx 0.5m

    incr data(listnitems)
    update_button_states $f
}

proc privacy::update_checkbuttons {i} {
    variable data

    if {!$data(message,$i) && !$data(presencein,$i) && \
            !$data(presenceout,$i) && !$data(iq,$i)} {
        set data(message,$i) 1
        set data(presencein,$i) 1
        set data(presenceout,$i) 1
        set data(iq,$i) 1
    }
}

proc privacy::update_button_states {f} {
    variable data

    set numrows 0
    set row 0
    for {set i 0} {$i < $data(listnitems)} {incr i} {
        if {$data(type,$i) ne "remove"} {
            $f.remove$i configure -state normal
            incr numrows
            set row $i
        }
    }
    if {$numrows == 1} {
        $f.remove$row configure -state disabled
    }
}

proc privacy::move_item_up {f i} {
    variable data

    set j $i
    incr j -1
    while {$j >= 0 && $data(type,$j) eq "remove"} {
        incr j -1
    }

    if {$j >= 0} {
        switch_items $f $i $j
    }
}

proc privacy::move_item_down {f i} {
    variable data

    set j $i
    incr j 1
    while {$j < $data(listnitems) && $data(type,$j) eq "remove"} {
        incr j 1
    }

    if {$j < $data(listnitems)} {
        switch_items $f $i $j
    }
}

proc privacy::switch_items {f i j} {
    variable data

    set type        $data(type,$i)
    set value       $data(value,$i)
    set action      $data(action,$i)
    set message     $data(message,$i)
    set presencein  $data(presencein,$i)
    set presenceout $data(presenceout,$i)
    set iq          $data(iq,$i)

    set data(type,$i)        $data(type,$j)
    set data(value,$i)       $data(value,$j)
    set data(action,$i)      $data(action,$j)
    set data(message,$i)     $data(message,$j)
    set data(presencein,$i)  $data(presencein,$j)
    set data(presenceout,$i) $data(presenceout,$j)
    set data(iq,$i)          $data(iq,$j)

    set data(type,$j)        $type
    set data(value,$j)       $value
    set data(action,$j)      $action
    set data(message,$j)     $message
    set data(presencein,$j)  $presencein
    set data(presenceout,$j) $presenceout
    set data(iq,$j)          $iq
}

proc privacy::remove_item {f i} {
    variable data

    destroy $f.type$i
    destroy $f.value$i
    destroy $f.action$i
    destroy $f.message$i
    destroy $f.presencein$i
    destroy $f.presenceout$i
    destroy $f.iq$i
    destroy $f.moveup$i
    destroy $f.movedown$i
    destroy $f.remove$i

    set data(type,$i) remove
    set data(value,$i) ""
    set data(action,$i) allow

    update_button_states $f
}

proc privacy::send_new_list {xlib name} {
    ::xmpp::privacy::sendItems $xlib $name {{action allow}} -command #
}

proc privacy::send_list {xlib ln w} {
    variable data

    set name $data(listnewname)
    ::xmpp::privacy::sendItems $xlib $name [list_items] -command #

    if {$name ne $data(listname)} {
        if {$data(default) eq $data(listname)} {
            send_default_or_active_list $xlib $name default -command #
        }
        ::xmpp::privacy::sendItems $xlib $data(listname) {} -command #
        set data(newname,$ln) $name
    }

    destroy $w
}

proc privacy::send_lists {xlib w} {
    variable data

    for {set i 0} {$i < $data(nlists)} {incr i} {
        if {$data(newname,$i) eq ""} {
            ::xmpp::privacy::sendItems $xlib $data(name,$i) {} -command #
        }
    }

    send_default_or_active_list $xlib $data(active) active -command #
    send_default_or_active_list $xlib $data(default) default -command #

    destroy $w
}

proc privacy::list_items {} {
    variable data

    set items {}
    for {set i 0} {$i < $data(listnitems)} {incr i} {
        if {$data(type,$i) eq "remove"} continue

        set vars [list action $data(action,$i)]
        if {$data(type,$i) ne "none"} {
            lappend vars type $data(type,$i) value $data(value,$i)
        }

        set stanzas {}
        if {$data(message,$i)} {
            lappend stanzas message
        }
        if {$data(presencein,$i)} {
            lappend stanzas presence-in
        }
        if {$data(presenceout,$i)} {
            lappend stanzas presence-out
        }
        if {$data(iq,$i)} {
            lappend stanzas iq
        }
        if {[llength $stanzas] == 4} {
            set stanzas {}
        }
        lappend vars stanzas $stanzas

        lappend items $vars
    }
    return $items
}

###############################################################################

proc privacy::send_default_or_active_list {xlib name tag args} {
    set newargs {}
    foreach {opt val} $args {
        switch -- $opt {
            -command { lappend newargs -command $val }
        }
    }

    if {$name ne "\u0000"} {
        lappend newargs -name $name
    }

    switch -- $tag {
        default {
            return [::xmpp::privacy::setDefault $xlib {*}$newargs]
        }
        active {
            return [::xmpp::privacy::setActive $xlib {*}$newargs]
        }
    }
}

###############################################################################
#
# Visible, invisible, ignore, conference list block
#

proc privacy::edit_special_list {xlib name args} {
    if {$xlib eq ""} {
        set xlib [first_supported]
    }
    if {$xlib eq ""} return

    ::xmpp::privacy::requestItems $xlib $name-list \
        -command [namespace code [list edit_special_list_dialog $xlib $name]]
}

proc privacy::edit_special_list_dialog {xlib name res child} {
    variable req_messages
    variable edit_messages

    if {[string equal $res error]} {
        if {[error_type_condition $child] ne {cancel item-not-found}} {
            MessageDlg .privacy_list_err -aspect 50000 -icon error \
                -message [format $req_messages($name) \
                                 [error_to_string $child]] \
                -type user -buttons ok -default 0 -cancel 0
            return
        }
        set child {}
    }

    set w .privacy_list

    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -title $edit_messages($name) \
        -modal none -anchor e \
        -default 0 -cancel 1

    $w add -text [::msgcat::mc "Send"] \
        -command [list [namespace current]::edit_special_list_enddialog \
                       $xlib $w $name]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set f [$w getframe]

    set tools [Frame $f.tools]
    pack $tools -side bottom -fill x

    set sw [ScrolledWindow $w.sw]
    set lf [Listbox $w.fields]
    pack $sw -side top -expand yes -fill both -in $f -pady 1m -padx 1m
    $sw setwidget $lf

    bind $lf <<ContextMenu>> \
             [list [namespace current]::select_and_popup_menu %W %x %y]

    set addentry [Entry $tools.addentry]
    set additem [Button $tools.additem \
                     -text [::msgcat::mc "Add JID"] \
                     -command \
                     [list [namespace current]::add_special_jid_entry $lf \
                           $addentry]]
    pack $additem -side right -padx 1m
    pack $addentry -side left -padx 1m -fill x -expand yes

    fill_edit_special_list $lf $name $child

    #update idletasks
    #$tools configure -width [winfo reqwidth $lf]

    DropSite::register $lf -dropcmd [list [namespace current]::dropcmd] \
        -droptypes {JID}

    $w draw
}

proc privacy::edit_special_list_enddialog {xlib w name} {
    $w itemconfigure 0 -state disabled
    send_special_list $xlib $name [$w.fields get 0 end]
    destroy $w
}

proc privacy::send_special_list {xlib name items} {
    variable special_list
    variable cboxes

    if {![is_supported $xlib]} {
        return
    }

    if {![info exists special_list($xlib,$name)]} {
        set special_list($xlib,$name) {}
    }

    set newitems {}
    foreach jid $items {
        if {$jid ni $special_list($xlib,$name)} {
            lappend newitems $jid
        }
    }

    set olditems {}
    foreach jid $special_list($xlib,$name) {
        if {$jid ni $items} {
            lappend olditems $jid
        }
    }

    switch -- $name {
        ignore {
            set stanzas {}
            set action deny
            foreach jid $newitems {
                send_custom_presence $xlib $jid unavailable
            }
            set postitems $olditems
        }
        invisible {
            set stanzas {presence-out iq}
            set action deny
            foreach jid $newitems {
                send_custom_presence $xlib $jid unavailable
            }
            set postitems $olditems
        }
        visible {
            # TODO: invisibility
            set stanzas {}
            set action allow
            set postitems $newitems
        }
        conference {
            set stanzas {}
            set action allow
            set postitems {}
        }
    }

    set items1 {}
    foreach item $items {
        lappend items1 [list type    jid \
                             value   $item \
                             action  $action \
                             stanzas $stanzas]
    }

    # We have to use synchronous mode because all privacy lists should be
    # updated before sending next stanzas
    set status \
        [catch {::xmpp::privacy::sendItems $xlib "$name-list" $items1} msg]

    update_tkabber_lists $xlib $name $items $postitems $status $msg
}

# subscription-list is responsible for blocking all messages
# not from the roster.
proc privacy::send_subscription_list {xlib} {
    variable accept_from_roster_only

    if {![is_supported $xlib]} {
        return
    }

    if {$accept_from_roster_only} {
        set items [list [list type   subscription \
                              value  none \
                              action deny]]
    } else {
        set items {}
    }

    # If items aren't empty, we'll never send unavailable presence to
    # all users to whom directed presence was sent. Bug?

    # We have to use synchronous mode because all privacy lists should be
    # updated before sending next stanzas
    set status \
        [catch {::xmpp::privacy::sendItems $xlib "subscription-list" $items} \
               msg]

    update_tkabber_lists $xlib subscription $items {} $status $msg
}

proc privacy::on_accept_from_roster_only_change {xlib} {
    if {$xlib eq ""} {
        set xlib [first_supported]
    }
    if {$xlib eq ""} return

    send_subscription_list $xlib
}

proc privacy::update_tkabber_lists {xlib name items postitems status msg} {
    global userstatus textstatus statusdesc
    variable send_messages
    variable special_list
    variable cboxes

    if {$status == 3} {
        # break
        return
    }

    switch -- $name {
        subscription {
            # Subscription list doesn't contain JIDs
        }
        default {
            # Workaround for servers without privacy list support/push
            if {$status == 0} {
                # ok
                set special_list($xlib,$name) $items
            }
            array unset cboxes $xlib,$name,*
            foreach jid $special_list($xlib,$name) {
                set cboxes($xlib,$name,$jid) 1
            }
        }
    }

    if {$status == 1} {
        # error
        MessageDlg .privacy_list_err -aspect 50000 -icon error \
            -message [format $send_messages($name) [error_to_string $msg]] \
            -type user -buttons ok -default 0 -cancel 0
        return
    }

    switch -- $name {
        ignore -
        conference -
        subscription {
            # Some inefficiency here. We load three lists twice.
            join_lists $xlib "i-am-visible-list" \
                       {ignore-list invisible-list
                        conference-list subscription-list} \
                       {allow {} {}} -command #
            join_lists $xlib "i-am-invisible-list" \
                       {ignore-list visible-list
                        conference-list subscription-list} \
                       {deny {} {presence-out iq}} -command #
        }
        invisible {
            join_lists $xlib "i-am-visible-list" \
                       {ignore-list invisible-list
                        conference-list subscription-list} \
                       {allow {} {}} -command #
        }
        visible {
            join_lists $xlib "i-am-invisible-list" \
                       {ignore-list visible-list
                        conference-list subscription-list} \
                       {deny {} {presence-out iq}} -command #
        }
    }

    # ejabberd behaves correctly and applies privacy lists before
    # routing any subsequent packet, so we haven't to wait for iq reply
    # before sending presence. What about other servers?
    if {$userstatus eq "invisible"} {
        set status available
    } else {
        set status $userstatus
    }

    set tstatus $textstatus

    foreach jid $postitems {
        send_presence $xlib $status -to $jid -status $tstatus
    }
}

proc privacy::join_lists {xlib name lists fallbacks args} {
    set items {}

    # Appending myself to the list to make sure we can communicate
    # between own resources
    lappend items [list type   jid \
                        value  [connection_bare_jid $xlib] \
                        action allow]

    foreach ln $lists {
        set status [catch {::xmpp::privacy::requestItems $xlib $ln} ritems]

        if {$status == 3} {
            # abort
            return
        }

        if {$status == 0} {
            # !ok
            set items [concat $items $ritems]
        }
    }

    foreach {action vars stanzas} $fallbacks {
        lappend items [concat [list action $action stanzas $stanzas] $vars]
    }

    ::xmpp::privacy::sendItems $xlib $name $items {*}$args
}

proc privacy::dropcmd {target source X Y op type data} {
    add_special_jid $target [lindex $data 1]
}

proc privacy::select_and_popup_menu {f x y} {
    set index [$f index @$x,$y]
    $f selection clear 0 end
    $f selection set $index

    if {[winfo exists [set m .privacy_list_popupmenu]]} {
        destroy $m
    }

    menu $m -tearoff 0
    $m add command -label [::msgcat::mc "Remove from list"] \
        -command [list $f delete $index]
    tk_popup $m [winfo pointerx .] [winfo pointery .]
}

proc privacy::fill_edit_special_list {fr name items} {
    set values {}
    foreach item $items {
        set type [::xmpp::xml::getAttr $item type]
        if {$type ne "jid"} continue
        lappend values [::xmpp::xml::getAttr $item value]
    }

    $fr insert end {*}[lsort -dictionary -unique $values]
}

proc privacy::add_special_jid_entry {f entry} {
    set item [$entry get]
    $entry delete 0 end

    add_special_jid $f $item
}

proc privacy::add_special_jid {f item} {
    set values [$f get 0 end]
    lappend values $item
    set values [lsort -dictionary -unique $values]

    set index [lsearch -exact $values $item]

    $f delete 0 end
    $f insert end {*}$values
    $f selection set $index
}

###############################################################################
#
# During connect try to activate "i-am-visible-list" privacy list
# If it's not found then create and activate it
# If activation or creation fails then terminate connect with error message
#

proc privacy::activate_privacy_list {depth xlib} {
    variable options

    set_status [::msgcat::mc "Waiting for activating privacy list"]
    debugmsg privacy "requested privacy list activation"

    set status \
        [catch {send_default_or_active_list $xlib "i-am-visible-list" active} \
               msg]

    debugmsg privacy "setting i-am-visible-list as default: $status $msg"

    switch -- $status {
        0 {
            # ok
            set_status [::msgcat::mc "Privacy list is activated"]
            set_supported $xlib
        }
        1 {
            # error
            switch -- [lindex [error_type_condition $msg] 1] {
                feature-not-implemented {
                    # Privacy lists aren't implemented
                    # Give up
                    set_status \
                        [::msgcat::mc "Privacy lists are not implemented"]
                }
                service-unavailable -
                recipient-unavailable {
                    # Privacy lists are unavailable
                    # Give up
                    set_status \
                        [::msgcat::mc "Privacy lists are unavailable"]
                }
                item-not-found {
                    if {$depth >= 1} {
                        # After successfully (!) created list it
                        # mustn't be possible
                        # TODO: error message
                        return
                    }
                    # There's no required privacy list
                    # Create it
                    set_status \
                        [::msgcat::mc "Creating default privacy list"]

                    set status1 \
                        [catch {join_lists $xlib "i-am-visible-list" \
                            {ignore-list invisible-list
                             conference-list subscription-list} \
                            {allow {} {}}} msg1]

                    debugmsg privacy \
                             "joining i-am-visible-list: $status1 $msg1"

                    switch -- $status1 {
                        0 {
                            # ok
                            # Activate newly created list
                            set_supported $xlib
                            return [activate_privacy_list [expr {$depth + 1}] \
                                                          $xlib]
                        }
                        1 {
                            # error
                            # Disconnect with error message
                            set_status \
                                [::msgcat::mc "Privacy list is not created"]

                            NonmodalMessageDlg \
                                .privacy_list_error[psuffix $xlib] \
                                -aspect 50000 -icon error \
                                -title [::msgcat::mc "Privacy lists error"] \
                                -message \
                                    [::msgcat::mc \
                                        "Creating default privacy list failed:\
                                         %s\n\nTry to reconnect. If problem\
                                         persists, you may want to disable\
                                         privacy list activation at start" \
                                    [error_to_string $msg1]]

                            logout $xlib

                            # Break connected_hook
                            return stop
                        }
                        default {
                            # abort
                            set_status \
                                [::msgcat::mc "Privacy list is not created"]

                            # Break connected_hook
                            return stop
                        }
                    }
                }
                default {
                    # Something wrong
                    # Disconnect with error message
                    set_status \
                        [::msgcat::mc "Privacy list is not activated"]

                    NonmodalMessageDlg .privacy_list_error[psuffix $xlib] \
                        -aspect 50000 -icon error \
                        -title [::msgcat::mc "Privacy lists error"] \
                        -message \
                            [::msgcat::mc \
                                "Activating privacy list failed:\
                                 %s\n\nTry to reconnect. If problem\
                                 persists, you may want to disable privacy\
                                 list activation at start" \
                            [error_to_string $msg]]

                    logout $xlib

                    # Break connected_hook
                    return stop
                }
            }
        }
        default {
            # abort
            set_status [::msgcat::mc "Privacy list is not activated"]

            # Break connected_hook
            return stop
        }
    }
}

##########################################################################

proc privacy::activate_privacy_list_at_startup {xlib} {
    variable options

    if {$options(activate_at_startup)} {
        activate_privacy_list 0 $xlib
    }
}

hook::add connected_hook \
    [namespace current]::privacy::activate_privacy_list_at_startup 1

##########################################################################

proc privacy::is_supported {xlib} {
    variable supported

    expr {[info exists supported($xlib)] && $supported($xlib)}
}

proc privacy::set_supported {xlib} {
    variable supported

    set supported($xlib) 1
}

proc privacy::clear_supported {xlib} {
    variable supported

    array unset supported $xlib
}

hook::add disconnected_hook [namespace current]::privacy::clear_supported

###############################################################################

proc privacy::create_menu {m xlib jid} {
    variable menu_messages
    variable special_list
    variable cboxes

    set rjid [roster::find_jid $xlib $jid]

    if {$rjid eq ""} {
         set rjid [::xmpp::jid::removeResource $jid]
    }

    if {![is_supported $xlib] || \
            [chat::is_groupchat [chat::chatid $xlib $rjid]]} {
        set state disabled
    } else {
        set state normal
    }

    set mm [menu $m.privacy_menu -tearoff 0]

    foreach name {invisible ignore} {
        if {![info exists special_list($xlib,$name)]} {
            set special_list($xlib,$name) {}
        }

        if {$rjid in $special_list($xlib,$name)} {
            set cboxes($xlib,$name,$rjid) 1
        }

        $mm add checkbutton -label $menu_messages($name) \
            -variable [namespace current]::cboxes($xlib,$name,$rjid) \
            -command [list [namespace current]::update_special_list \
                           $xlib $name $rjid]
    }

    $m add cascade -label [::msgcat::mc "Privacy rules"] \
                  -menu $mm \
                  -state $state
}

hook::add chat_create_user_menu_hook \
          [namespace current]::privacy::create_menu 79
hook::add roster_service_popup_menu_hook \
          [namespace current]::privacy::create_menu 79
hook::add roster_jid_popup_menu_hook \
          [namespace current]::privacy::create_menu 79


###############################################################################

proc privacy::update_special_list {xlib name jid} {
    variable cboxes

    if {[info exists cboxes($xlib,$name,$jid)] && $cboxes($xlib,$name,$jid)} {
        add_to_special_list $xlib $name $jid
    } else {
        remove_from_special_list $xlib $name $jid
    }
}

###############################################################################

proc privacy::add_to_special_list {xlib name jid} {
    variable special_list

    if {![info exists special_list($xlib,$name)]} {
        set special_list($xlib,$name) {}
    }

    if {$jid ni $special_list($xlib,$name)} {
        send_special_list $xlib $name \
                          [linsert $special_list($xlib,$name) 0 $jid]
    }
}

###############################################################################

proc privacy::remove_from_special_list {xlib name jid} {
    variable special_list

    if {![info exists special_list($xlib,$name)]} {
        set special_list($xlib,$name) {}
    }

    set idx [lsearch -exact $special_list($xlib,$name) $jid]

    if {$idx >= 0} {
        send_special_list $xlib $name \
                          [lreplace $special_list($xlib,$name) $idx $idx]
    }
}

###############################################################################

proc privacy::process_push {xlib from name args} {
    switch -- $name {
        invisible-list {
            reload_special_list $xlib invisible
        }
        visible-list {
            reload_special_list $xlib visible
        }
        ignore-list {
            reload_special_list $xlib ignore
        }
        conference-list {
            reload_special_list $xlib conference
        }
        subscription-list {
            reload_subscription_list $xlib
        }
    }
    return {result {}}
}

::xmpp::privacy::register -command [namespace current]::privacy::process_push

###############################################################################

proc privacy::clear_list_vars {xlib} {
    variable special_list
    variable cboxes

    array unset special_list $xlib,*
    array unset cboxes $xlib,*
}

hook::add disconnected_hook [namespace current]::privacy::clear_list_vars

###############################################################################
# Conference list should be loaded before any join group attempt is made

proc privacy::get_conference_list {xlib} {
    set status \
        [catch {::xmpp::privacy::requestItems $xlib conference-list} msg]

    if {($status == 0) || \
            ($status == 1 && \
             [lindex [error_type_condition $msg] 1] eq "item-not-found")} {
        set_supported $xlib
    }

    switch -- $status {
        0 { set res ok }
        1 { set res error }
        default { set res abort }
    }

    store_special_list $xlib conference $res $msg
}

hook::add connected_hook [namespace current]::privacy::get_conference_list 2

###############################################################################

proc privacy::get_list_vars {xlib} {
    foreach name {invisible visible ignore} {
        reload_special_list $xlib $name
    }
    reload_subscription_list $xlib
}

hook::add connected_hook [namespace current]::privacy::get_list_vars

###############################################################################

proc privacy::reload_special_list {xlib name} {
    ::xmpp::privacy::requestItems $xlib $name-list \
            -command [namespace code [list store_special_list $xlib $name]]
}

proc privacy::store_special_list {xlib name res child} {
    variable special_list
    variable cboxes

    set special_list($xlib,$name) {}
    array unset cboxes $xlib,$name,*

    if {$res ne "ok"} return

    foreach item $child {
        if {[::xmpp::xml::getAttr $item type] eq "jid" && \
                [set jid [::xmpp::xml::getAttr $item value]] ne ""} {
            lappend special_list($xlib,$name) $jid
            set cboxes($xlib,$name,$jid) 1
        }
    }
}

###############################################################################

proc privacy::reload_subscription_list {xlib} {
    ::xmpp::privacy::requestItems $xlib subscription-list \
            -command [list [namespace current]::store_subscription_list $xlib]
}

proc privacy::store_subscription_list {xlib res child} {
    variable accept_from_roster_only

    set accept_from_roster_only 0

    if {$res ne "ok"} return

    foreach item $child {
        if {[::xmpp::xml::getAttr $item type] eq "subscription" && \
                [::xmpp::xml::getAttr $item value] eq "none" && \
                [::xmpp::xml::getAttr $item action] eq "deny"} {
            set accept_from_roster_only 1
        }
    }
}

###############################################################################

proc privacy::first_supported {} {
    foreach xlib [connections] {
        if {[is_supported $xlib]} {
            return $xlib
        }
    }
    return ""
}

###############################################################################

proc privacy::enable_menu {xlib} {

    if {[first_supported] eq ""} return

    set m [.mainframe getmenu privacy]
    if {$::ifacetk::options(show_tearoffs)} {
        set start 1
    } else {
        set start 0
    }
    for {set i $start} {$i <= [$m index end]} {incr i} {
        catch {$m entryconfigure $i -state normal}
    }
}

proc privacy::disable_menu {xlib} {

    if {[first_supported] ne ""} return

    set m [.mainframe getmenu privacy]
    if {$::ifacetk::options(show_tearoffs)} {
        set start 1
    } else {
        set start 0
    }
    for {set i $start} {$i <= [$m index end]} {incr i} {
        catch {$m entryconfigure $i -state disabled}
    }
    $m entryconfigure [$m index [::msgcat::mc "Activate lists at startup"]] \
       -state normal
}

hook::add connected_hook [namespace current]::privacy::enable_menu
hook::add disconnected_hook [namespace current]::privacy::disable_menu
hook::add finload_hook [list [namespace current]::privacy::disable_menu {}]

# vim:ft=tcl:ts=8:sw=4:sts=4:et
