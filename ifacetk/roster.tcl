# roster.tcl --
#
#       This file is a part of the Tkabebr XMPP client. It implements roster
#       widgets.

button .fakebutton
foreach {k v} [list background       $::defaultbackground \
                    activebackground $::defaultforeground] {
    if {[set b$k [.fakebutton cget -$k]] eq ""} {
        set b$k $v
    }
}
destroy .fakebutton

option add *Roster.groupindent            5.5555m            widgetDefault
option add *Roster.jidindent              11.1111m           widgetDefault
option add *Roster.jidmultindent          11.1111m           widgetDefault
option add *Roster.subjidindent           16.4m              widgetDefault
option add *Roster.groupiconindent         0.53m             widgetDefault
option add *Roster.subgroupiconindent      0.53m             widgetDefault
option add *Roster.iconindent             5.5555m            widgetDefault
option add *Roster.subiconindent          11.1111m           widgetDefault
option add *Roster.textuppad               0                 widgetDefault
option add *Roster.textdownpad             0                 widgetDefault
option add *Roster.linepad                 0.26m             widgetDefault

# Type of subitem in roster (1 - display number of resources,
# 2 - display arrow, 3 - display both, 0 - display nothing)
option add *Roster.subitemtype             3                 widgetDefault

option add *Roster.cbackground            $::defaultbackground widgetDefault
option add *Roster.foreground             $::defaultforeground widgetDefault
option add *Roster.jidfill                $::defaultbackground widgetDefault
option add *Roster.jidborder              $::defaultbackground widgetDefault
option add *Roster.connectionfill         $::defaultbackground widgetDefault
option add *Roster.connectioncfill        $::defaultbackground widgetDefault

option add *Roster.connectionhlfill       $bactivebackground widgetDefault
option add *Roster.connectionborder       $bbackground       widgetDefault

unset bbackground bactivebackground

if {$::darktheme} {
    option add *Roster.jidhlfill              #2b4b76            widgetDefault
    option add *Roster.metajidfill            #505050            widgetDefault
    option add *Roster.metajidhlfill          #520a60            widgetDefault
    option add *Roster.metajidborder          #505050            widgetDefault
    option add *Roster.groupfill              #5e5e5e            widgetDefault
    option add *Roster.groupcfill             #5e5e5e            widgetDefault
    option add *Roster.grouphlfill            #215388            widgetDefault
    option add *Roster.groupborder            #5e5e5e            widgetDefault
    option add *Roster.unsubscribedforeground tan                widgetDefault
    option add *Roster.unavailableforeground  grey72             widgetDefault
    option add *Roster.dndforeground          rosybrown1         widgetDefault
    option add *Roster.xaforeground           azure3             widgetDefault
    option add *Roster.awayforeground         azure3             widgetDefault
    option add *Roster.availableforeground    #ffffff            widgetDefault
    option add *Roster.chatforeground         #ffffff            widgetDefault
    option add *Roster.stalkerforeground      tan                widgetDefault
    option add *Roster.errforeground          coral3             widgetDefault
} else {
    option add *Roster.jidhlfill              #d1eeee            widgetDefault
    option add *Roster.metajidfill            #e7e7e7            widgetDefault
    option add *Roster.metajidhlfill          #c5e7e7            widgetDefault
    option add *Roster.metajidborder          #e7e7e7            widgetDefault
    option add *Roster.groupfill              #dddddd            widgetDefault
    option add *Roster.groupcfill             #dddddd            widgetDefault
    option add *Roster.grouphlfill            #b4cdcd            widgetDefault
    option add *Roster.groupborder            #dddddd            widgetDefault
    option add *Roster.unsubscribedforeground #663333            widgetDefault
    option add *Roster.unavailableforeground  #515151            widgetDefault
    option add *Roster.dndforeground          #515129            widgetDefault
    option add *Roster.xaforeground           #0b3760            widgetDefault
    option add *Roster.awayforeground         #0b3760            widgetDefault
    option add *Roster.availableforeground    dodgerblue4        widgetDefault
    option add *Roster.chatforeground         dodgerblue4        widgetDefault
    option add *Roster.stalkerforeground      #663333            widgetDefault
    option add *Roster.errforeground          firebrick          widgetDefault
}

namespace eval roster {
    custom::defgroup Roster [::msgcat::mc "Roster options."] -group Tkabber
    custom::defvar show_only_online 0 \
        [::msgcat::mc "Show only online users in roster."] \
        -type boolean -group Roster \
        -command [namespace current]::redraw_after_idle
    custom::defvar show_transport_icons 0 \
        [::msgcat::mc "Show native icons for transports/services in roster."] \
        -type boolean -group Roster \
        -command [namespace current]::redraw_after_idle
    custom::defvar show_transport_user_icons 0 \
        [::msgcat::mc "Show native icons for contacts, connected to\
                       transports/services in roster."] \
        -type boolean -group Roster \
        -command [namespace current]::redraw_after_idle
    custom::defvar options(nested) 0 \
        [::msgcat::mc "Enable nested roster groups."] \
        -type boolean -group Roster \
        -command [namespace current]::redraw_after_idle
    custom::defvar options(nested_delimiter) "::" \
        [::msgcat::mc "Default nested roster group delimiter."] \
        -type string -group Roster \
        -command [namespace current]::redraw_after_idle
    custom::defvar options(show_own_resources) 0 \
        [::msgcat::mc "Show my own resources in the roster."] \
        -type boolean -group Roster \
        -command [namespace current]::redraw_after_idle
    custom::defvar options(chats_group) 0 \
        [::msgcat::mc "Add chats group in roster."] \
        -type boolean -group Roster \
        -command [namespace current]::redraw_after_idle
    custom::defvar options(use_filter) 0 \
        [::msgcat::mc "Use roster filter."] \
        -type boolean -group Roster \
        -command [namespace current]::pack_filter_entry
    custom::defvar options(match_jids) 0 \
        [::msgcat::mc "Match contact JIDs in addition to nicknames in\
                       roster filter."] \
        -type boolean -group Roster \
        -command [namespace current]::redraw_after_idle
    custom::defvar options(enable_metacontacts) 1 \
        [::msgcat::mc "Enable grouping contacts into a single metacontact\
                       in roster."] \
        -type boolean -group Roster \
        -command [namespace current]::redraw_after_idle
    custom::defvar options(enable_metacontact_labels) 1 \
        [::msgcat::mc "Always use main JID label for metacontact."] \
        -type boolean -group Roster \
        -command [namespace current]::redraw_after_idle
    custom::defvar options(free_drop) 1 \
        [::msgcat::mc "Roster item may be dropped not only over group name\
but also over any item in group."] \
        -type boolean -group Roster
    custom::defvar options(show_subscription) 0 \
        [::msgcat::mc "Show subscription type in roster item tooltips."] \
        -type boolean -group Roster
    custom::defvar options(show_conference_user_info) 0 \
        [::msgcat::mc "Show detailed info on conference room members in\
                       roster item tooltips."] \
        -type boolean -group Roster
    custom::defvar options(chat_on_doubleclick) 1 \
        [::msgcat::mc "If set then open chat window/tab when user\
                       doubleclicks roster item.\
                       Otherwise open normal message window."] \
        -type boolean -group Roster

#   {jid1 {group1 1 group2 0} jid2 {group3 0 group4 0}}
    custom::defvar collapsed_group_list {} \
        [::msgcat::mc "Stored collapsed roster groups."] \
        -type string -group Hidden
#   {jid1 {group1 1 group2 0} jid2 {group3 0 group4 0}}
    custom::defvar show_offline_group_list {} \
        [::msgcat::mc "Stored show offline roster groups."] \
        -type string -group Hidden
    custom::defvar options(filter) "" \
        [::msgcat::mc "Roster filter."] \
        -type string -group Hidden \
        -command [namespace current]::redraw_after_idle

    variable menu_item_idx 0

    variable undef_group_name $::roster::undef_group_name
    variable chats_group_name $::roster::chats_group_name
    variable own_resources_group_name $::roster::own_resources_group_name
}

proc roster::get_group_lists {xlib} {
    variable collapsed_group_list
    variable show_offline_group_list
    variable options
    variable roster

    set jid [::xmpp::jid::normalize [connection_bare_jid $xlib]]
    array set c $collapsed_group_list
    array set s $show_offline_group_list

    if {[info exists c($jid)]} {
        foreach {group val} $c($jid) {
            if {$options(nested)} {
                set gid [list $xlib [msplit $group $options(nested_delimiter)]]
            } else {
                set gid [list $xlib [list $group]]
            }
            set roster(collapsed,$gid) $val
        }
    }

    if {[info exists s($jid)]} {
        foreach {group val} $s($jid) {
            if {$options(nested)} {
                set gid [list $xlib [msplit $group $options(nested_delimiter)]]
            } else {
                set gid [list $xlib [list $group]]
            }
            set roster(show_offline,$gid) $val
        }
    }
}

hook::add connected_hook [namespace current]::roster::get_group_lists 1

