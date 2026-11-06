# conferences.tcl --
#
#       Bookmarks (XEP-0048) support (conference bookmarks in roster)
#
#       In addition to XEP-0048, Tkabber stores roster groups using
#       proprietory namespace tkabber:bookmarks:groups inside
#       jabber:iq:private storage (XEP-0049)
#
# tkabber:bookmarks:groups description:
#
#   setting:
#   <iq type='set' id='setgroups'>
#       <query xmlns='jabber:iq:private'>
#           <storage xmlns='tkabber:bookmarks:groups'>
#               <conference jid='talks@conference.jabber.ru'>
#                   <group>Conferences</group>
#                   <group>jabber.ru</group>
#               </conference>
#           </storage>
#       </query>
#   </iq>
#
#   getting:
#   <iq type='get' id='getgroups'>
#       <query xmlns='jabber:iq:private'>
#           <storage xmlns='tkabber:bookmarks:groups'/>
#       </query>
#   </iq>
#

package require xmpp::roster::bookmarks

namespace eval conferences {
    # variable to store roster conference bookmarks
    variable bookmarks
    array set bookmarks {}

    set ::NS(tkabber:groups) "tkabber:bookmarks:groups"

    custom::defvar options(ignore_autojoin) 0 \
        [::msgcat::mc "Ignore autojoin option and do not automatically join\
                       conference rooms on login."] \
        -type boolean -group Chat

    custom::defvar options(roster_group) [::msgcat::mc "Conferences"] \
        [::msgcat::mc "Default group for conferences in roster."] \
        -type string -group Hidden
}

###############################################################################
#
#   Free bookmarks on disconnect
#

proc conferences::free_bookmarks {xlib} {
    variable bookmarks

    array unset bookmarks $xlib,*
}

hook::add disconnected_hook [namespace current]::conferences::free_bookmarks

###############################################################################
#
#   Retrieve bookmarks on connect
#

proc conferences::request_bookmarks {xlib} {
    variable bookmarks
    variable responds

    set responds($xlib) 0
    array unset bookmarks $xlib,*
    set bookmarks($xlib) {}

    ::xmpp::roster::bookmarks::retrieve $xlib \
            -command [list [namespace current]::process_bookmarks $xlib]

    ::xmpp::private::retrieve $xlib [list [::xmpp::xml::create storage \
                                                -xmlns $::NS(tkabber:groups)]] \
            -command [list [namespace current]::process_groups $xlib]
}

hook::add connected_hook [namespace current]::conferences::request_bookmarks 20

proc conferences::process_bookmarks {xlib status bmlist} {
    variable bookmarks
    variable responds
    global NS

    if {$status != "ok"} return

    incr responds($xlib)

    foreach bookmark $bmlist {
        create_muc_bookmark $xlib $bookmark
    }

    if {$responds($xlib) < 2} return

    push_bookmarks_to_roster $xlib
    after idle [list [namespace current]::autojoin_groups $xlib]
}

proc conferences::process_groups {xlib status xmlList} {
    variable bookmarks
    variable responds
    global NS

    if {$status != "ok"} return

    incr responds($xlib)

    foreach xml $xmlList {
        ::xmpp::xml::split $xml tag xmlns attrs cdata subels

        if {$xmlns == $NS(tkabber:groups)} {
            foreach bookmark $subels {
                create_muc_bmgroup $xlib $bookmark
            }
        }
    }

    if {$responds($xlib) < 2} return

    push_bookmarks_to_roster $xlib
    after idle [list [namespace current]::autojoin_groups $xlib]
}

