# muc.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements an
#       interface part of Multi-User Conferences (dialogs, menus).

namespace eval muc {
    variable winid 0

    # MUC affiliations and roles:
    variable e2l
    variable l2e

    array set e2l [list owner       [::msgcat::mc "owner"] \
                        admin       [::msgcat::mc "admin"] \
                        member      [::msgcat::mc "member"] \
                        outcast     [::msgcat::mc "outcast"] \
                        none        [::msgcat::mc "none"] \
                        moderator   [::msgcat::mc "moderator"] \
                        participant [::msgcat::mc "participant"] \
                        visitor     [::msgcat::mc "visitor"]]

    variable maxl 0
    variable n
    variable l
    foreach n [array names e2l] {
        set l2e($e2l($n)) $n
        set l [string length $e2l($n)]
        if {$l + 2 > $maxl} {
            set maxl [expr {$l + 2}]
        }
    }

    namespace export join_group_dialog add_muc_menu_items
}

namespace eval :: {
    custom::defvar gr_nick_list {} \
            [::msgcat::mc "Join group dialog data (nicks)."] -group Hidden
    custom::defvar gr_group_list {} \
            [::msgcat::mc "Join group dialog data (groups)."] -group Hidden
    custom::defvar gr_server_list {} \
            [::msgcat::mc "Join group dialog data (servers)."] -group Hidden
}

###############################################################################

proc muc::join_group_dialog {xlib args} {
    global gr_nick_list gr_group_list gr_server_list

    if {[llength [connections]] == 0} return

    if {[llength $gr_group_list] > 0} {
        set gr_group [lindex $gr_group_list 0]
    } else {
        set gr_group jabber
    }
    if {[llength $gr_server_list] > 0} {
        set gr_server [lindex $gr_server_list 0]
    } else {
        set gr_server conference.jabber.org
    }
    if {[string equal $xlib ""]} {
        set xlib [lindex [connections] 0]
    }
    set gr_xlib [connection_jid $xlib]

    set gr_nick [get_group_nick $xlib [::xmpp::jid::jid $gr_group $gr_server]]
    set gr_passwd ""
    foreach {opt val} $args {
        switch -- $opt {
            -server     {set gr_server $val}
            -group      {set gr_group $val}
            -nick       {set gr_nick $val}
            -password   {set gr_passwd $val}
        }
    }

    set gw .joingroup
    catch { destroy $gw }

    Dialog $gw -title [::msgcat::mc "Join group"] \
               -anchor e \
               -default 0 \
               -cancel 1 \
               -modal none

    set gf [$gw getframe]
    grid columnconfigure $gf 1 -weight 1

    Label $gf.lgroup -text [::msgcat::mc "Group:"]
    Combobox $gf.group -values $gr_group_list
    $gf.group set $gr_group
    Label $gf.lserver -text [::msgcat::mc "Server:"]
    Combobox $gf.server -values $gr_server_list
    $gf.server set $gr_server
    Label $gf.lnick -text [::msgcat::mc "Nick:"]
    Combobox $gf.nick -values $gr_nick_list
    $gf.nick set $gr_nick

    Label $gf.lpasswd -text [::msgcat::mc "Password:"]
    Entry $gf.passwd -text $gr_passwd -width 30 -show *

    grid $gf.lgroup  -row 0 -column 0 -sticky e
    grid $gf.group   -row 0 -column 1 -sticky ew
    grid $gf.lserver -row 1 -column 0 -sticky e
    grid $gf.server  -row 1 -column 1 -sticky ew
    grid $gf.lnick   -row 2 -column 0 -sticky e
    grid $gf.nick    -row 2 -column 1 -sticky ew
    grid $gf.lpasswd -row 3 -column 0 -sticky e
    grid $gf.passwd  -row 3 -column 1 -sticky ew

    if {[llength [connections]] > 1} {
        foreach c [connections] {
            lappend connections [connection_jid $c]
        }
        Label $gf.lxlib -text [::msgcat::mc "Connection:"]
        Combobox $gf.xlib -values $connections
        $gf.xlib set $gr_xlib

        grid $gf.lxlib -row 4 -column 0 -sticky e
        grid $gf.xlib  -row 4 -column 1 -sticky ew
    }

    $gw add -text [::msgcat::mc "Join"] \
            -command [namespace code [list join_group_dialog_continue $gw $gf]]
    $gw add -text [::msgcat::mc "Cancel"] -command [list destroy $gw]
    $gw draw $gf.gr_group
}

