# tkcon.tcl --
#
#       This file is a part of the Tkabber XMPP client. It shows TkCon console
#       in the Tkabber menu if you're running tkabber under the tkcon package
#
#           http://tkcon.sourceforge.net
#
#       e.g.,
#
#       % tkcon.tcl -name tkabber -exec "" -root .tkconn -main "source tkabber.tcl"
#
#       or if tkcon is installed as a Tcl package and can be sourced via
#       [package require] (tkcon isn't loaded at start, so it doesn't waste
#       resources if it's unneeded).

if {[llength [package versions tkcon]] == 0 && \
        [llength [info commands ::tkcon::*]] <= 0} {
    return
}

namespace eval tkcon {
    variable onceP 1
    variable showP 0
}

proc tkcon::add_tkcon_to_tkabber_menu {args} {
    catch {
        set menu [.mainframe getmenu debug]
        $menu add checkbutton -label [::msgcat::mc "Show TkCon console"] \
              -command  [namespace current]::show_console \
              -variable [namespace current]::showP
        show_console
    }
}

proc tkcon::show_console {} {
    variable onceP
    variable showP

    if {[llength [info commands ::tkcon::*]] <= 0} {
        package require tkcon
    }

    if {$showP} {
        tkcon show

        if {$onceP} {
            wm protocol $::tkcon::PRIV(root) WM_DELETE_WINDOW \
                    [namespace current]::hide_console
            set onceP 0
        }
    } else {
        tkcon hide
    }
}

proc tkcon::hide_console {} {
    variable showP

    tkcon hide
    set showP 0
}

hook::add finload_hook [namespace current]::tkcon::add_tkcon_to_tkabber_menu

# vim:ft=tcl:ts=8:sw=4:sts=4:et
