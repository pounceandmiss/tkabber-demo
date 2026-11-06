# tls 2.0.1, linked statically into libmain.so (registered by tlsinit.c).
package ifneeded tls 2.0.1 [list apply {{dir} {
    load {} Tls
    source -encoding utf-8 [file join $dir tls.tcl]
    source -encoding utf-8 [file join $dir android.tcl]
}} $dir]
