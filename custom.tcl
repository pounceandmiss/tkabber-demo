# custom.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements the
#       customization interface and infrastructure.

if {$::darktheme} {
    option add *Customize.varforeground       steelblue1 widgetDefault
    option add *Customize.groupnameforeground steelblue1 widgetDefault
} else {
    option add *Customize.varforeground       dodgerblue4 widgetDefault
    option add *Customize.groupnameforeground dodgerblue4 widgetDefault
}

namespace eval custom {
    variable options

    # Filename for saving options
    set options(customfile) [file join $::configdir custom.tcl]

    # -1: stored values haven't been restored yet (only config changes vars)
    # 0: stored values are being restored now
    # 1: stored values have been restored (changes may be stored)
    variable custom_loaded -1
}

proc custom::defgroup {id doc args} {
    variable group

    if {![info exists group(members,$id)]} {
        set group(members,$id) {}
    }
    if {![info exists group(subgroups,$id)]} {
        set group(subgroups,$id) {}
    }
    set group(doc,$id) $doc
    set group(tag,$id) $id
    if {![info exists group(parents,$id)]} {
        set group(parents,$id) {}
    }

    foreach {attr val} $args {
        switch -- $attr {
            -tag {set group(tag,$id) $val}
            -group {
                lappend group(subgroups,$val) [list group $id]
                set group(subgroups,$val) \
                    [lsort -unique $group(subgroups,$val)]
                lappend group(parents,$id) $val
                set group(parents,$id) [lsort -unique $group(parents,$id)]
            }
            -type {
                set group(type,$id) $val
            }
        }
    }
}


proc custom::defvar {vname value doc args} {
    variable var
    variable group

    set fullname [uplevel 1 {namespace current}]::$vname

    if {[info exists $fullname]} {
        set v [set $fullname]

        if {![info exists var(default,$fullname)]} {
            set var(config,$fullname) $v
        }

        # Removing any existing trace
        unset $fullname
        set $fullname $v
    } else {
        set $fullname $value
    }

    trace add variable $fullname write \
          [list [namespace current]::on_var_change $fullname]

    set var(default,$fullname) $value
    set var(doc,$fullname) $doc
    set var(type,$fullname) string
    set var(state,$fullname) ""

    configvar $fullname {*}$args
}

proc custom::on_var_change {varname args} {
    variable options
    variable var
    variable custom_loaded

    switch -- $custom_loaded {
        -1 {
            set var(config,$varname) [set $varname]
        }
        0 { }
        1 {
            # Store variable if it has been changed by
            # any procedure which is not in ::custom namespace
            if {[namespace qualifiers [caller]] != [namespace current]} {
                # Don't store loginconf here
                # (storing all loginconf except password may be
                # confusing)
                if {![regexp {^(::)+loginconf\(.*\)} $varname]} {
                    store_vars $varname
                }
            }
        }
    }
}

proc custom::add_radio_options {vname values} {
    variable var

    set fullname [uplevel 1 {namespace current}]::$vname

    if {![info exists $fullname]} {
        return
    }

    set var(values,$fullname) [concat $var(values,$fullname) $values]
}

proc custom::configvar {fullname args} {
    variable var
    variable group

    if {![info exists $fullname]} {
        error "No such variable: $fullname"
    }

    foreach {attr val} $args {
        switch -- $attr {
            -type {
                set var(type,$fullname) $val
            }
            -group {
                if {![info exists group(members,$val)]} {
                    set group(members,$val) {}
                }
                if {[list var $fullname] ni $group(members,$val)} {
                    lappend group(members,$val) [list var $fullname]
                }
            }
            -values {
                set var(values,$fullname) $val
            }
            -layout {
                set var(layout,$fullname) $val
            }
        }
    }

    switch -- $var(type,$fullname) {
        radio {
            set q 0
            foreach {v d} $var(values,$fullname) {
                if {$v == [set $fullname]} {
                    set q 1
                }
            }
            if {!$q} {
                set $fullname $var(default,$fullname)
            }
        }
    }

    foreach {attr val} $args {
        switch -- $attr {
            -command {
                trace add variable $fullname write $val
            }
        }
    }
}

custom::defgroup Tkabber \
    [::msgcat::mc "Customization of the One True Jabber Client."]

