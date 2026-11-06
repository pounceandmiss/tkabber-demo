# subscribe_gateway.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       implements subscription dialogs for external gateways/transports.

namespace eval gateway {
    variable msgid 0

    hook::add roster_service_popup_menu_hook \
              [namespace current]::add_menu_item 30
}

proc gateway::add_menu_item {m xlib jid} {
    $m add command -label [::msgcat::mc "Add user to roster..."] \
        -command [list [namespace current]::subscribe_dialog $xlib $jid]
}

proc gateway::subscribe_dialog {xlib service} {
    variable msgid

    set mw .gwmsg$msgid
    Toplevel $mw
    wm group $mw .

    set title [::msgcat::mc "Send subscription at %s" $service]

    wm title $mw $title
    wm iconname $mw $title

    set bbox [ButtonBox $mw.buttons -spacing 0 -padx 2m -default 0]
    $bbox add -text [::msgcat::mc "Subscribe"] \
        -command [list [namespace current]::send_subscribe $mw $xlib $service]
    $bbox add -text [::msgcat::mc "Cancel"] -command [list destroy $mw]

    bind $mw <Return> "ButtonBox::invoke [double% $bbox] default"
    bind $mw <Escape> "ButtonBox::invoke [double% $bbox] 1"

    pack $bbox -side bottom -anchor e -padx 2m -pady 2m

    Frame $mw.frame
    pack $mw.frame -side top -fill both -expand yes -padx 2m -pady 2m

    Label $mw.prompt
    pack $mw.prompt -side top -anchor w -in $mw.frame

    variable $mw.prompt fulljid
    bind $mw <Destroy> [list catch [list unset [namespace current]::%W.prompt]]

    ::xmpp::sendIQ $xlib get \
        -query [::xmpp::xml::create query \
                    -xmlns jabber:iq:gateway] \
        -to $service \
        -command [list [namespace current]::configure_prompt $mw.prompt]

    Frame $mw.subj
    Label $mw.subj.lab -text [::msgcat::mc "Send subscription to: "]
    Entry $mw.subj.entry
    pack $mw.subj.lab -side left
    pack $mw.subj.entry -side left -fill x -expand yes
    pack $mw.subj -side top -anchor w -fill x -expand yes -in $mw.frame

    Frame $mw.space
    pack $mw.space -side top -fill x -in $mw.frame -pady 0.5m

    ScrolledWindow $mw.sw
    pack $mw.sw -side top -fill both -expand yes -in $mw.frame

    textUndoable $mw.body -width 60 -height 8 -wrap word
    $mw.body insert 0.0 [::msgcat::mc "I would like to add you to my roster."]
    $mw.sw setwidget $mw.body

    focus $mw.subj.entry

    incr msgid
}

proc gateway::configure_prompt {w res child} {
    if {![winfo exists $w]} return

    $w configure \
        -text [::msgcat::mc "Enter screenname of contact you want to add"]

    if {$res != "ok"} {
        return
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    foreach ch $subels {
        ::xmpp::xml::split $ch stag sxmlns sattrs scdata ssubels

        if {($stag == "desc") && ($scdata != "")} {
            $w configure -text $scdata
            variable $w screenname
            break
        }
    }
}

proc gateway::send_subscribe {mw xlib service} {
    variable $mw.prompt

    switch -- [set $mw.prompt] {
        fulljid {
            $mw.subj.entry insert end "@$service"
            message::send_subscribe $mw $xlib
        }
        screenname {
            set screenname [$mw.subj.entry get]
            ::xmpp::sendIQ $xlib set \
                -query [::xmpp::xml::create query \
                            -xmlns jabber:iq:gateway \
                            -subelement [::xmpp::xml::create prompt \
                                            -cdata $screenname]] \
                -to $service \
                -command [list [namespace current]::gw_send_subscribe $mw \
                               "$screenname@$service" \
                               $xlib]
        }
    }
}

proc gateway::gw_send_subscribe {mw fallback xlib res child} {

    set jid $fallback

    if {$res == "ok"} {
        ::xmpp::xml::split $child tag xmlns attrs cdata subels

        foreach ch $subels {
            ::xmpp::xml::split $ch stag sxmlns sattrs scdata ssubels

            if {($stag == "jid" || ($stag == "prompt")) && \
                    ($scdata != "")} {
                set jid $scdata
                break
            }
        }
    }

    $mw.subj.entry delete 0 end
    $mw.subj.entry insert 0 $jid
    message::send_subscribe $mw $xlib
}


proc gateway::convert_jid {xlib jid args} {

    ::xmpp::sendIQ $xlib get \
        -query [::xmpp::xml::create query \
                    -xmlns jabber:iq:gateway] \
        -to $jid \
        -command [list [namespace current]::convert_jid_dialog \
                       $xlib $jid]
}

proc gateway::convert_jid_dialog {xlib jid res child} {
    variable msgid

    if {$res != "ok"} return

    set w .gwmsg$msgid

    Dialog $w -title [::msgcat::mc "Screenname conversion"] \
        -anchor e -modal none \
        -default 0 -cancel 1

    set f [$w getframe]

    $w add -text [::msgcat::mc "Convert"] \
        -command [list [namespace current]::convert_screenname $w $xlib $jid]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    set row 0
    foreach ch $subels {
        ::xmpp::xml::split $ch stag sxmlns sattrs scdata ssubels

        switch -- $stag {
            desc {
                if {![winfo exists $f.desc]} {
                    Message $f.desc -text $scdata -width 15c
                    grid $f.desc -row $row -column 0 \
                        -columnspan 2 -sticky w -pady 2m
                }
            }
            prompt {
                if {![winfo exists $f.prompt]} {
                    Label $f.lprompt -text [::msgcat::mc "Screenname:"]
                    Entry $f.prompt
                    grid $f.lprompt -row $row -column 0
                    grid $f.prompt -row $row -column 1 -sticky ew -padx 1m
                }
            }
        }
        incr row
    }

    incr msgid

    $w draw $f.prompt
}

proc gateway::convert_screenname {w xlib jid} {
    set f [$w getframe]
    set screenname [$f.prompt get]

    destroy $w

    ::xmpp::sendIQ $xlib set \
        -query [::xmpp::xml::create query \
                    -xmlns jabber:iq:gateway \
                    -subelement [::xmpp::xml::create prompt \
                                    -cdata $screenname]] \
        -to $jid \
        -command [list [namespace current]::display_conversion $w $screenname]
}

proc gateway::display_conversion {w screenname res child} {

    if {$res != "ok"} {
        NonmodalMessageDlg $w -aspect 50000 -icon error \
            -message [::msgcat::mc "Error while converting screenname: %s." \
                          [error_to_string $child]]
    } else {
        set jid ""

        ::xmpp::xml::split $child tag xmlns attrs cdata subels

        foreach ch $subels {
            ::xmpp::xml::split $ch stag sxmlns sattrs scdata ssubels

            if {($stag == "jid" || ($stag == "prompt")) && \
                    ($scdata != "")} {
                set jid $scdata
                break
            }
        }

        NonmodalMessageDlg $w -aspect 50000 \
            -title [::msgcat::mc "Screenname conversion"] \
            -message [::msgcat::mc "Screenname: %s\n\nConverted JID: %s" \
                          $screenname $jid]
    }
}

hook::add postload_hook \
    [list disco::browser::register_feature_handler jabber:iq:gateway \
          [namespace current]::gateway::convert_jid \
          -desc [list * [::msgcat::mc "Convert screenname"]]]

# vim:ft=tcl:ts=8:sw=4:sts=4:et