proc muc::join_group_dialog_continue {gw gf} {
    global gr_nick_list gr_group_list gr_server_list

    set gr_group  [$gf.group  get]
    set gr_server [$gf.server get]
    set gr_nick   [$gf.nick   get]
    set gr_passwd [$gf.passwd get]
    catch {set gr_xlib [$gf.xlib get]}

    destroy $gw

    set gr_group_list  [update_combo_list $gr_group_list  $gr_group  20]
    set gr_server_list [update_combo_list $gr_server_list $gr_server 10]
    set gr_nick_list   [update_combo_list $gr_nick_list   $gr_nick   10]

    if {[info exists gr_xlib]} {
        foreach c [connections] {
            if {[connection_jid $c] eq $gr_xlib} {
                set xlib $c
            }
        }
    }

    if {![info exists xlib]} {
        set xlib [lindex [connections] 0]
    }

    muc::join_group_raise $xlib \
                          [::xmpp::jid::jid $gr_group $gr_server] \
                          $gr_nick \
                          $gr_passwd
}

###############################################################################

proc muc::add_groupchat_user_menu_items {type m xlib jid} {
    set group [::xmpp::jid::removeResource $jid]

    if {![muc::is_compatible $group]} return

    set chatid [chat::chatid $xlib $group]

    if {![chat::is_groupchat $chatid]} {
        return
    }

    switch -- $type {
        chat { set reschatid [chat::chatid $xlib $jid] }
        roster { set reschatid $chatid }
    }

    set mm [menu $m.muc -tearoff 0]
    $mm add command -label [::msgcat::mc "Whois"] \
        -command [list muc::whois $xlib $jid $reschatid]
    $mm add command -label [::msgcat::mc "Kick"] \
        -command [list muc::change_item_attr \
                      $xlib $jid role none down "" $reschatid]
    $mm add command -label [::msgcat::mc "Ban"] \
        -command [list muc::change_item_attr \
                      $xlib $jid affiliation outcast down "" $reschatid]
    $mm add command -label [::msgcat::mc "Grant Voice"] \
        -command [list muc::change_item_attr \
                      $xlib $jid role participant up "" $reschatid]
    $mm add command -label [::msgcat::mc "Revoke Voice"] \
        -command [list muc::change_item_attr \
                      $xlib $jid role visitor down "" $reschatid]
    $mm add command -label [::msgcat::mc "Grant Membership"] \
        -command [list muc::change_item_attr \
                      $xlib $jid affiliation member up "" $reschatid]
    $mm add command -label [::msgcat::mc "Revoke Membership"] \
        -command [list muc::change_item_attr \
                      $xlib $jid affiliation none down "" $reschatid]
    $mm add command -label [::msgcat::mc "Grant Moderator Privileges"] \
        -command [list muc::change_item_attr \
                      $xlib $jid role moderator up "" $reschatid]
    $mm add command -label [::msgcat::mc "Revoke Moderator Privileges"] \
        -command [list muc::change_item_attr \
                      $xlib $jid role participant down "" $reschatid]
    $mm add command -label [::msgcat::mc "Grant Admin Privileges"] \
        -command [list muc::change_item_attr \
                      $xlib $jid affiliation admin up "" $reschatid]
    $mm add command -label [::msgcat::mc "Revoke Admin Privileges"] \
        -command [list muc::change_item_attr \
                      $xlib $jid affiliation member down "" $reschatid]
    #$mm add command -label [::msgcat::mc "Grant Owner Privileges"] \
    #    -command [list muc::change_item_attr \
    #                 $xlib $jid affiliation owner up "" $reschatid]
    #$mm add command -label [::msgcat::mc "Revoke Owner Privileges"] \
    #    -command [list muc::change_item_attr \
    #                 $xlib $jid affiliation admin down "" $reschatid]

    $m add cascade -label [::msgcat::mc "MUC"] -menu $mm
}

