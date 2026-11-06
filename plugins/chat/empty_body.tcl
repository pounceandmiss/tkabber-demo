# empty_body.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which prevents putting messages with empty body to chatlog windows
#       and prevents messages with empty body to be sent using chat
#       input windows.

proc check_send_empty_body {chatid user body type} {
    if {$body eq ""} {
        return stop
    }
}

hook::add chat_send_message_hook [namespace current]::check_send_empty_body 10

proc check_draw_empty_body {chatid from type body x} {
    if {$body eq ""} {
        return stop
    }
}

hook::add draw_message_hook [namespace current]::check_draw_empty_body 2

# vim:ft=tcl:ts=8:sw=4:sts=4:et
