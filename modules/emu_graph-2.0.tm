 ##+##########################################################################
 #
 # ribbon.tcl -- Draws a line graph with a 3-D ribbon affect
 # by Keith Vetter, Sept 2006
 #
 namespace eval ::Ribbon {}
 #
 # ::Ribbon::Draw -- Creates 3d affect for a line graph
 #
 # Works in screen coordinates and shifts each point back dx,dy
 #
 # Tough issue:
 #  Bad news when the graph more steeply than our perspective line then
 #  two offset segments will need to get clipped to the graph.
 #  This can happen both to the left and to the right
 #    1. the upward segment shouldn't be drawn (it's "inside")
 #    2. incoming segment will have one corner drawn too far
 #
 # Three pass algorithm:
 #    1. each point w/ 2 sentinels into P; each 3d-offset point into Q
 #    3. detect offset points inside and move them
 #    4. draw all non-inside segments
 #
 proc ::Ribbon::Draw {w pxy dir length} {
    set dx 4
    set dy -10

    # Get vector to add to each point for 3d offset
    set dx [expr {$dx * ($dir eq "l" ? -1 : $dir eq "r" ? 1 : 0)}]
    set offsetXY [list $dx $dy]
    set scaler [expr {$length/hypot($dx,$dy)}]

    set CNT [expr {[llength $pxy] / 2}]
    unset -nocomplain P
    unset -nocomplain Q

    # 1st pass -- each point into P w/ 2 sentinels; each 3d-offset into Q
    for {set i -1} {$i <= $CNT} {incr i} {
        set P($i) [lrange $pxy [expr {2*$i}] [expr {2*$i + 1}]]
        if {$i == -1}   { set P(-1)   [::Ribbon::VAdd [lrange $pxy 0 1] {0 -100}] }
        if {$i == $CNT} { set P($CNT) [::Ribbon::VAdd [lrange $pxy end-1 end] {0 100}] }
        set Q($i) [::Ribbon::VAdd2 $P($i) $offsetXY $scaler]
    }

    # 2nd pass fixes up any offset point which are "inside"
    for {set i0 -1; set i 0; set i1 1} {$i < $CNT} {incr i0; incr i; incr i1} {
        set alpha [::Ribbon::GetAngle $P($i) $Q($i)]  ;# Perspective line angle
        set beta  [::Ribbon::GetAngle $P($i) $P($i1)] ;# Segment right angle
        set gamma [::Ribbon::GetAngle $P($i) $P($i0)] ;# Segment left angle
        set P($i,beta) $beta                    ;# Keep for color info

        set Q($i,badR) [expr {$alpha >= $beta}] ;# Clockwise from beta
        set Q($i,badL) [expr {$alpha <= $gamma}];# Anti-clockwise from gamma

        if {$Q($i,badR)} {                      ;# Clip left seg to right line
            catch {set Q($i) [::Ribbon::Intersect $Q($i) $Q($i0) $P($i) $P($i1)]}
        }
        if {$Q($i,badL)} {                      ;# Clip right seg to left line
            catch {set Q($i) [::Ribbon::Intersect $Q($i) $Q($i1) $P($i) $P($i0)]}
        }
    }

    # Now draw each segment--unless a corner is bad
    for {set i 0; set i1 1} {$i < $CNT-1} {incr i; incr i1} {
        if {$Q($i,badR) || $Q($i1,badL)} continue
        set xy [concat $P($i) $Q($i) $Q($i1) $P($i1)]
        set clr gray[expr {99-round(abs($P($i,beta) - 360))}]
	#modify original to give all segments a tag for deletion
        $w create poly $xy -fill $clr -outline black -tags 3dribbon
	$w lower 3dribbon
    }
 }

 ##+##########################################################################
 #
 # ::Ribbon::GetAngle -- returns clockwise angle a line makes with the x axis
 # BUT in 90-450 range
 #
 proc ::Ribbon::GetAngle {p0 p1} {
    foreach {x0 y0} $p0 {x1 y1} $p1 break
    set dx [expr {$x1 - $x0}]
    set dy [expr {$y1 - $y0}]
    set a [expr {atan2($dy,$dx)*180/acos(-1)}]
    while {$a <= 90} { set a [expr {$a + 360}] }
    return $a
 }

 proc ::Ribbon::VAdd {v1 v2 {scaler 1}} {
    foreach {x1 y1} $v1 {x2 y2} $v2 break
    return [list [expr {$x1 + $scaler*$x2}] [expr {$y1 + $scaler*$y2}]]
 }

 proc ::Ribbon::VAdd2 {v1 v2 {scaler 1}} {
    foreach {x1 y1} $v1 {x2 y2} $v2 break
    set origin [list -400 -100]
    set ox1 -400
    set oy1 -100
    set vx1 [expr {$x1 - $ox1}]
    set vy1 [expr {$y1 - $oy1}]
    return [list [expr {$x1 - $vx1 * 0.03}] [expr {$y1 - $vy1 * 0.05}]]
    # return [list [expr {$x1 * 0.9}] [expr {$y1 * 0.9}]]
 }

 proc ::Ribbon::VSub {v1 v2} { return [::Ribbon::VAdd $v1 $v2 -1] }
 ##+##########################################################################
 #
 # ::Ribbon::Intersect -- find two line intersection given two points on each line
 #
 proc ::Ribbon::Intersect {p1 p2 p3 p4} {
    return [::Ribbon::IntersectV $p1 [VSub $p2 $p1] $p3 [VSub $p4 $p3]]
 }
 ##+##########################################################################
 #
 # ::Ribbon::IntersectV -- find where 2 point/vector intersect
 #
 # p1+K(v1) = p3+J(v3)
 # convert into and solve matrix equation (a b / c d) ( K / J) = ( e / f )
 #
 proc ::Ribbon::IntersectV {p1 v1 p3 v3} {
    foreach {x1 y1} $p1 {vx1 vy1} $v1 {x3 y3} $p3 {vx3 vy3} $v3 break

    set a $vx1
    set b [expr {-1 * $vx3}]
    set c $vy1
    set d [expr {-1 * $vy3}]
    set e [expr {$x3 - $x1}]
    set f [expr {$y3 - $y1}]

    set det [expr {double($a*$d - $b*$c)}]
    if {$det == 0} {error "Determinant is 0"}

    set k [expr {($d*$e - $b*$f) / $det}]
    #set j [expr {($a*$f - $c*$e) / $det}]
    return [::Ribbon::VAdd $p1 $v1 $k]
 }
