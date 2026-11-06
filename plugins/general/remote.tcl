# remote.tcl --
#
#       Implementation of Remote Controlling Clients (XEP-0146)
#       via Ad-Hoc Commands (XEP-0050) for Tkabber.
#

namespace eval ::remote {
    variable commands
    variable sessions
    variable prefix

    array set commands {}
    array set sessions {}
    set prefix "::remote::sessions"

    custom::defgroup {Remote Control} \
        [::msgcat::mc "Remote control options."] -group Tkabber

    custom::defvar options(enable) 1 \
        [::msgcat::mc "Enable remote control."] \
        -type boolean -group {Remote Control}

    custom::defvar options(accept_from_myjid) 1 \
        [::msgcat::mc "Accept connections from my own JID."] \
        -type boolean -group {Remote Control}

    custom::defvar options(accept_list) "" \
        [::msgcat::mc "Accept connections from the listed JIDs."] \
        -type string -group {Remote Control}

    #custom::defvar options(show_my_resources) 1 \
    #        [::msgcat::mc "Show my own resources in the roster."] \
    #        -type boolean -group {Remote Control}
}
namespace eval ::remote::sessions {}

############################################

proc ::remote::allow_remote_control {xlib from} {
    variable options

    if {!$options(enable)} {
        return 0
    }

    set from [::xmpp::jid::normalize $from]
    set myjid [::xmpp::jid::normalize \
                      [::xmpp::jid::removeResource [connection_jid $xlib]]]
    set bare_from [::xmpp::jid::removeResource $from]

    if {$options(accept_from_myjid) && $myjid eq $bare_from} {
        return 1
    }

    set accept_list [split [string tolower $options(accept_list)] " "]
    if {$bare_from != "" && $bare_from in $accept_list} {
        return 1
    }

    return 0
}

############################################
# Register and announce commands via disco

proc ::remote::register_command {node command name args} {
    variable commands

    set commands(command,$node) $command
    set commands(name,$node) $name
    lappend commands(nodes) $node

    ::disco::register_subnode $node \
            [namespace code [list common_command_infoitems_handler $node]] \
            $name
}

proc ::remote::common_command_infoitems_handler {node type xlib from lang} {
    variable commands

    if {![allow_remote_control $xlib $from]} {
        return {error cancel not-allowed}
    }

    if {![string equal $node ""] && [info exists commands(command,$node)]} {
        if {[string equal $type info]} {
            return \
                [list result [list [list category automation \
                                         type command-node \
                                         name [::trans::trans $lang \
                                                    $commands(name,$node)]]] \
                             [list $::NS(commands)] {}]
        } else {
            return [list result {}]
        }
    } else {
        return {error modify bad-request}
    }
}

proc ::remote::commands_list_handler {type xlib from lang} {
    variable commands

    if {![allow_remote_control $xlib $from]} {
        return {error cancel not-allowed}
    }

    set myjid [connection_jid $xlib]

    switch -- $type {
        items {
            set items {}
            foreach node $commands(nodes) {
                lappend items [list jid $myjid \
                                    node $node \
                                    name [::trans::trans $lang \
                                                    $commands(name,$node)]]
            }
            return [list result $items]
        }
        info {
            return [list result [list [list category automation \
                                            type command-list \
                                            name [::trans::trans $lang \
                                                        "Remote control"]]] \
                                {} {}]
        }
    }
}

::disco::register_feature $::NS(commands)
::disco::register_node $::NS(commands) \
    ::remote::commands_list_handler [::trans::trans "Remote control"]

#######################################
# Base engine.

proc ::remote::clear_session {session node} {
    variable commands
    variable sessions

    if {![info exists commands(command,$node)]} return

    $commands(command,$node) $session cancel {}

    upvar 0 $session state
    catch {unset sessions($state(xlib),$state(from),$state(node),$state(id))}

    catch {unset $session}
}

