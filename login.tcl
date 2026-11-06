# login.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements the
#       login logic and options.

package require xmpp::dns
package require xmpp::auth
package require xmpp::register

if {[catch {package require xmpp::starttls}]} {
    set use_tls 0
} else {
    set use_tls 1
}

if {[catch {package require xmpp::compress}]} {
    set have_compress 0
} else {
    set have_compress 1
}

if {[catch {package require xmpp::sasl}]} {
    set have_sasl 0
} else {
    set have_sasl 1
}

if {[catch {package require xmpp::transport::bosh}]} {
    set have_bosh 0
} else {
    set have_bosh 1
}

if {[catch {package require xmpp::transport::poll}]} {
    set have_http_poll 0
} else {
    set have_http_poll 1
}

custom::defgroup Warnings [::msgcat::mc "Warning display options."] \
    -group Tkabber

if {$use_tls} {
    custom::defvar tls_warnings 1 [::msgcat::mc "Display SSL warnings."] \
        -group Warnings -type boolean
}

custom::defgroup Login \
    [::msgcat::mc "Login options."] \
    -group Tkabber

custom::defvar autologin 0 \
    [::msgcat::mc "Whether to automatically login to server or\
                   show the login window."] \
    -group Login -type options \
    -values [list 0  [::msgcat::mc "Show the login window"] \
                  1  [::msgcat::mc "Autologin to the server"] \
                  -1 [::msgcat::mc "Don't show the login window"]]

custom::defvar loginconf(user) "" \
    [::msgcat::mc "User name."] \
    -group Login -type string
custom::defvar loginconf(server) "localhost" \
    [::msgcat::mc "Server name."] \
    -group Login -type string
custom::defvar loginconf(password) "" \
    [::msgcat::mc "Password."] \
    -group Login -type password
custom::defvar loginconf(resource) "tkabber" \
    [::msgcat::mc "Resource."] \
    -group Login -type string
custom::defvar loginconf(priority) "8" \
    [::msgcat::mc "Priority."] \
    -group Login -type integer

custom::defvar loginconf(connect_forever) 0 \
    [::msgcat::mc "Retry to connect forever."] \
    -group Login -type boolean

# the default sequence goes: 15s, 30s, 1min, 2min, 4min, 8min,
# 16min, 32min, 32min...
custom::defvar loginconf(max_reconnect_interval) 32 \
    [::msgcat::mc "Maximum time interval between unsuccessful connection\
                   retries to the server (in minutes)."] \
    -group Login -type integer

custom::defvar loginconf(allowauthplain) 0 \
    [::msgcat::mc "Allow plaintext authentication mechanisms (when password\
                   is transmitted unencrypted)."] \
        -group Login -type boolean

if {$have_sasl} {
    custom::defvar loginconf(usesasl) 1 \
        [::msgcat::mc "Use SASL authentication."] \
        -group Login -type boolean

    custom::defvar loginconf(allowauthscram) 1 \
        [::msgcat::mc "Allow SCRAM authentication mechanisms (can slow down\
                       login significantly)."] \
            -group Login -type boolean
}

set values [list plaintext [::msgcat::mc "Plaintext"]]
if {$have_compress} {
    lappend values compressed [::msgcat::mc "Compression"]
}
if {$use_tls} {
    lappend values encrypted [::msgcat::mc "Encryption (STARTTLS)"] \
                   ssl       [::msgcat::mc "Encryption (legacy SSL)"]
}

if {$use_tls || $have_compress} {
    custom::defvar loginconf(stream_options) plaintext \
        [::msgcat::mc "XMPP stream options when connecting to server."] \
        -group Login -type options \
        -values $values
}

if {$use_tls} {
    custom::defvar loginconf(sslcertfile) "" \
        [::msgcat::mc "SSL client certificate file bundled with private\
                       key (optional)."] \
        -group Login -type file
    custom::defvar loginconf(sslcacertstore) \
        [expr {$tcl_platform(platform) eq "unix" &&
               [file exists /etc/ssl/certs]? "/etc/ssl/certs" : ""}] \
        [::msgcat::mc "SSL certification authority file or\
                       directory (optional)."] \
        -group Login -type file
}

