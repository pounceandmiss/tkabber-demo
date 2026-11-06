# gpgme.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements signing
#       and encrypting messages and presence updates using GnuPG (XEP-0027).

namespace eval ::ssj {
    variable NS
    array set NS [list \
        signed    "jabber:x:signed" \
        encrypted "jabber:x:encrypted" \
    ]
}

#############################################################################
# Draw icons aside encrypted messages even if no GPG support

proc ::ssj::draw_encrypted {chatid from type body x} {
    variable NS

    set chatw [chat::chat_win $chatid]

    if {![hook::is_flag rewrite_outgoing_message_hook encrypted]} {
        $chatw image create end -image gpg/encrypted

        hook::set_flag rewrite_outgoing_message_hook encrypted
    } else {
        foreach xe $x {
            ::xmpp::xml::split $xe tag xmlns attrs cdata subels

            if {$xmlns ne $NS(encrypted)} {
                continue
            }

            if {$cdata eq "" || [info commands ::ssj::encrypted:input] eq ""} {
                $chatw image create end -image gpg/badencrypted
            } else {
                # We already deciphered it in rewrite_message_hook
                $chatw image create end -image gpg/encrypted
            }
            break
        }
    }
}

hook::add draw_message_hook ::ssj::draw_encrypted 5

#############################################################################

proc ::ssj::process_x_encrypted {rowvar bodyvar f x xlib from id type replyP} {
    variable NS
    upvar 2 $rowvar row
    upvar 2 $bodyvar body

    if {!$replyP || $type eq "error"} {
        return
    }

    foreach xa $x {
        ::xmpp::xml::split $xa tag xmlns attrs cdata subels

        if {$xmlns ne $NS(encrypted)} continue

        set lb [join [lrange [split $f .] 0 end-1] .].title.encrypted
        if {[winfo exists $lb]} {
            destroy $lb
        }

        if {$cdata eq "" || [info commands ::ssj::encrypted:input] eq ""} {
            Label $lb -image gpg/badencrypted
        } else {
            # We already deciphered it in rewrite_message_hook
            Label $lb -image gpg/encrypted
        }
        grid $lb -row 1 -column 3 -sticky e
    }

    return
}

hook::add message_process_x_hook ::ssj::process_x_encrypted 21

#############################################################################

if {[catch {package require gpg}]} {
    debugmsg ssj "unable to load the GPG package, so no crypto!"
    return
}

namespace eval ::ssj {
    variable options

    custom::defgroup GPG [::msgcat::mc "GPG options (signing and\
                                        encryption)."] \
        -group Tkabber

    custom::defvar options(one-passphrase) 1 \
        [::msgcat::mc "Use the same passphrase for signing and\
                       decrypting messages."] \
        -group GPG -type boolean

    custom::defvar options(sign-traffic) 0 \
        [::msgcat::mc "GPG-sign outgoing presence updates."] \
        -group GPG -type boolean

    custom::defvar options(sign-personal-messages) 0 \
        [::msgcat::mc "GPG-sign outgoing personal messages."] \
        -group GPG -type boolean

    custom::defvar options(sign-groupchat-messages) 0 \
        [::msgcat::mc "GPG-sign outgoing groupchat messages."] \
        -group GPG -type boolean

    custom::defvar options(encrypt-traffic) 0 \
        [::msgcat::mc "GPG-encrypt outgoing messages where possible."] \
        -group GPG -type boolean

    custom::defvar options(prevent-replay-attack) 1 \
        [::msgcat::mc "Add the recipient's JID and timestamp to the\
                       GPG-signed or encrypted outgoing messages. This\
                       prevents replay attacks."] \
        -group GPG -type boolean

    custom::defvar options(key) "" \
        [::msgcat::mc "Use specified key ID for signing and decrypting\
                       messages."] \
        -group GPG -type string

    custom::defvar options(display_sig_warnings) 1 \
        [::msgcat::mc "Display warning dialogs when signature\
                       verification fails."] \
        -group GPG -type boolean
}


package require base64


namespace eval ::ssj {
    variable ctx
    variable e4me
    variable j2k
    variable options
    variable passphrase
    variable s2e
    variable f2s
    variable signers
    variable warnings
    variable gpg_error_id 0

    array set ctx {}

    array set j2k {}

    array set options {}

    array set passphrase {}

    array set s2e \
          [list none       [::msgcat::mc "No information available"] \
                bad        [::msgcat::mc "Invalid signature"] \
                nokey      [::msgcat::mc "Signature not processed due\
                                          to missing key"] \
                nosig      [::msgcat::mc "Malformed signature block"] \
                error      [::msgcat::mc "Error in signature processing"] \
                diff       [::msgcat::mc "Multiple signatures having different\
                                          authenticity"] \
                expired    [::msgcat::mc "The signature is good but has\
                                          expired"] \
                expiredkey [::msgcat::mc "The signature is good but the key\
                                          has expired"]]

    array set f2s \
          [list unchanged       [::msgcat::mc "not actually changed"] \
                new_key         [::msgcat::mc "entirely new key"] \
                new_uids        [::msgcat::mc "new user IDs"] \
                new_sigs        [::msgcat::mc "new signatures"] \
                new_subkeys     [::msgcat::mc "new subkeys"] \
                new_private_key [::msgcat::mc "contains private key"]]

    unset -nocomplain warnings
    array set warnings {}

    variable signedid 0
}