hook::add chat_create_user_menu_hook \
          [list [namespace current]::muc::add_groupchat_user_menu_items \
                chat] 43
hook::add roster_create_groupchat_user_menu_hook \
          [list [namespace current]::muc::add_groupchat_user_menu_items \
                roster] 39

###############################################################################

proc muc::add_muc_menu_items {m xlib group {state disabled}} {
    if {[muc::is_compatible $group]} {
        set state normal
    }

    set chatid [chat::chatid $xlib $group]

    set mm [menu $m.muc -tearoff 0]

    $mm add command -label [::msgcat::mc "Configure room"] \
        -command [list muc::request_config $chatid]
    $mm add command -label [::msgcat::mc "Edit voice list"] \
        -command [namespace code [list request_roles_list participant $chatid]]
    $mm add command -label [::msgcat::mc "Edit ban list"] \
        -command [namespace code [list request_affiliations_list \
                                       outcast $chatid]]
    $mm add command -label [::msgcat::mc "Edit member list"] \
        -command [namespace code [list request_affiliations_list \
                                       member $chatid]]
    $mm add command -label [::msgcat::mc "Edit moderator list"] \
        -command [namespace code [list request_roles_list moderator $chatid]]
    $mm add command -label [::msgcat::mc "Edit admin list"] \
        -command [namespace code [list request_affiliations_list \
                                       admin $chatid]]
    $mm add command -label [::msgcat::mc "Edit owner list"] \
        -command [namespace code [list request_affiliations_list \
                                       owner $chatid]]
    $mm add separator
    $mm add command -label [::msgcat::mc "Destroy room"] \
        -command [namespace code [list request_destruction_dialog \
                                       $chatid "" ""]]

    $m add cascade -label [::msgcat::mc "MUC"] -menu $mm -state $state
}

hook::add chat_create_conference_menu_hook \
          [namespace current]::muc::add_muc_menu_items 37

proc muc::add_edit_info_menu_item {m xlib group} {
    $m add command -label [::msgcat::mc "Edit room info..."] \
       -command [list ::userinfo::open $xlib $group -editable 1]
}

hook::add chat_create_conference_menu_hook \
          [namespace current]::muc::add_edit_info_menu_item 37

proc muc::disco_node_menu_setup {m bw tnode data parentdata} {
    lassign $data type xlib jid node
    switch -- $type {
        item -
        item2 {
            set identities [disco::browser::get_identities $bw $tnode]

            if {[llength $identities] == 0} {
                set identities \
                    [disco::browser::get_parent_identities $bw $tnode]
            }

            set features [disco::browser::get_features $bw $tnode]

            if {[llength $features] == 0} {
                set features [disco::browser::get_parent_features $bw $tnode]
            }

            # JID with resource is not a room JID
            if {[::xmpp::jid::removeResource $jid] ne $jid} return

            # A room must have non-empty node
            if {[::xmpp::jid::node $jid] eq ""} return

            foreach id $identities {
                if {[get_prop $id category] eq "conference"} {
                    if {"http://jabber.org/protocol/muc" in $features} {
                        add_muc_menu_items $m $xlib $jid normal
                        break
                    }
                }
            }
        }
    }
}

hook::add disco_node_menu_hook \
          [namespace current]::muc::disco_node_menu_setup 60

###############################################################################

