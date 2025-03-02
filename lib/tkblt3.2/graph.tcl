package provide Tkblt 3.0

namespace eval ::blt::legend {
    variable _private 
    array set _private {
	afterId ""
	scroll 0
	space off
	drag 0
	x 0
	y 0
    }
}

namespace eval ::blt::ZoomStack {
    variable _private
    array set _private {
	afterId ""
	scroll 0
	space off
	drag 0
	x 0
	y 0
    }
}

proc blt::legend::SetSelectionAnchor { w tagOrId } {
    set elem [$w legend get $tagOrId]
    # If the anchor hasn't changed, don't do anything
    if { $elem != [$w legend get anchor] } {
	$w legend selection clearall
	$w legend focus $elem
	$w legend selection set $elem
	$w legend selection anchor $elem
    }
}

# ----------------------------------------------------------------------
#
# MoveFocus --
#
#	Invoked by KeyPress bindings.  Moves the active selection to
#	the entry <where>, which is an index such as "up", "down",
#	"prevsibling", "nextsibling", etc.
#
# ----------------------------------------------------------------------
proc blt::legend::MoveFocus { w elem } {
    catch {$w legend focus $elem} result
    puts stderr "result=$result elem=$elem"
    if { [$w legend cget -selectmode] == "single" } {
        $w legend selection clearall
        $w legend selection set focus
	$w legend selection anchor focus
    }
}


proc Blt_ActiveLegend { g } {
    $g legend bind all <Enter> [list blt::ActivateLegend $g ]
    $g legend bind all <Leave> [list blt::DeactivateLegend $g]
    $g legend bind all <ButtonPress-1> [list blt::HighlightLegend $g]
}

proc Blt_Crosshairs { g } {
    blt::Crosshairs $g 
}

proc Blt_ResetCrosshairs { g state } {
    blt::Crosshairs $g "Any-Motion" $state
}

proc Blt_ZoomStack { g args } {
    array set params {
	-mode click
	-button "ButtonPress-3"
    }
    array set params $args
    if { $params(-mode) == "click" } {
	blt::ZoomStack::ClickClick $g $params(-button)
    } else {
	blt::ZoomStack::ClickRelease $g $params(-button)
    }	
}

proc Blt_ClosestPoint { g } {
    blt::ClosestPoint $g
}

#
# The following procedures that reside in the "blt" namespace are
# supposed to be private.
#

proc blt::ActivateLegend { g } {
    set elem [$g legend get current]
    $g legend activate $elem
}
proc blt::DeactivateLegend { g } {
    set elem [$g legend get current]
    $g legend deactivate $elem
}

proc blt::HighlightLegend { g } {
    set elem [$g legend get current]
    if { $elem != ""  } {
      set relief [$g element cget $elem -legendrelief]
      if { $relief == "flat" } {
	$g element configure $elem -legendrelief raised
	$g element activate $elem
      } else {
	$g element configure $elem -legendrelief flat
	$g element deactivate $elem
      }
   }
}

proc blt::Crosshairs { g {event "Any-Motion"} {state "on"}} {
    $g crosshairs $state
    bind crosshairs-$g <$event>   {
	%W crosshairs configure -position @%x,%y 
    }
    bind crosshairs-$g <Leave>   {
	%W crosshairs off
    }
    bind crosshairs-$g <Enter>   {
	%W crosshairs on
    }
    $g crosshairs configure -color red
    if { $state == "on" } {
	blt::AddBindTag $g crosshairs-$g
    } elseif { $state == "off" } {
	blt::RemoveBindTag $g crosshairs-$g
    }
}

proc blt::ClosestPoint { g {event "Control-ButtonPress-2"} } {
    bind closest-point-$g <$event>  {
	blt::FindElement %W %x %y
    }
    blt::AddBindTag $g closest-point-$g
}

proc blt::AddBindTag { widget tag } {
    set oldTagList [bindtags $widget]
    if { [lsearch $oldTagList $tag] < 0 } {
	bindtags $widget [linsert $oldTagList 0  $tag]
    }
}

proc blt::RemoveBindTag { widget tag } {
    set oldTagList [bindtags $widget]
    set index [lsearch $oldTagList $tag]
    if { $index >= 0 } {
	bindtags $widget [lreplace $oldTagList $index $index]
    }
}

