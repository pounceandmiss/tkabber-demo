# muc.tcl --
#
#       Multi-User Chat support (XEP-0045)

package require xmpp::muc

namespace eval muc {
    variable winid 0
    custom::defvar options(gen_enter_exit_msgs) 1 \
        [::msgcat::mc "Generate status messages when occupants\
            enter/exit MUC compatible conference rooms."] \
        -type boolean -group Chat
    custom::defvar options(gen_muc_status_change_msgs) 0 \
        [::msgcat::mc "Generate groupchat messages when occupant\
            changes his/her status and/or status message."] \
        -type boolean -group Chat
    custom::defvar options(gen_muc_position_change_msgs) 0 \
        [::msgcat::mc "Generate groupchat messages when occupant's\
            room position (affiliation and/or role) changes."] \
        -type boolean -group Chat
    custom::defvar options(propose_configure) 0 \
        [::msgcat::mc "Propose to configure newly created MUC room.\
                       If set to false then the default room configuration\
                       is automatically accepted."] \
        -type boolean -group Chat
    custom::defvar options(history_maxchars) 10000 \
        [::msgcat::mc "Maximum number of characters in the history in MUC\
                       compatible conference rooms."] \
        -type integer -group Chat
    custom::defvar options(history_maxstanzas) 20 \
        [::msgcat::mc "Maximum number of stanzas in the history in MUC\
                       compatible conference rooms."] \
        -type integer -group Chat
    custom::defvar options(request_only_unseen_history) 1 \
        [::msgcat::mc "Request only unseen (which aren't displayed in the\
                       chat window) messages in the history in MUC compatible\
                       conference rooms."] \
        -type boolean -group Chat
    custom::defvar options(retry_with_different_nick) 0 \
        [::msgcat::mc "Retry to join MUC room with a different nickname\
                       (with added _ suffix) in case of name conflicts."] \
        -type boolean -group Chat
    custom::defvar options(report_muc_rooms) 0 \
        [::msgcat::mc "Report the list of current MUC rooms on\
                       disco#items query."] \
        -type boolean -group IQ
}

