# ispell.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       implements spellchecking in the Tkabber text input windows.

package require textutil

#############################################################################

namespace eval ispell {
    custom::defgroup Plugins [::msgcat::mc "Plugins options."] \
        -group Tkabber

    custom::defgroup Ispell [::msgcat::mc "Spell check options."] \
        -group Plugins

    variable options

    custom::defvar options(enable) 0 \
        [::msgcat::mc "Enable spellchecker in text input windows."] \
        -type boolean \
        -group Ispell \
        -command [namespace current]::stop

    custom::defvar options(executable) /usr/bin/ispell \
        [::msgcat::mc "Path to the ispell executable."] \
        -group Ispell \
        -command [namespace current]::stop

    custom::defvar options(command_line) "" \
        [::msgcat::mc "Ispell options. See ispell manual for\
                       details.\n\nExamples:\n  -d russian\n  -d german -T\
                       latin1\n  -C -d english"] \
        -type string \
        -group Ispell \
        -command [namespace current]::stop

    custom::defvar options(dictionary_encoding) "" \
        [::msgcat::mc "Ispell dictionary encoding. If it is empty,\
                       system encoding is used."] \
        -type string \
        -group Ispell \
        -command [namespace current]::stop

    custom::defvar options(check_every_symbol) 0 \
        [::msgcat::mc "Check spell after every entered symbol."] \
        -type boolean \
        -group Ispell \
        -command [namespace current]::stop

    variable misspelled
    variable word_id 0

    if {$::darktheme} {
        option add *Text.errorColor coral3         widgetDefault
        option add *Text.comboColor steelblue1 widgetDefault
    } else {
        option add *Text.errorColor firebrick      widgetDefault
        option add *Text.comboColor dodgerblue4    widgetDefault
    }
}

#############################################################################

proc ispell::stop {args} {
    variable pipe

    catch {close $pipe}
    catch {unset pipe}
}

#############################################################################

proc ispell::start {} {
    variable options
    variable pipe

    if {[catch {open "|[list $options(executable)] -a $options(command_line)" r+} pipe]} {
        stop
        return
    }

    set version [gets $pipe]
    if {[string equal $version ""]} {
        stop
        return
    }

    fconfigure $pipe -blocking off -buffering line

    if {![string equal $options(dictionary_encoding) ""]} {
        fconfigure $pipe -encoding $options(dictionary_encoding)
    }

    fileevent $pipe readable [namespace current]::process_filter
}

#############################################################################

proc ispell::process_filter {} {
    variable pipe
    variable response
    variable current_word
    variable input_window
    variable misspelled

    set word [read $pipe]
    if {[string length $word] <= 1} {
        set response $word
        return
    }
    switch -- [string index $word 0] {
        \- {
            set misspelled($current_word) combo
        }
        \& -
        \? -
        \# {
            set misspelled($current_word) err
        }
        default {
            set misspelled($current_word) ok
        }
    }
    set response $word
}

#############################################################################

proc ispell::pipe_word {word} {
    variable options
    variable pipe
    variable response
    variable current_word
    variable misspelled

    if {!$options(enable)} return

    set current_word $word

    if {![info exist pipe]} {
        start
        if {![info exist pipe]} {
            after idle [list NonmodalMessageDlg .ispell_error \
                             -aspect 50000 \
                             -icon error \
                             -message [::msgcat::mc "Could not start ispell\
                                                     server. Check your ispell\
                                                     path and dictionary name.\
                                                     Ispell is disabled now"]]
            set options(enable) 0
            return
        }
    }
    if {[string length $word] <= 1} {
        set misspelled($word) ok
        return
    }
    puts $pipe $word
    vwait [namespace current]::response
}

#############################################################################

proc ispell::process_word {iw insind} {
    variable input_window
    variable misspelled
    variable word_id

    set wid $word_id
    incr word_id

    set ins [lindex [split $insind .] 1]
    set line [$iw get "$insind linestart" "$insind lineend"]
    set wordstart [string wordstart $line $ins]
    set wordend   [expr {[string wordend $line $ins] - 1}]
    set w [string range $line $wordstart $wordend]
    $iw mark set ispell_wordstart$wid "insert linestart +$wordstart chars"
    $iw mark set ispell_wordend$wid \
        "insert linestart +$wordend chars +1 chars"
    if {[info exists misspelled($w)]} {
        $iw tag remove err ispell_wordstart$wid ispell_wordend$wid
        $iw tag remove combo ispell_wordstart$wid ispell_wordend$wid
        $iw tag add $misspelled($w) \
            ispell_wordstart$wid ispell_wordend$wid
    } elseif {[string length $w] > 1} {
        pipe_word $w
        if {![winfo exists $iw]} {
            return 0
        }
        $iw tag remove err ispell_wordstart$wid ispell_wordend$wid
        $iw tag remove combo ispell_wordstart$wid ispell_wordend$wid
        if {[info exists misspelled($w)]} {
            $iw tag add $misspelled($w) \
                ispell_wordstart$wid ispell_wordend$wid
        }
    } else {
        $iw tag remove err ispell_wordstart$wid ispell_wordend$wid
        $iw tag remove combo ispell_wordstart$wid ispell_wordend$wid
        $iw mark unset ispell_wordstart$wid
        $iw mark unset ispell_wordend$wid
        return 0
    }
    $iw mark unset ispell_wordstart$wid
    $iw mark unset ispell_wordend$wid
    return 1
}

