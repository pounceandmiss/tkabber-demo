# utils.tcl --
#
#       This file is a part of the Tkabber XMPP client. It provides a set
#       of useful auxiliary procedures.

proc rand {num} {
    expr int(floor(rand()*$num))
}

proc psuffix {xlib} {
    string map {: #} $xlib
}

# my_jid - returns JID for inclusion in queries. If the recipient
# is from some conference room then JID is a room JID.

proc my_jid {xlib recipient} {
    set bare_recipient [::xmpp::jid::removeResource $recipient]
    set chatid [chat::chatid $xlib $bare_recipient]
    if {[chat::is_groupchat $chatid]} {
        chat::our_jid $chatid
    } else {
        connection_jid $xlib
    }
}

proc win_id {prefix key} {
    global wins

    if {![info exists wins(seq,$prefix)]} {
        set wins(seq,$prefix) 0
    }

    if {![info exists wins(key,$prefix,$key)]} {
        set idx $wins(seq,$prefix)
        set wins(key,$prefix,$key) ".${prefix}_$idx"
        incr wins(seq,$prefix)
    }
    return $wins(key,$prefix,$key)
}


proc jid_to_tag {jid} {
    variable tagid
    variable jidtag
    variable tagjid

    if {[info exists jidtag($jid)]} {
        return $jidtag($jid)
    } else {
        set tag tag[incr tagid]

        set jidtag($jid) $tag
        set tagjid($tag) $jid

        return $tag
    }
}

proc tag_to_jid {tag} {
    variable tagjid

    if {[info exists tagjid($tag)]} {
        return $tagjid($tag)
    } else {
        error "Unknown tag $tag"
    }
}

proc double% {str} {
    string map {% %%} $str
}

proc error_type_condition {errmsg} {
    list [::xmpp::stanzaerror::type $errmsg] \
         [::xmpp::stanzaerror::condition $errmsg]
}

proc error_to_string {errmsg} {
    ::xmpp::stanzaerror::message $errmsg
}

proc get_group_nick {xlib jid} {
    global defaultnick

    if {[catch {set nick [connection_user $xlib]}]} {
        set nick ""
    }
    set tmp_pattern *
    foreach pattern [array names defaultnick] {
        if {[string equal $pattern $jid]} {
            return $defaultnick($pattern)
        } elseif {([string match $pattern $jid]) &&
                        ([string match $tmp_pattern $pattern])} {
            set nick $defaultnick($pattern)
            set tmp_pattern $pattern
        }
    }
    return $nick
}

proc check_message {nick body} {
    set personal 0

    hook::run check_personal_message_hook personal $nick $body

    return $personal
}

proc personal_message_fallback {vpersonal nick body} {
    upvar 2 $vpersonal personal

    set prefixes {"" "2"}
    set suffixes {":" 1 " " 1 "" 0}

    foreach pref $prefixes {
        foreach {suff anypos} $suffixes {
            set str "$pref$nick$suff"
            if {$body eq $str ||
                    ($anypos && [string equal -length [string length $str] $body $str])} {
                set personal 1
                return
            }
        }
    }
}

hook::add check_personal_message_hook personal_message_fallback 100

proc format_time {t} {
    if {$t eq ""} {
        return
    }

    set sec [expr {$t % 60}]
    set secs [expr {($sec==1)?"[::msgcat::mc second]":"[::msgcat::mc seconds]"}]
    set t [expr {$t / 60}]
    set min [expr {$t % 60}]
    set mins [expr {($min==1)?"[::msgcat::mc minute]":"[::msgcat::mc minutes]"}]
    set t [expr {$t / 60}]
    set hour [expr {$t % 24}]
    set hours [expr {($hour==1)?"[::msgcat::mc hour]":"[::msgcat::mc hours]"}]
    set day [expr {$t / 24}]
    set days [expr {($day==1)?"[::msgcat::mc day]":"[::msgcat::mc days]"}]

    set flag 0
    set message ""
    if {$day != 0} {
        set flag 1
        set message "$day $days"
    }
    if {$flag || ($hour != 0)} {
        set flag 1
        set message "$message $hour $hours"
    }
    if {$flag || ($min != 0)} {
        set message "$message $min $mins"
    }

    return "$message $sec $secs"
}

proc NonmodalMessageDlg {path args} {
    set icon "none"
    set title ""
    set message ""
    set opts {}
    set mopts {}
    foreach {option value} $args {
        switch -- $option {
            -icon {
                set icon $value
            }
            -title {
                set title $value
            }
            -aspect {
                lappend mopts $option $value
            }
            -message {
                lappend mopts -text $value
            }
            default {
                lappend opts $option $value
            }
        }
    }

    if {$icon == "none"} {
        set image ""
    } else {
        set image [Bitmap::get $icon]
    }

    if {$title == ""} {
        set frame [frame $path -class MessageDlg]
        set title [option get $frame "${icon}Title" MessageDlg]
        destroy $frame
        if { $title == "" } {
            set title "Message"
        }
    }

    Dialog::create $path \
                   -image $image \
                   -modal none \
                   -title $title \
                   -side bottom \
                   -anchor e \
                   -default 0 \
                   -cancel 0 {*}$opts
    Dialog::add $path -text [::msgcat::mc "OK"] \
                      -name ok \
                      -command "destroy $path"

    set frame [Dialog::getframe $path]
    Message $frame.msg -relief flat \
                       -borderwidth 0 \
                       -highlightthickness 0 {*}$mopts
    pack  $frame.msg -side left -padx 3m -pady 1m -fill x -expand yes

    Dialog::draw $path
}

proc bindscroll {w {w1 ""}} {
    if {![string equal $w1 ""]} {
        set w1 [double% $w1]
    } else {
        set w1 [double% $w]
    }

    bind $w <<ScrollUp>> \
        "if {\[lindex \[$w1 yview\] 0\] > 0} {
            $w1 yview scroll -5 units
         }"
    bind $w <<ScrollDown>> \
        "if {\[lindex \[$w1 yview\] 1\] < 1} {
            $w1 yview scroll 5 units
         }"
    bind $w <<ScrollLeft>> \
        "if {\[lindex \[$w1 xview\] 0\] > 0} {
            $w1 xview scroll -10 units
         }"
    bind $w <<ScrollRight>> \
        "if {\[lindex \[$w1 xview\] 1\] < 1} {
            $w1 xview scroll 10 units
         }"
}

