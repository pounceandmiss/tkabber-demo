# send_message.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       actually composes the message to send and sends it.

proc send_message {chatid user body type} {
    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]
    set chatw [chat::chat_win $chatid]

    if {[hook::is_flag chat_send_message_hook send]} {
        set id [::xmpp::packetID $xlib]

        set args {}

        if {[info exists ::chat::chats(thread,$chatid)]} {
            lappend args -thread $::chat::chats(thread,$chatid)
        }

        set xlist {}

        hook::run chat_send_message_xlist_hook xlist \
                  $chatid $user $id $body $type

        if {[llength $xlist] > 0} {
            lappend args -xlist $xlist
        }

        lassign [message::send_msg $xlib $jid \
                         -id $id \
                         -type $type \
                         -body $body {*}$args] status x

        if {$status eq "error"} {
            return stop
        }
    }

    hook::unset_flag chat_send_message_hook send
}

hook::add chat_send_message_hook [namespace current]::send_message 90

# vim:ft=tcl:ts=8:sw=4:sts=4:et
