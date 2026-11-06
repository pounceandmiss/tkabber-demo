# csd.tcl --
#
#	A header bar for Tkabber on Wayland: the compositor does not decorate
#	the main window, whose title bar is made of Tk widgets instead (see
#	demos/headerbar.tcl of the Tk Wayland port). It holds the icon of the
#	presence status (click it to change the status), the menus of the
#	menubar and the window buttons. Drag it to move the window,
#	double-click it to maximize the window, press the right button on it
#	for the window menu of the compositor; drag the edges of the window to
#	resize it.
#
#	Does nothing on other windowing systems.

if {[tk windowingsystem] ne "wayland"} {
    return
}

namespace eval csd {
    variable border 4		;# Width of the edges which resize the window.
    variable corner 16		;# Length of the corners along the edges.
    variable radius 10		;# Radius of the rounded corners.
    variable press {}		;# Where button 1 was pressed in the header.
    variable color		;# The colors of the header.
    variable fg			;# The current color of its text.
}

proc csd::colors {} {
    variable color
    lassign [winfo rgb . [.mainframe cget -background]] r g b
    if {$r + $g + $b < 3 * 0x8000} {
	array set color {
	    header #2e2e2e inactive #242424 hover #444444 close #c01c28
	    fg #eeeeee dim #8c8c8c
	}
    } else {
	array set color {
	    header #dededb inactive #efefed hover #c8c8c4 close #e01b24
	    fg #202020 dim #8a8a8a
	}
    }
}

proc csd::setup {} {
    variable color
    variable radius

    colors
    ::tk::wayland::decorations . none
    ::tk::wayland::corners . $radius

    set h [frame .csd -background $color(header) -padx 4 -pady 3]

    # The status icon, with the presence menu.

    label $h.icon -image roster/user/$::curuserstatus -padx 6
    bind $h.icon <ButtonPress-1> {
	if {[winfo exists .presence.button.menu]} {
	    tk_popup .presence.button.menu [winfo rootx %W] \
		    [expr {[winfo rooty %W] + [winfo height %W]}]
	}
    }
    trace add variable ::curuserstatus write [namespace code statusIcon]
    pack $h.icon -side left

    # The menus of the menubar, which the main window no longer has.

    set i 0
    set last [.menubar index end]
    for {set e 0} {$last ne "none" && $e <= $last} {incr e} {
	if {[.menubar type $e] ne "cascade"} {
	    continue
	}
	set l [label $h.menu$i -text [.menubar entrycget $e -label] \
		-underline [.menubar entrycget $e -underline] -padx 7 -pady 2]
	bind $l <ButtonPress-1> [namespace code [list post $l \
		[.menubar entrycget $e -menu]]]
	hoverable $l
	pack $l -side left
	incr i
    }
    . configure -menu {}

    # The window buttons, and empty space up to them, which moves the window.

    foreach {b command} {
	close close
	max toggleMaximized
	min {wm iconify .}
    } {
	canvas $h.$b -width 28 -height 22 -highlightthickness 0 \
		-borderwidth 0
	bind $h.$b <ButtonRelease-1> [namespace code $command]
	hoverable $h.$b [expr {$b eq "close" ? "close" : "hover"}]
	pack $h.$b -side right -padx {2 0}
    }
    frame $h.space
    pack $h.space -side left -fill both -expand yes

    foreach w [list $h $h.space] {
	bind $w <ButtonPress-1> [namespace code {set press [list %X %Y]}]
	bind $w <B1-Motion> [namespace code {headerMotion %X %Y}]
	bind $w <ButtonRelease-1> [namespace code {set press {}}]
	bind $w <Double-ButtonPress-1> [namespace code toggleMaximized]
	bind $w <ButtonPress-3> {::tk::wayland::windowmenu .}
    }
    pack $h -side top -fill x -before .mainframe

    # The edges of the window, around the header and the main frame, resize
    # it.

    bind . <Motion> [namespace code {if {"%W" eq "."} {edgeCursor %X %Y}}]
    bind . <Leave> [namespace code {if {"%W" eq "."} {. configure -cursor {}}}]
    bind . <ButtonPress-1> [namespace code {if {"%W" eq "."} {edgePress %X %Y}}]
    bind . <Configure> [namespace code {if {"%W" eq "."} refresh}]
    bind . <FocusIn> +[list after idle [namespace code refresh]]
    bind . <FocusOut> +[list after idle [namespace code refresh]]
    refresh
}

proc csd::statusIcon {args} {
    if {[winfo exists .csd.icon]} {
	.csd.icon configure -image roster/user/$::curuserstatus
    }
}

# A label of the header which lights up under the pointer.

proc csd::hoverable {w {kind hover}} {
    bind $w <Enter> [namespace code [list hover $w $kind 1]]
    bind $w <Leave> [namespace code [list hover $w $kind 0]]
}

