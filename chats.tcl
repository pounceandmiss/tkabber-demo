# chats.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements user
#       interface for the main Tkabber purpose: for chats.

package require textutil

if {$::darktheme} {
    option add *Chat.theyforeground        steelblue1      widgetDefault
    option add *Chat.meforeground          coral3          widgetDefault
    option add *Chat.highlightforeground   coral3          widgetDefault
    option add *Chat.serverlabelforeground darkseagreen3   widgetDefault
    option add *Chat.serverforeground      darkseagreen3   widgetDefault
    option add *Chat.infoforeground        steelblue1      widgetDefault
    option add *Chat.errforeground         coral3          widgetDefault
} else {
    option add *Chat.theyforeground        dodgerblue4 widgetDefault
    option add *Chat.meforeground          firebrick4  widgetDefault
    option add *Chat.highlightforeground   firebrick4  widgetDefault
    option add *Chat.serverlabelforeground DarkGreen   widgetDefault
    option add *Chat.serverforeground      DarkGreen   widgetDefault
    option add *Chat.infoforeground        dodgerblue4 widgetDefault
    option add *Chat.errforeground         firebrick   widgetDefault
}

option add *Chat.inputheight           3           widgetDefault

namespace eval chat {
    variable enrichid 0
    custom::defgroup Chat [::msgcat::mc "Chat options."] -group Tkabber
    custom::defvar options(smart_scroll) 1 \
        [::msgcat::mc "Enable chat window autoscroll only when\
                       last message is shown."] \
        -type boolean -group Chat
    custom::defvar options(stop_scroll) 0 \
        [::msgcat::mc "Stop chat window autoscroll."] \
        -type boolean -group Chat
    custom::defvar options(display_status_description) 1 \
        [::msgcat::mc "Display description of user status in chat windows."] \
        -type boolean -group Chat
    custom::defvar options(gen_status_change_msgs) 0 \
        [::msgcat::mc "Generate chat messages when chat peer\
            changes his/her status and/or status message"] \
        -type boolean -group Chat

    custom::defvar open_chat_list {} [::msgcat::mc "List of users for chat."] \
            -group Hidden

    variable chatid
}

set chat_width 50
set chat_height 18

plugins::load [file join plugins chat]

proc chat::open_chat_dialog {} {
    variable open_chat_jid
    variable open_chat_list
    variable open_chat_xlib

    if {[llength [connections]] == 0} return

    set gw .open_chat
    catch { destroy $gw }

    set xlib [lindex [connections] 0]
    set open_chat_xlib [connection_jid $xlib]

    Dialog $gw -title [::msgcat::mc "Open chat"] -anchor e \
            -default 0 -cancel 1

    set gf [$gw getframe]
    grid columnconfigure $gf 1 -weight 1

    set open_chat_jid ""

    label $gf.ljid -text [::msgcat::mc "JID:"]
    Combobox $gf.jid -textvariable [namespace current]::open_chat_jid \
            -values [linsert $open_chat_list 0 ""] -width 35

    grid $gf.ljid -row 0 -column 0 -sticky e
    grid $gf.jid  -row 0 -column 1 -sticky ew

    if {[llength [connections]] > 1} {
        set connections {}
        foreach c [connections] {
            lappend connections [connection_jid $c]
        }
        label $gf.lconnection -text [::msgcat::mc "Connection:"]
        Combobox $gf.connection \
                 -textvariable [namespace current]::open_chat_xlib \
                 -values $connections

        grid $gf.lconnection -row 1 -column 0 -sticky e
        grid $gf.connection  -row 1 -column 1 -sticky ew
    }

    $gw add -text [::msgcat::mc "Chat"] \
            -command "[namespace current]::open_chat $gw"
    $gw add -text [::msgcat::mc "Cancel"] -command "destroy $gw"

    $gw draw $gf.jid
}

proc chat::open_chat {gw} {
    variable open_chat_jid
    variable open_chat_list
    variable open_chat_xlib

    destroy $gw

    if {[llength [connections]] == 0} return

    foreach c [connections] {
        if {[connection_jid $c] eq $open_chat_xlib} {
            set xlib $c
        }
    }
    if {![info exists xlib]} {
        set xlib [lindex [connections] 0]
    }

    set open_chat_list [update_combo_list $open_chat_list $open_chat_jid 20]
    open_to_user $xlib $open_chat_jid
}

# chat::close --
#  Closes the container chat window for a chat identified
#  by given chat ID. Has the same effect as if the user closed
#  the chat's window using the UI.
proc chat::close {chatid} {
    ifacetk::destroy_win [winid $chatid]
}

proc chat::get_nick {xlib jid type} {
    variable chats

    set nick $jid
    switch -- $type {
        chat {
            set group [::xmpp::jid::removeResource $jid]
            set chatid1 [chatid $xlib $group]
            if {[is_groupchat $chatid1]} {
                set nick [::xmpp::jid::resource $jid]
            } else {
                set rjid [roster::find_jid $xlib $jid]
                set nick [roster::itemconfig $xlib $rjid -name]
                if {$rjid eq "" || $nick eq ""} {
                    if {[::xmpp::jid::node $jid] ne ""} {
                        set nick [::xmpp::jid::node $jid]
                    } else {
                        set nick $jid
                    }
                }
            }
        }
        groupchat {
            set nick [::xmpp::jid::resource $jid]
        }
    }
    return $nick
}

proc chat::winid {chatid} {
    return .chat_[jid_to_tag $chatid]
}

