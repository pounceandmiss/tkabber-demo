# completion.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       impements an inportant part of the Tkabber user interface: words
#       completion in chat input windows.

namespace eval completion {
    variable options

    set options(prefix) ""
    set options(suffix) " "
    set options(nlprefix) ""
    set options(nlsuffix) ": "
}

# Run all generate_completions hooks and return only those completion
# that could be used to complete given word, provided that it was typed in given window
# from the given position
proc completion::get_matching_completions {chatid input_window word_pos word} {
    variable comps {}

    hook::run generate_completions_hook \
      $chatid [namespace current]::comps \
      [string length [$input_window get 1.0 $word_pos]] \
      [$input_window get 1.0 "end -1c"]
    set len [string length $word]
    set matches {}
    foreach comp $comps {
        if {[string equal -nocase -length $len $word $comp]} {
            lappend matches $comp
        }
    }

    return $matches
}

proc completion::complete {chatid shift} {
    variable completion
    # completion(state,$chatid) holds state of completion for each chatid.
    # Possible states are:
    #   normal      -- we are not currently completing anything
    #   menu_start  --
    #   menu_next   --
    #   completed   --
    #
    # completion(word,$chatid) holds current word being completed
    # (for the "menu-style" completion)
    #
    # completion(idx,$chatid)

    variable options
    variable comps {}

    # TODO: find out what is this state transition for ...
    if {![info exists completion(state,$chatid)] || \
            [string equal $completion(state,$chatid) normal]} {
        set completion(state,$chatid) completed
    }

    set iw [chat::input_win $chatid]

    if {$completion(state,$chatid) == "menu_next" && \
            [$iw compare insert == compins]} {
        set word $completion(word,$chatid)

        set matches [get_matching_completions $chatid $iw compstart $word]

        set n [llength $matches]
        if {!$n} {return}

        # TODO: what is this for?
        set completion(idx,$chatid) [expr {($completion(idx,$chatid)+$shift) % $n}]
        set comp [lindex $matches $completion(idx,$chatid)]

        debugmsg plugins "COMPLETION deleting compstart compent for $comp"
        $iw delete compstart compend
        $iw insert compstart $comp
        return
    } elseif {$completion(state,$chatid) == "menu_next"} {
        set completion(state,$chatid) completed
    }

    set ins [lindex [split [$iw index insert] .] 1]
    set line [$iw get "insert linestart" "insert lineend"]
    set lbefore [string range $line 0 [expr {$ins - 1}]]
    #set lafter [string range $line $ins end]

    # Try to find out what part of the input we are going to complete.
    # If line is empty or consists of a single word, then complete that,
    # if there are several words, try to complete all of them, except for the case when first
    # word starts with a '/' - then it is a command name and must be excluded from completion
    if {[string first " " $lbefore] == -1} {
        # Trying to complete a single word
        set word $lbefore
        debugmsg plugins "COMPLETION SINGLEWORD: $word"
    } else {
        # Trying to complete multy-word phrase.
        # If there is no completion for current line, drop the first word
        # Repeat until there would be some completions or all words would be dropped
        if {[string equal -nocase -length 1 $lbefore "/"]} {
            # First word is a command and will be ignored by regexp later in the code
            set words $lbefore
        } else {
            # First word is not a command, we should add a bogus word to be ignored
            # by the regexp later in the code
            set words "foo $lbefore"
        }
        debugmsg plugins "COMPLETION MULTIWORD: $words"
        while {$words != ""} {
            if {[regexp {^\S+\s+(.*)$} $words temp word] == 0} {
                set word $words
                debugmsg plugins "MULTIWORD COMPLETION fallback to single word $word"
                break
            }
            set phrasestart [expr {$ins - [string length $word]}]
            set matches [get_matching_completions $chatid $iw "insert linestart +$phrasestart chars" $word]
            debugmsg plugins "COMPLETION for $word: $matches"
            if {[llength $matches] == 0} {
                # Drop first word. Since "$word" has all words from "$words" minus first, it is easy.
                set words $word
            } else {
                # we got some completions, lets apply them
                break
            }
        }
    }

    #set wordstart [expr {$ins - [string length $word]}]
    #set word [$iw get "insert -1 chars wordstart" insert]
    debugmsg plugins "COMPLETION: completing $word"
    set len [string length $word]

    if {1 || $word != ""} {
        set wordstart [expr {$ins - [string length $word]}]
        set matches [get_matching_completions $chatid $iw "insert linestart +$wordstart chars" $word]
        debugmsg plugins "COMPLETION: $matches"

        if {[llength [lsort -unique $matches]] == 1 || \
                $completion(state,$chatid) == "menu_start"} {
            set comp [lindex $matches [expr {$shift==1?0:"end"}]]

            debugmsg plugins "COMPLETION deleting from $wordstart for $comp"
            $iw delete "insert linestart +$wordstart chars" insert
            $iw insert insert $comp

            if {$completion(state,$chatid) == "menu_start"} {
                set compstart $wordstart
                set compend [expr {$compstart + [string length $comp]}]
                $iw mark set compstart "insert linestart +$compstart chars"
                $iw mark gravity compstart left
                $iw mark set compend "insert linestart +$compend chars"
                $iw mark gravity compend right
                $iw mark set compins insert
                set completion(state,$chatid) menu_next
                set completion(word,$chatid) $word
                set completion(idx,$chatid) [expr {$shift==1?0:[llength $matches]-1}]
            }
        } elseif {[llength [lsort -unique $matches]] > 1} {
            set app ""
            while {[set ch [same_char $matches $len]] != ""} {
                debugmsg plugins "COMPLETION APP: $len; $ch"
                append app $ch
                incr len
            }
            $iw insert insert $app
            set completion(state,$chatid) menu_start
        }
    }
}

