# iface.tcl --
#
#       This file is a part of the Tkabber XMPP client. It creates the main
#       Tkabber window.

namespace eval ifacetk {
    variable options

    custom::defgroup IFace \
        [::msgcat::mc "Options for main interface."] \
        -group Tkabber -tag "Main Interface"

    custom::defvar options(use_tabbar) 1 \
        [::msgcat::mc \
             "Use Tabbed Interface (you need to restart)."] \
        -group IFace -type boolean

    custom::defvar options(tabs_side) top \
        [::msgcat::mc "Side where to place tabs in tabbed mode."] \
        -group IFace -type options \
        -values [list top    [::msgcat::mc "Top"] \
                      bottom [::msgcat::mc "Bottom"] \
                      left   [::msgcat::mc "Left"] \
                      right  [::msgcat::mc "Right"]] \
        -command [namespace current]::configure_tabs

    custom::defvar options(tab_minwidth) [winfo pixels . 25m] \
        [::msgcat::mc "Minimum width of tab buttons in tabbed mode."] \
        -group IFace -type integer \
        -command [namespace current]::configure_tabs

    custom::defvar options(tab_maxwidth) [winfo pixels . 30m] \
        [::msgcat::mc "Maximum width of tab buttons in tabbed mode."] \
        -group IFace -type integer \
        -command [namespace current]::configure_tabs

    custom::defvar options(show_toolbar) 1 \
        [::msgcat::mc "Show Toolbar."] \
        -group IFace -type boolean \
        -command [namespace current]::switch_toolbar

    custom::defvar options(show_presencebar) 1 \
        [::msgcat::mc "Show presence bar."] \
        -group IFace -type boolean \
        -command [namespace current]::switch_presencebar

    custom::defvar options(show_statusbar) 1 \
        [::msgcat::mc "Show status bar."] \
        -group IFace -type boolean \
        -command [namespace current]::switch_statusbar

    if {!$::XLFDFonts} {
        custom::defvar options(font) $::default_Chat_font \
            [::msgcat::mc "Font to use in chat windows."] \
            -group IFace -type font \
            -command [list [namespace current]::switch_font font Chat]

        custom::defvar options(roster_font) $::default_Roster_font \
            [::msgcat::mc "Font to use in roster windows."] \
            -group IFace -type font \
            -command [list [namespace current]::switch_font roster_font Roster]
    }

    custom::defvar options(raise_new_tab) 1 \
        [::msgcat::mc "Raise new tab."] \
        -group IFace -type boolean

    custom::defvar options(message_numbers_in_tabs) 1 \
        [::msgcat::mc "Show number of unread messages in tab titles."] \
        -group IFace -type boolean

    custom::defvar options(only_personal_messages_in_window_title) 0 \
        [::msgcat::mc "Show only the number of personal unread messages\
                       in window title."] \
        -group IFace -type boolean

    custom::defvar options(update_title_delay) 600 \
        [::msgcat::mc "Delay between getting focus and updating window or\
                       tab title in milliseconds."] \
        -group IFace -type integer

    custom::defvar options(show_tearoffs) 1 \
        [::msgcat::mc "Show menu tearoffs when possible."] \
        -group IFace -type boolean

    custom::defvar options(closebuttonaction) close \
        [::msgcat::mc "What action does the close button."] \
        -group IFace -type options \
        -values [list \
                     close    [::msgcat::mc "Close Tkabber"] \
                     nothing  [::msgcat::mc "Do nothing"] \
                     minimize [::msgcat::mc "Minimize"] \
                     iconize  [::msgcat::mc "Iconize"] \
                     systray  [::msgcat::mc "Minimize to systray (if systray\
                                             icon is enabled, otherwise do\
                                             nothing)"] \
                    ]

    custom::defvar status_history [list] \
            [::msgcat::mc "History of availability status messages"] \
            -type string \
            -group Hidden

    custom::defvar options(max_status_history) 10 \
            [::msgcat::mc "Maximum number of status messages to keep.\
                    If the history size reaches this threshold,\
                    the oldest message will be deleted automatically\
                    when a new one is recorded."] \
            -type integer -group IFace

    proc isource {file} {
        set dir [file dirname [info script]]
        source [file join $dir $file]
    }

    isource login.tcl
    isource roster.tcl
    isource systray.tcl
    isource muc.tcl

    variable after_focused_id ""

    variable number_msg
    variable personal_msg

    namespace export raise_win add_win destroy_win tab_set_updated
}

source [file join [file dirname [info script]] buttonbar.tcl]

proc ifacetk::configure_tabs {args} {
    variable options
    global usetabbar
    variable tabs

    if {$usetabbar} {
        if {[string is integer -strict $options(tab_minwidth)] && \
                $options(tab_minwidth) >= 0} {
            set minwidth $options(tab_minwidth)
        } else {
            set minwidth [winfo pixels . 25m]
        }
        if {[string is integer -strict $options(tab_maxwidth)] && \
                $options(tab_maxwidth) >= 0} {
            set maxwidth $options(tab_maxwidth)
        } else {
            set maxwidth [winfo pixels . 25m]
        }

        switch -- $options(tabs_side) {
            bottom {
                set row 2
                set col 1
                set orient horizontal
            }
            left {
                set row 1
                set col 0
                set orient vertical
            }
            right {
                set row 1
                set col 2
                set orient vertical
            }
            default {
                set row 0
                set col 1
                set orient horizontal
            }
        }
        grid .nb -row $row -column $col -sticky nswe -in $tabs
        .nb configure -minwidth $minwidth -maxwidth $maxwidth -orient $orient
    }
}

if {$::darktheme} {
    option add *errorForeground coral3 widgetDefault
} else {
    option add *errorForeground red widgetDefault
}

wm protocol . WM_SAVE_YOURSELF session_checkpoint

wm protocol . WM_DELETE_WINDOW \
   [list [namespace current]::ifacetk::wm_delete_window]

proc ifacetk::wm_delete_window {} {
    variable options

    hook::run protocol_wm_delete_window_hook $options(closebuttonaction)
}

proc ifacetk::closebuttonproc {action} {
    variable options

    switch -- $action {
        nothing {}
        minimize {
            wm iconify .
        }
        iconize {
            wm iconify .
            wm state . withdrawn
        }
        close -
        default {
            quit
        }
    }
}

hook::add protocol_wm_delete_window_hook \
    [namespace current]::ifacetk::closebuttonproc

set xselection ""