##-----------------------------------------------------------------------
##           graph.tcl -- the emu_graph widget for data plotting
##
##		       (c) Copyright 1996, 1997
##	     Speech Hearing and Language Research Centre,
##	       Macquarie University, Sydney, Australia.
##
##
##                       All rights reserved.
##
## Redistribution and use in source and binary forms, with or without
## modification, are permitted provided that the following conditions are
## met:
## 	1. Redistributions of source code must retain the above
## 	copyright notice, this list of conditions and the following
## 	disclaimer.
##
## 	2. Redistributions in binary form must reproduce the above
## 	copyright notice, this list of conditions and the following
## 	disclaimer in the documentation and/or other materials provided
## 	with the distribution.
##
## 	3. Neither the name of Macquarie University nor the names of its
## 	contributors may be used to endorse or promote products derived
## 	from this software without specific prior written permission.
##
## THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
## IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
## TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
## PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR
## CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
## EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
## PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
## PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
## LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
## NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
## SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
##-----------------------------------------------------------------------
## $Id: graph.tcl,v 1.3 1998/02/20 03:58:06 steve Exp $ 

# This file implements package emu_graph, which  draws a graph on 
#  a tk canvas
#
package provide emu_graph 2.0

namespace eval emu_graph {

## we only export emu_graph, everything else is accessed through the
## widget command
namespace export -clear emu_graph

## legal options 
set emu_graph(options) { 
    width height xref yref ticklen axistextoffset
    nticks_x nticks_y font autorange canvas xmin xmax ymin ymax
}

## default values for some options
set emu_graph(default) { \
    -width           300\
    -height          200\
    -xref            50\
    -yref            30\
    -ticklen         5\
    -axistextoffset  5\
    -nticks_x         5\
    -nticks_y         5\
    -font            TkDefaultFont \
    -autorange       0\
}

set emu_graph(dataoptions) {
    points lines colour coords time mask maskthresh\
	trackdata trackcolumn redraw labels
}

set emu_graph(datadefault) {
    -labels          { } \
    -points          0 \
    -lines           1\
    -colour          white \
    -trackcolumn     0 \
    -redraw          1
}

# here we will record all the graph names as they are made
set emu_graph(graphs) {}

## create a new emu_graph...
proc emu_graph args {
    variable emu_graph

    set graph [lindex $args 0]
    lappend emu_graph(graphs) $graph
    
    ## remove any existing config info under this name
    foreach key [array names emu_graph] {
        if [string match "$graph,*" $key] {
            unset emu_graph($key)
        }
    }

    ## prepend the default options to args, they can then be overridden if they
    ## appear later in the args
    set args [concat $graph 0 $emu_graph(default) [lrange $args 1 end]] 

    ## now parse the options
    set restargs [eval "internal_configure $args"]
    
    # shouldn't be any more args
    if { $restargs != {} } {
	error "Usage: emu_graph graph \[options\] ($restargs)"
    }
    set emu_graph($graph,datasets) {}
    set emu_graph($graph,gradsets) {}
    
    # define the widget command
    namespace eval :: \
	proc $graph args "\{namespace eval emu_graph \[concat emu_graph::invoke $graph  \$args\] \}"

}

proc invoke args {
    variable emu_graph;

    set graph [lindex $args 0]
    set method [lindex $args 1]

    if {[info procs $method] != {}} {
	eval [concat $method $graph [lrange $args 2 end]]
	} else { 
	    error "no method $method for emu_graph,\n options are [methods]"
        }
}


## find the names of all methods *, just giving the * bit
proc methods {} {
    return [info procs]
}


## implement the 'data' subcommand for graph objects
proc data args {

    variable emu_graph

    set graph [lindex $args 0]
    set tag [lindex $args 1]

    if {[llength $tag]>1 || [string match "-*" $tag]} {
	error "Usage: graph data tag \[options\]"
    }

    set args [concat $graph $tag $emu_graph(datadefault) [lrange $args 2 end]] 

    ## now parse the options
    set restargs [eval "internal_configure $args"]

    if { [llength $restargs] != 0 } {
	error "Usage: graph data tag \[options\]"
    }

    ## append tag only if not already exists, Mark Koennecke
    set mark_list $emu_graph($graph,datasets)
    if { [lsearch -exact $mark_list $tag] < 0 } {    
       set emu_graph($graph,datasets) [lappend emu_graph($graph,datasets) $tag]
    }
    set datalength 0 
    ## if we have data as coords then verify that each element is a pair 
    ## and remember the length for later
    if { [info exists emu_graph($graph,$tag,coords)] } {
	set ncoords [llength $emu_graph($graph,$tag,coords)]
	if { int($ncoords/2)*2 != $ncoords } {
	    set emu_graph($graph,$tag,coords) {}
	    error "bad data format in emu_graph $graph, data $tag\n -- length of coords must be even, it was $ncoords"
	}
	set datalength [expr {$ncoords/2}]
    }
    ## if we have data as trackdata, remember it's length
    if { [info exists emu_graph($graph,$tag,trackdata)] } {
	set datalength [$emu_graph($graph,$tag,trackdata) length]
    }
    if { [info exists emu_graph($graph,$tag,time)] } {
	set timelength [llength $emu_graph($graph,$tag,time)]
	set timelist [ list $emu_graph($graph,$tag,time) ]
	}
    # if there's a mask, chech that there's also a maskthresh and 
    # that the length of the mask is the same as the data
    if { $datalength != 0 && [info exists emu_graph($graph,$tag,mask)] } {
	if { ![info exists emu_graph($graph,$tag,maskthresh)] } {
	    error "No threshold supplied with masking vector in emu_graph, use -maskthresh N"
	}
	if { [llength $emu_graph($graph,$tag,mask)] != $datalength } {
	    error "Mask vector and coords have different lengths ([llength $emu_graph($graph,$tag,$mask)] and  $datalength)"
	}
    }
    if {$datalength != 0 && $emu_graph($graph,$tag,redraw)} {
	redraw $graph $timelist $timelength
    }
}

proc configure args {
    set newargs [concat [lindex $args 0] 0 [lrange $args 1 end]]
    eval "internal_configure $newargs"
}

proc internal_configure args {
    ## rest of args is a list of option value pairs, 
    ## set emu_graph($canvas,option) to value for each option, 
    ## if args remain after last option (ie
    ## something not beginning with a - or after a --, they are returned

    variable emu_graph
    
    set graph [lindex $args 0]
    set datatag [lindex $args 1]
    set args [lrange $args 2 end]
    
    if {![is_graph $graph]} {
        error "$graph is not an emu_graph"
    }

    # if we're setting options for a data set we modify $graph
    # to include the tag to make the array entry 
    # emu_graph($graph,$tag,$option)
    if { $datatag != 0 } {
	set graph "$graph,$datatag"    
	set validoptions $emu_graph(dataoptions)
    } else {
	set validoptions $emu_graph(options)
    }	

    
    set curropt ""
    for {set i 0} { $i<[llength $args] } { incr i 2 } {
        if { [lindex $args $i] == "--" } {
            # terminating switch, return rest of args
            return [lrange $args [expr {$i+1}] end]
        } elseif { [regexp -- "-(.*)" [lindex $args $i] ignore curropt] } {
            # have a switch, get value and set option
            # but check first that it's kosher
            if { [lsearch $validoptions $curropt] >= 0 } {
                if { $i+1<[llength $args] } {
                    set emu_graph($graph,$curropt) [lindex $args [expr {$i+1}]]
 
                }
            } else {
                error "Bad option -$curropt to emu_graph\n\tuse one of $validoptions"
            }
        } else {
            ## options have run out, return rest of args
            return [lrange $args $i end]
        }
    }
}

proc destroy {graph} {
    variable emu_graph
    $emu_graph($graph,canvas) delete withtag graph$graph
    set where [lsearch $emu_graph(graphs) $graph]
    lreplace $emu_graph(graphs) $where $where
}

proc redraw {graph timelist timelength} {
    variable emu_graph
    if {![is_graph $graph]} {
        error "$graph is not an emu_graph"
    }
    # draw it if we have a canvas
    if {[info exists emu_graph($graph,canvas)]} {
	$emu_graph($graph,canvas) delete withtag graph$graph
        axes $graph $timelist $timelength
        plot_data $graph
    } else {
        error "$graph isn't associated with a canvas, use the -canvas option"
    }
}


proc is_graph {graph} {
    variable emu_graph
    return [expr {[lsearch $emu_graph(graphs) $graph] >= 0}]
}

proc auto_range {graph} {

    variable emu_graph

    if {![is_graph $graph]} {
        error "$graph is not an emu_graph"
    }

    ## we only autorange if the option is on or if there is no range set
    if { $emu_graph($graph,autorange) ||
         !([info exists emu_graph($graph,xmin)] &&
           [info exists emu_graph($graph,xmax)] &&
           [info exists emu_graph($graph,ymin)] &&
           [info exists emu_graph($graph,ymax)]) } {


        set xyrange {{1e19 -1e19} {1e19 -1e19}}
        ## look at each dataset, find max/min for all
        foreach tag $emu_graph($graph,datasets) {

	    if { [info exists emu_graph($graph,$tag,mask)] } {
		set mask $emu_graph($graph,$tag,mask)
		set maskthresh $emu_graph($graph,$tag,maskthresh)
	    } else {
		set mask 0
		set maskthresh 0
	    }

	    if { [info exists emu_graph($graph,$tag,trackdata)] } {
		## get ranges from the data
		set yrange [$emu_graph($graph,$tag,trackdata) \
				range $emu_graph($graph,$tag,trackcolumn)]
		## xrange is start and end times
		set xrange [list [$emu_graph($graph,$tag,trackdata) start]\
				[$emu_graph($graph,$tag,trackdata) end]]
		set xyrange [list $xrange $yrange]
	    } elseif { [info exists emu_graph($graph,$tag,coords)] } {
		set xyrange [maxrange $xyrange \
				 [range\
				      $emu_graph($graph,$tag,coords)\
				      $mask $maskthresh]]
	    		} 
        }


	set xrange [lindex $xyrange 0]
	set yrange [lindex $xyrange 1]
	
        set xextra 0
        set yextra 0
	
        set emu_graph($graph,xmin) [expr {[lindex $xrange 0]-$xextra}]
        set emu_graph($graph,xmax) [expr {[lindex $xrange 1]+$xextra}]
        set emu_graph($graph,ymin) [expr {[lindex $yrange 0]-$yextra}]
        set emu_graph($graph,ymax) [expr {[lindex $yrange 1]+$yextra}]
    }
}

proc generate_colors {} {

    set values {"00" "FF" "00"}
    # set values {"EE" "88" "11"}
    foreach r $values {
	foreach g $values {
	    foreach b $values {
		lappend colors "\#$r$g$b"
	    }
	}
    }
    return $colors    
}
 
## set up emu_graph($graph,$dataset,color,$label) array
proc assign_colors {graph dataset} {
    variable emu_graph

    set colors [generate_colors]

    if {[llength $emu_graph($graph,$dataset,labels)] > 0} {
	set labels [lsort $emu_graph($graph,$dataset,labels)]
	set emu_graph($graph,$dataset,uniqlabs) {}
	set i 0
	foreach f $labels {
	    if {[lsearch -exact $f $emu_graph($graph,$dataset,uniqlabs)] == -1} {
		lappend emu_graph($graph,$dataset,uniqlabs) $f
		set emu_graph($graph,$dataset,colour,$f) [lindex $colors $i]
		incr i
		if {$i>[llength $colors]} {
		    set i 0
		}
	    }
	}
    }
}
    proc rgb_to_hex {rgb} {
        lassign $rgb r g b
        set r [format %02x [expr {$r/256}]]
        set g [format %02x [expr {$g/256}]]
        set b [format %02x [expr {$b/256}]]
        return #$r$g$b
    }

