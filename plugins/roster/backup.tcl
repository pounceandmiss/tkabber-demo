# backup.tcl --
#
#       Export/import of the roster items using an XML file.
#       This code provides basic framework for handling roster backup
#       files and it's able to serialize/deserialize regular roster contacts.
#       Hooks provided to facilitate implementations of storing/restoring
#       other kinds of data logically pertaining to the roster
#       such as conference bookmarks, annotations, etc.

namespace eval rosterbackup {
    set ::NS(rosterbackup) http://tkabber.jabber.ru/contactlist

    hook::add connected_hook \
        [namespace current]::setup_import_export_menus
    hook::add disconnected_hook \
        [namespace current]::setup_import_export_menus
    hook::add finload_hook \
        [namespace current]::setup_import_export_menus

    hook::add serialize_roster_hook \
        [namespace current]::serialize_roster_contacts
    hook::add deserialize_roster_hook \
        [namespace current]::deserialize_roster_contacts
}

###############################################################################

proc rosterbackup::setup_import_export_menus {args} {
    set rmenu [.mainframe getmenu roster]
    set elabel2 [::msgcat::mc "Export roster"]
    set ilabel2 [::msgcat::mc "Import roster"]
    set elabel1 $elabel2...
    set ilabel1 $ilabel2...

    catch {$rmenu delete $elabel1}
    catch {$rmenu delete $ilabel1}
    catch {$rmenu delete $elabel2}
    catch {$rmenu delete $ilabel2}

    set index [$rmenu index [::msgcat::mc "Add group by regexp on JIDs..."]]

    set emenu .export_roster
    set imenu .import_roster

    if {[winfo exists $emenu]} {
        destroy $emenu
    }

    if {[winfo exists $imenu]} {
        destroy $imenu
    }

    switch -- [llength [connections]] {
        0 {
            $rmenu insert $index command -label $ilabel1 -state disabled
            $rmenu insert $index command -label $elabel1 -state disabled
        }
        1 {
            set xlib [lindex [connections] 0]
            $rmenu insert $index command -label $ilabel1 -state normal \
                    -command [namespace code [list import_from_file $xlib]]
            $rmenu insert $index command -label $elabel1 -state normal \
                    -command [namespace code [list export_to_file $xlib]]
        }
        default {
            menu $emenu -tearoff $::ifacetk::options(show_tearoffs)
            menu $imenu -tearoff $::ifacetk::options(show_tearoffs)

            $rmenu insert $index cascade -label $ilabel2 -state normal \
                    -menu $imenu
            $rmenu insert $index cascade -label $elabel2 -state normal \
                    -menu $emenu

            foreach xlib [connections] {
                set jid [connection_jid $xlib]
                $emenu add command -label [::msgcat::mc "Export roster for %s..." $jid] \
                        -command [namespace code [list export_to_file $xlib]]
                $imenu add command -label [::msgcat::mc "Import roster for %s..." $jid] \
                        -command [namespace code [list import_from_file $xlib]]
            }
        }
    }
}

###############################################################################

proc rosterbackup::export_to_file {xlib} {
    set filename [tk_getSaveFile \
                      -initialdir $::configdir \
                      -initialfile [connection_user $xlib]-roster.xml \
                      -filetypes [list \
                                      [list [::msgcat::mc "Roster files"] \
                                           .xml] \
                                      [list [::msgcat::mc "All files"] *]]]
    if {$filename == ""} return

    set fd [open $filename w]
    fconfigure $fd -encoding utf-8

    puts $fd {<?xml version="1.0" encoding="UTF-8"?>}
    puts $fd [serialize_roster $xlib]

    close $fd
}

###############################################################################

proc rosterbackup::serialize_roster {xlib} {
    global NS

    set subtags [list]
    hook::run serialize_roster_hook $xlib #[info level] subtags

    ::xmpp::xml::toTabbedText [::xmpp::xml::create contactlist \
                                        -xmlns $NS(rosterbackup) \
                                        -subelements $subtags]
}

###############################################################################

proc rosterbackup::serialize_roster_contacts {xlib level varName} {
    upvar $level $varName subtags

    set items [list]
    foreach jid [::roster::get_jids $xlib] {
        set category [::roster::itemconfig $xlib $jid -category]
        switch -- $category {
            user -
            gateway {
                lappend items [::roster::item_to_xml $xlib $jid]
            }
        }
    }

    lappend subtags [::xmpp::xml::create roster \
                            -xmlns jabber:iq:roster \
                            -subelements $items]
}

###############################################################################

