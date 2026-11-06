# http.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements file
#       transfer via Out of Band Data (XEP-0066).

namespace eval http {
    variable winid 0
    variable chunk_size 4096

    variable options

    custom::defgroup HTTP \
        [::msgcat::mc "HTTP options."] \
        -group {File Transfer}

    custom::defvar options(port) 0 \
        [::msgcat::mc "Port for outgoing HTTP file transfers (0 for assigned\
                       automatically). This is useful when sending files from\
                       behind a NAT with a forwarded port."] \
        -group HTTP -type integer

    custom::defvar options(host) "" \
        [::msgcat::mc "Force advertising this hostname (or IP address) for\
                       outgoing HTTP file transfers."] \
        -group HTTP -type string

}

###############################################################################

proc http::send_file {token} {
    upvar #0 $token state
    variable options

    if {![info exists state(fd)]} return

    #set ip [$f.ip get]
    #label $f.lip -text [::msgcat::mc "IP address:"]
    #entry $f.ip -textvariable [list [namespace current]::ip$winid]
    #variable ip$winid 127.0.0.1

    set host 127.0.0.1
    if {$options(host) ne ""} {
        set host $options(host)
    } else {
        catch {
            set host [info hostname]
            set host [lindex [host_info addresses $host] 0]
        }
        if {[::xmpp::ip $state(xlib)] ne ""} {
            set host [::xmpp::ip $state(xlib)]
        }
    }
    set state(host) $host

    set state(servsock) \
        [socket -server \
             [list [namespace current]::send_file_accept $token] $options(port)]

    lassign [fconfigure $state(servsock) -sockname] addr hostname port

    set url "http://$state(host):$port/[file tail $state(filename)]"

    ::xmpp::sendIQ $state(xlib) set \
        -query [::xmpp::xml::create query \
                           -xmlns jabber:iq:oob \
                           -subelement [::xmpp::xml::create url \
                                               -cdata $url] \
                           -subelement [::xmpp::xml::create desc \
                                               -cdata $state(desc)]] \
        -to $state(jid) \
        -command [list [namespace current]::send_file_error_handler $token]
}

###############################################################################

proc http::send_file_error_handler {token res child} {
    upvar #0 $token state

    if {![info exists state(fd)]} return
    if {$res eq "ok"} return

    {*}$state(command) error \
         [::msgcat::mc "Request failed: %s" [error_to_string $child]]
}

###############################################################################

proc http::send_file_accept {token chan addr port} {
    upvar #0 $token state

    if {![info exists state(fd)]} return

    variable chanreadable$chan

    if {[info exists state(chan)]} {
        close $chan
        return
    } else {
        set state(chan) $chan
    }

    set size $state(size)

    fconfigure $chan -blocking 0 -translation binary -buffering line
    fileevent $chan readable [list set [namespace current]::chanreadable$chan 1]

    set request " "

    while {$request ne ""} {
        vwait [namespace current]::chanreadable$chan
        set request [gets $chan]
        debugmsg filetransfer $request
    }

    fileevent $chan readable {}
    unset chanreadable$chan

    fconfigure $chan -translation binary

    puts -nonewline $chan "HTTP/1.0 200 OK\n"
    puts -nonewline $chan "Content-Length: $size\n"
    puts -nonewline $chan "Content-Type: application/octet-stream\n\n"

    fileevent $chan writable \
        [list [namespace current]::send_file_transfer_chunk $token $chan]
}

###############################################################################

proc http::send_file_transfer_chunk {token chan} {
    upvar #0 $token state
    variable chunk_size

    if {![info exists state(fd)]} return

    set chunk [read $state(fd) $chunk_size]
    if {$chunk ne ""} {
        if {[catch {puts -nonewline $chan $chunk}]} {
            {*}$state(command) error "File transfer failed"
        } else {
            {*}$state(command) progress [tell $state(fd)]
        }
    } else {
        {*}$state(command) ok
    }
}

###############################################################################

proc http::send_file_close {token} {
    upvar #0 $token state

    if {![info exists state(fd)]} return

    catch {close $state(chan)}
    catch {close $state(servsock)}
    catch {
        variable chanreadable$state(chan)
        unset chanreadable$state(chan)
    }
}

###############################################################################
###############################################################################

