# disco.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       registers /disco command for chat input windows. This command opens
#       a service discovery window.

namespace eval cdisco {}

proc cdisco::handle_disco_command {chatid user body type} {
    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]
    set bjid [::xmpp::jid::removeResource $jid]

    if {![chat::is_groupchat [chat::chatid $xlib $bjid]]} {
        set jid $bjid
    }

    set body [string trim $body]

    if {[string equal [string range $body 0 6] "/disco "]} {
        set jid [string range $body 7 end]
    } elseif {![string equal $body "/disco"]} {
        return
    }

    disco::browser::open_win $xlib $jid
    return stop
}

hook::add chat_send_message_hook \
    [namespace current]::cdisco::handle_disco_command 50

proc cdisco::disco_command_comp {chatid compsvar wordstart line} {
    upvar 0 $compsvar comps

    if {!$wordstart} {
        lappend comps {/disco }
    }
}

hook::add generate_completions_hook \
          [namespace current]::cdisco::disco_command_comp

# vim:ft=tcl:ts=8:sw=4:sts=4:et
