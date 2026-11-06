# login.tcl --
#
#       This file is a part of the Tkabber XMPP client. It implements the
#       login user dialog.

proc enable_disable_field {field state} {
    if {[winfo exists $field]} {
        $field configure -state $state
        if {[focus] eq $field && $state eq "disabled"} {
            focus [Widget::focusPrev $field]
        }
    }
}

proc update_login_entries {l {i 0}} {
    global ltmp have_bosh have_http_poll have_sasl

    if {$i} {
        array set ltmp [array get ::loginconf$i]
        array set loginconf [array get ltmp]
    }
    foreach ent {username server port password resource priority \
            altserver proxyhost proxyport proxyusername proxypassword \
            sslcertfile boshurl pollurl} {
        if {[winfo exists $l.$ent]} {
            catch { $l.$ent icursor end }
        }
    }

    set checks {}
    if {$have_bosh} {
        enable_disable_field $l.usebosh normal
        if {$ltmp(usebosh)} {
            enable_disable_field $l.usehttppoll disabled
            set checks {usebosh {lboshurl boshurl useboshkeys}
                            {lpollurl pollurl usepollkeys
                             dontusessl usecompress legacyssl encrypted
                             sslcertfile lsslcertfile bsslcertfile}}
        } else {
            if {$have_http_poll} {
                enable_disable_field $l.usehttppoll normal
                if {$ltmp(usehttppoll)} {
                    enable_disable_field $l.usebosh disabled
                }
                enable_disable_field $l.lboshurl disabled
                enable_disable_field $l.boshurl disabled
                enable_disable_field $l.useboshkeys disabled
                set checks {usehttppoll {lpollurl pollurl usepollkeys}
                                {usebosh
                                 dontusessl usecompress legacyssl encrypted
                                 sslcertfile lsslcertfile bsslcertfile}}
            } else {
                set checks {usebosh {lboshurl boshurl useboshkeys}
                                    {dontusessl usecompress legacyssl encrypted
                                     sslcertfile lsslcertfile bsslcertfile}}
            }
        }
    } elseif {$have_http_poll} {
        enable_disable_field $l.usehttppoll normal
        set checks {usehttppoll {lpollurl pollurl usepollkeys}
                                {dontusessl usecompress legacyssl encrypted
                                 sslcertfile lsslcertfile bsslcertfile}}
    }

    foreach {check enable disable} [concat $checks \
            {usealtserver {altserver laltserver port lport} {}}] {

        if {![info exists ltmp($check)] || ![winfo exists $l.$check]} {
            continue
        }

        if {$ltmp($check) && [$l.$check cget -state] ne "disabled"} {
            set state1 normal
            set state2 disabled
        } else {
            set state1 disabled
            set state2 normal
        }
        foreach ent $enable {
            enable_disable_field $l.$ent $state1
        }
        foreach ent $disable {
            enable_disable_field $l.$ent $state2
        }
    }

    catch {
        if {[string equal $ltmp(proxy) none]} {
            foreach ent {proxyhost proxyport proxyusername proxypassword \
                         lproxyhost lproxyport lproxyusername lproxypassword} {
                $l.$ent configure -state disabled
                if {[string equal [focus] $l.$ent]} {
                    focus [Widget::focusPrev $l.$ent]
                }
            }
        } else {
            foreach ent {proxyhost proxyport proxyusername proxypassword \
                         lproxyhost lproxyport lproxyusername lproxypassword} {
                $l.$ent configure -state normal
            }
        }
    }

    catch {
        if {![string equal [$l.dontusessl cget -state] disabled] && \
                ($ltmp(stream_options) == "ssl" || \
                 $ltmp(stream_options) == "encrypted")} {
            $l.sslcertfile configure -state normal
            $l.lsslcertfile configure -state normal
            $l.bsslcertfile configure -state normal
        } else {
            $l.sslcertfile configure -state disabled
            $l.lsslcertfile configure -state disabled
            $l.bsslcertfile configure -state disabled
            if {[string equal [focus] $l.sslcertfile] || \
                    [string equal [focus] $l.bsslcertfile]} {
                focus [Widget::focusPrev $l.sslcertfile]
            }
        }
    }

    if {$have_sasl} {
        enable_disable_field $l.usesasl normal
        if {$ltmp(usesasl)} {
            enable_disable_field $l.allowauthscram normal
        } else {
            enable_disable_field $l.allowauthscram disabled
        }
    }
}

