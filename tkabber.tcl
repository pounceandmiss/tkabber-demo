#!/bin/sh
# the next line restarts using the correct interpreter \
exec wish "$0" -name tkabber "$@"

# tkabber.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a main file.

package require Tk 8.5-

wm withdraw .

set interface tk
namespace eval ifacetk {}

foreach {opt val} $argv {
    switch -- $opt/$val {
        -interface/ttk  {
            set interface ttk
        }
    }
}

set aquaP 0
catch {
    switch -- [tk windowingsystem] {
        classic -
        aqua {
            set aquaP 1
            set tk_modify Cmd
            set tk_close Cmd-W

            rename ::bind ::bind_orig
            proc ::bind {args} {
                if {[llength $args] < 2} {
                    ::bind_orig {*}$args
                }
                if {[string first "<Control-" [set arg1 [lindex $args 1]]] == 0} {
                    set arg1 "<Command-[string range $arg1 9 end]"
                }

                ::bind_orig {*}[lreplace $args 1 1 $arg1]
            }
        }
    }
}
if {!$aquaP} {
    set tk_modify Ctrl
    set tk_close Ctrl-F4
}

set rootdir [file dirname [info script]]

if {[package provide starkit] != ""} {
    # In case of a starkit, $rootdir now holds a relative path,
    # so we glue it with the main "mount point"
    set rootdir [file join $::starkit::topdir $rootdir]
}

lappend auto_path [file join $rootdir tclxmpp]

package require msgcat
if {[info exists ::env(LC_MESSAGES)]} {
    ::msgcat::mclocale $::env(LC_MESSAGES)
}

tk appname tkabber

set debug_lvls {}

proc debugmsg {level msg} {
    global debug_lvls

    if {$level in $debug_lvls} {
        catch {puts "$level: $msg"}
    }
}

proc fullpath {args} {
    global rootdir
    return [file join $rootdir {*}$args]
}

proc load_source {args} {
    set fullpath [fullpath {*}$args]

    debugmsg tkabber "Loading $fullpath"
    uplevel #0 [list source $fullpath]
}

load_source configdir.tcl
# from now on Tkabber config directory should be referenced via $::configdir

proc get_vcs {} {
    if {[file exists [fullpath .fslckout]]} {
        return -fossil
    } elseif {[file exists [fullpath _FOSSIL_]]} {
        return -fossil
    } elseif {[file exists [fullpath .svn]]} {
        return -svn
    } elseif {[file exists [fullpath .git]]} {
        return -git
    } else {
        return ""
    }
}

proc get_snapshot {changelog} {
    set snapshot ""
    if {[catch { open $changelog } fd]} {
        return $snapshot
    }
    while {[gets $fd line] >= 0} {
        if {[regexp {(\d\d\d\d)-(\d\d)-(\d\d)} $line -> year month day]} {
            set snapshot "-$year$month$day"
            break
        }
    }
    close $fd
    return $snapshot
}

set tkabber_version "1.1.2[get_vcs][get_snapshot [fullpath ChangeLog]]"
set toolkit_version "Tcl/Tk [info patchlevel]"

proc quit {{status 0}} {
    hook::run quit_hook
    catch { bind $::ifacetk::mf <Destroy> {} }
    destroy .
    exit $status
}

namespace eval ifacetk {}
namespace eval ssj {}
load_source hooks.tcl

# Give the starkit a chance to initialize things before
# the bulk of the Tkabber code is loaded:
if {[info commands starkit_init] != ""} starkit_init

hook::add quit_hook logout 10

proc close_channels {} {
    foreach chan [file channels] {
        if {[string first sock $chan] != -1} {
            catch { close $chan } res
            debugmsg tkabber "closed $chan '$res'"
        }
    }
}

hook::add quit_hook close_channels 100

load_source default.tcl

hook::add postload_hook postload
hook::add finload_hook finload

package require BWidget

if {[info exists env(TKABBER_SITE_CONFIG)] && \
        [file exists $env(TKABBER_SITE_CONFIG)]} {
    source $env(TKABBER_SITE_CONFIG)
}

if {[file exists [file join $configdir config.tcl]]} {
    source [file join $configdir config.tcl]
}

# Determine if the theme is light or dark, and also
# fix the default foreground color

if {$interface eq "ttk"} {
    # If a ttk theme has been applied in the config file
    # the actual theme will be changed only after crating
    # some ttk widget, so do that here (otherwise the
    # default text background and foreground will be
    # always white and black.
    ttk::button .tmpb
    update idletasks
    destroy .tmpb
}

set t [text .tmpt]
set defaultforeground [$t cget -foreground]
set defaultbackground [$t cget -background]
lassign [winfo rgb $t $defaultforeground] r g b
set meanfg [expr {($r+$g+$b)/3}]
lassign [winfo rgb $t $defaultbackground] r g b
set meanbg [expr {($r+$g+$b)/3}]
if {$meanfg > $meanbg} {
    set darktheme 1
} else {
    set darktheme 0
}
destroy $t