proc rosterbackup::import_from_file {xlib} {
    set filename [tk_getOpenFile \
                      -initialdir $::configdir \
                      -initialfile [connection_user $xlib]-roster.xml \
                      -filetypes [list \
                                      [list [::msgcat::mc "Roster files"] \
                                           .xml] \
                                      [list [::msgcat::mc "All files"] *]]]
    if {$filename == ""} return

    set fd [open $filename r]
    fconfigure $fd -encoding utf-8
    set xml [string trimleft [read $fd] [format %c 0xFEFF]] ;# strip BOM, if any
    close $fd

    deserialize_roster $xlib $xml
}

###############################################################################

proc rosterbackup::deserialize_roster {xlib data} {
    hook::run roster_deserializing_hook $xlib

    ::xmpp::xml::parseData $data [namespace code [list parse_roster_xml $xlib]]

    hook::run roster_deserialized_hook $xlib
}

###############################################################################

proc rosterbackup::parse_roster_xml {xlib data} {
    global NS

    ::xmpp::xml::split $data tag xmlns attrs cdata subels

    if {![string equal $tag contactlist]} {
        return -code error "Bad root element \"$tag\": must be contactlist"
    }
    if {![string equal $xmlns $NS(rosterbackup)]} {
        return -code error "Bad root element namespace \"$xmlns\":\
                            must be \"$NS(rosterbackup)\""
    }

    set tuples [list]
    hook::run deserialize_roster_hook $xlib $subels #[info level] tuples

    if {[llength $tuples] > 0} {
        set scripts [list]
        foreach tuple [lsort -integer -index 0 $tuples] {
            lappend scripts [lindex $tuple 1]
        }
        [namespace current]::run_deserialization_scripts $scripts
    }
}

###############################################################################

proc rosterbackup::run_deserialization_scripts {scripts} {
    if {[llength $scripts] == 0} return

    uplevel #0 [linsert [lindex $scripts 0] end \
        [list [lindex [info level 0] 0] [lrange $scripts 1 end]]]
}

###############################################################################

proc rosterbackup::deserialize_roster_contacts {xlib data level varName} {
    global NS
    upvar $level $varName handlers

    array set existing {}
    foreach jid [::roster::get_jids $xlib] {
        set existing($jid) {}
    }

    upvar 0 sent($xlib,jids) jids
    set jids [list]
    set subtags [list]

    foreach item $data {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        if {![string equal $tag roster]} continue
        if {![string equal $xmlns jabber:iq:roster]} {
            return -code error "Bad roster element namespace \"$xmlns\":\
                                must be \"jabber:iq:roster\""
        }

        foreach subel $subels {
            set jid [get_item_jid $subel]
            if {![info exists existing($jid)]} {
                lappend jids $jid
                lappend subtags $subel
            }
        }
    }

    if {[llength $subtags] > 0} {
        lappend handlers [list 50 [namespace code [list \
                                             send_contacts $xlib $subtags]]]
    }

    lappend handlers [list 1000 [namespace code [list \
                                        show_restore_completion_dialog $xlib]]]
}

###############################################################################

proc rosterbackup::get_item_jid {data} {
    ::xmpp::xml::split $data tag xmlns attrs cdata subels
    ::xmpp::xml::getAttr $attrs jid
}

###############################################################################

proc rosterbackup::send_contacts {xlib contacts continuation} {
    global NS

    set contact [lindex $contacts 0]
    ::xmpp::sendIQ $xlib set \
        -query [::xmpp::xml::create query \
                            -xmlns jabber:iq:roster \
                            -subelement $contact] \
        -command [namespace code [list process_send_result $xlib \
                                                [lrange $contacts 1 end] \
                                                [get_item_jid $contact] \
                                                $continuation]]
}

###############################################################################

proc rosterbackup::process_send_result {xlib contacts jid
                                        continuation result xmldata} {
    switch -- $result {
        ok {
            if {[llength $contacts] > 0} {
                send_contacts $xlib $contacts $continuation
            } else {
                {*}$continuation
            }
        }
        default {
            # TODO check whether do we need to handle TIMEOUT specially
            NonmodalMessageDlg [epath] \
                -aspect 50000 \
                -icon error \
                -title [::msgcat::mc "Error"] \
                -message [::msgcat::mc "Error importing roster contact %s: %s" \
                                       $jid [error_to_string $xmldata]]
        }
    }
}

###############################################################################

proc rosterbackup::show_restore_completion_dialog {xlib continuation} {
    NonmodalMessageDlg [epath] \
        -aspect 50000 \
        -icon info \
        -title [::msgcat::mc "Information"] \
        -message [::msgcat::mc "Roster import for %s is completed" \
                               [connection_bare_jid $xlib]]
    {*}$continuation
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
