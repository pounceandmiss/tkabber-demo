# urls.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       renders URLs in richtext widgets.

if {$::darktheme} {
    option add *urlforeground       steelblue1  widgetDefault
    option add *urlactiveforeground skyblue     widgetDefault
    option add *urlcursor           hand2       widgetDefault
} else {
    option add *urlforeground       dodgerblue4 widgetDefault
    option add *urlactiveforeground dodgerblue3 widgetDefault
    option add *urlcursor           hand2       widgetDefault
}

namespace eval urls {
    variable options
    variable urlid 0

    # TODO add user:pass@ match
    # TODO sync TLDs with https://data.iana.org/TLD/tlds-alpha-by-domain.txt
    variable url_regexp {
        (^|\s)
        ([^\w\d]*)
        (
            (?:
                (?: ftp|https?)://
                    (?: [-\w]+(\.\w[-\w]*)*
                      | \[([a-fA-F0-9:]+:+)+[a-fA-F0-9]+\]
                    )
                  |
                (?: \w[-\w]* \. )+
                (?: com
                  | edu
                  | biz
                  | gov
                  | in(?:t|fo)
                  | mil
                  | net
                  | org
                  | name
                  | aero
                  | arpa
                  | coop
                  | museum
                  | pro
                  | travel
                  | asia
                  | cat
                  | jobs
                  | mobi
                  | tel
                  | xn-- (?: 0zwm56d
                           | 11b5bs3a9aj6g
                           | 80akhbyknj4f
                           | 9t4b11yi5a
                           | deba0ad
                           | fiqs8s
                           | fiqz9s
                           | fzc2c9e2c
                           | g6w251d
                           | hgbk6aj7f53bba
                           | hlcj6aya9esc7a
                           | j6w193g
                           | jxalpdlp
                           | kgbechtv
                           | kprw13d
                           | kpry57d
                           | mgbaam7a8h
                           | mgbayh7gpa
                           | mgberp4a5d4ar
                           | o3cw4h
                           | p1ai
                           | pgbs0dh
                           | wgbh1c
                           | xkc2al3hye2a
                           | ygbi2ammx
                           | zckzah
                         )
                  | \u6d4b\u8bd5
                  | \u092a\u0930\u0940\u0915\u094d\u0937\u093e
                  | \u0438\u0441\u043f\u044b\u0442\u0430\u043d\u0438\u0435
                  | \ud14c\uc2a4\ud2b8
                  | \u05d8\u05e2\u05e1\u05d8
                  | \u4e2d\u56fd
                  | \u4e2d\u570b
                  | \u0dbd\u0d82\u0d9a\u0dcf
                  | \u6e2c\u8a66
                  | \u0622\u0632\u0645\u0627\u06cc\u0634\u06cc
                  | \u0baa\u0bb0\u0bbf\u0b9f\u0bcd\u0b9a\u0bc8
                  | \u9999\u6e2f
                  | \u03b4\u03bf\u03ba\u03b9\u03bc\u03ae
                  | \u0625\u062e\u062a\u0628\u0627\u0631
                  | \u53f0\u6e7e
                  | \u53f0\u7063
                  | \u0627\u0645\u0627\u0631\u0627\u062a
                  | \u0627\u0644\u0627\u0631\u062f\u0646
                  | \u0627\u0644\u0633\u0639\u0648\u062f\u064a\u0629
                  | \u0e44\u0e17\u0e22
                  | \u0440\u0444
                  | \u062a\u0648\u0646\u0633
                  | \u0645\u0635\u0631
                  | \u0b87\u0bb2\u0b99\u0bcd\u0b95\u0bc8
                  | \u0641\u0644\u0633\u0637\u064a\u0646
                  | \u30c6\u30b9\u30c8
                  | [a-z][a-z]
                )
            )
            (?: : \d+ )?
            (?:
                (?:
                    /
                    [^.,?!:;"'<>()\[\]{}\s\x7F-\x9F]*
                    (?:
                        \([^.,?!:;"'<>()\[\]{}\s\x7F-\x9F]*\)
                    )?
                    [^.,?!:;"'<>()\[\]{}\s\x7F-\x9F]*
                )?
                (?:
                    [.,?!:;]+ [^.,?!:;"'<>()\[\]{}\s\x7F-\x9F]+
                )*
            )?
        )
        ([^\w\d]*)
        (\s|$)
    }
}

proc urls::process_urls {atLevel accName} {
    upvar #$atLevel $accName chunks

    set out {}

    foreach {s type tags} $chunks {
        if {$type ne "text"} {
            # pass through
            lappend out $s $type $tags
            continue
        }

        set ix 0; set us 0; set ue 0

        while {[spot_url $s $ix us ue]} {
            if {$us - $ix > 0} {
                # dump chunk before URL:
                lappend out [string range $s $ix [expr {$us - 1}]] $type $tags
            }

            set title [string range $s $us $ue]
            set url [make_url $title]

            lappend out $url url $tags
            ::richtext::property_update url:title,$url $title

            set ix [expr {$ue + 1}]
        }

        if {[string length $s] - $ix > 0} {
            # dump chunk after URL:
            lappend out [string range $s $ix end] $type $tags
        }
    }

    set chunks $out
}

proc urls::spot_url {what at startVar endVar} {
    variable url_regexp

    set matched [regexp -expanded -nocase -indices \
                        -start $at -- $url_regexp $what -> _ _ bounds]

    if {!$matched} { return false }

    upvar 1 $startVar us $endVar ue
    lassign $bounds us ue
    return true
}

proc urls::make_url {title} {
    if {[regexp -nocase {^(ftp|https?)://} $title]} {
        return $title
    }
    if {[regexp -nocase {^ftp} $title]} {
        return "ftp://$title"
    }
    return "https://$title"
}

proc urls::encode_url {url} {
    set utf8_url [encoding convertto utf-8 $url]
    set encoded_url ""
    binary scan $utf8_url cu* syms
    foreach sym $syms {
        if {$sym >= 128 || $sym <= 32} {
            append encoded_url [format "%%%02X" $sym]
        } else {
            append encoded_url [binary format c $sym]
        }
    }
    return $encoded_url
}

# Renders a rich text chunk of type "url" in the rich text widget.
#
# Accepts several trailing options:
#   -title TITLE -- allows to "hide" the actual URL
#                   and display its title instead;
#   other options are passed to [config_url], see below.
#
# An URL is physically represented by pieces of text between tags:
#
# <url> [<uri>actual URL</uri>] <href_N>title or URL</href_N> </url>
#
# That is:
# * The "url" tag is always present and it covers all the URL text;
# * The "href_N" tag (whth auto-generated integer part N) is also
#   always pesent. It contains also the URL itself, if the URL title
#   is not specified, or that URL title;
# * The "uri" tag is present only if the URL title was specified, and
#   then this tag denotes the actuall hidden URL and it then appears
#   earlier in the text that the related "href_N" tag.

proc urls::render_url {w type url tags args} {
    variable options
    variable urlid

    set privtag href_$urlid

    $w tag configure $privtag -foreground $options(foreground) -underline 1

    set url_start [$w index {end - 1 char}]

    set title [url_get_title $url $args]
    if {$title ne ""} {
        set uri_tag [list [list uri $url]]
        set url $title
        set show_hints true
    } else {
        set uri_tag [list]
        set show_hints false
    }

    $w insert end $url [lfuse $tags [list $privtag] $uri_tag]

    $w tag add $type $url_start {end - 1 char}

    $w tag bind $privtag <Any-Enter> \
        [double% [list ::richtext::highlighttext \
                       $w $privtag $options(activeforeground) $options(cursor)]]
    $w tag bind $privtag <Any-Leave> \
        [double% [list ::richtext::highlighttext \
                       $w $privtag $options(foreground) [lindex [$w configure -cursor] 3]]]

    if {$show_hints} {
        $w tag bind $privtag <Any-Enter> \
            +[list [namespace current]::balloon [double% $w] [double% $privtag] enter %x %y %X %Y]
        $w tag bind $privtag <Any-Motion> \
            +[list [namespace current]::balloon [double% $w] [double% $privtag] motion %x %y %X %Y]
        $w tag bind $privtag <Any-Leave> \
            +[list [namespace current]::balloon [double% $w] [double% $privtag] leave %x %y %X %Y]
    }

    # Default URL action:
    config_url $w $privtag \
        -command [list [namespace current]::browse_url %W %x %y] {*}$args

    incr urlid

    return $privtag ;# to allow further configuration of this tag
}

proc urls::balloon {w tag action x y X Y} {
    switch -- $action {
        enter {
            ::balloon::default_balloon $w:$tag enter $X $Y -text [get_url $w $x $y]
        }
        motion {
            ::balloon::default_balloon $w:$tag motion $X $Y -text [get_url $w $x $y]
        }
        leave {
            ::balloon::default_balloon $w:$tag leave $X $Y
        }
    }
}

# Tries to find the title for the URL $url either in the $options
# (which are usually those passed to [render_url] or among the
# properties of the message being processed.
proc urls::url_get_title {url options} {
    array set opts $options

    if {[info exists opts(-title)]} {
        set title $opts(-title)
    } elseif {[::richtext::property_exists url:title,$url]} {
        set title [::richtext::property_get url:title,$url]
    } else {
        set title ""
    }

    return $title
}

# Configures a URL $tag rendered in a text widget $w.
# This tag is either a metatag "url" or some other tag
# returned by the [render_url] proc.

# $args should be a list of option/value pairs.
# Supported options:
# -command: invoke this command when the URL is clicked with LMB;
#   replaces any existing command bound to the URL.
# -add-command: same as -command, but preserves the existing command.
#   any number of commands can be assotiated with a URL this way.

proc urls::config_url {w tag args} {
    foreach {key val} $args {
        switch -- $key {
            -command {
                $w tag bind $tag <Button-1> $val
            }
            -add-command {
                $w tag bind $tag <Button-1> +$val
            }
        }
    }
}

# Passes a URL containing the $x,$y point in the text widget $w
# to the system-dependent browser program.
# The URL undergoes W3C-urlencoding first, to be ASCII-clean.
proc urls::browse_url {w x y} {
    browseurl [encode_url [get_url $w $x $y]]
}

# Returns a URL containing the $x,$y point in the text widget $w:
proc urls::get_url {w x y} {
    set tags [$w tag names "@$x,$y"]
    set idx [lsearch $tags href_*]

    if {$idx < 0} return

    set idx1 [lsearch $tags uri*]
    if {$idx1 >= 0} {
        return [lindex [lindex $tags $idx1] 1]
    } else {
        lassign [$w tag prevrange url "@$x,$y"] a b
        return [$w get $a $b]
    }
}

# Copies an URL under $x,$y in $w into CLIPBOARD:
proc urls::copy_url {w x y} {
    clipboard clear -displayof $w
    clipboard append -displayof $w [get_url $w $x $y]
}

proc urls::add_chat_win_popup_menu {m chatwin X Y x y} {
    set tags [$chatwin tag names "@$x,$y"]
    set idx [lsearch $tags href_*]
    if {$idx >= 0} {
        $m add command -label [::msgcat::mc "Copy URL to clipboard"] \
            -command [list [namespace current]::copy_url $chatwin $x $y]
    }
}

hook::add chat_win_popup_menu_hook \
    [namespace current]::urls::add_chat_win_popup_menu 10


proc urls::configure_richtext_widget {w} {
    variable options

    set options(foreground)       [option get $w urlforeground       Text]
    set options(activeforeground) [option get $w urlactiveforeground Text]
    set options(cursor)           [option get $w urlcursor           Text]

    # "uri" -- tag for "hidden" URLs (presented as their alt. text):
    $w tag configure uri -elide 1
}

namespace eval urls {
    ::richtext::register_entity url \
        -configurator [namespace current]::configure_richtext_widget \
        -parser [namespace current]::process_urls \
        -renderer [namespace current]::render_url \
        -parser-priority 50

    ::richtext::entity_state url 1
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
