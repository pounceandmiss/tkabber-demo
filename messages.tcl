# messages.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements sending
#       and processing normal messages.

namespace eval message {
    variable msgid 0
    variable headid 0

    variable options

    custom::defvar message_dest_list {} \
        [::msgcat::mc "List of message destination JIDs."] \
        -group Hidden

    custom::defgroup Messages [::msgcat::mc "Message and Headline options."] \
        -group Tkabber

    disco::register_feature jabber:x:oob
}

proc message::process_message \
     {xlib from id type is_subject subject body err thread priority x} {
    switch -- $type {
        normal {
            show_dialog $xlib $from $id $type $subject \
                        $body $thread $priority $x
            return stop
        }
    }
    return
}

hook::add process_message_hook \
          [namespace current]::message::process_message 98

proc message::log_message \
     {xlib from id type is_subject subject body err thread priority x} {
    if {$type ne "normal" || $body eq ""} return
    if {![hook::is_flag process_message_hook log]} return

    ::message_archive::log_message $from [connection_jid $xlib] \
                                   $subject $body $x

    return
}
hook::add process_message_hook \
          [namespace current]::message::log_message 97

proc message::show_dialog \
     {xlib from id type subject body thread priority x {replyP 1}} {
    variable msgid

    set mw .msgshow[incr msgid]
    Toplevel $mw -class Message
    wm group $mw .

    if {$replyP} {
        set title [::msgcat::mc "Message from %s" $from]
    } else {
        set title [::msgcat::mc "Extras from %s" $from]
    }
    wm title $mw $title
    wm iconname $mw $title

    wm withdraw $mw

    Frame $mw.bottom
    pack $mw.bottom -side bottom -fill x

    if {$replyP} {
        set bbox [ButtonBox $mw.bottom.buttons -spacing 2m -padx 2m]
        $bbox add -text [::msgcat::mc "Reply"] \
            -command [list message::send $mw $xlib]
        $bbox add -text [::msgcat::mc "Chat"] \
            -command "chat::open_to_user [list $xlib] [list $from]
                      destroy $mw"
        $bbox add -text [::msgcat::mc "Close"] -command [list destroy $mw]
        bind $mw <Control-Return> "ButtonBox::invoke [double% $bbox] 0"
        bind $mw <Escape> "ButtonBox::invoke [double% $bbox] 2"
        pack $bbox -side right -fill x -padx 2m -pady 2m
    } else {
        ButtonBox $mw.bottom.buttons -spacing 0 -padx 2m
        $mw.bottom.buttons add \
                -text [::msgcat::mc "Close"] -command [list destroy $mw]
        bind $mw <Return> "ButtonBox::invoke [double% $mw.bottom.buttons] 0"
        bind $mw <Escape> "ButtonBox::invoke [double% $mw.bottom.buttons] 0"
    }
    pack $mw.bottom.buttons -side right -fill x -padx 2m -pady 2m

    Frame $mw.frame
    pack $mw.frame -side top -fill both -expand yes -padx 2m -pady 2m

    Label $mw.thread -text $thread

    if {$replyP} {
        set title [::msgcat::mc "Message from:"]
    } else {
        set title [::msgcat::mc "Extras from:"]
    }

    Frame $mw.title
    pack $mw.title -side top -anchor w -fill x -expand no -in $mw.frame
    grid columnconfigure $mw.title 1 -weight 1

    if {[llength [connections]] > 1} {
        Label $mw.title.lconnection -text [::msgcat::mc "Received by:"]
        Label $mw.title.connection -text " [connection_jid $xlib]"
        grid $mw.title.lconnection -row 0 -column 0 -sticky e
        grid $mw.title.connection  -row 0 -column 1 -sticky w
    }

    Label $mw.title.lab -text $title
    MenuToolbutton $mw.title.mb -text $from -menu $mw.title.mb.menu
    menu $mw.title.mb.menu -tearoff 0 \
         -postcommand [namespace code [list subject_menu $mw.title.mb.menu \
                                            $xlib $from message]]
    grid $mw.title.lab -row 1 -column 0 -sticky e
    grid $mw.title.mb  -row 1 -column 1 -sticky w

    foreach tag [bind Menubutton] {
        if {[string first 1 $tag] >= 0} {
            regsub -all 1 $tag 3 new
            bind $mw.title.mb $new [bind Menubutton $tag]
        }
    }

    Frame $mw.tspace
    pack $mw.tspace -side top -fill x -pady 0.5m -in $mw.frame

    Frame $mw.rf
    grid columnconfigure $mw.rf 1 -weight 1

    set row 0

    if {$replyP || $subject ne ""} {
        Label $mw.rf.lsubj -text [::msgcat::mc "Subject:"]
        Entry $mw.rf.subj
        $mw.rf.subj insert 0 $subject
        #set bgcolor [lindex [$mw.rf.subj configure -background] 4]
        #$mw.rf.subj configure -state readonly -readonlybackground $bgcolor
        $mw.rf.subj:cmd configure -state readonly
        grid $mw.rf.lsubj -row 0 -column 0 -sticky e
        grid $mw.rf.subj  -row 0 -column 1 -sticky ew
        incr row
    }

    pack $mw.rf -side top -anchor w -fill x -in $mw.frame

    Frame $mw.rspace
    pack $mw.rspace -side top -fill x -in $mw.frame -pady 0.5m

    incr row
    set last $row
    hook::run message_process_x_hook row body \
              $mw.rf $x $xlib $from $id $type $replyP

    if {!$replyP && $row == $last} {
        destroy $mw
        return
    }
    # Ignore messages with empty body and no (or unsupported, e.g.
    # jabber:x:event) extras
    if {$body eq "" && $row == $last} {
        destroy $mw
        return
    }

    ScrolledWindow $mw.rsw
    Text $mw.rbody -width 60 -height 8 -wrap word
    ::richtext::config $mw.rbody -using {url emoticon stylecode}
    ::richtext::render_message $mw.rbody $body ""
    $mw.rbody configure -state disabled
    pack $mw.rsw -side top -fill both -expand yes -in $mw.frame
    $mw.rsw setwidget $mw.rbody

    if {$replyP} {
        Button $mw.cite -text [::msgcat::mc "Quote"] \
                        -command [list message::quote $mw $body]
        pack $mw.cite -side top -anchor e -in $mw.frame

        Frame $mw.f
        grid columnconfigure $mw.f 1 -weight 1

        #label $mw.f.lto -text To:
        Entry $mw.f.to -dropenabled 1 -droptypes {JID {}} \
                -dropcmd [list message::jiddropcmd]
        $mw.f.to insert 0 $from

        Label $mw.f.lsubj -text [::msgcat::mc "Reply subject:"]
        Entry $mw.f.subj
        regsub {(^Re: )*} $subject {Re: } subject
        $mw.f.subj insert 0 $subject

        #grid $mw.f.lto   -row 0 -column 0 -sticky e
        #grid $mw.f.to    -row 0 -column 1 -sticky ew
        grid $mw.f.lsubj -row 1 -column 0 -sticky e
        grid $mw.f.subj  -row 1 -column 1 -sticky ew

        pack $mw.f -side top -anchor w -fill x -in $mw.frame

        Frame $mw.space
        pack $mw.f -side top -anchor w -fill x -in $mw.frame -pady 1m

        ScrolledWindow $mw.sw
        pack $mw.sw -in $mw.frame -side top -fill both -expand yes

        textUndoable $mw.body -width 60 -height 8 -wrap word
        bind [Wrapped $mw.body] <Control-Return> \
                "ButtonBox::invoke [double% $bbox] 0
                 break"
        $mw.sw setwidget $mw.body

        focus [Wrapped $mw.body]

        hook::run open_message_post_hook $mw $xlib $from
    }

    BWidget::place $mw 0 0 center
    wm deiconify $mw
}

