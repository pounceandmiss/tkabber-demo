# userinfo.tcl --
#
#       This file is a part of the Tkabber XMPP client. It shows
#       basic user/service info window and provides infrastructure for
#       registering userinfo tabs.

namespace eval userinfo {
    custom::defvar show_info_list {} \
            [::msgcat::mc "List of users for userinfo."] \
            -group Hidden
}

proc userinfo::show_info_dialog {} {
    variable show_info_jid
    variable show_info_list
    variable show_info_xlib

    if {[llength [connections]] == 0} return

    set gw .userinfo
    catch { destroy $gw }

    set xlib [lindex [connections] 0]
    set show_info_xlib [connection_jid $xlib]

    Dialog $gw -title [::msgcat::mc "Show user or service info"] \
               -anchor e \
               -default 0 \
               -cancel 1

    set gf [$gw getframe]
    grid columnconfigure $gf 1 -weight 1

    set show_info_jid ""

    Label $gf.ljid -text [::msgcat::mc "JID:"]
    Combobox $gf.jid -textvariable [namespace current]::show_info_jid \
                     -values [linsert $show_info_list 0 ""] \
                     -width 35

    grid $gf.ljid -row 0 -column 0 -sticky e
    grid $gf.jid  -row 0 -column 1 -sticky ew

    if {[llength [connections]] > 1} {
        set connections {}
        foreach c [connections] {
            lappend connections [connection_jid $c]
        }
        Label $gf.lconnection -text [::msgcat::mc "Connection:"]
        Combobox $gf.connection \
                 -textvariable [namespace current]::show_info_xlib \
                 -values $connections

        grid $gf.lconnection -row 1 -column 0 -sticky e
        grid $gf.connection  -row 1 -column 1 -sticky ew
    }

    $gw add -text [::msgcat::mc "Show"] \
            -command "[namespace current]::show_info $gw"
    $gw add -text [::msgcat::mc "Cancel"] -command "destroy $gw"

    $gw draw $gf.jid
}

proc userinfo::show_info {gw} {
    variable show_info_jid
    variable show_info_list
    variable show_info_xlib

    destroy $gw

    foreach c [connections] {
        if {[connection_jid $c] == $show_info_xlib} {
            set xlib $c
        }
    }
    if {![info exists xlib]} {
        set xlib [lindex [connections] 0]
    }

    set show_info_list [update_combo_list $show_info_list $show_info_jid 10]
    userinfo::open $xlib $show_info_jid
}

proc userinfo::w_from_jid {jid} {
    return [win_id userinfo $jid]
}

proc userinfo::pack_frame {w text} {
    set tf [Labelframe $w -text $text -padding {2m 2m}]
    pack $tf -fill both -expand yes -padx 1m -pady 1m
    return $tf
}

proc userinfo::pack_entry {jid g row name text} {
    set w [w_from_jid $jid]

    Label $g.l$name -text $text
    upvar editable editable

    if {!$editable} {
        if {$::interface eq "ttk"} {
            set bg [ttk::style lookup TFrame -background]
        } else {
            set bg [lindex [$g configure -background] 4]
        }
        entry $g.$name -textvariable ::userinfo::userinfo($name,$jid) \
                       -borderwidth 0 -state readonly -takefocus 0 \
                       -highlightthickness 0 -readonlybackground $bg
    } else {
        if {![info exists ::userinfo::userinfo($name,$jid)]} {
            set ::userinfo::userinfo($name,$jid) ""
        }
        Entry $g.$name -textvariable ::userinfo::userinfo($name,$jid)
    }

    grid $g.l$name -row $row -column 0 -padx 0.5m -sticky e
    grid $g.$name  -row $row -column 1 -padx 0.5m -sticky we
    grid columnconfig $g 1 -weight 1 -minsize 0
    #grid rowconfig $g $row -weight 1 -minsize 0
}

proc userinfo::pack_text_entry {jid g row name text} {
    variable userinfo

    set w [w_from_jid $jid]

    Label $g.l$name -text $text
    if {$::interface eq "ttk"} {
        set bg [ttk::style lookup TFrame -background]
    } else {
        set bg [lindex [$g configure -background] 4]
    }
    text $g.$name -height 1 -state disabled -borderwidth 0 -takefocus 0 \
                  -highlightthickness 0 -background $bg
    ::richtext::config $g.$name -using url
    fill_user_description $g.$name userinfo($name,$jid) 0

    grid $g.l$name -row $row -column 0 -padx 0.5m -sticky e
    grid $g.$name  -row $row -column 1 -padx 0.5m -sticky we
    grid columnconfig $g 1 -weight 1 -minsize 0
    trace add variable [namespace current]::userinfo($name,$jid) write \
        [list userinfo::fill_user_description $g.$name userinfo($name,$jid) 0]
    bind $g.$name <Destroy> \
        +[double% [list \
               trace remove variable [namespace current]::userinfo($name,$jid) write \
               [list userinfo::fill_user_description $g.$name \
                     userinfo($name,$jid) 0]]]
}

