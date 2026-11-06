# unisymbols.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       replaces &<hexcode>Ctrl+; by a Unicode symbol with the specified code.

namespace eval unisymbols {}

proc unisymbols::expand_entity {iw} {
    set s [$iw get "insert linestart" insert]
    if {[regexp {.*&(.*)} $s temp e]} {
        if {$e != "" && [string is xdigit $e]} {
            $iw delete "insert -[string length $e] char -1c" insert
            $iw insert insert [format %c 0x$e]
        }
    }
}

proc unisymbols::setup_bindings {chatid type} {
    set iw [chat::input_win $chatid]
    bind $iw <Control-Key-semicolon> \
        [list [namespace current]::expand_entity %W]
}

hook::add open_chat_post_hook [namespace current]::unisymbols::setup_bindings

# vim:ft=tcl:ts=8:sw=4:sts=4:et
