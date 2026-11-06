#!/usr/bin/tclsh

# extract.tcl --
#
#       Extract all msgcat or trans messages for a given language.
#
# Author: Vincent Ricard <vincent@magicninja.org>
# Modified: Sergei Golovan <sgolovan@nes.ru>

package require fileutil
package require cmdline

set msgcat_regexp0 \
    {::msgcat::mcset [a-zA-Z]+[ \t\r\n]+\"(([^\"]|\\\")*)\"}
set msgcat_regexp1 \
    {\[::msgcat::mc[ \t\r\n]+\"(([^\"]|\\\")*)\"}
set msgcat_regexp2 \
    {\[::msgcat::mc[ \t\r\n]+{([^\}]*)}}
set msgcat_regexp3 \
    {\[::msgcat::mc[ \t\r\n]+([^ \t\r\n\{\"\[\]]*)}

set trans_regexp0 \
    {::trans::trset [a-zA-Z]+[ \t\r\n]+\"(([^\"]|\\\")*)\"}
set trans_regexp1 \
    {\[::trans::trans[ \t\r\n]+(\$[^ \t\r\n]+[ \t\r\n]+)?\"(([^\"]|\\\")*)\"}
set trans_regexp2 \
    {\[::trans::trans[ \t\r\n]+(\$[^ \t\r\n]+[ \t\r\n]+)?{([^\}]*)}}
set trans_regexp3 \
    {\[::trans::trans[ \t\r\n]+(\$[^ \t\r\n]+[ \t\r\n]+)?([^ \t\r\n\{\"\[\]]*)}

set options {
    {trans       "Extract ::trans messages (::msgcat messages by default)"}
    {unused      "Show unused translated messages"}
    {lang.arg ?? "Prepare messages for specified language, default is"}
    {showvars.secret "Show translatable strings with variables only"}
}
set usage ": extract.tcl \[options\] directory \[msgfile\]\noptions:"
if {[catch {
         array set params [::cmdline::getoptions argv $options $usage]
     } msg]} {
    puts stderr $msg
    exit 1
}

switch -- [llength $argv] {
    1 {
        set sourceDir [lindex $argv 0]
        set translationFile ""
    }
    2 {
        set sourceDir [lindex $argv 0]
        set translationFile [lindex $argv 1]
    }
    default {
        puts stderr [::cmdline::usage $options $usage]
        exit 1
    }
}

set sourceDir [lindex $argv 0]
set trans $params(trans)
set invertMatch $params(unused)
set lang $params(lang)
if {$lang == "??"} {
    # take lang from the message file name
    regexp {([-a-z]+)\.msg$} $translationFile -> lang
}
set showvars $params(showvars)

proc key_with_var {___key} {
    # The only variable which is defined here is ___key, but
    # it isn't likely to appear in translatable messages
    catch [list eval list $___key]
}

# Read all tcl file from sourceDir
set tclFileList [::fileutil::findByPattern $sourceDir -glob -- *tcl]
foreach filename $tclFileList {
    set fd [open $filename]

    while {[gets $fd line] >= 0} {
        while {[regexp {(^|[^\B])(\B\B)*\B$} $line] && [gets $fd line1] >= 0} {
            set line [string replace $line end end " [string trimleft $line1]"]
        }

        set line1 $line
        # Search: [ ::msgcat::mc "translation key"
        while {[regexp -- $msgcat_regexp1 $line1 whole key] || \
                    [regexp -- $msgcat_regexp2 $line1 whole key] || \
                    [regexp -- $msgcat_regexp3 $line1 whole key]} {
            if {$key != "" && ((![key_with_var $key] && !$showvars) || \
                               ([key_with_var $key] && $showvars))} {
                if {![info exists mkeyHash($filename)]} {
                    # Create a new list (with the current key) for this file
                    set mkeyHash($filename) [list $key]
                } elseif {[lsearch -exact $mkeyHash($filename) $key] < 0} {
                    # key doesn't exist for this file
                    lappend mkeyHash($filename) $key
                }
            }
            set idx [string first $whole $line1]
            set line1 [string replace $line1 0 \
                              [expr {$idx + [string length $whole] - 1}]]
        }

        set line1 $line
        # Search: [ ::trans::trans "translation key"
        while {[regexp -- $trans_regexp1 $line1 whole _lang key] || \
                    [regexp -- $trans_regexp2 $line1 whole _lang key] || \
                    [regexp -- $trans_regexp3 $line1 whole _lang key]} {
            if {$key != "" && ((![key_with_var $key] && !$showvars) || \
                               ([key_with_var $key] && $showvars))} {
                if {![info exists tkeyHash($filename)]} {
                    # Create a new list (with the current key) for this file
                    set tkeyHash($filename) [list $key]
                } elseif {[lsearch -exact $tkeyHash($filename) $key] < 0} {
                    # key doesn't exist for this file
                    lappend tkeyHash($filename) $key
                }
            }
            set idx [string first $whole $line1]
            set line1 [string replace $line1 0 \
                              [expr {$idx + [string length $whole] - 1}]]
        }
    }
    close $fd
}

proc remove_duplicate_keys {hashname} {
    upvar 1 $hashname hash

    set fileList [array names hash]
    for {set i 0} {$i < [llength $fileList]} {incr i} {
        for {set j [expr $i + 1]} {$j < [llength $fileList]} {incr j} {
            foreach k $hash([lindex $fileList $i]) {
                set J [lindex $fileList $j]
                set ix [lsearch -exact $hash($J) $k]
                if {-1 < $ix} {
                    set hash($J) [lreplace $hash($J) $ix $ix]
                }
            }
        }
    }
}

# Remove duplicated keys (through all files)
remove_duplicate_keys mkeyHash
remove_duplicate_keys tkeyHash

proc read_translation_file {filename regexp} {
    # Read translation file
    set fd [open $filename]
    fconfigure $fd -encoding utf-8
    set translated [list]

    while {[gets $fd line] >= 0} {
        while {[regexp {(^|[^\B])(\B\B)*\B$} $line] && [gets $fd line1] >= 0} {
            set line [string replace $line end end " [string trimleft $line1]"]
        }
        if {[regexp -- $regexp $line whole key]} {
            lappend translated $key
        }
    }
    close $fd

    return $translated
}

proc print_all_results {hashname prefix lang} {
    upvar 1 $hashname hash

    foreach f [array names hash] {
        if {[llength $hash($f)] > 0} {
            puts "# $f"
            foreach k [lsort $hash($f)] {
                puts "$prefix $lang \"$k\""
            }
            puts ""
        }
    }
}

if {$showvars} {
    print_all_results mkeyHash ::msgcat::mcset $lang
    print_all_results tkeyHash ::trans::trset $lang
    exit 0
}

if {$trans} {
    upvar 0 tkeyHash hash
    set regexp $trans_regexp0
    set prefix ::trans::trset
} else {
    upvar 0 mkeyHash hash
    set regexp $msgcat_regexp0
    set prefix ::msgcat::mcset
}

if {$translationFile != "" && [file readable $translationFile]} {

    set translated [read_translation_file $translationFile $regexp]

    if {!$invertMatch} {
        # Display untranslated keys
        foreach f [array names hash] {
            set displayFileName 1
            foreach k [lsort $hash($f)] {
                if {[lsearch -exact $translated $k] < 0} {
                    if {$displayFileName} {
                        set displayFileName 0
                        puts "# $f"
                    }
                    puts "$prefix $lang \"$k\""
                }
            }
            if {!$displayFileName} {
                puts ""
            }
        }
    } else {
        # Remove useless keys
        foreach t [lsort $translated] {
            set found 0
            foreach f [array names hash] {
                if {[lsearch -exact $hash($f) $t] >= 0} {
                    set found 1
                }
            }
            if {!$found} {
                puts "\"$t\""
            }
        }
    }
} else {
    if {!$invertMatch} {
        # Print result
        print_all_results hash $prefix $lang
    }
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
