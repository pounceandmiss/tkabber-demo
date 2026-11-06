# logger.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       provides chats and groupchats logging.

namespace eval ::logger {
    variable options

    custom::defgroup Logging [::msgcat::mc "Logging options."] -group Chat

    custom::defvar options(logdir) [file join $::configdir logs] \
        [::msgcat::mc "Directory to store logs."] \
        -type string -group Logging

    custom::defvar options(log_chat) 1 \
        [::msgcat::mc "Store private chats logs."] \
        -type boolean -group Logging

    custom::defvar options(log_groupchat) 1 \
        [::msgcat::mc "Store group chats logs."] \
        -type boolean -group Logging

    variable version 1.0

    if {![file exists $options(logdir)]} {
        file mkdir $options(logdir)

        # Storing version for possible future conversions
        variable fd [open [file join $options(logdir) version] w]
        puts $fd $version
        close $fd
    }

    variable m2d
    variable d2m

    array set m2d [list [::msgcat::mc "January"]   01 \
                        [::msgcat::mc "February"]  02 \
                        [::msgcat::mc "March"]     03 \
                        [::msgcat::mc "April"]     04 \
                        [::msgcat::mc "May"]       05 \
                        [::msgcat::mc "June"]      06 \
                        [::msgcat::mc "July"]      07 \
                        [::msgcat::mc "August"]    08 \
                        [::msgcat::mc "September"] 09 \
                        [::msgcat::mc "October"]   10 \
                        [::msgcat::mc "November"]  11 \
                        [::msgcat::mc "December"]  12]

    array set d2m [list 01 [::msgcat::mc "January"]   \
                        02 [::msgcat::mc "February"]  \
                        03 [::msgcat::mc "March"]     \
                        04 [::msgcat::mc "April"]     \
                        05 [::msgcat::mc "May"]       \
                        06 [::msgcat::mc "June"]      \
                        07 [::msgcat::mc "July"]      \
                        08 [::msgcat::mc "August"]    \
                        09 [::msgcat::mc "September"] \
                        10 [::msgcat::mc "October"]   \
                        11 [::msgcat::mc "November"]  \
                        12 [::msgcat::mc "December"]]
}

#############################################################################

proc ::logger::add_menu_item {state category m xlib jid} {
    switch -- $category {
        roster {
            set rjid [roster::find_jid $xlib $jid]
            if {$rjid ne ""} {
                set jid $rjid
            }
        }
        chat {
            set nas [::xmpp::jid::removeResource $jid]
            if {![chat::is_groupchat [chat::chatid $xlib $nas]]} {
                set jid $nas
            }
        }
    }
    $m add command -label [::msgcat::mc "Show history"] \
           -state $state \
           -command [list logger::show_log $jid -connection $xlib \
                                                -metacontact 1]
}

#############################################################################

hook::add chat_create_user_menu_hook \
    [list ::logger::add_menu_item normal chat] 65
hook::add chat_create_conference_menu_hook \
    [list ::logger::add_menu_item normal group] 65
hook::add roster_create_groupchat_user_menu_hook \
    [list ::logger::add_menu_item normal grouproster] 65
hook::add roster_conference_popup_menu_hook \
    [list ::logger::add_menu_item normal roster] 65
hook::add roster_service_popup_menu_hook \
    [list ::logger::add_menu_item disabled roster] 65
hook::add roster_jid_popup_menu_hook \
    [list ::logger::add_menu_item normal roster] 65
hook::add message_dialog_menu_hook \
    [list ::logger::add_menu_item disabled message] 65
hook::add search_popup_menu_hook \
    [list ::logger::add_menu_item disabled search] 65

#############################################################################

proc ::logger::str_to_log {str} {
    string map {\\ \\\\ \r \\r \n \\n} $str
}

#############################################################################

proc ::logger::log_to_str {str} {
    string map {\\\\ \\ \\r \r \\n \n} $str
}

#############################################################################

