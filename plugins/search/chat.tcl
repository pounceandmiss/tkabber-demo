# chat.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       implements search panel setup in chat windows.

namespace eval search {}

namespace eval search::chat {
    hook::add open_chat_post_hook [namespace current]::setup_panel
}

proc search::chat::open_panel {chatw sf} {
    pack $sf -side bottom -anchor w -fill x -before [winfo parent $chatw].csw
    update idletasks
    $chatw see end
}

proc search::chat::close_panel {chatid sf} {
    set chatw [chat::chat_win $chatid]

    $chatw tag remove search_highlight 0.0 end
    pack forget $sf
    focus [chat::input_win $chatid]
}

proc search::chat::setup_panel {chatid type} {
    set chatw [chat::chat_win $chatid]

    $chatw mark set sel_start end
    $chatw mark set sel_end 0.0

    set sf [plugins::search::spanel [winfo parent $chatw].search \
                -searchcommand [list [namespace parent]::do_text_search $chatw] \
                -closecommand [list [namespace current]::close_panel $chatid]]

    bind [chat::input_win $chatid] <<OpenSearchPanel>> \
        [double% [list [namespace current]::open_panel $chatw $sf]]
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