proc chat::winid_to_chatid {winid} {
    variable chat_id
    expr {[info exists chat_id($winid)] ? $chat_id($winid) : ""}
}

proc chat::chatid {xlib jid} {
    list $xlib $jid
}

proc chat::get_xlib {chatid} {
    lindex $chatid 0
}

proc chat::get_jid {chatid} {
    lindex $chatid 1
}

###############################################################################

proc client:message {xlib from type x args} {
    set id ""
    set body ""
    set is_subject 0
    set subject ""
    set thread ""
    set priority ""
    set err {}
    foreach {key val} $args {
        switch -- $key {
            -id {
                set id $val
            }
            -body {
                set body $val
            }
            -subject {
                set is_subject 1
                set subject $val
            }
            -error {
                set err $val
            }
        }
    }

    debugmsg chat "MESSAGE: $xlib; $from; $id; $type; $is_subject;\
                   $subject; $body; $err; $thread; $priority; $x"

    hook::run rewrite_message_hook xlib from id type is_subject \
                                   subject body err thread priority x

    debugmsg chat "REWRITTEN MESSAGE: $xlib; $from; $id; $type; $is_subject;\
                   $subject; $body; $err; $thread; $priority; $x"

    hook::run process_message_hook $xlib $from $id $type $is_subject \
                                   $subject $body $err $thread $priority $x
}

###############################################################################

proc chat::rewrite_message \
     {vxlib vfrom vid vtype vis_subject vsubject \
      vbody verr vthread vpriority vx} {
    upvar 2 $vfrom from
    upvar 2 $vtype type
    variable options

    if {$type eq ""} {
        # If message lacks type set it to 'normal' as required by RFC
        set type normal
    }

    set from [::xmpp::jid::normalize $from]
}

hook::add rewrite_message_hook [namespace current]::chat::rewrite_message 60

###############################################################################

proc chat::process_message_fallback \
     {xlib from id type is_subject subject body err thread priority x} {
    variable chats

    # $from is normalized here (in rewrite_message_hook)
    set chatid [chatid $xlib $from]

    switch -- $type {
        chat {
            if {$thread ne ""} {
                set chats(thread,$chatid) $thread
            }
            set chats(id,$chatid) $id
        }
        groupchat {
            set chatid [chatid $xlib [::xmpp::jid::removeResource $from]]

            if {![is_groupchat $chatid]} return

            if {$is_subject} {
                set_subject $chatid $subject
                if {$body eq ""} {
                    set nick [::xmpp::jid::resource $from]
                    if {$nick eq ""} {
                        set body \
                            [::msgcat::mc "Subject is set to: %s" $subject]
                    } else {
                        set body \
                            [::msgcat::mc "/me has set the subject to: %s" \
                                          $subject]
                    }
                }
            }
        }
        error {
            if {[is_groupchat $chatid]} {
                if {$is_subject} {
                    set body "subject: "
                    restore_subject $chatid
                } else {
                    set body ""
                }
                append body [error_to_string $err]
            } else {
                if {$is_subject && $subject ne ""} {
                    set body "[::msgcat::mc {Subject:}] $subject\n$body"
                }
                set body "[error_to_string $err]\n$body"
            }
        }
        default {
            debugmsg chat "MESSAGE: UNSUPPORTED message type '$type'"
        }
    }

    #chat::open_window $chatid $type

    chat::add_message $chatid $from $type $body $x
    if {[llength $x] > 0} {
        message::show_dialog \
                $xlib $from $id $type $subject $body $thread $priority $x 0
    }
}

hook::add process_message_hook \
    [namespace current]::chat::process_message_fallback 99

###############################################################################

proc chat::window_titles {chatid} {
    set xlib [get_xlib $chatid]
    set jid [get_jid $chatid]
    set rjid [roster::find_jid $xlib $jid]
    set chatname [roster::itemconfig $xlib $rjid -name]
    if {$rjid ne "" && $chatname ne ""} {
        if {[is_groupchat [chatid $xlib $rjid]] && ![is_groupchat $chatid]} {
            set titlename $jid
            set tabtitlename [get_nick $xlib $jid chat]
        } else {
            set titlename $chatname
            set tabtitlename $chatname
        }
    } else {
        set titlename $jid
        if {[is_groupchat $chatid]} {
            set tabtitlename [::xmpp::jid::node $jid]
        } else {
            set tabtitlename [get_nick $xlib $jid chat]
        }
    }
    if {$tabtitlename eq ""} {
        set tabtitlename $titlename
    }
    return [list $tabtitlename [::msgcat::mc "%s - Chat" $titlename]]
}

proc chat::reconnect_groupchats {xlib} {
    variable chats

    foreach chatid [opened $xlib] {
        if {[is_groupchat $chatid]} {
            if {[info exists ::muc::muc_password($chatid)]} {
                set password $::muc::muc_password($chatid)
            } else {
                set password ""
            }
            muc::join_group $xlib \
                            [get_jid $chatid] \
                            [get_our_groupchat_nick $chatid] \
                            $password
        }
    }
}

hook::add connected_hook [namespace current]::chat::reconnect_groupchats 99

proc chat::disconnect_groupchats {xlib} {
    variable chats
    global statusdesc

    foreach chatid [opened $xlib] {
        if {![winfo exists [chat_win $chatid]]} return

        set jid [get_jid $chatid]

        if {[is_groupchat $chatid]} {
            muc::reset_group $chatid
            client:presence $xlib $jid unavailable "" {}
            foreach jid [get_jids_of_user $xlib $jid] {
                client:presence $xlib $jid unavailable "" {}
            }
        }
        add_message $chatid $jid error [::msgcat::mc "Disconnected"] {}

        set cw [winid $chatid]

        if {[winfo exists $cw.status.icon]} {
            $cw.status.icon configure \
                -image [ifacetk::roster::get_jid_icon $xlib $jid unavailable] \
                -helptext ""
        }

        if {[winfo exists $cw.status.desc]} {
            $cw.status.desc configure \
                -text "($statusdesc(unavailable))" \
                -helptext ""
        }
    }
}

