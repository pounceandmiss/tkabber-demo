# filetransfer.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements the user
#       interface part and infrastructure (registering different protocols)
#       for file transfer.

namespace eval ft {
    custom::defgroup {File Transfer} [::msgcat::mc "File Transfer options."] \
        -group Tkabber

    variable default_dir

    switch -- $::tcl_platform(platform) {
        windows {
            if {[info exists $::env(TEMP)]} {
                set default_dir $::env(TEMP)
            } else {
                set default_dir "C:\\TEMP"
            }
        }
        default {
            set default_dir "/tmp"
        }
    }
    # TODO macintosh?
    custom::defvar options(download_dir) $default_dir \
        [::msgcat::mc "Default directory for downloaded files."] \
        -type string -group {File Transfer}

    variable winid 0

    variable protocols
    set protocols(names) {}
}

###############################################################################

proc ft::register_protocol {name args} {
    variable protocols

    set priority 50
    set label $name

    foreach {key val} $args {
        switch -- $key {
            -priority { set priority $val }
            -label    { set label $val }
            -options  { set options $val }
            -send     { set send $val }
            -receive  { set receive $val }
            -close    { set close $val }
            -closed   { set closed $val }
            default   {
                return -code error "[namespace current]::register_protocol:\
                                    Illegal option $key"
            }
        }
    }

    lappend protocols(names) [list $name $priority]
    set protocols(names) [lsort -integer -index 1 $protocols(names)]

    set protocols(label,$name) $label

    foreach option {options send receive close closed} {
        if {[info exists $option]} {
            set protocols($option,$name) [set $option]
        }
    }
}

proc ft::unregister_protocol {name} {
    variable protocols

    while {[set idx [lsearch -glob $protocols(names) [list $name *]]] >= 0} {
        set protocols(names) [lreplace $protocols(names) $idx $idx]
    }

    array unset protocols *,$name
}

plugins::load [file join plugins filetransfer]

###############################################################################

namespace eval ft {
    variable protocols

    variable values {}
    variable name_prio
    variable name
    variable priority
    foreach name_prio $protocols(names) {
        lassign $name_prio name priority
        lappend values $name $protocols(label,$name)
    }

    custom::defvar options(default_proto) [lindex $values 0] \
        [::msgcat::mc "Default protocol for sending files."] \
        -type options \
        -values $values \
        -group {File Transfer}
}

###############################################################################

proc ft::get_POSIX_error_desc {} {
    global errorCode
    set class [lindex $errorCode 0]
    if {$class != "POSIX"} {
        return [::msgcat::mc "unknown"]
    } else {
        return [::msgcat::mc [lindex $errorCode 2]]
    }
}

proc ft::report_cannot_open_file {f filename error} {
    report_error $f [::msgcat::mc "Can't open file \"%s\": %s" \
                                  $filename $error]
}

proc ft::report_error {f errormsg} {
    set m $f.errormsg
    catch {destroy $m}
    Message $m -aspect 50000 \
               -text $errormsg \
               -pady 1m
    $m configure -foreground [option get $m errorForeground Message]
    grid $m -row 0 -column 0 -sticky ewns -columnspan 4
}

proc ft::hide_error_msg {f} {
    catch {destroy $f.errormsg}
}

###############################################################################

proc ft::create_menu {m xlib jid} {
    variable protocols

    if {[llength $protocols(names)] > 0} {
        $m add command -label [::msgcat::mc "Send file..."] \
                       -command [list [namespace current]::send_file_dialog \
                                      $xlib $jid]
    }
}

hook::add chat_create_user_menu_hook \
    [namespace current]::ft::create_menu 46
hook::add roster_create_groupchat_user_menu_hook \
    [namespace current]::ft::create_menu 46
hook::add roster_jid_popup_menu_hook \
    [namespace current]::ft::create_menu 46
hook::add message_dialog_menu_hook \
    [namespace current]::ft::create_menu 46
hook::add search_popup_menu_hook \
    [namespace current]::ft::create_menu 46

###############################################################################
#
# Draw a send file dialog
#

