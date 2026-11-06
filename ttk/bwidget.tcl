# bwidget.tcl --
#
#       This file is a part of the Tkabber XMPP client. It contains all sorts
#       of hacks around BWidget bugs or inconveniencies.

proc Combobox {path args} {
    if {[dict exists $args -editable]} {
        if {![dict get $args -editable]} {
            dict set args -state readonly
        }
    }
    if {[dict exists $args -command]} {
        set cmd [dict get $args -command]
    }
    if {[dict exists $args -modifycmd]} {
        set mcmd [dict get $args -modifycmd]
    }
    set args [dict remove $args -editable -modifycmd -command]
    ttk::combobox $path {*}$args
    if {[info exists cmd]} {
        bind $path <Return> [double% $cmd]
    }
    if {[info exists mcmd]} {
        bind $path <<ComboboxSelected>> [double% $mcmd]
    }

    return $path
}

##########################################################################

proc PanedWin {path args} {
    ttk::panedwindow $path {*}$args
}

proc PanedWinAdd {path args} {
    set idx [llength [$path panes]]
    set f [frame $path.frame$idx]
    $path add $f {*}$args
    return $f
}

proc PanedWinSashXPos {path index args} {
    if {[llength $args] == 1} {
        $path sashpos $index [lindex $args 0]
    }
    return [$path sashpos $index]
}

##########################################################################

proc Notebook {args} {
    set nb [ttk::notebook {*}$args]
    rename ::$nb ::$nb:cmd
    interp alias {} ::$nb {} Notebook:cmd $nb
    bind $nb <Destroy> "rename ::$nb {}"
    bind $nb <<NotebookTabChanged>> {Notebook:tab_raised %W}
    return $nb
}

proc Notebook:tab_raised {nb} {
    global Notebook

    set fr [$nb:cmd select]
    set name [lindex [split $fr .] end]
    if {[info exists Notebook(raisecmd:$nb:$name)]} {
        {*}$Notebook(raisecmd:$nb:$name)
    }
}

proc Notebook:cleanup {nb} {
    global Notebook

    rename ::$nb {}
    array unset Notebook raisecmd:$nb:*
}

proc Notebook:cmd {nb cmd args} {
    switch -- $cmd {
        getframe {
            set name [lindex $args 0]
            return $nb.$name
        }
        raise {
            if {[llength $args] == 0} {
                set fr [$nb:cmd select]
                return [lindex [split $fr .] end]
            } else {
                set name [lindex $args 0]
                $nb:cmd select $nb.$name
            }
        }
        insert {
            set args [lassign $args pos name]
            if {[dict exists $args -raisecmd]} {
                global Notebook
                set Notebook(raisecmd:$nb:$name) [dict get $args -raisecmd]
                set args [dict remove $args -raisecmd]
            }
            Frame $nb.$name
            $nb:cmd insert $pos $nb.$name {*}[dict replace $args -padding 2m]
            return $nb.$name
        }
        pages {
            set res {}
            foreach fr [$nb:cmd tabs] {
                lappend res [lindex [split $fr .] end]
            }
            return $res
        }
        index {
            # There's a problem with this code. One cannot check if a
            # page exists with [$nb index page] >= 0. The command crashes.
            # A workaround: [winfo exists $nb.page] && [$nb index page] >= 0.
            set name [lindex $args 0]
            if {[winfo exists $nb.$name]} {
                set name $nb.$name
            }
            return [$nb:cmd index $name]
        }
        see {
            return ""
        }
        default {
            return [$nb:cmd $cmd {*}$args]
        }
    }
}

##########################################################################

proc Spinbox {path from to incr textvar args} {
    ttk::spinbox $path \
                 -from $from \
                 -to $to \
                 -increment $incr \
                 -textvariable $textvar \
                 {*}$args
}

##########################################################################

auto_load Dialog