custom::defvar loginconf(usealtserver) 0 \
    [::msgcat::mc "Use explicitly-specified server address and port."] \
    -group Login -type boolean
custom::defvar loginconf(altserver) "" \
    [::msgcat::mc "Server name or IP-address."] \
    -group Login -type string
custom::defvar loginconf(altport) "5222" \
    [::msgcat::mc "Server port."] \
    -group Login -type integer

custom::defvar loginconf(replace_opened) 1 \
    [::msgcat::mc "Replace opened connections."] \
    -group Login -type boolean

custom::defvar loginconf(stream_management) 1 \
    [::msgcat::mc "Use stream management protocol to acknowledge any stanza\
                   received from and sent to the server."] \
    -group Login -type boolean

if {$have_bosh} {
    custom::defvar loginconf(usebosh) 0 \
        [::msgcat::mc "Use BOSH connection method."] \
        -group Login -type boolean
    custom::defvar loginconf(boshurl) "" \
        [::msgcat::mc "URL to connect to using BOSH."] \
        -group Login -type string
    custom::defvar loginconf(useboshkeys) 1 \
        [::msgcat::mc "Use BOSH client security keys (recommended)."] \
        -group Login -type boolean
    custom::defvar loginconf(numberofboshkeys) 100 \
        [::msgcat::mc "Number of BOSH client security keys to send\
                       before creating new key sequence."] \
        -group Login -type integer
    custom::defvar loginconf(boshtimeout) 0 \
        [::msgcat::mc "Timeout for waiting for BOSH responses (if set\
                       to zero, Tkabber will wait forever)."] \
        -group Login -type integer
    custom::defvar loginconf(boshwait) 30000 \
        [::msgcat::mc "Interval server can wait before responding to BOSH\
                       request (in milliseconds)."] \
        -group Login -type integer
    custom::defvar loginconf(boshhold) 1 \
        [::msgcat::mc "Maximum number of requests the connection manager is\
                       allowed to keep waiting at any time."] \
        -group Login -type integer
}

if {$have_http_poll} {
    custom::defvar loginconf(usehttppoll) 0 \
        [::msgcat::mc "Use HTTP poll connection method."] \
        -group Login -type boolean
    custom::defvar loginconf(pollurl) "" \
        [::msgcat::mc "URL to connect to."] \
        -group Login -type string
    custom::defvar loginconf(usepollkeys) 1 \
        [::msgcat::mc "Use HTTP poll client security keys (recommended)."] \
        -group Login -type boolean
    custom::defvar loginconf(numberofpollkeys) 100 \
        [::msgcat::mc "Number of HTTP poll client security keys to send\
                       before creating new key sequence."] \
        -group Login -type integer
    custom::defvar loginconf(polltimeout) 0 \
        [::msgcat::mc "Timeout for waiting for HTTP poll responses (if set\
                       to zero, Tkabber will wait forever)."] \
        -group Login -type integer
    custom::defvar loginconf(pollmin) 6000 \
        [::msgcat::mc "Minimum poll interval."] \
        -group Login -type integer
    custom::defvar loginconf(pollmax) 60000 \
        [::msgcat::mc "Maximum poll interval."] \
        -group Login -type integer
}

custom::defvar reasonlist {} [::msgcat::mc "List of logout reasons."] \
        -group Hidden

######################################################################

# connect errors mapping

array set connect_error [list \
        err_unknown [::msgcat::mc "Unknown error"] \
        timeout [::msgcat::mc "Timeout"] \
        network-failure [::msgcat::mc "Network failure"] \
        err_authorization_required \
                [::msgcat::mc "Proxy authentication required"] \
        err_version [::msgcat::mc "Incorrect SOCKS version"] \
        err_unsupported_method [::msgcat::mc "Unsupported SOCKS method"] \
        err_authentication_unsupported \
                [::msgcat::mc "Unsupported SOCKS authentication method"] \
        err_authorization [::msgcat::mc "SOCKS authentication failed"] \
        rsp_failure [::msgcat::mc "SOCKS request failed"] \
        rsp_errconnect \
                [::msgcat::mc "SOCKS server cannot identify username"] \
        rsp_erruserid \
                [::msgcat::mc "SOCKS server username identification failed"] \
        rsp_notallowed \
                [::msgcat::mc "SOCKS connection not allowed by ruleset"] \
        rsp_netunreachable [::msgcat::mc "Network unreachable"] \
        rsp_hostunreachable [::msgcat::mc "Host unreachable"] \
        rsp_refused [::msgcat::mc "Connection refused by destination host"] \
        rsp_expired [::msgcat::mc "TTL expired"] \
        rsp_cmdunsupported [::msgcat::mc "SOCKS command not supported"] \
        rsp_addrunsupported \
                [::msgcat::mc "Address type not supported by SOCKS proxy"] \
        err_unknown_address_type [::msgcat::mc "Unknown address type"]]

