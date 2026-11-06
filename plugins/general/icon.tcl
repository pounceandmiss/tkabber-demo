# icon.tcl --
#
#       This file is a part of the Tkabber XMPP client. This plugin provides
#       titlebar icons support.

##########################################################################

namespace eval icon {
    hook::add finload_hook [namespace current]::win_icons
}

##########################################################################

proc icon::win_icons {} {
    # Do not load static icon if a WindowMaker dock is used.
    if {[info exists ::wmaker_dock] && $::wmaker_dock} {
        return
    }

    wm iconphoto . roster/user/unavailable

    trace add variable ::curuserstatus write [namespace code update_icon]

    bind all <Map> +[namespace code {
        if {[string equal [winfo toplevel %W] %W]} { win_icon_setup %W }
    }]
}

##########################################################################

proc icon::win_icon_setup {w} {
    if {$w == "."} return

    switch -- [winfo class $w] {
        Chat {
            wm iconphoto $w roster/conference/available
        }
        JDisco {
            wm iconphoto $w roster/user/available
        }
        default {
            wm iconphoto $w roster/user/available
        }
    }
}

##########################################################################

proc icon::update_icon {name1 {name2 ""} {op ""}} {
    global curuserstatus

    wm iconphoto . roster/user/$curuserstatus
}

##########################################################################

proc icon::update_all_icons {} {
    catch {
        foreach w [concat . [winfo children .]] {
            win_icon_setup $w
        }
        update_icon curuserstatus
    }
}

hook::add set_theme_hook [namespace current]::icon::update_all_icons

# vim:ft=tcl:ts=8:sw=4:sts=4:et
