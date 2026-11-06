#!/bin/sh
# the next line restarts using the correct interpreter \
exec tclsh "$0" "$@"

# tkabber-remote.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a runnable
#       script which executes commands at remote Tkabber instances.
#       It utilizes the plugins/general/comm plugin at the remote side.

package require cmdline
package require comm

set options {
    {user.arg   ""  "Control Tkabber run by a specified user,\
                     default is the current user"}
    {pid.arg    0   "Control Tkabber with a specified pid,\
                     default is all PIDs"}
    {eval.secret    "Evaluate arguments as a script"}
    {command.secret "Evaluate arguments as a command"}
}

set usage ":\ntkabber-remote ?options? -eval script\
...\ntkabber-remote ?options? -command command ?arg?\
...\noptions:"

if {[catch {
        array set params [::cmdline::getoptions argv $options $usage]
     } msg]} {
    puts stderr $msg
    exit 1
}

switch -- [llength $argv] {
    0 {
        puts stderr [::cmdline::usage $options $usage]
        puts stderr "example:\n tkabber-remote -command list-commands"
        exit 1
    }
    default {}
}

if {$params(eval) + $params(command) != 1} {
    puts stderr [::cmdline::usage $options $usage]
    exit 1
}

if {[info exists env(TKABBER_HOME)]} {
    set configdir $env(TKABBER_HOME)
} else {
    # TODO: make this work for non-UNIX platform
    if {[catch {file home}]} {
        set configdir [file join ~$params(user) .tkabber]
    } else {
        set configdir [file join [file tildeexpand ~$params(user)] .tkabber]
    }
}

if {$params(pid) != 0} {
    set files [list [file join $configdir comm.$params(pid)]]
} else {
    set files [glob -nocomplain -directory $configdir comm.*]
}

::comm::comm hook connected {
    global cookie

    puts $fid $cookie
}

set status 0
foreach file $files {
    set fd [open $file]
    set id_cookie [read $fd]
    close $fd

    set id [lindex $id_cookie 0]
    set cookie [lindex $id_cookie 1]

    if {$params(eval)} {
        set command ::plugins::comm::eval_script
    } else {
        set command ::plugins::comm::eval_command
    }

    set s [catch {::comm::comm send $id $command [list $argv]} res]
    if {$s != 0} {
        set res [list $s $res]
    }

    set status1 [lindex $res 0]
    if {$status1 > $status} {
        set status $status1
    }
    puts "PID [string range [file extension $file] 1 end]"
    puts [lindex $res 1]
}

exit $status

# vim:ts=8:sw=4:sts=4:et