proc userinfo::pack_spinbox {jid g row col name low high text} {
    label $g.l$name -text $text

    if {![info exists ::userinfo::userinfo($name,$jid)]} {
        set ::userinfo::userinfo($name,$jid) ""
    }
    Spinbox $g.$name $low $high 1 ::userinfo::userinfo($name,$jid)

    grid $g.l$name -row $row -column $col -padx 0.5m -sticky e
    grid $g.$name  -row $row -column [expr {$col + 1}] -padx 0.5m -sticky we
}

proc userinfo::manage_focus {jid tab w editable} {
    variable userinfo

    if {$editable} {
        upvar $tab t
        set userinfo(focus_$tab,$jid) $w
        bind $t <Map> \
             +[double% \
             "focus \$[list [namespace current]::userinfo(focus_$tab,$jid)]"]
        bind $t <Unmap> \
             +[double% \
             "set [list [namespace current]::userinfo(focus_$tab,$jid)] \
                  \[focus\]"]
    }
}

proc userinfo::open_client {xlib jid args} {
    open $xlib $jid {*}$args -page client
}

proc userinfo::open {xlib jid args} {
    global tcl_platform
    variable userinfo

    set w [w_from_jid $jid]

    if {[winfo exists $w]} {
        #focus -force $w
        #return
        destroy $w
    }

    set editable 0
    set top_page personal
    foreach {opt val} $args {
        switch -- $opt {
            -editable   {set editable $val}
            -page {set top_page $val}
        }
    }
    if {$xlib == ""} {
        set xlib [lindex [connections] 0]
    }

    Toplevel $w
    wm withdraw $w
    wm group $w .
    set title [::msgcat::mc "%s info" $jid]
    wm title $w $title
    wm iconname $w $title

    if {$editable} {
        set bbox [ButtonBox $w.bbox -spacing 2m -padx 2m -default 0]
        $bbox add -text [::msgcat::mc "Update"] -command "
                userinfo::send_vcard [list $xlib] [list $jid]
                destroy [list $w]
        "
        $bbox add -text [::msgcat::mc "Cancel"] -command [list destroy $w]
        bind $w <Return> [list ButtonBox::invoke [double% $bbox] default]
        bind $w <Escape> [list ButtonBox::invoke [double% $bbox] 1]

        pack $bbox -padx 1m -pady 1m -anchor e -side bottom
    }

    Frame $w.frame
    pack $w.frame -padx 1m -pady 1m -expand yes -fill both

    set tab [Notebook $w.frame.tab]
    pack $tab -expand yes -fill both


    set personal [$tab insert end personal -text [::msgcat::mc "Personal"]]

    set n [pack_frame $personal.n [::msgcat::mc "Name"]]
    pack_entry $jid $n 0 fn [::msgcat::mc "Full name:"]
    pack_entry $jid $n 1 family [::msgcat::mc "Family name:"]
    pack_entry $jid $n 2 name [::msgcat::mc "First name:"]
    pack_entry $jid $n 3 middle [::msgcat::mc "Middle name:"]
    pack_entry $jid $n 4 prefix [::msgcat::mc "Prefix:"]
    pack_entry $jid $n 5 suffix [::msgcat::mc "Suffix:"]
    pack_entry $jid $n 6 nickname [::msgcat::mc "Nickname:"]

    set c [pack_frame $personal.info [::msgcat::mc "Information"]]
    pack_entry $jid $c 0 email [::msgcat::mc "E-mail:"]
    if {$editable} {
        pack_entry $jid $c 1 url [::msgcat::mc "Web site:"]
    } else {
        pack_text_entry $jid $c 1 url [::msgcat::mc "Web site:"]
    }
    pack_entry $jid $c 2 jabberid [::msgcat::mc "JID:"]
    pack_entry $jid $c 3 uid [::msgcat::mc "UID:"]

    manage_focus $jid personal $n.fn $editable

    set phones [$tab insert end phones -text [::msgcat::mc "Phones"]]

    set t [pack_frame $phones.tel [::msgcat::mc "Telephone numbers"]]
    pack_entry $jid $t 0  tel_home      [::msgcat::mc "Home:"]
    pack_entry $jid $t 1  tel_work      [::msgcat::mc "Work:"]
    pack_entry $jid $t 2  tel_voice     [::msgcat::mc "Voice:"]
    pack_entry $jid $t 3  tel_fax       [::msgcat::mc "Fax:"]
    pack_entry $jid $t 4  tel_pager     [::msgcat::mc "Pager:"]
    pack_entry $jid $t 5  tel_msg       [::msgcat::mc "Message recorder:"]
    pack_entry $jid $t 6  tel_cell      [::msgcat::mc "Cell:"]
    pack_entry $jid $t 7  tel_video     [::msgcat::mc "Video:"]
    pack_entry $jid $t 8  tel_bbs       [::msgcat::mc "BBS:"]
    pack_entry $jid $t 9  tel_modem     [::msgcat::mc "Modem:"]
    pack_entry $jid $t 10 tel_isdn      [::msgcat::mc "ISDN:"]
    pack_entry $jid $t 11 tel_pcs       [::msgcat::mc "PCS:"]
    pack_entry $jid $t 12 tel_pref      [::msgcat::mc "Preferred:"]

    manage_focus $jid phones $t.tel_home $editable

    set location [$tab insert end location -text [::msgcat::mc "Location"]]

    set l [pack_frame $location.address [::msgcat::mc "Address"]]
    pack_entry $jid $l 0 address [::msgcat::mc "Address:"]
    pack_entry $jid $l 1 address2 [::msgcat::mc "Address 2:"]
    pack_entry $jid $l 2 city [::msgcat::mc "City:"]
    pack_entry $jid $l 3 state [::msgcat::mc "State:"]
    pack_entry $jid $l 4 pcode [::msgcat::mc "Postal code:"]
    pack_entry $jid $l 5 country [::msgcat::mc "Country:"]

    set g [pack_frame $location.geo [::msgcat::mc "Geographical position"]]
    pack_entry $jid $g 0 geo_lat [::msgcat::mc "Latitude:"]
    pack_entry $jid $g 1 geo_lon [::msgcat::mc "Longitude:"]

    manage_focus $jid location $l.address $editable

    set organization \
        [$tab insert end organization -text [::msgcat::mc "Organization"]]

    set d [pack_frame $organization.details [::msgcat::mc "Details"]]
    pack_entry $jid $d 0 orgname [string trim [::msgcat::mc "Name: "]]
    pack_entry $jid $d 1 orgunit [::msgcat::mc "Unit:"]

    set p [pack_frame $organization.personal \
                      [string trim [::msgcat::mc "Personal "]]]
    pack_entry $jid $p 0 title [::msgcat::mc "Title:"]
    pack_entry $jid $p 1 role [::msgcat::mc "Role:"]

    manage_focus $jid organization $d.orgname $editable

    # This strange trim is to distinguish different "about"s
    set about \
        [$tab insert end about -text [string trim [::msgcat::mc "About "]]]

    set b [pack_frame $about.bday [::msgcat::mc "Birthday"]]
    if {!$editable} {
        pack_entry $jid $b 0 bday [::msgcat::mc "Birthday:"]
    } else {
        pack_spinbox $jid $b 0 0 bdayyear 1900 1000000 [::msgcat::mc "Year:"]
        grid [Label $b.space0 -text " "] -row 0 -column 2
        pack_spinbox $jid $b 0 3 bdaymonth 0 12 [::msgcat::mc "Month:"]
        grid [Label $b.space1 -text " "] -row 0 -column 5
        pack_spinbox $jid $b 0 6 bdayday 0 31 [::msgcat::mc "Day:"]
    }

    set a [pack_frame $about.about [string trim [::msgcat::mc "About "]]]
    set sw [ScrolledWindow $a.sw -scrollbar vertical]
    if {!$editable} {
        Text $a.text -height 12 -wrap word
        ::richtext::config $a.text -using {url emoticon}
    } else {
        textUndoable $a.text -height 12 -wrap word
    }
    $sw setwidget $a.text
    set text [Wrapped $a.text]
    if {$editable} {
        bind $text <Key-Return> [bind Text <Key-Return>]
        bind $text <Key-Return> +break
        bind $text <Control-Key-Return> "
            ButtonBox::invoke [double% $bbox] default
            break
        "
    }
    fill_user_description $a.text userinfo(desc,$jid) $editable
    pack $sw -fill both -expand yes
    pack $a -fill both -expand yes
    trace add variable [namespace current]::userinfo(desc,$jid) write \
        [list userinfo::fill_user_description $a.text \
              userinfo(desc,$jid) $editable]
    bind $text <Destroy> \
        +[double% \
               [list trace remove variable [namespace current]::userinfo(desc,$jid) write \
               [list userinfo::fill_user_description $a.text \
                     userinfo(desc,$jid) $editable]]]
    set userinfo(descfield,$jid) $a.text

    manage_focus $jid about $b.bday[expr {$editable ? "year" : ""}] $editable

    if {!$editable} {
        set photo [$tab insert end photo -text [::msgcat::mc "Photo"]]
        if {[catch {
                $tab itemconfigure photo \
                     -raisecmd [list after idle \
                            [list [namespace current]::reconfigure_photo $jid]]
            }]} {
            bind $tab <<NotebookTabChanged>> \
                      [list [namespace current]::reconfigure_photo $jid]
        }
    } else {
        set photo [$tab insert end photo -text [::msgcat::mc "Photo"]]
    }

    set p [pack_frame $photo.photo [::msgcat::mc "Photo"]]
    set photo_img photo_$jid
    if {$photo_img ni [image names]} {
        image create photo $photo_img
    }
    if {!$editable} {
        pack_text_entry $jid $p 0 photo_extval [::msgcat::mc "URL:"]
        set sw [ScrolledWindow $p.sw]
        grid $sw -row 1 -column 0 -sticky wens -columnspan 2 -pady 0.5m
        grid rowconfig $p 1 -weight 1
        set sf [ScrollableFrame $p.sf]
        $sw setwidget $sf
        set l [label [$sf getframe].photo -image $photo_img -borderwidth 0]
        grid $l -row 0 -column 0
        bindscroll $l $sf
        bindscroll $sf $sf
    } else {
        if {![info exists userinfo(photo_use,$jid)]} {
            set userinfo(photo_use,$jid) none
        }

        Radiobutton $p.use_url -text [::msgcat::mc "URL"] \
            -value url -variable ::userinfo::userinfo(photo_use,$jid) \
            -command [list [namespace current]::enable_active_photo $p $jid]
        Radiobutton $p.use_image -text [::msgcat::mc "Image"] \
            -value image -variable ::userinfo::userinfo(photo_use,$jid) \
            -command [list [namespace current]::enable_active_photo $p $jid]
        Radiobutton $p.use_none -text [::msgcat::mc "None"] \
            -value none -variable ::userinfo::userinfo(photo_use,$jid) \
            -command [list [namespace current]::enable_active_photo $p $jid]
        if {![info exists ::userinfo::userinfo(photo_extval,$jid)]} {
            set ::userinfo::userinfo(photo_extval,$jid) ""
        }
        Entry $p.photo_url -textvariable ::userinfo::userinfo(photo_extval,$jid)
        Label $p.photo -image $photo_img

        grid $p.use_url -row 1 -column 0 -sticky w
        grid $p.photo_url  -row 1 -column 1 -sticky we
        grid $p.use_image -row 2 -column 0 -sticky w
        grid $p.photo  -row 3 -column 1 -sticky we
        grid $p.use_none -row 0 -column 0 -sticky w

        Button $p.loadimage -text [::msgcat::mc "Load image"] \
            -command [list userinfo::load_photo $jid $p.photo]
        grid $p.loadimage -row 2 -column 1 -sticky w
        grid columnconfig $p 1 -weight 1 -minsize 0
        #grid rowconfig $p 0 -weight 1
        grid rowconfig $p 1
        #grid rowconfig $p 1 -weight 1
        enable_active_photo $p $jid
        manage_focus $jid photo $p.use_none $editable

        trace add variable [namespace current]::userinfo(photo_use,$jid) write \
            [list userinfo::enable_active_photo $p $jid]
        bind $p <Destroy> \
            +[double% \
                [list trace remove variable \
                      [namespace current]::userinfo(photo_use,$jid) write \
                [list userinfo::enable_active_photo $p $jid]]]
    }


    if {!$editable} {
        $a.text configure -state disabled
    }

    hook::run userinfo_hook $tab $xlib $jid $editable

    set vjid [::xmpp::jid::removeResource $jid]
    if {[chat::is_groupchat [chat::chatid $xlib $vjid]]} {
        set vjid $jid
    }

    ::xmpp::sendIQ $xlib get \
        -query [::xmpp::xml::create vCard -xmlns vcard-temp] \
        -to $vjid \
        -command [list userinfo::parse_vcard $jid]

    catch {$tab compute_size}

    bind $w <Control-Prior> [list ifacetk::tab_move [double% $tab] -1]
    bind $w <Control-Next> [list ifacetk::tab_move [double% $tab] 1]

    $tab raise $top_page

    wm deiconify $w
}

