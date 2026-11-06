# geometry.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       saves and restores the main Tkabber window geometry.

namespace eval geometry {
    custom::defvar MainWindowState {} \
        [::msgcat::mc "Stored main window state (normal or zoomed)"] \
        -type string -group Hidden

    custom::defvar MainWindowStateUntabbed {} \
        [::msgcat::mc "Stored main window state (normal or zoomed) in\
                       non-tabbed mode"] \
        -type string -group Hidden

    custom::defvar MainWindowGeometry {} \
        [::msgcat::mc "Stored main window geometry"] \
        -type string -group Hidden

    custom::defvar MainWindowGeometryUntabbed {} \
        [::msgcat::mc "Stored main window geometry in non-tabbed mode"] \
        -type string -group Hidden

    hook::add finload_hook [namespace current]::setupBindings 101
    hook::add finload_hook [namespace current]::restoreMainWindowState 99.9
}

proc geometry::setupBindings {} {
    bind . <Map> [namespace current]::saveMainWindowState
    bind . <Configure> [namespace current]::saveMainWindowGeometry
}

proc geometry::saveMainWindowState {} {
    global usetabbar
    variable MainWindowState
    variable MainWindowStateUntabbed

    set screen [winfo screen .]
    if {$usetabbar} {
        array set tmp $MainWindowState
    } else {
        array set tmp $MainWindowStateUntabbed
    }

    set state [wmstate .]
    if {![info exists tmp($screen)] || ![string equal $state $tmp($screen)]} {
        set tmp($screen) $state
        if {$usetabbar} {
            set MainWindowState [array get tmp]
        } else {
            set MainWindowStateUntabbed [array get tmp]
        }
    }
}

proc geometry::saveMainWindowGeometry {} {
    after cancel [namespace current]::afterSaveMainWindowGeometry
    after idle [namespace current]::afterSaveMainWindowGeometry
}

proc geometry::afterSaveMainWindowGeometry {} {
    global usetabbar
    variable MainWindowGeometry
    variable MainWindowGeometryUntabbed

    set state [wmstate .]
    if {![string equal $state normal]} {
        return
    }

    set screen [winfo screen .]
    if {$usetabbar} {
        array set tmp $MainWindowGeometry
    } else {
        array set tmp $MainWindowGeometryUntabbed
    }

    set geometry [wm geometry .]
    if {![info exists tmp($screen)] || ![string equal $geometry $tmp($screen)]} {
        set tmp($screen) $geometry
        if {$usetabbar} {
            set MainWindowGeometry [array get tmp]
        } else {
            set MainWindowGeometryUntabbed [array get tmp]
        }
    }
}

proc geometry::restoreMainWindowState {} {
    global tcl_platform
    global usetabbar
    variable MainWindowState
    variable MainWindowStateUntabbed
    variable MainWindowGeometry
    variable MainWindowGeometryUntabbed

    set screen [winfo screen .]

    if {$usetabbar} {
        array set tmp1 $MainWindowGeometry
    } else {
        array set tmp1 $MainWindowGeometryUntabbed
    }
    if {[info exists tmp1($screen)]} {
        wm geometry . $tmp1($screen)
    }

    if {$usetabbar} {
        array set tmp2 $MainWindowState
    } else {
        array set tmp2 $MainWindowStateUntabbed
    }
    if {[info exists tmp2($screen)] && [string equal $tmp2($screen) zoomed]} {
        wmstate . zoomed
    }
    update
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
