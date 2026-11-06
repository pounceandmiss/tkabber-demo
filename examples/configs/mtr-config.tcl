# MTR's config file for tkabber (now with Aqua support!)


set ssj::options(one-passphrase)  1
set ssj::options(sign-traffic)    1
set ssj::options(encrypt-traffic) 1

set use_ispell                    1

set debug_lvls                    [list zerobot]
set debug_winP                    1

set show_splash_window            1

proc debugmsg {module msg} {
    global debug_lvls w
    global debug_fd debug_winP

    if {![info exists debug_fd]} {
        catch { file rename -force -- $::configdir/tkabber.log \
                                      $::configdir/tkabber0.log }
        set debug_fd [open $::configdir/tkabber.log \
                           { WRONLY CREAT TRUNC APPEND }]
        fconfigure $debug_fd -buffering line
    }

    puts $debug_fd [format "%s %-12.12s %s" \
                           [clock format [clock seconds] -format "%m/%d %T"] \
                           $module $msg]

    if {([lsearch -exact $debug_lvls $module] < 0) || (!$debug_winP)} {
        return
    }

    set dw $w.debug

    if {![winfo exists $dw]} {
        add_win $dw -title Debug -tabtitle debug -class Chat

        [ScrolledWindow $dw.sw] setwidget \
            [text $dw.body -yscrollcommand [list $dw.scroll set]]

        pack $dw.sw -side bottom -fill both -expand yes

        $dw.body tag configure module \
            -foreground [option get $dw theyforeground Chat]
        $dw.body tag configure proc   \
            -foreground [option get $dw meforeground Chat]
        $dw.body tag configure error  \
            -foreground [option get $dw errforeground Chat]
    }

    $dw.body insert end [format "%-12.12s" $module] module " "
    set tag normal
    switch -- $module {
        jlib {
            if {[set x [string first "(jlib::" $msg]] > 0} {
                set tag error
            }
            if {[set y [string first ")" $msg]] > 0} {
                $dw.body insert end \
                         [string range $msg [expr $x+7] [expr $y-1]] proc \
                         "\n"
                set msg [string trimleft \
                                [string range $msg [expr $y+1] end]]
            }
        }

        default {
        }
    }
    $dw.body insert end [string trimright $msg] $tag
    $dw.body insert end "\n"

    if {!$::chat::options(stop_scroll)} {
        $dw.body see end
    }
}

if {$aquaP} {
    set load_default_xrdb 1
    set font {Monoco 12 normal}
    option add *font $font userDefault
} else {
    set load_default_xrdb 0
    option readfile $configdir/../src/tkabber/tkabber/examples/ice.xrdb userDefault
    option add *font fixed userDefault
}

switch -- [winfo screenwidth .]x[winfo screenheight .] {
    1440x900
        -
    1440x879 {
        option add Tkabber.geometry =710x481+730+21 userDefault
    }

    1400x1050
        -
    1280x1024 {
        option add Tkabber.geometry =788x550-0+0 userDefault
    }

    1024x768
        -
    default {
        option add Tkabber.geometry =630x412-0+0 userDefault
    }
}