proc roster::set_group_lists {xlib} {
    variable collapsed_group_list
    variable show_offline_group_list
    variable options
    variable roster
    variable undef_group_name
    variable chats_group_name

    set jid [::xmpp::jid::normalize [connection_bare_jid $xlib]]
    array set c $collapsed_group_list
    array set s $show_offline_group_list

    set groups [roster::get_groups $xlib -raw 1]
    lappend groups $undef_group_name $chats_group_name

    if {$options(nested)} {
        set tmp {}
        foreach group $groups {
            set tmp1 [msplit $group $options(nested_delimiter)]
            for {set i 0} {$i < [llength $tmp1]} {incr i} {
                lappend tmp [lrange $tmp1 0 $i]
            }
        }
        set groups [lsort -unique $tmp]
    }

    set c($jid) {}
    set s($jid) {}
    foreach group $groups {
        if {$options(nested)} {
            set grname [join $group $options(nested_delimiter)]
            set gid [list $xlib $group]
        } else {
            set grname $group
            set gid [list $xlib [list $group]]
        }
        if {[info exists roster(collapsed,$gid)] && $roster(collapsed,$gid)} {
            lappend c($jid) $grname $roster(collapsed,$gid)
        }
        if {[info exists roster(show_offline,$gid)] &&
                $roster(show_offline,$gid)} {
            lappend s($jid) $grname $roster(show_offline,$gid)
        }
    }

    if {[llength $c($jid)] == 0} {
        unset c($jid)
    }
    if {[llength $s($jid)] == 0} {
        unset s($jid)
    }

    set collapsed_group_list [array get c]
    set show_offline_group_list [array get s]
}

hook::add disconnected_hook [namespace current]::roster::set_group_lists 40

proc roster::process_item {xlib jid name groups subsc ask} {
    execute_script_after_idle [list [namespace parent]::update_chat_titles] {}
}

hook::add roster_push_hook [namespace current]::roster::process_item 90

proc roster::create_filter_entry {} {
    Entry .roster_filter -textvariable [namespace current]::options(filter) \
                         -width 1
    bind .roster_filter <Escape> \
         [list set [namespace current]::options(filter) ""]
    pack_filter_entry
}

hook::add finload_hook [namespace current]::roster::create_filter_entry

proc roster::pack_filter_entry {args} {
    global usetabbar
    variable options

    if {![winfo exists .roster_filter]} return

    if {$options(use_filter)} {
        if {$usetabbar} {
            grid .roster_filter -row 1 \
                                -column 0 \
                                -sticky we \
                                -in $::ifacetk::rw
        } else {
            grid .roster_filter -row 2 \
                                -column 1 \
                                -sticky we \
                                -in [$::ifacetk::mf getframe]
        }
        focus .roster_filter
    } else {
        grid forget .roster_filter
    }
    redraw_after_idle
}

proc roster::filter_match {xlib jid} {
    variable options

    if {$options(use_filter) && $options(filter) ne ""} {
        if {[string first [string tolower $options(filter)] \
                    [string tolower [::roster::get_label $xlib $jid]]] < 0} {
            if {!$options(match_jids) || \
                    [string first [string tolower $options(filter)] \
                                  [string tolower $jid]] < 0} {
                return 0
            }
        }
    }

    return 1
}

