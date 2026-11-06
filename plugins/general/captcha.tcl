# captcha.tcl --
#
#       CAPTCHA Forms support (XEP-0158)

namespace eval captcha {
    hook::add message_process_x_hook [namespace current]::process_x 10
}

###############################################################################

proc captcha::process_x {rowvar bodyvar f x xlib from id type replyP} {
    upvar 2 $rowvar row
    upvar 2 $bodyvar body

    set captcha 0
    foreach xa $x {
        ::xmpp::xml::split $xa tag xmlns attrs cdata subels

        if {![string equal $xmlns urn:xmpp:captcha]} {
            continue
        }

        set captcha 1

        lassign [::xmpp::data::findForm $subels] type form
        if {[string equal $type form]} {
            if {[catch {process_x_data $f $xlib $from $form}]} {
                # Cannot process CAPTCHA form, so falling back to a
                # legacy CAPTCHA method if any.
                # TODO: Show error message to user.
                set captcha 0
            }
        }
    }

    if {!$captcha} {
        return
    } else {
        set body ""
        return -code break
    }
}

proc captcha::process_x_data {f xlib from x} {
    data::draw_window [list $x] \
                      [namespace code [list send_x_data $xlib $from]] \
                      -title [::msgcat::mc "CAPTCHA from %s" $from]
}

proc captcha::send_x_data {xlib to w restags} {
    ::xmpp::sendIQ $xlib set \
                   -query [::xmpp::xml::create captcha \
                                        -xmlns urn:xmpp:captcha \
                                        -subelements $restags] \
                   -to $to \
                   -command [list [namespace current]::result $xlib $to]
    destroy $w
}

proc captcha::result {xlib to status xml} {
    # TODO
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
