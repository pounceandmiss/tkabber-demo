#  buttonbar.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements multirow
#       tabs (by placing buttons on a grid) on top of BWidget infrastructure.

# ----------------------------------------------------------------------------
#  Index of commands:
#     - ButtonBar::create
#     - ButtonBar::configure
#     - ButtonBar::cget
#     - ButtonBar::insert
#     - ButtonBar::delete
#     - ButtonBar::move
#     - ButtonBar::itemconfigure
#     - ButtonBar::itemcget
#     - ButtonBar::setfocus
#     - ButtonBar::index
# ----------------------------------------------------------------------------

namespace eval ButtonBar {
    Widget::define ButtonBar ButtonBar Button

    variable declare {
        {-orient      Enum       horizontal 0 {horizontal vertical}}
        {-minwidth    Int        0          0 "%d >= 0"}
        {-maxwidth    Int        200        0 "%d >= 0"}
        {-padx        TkResource ""         0 button}
        {-pady        TkResource ""         0 button}
        {-command     String     ""         0}
        {-pages       String     ""         0}
    }
    if {[catch {Widget::theme}] || ![Widget::theme]} {
        lappend declare \
                {-background  TkResource ""         0 frame} \
                {-bg          Synonym    -background}
    }

    Widget::declare ButtonBar $declare

    Widget::addmap ButtonBar "" :cmd {}