proc roster::redraw {args} {
    variable roster
    variable options
    variable config
    variable show_only_online
    variable show_transport_user_icons
    variable undef_group_name
    variable chats_group_name
    variable own_resources_group_name

    clear .roster 0

    set connections [connections]
    switch -- [llength $connections] {
        0 {
            update_scrollregion .roster
            return
        }
        1 {
            set draw_connection 0
        }
        default {
            set draw_connection 1
        }
    }

    foreach xlib $connections {

        # TODO: Move to a plugin
        # Preparing metacontacts.
        array unset metajids
        array unset metagroups
        array unset groups_from_meta
        set metacontacted {}
        if {$options(enable_metacontacts) && \
                [llength [info procs ::plugins::metacontacts::*]] > 0} {
            foreach tag [::plugins::metacontacts::get_all_tags $xlib] {
                set jids [::plugins::metacontacts::get_jids $xlib $tag]
                set metagroups($tag) {}

                set cgroups {}
                foreach jid $jids {
                    # Skip JID if it doesn't match filter pattern or if it
                    # isn't a JID of use
                    set isuser [::roster::itemconfig $xlib $jid -isuser]
                    if {$isuser eq ""} {
                        set isuser 1
                    }
                    if {$isuser} {
                        set cgroups \
                            [concat $cgroups \
                                    [::roster::itemconfig $xlib $jid -group]]
                    }
                    if {$isuser && [filter_match $xlib $jid]} {
                        lappend metagroups($tag) $jid
                        lappend metacontacted $jid
                    }
                }

                if {[llength $metagroups($tag)] == 0} continue

                set mjid [lindex $metagroups($tag) 0]
                set pjid [get_jid_of_user $xlib $mjid]
                set priority [get_jid_presence_info priority $xlib $pjid]
                set status [get_jid_status $xlib $pjid]

                foreach rjid [lrange $metagroups($tag) 1 end] {
                    set jid  [get_jid_of_user $xlib $rjid]
                    set stat [get_jid_status $xlib $jid]

                    if {$stat eq "unavailable"} continue

                    set prio [get_jid_presence_info priority $xlib $jid]
                    if {$prio eq ""} {
                        set prio 0
                    }

                    if {$prio > $priority ||
                            ($prio == $priority &&
                             [compare_status $stat $status] > 0)} {
                        set mjid $rjid
                        set pjid $jid
                        set status $stat
                        set priority $prio
                    }
                }

                lappend metajids($mjid) $tag
                if {![info exists groups_from_meta($mjid)]} {
                    set groups_from_meta($mjid) $cgroups
                } else {
                    set groups_from_meta($mjid) \
                        [concat $groups_from_meta($mjid) $cgroups]
                }
            }

            foreach jid [array names metajids] {
                set metajids($jid) [lsort -unique $metajids($jid)]
            }
            set metacontacted [lsort -unique $metacontacted]
        }

        # Draw connection group
        if {$draw_connection} {
            if {![info exists roster(collapsed,[list xlib $xlib])]} {
                set roster(collapsed,[list xlib $xlib]) 0
            }
            addline .roster connection \
                            [connection_jid $xlib] \
                            [list xlib $xlib] \
                            [list xlib $xlib] \
                            {} 0

            if {$roster(collapsed,[list xlib $xlib])} {
                continue
            }
        }

        # Don't draw roster if it doesn't contain items
        if {[llength [::roster::get_jids $xlib]] == 0} {
            continue
        }

        # List of pairs {"group string for sorting",
        #                "group split on delimiter"}
        set groups {}

        # Array of lists of JIDs in group
        array unset jidsingroup

        # Array of lists of JIDs in group descendants
        array unset jidsundergroup

        # Array of lists of subgroups
        array unset groupsundergroup

        array unset jstat
        array unset useronline

        foreach jid [::roster::get_jids $xlib] {
            # Skip JID if it doesn't match filter pattern
            if {![filter_match $xlib $jid]} continue

            # TODO: Move to the metacontacts plugin
            # Skip JID if it should be ignored because of metacontacts
            if {$jid in $metacontacted && ![info exists metajids($jid)]} {
                continue
            }

            # Add JID groups to a groups list
            set jid_groups [::roster::itemconfig $xlib $jid -group]

            if {[info exists groups_from_meta($jid)]} {
                set jid_groups [concat $jid_groups $groups_from_meta($jid)]
            }

            if {[llength $jid_groups] > 0} {
                foreach group $jid_groups {
                    if {$options(nested)} {
                        set sgroup [msplit $group $options(nested_delimiter)]
                    } else {
                        set sgroup [list $group]
                    }

                    # Use the fact that -dictionary sorting puts \u0000 before
                    # any other character, so subgroups will be placed just
                    # after their parent group
                    lappend groups [list [join $sgroup "\u0000"] $sgroup]

                    lappend jidsingroup($sgroup) $jid

                    if {![info exists jidsundergroup($sgroup)]} {
                        set jidsundergroup($sgroup) {}
                    }

                    if {![info exists groupsundergroup($sgroup)]} {
                        set groupsundergroup($sgroup) {}
                    }

                    for {set i [expr {[llength $sgroup] - 2}]} {$i >= 0} \
                                                                  {incr i -1} {
                        # Adding all parent groups to a group list
                        set sgr [lrange $sgroup 0 $i]

                        lappend groups [list [join $sgr "\u0000"] $sgr]

                        lappend jidsundergroup($sgr) $jid

                        lappend groupsundergroup($sgr) $sgroup

                        if {![info exists jidsingroup($sgr)]} {
                            set jidsingroup($sgr) {}
                        }
                    }
                }
            } else {
                set sgroup [list $undef_group_name]

                lappend jidsingroup($sgroup) $jid

                if {![info exists jidsundergroup($sgroup)]} {
                    set jidsundergroup($sgroup) {}
                }

                set groupsundergroup($sgroup) {}
            }
        }

        set groups [lsort -unique -dictionary -index 0 $groups]

        # FIXME: What to do with subgroups of $undef_group_name?
        # Putting undefined group to the and of list
        set ugroup [list $undef_group_name]
        if {[info exists jidsingroup($ugroup)]} {
            lappend groups [list [join $ugroup "\u0000"] $ugroup]
        }

        # Putting active chats group to the beginning
        if {$options(chats_group)} {
            set cgroup [list $chats_group_name]
            foreach chatid [chat::opened $xlib] {
                set jid [chat::get_jid $chatid]
                lappend jidsingroup($cgroup) $jid
                if {[roster::itemconfig $xlib $jid -isuser] eq ""} {
                    roster::itemconfig $xlib $jid \
                            -name [chat::get_nick $xlib $jid chat]
                    roster::itemconfig $xlib $jid -subsc none
                }
            }
            if {[info exists jidsingroup($cgroup)]} {
                set groups \
                    [linsert $groups 0 [list [join $cgroup "\u0000"] $cgroup]]
            }
            set groupsundergroup($cgroup) {}
            set jidsundergroup($cgroup) {}
        }

        # Putting own resources group to the beginning
        if {$options(show_own_resources)} {
            set cgroup [list $own_resources_group_name]
            set jid [::xmpp::jid::normalize [connection_bare_jid $xlib]]
            set jidsingroup($cgroup) [list $jid]
            set groups \
                [linsert $groups 0 [list [join $cgroup "\u0000"] $cgroup]]
            roster::itemconfig $xlib $jid -subsc both
            set groupsundergroup($cgroup) {}
            set jidsundergroup($cgroup) {}
        }

        # Info on whether to show offline users in a group is needed for
        # subgroups too, so an extra loop
        foreach group $groups {
            set group [lindex $group 1]
            set gid [list $xlib $group]
            if {![info exists roster(show_offline,$gid)]} {
                set roster(show_offline,$gid) 0
            }
        }

        # Drawing groups an JIDs in them
        foreach group $groups {
            set group [lindex $group 1]
            set gid [list $xlib $group]

            set jidsingroup($group) [lsort -unique $jidsingroup($group)]
            set groupsundergroup($group) \
                [lsort -unique $groupsundergroup($group)]

            if {![info exists roster(collapsed,$gid)]} {
                set roster(collapsed,$gid) 0
            }

            # How to indent the group (also, the number of its ancestors)
            set indent [expr {[llength $group] - 1}]

            # Whether to draw group at all
            set collapse 0

            # Whether to show offline users in the group
            set show_offline_users 0

            # Whether to show the group ???
            set show_offline_group 0

            foreach undergroup $groupsundergroup($group) {
                if {$roster(show_offline,[list $xlib $undergroup])} {
                    set show_offline_group 1
                    break
                }
            }
            for {set i 0} {$i < $indent} {incr i} {
                set sgr [list $xlib [lrange $group 0 $i]]
                if {$roster(collapsed,$sgr)} {
                    # Whether some ancestor is collapsed
                    set collapse 1
                    break
                }
                if {$roster(show_offline,$sgr)} {
                    # Whether showing offline users is required for some
                    # ancestor
                    set show_offline_users 1
                    set show_offline_group 1
                }
            }

            # If some ancestor is collapsed don't draw the group
            if {$collapse} continue

            set group_label [lindex $group end]
            set online 0
            set users 0
            set not_users 0
            foreach jid [concat $jidsingroup($group) $jidsundergroup($group)] {
                if {[::roster::itemconfig $xlib $jid -isuser]} {
                    incr users
                    if {![info exists jstat($jid)]} {
                        set jstat($jid) [get_user_status $xlib $jid]
                    }
                    if {$jstat($jid) ne "unavailable"} {
                        incr online
                        set useronline($jid) 1
                    } else {
                        set useronline($jid) 0
                    }
                } else {
                    incr not_users
                }
            }

            # Draw group label
            if {!$show_only_online || $show_offline_group || \
                    $roster(show_offline,$gid) || \
                    ($options(use_filter) && $options(filter) ne "") || \
                    $online + $not_users > 0} {
                if {$users > 0} {
                    append group_label " ($online/$users)"
                }
                addline .roster group $group_label $gid $gid {} $indent
            }

            # Draw group contents if it isn't collapsed
            if {!$roster(collapsed,$gid)} {
                set jid_labels {}
                foreach jid $jidsingroup($group) {
                    lappend jid_labels \
                            [list $jid [::roster::get_label $xlib $jid]]
                }
                set jid_labels [lsort -index 1 -dictionary $jid_labels]

                foreach jid_label $jid_labels {
                    lassign $jid_label jid label

                    if {$options(chats_group)} {
                        set chatid [chat::chatid $xlib $jid]
                        if {[info exists ::chat::chats(messages,$chatid)] && \
                                $::chat::chats(messages,$chatid) > 0} {
                            append label " ($::chat::chats(messages,$chatid))"
                        }
                    }

                    set condition \
                        [expr {!$show_only_online || $show_offline_users ||
                               $roster(show_offline,$gid) ||
                               ($options(use_filter) &&
                                $options(filter) ne "")}]
                    set cjid [list $xlib $jid]
                    if {$condition || ![info exists useronline($jid)] ||
                                $useronline($jid)} {

                        if {[info exists metajids($jid)]} {

                            set jids {}
                            foreach tag $metajids($jid) {
                                foreach subjid $metagroups($tag) {
                                    # Metacontact members are necessarily
                                    # users, so don't check for this
                                    if {![info exists jstat($subjid)]} {
                                        set jstat($subjid) \
                                            [get_user_status $xlib $subjid]
                                    }
                                    if {$jstat($subjid) ne "unavailable"} {
                                        set useronline($subjid) 1
                                    } else {
                                        set useronline($subjid) 0
                                    }
                                    if {$condition || $useronline($subjid)} {
                                        lappend jids $subjid
                                    }
                                }
                            }
                            set jids [lsort -unique $jids]
                            set numjids [llength $jids]

                            if {$options(enable_metacontact_labels)} {
                                set tag [lindex $metajids($jid) 0]
                                set mjid \
                                    [lindex [::plugins::metacontacts::get_jids\
                                             $xlib $tag] 0]
                                set label [::roster::get_label $xlib $mjid]
                            }

                            if {($options(enable_metacontact_labels) &&
                                    $numjids > 0) || $numjids > 1} {
                                # Draw as a metacontact
                                if {$config(subitemtype) & 1} {
                                    append label " ($numjids)"
                                }
                                addline .roster metajid $label $cjid $gid \
                                                [list $xlib $metajids($jid)] \
                                                $indent $jids \
                                                [get_jid_icon $xlib $jid] \
                                                [get_jid_foreground $xlib $jid]

                                if {!$roster(metacollapsed,$gid,[list $xlib \
                                                           $metajids($jid)])} {
                                    set subjid_labels {}
                                    foreach subjid $jids {
                                        lappend subjid_labels \
                                            [list $subjid [::roster::get_label\
                                                                $xlib $subjid]]
                                    }
                                    set subjid_labels \
                                        [lsort -index 1 -dictionary \
                                                $subjid_labels]
                                    foreach subjid_label $subjid_labels {
                                        lassign $subjid_label subjid label
                                        draw_jid $xlib $subjid $label $gid \
                                                 [list $xlib $metajids($jid)] \
                                                 $indent jstat
                                    }
                                }
                            } else {
                                # Draw as an ordinary contact using a hack with
                                # indent which allows to add metajid tag. The
                                # hack depends on metajid indent equals to
                                # group indent
                                draw_jid $xlib $jid $label $gid \
                                         [list $xlib $metajids($jid)] \
                                         [expr {$indent - 1}] jstat
                            }
                        } else {
                            draw_jid $xlib $jid $label $gid {} $indent jstat
                        }
                    }
                }
            }
        }
    }

    update_scrollregion .roster
}

proc roster::draw_jid {xlib jid label gid metajids indent jstatVar} {
    variable config
    variable roster
    variable show_transport_user_icons
    upvar $jstatVar jstat

    set cjid [list $xlib $jid]
    lassign [::roster::get_category_and_subtype $xlib $jid] category type

    set jids [get_jids_of_user $xlib $jid]
    set numjids [llength $jids]

    if {$category eq "user" && $numjids > 1 && $config(subitemtype) > 0} {

        if {$config(subitemtype) & 1} {
            append label " ($numjids)"
        }
        addline .roster jid $label $cjid $gid $metajids $indent $jids \
                        [get_jid_icon $xlib $jid] \
                        [get_jid_foreground $xlib $jid]

        if {!$roster(jidcollapsed,$gid,$cjid)} {
            foreach subjid $jids {
                set subjid_resource [::xmpp::jid::resource $subjid]
                if {$subjid_resource ne ""} {
                    addline .roster jid2 \
                                    $subjid_resource [list $xlib $subjid] \
                                    $gid $metajids $indent \
                                    [list $subjid] \
                                    [get_jid_icon $xlib $subjid] \
                                    [get_jid_foreground $xlib $subjid]
                }
            }
        }
    } elseif {$category eq "user" && $numjids <= 1 && !$show_transport_user_icons} {

        if {[info exists jstat($jid)]} {
            set status $jstat($jid)
        } else {
            set status [get_user_status $xlib $jid]
        }

        set subsc [::roster::itemconfig $xlib $jid -subsc]
        if {$subsc in {from none} && $status eq "unavailable"} {
            set status unsubscribed
        }
        addline .roster jid $label $cjid $gid $metajids $indent $jids \
                        roster/user/$status \
                        $config(${status}foreground)
    } else {
        if {$category eq "conference" && ($config(subitemtype) & 1) &&
                    $numjids > 1} {
            append label " ([incr numjids -1])"
        }
        addline .roster jid $label $cjid $gid $metajids $indent $jids \
                        [get_jid_icon $xlib $jid] \
                        [get_jid_foreground $xlib $jid]
    }
}

