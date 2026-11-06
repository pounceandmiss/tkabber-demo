# complete_last_nick.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       raises priority (in the list of word completions) of that nickname
#       who addressed a message personally to me.

namespace eval completion {
    custom::defvar options(completion_expire) 10 \
        [::msgcat::mc "Number of groupchat messages to expire nick completion\
                       according to the last personally addressed message."] \
        -type integer \
        -group Chat
}

proc handle_last_nick {chatid from type body x} {
    global last_nick my_last_nick my_last_nick_counter

    if {$type != "groupchat"} return

    set xlib [chat::get_xlib $chatid]

    set nick [chat::get_nick $xlib $from $type]
    set myjid [chat::our_jid $chatid]
    set mynick [chat::get_nick $xlib $myjid $type]
    if {$nick != $mynick} {
        if {[check_message $mynick $body]} {
            set my_last_nick($chatid) $nick
            set my_last_nick_counter($chatid) 0
        } else {
            set last_nick($chatid) $nick
            if {[info exists my_last_nick_counter($chatid)]} {
                incr my_last_nick_counter($chatid)
            }
        }
    }

    return
}

hook::add draw_message_hook [namespace current]::handle_last_nick 79

proc last_nick_comp {chatid compsvar wordstart line} {
    global last_nick my_last_nick my_last_nick_counter
    upvar 0 $compsvar comps

    if {$wordstart} return

    set prefix $::plugins::completion::options(nlprefix)
    set suffix $::plugins::completion::options(nlsuffix)
    if {[info exists last_nick($chatid)]} {

        set ln ${prefix}$last_nick($chatid)${suffix}

        set idx [lsearch -exact $comps $ln]
        #set comps [lreplace $comps $idx $idx]
        if {$idx > 0} {
            set comps [concat [list $ln] $comps]
        }
    }
    if {[info exists my_last_nick($chatid)] && \
            (![info exists my_last_nick_counter($chatid)] || \
                 $my_last_nick_counter($chatid) < $::plugins::completion::options(completion_expire))} {

        set ln ${prefix}$my_last_nick($chatid)${suffix}

        set idx [lsearch -exact $comps $ln]
        #set comps [lreplace $comps $idx $idx]
        if {$idx > 0} {
            set comps [concat [list $ln] $comps]
        }
    }
}

hook::add generate_completions_hook [namespace current]::last_nick_comp 92

# vim:ft=tcl:ts=8:sw=4:sts=4:et
