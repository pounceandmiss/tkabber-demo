# console.tcl --
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       adds a console menu item into the services->debug submenu under
#       MS Windows.

namespace eval console {
    variable showConsole 0
    hook::add finload_hook [namespace current]::add_console_menu

    console eval {
        bind . <Map> {
            consoleinterp eval {set ::plugins::console::showConsole 1}
        }
            bind . <Unmap> {
            consoleinterp eval {set ::plugins::console::showConsole 0}
        }
    }
}

proc console::add_console_menu {} {
    set menu [.mainframe getmenu debug]
    $menu add checkbutton -label [::msgcat::mc "Show console"] \
                          -command [namespace current]::show_console \
                          -variable [namespace current]::showConsole
    show_console
}

proc console::show_console {} {
    variable showConsole
    if {$showConsole} {
        console show
    } else {
        console hide
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