proc conferences::create_muc_bookmark {xlib bookmark args} {
    variable bookmarks

    set merge 0
    foreach {opt val} $args {
        switch -- $opt {
            -merge { set merge $val }
            default {
                return -code error "Bad option \"$opt\": must be -merge"
            }
        }
    }

    array set n $bookmark

    set jid [::xmpp::jid::normalize $n(jid)]

    if {$merge && [info exists bookmarks($xlib,jid,$jid)]} {
        return 0
    } else {
        if {$jid ni $bookmarks($xlib)} {
            lappend bookmarks($xlib) $jid
        }
        set bookmarks($xlib,jid,$jid) $jid

        set bookmarks($xlib,name,$jid) ""
        set bookmarks($xlib,nick,$jid) ""
        set bookmarks($xlib,password,$jid) ""
        set bookmarks($xlib,autojoin,$jid) 0

        if {[info exists n(name)]} {
            set bookmarks($xlib,name,$jid) $n(name)
        }
        if {[info exists n(nick)]} {
            set bookmarks($xlib,nick,$jid) $n(nick)
        }
        if {[info exists n(password)]} {
            set bookmarks($xlib,password,$jid) $n(password)
        }
        if {[info exists n(autojoin)]} {
            set bookmarks($xlib,autojoin,$jid) $n(autojoin)
        }

        if {![info exists bookmarks($xlib,groups,$jid)]} {
            set bookmarks($xlib,groups,$jid) {}
            set bookmarks($xlib,hasgroups,$jid) 0
        } else {
            set bookmarks($xlib,hasgroups,$jid) 1
        }

        return 1
    }
}

proc conferences::create_muc_bmgroup {xlib xmldata args} {
    variable bookmarks

    set merge 0
    foreach {opt val} $args {
        switch -- $opt {
            -merge { set merge $val }
            default {
                return -code error "Bad option \"$opt\":\
                    must be -merge"
            }
        }
    }

    ::xmpp::xml::split $xmldata tag xmlns attrs cdata subels

    if {![string equal $tag conference]} return

    set jid [::xmpp::jid::normalize [::xmpp::xml::getAttr $attrs jid]]

    set groups [list]
    foreach subel $subels {
        ::xmpp::xml::split $subel stag sxmlns sattrs scdata ssubels
        if {[string equal $stag group]} {
            lappend groups $scdata
        }
    }

    if {$merge && [info exists bookmarks($xlib,jid,$jid)]
                && $bookmarks($xlib,hasgroups,$jid)} {
        return 0
    } else {
        set bookmarks($xlib,groups,$jid) $groups
        set bookmarks($xlib,hasgroups,$jid) 1
        return 1
    }
}

proc conferences::push_bookmarks_to_roster {xlib} {
    variable bookmarks

    foreach idx [array names bookmarks $xlib,jid,*] {
        set jid $bookmarks($idx)
        client:roster_push $xlib $jid \
                           -name $bookmarks($xlib,name,$jid) \
                           -groups $bookmarks($xlib,groups,$jid) \
                           -subscription bookmark
        roster::override_category_and_subtype $xlib $jid conference ""
    }
}

###############################################################################
#
#   Store bookmarks
#

proc conferences::serialize_bookmarks {xlib} {
    variable bookmarks

    set bookmarklist {}
    set grouplist {}
    foreach jid $bookmarks($xlib) {
        set name $bookmarks($xlib,name,$jid)
        set autojoin $bookmarks($xlib,autojoin,$jid)

        set vars [list jid $jid name $name autojoin $autojoin]

        if {$bookmarks($xlib,nick,$jid) != ""} {
            lappend vars nick $bookmarks($xlib,nick,$jid)
        }
        if {$bookmarks($xlib,password,$jid) != ""} {
            lappend vars password $bookmarks($xlib,password,$jid)
        }
        lappend bookmarklist $vars

        set vars [list jid $jid]
        set groups {}
        foreach group $bookmarks($xlib,groups,$jid) {
            lappend groups [::xmpp::xml::create group \
                                    -cdata $group]
        }
        lappend grouplist [::xmpp::xml::create conference \
                                -attrs $vars \
                                -subelements $groups]
    }

    return [list $bookmarklist \
                 [::xmpp::xml::create storage \
                            -xmlns $::NS(tkabber:groups) \
                            -subelements $grouplist]]
}

proc conferences::store_bookmarks {xlib args} {
    set command [list [namespace current]::store_bookmarks_result $xlib]
    foreach {opt val} $args {
        switch -- $opt {
            -command { set command $val }
            default {
                return -code error "Bad option \"$opt\":\
                    must be -command"
            }
        }
    }

    lassign [serialize_bookmarks $xlib] bookmarks groups

    ::xmpp::roster::bookmarks::store $xlib $bookmarks -command $command
    ::xmpp::private::store $xlib [list $groups] -command $command
}

