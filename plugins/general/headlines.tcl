# headlines.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       implements processing and displaying headline messages.

namespace eval headlines {
    variable headid 0

    variable headlines
    array set headlines {}

    variable selected_id
    variable options
    variable trees {}

    custom::defvar send_jids {} \
        [::msgcat::mc "List of JIDs to whom headlines have been sent."] \
        -group Hidden

    custom::defvar options(cache) 0 \
        [::msgcat::mc "Cache headlines on exit and restore on start."] \
        -group Messages -type boolean

    custom::defvar options(multiple) 0 \
        [::msgcat::mc "Display headlines in single/multiple windows."] \
        -group Messages -type options \
        -values [list 0 [::msgcat::mc "Single window"] \
                      1 [::msgcat::mc "One window per bare JID"] \
                      2 [::msgcat::mc "One window per full JID"]]

    custom::defvar options(mark_seen_by) following \
        [::msgcat::mc "Mark headline read by"] \
        -group Messages -type options \
        -values [list following [::msgcat::mc "Following"] \
                      selection [::msgcat::mc "Selection"] \
                      timeout [string trim [::msgcat::mc "Timeout "]]]

    custom::defvar options(mark_timeout) 2 \
        [::msgcat::mc "Headline read timeout value (in seconds)."] \
        -group Messages -type integer



    custom::defvar options(display_subject_only) 1 \
        [::msgcat::mc "Do not display headline descriptions as tree nodes."] \
        -group Messages -type boolean

    custom::defvar options(timestamp_format) {[%R] } \
        [::msgcat::mc "Format of timestamp in headline tree view. Set to\
                       empty string if you don't want to see timestamps."] \
        -group Messages -type string

    custom::defvar options(show_balloons) 0 \
        [::msgcat::mc "Show balloons with headline messages over tree nodes."] \
        -group Messages -type boolean
}

#############################################################################

package require md5

#############################################################################

proc headlines::process_message {xlib from id type is_subject subject body err thread priority x} {
    switch -- $type {
        headline {
            show $xlib $from $type $subject $body $thread $priority $x
            return stop
        }
    }
    return
}

hook::add process_message_hook \
    [namespace current]::headlines::process_message 90

#############################################################################

proc headlines::get_win {xlib from} {
    variable options

    switch -- $options(multiple) {
        0 { return .headlines }
        1 { return .headlines_[jid_to_tag [::xmpp::jid::removeResource $from]] }
        default { return .headlines_[jid_to_tag $from] }
    }
}

#############################################################################

proc headlines::get_tree {xlib from} {
    set hw [get_win $xlib $from]
    return $hw.tree
}

#############################################################################

