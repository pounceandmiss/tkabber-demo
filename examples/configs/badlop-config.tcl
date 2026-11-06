# Badlop's config file for Tkabber 20031201
#  - based on MTR and TeopeTuK config files (available on 'examples/'
#    directory)
#  - includes references to Tkabber documentation (available on 'doc/'
#    directory)
#  - contributions:
#     Marcansoft for Linux options
# Report any error or suggestion to badlop@ono.com


# Configuration ------------------------------------------------------- PRELOAD

# 2. Configuration

# 2.1 Pre-load

# 2.1.1 Tabbed Interface

#    set usetabbar 1

# 2.1.2 Primary Look-and-Feel

    set pixmaps_theme gush

    set load_default_xrdb 0
    option readfile $rootdir/examples/xrdb/badlop-dark.xrdb userDefault

#    option add *font fixed userDefault
    switch -- [winfo screenwidth .]x[winfo screenheight .] {
        1400x1050
            -
        1280x1024 {
            option add Tkabber.geometry =788x550-0+0 userDefault
        }
        1024x768 {
            option add Tkabber.geometry =700x520-30+170 userDefault

            # sets font of most of labels in widgets,
            option add *font \
                   -monotype-arial-medium-r-*-*-11-*-100-100-*-*-iso10646-1

            # sets font of chat and roster text
            set font -monotype-arial-medium-r-*-*-11-*-100-100-*-*-iso10646-1
        }
        800x600 {
            option add Tkabber.geometry =600x420-30+100 userDefault

            # sets font of most of labels in widgets,
            option add *font \
                   -monotype-arial-medium-r-*-*-9-*-100-100-*-*-iso10646-1

            # sets font of chat and roster text
            set font -monotype-arial-medium-r-*-*-9-*-100-100-*-*-iso10646-1
        }
        default {
            #option add Tkabber.geometry =630x412-0+0 userDefault
        }
    }



# 2.1.3 Cryptography by default

#    set ssj::options(one-passphrase)  1
#    set ssj::options(sign-traffic)    1
#    set ssj::options(encrypt-traffic) 1

# 2.1.4 Using of external TclXML library

#    set use_external_tclxml           1

# 2.1.5 Use ispell to check spelling

#    set use_ispell 1

# 2.1.6 Debugging Output

#    set debug_lvls     {jlib warning}
#    set debug_lvls     [list message presence ssj warning]
#    set debug_lvls     [list zerobot]
#    set debug_lvls     [list jlib plugins]
#    set debug_winP     0

# 2.1.7 Splash window

#    set show_splash_window 1

# 2.1.8 Periodically send empty string to server

#    set keep_alive           0
#    set keep_alive_interval 10

# 2.1.9 I18n/L10n

#    ::msgcat::mclocale es

# Other non documented:

# Remove the four button bar at the top of the roster

#    hook::add finload_hook {.mainframe showtoolbar 0 0}

# Define here the route to your prefered web browser
#   if {$tcl_platform(platform) == "unix"} {
#       # Linux users
#       proc browseurl {url} {
#           exec mozilla $url &}
#   } else {
#       # Windows users
#       proc browseurl {url} {
#           exec "c:/Mozilla/MozillaFirebird.exe" $url &
#       }
#   }

#   global BROWSER
#   if {$tcl_platform(platform) == "unix"} {
#       # Linux users
#       set ::BROWSER mozilla
#   } else {
#       # Windows users
#       set ::BROWSER explorer
#   }
#   proc browseurl {url} {
#       exec $::BROWSER $url &
#   }

    # show SSL warnings
#   set ::tls_warnings 0

# Join groupchats automatically at the start
#proc connload {connid} {
#       muc::join_group $connid jabber@conference.jabber.org badlop }
#hook::add connected_hook connload 1000