proc EncodeTextSelection {txt offset len} {
    set elided ""
    if {"emphasized" in [$txt tag names] && \
            [$txt tag cget emphasized -elide]} {
        set elided emphasized
    } elseif {"nonemphasized" in [$txt tag names] && \
            [$txt tag cget nonemphasized -elide]} {
        set elided nonemphasized
    }
    if {$elided eq ""} {
        set sel [$txt tag ranges sel]
        if {[llength $sel] == 0} {
            set ::xselection ""
        } else {
            set ::xselection [$txt get {*}$sel]
        }
    } else {
        lassign [$txt tag ranges sel] selstart selstop
        set sel $selstart
        set ::xselection ""
        while {[set range [$txt tag nextrange $elided $sel $selstop]] ne ""} {
            append ::xselection [$txt get $sel [lindex $range 0]]
            set sel [lindex $range 1]
        }
        append ::xselection [$txt get $sel $selstop]
    }
    encoding convertto \
             [string range $::xselection $offset [expr {$offset + $len - 1}]]
}

proc EncodeEntrySelection {txt offset len} {
    if [$txt selection present] {
        set idx1 [$txt index sel.first]
        set idx2 [$txt index sel.last]
        set ::xselection [string range [$txt get] $idx1 $idx2]
        encoding convertto \
             [string range $::xselection $offset [expr {$offset + $len - 1}]]
    } else {
        set ::xselection ""
    }
}

if {$tcl_platform(platform) eq "unix"} {
    proc ::tk::GetSelection {w {sel PRIMARY}} {
        if {![catch {selection get -displayof $w \
                        -selection $sel -type UTF8_STRING} txt]} {
            return $txt
        } elseif {![catch {selection get -displayof $w -selection $sel} txt]} {
            if {[selection own] eq ""} {
                return [encoding convertfrom $txt]
            } else {
                return $::xselection
            }
        } else {
            return -code error "could not find default selection"
        }
    }

    bind Text  <Map> { selection handle %W "EncodeTextSelection %W" }
    bind Entry <Map> { selection handle %W "EncodeEntrySelection %W" }
}

proc ifacetk::load_descmenu {} {
    global descmenu
    variable options

    set descmenu \
        [list "&Tkabber" {} tkabber $options(show_tearoffs) \
             [list \
                  [list cascade [::msgcat::mc "Presence"] {} presence $options(show_tearoffs) \
                       [list \
                            [list command [::msgcat::mc "Available"] {} {} {} \
                                 -command {set userstatus available}] \
                            [list command [::msgcat::mc "Free to chat"] {} {} {} \
                                 -command {set userstatus chat}] \
                            [list command [::msgcat::mc "Away"] {} {} {} \
                                 -command {set userstatus away}] \
                            [list command [::msgcat::mc "Extended away"] {} {} {} \
                                 -command {set userstatus xa}] \
                            [list command [::msgcat::mc "Do not disturb"] {} {} {} \
                                 -command {set userstatus dnd}] \
                            {separator} \
                            [list command [::msgcat::mc "Change priority..."] {} {} {} \
                                 -command {change_priority_dialog}]]] \
                  [list command [::msgcat::mc "Log in..."] {} {} {Ctrl l} \
                       -command [list [namespace current]::login_dialog]] \
                  [list command [::msgcat::mc "Log out"] {} {} {Ctrl j} \
                       -command [list [namespace current]::logout_dialog]] \
                  [list command [::msgcat::mc "Log out with reason..."] {} {} {} \
                       -command {show_logout_dialog}] \
                  [list command [::msgcat::mc "Open login log"] {} {} {} \
                       -command {login_log_window}] \
                  {separator} \
                  [list command [::msgcat::mc "Change password..."] {} {} {} \
                       -command {::register::password [lindex [connections] 0]}] \
                  [list command [::msgcat::mc "Edit my info..."] {} {} {} \
                       -command {
                            if {[llength [connections]] > 0} {
                                set xlib [lindex [connections] 0]
                                userinfo::open $xlib [connection_bare_jid $xlib] \
                                               -editable 1 \
                            }}] \
                  [list cascade [::msgcat::mc "Privacy rules"] {} privacy $options(show_tearoffs) \
                       [list \
                            [list checkbutton [::msgcat::mc "Activate lists at startup"] {} {} {} \
                                 -variable ::privacy::options(activate_at_startup)] \
                            [list command [string trim [::msgcat::mc "Edit invisible list "]] {} {} {} \
                                 -command {privacy::edit_special_list "" invisible}] \
                            [list command [string trim [::msgcat::mc "Edit ignore list "]] {} {} {} \
                                 -command {privacy::edit_special_list "" ignore}] \
                            [list command [string trim [::msgcat::mc "Edit conference list "]] {} {} {} \
                                 -command {privacy::edit_special_list "" conference}] \
                            [list checkbutton [::msgcat::mc "Accept messages from roster users only"] {} {} {} \
                                 -variable ::privacy::accept_from_roster_only \
                                 -command {privacy::on_accept_from_roster_only_change ""}] \
                            {separator} \
                            [list command [::msgcat::mc "Manually edit rules"] {} {} {} \
                                 -command {privacy::request_lists ""}]]] \
                  {separator} \
                  [list cascade [::msgcat::mc "View"] {} {} $options(show_tearoffs) \
                   [list \
                     [list checkbutton [::msgcat::mc "Toolbar"] \
                          {} {} {} \
                          -variable [namespace current]::options(show_toolbar)] \
                     [list checkbutton [::msgcat::mc "Presence bar"] \
                          {} {} {} \
                          -variable [namespace current]::options(show_presencebar)] \
                     [list checkbutton [::msgcat::mc "Status bar"] \
                          {} {} {} \
                          -variable [namespace current]::options(show_statusbar)] \
                  ]] \
                  [list cascade [::msgcat::mc "Roster"] {} roster $options(show_tearoffs) \
                   [list \
                    [list checkbutton [::msgcat::mc "Show online users only"] \
                         {} {} {} \
                         -variable [namespace current]::roster::show_only_online] \
                    [list checkbutton [::msgcat::mc "Show own resources"] {} {} {} \
                         -variable [namespace current]::roster::options(show_own_resources)] \
                    [list checkbutton [::msgcat::mc "Use roster filter"] {} {} {} \
                         -variable [namespace current]::roster::options(use_filter)] \
                    [list checkbutton [::msgcat::mc "Enable metacontacts"] {} {} {} \
                         -variable [namespace current]::roster::options(enable_metacontacts)] \
                    [list command [::msgcat::mc "Add group by regexp on JIDs..."] {} {} {} \
                         -command [namespace current]::roster::add_group_by_jid_regexp_dialog] \
                  ]] \
                  [list cascade [::msgcat::mc "Chats"] {} chats $options(show_tearoffs) \
                   [list \
                    [list checkbutton [::msgcat::mc "Generate enter/exit messages"] {} {} {} \
                         -variable ::muc::options(gen_enter_exit_msgs)] \
                    [list checkbutton [::msgcat::mc "Smart autoscroll"] {} {} {} \
                         -variable ::chat::options(smart_scroll)] \
                    [list checkbutton [::msgcat::mc "Stop autoscroll"] {} {} {} \
                         -variable ::chat::options(stop_scroll)] \
                    [list checkbutton [::msgcat::mc "Emphasize"] {} {} {} \
                         -variable ::plugins::stylecodes::options(emphasize)] \
                    [list checkbutton [::msgcat::mc "Show emoticons"] {} {} {} \
                         -variable ::plugins::emoticons::options(show_emoticons)] \
                    {separator} \
                  ]] \
                  {separator} \
                  [list command [::msgcat::mc "Manage proxy servers"] {} {} {} \
                       -command {proxy::open}] \
                  [list command [::msgcat::mc "Customize"] {} {} {} \
                       -command {custom::open_window Tkabber}] \
                  {separator} \
                  [list command [::msgcat::mc "Quit"] {} {} {} \
                       -command {quit}] \
                 ] \
             [::msgcat::mc "&Services"] {} services $options(show_tearoffs) \
             [list \
                  [list command [::msgcat::mc "Add user to roster..."] {} {} {} \
                       -command {message::send_subscribe_dialog ""}] \
                  {separator} \
                  [list command [::msgcat::mc "Send message..."] {} {} {} \
                       -command {message::send_dialog}] \
                  [list command [::msgcat::mc "Open chat..."] {} {} {} \
                       -command {chat::open_chat_dialog}] \
                  [list command [::msgcat::mc "Join group..."] {} {} {}\
                       -command {join_group_dialog ""}] \
                  [list command [::msgcat::mc "Show user or service info..."] {} {} {} \
                       -command {userinfo::show_info_dialog}] \
                  {separator} \
                  [list command [::msgcat::mc "Service Discovery"] {} {} {} \
                       -command {disco::browser::open_win "" ""}] \
                  {separator} \
                  [list command [::msgcat::mc "Message archive"] {} {} {} \
                       -command {message_archive::show_archive}] \
          [list cascade [::msgcat::mc "Plugins"] {} plugins $options(show_tearoffs) \
                ] \
                  {separator} \
                  [list cascade [::msgcat::mc "Admin tools"] {} admin $options(show_tearoffs) \
                       [list \
                            [list command [::msgcat::mc "Send broadcast message..."] {} {} {} \
                                 -command {ifacetk::send_announce_message announce/online}] \
                            [list command [::msgcat::mc "Send message of the day..."] {} {} {} \
                                 -command {ifacetk::send_announce_message announce/motd}] \
                            [list command [::msgcat::mc "Update message of the day..."] {} {} {} \
                                 -command {ifacetk::send_announce_message announce/motd/update}] \
                            [list command [::msgcat::mc "Delete message of the day"] {} {} {} \
                                 -command {ifacetk::send_announce_message announce/motd/delete}] \
                        {separator} \
               ]] \
                  [list cascade [::msgcat::mc "Debug tools"] {} debug $options(show_tearoffs) \
               ] \
                 ] \
             [::msgcat::mc "&Help"] {} help $options(show_tearoffs) \
             [list \
                  [list command [::msgcat::mc "Quick help"] {} {} {} \
                       -command ifacetk::quick_help_window] \
                  [list command [::msgcat::mc "About"] {} {} {} \
                       -command ifacetk::about_window] \
                 ] \
            ]

    set descmenu [menuload $descmenu]
}