proc muc::request_destruction_dialog {chatid alt reason} {
    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]

    set w .muc_request_destruction
    if {[info exists $w]} {
        destroy $w
    }

    set res [MessageDlg $w \
                        -aspect 50000 \
                        -icon warning \
                        -type user \
                        -buttons [list [::msgcat::mc "Destroy room"] cancel] \
                        -default 1 \
                        -cancel 1 \
                        -message [::msgcat::mc "Conference room %s will be\
                                        destroyed permanently.\n\nProceed?" \
                                        $group]]
    if {!$res} {
        set args [list -command [list muc::test_error_res "destroy" $xlib \
                                      $group $chatid]]
        if {![string equal $alt ""]} {
            lappend args -jid $alt
        }
        if {![string equal $reason ""]} {
            lappend args -reason $reason
        }
        ::xmpp::muc::destroy $xlib $group {*}$args
    }
}

###############################################################################

proc muc::request_affiliations_list {val chatid} {
    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]

    ::xmpp::muc::requestAffiliations $xlib $group $val \
            -command [namespace code [list receive_list affiliation \
                                           $val $chatid]]
}

proc muc::request_roles_list {val chatid} {
    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]

    ::xmpp::muc::requestRoles $xlib $group $val \
            -command [namespace code [list receive_list role $val $chatid]]
}

