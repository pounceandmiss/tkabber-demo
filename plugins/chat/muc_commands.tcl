# muc_commands.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       implements several MUC-related commands in chat input windows. They are
#       /whois, /kick, /ban, /banjid, /unban, /voice, /devoice, /member,
#       /demember, /moderator, /demoderator, /admin, /deadmin. Most commands
#       have two arguments: nickname (or jid) and reason. Reason is placed at
#       the second line in the window.
#
#       Example:
#       /kick somebody
#       You are an annoying person!

namespace eval muc {}

###############################################################################

proc muc::handle_commands {chatid user body type} {
    if {![string equal $type groupchat]} return

    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]
    if {[string equal [string range $body 0 5] "/kick "]} {
        set attr role
        set value none
        set dir down
        lassign [parse_nick_reason $body 6] nick reason
    } elseif {[string equal [string range $body 0 4] "/ban "]} {
        set attr affiliation
        set value outcast
        set dir down
        lassign [parse_nick_reason $body 5] nick reason
    } elseif {[string equal [string range $body 0 7] "/banjid "]} {
        lassign [parse_nick_reason $body 8] jid reason
        ::xmpp::muc::setAffiliation $xlib $group outcast \
                             -jid $jid -reason $reason \
                             -command [list muc::test_error_res \
                                            "affiliation outcast '$jid'" \
                                            $xlib $group $chatid]
        return stop
    } elseif {[string equal [string range $body 0 6] "/unban "]} {
        set jid [parse_nick $body 7]
        muc::unban $xlib $group $jid
        return stop
    } elseif {[string equal [string range $body 0 6] "/whois "]} {
        set nick [parse_nick $body 7]
        muc::whois $xlib $group/$nick $chatid
        return stop
    } elseif {[string equal [string range $body 0 6] "/voice "]} {
        set attr role
        set value participant
        set dir up
        lassign [parse_nick_reason $body 7] nick reason
    } elseif {[string equal [string range $body 0 8] "/devoice "]} {
        set attr role
        set value visitor
        set dir down
        lassign [parse_nick_reason $body 9] nick reason
    } elseif {[string equal [string range $body 0 7] "/member "]} {
        set attr affiliation
        set value member
        set dir up
        lassign [parse_nick_reason $body 8] nick reason
    } elseif {[string equal [string range $body 0 9] "/demember "]} {
        set attr affiliation
        set value none
        set dir down
        lassign [parse_nick_reason $body 10] nick reason
    } elseif {[string equal [string range $body 0 10] "/moderator "]} {
        set attr role
        set value moderator
        set dir up
        lassign [parse_nick_reason $body 11] nick reason
    } elseif {[string equal [string range $body 0 12] "/demoderator "]} {
        set attr role
        set value participant
        set dir down
        lassign [parse_nick_reason $body 13] nick reason
    } elseif {[string equal [string range $body 0 6] "/admin "]} {
        set attr affiliation
        set value admin
        set dir up
        lassign [parse_nick_reason $body 7] nick reason
    } elseif {[string equal [string range $body 0 8] "/deadmin "]} {
        set attr affiliation
        set value member
        set dir down
        lassign [parse_nick_reason $body 9] nick reason
    } else {
        return
    }
    muc::change_item_attr $xlib $group/$nick $attr $value $dir $reason $chatid

    return stop
}

hook::add chat_send_message_hook [namespace current]::muc::handle_commands 50

proc muc::parse_nick {body n} {
    return [lindex [parse_nick_reason $body $n] 0]
}

proc muc::parse_nick_reason {body n} {
    # Parse nickname and reason
    # first line is a nick, rest are reason
    set nick_reason [string range $body $n end]
    set ne [string first "\n" $nick_reason]
    if {$ne < 0} {
        set nick $nick_reason
        set reason ""
    } else {
        set nick [string range $nick_reason 0 [expr {$ne - 1}]]
        set reason [string range $nick_reason [expr {$ne + 1}] end]
    }
    return [list $nick [string trim $reason]]
}

###############################################################################

proc muc::commands_comps {chatid compsvar wordstart line} {
    set group [chat::get_jid $chatid]
    if {![muc::is_compatible $group]} return

    upvar 0 $compsvar comps

    if {!$wordstart} {
        lappend comps {/whois } {/kick } {/ban } {/banjid } {/unban } \
            {/voice } {/devoice } \
            {/member } {/demember } \
            {/moderator } {/demoderator } \
            {/admin } {/deadmin }
    }
}

hook::add generate_completions_hook [namespace current]::muc::commands_comps

# vim:ft=tcl:ts=8:sw=4:sts=4:et
