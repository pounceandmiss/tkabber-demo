# proxy.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements proxy
#       profiles infrasrtucture and user interface.

package require pconnect::socks4
package require pconnect::socks5
package require pconnect::https
package require http 2

::http::config -proxyhost "" -proxyport "" -proxyfilter ""

namespace eval proxy {}

proc proxy::serialize_profile {proxyconfvar} {
    upvar #0 $proxyconfvar proxyconf

    set tproxies {}
    set hproxies {}

    foreach {key varlist} [array get proxyconf] {
        switch -- $key {
            tunnel -
            http {}
            default {
                continue
            }
        }

        foreach varname $proxyconf($key) {
            upvar #0 $varname p
            if {![info exists p(type)] ||
                        $p(type) ni {http https socks4 socks5}} {
                continue
            }
            set proxy [list type $p(type)]
            if {[info exists p(host)]} {
                lappend proxy host $p(host)
            } else {
                continue
            }
            if {[info exists p(port)]} {
                lappend proxy port $p(port)
            } else {
                continue
            }
            if {[info exists p(username)]} {
                lappend proxy username $p(username)
            }
            if {[info exists p(password)]} {
                lappend proxy password $p(password)
            }
            if {[info exists p(match)]} {
                lappend proxy match $p(match)
            }
            if {[info exists p(exclude)]} {
                lappend proxy exclude $p(exclude)
            }

            switch -- $key {
                tunnel {
                    lappend tproxies $proxy
                }
                http {
                    lappend hproxies $proxy
                }
            }
        }
    }

    if {[llength $tproxies] > 0 || [llength $hproxies] > 0} {
        # There are proxies defined in the config file

        return [list tunnels $tproxies http $hproxies]
    } else {
        return {tunnels {} http {}}
    }
}

namespace eval proxy {
    variable proxylist [serialize_profile ::proxyconf]

    custom::defvar proxylist {tunnels {} http {}} \
        [::msgcat::mc "Serialized array of proxy servers to connect via."] \
        -type string -group Hidden
}

# http package doesn't work with HTTPS URLs through proxy, so workaround this:

if {![catch {package require tls}]} {
    # proxy::tlssocket --
    #
    # Arguments:
    #       ?options? host port
    #
    # Bugs:
    #       Doesn't work with -async

    proc proxy::tlssocket {args} {
        set host [lindex $args end-1]
        set port [lindex $args end]

        set opts {-ssl2 0 -ssl3 0 -tls1 1}
        if {![catch ::tls::ciphers tls1.1]} {
            lappend opts -tls1.1 1
        }
        if {![catch ::tls::ciphers tls1.2]} {
            lappend opts -tls1.2 1
        }

        # Find tunnelling proxy
        if {![catch {proxyfilter $host $port} answer] && $answer != {}} {
            return [::tls::import {*}$opts \
                        [::pconnect::socket $host $port \
                            -proxyfilter [namespace current]::proxyfilter]]
        } else {
            return [::tls::socket {*}$opts {*}$args]
        }
    }

    ::http::register https 443 [namespace current]::proxy::tlssocket
}

# ::http::geturl --
#
#       A wrapper around http::geturl which adds proxy authorization header
#       if necessary.

rename ::http::geturl ::http::geturl:orig