hook::add disconnected_hook [namespace current]::chat::disconnect_groupchats

proc chat::open_window {chatid type args} {
    global chat_width chat_height
    variable chats
    variable chat_id
    variable options
    global statusdesc

    set xlib [get_xlib $chatid]
    set jid [get_jid $chatid]
    set jid [::xmpp::jid::normalize $jid]
    set chatid [chatid $xlib $jid]

    set cw [winid $chatid]

    set cleanroster 1
    foreach {key val} $args {
        switch -- $key {
            -cleanroster { set cleanroster $val }
        }
    }

    if {[winfo exists $cw]} {
        if {!$::usetabbar && \
                [info exists ::raise_on_activity] && $::raise_on_activity} {
            if {$type eq "chat"} {
                wm deiconify $cw
            }
            raise $cw
        }
        return
    }

    switch -- $type {
        chat -
        groupchat { }
        error {
            # TODO: check JID category
            set type chat
        }
    }

    hook::run open_chat_pre_hook $chatid $type

    set chats(type,$chatid) $type
    set chats(subject,$chatid) ""
    set chats(exit_status,$chatid) ""

    if {$type eq "groupchat"} {
        # Variable to hold groupchat roster items

        set chats(roster,$chatid) [dict create moderator {} \
                                               participant {} \
                                               visitor {} \
                                               user {}]
    }

    add_to_opened $chatid

    set chat_id($cw) $chatid

    lassign [chat::window_titles $chatid] chats(tabtitlename,$chatid) \
        chats(titlename,$chatid)

    add_win $cw -title $chats(titlename,$chatid) \
        -tabtitle $chats(tabtitlename,$chatid) \
        -class Chat -type $type \
        -raisecmd [list [namespace current]::raisecmd $chatid $cw]

    Frame $cw.status
    pack $cw.status -side top -fill x
    if {$type eq "chat"} {
        set status [get_user_status $xlib $jid]
        Label $cw.status.icon \
            -image [ifacetk::roster::get_jid_icon $xlib $jid $status] \
            -helptext [get_user_status_desc $xlib $jid]
        pack $cw.status.icon -side left
        if {$options(display_status_description)} {
            Label $cw.status.desc -text "($statusdesc($status))" \
                -helptext [get_user_status_desc $xlib $jid]
            pack $cw.status.desc -side left
        }
    }

    set mb $cw.status.mb
    set m $mb.menu
    if {$type eq "chat"} {
        MenuToolbutton $mb -text $jid -menu $m
        menu $m -tearoff 0 \
                -postcommand [namespace code \
                                        [list create_user_menu $m $chatid]]
        pack $mb -side left
    } else {
        MenuToolbutton $mb -text [::msgcat::mc "Subject:"] \
                       -direction below -menu $m
        menu $m -tearoff 0 \
                -postcommand [namespace code \
                                    [list create_conference_menu $m $chatid]]
        pack $mb -side left

        Entry $cw.status.subject \
            -xscrollcommand [list [namespace current]::set_subject_tooltip \
                                  $chatid]
        pack $cw.status.subject -side left -fill x -expand yes

        bind $cw.status.subject <Return> \
            [list chat::change_subject [double% $chatid]]

        bind $cw.status.subject <Escape> \
            [list chat::restore_subject [double% $chatid]]

        balloon::setup $cw.status.subject \
            -command [list [namespace current]::set_subject_balloon $chatid]
    }
    foreach tag [bind Menubutton] {
        if {[string first 1 $tag] >= 0} {
            regsub -all 1 $tag 3 new
            bind $cw.status.mb $new [bind Menubutton $tag]
        }
    }

    PanedWin $cw.pw0 -orient vertical
    pack $cw.pw0 -fill both -expand yes


    set upw [PanedWinAdd $cw.pw0 -weight 1]
    set dow [PanedWinAdd $cw.pw0 -weight 0]

    set isw [ScrolledWindow $cw.isw -scrollbar vertical]
    pack $cw.isw -fill both -expand yes -side bottom -in $dow
    set chats(inputwin,$chatid) \
        [Wrapped [textUndoable $cw.input -width $chat_width \
                                         -height [option get $cw inputheight \
                                                                 Chat] \
                                         -wrap word]]
    $isw setwidget $cw.input
    [winfo parent $dow] configure -height [winfo reqheight $cw.input]

    if {$type eq "groupchat"} {
        PanedWin $cw.pw -orient horizontal
        pack $cw.pw -fill both -expand yes -in $upw

        set cf [PanedWinAdd $cw.pw -weight 1]

        set uw [PanedWinAdd $cw.pw -weight 0]
        set chats(userswin,$chatid) $uw.users

        set rosterwidth [option get . chatRosterWidth [winfo class .]]
        if {$rosterwidth eq ""} {
            set rosterwidth [winfo pixels . 3c]
        }

        ifacetk::roster::create $uw.users -width $rosterwidth \
            -popup ifacetk::roster::groupchat_popup_menu \
            -singleclick [list [namespace current]::user_singleclick $chatid] \
            -doubleclick ifacetk::roster::jid_doubleclick \
            -draginitcmd [namespace current]::draginitcmd \
            -dropovercmd [list [namespace current]::dropovercmd $chatid] \
            -dropcmd [list [namespace current]::dropcmd $chatid]
        pack $uw.users -fill both -side right -expand yes
        [winfo parent $uw] configure -width $rosterwidth

        set pack_in $cf
    } else {
        set cf $cw
        set pack_in $upw
    }

    set csw [ScrolledWindow $cf.csw -scrollbar vertical -auto none]
    pack $csw -expand yes -fill both -side top -in $pack_in

    ::richtext::richtext $cf.chat \
        -width $chat_width -height $chat_height \
        -wrap word

    set chats(chatwin,$chatid) $cf.chat

    ::plugins::chatlog::config $cf.chat \
        -theyforeground [query_optiondb $cw theyforeground] \
        -meforeground [query_optiondb $cw meforeground] \
        -serverlabelforeground [query_optiondb $cw serverlabelforeground] \
        -serverforeground [query_optiondb $cw serverforeground] \
        -infoforeground [query_optiondb $cw infoforeground] \
        -errforeground [query_optiondb $cw errforeground] \
        -highlightforeground [query_optiondb $cw highlightforeground]

    $csw setwidget $cf.chat

    reverse_scroll [chat_win $chatid]

    focus [input_win $chatid]

    bind [input_win $chatid] <Shift-Key-Return> { }

    bind [input_win $chatid] <Key-Return> [double% "
        chat::send_message [list $cw] [list $chatid] [list $type]
        break"]

    set wr [Wrapped [chat_win $chatid]]

    regsub -all %W [bind Text <Prior>] [double% $wr] prior_binding
    regsub -all %W [bind Text <Next>] [double% $wr] next_binding
    bind [input_win $chatid] <Meta-Prior> $prior_binding
    bind [input_win $chatid] <Meta-Next> $next_binding
    bind [input_win $chatid] <Alt-Prior> $prior_binding
    bind [input_win $chatid] <Alt-Next> $next_binding
    bind [input_win $chatid] <Meta-Prior> +break
    bind [input_win $chatid] <Meta-Next> +break
    bind [input_win $chatid] <Alt-Prior> +break
    bind [input_win $chatid] <Alt-Next> +break
    bind [input_win $chatid] <Control-Meta-Prior> continue
    bind [input_win $chatid] <Control-Meta-Next> continue
    bind [input_win $chatid] <Control-Alt-Prior> continue
    bind [input_win $chatid] <Control-Alt-Next> continue

    regsub -all %W [bind Text <Control-Home>] [double% $wr] home_binding
    regsub -all %W [bind Text <Control-End>] [double% $wr] end_binding
    bind [input_win $chatid] <Control-Meta-Home> $home_binding
    bind [input_win $chatid] <Control-Meta-End> $end_binding
    bind [input_win $chatid] <Control-Alt-Home> $home_binding
    bind [input_win $chatid] <Control-Alt-End> $end_binding
    bind [input_win $chatid] <Control-Meta-Home> +break
    bind [input_win $chatid] <Control-Meta-End> +break
    bind [input_win $chatid] <Control-Alt-Home> +break
    bind [input_win $chatid] <Control-Alt-End> +break

    bind $cw <Destroy> [list chat::close_window [double% $chatid]]

    hook::run open_chat_post_hook $chatid $type
}

proc chat::raisecmd {chatid cw} {
    focus [chat::input_win $chatid]
    hook::run raise_chat_tab_hook $cw $chatid
}

###############################################################################

proc chat::activate {chatid} {
    raise_win [winid $chatid]
    focus -force [input_win $chatid]
}

###############################################################################

# This proc is used by the "richtext widget" to query the option DB for
# it's attributes which are really maintained by the main chat window
proc chat::query_optiondb {w option} {
    option get $w $option Chat
}

###############################################################################

proc chat::draginitcmd {target x y top} {
    return {}
}

###############################################################################

proc chat::dropovercmd {chatid target source event x y op type data} {
    variable chats

    set chat_xlib [get_xlib $chatid]
    lassign $data jid_xlib jid

    if {$source ne ".roster.canvas" || [is_disconnected $chatid] || \
            $chat_xlib ne $jid_xlib || \
            ![::roster::itemconfig $jid_xlib $jid -isuser]} {
        DropSite::setcursor dot
        return 0
    } else {
        DropSite::setcursor based_arrow_down
        return 1
    }
}

###############################################################################

proc chat::dropcmd {chatid target source x y op type data} {
    set group [get_jid $chatid]
    lassign $data xlib jid
    set reason [::msgcat::mc "Please join %s" $group]

    if {[muc::is_compatible $group]} {
        muc::invite_muc $xlib $group $jid $reason
    } else {
        muc::invite_xconference $xlib $group $jid $reason
    }
}

###############################################################################

proc chat::user_singleclick {chatid tags cjid jids} {
    lassign $cjid xlib jid
    set nick [get_nick $xlib $jid groupchat]
    hook::run groupchat_roster_user_singleclick_hook $chatid $nick
}

###############################################################################

proc chat::bind_window_click {chatid type} {
    set cw [Wrapped [chat::chat_win $chatid]]
    bind $cw <ButtonPress-1><ButtonRelease-1> \
        [list hook::run chat_window_click_hook [double% $chatid] %W %x %y]
}

hook::add open_chat_post_hook [namespace current]::chat::bind_window_click

###############################################################################

proc chat::close_window {chatid} {
    variable chats
    variable chat_id

    if {![is_opened $chatid]} return

    remove_from_opened $chatid

    set xlib [get_xlib $chatid]
    set jid [get_jid $chatid]

    set cw [winid $chatid]
    unset chat_id($cw)

    if {[is_groupchat $chatid]} {
        muc::leave_group $chatid $chats(exit_status,$chatid)
        client:presence $xlib $jid unavailable "" {}
        foreach jid [get_jids_of_user $xlib $jid] {
            client:presence $xlib $jid unavailable "" {}
        }
    }

    destroy $cw
    hook::run close_chat_post_hook $chatid
}

##############################################################################

proc chat::trace_room_nickname_change {chatid nick new_nick} {
    set xlib [get_xlib $chatid]
    set group [get_jid $chatid]
    set from $group/$nick
    set to $group/$new_nick
    set chatid1 [chatid $xlib $from]

    if {$chatid1 ni [::chat::opened]} return

    set msg [::msgcat::mc "%s has changed nick to %s." $nick $new_nick]
    ::chat::add_message $chatid1 "" chat $msg {}

    set cw [chat_win $chatid1]
    $cw config -state normal
    $cw delete {end - 1 char} ;# zap trailing newline
    $cw insert end " "
    set tooltip [::msgcat::mc "Opens a new chat window\
        for the new nick of the room occupant"]
    ::plugins::urls::render_url $cw url $tooltip {} \
        -title [::msgcat::mc "Open new conversation"] \
        -command [list [namespace current]::open_to_user $xlib $to]
    $cw insert end \n
    $cw config -state disabled
}

hook::add room_nickname_changed_hook chat::trace_room_nickname_change

##############################################################################

proc chat::check_xlib {xlib chatid} {
    if {[get_xlib $chatid] eq $xlib} {
        return 1
    } else {
        return 0
    }
}

proc chat::check_jid {xlib jid chatid} {
    if {[get_xlib $chatid] ne $xlib} {
        return 0
    } elseif {[get_jid $chatid] ne $jid && \
            [::xmpp::jid::removeResource [get_jid $chatid]] ne $jid} {
        return 0
    } else {
        return 1
    }
}

##############################################################################

proc chat::opened {{xlib {}} {jid {}}} {
    variable chats

    if {![info exists chats(opened)]} {
        return {}
    } elseif {$jid ne {}} {
        return [lfilter [list [namespace current]::check_jid $xlib $jid] \
                        $chats(opened)]
    } elseif {$xlib ne {}} {
        return [lfilter [list [namespace current]::check_xlib $xlib] \
                        $chats(opened)]
    } else {
        return $chats(opened)
    }
}

proc chat::is_opened {chatid} {
    variable chats

    if {[info exists chats(opened)] && $chatid in $chats(opened)} {
        return 1
    } else {
        return 0
    }
}

proc chat::add_to_opened {chatid} {
    variable chats

    lappend chats(opened) $chatid
    set chats(opened) [lsort -unique $chats(opened)]
}

proc chat::remove_from_opened {chatid} {
    variable chats

    set idx [lsearch -exact $chats(opened) $chatid]
    if {$idx >= 0} {
        set chats(opened) [lreplace $chats(opened) $idx $idx]
    }
}

##############################################################################

proc chat::users_win {chatid} {
    variable chats
    if {[info exists chats(userswin,$chatid)]} {
        return $chats(userswin,$chatid)
    } else {
        return ""
    }
}

proc chat::chat_win {chatid} {
    variable chats
    if {[info exists chats(chatwin,$chatid)]} {
        return $chats(chatwin,$chatid)
    } else {
        return ""
    }
}

proc chat::input_win {chatid} {
    variable chats
    if {[info exists chats(inputwin,$chatid)]} {
        return $chats(inputwin,$chatid)
    } else {
        return ""
    }
}

##############################################################################

proc chat::is_chat {chatid} {
    variable chats
    if {[info exists chats(type,$chatid)]} {
        string equal $chats(type,$chatid) chat
    } else {
        return 1
    }
}

proc chat::is_groupchat {chatid} {
    variable chats
    if {[info exists chats(type,$chatid)]} {
        string equal $chats(type,$chatid) groupchat
    } else {
        return 0
    }
}

##############################################################################

proc chat::is_disconnected {chatid} {
    if {[is_groupchat $chatid] && [muc::status $chatid] ne "connected"} {
        return 1
    } else {
        return 0
    }
}

##############################################################################

proc chat::create_user_menu {m chatid} {
    $m delete 0 end
    foreach mm [winfo children $m] {
        destroy $mm
    }

    set xlib [get_xlib $chatid]
    set jid [get_jid $chatid]

    hook::run chat_create_user_menu_hook $m $xlib $jid

    return $m
}

proc chat::create_conference_menu {m chatid} {
    $m delete 0 end
    foreach mm [winfo children $m] {
        destroy $mm
    }

    set xlib [get_xlib $chatid]
    set jid [get_jid $chatid]

    hook::run chat_create_conference_menu_hook $m $xlib $jid

    return $m
}

proc chat::add_separator {m xlib jid} {
    $m add separator
}

hook::add chat_create_user_menu_hook chat::add_separator 40
hook::add chat_create_user_menu_hook chat::add_separator 42
hook::add chat_create_user_menu_hook chat::add_separator 50
hook::add chat_create_user_menu_hook chat::add_separator 70
hook::add chat_create_user_menu_hook chat::add_separator 85
hook::add chat_create_conference_menu_hook chat::add_separator 40
hook::add chat_create_conference_menu_hook chat::add_separator 42
hook::add chat_create_conference_menu_hook chat::add_separator 50

proc chat::send_message {cw chatid type} {
    set iw [input_win $chatid]

    set xlib [get_xlib $chatid]

    if {[catch { set user [connection_user $xlib] }]} {
        set user ""
    }

    set body [$iw get 1.0 "end -1 chars"]

    debugmsg chat "SEND_MESSAGE:\
 [list $chatid] [list $user] [list $body] [list $type]"

    set chatw [chat_win $chatid]
    $chatw mark set start_message "end -1 chars"
    $chatw mark gravity start_message left

    hook::run chat_send_message_hook $chatid $user $body $type

    $iw delete 1.0 end
    catch {$iw edit reset}
}

proc chat::add_message {chatid from type body x} {
    variable chats
    variable options

    if {[catch {lindex [info level -1] 0} parent]} {
        set parent "{}"
    }

    debugmsg chat "ADD_MESSAGE: $parent $chatid $from $type $body $x"

    if {[is_opened $chatid]} {
        set chatw [chat_win $chatid]

        if {[lindex [$chatw yview] 1] == 1} {
            set scroll 1
        } else {
            set scroll 0
        }
    } else {
        set scroll 1
    }

    hook::run draw_message_hook $chatid $from $type $body $x

    if {[is_opened $chatid]} {
        set chatw [chat_win $chatid]

        if {![$chatw compare "end -1 chars linestart" == "end -1 chars"]} {
            $chatw insert end "\n"
        }

        # In the last condition we work around the underscrolling if the chat
        # window wasn't mapped yet. It's unlikely that mapped chat window will
        # be exactly 1 pixel tall.
        if {$body ne "" && !$options(stop_scroll) && \
                (!$options(smart_scroll) || \
                     ($options(smart_scroll) && $scroll) || \
                     [chat::is_our_jid $chatid $from] || \
                     [winfo height $chatw] == 1)} {
            after idle [list catch [list $chatw yview moveto 1]]
        }

        $chatw configure -state disabled
    }

    hook::run draw_message_post_hook $chatid $from $type $body $x
}

proc chat::add_open_to_user_menu_item {m xlib jid} {
    $m add command -label [::msgcat::mc "Start chat"] \
        -command [list chat::open_to_user $xlib $jid]
}

hook::add roster_create_groupchat_user_menu_hook \
    [namespace current]::chat::add_open_to_user_menu_item 10
hook::add roster_jid_popup_menu_hook \
    [namespace current]::chat::add_open_to_user_menu_item 10
hook::add message_dialog_menu_hook \
    [namespace current]::chat::add_open_to_user_menu_item 10
hook::add search_popup_menu_hook \
    [namespace current]::chat::add_open_to_user_menu_item 10

proc chat::open_to_user {xlib user args} {
    set msg ""
    foreach {opt val} $args {
        switch -- $opt {
            -message { set msg $val }
        }
    }

    if {$xlib eq ""} {
        set xlib [lindex [connections] 0]
    }

    set jid [get_jid_of_user $xlib $user]

    if {$jid eq ""} {
        set jid $user
    }

    set jid [::xmpp::jid::normalize $jid]

    set chatid [chatid $xlib $jid]
    set cw [winid $chatid]
    if {![winfo exists $cw]} {
        chat::open_window $chatid chat
    }
    raise_win $cw
    focus -force [input_win $chatid]

    if {$msg ne ""} {
        debugmsg chat "SEND_MESSAGE ON OPEN:\
            [list $chatid] [connection_user $xlib] [list $msg] chat"

        set chatw [chat_win $chatid]
        $chatw mark set start_message "end -1 chars"
        $chatw mark gravity start_message left

        hook::run chat_send_message_hook $chatid [connection_user $xlib] \
            $msg chat
    }
}

###############################################################################

proc chat::change_presence {xlib jid type x args} {
    variable options
    global statusdesc

    debugmsg chat "PRESENCE: $xlib $jid $type $x $args"

    set chatid [chatid $xlib $jid]

    if {![is_opened $chatid] || [is_groupchat $chatid]} return

    switch -- $type {
        error -
        unavailable { set status $type }
        available {
            set status available
            foreach {key val} $args {
                switch -- $key {
                    -show { set status [normalize_show $val] }
                }
            }
        }
        default { return }
    }

    # This case traces both chat and private groupchat conversations:
    if {$options(gen_status_change_msgs)} {
        set msg [get_nick $xlib $jid chat]
        append msg " " [::get_long_status_desc [::get_user_status $xlib $jid]]
        set desc [::get_user_status_desc $xlib $jid]
        if {$desc ne ""} {
            append msg " ($desc)"
        }
        ::chat::add_message $chatid "" chat $msg {}
    }

    set cw [winid $chatid]

    if {[winfo exists $cw.status.icon]} {
        $cw.status.icon configure \
            -image [ifacetk::roster::get_jid_icon $xlib $jid $status] \
            -helptext [get_user_status_desc $xlib $jid]
    }

    if {[winfo exists $cw.status.desc]} {
        $cw.status.desc configure \
                -text "($statusdesc([get_user_status $xlib $jid]))" \
                -helptext [get_user_status_desc $xlib $jid]
    }

    set user [::xmpp::jid::removeResource $jid]
    set cw [winid [chatid $xlib $user]]

    if {[winfo exists $cw.status.icon]} {
        $cw.status.icon configure \
            -image [ifacetk::roster::get_jid_icon \
                        $xlib $user [get_user_status $xlib $user]] \
            -helptext [get_user_status_desc $xlib $user]
    }
}

hook::add client_presence_hook chat::change_presence 70

###############################################################################

proc chat::process_roster_event {chatid jid nick status args} {
    variable chats

    debugmsg chat "ROSTER: $chatid $jid $nick $status $args"

    if {$nick eq ""} return

    foreach role {moderator participant visitor user} {
        dict unset chats(roster,$chatid) $role $nick
    }

    if {$status ne "unavailable"} {
        set role user
        array set tmp $args
        switch -- $tmp(-role) {
            moderator -
            participant -
            visitor {
                set role $tmp(-role)
            }
            default {
                set role user
            }
        }

        if {$::plugins::nickcolors::options(use_colored_roster_nicks)} {
            set foreground [plugins::nickcolors::get_color $nick]
        } else {
            set foreground [ifacetk::roster::get_foreground $status]
        }

        dict set chats(roster,$chatid) $role $nick [list $jid $status $foreground]
    }

    chat::redraw_roster_after_idle $chatid
}

proc chat::update_roster_foregrounds {chatid} {
    variable chats

    foreach role {moderator participant visitor user} {
        dict for {nick val} [dict get $chats(roster,$chatid) $role] {
            lassign $val jid status foreground

            if {$::plugins::nickcolors::options(use_colored_roster_nicks)} {
                set foreground [plugins::nickcolors::get_color $nick]
            } else {
                set foreground [ifacetk::roster::get_foreground $status]
            }

            dict set chats(roster,$chatid) $role $nick [list $jid $status $foreground]
        }
    }

    chat::redraw_roster_after_idle $chatid
}

namespace eval chat {
    variable g2l
    array set g2l [list moderator   [::msgcat::mc "Moderators"] \
                        participant [::msgcat::mc "Participants"] \
                        visitor     [::msgcat::mc "Visitors"] \
                        user        [::msgcat::mc "Users"]]
}

proc chat::redraw_roster {chatid args} {
    variable g2l
    variable chats

    set userswin [users_win $chatid]

    if {![winfo exists $userswin]} return

    ifacetk::roster::clear $userswin 0

    set xlib [get_xlib $chatid]

    foreach role {moderator participant visitor user} {
        set users [lsort -dictionary [dict keys [dict get $chats(roster,$chatid) $role]]]
        set nusers [llength $users]
        if {$nusers == 0} {
            continue
        }
        ifacetk::roster::addline $userswin group "$g2l($role) ($nusers)" $role $role {} 0

        foreach nick $users {
            lassign [dict get $chats(roster,$chatid) $role $nick] jid status foreground

            ifacetk::roster::addline $userswin jid $nick [list $xlib $jid] $role {} 0 \
                                     {} roster/user/$status $foreground
        }
    }

    ifacetk::roster::update_scrollregion $userswin
}

proc chat::redraw_roster_after_idle {chatid} {
    execute_script_after_idle [list chat::redraw_roster $chatid] {}
}

proc chat::restore_subject {chatid} {
    variable chats

    set sw [winid $chatid].status.subject

    if {[is_opened $chatid] && [winfo exists $sw]} {
        $sw delete 0 end
        $sw insert 0 $chats(subject,$chatid)
    }
}

proc chat::set_subject {chatid subject} {
    variable chats

    set cw [winid $chatid]

    if {[is_opened $chatid]} {
        $cw.status.subject delete 0 end
        $cw.status.subject insert 0 $subject
        set chats(subject,$chatid) $subject
    }
}

proc chat::change_subject {chatid} {
    set cw [winid $chatid]
    set xlib [get_xlib $chatid]
    set jid [get_jid $chatid]

    set subject [$cw.status.subject get]

    message::send_msg $xlib $jid -type groupchat -subject $subject
}

proc chat::set_subject_balloon {chatid} {
    variable chats

    set sw [winid $chatid].status.subject

    if {[info exists chats(subject_tooltip,$chatid)]} {
        return [list $chatid $chats(subject_tooltip,$chatid) \
                     -width [winfo width $sw]]
    } else {
        return [list $chatid ""]
    }
}

proc chat::set_subject_tooltip {chatid lo hi} {
    variable chats

    set sw [winid $chatid].status.subject

    if {![winfo exists $sw]} return

    if {$lo == 0 && $hi == 1} {
        set chats(subject_tooltip,$chatid) ""
    } else {
        set chats(subject_tooltip,$chatid) [$sw get]
    }
}

proc chat::is_our_jid {chatid jid} {
    ::xmpp::jid::equal [our_jid $chatid] $jid
}

proc chat::our_jid {chatid} {
    variable chats

    set xlib [get_xlib $chatid]
    set jid [get_jid $chatid]

    if {![info exists chats(type,$chatid)]} {
        return ""
    }

    switch -- $chats(type,$chatid) {
        groupchat {
            return $jid/[get_our_groupchat_nick $chatid]
        }
        chat {
            set group [::xmpp::jid::removeResource $jid]
            set groupid [chatid $xlib $group]
            if {[is_groupchat $groupid]} {
                return $group/[get_our_groupchat_nick $groupid]
            } else {
                return [connection_jid $xlib]
            }
        }
    }

    return ""
}

###############################################################################

proc chat::add_invite_menu_item {m xlib jid} {
    $m add command -label [::msgcat::mc "Invite to conference..."] \
           -command [list chat::invite_dialog $xlib $jid 0]
}

hook::add chat_create_user_menu_hook \
    [namespace current]::chat::add_invite_menu_item 20
hook::add roster_create_groupchat_user_menu_hook \
    [namespace current]::chat::add_invite_menu_item 20
hook::add roster_jid_popup_menu_hook \
    [namespace current]::chat::add_invite_menu_item 20
hook::add message_dialog_menu_hook \
    [namespace current]::chat::add_invite_menu_item 20
hook::add search_popup_menu_hook \
    [namespace current]::chat::add_invite_menu_item 20

proc chat::add_invite2_menu_item {m xlib jid} {
    $m add command -label [::msgcat::mc "Invite users..."] \
           -command [list chat::invite_dialog2 $xlib $jid 0]
}

hook::add chat_create_conference_menu_hook \
    [namespace current]::chat::add_invite2_menu_item 20

###############################################################################

proc chat::invite_dialog {xlib user {ignore_muc 0} args} {
    variable chats
    global invite_gc

    set jid [get_jid_of_user $xlib $user]

    if {$jid eq ""} {
        set jid $user
    }

    set gw .invite
    catch { destroy $gw }

    if {[catch { set nick [roster::get_label $user] }]} {
        if {[catch {set nick [roster::get_label \
                                  [::xmpp::jid::removeResource $user]] }]} {
            if {[catch { set nick [chat::get_nick $xlib \
                                                  $user groupchat] }]} {
                set nick $user
            }
        }
    }

    set titles {}
    set jids {}
    foreach chatid [lsort [lfilter [namespace current]::is_groupchat \
                                   [opened $xlib]]] {
        lappend jids $chatid [get_jid $chatid]
        lappend titles $chatid [::xmpp::jid::node [get_jid $chatid]]
    }
    if {[llength $titles] == 0} {
        MessageDlg ${gw}_err -aspect 50000 -icon info \
            -message \
                [::msgcat::mc "No conferences for %s in progress..." \
                    [connection_jid $xlib]] \
            -type user \
            -buttons ok -default 0 -cancel 0
        return
    }

    CbDialog $gw [::msgcat::mc "Invite %s to conferences" $nick] \
        [list [::msgcat::mc "Invite"] \
              "chat::invitation [list $jid] 0 $ignore_muc
               destroy $gw" \
              [::msgcat::mc "Cancel"] "destroy $gw"] \
        invite_gc $titles $jids
}

proc chat::invite_dialog2 {xlib jid ignore_muc args} {
    variable chats
    global invite_gc

    set gw .invite
    catch { destroy $gw }

    set title [::xmpp::jid::node $jid]

    set choices {}
    set balloons {}
    foreach choice [roster::get_jids $xlib] {
        if {[roster::itemconfig $xlib $choice -category] ne "conference"} {
            lappend choices \
                    [list $xlib $choice] [roster::get_label $xlib $choice]
            lappend balloons [list $xlib $choice] $choice
        }
    }
    if {[llength $choices] == 0} {
        MessageDlg ${gw}_err -aspect 50000 -icon info \
            -message \
                [::msgcat::mc "No users in %s roster..." \
                     [connection_jid $xlib]] \
            -type user \
            -buttons ok -default 0 -cancel 0
        return
    }

    CbDialog $gw [::msgcat::mc "Invite users to %s" $title] \
        [list [::msgcat::mc "Invite"] \
              "chat::invitation [list $jid] 1 $ignore_muc
               destroy $gw" \
              [::msgcat::mc "Cancel"] "destroy $gw"] \
        invite_gc $choices $balloons
}

proc chat::invitation {jid usersP ignore_muc {reason ""}} {
    global invite_gc

    foreach choice [array names invite_gc] {
        if {$invite_gc($choice)} {
            lassign $choice con gc
            if {$usersP} {
                set to $gc
                set group $jid
            } else {
                set to $jid
                set group $gc
            }
            if {$reason eq ""} {
                set reas [::msgcat::mc "Please join %s" $group]
            } else {
                set reas $reason
            }
            if {!$ignore_muc && [muc::is_compatible $group]} {
                muc::invite_muc $con $group $to $reas
            } else {
                muc::invite_xconference $con $group $to $reas
            }
        }
    }
}

#############################################################################

proc chat::restore_window {cjid type nick xlib jid} {
    set chatid [chatid $xlib $cjid]

    if {$type eq "groupchat"} {
        set_our_groupchat_nick $chatid $nick
    }

    # TODO: Password?
    open_window $chatid $type
    set cw [winid $chatid]
    raise_win $cw
}

#############################################################################

proc chat::save_session {vsession} {
    upvar 2 $vsession session
    global usetabbar
    variable chats
    variable chat_id

    if {$usetabbar} {
        set pages [.nb pages]
        set paths {}
        foreach page [.nb pages] {
            lappend paths [ifacetk::nbpath $page]
        }
    } else {
        # We rely on the fact that chat windows are direct children of .
        set paths [winfo children .]
    }

    set prio 0
    foreach path $paths {
        if {[info exists chat_id($path)]} {
            set chatid $chat_id($path)

            set xlib [get_xlib $chatid]
            set jid [get_jid $chatid]
            set type $chats(type,$chatid)

            if {$type eq "groupchat"} {
                set nick [get_our_groupchat_nick $chatid]
            } else {
                set nick ""
            }

            set user [connection_requested_user $xlib]
            set server [connection_requested_server $xlib]
            set resource [connection_requested_resource $xlib]

            lappend session [list $prio $user $server $resource \
                [list [namespace current]::restore_window $jid $type $nick] \
            ]
        }
        incr prio
    }
}

hook::add save_session_hook [namespace current]::chat::save_session

#############################################################################

# vim:ft=tcl:ts=8:sw=4:sts=4:et