proc ::ssj::once_only {xlib} {
    global env
    variable options
    variable ctx

    debugmsg ssj "ONCE_ONLY $xlib"

    if {[info exists ctx($xlib)] && $ctx($xlib) ne ""} {
        return
    }

    set ctx($xlib) [gpg::new]
    $ctx($xlib) set -property armor \
                    -value    true
    $ctx($xlib) set -property encoding \
                    -value    utf-8

    # Setting the passphrase-callback property doesn't prevent from using
    # pinentry via gpg-agent. passphrase-callback will just be ignored in
    # that case. It will only be used if the agent allows loopback pinentry
    # mode (allow-loopback-pinentry in ~/.gnupg/gpg-agent.conf) for gpg 2.1.

    # So, passphrase-callback is not ignored for:

    # 1. gpg 1.4 without GPG_AGENT_INFO set to something sensible
    # 2. gpg 2.1 with agent that allow using loopback pinentry

    $ctx($xlib) set -property passphrase-callback \
                    -value    [list ::ssj::passphrase $xlib]

    set pattern [connection_bare_jid $xlib]

    set firstP 1
    if {$options(key) ne ""} {
        set patterns [list $options(key)]
    } else {
        set patterns {}
    }
    lappend patterns $pattern ""
    foreach p $patterns {
        set args [list -secretonly true]
        if {$p ne ""} {
            lappend args -patterns [list $p]
        }
        set keys [$ctx($xlib) list-keys {*}$args]
        if {[llength $keys] > 0} {
            break
        }
        if {$p eq ""} {
            return
        }
        set firstP 0
    }

    switch -- [llength $keys] {
        0 {
            return
        }
        1 {
            if {$firstP} {
                e4meP $xlib $keys
                return
            }
        }
    }

    set dw .selectkey[psuffix $xlib]
    catch {destroy $dw}

    set titles {}
    set balloons {}
    foreach key $keys {
        set key_info [$ctx($xlib) info-key -key $key]
        foreach {k v} $key_info {
            if {$k eq "email"} {
                lappend titles $key $v
                lappend balloons $key [key_balloon_text $key_info]
                break
            }
        }
        foreach {k v} [$ctx($xlib) info-key -key $key] {
            if {$k ne "subkeys"} {
                continue
            }

            foreach subkey $v {
                foreach {k1 v1} $subkey {
                    if {$k1 eq "email"} {
                        lappend titles $key $v1
                        lappend balloons $key [key_balloon_text $subkey]
                        break
                    }
                }
            }
        }
    }

    CbDialog $dw [::msgcat::mc "Select Key for Signing %s Traffic" $pattern] \
        [list [::msgcat::mc "Select"] [list ::ssj::once_only_aux $dw $xlib] \
              [::msgcat::mc "Cancel"] [list destroy $dw]] \
        ::ssj::selectkey[psuffix $xlib] $titles $balloons \
        -modal local
}

proc ::ssj::keyid {fingerprint} {
    string range $fingerprint end-15 end
}

proc ::ssj::key_balloon_text {key} {
    array set params $key
    if {[catch {format "%d%s/%s %s" $params(length)          \
                       [string range $params(algorithm) 0 0]   \
                       [keyid $params(keyid)] \
                       [clock format $params(created)          \
                                     -format "%Y-%m-%d"]} text]} {
        return ""
    }

    foreach {k v} $key {
        switch -- $k {
            userid {
                append text [format "\n\t%s" $v]
            }
        }
    }
    return $text
}

proc ::ssj::once_only_aux {dw xlib} {
    variable selectkey[psuffix $xlib]

    set keys {}
    foreach key [array names selectkey[psuffix $xlib]] {
        if {[set selectkey[psuffix $xlib]($key)]} {
            lappend keys $key
        }
    }

    destroy $dw
    unset -nocomplain selectkey[psuffix $xlib]

    if {[llength $keys] > 0} {
        e4meP $xlib $keys
    }
}


proc ::ssj::passphrase {xlib data} {
    variable passphrase
    variable options

    array set params $data

    if {!$options(one-passphrase)} {
        set params(keyid) $params(subkeyid)
    }
    set keyid $params(keyid)

    if {$params(hint) eq "enter" &&
            [info exists passphrase($keyid)] && $passphrase($keyid) ne ""} {
        return $passphrase($keyid)
    }

    set pw .passphrase[psuffix $xlib]
    if {[winfo exists $pw]} {
        destroy $pw
    }

    set title [::msgcat::mc "Please enter passphrase"]
    switch -- $params(hint) {
        enter {}
        try_again {
            set title [::msgcat::mc "Please try again"]
        }
        default {
            append title ": " $params(hint)
        }
    }
    Dialog $pw -title $title -anchor e -default 0 -cancel 1

    set pf [$pw getframe]
    grid columnconfigure $pf 1 -weight 1

    foreach {k v} [list keyid  [::msgcat::mc "Key ID"] \
                        userid [::msgcat::mc "User ID"]] {
        Label $pf.l$k -text ${v}:
        Entry $pf.$k
        $pf.$k insert 0 $params($k)
        if {[string length $params($k)] <= 72} {
            $pf.$k configure -width 0
        }
        #set bgcolor [lindex [$pf.$k configure -background] 4]
        #$pf.$k configure -state readonly -readonlybackground $bgcolor
        $pf.$k:cmd configure -state readonly
    }

    Label $pf.lpassword -text [::msgcat::mc "Passphrase:"]
    Entry $pf.password  \
          -textvariable ::ssj::passphrase($xlib,$keyid) \
          -show *
    set passphrase($xlib,$keyid) ""

    grid $pf.lkeyid    -row 0 -column 0 -sticky e
    grid $pf.keyid     -row 0 -column 1 -sticky ew
    grid $pf.luserid   -row 1 -column 0 -sticky e
    grid $pf.userid    -row 1 -column 1 -sticky ew
    grid $pf.lpassword -row 2 -column 0 -sticky e
    grid $pf.password  -row 2 -column 1 -sticky ew

    $pw add -text [::msgcat::mc "OK"] -command [list $pw enddialog 0]
    $pw add -text [::msgcat::mc "Cancel"] -command [list $pw enddialog 1]

    set abort [$pw draw $pf.password]

    destroy $pw

    if {!$abort} {
        set passphrase($keyid) $passphrase($xlib,$keyid)
        unset passphrase($xlib,$keyid)
        return $passphrase($keyid)
    } else {
        return -code break
    }
}

proc ::ssj::armor:encode {text} {
    if {[set x [string first "\n\n" $text]] >= 0} {
        set text [string range $text [expr {$x + 2}] end]
    }
    if {[set x [string first "\n-----" $text]] > 0} {
        set text [string range $text 0 [expr {$x - 1}]]
    }

    return $text
}

proc ::ssj::armor:decode {text} {
    return "-----BEGIN PGP MESSAGE-----\n\n$text\n-----END PGP MESSAGE-----"
}