proc userinfo::reconfigure_photo {jid} {
    set w [w_from_jid $jid]
    set tab $w.frame.tab

    if {![winfo exists $tab]} return
    if {[$tab raise] ne "photo"} return

    set p [$tab getframe photo].photo
    set sw $p.sw
    set sf $p.sf
    set l [$sf getframe].photo

    update

    if {![winfo exists $l]} return

    $sf configure \
        -areawidth [::tcl::mathfunc::max [winfo width $l] [winfo width $sw]] \
        -areaheight [::tcl::mathfunc::max [winfo height $l] [winfo height $sw]]
}

proc userinfo::client_page {tab xlib jid editable} {
    if {$editable} return

    set client [$tab insert end client -text [::msgcat::mc "Client"]]

    set c [pack_frame $client.client [::msgcat::mc "Client"]]
    pack_entry $jid $c 0 clientname [::msgcat::mc "Client:"]
    pack_entry $jid $c 1 clientversion [::msgcat::mc "Version:"]
    pack_entry $jid $c 2 os [::msgcat::mc "OS:"]

    set l [pack_frame $client.last [::msgcat::mc "Last activity or uptime"]]
    pack_entry $jid $l 0 lastseconds [::msgcat::mc "Interval:"]
    pack_entry $jid $l 1 lastdesc [::msgcat::mc "Description:"]

    set o [pack_frame $client.computer [::msgcat::mc "Time"]]
    pack_entry $jid $o 0 time [::msgcat::mc "Time:"]
    pack_entry $jid $o 1 tz   [::msgcat::mc "Time zone:"]
    pack_entry $jid $o 2 utc  [::msgcat::mc "UTC:"]

    # FIX -to ...
    request_iq version $xlib $jid
    request_iq time $xlib $jid
    request_iq last $xlib $jid
}