proc headlines::open_window {xlib from} {
    global tcl_platform
    variable options
    variable trees

    set hw [get_win $xlib $from]

    if {[winfo exists $hw]} return

    switch -- $options(multiple) {
        0 {
            set title [::msgcat::mc "Headlines"]
            set tabtitle [::msgcat::mc "Headlines"]
        }
        1 {
            set user [::xmpp::jid::removeResource $from]
            set title [::msgcat::mc "%s Headlines" $user]
            set tabtitle [::xmpp::jid::node $from]
        }
        default {
            set title [::msgcat::mc "%s Headlines" $from]
            set tabtitle [::xmpp::jid::node $from]/[::xmpp::jid::resource $from]
        }
    }

    set tw [get_tree $xlib $from]

    if {$tw ni $trees} {
        lappend trees $tw
    }

    add_win $hw -title $title -tabtitle $tabtitle \
                -raisecmd [list focus $tw] \
                -class JDisco

    PanedWin $hw.pw -orient vertical
    pack $hw.pw -fill both -expand yes

    set uw [PanedWinAdd $hw.pw -weight 1]
    set dw [PanedWinAdd $hw.pw -weight 1]

    Frame $dw.date
    if {[catch {$dw.date configure -background}]} {
        set bg [ttk::style lookup TFrame -background]
    } else {
        set bg [lindex [$dw.date configure -background] 4]
    }
    Label $dw.date.label -anchor w -text [::msgcat::mc "Date:"]
    entry $dw.date.ts -state readonly \
                      -takefocus 0 \
                      -highlightthickness 0 \
                      -relief flat \
                      -readonlybackground $bg
    pack $dw.date -fill x
    pack $dw.date.label -side left
    pack $dw.date.ts -side left -fill x -expand yes

    Frame $dw.from
    Label $dw.from.label -anchor w -text [::msgcat::mc "From:"]
    entry $dw.from.jid -state readonly \
                       -takefocus 0 \
                       -highlightthickness 0 \
                       -relief flat \
                      -readonlybackground $bg
    pack $dw.from -fill x
    pack $dw.from.label -side left
    pack $dw.from.jid -side left -fill x -expand yes

    Frame $dw.subject
    Label $dw.subject.lsubj -anchor w -text [::msgcat::mc "Subject:"]
    text $dw.subject.subj \
                          -height 1 \
                          -takefocus 0 \
                          -highlightthickness 0 \
                          -relief flat \
                          -state disabled \
                          -background $bg

    pack $dw.subject -fill x
    pack $dw.subject.lsubj -side left
    pack $dw.subject.subj -side left -fill x -expand yes

    if {[string equal $tcl_platform(platform) unix] && \
            ![string equal [option get $hw disabledForeground JDisco] ""]} {
        set config(seencolor) [option get $hw disabledForeground JDisco]
    } else {
        set config(seencolor) [option get $hw featurecolor JDisco]
    }
    set config(unseencolor) [option get $hw fill JDisco]

    set sw [ScrolledWindow $uw.sw]
    MyTree $tw

    $tw tag configure seen -foreground $config(seencolor)
    $tw tag configure unseen -foreground $config(unseencolor)

    bind $tw <<TreeviewSelect>> \
             [list [namespace current]::update_body \
                        [double% $dw.date.ts] \
                        [double% $dw.from.jid] \
                        [double% $dw.subject.subj] \
                        [double% $hw.body] %W]
    $sw setwidget $tw
    pack $sw -side top -expand yes -fill both

    $tw tag bind Text <<ContextMenu>> [list [namespace current]::select_popup [double% $hw] %x %y]
    $tw tag bind Text <Double-ButtonPress-1> \
                      [double% "[namespace current]::action browse $hw \[$tw selection\]"]
    balloon::setup $tw -command [list [namespace current]::balloon $hw]

    if {[winfo exists $tw.c]} {
        # HACK
        bind $tw.c <Return> \
             [double% "[namespace current]::action browse $hw \[$tw selection\]"]
        bind $tw.c <Delete> \
             [double% "[namespace current]::action delete $hw \[$tw selection\]"]
        bind $tw.c <Insert> \
             [double% "[namespace current]::action toggle $hw \[$tw selection\]"]
    } else {
        $tw tag bind Text <Return> \
             [double% "[namespace current]::action browse $hw \[$tw selection\]"]
        $tw tag bind Text <Delete> \
             [double% "[namespace current]::action delete $hw \[$tw selection\]"]
        $tw tag bind Text <Insert> \
             [double% "[namespace current]::action toggle $hw \[$tw selection\]"]
    }

    set dsw [ScrolledWindow $dw.sw]
    Text $hw.body -height 12 -state disabled \
                  -wrap word -takefocus 1
    ::richtext::config $hw.body -using url
    $dsw setwidget $hw.body
    pack $dsw -expand yes -fill both -anchor nw

    bind $hw.body <ButtonPress-1> [list focus %W]

    foreach ww [list $hw.body $dw.date.ts $dw.from.jid $dw.subject.subj] {
        foreach event {<Key-Up> <Key-Down> <Key-Left> <Key-Right>} {
            if {[winfo exists $tw.c]} {
                set w $tw.c
            } else {
                set w Treeview
            }
            bind $ww $event [string map [list %W [double% $tw]] [bind $w $event]]
        }
    }

    hook::run open_headlines_post_hook $hw $tw $uw $dw
}

#############################################################################