proc message::quote {mw body} {
    regsub -all {(^|\n)} $body {\1> } body
    $mw.body insert 0.0 $body
    $mw.body insert insert "\n"
    focus [Wrapped $mw.body]
}

proc message::process_x_oob {rowvar bodyvar f x xlib from id type replyP} {
    upvar 2 $rowvar row

    foreach xa $x {
        ::xmpp::xml::split $xa tag xmlns attrs cdata subels

        if {$xmlns ne "jabber:x:oob"} continue

        set desc ""
        set url ""
        foreach item $subels {
            ::xmpp::xml::split $item tag1 xmlns1 attrs1 cdata1 subels1

            switch -- $tag1 {
                desc -
                url {
                    set $tag1 $cdata1
                }
            }
        }
        if {$url eq ""} {
            return $row
        }
        if {$desc eq ""} {
            set desc $url
        }

        Label $f.luser$row -text [::msgcat::mc "Attached URL:"]
        render_url $f.user$row $url $desc -background [get_conf $f -background]
        grid $f.luser$row -row $row -column 0 -sticky e
        grid $f.user$row  -row $row -column 1 -sticky ew

        incr row
    }
}

hook::add message_process_x_hook message::process_x_oob 99

proc message::process_x_data {rowvar bodyvar f x xlib from id type replyP} {
    foreach xa $x {
        ::xmpp::xml::split $xa tag xmlns attrs cdata subels

        if {$xmlns eq "jabber:x:data" && [llength $subels] > 0} {
            data::draw_window [list $xa] \
                              [list message::send_x_data $xlib $from]
        }
    }
}

