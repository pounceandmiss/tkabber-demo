# pixmaps.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements loading
#       pixmaps themes.

catch {
    package require vfs::zip
}

###############################################################################

namespace eval pixmaps {
    variable theme_dirs \
        [concat [glob -nocomplain -directory \
                        [file join $::configdir pixmaps] *] \
                [glob -nocomplain -directory [fullpath pixmaps] *]]

    variable themes
    array set themes {}

    variable filenames
    array set filenames {}
}

###############################################################################

proc pixmaps::init_custom {} {
    variable options
    variable themes

    set values {}
    set theme_names [lsort [array names themes]]
    set idx [lsearch -exact $theme_names Default]
    set theme_names [linsert [lreplace $theme_names $idx $idx] 0 Default]
    foreach theme $theme_names {
        lappend values $theme $theme
    }

    custom::defvar options(pixmaps_theme) Default \
        [::msgcat::mc \
            "Tkabber icon theme. To make new theme visible for Tkabber\
             put it to some subdirectory of %s." \
             [file join $::configdir pixmaps]] \
        -group IFace -type options -values $values \
        -command [namespace current]::load_stored_theme
}

hook::add postload_hook [namespace current]::pixmaps::init_custom 45

###############################################################################

proc pixmaps::load_stored_theme {args} {
    variable options

    load_theme $options(pixmaps_theme)

    hook::run set_theme_hook
}

###############################################################################

proc pixmaps::load_themes {} {
    variable theme_dirs
    variable themes

    array unset themes

    foreach dir $theme_dirs {
        load_theme_name [namespace current]::themes $dir
    }
}

hook::add postload_hook [namespace current]::pixmaps::load_themes 40

###############################################################################

proc pixmaps::load_theme_name {var dir} {
    set icondef_path [file join $dir icondef.xml]
    if {[file isfile $icondef_path]} {
        set thdir $dir
    } elseif {![catch {::vfs::zip::Mount $dir $dir} mount_fd] && \
        ([llength [glob -nocomplain $dir/*/icondef.xml]] > 0)} {
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

    ::xmpp::xml::parseData $icondef [list pixmaps::find_name $var $thdir]
}

###############################################################################

proc pixmaps::find_name {var dir xmldata} {
    upvar #0 $var themes

    ::xmpp::xml::split $xmldata tag xmlns attrs cdata subels

    if {$tag == "name"} {
        set themes($cdata) $dir
        return 1
    }

    set found 0
    foreach subel $subels {
        if {[find_name $var $dir $subel]} {
            return 1
        }
    }
    return 0
}

###############################################################################

proc pixmaps::load_theme {theme} {
    variable themes

    load_dir $themes(Default)
    catch { load_dir $themes($theme) }
}

###############################################################################

proc pixmaps::load_dir {dir} {
    set icondef_path [file join $dir icondef.xml]
    if {![file isfile $icondef_path]} {
        return -code error
    }
    set f [open $icondef_path]
    set icondef [read $f]
    close $f

    ::xmpp::xml::parseData $icondef [list pixmaps::parse_icondef $dir]
}

###############################################################################

proc pixmaps::parse_icondef {dir xmldata} {
    ::xmpp::xml::split $xmldata tag xmlns attrs cdata subels

    if {$tag != "icondef"} {
        return -code error
    }

    foreach subel $subels {
        parse_item $dir $subel
    }

}

###############################################################################

proc pixmaps::parse_item {dir item} {
    ::xmpp::xml::split $item tag xmlns attrs cdata subels

    switch -- $tag {
        icon {
            parse_icon $dir $subels
        }
    }
}

###############################################################################

proc pixmaps::parse_icon {dir items} {
    variable filenames

    set type ""
    set image ""
    set object ""
    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels
        switch -- $tag {
            image {
                if {$xmlns == "tkimage"} {
                    set image $cdata
                }
            }
            object {
                switch -glob -- [::xmpp::xml::getAttr $attrs mime] {
                    image/ico {
                        set type ico
                        set object $cdata
                    }
                    image/* {
                        set object $cdata
                    }
                }
            }
        }
    }

    if {$image == "" || $object == ""} return

    set filename [file join $dir $object]
    set filenames($image) $filename

    switch -- $type {
        ico {}
        default {
            # TODO: use custom scale if icons are not 16x16
            create_image $image -file $filename
        }
    }
}

###############################################################################

proc pixmaps::get_filename {image} {
    variable filenames

    if {[info exists filenames($image)]} {
        return $filenames($image)
    } else {
        return -code error
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