proc csd::hover {w kind on} {
    variable color
    variable fg
    if {$on} {
	paint $w $color($kind) \
		[expr {$kind eq "close" ? "white" : $color(fg)}]
    } else {
	paint $w [.csd cget -background] $fg
    }
}

# Give a widget of the header its colors: a window button is drawn again in
# the color of the text.

proc csd::paint {w bg fg} {
    $w configure -background $bg
    if {[winfo class $w] eq "Canvas"} {
	glyph $w $fg
    } else {
	catch {$w configure -foreground $fg}
    }
}

# Draw the icon of a window button: all of them fit in the same square of
# 9 pixels, with lines of 1 pixel, on half pixels so that they are sharp.

proc csd::glyph {w fg} {
    $w delete all
    set x0 9.5
    set y0 6.5
    set x1 [expr {$x0 + 9}]
    set y1 [expr {$y0 + 9}]
    switch -- [winfo name $w] {
	min {
	    $w create line $x0 $y1 $x1 $y1 -fill $fg
	}
	max {
	    if {[wm attributes . -zoomed]} {
		$w create rectangle $x0 [expr {$y0 + 2}] [expr {$x1 - 2}] $y1 \
			-outline $fg
		$w create line [expr {$x0 + 2}] [expr {$y0 + 2}] \
			[expr {$x0 + 2}] $y0 $x1 $y0 $x1 [expr {$y1 - 2}] \
			[expr {$x1 - 2}] [expr {$y1 - 2}] -fill $fg
	    } else {
		$w create rectangle $x0 $y0 $x1 $y1 -outline $fg
	    }
	}
	close {
	    $w create line $x0 $y0 $x1 $y1 -fill $fg
	    $w create line $x0 $y1 $x1 $y0 -fill $fg
	}
    }
}

proc csd::post {w menu} {
    hover $w hover 0
    tk_popup $menu [winfo rootx $w] [expr {[winfo rooty $w] + [winfo height $w]}]
}

proc csd::close {} {
    set command [wm protocol . WM_DELETE_WINDOW]
    if {$command ne ""} {
	uplevel #0 $command
    } else {
	destroy .
    }
}

proc csd::toggleMaximized {} {
    wm attributes . -zoomed [expr {![wm attributes . -zoomed]}]
}

# Update the window after its state: no resizing edges when maximized, the
# header greyed out when the window is inactive.

proc csd::refresh {} {
    variable color
    variable border
    variable fg
    if {![winfo exists .csd]} {
	return
    }
    set full [expr {[wm attributes . -zoomed] || [wm attributes . -fullscreen]}]
    set pad [expr {$full ? 0 : $border}]
    set active [expr {[focus] ne "" && [winfo toplevel [focus]] eq "."}]
    set bg [expr {$active ? $color(header) : $color(inactive)}]
    set fg [expr {$active ? $color(fg) : $color(dim)}]
    . configure -padx $pad -pady $pad -background $bg
    foreach w [linsert [winfo children .csd] 0 .csd] {
	paint $w $bg $fg
    }
}

proc csd::headerMotion {x y} {
    variable press
    if {$press eq ""} {
	return
    }
    lassign $press x0 y0
    if {abs($x - $x0) > 3 || abs($y - $y0) > 3} {
	set press {}
	::tk::wayland::startmove .
    }
}

# The edge of the window at a point of the screen, or "" if none.

proc csd::edge {X Y} {
    variable border
    variable corner
    if {[. cget -padx] == 0} {
	return ""
    }
    set x [expr {$X - [winfo rootx .]}]
    set y [expr {$Y - [winfo rooty .]}]
    set width [winfo width .]
    set height [winfo height .]
    set v [expr {$y < $border ? "n" : $y >= $height - $border ? "s" : ""}]
    set h [expr {$x < $border ? "w" : $x >= $width - $border ? "e" : ""}]
    if {$v ne "" && $h eq "" && ($x < $corner || $x >= $width - $corner)} {
	set h [expr {$x < $corner ? "w" : "e"}]
    }
    if {$h ne "" && $v eq "" && ($y < $corner || $y >= $height - $corner)} {
	set v [expr {$y < $corner ? "n" : "s"}]
    }
    return $v$h
}

proc csd::edgeCursor {X Y} {
    . configure -cursor [dict get {
	"" {} n top_side s bottom_side w left_side e right_side
	nw top_left_corner ne top_right_corner
	sw bottom_left_corner se bottom_right_corner
    } [edge $X $Y]]
}

proc csd::edgePress {X Y} {
    set edge [edge $X $Y]
    if {$edge ne ""} {
	::tk::wayland::startresize . $edge
    }
}

hook::add finload_hook [namespace current]::csd::setup 100