proc ::remote::create_session {node xlib from lang} {
    variable commands
    variable sessions
    variable prefix

    if {![info exists commands(command,$node)]} return

    set id [rand 1000000000]
    while {[info exists sesssions($xlib,$from,$node,$id)]} {
        set id [rand 1000000000]
    }

    set counter 1
    while {[info exists "${prefix}::${counter}"]} {
        incr counter
    }

    set session "${prefix}::${counter}"
    upvar 0 $session state

    set state(id) $id
    set state(xlib) $xlib
    set state(from) $from
    set state(node) $node
    set state(lang) $lang
    set sessions($xlib,$from,$node,$id) $session

    return $session
}

proc ::remote::command_set_handler {xlib from child args} {
    variable commands
    variable sessions

    if {![allow_remote_control $xlib $from]} {
        return {error cancel not-allowed}
    }

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    set node [::xmpp::xml::getAttr $attrs node]
    set action [::xmpp::xml::getAttr $attrs action]
    set id [::xmpp::xml::getAttr $attrs sessionid]

    set lang [::xmpp::xml::getAttr $args -lang en]

    if {![info exists commands(command,$node)]} {
        return {error cancel item-not-found}
    }

    if {$id eq ""} {
        # We use lang only when create session.
        # Probably it would be better to use it after every request.
        set session [create_session $node $xlib $from $lang]
    } else {
        if {![info exists sessions($xlib,$from,$node,$id)]} {
            return [get_error modify bad-request bad-sessionid]
        }
        set session $sessions($xlib,$from,$node,$id)
    }

    upvar 0 $session state
    set id $state(id)

    if {$action eq "cancel"} {
        clear_session $session $node
        return [list result [::xmpp::xml::create command \
                                 -xmlns $::NS(commands) \
                                 -attrs [list sessionid $id \
                                              node $node \
                                              status canceled]]]
    }

    set result [$commands(command,$node) $session $action $subels]

    set status [lindex $result 0]
    switch -- $status {
        error {
            set error_type [lindex $result 1]
            if {$error_type ne "modify"} {
                clear_session $session $node
            }
            return $result
        }
        completed {
            clear_session $session $node
        }
        executing {}
        default {
            clear_session $session $node
            return {error wait internal-server-error}
        }
    }

    return [list result [::xmpp::xml::create command \
                             -xmlns $::NS(commands) \
                             -attrs [list sessionid $id \
                                          node $node \
                                          status $status] \
                             -subelements [lrange $result 1 end]]]
}

::xmpp::iq::register set command $::NS(commands) ::remote::command_set_handler

proc ::remote::get_error {type general {specific ""}} {
    set res [list error $type $general]
    if {$specific ne ""} {
        lappend res -application-specific \
            [::xmpp::xml::create $specific -xmlns $::NS(commands)]
    }
    return $res
}


############################################
# Common functions for command implementations.

# Scheduler for one-step dialogs and wizards
proc ::remote::standard_scheduler {steps prefix session action children} {
    upvar 0 $session state

    if {$action eq "cancel"} {
        for {set i 1} {$i <= $steps} {incr i} {
            ${prefix}clear_step$i $session
        }
        return
    }

    if {![info exists state(step)] } {
        # First step

        if {$action eq "execute" || $action eq ""} {

            set state(step) 1
            return [${prefix}get_step$state(step) $session]

        } else {
            return [::remote::get_error modify bad-request bad-action]
        }

    } elseif {($state(step) < $steps) && ($state(step) > 0)} {
        # Inner step
        if {$action eq "next" || $action eq "execute" || $action eq ""} {

            set res [${prefix}set_step$state(step) $session $children]
            if {[lindex $res 0] eq "error"} {
                return $res
            }

            incr state(step)
            return [${prefix}get_step$state(step) $session]

        } elseif {$action eq "prev"} {

            incr state(step) -1
            ${prefix}clear_step$state(step) $session

            return [${prefix}get_step$state(step) $session]

        } elseif {$action eq "complete"} {

            set res [${prefix}set_step$state(step) $session $children]
            if {[lindex $res 0] eq "error"} {
                return $res
            }

            return [${prefix}get_finish $session]

        } else {
            return [::remote::get_error modify bad-request bad-action]
        }


    } elseif {$state(step) == $steps} {
        # Last step
        if {$action eq "complete" || $action eq "execute" || $action eq ""} {

            set res [${prefix}set_step$state(step) $session $children]
            if {[lindex $res 0] eq "error"} {
                return $res
            }

            return [${prefix}get_finish $session]

        } elseif {$action eq "prev"} {

            incr state(step) -1
            ${prefix}clear_step$state(step) $session

            return [${prefix}get_step$state(step) $session]

        } else {
            return [::remote::get_error modify bad-request bad-action]
        }

    } else {
        return {error wait internal-server-error}
    }
}