proc ::logger::jid_to_filename {jid} {
    if {$jid eq ""} {
        set jid @@empty
    }
    set utf8_jid [encoding convertto utf-8 $jid]
    set len [string length $utf8_jid]
    set filename ""
    binary scan $utf8_jid cu* syms
    set i 0
    foreach sym $syms {
        incr i
        switch -- $sym {
            34 - 37 - 39 - 42 - 43 - 47 - 58 - 59 - 60 - 62 - 63 - 92 - 124 - 126 {
          # 34 " 37 % 39 ' 42 * 43 + 47 / 58 : 59 ; 60 < 62 > 63 ? 92 \ 124 | 126 ~
                append filename [format "%%%02X" $sym]
            }
            46 {
          # 46 .
                if {$i == $len} {
                    append filename [format "%%%02X" $sym]
                } else {
                    append filename [binary format c $sym]
                }
            }
            default {
                if {$sym >= 128 || $sym <= 32} {
                    append filename [format "%%%02X" $sym]
                } else {
                    append filename [binary format c $sym]
                }
            }
        }
    }
    if {[string index $filename 253] eq "%"} {
        return [string range $filename 0 252]
    }
    if {[string index $filename 252] eq "%"} {
        return [string range $filename 0 251]
    }
    return [string range $filename 0 253]
}

#############################################################################

proc ::logger::filename_to_jid {filename} {
    if {$filename eq "@@empty"} {
        return ""
    } else {
        set len [string length $filename]
        set utf8_jid ""
        for {set i 0} {$i < $len} {incr i} {
            catch {
                binary scan $filename @${i}a sym
                switch -- $sym {
                    "%" {
                        incr i
                        binary scan $filename @${i}a2 num
                        append utf8_jid [binary format c 0x$num]
                        incr i
                    }
                    default {
                        append utf8_jid $sym
                    }
                }
            }
        }
        return [encoding convertfrom utf-8 $utf8_jid]
    }
}

#############################################################################

proc ::logger::cdopen {filepath {mode r}} {
    set dir [file dirname $filepath]
    set file [file tail $filepath]
    set current_dir [pwd]
    cd $dir
    if {[catch {open $file $mode} fd]} {
        cd $current_dir
        return -code error $fd
    } else {
        cd $current_dir
        return $fd
    }
}

#############################################################################

proc ::logger::log_message {chatid from type body x} {
    variable options

    if {$type eq "chat" && !$options(log_chat)} return
    if {$type eq "groupchat" && !$options(log_groupchat)} return

    if {![hook::is_flag draw_message_hook log]} return

    foreach xelem $x {
        ::xmpp::xml::split $xelem tag xmlns attrs cdata subels

        # Don't log message if this 'empty' tag is present. It indicates
        # messages history in chat window.
        if {$tag eq "" && $xmlns eq "tkabber:x:nolog"} {
            return
        }
    }

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]
    set bjid [::xmpp::jid::removeResource $jid]
    if {$type eq "chat" && ![chat::is_groupchat [chat::chatid $xlib $bjid]]} {
        set jid $bjid
    }

    set nick [chat::get_nick $xlib $from $type]
    if {[::xmpp::jid::equal $from [my_jid $xlib $jid]]} {
        set me 1
    } else {
        set me 0
    }

    set seconds [::xmpp::xml::getAttr [::xmpp::delay::parse $x] seconds]
    set ts [clock format $seconds -format "%Y%m%dT%H%M%S" -gmt 1]
    set year [clock format $seconds -format %Y]
    set month [clock format $seconds -format %m]

    file mkdir [file join $options(logdir) $year $month]
    set fd [cdopen [file join $options(logdir) $year $month [jid_to_filename $jid]] a]
    fconfigure $fd -encoding utf-8
    puts $fd [str_to_log [list timestamp $ts \
                               seconds $seconds \
                               jid $from \
                               nick $nick \
                               body $body \
                               me $me \
                               type $type]]
    close $fd
}

hook::add draw_message_hook ::logger::log_message 15

#############################################################################

proc ::logger::winid {name} {
    set allowed_name [jid_to_tag $name]
    return .log_$allowed_name
}

#############################################################################

proc ::logger::describe_month {year-month} {
    variable d2m

    lassign [split ${year-month} -] year month
    return "$d2m($month) $year"
}

#############################################################################