    proc get_colour {rgb1 rgb2 length index} {
        if { $index < 0  ||  $index >= $length } {
            error "index $index is out of bounds for length $length"
        }
        lassign $rgb1 r1 g1 b1
        lassign $rgb2 r2 g2 b2
        set r_ratio [expr { 1.00*($r2-$r1+1)/$length }]
        set g_ratio [expr { 1.00*($g2-$g1+1)/$length }]
        set b_ratio [expr { 1.00*($b2-$b1+1)/$length }]
        set r [expr { int($r_ratio*$index+$r1) }]
        set g [expr { int($g_ratio*$index+$g1) }]
        set b [expr { int($b_ratio*$index+$b1) }]
        if { $index == [expr {$length-1}] } {
            lassign $rgb2 r g b
        }
        return [rgb_to_hex [list $r $g $b]]
    }

proc plot_data {graph} {

    variable emu_graph

    if {![is_graph $graph]} { 
        error "$graph is not an emu_graph"
    }
    set x_min $emu_graph($graph,xmin)
    set x_max $emu_graph($graph,xmax)
    set y_min $emu_graph($graph,ymin)  
    set x_min_c [x2canvas $graph $x_min]
    set x_max_c [x2canvas $graph $x_max]
    set y_min_c [y2canvas $graph $y_min]

    set canvas $emu_graph($graph,canvas)
    foreach tag $emu_graph($graph,gradsets) {
        $canvas delete -withtag $tag 
    }
    set emu_graph($graph,gradsets) {}

    foreach tag $emu_graph($graph,datasets) {
        # plot the points, first delete any old ones
        $canvas delete -withtag $tag 
	$canvas delete -withtag 3dribbon

        set tags [list graph$graph data$graph $tag]

	if { [info exists emu_graph($graph,$tag,trackdata)] } {
	    ## get coords data from an emu trackdata object
	    set coords \
		[$emu_graph($graph,$tag,trackdata) coords\
		     $emu_graph($graph,$tag,trackcolumn)\
		     $emu_graph($graph,xmin) $emu_graph($graph,xmax)\
		     $emu_graph($graph,xfactor) $emu_graph($graph,xref)\
		     $emu_graph($graph,ymin) $emu_graph($graph,ymax)\
		     $emu_graph($graph,yfactor) $emu_graph($graph,yref)]
	} elseif { [info exists emu_graph($graph,$tag,coords)] } {
	    ## coords have been supplied
	    set coords \
		[scale_points $graph $emu_graph($graph,$tag,coords)]
	} else {
	    set coords {}
	}
	
	# we may have a masking vector
	if { [info exists emu_graph($graph,$tag,mask)] } {
	    set mask $emu_graph($graph,$tag,mask)
	    set maskthresh $emu_graph($graph,$tag,maskthresh)
	} else {
	    set mask 0
	}
	
	## we may have labels, if so set colours but only when 
	## plotting only points
	if { [llength $emu_graph($graph,$tag,labels)] > 0 } {
	    assign_colors $graph $tag
	    set labelcolors 1
	} else {
	    set labelcolors 0
	}

	if { $emu_graph($graph,$tag,lines) } {
	set colour1 $emu_graph($graph,$tag,colour)
	#Fix colour 2 to always grade to white
	set colour2 white
        if { [catch {winfo rgb . $colour1} rgb1] } {
            error "invalid color: $colour1"
        }
        if { [catch {winfo rgb . $colour2} rgb2] } {
            error "invalid color: $colour2"
        }
	    ## create the line as a single line item
	    ## add start and end points

	set ribcoords $coords
	set coords [concat $x_min_c $y_min_c $coords $x_max_c $y_min_c ]
	    #grab last 6 points for gradient poly
	set lastsixcoords [ lrange $coords end-5 end ]
            #complete grad coordinates by adding pair at bottom of line in line with last point
        set gradcoords [ concat [ lindex $lastsixcoords 0 ] [ lindex $lastsixcoords end ] $lastsixcoords ]
            #delete last 6 points
        set coordscopy [ lreplace $coords end-5 end ]
            #complete coords by adding same pair
        lappend coordscopy [ expr [ lindex $lastsixcoords 0 ] + 2 ] [ lindex $lastsixcoords 1 ] [ expr [ lindex $lastsixcoords 0 ] + 2 ] [ lindex $lastsixcoords end ] 
	set x1 [ lindex $gradcoords 0 ]
	set x2 [ lindex $gradcoords end-1 ]
	set z1 [ lindex $gradcoords 3 ]
	set z2 [ lindex $gradcoords 4 ]
	set z3 [ lindex $gradcoords 5 ]
	set width [expr {$x2-$x1}]
	eval "$canvas create poly $coordscopy -fill $colour1 -tag {$tag}"
    	::Ribbon::Draw $canvas $ribcoords l 18
	$canvas lower $tag
	#create gradient poly as a number of polys from colour to white
	for {set x 1} {$x < $width} {incr x} {
	set gradcolour [ get_colour $rgb1 $rgb2 $width $x ]
	eval "$canvas create poly [expr $x1+$x] $z1 $z2 $z3 [expr $x1+$x+1] [ lindex $gradcoords end ] -fill $gradcolour -tag {$tag-g-$x}" 
        lappend emu_graph($graph,gradsets) $tag-g-$x
	}
	}

        for {set i 0} {$i < [llength $coords]-1} {incr i 2} {
	    ## we'll draw the point if were either not masking or if
	    ## the mask value is over the threshold
	    if { $mask == 0 || \
		     [lindex $mask [expr {$i/2}]] >= $maskthresh } {
		set point [lrange $coords $i [expr {$i+1}]]
		if { [point_in_bounds $graph $point] } {
		    
		    if { $labelcolors } {
			## find the colour for this point via its label
			set ll [lindex $emu_graph($graph,$tag,labels) \
				    [expr {$i/2}]]
			set color $emu_graph($graph,$tag,colour,$ll)
		    } else {
			set ll {}
			set color $emu_graph($graph,$tag,colour)
		    }

		    if { $emu_graph($graph,$tag,points) } {

			set thesetags [linsert $tags end point \
					   "index[expr {$i/2}]" "label$ll"]

			set ox [lindex $point 0]
			set oy [lindex $point 1]
			$canvas create oval \
			    [expr {$ox-2}] [expr {$oy-2}]\
			    [expr {$ox+2}] [expr {$oy+2}]\
			    -fill $color \
			    -outline black\
			    -width 0 \
			    -tag $thesetags
		    }
		}
	    }
	}
    }
}
                   
#
# check whether point is in bounds, where point is already scaled to canvas coords
#
proc point_in_bounds {graph point} {
    variable emu_graph
    set x [lindex $point 0]
    set y [lindex $point 1]
 
    if { $x >= $emu_graph($graph,xref) && 
	 $x <= $emu_graph($graph,xref)+$emu_graph($graph,width)  &&
	 $y <= $emu_graph($graph,yref)+$emu_graph($graph,height) && 
	 $y >= $emu_graph($graph,yref) } {
	return 1 
    } else {
	return 0
    }
}


proc scale_factor {graph} {

    variable emu_graph

    if {![is_graph $graph]} {
        error "$graph is not an emu_graph"
    }

    ## calculate scale factors for x and y
    set width  $emu_graph($graph,width)
    set height $emu_graph($graph,height)
    set xdelta [expr {double($emu_graph($graph,xmax) - $emu_graph($graph,xmin))}]
    set ydelta [expr {double($emu_graph($graph,ymax) - $emu_graph($graph,ymin))}]
    if {$xdelta == 0} { set xdelta 0.001 }
    if {$ydelta == 0} { set ydelta 0.001 }

    set xfactor [expr {double($width)/$xdelta}]
    set yfactor [expr {double($height)/$ydelta}]

    set emu_graph($graph,xfactor) $xfactor
    set emu_graph($graph,yfactor) $yfactor

}

proc axes {graph timelist timelength} {
    # generate axes for a plot
    variable emu_graph

    if {![is_graph $graph]} {
        error "$graph is not an emu_graph"
    }

    ## make sure we have the current scale factors etc
    auto_range $graph
    scale_factor $graph

    set x_min $emu_graph($graph,xmin)
    set x_max $emu_graph($graph,xmax)
    set y_min $emu_graph($graph,ymin)  
    set y_max $emu_graph($graph,ymax)

    set y_min_c [y2canvas $graph $y_min]
    set y_max_c [y2canvas $graph $y_max]
    set x_min_c [x2canvas $graph $x_min]
    set x_max_c [x2canvas $graph $x_max]

    # parameters affecting axis drawing
    set ticklen        $emu_graph($graph,ticklen)
    set axistextoffset $emu_graph($graph,axistextoffset)
    set nticks_x       $emu_graph($graph,nticks_x)
    set nticks_y       $emu_graph($graph,nticks_y)
    set graphfont      $emu_graph($graph,font)

    set canvas         $emu_graph($graph,canvas)
	
    # clear up any existing axes
    $canvas delete -withtag axis

    $canvas create rect $x_min_c $y_min_c $x_max_c [ expr $y_max_c - 20 ]\
        -outline black -tag [list graph$graph axis]
                                          
    # y-pos of tick end points and of axis tick labels
    set ticky [expr {$y_min_c-$ticklen}]
    set texty [expr {$y_min_c+$axistextoffset}]
    # put ticks and numbers on the axis 
    # starting at next nice number above x_min
    set delta_x [nicenum [expr {double($x_max-$x_min)/$nticks_x}] 1]
    set nicex_min [nicenum $x_min 1]
#    for {set t $nicex_min} {$t <= $x_max} {set t [expr {$t+$delta_x}]} 
    for {set t 1 } {$t <= [ expr {$timelength / 2  - 1} ] } { incr t } {
	## it may be that $f is one tick below y_min, don't draw it if it is
	## this is because of a problem with rounding down in nicenum
	if {$t >= $x_min} {
	    #puts "t=$t, next t [expr {$t+$delta_x}]"
	    set x [x2canvas $graph $t]
	    $canvas create line $x $y_min_c $x $ticky \
		-fill black -tag [list graph$graph axis]
	    $canvas create line $x [expr $y_max_c-20] $x [expr {$y_max_c+$ticklen-20}]\
		-fill black -tag [list graph$graph axis]
if { ($t eq 1) || ($t eq 4) || ($t eq 7) || ($t eq 10) || ($t eq 13) || ($t eq 16) || ($t eq 19) } {
		set n [ expr {$t * 2 - 1} ]
		set tind [ lindex [ split $timelist ] $n ]
		regsub -all {\}} $tind tind
	    $canvas create text [x2canvas $graph $t] $texty \
		-fill black -text $tind -font "$graphfont 7" -tag [list graph$graph axis]\
		-anchor w
		}
	}
    }

