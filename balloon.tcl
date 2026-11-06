# balloon.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements
#       floating balloon help windows.

option add *Balloon*background LightYellow widgetDefault
option add *Balloon*foreground Black       widgetDefault
option add *Balloon.style      delay       widgetDefault
option add *Balloon.text.padX  0.5m       widgetDefault
option add *Balloon.text.padY  0.5m       widgetDefault


toplevel .balloon -borderwidth 0 -class Balloon

bind .balloon <Any-Motion> \
         [list balloon::default_balloon .balloon leave %X %Y]

pack [message .balloon.text -text "" \
                            -aspect 5000 \
                            -width 0 \
                            -relief solid \
                            -borderwidth 0.25m]

if {$::tcl_platform(platform) == "macintosh"} {
    catch { unsupported1 style .balloon floating sideTitlebar }
} elseif {$::aquaP} {
    ::tk::unsupported::MacWindowStyle style .balloon help none
} else {
    wm transient .balloon .
}

wm withdraw .balloon

namespace eval balloon {
    variable _id ""
    variable _delay 600
    variable _cur ""
    variable balloon_showed 0
    variable balloon_remove 0

    variable style [option get .balloon style Balloon]
}

proc balloon::set_text {text args} {
    if {[.balloon.text cget -text] eq $text} return

    set width 0
    set aspect 5000
    foreach {opt val} $args {
        switch -- $opt {
            -width { set width $val }
            -aspect { set aspect $val }
        }
    }

    after idle [list .balloon.text configure -text $text \
                                             -aspect $aspect \
                                             -width $width]
}

proc balloon::show {mx my} {
    variable balloon_showed
    variable balloon_remove
    variable max_bx

    if {[.balloon.text cget -text] == ""} {
        balloon::destroy
        return
    }

    set balloon_showed 1
    set balloon_remove 0

    set b_w [winfo reqwidth .balloon]
    set b_h [winfo reqheight .balloon]

    if {$::tcl_platform(platform) == "windows" && \
            ($mx >= [winfo screenwidth .] || $my >= [winfo screenheight .] ||
             $mx < 0 || $my < 0)} {
        set b_x [expr {$mx + 1}]
        set b_y [expr {$my + 1}]
    } else {
        set max_bx [expr {[winfo screenwidth .] - $b_w}]
        set max_by [expr {[winfo screenheight .] - $b_h}]

        set b_x [expr {$mx + [winfo pixels .balloon 3m]}]
        set b_y [expr {$my + [winfo pixels .balloon 4m]}]

        set b_x [::tcl::mathfunc::max [::tcl::mathfunc::min $b_x $max_bx] 0]
        set b_y [::tcl::mathfunc::max [::tcl::mathfunc::min $b_y $max_by] 0]

        if {($mx >= $b_x) && ($mx <= $b_x+$b_w)} {
            if {($my >= $b_y) && ($my <= $b_y+$b_h)} {
                set b_y1 [expr {$my - 5 - $b_h}]
                if {$b_y1 >= 0} {
                    set b_y $b_y1
                }
            }
            set max_bx [::tcl::mathfunc::max $max_bx $b_h]
            if {$b_x < $max_bx && $b_x <= $mx + [winfo pixels .balloon 3m] && $b_w <= $max_bx} {
                set b_x [expr {$mx + [winfo pixels .balloon 3m]}]
            }
        }
    }

    wm overrideredirect .balloon 1
    wm geometry .balloon +$b_x+$b_y
    wm deiconify .balloon

    # need the raise in case we're ballooning over a detached menu (emoticons)
    raise .balloon
}

proc balloon::set_delay {w mx my} {
    global tcl_platform
    variable balloon_showed
    variable balloon_remove
    variable _id
    variable _delay
    variable _cur

    if {$_cur != $w} {
        if {$_id != ""} {
            after cancel $_id
        }
        set _id [after $_delay "balloon::show $mx $my"]
        set _cur $w
        wm withdraw .balloon
        if {$tcl_platform(platform) == "unix"} {
            wm overrideredirect .balloon 0
        }
        set balloon_showed 0
        set balloon_remove 0
    } else {
        set balloon_remove 0
        if {$balloon_showed == 0} {
            if {$_id != ""} {
                after cancel $_id
            }
            set _id [after $_delay "balloon::show $mx $my"]
        }
    }
}

proc balloon::on_mouse_move {w mx my} {
    variable style

    switch -- $style {
        delay  {set_delay $w $mx $my}
        follow {show $mx $my}
    }
}

proc balloon::destroy {} {
    global tcl_platform
    variable balloon_showed
    variable balloon_remove
    variable _id

    if {$_id != ""} {
        after cancel $_id
        set _id ""
    }

    set balloon_remove 1
    after 100 {
        if {$::balloon::balloon_remove} {
            wm withdraw .balloon
            if {$::tcl_platform(platform) == "unix"} {
                wm overrideredirect .balloon 0
            }
            set ::balloon::balloon_showed 0
            set ::balloon::balloon_remove 0
        }
    }
}

proc balloon::default_balloon {w action X Y args} {
    set sw $w
    set text ""
    set command ""
    set newargs $args
    # $args may contain odd number of members, so a bit unusual parsing
    set idx 0
    foreach {opt val} $args {
        switch -- $opt {
            -text {
                set text $val
                set newargs [lreplace $newargs $idx [expr {$idx + 1}]]
            }
            -command {
                set command $val
                set newargs [lreplace $newargs $idx [expr {$idx + 1}]]
            }
            default {
                incr idx 2
            }
        }
    }

    if {$command != ""} {
        set newargs [lassign [{*}$command {*}$newargs] sw text]
    }

    switch -- $action {
        enter {
            balloon::set_text $text {*}$newargs
        }

        motion {
            balloon::set_text $text {*}$newargs
            balloon::on_mouse_move $sw $X $Y
        }

        leave {
            balloon::destroy
        }
    }
}

proc balloon::setup {w args} {
    # Try to bind in Tree widget
    if {![catch {
              $w bindText <Any-Enter> \
                   [list [namespace current]::default_balloon %W enter %X %Y \
                         {*}[double% $args]]
         }]} {
        $w bindText <Any-Motion> \
             [list [namespace current]::default_balloon %W motion %X %Y \
                   {*}[double% $args]]
        $w bindText <Any-Leave> \
             [list balloon::default_balloon %W leave %X %Y]
    } else {
        bind $w <Any-Enter> \
             [list [namespace current]::default_balloon %W enter %X %Y \
                   {*}[double% $args]]
        bind $w <Any-Motion> \
             [list [namespace current]::default_balloon %W motion %X %Y \
                   {*}[double% $args]]
        bind $w <Any-Leave> \
             [list balloon::default_balloon %W leave %X %Y]
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