custom::defgroup Hidden "Hidden group" -group Tkabber -tag "Hidden group" \
    -type hidden

###############################################################################

proc custom::raisecmd {} {
    focus [Wrapped .customize.fields]
}

proc custom::open_window {gid} {
    set w .customize
    if {[winfo exists $w]} {
        raise_win $w
        goto $gid
        focus [Wrapped $w.fields]
        return
    }

    add_win $w -title [::msgcat::mc "Customize"] \
        -tabtitle [::msgcat::mc "Customize"] \
        -class Customize \
        -raisecmd [list [namespace current]::raisecmd] \
        -raise 1


    set sw [ScrolledWindow $w.sw]
    if {[catch {$w cget -background} bg]} {
        set bg [ttk::style configure . -background]
    }
    set t [Text $w.fields -wrap word -takefocus 1]
    $t configure -background $bg
    $sw setwidget $t


    Frame $w.navigate
    Button $w.navigate.back -text <- \
        -width 3 \
        -command [list [namespace current]::history_move 1]
    Button $w.navigate.forward -text -> \
        -width 3 \
        -command [list [namespace current]::history_move -1]
    Button $w.navigate.toplevel -text Tkabber \
        -command [list [namespace current]::goto Tkabber]
    Label $w.navigate.lab -text [::msgcat::mc "Group:"]
    Entry $w.navigate.entry -textvariable [namespace current]::curgroup \
        -command [list [namespace current]::go]
    Button $w.navigate.browse -text [::msgcat::mc "Open"] \
        -command [list [namespace current]::go]

    pack $w.navigate.back $w.navigate.forward \
        $w.navigate.toplevel $w.navigate.lab -side left
    pack $w.navigate.entry -side left -expand yes -fill x
    pack $w.navigate.browse -side left
    pack $w.navigate -side top -fill x


    pack $sw -side top -fill both -expand yes


    $t tag configure var -underline no \
        -foreground [option get $w varforeground Customize]
    $t tag configure groupname -underline no \
        -foreground [option get $w groupnameforeground Customize]

    bind [Wrapped $t] <Key-Down> [list %W yview scroll 1 unit]
    bind [Wrapped $t] <Key-Up> [list %W yview scroll -1 unit]
    bind [Wrapped $t] <Key-Next> [list %W yview scroll 1 page]
    bind [Wrapped $t] <Key-Prior> [list %W yview scroll -1 page]
    bind [Wrapped $t] <1> [list focus %W]

    variable history
    set history(pos) 0
    set history(list) {}

    variable curgroup $gid

    hook::run open_custom_post_hook $w

    update idletasks
    goto $gid

    focus [Wrapped $t]
}

proc custom::go {} {
    variable curgroup
    goto $curgroup
}

proc custom::goto {gid} {
    history_add $gid
    fill_group .customize.fields $gid 0
}

proc custom::fill_group {t gid offset} {
    variable group
    variable var
    variable curgroup

    set curgroup $gid

    $t configure -state normal

    $t delete 1.0 end

    if {![info exists group(members,$gid)]} {
        $t configure -state disabled
        return
    }

    set i 0

    if {[info exists group(parents,$gid)] && $group(parents,$gid) != {}} {
        foreach parent $group(parents,$gid) {
            set b [Button $t.gr$i -text $group(tag,$parent) \
                       -cursor left_ptr \
                       -command [list [namespace current]::goto $parent]]
            $t window create end -window $b
            $t insert end " "
            bindscroll $b $t

            incr i
        }
        if {[llength $group(parents,$gid)] == 1} {
            $t insert end [::msgcat::mc "Parent group"]
        } else {
            $t insert end [::msgcat::mc "Parent groups"]
        }
        $t insert end "\n\n"
    }

    set butwidth 0
    foreach member [concat $group(members,$gid) \
                        [lsort -dictionary -index 1 $group(subgroups,$gid)]] {
        lassign $member type data
        switch -- $type {
            group {
                if {[info exists group(type,$data)] &&
                            $group(type,$data) eq "hidden"} {
                    continue
                }
                $t insert end "\n"
                set b [Button $t.gr$i -text "$group(tag,$data)" \
                           -width $butwidth \
                           -cursor left_ptr \
                           -command [list [namespace current]::goto $data]]
                $t window create end -window $b
                if {$butwidth < [string length "$group(tag,$data)"]} {
                    set butwidth [string length "$group(tag,$data)"]
                    for {set j 0} {$j <= $i} {incr j} {
                        if {[winfo exists $t.gr$j]} {
                            $t.gr$j configure -width $butwidth
                        }
                    }
                }
                bindscroll $b $t

                $t insert end " $group(doc,$data)"

                bindtags $b [lreplace [bindtags $b] 1 0 $t]

                $t insert end "\n"
            }
            var {
                $t insert end $data var ": "

                fill_var $t $data $i

                $t insert end "\n"

            }
        }
        incr i
    }

    $t configure -state disabled
    $t yview moveto $offset
}