# TLS info
#
# [::msgcat::mc "Certificate has expired"]
# [::msgcat::mc "Self signed certificate"]

######################################################################

if {![info exists connections]} {
    set connections {}
}

proc connections {{all 0}} {
    global connections

    set res {}
    foreach c $connections {
        if {$all || [lindex $c 1]} {
            lappend res [lindex $c 0]
        }
    }
    return $res
}

proc add_to_connection {active xlib} {
    global connections

    set idx [lsearch -exact $connections [list $xlib 0]]
    set connections [lreplace $connections $idx $idx]
    set idx [lsearch -exact $connections [list $xlib 1]]
    set connections [lreplace $connections $idx $idx]
    lappend connections [list $xlib $active]
}

hook::add connected_hook [list add_to_connection 1] 1

proc remove_from_connection {xlib} {
    global connections

    set idx [lsearch -exact $connections [list $xlib 0]]
    set connections [lreplace $connections $idx $idx]
    set idx [lsearch -exact $connections [list $xlib 1]]
    set connections [lreplace $connections $idx $idx]
}

hook::add disconnected_hook remove_from_connection 1

proc connection_jid {xlib} {
    global connjid
    return $connjid($xlib)
}

proc connection_bare_jid {xlib} {
    global connjid
    return [::xmpp::jid::removeResource $connjid($xlib)]
}

proc connection_user {xlib} {
    global connjid
    return [::xmpp::jid::node $connjid($xlib)]
}

proc connection_server {xlib} {
    global connjid
    return [::xmpp::jid::server $connjid($xlib)]
}

proc connection_resource {xlib} {
    global connjid
    return [::xmpp::jid::resource $connjid($xlib)]
}

proc connection_requested_jid {xlib} {
    global connrjid
    return $connrjid($xlib)
}

proc connection_requested_user {xlib} {
    global connrjid
    return [::xmpp::jid::node $connrjid($xlib)]
}

proc connection_requested_server {xlib} {
    global connrjid
    return [::xmpp::jid::server $connrjid($xlib)]
}

proc connection_requested_resource {xlib} {
    global connrjid
    return [::xmpp::jid::resource $connrjid($xlib)]
}

######################################################################

proc login {logindata} {
    global login_after_id

    array set lc $logindata

    set jid [::xmpp::jid::normalize [::xmpp::jid::jid $lc(user) \
                                                      $lc(server) \
                                                      $lc(resource)]]
    set lc(jid) $jid
    set logindata [array get lc]

    if {[info exists login_after_id($jid)]} {
        after cancel $login_after_id($jid)
        unset login_after_id($jid)
    }

    login_log $jid ok [::msgcat::mc "Starting login"]

    debugmsg login "Starting login ($jid)"
    set_status [::msgcat::mc "Connecting to %s" $lc(server)]

    login_connect $logindata
}

proc login_connected {xlib logindata status msg} {
    global connect_error
    global login_after_time

    array set lc $logindata

    switch -- $status {
        ok {
            # OK, connected.
            add_to_connection 0 $xlib
            debugmsg login "Connect successful $xlib"

            set login_after_time 7500
            login_login $xlib $logindata
        }
        abort {
            # TODO
            debugmsg login "Connect aborted: $xlib $msg"
            login_log $lc(jid) abort $msg
        }
        default {
            # Nasty thing has happened.
            # $msg contains error message here.
            debugmsg login "Failed to connect: $xlib $status $msg"
            login_log $lc(jid) $status $msg

            if {$lc(connect_forever)} {
                login_retry $logindata
            } else {
                if {[winfo exists .connect_err]} {
                    destroy .connect_err
                }
                if {[info exists connect_error($msg)]} {
                    set msg $connect_error($msg)
                }
                set res [MessageDlg .connect_err -width 600 -icon error \
                    -message [::msgcat::mc "Failed to connect: %s" $msg] \
                    -type user \
                    -buttons [list abort [::msgcat::mc "Keep trying"]] \
                    -default 0 -cancel 0]
                if {$res} {
                    set lc(connect_forever) 1
                    set logindata [array get lc]
                    login_retry $logindata
                }
            }
        }
    }
}

