# user_location.tcl --
#
#       Implementation of XEP-0080 "User Location"

package require xmpp::pep

namespace eval geoloc {
    variable node http://jabber.org/protocol/geoloc
    variable substatus
    variable geoloc

    custom::defvar options(auto-subscribe) 0 \
        [::msgcat::mc "Auto-subscribe to other's user location notifications."] \
        -command [namespace current]::register_in_disco \
        -group PEP -type boolean

    pubsub::register_event_notification_handler $node \
            [namespace current]::process_geoloc_notification
    hook::add user_geoloc_notification_hook \
            [namespace current]::notify_via_status_message

    hook::add finload_hook \
            [namespace current]::on_init 60
    hook::add connected_hook \
            [namespace current]::on_connect_disconnect
    hook::add disconnected_hook \
            [namespace current]::on_connect_disconnect
    hook::add roster_jid_popup_menu_hook \
            [namespace current]::add_roster_pep_menu_item
    hook::add roster_user_popup_info_hook \
            [namespace current]::provide_roster_popup_info
    hook::add userinfo_hook \
            [namespace current]::provide_userinfo

    disco::register_feature $node

    variable fields [list alt area bearing building country datum \
                          description error floor lat locality lon \
                          postalcode region room speed street text \
                          timestamp uri]

    variable labels
    array set labels [list alt         [::msgcat::mc "Altitude:"] \
                           area        [::msgcat::mc "Area:"] \
                           bearing     [::msgcat::mc "Bearing:"] \
                           building    [::msgcat::mc "Building:"] \
                           country     [::msgcat::mc "Country:"] \
                           datum       [::msgcat::mc "GPS datum:"] \
                           description [::msgcat::mc "Description:"] \
                           error       [::msgcat::mc "Horizontal GPS error:"] \
                           floor       [::msgcat::mc "Floor:"] \
                           lat         [::msgcat::mc "Latitude:"] \
                           locality    [::msgcat::mc "Locality:"] \
                           lon         [::msgcat::mc "Longitude:"] \
                           postalcode  [::msgcat::mc "Postal code:"] \
                           region      [::msgcat::mc "Region:"] \
                           room        [::msgcat::mc "Room:"] \
                           speed       [::msgcat::mc "Speed:"] \
                           street      [::msgcat::mc "Street:"] \
                           text        [::msgcat::mc "Text:"] \
                           timestamp   [::msgcat::mc "Timestamp:"] \
                           uri         [::msgcat::mc "URI:"]]
}

proc geoloc::register_in_disco {args} {
    variable options
    variable node

    if {$options(auto-subscribe)} {
       disco::register_feature $node+notify
    } else {
       disco::unregister_feature $node+notify
    }
}

proc geoloc::add_roster_pep_menu_item {m xlib jid} {
    set rjid [roster::find_jid $xlib $jid]

    if {$rjid == ""} {
         set rjid [::xmpp::jid::removeResource $jid]
    }

    set pm [pep::get_roster_menu_pep_submenu $m $xlib $rjid]

    set mm [menu $pm.geoloc -tearoff no]
    $pm add cascade -menu $mm \
            -label [::msgcat::mc "User location"]

    $mm add command \
            -label [::msgcat::mc "Subscribe"] \
            -command [list [namespace current]::subscribe $xlib $rjid]
    $mm add command \
            -label [::msgcat::mc "Unsubscribe"] \
            -command [list [namespace current]::unsubscribe $xlib $rjid]

    hook::run roster_pep_user_geoloc_menu_hook $mm $xlib $rjid
}

proc geoloc::subscribe {xlib jid args} {
    variable node
    variable substatus

    set to [::xmpp::jid::removeResource $jid]
    set cmd [linsert $args 0 [namespace current]::subscribe_result $xlib $to]
    ::xmpp::pep::subscribe $xlib $to $node -command $cmd
    set substatus($xlib,$to) sent-subscribe
}

