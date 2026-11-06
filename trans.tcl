# trans.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements message
#       translations in a way similar to the msgcat package, but these
#       messages are intended to be sent to the other XMPP users, so we have
#       have to load them for all languages simultaneously.

namespace eval ::trans {
    variable trans
    array set trans {}
}

# Load message file. It must be in UTF-8 encoding.
proc ::trans::loadfile {filepath} {
    set fd [open $filepath "r"]
    fconfigure $fd -encoding utf-8
    uplevel #0 [read $fd]
    close $fd
}

# Load all message files in the directory.
proc ::trans::load {dirpath} {
    foreach filepath [glob -nocomplain -directory $dirpath *.msg] {
        loadfile $filepath
    }
}

# Set translated message.
proc ::trans::trset {lang msgfrom {msgto ""}} {
    variable trans

    if {$msgto != ""} {
        set trans($lang,$msgfrom) $msgto
    }
}

# ::trans::trans lang msg
# ::trans::trans msg
# Translate message 'msg' to language 'lang'. If there is only one
# argument (no lang), then return unchanged message.
proc ::trans::trans {args} {
    switch -- [llength $args] {
        0 {
            return -code error "::trans::trans: Too few arguments"
        }
        1 {
            # Dummy call for searching translations in the source.
            return [lindex $args 0]
        }
        2 {
            lassign $args lang msg
            variable trans

            set langlist [split [string tolower $lang] -]
            set shortlang [lindex $langlist 0]
            set longlang [join $langlist _]

            if {[info exists trans($longlang,$msg)]} {
                return $trans($longlang,$msg)
            } elseif {[info exists trans($shortlang,$msg)]} {
                return $trans($shortlang,$msg)
            } else {
                return $msg
            }
        }
        default {
            return -code error "::trans::trans: Too many arguments"
        }
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
