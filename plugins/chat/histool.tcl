# histool.tcl --
#
#       History tool -- allows browsing and searching through Tkabber chat logs.

option add *ChatHistory.geometry          [winfo pixels . 18c]x[winfo pixels . 15c] widgetDefault
option add *ChatHistory.oddBackground     ""        widgetDefault
option add *ChatHistory.evenBackground    ""        widgetDefault
option add *ChatHistory.bodyForeground    ""        widgetDefault
if {$::darktheme} {
    option add *ChatHistory.headerForeground  steelblue1  widgetDefault
    option add *ChatHistory.warningForeground coral3      widgetDefault
} else {
    option add *ChatHistory.headerForeground  dodgerblue4 widgetDefault
    option add *ChatHistory.warningForeground firebrick   widgetDefault
}

event add <<TreeDefaultNodeAction>> <KeyPress-Return>
event add <<TreeStepUp>> <KeyPress-BackSpace>

namespace eval histool {
    hook::add finload_hook [namespace current]::on_init
}

proc histool::on_init {} {
    set m [.mainframe getmenu services]
    set idx [$m index [::msgcat::mc "Service Discovery"]]
    $m insert [expr {$idx + 2}] command \
       -label [::msgcat::mc "Chats history"] \
       -command [namespace current]::browse
}

proc histool::browse args {
    if {[is_unsupported]} {
        NonmodalMessageDlg [epath] \
                -aspect 50000 \
                -icon error \
                -title [::msgcat::mc "Error"] \
                -message [::msgcat::mc "Unsupported log dir format"]
        return
    }

    set w .histool
    if {[winfo exists $w]} {
        focus -force $w
        return
    }

    browser_create $w
}

proc histool::browser_create {w} {
    variable loghier [get_log_hier]

    add_win $w \
            -title [::msgcat::mc "Chats History"] \
            -tabtitle [::msgcat::mc "Chats history"] \
            -class ChatHistory \
            -raise 1

    set nb [Notebook $w.nb]

    bind $nb <Destroy> +[list [namespace current]::browser_cleanup]

    set p [$nb insert end jidlist \
               -text [::msgcat::mc "JID list"] \
               -raisecmd [list [namespace current]::jidlist_raise $nb]]
    jidlist_create $p

    set p [$nb insert end ltree \
               -text [::msgcat::mc "Logs"] \
               -raisecmd [list [namespace current]::ltree_raise $nb]]
    ltree_create $p

    set p [$nb insert end ftsearch \
               -text [::msgcat::mc "Full-text search"] \
               -raisecmd [list [namespace current]::ftsearch_raise $nb]]
    ftsearch_create $p -mainwindow $w

    pack $nb -fill both -expand true

    $nb raise jidlist
}

proc histool::browser_cleanup {} {
    variable loghier
    unset loghier
}

################################################################

proc histool::jidlist_create {w} {
    variable loghier

    grid columnconfigure $w 0 -weight 1

    set sw [ScrolledWindow $w.sw]

    set lbox [Listbox $w.lbox -takefocus 1 -exportselection 0]
    $lbox selection clear 0 end
    $lbox selection set 0
    focus $lbox

    # Workaround for a bug in listbox (can't get focus on mouse clicks):
    bind Listbox <Button-1> {+ if {[winfo exists %W]} {focus %W}}

    bind $lbox <Double-Button-1> [namespace code {
        jidlist_open_log %W [%W nearest %y]
    }]

    bind $lbox <Return> [namespace code {
        jidlist_open_log %W [%W index active]
    }]

    $sw setwidget $lbox
    grid $sw -sticky news
    grid rowconfigure $w 0 -weight 1

    foreach jid [sort_jids [get_jids $loghier] -order {server node resource}] {
        $lbox insert end $jid
    }

    # Setup searching:

    set sp [::plugins::search::spanel $w.spanel \
            -defaultdirection up \
            -searchcommand [list ::plugins::search::listbox::do_search $lbox] \
            -closecommand  [list [namespace current]::jidlist_spanel_close $lbox]]

    bind $lbox <<OpenSearchPanel>> \
         [double% [list [namespace current]::jidlist_spanel_open $w $sp]]
}

proc histool::jidlist_open_log {w idx args} {
    variable loghier

    set jid [$w get $idx]
    set subdirs [get_subdirs of $loghier for $jid]

    ::logger::show_log $jid -subdirs $subdirs
}