proc headlines::show {xlib from type subject body thread priority x {data {}}} {
    variable headid
    variable headlines
    variable trees
    variable options

    set subject [string trim $subject]
    set body [string trim $body]

    set desc ""
    set url ""
    set seconds [::xmpp::xml::getAttr [::xmpp::delay::parse $x] seconds]
    foreach extra $x {
        ::xmpp::xml::split $extra tag xmlns attrs cdata subels
        switch -- $xmlns {
            jabber:x:oob {
                foreach item $subels {
                    ::xmpp::xml::split $item stag sxmlns sattrs scdata ssubels

                    switch -- $stag {
                        desc -
                        url {
                            set $stag [string trim $scdata]
                        }
                    }
                }
            }
        }
    }

    if {[string equal $subject ""] && [string equal $body ""] && \
            [string equal $desc ""] && [string equal $url ""]} {
        # Ignore an empty message
        return
    }

    if {[string equal $subject ""]} {
        set subject $desc
    } else {
        if {$options(display_subject_only)} {
            set desc $subject
        }
    }

    if {$subject == ""} {
        set dsubject [::msgcat::mc "<none>"]
    } else {
        set dsubject $subject
    }

    if {$desc == ""} {
        set ddesc [::msgcat::mc "<none>"]
    } else {
        set ddesc $desc
    }

    set hw [get_win $xlib $from]

    if {![winfo exists $hw]} {
        open_window $xlib $from
    }

    set tw [get_tree $xlib $from]

    if {$options(multiple) > 1} {
        set text $dsubject
    } else {
        set text $from
    }
    set fnode [str2node $text]
    if {![$tw exists $fnode]} {
        $tw insert {} end -id $fnode \
            -text [string map [list "\n" " "] $text] \
            -open 1 \
            -image browser/headline \
            -tags {Text seen} \
            -values [list type from text $text unseen 0]
    }

    if {($options(multiple) > 1) || ([string equal $subject $desc])} {
        set snode $fnode
    } else {
        set snode $fnode-subject-[str2node $dsubject]

        if {![$tw exists $snode]} {
            $tw insert $fnode end -id $snode \
                -text [string map [list "\n" " "] $dsubject] \
                -open 1 \
                -image browser/headline \
                -tags {Text seen} \
                -values [list type subject text $subject unseen 0]
        }
    }

    set anode $fnode-article-[incr headid]
    if {[$tw exists $anode]} {
        $tw delete [list $anode]
    }
    array set props [list type article unseen 1 seconds $seconds]
    array set props $data
    array set props [list text $desc url $url body $body]

    set nodetext \
             [clock format $props(seconds) -format $options(timestamp_format)]
    append nodetext [string map [list "\n" " "] $ddesc]

    $tw insert $snode end -id $anode \
        -text $nodetext \
        -open 1 \
        -tags {Text seen} \
        -values [array get props]
    if {$props(unseen)} {
        $tw item $anode -tags {Text unseen}
    }

    set headlines($anode) [list $xlib $from $type $subject $body $thread $priority $x]

    update $tw $anode
    tab_set_updated $hw 1 message
}

#############################################################################

proc headlines::str2node {string} {
    set utf8str [encoding convertto utf-8 $string]
    if {[catch { ::md5::md5 -hex $utf8str } ret]} {
        return [::md5::md5 $utf8str]
    } else {
        return $ret
    }
}

#############################################################################