set ::NS(muc)       http://jabber.org/protocol/muc
set ::NS(muc#owner) http://jabber.org/protocol/muc#owner
set ::NS(muc#user)  http://jabber.org/protocol/muc#user

set ::NS(muc#rooms)  http://jabber.org/protocol/muc#rooms

###############################################################################

proc set_our_groupchat_nick {chatid nick} {
    global groupchats

    debugmsg conference "SET NICK: $chatid '$nick'"

    set groupchats(nick,$chatid) $nick
}

proc get_our_groupchat_nick {chatid} {
    global groupchats

    debugmsg conference "GET NICK: $chatid"

    set groupchats(nick,$chatid)
}

###############################################################################

proc muc::get_real_jid {xlib jid} {
    variable tokens

    set group [::xmpp::jid::removeResource $jid]
    set nick [::xmpp::jid::resource $jid]
    set chatid [chat::chatid $xlib $group]

    if {![info exists tokens($chatid)]} {
        return ""
    } else {
        return [::xmpp::muc::realJid $tokens($chatid) $nick]
    }
}

proc muc::get_affiliation {xlib jid} {
    variable tokens

    set group [::xmpp::jid::removeResource $jid]
    set nick [::xmpp::jid::resource $jid]
    set chatid [chat::chatid $xlib $group]

    if {![info exists tokens($chatid)]} {
        return ""
    } else {
        return [::xmpp::muc::affiliation $tokens($chatid) $nick]
    }
}

proc muc::get_role {xlib jid} {
    variable tokens

    set group [::xmpp::jid::removeResource $jid]
    set nick [::xmpp::jid::resource $jid]
    set chatid [chat::chatid $xlib $group]

    if {![info exists tokens($chatid)]} {
        return ""
    } else {
        return [::xmpp::muc::role $tokens($chatid) $nick]
    }
}

proc muc::whois {xlib user reschatid} {
    set group [::xmpp::jid::removeResource $user]
    set chatid [chat::chatid $xlib $group]
    set nick [chat::get_nick $xlib $user groupchat]

    set real_jid [get_real_jid $xlib $user]

    if {$real_jid ne ""} {
        chat::add_message $reschatid $group info \
            [::msgcat::mc "whois '%s': %s" $nick $real_jid] {}
    } else {
        chat::add_message $reschatid $group error \
            [::msgcat::mc "whois '%s': no info" $nick] {}
    }
}

###############################################################################

proc muc::change_item_attr {xlib user attr value dir reason reschatid} {
    variable tokens

    set group [::xmpp::jid::removeResource $user]
    set chatid [chat::chatid $xlib $group]
    set nick  [chat::get_nick $xlib $user groupchat]

    if {![info exists tokens($chatid)]} {
        chat::add_message $reschatid $group error \
                "$attr $value '$nick':\
                 [::msgcat::mc {You must join the room to set %s} $attr]" {}
        return
    }

    set args [list -command \
                   [list muc::test_error_res \
                         "$attr $value '$nick'" $xlib $group $reschatid]]
    if {$reason ne ""} {
        lappend args -reason $reason
    }

    switch -- $attr/$dir {
        affiliation/up   { set command ::xmpp::muc::raiseAffiliation }
        affiliation/down { set command ::xmpp::muc::lowerAffiliation }
        role/up   { set command ::xmpp::muc::raiseRole }
        role/down { set command ::xmpp::muc::lowerRole }
    }

    $command $tokens($chatid) $nick $value {*}$args
}

###############################################################################

proc muc::unban {xlib group jid} {
    ::xmpp::muc::unsetOutcast $xlib $group $jid \
                -command [list muc::test_unban_res $xlib $group $jid]
}

proc muc::test_unban_res {xlib group jid status msg} {
    switch -- $status {
        ok {
            chat::add_message [chat::chatid $xlib $group] $group info \
                    [format "affiliation none '%s': %s" \
                            $jid [::msgcat::mc "User is unbanned"]] {}
        }
        default {
            chat::add_message [chat::chatid $xlib $group] $group error \
                    [format "affiliation none '%s': %s" \
                            $jid [error_to_string $msg]] {}
        }
    }
}

###############################################################################

proc muc::request_config_dialog {chatid} {
    variable winid

    set w .muc_req_config$winid
    incr winid

    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -title [::msgcat::mc "Room is created"] \
        -modal none -anchor e -default 0 -cancel 1

    set wf [$w getframe]
    Message $wf.message -aspect 50000 \
        -text [::msgcat::mc "Room %s is successfully created" \
                    [chat::get_jid $chatid]]

    pack $wf.message -pady 2m

    $w add -text [::msgcat::mc "Configure room"] \
        -command "[list destroy $w]
                  [list [namespace current]::request_config $chatid]"
    $w add -text [::msgcat::mc "Accept default config"] \
        -command "[list destroy $w]
                  [list [namespace current]::request_instant_room $chatid]"

    $w draw
}

proc muc::request_instant_room {chatid} {
    ::xmpp::sendIQ [chat::get_xlib $chatid] set \
        -query [::xmpp::xml::create query \
                        -xmlns $::NS(muc#owner) \
                        -subelement [::xmpp::data::submitForm {}]] \
        -to [chat::get_jid $chatid]
}

proc muc::request_config {chatid} {
    ::xmpp::sendIQ [chat::get_xlib $chatid] get \
        -query [::xmpp::xml::create query \
                        -xmlns $::NS(muc#owner)] \
        -to [chat::get_jid $chatid] \
        -command [list muc::receive_config $chatid]
}

proc muc::receive_config {chatid res child} {
    set group [chat::get_jid $chatid]
    if {![string equal $res ok]} {
        chat::add_message $chatid $group error \
            [::msgcat::mc "Configure form: %s" [error_to_string $child]] \
            {}
        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    data::draw_window $subels \
        [list muc::send_config $chatid] \
        -cancelCommand [list muc::cancel_config $chatid] \
        -title [::msgcat::mc "Configure room %s" $group]
    return
}

###############################################################################

proc muc::send_config {chatid w restags} {
    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]
    ::xmpp::sendIQ $xlib set \
        -query [::xmpp::xml::create query \
                           -xmlns $::NS(muc#owner) \
                           -subelements $restags] \
        -to $group \
        -command [list muc::test_error_res \
                       [::msgcat::mc "Sending configure form"] \
                       $xlib $group $chatid]
    destroy $w
}

###############################################################################

proc muc::cancel_config {chatid w} {
    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]
    ::xmpp::sendIQ $xlib set \
        -query [::xmpp::xml::create query \
                           -xmlns $::NS(muc#owner) \
                           -subelement [::xmpp::data::cancelForm]] \
        -to $group \
        -command [list muc::test_error_res \
                       [::msgcat::mc "Cancelling configure form"] \
                       $xlib $group $chatid]
    destroy $w
}

###############################################################################

proc muc::test_error_res {op xlib group reschatid res child} {
    if {![string equal $res ok]} {
        set chatid [chat::chatid $xlib $group]
        chat::add_message $reschatid $group error \
            [format "%s: %s" $op [error_to_string $child]] {}
        return
    }
}

###############################################################################

proc muc::report_muc_event {chatid action nick args} {
    variable options

    debugmsg conference "MUC EVENT: $chatid $action $nick $args"

    if {![chat::is_opened $chatid]} return

    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]
    set user $group/$nick

    switch -- $action {
        disconnect {
            set msg [::msgcat::mc "Disconnected"]
            foreach {key val} $args {
                switch -- $key {
                    -error { set msg [::xmpp::stanzaerror::message $val] }
                }
            }

            chat::add_message $chatid $group error $msg {}
            client:presence $xlib $group unavailable "" {}
        }
        enter {
            hook::run chat_user_enter $chatid $nick
        }
        presence {
            hook::run chat_user_presence $chatid $nick
        }
        exit {
            hook::run chat_user_exit $chatid $nick
        }
        position {
            track_room_position $xlib $user {*}$args
        }
        create {
            chat::add_message \
                    $chatid $group groupchat \
                    [::msgcat::mc "A new room is created"] {}

            if {$options(propose_configure)} {
                request_config_dialog $chatid
            } else {
                # requesting "instant" room as specified in XEP-0045
                # if the user wants to configure room (s)he can do it later
                request_instant_room $chatid
            }
        }
        destroy {
            set msg [::msgcat::mc "Room is destroyed"]
            foreach {key val} $args {
                switch -- $key {
                    -reason {
                        append msg [::msgcat::mc "\nReason: %s" $val]
                    }
                    -jid {
                        append msg [::msgcat::mc "\nAlternative venue: %s" \
                                                 $val]
                    }
                }
            }
            if {$options(gen_enter_exit_msgs)} {
                chat::add_message \
                        $chatid $group groupchat $msg {}
            }
        }
        ban -
        kick -
        demember -
        members-only {
            set real_jid ""
            foreach {key val} $args {
                switch -- $key {
                    -jid    { set real_jid " ($val)" }
                    -actor  { set actor $val }
                    -reason { set reason $val }
                }
            }

            switch -- $action {
                ban { set msg [::msgcat::mc "%s has been banned" \
                                            $nick$real_jid] }
                kick { set msg [::msgcat::mc "%s has been kicked" \
                                             $nick$real_jid] }
                demember { set msg [::msgcat::mc "%s has been kicked because\
                                                  of membership loss" \
                                                 $nick$real_jid] }
                members-only { set msg [::msgcat::mc \
                                            "%s has been kicked because\
                                             room became members-only" \
                                            $nick$real_jid] }
            }

            if {[info exists actor] && $actor ne ""} {
                append msg [::msgcat::mc " by %s" $actor]
            }

            if {[info exists reason] && $reason ne ""} {
                append msg ": $reason"
            }

            if {$options(gen_enter_exit_msgs)} {
                chat::add_message $chatid $group groupchat $msg {}
            }
        }
        nick {
            set real_jid ""
            foreach {key val} $args {
                switch -- $key {
                    -jid {
                        set real_jid " ($val)"
                    }
                    -nick {
                        set new_nick $val
                    }
                }
            }

            # TODO may be this reporting should not be done
            # if the $nick is being ignored (MUC ignore)
            if {$options(gen_enter_exit_msgs)} {
                chat::add_message $chatid $group groupchat \
                            [::msgcat::mc "%s is now known as %s" \
                                         $nick$real_jid $new_nick] {}
            }
            ::hook::run room_nickname_changed_hook $chatid $nick $new_nick
        }
    }
}

proc muc::report_unavailable {chatid nick} {
    variable options

    set group [chat::get_jid $chatid]

    if {$options(gen_enter_exit_msgs)} {
        set message [::msgcat::mc "%s has left" $nick]
        set xlib [chat::get_xlib $chatid]
        set error [get_jid_presence_info error $xlib $group/$nick]
        if {$error ne ""} {
            set status [::xmpp::stanzaerror::message $error]
        } else {
            set status [get_jid_presence_info status $xlib $group/$nick]
        }
        if {$status ne ""} {
            append message ": $status"
        } else {
            append message ""
        }
        chat::add_message $chatid $group groupchat $message {}
    }
}

hook::add chat_user_exit muc::report_unavailable 100

proc muc::report_enter {chatid nick} {
    report_available $chatid $nick 1
}

hook::add chat_user_enter muc::report_enter 100

proc muc::report_available {chatid nick {entered 0}} {
    variable options

    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]

    if {![is_compatible $group]} return

    set jid $group/$nick

    set msg ""

    if {$entered && $options(gen_enter_exit_msgs)} {
        set real_jid [get_real_jid $xlib $jid]
        if {$real_jid ne ""} {
            set occupant "$nick ($real_jid)"
        } else {
            set occupant $nick
        }
        set msg [::msgcat::mc "%s has entered" $occupant]
        if {$options(gen_muc_position_change_msgs)} {
            append msg " " [::msgcat::mc "as %s/%s" \
                [::msgcat::mc [get_affiliation $xlib $jid]] \
                [::msgcat::mc [get_role $xlib $jid]]]
        }
    }

    if {$options(gen_muc_status_change_msgs)} {
        set status [::get_user_status $xlib $jid]
        if {$entered && $options(gen_enter_exit_msgs)} {
            append msg " " [::msgcat::mc "and"] " "
        } else {
            append msg $nick " "
        }
        append msg [::get_long_status_desc $status]
        set desc [::get_user_status_desc $xlib $jid]
        if {$desc ne {}} {
            append msg " ($desc)"
        }
    }

    chat::add_message $chatid $group groupchat $msg {}
}

hook::add chat_user_presence muc::report_available 100

proc muc::track_room_position {xlib jid args} {
    variable options

    set group [::xmpp::jid::removeResource $jid]
    if {![is_compatible $group]} return

    set chatid [chat::chatid $xlib $group]

    if {[chat::is_opened $chatid] && $options(gen_muc_position_change_msgs)} {
        set nick [chat::get_nick $xlib $jid groupchat]

        foreach {key val} $args {
            switch -- $key {
                -affiliation { set affiliation $val }
                -role { set role $val }
            }
        }

        if {[info exists affiliation]} {
            if {[info exists role]} {
                set msg [::msgcat::mc "%s has been assigned a new room\
                                       position: %s/%s" \
                                      $nick [::msgcat::mc $affiliation] \
                                      [::msgcat::mc $role]]
            } else {
                set msg [::msgcat::mc "%s has been assigned a new\
                                       affiliation: %s" \
                                      $nick [::msgcat::mc $affiliation]]
            }
        } elseif {[info exists role]} {
            set msg [::msgcat::mc "%s has been assigned a new role: %s" \
                $nick [::msgcat::mc $role]]
        } else {
            set msg ""
        }

        if {$msg ne ""} {
            chat::add_message $chatid $group groupchat $msg {}
        }
    }
}

###############################################################################

proc muc::change_nick {chatid nick} {
    global userstatus textstatus
    variable tokens

    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]

    if {![is_compatible $group]} {
        chat::add_message $chatid $group error \
            [::msgcat::mc "Can't change nickname in MUC incompatible rooms"] {}
        return
    }

    debugmsg conference "CHANGE_NICK: $chatid $nick"

    ::xmpp::muc::setNick $tokens($chatid) $nick \
            {*}[presence_args $xlib $userstatus -status $textstatus] \
            -command [namespace code [list process_change_nick $chatid]]
}

proc muc::process_change_nick {chatid status msg} {
    debugmsg conference "PROCESS_CHANGE_NICK: $chatid $status $msg"

    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]

    switch -- $status {
        ok {
            set_our_groupchat_nick $chatid $msg
        }
        error {
            if {[chat::is_opened $chatid]} {
                chat::add_message $chatid $group error \
                                  [::xmpp::stanzaerror::message $msg] {}
            }
        }
    }
    return
}

###############################################################################

proc muc::request_negotiation {xlib group} {
    variable muc_compatible

    # It's almost impossible to find MUC-incompatible room now, so the default
    # value is 1
    set muc_compatible($group) 1

    disco::request_info $xlib [::xmpp::jid::server $group] \
        -cache yes \
        -command [list muc::recv_negotiation1 $xlib $group]
}

proc muc::recv_negotiation1 {xlib group res identities features extras} {
    variable muc_compatible

    if {$res eq "ok" && $::NS(muc) in $features} {
        set muc_compatible($group) 1
        set muc_compatible([::xmpp::jid::server $group]) 1
        return
    }

    disco::request_info $xlib $group \
        -cache yes \
        -command [list muc::recv_negotiation2 $group]
}

proc muc::recv_negotiation2 {group res identities features extras} {
    variable muc_compatible

    if {$res eq "ok" && $::NS(muc) in $features} {
        set muc_compatible($group) 1
        return
    }

    set muc_compatible($group) 0
}

proc muc::is_compatible {group} {
    variable muc_compatible

    if {[info exists muc_compatible($group)]} {
        return $muc_compatible($group)
    } elseif {[info exists muc_compatible([::xmpp::jid::server $group])]} {
        return $muc_compatible([::xmpp::jid::server $group])
    } else {
        return 0
    }
}

proc muc::roster {chatid} {
    variable tokens

    if {![info exists tokens($chatid)]} {
        return {}
    } else {
        return [::xmpp::muc::roster $tokens($chatid)]
    }
}

proc muc::nick {chatid} {
    variable tokens

    if {![info exists tokens($chatid)]} {
        return ""
    } else {
        return [::xmpp::muc::nick $tokens($chatid)]
    }
}

proc muc::status {chatid} {
    variable tokens

    if {![info exists tokens($chatid)]} {
        return disconnected
    } else {
        return [::xmpp::muc::status $tokens($chatid)]
    }
}

###############################################################################

proc muc::add_user_popup_info {infovar xlib user} {
    upvar 0 $infovar info

    set real_jid [get_real_jid $xlib $user]
    if {$real_jid ne ""} {
        append info [::msgcat::mc "\n\tJID: %s" $real_jid]
    }
    set affiliation [get_affiliation $xlib $user]
    if {$affiliation ne ""} {
        append info [::msgcat::mc "\n\tAffiliation: %s" $affiliation]
    }
}

hook::add roster_user_popup_info_hook muc::add_user_popup_info

###############################################################################

proc muc::set_message_timestamp {chatid from type body x} {
    variable timestamps

    if {[::xmpp::delay::exists $x]} {
        set ts [::xmpp::xml::getAttr [::xmpp::delay::parse $x] seconds]
    } else {
        if {[chat::is_disconnected $chatid]} {
            return
        }
        set ts [clock seconds]
    }
    set timestamps($chatid) $ts
}

hook::add draw_message_hook muc::set_message_timestamp 15

proc muc::clear_message_timestamp {chatid} {
    variable timestamps

    catch { unset timestamps($chatid) }
}

hook::add close_chat_post_hook muc::clear_message_timestamp

###############################################################################

proc muc::new {chatid type} {
    variable tokens

    # MUC token is created only for groupchat windows

    if {$type ne "groupchat"} return

    debugmsg conference "NEW_GROUP: $chatid"

    set xlib  [chat::get_xlib $chatid]
    set group [chat::get_jid  $chatid]

    set tokens($chatid) \
        [::xmpp::muc::new $xlib $group \
                -eventcommand  [list muc::report_muc_event $chatid] \
                -rostercommand [list chat::process_roster_event $chatid]]
}

hook::add open_chat_pre_hook muc::new

###############################################################################

proc muc::join_group_raise {xlib group nick {password ""}} {
    if {[llength [connections]] == 0} return

    if {[string equal $xlib ""]} {
        set xlib [lindex [connections] 0]
    }

    join_group $xlib $group $nick $password

    chat::activate [chat::chatid $xlib [::xmpp::jid::normalize $group]]
}

proc muc::join_group {xlib group nick {password ""} {retries 2}} {
    global userstatus textstatus
    variable options
    variable timestamps
    variable muc_password
    variable tokens

    set group [::xmpp::jid::normalize $group]
    set chatid [chat::chatid $xlib $group]

    privacy::add_to_special_list $xlib conference [::xmpp::jid::server $group]

    set_our_groupchat_nick $chatid $nick

    chat::open_window $chatid groupchat
    #update idletasks

    request_negotiation $xlib $group

    set x_args {}

    set muc_password($chatid) $password

    if {$options(history_maxchars) >= 0} {
        lappend x_args -maxchars $options(history_maxchars)
    }
    if {$options(history_maxstanzas) >= 0} {
        lappend x_args -maxstanzas $options(history_maxstanzas)
    }
    if {$options(request_only_unseen_history) && \
            [info exists timestamps($chatid)]} {
        lappend x_args \
                -seconds [expr {[clock seconds] - $timestamps($chatid) + 2}]
    }

    debugmsg conference "JOIN: $chatid $nick"

    incr retries -1

    ::xmpp::muc::join $tokens($chatid) $nick \
               -password $password \
               -command [namespace code [list process_join $chatid \
                                                           $nick \
                                                           $password \
                                                           $retries]] \
         {*}[presence_args $xlib $userstatus -status $textstatus] \
         {*}$x_args
}

proc muc::process_join {chatid nick password retries status msg} {
    variable options

    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]

    debugmsg conference "PROCESS_JOIN: $chatid $status $msg"

    switch -- $status {
        ok {
            set_our_groupchat_nick $chatid $msg
            client:presence $xlib $group "" "" {}
            hook::run join_group_hook $chatid $msg
        }
        error {
            set message [::xmpp::stanzaerror::message $msg]
            if {$options(retry_with_different_nick) && \
                    [::xmpp::stanzaerror::condition $msg] eq "conflict" && \
                    $retries >= 0} {
                if {[chat::is_opened $chatid]} {
                    append message " - " [::msgcat::mc "Retrying with nickname\
                                                        '%s_'" $nick]
                    chat::add_message $chatid $group error $message {}
                }

                join_group $xlib $group ${nick}_ $password $retries

            } else {
                if {[chat::is_opened $chatid]} {
                    chat::add_message $chatid $group error $message {}
                }
            }
        }
    }
    return
}

###############################################################################

proc muc::leave_group {chatid status} {
    variable tokens

    debugmsg conference "LEAVE_GROUP: $chatid"

    if {[info exists tokens($chatid)]} {
        if {![string equal $status ""]} {
            ::xmpp::muc::leave $tokens($chatid) -status $status
        } else {
            ::xmpp::muc::leave $tokens($chatid)
        }
    }
}

proc muc::reset_group {chatid} {
    variable tokens

    debugmsg conference "RESSET_GROUP: $chatid"

    ::xmpp::muc::reset $tokens($chatid)
}

proc muc::free {chatid} {
    variable tokens

    # This routine is called not only for groupchats, so checking existence of
    # tokens($chatid) is necessary.

    if {[info exists tokens($chatid)]} {
        debugmsg conference "FREE_GROUP: $chatid"

        ::xmpp::muc::free $tokens($chatid)
        unset tokens($chatid)
    }
}

hook::add close_chat_post_hook muc::free

###############################################################################

proc muc::test_connection {chatid args} {
    variable tokens

    debugmsg conference "TEST_CONNECTION: $chatid"

    foreach {key val} $args {
        switch -- $key {
            -command { set command $val }
        }
    }

    if {![info exists command]} {
        return -code error "Command is mandatory"
    }

    if {![info exists tokens($chatid)]} {
        return -code error "MUC token doesn't exist"
    }

    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]
    set nick [::xmpp::muc::nick $tokens($chatid)]

    ::xmpp::ping::ping $xlib -to $group/$nick \
            -timeout 10000 \
            -command [list muc::parse_test_connection $command]
}

proc muc::parse_test_connection {command status msg} {
    debugmsg conference "TEST_CONNECTION_REPLY: $status $msg"

    switch -- $status {
        ok {
            {*}$command connected
        }
        error {
            lassign [error_type_condition $msg] type condition
            switch -- $type/$condition {
                cancel/not-allowed -
                modify/not-acceptable {
                    {*}$command disconnected
                }
                default {
                    {*}$command connected
                }
            }
        }
        default {
            {*}$command disconnected
        }
    }
}

###############################################################################

proc muc::invite_muc {xlib group jid reason} {
    # If $jid is a 'real' JID then invite
    # If $jid is in a conference room try to invite real JID

    set real_jid [get_real_jid $xlib $jid]
    if {$real_jid eq ""} {
        set real_jid $jid
    }

    message::send_msg $xlib $group \
        -xlist [list \
            [::xmpp::xml::create x \
                 -xmlns $::NS(muc#user) \
                 -subelement [::xmpp::xml::create invite \
                                    -attrs [list to $real_jid] \
                                    -subelement [::xmpp::xml::create reason \
                                                        -cdata $reason]]]]
}

proc muc::invite_xconference {xlib group jid reason} {
    message::send_msg $xlib $jid \
        -type normal \
        -subject "Invitation" \
        -body $reason \
        -xlist [list [::xmpp::xml::create x \
                            -xmlns $::NS(xconference) \
                            -attrs [list jid $group]]]
}

###############################################################################

proc muc::process_invitation {rowvar bodyvar f x xlib from id type replyP} {
    upvar 2 $rowvar row
    upvar 2 $bodyvar body

    foreach xa $x {
        ::xmpp::xml::split $xa tag xmlns attrs cdata subels

        switch -- $xmlns \
            $::NS(xconference) {
                set xconference_group [::xmpp::xml::getAttr $attrs jid]
                set xconference_password ""
                if {[string equal $body ""] && ![string equal $cdata ""]} {
                    set xconference_body $cdata
                } else {
                    set xconference_body $body
                }
            } \
            $::NS(muc#user) {
                set password ""
                set inviter ""
                foreach ch $subels {
                    ::xmpp::xml::split $ch stag sxmlns sattrs scdata ssubels

                    switch -- $stag {
                        invite {
                            set inviter [::xmpp::xml::getAttr $sattrs from]
                            if {![string equal $inviter ""]} {
                                foreach c [connections] {
                                    set rjid [roster::find_jid $c $inviter]
                                    set name \
                                        [roster::itemconfig $c $rjid -name]
                                    if {$rjid ne "" && $name ne ""} break
                                }
                                if {![string equal $name ""]} {
                                    set inviter "$name ($inviter)"
                                }
                                set muc_body \
                                    [::msgcat::mc \
                                         "%s invites you to conference\
                                          room %s" \
                                         $inviter $from]

                                foreach sch $ssubels {
                                    ::xmpp::xml::split $sch sstag ssxmlns \
                                                            ssattrs sscdata \
                                                            sssubels
                                    if {[string equal $sstag "reason"]} {
                                        append muc_body \
                                            [::msgcat::mc "\nReason is: %s" \
                                                 $sscdata]
                                    }
                                }
                            }
                            # TODO decline
                        }
                        password {
                            set password $scdata
                        }
                    }
                }
                if {![string equal $inviter ""]} {
                    set muc_group $from
                    set muc_password $password
                }
            }
    }

    if {[info exists muc_group] && $muc_group ne ""} {
        if {[status [::chat::chatid $xlib $muc_group]] eq "disconnected"} {
            process_x_conference $f $xlib $muc_group $muc_password $row
            incr row
            set body $muc_body
            return
        } else {
            # HACK: ignore the invitation if we are already in the room
            set body ""
            return
        }
    } elseif {[info exists xconference_group] && $xconference_group ne ""} {
        if {[status [::chat::chatid $xlib $xconference_group]] eq "disconnected"} {
            process_x_conference $f $xlib $xconference_group \
                $xconference_password $row
            incr row
            set body $xconference_body
            return
        } else {
            # HACK: ignore the invitation if we are already in the room
            set body ""
            return
        }
    }

    return
}

hook::add message_process_x_hook muc::process_invitation

proc muc::process_x_conference {f xlib group password row} {
    Label $f.lgroup$row -text [::msgcat::mc "Invited to:"]
    Button $f.group$row -text $group \
        -command [list muc::join_group_raise $xlib \
                                             $group \
                                             [get_group_nick $xlib $group] \
                                             $password]

    grid $f.lgroup$row -row $row -column 0 -sticky e
    grid $f.group$row  -row $row -column 1 -sticky ew
}

###############################################################################

proc muc::disco_reply {type xlib from lang} {
    variable options

    if {!$options(report_muc_rooms)} {
        return {error cancel not-allowed}
    }

    switch -- $type {
        info {
            return [list result {}]
        }
        items {
            set res {}
            foreach chatid [lfilter chat::is_groupchat [chat::opened $xlib]] {
                set group [chat::get_jid $chatid]
                if {[is_compatible $group]} {
                    lappend res [list jid $group]
                }
            }
            return [list result $res]
        }
    }
}

hook::add postload_hook \
    [list disco::register_node $::NS(muc#rooms) muc::disco_reply \
          [::trans::trans "Current rooms"]]

###############################################################################

# vim:ft=tcl:ts=8:sw=4:sts=4:et