proc login_retry {logindata} {
    global login_after_time
    global login_after_id

    array set lc $logindata

    if {![info exists login_after_time]} {
        set login_after_time 7500
    }
    if {$login_after_time == 7500 || \
            $login_after_time < $lc(max_reconnect_interval) * 60 * 1000} {
        # the default sequence goes: 15s, 30s, 1min, 2min, 4min, 8min,
        # 16min, 32min, 32min...
        set login_after_time \
            [expr {min($login_after_time * 2, $lc(max_reconnect_interval) * 60 * 1000)}]
    }
    array set lc $logindata
    set jid $lc(jid)

    debugmsg login "Scheduling connect retry for $jid in ${login_after_time}ms"
    if {[info exists login_after_id($jid)]} {
        after cancel $login_after_id($jid)
        unset login_after_id($jid)
    }
    login_retry1 $login_after_time $jid $logindata
}

proc login_retry1 {interval jid logindata} {
    global login_after_id

    incr interval -1000

    if {$interval <= 0} {
        login $logindata
    } else {
        set login_after_id($jid) \
            [after 1000 [list login_retry1 $interval $jid $logindata]]
        set_status [::msgcat::mc "Login retry for %s in %s" $jid \
                                 [format_time [expr {$interval/1000}]]]
    }
}

proc client:tls_callback {xlib args} {
    global tls_result tls_warnings
    global ssl_certificate_fields
    global tls_warning_info

    switch -- [lindex $args 0] {
        info {
            set_status [lindex $args 4]
        }

        verify {
            if {[lindex $args 4]} {
                return 1
            }
            if {[set reason [lindex $args 5]] eq ""} {
                return 1
            }
            set info [::msgcat::mc [string totitle $reason 0 0]]
            append tls_warning_info($xlib) "$info\n"
            if {!$tls_warnings} {
                return 1
            }
            append info [::msgcat::mc ". Proceed?\n\n"]
            foreach {k v} [lindex $args 3] {
                switch -- $k {
                    subject - issuer {
                        set v [regsub -all {\s*[/,]\s*(\w+=)} $v \n\t\\1]
                    }
                }
                if {$v ne ""} {
                    if {[info exists ssl_certificate_fields($k)]} {
                        append info [format "%s: %s\n" \
                                            $ssl_certificate_fields($k) $v]
                    } else {
                        append info [format "%s: %s\n" $k $v]
                    }
                }
            }

            set blocking [fconfigure [set fd [lindex $args 1]] -blocking]
            fconfigure $fd -blocking 1
            set readable [fileevent $fd readable]
            fileevent $fd readable {}

            set w .tls_callback
            Dialog $w -modal local -anchor e -default 1 -cancel 1 -parent .
            $w add -text [::msgcat::mc Yes] -command [list $w enddialog 0]
            $w add -text [::msgcat::mc No] -command [list $w enddialog 1]

            set f [$w getframe]
            set sw [ScrolledWindow $w.sw -scrollbar both]
            pack $sw -side top -expand yes -fill both -in $f -pady 1m -padx 1m

            set msg [text $w.message]
            $msg insert 0.0 [string trim $info]
            $sw setwidget $msg

            set res [$w draw]

            fileevent $fd readable $readable
            fconfigure $fd -blocking $blocking

            if {$res == 0} {
                return 1
            } else {
                return 0
            }
        }

        error {
            set tls_result [join [lrange $args 2 end] " "]
        }

        default {
        }
    }
}

