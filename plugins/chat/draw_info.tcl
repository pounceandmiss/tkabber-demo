# draw_info.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which puts info messages to chatlog windows.

proc handle_info {chatid from type body x} {
    if {$type eq "info"} {
        ::richtext::render_message [chat::chat_win $chatid] $body info
        return stop
    }
}

hook::add draw_message_hook [namespace current]::handle_info 10

# vim:ft=tcl:ts=8:sw=4:sts=4:et