###############################################################################

proc ifacetk::send_announce_message {resource} {
    if {[llength [connections]] == 0} return

    set xlib [lindex [connections] 0]
    set server [connection_server $xlib]

    if {$resource eq "announce/motd/delete"} {
        message::send_msg $xlib $server/$resource -type normal
    } else {
        message::send_dialog -to $server/$resource -connection $xlib
    }
}

###############################################################################

proc ifacetk::quick_help_window {} {
    set w .quick_help

    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -anchor e \
              -title [::msgcat::mc "Quick Help"] \
              -side bottom \
              -modal none \
              -default 0 \
              -cancel 0
    $w add -text [::msgcat::mc "Close"] -command [list destroy $w]

    set frame [$w getframe]
    set sw [ScrolledWindow $frame.sw]
    pack $sw -fill both -expand yes

    set t [Text $frame.help -wrap none -takefocus 0]

    set tabstop [font measure [get_conf $t -font] \
                      "    [::msgcat::mc {Middle mouse button}]      "]
    $t configure -tabs $tabstop

    $sw setwidget $t
    $t insert 0.0 \
"[::msgcat::mc {Main window:}]
    $::tk_modify-L\t[::msgcat::mc {Log in}]
    $::tk_modify-J\t[::msgcat::mc {Log out}]

[::msgcat::mc Tabs:]
    $::tk_modify-F4,
    [::msgcat::mc {Middle mouse button}]\t[::msgcat::mc {Close tab}]
    $::tk_modify-PgUp/Down\t[::msgcat::mc {Previous/Next tab}]
    $::tk_modify-Alt-PgUp/Down\t[::msgcat::mc {Move tab left/right}]
    Alt-\[1-9,0\]\t[::msgcat::mc {Switch to tab number 1-9,10}]
    $::tk_modify-R\t[::msgcat::mc {Hide/Show roster}]

[::msgcat::mc Common:]
    $::tk_modify-S\t[::msgcat::mc {Activate search panel}]

[::msgcat::mc Chats:]
    TAB\t[::msgcat::mc {Complete nickname or command}]
    $::tk_modify-Up/Down\t[::msgcat::mc {Previous/Next history message}]
    Alt-E\t[::msgcat::mc {Show palette of emoticons}]
    $::tk_modify-Z\t[::msgcat::mc {Undo}]
    $::tk_modify-Shift-Z\t[::msgcat::mc {Redo}]
    Alt-PgUp/Down\t[::msgcat::mc {Scroll chat window up/down}]
    [::msgcat::mc {Right mouse button}]\t[::msgcat::mc {Correct word}]

[::msgcat::mc Systray:]
    [::msgcat::mc {Left mouse button}]\t[::msgcat::mc {Show main window}]
    [::msgcat::mc {Middle mouse button}]\t[::msgcat::mc {Hide main window}]
    [::msgcat::mc {Right mouse button}]\t[::msgcat::mc {Popup menu}]"
    $t configure -state disabled

    $w draw
}

