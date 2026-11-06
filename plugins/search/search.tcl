# search.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       implements searching in various widgets.

if {$::darktheme} {
    option add *highlightSearchBackground PaleGreen4 widgetDefaul
} else {
    option add *highlightSearchBackground PaleGreen1 widgetDefaul
}

##########################################################################

namespace eval search {
    custom::defgroup Plugins [::msgcat::mc "Plugins options."] \
        -group Tkabber

    custom::defgroup Search \
        [::msgcat::mc "Search in Tkabber windows options."] \
        -group Plugins

    custom::defvar options(case) 0 \
        [::msgcat::mc "Match case while searching in chat, log or disco windows."] \
        -type boolean -group Search

    custom::defvar options(mode) substring \
        [::msgcat::mc "Specifies search mode while searching in chat, log or\
                       disco windows. \"substring\" searches exact substring,\
                       \"glob\" uses glob style matching, \"regexp\" allows\
                       to match regular expression."] \
        -type options \
        -values [list substring substring glob glob regexp regexp] \
        -group Search

    event add <<OpenSearchPanel>> <Control-s>
}

##########################################################################

proc search::valid_input {val} {
    variable options

    expr {$options(mode) ne "regexp" || ![catch {regexp -- $val {}}]}
}

proc search::validate_entry {w val} {
    if {![catch {Widget::theme}] && [Widget::theme]} {
        set style TEntry
        if {[string match *notfound* [$w configure -style]]} {
            set style notfound.$style
        }
        if {![valid_input $val]} {
            set style invalid.$style
        }
        $w configure -style $style
    } else {
        if {[valid_input $val]} {
            $w configure -foreground [option get $w foreground Entry]
        } else {
            $w configure -foreground [option get $w errorForeground Entry]
        }
    }

    return 1
}

##########################################################################
# Search in text widget