# 2.2 Post-load ------------------------------------------------------ POSTLOAD
proc postload {} {

# 2.2.1 Look-and-Feel

#    set raise_new_tab 0

# 2.2.2 The Autoaway Module

#    set plugins::autoaway::options(awaytime) [expr  2*60*1000]
#    set plugins::autoaway::options(xatime)   [expr 15*60*1000]
#    set plugins::autoaway::options(status)   "Idle"
#    set plugins::autoaway::options(drop_priority) 0

# 2.2.3 The Avatar Module

#   if {[file exists  $configdir/avatar.gif]} {
#       avatar::load_file $configdir/avatar.gif
#   } else {
#       avatar::load_file $::rootdir/pixmaps/default/tkabber/mainlogo.gif
#   }
#   set avatar::options(announce)   1
#   set avatar::options(share)      1

# 2.2.4 The Chat Module (chat, normal)

#   set chat::options(stop_scroll)                0
#   set chat::options(smart_scroll)               1
#   set chat::options(display_status_description) 1

# Examples:
#  [%R] -- [20:37]
#  [%T] -- [20:37:12]
#  [%a %b %d %H:%M:%S %Z %Y] -- [Thu Jan 01 03:00:00 MSK 1970]

#    set plugins::options(timestamp_format)  {[%R]}

# 2.2.5 The Clientinfo Module

#    set plugins::clientinfo::options(autoask) 1

# 2.2.6 The Conferenceinfo Module

#    set plugins::conferenceinfo::options(autoask)         1
#    set plugins::conferenceinfo::options(interval)      300
#    set plugins::conferenceinfo::options(err_interval) 3600

# 2.2.7 The Cryptographic Module

#    set ssj::options(encrypt,fred@example.com) 1

# 2.2.8 The Emoticons Module

#   plugins::emoticons::load_dir $::rootdir/emoticons/rhymbox-1.0

# 2.2.9 The File Transfer Module

#   if {$::tcl_platform(platform) == "unix"} {
        # Linux users
#       set ft::options(download_dir) "$env(HOME)"
#   } else {
        # Windows users
#       set ft::options(download_dir) "c:/"
#   }

# 2.2.10 The Groupchat Module

#    global gra_group gra_server
#    global gr_nick gr_group gr_server gr_v2
#    global defaultnick

#    set defaultnick(talks@conference.jabber.org) teo

# 2.2.11 The Ispell Module

#   set plugins::ispell::options(executable)            ispell/bin/ispell.exe
#   set plugins::ispell::options(executable)            /usr/bin/ispell
#   set plugins::ispell::options(dictionary)            spanish
#   set plugins::ispell::options(check_every_symbol)    0
#   set plugins::ispell::options(dictionary_encoding)   koi8-r

# 2.2.12 The Jidlink Module

#    set jidlink::transport(allowed,dtcp-passive) 0

# 2.2.13 The Logger Module

#    set logger::options(logdir) $configdir/logs
#    set logger::options(log_chat)      1
#    set logger::options(log_groupchat) 1

# 2.2.14 The Login Module

    global loginconf autologin loginconf1 loginconf2

    # Jabber account:
    set loginconf1(profile)      Default
#    set loginconf1(user)         ++++++++
#    set loginconf1(password)     ++++++++
#    set loginconf1(server)       ++++++++

    # Other Jabber account:
    set loginconf2(profile)      Secondary
#    set loginconf2(user)         --------
#    set loginconf2(password)     --------
#    set loginconf2(server)       --------

#    set loginconf(usedigest)     1
#    set loginconf(resource)      TkabberP
#    set loginconf(port)          5222
#    set loginconf(priority)      3
#    set loginconf(usessl)        0
#    set loginconf(sslport)       5223
#    set loginconf(useproxy)      0
#    set loginconf(httpproxy)     localhost
#    set loginconf(httpproxyport) 3128
#    set loginconf(replace_opened) 0

#    array set loginconf          [array get loginconf1]

    set autologin 0

# 2.2.15 The Message Module

#    set message::options(headlines,cache)    1
#    set message::options(headlines,multiple) 1

# 2.2.16 The Raw XML Input Module

#    set plugins::rawxml::options(pretty_print) 1
#    set plugins::rawxml::options(indent)       2

# 2.2.17 The Roster Module

#    set roster::show_only_online              1
#    set roster::show_transport_icons          1
#    set roster::show_transport_user_icons     1

#    set roster::roster(collapsed,Transports)  1
#    set roster::roster(collapsed,Conferences) 1
#    set roster::roster(collapsed,Undefined)   1

#   set roster::options(show_subscription) 1
#   set roster::options(show_conference_user_info) 1

#   set roster::use_aliases 0
#   set roster::aliases(perico@servidor.org) \
#       {perico@servidor2.com}

# 2.2.18 The Sound Module

#    set sound::options(sound)                  1
#    set sound::options(mute)                   0
#    set sound::options(mute_groupchat_delayed) 1
#    set sound::options(mute_chat_delayed)      1
#    set sound::options(delay)                  200
    set sound::options(theme)                   "psi"

#   if {$::tcl_platform(platform) == "unix"} {
    # Linux users
        # If no sound is available, use one of the following:
        #set sound::options(external_play_program) /usr/bin/play
        #set sound::options(external_play_program) artsplay
#   } else {
    # Windows users
#       set sound::options(external_play_program) plwav.exe
#   }

# Others non documented:

# .. The XHTML Module

#    set plugins::xhtml::options(enable)    1

#    plugins::emoticons::load_dir $configdir/cool-emoticon-theme

# Set theme for chess plugin

#    set plugins::chess::theme 1

# special key bindings (due to KDE)

    bind . <Alt-Left>      {ifacetk::tab_move .nb -1}
    bind . <Alt-Right>     {ifacetk::tab_move .nb 1}
    bind . <Alt-Up>        {ifacetk::current_tab_move .nb -1}
    bind . <Alt-Down>      {ifacetk::current_tab_move .nb  1}
    bind . <Alt-Key-w> {
        if {[.nb raise] != ""} {
            eval destroy [pack slaves [.nb getframe [.nb raise]]]
            .nb delete [.nb raise] 1
            ifacetk::tab_move .nb 0
        }
    }

    # Change presence indicator
    #bind . <Control-Key-Fx>      {set userstatus chat}
    bind . <Control-Key-F1>      {set userstatus available}
    #bind . <Control-Key-Fx>      {set userstatus away}
    bind . <Control-Key-F2>      {set userstatus xa}
    bind . <Control-Key-F3>      {set userstatus dnd}
    #bind . <Control-Key-Fx>      {set userstatus invisible}


# Set search behaviour
#    set search::show_all 1


# Georoster plugin

# MTR's config file for tkabber

# If you want to use Georoster, uncomment the lines that start with a '#'.
# The lines that start with '   #' are not necessary.

#    source $configdir/tkabber-plugins/georoster/georoster.tcl

    # automatically open GeoRoster window
#    set georoster::options(automatic) 0

    # show cities on map (none, markers, or all)
#    set georoster::options(showcities) all

    # file defining city names & locations, localized for XX
    #set georoster::options(citiesfile) \
    #    $configdir/tkabber-plugins/georoster/earth.XX

    # file defining ISO 3166 country codes
    #set georoster::options(3166file) iso3166

    # default country to use, if unspecified in vCard
    #set georoster::options(default_country) us

    # file defining region/locality names & locations, for country XX
    #set georoster::options(coords,XX) \
    #    $configdir/tkabber-plugins/georoster/XX.coords

    # file containing gif to use as background for map
    #set georoster::options(mapfile) \
    #    $configdir/tkabber-plugins/georoster/colormap.jpg

    # procedures to map from x/y to lo/la, and back again
    #proc georoster::lo {x  y}
    #proc georoster::la {x  y}
    #proc georoster::x  {lo la}
    #proc georoster::y  {lo la}

    # hook to locate a given jid:

    #proc XX {jid update} {
    #    if {$success} {
    #        eval $update [list $la $lo]
    #        return stop
    #    }
    #}

    #hook::add georoster:locate_hook [namespace current]::XX
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
