# popupmenu.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which creates popup menus in chatlog windows. It adds a few
#       commands to the menu by itself and runs a hook which allows
#       other plugins to populate the menu. The current plugin allows
#       to search selected string in Google (using Ctrl+H shortcut or
#       from the context menu) and bookmark some messages in the chat
#       log to return to them using the menu or F2 shortcut.

package require http 2

namespace eval popupmenu {
    hook::add postload_hook [namespace current]::init
    hook::add open_chat_post_hook [namespace current]::on_open_chat
    hook::add close_chat_post_hook [namespace current]::on_close_chat
}

proc popupmenu::init {} {
    global usetabbar

    if {$usetabbar} {
        bind . <Shift-F2>  [list [namespace current]::BookmarkNext .]
        catch {bind . <XF86_Switch_VT_2>  [list [namespace current]::BookmarkNext .]}
        bind . <F2>        [list [namespace current]::BookmarkPrev .]
        bind . <Control-H> [list [namespace current]::GoogleSelection .]
        bind . <Control-h> [list [namespace current]::GoogleSelection .]
    }
}

proc popupmenu::on_open_chat {chatid type} {
    global usetabbar

    set cw [chat::chat_win $chatid]
    bind $cw <<ContextMenu>> [list [namespace current]::popup_menu %W %X %Y %x %y]

    if {!$usetabbar} {
        set top [winfo toplevel $cw]
        bind $top <Shift-F2>  [list [namespace current]::BookmarkNext [double% $cw]]
        catch {bind $top <XF86_Switch_VT_2>  [list [namespace current]::BookmarkNext [double% $cw]]}
        bind $top <F2>        [list [namespace current]::BookmarkPrev [double% $cw]]
        bind $top <Control-H> [list [namespace current]::GoogleSelection [double% $cw]]
        bind $top <Control-h> [list [namespace current]::GoogleSelection [double% $cw]]
    }
}

proc popupmenu::on_close_chat {chatid} {
    variable bookmark

    set cw [chat::chat_win $chatid]
    catch { array unset bookmark $cw,* }
}

proc popupmenu::popup_menu {W X Y x y} {
    set m .popup
    if {[winfo exists $m]} {
        destroy $m
    }

    menu $m -tearoff 0

    hook::run chat_win_popup_menu_hook $m $W $X $Y $x $y

    tk_popup $m $X $Y
}

proc popupmenu::selection_popup {m W X Y x y} {
    if {[llength [$W tag ranges sel]] == 0} {
        set state disabled
    } else {
        set state normal
    }

    $m add command -label [::msgcat::mc "Copy selection to clipboard"] \
        -command [list [namespace current]::CopySelection $W] \
        -state $state
    $m add command -label [::msgcat::mc "Google selection"] -accelerator Ctrl-H \
        -command [list [namespace current]::GoogleSelection $W]\
        -state $state
}

hook::add chat_win_popup_menu_hook [namespace current]::popupmenu::selection_popup 20

proc popupmenu::bookmarks_popup {m W X Y x y} {
    $m add command -label [::msgcat::mc "Set bookmark"] \
        -command [list [namespace current]::BookmarkAdd $W $x $y]
    $m add command -label [::msgcat::mc "Prev bookmark"] -accelerator F2 \
        -command [list [namespace current]::BookmarkPrev $W]
    $m add command -label [::msgcat::mc "Next bookmark"] -accelerator Shift-F2 \
        -command [list [namespace current]::BookmarkNext $W]
    $m add command -label [::msgcat::mc "Clear bookmarks"] \
        -command [list [namespace current]::BookmarkClear $W]
}

hook::add chat_win_popup_menu_hook [namespace current]::popupmenu::bookmarks_popup 80

proc popupmenu::get_chatwin {} {
    global usetabbar

    if {!$usetabbar} {
        return ""
    }

    set cw ""
    foreach chatid [chat::opened] {
        if {[.nb raise] == [ifacetk::nbpage [chat::winid $chatid]]} {
            set cw [chat::chat_win $chatid]
            break
        }
    }
    return $cw
}

