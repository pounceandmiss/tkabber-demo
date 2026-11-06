# chatstate.tcl --
#
#       Chat State Notifications (XEP-0085) support.

namespace eval chatstate {
    custom::defgroup Chatstate \
        [::msgcat::mc "Chat message window state plugin options."] \
        -group Chat
    custom::defvar options(enable) 0 \
        [::msgcat::mc "Enable sending chat state notifications."] \
        -type boolean -group Chatstate
    custom::defvar options(ignore_muc) 1 \
        [::msgcat::mc "Ignore mass chat state notifications in multi-user\
                       chatrooms."] \
        -type boolean -group Chatstate

    disco::register_feature $::NS(chatstate)
}

proc chatstate::is_reply_allowed {xlib jid} {
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

# Workaround a bug in JIT, which responds with error to chatstate
# events without a body
proc chatstate::ignore_error \
     {xlib from id type is_subject subject body err thread priority x} {
    switch -- $type/$id {
        error/chatstate {
            return -code break
        }
    }
}

hook::add process_message_hook [namespace current]::chatstate::ignore_error 20

proc chatstate::flush_composing {chatid user body type} {
    variable chatstate
    variable event_afterid

    set chatstate(composing,$chatid) 1
    set chatstate(paused,$chatid) 0
    if {[info exists event_afterid(pause,$chatid)]} {
        after cancel $event_afterid(pause,$chatid)
        unset event_afterid(pause,$chatid)
    }
}

hook::add chat_send_message_hook \
          [namespace current]::chatstate::flush_composing 91

proc chatstate::process_message \
        {xlib from id type is_subject subject body err thread priority xs} {
    set chatid [chat::chatid $xlib $from]

    foreach x $xs {
        ::xmpp::xml::split $x tag xmlns attrs cdata subels
        switch -- $xmlns \
            $::NS(chatstate) {
                return [process_x_chatstate $chatid $from $type $body $x]
            }
    }
}

hook::add process_message_hook [namespace current]::chatstate::process_message

proc chatstate::process_x_chatstate {chatid from type body x} {
    variable options
    variable chatstate

    if {$options(ignore_muc) && $type == "groupchat"} {
        return
    }

    ::xmpp::xml::split $x tag xmlns attrs cdata subels

    switch -- $tag {
        active {
            if {![info exists chatstate(active,$chatid)] || \
                    !$chatstate(active,$chatid)} {
                set chatstate(active,$chatid) 1
                change_status $chatid active
            }
        }
        inactive {
            if {[info exists chatstate(active,$chatid)] && \
                    $chatstate(active,$chatid)} {
                set chatstate(active,$chatid) 0
                change_status $chatid inactive
            }
        }
        gone {
            set chatstate(active,$chatid) 0
            change_status $chatid gone
        }
        composing -
        paused {
            change_status $chatid $tag
        }
    }
    return
}

proc chatstate::change_status {chatid status} {
    global usetabbar
    variable event_afterid

    if {[info exists event_afterid(clear,$chatid)]} {
        after cancel $event_afterid(clear,$chatid)
    }
    set cw [chat::winid $chatid]
    set jid [chat::get_jid $chatid]
    set text ""
    set stext ""
    switch -- $status {
        active {
            set text [::msgcat::mc "Chat window is active"]
            set stext [::msgcat::mc "%s has activated chat window" $jid]
        }
        composing {
            set text [::msgcat::mc "Composing a reply"]
            set stext [::msgcat::mc "%s is composing a reply" $jid]
        }
        paused {
            set text [::msgcat::mc "Paused a reply"]
            set stext [::msgcat::mc "%s is paused a reply" $jid]
        }
        inactive {
            set text [::msgcat::mc "Chat window is inactive"]
            set stext [::msgcat::mc "%s has inactivated chat window" $jid]
        }
        gone {
            set text [::msgcat::mc "Chat window is gone"]
            set stext [::msgcat::mc "%s has gone chat window" $jid]
        }
    }

    if {$stext != "" && $usetabbar} {
        set_status $stext
    }

    if {![winfo exists $cw]} return

    $cw.status.event configure -text $text
    set event_afterid(clear,$chatid) \
        [after 10000 [list [namespace current]::clear_status $chatid]]
}

proc chatstate::clear_status {chatid} {
    set cw [chat::winid $chatid]

    if {![winfo exists $cw]} return

    $cw.status.event configure -text ""
}

proc chatstate::event_composing {iw sym} {
    variable options
    variable chatstate
    variable event_afterid

    if {$sym == ""} return

    set cw [join [lrange [split $iw .] 0 end-1] .]
    set chatid [chat::winid_to_chatid $cw]

    if {![chat::is_chat $chatid]} return

    if {![info exists chatstate(windowactive,$chatid)] || \
            ($chatstate(windowactive,$chatid) == 0)} return

    set empty [expr {[string length [$iw get 0.0 "end-1c"]] == 0}]

    if {[info exists event_afterid(pause,$chatid)]} {
        after cancel $event_afterid(pause,$chatid)
        unset event_afterid(pause,$chatid)
    }

    set paused [expr {[info exists chatstate(paused,$chatid)] && \
                      $chatstate(paused,$chatid)}]
    if {!$empty} {
        set event_afterid(pause,$chatid) \
                [after 6400 [list [namespace current]::send_paused $chatid]]

        if {($sym == "<Delete>" || $sym == "<BackSpace>") && !$paused} return
    }

    if {[info exists chatstate(composing,$chatid)] && \
            ($chatstate(composing,$chatid) == $empty) && \
            !$paused} return

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]

    set chatstate(composing,$chatid) $empty
    set chatstate(paused,$chatid) 0

    if {![is_reply_allowed $xlib $jid]} return

    if {$empty} {
        lappend xlist [::xmpp::xml::create active -xmlns $::NS(chatstate)]
    } else {
        lappend xlist [::xmpp::xml::create composing -xmlns $::NS(chatstate)]
    }

    ::xmpp::sendMessage $xlib $jid -type chat -id chatstate -xlist $xlist
}

