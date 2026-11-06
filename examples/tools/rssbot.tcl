#!/bin/sh
# the following restarts using tclsh \
PATH=/usr/bin:/bin:/usr/pkg/bin:/usr/local/bin:/sbin:/usr/sbin \
LD_LIBRARY_PATH=/usr/pkg/lib:/usr/lib:/usr/local/lib \
export PATH LD_LIBRARY_PATH; exec tclsh "$0" "$@"


package require jabberlib -exact 0.10.1
package require http 2
package require mime
package require tls
package require uri


proc jlib::sendit {stayP to args} {
    global env

    variable lib
    variable roster
    variable sendit_result

    array set options [list -to          $to      \
                            -from        ""       \
                            -password    ""       \
                            -host        ""       \
                            -port        ""       \
                            -activity    ""       \
                            -type        headline \
                            -subject     ""       \
                            -body        ""       \
                            -description ""       \
                            -url         ""       \
                            -tls         true]
    array set options $args

    if {![string compare $options(-host) ""]} {
        set options(-host) [info hostname]
    }

    set params [list from]
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
        set aprops(resource) "rssbot"
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

    if {[llength [jlib::connections] <= 0} {
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
            error [lindex [stanzaerror::error_to_list [lindex $sendit_result 1]]
        }

        roster_get -command [namespace current]::roster_get_aux
        vwait [namespace current]::sendit_result
    } else {
        set connid [lindex [jlib::connections] 0]
    }

    if {$stayP > 1} {
        jlib::send_presence -stat Online \
                            -connection $connid
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
        jlib::disconnect $connid
    }

    return 1
}

proc jlib::sendit_aux {result args} {
    variable sendit_result

    set sendit_result [list $result $args]
}

proc jlib::roster_get_aux {what} {
    variable sendit_result

    set sendit_result $what
}

proc client:message {connid from id type is_subject subject body err thread priority x} {
    ::LOG "client:message $from $body"

    if {![regexp {(.*@.*)/.*} $from x jid]} {
        set jid $from
    }
    switch -- $type {
        normal
            -
        chat {
        }

        "" {
            set type chat
        }

        default {
            ::LOG "$from ignoring $type"
            return
        }
    }

    if {[catch { rssbot::message $jid $body } answer]} {
        ::LOG "$jid/$body: $answer"
        set answer "internal error, sorry! ($answer)"
    }
    if {[catch { jlib::sendit 1 "" \
                     -to       $from          \
                     -activity "$jid: $body" \
                     -type     $type          \
                     -subject  $subject       \
                     -body     $answer } result]} {
        ::LOG "$from: $result"
    }
}

proc client:presence {connid from type x args} {
    ::LOG "client:presence $args"

    if {![regexp {(.*@.*)/.*} $from x jid]} {
        set jid $from
    }
    switch -- $type {
        available
            -
        unavailable {
        }

        "" {
            set type available
        }

        default {
            ::LOG "$from ignoring $type"
            return
        }
    }

    rssbot::presence $jid $type
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
    rssbot::reconnect
}

proc client:disconnect {connid} {
    rssbot::reconnect
}


namespace eval rssbot {}

# state variables
#     mtime - modified time
#     ntime - expiration time
#
#
# articles(source,url)    [list mtime ... ntime ... args { ... }  source "..."]
# sources(site)           [list mtime ... ntime ...]
# subscribers(jid)        [list mtime ...           sites { ... } status "..."]
#

proc rssbot::begin {argv} {
    global doneP

    variable iqP
    variable loopID
    variable parser

    variable articles
    variable sources
    variable subscribers

    proc [namespace current]::reconnect {} \
         [list [namespace current]::reconnect_aux $argv]

    if {[catch {
        set loopID ""
        [set parser [xml::parser]] configure \
                -elementstartcommand    [list [namespace current]::element \
                                              begin]                       \
                -elementendcommand      [list [namespace current]::element \
                                              end]                         \
                -characterdatacommand   [list [namespace current]::pcdata] \
                -errorcommand           [list [namespace current]::error]

        array set articles {}
        array set sources {}
        array set subscribers {}

        eval [list jlib::sendit 2 ""] $argv

        set iqP 0
        foreach array [list articles sources subscribers] {
            incr iqP
            jlib::send_iq get \
                [jlib::wrapper:createtag query \
                     -vars [list xmlns jabber:iq:private] \
                     -subtags [list [jlib::wrapper:createtag $array \
                                         -vars [list xmlns rssbot.$array]]]] \
                -connection [jlib::route ""] \
                -command [list [namespace current]::iq_private 0]
        }
        while {$iqP > 0} {
            vwait [namespace current]::iqP
        }

        loop $argv
    } result]} {
        set doneP 1
        bgerror $result
    }
}

proc rssbot::loop {argv} {
    variable loopID

    set loopID ""

    if {[catch { loop_aux $argv } result]} {
        bgerror $result
    }

    set loopID [after [expr 5*60*1000] [list [namespace current]::loop $argv]]
}

proc rssbot::loop_aux {argv} {
    variable articles
    variable sources
    variable subscribers

    array set updateP [list articles 0 sources 0 subscribers 0]

    set sites {}
    foreach jid [array names subscribers] {
        array set props $subscribers($jid)

        if {![string compare $props(status) available]} {
            foreach site $props(sites) {
                if {[lsearch -exact $sites $site] < 0} {
                    lappend sites $site
                }
            }
        }
    }

    set now [clock seconds]
    foreach site $sites {
        catch { array unset sprops }
        array set sprops [list ntime 0]
        catch { array set sprops $sources($site) }

        if {$sprops(ntime) > $now} {
            continue
        }

        if {[catch { ::http::geturl $site } httpT]} {
            ::LOG "$site: $httpT"
            continue
        }

        switch -exact -- [set status [::http::status $httpT]] {
            ok {
                if {![string match 2* [set ncode [::http::ncode $httpT]]]} {
                    ::LOG "$site: returns code $ncode"
                } else {
                    catch { unset state }
                    upvar #0 $httpT state

                    catch { unset array meta }
                    array set meta $state(meta)
                    if {![info exists meta(Last-Modified)]} {
                        set mtime $now
                    } elseif {[catch { clock scan $meta(Last-Modified) } t]} {
                        ::LOG "$site: invalid Last-Modified meta-data $meta(Last-Modified)"
                        set mtime $now
                    } else {
                        set mtime $t
                    }
                    foreach {k v} [process $site $mtime [expr $now+(5*60)] \
                                           $now [::http::data $httpT]] {
                        if {$v} {
                            set updateP($k) 1
                        }
                    }
                }
            }

            timeout
                -
            default {
                ::LOG "$site: $status"
            }
        }

        ::http::cleanup $httpT
    }

    foreach jid [array names subscribers] {
        catch { array unset props }
        array set props $subscribers($jid)

        if {[catch { set props(mtime) } mtime]} {
            set mtime 0
        }

        set xtime 0
        foreach site $props(sites) {
            foreach article [array names articles] {
                catch { array unset aprops }
                array set aprops $articles($article)

                if {$aprops(ntime) <= $now} {
                    unset articles($article)

                    set updateP(articles) 1
                    continue
                }

                if {[string first "$site," $article]} {
                    continue
                }

                if {$aprops(mtime) <= $mtime} {
                    continue
                }

                if {[catch { eval [list jlib::sendit 1 $jid] $argv \
                                  $aprops(args) } result]} {
                    ::LOG "$jid: $result"
                } else {
                    if {$xtime < $aprops(mtime)} {
                        set xtime $aprops(mtime)
                    }

                    set jlib::lib(lastwhat) $aprops(source)
                    set jlib::lib(lastwhen) $aprops(mtime)
                }
            }
        }

        if {$xtime > $mtime} {
            set updateP(subscribers) 1

            set props(mtime) $xtime
            set subscribers($jid) [array get props]
        }
    }


    foreach array [list articles sources subscribers] {
        if {$updateP($array)} {
            jlib::send_iq set \
                [jlib::wrapper:createtag query \
                     -vars [list xmlns jabber:iq:private] \
                     -subtags [list [jlib::wrapper:createtag $array \
                                         -vars [list xmlns rssbot.$array] \
                                         -chdata [array get $array]]]] \
                -connection [jlib::route ""] \
                -command [list [namespace current]::iq_private 1]
        }
    }
}


proc rssbot::process {site mtime ntime now data} {
    variable info
    variable parser
    variable stack

    variable sources

    array set info [list site $site ctime $mtime now $now articleP 0]

    set stack {}
    if {[catch { $parser parse $data } result]} {
        ::LOG "$site: $result"
    } else {
        set sources($site) [list mtime $mtime ntime $ntime]
    }

    return [list articles $info(articleP) sources $info(articleP)]
}

proc rssbot::element {tag name {av {}} args} {
    variable info
    variable stack

    variable articles

    switch -- $tag {
        begin {
            set parent [lindex [lindex $stack end] 0]
            lappend stack [list $name $av]
            switch -- $parent/$name {
                channel/title {
                    array set info [list subject ""]
                }

                channel/item
                    -
                rdf:RDF/item
                    -
                RDF/item {
                    array set info [list description "" \
                                         body        "" \
                                         url         "" \
                                         date        ""]
                }
            }
        }

        end {
            set stack [lreplace $stack end end]
            set parent [lindex [lindex $stack end] 0]

            switch -- $parent/$name {
                channel/item
                    -
                rdf:RDF/item
                    -
                RDF/item {
                }

                default {
                    return
                }
            }

            if {[string compare $info(date) ""]} {
                if {![string compare [string range $info(date) 22 22] ":"]} {
                    set info(date) [string replace $info(date) 22 22]
                }
                if {[catch { clock scan $info(date) } info(mtime)]} {
                    ::LOG "$info(site): invalid dc:date $info(date)"
                    set info(mtime) $info(ctime)
                }
            } else {
                set info(mtime) $info(ctime)
            }

            if {![string compare [set url $info(url)] ""]} {
                ::LOG "$info(site): missing URL in item"
                return
            }

            set ntime [expr $info(mtime)+(2*24*60*60)]
            if {$ntime <= $info(now)} {
                return
            }

            set site $info(site)
            if {[info exists articles($site,$url)]} {
                return
            }

            if {![string compare $info(body) ""]} {
                set info(body) [string trim "$info(description)\n$info(url)"]
            }

            set args {}
            foreach k [list subject body description url] {
                lappend args -$k [string trim $info($k)]
            }
            set articles($site,$url) \
                [list mtime  $info(mtime)                 \
                      ntime  $ntime                       \
                      source [string trim $info(subject)] \
                      args   $args]

            set info(articleP) 1
        }
    }
}

proc rssbot::pcdata {text} {
    variable info
    variable stack

    if {![string compare [string trim $text] ""]} {
        return
    }

    set name [lindex [lindex $stack end] 0]
    set parent [lindex [lindex $stack end-1] 0]
    switch -- $parent/$name {
        channel/title {
            append info(subject) $text
        }

        item/title {
            append info(description) $text
        }

        item/link {
            append info(url) $text
        }

        item/description {
            append info(body) $text
        }

        item/dc:date
            -
        item/date {
            append info(date) $text
        }
    }
}

proc rssbot::error {args} {
    return -code error [join $args " "]
}


proc rssbot::message {jid request} {
    variable loopID

    variable articles
    variable sources
    variable subscribers

    if {[catch { split [string trim $request] } args]} {
        return $args
    }

    set answer ""
    set updateP 0
    set arrayL [list subscribers]

    set fmt "%a %b %d %H:%M:%S %Z %Y"
    switch -glob -- [set arg0 [string tolower [lindex $args 0]]] {
        he* {
            set answer {commands are:
  subscribe  URL
unsubscribe [URL ...]
      reset [DATE-TIME]
       list
       dump [URL ...]
       flush
       help}
        }

        sub* {
            if {[llength $args] <= 1} {
                return "usage: subscribe URL ..."
            }

            array set props [list mtime 0 sites {} status available]
            if {([catch { array set props $subscribers($jid) }]) \
                    && ([lsearch -exact $jlib::roster(users) $jid] < 0)} {
                return "not authorized"
            }

            set s ""
            foreach arg [lrange $args 1 end] {
                if {![string compare $arg ""]} {
                    append answer $s "invalid source: empty URL"
                } elseif {[lsearch -exact $props(sites) $arg] >= 0} {
                    append answer $s "already subscribed to $arg"
                } elseif {[catch { uri::split $arg } result]} {
                    append answer $s "invalid source: $arg ($result)"
                } else {
                    lappend props(sites) $arg
                    set updateP 1

                    append answer $s "added subscription to $arg"
                }
                set s "\n"
            }
        }

        unsub* {
            if {![info exists subscribers($jid)]} {
                return "no subscriptions"
            }

            array set props $subscribers($jid)
            if {[llength $args] <= 1} {
                set props(sites) {}
                set updateP 1

                set s ""
                foreach site $props(sites) {
                    append answer $s "cancelled subscription to $site"
                    set s "\n"
                }
            } else {
                set s ""
                foreach arg [lrange $args 1 end] {
                    if {[set x [lsearch -exact $props(sites) $arg]] < 0} {
                        append answer $s "not subscribed to $arg"
                    } else {
                        set props(sites) [lreplace $props(sites) $x $x]
                        set updateP 1

                        append answer $s "cancelled subscription to $arg"
                    }
                    set s "\n"
                }
            }
        }

        reset {
            if {![info exists subscribers($jid)]} {
                return "no subscriptions"
            }

            array set props $subscribers($jid)

            append answer "subscription history reset"
            if {[llength $args] <= 1} {
                set props(mtime) 0
            } elseif {[catch { clock scan [concat [lrange $args 1 end]] \
                                     -base [clock seconds] } m]} {
                return "invalid date-time: [concat [lrange $args 1 end]] ($m)"
            } else {
                set props(mtime) $m
                append answer " to [clock format $m -format $fmt]"
            }
            set updateP 1
        }

        list {
            if {![info exists subscribers($jid)]} {
                return "no subscriptions"
            }

            array set props $subscribers($jid)

            set s ""
            foreach site $props(sites) {
                append answer $s $site
                set s "\n"
            }
        }

        dump {
            if {![info exists subscribers($jid)]} {
                return [jlib::wrapper:createtag subscriber \
                            -vars [list jid $jid]]
            }

            array set props $subscribers($jid)

            set tags {}

            if {[info exists props(mtime)]} {
                set chdata [clock format $props(mtime) -format $fmt]
            } else {
                set chdata never
            }
            lappend tags [jlib::wrapper:createtag updated -chdata $chdata]

            foreach site $props(sites) {
                if {([llength $args] > 1)
                        && ([lsearch -exact [lrange $args 1 end] $site] \
                                < 0)} {
                    continue
                }

                catch { unset array sprops }
                array set sprops $sources($site)

                set stags {}
                lappend stags [jlib::wrapper:createtag url -chdata $site]
                lappend stags [jlib::wrapper:createtag modified \
                                   -chdata [clock format $sprops(mtime) \
                                                 -format $fmt]]
                lappend stags [jlib::wrapper:createtag expires \
                                   -chdata [clock format $sprops(ntime) \
                                                 -format $fmt]]

                set atags {}
                foreach article [array names articles] {
                    if {[string first "$site," $article]} {
                        continue
                    }
                    set url [string range $article [string length $site,] end]

                    catch { array unset aprops }
                    array set aprops $articles($article)

                    set atag {}
                    lappend atag [jlib::wrapper:createtag url -chdata $url]
                    lappend atag [jlib::wrapper:createtag modified \
                                      -chdata [clock format $aprops(mtime) \
                                                    -format $fmt]]
                    lappend atag [jlib::wrapper:createtag expires \
                                      -chdata [clock format $aprops(ntime) \
                                                    -format $fmt]]
                    lappend atag [jlib::wrapper:createtag args \
                                      -chdata $aprops(args)]

                    lappend atags [jlib::wrapper:createtag article \
                                       -subtags $atag]
                }
                lappend stags [jlib::wrapper:createtag articles \
                                   -subtags $atags]

                lappend tags [jlib::wrapper:createtag site \
                                  -subtags $stags]
            }

            set answer [jlib::wrapper:createxml \
                            [jlib::wrapper:createtag subscriber \
                                 -vars [list jid $jid] \
                                 -subtags [list [jlib::wrapper:createtag \
                                                     sites -subtags $tags]]]]
        }

        flush {
            if {![info exists subscribers($jid)]} {
                return "no subscriptions"
            }

            array set props $subscribers($jid)

            foreach array [set arrayL [list articles sources]] {
                lappend arrayL $array
                array unset $array
                array set $array {}
            }
            set updateP 1

            append answer "cache flushed"
        }

        default {
            append answer "unknown request: $arg0\n"
            append answer "try \"help\" instead"
        }
    }

    if {$updateP} {
        set subscribers($jid) [array get props]

        foreach array $arrayL {
            jlib::send_iq set \
                [jlib::wrapper:createtag query \
                     -vars [list xmlns jabber:iq:private] \
                     -subtags [list [jlib::wrapper:createtag $array \
                                         -vars [list xmlns rssbot.$array] \
                                         -chdata [array get $array]]]] \
                -connection [jlib::route ""] \
                -command [list [namespace current]::iq_private 1]
        }

        if {[string compare $loopID ""]} {
            set script [lindex [after info $loopID] 0]
            after cancel $loopID
            set loopID [after idle $script]
        }

    }

    return $answer
}


proc rssbot::presence {jid status} {
    variable loopID

    variable articles
    variable sources
    variable subscribers

    if {![info exists subscribers($jid)]} {
        ::LOG "$jid not subscribed?!?"
        return
    }

    array set props $subscribers($jid)

    if {[string compare $props(status) $status]} {
        set props(status) $status
        set subscribers($jid) [array get props]

        jlib::send_iq set \
            [jlib::wrapper:createtag query \
                 -vars [list xmlns jabber:iq:private] \
                 -subtags [list [jlib::wrapper:createtag subscribers \
                                     -vars [list xmlns rssbot.subscribers] \
                                     -chdata [array get subscribers]]]] \
            -connection [jlib::route ""] \
            -command [list [namespace current]::iq_private 1]

        if {(![string compare $status available]) \
                && ([string compare $loopID ""])} {
            set script [lindex [after info $loopID] 0]
            after cancel $loopID
            set loopID [after idle $script]
        }
    }
}


proc rssbot::reconnect_aux {argv} {
    while {1} {
        after [expr 60*1000]
        if {![catch { eval [list jlib::sendit 2 ""] $argv } result]} {
            break
        }

        ::LOG $result
    }
}

proc rssbot::iq_private {setP status child} {
    global doneP

    variable iqP

    variable articles
    variable sources
    variable subscribers

    if {[set code [catch {
        if {[string compare $status OK]} {
            error "iq_private: [lindex $child 0]"
        }

        if {$setP} {
            return
        }

        jlib::wrapper:splitxml $child tag vars isempty chdata children
        set xmlns [jlib::wrapper:getattr $vars xmlns]
        jlib::wrapper:splitxml [lindex $children 0] tag vars isempty chdata \
            children
        set xmlns [jlib::wrapper:getattr $vars xmlns]

        if {[catch { llength $chdata }]} {
            error "iq_private: bad data: $chdata"
        }

        if {$isempty} {
            set chdata {}
        }
        switch -- $xmlns {
            rssbot.articles
                -
            rssbot.sources
                -
            rssbot.subscribers {
                array set [string range $xmlns 7 end] $chdata
            }

            default {
                error "iq_private: unexpected namespace: $xmlns"
            }
        }

        incr iqP -1
    } result]]} {
        if {$code == 2} {
            return
        }

        set doneP 1
        set iqP 0
        bgerror $result
    }
}


set debugP 0
set logFile ""

proc ::LOG {message} {
    global debugP logFile

    if {$debugP > 0} {
        puts stderr $message
    }

    if {([string first "DEBUG " $message] == 0) \
            || (![string compare $logFile ""]) \
            || ([catch { set fd [open $logFile { WRONLY CREAT APPEND }] }])} {
        return
    }

    regsub -all "\n" $message " " message

    set now [clock seconds]
    if {[set x [string first . [set host [info hostname]]]] > 0} {
        set host [string range $host 0 [expr $x-1]]
    }
    catch { puts -nonewline $fd \
                 [format "%s %2d %s %s personal\[%d\]: %s\n" \
                         [clock format $now -format %b] \
                         [string trimleft [clock format $now -format %d] 0] \
                         [clock format $now -format %T] $host \
                         [expr [pid]%65535] $message] }

    catch { close $fd }
}

proc ::bgerror {err} {
    global errorInfo

    ::LOG "$err\n$errorInfo"
}


set status 1

array set jlib::lib [list lastwhen [clock seconds] lastwhat ""]

if {(([set x [lsearch -exact $argv -help]] >= 0) \
            || ([set x [lsearch -exact $argv --help]] >= 0)) \
        && (![expr $x%2])} {
    puts stdout "usage: rssbot.tcl ?options...?
            -pidfile     file
            -from        jid
            -password    string
            -tls         boolean (e.g., 'true')

The file .jsendrc.tcl is consulted, e.g.,

    set args {-from fred@example.com/bedrock -password wilma}

for default values."

    set status 0
} elseif {[expr $argc%2]} {
    puts stderr "usage: rssbot.tcl ?-key value?..."
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
            set argv [eval [list linsert $argv 0] $args]
        }
    }
} result]} {
    puts stderr "error in $file: $result"
} else {
    if {([set x [lsearch -exact $argv -debug]] >= 0) && (![expr $x%2])} {
        switch -- [string tolower [lindex $argv [expr $x+1]]] {
            1 - true - yes - on { set debugP 1 }
        }
    }
    if {([set x [lsearch -exact $argv -logfile]] >= 0) && (![expr $x%2])} {
        set logFile [lindex $argv [expr $x+1]]
    }

    set keep_alive 1
    set keep_alive_interval 5

    if {([set x [lsearch -exact $argv "-pidfile"]] >= 0) && (![expr $x%2])} {
        set fd [open [set pf [lindex $argv [expr $x+1]]] \
                     { WRONLY CREAT TRUNC }]
        puts $fd [pid]
        close $fd
    }

    after idle [list rssbot::begin $argv]

    set doneP 0
    vwait doneP

    catch { file delete -- $pf }

    set status 0
}

exit $status

# vim:ft=tcl:ts=8:sw=4:sts=4:et