# Parse form result and returns array with values, check for correct form type
proc ::remote::standard_parseresult {children_b form_type} {
    set result {}

    lassign [::xmpp::data::findForm $children_b] type form

    if {![string equal $type submit]} {
        return [::remote::get_error modify bad-request bad-payload]
    }

    foreach {tag field} [::xmpp::data::parseSubmit $form] {
        lassign $field var type label values
        switch -- $var {
            FORM_TYPE {
                if {![string equal [lindex $values 0] $form_type]} {
                    return [::remote::get_error modify bad-request bad-payload]
                }
            }
            default {
                lappend result $var $values
            }
        }
    }

    return $result
}

############################
#Change status
namespace eval ::remote::change_status {}

proc ::remote::change_status::scheduler {session action children} {
    return [::remote::standard_scheduler 1 "[namespace current]::" \
                                         $session $action $children]
}
::remote::register_command "http://jabber.org/protocol/rc#set-status" \
    ::remote::change_status::scheduler [::trans::trans "Change status"]

# step1:
# send standard form
proc ::remote::change_status::get_step1 {session} {
    global userstatus
    global textstatus
    global userpriority

    upvar 0 $session state
    set lang $state(lang)

    set fields \
        [concat [::xmpp::data::formField field \
                        -var FORM_TYPE \
                        -type hidden \
                        -value "http://jabber.org/protocol/rc"] \
                [::xmpp::data::formField title \
                        -value [::trans::trans $lang "Change Status"]] \
                [::xmpp::data::formField instructions \
                        -value [::trans::trans $lang \
                                    "Choose status, priority, and\
                                     status message"]]]

    set options {}
    foreach {status statusdesc} \
            [list available   [::trans::trans $lang "Available"]      \
                  chat        [::trans::trans $lang "Free to chat"]   \
                  away        [::trans::trans $lang "Away"]           \
                  xa          [::trans::trans $lang "Extended away"]  \
                  dnd         [::trans::trans $lang "Do not disturb"] \
                  unavailable [::trans::trans $lang "Unavailable"]] {
        lappend options $statusdesc $status
    }
    set fields \
        [concat $fields \
                [::xmpp::data::formField field \
                        -var status \
                        -type list-single \
                        -label [::trans::trans $lang "Status"] \
                        -required 1 \
                        -value $userstatus \
                        -options $options] \
                [::xmpp::data::formField field \
                        -var status-priority \
                        -type text-single \
                        -label [::trans::trans $lang "Priority"] \
                        -value $userpriority \
                        -required 1] \
                [::xmpp::data::formField field \
                        -var status-message \
                        -type text-multi \
                        -label [::trans::trans $lang "Message"] \
                        -values [split $textstatus "\n"]]]

    return [list executing [::xmpp::data::form $fields]]
}

proc ::remote::change_status::set_step1 {session children} {
    upvar 0 $session state

    set result [remote::standard_parseresult $children \
                                             "http://jabber.org/protocol/rc"]

    if {[lindex $result 0] eq "error"} {
        return $result
    }
    array set params $result

    if {![info exists params(status)] || \
        ![info exists params(status-priority)] || \
        ![info exists ::statusdesc($params(status))] || \
        [catch {expr int($params(status-priority))}]} {
        return [::remote::get_error modify bad-request bad-payload]
    }

    set state(textstatus) {}
    catch {
        set state(textstatus) \
            [join $params(status-message) "\n"]
    }

    set state(userstatus) \
        [lindex $params(status) 0]
    set state(userpriority) \
        [lindex $params(status-priority) 0]

    return {}
}

proc ::remote::change_status::clear_step1 {session} {}

