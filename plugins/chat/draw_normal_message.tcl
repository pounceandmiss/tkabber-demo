# draw_normal_message.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which puts common chat or groupchat messages to chatlog windows.

proc draw_normal_message {chatid from type body x} {
    if {[chat::is_our_jid $chatid $from]} {
        set tag me
    } else {
        set tag they
    }

    set xlib [chat::get_xlib $chatid]
    set chatw [chat::chat_win $chatid]
    set nick [chat::get_nick $xlib $from $type]

    $chatw insert end "<$nick>" [list $tag NICK-$nick] " "

    $chatw mark set MSGLEFT "end - 1 char"
    $chatw mark gravity MSGLEFT left

    if {$type eq "groupchat"} {
        set myjid [chat::our_jid $chatid]
        set mynick [chat::get_nick $xlib $myjid $type]

        ::richtext::property_add mynick $mynick
        ::richtext::render_message $chatw $body ""
    } else {
        ::richtext::render_message $chatw $body ""
    }

    $chatw tag add MSG-$nick MSGLEFT "end - 1 char"

    if {![catch {::plugins::mucignore::is_ignored $xlib $from $type} ignore] && \
            $ignore ne ""} {
        $chatw tag add $ignore {MSGLEFT linestart} {end - 1 char}
    }

    return stop
}

hook::add draw_message_hook [namespace current]::draw_normal_message 87

# vim:ft=tcl:ts=8:sw=4:sts=4:et
