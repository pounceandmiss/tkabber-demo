# default.tcl --
#
#       This file is a part of the Tkabber XMPP browser. It defines the default
#       empty postload and finload procedure and the browseurl procedure which
#       is called when user clicks on an HTTP link in chatlog windows.

proc postload {} {}

proc menuload {menudesc} { return $menudesc }

proc finload  {} {}

proc browser_loadopt {} {
    custom::defvar webbrowser "" \
        [::msgcat::mc "Command to be run when you click a URL\
                       in a message. '%s' will be replaced with this\
                       URL (e.g. \"chromium %s >>& /dev/null\" or\
                       \"{C:/Program Files (x86)/Mozilla\
                       Firefox/firefox.exe} %s\")."] \
        -group IFace -type string
}

hook::add postload_hook browser_loadopt

proc browseurl {url} {
    global env tcl_platform

    set_status $url
    update idletask

    set url [string map {\u0009 %09 \u000a %0a \u000d %0d \u0020 %20
                         \" %22 \' %27 \< %3c \> %3e
                         \{ %7b \| %7c \} %7d \\ %5c} $url]

    debugmsg browseurl "Mapped URL: '$url'"

    if {[info exists ::webbrowser] && $::webbrowser != ""} {
        # If user specified a browser, use it
        
        set args {}
        if {[catch {llength $::webbrowser}]} {
            error "Can't process the \$::webbrowser variable.\
                   It must be a list of words."
        } else {
            if {$tcl_platform(platform) eq "windows" && $tcl_platform(os) eq "Windows NT" && \
                    [regexp -nocase {^(.*[\\/])?cmd(\.exe)?$} [lindex $::webbrowser 0]]} {
                set url [string map {& ^&} $url]
            }

            foreach word $::webbrowser {
                lappend args [format $word $url]
            }
        }
        exec {*}$args &
        return
    }

    switch -- $tcl_platform(platform) {
        windows {
            # The windows NT shell treats '&' as a special character. Using
            # a '^' will escape it. See https://wiki.tcl.tk/557 for more info.

            if {$tcl_platform(os) eq "Windows NT" && $tcl_platform(osVersion) < 6.1} {
                set url [string map {& ^&} $url]
            }
            if {[catch { exec {*}[auto_execok start] {} $url & } emsg]} {
                MessageDlg .browse_err \
                           -icon error \
                           -aspect 50000 \
                           -buttons ok \
                           -default 0 \
                           -cancel 0 \
                           -type user \
                           -message \
                                [::msgcat::mc "Error displaying %s in\
                                               browser\n\n%s" \
                                              $url $emsg]
            }
        }
        macintosh {
            if {[info exists env(BROWSER)]} {
                set browser $env(BROWSER)
            } else {
                set browser "Browse the Internet"
            }
            AppleScript execute \
                "tell application \"$browser\"\nopen url \"$url\"\nend tell\n"
        }
        default {
            if {[info exists env(BROWSER)]} {
                set browser $env(BROWSER)
            } else {
                foreach b [list xdg-open sensible-browser \
                                chrome chromium \
                                firefox mozilla-firefox iceweasel \
                                mozilla netscape \
                                opera konqeror] {
                    if {[llength [set e [auto_execok $b]]] > 0} {
                        set browser [lindex $e 0]
                        break
                    }
                }
            }
            if {![info exists browser]} {
                if {[string equal $tcl_platform(os) Darwin]} {
                    exec open $url &
                } else {
                    MessageDlg .browse_err \
                               -icon error \
                               -aspect 50000 \
                               -message [::msgcat::mc "Please define\
                                                       environment variable\
                                                       BROWSER"] \
                               -type user \
                               -buttons ok \
                               -default 0 \
                               -cancel 0
                }
            } else {
                debugmsg browseurl "Browser: '$browser'"
                exec $browser $url &
            }
        }
    }

    set_status ""
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
