# comm.tcl --
#
#       Remote control via comm module.

package require comm

namespace eval comm {
    # Cleanup stale comm files

    variable filename
    variable fd
    variable id
    variable cookie

    foreach filename [glob -nocomplain -directory $::configdir comm.*] {
        set fd [open $filename]
        lassign [read $fd] id cookie
        close $fd

        if {[catch {::comm::comm send -async \
                            $id ::plugins::comm::eval_command list-commands}]} {
            file delete -force -- $filename
        }
    }

    set cookie [rand 1000000000][rand 1000000000][rand 1000000000]

    variable cookieFile [file join $::configdir comm.[pid]]

    file delete -force -- $cookieFile
    set fd [open $cookieFile w]
    puts $fd [list [::comm::comm self] $cookie]
    close $fd
    unset fd
    catch {file attributes $cookieFile -permissions 0600}

    hook::add quit_hook [namespace current]::cleanup 1

    ::comm::comm hook incoming "[namespace current]::checkpass \$fid"

    rename ::comm::commIncoming ::comm::commIncoming:orig

    proc ::comm::commIncoming {args} {
        if {![catch { ::comm::commIncoming:orig {*}$args } res]} {
            return $res
        } else {
            return
        }
    }
}

proc comm::cleanup {} {
    variable cookieFile

    file delete -force -- $cookieFile
}

proc comm::checkpass {fid} {
    variable wait
    variable cookie

    set blocking [fconfigure $fid -blocking]
    fconfigure $fid -blocking 0
    fileevent $fid readable [namespace code [list getpass $fid]]

    after 2000 [list set [namespace current]::wait($fid) ""]

    vwait [namespace current]::wait($fid)
    set ans $wait($fid)
    unset wait($fid)

    fconfigure $fid -blocking $blocking

    if {$ans != $cookie} {
        return -code error "Incorrect cookie"
    }
}

proc comm::getpass {fid} {
    variable wait

    if {[gets $fid line] >= 0} {
        set wait($fid) $line
    }
}

proc comm::eval_script {script} {
    set status [catch {eval {uplevel #0} $script} res]

    return [list $status $res]
}

proc comm::register_command {command proc arguments} {
    variable commands

    set commands($command) [list $proc $arguments]
}

proc comm::unregister_command {command} {
    variable commands

    catch {unset commands($command)}
}

proc comm::eval_command {arglist} {
    variable commands

    set arglist [lassign $arglist command]
    if {![info exists commands($command)]} {
        return [list 1 [format "Command %s not found" $command]]
    } else {
        set status [catch {uplevel #0 [lindex $commands($command) 0] $arglist} res]
        return [list $status $res]
    }
}

proc comm::list_commands {} {
    variable commands

    set res {}
    foreach command [lsort -dictionary [array names commands]] {
        lappend res "$command [lindex $commands($command) 1]"
    }

    return [join $res \n]
}

comm::register_command list-commands [namespace current]::comm::list_commands ""

proc comm::set_status {status {text \u0000}} {
    global userstatus
    global textstatus

    if {$text != "\u0000"} {
        set textstatus $text
    }

    set userstatus $status
}

comm::register_command set-status [namespace current]::comm::set_status "status ?textstatus?"

# vim:ft=tcl:ts=8:sw=4:sts=4:et