proc http::recv_file_dialog {from lang urls desc} {
    variable winid
    variable result

    set w .ftrfd$winid

    while {[winfo exists $w]} {
        incr winid
        set w .ftrfd$winid
    }

    set url [lindex $urls 0]

    Dialog $w -title [::msgcat::mc "Receive file from %s" $from] \
        -anchor e -transient 0 \
        -modal none -default 0 -cancel 1

    set f [$w getframe]

    Label $f.lurl -text [::msgcat::mc "URL:"]
    Label $f.url -text $url

    Label $f.ldesc -text [::msgcat::mc "Description:"]
    Message $f.desc -width 10c -text $desc

    set dir $::ft::options(download_dir)
    set fname [file tail $url]
    Label $f.lsaveas -text [::msgcat::mc "Save as:"]
    Entry $f.saveas -textvariable [list [namespace current]::saveas$winid]
    variable saveas$winid [file join $dir $fname]
    Button $f.browsefile -text [::msgcat::mc "Browse..."] \
        -command [list [namespace current]::set_receive_file_name $w $winid $dir $fname]

    Progressbar $f.pb -variable [list [namespace current]::progress$f.pb]
    variable progress$f.pb 0

    grid $f.lurl    -row 0 -column 0 -sticky e
    grid $f.url     -row 0 -column 1 -sticky w -columnspan 2

    grid $f.ldesc   -row 1 -column 0 -sticky en
    grid $f.desc    -row 1 -column 1 -sticky ewns -columnspan 2 -pady 1m

    grid $f.lsaveas -row 2 -column 0 -sticky e
    grid $f.saveas  -row 2 -column 1 -sticky ew
    grid $f.browsefile -row 2 -column 2 -sticky ew

    grid $f.pb      -row 3 -column 0 -sticky ew -columnspan 3 -pady 2m

    grid columnconfigure $f 1 -weight 1 -minsize 8c
    grid rowconfigure $f 1 -weight 1

    $w add -text [::msgcat::mc "Receive"] \
        -command [list [namespace current]::recv_file_start $winid $from $lang $url]
    $w add -text [::msgcat::mc "Cancel"] \
        -command [list destroy $w]
    bind .ftrfd$winid <Destroy> \
         [double% [list [namespace current]::recv_file_cancel $winid $lang]]

    $w draw
    vwait [namespace current]::result($winid)
    set res $result($winid)
    unset result($winid)
    incr winid
    return $res
}

proc http::set_receive_file_name {w winid dir fname} {
    variable saveas$winid

    set file [tk_getSaveFile -parent $w -initialdir $dir -initialfile $fname]
    if {$file ne ""} {
        set saveas$winid $file
    }
}

package require http 2

proc http::recv_file_start {winid from lang url} {
    variable saveas$winid
    variable chunk_size
    variable result
    variable fds

    set filename [set saveas$winid]

    .ftrfd$winid itemconfigure 0 -state disabled
    set f [.ftrfd$winid getframe]

    set fd [open $filename w]
    fconfigure $fd -translation binary
    set fds($winid) $fd

    set geturl \
        [list ::http::geturl $url -channel $fd \
              -blocksize $chunk_size \
              -progress [list [namespace current]::recv_file_progress $f.pb] \
              -command [list [namespace current]::recv_file_finish $winid $lang]]

    if {[package vcompare 2.3.3 [package present http]] <= 0} {
        lappend geturl -binary 1
    }

    if {[catch $geturl token]} {
        bind .ftrfd$winid <Destroy> {}
        destroy .ftrfd$winid
        # TODO: More precise error messages?
        set result($winid) \
            [list error cancel item-not-found \
                  -text [::trans::trans $lang "File not found"]]
        after idle [list MessageDlg .ftrecv_error$winid \
                         -aspect 50000 \
                         -icon error \
                         -message [::msgcat::mc \
                                       "Can't receive file: %s" $token] \
                         -type user \
                         -buttons ok \
                         -default 0 \
                         -cancel 0]
    } else {
        bind .ftrfd$winid <Destroy> \
             [double% [list [namespace current]::recv_file_cancel $winid $lang $token]]
    }
}

proc http::recv_file_progress {pb token total current} {
    variable progress$pb
    debugmsg filetransfer "$total $current"
    $pb configure -maximum $total
    set progress$pb $current
}

proc http::recv_file_finish {winid lang token} {
    variable result
    variable fds

    if {[info exists fds($winid)]} {
        close $fds($winid)
        unset fds($winid)
    }

    upvar #0 $token state
    debugmsg filetransfer "transfer $state(status) $state(http)"

    bind .ftrfd$winid <Destroy> {}
    destroy .ftrfd$winid

    if {[::http::ncode $token] == 200} {
        set result($winid) {result {}}
    } else {
        # TODO: More precise error messages?
        set result($winid) \
            [list error cancel item-not-found \
                  -text [::trans::trans $lang "File not found"]]
        after idle [list MessageDlg .ftrecv_error$winid \
                         -aspect 50000 \
                         -icon error \
                         -message [::msgcat::mc \
                                       "Can't receive file: %s" [::http::code $token]] \
                         -type user \
                         -buttons ok \
                         -default 0 \
                         -cancel 0]
    }
}

proc http::recv_file_cancel {winid lang {token ""}} {
    variable result
    variable fds

    if {[info exists fds($winid)]} {
        close $fds($winid)
        unset fds($winid)
    }

    bind .ftrfd$winid <Destroy> {}

    if {$token ne ""} {
        ::http::reset $token cancelled
    }
    set result($winid) \
        [list error cancel not-allowed \
              -text [::trans::trans $lang "File transfer is refused"]]
}

###############################################################################

proc http::iq_handler {xlib from child args} {
    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    set urls ""
    set desc ""

    foreach child $subels {
        ::xmpp::xml::split $child stag sxmlns sattrs scdata ssubels
        switch -- $stag {
            url  {lappend urls $scdata}
            desc {set desc $scdata}
        }
    }

    set lang [::xmpp::xml::getAttr $args -lang en]

    return [recv_file_dialog $from $lang $urls $desc]
}

::xmpp::iq::register set query jabber:iq:oob \
                     [namespace current]::http::iq_handler

###############################################################################

ft::register_protocol http \
    -priority 30 \
    -label "HTTP" \
    -send [namespace current]::http::send_file \
    -close [namespace current]::http::send_file_close

# vim:ft=tcl:ts=8:sw=4:sts=4:et
