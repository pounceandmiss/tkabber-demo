# splash.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements
#       Tkabebr splash window which is shown while Tkabber starts.

# BWidget's Button overrides this option, so set its priority to
# 30 instead of widgetDefault (20)
option add *ErrorDialog.function.text [::msgcat::mc "Save To Log"] 30

# Wrapper around bgerror which hides splash window. It's useful when
# error window is small
auto_load bgerror
rename bgerror bgerror_default
proc bgerror {msg} {
    if {[winfo exists .bgerrorDialog]} {
        # If there's another error message around then don't report the
        # next error (questionnable).
        return
    }
    if {[winfo exists .splash]} {
        wm withdraw .splash
    }
    bgerror_default $msg
    if {[winfo exists .splash]} {
        wm deiconify .splash
        update
    }
}

if {[catch {package require tksvg}]} {
    create_image tkabber/logo1 \
                 -file [fullpath pixmaps default tkabber tkabber-logo.gif]
} else {
    create_image tkabber/logo1 \
                 -file [fullpath pixmaps default tkabber tkabber-logo.svg] \
                 -scale 1 \
                 -format [list svg -dpi [expr {[tk scaling]*72}]]
}

if {[info exists show_splash_window] && !$show_splash_window} {
    return
}

proc splash_start {} {
    global splash_count splash_image splash_info splash_max splash_text
    global tkabber_version toolkit_version

    set splash_info   ""
    set splash_count   0
    set splash_max   250

    array set splash_text [list                                    \
        custom               [::msgcat::mc "customization"]        \
        utils                [::msgcat::mc "utilities"]            \
        plugins              [::msgcat::mc "plugin management"]    \
        pixmaps              [::msgcat::mc "pixmaps management"]   \
        balloon              [::msgcat::mc "balloon help"]         \
        presence             [::msgcat::mc "xmpp presence"]        \
        iq                   [::msgcat::mc "xmpp iq"]              \
        plugins:iq           [::msgcat::mc "xmpp iq"]              \
        roster               [::msgcat::mc "xmpp roster"]          \
        itemedit             [::msgcat::mc "xmpp roster"]          \
        messages             [::msgcat::mc "xmpp messages"]        \
        chats                [::msgcat::mc "xmpp chat/muc"]        \
        plugins:chat         [::msgcat::mc "xmpp chat/muc"]        \
        joingrdialog         [::msgcat::mc "xmpp chat/muc"]        \
        muc                  [::msgcat::mc "xmpp chat/muc"]        \
        emoticons            [::msgcat::mc "emoticons"]            \
        aniemoticons         [::msgcat::mc "emoticons"]            \
        login                [::msgcat::mc "connections"]          \
        proxy                [::msgcat::mc "connections"]          \
        browser              [::msgcat::mc "browsing"]             \
        disco                [::msgcat::mc "service discovery"]    \
        userinfo             [::msgcat::mc "presence"]             \
        datagathering        [::msgcat::mc "utilities"]            \
        negotiate            [::msgcat::mc "negotiation"]          \
        search               [::msgcat::mc "searching"]            \
        register             [::msgcat::mc "xmpp registration"]    \
        si                   [::msgcat::mc "file transfer"]        \
        plugins:si           [::msgcat::mc "file transfer"]        \
        filetransfer         [::msgcat::mc "file transfer"]        \
        plugins:filetransfer [::msgcat::mc "file transfer"]        \
        privacy              [::msgcat::mc "privacy rules"]        \
        gpgme                [::msgcat::mc "cryptographics"]       \
        ifacetk              [::msgcat::mc "user interface"]       \
        plugins:general      [::msgcat::mc "general plugins"]      \
        plugins:roster       [::msgcat::mc "roster plugins"]       \
        plugins:search       [::msgcat::mc "search plugins"]       \
        plugins:unix         [::msgcat::mc "unix plugins"]         \
        plugins:windows      [::msgcat::mc "windows plugins"]      \
        plugins:macintosh    [::msgcat::mc "macintosh plugins"]    \
        iface                [::msgcat::mc "user interface"]       \
        autoaway             [::msgcat::mc "auto-away"]            \
        avatars              [::msgcat::mc "avatars"]              \
        bwidget_workarounds  [::msgcat::mc "bwidget workarounds"]  \
        config               [::msgcat::mc "configuration"]        \
        dockingtray          [::msgcat::mc "kde"]                  \
        hooks                [::msgcat::mc "extension management"] \
        tclxmpp              [::msgcat::mc "xmpp library"]         \
        plugins              [::msgcat::mc "plugin management"]    \
        sound                [::msgcat::mc "sound"]                \
        wmdock               [::msgcat::mc "wmaker"]               \
    ]

    wm withdraw .

    set w [toplevel .splash]

    wm withdraw $w
    wm overrideredirect $w 1

    catch {
        if {"-topmost" in [wm attributes $w]} {
            wm attributes $w -topmost 1
        }
    }
    catch {
        if {"-alpha" in [wm attributes $w]} {
            wm attributes $w -alpha 0.7
        }
    }

    Frame $w.frame
    Frame $w.frame.spacer -width 4m

    Label $w.frame.image -image tkabber/logo1

    Label $w.frame.msg   \
          -anchor  nw    \
          -justify left  \
          -text          \
"Tkabber $tkabber_version ($toolkit_version)

Copyright \u00a9 2002-2025 [::msgcat::mc {Alexey Shchepin}]

[::msgcat::mc Authors:]
    [::msgcat::mc {Alexey Shchepin}]
    [::msgcat::mc {Marshall T. Rose}]
    [::msgcat::mc {Sergei Golovan}]
    [::msgcat::mc {Michail Litvak}]
    [::msgcat::mc {Konstantin Khomoutov}]

https://tkabber.jabber.ru/"

    grid $w.frame.spacer -row 0 -column 0 -sticky e -pady 4m
    grid $w.frame.image -row 0 -column 1 -sticky e -pady 4m
    grid $w.frame.msg   -row 0 -column 2 -sticky w -padx 4m -pady 4m

    Progressbar $w.frame.bar     \
            -variable   splash_count \
            -maximum    $splash_max
    Label $w.frame.info -textvariable splash_info

    grid $w.frame.bar  -row 2 -column 0 -sticky sew -columnspan 3 -padx 1m
    grid $w.frame.info -row 3 -column 0 -sticky s -columnspan 3

    pack $w.frame -anchor nw

    if {[info commands splash_source] eq ""} {
        rename source splash_source
        rename splash_progress source
    }

    BWidget::place $w 0 0 center
    wm deiconify $w
}

