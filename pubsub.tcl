# pubsub.tcl --
#
#       Publish-Subscribe Support (XEP-0060)
#       Personal Eventing via Pubsub Support (XEP-0163)

package require xmpp::pubsub

##########################################################################
#
# Publish-subscribe XEP-0060
#

namespace eval pubsub {
    variable m2a
    variable a2m
    variable aff_list [list [::msgcat::mc "Owner"] owner \
                            [::msgcat::mc "Publisher"] publisher \
                            [::msgcat::mc "None"] none \
                            [::msgcat::mc "Outcast"] outcast]
    variable m
    variable a
    foreach {m a} $aff_list {
        set m2a($m) $a
        set a2m($a) $m
    }

    variable m2s
    variable s2m
    variable subsc_list [list [::msgcat::mc "None"] none \
                              [::msgcat::mc "Pending"] pending \
                              [::msgcat::mc "Unconfigured"] unconfigured \
                              [::msgcat::mc "Subscribed"] subscribed]
    variable s
    foreach {m s} $subsc_list {
        set m2s($m) $s
        set s2m($s) $m
    }
}

##########################################################################
#
# Configure subscription options (6.3)
#

proc pubsub::requestSubscriptionOptions {xlib service node args} {

    debugmsg pubsub [info level 0]

    set commands {}
    set newArgs {}
    foreach {key val} $args {
        switch -- $key {
            -command { set commands [list $val] }
            default  { lappend newArgs $key $val }
        }
    }

    ::xmpp::pubsub::requestSubscriptionOptions $xlib $service $node \
        {*}$newArgs \
        -command [namespace code [list SubscriptionOptionsResult \
                                         $xlib $service $commands]]
}

proc pubsub::SubscriptionOptionsResult {xlib service commands status res} {
    debugmsg pubsub [info level 0]

    if {![string equal $status ok]} {
        if {[llength $commands] > 0} {
            {*}[lindex $commands 0] $status $res
        }
        return
    }

    lassign $res attrs form
    set node  [::xmpp::xml::getAttr $attrs node]
    set jid   [::xmpp::xml::getAttr $attrs jid]
    set subid [::xmpp::xml::getAttr $attrs subid]

    data::draw_window [list $form] \
        [namespace code [list SendSubscriptionOptions
              $xlib $service $node $jid $subid $commands]]
}

# TODO: $commands
proc pubsub::SendSubscriptionOptions \
     {xlib service node jid subid commands w restags} {
    debugmsg pubsub [info level 0]

    destroy $w.error.msg
    $w.bbox itemconfigure 0 -state disabled

    ::xmpp::pubsub::sendSubscriptionOptions $xlib $service $node $restags \
            -jid $jid -subid $subid -resource $resource \
            -command [list data::test_error_res $w]
}

proc pubsub::requestSubscriptions {xlib service node args} {
    debugmsg pubsub [info level 0]

    set commands {}
    set newArgs {}
    foreach {key val} $args {
        switch -- $key {
            -command { set commands [list $val] }
            default  { lappend newArgs $key $val }
        }
    }

    ::xmpp::pubsub::requestSubscriptions $xlib $service $node {*}$newArgs \
         -command [namespace code [list RequestSubscriptionsResult \
                                                $xlib $service $commands]]
}

proc pubsub::RequestSubscriptionsResult {xlib service commands status items} {
    debugmsg pubsub [info level 0]

    if {![string equal $status ok]} {
        if {[llength $commands] > 0} {
            {*}[lindex $commands 0] $status $items
        }
        return
    }

    set w .pubsub_subscriptions
    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -title [::msgcat::mc "Subscriptions to pubsub nodes at %s" \
                                   $service] \
              -modal none -anchor e -default 0 -cancel 0

    $w add -text [::msgcat::mc "Close"] -command [list destroy $w]

    set wf [$w getframe]

    set sw [ScrolledWindow $wf.sw -scrollbar vertical]
    set sf [ScrollableFrame $w.fields -constrainedwidth yes]
    set f [$sf getframe]
    $sw setwidget $sf

    set row 1
    foreach item $items {
        set node         [::xmpp::xml::getAttr $item node]
        set jid          [::xmpp::xml::getAttr $item jid]
        set subscription [::xmpp::xml::getAttr $item subscription]
        set subid        [::xmpp::xml::getAttr $item subid]

        Label $f.node$row -text $node
        Label $f.jid$row -text $jid
        Label $f.subscription -text $subscription
        Label $f.subid -text $subid

        grid $f.node$row -row $row -column 0
        grid $f.jid$row -row $row -column 1
        grid $f.subscription$row -row $row -column 2
        grid $f.subid$row -row $row -column 3

        set command [list requestSubscriptionOptions $xlib $service $node \
                          -jid $jid -command [namespace code test_error]]
        if {[::xmpp::xml::isAttr $item subid]} {
            lappend command -subid $subid
        }

        Button $f.edit$row -text [::msgcat::mc "Edit"] \
                           -command [namespace code $command]
        grid $f.edit$row -row $row -column 4
    }
}