proc blt::FindElement { g x y } {
    array set info [$g element closest $x $y -interpolate yes]
    if { ![info exists info(name)] } {
	beep
	return
    }
    # --------------------------------------------------------------
    # find(name)		- element Id
    # find(index)		- index of closest point
    # find(x) find(y)		- coordinates of closest point
    #				  or closest point on line segment.
    # find(dist)		- distance from sample coordinate
    # --------------------------------------------------------------
    set markerName "bltClosest_$info(name)"
    catch { $g marker delete $markerName }
    $g marker create text $markerName \
	-coords "$info(x) $info(y)" \
	-text "$info(name): $info(dist)\nindex $info(index)" \
	-anchor center -justify left \
	-yoffset 0 -bg {} 

    set coords [$g invtransform $x $y]
    set nx [lindex $coords 0]
    set ny [lindex $coords 1]

    $g marker create line line.$markerName -coords "$nx $ny $info(x) $info(y)"

    blt::FlashPoint $g $info(name) $info(index) 10
    blt::FlashPoint $g $info(name) [expr $info(index) + 1] 10
}

proc blt::FlashPoint { g name index count } {
    if { $count & 1 } {
        $g element deactivate $name 
    } else {
        $g element activate $name $index
    }
    incr count -1
    if { $count > 0 } {
	after 200 blt::FlashPoint $g $name $index $count
	update
    } else {
	catch {eval $g marker delete [$g marker names "bltClosest_*"]}
    }
}


proc blt::ZoomStack::Init { g } {
    variable _private
    set _private($g,interval) 100
    set _private($g,afterId) 0
    set _private($g,A,x) {}
    set _private($g,A,y) {}
    set _private($g,B,x) {}
    set _private($g,B,y) {}
    set _private($g,stack) {}
    set _private($g,corner) A
}

proc blt::ZoomStack::ClickClick { g reset } {
    variable _private
    
    Init $g
    
    bind zoom-$g <Enter> "focus %W"
    bind zoom-$g <KeyPress-Escape> { blt::ZoomStack::Reset %W }
    bind zoom-$g <ButtonPress-1> { blt::ZoomStack::SetPoint %W %x %y }
    bind zoom-$g <${reset}> { 
	if { [%W inside %x %y] } { 
	    blt::ZoomStack::Reset %W 
	}
    }
    blt::AddBindTag $g zoom-$g
}

proc blt::ZoomStack::ClickRelease { g reset } {
    variable _private
    
    Init $g
    bind zoom-$g <Enter> "focus %W"
    bind zoom-$g <KeyPress-Escape> {blt::ZoomStack::Reset %W}
    bind zoom-$g <ButtonPress-1> {blt::ZoomStack::DragStart %W %x %y}
    bind zoom-$g <B1-Motion> {blt::ZoomStack::DragMotion %W %x %y}
    bind zoom-$g <ButtonRelease-1> {blt::ZoomStack::DragFinish %W %x %y}
    bind zoom-$g <${reset}> { 
	if { [%W inside %x %y] } { 
	    blt::ZoomStack::Reset %W 
	}
    }
    blt::AddBindTag $g zoom-$g
}

proc blt::ZoomStack::GetCoords { g x y index } {
    variable _private
    if { [$g cget -invertxy] } {
	set _private($g,$index,x) $y
	set _private($g,$index,y) $x
    } else {
	set _private($g,$index,x) $x
	set _private($g,$index,y) $y
    }
}

proc blt::ZoomStack::MarkPoint { g index } {
    variable _private

    if { [llength [$g xaxis use]] > 0 } {
	set x [$g xaxis invtransform $_private($g,$index,x)]
    } else if { [llength [$g x2axis use]] > 0 } {
	set x [$g x2axis invtransform $_private($g,$index,x)]
    }
    if { [llength [$g yaxis use]] > 0 } {
	set y [$g yaxis invtransform $_private($g,$index,y)]
    } else if { [llength [$g y2axis use]] > 0 } {
	set y [$g y2axis invtransform $_private($g,$index,y)]
    }
    set marker "zoomText_$index"
    set text [format "x=%.4g\ny=%.4g" $x $y] 

    if [$g marker exists $marker] {
     	$g marker configure $marker -coords "$x $y" -text $text 
    } else {
    	$g marker create text $marker \
	    -coords "$x $y" \
	    -text $text -anchor center -bg {} -justify left
    }
}

