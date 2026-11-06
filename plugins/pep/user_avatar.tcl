# user_avatar.tcl --
#
#       Implementation of XEP-0084 "User Avatar"

if {[catch {package require Img}]} {
    return
}

package require sha1
package require base64
package require xmpp::pep

namespace eval avatar {
    variable data_node     urn:xmpp:avatar:data
    variable metadata_node urn:xmpp:avatar:metadata
    variable substatus

    variable options

    custom::defvar options(auto-subscribe) 0 \
        [::msgcat::mc "Auto-subscribe to other's user avatar notifications."] \
        -command [namespace current]::register_in_disco \
        -group PEP -type boolean

    pubsub::register_event_notification_handler $metadata_node \
            [namespace current]::process_avatar_notification
    hook::add user_avatar_pep_notification_hook \
            [namespace current]::notify_via_status_message

    hook::add finload_hook \
            [namespace current]::on_init 60
    hook::add connected_hook \
            [namespace current]::on_connect_disconnect
    hook::add disconnected_hook \
            [namespace current]::on_connect_disconnect
    hook::add roster_jid_popup_menu_hook \
            [namespace current]::add_roster_pep_menu_item
    hook::add userinfo_hook \
            [namespace current]::provide_userinfo

    variable cache_dir [file join $::configdir avatar_cache]
    if {![file isdirectory $cache_dir]} {
        file mkdir $cache_dir
    }

    variable fields {}

    disco::register_feature $data_node
    disco::register_feature $metadata_node
}

proc avatar::register_in_disco {args} {
    variable options
    variable metadata_node

    if {$options(auto-subscribe)} {
        disco::register_feature $metadata_node+notify
    } else {
        disco::unregister_feature $metadata_node+notify
    }
}

proc avatar::add_roster_pep_menu_item {m xlib jid} {
    set rjid [roster::find_jid $xlib $jid]

    if {$rjid == ""} {
         set rjid [::xmpp::jid::removeResource $jid]
    }

    set pm [pep::get_roster_menu_pep_submenu $m $xlib $rjid]

    set mm [menu $pm.avatar -tearoff no]
    $pm add cascade -menu $mm \
            -label [::msgcat::mc "User avatar"]

    $mm add command \
            -label [::msgcat::mc "Subscribe"] \
            -command [list [namespace current]::subscribe $xlib $rjid]
    $mm add command \
            -label [::msgcat::mc "Unsubscribe"] \
            -command [list [namespace current]::unsubscribe $xlib $rjid]

    hook::run roster_pep_user_avatar_menu_hook $mm $xlib $rjid
}

proc avatar::subscribe {xlib jid args} {
    variable metadata_node
    variable substatus

    set to [::xmpp::jid::removeResource $jid]
    set cmd [linsert $args 0 [namespace current]::subscribe_result $xlib $to]
    ::xmpp::pep::subscribe $xlib $to $metadata_node -command $cmd
    set substatus($xlib,$to) sent-subscribe
}

proc avatar::unsubscribe {xlib jid args} {
    variable metadata_node
    variable substatus

    set to [::xmpp::jid::removeResource $jid]
    set cmd [linsert $args 0 [namespace current]::unsubscribe_result $xlib $to]
    ::xmpp::pep::unsubscribe $xlib $to $metadata_node -command $cmd
    set substatus($xlib,$to) sent-unsubscribe
}

# Err may be one of: ok, error and abort
proc avatar::subscribe_result {xlib jid res child args} {
    variable substatus

    set cmd ""
    foreach {opt val} $args {
        switch -- $opt {
            -command {
                set cmd $val
            }
            default {
                return -code error "unknown option: $opt"
            }
        }
    }

    switch -- $res {
        ok {
            set substatus($xlib,$jid) from
        }
        error {
            set substatus($xlib,$jid) error
        }
        default {
            return
        }
    }

    if {$cmd != ""} {
        {*}$cmd $jid $res $child
    }
}

proc avatar::unsubscribe_result {xlib jid res child args} {
    variable substatus
    variable avatar
    variable fields

    set cmd ""
    foreach {opt val} $args {
        switch -- $opt {
            -command {
                set cmd $val
            }
            default {
                return -code error "unknown option: $opt"
            }
        }
    }

    if {[string equal $res ok]} {
        set substatus($xlib,$jid) none
        foreach f $fields {
            catch {unset avatar($f,$xlib,$jid)}
        }
    }

    if {$cmd != ""} {
        {*}$cmd $jid $res $child
    }
}

