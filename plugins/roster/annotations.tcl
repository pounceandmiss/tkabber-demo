# annotations.tcl --
#
#       Annotations (XEP-0145) support

package require xmpp::roster::annotations

namespace eval annotations {
    # variable to store roster notes
    variable notes
    array set notes {}
}

proc annotations::free_notes {xlib} {
    variable notes

    array unset notes $xlib,*
}

hook::add disconnected_hook [namespace current]::annotations::free_notes

proc annotations::request_notes {xlib} {
    ::xmpp::roster::annotations::retrieve $xlib \
                -command [list [namespace current]::process_notes $xlib]
}

hook::add connected_hook [namespace current]::annotations::request_notes

proc annotations::process_notes {xlib status noteslist} {
    variable notes

    if {$status != "ok"} return

    free_notes $xlib

    foreach note $noteslist {
        create_note $xlib $note
    }
}

proc annotations::create_note {xlib note args} {
    variable notes

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

    array set n $note
    set jid $n(jid)

    if {!$merge || [more_recent $xlib $n(jid) $n(cdate) $n(mdate)]} {
        set notes($xlib,jid,$jid)   $n(jid)
        set notes($xlib,cdate,$jid) $n(cdate)
        set notes($xlib,mdate,$jid) $n(mdate)
        set notes($xlib,note,$jid)  $n(note)
        return 1
    } else {
        return 0
    }
}

proc annotations::more_recent {xlib jid cdate mdate} {
    variable notes

    if {![info exists notes($xlib,jid,$jid)]} {
        return 1
    } elseif {[info exists notes($xlib,mdate,$jid)]} {
        return [expr {$mdate > $notes($xlib,mdate,$jid)}]
    } elseif {[info exists notes($xlib,cdate,$jid)]} {
        return [expr {$cdate > $notes($xlib,cdate,$jid)}]
    } else {
        return 1
    }
}

proc annotations::cleanup_and_store_notes {xlib args} {
    variable notes

    set roster_jids {}
    foreach rjid [roster::get_jids $xlib] {
        lappend roster_jids [::xmpp::jid::removeResource $rjid]
    }

    foreach idx [array names notes $xlib,jid,*] {
        set jid $notes($idx)
        if {$jid ni $roster_jids || \
                ![info exists notes($xlib,note,$jid)] || \
                $notes($xlib,note,$jid) == ""} {
            catch { unset notes($xlib,jid,$jid) }
            catch { unset notes($xlib,cdate,$jid) }
            catch { unset notes($xlib,mdate,$jid) }
            catch { unset notes($xlib,note,$jid) }
        }
    }

    store_notes $xlib {*}$args
}

proc annotations::serialize_notes {xlib} {
    variable notes

    set notelist {}
    foreach idx [array names notes $xlib,jid,*] {
        set jid $notes($idx)

        if {![info exists notes($xlib,note,$jid)] || \
                $notes($xlib,note,$jid) == ""} continue

        lappend notelist [list jid $jid \
                               cdate $notes($xlib,cdate,$jid) \
                               mdate $notes($xlib,mdate,$jid) \
                               note $notes($xlib,note,$jid)]
    }

    return $notelist
}

proc annotations::store_notes {xlib args} {
    set command [list [namespace current]::store_notes_result $xlib]
    foreach {opt val} $args {
        switch -- $opt {
            -command { set command $val }
            default {
                return -code error "Bad option \"$opt\":\
                    must be -command"
            }
        }
    }

    ::xmpp::roster::annotations::store $xlib [serialize_notes $xlib] \
                -command $command
}

proc annotations::store_notes_result {xlib res child} {

    if {$res == "ok"} return

    if {[winfo exists .store_notes_error]} {
        destroy .store_notes_error
    }
    MessageDlg .store_notes_error -aspect 50000 -icon error \
        -message [::msgcat::mc "Storing roster notes failed: %s" \
                         [error_to_string $child]] \
        -type user -buttons ok -default 0 -cancel 0
}

proc annotations::add_user_popup_info {infovar xlib jid} {
    variable notes
    upvar 0 $infovar info

    set bjid [::xmpp::jid::removeResource $jid]
    lassign [::roster::get_category_and_subtype $xlib $bjid] category subtype

    if {![::xmpp::jid::equal $bjid $jid] && $category ne "user"} {
        return
    }

    if {[info exists notes($xlib,note,$bjid)] && \
            $notes($xlib,note,$bjid) != ""} {
        append info "\n\tNote:\t"
        append info [string map [list "\n" "\n\t\t"] "$notes($xlib,note,$bjid)"]

        if {0} {
            if {[info exists notes($xlib,cdate,$bjid)]} {
                append info [format "\n\tNote created: %s" \
                                 [clock format $notes($xlib,cdate,$bjid) \
                                        -format "%Y-%m-%d %T" -gmt false]]
            }
            if {[info exists notes($xlib,mdate,$bjid)]} {
                append info [format "\n\tNote modified: %s" \
                                 [clock format $notes($xlib,mdate,$bjid) \
                                        -format "%Y-%m-%d %T" -gmt false]]
            }
        }
    }
}

