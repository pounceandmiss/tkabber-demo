# hooks.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements the
#       hooks infrastructure.

namespace eval hook {}

proc hook::add {hook func {seq 50}} {
    variable flags
    variable $hook

    lappend $hook [list $func $seq]
    set $hook [lsort -real -index 1 [lsort -unique [set $hook]]]
}

proc hook::remove {hook func {seq ""}} {
    variable $hook

    if {$seq ne ""} {
        set idx [lsearch -exact [set $hook] [list $func $seq]]
        set $hook [lreplace [set $hook] $idx $idx]
    } else {
        foreach idx [lsort -integer -decreasing [lsearch -all -exact -index 0 [set $hook] $func]] {
            set $hook [lreplace [set $hook] $idx $idx]
        }
    }
}

proc hook::is_empty {hook} {
    variable $hook

    if {![info exists $hook] || [llength [set $hook]] == 0} {
        return 1
    } else {
        return 0
    }
}

proc hook::set_flag {hook flag} {
    variable flags

    set idx [lsearch -exact $flags($hook) $flag]
    set flags($hook) [lreplace $flags($hook) $idx $idx]
}

proc hook::unset_flag {hook flag} {
    variable flags

    if {$flag ni $flags($hook)} {
        lappend flags($hook) $flag
    }
}

proc hook::is_flag {hook flag} {
    variable flags

    if {![info exists flags($hook)]} {
        set flags($hook) {}
    }

    expr {$flag ni $flags($hook)}
}

proc hook::run {hook args} {
    variable flags
    variable $hook

    if {![info exists $hook]} {
        return
    }

    set flags($hook) {}

    foreach func_prio [set $hook] {
        set func [lindex $func_prio 0]
        set code [catch { {*}$func {*}$args } state]

        debugmsg hook "$hook: $func -> $state (code $code)"

        switch -- $code {
            0 {
                if {$state eq "stop"} {
                    # return stop
                    break
                }
            }
            3 {
                # return -code break
                break
            }
            1 {
                # return -code error (which would be weird) or just error
                ::bgerror [format "Hook %s failed\nProcedure %s returned code\
                               %s\n%s" $hook $func $code $state]
            }
        }
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
