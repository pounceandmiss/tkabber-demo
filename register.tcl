# register.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements user
#       interface for registering protocol (XEP-0077).

package require xmpp::register

namespace eval register {}

proc register::open {xlib jid args} {
    variable winid

    if {![info exists winid]} {
        set winid 0
    }

    set commands {}
    foreach {key val} $args {
        switch -- $key {
            -command { set commands [list $val] }
        }
    }

    set w .register[incr winid]

    Toplevel $w
    wm group $w .
    set title [::msgcat::mc "Register in %s" $jid]
    wm title $w $title
    wm iconname $w $title
    wm transient $w .
    if {$::tcl_platform(platform) == "macintosh"} {
        catch { unsupported1 style $w floating sideTitlebar }
    } elseif {$::aquaP} {
        ::tk::unsupported::MacWindowStyle style $w floating {closeBox}
    }
    wm resizable $w 0 0

    set hf [Frame $w.error]
    set vf [Frame $w.vf]

    set sw [ScrolledWindow $w.sw]
    set sf [ScrollableFrame $w.fields -constrainedwidth yes]
    set f [$sf getframe]
    $sf configure -height 10
    $sw setwidget $sf

    bindscroll $f $sf

    set bbox [ButtonBox $w.bbox -spacing 0 -padx 2m -default 0]
    $bbox add -text [::msgcat::mc "Register"] \
        -command [namespace code [list Register $w $f $xlib $jid \
                                                $commands false]] \
        -state disabled
    $bbox add -text [::msgcat::mc "Unregister"] \
        -command [namespace code [list Unregister $w $xlib $jid $commands]] \
        -state disabled
    $bbox add -text [::msgcat::mc "Cancel"] \
        -command [namespace code [list Cancel $w $commands]]
    bind $w <Return> "ButtonBox::invoke [double% $bbox] default"
    bind $w <Escape> "ButtonBox::invoke [double% $bbox] 2"
    pack $bbox -padx 2m -pady 2m -anchor e -side bottom

    pack [Frame $w.sep -height 0] -side bottom

    pack $hf -side top
    pack $vf -side left -pady 2m
    pack $sw -side top -expand yes -fill both -padx 2m -pady 2m

    bind $f <Destroy> [list data::cleanup %W]

    wm withdraw $w

    ::xmpp::register::request $xlib $jid \
        -command [namespace code [list RecvFields $w $f $xlib $jid $commands]]
}

proc register::Cancel {w commands} {
    destroy $w
    if {[llength $commands] > 0} {
        uplevel #0 [lindex $commands 0] [list abort {}]
    }
}

proc register::RecvFields {w f xlib jid commands status fields args} {
    debugmsg register "$status $fields"

    if {![winfo exists $w]} {
        # User may have already destroyed this window
        return
    }

    switch -- $status {
        error {
            destroy $w
            MessageDlg ${w}_err -aspect 50000 -icon error \
                -message [::msgcat::mc "Registration: %s" \
                                       [error_to_string $fields]] \
                -type user -buttons ok -default 0 -cancel 0
            if {[llength $commands] > 0} {
                uplevel #0 [lindex $commands 0] [list $status $fields]
            }
        }
        ok {
            foreach {key val} $args {
                switch -- $key {
                    -old {
                        $w.bbox itemconfigure 0 \
                                -command [namespace code [list Register $w $f \
                                                               $xlib $jid \
                                                               $commands $val]]
                    }
                }
            }

            set focus [data::fill_fields_x $f $fields]

            $w.bbox itemconfigure 0 -state normal
            if {![::xmpp::jid::equal $jid [connection_server $xlib]]} {
                $w.bbox itemconfigure 1 -state normal
            }

            update idletasks
            $w.error configure \
                     -width [expr {[winfo reqwidth $f] + [winfo pixels $f 1c]}]

            set h [winfo reqheight $f]
            set sh [winfo screenheight $w]
            if {$h > $sh - [winfo pixels $f 5c]} {
                set h [expr {$sh - [winfo pixels $f 5c]}]
            }
            $w.vf configure -height $h
            wm deiconify $w

            if {$focus != ""} {
                focus $focus
            }
        }
        default {
            destroy $w
        }
    }
}

proc register::Register {w f xlib jid commands old} {
    variable data

    destroy $w.error.msg
    $w.bbox itemconfigure 0 -state disabled
    $w.bbox itemconfigure 1 -state disabled

    set fields [data::get_fields $f]

    ::xmpp::register::submit $xlib $jid $fields \
        -command [namespace code [list RecvResult $w $xlib $jid $commands]] \
        -old $old
}


proc register::Unregister {w xlib jid commands} {
    variable data

    destroy $w.error.msg
    $w.bbox itemconfigure 0 -state disabled
    $w.bbox itemconfigure 1 -state disabled

    ::xmpp::register::remove $xlib $jid \
        -command [namespace code [list RecvResult $w $xlib $jid $commands]]
}

