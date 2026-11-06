# default.tcl --
#
#       This file is a part of the Tkabber XMPP client. It defines the
#       default geometry for Tkabber windows, fonts for rosters and
#       chatlog windows, and provides a few useful bindings.

set priority 21

option add *Chat.chatgeometry      [winfo pixels . 12c]x[winfo pixels . 12c] $priority
option add *Chat.groupchatgeometry [winfo pixels . 15c]x[winfo pixels . 15c] $priority
option add *Customize.geometry     [winfo pixels . 18c]x[winfo pixels . 15c] $priority
option add *RawXML.geometry        [winfo pixels . 15c]x[winfo pixels . 15c] $priority
option add *Stats.geometry         [winfo pixels . 15c]x[winfo pixels . 15c] $priority
option add *Messages.geometry      [winfo pixels . 18c]x[winfo pixels . 15c] $priority
option add *JDisco.geometry        [winfo pixels . 15c]x[winfo pixels . 15c] $priority

option add *insertWidth           [winfo pixels . 0.25m] $priority
option add *RawXML.inputheight             4             $priority

option add *font                           TkDefaultFont $priority

option add *Menubutton.indicatorOn         1             $priority
option add *Chat*Menubutton.indicatorOn    0             $priority
option add *Message*Menubutton.indicatorOn 0             $priority
option add *Menubutton.relief              raise         $priority
option add *Chat*Menubutton.relief         flat          $priority
option add *Message*Menubutton.relief      flat          $priority

if {$::darktheme} {
    # Color of inactive urls in text
    option add *urlforeground steelblue1 $priority
    # Color of active urls in text
    option add *urlactiveforeground skyblue $priority
    # Colors of erroneous words (when ispell module is using)
    option add *Text.errorColor coral3 $priority
    option add *Text.comboColor steelblue1 $priority
    # Color for highlighting found items
    option add *highlightSearchBackground darkolivegreen4 $priority
} else {
    # Color of inactive urls in text
    option add *urlforeground dodgerblue4 $priority
    # Color of active urls in text
    option add *urlactiveforeground dodgerblue3 $priority
    # Colors of erroneous words (when ispell module is using)
    option add *Text.errorColor firebrick4 $priority
    option add *Text.comboColor dodgerblue4 $priority
    # Color for highlighting found items
    option add *highlightSearchBackground #c1eec1 $priority
}

if {$::tcl_platform(platform) eq "unix" && \
        ([catch {tk::pkgconfig get fontsystem} fontsystem] || \
         $fontsystem ne "xft")} {
    set ::XLFDFonts 1
} else {
    set ::XLFDFonts 0
}

proc create_default_fonts {class} {
    global ${class}Font ${class}BoldFont ${class}ItalicFont \
           ${class}BoldItalicFont

    # Getting the default font in text widget
    set f [frame .tmpframe -class $class]
    set t [text $f.tmptext]
    set ${class}Font [lindex [$t configure -font] 4]
    font create ${class}Font {*}[font actual [set ${class}Font]]
    set ${class}BoldFont [option get .tmpframe boldFont $class]
    set ${class}ItalicFont [option get .tmpframe italicFont $class]
    set ${class}BoldItalicFont [option get .tmpframe boldItalicFont $class]
    destroy $f

    if {!$::XLFDFonts} {
        set ::default_${class}_font \
            [list [font actual ${class}Font -family] \
                  [font actual ${class}Font -size]]
        set ${class}Font ${class}Font
    }

    if {!$::XLFDFonts || [set ${class}BoldFont] eq ""} {
        set ${class}BoldFont \
            [font create ${class}BoldFont {*}[font configure ${class}Font] \
                         -weight bold]
    }
    if {!$::XLFDFonts || [set ${class}ItalicFont] eq ""} {
        set ${class}ItalicFont \
            [font create ${class}ItalicFont {*}[font configure ${class}Font] \
                         -slant italic]
    }
    if {!$::XLFDFonts || [set ${class}BoldItalicFont] eq ""} {
        set ${class}BoldItalicFont \
            [font create ${class}BoldItalicFont \
                         {*}[font configure ${class}Font] \
                         -weight bold -slant italic]
    }
}

proc redefine_fonts {class args} {
    font configure ${class}Font {*}$args
    font configure ${class}BoldFont {*}[font configure ${class}Font] \
                   -weight bold
    font configure ${class}ItalicFont {*}[font configure ${class}Font] \
                   -slant italic
    font configure ${class}BoldItalicFont {*}[font configure ${class}Font] \
                   -weight bold -slant italic
}

create_default_fonts Chat
create_default_fonts Roster

if {![info exists usetabbar]} {
    set usetabbar 1
}

bind Text <<ScrollUp>> {
    %W yview scroll -5 units
}
bind Text <<ScrollDown>> {
    %W yview scroll 5 units
}
bind Listbox <<ScrollUp>> {
    %W yview scroll -5 units
}
bind Listbox <<ScrollDown>> {
    %W yview scroll 5 units
}
bind Treeview <<ScrollUp>> {
    %W yview scroll -5 units
}
bind Treeview <<ScrollDown>> {
    %W yview scroll 5 units
}

bind Text <<ScrollLeft>> {
    %W xview scroll -10 units
}
bind Text <<ScrollRight>> {
    %W xview scroll 10 units
}
bind Listbox <<ScrollLeft>> {
    %W xview scroll -10 units
}
bind Listbox <<ScrollRight>> {
    %W xview scroll 10 units
}
bind Treeview <<ScrollLeft>> {
    %W xview scroll -10 units
}
bind Treeview <<ScrollRight>> {
    %W xview scroll 10 units
}

if {([catch {tk windowingsystem}] && $::tcl_platform(platform) eq "unix") ||
        (![catch {tk windowingsystem}] && [tk windowingsystem] eq "x11")} {
    event add <<ScrollUp>>    <4>
    event add <<ScrollDown>>  <5>
    event add <<ScrollLeft>>  <Shift-4>
    event add <<ScrollRight>> <Shift-5>
}

if {$::tcl_platform(platform) eq "windows"} {
    # workaround for shortcuts in russian keyboard layout
    event add <<Cut>>   <Control-division>
    event add <<Copy>>  <Control-ntilde>
    event add <<Paste>> <Control-igrave>
    event add <<Undo>>  <Control-ydiaeresis>
    event add <<Redo>>  <Control-ssharp>
    event add <<CollapseRoster>>  <Control-ecircumflex>
    event add <<OpenSearchPanel>> <Control-ucircumflex>
}

if {[event info <<ContextMenu>>] eq ""} {
    # tk < 8.6
    if {$::aquaP} {
        # workaround for tk < 8.6.1
        set context 2
    } else {
        set context 3
    }
    event add <<ContextMenu>> <$context>
}
if {[event info <<PasteSelection>>] eq ""} {
    if {$::aquaP} {
        set middle 2
    } else {
        set middle 3
    }
    event add <<PasteSelection>> <$middle>
}

# vim:ft=tcl:ts=8:sw=4:sts=4:et