proc avatar::process_avatar_notification {xlib jid items} {
    variable metadata_node
    variable avatar
    variable fields

    foreach f $fields {
        set $f ""
    }
    set retract false
    set parsed  false

    foreach item $items {
        ::xmpp::xml::split $item tag xmlns attrs cdata subels

        switch -- $tag {
            retract {
                set retract true
            }
            default {
                foreach iavatar $subels {
                    ::xmpp::xml::split $iavatar stag sxmlns sattrs scdata ssubels

                    if {![string equal $stag avatar]} continue
                    if {![string equal $sxmlns $metadata_node]} continue

                    set parsed true

                    foreach i $ssubels {
                        ::xmpp::xml::split $i sstag ssxmlns ssattrs sscdata sssubels

                        if {$sstag in $fields} {
                            set $sstag $sscdata
                        }
                    }
                }
            }
        }
    }

    if {$parsed} {
        foreach f $fields {
            set avatar($f,$xlib,$jid) [set $f]
        }
        hook::run user_avatar_pep_notification_hook $xlib $jid 1
    } elseif {$retract} {
        foreach f $fields {
            catch {unset avatar($f,$xlib,$jid)}
        }
        hook::run user_avatar_pep_notification_hook $xlib $jid 0
    }
}

proc avatar::notify_via_status_message {xlib jid set} {
    set contact [::roster::itemconfig $xlib $jid -name]
    if {$contact == ""} {
        set contact $jid
    }

    if {!$set} {
        set msg [::msgcat::mc "%s's avatar is unset" $contact]
    } else {
        set msg [::msgcat::mc "%s's avatar is set" $contact]
    }

    set_status $msg
}

proc avatar::publish_data {xlib image args} {
    variable data_node
    variable cache_dir

    set callbacks {}
    foreach {opt val} $args {
        switch -- $opt {
            -command { set callbacks [list $val] }
        }
    }

    set data [$image data -format png]

    # Calculate SHA-1 hash (for new filename and item id)
    set hash [sha1::sha1 $data]

    set fd [open [file join $cache_dir $hash.png] wb]
    puts -nonewline $fd $data
    close $fd

    set args {}
    if {[llength $callbacks] > 0} {
        lappend args -command [linsert [lindex $callbacks 0] end $hash]
    }

    ::xmpp::pep::publishItem $xlib $data_node $hash \
            -payload [list [::xmpp::xml::create data \
                                    -xmlns $data_node \
                                    -cdata [base64::encode $data]]] \
            {*}$args


    return $hash
}

proc avatar::publish_metadata {xlib id args} {
    variable metadata_node
    variable cache_dir

    set callbacks {}
    foreach {opt val} $args {
        switch -- $opt {
            -command { set callbacks [list $val] }
        }
    }

    set filename [file join $cache_dir $id.png]
    if {![file exists $filename]} {
        return -code error "File $filename doesn't exist"
    }

    set size [file size $filename]

    set args {}
    if {[llength $callbacks] > 0} {
        lappend args -command [lindex $callbacks 0]
    }

    ::xmpp::pep::publishItem $xlib $metadata_node $id \
            -payload [list [::xmpp::xml::create metadata \
                                    -xmlns $metadata_node \
                                    -subelement [::xmpp::xml::create info \
                                                        -attrs [list bytes $size \
                                                                     id $id \
                                                                     type image/png]]]] \
            {*}$args
}

proc avatar::disable_metadata {xlib args} {
    variable metadata_node

    set callbacks {}
    foreach {opt val} $args {
        switch -- $opt {
            -command { set callbacks [list $val] }
        }
    }

    set args {}
    if {[llength $callbacks] > 0} {
        lappend args -command [lindex $callbacks 0]
    }

    ::xmpp::pep::publishItem $xlib $metadata_node stop \
            -payload [list [::xmpp::xml::create metadata \
                                    -xmlns $metadata_node]] \
            {*}$args
}

proc avatar::unpublish_data {xlib id args} {
    variable data_node

    set callbacks {}
    foreach {opt val} $args {
        switch -- $opt {
            -command { set callbacks [list $val] }
        }
    }

    set args {}
    if {[llength $callbacks] > 0} {
        lappend args -command [lindex $callbacks 0]
    }

    ::xmpp::pep::deleteItem $xlib $data_node $id -notify false {*}$args
}