proc roster::redraw_after_idle {args} {
    if {![winfo exists .roster.canvas]} return
    execute_script_after_idle [list [namespace current]::redraw] {}
}

# Callback
proc ::redraw_roster {args} {
    ifacetk::roster::redraw_after_idle
}

proc roster::get_jids_of_user {xlib user} {
    # TODO: metacontacts
    return [::get_jids_of_user $xlib $user]
}

proc roster::get_foreground {status} {
    variable config

    return $config(${status}foreground)
}

proc roster::get_jid_foreground {xlib jid} {
    variable config

    lassign [::roster::get_category_and_subtype $xlib $jid] category type

    switch -- $category {
        "" -
        user {
            return [get_user_foreground $xlib $jid]
        }
        conference {
            if {[get_jid_status $xlib $jid] ne "unavailable"} {
                return $config(availableforeground)
            } else {
                return $config(unavailableforeground)
            }
        }
        server  -
        gateway -
        service {
            return [get_service_foreground $xlib $jid $type]
        }
        default {
            return $config(foreground)
        }
    }
}

proc roster::get_service_foreground {xlib service type} {
    variable config

    switch -- $type {
        jud {
            return $config(foreground)
        }
    }

    if {[::roster::itemconfig $xlib $service -subsc] ne "none"} {
        set status [get_user_status $xlib $service]
        return $config(${status}foreground)
    } else {
        return $config(unsubscribedforeground)
    }
}

proc roster::get_user_foreground {xlib user} {
    variable config

    set status [get_user_status $xlib $user]

    set subsc [::roster::itemconfig $xlib $user -subsc]
    if {$subsc eq ""} {
        set ruser [::roster::find_jid $xlib $user]
        if {$ruser ne ""} {
            set subsc [::roster::itemconfig $xlib $ruser -subsc]
        } else {
            set subsc none
        }
    }

    if {$subsc in {from none} && $status eq "unavailable"} {
        return $config(unsubscribedforeground)
    } else {
        return $config(${status}foreground)
    }
}

proc roster::get_jid_icon {xlib jid {status ""}} {
    lassign [::roster::get_category_and_subtype $xlib $jid] category type

    switch -- $category {
        "" -
        user {
            if {$status eq ""} {
                set status [get_user_status $xlib $jid]
            }
            return [get_user_icon $xlib $jid $status]
        }
        conference {
            if {$status eq ""} {
                set status [get_jid_status $xlib $jid]
            }
            if {$status ne "unavailable"} {
                return roster/conference/available
            }
            return roster/conference/unavailable
        }
        server  -
        gateway -
        service {
            if {$status eq ""} {
                set status [get_user_status $xlib $jid]
            }
            return [get_service_icon $xlib $jid $type $status]
        }
        default {
            if {$status eq ""} {
                set status [get_jid_status $xlib $jid]
            }
            return [get_user_icon $xlib $jid $status]
        }
    }
}

proc roster::get_service_icon {xlib service type status} {
    variable show_transport_icons

    if {$show_transport_icons} {
        switch -- $type {
            jud {return services/jud}
            sms {return services/sms}
        }
        if {[::roster::itemconfig $xlib $service -subsc] ne "none"} {
            if {![catch { image type services/$type/$status }]} {
                return services/$type/$status
            } else {
                return roster/user/$status
            }
        } else {
            return roster/user/unsubscribed
        }
    } else {
        if {[::roster::itemconfig $xlib $service -subsc] ne "none"} {
            return roster/user/$status
        } else {
            return roster/user/unsubscribed
        }
    }
}

proc roster::get_user_icon {xlib user status} {
    variable show_transport_user_icons

    set subsc [::roster::itemconfig $xlib $user -subsc]
    if {$subsc eq ""} {
        set ruser [::roster::find_jid $xlib $user]
        if {$ruser ne ""} {
            set subsc [::roster::itemconfig $xlib $ruser -subsc]
        }
    }

    if {$subsc ni {from none} || $status ne "unavailable"} {
        if {$show_transport_user_icons} {
            set service [::xmpp::jid::server $user]
            lassign [::roster::get_category_and_subtype $xlib $service] \
                    category type
            switch -glob -- $category/$type {
                directory/* -
                */jud {
                    return services/jud
                }
                */sms {
                    return services/sms
                }
            }
            if {![catch { image type services/$type/$status }]} {
                return services/$type/$status
            } else {
                return roster/user/$status
            }
        } else {
            return roster/user/$status
        }
    } else {
        return roster/user/unsubscribed
    }
}

proc roster::changeicon {w jid icon} {
    set c $w.canvas
    set tag [jid_to_tag $jid]

    $c itemconfigure jid$tag&&icon -image $icon
}

proc roster::changeforeground {w jid color} {
    set c $w.canvas
    set tag [jid_to_tag $jid]

    $c itemconfigure jid$tag&&text -fill $color
}

proc roster::create {w args} {
    variable iroster
    variable config

    set c $w.canvas

    set width 150
    set height 100
    set popupproc {}
    set grouppopupproc {}
    set singleclickproc {}
    set doubleclickproc {}
    foreach {attr val} $args {
        switch -- $attr {
            -width {set width $val}
            -height {set height $val}
            -popup {set popupproc $val}
            -grouppopup {set grouppopupproc $val}
            -singleclick {set singleclickproc $val}
            -doubleclick {set doubleclickproc $val}
            -draginitcmd {set draginitcmd $val}
            -dropovercmd {set dropovercmd $val}
            -dropcmd {set dropcmd $val}
        }
    }

    frame $w -relief flat -borderwidth 0 -class Roster
    set sw [ScrolledWindow $w.sw -scrollbar vertical]
    pack $sw -fill both -expand yes

    set config(groupindent)         [winfo pixels $w [option get $w groupindent        Roster]]
    set config(jidindent)           [winfo pixels $w [option get $w jidindent          Roster]]
    set config(jidmultindent)       [winfo pixels $w [option get $w jidmultindent      Roster]]
    set config(jid2indent)          [winfo pixels $w [option get $w subjidindent       Roster]]
    set config(groupiconindent)     [winfo pixels $w [option get $w groupiconindent    Roster]]
    set config(subgroupiconindent)  [winfo pixels $w [option get $w subgroupiconindent Roster]]
    set config(iconindent)          [winfo pixels $w [option get $w iconindent         Roster]]
    set config(subiconindent)       [winfo pixels $w [option get $w subiconindent      Roster]]
    set config(textuppad)           [winfo pixels $w [option get $w textuppad          Roster]]
    set config(textdownpad)         [winfo pixels $w [option get $w textdownpad        Roster]]
    set config(linepad)             [winfo pixels $w [option get $w linepad            Roster]]
    set config(subitemtype)         [option get $w subitemtype         Roster]
    set config(background)          [option get $w cbackground         Roster]
    set config(metajidfill)         [option get $w metajidfill         Roster]
    set config(metajidhlfill)       [option get $w metajidhlfill       Roster]
    set config(metajidborder)       [option get $w metajidborder       Roster]
    set config(jidfill)             [option get $w jidfill             Roster]
    set config(jidhlfill)           [option get $w jidhlfill           Roster]
    set config(jidborder)           [option get $w jidborder           Roster]
    set config(jid2fill)            $config(jidfill)
    set config(jid2hlfill)          $config(jidhlfill)
    set config(jid2border)          $config(jidborder)
    set config(groupfill)           [option get $w groupfill           Roster]
    set config(groupcfill)          [option get $w groupcfill          Roster]
    set config(grouphlfill)         [option get $w grouphlfill         Roster]
    set config(groupborder)         [option get $w groupborder         Roster]
    set config(connectionfill)      [option get $w connectionfill      Roster]
    set config(connectioncfill)     [option get $w connectioncfill     Roster]
    set config(connectionhlfill)    [option get $w connectionhlfill    Roster]
    set config(connectionborder)    [option get $w connectionborder    Roster]
    set config(foreground)          [option get $w foreground          Roster]
    set config(dndforeground)       [option get $w dndforeground       Roster]
    set config(xaforeground)        [option get $w xaforeground        Roster]
    set config(awayforeground)      [option get $w awayforeground      Roster]
    set config(availableforeground) [option get $w availableforeground Roster]
    set config(chatforeground)      [option get $w chatforeground      Roster]
    set config(unsubscribedforeground) \
        [option get $w unsubscribedforeground Roster]
    set config(unavailableforeground) \
        [option get $w unavailableforeground Roster]
    set config(errorforeground)     [option get $w errorforeground     Roster]

    Canvas $c -bg $config(background) \
        -scrollregion {0 0 0 0} \
        -width $width -height $height
    if {$::interface eq "tk"} {
        $c configure -borderwidth 0.25m -relief sunken
    }

    $sw setwidget $c

    set iroster($w,ypos) 1
    set iroster($w,width) 0
    set iroster($w,popup) $popupproc
    set iroster($w,grouppopup) $grouppopupproc
    set iroster($w,singleclick) $singleclickproc
    set iroster($w,doubleclick) $doubleclickproc

    bindscroll $c

    if {[info exists draginitcmd]} {
        DragSite::register [Wrapped $c] -draginitcmd $draginitcmd
    }

    set args {}
    if {[info exists dropovercmd]} {
        lappend args -dropovercmd $dropovercmd
    }
    if {[info exists dropcmd]} {
        lappend args -dropcmd $dropcmd
    }
    if {[llength $args] > 0} {
        DropSite::register [Wrapped $c] -droptypes {JID} {*}$args
    }
}