proc ::logger::create_log_viewer {lw jid args} {
    global tcl_platform
    global defaultnick

    set metacontact 0
    foreach {key val} $args {
        switch -- $key {
            -connection { set xlib $val }
            -subdirs { set subdirs $val }
            -metacontact { set metacontact $val }
        }
    }

    if {![info exists xlib]} {
        set xlib [lindex [connections] 0]
    }

    if {!$::ifacetk::roster::options(enable_metacontacts)} {
        set metacontact 0
    }

    set jids [list $jid]
    if {$metacontact} {
        foreach tag [::plugins::metacontacts::get_all_tags $xlib] {
            set mjids [::plugins::metacontacts::get_jids $xlib $tag]
            if {[lsearch -exact $mjids $jid] >= 0} {
                set jids $mjids
                break
            }
        }
    }

    foreach j $jids {
        lappend logfiles [jid_to_filename $j]
    }

    set mynick [get_group_nick $xlib $jid]

    Toplevel $lw -class Chat
    wm group $lw .
    wm withdraw $lw
    set title [::msgcat::mc "History for %s" $jid]
    wm title $lw $title
    wm iconname $lw $title

    set lf [ScrolledWindow $lw.sw]
    set l [Text $lw.log -wrap word -takefocus 0]

    set mf [Frame $lw.mf]
    pack $mf -side top -fill x -expand no -padx 1m -pady 1m

    set jlabel [Label $mf.jlabel -text [::msgcat::mc "Log for:"]]
    pack $jlabel -side left

    if {[llength $logfiles] == 1} {
        set jselect [Label $mf.jselect \
                           -text "[::msgcat::mc {JID}] $jid"]
    } else {
        set textjids [list "[::msgcat::mc {Metacontact}] [lindex $jids 0]"]
        set idx 0
        foreach j $jids {
            if {[::xmpp::jid::equal $j $jid]} {
                set idx [llength $textjids]
            }
            lappend textjids "[::msgcat::mc {JID}] $j"
        }
        set w 0
        foreach textjid $textjids {
            set w [::tcl::mathfunc::max $w [string length $textjid]]
        }
        set jselect [Combobox $mf.jselect \
                         -editable no \
                         -exportselection no \
                         -values $textjids \
                         -width [expr {$w+2}] \
                         -modifycmd [list \
                            [namespace current]::change_month \
                                    $mf.jselect $mf.mcombo $logfiles $l $mynick]]
        $jselect set [lindex $textjids $idx]
    }
    pack $jselect -side left

    set mlabel [Label $mf.mlabel -text "   [::msgcat::mc {Select month:}]"]
    pack $mlabel -side left
    set ebutton [Button $mf.ebutton \
                        -text [::msgcat::mc "Export to XHTML"] \
                        -command [list [namespace current]::export \
                                       $mf.jselect $mf.mcombo $logfiles $mynick]]
    pack $ebutton -side right
    pack $lf -padx 1m -pady 1m -fill both -expand yes

    $lf setwidget $l

    regsub -all %W [bind Text <Prior>] [double% $l] prior_binding
    regsub -all %W [bind Text <Next>]  [double% $l] next_binding
    bind $lw <Prior> $prior_binding
    bind $lw <Next>  $next_binding

    $l tag configure they -foreground [option get $lw theyforeground Chat]
    $l tag configure me -foreground [option get $lw meforeground Chat]
    $l tag configure server_lab \
       -foreground [option get $lw serverlabelforeground Chat]
    $l tag configure server \
       -foreground [option get $lw serverforeground Chat]

    $l configure -state disabled

    if {![info exists subdirs]} {
        foreach lf $logfiles {
            lappend subdirs {*}[get_subdirs $lf]
        }
        set subdirs [lsort -unique $subdirs]
    }

    set ympairs {}
    foreach sd [lsort -decreasing $subdirs] {
        lappend ympairs [describe_month $sd]
    }
    lappend ympairs [::msgcat::mc "All"]

    set mcombo [Combobox $mf.mcombo \
                         -editable no \
                         -exportselection no \
                         -values $ympairs \
                         -modifycmd [list \
                            [namespace current]::change_month \
                                          $mf.jselect $mf.mcombo $logfiles $l $mynick]]
    $mcombo set [lindex $ympairs 0]
    pack $mcombo -side left

    hook::run open_log_post_hook $xlib $jid $lw

    wm deiconify $lw
}

#############################################################################

