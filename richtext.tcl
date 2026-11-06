# richtext.tcl --
#
#       "Rich text" facility for Tk Text widgets -- allows to:
#       * Register parsers and renderers for particular patterns in plain
#         text messages -- "entities";
#       * Parse plain text messages with registered parsers (in order of
#         their priorities);
#       * Render the resulting chunks of text with the appropriate renderers;
#       * Get back the original text from PRIMARY and CLIPBOARD selections
#         acquired from such Text widget.
#
#       This scheme supports URL highlighting, emoticons and such.

namespace eval richtext {
    variable registered
    variable entities
    variable state
    variable texts {}

    # free-form properties for processing of current message
    variable msgprops

    custom::defgroup {Rich Text} \
        [::msgcat::mc "Settings of rich text facility which is used\
                       to render chat messages and logs."] \
        -group Plugins
}

proc richtext::register_entity {type args} {
    variable registered
    variable entities

    lappend registered $type
    set entities($type,priority) 80

    foreach {opt val} $args {
        switch -glob -- $opt {
            -configurator {
                set entities($type,configurator) $val
            }
            -parser {
                set entities($type,parser) $val
            }
            -reconstructor {
                set entities($type,reconstructor) $val
            }
            -renderer {
                set entities($type,renderer) $val
            }
            -parser-priority {
                set entities($type,priority) $val
            }
            default {
                return -code error "[namespace current]::register_entity:\
                                    Unknown option $opt"
            }
        }
    }
}
proc richtext::unregister_entity {type} {
    variable registered
    variable entities

    lexclude registered $type
    array unset entities $type,*
}

proc richtext::entity_state {type {val ""}} {
    variable entities

    if {$val eq ""} {
        set entities($type,enabled)
    } else {
        set entities($type,enabled) $val
    }
}

# Configures a text widget so that the "::richtext::render_message" proc
# can be used on it.

# Accepts an optional parameter "-using ?list_of_entities?"; when specified,
# the text widget is configured to support only the specified entities,
# otherwise it's configured to support all registered entities. If the list
# is empty, this is *almost* a no-op: render_message can be called on such
# widget, but it won't trigger any special processing of the passed text.

# NOTE that currently this proc can be safely called only once per widget
# since it essentially has a "constructor" semantics (though it requires
# an already created text widget).

proc richtext::config {w args} {
    variable registered
    variable entities
    variable state
    variable texts

    lappend texts $w

    # By default, configure for all registered entities:
    set using $registered

    # Parse options:
    foreach {opt val} $args {
        switch -- $opt {
            -using {
                set using $val
            }
            default {
                return -code error "[namespace current]::config:\
                                    Unknown option: $opt"
            }
        }
    }

    # Run configurators for requested entities:
    foreach type $using {
        if {[info exists entities($type,configurator)]} {
            $entities($type,configurator) $w
        }
    }

    # Save enabled entities in the widget state, sorted by the
    # parsing priority:
    set state($w,types) [lsort -command compare_entity_prios $using]

    # Register a kind of "destructor" to clean up state:
    bind $w <Destroy> \
            +[list [namespace current]::richtext_on_destroy [double% $w]]
}

# Cleans up state of richtext widgets:
proc richtext::richtext_on_destroy {w} {
    variable state
    variable texts

    lexclude texts $w
    array unset state $w,*
}

proc richtext::textlist {} {
    variable texts
    return $texts
}

proc richtext::compare_entity_prios {a b} {
    variable entities

    expr {$entities($a,priority) - $entities($b,priority)}
}

# Configure a text widget to be ready for enriched text:
proc richtext::richtext {args} {
    set w [Text {*}$args]
    config $w
    install_selection_handlers $w
    $w configure -state disabled -font $::ChatFont
}

# TODO get rid of "deftag"
proc richtext::render_message {w body deftag {nonewline ""}} {
    variable entities
    variable state
    variable msgprops

    # Parse the message text with rich text entity parsers:
    set chunks [list $body text $deftag]
    foreach type $state($w,types) {
        if {$entities($type,enabled) && [info exists entities($type,parser)]} {
            {*}$entities($type,parser) [info level] chunks
        }
    }

    # Render the parsed pieces with entity renderers:
    foreach {piece type tags} $chunks {
        #puts "(draw) piece: $piece; type: $type; tags: $tags"

        if {![info exists entities($type,renderer)]} {
            # Fallback
            debugmsg richtext "Got piece with unknown type $type"
            set type text
        }

        $entities($type,renderer) $w $type $piece $tags
    }

    if {$nonewline ne "-nonewline"} {
        $w insert end \n
    }

    # Get rid of the current message properties
    array unset msgprops *
}

proc richtext::fixup_tags {tags tgroups} {
    foreach t $tags {
        set thash($t) 0
    }

    foreach tg $tgroups {
        glue_tags thash $tg
    }

    return [array names thash]
}

proc richtext::glue_tags {arrayName tags} {
    upvar 1 $arrayName thash

    foreach t $tags {
        if {![info exists thash($t)]} return
    }

    foreach t $tags {
        unset thash($t)
    }

    set t [join $tags _]
    set thash($t) 0
}

