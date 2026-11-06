# metacontacts.tcl --
#
#       Storing metacontacts (XEP-0209) support

package require xmpp::roster::metacontacts

namespace eval metacontacts {
    # variable to store roster contacts
    variable contacts
    array set contacts {}

    hook::add disconnected_hook [namespace current]::free_contacts
    hook::add connected_hook [namespace current]::request_contacts
    hook::add roster_jid_popup_menu_hook [namespace current]::roster_menu 72
}

proc metacontacts::free_contacts {xlib} {
    variable contacts

    array unset contacts $xlib,*
}

proc metacontacts::request_contacts {xlib} {
    variable contacts

    array unset contacts $xlib,*
    set contacts($xlib,tags) {}

    ::xmpp::roster::metacontacts::retrieve $xlib \
                -command [namespace code [list process_contacts $xlib]]
}

proc metacontacts::process_contacts {xlib status contactslist} {
    variable contacts

    if {$status != "ok"} return

    foreach {tag jids} $contactslist {
        create_contact $xlib $tag $jids
    }
}

proc metacontacts::create_contact {xlib tag jids args} {
    variable contacts

    set merge 0
    foreach {opt val} $args {
        switch -- $opt {
            -merge { set merge $val }
            default {
                return -code error "Bad option \"$opt\":\
                    must be -merge"
            }
        }
    }

    if {!$merge || ![info exists contacts($xlib,jids,$tag)]} {
        lappend contacts($xlib,tags) $tag
        set contacts($xlib,tags) [lsort -unique $contacts($xlib,tags)]

        set contacts($xlib,jids,$tag) $jids

        foreach idx [array names contacts $xlib,tag,*] {
            if {[set idx1 [lsearch -exact $contacts($idx) $tag]] >= 0} {
                set contacts($idx) [lreplace $contacts($idx) $idx1 $idx1]
                if {[llength $contacts($idx)] == 0} {
                    unset contacts($idx)
                }
            }
        }
        foreach jid $jids {
            lappend contacts($xlib,tag,$jid) $tag
            set contacts($xlib,tag,$jid) [lsort -unique $contacts($xlib,tag,$jid)]
        }
        return 1
    } else {
        return 0
    }
}

proc metacontacts::get_all_tags {xlib} {
    variable contacts

    if {[info exists contacts($xlib,tags)]} {
        return $contacts($xlib,tags)
    } else {
        return {}
    }
}

proc metacontacts::get_tags {xlib jid} {
    variable contacts

    if {[info exists contacts($xlib,tag,$jid)]} {
        return $contacts($xlib,tag,$jid)
    } else {
        return {}
    }
}

proc metacontacts::get_jids {xlib tag} {
    variable contacts

    if {[info exists contacts($xlib,jids,$tag)]} {
        return $contacts($xlib,jids,$tag)
    } else {
        return {}
    }
}

proc metacontacts::cleanup_and_store_contacts {xlib args} {
    variable contacts

    set roster_jids [roster::get_jids $xlib]

    foreach idx [array names contacts $xlib,jids,*] {
        set tag [string range $idx [string length $xlib,jids,] end]
        set jids {}
        foreach jid $contacts($idx) {
            if {$jid ni $roster_jids} {
                catch { unset contacts($xlib,tag,$jid) }
            } else {
                lappend jids $jid
            }
        }
        set contacts($idx) $jids
    }

    store_contacts $xlib {*}$args
}

proc metacontacts::serialize_contacts {xlib} {
    variable contacts

    set contactlist {}
    foreach idx [array names contacts $xlib,jids,*] {
        set tag [string range $idx [string length $xlib,jids,] end]

        lappend contactlist $tag $contacts($idx)
    }

    return $contactlist
}

proc metacontacts::store_contacts {xlib args} {
    set command [namespace code [list store_contacts_result $xlib]]
    foreach {opt val} $args {
        switch -- $opt {
            -command { set command $val }
            default {
                return -code error "Bad option \"$opt\":\
                    must be -command"
            }
        }
    }

    ::xmpp::roster::metacontacts::store $xlib [serialize_contacts $xlib] \
                -command $command
}

proc metacontacts::store_contacts_result {xlib status xml} {

    if {$status == "ok"} return

    if {[winfo exists .store_contacts_error]} {
        destroy .store_contacts_error
    }
    MessageDlg .store_contacts_error -aspect 50000 -icon error \
        -message [::msgcat::mc "Storing roster metacontacts failed: %s" \
                         [error_to_string $xml]] \
        -type user -buttons ok -default 0 -cancel 0
}