proc create_xlib {jid} {
    global connhist connrjid connjid

    set njid [::xmpp::jid::normalize $jid]
    if {[info exists connhist($njid)] && $connhist($njid) ni [connections]} {
        set xlib $connhist($njid)
    } else {
        set xlib [::xmpp::new -messagecommand    client:message    \
                              -presencecommand   client:presence   \
                              -iqcommand         client:iq         \
                              -disconnectcommand client:disconnect \
                              -statuscommand     client:status     \
                              -errorcommand      client:error      \
                              -logcommand        client:log]
    }

    if {![info exists connhist($njid)]} {
        set connhist($njid) $xlib
    }

    set connrjid($xlib) $jid
    set connjid($xlib) $jid

    disco::new $xlib

    return $xlib
}

proc login_connect {logindata} {
    global use_tls have_compress have_sasl have_bosh have_http_poll
    global tls_warning_info
    global reconnect

    array set lc $logindata

    set jid [::xmpp::jid::jid $lc(user) \
                              $lc(server) \
                              $lc(resource)]

    set xlib [create_xlib $jid]

    set tls_warning_info($xlib) ""
    set reconnect($xlib) 0

    set ascii_server [idna::domain_toascii $lc(server)]

    set args {-proxyfilter ::proxy::proxyfilter}

    if {$have_bosh && $lc(usebosh)} {
        if {$lc(boshurl) != ""} {
            set url $lc(boshurl)
        } else {
            # TODO: Asynchronous DNS resolution
            if {[catch {::xmpp::dns::resolveBOSH $ascii_server} urls]} {
                set urls {}
            }
            if {[llength $urls] == 0} {
                set url ""
            } else {
                set url [lindex $urls 0]
            }
        }

        set transport bosh
        lappend args -transport bosh \
                     -timeout   $lc(boshtimeout) \
                     -wait      $lc(boshwait) \
                     -hold      $lc(boshhold) \
                     -url       $url \
                     -usekeys   $lc(useboshkeys) \
                     -numkeys   $lc(numberofboshkeys) \

        ::xmpp::connect $xlib -command [list login_connect_result $xlib \
                                             {} $logindata $args] \
                        {*}$args
    } elseif {$have_http_poll && $lc(usehttppoll)} {
        if {$lc(pollurl) != ""} {
            set url $lc(pollurl)
        } else {
            # TODO: Asynchronous DNS resolution
            if {[catch {::xmpp::dns::resolveHTTPPoll $ascii_server} urls]} {
                set urls {}
            }
            if {[llength $urls] == 0} {
                set url ""
            } else {
                set url [lindex $urls 0]
            }
        }

        set transport poll
        lappend args -transport poll \
                     -timeout   $lc(polltimeout) \
                     -int       $lc(pollmin) \
                     -min       $lc(pollmin) \
                     -max       $lc(pollmax) \
                     -url       $url \
                     -usekeys   $lc(usepollkeys) \
                     -numkeys   $lc(numberofpollkeys) \

        ::xmpp::connect $xlib -command [list login_connect_result $xlib \
                                             {} $logindata $args] \
                        {*}$args
    } else {
        if {$lc(usealtserver)} {
            set hosts {}
        } else {
            # TODO: Asynchronous DNS resolution
            if {[catch {::xmpp::dns::resolveXMPPClient $ascii_server} hosts]} {
                set hosts {}
            }
            if {[llength $hosts] == 0} {
                set hosts [list [list $ascii_server 5222]]
            }
        }
        set transport tcp
        if {$use_tls && $lc(stream_options) == "ssl"} {
            set transport tls
            # Do some heuristic.
            # Traditionally legacy SSL port is 5223,
            # so let's add 1 to all ports from SRV reply
            set hosts1 {}
            foreach hp $hosts {
                lassign $hp host port
                lappend hosts1 [list $host [incr port]]
            }
            set hosts $hosts1
            if {![catch ::tls::ciphers tls1.1]} {
                lappend args -tls1.1 1
            }
            if {![catch ::tls::ciphers tls1.2]} {
                lappend args -tls1.2 1
            }
            if {$lc(sslcertfile) ne ""} {
                lappend args -certfile $lc(sslcertfile)
            }
            if {$lc(sslcacertstore) ne ""} {
                lappend args -castore $lc(sslcacertstore)
            }
            lappend args -tls1          1 \
                         -verifycommand [list client:tls_callback $xlib] \
                         -infocommand   [list update_tls_info $xlib]
        }

        lappend args -transport $transport

        if {$lc(usealtserver)} {
            set hosts [list [list [idna::domain_toascii $lc(altserver)] \
                            $lc(altport)]]
        }

        set hosts [lassign $hosts hp]
        lassign $hp host port

        global xmppTransport
        set xmppTransport($xlib) $transport

        ::xmpp::connect $xlib $host $port \
                        -command [list login_connect_result $xlib \
                                       $hosts $logindata $args] \
                        {*}$args
    }
}

