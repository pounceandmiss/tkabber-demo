# shuffle.tcl --
#
#       It's a 1st Aprril joke plugin which shuffles letters in message words.
#
# Written by Ruslan Rakhmanin <rakhmaninr@gmail.com>
# Thanks to Serge Yudin xmpp:bigote@jabber.ru

# Disabling it.

return

namespace eval text_shuffler {
    variable testing 0
    variable nicks_collection
    variable url_regexp {
        (^|\s)
        ([^\w\d]*)
        (
        (?:
        (?: ftp|https?)://[-\w]+(\.\w[-\w]*)*
        |
        (?: [a-z0-9][-a-z0-9]* \. )+
        (?: com
        | edu
        | biz
        | gov
        | in(?:t|fo)
        | mil
        | net
        | org
        | name
        | aero
        | arpa
        | coop
        | museum
        | pro
        | travel
        | asia
        | [a-z][a-z]
        )
        )
        (?: : \d+ )?
        (?:
        (?:
        /
        [^.,?!:;"'<>()\[\]{}\s\x7F-\x9F]*
        )?
        (?:
        [.,?!:;]+ [^.,?!:;"'<>()\[\]{}\s\x7F-\x9F]+
        )*
        )?
        )
        ([^\w\d]*)
        (\s|$)
    }
}

# --------------------------------------------------
# Procedure for collecting nicks in groupchars
# Thanks to Alexey Smirnov <alexey.smirnov@gmx.com>
# --------------------------------------------------
proc text_shuffler::collecting_nicks {xlib jid type x args} {
    variable nicks_collection

    if {$type != "available" && $type != "unavailable"} {
        return
    }

    set group [::xmpp::jid::removeResource $jid]
    set chatid [::chat::chatid $xlib $group]

    if {[::chat::is_opened $chatid]} {
        if {[::chat::is_groupchat $chatid]} {
            if {[::xmpp::jid::resource $jid] == ""} {
                return
            }
            set nick [::chat::get_nick $xlib $jid groupchat]
            if {[info exists nicks_collection($group)]} {
                set idx [lsearch -exact $nicks_collection($group) $nick]
                if {$idx >= 0} {
                    if {$type == "unavailable"} {
                        set nicks_collection($group) \
                            [lreplace $nicks_collection($group) $idx $idx]
                    }
                } else {
                    if {$type == "available"} {
                        lappend nicks_collection($group) $nick
                    }
                }
            } else {
                if {$type == "available"} {
                    lappend nicks_collection($group) $nick
                }
            }
        }
    }
}
hook::add client_presence_hook \
        [namespace current]::text_shuffler::collecting_nicks 99

proc text_shuffler::shuffle_message {chatid user body type} {
    variable testing
    set group [chat::get_jid $chatid]
    set seconds [clock seconds]
    if {$testing || ([clock format $seconds -format %m/%d] == "04/01" && rand() < 0.05)} {
        upvar args margs
        set body [shuffle_text [lindex $margs 2] $group]
        set margs [lreplace $margs 2 2 $body]
    }
}

hook::add chat_send_message_hook \
        [namespace current]::text_shuffler::shuffle_message 55


proc text_shuffler::shuffle_text {text {group ""}} {
    set shtext ""
    variable url_regexp
    set at 0
    while {1} {
        set matched [regexp -expanded -nocase -indices \
                -start $at -- $url_regexp $text -> _ _ bounds]
        if {$matched} {
            lassign $bounds ub ue
            if {$at != $ub} {
                append shtext [shuffle_subtext [string range $text $at [expr $ub - 1]] $group]
            }
            append shtext [string range $text $ub $ue]
            set at [expr $ue + 1]
        } else {
            append shtext [shuffle_subtext [string range $text $at end] $group]
            set at [string length $text]
        }
        if {$at == [string length $text]} {
            break
        }
    }
    return $shtext
}


proc text_shuffler::shuffle_subtext {text_part {group ""}} {
    variable nicks_collection
    set nicks ""
    if {[info exists nicks_collection($group)]} {
        set nicks $nicks_collection($group)
    }
    set tindex [list -1 [string length $text_part]]
    foreach nick $nicks {
        set startindex 0
        set nicklen [string length $nick]
        while {[set index [string first $nick $text_part $startindex]] != -1} {
            set startindex [expr $index + $nicklen]
            set first 1
            for {set i 0} {$i < [llength $tindex]} {incr i} {
                if {$first} {
                    if {[lindex $tindex $i] >= $index} {
                        set tindex [linsert $tindex $i $index]
                        set first 0
                    }
                } else {
                    if {[lindex $tindex $i] <= $index} {
                        set tindex [lreplace $tindex $i $i]
                        incr i -1
                    } else {
                        set tindex [linsert $tindex $i [expr $index + $nicklen]]
                        break
                    }
                }
            }
        }
    }
    set shtext ""
    set previ 0
    foreach {ib ie} $tindex {
        if {$ie == [llength $tindex]} {
            incr ie -1
        }
        if {$previ != $ib} {
            append shtext [string range $text_part $previ $ib]
        }
        set previ $ie
        if {$ib != $ie} {
            set substring [string range $text_part [expr $ib + 1]  [expr $ie - 1]]

            foreach subpart [regexp -inline -all {[[:alpha:]]+|[^[:alpha:]]} $substring] {
                if {[regexp {[[:alpha:]]} $subpart]} {
                    set subpart [shuffle_word $subpart]
                }
                append shtext $subpart
            }
        }
    }
    if {$previ != [expr [llength $tindex] - 1]} {
        append shtext [string range $text_part $previ [expr [llength $tindex] - 1]]
    }
    return $shtext
}


proc text_shuffler::shuffle_word {nick} {
    set snick $nick
    if {[string length $snick] > 3} {
        if {[string length $snick] == 4} {
            set c1 [string index $snick 1]
            set c2 [string index $snick 2]
            set snick [string replace $snick 1 1 $c2]
            set snick [string replace $snick 2 2 $c1]
        } elseif {[string length $snick] == 5} {
            set c3 [string index $snick 3]
            set c2 [string index $snick 2]
            set snick [string replace $snick 3 3 $c2]
            set snick [string replace $snick 2 2 $c3]
        } elseif {[string length $snick] == 6} {
            set c3 [string index $snick 3]
            set c2 [string index $snick 2]
            set snick [string replace $snick 3 3 $c2]
            set snick [string replace $snick 2 2 $c3]
        } else {
            set ss [string range $snick 2 end-2]
            set ns ""
            set count 4
            while {[string length $ss] > 1} {
                set slen [string length $ss]
                if {$count < $slen} {
                    set slen $count
                }
                set n [expr int(rand() * $slen)]
                append ns [string index $ss $n]
                set ss [string replace $ss $n $n]
                if {$count == 0} {
                    set count 4
                } else  {
                    incr count -1
                }
            }
            append ns $ss
            set snick [string replace $snick 2 end-2 $ns]
        }
    }

    return $snick
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