proc conferences::store_bookmarks_result {xlib res child} {
    if {$res == "ok"} return

    if {[winfo exists .store_bookmarks_error]} {
        return
    }

    MessageDlg .store_bookmarks_error -aspect 50000 -icon error \
        -message [::msgcat::mc "Storing conferences failed: %s" \
                         [error_to_string $child]] \
        -type user -buttons ok -default 0 -cancel 0
}

###############################################################################
#
#   Menu item for conference window
#

proc conferences::add_conference_menu_item {m xlib jid} {
    set chatid [chat::chatid $xlib $jid]

    if {[info exists ::muc::muc_password($chatid)]} {
        set password $::muc::muc_password($chatid)
    } else {
        set password ""
    }

    $m add command -label [::msgcat::mc "Add conference to roster..."] \
        -command [list [namespace current]::add_conference_dialog $xlib \
                       -group [::xmpp::jid::node $jid] \
                       -server [::xmpp::jid::server $jid] \
                       -password $password]
}

hook::add chat_create_conference_menu_hook \
    [namespace current]::conferences::add_conference_menu_item 35

###############################################################################
#
#   Add conference to roster dialog
#

proc conferences::add_conference_dialog {xlib args} {
    variable options
    variable gra_group
    variable gra_server
    variable gra_nick
    variable gra_password
    variable gra_autojoin
    variable gra_xlib

    if {[llength [connections]] == 0} return

    set gw .addgroup
    catch { destroy $gw }

    if {$xlib == ""} {
        set xlib [lindex [connections] 0]
    }
    set gra_server conference.[connection_server $xlib]
    set gra_group ""
    set gra_password ""
    set gra_autojoin 0
    catch { unset gra_nick }

    foreach {key val} $args {
        switch -- $key {
            -group { set gra_group $val }
            -server { set gra_server $val }
            -nick { set gra_nick $val }
            -password { set gra_password $val }
            -autojoin { set gra_autojoin $val }
        }
    }

    if {![info exists gra_nick]} {
        set gra_nick [get_group_nick $xlib [::xmpp::jid::jid $gra_group $gra_server]]
    }
    set gra_xlib [connection_jid $xlib]

    Dialog $gw -title [::msgcat::mc "Add Conference to Roster"] -anchor e \
            -default 0 -cancel 1 -modal none

    set gf [$gw getframe]
    grid columnconfigure $gf 0 -weight 0
    grid columnconfigure $gf 1 -weight 1

    Label $gf.lgroup -text [::msgcat::mc "Conference:"]
    Entry $gf.group -textvariable [namespace current]::gra_group
    Label $gf.lserver -text [::msgcat::mc "Server:"]
    Entry $gf.server -textvariable [namespace current]::gra_server
    Label $gf.lnick -text [::msgcat::mc "Nick:"]
    Entry $gf.nick -textvariable [namespace current]::gra_nick
    Label $gf.lpassword -text [::msgcat::mc "Password:"]
    Entry $gf.password -show * -textvariable [namespace current]::gra_password
    Checkbutton $gf.autojoin -text [::msgcat::mc "Automatically join conference upon connect"] \
        -variable [namespace current]::gra_autojoin
    Label $gf.lrostergroup -text [::msgcat::mc "Roster group:"]
    Combobox $gf.rostergroup -textvariable [namespace current]::options(roster_group) \
        -values [get_groups $xlib]

    grid $gf.lgroup  -row 0 -column 0 -sticky e
    grid $gf.group   -row 0 -column 1 -sticky ew
    grid $gf.lserver -row 1 -column 0 -sticky e
    grid $gf.server  -row 1 -column 1 -sticky ew
    grid $gf.lnick -row 2 -column 0 -sticky e
    grid $gf.nick  -row 2 -column 1 -sticky ew
    grid $gf.lpassword -row 3 -column 0 -sticky e
    grid $gf.password  -row 3 -column 1 -sticky ew
    grid $gf.autojoin -row 4 -column 0 -sticky w -columnspan 2
    grid $gf.lrostergroup  -row 5 -column 0 -sticky e
    grid $gf.rostergroup   -row 5 -column 1 -sticky ew

    if {[llength [connections]] > 1} {
        foreach c [connections] {
            lappend connections [connection_jid $c]
        }
        Label $gf.lconnection -text [::msgcat::mc "Connection:"]
        Combobox $gf.connection -textvariable [namespace current]::gra_xlib \
                                -values $connections -editable 0 \
                                -modifycmd [list [namespace current]::change_groups \
                                                 $gf.rostergroup]

        grid $gf.lconnection -row 6 -column 0 -sticky e
        grid $gf.connection  -row 6 -column 1 -sticky ew
    }


    $gw add -text [::msgcat::mc "Add"] -command [list [namespace current]::add_conference $gw]
    $gw add -text [::msgcat::mc "Cancel"] -command [list destroy $gw]

    $gw draw $gf.group
}

