# clear.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which implements /clear command in chat windows (it clears the
#       chatlog window).

namespace eval clear {}

proc clear::clear_chat_win {chatid} {
    set chatw [chat::chat_win $chatid]
    $chatw configure -state normal
    $chatw delete 0.0 end
    $chatw configure -state disabled
}

proc clear::handle_clear_command {chatid user body type} {
    set body [string trim $body]
    if {$body ne "/clear"} {
        return
    }

    clear_chat_win $chatid
    return stop
}

hook::add chat_send_message_hook \
    [namespace current]::clear::handle_clear_command 50

proc clear::clear_command_comp {chatid compsvar wordstart line} {
    upvar 0 $compsvar comps

    if {!$wordstart} {
        lappend comps {/clear }
    }
}

hook::add generate_completions_hook \
    [namespace current]::clear::clear_command_comp

proc clear::add_chat_menu_item {m xlib jid} {
    set chatid [chat::chatid $xlib $jid]
    $m add command -label [::msgcat::mc "Clear chat window"] \
        -command [list [namespace current]::clear_chat_win $chatid]
}

hook::add chat_create_conference_menu_hook \
    [namespace current]::clear::add_chat_menu_item 41
hook::add chat_create_user_menu_hook \
    [namespace current]::clear::add_chat_menu_item 41

# vim:ft=tcl:ts=8:sw=4:sts=4:et
