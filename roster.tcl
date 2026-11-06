# roster.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements routines
#       working with rosters.

package require xmpp::roster 0.2
package require xmpp::register

namespace eval roster {
    variable undef_group_name [::msgcat::mc "Undefined"]
    variable chats_group_name [::msgcat::mc "Active Chats"]
    variable own_resources_group_name [::msgcat::mc "My Resources"]

    custom::defgroup Roster [::msgcat::mc "Roster options."] -group Tkabber

    custom::defvar cache_roster_offline 0 \
        [::msgcat::mc "Cache roster items offline and use roster versioning\
                       if supported by a server."] \
        -type boolean -group Roster \

    custom::defvar offline_roster_cache {} "Offline cache for XEP-0237" \
        -group Hidden
}

proc roster::process_item {xlib jid name groups subsc ask} {
    variable roster
    variable undef_group_name
    variable chats_group_name
    variable own_resources_group_name

    debugmsg roster "ROSTER_ITEM: $xlib; $jid; $name; $groups; $subsc; $ask"

    set jid [::xmpp::jid::normalize $jid]

    if {$subsc ne "remove"} {
        if {$jid ni $roster(jids,$xlib)} {
            lappend roster(jids,$xlib) $jid
        }
        set groups [lsort -unique $groups]
        foreach group [list "" $undef_group_name $chats_group_name \
                            $own_resources_group_name] {
            set ind [lsearch -exact $groups $group]
            if {$ind >= 0} {
                set groups [lreplace $groups $ind $ind]
            }
        }
        set roster(group,$xlib,$jid)    $groups
        set roster(name,$xlib,$jid)     $name
        set roster(subsc,$xlib,$jid)    $subsc
        set roster(ask,$xlib,$jid)      $ask

        catch {unset roster(cached_category_and_subtype,$xlib,$jid)}
        get_category_and_subtype $xlib $jid
    } else {
        set idx [lsearch -exact $roster(jids,$xlib) $jid]
        set roster(jids,$xlib) [lreplace $roster(jids,$xlib) $idx $idx]

        catch {unset roster(group,$xlib,$jid)}
        catch {unset roster(name,$xlib,$jid)}
        catch {unset roster(subsc,$xlib,$jid)}
        catch {unset roster(ask,$xlib,$jid)}
        catch {unset roster(cached_category_and_subtype,$xlib,$jid)}
    }
}

hook::add roster_push_hook [namespace current]::roster::process_item

proc client:roster_push {xlib njid args} {
    set jid $njid
    set name ""
    set subsc none
    set ask ""
    set groups {}
    foreach {key val} $args {
        switch -- $key {
            -jid {set jid $val}
            -name {set name $val}
            -subscription {set subsc $val}
            -ask {set ask $val}
            -groups {set groups $val}
        }
    }

    hook::run roster_push_hook $xlib $jid $name $groups $subsc $ask
    ::redraw_roster
}

proc client:roster_cmd {xlib status xml} {
    debugmsg roster "ROSTER_CMD: $status"

    if {[string equal $status ok]} {
        hook::run roster_end_hook $xlib
        ::redraw_roster
    }
}

proc roster::request_roster {xlib} {
    variable cache_roster_offline
    variable offline_roster_cache
    variable roster

    set args {}
    if {$cache_roster_offline} {
        debugmsg roster "We use the roster cache now..."

        array set tmp $offline_roster_cache
        set bjid [::xmpp::jid::normalize [connection_bare_jid $xlib]]
        if {[info exists tmp($bjid)]} {
            lassign $tmp($bjid) version cache
            set args [list -version $version -cache $cache]
        }
    }

    set roster(jids,$xlib) {}
    set roster(token,$xlib) \
        [::xmpp::roster::new $xlib \
                    -itemcommand [list client:roster_push $xlib] {*}$args]
    ::xmpp::roster::get $roster(token,$xlib) \
            -command [list client:roster_cmd $xlib]
}

hook::add connected_hook [namespace current]::roster::request_roster 10