proc histool::jidlist_spanel_open {w sp} {
    grid $sp -sticky we
}

proc histool::jidlist_spanel_close {lbox w} {
    grid forget $w
    focus $lbox
}

################################################################

proc histool::ltree_create {w} {
    variable loghier
    variable ::logger::d2m

    set sw [ScrolledWindow $w.sw]

    set t [MyTree $w.tree]

    $sw setwidget $t
    pack $sw -fill both -expand yes

    $t tag bind Text <Double-Button-1> \
        [list [namespace current]::ltree_for_node [double% $t] ltree_node_action]

    if {[winfo exists $t.c]} {
        # Keyboard bindings don't work in BWidget Tree's bindText;
        # HACK: Tree.c widget is what receives keyboard events:

        bind $t.c <<TreeDefaultNodeAction>> \
             [list [namespace current]::ltree_for_node [double% $t] ltree_node_action]
        bind $t.c <<TreeStepUp>> \
             [list [namespace current]::ltree_for_node [double% $t] ltree_step_up]
    } else {
        $t tag bind Text <<TreeDefaultNodeAction>> \
             [list [namespace current]::ltree_for_node [double% $t] ltree_node_action]
        $t tag bind Text <<TreeStepUp>> \
             [list [namespace current]::ltree_for_node [double% $t] ltree_step_up]
    }

    [namespace parent]::search::browser::setup_panel $w $sw $t

    set counter 0
    foreach LA [lsort -index 0 $loghier] {
        lassign $LA year months
        $t insert {} end -id .$year -text $year -tags {Text}
        foreach LB [lsort -index 0 $months] {
            lassign $LB month jids
            $t insert .$year end -id .$year.$month -text $d2m($month) -tags {Text}
            foreach jid [sort_jids $jids -order {server node resource}] {
                $t insert .$year.$month end -id [incr counter] -text $jid -tags {Text}
            }
        }
    }
}

proc histool::ltree_for_node {t command} {
    set node [lindex [$t selection] 0]
    if {$node eq ""} return

    {*}$command $t $node
}

proc histool::ltree_node_action {t n} {
    variable loghier

    if {[tree_node_is_leaf $t $n]} {
        variable ::logger::m2d
        set mn [$t parent $n]
        set yn [$t parent $mn]
        set year [$t item $yn -text]
        set month $m2d([$t item $mn -text])
        set jid [$t item $n -text]
        ::logger::show_log $jid -when $year-$month \
            -subdirs [get_subdirs of $loghier for $jid]
    } elseif {[winfo exists $t.c]} {
        $t item $n -open [expr {![$t item $n -open]}]
        $t selection set [list $n]
    }
}

proc histool::tree_node_is_leaf {t n} {
    string equal [lindex [$t children $n] 0] ""
}

proc histool::ltree_step_up {t n} {
    set p [$t parent $n]
    if {[string equal $p {}]} return

    $t item $p -open [expr {![$t item $p -open]}]
    $t selection set [list $p]
    catch {$t focus $n}
}

################################################################

