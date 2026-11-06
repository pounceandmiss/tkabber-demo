# bkup_metacontacts.tcl --
#
#       Support for backup/restore of metacontacts (XEP-0209)
#       for roster items.

namespace eval metabackup {
    # Should probably go after the roster contacts, so we set prio to 60:
    hook::add serialize_roster_hook \
              [namespace current]::serialize_metacontacts 60
    hook::add deserialize_roster_hook \
              [namespace current]::deserialize_metacontacts 60
}

###############################################################################

proc metabackup::serialize_metacontacts {xlib level varName} {
    upvar $level $varName subtags
    global NS

    set xmldata [::xmpp::roster::metacontacts::serialize \
                        [::plugins::metacontacts::serialize_contacts $xlib]]

    lappend subtags [::xmpp::xml::create privstorage \
                                -xmlns jabber:iq:private \
                                -subelement $xmldata]
}

###############################################################################

proc metabackup::deserialize_metacontacts {xlib data level varName} {
    global NS
    upvar $level $varName handlers

    set contacts [list]
    foreach item $data {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels
        if {![string equal $tag privstorage]} continue
        if {![string equal $xmlns jabber:iq:private]} {
            return -code error "Bad roster element namespace \"$xmlns\":\
                                must be \"jabber:iq:private\""
        }

        set contacts [concat $contacts \
                          [::xmpp::roster::metacontacts::deserialize $subels]]
    }

    if {[llength $contacts] > 0} {
        lappend handlers [list 60 [namespace code [list \
                                                    send_contacts $xlib $contacts]]]
    }
}

###############################################################################

proc metabackup::send_contacts {xlib contacts continuation} {
    set updated 0

    foreach {tag jids} $contacts {
        set added [::plugins::metacontacts::create_contact \
                            $xlib $tag $jids -merge yes]
        set updated [expr {$updated || $added}]
    }

    if {$updated} {
        ::plugins::metacontacts::store_contacts $xlib \
            -command [namespace code [list process_sending_result $continuation]]
    } else {
        {*}$continuation
    }
}

###############################################################################

proc metabackup::process_sending_result {continuation result xmldata} {
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
                -message [::msgcat::mc "Error restoring metacontacts: %s" \
                    [error_to_string $xmldata]]
        }
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