proc ::logger::show_log {jid args} {
    set lw [winid $jid]
    debugmsg plugins "LOGGER: $lw"

    variable $lw
    upvar 1 $lw state

    if {![winfo exists $lw]} {
        create_log_viewer $lw $jid {*}$args
    } else {
        focus -force $lw
    }

    foreach {key val} $args {
        switch -- $key {
            -when { set when $val }
            -timestamp { set timestamp $val }
        }
    }

    set logfile [jid_to_filename $jid]
    set mynick [get_group_nick "" $jid]

    set log $lw.log
    set jbox $lw.mf.jselect
    set cbox $lw.mf.mcombo

    set ympairs [$cbox cget -values]
    if {[info exists when]} {
        set text [describe_month $when]
        if {$text ni $ympairs} {
            error "no log entries for: $when"
        }
    } else {
        set text [lindex $ympairs 0]
    }

    $cbox set $text

    # TODO
    change_month $jbox $cbox [list $logfile] $log $mynick

    if {[info exists timestamp]} {
        set pos [lindex [$log tag ranges TS-$timestamp] 0]
        if {$pos eq ""} { set pos end }
    } else {
        set pos end
    }

    $log see $pos
}

#############################################################################

proc ::logger::get_subdirs {logfile} {
    variable options

    set subdirs {}
    foreach yeard [glob -nocomplain -type d -directory $options(logdir) *] {
        foreach monthd [glob -nocomplain -type d -directory $yeard *] {
            if {[file exists [file join $monthd $logfile]]} {
                lappend subdirs [file tail $yeard]-[file tail $monthd]
            }
        }
    }

    return $subdirs
}

#############################################################################

proc ::logger::draw_messages {l hist mynick} {
    $l configure -state normal
    $l delete 1.0 end

    add_messages $l $hist $mynick
}

#############################################################################

proc ::logger::formatxmppseconds {seconds} {
    clock format $seconds -format {%Y-%m-%d %X}
}

proc ::logger::formatxmppts {xmppts} {
    set seconds [clock scan $xmppts -gmt 1]
    formatxmppseconds $seconds
}

#############################################################################

proc ::logger::exists_and_empty {what} {
    upvar 1 $what var
    expr {[info exists var] && $var eq ""}
}

proc ::logger::exists_and_nonempty {what} {
    upvar 1 $what var
    expr {[info exists var] && $var ne ""}
}

proc ::logger::add_messages {l hist mynick} {
    $l configure -state normal

    foreach vars $hist {
        array unset tmp
        if {[catch {array set tmp $vars}]} continue

        if {[info exists tmp(seconds)] && [info exists tmp(timestamp)]} {
            $l insert end \[[formatxmppseconds $tmp(seconds)]\] \
                [list TS-$tmp(timestamp)]
        } elseif {[info exists tmp(timestamp)]} {
            $l insert end \[[formatxmppts $tmp(timestamp)]\] \
                [list TS-$tmp(timestamp)]
        }
        if {[exists_and_empty tmp(jid)]} {
            # synthesized message
            $l insert end "---" server_lab
            set servertag server
        } else {
            if {[exists_and_empty tmp(nick)]} {
                # message from the server:
                $l insert end "---" server_lab
                set servertag server
            } else {
                set nick $tmp(nick)
                if {([info exists tmp(me)] && $tmp(me)) || $nick eq $mynick} {
                    set tag me
                } else {
                    set tag they
                }
                if {[info exists tmp(body)] && [regsub {^/me } $tmp(body) {} body]} {
                    $l insert end "*$nick $body" $tag
                    unset tmp(body)
                } else {
                    $l insert end "<$nick>" $tag
                }
                set servertag ""
            }
        }
        if {[info exists tmp(body)]} {
            $l insert end " $tmp(body)" $servertag
        }
        if {![$l compare "end -1 chars linestart" == "end -1 chars"]} {
            $l insert end "\n"
        }
    }
    $l configure -state disabled
}

#############################################################################

