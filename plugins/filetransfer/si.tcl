# si.tcl --
#
#       File transfer via Stream Initiation (XEP-0096)

namespace eval si {
    variable winid 0
    variable chunk_size 1024

    variable options

    custom::defgroup {Stream Initiation} \
        [::msgcat::mc "Stream initiation options."] \
        -group {File Transfer}

    set ::NS(file-transfer) http://jabber.org/protocol/si/profile/file-transfer
    disco::register_feature $::NS(file-transfer)
}

###############################################################################

proc si::send_file {token} {
    upvar #0 $token state
    variable chunk_size

    if {![info exists state(fd)]} return

    set state(stream) [si::newout $state(xlib) $state(jid)]

    set profile [::xmpp::xml::create file \
                        -xmlns $::NS(file-transfer) \
                        -attrs [list name $state(name) \
                                     size $state(size)] \
                        -subelement [::xmpp::xml::create desc \
                                            -cdata $state(desc)]]

    si::connect $state(stream) $chunk_size application/octet-stream \
                $::NS(file-transfer) $profile \
                [list [namespace current]::send_file_result $token]
}

###############################################################################

proc si::send_file_result {token res} {
    upvar #0 $token state

    if {![info exists state(fd)]} return

    if {![lindex $res 0]} {
        {*}$state(command) error \
                   [::msgcat::mc "Request failed: %s" [lindex $res 1]]
        return
    }

    set_status [::msgcat::mc "Transferring..."]
    after idle [list [namespace current]::send_chunk $token]
}

proc si::send_chunk {token} {
    upvar #0 $token state
    variable chunk_size

    if {![info exists state(fd)]} return

    set chunk [read $state(fd) $chunk_size]
    if {$chunk != ""} {
        si::send_data $state(stream) $chunk \
                      [list [namespace current]::send_chunk_response $token]
    } else {
        {*}$state(command) ok
    }
}

proc si::send_chunk_response {token res} {
    upvar #0 $token state

    if {![info exists state(fd)]} return

    if {![lindex $res 0]} {
        {*}$state(command) error \
                   [::msgcat::mc "Transfer failed: %s" [lindex $res 1]]
        return
    }

    {*}$state(command) progress [tell $state(fd)]
    after idle [list [namespace current]::send_chunk $token]
}

###############################################################################

proc si::send_file_close {token} {
    upvar #0 $token state

    if {![info exists state(stream)]} return

    catch {si::close $state(stream)}
    catch {si::freeout $state(stream)}
}

###############################################################################
###############################################################################

proc si::recv_file_dialog {xlib from lang id name size date hash desc command} {
    variable winid

    set token [namespace current]::[incr winid]
    upvar #0 $token state

    set w .rfd$winid
    set state(w) $w

    set state(xlib) $xlib
    set state(jid) $from
    set state(lang) $lang
    set state(id) $id

    Dialog $w -title [::msgcat::mc "Receive file from %s" $from] \
        -anchor e -transient 0 \
        -modal none -default 0 -cancel 1


    set f [$w getframe]

    Label $f.lname -text [::msgcat::mc "Name:"]
    Label $f.name -text $name

    Label $f.lsize -text [::msgcat::mc "Size:"]
    Label $f.size -text $size

    Label $f.ldesc -text [::msgcat::mc "Description:"]
    Message $f.desc -width 10c -text $desc

    set dir $::ft::options(download_dir)
    Label $f.lsaveas -text [::msgcat::mc "Save as:"]
    Entry $f.saveas -textvariable ${token}(filename)

    set state(f) $f

    set state(size) $size

    set state(dir) $dir
    set state(name) $name
    set state(filename) [file join $dir $name]
    Button $f.browsefile -text [::msgcat::mc "Browse..."] \
        -command [list [namespace current]::set_receive_file_name $token $w]

    set state(progress) 0

    # Working around a bug in ProgressBar:
    # crash when setting PB variable while -maximum is 0:
    if {$size > 0} {
        Progressbar $f.pb -variable ${token}(progress)
        $f.pb configure -maximum $size
        grid $f.pb  -row 5 -column 0 -sticky ew -columnspan 3 -pady 2m
    }

    # grid row 0 is used for displaying error messages

    grid $f.lname   -row 1 -column 0 -sticky e
    grid $f.name    -row 1 -column 1 -sticky w

    grid $f.lsize   -row 2 -column 0 -sticky e
    grid $f.size    -row 2 -column 1 -sticky w

    grid $f.ldesc   -row 3 -column 0 -sticky en
    grid $f.desc    -row 3 -column 1 -sticky ewns -columnspan 2 -pady 1m

    grid $f.lsaveas -row 4 -column 0 -sticky e
    grid $f.saveas  -row 4 -column 1 -sticky ew
    grid $f.browsefile  -row 4 -column 2 -sticky ew

    grid columnconfigure $f 1 -weight 1 -minsize 8c
    grid rowconfigure $f 3 -weight 1

    $w add -text [::msgcat::mc "Receive"] -command \
        [namespace code [list recv_file_start $token $w $command]]
    $w add -text [::msgcat::mc "Cancel"] -command \
        [namespace code [list recv_file_cancel $token $w $command]]

    bind $w <Destroy> \
         [double% [namespace code [list recv_file_cancel $token $w $command]]]

    $w draw
    return
}

