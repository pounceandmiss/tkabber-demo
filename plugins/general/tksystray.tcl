# tksystray.tcl --
#
#       A universal systray icon support, both for Windows and for UNIX.
#       Requires Tcl/Tk 9.0 with its [tk systray] command.

if {[catch { tk systray exists }]} return

##########################################################################

namespace eval tksystray {
    variable options

    custom::defvar options(enable) 1 \
        [::msgcat::mc "Enable Window/UNIX system tray icon."] \
        -group Systray -type boolean \
        -command [namespace code enable_disable]

    variable s2p
    variable k
    variable v
    foreach {k v} [list available   available      \
                        away        away           \
                        chat        chat           \
                        dnd         dnd            \
                        xa          xa             \
                        unavailable unavailable    \
                        invisible   invisible      \
                        blank       blank          \
                        message1    message-server \
                        message2    message        \
                        message3    message-personal] {
        set s2p($k) docking/$v
    }
}

##########################################################################

proc tksystray::enable_disable {args} {
    variable options

    set icon .tksysi

    if {$options(enable) && ![tk systray exists]} {
        ifacetk::systray::create $icon \
            -createcommand [namespace code create] \
            -existscommand [namespace code exists] \
            -configurecommand [namespace code configure] \
            -destroycommand [namespace code destroy]
    } elseif {!$options(enable) && [tk systray exists]} {
        ifacetk::systray::destroy $icon
    }
}

hook::add finload_hook [namespace current]::tksystray::enable_disable

##########################################################################

proc tksystray::popup_menu {} {
    set m .systraymenu
    if {![winfo exists $m]} {
        ifacetk::systray::popupmenu $m
    }

    tk_popup $m [winfo pointerx .] [winfo pointery .]
}

proc tksystray::create {icon} {
    variable s2p

    tk systray create -image $s2p(unavailable) \
                      -text [ifacetk::systray::balloon_text] \
                      -button1 ifacetk::systray::restore \
                      -button3 [namespace code popup_menu]
    update idletasks
}

##########################################################################

proc tksystray::exists {icon} {
    tk systray exists
}

##########################################################################

proc tksystray::configure {icon status} {
    variable s2p

    if {[tk systray exists]} {
        tk systray configure -image $s2p($status) \
                             -text [ifacetk::systray::balloon_text]
    }
}

##########################################################################

proc tksystray::destroy {icon} {
    if {[tk systray exists]} {
        tk systray destroy
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
