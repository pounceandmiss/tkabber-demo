# bwidget.tcl --
#
#       This file is a part of the Tkabber XMPP client. It contains all sorts
#       of hacks around BWidget bugs or inconveniencies.

auto_load Button
rename Button::create Button::create#orig

proc Button::create {path args} {
    Button::create#orig $path {*}[dict remove $args -background -bg]
}

##########################################################################

rename menu menu#orig

proc menu {path args} {
    menu#orig $path {*}[dict remove $args -background -bg]
}

##########################################################################

auto_load Tree

proc Tree::_see {path idn {side "none"}} {
    set bbox [$path.c bbox $idn]
    set scrl [$path.c cget -scrollregion]

    set ymax [lindex $scrl 3]
    set dy   [$path.c cget -yscrollincrement]
    set yv   [$path yview]
    set yv0  [expr {round([lindex $yv 0]*$ymax/$dy)}]
    set yv1  [expr {int([lindex $yv 1]*$ymax/$dy + 0.1)}]
    set y    [expr {int([lindex [$path.c coords $idn] 1]/$dy)}]
    if { $y < $yv0 } {
        $path.c yview scroll [expr {$y-$yv0}] units
    } elseif { $y >= $yv1 } {
        $path.c yview scroll [expr {$y-$yv1+1}] units
    }

    set xmax [lindex $scrl 2]
    set dx   [$path.c cget -xscrollincrement]
    set xv   [$path xview]
    if { $side eq "none" } {
        set x0   [expr {int([lindex $bbox 0]/$dx)}]
        set xv0  [expr {round([lindex $xv 0]*$xmax/$dx)}]
        set xv1  [expr {round([lindex $xv 1]*$xmax/$dx)}]
        if { $x0 >= $xv1 || $x0 < $xv0 } {
            $path.c xview scroll [expr {$x0-$xv0}] units
        }
    } elseif { $side eq "right" } {
        set xv1 [expr {round([lindex $xv 1]*$xmax/$dx)}]
        set x1  [expr {int([lindex $bbox 2]/$dx)}]
        if { $x1 >= $xv1 } {
            $path.c xview scroll [expr {$x1-$xv1+1}] units
        }
    } else {
        set xv0 [expr {round([lindex $xv 0]*$xmax/$dx)}]
        set x0  [expr {int([lindex $bbox 0]/$dx)}]
        if { $x0 < $xv0 } {
            $path.c xview scroll [expr {$x0-$xv0}] units
        }
    }
}

proc Tree::tag {path command args} {
    variable $path
    upvar 0  $path data

    switch -- $command {
        configure {
            set args [lassign $args tag]
            foreach {key val} $args {
                dict set data(tags) $tag $key $val
            }
            # TODO: reconfigure existing items
        }
        bind {
            lassign $args tag event script
            $path.c bind tag:$tag $event $script
        }
    }
}

proc Tree::item {path item args} {
    switch -- [llength $args] {
        1 {
            set key [lindex $args 0]
            switch -- $key {
                -text -
                -image -
                -open {
                    return [$path itemcget $item $key]
                }
                -values {
                    return [lindex [$path itemcget $item -data] 0]
                }
                -tags {
                    return [lindex [$path itemcget $item -data] 1]
                }
            }
        }
        default {
            foreach {key val} $args {
                switch -- $key {
                    -text -
                    -image -
                    -open {
                        $path itemconfigure $item $key $val
                    }
                    -values {
                        $path itemconfigure $item \
                              -data [lreplace [$path itemcget $item -data] \
                                              0 0 $val]
                    }
                    -tags {
                        $path itemconfigure $item \
                              -data [lreplace [$path itemcget $item -data] \
                                              1 1 $val]
                        Tree::_itemconf $path $item $val
                    }
                }
            }
        }
    }
}

proc Tree::_itemconf {path item tags} {
    variable $path
    upvar 0  $path data

    foreach tag $tags {
        if {[info exists data(tags)] && [dict exists $data(tags) $tag]} {
            foreach {key val} [dict get $data(tags) $tag] {
                switch -- $key {
                    -foreground {
                        $path itemconfigure $item -fill $val
                    }
                    -font {
                        $path itemconfigure $item -font $val
                    }
                }
            }
        }
    }
}

proc Tree::children {path item args} {
    switch -- [llength $args] {
        0 {
            if {$item eq {}} {
                set item root
            }
            return [$path nodes $item]
        }
        1 {
            set newchildren [lindex $args 0]
            if {$item eq {}} {
                set item root
            }
            return [$path reorder $item $newchildren]
        }
    }
}