proc ::logger::change_month {jselect mcombo logfiles l mynick} {
    variable m2d

    if {[catch {$jselect current} jidx]} {
        # jselect is a label
        set jidx -1
    }
    incr jidx -1
    if {$jidx >= 0 && [llength $logfiles] > 1} {
        set logfiles [list [lindex $logfiles $jidx]]
    }

    set month [$mcombo get]
    draw_messages $l {} $mynick
    if {$month eq [::msgcat::mc "All"]} {
        foreach logfile $logfiles {
            foreach m [get_subdirs $logfile] {
                lappend tmp($m) $logfile
            }
        }
        foreach m [lsort -unique -increasing [array names tmp]] {
            set hist {}
            foreach logfile $logfiles {
                lappend hist {*}[read_hist_from_file $logfile $m]
            }
            add_messages $l [lsort -index 1 $hist] $mynick
            update
        }
    } else {
        set my_list [split $month " "]
        set month [lindex $my_list end]-$m2d([join [lrange $my_list 0 end-1] " "])
        set hist {}
        foreach logfile $logfiles {
            lappend hist {*}[read_hist_from_file $logfile $month]
        }
        add_messages $l [lsort -index 1 $hist] $mynick
    }
    $l see end
}

#############################################################################

proc ::logger::read_lines_from_file {filename max} {
    if {$max == 0} {
        return {}
    }
    set fd [cdopen $filename r]
    if {$max < 0} {
        chan configure $fd -encoding utf-8
        set lines [split [chan read -nonewline $fd] \n]
        chan close $fd
        return $lines
    } else {
        chan configure $fd -translation binary
        chan seek $fd 0 end
        set cur_offset [chan tell $fd]
        set prefix ""
        set lines {}
        set old_chunk_size 0
        set chunk_size 24576
        while {[llength $lines] < $max} {
            if {$cur_offset > $chunk_size} { 
                set new_offset [expr {$cur_offset - $chunk_size}]
                set shift [expr {-($chunk_size + $old_chunk_size)}]
                chan seek $fd $shift current
            } else {
                chan seek $fd 0 start
                set new_offset 0
                set chunk_size $cur_offset
            }
            set str [chan read $fd $chunk_size]$prefix
            set npos [string first \n $str]
            if {$npos < 0} {
                set prefix $str
            } else {
                set prefix [string range $str 0 [incr npos -1]]
                set lines [linsert $lines 0 {*}[split [encoding convertfrom utf-8 \
                                                            [string range $str [incr npos 2] end]] \n]]
            }

            if {$new_offset == 0} {
                if {$prefix ne ""} {
                    set lines [linsert $lines 0 [encoding convertfrom utf-8 $prefix]]
                }
                break
            }

            set old_chunk_size $chunk_size
            set chunk_size [expr {2*$chunk_size}]
            set cur_offset $new_offset
        }
        chan close $fd
        if {[regexp {^\s*$} [lindex $lines end]]} {
            set lines [lrange $lines 0 end-1]
        }
        lrange $lines [expr {[llength $lines] - $max}] end
    }
}

proc ::logger::read_hist_from_file {logfile month {max -1}} {
    variable options

    lassign [split $month -] year month1
    set filename [file join $options(logdir) $year $month1 $logfile]

    if {[file exists $filename]} {
        set hist [read_lines_from_file $filename $max]

        set hist1 {}
        foreach line $hist {
            lappend hist1 [log_to_str $line]
        }
        return $hist1
    } else {
        return {}
    }
}

#############################################################################

proc ::logger::logs_exist {jid} {
    expr {[llength [get_subdirs [jid_to_filename $jid]]] > 0}
}

proc ::logger::get_last_messages {jids type max interval} {
    if {$max == 0 || $interval == 0} {
        return {}
    }

    foreach jid $jids {
        set logfile [jid_to_filename $jid]
        foreach month [get_subdirs $logfile] {
            lappend logs($month) $logfile
        }
    }

    set messages {}
    set curseconds [clock seconds]
    set max1 [expr {$max - 1}]
    foreach mon [lsort -decreasing [array names logs]] {
        foreach logfile $logs($mon) {
            catch {
                lappend messages {*}[read_hist_from_file $logfile $mon $max]
            }
        }
        set messages [lsort -decreasing $messages]
        set len [llength $messages]

        if {$max > 0 && $len > $max} {
            set messages [lrange $messages 0 $max1]
            set len [llength $messages]
        }

        if {$interval > 0} {
            set idx -1
            foreach m $messages {
                if {[catch {dict exists $m type} res] || !$res || [dict get $m type] ne $type} continue
                if {![dict exists $m timestamp]} continue

                if {[dict exists $m seconds]} {
                    set seconds [dict get $m seconds]
                } else {
                    set seconds [clock scan [dict get $m timestamp] -gmt 1]
                }
                if {$interval > 0 && $curseconds - $seconds <= $interval * 3600} {
                    incr idx
                } else {
                    break
                }
            }
            set messages [lrange $messages 0 $idx]
        }

        if {$max > 0 && $len >= $max} break
        if {$interval > 0 && $idx < $len-1} break 
    }
    return [lsort -increasing -index 1 $messages]
}

