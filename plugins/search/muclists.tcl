# muclists.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which adds
#       a serach panel to the MUC lists (admin list, ban list etc.).

namespace eval search::muclists {}

proc search::muclists::open_panel {w sw swl sf} {
    pack $sf -side bottom -anchor w -fill x -before $sw
    update idletasks
    $swl show end
}

proc search::muclists::close_panel {w sw swl sf} {
    $swl sel clear 0 end
    pack forget $sf
    $w setfocus 0
}

proc search::muclists::setup_panel {w sw swl} {
    set sf [plugins::search::spanel $w.search \
                -searchcommand [list [namespace parent]::mclistbox::do_search $swl] \
                -closecommand [list [namespace current]::close_panel $w $sw $swl]]

    bind $w <<OpenSearchPanel>> \
            [double% [list [namespace current]::open_panel $w $sw $swl $sf]]
}

hook::add open_muc_list_post_hook \
          [namespace current]::search::muclists::setup_panel

# vim:ft=tcl:ts=8:sw=4:sts=4:et
