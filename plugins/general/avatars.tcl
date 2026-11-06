# avatars.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which implements a historical IQ-Based Avatars (XEP-0008) protocol.

package require base64
package require sha1

namespace eval ::avatar {
    variable options

    set options(announce) 0
    set options(share) 0
}

##############################################################################

proc ::avatar::setup_menu {} {
    catch {
        #set m [.mainframe getmenu services]
        #for {set ind [$m index end]} {$ind > 0} {incr ind -1} {
        #    if {[$m type $ind] == "separator"} {
        #        break
        #    }
        #}
        set m [.mainframe getmenu plugins]

        set mm .avatar_menu
        menu $mm -tearoff $::ifacetk::options(show_tearoffs)
        $mm add checkbutton -label [::msgcat::mc "Announce"] \
            -variable avatar::options(announce)
        $mm add checkbutton -label [::msgcat::mc "Allow downloading"] \
            -variable avatar::options(share)
        $mm add command -label [::msgcat::mc "Send to server"] \
            -command {avatar::store_on_server}

        $m add cascade -label [::msgcat::mc "Avatar"] \
            -menu $mm
    }
}

hook::add finload_hook ::avatar::setup_menu

##############################################################################

proc ::avatar::load_file {filename} {
    variable avatar
    variable options

    create_image user_avatar -file $filename
    set f [open $filename]
    fconfigure $f -translation binary
    set data [read $f]
    close $f

    set avatar(userhash) [sha1::sha1 $data]
    set avatar(userdata) [base64::encode $data]

    set options(announce) 1
    set options(share) 1
}

##############################################################################

proc ::avatar::get_presence_x {varname xlib status} {
    variable avatar
    variable options
    upvar 2 $varname var

    if {$options(announce) && [info exists avatar(userhash)]} {
        lappend var [::xmpp::xml::create x \
                         -xmlns $::NS(xavatar) \
                         -subelement [::xmpp::xml::create hash \
                                            -cdata $avatar(userhash)]]

    }
    return
}

hook::add presence_xlist_hook ::avatar::get_presence_x

##############################################################################

proc ::avatar::process_presence {xlib from type x args} {
    switch -- $type {
        available -
        unavailable {
            foreach xs $x {
                ::xmpp::xml::split $xs tag xmlns attrs cdata subels
                if {$xmlns == $::NS(xavatar)} {
                    set_hash $xlib $from $subels
                    break
                }
            }
        }
    }
}

hook::add client_presence_hook ::avatar::process_presence

##############################################################################

proc ::avatar::insert_userinfo {tab xlib jid editable} {
    if {$editable} return

    set avatar_img [get_image $xlib [get_jid_of_user $xlib $jid]]
    if {$avatar_img != ""} {
        set avatar [$tab insert end avatar -text [::msgcat::mc "Avatar"]]

        set av [userinfo::pack_frame $avatar.avatar [::msgcat::mc "Avatar"]]
        Label $av.a -image $avatar_img
        pack $av.a -expand yes -fill both
    }
}

hook::add userinfo_hook ::avatar::insert_userinfo 40

##############################################################################

proc ::avatar::set_hash {xlib jid children} {
    variable avatar

    debugmsg avatar "set hash $xlib $jid $children"
    foreach child $children {
        ::xmpp::xml::split $child tag xmlns attrs cdata subels
        if {$tag == "hash"} {
            set hash $cdata
        }
    }
    if {[info exists hash]} {
        if {![info exists avatar(hash,$xlib,$jid)] || \
                $hash != $avatar(hash,$xlib,$jid)} {
            set avatar(hash,$xlib,$jid) $hash
            set avatar(needupdate,$xlib,$jid) 1
        }
    }
}

##############################################################################

proc ::avatar::get_image {xlib jid} {
    variable avatar

    debugmsg avatar "$jid; [array name avatar]"
    if {[info exists avatar(hash,$xlib,$jid)]} {
        if {![info exists avatar(data,$xlib,$jid)]} {
            image create photo avatar$xlib@$jid
            get $xlib $jid
        } elseif {$avatar(needupdate,$xlib,$jid)} {
            get $xlib $jid
        }
        return avatar$xlib@$jid
    } else {
        return ""
    }
}

##############################################################################

proc ::avatar::get {xlib jid} {
    variable avatar

    set avatar(needupdate,$xlib,$jid) 0

    ::xmpp::sendIQ $xlib get \
        -query [::xmpp::xml::create query \
                        -xmlns $::NS(iqavatar)] \
        -to $jid -command [list avatar::recv $xlib $jid]
}

proc ::avatar::recv {xlib jid res child} {
    variable avatar

    if {![string equal $res ok]} {
        ::xmpp::sendIQ $xlib get \
            -query [::xmpp::xml::create query \
                               -xmlns storage:client:avatar] \
            -to [::xmpp::jid::removeResource $jid] \
            -command [list avatar::recv_from_serv $xlib $jid]

        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels
    foreach subel $subels {
        ::xmpp::xml::split $subel stag sxmlns sattrs scdata ssubels
        if {$stag == "data"} {
            catch {
                set avatar(data,$xlib,$jid) [base64::decode $scdata]
                create_image avatar$xlib@$jid -data $avatar(data,$xlib,$jid)
            }
        }
    }
}

proc ::avatar::recv_from_serv {xlib jid res child} {
    variable avatar

    if {![string equal $res ok]} {
        # TODO
        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels
    foreach subel $subels {
        ::xmpp::xml::split $subel stag sxmlns sattrs scdata ssubels
        if {$stag == "data"} {
            catch {
                set avatar(data,$xlib,$jid) [base64::decode $scdata]
                avatar$xlib@$jid put $scdata
            }
        }
    }
}

##############################################################################

proc ::avatar::store_on_server {{xlib ""}} {
    variable avatar

    if {[llength [connections]] == 0} return

    if {$xlib == ""} {
        set xlib [lindex [connections] 0]
    }

    if {![info exists avatar(userdata)]} {
        MessageDlg .avatar_error -aspect 50000 -icon error \
                -message [::msgcat::mc "No avatar to store"] -type user \
                -buttons ok -default 0 -cancel 0
        return
    }

    ::xmpp::sendIQ $xlib set \
        -query [::xmpp::xml::create query \
                        -xmlns storage:client:avatar \
                        -subelement [::xmpp::xml::create data \
                                            -cdata $avatar(userdata)]]
}

##############################################################################

proc ::avatar::iq_reply {xlib from child args} {
    variable avatar
    variable options

    if {$options(share) && [info exists avatar(userdata)]} {
        set res [::xmpp::xml::create query \
                        -xmlns $::NS(iqavatar) \
                        -subelement [::xmpp::xml::create data \
                                            -cdata $avatar(userdata)]]
        return [list result $res]
    } else {
        return [list error cancel service-unavailable]
    }
}

::xmpp::iq::register get query $::NS(iqavatar) ::avatar::iq_reply

# vim:ft=tcl:ts=8:sw=4:sts=4:et