rename Tree::parent Tree::parent:old

proc Tree::parent {path item} {
    set parent [Tree::parent:old $path $item]
    if {$parent eq "root"} {
        return {}
    } else {
        return $parent
    }
}

rename Tree::insert Tree::insert:old

proc Tree::insert {path parent index args} {
    variable itemid

    if {$parent eq {}} {
        set parent root
    }
    if {[dict exists $args -id]} {
        set item [dict get $args -id]
        set args [dict remove $args -id]
    } else {
        set item i[incr itemid]
    }

    set data {{} {}}
    if {[dict exists $args -values]} {
        set data [lreplace $data 0 0 [dict get $args -values]]
        set args [dict remove $args -values]
    }
    set tags {}
    if {[dict exists $args -tags]} {
        set tags [dict get $args -tags]
        set data [lreplace $data 1 1 $tags]
        set args [dict remove $args -tags]
    }

    set res [Tree::insert:old $path $index $parent $item -data $data {*}$args]

    Tree::_itemconf $path $item $tags

    return $res
}

rename Tree::selection Tree::selection:old

proc Tree::selection {path args} {
    if {[llength $args] == 0} {
        return [Tree::selection:old $path get]
    } else {
        return [Tree::selection:old $path {*}$args]
    }
}

rename Tree::move Tree::move:old

proc Tree::move {path item parent index} {
    Tree::move:old $path $parent $item $index
}

rename Tree::_get_node_tags Tree::_get_node_tags:old

proc Tree::_get_node_tags {path node {tags ""}} {
    set newtags [Tree::_get_node_tags:old $path $node $tags]
    foreach tag [$path item $node -tags] {
        lappend newtags tag:$tag
    }
    return $newtags
}

proc Tree::identify {path what x y} {
    # TODO: not item $what
    $path find @$x,$y
}

create_image tree/opennode -data "R0lGODlhCQAJAIABAAAAAP///yH+EUNyZWF0ZWQgd2l0aCBHSU1QACwAAAAACQAJAAACEISPoRvG614D80x5ZXyogwIAOw=="
create_image tree/closenode -data "R0lGODlhCQAJAIABAAAAAP///yH+EUNyZWF0ZWQgd2l0aCBHSU1QACwAAAAACQAJAAACEYSPoRu28KCSDSJLc44s3lMAADs="

proc MyTree {path args} {
    set args \
        [dict replace $args \
              -deltax [expr {int(1.2*[font measure $::ChatFont M])}] \
              -deltay [expr {int(1.2*[font metrics $::ChatFont -linespace])}] \
              -padx [expr {20*$::icons_scale}] \
              -crossopenimage tree/opennode \
              -crosscloseimage tree/closenode \
              -selectfill 1]
    Tree::create $path {*}$args

    # TODO: Make tree lines thicker for displays with higher DPI

    Tree::bindText  $path <Control-Button-1> [list $path selection set]
    Tree::bindImage $path <Control-Button-1> [list $path selection set]

    bind $path <<TreeSelect>> {event generate %W <<TreeviewSelect>>}

    bindscroll $path.c

    return $path
}

##########################################################################

interp alias {} PanedWin {} panedwindow

proc PanedWinAdd {path args} {
    set newargs {}
    foreach {key val} $args {
        switch -- $key {
            -weight {
                if {$val == 0} {
                    lappend newargs -stretch never
                } else {
                    lappend newargs -stretch always
                }
            }
            default {
                lappend newargs $key $val
            }
        }
    }
    set idx [llength [$path panes]]
    set f [frame $path.frame$idx]
    $path add $f {*}$newargs
    return $f
}

proc PanedWinSashXPos {path index args} {
    if {[llength $args] == 1} {
        $path sash place $index [lindex $args 0] 0
    }
    return [lindex [$path sash coord $index] 0]
}

##########################################################################

auto_load ComboBox

interp alias {} Combobox {} ComboBox

option add *ComboBox.arrowButtonWidth 2.5m widgetDefault
option add *ComboBox.listRelief ridge widgetDefault
option add *ComboBox.listBorder 0.5m widgetDefault

rename ComboBox::_create_popup ComboBox::_create_popup_old

proc ComboBox::_create_popup {path args} {
    ComboBox::_create_popup_old $path {*}$args
    $path.shell configure \
            -relief [option get $path listRelief ComboBox] \
            -border [option get $path listBorder ComboBox]
}

rename ComboBox::create ComboBox::create_old