proc histool::ftsearch_create {w args} {
    variable loghier
    variable ftsearch

    grid columnconfigure $w 0 -weight 1

    set sp $w.spanel
    ::plugins::search::spanel $sp \
        -allowclose no \
        -twoway no \
        -searchcommand [namespace current]::ftsearch_do_search \
        -stopcommand   [namespace current]::ftsearch_cancel_search
    grid $sp -sticky we

    set sw [ScrolledWindow $w.sw]
    set r [Text $w.results -cursor "" -state disabled]
    $sw setwidget $r
    grid $sw -sticky news
    grid rowconfigure $w 1 -weight 1

    set f [frame $w.cf -class Chat]
    $r tag configure they -foreground [option get $f theyforeground Chat]
    $r tag configure me -foreground [option get $f meforeground Chat]
    $r tag configure server_lab \
        -foreground [option get $f serverlabelforeground Chat]
    $r tag configure server \
        -foreground [option get $f serverforeground Chat]
    destroy $f

    bind [Wrapped $r] <Double-Button-1> [namespace code {
        ftsearch_open_log %W %x %y
        break
    }]

    set ix [lsearch $args -mainwindow]
    if {$ix >= 0} {
        set mw [lindex $args [incr ix]]
        if {$mw != ""} {
            set val [option get $mw oddBackground ChatHistory]
            if {$val != ""} { $r tag configure ODD -background $val }
            set val [option get $mw evenBackground ChatHistory]
            if {$val != ""} { $r tag configure EVEN -background $val }

            set val [option get $mw headerForeground ChatHistory]
            if {$val != ""} { $r tag configure HEADER -foreground $val }
            set val [option get $mw bodyForeground ChatHistory]
            if {$val != ""} { $r tag configure BODY -background $val }

            set val [option get $mw warningForeground ChatHistory]
            if {$val != ""} { $r tag configure WARNING -foreground $val }
        }
    }

    set ftsearch(last) ""
    set ftsearch(results) $r
    set ftsearch(bg) EVEN

    bind $w <Destroy> +[list [namespace current]::ftsearch_cleanup]

    # Set search panel up:

    # TODO remove when fixed elsewhere.
    # See also [ftsearch_spanel_close]
    $r mark set sel_start end
    $r mark set sel_end   1.0

    set asp [::plugins::search::spanel $w.auxspanel \
            -defaultdirection up \
            -searchcommand [list ::plugins::search::do_text_search $r] \
            -closecommand  [list [namespace current]::ftsearch_spanel_close $r $sp.sentry]]

    bind $sp.sentry <<OpenSearchPanel>> \
         [list [namespace current]::ftsearch_spanel_open [double% $w] [double% $asp]]
}

# Schedules an execution of a script produced by concatenating
# the words of $args using the # [after idle [after 0 [list ...]]]
# concept presented at http://mini.net/tcl/1526
# The idea is that some parts of Tk wait for all idle event
# handlers to complete. So, when executes, our idle event handler
# installed in [schedule] installs timed event handler that
# will be executed ASAP, and since it's not an idle event, it
# allows the event queue to be in a state free of scheduled
# idle events (thus allowing Tk to do its job, keeping GUI alive).
proc histool::schedule args {
    after idle [list after 0 $args]
}

# Must be used as the (almost) first command inside any procs
# scheduled as [after ...] callbacks installed in the course
# of performing full-text search.
proc histool::ftsearch_can_proceed {} {
    variable ftsearch_terminate

    if {$ftsearch_terminate} {
        unset ftsearch_terminate
        return false
    } else {
        return true
    }
}

# This proc builds a list of log files to grep and then starts
# an asynchronous searching through them
proc histool::ftsearch_do_search {what dir args} {
    variable loghier
    variable ftsearch
    variable ftsearch_terminate false

    # Returning false means we refuse to start searching:
    if {$what == ""} { return 0 }
    if {[string equal $ftsearch(last) $what]} { return 0 }

    set ftsearch(now) $what
    set ftsearch(found) 0

    set r $ftsearch(results)
    $r configure -state normal
    $r delete 1.0 end
    $r configure -state normal

    set slist {}
    foreach LA [lsort -index 0 $loghier] {
        lassign $LA year months
        foreach LB [lsort -index 0 $months] {
            lassign $LB month jids
            foreach jid $jids {
                lappend slist [list $year $month $jid]
            }
        }
    }

    set ix [lsearch $args -completioncommand]
    if {$ix >= 0} {
        set ftsearch(compcmd) [lindex $args [incr ix]]
    } else {
        set ftsearch(compcmd) ""
    }

    # will return almost immediately:
    ftsearch_grep_next of $slist for $what

    return 1 ;# signalize we've started the search process
}

# Tries to open the last file in the $slist and schedules
# the execution of a handler that will read that file
# looking for $what
proc histool::ftsearch_grep_next {"of" slist "for" what args} {
    if {![ftsearch_can_proceed]} return

    variable ftsearch
    variable ::logger::options

    # Some files are unreadable due to some reason, so we loop
    # over the list of them until opening succeeds or the list
    # is exhausted:
    while true {
        lassign [lindex $slist end] year month jid
        set fname [file join $options(logdir) \
            $year $month [::logger::jid_to_filename $jid]]
        if {[catch {open $fname} chan]} {
            set r $ftsearch(results)
            $r configure -state normal
            $r insert end [::msgcat::mc "WARNING: %s\n" $chan] WARNING
            $r configure -state disabled

            set slist [lrange $slist 0 end-1]
            if {[llength $slist] > 0} {
                continue
            } else {
                ftsearch_complete_search for $what
                return
            }
        } else break
    }

    fconfigure $chan -encoding utf-8

    schedule \
        [namespace current]::ftsearch_grep_msg of $slist for $what from $chan
}