proc custom::fill_var {t varname idx} {
    variable var
    variable tmp

    switch -- $var(type,$varname) {
        string {
            catch {unset tmp($varname)}
            trace add variable [namespace current]::tmp($varname) write \
                [list [namespace current]::on_edit $varname]
            set tmp($varname) [set $varname]
            set e [Entry $t.entry$idx \
                       -textvariable [namespace current]::tmp($varname)]
            $t window create end -window $e
            bindscroll $e $t
            $t insert end "\n"
        }

        password {
            catch {unset tmp($varname)}
            trace add variable [namespace current]::tmp($varname) write \
                [list [namespace current]::on_edit $varname]
            set tmp($varname) [set $varname]
            set e [Entry $t.entry$idx -show * \
                       -textvariable [namespace current]::tmp($varname)]
            $t window create end -window $e
            bindscroll $e $t
            $t insert end "\n"
        }

        boolean {
            catch {unset tmp($varname)}
            trace add variable [namespace current]::tmp($varname) write \
                [list [namespace current]::on_edit $varname]
            set tmp($varname) [set $varname]
            set cb [Checkbutton $t.cb$idx -cursor left_ptr \
                        -variable [namespace current]::tmp($varname)]
            $t window create end -window $cb
            bindscroll $cb $t
            $t insert end "\n"
        }

        integer {
            catch {unset tmp($varname)}
            trace add variable [namespace current]::tmp($varname) write \
                [list [namespace current]::on_edit $varname]
            set tmp($varname) [set $varname]
            set e [Spinbox $t.spin$idx -1000000000 1000000000 1 \
                           [namespace current]::tmp($varname)]
            $t window create end -window $e
            bindscroll $e $t
            $t insert end "\n"
        }

        options {
            catch {unset tmp($varname)}
            catch {unset var(temp,$varname)}
            trace add variable [namespace current]::tmp($varname) write \
                [list [namespace current]::on_edit $varname]
            trace add variable [namespace current]::var(temp,$varname) write \
                [list [namespace current]::on_change $t $varname]
            set var(temp,$varname) [set $varname]
            set tmp($varname) [set $varname]
            set options {}
            foreach {val text} $var(values,$varname) {
                lappend options $text
            }
            set opt [OptionMenu $t.opt$idx [namespace current]::var(temp,$varname) \
                                {*}$options]
            $t.opt$idx configure -cursor left_ptr
            $t window create end -window $t.opt$idx
            bindscroll $t.opt$idx $t
            $t insert end "\n"
        }

        list {
            if {![info exists var(values,$varname)]} return

            catch {unset tmp($varname)}
            trace add variable [namespace current]::tmp($varname) write \
                [list [namespace current]::on_edit $varname]
            set tmp($varname) [set $varname]
            set fr [frame $t.fr$idx -cursor left_ptr]
            trace add variable [namespace current]::tmp($varname) write \
                [list [namespace current]::on_change $fr.lb $varname]
            set sw [ScrolledWindow $fr.sw]
            set lb [Listbox $fr.lb -cursor left_ptr \
                        -selectmode extended -height 3 -exportselection false]
            $lb insert end {*}$var(values,$varname)
            $sw setwidget $lb
            pack $sw
            foreach i $tmp($varname) {
                $lb selection set $i
            }
            bind $lb <<ListboxSelect>> \
                [double% "set [namespace current]::tmp($varname) \
                          \[$lb curselection\]"]
            $t window create end -window $fr -align top
            $t insert end "\n"
        }

        radio {
            catch {unset tmp($varname)}
            trace add variable [namespace current]::tmp($varname) write \
                [list [namespace current]::on_edit $varname]
            set tmp($varname) [set $varname]
            if {[info exists var(layout,$varname)] && \
                        [string first v $var(layout,$varname)] == 0} {
                set anchor w
                set side top
            } else {
                set anchor n
                set side left
            }
            set fr [Frame $t.fr$idx -cursor left_ptr]
            set i 0
            foreach {val displ} $var(values,$varname) {
                set rb [Radiobutton $fr.rb$i -cursor left_ptr \
                            -text $displ -value $val \
                            -variable [namespace current]::tmp($varname)]
                pack $rb -anchor $anchor -side $side
                bindscroll $rb $t
                incr i
            }
            $t window create end -window $fr -align top
            bindscroll $fr $t
            $t insert end "\n"
        }

        font {
            catch {unset tmp($varname)}
            trace add variable [namespace current]::tmp($varname) write \
                [list [namespace current]::on_edit $varname]
            set tmp($varname) [set $varname]
            set fr [Frame $t.fr$idx -cursor left_ptr]
            trace add variable [namespace current]::tmp($varname) write \
                [list [namespace current]::on_change $fr.selectfont $varname]
            set sf [SelectFont $fr.selectfont -type toolbar \
                        -font $tmp($varname) \
                        -command [list [namespace current]::on_set_font \
                                      $fr.selectfont $varname]]
            pack $sf
            bindscroll $sf $t
            $t window create end -window $fr
            bindscroll $fr $t
            $t insert end "\n"
        }

        file {
            catch {unset tmp($varname)}
            trace add variable [namespace current]::tmp($varname) write \
                [list [namespace current]::on_edit $varname]
            set tmp($varname) [set $varname]
            set e [Entry $t.entry$idx -width 30 \
                       -textvariable [namespace current]::tmp($varname)]
            set browse \
                [Button $t.browse$idx -text [::msgcat::mc "Browse..."] \
                     -cursor left_ptr \
                     -command [list [namespace current]::get_filename \
                                    $varname]]
            $t window create end -window $e
            $t window create end -window $browse
            bindscroll $e $t
            bindscroll $browse $t
            $t insert end "\n"
        }

        default {
            $t insert end "\n"
        }
    }

    set b [Menubutton $t.stb$idx -text [::msgcat::mc "State"] \
               -cursor left_ptr \
               -menu $t.stb$idx.statemenu]
    create_state_menu $b.statemenu $varname
    $t window create end -window $b
    bindscroll $b $t
    set l [Label $t.stl$idx \
               -textvariable [namespace current]::var(state,$varname)]
    $t insert end " "
    $t window create end -window $l
    bindscroll $l $t
    $t insert end "\n"

    $t insert end "$var(doc,$varname)\n"
}