hook::add roster_user_popup_info_hook \
    [namespace current]::annotations::add_user_popup_info 80

proc annotations::show_dialog {xlib jid} {
    variable notes

    set jid [::xmpp::jid::removeResource $jid]

    set allowed_name [jid_to_tag $jid]
    set w .note_edit_[psuffix $xlib]_$allowed_name

    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -title [::msgcat::mc "Edit roster notes for %s" $jid] \
        -modal none -anchor e \
        -default 0 -cancel 1

    $w add -text [::msgcat::mc "Store"] \
        -command [list [namespace current]::commit_changes $w $xlib $jid]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set f [$w getframe]

    if {[info exists notes($xlib,cdate,$jid)]} {
        Label $f.cdate -text [::msgcat::mc "Created: %s" \
                                     [clock format $notes($xlib,cdate,$jid) \
                                            -format "%Y-%m-%d %T" -gmt false]]
        pack $f.cdate -side top -anchor w
    }

    if {[info exists notes($xlib,mdate,$jid)]} {
        Label $f.mdate -text [::msgcat::mc "Modified: %s" \
                                     [clock format $notes($xlib,mdate,$jid) \
                                            -format "%Y-%m-%d %T" -gmt false]]
        pack $f.mdate -side top -anchor w
    }

    ScrolledWindow $f.sw
    pack $f.sw -side top -expand yes -fill both
    textUndoable $f.note -width 50 -height 5 -wrap word
    if {[info exists notes($xlib,note,$jid)]} {
        $f.note insert 0.0 $notes($xlib,note,$jid)
    }
    $f.sw setwidget $f.note

    bind [Wrapped $f.note] <Control-Key-Return> "[double% $w] invoke default
                                       break"
    bind $w <Key-Return> { }
    bind $w <Control-Key-Return> "[double% $w] invoke default
                                  break"

    $w draw $f.note
}

proc annotations::commit_changes {w xlib jid} {
    variable notes

    set text [$w getframe].note

    set date [clock seconds]

    set notes($xlib,jid,$jid) $jid
    if {![info exists notes($xlib,cdate,$jid)]} {
        set notes($xlib,cdate,$jid) $date
    }
    set notes($xlib,mdate,$jid) $date
    set notes($xlib,note,$jid) [$text get 0.0 "end -1 char"]

    cleanup_and_store_notes $xlib

    destroy $w
}

proc annotations::prefs_user_menu {m xlib jid} {
    set rjid [roster::find_jid $xlib $jid]
    if {$rjid == ""} {
        set state disabled
    } else {
        set state normal
    }
    $m add command -label [::msgcat::mc "Edit item notes..."] \
        -command [list [namespace current]::show_dialog $xlib $rjid] \
        -state $state
}

hook::add chat_create_user_menu_hook \
    [namespace current]::annotations::prefs_user_menu 76
hook::add roster_conference_popup_menu_hook \
    [namespace current]::annotations::prefs_user_menu 76
hook::add roster_service_popup_menu_hook \
    [namespace current]::annotations::prefs_user_menu 76
hook::add roster_jid_popup_menu_hook \
    [namespace current]::annotations::prefs_user_menu 76

proc annotations::note_page {tab xlib jid editable} {
    variable notes

    if {$editable} return

    set bjid [::xmpp::jid::removeResource $jid]
    lassign [::roster::get_category_and_subtype $xlib $bjid] category subtype

    if {![::xmpp::jid::equal $bjid $jid] && $category ne "user"} {
        return
    }

    if {![info exists notes($xlib,note,$bjid)] || \
            $notes($xlib,note,$bjid) == ""} {
        return
    }

    set notestab [$tab insert end notes -text [::msgcat::mc "Notes"]]
    set n [userinfo::pack_frame $notestab.notes [::msgcat::mc "Roster Notes"]]

    if {[info exists notes($xlib,cdate,$bjid)]} {
        Label $n.cdate -text [::msgcat::mc "Created: %s" \
                                     [clock format $notes($xlib,cdate,$bjid) \
                                            -format "%Y-%m-%d %T" -gmt false]]
        pack $n.cdate -side top -anchor w
    }

    if {[info exists notes($xlib,mdate,$bjid)]} {
        Label $n.mdate -text [::msgcat::mc "Modified: %s" \
                                     [clock format $notes($xlib,mdate,$bjid) \
                                            -format "%Y-%m-%d %T" -gmt false]]
        pack $n.mdate -side top -anchor w
    }

    set sw [ScrolledWindow $n.sw -scrollbar vertical]
    Text $n.text -height 12 -wrap word
    $sw setwidget $n.text
    $n.text insert 0.0 $notes($xlib,note,$bjid)
    $n.text configure -state disabled
    pack $sw -side top -fill both -expand yes
    pack $n -fill both -expand yes
}

hook::add userinfo_hook [namespace current]::annotations::note_page 40

# vim:ft=tcl:ts=8:sw=4:sts=4:et