proc avatar::unpublish_metadata {xlib id args} {
    variable metadata_node

    set callbacks {}
    foreach {opt val} $args {
        switch -- $opt {
            -command { set callbacks [list $val] }
        }
    }

    set args {}
    if {[llength $callbacks] > 0} {
        lappend args -command [lindex $callbacks 0]
    }

    ::xmpp::pep::deleteItem $xlib $metadata_node $id -notify true {*}$args
}

proc avatar::on_init {} {
    set m [pep::get_main_menu_pep_submenu]
    set mm [menu $m.avatar -tearoff $::ifacetk::options(show_tearoffs)]
    $m add cascade -menu $mm \
           -label [::msgcat::mc "User avatar"]
    $mm add command -label [::msgcat::mc "Upload or publish user avatar..."] \
            -state disabled \
            -command [namespace current]::show_upload_dialog
    $mm add command -label [::msgcat::mc "Unpublish user avatar..."] \
            -state disabled \
            -command [namespace current]::show_unpublish_dialog
    $mm add checkbutton -label [::msgcat::mc "Auto-subscribe to other's user avatar"] \
            -variable [namespace current]::options(auto-subscribe)
}

proc avatar::on_connect_disconnect {args} {
    set mm [pep::get_main_menu_pep_submenu].avatar
    set idx [expr {$::ifacetk::options(show_tearoffs)? 1 : 0}]

    switch -- [llength [connections]] {
        0 {
            $mm entryconfigure $idx -state disabled
            $mm entryconfigure [incr idx] -state disabled
        }
        default {
            $mm entryconfigure $idx -state normal
            $mm entryconfigure [incr idx] -state normal
        }
    }
}

proc avatar::show_upload_dialog {} {
    variable myjid

    set w .user_avatar
    if {[winfo exists $w]} {
        destroy $w
    }

    set xlibs [connections]
    if {[llength $xlibs] == 0} {
        NonmodalMessageDlg [epath] \
                -aspect 50000 \
                -icon error \
                -title [::msgcat::mc "Error"] \
                -message [::msgcat::mc "Publishing is only possible\
                                        while being online"]
        return
    }

    Dialog $w -title [::msgcat::mc "User avatar"] \
            -modal none -anchor e -default 0 -cancel 1

    set f [$w getframe]

    $w add -text [::msgcat::mc "Upload and publish"] \
           -command [list [namespace current]::do_upload $w $f \
                          [namespace current]::publish_result]
    $w add -text [::msgcat::mc "Upload"] \
           -command [list [namespace current]::do_upload $w $f \
                          [namespace current]::upload_result]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set connjids [list [::msgcat::mc "All"]]
    foreach xlib $xlibs {
        lappend connjids [connection_jid $xlib]
    }
    set myjid [lindex $connjids 0]

    Label $f.ccap -text [::msgcat::mc "Use connection:"]
    Combobox $f.conn -editable false \
            -values $connjids \
            -textvariable [namespace current]::myjid
    if {[llength $connjids] > 2} {
        grid $f.ccap -row 0 -column 0 -sticky e
        grid $f.conn -row 0 -column 1 -sticky ew
    }

    set preview [create_preview $f]
    set options [create_options $f]
    set loptions [Label $f.ldir -text [::msgcat::mc "Directory:"]]
    set list [create_listbox $f]

    grid $loptions -row 1 -column 0 -sticky e
    grid $options  -row 1 -column 1 -columnspan 2 -sticky w
    grid $list     -row 2 -column 0 -columnspan 2 -sticky nswe
    grid $preview  -row 2 -column 2

    grid columnconfigure $f 1 -weight 1
    grid columnconfigure $f 2 -minsize [winfo pixels $f 4c]
    grid rowconfigure    $f 2 -minsize [winfo pixels $f 4c] -weight 1

    $w draw
}

proc avatar::do_upload {w f command} {
    variable myjid

    set img avatar:img:$f

    if {[catch {image height $img}]} {
        destroy $w
        NonmodalMessageDlg [epath] \
            -aspect 50000 \
            -icon error \
            -title [::msgcat::mc "Error"] \
            -message [::msgcat::mc "User avatar image is not selected"]
        return
    }

    foreach xlib [connections] {
        if {[string equal $myjid [connection_jid $xlib]] || \
                [string equal $myjid [::msgcat::mc "All"]]} {
            publish_data $xlib $img -command [list $command $xlib $img]
            break
        }
    }

    unset myjid
    destroy $w
}

