# datagathering.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements the
#       user interface part for Data Forms (XEP-0004) support.

package require xmpp::data

namespace eval data {
    disco::register_feature jabber:x:data
}

proc data::fill_fields {g items} {
    variable data

    lassign [::xmpp::data::findForm $items] type form

    if {[string equal $type form]} {
        set data(x,$g) 1
        set fields [::xmpp::data::parseForm $form]
    } else {
        set fields [parse_fields $items]
    }

    return [fill_fields_x $g $fields]
}


proc data::parse_fields {items} {
    set res {}
    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        switch -- $tag {
            instructions {
                set res [linsert $res 0 instructions $cdata]
            }
            x {}
            default {
                switch -- $tag {
                    key -
                    registered {set type hidden}
                    password   {set type text-private}
                    default    {set type text-single}
                }

                lappend res field \
                        [list $tag $type "" "" false {} [list $cdata] {}]
            }
        }
    }

    return $res
}

proc data::cleanup {g} {
    variable data

    array unset data *,$g
}

proc data::get_tags {g} {
    variable data

    if {[info exists data(x,$g)]} {
        return [get_tags_x $g]
    }

    set restags {}

    if {[info exists data(varlist,$g)]} {
        foreach var $data(varlist,$g) {
            lappend restags [::xmpp::xml::create $var \
                                        -cdata $data(var,$var,$g)]
        }
    }

    return $restags
}

proc data::get_fields {g} {
    variable data

    set res {}

    if {[info exists data(varlist,$g)]} {
        foreach var $data(varlist,$g) {
            if {[info exists data(multi,$var,$g)]} {
                lappend res $var $data(var,$var,$g)
            } elseif {[info exists data(text,$var,$g)]} {
                set data(var,$var,$g) [$data(text,$var,$g) get 1.0 "end -1c"]
                lappend res $var [split $data(var,$var,$g) \n]
            } else {
                lappend res $var [list $data(var,$var,$g)]
            }
        }
    }

    return $res
}

proc data::add_label {g row label {required 0}} {
    if {$label != ""} {
        if {$required} {
            set prefix *
        } else {
            set prefix ""
        }
        if {![string is punct [string index $label end]]} {
            set suffix :
        } else {
            set suffix ""
        }
        Label $g.label$row -text ${prefix}${label}$suffix
        grid $g.label$row -row $row -column 0 -sticky en
    }
}

