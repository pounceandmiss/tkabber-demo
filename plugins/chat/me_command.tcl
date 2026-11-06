# me_command.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements
#       rendering and completing of /me command. Messages started with /me
#       traditionally render as if someone tells about herself in third
#       person.

proc handle_me {chatid from type body x} {
    if {[regexp {^/me\M} $body]} {
        set body [string range $body 3 end]

        if {[chat::is_our_jid $chatid $from]} {
            set tag me
        } else {
            set tag they
        }

        set xlib [chat::get_xlib $chatid]
        set chatw [chat::chat_win $chatid]
        set nick [chat::get_nick $xlib $from $type]

        $chatw insert end "* $nick" [list $tag NICK-$nick]

        $chatw mark set MSGLEFT "end - 1 char"
        $chatw mark gravity MSGLEFT left

        if {[string equal $type groupchat]} {
            set myjid [chat::our_jid $chatid]
            set mynick [chat::get_nick $xlib $myjid $type]

            ::richtext::property_add mynick $mynick
            ::richtext::render_message $chatw $body $tag
        } else {
            ::richtext::render_message $chatw $body $tag
        }

        $chatw tag add NICKMSG-$nick MSGLEFT "end - 1 char"

        if {![catch {::plugins::mucignore::is_ignored $xlib $from $type} ignore] && \
                $ignore != ""} {
            $chatw tag add $ignore {MSGLEFT linestart} {end - 1 char}
        }

        return stop
    }
}
hook::add draw_message_hook [namespace current]::handle_me 83

proc me_command_comp {chatid compsvar wordstart line} {
    upvar 0 $compsvar comps

    if {!$wordstart} {
        lappend comps {/me }
    }
}

hook::add generate_completions_hook [namespace current]::me_command_comp

# vim:ft=tcl:ts=8:sw=4:sts=4:et