# finish:
# change status
# report
proc ::remote::change_status::get_finish {session} {
    global userstatus
    global textstatus
    global userpriority

    upvar 0 $session state
    set lang $state(lang)

    if {$state(userstatus) != "unavailable"} {
        set textstatus $state(textstatus)
        set userpriority $state(userpriority)
        set userstatus $state(userstatus)
    } else {
        # Special processing -- disconnect current session.
        # It is scheduled for idle processing so that the remote-command
        # processing machinery has a chance to send the result.
        after idle [list ::logout $state(xlib)]
    }

    return [list completed [::xmpp::xml::create note \
                                -attrs {type info} \
                                -cdata \
                                    [::trans::trans $lang \
                                         "Status was changed successfully"]]]
}


############################
# Leave groupchats
namespace eval ::remote::leave_groupchats {}

proc ::remote::leave_groupchats::scheduler {session action children} {
    return [::remote::standard_scheduler 1 "[namespace current]::" $session $action $children]
}
::remote::register_command "http://jabber.org/protocol/rc#leave-groupchats" \
    ::remote::leave_groupchats::scheduler [::trans::trans "Leave groupchats"]

# step1:
# allow users to choose which chats to leave
proc ::remote::leave_groupchats::get_step1 {session} {
    upvar 0 $session state

    set options {}
    set lang $state(lang)
    set xlib $state(xlib)
    foreach chatid [lfilter chat::is_groupchat [chat::opened $xlib]] {
        set jid [chat::get_jid $chatid]
        if {[get_jid_presence_info show $xlib $jid] ne ""} {
            set nick [get_our_groupchat_nick $chatid]
            lappend options [format [::trans::trans $lang "%s at %s"] \
                                    $nick $jid] $jid
        }
    }
    if {[llength $options] == 0} {
        return [list completed [::xmpp::xml::create note \
                                    -attrs {type info} \
                                    -cdata [::trans::trans $lang \
                                                 "No groupchats to leave"]]]
    }

    set fields \
        [concat [::xmpp::data::formField field \
                        -var FORM_TYPE \
                        -type hidden \
                        -value "http://jabber.org/protocol/rc"] \
                [::xmpp::data::formField title \
                        -value [::trans::trans $lang "Leave Groupchats"]] \
                [::xmpp::data::formField instructions \
                        -value [::trans::trans $lang \
                                    "Choose groupchats you want to leave"]] \
                [::xmpp::data::formField field \
                        -var x-all \
                        -type boolean \
                        -label [::trans::trans $lang "Leave all groupchats"] \
                        -value 0] \
                [::xmpp::data::formField field \
                        -var groupchats \
                        -type list-multi \
                        -label [::trans::trans $lang "Groupchats"] \
                        -required 1 \
                        -options $options] \
                [::xmpp::data::formField field \
                        -var x-reason \
                        -type text-single \
                        -label [::trans::trans $lang "Reason"]]]

    return [list executing [::xmpp::data::form $fields]]
}

proc ::remote::leave_groupchats::set_step1 {session children} {
    upvar 0 $session state

    set result [remote::standard_parseresult $children \
                                             "http://jabber.org/protocol/rc"]
    if {[lindex $result 0] eq "error"} {
        return $result
    }
    array set params $result

    if {![info exists params(groupchats)]} {
        return [::remote::get_error modify bad-request bad-payload]
    }

    set state(all) [lindex $params(x-all) 0]
    set state(groupchats) $params(groupchats)
    set state(reason) ""
    catch {
        set state(reason) [lindex $params(x-reason) 0]
    }
    return {}

}

proc ::remote::leave_groupchats::clear_step1 {session} {}

# finish step
# leave groupchats.
# report
proc ::remote::leave_groupchats::get_finish {session} {
    upvar 0 $session state

    set xlib $state(xlib)
    set args {}
    set lang $state(lang)

    if {![string equal $state(reason) ""]} {
        lappend args -status $state(reason)
    }

    # "all" workaround, will be removed soon
    if $state(all) {
        set state(groupchats) ""

        foreach chatid [lfilter chat::is_groupchat [chat::opened $xlib]] {
            set jid [chat::get_jid $chatid]
            if {![string equal [get_jid_presence_info show $xlib $jid] ""]} {
                lappend state(groupchats) $jid
            }
        }
    }

    foreach jid $state(groupchats) {
        send_presence $xlib unavailable -to $jid {*}$args
    }

    return [list completed [::xmpp::xml::create note \
                                -attrs {type info} \
                                -cdata [::trans::trans $lang \
                                             "Groupchats were left\
                                              successfully"]]]
}

