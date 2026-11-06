# history.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which implements chat input window history. It also binds
#       <Control-Up> and <Control-Down> keys to retrieve the previous
#       and the next history item.

proc history_move {chatid shift} {
    variable history

    set newpos [expr $history(pos,$chatid) + $shift]

    if {$newpos < 0} { set newpos 0 }
    set len [expr [llength $history(stack,$chatid)] - 1]

    if {$newpos > $len} { set newpos $len }

    set iw [chat::input_win $chatid]
    set body [$iw get 1.0 "end -1 chars"]

    if {$history(pos,$chatid) == 0} {
        set history(stack,$chatid) \
            [lreplace $history(stack,$chatid) 0 0 $body]
    }


    set history(pos,$chatid) $newpos

    set newbody [lindex $history(stack,$chatid) $newpos]

    $iw delete 1.0 end
    after idle [list $iw insert end $newbody]
}

#debugmsg plugins "HISTORY: [namespace which history_move]"
#namespace export history_move

proc add_body_to_history {chatid user body type} {
    variable history

    set history(stack,$chatid) [linsert $history(stack,$chatid) 1 $body]
    set history(pos,$chatid) 0

}
hook::add chat_send_message_hook [namespace current]::add_body_to_history 12


proc setup_history_bindings {chatid type} {
    variable history

    set iw [chat::input_win $chatid]

    bind $iw <Control-Key-Up> \
        [list [namespace current]::history_move [double% $chatid] 1]
    bind $iw <Control-Key-p> \
        [list [namespace current]::history_move [double% $chatid] 1]
    bind $iw <Control-Key-Down> \
        [list [namespace current]::history_move [double% $chatid] -1]
    bind $iw <Control-Key-n> \
        [list [namespace current]::history_move [double% $chatid] -1]

    set history(stack,$chatid) [list {}]
    set history(pos,$chatid) 0
}

hook::add open_chat_post_hook [namespace current]::setup_history_bindings

# vim:ft=tcl:ts=8:sw=4:sts=4:et