##########################################################################
#
# Owner use cases (8)
#

##########################################################################
#
# Configure pubsub node "node" at service "service" (8.2)
# node must not be empty
#

proc pubsub::configureNode {xlib service node args} {

    debugmsg pubsub [info level 0]

    set commands {}
    set newArgs {}
    foreach {key val} $args {
        switch -- $key {
            -command { set commands [list $val] }
            default  { lappend newArgs $key $val }
        }
    }

    ::xmpp::pubsub::configureNode $xlib $service $node {*}$newArgs \
         -command [namespace code [list ConfigureNodeResult \
                                         $xlib $service $commands]]
}

proc pubsub::ConfigureNodeResult {xlib service commands status res} {

    debugmsg pubsub [info level 0]

    if {![string equal $status ok]} {
        if {[llength $commands] > 0} {
            {*}[lindex $commands 0] $status $res
        }
        return
    }

    lassign $res node form

    data::draw_window [list $form] \
        [namespace code [list SendConfigureNode \
              $xlib $service $node $commands]]
}

proc pubsub::SendConfigureNode {xlib service node commands w restags} {

    debugmsg pubsub [info level 0]

    destroy $w.error.msg
    $w.bbox itemconfigure 0 -state disabled

    ::xmpp::pubsub::sendConfigureNode $xlib $service $node $restags \
            -command [list data::test_error_res $w]
}

##########################################################################
#
# Request default configuration options (8.3)
#

proc pubsub::requestDefaultConfig {xlib service args} {
    variable ns

    debugmsg pubsub [info level 0]

    set commands {}
    set newArgs {}
    foreach {key val} $args {
        switch -- $key {
            -command { set commands [list $val] }
            default  { lappend newArgs $key $val }
        }
    }

    ::xmpp::pubsub::requestDefaultConfig $xlib $service {*}$newArgs \
         -command [namespace code [list RequestDefaultConfigResult \
                                         $xlib $service $commands]]
}

proc pubsub::RequestDefaultConfigResult {xlib service commands status form} {

    debugmsg pubsub [info level 0]

    if {![string equal $status ok]} {
        if {[llength $commands] > 0} {
            {*}[lindex $commands 0] $status $form
        }
        return
    }

    # TODO: Don't send the form
    data::draw_window [list $form] \
        [namespace code [list SendRequestResults \
              $xlib $service $commands]]
}

proc pubsub::SendRequestResults {xlib service commands w restags} {

    debugmsg pubsub [info level 0]

    destroy $w.error.msg
}

##########################################################################
#
# Request all pending subscription requests (8.6.1)
#

proc pubsub::request_pending_subscription {xlib service} {
    debugmsg pubsub [info level 0]

    # Let xcommands.tcl do the job
    xcommands::execute $xlib $service $::xmpp::pubsub::ns(get-pending)
}

##########################################################################
#
# Modifying entity affiliations
# node must not be empty
# TODO
#

proc pubsub::request_entities {xlib service node args} {

    debugmsg pubsub [info level 0]

    set command ""
    foreach {key val} $args {
        switch -- $key {
            -command { set command $val }
        }
    }

    if {$node == ""} {
        return -code error "pubsub::request_entities error: Node is empty"
    }

    ::xmpp::sendIQ $xlib set \
        -query [::xmpp::xml::create pubsub \
                    -xmlns $::NS(pubsub) \
                    -subelement [::xmpp::xml::create entities \
                                        -attrs [list node $node]]] \
        -to $service \
        -command [list [namespace current]::receive_entities \
                       $xlib $service $command]
}