proc muc::receive_list {attr val chatid res items} {
    variable e2l
    variable maxl

    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]
    if {![string equal $res ok]} {
        chat::add_message $chatid $group error \
            "$attr $val list: [error_to_string $items]" {}
        return
    }

    variable winid

    set w .muc_list$winid
    incr winid

    if {[winfo exists $w]} {
        destroy $w
    }

    # [format] is intentional here. After %s substitution, it becomes
    # one of the following:
    # [::msgcat::mc "Edit owner list"]
    # [::msgcat::mc "Edit admin list"]
    # [::msgcat::mc "Edit member list"]
    # [::msgcat::mc "Edit outcast list"]
    # [::msgcat::mc "Edit moderator list"]
    # [::msgcat::mc "Edit participant list"]
    # [::msgcat::mc "Edit visitor list"]
    Dialog $w -title [::msgcat::mc [format "Edit %s list" $val]] \
              -modal none \
              -anchor e \
              -default 0 \
              -cancel 1

    set wf [$w getframe]

    set sw [ScrolledWindow $wf.sw]

    set lb [::mclistbox::mclistbox $sw.listbox \
                    -exportselection 0 \
                    -width 90 \
                    -height 16]

    bind $lb <Destroy> [namespace code [list list_cleanup %W]]

    bind $lb <<ListboxSelect>> \
             [namespace code [list update_fields %W [double% $val] \
                                   [double% $w.fr1]]]

    $sw setwidget $lb
    fill_list $lb $items $attr $val

    $w add -text [::msgcat::mc "Update list"] \
        -command [namespace code [list send_list $chatid $attr $val $w $lb]]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]


    Frame $w.fr1
    pack $w.fr1 -side bottom -in $wf -fill x -pady 1m

    grid columnconfigure $w.fr1 3 -weight 1

    Label $w.fr1.lnick -text [::msgcat::mc "Nick"]
    Label $w.fr1.ljid -text [::msgcat::mc "JID"]
    switch -- $attr {
        role {
            Label $w.fr1.lattr -text [::msgcat::mc "Role"]
        }
        affiliation {
            Label $w.fr1.lattr -text [::msgcat::mc "Affiliation"]
        }
    }
    Label $w.fr1.lreason -text [::msgcat::mc "Reason"]

    grid $w.fr1.lnick   -row 0 -column 0 -sticky w
    grid $w.fr1.ljid    -row 0 -column 1 -sticky w
    grid $w.fr1.lattr   -row 0 -column 2 -sticky w
    grid $w.fr1.lreason -row 0 -column 3 -sticky w

    Entry $w.fr1.nick1 -takefocus 0
    $w.fr1.nick1:cmd configure -state readonly
    Entry $w.fr1.jid1 -takefocus 0
    $w.fr1.jid1:cmd configure -state readonly

    switch -- $attr {
        role {
            Combobox $w.fr1.attr1 \
                -values [list $e2l(moderator) $e2l(participant) \
                              $e2l(visitor) $e2l(none)] \
                -editable no \
                -width $maxl
        }
        affiliation {
            Combobox $w.fr1.attr1 \
                -values [list $e2l(owner) $e2l(admin) $e2l(member) \
                              $e2l(none) $e2l(outcast)] \
                -editable no \
                -width $maxl
        }
    }
    $w.fr1.attr1 set $e2l($val)

    Entry $w.fr1.reason1

    Button $w.fr1.update -text [::msgcat::mc "Update item"] \
                         -command [namespace code [list list_update_item $lb \
                                                        $attr $w.fr1]]

    grid $w.fr1.nick1   -row 1 -column 0 -sticky ew
    grid $w.fr1.jid1    -row 1 -column 1 -sticky ew
    grid $w.fr1.attr1   -row 1 -column 2 -sticky ew
    grid $w.fr1.reason1 -row 1 -column 3 -sticky ew
    grid $w.fr1.update  -row 1 -column 4 -sticky ew

    Entry $w.fr1.nick2
    Entry $w.fr1.jid2

    switch -- $attr {
        role {
            Combobox $w.fr1.attr2 \
                -values [list $e2l(moderator) $e2l(participant) \
                              $e2l(visitor) $e2l(none)] \
                -editable no \
                -width $maxl
        }
        affiliation {
            Combobox $w.fr1.attr2 \
                -values [list $e2l(owner) $e2l(admin) $e2l(member) \
                              $e2l(none) $e2l(outcast)] \
                -editable no \
                -width $maxl
        }
    }
    $w.fr1.attr2 set $e2l($val)

    Entry $w.fr1.reason2

    Button $w.fr1.add -text [::msgcat::mc "Add new item"] \
                      -command [namespace code [list list_add_item $lb $val \
                                                     $w.fr1]]

    grid $w.fr1.nick2   -row 2 -column 0 -sticky ew
    grid $w.fr1.jid2    -row 2 -column 1 -sticky ew
    grid $w.fr1.attr2   -row 2 -column 2 -sticky ew
    grid $w.fr1.reason2 -row 2 -column 3 -sticky ew
    grid $w.fr1.add     -row 2 -column 4 -sticky ew

    Frame $w.fr1.fr

    Label $w.lall -text [::msgcat::mc "All items:"]
    pack $w.lall -side left -in $w.fr1.fr -padx 1m -pady 1m

    switch -- $attr {
        role {
            Combobox $w.roleall \
                -values [list $e2l(moderator) $e2l(participant) \
                              $e2l(visitor) $e2l(none)] \
                -editable no \
                -width $maxl \
                -modifycmd [namespace code [list change_all_items $lb \
                                                 $w.roleall $attr]]
            $w.roleall set $e2l($val)
            pack $w.roleall -side left -anchor w -in $w.fr1.fr -pady 1m
        }
        affiliation {
            Combobox $w.affiliationall \
                -values [list $e2l(owner) $e2l(admin) $e2l(member) \
                              $e2l(none) $e2l(outcast)] \
                -editable no \
                -width $maxl \
                -modifycmd [namespace code [list change_all_items $lb \
                                                 $w.affiliationall $attr]]
            $w.affiliationall set $e2l($val)
            pack $w.affiliationall -side left -in $w.fr1.fr -pady 1m
        }
    }

    grid $w.fr1.fr -row 3 -column 0 -columnspan 5 -sticky w

    pack $sw -side top -expand yes -fill both

    bindscroll $sw $lb

    hook::run open_muc_list_post_hook $w $sw $lb

    $w draw
}

###############################################################################

proc muc::update_fields {lb val fr} {
    set selection [$lb curselection]
    if {[llength $selection] == 0} {
        set nick ""
        set jid ""
        set attr $val
        set reason ""
    } else {
        set data [$lb get [lindex $selection 0]]
        lassign $data n nick jid attr reason
    }

    $fr.nick1:cmd configure -state normal
    $fr.nick1 delete 0 end
    $fr.nick1 insert 0 $nick
    $fr.nick1:cmd configure -state readonly
    $fr.jid1:cmd configure -state normal
    $fr.jid1 delete 0 end
    $fr.jid1 insert 0 $jid
    $fr.jid1:cmd configure -state readonly
    $fr.attr1 set $attr
    $fr.reason1 delete 0 end
    $fr.reason1 insert 0 $reason
}

