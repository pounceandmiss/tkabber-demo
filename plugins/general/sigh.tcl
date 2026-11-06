# sigh.tcl --
#
#       An April 1st joke plugin which makes Tkabber sigh.
#
# Written by Ruslan Rakhmanin <rakhmaninr@gmail.com>
# Sound and testing by Serge Yudin xmpp:bigote@jabber.ru

return

namespace eval sigh {
    # Maximum number of animation steps
    variable steps_num 20
    # Step duration in mc
    variable step_duration 100
    variable testing 0
}

proc sigh::setup {} {
    set ::sound::options(sigh_sound) [fullpath sounds default sigh.wav]
    ::sound::load_sound_file sigh
    after 1000 [namespace current]::is_sigh
}

hook::add finload_hook [namespace current]::sigh::setup

proc sigh::is_sigh {} {
    variable testing
    # Every 15 seconds try random number
    after 300000 [namespace current]::is_sigh
    set seconds [clock seconds]
    if {$testing || [clock format $seconds -format %m/%d] == "04/01"} {
        # Probability of sigh is 5% at every 5 minutes
        if {$testing || rand() < 0.05} {
            regexp -- {([0-9]+)x([0-9]+)\+?([0-9-]+)\+?([0-9-]+)} \
                    [wm geometry .] -> x y kx ky
            ::sound::play $::sound::sounds(sigh)
            [namespace current]::make_step 1 $x $y $kx $ky
        }
    }
}


proc sigh::make_step {step x y kx ky} {
    variable step_duration
    variable steps_num
    # Geometry of window could be changed maximum in 5%
    set dif_w [expr {($x / 100 * 5) * sin(3.1415926 / $steps_num * $step)} ]
    set dif_h [expr {($y / 100 * 5) * sin(3.1415926 / $steps_num * $step)} ]

    set newgeometry [expr round($dif_w + $x)]x[expr round($dif_h + $y)]

    if {$kx >= 0} {
        set sx [expr round(-$dif_w/2 + $kx)]
        if {$sx < 0} {
            set sx 0
        }
        append newgeometry +$sx
    } else {
        set sx [expr round(-$dif_w/2 - $kx)]
        if {$sx < 0} {
            set sx 0
        }
        append newgeometry -$sx
    }
    if {$ky >= 0} {
        set sy [expr round(-$dif_h/2 + $ky)]
        if {$sy < 0} {
            set sy 0
        }
        append newgeometry +$sy
    } else {
        set sy [expr round(-$dif_h/2 - $ky)]
        if {$sy < 0} {
            set sy 0
        }
        append newgeometry -$sy
    }
    wm geometry . $newgeometry
    if {$step == 0} {
        return
    }
    incr step
    if {$step <= $steps_num} {
        after $step_duration [namespace current]::make_step $step $x $y $kx $ky
    } else {
        after $step_duration [namespace current]::make_step 0 $x $y $kx $ky
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
