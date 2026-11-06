# tktray.tcl --
#
#       Another Freedesktop systray icon support.
#       Requires tktray (http://sw4me.com/wiki/Tktray) package

if {[catch { package require tktray }]} return

##########################################################################

namespace eval tktray {
    variable options

    custom::defvar options(enable) 1 \
        [::msgcat::mc "Enable freedesktop system tray icon."] \
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

proc tktray::enable_disable {args} {
    variable options

    set icon .tksi

    if {$options(enable) && ![winfo exists $icon]} {
        ifacetk::systray::create $icon \
            -createcommand [namespace code create] \
            -existscommand [namespace code exists] \
            -configurecommand [namespace code configure] \
            -destroycommand [namespace code destroy] \
            -locationcommand [namespace code location]
    } elseif {!$options(enable) && [winfo exists $icon]} {
        ifacetk::systray::destroy $icon
    }
}

hook::add finload_hook [namespace current]::tktray::enable_disable

##########################################################################

proc tktray::create {icon} {
    variable s2p

    tktray::icon $icon -image $s2p(unavailable) -class TkabberIcon
    update idletasks

    set m [ifacetk::systray::popupmenu $icon.menu]

    bind $icon <ButtonRelease-1> ifacetk::systray::restore
    bind $icon <<PasteSelection>> ifacetk::systray::withdraw
    bind $icon <<ContextMenu>> [list tk_popup [double% $m] %X %Y]
    balloon::setup $icon -command [list ifacetk::systray::balloon $icon]
}

##########################################################################

proc tktray::exists {icon} {
    expr {$icon ne "" && [winfo exists $icon]}
}

##########################################################################

proc tktray::configure {icon status} {
    variable s2p

    if {$icon ne "" && [winfo exists $icon]} {
        $icon configure -image $s2p($status)
    }
}

##########################################################################

proc tktray::destroy {icon} {
    if {$icon ne "" && [winfo exists $icon]} {
        ::destroy $icon
    }
}

##########################################################################

proc tktray::location {icon} {
    if {$icon ne "" && [winfo exists $icon]} {
        return [lrange [$icon bbox] 0 1]
    } else {
        return {0 0}
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
