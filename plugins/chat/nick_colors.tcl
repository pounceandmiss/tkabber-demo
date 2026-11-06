# nick_colors.tcl --
#
#       Do full text coloring based upon nicks. Includes a color editor and
#       persistence for modified color selection.
#
# Copyright (C) 2004 Pat Thoyts <patthoyts@users.sourceforge.net>
# Modifications Sergei Golovan <sgolovan@nes.ru>

package require sum

namespace eval nickcolors {

    custom::defvar options(use_colored_nicks) 0 \
        [::msgcat::mc "Use colored nicks in chat windows."] \
        -group Chat -type boolean \
        -command [namespace current]::change_options

    custom::defvar options(use_colored_roster_nicks) 0 \
        [::msgcat::mc "Use colored nicks in groupchat rosters."] \
        -group Chat -type boolean \
        -command [namespace current]::change_options

    custom::defvar options(use_colored_messages) 0 \
        [::msgcat::mc "Color message bodies in chat windows."] \
        -group Chat -type boolean \
        -command [namespace current]::change_options

    hook::add open_chat_post_hook [namespace current]::chat_add_nick_colors
    hook::add close_chat_post_hook [namespace current]::chat_delete_nick_colors
    hook::add quit_hook           [namespace current]::save_nick_colors
    hook::add draw_message_hook   [namespace current]::check_nick 60
    hook::add finload_hook        [namespace current]::init_nick_colors
    hook::add chat_win_popup_menu_hook [namespace current]::add_chat_win_popup_menu 10
    hook::add roster_create_groupchat_user_menu_hook \
        [namespace current]::add_groupchat_user_menu_items

    variable NickColorPool
    if {![info exists NickColorPool]} {
        set NickColorPool [list blue4 green4 red brown4 orange3 purple3 \
                               tomato chocolate pink3]
    }

    variable NickColors
    if {![info exists NickColors]} {
        array set NickColors {}
    }
}

proc nickcolors::init_nick_colors {} {
    load_nick_colors
    add_nick_colors_menu
}

proc nickcolors::add_nick_colors_menu {} {
    set m [.mainframe getmenu chats]

    $m insert end checkbutton \
        -label [::msgcat::mc "Use colored nicks"] \
        -variable [namespace current]::options(use_colored_nicks) \
        -command [namespace current]::change_options
    $m insert end checkbutton \
        -label [::msgcat::mc "Use colored roster nicks"] \
        -variable [namespace current]::options(use_colored_roster_nicks) \
        -command [namespace current]::change_options
    $m insert end checkbutton \
        -label [::msgcat::mc "Use colored messages"] \
        -variable [namespace current]::options(use_colored_messages) \
        -command [namespace current]::change_options
    $m insert end command \
        -label [::msgcat::mc "Edit nick colors..."] \
        -command [namespace current]::edit_nick_colors
}