################################
# Forward unread messages
namespace eval ::remote::forward {
    variable unread
    array set unread {}
}

proc ::remote::forward::scheduler {session action children} {
    return [::remote::standard_scheduler 1 "[namespace current]::" $session $action $children]
}
::remote::register_command "http://jabber.org/protocol/rc#forward" \
    ::remote::forward::scheduler [::trans::trans "Forward unread messages"]

# step1:
# form with list of unreaded correspondence
proc ::remote::forward::get_step1 {session} {
    upvar 0 $session state
    variable unread

    set options {}
    set lang $state(lang)
    set xlib $state(xlib)
    foreach id [array names unread] {
        lassign $id type chatid
        if {[chat::get_xlib $chatid] ne $xlib} continue

        set jid [chat::get_jid $chatid]
        set rjid [::roster::find_jid $xlib $jid]
        set name [::roster::itemconfig $xlib $rjid -name]
        if {$rjid != "" && $name != ""} {
            set name [format "%s (%s)" $name $jid]
        } else {
            set name $jid
        }

        set count [llength $unread($id)]

        switch -- $type {
            chat      {set msg [::trans::trans $lang "%s: %s chat message(s)"]}
            groupchat {set msg [::trans::trans $lang "%s: %s groupchat message(s)"]}
            headline  {set msg [::trans::trans $lang "%s: %s headline message(s)"]}
            normal    {set msg [::trans::trans $lang "%s: %s normal message(s)"]}
            default   {set msg [::trans::trans $lang "%s: %s unknown message(s)"]}
        }

        lappend options [format $msg $name $count] $id
    }
    if {[llength $options] == 0} {
        return [list completed [::xmpp::xml::create note \
                                    -attrs {type info} \
                                    -cdata \
                                        [::trans::trans $lang \
                                             "There are no unread messages"]]]
    }

    set fields \
        [concat [::xmpp::data::formField field \
                            -var FORM_TYPE \
                        -type hidden \
                            -value "tkabber:plugins:remote:forward_form"] \
                [::xmpp::data::formField title \
                        -value [::trans::trans $lang \
                                    "Forward Unread Messages"]] \
                [::xmpp::data::formField instructions \
                        -value [::trans::trans $lang \
                                    "Choose chats or groupchats from which you\
                                     want to forward messages"]] \
                [::xmpp::data::formField field \
                        -var all \
                        -type boolean \
                        -label [::trans::trans $lang "Forward all messages"] \
                        -value 0] \
                [::xmpp::data::formField field \
                        -var chats \
                        -type list-multi \
                        -label [::trans::trans $lang "Forward messages from"] \
                        -required 1 \
                        -options $options]]

    return [list executing [::xmpp::data::form $fields]]
}

proc ::remote::forward::set_step1 {session children} {
    upvar 0 $session state

    set result [remote::standard_parseresult $children \
                                             "tkabber:plugins:remote:forward_form"]
    if {[lindex $result 0] eq "error"} {
        return $result
    }
    array set params $result

    if {![info exists params(chats)]} {
        return [::remote::get_error modify bad-request bad-payload]
    }

    set state(all) [lindex $params(all) 0]
    set state(chats) $params(chats)
    return {}
}

proc ::remote::forward::clear_step1 {session} {}

# finish:
# forward selected unread messages
# report
proc ::remote::forward::get_finish {session} {
    upvar 0 $session state
    variable unread

    set xlib $state(xlib)
    set lang $state(lang)
    set oto [connection_jid $xlib]
    set target $state(from)

    # "all" workaround, will be removed soon
    if $state(all) {
        set state(chats) {}

        foreach id [array names unread] {
            lassign $id type chatid
            if {[chat::get_xlib $chatid] ne $xlib} continue
            lappend state(chats) $id
        }
    }

    foreach id $state(chats) {
        forward_messages $id $xlib $oto $target
    }

    return [list completed \
                 [::xmpp::xml::create note \
                      -attrs {type info} \
                      -cdata [::trans::trans $lang \
                                   "Unread messages were forwarded\
                                    successfully"]]]
}