#############################################################################

proc ::logger::export {jselect mcombo logfiles mynick} {
    variable m2d

    if {[catch {$jselect current} jidx]} {
        # jselect is a label
        set jidx -1
    }
    incr jidx -1
    if {$jidx >= 0 && [llength $logfiles] > 1} {
        set logfiles [list [lindex $logfiles $jidx]]
    }

    set month [$mcombo get]
    set hist {}
    if {$month eq [::msgcat::mc "All"]} {
        foreach logfile $logfiles {
            foreach m [get_subdirs $logfile] {
                lappend tmp($m) $logfile
            }
        }
        foreach m [lsort -unique -increasing [array names tmp]] {
            set h {}
            foreach logfile $logfiles {
                lappend h {*}[read_hist_from_file $logfile $m]
            }
            lappend hist {*}[lsort -index 1 $h]
        }
    } else {
        set my_list [split $month " "]
        set month [lindex $my_list end]-$m2d([join [lrange $my_list 0 end-1] " "])
        set h {}
        foreach logfile $logfiles {
            lappend h {*}[read_hist_from_file $logfile $month]
        }
        lappend hist {*}[lsort -index 1 $h]
    }

    set filename [tk_getSaveFile -defaultextension .html]
    if {$filename eq ""} return
    set fd [open $filename w]
    fconfigure $fd -encoding utf-8

    puts $fd {<?xml version="1.0" encoding="UTF-8"?>}
    puts $fd {<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "DTD/xhtml1-strict.dtd">}
    puts $fd {<html xmlns="http://www.w3.org/1999/xhtml">}
    puts $fd {<head><style type="text/css">}
    puts $fd [write_css]
    puts $fd {</style></head>}

    foreach vars $hist {
        array unset tmp
        if {[catch {array set tmp $vars}]} continue

        set subtags {}
        if {[info exists tmp(timestamp)]} {
            if {[info exists tmp(seconds)]} {
                set seconds $tmp(seconds)
            } else {
                set seconds [clock scan $tmp(timestamp) -gmt 1]
            }
            set timestamp [clock format $seconds -format {[%Y-%m-%d %X]}]
            lappend subtags [::xmpp::xml::create span \
                                    -attrs {class timestamp} \
                                    -cdata $timestamp]
        }
        if {[info exists tmp(nick)] && $tmp(nick) ne ""} {
            if {([info exists tmp(me)] && $tmp(me)) || $tmp(nick) eq $mynick} {
                set tag me
            } else {
                set tag they
            }
            if {[info exists tmp(body)] && [regsub {^/me } $tmp(body) {} body]} {
                set nick "*$tmp(nick) $body"
                unset tmp(body)
            } else {
                set nick "<$tmp(nick)> "
            }
            lappend subtags [::xmpp::xml::create span \
                                    -attrs [list class $tag] \
                                    -cdata $nick]

            if {[info exists tmp(body)]} {
                lappend subtags [::xmpp::xml::create span \
                                        -attrs {class body} \
                                        -cdata "$tmp(body)"]
            }
        } else {
            if {[info exists tmp(body)]} {
                lappend subtags [::xmpp::xml::create span \
                                        -attrs {class server} \
                                        -cdata "--- $tmp(body)"]
            }
        }
        #if {![$l compare "end -1 chars linestart" == "end -1 chars"]} {
        #    puts "\n"
        #}
        set msg [::xmpp::xml::create div \
                        -attrs {class message} \
                        -subelements $subtags]

        puts $fd [::xmpp::xml::toText $msg]
    }

    puts $fd {</html>}
    close $fd
}

#############################################################################

proc ::logger::write_css {} {
    return "
html body {
    background-color: white;
    color: black;
}

.me {
    color: red;
}

.they {
    color: blue;
}

.server {
    color: green;
}
"
}

