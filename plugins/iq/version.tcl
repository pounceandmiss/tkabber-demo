# version.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       replies to Software Version (XEP-0092) protocol requests.

custom::defvar options(reply_iq_version) 1 \
    [::msgcat::mc "Reply to version (jabber:iq:version) requests."] \
        -group IQ -type boolean

custom::defvar options(reply_iq_os_version) 1 \
    [::msgcat::mc "Include operating system info into a reply to version\
                  (jabber:iq:version) requests."] \
        -group IQ -type boolean

proc try_linux_version {distr file flag} {
    global linux_distribution

    if {![file exists $file]} {
        return
    }
    if {![file readable $file]} {
        set linux_distribution $distr
        return
    }
    set fd [open $file r]
    set content [read $fd]
    close $fd
    set last [string first "\n" $content]
    if {$last < 0} {
        set last end
    } else {
        set last [expr {$last - 1}]
    }
    set line [string range $content 0 $last]

    switch -- $flag {
        file { set linux_distribution $line }
        append { set linux_distribution "$distr $line" }
    }
}

# NOTE: lsb_release on Debian Etch is known to dump some complaints to
# stderr is some LSB modules are not available, so we rely only on the
# existence of lsb_release and its return code.
proc get_lsb_info {} {
    if {[catch { exec lsb_release -sd 2>/dev/null } info]} {
        return {}
    }

    string trim $info
}

proc guess_linux_distribution {} {
    global linux_distribution

    if {[info exists linux_distribution] && $linux_distribution ne ""} {
        return $linux_distribution
    }

    # First, let's see if we're on a LSB-compatible system:
    set linux_distribution [get_lsb_info]
    if {$linux_distribution ne ""} {
        return $linux_distribution
    }

    foreach {distr file flag} { \
        "SuSE Linux"       /etc/SuSE-release      file \
        "Debian GNU/Linux" /etc/debian_version    append \
        "ASPLinux"         /etc/asplinux-release  file \
        "Alt Linux"        /etc/altlinux-release  file \
        "PLD Linux"        /etc/pld-release       file \
        "Gentoo Linux"     /etc/gentoo-release    file \
        "Mandrake Linux"   /etc/mandrake-release  file \
        "RedHat Linux"     /etc/redhat-release    file \
        "Conectiva Linux"  /etc/conectiva-release file \
        "Slackware Linux"  /etc/slackware-version append \
        "Arch Linux"       /etc/arch-release      file} {

        try_linux_version $distr $file $flag

        if {[info exists linux_distribution] && $linux_distribution ne ""} {
            return $linux_distribution
        }
    }

    set linux_distribution Linux
}

proc guess_windows_version {} {
    global tcl_platform

    switch -- $tcl_platform(os) {
        "Win32s" {
            return {Windows 3.1}
        }
        "Windows 95" {
            switch -- $tcl_platform(osVersion) {
                4.0  { return {Windows 95} }
                4.10 { return {Windows 98} }
                4.90 { return {Windows ME} }
                default {
                    return [list $tcl_platform(os) $tcl_platform(osVersion)]
                }
            }
        }
        "Windows NT" {
            switch -- $tcl_platform(osVersion) {
                5.0  { return {Windows 2000}  }
                5.1  { return {Windows XP}    }
                5.2  { return {Windows 2003}  }
                6.0  { return {Windows Vista} }
                6.1  { return {Windows 7}     }
                6.2  { return {Windows 8}     }
                6.3  { return {Windows 8.1}   }
                10.0 { return {Windows 10}    }
                11.0 { return {Windows 11}    }
                default {
                    return [list $tcl_platform(os) $tcl_platform(osVersion)]
                }
            }
        }
        default {
            return [list $tcl_platform(os) $tcl_platform(osVersion)]
        }
    }
}

proc iq_version {xlib from child args} {
    global tkabber_version toolkit_version tcl_platform
    variable options

    if {!$options(reply_iq_version)} {
        return {error cancel service-unavailable}
    }

    set restags [list [::xmpp::xml::create name \
                                -cdata Tkabber] \
                      [::xmpp::xml::create version \
                                -cdata "$tkabber_version ($toolkit_version)"]]

    if {$options(reply_iq_os_version)} {
        switch -glob -- $tcl_platform(os) {
            Linux {
                set os "[guess_linux_distribution] $tcl_platform(osVersion)"
            }
            Win* {
                set os [join [guess_windows_version]]
            }
            default {
                set os "$tcl_platform(os) $tcl_platform(osVersion)"
            }
        }

        lappend restags [::xmpp::xml::create os -cdata $os]
    }

    set res [::xmpp::xml::create query \
                    -xmlns jabber:iq:version \
                    -subelements $restags]

    return [list result $res]
}

::xmpp::iq::register get query jabber:iq:version \
                     [namespace current]::iq_version

proc disco_extra_version {xlib from lang} {
    global tkabber_version toolkit_version tcl_platform
    variable options

    if {!$options(reply_iq_version)} {
        return {}
    }

    set fields \
        [list field [list FORM_TYPE hidden "" {urn:xmpp:dataforms:softwareinfo}] \
              field [list software "" "" {Tkabber}] \
              field [list software_version "" "" \
                          [list "$tkabber_version ($toolkit_version)"]]]

    if {$options(reply_iq_os_version)} {
        switch -glob -- $tcl_platform(os) {
            Linux {
                set os [guess_linux_distribution]
                set os_version $tcl_platform(osVersion)
            }
            Win* {
                lassign [guess_windows_version] os os_version
            }
            default {
                set os $tcl_platform(os)
                set os_version $tcl_platform(osVersion)
            }
        }

        lappend fields field [list os "" "" [list $os]] \
                       field [list os_version "" "" [list $os_version]]
    }

    return $fields
}

hook::add postload_hook \
        [list disco::register_extra [namespace current]::disco_extra_version]

# vim:ft=tcl:ts=8:sw=4:sts=4:et
