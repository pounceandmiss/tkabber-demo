# emoticons.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which enables rendering emoticons in chatlog windows by eliding
#       out their textual representation and putting images instead.

catch {package require vfs::zip}

namespace eval emoticons {
    variable themes
    variable emoticons   ;# mapping from text mnemonics to images
    variable images      ;# reference counts of images
    variable txtdefaults ;# default textual representation
    variable lasttext ""
    variable lastX
    variable lastY
    variable faces_regexp ""

    variable options

    custom::defgroup Emoticons \
        [::msgcat::mc "Handling of \"emoticons\".\
                       Emoticons (also known as \"smileys\")\
                       are small pictures resembling a human face\
                       used to represent user's emotion. They are\
                       typed in as special mnemonics like :)\
                       or can be inserted using menu."]\
        -group {Rich Text} \
        -group Chat

    custom::defvar options(show_emoticons) 1 \
        [::msgcat::mc "Show images for emoticons."] \
        -type boolean -group Emoticons \
        -command [namespace current]::toggle_emoticons

    set options(no_theme) [::msgcat::mc "None"]

    custom::defvar options(theme) "" \
        [::msgcat::mc "Tkabber emoticons theme. To make new theme visible\
                       for Tkabber put it to some subdirectory of %s." \
                      [file join $::configdir emoticons]] \
        -group Emoticons -type options \
        -values [list "" $options(no_theme)] \
        -command [namespace current]::on_theme_changed

    custom::defvar options(match_whole_word) 1 \
        [::msgcat::mc "Use only whole words for emoticons."] \
        -group Emoticons -type boolean \
        -command [namespace current]::on_regex_mode_changed

    custom::defvar options(handle_lol) 0 \
        [::msgcat::mc "Handle ROTFL/LOL smileys -- those like :))) --\
                       by \"consuming\" all that parens and rendering the\
                       whole word with appropriate icon."] \
        -group Emoticons -type boolean \
        -command [namespace current]::on_regex_mode_changed

    # The [enable_subsystem] proc called by postload_hook
    # completes initialization, if needed.
}

proc emoticons::add {face image} {
    variable options
    variable emoticons
    variable images
    variable faces_regexp

    if {$face == ""} {
        return -code error "Empty emoticon mnemonic for image \"$image\""
    }

    if {![info exists images($image)]} {
        set images($image) 0
    }

    if {[info exists emoticons($face)]} {
        incr images($emoticons($face)) -1
    }

    set emoticons($face) $image

    incr images($image)

    if {$faces_regexp != ""} {
        append faces_regexp |
    }

    append faces_regexp [re_escape $face]

    if {$options(handle_lol)} {
        append faces_regexp +
    }
}

proc emoticons::get {word} {
    variable emoticons

    if {[info exists emoticons($word)]} {
        return $emoticons($word)
    } else {
        return ""
    }
}

proc emoticons::put {txt word} {
    variable emoticons

    if {[info exists emoticons($word)]} {
        $txt image create end -image $emoticons($word)
        $txt tag add emoticon_image "end-2char"
    }
}

# Clears all arrays related to emoticons
# and sets logical reference counts of images to zero.
# NOTE that it does not actually frees unused images.
# Call [sweep] or [load_dir] (which calls [sweep]) after
# calling [clear].
proc emoticons::clean {} {
    variable images
    variable emoticons
    variable txtdefaults
    variable faces_regexp

    # Prepare for loading:

    array unset emoticons *
    array unset txtdefaults *

    set faces_regexp ""

    # Set refcount to 0 on all images:
    foreach iname [array names images] {
        set images($iname) 0
    }
}

# Sweeps out orphaned (not used anymore) physical images (i.e. those
# with logical refcounts less or equal than 0.
# NOTE that images which are still physically in use (by Tk) are not
# deleted in 8.4+.
proc emoticons::sweep {} {
    variable images
    variable txtdefaults

    foreach iname [array names images] {
        if {$images($iname) < 1} {
            # Work around Tcl 8.3 which lacks [image inuse] (always kill in this case):
            if {[catch {image inuse $iname} keep]} {
                set keep 0
            }

            if {! $keep} {
                delete_image $iname
                unset images($iname)
                if {[info exists txtdefaults($iname)]} {
                    unset txtdefaults($iname)
                }
            }
        }
    }
}

