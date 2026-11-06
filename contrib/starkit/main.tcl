# main.tcl --
#
#       Sample startup file for the Tkabber starkit.
#       See README for details.

# See: http://wiki.tcl.tk/8186
package require starkit
if {[string equal [starkit::startup] sourced]} return

# Linux tclkits don't load Tk themselves:
package require Tk

proc starkit_init {args} {
    global configdir toolkit_version
    variable starkit::topdir

    # Prevent bogus zlib package from confusing Tkabber
    # (stream compression doesn't work in starkits using vanilla Tkabber):
    package forget zlib

    append toolkit_version " (starkit)"

    set spath $configdir
    if {[info exists topdir]} {
        lappend spath [file dirname $topdir]
    }

    # Preserve the value of ::starkit::topdir before loading
    # another starkits, see: http://wiki.tcl.tk/8186
    set top $topdir

    set log ""
    foreach dir $spath {
        foreach kit [glob -type f -dir $dir -nocomplain *.kit] {
            set failed [catch { source $kit } err]
            if {$failed} {
                append log "\nFile: $kit\nError: $err"
            }
        }
    }

    set topdir $top

    if {$log != ""} {
        tk_messageBox -icon error -title "Startup problem" \
                      -message "Failed to load some .kit files:\n$log"
    }
}

source [file join [file dirname [info script]] tkabber tkabber.tcl]

# vim:ft=tcl:ts=8:sw=4:sts=4:et
