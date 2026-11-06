# mclistbox.tcl --
#
#       This file is a part of the Tkabber XMPP client. It wraps ttk::treeview
#       into an interface similar to the Brian Oakley's mclistbox which is
#       used with plain Tk widgets. Not all mclistbox commands and options
#       are implemented.

namespace eval ::mclistbox {}

proc ::mclistbox::mclistbox {path args} {

    ttk::treeview $path -show {headings} -columns {} -displaycolumns {}

    bind $path <<TreeviewSelect>> {event generate %W <<ListboxSelect>>}

    rename ::$path ::$path#orig
    proc ::$path {command args} \
                 "::mclistbox::WidgetProc $path \$command {*}\$args"
    return $path
}

proc ::mclistbox::WidgetProc {path command args} {
    switch -- $command {
        column {
            return [ColumnProc $path {*}$args]
        }
        label {
            return [LabelProc $path {*}$args]
        }
        insert {
            return [InsertProc $path {*}$args]
        }
        delete {
            return [DeleteProc $path {*}$args]
        }
        get {
            return [GetProc $path {*}$args]
        }
        find {
            return [FindProc $path {*}$args]
        }
        configure {
            return [ConfigureProc $path {*}$args]
        }
        curselection {
            return [CurselectionProc $path {*}$args]
        }
        sel {
            return [SelectionProc $path {*}$args]
        }
        show {
            return [ShowProc $path {*}$args]
        }
        size {
            return [SizeProc $path {*}$args]
        }
        default {
            return [$path#orig $command {*}$args]
        }
    }
}

proc ::mclistbox::ConfigureProc {path args} {
    foreach {key val} $args {
        switch -- $key {
            -fillcolumn {
                $path#orig column $val -stretch 1 -minwidth 0
            }
            -xscrollcommand -
            -yscrollcommand -
            -height {
                $path#orig configure $key $val
            }
        }
    }
}

proc ::mclistbox::CgetProc {path option} {
    $path#orig cget $option
}

proc ::mclistbox::CurselectionProc {path args} {
    set items [$path#orig children {}]
    set res {}
    foreach item [$path#orig selection] {
        lappend res [lsearch -exact $items $item]
    }
    return $res
}

proc ::mclistbox::SelectionProc {path cmd args} {
    switch -- $cmd {
        set {
            lassign $args start end
            if {$end eq ""} {
                set end $start
            }
            $path#orig selection set \
                       [lrange [$path#orig children {}] $start $end]
        }
        clear {
            lassign $args start end
            if {$end eq ""} {
                set end $start
            }
            $path#orig selection remove \
                       [lrange [$path#orig children {}] $start $end]
        }
        includes {
            lassign $args index
            set item [lindex [$path#orig children {}] $index]
            return [expr {$item in [$path#orig selection]}]
        }
    }
}

proc ::mclistbox::ShowProc {path index} {
    $path#orig see [lindex [$path#orig children {}] $index]
}

proc ::mclistbox::SizeProc {path} {
    llength [$path#orig children {}]
}

proc ::mclistbox::InsertProc {path index args} {
    foreach row $args {
        $path#orig insert {} $index -values $row
        set index [expr {$index eq "end"? $index : $index + 1}]
    }
}

proc ::mclistbox::DeleteProc {path args} {
    lassign $args start end
    if {$end eq ""} {
        set end $start
    }
    $path#orig delete [lrange [$path#orig children {}] $start $end]
}

proc ::mclistbox::GetProc {path args} {
    set type list
    lassign $args start end
    if {$end eq ""} {
        set type item
        set end $start
    }
    set res {}
    foreach item [lrange [$path#orig children {}] $start $end] {
        lappend res [$path#orig item $item -values]
    }
    if {$type eq "list"} {
        return $res
    } else {
        return [lindex $res 0]
    }
}

proc ::mclistbox::FindProc {path x y} {
    set item [$path#orig identify item $x $y]
    if {$item eq ""} {
        return -1
    } else {
        return [lsearch [$path#orig children {}] $item]
    }
}

proc ::mclistbox::ColumnProc {path command args} {
    switch -- $command {
        names {
            return [$path#orig cget -columns]
        }
        add {
            return [ColumnAddProc $path {*}$args]
        }
        configure {
            return [ColumnConfigureProc $path {*}$args]
        }
        cget {
            return [ColumnCgetProc $path {*}$args]
        }
    }
}

proc ::mclistbox::ColumnAddProc {path name args} {
    set cols [$path#orig cget -columns]

    # $path configure -columns {list} destroys the columns options,
    # so, store them and restore after the configure call

    foreach c $cols {
        set head($c) [dict remove [$path#orig heading $c] -id]
        set col($c) [dict remove [$path#orig column $c] -id]
    }

    set ncols $cols
    lappend ncols $name

    set dcols [$path#orig cget -displaycolumns]
    if {![dict exists $args -visible] || [dict get $args -visible]} {
        lappend dcols $name
    }

    $path#orig configure -columns $ncols -displaycolumns $dcols

    foreach c $cols {
        $path#orig heading $c {*}$head($c)
        $path#orig column $c {*}$col($c)
    }

    $path#orig heading $name -anchor w
    $path#orig column $name -stretch 0
    ColumnConfigureProc $path $name {*}$args
}

proc ::mclistbox::ColumnConfigureProc {path name args} {
    foreach {key val} $args {
        switch -- $key {
            -label {
                $path#orig heading $name -text $val
            }
            -image -
            -command {
                $path#orig heading $name $key $val
            }
            -width {
                set font [ttk::style lookup Treeview -font {} TkDefaultFont]
                set factor [font measure $font "0"]
                set width [expr {$val * $factor}]

                $path#orig column $name -width $width
            }
        }
    }
}

proc ::mclistbox::ColumnCgetProc {path name option} {
    switch -- $option {
        -label {
            return [$path#orig heading $name -text]
        }
        -image -
        -command {
            return [$path#orig heading $name $option]
        }
        -width {
            set width [$path#orig column $name -width]
            set font [ttk::style lookup Treeview -font {} TkDefaultFont]
            set factor [font measure $font "0"]

            return [expr {int(ceil($width / $factor))}]
        }
    }
}

proc ::mclistbox::LabelProc {path command args} {
    return ""
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
