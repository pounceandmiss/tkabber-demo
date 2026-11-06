# TeopeTuK config file for Tkabber

# Loading X resources
option readfile $configdir/teopetuk.xrdb userDefault
#option readfile $configdir/light.xrdb userDefault

# Loading non-raising buttons
#source $configdir/button.tcl

# Setting Balloon style
option add *Balloon.style delay userDefault

# Set message locale explicitly
#msgcat::mclocale ru

#set font "-monotype-arial unicode-medium-r-*-*-14-*-90-100-*-*-iso10646-1"
set font "-monotype-arial-medium-r-*-*-13-*-100-100-*-*-iso10646-1"
set usetabbar 1
set autologin 0
set ssj::options(sign-traffic) 0
set ssj::options(encrypt-traffic) 0
set pixmaps_theme gabber
#set pixmaps_theme psi

# Login settings, common for all profiles
set loginconf(usedigest) 1
set loginconf(httpproxy) sun
set loginconf(httpproxyport) 3128
set loginconf(priority) 0

# Every 10 minutes send empty message to the server
# to avoid proxy disconnect
set keep_alive 1
set keep_alive_interval 10

# Login profiles setup
set loginconf1(profile)  "teopetuk@jabber.ru"
set loginconf1(user)     teopetuk
set loginconf1(password) ""
set loginconf1(server)   jabber.ru
set loginconf1(resource) tkabber
set loginconf1(usealtserver)       0
set loginconf1(altserver)       ""
set loginconf1(useproxy) 1

set loginconf2(profile)  "teopetuk@amessage.info"
set loginconf2(user)     teopetuk
set loginconf2(password) ""
set loginconf2(server)   amessage.info
set loginconf2(resource) tkabber
set loginconf2(usealtserver)       0
set loginconf2(altserver)       ""
set loginconf2(useproxy) 1

# Set default profile
array set loginconf [array get loginconf2]

# Set default conference nicks
set defaultnick(talks@conference.jabber.ru) teo
set defaultnick(debian@conference.jabber.ru) teo
#set defaultnick(talks@conference.jabber.ru) "\u0473\u0463\u0461"
#set defaultnick(talks@conference.jupiter.golovan.ru) "\u0473\u0463\u0461"
#set defaultnick(talks@conference.jupiter.golovan.ru) "\u03c4\u03b5\u03bf"

# Check spelling using ispell module
set use_ispell 1

# Set procedure for launching browser
proc browseurl {url} {
    exec galeon -w $url &
}

proc postload {} {

# Set initial roster options
    set roster::show_only_online 1
    set roster::show_transport_icons 1
    set roster::show_transport_user_icons 1
    set roster::roster(collapsed,Agents) 1
    #set roster::aliases(teopetuk@amessage.info) {258151@aim.jabber.ru}
    #set roster::aliases(teo@jupiter.golovan.ru) {petr@golovan.ru}
    #set roster::use_aliases 0

# Set search behaviour
    set search::show_all 1

# Set sound module options
    set sound::options(sound) 1
    set sound::options(theme) "$::configdir/sounds"
    set sound::options(external_play_program) "esdplay"

# Set autoaway module options
    set plugins::autoaway::options(awaytime) [expr 5*60*1000]
    set plugins::autoaway::options(xatime) [expr 15*60*1000]

# Set ispell module options
    set plugins::ispell::options(dictionary) engrus
    set plugins::ispell::options(dictionary_encoding) koi8-r

# Define the set of emoticons (empty set)
    set plugins::emoticons::options(theme) ""
}

# Debug window handling (mostly taken from MTR config file)
#set debug_lvls [list presence ssj warning]
set debug_lvls [list jlib plugins]
set debug_winP 0

proc menuload {menudesc} {
    set newmenu [lindex $menudesc end]
    lappend newmenu \
            [list checkbutton "Debug window" {} {} {} \
                              -variable debug_winP \
                              -command debug_window_update]
    lappend newmenu [list cascad Debug {} {} 1 [debug_buttons]]
    return [lreplace $menudesc end end $newmenu]
}

proc debug_buttons {} {
    global debug_levels debug_lvls

    set buttons {}
    foreach l [list avatar       browser      chat         completion   \
                    conference   filetransfer filters      iq           \
                    jlib         logger       login        message      \
                    nick         plugins      presence     register     \
                    roster       search       ssj          tkabber      \
                    userinfo     warning] {
        if {[lsearch -exact $debug_lvls $l] >= 0} {
            set debug_levels($l) 1
        } else {
            set debug_levels($l) 0
        }

        lappend buttons [list checkbutton $l {} {} {} \
                              -variable debug_levels($l) -command debug_update]
    }

    return $buttons
}

proc debug_window_update {} {
    global w debug_winP usetabbar
    if {!$debug_winP && [winfo exists $w.debug]} {
        if {$usetabbar} {
            foreach tab [.nb pages] {
                if {[lsearch -exact [pack slaves [.nb getframe $tab]] \
                                    $w.debug] >= 0} {
                    eval destroy [pack slaves [.nb getframe $tab]]
                    .nb delete $tab 1
                    tab_move .nb 0
                }
            }
        } else {
            destroy $w.debug
        }
    }
}

proc debug_update {} {
    global debug_levels debug_lvls

    set debug_lvls {}
    foreach {k v} [array get debug_levels] {
        if {$v} {
            lappend debug_lvls $k
        }
    }
}

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
        add_win $dw -title Debug -tabtitle debug

        [ScrolledWindow $dw.sw] setwidget \
            [text $dw.body -yscrollcommand [list $dw.scroll set]]

        pack $dw.sw -side bottom -fill both -expand yes

        $dw.body tag configure module -foreground red3
        $dw.body tag configure proc  -foreground blue
        $dw.body tag configure error -foreground red
    }

    $dw.body insert end [format "%s: %-12.12s" \
                            [clock format [clock seconds] -format "%m/%d %T"] \
                            $module] module " "
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
    $dw.body insert end "\n\n"
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