proc Dialog::frame {path args} {
    set newargs {}
    set padding 0
    foreach {key val} $args {
        switch -- $key {
            -highlightthickness -
            -background {}
            -padding {
                lappend newargs $key $val
                set padding 1
            }
            default {
                lappend newargs $key $val
            }
        }
    }
    if {!$padding} {
        lappend newargs -padding 0.5m
    }
    set f [ttk::frame $path {*}$newargs]
    rename ::$f ::$f:cmd1
    interp alias {} ::$f {} Dialog::frame:cmd $f
    bind $f <Destroy> "rename ::$f {}"
    bind $f <Destroy> "+catch {rename ::$f:cmd {}}"
    return $f
}

proc Dialog::frame:cmd {f cmd args} {
    switch [llength $args] {
        0 {
            return [$f:cmd1 $cmd]
        }
        1 {
            set arg [lindex $args 0]
            switch -- $arg {
                -highlightthickness {
                    return 0
                }
                -background {
                    return [ttk::style lookup . -background]
                }
                default {
                    return [$f:cmd1 $cmd $arg]
                }
            }
        }
        default {
            set newargs {}
            foreach {key val} $args {
                switch -- $key {
                    -highlightthickness -
                    -background {}
                    default {
                        lappend newargs $key $val
                    }
                }
            }
            return [$f:cmd1 $cmd {*}$newargs]
        }
    }
}

rename Dialog::create Dialog::create:old

proc Dialog::create {path args} {
    toplevel $path
    wm withdraw $path
    set parent [winfo parent $path]
    destroy $path
    set spacing 0
    set padx 0
    set transient 1
    set newargs {}
    foreach {key val} $args {
        switch -- $key {
            -parent {
                set parent $val
                lappend newargs -parent $val
            }
            -transient {
                set transient $val
            }
            -spacing {
                lappend newargs -spacing [winfo pixels $parent $val]
                set spacing 1
            }
            -padx {
                lappend newargs -padx $val
                set padx 1
            }
            default {
                lappend newargs $key $val
            }
        }
    }
    if {!$spacing} {
        lappend newargs -spacing [winfo pixels $parent 2.5m]
    }
    if {!$padx} {
        lappend newargs -padx [winfo pixels $parent 2.5m]
    }
    # Do not make a dialog window transient if its parent isn't vewable.
    # Otherwise it leads to hang of a whole application.
    if {$parent == ""} {
        set parent .
    }
    if {![winfo viewable [winfo toplevel $parent]] } {
        set transient 0
    }

    set res [Dialog::create:old $path -transient $transient {*}$newargs]
    $path:cmd configure -background [ttk::style configure . -background]
    return $res
}

##########################################################################

auto_load ButtonBox

rename ButtonBox::create ButtonBox::create:old

proc ButtonBox::create {path args} {
    toplevel $path
    wm withdraw $path
    set parent [winfo parent $path]
    destroy $path
    set spacing 0
    set newargs {}
    foreach {key val} $args {
        switch -- $key {
            -spacing {
                lappend newargs -spacing [winfo pixels $parent $val]
                set spacing 1
            }
            default {
                lappend newargs $key $val
            }
        }
    }
    if {!$spacing} {
        lappend newargs -spacing [winfo pixels $parent 2.5m]
    }

    ButtonBox::create:old $path {*}$newargs
}

proc ButtonBox::frame {args} {
    Dialog::frame {*}$args
}

##########################################################################

proc tk_optionMenu {w varName firstValue args} {
    upvar #0 $varName var

    if {![info exists var]} {
        set var $firstValue
    }
    ttk::menubutton $w -textvariable $varName \
                       -menu $w.menu \
                       -direction flush
    menu $w.menu -tearoff 0
    $w.menu add radiobutton -label $firstValue -variable $varName
    foreach i $args {
        $w.menu add radiobutton -label $i -variable $varName
    }
    return $w.menu
}

##########################################################################

auto_load MainFrame

rename MainFrame::addindicator MainFrame::addindicator:old