proc muc::list_update_item {lb attr fr} {
    set selection [$lb curselection]
    if {[llength $selection] == 0} {
        return
    }
    set idx [lindex $selection 0]
    set data [lrange [$lb get $idx] 0 0]

    lappend data [$fr.nick1 get] \
                 [$fr.jid1 get] \
                 [$fr.attr1 get] \
                 [$fr.reason1 get]

    incr idx
    $lb insert $idx $data
    incr idx -1
    $lb delete $idx
    $lb sel clear 0 end
    $lb sel set $idx
}

proc muc::change_all_items {lb combobox attr} {
    set value [$combobox get]

    set yposition [lindex [$lb yview] 0]
    set data [$lb get 0 end]
    set result {}
    set i 0
    foreach row $data {
        lappend result [lreplace $row 3 3 $value]
    }
    $lb delete 0 end
    $lb insert end {*}$result
    $lb yview moveto $yposition
}

###############################################################################

proc muc::fill_list {lb items attr val} {
    variable listdata
    variable e2l
    variable maxl

    set width(0) 1
    set name(0) n
    $lb column add n -label [::msgcat::mc "#"]

    set width(1) [string length [::msgcat::mc "Nick"]]
    set name(1) nick
    $lb column add nick -label [::msgcat::mc "Nick"] \
                        -image search/sort/noArrow \
                        -command [list search::Sort $lb nick]

    set width(2) [string length [::msgcat::mc "JID"]]
    set name(2) jid
    $lb column add jid -label [::msgcat::mc "JID"] \
                       -image search/sort/downArrow \
                       -command [list search::Sort $lb jid]

    switch -- $attr {
        role {
            set width(3) [string length [::msgcat::mc "Role"]]
            if {$width(3) < $maxl} {
                set width(3) $maxl
            }
            set name(3) role
            $lb column add role -label [::msgcat::mc "Role"] \
                                -image search/sort/noArrow \
                                -command [list search::Sort $lb role]
        }
        affiliation {
            set width(3) [string length [::msgcat::mc "Affiliation"]]
            if {$width(3) < $maxl} {
                set width(3) $maxl
            }
            set name(3) affiliation
            $lb column add affiliation -label [::msgcat::mc "Affiliation"] \
                                       -image search/sort/noArrow \
                                       -command [list search::Sort $lb \
                                                      affiliation]
        }
    }

    set width(4) [string length [::msgcat::mc "Reason"]]
    set name(4) reason
    $lb column add reason -label [::msgcat::mc "Reason"] \
                          -image search/sort/noArrow \
                          -command [list search::Sort $lb reason]

    $lb column add lastcol -label "" -width 0
    $lb configure -fillcolumn lastcol

    set items2 {}
    foreach item $items {
        lassign $item nick jid attribute reason
        lappend items2 [list $nick $jid $e2l($attribute) $reason]
    }

    for {set i 0} {$i < 5} {incr i} {
        incr width($i) 3
    }

    set listdata($lb) [lsort -dictionary -index 1 $items2]
    set row 1
    foreach item $listdata($lb) {
        set itemdata {}
        set i 0
        foreach data [linsert $item 0 $row] {
            set wd [string length $data]
            if {$wd > $width($i)} {
                if {$wd > 50} {
                    set width($i) 50
                } else {
                    set width($i) $wd
                }
            }
            lappend itemdata $data
            incr i
        }
        lappend itemdata ""
        $lb insert end $itemdata

        incr row
    }

    for {set i 0} {$i < 5} {incr i} {
        $lb column configure $name($i) -width [expr {$width($i) + 2}]
    }
}

###############################################################################

