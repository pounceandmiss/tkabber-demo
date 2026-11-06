# custom.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       adds a search panel into the Customize tab or window.

namespace eval search {}

namespace eval search::custom {
    hook::add open_custom_post_hook [namespace current]::setup_panel
}

proc search::custom::open_panel {w sf} {
    pack $sf -side bottom -anchor w -fill x -before $w.sw
    update idletasks
    $w.fields see end
}

proc search::custom::close_panel {w sf} {
    $w.fields tag remove search_highlight 0.0 end
    pack forget $sf
    focus $w.fields
}

proc search::custom::setup_panel {w} {
    set fields $w.fields

    $fields mark set sel_start end
    $fields mark set sel_end 0.0

    set sf [plugins::search::spanel $w.search \
                -searchcommand [list [namespace parent]::do_text_search $fields] \
                -closecommand [list [namespace current]::close_panel $w]]

    bind $fields <<OpenSearchPanel>> \
        [double% [list [namespace current]::open_panel $w $sf]]
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