hook::add userinfo_hook [namespace current]::userinfo::client_page

proc userinfo::enable_active_photo {p jid args} {
    switch -- $::userinfo::userinfo(photo_use,$jid) {
        url {
            $p.photo_url configure -state normal
            $p.loadimage configure -state disabled
            focus $p.use_url
        }
        image {
            $p.photo_url configure -state disabled
            $p.loadimage configure -state normal
            focus $p.use_image
        }
        none {
            $p.photo_url configure -state disabled
            $p.loadimage configure -state disabled
            focus $p.use_none
        }
    }
}

proc userinfo::fill_user_description {txt descvar editable args} {
    variable userinfo

    if {[info exists $descvar] && [winfo exists $txt]} {
        set state [$txt cget -state]
        $txt configure -state normal
        $txt delete 0.0 end
        if {$editable} {
            $txt insert 0.0 [set $descvar]
        } else {
            ::richtext::render_message $txt [set $descvar] ""
            $txt delete {end - 1 char}
        }
        $txt configure -state $state
    }
}

proc userinfo::load_photo {jid l} {
    variable userinfo

    set photo_img photo_$jid
    if {![catch { package require Img }]} {
        set types [list [list [::msgcat::mc "JPEG images"] {.jpg .jpeg}] \
                        [list [::msgcat::mc "PNG images"] {.png}] \
                        [list [::msgcat::mc "GIF images"] {.gif}] \
                        [list [::msgcat::mc "All files"] {*}]]
    } elseif {![catch { package require tkpng }]} {
        set types [list [list [::msgcat::mc "GIF images"] {.gif}] \
                        [list [::msgcat::mc "PNG images"] {.png}] \
                        [list [::msgcat::mc "All files"] {*}]]
    } else {
        set types [list [list [::msgcat::mc "GIF images"] {.gif}] \
                        [list [::msgcat::mc "All files"] {*}]]
    }
    set filename [tk_getOpenFile -filetypes $types]
    if {$filename != ""} {
        if {[catch {create_image $photo_img -file $filename} res]} {
            if {[winfo exists .load_photo_error]} {
                destroy .load_photo_error
            }
            NonmodalMessageDlg .load_photo_error -aspect 50000 -icon error \
                -message [::msgcat::mc "Loading photo failed: %s." \
                                 $res]
        } else {
            set f [::open $filename]
            fconfigure $f -translation binary
            set userinfo(photo_binval,$jid) [read $f]
            binary scan $userinfo(photo_binval,$jid) H4 binsig
            switch -- $binsig {
                ffd8 { set userinfo(photo_type,$jid) "image/jpeg" }
                8950 { set userinfo(photo_type,$jid) "image/png" }
                4749 { set userinfo(photo_type,$jid) "image/gif" }
                default { set userinfo(photo_type,$jid) "image" }
            }
            close $f
            set userinfo(photo_use_binval,$jid) 1
        }
    }
}


