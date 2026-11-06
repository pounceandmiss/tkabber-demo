# search.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements user
#       interface part for the Jabber Search protocol (XEP-0055).

package require xmpp::search

namespace eval search {
    variable show_all 0

    create_image search/sort/upArrow -data {
        R0lGODlhDgAOAJEAANnZ2YCAgPz8/P///yH5BAEAAAAALAAAAAAOAA4AAAImhI+
        py+1LIsJHiBAh+BgmiEAJQITgW6DgUQIAECH4JN8IPqYuNxUAOw==}
    create_image search/sort/downArrow -data {
        R0lGODlhDgAOAJEAANnZ2YCAgPz8/P///yH5BAEAAAAALAAAAAAOAA4AAAInhI+
        py+1I4ocQ/IgDEYIPgYJICUCE4F+YIBolEoKPEJKZmVJK6ZACADs=}
    create_image search/sort/noArrow -height 14 -width 14
}

proc search::open {xlib jid args} {
    variable winid

    if {![info exists winid]} {
        set winid 0
    }

    set sw .search[incr winid]

    Toplevel $sw -cursor watch
    wm group $sw .
    set title [::msgcat::mc "Search in %s" $jid]
    wm title $sw $title
    wm iconname $sw $title
    wm transient $sw .
    if {$::tcl_platform(platform) == "macintosh"} {
        catch { unsupported1 style $sw floating sideTitlebar }
    } elseif {$::aquaP} {
        ::tk::unsupported::MacWindowStyle style $sw floating {closeBox}
    }
    wm resizable $sw 0 0

    wm withdraw $sw

    ButtonBox $sw.bbox -spacing 0 -padx 2m -default 0
    $sw.bbox add -text [::msgcat::mc "OK"] \
                 -command [namespace code [list Search $sw $xlib $jid false]] \
                 -state disabled
    $sw.bbox add -text [::msgcat::mc "Cancel"] \
                 -command [list destroy $sw]
    pack $sw.bbox -padx 2m -pady 2m -anchor e -side bottom

    bind $sw <Return> [list ButtonBox::invoke [double% $sw.bbox] default]
    bind $sw <Escape> [list ButtonBox::invoke [double% $sw.bbox] 1]

    Frame $sw.fields -class Search

    pack $sw.fields -expand yes -fill both -anchor nw -padx 2m -pady 2m
    bind $sw.fields <Destroy> [list data::cleanup %W]

    ::xmpp::search::request $xlib $jid \
                -command [namespace code [list RecvFields $sw $xlib $jid]]
}

proc search::RecvFields {sw xlib jid status fields args} {
    debugmsg search "$status $fields"

    if {![string equal $status ok]} {
        destroy $sw
        MessageDlg ${sw}err -aspect 50000 \
                            -icon error \
                            -message [::msgcat::mc "Search: %s" \
                                                   [error_to_string $fields]] \
                            -type user \
                            -buttons ok \
                            -default 0 \
                            -cancel 0
        return
    }

    foreach {key val} $args {
        switch -- $key {
            -old {
                $sw.bbox itemconfigure 0 \
                         -command [namespace code [list Search $sw $xlib \
                                                               $jid $val]]
            }
        }
    }

    set focus [data::fill_fields_x $sw.fields $fields]

    $sw configure -cursor {}
    $sw.bbox itemconfigure 0 -state normal

    if {$focus != ""} {
        focus $focus
    }
    update idletasks
    BWidget::place $sw 0 0 center
    wm deiconify $sw
}

proc search::Search {sw xlib jid old} {
    variable data

    $sw configure -cursor watch
    $sw.bbox itemconfigure 0 -state disabled

    set resfields [data::get_fields $sw.fields]

    ::xmpp::search::submit $xlib $jid $resfields \
            -command [namespace code [list RecvItems $sw $xlib $jid $old]] \
            -old $old
}

proc search::RecvItems {sw xlib jid old status items} {
    debugmsg search "$status $items"

    if {![winfo exists $sw]} {
        return
    }

    if {![string equal $status ok]} {
        $sw configure -cursor {}
        $sw.bbox itemconfigure 0 -text [::msgcat::mc "Try again"] \
            -command [namespace code [list SearchAgain "" $sw $jid $xlib \
                                                       $old errormsg]] \
            -state normal
        $sw.bbox itemconfigure 1 -text [::msgcat::mc "Close"]

        if {[winfo exists $sw.errormsg]} {
            destroy $sw.errormsg
        }

        Message $sw.errormsg -aspect 50000 \
            -text [::msgcat::mc "An error occurred when searching\
                                 in %s\n\n%s" \
                                $jid [error_to_string $items]]

        pack $sw.errormsg -expand yes -fill both -after $sw.fields \
                          -anchor nw -padx 1c -pady 1c
        pack forget $sw.fields

        return
    }

    wm withdraw $sw

    set rw [Toplevel ${sw}results]
    wm group $rw .
    set title [::msgcat::mc "Search in %s" $jid]
    wm title $rw $title
    wm iconname $rw $title
    wm withdraw $rw

    ButtonBox $rw.bbox -spacing 0 -padx 2m -default 0
    $rw.bbox add -text [::msgcat::mc "Search again"] \
                 -command [namespace code [list SearchAgain $rw $sw $jid \
                                                            $xlib $old]]
    $rw.bbox add -text [::msgcat::mc "Close"] \
                 -command "destroy [list $rw]
                           destroy [list $sw]"
    pack $rw.bbox -padx 2m -pady 2m -anchor e -side bottom

    bind $rw <Return> [list ButtonBox::invoke [double% $rw.bbox] default]
    bind $rw <Escape> [list ButtonBox::invoke [double% $rw.bbox] 1]

    set sww [ScrolledWindow $rw.items]

    set l $sww.listbox
    ::mclistbox::mclistbox $l \
        -width 90 \
        -height 16

    pack $sww -expand yes -fill both -anchor nw -padx 2m -pady 2m
    $sww setwidget $l

    bind $l <<ContextMenu>> \
            [namespace code [list SelectAndPopupMenu [double% $xlib] \
                                                     [double% $l] %x %y]]

    bindscroll $sww $l

    set rows [FillMclistbox $rw $jid $l $items]

    if {$rows <= 0} {
        pack forget $sww
        Message $rw.errormsg -aspect 50000 \
            -text [::msgcat::mc "Search in %s: No matching items found" $jid]
        pack $rw.errormsg -expand yes -fill both -anchor nw -padx 1c -pady 1c
    } elseif {$rows <= 12} {
        $l configure -height [expr {$rows - ($rows % 4) + 4}]
    }

    BWidget::place $rw 0 0 center
    wm deiconify $rw
}