# Called upon startup, this will merge the user's stored set of nick-colors
# into the current array. New chat windows will pick these up.
#
proc nickcolors::load_nick_colors {} {
    variable NickColors
    set filename [file join $::configdir nickcolors.tcl]
    if {[file exists $filename]} {
        set f [open $filename r]
        fconfigure $f -encoding utf-8
        while {![eof $f]} {
            set line [string trim [gets $f]]
            if {[string length $line] > 0
                && ![string match \#* $line]} {
                catch {
                    set NickColors([lindex $line 0]) [lindex $line 1]
                }
            }
        }
        close $f
    }
}

# Called at shutdown to save the current set of nick-colors to file.
proc nickcolors::save_nick_colors {} {
    variable NickColors
    set filename [file join $::configdir nickcolors.tcl]
    set f [open $filename w]
    fconfigure $f -encoding utf-8
    puts $f "# This is an automatically generated file. Do not edit."
    foreach {nick clr} [array get NickColors] {
        puts $f [list $nick $clr]
    }
    close $f
}

proc nickcolors::get_color {nick} {
    variable NickColors
    variable NickColorPool

    if {[info exists NickColors($nick)]} {
        return $NickColors($nick)
    } else {
        set index [expr {[crc::sum -- [encoding convertto utf-8 $nick]] % [llength $NickColorPool]}]
        return [lindex $NickColorPool $index]
    }
}

proc nickcolors::set_color {chatid nick color} {
    variable options

    if {[catch {set w [chat::chat_win $chatid]}] || \
            ![winfo exists $w]} {
        return
    }

    if {$options(use_colored_nicks)} {
        $w tag configure NICK-$nick -foreground $color
        $w tag configure NICKMSG-$nick -foreground $color
    }
    if {$options(use_colored_messages)} {
        $w tag configure MSG-$nick -foreground $color
        $w tag lower MSG-$nick
    }
}

# Called upon opening a new chat window. This added all the currently defined
# nick-colors as tags into the text widget.
#
proc nickcolors::chat_add_nick_colors {chatid type} {
    variable NicksInChat

    debugmsg chat "on_open_chat $chatid $type"
    set NicksInChat($chatid) {}
}

proc nickcolors::chat_delete_nick_colors {chatid} {
    variable NicksInChat

    debugmsg chat "on_close_chat $chatid"
    catch {unset NicksInChat($chatid)}
}

# draw_message hook used to check that the nick exists as a color and tag.
proc nickcolors::check_nick {chatid from type body x} {
    variable NicksInChat

    set xlib [chat::get_xlib $chatid]
    set nick [chat::get_nick $xlib $from $type]
    if {$nick ni $NicksInChat($chatid)} {
        lappend NicksInChat($chatid) $nick
        set_color $chatid $nick [get_color $nick]
    }
}

proc nickcolors::edit_nick_colors {} {
    variable NickColors
    variable NickColorEdits

    array set NickColorEdits [array get NickColors]

    set w .edit_nicks

    Dialog $w -title [::msgcat::mc "Edit chat user colors"] \
              -modal none -anchor e \
              -default 0 -cancel 1

    $w add -text [::msgcat::mc "OK"] \
        -command [list [namespace current]::end_dialog $w ok]
    $w add -text [::msgcat::mc "Cancel"] \
        -command [list [namespace current]::end_dialog $w cancel]

    set f [$w getframe]

    bind $f <Destroy> [list [namespace current]::end_dialog [double% $w] cancel]

    set tools [Frame $f.tools]
    pack $tools -side bottom -fill x

    set sw [ScrolledWindow $w.sw]

    set lf [Text $w.nicks -width 32 -height 14 -cursor left_ptr -font $::ChatFont]
    pack $sw -side top -expand yes -fill both -in $f -pady 1m -padx 1m
    $sw setwidget $lf

    foreach nick [lsort -dictionary [array names NickColors]] {
        set clr $NickColors($nick)
        $lf tag configure NICK-$nick -foreground $clr
        $lf tag bind NICK-$nick <Enter> \
            [double% [list [namespace current]::on_nick_hover $lf $nick Enter]]
        $lf tag bind NICK-$nick <Leave> \
            [double% [list [namespace current]::on_nick_hover $lf $nick Leave]]
        $lf tag bind NICK-$nick <ButtonPress-1> \
            [double% [list [namespace current]::on_nick_click $lf $nick]]
        $lf insert end $nick [list NICK-$nick]
        $lf insert end "\n"
    }

    $lf configure -state disabled

    $w draw
}

proc nickcolors::end_dialog {w res} {
    variable options
    variable NickColors
    variable NickColorEdits

    bind [$w getframe] <Destroy> { }
    destroy $w

    if {$res == "ok"} {
        array set NickColors [array get NickColorEdits]
        change_options
    }
    catch {unset NickColorEdits}
}

proc nickcolors::on_nick_hover {w nick event} {
    if {$event == "Enter"} {
        $w tag configure NICK-$nick -underline 1
        $w configure -cursor hand2
    } else {
        $w tag configure NICK-$nick -underline 0
        $w configure -cursor left_ptr
    }
}

proc nickcolors::on_nick_click {w nick} {
    variable NickColorEdits

    if {[info exists NickColorEdits($nick)]} {
        set clr $NickColorEdits($nick)
    } else {
        set clr [$w cget -foreground]
    }
    set new [tk_chooseColor -initialcolor $clr \
                 -title [::msgcat::mc "Edit %s color" $nick]]
    if {$new != ""} {
        $w tag configure NICK-$nick -foreground $new
        set NickColorEdits($nick) $new
        [namespace current]::save_nick_colors
    }
}

proc nickcolors::change_options {args} {
    variable options
    variable NicksInChat

    foreach chatid [chat::opened] {
        set wn [chat::chat_win $chatid]
        if {[winfo exists $wn]} {
            if {[chat::is_groupchat $chatid]} {
                chat::update_roster_foregrounds $chatid
            }
            foreach nick $NicksInChat($chatid) {
                set clr [get_color $nick]
                $wn tag configure NICK-$nick \
                    -foreground [expr {$options(use_colored_nicks) ? $clr : ""}]
                $wn tag configure NICKMSG-$nick \
                    -foreground [expr {$options(use_colored_nicks) ? $clr : ""}]
                $wn tag configure MSG-$nick \
                    -foreground [expr {$options(use_colored_messages) ? $clr : ""}]
            }
        }
    }
}

proc nickcolors::add_chat_win_popup_menu {m chatwin X Y x y} {
    variable options

    set tags [$chatwin tag names "@$x,$y"]
    set nick ""
    if {$options(use_colored_messages)} {
        if {[set idx [lsearch -glob $tags MSG-*]] >= 0} {
            set nick [string range [lindex $tags $idx] 4 end]
        }
    }
    if {$options(use_colored_nicks)} {
        if {[set idx [lsearch -glob $tags NICK-*]] >= 0} {
            set nick [string range [lindex $tags $idx] 5 end]
        }
        if {[set idx [lsearch -glob $tags NICKMSG-*]] >= 0} {
            set nick [string range [lindex $tags $idx] 5 end]
        }
    }

    if {$nick == ""} return

    $m add command -label [::msgcat::mc "Edit nick color..."] \
        -command [list [namespace current]::edit_nick_color $chatwin $nick]
}

proc nickcolors::add_groupchat_user_menu_items {m xlib jid} {
    variable options

    if {$options(use_colored_roster_nicks)} {
        set chatid [chat::chatid $xlib [::xmpp::jid::removeResource $jid]]
        set chatwin [chat::chat_win $chatid]
        set nick [chat::get_nick $xlib $jid groupchat]
        $m add command -label [::msgcat::mc "Edit nick color..."] \
            -command [list [namespace current]::edit_nick_color $chatwin $nick]
    }
}

proc nickcolors::edit_nick_color {chatwin nick} {
    variable NickColors

    set new [tk_chooseColor -initialcolor [get_color $nick] \
                 -title [::msgcat::mc "Edit %s color" $nick]]
    if {$new == ""} return

    if {$new != [get_color $nick]} {
        set NickColors($nick) $new
        change_options
        [namespace current]::save_nick_colors
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