proc MainFrame::addindicator {path args} {
    set indic [MainFrame::addindicator:old $path {*}$args]
    catch { $indic configure -background [ttk::style lookup TFrame -background] }
    return $indic
}

##########################################################################

proc Listbox {path args} {
    if {![dict exists $args -selectmode]} {
        dict set args -selectmode browse
    }
    set args [dict remove $args -exportselection]
    set args [dict replace $args -show {} \
                                 -columns {list} \
                                 -displaycolumns {list}]
    ttk::treeview $path {*}$args
    rename ::$path ::$path:cmd
    interp alias {} $path {} Listbox:cmd $path
    bind $path <<TreeviewSelect>> [list event generate $path <<ListboxSelect>>]
    return $path
}

proc Listbox:cmd {path cmd args} {
    switch -- $cmd {
        bbox {
            lassign $args idx
            if {[lsearch -exact [$path:cmd children {}] $idx] >= 0} {
                return [$path:cmd index {*}$args]
            }
            if {[regexp {^@(\d+),(\d+)$} $idx -> x y]} {
                set item [$path:cmd identify item $x $y]
                if {$item eq ""} {
                    set item [lindex [$path:cmd children {}] end]
                }
                return [$path:cmd bbox $item]
            } else {
                set item [lindex [$path:cmd children {}] $idx]
                return [$path:cmd bbox $item]
            }
        }
        curselection {
            set res {}
            foreach item [$path:cmd select] {
                lappend res [$path:cmd index $item]
            }
            return $res
        }
        delete {
            lassign $args start end
            if {$end eq ""} {
                set end $start
            }
            set del [lrange [$path:cmd children {}] $start $end]
            $path:cmd delete $del
        }
        index {
            lassign $args idx
            if {[lsearch -exact [$path:cmd children {}] $idx] >= 0} {
                return [$path:cmd index $idx]
            }
            if {[regexp {^@(\d+),(\d+)$} $idx -> x y]} {
                set item [$path:cmd identify item $x $y]
                if {$item eq ""} {
                    set item [lindex [$path:cmd children {}] end]
                }
                return [$path:cmd index $item]
            } elseif {$idx eq "end"} {
                return [llength [$path:cmd children {}]]
            } else {
                set item [lindex [$path:cmd children {}] $idx]
                return [$path:cmd index $item]
            }
        }
        insert {
            set items [lassign $args idx]
            foreach item $items {
                $path:cmd insert {} $idx -values [list $item]
                set idx [expr {$idx eq "end"? $idx : $idx+1}]
            }
        }
        get {
            set l 1
            lassign $args start end
            if {$end eq ""} {
                set end $start
                set l 0
            }
            set res {}
            foreach item [lrange [$path:cmd children {}] $start $end] {
                lappend res [lindex [$path:cmd item $item -values] 0]
            }
            if {$l} {
                return $res
            } else {
                return [lindex $res 0]
            }
        }
        nearest {
            lassign $args y
            set item [$path:cmd identify item 0 $y]
            if {$item ne {}} {
                return [lsearch -exact [$path:cmd children {}] $item]
            } else {
                return [expr {[llength [$path:cmd children {}]] - 1}]
            }
        }
        selection {
            set args [lassign $args subcommand]
            switch -- $subcommand {
                clear {
                    lassign $args start end
                    if {$end eq ""} {
                        set end $start
                    }
                    set range [lrange [$path:cmd children {}] $start $end]
                    $path:cmd selection remove $range
                }
                includes {
                    lassign $args index
                    set item [lindex [$path:cmd children {}] $index]
                    return [expr {[lsearch -exact \
                                           [$path:cmd selection] $item] >= 0}]
                }
                set {
                    lassign $args start end
                    if {![string is integer $start] && $start ne "end"} {
                        return [$path:cmd selection set {*}$args]
                    }
                    if {$end eq ""} {
                        set end $start
                    }
                    set range [lrange [$path:cmd children {}] $start $end]
                    foreach item [$path:cmd selection] {
                        lappend range $item
                    }
                    $path:cmd selection set $range
                }
                default {
                    $path:cmd selection $subcommand {*}$args
                }
            }
        }
        see {
            lassign $args idx
            if {![string is integer $idx] && $idx ne "end"} {
                $path:cmd see $idx
            } else {
                $path:cmd see [lindex [$path:cmd children {}] $idx]
            }
        }
        size {
            return [llength [$path:cmd children {}]]
        }
        default {
            $path:cmd $cmd {*}$args
        }
    }
}

