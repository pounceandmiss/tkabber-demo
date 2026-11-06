# navigate_messages.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       implements scrolling to the previous/next normal message in
#       Tkabber chatlog windows skipping server messages.

namespace eval navmessages {
    hook::add postload_hook [namespace current]::init
    hook::add open_chat_post_hook [namespace current]::on_open_chat
    hook::add close_chat_post_hook [namespace current]::on_close_chat
    hook::add chat_win_popup_menu_hook [namespace current]::popup_menu
    hook::add draw_message_hook [namespace current]::add_bookmark 80
}

proc navmessages::init {} {
    global usetabbar

    if {$usetabbar} {
        bind . <Shift-F4> [list [namespace current]::next_bookmark .]
        bind . <F4>       [list [namespace current]::prev_bookmark .]
    }
}

proc navmessages::on_open_chat {chatid type} {
    global usetabbar

    if {!$usetabbar} {
        set cw [chat::chat_win $chatid]
        set top [winfo toplevel $cw]
        bind $top <Shift-F4> [list [namespace current]::next_bookmark [double% $cw]]
        bind $top <F4>       [list [namespace current]::prev_bookmark [double% $cw]]
    }
}

proc navmessages::on_close_chat {chatid} {
    variable bookmark

    set cw [chat::chat_win $chatid]
    unset -nocomplain bookmark(id,$cw)
    unset -nocomplain bookmark(last,$cw)
}

proc navmessages::popup_menu {m W X Y x y} {
    set groupchat 0
    foreach chatid [chat::opened] {
        if {[chat::chat_win $chatid] eq $W} {
            set groupchat [chat::is_groupchat $chatid]
            break
        }
    }
    if {!$groupchat} return

    $m add command -label [::msgcat::mc "Prev message"] -accelerator F4 \
        -command [list [namespace current]::prev_bookmark $W]
    $m add command -label [::msgcat::mc "Next message"] -accelerator Shift-F4 \
        -command [list [namespace current]::next_bookmark $W]
}


proc navmessages::get_chatwin {} {
    global usetabbar

    if {!$usetabbar} {
        return ""
    }

    foreach chatid [chat::opened] {
        if {[.nb raise] eq [ifacetk::nbpage [chat::winid $chatid]]} {
            return [chat::chat_win $chatid]
        }
    }
    return ""
}

proc navmessages::add_bookmark {chatid from type body x} {
    variable bookmark

    if {$type ne "groupchat"} return

    set cw [chat::chat_win $chatid]

    if {![info exists bookmark(id,$cw)]} {
        set bookmark(id,$cw) 0
    }
    set b [incr bookmark(id,$cw)]
    $cw mark set mbookmark$b "end - 1 char"
    $cw mark gravity mbookmark$b left
}

proc navmessages::next_bookmark {cw} {
    variable bookmark

    if {$cw eq "."} {
        set cw [get_chatwin]
        if {$cw eq ""} return
    }

    set groupchat 0
    foreach chatid [chat::opened] {
        if {[chat::chat_win $chatid] eq $cw} {
            set groupchat [chat::is_groupchat $chatid]
            break
        }
    }
    if {!$groupchat} return

    if {![info exists bookmark(last,$cw)] || [catch {$cw index $bookmark(last,$cw)} idx]} {
        set bookmark(last,$cw) 0.0
        set idx [$cw index $bookmark(last,$cw)]
    }
    if {$bookmark(last,$cw) eq "end" || \
            (([lindex [$cw yview] 0] == 0 || [lindex [$cw yview] 1] == 1) && \
                ([$cw dlineinfo $idx] eq {} || "sel" ni [$cw tag names $idx]))} {
        set bookmark(last,$cw) 0.0
    }
    if {$bookmark(last,$cw) eq "0.0"} {
        set first_round 0
    } else {
        set first_round 1
    }
    while {$bookmark(last,$cw) ne "" || $first_round} {
        if {$bookmark(last,$cw) eq ""} {
            set bookmark(last,$cw) 0.0
            set first_round 0
        }
        set bookmark(last,$cw) [$cw mark next $bookmark(last,$cw)]
        if {[string match "mbookmark*" $bookmark(last,$cw)]} {
            break
        }
    }
    if {$bookmark(last,$cw) eq ""} {
        set bookmark(last,$cw) 0.0
    } else {
        $cw tag remove sel 0.0 end
        $cw tag add sel \
            "$bookmark(last,$cw) linestart" \
            "$bookmark(last,$cw) lineend"
        $cw see $bookmark(last,$cw)
    }
    return $bookmark(last,$cw)
}

proc navmessages::prev_bookmark {cw} {
    variable bookmark

    if {$cw eq "."} {
        set cw [get_chatwin]
        if {$cw eq ""} return
    }

    set groupchat 0
    foreach chatid [chat::opened] {
        if {[chat::chat_win $chatid] eq $cw} {
            set groupchat [chat::is_groupchat $chatid]
            break
        }
    }
    if {!$groupchat} return

    if {![info exists bookmark(last,$cw)] || [catch {$cw index $bookmark(last,$cw)} idx]} {
        set bookmark(last,$cw) end
        set idx [$cw index $bookmark(last,$cw)]
    }
    if {$bookmark(last,$cw) eq "0.0" || \
            ([lindex [$cw yview] 1] == 1 && \
                ([$cw dlineinfo $idx] eq {} || "sel" ni [$cw tag names $idx]))} {
        set bookmark(last,$cw) end
    }
    if {$bookmark(last,$cw) eq "end"} {
        set first_round 0
    } else {
        set first_round 1
    }
    while {$bookmark(last,$cw) ne "" || $first_round} {
        if {$bookmark(last,$cw) eq ""} {
            set bookmark(last,$cw) end
            set first_round 0
        }
        set bookmark(last,$cw) [$cw mark previous $bookmark(last,$cw)]
        if {[string match "mbookmark*" $bookmark(last,$cw)]} {
            break
        }
    }
    if {$bookmark(last,$cw) eq ""} {
        set bookmark(last,$cw) end
    } else {
        $cw tag remove sel 0.0 end
        $cw tag add sel \
            "$bookmark(last,$cw) linestart" \
            "$bookmark(last,$cw) lineend"
        $cw see $bookmark(last,$cw)
    }
    return $bookmark(last,$cw)
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