proc blt::ZoomStack::DestroyTitle { g } {
    variable _private

    if { $_private($g,corner) == "A" } {
	catch { $g marker delete "zoomTitle" }
    }
}

proc blt::ZoomStack::Pop { g } {
    variable _private

    set zoomStack $_private($g,stack)
    if { [llength $zoomStack] > 0 } {
	set cmd [lindex $zoomStack 0]
	set _private($g,stack) [lrange $zoomStack 1 end]
	eval $cmd
	TitleLast $g
	update
	after 2000 [list blt::ZoomStack::DestroyTitle $g]
    } else {
	catch { $g marker delete "zoomTitle" }
    }
}

# Push the old axis limits on the stack and set the new ones

proc blt::ZoomStack::Push { g } {
    variable _private

    catch {eval $g marker delete [$g marker names "zoom*"]}
    if { [info exists _private($g,afterId)] } {
	after cancel $_private($g,afterId)
    }
    set x1 $_private($g,A,x)
    set y1 $_private($g,A,y)
    set x2 $_private($g,B,x)
    set y2 $_private($g,B,y)

    if { ($x1 == $x2) || ($y1 == $y2) } { 
	# No delta, revert to start
	return
    }
    set cmd {}
    foreach axis [$g axis names] {
	if { [$g axis cget $axis -hide] } {
	    continue
	}
	set min [$g axis cget $axis -min] 
	set max [$g axis cget $axis -max]
	set logscale  [$g axis cget $axis -logscale]
	# Save the current scale (log or linear) so that we can restore it.
	# This is for the case where the user changes to logscale while
	# zooming.  A previously pushed axis limit could be negative.  It
	# seems better for popping the zoom stack to restore a previous view
	# (not convert the ranges).
	set c [list $g axis configure $axis]
	lappend c -min $min -max $max -logscale $logscale
	append cmd "$c\n"
    }

    # This effectively pushes the command to reset the graph to the current
    # zoom level onto the stack.  This is useful if the new axis ranges are
    # bad and we need to reset the zoom stack.
    set _private($g,stack) [linsert $_private($g,stack) 0 $cmd]
    foreach axis [$g axis names] {
	if { [$g axis cget $axis -hide] } {
	    continue;			# Don't set zoom on axes not displayed.
	}
	set type [$g axis type $axis]
	if { $type  == "x" } {
	    set min [$g axis invtransform $axis $x1]
	    set max [$g axis invtransform $axis $x2]
	} elseif { $type == "y" } {
	    set min [$g axis invtransform $axis $y1]
	    set max [$g axis invtransform $axis $y2]
	} else {
	    continue;			# Axis is not bound to any margin.
	}
	if { ![SetAxisRanges $g $axis $min $max] } {
	    Pop $g
	    bell
	    return
	}
    }
    update;				# This "update" redraws the graph
}

proc blt::ZoomStack::SetAxisRanges { g axis min max } {
    if { $min > $max } { 
	set tmp $max; set max $min; set min $tmp
    }
    if { [catch { $g axis configure $axis -min $min -max $max }] != 0 } {
	return 0
    }
    return 1
}

#
# This routine terminates either an existing zoom, or pops back to
# the previous zoom level (if no zoom is in progress).
#
proc blt::ZoomStack::Reset { g } {
    variable _private

    if { ![info exists _private($g,corner)] } {
	Init $g 
    }
    catch {eval $g marker delete [$g marker names "zoom*"]}

    if { $_private($g,corner) == "A" } {
	# Reset the whole axis
	Pop $g
    } else {
	set _private($g,corner) A
	blt::RemoveBindTag $g select-region-$g
    }
}

proc blt::ZoomStack::TitleNext { g } {
    variable _private

    set level [expr [llength $_private($g,stack)] + 1]
    if { [$g cget -invertxy] } {
	set coords "Inf -Inf"
    } else {
	set coords "-Inf Inf"
    }
    set marker "zoomTitle"
    if {![$g marker exists $marker]} {
	$g marker create text $marker -bindtags "" -anchor nw
    }
    $g marker configure $marker -text "Zoom #$level" -coords $coords
}

