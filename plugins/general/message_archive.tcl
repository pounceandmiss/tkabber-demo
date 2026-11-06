# message_archive.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which stores normal messages into an archive and aloows user to
#       browse through it.

option add *Messages.listheight 10 widgetDefault

namespace eval ::message_archive {
    variable logdir [file join $::configdir logs]

    if {![file exists $logdir]} {
        file mkdir $logdir
    }

    variable archive_file [file join $logdir message_archive]
    variable label
    array set label [list to [::msgcat::mc "To:"] from [::msgcat::mc "From:"]]

    variable messages
}

#############################################################################

proc ::message_archive::str_to_log {str} {
    return [string map {\\ \\\\ \r \\r \n \\n} $str]
}

#############################################################################

proc ::message_archive::log_to_str {str} {
    return [string map {\\\\ \\ \\r \r \\n \n} $str]
}

#############################################################################

proc ::message_archive::log_message {from to subject body x} {
    variable archive_file

    set seconds [::xmpp::xml::getAttr [::xmpp::delay::parse $x] seconds]
    set ts [clock format $seconds -format "%Y%m%dT%H%M%S"]

    set fd [open $archive_file a]
    fconfigure $fd -encoding utf-8
    puts $fd [str_to_log [list timestamp $ts id $ts[rand 10000] from $from to $to subject $subject body $body]]
    close $fd
}

