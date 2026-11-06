# mousewheel.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       makes widgets receive mousewheel events even in unfocused
#       state. It also converts the mousewheel events into button events
#       which aloows one to bind them identically on all platforms.

namespace eval mousewheel {}

proc mousewheel::convert_to_button {modifier d x y} {
    switch -- $modifier {
        shift {
            set scroll_up <<ScrollLeft>>
            set scroll_down <<ScrollRight>>
        }
        default {
            set scroll_up <<ScrollUp>>
            set scroll_down <<ScrollDown>>
        }
    }
    if {$d < 0} {
        for {set i 0} {$i > $d} {incr i -120} {
            event generate [winfo containing $x $y] $scroll_down
        }
    } else {
        for {set i 0} {$i < $d} {incr i 120} {
            event generate [winfo containing $x $y] $scroll_up
        }
    }
}

bind Text <MouseWheel> " "
bind ListBox <MouseWheel> " "

bind Text <Shift-MouseWheel> " "
bind ListBox <Shift-MouseWheel> " "

bind all <MouseWheel> \
     [list [namespace current]::mousewheel::convert_to_button none %D %X %Y]
bind all <MouseWheel> +break
bind all <Shift-MouseWheel> \
     [list [namespace current]::mousewheel::convert_to_button shift %D %X %Y]
bind all <Shift-MouseWheel> +break

# vim:ft=tcl:ts=8:sw=4:sts=4:et