proc ::ssj::signed:input {xlib from signature data what} {
    variable ctx
    variable j2k
    variable s2e
    variable warnings
    variable options

    once_only $xlib

    if {[catch {$ctx($xlib) verify \
                            -input     $data  \
                            -signature [armor:decode $signature]} result]} {
        debugmsg ssj "verify processing error ($xlib): $result ($from)"

        if {![info exists warnings(verify-traffic,$xlib)]} {
            set warnings(verify-traffic,$xlib) 1
            hook::run gpg_input_error_hook $xlib $from software \
                [::msgcat::mc "Error in signature verification software: %s." \
                    $result]
        }

        set params(reason) $result

        return [array get params]
    }

    debugmsg ssj "VERIFY: $xlib $from ($data); $result"

    array set params $result
    set result $params(status)

    set signatures {}
    foreach signature $params(signatures) {
        unset -nocomplain sparams
        array set sparams $signature

        if {[info exists sparams(key)]} {
            set sparams(key) [$ctx($xlib) info-key -key $sparams(key)]
            foreach {k v} $sparams(key) {
                switch -- $k {
                    keyid {
                        set j2k($from) $v
                        break
                    }
                    subkeys {
                        foreach subkey $v {
                            unset -nocomplain kparams
                            array set kparams $subkey
                            if {[info exists kparams(keyid)]} {
                                set j2k($from) $kparams(keyid)
                                break
                            }
                        }
                    }
                }
            }
        }

        lappend signatures [array get sparams]
    }
    unset -nocomplain params
    array set params [list signatures $signatures]

    if {$result ne "good"} {
        if {[info exists s2e($result)]} {
            set result $s2e($result)
        }
        set params(reason) $result

        if {$options(display_sig_warnings) &&
                        ![info exists warnings(verify,$from)]} {
            set warnings(verify,$from) 1
            if {[info exists j2k($from)]} {
                set message [::msgcat::mc "%s purportedly signed by %s\
                                           using key 0x%s can't be\
                                           verified: %s." \
                                          $what $from \
                                          [keyid $j2k($from)] \
                                          $result]
            } else {
                set message [::msgcat::mc "%s purportedly signed by %s\
                                           can't be verified: %s." \
                                          $what $from $result]
            }
            hook::run gpg_input_error_hook $xlib $from $what $message
        }
    }

    return [array get params]
}

# ::ssj::signed:output --
#
# Result:
#       "" if signing is disabled for the given JID
#       'Armored signature' if signing is enabled and succeeded
#       Error if something went wrong

proc ::ssj::signed:output {xlib data args} {
    variable ctx
    variable options
    variable warnings
    variable gpg_error_id

    if {[llength $args] == 0} {
        # Presence
        if {!$options(sign-traffic)} return
    } else {
        # Message
        set to [lindex $args 0]
        set chatid [chat::chatid $xlib $to]
        if {[chat::is_groupchat $chatid]} {
            if {!$options(sign-groupchat-messages)} return
        } else {
            if {!$options(sign-personal-messages)} return
        }
    }

    once_only $xlib

    if {[catch {$ctx($xlib) sign -input $data \
                                 -mode  detach} result]} {
        set options(sign-traffic) 0
        set options(sign-personal-messages) 0
        set options(sign-groupchat-messages) 0

        debugmsg ssj "signature processing error ($xlib): $result ($data)"

        if {[llength $args] == 0} {
            set buttons ok
            set cancel 0
            set message [::msgcat::mc "Unable to sign presence information:\
                                       %s.\n\nPresence will be sent, but\
                                       signing traffic is now disabled." \
                                      $result]
        } else {
            set buttons {ok cancel}
            set cancel 1
            set message [::msgcat::mc "Unable to sign message body:\
                                       %s.\n\nSigning traffic is now\
                                       disabled.\n\nSend it WITHOUT a\
                                       signature?"\
                                      $result]
        }

        incr gpg_error_id
        if {[MessageDlg .sign_error$gpg_error_id \
                        -aspect 50000 -icon error -type user \
                        -buttons $buttons -default 0 -cancel $cancel \
                        -message $message]} {
            # Return error to disable sending the message
            error ""
        }

        return
    }
    set result [armor:encode $result]

    debugmsg ssj "SIGN: $data; $result"
    whichkeys $xlib sign

    return $result
}

proc ::ssj::signed:info {pinfo} {
    set text ""
    array set params $pinfo

    foreach {k v} $pinfo {
        if {$k ne "signatures"} {
            if {$v ne ""} {
                append text [format "%s: %s\n" $k $v]
            }
        }
    }

    if {[info exists params(signatures)]} {
        foreach signature $params(signatures) {
            set info ""
            set addrs ""
            set s ""
            foreach {k v} $signature {
                switch -- $k {
                    key {
                        foreach {k v} $v {
                            if {$k ne "subkeys"} {
                                continue
                            }
                            foreach subkey $v {
                                unset -nocomplain sparams
                                array set sparams $subkey
                                if {[info exists sparams(email)]} {
                                    append addrs $s $sparams(email)
                                    set s "\n     "
                                }
                            }
                        }
                    }
                    created {
                        append info "created: [clock format $v]\n"
                    }
                    expires {
                        append info "expires: [clock format $v]\n"
                    }
                    fingerprint {
                        append info [format "keyid: 0x%s\n" [keyid $v]]
                        append info [format "%s: %s\n" $k $v]
                    }
                    default {
                        if {$v ne ""} {
                            append info [format "%s: %s\n" $k $v]
                        }
                    }
                }
            }

            if {$addrs ne ""} {
                set info "email: $addrs\n$info"
            }
            if {$info ne ""} {
                append text "\n" [string trimright $info]
            }
        }
    }

    return [string trimleft $text]
}

proc ::ssj::signed:Label {lb xlib jid pinfo} {
    set rjid [::muc::get_real_jid $xlib $jid]
    if {$rjid eq ""} {
        set rjid [::xmpp::jid::removeResource $jid]
    } else {
        set rjid [::xmpp::jid::removeResource $rjid]
    }

    array set params $pinfo

    set checks {}
    set trust 0
    foreach signature $params(signatures) {
        set emails {}
        set valid 0
        foreach {k v} $signature {
            switch -- $k {
                key {
                    foreach {k v} $v {
                        if {$k ne "subkeys"} {
                            continue
                        }
                        foreach subkey $v {
                            unset -nocomplain sparams
                            array set sparams $subkey
                            if {[info exists sparams(email)]} {
                                lappend emails $sparams(email)
                            }
                        }
                    }
                }
                validity {
                    switch -- $v {
                        ultimate -
                        full -
                        marginal {
                            set valid 1
                        }
                        never -
                        undefined -
                        unknown -
                        default {
                            set valid 0
                        }
                    }
                }
            }
        }
        if {$valid && $rjid in $emails} {
            set trust 1
            break
        }
    }

    if {[info exists params(reason)]} {
        set args [list -image gpg/badsigned]
    } elseif {$trust} {
        set args [list -image gpg/signed]
    } else {
        set args [list -image gpg/vsigned]
    }

    set info [signed:info $pinfo]
    if {$info ne ""} {
        lappend args -helptext $info -helptype balloon
    }

    Label $lb {*}$args \
          -cursor arrow \
          -padx 0 \
          -pady 0 \
          -borderwidth 0 \
          -highlightthickness 0

    if {[info exists params(reason)] && $params(reason) eq "nokey"} {
        bind $lb <<ContextMenu>> [list ::ssj::signed:popup [double% $pinfo]]
    }
    return $lb
}