proc search::FillMclistbox {sw jid w items} {
    variable show_all

    set width(0) [expr {[string length [::msgcat::mc #]] + 3}]
    set name(0) N
    $w column add N -label [::msgcat::mc #] -width $width(0)

    set row 0
    set col 1

    foreach {tag item} $items {
        switch -- $tag {
            title {
                if {$item != ""} {
                    wm title $sw $item
                    wm iconname $sw $item
                }
            }
            reported {
                set reported {}
                foreach {var label} $item {
                    lappend reported $var
                    set label_name($var) $label
                }
            }
        }
    }

    foreach {tag item} $items {
        switch -- $tag {
            item {
                foreach {var values} $item {
                    foreach value $values {
                        if {![string equal $value ""]} {
                            if {$show_all || ![info exists reported] || \
                                    $var in $reported} {
                                if {![info exists fieldcol($var)]} {
                                    set fieldcol($var) $col
                                    if {[info exists label_name($var)]} {
                                        set l $label_name($var)
                                    } else {
                                        set l $var
                                    }
                                    set width($col) \
                                        [expr {[string length $l] + 5}]
                                    set name($col) $var
                                    $w column add $var \
                                            -label $l \
                                            -width $width($col) \
                                            -image search/sort/noArrow \
                                            -command \
                                                [namespace code [list Sort \
                                                                      $w $var]]
                                    set lasttag $var
                                    incr col
                                }
                                set data($fieldcol($var),$row) $value

                                debugmsg search "$var $value"
                            }
                        }
                    }
                }

                set data(0,$row) [expr {$row + 1}]
                incr row
            }
        }
    }

    FinalizeMclistbox $w $row $col name data width
}

proc search::FinalizeMclistbox {w row col n d wi} {
    upvar $n name
    upvar $d data
    upvar $wi width

    $w column add lastcol -label "" -width 0
    $w configure -fillcolumn lastcol

    for {set j 0} {$j < $row} {incr j} {
        set datalist {}
        for {set i 0} {$i < $col} {incr i} {
            if {[info exists data($i,$j)]} {
                set wd [string length $data($i,$j)]
                if {$wd > $width($i)} {
                    set width($i) $wd
                }
                lappend datalist $data($i,$j)
            } else {
                lappend datalist ""
            }
        }
        lappend datalist ""
        $w insert end $datalist
    }
    for {set i 0} {$i < $col} {incr i} {
        $w column configure $name($i) -width [expr {$width($i) + 2}]
    }

    return $row
}

proc search::Sort {l tag} {
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
    foreach t [$l column names] {
        if {$t ne $tag && [$l column cget $t -image] ne ""} {
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

proc search::SearchAgain {rw sw jid xlib old {delwidget ""}} {
    catch {destroy $rw}

    $sw configure -cursor {}
    if {![string equal $delwidget ""]} {
        pack $sw.fields -expand yes -fill both -after $sw.$delwidget \
                        -anchor nw -padx 2m -pady 2m
        pack forget $sw.$delwidget

        $sw.bbox itemconfigure 0 -text [::msgcat::mc "OK"] \
            -command [namespace code [list Search $sw $xlib $jid $old]] \
            -state normal
        $sw.bbox itemconfigure 1 -text [::msgcat::mc "Cancel"]
    } else {
        $sw.bbox itemconfigure 0 -state normal
        wm deiconify $sw
    }
}

proc search::SelectAndPopupMenu {xlib w x y} {
    set index [$w find $x $y]
    if {$index < 0} return

    $w sel clear 0 end
    $w sel set $index

    set col [lsearch -exact [$w column names] jid]
    if {$col < 0} return

    set jid [lindex [$w get $index] $col]

    if {[winfo exists [set m .searchpopupmenu]]} {
        destroy $m
    }
    menu $m -tearoff 0

    hook::run search_popup_menu_hook $m $xlib $jid

    tk_popup $m [winfo pointerx .] [winfo pointery .]
}

proc search::AddSeparator {m xlib jid} {
    $m add separator
}

hook::add search_popup_menu_hook \
    [namespace current]::search::AddSeparator 40
hook::add search_popup_menu_hook \
    [namespace current]::search::AddSeparator 50

hook::add postload_hook \
    [list disco::browser::register_feature_handler jabber:iq:search \
        [namespace current]::search::open \
        -desc [list * [::msgcat::mc "Search"]]]

# vim:ft=tcl:ts=8:sw=4:sts=4:et