proc custom::get_filename {varname} {
    variable tmp

    set args {}
    if {$tmp($varname) == ""} {
        lappend args -initialdir $::configdir
    } else {
        lappend args -initialdir [file dirname $tmp($varname)] \
            -initialfile [file tail $tmp($varname)]
    }
    set filename [tk_getOpenFile {*}$args]
    if {$filename != ""} {
        set tmp($varname) $filename
    }
}

proc custom::on_change {w varname args} {
    variable var
    variable tmp

    if {![winfo exists $w]} {
        return
    }

    switch -- $var(type,$varname) {
        font {
            $w configure -font $tmp($varname)
        }
        list {
            $w selection clear 0 end
            foreach i $tmp($varname) {
                $w selection set $i
            }
        }
        options {
            foreach {val text} $var(values,$varname) {
                if {$text == $var(temp,$varname) && \
                        (![info exists tmp($varname)] || \
                         $tmp($varname) != $val)} {
                    set tmp($varname) $val
                    break
                }
            }
        }
    }
}

proc custom::on_set_font {sf varname} {
    variable tmp

    set tmp($varname) [$sf cget -font]
}

proc custom::on_edit {varname args} {
    variable var
    variable tmp
    variable saved

    switch -- $var(type,$varname) {
        options {
            foreach {val text} $var(values,$varname) {
                if {$tmp($varname) == $val && \
                        (![info exists var(temp,$varname)] || \
                         $var(temp,$varname) != $text)} {
                    set var(temp,$varname) $text
                    break
                }
            }
        }
    }

    set is_default [string equal [set $varname] $var(default,$varname)]
    if {[info exists var(config,$varname)]} {
        set is_config [string equal [set $varname] $var(config,$varname)]
    } else {
        set is_config -1
    }
    set is_current [string equal [set $varname] $tmp($varname)]
    if {[info exists saved($varname)]} {
        set is_saved [string equal [set $varname] $saved($varname)]
    } else {
        set is_saved -1
    }

    if {!$is_current} {
        set st [::msgcat::mc "value is changed, but the option is not set."]
    } else {
        switch -glob -- $is_default,$is_config,$is_saved {
            0,0,1 -
            0,-1,1 {
                set st [::msgcat::mc "the option is set and saved."]
            }
            *,*,0 -
            0,0,-1 -
            0,-1,-1 {
                set st [::msgcat::mc "the option is set, but not saved."]
            }
            *,1,* {
                set st [::msgcat::mc "the option is taken from config file."]
            }
            1,*,* {
                set st [::msgcat::mc "the option is set to its default value."]
            }
        }
    }

    set var(state,$varname) $st
}


