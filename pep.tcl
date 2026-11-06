# pep.tcl --
#
#       Personal eventing via pubsub XEP-0163

package require xmpp::pep

namespace eval pep {
    custom::defgroup Plugins \
        [::msgcat::mc "Plugins options."] \
        -group Tkabber

    custom::defgroup PEP \
        [::msgcat::mc "Personal eventing via pubsub plugins options."] \
        -group Plugins
}

##########################################################################
# Returns a name of a submenu (of menu $m) for PEP commands to perform on
# the roster item for a user with JID $jid.
# This command automatically creates this submenu if needed.

proc pep::get_roster_menu_pep_submenu {m xlib jid} {
    set pm $m.pep

    if {![winfo exists $pm]} {
        menu $pm -tearoff no
        $m add cascade -menu $pm \
                -label [::msgcat::mc "Personal eventing"]
    }

    return $pm
}

##########################################################################
# Returns pathname of a frame comprising a page for PEP info in
# the userinfo (vCard) dialog which notebook widget is $notebook.
# If that page is not yet exist, it's created.

proc pep::get_userinfo_dialog_pep_frame {notebook} {
    if {![winfo exists $notebook.pep] || [$notebook index pep] < 0} {
        return [$notebook insert end pep \
                        -text [::msgcat::mc "Personal eventing"]]
    } else {
        return [$notebook getframe pep]
    }
}

proc pep::get_main_menu_pep_submenu {} {
    return [.mainframe getmenu services].pep
}

proc pep::on_init {} {
    set m [.mainframe getmenu services]
    set idx [$m index [::msgcat::mc "Service Discovery"]]
    set pm [menu $m.pep -tearoff $::ifacetk::options(show_tearoffs)]
    $m insert [expr {$idx + 2}] cascade -menu $pm \
            -label [::msgcat::mc "Personal eventing"]
}

hook::add finload_hook [namespace current]::pep::on_init

# vim:ft=tcl:ts=8:sw=4:sts=4:et
