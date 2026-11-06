# draw_server_message.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which puts server messages (either groupchat messages originated
#       at the service itself, or chat messages without from attribute)
#       to chatlog windows.

proc handle_server_message {chatid from type body x} {
    set jid [chat::get_jid $chatid]
    if {($type eq "groupchat" && $jid eq $from) || ($type eq "chat" && $from eq "")} {
        set chatw [chat::chat_win $chatid]

        $chatw insert end --- server_lab " "
        ::richtext::render_message $chatw $body server
        return stop
    }
}

hook::add draw_message_hook [namespace current]::handle_server_message 20

# vim:ft=tcl:ts=8:sw=4:sts=4:et
