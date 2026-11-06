# menu.tcl --
#
#       This file is a part of the Tkabber XMPP client. It overrides the
#       stock Tcl/Tk menues on UNIX and make them stay after button is up,
#       which is way more convenient.

namespace eval :: {

proc myMenuButtonDown {args} {
    global myMenuFlag myMenuMotion
    ::tk::MenuButtonDown {*}$args
    set myMenuFlag 1
}

proc myMenuInvoke {args} {
    global myMenuFlag myMenuMotion
    if {$myMenuFlag || $myMenuMotion} {
        ::tk::MenuInvoke {*}$args
    }
    set myMenuFlag 0
    set myMenuMotion 0
}

proc myMenuMotion {args} {
    global myMenuFlag myMenuMotion
    ::tk::MenuMotion {*}$args
    set myMenuMotion 1
}

proc myMenuLeave {args} {
    global myMenuFlag myMenuMotion
    ::tk::MenuLeave {*}$args
    set myMenuMotion 0
}

bind Menu <Leave> {myMenuLeave %W %X %Y %s}
bind Menu <ButtonPress> {myMenuButtonDown %W}
bind Menu <ButtonRelease> {myMenuInvoke %W 1}
bind Menu <Motion> {myMenuMotion %W %x %y %s}

set myMenuFlag 0
set myMenuMotion 0

# ::tk::MenuNextEntry --
# Activate the next higher or lower entry in the posted menu,
# wrapping around at the ends.  Disabled entries are skipped.
#
# Arguments:
# menu -                        Menu window that received the keystroke.
# count -                       1 means go to the next lower entry,
#                               -1 means go to the next higher entry.

proc ::tk::MenuNextEntry {menu count} {
    global ::tk::Priv

    if {[string equal [$menu index last] "none"]} {
        return
    }
    set length [expr {[$menu index last]+1}]
    set quitAfter $length
    set active [$menu index active]
    if {[string equal $active "none"]} {
        set i 0
    } else {
        set i [expr {$active + $count}]
    }
    while {1} {
        if {$quitAfter <= 0} {
            # We've tried every entry in the menu.  Either there are
            # none, or they're all disabled.  Just give up.

            return
        }
        while {$i < 0} {
            incr i $length
        }
        while {$i >= $length} {
            incr i -$length
        }
        if {[catch {$menu entrycget $i -state} state] == 0} {
            if {[string compare $state "disabled"]} {
                break
            }
        }
        if {$i == $active} {
            return
        }
        incr i $count
        incr quitAfter -1
    }
    $menu activate $i
    ::tk::GenerateMenuSelect $menu
    if {[string equal [$menu type $i] "cascade"]} {
        set cascade [$menu entrycget $i -menu]
        if {[string equal [$menu cget -type] "menubar"] && [string compare $cascade ""]} {
            # Here we auto-post a cascade.  This is necessary when
            # we traverse left/right in the menubar, but undesirable when
            # we traverse up/down in a menu.
            $menu postcascade $i
            ::tk::MenuFirstEntry $cascade
        }
    }
}

# ::tk::MenuNextMenu --
# This procedure is invoked to handle "left" and "right" traversal
# motions in menus.  It traverses to the next menu in a menu bar,
# or into or out of a cascaded menu.
#
# Arguments:
# menu -                The menu that received the keyboard
#                       event.
# direction -           Direction in which to move: "left" or "right"

proc ::tk::MenuNextMenu {menu direction} {
    global ::tk::Priv

    # First handle traversals into and out of cascaded menus.

    if {[string equal $direction "right"]} {
        set count 1
        set parent [winfo parent $menu]
        set class [winfo class $parent]
        if {[string equal [$menu type active] "cascade"]} {
            $menu postcascade active
            set m2 [$menu entrycget active -menu]
            if {[string compare $m2 ""]} {
                ::tk::MenuFirstEntry $m2
            }
            return
        } else {
            set parent [winfo parent $menu]
            while {[string compare $parent "."]} {
                if {[string equal [winfo class $parent] "Menu"] \
                        && [string equal [$parent cget -type] "menubar"]} {
                    tk_menuSetFocus $parent
                    ::tk::MenuNextEntry $parent 1
                    return
                }
                set parent [winfo parent $parent]
            }
        }
    } else {
        set count -1
        set m2 [winfo parent $menu]
        if {[string equal [winfo class $m2] "Menu"]} {
            if {[string compare [$m2 cget -type] "menubar"]} {
                $menu activate none
                ::tk::GenerateMenuSelect $menu
                tk_menuSetFocus $m2

                # This code unposts any posted submenu in the parent.
                $m2 postcascade none

                #set tmp [$m2 index active]
                #$m2 activate none
                #$m2 activate $tmp
                return
            }
        }
    }

    # Can't traverse into or out of a cascaded menu.  Go to the next
    # or previous menubutton, if that makes sense.

    set m2 [winfo parent $menu]
    if {[string equal [winfo class $m2] "Menu"]} {
        if {[string equal [$m2 cget -type] "menubar"]} {
            tk_menuSetFocus $m2
            ::tk::MenuNextEntry $m2 -1
            return
        }
    }

    set w $::tk::Priv(postedMb)
    if {[string equal $w ""]} {
        return
    }
    set buttons [winfo children [winfo parent $w]]
    set length [llength $buttons]
    set i [expr {[lsearch -exact $buttons $w] + $count}]
    while {1} {
        while {$i < 0} {
            incr i $length
        }
        while {$i >= $length} {
            incr i -$length
        }
        set mb [lindex $buttons $i]
        if {[string equal [winfo class $mb] "Menubutton"] \
                && [string compare [$mb cget -state] "disabled"] \
                && [string compare [$mb cget -menu] ""] \
                && [string compare [[$mb cget -menu] index last] "none"]} {
            break
        }
        if {[string equal $mb $w]} {
            return
        }
        incr i $count
    }
    ::tk::MbPost $mb
    ::tk::MenuFirstEntry [$mb cget -menu]
}

# ::tk::MenuFirstEntry --
# Given a menu, this procedure finds the first entry that isn't
# disabled or a tear-off or separator, and activates that entry.
# However, if there is already an active entry in the menu (e.g.,
# because of a previous call to ::tk::PostOverPoint) then the active
# entry isn't changed.  This procedure also sets the input focus
# to the menu.
#
# Arguments:
# menu -                Name of the menu window (possibly empty).

proc ::tk::MenuFirstEntry menu {
    if {[string equal $menu ""]} {
        return
    }
    tk_menuSetFocus $menu
    if {[string compare [$menu index active] "none"]} {
        return
    }
    set last [$menu index last]
    if {[string equal $last "none"]} {
        return
    }
    for {set i 0} {$i <= $last} {incr i} {
        if {([catch {set state [$menu entrycget $i -state]}] == 0) \
                && [string compare $state "disabled"]} {
            $menu activate $i
            ::tk::GenerateMenuSelect $menu
            # Only post the cascade if the current menu is a menubar;
            # otherwise, if the first entry of the cascade is a cascade,
            # we can get an annoying cascading effect resulting in a bunch of
            # menus getting posted (bug 676)
            if {[string equal [$menu type $i] "cascade"] && \
                [string equal [$menu cget -type] "menubar"]} {
                set cascade [$menu entrycget $i -menu]
                if {[string compare $cascade ""]} {
                    $menu postcascade $i
                    ::tk::MenuFirstEntry $cascade
                }
            }
            return
        }
    }
}

# ::tk::MenuMotion --
# This procedure is called to handle mouse motion events for menus.
# It does two things.  First, it resets the active element in the
# menu, if the mouse is over the menu.  Second, if a mouse button
# is down, it posts and unposts cascade entries to match the mouse
# position.
#
# Arguments:
# menu -                The menu window.
# x -                   The x position of the mouse.
# y -                   The y position of the mouse.
# state -               Modifier state (tells whether buttons are down).

proc ::tk::MenuMotion {menu x y state} {
    global ::tk::Priv
    if {[string equal $menu $::tk::Priv(window)]} {
        if {[string equal [$menu cget -type] "menubar"]} {
            if {[info exists ::tk::Priv(focus)] && \
                    [string compare $menu $::tk::Priv(focus)]} {
                $menu activate @$x,$y
                ::tk::GenerateMenuSelect $menu
            }
        } else {
            $menu activate @$x,$y
            ::tk::GenerateMenuSelect $menu
        }
    }
    #debugmsg plugins "MENU: $menu $::tk::Priv(activeMenu) $::tk::Priv(activeItem) $::tk::Priv(focus)"
    if {(![string equal [$menu cget -type] "menubar"]) || \
            ([info exist ::tk::Priv(focus)] && ($::tk::Priv(focus) != "") && ($::tk::Priv(activeItem) != "none"))} {
        myMenuPostCascade $menu
    }
}

set myPriv(id) ""
set myPriv(delay) 170
set myPriv(activeMenu) ""
set myPriv(activeItem) ""

proc myMenuPostCascade {menu} {
    global myPriv

    if {$myPriv(id) != ""} {
        if {($myPriv(activeMenu) == $menu) && ($myPriv(activeItem) == [$menu index active])} {
            return
        } else {
            after cancel $myPriv(id)
        }
    }
    if {[string equal [$menu cget -type] "menubar"]} {
        $menu postcascade active
    } else {
        set myPriv(activeMenu) $menu
        set myPriv(activeItem) [$menu index active]
        set myPriv(id) [after $myPriv(delay) "$menu postcascade active"]
    }
}

}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