proc custom::create_state_menu {m varname} {
    variable var
    variable saved

    if {[winfo exists $m]} {
        destroy $m
    }

    menu $m -tearoff 0
    $m add command -label [::msgcat::mc "Set for current session only"] \
        -command [list [namespace current]::set_for_current_sess $varname]
    $m add command \
        -label [::msgcat::mc "Set for current and future sessions"] \
        -command [list [namespace current]::save_var $varname]
    $m add command -label [::msgcat::mc "Reset to current value"] \
        -command [list [namespace current]::reset_to_current $varname]
    $m add command -label [::msgcat::mc "Reset to saved value"] \
        -command [list [namespace current]::reset_to_saved $varname] \
        -state [expr {[info exists saved($varname)] ? "normal" : "disabled"}]
    $m add command -label [::msgcat::mc "Reset to value from config file"] \
        -command [list [namespace current]::reset_to_config $varname] \
        -state \
            [expr {[info exists var(config,$varname)] ? "normal" : "disabled"}]
    $m add command -label [::msgcat::mc "Reset to default value"] \
        -command [list [namespace current]::reset_to_default $varname]

    return $m
}

proc custom::set_for_current_sess {varname} {
    variable var
    variable tmp
    variable saved

    set $varname $tmp($varname)

    on_edit $varname
}

proc custom::reset_to_current {varname} {
    variable var
    variable tmp
    variable saved

    set tmp($varname) [set $varname]

    on_edit $varname
}

proc custom::reset_to_saved {varname} {
    variable var
    variable tmp
    variable saved

    if {![info exists saved($varname)]} return

    set tmp($varname) $saved($varname)
    set $varname $saved($varname)

    on_edit $varname
}

proc custom::reset_to_config {varname} {
    variable var
    variable tmp
    variable saved

    if {![info exists var(config,$varname)]} return

    set tmp($varname) $var(config,$varname)
    set $varname $var(config,$varname)

    on_edit $varname
}

proc custom::reset_to_default {varname} {
    variable var
    variable tmp
    variable saved

    set tmp($varname) $var(default,$varname)
    set $varname $var(default,$varname)

    on_edit $varname
}

proc custom::save_var {varname} {
    variable var
    variable tmp
    variable saved

    set saved($varname) $tmp($varname)
    set $varname $tmp($varname)

    store

    on_edit $varname
}

proc custom::store {} {
    variable var
    variable saved
    variable options

    lassign [TempFile] tempfile fd
    fconfigure $fd -encoding utf-8

    foreach varname [array names saved] {
        if {[info exists var(config,$varname)]} {
            if {$saved($varname) != $var(config,$varname)} {
                puts $fd [list [list $varname $saved($varname)]]
            }
        } else {
            if {![info exists var(default,$varname)] || \
                    $saved($varname) != $var(default,$varname)} {
                puts $fd [list [list $varname $saved($varname)]]
            }
        }
    }

    close $fd
    catch {file attributes $tempfile -permissions 00600}
    file rename -force $tempfile $options(customfile)
}