proc geoloc::unsubscribe {xlib jid args} {
    variable node
    variable substatus

    set to [::xmpp::jid::removeResource $jid]
    set cmd [linsert $args 0 [namespace current]::unsubscribe_result $xlib $to]
    ::xmpp::pep::unsubscribe $xlib $to $node -command $cmd
    set substatus($xlib,$to) sent-unsubscribe
}

# Err may be one of: ok, error and abort
proc geoloc::subscribe_result {xlib jid res child args} {
    variable substatus

    set cmd ""
    foreach {opt val} $args {
        switch -- $opt {
            -command {
                set cmd $val
            }
            default {
                return -code error "unknown option: $opt"
            }
        }
    }

    switch -- $res {
        ok {
            set substatus($xlib,$jid) from
        }
        error {
            set substatus($xlib,$jid) error
        }
        default {
            return
        }
    }

    if {$cmd ne ""} {
        {*}$cmd $jid $res $child
    }
}

proc geoloc::unsubscribe_result {xlib jid res child args} {
    variable substatus
    variable geoloc
    variable fields

    set cmd ""
    foreach {opt val} $args {
        switch -- $opt {
            -command {
                set cmd $val
            }
            default {
                return -code error "unknown option: $opt"
            }
        }
    }

    if {[string equal $res ok]} {
        set substatus($xlib,$jid) none
        foreach f $fields {
            catch {unset geoloc($f,$xlib,$jid)}
        }
    }

    if {$cmd != ""} {
        {*}$cmd $jid $res $child
    }
}

proc geoloc::provide_roster_popup_info {var xlib user} {
    variable substatus
    variable geoloc

    upvar 0 $var info

    set jid [::xmpp::jid::removeResource $user]

    if {[info exists geoloc(title,$xlib,$jid)]} {
        append info [::msgcat::mc "\n\tLocation: %s : %s" \
                                  $geoloc(lat,$xlib,$jid) \
                                  $geoloc(lon,$xlib,$jid)]
    } elseif {[info exists substatus($xlib,$jid)]} {
        append info [::msgcat::mc "\n\tUser location subscription: %s" \
                                  $substatus($xlib,$jid)]
    } else {
        return
    }

}

proc geoloc::process_geoloc_notification {xlib jid items} {
    variable node
    variable geoloc
    variable fields

    foreach f $fields {
        set $f ""
    }
    set retract false
    set parsed  false

    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        switch -- $tag {
            retract {
                set retract true
            }
            default {
                foreach igeoloc $subels {
                    ::xmpp::xml::split $igeoloc stag sxmlns sattrs scdata ssubels

                    if {![string equal $stag geoloc]} continue
                    if {![string equal $sxmlns $node]} continue

                    set parsed true

                    foreach i $ssubels {
                        ::xmpp::xml::split $i sstag ssxmlns ssattrs sscdata sssubels

                        if {$sstag in $fields} {
                            set $sstag $sscdata
                        }
                    }
                }
            }
        }
    }

    if {$parsed} {
        foreach f $fields {
            set geoloc($f,$xlib,$jid) [set $f]
        }
        hook::run user_geoloc_notification_hook $xlib $jid $lat $lon
    } elseif {$retract} {
        foreach f $fields {
            catch {unset geoloc($f,$xlib,$jid)}
        }
        hook::run user_geoloc_notification_hook $xlib $jid "" ""
    }
}

proc geoloc::notify_via_status_message {xlib jid lat lon} {
    set contact [::roster::itemconfig $xlib $jid -name]
    if {$contact == ""} {
        set contact $jid
    }

    if {$lat == "" && $lon == ""} {
        set msg [::msgcat::mc "%s's location is unset" $contact]
    } else {
        set msg [::msgcat::mc "%s's location changed to %s : %s" \
                              $contact $lat $lon]
    }

    set_status $msg
}

proc geoloc::publish {xlib args} {
    variable node
    variable fields

    foreach f $fields {
        set $f ""
    }
    set callback ""
    foreach {opt val} $args {
        switch -- $opt {
            -command { set callback $val }
            default {
                set opt [string trimleft $opt -]
                if {$opt in $fields} {
                    set $opt $val
                }
            }
        }
    }

    set content {}
    foreach f $fields {
        if {[set $f] ne ""} {
            lappend content [::xmpp::xml::create $f -cdata [set $f]]
        }
    }

    set args {}
    if {$callback ne ""} {
        lappend args -command $callback
    }

    ::xmpp::pep::publishItem $xlib $node geoloc \
            -payload [list [::xmpp::xml::create geoloc \
                                    -xmlns $node \
                                    -subelements $content]] \
            {*}$args
}