proc roster::clean {xlib} {
    variable cache_roster_offline
    variable offline_roster_cache
    variable roster

    if {[info exists roster(token,$xlib)]} {
        lassign [::xmpp::roster::free $roster(token,$xlib)] version cache

        if {$cache_roster_offline} {
            debugmsg roster "We caching the roster now..."

            array set tmp $offline_roster_cache
            set bjid [::xmpp::jid::normalize [connection_bare_jid $xlib]]
            set tmp($bjid) [list $version $cache]
            set offline_roster_cache [array get tmp]
        }
    }

    array unset roster token,$xlib
    array unset roster jids,$xlib
    array unset roster group,$xlib,*
    array unset roster name,$xlib,*
    array unset roster subsc,$xlib,*
    array unset roster ask,$xlib,*
    array unset roster subtype,$xlib,*
    array unset roster cached_category_and_subtype,$xlib,*
    array unset roster overridden_category_and_subtype,$xlib,*

    ::redraw_roster
}

hook::add disconnected_hook [namespace current]::roster::clean

proc roster::get_group_jids {xlib group args} {
    variable roster
    variable undef_group_name

    if {![info exists roster(jids,$xlib)]} {
        return {}
    }

    set nested 0
    set delim "::"
    foreach {opt val} $args {
        switch -- $opt {
            -nested { set nested $val }
            -delimiter { set delim $val }
        }
    }

    set jids {}
    if {$group eq $undef_group_name} {
        foreach jid $roster(jids,$xlib) {
            if {[llength [::roster::itemconfig $xlib $jid -group]] == 0} {
                lappend jids $jid
            }
        }
    } else {
        foreach jid $roster(jids,$xlib) {
            foreach jgroup [::roster::itemconfig $xlib $jid -group] {
                if {($nested &&
                        [string first "$group$delim" "$jgroup$delim"] == 0) ||
                        $group eq $jgroup} {
                    lappend jids $jid
                    break
                }
            }
        }
    }
    return $jids
}

proc roster::get_jids {xlib} {
    variable roster

    if {[info exists roster(jids,$xlib)]} {
        return [lsort -dictionary $roster(jids,$xlib)]
    } else {
        return {}
    }
}

proc roster::get_groups {xlib args} {
    variable roster
    variable undef_group_name

    if {![info exists roster(jids,$xlib)]} {
        return {}
    }

    set nested 0
    set delimiter "::"
    set undefined 0
    set groups {}

    foreach {opt val} $args {
        switch -- $opt {
            -nested { set nested $val }
            -delimiter { set delimiter $val }
            -raw {
                if {$val} {
                    foreach jid $roster(jids,$xlib) {
                        set groups [concat $groups $roster(group,$xlib,$jid)]
                    }
                    return [lsort -unique $groups]
                }
            }
            -undefined { set undefined $val }
        }
    }

    set empty 0
    foreach jid $roster(jids,$xlib) {
        set jid_groups [::roster::itemconfig $xlib $jid -group]
        if {[llength $jid_groups] > 0} {
            foreach group $jid_groups {
                if {$nested} {
                    set sgroup [msplit $group $delimiter]
                } else {
                    set sgroup [list $group]
                }
                set deep [llength $sgroup]
                for {set i 0} {$i < $deep} {incr i} {
                        set sgr [lrange $sgroup 0 $i]
                        lappend groups [join $sgr "\u0000"]
                }
            }
        } else {
            set empty 1
        }
    }
    set res {}
    foreach sgroup [lsort -unique -dictionary $groups] {
        lappend res [join [split $sgroup "\u0000"] $delimiter]
    }
    if {$empty && $undefined} {
        lappend res $undef_group_name
    }

    return $res
}