# $res is one of: ok, error, abort
proc avatar::publish_result {xlib img hash res child} {
    switch -- $res {
        error {
            set error [error_to_string $child]
        }
        default {
            publish_metadata $xlib $hash \
                    -command [namespace current]::publish2_result
            return
        }
    }

    NonmodalMessageDlg [epath] \
            -aspect 50000 \
            -icon error \
            -title [::msgcat::mc "Error"] \
            -message [::msgcat::mc "User avatar uploading failed: %s" $error]
}

# $res is one of: ok, error, abort
proc avatar::publish2_result {res child} {
    switch -- $res {
        error {
            set error [error_to_string $child]
        }
        default {
            return
        }
    }

    NonmodalMessageDlg [epath] \
            -aspect 50000 \
            -icon error \
            -title [::msgcat::mc "Error"] \
            -message [::msgcat::mc "User avatar publishing failed: %s" $error]
}

# $res is one of: ok, error, abort
proc avatar::upload_result {xlib img hash res child} {
    switch -- $res {
        error {
            set error [error_to_string $child]
        }
        default {
            return
        }
    }

    NonmodalMessageDlg [epath] \
            -aspect 50000 \
            -icon error \
            -title [::msgcat::mc "Error"] \
            -message [::msgcat::mc "User avatar uploading failed: %s" $error]
}

proc avatar::show_disabled_dialog {} {
    variable myjid

    set w .user_avatar
    if {[winfo exists $w]} {
        destroy $w
    }

    set xlibs [connections]
    if {[llength $xlibs] == 0} {
        NonmodalMessageDlg [epath] \
                -aspect 50000 \
                -icon error \
                -title [::msgcat::mc "Error"] \
                -message [::msgcat::mc "Disabling avatar is only possible\
                                        while being online"]
        return
    }

    Dialog $w -title [::msgcat::mc "User avatar"] \
            -modal none -anchor e -default 0 -cancel 1
    $w add -text [::msgcat::mc "Disable"] \
           -command [list [namespace current]::do_disable $w]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set f [$w getframe]

    set connjids [list [::msgcat::mc "All"]]
    foreach xlib $xlibs {
        lappend connjids [connection_jid $xlib]
    }
    set myjid [lindex $connjids 0]

    Label $f.ccap -text [::msgcat::mc "Use connection:"]
    Combobox $f.conn -editable false \
            -values $connjids \
            -textvariable [namespace current]::myjid

    if {[llength $connjids] > 2} {
        grid $f.ccap   -row 0 -column 0 -sticky e
        grid $f.conn   -row 0 -column 1 -sticky ew
    }

    grid columnconfigure $f 1 -weight 1

    if {[llength $xlibs] == 1} {
        do_disable $w
    } else {
        $w draw
    }
}

proc avatar::do_disable {w} {
    variable myjid

    foreach xlib [connections] {
        if {[string equal $myjid [connection_jid $xlib]] || \
                [string equal $myjid [::msgcat::mc "All"]]} {
            disable_metadata $xlib \
                    -command [namespace current]::disable_result
            break
        }
    }

    unset myjid
    destroy $w
}

# $res is one of: ok, error, abort
proc avatar::disable_result {res child} {
    switch -- $res {
        error {
            if {[lindex [error_type_condition $child] 1] == "item-not-found"} {
                return
            }
            set error [error_to_string $child]
        }
        default {
            return
        }
    }

    NonmodalMessageDlg [epath] \
            -aspect 50000 \
            -icon error \
            -title [::msgcat::mc "Error"] \
            -message [::msgcat::mc "Disabling user avatar failed: %s" $error]
}

proc avatar::provide_userinfo {notebook xlib jid editable} {
    variable avatar
    variable m2d
    variable ::userinfo::userinfo
    variable fields
    variable labels

    if {$editable} return

    set barejid [::xmpp::jid::removeResource $jid]
    if {![info exists avatar(alt,$xlib,$barejid)]} return

    foreach ff $fields {
        set userinfo(avatar$ff,$jid) $avatar($ff,$xlib,$barejid)
    }

    set f [pep::get_userinfo_dialog_pep_frame $notebook]
    set mf [userinfo::pack_frame $f.avatar [::msgcat::mc "User avatar"]]

    set row 0
    foreach ff $fields {
        userinfo::pack_entry $jid $mf $row avatar$ff $labels($ff)
        incr row
    }
}

proc avatar::create_options {path} {
    variable dirmenu
    if {![info exists dir($path)]} {
        set dir($path) [pwd]
    }
    set dirmenu($path) \
        [tk_optionMenu $path.dir [namespace current]::dir($path) $dir($path)]
    return $path.dir
}