proc metacontacts::edit {xlib tag {jid ""}} {
    variable contacts

    if {$tag == ""} {
        # New metacontact
        for {set i 0} {1} {incr i} {
            if {$i ni $contacts($xlib,tags)} {
                set tag $i
                break
            }
        }
    }

    set w .metacontact

    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -title [::msgcat::mc "Edit Metacontact"] \
              -modal none \
              -anchor e \
              -default 0 \
              -cancel 1

    $w add -text [::msgcat::mc "Store"] \
           -command [namespace code [list edit_enddialog $w $xlib $tag]]

    $w add -text [::msgcat::mc "Cancel"] \
           -command [list destroy $w]

    set f [$w getframe]

    set tools [Frame $f.tools]
    pack $tools -side bottom -fill x

    set sw [ScrolledWindow $w.sw]
    set lf [Listbox $w.fields]
    pack $sw -side top -expand yes -fill both -in $f -pady 1m -padx 1m
    $sw setwidget $lf

    bind $lf <<ContextMenu>> [namespace code [list select_and_popup_menu %W [double% $xlib] %x %y]]

    bind $lf <Control-Key-Up> [namespace code [list move_selected %W [double% $xlib] -1]]
    bind $lf <Control-Key-Down> [namespace code [list move_selected %W [double% $xlib] 1]]

    set addentry [Entry $tools.addentry]
    set additem [Button $tools.additem \
                     -text [::msgcat::mc "Add JID"] \
                     -command \
                     [namespace code [list add_jid_entry $lf $xlib $addentry]]]
    pack $additem -side right -padx 1m
    pack $addentry -side left -padx 1m -fill x -expand yes

    bind $addentry <Key-Return> [list $additem invoke]
    bind $addentry <Key-Return> +break

    bind $additem <Key-Return> [list $additem invoke]
    bind $additem <Key-Return> +break

    lower $lf $additem
    lower $sw
    lower $f

    if {[info exists contacts($xlib,jids,$tag)]} {
        $lf insert end {*}$contacts($xlib,jids,$tag)
    } elseif {$jid != ""} {
        $lf insert end $jid
    }

    fix_dialog_title $lf $xlib

    focus $lf

    DropSite::register $lf -dropcmd [namespace code [list dropcmd $xlib]] \
                           -droptypes {JID}

    DragSite::register $lf -draginitcmd [namespace code [list draginitcmd $xlib]]

    $w draw
}

proc metacontacts::move_selected {f xlib shift} {
    set index [$f index active]
    set item [$f get $index]
    $f delete $index
    $f insert [expr {$index + $shift}] $item
    $f activate $index

    fix_dialog_title $f $xlib
}

proc metacontacts::fix_dialog_title {f xlib} {
    set w [winfo toplevel $f]

    if {[$f size] > 0} {
        set jid [$f get 0]
        $w configure -title [::msgcat::mc "Edit %s's Metacontact" \
                                          [::roster::get_label $xlib $jid]]
    } else {
        $w configure -title [::msgcat::mc "Edit Metacontact"]
    }
}

proc metacontacts::edit_enddialog {w xlib tag} {
    variable contacts

    $w itemconfigure 0 -state disabled
    set jids [$w.fields get 0 end]
    destroy $w

    create_contact $xlib $tag $jids
    store_contacts $xlib
    redraw_roster
}

proc metacontacts::dropcmd {xlib target source X Y op type data} {
    set x [expr {$X - [winfo rootx $target]}]
    set y [expr {$Y - [winfo rooty $target]}]

    set bbox [$target bbox @$x,$y]
    if {$y > [lindex $bbox 1] + [lindex $bbox 3]} {
        set index end
    } else {
        set index [$target index @$x,$y]
    }

    add_jid $target $xlib [lindex $data 1] $index
}

proc metacontacts::draginitcmd {xlib target X Y top} {
    set x [expr {$X - [winfo rootx $target]}]
    set y [expr {$Y - [winfo rooty $target]}]

    set bbox [$target bbox @$x,$y]
    if {$y > [lindex $bbox 1] + [lindex $bbox 3]} {
        return {}
    } else {
        set jid [$target get [$target index @$x,$y]]
        set data [list $xlib $jid \
                       [::roster::itemconfig $xlib $jid -category] \
                       [::roster::itemconfig $xlib $jid -subtype] \
                       [::roster::itemconfig $xlib $jid -name] {} \
                       {}]

        return [list JID {move} $data]
    }
}

