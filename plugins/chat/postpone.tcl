# postpone.tcl --
#
#       The "Postpone text" plugin for Tkabber.
#
#       Provides a private hidden text buffer for each chat input window
#       and a binding to operate with it.
#       The idea is to provide for quick moving of the text typed into the chat
#       input window to that buffer, and then moving it back to the input window
#       with <Control-q> and <Control-g>.
#       This is helpful when the user types in some elaborate text and realizes she
#       wants to quickly post another text to the same chat and then continue with
#       editing.
#
# Written by Konstantin Khomoutov <flatworm at users dot sourceforge dot com>
# Modified by Sergei Golovan

namespace eval postpone {
    variable state

    event add <<ChatPushText>> <Control-q>
    event add <<ChatPopText>> <Control-g>

    ::hook::add open_chat_post_hook [namespace current]::setup_bindings
}

proc postpone::setup_bindings {chatid type} {
    variable state

    set w [::chat::input_win $chatid]

    set state($w,buffer) [list]

    bind $w <Destroy> +[list [namespace current]::cleanup_text_widget %W]
    bind $w <<ChatPushText>> [list [namespace current]::buffer_push %W]
    bind $w <<ChatPushText>> +break
    bind $w <<ChatPopText>> [list [namespace current]::buffer_pop %W]
    bind $w <<ChatPopText>> +break
}

proc postpone::cleanup_text_widget {w} {
    variable state

    array unset state $w,*
}

proc postpone::buffer_push {w} {
    variable state

    if {[$w compare 1.0 == {end - 1 char}]} return ;# empty

    lappend state($w,buffer) [$w get 1.0 {end - 1 char}] ;# don't get last newline

    $w delete 1.0 end
}

proc postpone::buffer_pop {w} {
    variable state

    if {[llength $state($w,buffer)] == 0} return

    set text [lindex $state($w,buffer) end]
    set state($w,buffer) [lrange $state($w,buffer) 0 end-1]

    $w insert insert $text
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
