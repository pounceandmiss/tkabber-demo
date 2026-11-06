# insert_nick.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       allows user to insert someone's nickname into chat input window
#       by clicking the desired nickname either in the groupchat roster or
#       in the chatlog window.

namespace eval insert_nick {}

proc insert_nick::insert {chatid nick} {
    set ci [chat::input_win $chatid]
    if {[$ci compare insert == "1.0"]} {
        $ci insert insert \
            $::plugins::completion::options(nlprefix)$nick$::plugins::completion::options(nlsuffix)
    } else {
        $ci insert insert \
            $::plugins::completion::options(prefix)$nick$::plugins::completion::options(suffix)
    }
}

hook::add groupchat_roster_user_singleclick_hook \
    [namespace current]::insert_nick::insert

proc insert_nick::insert_from_window {chatid w x y} {
    set nick ""
    set cw [chat::chat_win $chatid]
    set tags [$cw tag names "@$x,$y"]

    if {[set idx [lsearch -glob $tags NICK-*]] >= 0} {
        set nick [string range [lindex $tags $idx] 5 end]
    }

    if {$nick == ""} return

    insert $chatid $nick
    focus -force [chat::input_win $chatid]
    return stop
}

hook::add chat_window_click_hook \
    [namespace current]::insert_nick::insert_from_window

# vim:ft=tcl:ts=8:sw=4:sts=4:et