    # now the y axis
    set tickx1   [expr {[x2canvas $graph $x_min]+$ticklen}]
    set tickx2   [expr {[x2canvas $graph $x_max]-$ticklen}]
    set textx    [expr {[x2canvas $graph $x_min]-$axistextoffset}]

    set nicey_min [nicenum $y_min 1]   
    set delta_y [nicenum [expr {double($y_max-$y_min)/$nticks_y}] 1]

    for { set f $nicey_min } { $f <= $y_max } { set f [expr {$f + $delta_y}] } {
	## it may be that $f is one tick below y_min, don't draw it if it is
	## this is because of a problem with rounding down in nicenum
	if {$f >= $y_min} {
	    set y [y2canvas $graph $f]
	    $canvas create line [x2canvas $graph $x_min]\
	$y $tickx1 $y -fill black -tag [list graph$graph axis]
	    $canvas create line [x2canvas $graph $x_max]\
	$y $tickx2 $y -fill black -tag [list graph$graph axis]
	    # and add the label
		set dispf [ expr {int($f)} ]
	    $canvas create text $textx $y -text $dispf -anchor e \
		-fill black -tag [list graph$graph axis] -font "$graphfont 7"
        }
    }
}

# scale_points with inlined scaling, Mark Koennecke
proc scale_points {graph coords} {
    variable emu_graph

    if {![is_graph $graph]} {
        error "$graph is not an emu_graph"
    }

    set result {}
    foreach {x y} $coords {
#	puts "x: $x, y: $y"
	lappend result [expr {int(($x - $emu_graph($graph,xmin)) \
                * $emu_graph($graph,xfactor) + $emu_graph($graph,xref))}]

	lappend result [expr {int(($emu_graph($graph,ymax) - $y) \
                * $emu_graph($graph,yfactor) + $emu_graph($graph,yref))}]
    }
    return $result
}