proc ::http::geturl {url args} {
    # Save and remove proxy settings

    set savedProxyHost   [::http::config -proxyhost]
    set savedProxyPort   [::http::config -proxyport]
    set savedProxyFilter [::http::config -proxyfilter]

    ::http::config -proxyhost "" -proxyport "" -proxyfilter ""

    # URLmatcher is borrowed from http package.
    set URLmatcher {(?x)                    # this is _expanded_ syntax
        ^
        (?: (\w+) : ) ?                     # <protocol scheme>
        (?: //
            (?:
                (
                    [^@/\#?]+               # <userinfo part of authority>
                ) @
            )?
            ( [^/:\#?]+ )                   # <host part of authority>
            (?: : (\d+) )?                  # <port part of authority>
        )?
        ( / [^\#?]* (?: \? [^\#?]* )?)?     # <path> (including query)
        (?: \# (.*) )?                      # <fragment>
        $
    }

    set auth {}
    if {[regexp -- $URLmatcher $url -> \
                   proto user host port srvurl]} {

        if {$proto != "https"} {
            ::http::config -proxyfilter ::proxy::proxyfilter

            if {![catch {proxyfilter $host} answer]} {
                lassign $answer phost pport pusername ppassword
                if {$pusername ne "" || $ppassword ne ""} {
                    set auth [list Proxy-Authorization \
                                   "Basic [base64::encode \
                                               [encoding convertto \
                                                    $pusername:$ppassword]]"]
                }
            }
        }
    }

    set newArgs {}
    set q 0
    foreach {key val} $args {
        switch -- $key {
            -headers {
                lappend newArgs $key [concat $val $auth]
                set q 1
            }
            default {
                lappend newArgs $key $val
            }
        }
    }
    if {!$q} {
        lappend newArgs -headers $auth
    }

    set res [::http::geturl:orig $url {*}$newArgs]

    ::http::config -proxyhost $savedProxyHost \
                   -proxyport $savedProxyPort \
                   -proxyfilter $savedProxyFilter
    return $res
}

proc proxy::open {} {
    variable proxylist

    set w .proxy

    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -title [::msgcat::mc "Manage proxy servers"] \
              -anchor e \
              -default 0 \
              -cancel 1 \
              -modal none

    $w add -text [::msgcat::mc "Save"] \
           -command [namespace code [list save_proxies $w]]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set hf [Frame $w.hf]
    pack $hf -side bottom

    set f [$w getframe]
    set nb [Notebook $f.nb]
    set tunnels_page \
        [$nb insert end tunnels_page -text [::msgcat::mc "Tunnel proxies"]]
    set http_page \
        [$nb insert end http_page -text [::msgcat::mc "HTTP proxies"]]

    set n 1
    while {[info exists ::proxyconf$n]} {incr n}
    incr n -1

    if {$n} {
        Menubutton $f.profiles -text [::msgcat::mc "Profiles"] \
                               -menu $f.profiles.menu
        set m [menu $f.profiles.menu -tearoff 0]
        $m add command -label [::msgcat::mc "Default empty profile"] \
            -command [list [namespace current]::update_proxy_entries $hf $nb \
                           $tunnels_page $http_page default]
        $m add command -label [::msgcat::mc "Profile from config file"] \
            -command [list [namespace current]::update_proxy_entries $hf $nb \
                           $tunnels_page $http_page config]
        $m add command -label [::msgcat::mc "Currently active profile"] \
            -command [list [namespace current]::update_proxy_entries $hf $nb \
                           $tunnels_page $http_page current]
        for {set i 1} {$i <= $n} {incr i} {
            if {[info exists ::proxyconf${i}(profile)]} {
                set lab [set ::proxyconf${i}(profile)]
            } else {
                set lab "[::msgcat::mc Profile] $i"
            }
            if {$i <= 10} {
                set j [expr {$i % 10}]
                $m add command -label $lab -accelerator "$::tk_modify-$j" \
                    -command [list [namespace current]::update_proxy_entries \
                                   $hf $nb $tunnels_page $http_page $i]
                bind $w <Control-Key-$j> \
                    [list [namespace current]::update_proxy_entries \
                          [double% $hf] [double% $nb] [double% $tunnels_page] \
                          [double% $http_page] $i]
            } else {
                $m add command -label $lab \
                    -command [list [namespace current]::update_proxy_entries \
                                   $hf $nb $tunnels_page $http_page $i]
            }
        }

        grid $f.profiles -row 0 -column 0 -sticky ne
    }

    grid $nb -row 1 -column 0 -sticky nswe
    grid columnconfigure $f 0 -weight 1
    grid rowconfigure $f 0 -weight 1

    fill_pages $hf $nb $tunnels_page $http_page $proxylist
    $nb raise tunnels_page

    $w draw
}

proc proxy::update_proxy_entries {hf nb tunnels_page http_page i} {
    variable proxylist

    switch -- $i {
        default {
            fill_pages $hf $nb $tunnels_page $http_page {tunnels {} http {}}
        }
        config {
            fill_pages $hf $nb $tunnels_page $http_page \
                       [serialize_profile ::proxyconf]
        }
        current {
            fill_pages $hf $nb $tunnels_page $http_page $proxylist
        }
        default {
            fill_pages $hf $nb $tunnels_page $http_page \
                       [serialize_profile ::proxyconf$i]
        }
    }
}

proc proxy::fill_pages {hf nb tunnels_page http_page proxies} {
    set w1 [customize_frame $tunnels_page tunnels $proxies]
    set w2 [customize_frame $http_page http $proxies]

    catch {$nb compute_size}
    update idletasks

    if {$w1 > $w2} {
        $hf configure \
            -width [expr {$w1 + [winfo pixels $nb 1c]}]
    } elseif {$w2 > 0} {
        $hf configure \
            -width [expr {$w2 + [winfo pixels $nb 1c]}]
    }
}

proc proxy::customize_frame {frame type proxies} {
    variable data

    switch -- $type {
        tunnels {
            set add_type https
        }
        http {
            set add_type http
        }
        default {
            return -code error
        }
    }

    array set Proxy $proxies

    set q 0
    foreach path [winfo children $frame] {
        destroy $path
        set q 1
    }

    set tools [Frame $frame.tools]
    pack $tools -side bottom -fill x

    set sw [ScrolledWindow $frame.sw -scrollbar vertical]
    set sf [ScrollableFrame $frame.fields -constrainedwidth yes]
    pack $sw -side bottom -expand yes -fill both
    $sw setwidget $sf
    set f [$sf getframe]
    bindscroll $f $sf

    bind $f <Destroy> [namespace code [list cleanup $f $type]]

    set add [Button $tools.add \
                    -text [::msgcat::mc "Add proxy"] \
                    -command [namespace code \
                        [list add_proxy $sf $f $type $add_type "" "" "" "" * \
                              "localhost* 127.0.0.* 172.* 192.168.* 10.*"]]]
    pack $add -side right -pady 2m

    set data($type,counter) 0

    if {!$q} {
        add_proxy $sf $f $type remove "" "" "" "" "" ""
    }

    if {[info exists Proxy($type)]} {
        foreach proxy $Proxy($type) {
            array unset Args
            array set Args $proxy

            set add_args {}
            foreach idx {type host port username password match exclude} {
                if {[info exists Args($idx)]} {
                    lappend add_args $Args($idx)
                } else {
                    lappend add_args ""
                }
            }

            add_proxy $sf $f $type {*}$add_args
        }
    }

    if {!$q} {
        update idletasks
        set w [winfo reqwidth $f]

        remove_proxy $f $type 1
    } else {
        set w 0
    }

    return $w
}

proc proxy::cleanup {f type} {
    variable data

    array unset data $type,*
}

proc proxy::save_proxies {w} {
    variable data
    variable proxylist

    foreach type {tunnels http} {
        set proxies($type) {}
        for {set i 1} {$i <= $data($type,counter)} {incr i} {
            if {$data($type,type,$i) == "remove"} continue

            if {$data($type,type,$i) ni {http https socks4 socks5}} {
                continue
            }

            lappend proxies($type) [list type $data($type,type,$i) \
                                         host $data($type,host,$i) \
                                         port $data($type,port,$i) \
                                         username $data($type,username,$i) \
                                         password $data($type,password,$i) \
                                         match $data($type,match,$i) \
                                         exclude $data($type,exclude,$i)]
        }
    }

    destroy $w

    set proxylist [list tunnels $proxies(tunnels) http $proxies(http)]
}

proc proxy::add_proxy \
     {sf f type ptype host port username password match exclude} {
    variable data

    switch -- $type {
        tunnels {
            if {$ptype ni {remove https socks4 socks5}} return
        }
        http {
            if {$ptype ni {remove http}} return
        }
        default {
            return
        }
    }

    set i [incr data($type,counter)]

    set data($type,type,$i) $ptype
    set data($type,host,$i) $host
    set data($type,port,$i) $port
    set data($type,username,$i) $username
    set data($type,password,$i) $password
    set data($type,match,$i) $match
    set data($type,exclude,$i) $exclude

    set erow [lindex [grid size $f] 1]

    set ff [Labelframe $f.p$i -padding {2m 2m}]
    grid $ff -row $erow -column 0 -rowspan 3 -sticky nwes -padx 1m -pady 1m
    bindscroll $ff $sf

    set row 0

    Label $ff.lproxy$i -text [::msgcat::mc "Proxy type:"]
    grid $ff.lproxy$i -row $row -column 0 -sticky e
    bindscroll $ff.lproxy$i $sf
    Frame $ff.proxy$i
    grid $ff.proxy$i -row $row -column 1 -columnspan 3 -sticky w

    set col 0

    if {$type == "tunnels"} {
        Radiobutton $ff.proxy$i.https -text [::msgcat::mc "HTTPS"] \
                    -variable [namespace current]::data($type,type,$i) \
                    -value https
        grid $ff.proxy$i.https -row 0 -column [incr col] -sticky w
        bindscroll $ff.proxy$i.https $sf

        Radiobutton $ff.proxy$i.socks4 -text [::msgcat::mc "SOCKS4a"] \
                    -variable [namespace current]::data($type,type,$i) \
                    -value socks4
        grid $ff.proxy$i.socks4 -row 0 -column [incr col] -sticky w
        bindscroll $ff.proxy$i.socks4 $sf

        Radiobutton $ff.proxy$i.socks5 -text [::msgcat::mc "SOCKS5"] \
                    -variable [namespace current]::data($type,type,$i) \
                    -value socks5
        grid $ff.proxy$i.socks5 -row 0 -column [incr col] -sticky w
        bindscroll $ff.proxy$i.socks5 $sf
    } else {
        Label $ff.proxy$i.https -text [::msgcat::mc "HTTP"]
        grid $ff.proxy$i.https -row 0 -column [incr col] -sticky w
        bindscroll $ff.proxy$i.https $sf
    }

    incr row

    Label $ff.lhost$i -text [::msgcat::mc "Host:"]
    Entry $ff.host$i -textvariable [namespace current]::data($type,host,$i)
    Label $ff.lport$i -text [::msgcat::mc "Port:"]
    Spinbox $ff.port$i 0 65535 1 [namespace current]::data($type,port,$i)

    grid $ff.lhost$i -row $row -column 0 -sticky e
    grid $ff.host$i  -row $row -column 1 -sticky ew
    grid $ff.lport$i -row $row -column 2 -sticky e
    grid $ff.port$i  -row $row -column 3 -sticky ew

    incr row

    Label $ff.lusername$i -text [::msgcat::mc "Username:"]
    Entry $ff.username$i \
          -textvariable [namespace current]::data($type,username,$i)
    Label $ff.lpassword$i -text [::msgcat::mc "Password:"]
    Entry $ff.password$i -show * \
          -textvariable [namespace current]::data($type,password,$i)

    grid $ff.lusername$i -row $row -column 0 -sticky e
    grid $ff.username$i  -row $row -column 1 -sticky ew
    grid $ff.lpassword$i -row $row -column 2 -sticky e
    grid $ff.password$i  -row $row -column 3 -sticky ew

    incr row

    Label $ff.lmatch$i -text [::msgcat::mc "Match:"]
    Entry $ff.match$i \
          -textvariable [namespace current]::data($type,match,$i)

    grid $ff.lmatch$i -row $row -column 0 -sticky e
    grid $ff.match$i  -row $row -column 1 -columnspan 3 -sticky ew

    incr row

    Label $ff.lexclude$i -text [::msgcat::mc "Exclude:"]
    Entry $ff.exclude$i \
          -textvariable [namespace current]::data($type,exclude,$i)

    grid $ff.lexclude$i -row $row -column 0 -sticky e
    grid $ff.exclude$i  -row $row -column 1 -columnspan 3 -sticky ew

    grid columnconfigure $ff 1 -weight 3
    grid columnconfigure $ff 2 -weight 1
    grid columnconfigure $ff 3 -weight 3

    Button $f.moveup$i -text [::msgcat::mc "Move up"] \
           -command [namespace code [list move_proxy_up $f $type $i]]
    Button $f.movedown$i -text [::msgcat::mc "Move down"] \
           -command [namespace code [list move_proxy_down $f $type $i]]
    Button $f.remove$i -text [::msgcat::mc "Remove"] \
           -command [namespace code [list remove_proxy $f $type $i]]

    grid $f.moveup$i -row $erow -column 1 -sticky ews -padx 1m
    grid $f.movedown$i -row [expr {$erow+1}] -column 1 -sticky ewns -padx 1m
    grid $f.remove$i -row [expr {$erow+2}] -column 1 -sticky ewn -padx 1m
    bindscroll $f.moveup$i $sf
    bindscroll $f.movedown$i $sf
    bindscroll $f.remove$i $sf

    grid rowconfigure $f $erow -weight 1
    grid rowconfigure $f [expr {$erow+2}] -weight 1
    grid columnconfigure $f 0 -weight 1

    foreach path [winfo children $ff] {
        bindscroll $path $sf
    }
}

proc proxy::remove_proxy {f type i} {
    variable data

    destroy $f.p$i
    destroy $f.moveup$i
    destroy $f.movedown$i
    destroy $f.remove$i

    set data($type,type,$i) remove
}

proc proxy::move_proxy_up {f type i} {
    variable data

    set j $i
    incr j -1
    while {$j > 0 && $data($type,type,$j) == "remove"} {
        incr j -1
    }

    if {$j > 0} {
        switch_proxies $f $type $i $j
    }
}

proc proxy::move_proxy_down {f type i} {
    variable data

    set j $i
    incr j 1
    while {$j <= $data($type,counter) && $data($type,type,$j) == "remove"} {
        incr j 1
    }

    if {$j <= $data($type,counter)} {
        switch_proxies $f $type $i $j
    }
}

proc proxy::switch_proxies {f type i j} {
    variable data

    set ptype    $data($type,type,$i)
    set host     $data($type,host,$i)
    set port     $data($type,port,$i)
    set username $data($type,username,$i)
    set password $data($type,password,$i)
    set match    $data($type,match,$i)
    set exclude  $data($type,exclude,$i)

    set data($type,type,$i)     $data($type,type,$j)
    set data($type,host,$i)     $data($type,host,$j)
    set data($type,port,$i)     $data($type,port,$j)
    set data($type,username,$i) $data($type,username,$j)
    set data($type,password,$i) $data($type,password,$j)
    set data($type,match,$i)    $data($type,match,$j)
    set data($type,exclude,$i)  $data($type,exclude,$j)

    set data($type,type,$j)     $ptype
    set data($type,host,$j)     $host
    set data($type,port,$j)     $port
    set data($type,username,$j) $username
    set data($type,password,$j) $password
    set data($type,match,$j)    $match
    set data($type,exclude,$j)  $exclude
}

proc proxy::proxyfilter {host {port -1}} {
    variable proxylist

    array set Proxy $proxylist

    if {$port < 0} {
        # HTTP proxy

        set plist $Proxy(http)
    } else {
        # Tunnel proxy

        set plist $Proxy(tunnels)
    }

    foreach proxy $plist {
        array unset Args
        array set Args $proxy

        if {$Args(type) ni {http https socks4 socks5}} {
            continue
        }

        if {![info exists Args(host)] || [string length $Args(host)] == 0} {
            continue
        }

        if {![info exists Args(port)] ||
                    ![string is integer -strict $Args(port)] ||
                    $Args(port) < 0 || $Args(port) >= 65536} {
            continue
        }

        set m 0
        if {[info exists Args(match)]} {
            foreach pattern [split $Args(match)] {
                if {[string match -nocase $pattern $host]} {
                    set m 1
                    break
                }
            }
        }

        set x 0
        if {[info exists Args(exclude)]} {
            foreach pattern [split $Args(exclude)] {
                if {[string match -nocase $pattern $host]} {
                    set x 1
                    break
                }
            }
        }

        if {$m && !$x} {
            if {$port < 0} {
                set res [list $Args(host) $Args(port)]
            } else {
                set res [list $Args(type) $Args(host) $Args(port)]
            }

            if {[info exists Args(username)] && [info exists Args(password)]} {
                lappend res $Args(username) $Args(password)
            }

            return $res
        }
    }

    return {}
}

proc proxy::set_profile {profile} {
    variable proxylist

    set i 1
    while {[info exists ::proxyconf$i]} {
        if {[info exists ::proxyconf${i}(profile)] &&
                    [set ::proxyconf${i}(profile)] eq $profile} {
            set proxylist [serialize_profile proxyconf$i]
            return $profile
        }
        incr i
    }
    return -code error "Can't find proxy profile $profile"
}

proc proxy::register_remote_command {} {
    if {[llength [info procs ::plugins::comm::register_command]] > 0} {
        ::plugins::comm::register_command set-proxy-profile \
                [namespace current]::set_profile "profile"
    }
}

hook::add postload_hook proxy::register_remote_command

# vim:ft=tcl:ts=8:sw=4:sts=4:et