hook::add message_process_x_hook message::process_x_data 100

proc message::send_x_data {xlib to w restags} {
    ::xmpp::sendMessage $xlib $to -xlist $restags
    destroy $w
}

proc message::send_dialog_item {m xlib jid} {
    $m add command -label [::msgcat::mc "Send message..."] \
        -command [list message::send_dialog \
                       -to $jid -connection $xlib]
}

hook::add roster_jid_popup_menu_hook message::send_dialog_item 15
hook::add message_dialog_menu_hook message::send_dialog_item 15
hook::add search_popup_menu_hook message::send_dialog_item 15
hook::add roster_create_groupchat_user_menu_hook message::send_dialog_item 15

package require sha1

proc message::generate_thread {from to} {
    return [sha1::sha1 $from$to[rand 1000000000]]
}

proc message::send_dialog {args} {
    variable msgid
    variable message_dest_list
    variable send_dialog_xlib

    if {[llength [connections]] == 0} return

    set to ""
    set subject ""
    set group 0
    set cstate normal
    foreach {opt val} $args {
        switch -- $opt {
            -to { set to $val }
            -subject { set subject $val }
            -thread { set thread $val }
            -group { set group $val }
            -connection {
                set xlib $val
                set cstate disabled
            }
        }
    }

    if {![info exists xlib]} {
        set xlib [lindex [connections] 0]
    }

    set mw .msgsend[incr msgid]
    Toplevel $mw -class Message
    wm group $mw .

    set send_dialog_xlib($mw) [connection_jid $xlib]

    if {![info exists thread]} {
        set thread [generate_thread $send_dialog_xlib($mw) $to]
    }

    if {$group} {
        if {$to ne ""} {
            set title [::msgcat::mc "Send message to group %s" $to]
        } else {
            set title [::msgcat::mc "Send message to group"]
        }
    } else {
        if {$to ne ""} {
            set title [::msgcat::mc "Send message to %s" $to]
        } else {
            set title [::msgcat::mc "Send message"]
        }
    }
    wm title $mw $title
    wm iconname $mw $title

    wm withdraw $mw

    #frame $mw.subj
    #label $mw.subj.lab -text Subject:
    #entry $mw.subj.entry
    #$mw.subj.entry insert 0 $subject
    #pack $mw.subj.lab $mw.subj.entry -side left
    #pack $mw.subj -side top -anchor w

    Frame $mw.bottom
    pack $mw.bottom -side bottom -fill x

    set bbox [ButtonBox $mw.bottom.buttons -spacing 2m -padx 2m]
    $bbox add -text [::msgcat::mc "Send"] \
        -command [list message::send0 $mw -group $group]
    $bbox add -text [::msgcat::mc "Cancel"] -command [list destroy $mw]
    bind $mw <Control-Return> "ButtonBox::invoke [double% $bbox] 0"
    bind $mw <Escape> "ButtonBox::invoke [double% $bbox] 1"
    pack $bbox -side right -fill x -padx 2m -pady 2m

    Label $mw.thread -text $thread

    Frame $mw.frame
    pack $mw.frame -side top -fill both -expand yes -padx 2m -pady 2m

    Frame $mw.f
    grid columnconfigure $mw.f 1 -weight 1

    set connections {}
    if {[llength [connections]] > 1} {
        foreach c [connections] {
            lappend connections [connection_jid $c]
        }
        Label $mw.f.lconnection -text [::msgcat::mc "From: "]
        Combobox $mw.f.connection \
            -textvariable [namespace current]::send_dialog_xlib($mw) \
            -values $connections \
            -state $cstate

        grid $mw.f.lconnection -row 0 -column 0 -sticky e
        grid $mw.f.connection  -row 0 -column 1 -sticky ew
    }

    if {$group} {
        # TODO reflect changes in xlib
        Label $mw.f.lto -text [::msgcat::mc "Group: "]
        Combobox $mw.f.to \
            -values [roster::get_groups $xlib \
                         -nested $::ifacetk::roster::options(nested) \
                         -delimiter \
                                $::ifacetk::roster::options(nested_delimiter) \
                         -undefined 1]
        $mw.f.to set $to
    } else {
        Label $mw.f.lto -text [::msgcat::mc "To: "]
        Combobox $mw.f.to -values $message_dest_list
        DropSite::register $mw.f.to -droptypes {JID {}} \
                                    -dropcmd [list message::jiddropcmd]
        $mw.f.to set $to
    }

    Label $mw.f.lsubj -text [::msgcat::mc "Subject: "]
    Entry $mw.f.subj
    $mw.f.subj insert 0 $subject

    grid $mw.f.lto   -row 1 -column 0 -sticky e
    grid $mw.f.to    -row 1 -column 1 -sticky ew
    grid $mw.f.lsubj -row 2 -column 0 -sticky e
    grid $mw.f.subj  -row 2 -column 1 -sticky ew

    pack $mw.f -side top -anchor w -fill x -in $mw.frame

    Frame $mw.space
    pack $mw.f -side top -anchor w -fill x -in $mw.frame -pady 1m

    ScrolledWindow $mw.sw
    pack $mw.sw -in $mw.frame -side top -fill both -expand yes

    textUndoable $mw.body -width 60 -height 8 -wrap word
    bind [Wrapped $mw.body] <Control-Return> \
            "ButtonBox::invoke [double% $bbox] 0
             break"
    $mw.sw setwidget $mw.body

    if {$to ne ""} {
        focus $mw.f.subj
    } else {
        focus $mw.f.to
    }

    hook::run open_message_post_hook $mw $xlib $to

    BWidget::place $mw 0 0 center
    wm deiconify $mw
}