proc bbox {graph} {
    variable emu_graph
    return [$emu_graph($graph,canvas) bbox graph$graph]
}

proc cget {graph option} { 
    variable emu_graph
    # remove leading - if present
    if { [regexp -- "-(.*)" $option ignore optname] } {
	set option $optname
    }
    # now look for it in the options store
    if {[info exists emu_graph($graph,$option)] } {
	return $emu_graph($graph,$option)
    } else {
	error "emu_graph has no configuration option $option"
    }
}


proc y2canvas {graph y} {
    variable emu_graph

    if {![is_graph $graph]} {
        error "$graph is not an emu_graph"
    }

    return [expr {int(($emu_graph($graph,ymax) - $y) \
                * $emu_graph($graph,yfactor) + $emu_graph($graph,yref))}]
}

proc canvas2y {graph cy} {
    variable emu_graph

    if {![is_graph $graph]} {
        error "$graph is not an emu_graph"
    }

    return [expr {$emu_graph($graph,ymax) - \
		      ($cy - $emu_graph($graph,yref))/$emu_graph($graph,yfactor)}]
}

proc canvas2x {graph cx} {
    variable emu_graph

    if {![is_graph $graph]} {
        error "$graph is not an emu_graph"
    }

    return [expr {$emu_graph($graph,xmin) + \
		      double($cx - $emu_graph($graph,xref))/double($emu_graph($graph,xfactor))}]
}