proc login_dialog {} {
    global loginconf
    global ltmp
    global use_tls have_compress have_sasl have_bosh have_http_poll have_proxy

    if {[winfo exists .login]} {
        focus -force .login
        return
    }

    array set ltmp [array get loginconf]

    Dialog .login -title [::msgcat::mc "Login"] \
                  -anchor e \
                  -default 0 \
                  -cancel 1

    wm resizable .login 0 0

    set l [.login getframe]
    catch {$l configure -padding {0.25m 0.25m}}
    catch {$l configure -padx 0.25m -pady 0.25m}

    set n 1
    while {[info exists ::loginconf$n]} {incr n}
    incr n -1

    if {$n} {
        Menubutton $l.profiles -text [::msgcat::mc "Profiles"] \
                               -menu $l.profiles.menu
        set m [menu $l.profiles.menu -tearoff 0]
        for {set i 1} {$i <= $n} {incr i} {
            if {[info exists ::loginconf${i}(profile)]} {
                set lab [set ::loginconf${i}(profile)]
            } else {
                set lab "[::msgcat::mc Profile] $i"
            }
            if {$i <= 10} {
                set j [expr {$i % 10}]
                $m add command -label $lab -accelerator "$::tk_modify-$j" \
                    -command [list [namespace current]::update_login_entries \
                                   $l $i]
                bind .login <Control-Key-$j> \
                    [list [namespace current]::update_login_entries \
                          [double% $l] $i]
            } else {
                $m add command -label $lab \
                    -command [list [namespace current]::update_login_entries \
                                   $l $i]
            }
        }

        grid $l.profiles -row 0 -column 0 -sticky e
    }

    set nb [Notebook $l.nb]

    set account_page \
        [$nb insert end account_page -text [::msgcat::mc "Account"]]

    Label $l.lusername -text [::msgcat::mc "Username:"]
    Entry $l.username -textvariable ltmp(user)
    Label $l.lserver -text [::msgcat::mc "Server:"]
    Entry $l.server -textvariable ltmp(server)
    Label $l.lpassword -text [::msgcat::mc "Password:"]
    Entry $l.password -show * -textvariable ltmp(password)
    Label $l.lresource -text [::msgcat::mc "Resource:"]
    Entry $l.resource -textvariable ltmp(resource)
    Label $l.lpriority -text [::msgcat::mc "Priority:"]
    Spinbox $l.priority -1000 1000 1 ltmp(priority)

    grid $l.lusername -row 0 -column 0 -sticky e -in $account_page
    grid $l.username  -row 0 -column 1 -sticky ew -in $account_page
    grid $l.lserver   -row 0 -column 2 -sticky e -in $account_page
    grid $l.server    -row 0 -column 3 -sticky ew -in $account_page
    grid $l.lpassword -row 1 -column 0 -sticky e -in $account_page
    grid $l.password  -row 1 -column 1 -sticky ew -in $account_page
    grid $l.lresource -row 2 -column 0 -sticky e -in $account_page
    grid $l.resource  -row 2 -column 1 -sticky ew -in $account_page
    grid $l.lpriority -row 2 -column 2 -sticky e -in $account_page
    grid $l.priority  -row 2 -column 3 -sticky ew -in $account_page

    grid columnconfigure $account_page 1 -weight 3
    grid columnconfigure $account_page 2 -weight 1
    grid columnconfigure $account_page 3 -weight 3

    set connection_page \
        [$nb insert end connection_page -text [::msgcat::mc "Connection"]]

    Checkbutton $l.usealtserver \
        -text [::msgcat::mc "Explicitly specify host and port to connect"] \
        -variable ltmp(usealtserver) \
        -command [list [namespace current]::update_login_entries $l]
    Label $l.laltserver -text [::msgcat::mc "Host:"]
    Entry $l.altserver -textvariable ltmp(altserver)
    Label $l.lport -text [::msgcat::mc "Port:"]
    Spinbox $l.port 0 65535 1 ltmp(altport)

    grid $l.usealtserver -row 0 -column 0 -sticky w -columnspan 4 \
                         -in $connection_page
    grid $l.laltserver -row 1 -column 0 -sticky e -in $connection_page
    grid $l.altserver -row 1 -column 1 -sticky ew -in $connection_page
    grid $l.lport     -row 1 -column 2 -sticky e -in $connection_page
    grid $l.port      -row 1 -column 3 -sticky we -in $connection_page

    Checkbutton $l.replace -text [::msgcat::mc "Replace opened connections"] \
        -variable ltmp(replace_opened)
    grid $l.replace -row 3 -column 0 -sticky w -columnspan 2 \
                    -in $connection_page

    Checkbutton $l.sm -text [::msgcat::mc "Use stream management"] \
        -variable ltmp(stream_management)
    grid $l.sm   -row 3 -column 2 -sticky e -columnspan 2 -in $connection_page

    grid columnconfigure $connection_page 1 -weight 6
    grid columnconfigure $connection_page 2 -weight 1

    set auth_page \
        [$nb insert end auth_page -text [::msgcat::mc "Authentication"]]

    Checkbutton $l.allowauthplain \
        -text [::msgcat::mc "Allow plaintext authentication mechanisms"] \
        -variable ltmp(allowauthplain) \
        -command [list [namespace current]::update_login_entries $l]

    grid $l.allowauthplain -row 0 -column 0 -sticky w -in $auth_page

    if {$have_sasl} {
        Checkbutton $l.usesasl \
            -text [::msgcat::mc "Use SASL authentication"] \
            -variable ltmp(usesasl) \
            -command [list [namespace current]::update_login_entries $l]

        grid $l.usesasl -row 1 -column 0 -sticky w -in $auth_page

        Checkbutton $l.allowauthscram \
            -text [::msgcat::mc "Allow SCRAM authentication mechanisms"] \
            -variable ltmp(allowauthscram) \
            -command [list [namespace current]::update_login_entries $l]

        grid $l.allowauthscram -row 2 -column 0 -sticky w -in $auth_page
    }

    grid columnconfigure $auth_page 0 -weight 1

    if {$use_tls || $have_compress} {
        if {$use_tls && $have_compress} {
                set page_label [::msgcat::mc "SSL & Compression"]
        } elseif {$have_compress} {
            set page_label [::msgcat::mc "Compression"]
        } else {
            set page_label [::msgcat::mc "SSL"]
        }

        set ssl_page [$nb insert end ssl_page -text $page_label]

        Radiobutton $l.dontusessl -text [::msgcat::mc "Plaintext"] \
            -variable ltmp(stream_options) -value plaintext \
            -command [list [namespace current]::update_login_entries $l]
        if {$have_compress} {
            Radiobutton $l.usecompress -text [::msgcat::mc "Compression"] \
                -variable ltmp(stream_options) -value compressed \
                -command [list [namespace current]::update_login_entries $l]
        }
        if {$use_tls} {
            Radiobutton $l.encrypted \
                -text [::msgcat::mc "Encryption (STARTTLS)"] \
                -variable ltmp(stream_options) -value encrypted \
                -command [list [namespace current]::update_login_entries $l]
            Radiobutton $l.legacyssl \
                -text [::msgcat::mc "Encryption (legacy SSL)"] \
                -variable ltmp(stream_options) -value ssl \
                -command [list [namespace current]::update_login_entries $l]
            Label $l.lsslcertfile -text [::msgcat::mc "SSL certificate:"]
            Entry $l.sslcertfile -textvariable ltmp(sslcertfile)
            Button $l.bsslcertfile -text [::msgcat::mc "Browse..."] \
                -command [list eval set ltmp(sslcertfile) {[tk_getOpenFile]}]
        }

        set column 0
        grid $l.dontusessl -row 0 -column $column -sticky w -in $ssl_page

        if {$have_compress} {
            grid $l.usecompress -row 0 -column [incr column] -sticky w \
                                -in $ssl_page
        }
        if {$use_tls} {
            grid $l.encrypted -row 0 -column [incr column] -sticky w \
                              -in $ssl_page
            grid $l.legacyssl -row 0 -column [incr column] -sticky w \
                              -in $ssl_page

            grid $l.lsslcertfile -row 1 -column 0 -sticky e -in $ssl_page
            grid $l.sslcertfile  -row 1 -column 1 -sticky ew -columnspan 2 \
                                 -in $ssl_page
            grid $l.bsslcertfile -row 1 -column 3 -sticky w -in $ssl_page
        }

        grid columnconfigure $ssl_page 1 -weight 1
        grid columnconfigure $ssl_page 2 -weight 1
    }

    if {$have_bosh} {
        set bosh_page [$nb insert end bosh_page -text [::msgcat::mc "BOSH"]]

        Checkbutton $l.usebosh -text [::msgcat::mc "Connect via BOSH"] \
            -variable ltmp(usebosh) \
            -command [list [namespace current]::update_login_entries $l]
        Label $l.lboshurl -text [::msgcat::mc "URL to use:"]
        Entry $l.boshurl -textvariable ltmp(boshurl)
        Checkbutton $l.useboshkeys \
            -text [::msgcat::mc "Use client security keys"] \
            -state disabled \
            -variable ltmp(useboshkeys) \
            -command [list [namespace current]::update_login_entries $l]

        grid $l.usebosh -row 0 -column 0 -sticky w -columnspan 3 -in $bosh_page
        grid $l.lboshurl -row 1 -column 0 -sticky e -in $bosh_page
        grid $l.boshurl -row 1 -column 1 -sticky ew -in $bosh_page
        grid $l.useboshkeys -row 2 -column 0 -sticky w -columnspan 3 \
                            -in $bosh_page

        grid columnconfigure $bosh_page 1 -weight 1
    }

    if {$have_http_poll} {
        set httppoll_page \
            [$nb insert end httpoll_page -text [::msgcat::mc "HTTP Poll"]]

        Checkbutton $l.usehttppoll \
            -text [::msgcat::mc "Connect via HTTP polling"] \
            -variable ltmp(usehttppoll) \
            -command [list [namespace current]::update_login_entries $l]
        Label $l.lpollurl -text [::msgcat::mc "URL to poll:"]
        Entry $l.pollurl -textvariable ltmp(pollurl)
        Checkbutton $l.usepollkeys \
            -text [::msgcat::mc "Use client security keys"] \
            -state disabled \
            -variable ltmp(usepollkeys) \
            -command [list [namespace current]::update_login_entries $l]

        grid $l.usehttppoll -row 0 -column 0 -sticky w -columnspan 3 \
                            -in $httppoll_page
        grid $l.lpollurl -row 1 -column 0 -sticky e -in $httppoll_page
        grid $l.pollurl -row 1 -column 1 -sticky ew -in $httppoll_page
        grid $l.usepollkeys -row 2 -column 0 -sticky w -columnspan 3 \
                            -in $httppoll_page

        grid columnconfigure $httppoll_page 1 -weight 1
    }

    catch {$nb compute_size}
    catch {$nb raise account_page}
    bind .login <Control-Prior> \
                [list [namespace current]::tab_move [double% $nb] -1]
    bind .login <Control-Next> \
                [list [namespace current]::tab_move [double% $nb] 1]
    grid $nb -row 1 -column 0

    .login add -text [::msgcat::mc "Log in"] -command {
        array set loginconf [array get ltmp]
        destroy .login
        if {$loginconf(replace_opened)} {
            logout
        }
        update
        login [array get loginconf]
    }
    .login add -text [::msgcat::mc "Cancel"] -command {destroy .login}

    update_login_entries $l

    if {[string equal $ltmp(user) ""]} {
        .login draw $l.username
    } elseif {[string equal $ltmp(password) ""]} {
        .login draw $l.password
    } else {
        .login draw $l.resource
    }
}