proc config_postload {} {
# the emoticon module

    plugins::emoticons::load_dir $::configdir/emoticons/rythmbox


# the georoster module

    source $::configdir/../src/tkabber/tkabber-plugins/georoster/georoster.tcl
#   source $::configdir/proprietary/georoster-prop.tcl

    namespace eval georoster {
        variable mapnum 1
        variable mapwidth
        variable mapheight
        variable options

        set options(showcities)  none

        switch -- [winfo screenwidth .]x[winfo screenheight .] {
            1440x900 {
                set mapwidth  812
                set mapheight 422
            }

            1400x1050
                -
            1280x1024 {
                set mapwidth  975
                set mapheight 506
            }

            1024x768
                -
            default {
                set mapwidth  650
                set mapheight 338

                set options(mapfile) \
                    $::configdir/../src/tkabber/tkabber-plugins/georoster/bwmap4.gif

                proc lo {x y} {expr {($x*2 - 649)*18/65 + 10}}
                proc la {x y} {expr {(371 - $y*2)*9/40}}

                proc x {lo la} {expr {(649+(($lo-10)*65/18))/2}}
                proc y {lo la} {expr {(371-($la * 40/9))/2}}
            }
        }


        variable M_PI       3.14159265358979323846
        variable M_PI_2     [expr $M_PI/2.0]
        variable deg_to_rad [expr $M_PI/180.0]
        variable TWO_PI     [expr $M_PI*2.0]
        variable M_DEG      [expr 180/$M_PI]
        variable M_INVDEG   [expr $M_PI/180]

        variable del_lon    [expr $TWO_PI/$mapwidth]
        variable del_lat    [expr $M_PI/$mapheight]

        variable lon_array
        for {set i 0} {$i < $mapwidth} {incr i} {
            set lon_array($i) [expr (($i+0.5)*$del_lon-$M_PI)]
        }

        variable lat_array
        for {set i 0} {$i < $mapheight} {incr i} {
            set lat_array($i) [expr ($M_PI_2 - ($i+0.5)*$del_lat)]
        }

        proc sp2px {lo la} {
            variable M_PI
            variable M_PI_2
            variable TWO_PI
            variable del_lon
            variable del_lat
            variable mapwidth
            variable mapheight

            if {$lo > $M_PI} {
                set lo [expr $lo-$TWO_PI]
            } elseif {$lo < -$M_PI} {
                set lo [expr $lo+$TWO_PI]
            }

            set x [expr round(($lo+$M_PI)/$del_lon + 0.5)]
            if {$x >= $mapwidth} {
                incr x -$mapwidth
            } elseif {$x < 0} {
                incr x $mapwidth
            }

            set y [expr round(($M_PI_2-$la)/$del_lat + 0.5)]
            if {$y >= $mapheight} {
                set y [expr $mapheight-1]
            }

            return [list $x $y]
        }

        proc refresh {} {
            variable mapcmd
            variable mapnum
            variable mapwidth
            variable mapheight

            if {![winfo exists .georoster.c]} {
                return [after [expr 60*1000] [namespace current]::refresh]
            }

            set file [file join $::configdir georoster_${mapnum}.gif]
            if {[catch { exec xplanet -geometry =${mapwidth}x${mapheight} \
                                      -projection rectangular \
                                      -num_times 1 \
                                      -output $file & } result]} {
                set_status "unable to create new georoster image: $result"
            } else {
                after [expr 60*1000] \
                      [list [namespace current]::refresh_aux $file]
            }
        }

        proc refresh_aux {file} {
            variable mapimage

            image delete $mapimage
            set mapimage [image create photo -file $file]
            catch { file delete -- $file }

            [set c .georoster.c] delete map
            $c create image 0 0 -image $mapimage -anchor nw -tag map
            $c configure -scrollregion [list 0 0 [image width $mapimage] \
                                                 [image height $mapimage]]

            proc x {lo la} {
                variable M_INVDEG

                lindex [sp2px [expr $lo*$M_INVDEG] [expr $la*$M_INVDEG]] 0
            }

            proc y {lo la} {
                variable M_INVDEG

                lindex [sp2px [expr $lo*$M_INVDEG] [expr $la*$M_INVDEG]] 1
            }

            proc lo {x y} {
                variable lon_array
                variable M_DEG

                if {[set x [expr int($x)]] < 0} {
                    set x 0
                } elseif {![info exists lon_array($x)]} {
                    return 180
                }
                return [expr $lon_array($x)*$M_DEG]
            }

            proc la {x y} {
                variable lat_array
                variable M_DEG

                if {[set y [expr int($y)]] < 0} {
                    set y 0
                } elseif {![info exists lat_array($x)]} {
                    return -90
                }
                return [expr $lat_array($y)*$M_DEG]
            }

            redraw $c

            after [expr 10*60*1000] [list [namespace current]::refresh]
        }
    }


# special key bindings (due to KDE)

    bind . <Alt-Left>      {ifacetk::tab_move .nb -1}
    bind . <Alt-Right>     {ifacetk::tab_move .nb  1}
    bind . <Control-Left>  {ifacetk::current_tab_move .nb -1}
    bind . <Control-Right> {ifacetk::current_tab_move .nb  1}
    bind . <Control-w> {
        if {[.nb raise] != ""} {
            eval destroy [pack slaves [.nb getframe [.nb raise]]]
            .nb delete [.nb raise] 1
            ifacetk::tab_move .nb 0
        }
    }
}

hook::add postload_hook config_postload 9


