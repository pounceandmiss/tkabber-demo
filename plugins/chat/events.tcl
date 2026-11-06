# events.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which implements Message Events (XEP-0022) protocol.

namespace eval events {
    custom::defgroup Events \
        [::msgcat::mc "Chat message events plugin options."] \
        -group Chat
    custom::defvar options(enable) 1 \
        [::msgcat::mc "Enable sending chat message events."] \
        -type boolean -group Events

    disco::register_feature $::NS(event)
}

proc events::is_reply_allowed {xlib jid} {
    variable options

    if {!$options(enable)} {
        return 0
    }

    if {[get_jid_status $xlib $jid] == "unavailable"} {
        return 0
    }

    set chatid [chat::chatid $xlib [::xmpp::jid::removeResource $jid]]
    if {[chat::is_groupchat $chatid]} {
        return 1
    }

    return [roster::is_trusted $xlib $jid]
}

proc events::process_message \
        {xlib from id type is_subject subject body err thread priority xs} {
    set chatid [chat::chatid $xlib $from]

    foreach x $xs {
        ::xmpp::xml::split $x tag xmlns attrs cdata subels
        switch -- $xmlns \
            $::NS(event) {
                return [process_x_event 0 $chatid $from $type $body $x]
            }
    }
}

hook::add process_message_hook [namespace current]::events::process_message

proc events::process_x {chatid from type body xs} {
    variable chats
    variable options

    if {$type == "chat"} {
        foreach x $xs {
            ::xmpp::xml::split $x tag xmlns attrs cdata subels
            switch -- $xmlns \
                $::NS(event) {
                    return [process_x_event 1 $chatid $from $type $body $x]
                }
        }
    }
}

hook::add draw_message_hook [namespace current]::events::process_x 6

proc events::process_x_event {check_request chatid from type body x} {
    variable options
    variable events

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]
    set cw [chat::winid $chatid]

    ::xmpp::xml::split $x tag xmlns attrs cdata subels

    set offline 0
    set delivered 0
    set displayed 0
    set composing 0
    set id 0
    foreach subel $subels {
        ::xmpp::xml::split $subel stag sxmlns sattrs scdata ssubels

        switch -- $stag {
            offline   {set offline 1}
            delivered {set delivered 1}
            displayed {set displayed 1}
            composing {set composing 1}
            id        {set id        1}
        }
    }
    if {$id && !$check_request} {
        set status ""
        if {$offline}   {set status offline}
        if {$delivered} {set status delivered}
        if {$displayed} {set status displayed}
        if {$composing} {set status composing}
        change_status $chatid $status
        if {$body != ""} {
            # due to some buggy clients (e.g. Yahoo-t), which send <id/>
            # with real messages
            return
        } else {
            return -code break
        }
    } elseif {!$id && $check_request} {
        clear_status $chatid

        set events(displayed,$chatid) $displayed
        set events(composing,$chatid) $composing

        if {![is_reply_allowed $xlib $jid]} return

        lappend eventtags [::xmpp::xml::create id \
                               -cdata $::chat::chats(id,$chatid)]
        if {$delivered} {
            lappend eventtags [::xmpp::xml::create delivered]
        }
        if {$displayed} {
            if {$::usetabbar} {
                set page [string range [win_id tab $cw] 1 end]
                if {[.nb raise] == $page} {
                    lappend eventtags [::xmpp::xml::create displayed]
                    set events(displayed,$chatid) 0
                }
            } else {
                lappend eventtags [::xmpp::xml::create displayed]
                set events(displayed,$chatid) 0
            }
        }
        if {[llength $eventtags] > 1} {
            lappend xlist [::xmpp::xml::create x \
                                -xmlns $::NS(event) \
                                -subelements $eventtags]

            ::xmpp::sendMessage $xlib $from -xlist $xlist
        }
    }
    return
}