proc headlines::update_body {wdate wfrom wsubj wbody tw} {
    variable headlines
    variable options
    variable selected_id
    variable shown

    set node [lindex [$tw selection] 0]

    if {[info exists shown($tw)] && $shown($tw) eq $node} {
        return
    }
    set shown($tw) $node

    if {[catch {array set props [$tw item $node -values]}] ||
            ![info exists props(type)] || \
            $props(type) != "article"} {
        set from ""
        set subj ""
        set body ""
        set date ""
        set url ""
    } else {
        set from [lindex $headlines($node) 1]
        set subj [string map [list "\n" " "] $props(text)]
        set body $props(body)
        set date [clock format $props(seconds)]
        set url $props(url)
        if {[info exists selected_id]} {
            after cancel $selected_id
        }
        if {$props(unseen)} {
            switch -- $options(mark_seen_by) {
                selection {
                    after idle \
                          [namespace code [list action toggle \
                                                [winfo parent $tw] $node]]
                }
                timeout {
                    if {$props(unseen) == 1} {
                        set selected_id [after [expr {$options(mark_timeout)*1000}] \
                                             [namespace code [list action markseen \
                                                                  [winfo parent $tw] $node]]]
                    }
                }
            }
            }
    }

    foreach {w s} [list $wdate $date \
                        $wfrom $from] {
        $w configure -state normal
        $w delete 0 end
        $w insert 0 $s
        if {[catch {$w configure -state readonly}]} {
            $w configure -state disabled
        }
    }

    $wsubj configure -state normal
    $wsubj delete 0.0 end
    $wsubj insert 0.0 $subj
    $wsubj delete {end - 1 char}

    $wsubj mark set sel_start end
    $wsubj mark set sel_end 0.0

    $wsubj configure -state disabled

    $wbody configure -state normal
    $wbody delete 0.0 end
    ::richtext::render_message $wbody "$body\n\n" ""
    if {$url != ""} {
        ::plugins::urls::render_url $wbody url $url {} \
            -title [::msgcat::mc "Read on..."] \
            -add-command [namespace code [list action markseen \
                               [winfo parent $tw] $node]]
    }

    $wbody mark set sel_start end
    $wbody mark set sel_end 0.0

    $wbody configure -state disabled
}

#############################################################################

proc headlines::update_menu {menu num} {
    variable send_jids

    set ind 3
    if {$num} {
        $menu delete $ind [expr $ind + $num - 1]
    }
    foreach jid $send_jids {
        $menu insert $ind command \
            -label [::msgcat::mc "Forward to %s" $jid] \
            -command "[namespace current]::forward3 [list $menu] [list $jid] \
                          \$[namespace current]::headwindow \$[namespace current]::headnode"
        incr ind
    }
}

#############################################################################

namespace eval headlines {
    variable m

    if {[winfo exists [set m .h1popmenu]]} {
        destroy $m
    }
    menu $m -tearoff 0
    $m add command -label [::msgcat::mc "Browse"] \
        -command "[namespace current]::action browse \
                    \$[namespace current]::headwindow \$[namespace current]::headnode"
    $m add separator
    $m add command -label [::msgcat::mc "Forward..."] \
        -command "[namespace current]::action forward \
                    \$[namespace current]::headwindow \$[namespace current]::headnode"
    $m add separator
    $m add command -label [::msgcat::mc "Copy headline to clipboard"] \
        -command "[namespace current]::action copy_headline \
                    \$[namespace current]::headwindow \$[namespace current]::headnode"
    $m add command -label [::msgcat::mc "Copy URL to clipboard"] \
        -command "[namespace current]::action copy_url \
                    \$[namespace current]::headwindow \$[namespace current]::headnode"
    $m add command -label [::msgcat::mc "Toggle seen"] \
        -command "[namespace current]::action toggle \
                    \$[namespace current]::headwindow \$[namespace current]::headnode" \
        -accelerator Insert
    $m add command -label [::msgcat::mc "Delete"] \
        -command "[namespace current]::action delete \
                    \$[namespace current]::headwindow \$[namespace current]::headnode"
    hook::add finload_hook [list [namespace current]::update_menu $m 0]

    if {[winfo exists [set m .h2popmenu]]} {
        destroy $m
    }
    menu $m -tearoff 0
    $m add command -label [::msgcat::mc "Sort"] \
        -command "[namespace current]::action sort \
                    \$[namespace current]::headwindow \$[namespace current]::headnode"
    $m add command -label [::msgcat::mc "Sort by date"] \
        -command "[namespace current]::action datesort \
                    \$[namespace current]::headwindow \$[namespace current]::headnode"
    $m add command -label [::msgcat::mc "Mark all seen"] \
        -command "[namespace current]::action markseen \
                    \$[namespace current]::headwindow \$[namespace current]::headnode"
    $m add command -label [::msgcat::mc "Mark all unseen"] \
        -command "[namespace current]::action markunseen \
                    \$[namespace current]::headwindow \$[namespace current]::headnode"
    $m add command -label [::msgcat::mc "Delete seen"] \
        -command "[namespace current]::action deleteseen \
                    \$[namespace current]::headwindow \$[namespace current]::headnode"
    $m add command -label [::msgcat::mc "Delete all"] \
        -command "[namespace current]::action delete \
                    \$[namespace current]::headwindow \$[namespace current]::headnode"
}

