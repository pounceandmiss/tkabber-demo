# wmdock.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which implements basic WindowMaker icon.

if {![info exists ::wmaker_dock] || !$::wmaker_dock} {
    return
}

namespace eval ::wmdock {
    variable save_status unavailable
    variable balloon_msg ""
    variable msgs 0
    variable msgsc
    array set msgsc {}
    variable msg_afterid ""
}

proc ::wmdock::change_status {status} {
    variable save_status
    variable msgs
    variable balloon_msg

    if {![winfo exists .icon]} return

    set save_status $status
    set balloon_msg $status
    .icon.c itemconfigure text -text [concat $msgs "msgs"]
    .icon.c itemconfigure icon -image roster/user/$status
}


proc ::wmdock::msg_recv {chatid from type body x} {
    variable msg_afterid
    variable balloon_msg
    variable msgs
    variable msgsc
    variable icon

    if {![winfo exists .icon]} return

    if {[chat::is_our_jid $chatid $from] || $type ne "chat"} {
        return
    }

    foreach xelem $x {
        ::xmpp::xml:split $xelem tag xmlns attrs cdata subels

        # Don't count message if this 'empty' tag is present. It indicates
        # messages history in chat window.
        if {[string equal $tag ""] && [string equal $xmlns tkabber:x:nolog]} {
            return
        }
    }

    set cw [chat::winid $chatid]
    set page [string range [win_id tab $cw] 1 end]
    if {$::usetabbar && $page != [.nb raise]} {
        if {![info exists msgsc($chatid)]} {
            set msgsc($chatid) 0
        }
        incr msgsc($chatid) 1
        incr msgs 1
    }

    #        set balloon_msg [concat "Message from" [roster::get_label $from] ]
    set balloon_msg [::msgcat::mc "Message from %s" $from]

    after cancel $msg_afterid
    .icon.c itemconfigure icon -image docking/message
    .icon.c itemconfigure text -text [::msgcat::mc "%s msgs" $msgs]

    set msg_afterid [after 5000 ::wmdock::clear_msg_status]
}

proc ::wmdock::msg_read {path chatid} {
    variable msgs
    variable msgsc

    if {![winfo exists .icon]} return

    if {[info exists msgsc($chatid)]} {
        set msgs [expr $msgs - $msgsc($chatid)]
        unset msgsc($chatid)
    }
    .icon.c itemconfigure text -text [::msgcat::mc "%s msgs" $msgs]
}

proc ::wmdock::presence_recv {who status} {
    variable msg_afterid
    variable balloon_msg
    variable icon

    if {![winfo exists .icon]} return

    set balloon_msg [::msgcat::mc "%s is %s" $who $status]

    after cancel $msg_afterid
    .icon.c itemconfigure icon -image browser/user

    set msg_afterid [after 10000 ::wmdock::clear_msg_status]
}

proc ::wmdock::clear_msg_status {} {
    variable save_status
    variable balloon_msg

    if {![winfo exists .icon]} return

    set balloon_msg $save_status
    .icon.c itemconfigure icon -image roster/user/$save_status
}


proc ::wmdock::showhide {} {
    if {[wm state .] == "withdrawn"} {
        wm deiconify .
        wm state . normal
    } else {
        wm withdraw .
    }
}

proc ::wmdock::balloon {} {
    variable balloon_msg

    return [list .icon $balloon_msg]
}

proc ::wmdock::create_dock {} {
    variable balloon_msg

    if {[wm iconwindow .] eq ""} {
        toplevel .icon -class TkabberIcon
        wm iconwindow . .icon
    }

    wm command . [file join [pwd] $::argv0]

    canvas .icon.c -background black -width 52 -height 52 -relief sunken
    .icon.c create image 26 26 -anchor s \
        -image roster/user/unavailable -tag icon
    .icon.c create text 26 52 -anchor s -text "no" -fill white -tag text
    pack .icon.c

    bind .icon <<ContextMenu>> ::wmdock::showhide
    balloon::setup .icon -command [list ::wmdock::balloon]
}

hook::add postload_hook ::wmdock::create_dock 80
hook::add change_our_presence_post_hook ::wmdock::change_status 15
hook::add draw_message_hook ::wmdock::msg_recv 70
hook::add on_change_user_presence_hook ::wmdock::presence_recv 15
hook::add raise_chat_tab_hook ::wmdock::msg_read 15

# vim:ft=tcl:ts=8:sw=4:sts=4:et