proc data::render_media {g row media_list} {
    foreach item $media_list {
        set unsupported 1
        foreach {type uri} $item {
            if {[string first cid: $uri] == 0} {
                set cid [string range $uri 4 end]
                switch -glob -- $type {
                    image/* {
                        # TODO: Request BOB data if it isn't present
                        set tdata [::xmpp::bob::get $cid]
                        if {[llength $tdata] < 2} {
                            continue
                        }
                        lassign $tdata type data
                        if {![catch { create_image -data $data } img]} {
                            Label $g.mediaimg$row -image $img
                            bind $g.mediaimg$row <Destroy> \
                                    [list image delete [double% $img]]
                            grid $g.mediaimg$row -row $row -column 1 -sticky ew
                            set unsupported 0
                            incr row
                        }
                    }
                    default {
                        # TODO
                    }
                }
            } else {
                render_url $g.mediauri$row $uri $uri \
                           -background [get_conf $g -background]
                grid $g.mediauri$row -row $row -column 1 -sticky ew
                set unsupported 0
                incr row
            }
        }
        if {$unsupported} {
            # No supported media item
            return -code error "No supported types for a media element"
        }
    }
    return $row
}

proc data::fill_fields_x {g items} {
    variable data

    set row 0
    set data(varlist,$g) {}
    set data(allvarlist,$g) {}
    set focus ""

    grid columnconfig $g 1 -weight 1 -minsize 0

    foreach {tag item} $items {
        switch -- $tag {
            instructions {
                Message $g.instructions$row -text $item -width 15c
                grid $g.instructions$row -row $row -column 0 \
                    -columnspan 2 -sticky w -pady 2m
                incr row
            }
            title {
                set top [winfo toplevel $g]
                if {$top != "."} {
                    wm title $top $item
                    wm iconname $top $item
                }
            }
            field {
                set widget [fill_field_x $g $row $item]
                if {$focus == ""} {
                    set focus $widget
                }
                incr row
            }
            default {
                debugmsg filetransfer "XDATA: unknown tag $tag"
            }
        }
    }

    # FIX THIS
    set data(varlist,$g) $data(allvarlist,$g)

    return $focus
}


proc data::fill_field_x {g row item} {
    variable data

    lassign $item var type label desc required options vals media_list

    if {$type == ""} {
        set type text-single
    }
    if {$label == ""} {
        set label $var
    }
    set data(var,$var,$g) [lindex $vals 0]
    set widget ""

    switch -- $type {
        jid-single -
        text-single -
        text-private {
            add_label $g $row $label $required
            set row [render_media $g $row $media_list]
            Entry $g.entry$row \
                -textvariable [namespace current]::data(var,$var,$g)
            if {$type == "text-private"} {
                $g.entry$row configure -show *
            }
            grid $g.entry$row  -row $row -column 1 -sticky we
            set widget $g.entry$row
            if {$desc != ""} {
                balloon::setup $g.entry$row -text $desc
            }
        }
        jid-multi -
        text-multi {
            add_label $g $row $label $required
            set row [render_media $g $row $media_list]
            set sw [ScrolledWindow $g.textsw$row -scrollbar vertical]
            textUndoable $g.text$row -height 6 -width 50
            $sw setwidget $g.text$row
            bind $g.text$row <Control-Key-Return> { }
            bind $g.text$row <Return> "[bind Text <Return>]\nbreak"
            set data(var,$var,$g) [join $vals \n]
            $g.text$row insert end $data(var,$var,$g)
            grid $sw -row $row -column 1 -sticky we
            set data(text,$var,$g) $g.text$row
            set widget $g.text$row
            if {$desc != ""} {
                balloon::setup $g.text$row -text $desc
            }
        }
        boolean {
            switch -- $data(var,$var,$g) {
                1 -
                0 {
                    set onvalue 1
                    set offvalue 0
                }
                true -
                false {
                    set onvalue true
                    set offvalue false
                }
                default {
                    set onvalue 1
                    set offvalue 0
                    set data(var,$var,$g) 0
                }
            }
            add_label $g $row $label $required
            set row [render_media $g $row $media_list]
            Checkbutton $g.cb$row \
                -variable [namespace current]::data(var,$var,$g) \
                -onvalue $onvalue -offvalue $offvalue
            grid $g.cb$row  -row $row -column 1 -sticky w
            set widget $g.cb$row
            if {$desc != ""} {
                balloon::setup $g.cb$row -text $desc
            }
        }
        fixed {
            add_label $g $row $label $required
            set row [render_media $g $row $media_list]
            Message $g.m$row -text [join $vals \n] -width 10c
            grid $g.m$row -row $row -column 1 -sticky w
            set dont_report 1
            if {$desc != ""} {
                balloon::setup $g.m$row -text $desc
            }
        }
        list-single {
            add_label $g $row $label $required
            set row [render_media $g $row $media_list]
            set height 0
            set data(combol$row,$var,$g) {}
            foreach {lab val} $options {
                lappend data(combol$row,$var,$g) $lab
                incr height
                if {[string equal $data(var,$var,$g) $val]} {
                    set data(combov$row,$var,$g) $lab
                }
            }
            if {$height > 10} {
                set height 10
            }
            set cb [Combobox $g.combo$row \
                        -height $height \
                        -editable no \
                        -values $data(combol$row,$var,$g) \
                        -textvariable \
                        [namespace current]::data(combov$row,$var,$g)]
            grid $cb -row $row -column 1 -sticky we
            trace add variable [namespace current]::data(combov$row,$var,$g) write \
                [list data::trace_combo $options \
                     [namespace current]::data(var,$var,$g)]
            set widget $g.combo$row
            if {$desc != ""} {
                balloon::setup $g.combo$row -text $desc
            }
        }
        list-multi {
            add_label $g $row $label $required
            set row [render_media $g $row $media_list]
            set sw [ScrolledWindow $g.sw$row]
            set l [Listbox $g.lb$row -height 6 \
                       -selectmode extended -exportselection no]
            $sw setwidget $l
            foreach {lab val} $options {
                $l insert end $lab
                if {$val in $vals} {
                    $l selection set end
                }
            }
            grid $sw  -row $row -column 1 -sticky we
            set data(multi,$var,$g) 1
            trace_listmulti $l $options \
                ::data::data(var,$var,$g)
            bind $l <<ListboxSelect>> \
                [list data::trace_listmulti %W [double% $options] \
                     [double% [namespace current]::data(var,$var,$g)]]
            set widget $sw
            if {$desc != ""} {
                balloon::setup $g.lb$row -text $desc
            }
        }
        hidden {}

        default {
            debugmsg filetransfer "XDATA: unknown field type '$type'"
        }
    }

    if {![info exists dont_report]} {
        lappend data(allvarlist,$g) $var
    }
    return $widget
}

proc data::trace_combo {assoc dst name1 name2 op} {
    foreach {lab val} $assoc {
        if {[string equal $lab [set ${name1}($name2)]]} {
            set $dst $val
        }
    }
}

proc data::trace_listmulti {l assoc dst} {
    set $dst {}
    foreach idx [$l curselection] {
        #debugmsg filetransfer [lindex $assoc [expr $idx * 2 + 1]]
        lappend $dst [lindex $assoc [expr $idx * 2 + 1]]
    }
}


proc data::get_tags_x {g} {
    return [list [::xmpp::data::submitForm [get_fields $g]]]
}

###############################################################################

proc data::draw_window {items send_cmd args} {
    variable winid

    if {![info exists winid]} {
        set winid 0
    }

    set w .datagathering[incr winid]

    if {[winfo exists $w]} {
        destroy $w
    }

    set cancel_cmd destroy
    set title ""
    foreach {key val} $args {
        switch -- $key {
            -cancelCommand { set cancel_cmd $val }
            -title { set title $val }
        }
    }

    Toplevel $w -class XData
    wm group $w .
    wm title $w $title
    wm iconname $w $title
    wm transient $w .
    wm withdraw $w
    set geometry [option get $w geometry XData]
    if {$geometry != ""} {
        wm geometry $w $geometry
    }

    set sw [ScrolledWindow $w.sw]
    set sf [ScrollableFrame $w.fields -constrainedwidth yes]
    set f [$sf getframe]
    $sf configure -height 10
    $sw setwidget $sf
    if {[catch {data::fill_fields $f $items} focus]} {
        destroy $w
        return -code error $focus
    }

    set bbox [ButtonBox $w.bbox -spacing 2m -padx 2m -default 0]
    pack $bbox -side bottom -anchor e -padx 2m -pady 2m
    $bbox add -text [::msgcat::mc "Send"] \
        -command [list eval $send_cmd [list $w] \[data::get_tags $f\]]
    $bbox add -text [::msgcat::mc "Cancel"] \
        -command [list eval $cancel_cmd [list $w]]
    bind $w <Return> [list ButtonBox::invoke [double% $bbox] default]
    bind $w <Escape> [list ButtonBox::invoke [double% $bbox] 1]
    bind $f <Destroy> [list [namespace current]::cleanup %W]

    bindscroll $f $sf

    set hf [Frame $w.error]
    pack $hf -side top
    set vf [Frame $w.vf]
    pack $vf -side left -pady 2m
    pack $sw -side top -expand yes -fill both -padx 2m -pady 2m

    update idletasks
    $hf configure -width [expr {[winfo reqwidth $f] + [winfo pixels $f 1c]}]

    set h [winfo reqheight $f]
    set sh [winfo screenheight $w]
    if {$h > $sh - [winfo pixels $f 5c]} {
        set h [expr {$sh - [winfo pixels $f 5c]}]
    }
    $vf configure -height $h

    BWidget::place $w 0 0 center

    wm deiconify $w
    if {$focus != ""} {
        focus $focus
    }

    return $w
}

proc data::destroy_windows {xlib} {
    foreach w [winfo children .] {
        if {![string match .datagathering* $w]} continue

        # HACK: search for $xlib in the send data command for the window
        set cmd [$w.bbox itemcget 0 -command]
        if {[string match "* $xlib *" $cmd]} {
            destroy $w
        }
    }
}

hook::add disconnected_hook [namespace current]::data::destroy_windows

###############################################################################

proc data::request_data {xmlns xlib jid node args} {
    if {$node == ""} {
        set vars {}
    } else {
        set vars [list node $node]
    }

    ::xmpp::sendIQ $xlib get \
        -query [::xmpp::xml::create query \
                                    -xmlns $xmlns \
                                    -attrs $vars] \
        -to $jid \
        -command [list [namespace current]::receive_data $xlib $xmlns \
                                                         $jid $node]
}

proc data::receive_data {xlib xmlns jid node res child} {
    if {[string equal $res abort]} {
        return
    }

    if {[string equal $res error]} {
        set ew .data_err
        if {[winfo exists $ew]} {
            destroy $ew
        }
        MessageDlg $ew -aspect 50000 -icon error \
            -message [::msgcat::mc "Error requesting data: %s" \
                                   [error_to_string $child]] \
            -type user -buttons ok -default 0 -cancel 0
        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    data::draw_window $subels \
        [list [namespace current]::send_data $xlib $xmlns $jid $node] \
        -cancelCommand [list [namespace current]::cancel_data $xlib $xmlns \
                                                              $jid $node]
}

proc data::cancel_data {xlib xmlns jid node w} {
    send_data $xlib $xmlns $jid $node $w [list [::xmpp::data::cancelForm]]
}

proc data::send_data {xlib xmlns jid node w restags} {
    set subels $restags
    set attrs {}

    if {$node != ""} {
        lappend attrs node $node
    }

    destroy $w.error.msg
    $w.bbox itemconfigure 0 -state disabled

    ::xmpp::sendIQ $xlib set \
            -query [::xmpp::xml::create query \
                                        -xmlns $xmlns \
                                        -attrs $attrs \
                                        -subelements $subels] \
            -to $jid \
            -command [list [namespace current]::test_error_res $w]
}

proc data::test_error_res {w res child} {
    if {![winfo exists $w]} {
        return
    }

    if {[string equal $res ok]} {
        destroy $w
        return
    }

    $w.bbox itemconfigure 0 -state normal

    set m [Message $w.error.msg \
                   -anchor center \
                   -width [winfo width $w.error] \
                   -text [error_to_string $child] \
                   -pady 2m]
    $m configure -foreground [option get $m errorForeground Message]
    pack $m -fill x
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
