# itemedit.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements user
#       interface for editing roster items properties (nickname, groups).

namespace eval ::itemedit {}

proc ::itemedit::show_dialog {xlib jid} {
    set allowed_name [jid_to_tag $jid]
    set w .gredit_[psuffix $xlib]_$allowed_name

    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -title [::msgcat::mc "Edit properties for %s" $jid] \
              -anchor e \
              -default 0 \
              -cancel 1

    set f [$w getframe]

    hook::run roster_itemedit_setup_hook $f $xlib $jid

    set g [Labelframe $f.gr -text [::msgcat::mc "Edit groups for %s" $jid] \
                            -padding {2m 2m}]
    pack $f.gr -side top -expand yes -fill both -pady 1m

    set ga [Frame $g.available]
    pack $ga -side left -expand yes -fill both

    Label $ga.title -text [::msgcat::mc "Available groups"]
    pack $ga.title -side top -anchor w
    Frame $ga.gr
    Label $ga.gr.lab -text [::msgcat::mc "Group:"]
    set gae [Entry $ga.gr.oup]
    pack $ga.gr.lab -side left
    pack $ga.gr.oup -side left -fill x -expand yes
    pack $ga.gr -side top -fill x

    set gasw [ScrolledWindow $ga.grouplist_sw]
    set gal [Listbox $ga.grouplist]
    $gasw setwidget $gal
    pack $gasw -side top -expand yes -fill both

    set gc [Frame $g.current]
    pack $gc -side right -expand yes -fill both

    Label $gc.title -text [::msgcat::mc "Current groups"]
    pack $gc.title -side top -anchor w
    set gcsw [ScrolledWindow $gc.grouplist_sw]
    set gcl [Listbox $gc.grouplist]
    $gcsw setwidget $gcl
    pack $gcsw -side top -expand yes -fill both

    Frame $g.buttons
    Button $g.buttons.add -text [::msgcat::mc "Add ->"] \
        -command "itemedit::add_group $gcl \[$ga.gr.oup get\]"
    Button $g.buttons.remove -text [::msgcat::mc "<- Remove"] \
        -command [list itemedit::remove_current_group $gcl]
    pack $g.buttons.add $g.buttons.remove -side top -fill x -anchor c
    pack $g.buttons -side left


    $w add -text [::msgcat::mc "OK"] \
        -command [list [namespace current]::commit_changes $gcl $xlib $jid]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]


    foreach group [roster::get_groups $xlib \
                       -nested $::ifacetk::roster::options(nested) \
                       -delimiter $::ifacetk::roster::options(nested_delimiter)] {
        $gal insert end $group
    }

    foreach group [roster::itemconfig $xlib $jid -group] {
        $gcl insert end $group
    }

    bindtags $gal [list [winfo class $gal] $gal [winfo toplevel $gal] all]
    bind $gal <1> [list itemedit::select_available_group %W [double% $gae]]

    $w draw
}

proc ::itemedit::edit_item_setup_fallback {f xlib jid} {
    variable gra_name

    set tf [Labelframe $f.name -text [::msgcat::mc "Edit nickname for %s" $jid] \
                               -padding {2m 2m}]
    set slaves [pack slaves $f]
    if {$slaves == ""} {
        pack $tf -side top -expand yes -fill both -pady 1m
    } else {
        pack $tf -side top -expand yes -fill both -pady 1m -before [lindex $slaves 0]
    }
    set g $tf

    Label $g.lname -text [::msgcat::mc "Nickname:"]
    set gn [Entry $g.name -textvariable [namespace current]::gra_name]

    set name [roster::itemconfig $xlib $jid -name]
    if {$name == ""} {
        if {[info exists ::userinfo::userinfo(nickname,$jid)] && \
                $::userinfo::userinfo(nickname,$jid) ne ""} {
           set name $::userinfo::userinfo(nickname,$jid)
        } else {
            set name [::xmpp::jid::node $jid]
            ::xmpp::sendIQ $xlib get \
                -query [::xmpp::xml::create vCard -xmlns vcard-temp] \
                -to [::xmpp::jid::removeResource [get_jid_of_user $xlib $jid]] \
                -command [list [namespace current]::fetch_nickname $gn $name $jid]
        }
    }
    $g.name delete 0 end
    $g.name insert 0 $name

    pack $g.lname -side left
    pack $g.name -side left -expand yes -fill x
}

hook::add roster_itemedit_setup_hook \
          ::itemedit::edit_item_setup_fallback 100

proc ::itemedit::prefs_user_menu {m xlib jid} {
    set rjid [roster::find_jid $xlib $jid]
    if {$rjid == ""} {
        set state disabled
    } else {
        set state normal
    }
    $m add command -label [::msgcat::mc "Edit item..."] \
        -command [list [namespace current]::show_dialog $xlib $rjid] \
        -state $state
}

hook::add chat_create_user_menu_hook \
          ::itemedit::prefs_user_menu 74
hook::add roster_conference_popup_menu_hook \
          ::itemedit::prefs_user_menu 74
hook::add roster_service_popup_menu_hook \
          ::itemedit::prefs_user_menu 74
hook::add roster_jid_popup_menu_hook \
          ::itemedit::prefs_user_menu 74

proc ::itemedit::add_group {grlist group} {
    set group [string trim $group]

    if {$group ne ""} {
        set groups [$grlist get 0 end]

        lappend groups $group

        set groups [lsort -unique $groups]

        $grlist delete 0 end
        $grlist insert end {*}$groups
    }
}

proc ::itemedit::select_available_group {grlist grentry} {
    if {[llength [$grlist curselection]] > 0} {
        set group [$grlist get [$grlist curselection]]
        $grentry delete 0 end
        $grentry insert 0 $group
    }
}

proc ::itemedit::remove_current_group {grlist} {
    if {[llength [$grlist curselection]] > 0} {
        $grlist delete [$grlist curselection]
    }
}

proc ::itemedit::commit_changes {grlist xlib jid} {
    hook::run roster_itemedit_commit_hook $xlib $jid [$grlist get 0 end]

    destroy [winfo toplevel $grlist]
}

proc ::itemedit::commit_changes_fallback {xlib jid groups} {
    variable gra_name

    if {![info exists gra_name]} return

    roster::itemconfig $xlib $jid \
        -name $gra_name \
        -group $groups
    roster::send_item $xlib $jid
}

hook::add roster_itemedit_commit_hook \
          ::itemedit::commit_changes_fallback 100

proc ::itemedit::fetch_nickname {name_entry name jid res child} {
    if {![winfo exists $name_entry] || ![string equal $res ok]} {
        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    foreach item $subels {
        userinfo::parse_vcard_item $jid $item
    }
    if {[info exists ::userinfo::userinfo(nickname,$jid)] && \
            $::userinfo::userinfo(nickname,$jid) ne "" && \
            [winfo exists $name_entry] && \
            [$name_entry get] ne $name} {
        $name_entry delete 0 end
        $name_entry insert 0 $::userinfo::userinfo(nickname,$jid)
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
