# open_window.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       opens chat tab on incoming message if it's not open already, and
#       temporarily configures the chatlog window state to normal to help
#       other plugins with inserting message into it.

proc chat_open_window {chatid from type body x} {
    if {$type eq "info"} {
        set type chat
    }
    chat::open_window $chatid $type -cleanroster 0
    set chatw [chat::chat_win $chatid]
    $chatw configure -state normal
}

hook::add draw_message_hook [namespace current]::chat_open_window 3

# vim:ft=tcl:ts=8:sw=4:sts=4:et