##########################################################################

proc BWidget::bindMouseWheel {widget} {}

##########################################################################

proc Message {path args} {
    set args [dict remove $args -background]
    message $path {*}$args -background [ttk::style lookup . -background]
}

##########################################################################

proc Toplevel {path args} {
    set args [dict remove $args -background]
    toplevel $path {*}$args -background [ttk::style lookup . -background]
}

##########################################################################

namespace eval ::ttk {
    bind Wrapframe <FocusIn>  {
        %W#border state focus
    }
    bind Wrapframe <FocusOut> {
        %W#border state !focus
    }
}

# wraps a plain Tk widget inside a ttk frame
proc ::ttk::WrapWidget {class path args} {
    set bg [ttk::style lookup . -fieldbackground {} white]
    # handle the args
    set args [dict replace $args \
        -background $bg \
        -borderwidth 0 \
        -highlightthickness 0]
    set args [dict remove $args -bg -bd]

    # real widget
    set rw $path.$class

    # create the container frame and the widget
    frame $path -style TEntry -class Wrapframe
    ::$class $rw {*}$args
    bindtags $rw [linsert [bindtags $rw] 0 $path]

    # rename the container widget cmd and install
    # a proxy cmd to the real one
    rename ::$path ::${path}#border
    interp alias {} $path {} ::ttk::WrapProxy $rw

    pack $rw -expand 1 -fill both -padx 0.5m -pady 0.5m

    # adjust the select{fore|back}ground with the theme
    bind $rw <<ThemeChanged>> [list apply {rw {
        set sb [ttk::style configure . -selectbackground]
        set sf [ttk::style configure . -selectforeground]
        if {$sb ne ""} {
            $rw configure -selectbackground $sb
        }
        if {$sf ne ""} {
            $rw configure -selectforeground $sf
        }
    }} $rw]
    after idle [list after 0 [list GenThemeChanged $rw]]

    return $path
}

proc ::ttk::WrapProxy {w args} {
    # prevent the border window to take focus
    if {[lindex $args 0] eq "cget" &&
        [lindex $args 1] eq "-takefocus"} {
        return 0
    }
    uplevel 1 [linsert $args 0 $w]
}

proc Wrapped {w} {
    lindex [winfo children $w] 0
}

proc GenThemeChanged {w} {
    if {[winfo exists $w]} {
        event generate $w <<ThemeChanged>>
    }
}

##########################################################################

interp alias {} Labelframe  {} ttk::labelframe
interp alias {} Text        {} ::ttk::WrapWidget text
interp alias {} Canvas      {} ::ttk::WrapWidget canvas
interp alias {} Frame       {} ::ttk::frame
interp alias {} Menubutton  {} ::ttk::menubutton
interp alias {} Progressbar {} ::ttk::progressbar
interp alias {} Checkbutton {} ::ttk::checkbutton
interp alias {} Radiobutton {} ::ttk::radiobutton
interp alias {} Scale       {} ::ttk::scale
interp alias {} Scrollbar   {} ::ttk::scrollbar

##########################################################################

proc MyTree {args} {
    set path [::ttk::treeview {*}$args -show {tree} \
                                       -columns {} \
                                       -displaycolumns {} \
                                       -selectmode browse]
    bindscroll $path
    return $path
}

##########################################################################

proc MenuToolbutton {args} {
    ttk::menubutton {*}$args -style Toolbutton
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