###########################################################################

proc textUndoable {path args} {
    Text $path -undo 1 {*}$args
    bind [Wrapped $path] <Key-space> +[list %W edit separator]
    bind [Wrapped $path] <<ContextMenu>> \
         [list text_context_menu %W %X %Y %x %y]
    hook::run text_on_create_hook [Wrapped $path]
    return $path
}

# There is an evil bug in Tk, which does not allow inserting symbols
# using XIM if more than one bound script uses %A.
# See http://sourceforge.net/tracker/index.php?func=detail&aid=1373712&group_id=12997&atid=112997
# Workaround overwrites existiong binding and uses hook to
# simulate event with %A substituted.
# Usage example see in plugins/unix/ispell.tcl.
proc text_on_keypress {path sym} {
    tk::TextInsert $path $sym
    hook::run text_on_keypress_hook $path $sym
}

bind Text <Key> {text_on_keypress %W %A}

proc text_context_menu {W X Y x y} {
    set m .input_popup
    if {[winfo exists $m]} {
        destroy $m
    }

    menu $m -tearoff 0
    hook::run textinput_popup_menu_hook $m $W $x $y

    tk_popup $m $X $Y
}

proc text_add_copypaste_to_menu {m w x y} {
    $m add command -label [::msgcat::mc "Cut"] \
                   -command [list event generate $w <<Cut>>] \
                   -accelerator Ctrl-X
    $m add command -label [::msgcat::mc "Copy"] \
                   -command [list event generate $w <<Copy>>] \
                   -accelerator Ctrl-C
    $m add command -label [::msgcat::mc "Paste"] \
                   -command [list event generate $w <<Paste>>] \
                   -accelerator Ctrl-V
}

hook::add textinput_popup_menu_hook text_add_copypaste_to_menu 30

###########################################################################

proc focus_next {path fr} {
    focus [Widget::focusNext $path]
    set widget [focus]
    if {[string first $fr $widget] == 0} {
        $fr see $widget
    }
}

proc focus_prev {path fr} {
    focus [Widget::focusPrev $path]
    $fr see [focus]
}

