# log_on_open.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       displays several previously received messages on opening a chat
#       window. The maximum number of messages and time interval for
#       messages too old to show are customizable.

namespace eval log_on_open {
    custom::defvar options(enable_in_chats) 1 \
        [::msgcat::mc "Show several most recently received messages in a\
                       newly opened chat window. They are taken from the\
                       logs, so you'll have to enable them for chats."] \
        -type boolean -group Chat
    custom::defvar options(enable_in_groupchats) 0 \
        [::msgcat::mc "Show several most recently received messages in a\
                       newly opened conference window. They are taken from\
                       the logs, so you'll have to enable them for\
                       groupchat."] \
        -type boolean -group Chat
    custom::defvar options(max_messages) 20 \
        [::msgcat::mc "Maximum number of log messages to show in newly\
                       opened chat window (if set to negative then the\
                       number is unlimited)."] \
        -type integer -group Chat
    custom::defvar options(max_interval) 24 \
        [::msgcat::mc "Maximum interval length in hours for which log\
                       messages should be shown in newly opened chat\
                       window (if set to negative then the interval is\
                       unlimited)."] \
        -type integer -group Chat
    custom::defvar options(use_metacontacts) 0 \
        [::msgcat::mc "If the chat window that is being opened belongs\
                       to a JID which corresponds to some metacontact\
                       in your roster then messages from all JIDs from\
                       that metacontact will show up in the window.\
                       This option requires enabling metacontacts in your\
                       roster."] \
        -type boolean -group Chat
}

proc log_on_open::show {chatid type} {
    variable options

    if {$type ne "chat" && $type ne "groupchat"} return
    if {$type eq "chat" && !$options(enable_in_chats)} return
    if {$type eq "groupchat" && !$options(enable_in_groupchats)} return

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]
    set bjid [::xmpp::jid::removeResource $jid]
    set groupchat [chat::is_groupchat [chat::chatid $xlib $bjid]]

    if {$groupchat || ($jid ne $bjid && [::logger::logs_exist $jid])} {
        set log_jids [list $jid]
    } else {
        set log_jids [list $bjid]
        if {$::ifacetk::roster::options(enable_metacontacts) && $options(use_metacontacts)} {
            foreach tag [::plugins::metacontacts::get_all_tags $xlib] {
                set jids [::plugins::metacontacts::get_jids $xlib $tag]
                if {[lsearch -exact $jids $bjid] >= 0} {
                    set log_jids $jids
                    break
                }
            }
        }
    }

    set messages [::logger::get_last_messages $log_jids $type \
                                              $options(max_messages) \
                                              $options(max_interval)]
    foreach m $messages {
        set x {}
        if {[dict exists $m timestamp]} {
            set seconds [clock scan [dict get $m timestamp] -gmt 1]
            lappend x [::xmpp::delay::create $seconds]
        }
        if {[dict exists $m jid]} {
            set from [dict get $m jid]
            if {!$groupchat && [::xmpp::jid::removeResource $from] eq $bjid} {
                set from $jid
            }
        } else {
            set from ""
        }
        # Don't log this message. Request this by creating very special 'empty'
        # tag which can't be received from the peer.
        # TODO: Create more elegant mechanism
        lappend x [::xmpp::xml::create "" -xmlns tkabber:x:nolog]

        chat::add_message $chatid $from $type [dict get $m body] $x
    }
}

hook::add open_chat_post_hook [namespace current]::log_on_open::show 100

# vim:ft=tcl:ts=8:sw=4:sts=4:et