proc geoloc::unpublish {xlib args} {
    variable node

    set callback ""
    foreach {opt val} $args {
        switch -- $opt {
            -command { set callback $val }
        }
    }

    set args {}
    if {$callback ne ""} {
        lappend args -command $callback
    }

    ::xmpp::pep::deleteItem $xlib $node geoloc -notify true {*}$args
}

proc geoloc::on_init {} {
    set m [pep::get_main_menu_pep_submenu]
    set mm [menu $m.geoloc -tearoff $::ifacetk::options(show_tearoffs)]
    $m add cascade -menu $mm \
           -label [::msgcat::mc "User location"]
    $mm add command -label [::msgcat::mc "Publish user location..."] \
            -state disabled \
            -command [namespace current]::show_publish_dialog
    $mm add command -label [::msgcat::mc "Unpublish user location"] \
            -state disabled \
            -command [namespace current]::show_unpublish_dialog
    $mm add checkbutton -label [::msgcat::mc "Auto-subscribe to other's user location"] \
            -variable [namespace current]::options(auto-subscribe)
}

proc geoloc::on_connect_disconnect {args} {
    set mm [pep::get_main_menu_pep_submenu].geoloc
    set idx [expr {$::ifacetk::options(show_tearoffs) ? 1 : 0}]

    switch -- [llength [connections]] {
        0 {
            $mm entryconfigure $idx -state disabled
            $mm entryconfigure [incr idx] \
                -label [::msgcat::mc "Unpublish user location"] \
                -state disabled
        }
        1 {
            $mm entryconfigure $idx -state normal
            $mm entryconfigure [incr idx] \
                -label [::msgcat::mc "Unpublish user location"] \
                -state normal
        }
        default {
            $mm entryconfigure $idx -state normal
            $mm entryconfigure [incr idx] \
                -label [::msgcat::mc "Unpublish user location..."] \
                -state normal
        }
    }
}

proc geoloc::show_publish_dialog {} {
    variable fields
    variable labels
    variable myjid
    foreach ff $fields {
        variable geoloc$ff ""
    }

    set w .user_geoloc
    if {[winfo exists $w]} {
        destroy $w
    }

    set xlibs [connections]
    if {[llength $xlibs] == 0} {
        NonmodalMessageDlg [epath] \
                -aspect 50000 \
                -icon error \
                -title [::msgcat::mc "Error"] \
                -message [::msgcat::mc "Publishing is only possible\
                                        while being online"]
        return
    }

    Dialog $w -title [::msgcat::mc "User location"] \
            -modal none -anchor e -default 0 -cancel 1 -parent .
    $w add -text [::msgcat::mc "Publish"] \
           -command [list [namespace current]::do_publish $w]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set f [$w getframe]

    set connjids [list [::msgcat::mc "All"]]
    foreach xlib $xlibs {
        lappend connjids [connection_jid $xlib]
    }
    set myjid [lindex $connjids 0]

    Label $f.ccap -text [::msgcat::mc "Use connection:"]
    Combobox $f.conn -editable false \
            -values $connjids \
            -textvariable [namespace current]::myjid
    if {[llength $connjids] > 1} {
        grid $f.ccap   -row 0 -column 0 -sticky e
        grid $f.conn   -row 0 -column 1 -sticky ew
    }

    set row 1
    foreach ff $fields {
        Label $f.l$ff -text $labels($ff)
        Entry $f.$ff -textvariable [namespace current]::geoloc$ff
        grid $f.l$ff  -row $row -column 0 -sticky e
        grid $f.$ff   -row $row -column 1 -sticky ew
        incr row
    }

    grid columnconfigure $f 1 -weight 1

    $w draw
}