proc ft::send_file_dialog {xlib jid args} {
    variable winid
    variable options
    variable protocols

    set token [namespace current]::[incr winid]
    upvar #0 $token state

    set w .sfd$winid
    set state(w) $w
    set state(jid) $jid
    set state(xlib) $xlib

    Dialog $w -title [::msgcat::mc "Send file to %s" $jid] \
              -anchor e -modal none \
              -transient 0 -default 0 -cancel 1

    $w add -text [::msgcat::mc "Send"] \
           -command [list [namespace current]::send_file_negotiate $token]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    bind $w <Destroy> \
            [list [namespace current]::send_file_close [double% $token] %W]

    set f [$w getframe]
    set state(f) $f

    Label $f.lfile -text [::msgcat::mc "File path:"]
    Entry $f.file -textvariable ${token}(filename)
    Button $f.browsefile -text [::msgcat::mc "Browse..."] \
        -command [list [namespace current]::set_send_file_name $token $w]

    Label $f.ldesc -text [::msgcat::mc "Description:"]
    set sw [ScrolledWindow $f.sw -scrollbar vertical]
    textUndoable $f.desc -width 55 -height 4 -wrap word
    $sw setwidget $f.desc

    set values {}
    foreach name_prio $protocols(names) {
        lassign $name_prio name priority
        lappend values $protocols(label,$name)
        if {$options(default_proto) == $name} {
            set state(protocol) $protocols(label,$name)
        }
    }
    if {![info exists state(protocol)]} {
        set state(protocol) [lindex $values 0]
    }
    Label $f.lproto -text [::msgcat::mc "Protocol:"]
    OptionMenu $f.proto ${token}(protocol) {*}$values

    Progressbar $f.pb -variable ${token}(progress)
    set state(pb) $f.pb
    set state(progress) 0

    # Grid row 0 is used for displaying error messages

    grid $f.lfile      -row 1 -column 0 -sticky e
    grid $f.file       -row 1 -column 1 -sticky ew
    grid $f.browsefile -row 1 -column 2 -sticky ew

    grid $f.ldesc -row 2 -column 0 -sticky en
    grid $f.sw    -row 2 -column 1 -sticky ewns -columnspan 2

    grid $f.lproto -row 3 -column 0 -sticky e
    grid $f.proto  -row 3 -column 1 -sticky ew -columnspan 2 -pady 1m

    # Grid row 4 vill be used for displaying protocol options

    grid $f.pb -row 5 -column 0 -sticky ew -columnspan 3

    grid columnconfigure $f 1 -weight 1
    grid rowconfigure $f 2 -weight 1

    $w draw $f.file
}

proc ft::set_send_file_name {token w} {
    variable $token
    upvar 0 $token state

    set file [tk_getOpenFile -parent $w]
    if {$file != ""} {
        set state(filename) $file
    }
}

###############################################################################

proc ft::send_file_negotiate {token} {
    upvar #0 $token state
    variable chunk_size
    variable protocols

    hide_error_msg $state(f)
    $state(w) itemconfigure 0 -state disabled

    set state(desc) [$state(f).desc get 0.0 "end -1c"]

    if {[catch {open $state(filename)} fd]} {
        report_cannot_open_file $state(f) $state(filename) \
                                [get_POSIX_error_desc]
        $state(w) itemconfigure 0 -state normal
        return
    }

    debugmsg filetransfer "SENDFILE: $state(filename)"

    set state(fd) $fd
    fconfigure $fd -translation binary

    set state(name) [file tail $state(filename)]
    set size [file size $state(filename)]
    set state(size) $size

    if {$size == 0} {
        $state(pb) configure -maximum 1
        set state(progress) -1
    } else {
        $state(pb) configure -maximum $size
    }

    foreach name_prio $protocols(names) {
        lassign $name_prio proto priority
        if {$state(protocol) == $protocols(label,$proto)} {
            break
        }
    }
    set state(proto) $proto

    set state(command) [list [namespace current]::send_file_callback $token]

    # Use $token as filetransfer ID and state array variable
    {*}$protocols(send,$proto) $token
}

###############################################################################

proc ft::send_file_close {token w} {
    upvar #0 $token state
    variable protocols

    if {[winfo toplevel $w] != $w} return

    catch {{*}$protocols(close,$state(proto)) $token}
    catch {close $state(fd)}
    catch {unset $token}
}

###############################################################################

proc ft::send_file_callback {token res {msg ""}} {
    upvar #0 $token state

    # Peer's reply may arrive after window is closed.
    if {![info exists state(w)] || ![winfo exists $state(w)]} return

    switch -- $res {
        error {
            if {$state(size) > 0} {
                set state(progress) 0
            }
            report_error $state(f) $msg
            catch {{*}$protocols(close,$state(proto)) $token}
            catch {close $state(fd)}
            $state(w) itemconfigure 0 -state normal
        }
        progress {
            if {$state(size) > 0} {
                set state(progress) $msg
            }
        }
        default {
            destroy $state(w)
        }
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