proc userinfo::parse_vcard {jid status xml} {
    debugmsg userinfo "$status $xml"

    if {![string equal $status ok]} {
        return
    }

    ::xmpp::xml::split $xml tag xmlns attrs cdata subels

    foreach item $subels {
        parse_vcard_item $jid $item
    }
}


proc userinfo::parse_vcard_item {jid xml} {
    variable userinfo

    set w [w_from_jid $jid]
    ::xmpp::xml::split $xml tag xmlns attrs cdata subels

    # TODO:
    #  VERSION, ---
    #  ADR?,
    #  LABEL?,
    #  TEL?,    +?
    #  EMAIL?,
    #  MAILER?,
    #  TZ?,
    #  LOGO?,
    #  AGENT?,
    #  CATEGORIES?,
    #  NOTE?,
    #  PRODID?,
    #  REV?,
    #  SORT-STRING?,
    #  SOUND?,
    #  UID?,
    #  URL?,
    #  CLASS?,
    #  KEY?,

    switch -- $tag {
        FN       {set userinfo(fn,$jid)        $cdata}
        NICKNAME {set userinfo(nickname,$jid)  $cdata}
        N        {parse_vcard_n_item $jid $subels}
        PHOTO    {parse_vcard_photo_item $jid $subels}
        ADR      {parse_vcard_adr_item $jid $subels}
        TEL      {parse_vcard_tel_item $jid $subels}
        TEL      {set userinfo(telephone,$jid) $cdata}
        EMAIL    {
            set userinfo(email,$jid) $cdata
            parse_vcard_email_item $jid $subels
        }
        JABBERID {set userinfo(jabberid,$jid)  $cdata}
        GEO      {parse_vcard_geo_item $jid $subels}
        ORG      {parse_vcard_org_item $jid $subels}
        TITLE    {set userinfo(title,$jid)     $cdata}
        ROLE     {set userinfo(role,$jid)      $cdata}
        BDAY     {
            set userinfo(bday,$jid)      $cdata
            if {![catch {set bday [clock scan $cdata]}]} {
                set userinfo(bdayyear,$jid) [clock format $bday -format %Y]
                set userinfo(bdaymonth,$jid) [clock format $bday -format %m]
                set userinfo(bdayday,$jid) [clock format $bday -format %d]
            }
        }
        UID      {set userinfo(uid,$jid)       $cdata}
        URL      {set userinfo(url,$jid)       $cdata}
        DESC     {set userinfo(desc,$jid)      $cdata}
        default {debugmsg userinfo "Unknown vCard tag $tag"}
    }
}