#############################################################################

proc ispell::process_line {iw sym args} {
    variable state
    variable insert_prev
    variable options

    if {![winfo exists $iw]} {
        return
    }

    switch -- $state($iw) {
        0 {
            if {[string equal $sym ""]} {
                set state($iw) 1
                # in state 0 it's more likely that the word is to the left
                # of cursor position
                set leftword [process_word $iw [$iw index "$insert_prev -1 chars"]]
                # but in rare cases (BackSpace) the word could be to the right
                if {!$leftword} {
                    process_word $iw [$iw index "$insert_prev +0 chars"]
                }
            } elseif {![string is wordchar $sym] && ($sym != "\u0008")} {
                set state($iw) 1
                process_word $iw [$iw index "$insert_prev -1 chars"]
                process_word $iw [$iw index "insert +0 chars"]
            } elseif {$options(check_every_symbol)} {
                process_word $iw [$iw index "insert -1 chars"]
            }
        }
        1 {
            if {[string equal $sym ""]} {
                # do nothing
            } elseif {![string is wordchar $sym]} {
                process_word $iw [$iw index "$insert_prev -1 chars"]
                process_word $iw [$iw index "insert +0 chars"]
                process_word $iw [$iw index "insert -1 chars"]
            } else {
                set leftword [process_word $iw [$iw index "insert -1 chars"]]
                set cur_sym [$iw get "insert" "insert +1 chars"]
                if {!$leftword && ![string is wordchar $cur_sym]} {
                    set state($iw) 0
                }
            }

        }
    }

    set insert_prev [$iw index "insert"]
}

#############################################################################

proc ispell::clear_ispell {iw} {
    variable misspelled
    variable state
    variable insert_prev

    set insert_prev [$iw index "insert"]
    if {[llength [array names misspelled]] > 2048} {
        array unset misspelled
    }
    set state($iw) 0
}

#############################################################################

proc ispell::popup_menu {m iw x y} {
    variable response

    set ind [$iw index @$x,$y]
    lassign [split $ind .] l i
    set line [$iw get "$ind linestart" "$ind lineend"]
    set wordstart [string wordstart $line $i]
    set wordend   [expr {[string wordend $line $i] - 1}]
    set w [string range $line $wordstart $wordend]
    pipe_word $w
    if {[catch { string trim $response } r]} {
        return
    }
    if {[winfo exists [set im $m.ispellpopupmenu]]} {
        destroy $im
    }
    menu $im -tearoff 0

    switch -- [string index $r 0] {
        \& -
        \? {
            regsub -all {: } $r {:} r
            regsub -all {, } $r {,} r
            set variants [split [lindex [split $r ":"] 1] ","]
            foreach var $variants {
                $im add command -label "$var" \
                    -command [list [namespace current]::substitute $iw \
                                   $l.$wordstart $l.[expr {$wordend + 1}] \
                                   $var]
            }
            $m add cascade -menu $im -label [::msgcat::mc "Spelling"]
        }
        \# {
            $im add command -label [::msgcat::mc "- nothing -"] -command {}
            $m add cascade -menu $im -label [::msgcat::mc "Spelling"]
        }
        default {}
    }

}

#############################################################################

proc ispell::substitute {iw wordstart wordend sub} {
    $iw delete $wordstart $wordend
    $iw insert $wordstart $sub
}

#############################################################################

proc ispell::key_process {iw key} {
    if {$key == 65288} {
        # BackSpace
        after_process $iw "\u0008"
    } elseif {$key >= 65280} {
        # All nonletters
        after_process $iw ""
    }
}

#############################################################################

proc ispell::after_process {iw sym} {
    variable state

    if {![info exists state($iw)]} return

    execute_script_after_idle [list [namespace current]::process_line $iw $sym] {}
}

hook::add text_on_keypress_hook [namespace current]::ispell::after_process

#############################################################################

proc ispell::setup_bindings {iw} {
    clear_ispell $iw
    bind $iw <KeyPress> [list [namespace current]::key_process %W %N]
    bind $iw <Return> +[list [namespace current]::clear_ispell %W]
    hook::add textinput_popup_menu_hook [namespace current]::popup_menu
    $iw tag configure err -foreground [option get $iw errorColor Text]
    $iw tag configure combo -foreground [option get $iw comboColor Text]
}

hook::add text_on_create_hook [namespace current]::ispell::setup_bindings

# vim:ft=tcl:ts=8:sw=4:sts=4:et