# tk_scale: config variable to scale widgets
# tk_scale is taken from env(GDK_SCALE) if the latter
# is available
# type: real > 0
if {![info exists tk_scale]} {
    if {[info exists env(GDK_SCALE)] && \
            [string is integer -strict $env(GDK_SCALE)]} {
        set tk_scale $env(GDK_SCALE)
    } else {
        set tk_scale 1
    }
}
tk scaling [expr {$tk_scale * [tk scaling]}]

# icons_scale: config variable to scale the default icons
# (icons 16x16). If it's not set in the config file,
# heuristically compute it given that icons 16x16 are to
# be used with 96 DPI
# type: integer >= 1
if {![info exists icons_scale]} {
    set icons_scale [expr {([tk scaling]*72 + 32) / 96}]
}
set icons_scale [expr {int($icons_scale)}]
if {$icons_scale<1} {
    set icons_scale 1
}

proc create_image {args} {
    if {[llength $args] % 2 == 1} {
        set args [lassign $args name]
        set images [list $name]
    } else {
        set images {}
    }

    if {[dict exists $args -scale]} {
        set scale [dict get $args -scale]
        set args [dict remove $args -scale]
    } else {
        set scale $::icons_scale
    }

    if {$scale > 1} {
        set zoom [list -zoom $scale $scale]
    } else {
        set zoom {}
    }
    image create photo __tmp {*}$args
    set image [image create photo {*}$images]
    $image copy __tmp {*}$zoom
    return $image
}

if {$interface eq "ttk"} {
    Widget::theme 1
    set load_default_xrdb 0
}

option readfile [fullpath $interface default.xrdb] 21

if {![info exists load_default_xrdb] || $load_default_xrdb} {
    switch -- $tcl_platform(platform) {
        unix {
            source [fullpath ifacetk unix.tcl]
        }
    }
}

load_source trans.tcl
::trans::load [file join $rootdir trans]
::msgcat::mcload [file join $rootdir msgs]
foreach pr [::msgcat::mcpreferences] {
    set f [file join $::BWIDGET::LIBRARY lang $pr.rc]
    if {[file exists $f]} {
        option readfile $f
        break
    }
}
foreach pr [::msgcat::mcpreferences] {
    set f [file join $rootdir msgs $pr.rc]
    if {[file exists $f]} {
        option readfile $f
        break
    }
}
unset pr f

package require xmpp 0.3
package require xmpp::delay

load_source xmppmime.tcl

foreach {opt val} $argv {
    switch -- $opt {
        -mime       {set mime_file $val}
        -user       {set loginconf(user) $val}
        -password   {set loginconf(password) $val}
        -resource   {set loginconf(resource) $val}
        -port       {set loginconf(port) $val}
        -autologin  {set autologin $val}
        -chat       {xmppmime::send_event [list chat $val]}
        -message    {xmppmime::send_event [list message $val]}
        -conference {xmppmime::send_event [list groupchat $val]}
        -splash     {set show_splash_window $val}
    }
}

if {[info exists mime_file]} {
    xmppmime::load $mime_file
}
if {[xmppmime::is_done]} exit

load_source $interface bwidget.tcl
load_source splash.tcl

if {[catch { package require Img }]} {
    if {[catch { package require tkpng }]} {
        set msg "Unable to load the Img or tkpng package, so no PNG/JPEG image support!"
    } else {
        set msg "Unable to load the Img package, so no JPEG image support!"
    }
    debugmsg tkabber "$msg

The IMG package is available at https://tkimg.sourceforge.net/"
}

load_source idna.tcl
load_source namespaces.tcl
load_source ifacetk default.tcl
load_source custom.tcl
load_source utils.tcl
load_source plugins.tcl
load_source pixmaps.tcl
load_source balloon.tcl
load_source presence.tcl
load_source iq.tcl
load_source disco.tcl
load_source roster.tcl
load_source messages.tcl
load_source chats.tcl
load_source muc.tcl
load_source login.tcl
load_source proxy.tcl
load_source userinfo.tcl
load_source datagathering.tcl
load_source $interface mclistbox.tcl
load_source search.tcl
load_source register.tcl
load_source si.tcl
load_source filetransfer.tcl
load_source privacy.tcl
load_source pubsub.tcl
load_source pep.tcl
load_source richtext.tcl

load_source ifacetk iface.tcl

plugins::load [file join plugins general]
plugins::load [file join plugins roster]
plugins::load [file join plugins search]
plugins::load [file join plugins richtext]
plugins::load [file join plugins pep]
plugins::load [file join plugins $tcl_platform(platform)]

if {[info exists env(TKABBER_SITE_PLUGINS)]} {
    plugins::load_dir $env(TKABBER_SITE_PLUGINS)
}

plugins::load_dir [file join $configdir plugins]

hook::run postload_hook

load_source iface.tcl

hook::run finload_hook

# vim:ts=8:sw=4:sts=4:et