proc conferences::change_groups {combo args} {
    variable gra_xlib

    foreach xlib [connections] {
        if {[connection_jid $xlib] == $gra_xlib} {
            $combo configure -values [get_groups $xlib]
            return
        }
    }
}

proc conferences::get_groups {xlib} {
    return [roster::get_groups $xlib \
                -nested $::ifacetk::roster::options(nested) \
                -delimiter $::ifacetk::roster::options(nested_delimiter) \
                -undefined 0]
}

proc conferences::add_conference {gw} {
    variable options
    variable bookmarks
    variable gra_group
    variable gra_server
    variable gra_nick
    variable gra_password
    variable gra_autojoin
    variable gra_xlib

    destroy $gw

    set jid [::xmpp::jid::normalize ${gra_group}@$gra_server]
    if {$options(roster_group) == ""} {
        set groups {}
    } else {
        set groups [list $options(roster_group)]
    }

    foreach c [connections] {
        if {[connection_jid $c] == $gra_xlib} {
            set xlib $c
        }
    }
    if {![info exists xlib]} {
        # Disconnect while dialog is opened
        return
    }

    if {[info exists bookmarks($xlib,jid,$jid)]} {
        update_bookmark $xlib $jid -name $gra_group -nick $gra_nick \
                        -password $gra_password -autojoin $gra_autojoin \
                        -groups $groups
    } else {
        add_bookmark $xlib $jid -name $gra_group -nick $gra_nick \
                     -password $gra_password -autojoin $gra_autojoin \
                     -groups $groups
    }
}

###############################################################################
#
#   Add bookmark to roster
#

proc conferences::add_bookmark {xlib jid args} {
    variable bookmarks

    if {[info exists bookmarks($xlib,jid,$jid)]} return

    foreach {key val} $args {
        switch -- $key {
            -name { set name $val }
            -nick { set nick $val }
            -password { set password $val }
            -autojoin { set autojoin $val }
            -groups { set groups $val }
        }
    }

    if {![info exists name]} {
        set name [::xmpp::jid::node $jid]
    }
    if {![info exists nick]} {
        set nick [get_group_nick $xlib $jid]
    }
    if {![info exists password]} {
        set password ""
    }
    if {![info exists autojoin]} {
        set autojoin 0
    }
    if {![info exists groups]} {
        set groups {}
    }

    if {$jid ni $bookmarks($xlib)} {
        lappend bookmarks($xlib) $jid
    }
    set bookmarks($xlib,jid,$jid) $jid
    set bookmarks($xlib,name,$jid) $name
    set bookmarks($xlib,nick,$jid) $nick
    set bookmarks($xlib,password,$jid) $password
    set bookmarks($xlib,autojoin,$jid) $autojoin
    set bookmarks($xlib,groups,$jid) $groups
    set bookmarks($xlib,hasgroups,$jid) 1

    # TODO should we remove $jid from the roster if it is here?
    client:roster_push $xlib $jid \
                       -name $name \
                       -groups $groups \
                       -subscription bookmark
    roster::override_category_and_subtype $xlib $jid conference ""
    store_bookmarks $xlib
}

###############################################################################
#
#   Update bookmark in roster
#