proc chatstate::send_paused {chatid} {
    variable options
    variable chatstate
    variable event_afterid

    if {[info exists event_afterid(pause,$chatid)]} {
        after cancel $event_afterid(pause,$chatid)
        unset event_afterid(pause,$chatid)
    }

    if {![info exists chatstate(windowactive,$chatid)] || \
            ($chatstate(windowactive,$chatid) == 0)} return

    if {![info exists chatstate(composing,$chatid)] || \
            $chatstate(composing,$chatid)} return

    if {![chat::is_chat $chatid]} return

    set chatstate(paused,$chatid) 1

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]

    if {![is_reply_allowed $xlib $jid]} return

    lappend xlist [::xmpp::xml::create paused -xmlns $::NS(chatstate)]

    ::xmpp::sendMessage $xlib $jid -type chat -id chatstate -xlist $xlist
}

proc chatstate::setup_ui {chatid type} {
    variable chatstate

    if {![chat::is_chat $chatid]} return

    set cw [chat::winid $chatid]
    set input [chat::input_win $chatid]

    set l $cw.status.event
    if {![winfo exists $l]} {
        Label $l
        pack $l -side left
    }

    bind $input <Key-Delete> \
         [list after idle [namespace code [list event_composing %W <Delete>]]]
    bind $input <Key-BackSpace> \
         [list after idle [namespace code [list event_composing %W <BackSpace>]]]
}

hook::add text_on_keypress_hook [namespace current]::chatstate::event_composing
hook::add open_chat_post_hook [namespace current]::chatstate::setup_ui

proc chatstate::clear_status_on_send {chatid user body type} {
    if {![chat::is_chat $chatid]} return
    clear_status $chatid
}

hook::add chat_send_message_hook \
          [namespace current]::chatstate::clear_status_on_send

proc chatstate::make_xlist {varname chatid user id body type} {
    variable options
    variable chatstate
    upvar 2 $varname var

    if {$type != "chat"} {
        return
    }

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]

    set chatstate(windowactive,$chatid) 1

    if {![is_reply_allowed $xlib $jid]} return

    lappend var [::xmpp::xml::create active -xmlns $::NS(chatstate)]
    return
}

hook::add chat_send_message_xlist_hook \
          [namespace current]::chatstate::make_xlist

proc chatstate::send_gone {chatid} {
    variable options
    variable chatstate
    variable event_afterid

    if {[info exists event_afterid(pause,$chatid)]} {
        after cancel $event_afterid(pause,$chatid)
        unset event_afterid(pause,$chatid)
    }

    if {[info exists event_afterid(clear,$chatid)]} {
        after cancel $event_afterid(clear,$chatid)
        unset event_afterid(clear,$chatid)
    }

    if {![info exists chatstate(windowactive,$chatid)] || \
            ($chatstate(windowactive,$chatid) == 0)} return

    if {![chat::is_chat $chatid]} return

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]

    catch {unset chatstate(windowactive,$chatid)}
    catch {unset chatstate(composing,$chatid)}
    catch {unset chatstate(paused,$chatid)}

    if {![is_reply_allowed $xlib $jid]} return

    lappend xlist [::xmpp::xml::create gone -xmlns $::NS(chatstate)]

    ::xmpp::sendMessage $xlib $jid -type chat -id chatstate -xlist $xlist
}

hook::add close_chat_post_hook \
          [namespace current]::chatstate::send_gone 10

# vim:ft=tcl:ts=8:sw=4:sts=4:et
