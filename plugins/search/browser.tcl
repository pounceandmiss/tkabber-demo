# browser.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       implements search panel for browser trees (like a service discovery
#       browser).

namespace eval search {}

namespace eval search::browser {
    hook::add open_browser_post_hook [namespace current]::setup_panel
    hook::add open_disco_post_hook [namespace current]::setup_panel
}

proc search::browser::open_panel {sw sf} {
    pack $sf -side bottom -anchor w -fill x -before $sw
}

proc search::browser::close_panel {tw sf} {
    pack forget $sf
    focus $tw
}

proc search::browser::setup_panel {w sw tw} {
    set sf [plugins::search::spanel $w.search \
                -searchcommand [list [namespace parent]::bwtree::do_search $tw] \
                -closecommand [list [namespace current]::close_panel $tw]]

    if {[winfo exists $tw.c]} {
        set tw $tw.c
    }
    bind $tw <<OpenSearchPanel>> \
        [double% [list [namespace current]::open_panel $sw $sf]]
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
