# draw_error.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which puts error messages to chatlog windows.

proc handle_error {chatid from type body x} {
    if {$type eq "error"} {
        set chatw [chat::chat_win $chatid]
        $chatw insert end $body err
        return stop
    }
}

hook::add draw_message_hook [namespace current]::handle_error 10

# vim:ft=tcl:ts=8:sw=4:sts=4:et