proc x2canvas {graph x} {
    variable emu_graph

    if {![is_graph $graph]} {
        error "$graph is not an emu_graph"
    }
    return  [expr {int(($x - $emu_graph($graph,xmin)) \
                * $emu_graph($graph,xfactor) + $emu_graph($graph,xref))}]
}


## find the ranges of a list of coordinates {{x y} {x' y'} {x'' y''}...}
## returns two ranges {{xmin xmax} {ymin ymax}}
proc range {list {mask 0} {maskthresh 0}} {
    set xmax -10e64
    set xmin 10e64
    set ymax -10e64
    set ymin 10e64
    for {set i 0} {$i < [llength $list]-1} {incr i 2} {
	set x [lindex $list $i]
	set y [lindex $list [expr {$i+1}]]

	if { $mask == 0 || \
		 [lindex $mask [expr {$i/2}]] >= $maskthresh } {
	
	    if {$y > $ymax} {
		set ymax $y
	    }
		set ymin 0
	  }
	# don't worry about the mask for x -- we still want to line up with
	# other plots 
	if {$x>$xmax} {
	    set xmax $x
	}
	
	if {$x < $xmin} {
	    set xmin $x
	}
    }
    return [list [list $xmin $xmax] [list $ymin $ymax]] 
}


## find the maxima of the sets of ranges a and b which are both {{xmin xmax} {ymin ymax}}
proc maxrange {a b} {
    return [list [maxrange-aux [lindex $a 0] [lindex $b 0]]\
		[maxrange-aux [lindex $a 1] [lindex $b 1]]]
}