proc muc::list_add_item {lb val fr} {
    variable e2l

    set n [lindex [$lb get end] 0]
    if {[string equal $n ""]} {
        set n 0
    }

    set data [list [incr n] \
                   [$fr.nick2 get] \
                   [$fr.jid2 get] \
                   [$fr.attr2 get] \
                   [$fr.reason2 get]]

    $lb insert end $data

    $fr.nick2 delete 0 end
    $fr.jid2 delete 0 end
    $fr.attr2 set $e2l($val)
    $fr.reason2 delete 0 end
}

###############################################################################

proc muc::send_list {chatid attr val w lb} {
    variable listdata
    variable l2e

    foreach item $listdata($lb) {
        set tmp([lrange $item 0 1]) $item
    }

    set items {}
    foreach item [$lb get 0 end] {
        lassign $item n nick jid val reason
        set nick $nick
        set jid $jid

        if {$nick eq "" && $jid eq ""} {
            continue
        }

        set val $val
        set reason $reason

        if {[info exists tmp([list $nick $jid])] &&
                $tmp([list $nick $jid]) eq [list $nick $jid $val $reason]} {
            continue
        }

        lappend items [list $nick $jid $l2e($val) $reason]
    }

    if {$items ne {}} {
        set xlib [chat::get_xlib $chatid]
        set group [chat::get_jid $chatid]

        set newArgs [list \
            -command [list muc::test_error_res \
                           [::msgcat::mc "Sending %s %s list" $attr $val] \
                           $xlib $group $chatid]]

        switch -- $attr {
            affiliation {
                ::xmpp::muc::sendAffiliations $xlib $group $items {*}$newArgs
            }
            role {
                ::xmpp::muc::sendRoles $xlib $group $items {*}$newArgs
            }
        }
    }
    destroy $w
}

proc muc::list_cleanup {f} {
    variable listdata

    catch {unset listdata($f)}
}

###############################################################################

proc muc::joingroup_disco_node_menu_setup {m bw tnode data parentdata} {
    lassign $data type xlib jid node
    switch -- $type {
        item -
        item2 {
            set identities [::disco::browser::get_identities $bw $tnode]

            if {[llength $identities] == 0} {
                set identities \
                    [::disco::browser::get_parent_identities $bw $tnode]
            }

            # JID with resource is not a room JID
            if {[::xmpp::jid::resource $jid] ne ""} return

            foreach id $identities {
                if {[string equal [get_prop $id category] conference]} {
                    $m add command -label [::msgcat::mc "Join group..."] \
                        -command [namespace code \
                                    [list join_group_dialog $xlib \
                                          -server [::xmpp::jid::server $jid] \
                                          -group [::xmpp::jid::node $jid]]]
                    break
                }
            }
        }
    }
}

hook::add disco_node_menu_hook \
          [namespace current]::muc::joingroup_disco_node_menu_setup 45

###############################################################################

proc muc::join {xlib jid args} {
    set category conference
    foreach {opt val} $args {
        switch -- $opt {
            -category { set category $val }
        }
    }

    if {![string equal $category conference]} return

    if {![string equal [::xmpp::jid::node $jid] ""]} {
        muc::join_group_raise $xlib $jid [get_group_nick $xlib $jid] ""
    } else {
        join_group_dialog $xlib -server [::xmpp::jid::server $jid] -group {}
    }
}

hook::add postload_hook \
    [list disco::browser::register_feature_handler jabber:iq:conference \
         [namespace current]::muc::join \
         -desc [list conference [::msgcat::mc "Join conference"]]]
hook::add postload_hook \
    [list disco::browser::register_feature_handler \
         http://jabber.org/protocol/muc \
         [namespace current]::muc::join \
         -desc [list conference [::msgcat::mc "Join conference"]]]
hook::add postload_hook \
    [list disco::browser::register_feature_handler "gc-1.0" \
         [namespace current]::muc::join \
         -desc [list conference [::msgcat::mc "Join groupchat"]]]

###############################################################################

namespace eval :: {
    namespace import ::ifacetk::muc::join_group_dialog \
                     ::ifacetk::muc::add_muc_menu_items
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
