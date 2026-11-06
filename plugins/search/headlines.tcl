# headlines.tcl --
#
#       This file is a part of the Tkabber XMPP client. It's a plugin which
#       implements search through the received headlines (their subjects and
#       bodies).

namespace eval headlines::search {}

proc headlines::search::open_panel {w dw sf} {
    pack $sf -side bottom -anchor w -fill x -before $dw.sw
    update idletasks
    $w.body see end
}

#############################################################################

proc headlines::search::close_panel {w tw sf} {
    $w.body tag remove search_highlight 0.0 end
    pack forget $sf
    focus $tw
}

#############################################################################

proc headlines::search::setup_panel {w tw uw dw} {
    set body $w.body

    $body mark set sel_start end
    $body mark set sel_end 0.0

    set sf [plugins::search::spanel $w.search \
                -searchcommand [list [namespace current]::do_search $w $tw $uw $dw] \
                -closecommand [list [namespace current]::close_panel $w $tw]]

    if {[winfo exists $tw.c]} {
        set tw $tw.c
    }

    foreach ww [list $tw $w.body $dw.date.ts $dw.from.jid $dw.subject.subj] {
        bind $ww <<OpenSearchPanel>> \
             [double% [list [namespace current]::open_panel $w $dw $sf]]
    }
}

hook::add open_headlines_post_hook \
          [namespace current]::headlines::search::setup_panel

#############################################################################

proc headlines::search::do_search {hw tw uw dw pattern dir} {
    if {![string length $pattern]} {
        return 0
    }

    if {$dir == "up"} {
        set start_node [lindex [$tw selection] 0]
        set node [search_up $hw $tw $uw $dw $start_node $pattern]
    } else {
        set start_node [lindex [$tw selection] end]
        set node [search_down $hw $tw $uw $dw $start_node $pattern]
    }

    if {$node != ""} {
        return 1
    } else {
        return 0
    }
}

##########################################################################

proc headlines::search::search_up {hw tw uw dw node pattern} {
    set body $hw.body
    set subj $dw.subject.subj

    # Try to search in current article
    if {[search_in_article_up $body $subj $pattern]} {
        return $node
    }

    set n [plugins::search::bwtree::prev_node $tw $node]
    while {1} {
        if {($n != {}) && \
                ![catch {array set props [$tw item $n -values]}] && \
                [info exists props(type)] && \
                $props(type) == "article"} {

            set subjtext [string map [list "\n" " "] $props(text)]
            set bodytext "$props(body)\n\n[::msgcat::mc {Read on...}]"
            if {[plugins::search::match $pattern $subjtext] || \
                   [plugins::search::match $pattern $bodytext]} {
                plugins::search::bwtree::search_hilite $tw $n
                if {[search_in_article_up $body $subj $pattern]} {
                    return $n
                }
            }
        }
        if {$n == $node} break
        set n [plugins::search::bwtree::prev_node $tw $n]
    }
    return ""
}

#############################################################################

proc headlines::search::search_in_article_up {body subj pattern} {
    catch {
        set bfirst [$body index search_highlight.first]
        set blast [$body index search_highlight.last]
    }
    catch {
        set sfirst [$subj index search_highlight.first]
        set slast [$subj index search_highlight.last]
    }

    if {![info exists sfirst]} {
        # Try to find pattern in article body

        plugins::search::do_text_search $body $pattern up
        if {![catch {
                  set bfirst1 [$body index search_highlight.first]
                  set blast1 [$body index search_highlight.last]
              }]} {
            if {![info exists bfirst]} {
                return 1
            }
            if {[$body compare $bfirst1 < $bfirst] || \
                 ([$body compare $bfirst1 == $bfirst] && [$body compare $blast1 < $blast])} {
                return 1
            }
            $body tag remove search_highlight 0.0 end
        }

        $subj mark set sel_start end
        $subj mark set sel_end 0.0
    }
    # Then try to find pattern in the subject
    plugins::search::do_text_search $subj $pattern up
    if {![catch {
              set sfirst1 [$subj index search_highlight.first]
              set slast1 [$subj index search_highlight.last]
          }]} {
        if {![info exists sfirst]} {
            return 1
        }
        if {[$subj compare $sfirst1 < $sfirst] || \
             ([$subj compare $sfirst1 == $sfirst] && [$subj compare $slast1 < $slast])} {
            return 1
        }
        $subj tag remove search_highlight 0.0 end
    }
    return 0
}

#############################################################################

proc headlines::search::search_down {hw tw uw dw node pattern} {
    set body $hw.body
    set subj $dw.subject.subj

    # Try to search in current article
    if {[search_in_article_down $body $subj $pattern]} {
        return $node
    }

    set n [plugins::search::bwtree::next_node $tw $node]
    while {1} {
        if {($n != {}) && \
                ![catch {array set props [$tw item $n -values]}] && \
                [info exists props(type)] && \
                $props(type) == "article"} {

            set subjtext [string map [list "\n" " "] $props(text)]
            set bodytext "$props(body)\n\n[::msgcat::mc {Read on...}]"
            if {[plugins::search::match $pattern $subjtext] || \
                   [plugins::search::match $pattern $bodytext]} {
                plugins::search::bwtree::search_hilite $tw $n
                if {[search_in_article_down $body $subj $pattern]} {
                    return $n
                }
            }
        }
        if {$n == $node} break
        set n [plugins::search::bwtree::next_node $tw $n]
    }
    return ""
}

#############################################################################

proc headlines::search::search_in_article_down {body subj pattern} {
    catch {
        set bfirst [$body index search_highlight.first]
        set blast [$body index search_highlight.last]
    }
    catch {
        set sfirst [$subj index search_highlight.first]
        set slast [$subj index search_highlight.last]
    }

    if {![info exists bfirst]} {
        # Try to find pattern in article subject

        plugins::search::do_text_search $subj $pattern down
        if {![catch {
                  set sfirst1 [$subj index search_highlight.first]
                  set slast1 [$subj index search_highlight.last]
              }]} {
            if {![info exists sfirst]} {
                return 1
            }
            if {[$subj compare $sfirst1 > $sfirst] || \
                 ([$subj compare $sfirst1 == $sfirst] && [$subj compare $slast1 > $slast])} {
                return 1
            }
            $subj tag remove search_highlight 0.0 end
        }

        $body mark set sel_start end
        $body mark set sel_end 0.0
    }
    # Then try to find pattern in the body
    plugins::search::do_text_search $body $pattern down
    if {![catch {
              set bfirst1 [$body index search_highlight.first]
              set blast1 [$body index search_highlight.last]
          }]} {
        if {![info exists bfirst]} {
            return 1
        }
        if {[$body compare $bfirst1 > $bfirst] || \
             ([$body compare $bfirst1 == $bfirst] && [$body compare $blast1 > $blast])} {
            return 1
        }
        $body tag remove search_highlight 0.0 end
    }
    return 0
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