proc userinfo::parse_vcard_email_item {jid items} {
    variable userinfo

    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        switch -- $tag {
            USERID {set userinfo(email,$jid) $cdata}
        }
    }
}

proc userinfo::parse_vcard_n_item {jid items} {
    variable userinfo

    set w [w_from_jid $jid]

    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        switch -- $tag {
            FAMILY {set userinfo(family,$jid) $cdata}
            GIVEN  {set userinfo(name,$jid)   $cdata}
            MIDDLE {set userinfo(middle,$jid) $cdata}
            PREFIX {set userinfo(prefix,$jid) $cdata}
            SUFFIX {set userinfo(suffix,$jid) $cdata}
            default {debugmsg userinfo "Unknown vCard <N/> subtag $tag"}
        }
    }
}

proc userinfo::parse_vcard_photo_item {jid items} {
    variable userinfo

    set w [w_from_jid $jid]

    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        switch -- $tag {
            BINVAL {
                catch {
                    set userinfo(photo_binval,$jid) [base64::decode $cdata]
                    set userinfo(photo_use,$jid) image
                    create_image photo_$jid -data $userinfo(photo_binval,$jid)
                    catch { reconfigure_photo $jid }
                } msg
            }
            EXTVAL {
                set userinfo(photo_extval,$jid) $cdata
                set userinfo(photo_use,$jid) url
            }
            TYPE {
                set userinfo(photo_type,$jid) $cdata
            }
            default {debugmsg userinfo "Unknown vCard <PHOTO/> subtag $tag"}
        }
    }
}

proc userinfo::parse_vcard_adr_item {jid items} {
    variable userinfo

    set w [w_from_jid $jid]

    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        # TODO:
        #  HOME?,
        #  WORK?,
        #  POSTAL?,
        #  PARCEL?,
        #  (DOM | INTL)?,
        #  PREF?,
        #  POBOX?,
        #  LOCALITY?,

        switch -- $tag {
            STREET   {set userinfo(address,$jid)  $cdata}
            EXTADD   {set userinfo(address2,$jid) $cdata}
            LOCALITY {set userinfo(city,$jid)     $cdata}
            REGION   {set userinfo(state,$jid)    $cdata}
            PCODE    {set userinfo(pcode,$jid)    $cdata}
            COUNTRY  {set userinfo(country,$jid)  $cdata}
            CTRY     {set userinfo(country,$jid)  $cdata}
            default  {debugmsg userinfo "Unknown vCard <ADR/> subtag $tag"}
        }
    }
}

proc userinfo::parse_vcard_tel_item {jid items} {
    variable userinfo

    set w [w_from_jid $jid]

    set types {}
    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        # TODO:
        #  HOME?,
        #  WORK?,
        #  VOICE?,
        #  FAX?,
        #  PAGER?,
        #  MSG?,
        #  CELL?,
        #  VIDEO?,
        #  BBS?,
        #  MODEM?,
        #  ISDN?,
        #  PCS?,
        #  PREF?,
        #  NUMBER

        switch -- $tag {
            HOME   {lappend types home}
            WORK   {lappend types work}
            VOICE  {lappend types voice}
            FAX    {lappend types fax}
            PAGER  {lappend types pager}
            MSG    {lappend types msg}
            CELL   {lappend types cell}
            VIDEO  {lappend types video}
            BBS    {lappend types bbs}
            MODEM  {lappend types modem}
            ISDN   {lappend types isdn}
            PCS    {lappend types pcs}
            PREF   {lappend types pref}
            NUMBER {
                foreach t $types {
                    set userinfo(tel_$t,$jid) $cdata
                }
            }
            default {debugmsg userinfo "Unknown vCard <TEL/> subtag $tag"}
        }
    }
}

proc userinfo::parse_vcard_geo_item {jid items} {
    variable userinfo

    set w [w_from_jid $jid]

    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        switch -- $tag {
            LAT {set userinfo(geo_lat,$jid) $cdata}
            LON {set userinfo(geo_lon,$jid) $cdata}
            default {debugmsg userinfo "Unknown vCard <ORG/> subtag $tag"}
        }
    }
}