proc conferences::update_bookmark {xlib jid args} {
    variable bookmarks

    set store 0

    foreach {key val} $args {
        switch -- $key {
            -name { set name $val }
            -nick { set nick $val }
            -password { set password $val }
            -autojoin { set autojoin $val }
            -groups { set groups $val }
        }
    }

    if {[info exists name] && $name != $bookmarks($xlib,name,$jid)} {
        set bookmarks($xlib,name,$jid) $name
        set store 1
    }
    if {[info exists nick] && $nick != $bookmarks($xlib,nick,$jid)} {
        set bookmarks($xlib,nick,$jid) $nick
        set store 1
    }
    if {[info exists password] && $password != $bookmarks($xlib,password,$jid)} {
        set bookmarks($xlib,password,$jid) $password
        set store 1
    }
    if {[info exists autojoin] && $autojoin != $bookmarks($xlib,autojoin,$jid)} {
        set bookmarks($xlib,autojoin,$jid) $autojoin
        set store 1
    }
    if {[info exists groups] && [lsort $groups] != [lsort $bookmarks($xlib,groups,$jid)]} {
        set bookmarks($xlib,groups,$jid) $groups
        set store 1
    }
    if {$store} {
        client:roster_push $xlib $jid \
                           -name $bookmarks($xlib,name,$jid) \
                           -groups $bookmarks($xlib,groups,$jid) \
                           -subscription bookmark
        roster::override_category_and_subtype $xlib $jid conference ""
        store_bookmarks $xlib
    }
}

###############################################################################
#
#   Add or update item in roster
#

proc conferences::send_bookmark {xlib jid} {

    if {[roster::itemconfig $xlib $jid -subsc] != "bookmark"} return

    set groups [roster::itemconfig $xlib $jid -group]

    add_bookmark $xlib $jid -groups $groups
    update_bookmark $xlib $jid -groups $groups

    return stop
}

hook::add roster_send_item_hook [namespace current]::conferences::send_bookmark

###############################################################################
#
#   Remove bookmark from roster
#

proc conferences::remove_bookmark {xlib jid} {
    variable bookmarks

    if {[roster::itemconfig $xlib $jid -subsc] != "bookmark"} return

    if {![info exists bookmarks($xlib,jid,$jid)]} return

    client:roster_push $xlib $jid \
                       -name $bookmarks($xlib,name,$jid) \
                       -groups $bookmarks($xlib,groups,$jid) \
                       -subscription remove

    if {[set idx [lsearch -exact $bookmarks($xlib) $jid]] >= 0} {
        set bookmarks($xlib) [lreplace $bookmarks($xlib) $idx $idx]
    }
    catch { unset bookmarks($xlib,jid,$jid) }
    catch { unset bookmarks($xlib,name,$jid) }
    catch { unset bookmarks($xlib,nick,$jid) }
    catch { unset bookmarks($xlib,password,$jid) }
    catch { unset bookmarks($xlib,autojoin,$jid) }
    catch { unset bookmarks($xlib,groups,$jid) }
    catch { unset bookmarks($xlib,hasgroups,$jid) }

    store_bookmarks $xlib

    return stop
}

hook::add roster_remove_item_hook \
    [namespace current]::conferences::remove_bookmark

###############################################################################
#
#   Rename group in roster bookmarks
#

proc conferences::rename_group {xlib name new_name} {
    variable bookmarks

    set store 0
    foreach idx [array names bookmarks $xlib,jid,*] {
        set jid $bookmarks($idx)

        set groups $bookmarks($xlib,groups,$jid)
        if {$name in $groups || \
                ($name == $::roster::undef_group_name && $groups == {})} {
            set idx [lsearch -exact $groups $name]
            if {$new_name != ""} {
                set groups [lreplace $groups $idx $idx $new_name]
            } else {
                set groups [lreplace $groups $idx $idx]
            }
            set groups [lsort -unique $groups]
            client:roster_push $xlib $jid \
                               -name $bookmarks($xlib,name,$jid) \
                               -groups $groups \
                               -subscription bookmark
            roster::override_category_and_subtype $xlib $jid conference ""
            set bookmarks($xlib,groups,$jid) $groups
            set store 1
        }
    }
    if {$store} {
        store_bookmarks $xlib
    }
}

hook::add roster_rename_group_hook \
    [namespace current]::conferences::rename_group

###############################################################################
#
#   Remove group name from roster bookmarks
#

