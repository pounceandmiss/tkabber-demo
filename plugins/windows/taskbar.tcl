# taskbar.tcl --
#
#       MS Windows taskbar and tray icon support.
#       Requires Winico package
#       (http://tktable.sourceforge.net/winico/winico.html)

if {[catch { package require Winico }]} return

##########################################################################

namespace eval taskbar {
    variable s2p
    array set s2p [list blank       0 \
                        available   1 \
                        away        2 \
                        chat        3 \
                        dnd         4 \
                        xa          5 \
                        unavailable 6 \
                        invisible   7 \
                        browser     8 \
                        group       9 \
                        browser32   10 \
                        group32     11 \
                        available32 12 \
                        message1    13 \
                        message2    14 \
                        message3    15]

    variable options

    custom::defvar options(enable) 1 \
        [::msgcat::mc "Enable windows tray icon."] \
        -group Systray -type boolean \
        -command [namespace code enable_disable]
}

##########################################################################
#
# Systray icons
#
##########################################################################

proc taskbar::set_current_theme {} {
    variable icon
    variable s2p
    global curuserstatus

    set newicon [winico createfrom [pixmaps::get_filename docking/tkabber]]

    if {[info exists icon]} {
        set oldicon $icon
        set icon $newicon

        # Change taskbar icon:
        winico taskbar add $newicon
        # TODO ideally there should be a call to [enable_disable]
        # instead but the latter relies on the existence of some
        # windows (i.e. it's called from finload_hook) while this
        # proc is called for the first time earlier in the loading
        # sequence...
        configure .tray $curuserstatus

        # Change icons of all mapped toplevels:
        foreach w [wm stackorder .] {
            win_icon_setup $w
        }

        winico delete $oldicon
    } else {
        set icon $newicon
    }
}

hook::add set_theme_hook [namespace current]::taskbar::set_current_theme

##########################################################################

proc taskbar::enable_disable {args} {
    variable options

    set m .tray

    if {$options(enable) && ![winfo exists $m]} {
        ifacetk::systray::create $m \
            -createcommand [namespace code create] \
            -existscommand [namespace code exists] \
            -configurecommand [namespace code configure] \
            -destroycommand [namespace code destroy]
    } elseif {!$options(enable) && [winfo exists $m]} {
        ifacetk::systray::destroy $m
    }
}

hook::add finload_hook [namespace current]::taskbar::enable_disable

##########################################################################

proc taskbar::create {m} {
    variable icon
    variable s2p

    set m [ifacetk::systray::popupmenu .tray]

    winico taskbar add $icon -pos $s2p(unavailable) \
           -callback [namespace code [list callback $m %m %x %y]] \
           -text [ifacetk::systray::balloon_text]
}

##########################################################################

proc taskbar::configure {m} {
    winfo exists $m
}

##########################################################################

proc taskbar::configure {m status} {
    variable icon
    variable s2p

    if {[info exists icon] && $icon ne ""} {
        winico taskbar modify $icon -pos $s2p($status) \
               -text [ifacetk::systray::balloon_text]
    }
}

##########################################################################

proc taskbar::destroy {m} {
    variable icon

    if {[info exists icon] && $icon ne ""} {
        winico taskbar delete $icon
        ::destroy $m
    }
}

##########################################################################

proc taskbar::callback {m event x y} {
    switch -- $event {
        WM_LBUTTONUP {
            ifacetk::systray::restore
        }

        WM_MBUTTONUP {
            ifacetk::systray::withdraw
        }

        WM_RBUTTONUP {
            $m post $x $y
        }
    }
}

##########################################################################
#
# Window & taskbar icons
#
##########################################################################

proc taskbar::win_icons {} {
    variable icon
    variable s2p

    winico setwindow . $icon small $s2p(unavailable)
    winico setwindow . $icon big $s2p(available32)

    trace add variable ::curuserstatus write [namespace code update]

    bind all <Map> +[namespace code {
        if {[string equal [winfo toplevel %W] %W]} { win_icon_setup %W }
    }]
}

hook::add finload_hook [namespace current]::taskbar::win_icons

##########################################################################

proc taskbar::win_icon_setup {w} {
    variable icon
    variable s2p
    global curuserstatus

    if {$icon eq ""} return

    # Special case for the main window (which is also the roster
    # window in windowed UI mode) -- it shows the current
    # user status in its window icon:
    if {[string equal $w .]} {
        winico setwindow $w $icon small $s2p($curuserstatus)
        winico setwindow $w $icon big $s2p(available32)
        return
    }

    switch -- [winfo class $w] {
        Chat {
            winico setwindow $w $icon small $s2p(group)
            winico setwindow $w $icon big $s2p(group32)
        }
        JDisco {
            winico setwindow $w $icon small $s2p(browser)
            winico setwindow $w $icon big $s2p(browser32)
        }
        default {
            winico setwindow $w $icon small $s2p(available)
            winico setwindow $w $icon big $s2p(available32)
        }
    }
}

##########################################################################

proc taskbar::update {name1 {name2 ""} {op ""}} {
    global curuserstatus
    variable icon
    variable s2p

    winico setwindow . $icon small $s2p($curuserstatus)
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
