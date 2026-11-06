# sound.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which implements sound notifications for a predefined set of events.

namespace eval ::sound {
    # First, try to load Snack sound library. It uses Tcl event loop when
    # playing sounds, so it suffers from `heavy' procedures called in event
    # loop. Therefore it's better to put all sounds to a separate thread
    # if it's possible.

    variable snack

    if {![catch {package require Thread 2-}]} {
        variable SoundThread [thread::create]
        if {![catch {thread::send $SoundThread {package require sound 2.0}}]} {
            set snack 2
        } else {
            set snack 0
            thread::release $SoundThread
            unset SoundThread
        }
    } else {
        if {![catch {package require sound 2.0}]} {
            set snack 1
        } else {
            set snack 0
        }
    }

    custom::defgroup Sound [::msgcat::mc "Sound options."] -group Tkabber

    variable options
    variable groupchat_may_notify
    variable vfs

    if {[catch {
             set vfs [string match tclvfs* [file system [fullpath sound]]]
        }]} {
        set vfs 0
    }

    variable mute 0

    custom::defvar options(mute) 0 \
        [::msgcat::mc "Mute sound notification."] \
        -type boolean \
        -group Sound
    custom::defvar options(notify_online) 1 \
        [::msgcat::mc "Use sound notification only when being available."] \
        -type boolean \
        -group Sound
    custom::defvar options(mute_groupchat_delayed) 1 \
        [::msgcat::mc "Mute sound when displaying delayed groupchat\
                       messages."] \
        -type boolean \
        -group Sound
    custom::defvar options(mute_chat_delayed) 0 \
        [::msgcat::mc "Mute sound when displaying delayed personal chat\
                       messages."] \
        -type boolean \
        -group Sound
    custom::defvar options(mute_if_focus) 0 \
        [::msgcat::mc "Mute sound if Tkabber window is focused."] \
        -type boolean \
        -group Sound

    # One could use external play program instead of Snack
    custom::defvar options(external_play_program) "" \
        [::msgcat::mc "External program, which is to be executed to play\
                       sound. If empty, Snack library is used (if available)\
                       to play sound."] \
        -type string \
        -group Sound

    # Command line options for external play program
    custom::defvar options(external_play_program_options) "" \
        [::msgcat::mc "Options for external play program"] \
        -type string \
        -group Sound

    custom::defvar options(connected_sound) \
        [fullpath sounds default connected.wav] \
        [::msgcat::mc "Sound to play when connected to Jabber server."] \
        -command [namespace code [list load_sound_file connected]] \
        -type file \
        -group Sound
    custom::defvar options(disconnected_sound) \
        [fullpath sounds default disconnected.wav] \
        [::msgcat::mc "Sound to play when disconnected from Jabber server."] \
        -command [namespace code [list load_sound_file disconnected]] \
        -type file \
        -group Sound
    custom::defvar options(presence_available_sound) \
        [fullpath sounds default presence_available.wav] \
        [::msgcat::mc "Sound to play when available presence is received."] \
        -command [namespace code [list load_sound_file presence_available]] \
        -type file \
        -group Sound
    custom::defvar options(presence_unavailable_sound) \
        [fullpath sounds default presence_unavailable.wav] \
        [::msgcat::mc "Sound to play when unavailable presence is received."] \
        -command [namespace code [list load_sound_file presence_unavailable]] \
        -type file \
        -group Sound
    custom::defvar options(chat_my_message_sound) \
        [fullpath sounds default chat_my_message.wav] \
        [::msgcat::mc "Sound to play when sending personal chat message."] \
        -command [namespace code [list load_sound_file chat_my_message]] \
        -type file \
        -group Sound
    custom::defvar options(chat_their_message_sound) \
        [fullpath sounds default chat_their_message.wav] \
        [::msgcat::mc "Sound to play when personal chat message is received."] \
        -command [namespace code [list load_sound_file chat_their_message]] \
        -type file \
        -group Sound
    custom::defvar options(groupchat_server_message_sound) \
        [fullpath sounds default groupchat_server_message.wav] \
        [::msgcat::mc "Sound to play when groupchat server message is received."] \
        -command [namespace code [list load_sound_file groupchat_server_message]] \
        -type file \
        -group Sound
    custom::defvar options(groupchat_my_message_sound) \
        [fullpath sounds default groupchat_my_message.wav] \
        [::msgcat::mc "Sound to play when groupchat message from me is received."] \
        -command [namespace code [list load_sound_file groupchat_my_message]] \
        -type file \
        -group Sound
    custom::defvar options(groupchat_their_message_sound) \
        [fullpath sounds default groupchat_their_message.wav] \
        [::msgcat::mc "Sound to play when groupchat message is received."] \
        -command [namespace code [list load_sound_file groupchat_their_message]] \
        -type file \
        -group Sound
    custom::defvar options(groupchat_their_message_to_me_sound) \
        [fullpath sounds default chat_their_message.wav] \
        [::msgcat::mc "Sound to play when highlighted (usually addressed personally)\
                       groupchat message is received."] \
        -command [namespace code [list load_sound_file groupchat_their_message_to_me]] \
        -type file \
        -group Sound

    variable play_id ""
    variable play_priority 0

    # Do not allow play sound very often
    custom::defvar options(delay) 200 \
        [::msgcat::mc "Time interval before playing next sound\
                       (in milliseconds)."] \
        -type integer \
        -group Sound

