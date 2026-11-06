# bkup_conferences.tcl --
#
#       Support for backup/restore of "roster bookmarks" to MUC rooms
#       (XEP-0048, v1.0)
#
# Depends on:
#       conferences.tcl, backup.tcl

namespace eval mucbackup {
    # Should probably go after the roster contacts, so we set prio to 70:
    hook::add serialize_roster_hook \
        [namespace current]::serialize_muc_bookmarks 70
    hook::add deserialize_roster_hook \
        [namespace current]::deserialize_muc_bookmarks 70
}

###############################################################################

proc mucbackup::serialize_muc_bookmarks {xlib level varName} {
    upvar $level $varName subtags
    global NS

    lassign [::plugins::conferences::serialize_bookmarks $xlib] \
            bookmarks groupstag

    lappend subtags [::xmpp::xml::create privstorage \
                                         -xmlns jabber:iq:private \
                                         -subelement \
                                         [::xmpp::roster::bookmarks::serialize \
                                                            $bookmarks]]
    lappend subtags [::xmpp::xml::create privstorage \
                                         -xmlns jabber:iq:private \
                                         -subelement $groupstag]
}

###############################################################################

proc mucbackup::deserialize_muc_bookmarks {xlib data level varName} {
    global NS
    upvar $level $varName handlers

    set bookmarks [list]
    set bmgroups  [list]
    foreach item $data {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels
        if {![string equal $tag privstorage]} continue
        if {![string equal $xmlns $NS(private)]} {
            return -code error "Bad roster element namespace \"$xmlns\":\
                                must be \"$NS(private)\""
        }

        set bookmarks [concat $bookmarks \
                              [::xmpp::roster::bookmarks::deserialize $subels]]

        foreach storage $subels {
            ::xmpp::xml::split $storage stag sxmlns sattrs scdata ssubels
            if {![string equal $stag storage] || \
                    ![string equal $sxmlns tkabber:bookmarks:groups]} continue
                set bmgroups [concat $bmgroups $ssubels]
        }
    }

    if {[llength $bookmarks] > 0 || [llength $bmgroups] > 0} {
        lappend handlers [list 70 [namespace code [list \
            merge_muc_bookmarks $xlib $bookmarks $bmgroups]]]
    }
}

###############################################################################

proc mucbackup::merge_muc_bookmarks {xlib bookmarks bmgroups continuation} {
    variable updated 0

    foreach item $bookmarks {
        set added [::plugins::conferences::create_muc_bookmark \
                $xlib $item -merge yes]
        set updated [expr {$updated || $added}]
    }

    foreach item $bmgroups {
        set added [::plugins::conferences::create_muc_bmgroup \
                $xlib $item -merge yes]
        set updated [expr {$updated || $added}]
    }

    if {$updated} {
        ::plugins::conferences::store_bookmarks $xlib \
            -command [namespace code [list process_merging_result $continuation]]
        ::plugins::conferences::push_bookmarks_to_roster $xlib
    } else {
        {*}$continuation
    }
}

###############################################################################

proc mucbackup::process_merging_result {continuation result xmldata} {
    switch -- $result {
        ok {
            {*}$continuation
        }
        default {
            # TODO check whether TIMEOUT should be processed separately
            NonmodalMessageDlg [epath] \
                -aspect 50000 \
                -icon error \
                -title [::msgcat::mc "Error"] \
                -message [::msgcat::mc "Error restoring conference bookmarks: %s" \
                    [error_to_string $xmldata]]
        }
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