proc userinfo::parse_vcard_org_item {jid items} {
    variable userinfo

    set w [w_from_jid $jid]

    # TODO: <!ELEMENT ORG (ORGNAME, ORGUNIT*)>

    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        switch -- $tag {
            ORGNAME {set userinfo(orgname,$jid) $cdata}
            ORGUNIT {set userinfo(orgunit,$jid) $cdata}
            default {debugmsg userinfo "Unknown vCard <ORG/> subtag $tag"}
        }
    }
}


proc userinfo::request_iq {type xlib jid} {
    if {[chat::is_groupchat [chat::chatid $xlib $jid]]} {
        set to $jid
    } else {
        set to [get_jid_of_user $xlib $jid]
    }
    ::xmpp::sendIQ $xlib get \
        -query [::xmpp::xml::create query -xmlns jabber:iq:$type] \
        -to $to \
        -command [list userinfo::parse_iq$type $jid]
}

proc userinfo::parse_iqversion {jid status xml} {
    debugmsg userinfo "$status $xml"

    if {![string equal $status ok]} {
        return
    }

    ::xmpp::xml::split $xml tag xmlns attrs cdata subels

    if {[string equal $xmlns jabber:iq:version]} {
        userinfo::parse_iqversion_item $jid $subels
    }
}

proc userinfo::parse_iqversion_item {jid items} {
    variable userinfo

    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        switch -- $tag {
            name    {set userinfo(clientname,$jid)    $cdata}
            version {set userinfo(clientversion,$jid) $cdata}
            os      {set userinfo(os,$jid)            $cdata}
            default {debugmsg userinfo "Unknown iq:version tag '$tag'"}
        }
    }
}

proc userinfo::parse_iqtime {jid status xml} {
    debugmsg userinfo "$status $xml"

    if {![string equal $status ok]} {
        return
    }

    ::xmpp::xml::split $xml tag xmlns attrs cdata subels

    if {[string equal $xmlns jabber:iq:time]} {
        userinfo::parse_iqtime_item $jid $subels
    }
}

proc userinfo::parse_iqtime_item {jid items} {
    variable userinfo

    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        switch -- $tag {
            utc     {set userinfo(utc,$jid)  $cdata}
            display {set userinfo(time,$jid) $cdata}
            tz      {set userinfo(tz,$jid)   $cdata}
            default {debugmsg userinfo "Unknown iq:time tag '$tag'"}
        }
    }
}

proc userinfo::parse_iqlast {jid status xml} {
    variable userinfo

    debugmsg userinfo "$status $xml"

    if {![string equal $status ok]} {
        return
    }

    ::xmpp::xml::split $xml tag xmlns attrs cdata subels

    if {[string equal $xmlns jabber:iq:last]} {
        set seconds [::xmpp::xml::getAttr $attrs seconds]
        if {[string is integer -strict $seconds]} {
            set userinfo(lastseconds,$jid) [format_time $seconds]
        } else {
            set userinfo(lastseconds,$jid) ""
        }
        set userinfo(lastdesc,$jid) $cdata
    }
}

proc userinfo::append_tag {varname tag cdata {subtags {}}} {
    upvar $varname tags

    if {$cdata != "" || $subtags != {}} {
        lappend tags [::xmpp::xml::create $tag \
                                -cdata $cdata \
                                -subelements $subtags]
    }
}

proc userinfo::send_vcard {xlib jid} {
    variable userinfo

    set w [w_from_jid $jid]

    set tags {}
    append_tag tags FN       $userinfo(fn,$jid)
    append_tag tags NICKNAME $userinfo(nickname,$jid)
    append_tag tags N ""     [make_n_item $jid]
    append_tag tags PHOTO "" [make_photo_item $jid]
    append_tag tags ADR ""   [make_adr_item $jid]
    lappend tags {*}[make_tel_item $jid]
    lappend tags {*}[make_email_item $jid]
    append_tag tags EMAIL    $userinfo(email,$jid)
    append_tag tags JABBERID $userinfo(jabberid,$jid)
    append_tag tags GEO ""   [make_geo_item $jid]
    append_tag tags ORG ""   [make_org_item $jid]
    append_tag tags TITLE    $userinfo(title,$jid)
    append_tag tags ROLE     $userinfo(role,$jid)
    if {($userinfo(bdaymonth,$jid) > 0) && ($userinfo(bdayday,$jid) > 0)} {
        set userinfo(bday,$jid) [format "%d-%02d-%02d" \
                [string trimleft $userinfo(bdayyear,$jid) "0"] \
                [string trimleft $userinfo(bdaymonth,$jid) "0"] \
                [string trimleft $userinfo(bdayday,$jid) "0"]]
    } else {
        set userinfo(bday,$jid) ""
    }
    append_tag tags BDAY     $userinfo(bday,$jid)
    append_tag tags UID      $userinfo(uid,$jid)
    append_tag tags URL      $userinfo(url,$jid)
    append_tag tags DESC     [$userinfo(descfield,$jid) get 0.0 "end -1 chars"]
    debugmsg userinfo $tags

    ::xmpp::sendIQ $xlib set \
        -query [::xmpp::xml::create vCard \
                        -xmlns vcard-temp \
                        -subelements $tags] \
        -to $jid \
        -command [list [namespace current]::check_answer $xlib $jid]
}

