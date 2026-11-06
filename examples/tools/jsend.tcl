#!/bin/sh
# the next line restarts using the correct interpreter \
exec tclsh "$0" "$0" "$@"

package require -exact jabberlib 0.10.1
package require mime
package require sha1
package require tls


proc jlib::sendit {stayP to args} {
    global env

    variable lib
    variable roster
    variable sendit_result

    array set options [list -to          $to  \
                            -from        ""   \
                            -password    ""   \
                            -host        ""   \
                            -port        ""   \
                            -activity    ""   \
                            -type        chat \
                            -subject     ""   \
                            -body        ""   \
                            -xhtml       ""   \
                            -description ""   \
                            -url         ""   \
                            -tls         true]
    array set options $args

    if {![string compare $options(-host) ""]} {
        set options(-host) [info hostname]
    }

    set params [list from]
    if {[string compare $options(-to) "-"]} {
        lappend params to
    }
    foreach k $params {
        if {[string first @ $options(-$k)] < 0} {
            if {[set x [string first / $options(-$k)]] >= 0} {
                set options(-$k) [string replace $options(-$k) $x $x \
                                         @$options(-host)/]
            } else {
                append options(-$k) @$options(-host)
            }
        }
        if {([string first @ $options(-$k)] == 0) \
                && ([info exists env(USER)])} {
            set options(-$k) $env(USER)$options(-$k)
        }
    }
    if {[string compare $options(-to) "-"]} {
        set options(-to) [list $options(-to)]
    }

    foreach k [list tls] {
        switch -- [string tolower $options(-$k)] {
            1 - 0               {}
            false - no  - off   { set options(-$k) 0 }
            true  - yes - on    { set options(-$k) 1 }
            default {
                error "invalid value for -$k: $options(-$k)"
            }
        }
    }

    array set aprops [lindex [mime::parseaddress $options(-from)] 0]
    if {[set x [string first / $aprops(domain)]] >= 0} {
        set aprops(resource) [string range $aprops(domain) [expr $x+1] end]
        set aprops(domain) [string range $aprops(domain) 0 [expr $x-1]]
    } else {
        set aprops(resource) "jsend"
    }

    if {(![string compare $options(-body) ""]) && ($stayP < 2)} {
        set options(-body) [read -nonewline stdin]
    }

    set options(-xlist) {}
    if {[string compare $options(-url)$options(-description) ""]} {
        lappend options(-xlist) \
                [jlib::wrapper:createtag x \
                       -vars [list xmlns jabber:x:oob] \
                       -subtags [list [jlib::wrapper:createtag url \
                                             -chdata $options(-url)] \
                                      [jlib::wrapper:createtag desc \
                                             -chdata $options(-description)]]]
    }
    if {([string compare $options(-xhtml) ""]) \
            && ([string compare $options(-body) ""]) \
            && ($stayP < 1)} {
        lappend options(-xlist) \
                [jlib::wrapper:createtag html \
                       -vars [list xmlns http://jabber.org/protocol/xhtml-im] \
                       -subtags [list [jlib::wrapper:createtag body \
                                             -vars [list xmlns \
                                                         http://www.w3.org/1999/xhtml] \
                                             -subtags [jsend::parse_xhtml $options(-xhtml)]]]]
    }
    if {![string compare $options(-type) announce]} {
        set options(-type) normal
        set announce [sha1::sha1 \
                          [clock seconds]$options(-subject)$options(-body)]
        lappend options(-xlist) \
                [jlib::wrapper:createtag x \
                     -vars [list xmlns \
                                 http://2entwine.com/protocol/gush-announce-1_0] \
                     -subtags [list [jlib::wrapper:createtag id \
                                          -chdata $announce]]]
    }

    set lib(lastwhat) $options(-activity)
    if {[catch { clock scan $options(-time) } lib(lastwhen)]} {
        set lib(lastwhen) [clock seconds]
    }

    set params {}
    foreach k [list body subject type xlist] {
        if {[string compare $options(-$k) ""]} {
            lappend params -$k $options(-$k)
        }
    }

    if {[llength [jlib::connections]] <= 0} {
        set connid [jlib::new -user $aprops(local) \
                              -server $aprops(domain) \
                              -resource $aprops(resource)]
        if {$options(-tls)} {
            set transport tls
            if {[string compare $options(-port) ""]} {
                set port $options(-port)
            } else {
                set port 5223
            }
        } else {
            set transport tcp
            if {[string compare $options(-port) ""]} {
                set port $options(-port)
            } else {
                set port 5222
            }
        }
        jlib::connect $connid \
                      -transport $transport \
                      -host [idna::domain_toascii $aprops(domain)] \
                      -port $port \
                      -password $options(-password)

        jlib::login $connid [namespace current]::sendit_aux

        vwait [namespace current]::sendit_result

        if {[string compare [lindex $sendit_result 0] OK]} {
            error [lindex $sendit_result 1]
        }

        roster_get -command [namespace current]::roster_get_aux
        vwait [namespace current]::sendit_result
    } else {
        set connid [lindex [jlib::connections] 0]
    }

    if {![string compare $options(-to) "-"]} {
        set options(-to) $roster(users)
    }

    if {$stayP > 1} {
        jlib::send_presence -stat Online \
                            -connection $connid
        if {![string compare $options(-type) groupchat]} {
            set nick $aprops(local)@$aprops(domain)/@aprops(resource)
            set nick [string range [sha1::sha1 $nick+[clock seconds]] 0 7]
            foreach to $options(-to) {
                jlib::send_presence -to $to/$nick \
                                    -connection $connid
            }
        }
        return 1
    }

    foreach to $options(-to) {
        switch -- [eval [list jlib::send_msg $to -connection $connid] $params] {
            -1 - -2 {
                if {$stayP} {
                    set cmd [list ::LOG]
                } else {
                    set cmd [list error]
                }
                eval $cmd [list "error writing to socket, continuing..."]
                return 0
            }

            default {
            }
        }
    }
    if {!$stayP} {
        set jsend::stayP 0
        jlib::disconnect $connid
    }

    return 1
}

proc jlib::sendit_aux {result args} {
    variable sendit_result

    set sendit_result [list $result $args]
}

proc jlib::roster_get_aux {what args} {
    variable sendit_result

    set sendit_result $what
}

proc client:message {args} {
#    ::LOG "client:message $args"
}

proc client:presence {args} {
#    ::LOG "client:presence $args"
}

proc client:iqreply {connid from userid id type lang child} {
    jlib::wrapper:splitxml $child tag vars isempty chdata children
    set xmlns [jlib::wrapper:getattr $vars xmlns]
    ::LOG "client:iqreply $from $userid $id $type $lang $xmlns"

    set result result
    set now [clock seconds]
    switch -- $type/$xmlns {
        get/jabber:iq:browse {
            foreach ns [list browse last time version] {
                lappend tags [jlib::wrapper:createtag ns -chdata $ns]
            }
            set xmldata [jlib::wrapper:createtag user \
                             -vars [list xmlns $xmlns type client] \
                             -subtags $tags]
        }

        get/jabber:iq:last {
            set xmldata [jlib::wrapper:createtag query  \
                             -vars [list xmlns   $xmlns \
                                         seconds        \
                                            [expr $now-$jlib::lib(lastwhen)]] \
                             -chdata $jlib::lib(lastwhat)]
        }

        get/jabber:iq:time {
            set gmtP true
            foreach {k f} [list utc     "%Y%m%dT%T" \
                                tz      "%Z"        \
                                display "%a %b %d %H:%M:%S %Z %Y"] {
                lappend tags [jlib::wrapper:createtag $k \
                                 -chdata [clock format $now \
                                               -format $f   \
                                               -gmt    $gmtP]]
                set gmtP false
            }
            set xmldata [jlib::wrapper:createtag query \
                             -vars [list xmlns $xmlns] \
                             -subtags $tags]
        }

        get/jabber:iq:version {
            global argv0 tcl_platform

            foreach {k v} [list name    [file tail [file rootname $argv0]] \
                                version "1.0 (Tcl [info patchlevel])"      \
                                os      "$tcl_platform(os) $tcl_platform(osVersion)"] {
                lappend tags [jlib::wrapper:createtag $k -chdata $v]
                set gmtP false
            }
            set xmldata [jlib::wrapper:createtag query \
                             -vars [list xmlns $xmlns] \
                             -subtags $tags]
        }

        default {
            set result error
            set xmldata [jlib::wrapper:createtag error \
                             -vars [list code 501] \
                             -chdata "not implemented"]
        }
    }

    jlib::send_iq $result $xmldata -to $from -id $id -connection $connid
}

proc client:roster_push {args} {}

proc client:roster_item {args} {}

proc client:reconnect {connid} {
    jsend::reconnect
}

proc client:disconnect {connid} {
    jsend::reconnect
}

proc client:status {args} {
    ::LOG "client:status $args"
}


namespace eval jsend {
    variable stayP 1
}

proc jsend::follow {file argv} {
    proc [namespace current]::reconnect {} \
         [list [namespace current]::reconnect_aux $argv]

    if {[catch { eval [list jlib::sendit 2] $argv } result]} {
        ::bgerror $result
        return
    }

    set buffer ""
    set fd ""
    set newP 1
    array set st [list dev 0 ino 0 size 0]

    for {set i 0} {1} {incr i} {
        if {[expr $i%5] == 0} {
            if {[catch { file stat $file st2 } result]} {
                ::LOG $result
                break
            }

            if {($st(dev) != $st2(dev)) \
                    || ($st(ino) != $st2(ino)) \
                    || ($st(size) > $st2(size))} {
                if {$newP} {
                    catch { close $fd }
                }

                fconfigure [set fd [open $file { RDONLY }]] -blocking off
                unset st
                array set st [array get st2]

                if {(!$newP) && (![string compare $st(type) file])} {
                    seek $fd 0 end
                }

                if {!$newP} {
                    set newP 0
                }

                if {[string length $buffer] > 0} {
                    if {[catch { eval [list jlib::sendit 1] $argv \
                                      [parse $buffer] \
                                      [list -body $buffer] } result]} {
                        ::LOG $result
                        break
                    } elseif {$result} {
                        set buffer ""
                    }
                }
            }
        }

        if {[fblocked $fd]} {
        } elseif {[catch {
            set len [string length [set line [read $fd]]]
            append buffer $line
        } result]} {
            ::LOG $result
            break
        } elseif {[set x [string first "\n" $buffer]] < 0} {
        } else {
            set body [string range $buffer 0 [expr {$x-1}]]
            while {[catch { eval [list jlib::sendit 1] $argv [parse $body] \
                                 [list -body $body] } result]} {
                ::LOG $result
            }
            if {$result} {
                set buffer [string range $buffer [expr $x+1] end]
            }
        }

        after 1000 "set alarmP 1"
        vwait alarmP
    }
}

proc jsend::parse {line} {
    set args {}

    if {![string equal [string index $line 15] " "]} {
        return $args
    }
    catch { lappend args -time [clock scan [string range $line 0 14]] }

    set line [string range $line 16 end]
    if {([set d [string first " " $line]] > 0) \
            && ([string first ": " $line] > $d)} {
        lappend args -activity [string trim [string range $line $d end]]
    }

    return $args
}

proc jsend::reconnect_aux {argv} {
    variable stayP

    while {$stayP} {
        after [expr 60*1000]
        if {![catch { eval [list jlib::sendit 2] $argv } result]} {
            break
        }

        ::LOG $result
    }
}

proc jsend::parse_xhtml {text} {
    variable xhtml

    set wrap [jlib::wrapper:new [list [namespace current]::wrap_xhtml start] \
                                [list [namespace current]::wrap_xhtml end] \
                                [list [namespace current]::wrap_xhtml parse]]
    jlib::wrapper:parser $wrap parse "<body>$text</body>"
    jlib::wrapper:reset $wrap

    return $xhtml
}


proc jsend::wrap_xhtml {mode args} {
    variable xhtml

    if {![string compare $mode parse]} {
        set xhtml $args
    }
}


proc ::LOG {text} {
#    puts stderr $text
}

proc ::debugmsg {args} {
#    ::LOG "debugmsg: $args"
}

proc ::bgerror {err} {
    global errorInfo

    ::LOG "$err\n$errorInfo"
}


set status 1

array set jlib::lib [list lastwhen [clock seconds] lastwhat ""]

if {![string compare [file tail [lindex $argv 0]] "jsend.tcl"]} {
    incr argc -1
    set argv [lrange $argv 1 end]
}

if {(([set x [lsearch -exact $argv -help]] >= 0) \
            || ([set x [lsearch -exact $argv --help]] >= 0)) \
        && (($x == 0) || ([expr $x%2]))} {
    puts stdout "usage: jsend.tcl recipient ?options...?
            -follow      file
            -pidfile     file
            -from        jid
            -password    string
            -type        string (e.g., 'chat')
            -subject     string
            -body        string
            -xhtml       string
            -description string
            -url         string
            -tls         boolean (e.g., 'true')

If recipient is '-', roster is used.

If both '-body' and '-follow' are absent, the standard input is used.

The file .jsendrc.tcl is consulted, e.g.,

    set args {-from fred@example.com/bedrock -password wilma}

for default values."

    set status 0
} elseif {($argc < 1) || (![expr $argc%2])} {
    puts stderr "usage: jsend.tcl recipent ?-key value?..."
} elseif {[catch {
    if {([file exists [set file .jsendrc.tcl]]) \
            || ([file exists [set file ~/.jsendrc.tcl]])} {
        set args {}

        source $file

        array set at [list -permissions 600]
        array set at [file attributes $file]

        if {([set x [lsearch -exact $args "-password"]] > 0) \
                    && (![expr $x%2]) \
                    && (![string match *00 $at(-permissions)])} {
            error "file should be mode 0600"
        }

        if {[llength $args] > 0} {
            set argv [eval [list linsert $argv 1] $args]
        }
    }
} result]} {
    puts stderr "error in $file: $result"
} elseif {([set x [lsearch -exact $argv "-follow"]] > 0) && ([expr $x%2])} {
    set keep_alive 1
    set keep_alive_interval 3

    if {([set y [lsearch -exact $argv "-pidfile"]] > 0) && ([expr $y%2])} {
        set fd [open [set pf [lindex $argv [expr $y+1]]] \
                     { WRONLY CREAT TRUNC }]
        puts $fd [pid]
        close $fd
    }

    jsend::follow  [lindex $argv [expr $x+1]] $argv

    catch { file delete -- $pf }
} elseif {[catch { eval [list jlib::sendit 0] $argv } result]} {
    puts stderr $result
} else {
    set status 0
}

exit $status

# vim:ft=tcl:ts=8:sw=4:sts=4:et