proc roster::addline {w type text jid group metajids indent {jids {}}
                      {icon ""} {foreground ""}} {
    variable options
    variable roster
    variable iroster
    variable config

    set c $w.canvas

    set tag [jid_to_tag $jid]
    set grouptag [jid_to_tag $group]
    set metatag [jid_to_tag $metajids]

    set ypad 1
    set linespace [font metric $::RosterFont -linespace]
    set lineheight [expr {$linespace + $ypad}]

    set uy $iroster($w,ypos)
    set ly \
        [expr {$uy + $lineheight + $config(textuppad) + $config(textdownpad)}]

    set levindent [expr $config(groupindent)*$indent]

    if {$metajids eq {}} {
        set metaindent 0
    } else {
        set metaindent $config(groupindent)
    }

    set border $config(${type}border)
    set hlfill $config(${type}hlfill)

    if {$type in {group connection} && \
            [info exists roster(collapsed,$jid)] && $roster(collapsed,$jid)} {
        set rfill $config(${type}cfill)
    } else {
        set rfill $config(${type}fill)
    }

    if {$type eq "connection"} {
        set type group
    }

    $c create rectangle [expr {1 + $levindent}] $uy 10000 $ly \
              -fill $rfill \
              -outline $border \
              -tags [list jid$tag group$grouptag meta$metatag $type rect]

    switch -- $type {
        metajid {
            set isuser 1
            set y [expr {($uy + $ly)/2}]
            set x [expr {$config(iconindent) + $levindent}]

            if {$icon eq ""} {
                set icon roster/user/unavailable
            }
            $c create image $x $y -image $icon \
                                  -anchor w \
                                  -tags [list jid$tag group$grouptag \
                                              meta$metatag $type icon]

            if {[llength $jids] > 0} {
                if {[info exists roster(metacollapsed,$group,$metajids)] && \
                        !$roster(metacollapsed,$group,$metajids)} {
                    set jid_state opened
                } else {
                    set roster(metacollapsed,$group,$metajids) 1
                    set jid_state closed
                }
                if {$config(subitemtype) > 0 && ($config(subitemtype) & 2)} {
                    set y [expr {($uy + $ly)/2}]
                    set x [expr {$config(subgroupiconindent) + $levindent}]
                    $c create image $x $y -image roster/group/$jid_state \
                                          -anchor w \
                                          -tags [list jid$tag group$grouptag \
                                                      meta$metatag $type group]
                }
            } else {
                set roster(metacollapsed,$group,$metajids) 1
            }
        }
        jid {
            lassign $jid xlib jjid
            set isuser [::roster::itemconfig $xlib $jjid -isuser]
            if {$isuser eq ""} {
                set isuser 1
            }

            set y [expr {($uy + $ly)/2}]
            set x [expr {$config(iconindent) + $levindent + $metaindent}]

            if {$icon eq ""} {
                set icon roster/user/unavailable
            }
            $c create image $x $y -image $icon \
                                  -anchor w \
                                  -tags [list jid$tag group$grouptag \
                                              meta$metatag $type icon]

            if {[llength $jids] > 1} {
                if {[info exists roster(jidcollapsed,$group,$jid)] &&
                            !$roster(jidcollapsed,$group,$jid)} {
                    set jid_state opened
                } else {
                    set roster(jidcollapsed,$group,$jid) 1
                    set jid_state closed
                }
                if {$config(subitemtype) > 0 &&
                            ($config(subitemtype) & 2) && $isuser} {
                    set y [expr {($uy + $ly)/2}]
                    set x [expr {$config(subgroupiconindent) + $levindent +
                                 $metaindent}]
                    $c create image $x $y -image roster/group/$jid_state \
                                          -anchor w \
                                          -tags [list jid$tag group$grouptag \
                                                      meta$metatag $type group]
                }
            } else {
                set roster(jidcollapsed,$group,$jid) 1
            }
        }
        jid2 {
            set y [expr {($uy + $ly)/2}]
            set x [expr {$config(subiconindent) + $levindent + $metaindent}]

            if {$icon eq ""} {
                set icon roster/user/unavailable
            }
            $c create image $x $y -image $icon \
                                  -anchor w \
                                  -tags [list jid$tag group$grouptag \
                                              meta$metatag $type icon]
        }
        group {
            set y [expr {($uy + $ly)/2}]
            set x [expr {$config(groupiconindent) + $levindent}]
            if {[info exists roster(collapsed,$jid)] &&
                        $roster(collapsed,$jid)} {
                set group_state closed
            } else {
                set group_state opened
            }
            $c create image $x $y -image roster/group/$group_state \
                                  -anchor w \
                                  -tags [list jid$tag group$grouptag \
                                              meta$metatag $type icon]
        }
    }

    switch -- $type {
        metajid {
            if {($config(subitemtype) > 0) && ($config(subitemtype) & 2) &&
                    (($options(enable_metacontact_labels) &&
                        [llength $jids] > 0) ||
                    [llength $jids] > 1)} {
                set x [expr {$config(jidmultindent) + $levindent}]
            } else {
                set x [expr {$config(jidindent) + $levindent}]
            }
        }
        jid {
            if {($config(subitemtype) > 0) && ($config(subitemtype) & 2) && \
                    $isuser && ([llength $jids] > 1)} {
                set x [expr {$config(jidmultindent) + $levindent}]
            } else {
                set x [expr {$config(jidindent) + $levindent}]
            }
        }
        default {
            set x [expr {$config(${type}indent) + $levindent}]
        }
    }
    switch -- $type {
        jid -
        jid2 {
            incr x $metaindent
        }
    }

    incr uy $config(textuppad)

    if {$foreground eq ""} {
        switch -- $type {
            metajid -
            jid -
            jid2 {
                set foreground $config(unavailableforeground)
            }
            default {
                set foreground $config(foreground)
            }
        }
    }
    set tid [$c create text $x $uy -text $text \
                                   -anchor nw \
                                   -font $::RosterFont \
                                   -fill $foreground \
                                   -tags [list jid$tag group$grouptag \
                                               meta$metatag $type text]]

    set xmax [lindex [$c bbox $tid] 2]
    if {$xmax > $iroster($w,width)} {
        set iroster($w,width) $xmax
    }

    $c bind jid$tag&&$type <Any-Enter> \
            [double% [list $c itemconfig jid$tag&&$type&&rect -fill $hlfill]]
    $c bind jid$tag&&$type <Any-Leave> \
            [double% [list $c itemconfig jid$tag&&$type&&rect -fill $rfill]]

    set doubledjid  [double% $jid]
    set doubledjids [double% $jids]

    set iroster($w,ypos) [expr {$ly + $config(linepad)}]

    switch -- $type {
        metajid -
        jid -
        jid2 {
            $c bind jid$tag&&$type <Button-1> \
                    [list [namespace current]::on_singleclick \
                          [double% $iroster($w,singleclick)] \
                          [double% $c] %x %y $doubledjid $doubledjids]

            $c bind jid$tag&&$type <Double-Button-1> \
                    [list [namespace current]::on_doubleclick \
                          [double% $iroster($w,doubleclick)] $doubledjid \
                          $doubledjids]

            $c bind jid$tag&&$type <Any-Enter> \
                    +[list eval balloon::set_text \
                           \[[namespace current]::jids_popup_info \
                           [list $doubledjid] [list $doubledjids]\]]

            $c bind jid$tag&&$type <Any-Motion> \
                    [list eval balloon::on_mouse_move \
                          \[[namespace current]::jids_popup_info \
                          [list $doubledjid] [list $doubledjids]\] %X %Y]

            $c bind jid$tag&&$type <Any-Leave> {+ balloon::destroy}

            if {$iroster($w,popup) ne ""} {
                $c bind jid$tag&&$type <<ContextMenu>> \
                        [list [double% $iroster($w,popup)] \
                              $doubledjid $doubledjids]
            }
        }
        default {
            if {$w eq ".roster"} {
                $c bind jid$tag&&group <Button-1> \
                        [list [namespace current]::group_click $doubledjid]
            }

            if {$iroster($w,grouppopup) ne ""} {
                $c bind jid$tag&&group <<ContextMenu>> \
                        [list [double% $iroster($w,grouppopup)] $doubledjid]
            }
        }
    }
}