proc auto_login {} {
    if {![info exist ::autologin] || $::autologin == 0} {
        ifacetk::login_dialog
    } elseif {$::autologin > 0} {
        logout
        update
        login [array get ::loginconf]
    }
}

hook::add finload_hook [namespace current]::auto_login 9999

proc logout_dialog {} {
    global logout_conn

    set w .logout
    if {[winfo exists $w]} {
        destroy $w
    }

    switch -- [llength [connections]] {
        0 -
        1 {
            logout
            return
        }
    }

    set lnames {}
    foreach xlib [connections] {
        lappend lnames $xlib [connection_jid $xlib]
    }

    if {[CbDialog $w [::msgcat::mc "Logout"] \
            [list [::msgcat::mc "Log out"] [list $w enddialog 0] \
                  [::msgcat::mc "Cancel"] [list $w enddialog 1]] \
            logout_conn $lnames {} -modal local] != 0} {
        return
    }

    foreach xlib [array names logout_conn] {
        if {$xlib in [connections] && $logout_conn($xlib)} {
            logout $xlib
        }
    }
}

# TODO
proc change_password_dialog {} {
    global oldpassword newpassword password

    set oldpassword ""
    set newpassword ""
    set password ""

    if {[winfo exists .passwordchange]} {
        destroy .passwordchange
    }

    Dialog .passwordchange -title [::msgcat::mc "Change password"] \
                           -anchor e \
                           -default 0 \
                           -cancel 1

    .passwordchange add -text [::msgcat::mc "OK"] -command {
        destroy .passwordchange
        send_change_password
    }
    .passwordchange add -text [::msgcat::mc "Cancel"] \
                        -command [list destroy .passwordchange]


    set p [.passwordchange getframe]

    Label $p.loldpass -text [::msgcat::mc "Old password:"]
    Entry $p.oldpass -show * -textvariable oldpassword
    Label $p.lnewpass -text [::msgcat::mc "New password:"]
    Entry $p.newpass -show * -textvariable newpassword
    Label $p.lpassword -text [::msgcat::mc "Repeat new password:"]
    Entry $p.password -show * -textvariable password

    grid $p.loldpass  -row 0 -column 0 -sticky e
    grid $p.oldpass   -row 0 -column 1 -sticky ew
    grid $p.lnewpass  -row 1 -column 0 -sticky e
    grid $p.newpass   -row 1 -column 1 -sticky ew
    grid $p.lpassword -row 2 -column 0 -sticky e
    grid $p.password  -row 2 -column 1 -sticky ew

    focus $p.oldpass
    .passwordchange draw

}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
