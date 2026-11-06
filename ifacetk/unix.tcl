# unix.tcl --
#
#       This file is a part of the Tkabber XMPP client. It add the
#       default XRDB options for the Tkabber widgets on Unix.

set priority 21

if {!$::darktheme} {
    # Scrollbar bed color
    option add *troughColor        #cccccc $priority

    option add *background         #dddddd $priority
    option add *readonlyBackground #dddddd $priority
    option add *foreground         #000000 $priority
    option add *disabledForeground #888888 $priority
    option add *errorForeground    firebrick $priority

    # Colors, which are used when mouse is over the item
    option add *activeBackground   #ebebeb $priority
    option add *activeForeground   #000000 $priority

    # Colors and border width selected item
    option add *selectBackground         #d1eeee $priority
    option add *selectForeground         #000000 $priority
    option add *inactiveSelectBackground #d1eeee $priority
}
option add *selectBorderWidth        0 $priority

if {!$::darktheme} {
    # Color for checkboxes and radiobuttons
    option add *selectColor      #f4f4f4 $priority
    option add *Menu*selectColor #000000 $priority

    # Color of traversal highlight rectangle
    option add *highlightBackground #dddddd $priority
    option add *highlightColor      #666666 $priority

    # Color of insertion cursor
    option add *insertBackground    #000000 $priority
}
# Depth of scrollbars
option add *Scrollbar*borderWidth        [winfo pixels . 0.25m] $priority
option add *Scrollbar*elementBorderWidth [winfo pixels . 0.25m] $priority

# Menu border
option add *Menu*borderWidth             [winfo pixels . 0.25m] $priority

if {!$::darktheme} {
    # Progressbars are used in the splash screen and in the file transfer dialogs
    option add *ProgressBar.foreground       #334080 $priority
}
option add *ProgressBar*borderWidth      [winfo pixels . 0.25m] $priority

if {!$::darktheme} {
    # Flatten Spinbox, ComboBox and ArrowButton
    option add *Spinbox.background                #eeeeee $priority
    option add *Spinbox.buttonBackground          #dddddd $priority
    option add *Spinbox.disabledBackground        #dddddd $priority
    option add *SpinBox*Entry*highlightBackground #eeeeee $priority
}
option add *Spinbox.borderWidth               [winfo pixels . 0.25m] $priority
option add *SpinBox.borderWidth               [winfo pixels . 0.25m] $priority
option add *ComboBox.borderWidth              [winfo pixels . 0.25m] $priority
option add *ArrowButton.borderWidth           0 $priority
option add *ArrowButton.highlightThickness    0 $priority

if {!$::darktheme} {
    # Colors for multicolumn listboxes (as in search result window)
    option add *Mclistbox.background              #eeeeee $priority
    option add *Mclistbox.labelActiveBackground   #ebebeb $priority
    option add *Mclistbox.labelBackground         #dddddd $priority
}
option add *Mclistbox*borderWidth             [winfo pixels . 0.25m] $priority
option add *Mclistbox.highlightThickness      [winfo pixels . 0.25m] $priority

if {!$::darktheme} {
    # Tree widget colors (service discovery)
    option add *Tree*background                   #eeeeee $priority
}
option add *Tree*borderWidth                  [winfo pixels . 0.25m] $priority
option add *Tree.highlightThickness           [winfo pixels . 0.25m] $priority

if {!$::darktheme} {
    # Roster background
    option add *Roster.cbackground          #eeeeee $priority
    option add *Roster.jidfill              #eeeeee $priority
    option add *Roster.jidborder            #eeeeee $priority
    option add *Roster.connectionfill       #eeeeee $priority
    option add *Roster.connectioncfill      #eeeeee $priority

    # Discovery tree branches color
    # Colors for browser and discovery service windows
    option add *JBrowser.fill               #000000 $priority
    option add *JBrowser.activefill         #000000 $priority
    option add *JBrowser.border             #eeeeee $priority
    option add *JBrowser.nscolor            #666666 $priority
    option add *JBrowser.nsactivecolor      #666666 $priority
}
option add *JBrowser.highlightThickness [winfo pixels . 0.25m] $priority

if {!$::darktheme} {
    option add *JDisco.fill                 #000000 $priority
    option add *JDisco.activefill           #000000 $priority
    option add *JDisco.border               #eeeeee $priority
    option add *JDisco.featurecolor         #666666 $priority
    option add *JDisco.identitycolor        DarkGreen $priority
    option add *JDisco.optioncolor          DarkViolet $priority
    option add *linesfill                   #000000 $priority
    option add *crossfill                   #000000 $priority
}
option add *JDisco.highlightThickness   [winfo pixels . 0.25m] $priority

if {!$::darktheme} {
    # Tooltip options
    option add *Balloon*background          #ffeeaa $priority
    option add *Balloon*foreground          #000000 $priority
    option add *DynamicHelp.background      #ffeeaa $priority
    option add *DynamicHelp.foreground      #000000 $priority

    # Listbox colors (various lists)
    option add *Listbox.background          #eeeeee $priority
    option add *Listbox.foreground          #000000 $priority
}
option add *Listbox.borderWidth         [winfo pixels . 0.25m] $priority

if {!$::darktheme} {
    # Text main colors
    option add *Chat*Text*Label.background  #eeeeee $priority
    option add *Text.background             #eeeeee $priority
    option add *Text.foreground             #000000 $priority
}
option add *Text.borderWidth            [winfo pixels . 0.25m] $priority
option add *Text.highlightThickness     [winfo pixels . 0.25m] $priority

if {!$::darktheme} {
    # Entry colors (ordinary and inside notebooks)
    option add *Entry.background            #eeeeee $priority
    option add *Entry.foreground            #000000 $priority
}
option add *Entry.borderWidth           [winfo pixels . 0.25m] $priority
option add *Entry.highlightThickness    [winfo pixels . 0.25m] $priority

if {!$::darktheme} {
    option add *NoteBook*Entry.background         #eeeeee $priority
    option add *NoteBook*Entry.disabledBackground #dddddd $priority
    option add *NoteBook*Entry.readonlyBackground #dddddd $priority
    option add *NoteBook*Entry.foreground         #000000 $priority

    option add *Customize.Text.Button.foreground  black $priority
}
option add *Button.borderWidth                [winfo pixels . 0.25m] $priority
option add *Button.highlightThickness         [winfo pixels . 0.25m] $priority

option add *Radiobutton.highlightThickness    [winfo pixels . 0.25m] $priority
option add *Checkbutton.highlightThickness    [winfo pixels . 0.25m] $priority

option add *Menu.activeBorderWidth            [winfo pixels . 0.25m] $priority
option add *Menu.borderWidth                  [winfo pixels . 0.25m] $priority
option add *Menubutton.borderWidth            [winfo pixels . 0.25m] $priority

option add *Buttonbox*borderWidth             0 $priority
option add *Buttonbox*activeBorderWidth       0 $priority

option add *Scrollbar.width                   [winfo pixels . 2.5m] $priority

# vim:ft=tcl:ts=8:sw=4:sts=4:et