proc completion::same_char {strings pos} {
    if {![llength $strings]} {
        return ""
    }

    set strs [lassign $strings str1]
    set ch [string index $str1 $pos]

    foreach str $strs {
        if {![string equal -nocase $ch [string index $str $pos]]} {
            return ""
        }
    }
    return $ch
}

proc completion::nick_comps {chatid compsvar wordstart line} {
    if {![chat::is_groupchat $chatid]} return

    set xlib [chat::get_xlib $chatid]

    variable options
    upvar 0 $compsvar comps
    debugmsg plugins "COMPLETION N: $comps"

    if {!$wordstart} {
        set prefix $options(nlprefix)
        set suffix $options(nlsuffix)
    } else {
        set prefix $options(prefix)
        set suffix $options(suffix)
    }

    set nickcomps {}
    foreach nick [muc::roster $chatid] {
        lappend nickcomps $prefix$nick$suffix
    }
    set nickcomps [lsort -dictionary -unique $nickcomps]
    set comps [concat $nickcomps $comps]
    debugmsg plugins "COMPLETION N: $comps"
}

hook::add generate_completions_hook \
    [namespace current]::completion::nick_comps 90

proc completion::sort_comps {chatid compsvar wordstart line} {
    upvar 0 $compsvar comps

    set comps [lsort -dictionary -unique $comps]

    debugmsg plugins "COMPLETION S: $comps"
}

hook::add generate_completions_hook \
    [namespace current]::completion::sort_comps 75

proc completion::delete_suffix {chatid} {
    variable completion
    variable options

    set iw [chat::input_win $chatid]

    if {![info exists completion(state,$chatid)]} return

    if {([string equal $completion(state,$chatid) menu_next] || \
            [string equal $completion(state,$chatid) completed]) && \
            [$iw compare insert == {end - 1 chars}]} {
        set ind [list insert - [string length $options(suffix)] chars]
        if {[string equal [$iw get $ind insert] $options(suffix)]} {
            debugmsg plugins "COMPLETION deleting suffix"
            $iw delete $ind insert
        }
    }
    set completion(state,$chatid) normal
}

proc completion::on_keypress {chatid} {
    set iw [chat::input_win $chatid]
    after idle \
          [list [namespace current]::on_keypress1 $chatid [$iw index insert]]
}

proc completion::on_keypress1 {chatid idx} {
    variable completion

    set iw [chat::input_win $chatid]
    if {![winfo exists $iw]} return

    if {[$iw index insert] != $idx} {
        set completion(state,$chatid) normal
    }
}

proc completion::setup_bindings {chatid type} {
    variable history

    set iw [chat::input_win $chatid]
    set cc CompCtl$iw

    set bt [bindtags $iw]
    set bt [lreplace $bt -1 -1 $cc]
    bindtags $iw $bt
    debugmsg plugins "COMPLETION TAGS: $bt"

    bind $cc <Key-Tab> \
        [list [namespace current]::complete [double% $chatid] 1]
    bind $cc <Key-Tab> +break
    bind $cc <Shift-Tab> \
        [list [namespace current]::complete [double% $chatid] -1]
    bind $cc <Shift-Tab> +break
    bind $cc <Key-Return> \
        [list [namespace current]::delete_suffix [double% $chatid]]
    bind $cc <KeyPress> \
        [list [namespace current]::on_keypress [double% $chatid]]
}

hook::add open_chat_post_hook [namespace current]::completion::setup_bindings

# vim:ft=tcl:ts=8:sw=4:sts=4:et