proc roster_user_popup_info {info connid user} {
    set text [set $info]
    if {([set x [string first "(" $text]] > 0) \
            && ([string compare [string index $text end] ")"] == 0) \
            && ([string first "\n" [string range $text $x end]] > 0)} {
        set start [string range $text 0 [expr $x-1]]
        if {[set y [string last ":" $start]] > 0} {
            set start [string range $start 0 [expr $y-1]]
        }
        set $info $start
        append $info "\n    "
        append $info [string map [list "\n" "\n    "] \
                             [string range $text [expr $x+1] end-1]]
    }
}

hook::add roster_user_popup_info_hook \
          [namespace current]::roster_user_popup_info 1


namespace eval jbot {
    proc open_chat_post {chatid type} {
        global usetabbar

        if {[string equal [chat::get_nick [chat::get_xlib $chatid] \
                                         [chat::get_jid $chatid] $type]/$type \
                    jbot/chat]} {
            set cw [chat::winid $chatid]
            pack forget $cw.csw
            pack $cw.csw -expand yes -fill both -side left
            destroy $cw.status $cw.input $cw.pw0
            if {$usetabbar} {
                .nb itemconfigure [string range [win_id tab $cw] 1 end] \
                    -text jbot \
                    -raisecmd [list hook::run raise_chat_tab_hook $cw $chatid]
            }

            return stop
        }
    }

    proc draw_message {chatid from type body x} {
        if {[string equal [chat::get_nick [chat::get_xlib $chatid] \
                                          $from $type]/$type jbot/chat]} {
            set cw [chat::chat_win $chatid]
            foreach line [split [string trimright $body] "\n"] {
                if {[string equal [string index $line 15] " "]} {
                    $cw insert end [string range $line 0 15] me
                    set line [string range $line 16 end]
                    if {([set d [string first " " $line]] > 0) \
                            && (([string first ": " $line] > $d)
                                    || ([string first "last message repeated" \
                                                $line] > $d))} {
                        $cw insert end [string range $line 0 $d] they
                        set line [string range $line [expr $d+1] end]
                    }
                }
                if {[set d [string first ": " $line]] > 0} {
                    $cw insert end [string range $line 0 $d] me
                    set line [string range $line [expr $d+1] end]
                }
                $cw insert end "$line\n" ""
            }

            return stop
        }
    }

    proc normalize_chat_id \
         {vconnid vfrom vid vtype vis_subject vsubject
          vbody verr vthread vpriority vx} {
        upvar 2 $vconnid connid
        upvar 2 $vfrom from
        upvar 2 $vtype type

        if {![string equal $type chat]} return

        if {[string equal [chat::get_nick $connid $from $type] jbot]} {
            set from [::xmpp::jid::replaceResource $from syslog]
        }
    }

    hook::add open_chat_post_hook  [namespace current]::open_chat_post     1
    hook::add draw_message_hook    [namespace current]::draw_message       1
    hook::add rewrite_message_hook [namespace current]::normalize_chat_id  1
}


hook::add finload_hook georoster::refresh 100


proc config_connload {connid} {
    return

    foreach g [list xmpp] {
        muc::join_group $connid ${g}@ietf.xmpp.org mrose
    }
    muc::join_group $connid wgchairs@conference.psg.com mrose
}

hook::add connected_hook config_connload 1000


if {![catch { package require tclCarbonNotification }]} {
    proc config_tab_set_updated {path updated level} {
        switch -- $level {
            message {
                switch -glob -- $path {
                    .chat_*_jbot*
                        -
                    .headlines_* {
                    }

                    default {
                        tclCarbonNotification 1 ""
                    }
                }
            }

            mesg_to_user {
                tclCarbonNotification 1 ""
            }

            default {
            }
        }
    }

    hook::add tab_set_updated config_tab_set_updated 10
}



if {(![file exists [set file .jsendrc.tcl]]) \
        && (![file exists [set file $configdir/../.jsendrc.tcl]])} {
    return
}
source $file

namespace eval zerobot {
    proc examine_message {connid from id type is_subject subject
                          body err thread priority x} {
        global userstatus

        switch -- $userstatus {
            away
                -
            xa {
                if {([string length [set body [checkP $from $type $subject \
                                                     $body $x]]] > 0) \
                        && ([catch { notify $from $body } result])} {
                    debugmsg zerobot "notify: $result"
                }
            }

            default {
                reset
            }
        }
    }

    hook::add process_message_hook   [namespace current]::examine_message   10
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