proc message::send0 {mw args} {
    variable send_dialog_xlib

    foreach c [connections] {
        if {[connection_jid $c] eq $send_dialog_xlib($mw)} {
            set xlib $c
        }
    }
    unset send_dialog_xlib($mw)

    send $mw $xlib {*}$args
}

proc message::send {mw xlib args} {
    variable message_dest_list

    set group 0
    foreach {opt val} $args {
        switch -- $opt {
            -group { set group $val }
        }
    }

    set jid [$mw.f.to cget -text]

    if {$group} {
        set jids [roster::get_group_jids $xlib $jid \
                      -nested $::ifacetk::roster::options(nested) \
                      -delimiter $::ifacetk::roster::options(nested_delimiter)]
    } else {
        set message_dest_list [update_combo_list $message_dest_list $jid 20]
        set jids [list $jid]
    }

    set thread [$mw.thread cget -text]
    set subj [$mw.f.subj get]
    set body [$mw.body get 1.0 {end -1 chars}]

    foreach jid $jids {
        if {!$group || [::roster::itemconfig $xlib $jid -isuser]} {
            hook::run send_normal_message_hook $xlib $jid $subj $body $thread
            send_msg $xlib $jid -type normal \
                -subject $subj -body $body -thread $thread
        }
    }

    destroy $mw
}

proc message::log_outgoing {xlib to subj body thread} {
    if {$body eq ""} return
    if {![hook::is_flag send_normal_message_hook log]} return

    ::message_archive::log_message [connection_jid $xlib] $to $subj $body {}

    return
}

hook::add send_normal_message_hook \
          [namespace current]::message::log_outgoing 50