proc si::set_receive_file_name {token w} {
    upvar #0 $token state

    set file [tk_getSaveFile -initialdir $state(dir) \
                             -initialfile $state(name) \
                             -parent $w]
    if {$file != ""} {
        set state(filename) $file
    }
}

###############################################################################

proc si::recv_file_cancel {token w command} {
    upvar #0 $token state

    bind $w <Destroy> {}
    destroy $w
    {*}$command error \
               [::xmpp::stanzaerror::error cancel not-allowed \
                        -text [::trans::trans $state(lang) \
                                              "File transfer is refused"]]
    return
}

###############################################################################

proc si::recv_file_start {token w command} {
    upvar #0 $token state

    ft::hide_error_msg $state(f)

    if {[catch {open $state(filename) w} fd]} {
        ft::report_cannot_open_file $state(f) $state(filename) \
                                    [ft::get_POSIX_error_desc]
        return
    }

    fconfigure $fd -translation binary

    $state(w) itemconfigure 0 -state disabled
    $state(w) itemconfigure 1 -command [namespace code [list recv_file_close $token $w %W]]
    bind $w <Destroy> [namespace code [list recv_file_close [double% $token] [double% $w] %W]]

    if {[catch {si::newin $state(xlib) $state(jid) $state(id)} stream]} {
        # Return error to the sender but leave transfer window with disabled
        # 'Receive' button and error message.
        {*}$command error
                   [::xmpp::stanzaerror::error modify bad-request \
                                -text [::trans::trans $state(lang) \
                                                      "Stream ID is in use"]]
        ft::report_error $state(f) \
                [::msgcat::mc "Receive error: Stream ID is in use"]
        return
    }

    set state(stream) $stream

    set state(fd) $fd

    si::set_readable_handler \
        $stream [list [namespace current]::recv_file_chunk $token]
    si::set_closed_handler \
        $stream [list [namespace current]::closed $token]

    {*}$command ok {}
    return
}

###############################################################################

proc si::recv_file_chunk {token stream} {
    upvar #0 $token state

    if {![info exists state(w)] || ![winfo exists $state(w)]} {return 0}
    if {![info exists state(stream)] || !($state(stream) == $stream)} {return 0}

    set fd $state(fd)
    set filename $state(filename)
    set data [si::read_data $stream]

    debugmsg filetransfer "RECV into $filename data $data"

    puts -nonewline $fd $data
    set state(progress) [tell $fd]

    return 1
}

###############################################################################

proc si::closed {token stream} {
    upvar #0 $token state

    if {![info exists state(w)] || ![winfo exists $state(w)]} {return 0}
    if {![info exists state(stream)] || !($state(stream) == $stream)} {return 0}

    debugmsg filetransfer "CLOSE"
    destroy $state(w)
}

###############################################################################

proc si::recv_file_close {token w1 w2} {
    upvar #0 $token state

    if {$w1 != $w2} return

    catch {close $state(fd)}
    catch {si::freein $state(stream)}
    catch {unset $token}
}

###############################################################################
###############################################################################

proc si::si_handler {xlib from lang id mimetype child command} {
    debugmsg filetransfer "SI set: [list $from $child]"

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    if {$tag == "file"} {
        set desc ""
        foreach item $subels {
            ::xmpp::xml::split $item stag sxmlns sattrs scdata ssubels

            switch -- $stag {
                desc {set desc $scdata}
            }
        }

        return [recv_file_dialog \
                        $xlib \
                        $from \
                        $lang \
                        $id \
                        [::xmpp::xml::getAttr $attrs name] \
                        [::xmpp::xml::getAttr $attrs size] \
                        [::xmpp::xml::getAttr $attrs date] \
                        [::xmpp::xml::getAttr $attrs hash] \
                        $desc \
                        $command]
    } else {
        return [list error modify bad-request]
    }
}

si::register_profile $::NS(file-transfer) [namespace current]::si::si_handler

###############################################################################

ft::register_protocol si \
    -priority 10 \
    -label "Stream Initiation" \
    -send [namespace current]::si::send_file \
    -close [namespace current]::si::send_file_close

# vim:ft=tcl:ts=8:sw=4:sts=4:et