proc CbDialog {path title buttons var lnames lballoons args} {
    upvar #0 $var result
    array set names $lnames
    array set balloons $lballoons

    set modal none
    set radio 0
    foreach {opt val} $args {
        switch -- $opt {
            -type { set radio [string equal $val radio] }
            -modal { set modal $val }
            -disabled { array set disabled $val }
        }
    }

    set len [llength $buttons]

    Dialog $path -title $title \
                 -modal $modal \
                 -anchor e \
                 -default 0 \
                 -cancel [expr {[llength $buttons]/2 - 1}]

    foreach {but com} $buttons {
        $path add -text $but -command $com
    }

    set m [Message [$path getframe].title -aspect 50000 -text $title]
    pack $m -expand no -fill x

    set sw [ScrolledWindow [$path getframe].sw]
    set sf [ScrollableFrame $sw.sf -constrainedwidth yes]
    pack $sw -expand yes -fill both
    $sw setwidget $sf
    set sff [$sf getframe]

    bind $path <Key-Up> [list focus_prev %W [double% $sf]]
    bind $path <Key-Down> [list focus_next %W [double% $sf]]
    bind $path <Key-Tab> [list focus_next %W [double% $sf]]
    bind $path <Shift-Tab> [list focus_prev %W [double% $sf]]
    bind $path <<PrevWindow>> [list focus_prev %W [double% $sf]]
    bindscroll $sff $sf

    set temp {}
    foreach idx [array names names] {
        lappend temp [list $idx $names($idx)]
    }

    set i 0
    foreach idxt [lsort -dictionary -index 1 $temp] {
        set idx [lindex $idxt 0]
        if {$radio} {
            set cb [Radiobutton $sff.cb$i -variable $var \
                                          -text $names($idx) \
                                          -value $idx]
            if {![info exists result] && $i == 0} {
                set result $idx
            }
        } else {
            if {![info exists result($idx)]} {
                set result($idx) 0
            }
            set cb [Checkbutton $sff.cb$i -variable ${var}($idx) \
                                          -text $names($idx)]
        }
        if {[info exists disabled($idx)] && $disabled($idx)} {
            $sff.cb$i configure -state disabled
        }
        bind $cb <Return> [list [double% $path] invoke 0]
        bind $cb <Return> +break
        bind $cb <1> [list focus %W]
        bindscroll $cb $sf
        if {[info exists balloons($idx)]} {
            balloon::setup $cb -text $balloons($idx)
        }
        pack $cb -anchor w
        incr i
    }

    $path draw $sff.cb0
}

proc OptionMenu {path args} {
    set m [::tk_optionMenu $path {*}$args]

    set bd [option get $path borderWidth ""]
    if {$bd != ""} {
        $path configure -borderwidth $bd
    }
    return $m
}

# Forces (string) $x to be interpreted as integer.
# Useful to deal with strings representing decimal integers and
# containing leading zeroes (so, normaly they would be interpreted
# by Tcl as octal integers).
# Contributed on c.l.t. by Kevin Kenny, see http://wiki.tcl.tk/498
proc force_integer {x} {
    set count [scan $x %lld%s n rest]
    if { $count <= 0 || ( $count == 2 && ![string is space $rest] ) } {
        return -code error "not an integer: $x"
    }

    return $n
}

# Excludes element $what from the list named $listVar:
proc lexclude {listVar what} {
    upvar 1 $listVar list

    set at [lsearch $list $what]

    if {$at >= 0} {
        set list [lreplace $list $at $at]
    }
}

# Takes one or more lists and returns one list with only unique
# members from all of the passed lists:
proc lfuse {args} {
    lsort -unique [lconcat $args]
}

# Takes a list of lists and flattens them into one list.
# NOTE that it takes ONE argument, which should be a list.
proc lconcat {L} {
    foreach S $L { lappend out {*}$S }
    set out
}

# List intersection.
# For a number of lists, return only those elements
# that are present in all lists.
# (Richard Suchenwirth, from http://wiki.tcl.tk/43)
proc lintersect {args} {
    set res {}
    foreach element [lindex $args 0] {
        set found 1
        foreach list [lrange $args 1 end] {
            if {$element ni $list} {
                set found 0
                break
            }
        }
        if {$found} {lappend res $element}
    }
    set res
}

proc lfilter {command list} {
    set newlist {}
    foreach elem $list {
        if {[{*}$command $elem]} {
            lappend newlist $elem
        }
    }
    return $newlist
}

# Removes $nth element from the list contained in a
# variable named $listVar in the caller's scope,
# then returns the value of the removed element.
proc lpop {listVar {nth 0}} {
    upvar 1 $listVar L
    set v [lindex $L $nth]
    set L [lreplace $L $nth $nth]
    set v
}