proc message::send_msg {xlib to args} {
    set x {}
    foreach {key val} $args {
        switch -- $key {
            -from    { set from $val }
            -type    { set type $val }
            -id      { set id $val }
            -subject { set subject $val }
            -thread  { set thread $val }
            -body    { set body $val }
            -error   { set err $val }
            -xlist   { set x $val }
        }
    }

    hook::run rewrite_outgoing_message_hook \
              xlib to id type subject body err thread x

    if {[hook::is_flag rewrite_outgoing_message_hook send]} {
        set args {}

        if {[info exists from]}    { lappend args -from $from }
        if {[info exists type]}    { lappend args -type $type }
        if {[info exists id]}      { lappend args -id $id }
        if {[info exists subject]} { lappend args -subject $subject }
        if {[info exists thread]}  { lappend args -thread $thread }
        if {[info exists body]}    { lappend args -body $body }
        if {[info exists err]}     { lappend args -error $err }
        if {[info exists x]}       { lappend args -xlist $x }

        ::xmpp::sendMessage $xlib $to {*}$args
        return [list ok $x]
    }

    return [list error $x]
}

proc message::jiddropcmd {target source x y op type data} {
    set jid [lindex $data 1]
    $target delete 0 end
    $target insert 0 $jid
}

###############################################################################

proc message::show_subscribe_dialog {xlib from type x args} {
    variable msgid

    if {$type ne "subscribe"} return

    set status ""

    foreach {opt val} $args {
        switch -- $opt {
            -status { set status $val }
            default {
                debugmsg message \
                         "SHOW_SUBSCRIBE_MESSAGE: unknown option $opt $val"
            }
        }
    }

    set mw .subscshow[incr msgid]
    Toplevel $mw -class Message
    wm group $mw .
    wm withdraw $mw

    set title [::msgcat::mc "Subscription request from %s" $from]
    wm title $mw $title
    wm iconname $mw $title

    set bbox [ButtonBox $mw.buttons -spacing 0 -padx 2m -default 0]
    $bbox add -text [::msgcat::mc "Approve subscription"] \
              -command [list [namespace current]::subscribe $mw $xlib $from]
    $bbox add -text [::msgcat::mc "Decline subscription"] \
              -command [list [namespace current]::unsubscribe $mw $xlib $from]
    bind $mw <Return> "ButtonBox::invoke [double% $bbox] default"
    bind $mw <Escape> "ButtonBox::invoke [double% $bbox] 1"
    pack $bbox -side bottom -anchor e -padx 2m -pady 2m

    Frame $mw.frame
    pack $mw.frame -side top -fill both -expand yes -padx 2m -pady 2m

    Frame $mw.subj
    pack $mw.subj -side top -anchor w -fill x -expand no -in $mw.frame
    grid columnconfigure $mw.subj 1 -weight 1

    if {[llength [connections]] > 1} {
        Label $mw.subj.lconnection -text [::msgcat::mc "Received by:"]
        Label $mw.subj.connection -text " [connection_jid $xlib]"
        grid $mw.subj.lconnection -row 0 -column 0 -sticky e
        grid $mw.subj.connection  -row 0 -column 1 -sticky w
    }


    Label $mw.subj.lab -text [::msgcat::mc "Subscription request from:"]
    MenuToolbutton $mw.subj.mb -text $from -menu $mw.subj.mb.menu
    menu $mw.subj.mb.menu -tearoff 0 \
         -postcommand [namespace code [list subject_menu $mw.subj.mb.menu \
                                            $xlib $from subscribe]]
    grid $mw.subj.lab -row 1 -column 0 -sticky e
    grid $mw.subj.mb  -row 1 -column 1 -sticky w

    foreach tag [bind Menubutton] {
        if {[string first 1 $tag] >= 0} {
            regsub -all 1 $tag 3 new
            bind $mw.subj.mb $new [bind Menubutton $tag]
        }
    }

    Frame $mw.space
    pack $mw.space -side top -fill x -pady 0.5m -in $mw.frame

    ScrolledWindow $mw.sw
    pack $mw.sw -side top -fill both -expand yes -in $mw.frame

    Text $mw.body -width 60 -height 8 -wrap word
    $mw.body insert 0.0 $status
    $mw.body configure -state disabled
    $mw.sw setwidget $mw.body

    BWidget::place $mw 0 0 center
    wm deiconify $mw
}

hook::add client_presence_hook message::show_subscribe_dialog

###############################################################################

proc message::show_unsubscribed_dialog {xlib from type x args} {
    variable msgid

    if {$type ne "unsubscribed"} return

    NonmodalMessageDlg .unsubscribed[incr msgid] \
            -aspect 50000 \
            -icon info \
            -title [::msgcat::mc "Unsubscribed from %s" $from] \
            -message [::msgcat::mc "You are unsubscribed from %s" $from]
}

