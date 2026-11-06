# configdir.tcl --
#
#       This file is a part of the Tkabber XMPP client. It provides the
#       necessary heuristics for deducing the location of Tkabber config
#       directory depending on the current platform.

namespace eval config {}

# Deduces the location of the "Application Data" directory
# (in its wide sense) on the current Windows platform.
# See: http://ru.tkabber.jabe.ru/index.php/Config_dir
proc config::appdata_windows {} {
    global env

    if {[info exists env(APPDATA)]} {
        return $env(APPDATA)
    }

    if {![catch {package require registry}]} {
        set key {HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders}
        if {![catch {registry get $key AppData} dir]} {
            return $dir
        }
    }

    return {}
}

# Copies the contents of dir $from under dir $to using bells'n'whistles.
# NOTE that at the time of invocation:
# * $from MUST exist
# * $to MUST NOT exist.
# Returns true if copying succeeded, false otherwise.
proc config::transfer_dir {from to} {
    wm withdraw .
    wm title . [::msgcat::mc "Attention"]
    # Use [message] instead of [Message] wrapper because this script is
    # executed before the Tkabber requires BWidget or know if it uses Ttk
    # instead of Tk.
    pack [message .msg \
                  -aspect 50000 \
                  -text [::msgcat::mc "Please, be patient while Tkabber\
                                       configuration directory is being\
                                       transferred\
                                       to the new location"]] \
         -fill both -expand yes
    #::tk::PlaceWindow .
    wm deiconify .

    set failed [catch {file copy $from $to} err]

    # Use [tk_messageBox] instead of BWidget's [DialogMsg] because the latter
    # is unavailable at the time this procedure is called.
    if {$failed} {
        tk_messageBox .errormsg \
                      -icon error \
                      -title [::msgcat::mc "Error"] \
                      -message [::msgcat::mc "Tkabber configuration directory\
                                              transfer failed with:\n%s\n\
                                              Tkabber will use the old\
                                              directory:\n%s" \
                                             $err $from] \
                      -type ok
    } else {
        set to [file nativename $to]
        tk_messageBox .infomsg \
                      -icon info \
                      -title [::msgcat::mc "Attention"] \
                      -message [::msgcat::mc "Your new Tkabber config\
                                              directory is now:\n%s\nYou\
                                              can delete the old one:\n%s" \
                                             $to $from] \
                      -type ok
    }

    destroy .msg

    expr {!$failed}
}

# Based on the current platform, chooses the location of the Tkabber's
# config dir and sets the "configdir" global variable to its pathname.
# "TKABBER_HOME" env var overrides any guessing.
# NOTE that this proc now tries to copy contents of the "old-style"
# ~/.tkabber config dir to the new location, if needed, to provide
# smooth upgrade for Tkabber users on Windows.
# This behaviour should be lifted eventually in the future.

if {[catch {file home}]} {
    # Tcl 8

    set home ~
} else {
    # Tcl 9-

    set home [file home]
}

if {![info exists env(TKABBER_HOME)]} {
    switch -- $tcl_platform(platform) {
        unix {
            set configdir [file join $home .tkabber]
        }
        windows {
            set dir [config::appdata_windows]
            if {$dir != {}} {
                set configdir [file join $dir Tkabber]
            } else {
            # Fallback default (depends on Tcl's idea about ~):
            set configdir [file join $home .tkabber]
            }
        }
        macintosh {
            set configdir [file join $home Library "Application Support" Tkabber]
        }
    }

    set env(TKABBER_HOME) $configdir
} else {
    set configdir $env(TKABBER_HOME)
}

set configdir [file normalize $configdir]

# This should be lifted in the next release after introduction
# of configdir.
# TODO: what perms does the dest dir of [file copy] receive?
# Since it's only needed for Windows, we don't really care now.
if {![file exists $configdir] && [file isdir [file join $home .tkabber]]} {
    if {![config::transfer_dir [file join $home .tkabber] $configdir]} {
        # Transfer error-case fallback:
        set configdir [file join $home .tkabber]
    }
}

file mkdir $configdir

# vim:ft=tcl:ts=8:sw=4:sts=4:et