# Returns a fully-qualified name of the command that has invoked
# the caller of this procedure.
# To put is simple: if ::one::bar has invoked ::two::foo, the
# ::two::foo proc can use [caller] to know that its caller
# is ::one::bar
# If the caller of this proc has no caller (i.e. it was called
# on level 0), this proc returns empty string.
# You can specify 2, 3, etc as the argument to get info about
# the caller of the caller and so on (think of [uplevel]).

proc caller {{level 1}} {
    incr level
    if {[catch {info level -$level} prc]} {
        return ""
    } else {
        return [namespace which -command [lindex $prc 0]]
    }
}

# Splits a string given in $s at each occurence of
# substring given in $by.
# $sep contains a Unicode character used to replace
# found substrings before actual splitting;
# this character MUST NOT occur in $s.
proc msplit {s by {sep \u0000}} {
    split [string map [list $by $sep] $s] $sep
}

##################################################################

proc get_prop {list prop {fallback ""}} {
    if {[dict exists $list $prop]} {
        return [dict get $list $prop]
    } else {
        return $fallback
    }
}

##################################################################

proc reverse_scroll {w} {
    set command [$w cget -yscrollcommand]
    $w configure -yscrollcommand [list store_scroll $w $command]
    bind $w <Configure> {move_scroll %W}
    bind $w <Destroy> {+clean_scroll %W}
}

proc store_scroll {w command lo hi} {
    set ::lo($w) $lo
    set ::hi($w) $hi
    {*}$command $lo $hi
}

proc move_scroll {w} {
    if {![info exists ::lo($w)] || ![info exists ::hi($w)]} return
    foreach {lo hi} [$w yview] break
    if {$::hi($w) < 1.0} {
        $w yview moveto [expr {$::hi($w) - ($hi - $lo)}]
    } else {
        $w yview moveto 1.0
    }
}

proc clean_scroll {w} {
    catch {unset ::lo($w)}
    catch {unset ::hi($w)}
}

##################################################################

proc epath {} {
    global EPathNum
    if {![info exists EPathNum]} {
        set EPathNum 0
    } else {
        incr EPathNum
    }
    return .errorpath$EPathNum
}

##################################################################

proc get_conf {w option} {
    if {[catch {lindex [$w configure $option] 4} res]} {
        return [ttk::style lookup {} $option]
    } else {
        return $res
    }
}

##################################################################

proc render_url {path url title args} {
    set t [Text $path \
               -cursor left_ptr \
               -height 1 \
               -width 10 \
               -borderwidth 0 \
               -highlightthickness 0 \
               -takefocus 0 \
               -wrap none {*}$args]
    ::richtext::config $t -using url
    ::plugins::urls::render_url $t text $url {} -title $title
    $t delete {end - 1 char}
    $t configure -state disabled
    return $t
}

##################################################################

proc ecursor_entry {entry} {
    $entry icursor end
    return $entry
}

##################################################################

proc update_combo_list {list entry num} {
    set ind [lsearch -exact $list $entry]
    if {$ind >= 0} {
        set newlist [linsert [lreplace $list $ind $ind] 0 $entry]
    } else {
        set newlist [linsert $list 0 $entry]
    }
    if {[llength $newlist] > $num} {
        return [lreplace $newlist end end]
    } else {
        return $newlist
    }
}

##################################################################

proc wmstate {window args} {
    switch -- [llength $args] {
        0 {
            set state [wm state $window]
            if {[string equal $state normal]} {
                if {![catch {wm attributes $window -zoomed} res]} {
                    if {$res} {
                        set state zoomed
                    }
                }
            }
            return $state
        }
        1 {
            set state [lindex $args 0]
            switch -- $state {
                zoomed {
                    if {[catch {wm state $window zoomed}]} {
                        wm state $window normal
                        catch {wm attributes $window -zoomed 1}
                    }
                }
                default {
                    wm state $window $state
                    catch {wm attributes $window -zoomed 0}
                }
            }
            return $state
        }
    }
}

##################################################################

proc execute_script_after_idle {script value} {
    variable script_after_id
    variable script_after_value

    set script_after_value($script) $value

    if {![info exists script_after_id($script)]} {
        set script_after_id($script) [after idle execute_script [list $script]]
    }
}

proc execute_script {script} {
    variable script_after_id
    variable script_after_value

    {*}$script $script_after_value($script)

    unset script_after_id($script)
    unset script_after_value($script)
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