proc login_connect_result {xlib hosts logindata args status msg} {
    if {$status == "ok" || $status == "abort" || [llength $hosts] == 0} {
        login_connected $xlib $logindata $status $msg
    } else {
        set hosts [lassign $hosts hp]
        lassign $hp host port

        ::xmpp::connect $xlib $host $port \
                        -command [list login_connect_result $xlib \
                                       $hosts $logindata $args] \
                        {*}$args
    }
}

########################################################################

proc login_login {xlib logindata} {
    global use_tls have_compress have_sasl
    global loginconf_hist

    set loginconf_hist($xlib) $logindata

    array set lc $logindata

    if {($use_tls && $lc(stream_options) == "encrypted") || \
            ($have_compress && $lc(stream_options) == "compressed") || \
            ($have_sasl && $lc(usesasl)) || \
            $lc(stream_management)} {
        ::xmpp::openStream $xlib $lc(server) \
                           -from [::xmpp::jid::jid $lc(user) $lc(server)] \
                           -version 1.0 \
                           -command [list login_login1 $xlib $logindata]
    } else {
        ::xmpp::openStream $xlib $lc(server) \
                           -from [::xmpp::jid::jid $lc(user) $lc(server)] \
                           -command [list login_login1 $xlib $logindata]
    }
}

proc login_login1 {xlib logindata status sessionid} {
    global use_tls have_compress

    if {$status != "ok"} {
        recv_auth_result $xlib $logindata $status $sessionid
        return
    }

    array set lc $logindata

    if {!$lc(usebosh) && !$lc(usehttppoll) && \
            $use_tls && $lc(stream_options) == "encrypted"} {
        set opts {}
        if {![catch ::tls::ciphers tls1.1]} {
            lappend opts -tls1.1 1
        }
        if {![catch ::tls::ciphers tls1.2]} {
            lappend opts -tls1.2 1
        }
        if {$lc(sslcertfile) ne ""} {
            lappend opts -certfile $lc(sslcertfile)
        }
        if {$lc(sslcacertstore) ne ""} {
            lappend opts -castore $lc(sslcacertstore)
        }
        ::xmpp::starttls::starttls $xlib {*}$opts \
                        -command       [list login_login2 $xlib $logindata] \
                        -tls1          1 \
                        -verifycommand [list client:tls_callback $xlib] \
                        -infocommand   [list update_tls_info $xlib]
    } elseif {!$lc(usebosh) && !$lc(usehttppoll) && \
            $have_compress && $lc(stream_options) == "compressed"} {
        ::xmpp::compress::compress $xlib \
                        -command     [list login_login2 $xlib $logindata]
    } else {
        login_login2 $xlib $logindata $status $sessionid
    }
}

proc login_login2 {xlib logindata status sessionid} {
    global have_sasl

    if {$status ne "ok"} {
        recv_auth_result $xlib $logindata $status $sessionid
        return
    }

    array set lc $logindata

    if {$lc(allowauthplain)} {
        set digest auto
    } else {
        set digest true
    }

    # Disable the X-GOOGLE-TOKEN SASL mechanism because it doesn't work anymore

    set disable {X-GOOGLE-TOKEN}

    if {!$lc(allowauthscram)} {
        lappend disable SCRAM-SHA-512-PLUS \
                        SCRAM-SHA-512 \
                        SCRAM-SHA-256-PLUS \
                        SCRAM-SHA-256 \
                        SCRAM-SHA-1-PLUS \
                        SCRAM-SHA-1
    }

    if {$lc(stream_management)} {
        set sm enable
    } else {
        set sm disable
    }

    if {$have_sasl && $lc(usesasl)} {
        # SASL authentication
        ::xmpp::sasl::auth $xlib -username $lc(user) \
                                 -password $lc(password) \
                                 -resource $lc(resource) \
                                 -digest   $digest \
                                 -disable  $disable \
                                 -sm       $sm \
                                 -command  [list recv_auth_result $xlib \
                                                                 $logindata]
    } else {
        # Non-SASL authentication
        ::xmpp::auth::auth $xlib -sessionid $sessionid \
                                 -username  $lc(user) \
                                 -password  $lc(password) \
                                 -resource  $lc(resource) \
                                 -digest    $digest \
                                 -sm        $sm \
                                 -command [list recv_auth_result $xlib \
                                                                 $logindata]
    }
}