proc search::glob2regexp {pattern} {
    string map {\\* \\*
                \\? \\?
                \\[ \\[
                *   .*
                ?   .
                [^] \\^
                [^  [\\^
                [!  [^
                |   \\|
                +   \\+
                (   \\(
                )   \\)
                $   \\$
                .   \\.
                \"   \\"} $pattern
}

proc search::do_text_search {txt pattern dir} {
    variable options

    if {![string length $pattern]} {
        return 0
    }

    if {$dir == "up"} {
        set search_from sel_start
        set search_to   0.0
        set search_dir  -backwards
    } else {
        set search_from "sel_start +1char"
        set search_to        end
        set search_dir  -forwards
    }

    set args [list $search_dir]
    set cargs {}
    if {!$options(case)} {
        lappend args -nocase
        lappend cargs -nocase
    }

    switch -- $options(mode) {
        regexp {
            set exact -regexp
        }
        glob {
            set exact -regexp
            set pattern [glob2regexp $pattern]
        }
        default {
            set exact -exact
        }
    }
    lappend args $exact

    if {[catch { $txt search {*}$args -- $pattern $search_from } index]} {
        set index {}
    }

    if {![string length $index]} {
         return 0
    } else {
        $txt tag remove search_highlight 0.0 end
        if {$exact eq "-regexp"} {
            set line [$txt get $index "$index lineend"]
            regexp {*}$cargs -- $pattern $line match
            $txt tag add search_highlight $index "$index + [string length $match] chars"
            if {[string length $match] == 0} {
                set nohighlight 1
            } else {
                set nohighlight 0
            }
        } else {
            $txt tag add search_highlight $index "$index + [string length $pattern] chars"
            if {[string length $pattern] == 0} {
                set nohighlight 1
            } else {
                set nohighlight 0
            }
        }
        if {!$nohighlight} {
            $txt tag configure search_highlight -background \
                [option get $txt highlightSearchBackground Text]
            $txt mark set sel_start search_highlight.first
            $txt mark set sel_end search_highlight.last
            $txt see $index
            return 1
        }
    }
}

##########################################################################
# Search in MyTree widget

# Searches $where for $what using global searching options.
# Returns: 1 if found, 0 otherwise.
proc search::match {what where} {
    variable options

    if {$options(mode) == "substring"} {
        regsub -all {([*?\[\]\\])} $what {\\\1} what
    }

    if {$options(case)} {
        set cargs {}
    } else {
        set cargs {-nocase}
    }

    switch -- $options(mode) {
        substring -
        glob {
            return [string match {*}$cargs *$what* $where]
        }
        regexp {
            if {[catch {regexp {*}$cargs -- $what $where} res]} {
                return 0
            } else {
                return $res
            }
        }
        exact {
            return [string equal {*}$cargs $what $where]
        }
    }

    return 0
}

##########################################################################
##########################################################################

namespace eval search::bwtree {}

##########################################################################
# Find "next" tree node
#

proc search::bwtree::next_node {t node} {
    if {[set child [lindex [$t children $node] 0]] != ""} {
        return $child
    } else {
        while {$node != ""} {
            set parent [$t parent $node]
            set siblings [$t children $parent]
            set idx [lsearch -exact $siblings $node]
            if {$idx < 0} {
                # This should not happen
                return $parent
            }
            set next_sibling [lindex $siblings [expr {$idx + 1}]]
            if {$next_sibling != ""} {
                return $next_sibling
            }
            set node $parent
        }
        return {}
    }
}

##########################################################################
# Find "previous" tree node
#

proc search::bwtree::prev_node {t node} {
    if {$node != ""} {
        set parent [$t parent $node]
        set siblings [$t children $parent]
        set idx [lsearch -exact $siblings $node]
        if {$idx < 0} {
            # This should not happen
            return $parent
        }
        set prev_sibling [lindex $siblings [expr {$idx - 1}]]
        if {$prev_sibling == ""} {
            return $parent
        } else {
            return [go_down $t $prev_sibling]
        }
    } else {
        return [go_down $t $node]
    }
}

proc search::bwtree::go_down {t node} {
    while {[set child [lindex [$t children $node] end]] != ""} {
        set node $child
    }
    return $node
}

##########################################################################

proc search::bwtree::search_node {t next_node node what} {
    set n $node
    while {[set n [$next_node $t $n]] != $node} {
        if {$n != {} && \
                [[namespace parent]::match $what [$t item $n -text]]} {
            return $n
        }
    }
    if {$n != {} && \
            [[namespace parent]::match $what [$t item $n -text]]} {
        return $n
    }
    return ""
}

##########################################################################

proc search::bwtree::do_search {tw pattern dir} {
    if {![string length $pattern]} {
        return 0
    }

    if {$dir == "up"} {
        set start_node [lindex [$tw selection] 0]
        set node [search_node $tw \
                              [namespace current]::prev_node \
                              $start_node \
                              $pattern]
    } else {
        set start_node [lindex [$tw selection] end]
        set node [search_node $tw \
                              [namespace current]::next_node \
                              $start_node \
                              $pattern]
    }

    if {$node != ""} {
        search_hilite $tw $node
        return 1
    } else {
        return 0
    }
}

##########################################################################

proc search::bwtree::search_hilite {t node} {
    tree_openpath $t $node

    $t selection set [list $node]
    event generate $t <<TreeviewSelect>>
    $t see $node
}

proc search::bwtree::tree_openpath {t node} {
    variable state

    set node [$t parent $node]
    while {$node != {}} {
        $t item $node -open 1
        set node [$t parent $node]
    }
}

##########################################################################
##########################################################################
# Support for searching in listbox widgets for Tkabber.

namespace eval search::listbox {}

##########################################################################

proc search::listbox::do_search {w pattern dir} {
    set selection_first 0
    set selection_last [$w index end]
    for {set i 0} {$i < [$w index end]} {incr i} {
        if {[$w selection includes $i]} {
            if {$selection_first == 0} {
                set selection_first $i
            }
            set selection_last $i
        }
    }

    if {[string equal $dir down]} {
        set step   1
        set start1 [incr selection_last]
        set end1   [$w index end]
        set cond1  {$i <= $end1}
        set start2 0
        set end2   $selection_last
        set cond2  {$i < $end2}
    } else {
        set step   -1
        set start1 [incr selection_first -1]
        set end1   0
        set cond1  {$i >= $end1}
        set start2 [$w index end]
        set end2   $selection_first
        set cond2  {$i > $end2}
    }

    set found 0

    for {set i $start1} $cond1 {incr i $step} {
        if {[[namespace parent]::match $pattern [$w get $i]]} {
            set found 1
            break
        }
    }
    if {!$found} {
        for {set i $start2} $cond2 {incr i $step} {
            if {[[namespace parent]::match $pattern [$w get $i]]} {
                set found 1
                break
            }
        }
    }

    if {$found} {
        hilite $w $i
    }

    return $found
}

##########################################################################

proc search::listbox::hilite {w index} {
    $w selection clear 0 end
    $w selection set $index
    $w see $index
}

##########################################################################
##########################################################################
# Support for searching in mclistbox widgets for Tkabber.

namespace eval search::mclistbox {}

##########################################################################

proc search::mclistbox::do_search {w pattern dir} {
    set selection_first 0
    set selection_last [$w size]
    for {set i 0} {$i < [$w size]} {incr i} {
        if {[$w sel includes $i]} {
            if {$selection_first == 0} {
                set selection_first $i
            }
            set selection_last $i
        }
    }

    if {[string equal $dir down]} {
        set step   1
        set start1 [incr selection_last]
        set end1   [$w size]
        set cond1  {$i <= $end1}
        set start2 0
        set end2   $selection_last
        set cond2  {$i < $end2}
    } else {
        set step   -1
        set start1 [incr selection_first -1]
        set end1   0
        set cond1  {$i >= $end1}
        set start2 [$w size]
        set end2   $selection_first
        set cond2  {$i > $end2}
    }

    set found 0

    for {set i $start1} $cond1 {incr i $step} {
        foreach item [$w get $i] {
            if {[[namespace parent]::match $pattern $item]} {
                set found 1
                break
            }
        }
        if {$found} break
    }
    if {!$found} {
        for {set i $start2} $cond2 {incr i $step} {
            foreach item [$w get $i] {
                if {[[namespace parent]::match $pattern $item]} {
                    set found 1
                    break
                }
            }
            if {$found} break
        }
    }

    if {$found} {
        hilite $w $i
    }

    return $found
}

##########################################################################

proc search::mclistbox::hilite {w index} {
    $w sel clear 0 end
    $w sel set $index
    $w show $index
    event generate $w <<ListboxSelect>>
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