proc metacontacts::select_and_popup_menu {f xlib x y} {
    set index [$f index @$x,$y]
    $f selection clear 0 end
    $f selection set $index

    if {[winfo exists [set m .metacontact_popupmenu]]} {
        destroy $m
    }

    menu $m -tearoff 0
    $m add command -label [::msgcat::mc "Remove from metacontact"] \
                   -command [namespace code [list delete_jid $f $xlib $index]]

    tk_popup $m [winfo pointerx .] [winfo pointery .]
}

proc metacontacts::add_jid_entry {f xlib entry} {
    set item [$entry get]
    $entry delete 0 end

    add_jid $f $xlib $item
}

proc metacontacts::add_jid {f xlib item {index end}} {
    set values [$f get 0 end]
    if {[set idx [lsearch -exact $values $item]] >= 0} {
        set values [lreplace $values $idx $idx]
    }

    set values [linsert $values $index $item]

    set index [lsearch -exact $values $item]

    $f delete 0 end
    $f insert end {*}$values
    $f selection set $index

    fix_dialog_title $f $xlib
}

proc metacontacts::delete_jid {f xlib index} {
    $f delete $index

    fix_dialog_title $f $xlib
}

proc metacontacts::confirm_delete {xlib tag} {
    variable contacts

    set w .metacontact_delete

    if {[winfo exists $w]} {
        destroy $w
    }

    if {![info exists contacts($xlib,jids,$tag)] || \
            [llength $contacts($xlib,jids,$tag)] == 0} {
        set message [::msgcat::mc "Are you sure to delete metacontact?"]
    } else {
        set jid [lindex $contacts($xlib,jids,$tag) 0]
        set message [::msgcat::mc "Are you sure to delete %s's metacontact?" \
                                  [::roster::get_label $xlib $jid]]
    }

    set res [MessageDlg .metacontact_delete \
                        -aspect 50000 \
                        -icon warning \
                        -type user \
                        -buttons {yes no} \
                        -default 1 \
                        -cancel 1 \
                        -message $message]

    if {$res == 0} {
        if {[set idx [lsearch -exact $contacts($xlib,tags) $tag]] >= 0} {
            set contacts($xlib,tags) [lreplace $contacts($xlib,tags) $idx $idx]
            unset contacts($xlib,jids,$tag)
            foreach idx [array names contacts $xlib,tag,*] {
                if {[set idx1 [lsearch -exact $contacts($idx) $tag]] >= 0} {
                    set contacts($idx) [lreplace $contacts($idx) $idx1 $idx1]
                    if {[llength $contacts($idx)] == 0} {
                        unset contacts($idx)
                    }
                }
            }
        }
        store_contacts $xlib
        redraw_roster
    }
}

proc metacontacts::roster_menu {m xlib jid} {
    variable contacts

    set rjid [roster::find_jid $xlib $jid]
    if {$rjid == "" || !$::ifacetk::roster::options(enable_metacontacts)} {
        set tag ""
        set state disabled
        set state1 disabled
        set state2 disabled
    } else {
        set state normal
        if {[info exists contacts($xlib,tag,$rjid)]} {
            set tag [lindex $contacts($xlib,tag,$rjid) 0]
            set state1 disabled
            set state2 normal
            set rjid "" ; # It doesn't make sense to split this menu entry
        } else {
            set tag ""
            set state1 normal
            set state2 disabled
        }
    }

    set mm [menu $m.metacontact -tearoff 0]

    $mm add command -label [::msgcat::mc "Create metacontact"] \
                    -state $state1 \
                    -command [namespace code [list edit $xlib "" $rjid]]
    $mm add command -label [::msgcat::mc "Edit metacontact"] \
                    -state $state2 \
                    -command [namespace code [list edit $xlib $tag]]
    $mm add command -label [::msgcat::mc "Delete metacontact"] \
                    -state $state2 \
                    -command [namespace code [list confirm_delete $xlib $tag]]

    $m add cascade -label [::msgcat::mc "Metacontact"] \
                   -state $state \
                   -menu $mm
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
