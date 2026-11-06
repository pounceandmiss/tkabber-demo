# plugins.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements routines
#       which load internal (located inside Tkabber's root directory) or load
#       and unload external plugins (files like dir/plugin/plugin.tcl).

namespace eval plugins {}

proc plugins::load {dir args} {
    set dir [fullpath $dir]
    set uplev 0
    foreach {attr val} $args {
        switch -- $attr {
            -uplevel {set uplev $val}
        }
    }

    foreach file [lsort [glob -nocomplain $dir/*.tcl]] {
        debugmsg plugins "Loading plugin from $file"
        if {$uplev} {
            uplevel [list source $file]
        } else {
            source $file
        }
    }
}

proc plugins::load_dir {plugins_dir} {
    foreach dir [lsort [glob -nocomplain -type {d l} \
                             [file join $plugins_dir *]]] {
        set file [file join $dir [file tail $dir].tcl]
        if {[file exists $file]} {
            debugmsg plugins "Loading plugin from $file"
            source $file
        } else {
            debugmsg plugins "Can't load plugin from directory $dir"
        }
    }
}

proc plugins::is_registered {name} {
    variable loaded

    if {[info exists loaded($name)]} {
        return 1
    } else {
        return 0
    }
}

proc plugins::register {name args} {
    foreach {key val} $args {
        switch -- $key {
            -namespace -
            -source -
            -description -
            -loadcommand -
            -unloadcommand {
                set opts($key) $val
            }
            default {
                return -code error [::msgcat::mc "Invalid option \"%s\"" $key]
            }
        }
    }

    foreach key {-namespace -source -description -loadcommand -unloadcommand} {
        if {![info exists opts($key)]} {
            return -code error [::msgcat::mc "Missing option \"%s\"" $key]
        }
    }

    custom::defgroup {Plugins Management} \
                     [::msgcat::mc "Loading and unloading external plugins."] \
                     -group Tkabber

    custom::defvar loaded($name) 0 $opts(-description) \
                   -type boolean \
                   -group {Plugins Management} \
                   -command [namespace code [list load_or_unload \
                                                        $name \
                                                        $opts(-namespace) \
                                                        $opts(-source) \
                                                        $opts(-loadcommand) \
                                                        $opts(-unloadcommand)]]
}

proc plugins::load_or_unload {name ns source loadcmd unloadcmd args} {
    variable loaded

    # Checking if a plugin is loaded by querying a list of commands in
    # a corresponding namespace.

    set commands [info commands ${ns}::*]

    if {$loaded($name)} {
        if {[llength $commands] == 0} {
            # Plugin isn't loaded, so loading it

            debugmsg plugins "Loading external plugin $name"

            source $source
            {*}$loadcmd
        } else {
            debugmsg plugins "External plugin $name is already loaded"
        }
    } else {
        if {[llength $commands] > 0} {
            # Plugin is loaded, so unloading it

            debugmsg plugins "Unoading external plugin $name"

            {*}$unloadcmd
            foreach cmd $commands {
                rename $cmd ""
            }
        } else {
            debugmsg plugins "External plugin $name is already unloaded"
        }
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
