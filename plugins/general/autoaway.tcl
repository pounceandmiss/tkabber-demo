# autoaway.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugind which
#       switches Tkabber status to away or xa after a specified period of
#       inactivity.

namespace eval autoaway {
    variable idletime

    if {[catch {tk inactive} idletime] || $idletime < 0} {
        return
    }

    custom::defgroup AutoAway \
        [::msgcat::mc "Options for module that automatically marks\
                       you as away after idle threshold."] \
        -group Tkabber

    custom::defvar options(awaytime) 5 \
        [::msgcat::mc "Idle threshold in minutes after that\
                       Tkabber marks you as away."] \
        -group AutoAway -type integer

    custom::defvar options(xatime) 15 \
        [::msgcat::mc "Idle threshold in minutes after that\
                       Tkabber marks you as extended away."] \
        -group AutoAway -type integer

    custom::defvar options(status) \
        [::msgcat::mc "Automatically away due to idle"] \
        [::msgcat::mc "Text status, which is set when\
                       Tkabber is moving to away state."] \
        -group AutoAway -type string

    custom::defvar options(drop_priority) 1 \
        [::msgcat::mc "Set priority to 0 when moving to extended away state."] \
        -group AutoAway -type boolean

    custom::defvar savepriority 0 [::msgcat::mc "Stored user priority while she's away."] \
        -type integer -group Hidden

    custom::defvar savestatus "" [::msgcat::mc "Stored user status while she's away."] \
        -type string -group Hidden

    custom::defvar savetext "" [::msgcat::mc "Stored user text status while she's away."] \
        -type string -group Hidden

    hook::add finload_hook [namespace current]::after_idle
    hook::add quit_hook    [namespace current]::after_idle_cancel 10
}


proc autoaway::after_idle {args} {
    after_idle_cancel
    after_idle_aux
    if {$::aquaP} {
        set msec 1000
    } else {
        set msec 250
    }
    after $msec [namespace current]::after_idle
}

proc autoaway::after_idle_cancel {args} {
    variable options
    variable savestatus
    variable savetext
    variable savepriority
    global userstatus textstatus userpriority

    if {[connections] == {}} {
        if {$savestatus ne ""} {
            if {$options(drop_priority) && $userpriority >= 0} {
                set userpriority $savepriority
            }
            set savepriority 0
            set textstatus $savetext
            set savetext ""
            set userstatus $savestatus
            set savestatus ""
        }

        after cancel [namespace current]::after_idle
    }
}

proc autoaway::after_idle_aux {} {
    variable options
    variable savestatus
    variable savetext
    variable savepriority
    global userstatus textstatus userpriority

    if {$options(awaytime) <= 0 && $options(xatime) <= 0} {
        return
    }

    if {[catch {tk inactive} idletime] || $idletime < 0} {
        return
    }

    if {$idletime < $options(awaytime)*60*1000} {
        if {$savestatus ne ""} {
            if {$options(drop_priority) && $userpriority >= 0} {
                set userpriority $savepriority
            }
            set savepriority 0
            set textstatus $savetext
            set savetext ""
            set userstatus $savestatus
            set savestatus ""
            set_status [::msgcat::mc "Returning from auto-away"]
        }

        return
    }

    switch -- $userstatus {
        available -
        chat {
            set savestatus $userstatus
            set savetext $textstatus
            set savepriority $userpriority
            if {$options(status) ne ""} {
               set textstatus $options(status)
            }
            if {$idletime >= $options(xatime)*60*1000} {
                if {$options(drop_priority) && $userpriority >= 0} {
                    set userpriority 0
                }
                set userstatus xa
                set_status [::msgcat::mc "Moving to extended away"]
            } else {
                set userstatus away
                set_status [::msgcat::mc "Starting auto-away"]
            }
            return
        }

        away {
            if {$savestatus ne "" && $idletime >= $options(xatime)*60*1000} {
                set savepriority $userpriority
                if {$options(status) ne ""} {
                    set textstatus $options(status)
                }
                if {$options(drop_priority) && $userpriority >= 0} {
                    set userpriority 0
                }
                set userstatus xa
                set_status [::msgcat::mc "Moving to extended away"]
                return
            }
        }

        default {
        }
    }

    if {$savestatus ne ""} {
        set_status [::msgcat::mc "Idle for %s" [format_time [expr {$idletime/1000}]]]
    }
}

proc autoaway::set_status {status} {
    if {[llength [connections]] > 0} {
        ::set_status $status
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