proc conferences::remove_bookmarks_group {xlib name} {
    variable bookmarks

    set store 0
    foreach idx [array names bookmarks $xlib,jid,*] {
        set jid $bookmarks($idx)

        set groups $bookmarks($xlib,groups,$jid)
        if {$name in $groups || \
                (($name == $::roster::undef_group_name) && ($groups == {}))} {

            client:roster_push $xlib $jid \
                               -name $bookmarks($xlib,name,$jid) \
                               -groups $groups \
                               -subscription remove

            if {[set idx [lsearch -exact $bookmarks($xlib) $jid]] >= 0} {
                set bookmarks($xlib) [lreplace $bookmarks($xlib) $idx $idx]
            }
            catch { unset bookmarks($xlib,jid,$jid) }
            catch { unset bookmarks($xlib,name,$jid) }
            catch { unset bookmarks($xlib,nick,$jid) }
            catch { unset bookmarks($xlib,password,$jid) }
            catch { unset bookmarks($xlib,autojoin,$jid) }
            catch { unset bookmarks($xlib,groups,$jid) }
            catch { unset bookmarks($xlib,hasgroups,$jid) }

            set store 1
        }
    }
    if {$store} {
        store_bookmarks $xlib
    }
}

hook::add roster_remove_users_group_hook \
    [namespace current]::conferences::remove_bookmarks_group

###############################################################################
#
#   Join group on roster item doubleclick
#

proc conferences::join_group {xlib jid} {
    variable bookmarks

    set args {}
    if {$bookmarks($xlib,nick,$jid) != ""} {
        set nick $bookmarks($xlib,nick,$jid)
    } else {
        set nick [get_group_nick $xlib $jid]
    }
    if {$bookmarks($xlib,password,$jid) != ""} {
        set password $bookmarks($xlib,password,$jid)
    } else {
        set password ""
    }
    muc::join_group_raise $xlib $jid $nick $password
}

###############################################################################
#
#   Join group during autojoin
#

proc conferences::autojoin_group {xlib jid} {
    variable bookmarks

    if {$bookmarks($xlib,nick,$jid) != ""} {
        set nick $bookmarks($xlib,nick,$jid)
    } else {
        set nick [get_group_nick $xlib $jid]
    }
    if {$bookmarks($xlib,password,$jid) != ""} {
        set password $bookmarks($xlib,password,$jid)
    } else {
        set password ""
    }
    after 100 [list muc::join_group $xlib $jid $nick $password]
}

###############################################################################
#
#   Autojoin groups
#

proc conferences::autojoin_groups {xlib} {
    variable options
    variable bookmarks

    if {$options(ignore_autojoin)} return

    foreach idx [array names bookmarks $xlib,jid,*] {
        set jid $bookmarks($idx)
        set chatid [chat::chatid $xlib $jid]
        if {$bookmarks($xlib,autojoin,$jid) && ![chat::is_opened $chatid]} {
            autojoin_group $xlib $jid
        }
    }
}

###############################################################################
#
#   "Join" item in roster conference popup menu
#

proc conferences::popup_menu {m xlib jid} {
    variable bookmarks

    set args {}
    if {[roster::itemconfig $xlib $jid -subsc] == "bookmark"} {
        if {$bookmarks($xlib,nick,$jid) != ""} {
            lappend args -nick $bookmarks($xlib,nick,$jid)
        }
        if {$bookmarks($xlib,password,$jid) != ""} {
            lappend args -password $bookmarks($xlib,password,$jid)
        }
    }

    $m add command -label [::msgcat::mc "Join..."] \
        -command [list join_group_dialog $xlib \
                                  -server [::xmpp::jid::server $jid] \
                                  -group [::xmpp::jid::node $jid] \
                                  {*}$args]

    # TODO: Check for real MUC? Move to muc.tcl?
    ::add_muc_menu_items $m $xlib $jid
}

hook::add roster_conference_popup_menu_hook \
    [namespace current]::conferences::popup_menu 20

###############################################################################
#
#   Roster doubleclick
#

proc conferences::roster_doubleclick {xlib jid category subtype} {
    switch -- $category {
        conference {
            if {[roster::itemconfig $xlib $jid -subsc] == "bookmark"} {
                join_group $xlib $jid
            } else {
                muc::join_group_raise $xlib $jid [get_group_nick $xlib $jid]
            }
            return stop
        }
    }
}

hook::add roster_jid_doubleclick \
    [namespace current]::conferences::roster_doubleclick

###############################################################################
#
#   Main menu setup
#

proc conferences::main_menu {} {
    set m [.mainframe getmenu services]
    $m insert 2 command -label [::msgcat::mc "Add conference to roster..."] \
        -command [list [namespace current]::add_conference_dialog ""]
}

