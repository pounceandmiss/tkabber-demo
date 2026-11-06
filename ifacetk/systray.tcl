# systray.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements
#       infrastructure for tray icon support.
#
#       See also plugins/unix/tktray.tcl, plugins/unix/systray.tcl,
#       plugins/unix/dokingtray.tcl, plugins/windows/taskbar.tcl.

namespace eval systray {
    variable saved_state normal
    variable saved_geometry
    variable balloon ""

    variable s2p
    array set s2p {}

    variable icons {}

    variable options

    custom::defgroup Systray [::msgcat::mc "Systray icon options."] \
        -group IFace

    custom::defvar options(display_status) 0 \
        [::msgcat::mc "Display status tooltip when main window is minimized\
                       to systray."] \
        -group Systray -type boolean

    custom::defvar options(blink_type) 100 \
        [::msgcat::mc "Systray icon blinks when there are unread messages."] \
        -group Systray -type options \
        -values [list 1    [::msgcat::mc "On any messages (including\
                                          service messages)"] \
                      2    [::msgcat::mc "On conference and personal\
                                          messages"] \
                      3    [::msgcat::mc "On personal messages only"] \
                      100  [::msgcat::mc "Turn blinking off"]]

    custom::defvar options(display_muc_change) 1 \
        [::msgcat::mc "Change icon on server and enter/exit groupchat\
                       messages."] \
        -group Systray -type boolean

    custom::defvar options(display_muc_others) 1 \
        [::msgcat::mc "Change icon on other users groupchat messages."] \
        -group Systray -type boolean
}

##########################################################################

proc systray::token {icon} {
    return [namespace current]::$icon
}

##########################################################################

proc systray::create {icon args} {
    global curuserstatus
    variable icons

    set token [token $icon]
    if {[info exists $token]} {
        return -code error "Systray icon $icon exists"
    }
    lappend icons $icon
    upvar 0 $token state

    array set state {create "" configure "" destroy "" tray ""}

    foreach {key val} $args {
        switch -- $key {
            -createcommand { set state(create) $val }
            -existscommand { set state(exists) $val }
            -configurecommand { set state(configure) $val }
            -destroycommand { set state(destroy) $val }
            -locationcommand { set state(location) $val }
        }
    }

    {*}$state(create) $icon
    update $icon ::curuserstatus
    update $icon ::tabcolors

    foreach var [list curuserstatus tabcolors] {
        trace add variable ::$var write [namespace code [list update $icon]]
    }
}

##########################################################################

proc systray::destroy {icon} {
    variable icons

    catch {
        upvar 0 [token $icon] state

        {*}$state(destroy) $icon
        unset state

        set id [lsearch -exact $icons $icon]
        if {$id >= 0} {
            set icons [lreplace $icons $id $id]
        }
    }

    foreach var [list curuserstatus tabcolors] {
        trace remove variable ::$var write [namespace code [list update $icon]]
    }
}

##########################################################################

proc systray::popupmenu {m} {
    set tearoff [set [namespace parent]::options(show_tearoffs)]

    menu $m -title [::msgcat::mc "Tkabber Systray"] -tearoff $tearoff
    $m add command -label [::msgcat::mc "About"] \
        -command [list [namespace parent]::about_window]
    $m add separator

    hook::run systray_menu_hook $m

    return $m
}

##########################################################################

# Withdraws the main Tkabber window from the screen:
proc systray::withdraw {} {
    variable saved_state
    variable saved_geometry

    if {[wmstate .] eq "withdrawn"} return

    set saved_state [wmstate .]
    set saved_geometry [wm geometry .]
    wm withdraw .
}

# Iconifies the main Tkabber window:
proc systray::iconify {} {
    if {[wmstate .] eq "iconic"} return

    wm iconify .
}

# De-withdraws the main Tkabber window:
proc systray::reshow {} {
    variable saved_state
    variable saved_geometry

    if {[wmstate .] ne "withdrawn"} return

    if {[info exists saved_state]} {
        if {$saved_state ne "zoomed" && [info exists saved_geometry]} {
            wm geometry . $saved_geometry
        }
        wmstate . $saved_state
    } else {
        if {[info exists saved_geometry]} {
            wm geometry . $saved_geometry
        }
        wmstate . normal
    }
    wm deiconify .
}

# Restores the main Tkabber window from iconic or withdrawn states:
proc systray::restore {} {
    switch -- [wmstate .] {
        iconic {
            wm deiconify .
        }
        withdrawn {
            reshow
        }
        default {
            wm deiconify .
        }
    }
    raise .
    hook::run restore_main_window_hook
}

