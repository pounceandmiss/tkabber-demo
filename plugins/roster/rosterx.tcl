# rosterx.tcl --
#
#       Roster Item Exchange Support (XEP-0093 and XEP-0144)

namespace eval rosterx {}

###############################################################################

proc rosterx::process_x {rowvar bodyvar f x xlib from id type replyP} {
    upvar 2 $rowvar row
    upvar 2 $bodyvar body

    set rosterx 0
    foreach xa $x {
        ::xmpp::xml::split $xa tag xmlns attrs cdata subels

        switch -- $xmlns \
            $::NS(rosterx) {
                set rosterx 1
                foreach subel $subels {
                    process_x_rosterx $f $subel $row $xlib $from
                    incr row
                }
            } \
            $::NS(xroster) {
                if {$rosterx} break
                foreach subel $subels {
                    process_x_xroster $f $subel $row $xlib $from
                    incr row
                }
            }
        }

    return
}

hook::add message_process_x_hook [namespace current]::rosterx::process_x 60
::xmpp::iq::register set x $::NS(rosterx) \
                     [namespace current]::rosterx::process_x_iq

###############################################################################

proc rosterx::process_x_iq {xlib from stanza args} {
    set choices {}
    set balloons {}
    global recv_uc
    variable dlg

    ::xmpp::xml::split $stanza tag xmlns attrs cdata subels
    foreach c $subels {
        lassign [process_item $c] jid name groups desc
        if {[::roster::find_jid $xlib $jid] eq ""} {
            lappend choices [list $jid $name $groups] $desc
        }
    }

    if {[llength $choices] == 0} {
        return {result ""}
    }

    set d .dlg[incr dlg]
    CbDialog $d [::msgcat::mc "Attached user:"] \
            [list "Ok" \
            [list [namespace current]::process_item_selection $d $xlib $from] \
            [::msgcat::mc "Cancel"] [list destroy $d]] \
            recv_uc $choices $balloons

    return {result ""}
}

###############################################################################

proc rosterx::process_item_selection {d xlib from} {
    global recv_uc

    foreach uc [array names recv_uc] {
        if {$recv_uc($uc)} {
            set jid [lindex $uc 0]
            set name [lindex $uc 1]
            set groups [lindex $uc 2]
            [namespace current]::process_user $xlib $jid $name \
                    "$from asked me to add you to my roster." $groups
        }
    }
    destroy $d

}

###############################################################################

proc rosterx::process_item {item} {

    ::xmpp::xml::split $item tag xmlns attrs cdata subels

    set jid    [::xmpp::xml::getAttr $attrs jid]
    set name   [::xmpp::xml::getAttr $attrs name]
    set action [::xmpp::xml::getAttr $attrs action]

    if {$jid == ""} return
    if {$action != "add"} return

    if {$name != ""} {
        set desc "$name ($jid)"
    } else {
        set desc $jid
    }
    set groups [list]
    foreach group $subels {
        ::xmpp::xml::split $group gtag gxmlns gattrs gcdata gsubels
        lappend groups $gcdata
    }
    return [list $jid $name $groups $desc]
}

###############################################################################

proc rosterx::process_x_rosterx {f x row xlib from} {
    ::xmpp::xml::split $x tag xmlns attrs cdata subels

    set jid    [::xmpp::xml::getAttr $attrs jid]
    set name   [::xmpp::xml::getAttr $attrs name]
    set action [::xmpp::xml::getAttr $attrs action]

    if {$jid == ""} return

    if {$name != ""} {
        set desc "$name ($jid)"
    } else {
        set desc $jid
    }

    Label $f.luser$row -text [::msgcat::mc "Attached user:"]
    set cb [Button $f.user$row -text $desc \
                -command [list [namespace current]::process_user $xlib $jid \
                               $name "$from asked me to add you to my roster."]]
    grid $f.luser$row -row $row -column 0 -sticky e
    grid $f.user$row  -row $row -column 1 -sticky ew
}

###############################################################################

