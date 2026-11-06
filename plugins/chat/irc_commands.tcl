# irc_commands.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which implements /topic (or /subject), /nick, /invite, /join
#       /rejoin, /msg, and /part (or /leave) commands in chat or
#       groupchat windows.

namespace eval irc {}

proc irc::handle_irc_commands {chatid user body type} {

    set body [string trim $body]
    if {[string equal -length 7 $body "/topic "]} {
        set command subject
        set subject [string trim [string range $body 7 end]]
    } elseif {[string equal -length 9 $body "/subject "]} {
        set command subject
        set subject [string trim [string range $body 9 end]]
    } elseif {[string equal $body "/topic"] || \
              [string equal $body "/subject"]} {
        set command show_subject
    } elseif {[string equal -length 6 $body "/nick "]} {
        set command nick
        set nick [string trim [string range $body 6 end]]
    } elseif {[string equal -length 8 $body "/invite "]} {
        set command invite
        set arg [string range $body 8 end]
        lassign [parse_body $arg "\n"] to reason
    } elseif {[string equal -length 6 $body "/join "]} {
        set command join
        set arg [string range $body 6 end]
        lassign [parse_body $arg " "] room password
    } elseif {[string equal $body "/join"]} {
        set command join
        set room ""
        set password ""
    } elseif {[string equal $body "/rejoin"]} {
        set command rejoin
        set password ""
    } elseif {[string equal -length 5 $body "/msg "]} {
        set command msg
        set arg [string range $body 5 end]
        lassign [parse_body $arg "\n"] nick body
    } elseif {[string equal $body "/nick"] || \
              [string equal $body "/msg"] || \
              [string equal $body "/invite"]} {
        return stop
    } elseif {[string equal -length 6 $body "/part "]} {
        set command leave
        set status [string trim [string range $body 6 end]]
    } elseif {[string equal -length 7 $body "/leave "]} {
        set command leave
        set status [string trim [string range $body 7 end]]
    } elseif {[string equal $body "/part"] || \
              [string equal $body "/leave"]} {
        set command leave
        set status ""
    } else {
        return
    }

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]

    switch -- $command {
        nick {
            if {$type ne "groupchat"} return
            muc::change_nick $chatid $nick
            debugmsg plugins "NICK: $nick"
        }
        subject {
            if {$type ne "groupchat"} return
            message::send_msg $xlib $jid -type groupchat -subject $subject
            debugmsg plugins "SUBJECT: $subject"
        }
        show_subject {
            chat::add_message $chatid $jid info \
                "[::msgcat::mc Subject:] $::chat::chats(subject,$chatid)" {}
        }
        invite {
            if {$type eq "groupchat"} {
                muc::invite_muc $xlib $jid $to $reason
            } else {
                muc::invite_muc $xlib $to $jid $reason
            }
            debugmsg plugins "INVITE: $to $reason"
        }
        join {
            if {$type eq "groupchat"} {
                if {$room eq ""} {
                    set room $jid
                } elseif {[::xmpp::jid::node $room] == ""} {
                    set room [::xmpp::jid::jid $room [::xmpp::jid::server $jid]]
                }
            }

            set chatid [chat::chatid $xlib $room]
            if {[catch {get_our_groupchat_nick $chatid} nick]} {
                set nick [get_group_nick $xlib $room]
            }
            # HACK: TODO: remove usage of tokens.
            if {[chat::is_opened $chatid] && [info exists ::muc::tokens($chatid)]} {
                muc::test_connection $chatid \
                        -command [namespace code [list join_if_disconnected \
                                                       $xlib $room $nick $password]]
            } else {
                muc::leave_group $chatid ""
                muc::join_group $xlib $room $nick $password
            }
            debugmsg plugins "JOIN: $room $nick"
        }
        rejoin {
            if {$type ne "groupchat"} return
            if {[catch {get_our_groupchat_nick $chatid} nick]} {
                set nick [get_group_nick $xlib $jid]
            }
            muc::leave_group $chatid ""
            muc::join_group $xlib $jid $nick $password
            debugmsg plugins "REJOIN: $jid $nick"
        }
        msg {
            if {$type eq "groupchat" && $nick != "" && $body != ""} {
                chat::open_to_user $xlib $jid/$nick -message $body
                debugmsg plugins "MSG: $jid/$nick: $body"
            } else {
                chat::add_message $chatid $jid error \
                    "/msg to $nick failed" {}
            }
        }
        leave {
            set ::chat::chats(exit_status,$chatid) $status
            after idle [list ifacetk::destroy_win [chat::winid $chatid]]
            debugmsg plugins "LEAVE: $jid $status"
        }
    }
    return stop
}

hook::add chat_send_message_hook [namespace current]::irc::handle_irc_commands 50

proc irc::parse_body {line separator} {
    set ne [string first $separator $line]
    if {$ne < 0} {
        set nick $line
        set body ""
    } else {
        set nick [string range $line 0 [expr {$ne - 1}]]
        set body [string range $line [expr {$ne + [string length $separator]}] end]
    }
    return [list $nick [string trim $body]]
}

proc irc::irc_commands_comp {chatid compsvar wordstart line} {
    upvar 0 $compsvar comps

    if {!$wordstart} {
        lappend comps {/invite }
        lappend comps {/join }
        lappend comps {/leave }
        lappend comps {/msg }
        lappend comps {/nick }
        lappend comps {/part }
        lappend comps {/rejoin }
        lappend comps {/subject }
        lappend comps {/topic }
    }

    if {$wordstart && [string equal -length 8 $line "/invite "] && \
            [string first "\n" $line] < 0} {
        set prefix $::plugins::completion::options(prefix)
        set suffix $::plugins::completion::options(suffix)
        set jidcomps {}
        set xlib [chat::get_xlib $chatid]
        if {[chat::is_groupchat $chatid]} {
            foreach jid [roster::get_jids $xlib] {
                if {[roster::itemconfig $xlib $jid -isuser]} {
                    lappend jidcomps $prefix$jid$suffix
                }
            }
        } else {
            foreach chatid1 [lfilter chat::is_groupchat [chat::opened $xlib]] {
                set jid [chat::get_jid $chatid1]
                lappend jidcomps $prefix$jid$suffix
            }
        }
        set jidcomps [lsort -dictionary -unique $jidcomps]
        set comps $jidcomps
        debugmsg plugins "COMPLETION from roster: $comps"
        return stop
    }
}

hook::add generate_completions_hook [namespace current]::irc::irc_commands_comp

proc irc::join_if_disconnected {xlib room nick password status} {
    set chatid [chat::chatid $xlib $room]

    debugmsg conference "TEXTJOIN: $xlib $room $status/[muc::status $chatid]"

    switch -glob -- $status/[muc::status $chatid] {
        connected/disconnected -
        disconnected/* {
            muc::leave_group $chatid ""
            muc::join_group $xlib $room $nick $password
        }
        default {
            chat::add_message $chatid $room info \
                [::msgcat::mc "Already joined"] {}
        }
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
