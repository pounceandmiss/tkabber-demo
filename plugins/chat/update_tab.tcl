# update_tab.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       updates tab headers upon receiving chat message.

namespace eval update_tab {}

proc update_tab::update {chatid from type body x} {
    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]
    set cw [chat::winid $chatid]

    foreach xelem $x {
        ::xmpp::xml::split $xelem tag xmlns attrs cdata subels

        # Don't update tab if this 'empty' tag is present. It indicates
        # messages history in chat window.
        if {[string equal $tag ""] && [string equal $xmlns tkabber:x:nolog]} {
            return
        }
    }

    if {![catch {::plugins::mucignore::is_ignored $xlib $from $type} ignore] && \
            $ignore != ""} {
        return
    }

    switch -- $type {
        error -
        info {
            tab_set_updated $cw 1 $type
        }
        groupchat {
            if {$from == $jid} {
                tab_set_updated $cw 1 server
            } else {
                set myjid [chat::our_jid $chatid]
                set mynick [chat::get_nick $xlib $myjid $type]

                if {[check_message $mynick $body]} {
                    tab_set_updated $cw 1 mesg_to_user
                } else {
                    tab_set_updated $cw 1 message
                }
            }
        }
        chat -
        default {
            if {$from == ""} {
                # synthesized message
                tab_set_updated $cw 1 server
            } else {
                tab_set_updated $cw 1 mesg_to_user
            }
        }
    }
}

hook::add draw_message_hook [namespace current]::update_tab::update 8

# vim:ft=tcl:ts=8:sw=4:sts=4:et