proc ifacetk::about_window {} {
    global tkabber_version toolkit_version

    set w .about

    if {[winfo exists $w]} {
        destroy $w
    }

    Dialog $w -anchor e \
              -title [::msgcat::mc "About"] \
              -image tkabber/logo1 \
              -side bottom \
              -modal none \
              -default 0 \
              -cancel 0
    $w add -text [::msgcat::mc "Close"] -command [list destroy $w]

    set frame [$w getframe]
    set m [Message $frame.msg -text "
Tkabber $tkabber_version ($toolkit_version)

Copyright \u00a9 2002-2025 [::msgcat::mc {Alexey Shchepin}]
\n[::msgcat::mc Authors:]
    [::msgcat::mc {Alexey Shchepin}]
    [::msgcat::mc {Marshall T. Rose}]
    [::msgcat::mc {Sergei Golovan}]
    [::msgcat::mc {Michail Litvak}]
    [::msgcat::mc {Konstantin Khomoutov}]
"]
    pack $m -side top -anchor w

    set t [text $frame.url -cursor [get_conf $frame.msg -cursor] \
                           -background [get_conf $frame.msg -background] \
                           -height 1 \
                           -width 25 \
                           -borderwidth 0 \
                           -highlightthickness 0 \
                           -takefocus 0]
    ::richtext::config $t -using url
    ::richtext::render_message $t "  https://tkabber.jabber.ru/" ""
    $t delete {end - 1 char}
    $t configure -state disabled

    pack $t -side top -anchor w -fill x

    $w draw
}

proc ifacetk::switch_font {font class args} {
    variable options

    set opts [lassign $options($font) family size]
    set args [list -family $family -size $size]
    set bold 0
    set italic 0
    set underline 0
    set overstrike 0
    foreach opt $opts {
        switch -- $opt {
            bold {
                lappend args -weight bold
                set bold 1
            }
            italic {
                lappend args -slant italic
                set italic 1
            }
            underline {
                lappend args -underline 1
                set underline 1
            }
            overstrike {
                lappend args -overstrike 1
                set overstrike 1
            }

        }
    }
    if {!$bold} {
        lappend args -weight normal
    }
    if {!$italic} {
        lappend args -slant roman
    }
    if {!$underline} {
        lappend args -underline 0
    }
    if {!$overstrike} {
        lappend args -overstrike 0
    }

    redefine_fonts $class {*}$args
    if {$class eq "Roster"} {
        roster::redraw_after_idle

        foreach chatid [chat::opened] {
            if {[chat::is_groupchat $chatid]} {
                chat::redraw_roster_after_idle $chatid
            }
        }
    }
}

proc ifacetk::show_ssl_info {} {
    global ssl_certificate_fields

    if {[winfo exists .ssl_info]} {
        destroy .ssl_info
    }

    if {[llength [set msg_list [ssl_info]]] == 0} return

    Dialog .ssl_info -title [::msgcat::mc "SSL Info"] \
                     -anchor e \
                     -default 0 \
                     -cancel 0 \
                     -modal none
    .ssl_info add -text [::msgcat::mc "Close"] -command "destroy .ssl_info"
    set fr [.ssl_info getframe]

    if {[llength $msg_list] == 2} {
        lassign $msg_list server msg
        set page [Frame $fr.page]
        set title [::msgcat::mc "%s SSL Certificate Info" $server]
        grid [Label $page.title -text $title] -row 0 -column 0 -sticky ew
        grid [Message $page.info -aspect 50000 -text $msg] \
            -row 1 -column 0 -sticky ew
        pack $page -expand yes -fill both -padx 1m -pady 1m
    } else {
        set nb [Notebook $fr.nb]
        pack $nb -expand yes -fill both -padx 0m -pady 0m

        set i 0
        foreach {server msg} $msg_list {
            set page [$nb insert end page$i -text $server]
            set title [::msgcat::mc "%s SSL Certificate Info" $server]
            grid [Label $page.title -text $title] -row 0 -column 0 -sticky ew
            grid [Message $page.info -aspect 50000 -text $msg] \
                -row 1 -column 0 -sticky ew
            incr i
        }
        catch {$nb compute_size}
        catch {$nb raise page0}
    }
    .ssl_info draw
}

proc ifacetk::update_ssl_ind {xlib} {
    global use_tls
    variable ssl_ind

    if {!$use_tls} return

    lassign [update_ssl_info] state fg balloon

    if {$fg ne "warning"} {
        label .fake_label
        set fg [.fake_label cget -foreground]
        destroy .fake_label
    } else {
        set fg [option get $ssl_ind errorForeground Label]
    }
    $ssl_ind configure -state $state
    if {$state eq "normal"} {
        $ssl_ind configure -foreground $fg
    }
    DynamicHelp::register $ssl_ind balloon $balloon
}

hook::add connected_hook [namespace current]::ifacetk::update_ssl_ind
hook::add disconnected_hook [namespace current]::ifacetk::update_ssl_ind

###############################################################################

proc ifacetk::add_toolbar_button {icon command helptext} {
    if {[catch {set bbox [.mainframe gettoolbar 0].bbox}] || \
            ![winfo exists $bbox]} {
        return 0
    }
    $bbox add -image $icon \
              -takefocus 0 \
              -relief link \
              -command $command \
              -helptext $helptext
    return [$bbox index end]
}

###############################################################################

proc ifacetk::set_toolbar_icon {index script args} {
    if {[catch {set bbox [.mainframe gettoolbar 0].bbox}] || \
            ![winfo exists $bbox]} {
        return
    }
    set image [{*}$script]
    $bbox itemconfigure $index -image $image
}

###############################################################################

proc ifacetk::online_icon {args} {
    if {$::ifacetk::roster::show_only_online} {
        return toolbar/show-online
    } else {
        return toolbar/show-offline
    }
}

proc ifacetk::fix_borders {w} {
    $w configure -borderwidth 0.25m
    foreach ww [winfo children $w] {
        fix_borders $ww
    }
}

proc ifacetk::create_main_window {} {
    global usetabbar
    global user_status_list
    global use_tls
    global descmenu
    variable mf
    variable rw
    variable rosterwidth
    variable ssl_ind
    variable main_window_title
    variable options
    variable status_history

    set main_window_title "Tkabber"
    wm title . $main_window_title
    wm iconname . $main_window_title
    wm group . .

    bind all <<PrevWindow>> {focus [Widget::focusPrev %W]}

    load_descmenu
    set mf [MainFrame .mainframe -menu $descmenu -textvariable status]
    $mf.frame configure -borderwidth 0.25m
    $mf.botf configure -borderwidth 0.25m
    fix_borders .menubar
    unset descmenu

    if {$use_tls} {
        set ssl_ind [$mf addindicator -text "SSL" -state disabled]
        $ssl_ind configure -relief flat
        DynamicHelp::register $ssl_ind balloon [::msgcat::mc "Disconnected"]
        bind $ssl_ind <1> [namespace current]::show_ssl_info
    }

    pack $mf -expand yes -fill both

    bind $mf <Destroy> quit

    set bbox [ButtonBox [$mf addtoolbar].bbox -spacing 0 -padx 0.25m -pady 0.25m]

    add_toolbar_button toolbar/add-user {message::send_subscribe_dialog ""} \
        [::msgcat::mc "Add new user..."]
    add_toolbar_button toolbar/disco {disco::browser::open_win "" ""} \
        [::msgcat::mc "Service Discovery"]
    add_toolbar_button toolbar/join-conference {join_group_dialog ""} \
        [::msgcat::mc "Join group..."]

    set idx [add_toolbar_button [ifacetk::online_icon] \
                 [namespace current]::roster::switch_only_online \
                 [::msgcat::mc "Toggle showing offline users"]]
    trace add variable [namespace current]::roster::show_only_online write \
        [list [namespace current]::set_toolbar_icon $idx \
              [namespace current]::online_icon]

    pack $bbox -side left -anchor w
    switch_toolbar

    if {$options(use_tabbar)} {
        set usetabbar 1
    } else {
        set usetabbar 0
    }

    set ww 0
    foreach {status str} $user_status_list {
        if {[string length $str] > $ww} {
            set ww [string length $str]
        }
    }

    Frame .presence
    Menubutton .presence.button -menu .presence.button.menu \
                                -textvariable userstatusdesc \
                                -direction above \
                                -width $ww

    disallow_presence_change ""

    set w .presence.status
    Combobox $w -textvariable textstatus \
                -values $status_history \
                -command {set userstatus $userstatus}
    trace add variable ::userstatus write \
        [list [namespace current]::save_availability_status $w]
    bind $w <<ContextMenu>> \
            [list [namespace current]::show_status_context_menu [double% $w]]
    catch { bind $w.e <<ContextMenu>> [bind $w <<ContextMenu>>] }
    if {$usetabbar} {
        pack .presence.button -side left
        pack .presence.status -side left -fill x -expand yes
    } else {
        pack .presence.button -side top -anchor w
        pack .presence.status -side top -fill x -expand yes -anchor w
    }
    grid .presence -row 3 -column 1 -sticky nswe -in [$mf getframe]

    if {[winfo exists [set m .presence.button.menu]]} {
        destroy $m
    }
    menu $m -tearoff $options(show_tearoffs)
    foreach {status str} $user_status_list {
        switch -- $status {
            invisible -
            unavailable {}
            default {
                $m add command \
                       -label $str \
                       -command [list set userstatus $status]
            }
        }
    }

    switch_presencebar
    switch_statusbar

    set rosterwidth [option get . mainRosterWidth [winfo class .]]
    if {$rosterwidth eq ""} {
        set rosterwidth [winfo pixels . 3c]
    }

    grid columnconfigure [$mf getframe] 1 -weight 1
    grid rowconfigure [$mf getframe] 1 -weight 1

    if {$usetabbar} {
        set pw [PanedWin [$mf getframe].pw -orient horizontal]
        grid $pw -row 1 -column 1 -sticky nswe
        set rw [PanedWinAdd $pw -weight 0]
        set nw [PanedWinAdd $pw -weight 1]

        variable tabs
        set tabs $nw

        roster::create .roster -width $rosterwidth -height 300 \
            -popup [namespace current]::roster::popup_menu \
            -grouppopup [namespace current]::roster::group_popup_menu \
            -singleclick [namespace current]::roster::user_singleclick \
            -doubleclick [namespace current]::roster::jid_doubleclick \
            -draginitcmd [namespace current]::roster::draginitcmd \
            -dropcmd [namespace current]::roster::dropcmd
        grid .roster -row 0 -column 0 -sticky nswe -in $rw

        grid columnconfigure $rw 0 -weight 1
        grid rowconfigure $rw 0 -weight 1

        grid columnconfigure $nw 1 -weight 1
        grid rowconfigure $nw 1 -weight 1

        ButtonBar .nb -orient horizontal \
                      -pady 0.25m \
                      -padx 1m \
                      -pages .pages

        configure_tabs

        Frame $nw.fr -relief raised -borderwidth 0.25m
        grid $nw.fr -row 1 -column 1 -sticky nsew

        grid columnconfigure $nw.fr 0 -weight 1
        grid rowconfigure $nw.fr 0 -weight 1

        PagesManager .pages -width 400
        grid .pages -row 0 -column 0 -padx 2m -pady 2m -in $nw.fr -sticky nsew
        $pw configure -width $rosterwidth

        event add <<CollapseRoster>> <Control-Key-r>
        bind . <<CollapseRoster>>   [list [namespace current]::collapse_roster]
        bind . <Control-Prior>      [list [namespace current]::tab_move .nb -1]
        bind . <Control-Next>       [list [namespace current]::tab_move .nb 1]
        bind . <Control-Meta-Prior> \
               [list [namespace current]::current_tab_move .nb -1]
        bind . <Control-Alt-Prior> \
               [list [namespace current]::current_tab_move .nb -1]
        bind . <Control-Meta-Next> \
               [list [namespace current]::current_tab_move .nb  1]
        bind . <Control-Alt-Next> \
               [list [namespace current]::current_tab_move .nb  1]
        bind . <Control-Key-F4> {
            if {[.nb raise] ne ""} {
                destroy {*}[pack slaves [.nb getframe [.nb raise]]]
                .nb delete [.nb raise] 1
                ifacetk::tab_move .nb 0
            }
        }

        for {set i 1} {$i < 10} {incr i} {
            bind . <Meta-Key-$i> \
                   [list [namespace current]::tab_raise_by_number .nb $i]
            bind . <Alt-Key-$i> \
                   [list [namespace current]::tab_raise_by_number .nb $i]
        }
        bind . <Meta-Key-0> \
               [list [namespace current]::tab_raise_by_number .nb 10]
        bind . <Alt-Key-0> \
               [list [namespace current]::tab_raise_by_number .nb 10]

        set m [menu .tabsmenu -tearoff 0]
        $m add command -label [::msgcat::mc "Close"] -accelerator $::tk_close \
            -command {
                if {[.nb raise] ne ""} {
                    destroy {*}[pack slaves [.nb getframe $curmenutab]]
                    .nb delete $curmenutab 1
                    ifacetk::tab_move .nb 0
                }
            }
        $m add separator
        $m add command -label [::msgcat::mc "Close other tabs"] \
            -command {
                foreach tab [.nb pages] {
                    if {$tab ne $curmenutab} {
                        destroy {*}[pack slaves [.nb getframe $tab]]
                        .nb delete $tab 1
                    }
                }
                ifacetk::tab_move .nb 0
            }
        $m add command -label [::msgcat::mc "Close all tabs"] \
            -command {
                foreach tab [.nb pages] {
                    destroy {*}[pack slaves [.nb getframe $tab]]
                    .nb delete $tab 1
                }
            }

        .nb bindtabs <<ContextMenu>> [list [namespace current]::tab_menu %X %Y]
        .nb bindtabs <<PasteSelection>> [list [namespace current]::destroy_tab]
        .nb bindtabs <<ScrollUp>> [list [namespace current]::tab_move .nb -1]
        .nb bindtabs <<ScrollDown>> [list [namespace current]::tab_move .nb 1]

        set geometry [option get . geometry [winfo class .]]
        if {$geometry eq ""} {
            set geometry 788x550
        }
    } else {
        roster::create .roster -width $rosterwidth -height 300 \
            -popup [namespace current]::roster::popup_menu \
            -grouppopup [namespace current]::roster::group_popup_menu \
            -singleclick [namespace current]::roster::user_singleclick \
            -doubleclick [namespace current]::roster::jid_doubleclick \
            -draginitcmd [namespace current]::roster::draginitcmd \
            -dropcmd [namespace current]::roster::dropcmd
        grid .roster -row 1 -column 1 -sticky nswe -in [$mf getframe]
        set geometry [option get . geometry [winfo class .]]
        if {$geometry eq ""} {
            set geometry 200x350
        }
    }

    bind . <Map> [list [namespace current]::map_dot %W]

    wm geometry . $geometry

    define_alert_colors
    update idletasks
}

proc ifacetk::map_dot {w} {
    if {$w ne "."} return

    hook::run map_window_hook $w
}

proc ifacetk::destroy_tab {page} {
    if {[.nb raise] ne ""} {
        destroy {*}[pack slaves [.nb getframe $page]]
        .nb delete $page 1
        ifacetk::tab_move .nb 0
    }
}

proc ifacetk::destroy_win {path} {
    global usetabbar

    if {$usetabbar} {
        if {[winfo exists $path]} {
            set page [ifacetk::nbpage $path]
            destroy {*}[pack slaves [.nb getframe $page]]
            .nb delete $page 1
            ifacetk::tab_move .nb 0
        }
    } else {
        destroy $path
    }
}

hook::add finload_hook [namespace current]::ifacetk::create_main_window 1

proc ifacetk::allow_presence_change {xlib} {
    .presence.button configure -state normal

    set m [.mainframe getmenu tkabber]
    $m entryconfigure [$m index [::msgcat::mc "Presence"]] -state normal

}

proc ifacetk::disallow_presence_change {xlib} {
    if {[llength [connections]] == 0} {
        .presence.button configure -state disabled

        set m [.mainframe getmenu tkabber]
        $m entryconfigure [$m index [::msgcat::mc "Presence"]] -state disabled
    }
}

hook::add connected_hook [namespace current]::ifacetk::allow_presence_change
hook::add disconnected_hook \
          [namespace current]::ifacetk::disallow_presence_change

proc ifacetk::on_open_chat_window {chatid type} {
    variable number_msg
    variable personal_msg

    set number_msg($chatid) 0
    set personal_msg($chatid) 0
}

proc ifacetk::on_close_chat_window {chatid} {
    variable number_msg
    variable personal_msg

    unset number_msg($chatid)
    unset personal_msg($chatid)

    update_main_window_title
}

hook::add open_chat_pre_hook [namespace current]::ifacetk::on_open_chat_window
hook::add close_chat_post_hook \
          [namespace current]::ifacetk::on_close_chat_window

proc ifacetk::nbpage {path} {
    return [string range [win_id tab $path] 1 end]
}

proc ifacetk::nbpath {page} {
    return [lindex [pack slaves [.nb getframe $page]] 0]
}

proc ifacetk::update_chat_title {chatid} {
    global usetabbar
    variable options
    variable number_msg
    variable personal_msg

    set cw [chat::winid $chatid]

    if {$usetabbar} {
        set tabtitle $::chat::chats(tabtitlename,$chatid)
        if {$options(message_numbers_in_tabs) && $number_msg($chatid) > 0} {
            append tabtitle " ($number_msg($chatid))"
        }
        set_tab_title_after_idle $cw $tabtitle
    } else {
        if {$personal_msg($chatid) > 0} {
            set star "*"
        } else {
            set star ""
        }

        if {$options(only_personal_messages_in_window_title)} {
            set messages $personal_msg($chatid)
        } else {
            set messages $number_msg($chatid)
        }

        if {$messages > 0} {
            set title "($messages$star) $::chat::chats(titlename,$chatid)"
        } else {
            set title $::chat::chats(titlename,$chatid)
        }

        set_window_title_after_idle $cw $title
    }
}

proc ifacetk::set_tab_title_after_idle {w title} {
    execute_script_after_idle [list .nb itemconfigure [nbpage $w] -text] $title
}

proc ifacetk::update_chat_titles {args} {

    foreach chatid [chat::opened] {
        lassign [chat::window_titles $chatid] \
            ::chat::chats(tabtitlename,$chatid) \
            ::chat::chats(titlename,$chatid)
        ifacetk::update_chat_title $chatid
    }
}

proc ifacetk::update_main_window_title {} {
    global usetabbar
    variable options
    variable main_window_title
    variable number_msg
    variable personal_msg

    if {!$usetabbar} return

    set star ""
    set messages 0

    if {$options(only_personal_messages_in_window_title)} {
        set star "*"
        foreach chatid [chat::opened] {
            incr messages $personal_msg($chatid)
        }
    } else {
        foreach chatid [chat::opened] {
            incr messages $number_msg($chatid)
            if {$personal_msg($chatid) > 0} {
                set star "*"
            }
        }
    }

    if {$messages} {
        set title "($messages$star) $main_window_title"
    } else {
        set title $main_window_title
    }
    set_window_title_after_idle . $title
}

proc ifacetk::set_window_title_after_idle {w title} {
    execute_script_after_idle [namespace code [list set_window_title $w]] $title
}

proc ifacetk::set_window_title {w title} {
    if {![winfo exists $w]} return

    wm title $w $title
    wm iconname $w $title
}

proc ifacetk::chat_window_is_active {chatid} {
    global usetabbar

    set cw [chat::winid $chatid]
    set w [winfo toplevel $cw]
    set f [focus]
    if {$f ne "" && $w eq [winfo toplevel $f] && \
            (!$usetabbar || ([.nb raise] eq [nbpage $cw]))} {
        return 1
    } else {
        return 0
    }
}

proc ifacetk::add_number_of_messages_to_title {chatid from type body extras} {
    global usetabbar
    variable number_msg
    variable personal_msg

    set xlib [chat::get_xlib $chatid]

    if {![catch {::plugins::mucignore::is_ignored $xlib $from $type} ignore] && $ignore ne ""} {
        return
    }

    foreach xelem $extras {
        ::xmpp::xml::split $xelem tag xmlns attrs cdata subels
        # Don't add number to title if this 'empty' tag is present. It
        # indicates messages history in chat window.
        if {$tag eq "" && $xmlns eq "tkabber:x:nolog"} {
            return
        }
    }

    if {[chat_window_is_active $chatid]} return

    if {$from eq ""} return

    if {$type eq "chat"} {
        incr number_msg($chatid)
        incr personal_msg($chatid)
    } elseif {$type eq "groupchat"} {
        set jid [chat::get_jid $chatid]
        set myjid [chat::our_jid $chatid]
        set mynick [chat::get_nick $xlib $myjid $type]
        if {$jid ne $from && $myjid ne $from} {
            incr number_msg($chatid)
            if {[check_message $mynick $body]} {
                incr personal_msg($chatid)
            }
        }
    }
    update_chat_title $chatid
    update_main_window_title
}

hook::add draw_message_hook \
          [namespace current]::ifacetk::add_number_of_messages_to_title 18

proc ifacetk::set_main_window_title_on_connect {xlib} {
    variable main_window_title

    set main_window_title "[connection_jid $xlib] - Tkabber"
    set_window_title_after_idle . $main_window_title
}

proc ifacetk::set_main_window_title_on_disconnect {xlib} {
    variable main_window_title

    if {[llength [connections]] == 0} {
        set main_window_title "Tkabber"
    } else {
        set main_window_title \
            "[connection_jid [lindex [connections] end]] - Tkabber"
    }
    set_window_title_after_idle . $main_window_title
}

hook::add connected_hook \
    [namespace current]::ifacetk::set_main_window_title_on_connect
hook::add disconnected_hook \
    [namespace current]::ifacetk::set_main_window_title_on_disconnect

proc ifacetk::raise_win {path} {
    global usetabbar

    if {[winfo exists $path]} {
        if {$usetabbar} {
            .nb raise [nbpage $path]
        }
    }
}

proc ifacetk::add_win {path args} {
    global usetabbar
    variable options

    set title ""
    set tabtitle ""
    set class ""
    set raisecmd ""
    set type ""
    set raise 0

    foreach {attr val} $args {
        switch -- $attr {
            -title    {set title    $val}
            -tabtitle {set tabtitle $val}
            -class    {set class    $val}
            -raisecmd {set raisecmd $val}
            -raise    {set raise    $val}
            -type     {set type     $val}
            default   {error "Unknown option $attr"}
        }
    }

    if {$usetabbar} {
        set page [nbpage $path]
        set f [.nb insert end $page \
                   -text $tabtitle \
                   -raisecmd [list [namespace current]::tab_raise \
                                   $path $raisecmd]]
        Frame $path -class $class
        pack $path -expand yes -fill both -in $f
        #tkwait visibility $path
        set ::tabcolors($page) ""
        if {$raise || $options(raise_new_tab) || [llength [.nb pages]] == 1} {
            after idle [list catch [list .nb raise $page]]
        }
    } else {
        toplevel $path -class $class -relief flat -borderwidth 2m
        wm group $path .
        wm title $path $title
        wm iconname $path $title
        set geometry [option get $path ${type}geometry $class]
        if {$geometry ne ""} {
            wm geometry $path $geometry
        }
    }
}

bind . <FocusIn>  [list [namespace current]::ifacetk::get_focus %W]
bind . <FocusOut> [list [namespace current]::ifacetk::loose_focus %W]
bind Chat <FocusIn>  [list [namespace current]::ifacetk::get_focus %W]
bind Chat <FocusOut> [list [namespace current]::ifacetk::loose_focus %W]

proc ifacetk::tab_raise {path command} {
    tab_set_updated $path
    if {$command ne ""} {
        {*}$command
    }
}

proc ifacetk::get_focus {path} {
    if {![winfo exists $path]} return
    hook::run got_focus_hook $path
}

proc ifacetk::on_focus_got {path} {
    variable options
    variable after_focused_id

    if {$after_focused_id ne ""} {
        after cancel $after_focused_id
    }
    set after_focused_id \
        [after $options(update_title_delay) \
               [list [namespace current]::set_title $path]]
}
hook::add got_focus_hook [namespace current]::ifacetk::on_focus_got

proc ifacetk::set_title {path} {
    global usetabbar
    variable number_msg
    variable personal_msg

    if {![winfo exists $path]} return

    if {$usetabbar} {
        if {[set p [.nb raise]] ne ""} {
            tab_set_updated $p
        }
        update_main_window_title
    } else {
        if {[info exists ::chat::chat_id($path)]} {
            set chatid $::chat::chat_id($path)
            set number_msg($chatid) 0
            set personal_msg($chatid) 0
            update_chat_title $chatid
        }
    }
}

proc ifacetk::loose_focus {path} {
    if {![winfo exists $path]} return
    hook::run lost_focus_hook $path
}

proc ifacetk::on_focus_lost {path} {
    variable after_focused_id

    if {$after_focused_id ne ""} {
        after cancel $after_focused_id
        set after_focused_id ""
    }
    balloon::destroy
}
hook::add lost_focus_hook [namespace current]::ifacetk::on_focus_lost

proc ifacetk::tab_move {nb shift args} {
    set len [llength [$nb pages]]

    if {$len > 0} {
        set newidx [expr [$nb index [$nb raise]] + $shift]

        if {$newidx < 0} {
            set newidx [expr $len - 1]
        } elseif {$newidx >= $len} {
            set newidx 0
        }

        $nb see [lindex [$nb pages] $newidx]
        $nb raise [lindex [$nb pages] $newidx]
    }
}

proc ifacetk::current_tab_move {nb shift} {
    set len [llength [$nb pages]]

    if {$len > 0} {
        set newidx [expr [$nb index [$nb raise]] + $shift]

        if {$newidx < 0} {
            set newidx [expr $len - 1]
        } elseif {$newidx >= $len} {
            set newidx 0
        }

        $nb move [$nb raise] $newidx
        $nb see [$nb raise]
    }
}

proc ifacetk::tab_raise_by_number {nb num} {
    set pages [$nb pages]
    incr num -1
    set page [lindex $pages $num]
    if {$page ne ""} {
        $nb raise $page
    }
}

proc ifacetk::define_alert_colors {} {
    global usetabbar
    global alert_colors

    if {$usetabbar} {
        # Colors of tab labels (when in tabbed mode)

        if {$::darktheme} {
            # Usual color
            option add *alertColor0 $::defaultforeground widgetDefault
            # Color when server message is arrived
            option add *alertColor1 mediumorchid3 widgetDefault
            # Color when message is arrived
            option add *alertColor2 steelblue1 widgetDefault
            # Color when personally addressed message is arrived
            option add *alertColor3 coral3 widgetDefault
        } else {
            # Usual color
            option add *alertColor0 $::defaultforeground widgetDefault
            # Color when server message is arrived
            option add *alertColor1 DarkViolet widgetDefault
            # Color when message is arrived
            option add *alertColor2 dodgerblue4 widgetDefault
            # Color when personally addressed message is arrived
            option add *alertColor3 firebrick4 widgetDefault
        }

        set alert_colors [list \
                [option get .nb alertColor0 ButtonBar] \
                [option get .nb alertColor1 ButtonBar] \
                [option get .nb alertColor2 ButtonBar] \
                [option get .nb alertColor3 ButtonBar]]
    }
}

array set ::alert_lvls {info 1 error 1 server 1 message 2 mesg_to_user 3}

proc ifacetk::tab_set_updated {path {updated 0} {level ""}} {
    global usetabbar
    global tabcolors
    global alert_lvls alert_colors
    variable number_msg
    variable personal_msg

    if {!$usetabbar} return

    set page [nbpage $path]
    if {[.nb index $page] < 0} {
        set page $path
        if {[.nb index $page] < 0} return
        set path [nbpath $page]
    }

    set st [wm state .]
    if {$st ni {normal zoomed} || [focus -displayof .] eq ""} {
        set backgroundP 1
    } else {
        set backgroundP 0
    }
    if {!$updated && $backgroundP} {
        return
    }

    if {$updated && \
            ($page ne [.nb raise] && \
                [info exists alert_lvls($level)] || \
                $backgroundP)} {
        set lvlnum $alert_lvls($level)
    } else {
        set lvlnum 0
    }

    if {!$updated || $tabcolors($page) < $lvlnum} {
        set color [lindex $alert_colors $lvlnum]
        .nb itemconfigure $page -foreground $color -activeforeground $color
        set tabcolors($page) $lvlnum
        hook::run tab_set_updated $path $updated $level
    }
    if {[info exists ::chat::chat_id($path)]} {
        if {!$updated || $lvlnum == 0} {
            set chatid $::chat::chat_id($path)
            set number_msg($chatid) 0
            set personal_msg($chatid) 0
            update_chat_title $chatid
            update_main_window_title
        }
    }
}

proc ifacetk::tab_menu {x y page} {
    global curmenutab
    set curmenutab $page
    tk_popup .tabsmenu $x $y
}

###############################################################################

proc ifacetk::collapse_roster {} {
    variable mf
    variable rosterwidth
    variable sashpos

    set pw [$mf getframe].pw
    set r [winfo width $pw.frame0]
    set s [PanedWinSashXPos $pw 0]

    if {$r == 1 || $r > $s} {
        PanedWinSashXPos $pw 0 $sashpos
    } else {
        set rosterwidth $r
        set sashpos [PanedWinSashXPos $pw 0]
        PanedWinSashXPos $pw 0 0
    }
}

###############################################################################

proc ifacetk::switch_toolbar {args} {
    variable options
    variable mf
    $mf showtoolbar 0 $options(show_toolbar)
}

proc ifacetk::switch_presencebar {args} {
    global usetabbar
    variable options
    variable mf

    if {[winfo exists .presence]} {
        if {$options(show_presencebar)} {
            catch {
                grid .presence -row 3 -column 1 \
                    -sticky nswe -in [.mainframe getframe]
                .presence.status configure -takefocus 1
            }
        } else {
            grid forget .presence
            .presence.status configure -takefocus 0
            if {[focus] eq ".presence.status"} {
            focus [Widget::focusPrev .presence.status]
            }
        }
    }
}

proc ifacetk::switch_statusbar {args} {
    variable options
    variable mf

    catch {
        if {$options(show_statusbar)} {
            pack $mf.botf -side bottom -fill x -before [$mf getframe]
        } else {
            pack forget $mf.botf
        }
    }
}

proc ifacetk::deiconify {} {
    wm deiconify .
}

hook::add finload_hook [namespace current]::ifacetk::deiconify 100

proc ifacetk::save_availability_status {w args} {
    variable status_history
    variable options

    set avstatus [$w get]
    if {$avstatus eq ""} return

    if {[catch {$w getvalue} ix]} {
        set ix [$w current]
    }
    if {$ix >= 0} {
        set status_history \
            [linsert [lreplace $status_history $ix $ix] end $avstatus]
    } elseif {[llength $status_history] < $options(max_status_history)} {
        lappend status_history $avstatus
    } else {
        set status_history \
            [linsert [lrange $status_history 1 end] end $avstatus]
    }

    $w configure -values $status_history
}

proc ifacetk::show_status_context_menu w {
    set m $w.menu

    if {![winfo exists $m]} {
        menu $m -tearoff 0
        $m add command \
            -label [::msgcat::mc "Clear history"] \
            -command [list [namespace current]::clear_status_history $w]
    }

    tk_popup $m [winfo pointerx $w] [winfo pointery $w]
}

proc ifacetk::clear_status_history w {
    variable status_history

    set status_history [list]
    $w configure -values $status_history
}

# This proc should be called by WM_SAVE_YOURSELF protocol callback.
# On Windows (and Tk >= 8.4.13) this means WM_QUERYENDSESSION (so we should
# quit), on Unix, an X session manager may call this repeatedly.
proc session_checkpoint {} {
    global tcl_platform
    ::hook::run save_yourself_hook
    if {$tcl_platform(platform) eq "windows"} quit
}

# Trap SIGTERM to quit gracefully on Unix when Tclx is available:
if {$tcl_platform(platform) eq "unix"
    && ![catch {package require Tclx}]} {
    signal trap SIGTERM quit
}

# Import add_win tab_set_updated to the root namespace:
namespace import ::ifacetk::raise_win ::ifacetk::add_win \
                 ::ifacetk::destroy_win ::ifacetk::tab_set_updated

# vim:ft=tcl:ts=8:sw=4:sts=4:et