# Selection handlers are "wrapped" by Tk so that they cannot fail
# due to errors since they are silenced.
# So this proc is kind of "error-enabled selection handler" -- it will
# raise any error occured in the selection handler.
proc richtext::chk_reconstruct_text {w first last} {
    if {[catch [list reconstruct_text $w $first $last] out]} {
        after idle [list error $out]
        return
    } else {
        return $out
    }
}

# Parses the contents of Text widget $w from $first to $last
# and returns reconstructed "plain text".
# It's main purpose is to return the "original" text that was
# submitted to that Text widget and then undergone
# "rich text" processing.
proc richtext::reconstruct_text {w first last} {
    variable state

    #puts "in [info level 0]"

    if {[catch {$w dump -text -tag $first $last} dump]} {
        #puts "dump failed: $dump"
        return {}
    }

    set dump [concat {start {} {}} $dump {end {} {}}]

    #puts "ready to parse: $dump"

    foreach {what val where} $dump {
        #puts "what: $what; val: $val; where $where"
        switch -- $what {
            start {
                set out ""
                set in nowhere
                set chunk ""
                set tags {}
                set ignore false
            }
            tagon {
                if {[lsearch $state($w,types) $val] >= 0} {
                    if {$in ne "tag"} { write_chunk_out out chunk $tags }
                    lappend tags $val
                    set in tag
                } elseif {$val eq "transient"} {
                    set ignore true
                }
            }
            tagoff {
                if {[lsearch $state($w,types) $val] >= 0} {
                    if {$in ne "tag"} { write_chunk_out out chunk $tags }
                    lexclude tags $val
                    set in tag
                } elseif {$val eq "transient"} {
                    set ignore false
                }
            }
            text {
                if {$ignore} continue
                append chunk $val
                set in text
            }
            image {
                set chunk $val
                set in image
            }
            end {
                if {$ignore} continue
                if {$in ne "tag"} { write_chunk_out out chunk $tags }
            }
        }
    }

    #puts "parsed sel: $out"

    return $out
}

proc richtext::write_chunk_out {outVar chunkVar t} {
    upvar 1 $outVar out $chunkVar chunk
    variable entities

    if {[string length $chunk] == 0} return

    if {[llength $t] > 1} {
        #puts stderr "chunk $chunk belongs to several rich text entities: $t"
    }

    if {[info exists entities($t,reconstructor)]} {
        append out [$entities($t,reconstructor) $t $chunk]
    } else {
        append out $chunk
    }

    set chunk ""
}

# Used to handle PRIMARY selection requests on "rich text" widgets
proc richtext::get_selection {w off max} {
    return [string range \
                   [chk_reconstruct_text $w sel.first sel.last] \
                   $off [expr {$off + $max}]]
}

# Used to subvert tk_textCopy on "rich text" widgets
proc richtext::text_copy {w} {
    set data [chk_reconstruct_text $w sel.first sel.last]
    clipboard clear -displayof $w
    clipboard append -displayof $w $data
}

# Used to subvert tk_textCut on "rich text" widgets
proc richtext::text_cut {w} {
    set data [chk_reconstruct_text $w sel.first sel.last]
    clipboard clear -displayof $w
    clipboard append -displayof $w $data
    $w delete sel.first sel.last
}

# Installs selection handlers on a text widget.
# 1) There's only need to support PRIMARY selection of type STRING
#    since all other types are only used in application-private protocols
#    (except UTF8_STRING, which is used by UTF-8-enabled software);
# 2) Tk automagically handles UTF8_STRING if the handler for STRING
#    is installed;
# 3) (2) is not exactly true, see Tk bug #1571737, we work around it here.

proc richtext::install_selection_handlers {w} {
    # Handlers for PRIMARY selection:
    selection handle -type UTF8_STRING $w {}
    selection handle -type STRING $w \
              [list [namespace current]::get_selection $w]

    # Handlers of CLIPBOARD selections
    # (subvert tk_textCopy and tk_textCut)
    bind $w <<Copy>> [list [namespace current]::text_copy [double% $w]]
    bind $w <<Cut>>  [list [namespace current]::text_cut [double% $w]]
}

proc richtext::render_text {w type piece tags} {
    $w insert end $piece [fixup_tags $tags {{bold italic}}]
}

proc richtext::highlighttext {w tag color cursor} {
    $w configure -cursor $cursor
    $w tag configure $tag -foreground $color
}

# Message properties may be added before [::richtext::render_message]
# is called and are intended to be used by rich text plugins whatever
# they wish to use them.
# Message properties are automatically killed when message rendering
# process is over.

# Assotiates "message property" $name and assigns value $val to it:
proc richtext::property_add {name value} {
    variable msgprops

    if {[info exists msgprops($name)]} {
        return -code error "[namespace current]::property_add:\
                            Attempted to overwrite message property: $name"
    }

    set msgprops($name) $value
}

# Unlike _add, allows stomping on existing property value:
proc richtext::property_update {name value} {
    variable msgprops

    set msgprops($name) $value
}

proc richtext::property_get {name} {
    variable msgprops

    set msgprops($name)
}

proc richtext::property_exists {name} {
    variable msgprops

    info exists msgprops($name)
}

# Register the most basic renderer for type "text":
richtext::register_entity text -renderer richtext::render_text
richtext::entity_state text 1

# vim:ft=tcl:ts=8:sw=4:sts=4:et