# Reads one line from a log file opened as $chan, parses it, looks
# for $what in the relevant parts of the aqcuired message, renders
# it if it match.
# Searching conditions are checked: this proc is either re-schedules
# its execution (for the next line of the log file) or schedules the
# reading of the next log file or completes the searching process.
proc histool::ftsearch_grep_msg {"of" slist "for" what "from" chan} {
    if {![ftsearch_can_proceed]} return

    variable ftsearch

    set line [gets $chan]

    if {![eof $chan]} {
        set msg [::logger::log_to_str $line]
        if {![catch {array set mparts $msg}]} {
            foreach part {nick body} {
                if {[info exists mparts($part)] && \
                        [::plugins::search::match $what $mparts($part)]} {
                    lassign [lindex $slist end] year month jid
                    set r $ftsearch(results)
                    $r configure -state normal
                    ftsearch_render_msg $r $year $month $jid $msg
                    $r configure -state disabled
                    set ftsearch(found) 1
                    break
                }
            }
        }
        schedule \
            [namespace current]::ftsearch_grep_msg of $slist for $what from $chan
    } else {
        close $chan

        set rem [lrange $slist 0 end-1]
        if {[llength $rem] > 0} {
            schedule \
                [namespace current]::ftsearch_grep_next of $rem for $what
        } else {
            ftsearch_complete_search for $what
        }
    }
}

proc histool::ftsearch_render_msg {t year month jid msg} {
    variable ftsearch

    set tags [list $ftsearch(bg) YEAR-$year MONTH-$month JID-$jid]

    set mynick [get_group_nick "" $jid]

    if {[catch {array set mparts $msg}]} return

    set start [$t index {end - 1 char}]

    set header $jid

    if {[info exists mparts(timestamp)] && $mparts(timestamp) != ""} {
        set ts [::logger::formatxmppts $mparts(timestamp)]
        append header " \[$ts\]"
        lappend tags TS-$mparts(timestamp)
    }

    if {[info exists mparts(jid)] && $mparts(jid) == ""} {
        append header " " [::msgcat::mc "Client message"]
    } elseif {[info exists mparts(nick)]} {
        if {$mparts(nick) == ""} {
            append header " " [::msgcat::mc "Server message"]
        } else {
            append header " " [::msgcat::mc "From:"] " " $mparts(nick)
        }
    }
    $t insert end $header\n HEADER
    $t insert end $mparts(body)\n BODY

    set end [$t index {end - 1 char}]

    foreach tag $tags {
        $t tag add $tag $start $end
    }

    if {[string equal $ftsearch(bg) EVEN]} {
        set ftsearch(bg) ODD
    } else {
        set ftsearch(bg) EVEN
    }
}

proc histool::ftsearch_complete_search {"for" what} {
    variable ftsearch

    set ftsearch(now) ""
    set ftsearch(last) $what

    if {$ftsearch(compcmd) ne ""} {
        {*}$ftsearch(compcmd) {*}$ftsearch(found)
    }
}

proc histool::ftsearch_cancel_search {args} {
    variable ftsearch
    variable ftsearch_terminate true

    set ftsearch(last) $ftsearch(now)
    set ftsearch(now) ""

    if {$ftsearch(compcmd) ne ""} {
        {*}$ftsearch(compcmd) {*}$ftsearch(found)
    }
}

proc histool::ftsearch_open_log {t x y} {
    variable loghier

    set year   ""
    set month  ""
    set ts     ""
    set jid    ""

    foreach tag [$t tag names @$x,$y] {
        if {[string match YEAR-* $tag]} {
            set year [string range $tag 5 end]
        }
        if {[string match MONTH-* $tag]} {
            set month [string range $tag 6 end]
        }
        if {[string match TS-* $tag]} {
            set ts [string range $tag 3 end]
        }
        if {[string match JID-* $tag]} {
            set jid [string range $tag 4 end]
        }
    }

    if {$jid eq ""} return

    set args {}
    if {$year ne "" && $month ne ""} {
        lappend args -when $year-$month
        if {$ts ne ""} {
            lappend args -timestamp $ts
        }
    }

    lappend args -subdirs [get_subdirs of $loghier for $jid]

    :logger::show_log $jid {*}$args
}

