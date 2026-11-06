# highlight.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which highlights certain words (e.g. the user's nickname) in chatlog
#       windows.

namespace eval highlight {

    custom::defgroup Highlight [::msgcat::mc "Groupchat message highlighting plugin options."] \
        -group Chat \
        -group {Rich Text}

    custom::defvar options(enable_highlighting) 1 \
        [::msgcat::mc "Enable highlighting plugin."] \
        -type boolean -group Highlight \
        -command [namespace current]::on_state_changed

    custom::defvar options(highlight_nick) 1 \
        [::msgcat::mc "Highlight current nickname in messages."] \
        -type boolean -group Highlight

    custom::defvar options(highlight_substrings) {} \
        [::msgcat::mc "Substrings to highlight in messages."] \
        -type string -group Highlight \
        -command [namespace current]::on_substring_list_changed

    custom::defvar options(highlight_whole_words) 1 \
        [::msgcat::mc "Highlight only whole words in messages."] \
        -type boolean -group Highlight
}

proc highlight::on_substring_list_changed {args} {
    variable options
    variable highlight_strings {}

    foreach str [split $options(highlight_substrings) " "] {
        if {$str ne ""} {
            lappend highlight_strings $str
        }
    }
}

proc highlight::configure_richtext_widget {w} {
    # TODO some defaults may be?

    $w tag configure highlight
}

proc highlight::process_highlights {atLevel accVar} {
    upvar #$atLevel $accVar chunks
    variable options
    variable highlight_strings

    set subs $highlight_strings
    if {$options(highlight_nick) && [::richtext::property_exists mynick]} {
        lappend subs [::richtext::property_get mynick]
    }

    set out {}

    foreach {s type tags} $chunks {
        if {$type ne "text"} {
            # pass through
            lappend out $s $type $tags
            continue
        }

        set ts 0

        foreach {ms me} [spot_highlights $s $subs] {
            # Write out text before current highlight, if any:
            if {$ts < $ms} {
                lappend out [string range $s $ts [expr {$ms - 1}]] $type $tags
            }
            # Write out current highlight:
            lappend out [string range $s $ms $me] highlight $tags

            set ts [expr {$me + 1}]
        }

        # Write out text after the last highlight, if any:
        if {[string length $s] - $ts > 0} {
            lappend out [string range $s $ts end] $type $tags
        }
    }

    set chunks $out
}

proc highlight::spot_highlights {s subs} {
    variable options

    set ind_end 0
    set stop_ind [string length $s]
    set ranges {}
    set found 1
    while {$found && $ind_end < $stop_ind} {
        set found 0
        set ind $ind_end
        foreach str $subs {
            set len [string length $str]
            if {$len > 0 && [set match [string first $str $s $ind]] >= 0} {
                if {!$options(highlight_whole_words) || \
                        (![string is wordchar -strict [string index $s [expr {$match - 1}]]] && \
                        ![string is wordchar -strict [string index $s [expr {$match + $len}]]])} {
                    if {!$found} {
                        set found 1
                        set ind_start $match
                        set ind_end [expr {$match + $len}]
                    } elseif {$match < $ind_start} {
                        set ind_start $match
                        set ind_end [expr {$match + $len}]
                    }
                }
            }
        }
        if {$found} {
            lappend ranges $ind_start [expr {$ind_end - 1}]
        }
    }

    return $ranges
}

proc highlight::render_highlight {w type piece tags} {
    $w insert end $piece [lfuse $type $tags]
}

# The following procedure reports highlighting inside URLs too
proc highlight::check_highlighted_message {vpersonal nick body} {
    variable options
    variable highlight_strings
    upvar 2 $vpersonal personal

    set subs $highlight_strings
    if {$options(highlight_nick) && [::richtext::property_exists mynick]} {
        lappend subs [::richtext::property_get mynick]
    }

    if {[llength [spot_highlights $body $subs]] > 0} {
        set personal 1
    }
}

hook::add check_personal_message_hook \
          [namespace current]::highlight::check_highlighted_message

proc highlight::on_state_changed {args} {
    variable options

    ::richtext::entity_state highlight $options(enable_highlighting)
}

namespace eval highlight {
    ::richtext::register_entity highlight \
        -configurator [namespace current]::configure_richtext_widget \
        -parser [namespace current]::process_highlights \
        -renderer [namespace current]::render_highlight \
        -parser-priority 60

    on_state_changed
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