proc roster::clear {w {updatescroll 1}} {
    variable iroster

    $w.canvas delete rect||icon||text||group

    set iroster($w,ypos) 1
    set iroster($w,width) 0
    if {$updatescroll} {
        update_scrollregion $w
    }
}

proc roster::update_scrollregion {w} {
    variable iroster

    $w.canvas configure \
        -scrollregion [list 0 0 $iroster($w,width) $iroster($w,ypos)]
}

###############################################################################

proc roster::on_singleclick {command c x y cjid jids} {
    variable click_afterid

    if {$command eq ""} return

    set xc [$c canvasx $x]
    set yc [$c canvasy $y]
    set tags [$c gettags [lindex [$c find closest $xc $yc] 0]]

    if {![info exists click_afterid]} {
        set click_afterid \
            [after 300 [list [namespace current]::singleclick_run $command \
                             $tags $cjid $jids]]
    } else {
        after cancel $click_afterid
        unset click_afterid
    }
}

proc roster::singleclick_run {command tags cjid jids} {
    variable click_afterid

    if {[info exists click_afterid]} {
        unset click_afterid
    }

    {*}$command $tags $cjid $jids
}

proc roster::on_doubleclick {command cjid jids} {
    variable click_afterid

    if {[info exists click_afterid]} {
        after cancel $click_afterid
        unset click_afterid
    }

    if {$command eq ""} return

    {*}$command $cjid $jids
}

###############################################################################

proc roster::jid_doubleclick {id ids} {
    lassign $id xlib jid
    lassign [::roster::get_category_and_subtype $xlib $jid] category subtype

    hook::run roster_jid_doubleclick $xlib $jid $category $subtype
}

###############################################################################

proc roster::doubleclick_fallback {xlib jid category subtype} {
    variable options

    if {$options(chat_on_doubleclick)} {
        chat::open_to_user $xlib $jid
    } else {
        message::send_dialog -to $jid
    }
}

hook::add roster_jid_doubleclick \
    [namespace current]::roster::doubleclick_fallback 100

###############################################################################

proc roster::group_click {gid} {
    variable roster

    set roster(collapsed,$gid) [expr {!$roster(collapsed,$gid)}]
    redraw_after_idle
}

proc roster::jids_popup_info {id jids} {
    lassign $id xlib jid

    # TODO: metacontacts
    if {$jids eq {}} {
        set jids [list $jid]
    }

    set text {}
    set i 0
    foreach j [lsort $jids] {
        set popup_info [user_popup_info $xlib $j $i]
        if {$popup_info ne ""} {
            append text "\n[user_popup_info $xlib $j $i]"
        }
        incr i
    }
    set text [string trimleft $text "\n"]
    return $text
}

proc roster::user_popup_info {xlib user i} {
    variable options
    variable user_popup_info
    global statusdesc

    lassign [::roster::get_category_and_subtype $xlib $user] category subtype
    set bare_user [::roster::find_jid $xlib $user]
    lassign [::roster::get_category_and_subtype $xlib $bare_user] category1 subtype1

    set name $user
    switch -- $category {
        conference {
            set status $statusdesc([get_jid_status $xlib $user])
            set desc ""
        }
        user -
        default {
            set status $statusdesc([get_user_status $xlib $user])
            set desc   [get_user_status_desc $xlib $user]
            if {$category1 eq "conference" && $i > 0} {
                if {$options(show_conference_user_info)} {
                    set name "     [::xmpp::jid::resource $user]"
                } else {
                    set name "\t[::xmpp::jid::resource $user]"
                }
            }
        }
    }

    if {![string equal -nocase $status $desc] && $desc ne ""} {
        append status " ($desc)"
    }

    set subsc [::roster::itemconfig $xlib $bare_user -subsc]
    if {($options(show_subscription) && $subsc ne "") &&
            !($category1 eq "conference" && $category eq "user")} {
        set subsc "\n\t[::msgcat::mc {Subscription:}] $subsc"
        set ask [::roster::itemconfig $xlib $bare_user -ask]
        if {$ask ne ""} {
            set ask "  [::msgcat::mc {Ask:}] $ask"
        }
    } else {
        set subsc ""
        set ask ""
    }

    set user_popup_info ""

    if {$category1 ne "conference" || $i == 0 || $options(show_conference_user_info)} {
        set user_popup_info "$name: $status$subsc$ask"

        hook::run roster_user_popup_info_hook \
            [namespace which -variable user_popup_info] $xlib $user
    } elseif {$category1 eq "conference" && $i > 0} {
        set user_popup_info $name
    }

    return $user_popup_info
}

proc roster::switch_only_online {args} {
    variable show_only_online

    set show_only_online [expr {!$show_only_online}]
}

proc roster::is_online {xlib jid} {
    if {[::roster::itemconfig $xlib $jid -isuser]} {
        switch -- [get_user_status $xlib $jid] {
            unavailable {return 0}
            default {return 1}
        }
    } else {
        return 1
    }
}

###############################################################################

proc roster::add_remove_item_menu_item {m xlib jid} {
    set rjid [roster::find_jid $xlib $jid]
    if {$jid ne "" && $rjid eq ""} {
        set state disabled
    } else {
        set state normal
    }
    $m add command -label [::msgcat::mc "Remove from roster..."] \
        -command [list ifacetk::roster::remove_item_dialog $xlib $rjid] \
        -state $state
}

hook::add chat_create_user_menu_hook \
    [namespace current]::roster::add_remove_item_menu_item 90
hook::add roster_conference_popup_menu_hook \
    [namespace current]::roster::add_remove_item_menu_item 90
hook::add roster_service_popup_menu_hook \
    [namespace current]::roster::add_remove_item_menu_item 90
hook::add roster_jid_popup_menu_hook \
    [namespace current]::roster::add_remove_item_menu_item 90

###############################################################################

proc roster::remove_item_dialog {xlib jid} {
    set res [MessageDlg .remove_item -aspect 50000 -icon question -type user \
        -buttons {yes no} -default 0 -cancel 1 \
        -message [::msgcat::mc "Are you sure to remove %s from roster?" $jid]]
    if {$res == 0} {
        ::roster::remove_item $xlib $jid
    }
}

proc roster::update_chat_activity {args} {
    variable options

    if {$options(chats_group)} {
        redraw_after_idle
    }
}

hook::add open_chat_post_hook [namespace current]::roster::redraw_after_idle
hook::add close_chat_post_hook [namespace current]::roster::redraw_after_idle
hook::add draw_message_hook [namespace current]::roster::update_chat_activity
hook::add raise_chat_tab_hook [namespace current]::roster::update_chat_activity


###############################################################################

proc roster::dropcmd {target source X Y op type data} {
    variable options

    debugmsg roster "$target $source $X $Y $op $type $data"

    set c .roster.canvas

    set x [expr {$X-[winfo rootx $c]}]
    set y [expr {$Y-[winfo rooty $c]}]
    set xc [$c canvasx $x]
    set yc [$c canvasy $y]

    set tags [$c gettags [lindex [$c find closest $xc $yc] 0]]

    if {$options(free_drop) && $tags ne ""} {
        lassign [tag_to_jid [string range [lindex $tags 1] 5 end]] xlib gr
        if {$xlib eq "xlib"} {
            set xlib $gr
            set gr {}
        }
    } elseif {"group" in $tags} {
        lassign [tag_to_jid [string range [lindex $tags 0] 3 end]] xlib gr
        if {$xlib eq "xlib"} {
            set xlib $gr
            set gr {}
        }
    } elseif {$tags ne ""} {
        lassign [tag_to_jid [string range [lindex $tags 1] 5 end]] xlib
        set gr {}
    } else {
        set xlib [lindex [connections] 0]
        set gr {}
    }
    if {$options(nested)} {
        set gr [join $gr $options(nested_delimiter)]
    } else {
        set gr [lindex $gr 0]
    }

    debugmsg roster "GG: $gr; $tags"

    lassign $data _xlib jid category type name version fromgid
    set subsc ""

    if {[info exists fromgid]} {
        lassign $fromgid fromxlib fromgr
        if {$options(nested)} {
            set fromgr [join $fromgr $options(nested_delimiter)]
        } else {
            set fromgr [lindex $fromgr 0]
        }
    }

    if {$jid ni [::roster::get_jids $xlib]} {
        if {$gr ne {}} {
            set groups [list $gr]
        } else {
            set groups {}
        }
        ::roster::itemconfig $xlib $jid -category $category -subtype $type \
            -name $name -group $groups

        lassign [::roster::get_category_and_subtype $xlib $jid] ccategory ctype
        switch -- $ccategory {
            conference {
                ::roster::itemconfig $xlib $jid -subsc bookmark
            }
            user {
                ::xmpp::sendPresence $xlib -to $jid -type subscribe
            }
        }
    } else {
        set groups [::roster::itemconfig $xlib $jid -group]

        if {[info exists fromgid] && ($fromxlib eq $xlib)} {
            set idx [lsearch -exact $groups $fromgr]
            if {$idx >= 0} {
                set groups [lreplace $groups $idx $idx]
            }
        }
        if {$gr ne ""} {
            lappend groups $gr
            set groups [lsort -unique $groups]
            debugmsg roster $groups
        }

        ::roster::itemconfig $xlib $jid -category $category -subtype $type \
            -name $name -group $groups
    }

    ::roster::send_item $xlib $jid
}

