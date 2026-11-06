# copy_jid.tcl --
#
#       Copy JID to clipboard.

namespace eval copy_jid {}

proc copy_jid::copy {m jid} {
    clipboard clear -displayof $m
    clipboard append -displayof $m $jid
}

proc copy_jid::add_menu_item {m xlib jid} {
    $m add command \
           -label [::msgcat::mc "Copy JID to clipboard"] \
           -command [list [namespace current]::copy $m $jid]
}

proc copy_jid::add_muc_menu_item {m xlib jid} {
    set real_jid [::muc::get_real_jid $xlib $jid]
    if {$real_jid != ""} {
        $m add command \
           -label [::msgcat::mc "Copy real JID to clipboard"] \
           -command [list [namespace current]::copy $m $real_jid]
    } else {
        $m add command \
           -label [::msgcat::mc "Copy real JID to clipboard"] \
           -state disabled
    }
}

hook::add roster_create_groupchat_user_menu_hook \
    [namespace current]::copy_jid::add_menu_item 44
hook::add roster_create_groupchat_user_menu_hook \
    [namespace current]::copy_jid::add_muc_menu_item 44.5
hook::add chat_create_user_menu_hook \
    [namespace current]::copy_jid::add_menu_item 44
hook::add chat_create_conference_menu_hook \
    [namespace current]::copy_jid::add_menu_item 44
hook::add roster_jid_popup_menu_hook \
    [namespace current]::copy_jid::add_menu_item 44
hook::add roster_conference_popup_menu_hook \
    [namespace current]::copy_jid::add_menu_item 44
hook::add roster_service_popup_menu_hook \
    [namespace current]::copy_jid::add_menu_item 44
hook::add message_dialog_menu_hook \
    [namespace current]::copy_jid::add_menu_item 44
hook::add search_popup_menu_hook \
    [namespace current]::copy_jid::add_menu_item 44

# vim:ft=tcl:ts=8:sw=4:sts=4:et