#############################################################################

proc headlines::select_popup {hw x y} {
    variable headwindow
    variable headnode

    set tw $hw.tree
    $tw selection set [list [$tw identify item $x $y]]
    set node [lindex [$tw selection] 0]

    if {[catch {array set props [$tw item $node -values]}]} {
        return
    }

    set headwindow $hw
    set headnode $node

    switch -- $props(type) {
        article {
           set hm .h1popmenu
        }

        default {
           set hm .h2popmenu
        }
    }

    tk_popup $hm [winfo pointerx .] [winfo pointery .]
}

#############################################################################

proc headlines::action {action hw node} {
    variable headlines
    variable options

    if {[catch {array set props [[set tw $hw.tree] item $node -values]}]} {
        return
    }

    switch -glob -- $props(type)/$action {
        article/browse {
            if {$props(url) != ""} {
                browseurl $props(url)
            }

            if {$props(unseen)} {
                switch -- $options(mark_seen_by) {
                    following {
                        set props(unseen) 0
                        $tw item $node -tags {Text seen} -values [array get props]
                        update $tw $node
                    }
                }
            }
        }

        article/forward {
            forward .h1popmenu $tw $node
        }

        article/copy_headline {
            clipboard clear -displayof $hw
            clipboard append -displayof $hw "$props(text)\n$props(body)\n$props(url)"
        }

        article/copy_url {
            clipboard clear -displayof $hw
            clipboard append -displayof $hw $props(url)
        }

        article/toggle {
            if {$props(unseen)} {
                set props(unseen) 0
                set tag seen
            } else {
                set props(unseen) 1
                set tag unseen
            }
            $tw item $node -tags [list Text $tag] -values [array get props]
            update $tw $node
        }

        article/markseen {
            set props(unseen) 0
            $tw item $node -tags {Text seen} -values [array get props]
            update $tw $node
        }

        article/markunseen {
            set props(unseen) 1
            $tw item $node -tags {Text unseen} -values [array get props]
            update $tw $node
        }

        */delete {
            set props(unseen) 0
            $tw item $node -tags {Text seen} -values [array get props]
            update $tw $node

            # Deduce the node to select after $node is deleted:
            # Next sibling is tried first, then previous, then parent node.
            set p [$tw parent $node]
            set end [expr {[llength [$tw children $p]] - 1}]
            set ix [$tw index $node]
            if {$ix < $end} {
                set next [lindex [$tw children $p] [incr ix]]
            } elseif {$ix > 0} {
                set next [lindex [$tw children $p] [incr ix -1]]
            } else {
                set next $p
            }

            $tw delete [list $node]

            if {![string equal $next {}]} {
                $tw selection set [list $next]
            }
        }

        article/deleteseen {
            if {$props(unseen) == 0} {
                action delete $hw $node
            }
        }

        from/markseen -
        subject/markseen {
            foreach child [$tw children $node] {
                action markseen $hw $child
            }
        }

        from/markunseen -
        subject/markunseen {
            foreach child [$tw children $node] {
                action markunseen $hw $child
            }
        }

        from/deleteseen -
        subject/deleteseen {
            if {$props(unseen) > 0} {
                foreach child [$tw children $node] {
                    action deleteseen $hw $child
                }
            } else {
                action delete $hw $node
            }
        }

        from/sort -
        subject/sort {
            set children {}
            foreach child [$tw children $node] {
                catch {unset props}
                array set props [$tw item $child -values]

                lappend children [list $child $props(text)]
            }
            set neworder {}
            foreach child [lsort -index 1 $children] {
                lappend neworder [lindex $child 0]
            }
            $tw children $node $neworder

            foreach child [$tw children $node] {
                action $action $hw $child
            }
        }

        from/datesort -
        subject/datesort {
            set children {}
            set seconds [clock seconds]
            foreach child [$tw children $node] {
                catch {unset props}
                set props(seconds) $seconds
                array set props [$tw item $child -values]

                lappend children [list $child $props(seconds)]
            }
            set neworder {}
            foreach child [lsort -decreasing -index 1 $children] {
                lappend neworder [lindex $child 0]
            }
            $tw children $node $neworder

            foreach child [$tw children $node] {
                action $action $hw $child
            }
        }

        default {
        }
    }
}