proc roster::itemconfig {xlib jid args} {
    variable roster

    if {[llength $args] == 1} {
        lassign $args attr
        switch -- $attr {
            -group    {set param group}
            -name     {set param name}
            -subsc    {set param subsc}
            -ask      {set param ask}
            -category {
                return [lindex [get_category_and_subtype $xlib $jid] 0]
            }
            -subtype  {
                return [lindex [get_category_and_subtype $xlib $jid] 1]
            }
            -isuser   {
                return [string equal \
                            [lindex [get_category_and_subtype $xlib $jid] 0] \
                            user]
            }
            default   {
                return -code error "Bad option \"$attr\":\
                    must be one of: -group, -name, -subsc, -ask,\
                    -category, -subtype or -isuser"
            }
        }
        if {[info exists roster($param,$xlib,$jid)]} {
            return $roster($param,$xlib,$jid)
        } else {
            return ""
        }
    } else {
        foreach {attr val} $args {
            switch -- $attr {
                -group    {set param group}
                -name     {set param name}
                -subsc    {set param subsc}
                -ask      {set param ask}
                -category {
                    override_category $xlib $jid $val
                    continue
                }
                -subtype  {
                    override_subtype $xlib $jid $val
                    continue
                }
                default   {return -code error "Illegal option"}
            }
            set roster($param,$xlib,$jid) $val
        }
    }
}

# Returns true if $jid is allowed to receive our presence information,
# false otherwise.
proc roster::is_trusted {xlib jid} {
    set rjid [find_jid $xlib $jid]
    if {$rjid eq ""} {
        return 0
    }
    set subsc [itemconfig $xlib $rjid -subsc]

    if {[::xmpp::jid::equal [::xmpp::jid::removeResource $jid] [connection_bare_jid $xlib]]} {
        return 1
    } elseif {$subsc eq "both" || $subsc eq "from"} {
        return 1
    } else {
        return 0
    }
}

proc roster::on_change_jid_presence {xlib jid type x args} {
    variable roster

    switch -- $type {
        error -
        unavailable -
        available {}
        default { return }
    }

    set rjid [find_jid $xlib $jid]
    debugmsg roster "$jid $rjid"

    if {$rjid ne ""} {
        lassign [get_category_and_subtype $xlib $rjid] category subtype

        if {$category eq "user"} {
            set status [get_user_status $xlib $rjid]
            set label [get_label $xlib $rjid]
            if {![catch {set desc [::get_long_status_desc $status]}]} {
                set_status [format "%s $desc" $label]
            }
            hook::run on_change_user_presence_hook $label $status
        }
    }
    ::redraw_roster
}

hook::add client_presence_hook roster::on_change_jid_presence 60

proc roster::find_jid {xlib jid} {
    variable roster

    if {![info exists roster(jids,$xlib)]} {
        return ""
    }

    if {$jid in $roster(jids,$xlib)} {
        return $jid
    }

    lassign [get_category_and_subtype $xlib $jid] category subtype
    if {$category eq "user"} {
        set rjid [::xmpp::jid::removeResource $jid]
        if {$rjid in $roster(jids,$xlib)} {
            lassign [get_category_and_subtype $xlib $rjid] rcategory rsubtype
            switch -- $rcategory {
                user -
                conference {
                    return $rjid
                }
                default {
                    return ""
                }
            }
        }
    }
    return ""
}

proc roster::get_label {xlib jid} {
    set name [itemconfig $xlib $jid -name]
    if {[string equal $name ""]} {
        return $jid
    } else {
        return $name
    }
}

proc roster::override_category_and_subtype {xlib jid category subtype} {
    variable roster

    set roster(overridden_category_and_subtype,$xlib,$jid) \
        [list $category $subtype]
}

proc roster::override_category {xlib jid category} {
    variable roster

    if {![info exists roster(overridden_category_and_subtype,$xlib,$jid)]} {
        lassign [get_category_and_subtype $xlib $jid] category1 subtype
        set roster(overridden_category_and_subtype,$xlib,$jid) \
            [list $category $subtype]
    } else {
        set roster(overridden_category_and_subtype,$xlib,$jid) \
            [list $category \
                  [lindex \
                       $roster(overridden_category_and_subtype,$xlib,$jid) 1]]
    }
}

proc roster::override_subtype {xlib jid subtype} {
    variable roster

    if {![info exists roster(overridden_category_and_subtype,$xlib,$jid)]} {
        lassign [get_category_and_subtype $xlib $jid] category subtype1
        set roster(overridden_category_and_subtype,$xlib,$jid) \
            [list $category $subtype]
    } else {
        set roster(overridden_category_and_subtype,$xlib,$jid) \
            [list [lindex \
                       $roster(overridden_category_and_subtype,$xlib,$jid) 0] \
                  $subtype]
    }
}