proc pubsub::receive_entities {xlib service command res child} {
    variable winid

    debugmsg pubsub [info level 0]

    if {$res != "ok"} {
        if {$command != ""} {
            {*}$command $res $child
        }
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    foreach subel $subels {
        ::xmpp::xml::split $subel stag sxmlns sattrs scdata ssubels

        if {$stag == "entities"} {
            set node [::xmpp::xml::getAttr $sattrs node]
            set entities $ssubels
            break
        }
    }

    if {![info exists winid]} {
        set winid 0
    } else {
        incr winid
    }
    set w .pubsub_entities$winid

    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -title [::msgcat::mc "Edit entities affiliations: %s" $node] \
        -modal none -anchor e -default 0 -cancel 1

    set wf [$w getframe]

    set sw [ScrolledWindow $wf.sw -scrollbar vertical]
    set sf [ScrollableFrame $w.fields -constrainedwidth yes]
    set f [$sf getframe]
    $sw setwidget $sf
    fill_list $sf $f $entities
    list_add_item $sf $f

    $w add -text [::msgcat::mc "Send"] \
        -command [list [namespace current]::send_entities \
                       $xlib $service $node $w $f]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    bind $f <Destroy> \
         [list [namespace current]::cleanup_entities %W]

    Button $w.add -text [::msgcat::mc "Add"] \
        -command [list [namespace current]::list_add_item $sf $f]
    pack $w.add -side bottom -anchor e -in $wf -padx 1m -pady 1m
    pack $sw -side top -expand yes -fill both

    bindscroll $f $sf

    set hf [Frame $w.hf]
    pack $hf -side top
    set vf [Frame $w.vf]
    pack $vf -side left

    update idletasks
    $hf configure -width [expr {[winfo reqwidth $f] + [winfo pixels $f 1c]}]

    set h [winfo reqheight $f]
    set sh [winfo screenheight $w]
    if {$h > $sh - [winfo pixels $f 5c]} {
        set h [expr {$sh - [winfo pixels $f 5c]}]
    }
    $vf configure -height $h

    $w draw
}

proc pubsub::fill_list {sf f entities} {
    variable a2m
    variable s2m
    variable listdata
    variable origlistdata

    debugmsg pubsub [info level 0]

    grid columnconfigure $f 0 -weight 1
    grid columnconfigure $f 1 -weight 1
    grid columnconfigure $f 2 -weight 1
    grid columnconfigure $f 3 -weight 1

    Label $f.ljid -text [::msgcat::mc "Jabber ID"]
    grid $f.ljid -row 0 -column 0 -sticky we -padx 1m
    bindscroll $f.ljid $sf

    Label $f.lsubid -text [::msgcat::mc "SubID"]
    grid $f.lsubid -row 0 -column 1 -sticky we -padx 1m
    bindscroll $f.lsubid $sf

    Label $f.laffiliation -text [::msgcat::mc "Affiliation"]
    grid $f.laffiliation -row 0 -column 2 -sticky we -padx 1m
    bindscroll $f.laffiliation $sf

    Label $f.lsubscription -text [::msgcat::mc "Subscription"]
    grid $f.lsubscription -row 0 -column 3 -sticky we -padx 1m
    bindscroll $f.lsubscription $sf

    set row 1

    set entities2 {}
    foreach entity $entities {
        ::xmpp::xml::split $entity tag xmlns attrs cdata subels
        switch -- $tag {
            entity {
                set jid [::xmpp::xml::getAttr $attrs jid]
                set subid [::xmpp::xml::getAttr $attrs subid]
                set affiliation [::xmpp::xml::getAttr $attrs affiliation]
                set subscription [::xmpp::xml::getAttr $attrs subscription]
                lappend entities2 [list $jid $subid $affiliation $subscription]
            }
        }
    }

    foreach entity [lsort -dictionary -index 0 $entities2] {
        lassign $item jid subid affiliation subscription

        Label $f.jid$row -text $jid \
            -textvariable [namespace current]::listdata($f,jid,$row)
        grid $f.jid$row -row $row -column 0 -sticky w -padx 1m
        bindscroll $f.jid$row $sf

        Label $f.subid$row -text $subid \
            -textvariable [namespace current]::listdata($f,subid,$row)
        grid $f.subid$row -row $row -column 1 -sticky w -padx 1m
        bindscroll $f.subid$row $sf

        Combobox $f.affiliation$row -text $a2m($affiliation) \
            -values [list $a2m(owner) \
                          $a2m(publisher) \
                          $a2m(none) \
                          $a2m(outcast)] \
            -editable no \
            -width 9 \
            -textvariable [namespace current]::listdata($f,affiliation,$row)
        grid $f.affiliation$row -row $row -column 2 -sticky we -padx 1m
        bindscroll $f.affiliation$row $sf

        Combobox $f.subscription$row -text $s2m($subscription) \
            -values [list $s2m(none) \
                          $s2m(pending) \
                          $s2m(unconfigured) \
                          $s2m(subscribed)] \
            -editable no \
            -width 12 \
            -textvariable [namespace current]::listdata($f,subscription,$row)
        grid $f.subscription$row -row $row -column 3 -sticky we -padx 1m
        bindscroll $f.subscription$row $sf

        incr row
    }

    set listdata($f,rows) $row
    array set origlistdata [array get listdata $f,*]
}

proc pubsub::list_add_item {sf f} {
    variable a2m
    variable s2m
    variable listdata

    debugmsg pubsub [info level 0]

    set row $listdata($f,rows)

    Entry $f.jid$row \
        -textvariable [namespace current]::listdata($f,jid,$row)
    grid $f.jid$row -row $row -column 0 -sticky we -padx 1m
    bindscroll $f.jid$row $sf

    Entry $f.subid$row \
        -textvariable [namespace current]::listdata($f,subid,$row)
    grid $f.subid$row -row $row -column 1 -sticky we -padx 1m
    bindscroll $f.subid$row $sf

    Combobox $f.affiliation$row \
        -values [list $a2m(owner) \
                      $a2m(publisher) \
                      $a2m(none) \
                      $a2m(outcast)] \
        -editable no \
        -width 9 \
        -textvariable [namespace current]::listdata($f,affiliation,$row)
    $f.affiliation$row set $a2m(none)
    grid $f.affiliation$row -row $row -column 2 -sticky we -padx 1m
    bindscroll $f.affiliation$row $sf

    Combobox $f.subscription$row \
        -values [list $s2m(none) \
                      $s2m(pending) \
                      $s2m(unconfigured) \
                      $s2m(subscribed)] \
        -editable no \
        -width 12 \
        -textvariable [namespace current]::listdata($f,subscription,$row)
    $f.subscription$row set $s2m(none)
    grid $f.subscription$row -row $row -column 3 -sticky we -padx 1m
    bindscroll $f.subscription$row $sf

    incr listdata($f,rows)
}

proc pubsub::send_entities {xlib service node w f} {
    variable origlistdata
    variable listdata

    debugmsg pubsub [info level 0]

    set entities {}

    for {set i 1} {$i < $origlistdata($f,rows)} {incr i} {
        set vars {}
        if {$listdata($f,affiliation,$i) != $origlistdata($f,affiliation,$i)} {
            lappend vars affiliation $listdata($f,affiliation,$i)
        }
        if {$listdata($f,subscription,$i) ne
                    $origlistdata($f,subscription,$i)} {
            lappend vars subscription $listdata($f,subscription,$i)
        }

        if {$vars != {} && $origlistdata($f,jid,$i) != ""} {
            lappend vars jid $origlistdata($f,jid,$i)
            lappend entities [::xmpp::xml::create entity \
                                        -attrs $vars]
        }
    }

    for {} {$i < $listdata($f,rows)} {incr i} {
        set vars1 {}
        set vars2 {}
        set vars3 {}
        if {$listdata($f,affiliation,$i) != ""} {
            lappend vars1 affiliation $listdata($f,affiliation,$i)
        }
        if {$listdata($f,subscription,$i) != ""} {
            lappend vars1 subscription $listdata($f,subscription,$i)
        }
        if {$listdata($f,jid,$i) != ""} {
            lappend vars2 jid $listdata($f,jid,$i)
        }
        if {$listdata($f,subid,$i) != ""} {
            lappend vars3 subid $listdata($f,subid,$i)
        }

        if {$vars1 != {} && $vars2 != {} && $vars3 != {}} {
            lappend entities [::xmpp::xml::create item \
                                    -attrs $vars2 \
                                    -attrs $vars3 \
                                    -attrs $vars1]
        }
    }

    set xlib [chat::get_xlib $chatid]
    set group [chat::get_jid $chatid]

    if {$entities != {}} {
        ::xmpp::sendIQ $xlib set \
            -query [::xmpp::xml::create pubsub \
                        -xmlns $::NS(pubsub) \
                        -subelement [::xmpp::xml::create entities \
                                        -attrs [list node $node] \
                                        -subelements $entities]] \
            -to $service
    # TODO error checking
    }
    destroy $w
}

proc pubsub::cleanup_entities {f} {
    variable listdata
    variable origlistdata

    debugmsg pubsub [info level 0]

    array unset listdata $f,*
    array unset origlistdata $f,*
}

##########################################################################
#
# Framework for handling of Pubsub event notifications.

proc pubsub::register_event_notification_handler {xmlns h} {
    variable handler
    variable supported_ns

    set handler($xmlns) $h
    set supported_ns [array names handler]
}

proc pubsub::process_event_notification \
     {xlib from mid type is_subject subject body \
      err thread priority x} {

    if {[string equal $type error]} return

    variable handler

    set res ""

    foreach event $x {
        ::xmpp::xml::split $event tag xmlns attrs cdata subels

        if {![string equal $tag event]} continue
        if {![string equal $xmlns $::xmpp::pubsub::ns(event)]} continue

        foreach item $subels {
            ::xmpp::xml::split $item stag sxmlns sattrs scdata ssubels

            if {![string equal $stag items]} continue

            set node [::xmpp::xml::getAttr $sattrs node]
            if {![info exists handler($node)]} continue

            set res stop
            {*}$handler($node) $xlib $from $ssubels
        }
    }

    return $res
}

hook::add process_message_hook pubsub::process_event_notification

##########################################################################

proc pubsub::disco_node_menu_setup {m bw tnode data parentdata} {
    lassign $data type xlib jid node
    lassign $parentdata ptype pxlib pjid pnode

    if {$pjid != $jid} return

    switch -- $type {
        item -
        item2 {
            set identities [disco::browser::get_identities $bw $tnode]

            if {[llength $identities] == 0} {
                set identities \
                    [disco::browser::get_parent_identities $bw $tnode]
            }

            foreach id $identities {
                if {[::xmpp::xml::getAttr $id category] == "pubsub"} {
                    $m add command \
                        -label [::msgcat::mc "Request default configuration"] \
                        -command [namespace code [list requestDefaultConfig \
                                        $xlib $jid \
                                        -command [namespace code test_error]]]

                    $m add command \
                        -label [::msgcat::mc "Retrieve subscriptions"] \
                        -command [namespace code [list requestSubscriptions \
                                        $xlib $jid $node \
                                        -command [namespace code test_error]]]

                    if {$node == ""} {
                        set state disabled
                    } else {
                        set state normal
                    }

                    $m add command -label [::msgcat::mc "Configure node"] \
                        -command [namespace code [list configureNode \
                                       $xlib $jid $node \
                                       -command [namespace code test_error]]] \
                        -state $state

                    $m add command -label [::msgcat::mc "Subscribe"] \
                        -command [list ::xmpp::pubsub::subscribe \
                                       $xlib $jid $node \
                                       -command [namespace code test_result]] \
                        -state $state

                    $m add command -label [::msgcat::mc "Unsubscribe"] \
                        -command [list ::xmpp::pubsub::unsubscribe \
                                       $xlib $jid $node \
                                       -command [namespace code test_result]] \
                        -state $state
                    return
                }
            }
        }
    }
}

hook::add disco_node_menu_hook pubsub::disco_node_menu_setup 60

proc pubsub::test_error {status xml} {
    if {[string equal $status ok]} {
        return
    }

    NonmodalMessageDlg [epath] \
            -aspect 50000 \
            -icon error \
            -title [::msgcat::mc "Error"] \
            -message [::msgcat::mc "Pubsub request failed: %s" \
                                   [error_to_string $xml]]
}

proc pubsub::test_result {status xml} {
    if {[string equal $status ok]} {
        NonmodalMessageDlg [epath] \
            -aspect 50000 \
            -icon warning \
            -title [::msgcat::mc "Success"] \
            -message [::msgcat::mc "Pubsub request succeeded"]
    } else {
        NonmodalMessageDlg [epath] \
            -aspect 50000 \
            -icon error \
            -title [::msgcat::mc "Error"] \
            -message [::msgcat::mc "Pubsub request failed: %s" \
                                   [error_to_string $xml]]
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
