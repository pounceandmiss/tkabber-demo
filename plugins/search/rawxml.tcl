# rawxml.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       implements search panel setup in raw XML window.

namespace eval search {}

namespace eval search::rawxml {
    hook::add open_rawxml_post_hook [namespace current]::setup_panel
}

proc search::rawxml::open_panel {w sf} {
    pack $sf -side bottom -anchor w -fill x -before $w.sw
    update idletasks
    $w.dump see end
}

proc search::rawxml::close_panel {w sf} {
    $w.dump tag remove search_highlight 0.0 end
    pack forget $sf
    focus $w.input
}

proc search::rawxml::setup_panel {w} {
    set dump $w.dump

    $dump mark set sel_start end
    $dump mark set sel_end 0.0

    set sf [plugins::search::spanel [winfo parent $dump].search \
                -searchcommand [list [namespace parent]::do_text_search $dump] \
                -closecommand [list [namespace current]::close_panel $w]]

    bind [Wrapped $w.input] <<OpenSearchPanel>> \
        [double% [list [namespace current]::open_panel $w $sf]]
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
