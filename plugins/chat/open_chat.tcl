# open_chat.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which allows user to open new chat window.
#       Just type "/open jid" and press enter.
#       Command and JID could be completed in the usual way.

proc handle_open_chat {chatid user body type} {
    if {[string equal -length 6 $body "/open "]} {
        set user [string range $body 6 end]
        # What if conference nickname contains "@"?
        if {[string first "@" $user] >= 0} {
            chat::open_to_user [chat::get_xlib $chatid] $user
        } else {
            chat::open_to_user [chat::get_xlib $chatid] \
                [chat::get_jid $chatid]/$user
        }
        return stop
    }
}
hook::add chat_send_message_hook [namespace current]::handle_open_chat 15

proc roster_completions {chatid compsvar wordstart line} {
    upvar 0 $compsvar comps

    if {!$wordstart} {
            lappend comps {/open }
    }

    if {$wordstart && [string equal -length 6 $line "/open "]} {
        set prefix $::plugins::completion::options(prefix)
        set suffix $::plugins::completion::options(suffix)
        set jidcomps {}
        set xlib [chat::get_xlib $chatid]
        foreach jid [roster::get_jids $xlib] {
            if {[roster::itemconfig $xlib $jid -isuser]} {
                lappend jidcomps $prefix$jid$suffix
            }
        }
        set jidcomps [lsort -dictionary -unique $jidcomps]
        set comps [concat $comps $jidcomps]
        debugmsg plugins "COMPLETION from roster: $comps"
    }
}

hook::add generate_completions_hook \
    [namespace current]::roster_completions 93

# vim:ft=tcl:ts=8:sw=4:sts=4:et
