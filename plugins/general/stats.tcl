# stats.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin
#       which implements the Statistics Gathering (XEP-0039) protocol.

namespace eval stats {}

set ::NS(stats) http://jabber.org/protocol/stats


proc stats::open_window {} {
    variable lastline
    variable f

    set w .stats

    if {[winfo exists $w]} {
        return
    }


    add_win $w -title [::msgcat::mc "Statistics monitor"] \
        -tabtitle [::msgcat::mc "Statistics"] \
        -class Stats \
        -raise 1
        #-raisecmd [list focus $w.tree] \

    set sw [ScrolledWindow $w.sw]
    pack $sw -side top -fill both -expand yes
    set sf [ScrollableFrame $w.sf]
    $sw setwidget $sf

    set f [$sf getframe]

    set i 0
    foreach label [list [::msgcat::mc "JID"] \
                        [::msgcat::mc "Node"] \
                        [::msgcat::mc "Name "] \
                        [::msgcat::mc "Value"] \
                        [::msgcat::mc "Units"]] {
        set l [label $f.titlelabel$i -text $label]
        grid $l -row 0 -column $i -sticky w

        incr i
    }

    set i 7
    set l [label $f.titlelabel$i -text [::msgcat::mc "Timer"]]
    grid $l -row 0 -column $i -sticky w -columnspan 2

    set lastline 1
}

proc stats::add_line {jid node name} {
    variable data
    variable lastline
    variable f

    set n $lastline
    incr lastline

    set l [label $f.ljid$n -text $jid]
    grid $l -row $n -column 0 -sticky w

    set l [label $f.lnode$n -text $node]
    grid $l -row $n -column 1 -sticky w

    set l [label $f.lname$n -text $name]
    grid $l -row $n -column 2 -sticky w

    set l [label $f.lvalue$n \
               -textvariable [namespace current]::data(value,$jid,$node,$name)]
    grid $l -row $n -column 3 -sticky e

    set l [label $f.lunits$n \
               -textvariable [namespace current]::data(units,$jid,$node,$name)]
    grid $l -row $n -column 4 -sticky w

    set b [button $f.brequest$n -text [::msgcat::mc "Request"] \
               -command [list [namespace current]::request_value \
                             $jid $node $name]]
    grid $b -row $n -column 5 -sticky w

    set b [button $f.bremove$n -text [::msgcat::mc "Remove"] \
               -command [list [namespace current]::remove_line \
                             $n]]
    grid $b -row $n -column 6 -sticky w

    set s [Spinbox $f.spin$n 0 1000000000 1 \
                   [namespace current]::data(tmpperiod,$jid,$node,$name) \
                   -width 4]
    trace add variable [namespace current]::data(tmpperiod,$jid,$node,$name) write \
          [list [namespace current]::unset_timer $n $jid $node $name]
    grid $s -row $n -column 7 -sticky w

    catch {unset data(period,$jid,$node,$name)}

    set b [button $f.bsettimer$n -text [::msgcat::mc "Set"] \
               -relief raised \
               -command [list [namespace current]::toggle_timer \
                             $n $jid $node $name]]
    grid $b -row $n -column 8 -sticky w

}

proc stats::query_list {xlib jid node args} {
    set vars {}
    if {$node != ""} {
        lappend vars node $node
    }

    if {$xlib == ""} {
        set xlib [lindex [connections] 0]
    }

    ::xmpp::sendIQ $xlib get \
        -query [::xmpp::xml::create query \
                        -xmlns $::NS(stats) \
                        -attrs $vars] \
        -to $jid \
        -command [list [namespace current]::recv_query_list_result $jid $node]
}

proc stats::recv_query_list_result {jid node res child} {
    variable data

    if {$res ne "ok"} {
        return
    }

    open_window

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    foreach item $subels {
        ::xmpp::xml::split $item stag sxmlns sattrs scdata ssubels

        if {$stag == "stat"} {
            set name [::xmpp::xml::getAttr $sattrs name]
            add_line $jid $node $name
        }
    }
}

proc stats::request_value {jid node name} {
    set vars {}
    if {$node != ""} {
        lappend vars node $node
    }

    ::xmpp::sendIQ [lindex [connections] 0] get \
        -query [::xmpp::xml::create query \
                        -xmlns $::NS(stats) \
                        -attrs $vars \
                        -subelement [::xmpp::xml::create stat \
                                            -attrs [list name $name]]] \
        -to $jid \
        -command [list [namespace current]::recv_values_result $jid $node]
}

proc stats::recv_values_result {jid node res child} {
    variable data

    if {$res ne "ok"} {
        return
    }

    open_window

    ::xmpp::xml::split $child tag xmlns attrs cdata subels

    foreach item $subels {
        ::xmpp::xml::split $item stag sxmlns sattrs scdata ssubels

        if {$stag == "stat"} {
            set name  [::xmpp::xml::getAttr $sattrs name]
            set value [::xmpp::xml::getAttr $sattrs value]
            set units [::xmpp::xml::getAttr $sattrs units]

            foreach sitem $ssubels {
                ::xmpp::xml::split $sitem sstag ssxmlns ssattrs sscdata sssubels
                if {$sstag == "error"} {
                    set error [error_to_string \
                                   [list [::xmpp::xml::getAttr $ssattrs code] \
                                         $sscdata]]
                    break
                }
            }

            if {[info exists error]} {
                set data(value,$jid,$node,$name) $error
                set data(units,$jid,$node,$name) error
            } else {
                set data(value,$jid,$node,$name) $value
                set data(units,$jid,$node,$name) $units
            }
        }
    }
}


proc stats::remove_line {n} {
    variable f

    foreach slave [grid slaves $f -row $n] {
        destroy $slave
    }
}

proc stats::unset_timer {n jid node name args} {
    variable data
    variable f

    if {[info exists data(period,$jid,$node,$name)]} {
        unset data(period,$jid,$node,$name)
        $f.bsettimer$n configure -relief raised
    }
}

proc stats::toggle_timer {n jid node name} {
    variable data
    variable f

    if {![info exists data(period,$jid,$node,$name)]} {
        if {[string is integer -strict $data(tmpperiod,$jid,$node,$name)] && \
                $data(tmpperiod,$jid,$node,$name) > 0} {
            set data(period,$jid,$node,$name) $data(tmpperiod,$jid,$node,$name)
            $f.bsettimer$n configure -relief sunken

            timer $n $jid $node $name
        }
    } else {
        unset data(period,$jid,$node,$name)
        $f.bsettimer$n configure -relief raised
    }
}

proc stats::timer {n jid node name} {
    variable data
    variable f

    if {![winfo exists $f.spin$n]} return

    request_value $jid $node $name

    if {![info exists data(period,$jid,$node,$name)]} return

    set p $data(period,$jid,$node,$name)

    after cancel \
        [list [namespace current]::timer $n $jid $node $name]
    if {$p > 0 && [winfo exists $f.spin$n]} {
        after [expr {$p * 1000}] \
            [list [namespace current]::timer $n $jid $node $name]
    }
}



proc stats::setup_menu {} {
    catch {
        set m [.mainframe getmenu admin]

        $m add command -label [::msgcat::mc "Open statistics monitor"] \
            -command [namespace current]::open_window
    }
}
hook::add finload_hook [namespace current]::stats::setup_menu

stats::setup_menu


hook::add postload_hook \
    [list disco::browser::register_feature_handler $::NS(stats) \
         [namespace current]::stats::query_list -node 1 \
          -desc [list * [::msgcat::mc "Service statistics"]]]

# vim:ft=tcl:ts=8:sw=4:sts=4:et
