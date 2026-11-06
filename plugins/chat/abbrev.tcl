# abbrev.tcl --
#
#       "abbrev" Tkabber plugin -- "Chat input abbreviations".
#       Written by Konstantin Khomoutov <flatworm@users.sourceforge.net>
#
# TODO More comments
# TODO extensive testing

namespace eval abbrev {
    variable abbrevs
    array set abbrevs {}
    trace add variable [namespace current]::abbrevs write \
          [namespace current]::store_abbrevs

    custom::defvar stored_abbrevs {} \
        "List of chat input abbreviations" \
        -group Hidden \
        -type string

    bind TextAbbrevs <Shift-KeyPress-space> \
         [list [namespace current]::expand_abbrevs %W]
    
    variable startOfPreviousWordProc
    if {[info commands ::tk::startOfPreviousWord] eq ""} {
        # Tcl 8.6 or older
        set startOfPreviousWordProc tcl_startOfPreviousWord
    } else {
        # Tcl 9.0 or newer
        set startOfPreviousWordProc ::tk::startOfPreviousWord
    }
}

proc abbrev::command_comps {chatid compsvar wordstart line} {
    upvar 0 $compsvar comps

    if {!$wordstart} {
        lappend comps {/abbrev } {/unabbrev } {/listabbrevs }
    }
}

hook::add generate_completions_hook \
          [namespace current]::abbrev::command_comps

proc abbrev::handle_command {chatid user body type} {
    variable abbrevs

    if {[string match "/abbrev*" $body]} {
        if {![regexp {^/abbrev\s+(\S+)\s+(.*)$} $body - what for]} {
            show error $chatid [::msgcat::mc "Usage: /abbrev WHAT FOR"]
            return stop
        }

        set abbrevs($what) $for
        show info $chatid [::msgcat::mc "Added abbreviation:\n%s: %s" \
                                  $what $for]
    } elseif {[string match "/unabbrev*" $body]} {
        if {![regexp {^/unabbrev\s+(\S+)} $body - what]} {
            show error $chatid [::msgcat::mc "Usage: /unabbrev WHAT"]
            return stop
        }

        # Handle special case: * stands for "all abbreviations":
        if {[string equal $what *]} {
            array unset abbrevs *
            show info $chatid [::msgcat::mc "Purged all abbreviations" $what]
            return stop
        }

        if {[catch {unset abbrevs($what)}]} {
            show error $chatid [::msgcat::mc "No such abbreviation: %s" $what]
            return stop
        } else {
            show info $chatid [::msgcat::mc "Deleted abbreviation: %s" $what]
        }
    } elseif {[string match "/listabbrevs*" $body]} {
        set out [::msgcat::mc "Abbreviations:"]
        foreach ab [array names abbrevs] {
            append out "\n$ab: $abbrevs($ab)"
        }
        show info $chatid $out
    } else {
        return
    }

    return stop
}

hook::add chat_send_message_hook \
          [namespace current]::abbrev::handle_command 15

proc abbrev::install_bindtag {chatid type} {
    set iw [chat::input_win $chatid]

    set bt [bindtags $iw]
    set ix [lsearch -exact $bt Text]
    if {$ix < 0} return ;# very, very strange...

    bindtags $iw [linsert $bt $ix TextAbbrevs]
}

hook::add open_chat_post_hook \
          [namespace current]::abbrev::install_bindtag

proc abbrev::expand_abbrevs {w} {
    variable abbrevs
    variable startOfPreviousWordProc

    set from [tk::TextPrevPos $w insert $startOfPreviousWordProc]
    set what [$w get $from insert]

    if {[info exists abbrevs($what)]} {
        set for $abbrevs($what)
        $w delete $from insert
        $w insert $from $for
    }
}

proc abbrev::store_abbrevs {args} {
    variable abbrevs
    variable stored_abbrevs

    set stored_abbrevs [array get abbrevs]
}

proc abbrev::restore_abbrevs {args} {
    variable abbrevs
    variable stored_abbrevs

    array set abbrevs $stored_abbrevs
}

# Prio of this handler must be > 60 since customize db is read at 60
hook::add postload_hook \
          [namespace current]::abbrev::restore_abbrevs 70

# $type should be either "info" or "error"
proc abbrev::show {type chatid msg} {
    set jid [chat::get_jid $chatid]
    set cw [chat::chat_win $chatid]

    chat::add_message $chatid $jid $type $msg {}
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