    hook::add finload_hook [namespace current]::setup_menu
    hook::add on_change_user_presence_hook \
              [namespace current]::presence_notify 100
    hook::add change_our_presence_post_hook [namespace current]::mute_setup 100
    hook::add connected_hook [namespace current]::connected_notify 100
    hook::add disconnected_hook [namespace current]::disconnected_notify
    hook::add postload_hook [namespace current]::sound_setup 100
    hook::add draw_message_hook [namespace current]::chat_message_notify 19
}

proc ::sound::setup_menu {} {
    variable options

    set m [.mainframe getmenu tkabber]
    set ind [$m index [::msgcat::mc "Chats"]]
    incr ind

    set mm .sound_menu
    menu $mm -tearoff $::ifacetk::options(show_tearoffs)
    $mm add checkbutton -label [::msgcat::mc "Mute sound"] \
                        -variable [namespace current]::options(mute)
    $mm add checkbutton -label [::msgcat::mc "Notify only when available"] \
                        -variable [namespace current]::options(notify_online)

    $m insert $ind cascade -label [::msgcat::mc "Sound"] \
                           -menu $mm
}

proc ::sound::load_sound_file {name args} {
    variable snack
    variable options
    variable sounds
    variable SoundThread

    if {[file exist $options(${name}_sound)]} {
        set sounds($name) $options(${name}_sound)
        switch -- $snack {
            1 {
                catch {$sounds($name) destroy}
                catch {snack::sound $sounds($name) -file $sounds($name)}
            }
            2 {
                thread::send $SoundThread \
                    [list catch [list $sounds($name) destroy]]
                thread::send $SoundThread \
                    [list catch [list snack::sound $sounds($name) -file $sounds($name)]]
            }
        }
    } else {
        set sounds($name) ""
    }

}

proc ::sound::sound_setup {} {
    variable options
    variable groupchat_may_notify
    variable sounds

    foreach name [list groupchat_server_message groupchat_my_message \
                       groupchat_their_message chat_my_message \
                       chat_their_message connected disconnected \
                       presence_available presence_unavailable \
                       groupchat_their_message_to_me] {
        load_sound_file $name
    }
}

proc ::sound::play {name {priority 0}} {
    global userstatus
    variable snack
    variable options
    variable play_id
    variable play_priority
    variable SoundThread

    if {$name == ""} return

    if {$play_id != ""} {
        if {$priority >= $play_priority} {
            return
        } else {
            after cancel $play_id
        }
    }
    if {$options(delay) > 0} {
        set play_id \
            [after $options(delay) [list set [namespace current]::play_id {}]]
    }
    set play_priority $priority

    if {$options(external_play_program) == ""} {
        switch -- $snack {
            1 {
                catch {$name play -block 0}
            }
            2 {
                thread::send -async $SoundThread \
                             [list catch [list $name play -block 0]]
            }
        }
    } else {
        catch {eval "exec $options(external_play_program)\
                          $options(external_play_program_options)\
                          [list $name] &"}
    }
}

proc ::sound::chat_message_notify {chatid from type body extras} {
    variable options
    variable sounds

    if {[is_mute]} return

    set delayed [::xmpp::delay::exists $extras]

    switch -- $type {
        groupchat {
            if {$delayed && $options(mute_groupchat_delayed)} {
                return
            }
            if {[chat::get_jid $chatid] eq $from} {
                play $sounds(groupchat_server_message)
            } elseif {[chat::is_our_jid $chatid $from]} {
                play $sounds(groupchat_my_message)
            } else {
                set mynick [chat::get_nick [chat::get_xlib $chatid] \
                                           [chat::our_jid $chatid] $type]
                if {[check_message $mynick $body]} {
                    play $sounds(groupchat_their_message_to_me) -1
                } else {
                    play $sounds(groupchat_their_message)
                }
            }
        }
        chat {
            if {$delayed && $options(mute_chat_delayed)} {
                return
            }
            foreach xelem $extras {
                ::xmpp::xml::split $xelem tag xmlns attrs cdata subels
                # Don't play sound if this 'empty' tag is present. It indicates
                # messages history in chat window.
                if {[string equal $tag ""] && \
                                    [string equal $xmlns tkabber:x:nolog]} {
                    return
                }
            }

            if {[chat::is_our_jid $chatid $from]} {
                play $sounds(chat_my_message)
            } elseif {$from == ""} {
                play $sounds(groupchat_server_message)
            } else {
                play $sounds(chat_their_message) -1
            }
        }
    }
}

proc ::sound::presence_notify {name status} {
    variable options
    variable sounds

    if {[is_mute]} return

    if {$status == "available" || $status == "chat"} {
        play $sounds(presence_available)
    } else {
        play $sounds(presence_unavailable)
    }
}

proc ::sound::mute_setup {status} {
    variable options
    variable mute

    if {$options(notify_online)} {
        switch -- $status {
            available -
            chat {
                set mute 0
            }
            default {
                set mute 1
            }
        }
    } else {
        set mute 0
    }
}

proc ::sound::connected_notify {xlib} {
    variable options
    variable sounds

    if {[is_mute]} return

    play $sounds(connected) 1
}

proc ::sound::disconnected_notify {xlib} {
    variable options
    variable sounds

    if {[is_mute]} return

    play $sounds(disconnected) 1
}

proc ::sound::is_mute {} {
    variable snack
    variable options
    variable mute

    expr {($options(external_play_program) == "" && $snack == 0) || \
          $options(mute) || \
          $mute || \
          ($options(mute_if_focus) && [focus -displayof .] != "")}
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