    bind ButtonBar <Destroy> [list [namespace current]::_destroy %W]
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::create
# ----------------------------------------------------------------------------
proc ButtonBar::create {path args} {
    Widget::init ButtonBar $path $args

    variable $path
    upvar 0  $path data

    if {![catch {Widget::theme}] && [Widget::theme]} {
        ttk::frame $path {*}[Widget::subcget $path :cmd] -class ButtonBar
        ttk::frame $path.spacer -width [winfo screenwidth $path]
    } else {
        frame $path {*}[Widget::subcget $path :cmd] -class ButtonBar \
                -takefocus 0 -highlightthickness 0
        # For 8.4+ we don't want to inherit the padding
        catch {$path configure -padx 0 -pady 0}
        frame $path.spacer -width [winfo screenwidth $path]
    }

    bind $path <Configure> [list [namespace current]::_configure %W]

    set data(buttons)  [list]
    set data(active) ""
    set data(bindtabs) [list]

    return [Widget::create ButtonBar $path]
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::configure
# ----------------------------------------------------------------------------
proc ButtonBar::configure {path args} {
    variable $path
    upvar 0  $path data

    set res [Widget::configure $path $args]

    if {[Widget::hasChanged $path -orient val] || \
        [Widget::hasChanged $path -minwidth val] || \
        [Widget::hasChanged $path -maxwidth val]} {
        _redraw $path
    }

    return $res
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::cget
# ----------------------------------------------------------------------------
proc ButtonBar::cget {path option} {
    return [Widget::cget $path $option]
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::_option
# ----------------------------------------------------------------------------
proc ButtonBar::_itemoption {path name option} {
    if {![catch {Widget::theme}] && [Widget::theme]} {
        switch -- $option {
            -font {
                return [ttk::style lookup ButtonBar.$name.TButton -font {} TkDefaultFont]
            }
            -padx {
                return [lindex [ttk::style lookup ButtonBar.$name.TButton \
                                           -padding] 0]
            }
            -pady {
                return [lindex [ttk::style lookup ButtonBar.$name.TButton \
                                           -padding] 1]
            }
            -bd -
            -borderwidth {
                set bd [ttk::style lookup ButtonBar.$name.TButton \
                                   -borderwidth]
                if {$bd ne ""} {
                    return $bd
                } else {
                    return 0
                }
            }
            -highlightthickness {
                set hl [ttk::style lookup ButtonBar.$name.TButton \
                                   -highlightthickness]
                if {$hl ne ""} {
                    return $hl
                } else {
                    return 0
                }
            }
        }
    }
    return [lindex [Button::configure [_but $path $name] $option] 4]
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::insert
# ----------------------------------------------------------------------------
proc ButtonBar::insert {path idx name args} {
    variable $path
    upvar 0  $path data

    set but [_but $path $name]
    set data(buttons) [linsert $data(buttons) $idx $name]

    set newargs {}
    foreach {key val} $args {
        switch -- $key {
            -raisecmd {
                set data(raisecmd,$name) $val
            }
            default { lappend newargs $key $val }
        }
    }

    if {[catch {Widget::theme}] || ![Widget::theme]} {
        lappend newargs -padx [Widget::getoption $path -padx] \
                        -pady [Widget::getoption $path -pady] \
                        -anchor w
    }
    Button::create $but \
              -command [list [namespace current]::activate $path $name] \
              {*}$newargs
    if {![catch {Widget::theme}] && [Widget::theme]} {
        ttk::style configure ButtonBar.$name.TButton \
                   -padding [list [Widget::getoption $path -padx] \
                                  [Widget::getoption $path -pady]] \
                   -anchor w
        $but:cmd configure -style ButtonBar.$name.TButton
    }

    _calc_text $path $name

    bind $but <Configure> [list [namespace current]::_itemconfigure \
                                [_escape $path] [_escape $name]]

    foreach {event script} $data(bindtabs) {
        bind $but $event [linsert $script end [_escape $name]]
    }

    DragSite::register $but \
        -draginitcmd [list [namespace current]::_draginitcmd $path $name]
    DropSite::register $but \
        -dropcmd [list [namespace current]::_dropcmd $path $name] \
        -droptypes [list ButtonBar:$path]

    _redraw $path

    if {![string equal [Widget::getoption $path -pages] ""]} {
        set res [[Widget::getoption $path -pages] add $name]
    } else {
        set res $but
    }

    if {[llength $data(buttons)] == 1} {
        activate $path $name -nocmd
    }

    return $res
}

proc ButtonBar::_draginitcmd {path name target x y top} {
    activate $path $name
    return [list ButtonBar:$path {move} $name]
}

proc ButtonBar::_dropcmd {path tname target source X Y op type name} {
    move $path $name [index $path $tname]
}

# ----------------------------------------------------------------------------
#  Command ButtonBar::move
# ----------------------------------------------------------------------------
proc ButtonBar::move {path name idx} {
    variable $path
    upvar 0  $path data

    set i [lsearch -exact $data(buttons) $name]
    if {$i >= 0} {
        set data(buttons) [linsert [lreplace $data(buttons) $i $i] $idx $name]
        _redraw $path
    }
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::delete
# ----------------------------------------------------------------------------
proc ButtonBar::delete {path name {destroyframe 1}} {
    variable $path
    upvar 0  $path data

    set i [lsearch -exact $data(buttons) $name]
    if {$i >= 0} {
        set data(buttons) [lreplace $data(buttons) $i $i]
        destroy [_but $path $name]
        if {![string equal [Widget::getoption $path -pages] ""]} {
            [Widget::getoption $path -pages] delete $name
        }
        if {[llength $data(buttons)] == 0} {
            set data(active) ""
        }
        catch {unset data(raisecmd,$name)}
        catch {unset data(text,$name)}
        catch {unset data(width,$name)}
        catch {unset data(height,$name)}
        _redraw $path
        # TODO: Delete style ButtonBar.$name.TButton
    }
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::activate
# ----------------------------------------------------------------------------
proc ButtonBar::activate {path name {nocmd ""}} {
    variable $path
    upvar 0  $path data

    set active ""
    foreach n $data(buttons) {
        set but [_but $path $n]
        if {![catch {Widget::theme}] && [Widget::theme]} {
            if {[string equal $n $name]} {
                $but:cmd state {pressed active}
                set active $n
            } else {
                $but:cmd state {!pressed !active}
            }
        } else {
            if {[string equal $n $name]} {
                Button::configure $but -relief sunken -state active
                set active $n
            } else {
                Button::configure $but -relief raised -state normal
            }
        }
    }
    if {![string equal [Widget::getoption $path -pages] ""]} {
        [Widget::getoption $path -pages] raise $active
    }
    if {$nocmd != "-nocmd" && $active != $data(active)} {
        if {[info exists data(raisecmd,$name)]} {
            uplevel #0 $data(raisecmd,$name)
        }
        set cmd [Widget::getoption $path -command]
        if {$cmd != ""} {
            uplevel #0 $cmd [list $active]
        }
    }
    set data(active) $active
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::itemconfigure
# ----------------------------------------------------------------------------
proc ButtonBar::itemconfigure {path name args} {
    variable $path
    upvar 0  $path data
    set but [_but $path $name]

    if {[llength $args] == 1} {
        set key [lindex $args 0]
        switch -- $key {
            -text {
                set res $data(text,$name)
            }
            -raisecmd {
                if {[info exists data(raisecmd,$name)]} {
                    set res [list -raisecmd raisecmd Raisecmd "" \
                                  $data(raisecmd,$name)]
                } else {
                    set res [list -raisecmd raisecmd Raisecmd "" ""]
                }
            }
            -font -
            -foreground -
            -activeforeground {
                if {![catch {Widget::theme}] && [Widget::theme]} {
                    # TODO: Do we really need this for Ttk?
                    set val [ttk::style configure ButtonBar.$name.TButton $key]
                    set def [ttk::style configure TButton $key]
                    set res [list $key {} {} $def $val]
                } else {
                    set res [Button:configure $but $key]
                }
            }
            default {
                set res [Button:configure $but $key]
            }
        }
        return $res
    } else {
        set opts {}
        foreach {key val} $args {
            switch -- $key {
                -raisecmd {
                    set data(raisecmd,$name) $val
                }
                -foreground -
                -activeforeground {
                    if {![catch {Widget::theme}] && [Widget::theme]} {
                        ttk::style configure ButtonBar.$name.TButton \
                                   -foreground $val
                    } else {
                        lappend opts $key $val
                    }
                }
                -font {
                    if {![catch {Widget::theme}] && [Widget::theme]} {
                        ttk::style configure ButtonBar.$name.TButton -font $val
                    } else {
                        lappend opts $key $val
                    }
                }
                default {
                    lappend opts $key $val
                }
            }
        }

        if {[llength $opts] > 0} {
            set res [Button::configure $but {*}$opts]
        } else {
            set res ""
        }

        set tf 0
        foreach {key val} $args {
            switch -- $key {
                -text -
                -font {
                    set tf 1
                }
            }
        }
        if {$tf} {
            _calc_text $path $name
            _reconfigure_text $path $name
        }
    }
    return $res
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::itemcget
# ----------------------------------------------------------------------------
proc ButtonBar::itemcget {path name option} {
    variable $path
    upvar 0  $path data

    switch -- $option {
        -text {
            set res $data(text,$name)
        }
        -raisecmd {
            if {[info exists data(raisecmd,$name)]} {
                set res $data(raisecmd,$name)
            } else {
                set res ""
            }
        }
        -font -
        -foreground -
        -activeforeground {
            if {![catch {Widget::theme}] && [Widget::theme]} {
                set res [ttk::style lookup ButtonBar.$name.TButton $option]
            } else {
                set res [Button::cget [_but $path $name] $option]
            }
        }
        default {
            set res [Button::cget [_but $path $name] $option]
        }
    }
    return $res
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::setfocus
# ----------------------------------------------------------------------------
proc ButtonBar::setfocus {path name} {
    set but [_but $path $name]
    if { [winfo exists $but] } {
        focus $but
    }
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::index
# ----------------------------------------------------------------------------
proc ButtonBar::index {path name} {
    variable $path
    upvar 0  $path data

    return [lsearch -exact $data(buttons) $name]
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::_configure
# ----------------------------------------------------------------------------
proc ButtonBar::_configure {path} {
    variable $path
    upvar 0  $path data

    set w [winfo width $path]
    set h [winfo height $path]
    if {![info exists data(width)] || $data(width) != $w || \
        ![info exists data(height)] || $data(height) != $h} {
        set data(width) $w
        set data(height) $h
        _redraw $path
    }
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::_redraw
# ----------------------------------------------------------------------------
proc ButtonBar::_redraw {path} {
    variable $path
    upvar 0  $path data

    array unset data configured,*

    $path:cmd configure -width 0

    grid forget $path.spacer

    set cols [lindex [grid size $path] 0]
    set rows [lindex [grid size $path] 1]
    for {set c 0} {$c < $cols} {incr c} {
        grid columnconfigure $path $c -weight 0 -minsize 0
        catch {grid columnconfigure $path $c -uniform {}}
    }
    for {set r 0} {$r < $rows} {incr r} {
        grid rowconfigure $path $r -weight 0 -minsize 0
        catch {grid rowconfigure $path $r -uniform {}}
    }

    set num [llength $data(buttons)]

    if {$num == 0} return

    # Change buttons stacking order
    foreach name $data(buttons) {
        ::raise [_but $path $name]
    }

    set min [winfo pixels $path [Widget::getoption $path -minwidth]]
    set max [winfo pixels $path [Widget::getoption $path -maxwidth]]
    if {$min > $max} {
        set max $min
    }

    if {[string equal [Widget::getoption $path -orient] "horizontal"]} {
        set w [winfo width $path]

        if {$min == 0} {
            set cols $num
        } else {
            set cols [expr {int($w / $min)}]
            if {$cols > $num} {
                set cols $num
            }
        }

        if {[expr {$max * $cols}] < $w} {
            set weight 2
            set minsize $max
            grid $path.spacer -column $cols -row 0
            grid columnconfigure $path $cols -weight 1 -minsize 0
        } else {
            set weight 1
            set minsize $min
        }

        set c 0
        set r 0
        foreach name $data(buttons) {
            grid [_but $path $name] -column $c -row $r -sticky nsew
            grid columnconfigure $path $c -weight $weight -minsize $minsize
            catch {grid columnconfigure $path $c -uniform 1}
            incr c
            if {$c >= $cols} {
                set c 0
                incr r
            }
        }
    } else {
        set h [winfo height $path]

        set c 0
        set r 0
        set th 0
        set num 0
        foreach name $data(buttons) {
            _reconfigure_text $path $name
        }
        foreach name $data(buttons) {
            set but [_but $path $name]

            if {[info exists data(height,$name)]} {
                incr th $data(height,$name)
            } else {
                incr th [winfo reqheight $but]
            }
            if {($c > 0 && $r >= $num) || ($c == 0 && $th > $h)} {
                set r 0
                incr c
            } elseif {$c == 0} {
                incr num
            }
            grid $but -column $c -row $r -sticky nsew
            grid rowconfigure $path $r -weight 0 -minsize 0
            grid columnconfigure $path $c -weight 0 -minsize $max
            incr r
        }
        grid rowconfigure $path $num -weight 10000000 -minsize 0
    }
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::_destroy
# ----------------------------------------------------------------------------
proc ButtonBar::_destroy {path} {
    variable $path
    upvar 0  $path data
    Widget::destroy $path
    unset data
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::_but
# ----------------------------------------------------------------------------
proc ButtonBar::_but {path name} {
    return $path.b:$name
}

# ----------------------------------------------------------------------------
#  Command ButtonBar::pages
# ----------------------------------------------------------------------------
proc ButtonBar::pages {path {first ""} {last ""}} {
    variable $path
    upvar 0  $path data

    if {[string equal $first ""]} {
        return $data(buttons)
    } elseif {[string equal $last ""]} {
        return [lindex $data(buttons) $first]
    } else {
        return [lrange $data(buttons) $first $last]
    }
}

# ----------------------------------------------------------------------------
#  Command ButtonBar::raise
# ----------------------------------------------------------------------------
proc ButtonBar::raise {path {name ""}} {
    variable $path
    upvar 0  $path data

    if {[string equal $name ""]} {
        return $data(active)
    } else {
        activate $path $name
    }
}

# ----------------------------------------------------------------------------
#  Command ButtonBar::getframe
# ----------------------------------------------------------------------------
proc ButtonBar::getframe {path name} {
    if {![string equal [Widget::getoption $path -pages] ""]} {
        return [[Widget::getoption $path -pages] getframe $name]
    } else {
        return ""
    }
}

# ----------------------------------------------------------------------------
#  Command ButtonBar::bindtabs
# ----------------------------------------------------------------------------
proc ButtonBar::bindtabs {path event script} {
    variable $path
    upvar 0  $path data

    lappend data(bindtabs) $event $script

    foreach name $data(buttons) {
        bind [_but $path $name] $event [linsert $script end [_escape $name]]
    }
}

# ----------------------------------------------------------------------------
#  Command ButtonBar::see
# ----------------------------------------------------------------------------
proc ButtonBar::see {path name} {
    return ""
}

# ----------------------------------------------------------------------------
#  Command ButtonBar::_itemconfigure
# ----------------------------------------------------------------------------
proc ButtonBar::_itemconfigure {path name} {
    variable $path
    upvar 0  $path data

    if {[info exists data(configured,$name)]} return

    set data(configured,$name) 1

    set but [_but $path $name]
    set w [winfo width $but]

    if {![info exists data(text,$name)] ||
            ![info exists data(width,$name)] || $data(width,$name) != $w} {
        set data(width,$name) $w
        _reconfigure_text $path $name
    }
    set data(height,$name) [winfo height $but]
}


# ----------------------------------------------------------------------------
#  Command ButtonBar::_calc_text
# ----------------------------------------------------------------------------
proc ButtonBar::_calc_text {path name} {
    variable $path
    upvar 0  $path data

    set text [_itemoption $path $name -text]
    set font [_itemoption $path $name -font]

    set data(text,$name) [list $text [font measure $font $text]]

    set len [string length $text]

    for {set ind 0} {$ind < $len} {incr ind} {
        lappend data(text,$name) \
                [font measure $font [string range $text 0 $ind]\u2026]
    }
}

# ----------------------------------------------------------------------------
#  Command ButtonBar::_reconfigure_text
# ----------------------------------------------------------------------------
proc ButtonBar::_reconfigure_text {path name} {
    variable $path
    upvar 0  $path data


    if {![info exists data(text,$name)]} return

    set but [_but $path $name]

    set padx [winfo pixels $path [_itemoption $path $name -padx]]
    set bd   [winfo pixels $path [_itemoption $path $name -borderwidth]]
    set hl   [winfo pixels $path [_itemoption $path $name -highlightthickness]]

    set w [winfo width $but]
    set min [winfo pixels $path [Widget::getoption $path -minwidth]]
    set max [winfo pixels $path [Widget::getoption $path -maxwidth]]
    if {$min > $max} {
        set max $min
    }

    set tw [expr {$w - 2*($padx + $bd + $hl + 1)}]
    set mw [expr {$max - 2*($padx + $bd + $hl + 1)}]

    set text [lindex $data(text,$name) 0]
    set textw [lindex $data(text,$name) 1]

    Button::configure $but -text $text -helptext ""
    if {$textw <= $tw && $textw <= $mw} {
        return
    }

    set i -1
    foreach textw [lrange $data(text,$name) 2 end] {
        if {$textw > $tw || $textw > $mw} {
            Button::configure $but -text [string range $text 0 $i]\u2026 \
                                   -helptext $text
            return
        }
        incr i
    }
}

# ----------------------------------------------------------------------------
#  Command ButtonBar::_escape
# ----------------------------------------------------------------------------
proc ButtonBar::_escape {str} {
    string map {% %%} $str
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