#############################################################################

proc headlines::update {tw node} {
    for {set parent [$tw parent $node]} \
            {![string equal $parent {}]} \
            {set parent [$tw parent $parent]} {
        set unseen 0

        foreach child [$tw children $parent] {
            catch {unset props}
            array set props [$tw item $child -values]

            incr unseen $props(unseen)
        }

        catch {unset props}
        array set props [$tw item $parent -values]
        set props(unseen) $unseen

        set text $props(text)
        if {$text == ""} {
            set text [::msgcat::mc "<none>"]
        }
        set tag seen
        if {$unseen > 0} {
            append text " ($unseen)"
            set tag unseen
        }
        $tw item $parent -text $text \
                         -tags [list Text $tag] \
                         -values [array get props]
    }
}

#############################################################################

proc headlines::balloon {hw args} {
    variable options

    set tw $hw.tree

    if {[llength $args] == 1} {
        set node [lindex $args 0]
    } else {
        if {$::interface eq "ttk"} {
            set bd [ttk::style lookup Treeview -borderwidth {} [winfo pixels $tw 0.25m]]
        } else {
            set bd [winfo pixels $tw 0.25m]
        }
        set x [expr {[winfo pointerx $tw] - [winfo rootx $tw] - $bd}]
        set y [expr {[winfo pointery $tw] - [winfo rooty $tw] - $bd}]
        set node [$tw identify item $x $y]
        if {$node eq ""} {
            return [list $hw:$node ""]
        }
    }

    if {!$options(show_balloons)} {
        return [list $hw:$node ""]
    }

    if {[catch {array set props [$tw item $node -values]}]} {
        return [list $hw:$node ""]
    }

    set width [expr {[winfo width $tw] * 0.8}]
    if {$width < [winfo pixels $tw 12c]} {
        set width [winfo pixels $tw 12c]
    }

    switch -- $props(type) {
        article {
            if {![string equal $props(body) ""]} {
                return [list $hw:$node $props(body) -width $width]
            }
        }
    }
    return [list $hw:$node ""]
}

#############################################################################

proc headlines::save {} {
    variable options
    variable trees

    if {!$options(cache)} {
        return
    }

    if {[catch {open [set file1 [file join $::configdir headlines1.tcl]] \
                     {WRONLY CREAT TRUNC}} fd]} {
        debugmsg headlines "unable to open $file: $fd"
        return
    }
    fconfigure $fd -encoding utf-8

    set code [catch {
                foreach tw $trees {
                    save_aux $tw {} $fd
                }
             } result]

    catch {close $fd}

    if {$code} {
        debugmsg headlines $result
        catch {file delete $file1}

        return
    }

    set renameP 0
    if {![file exists [set file [file join $::configdir headlines.tcl]]]} {
    } elseif {[file size $file] == 0} {
        catch { file delete -force $file }
    } else {
        set renameP 1
        catch {file rename -force $file \
                    [set file0 [file join $::configdir headlines0.tcl]]}
    }

    if {![catch {file rename $file1 $file} result]} {
        return
    }

    debugmsg headlines "unable to rename $file1 to $file: $result"
    if {($renameP) && ([catch {file rename -force $file0 $file} result])} {
        debugmsg headlines "unable to rename $file0 back to $file: $result"
    }
    catch {file delete $file1}

    return
}

#############################################################################

proc headlines::save_aux {tw node fd} {
    variable headlines

    if {![winfo exists $tw]} {
        return
    }

    if {[llength [set children [$tw children $node]]] > 0} {
        foreach child $children {
            save_aux $tw $child $fd
        }
    } elseif {([info exists headlines($node)]) \
            && (![catch {array set props [$tw item $node -values]}])} {
        puts $fd [concat [list [namespace current]::show] \
                         $headlines($node) [list [array get props]]]
    }
}

#############################################################################

