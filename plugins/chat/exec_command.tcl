# exec_command.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which implements /exec command. It executes the typed command
#       and inserts its output into the same chat input window. After
#       that you may review and send it to the recipient.

proc handle_exec_command {chatid user body type} {
    if {[string equal -length 6 $body "/exec "]} {
        set iw [chat::input_win $chatid]
        set command [string range $body 6 end]
        set res [catch {set output [eval exec $command]} errMsg]
        if {$res} {
            set msg $errMsg
        } else {
            set msg $output
        }
        after idle [list $iw insert end "\$ $command\n" {} $msg]
        return stop
    }
}

hook::add chat_send_message_hook [namespace current]::handle_exec_command 15

proc exec_command_comps {chatid compsvar wordstart line} {
    upvar 0 $compsvar comps

    if {!$wordstart} {
        lappend comps {/exec }
    }
}

hook::add generate_completions_hook [namespace current]::exec_command_comps

# vim:ft=tcl:ts=8:sw=4:sts=4:et