proc roster::draginitcmd {target x y top} {
    debugmsg roster "$target $x $y $top"

    balloon::destroy
    set c .roster.canvas

    set tags [$c gettags current]
    if {"jid" in $tags} {
        set grouptag [string range [lindex $tags 1] 5 end]
        set gid [tag_to_jid $grouptag]
        set tag [string range [lindex $tags 0] 3 end]
        set cjid [tag_to_jid $tag]
        lassign $cjid xlib jid

        set data [list $xlib $jid \
                      [::roster::itemconfig $xlib $jid -category] \
                      [::roster::itemconfig $xlib $jid -subtype] \
                      [::roster::itemconfig $xlib $jid -name] {} \
                      $gid]

        debugmsg roster $data
        return [list JID {move} $data]
    } else {
        return {}
    }
}

###############################################################################

proc roster::user_singleclick {tags cjid jids} {
    variable options
    variable roster

    lassign $cjid xlib jid
    set type [lindex $tags 3]
    set cgroup [tag_to_jid [string range [lindex $tags 1] 5 end]]
    set cmeta [tag_to_jid [string range [lindex $tags 2] 4 end]]

    switch -- $type {
        metajid {
            if {[llength $jids] > 1 ||
                    ($options(enable_metacontact_labels) &&
                     [llength $jids] > 0)} {
                set roster(metacollapsed,$cgroup,$cmeta) \
                    [expr {!$roster(metacollapsed,$cgroup,$cmeta)}]
                redraw_after_idle
            }
        }
        default {
            if {[roster::itemconfig $xlib $jid -isuser] &&
                    [llength $jids] > 1} {
                set roster(jidcollapsed,$cgroup,$cjid) \
                    [expr {!$roster(jidcollapsed,$cgroup,$cjid)}]
                redraw_after_idle
            }
        }
    }
}

###############################################################################

proc roster::popup_menu {id jids} {
    lassign $id xlib jid

    lassign [::roster::get_category_and_subtype $xlib $jid] category subtype

    switch -- $category {
        user       {set menu [create_user_menu $xlib $jid $jids]}
        conference {set menu [conference_popup_menu $xlib $jid]}
        server  -
        gateway -
        service    {set menu [service_popup_menu $xlib $jid]}
        default    {set menu [jid_popup_menu $xlib $jid]}
    }

    tk_popup $menu [winfo pointerx .] [winfo pointery .]
}

###############################################################################

proc roster::group_popup_menu {id} {
    variable options

    lassign $id xlib name
    if {$options(nested)} {
        set name [join $name $options(nested_delimiter)]
    } else {
        set name [lindex $name 0]
    }
    if {$xlib ne "xlib"} {
        tk_popup [create_group_popup_menu $xlib $name] \
            [winfo pointerx .] [winfo pointery .]
    }
}

###############################################################################

proc roster::groupchat_popup_menu {id jids} {
    lassign $id xlib jid
    tk_popup [create_groupchat_user_menu $xlib $jid] \
        [winfo pointerx .] [winfo pointery .]
}

###############################################################################

proc roster::create_user_menu {xlib user jids} {
    set m .jidpopupmenu
    if {[winfo exists $m]} { destroy $m }
    menu $m -tearoff 0

    set jids1 {}
    foreach jid $jids {
        set resources [get_jids_of_user $xlib $jid]
        if {[llength $resources] == 0} {
            lappend jids1 $jid
        } else {
            set jids1 [concat $jids1 [get_jids_of_user $xlib $jid]]
        }
    }
    set jids $jids1

    switch -- [llength $jids] {
        0 {
            hook::run roster_jid_popup_menu_hook $m $xlib $user
            return $m
        }
        1 {
            hook::run roster_jid_popup_menu_hook $m $xlib [lindex $jids 0]
            return $m
        }
        default {
            foreach jid $jids {
                set m1 .jidpopupmenu[jid_to_tag $jid]
                if {[winfo exists $m1]} { destroy $m1 }
                menu $m1 -tearoff 0
                hook::run roster_jid_popup_menu_hook $m1 $xlib $jid
            }

            add_menu_submenu $m .jidpopupmenu "" $jids

            foreach jid $jids {
                set m1 .jidpopupmenu[jid_to_tag $jid]
                if {[winfo exists $m1]} { destroy $m1 }
            }

            return $m
        }
    }
}

###############################################################################

proc roster::add_menu_submenu {m prefix suffix jids} {
    set m1 $prefix[jid_to_tag [lindex $jids 0]]$suffix

    for {set i 0} {[$m1 index $i] == $i} {incr i} {
        switch -- [$m1 type $i] {
            separator {
                $m add separator
            }
            cascade {
                set label [$m1 entrycget $i -label]
                set menu [$m1 entrycget $i -menu]
                set state [$m1 entrycget $i -state]
                set suffix2 [join [lrange [split $menu .] 2 end] .]
                set suffix3 [lindex [split $menu .] end]
                set m2 [menu $m.$suffix3 -tearoff 0]
                # TODO: Check if state is the same for all menus
                $m add cascade -label $label -menu $m2 -state $state
                add_menu_submenu $m2 $prefix .$suffix2 $jids
            }
            checkbutton {
                set label [$m1 entrycget $i -label]
                add_checkbutton_submenu $m $prefix $suffix $i $label $jids
            }
            radiobutton {
                set label [$m1 entrycget $i -label]
                add_radiobutton_submenu $m $prefix $suffix $i $label $jids
            }
            command {
                set label [$m1 entrycget $i -label]
                add_command_submenu $m $prefix $suffix $i $label $jids
            }
        }
    }
}

###############################################################################

proc roster::get_popup_command_list {m prefix suffix label jids args} {
    set command_list0 {}
    set command_list1 {}
    set command_list2 {}
    foreach jid $jids {
        set bjid [::xmpp::jid::removeResource $jid]
        set m1 $prefix[jid_to_tag $jid]$suffix
        if {![catch {$m1 index $label} idx] && $idx ne "none"} {
            set command {}
            foreach opt $args {
                # In some commands menu path is used, which is destroyed after
                # the submenus are created
                lappend command [string map [list $m1 $m] \
                                            [$m1 entrycget $idx $opt]]
            }
            lappend command_list0 [list $label $command]
            lappend command_list1 [list $jid $command]
            lappend command_list2 [list $bjid $command]
        }
    }

    set command_list0 [lsort -unique $command_list0]
    set command_list2 [lsort -unique $command_list2]
    set command_list3 [lsort -unique -index 0 $command_list2]

    if {[llength $command_list0] == 1} {
        return $command_list0
    } elseif {[llength $command_list2] != [llength $command_list3]} {
        return $command_list1
    } else {
        return $command_list2
    }
}

proc roster::add_command_submenu {m prefix suffix i label jids} {
    set command_list [get_popup_command_list $m $prefix $suffix $label $jids \
                                             -command -state]
    if {[llength $command_list] > 1} {
        set m2 [menu $m.$i -tearoff 0]
        $m add cascade -label $label -menu $m2

        foreach jid_command $command_list {
            lassign $jid_command jid command
            $m2 add command -label $jid \
                            -command [lindex $command 0] \
                            -state [lindex $command 1]
        }
    } else {
        lassign [lindex [lindex $command_list 0] 1] command state
        $m add command -label $label \
                       -command $command \
                       -state $state
    }
}

proc roster::add_checkbutton_submenu {m prefix suffix i label jids} {
    set command_list [get_popup_command_list $m $prefix $suffix $label $jids \
                                             -variable -command -state]

    if {[llength $command_list] > 1} {
        set m2 [menu $m.$i -tearoff 0]
        $m add cascade -label $label -menu $m2

        foreach jid_command $command_list {
            lassign $jid_command jid command
            $m2 add checkbutton -label $jid \
                                -variable [lindex $command 0] \
                                -command [lindex $command 1] \
                                -state [lindex $command 2]
        }
    } else {
        lassign [lindex [lindex $command_list 0] 1] var command state
        $m add checkbutton -label $label \
                           -variable $var \
                           -command $command \
                           -state $state
    }
}

