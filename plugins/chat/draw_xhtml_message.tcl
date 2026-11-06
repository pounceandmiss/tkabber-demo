# draw_xhtml_message.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which puts XHTML messages if they are included into the message
#       stanza to chatlog windows. Currently, only chat messages are
#       supported, and not groupchat ones.

namespace eval xhtml {
    variable options

    variable statevars {
        color
        lmargin1 lmargin2
        weight slant size
        list_style list_counter
    }

    variable urlid 0

    custom::defvar options(enable) 0 \
        [::msgcat::mc "Enable rendering of XHTML messages."] \
        -type boolean -group Chat

}

proc xhtml::draw_xhtml_message {chatid from type plainbody x} {
    variable options

    if {!$options(enable)} return

    foreach xelem $x {
        ::xmpp::xml::split $xelem tag xmlns attrs cdata subels

        if {[string equal $xmlns http://jabber.org/protocol/xhtml-im]} {
            set xhtml $subels
        }
    }

    if {![info exists xhtml]} return

    foreach el $xhtml {
        ::xmpp::xml::split $el tag xmlns attrs cdata subels

        if {$tag == "body"} {
            set body $el
        }
    }

    if {![info exists body]} return

    if {[chat::is_our_jid $chatid $from]} {
        set tag me
    } else {
        set tag they
    }

    set xlib [chat::get_xlib $chatid]

    set chatw [chat::chat_win $chatid]
    set nick [chat::get_nick $xlib $from $type]

    if {$type eq "groupchat"} {
        return
        # TODO
        $chatw insert end "<$nick>" $tag " "
        set myjid [chat::our_jid $chatid]
        set mynick [chat::get_nick $xlib $myjid $type]

        set mynickl [string length $mynick]
        if {[string equal -length [expr {$mynickl + 2}] $body "$mynick: "]} {
            $chatw insert end $mynick me
            ::richtext::render_message $chatw [string range $body $mynickl end] ""
        } else {
            ::richtext::render_message $chatw $body ""
        }
    } else {
        $chatw insert end "<$nick>" $tag " "
        init $chatw
        add_xhtml $chatw $body
    }

    return stop
}
hook::add draw_message_hook [namespace current]::xhtml::draw_xhtml_message 85


proc xhtml::init {cw} {
    variable state
    variable stack

    array unset stack
    array unset state
    set state(color) [$cw cget -foreground]
    set stack(color) {}
    set state(lmargin1) 0
    set stack(lmargin1) {}
    set state(lmargin2) 0
    set stack(lmargin2) {}
    set state(weight) 0
    set stack(weight) {}
    set state(slant) 0
    set stack(slant) {}
    # TODO: use default font size
    set state(size) 12
    set stack(size) {}
    set state(list_style) ul
    set stack(list_style) {}
    set state(list_counter) 0
    set stack(list_counter) {}


    set state(afterspace) 1
    set state(lastnl) 2
}

proc xhtml::add_xhtml {cw xhtml} {
    variable state

    ::xmpp::xml::split $xhtml name xmlns attrs cdata subels
    set nextcdata [::xmpp::xml::getFirstCdata $xhtml]

    push

    set tag ""
    set prefix ""
    set suffix ""
    set pre 0

    parse_style [::xmpp::xml::getAttr $attrs style]

    switch -- $name {
        h1 -
        h2 -
        h3 -
        blockquote -
        p {
            set prefix [string repeat "\n" [expr {2 - $state(lastnl)}]]
            set suffix "\n\n"
            set state(afterspace) 1
        }
        pre -
        li {
            set prefix [string repeat "\n" [expr {1 - $state(lastnl)}]]
            set suffix "\n"
            set state(afterspace) 1
        }
    }

    switch -- $name {
        h1 {
            incr state(size) 6
            set state(weight) 1
        }
        h2 {
            incr state(size) 4
            set state(weight) 1
        }
        h3 {
            incr state(size) 2
            set state(weight) 1
        }
        p {
        }
        br {
            set prefix "\n"
            set state(afterspace) 1
        }
        strong {
            set state(weight) 1
        }
        em {
            set state(slant) [expr {!$state(slant)}]
        }
        a {
            set url [::xmpp::xml::getAttr $attrs href]
            lappend tag [get_url_tag $cw $url]
        }
        img {
            set imgsrc [::xmpp::xml::getAttr $attrs src]
            set imgalt [::xmpp::xml::getAttr $attrs alt]
            set nextcdata "\[$imgalt\]"
            lappend tag [get_url_tag $cw $imgsrc]
        }
        span {}
        blockquote {
            incr state(lmargin1) 32
            incr state(lmargin2) 32
        }
        q {
            #set nextcdata "\"[string trim $cdata]\""
            #set subels {}
            set prefix \"
            set suffix \"
        }
        pre {
            set nextcdata $cdata
            set subels {}
            set pre 1
        }

        li {
            ::richtext::render_message $cw $prefix "" -nonewline
            set prefix ""
            switch -- $state(list_style) {
                ul {
                    set item_prefix "\u2022 "
                }
                ol {
                    variable stack
                    set item_prefix "[incr state(list_counter)]. "
                    set stack(list_counter) \
                        [lreplace $stack(list_counter) 0 0 \
                             $state(list_counter)]
                }
            }
            ::richtext::render_message $cw $item_prefix \
                [concat xhtml_symb [get_tags $cw]] -nonewline
        }
        ul {
            incr state(lmargin1) 32
            incr state(lmargin2) 32
            set state(list_style) ul
        }
        ol {
            incr state(lmargin1) 32
            incr state(lmargin2) 32
            set state(list_style) ol
            set state(list_counter) 0
        }
    }

    # TODO
    set tag [concat $tag [get_tags $cw]]

    if {!$pre} {
        regsub -all {[[:space:]]+} $nextcdata " " formatted
    } else {
        set formatted [string trim $nextcdata "\n"]
    }
    if {$state(afterspace) && [string index $formatted 0] == " "} {
        set formatted [string range $formatted 1 end]
    }

    if {$formatted != ""} {
        set state(afterspace) [expr {[string index $formatted end] == " "}]
    }

    ::richtext::render_message $cw $prefix $tag -nonewline
    ::richtext::render_message $cw $formatted $tag -nonewline

    if {$formatted != ""} {
        set state(lastnl) 0
    }

    foreach xelem $subels {
        add_xhtml $cw $xelem
        set nextcdata [::xmpp::xml::getNextCdata $xelem]

        regsub -all {[[:space:]]+} $nextcdata " " formatted
        if {$state(afterspace) && [string index $formatted 0] == " "} {
            set formatted [string range $formatted 1 end]
        }

        if {$formatted != ""} {
            set state(afterspace) [expr {[string index $formatted end] == " "}]
        }

        ::richtext::render_message $cw $formatted $tag -nonewline
        if {$formatted != ""} {
            set state(lastnl) 0
        }
    }

    # messy
    set state(lastnl) 0
    if {[$cw get "end - 2c"] == "\n"} {
        incr state(lastnl)
        set state(afterspace) 1
        if {[$cw get "end - 3c"] == "\n"} {
            incr state(lastnl)
        }
    }
    if {$suffix == "\n\n"} {
        ::richtext::render_message $cw \
            [string repeat "\n" [expr {2 - $state(lastnl)}]] "" -nonewline
    } elseif {$suffix == "\n"} {
        ::richtext::render_message $cw \
            [string repeat "\n" [expr {1 - $state(lastnl)}]] "" -nonewline
    } else {
        ::richtext::render_message $cw $suffix $tag -nonewline
    }
    set state(lastnl) 0
    if {[$cw get "end - 2c"] == "\n"} {
        incr state(lastnl)
        set state(afterspace) 1
        if {[$cw get "end - 3c"] == "\n"} {
            incr state(lastnl)
        }
    }
    pop
}


proc xhtml::push {} {
    variable state
    variable stack
    variable statevars

    foreach name $statevars {
        set stack($name) [linsert $stack($name) 0 $state($name)]
    }
}

proc xhtml::pop {} {
    variable state
    variable stack
    variable statevars

    foreach name $statevars {
        if {[info exists stack($name)]} {
            set stack($name) [lassign $stack($name) state($name)]
        }
    }
}

proc xhtml::parse_style {style} {
    variable state

    set optlist [split $style ";"]

    foreach opt $optlist {
        lassign [split $opt ":"] arg val
        set val [string trim $val]

        switch -- $arg {
            color {
                set state(color) $val
            }
        }
    }
}

proc xhtml::get_tags {chatw} {
    variable state

    set tags {}

    set color_tag tag_color_$state(color)
    if {![catch {$chatw tag configure $color_tag -foreground $state(color)}]} {
        lappend tags $color_tag
    }

    set indent_tag tag_indent_$state(lmargin1)_$state(lmargin2)
    $chatw tag configure $indent_tag \
        -lmargin1 $state(lmargin1) -lmargin2 $state(lmargin2)
    lappend tags $indent_tag

    if {$state(weight)} {
        set fweight bold
        if {$state(slant)} {
            set fslant i
            set fnt $::ChatBoldItalicFont
        } else {
            set fslant r
            set fnt $::ChatBoldFont
        }
    } else {
        set fweight normal
        if {$state(slant)} {
            set fslant i
            set fnt $::ChatItalicFont
        } else {
            set fslant r
            set fnt $::ChatFont
        }
    }
    # TODO: use different sizes
    set fsize $state(size)
    set font_tag tag_font_${fsize}_${fslant}_${fweight}
    $chatw tag configure $font_tag -font $fnt
    lappend tags $font_tag
    $chatw tag lower $font_tag xhtml_symb

    return $tags
}


proc xhtml::get_url_tag {chatw url} {
    variable urlid
    set tag xhtmlurl[incr urlid]
    set urlfg    [option get $chatw urlforeground       Text]
    set urlactfg [option get $chatw urlactiveforeground Text]
    $chatw tag configure $tag -foreground $urlfg -underline 1
    $chatw tag bind $tag <1> [list browseurl [double% $url]]
    $chatw tag bind $tag <Any-Enter> \
        [list ::richtext::highlighttext %W [double% $tag] [double% $urlactfg] hand2]
    $chatw tag bind $tag <Any-Leave> \
        [list ::richtext::highlighttext %W [double% $tag] [double% $urlfg] xterm]
    $chatw tag raise $tag
    return $tag
}

proc xhtml::setup_xhtml_tags {chatid type} {
    set cw [::chat::chat_win $chatid]
    $cw tag configure xhtml_symb -font $::ChatFont
    $cw tag raise xhtml_symb
}

hook::add open_chat_post_hook [namespace current]::xhtml::setup_xhtml_tags

# vim:ft=tcl:ts=8:sw=4:sts=4:et
