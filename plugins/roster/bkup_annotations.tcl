# bkup_annotations.tcl --
#
#       Support for backup/restore of "annotations" (XEP-0145)
#       for roster items.
#
# Depends on: annotations.tcl, backup.tcl

namespace eval annobackup {
    # Should probably go after the roster contacts, so we set prio to 60:
    hook::add serialize_roster_hook \
              [namespace current]::serialize_annotations 60
    hook::add deserialize_roster_hook \
              [namespace current]::deserialize_annotations 60
}

###############################################################################

proc annobackup::serialize_annotations {xlib level varName} {
    upvar $level $varName subtags
    global NS

    set xmldata [::xmpp::roster::annotations::serialize \
                        [::plugins::annotations::serialize_notes $xlib]]

    lappend subtags [::xmpp::xml::create privstorage \
                                -xmlns jabber:iq:private \
                                -subelement $xmldata]
}

###############################################################################

proc annobackup::deserialize_annotations {xlib data level varName} {
    global NS
    upvar $level $varName handlers

    set notes [list]
    foreach item $data {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels
        if {![string equal $tag privstorage]} continue
        if {![string equal $xmlns jabber:iq:private]} {
            return -code error "Bad roster element namespace \"$xmlns\":\
                                must be \"jabber:iq:private\""
        }

        set notes [concat $notes \
                          [::xmpp::roster::annotations::deserialize $subels]]
    }

    if {[llength $notes] > 0} {
        lappend handlers [list 60 [namespace code [list \
                                                    send_notes $xlib $notes]]]
    }
}

###############################################################################

proc annobackup::send_notes {xlib notes continuation} {
    set updated 0

    foreach item $notes {
        set added [::plugins::annotations::create_note \
                $xlib $item -merge yes]
        set updated [expr {$updated || $added}]
    }

    if {$updated} {
        ::plugins::annotations::cleanup_and_store_notes $xlib \
            -command [namespace code [list process_sending_result $continuation]]
    } else {
        {*}$continuation
    }
}

###############################################################################

proc annobackup::process_sending_result {continuation result xmldata} {
    switch -- $result {
        ok {
            {*}$continuation
        }
        default {
            # TODO check whether do we need to handle TIMEOUT specially
            NonmodalMessageDlg [epath] \
                -aspect 50000 \
                -icon error \
                -title [::msgcat::mc "Error"] \
                -message [::msgcat::mc "Error restoring annotations: %s" \
                    [error_to_string $xmldata]]
        }
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