proc rosterx::process_x_xroster {f x row xlib from} {
    ::xmpp::xml::split $x tag xmlns attrs cdata subels

    set jid  [::xmpp::xml::getAttr $attrs jid]
    set name [::xmpp::xml::getAttr $attrs name]

    if {$jid == ""} return

    if {$name != ""} {
        set desc "$name ($jid)"
    } else {
        set desc $jid
    }

    Label $f.luser$row -text [::msgcat::mc "Attached user:"]
    set cb [Button $f.user$row -text $desc \
                -command [list [namespace current]::process_user $xlib $jid \
                               $name "$from asked me to add you to my roster."]]
    grid $f.luser$row -row $row -column 0 -sticky e
    grid $f.user$row  -row $row -column 1 -sticky ew
}

###############################################################################

proc rosterx::process_user {xlib jid name body {groups {}}} {
    ::xmpp::sendPresence $xlib -to $jid \
                               -type subscribe \
                               -status $body

    set vars [list -jid $jid]
    if {$name != ""} {
        lappend vars -name $name
    }

    ::xmpp::roster::send $::roster::roster(token,$xlib) {*}$vars -groups $groups
}

###############################################################################

proc rosterx::send_users_dialog {xlib user} {
    global send_uc

    set jid [get_jid_of_user $xlib $user]

    if {$jid eq ""} {
        set jid $user
    }

    set gw .contacts
    catch { destroy $gw }

    if {[catch { set nick [roster::get_label $xlib $user] }]} {
        if {[catch { set nick [chat::get_nick $xlib \
                                              $user groupchat] }]} {
            set nick $user
        }
    }

    set choices {}
    set balloons {}
    foreach c [connections] {
        foreach choice [roster::get_jids $c] {
            if {[roster::itemconfig $c $choice -isuser]} {
                lappend choices [list $c $choice] [roster::get_label $c $choice]
                lappend balloons [list $c $choice] $choice
            }
        }
    }
    if {[llength $choices] == 0} {
        MessageDlg ${gw}_err -aspect 50000 -icon info \
            -message [::msgcat::mc "No users in roster..."] -type user \
            -buttons ok -default 0 -cancel 0
        return
    }

    CbDialog $gw [::msgcat::mc "Send contacts to %s" $nick] \
        [list [::msgcat::mc "Send"] \
              [list [namespace current]::send_users $gw $xlib $jid] \
              [::msgcat::mc "Cancel"] \
              [list destroy $gw]] \
        send_uc $choices $balloons
}

###############################################################################

proc rosterx::add_menu_item {m xlib jid} {
    $m add command \
           -label [::msgcat::mc "Send users..."] \
           -command [list [namespace current]::send_users_dialog $xlib $jid]
}

hook::add roster_create_groupchat_user_menu_hook \
    [namespace current]::rosterx::add_menu_item 45
hook::add chat_create_user_menu_hook \
    [namespace current]::rosterx::add_menu_item 45
hook::add roster_jid_popup_menu_hook \
    [namespace current]::rosterx::add_menu_item 45
hook::add message_dialog_menu_hook \
    [namespace current]::rosterx::add_menu_item 45
hook::add search_popup_menu_hook \
    [namespace current]::rosterx::add_menu_item 45

###############################################################################

proc rosterx::send_users {gw xlib jid} {
    global send_uc

    set sf [$gw getframe].sw.sf
    set choices {}
    foreach uc [array names send_uc] {
        if {$send_uc($uc)} {
            lappend choices $uc
        }
    }

    destroy $gw

    set subtags {}
    set body [::msgcat::mc "Contact Information"]
    foreach choice $choices {
        lassign $choice con uc
        lappend subtags [roster::item_to_xml $con $uc]
        set nick [roster::get_label $con $uc]
        append body "\n$nick - xmpp:$uc"
    }

    message::send_msg $xlib $jid -type normal -body $body \
        -xlist [list \
                    [::xmpp::xml::create x \
                            -xmlns $::NS(rosterx) \
                            -subelements $subtags] \
                    [::xmpp::xml::create x \
                            -xmlns $::NS(xroster) \
                            -subelements $subtags]]
}

###############################################################################

disco::register_feature $::NS(rosterx)

# vim:ft=tcl:ts=8:sw=4:sts=4:et