# For backward compatibility:
namespace eval ::emoteicons {}

proc ::emoteicons::load_dir {dir} \
     [list eval [list [namespace current]::emoticons::load_dir] \$dir]

# Loads a new set of emoticons, adding them to the existing set,
# replacing any existing emoticons with the same mnemonics:
proc emoticons::load_dir {dir} {
    variable images
    variable faces_regexp

    if {$dir != ""} {
        set icondef_path [file join $dir icondef.xml]
        if {![file isfile $icondef_path]} {
            ### TODO: some error messages
            return
        }
        set f [open $icondef_path]
        set icondef [read $f]
        close $f

        set faces_regexp ""

        ::xmpp::xml::parseData $icondef [namespace code [list parse_icondef $dir]]
    }

    # Sweep out orphaned images:
    sweep
}

proc emoticons::parse_icondef {dir xmldata} {
    ::xmpp::xml::split $xmldata tag xmlns attrs cdata subels

    if {$tag != "icondef"} {
        # TODO: error message
        return
    }

    foreach subel $subels {
        parse_item $dir $subel
    }

}

proc emoticons::parse_item {dir item} {
    ::xmpp::xml::split $item tag xmlns attrs cdata subels

    switch -- $tag {
        name {}
        version {}
        description {}
        author {}
        creation {}
        meta {}
        icon {
            parse_icon $dir $subels
        }
    }
}