## find the maxima of the ranges a and b which are both {min max} pairs
proc maxrange-aux {a b} {
    # get the smallest minimum
    if {[lindex $a 0] < [lindex $b 0]} {
        set first [lindex $a 0]
    } else {
        set first [lindex $b 0]
    }
    # and the largest maximum
    if {[lindex $a 1] > [lindex $b 1]} {
        set second [lindex $a 1]
    } else {
        set second [lindex $b 1]
    }
    return [list $first $second]
}

             
## translated from C-code in Blt, who got it from:
##      Taken from Paul Heckbert's "Nice Numbers for Graph Labels" in
##      Graphics Gems (pp 61-63).  Finds a "nice" number approximately
##      equal to x.

proc nicenum {x floor} {

    if {$x == 0} { return 0 }
    
    set negative 0
    if {$x < 0} {
        set x [expr {-$x}]
        set negative 1
    }

    set exponX [expr {floor(log10($x))}]
    set fractX [expr {$x/pow(10,$exponX)}]; # between 1 and 10
    if {$floor} {
        if {$fractX < 1.5} {
            set nf 1.0
        } elseif {$fractX < 3.0} {
            set nf 2.0
        } elseif {$fractX < 7.0} {
            set nf 5.0
        } else {                
         set nf 10.0
        }
    } elseif {$fractX <= 1.0} {
        set nf 1.0
    } elseif {$fractX <= 2.0} {
        set nf 2.0
    } elseif {$fractX <= 5.0} {
        set nf 5.0
    } else {
        set nf 10.0
    }
    if { $negative } {
#	puts "nicenum $x -> [expr {-$nf * pow(10,$exponX)}]"
        return [expr {-$nf * pow(10,$exponX)}]
    } else {
#	puts "fractX: $fractX\nexponX: $exponX\nnf: $nf"
#	puts "nicenum $x -> [expr {$nf * pow(10,$exponX)}]"
	set value [expr {$nf * pow(10,$exponX)}]
	if {abs($value-$x) > 100} {
	    return $x
	} else {
	    return $value
	}
    }
}                

