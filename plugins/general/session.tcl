# session.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which implements saving and opening Tkabber sessions infrastructure.
#       Every pluging which wants to save it's state on exit and restore it
#       on Tkabber start can add a procedure to the save_session_hook hook.
#
#       Session is a list of {priority user server resource script}

namespace eval session {
    variable session_file [file join $::configdir session.tcl]

    custom::defgroup State [::msgcat::mc "Tkabber save state options."] \
        -group Tkabber
    custom::defvar options(save_on_exit) 1 \
        [::msgcat::mc "Save state on Tkabber exit."] \
        -type boolean -group State
    custom::defvar options(open_on_start) 1 \
        [::msgcat::mc "Load state on Tkabber start."] \
        -type boolean -group State
}

#############################################################################

proc session::save_session {} {
    variable session_file

    set session {}
    hook::run save_session_hook session

    set fd [open $session_file w]
    fconfigure $fd -encoding utf-8
    puts $fd $session
    close $fd
}

#############################################################################

proc session::save_session_on_exit {} {
    variable options

    if {$options(save_on_exit)} {
        save_session
    }
}

hook::add quit_hook [namespace current]::session::save_session_on_exit

#############################################################################

proc session::open_session {} {
    variable session_file

    set session_script_list {}
    catch {
        set fd [open $session_file r]
        fconfigure $fd -encoding utf-8
        set session_script_list [read $fd]
        close $fd
    }

    foreach script [lsort -integer -index 0 $session_script_list] {
        lassign $script priority user server resource command

        set jid [::xmpp::jid::jid $user $server $resource]

        if {($user != "") || ($server != "") || ($resource != "")} {
            # HACK. It works if called before any JID is connected
            set xlib [create_xlib $jid]
        } else {
            set xlib ""
        }

        after idle [linsert $command end $xlib $jid]
    }
}

#############################################################################

proc session::open_session_on_start {} {
    variable options

    if {$options(open_on_start)} {
        open_session
    }
}

hook::add finload_hook [namespace current]::session::open_session_on_start 90

#############################################################################

proc session::setup_menu {} {
    catch {
        set m [.mainframe getmenu tkabber]
        set ind [expr {[$m index [::msgcat::mc "Chats"]] + 1}]

        set mm .session_menu
        menu $mm -tearoff $::ifacetk::options(show_tearoffs)
        $mm add command -label [::msgcat::mc "Save state"] \
            -command [namespace current]::save_session
        $mm add checkbutton -label [::msgcat::mc "Save state on exit"] \
            -variable [namespace current]::options(save_on_exit)
        $mm add checkbutton -label [::msgcat::mc "Load state on start"] \
            -variable [namespace current]::options(open_on_start)

        $m insert $ind cascade -label [::msgcat::mc "State"] -menu $mm
    }
}

hook::add finload_hook [namespace current]::session::setup_menu 60

# vim:ft=tcl:ts=8:sw=4:sts=4:et
