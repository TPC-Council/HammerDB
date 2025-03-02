# tkpath.tcl --
#
# 20160121 ensemble version created
#
#       Various support procedures for the tkpath package.
#
#  Copyright (c) 2016 r.zaumseil@freenet.de
#

namespace eval ::tkp {
    namespace export *
    namespace ensemble create -map {matrix ::tkp::matrix path ::tk::path}

    # All functions inside this namespace return a transormation matrix.
    namespace eval matrix {
	namespace export *
	namespace ensemble create
    }

    # All functions inside this namespace return a path description.
    namespace eval path {
	namespace export *
	namespace ensemble create
    }
}


# ::tkp::matrix::rotate --
# Arguments:
#	angle	Angle in grad
#	cx	X-center coordinate
#	cy	Y-center coordinate
# Results:
#       The transformation matrix.
proc ::tkp::matrix::rotate {angle {cx 0} {cy 0}} {
    set myCos [expr {cos($angle)}]
    set mySin [expr {sin($angle)}]
    if {$cx == 0 && $cy == 0} {
	return [list [list $myCos $mySin] [list [expr {-1.*$mySin}] $myCos] {0 0}]
    }
    return [list [list $myCos $mySin] [list [expr {-1.*$mySin}] $myCos] \
	[list [expr {$cx - $myCos*$cx + $mySin*$cy}] \
	[expr {$cy - $mySin*$cx - $myCos*$cy}]]]
}

# ::tkp::matrix::scale --
# Arguments:
#	sx	Scaling factor x-coordinate
#	sy	Scaling factor y-coordinate
# Results:
#       The transformation matrix.
proc ::tkp::matrix::scale {sx {sy {}}} {
    if {$sy eq {}} {set sy $sx}
    return [list [list $sx 0] [list 0 $sy] {0 0}]
}

# ::tkp::matrix::flip --
# Arguments:
#	fx	1 no flip, -1 horizontal flip
#	fy	1 no flip, -1 vertical flip
# Results:
#       The transformation matrix.
proc ::tkp::matrix::flip {{cx 0} {cy 0} {fx 1} {fy 1}} {
    return [list [list $fx 0] [list 0 $fy] \
	[list [expr {$cx*(1-$fx)}] [expr {$cy*($fy-1)}]]]
}

# ::tkp::matrix::rotateflip --
# Arguments:
#	angle	Angle in grad
#	cx	X-center coordinate
#	cy	Y-center coordinate
#	fx	1 no flip, -1 horizontal flip
#	fy	1 no flip, -1 vertical flip
# Results:
#       The transformation matrix.
proc ::tkp::matrix::rotateflip {{angle 0} {cx 0} {cy 0} {fx 1} {fy 1}} {
    set myCos [expr {cos($angle)}]
    set mySin [expr {sin($angle)}]
    if {$cx == 0 && $cy == 0} {
	return [list [list [expr {$fx*$myCos}] [expr {$fx*$mySin}]] \
	    [list [expr {-1.*$mySin*$fy}] [expr {$myCos*$fy}]] {0 0}]
    }
    return [list [list [expr {$fx*$myCos}] [expr {$fx*$mySin}]] \
	[list [expr {-1.*$mySin*$fy}] [expr {$myCos*$fy}]] \
        [list \
       	[expr {$myCos*$cx*(1.-$fx) - $mySin*$cy*($fy-1.) + $cx - $myCos*$cx + $mySin*$cy}] \
        [expr {$mySin*$cx*(1.-$fx) + $myCos*$cy*($fy-1.) + $cy - $mySin*$cx - $myCos*$cy}] \
	]]

}

# ::tkp::matrix::skewx --
# Arguments:
#	angle	Angle in grad
# Results:
#       The transformation matrix.
proc ::tkp::matrix::skewx {angle} {
    return [list {1 0} [list [expr {tan($angle)}] 1] {0 0}]
}

# ::tkp::matrix::skewy --
# Arguments:
#	angle	Angle in grad
# Results:
#       The transformation matrix.
proc ::tkp::matrix::skewy {angle} {
    return [list [list 1 [expr {tan($angle)}]] {0 1} {0 0}]
}

# ::tkp::matrix::move --
# Arguments:
#	dx	Difference in x direction
#	dy	Difference in y direction
# Results:
#       The transformation matrix.
proc ::tkp::matrix::move {dx dy} {
    return [list {1 0} {0 1} [list $dx $dy]]
}

# ::tkp::matrix::mult --
# Arguments:
# 	ma	First matrix
# 	mb	Second matrix
# Results:
#       Product of transformation matrices.
proc ::tkp::matrix::mult {ma mb} {
    foreach {ma1 ma2 ma3} $ma {mb1 mb2 mb3} $mb {
	lassign $ma1 a1 b1
	lassign $ma2 c1 d1
	lassign $ma3 x1 y1
	lassign $mb1 a2 b2
	lassign $mb2 c2 d2
	lassign $mb3 x2 y2
    }
    return [list \
	[list [expr {$a1*$a2 + $c1*$b2}] [expr {$b1*$a2 + $d1*$b2}]] \
	[list [expr {$a1*$c2 + $c1*$d2}] [expr {$b1*$c2 + $d1*$d2}]] \
	[list [expr {$a1*$x2 + $c1*$y2 + $x1}] [expr {$b1*$x2 + $d1*$y2 + $y1}]]] 
}

# ::tkp::path::ellipse --
# Arguments:
#	x	Start x coordinate
#	y	Start y coordinate
#	rx	Radius in x direction
#	ry	Radius in y direction
# Results:
#	The path definition.
proc ::tkp::path::ellipse {x y rx ry} {
    return [list M $x $y a $rx $ry 0 1 1 0 [expr {2*$ry}] a $rx $ry 0 1 1 0 [expr {-2*$ry}] Z]
}

# ::tkp::path::circle --
# Arguments:
#	x	Start x coordinate
#	y	Start y coordinate
#	r	Radius of circle
# Results:
#       The path definition.
proc ::tkp::path::circle {x y r} {
    return [list M $x $y a $r $r 0 1 1 0 [expr {2*$r}] a $r $r 0 1 1 0 [expr {-2*$r}] Z]
}

# ::tkp::gradientstopsstyle --
#       Utility function to create named example gradient definitions.
# Arguments:
#       name      the name of the gradient
#       args
# Results:
#       The stops list.
proc ::tkp::gradientstopsstyle {name args} {
    switch -- $name {
	rainbow {
	    return {
		{0.00 "#ff0000"}
		{0.15 "#ff7f00"}
		{0.30 "#ffff00"}
		{0.45 "#00ff00"}
		{0.65 "#0000ff"}
		{0.90 "#7f00ff"}
		{1.00 "#7f007f"}
	    }
	}
	default {
	    return -code error "the named gradient '$name' is unknown"
	}
    }
}