#############################
# Forward namespace

# forwards messages
# leaves marks that they were forwarded.
# cleanup arrays
proc ::remote::forward::forward_messages {id xlib oto target} {
    variable unread
    variable msgdata

    lassign $id type chatid

    if {![info exists unread($id)]} {
        return
    }

    foreach elem $unread($id) {

        switch -- $type {
            groupchat -
            chat {
                lassign $elem date ofrom body x
            }
            normal {
                lassign $msgdata($elem) date ofrom body x
            }
        }

        lappend x [::xmpp::xml::create addresses \
                       -xmlns $::NS(xaddress) \
                       -subelement [::xmpp::xml::create address \
                                           -attrs [list type ofrom \
                                                        jid $ofrom]] \
                       -subelement [::xmpp::xml::create address \
                                           -attrs [list type oto \
                                                        jid $oto]]]

        lappend x [::xmpp::delay::create $date]

        ::xmpp::sendMessage $xlib $target -body $body \
                                          -type $type \
                                          -xlist $x

        switch -- $type {
            normal {
                set lab \
                    [Label $elem.forwlab \
                           -text [::msgcat::mc \
                                      "This message was forwarded to %s" \
                                      $target]]
                pack $lab -anchor w -fill none -expand no -before $elem.title

                catch {unset msgdata($elem)}
            }
        }
    }

    catch {unset unread($id)}
    switch -- $type {
        groupchat -
        chat {
            after idle \
                  [list ::chat::add_message $chatid $ofrom info \
                        [::msgcat::mc "All unread messages were forwarded to %s." \
                             $target] \
                        {}]
        }
    }
}

# store message into the unread if type == chat
proc ::remote::forward::draw_message_handler {chatid from type body extras} {
    variable unread

    if {[ifacetk::chat_window_is_active $chatid]} return

    if {$type ni {chat groupchat}} return

    if {$from == ""} {
        # Don't forward service messages
        return
    }

    set date [clock seconds]
    set message [list $date $from $body $extras]
    set id [list $type $chatid]
    lappend unread($id) $message

    return 0
}

hook::add draw_message_hook ::remote::forward::draw_message_handler 19

# clear list of unread messages with type == chat
proc ::remote::forward::trace_number_msg {var1 chatid mode} {
    variable unread

    if {$::ifacetk::number_msg($chatid) == 0} {
        if {[chat::is_chat $chatid]} {
            set type chat
        } else {
            set type groupchat
        }
        set id [list $type $chatid]
        catch {unset unread($id)}
    }

}

trace add variable ::ifacetk::number_msg write ::remote::forward::trace_number_msg

# store message with type == normal
proc ::remote::forward::message_process_x \
     {rowvar bodyvar f x xlib from id type replyP} {
    upvar 2 $rowvar row
    upvar 2 $bodyvar body
    variable unread
    variable msgdata

    if {!$replyP || $type eq "error"} {
        return
    }

    set id [list normal [chat::chatid $xlib $from]]

    if {![info exists unread($id)]} {
        set unread($id) {}
    }

    set msgwin [winfo toplevel $f]
    lappend unread($id) $msgwin

    bind $f <Destroy> \
         +[double% [namespace code [list on_msgwin_destroy $msgwin $id]]]

    set date [clock seconds]
    set msgdata($msgwin) [list $date $from $body $x]

    return
}

hook::add message_process_x_hook ::remote::forward::message_process_x

# clear message with type == normal if it was closed
proc ::remote::forward::on_msgwin_destroy {msgwin id} {
    variable unread
    variable msgdata

    if {![info exists unread($id)]} return

    if {[set index [lsearch -exact $unread($id) $msgwin]] >= 0} {
        set unread($id) [lreplace $unread($id) $index $index]
        catch {unset msgdata($msgwin)}
    }

    if {[llength $unread($id)] == 0} {
        catch {unset unread($id)}
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