proc events::change_status {chatid status} {
    variable event_afterid

    if {[info exists event_afterid($chatid)]} {
        after cancel $event_afterid($chatid)
    }
    set cw [chat::winid $chatid]
    set jid [chat::get_jid $chatid]
    set text ""
    set stext ""
    switch -- $status {
        offline   {
            set text [::msgcat::mc "Message stored on the server"]
            set stext [::msgcat::mc "Message stored on %s's server" \
                           $jid]
        }
        delivered {
            set text [::msgcat::mc "Message delivered"]
            set stext [::msgcat::mc "Message delivered to %s" $jid]
        }
        displayed {
            set text [::msgcat::mc "Message displayed"]
            set stext [::msgcat::mc "Message displayed to %s" $jid]
        }
        composing {
            set text [::msgcat::mc "Composing a reply"]
            set stext [::msgcat::mc "%s is composing a reply" $jid]
        }
    }

    if {$stext != "" && $::usetabbar} {set_status $stext}
    if {![winfo exists $cw]} return
    $cw.status.event configure -text $text
    set event_afterid($chatid) \
        [after 10000 [list [namespace current]::clear_status $chatid]]
}

proc events::clear_status {chatid} {
    set cw [chat::winid $chatid]
    if {![winfo exists $cw]} return
    $cw.status.event configure -text ""
}

proc events::send_event_on_raise {cw chatid} {
    variable options
    variable events

    if {![chat::is_chat $chatid]} return
    if {![info exists events(displayed,$chatid)] || \
            !$events(displayed,$chatid)} return

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]

    set events(displayed,$chatid) 0

    if {![is_reply_allowed $xlib $jid]} return

    lappend eventtags [::xmpp::xml::create id \
                           -cdata $::chat::chats(id,$chatid)]
    lappend eventtags [::xmpp::xml::create displayed]

    lappend xlist [::xmpp::xml::create x \
                        -xmlns $::NS(event) \
                        -subelements $eventtags]

    ::xmpp::sendMessage $xlib $jid -xlist $xlist
}

hook::add raise_chat_tab_hook [namespace current]::events::send_event_on_raise

proc events::event_composing {iw sym} {
    variable options
    variable events

    if {$sym == ""} return

    set cw [join [lrange [split $iw .] 0 end-1] .]
    set chatid [chat::winid_to_chatid $cw]

    if {![chat::is_chat $chatid]} return
    if {![info exists events(composing,$chatid)] || \
            !$events(composing,$chatid)} return

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]

    set events(composing,$chatid) 0

    if {![is_reply_allowed $xlib $jid]} return

    lappend eventtags [::xmpp::xml::create id \
                           -cdata $::chat::chats(id,$chatid)]
    lappend eventtags [::xmpp::xml::create composing]

    lappend xlist [::xmpp::xml::create x \
                        -xmlns $::NS(event) \
                        -subelements $eventtags]

    ::xmpp::sendMessage $xlib $jid -xlist $xlist
}

proc events::setup_ui {chatid type} {
    variable events

    if {![chat::is_chat $chatid]} return

    set cw [chat::winid $chatid]

    set l $cw.status.event
    if {![winfo exists $l]} {
        Label $l
        pack $l -side left
    }
}

hook::add text_on_keypress_hook [namespace current]::events::event_composing
hook::add open_chat_post_hook [namespace current]::events::setup_ui

proc events::clear_status_on_send {chatid user body type} {
    if {![chat::is_chat $chatid]} return
    clear_status $chatid
}

hook::add chat_send_message_hook \
          [namespace current]::events::clear_status_on_send

proc events::make_xlist {varname chatid user id body type} {
    variable options
    upvar 2 $varname var

    if {$type != "chat"} return

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]

    if {![is_reply_allowed $xlib $jid]} return

    lappend events [::xmpp::xml::create offline]
    lappend events [::xmpp::xml::create delivered]
    lappend events [::xmpp::xml::create displayed]
    lappend events [::xmpp::xml::create composing]
    lappend var [::xmpp::xml::create x \
                        -xmlns $::NS(event) \
                        -subelements $events]
    return
}

hook::add chat_send_message_xlist_hook [namespace current]::events::make_xlist

# vim:ft=tcl:ts=8:sw=4:sts=4:et
