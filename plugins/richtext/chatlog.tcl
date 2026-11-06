# chatlog.tcl --
#
#       This is a (pretty much eclectic) framework to support various highlights
#       in chat messages. It registers a rich text entity "chatlog" and provides
#       for configuring a text widget to be ready to display highlights.
#       On the other hand, detection of such highlights is done elsewhere -- in the
#       already existing bits of code (that is, handling /me messages, server messages,
#       MUC subjects, etc). There are plans to eventually move such code to
#       this "chatlog" plugin.
#
#       NOTE that "real" configurable chat highlights are handled by the
#       highlights.tcl rich text plugin.

namespace eval chatlog {}

# This proc provides for reconfiguration of the chatlog tags.
# It is intended to be used for post-configuration of the rich text
# widgets when creating them to server as chat log windows,
# since chatlog windows allow the customization of these parameters
# via the Tk option database.
proc chatlog::config {w args} {
    foreach {opt val} $args {
        switch -- $opt {
            -theyforeground {
                $w tag configure they -foreground $val
            }
            -meforeground {
                $w tag configure me -foreground $val
            }
            -serverlabelforeground {
                $w tag configure server_lab -foreground $val
            }
            -serverforeground {
                $w tag configure server -foreground $val
            }
            -infoforeground {
                $w tag configure info -foreground $val
            }
            -errforeground {
                $w tag configure err -foreground $val
            }
            -highlightforeground {
                $w tag configure highlight -foreground $val
            }
            default {
                return -code error "[namespace current]::config:\
                                    Unknown option: $opt"
            }
        }
    }
}

proc chatlog::configure_richtext_widget {w} {
    # TODO do we need to provide some defaults?

    $w tag configure they
    $w tag configure me
    $w tag configure server_lab
    $w tag configure server
    $w tag configure info
    $w tag configure err
}

namespace eval chatlog {
    ::richtext::register_entity chatlog \
        -configurator [namespace current]::configure_richtext_widget

    ::richtext::entity_state chatlog 1
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