proc ComboBox::create {path args} {
    entry .fake_entry
    set hlthick [lindex [.fake_entry configure -highlightthickness] 4]
    destroy .fake_entry
    set newargs {}
    foreach {opt arg} $args {
        switch -- $opt {
            -highlightthickness {
                set hlthick $arg
            }
            -command {
                set cmd $arg
            }
            default {
                lappend newargs $opt $arg
            }
        }
    }
    ComboBox::create_old $path {*}$newargs -highlightthickness 0
    $path:cmd configure -highlightthickness $hlthick

    $path.a configure -width [winfo pixels $path [option get $path arrowButtonWidth ComboBox]]

    if {[info exists cmd]} {
        ::bind $path.e <Return> [double% $cmd]
    }

    proc ::$path {cmd args} "ComboBox::_proc $path \$cmd {*}\$args"
    return $path
}

proc ComboBox::_proc {path cmd args} {
    switch -- $cmd {
        set {
            return [_set $path [lindex $args 0]]
        }
        current {
            return [getvalue $path]
        }
        default {
            return [$cmd $path {*}$args]
        }
    }
}

proc ComboBox::_set {path value} {
    $path.e configure -text $value
}

##########################################################################

auto_load NoteBook

if {![catch {rename NoteBook::_get_page_name NoteBook::_get_page_name:old}]} {
    proc NoteBook::_get_page_name {path {item current} {tagindex end-1}} {
        set pagename [NoteBook::_get_page_name:old $path $item $tagindex]
        if {[catch { NoteBook::_test_page $path $pagename }]} {
            return [string range [lindex [$path.c gettags $item] 1] 2 end]
        } else {
            return $pagename
        }
    }
}

proc Notebook {path args} {
    NoteBook $path {*}$args
    if {![dict exists $args -bd] && ![dict exists $args -borderwidth]} {
        set bd [winfo pixels $path 0.25m]
        if {$bd < 1} {
            set bd 1
        } elseif {$bd > 2} {
            set bd 2
        }
        $path configure -borderwidth $bd
    }
    if {![dict exists $args -ibd] && ![dict exists $args -internalborderwidth]} {
        $path configure -internalborderwidth [winfo pixels $path 2m]
    }
    return $path
}

##########################################################################

proc Spinbox {path from to incr textvar args} {
    spinbox $path -from $from \
                  -to $to \
                  -increment $incr \
                  -buttoncursor left_ptr \
                  -textvariable $textvar \
                  {*}$args
}

##########################################################################

if {$::tcl_platform(platform) ne "unix" || $::aquaP} {
    auto_load SelectFont

    rename SelectFont::create SelectFont::create:old

    proc SelectFont::create {path args} {
        SelectFont::create:old $path {*}$args

        foreach style {bold italic underline overstrike} {
            if {![catch { set bd [option get $path.$style \
                                      borderWidth Button] }]} {
                if {$bd ne ""} {
                    $path.$style configure -borderwidth $bd
                }
            }
        }
        return $path
    }
}

##########################################################################

proc BWidget::bindMouseWheel {widget} {}

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

##########################################################################

auto_load Dialog

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
    if {$parent eq ""} {
        set parent .
    }
    if {![winfo viewable [winfo toplevel $parent]] } {
        set transient 0
    }
    set res [Dialog::create:old $path -transient $transient {*}$newargs]
    $path.frame configure -padx 0.5m -pady 0.5m
    return $res
}

##########################################################################

proc Labelframe {path args} {
    if {[dict exists $args -padding]} {
        lassign [dict get $args -padding] padx pady
        set args [dict remove $args -padding]
        set args [dict replace $args -padx $padx -pady $pady]
    }
    labelframe $path {*}$args
}

##########################################################################

proc Wrapped {w} {
    return $w
}

##########################################################################

proc Progressbar {path args} {
    if {[dict exists $args -mode]} {
        switch -- [dict get $args -mode] {
            determinate {
                dict set args -type normal
            }
            indeterminate {
                dict set args -type nonincremental_infinite
            }
        }
        set args [dict remove $args -mode]
    }
    ProgressBar $path {*}$args
}

##########################################################################

interp alias {} Checkbutton     {} checkbutton
interp alias {} Radiobutton     {} radiobutton
interp alias {} Message         {} message
interp alias {} Listbox         {} listbox
interp alias {} Toplevel        {} toplevel
interp alias {} Text            {} text
interp alias {} Canvas          {} canvas
interp alias {} Frame           {} frame
interp alias {} Menubutton      {} menubutton
interp alias {} MenuToolbutton  {} menubutton
interp alias {} Scale           {} scale
interp alias {} Scrollbar       {} scrollbar

# vim:ft=tcl:ts=8:sw=4:sts=4:et
