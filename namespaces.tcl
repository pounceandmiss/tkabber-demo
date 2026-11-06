#  namespaces.tcl --
#
#      This file is a part of the Tkabebr XMPP client. It lists Jabber
#      namespaces registered by JSF and haven't yet moved to TclXMPP.
#
#  Copyright (c) 2005 Sergei Golovan <sgolovan@nes.ru>

namespace eval :: {
    array set NS [list \
        iqavatar        "jabber:iq:avatar" \
        xavatar         "jabber:x:avatar" \
        xconference     "jabber:x:conference" \
        event           "jabber:x:event" \
        xroster         "jabber:x:roster" \
        rosterx         "http://jabber.org/protocol/rosterx" \
        chatstate       "http://jabber.org/protocol/chatstates" \
        commands        "http://jabber.org/protocol/commands" \
        private         "jabber:iq:private" \
        delimiter       "roster:delimiter" \
        bookmarks       "storage:bookmarks" \
        tkabber:groups  "tkabber:bookmarks:groups" \
        pubsub          "http://jabber.org/protocol/pubsub" \
        nick            "http://jabber.org/protocol/nick" \
    ]
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