proc ::custom::TempFile {} {
    set maxtries 10
    set access [list RDWR CREAT EXCL TRUNC]
    set permission 0600
    set fd ""

    for {set i 0} {$i < $maxtries} {incr i} {
        set newname [file join $::configdir custom[rand 1000000000]]

        if {![file exists $newname]} {
            if {![catch {open $newname $access $permission} fd]} {
                fconfigure $fd -translation binary
                return [list $newname $fd]
            }
        }
    }
    if {$fd == ""} {
        return -code error \
               "failed to find an unused temporary file name"
    } else {
        return -code error \
               [format "failed to open a temporary file: %s" $fd]
    }
}

proc custom::store_vars {args} {
    variable saved

    foreach varname $args {
        set saved($varname) [set $varname]
    }

    store
}

proc custom::restore {} {
    variable var
    variable saved
    variable options
    variable custom_loaded

    set custom_loaded 0

    if {[file readable $options(customfile)]} {
        set fd [open $options(customfile) r]
        fconfigure $fd -encoding utf-8

        set opts [read $fd]
        close $fd

        foreach opt $opts {
            lassign $opt varname value

            # HACK: ::plugins::loaded(*) variables must be processed first
            if {[string match ::plugins::loaded(*) $varname]} {
                set saved($varname) $value
                catch {set $varname $value}
            }
        }

        foreach opt $opts {
            lassign $opt varname value

            # HACK: matching variables other than ::plugins::loaded(*)
            # TODO: What to do with variables which namespace isn't created?
            if {![string match ::plugins::loaded(*) $varname]} {
                set saved($varname) $value
                catch {set $varname $value}
            }
        }
    }

    foreach idx [array names var default,*] {
        set varname [string range $idx 8 end]

        if {![info exists saved($varname)]} {
            # We have to trigger commands bound to the variable
            # if it was set in config or as default
            catch {set $varname [set $varname]}
        }
    }

    set custom_loaded 1
}

hook::add postload_hook custom::restore 60


proc custom::update_page_offset {} {
    variable history

    if {[llength $history(list)] == 0} return

    lassign [.customize.fields yview] offset
    lassign [lindex $history(list) $history(pos)] page

    set history(list) [lreplace $history(list) $history(pos) $history(pos) \
                                [list $page $offset]]
}

proc custom::history_move {shift} {
    variable history
    variable curgroup

    set newpos [expr {$history(pos) + $shift}]

    if {$newpos < 0} {
        return
    }

    if {$newpos >= [llength $history(list)]} {
        return
    }

    update_page_offset

    lassign [lindex $history(list) $newpos] newgroup offset
    set history(pos) $newpos
    history_set_buttons

    set curgroup $newgroup

    fill_group .customize.fields $newgroup $offset
}


proc custom::history_add {gid} {
    variable history

    update_page_offset

    set history(list) [lreplace $history(list) 0 [expr {$history(pos) - 1}]]

    set history(list) [linsert $history(list) 0 [list $gid 0]]
    set history(pos) 0
    history_set_buttons

    debugmsg custom [array get history]
}

proc custom::history_set_buttons {} {
    variable history

    if {$history(pos) == 0} {
        .customize.navigate.forward configure -state disabled
    } else {
        .customize.navigate.forward configure -state normal
    }

    if {$history(pos) + 1 == [llength $history(list)]} {
        .customize.navigate.back configure -state disabled
    } else {
        .customize.navigate.back configure -state normal
    }
}

##############################################################################

proc custom::restore_window {gid args} {
    open_window $gid
}

proc custom::save_session {vsession} {
    upvar 2 $vsession session
    global usetabbar
    variable history

    # We don't need JID at all, so make it empty (special case)
    set user     ""
    set server   ""
    set resource ""

    # TODO
    if {!$usetabbar} return

    set prio 0
    foreach page [.nb pages] {
        set path [ifacetk::nbpath $page]

        if {[string equal $path .customize]} {
            lassign [lindex $history(list) $history(pos)] gid
            lappend session [list $prio $user $server $resource \
                [list [namespace current]::restore_window $gid] \
            ]
        }
        incr prio
    }
}

hook::add save_session_hook [namespace current]::custom::save_session

# vim:ft=tcl:ts=8:sw=4:sts=4:et