hook::add finload_hook [namespace current]::conferences::main_menu

###############################################################################
#
#   Edit roster item
#

proc conferences::edit_item_setup {f xlib jid} {
    variable egra_name
    variable egra_nick
    variable egra_password
    variable egra_autojoin
    variable bookmarks

    if {[roster::itemconfig $xlib $jid -subsc] != "bookmark"} return

    set tf [Labelframe $f.prop \
                -text [::msgcat::mc "Edit properties for %s" $jid] \
                -padding {2m 2m}]
    set slaves [pack slaves $f]
    if {$slaves == ""} {
        pack $tf -side top -expand yes -fill both -pady 1m
    } else {
        pack $tf -side top -expand yes -fill both -pady 1m -before [lindex $slaves 0]
    }
    set g $tf

    set egra_name $bookmarks($xlib,name,$jid)
    set egra_autojoin [string is true -strict $bookmarks($xlib,autojoin,$jid)]
    if {[info exists bookmarks($xlib,nick,$jid)]} {
        set egra_nick $bookmarks($xlib,nick,$jid)
    } else {
        set egra_nick ""
    }
    if {[info exists bookmarks($xlib,password,$jid)]} {
        set egra_password $bookmarks($xlib,password,$jid)
    } else {
        set egra_password ""
    }

    Label $g.lname -text [string trim [::msgcat::mc "Name: "]]
    Entry $g.name -textvariable [namespace current]::egra_name
    Label $g.lnick -text [::msgcat::mc "Nick:"]
    Entry $g.nick -textvariable [namespace current]::egra_nick
    Label $g.lpassword -text [::msgcat::mc "Password:"]
    Entry $g.password -show * -textvariable [namespace current]::egra_password
    Checkbutton $g.autojoin \
        -text [::msgcat::mc "Automatically join conference upon connect"] \
        -variable [namespace current]::egra_autojoin
    grid columnconfigure $g 0 -weight 0
    grid columnconfigure $g 1 -weight 1

    grid $g.lname  -row 0 -column 0 -sticky e
    grid $g.name   -row 0 -column 1 -sticky ew
    grid $g.lnick -row 1 -column 0 -sticky e
    grid $g.nick  -row 1 -column 1 -sticky ew
    grid $g.lpassword -row 2 -column 0 -sticky e
    grid $g.password  -row 2 -column 1 -sticky ew
    grid $g.autojoin -row 3 -column 0 -sticky w -columnspan 2

    return stop
}

hook::add roster_itemedit_setup_hook \
    [namespace current]::conferences::edit_item_setup

proc conferences::commit_bookmark_changes {xlib jid groups} {
    variable egra_name
    variable egra_nick
    variable egra_password
    variable egra_autojoin

    if {[roster::itemconfig $xlib $jid -subsc] != "bookmark"} return

    plugins::conferences::update_bookmark $xlib $jid \
        -name $egra_name -nick $egra_nick -password $egra_password \
        -autojoin $egra_autojoin -groups $groups

    return stop
}

hook::add roster_itemedit_commit_hook \
    [namespace current]::conferences::commit_bookmark_changes

###############################################################################

proc conferences::disco_node_menu_setup {m bw tnode data parentdata} {
    lassign $data type xlib jid node
    lassign $parentdata ptype pxlib pjid pnode
    switch -- $type {
        item -
        item2 {
            set identities [::disco::browser::get_identities $bw $tnode]

            if {[llength $identities] == 0} {
                set identities [::disco::browser::get_parent_identities $bw $tnode]
            }

            # JID with resource is not a room JID
            if {[::xmpp::jid::resource $jid] != ""} return

            foreach id $identities {
                if {[::xmpp::xml::getAttr $id category] == "conference"} {
                    $m add command -label [::msgcat::mc "Add conference to roster..."] \
                        -command [list [namespace current]::add_conference_dialog $xlib \
                                       -group [::xmpp::jid::node $jid] \
                                       -server [::xmpp::jid::server $jid]]
                    break
                }
            }
        }
    }
}

hook::add disco_node_menu_hook \
          [namespace current]::conferences::disco_node_menu_setup 50

# vim:ft=tcl:ts=8:sw=4:sts=4:et