proc emoticons::parse_icon {dir items} {
    variable txtdefaults
    variable images

    set faces {}
    set txtdefault ""
    set graphic ""
    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels
        switch -- $tag {
            text {
                if {$cdata == ""} continue ;# skip empty <text> element
                lappend faces $cdata
                if {$txtdefault == "" || \
                        [::xmpp::xml::getAttr $attrs default] == "true"} {
                    set txtdefault $cdata
                }
            }
            object {
                switch -glob -- [::xmpp::xml::getAttr $attrs mime] {
                    image/* {set graphic $cdata}
                }
            }
            graphic {
                # For compatibility with older versions of icondef.xml
                switch -glob -- [::xmpp::xml::getAttr $attrs type] {
                    image/* {set graphic $cdata}
                }
            }
            sound {}
        }
    }

    #debugmsg emoticons "E: $graphic; $txts"

    if {$graphic == "" || [llength $faces] == 0} return

    # Work around absence of default face:
    if {$txtdefault == ""} {
        set txtdefault [lindex $faces 0]
    }

    set iname [imagename $txtdefault]

    # TODO what if more than one face match existing images?
    foreach face $faces {
        set icon [imagename $face]
        if {[info exists images($icon)]} {
            set iname $icon
            break
        }
    }

    create_image $iname -file [file join $dir $graphic]

    set images($iname) 0 ;# Initial refcount is zero since it'll bumped by successive [add]s:

    foreach face $faces {
        add $face $iname
    }

    set txtdefaults($iname) $txtdefault
}

# Constructs a name for the emoticon image from its mnemonic.
# Since [image] creates a command with the name of the image, we
# add our namespace as a prefix.
proc emoticons::imagename {mnemonic} {
    return [namespace current]::emoticon_$mnemonic
}

proc emoticons::create_image {name args} {
    ::create_image $name {*}$args
}

proc emoticons::delete_image {name} {
    image delete $name
}

proc emoticons::show_menu {iw} {
    variable txtdefaults

    set imgs [array names txtdefaults]

    if {[llength $imgs] == 0} return

    set m .emoticonsmenu
    if {[winfo exists $m]} {
        destroy $m
    }
    menu $m -tearoff 0

    set rows [expr {floor(sqrt([llength $imgs]))}]
    set row 0

    foreach img $imgs {
        if {$row >= $rows} {
            $m add command -image $img -columnbreak 1 \
                -label $txtdefaults($img) \
                -command [list [namespace current]::insert $iw \
                                                $txtdefaults($img)]
            set row 1
        } else {
            $m add command -image $img \
                -label $txtdefaults($img) \
                -command [list [namespace current]::insert $iw \
                                                $txtdefaults($img)]
            incr row
        }
    }

    bind $m <Any-Enter>  \
        [list [namespace current]::balloon %W enter  %X %Y %x %y]
    bind $m <Any-Motion> \
        [list [namespace current]::balloon %W motion %X %Y %x %y]
    bind $m <Any-Leave>  \
        [list [namespace current]::balloon %W leave  %X %Y %x %y]

    tk_popup $m [winfo pointerx .] [winfo pointery .]
}

# trying to get motion events in a menu is problematic...

proc emoticons::balloon {w action X Y x y} {
    variable lasttext
    variable lastX
    variable lastY

    if {[set index [$w index @$x,$y]] eq "none"} {
        if {$lasttext ne ""} {
            balloon::default_balloon $w:$lasttext leave $lastX $lastY
        }

        return
    }

    set text [$w entrycget $index -label]
    switch -- $action {
        motion {
            if {$text ne $lasttext} {
                if {$lasttext ne ""} {
                    balloon::default_balloon $w:$lasttext leave $lastX $lastY
                }

                balloon::default_balloon $w:$text enter [set lastX $X] \
                                                  [set lastY $Y] \
                                                  -text [set lasttext $text]
            }
        }

        leave {
            set lasttext ""
        }
    }

    balloon::default_balloon $w:$text $action $X $Y -text $text
}

proc emoticons::insert {iw text} {
    set p ""
    switch -- [$iw get "insert - 1 chars"] {
        "" - " " - "\n" {}

        default         {
            if {[$iw index "insert -1 chars"] ne "1.0"} {
                set p " "
            }
        }
    }

    $iw insert insert "$p$text "
}

event add <<EmoticonsMenu>> <Meta-e>
event add <<EmoticonsMenu>> <Alt-e>

if {$::tcl_platform(platform) == "windows"} {
    # workaround for shortcuts in russian keyboard layout
    event add <<EmoticonsMenu>> <Alt-oacute>
}

proc emoticons::setup_bindings {chatid type} {
    set iw [chat::input_win $chatid]

    bind $iw <<EmoticonsMenu>> \
        [list [namespace current]::show_menu %W]
    bind $iw <<EmoticonsMenu>> +break
}

proc emoticons::process_emoticons {atLevel accName} {
    variable options
    variable faces_regexp
    upvar #$atLevel $accName chunks

    set out {}
    foreach {s type tags} $chunks {
        if {$type != "text"} {
            # pass through
            lappend out $s $type $tags
            continue
        }

        set ix 0
        if {$faces_regexp != ""} {
            if {$options(match_whole_word)} {
                set regexp (?:^|\\s)($faces_regexp)(?=\\s|\$)
            } else {
                set regexp ($faces_regexp)
            }

            foreach {ign inds} [regexp -all -inline -indices -- $regexp $s] {
                lassign $inds fs fe

                if {$fs - $ix > 0} {
                    # dump chunk before emoticon:
                    lappend out [string range $s $ix [expr {$fs - 1}]] $type $tags
                }

                # dump emoticon:
                lappend out [string range $s $fs $fe] emoticon $tags

                set ix [expr {$fe + 1}]
            }
        }

        if {[string length $s] - $ix > 0} {
            # dump chunk after emoticon:
            lappend out [string range $s $ix end] $type $tags
        }
    }

    set chunks $out
}

proc emoticons::render_emoticon {w type word tags} {
    variable options

    if {$options(handle_lol)} {
        set word [string_collapseright $word]
    }

    if {[get $word] != {}} {
        $w insert end $word emoticon
        put $w $word
    } else {
        $w insert end $word
    }
}



# TODO good candidate to go outside:
proc emoticons::re_escape {s} {
    return [string map {\\ \\\\
                        * \\*
                        . \\.
                        [ \\[
                        ] \\]
                        \{ \\{
                        \} \\}
                        ( \\(
                        ) \\)
                        | \\|
                        ? \\?
                        $ \\$
                        ^ \\^
                        + \\+} $s]
}

proc emoticons::configure_richtext_widget {w} {
    variable options

    if {$options(show_emoticons)} {
        $w tag configure emoticon -elide 1
        $w tag configure emoticon_image -elide 0
    } else {
        $w tag configure emoticon -elide 0
        $w tag configure emoticon_image -elide 1
    }
}

proc emoticons::toggle_emoticons {args} {
    foreach w [::richtext::textlist] {
        configure_richtext_widget $w
    }
}

proc emoticons::enumerate_available_themes {} {
    set dirs [concat \
                  [glob -nocomplain -directory [fullpath emoticons] *] \
                  [glob -nocomplain -directory [file join $::configdir emoticons] *]]

    foreach dir $dirs {
        enumerate_theme [namespace current]::themes $dir
    }
}

proc emoticons::enumerate_theme {varName dir} {
    set icondef_path [file join $dir icondef.xml]

    if {[file isfile $icondef_path]} {
        set thdir $dir
    } elseif {![catch {::vfs::zip::Mount $dir $dir} mount_fd] && \
        [llength [glob -nocomplain $dir/*/icondef.xml]] > 0} {
        set icondef_path [lindex [glob -nocomplain $dir/*/icondef.xml] 0]
        set thdir [file dirname $icondef_path]
    } else {
        return
    }
    if {![catch {open $icondef_path} f]} {
        set icondef [read $f]
        close $f
    } else {
        catch {::vfs::zip::Unmount $mount_fd $dir}
        return
    }

    ::xmpp::xml::parseData $icondef \
                [namespace code [list get_theme_name $varName $thdir]]
}

proc emoticons::get_theme_name {varName dir xmldata} {
    upvar #0 $varName themes

    ::xmpp::xml::split $xmldata tag xmlns attrs cdata subels

    if {$tag == "name"} {
        set themes($cdata) $dir
        return 1
    }

    foreach subel $subels {
        if {[get_theme_name $varName $dir $subel]} {
            return 1
        }
    }
    return 0
}

# Gets called when options(theme) changes
proc emoticons::on_theme_changed {args} {
    variable options

    clean
    load_dir $options(theme)
}

proc emoticons::find_themes {} {
    variable options
    variable themes

    set values {}
    array unset themes *

    enumerate_available_themes

    set theme_names [lsort [array names themes]]

    set idx [lsearch -exact $theme_names Default]
    if {$idx > 0} {
        set theme_names [linsert [lreplace $theme_names $idx $idx] 0 Default]
    }

    foreach theme $theme_names {
        lappend values $themes($theme) $theme
    }

    set values [linsert $values 0 "" $options(no_theme)]

    set idx [lsearch -exact $theme_names $options(theme)]
    if {$idx >= 0} {
        set theme [lindex $theme_names $idx]
    } else {
        set idx [lsearch -exact $theme_names Default]
        if {$idx >= 0} {
            set theme [lindex $theme_names [expr {$idx - 1}]]
        } else {
            set theme ""
        }
    }

    custom::configvar [namespace current]::options(theme) -values $values
}

proc emoticons::enable_subsystem {} {
    find_themes
    on_theme_changed

    ::richtext::entity_state emoticon 1
}

proc emoticons::disable_subsystem {} {
    ::richtext::entity_state emoticon 0
}

proc emoticons::on_regex_mode_changed {args} {
    rebuild_faces_regex
}

proc emoticons::rebuild_faces_regex {} {
    variable options
    variable emoticons
    variable faces_regexp

    set faces_regexp ""

    foreach face [array names emoticons] {
        if {$faces_regexp != ""} {
            append faces_regexp |
        }

        append faces_regexp [re_escape $face]

        if {$options(handle_lol)} {
            append faces_regexp +
        }
    }
}

# Returns a string with its rightmost repeated characters collapsed into one.
# TODO good candidate to go into utils.tcl
proc emoticons::string_collapseright {s} {
    set c [string index $s end]
    set s [string trimright $s $c]
    append s $c
    return $s
}

namespace eval emoticons {
    ::hook::add postload_hook [namespace current]::enable_subsystem 40

    ::hook::add open_chat_post_hook [namespace current]::setup_bindings

    ::richtext::register_entity emoticon \
        -configurator [namespace current]::configure_richtext_widget \
        -parser [namespace current]::process_emoticons \
        -renderer [namespace current]::render_emoticon \
        -parser-priority 70
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