hook::add client_presence_hook message::show_unsubscribed_dialog

###############################################################################

proc message::subscribe {mw xlib jid} {
    ::xmpp::sendPresence $xlib -to $jid -type subscribed

    switch -- [roster::itemconfig $xlib \
                                  [::xmpp::jid::normalize $jid] -subsc] {
        {}   -
        none -
        from {
            message::send_subscribe_dialog $jid -connection $xlib
        }
    }

    destroy $mw
}

###############################################################################

proc message::unsubscribe {mw xlib jid} {
    ::roster::remove_item $xlib [::xmpp::jid::normalize $jid]
    destroy $mw
}

###############################################################################

proc message::destroy_subscription_dialogs {xlib jid name groups subsc ask} {
    switch -- $subsc {
        both -
        from {}
        default { return }
    }

    foreach mw [winfo children .] {
        if {![string match .subscshow* $mw]} continue

        set curjid [$mw.subj.mb cget -text]
        if {$curjid eq $jid} {
            destroy $mw
        }
    }
}

hook::add roster_push_hook message::destroy_subscription_dialogs

###############################################################################

proc message::disco_popup_menu {m bw tnode data parentdata} {
    lassign $data type xlib jid node
    switch -- $type {
        item -
        item2 {
            set identities [disco::browser::get_identities $bw $tnode]

            foreach id $identities {
                if {[get_prop $id category] eq "client"} {
                    subject_menu $m $xlib $jid message
                    return
                }
            }
        }
    }
}

hook::add disco_node_menu_hook message::disco_popup_menu

###############################################################################

proc message::subject_menu {m xlib jid type} {
    if {![winfo exists $m]} {
        menu $m -tearoff 0
    } else {
        $m delete 0 end
        foreach mm [winfo children $m] {
            destroy $mm
        }
    }

    hook::run message_dialog_menu_hook $m $xlib $jid

    return $m
}

###############################################################################

proc message::add_separator {m xlib jid} {
    $m add separator
}

hook::add message_dialog_menu_hook \
    [namespace current]::message::add_separator 40
hook::add message_dialog_menu_hook \
    [namespace current]::message::add_separator 50

###############################################################################

proc message::add_subscribe_menu_item {m xlib jid} {
    set user [::xmpp::jid::removeResource $jid]
    set chatid [chat::chatid $xlib $user]
    if {[chat::is_groupchat $chatid]} {
        set real_jid [muc::get_real_jid $xlib $jid]
        if {$real_jid ne ""} {
            set jid $real_jid
            set state normal
        } else {
            set state disabled
        }
    } else {
        set state normal
    }
    if {[roster::itemconfig $xlib $user -subsc] ne ""} {
        set state disabled
    }
    $m add command -label [::msgcat::mc "Add user to roster..."] \
                   -state $state \
                   -command [list message::send_subscribe_dialog $user \
                                  -connection $xlib]
}

hook::add chat_create_user_menu_hook \
    [namespace current]::message::add_subscribe_menu_item 35
hook::add message_dialog_menu_hook \
    [namespace current]::message::add_subscribe_menu_item 35
hook::add search_popup_menu_hook \
    [namespace current]::message::add_subscribe_menu_item 35

###############################################################################

