# draw_message.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which adds our own chat (not groupchat) messages to chatlog windows.

proc draw_message {chatid user body type} {
    if {$type ne "groupchat" && [hook::is_flag chat_send_message_hook draw]} {
        chat::add_message $chatid [chat::our_jid $chatid] $type $body {}
    }

    hook::unset_flag chat_send_message_hook draw
}

hook::add chat_send_message_hook [namespace current]::draw_message 91

# vim:ft=tcl:ts=8:sw=4:sts=4:et
