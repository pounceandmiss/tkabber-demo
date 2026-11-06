# iface.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements a few
#       procedures which are used in Tkabber's user interface.

set user_status_list [list \
    available   [::msgcat::mc "Available"] \
    chat        [::msgcat::mc "Free to chat"] \
    away        [::msgcat::mc "Away"] \
    xa          [::msgcat::mc "Extended away"] \
    dnd         [::msgcat::mc "Do not disturb"] \
    invisible   [::msgcat::mc "Invisible"] \
    unavailable [::msgcat::mc "Not logged in"]]

array set ssl_certificate_fields [list \
    subject   [::msgcat::mc "Subject"] \
    issuer    [::msgcat::mc "Issuer"] \
    notBefore [::msgcat::mc "Begin date"] \
    notAfter  [::msgcat::mc "Expiry date"] \
    serial    [::msgcat::mc "Serial number"] \
    cipher    [::msgcat::mc "Cipher"] \
    sbits     [::msgcat::mc "Session key bits"] \
    sha1_hash [::msgcat::mc "SHA1 hash"]]

proc update_tls_info {xlib args} {
    global tls_info

    catch {unset tls_info($xlib)}
    if {[llength $args] > 0} {
        set tls_info($xlib) $args
    }
}

hook::add disconnected_hook update_tls_info

proc ssl_info {} {
    global ssl_certificate_fields
    global tls_info

    set server_list {}
    set msg_list {}
    foreach xlib [connections] {
        if {[info exists tls_info($xlib)]} {
            set server [connection_server $xlib]
            if {$server in $server_list} {
                continue
            } else {
                lappend server_list $server
                lappend msg_list $server
            }
            set info {}
            foreach {k v} $tls_info($xlib) {
                switch -- $k {
                    subject -
                    issuer {
                        set v [regsub -all {\s*[/,]\s*(\w+=)} $v \n\t\\1]
                    }
                }
                if {![string equal $v ""]} {
                    if {[info exists ssl_certificate_fields($k)]} {
                        append info [format "%s: %s\n" \
                                            $ssl_certificate_fields($k) $v]
                    } else {
                        append info [format "%s: %s\n" $k $v]
                    }
                }
            }
            lappend msg_list [string trim $info]
        }
    }
    return $msg_list
}

proc update_ssl_info {} {
    global tls_warning_info
    global tls_info

    set state disabled
    set len [llength [connections]]
    set fg normal
    if {$len} {
        set balloon ""
        foreach xlib [connections] {
            if {$len > 1} {
                append balloon "[connection_jid $xlib]: "
            }
            if {[info exists tls_info($xlib)]} {
                if {![info exists tls_warning_info($xlib)] ||
                        [string equal $tls_warning_info($xlib) ""]} {
                    append balloon [::msgcat::mc "Enabled\n"]
                } else {
                    append balloon $tls_warning_info($xlib)
                    set fg warning
                }
                set state normal
            } else {
                append balloon [::msgcat::mc "Disabled\n"]
            }
        }
    } else {
        set balloon [::msgcat::mc "Disconnected"]
    }
    return [list $state $fg [string trim $balloon]]
}

###############################################################################

set status_afterid ""

proc client:status {xlib text} {
    set_status $text
}

proc set_status {text} {
    global status
    global status_afterid

    after cancel $status_afterid
    set status $text

    hook::run set_status_hook $text

    set status_afterid [after 5000 clear_status]
}

proc clear_status {} {
    global status

    set status ""

    hook::run clear_status_hook
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