###############################################################################

proc ::ssj::signed:popup {pinfo} {
    set m .signed_label_popupmenu
    if {[winfo exists $m]} {
        destroy $m
    }
    menu $m -tearoff 0
    $m add command -label [::msgcat::mc "Fetch GPG key"] \
                   -command [list ::ssj::fetchkeys $pinfo]
    tk_popup $m [winfo pointerx .] [winfo pointery .]
}

proc ::ssj::signed:user_menu {m xlib jid} {
    variable signed

    if {[info exists signed($xlib,$jid)]} {
        $m add command -label [::msgcat::mc "Fetch GPG key"] \
                       -command [list ::ssj::fetchkeys $xlib $signed($xlib,$jid)]
    } else {
        $m add command -label [::msgcat::mc "Fetch GPG key"] \
                       -state disabled
    }
}

hook::add chat_create_user_menu_hook ::ssj::signed:user_menu 78
hook::add roster_create_groupchat_user_menu_hook ::ssj::signed:user_menu 78
hook::add message_dialog_menu_hook ::ssj::signed:user_menu 78

###############################################################################

proc ::ssj::fetchkeys {xlib pinfo} {
    variable ctx

    array set params $pinfo

    set keyids {}
    foreach signature $params(signatures) {
        unset -nocomplain sparams
        array set sparams $signature

        if {[info exists sparams(keyid)]} {
            lappend keyids $sparams(keyid)
        }
    }

    $ctx($xlib) import -keys $keyids -command [list ::ssj::processFetchkeys $xlib]
}

proc ::ssj::processFetchkeys {xlib status output} {
    variable ctx
    variable gpg_error_id

    if {$status ne "ok"} {
        NonmodalMessageDlg .keyfetch_error[incr gpg_error_id] \
            -aspect 50000 -icon error \
            -message "Key fetch error\n\n$output"
    } else {
        # In case of success let's update the affected keys info

        set patterns {}
        foreach {fp status} $output {
            lappend patterns $fp
        }
        $ctx($xlib) list-keys -patterns $patterns \
                -command [list ::ssj::reportFetchkeys $xlib $output]
    }
}

proc ::ssj::reportFetchkeys {xlib output status keys} {
    variable ctx
    variable gpg_error_id
    variable f2s

    set text ""
    foreach {fp info} $output {
        unset -nocomplain status
        array set status $info
        if {$status(status) ne "ok"} {
            append text "\n0x[keyid $fp]: $status(reason)"
        } else {
            set flags {}
            foreach f $status(flags) {
                lappend flags $f2s($f)
            }
            set tflags [join $flags ",\n\t"]
            if {[catch {$ctx($xlib) info-key -key $fp} keyinfo]} {
                append text "\n0x[keyid $fp]:\n\t$tflags"
            } else {
                set uids ""
                foreach {k v} $keyinfo {
                    if {$k eq "userid"} {
                        append uids "\n    $v"
                    }
                }
                append text "\n0x[keyid $fp]$uids:\n\t$tflags"
            }
        }
    }

    NonmodalMessageDlg .keyfetch_ok[incr gpg_error_id] \
            -aspect 50000 -icon info \
            -message "Key fetch result\n$text"
}

###############################################################################

proc ::ssj::rewrite_message_body \
     {vxlib vfrom vid vtype vis_subject vsubject
      vbody verr vthread vpriority vx} {
    variable NS
    upvar 2 $vxlib xlib
    upvar 2 $vfrom from
    upvar 2 $vbody body
    upvar 2 $vx x

    set badenc 0
    set xs {}
    foreach xe $x {
        ::xmpp::xml::split $xe tag xmlns attrs cdata subels

        if {$xmlns ne $NS(encrypted)} {
            lappend xs $xe
        } elseif {$cdata eq ""} {
            # in case the sender didn't check the exit code from gpg we ignore
            # jabber:x:encrypted
        } elseif {[catch {ssj::encrypted:input $xlib $from $cdata} msg]} {
            set body [::msgcat::mc ">>> Unable to decipher data: %s <<<" $msg]
            # Add empty x tag to show problems with gpg
            lappend xs [::xmpp::xml::create x -xmlns $NS(encrypted)]
            set badenc 1
        } else {
            set body $msg
            lappend xs $xe
        }
    }

    set x $xs

    if {$badenc} {
        # if decryption failed, then remove signature. It can't be correct.

        set xs {}
        foreach xe $x {
            ::xmpp::xml::split $xe tag xmlns attrs cdata subels

            if {$xmlns ne $NS(signed)} {
                lappend xs $xe
            }
        }
        set x $xs
    } else {
        # Check the signature before some other plugin rewrites
        # the message body

        set xs {}
        foreach xe $x {
            ::xmpp::xml::split $xe tag xmlns attrs cdata subels

            if {$xmlns ne $NS(signed)} {
                lappend xs $xe
            } else {
                # in case the sender didn't check the exit code from gpg...
                if {$cdata ne ""} {
                    # Create special tag with signature info
                    lappend xs [::xmpp::xml::create "" -xmlns $NS(signed) \
                                    -attrs [signed:input $xlib $from \
                                                $cdata $body \
                                                [::msgcat::mc "Message body"]]]
                }
            }
        }
        set x $xs
    }
    return
}

hook::add rewrite_message_hook ::ssj::rewrite_message_body 70

###############################################################################

proc ::ssj::encrypted:input {xlib from data} {
    variable ctx
    variable warnings
    variable gpg_error_id

    once_only $xlib

    if {[catch {$ctx($xlib) decrypt -input [armor:decode $data]} result]} {
        debugmsg ssj "decryption processing error ($xlib): $result ($from)"

        if {![info exists warnings(decrypt,$from)]} {
            set warnings(decrypt,$from) 1
            incr gpg_error_id
            after idle [list NonmodalMessageDlg .decrypt_error$gpg_error_id \
                                    -aspect 50000 -icon error \
                                    -message [::msgcat::mc \
                                                    "Data purportedly sent by\
                                                     %s can't be\
                                                     deciphered.\n\n%s." \
                                                    $from $result]]
        }

        error $result
    }

    debugmsg ssj "DECRYPT: $xlib; $from; $result"

    array set params $result
    return $params(plaintext)
}

# ::ssj::encrypted:output --
#
# Result:
#       "" if encrypting is disabled for the given JID
#       'enciphered data' if encrypting is enabled and succeeded
#       error if something went wrong