proc register::password {xlib} {
    variable winid

    if {![info exists winid]} {
        set winid 0
    }

    set w .register[incr winid]

    Toplevel $w
    wm group $w .
    set title \
        [::msgcat::mc "Change Password for %s" [connection_bare_jid $xlib]]
    wm title $w $title
    wm iconname $w $title
    wm transient $w .
    if {$::tcl_platform(platform) == "macintosh"} {
        catch { unsupported1 style $w floating sideTitlebar }
    } elseif {$::aquaP} {
        ::tk::unsupported::MacWindowStyle style $w floating {closeBox}
    }
    wm resizable $w 0 0

    set hf [Frame $w.error]
    set vf [Frame $w.vf]

    set sw [ScrolledWindow $w.sw]
    set sf [ScrollableFrame $w.fields -constrainedwidth yes]
    set f [$sf getframe]
    $sf configure -height 10
    $sw setwidget $sf

    bindscroll $f $sf

    set bbox [ButtonBox $w.bbox -spacing 0 -padx 2m -default 0]
    $bbox add -text [::msgcat::mc "Submit"] \
        -command [namespace code [list Password $w $f $xlib]]
    $bbox add -text [::msgcat::mc "Cancel"] -command [list destroy $w]
    bind $w <Return> "ButtonBox::invoke [double% $bbox] default"
    bind $w <Escape> "ButtonBox::invoke [double% $bbox] 1"
    pack $bbox -padx 2m -pady 2m -anchor e -side bottom

    pack [Frame $w.sep -height 0] -side bottom

    pack $hf -side top
    pack $vf -side left -pady 2m
    pack $sw -side top -expand yes -fill both -padx 2m -pady 2m

    bind $f <Destroy> [list data::cleanup %W]

    set fields \
        [list instructions [::msgcat::mc "Enter the new password for %s" \
                                         [connection_bare_jid $xlib]] \
              field [list username hidden "" "" false \
                          {} [list [connection_user $xlib]] {}] \
              field [list password text-private \
                          [::msgcat::mc "New password:"] "" false \
                          {} {} {}]]

    wm withdraw $w

    RecvFields $w $f $xlib "" {} ok $fields
}

proc register::Password {w f xlib} {
    variable data

    if {![winfo exists $w]} {
        # User may have already destroyed this window
        return
    }

    destroy $w.error.msg
    $w.bbox itemconfigure 0 -state disabled

    set username [connection_user $xlib]
    set password ""
    foreach {var values} [data::get_fields $f] {
        switch -- $var {
            username {
                set username [lindex $values 0]
            }
            password {
                set password [lindex $values 0]
            }
        }
    }

    ::xmpp::register::password $xlib $username $password \
        -command [namespace code [list RecvResult $w $xlib "" {}]]
}

proc register::RecvResult {w xlib jid commands status xml} {
    variable data

    debugmsg register "$status $xml"

    if {![winfo exists $w]} {
        # User may have already destroyed this window
        return
    }

    switch -- $status {
        ok {
            set result [::msgcat::mc "Registration is successful!"]
            Label $w.result -text $result
            pack $w.result -expand yes -fill both -after $w.sw -anchor nw \
                           -padx 1c -pady 1c
            pack forget $w.sw

            destroy $w.bbox
            set bbox [ButtonBox $w.bbox -spacing 0 -padx 2m -default 0]
            $bbox add -text [::msgcat::mc "Close"] -command [list destroy $w]
            bind $w <Return> "ButtonBox::invoke [double% $bbox] default"
            bind $w <Escape> "ButtonBox::invoke [double% $bbox] 0"
            pack $bbox -padx 2m -pady 2m -anchor e -side bottom -before $w.sep
            if {[llength $commands] > 0} {
                uplevel #0 [lindex $commands 0] [list $status $xml]
            }
        }
        continue {
            set f [$sf getframe]
            foreach ch [winfo children $f] {
                destroy $f
            }
            data::cleanup $f

            destroy $w.bbox
            set bbox [ButtonBox $w.bbox -spacing 0 -padx 2m -default 0]
            $bbox add -text [::msgcat::mc "Submit"] \
                -command [namespace code [list Register $w $f $xlib \
                                                        $jid false]]
            $bbox add -text [::msgcat::mc "Cancel"] -command [list destroy $w]
            bind $w <Return> "ButtonBox::invoke [double% $bbox] default"
            bind $w <Escape> "ButtonBox::invoke [double% $bbox] 1"
            pack $bbox -padx 2m -pady 2m -anchor e -side bottom -before $w.sep

            RecvFields $w $f $xlib $jid $commands ok $xml
        }
        default {
            $w.bbox itemconfigure 0 -state normal
            if {$jid != [connection_server $xlib]} {
                $w.bbox itemconfigure 1 -state normal
            }

            set m [Message $w.error.msg \
                           -aspect 50000 \
                           -text [error_to_string $xml] \
                           -pady 2m]
            $m configure -foreground [option get $m errorForeground Message]
            pack $m
        }
    }
}

hook::add postload_hook \
    [list disco::browser::register_feature_handler jabber:iq:register \
          register::open \
          -desc [list * [::msgcat::mc "Register"]]]

# vim:ft=tcl:ts=8:sw=4:sts=4:et