proc roster::get_category_and_subtype {xlib jid} {
    variable roster

    if {[info exists roster(overridden_category_and_subtype,$xlib,$jid)]} {
        return $roster(overridden_category_and_subtype,$xlib,$jid)
    }

    set server [::xmpp::jid::server $jid]
    if {[info exists roster(overridden_category_and_subtype,$xlib,$server)]} {
        catch { unset roster(cached_category_and_subtype,$xlib,$jid) }
        set cs [heuristically_get_category_and_subtype $xlib $jid]
        set roster(overridden_category_and_subtype,$xlib,$jid) $cs
        return $cs
    }

    if {[info exists roster(cached_category_and_subtype,$xlib,$jid)]} {
        return $roster(cached_category_and_subtype,$xlib,$jid)
    }

    catch {plugins::cache_categories::request_category_and_subtype $xlib $jid}

    set cs [heuristically_get_category_and_subtype $xlib $jid]
    set roster(cached_category_and_subtype,$xlib,$jid) $cs
    return $cs
}

proc roster::heuristically_get_category_and_subtype {xlib jid} {
    variable roster

    ::xmpp::jid::split $jid node server resource

    if {$node eq "" && $resource eq ""} {
        set updomain [lindex [split $server .] 0]
        set category service

        switch -- $updomain {
            aim        -
            conference -
            icq        -
            irc        -
            jabber     -
            jud        -
            msn        -
            mrim       -
            pager      -
            rss        -
            serverlist -
            sms        -
            smtp       -
            yahoo {
                set subtype $updomain
            }
            gg {
                set subtype gadu-gadu
            }
            pogoda -
            weather {
                set subtype x-weather
            }
            default {
                set subtype ""
            }
        }

        return [list $category $subtype]
    }

    if {$node eq ""} {
        return [get_category_and_subtype $xlib $server]
    }

    if {[::xmpp::jid::resource $jid] eq ""} {
        lassign [get_category_and_subtype $xlib $server] scategory ssubtype

        switch -glob -- $scategory/$ssubtype {
            conference/irc {
                if {[string first "%" $node] >= 0} {
                    set category conference
                    set subtype irc
                } else {
                    set category user
                    set subtype ""
                }
            }
            conference/* {
                set category conference
                set subtype ""
            }
            default {
                set category user
                set subtype ""
            }
        }

        return [list $category $subtype]
    }

    return {user client}
}

###############################################################################

proc roster::item_to_xml {xlib jid} {
    variable roster
    variable undef_group_name
    variable chats_group_name
    variable own_resources_group_name

    set grtags {}
    foreach group $roster(group,$xlib,$jid) {
        if {$group ne "" && \
                $group ne $undef_group_name && \
                $group ne $chats_group_name && \
                $group ne $own_resources_group_name} {
            lappend grtags [::xmpp::xml::create group -cdata $group]
        }
    }

    set vars [list jid $jid]

    if {$roster(name,$xlib,$jid) ne ""} {
        lappend vars name $roster(name,$xlib,$jid)
    }

    return [::xmpp::xml::create item -attrs $vars -subelements $grtags]
}

proc roster::item_to_options {xlib jid} {
    variable roster
    variable undef_group_name
    variable chats_group_name
    variable own_resources_group_name

    set groups {}
    foreach group $roster(group,$xlib,$jid) {
        if {$group ne "" && \
                $group ne $undef_group_name && \
                $group ne $chats_group_name && \
                $group ne $own_resources_group_name} {
            lappend groups $group
        }
    }

    set opts [list -jid $jid]

    if {$roster(name,$xlib,$jid) ne ""} {
        lappend opts -name $roster(name,$xlib,$jid)
    }

    lappend opts -groups $groups

    return $opts
}

###############################################################################

proc roster::send_item {xlib jid} {
    hook::run roster_send_item_hook $xlib $jid
}

proc roster::send_item_fallback {xlib jid} {
    variable roster

    ::xmpp::roster::send $roster(token,$xlib) {*}[item_to_options $xlib $jid]
}

hook::add roster_send_item_hook roster::send_item_fallback 100

###############################################################################

proc roster::remove_item {xlib jid} {
    hook::run roster_remove_item_hook $xlib $jid
}

proc roster::remove_item_fallback {xlib jid} {
    variable roster

    ::xmpp::roster::send $roster(token,$xlib) -jid $jid -subscription remove

    ::xmpp::sendPresence $xlib -to $jid -type unsubscribe
    ::xmpp::sendPresence $xlib -to $jid -type unsubscribed

    lassign [get_category_and_subtype $xlib $jid] category subtype

    if {$category in {service server gateway} && \
        ![::xmpp::jid::equal [::xmpp::jid::removeResource $jid] \
                             [connection_server $xlib]]} {
        ::xmpp::register::remove $xlib $jid
    }
}

hook::add roster_remove_item_hook roster::remove_item_fallback 100

###############################################################################

proc roster::send_rename_group {xlib name new_name} {
    variable roster
    variable undef_group_name

    if {[string equal $new_name $name]} return

    hook::run roster_rename_group_hook $xlib $name $new_name

    set items {}

    foreach jid $roster(jids,$xlib) {
        switch -- [itemconfig $xlib $jid -subsc] {
            none - from - to - both { }
            default { continue }
        }

        if {$name in $roster(group,$xlib,$jid) || \
                ($name eq $undef_group_name && \
                     $roster(group,$xlib,$jid) eq {})} {
            set idx [lsearch -exact $roster(group,$xlib,$jid) $name]
            if {$new_name ne ""} {
                set roster(group,$xlib,$jid) \
                    [lreplace $roster(group,$xlib,$jid) $idx $idx $new_name]
            } else {
                set roster(group,$xlib,$jid) \
                    [lreplace $roster(group,$xlib,$jid) $idx $idx]
            }
            set roster(group,$xlib,$jid) \
                [lsort -unique $roster(group,$xlib,$jid)]
            lappend items [item_to_options $xlib $jid]
        }
    }

    foreach item $items {
        ::xmpp::roster::send $roster(token,$xlib) {*}$item
    }
}

###############################################################################

proc roster::send_remove_users_group {xlib name} {
    variable roster
    variable undef_group_name

    hook::run roster_remove_users_group_hook $xlib $name

    foreach jid $roster(jids,$xlib) {
        switch -- [itemconfig $xlib $jid -subsc] {
            none - from - to - both { }
            default { continue }
        }

        set groups $roster(group,$xlib,$jid)
        if {$name in $groups || \
                (($name eq $undef_group_name) && ($groups eq {}))} {
            remove_item $xlib $jid
        }
    }
}

###############################################################################

proc roster::resubscribe_group {xlib name} {
    variable roster
    variable undef_group_name

    foreach jid $roster(jids,$xlib) {
        if {$name in $roster(group,$xlib,$jid) || \
                ($name eq $undef_group_name && \
                     $roster(group,$xlib,$jid) eq {})} {
            lassign [get_category_and_subtype $xlib $jid] category type
            if {$category eq "user"} {
                ::xmpp::sendPresence $xlib -to $jid -type subscribe
            }
        }
    }
}

###############################################################################

proc roster::send_custom_presence_group {xlib name status} {
    variable roster
    variable undef_group_name

    foreach jid $roster(jids,$xlib) {
        if {$name in $roster(group,$xlib,$jid) || \
                ($name eq $undef_group_name && \
                     $roster(group,$xlib,$jid) eq {})} {
            lassign [get_category_and_subtype $xlib $jid] category type
            if {$category eq "user"} {
                send_custom_presence $xlib $jid $status
            }
        }
    }
}

###############################################################################

proc roster::add_group_by_jid_regexp {name regexp} {
    variable roster

    # TODO: xlib
    if {$name eq ""} return

    foreach xlib [connections] {
        set items {}

        foreach jid $roster(jids,$xlib) {
            if {[regexp -- $regexp $jid]} {
                lappend roster(group,$xlib,$jid) $name
                set roster(group,$xlib,$jid) \
                    [lsort -unique $roster(group,$xlib,$jid)]
                lappend items [item_to_options $xlib $jid]
            }
        }

        foreach item $items {
            ::xmpp::roster::send $roster(token,$xlib) {*}$item
        }
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