########################################################################

proc logout {{xlib {}}} {
    global login_after_id

    debugmsg login "LOGOUT $xlib"

    if {$xlib == {}} {
        foreach jid [array names login_after_id] {
            after cancel $login_after_id($jid)
            unset login_after_id($jid)
        }

        foreach xlib [connections 1] {
            login_log [connection_jid $xlib] ok "Logout"
            disconnected $xlib
        }
    } else {
        login_log [connection_jid $xlib] ok [::msgcat::mc "Logout"]
        disconnected $xlib
    }
}

proc client:disconnect {xlib} {
    global reconnect
    global loginconf_hist

    login_log [connection_jid $xlib] error [::msgcat::mc "Forced logout"]

    if {$reconnect($xlib)} {
        debugmsg login "RECONNECT $xlib"
    } else {
        debugmsg login "DISCONNECT $xlib"
    }

    disconnected $xlib

    if {$reconnect($xlib)} {
        after 1000 [list login $loginconf_hist($xlib)]
    }
}

proc connected {xlib logindata} {
    hook::run connected_hook $xlib
}

# TODO
proc disconnected {xlib} {
    remove_from_login_after_id $xlib

    if {$xlib ni [connections]} {
        ::xmpp::disconnect $xlib
        return
    }

    hook::run disconnected_hook $xlib
}

hook::add disconnected_hook ::xmpp::disconnect 10

proc client:log {xlib dir type msg} {
    hook::run log_hook $xlib $dir $type $msg
}

proc remove_from_login_after_id {xlib} {
    global login_after_id

    set jid [::xmpp::jid::normalize [connection_requested_jid $xlib]]
    if {[info exists login_after_id($jid)]} {
        after cancel $login_after_id($jid)
        unset login_after_id($jid)
    }
}

proc recv_auth_result {xlib logindata status xml} {
    global connjid
    global reconnect

    array set lc $logindata

    switch -- $status {
        ok {
            set connjid($xlib) $xml
            set reconnect($xlib) 1
            login_log $xml ok [::msgcat::mc "Login is successful"]
            connected $xlib $logindata
        }
        abort {
            # TODO
            debugmsg login \
                     "Authentication aborted: $xlib [error_to_string $xml]"
            login_log $lc(jid) abort [error_to_string $xml]
            logout $xlib
        }
        default {
            login_log $lc(jid) $status [error_to_string $xml]

            lassign [error_type_condition $xml] type cond
            if {$type eq "sasl" ||
                        $type eq "auth" && $cond eq "not-authorized"} {
                set res [MessageDlg [epath] -aspect 50000 -icon error \
                             -message [::msgcat::mc "Authentication failed:\
                                                     %s\nCreate new account?" \
                                                    [error_to_string $xml]] \
                             -type user -buttons {yes no} -default 0 -cancel 1]
                if {!$res} {
                    ::register::open $xlib $lc(server) \
                            -command [list recv_register_result $xlib \
                                           $logindata]
                    return
                }
            } else {
                MessageDlg [epath] -aspect 50000 -icon error \
                    -message [::msgcat::mc "Authentication failed: %s" \
                                           [error_to_string $xml]] \
                    -type user -buttons {ok} -default 0 -cancel 0
            }

            logout $xlib
        }
    }
}

proc recv_register_result {xlib logindata status xml} {
    logout $xlib

    switch -- $status {
        ok {
            login $logindata
        }
    }
}