#############################################################################

proc ::logger::convert_subdir_log {t logfrom logto jid dir} {
    if {[catch {
            set fd [cdopen $logfrom r]
        } err]} {
        $t configure -state normal
        $t insert end [::msgcat::mc "File %s cannot be opened: %s.\
                                     History for %s (%s) is NOT converted\n" \
                                    $err $logfrom $jid $dir] error
        $t configure -state disabled
        $t see end
        update
        return
    }
    fconfigure $fd -encoding utf-8
    set hist [read $fd]
    close $fd

    set fd [cdopen $logto a]
    fconfigure $fd -encoding utf-8
    if {[catch {
            foreach vars $hist {
                puts $fd [str_to_log $vars]
            }
        }]} {
        $t configure -state normal
        $t insert end [::msgcat::mc "File %s is corrupt.\
                                     History for %s (%s) is NOT converted\n" \
                                    $logfrom $jid $dir] error
        $t configure -state disabled
        $t see end
    } else {
        $t configure -state normal
        $t insert end "($dir) $jid\n"
        $t configure -state disabled
        $t see end
    }
    close $fd
    update
}

proc ::logger::convert_root_log {t dirfrom dirto filename jid} {
    set logfile [file join $dirfrom $filename]
    if {[catch {
            set fd [cdopen $logfile r]
        } err]} {
        $t configure -state normal
        $t insert end [::msgcat::mc "File %s cannot be opened: %s.\
                                     History for %s is NOT converted\n" \
                                    $err $logfile $jid] error
        $t configure -state disabled
        $t see end
        update
        return
    }
    fconfigure $fd -encoding utf-8
    set hist [read $fd]
    close $fd

    if {[catch {
            foreach vars $hist {
                array unset tmp
                if {[catch {array set tmp $vars}]} continue

                if {[info exists tmp(timestamp)]} {
                    set seconds [clock scan $tmp(timestamp) -gmt 1]
                    set ym [clock format $seconds -format %Y-%m]
                    lappend newhist($ym) $vars
                }
            }
        }]} {
        $t configure -state normal
        $t insert end [::msgcat::mc "File %s is corrupt.\
                                     History for %s is NOT converted\n" \
                                    $logfile $jid] error
        $t configure -state disabled
        $t see end
        update
        return
    }

    foreach ym [lsort [array names newhist]] {
        $t configure -state normal
        $t insert end "($ym) $jid\n"
        $t configure -state disabled
        $t see end
        update
        lassign [split $ym -] year month
        set dir [file join $dirto $year $month]
        set newlog [file join $dir [jid_to_filename $jid]]
        file mkdir $dir

        set fd [cdopen $newlog a]
        fconfigure $fd -encoding utf-8
        catch {
            foreach vars $newhist($ym) {
                puts $fd [str_to_log $vars]
            }
        }
        close $fd
    }
}