proc systray::toggle_state {} {
    switch -- [wmstate .] {
        zoomed -
        normal {
            withdraw
        }

        iconic -
        withdrawn -
        default {
            restore
        }
    }
}

##########################################################################

proc systray::wm_win_iconify {action} {
    variable icons

    if {$action eq "systray"} {
        if {[llength $icons] > 0} {
            toggle_state
        }
        return stop
    }
}

hook::add protocol_wm_delete_window_hook \
    [namespace current]::systray::wm_win_iconify 40

##########################################################################

proc systray::quit {} {
    variable icons

    foreach icon $icons {
        destroy $icon
    }
}

hook::add quit_hook [namespace current]::systray::quit

##########################################################################

proc systray::update {icon name1 {name2 ""} {op ""}} {
    global curuserstatus
    upvar 0 [token $icon] state

    if {![info exists state(tray)]} return

    switch -- [string trimleft $name1 :] {
        curuserstatus {
            if {$state(tray) eq ""} {
                {*}$state(configure) $icon $curuserstatus
            }
        }

        tabcolors {
            toggle $icon 1
        }
    }
}

##########################################################################

proc systray::toggle {icon ff} {
    global curuserstatus tabcolors
    variable options
    upvar 0 [token $icon] state

    if {![info exists state(tray)]} return
    if {![{*}$state(exists) $icon]} return

    if {$state(tray) ne ""} {
        after cancel $state(tray)
        set state(tray) ""
    }

    set hitP 0
    foreach {k v} [array get tabcolors] {
        if {[.nb index $k] < 0} {
            continue
        }
        if {($v ne "") && ($v > $hitP)} {
            set hitP $v
        }
    }

    if {($hitP == 0) ||
            (($hitP == 1) && !$options(display_muc_change)) ||
        (($hitP == 2) && !$options(display_muc_others))} {
        update $icon ::curuserstatus
        return
    }

    if {$options(blink_type) <= $hitP} {
        set state(tray) \
            [after 500 [list [namespace current]::toggle $icon [expr {!$ff}]]]
        if {$ff} {
            {*}$state(configure) $icon message$hitP
        } else {
            {*}$state(configure) $icon blank
        }
    } else {
        set state(tray) message
        {*}$state(configure) $icon message$hitP
    }
}

##########################################################################

proc systray::set_status {text} {
    variable options
    variable icons
    variable balloon

    if {!$options(display_status)} return
    if {[llength $icons] == 0} return

    set icon [lindex $icons 0]
    upvar 0 [token $icon] state

    switch -- [wmstate .] {
        normal { }
        default {
            if {[info exists balloon] && ($balloon ne "")} {
                after cancel $balloon
                set balloon ""
            }

            if {![{*}$state(exists) $icon]} {
                return
            }
            balloon::set_text $text
            if {[info exists state(location)]} {
                lassign [{*}$state(location) $icon] x y
            } else {
                set x [winfo rootx $icon]
                set y [winfo rooty $icon]
            }
            balloon::show $x $y
            set balloon [after 15000 balloon::destroy]
        }
    }
}

hook::add set_status_hook [namespace current]::systray::set_status

##########################################################################

proc systray::clear_status {} {
    variable options
    variable icons
    variable balloon

    if {!$options(display_status)} return
    if {[llength $icons] == 0} return

    if {[info exists balloon] && ($balloon ne "")} {
        after cancel $balloon
        set balloon ""
    }
    balloon::destroy
}

hook::add clear_status_hook [namespace current]::systray::clear_status

##########################################################################

proc systray::balloon {icon} {
    return [list $icon [balloon_text]]
}

##########################################################################

proc systray::balloon_text {} {
    global userstatusdesc textstatus

    if {$textstatus ne ""} {
        set status $textstatus
    } else {
        set status $userstatusdesc
    }

    return "Tkabber: $status"
}

##########################################################################

proc systray::create_menu {m} {
    $m add command -label [::msgcat::mc "Log in..."] \
                   -command ::ifacetk::login_dialog
    $m add command -label [::msgcat::mc "Log out"] \
                   -command ::ifacetk::logout_dialog
    $m add command -label [::msgcat::mc "Log out with reason..."] \
                   -command show_logout_dialog
    $m add separator
    $m add command -label [::msgcat::mc "Show main window"] \
                   -command [namespace code restore]
    $m add command -label [::msgcat::mc "Hide main window"] \
                   -command [namespace code withdraw]
    $m add separator
    $m add command -label [::msgcat::mc "Quit"] -command quit
}

hook::add systray_menu_hook \
                   [namespace current]::systray::create_menu

# vim:ft=tcl:ts=8:sw=4:sts=4:et
