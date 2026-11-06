# spanel.tcl --
#
#       Generic horizontal search panel.

if {$::darktheme} {
    option add *noMatchesBackground HotPink4 widgetDefault
} else {
    option add *noMatchesBackground pink widgetDefault
}

namespace eval search {}

# TODO (?) require searchcmd to return a list:
#      [search_result wrapped_around]
#      and signalize wrap-around condition to the user

#
# Recognized options:
# -searchcommand
# -opencommand
# -closecommand
# -allowclose
# -twoway
# -defaultdirection
#
proc search::spanel {w args} {
    set opencmd   ""
    set closecmd  ""
    set stopcmd   ""
    set canclose  1
    set twoway    1
    set defbutton 0
    set async     0
    foreach {key val} $args {
        switch -- $key {
            -searchcommand {
                set searchcmd $val
            }
            -opencommand {
                set opencmd $val
            }
            -closecommand {
                set closecmd $val
            }
            -allowclose {
                set canclose $val
            }
            -twoway {
                set twoway $val
            }
            -defaultdirection {
                switch -- $val {
                    up   { set defbutton 0 }
                    down { set defbutton 1 }
                    default { error "Invaild default search direcrion: $val" }
                }
            }
            -stopcommand {
                set async 1
                set stopcmd $val
            }
            default { error "invalid option: $key" }
        }
    }

    if {![info exists searchcmd]} {
        error "missing mandatory option: -searchcommand"
    }

    Frame $w

    set sentry [Entry $w.sentry \
                    -validate all \
                    -validatecommand [namespace code {validate_entry %W %P}]]
    pack $sentry -padx 1m -side left

    if {![catch {Widget::theme}] && [Widget::theme]} {
        if {[ttk::style configure notfound.TEntry -fieldbackground] eq ""} {
            set bg [option get $w noMatchesBackground Entry]
            set fg [option get $w errorForeground Entry]
            ttk::style configure notfound.TEntry -fieldbackground $bg
            ttk::style configure invalid.TEntry -foreground $fg
            ttk::style configure invalid.notfound.TEntry -fieldbackground $bg
            ttk::style configure invalid.notfound.TEntry -foreground $fg
        }
        set bg ""
    } else {
        set bg [lindex [$sentry configure -background] 4]
    }

    bind $w <Map> [namespace code [list spanel_open [double% $w] \
                                                    [double% $opencmd]]]

    set sbox [ButtonBox $w.sbox -spacing 0]
    if {$twoway} {
        set lbl [::msgcat::mc "Search up"]
    } else {
        set lbl [::msgcat::mc "Search"]
    }
    $sbox add -text $lbl \
              -command [namespace code [list spanel_search $w $async \
                                             $searchcmd up $bg]]
    if {$twoway} {
        $sbox add -text [::msgcat::mc "Search down"] \
              -command [namespace code [list spanel_search $w $async \
                                             $searchcmd down $bg]]
    }
    pack $sbox -side left -padx 1m

    set xbox [ButtonBox $w.xbox -spacing 0]
    $xbox add -text [::msgcat::mc "Cancel"] \
        -command [namespace code [list spanel_cancel $w $stopcmd]]
    if {$async} {
        bind $sentry <Control-KeyPress-c> [namespace code [list spanel_cancel \
                                                                [double% $w] \
                                                                [double% $stopcmd]]]
        pack $xbox -side left -padx 1m
    }

    set cbox [ButtonBox $w.cbox -spacing 0]
    $cbox add -text [::msgcat::mc "Close"] \
              -command [namespace code [list spanel_close $w $closecmd]]
    if {$canclose} {
        pack $cbox -side right -padx 1m
    }

    bind $sentry <Key-Return> [double% [list $sbox invoke $defbutton]]
    bind $sentry <Key-Return> +break ;# prevent forwarding upstream
    bind $sentry <Shift-Key-Return> [double% [list $sbox invoke [expr {!$defbutton}]]]
    bind $sentry <Shift-Key-Return> +break ;# prevent forwarding upstream

    if {$canclose} {
        bind $sentry <Escape> [double% [list $cbox invoke 0]]
        bind $sentry <Escape> +break ;# prevent forwarding upstream
    }

    spanel_state $w inactive

    set w
}

# In async mode, the result of eval'ing of $searchcmd
# is treated specially:
# * true ("found") means the client code has started the search process;
# * false ("not found") means it refused to search for some reason.
proc search::spanel_search {w async searchcmd dir dbg} {
    set sentry $w.sentry

    spanel_state $w active

    set cmd $searchcmd
    lappend cmd [$sentry get] $dir
    if {$async} {
        lappend cmd -completioncommand [list \
            [namespace current]::spanel_on_completed $w $dbg]
    }

    set failed [catch { {*}$cmd } found]

    if {$failed} {
        spanel_state $w inactive
        return -code error $found
    }

    if {$async && $found} return

    spanel_state $w inactive

    spanel_signalize_result $w $dbg $found
}

proc search::spanel_state {w state} {
    set sentry $w.sentry
    set sbox   $w.sbox
    set xbox   $w.xbox
    set cbox   $w.cbox

    if {[string equal $state active]} {
        set a disabled
        set b normal
    } else {
        set a normal
        set b disabled
    }

    $sentry configure -state $a
    $sbox   configure -state $a
    $xbox   configure -state $b
    $cbox   configure -state $a
}

proc search::spanel_signalize_result {w dbg found} {
    set sentry $w.sentry

    if {![catch {Widget::theme}] && [Widget::theme]} {
        set style TEntry
        if {!$found} {
            set style notfound.$style
        }
        if {![valid_input [$sentry get]]} {
            set style invalid.$style
        }
        $sentry configure -style $style
    } else {
        if {$found} {
            set bg $dbg
        } else {
            set bg [option get $sentry noMatchesBackground Entry]
            if {$bg == ""} {
                set bg $dbg
            }
        }
        $sentry configure -background $bg
    }
    focus $sentry
}

proc search::spanel_open {w opencmd} {
    if {$opencmd ne {}} {
        {*}$opencmd $w
    }
    focus $w.sentry
}

proc search::spanel_close {w closecmd} {
    if {$closecmd ne {}} {
        {*}$closecmd $w
    }
}

proc search::spanel_cancel {w stopcmd} {
    if {$stopcmd ne {}} {
        {*}$stopcmd $w
    }
}

proc search::spanel_on_completed {w dbg found} {
    spanel_state $w inactive
    spanel_signalize_result $w $dbg $found
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
