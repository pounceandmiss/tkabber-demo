# caps.tcl --
#
#       Entity capabilities support (XEP-0115)

package require sha1
package require md5
package require base64

namespace eval caps {
    set ::NS(caps) http://jabber.org/protocol/caps
    variable caps_node ""

    custom::defgroup Plugins \
        [::msgcat::mc "Plugins options."] \
        -group Tkabber

    custom::defgroup Caps \
        [::msgcat::mc "Options for entity capabilities plugin."] \
        -group Plugins

    custom::defvar options(enable) 1 \
        [::msgcat::mc "Enable announcing entity capabilities in\
                       every outgoing presence."] \
        -group Caps -type boolean

    custom::defvar options(hash) sha-1 \
        [::msgcat::mc "Use the specified function to hash supported\
                       features list."] \
        -group Caps -type options -values {md5 MD5 sha-1 SHA-1}
}

proc caps::hash {identities features extras hash} {
    debugmsg caps "$identities; $features; $extras; $hash"

    set binidentities {}
    foreach id $identities {
        set category [::xmpp::xml::getAttr $id category]
        set type [::xmpp::xml::getAttr $id type]
        set lang [::xmpp::xml::getAttr $id xml:lang]
        set name [::xmpp::xml::getAttr $id name]
        lappend binidentities [encoding convertto utf-8 $category/$type/$lang/$name]
    }

    set binfeatures {}
    foreach fe $features {
        lappend binfeatures [encoding convertto utf-8 $fe]
    }

    set binextra {}
    foreach eform $extras {
        set bineform {}
        foreach {etag extra} $eform {
            lassign $extra var type label values
            switch -- $var/$type {
                FORM_TYPE/hidden {
                    set form_type [encoding convertto utf-8 [lindex $values 0]]
                }
                default {
                    set binex {}
                    foreach val $values {
                        lappend binex [encoding convertto utf-8 $val]
                    }
                    lappend bineform \
                            [linsert [lsort -ascii $binex] 0 \
                                     [encoding convertto utf-8 $var]]
                }
            }
        }
        set bineform1 {}
        foreach ex [lsort -ascii -index 0 $bineform] {
            lappend bineform1 [join $ex "<"]
        }
        lappend binextra [linsert $bineform1 0 $form_type]
    }

    set binextra1 {}
    foreach b [lsort -ascii -index 0 $binextra] {
        lappend binextra1 [join $b "<"]
    }

    debugmsg caps "$binidentities; $binfeatures; $binextra1"

    set binstr [join [concat [lsort -ascii $binidentities] \
                             [lsort -ascii $binfeatures] \
                             $binextra1] "<"]

    debugmsg caps "$binstr"

    if {[string equal $binstr ""]} {
        return ""
    }

    append binstr "<"

    switch -- $hash {
        md5 {
            if {[catch {::md5::md5 -hex $binstr} hex]} {
                # Old md5 package.
                set hex [::md5::md5 $binstr]
            }
            set binhash [binary format H32 $hex]
        }
        sha-1 {
            set binhash [binary format H40 [::sha1::sha1 $binstr]]
        }
        default {
            # Unsupported hash type
            return ""
        }
    }
    return [base64::encode $binhash]
}

proc caps::get_presence_x {varname xlib status} {
    variable options
    variable caps_node
    upvar 2 $varname var

    if {!$options(enable)} return

    lassign [disco::info_query_get_handler $xlib "" "" en] \
            status identities features extras

    debugmsg caps "$status; $identities; $features; $extras"

    if {![string equal $status result]} return

    set ver [hash $identities $features $extras $options(hash)]
    if {[string equal $ver ""]} return

    lappend var [::xmpp::xml::create c \
                        -xmlns $::NS(caps) \
                        -attrs [list hash $options(hash) \
                                     node http://tkabber.jabber.ru/ \
                                     ver $ver]]

    set caps_node http://tkabber.jabber.ru/#$ver

    debugmsg caps "$caps_node"

    return
}

hook::add presence_xlist_hook [namespace current]::caps::get_presence_x

proc caps::disco_reply {varname type node xlib from lang} {
    variable caps_node
    upvar 2 $varname res

    if {$type != "info" || $node != $caps_node} return

    set res [disco::info_query_get_handler $xlib "" "" en]

    return stop
}

hook::add disco_node_reply_hook [namespace current]::caps::disco_reply

# TODO match caps hash to a set of features
proc caps::process_presence {xlib from type x args} {
    variable htype
    variable hnode
    variable hver

    switch -- $type {
        unavailable {
            catch {unset htype($xlib,$from)}
            catch {unset hnode($xlib,$from)}
            catch {unset hver($xlib,$from)}
        }
        available {
            foreach xs $x {
                ::xmpp::xml::split $xs tag xmlns attrs cdata subels
                if {[string equal $xmlns $::NS(caps)]} {
                    set htype($xlib,$from) [::xmpp::xml::getAttr $attrs hash]
                    set hnode($xlib,$from) [::xmpp::xml::getAttr $attrs node]
                    set hver($xlib,$from)  [::xmpp::xml::getAttr $attrs ver]
                    return
                }
            }
            # Unset caps if they aren't included in <presence/>
            catch {unset htype($xlib,$from)}
            catch {unset hnode($xlib,$from)}
            catch {unset hver($xlib,$from)}
        }
    }
}

hook::add client_presence_hook [namespace current]::caps::process_presence

proc caps::clean {xlib} {
    variable htype
    variable hnode
    variable hver

    array unset htype $xlib,*
    array unset hnode $xlib,*
    array unset hver $xlib,*
}

hook::add disconnected_hook [namespace current]::caps::clean

proc caps::request_info {xlib jid} {
    variable hnode
    variable hver

    if {![info exists hver($xlib,$jid)] || ![info exists hnode($xlib,$jid)]} {
        after idle [namespace code [list info_receive $xlib $jid error {} {} {}]]
        return
    }

    ::disco::request_info $xlib $jid \
            -node $hnode($xlib,$jid)#$hver($xlib,$jid) \
            -cache yes \
            -command [namespace code [list info_receive $xlib $jid]]
}

proc caps::info_receive {xlib jid status identities features extras} {
    variable hidentities
    variable hfeatures
    variable htype
    variable hnode
    variable hver

    debugmsg caps "$xlib; $jid; $status; $identities; $features; $extras"

    if {![string equal $status ok]} return

    if {![info exists hver($xlib,$jid)] || ![info exists htype($xlib,$jid)]} return

    if {[string equal $htype($xlib,$jid) ""]} {
        debugmsg caps "Legacy caps ver $hver($xlib,$jid) for $jid"

        # TODO: legacy caps support
    } else {
        set hash [hash $identities $features $extras $htype($xlib,$jid)]
        if {![string equal $hash $hver($xlib,$jid)]} {
            debugmsg caps "Mismatched caps ver for $jid, expected $hver($xlib,$jid), calculated $hash"

            # TODO: Treat mismatched ver as legacy one
            return
        }

        debugmsg caps "Caps ver $hash for $jid matches its disco#info"

        set hidentities($htype($xlib,$jid),$hver($xlib,$jid)) $identities
        set hfeatures($htype($xlib,$jid),$hver($xlib,$jid)) $features
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