proc userinfo::check_answer {xlib jid res xml} {
    # TODO
}

proc userinfo::make_n_item {jid} {
    variable userinfo

    set tags {}
    append_tag tags FAMILY $userinfo(family,$jid)
    append_tag tags GIVEN  $userinfo(name,$jid)
    append_tag tags MIDDLE $userinfo(middle,$jid)
    append_tag tags PREFIX $userinfo(prefix,$jid)
    append_tag tags SUFFIX $userinfo(suffix,$jid)
    return $tags
}

proc userinfo::make_email_item {jid} {
    variable userinfo

    set tags {}
    if {$userinfo(email,$jid) != ""} {
        append_tag tags EMAIL "" \
            [list [::xmpp::xml::create INTERNET] \
                  [::xmpp::xml::create USERID \
                       -cdata $userinfo(email,$jid)]]
    }
    return $tags
}

proc userinfo::make_photo_item {jid} {
    variable userinfo

    set tags {}
    switch -- $userinfo(photo_use,$jid) {
        url {
            append_tag tags EXTVAL $userinfo(photo_extval,$jid)
        }
        image {
            if {[info exists userinfo(photo_binval,$jid)]} {
                if {[info exists userinfo(photo_type,$jid)]} {
                    append_tag tags TYPE $userinfo(photo_type,$jid)
                }
                append_tag tags \
                    BINVAL [base64::encode $userinfo(photo_binval,$jid)]
            }
        }
    }
    return $tags
}

proc userinfo::make_adr_item {jid} {
    variable userinfo

    set tags {}
    append_tag tags STREET   $userinfo(address,$jid)
    append_tag tags EXTADD   $userinfo(address2,$jid)
    append_tag tags LOCALITY $userinfo(city,$jid)
    append_tag tags REGION   $userinfo(state,$jid)
    append_tag tags PCODE    $userinfo(pcode,$jid)
    append_tag tags CTRY     $userinfo(country,$jid)
    return $tags
}

proc userinfo::make_tel_item {jid} {
    variable userinfo

    set tags {}
    foreach t {home work voice fax pager msg cell \
                   video bbs modem isdn pcs pref} {
        if {$userinfo(tel_$t,$jid) != ""} {
            append_tag tags TEL "" \
                [list [::xmpp::xml::create [string toupper $t]] \
                      [::xmpp::xml::create NUMBER \
                                    -cdata $userinfo(tel_$t,$jid)]]
        }
    }
    return $tags
}

proc userinfo::make_geo_item {jid} {
    variable userinfo

    set tags {}
    append_tag tags LAT $userinfo(geo_lat,$jid)
    append_tag tags LON $userinfo(geo_lon,$jid)
    return $tags
}

proc userinfo::make_org_item {jid} {
    variable userinfo

    set tags {}
    append_tag tags ORGNAME $userinfo(orgname,$jid)
    append_tag tags ORGUNIT $userinfo(orgunit,$jid)
    return $tags
}

proc userinfo::add_menu_item {m xlib jid} {
    $m add command -label [::msgcat::mc "Show info"] \
                   -command [list userinfo::open $xlib $jid]
}

hook::add chat_create_user_menu_hook userinfo::add_menu_item 60
hook::add chat_create_conference_menu_hook userinfo::add_menu_item 60
hook::add roster_create_groupchat_user_menu_hook userinfo::add_menu_item 60
hook::add roster_conference_popup_menu_hook userinfo::add_menu_item 60
hook::add roster_service_popup_menu_hook userinfo::add_menu_item 60
hook::add roster_jid_popup_menu_hook userinfo::add_menu_item 60
hook::add message_dialog_menu_hook userinfo::add_menu_item 60
hook::add search_popup_menu_hook userinfo::add_menu_item 60

hook::add postload_hook \
    [list disco::browser::register_feature_handler vcard-temp userinfo::open \
         -desc [list user [::msgcat::mc "User info"] \
         client [::msgcat::mc "User info"] \
         * [::msgcat::mc "Service info"]]]
hook::add postload_hook \
    [list disco::browser::register_feature_handler jabber:iq:last \
         userinfo::open_client \
         -desc [list user [::msgcat::mc "Last activity"] \
         client [::msgcat::mc "Last activity"] \
         * [::msgcat::mc "Uptime"]]]
hook::add postload_hook \
    [list disco::browser::register_feature_handler jabber:iq:time \
         userinfo::open_client \
         -desc [list * [::msgcat::mc "Time"]]]
hook::add postload_hook \
    [list disco::browser::register_feature_handler jabber:iq:version \
         userinfo::open_client \
         -desc [list * [::msgcat::mc "Version"]]]

# vim:ft=tcl:ts=8:sw=4:sts=4:et