proc ::message_archive::show_archive {} {
    variable label
    variable messages

    set w .message_archive
    if {[winfo exists $w]} {
        return
    }

    add_win $w -title [::msgcat::mc "Messages"] \
            -tabtitle [::msgcat::mc "Messages"] \
            -class Messages \
            -raise 1

    PanedWin $w.pw -orient vertical
    pack $w.pw -fill both -expand yes

    set uw [PanedWinAdd $w.pw -weight 1]
    set dw [PanedWinAdd $w.pw -weight 1]

    Frame $dw.title
    Label $dw.title.label -text $label(from)
    Label $dw.title.jid
    pack $dw.title -fill x
    pack $dw.title.label -side left
    pack $dw.title.jid -side left

    Frame $dw.subject
    Label $dw.subject.lsubj -text [::msgcat::mc "Subject:"]
    Label $dw.subject.subj
    pack $dw.subject -fill x
    pack $dw.subject.lsubj -side left
    pack $dw.subject.subj -side left

    set body [ScrolledWindow $dw.sw]
    Text $body.body -height 20 -state disabled -wrap word
    pack $body -expand yes -fill both -anchor nw
    $body setwidget $body.body
    ::richtext::config $body.body -using {url emoticon stylecode}

    set sww [ScrolledWindow $w.items]

    set height [option get $w listheight Messages]
    ::mclistbox::mclistbox $sww.listbox \
            -width 90 \
            -height $height
    set l $sww.listbox

    pack $sww -expand yes -fill both -anchor nw -in $uw
    $sww setwidget $l

    bindtags $l [list [winfo class $l] $l [winfo toplevel $l] all]

    bind $l <<ListboxSelect>> [namespace code [list print_body_selected [double% $dw] [double% $l]]]

#    bind $l <<ContextMenu>> "event generate [double% $l] <1>
#                 after idle {[namespace current]::popup_menu_selected [double% $dw] [double% $l]}"

    bindscroll $sww $l

    $l column add N -label [::msgcat::mc #]
    $l column add id -label "" -visible 0
    $l column add timestamp -label [::msgcat::mc Received/Sent]
    $l column add dir -label [::msgcat::mc Dir]
    $l column add fromto -label [::msgcat::mc From/To]
    $l column add subject -label [::msgcat::mc Subject]

    array unset messages

    foreach var {timestamp dir fromto subject} {
        $l column configure $var -image search/sort/noArrow \
                                 -command [list search::Sort $l $var]
    }

    $l column add lastcol -label "" -width 0
    $l configure -fillcolumn lastcol

    fill_list $l

    $l show end
    $l sel clear 0 end
    $l sel set end
}

proc ::message_archive::fill_list {l} {
    variable archive_file

    if {![file exists $archive_file]} {
        return
    }

    foreach i {N timestamp dir fromto subject} {
        set w [string length [$l column cget $i -label]]
        incr w 5
        $l column configure $i -width $w
    }

    set hist {}
    set fd [open $archive_file r]
    fconfigure $fd -encoding utf-8
    while {[gets $fd line] > 0} {
        catch {fill_row $l [log_to_str $line]}
    }
    close $fd
}

proc ::message_archive::fill_row {l var} {
    variable messages

    set connections [connections]
    if {[llength $connections] == 0} {
        set myjid ""
    } else {
        set myjid [connection_bare_jid [lindex $connections 0]]
    }

    foreach i {N timestamp dir fromto subject} {
        set width($i) 0
    }

    set row {}

    array unset tmp
    array set tmp $var
    if {[info exists tmp(id)]} {
        set id $tmp(id)
        lappend row $id
    } else {
        return
    }
    if {[info exists tmp(timestamp)]} {
        set seconds [clock scan $tmp(timestamp) -gmt 0]
        set str [clock format $seconds -format {%Y-%m-%d %X}]
        lappend row $str
        set width(timestamp) [string length $str]
    } else {
        lappend row {}
    }
    set q 0
    if {[info exists tmp(from)]} {
        set str [::xmpp::jid::removeResource $tmp(from)]
        if {$str == $myjid} {
            set q 1
            set fromto to
            set dir "->"
            set messages($id,dir) to
        }
    } else {
        set tmp(from) {}
    }
    if {[info exists tmp(to)]} {
        set str [::xmpp::jid::removeResource $tmp(to)]
        if {$str == $myjid} {
            set q 1
            set fromto from
            set dir "<-"
            set messages($id,dir) from
        }
    } else {
        set tmp(to) {}
    }
    set width(dir) [string length $dir]
    if {!$q} {
        return
    } else {
        lappend row $dir
        set str [::xmpp::jid::removeResource $tmp($fromto)]
        lappend row $str
        set width(fromto) [string length $str]
        set messages($id,fromto) $tmp($fromto)
    }
    if {[info exists tmp(subject)]} {
        lappend row $tmp(subject)
        set width(subject) [string length $tmp(subject)]
        set messages($id,subject) $tmp(subject)
    } else {
        lappend row {}
        set messages($id,subject) ""
    }
    if {[info exists tmp(body)]} {
        set messages($id,body) $tmp(body)
    } else {
        set messages($id,body) ""
    }

    set rownum [$l size]
    incr rownum
    set width(N) [string length $rownum]
    set row [linsert $row 0 $rownum]

    foreach i {N timestamp dir fromto subject} {
        set width($i) [::tcl::mathfunc::max [$l column cget $i -width] [expr {$width($i) + 2}]]
    }

    $l insert end $row

    foreach i {N timestamp dir fromto subject} {
        $l column configure $i -width $width($i)
    }
}

proc ::message_archive::sort {l tag} {
    set image [$l column cget $tag -image]
    if {$image eq ""} return

    set data [$l get 0 end]
    set index [lsearch -exact [$l column names] $tag]
    if {$image eq "search/sort/downArrow"} {
        set result [lsort -decreasing -dictionary -index $index $data]
        $l column configure $tag -image search/sort/upArrow
    } else {
        set result [lsort -dictionary -index $index $data]
        $l column configure $tag -image search/sort/downArrow
    }
    foreach t {timestamp dir fromto subject} {
        if {$t ne $tag} {
            $l column configure $t -image search/sort/noArrow
        }
    }
    set i 0
    foreach row $result {
        lset result $i 0 [incr i]

    }
    $l delete 0 end
    $l insert end {*}$result
}

proc ::message_archive::print_body_selected {w l} {
    variable label
    variable messages

    set curselection [$l curselection]
    if {[llength $curselection] == 0} return

    set id [lindex [$l get [lindex $curselection 0]] 1]
    if {$id == ""} {
        return
    }

    $w.title.label configure -text $label($messages($id,dir))
    $w.title.jid configure -text $messages($id,fromto)
    $w.subject.subj configure -text $messages($id,subject)

    $w.sw.body configure -state normal
    $w.sw.body delete 0.0 end
    ::richtext::render_message $w.sw.body $messages($id,body) ""
    $w.sw.body configure -state disabled
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