proc headlines::restore {} {
    variable options

    if {$options(cache)} {
        if {[file exists [set file [file join $::configdir headlines.tcl]]]} {
            catch {
                set fd [open $file "r"]
                fconfigure $fd -encoding utf-8
                uplevel #0 [read $fd]
                close $fd
            }
        }
    }

    return ""
}

#############################################################################

proc headlines::forward3 {menu to tw node} {
    variable send_jids

    if {[catch {array set props [$tw.tree item $node -values]}]} {
        return
    }

    if {[llength [connections]] == 0} return
    set xlib [lindex [connections] 0]

    # TODO: xlib
    message::send_msg $xlib $to -type headline \
        -subject $props(text) \
        -body $props(body) \
        -xlist [list [::xmpp::xml::create x \
                            -xmlns jabber:x:oob \
                            -subelement [::xmpp::xml::create url \
                                                -cdata $props(url)] \
                            -subelement [::xmpp::xml::create desc \
                                                -cdata $props(text)]]]
    set len [llength $send_jids]
    set send_jids [update_combo_list $send_jids $to 10]
    update_menu $menu $len
}

#############################################################################

proc headlines::forward2 {menu tw node} {
    global forward_hl
    variable send_jids

    if {[catch {array set props [$tw item $node -values]}]} {
        return
    }

    set len [llength $send_jids]
    set _send_jids $send_jids
    foreach choice [array names forward_hl] {
        if {$forward_hl($choice)} {
            lassign $choice xlib to
            message::send_msg $xlib $to -type headline \
                -subject $props(text) \
                -body $props(body) \
                -xlist [list [::xmpp::xml::create x \
                                    -xmlns jabber:x:oob \
                                    -subelement [::xmpp::xml::create url \
                                                        -cdata $props(url)] \
                                    -subelement [::xmpp::xml::create desc \
                                                        -cdata $props(text)]]]
            set _send_jids [update_combo_list $_send_jids $to 10]
        }
    }
    set send_jids $_send_jids
    update_menu $menu $len
}

#############################################################################

proc headlines::forward {menu tw node} {
    global forward_hl

    set gw .forward_headline
    catch {destroy $gw}

    set choices {}
    set balloons {}
    foreach c [connections] {
        foreach choice [roster::get_jids $c] {
            if {![string equal [roster::itemconfig $c $choice -category] conference]} {
                lappend choices [list $c $choice] [roster::get_label $c $choice]
                lappend balloons [list $c $choice] $choice
            }
        }
    }
    if {[llength $choices] == 0} {
        MessageDlg ${gw}_err -aspect 50000 -icon info \
            -message [::msgcat::mc "No users in roster..."] -type user \
            -buttons ok -default 0 -cancel 0
        return
    }

    CbDialog $gw [::msgcat::mc "Forward headline"] \
        [list [::msgcat::mc "Send"] "[namespace current]::forward2 [list $menu] \
                                                                   [list $tw] \
                                                                   [list $node]
                                     destroy $gw" \
              [::msgcat::mc "Cancel"] [list destroy $gw]] \
        forward_hl $choices $balloons
}

#############################################################################

hook::add finload_hook [namespace current]::headlines::restore
hook::add quit_hook    [namespace current]::headlines::save

#############################################################################

proc headlines::restore_window {from xlib jid} {
    open_window $xlib $from
}

#############################################################################

# TODO: Work with changes in options(multiple)
proc headlines::save_session {vsession} {
    upvar 2 $vsession session
    global usetabbar

    # We don't need JID at all, so make it empty (special case)
    set user     ""
    set server   ""
    set resource ""

    # TODO
    if {!$usetabbar} return

    set prio 0
    foreach page [.nb pages] {
        set path [ifacetk::nbpath $page]

        if {[string equal $path .headlines]} {
            lappend session [list $prio $user $server $resource \
                [list [namespace current]::restore_window ""] \
            ]
        }
        if {[regexp {^.headlines_(.*)} $path -> tag]} {
            set jid [tag_to_jid $tag]
            lappend session [list $prio $user $server $resource \
                [list [namespace current]::restore_window $jid] \
            ]
        }
        incr prio
    }
}

hook::add save_session_hook [namespace current]::headlines::save_session

# vim:ft=tcl:ts=8:sw=4:sts=4:et