proc ::ssj::encrypted:output {xlib data to} {
    variable ctx
    variable e4me
    variable j2k
    variable options
    variable gpg_error_id
    variable groupchat_encrypt

    if {$data eq ""} {
        return
    }

    if {![encryptP $xlib $to]} {
        return
    }

    set bto [::xmpp::jid::removeResource $to]
    set chatid [chat::chatid $xlib $to]

    if {[chat::is_groupchat $chatid]} {
        set name {}
        foreach n [::muc::roster $chatid] {
            set idx [list $xlib $to $n]
            if {[info exists groupchat_encrypt($idx)] &&
                        $groupchat_encrypt($idx)} {
                lappend name $j2k([::xmpp::jid::replaceResource $to $n])
            }
        }
    } else {
        if {[info exists j2k($to)]} {
            set name [list $j2k($to)]
        } elseif {[llength [set k [array names j2k $to/*]]] > 0} {
            set name [list $j2k([lindex $k 0])]
        } else {
            set name [list $bto]
        }
    }

    set recipient [gpg::recipient]
    foreach n $name {
        $recipient add -name     $n \
                       -validity full
    }
    foreach signer $e4me($xlib) {
        $recipient add -name     $signer \
                       -validity full
    }

    once_only $xlib

    set code [catch {$ctx($xlib) encrypt -input      $data \
                                         -recipients $recipient} result]
    $recipient free

    if {$code} {
        debugmsg ssj "encryption processing error ($xlib): $result ($data)"

        set options(encrypt,$xlib,$to) 0
        incr gpg_error_id
        if {[MessageDlg .encrypt_error$gpg_error_id \
                -aspect 50000 \
                -icon error \
                -type user \
                -buttons {ok cancel} \
                -default 0 \
                -cancel 1 \
                -message [::msgcat::mc \
                              "Unable to encipher data for %s:\
                               %s.\n\nEncrypting traffic to this user is\
                               now disabled.\n\nSend it as PLAINTEXT?" \
                              $to $result]]} {
            error ""
        }

        return
    }
    set result [armor:encode $result]

    debugmsg ssj "ENCRYPT: $xlib; $data; $result"

    return $result
}

proc ::ssj::whichkeys {xlib what} {
    variable ctx
    variable warnings

    if {[catch {$ctx($xlib) set -property last-op-info} s]} {
        return
    }

    set keys {}
    while {([set x [string first <fpr> $s]] > 0) &&
                ([set y [string first </fpr> $s]] > $x) &&
                ($x+45 == $y)} {
        lappend keys [string range $s [expr {$x + 20}] [expr {$y - 1}]]
        set s [string range $s $y end]
    }

    if {![info exists warnings($what)]} {
        set warnings($what) ""
    } elseif {$warnings($what) eq $keys} {
        return
    }

    set warnings($what) $keys
    debugmsg ssj "${what}ing with $keys"
}

#############################################################################

proc ::ssj::prefs {xlib jid} {
    variable ctx
    variable options
    variable optionsX

    set w [win_id security_preferences [list $xlib $jid]]

    if {[winfo exists $w]} {
        focus -force $w
        return
    }

    Dialog $w \
           -title [::msgcat::mc "Change security preferences for %s" $jid] \
           -anchor e -default 0 -cancel 1

    $w add -text [::msgcat::mc "OK"] \
           -command [list ::ssj::prefs_ok $w $xlib $jid]
    $w add -text [::msgcat::mc "Cancel"] -command [list destroy $w]

    set f [$w getframe]

    if {![info exists options(encrypt,$xlib,$jid)]} {
        set options(encrypt,$xlib,$jid) [encryptP $xlib $jid]
    }

    set optionsX(encrypt,$xlib,$jid) $options(encrypt,$xlib,$jid)
    Checkbutton $f.encrypt \
        -text     [::msgcat::mc "Encrypt traffic"] \
        -variable ::ssj::optionsX(encrypt,$xlib,$jid)

    pack $f.encrypt -side left
    pack [Frame $f.f -width 9c -height 2c]

    $w draw $f.name
}

proc ::ssj::prefs_ok {w xlib jid} {
    variable options
    variable optionsX

    set options(encrypt,$xlib,$jid) $optionsX(encrypt,$xlib,$jid)

    destroy $w
}

proc ::ssj::prefs_user_menu {m xlib jid} {
    $m add command -label [::msgcat::mc "Edit security..."] \
                   -command [list ::ssj::prefs $xlib $jid]
}

hook::add chat_create_user_menu_hook ::ssj::prefs_user_menu 78
hook::add chat_create_conference_menu_hook ::ssj::prefs_user_menu 78
hook::add roster_create_groupchat_user_menu_hook ::ssj::prefs_user_menu 78
hook::add roster_conference_popup_menu_hook ::ssj::prefs_user_menu 78
hook::add roster_service_popup_menu_hook ::ssj::prefs_user_menu 78
hook::add roster_jid_popup_menu_hook ::ssj::prefs_user_menu 78
hook::add message_dialog_menu_hook ::ssj::prefs_user_menu 78

#############################################################################

proc ::ssj::signP {} {
    variable options

    return $options(sign-traffic)
}

proc ::ssj::encryptP {xlib jid} {
    variable ctx
    variable j2k
    variable options

    if {$jid eq ""} {
        return $options(encrypt-traffic)
    }

    lassign [roster::get_category_and_subtype $xlib $jid] \
            category subtype
    switch -- $category {
        conference -
        server     -
        gateway    -
        service {
            set resP 0
        }

        default {
            set resP 1
        }
    }

    set bjid [::xmpp::jid::removeResource $jid]

    if {[info exists options(encrypt,$xlib,$jid)]} {
        return $options(encrypt,$xlib,$jid)
    } elseif {[info exists options(encrypt,$xlib,$bjid)]} {
        return $options(encrypt,$xlib,$bjid)
    } elseif {[info exists options(encrypt,$jid)]} {
        return $options(encrypt,$jid)
    } elseif {[info exists options(encrypt,$bjid)]} {
        return $options(encrypt,$jid)
    }

    if {!$options(encrypt-traffic)} {
        return 0
    }

    if {[info exists options(encrypt-tried,$xlib,$jid)]} {
        return $options(encrypt-tried,$xlib,$jid)
    }

    once_only $xlib

    if {[info exists j2k($jid)]} {
        set name $j2k($jid)
    } elseif {($resP) && ([llength [set k [array names j2k $jid/*]]] > 0)} {
        set name $j2k([lindex $k 0])
    } else {
        set name $bjid
    }

    set recipient [gpg::recipient]
    $recipient add -name     $name \
                   -validity full

    if {[catch {$ctx($xlib) encrypt -input      "Hello world." \
                                    -recipients $recipient}]} {
        set options(encrypt-tried,$xlib,$jid) 0
    } else {
        set options(encrypt-tried,$xlib,$jid) 1
    }

    $recipient free

    return $options(encrypt-tried,$xlib,$jid)
}

#############################################################################

proc ::ssj::e4meP {xlib keys} {
    variable ctx
    variable e4me
    variable signers

    $ctx($xlib) set -property signers \
                    -value    [set signers($xlib) $keys]

    set e4me($xlib) {}
    foreach signer $signers($xlib) {
        set recipient [gpg::recipient]
        $recipient add -name     $signer \
                       -validity full

        if {![catch {$ctx($xlib) encrypt -input      "Hello world." \
                                         -recipients $recipient} result]} {
            lappend e4me($xlib) $signer
        }

        $recipient free
    }
}

#############################################################################

proc ::ssj::sign:toggleP {} {
    variable options

    set options(sign-traffic) [expr {!$options(sign-traffic)}]
}

proc ::ssj::encrypt:toggleP {{xlib ""} {jid ""}} {
    variable options

    if {$jid eq ""} {
        set options(encrypt-traffic) [expr {!$options(encrypt-traffic)}]
        return
    }

    if {$xlib ne ""} {
        if {![info exists options(encrypt,$xlib,$jid)]} {
            set options(encrypt,$xlib,$jid) [encryptP $xlib $jid]
        }
        set options(encrypt,$xlib,$jid) \
            [expr {!$options(encrypt,$xlib,$jid)}]
    } else {
        return -code error \
            "::ssj::encrypt:toggleP: xlib is empty and jid is not"
    }
}

#############################################################################

proc ::ssj::signed:trace {script} {
    variable options
    variable trace

    if {![info exists trace(sign-traffic)]} {
        set trace(sign-traffic) {}

        ::trace add variable ::ssj::options(sign-traffic) write ::ssj::trace
    }

    lappend trace(sign-traffic) $script
}

proc ::ssj::encrypted:trace {script {xlib ""} {jid ""}} {
    variable options
    variable trace

    if {$jid eq ""} {
        set k encrypt-traffic
    } else {
        if {$xlib ne ""} {
            set k encrypt,$xlib,$jid
        } else {
            return -code error \
                "::ssj::encrypted:trace: xlib is empty and jid is not"
        }
    }
    if {![info exists trace($k)]} {
        set trace($k) {}

        ::trace add variable ::ssj::options($k) write ::ssj::trace
    }

    lappend trace($k) $script
}

proc ::ssj::trace {name1 name2 op} {
    variable trace

    set new {}
    foreach script $trace($name2) {
        if {[catch {eval $script} result]} {
            debugmsg ssj "$result -- $script"
        } else {
            lappend new $script
        }
    }
    set trace($name2) $new
}

#############################################################################

proc ::ssj::clear_signatures {xlib} {
    variable signed

    array unset signed $xlib,*
}

hook::add disconnected_hook ::ssj::clear_signatures

#############################################################################

proc ::ssj::check_signature {xlib from type x args} {
    variable NS
    variable signed

    switch -- $type {
        unavailable -
        available {
            unset -nocomplain signed($xlib,$from)

            set signature ""
            foreach xs $x {
                ::xmpp::xml::split $xs tag xmlns attrs cdata subels
                if {$xmlns eq $NS(signed)} {
                    set signature $cdata
                    break
                }
            }

            # in case the sender didn't check the exit code from gpg...
            if {$signature eq ""} return

            set status ""
            foreach {key val} $args {
                switch -- $key {
                    -status {
                        set status $val
                    }
                }
            }

            set signed($xlib,$from) \
                [signed:input $xlib $from $signature $status \
                     [::msgcat::mc "Presence information"]]
        }
    }
}

hook::add client_presence_hook ::ssj::check_signature

#############################################################################

proc ::ssj::make_signature {varname xlib status} {
    variable NS
    upvar 2 $varname var

    if {![catch {signed:output $xlib $status} cdata] && $cdata ne ""} {
        lappend var [::xmpp::xml::create x -xmlns $NS(signed) \
                                           -cdata $cdata]
    }
    return
}

hook::add presence_xlist_hook ::ssj::make_signature

#############################################################################

proc ::ssj::add_timestamp \
     {vxlib vto vid vtype vsubject vbody verr vthread vx} {
    variable options
    upvar 2 $vxlib xlib
    upvar 2 $vto to
    upvar 2 $vbody body
    upvar 2 $vx x

    if {!$options(prevent-replay-attack)} return

    if {![info exists body]} return

    if {(![catch {ssj::signed:output $xlib $body $to} cdata] && $cdata ne "") || \
            (![catch {ssj::encrypted:output $xlib $body $to} cdata] && $cdata ne "")} {
        set timestamp [clock format [clock seconds] \
                                    -format "%Y%m%dT%TZ" -gmt true]
        if {$body ne ""} {
            set body " $body"
        }
        set body "\[To: [::xmpp::jid::removeResource $to], Date: $timestamp\]$body"
    }
    return
}

hook::add rewrite_outgoing_message_hook ::ssj::add_timestamp 5

proc ::ssj::sign_encrypt_body \
     {vxlib vto vid vtype vsubject vbody verr vthread vx} {
    variable NS
    upvar 2 $vxlib xlib
    upvar 2 $vto to
    upvar 2 $vtype type
    upvar 2 $vbody body
    upvar 2 $vx x

    if {![info exists body]} return

    set newbody $body
    foreach tag {encrypted signed} {
        if {[catch {ssj::${tag}:output $xlib $body $to} cdata]} {
            debugmsg ssj "ssj::${tag}:output: $cdata"

            # Disable sending the message
            hook::unset_flag rewrite_outgoing_message_hook send

            return
        }

        if {$cdata ne ""} {
            lappend x [::xmpp::xml::create x -xmlns $NS($tag) -cdata $cdata]

            if {$type ne "groupchat"} {
                # Groupchat messages are shown only when come back, so don't
                # setup drawing the signed/encrypted icons for them

                hook::unset_flag rewrite_outgoing_message_hook $tag
            }

            if {$tag eq "encrypted"} {
                if {$type eq "groupchat"} {
                    set newbody "This message is encrypted."
                } else {
                    set lang [get_jid_presence_info lang $xlib $to]
                    set newbody [::trans::trans $lang "This message is encrypted."]
                }
            }
        }
    }
    set body $newbody

    return
}

hook::add rewrite_outgoing_message_hook ::ssj::sign_encrypt_body

#############################################################################

proc ::ssj::userinfo {tab xlib jid editable} {
    variable signed

    if {$editable} return

    set bare_jid [::xmpp::jid::removeResource $jid]
    set chatid [chat::chatid $xlib $bare_jid]
    if {[chat::is_groupchat $chatid]} {
        if {[info exists signed($xlib,$jid)]} {
            set jids [list $xlib,$jid]
        } else {
            set jids [list]
        }
    } else {
        set jids [array names signed $xlib,$bare_jid/*]
    }
    if {[llength $jids] > 0} {
        set presenceinfo [$tab insert end presenceinfo \
                              -text [::msgcat::mc "Presence"]]
        set i 0
        foreach j $jids {
            regexp {[^,]*,(.*)} $j -> fjid
            set x [userinfo::pack_frame $presenceinfo.presence_$i $fjid]
            unset -nocomplain params
            array set params $signed($j)

            set kv {}
            set addrs ""
            set s ""
            foreach signature $params(signatures) {
                foreach {k v} $signature {
                    switch -- $k {
                        key {
                            foreach {k v} $v {
                                if {$k ne "subkeys"} continue

                                foreach subkey $v {
                                    unset -nocomplain sparams
                                    array set sparams $subkey
                                    if {[info exists sparams(email)]} {
                                        append addrs $s $sparams(email)
                                        set s ", "
                                    }
                                }
                            }
                            continue
                        }
                        status {
                            continue
                        }
                        created -
                        expires {
                            set v [clock format $v]
                        }
                        fingerprint {
                            lappend kv keyid [format "0x%s" [keyid $v]]
                        }
                        default {
                            if {$v eq ""} continue
                        }
                    }

                    lappend kv $k $v
                }
            }


            userinfo::pack_entry $jid $x $i presence_$i \
                                 [::msgcat::mc "Reason:"]
            if {![info exists params(reason)]} {
                set params(reason) [::msgcat::mc "Presence is signed"]
                if {$addrs ne ""} {
                    append params(reason) [::msgcat::mc " by "] $addrs
                }
            }
            set ::userinfo::userinfo(presence_$i,$jid) $params(reason)
            incr i

            foreach {k v} $kv {
                userinfo::pack_entry $jid $x $i presence_$i \
                    [::msgcat::mc [string totitle ${k}:]]
                set ::userinfo::userinfo(presence_$i,$jid) $v
                incr i
            }
        }
    }
}

hook::add userinfo_hook ::ssj::userinfo 90

#############################################################################

proc ::ssj::message_buttons {mw xlib jid} {
    set bbox1 [ButtonBox $mw.bottom.buttons1 -spacing 0]

    # TODO reflect changes of xlib
    set b [$bbox1 add \
                  -image [encrypted:icon $xlib $jid] \
                  -helptype balloon \
                  -helptext [::msgcat::mc "Toggle encryption"] \
                  -relief link \
                  -command [list ::ssj::encrypt:toggleP $xlib $jid]]
    encrypted:trace \
        "$b configure -image \
                      \[::ssj::encrypted:icon [list $xlib] [list $jid]\]" \
        $xlib $jid

    pack $bbox1 -side left -fill x -padx 2m -pady 2m
}

hook::add open_message_post_hook ::ssj::message_buttons

#############################################################################

proc ::ssj::process_x_signed {rowvar bodyvar f x xlib from id type replyP} {
    variable NS
    upvar 2 $rowvar row
    upvar 2 $bodyvar body

    if {!$replyP || $type eq "error"} {
        return
    }

    foreach xa $x {
        ::xmpp::xml::split $xa tag xmlns attrs cdata subels

        if {$tag ne "" || $xmlns ne $NS(signed)} {
            continue
        }

        set lb [join [lrange [split $f .] 0 end-1] .].title.signed
        if {[winfo exists $lb]} {
            destroy $lb
        }

        grid [signed:Label $lb $xlib $from $attrs] -row 1 -column 2 -sticky e
    }

    return
}

hook::add message_process_x_hook ::ssj::process_x_signed 20

#############################################################################

proc ::ssj::signed:icon {} {
    return [lindex [list toolbar/gpg-unsigned toolbar/gpg-signed] \
                   [signP]]
}

proc ::ssj::encrypted:icon {{xlib ""} {jid ""}} {
    return [lindex [list toolbar/gpg-unencrypted toolbar/gpg-encrypted] \
                   [encryptP $xlib $jid]]
}

#############################################################################

proc ::ssj::draw_signed {chatid from type body x} {
    variable NS
    variable signedid

    set chatw [chat::chat_win $chatid]

    if {![hook::is_flag rewrite_outgoing_message_hook signed]} {
        $chatw image create end -image gpg/signed

        hook::set_flag rewrite_outgoing_message_hook signed
    } else {
        foreach xe $x {
            ::xmpp::xml::split $xe tag xmlns attrs cdata subels

            if {$tag ne "" || $xmlns ne $NS(signed)} continue

            incr signedid
            set xlib [chat::get_xlib $chatid]
            catch {
                set lb $chatw.signed$signedid
                $chatw window create end \
                      -window [signed:Label $lb $xlib $from $attrs]
                $lb configure -background [get_conf $chatw -background]
            }
        }
    }
}

hook::add draw_message_hook ::ssj::draw_signed 5.2

###############################################################################

proc ::ssj::chat_window_button {chatid type} {
    variable groupchat_encrypt
    variable signed
    variable options

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]
    set cw [chat::winid $chatid]

    set w $cw.status.encrypted

    if {$type eq "chat"} {
        set command [list ::ssj::encrypt:toggleP $xlib $jid]
    } else {
        set command [list ::ssj::groupchat_encrypt_dialog $xlib $jid]
        set options(encrypt,$xlib,$jid) 0
    }
    Button $w \
           -relief link \
           -image [encrypted:icon $xlib $jid] \
           -helptype balloon \
           -helptext [::msgcat::mc "Toggle encryption"] \
           -command $command

    encrypted:trace \
        "$w configure -image \[::ssj::encrypted:icon $xlib $jid\]" $xlib $jid
    pack $w -side left -before $cw.status.mb

    foreach nick [::muc::roster $chatid] {
        set user_jid [::xmpp::jid::replaceResource $jid $nick]
        if {![info exists signed($xlib,$user_jid)]} continue

        set idx [list $xlib $jid $nick]

        if {![info exists groupchat_encrypt($idx)]} {
            set groupchat_encrypt($idx) 0
        }
    }
}

hook::add open_chat_post_hook ::ssj::chat_window_button

proc ::ssj::on_close_chat {chatid} {
    variable groupchat_encrypt
    variable options

    set xlib [chat::get_xlib $chatid]
    set jid [chat::get_jid $chatid]

    array unset groupchat_encrypt [list $xlib $jid *]
    set options(encrypt,$xlib,$jid) 0
}

hook::add close_chat_post_hook ::ssj::on_close_chat

proc ::ssj::groupchat_encrypt_dialog {xlib jid} {
    variable groupchat_encrypt
    variable signed
    variable groupencrypt[psuffix $xlib]
    unset -nocomplain groupencrypt[psuffix $xlib]

    set chatid [chat::chatid $xlib $jid]

    set nicks {}
    set balloons {}
    set disabled {}

    foreach nick [lsort -dictionary [::muc::roster $chatid]] {
        set user_jid [::xmpp::jid::replaceResource $jid $nick]

        if {![info exists signed($xlib,$user_jid)]} {
            set groupencrypt[psuffix $xlib]($nick) 0
            continue
        }

        lappend nicks $nick $nick
        lappend balloons $nick [signed:info $signed($xlib,$user_jid)]
        unset -nocomplain params
        array set params $signed($xlib,$user_jid)
        if {[info exists params(reason)]} {
            set groupencrypt[psuffix $xlib]($nick) 0
            lappend disabled $nick 1
        } else {
            set idx [list $xlib $jid $nick]
            if {[info exists groupchat_encrypt($idx)]} {
                set groupencrypt[psuffix $xlib]($nick) $groupchat_encrypt($idx)
            }
        }
    }

    set dw .groupencrypt[psuffix $xlib]
    if {[winfo exists $dw]} {
        destroy $dw
    }

    CbDialog $dw [::msgcat::mc "Select room %s participants for encrypting\
                                traffic to" $jid] \
        [list [::msgcat::mc "OK"] [list ::ssj::save_groupchat_encrypt $dw $xlib $jid] \
              [::msgcat::mc "Cancel"] [list destroy $dw]] \
        ::ssj::groupencrypt[psuffix $xlib] $nicks $balloons \
        -disabled $disabled -modal local
}

proc ::ssj::save_groupchat_encrypt {dw xlib jid} {
    variable groupchat_encrypt
    variable groupencrypt[psuffix $xlib]

    foreach nick [array names groupencrypt[psuffix $xlib]] {
        set idx [list $xlib $jid $nick]

        if {![info exists groupchat_encrypt($idx)]} {
            set groupchat_encrypt($idx) 0
        }
        if {[set groupencrypt[psuffix $xlib]($nick)]} {
            set groupchat_encrypt($idx) 1
        } else {
            set groupchat_encrypt($idx) 0
        }
    }

    destroy $dw
    unset -nocomplain groupencrypt[psuffix $xlib]
}

proc ::ssj::aggregate_encrypt {name1 name2 op} {
    variable options
    variable groupchat_encrypt

    # Node and server can't contain a comma
    lassign [split $name2] xlib jid
    set chatid [chat::chatid $xlib $jid]
    foreach nick [::muc::roster $chatid] {
        set idx [list $xlib $jid $nick]

        if {[info exists groupchat_encrypt($idx)] &&
                                        $groupchat_encrypt($idx)} {
            set options(encrypt,$xlib,$jid) 1
            return
        }
    }
    set options(encrypt,$xlib,$jid) 0
}

trace add variable ::ssj::groupchat_encrypt {write} ::ssj::aggregate_encrypt

###############################################################################

proc ::ssj::toolbar {} {
    set idx [ifacetk::add_toolbar_button \
                 [signed:icon] \
                 ::ssj::sign:toggleP \
                 [::msgcat::mc "Toggle signing presence updates"]]
    signed:trace \
        [list ifacetk::set_toolbar_icon $idx ::ssj::signed:icon]

    set idx [ifacetk::add_toolbar_button \
                 [encrypted:icon] \
                 ::ssj::encrypt:toggleP \
                 [::msgcat::mc "Toggle encryption (when possible)"]]
    encrypted:trace \
        [list ifacetk::set_toolbar_icon $idx ::ssj::encrypted:icon]
}

hook::add finload_hook ::ssj::toolbar

###############################################################################

proc ::ssj::setup_menu {} {
    variable options

    set m [.mainframe getmenu tkabber]
    set ind [$m index [::msgcat::mc "View"]]
    incr ind -1

    set mm .ssj_menu
    menu $mm -tearoff $::ifacetk::options(show_tearoffs)
    $mm add checkbutton -label [::msgcat::mc "Sign presence updates"] \
            -variable ::ssj::options(sign-traffic)
    $mm add checkbutton \
            -label [::msgcat::mc "Encrypt messages (when possible)"] \
            -variable ::ssj::options(encrypt-traffic)

    $m insert $ind cascade -label [::msgcat::mc "Encryption"] \
            -menu $mm
}

hook::add finload_hook ::ssj::setup_menu

###############################################################################

proc ::ssj::add_user_popup_info {infovar xlib jid} {
    variable signed

    upvar 0 $infovar info

    if {[info exists signed($xlib,$jid)]} {
        set signed_info [signed:info $signed($xlib,$jid)]
        append info [::msgcat::mc "\n\tPresence is signed:"]
        regsub -all {(\n)} "\n$signed_info" "\\1\t    " extra
        append info $extra
    }
}

hook::add roster_user_popup_info_hook ::ssj::add_user_popup_info 99

###############################################################################

proc ::ssj::process_gpg_input_error {xlib from what message} {
    show_error $message
}

hook::add gpg_input_error_hook ::ssj::process_gpg_input_error 99

proc ::ssj::show_error {message} {
    set w .gpg_error

    if {![winfo exists $w]} {
        Dialog $w -title [::msgcat::mc "GPG error"] \
                -modal none -transient no \
                -anchor e -default 0
        $w add -text [::msgcat::mc "Close"] -command [list destroy $w]

        set f [$w getframe]
        ScrolledWindow $f.sw -scrollbar vertical
        pack $f.sw -fill both -expand yes -side bottom
        Text $f.text -wrap word
        $f.sw setwidget $f.text

        $w draw
    }

    set t [$w getframe].text
    $t configure -state normal
    $t insert end [format {[%s]: %s} \
                          [clock format [clock seconds]] $message\n\n]
    $t configure -state disabled
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