proc client:error {xlib condition message} {
    global reconnect

    login_log [connection_jid $xlib] error $message

    if {[winfo exists .client_error]} {
        destroy .client_error
    }

    switch -- $condition {
        bad-format -
        connection-timeout -
        invalid-from -
        invalid-id -
        invalid-namespace -
        invalid-xml -
        remote-connection-failed -
        restricted-xml -
        unsupported-encoding -
        unsupported-stanza-type -
        xml-not-well-formed {
            set reconnect($xlib) 1
        }
        default {
            set reconnect($xlib) 0
        }
    }

    NonmodalMessageDlg .client_error -aspect 50000 -icon error \
                                     -message $message
}

# TODO
proc show_logout_dialog {} {
    global reason reasonlist

    set lw .logout

    if {[winfo exists $lw]} {
        destroy $lw
    }

    Dialog $lw -title [::msgcat::mc "Logout with reason"] \
               -anchor e -default 0 -cancel 1

    set lf [$lw getframe]
    grid columnconfigure $lf 1 -weight 1

    if {[llength $reasonlist]} {set reason [lindex $reasonlist 0]}

    Label $lf.lreason   -text    [::msgcat::mc "Reason:"]
    Combobox $lf.reason -textvariable reason \
            -values $reasonlist -width 35
    Label $lf.lpriority -text    [::msgcat::mc "Priority:"]
    Entry $lf.priority -textvariable loginconf(priority)

    grid $lf.lreason   -row 0 -column 0 -sticky e
    grid $lf.reason    -row 0 -column 1 -sticky ew
    grid $lf.lpriority -row 1 -column 0 -sticky e
    grid $lf.priority  -row 1 -column 1 -sticky ew

    $lw add -text [::msgcat::mc "Log out"] -command logout_reason
    $lw add -text [::msgcat::mc "Cancel"] -command "$lw withdraw"

    $lw draw $lf.reason
}

proc logout_reason {} {
    global logoutuserstatus logouttextstatus logoutpriority reason reasonlist

    set reasonlist [update_combo_list $reasonlist $reason 10]

    set lw .logout
    if {[winfo exists $lw]} {
        destroy $lw
    }

    # TODO
    set logoutpriority $::loginconf(priority)
    set logouttextstatus $reason
    set logoutuserstatus unavailable

    logout
}

proc login_log_window {} {
    global login_log

    if {![info exists login_log]} {
        set login_log {}
    }

    set w .login_log

    if {[winfo exists $w]} {
        raise_win $w
        return
    }

    add_win $w -title [::msgcat::mc "Login log"] \
               -tabtitle [::msgcat::mc "Login log"] \
               -class Chat \
               -raisecmd [list focus $w.body]

    [ScrolledWindow $w.sw] setwidget \
                           [Text $w.body -state disabled -takefocus 1]
    bind $w.body <1> [list focus $w.body]

    pack $w.sw -side bottom -fill both -expand yes

    $w.body tag configure jid   \
            -foreground [option get $w meforeground Chat]
    $w.body tag configure ok \
            -foreground [option get $w theyforeground Chat]
    $w.body tag configure error  \
            -foreground [option get $w errforeground Chat]

    # TODO
    #search::setup_panel $w

    foreach {timestamp jid status message} $login_log {
        log_window_append $timestamp $jid $status $message
    }

    $w.body see end
    raise_win $w
}

proc log_window_append {timestamp jid status message} {
    set w .login_log

    if {![winfo exists $w.body]} return

    $w.body configure -state normal

    set scroll [expr {[lindex [$w.body yview] 1] == 1}]

    $w.body insert end [clock format $timestamp -format "\[%m/%d %T\] "] "" \
                       $jid jid " "

    switch -- $status {
        ok {set tag ok}
        default {set tag error}
    }

    $w.body insert end $status $tag " "

    $w.body insert end [string trim $message]
    $w.body insert end "\n"

    if {$scroll} {
        $w.body see end
    }

    $w.body configure -state disabled
}

proc login_log {jid status message} {
    global login_log

    if {![info exists login_log]} {
        set login_log {}
    }

    set timestamp [clock seconds]
    lappend login_log $timestamp $jid $status $message
    log_window_append $timestamp $jid $status $message
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