#
# put a vertical or horizontal mark on the graph 
#
proc vmark {graph x tag {color white}} {
    variable emu_graph
    if { $x >= $emu_graph($graph,xmin) && $x <= $emu_graph($graph,xmax) } {
	set tags [list graph$graph vmark $tag]
	# if there's already an item with this tag then delete it
	$emu_graph($graph,canvas) delete $tag
	set cx [x2canvas $graph $x]
	$emu_graph($graph,canvas) create line \
	    $cx [y2canvas $graph $emu_graph($graph,ymin)]\
	    $cx [y2canvas $graph $emu_graph($graph,ymax)]\
	    -fill $color -tags $tags
    }
}

proc hmark {graph y tag {color white}} {
    variable emu_graph
    if { $y >= $emu_graph($graph,ymin) && $y <= $emu_graph($graph,ymax) } {
	# if there's already an item with this tag then delete it
	$emu_graph($graph,canvas) delete $tag
	set tags [list graph$graph vmark $tag]
	set cy [y2canvas $graph $y]
	$emu_graph($graph,canvas) create line \
	    [x2canvas $graph $emu_graph($graph,xmin)] $cy\
	    [x2canvas $graph $emu_graph($graph,xmax)] $cy\
	    -fill $color -tags $tags
    }
}

proc clearmark {graph tag} {
    variable emu_graph
    $emu_graph($graph,canvas) delete $tag
}


proc movevmark {graph tag newx} {
    variable emu_graph
    set cx [x2canvas $graph $newx]
    $emu_graph($graph,canvas) coords $tag \
	    $cx [y2canvas $graph $emu_graph($graph,ymin)]\
	    $cx [y2canvas $graph $emu_graph($graph,ymax)]
}

proc movehmark {graph tag newy} {
    variable emu_graph
    set cy [y2canvas $graph $newy]
    $emu_graph($graph,canvas) coords $tag \
	    [x2canvas $graph $emu_graph($graph,xmin)] $cy\
	    [x2canvas $graph $emu_graph($graph,xmax)] $cy\
}


}

