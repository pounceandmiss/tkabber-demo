# stylecodes.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       converts wiki-like formatting codes (*bold*, /italic/, _underlined_,
#       -struck through-) into respective font changes in richtext windows.

namespace eval stylecodes {
    variable options

    custom::defgroup Stylecodes \
        [::msgcat::mc "Handling of \"stylecodes\".\
                       Stylecodes are (groups of) special formatting symbols\
                       used to emphasize parts of the text by setting them\
                       with boldface, italics or underlined styles,\
                       or as combinations of these."] \
        -group {Rich Text} \
        -group Chat

    custom::defvar options(emphasize) 1 \
        [::msgcat::mc "Emphasize stylecoded messages using different fonts."] \
        -type boolean -group Stylecodes \
        -command [namespace current]::update_config

    custom::defvar options(hide_markup) 1 \
        [::msgcat::mc "Hide characters comprising stylecode markup."] \
        -type boolean -group Stylecodes \
        -command [namespace current]::update_config

    variable stylecodes {* / _ -}
    variable stylecodes_regex {(?:^|[[:space:]]|(?![*/_-])[[:punct:]])([*/_-])}

    variable tags
    array set tags {* bold
                    / italic
                    _ underlined
                    - overstricken}
}



proc stylecodes::process_stylecodes {atLevel accName} {
    upvar #$atLevel $accName chunks
    variable stylecodes

    set out {}

    foreach {s type tags} $chunks {
        if {$type != "text"} {
            # pass through
            lappend out $s $type $tags
            continue
        }

        lappend out {*}[scan_stylecodes $s $type $tags $stylecodes]
    }

    set chunks $out
}



proc stylecodes::scan_stylecodes {what type tags stylecodes} {
    set len [string length $what]

    set out {}
    set si 0
    set ix 0

    while {$ix < $len} {

        # spot_highlight requires the first character to be a stylecode
        set sc [spot_highlight $what $stylecodes ix]

        if {$sc eq {}} break

        lassign $sc ls le ms me rs re pat

        if {$ls > $si} {
            # dump the text before opening stylecode block:
            lappend out [string range $what $si [expr {$ls - 1}]] $type $tags
        }

        set outtags [lfuse $tags [stylecodes->tags $pat]]

        # dump opening stylecode block:
        lappend out [string range $what $ls $le] stylecode $outtags

        # dump highlighted text:
        lappend out [string range $what $ms $me] $type $outtags

        # dump closing stylecode block:
        lappend out [string range $what $rs $re] stylecode $outtags

        set si $ix
    }

    if {$si < $len} {
        lappend out [string range $what $si end] $type $tags
    }

    return $out
}



proc stylecodes::spot_highlight {what stylecodes ixVar} {
    upvar 1 $ixVar ix
    variable stylecodes_regex

    set pat ""

    # Find the first stylecode character after a space or punctuation char
    if {[regexp -indices -start $ix $stylecodes_regex $what -> indices]} {
        set ls [lindex $indices 0]
        set ix $ls
    } else {
        return {}
    }

    # eat_stylecode requires for the first call that the first character
    # is a stylecode
    while {[eat_stylecode $what $ix stylecodes pat]} {
        incr ix
    }

    if {$ix == $ls} {
        return {}
    }

    if {[is_scbreak [string index $what $ix]]} {
        # stylecode break after stylecode
        return {}
    }

    # found opening stylecode block and the pattern for ending
    # this stylecode block to seek for it:

    set rs [string first $pat $what $ix]
    if {$rs < 0} {
        return {}
    }

    # found closing stylecode block.

    if {$rs == $ix} {
        # empty highlight
        return {}
    }

    if {[is_scbreak [string index $what [expr {$rs - 1}]]]} {
        # stylecode break before
        return {}
    }

    if {[string first \n [string range $what $ix $rs]] >= 0} {
        # intervening newline
        return {}
    }

    set patlen [string length $pat]

    if {![is_scbreak [string index $what [expr {$rs + $patlen}]]]} {
        # no proper break after closing stylecode block
        return {}
    }

    set le [expr {$ls + $patlen - 1}]
    set ms [expr {$ls + $patlen}]
    set me [expr {$rs - 1}]
    set re [expr {$rs + $patlen - 1}]

    # skip past the closing stylecode block
    set ix [expr {$re + 1}]

    return [list $ls $le \
                 $ms $me \
                 $rs $re \
                 $pat]
}

proc stylecodes::eat_stylecode {what at scodesVar patVar} {
    upvar 1 $scodesVar scodes $patVar pat

    set c [string index $what $at]
    set ix [lsearch -exact $scodes $c]
    if {$ix < 0} {
        return false
    } else {
        set scodes [lreplace $scodes $ix $ix]
        set pat $c$pat
        return true
    }
}

proc stylecodes::is_scbreak {c} {
    expr {[string is space $c] || [string is punct $c]}
}

proc stylecodes::stylecodes->tags {pattern} {
    variable tags

    set out {}

    foreach sc [split $pattern ""] {
        lappend out $tags($sc)
    }

    return $out
}

proc stylecodes::render_stylecode {w type piece tags} {
    $w insert end $piece \
        [richtext::fixup_tags [concat $type $tags] {{bold italic}}]
}

proc stylecodes::configure_richtext_widget {w} {
    variable options

    if {$options(emphasize)} {
        $w tag configure stylecode -elide $options(hide_markup)
        $w tag configure bold -font $::ChatBoldFont
        $w tag configure italic -font $::ChatItalicFont
        $w tag configure bold_italic -font $::ChatBoldItalicFont
        $w tag configure underlined -underline 1
        $w tag configure overstricken -overstrike 1
    } else {
        $w tag configure stylecode -elide 0
        $w tag configure bold -font $::ChatFont
        $w tag configure italic -font $::ChatFont
        $w tag configure bold_italic -font $::ChatFont
        $w tag configure underlined -underline 0
        $w tag configure overstricken -overstrike 0
    }
}

proc stylecodes::update_config {args} {
    foreach w [::richtext::textlist] {
        configure_richtext_widget $w
    }
}

namespace eval stylecodes {
    ::richtext::register_entity stylecode \
        -configurator [namespace current]::configure_richtext_widget \
        -parser [namespace current]::process_stylecodes \
        -renderer [namespace current]::render_stylecode \
        -parser-priority 80

    ::richtext::entity_state stylecode 1
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