proc geoloc::do_publish {w} {
    variable fields
    variable myjid
    foreach ff $fields {
        variable geoloc$ff
    }

    set args {}
    foreach ff $fields {
        lappend args -$ff [set geoloc$ff]
    }

    foreach xlib [connections] {
        if {[string equal $myjid [connection_jid $xlib]] || \
                [string equal $myjid [::msgcat::mc "All"]]} {
            publish $xlib -command [namespace current]::publish_result {*}$args
            break
        }
    }

    foreach ff $fields {
        unset geoloc$ff
    }
    unset myjid
    destroy $w
}

# $res is one of: ok, err, abort
proc geoloc::publish_result {res child} {
    switch -- $res {
        error {
            set error [error_to_string $child]
        }
        default {
            return
        }
    }

    NonmodalMessageDlg [epath] \
            -aspect 50000 \
            -icon error \
            -title [::msgcat::mc "Error"] \
            -message [::msgcat::mc "User location publishing failed: %s" $error]
}

proc geoloc::show_unpublish_dialog {} {
    variable myjid

    set w .user_geoloc
    if {[winfo exists $w]} {
        destroy $w
    }

    set xlibs [connections]
    if {[llength $xlibs] == 0} {
        NonmodalMessageDlg [epath] \
                -aspect 50000 \
                -icon error \
                -title [::msgcat::mc "Error"] \
                -message [::msgcat::mc "Unpublishing is only possible\
                                        while being online"]
        return
    }

    Dialog $w -title [::msgcat::mc "User location"] \
            -modal none -anchor e -default 0 -cancel 1 -parent .
    $w add -text [::msgcat::mc "Unpublish"] \
           -command [list [namespace current]::do_unpublish $w]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set f [$w getframe]

    set connjids [list [::msgcat::mc "All"]]
    foreach xlib $xlibs {
        lappend connjids [connection_jid $xlib]
    }
    set myjid [lindex $connjids 0]

    Label $f.ccap -text [::msgcat::mc "Use connection:"]
    Combobox $f.conn -editable false \
            -values $connjids \
            -textvariable [namespace current]::myjid

    if {[llength $connjids] > 1} {
        grid $f.ccap   -row 0 -column 0 -sticky e
        grid $f.conn   -row 0 -column 1 -sticky ew
    }

    grid columnconfigure $f 1 -weight 1

    if {[llength $xlibs] == 1} {
        do_unpublish $w
    } else {
        $w draw
    }
}

proc geoloc::do_unpublish {w} {
    variable myjid

    foreach xlib [connections] {
        if {[string equal $myjid [connection_jid $xlib]] || \
                [string equal $myjid [::msgcat::mc "All"]]} {
            unpublish $xlib \
                    -command [namespace current]::unpublish_result
            break
        }
    }

    unset myjid
    destroy $w
}

# $res is one of: ok, error, abort
proc geoloc::unpublish_result {res child} {
    switch -- $res {
        error {
            if {[lindex [error_type_condition $child] 1] == "item-not-found"} {
                return
            }
            set error [error_to_string $child]
        }
        default {
            return
        }
    }

    NonmodalMessageDlg [epath] \
            -aspect 50000 \
            -icon error \
            -title [::msgcat::mc "Error"] \
            -message [::msgcat::mc "User location unpublishing failed: %s" $error]
}

proc geoloc::provide_userinfo {notebook xlib jid editable} {
    variable geoloc
    variable m2d
    variable ::userinfo::userinfo
    variable fields
    variable labels

    if {$editable} return

    set barejid [::xmpp::jid::removeResource $jid]
    if {![info exists geoloc(alt,$xlib,$barejid)]} return

    foreach ff $fields {
        set userinfo(geoloc$ff,$jid) $geoloc($ff,$xlib,$barejid)
    }

    set f [pep::get_userinfo_dialog_pep_frame $notebook]
    set mf [userinfo::pack_frame $f.geoloc [::msgcat::mc "User location"]]

    set row 0
    foreach ff $fields {
        userinfo::pack_entry $jid $mf $row geoloc$ff $labels($ff)
        incr row
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