proc blt::ZoomStack::TitleLast { g } {
    variable _private

    set level [llength $_private($g,stack)]
    if { [$g cget -invertxy] } {
	set coords "Inf -Inf"
    } else {
	set coords "-Inf Inf"
    }

    set marker "zoomTitle"
    if { $level > 0 } {
	if {![$g marker exists $marker]} {
	    $g marker create text "zoomTitle" -anchor nw
	}
     	$g marker configure $marker -text "Zoom #$level" -coords $coords
    }
}


proc blt::ZoomStack::SetPoint { g x y } {
    variable _private
    if { ![info exists _private($g,corner)] } {
	Init $g
    }
    GetCoords $g $x $y $_private($g,corner)
    bind select-region-$g <Motion> { 
	blt::ZoomStack::GetCoords %W %x %y B
	#blt::ZoomStack::MarkPoint $g B
	blt::ZoomStack::Box %W
    }
    if { $_private($g,corner) == "A" } {
	if { ![$g inside $x $y] } {
	    return
	}
	# First corner selected, start watching motion events

	#MarkPoint $g A
	TitleNext $g 

	blt::AddBindTag $g select-region-$g
	set _private($g,corner) B
    } else {
	# Delete the modal binding
	blt::RemoveBindTag $g select-region-$g
	Push $g 
	set _private($g,corner) A
    }
}

proc blt::ZoomStack::DragStart { g x y } {
    variable _private
    if { ![info exists _private($g,corner)] } {
	Init $g
    }
    GetCoords $g $x $y A
    if { ![$g inside $x $y] } {
	return
    }
    set _private(drag) 1
    TitleNext $g 
}

proc blt::ZoomStack::DragMotion { g x y } {
    variable _private 

    if { $_private(drag) } {
	GetCoords $g $x $y B
	set dx [expr abs($_private($g,B,x) - $_private($g,A,x))]
	set dy [expr abs($_private($g,B,y) - $_private($g,A,y))]
	Box $g
	if { $dy > 10 && $dx > 10 } {
	    return 1
	}	
    }
    return 0
}

proc blt::ZoomStack::DragFinish { g x y } {
    variable _private 
    if { [DragMotion $g $x $y] } {
	Push $g 
    } else {
	catch {eval $g marker delete [$g marker names "zoom*"]}
	if { [info exists _private($g,afterId)] } {
	    after cancel $_private($g,afterId)
	}
    }
    set _private(drag) 0
}


proc blt::ZoomStack::MarchingAnts { g offset } {
    variable _private

    incr offset
    # wrap the counter after 2^16
    set offset [expr $offset & 0xFFFF]
    if { [$g marker exists zoomOutline] } {
	$g marker configure zoomOutline -dashoffset $offset 
	set interval $_private($g,interval)
	set id [after $interval [list blt::ZoomStack::MarchingAnts $g $offset]]
	set _private($g,afterId) $id
    }
}

proc blt::ZoomStack::Box { g } {
    variable _private

    if { $_private($g,A,x) > $_private($g,B,x) } { 
	set x1 [$g xaxis invtransform $_private($g,B,x)]
	set y1 [$g yaxis invtransform $_private($g,B,y)]
	set x2 [$g xaxis invtransform $_private($g,A,x)]
	set y2 [$g yaxis invtransform $_private($g,A,y)]
    } else {
	set x1 [$g xaxis invtransform $_private($g,A,x)]
	set y1 [$g yaxis invtransform $_private($g,A,y)]
	set x2 [$g xaxis invtransform $_private($g,B,x)]
	set y2 [$g yaxis invtransform $_private($g,B,y)]
    }
    set coords "$x1 $y1 $x2 $y1 $x2 $y2 $x1 $y2 $x1 $y1"
    if { [$g marker exists "zoomOutline"] } {
	$g marker configure "zoomOutline" -coords $coords 
    } else {
	set X [lindex [$g xaxis use] 0]
	set Y [lindex [$g yaxis use] 0]
	$g marker create line "zoomOutline" \
	    -coords $coords -mapx $X -mapy $Y \
	    -dashes 4 -linewidth 1
	set interval $_private($g,interval)
	set id [after $interval [list blt::ZoomStack::MarchingAnts $g 0]]
	set _private($g,afterId) $id
    }
}