proc histool::ftsearch_spanel_open {w sp} {
    grid $sp -sticky we
}

proc histool::ftsearch_spanel_close {t sentry w} {
    # TODO remove when fixed elsewhere.
    # See also [ftsearch_create]
    $t tag remove search_highlight 0.0 end
    $t mark set sel_start end
    $t mark set sel_end 0.0

    grid forget $w
    focus $sentry
}

# Cleans up relevant variables when the browser form
# is destroyed. "ftsearch_terminate" variable is
# unset in the [after ...] event handler, if such
# handler is installed.
proc histool::ftsearch_cleanup {} {
    variable ftsearch
    array unset ftsearch

    variable ftsearch_terminate
    if {[info exists ftsearch_terminate]} {
        set ftsearch_terminate true
    }
}

################################################################

proc histool::jidlist_raise {nb} {
    set lbox [$nb getframe jidlist].lbox
    if {[winfo exists $lbox]} {
        focus $lbox
    }
}

proc histool::ltree_raise {nb} {
    set tree [$nb getframe ltree].tree
    if {[winfo exists $tree]} {
        focus $tree
    }
}

proc histool::ftsearch_raise {nb} {
}

# Sorts a list of JIDs based on their parts: node, server and resource.
# The default comparison order is: server, node, resource.
# Optional argument/value pairs are accepted:
# -order LIST -- override the default comparison order.
proc histool::sort_jids {jids args} {
    set order {server node resource}
    foreach {opt val} $args {
        switch -- $opt {
            -order { set order $val }
            default { error "invalid option: $opt" }
        }
    }

    set norder {}
    foreach part {node server resource} {
        lappend norder [lsearch $order $part]
    }

    set items {}
    foreach jid $jids {
        ::xmpp::jid::split $jid node server resource
        set parts [list $node $server $resource]
        set ordered [list \
            [lindex $parts [lindex $norder 0]] \
            [lindex $parts [lindex $norder 1]] \
            [lindex $parts [lindex $norder 2]] \
        ]
        set pat [join $ordered \u0000]
        lappend items [list $pat $jid]
    }

    set sorted {}
    foreach item [lsort -index 0 -dictionary $items] {
        lappend sorted [lindex $item 1]
    }

    set sorted
}

proc histool::is_unsupported {} {
    variable ::logger::options

    catch {
        set fd [open [file join $options(logdir) version]]
        if {![package vsatisfies [gets $fd] 1.0]} {
            close $fd
            error "unsupported log dir structure format"
        }
        close $fd
    }
}

proc histool::get_log_hier {} {
    variable ::logger::options

    set LA {}
    foreach dyear [glob -nocomplain -type d -directory $options(logdir) *] {
        set year [file tail $dyear]
        if {![regexp {^\d{4}$} $year]} continue
        set LB {}
        foreach dmonth [glob -nocomplain -type d -directory $dyear *] {
            set month [file tail $dmonth]
            if {![regexp {^0[1-9]$|^1[0-2]$} $month]} continue
            set LC {}
            foreach file [glob -nocomplain -type f -directory $dmonth *] {
                lappend LC [::logger::filename_to_jid [file tail $file]]
            }
            lappend LB [list $month $LC]
        }
        lappend LA [list $year $LB]
    }

    set LA
}

proc histool::get_jids {loghier} {
    foreach LA $loghier {
        foreach LB [lindex $LA 1] {
            foreach jid [lindex $LB 1] {
                set jids($jid) ""
            }
        }
    }

    array names jids
}

# From the log hierarchy given by $loghier builds a list of
# YEAR-MONTH entries producing the same structure that
# is generated by [::logger::get_subdirs].
# See plugins/chat/logger.tcl
proc histool::get_subdirs {"of" loghier "for" jid} {
    set subdirs {}

    foreach LA $loghier {
        lassign $LA year months
        foreach LB $months {
            lassign $LB month jids
            if {$jid in $jids} {
                lappend subdirs $year-$month
            }
        }
    }

    set subdirs
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