proc message::send_subscribe_dialog {to args} {
    variable msgid
    variable send_subscribe_xlib

    if {[llength [connections]] == 0} return

    set cstate normal

    foreach {opt val} $args {
        switch -- $opt {
            -connection {
                set xlib $val
                set cstate disabled
            }
        }
    }
    if {![info exists xlib]} {
        set xlib [lindex [connections] 0]
    }

    set mw .subscsend[incr msgid]
    Toplevel $mw -class Message
    wm group $mw .
    wm withdraw $mw

    set send_subscribe_xlib($mw) [connection_jid $xlib]

    bind $mw <Destroy> \
         [list unset -nocomplain [namespace current]::send_subscribe_xlib($mw)]

    if {$to eq ""} {
        set title [::msgcat::mc "Send subscription request"]
    } else {
        set title [::msgcat::mc "Send subscription request to %s" $to]
    }
    wm title $mw $title
    wm iconname $mw $title

    set bbox [ButtonBox $mw.buttons -spacing 0 -padx 2m -default 0]
    $bbox add -text [::msgcat::mc "Request subscription"] \
        -command [list message::send_subscribe0 $mw]
    $bbox add -text [::msgcat::mc "Cancel"] -command [list destroy $mw]
    bind $mw <Return> "ButtonBox::invoke [double% $bbox] default"
    bind $mw <Escape> "ButtonBox::invoke [double% $bbox] 1"
    pack $bbox -side bottom -anchor e -padx 2m -pady 2m

    Frame $mw.frame
    pack $mw.frame -side top -fill both -expand yes -padx 2m -pady 2m

    Frame $mw.subj
    pack $mw.subj -side top -anchor w -fill x -expand no -in $mw.frame
    grid columnconfigure $mw.subj 1 -weight 1

    set connections {}
    if {[llength [connections]] > 1} {
        foreach c [connections] {
            lappend connections [connection_jid $c]
        }
        Label $mw.subj.lconnection -text [::msgcat::mc "From: "]
        Combobox $mw.subj.connection \
            -textvariable [namespace current]::send_subscribe_xlib($mw) \
            -values $connections \
            -state $cstate

        grid $mw.subj.lconnection -row 0 -column 0 -sticky e
        grid $mw.subj.connection  -row 0 -column 1 -sticky ew
    }

    Label $mw.subj.lab -text [::msgcat::mc "Send request to: "]
    Entry $mw.subj.entry
    $mw.subj.entry insert 0 $to
    grid $mw.subj.lab   -row 1 -column 0 -sticky e
    grid $mw.subj.entry -row 1 -column 1 -sticky ew

    Frame $mw.space
    pack $mw.space -side top -fill x -in $mw.frame -pady 0.5m

    ScrolledWindow $mw.sw
    pack $mw.sw -side top -fill both -expand yes -in $mw.frame

    textUndoable $mw.body -width 60 -height 8 -wrap word
    $mw.body insert 0.0 [::msgcat::mc "I would like to add you to my roster."]
    $mw.sw setwidget $mw.body

    focus $mw.subj.entry

    BWidget::place $mw 0 0 center
    wm deiconify $mw
}

###############################################################################

proc message::send_subscribe0 {mw} {
    variable send_subscribe_xlib

    foreach c [connections] {
        if {[connection_jid $c] eq $send_subscribe_xlib($mw)} {
            set xlib $c
        }
    }

    if {[info exists xlib]} {
        send_subscribe $mw $xlib
    }
}

###############################################################################

proc message::send_subscribe {mw xlib args} {
    set jid [$mw.subj.entry get]

    ::xmpp::sendPresence $xlib -to $jid -type subscribe \
        -status [$mw.body get 1.0 end]

    ::xmpp::roster::send $::roster::roster(token,$xlib) -jid $jid \
        -command "itemedit::show_dialog \
                      [list $xlib [::xmpp::jid::normalize $jid]] ;#"

    destroy $mw
}

###############################################################################

proc message::resubscribe_menu_item {m xlib jid} {
    set rjid [roster::find_jid $xlib $jid]
    if {$rjid eq ""} {
        set state disabled
    } else {
        set state normal
    }
    set mm [menu $m.subscription -tearoff 0]
    $mm add command -label [::msgcat::mc "Request subscription"] \
                    -command [list ::xmpp::sendPresence $xlib \
                                            -to $rjid \
                                            -type subscribe]
    $mm add command -label [::msgcat::mc "Grant subscription"] \
                    -command [list ::xmpp::sendPresence $xlib \
                                            -to $rjid \
                                            -type subscribed]
    $mm add command -label [::msgcat::mc "Request unsubscription"] \
                    -command [list ::xmpp::sendPresence $xlib \
                                            -to $rjid \
                                            -type unsubscribe]
    $mm add command -label [::msgcat::mc "Revoke subscription"] \
                    -command [list ::xmpp::sendPresence $xlib \
                                            -to $rjid \
                                            -type unsubscribed]

    $m add cascade -label [::msgcat::mc "Subscription"] \
                   -menu $mm \
                   -state $state
}

hook::add roster_jid_popup_menu_hook message::resubscribe_menu_item 30
hook::add roster_service_popup_menu_hook message::resubscribe_menu_item 30

###############################################################################

# vim:ft=tcl:ts=8:sw=4:sts=4:et
