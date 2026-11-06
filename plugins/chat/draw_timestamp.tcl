# draw_timestamp.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       outputs the message timestamp into chatlog windows. Format of the
#       timestamps is customizable.

custom::defvar options(timestamp_format) {[%R]} \
    [::msgcat::mc "Format of timestamp in chat message.\
                   Refer to Tcl documentation of 'clock' command for\
                   description of format.\n\nExamples:\n \
                   \[%R\] - \[20:37\]\n  \[%T\] - \[20:37:12\]\n \
                   \[%a %b %d %H:%M:%S %Z %Y\] -\
                   \[Thu Jan 01 03:00:00 MSK 1970\]"] \
    -type string -group Chat

custom::defvar options(delayed_timestamp_format) {[%m/%d %R]} \
    [::msgcat::mc "Format of timestamp in delayed chat messages delayed\
                   for more than 24 hours."] \
    -type string -group Chat

proc draw_timestamp {chatid from type body x} {
    variable options

    set chatw [chat::chat_win $chatid]

    set seconds [::xmpp::xml::getAttr [::xmpp::delay::parse $x] seconds]
    set seconds1 [expr {[clock seconds] - 24*60*60 + 60}]
    if {$seconds <= $seconds1} {
        set format $options(delayed_timestamp_format)
    } else {
        set format $options(timestamp_format)
    }

    $chatw insert end [clock format $seconds -format $format]
}

hook::add draw_message_hook [namespace current]::draw_timestamp 9

# vim:ft=tcl:ts=8:sw=4:sts=4:et