proc avatar::change_dir {path list1 list2 args} {
    variable dir
    variable dirmenu

    $dirmenu($path) delete 0 end

    set volumes [file volumes]

    set dir($path) [file normalize $dir($path)]
    set dirlist [file split $dir($path)]
    set d [lindex $dirlist 0]
    foreach v $volumes {
        $dirmenu($path) add command -label $v \
                -command [list set [namespace current]::dir($path) $v]
        if {$v eq $d} {
            foreach p [lrange $dirlist 1 end] {
                set d [file join $d $p]
                $dirmenu($path) add command -label $d \
                        -command [list set [namespace current]::dir($path) $d]
            }
        }
    }

    fill_listbox $path $list1 $list2
}

proc avatar::create_preview {path} {
    return [Frame $path.preview]
}

proc avatar::create_listbox {path} {
    variable dir

    set f [Frame $path.f]

    set sw1 [ScrolledWindow $path.sw1 -scrollbar vertical \
                                      -auto none]
    set list1 [Listbox $sw1.dirs]
    $sw1 setwidget $list1

    set sw2 [ScrolledWindow $path.sw2 -scrollbar vertical \
                                      -auto none]
    set list2 [Listbox $sw2.images]
    $sw2 setwidget $list2

    grid $sw1 -row 0 -column 0 -in $f -sticky nswe
    grid $sw2 -row 0 -column 1 -in $f -sticky nswe

    grid columnconfigure $f 0 -weight 1
    grid columnconfigure $f 1 -weight 1
    grid rowconfigure $f 0 -weight 1

    change_dir $path $list1 $list2

    trace add variable [namespace current]::dir($path) write \
              [list [namespace current]::change_dir $path $list1 $list2]
    bind $list1 <Destroy> [double% [list trace remove variable [namespace current]::dir($path) write \
                               [list [namespace current]::change_dir $path $list1 $list2]]]

    bind $list1 <<ListboxSelect>> [double% [list [namespace current]::select_dir $path $list1]]
    bind $list2 <<ListboxSelect>> [double% [list [namespace current]::select_image $path $list2]]

    return $f
}

proc avatar::fill_listbox {path list1 list2} {
    variable dir

    set directory $dir($path)

    $list1 delete 0 end
    $list2 delete 0 end
    $list1 insert end ..
    foreach f [lsort -dictionary [glob -nocomplain \
                                       -tails \
                                       -directory $directory \
                                       -types {d} \
                                       *]] {
        $list1 insert end $f
    }
    foreach f [lsort -dictionary [glob -nocomplain \
                                       -tails \
                                       -directory $directory \
                                       -types {f l} \
                                       *.gif *.png *.jpg *.jpeg \
                                       *.bmp *.pcx]] {
        $list2 insert end $f
    }
}

proc avatar::select_dir {path list} {
    variable dir

    set selected [$list curselection]
    if {[llength $selected] == 0} return

    $list selection clear 0 end
    set name [$list get [lindex $selected 0]]
    set dir($path) [file join $dir($path) $name]
}

proc avatar::select_image {path list} {
    set selected [$list curselection]
    if {[llength $selected] == 0} return

    set name [$list get [lindex $selected 0]]
    after idle [list [namespace current]::preview $path $name]
}

proc avatar::preview {path name} {
    variable dir

    set directory $dir($path)
    set tmp avatar:tmp:$path
    set img avatar:img:$path
    set preview avatar:preview:$path
    set l $path.preview.img

    catch { destroy $l }
    catch { image delete $img }
    catch { image delete $tmp }

    if {[catch {
             image create photo $tmp -file [file join $directory $name]
         }]} {
        return
    }

    image create photo $img
    $img blank
    image create photo $preview
    $preview blank
    set args {}
    if {[set w [image width $tmp]] > 128} {
        set x1 [expr {($w - 128)/2}]
        set x2 [expr {$x1 + 128}]
    } else {
        set x1 0
        set x2 $w
    }
    if {[set h [image height $tmp]] > 128} {
        set y1 [expr {($h - 128)/2}]
        set y2 [expr {$y1 + 128}]
    } else {
        set y1 0
        set y2 $h
    }
    $img copy $tmp -from $x1 $y1 $x2 $y2
    $preview copy $tmp -from $x1 $y1 $x2 $y2 -zoom $::icons_scale $::icons_scale
    image delete $tmp

    Label $l -image $preview -borderwidth 0
    pack $l
}

# vim:ts=8:sw=4:sts=4:et
