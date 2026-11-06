# logger.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       adds a search panel to the chat history windows.

namespace eval search {}

namespace eval search::logger {
    hook::add open_log_post_hook [namespace current]::setup_panel
}

proc search::logger::open_panel {w tw sf} {
    pack $sf -side bottom -anchor w -fill x -before $w.sw
    update idletasks
    $tw see end
}

proc search::logger::close_panel {tw sf} {
    $tw tag remove search_highlight 0.0 end
    pack forget $sf
}

proc search::logger::setup_panel {xlib jid w} {
    set tw $w.log

    $tw mark set sel_start end
    $tw mark set sel_end 0.0

    set sf [plugins::search::spanel $w.search \
                -searchcommand [list [namespace parent]::do_text_search $tw] \
                -closecommand [list [namespace current]::close_panel $tw]]

    bind $w <<OpenSearchPanel>> \
        [double% [list [namespace current]::open_panel $w $tw $sf]]
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