proc splash_progress {args} {
    global rootdir splash_count splash_max splash_info splash_text

    if {([winfo exists .splash]) && ([llength $args] == 1)} {
        set lrootdir [string tolower $rootdir]
        set filepath [string tolower [lindex $args 0]]
        set homedir [string tolower $::configdir]
        if {[catch { set globhomedir [file normalize $homedir] }]} {
            set plugins [lindex [glob -nocomplain \
                                      [file join $homedir plugins]] 0]
            set globhomedir \
                [file join [lrange [file split $plugins] 0 end-1]]
        }
        set globhomedir [string tolower $globhomedir]
        if {[string first $lrootdir $filepath] == 0} {
            set log 1
            set root $lrootdir
        } elseif {[string first $homedir $filepath] == 0} {
            set log 1
            set root $homedir
        } elseif {$globhomedir ne "" &&
                        [string first $globhomedir $filepath] == 0} {
            set log 1
            set root $globhomedir
        } else {
            set log 0
        }
        if {$log} {
            set srelpath [lrange [file split $filepath] \
                                 [llength [file split $root]] end]
            if {[llength $srelpath] > 1} {
                set name [join [lrange $srelpath 0 end-1] :]
            } else {
                set name [file rootname [lindex $srelpath 0]]
            }
            if {![string equal -nocase \
                         [lindex $srelpath end] "pkgIndex.tcl"]} {
                if {[info exists splash_text($name)]} {
                    set splash_info $splash_text($name)
                } else {
                    # Process plugins separately
                    set nlist [split $name :]
                    if {[lindex $nlist 0] == "plugins"} {
                        set splash_info \
                            [::msgcat::mc "%s plugin" \
                                          [join [lrange $nlist 1 end] :]]
                    }
                }
                incr splash_count
                if {$name eq "iface"} {
                    set splash_count $splash_max
                }
                update
            }
        }
    }

    uplevel 1 splash_source $args
}

proc splash_done {} {
    global splash_count splash_max

    if {![winfo exists .splash]} {
        return
    }
    set splash_count $splash_max
    update
    after 100
    destroy .splash

    rename source splash_progress
    rename splash_source source
}

hook::add finload_hook splash_done 99

splash_start

# vim:ft=tcl:ts=8:sw=4:sts=4:et