proc ::logger::convert_logs {t dirfrom dirto} {
    variable version

    # Heuristically reconstruct JIDs
    set fnlist {}
    foreach subdir [glob -nocomplain -type d -directory $dirfrom *] {
        set dir [file tail $subdir]
        if {![regexp {^(\d\d\d\d)-(\d\d)$} $dir -> year month]} continue

        foreach filepath [glob -nocomplain -type f -directory $subdir *] {
            lappend fnlist [file tail $filepath]
        }
    }
    foreach filepath [glob -nocomplain -type f -directory $dirfrom *] {
        lappend fnlist [file tail $filepath]
    }
    # Sort the list. It's important not only because it removes duplicates
    set fnlist [lsort -unique $fnlist]

    foreach fn $fnlist {
        # Set prefix (for processing groupchats)
        if {![info exists prefix] || [string first $prefix $fn] != 0} {
            set prefix $fn
        }

        # Simple case: no or one underscore in the filename
        set idx [string first _ $fn]
        if {($idx < 0) || ([string first _ $fn [expr {$idx + 1}]] < 0)} {
            set JID($fn) [string map {_ @} $fn]
            continue
        }

        # JID without a resource (very likely)
        # Since underscore is not allowed in domain names, just replace
        # the last one by @. It's the best guess we can do
        if {$prefix eq $fn} {
            set idx [string last _ $fn]
            set pr [string range $fn 0 [expr {$idx - 1}]]
            set sf [string range $fn [expr {$idx + 1}] end]
            set JID($fn) $pr@$sf
            continue
        }

        # JID with a resource is a private chat with someone in the
        # conference room. Take room JID from the $prefix and add
        # resource (don't replace _ in the resource)
        set idx [expr {[string length $prefix] + 1}]
        set sf [string range $fn $idx end]
        set JID($fn) $JID($prefix)/$sf
    }

    # Create dir for new logs
    if {![file exists $dirto]} {
        file mkdir $dirto
    }

    # Process all subdirs YYYY-MM
    foreach subdir [glob -nocomplain -type d -directory $dirfrom *] {
        set dir [file tail $subdir]
        if {![regexp {^(\d\d\d\d)-(\d\d)$} $dir -> year month]} continue

        foreach filepath [glob -nocomplain -type f -directory $subdir *] {
            set jid $JID([file tail $filepath])
            set filename [jid_to_filename $jid]
            set fdir [file join $dirto $year $month]
            file mkdir $fdir
            convert_subdir_log $t $filepath [file join $fdir $filename] $jid $dir
        }
    }

    # Process all files in log dir itself
    foreach filepath [glob -nocomplain -type f -directory $dirfrom *] {
        if {[file tail $filepath] eq "message_archive"} {
            convert_subdir_log $t $filepath \
                                  [file join $dirto [file tail $filepath]] \
                                  message_archive ""
        } else {
            convert_root_log $t $dirfrom $dirto \
                             [file tail $filepath] $JID([file tail $filepath])
        }
    }

    # Storing version for possible future conversions
    set fd [open [file join $dirto version] w]
    puts $fd $version
    close $fd
}

#############################################################################

proc ::logger::convert_on_start {} {
    variable version
    variable options

    set version_file [file join $options(logdir) version]
    if {[file exists $version_file]} {
        set fd [open $version_file r]
        set v [string trim [read $fd]]
        close $fd
        if {$v >= $version} return
    }

    set parent_dir [file dirname $options(logdir)]
    set log_dir [file tail $options(logdir)]

    if {$log_dir eq ""} {
        return -code error \
               [::msgcat::mc "You're using root directory %s for storing Tkabber\
                              logs!\n\nI refuse to convert logs database." \
                             $options(logdir)]
    }

    # Create temporary directory for converted logs
    set dir $log_dir.new
    while {[file exists [file join $parent_dir $dir]]} {
        set dir $dir~
    }

    set w .log_convert

    Dialog $w -title [::msgcat::mc "Converting Log Files"] \
        -separator 1 -anchor e -default 0 -cancel 0 -modal none

    bind $w <Destroy> [list set convert_result 1]

    $w add -text [::msgcat::mc "Close"] \
           -state disabled \
           -command [list destroy $w]

    set f [$w getframe]

    set msg [message $f.msg -aspect 50000 \
                     -text [::msgcat::mc "Please, be patient while chats\
                                          history is being converted to new format"]]
    pack $msg

    set sw [ScrolledWindow $f.sw]
    pack $sw -expand yes -fill both

    set t [text $sw.t -state disabled -wrap word]
    $t tag configure error -foreground [option get $t errorForeground Text]
    $sw setwidget $t

    $w draw
    grab $w

    convert_logs $t $options(logdir) [file join $parent_dir $dir]

    set bdir $log_dir~
    while {[file exists [file join $parent_dir $bdir]]} {
        set bdir $bdir~
    }
    file rename -- $options(logdir) [file join $parent_dir $bdir]
    file rename -- [file join $parent_dir $dir] $options(logdir)

    if {[winfo exists $w]} {
        $w itemconfigure 0 -state normal

        $msg configure -text [::msgcat::mc "Chats history is converted.\nBackup\
                                            of the old history\
                                            is stored in %s" \
                                           [file join $parent_dir $bdir]]

        $t configure -state normal
        $t insert end "[::msgcat::mc {Conversion is finished}]\n"
        $t configure -state disabled
        $t see end

        vwait convert_result
    }
    catch {unset ::convert_result}
}

hook::add finload_hook ::logger::convert_on_start 1000

# vim:ft=tcl:ts=8:sw=4:sts=4:et