proc roster::add_radiobutton_submenu {m prefix suffix i label jids} {
    set command_list [get_popup_command_list $m $prefix $suffix $label $jids \
                                             -value -variable -command -state]

    if {[llength $command_list] > 1} {
        set m2 [menu $m.$i -tearoff 0]
        $m add cascade -label $label -menu $m2

        foreach jid_command $command_list {
            lassign $jid_command jid command
            $m2 add radiobutton -label $jid \
                                -value [lindex $command 0] \
                                -variable [lindex $command 1] \
                                -command [lindex $command 2] \
                                -state [lindex $command 3]
        }
    } else {
        lassign [lindex [lindex $command_list 0] 1] value var command state
        $m add radiobutton -label $label \
                           -value $value \
                           -variable $var \
                           -command $command \
                           -state $state
    }
}

###############################################################################

proc roster::add_separator {m xlib jid} {
    $m add separator
}

###############################################################################

proc roster::jid_popup_menu {xlib jid} {
    if {[winfo exists [set m .jidpopupmenu]]} {
        destroy $m
    }
    menu $m -tearoff 0

    hook::run roster_jid_popup_menu_hook $m $xlib $jid

    return $m
}

hook::add roster_jid_popup_menu_hook \
    [namespace current]::roster::add_separator 40
hook::add roster_jid_popup_menu_hook \
    [namespace current]::roster::add_separator 50
hook::add roster_jid_popup_menu_hook \
    [namespace current]::roster::add_separator 70
hook::add roster_jid_popup_menu_hook \
    [namespace current]::roster::add_separator 85

###############################################################################

proc roster::conference_popup_menu {xlib jid} {
    if {[winfo exists [set m .confpopupmenu]]} {
        destroy $m
    }
    menu $m -tearoff 0

    hook::run roster_conference_popup_menu_hook $m $xlib $jid

    return $m
}

hook::add roster_conference_popup_menu_hook \
    [namespace current]::roster::add_separator 50
hook::add roster_conference_popup_menu_hook \
    [namespace current]::roster::add_separator 70
hook::add roster_conference_popup_menu_hook \
    [namespace current]::roster::add_separator 85

###############################################################################

proc roster::service_popup_menu {xlib jid} {
    if {[winfo exists [set m .servicepopupmenu]]} {
        destroy $m
    }
    menu $m -tearoff 0

    hook::run roster_service_popup_menu_hook $m $xlib $jid

    return $m
}

hook::add roster_service_popup_menu_hook \
    [namespace current]::roster::add_separator 50
hook::add roster_service_popup_menu_hook \
    [namespace current]::roster::add_separator 70
hook::add roster_service_popup_menu_hook \
    [namespace current]::roster::add_separator 85

###############################################################################

proc roster::create_groupchat_user_menu {xlib jid} {
    if {[winfo exists [set m .groupchatpopupmenu]]} {
        destroy $m
    }
    menu $m -tearoff 0

    hook::run roster_create_groupchat_user_menu_hook $m $xlib $jid

    return $m
}

hook::add roster_create_groupchat_user_menu_hook \
    [namespace current]::roster::add_separator 40
hook::add roster_create_groupchat_user_menu_hook \
    [namespace current]::roster::add_separator 50

###############################################################################

proc roster::create_group_popup_menu {xlib name} {
    variable options
    variable chats_group_name

    if {$name eq $chats_group_name} {
        set state disabled
    } else {
        set state normal
    }

    if {[winfo exists [set m .grouppopupmenu]]} {
        destroy $m
    }
    if {$options(nested)} {
        set oname [msplit $name $options(nested_delimiter)]
    } else {
        set oname $name
    }
    menu $m -tearoff 0
    $m add command \
        -label [::msgcat::mc "Send message to all users in group..."] \
        -command [list ::message::send_dialog \
                       -to $name -group 1 -connection $xlib]
    $m add command \
        -label [::msgcat::mc "Resubscribe to all users in group..."] \
        -command [list ::roster::resubscribe_group $xlib $name]

    add_group_custom_presence_menu $m $xlib $name

    $m add checkbutton -label [::msgcat::mc "Show offline users"] \
        -variable \
            [namespace current]::roster(show_offline,[list $xlib $oname]) \
        -command [list [namespace current]::redraw_after_idle]
    $m add command -label [::msgcat::mc "Rename group..."] \
        -command [list [namespace current]::rename_group_dialog $xlib $name] \
        -state $state
    $m add command -label [::msgcat::mc "Remove group..."] \
        -command [list [namespace current]::remove_group_dialog $xlib $name] \
        -state $state
    $m add command -label [::msgcat::mc "Remove all users in group..."] \
        -command [list [namespace current]::remove_users_group_dialog \
                       $xlib $name]

    set last [$m index end]

    ::hook::run roster_group_popup_menu_hook $m $xlib $name

    if {[$m index end] > $last} {
        $m insert [expr $last + 1] separator
    }

    return $m
}

###############################################################################

proc roster::remove_group_dialog {xlib name} {
    set res [MessageDlg .remove_item -aspect 50000 -icon question -type user \
                 -buttons {yes no} -default 0 -cancel 1 \
                 -message [::msgcat::mc "Are you sure to remove group '%s'\
                                         from roster? \n(Users which are in\
                                         this group only, will be in undefined\
                                         group.)" $name]]

    if {$res == 0} {
        roster::send_rename_group $xlib $name ""
    }
}

proc roster::remove_users_group_dialog {xlib name} {
    set res [MessageDlg .remove_item -aspect 50000 -icon question -type user \
                 -buttons {yes no} -default 0 -cancel 1 \
                 -message [::msgcat::mc "Are you sure to remove all users in\
                                         group '%s' from roster? \n(Users\
                                         which are not in this group only,\
                                         will be removed from the roster as\
                                         well.)" $name]]

    if {$res == 0} {
        roster::send_remove_users_group $xlib $name
    }
}

proc roster::rename_group_dialog {xlib name} {
    global new_roster_group_name

    set new_roster_group_name $name

    set w .roster_group_rename
    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -title [::msgcat::mc "Rename roster group"] \
              -anchor e \
              -default 0 \
              -cancel 1

    $w add -text [::msgcat::mc "OK"] -command \
        [list [namespace current]::confirm_rename_group $w $xlib $name]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set p [$w getframe]

    Label $p.lgroupname -text [::msgcat::mc "New group name:"]
    Entry $p.groupname -textvariable new_roster_group_name

    grid $p.lgroupname  -row 0 -column 0 -sticky e
    grid $p.groupname   -row 0 -column 1 -sticky ew

    focus $p.groupname
    $w draw
}

proc roster::confirm_rename_group {w xlib name} {
    global new_roster_group_name
    variable roster

    destroy $w

    ::roster::send_rename_group $xlib $name $new_roster_group_name

    set gid [list $xlib $name]
    set newgid [list $xlib $new_roster_group_name]

    if {[info exists roster(collapsed,$gid)]} {
        set roster(collapsed,$newgid) $roster(collapsed,$gid)
        unset roster(collapsed,$gid)
    }
    if {[info exists roster(show_offline,$gid)]} {
        set roster(show_offline,$newgid) $roster(show_offline,$gid)
        unset roster(show_offline,$gid)
    }
}

proc roster::add_group_by_jid_regexp_dialog {} {
    global new_roster_group_rname
    global new_roster_group_regexp

    set w .roster_group_add_by_jid_regexp
    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -title [::msgcat::mc "Add roster group by JID regexp"] \
              -anchor e -default 0 -cancel 1

    $w add -text [::msgcat::mc "OK"] -command "
        destroy [list $w]
        roster::add_group_by_jid_regexp \
            \$new_roster_group_rname \$new_roster_group_regexp
    "
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set p [$w getframe]

    Label $p.lgroupname -text [::msgcat::mc "New group name:"]
    Entry $p.groupname -textvariable new_roster_group_rname
    Label $p.lregexp -text [::msgcat::mc "JID regexp:"]
    Entry $p.regexp -textvariable new_roster_group_regexp

    grid $p.lgroupname -row 0 -column 0 -sticky e
    grid $p.groupname  -row 0 -column 1 -sticky ew
    grid $p.lregexp    -row 1 -column 0 -sticky e
    grid $p.regexp     -row 1 -column 1 -sticky ew

    focus $p.groupname
    $w draw
}

###############################################################################

proc roster::add_group_custom_presence_menu {m xlib name} {
    set mm [menu $m.custom_presence -tearoff 0]

    $mm add command -label [::msgcat::mc "Available"] \
        -command [list roster::send_custom_presence_group $xlib $name \
                                                                 available]
    $mm add command -label [::msgcat::mc "Free to chat"] \
        -command [list roster::send_custom_presence_group $xlib $name chat]
    $mm add command -label [::msgcat::mc "Away"] \
        -command [list roster::send_custom_presence_group $xlib $name away]
    $mm add command -label [::msgcat::mc "Extended away"] \
        -command [list roster::send_custom_presence_group $xlib $name xa]
    $mm add command -label [::msgcat::mc "Do not disturb"] \
        -command [list roster::send_custom_presence_group $xlib $name dnd]
    $mm add command -label [::msgcat::mc "Unavailable"] \
        -command [list roster::send_custom_presence_group $xlib $name \
                                                              unavailable]

    $m add cascade -label [::msgcat::mc "Send custom presence"] -menu $mm
}

###############################################################################

# vim:ft=tcl:ts=8:sw=4:sts=4:et