proc popupmenu::BookmarkAdd {cw x y} {
    variable bookmark

    $cw mark set AddBookmark "@$x,$y linestart"

    debugmsg popupmenu "BookmarkAdd at [$cw index AddBookmark]"
    if {![info exists bookmark($cw,id)]} {
        set bookmark($cw,id) 0
    }
    $cw configure -state normal
    $cw image create AddBookmark -image chat/bookmark/red
    set b [incr bookmark($cw,id)]
    $cw mark set bookmark$b AddBookmark
    $cw mark gravity bookmark$b left
    $cw mark unset AddBookmark
    $cw configure -state disabled
}

proc popupmenu::BookmarkNext {cw} {
    variable bookmark

    if {$cw == "."} {
        set cw [get_chatwin]
        if {$cw == ""} return
    }

    if {![info exists bookmark($cw,last)] || \
            [catch {$cw index $bookmark($cw,last)}]} {
        set bookmark($cw,last) 0.0
    }
    if {$bookmark($cw,last) == "end" || \
            ((([lindex [$cw yview] 0] == 0) || ([lindex [$cw yview] 1] == 1)) && \
            ([$cw dlineinfo [$cw index $bookmark($cw,last)]] == {}))} {
        set bookmark($cw,last) 0.0
    }
    while {$bookmark($cw,last) != {}} {
        set bookmark($cw,last) [$cw mark next $bookmark($cw,last)]
        if {[string match "bookmark*" $bookmark($cw,last)]} {
            break
        }
    }
    if {$bookmark($cw,last) == {}} {
        set bookmark($cw,last) end
    }
    $cw see $bookmark($cw,last)
    return $bookmark($cw,last)
}

proc popupmenu::BookmarkPrev {cw} {
    variable bookmark

    if {$cw == "."} {
        set cw [get_chatwin]
        if {$cw == ""} return
    }

    if {![info exists bookmark($cw,last)] || \
            [catch {$cw index $bookmark($cw,last)}]} {
        set bookmark($cw,last) end
    }
    if {$bookmark($cw,last) == "0.0" || \
            (([lindex [$cw yview] 1] == 1) && \
            ([$cw dlineinfo [$cw index $bookmark($cw,last)]] == {}))} {
        set bookmark($cw,last) end
    }
    while {$bookmark($cw,last) != {}} {
        set bookmark($cw,last) [$cw mark previous $bookmark($cw,last)]
        if {[string match "bookmark*" $bookmark($cw,last)]} {
            break
        }
    }
    if {$bookmark($cw,last) == {}} {
        set bookmark($cw,last) 0.0
    }
    $cw see $bookmark($cw,last)
    return $bookmark($cw,last)
}

proc popupmenu::BookmarkClear {cw} {
    debugmsg popupmenu "BookmarkClear"

    set mark 0.0
    while {[set mark [$cw mark next $mark]] != {}} {
        if {[string match "bookmark*" $mark]} {
            set remove $mark
            set mark "[$cw index $mark]"
            BookmarkRemove $cw $remove
        }
    }
}

proc popupmenu::BookmarkRemove {cw mark} {
    if {$mark in [$cw mark names]} {
        debugmsg popupmenu "BookmarkRemove $mark"
        $cw configure -state normal
        $cw delete "$mark - 1 char"
        $cw mark unset $mark
        $cw configure -state disabled
    }
}

proc popupmenu::GoogleSelection {cw} {
    if {$cw == "."} {
        set cw [get_chatwin]
        if {$cw == ""} return
    }

    set sel [$cw tag ranges sel]
    if {$sel != ""} {
        set t [$cw get [lindex $sel 0] [lindex $sel 1]]
        debugmsg popupmenu "google for $t"
        browseurl \
            https://www.google.com/search?[::http::formatQuery ie UTF-8 oe UTF-8 q $t]
    }
}

proc popupmenu::CopySelection {cw} {
    if {$cw == "."} {
        set cw [get_chatwin]
        if {$cw == ""} return
    }

    set sel [$cw tag ranges sel]
    if {$sel != ""} {
        set t [$cw get [lindex $sel 0] [lindex $sel 1]]
        debugmsg popupmenu "copy selection $t"
        clipboard clear -displayof $cw
        clipboard append -displayof $cw $t
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
