#Tablelist package modified to operate as a module
#Copyright norice from original package
#Multi-column listbox and tree widget package Tablelist, version 5.18
#Copyright (c) 2000-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#
#This library is free software; you can use, modify, and redistribute it
#for any purpose, provided that existing copyright notices are retained
#in all copies and that this notice is included verbatim in any
#distributions.
#
#This software is distributed WITHOUT ANY WARRANTY; without even the
#implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#==============================================================================
# Main Tablelist and Tablelist_tile package module.
#
# Copyright (c) 2000-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

namespace eval ::tablelist {
    #
    # Gets the scaling percentage (100, 125, 150, or 200).
    #
    proc scalingPercentage {} {
	set factor [tk scaling]
	if {$factor < 1.50} {
	    return 100 
	} elseif {$factor < 1.83} {
	    return 125 
	} elseif {$factor < 2.33} {
	    return 150 
	} else {
	    return 200
	}
    }

    #
    # Public variables:
    #
    variable version	5.18
    variable scalingpct	[scalingPercentage]

    #
    # Creates a new tablelist widget:
    #
    namespace export	tablelist

    #
    # Sort the items of a tablelist widget by one or more of its columns:
    #
    namespace export	sortByColumn addToSortColumns

    #
    # Helper procedures used in binding scripts:
    #
    namespace export	convEventFields getTablelistPath getTablelistColumn

    #
    # Register various widgets for interactive cell editing:
    #
    namespace export	addBWidgetEntry addBWidgetSpinBox addBWidgetComboBox
    namespace export    addIncrEntryfield addIncrDateTimeWidget \
			addIncrSpinner addIncrSpinint addIncrCombobox
    namespace export	addCtext addOakleyCombobox
    namespace export	addDateMentry addTimeMentry addDateTimeMentry \
			addFixedPointMentry addIPAddrMentry addIPv6AddrMentry
}

package provide tablelist::common $::tablelist::version

#
# The following procedure, invoked in "tablelist.tcl" and "tablelist_tile.tcl",
# sets the variable ::tablelist::usingTile to the given value and sets a trace
# on this variable.
#
proc ::tablelist::useTile {bool} {
    variable usingTile $bool
    trace variable usingTile wu [list ::tablelist::restoreUsingTile $bool]
}

#
# The following trace procedure is executed whenever the variable
# ::tablelist::usingTile is written or unset.  It restores the variable to its
# original value, given by the first argument.
#
proc ::tablelist::restoreUsingTile {origVal varName index op} {
    variable usingTile $origVal
    switch $op {
	w {
	    return -code error "it is not allowed to use both Tablelist and\
				Tablelist_tile in the same application"
	}
	u {
	    trace variable usingTile wu \
		  [list ::tablelist::restoreUsingTile $origVal]
	}
    }
}

interp alias {} ::tk::frame {} ::frame
interp alias {} ::tk::label {} ::label

#==============================================================================
# Main Tablelist_tile package module.
#
# Copyright (c) 2000-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

package require Tcl 8.4
package require Tk  8.4
if {$::tk_version < 8.5 || [regexp {^8\.5a[1-5]$} $::tk_patchLevel]} {
    package require tile 0.6
}
package require -exact tablelist::common 5.18

package provide tablelist_tile $::tablelist::version
package provide Tablelist_tile $::tablelist::version

::tablelist::useTile 1

namespace eval ::tablelist {
    #
    # Commands related to tile themes:
    #
    namespace export	getThemes getCurrentTheme setTheme setThemeDefaults
}
#==============================================================================
# Contains utility procedures for mega-widgets.
#
# Structure of the module:
#   - Namespace initialization
#   - Public utility procedures
#
# Copyright (c) 2000-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

package require Tcl 8
package require Tk  8

#
# Namespace initialization
# ========================
#

namespace eval mwutil {
    #
    # Public variables:
    #
    variable version	2.8
    variable library	[file dirname [info script]]

    #
    # Public procedures:
    #
    namespace export	wrongNumArgs getAncestorByClass convEventFields \
			defineKeyNav processTraversal focusNext focusPrev \
			configureWidget fullConfigOpt fullOpt enumOpts \
			configureSubCmd attribSubCmd hasattribSubCmd \
			unsetattribSubCmd getScrollInfo

    #
    # Make modified versions of the procedures tk_focusNext and
    # tk_focusPrev, to be invoked in the processTraversal command
    #
    proc makeFocusProcs {} {
	#
	# Enforce the evaluation of the Tk library file "focus.tcl"
	#
	tk_focusNext .

	#
	# Build the procedures focusNext and focusPrev
	#
	foreach direction {Next Prev} {
	    set procBody [info body tk_focus$direction]
	    regsub -all {winfo children} $procBody {getChildren $class} procBody
	    proc focus$direction {w class} $procBody
	}
    }
    makeFocusProcs 

    #
    # Invoked in the procedures focusNext and focusPrev defined above:
    #
    proc getChildren {class w} {
	if {[string compare [winfo class $w] $class] == 0} {
	    return {}
	} else {
	    return [winfo children $w]
	}
    }
}

#
# Public utility procedures
# =========================
#

#------------------------------------------------------------------------------
# mwutil::wrongNumArgs
#
# Generates a "wrong # args" error message.
#------------------------------------------------------------------------------
proc mwutil::wrongNumArgs args {
    set optList {}
    foreach arg $args {
	lappend optList \"$arg\"
    }
    return -code error "wrong # args: should be [enumOpts $optList]"
}

#------------------------------------------------------------------------------
# mwutil::getAncestorByClass
#
# Gets the path name of the widget of the specified class from the path name w
# of one of its descendants.  It is assumed that all of the ancestors of w
# exist (but w itself needn't exist).
#------------------------------------------------------------------------------
proc mwutil::getAncestorByClass {w class} {
    regexp {^(\..+)\..+$} $w dummy win
    while {[string compare [winfo class $win] $class] != 0} {
	set win [winfo parent $win]
    }

    return $win
}

#------------------------------------------------------------------------------
# mwutil::convEventFields
#
# Gets the path name of the widget of the specified class and the x and y
# coordinates relative to the latter from the path name w of one of its
# descendants and from the x and y coordinates relative to the latter.
#------------------------------------------------------------------------------
proc mwutil::convEventFields {w x y class} {
    set win [getAncestorByClass $w $class]
    set _x  [expr {$x + [winfo rootx $w] - [winfo rootx $win]}]
    set _y  [expr {$y + [winfo rooty $w] - [winfo rooty $win]}]

    return [list $win $_x $_y]
}

#------------------------------------------------------------------------------
# mwutil::defineKeyNav
#
# For a given mega-widget class, the procedure defines the binding tag
# ${class}KeyNav as a partial replacement for "all", by substituting the
# scripts bound to the events <Tab>, <Shift-Tab>, and <<PrevWindow>> with new
# ones which propagate these events to the mega-widget of the given class
# containing the widget to which the event was reported.  (The event
# <Shift-Tab> was replaced with <<PrevWindow>> in Tk 8.3.0.)  This tag is
# designed to be inserted before "all" in the list of binding tags of a
# descendant of a mega-widget of the specified class.
#------------------------------------------------------------------------------
proc mwutil::defineKeyNav class {
    foreach event {<Tab> <Shift-Tab> <<PrevWindow>>} {
	bind ${class}KeyNav $event \
	     [list mwutil::processTraversal %W $class $event]
    }

    bind Entry   <<TraverseIn>> { %W selection range 0 end; %W icursor end }
    bind Spinbox <<TraverseIn>> { %W selection range 0 end; %W icursor end }
}

#------------------------------------------------------------------------------
# mwutil::processTraversal
#
# Processes the given traversal event for the mega-widget of the specified
# class containing the widget w if that mega-widget is not the only widget
# receiving the focus during keyboard traversal within its top-level widget.
#------------------------------------------------------------------------------
proc mwutil::processTraversal {w class event} {
    set win [getAncestorByClass $w $class]

    if {[string compare $event "<Tab>"] == 0} {
	set target [focusNext $win $class]
    } else {
	set target [focusPrev $win $class]
    }

    if {[string compare $target $win] != 0} {
	set focus [focus]
	if {[string length $focus] != 0} {
	    event generate $focus <<TraverseOut>>
	}

	focus $target
	event generate $target <<TraverseIn>>
    }

    return -code break ""
}

#------------------------------------------------------------------------------
# mwutil::configureWidget
#
# Configures the widget win by processing the command-line arguments specified
# in optValPairs and, if the value of initialize is true, also those database
# options that don't match any command-line arguments.
#------------------------------------------------------------------------------
proc mwutil::configureWidget {win configSpecsName configCmd cgetCmd \
			      optValPairs initialize} {
    upvar $configSpecsName configSpecs

    #
    # Process the command-line arguments
    #
    set cmdLineOpts {}
    set savedVals {}
    set failed 0
    set count [llength $optValPairs]
    foreach {opt val} $optValPairs {
	if {[catch {fullConfigOpt $opt configSpecs} result] != 0} {
	    set failed 1
	    break
	}
	if {$count == 1} {
	    set result "value for \"$opt\" missing"
	    set failed 1
	    break
	}
	set opt $result
	lappend cmdLineOpts $opt
	lappend savedVals [eval $cgetCmd [list $win $opt]]
	if {[catch {eval $configCmd [list $win $opt $val]} result] != 0} {
	    set failed 1
	    break
	}
	incr count -2
    }

    if {$failed} {
	#
	# Restore the saved values
	#
	foreach opt $cmdLineOpts val $savedVals {
	    eval $configCmd [list $win $opt $val]
	}

	return -code error $result
    }

    if {$initialize} {
	#
	# Process those configuration options that were not
	# given as command-line arguments; use the corresponding
	# values from the option database if available
	#
	foreach opt [lsort [array names configSpecs]] {
	    if {[llength $configSpecs($opt)] == 1 ||
		[lsearch -exact $cmdLineOpts $opt] >= 0} {
		continue
	    }
	    set dbName [lindex $configSpecs($opt) 0]
	    set dbClass [lindex $configSpecs($opt) 1]
	    set dbValue [option get $win $dbName $dbClass]
	    if {[string length $dbValue] == 0} {
		set default [lindex $configSpecs($opt) 3]
		eval $configCmd [list $win $opt $default]
	    } else {
		if {[catch {
		    eval $configCmd [list $win $opt $dbValue]
		} result] != 0} {
		    return -code error $result
		}
	    }
	}
    }

    return ""
}

#------------------------------------------------------------------------------
# mwutil::fullConfigOpt
#
# Returns the full configuration option corresponding to the possibly
# abbreviated option opt.
#------------------------------------------------------------------------------
proc mwutil::fullConfigOpt {opt configSpecsName} {
    upvar $configSpecsName configSpecs

    if {[info exists configSpecs($opt)]} {
	if {[llength $configSpecs($opt)] == 1} {
	    return $configSpecs($opt)
	} else {
	    return $opt
	}
    }

    set optList [lsort [array names configSpecs]]
    set count 0
    foreach elem $optList {
	if {[string first $opt $elem] == 0} {
	    incr count
	    if {$count == 1} {
		set option $elem
	    } else {
		break
	    }
	}
    }

    if {$count == 1} {
	if {[llength $configSpecs($option)] == 1} {
	    return $configSpecs($option)
	} else {
	    return $option
	}
    } elseif {$count == 0} {
	### return -code error "unknown option \"$opt\""
	return -code error \
	       "bad option \"$opt\": must be [enumOpts $optList]"
    } else {
	### return -code error "unknown option \"$opt\""
	return -code error \
	       "ambiguous option \"$opt\": must be [enumOpts $optList]"
    }
}

#------------------------------------------------------------------------------
# mwutil::fullOpt
#
# Returns the full option corresponding to the possibly abbreviated option opt.
#------------------------------------------------------------------------------
proc mwutil::fullOpt {kind opt optList} {
    if {[lsearch -exact $optList $opt] >= 0} {
	return $opt
    }

    set count 0
    foreach elem $optList {
	if {[string first $opt $elem] == 0} {
	    incr count
	    if {$count == 1} {
		set option $elem
	    } else {
		break
	    }
	}
    }

    if {$count == 1} {
	return $option
    } elseif {$count == 0} {
	return -code error \
	       "bad $kind \"$opt\": must be [enumOpts $optList]"
    } else {
	return -code error \
	       "ambiguous $kind \"$opt\": must be [enumOpts $optList]"
    }
}

#------------------------------------------------------------------------------
# mwutil::enumOpts
#
# Returns a string consisting of the elements of the given list, separated by
# commas and spaces.
#------------------------------------------------------------------------------
proc mwutil::enumOpts optList {
    set optCount [llength $optList]
    set n 1
    foreach opt $optList {
	if {$n == 1} {
	    set str $opt
	} elseif {$n < $optCount} {
	    append str ", $opt"
	} else {
	    if {$optCount > 2} {
		append str ","
	    }
	    append str " or $opt"
	}

	incr n
    }

    return $str
}

#------------------------------------------------------------------------------
# mwutil::configureSubCmd
#
# This procedure is invoked to process configuration subcommands.
#------------------------------------------------------------------------------
proc mwutil::configureSubCmd {win configSpecsName configCmd cgetCmd argList} {
    upvar $configSpecsName configSpecs

    set argCount [llength $argList]
    if {$argCount > 1} {
	#
	# Set the specified configuration options to the given values
	#
	return [configureWidget $win configSpecs $configCmd $cgetCmd $argList 0]
    } elseif {$argCount == 1} {
	#
	# Return the description of the specified configuration option
	#
	set opt [fullConfigOpt [lindex $argList 0] configSpecs]
	set dbName [lindex $configSpecs($opt) 0]
	set dbClass [lindex $configSpecs($opt) 1]
	set default [lindex $configSpecs($opt) 3]
	return [list $opt $dbName $dbClass $default \
		[eval $cgetCmd [list $win $opt]]]
    } else {
	#
	# Return a list describing all available configuration options
	#
	foreach opt [lsort [array names configSpecs]] {
	    if {[llength $configSpecs($opt)] == 1} {
		set alias $configSpecs($opt)
		if {$::tk_version >= 8.1} {
		    lappend result [list $opt $alias]
		} else {
		    set dbName [lindex $configSpecs($alias) 0]
		    lappend result [list $opt $dbName]
		}
	    } else {
		set dbName [lindex $configSpecs($opt) 0]
		set dbClass [lindex $configSpecs($opt) 1]
		set default [lindex $configSpecs($opt) 3]
		lappend result [list $opt $dbName $dbClass $default \
				[eval $cgetCmd [list $win $opt]]]
	    }
	}
	return $result
    }
}

#------------------------------------------------------------------------------
# mwutil::attribSubCmd
#
# This procedure is invoked to process *attrib subcommands.
#------------------------------------------------------------------------------
proc mwutil::attribSubCmd {win prefix argList} {
    set classNs [string tolower [winfo class $win]]
    upvar ::${classNs}::ns${win}::attribs attribs

    set argCount [llength $argList]
    if {$argCount > 1} {
	#
	# Set the specified attributes to the given values
	#
	if {$argCount % 2 != 0} {
	    return -code error "value for \"[lindex $argList end]\" missing"
	}
	foreach {attr val} $argList {
	    set attribs($prefix-$attr) $val
	}
	return ""
    } elseif {$argCount == 1} {
	#
	# Return the value of the specified attribute
	#
	set attr [lindex $argList 0]
	set name $prefix-$attr
	if {[info exists attribs($name)]} {
	    return $attribs($name)
	} else {
	    return ""
	}
    } else {
	#
	# Return the current list of attribute names and values
	#
	set len [string length "$prefix-"]
	set result {}
	foreach name [lsort [array names attribs "$prefix-*"]] {
	    set attr [string range $name $len end]
	    lappend result [list $attr $attribs($name)]
	}
	return $result
    }
}

#------------------------------------------------------------------------------
# mwutil::hasattribSubCmd
#
# This procedure is invoked to process has*attrib subcommands.
#------------------------------------------------------------------------------
proc mwutil::hasattribSubCmd {win prefix attr} {
    set classNs [string tolower [winfo class $win]]
    upvar ::${classNs}::ns${win}::attribs attribs

    return [info exists attribs($prefix-$attr)]
}

#------------------------------------------------------------------------------
# mwutil::unsetattribSubCmd
#
# This procedure is invoked to process unset*attrib subcommands.
#------------------------------------------------------------------------------
proc mwutil::unsetattribSubCmd {win prefix attr} {
    set classNs [string tolower [winfo class $win]]
    upvar ::${classNs}::ns${win}::attribs attribs

    set name $prefix-$attr
    if {[info exists attribs($name)]} {
	unset attribs($name)
    }

    return ""
}

#------------------------------------------------------------------------------
# mwutil::getScrollInfo
#
# Parses a list of arguments of the form "moveto <fraction>" or "scroll
# <number> units|pages" and returns the corresponding list consisting of two or
# three properly formatted elements.
#------------------------------------------------------------------------------
proc mwutil::getScrollInfo argList {
    set argCount [llength $argList]
    set opt [lindex $argList 0]

    if {[string first $opt "moveto"] == 0} {
	if {$argCount != 2} {
	    wrongNumArgs "moveto fraction"
	}

	set fraction [format "%f" [lindex $argList 1]]
	return [list moveto $fraction]
    } elseif {[string first $opt "scroll"] == 0} {
	if {$argCount != 3} {
	    wrongNumArgs "scroll number units|pages"
	}

	set number [format "%d" [lindex $argList 1]]
	set what [lindex $argList 2]
	if {[string first $what "units"] == 0} {
	    return [list scroll $number units]
	} elseif {[string first $what "pages"] == 0} {
	    return [list scroll $number pages]
	} else {
	    return -code error "bad argument \"$what\": must be units or pages"
	}
    } else {
	return -code error "unknown option \"$opt\": must be moveto or scroll"
    }
}
#!/usr/bin/env wish

#==============================================================================
# Creates new versions of the files "tablelistWidget.tcl", "tablelistBind.tcl",
# "tablelistConfig.tcl", "tablelistEdit.tcl", "tablelistMove.tcl",
# "tablelistSort.tcl", and "tablelistUtil.tcl" by defining the procedure
# "arrElemExists" and replacing all invocations of "[info exists
# <array>(<name>)]" with "[arrElemExists <array> <name>]".  This works around a
# bug in Tcl versions 8.2, 8.3.0 - 8.3.2, and 8.4a1 (fixed in Tcl 8.3.3 and
# 8.4a2), which causes excessive memory use when calling "info exists" on
# non-existent array elements.
#
# Copyright (c) 2001-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

set procDef {
    #
    # The following procedure returns 1 if arrName($name) exists and
    # 0 otherwise.  It is a (partial) replacement for [info exists
    # arrName($name)], which -- due to a bug in Tcl versions 8.2,
    # 8.3.0 - 8.3.2, and 8.4a1 (fixed in Tcl 8.3.3 and 8.4a2) --
    # causes excessive memory use if arrName($name) doesn't exist.
    # The first version of the procedure assumes that the second
    # argument doesn't contain glob-style special characters.
    #
    if {[regexp {^8\.(2\.[0-3]|3\.[0-2]|4a1)$} $tk_patchLevel]} {
	proc arrElemExists {arrName name} {
	    upvar $arrName arr
	    return [llength [array names arr $name]]
	}
    } else {
	proc arrElemExists {arrName name} {
	    upvar $arrName arr
	    return [info exists arr($name)]		;# this is much faster
	}
    }
}

#==============================================================================
# Contains public and private procedures used in tablelist bindings.
#
# Structure of the module:
#   - Public helper procedures
#   - Binding tag Tablelist
#   - Binding tag TablelistWindow
#   - Binding tag TablelistBody
#   - Binding tags TablelistLabel, TablelistSubLabel, and TablelistArrow
#
# Copyright (c) 2000-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#
# Public helper procedures
# ========================
#

#------------------------------------------------------------------------------
# tablelist::getTablelistColumn
#
# Gets the column number from the path name w of a (sub)label or sort arrow of
# a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::getTablelistColumn w {
    if {[regexp {^(\..+)\.hdr\.t\.f\.l([0-9]+)(-[it]l)?$} $w dummy win col] ||
	[regexp {^(\..+)\.hdr\.t\.f\.c([0-9]+)$} $w dummy win col]} {
	return $col
    } else {
	return -1
    }
}

#------------------------------------------------------------------------------
# tablelist::getTablelistPath
#
# Gets the path name of the tablelist widget from the path name w of one of its
# descendants.  It is assumed that all of the ancestors of w exist (but w
# itself needn't exist).
#------------------------------------------------------------------------------
proc tablelist::getTablelistPath w {
    return [mwutil::getAncestorByClass $w Tablelist]
}

#------------------------------------------------------------------------------
# tablelist::convEventFields
#
# Gets the path name of the tablelist widget and the x and y coordinates
# relative to the latter from the path name w of one of its descendants and
# from the x and y coordinates relative to the latter.
#------------------------------------------------------------------------------
proc tablelist::convEventFields {w x y} {
    return [mwutil::convEventFields $w $x $y Tablelist]
}

#------------------------------------------------------------------------------
# tablelist::delaySashPosUpdates
#
# Overrides the Tk or Ttk library procedure ::tk::panedwindow::DragSash or
# ::ttk::panedwindow::Drag with a version in which the "sash place ..." or
# "sashpos ..." invocations for the (ttk::)panedwindow widget w are delayed by
# ms milliseconds.
#------------------------------------------------------------------------------
proc tablelist::delaySashPosUpdates {w ms} {
    #
    # Check the first argument
    #
    if {![winfo exists $w]} {
	return -code error "bad window path name \"$w\""
    }
    set class [winfo class $w]
    switch $class {
	Panedwindow {
	    if {[llength [info commands ::tk::panedwindow::DragSash]] == 0} {
		return -code error "window \"$w\" is not a panedwindow widget"
	    }
	}

	TPanedwindow {
	    if {[llength [info commands ::ttk::panedwindow::Drag]] != 0} {
		set namesp ::ttk::panedwindow
	    } else {
		return -code error \
		       "window \"$w\" is not a ttk::panedwindow widget"
	    }
	}

	TPaned {
	    if {[llength [info commands ::ttk::paned::Drag]] != 0} {
		set namesp ::ttk::paned
	    } elseif {[llength [info commands ::tile::paned::Drag]] != 0} {
		set namesp ::tile::paned
	    } else {
		return -code error "window \"$w\" is not a ttk::paned widget"
	    }
	}

	default {
	    return -code error \
		   "window \"$w\" is not a (ttk::)panewindow widget"
	}
    }

    #
    # Check the second argument
    #
    if {[catch {format "%d" $ms} result] != 0} { ;# integer check with error msg
	return -code error $result
    }
    set ms $result
    if {$ms < 0} {
	#
	# Forget the sash position update delay for the given widget
	#
	if {[info exists ::tablelist::sashPosUpdateDelays($w)]} {
	    unset ::tablelist::sashPosUpdateDelays($w)
	}
	return ""
    }

    #
    # Remember the sash position update delay for the given widget
    #
    set ::tablelist::sashPosUpdateDelays($w) $ms

    bind $w <Destroy> {+
	#
	# Forget the sash position update delay for the given widget
	#
	if {[info exists ::tablelist::sashPosUpdateDelays(%W)]} {
	    unset ::tablelist::sashPosUpdateDelays(%W)
	}
    }

    #
    # Override the Tk or Ttk library procedure
    # ::tk::panedwindow::DragSash or ${namesp}::Drag
    #
    if {[string compare [winfo class $w] "Panedwindow"] == 0} {
	proc ::tk::panedwindow::DragSash {w x y proxy} {
	    variable ::tk::Priv
	    if {![info exists Priv(sash)]} { return }

	    if {[$w cget -opaqueresize]} {
		set proxy 0
	    }

	    if {$proxy} {
		$w proxy place [expr {$x + $Priv(dx)}] [expr {$y + $Priv(dy)}]
	    } elseif {[info exists ::tablelist::sashPosUpdateDelays($w)]} {
		set Priv(newSashX) [expr {$x + $Priv(dx)}]
		set Priv(newSashY) [expr {$y + $Priv(dy)}]

		if {![info exists Priv(sashPosId)]} {
		    set Priv(sashPosId) \
			[after $::tablelist::sashPosUpdateDelays($w) \
			 [list ::tk::panedwindow::UpdateSashPos $w $Priv(sash)]]
		}
	    } else {
		$w sash place $Priv(sash) \
			[expr {$x + $Priv(dx)}] [expr {$y + $Priv(dy)}]
	    }
	}

	proc ::tk::panedwindow::UpdateSashPos {w index} {
	    variable ::tk::Priv
	    unset Priv(sashPosId)

	    if {[winfo exists $w]} {
		$w sash place $index $Priv(newSashX) $Priv(newSashY)
	    }
	}

    } else {
	proc ${namesp}::Drag {w x y} [format {
	    variable State
	    if {!$State(pressed)} { return }

	    switch -- [$w cget -orient] {
		horizontal	{ set delta [expr {$x - $State(pressX)}] }
		vertical	{ set delta [expr {$y - $State(pressY)}] }
	    }

	    if {[info exists ::tablelist::sashPosUpdateDelays($w)]} {
		set State(newSashPos) [expr {$State(sashPos) + $delta}]

		if {![info exists State(sashPosId)]} {
		    set State(sashPosId) \
			[after $::tablelist::sashPosUpdateDelays($w) \
			 [list %s::UpdateSashPos $w $State(sash)]]
		}
	    } else {
		$w sashpos $State(sash) [expr {$State(sashPos) + $delta}]
	    }
	} $namesp]

	proc ${namesp}::UpdateSashPos {w index} {
	    variable State
	    unset State(sashPosId)

	    if {[winfo exists $w]} {
		$w sashpos $index $State(newSashPos)
	    }
	}
    }
}

#
# Binding tag Tablelist
# =====================
#

#------------------------------------------------------------------------------
# tablelist::addActiveTag
#
# This procedure is invoked when the tablelist widget win gains the keyboard
# focus.  It moves the "active" tag to the line or cell that displays the
# active item or element of the widget in its body text child.
#------------------------------------------------------------------------------
proc tablelist::addActiveTag win {
    upvar ::tablelist::ns${win}::data data
    set data(ownsFocus) 1

    #
    # Conditionally move the "active" tag to the line
    # or cell that displays the active item or element
    #
    if {![info exists data(dispId)]} {
	moveActiveTag $win
    }
}

#------------------------------------------------------------------------------
# tablelist::removeActiveTag
#
# This procedure is invoked when the tablelist widget win loses the keyboard
# focus.  It removes the "active" tag from the body text child of the widget.
#------------------------------------------------------------------------------
proc tablelist::removeActiveTag win {
    upvar ::tablelist::ns${win}::data data
    set data(ownsFocus) 0

    $data(body) tag remove curRow 1.0 end
    $data(body) tag remove active 1.0 end
}

#------------------------------------------------------------------------------
# tablelist::cleanup
#
# This procedure is invoked when the tablelist widget win is destroyed.  It
# executes some cleanup operations.
#------------------------------------------------------------------------------
proc tablelist::cleanup win {
    #
    # Cancel the execution of all delayed handleMotion, updateKeyToRowMap,
    # adjustSeps, makeStripes, showLineNumbers, stretchColumns, updateColors,
    # updateScrlColOffset, updateHScrlbar, updateVScrlbar, updateView,
    # synchronize, displayItems, horizMoveTo, vertMoveTo, autoScan,
    # horizAutoScan, forceRedraw, doCellConfig, redisplay, redisplayCol, and
    # destroyWidgets commands
    #
    upvar ::tablelist::ns${win}::data data
    foreach id {motionId mapId sepsId stripesId lineNumsId stretchId colorsId
		offsetId hScrlbarId vScrlbarId viewId syncId dispId moveToId
		afterId redrawId reconfigId} {
	if {[info exists data($id)]} {
	    after cancel $data($id)
	}
    }
    foreach name [array names data *redispId] {
	after cancel $data($name)
    }
    foreach destroyId $data(destroyIdList) {
	after cancel $destroyId
    }

    #
    # If there is a list variable associated with the
    # widget then remove the trace set on this variable
    #
    upvar #0 $data(-listvariable) var
    if {$data(hasListVar) && [info exists var]} {
	trace vdelete var wu $data(listVarTraceCmd)
    }

    #
    # Destroy any existing bindings for data(bodyTag),
    # data(labelTag), and data(editwinTag)
    #
    foreach event [bind $data(bodyTag)] {
	bind $data(bodyTag) $event ""
    }
    foreach event [bind $data(labelTag)] {
	bind $data(labelTag) $event ""
    }
    foreach event [bind $data(editwinTag)] {
	bind $data(editwinTag) $event ""
    }

    #
    # Delete the bitmaps displaying the sort ranks
    # and the images used to display the sort arrows
    #
    for {set rank 1} {$rank < 10} {incr rank} {
	image delete sortRank$rank$win
    }
    set imgNames [image names]
    for {set col 0} {$col < $data(colCount)} {incr col} {
	set w $data(hdrTxtFrmCanv)$col
	foreach shape {triangleUp darkLineUp lightLineUp
		       triangleDn darkLineDn lightLineDn} {
	    if {[lsearch -exact $imgNames $shape$w] >= 0} {
		image delete $shape$w
	    }
	}
    }

    destroy $data(corner)

    namespace delete ::tablelist::ns$win
    catch {rename ::$win ""}
}

#------------------------------------------------------------------------------
# tablelist::updateCanvases
#
# This procedure handles the events <Activate> and <Deactivate> by configuring
# the canvases displaying sort arrows.
#------------------------------------------------------------------------------
proc tablelist::updateCanvases win {
    upvar ::tablelist::ns${win}::data data
    foreach col $data(arrowColList) {
	configCanvas $win $col
	raiseArrow $win $col
    }
}

#------------------------------------------------------------------------------
# tablelist::updateConfigSpecs
#
# This procedure handles the virtual event <<ThemeChanged>> by updating the
# theme-specific default values of some tablelist configuration options.
#------------------------------------------------------------------------------
proc tablelist::updateConfigSpecs win {
    #
    # This might be an "after idle" callback; check whether the window exists
    #
    if {![array exists ::tablelist::ns${win}::data]} {
	return ""
    }

    set currentTheme [getCurrentTheme]
    upvar ::tablelist::ns${win}::data data
    if {[string compare $currentTheme $data(currentTheme)] == 0} {
	if {[string compare $currentTheme "tileqt"] == 0} {
	    set widgetStyle [tileqt_currentThemeName]
	    if {[info exists ::env(KDE_SESSION_VERSION)] &&
		[string length $::env(KDE_SESSION_VERSION)] != 0} {
		set colorScheme [getKdeConfigVal "General" "ColorScheme"]
	    } else {
		set colorScheme [getKdeConfigVal "KDE" "colorScheme"]
	    }
	    if {[string compare $widgetStyle $data(widgetStyle)] == 0 &&
		[string compare $colorScheme $data(colorScheme)] == 0} {
		return ""
	    }
	} else {
	    return ""
	}
    }

    #
    # Populate the array tmp with values corresponding to the old theme
    # and the array themeDefaults with values corresponding to the new one
    #
    array set tmp $data(themeDefaults)
    setThemeDefaults

    #
    # Set those configuration options whose values equal the old
    # theme-specific defaults to the new theme-specific ones
    #
    variable themeDefaults
    foreach opt {-background -foreground -disabledforeground -stripebackground
		 -selectbackground -selectforeground -selectborderwidth -font
		 -labelforeground -labelfont -labelborderwidth -labelpady
		 -treestyle} {
	if {[string compare $data($opt) $tmp($opt)] == 0} {
	    doConfig $win $opt $themeDefaults($opt)
	}
    }
    if {[string compare $data(-arrowcolor) $tmp(-arrowcolor)] == 0 &&
	[string compare $data(-arrowstyle) $tmp(-arrowstyle)] == 0} {
	foreach opt {-arrowcolor -arrowdisabledcolor -arrowstyle} {
	    doConfig $win $opt $themeDefaults($opt)
	}
    }
    foreach opt {-background -foreground} {
	doConfig $win $opt $data($opt)	;# sets the bg color of the separators
    }
    updateCanvases $win

    #
    # Destroy and recreate the edit window if present
    #
    if {[set editCol $data(editCol)] >= 0} {
	set editRow $data(editRow)
	saveEditData $win
	destroy $data(bodyFrm)
	doEditCell $win $editRow $editCol 1
    }

    #
    # Destroy and recreate the embedded windows
    #
    if {$data(winCount) != 0} {
	for {set row 0} {$row < $data(itemCount)} {incr row} {
	    for {set col 0} {$col < $data(colCount)} {incr col} {
		set key [lindex $data(keyList) $row]
		if {[info exists data($key,$col-window)]} {
		    set val $data($key,$col-window)
		    doCellConfig $row $col $win -window ""
		    doCellConfig $row $col $win -window $val
		}
	    }
	}
    }

    set data(currentTheme) $currentTheme
    set data(themeDefaults) [array get themeDefaults]
    if {[string compare $currentTheme "tileqt"] == 0} {
	set data(widgetStyle) [tileqt_currentThemeName]
	if {[info exists ::env(KDE_SESSION_VERSION)] &&
	    [string length $::env(KDE_SESSION_VERSION)] != 0} {
	    set data(colorScheme) [getKdeConfigVal "General" "ColorScheme"]
	} else {
	    set data(colorScheme) [getKdeConfigVal "KDE" "colorScheme"]
	}
    } else {
	set data(widgetStyle) ""
	set data(colorScheme) ""
    }
}

#
# Binding tag TablelistWindow
# ===========================
#

#------------------------------------------------------------------------------
# tablelist::cleanupWindow
#
# This procedure is invoked when a window aux embedded into a tablelist widget
# is destroyed.  It invokes the cleanup script associated with the cell
# containing the window, if any.
#------------------------------------------------------------------------------
proc tablelist::cleanupWindow aux {
    regexp {^(.+)\.body\.frm_(k[0-9]+),([0-9]+)$} $aux dummy win key col
    upvar ::tablelist::ns${win}::data data
    if {[info exists data($key,$col-windowdestroy)]} {
	set row [keyToRow $win $key]
	uplevel #0 $data($key,$col-windowdestroy) [list $win $row $col $aux.w]
    }
}

#
# Binding tag TablelistBody
# =========================
#

#------------------------------------------------------------------------------
# tablelist::defineTablelistBody
#
# Defines the bindings for the binding tag TablelistBody.
#------------------------------------------------------------------------------
proc tablelist::defineTablelistBody {} {
    variable priv
    array set priv {
	x			""
	y			""
	afterId			""
	prevRow			""
	prevCol			""
	prevActExpCollCtrlCell	""
	selection		{}
	selClearPending		0
	selChangePending	0
	justClicked		0
	justReleased		0
	clickedInEditWin	0
	clickedExpCollCtrl	0
    }

    foreach event {<Enter> <Motion> <Leave>} {
	bind TablelistBody $event [format {
	    tablelist::handleMotionDelayed %%W %%x %%y %%X %%Y %%m %s
	} $event]
    }
    bind TablelistBody <Button-1> {
	if {[winfo exists %W]} {
	    foreach {tablelist::W tablelist::x tablelist::y} \
		[tablelist::convEventFields %W %x %y] {}

	    set tablelist::priv(x) $tablelist::x
	    set tablelist::priv(y) $tablelist::y
	    set tablelist::priv(row) [$tablelist::W nearest       $tablelist::y]
	    set tablelist::priv(col) [$tablelist::W nearestcolumn $tablelist::x]
	    set tablelist::priv(justClicked) 1
	    after 300 [list set tablelist::priv(justClicked) 0]
	    set tablelist::priv(clickedInEditWin) 0
	    if {[$tablelist::W cget -setfocus] &&
		[string compare [$tablelist::W cget -state] "normal"] == 0} {
		focus [$tablelist::W bodypath]
	    }
	    if {[tablelist::wasExpCollCtrlClicked %W %x %y]} {
		set tablelist::priv(clickedExpCollCtrl) 1
		if {[string length [$tablelist::W editwinpath]] != 0} {
		    tablelist::doFinishEditing $tablelist::W
		}
	    } else {
		tablelist::condEditContainingCell $tablelist::W \
		    $tablelist::x $tablelist::y
		set tablelist::priv(row) \
		    [$tablelist::W nearest       $tablelist::y]
		set tablelist::priv(col) \
		    [$tablelist::W nearestcolumn $tablelist::x]
		tablelist::condBeginMove $tablelist::W $tablelist::priv(row)
		tablelist::beginSelect $tablelist::W \
		    $tablelist::priv(row) $tablelist::priv(col) 1
	    }
	}
    }
    bind TablelistBody <Double-Button-1> {
	if {[winfo exists %W]} {
	    foreach {tablelist::W tablelist::x tablelist::y} \
		[tablelist::convEventFields %W %x %y] {}

	    if {[$tablelist::W cget -editselectedonly]} {
		tablelist::condEditContainingCell $tablelist::W \
		    $tablelist::x $tablelist::y
	    }
	}
    }
    bind TablelistBody <B1-Motion> {
	if {$tablelist::priv(justClicked)} {
	    continue
	}

	foreach {tablelist::W tablelist::x tablelist::y} \
	    [tablelist::convEventFields %W %x %y] {}

	if {[string length $tablelist::priv(x)] == 0 ||
	    [string length $tablelist::priv(y)] == 0} {
	    set tablelist::priv(x) $tablelist::x
	    set tablelist::priv(y) $tablelist::y
	}
	set tablelist::priv(prevX) $tablelist::priv(x)
	set tablelist::priv(prevY) $tablelist::priv(y)
	set tablelist::priv(x) $tablelist::x
	set tablelist::priv(y) $tablelist::y
	tablelist::condAutoScan $tablelist::W
	if {!$tablelist::priv(clickedExpCollCtrl)} {
	    tablelist::motion $tablelist::W \
		[$tablelist::W nearest       $tablelist::y] \
		[$tablelist::W nearestcolumn $tablelist::x] 1
	    tablelist::condShowTarget $tablelist::W $tablelist::y
	}
    }
    bind TablelistBody <ButtonRelease-1> {
	if {[winfo exists %W]} {
	    foreach {tablelist::W tablelist::x tablelist::y} \
		[tablelist::convEventFields %W %x %y] {}

	    set tablelist::priv(x) ""
	    set tablelist::priv(y) ""
	    after cancel $tablelist::priv(afterId)
	    set tablelist::priv(afterId) ""
	    set tablelist::priv(justReleased) 1
	    after 100 [list set tablelist::priv(justReleased) 0]
	    set tablelist::priv(releasedInEditWin) 0
	    if {!$tablelist::priv(clickedExpCollCtrl)} {
		if {$tablelist::priv(justClicked)} {
		    tablelist::moveOrActivate $tablelist::W \
			$tablelist::priv(row) $tablelist::priv(col) 1
		} else {
		    tablelist::moveOrActivate $tablelist::W \
			[$tablelist::W nearest       $tablelist::y] \
			[$tablelist::W nearestcolumn $tablelist::x] \
			[expr {$tablelist::x >= 0 &&
			       $tablelist::x < [winfo width $tablelist::W] &&
			       $tablelist::y >= [winfo y $tablelist::W.body] &&
			       $tablelist::y < [winfo height $tablelist::W]}]
		}
	    }
	    set tablelist::priv(clickedExpCollCtrl) 0
	    after 100 [list tablelist::condEvalInvokeCmd $tablelist::W]
	}
    }
    bind TablelistBody <Shift-Button-1> {
	foreach {tablelist::W tablelist::x tablelist::y} \
	    [tablelist::convEventFields %W %x %y] {}

	tablelist::beginExtend $tablelist::W \
	    [$tablelist::W nearest       $tablelist::y] \
	    [$tablelist::W nearestcolumn $tablelist::x]
    }
    bind TablelistBody <Control-Button-1> {
	foreach {tablelist::W tablelist::x tablelist::y} \
	    [tablelist::convEventFields %W %x %y] {}

	tablelist::beginToggle $tablelist::W \
	    [$tablelist::W nearest       $tablelist::y] \
	    [$tablelist::W nearestcolumn $tablelist::x]
    }

    bind TablelistBody <Return> {
	tablelist::condEditActiveCell [tablelist::getTablelistPath %W]
    }
    bind TablelistBody <KP_Enter> {
	tablelist::condEditActiveCell [tablelist::getTablelistPath %W]
    }
    bind TablelistBody <Tab> {
	tablelist::nextPrevCell [tablelist::getTablelistPath %W] 1
    }
    bind TablelistBody <Shift-Tab> {
	tablelist::nextPrevCell [tablelist::getTablelistPath %W] -1
    }
    bind TablelistBody <<PrevWindow>> {
	tablelist::nextPrevCell [tablelist::getTablelistPath %W] -1
    }
    bind TablelistBody <plus> {
	tablelist::plusMinus [tablelist::getTablelistPath %W] plus
    }
    bind TablelistBody <minus> {
	tablelist::plusMinus [tablelist::getTablelistPath %W] minus
    }
    bind TablelistBody <KP_Add> {
	tablelist::plusMinus [tablelist::getTablelistPath %W] plus
    }
    bind TablelistBody <KP_Subtract> {
	tablelist::plusMinus [tablelist::getTablelistPath %W] minus
    }

    foreach {virtual event} {
	PrevLine <Up>		 NextLine <Down>
	PrevChar <Left>		 NextChar <Right>
	LineStart <Home>	 LineEnd <End>
	PrevWord <Control-Left>	 NextWord <Control-Right>

	SelectPrevLine <Shift-Up>     SelectNextLine <Shift-Down>
	SelectPrevChar <Shift-Left>   SelectNextChar <Shift-Right>
	SelectLineStart <Shift-Home>  SelectLineEnd <Shift-End>
	SelectAll <Control-slash>     SelectNone <Control-backslash>} {
	if {[llength [event info <<$virtual>>]] == 0} {
	    set eventArr($virtual) $event
	} else {
	    set eventArr($virtual) <<$virtual>>
	}
    }

    bind TablelistBody $eventArr(PrevLine) {
	tablelist::upDown [tablelist::getTablelistPath %W] -1
    }
    bind TablelistBody $eventArr(NextLine) {
	tablelist::upDown [tablelist::getTablelistPath %W] 1
    }
    bind TablelistBody $eventArr(PrevChar) {
	tablelist::leftRight [tablelist::getTablelistPath %W] -1
    }
    bind TablelistBody $eventArr(NextChar) {
	tablelist::leftRight [tablelist::getTablelistPath %W] 1
    }
    bind TablelistBody <Prior> {
	tablelist::priorNext [tablelist::getTablelistPath %W] -1
    }
    bind TablelistBody <Next> {
	tablelist::priorNext [tablelist::getTablelistPath %W] 1
    }
    bind TablelistBody $eventArr(LineStart) {
	tablelist::homeEnd [tablelist::getTablelistPath %W] Home
    }
    bind TablelistBody $eventArr(LineEnd) {
	tablelist::homeEnd [tablelist::getTablelistPath %W] End
    }
    bind TablelistBody <Control-Home> {
	tablelist::firstLast [tablelist::getTablelistPath %W] first
    }
    bind TablelistBody <Control-End> {
	tablelist::firstLast [tablelist::getTablelistPath %W] last
    }
    bind TablelistBody $eventArr(SelectPrevLine) {
	tablelist::extendUpDown [tablelist::getTablelistPath %W] -1
    }
    bind TablelistBody $eventArr(SelectNextLine) {
	tablelist::extendUpDown [tablelist::getTablelistPath %W] 1
    }
    bind TablelistBody $eventArr(SelectPrevChar) {
	tablelist::extendLeftRight [tablelist::getTablelistPath %W] -1
    }
    bind TablelistBody $eventArr(SelectNextChar) {
	tablelist::extendLeftRight [tablelist::getTablelistPath %W] 1
    }
    bind TablelistBody $eventArr(SelectLineStart) {
	tablelist::extendToHomeEnd [tablelist::getTablelistPath %W] Home
    }
    bind TablelistBody $eventArr(SelectLineEnd) {
	tablelist::extendToHomeEnd [tablelist::getTablelistPath %W] End
    }
    bind TablelistBody <Shift-Control-Home> {
	tablelist::extendToFirstLast [tablelist::getTablelistPath %W] first
    }
    bind TablelistBody <Shift-Control-End> {
	tablelist::extendToFirstLast [tablelist::getTablelistPath %W] last
    }
    foreach event {<space> <Select>} {
	bind TablelistBody $event {
	    set tablelist::W [tablelist::getTablelistPath %W]

	    tablelist::beginSelect $tablelist::W \
		[$tablelist::W index active] [$tablelist::W columnindex active]
	}
    }
    foreach event {<Shift-Control-space> <Shift-Select>} {
	bind TablelistBody $event {
	    set tablelist::W [tablelist::getTablelistPath %W]

	    tablelist::beginExtend $tablelist::W \
		[$tablelist::W index active] [$tablelist::W columnindex active]
	}
    }
    foreach event {<Control-space> <Control-Select>} {
	bind TablelistBody $event {
	    if {!$tablelist::strictTk} {
		set tablelist::W [tablelist::getTablelistPath %W]

		tablelist::beginToggle $tablelist::W \
		    [$tablelist::W index active] \
		    [$tablelist::W columnindex active]
	    }
	}
    }
    bind TablelistBody <Escape> {
	tablelist::cancelSelection [tablelist::getTablelistPath %W]
    }
    bind TablelistBody $eventArr(SelectAll) {
	tablelist::selectAll [tablelist::getTablelistPath %W]
    }
    bind TablelistBody $eventArr(SelectNone) {
	set tablelist::W [tablelist::getTablelistPath %W]

	if {[string compare [$tablelist::W cget -selectmode] "browse"] != 0} {
	    $tablelist::W selection clear 0 end
	    event generate $tablelist::W <<TablelistSelect>>
	}
    }
    foreach pattern {Tab Shift-Tab ISO_Left_Tab hpBackTab} {
	catch {
	    foreach modifier {Control Meta} {
		bind TablelistBody <$modifier-$pattern> [format {
		    mwutil::processTraversal %%W Tablelist <%s>
		} $pattern]
	    }
	}
    }

    variable winSys
    catch {
	if {[string compare $winSys "classic"] == 0 ||
	    [string compare $winSys "aqua"] == 0} {
	    bind TablelistBody <MouseWheel> {
		[tablelist::getTablelistPath %W] yview scroll [expr {-%D}] units
		break
	    }
	    bind TablelistBody <Shift-MouseWheel> {
		[tablelist::getTablelistPath %W] xview scroll [expr {-%D}] units
		break
	    }
	    bind TablelistBody <Option-MouseWheel> {
		[tablelist::getTablelistPath %W] yview scroll \
		    [expr {-10 * %D}] units
		break
	    }
	    bind TablelistBody <Shift-Option-MouseWheel> {
		[tablelist::getTablelistPath %W] xview scroll \
		    [expr {-10 * %D}] units
		break
	    }
	} else {
	    bind TablelistBody <MouseWheel> {
		[tablelist::getTablelistPath %W] yview scroll \
		    [expr {-(%D / 120) * 4}] units
		break
	    }
	    bind TablelistBody <Shift-MouseWheel> {
		[tablelist::getTablelistPath %W] xview scroll \
		    [expr {-(%D / 120) * 4}] units
		break
	    }

	    foreach event {<Control-Key-a> <Control-Lock-Key-A>} {
		bind TablelistBody $event {
		    tablelist::selectAll [tablelist::getTablelistPath %W]
		}
	    }
	    foreach event {<Shift-Control-Key-A> <Shift-Control-Lock-Key-a>} {
		bind TablelistBody $event {
		    set tablelist::W [tablelist::getTablelistPath %W]

		    if {[string compare [$tablelist::W cget -selectmode] \
			 "browse"] != 0} {
			$tablelist::W selection clear 0 end
			event generate $tablelist::W <<TablelistSelect>>
		    }
		}
	    }
	}
    }

    if {[string compare $winSys "x11"] == 0} {
	bind TablelistBody <Button-4> {
	    if {!$tk_strictMotif} {
		[tablelist::getTablelistPath %W] yview scroll -5 units
		break
	    }
	}
	bind TablelistBody <Button-5> {
	    if {!$tk_strictMotif} {
		[tablelist::getTablelistPath %W] yview scroll 5 units
		break
	    }
	}
	bind TablelistBody <Shift-Button-4> {
	    if {!$tk_strictMotif} {
		[tablelist::getTablelistPath %W] xview scroll -5 units
		break
	    }
	}
	bind TablelistBody <Shift-Button-5> {
	    if {!$tk_strictMotif} {
		[tablelist::getTablelistPath %W] xview scroll 5 units
		break
	    }
	}
    }

    foreach event {<Control-Left> <<PrevWord>> <Control-Right> <<NextWord>>
		   <Control-Prior> <Control-Next> <<Copy>>
		   <Button-2> <B2-Motion>} {
	set script [strMap {
	    "%W" "$tablelist::W"  "%x" "$tablelist::x"  "%y" "$tablelist::y"
	} [bind Listbox $event]]

	if {[string length $script] != 0} {
	    bind TablelistBody $event [format {
		if {[winfo exists %%W]} {
		    foreach {tablelist::W tablelist::x tablelist::y} \
			[tablelist::convEventFields %%W %%x %%y] {}
		    %s
		}
	    } $script]
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::invokeMotionHandler
#
# Invokes the procedure handleMotionDelayed for the body of the tablelist
# widget win and the current pointer coordinates.
#------------------------------------------------------------------------------
proc tablelist::invokeMotionHandler win {
    upvar ::tablelist::ns${win}::data data
    set w $data(body)
    set X [winfo pointerx $w]
    set Y [winfo pointery $w]
    if {$X >= 0 && $Y >= 0} {	;# the mouse pointer is on the same screen as w
	set x [expr {$X - [winfo rootx $w]}]
	set y [expr {$Y - [winfo rooty $w]}]
    } else {
	set x -1
	set y -1
    }

    handleMotionDelayed $w $x $y $X $Y "" <Motion>
}

#------------------------------------------------------------------------------
# tablelist::handleMotionDelayed
#
# This procedure is invoked when the mouse pointer enters or leaves the body of
# a tablelist widget or one of its separators, or is moving within it.  It
# schedules the execution of the handleMotion procedure 100 ms later.
#------------------------------------------------------------------------------
proc tablelist::handleMotionDelayed {w x y X Y mode event} {
    set win [getTablelistPath $w]
    upvar ::tablelist::ns${win}::data data
    set data(motionData) [list $w $x $y $X $Y $event]
    if {![info exists data(motionId)]} {
	set data(motionId) [after 100 [list tablelist::handleMotion $win]]
    }

    if {[string compare $event "<Enter>"] == 0 &&
	[string compare $mode "NotifyNormal"] == 0} {
	set data(justEntered) 1
    }
}

#------------------------------------------------------------------------------
# tablelist::handleMotion
#
# Invokes the procedures showOrHideTooltip, updateExpCollCtrl, and updateCursor.
#------------------------------------------------------------------------------
proc tablelist::handleMotion win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(motionId)]} {
	after cancel $data(motionId)
	unset data(motionId)
    }

    set data(justEntered) 0

    foreach {w x y X Y event} $data(motionData) {}
    if {![winfo exists $w]} {
	invokeMotionHandler $win
	return ""
    }

    #
    # Get the containing cell from the coordinates relative to the tablelist
    #
    foreach {win _x _y} [convEventFields $w $x $y] {}
    set row [containingRow $win $_y]
    set col [containingCol $win $_x]

    showOrHideTooltip $win $row $col $X $Y
    updateExpCollCtrl $win $w $row $col $x

    #
    # Make sure updateCursor won't change the cursor of an embedded window
    #
    if {[string match "$data(body).frm_k*" $w] &&
	[string compare [winfo parent $w] $data(body)] == 0 &&
	[string compare $event "<Leave>"] != 0} {
	set row -1
	set col -1
    }

    updateCursor $win $row $col
}

#------------------------------------------------------------------------------
# tablelist::showOrHideTooltip
#
# If the pointer has crossed a cell boundary then the procedure removes the old
# tooltip and displays the one corresponding to the new cell.
#------------------------------------------------------------------------------
proc tablelist::showOrHideTooltip {win row col X Y} {
    upvar ::tablelist::ns${win}::data data
    if {[string length $data(-tooltipaddcommand)] == 0 ||
	[string length $data(-tooltipdelcommand)] == 0 ||
	[string compare $row,$col $data(prevCell)] == 0} {
	return ""
    }

    #
    # Remove the old tooltip, if any.  Then, if we are within a
    # cell, display the new tooltip corresponding to that cell.
    #
    event generate $win <Leave>
    catch {uplevel #0 $data(-tooltipdelcommand) [list $win]}
    set data(prevCell) $row,$col
    if {$row >= 0 && $col >= 0} {
	set focus [focus -displayof $win]
	if {[string length $focus] == 0 || [string first $win $focus] != 0 ||
	    [string compare [winfo toplevel $focus] \
	     [winfo toplevel $win]] == 0} {
	    uplevel #0 $data(-tooltipaddcommand) [list $win $row $col]
	    event generate $win <Enter> -rootx $X -rooty $Y
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::updateExpCollCtrl
#
# Activates or deactivates the expand/collapse control under the mouse pointer.
#------------------------------------------------------------------------------
proc tablelist::updateExpCollCtrl {win w row col x} {
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    set indentLabel $data(body).ind_$key,$col

    #
    # Check whether the x coordinate is inside the expand/collapse control
    #
    set inExpCollCtrl 0
    if {[winfo exists $indentLabel]} {
	if {[string compare $w $data(body)] == 0 &&
	    $x < [winfo x $indentLabel] &&
	    [string compare $data($key-parent) "root"] == 0} {
	    set imgName [$indentLabel cget -image]
	    if {[regexp {^tablelist_(.+)_(collapsed|expanded).*Img([0-9]+)$} \
			 $imgName dummy treeStyle mode depth]} {
		#
		# The mouse position is in the tablelist body, to the left
		# of an expand/collapse control of a top-level item:  Handle
		# this like a position inside the expand/collapse control
		#
		set inExpCollCtrl 1
	    }
	} elseif {[string compare $w $indentLabel] == 0} {
	    set imgName [$w cget -image]
	    if {[regexp {^tablelist_(.+)_(collapsed|expanded).*Img([0-9]+)$} \
			 $imgName dummy treeStyle mode depth]} {
		#
		# The mouse position is in an expand/collapse
		# image (which ends with the expand/collapse
		# control):  Check whether it is inside the control
		#
		set baseWidth [image width tablelist_${treeStyle}_collapsedImg]
		if {$x >= [winfo width $w] - $baseWidth - 5} {
		    set inExpCollCtrl 1
		}
	    }
	}
    }

    #
    # Conditionally deactivate the previously activated expand/collapse control
    #
    variable priv
    set prevCellIdx $priv(prevActExpCollCtrlCell)
    if {[string length $prevCellIdx] != 0 &&
	[info exists data($prevCellIdx-indent)] &&
	(!$inExpCollCtrl || [string compare $prevCellIdx $key,$col] != 0) &&
	[winfo exists $data(body).ind_$prevCellIdx]} {
	set data($prevCellIdx-indent) \
	    [strMap {"Act" ""} $data($prevCellIdx-indent)]
	$data(body).ind_$prevCellIdx configure -image $data($prevCellIdx-indent)
	set priv(prevActExpCollCtrlCell) ""
    }

    if {!$inExpCollCtrl || [string compare $prevCellIdx $key,$col] == 0} {
	return ""
    }

    #
    # Activate the expand/collapse control under the mouse pointer
    #
    variable ${treeStyle}_collapsedActImg
    if {[info exists ${treeStyle}_collapsedActImg]} {
	set data($key,$col-indent) [strMap {
	    "SelActImg" "SelActImg" "SelImg" "SelActImg"
	    "ActImg" "ActImg" "Img" "ActImg"
	} $data($key,$col-indent)]
	$indentLabel configure -image $data($key,$col-indent)
	set priv(prevActExpCollCtrlCell) $key,$col
    }
}

#------------------------------------------------------------------------------
# tablelist::updateCursor
#
# Updates the cursor of the body component of the tablelist widget win, over
# the specified cell containing the mouse pointer.
#------------------------------------------------------------------------------
proc tablelist::updateCursor {win row col} {
    upvar ::tablelist::ns${win}::data data
    if {$data(inEditWin)} {
	set cursor $data(-cursor)
    } elseif {$data(-showeditcursor)} {
	if {$data(-editselectedonly) &&
	    ![::$win cellselection includes $row,$col]} {
	    set editable 0
	} else {
	    set editable [expr {$row >= 0 && $col >= 0 &&
			  [isCellEditable $win $row $col]}]
	}

	if {$editable} {
	    if {$row == $data(editRow) && $col == $data(editCol)} {
		set cursor $data(-cursor)
	    } else {
		variable editCursor
		if {![info exists editCursor]} {
		    makeEditCursor 
		}
		set cursor $editCursor
	    }
	} else {
	    set cursor $data(-cursor)
	}

	#
	# Special handling for cell editing with the aid of BWidget
	# ComboBox. Oakley combobox, or Tk menubutton widgets
	#
	if {$data(editRow) >= 0 && $data(editCol) >= 0} {
	    foreach c [winfo children $data(bodyFrmEd)] {
		set class [winfo class $c]
		if {([string compare $class "Toplevel"] == 0 ||
		     [string compare $class "Menu"] == 0) &&
		     [winfo ismapped $c]} {
		    set cursor $data(-cursor)
		    break
		}
	    }
	}
    } else {
	set cursor $data(-cursor)
    }

    if {[string compare [$data(body) cget -cursor] $cursor] != 0} {
	$data(body) configure -cursor $cursor
    }
}

#------------------------------------------------------------------------------
# tablelist::makeEditCursor
#
# Creates the platform-specific edit cursor.
#------------------------------------------------------------------------------
proc tablelist::makeEditCursor {} {
    variable editCursor
    variable winSys

    if {[string compare $winSys "win32"] == 0} {
	variable library
	set cursorName "pencil.cur"
	set cursorFile [file join $library scripts $cursorName]
	if {$::tcl_version >= 8.4} {
	    set cursorFile [file normalize $cursorFile]
	}
	set editCursor [list @$cursorFile]

	#
	# Make sure it will work for starpacks, too
	#
	variable helpLabel
	if {[catch {$helpLabel configure -cursor $editCursor}] != 0} {
	    set tempDir $::env(TEMP)
	    file copy -force $cursorFile $tempDir
	    set editCursor [list @[file join $tempDir $cursorName]]
	}
    } else {
	set editCursor pencil
    }
}

#------------------------------------------------------------------------------
# tablelist::wasExpCollCtrlClicked
#
# This procedure is invoked when mouse button 1 is pressed in the body of a
# tablelist widget or in one of its separators.  It checks whether the mouse
# click occurred inside an expand/collapse control.
#------------------------------------------------------------------------------
proc tablelist::wasExpCollCtrlClicked {w x y} {
    foreach {win _x _y} [convEventFields $w $x $y] {}
    set row [containingRow $win $_y]
    set col [containingCol $win $_x]
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    set indentLabel $data(body).ind_$key,$col
    if {![winfo exists $indentLabel]} {
	return 0
    }

    #
    # Check whether the x coordinate is inside the expand/collapse control
    #
    set inExpCollCtrl 0
    if {[string compare $w $data(body)] == 0 && $x < [winfo x $indentLabel] &&
	[string compare $data($key-parent) "root"] == 0} {
	set imgName [$indentLabel cget -image]
	if {[regexp {^tablelist_(.+)_(collapsed|expanded).*Img([0-9]+)$} \
		     $imgName dummy treeStyle mode depth]} {
	    #
	    # The mouse position is in the tablelist body, to the left
	    # of an expand/collapse control of a top-level item:  Handle
	    # this like a position inside the expand/collapse control
	    #
	    set inExpCollCtrl 1
	}
    } elseif {[string compare $w $indentLabel] == 0} {
	set imgName [$w cget -image]
	if {[regexp {^tablelist_(.+)_(collapsed|expanded).*Img([0-9]+)$} \
		     $imgName dummy treeStyle mode depth]} {
	    #
	    # The mouse position is in an expand/collapse
	    # image (which ends with the expand/collapse
	    # control):  Check whether it is inside the control
	    #
	    set baseWidth [image width tablelist_${treeStyle}_collapsedImg]
	    if {$x >= [winfo width $w] - $baseWidth - 5} {
		set inExpCollCtrl 1
	    }
	}
    }

    if {!$inExpCollCtrl} {
	return 0
    }

    #
    # Toggle the state of the expand/collapse control
    #
    if {[string compare $mode "collapsed"] == 0} {
	::$win expand $row -partly
    } else {
	::$win collapse $row -partly
    }

    updateViewWhenIdle $win
    return 1
}

#------------------------------------------------------------------------------
# tablelist::condEditContainingCell
#
# This procedure is invoked when mouse button 1 is pressed in the body of a
# tablelist widget win or in one of its separators.  If the mouse click
# occurred inside an editable cell and the latter is not already being edited,
# then the procedure starts the interactive editing in that cell.  Otherwise it
# finishes a possibly active cell editing.
#------------------------------------------------------------------------------
proc tablelist::condEditContainingCell {win x y} {
    #
    # Get the containing cell from the coordinates relative to the parent
    #
    set row [containingRow $win $y]
    set col [containingCol $win $x]

    upvar ::tablelist::ns${win}::data data
    if {$data(justEntered) || ($data(-editselectedonly) &&
	![::$win cellselection includes $row,$col])} {
	set editable 0
    } else {
	set editable [expr {$row >= 0 && $col >= 0 &&
		      [isCellEditable $win $row $col]}]
    }

    #
    # The following check is sometimes needed on OS X if
    # editing with the aid of a menubutton is in progress
    #
    variable editCursor
    if {($row != $data(editRow) || $col != $data(editCol)) &&
	$data(-showeditcursor) && [info exists editCursor] &&
	[string compare [$data(body) cget -cursor] $editCursor] != 0} {
	set editable 0
    }

    if {$editable} {
	#
	# Get the coordinates relative to the
	# tablelist body and invoke doEditCell
	#
	set w $data(body)
	incr x -[winfo x $w]
	incr y -[winfo y $w]
	scan [$w index @$x,$y] "%d.%d" line charPos
	doEditCell $win $row $col 0 "" $charPos
    } elseif {$data(editRow) >= 0} {
	#
	# Finish the current editing
	#
	doFinishEditing $win
    }
}

#------------------------------------------------------------------------------
# tablelist::condBeginMove
#
# This procedure is typically invoked on button-1 presses in the body of a
# tablelist widget or in one of its separators.  It begins the process of
# moving the nearest row if the rows are movable and the selection mode is not
# browse or extended.
#------------------------------------------------------------------------------
proc tablelist::condBeginMove {win row} {
    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled) || !$data(-movablerows) || $data(itemCount) == 0 ||
	[string compare $data(-selectmode) "browse"] == 0 ||
	[string compare $data(-selectmode) "extended"] == 0} {
	return ""
    }

    set data(sourceRow) $row
    set sourceKey [lindex $data(keyList) $row]
    set data(sourceEndRow) [nodeRow $win $sourceKey end]
    set data(sourceDescCount) [descCount $win $sourceKey]

    set data(sourceParentKey) $data($sourceKey-parent)
    set data(sourceParentRow) [keyToRow $win $data(sourceParentKey)]
    set data(sourceParentEndRow) [nodeRow $win $data(sourceParentKey) end]

    set topWin [winfo toplevel $win]
    set data(topEscBinding) [bind $topWin <Escape>]
    bind $topWin <Escape> [list tablelist::cancelMove [strMap {"%" "%%"} $win]]
}

#------------------------------------------------------------------------------
# tablelist::beginSelect
#
# This procedure is typically invoked on button-1 presses in the body of a
# tablelist widget or in one of its separators.  It begins the process of
# making a selection in the widget.  Its exact behavior depends on the
# selection mode currently in effect for the widget.
#------------------------------------------------------------------------------
proc tablelist::beginSelect {win row col {checkIfDragSrc 0}} {
    variable priv
    set priv(selClearPending) 0
    set priv(selChangePending) 0

    upvar ::tablelist::ns${win}::data data
    switch $data(-selecttype) {
	row {
	    if {[string compare $data(-selectmode) "multiple"] == 0} {
		if {[::$win selection includes $row]} {
		    if {$checkIfDragSrc && [isDragSrc $win]} {
			set priv(selClearPending) 1
		    } else {
			::$win selection clear $row
		    }
		} else {
		    ::$win selection set $row
		}
	    } else {
		if {[::$win selection includes $row] &&
		    $checkIfDragSrc && [isDragSrc $win]} {
		    set priv(selChangePending) 1
		} else {
		    ::$win selection clear 0 end
		    ::$win selection set $row
		}
		::$win selection anchor $row
		set priv(selection) {}
	    }

	    set priv(prevRow) $row
	}

	cell {
	    if {[string compare $data(-selectmode) "multiple"] == 0} {
		if {[::$win cellselection includes $row,$col]} {
		    if {$checkIfDragSrc && [isDragSrc $win]} {
			set priv(selClearPending) 1
		    } else {
			::$win cellselection clear $row,$col
		    }
		} else {
		    ::$win cellselection set $row,$col
		}
	    } else {
		if {[::$win cellselection includes $row,$col] &&
		    $checkIfDragSrc && [isDragSrc $win]} {
		    set priv(selChangePending) 1
		} else {
		    ::$win cellselection clear 0,0 end
		    ::$win cellselection set $row,$col
		}
		::$win cellselection anchor $row,$col
		set priv(selection) {}
	    }

	    set priv(prevRow) $row
	    set priv(prevCol) $col
	}
    }

    event generate $win <<TablelistSelect>>
}

#------------------------------------------------------------------------------
# tablelist::condAutoScan
#
# This procedure is invoked when the mouse leaves or enters the scrollable part
# of a tablelist widget's body text child while button 1 is down.  It either
# invokes the autoScan procedure or cancels its executon as an "after" command.
#------------------------------------------------------------------------------
proc tablelist::condAutoScan win {
    variable priv
    set w [::$win bodypath]
    set wX [winfo x $w]
    set wY [winfo y $w]
    set wWidth  [winfo width  $w]
    set wHeight [winfo height $w]
    set x [expr {$priv(x) - $wX}]
    set y [expr {$priv(y) - $wY}]
    set prevX [expr {$priv(prevX) - $wX}]
    set prevY [expr {$priv(prevY) - $wY}]
    set minX [minScrollableX $win]

    if {($y >= $wHeight && $prevY < $wHeight) ||
	($y < 0 && $prevY >= 0) ||
	($x >= $wWidth && $prevX < $wWidth) ||
	($x < $minX && $prevX >= $minX)} {
	if {[string length $priv(afterId)] == 0} {
	    autoScan $win
	}
    } elseif {($y < $wHeight && $prevY >= $wHeight) ||
	      ($y >= 0 && $prevY < 0) ||
	      ($x < $wWidth && $prevX >= $wWidth) ||
	      ($x >= $minX && $prevX < $minX)} {
	after cancel $priv(afterId)
	set priv(afterId) ""
    }
}

#------------------------------------------------------------------------------
# tablelist::autoScan
#
# This procedure is invoked when the mouse leaves the scrollable part of a
# tablelist widget's body text child while button 1 is down.  It scrolls the
# child up, down, left, or right, depending on where the mouse left the
# scrollable part of the tablelist's body, and reschedules itself as an "after"
# command so that the child continues to scroll until the mouse moves back into
# the window or the mouse button is released.
#------------------------------------------------------------------------------
proc tablelist::autoScan win {
    if {![array exists ::tablelist::ns${win}::data] || [isDragSrc $win] ||
	[string length [::$win editwinpath]] != 0} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    if {!$data(-autoscan)} {
	return ""
    }

    variable priv
    set w [::$win bodypath]
    set x [expr {$priv(x) - [winfo x $w]}]
    set y [expr {$priv(y) - [winfo y $w]}]
    set minX [minScrollableX $win]

    if {$y >= [winfo height $w]} {
	::$win yview scroll 1 units
	set ms 50
    } elseif {$y < 0} {
	::$win yview scroll -1 units
	set ms 50
    } elseif {$x >= [winfo width $w]} {
	if {$data(-titlecolumns) == 0} {
	    ::$win xview scroll 2 units
	    set ms 50
	} else {
	    ::$win xview scroll 1 units
	    set ms 250
	}
    } elseif {$x < $minX} {
	if {$data(-titlecolumns) == 0} {
	    ::$win xview scroll -2 units
	    set ms 50
	} else {
	    ::$win xview scroll -1 units
	    set ms 250
	}
    } else {
	return ""
    }

    motion $win [::$win nearest $priv(y)] [::$win nearestcolumn $priv(x)] 1
    if {[string length $tablelist::priv(x)] != 0 &&
	[string length $tablelist::priv(y)] != 0} {
	set priv(afterId) [after $ms [list tablelist::autoScan $win]]
    }
}

#------------------------------------------------------------------------------
# tablelist::minScrollableX
#
# Returns the least x coordinate within the scrollable part of the body of the
# tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::minScrollableX win {
    upvar ::tablelist::ns${win}::data data
    if {$data(-titlecolumns) == 0} {
	return 0
    } else {
	set sep [::$win separatorpath]
	if {[winfo viewable $sep]} {
	    return [expr {[winfo x $sep] - [winfo x [::$win bodypath]] + 1}]
	} else {
	    return 0
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::motion
#
# This procedure is called to process mouse motion events in the body of a
# tablelist widget or in one of its separators. while button 1 is down.  It may
# move or extend the selection, depending on the widget's selection mode.
#------------------------------------------------------------------------------
proc tablelist::motion {win row col {checkIfDragSrc 0}} {
    if {$checkIfDragSrc && [isDragSrc $win]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    variable priv
    switch $data(-selecttype) {
	row {
	    set prRow $priv(prevRow)
	    if {$row == $prRow} {
		return ""
	    }

	    switch -- $data(-selectmode) {
		browse {
		    ::$win selection clear 0 end
		    ::$win selection set $row
		    set priv(prevRow) $row
		    event generate $win <<TablelistSelect>>
		}
		extended {
		    if {[string length $prRow] == 0} {
			set prRow $row
			::$win selection set $row
		    }

		    if {[::$win selection includes anchor]} {
			::$win selection clear $prRow $row
			::$win selection set anchor $row
		    } else {
			::$win selection clear $prRow $row
			::$win selection clear anchor $row
		    }

		    set ancRow $data(anchorRow)
		    foreach r $priv(selection) {
			if {($r >= $prRow && $r < $row && $r < $ancRow) ||
			    ($r <= $prRow && $r > $row && $r > $ancRow)} {
			    ::$win selection set $r
			}
		    }

		    set priv(prevRow) $row
		    event generate $win <<TablelistSelect>>
		}
	    }
	}

	cell {
	    set prRow $priv(prevRow)
	    set prCol $priv(prevCol)
	    if {$row == $prRow && $col == $prCol} {
		return ""
	    }

	    switch -- $data(-selectmode) {
		browse {
		    ::$win cellselection clear 0,0 end
		    ::$win cellselection set $row,$col
		    set priv(prevRow) $row
		    set priv(prevCol) $col
		    event generate $win <<TablelistSelect>>
		}
		extended {
		    if {[string length $prRow] == 0 ||
			[string length $prCol] == 0} {
			set prRow $row
			set prcol $col
			::$win cellselection set $row,$col
		    }

		    set ancRow $data(anchorRow)
		    set ancCol $data(anchorCol)
		    if {[::$win cellselection includes anchor]} {
			::$win cellselection clear $prRow,$prCol $row,$ancCol
			::$win cellselection clear $prRow,$prCol $ancRow,$col
			::$win cellselection set anchor $row,$col
		    } else {
			::$win cellselection clear $prRow,$prCol $row,$ancCol
			::$win cellselection clear $prRow,$prCol $ancRow,$col
			::$win cellselection clear anchor $row,$col
		    }

		    foreach {rMin1 cMin1 rMax1 cMax1} \
			[normalizedRect $prRow $prCol $row $ancCol] {}
		    foreach {rMin2 cMin2 rMax2 cMax2} \
			[normalizedRect $prRow $prCol $ancRow $col] {}
		    foreach {rMin3 cMin3 rMax3 cMax3} \
			[normalizedRect $ancRow $ancCol $row $col] {}
		    foreach cellIdx $priv(selection) {
			scan $cellIdx "%d,%d" r c
			if {([cellInRect $r $c $rMin1 $cMin1 $rMax1 $cMax1] ||
			     [cellInRect $r $c $rMin2 $cMin2 $rMax2 $cMax2]) &&
			    ![cellInRect $r $c $rMin3 $cMin3 $rMax3 $cMax3]} {
			    ::$win cellselection set $r,$c
			}
		    }

		    set priv(prevRow) $row
		    set priv(prevCol) $col
		    event generate $win <<TablelistSelect>>
		}
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::condShowTarget
#
# This procedure is called to process mouse motion events in the body of a
# tablelist widget or in one of its separators. while button 1 is down.  It
# visualizes the would-be target position of the clicked row if a move
# operation is in progress.
#------------------------------------------------------------------------------
proc tablelist::condShowTarget {win y} {
    upvar ::tablelist::ns${win}::data data
    if {![info exists data(sourceRow)]} {
	return ""
    }

    set indentImg [doCellCget $data(sourceRow) $data(treeCol) $win -indent]
    set w $data(body)
    incr y -[winfo y $w]
    set textIdx [$w index @0,$y]
    set dlineinfo [$w dlineinfo $textIdx]
    set lineY [lindex $dlineinfo 1]
    set lineHeight [lindex $dlineinfo 3]
    set row [expr {int($textIdx) - 1}]

    if {$::tk_version < 8.3 || [string length $indentImg] == 0} {
	if {$y < $lineY + $lineHeight/2} {
	    set data(targetRow) $row
	    set gapY $lineY
	} else {
	    set y [expr {$lineY + $lineHeight}]
	    set textIdx [$w index @0,$y]
	    set row2 [expr {int($textIdx) - 1}]
	    if {$row2 == $row} {
		set row2 $data(itemCount)
	    }
	    set data(targetRow) $row2
	    set gapY $y
	}
	set data(targetChildIdx) -1
    } else {
	if {$y < $lineY + $lineHeight/4} {
	    set data(targetRow) $row
	    set data(targetChildIdx) -1
	    set gapY $lineY
	} elseif {$y < $lineY + $lineHeight*3/4} {
	    set data(targetRow) $row
	    set data(targetChildIdx) 0
	    set gapY [expr {$lineY + $lineHeight/2}]
	} else {
	    set y [expr {$lineY + $lineHeight}]
	    set textIdx [$w index @0,$y]
	    set row2 [expr {int($textIdx) - 1}]
	    if {$row2 == $row} {
		set row2 $data(itemCount)
	    }
	    set data(targetRow) $row2
	    set data(targetChildIdx) -1
	    set gapY $y
	}
    }

    #
    # Get the key and node index of the potential target parent
    #
    if {$data(targetRow) > $data(lastRow)} {
	if {$data(targetRow) > $data(sourceParentEndRow)} {
	    set targetParentKey root
	    set targetParentNodeIdx root
	} else {
	    set targetParentKey $data(sourceParentKey)
	    set targetParentNodeIdx $data(sourceParentRow)
	}
    } elseif {$data(targetChildIdx) == 0} {
	set targetParentKey [lindex $data(keyList) $data(targetRow)]
	set targetParentNodeIdx $data(targetRow)
    } else {
	set targetParentKey [::$win parentkey $data(targetRow)]
	set targetParentNodeIdx [keyToRow $win $targetParentKey]
	if {$targetParentNodeIdx < 0} {
	    set targetParentNodeIdx root
	}
    }

    if {($data(targetRow) == $data(sourceRow)) ||

	($data(targetRow) == $data(sourceParentRow) &&
	 $data(targetChildIdx) == 0) ||

	($data(targetRow) == $data(sourceEndRow) &&
	 $data(targetChildIdx) < 0) ||

	($data(targetRow) > $data(sourceRow) &&
	 $data(targetRow) <= $data(sourceRow) + $data(sourceDescCount)) ||

	([string compare $data(sourceParentKey) $targetParentKey] != 0 &&
	 ($::tk_version < 8.3 ||
	  ([string length $data(-acceptchildcommand)] != 0 &&
	   ![uplevel #0 $data(-acceptchildcommand) \
	     [list $win $targetParentNodeIdx $data(sourceRow)]]))) ||

	($data(targetChildIdx) < 0 &&
	 [string length $data(-acceptdropcommand)] != 0 &&
	 ![uplevel #0 $data(-acceptdropcommand) \
	   [list $win $data(targetRow) $data(sourceRow)]])} {

	unset data(targetRow)
	unset data(targetChildIdx)
	$w configure -cursor $data(-cursor)
	place forget $data(rowGap)
    } else {
	$w configure -cursor $data(-movecursor)
	if {$data(targetChildIdx) == 0} {
	    place $data(rowGap) -anchor w -y $gapY -height $lineHeight -width 6
	} else {
	    place $data(rowGap) -anchor w -y $gapY -height 4 \
				-width [winfo width $data(hdrTxtFrm)]
	}
	raise $data(rowGap)
    }
}

#------------------------------------------------------------------------------
# tablelist::moveOrActivate
#
# This procedure is invoked whenever mouse button 1 is released in the body of
# a tablelist widget or in one of its separators.  It either moves the
# previously clicked row before or after the one containing the mouse cursor,
# or activates the given nearest item or element (depending on the widget's
# selection type).
#------------------------------------------------------------------------------
proc tablelist::moveOrActivate {win row col inside} {
    variable priv
    upvar ::tablelist::ns${win}::data data
    if {$priv(selClearPending) && $inside} {
	switch $data(-selecttype) {
	    row {
		if {$row == $priv(prevRow)} {
		    ::$win selection clear $priv(prevRow)
		}
	    }
	    cell {
		if {$row == $priv(prevRow) && $col == $priv(prevCol)} {
		    ::$win cellselection clear $priv(prevRow),$priv(prevCol)
		}
	    }
	}

	event generate $win <<TablelistSelect>>
	set priv(selClearPending) 0
    } elseif {$priv(selChangePending) && $inside} {
	switch $data(-selecttype) {
	    row {
		if {$row == $priv(prevRow)} {
		    ::$win selection clear 0 end
		    ::$win selection set $priv(prevRow)
		}
	    }
	    cell {
		if {$row == $priv(prevRow) && $col == $priv(prevCol)} {
		    ::$win cellselection clear 0,0 end
		    ::$win cellselection set $priv(prevRow),$priv(prevCol)
		}
	    }
	}

	event generate $win <<TablelistSelect>>
	set priv(selChangePending) 0
    }

    #
    # Return if both <Button-1> and <ButtonRelease-1> occurred in the
    # temporary embedded widget used for interactive cell editing
    #
    if {$priv(clickedInEditWin) && $priv(releasedInEditWin)} {
	return ""
    }

    if {[info exists data(sourceRow)]} {
	set sourceRow $data(sourceRow)
	unset data(sourceRow)
	unset data(sourceEndRow)
	unset data(sourceDescCount)
	unset data(sourceParentKey)
	unset data(sourceParentRow)
	unset data(sourceParentEndRow)
	bind [winfo toplevel $win] <Escape> $data(topEscBinding)
	$data(body) configure -cursor $data(-cursor)
	place forget $data(rowGap)

	if {[info exists data(targetRow)]} {
	    set sourceKey [lindex $data(keyList) $sourceRow]
	    set targetRow $data(targetRow)
	    unset data(targetRow)

	    if {$targetRow > $data(lastRow)} {
		if {[catch {::$win move $sourceRow $targetRow}] == 0} {
		    set targetParentNodeIdx [::$win parentkey $sourceRow]
		} else {
		    ::$win move $sourceRow root end
		    set targetParentNodeIdx root
		}

		set targetChildIdx [::$win childcount $targetParentNodeIdx]
	    } else {
		set targetChildIdx $data(targetChildIdx)
		unset data(targetChildIdx)

		if {$targetChildIdx == 0} {
		    set targetParentNodeIdx [lindex $data(keyList) $targetRow]
		    ::$win expand $targetParentNodeIdx -partly
		    ::$win move $sourceKey $targetParentNodeIdx $targetChildIdx
		} else {
		    set targetParentNodeIdx [::$win parentkey $targetRow]
		    set targetChildIdx [::$win childindex $targetRow]
		    ::$win move $sourceRow $targetParentNodeIdx $targetChildIdx
		}
	    }

	    set userData [list $sourceKey $targetParentNodeIdx $targetChildIdx]
	    genVirtualEvent $win <<TablelistRowMoved>> $userData

	    switch $data(-selecttype) {
		row  { ::$win activate $sourceKey }
		cell { ::$win activatecell $sourceKey,$col }
	    }

	    return ""
	}
    }

    switch $data(-selecttype) {
	row  { ::$win activate $row }
	cell { ::$win activatecell $row,$col }
    }
}

#------------------------------------------------------------------------------
# tablelist::condEvalInvokeCmd
#
# This procedure is invoked when mouse button 1 is released in the body of a
# tablelist widget win or in one of its separators.  If interactive cell
# editing is in progress in a column whose associated edit window has an invoke
# command that hasn't yet been called in the current edit session, then the
# procedure evaluates that command.
#------------------------------------------------------------------------------
proc tablelist::condEvalInvokeCmd win {
    #
    # This is an "after 100" callback; check whether the window exists
    #
    if {![array exists ::tablelist::ns${win}::data]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    if {$data(editCol) < 0} {
	return ""
    }

    variable editWin
    set name [getEditWindow $win $data(editRow) $data(editCol)]
    if {[string length $editWin($name-invokeCmd)] == 0 || $data(invoked)} {
	return ""
    }

    #
    # Return if both <Button-1> and <ButtonRelease-1> occurred in the
    # temporary embedded widget used for interactive cell editing
    #
    variable priv
    if {$priv(clickedInEditWin) && $priv(releasedInEditWin)} {
	return ""
    }

    #
    # Check whether the edit window is a checkbutton,
    # and return if it is an editable combobox widget
    #
    set isCheckbtn 0
    set w $data(bodyFrmEd)
    switch [winfo class $w] {
	Checkbutton -
	TCheckbutton {
	    set isCheckbtn 1
	}
	TCombobox {
	    if {[string compare [$w cget -state] "normal"] == 0} {
		return ""
	    }
	}
	ComboBox -
	Combobox {
	    if {[$w cget -editable]} {
		return ""
	    }
	}
    }

    #
    # Evaluate the edit window's invoke command
    #
    eval [strMap {"%W" "$w"} $editWin($name-invokeCmd)]
    set data(invoked) 1

    #
    # If the edit window is a checkbutton and the value of the
    # -instanttoggle option is true then finish the editing
    #
    if {$isCheckbtn && $data(-instanttoggle)} {
	doFinishEditing $win
    }
}

#------------------------------------------------------------------------------
# tablelist::cancelMove
#
# This procedure is invoked to process <Escape> events in the top-level window
# containing the tablelist widget win during a row move operation.  It cancels
# the action in progress.
#------------------------------------------------------------------------------
proc tablelist::cancelMove win {
    upvar ::tablelist::ns${win}::data data
    if {![info exists data(sourceRow)]} {
	return ""
    }

    unset data(sourceRow)
    unset data(sourceEndRow)
    unset data(sourceDescCount)
    unset data(sourceParentKey)
    unset data(sourceParentRow)
    unset data(sourceParentEndRow)
    if {[info exists data(targetRow)]} {
	unset data(targetRow)
    }
    if {[info exists data(targetChildIdx)]} {
	unset data(targetChildIdx)
    }
    bind [winfo toplevel $win] <Escape> $data(topEscBinding)
    $data(body) configure -cursor $data(-cursor)
    place forget $data(rowGap)
}

#------------------------------------------------------------------------------
# tablelist::beginExtend
#
# This procedure is typically invoked on shift-button-1 presses in the body of
# a tablelist widget or in one of its separators.  It begins the process of
# extending a selection in the widget.  Its exact behavior depends on the
# selection mode currently in effect for the widget.
#------------------------------------------------------------------------------
proc tablelist::beginExtend {win row col} {
    if {[string compare [::$win cget -selectmode] "extended"] != 0} {
	return ""
    }

    if {[::$win selection includes anchor]} {
	motion $win $row $col
    } else {
	beginSelect $win $row $col
    }
}

#------------------------------------------------------------------------------
# tablelist::beginToggle
#
# This procedure is typically invoked on control-button-1 presses in the body
# of a tablelist widget or in one of its separators.  It begins the process of
# toggling a selection in the widget.  Its exact behavior depends on the
# selection mode currently in effect for the widget.
#------------------------------------------------------------------------------
proc tablelist::beginToggle {win row col} {
    upvar ::tablelist::ns${win}::data data
    switch $data(-selecttype) {
	row {
	    if {[string compare $data(-selectmode) "extended"] == 0} {
		variable priv
		set priv(selection) [::$win curselection]
		set priv(prevRow) $row
		::$win selection anchor $row
		if {[::$win selection includes $row]} {
		    ::$win selection clear $row
		} else {
		    ::$win selection set $row
		}
	    } else {
		variable strictTk
		if {$strictTk} {
		    return ""
		}

		if {[::$win selection includes $row]} {
		    ::$win selection clear $row
		} else {
		    beginSelect $win $row $col
		    return ""
		}
	    }
	}

	cell {
	    if {[string compare $data(-selectmode) "extended"] == 0} {
		variable priv
		set priv(selection) [::$win curcellselection]
		set priv(prevRow) $row
		set priv(prevCol) $col
		::$win cellselection anchor $row,$col
		if {[::$win cellselection includes $row,$col]} {
		    ::$win cellselection clear $row,$col
		} else {
		    ::$win cellselection set $row,$col
		}
	    } else {
		variable strictTk
		if {$strictTk} {
		    return ""
		}

		if {[::$win cellselection includes $row,$col]} {
		    ::$win cellselection clear $row,$col
		} else {
		    beginSelect $win $row $col
		    return ""
		}
	    }
	}
    }

    event generate $win <<TablelistSelect>>
}

#------------------------------------------------------------------------------
# tablelist::condEditActiveCell
#
# This procedure is invoked whenever Return or KP_Enter is pressed in the body
# of a tablelist widget.  If the selection type is cell and the active cell is
# editable then the procedure starts the interactive editing in that cell.
#------------------------------------------------------------------------------
proc tablelist::condEditActiveCell win {
    upvar ::tablelist::ns${win}::data data
    if {[string compare $data(-selecttype) "cell"] != 0 ||
	[firstViewableRow $win] < 0 || [firstViewableCol $win] < 0} {
	return ""
    }

    set row $data(activeRow)
    set col $data(activeCol)
    if {[isCellEditable $win $row $col]} {
	doEditCell $win $row $col 0
    }
}

#------------------------------------------------------------------------------
# tablelist::plusMinus
#
# Partially expands or collapses the active row if possible.
#------------------------------------------------------------------------------
proc tablelist::plusMinus {win keysym} {
    upvar ::tablelist::ns${win}::data data
    set row $data(activeRow)
    set col $data(treeCol)
    set key [lindex $data(keyList) $row]
    set op ""

    if {[info exists data($key,$col-indent)]} {
	set indentLabel $data(body).ind_$key,$col
	set imgName [$indentLabel cget -image]
	if {[regexp {^tablelist_(.+)_(collapsed|expanded).*Img([0-9]+)$} \
		     $imgName dummy treeStyle mode depth]} {
	    if {[string compare $keysym "plus"] == 0 &&
		[string compare $mode "collapsed"] == 0} {
		set op "expand"
	    } elseif {[string compare $keysym "minus"] == 0 &&
		      [string compare $mode "expanded"] == 0} {
		set op "collapse"
	    }
	}
    }

    if {[string length $op] != 0} {
	#
	# Toggle the state of the expand/collapse control
	#
	::$win $op $row -partly

	updateViewWhenIdle $win
    }
}

#------------------------------------------------------------------------------
# tablelist::nextPrevCell
#
# Does nothing unless the selection type is cell; in this case it moves the
# location cursor (active element) to the next or previous element, and changes
# the selection if we are in browse or extended selection mode.
#------------------------------------------------------------------------------
proc tablelist::nextPrevCell {win amount} {
    upvar ::tablelist::ns${win}::data data
    switch $data(-selecttype) {
	row {
	    # Nothing
	}

	cell {
	    if {$data(editRow) >= 0} {
		return -code break ""
	    }

	    set row $data(activeRow)
	    set col $data(activeCol)
	    set oldRow $row
	    set oldCol $col

	    while 1 {
		incr col $amount
		if {$col < 0} {
		    incr row $amount
		    if {$row < 0} {
			set row $data(lastRow)
		    }
		    set col $data(lastCol)
		} elseif {$col > $data(lastCol)} {
		    incr row $amount
		    if {$row > $data(lastRow)} {
			set row 0
		    }
		    set col 0
		}

		if {$row == $oldRow && $col == $oldCol} {
		    return -code break ""
		} elseif {[isRowViewable $win $row] && !$data($col-hide)} {
		    condChangeSelection $win $row $col
		    return -code break ""
		}
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::upDown
#
# Moves the location cursor (active item or element) up or down by one line,
# and changes the selection if we are in browse or extended selection mode.
#------------------------------------------------------------------------------
proc tablelist::upDown {win amount} {
    upvar ::tablelist::ns${win}::data data
    if {$data(editRow) >= 0} {
	return ""
    }

    switch $data(-selecttype) {
	row {
	    set row $data(activeRow)
	    set col -1
	}

	cell {
	    set row $data(activeRow)
	    set col $data(activeCol)
	}
    }

    while 1 {
	incr row $amount
	if {$row < 0 || $row > $data(lastRow)} {
	    return ""
	} elseif {[isRowViewable $win $row]} {
	    condChangeSelection $win $row $col
	    return ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::leftRight
#
# Partially expands or collapses the active row if possible.  Otherwise, if the
# tablelist widget's selection type is "row" then this procedure scrolls the
# widget's view left or right by the width of the character "0".  Otherwise it
# moves the location cursor (active element) left or right by one column, and
# changes the selection if we are in browse or extended selection mode.
#------------------------------------------------------------------------------
proc tablelist::leftRight {win amount} {
    upvar ::tablelist::ns${win}::data data
    set row $data(activeRow)
    set col $data(treeCol)
    set key [lindex $data(keyList) $row]
    set op ""

    if {[info exists data($key,$col-indent)]} {
	set indentLabel $data(body).ind_$key,$col
	set imgName [$indentLabel cget -image]
	if {[regexp {^tablelist_(.+)_(collapsed|expanded).*Img([0-9]+)$} \
		     $imgName dummy treeStyle mode depth]} {
	    if {$amount > 0 && [string compare $mode "collapsed"] == 0} {
		set op "expand"
	    } elseif {$amount < 0 && [string compare $mode "expanded"] == 0} {
		set op "collapse"
	    }
	}
    }

    if {[string length $op] == 0} {
	switch $data(-selecttype) {
	    row {
		::$win xview scroll $amount units
	    }

	    cell {
		if {$data(editRow) >= 0} {
		    return ""
		}

		set col $data(activeCol)
		while 1 {
		    incr col $amount
		    if {$col < 0 || $col > $data(lastCol)} {
			return ""
		    } elseif {!$data($col-hide)} {
			condChangeSelection $win $row $col
			return ""
		    }
		}
	    }
	}
    } else {
	#
	# Toggle the state of the expand/collapse control
	#
	::$win $op $row -partly

	updateViewWhenIdle $win
    }
}

#------------------------------------------------------------------------------
# tablelist::priorNext
#
# Scrolls the tablelist view up or down by one page.
#------------------------------------------------------------------------------
proc tablelist::priorNext {win amount} {
    upvar ::tablelist::ns${win}::data data
    if {$data(editRow) >= 0} {
	return ""
    }

    ::$win yview scroll $amount pages
    ::$win activate @0,0
    update idletasks
}

#------------------------------------------------------------------------------
# tablelist::homeEnd
#
# If selecttype is row then the procedure scrolls the tablelist widget
# horizontally to its left or right edge.  Otherwise it sets the location
# cursor (active element) to the first/last element of the active row, selects
# that element, and deselects everything else in the widget.
#------------------------------------------------------------------------------
proc tablelist::homeEnd {win keysym} {
    upvar ::tablelist::ns${win}::data data
    switch $data(-selecttype) {
	row {
	    switch $keysym {
		Home { ::$win xview moveto 0 }
		End  { ::$win xview moveto 1 }
	    }
	}

	cell {
	    set row $data(activeRow)
	    switch $keysym {
		Home { set col [firstViewableCol $win] }
		End  { set col [ lastViewableCol $win] }
	    }
	    changeSelection $win $row $col
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::firstLast
#
# Sets the location cursor (active item or element) to the first/last item or
# element in the tablelist widget, selects that item or element, and deselects
# everything else in the widget.
#------------------------------------------------------------------------------
proc tablelist::firstLast {win target} {
    switch $target {
	first {
	    set row [firstViewableRow $win]
	    set col [firstViewableCol $win]
	}

	last {
	    set row [lastViewableRow $win]
	    set col [lastViewableCol $win]
	}
    }

    changeSelection $win $row $col
}

#------------------------------------------------------------------------------
# tablelist::extendUpDown
#
# Does nothing unless we are in extended selection mode; in this case it moves
# the location cursor (active item or element) up or down by one line, and
# extends the selection to that point.
#------------------------------------------------------------------------------
proc tablelist::extendUpDown {win amount} {
    upvar ::tablelist::ns${win}::data data
    if {[string compare $data(-selectmode) "extended"] != 0} {
	return ""
    }

    switch $data(-selecttype) {
	row {
	    set row $data(activeRow)
	    while 1 {
		incr row $amount
		if {$row < 0 || $row > $data(lastRow)} {
		    return ""
		} elseif {[isRowViewable $win $row]} {
		    ::$win activate $row
		    ::$win see active
		    motion $win $data(activeRow) -1
		    return ""
		}
	    }
	}

	cell {
	    set row $data(activeRow)
	    set col $data(activeCol)
	    while 1 {
		incr row $amount
		if {$row < 0 || $row > $data(lastRow)} {
		    return ""
		} elseif {[isRowViewable $win $row]} {
		    ::$win activatecell $row,$col
		    ::$win seecell active
		    motion $win $data(activeRow) $data(activeCol)
		    return ""
		}
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::extendLeftRight
#
# Does nothing unless we are in extended selection mode and the selection type
# is cell; in this case it moves the location cursor (active element) left or
# right by one column, and extends the selection to that point.
#------------------------------------------------------------------------------
proc tablelist::extendLeftRight {win amount} {
    upvar ::tablelist::ns${win}::data data
    if {[string compare $data(-selectmode) "extended"] != 0} {
	return ""
    }

    switch $data(-selecttype) {
	row {
	    # Nothing
	}

	cell {
	    set row $data(activeRow)
	    set col $data(activeCol)
	    while 1 {
		incr col $amount
		if {$col < 0 || $col > $data(lastCol)} {
		    return ""
		} elseif {!$data($col-hide)} {
		    ::$win activatecell $row,$col
		    ::$win seecell active
		    motion $win $data(activeRow) $data(activeCol)
		    return ""
		}
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::extendToHomeEnd
#
# Does nothing unless the selection mode is multiple or extended and the
# selection type is cell; in this case it moves the location cursor (active
# element) to the first/last element of the active row, and, if we are in
# extended mode, it extends the selection to that point.
#------------------------------------------------------------------------------
proc tablelist::extendToHomeEnd {win keysym} {
    upvar ::tablelist::ns${win}::data data
    switch $data(-selecttype) {
	row {
	    # Nothing
	}

	cell {
	    set row $data(activeRow)
	    switch $keysym {
		Home { set col [firstViewableCol $win] }
		End  { set col [ lastViewableCol $win] }
	    }

	    switch -- $data(-selectmode) {
		multiple {
		    ::$win activatecell $row,$col
		    ::$win seecell $row,$col
		}
		extended {
		    ::$win activatecell $row,$col
		    ::$win seecell $row,$col
		    if {[::$win selection includes anchor]} {
			motion $win $row $col
		    }
		}
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::extendToFirstLast
#
# Does nothing unless the selection mode is multiple or extended; in this case
# it moves the location cursor (active item or element) to the first/last item
# or element in the tablelist widget, and, if we are in extended mode, it
# extends the selection to that point.
#------------------------------------------------------------------------------
proc tablelist::extendToFirstLast {win target} {
    switch $target {
	first {
	    set row [firstViewableRow $win]
	    set col [firstViewableCol $win]
	}

	last {
	    set row [lastViewableRow $win]
	    set col [lastViewableCol $win]
	}
    }

    upvar ::tablelist::ns${win}::data data
    switch $data(-selecttype) {
	row {
	    switch -- $data(-selectmode) {
		multiple {
		    ::$win activate $row
		    ::$win see $row
		}
		extended {
		    ::$win activate $row
		    ::$win see $row
		    if {[::$win selection includes anchor]} {
			motion $win $row -1
		    }
		}
	    }
	}

	cell {
	    switch -- $data(-selectmode) {
		multiple {
		    ::$win activatecell $row,$col
		    ::$win seecell $row,$col
		}
		extended {
		    ::$win activatecell $row,$col
		    ::$win seecell $row,$col
		    if {[::$win selection includes anchor]} {
			motion $win $row $col
		    }
		}
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::cancelSelection
#
# This procedure is invoked to cancel an extended selection in progress.  If
# there is an extended selection in progress, it restores all of the elements
# to their previous selection state.
#------------------------------------------------------------------------------
proc tablelist::cancelSelection win {
    upvar ::tablelist::ns${win}::data data
    if {[string compare $data(-selectmode) "extended"] != 0} {
	return ""
    }

    variable priv
    switch $data(-selecttype) {
	row {
	    if {[string length $priv(prevRow)] == 0} {
		return ""
	    }

	    ::$win selection clear 0 end
	    foreach row $priv(selection) {
		::$win selection set $row
	    }
	    event generate $win <<TablelistSelect>>
	}

	cell {
	    if {[string length $priv(prevRow)] == 0 ||
		[string length $priv(prevCol)] == 0} {
		return ""
	    }

	    ::$win selection clear 0 end
	    foreach cellIdx $priv(selection) {
		::$win cellselection set $cellIdx
	    }
	    event generate $win <<TablelistSelect>>
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::selectAll
#
# This procedure is invoked to handle the "select all" operation.  For single
# and browse mode, it just selects the active item or element.  Otherwise it
# selects everything in the widget.
#------------------------------------------------------------------------------
proc tablelist::selectAll win {
    upvar ::tablelist::ns${win}::data data
    switch $data(-selecttype) {
	row {
	    if {[string compare $data(-selectmode) "single"] == 0 ||
		[string compare $data(-selectmode) "browse"] == 0} {
		::$win selection clear 0 end
		::$win selection set active
	    } else {
		::$win selection set 0 end
	    }
	}

	cell {
	    if {[string compare $data(-selectmode) "single"] == 0 ||
		[string compare $data(-selectmode) "browse"] == 0} {
		::$win cellselection clear 0,0 end
		::$win cellselection set active
	    } else {
		::$win cellselection set 0,0 end
	    }
	}
    }

    event generate $win <<TablelistSelect>>
}

#------------------------------------------------------------------------------
# tablelist::isDragSrc
#
# Checks whether the body component of the tablelist widget win is a BWidget or
# TkDND drag source for mouse button 1.
#------------------------------------------------------------------------------
proc tablelist::isDragSrc win {
    upvar ::tablelist::ns${win}::data data
    set bindTags [bindtags $data(body)]
    return [expr {[info exists data(sourceRow)] || $data(-customdragsource) ||
		  [lsearch -exact $bindTags "BwDrag1"] >= 0 ||
		  [lsearch -exact $bindTags "TkDND_Drag1"] >= 0
    }]
}

#------------------------------------------------------------------------------
# tablelist::normalizedRect
#
# Returns a list of the form {minRow minCol maxRow maxCol}, built from the
# given arguments.
#------------------------------------------------------------------------------
proc tablelist::normalizedRect {row1 col1 row2 col2} {
    if {$row1 <= $row2} {
	set minRow $row1
	set maxRow $row2
    } else {
	set minRow $row2
	set maxRow $row1
    }

    if {$col1 <= $col2} {
	set minCol $col1
	set maxCol $col2
    } else {
	set minCol $col2
	set maxCol $col1
    }

    return [list $minRow $minCol $maxRow $maxCol]
}

#------------------------------------------------------------------------------
# tablelist::cellInRect
#
# Checks whether the cell row,col is contained in the given rectangular range.
#------------------------------------------------------------------------------
proc tablelist::cellInRect {row col minRow minCol maxRow maxCol} {
    return [expr {$row >= $minRow && $row <= $maxRow &&
		  $col >= $minCol && $col <= $maxCol}]
}

#------------------------------------------------------------------------------
# tablelist::firstViewableRow
#
# Returns the index of the first viewable row of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::firstViewableRow win {
    upvar ::tablelist::ns${win}::data data
    for {set row 0} {$row < $data(itemCount)} {incr row} {
	if {[isRowViewable $win $row]} {
	    return $row
	}
    }

    return -1
}

#------------------------------------------------------------------------------
# tablelist::lastViewableRow
#
# Returns the index of the last viewable row of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::lastViewableRow win {
    upvar ::tablelist::ns${win}::data data
    for {set row $data(lastRow)} {$row >= 0} {incr row -1} {
	if {[isRowViewable $win $row]} {
	    return $row
	}
    }

    return -1
}

#------------------------------------------------------------------------------
# tablelist::firstViewableCol
#
# Returns the index of the first non-hidden column of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::firstViewableCol win {
    upvar ::tablelist::ns${win}::data data
    for {set col 0} {$col < $data(colCount)} {incr col} {
	if {!$data($col-hide)} {
	    return $col
	}
    }

    return -1
}

#------------------------------------------------------------------------------
# tablelist::lastViewableCol
#
# Returns the index of the last non-hidden column of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::lastViewableCol win {
    upvar ::tablelist::ns${win}::data data
    for {set col $data(lastCol)} {$col >= 0} {incr col -1} {
	if {!$data($col-hide)} {
	    return $col
	}
    }

    return -1
}

#------------------------------------------------------------------------------
# tablelist::condChangeSelection
#
# Activates the given item or element, and selects it exclusively if we are in
# browse or extended selection mode.
#------------------------------------------------------------------------------
proc tablelist::condChangeSelection {win row col} {
    upvar ::tablelist::ns${win}::data data
    switch $data(-selecttype) {
	row {
	    ::$win activate $row
	    ::$win see active

	    switch -- $data(-selectmode) {
		browse {
		    ::$win selection clear 0 end
		    ::$win selection set active
		    event generate $win <<TablelistSelect>>
		}
		extended {
		    ::$win selection clear 0 end
		    ::$win selection set active
		    ::$win selection anchor active
		    variable priv
		    set priv(selection) {}
		    set priv(prevRow) $data(activeRow)
		    event generate $win <<TablelistSelect>>
		}
	    }
	}

	cell {
	    ::$win activatecell $row,$col
	    ::$win seecell active

	    switch -- $data(-selectmode) {
		browse {
		    ::$win cellselection clear 0,0 end
		    ::$win cellselection set active
		    event generate $win <<TablelistSelect>>
		}
		extended {
		    ::$win cellselection clear 0,0 end
		    ::$win cellselection set active
		    ::$win cellselection anchor active
		    variable priv
		    set priv(selection) {}
		    set priv(prevRow) $data(activeRow)
		    set priv(prevCol) $data(activeCol)
		    event generate $win <<TablelistSelect>>
		}
	    }
	}
    }

    update idletasks
}

#------------------------------------------------------------------------------
# tablelist::changeSelection
#
# Activates the given item or element and selects it exclusively.
#------------------------------------------------------------------------------
proc tablelist::changeSelection {win row col} {
    upvar ::tablelist::ns${win}::data data
    switch $data(-selecttype) {
	row {
	    ::$win activate $row
	    ::$win see active

	    ::$win selection clear 0 end
	    ::$win selection set active
	}

	cell {
	    ::$win activatecell $row,$col
	    ::$win seecell active

	    ::$win cellselection clear 0,0 end
	    ::$win cellselection set active
	}
    }

    event generate $win <<TablelistSelect>>
}

#
# Binding tags TablelistLabel, TablelistSubLabel, and TablelistArrow
# ==================================================================
#

#------------------------------------------------------------------------------
# tablelist::defineTablelistSubLabel
#
# Defines the binding tag TablelistSubLabel (for sublabels of tablelist labels)
# to have the same events as TablelistLabel and the binding scripts obtained
# from those of TablelistLabel by replacing the widget %W with the containing
# label as well as the %x and %y fields with the corresponding coordinates
# relative to that label.
#------------------------------------------------------------------------------
proc tablelist::defineTablelistSubLabel {} {
    foreach event [bind TablelistLabel] {
	set script [strMap {
	    "%W" "$tablelist::W"  "%x" "$tablelist::x"  "%y" "$tablelist::y"
	} [bind TablelistLabel $event]]

	bind TablelistSubLabel $event [format {
	    set tablelist::W \
		[string range %%W 0 [expr {[string length %%W] - 4}]]
	    set tablelist::x \
		[expr {%%x + [winfo x %%W] - [winfo x $tablelist::W]}]
	    set tablelist::y \
		[expr {%%y + [winfo y %%W] - [winfo y $tablelist::W]}]
	    %s
	} $script]
    }
}

#------------------------------------------------------------------------------
# tablelist::defineTablelistArrow
#
# Defines the binding tag TablelistArrow (for sort arrows) to have the same
# events as TablelistLabel and the binding scripts obtained from those of
# TablelistLabel by replacing the widget %W with the containing label as well
# as the %x and %y fields with the corresponding coordinates relative to that
# label.
#------------------------------------------------------------------------------
proc tablelist::defineTablelistArrow {} {
    foreach event [bind TablelistLabel] {
	set script [strMap {
	    "%W" "$tablelist::W"  "%x" "$tablelist::x"  "%y" "$tablelist::y"
	} [bind TablelistLabel $event]]

	bind TablelistArrow $event [format {
	    set tablelist::W \
		[winfo parent %%W].l[string range [winfo name %%W] 1 end]
	    set tablelist::x \
		[expr {%%x + [winfo x %%W] - [winfo x $tablelist::W]}]
	    set tablelist::y \
		[expr {%%y + [winfo y %%W] - [winfo y $tablelist::W]}]
	    %s
	} $script]
    }
}

#------------------------------------------------------------------------------
# tablelist::labelEnter
#
# This procedure is invoked when the mouse pointer enters the header label w of
# a tablelist widget, or is moving within that label.  It updates the cursor,
# displays the tooltip, and activates or deactivates the label, depending on
# whether the pointer is on its right border or not.
#------------------------------------------------------------------------------
proc tablelist::labelEnter {w X Y x} {
    if {![parseLabelPath $w win col]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    configLabel $w -cursor $data(-cursor)

    if {[string length $data(-tooltipaddcommand)] != 0 &&
	[string length $data(-tooltipdelcommand)] != 0 &&
	$col != $data(prevCol)} {
	#
	# Display the tooltip corresponding to this label
	#
	set data(prevCol) $col
	set focus [focus -displayof $win]
	if {[string length $focus] == 0 ||
	    [string first $win $focus] != 0 ||
	    [string compare [winfo toplevel $focus] \
	     [winfo toplevel $win]] == 0} {
	    uplevel #0 $data(-tooltipaddcommand) [list $win -1 $col]
	    event generate $win <Leave>
	    event generate $win <Enter> -rootx $X -rooty $Y
	}
    }

    if {$data(isDisabled)} {
	return ""
    }

    if {[inResizeArea $w $x col] &&
	$data(-resizablecolumns) && $data($col-resizable)} {
	configLabel $w -cursor $data(-resizecursor)
	configLabel $w -active 0
    } else {
	configLabel $w -active 1
    }
}

#------------------------------------------------------------------------------
# tablelist::labelLeave
#
# This procedure is invoked when the mouse pointer leaves the header label w of
# a tablelist widget.  It removes the tooltip and deactivates the label.
#------------------------------------------------------------------------------
proc tablelist::labelLeave {w X x y} {
    if {![parseLabelPath $w win col]} {
	return ""
    }

    #
    # The following code is needed because the event
    # can also occur in a widget placed into the label
    #
    upvar ::tablelist::ns${win}::data data
    set hdrX [winfo rootx $data(hdr)]
    if {$X >= $hdrX && $X < $hdrX + [winfo width $data(hdr)] &&
	$x >= 1 && $x < [winfo width $w] - 1 &&
	$y >= 0 && $y < [winfo height $w]} {
	return ""
    }

    if {[string length $data(-tooltipaddcommand)] != 0 &&
	[string length $data(-tooltipdelcommand)] != 0} {
	#
	# Remove the tooltip, if any
	#
	event generate $win <Leave>
	catch {uplevel #0 $data(-tooltipdelcommand) [list $win]}
	set data(prevCol) -1
    }

    if {$data(isDisabled)} {
	return ""
    }

    configLabel $w -active 0
}

#------------------------------------------------------------------------------
# tablelist::labelB1Down
#
# This procedure is invoked when mouse button 1 is pressed in the header label
# w of a tablelist widget.  If the pointer is on the right border of the label
# then the procedure records its x-coordinate relative to the label, the width
# of the column, and some other data needed later.  Otherwise it saves the
# label's relief so it can be restored later, and changes the relief to sunken.
#------------------------------------------------------------------------------
proc tablelist::labelB1Down {w x shiftPressed} {
    if {![parseLabelPath $w win col]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled) ||
	[info exists data(colBeingResized)]} {	;# resize operation in progress
	return ""
    }

    set data(labelClicked) 1
    set data(X) [expr {[winfo rootx $w] + $x}]
    set data(shiftPressed) $shiftPressed

    if {[inResizeArea $w $x col] &&
	$data(-resizablecolumns) && $data($col-resizable)} {
	set data(colBeingResized) $col
	set data(colResized) 0

	set w $data(body)
	set topTextIdx [$w index @0,0]
	set btmTextIdx [$w index @0,[expr {[winfo height $w] - 1}]]
	$w tag add visibleLines "$topTextIdx linestart" "$btmTextIdx lineend"
	set data(topRow) [expr {int($topTextIdx) - 1}]
	set data(btmRow) [expr {int($btmTextIdx) - 1}]

	set w $data(hdrTxtFrmLbl)$col
	set labelWidth [winfo width $w]
	set data(oldStretchedColWidth) [expr {$labelWidth - 2*$data(charWidth)}]
	set data(oldColDelta) $data($col-delta)
	set data(configColWidth) [lindex $data(-columns) [expr {3*$col}]]

	if {[lsearch -exact $data(arrowColList) $col] >= 0} {
	    set canvasWidth $data(arrowWidth)
	    if {[llength $data(arrowColList)] > 1} {
		incr canvasWidth 6
	    }
	    set data(minColWidth) $canvasWidth
	} elseif {$data($col-wrap)} {
	    set data(minColWidth) $data(charWidth)
	} else {
	    set data(minColWidth) 0
	}
	incr data(minColWidth)

	set data(focus) [focus -displayof $win]
	set topWin [winfo toplevel $win]
	focus $topWin
	set data(topEscBinding) [bind $topWin <Escape>]
	bind $topWin <Escape> \
	     [list tablelist::escape [strMap {"%" "%%"} $win] $col]
    } else {
	set data(inClickedLabel) 1
	set data(relief) [$w cget -relief]

	if {[info exists data($col-labelcommand)] ||
	    [string length $data(-labelcommand)] != 0} {
	    set data(changeRelief) 1
	    configLabel $w -relief sunken -pressed 1
	} else {
	    set data(changeRelief) 0
	}

	if {$data(-movablecolumns)} {
	    set data(focus) [focus -displayof $win]
	    set topWin [winfo toplevel $win]
	    focus $topWin
	    set data(topEscBinding) [bind $topWin <Escape>]
	    bind $topWin <Escape> \
		 [list tablelist::escape [strMap {"%" "%%"} $win] $col]
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::labelB1Motion
#
# This procedure is invoked to process mouse motion events in the header label
# w of a tablelist widget while button 1 is down.  If this event occured during
# a column resize operation then the procedure computes the difference between
# the pointer's new x-coordinate relative to that label and the one recorded by
# the last invocation of labelB1Down, and adjusts the width of the
# corresponding column accordingly.  Otherwise a horizontal scrolling is
# performed if needed, and the would-be target position of the clicked label is
# visualized if the columns are movable.
#------------------------------------------------------------------------------
proc tablelist::labelB1Motion {w X x y} {
    if {![parseLabelPath $w win col]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    if {!$data(labelClicked)} {
	return ""
    }

    if {[info exists data(colBeingResized)]} {	;# resize operation in progress
	set width [expr {$data(oldStretchedColWidth) + $X - $data(X)}]
	if {$width >= $data(minColWidth)} {
	    set col $data(colBeingResized)
	    set data(colResized) 1
	    set idx [expr {3*$col}]
	    set data(-columns) [lreplace $data(-columns) $idx $idx -$width]
	    set idx [expr {2*$col}]
	    set data(colList) [lreplace $data(colList) $idx $idx $width]
	    set data($col-lastStaticWidth) $width
	    set data($col-delta) 0
	    redisplayCol $win $col $data(topRow) $data(btmRow)

	    #
	    # Handle the case that the bottom row has become
	    # greater (due to the redisplayCol invocation)
	    #
	    set b $data(body)
	    set btmTextIdx [$b index @0,$data(btmY)]
	    set btmRow [expr {int($btmTextIdx) - 1}]
	    if {$btmRow > $data(lastRow)} {		;# text widget bug
		set btmRow $data(lastRow)
	    }
	    while {$btmRow > $data(btmRow)} {
		$b tag add visibleLines [expr {$data(btmRow) + 2}].0 \
					"$btmTextIdx lineend"
		incr data(btmRow)
		redisplayCol $win $col $data(btmRow) $btmRow
		set data(btmRow) $btmRow

		set btmTextIdx [$b index @0,$data(btmY)]
		set btmRow [expr {int($btmTextIdx) - 1}]
		if {$btmRow > $data(lastRow)} {		;# text widget bug
		    set btmRow $data(lastRow)
		}
	    }

	    #
	    # Handle the case that the top row has become
	    # less (due to the redisplayCol invocation)
	    #
	    set topTextIdx [$b index @0,0]
	    set topRow [expr {int($topTextIdx) - 1}]
	    while {$topRow < $data(topRow)} {
		$b tag add visibleLines "$topTextIdx linestart" \
					$data(topRow).end
		incr data(topRow) -1
		redisplayCol $win $col $topRow $data(topRow)
		set data(topRow) $topRow

		set topTextIdx [$b index @0,0]
		set topRow [expr {int($topTextIdx) - 1}]
	    }

	    adjustColumns $win {} 0
	    adjustElidedText $win
	    redisplayVisibleItems $win
	    updateColors $win
	    updateVScrlbarWhenIdle $win
	}
    } else {
	#
	# Scroll the window horizontally if needed
	#
	set hdrX [winfo rootx $data(hdr)]
	if {$data(-titlecolumns) == 0 || ![winfo viewable $data(vsep)]} {
	    set leftX $hdrX
	} else {
	    set leftX [expr {[winfo rootx $data(vsep)] + 1}]
	}
	set rightX [expr {$hdrX + [winfo width $data(hdr)]}]
	set scroll 0
	if {($X >= $rightX && $data(X) < $rightX) ||
	    ($X < $leftX && $data(X) >= $leftX)} {
	    set scroll 1
	} elseif {($X < $rightX && $data(X) >= $rightX) ||
		  ($X >= $leftX && $data(X) < $leftX)} {
	    after cancel $data(afterId)
	    set data(afterId) ""
	}
	set data(X) $X
	if {$scroll} {
	    horizAutoScan $win
	}

	if {$x >= 1 && $x < [winfo width $w] - 1 &&
	    $y >= 0 && $y < [winfo height $w]} {
	    #
	    # The following code is needed because the event
	    # can also occur in a widget placed into the label
	    #
	    set data(inClickedLabel) 1
	    configLabel $w -cursor $data(-cursor)
	    $data(hdrTxtFrmCanv)$col configure -cursor $data(-cursor)
	    if {$data(changeRelief)} {
		configLabel $w -relief sunken -pressed 1
	    }

	    place forget $data(colGap)
	} else {
	    #
	    # The following code is needed because the event
	    # can also occur in a widget placed into the label
	    #
	    set data(inClickedLabel) 0
	    configLabel $w -relief $data(relief) -pressed 0

	    if {$data(-movablecolumns)} {
		#
		# Get the target column index
		#
		set contW [winfo containing -displayof $w $X [winfo rooty $w]]
		if {[parseLabelPath $contW dummy targetCol]} {
		    set master $contW
		    if {$X < [winfo rootx $contW] + [winfo width $contW]/2} {
			set relx 0.0
		    } else {
			incr targetCol
			set relx 1.0
		    }
		} elseif {[string compare $contW $data(colGap)] == 0} {
		    set targetCol $data(targetCol)
		    set master $data(master)
		    set relx $data(relx)
		} elseif {$X >= $rightX || $X >= [winfo rootx $w]} {
		    for {set targetCol $data(lastCol)} {$targetCol >= 0} \
			{incr targetCol -1} {
			if {!$data($targetCol-hide)} {
			    break
			}
		    }
		    incr targetCol
		    set master $data(hdrTxtFrm)
		    set relx 1.0
		} else {
		    for {set targetCol 0} {$targetCol < $data(colCount)} \
			{incr targetCol} {
			if {!$data($targetCol-hide)} {
			    break
			}
		    }
		    set master $data(hdrTxtFrm)
		    set relx 0.0
		}

		#
		# Visualize the would-be target position
		# of the clicked label if appropriate
		#
		if {$targetCol == $col || $targetCol == $col + 1 ||
		    ($data(-protecttitlecolumns) &&
		     (($col >= $data(-titlecolumns) &&
		       $targetCol < $data(-titlecolumns)) ||
		      ($col < $data(-titlecolumns) &&
		       $targetCol > $data(-titlecolumns))))} {
		    if {[info exists data(targetCol)]} {
			unset data(targetCol)
		    }
		    configLabel $w -cursor $data(-cursor)
		    $data(hdrTxtFrmCanv)$col configure -cursor $data(-cursor)
		    place forget $data(colGap)
		} else {
		    set data(targetCol) $targetCol
		    set data(master) $master
		    set data(relx) $relx
		    configLabel $w -cursor $data(-movecolumncursor)
		    $data(hdrTxtFrmCanv)$col configure -cursor \
					    $data(-movecolumncursor)
		    place $data(colGap) -in $master -anchor n \
					-bordermode outside \
					-relheight 1.0 -relx $relx
		}
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::labelB1Enter
#
# This procedure is invoked when the mouse pointer enters the header label w of
# a tablelist widget while mouse button 1 is down.  If the label was not
# previously clicked then nothing happens.  Otherwise, if this event occured
# during a column resize operation then the procedure updates the mouse cursor
# accordingly.  Otherwise it changes the label's relief to sunken.
#------------------------------------------------------------------------------
proc tablelist::labelB1Enter w {
    if {![parseLabelPath $w win col]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    if {!$data(labelClicked)} {
	return ""
    }

    configLabel $w -cursor $data(-cursor)

    if {[info exists data(colBeingResized)]} {	;# resize operation in progress
	configLabel $w -cursor $data(-resizecursor)
    } else {
	set data(inClickedLabel) 1
	if {$data(changeRelief)} {
	    configLabel $w -relief sunken -pressed 1
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::labelB1Leave
#
# This procedure is invoked when the mouse pointer leaves the header label w of
# a tablelist widget while mouse button 1 is down.  If the label was not
# previously clicked then nothing happens.  Otherwise, if no column resize
# operation is in progress then the procedure restores the label's relief, and,
# if the columns are movable, then it changes the mouse cursor, too.
#------------------------------------------------------------------------------
proc tablelist::labelB1Leave {w x y} {
    if {![parseLabelPath $w win col]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    if {!$data(labelClicked) ||
	[info exists data(colBeingResized)]} {	;# resize operation in progress
	return ""
    }

    #
    # The following code is needed because the event
    # can also occur in a widget placed into the label
    #
    if {$x >= 1 && $x < [winfo width $w] - 1 &&
	$y >= 0 && $y < [winfo height $w]} {
	return ""
    }

    set data(inClickedLabel) 0
    configLabel $w -relief $data(relief) -pressed 0
}

#------------------------------------------------------------------------------
# tablelist::labelB1Up
#
# This procedure is invoked when mouse button 1 is released, if it was
# previously clicked in a label of the tablelist widget win.  If this event
# occured during a column resize operation then the procedure redisplays the
# column and stretches the stretchable columns.  Otherwise, if the mouse button
# was released in the previously clicked label then the procedure restores the
# label's relief and invokes the command specified by the -labelcommand or
# -labelcommand2 configuration option, passing to it the widget name and the
# column number as arguments.  Otherwise the column of the previously clicked
# label is moved before the column containing the mouse cursor or to its right,
# if the columns are movable.
#------------------------------------------------------------------------------
proc tablelist::labelB1Up {w X} {
    if {![parseLabelPath $w win col]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    if {!$data(labelClicked)} {
	return ""
    }

    if {[info exists data(colBeingResized)]} {	;# resize operation in progress
	configLabel $w -cursor $data(-cursor)
	if {[winfo exists $data(focus)]} {
	    focus $data(focus)
	}
	bind [winfo toplevel $win] <Escape> $data(topEscBinding)
	set col $data(colBeingResized)
	if {$data(colResized)} {
	    if {$data(-width) <= 0} {
		$data(hdr) configure -width $data(hdrPixels)
		$data(lb) configure -width \
			  [expr {$data(hdrPixels) / $data(charWidth)}]
	    } elseif {[info exists data(stretchableCols)] &&
		      [lsearch -exact $data(stretchableCols) $col] >= 0} {
		set oldColWidth \
		    [expr {$data(oldStretchedColWidth) - $data(oldColDelta)}]
		set stretchedColWidth \
		    [expr {$data(oldStretchedColWidth) + $X - $data(X)}]
		if {$oldColWidth < $data(stretchablePixels) &&
		    $stretchedColWidth >= $data(minColWidth) &&
		    $stretchedColWidth < $oldColWidth + $data(delta)} {
		    #
		    # Compute the new column width,
		    # using the following equations:
		    #
		    # $colWidth = $stretchedColWidth - $colDelta
		    # $colDelta / $colWidth =
		    #    ($data(delta) - $colWidth + $oldColWidth) /
		    #    ($data(stretchablePixels) + $colWidth - $oldColWidth)
		    #
		    set colWidth [expr {
			$stretchedColWidth *
			($data(stretchablePixels) - $oldColWidth) /
			($data(stretchablePixels) + $data(delta) -
			 $stretchedColWidth)
		    }]
		    if {$colWidth < 1} {
			set colWidth 1
		    }
		    set idx [expr {3*$col}]
		    set data(-columns) \
			[lreplace $data(-columns) $idx $idx -$colWidth]
		    set idx [expr {2*$col}]
		    set data(colList) \
			[lreplace $data(colList) $idx $idx $colWidth]
		    set data($col-delta) [expr {$stretchedColWidth - $colWidth}]
		}
	    }
	}
	unset data(colBeingResized)
	$data(body) tag remove visibleLines 1.0 end
	$data(body) tag configure visibleLines -tabs {}

	if {$data(colResized)} {
	    redisplayCol $win $col 0 last
	    adjustColumns $win {} 0
	    stretchColumns $win $col
	    updateColors $win

	    genVirtualEvent $win <<TablelistColumnResized>> $col
	}
    } else {
	if {[info exists data(X)]} {
	    unset data(X)
	    after cancel $data(afterId)
	    set data(afterId) ""
	}
    	if {$data(-movablecolumns)} {
	    if {[winfo exists $data(focus)]} {
		focus $data(focus)
	    }
	    bind [winfo toplevel $win] <Escape> $data(topEscBinding)
	    place forget $data(colGap)
	}

	if {$data(inClickedLabel)} {
	    configLabel $w -relief $data(relief) -pressed 0
	    if {$data(shiftPressed)} {
		if {[info exists data($col-labelcommand2)]} {
		    uplevel #0 $data($col-labelcommand2) [list $win $col]
		} elseif {[string length $data(-labelcommand2)] != 0} {
		    uplevel #0 $data(-labelcommand2) [list $win $col]
		}
	    } else {
		if {[info exists data($col-labelcommand)]} {
		    uplevel #0 $data($col-labelcommand) [list $win $col]
		} elseif {[string length $data(-labelcommand)] != 0} {
		    uplevel #0 $data(-labelcommand) [list $win $col]
		}
	    }
	} elseif {$data(-movablecolumns)} {
	    $data(hdrTxtFrmCanv)$col configure -cursor $data(-cursor)
	    if {[info exists data(targetCol)]} {
		set sourceColName [doColCget $col $win -name]
		set targetColName [doColCget $data(targetCol) $win -name]

		moveCol $win $col $data(targetCol)

		set userData \
		    [list $col $data(targetCol) $sourceColName $targetColName]
		genVirtualEvent $win <<TablelistColumnMoved>> $userData

		unset data(targetCol)
	    }
	}
    }

    set data(labelClicked) 0
}

#------------------------------------------------------------------------------
# tablelist::labelB3Down
#
# This procedure is invoked when mouse button 3 is pressed in the header label
# w of a tablelist widget.  If the Shift key was down when this event occured
# then the procedure restores the last static width of the given column;
# otherwise it configures the width of the given column to be just large enough
# to hold all the elements (including the label).
#------------------------------------------------------------------------------
proc tablelist::labelB3Down {w shiftPressed} {
    if {![parseLabelPath $w win col]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    if {!$data(isDisabled) &&
	$data(-resizablecolumns) && $data($col-resizable)} {
	if {$shiftPressed} {
	    doColConfig $col $win -width -$data($col-lastStaticWidth)
	} else {
	    doColConfig $col $win -width 0
	}

	genVirtualEvent $win <<TablelistColumnResized>> $col
    }
}

#------------------------------------------------------------------------------
# tablelist::labelDblB1
#
# This procedure is invoked when the header label w of a tablelist widget is
# double-clicked.  If the pointer is on the right border of the label then the
# procedure performs the same action as labelB3Down.
#------------------------------------------------------------------------------
proc tablelist::labelDblB1 {w x shiftPressed} {
    if {![parseLabelPath $w win col]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    if {!$data(isDisabled) && [inResizeArea $w $x col] &&
	$data(-resizablecolumns) && $data($col-resizable)} {
	if {$shiftPressed} {
	    doColConfig $col $win -width -$data($col-lastStaticWidth)
	} else {
	    doColConfig $col $win -width 0
	}

	genVirtualEvent $win <<TablelistColumnResized>> $col
    }
}

#------------------------------------------------------------------------------
# tablelist::escape
#
# This procedure is invoked to process <Escape> events in the top-level window
# containing the tablelist widget win during a column resize or move operation.
# The procedure cancels the action in progress and, in case of column resizing,
# it restores the initial width of the respective column.
#------------------------------------------------------------------------------
proc tablelist::escape {win col} {
    upvar ::tablelist::ns${win}::data data
    set w $data(hdrTxtFrmLbl)$col
    if {[info exists data(colBeingResized)]} {	;# resize operation in progress
	configLabel $w -cursor $data(-cursor)
	update idletasks
	if {![array exists ::tablelist::ns${win}::data]} {
	    return ""
	}
	if {[winfo exists $data(focus)]} {
	    focus $data(focus)
	}
	bind [winfo toplevel $win] <Escape> $data(topEscBinding)
	set data(labelClicked) 0
	set col $data(colBeingResized)
	set idx [expr {3*$col}]
	setupColumns $win [lreplace $data(-columns) $idx $idx \
				    $data(configColWidth)] 0
	redisplayCol $win $col $data(topRow) $data(btmRow)
	unset data(colBeingResized)
	$data(body) tag remove visibleLines 1.0 end
	$data(body) tag configure visibleLines -tabs {}
	adjustColumns $win {} 1
	updateColors $win
    } elseif {!$data(inClickedLabel)} {
	configLabel $w -cursor $data(-cursor)
	$data(hdrTxtFrmCanv)$col configure -cursor $data(-cursor)
	if {[winfo exists $data(focus)]} {
	    focus $data(focus)
	}
	bind [winfo toplevel $win] <Escape> $data(topEscBinding)
	place forget $data(colGap)
	if {[info exists data(targetCol)]} {
	    unset data(targetCol)
	}
	if {[info exists data(X)]} {
	    unset data(X)
	    after cancel $data(afterId)
	    set data(afterId) ""
	}
	set data(labelClicked) 0
    }
}

#------------------------------------------------------------------------------
# tablelist::horizAutoScan
#
# This procedure is invoked when the mouse leaves the scrollable part of a
# tablelist widget's header frame while button 1 is down.  It scrolls the
# header and reschedules itself as an after command so that the header
# continues to scroll until the mouse moves back into the window or the mouse
# button is released.
#------------------------------------------------------------------------------
proc tablelist::horizAutoScan win {
    if {![array exists ::tablelist::ns${win}::data]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    if {![info exists data(X)]} {
	return ""
    }

    set X $data(X)
    set hdrX [winfo rootx $data(hdr)]
    if {$data(-titlecolumns) == 0 || ![winfo viewable $data(vsep)]} {
	set leftX $hdrX
    } else {
	set leftX [expr {[winfo rootx $data(vsep)] + 1}]
    }
    set rightX [expr {$hdrX + [winfo width $data(hdr)]}]
    if {$data(-titlecolumns) == 0} {
	set units 2
	set ms 50
    } else {
	set units 1
	set ms 250
    }

    if {$X >= $rightX} {
	::$win xview scroll $units units
    } elseif {$X < $leftX} {
	::$win xview scroll -$units units
    } else {
	return ""
    }

    set data(afterId) [after $ms [list tablelist::horizAutoScan $win]]
}

#------------------------------------------------------------------------------
# tablelist::inResizeArea
#
# Checks whether the given x coordinate relative to the header label w of a
# tablelist widget is in the resize area of that label or of the one to its
# left.
#------------------------------------------------------------------------------
proc tablelist::inResizeArea {w x colName} {
    if {![parseLabelPath $w dummy _col]} {
	return 0
    }


    upvar $colName col
    if {$x >= [winfo width $w] - 5} {
	set col $_col
	return 1
    } elseif {$x < 5} {
	set X [expr {[winfo rootx $w] - 3}]
	set contW [winfo containing -displayof $w $X [winfo rooty $w]]
	return [parseLabelPath $contW dummy col]
    } else {
	return 0
    }
}
#==============================================================================
# Contains private configuration procedures for tablelist widgets.
#
# Copyright (c) 2000-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#------------------------------------------------------------------------------
# tablelist::extendConfigSpecs
#
# Extends the elements of the array configSpecs.
#------------------------------------------------------------------------------
proc tablelist::extendConfigSpecs {} {
    variable usingTile
    variable helpLabel
    variable configSpecs
    variable winSys

    #
    # Extend some elements of the array configSpecs
    #
    lappend configSpecs(-acceptchildcommand)	{}
    lappend configSpecs(-acceptdropcommand)	{}
    lappend configSpecs(-activestyle)		frame
    lappend configSpecs(-autofinishediting)	0
    lappend configSpecs(-autoscan)		1
    lappend configSpecs(-collapsecommand)	{}
    lappend configSpecs(-colorizecommand)	{}
    lappend configSpecs(-columns)		{}
    lappend configSpecs(-columntitles)		{}
    lappend configSpecs(-customdragsource)	0
    lappend configSpecs(-displayondemand)	1
    lappend configSpecs(-editendcommand)	{}
    lappend configSpecs(-editselectedonly)	0
    lappend configSpecs(-editstartcommand)	{}
    lappend configSpecs(-expandcommand)		{}
    lappend configSpecs(-forceeditendcommand)	0
    lappend configSpecs(-fullseparators)	0
    lappend configSpecs(-incrarrowtype)		up
    lappend configSpecs(-instanttoggle)		0
    lappend configSpecs(-labelcommand)		{}
    lappend configSpecs(-labelcommand2)		{}
    lappend configSpecs(-labelrelief)		raised
    lappend configSpecs(-listvariable)		{}
    lappend configSpecs(-movablecolumns)	0
    lappend configSpecs(-movablerows)		0
    lappend configSpecs(-populatecommand)	{}
    lappend configSpecs(-protecttitlecolumns)	0
    lappend configSpecs(-resizablecolumns)	1
    lappend configSpecs(-selecttype)		row
    lappend configSpecs(-setfocus)		1
    lappend configSpecs(-showarrow)		1
    lappend configSpecs(-showeditcursor)	1
    lappend configSpecs(-showhorizseparator)	1
    lappend configSpecs(-showlabels)		1
    lappend configSpecs(-showseparators)	0
    lappend configSpecs(-snipstring)		...
    lappend configSpecs(-sortcommand)		{}
    lappend configSpecs(-spacing)		0
    lappend configSpecs(-stretch)		{}
    lappend configSpecs(-stripebackground)	{}
    lappend configSpecs(-stripeforeground)	{}
    lappend configSpecs(-stripeheight)		1
    lappend configSpecs(-targetcolor)		black
    lappend configSpecs(-tight)			0
    lappend configSpecs(-titlecolumns)		0
    lappend configSpecs(-tooltipaddcommand)	{}
    lappend configSpecs(-tooltipdelcommand)	{}
    lappend configSpecs(-treecolumn)		0

    #
    # Append the default values of the configuration options
    # of a temporary, invisible listbox widget to the values
    # of the corresponding elements of the array configSpecs
    #
    set helpListbox .__helpListbox
    for {set n 2} {[winfo exists $helpListbox]} {incr n} {
	set helpListbox .__helpListbox$n
    }
    listbox $helpListbox
    foreach configSet [$helpListbox configure] {
	if {[llength $configSet] != 2} {
	    set opt [lindex $configSet 0]
	    if {[info exists configSpecs($opt)]} {
		lappend configSpecs($opt) [lindex $configSet 3]
	    }
	}
    }
    destroy $helpListbox

    set helpLabel .__helpLabel
    for {set n 0} {[winfo exists $helpLabel]} {incr n} {
	set helpLabel .__helpLabel$n
    }

    if {$usingTile} {
	foreach opt {-highlightbackground -highlightcolor -highlightthickness
		     -labelactivebackground -labelactiveforeground
		     -labelbackground -labelbg -labeldisabledforeground
		     -labelheight} {
	    unset configSpecs($opt)
	}

	#
	# Append theme-specific values to some elements of the
	# array configSpecs and initialize some tree resources
	#
	if {[string compare [getCurrentTheme] "tileqt"] == 0} {
	    tileqt_kdeStyleChangeNotification 
	}
	setThemeDefaults
	variable themeDefaults
	set treeStyle $themeDefaults(-treestyle)
	${treeStyle}TreeImgs 
	variable maxIndentDepths
	set maxIndentDepths($treeStyle) 0

	ttk::label $helpLabel -takefocus 0

	#
	# Define the header label layout
	#
	style theme settings "default" {
	    style layout TablelistHeader.TLabel {
		Treeheading.cell
		Treeheading.border -children {
		    Label.padding -children {
			Label.label
		    }
		}
	    }
	}
	if {[string length [package provide ttk::theme::aqua]] != 0 ||
	    [string length [package provide tile::theme::aqua]] != 0} {
	    style theme settings "aqua" {
		if {[info exists tile::patchlevel] &&
		    [string compare $tile::patchlevel "0.6.4"] < 0} {
		    style layout TablelistHeader.TLabel {
			Treeheading.cell
			Label.padding -children {
			    Label.label -side top
			    Separator.hseparator -side bottom
			}
		    }
		} else {
		    style layout TablelistHeader.TLabel {
			Treeheading.cell
			Label.padding -children {
			    Label.label -side top
			}
		    }
		}
		style map TablelistHeader.TLabel -foreground [list \
		    {disabled background} #a3a3a3 disabled #a3a3a3 \
		    background black]
	    }
	}
    } else {
	if {$::tk_version < 8.3} {
	    unset configSpecs(-acceptchildcommand)
	    unset configSpecs(-collapsecommand)
	    unset configSpecs(-expandcommand)
	    unset configSpecs(-populatecommand)
	    unset configSpecs(-titlecolumns)
	    unset configSpecs(-treecolumn)
	    unset configSpecs(-treestyle)
	}

	#
	# Append the default values of some configuration options
	# of an invisible label widget to the values of the
	# corresponding -label* elements of the array configSpecs
	#
	tk::label $helpLabel -takefocus 0
	foreach optTail {font height} {
	    set configSet [$helpLabel configure -$optTail]
	    lappend configSpecs(-label$optTail) [lindex $configSet 3]
	}
	if {[catch {$helpLabel configure -activebackground} configSet1] == 0 &&
	    [catch {$helpLabel configure -activeforeground} configSet2] == 0} {
	    lappend configSpecs(-labelactivebackground) [lindex $configSet1 3]
	    lappend configSpecs(-labelactiveforeground) [lindex $configSet2 3]
	} else {
	    unset configSpecs(-labelactivebackground)
	    unset configSpecs(-labelactiveforeground)
	}
	if {[catch {$helpLabel configure -disabledforeground} configSet] == 0} {
	    lappend configSpecs(-labeldisabledforeground) [lindex $configSet 3]
	} else {
	    unset configSpecs(-labeldisabledforeground)
	}
	if {[string compare $winSys "win32"] == 0 &&
	    $::tcl_platform(osVersion) < 5.1} {
	    lappend configSpecs(-labelpady) 0
	} else {
	    set configSet [$helpLabel configure -pady]
	    lappend configSpecs(-labelpady) [lindex $configSet 3]
	}

	#
	# Steal the default values of some configuration
	# options from a temporary, invisible button widget
	#
	set helpButton .__helpButton
	for {set n 0} {[winfo exists $helpButton]} {incr n} {
	    set helpButton .__helpButton$n
	}
	button $helpButton
	foreach opt {-disabledforeground -state} {
	    if {[llength $configSpecs($opt)] == 3} {
		set configSet [$helpButton configure $opt]
		lappend configSpecs($opt) [lindex $configSet 3]
	    }
	}
	foreach optTail {background foreground} {
	    set configSet [$helpButton configure -$optTail]
	    lappend configSpecs(-label$optTail) [lindex $configSet 3]
	}
	if {[string compare $winSys "classic"] == 0 ||
	    [string compare $winSys "aqua"] == 0} {
	    lappend configSpecs(-labelborderwidth) 1
	} else {
	    set configSet [$helpButton configure -borderwidth]
	    lappend configSpecs(-labelborderwidth) [lindex $configSet 3]
	}
	destroy $helpButton

	#
	# Set the default values of the -arrowcolor,
	# -arrowdisabledcolor, -arrowstyle, and -treestyle options
	#
	switch $winSys {
	    x11 {
		set arrowColor		black
		set arrowDisabledColor	#a3a3a3
		set arrowStyle		flat7x5
		set treeStyle		gtk
	    }

	    win32 {
		if {$::tcl_platform(osVersion) < 5.1} {		;# Win native
		    set arrowColor		{}
		    set arrowDisabledColor	{}
		    set arrowStyle		sunken8x7
		    set treeStyle		winnative

		} elseif {$::tcl_platform(osVersion) == 5.1} {	;# Win XP
		    switch [winfo rgb . SystemHighlight] {
			"12593 27242 50629" {			;# Win XP Blue
			    set arrowColor	#aca899
			    set arrowStyle	flat9x5
			    set treeStyle	winxpBlue
			}
			"37779 41120 28784" {			;# Win XP Olive
			    set arrowColor	#aca899
			    set arrowStyle	flat9x5
			    set treeStyle	winxpOlive
			}
			"45746 46260 49087" {			;# Win XP Silver
			    set arrowColor	#aca899
			    set arrowStyle	flat9x5
			    set treeStyle	winxpSilver
			}
			default {				;# Win Classic
			    set arrowColor	SystemButtonShadow
			    set arrowStyle	flat7x4
			    set treeStyle	winnative
			}
		    }
		    set arrowDisabledColor	SystemDisabledText

		} elseif {$::tcl_platform(osVersion) == 6.0} {	;# Win Vista
		    variable scalingpct

		    switch [winfo rgb . SystemHighlight] {
			"13107 39321 65535" {			;# Vista Aero
			    set arrowColor	#569bc0
			    switch $scalingpct {
				100 { set arrowStyle	photo7x4 }
				125 { set arrowStyle	photo9x5 }
				150 { set arrowStyle	photo11x6 }
				200 { set arrowStyle	photo15x8 }
			    }
			    set treeStyle	vistaAero
			}
			default {				;# Win Classic
			    set arrowColor	SystemButtonShadow
			    switch $scalingpct {
				100 { set arrowStyle	flat7x4 }
				125 { set arrowStyle	flat9x5 }
				150 { set arrowStyle	flat11x6 }
				200 { set arrowStyle	flat15x8 }
			    }
			    set treeStyle	vistaClassic
			}
		    }
		    set arrowDisabledColor	SystemDisabledText

		} elseif {$::tcl_platform(osVersion) < 10.0} {	;# Win 7/8
		    variable scalingpct

		    switch [winfo rgb . SystemHighlight] {
			"13107 39321 65535" {			;# Win 7/8 Aero
			    set arrowColor	#569bc0
			    switch $scalingpct {
				100 { set arrowStyle	photo7x4 }
				125 { set arrowStyle	photo9x5 }
				150 { set arrowStyle	photo11x6 }
				200 { set arrowStyle	photo15x8 }
			    }
			    set treeStyle	win7Aero
			}
			default {				;# Win Classic
			    set arrowColor	SystemButtonShadow
			    switch $scalingpct {
				100 { set arrowStyle	flat7x4 }
				125 { set arrowStyle	flat9x5 }
				150 { set arrowStyle	flat11x6 }
				200 { set arrowStyle	flat15x8 }
			    }
			    set treeStyle	win7Classic
			}
		    }
		    set arrowDisabledColor	SystemDisabledText

		} else {					;# Win 10
		    variable scalingpct
		    switch $scalingpct {
			100 { set arrowStyle	flatAngle7x4 }
			125 { set arrowStyle	flatAngle9x5 }
			150 { set arrowStyle	flatAngle11x6 }
			200 { set arrowStyle	flatAngle15x8 }
		    }

		    set arrowColor		#595959
		    set arrowDisabledColor	SystemDisabledText
		    set treeStyle		win10
		}
	    }

	    classic -
	    aqua {
		scan $::tcl_platform(osVersion) "%d" majorOSVersion
		if {$majorOSVersion >= 14} {		;# OS X 10.10 or higher
		    set arrowColor	#404040
		    set arrowStyle	flatAngle7x4
		} else {
		    set arrowColor	#717171
		    variable pngSupported
		    if {$pngSupported} {
			set arrowStyle	photo7x7
		    } else {
			set arrowStyle	flat7x7
		    }
		}
		set arrowDisabledColor	#a3a3a3
		set treeStyle		aqua
	    }
	}
	lappend configSpecs(-arrowcolor)		$arrowColor
	lappend configSpecs(-arrowdisabledcolor)	$arrowDisabledColor
	lappend configSpecs(-arrowstyle)		$arrowStyle
	if {$::tk_version >= 8.3} {
	    lappend configSpecs(-treestyle)		$treeStyle
	    ${treeStyle}TreeImgs 
	    variable maxIndentDepths
	    set maxIndentDepths($treeStyle) 0
	}
    }

    #
    # Set the default values of the -movecolumncursor,
    # -movecursor, and -resizecursor options
    #
    switch $winSys {
	x11 -
	win32 {
	    set movecolumnCursor	icon
	    set moveCursor		hand2
	    set resizeCursor		sb_h_double_arrow
	}

	classic -
	aqua {
	    set movecolumnCursor	closedhand
	    set moveCursor		pointinghand
	    if {[catch {$helpLabel configure -cursor resizeleftright}] == 0} {
		set resizeCursor	resizeleftright
	    } else {
		set resizeCursor	sb_h_double_arrow
	    }
	}
    }
    lappend configSpecs(-movecolumncursor)	$movecolumnCursor
    lappend configSpecs(-movecursor)		$moveCursor
    lappend configSpecs(-resizecursor)		$resizeCursor

    variable centerArrows 0
    if {[string compare $winSys "win32"] == 0 &&
	$::tcl_platform(osVersion) >= 6.0 &&
	[string compare [winfo rgb . SystemHighlight] \
			"13107 39321 65535"] == 0} {
	set centerArrows 1
    }
}

#------------------------------------------------------------------------------
# tablelist::doConfig
#
# Applies the value val of the configuration option opt to the tablelist widget
# win.
#------------------------------------------------------------------------------
proc tablelist::doConfig {win opt val} {
    variable usingTile
    variable helpLabel
    variable configSpecs
    upvar ::tablelist::ns${win}::data data

    #
    # Apply the value to the widget(s) corresponding to the given option
    #
    switch [lindex $configSpecs($opt) 2] {
	c {
	    #
	    # Apply the value to all children and save the
	    # properly formatted value of val in data($opt)
	    #
	    foreach w [winfo children $win] {
		if {[regexp {^(body|hdr|.sep[0-9]*)$} [winfo name $w]]} {
		    $w configure $opt $val
		}
	    }
	    $data(hdrTxt) configure $opt $val
	    $data(hdrFrmLbl) configure $opt $val
	    $data(cornerLbl) configure $opt $val
	    foreach w [winfo children $data(hdrTxtFrm)] {
		$w configure $opt $val
	    }
	    set data($opt) [$data(hdrFrmLbl) cget $opt]
	}

	b {
	    #
	    # Apply the value to the body text widget and save
	    # the properly formatted value of val in data($opt)
	    #
	    set w $data(body)
	    $w configure $opt $val
	    set data($opt) [$w cget $opt]

	    switch -- $opt {
		-background {
		    #
		    # Apply the value to the frame (because of the shadow
		    # colors of its 3-D border), to the separators,
		    # to the header frame, and to the "disabled" tag
		    #
		    if {$usingTile} {
			styleConfig Frame$win.TFrame $opt $val
			styleConfig Seps$win.TSeparator $opt $val
		    } else {
			$win configure $opt $val
			foreach c [winfo children $win] {
			    if {[regexp {^(vsep[0-9]+|hsep)$} \
					[winfo name $c]]} {
				$c configure $opt $val
			    }
			}
		    }
		    $data(hdr) configure $opt $val
		    $w tag configure disabled $opt $val
		    updateColorsWhenIdle $win
		}
		-font {
		    #
		    # Apply the value to the listbox child, rebuild the lists
		    # of the column fonts and tag names, configure the edit
		    # window if present, set up and adjust the columns, and
		    # make sure the items will be redisplayed at idle time
		    #
		    $data(lb) configure $opt $val
		    set data(charWidth) [font measure $val -displayof $win 0]
		    makeColFontAndTagLists $win
		    if {$data(editRow) >= 0} {
			setEditWinFont $win
		    }
		    for {set col 0} {$col < $data(colCount)} {incr col} {
			if {$data($col-maxwidth) > 0} {
			    set data($col-maxPixels) \
				[charsToPixels $win $val $data($col-maxwidth)]
			}
		    }
		    setupColumns $win $data(-columns) 0
		    adjustColumns $win allCols 1
		    redisplayWhenIdle $win
		    updateViewWhenIdle $win
		}
		-foreground {
		    #
		    # Set the background color of the main separator
		    # (if any) to the specified value, and apply
		    # this value to the "disabled" tag if needed
		    #
		    if {$usingTile} {
			styleConfig Sep$win.TSeparator -background $val
		    } else {
			if {[winfo exists $data(vsep)]} {
			    $data(vsep) configure -background $val
			}
		    }
		    if {[string length $data(-disabledforeground)] == 0} {
			$w tag configure disabled $opt $val
		    }
		    updateColorsWhenIdle $win
		}
	    }
	}

	l {
	    #
	    # Apply the value to all not individually configured labels
	    # and save the properly formatted value of val in data($opt)
	    #
	    set optTail [string range $opt 6 end]	;# remove the -label
	    configLabel $data(hdrFrmLbl) -$optTail $val
	    configLabel $data(cornerLbl) -$optTail $val
	    for {set col 0} {$col < $data(colCount)} {incr col} {
		set w $data(hdrTxtFrmLbl)$col
		if {![info exists data($col$opt)]} {
		    configLabel $w -$optTail $val
		}
	    }
	    if {$usingTile && [string compare $opt "-labelpady"] == 0} {
		set data($opt) $val
	    } else {
		set data($opt) [$data(hdrFrmLbl) cget -$optTail]
	    }

	    switch -- $opt {
		-labelbackground -
		-labelforeground {
		    #
		    # Apply the value to $data(hdrTxt) and conditionally
		    # to the canvases displaying up- or down-arrows
		    #
		    $helpLabel configure -$optTail $val
		    set data($opt) [$helpLabel cget -$optTail]
		    $data(hdrTxt) configure -$optTail $data($opt)
		    foreach col $data(arrowColList) {
			if {![info exists data($col$opt)]} {
			    configCanvas $win $col
			}
		    }
		}
		-labelborderwidth {
		    #
		    # Adjust the columns (including
		    # the height of the header frame)
		    #
		    adjustColumns $win allLabels 1

		    set borderWidth [winfo pixels $win $data($opt)]
		    if {$borderWidth < 0} {
			set borderWidth 0
		    }
		    place configure $data(cornerLbl) -x -$borderWidth \
			-width [expr {2*$borderWidth}]
		}
		-labeldisabledforeground {
		    #
		    # Conditionally apply the value to the
		    # canvases displaying up- or down-arrows
		    #
		    foreach col $data(arrowColList) {
			if {![info exists data($col$opt)]} {
			    configCanvas $win $col
			}
		    }
		}
		-labelfont {
		    #
		    # Apply the value to $data(hdrTxt) and adjust the
		    # columns (including the height of the header frame)
		    #
		    $data(hdrTxt) configure -$optTail $data($opt)
		    adjustColumns $win allLabels 1
		}
		-labelheight -
		-labelpady {
		    #
		    # Adjust the height of the header frame
		    #
		    adjustHeaderHeight $win
		}
	    }
	}

	f {
	    #
	    # Apply the value to the frame and save the
	    # properly formatted value of val in data($opt)
	    #
	    $win configure $opt $val
	    set data($opt) [$win cget $opt]
	}

	w {
	    switch -- $opt {
		-acceptchildcommand -
		-acceptdropcommand -
		-collapsecommand -
		-colorizecommand -
		-editendcommand -
		-editstartcommand -
		-expandcommand -
		-labelcommand -
		-labelcommand2 -
		-populatecommand -
		-selectmode -
		-sortcommand -
		-tooltipaddcommand -
		-tooltipdelcommand -
		-yscrollcommand {
		    set data($opt) $val
		}
		-activestyle {
		    #
		    # Configure the "active" tag and save the
		    # properly formatted value of val in data($opt)
		    #
		    variable activeStyles
		    set val [mwutil::fullOpt "active style" $val $activeStyles]
		    set w $data(body)
		    switch $val {
			frame {
			    $w tag configure active \
				   -borderwidth 1 -relief solid -underline ""
			}
			none {
			    $w tag configure active \
				   -borderwidth "" -relief "" -underline ""
			}
			underline {
			    $w tag configure active \
				   -borderwidth "" -relief "" -underline 1
			}
		    }
		    set data($opt) $val
		}
		-arrowcolor -
		-arrowdisabledcolor {
		    #
		    # Save the properly formatted value of val in data($opt)
		    # and set the color of the normal or disabled arrows
		    #
		    if {[string length $val] == 0} {
			set data($opt) ""
		    } else {
			$helpLabel configure -foreground $val
			set data($opt) [$helpLabel cget -foreground]
		    }
		    if {([string compare $opt "-arrowcolor"] == 0 &&
			 !$data(isDisabled)) ||
			([string compare $opt "-arrowdisabledcolor"] == 0 &&
			 $data(isDisabled))} {
			foreach w [info commands $data(hdrTxtFrmCanv)*] {
			    fillArrows $w $val $data(-arrowstyle)
			}
		    }
		}
		-arrowstyle {
		    #
		    # Save the properly formatted value of val in data($opt)
		    # and draw the corresponding arrows in the canvas widgets
		    #
		    variable arrowStyles
		    set data($opt) \
			[mwutil::fullOpt "arrow style" $val $arrowStyles]
		    regexp {^(flat|flatAngle|sunken|photo)([0-9]+)x([0-9]+)$} \
			   $data($opt) dummy relief width height
		    set data(arrowWidth) $width
		    set data(arrowHeight) $height
		    foreach w [info commands $data(hdrTxtFrmCanv)*] {
			createArrows $w $width $height $relief
			if {$data(isDisabled)} {
			    fillArrows $w $data(-arrowdisabledcolor) $data($opt)
			} else {
			    fillArrows $w $data(-arrowcolor) $data($opt)
			}
		    }
		    if {[llength $data(arrowColList)] > 0} {
			foreach col $data(arrowColList) {
			    raiseArrow $win $col
			    lappend whichWidths l$col
			}
			adjustColumns $win $whichWidths 1
		    }
		}
		-autofinishediting -
		-autoscan -
		-customdragsource -
		-displayondemand -
		-forceeditendcommand -
		-instanttoggle -
		-movablecolumns -
		-movablerows -
		-protecttitlecolumns -
		-resizablecolumns -
		-setfocus {
		    #
		    # Save the boolean value specified by val in data($opt)
		    #
		    set data($opt) [expr {$val ? 1 : 0}]
		}
		-columns {
		    #
		    # Set up and adjust the columns, rebuild
		    # the lists of the column fonts and tag
		    # names, and redisplay the items
		    #
		    set selCells [curCellSelection $win]
		    setupColumns $win $val 1
		    adjustColumns $win allCols 1
		    adjustColIndex $win data(anchorCol) 1
		    adjustColIndex $win data(activeCol) 1
		    makeColFontAndTagLists $win
		    redisplay $win 0 $selCells
		    updateViewWhenIdle $win
		}
		-columntitles {
		    set titleCount [llength $val]
		    set colCount $data(colCount)
		    if {$titleCount <= $colCount} {
			#
			# Update the first titleCount column
			# titles and adjust the columns
			#
			set whichWidths {}
			for {set col 0} {$col < $titleCount} {incr col} {
			    set idx [expr {3*$col + 1}]
			    set data(-columns) [lreplace $data(-columns) \
						$idx $idx [lindex $val $col]]
			    lappend whichWidths l$col
			}
			adjustColumns $win $whichWidths 1
		    } else {
			#
			# Update the titles of the current columns,
			# extend the column list, and do nearly the
			# same as in the case of the -columns option
			#
			set columns {}
			set col 0
			foreach {width title alignment} $data(-columns) {
			    lappend columns $width [lindex $val $col] $alignment
			    incr col
			}
			for {} {$col < $titleCount} {incr col} {
			    lappend columns 0 [lindex $val $col] left
			}
			set selCells [curCellSelection $win]
			setupColumns $win $columns 1
			adjustColumns $win allCols 1
			makeColFontAndTagLists $win
			redisplay $win 0 $selCells
			updateViewWhenIdle $win

			#
			# If this option is being set at widget creation time
			# then append "-columns" to the list of command line
			# options processed by the caller proc, to make sure
			# that the columns-related information produced by the
			# setupColumns call above won't be overridden by the
			# default -columns {} option that would otherwise
			# be processed as a non-explicitly specified option
			#
			set callerProc [lindex [info level -1] 0]
			if {[string compare $callerProc \
			     "mwutil::configureWidget"] == 0} {
			    uplevel 1 lappend cmdLineOpts "-columns"
			}
		    }
		}
		-disabledforeground {
		    #
		    # Configure the "disabled" tag in the body text widget and
		    # save the properly formatted value of val in data($opt)
		    #
		    set w $data(body)
		    if {[string length $val] == 0} {
			$w tag configure disabled -fgstipple gray50 \
				-foreground $data(-foreground)
			set data($opt) ""
		    } else {
			$w tag configure disabled -fgstipple "" \
				-foreground $val
			set data($opt) [$w tag cget disabled -foreground]
		    }
		    if {$data(isDisabled)} {
			updateColorsWhenIdle $win
		    }
		}
		-editselectedonly {
		    #
		    # Save the boolean value specified by val in data($opt)
		    # and invoke the motion handler if necessary
		    #
		    set data($opt) [expr {$val ? 1 : 0}]
		    if {$data(-showeditcursor)} {
			invokeMotionHandler $win
		    }
		}
		-exportselection {
		    #
		    # Save the boolean value specified by val in
		    # data($opt).  In addition, if the selection is
		    # exported and there are any selected rows in the
		    # widget then make win the new owner of the PRIMARY
		    # selection and register a callback to be invoked
		    # when it loses ownership of the PRIMARY selection
		    #
		    set data($opt) [expr {$val ? 1 : 0}]
		    if {$val &&
			[llength [$data(body) tag nextrange select 1.0]] != 0} {
			selection own -command \
				[list ::tablelist::lostSelection $win] $win
		    }
		}
		-fullseparators -
		-showhorizseparator {
		    #
		    # Save the boolean value specified by val
		    # in data($opt) and adjust the separators
		    #
		    set data($opt) [expr {$val ? 1 : 0}]
		    adjustSepsWhenIdle $win
		}
		-height {
		    #
		    # Adjust the heights of the body text widget
		    # and of the listbox child, and save the
		    # properly formatted value of val in data($opt)
		    #
		    set val [format "%d" $val]	;# integer check with error msg
		    if {$val <= 0} {
			set viewableRowCount [expr \
			    {$data(itemCount) - $data(nonViewableRowCount)}]
			$data(body) configure $opt $viewableRowCount
			$data(lb) configure $opt $viewableRowCount
		    } else {
			$data(body) configure $opt $val
			$data(lb) configure $opt $val
		    }
		    set data($opt) $val
		}
		-incrarrowtype {
		    #
		    # Save the properly formatted value of val in
		    # data($opt) and raise the corresponding arrows
		    # if the currently mapped canvas widgets
		    #
		    variable arrowTypes
		    set data($opt) \
			[mwutil::fullOpt "arrow type" $val $arrowTypes]
		    foreach col $data(arrowColList) {
			raiseArrow $win $col
		    }
		}
		-listvariable {
		    #
		    # Associate val as list variable with the
		    # given widget and save it in data($opt)
		    #
		    makeListVar $win $val
		    set data($opt) $val
		    if {[string length $val] == 0} {
			set data(hasListVar) 0
		    } else {
			set data(hasListVar) 1
		    }
		}
		-movecolumncursor -
		-movecursor -
		-resizecursor {
		    #
		    # Save the properly formatted value of val in data($opt)
		    #
		    $helpLabel configure -cursor $val
		    set data($opt) [$helpLabel cget -cursor]
		}
		-selectbackground -
		-selectforeground {
		    #
		    # Configure the "select" tag in the body text widget
		    # and save the properly formatted value of val in
		    # data($opt).  Don't use the built-in "sel" tag
		    # because on Windows the selection in a text widget only
		    # becomes visible when the window gets the input focus.
		    #
		    set w $data(body)
		    set optTail [string range $opt 7 end] ;# remove the -select
		    $w tag configure select -$optTail $val
		    set data($opt) [$w tag cget select -$optTail]
		    if {!$data(isDisabled)} {
			updateColorsWhenIdle $win
		    }
		}
		-selecttype {
		    #
		    # Save the properly formatted value of val in data($opt)
		    #
		    variable selectTypes
		    set val [mwutil::fullOpt "selection type" $val $selectTypes]
		    set data($opt) $val
		}
		-selectborderwidth {
		    #
		    # Configure the "select" tag in the body text widget
		    # and save the properly formatted value of val in
		    # data($opt).  Don't use the built-in "sel" tag
		    # because on Windows the selection in a text widget only
		    # becomes visible when the window gets the input focus.
		    # In addition, adjust the line spacing accordingly and
		    # apply the value to the listbox child, too.
		    #
		    set w $data(body)
		    set optTail [string range $opt 7 end] ;# remove the -select
		    $w tag configure select -$optTail $val
		    set data($opt) [$w tag cget select -$optTail]
		    set pixVal [winfo pixels $w $val]
		    if {$pixVal < 0} {
			set pixVal 0
		    }
		    set spacing [winfo pixels $w $data(-spacing)]
		    if {$spacing < 0} {
			set spacing 0
		    }
		    $w configure -spacing1 [expr {$spacing + $pixVal}] \
			-spacing3 [expr {$spacing + $pixVal + !$data(-tight)}]
		    $data(lb) configure $opt $val
		    redisplayWhenIdle $win
		    updateViewWhenIdle $win
		}
		-setgrid {
		    #
		    # Apply the value to the listbox child and save
		    # the properly formatted value of val in data($opt)
		    #
		    $data(lb) configure $opt $val
		    set data($opt) [$data(lb) cget $opt]
		}
		-showarrow {
		    #
		    # Save the boolean value specified by val in
		    # data($opt) and manage or unmanage the
		    # canvases displaying up- or down-arrows
		    #
		    set data($opt) [expr {$val ? 1 : 0}]
		    makeSortAndArrowColLists $win
		    adjustColumns $win allLabels 1
		}
		-showeditcursor {
		    #
		    # Save the boolean value specified by val in
		    # data($opt) and invoke the motion handler
		    #
		    set data($opt) [expr {$val ? 1 : 0}]
		    invokeMotionHandler $win
		}
		-showlabels {
		    #
		    # Save the boolean value specified by val in data($opt)
		    # and adjust the height of the header frame
		    #
		    set data($opt) [expr {$val ? 1 : 0}]
		    adjustHeaderHeight $win
		}
		-showseparators {
		    #
		    # Save the boolean value specified by val in data($opt),
		    # and create or destroy the separators if needed
		    #
		    set oldVal $data($opt)
		    set data($opt) [expr {$val ? 1 : 0}]
		    if {!$oldVal && $data($opt)} {
			createSeps $win
		    } elseif {$oldVal && !$data($opt)} {
			foreach w [winfo children $win] {
			    if {[regexp {^(vsep[0-9]+|hsep)$} \
					[winfo name $w]]} {
				destroy $w
			    }
			}
		    }
		}
		-snipstring {
		    #
		    # Save val in data($opt), adjust the columns, and make
		    # sure the items will be redisplayed at idle time
		    #
		    set data($opt) $val
		    adjustColumns $win {} 0
		    redisplayWhenIdle $win
		    updateViewWhenIdle $win
		}
		-spacing {
		    #
		    # Adjust the line spacing and save val in data($opt)
		    #
		    set w $data(body)
		    set pixVal [winfo pixels $w $val]
		    if {$pixVal < 0} {
			set pixVal 0
		    }
		    set selectBd [winfo pixels $w $data(-selectborderwidth)]
		    if {$selectBd < 0} {
			set selectBd 0
		    }
		    $w configure -spacing1 [expr {$pixVal + $selectBd}] \
			-spacing3 [expr {$pixVal + $selectBd + !$data(-tight)}]
		    set data($opt) $val
		    redisplayWhenIdle $win
		    updateViewWhenIdle $win
		}
		-state {
		    #
		    # Apply the value to all labels and their sublabels
		    # (if any), as well as to the edit window (if present),
		    # add/remove the "disabled" tag to/from the contents
		    # of the body text widget, configure the borderwidth
		    # of the "active" and "select" tags, save the
		    # properly formatted value of val in data($opt),
		    # and raise the corresponding arrow in the canvas
		    #
		    variable states
		    set val [mwutil::fullOpt "state" $val $states]
		    catch {
			configLabel $data(hdrFrmLbl) $opt $val
			configLabel $data(cornerLbl) $opt $val
			for {set col 0} {$col < $data(colCount)} {incr col} {
			    configLabel $data(hdrTxtFrmLbl)$col $opt $val
			}
		    }
		    if {$data(editRow) >= 0} {
			catch {$data(bodyFrmEd) configure $opt $val}
		    }
		    set w $data(body)
		    switch $val {
			disabled {
			    $w tag add disabled 1.0 end
			    $w tag configure select -relief flat
			    $w tag configure curRow -relief flat
			    set data(isDisabled) 1
			}
			normal {
			    $w tag remove disabled 1.0 end
			    $w tag configure select -relief raised
			    $w tag configure curRow -relief raised
			    set data(isDisabled) 0
			}
		    }
		    set data($opt) $val
		    foreach col $data(arrowColList) {
			configCanvas $win $col
			raiseArrow $win $col
		    }
		    updateColorsWhenIdle $win
		}
		-stretch {
		    #
		    # Save the properly formatted value of val in
		    # data($opt) and stretch the stretchable columns
		    #
		    if {[string first $val "all"] == 0} {
			set data($opt) all
		    } else {
			set data($opt) $val
			sortStretchableColList $win
		    }
		    set data(forceAdjust) 1
		    stretchColumnsWhenIdle $win
		}
		-stripebackground -
		-stripeforeground {
		    #
		    # Configure the "stripe" tag in the body text
		    # widget, save the properly formatted value of val
		    # in data($opt), and draw the stripes if necessary
		    #
		    set w $data(body)
		    set optTail [string range $opt 7 end] ;# remove the -stripe
		    $w tag configure stripe -$optTail $val
		    set data($opt) [$w tag cget stripe -$optTail]
		    makeStripesWhenIdle $win
		}
		-stripeheight {
		    #
		    # Save the properly formatted value of val in
		    # data($opt) and draw the stripes if necessary
		    #
		    set val [format "%d" $val]	;# integer check with error msg
		    set data($opt) $val
		    makeStripesWhenIdle $win
		}
		-targetcolor {
		    #
		    # Set the color of the row and column gaps, and save
		    # the properly formatted value of val in data($opt)
		    #
		    $data(rowGap) configure -background $val
		    $data(colGap) configure -background $val
		    set data($opt) [$data(rowGap) cget -background]
		}
		-tight {
		    #
		    # Save the boolean value specified by val
		    # in data($opt) and adjust the line spacing
		    #
		    set data($opt) [expr {$val ? 1 : 0}]
		    set w $data(body)
		    set spacing1 [$w cget -spacing1]
		    $w configure -spacing3 [expr {$spacing1 + !$data($opt)}]
		    updateViewWhenIdle $win
		}
		-titlecolumns {
		    #
		    # Update the value of the -xscrollcommand option, save
		    # the properly formatted value of val in data($opt),
		    # and create or destroy the main separator if needed
		    #
		    set oldVal $data($opt)
		    set val [format "%d" $val]	;# integer check with error msg
		    if {$val < 0} {
			set val 0
		    }
		    xviewSubCmd $win 0
		    set w $data(vsep)
		    if {$val == 0} {
			$data(hdrTxt) configure -xscrollcommand \
				      $data(-xscrollcommand)
			if {$oldVal > 0} {
			    destroy $w
			}
		    } else {
			$data(hdrTxt) configure -xscrollcommand ""
			if {$oldVal == 0} {
			    if {$usingTile} {
				ttk::separator $w -style Sep$win.TSeparator \
						  -cursor $data(-cursor) \
						  -orient vertical -takefocus 0
			    } else {
				tk::frame $w -background $data(-foreground) \
					     -borderwidth 1 -container 0 \
					     -cursor $data(-cursor) \
					     -highlightthickness 0 \
					     -relief sunken -takefocus 0 \
					     -width 2
			    }
			    bindtags $w [lreplace [bindtags $w] 1 1 \
					 $data(bodyTag) TablelistBody]
			}
			adjustSepsWhenIdle $win
		    }
		    set data($opt) $val
		    updateHScrlbarWhenIdle $win
		}
		-treecolumn {
		    #
		    # Save the properly formatted value of val in
		    # data($opt), its adjusted value in data(treeCol),
		    # and move the tree images into the new tree column
		    #
		    set oldTreeCol $data(treeCol)
		    set newTreeCol [colIndex $win $val 0]
		    set data($opt) $newTreeCol
		    adjustColIndex $win newTreeCol
		    set data(treeCol) $newTreeCol
		    if {$data(colCount) != 0} {
			set data($opt) $newTreeCol
		    }
		    if {$newTreeCol != $oldTreeCol} {
			for {set row 0} {$row < $data(itemCount)} {incr row} {
			    doCellConfig $row $newTreeCol $win -indent \
				[doCellCget $row $oldTreeCol $win -indent]
			    doCellConfig $row $oldTreeCol $win -indent ""
			}
		    }
		}
		-treestyle {
		    #
		    # Update the tree images and save the properly
		    # formatted value of val in data($opt)
		    #
		    variable treeStyles
		    set newStyle [mwutil::fullOpt "tree style" $val $treeStyles]
		    set oldStyle $data($opt)
		    set treeCol $data(treeCol)
		    if {[string compare $newStyle $oldStyle] != 0} {
			${newStyle}TreeImgs 
			variable maxIndentDepths
			if {![info exists maxIndentDepths($newStyle)]} {
			    set maxIndentDepths($newStyle) 0
			}
			if {$data(colCount) != 0} {
			    for {set row 0} {$row < $data(itemCount)} \
				{incr row} {
				set oldImg \
				    [doCellCget $row $treeCol $win -indent]
				set newImg [strMap \
				    [list $oldStyle $newStyle "Sel" ""] $oldImg]
				if {[regexp {^.+Img([0-9]+)$} $newImg \
				     dummy depth]} {
				    if {$depth > $maxIndentDepths($newStyle)} {
					createTreeImgs $newStyle $depth
					set maxIndentDepths($newStyle) $depth
				    }
				    doCellConfig $row $treeCol $win \
						 -indent $newImg
				}
			    }
			}
		    }
		    set data($opt) $newStyle
		    switch -glob $newStyle {
			baghira -
			klearlooks -
			oxygen? -
			phase -
			plastik -
			vista* -
			winnative -
			winxp*		{ set data(protectIndents) 1 }
			default		{ set data(protectIndents) 0 }
		    }
		    set selCells [curCellSelection $win 1]
		    foreach {key col} $selCells {
			set row [keyToRow $win $key]
			cellSelection $win set $row $col $row $col
		    }
		    if {$data(ownsFocus) && ![info exists data(dispId)]} {
			addActiveTag $win
		    }
		}
		-width {
		    #
		    # Adjust the widths of the body text widget,
		    # header frame, and listbox child, and save the
		    # properly formatted value of val in data($opt)
		    #
		    set val [format "%d" $val]	;# integer check with error msg
		    $data(body) configure $opt $val
		    if {$val <= 0} {
			$data(hdr) configure $opt $data(hdrPixels)
			$data(lb) configure $opt \
				  [expr {$data(hdrPixels) / $data(charWidth)}]
		    } else {
			$data(hdr) configure $opt 0
			$data(lb) configure $opt $val
		    }
		    set data($opt) $val
		}
		-xscrollcommand {
		    #
		    # Save val in data($opt), and apply it to the header text
		    # widget if (and only if) no title columns are being used
		    #
		    set data($opt) $val
		    if {$data(-titlecolumns) == 0} {
			$data(hdrTxt) configure $opt $val
		    } else {
			$data(hdrTxt) configure $opt ""
		    }
		}
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::doCget
#
# Returns the value of the configuration option opt for the tablelist widget
# win.
#------------------------------------------------------------------------------
proc tablelist::doCget {win opt} {
    upvar ::tablelist::ns${win}::data data
    if {[string compare $opt "-columntitles"] == 0} {
	set colTitles {}
	foreach {width title alignment} $data(-columns) {
	    lappend colTitles $title
	}
	return $colTitles
    } else {
	return $data($opt)
    }
}

#------------------------------------------------------------------------------
# tablelist::doColConfig
#
# Applies the value val of the column configuration option opt to the col'th
# column of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::doColConfig {col win opt val} {
    variable canElide
    upvar ::tablelist::ns${win}::data data

    switch -- $opt {
	-align {
	    #
	    # Set up and adjust the columns, and make sure the
	    # given column will be redisplayed at idle time
	    #
	    set idx [expr {3*$col + 2}]
	    setupColumns $win [lreplace $data(-columns) $idx $idx $val] 0
	    adjustColumns $win {} 0
	    redisplayColWhenIdle $win $col
	}

	-background -
	-foreground {
	    set w $data(body)
	    set name $col$opt

	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		}
	    } else {
		#
		# Configure the tag col$opt-$val in the body text widget
		#
		set tag col$opt-$val
		$w tag configure $tag $opt $val
		$w tag lower $tag

		#
		# Save val in data($name)
		#
		set data($name) $val
	    }

	    if {!$data(isDisabled)} {
		updateColorsWhenIdle $win
	    }
	}

	-changesnipside -
	-wrap {
	    #
	    # Save the boolean value specified by val in data($col$opt) and
	    # make sure the given column will be redisplayed at idle time
	    #
	    set data($col$opt) [expr {$val ? 1 : 0}]
	    if {[lindex $data(-columns) [expr {3*$col}]] != 0} {
		redisplayColWhenIdle $win $col
		updateViewWhenIdle $win
	    }
	}

	-changetitlesnipside {
	    #
	    # Save the boolean value specified by val in
	    # data($col$opt) and adjust the col'th label
	    #
	    set data($col$opt) [expr {$val ? 1 : 0}]
	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    if {$pixels == 0} {			;# convention: dynamic width
		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set pixels $data($col-maxPixels)
		    }
		}
	    }
	    if {$pixels != 0} {	
		incr pixels $data($col-delta)
	    }
	    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
	    adjustLabel $win $col $pixels $alignment
	}

	-editable {
	    #
	    # Save the boolean value specified by val in data($col$opt)
	    # and invoke the motion handler if necessary
	    #
	    set data($col$opt) [expr {$val ? 1 : 0}]
	    if {$data(-showeditcursor)} {
		invokeMotionHandler $win
	    }
	}

	-editwindow {
	    variable editWin
	    if {[info exists editWin($val-creationCmd)]} {
		set data($col$opt) $val
	    } else {
		return -code error "name \"$val\" is not registered\
				    for interactive cell editing"
	    }
	}

	-font {
	    set w $data(body)
	    set name $col$opt

	    if {[info exists data($name)] &&
		(!$data($col-hide) || $canElide)} {
		#
		# Remove the tag col$opt-$data($name)
		# from the elements of the given column
		#
		set tag col$opt-$data($name)
		for {set line 1} {$line <= $data(itemCount)} {incr line} {
		    findTabs $win $line $col $col tabIdx1 tabIdx2
		    $w tag remove $tag $tabIdx1 $tabIdx2+1c
		}
	    }

	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		}
	    } else {
		#
		# Configure the tag col$opt-$val in the body text widget
		#
		set tag col$opt-$val
		$w tag configure $tag $opt $val
		$w tag lower $tag

		if {!$data($col-hide) || $canElide} {
		    #
		    # Apply the tag to the elements of the given column
		    #
		    for {set line 1} {$line <= $data(itemCount)} {incr line} {
			findTabs $win $line $col $col tabIdx1 tabIdx2
			$w tag add $tag $tabIdx1 $tabIdx2+1c
		    }
		}

		#
		# Save val in data($name)
		#
		set data($name) $val
	    }

	    #
	    # Rebuild the lists of the column fonts and tag names
	    #
	    makeColFontAndTagLists $win

	    #
	    # Adjust the columns, and make sure the specified
	    # column will be redisplayed at idle time
	    #
	    adjustColumns $win $col 1
	    redisplayColWhenIdle $win $col
	    updateViewWhenIdle $win

	    if {$col == $data(editCol)} {
		#
		# Configure the edit window
		#
		setEditWinFont $win
	    }
	}

	-formatcommand {
	    if {[string length $val] == 0} {
		if {[info exists data($col$opt)]} {
		    unset data($col$opt)
		}
		set fmtCmdFlag 0
	    } else {
		set data($col$opt) $val
		set fmtCmdFlag 1
	    }

	    #
	    # Update the corresponding element of the list data(fmtCmdFlagList)
	    #
	    set data(fmtCmdFlagList) \
		[lreplace $data(fmtCmdFlagList) $col $col $fmtCmdFlag]
	    set data(hasFmtCmds) \
		[expr {[lsearch -exact $data(fmtCmdFlagList) 1] >= 0}]

	    #
	    # Adjust the columns and make sure the specified
	    # column will be redisplayed at idle time
	    #
	    adjustColumns $win $col 1
	    redisplayColWhenIdle $win $col
	    updateViewWhenIdle $win
	}

	-hide {
	    #
	    # Save the boolean value specified by val in data($col$opt),
	    # adjust the columns, and redisplay the items
	    #
	    set oldVal $data($col$opt)
	    set newVal [expr {$val ? 1 : 0}]
	    if {$newVal != $oldVal} {
		if {!$canElide} {
		    set selCells [curCellSelection $win]
		}
		set data($col$opt) $newVal
		if {$newVal} {				;# hiding the column
		    incr data(hiddenColCount)
		    adjustColIndex $win data(anchorCol) 1
		    adjustColIndex $win data(activeCol) 1
		    if {$col == $data(editCol)} {
			doCancelEditing $win
		    }
		} else {
		    incr data(hiddenColCount) -1
		}
		makeColFontAndTagLists $win
		adjustColumns $win $col 1
		if {!$canElide} {
		    redisplay $win 0 $selCells
		    if {!$newVal &&
			[string compare $data(-selecttype) "row"] == 0} {
			foreach row [curSelection $win] {
			    rowSelection $win set $row $row
			}
		    }
		}
		updateViewWhenIdle $win

		genVirtualEvent $win <<TablelistColHiddenStateChanged>> $col
	    }
	}

	-labelalign {
	    if {[string length $val] == 0} {
		#
		# Unset data($col$opt)
		#
		set alignment [lindex $data(colList) [expr {2*$col + 1}]]
		if {[info exists data($col$opt)]} {
		    unset data($col$opt)
		}
	    } else {
		#
		# Save the properly formatted value of val in data($col$opt)
		#
		variable alignments
		set val [mwutil::fullOpt "label alignment" $val $alignments]
		set alignment $val
		set data($col$opt) $val
	    }

	    #
	    # Adjust the col'th label
	    #
	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    if {$pixels == 0} {			;# convention: dynamic width
		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set pixels $data($col-maxPixels)
		    }
		}
	    }
	    if {$pixels != 0} {	
		incr pixels $data($col-delta)
	    }
	    adjustLabel $win $col $pixels $alignment
	}

	-labelbackground -
	-labelforeground {
	    set w $data(hdrTxtFrmLbl)$col
	    set optTail [string range $opt 6 end]	;# remove the -label
	    if {[string length $val] == 0} {
		#
		# Apply the value of the corresponding widget
		# configuration option to the col'th label and
		# its sublabels (if any), and unset data($col$opt)
		#
		configLabel $w -$optTail $data($opt)
		if {[info exists data($col$opt)]} {
		    unset data($col$opt)
		}
	    } else {
		#
		# Apply the given value to the col'th label and
		# its sublabels (if any), and save the properly
		# formatted value of val in data($col$opt)
		#
		configLabel $w -$optTail $val
		variable helpLabel
		$helpLabel configure -$optTail $val
		set data($col$opt) [$helpLabel cget -$optTail]
	    }

	    if {[lsearch -exact $data(arrowColList) $col] >= 0} {
		configCanvas $win $col
	    }
	}

	-labelborderwidth {
	    set w $data(hdrTxtFrmLbl)$col
	    set optTail [string range $opt 6 end]	;# remove the -label
	    if {[string length $val] == 0} {
		#
		# Apply the value of the corresponding widget configuration
		# option to the col'th label and unset data($col$opt)
		#
		configLabel $w -$optTail $data($opt)
		if {[info exists data($col$opt)]} {
		    unset data($col$opt)
		}
	    } else {
		#
		# Apply the given value to the col'th label and save the
		# properly formatted value of val in data($col$opt)
		#
		configLabel $w -$optTail $val
		set data($col$opt) [$w cget -$optTail]
	    }

	    #
	    # Adjust the columns (including the height of the header frame)
	    #
	    adjustColumns $win l$col 1
	}

	-labelcommand -
	-labelcommand2 -
	-name -
	-sortcommand {
	    if {[string length $val] == 0} {
		if {[info exists data($col$opt)]} {
		    unset data($col$opt)
		}
	    } else {
		set data($col$opt) $val
	    }
	}

	-labelfont {
	    set w $data(hdrTxtFrmLbl)$col
	    set optTail [string range $opt 6 end]	;# remove the -label
	    if {[string length $val] == 0} {
		#
		# Apply the value of the corresponding widget
		# configuration option to the col'th label and
		# its sublabels (if any), and unset data($col$opt)
		#
		configLabel $w -$optTail $data($opt)
		if {[info exists data($col$opt)]} {
		    unset data($col$opt)
		}
	    } else {
		#
		# Apply the given value to the col'th label and
		# its sublabels (if any), and save the properly
		# formatted value of val in data($col$opt)
		#
		configLabel $w -$optTail $val
		set data($col$opt) [$w cget -$optTail]
	    }

	    #
	    # Adjust the columns (including the height of the header frame)
	    #
	    adjustColumns $win l$col 1
	}

	-labelheight -
	-labelpady {
	    set w $data(hdrTxtFrmLbl)$col
	    set optTail [string range $opt 6 end]	;# remove the -label
	    if {[string length $val] == 0} {
		#
		# Apply the value of the corresponding widget configuration
		# option to the col'th label and unset data($col$opt)
		#
		configLabel $w -$optTail $data($opt)
		if {[info exists data($col$opt)]} {
		    unset data($col$opt)
		}
	    } else {
		#
		# Apply the given value to the col'th label and save the
		# properly formatted value of val in data($col$opt)
		#
		configLabel $w -$optTail $val
		variable usingTile
		if {$usingTile} {
		    set data($col$opt) $val
		} else {
		    set data($col$opt) [$w cget -$optTail]
		}
	    }

	    #
	    # Adjust the height of the header frame
	    #
	    adjustHeaderHeight $win
	}

	-labelimage {
	    set w $data(hdrTxtFrmLbl)$col
	    if {[string length $val] == 0} {
		foreach l [getSublabels $w] {
		    destroy $l
		}
		if {[info exists data($col$opt)]} {
		    unset data($col$opt)
		}
	    } else {
		if {![winfo exists $w-il]} {
		    variable configSpecs
		    variable configOpts
		    foreach l [list $w-il $w-tl] {	;# image and text labels
			#
			# Create the label $l
			#
			tk::label $l -borderwidth 0 -height 0 \
				     -highlightthickness 0 -padx 0 \
				     -pady 0 -takefocus 0 -width 0

			#
			# Apply to it the current configuration options
			#
			foreach opt2 $configOpts {
			    if {[string compare \
				 [lindex $configSpecs($opt2) 2] "c"] == 0} {
				$l configure $opt2 $data($opt2)
			    }
			}
			if {[string compare [winfo class $w] "TLabel"] == 0} {
			    variable themeDefaults
			    $l configure -background \
					 $themeDefaults(-labelbackground)
			} else {
			    $l configure -background [$w cget -background]
			    $l configure -foreground [$w cget -foreground]
			}
			$l configure -font [$w cget -font]
			foreach opt2 {-activebackground -activeforeground
				      -disabledforeground -state} {
			    catch {$l configure $opt2 [$w cget $opt2]}
			}

			#
			# Replace the binding tag Label with $w,
			# $data(labelTag), and TablelistSubLabel in
			# the list of binding tags of the label $l
			#
			bindtags $l [lreplace [bindtags $l] 1 1 \
				     $w $data(labelTag) TablelistSubLabel]
		    }
		}

		#
		# Display the specified image in the label
		# $w-il and save val in data($col$opt)
		#
		$w-il configure -image $val
		set data($col$opt) $val
	    }

	    #
	    # Adjust the columns (including the height of the header frame)
	    #
	    adjustColumns $win l$col 1
	}

	-labelrelief {
	    set w $data(hdrTxtFrmLbl)$col
	    set optTail [string range $opt 6 end]	;# remove the -label
	    if {[string length $val] == 0} {
		#
		# Apply the value of the corresponding widget configuration
		# option to the col'th label and unset data($col$opt)
		#
		configLabel $w -$optTail $data($opt)
		if {[info exists data($col$opt)]} {
		    unset data($col$opt)
		}
	    } else {
		#
		# Apply the given value to the col'th label and save the
		# properly formatted value of val in data($col$opt)
		#
		configLabel $w -$optTail $val
		set data($col$opt) [$w cget -$optTail]
	    }
	}

	-maxwidth {
	    #
	    # Save the properly formatted value of val in
	    # data($col$opt), adjust the columns, and make sure
	    # the specified column will be redisplayed at idle time
	    #
	    set val [format "%d" $val]	;# integer check with error message
	    set data($col$opt) $val
	    if {$val > 0} {		;# convention: max. width in characters
		set pixels [charsToPixels $win $data(-font) $val]
	    } elseif {$val < 0} {	;# convention: max. width in pixels
		set pixels [expr {(-1)*$val}]
	    } else {			;# convention: no max. width
		set pixels 0
	    }
	    set data($col-maxPixels) $pixels
	    adjustColumns $win $col 1
	    redisplayColWhenIdle $win $col
	    updateViewWhenIdle $win
	}

	-resizable {
	    #
	    # Save the boolean value specified by val in data($col$opt)
	    #
	    set data($col$opt) [expr {$val ? 1 : 0}]
	}

	-selectbackground -
	-selectforeground {
	    set w $data(body)
	    set name $col$opt

	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		}
	    } else {
		#
		# Configure the tag col$opt-$val in the body text widget
		#
		set tag col$opt-$val
		set optTail [string range $opt 7 end]	;# remove the -select
		$w tag configure $tag -$optTail $val
		$w tag raise $tag select

		#
		# Save val in data($name)
		#
		set data($name) $val
	    }

	    if {!$data(isDisabled)} {
		updateColorsWhenIdle $win
	    }
	}

	-showarrow {
	    #
	    # Save the boolean value specified by val in data($col$opt) and
	    # manage or unmanage the canvas displaying an up- or down-arrow
	    #
	    set data($col$opt) [expr {$val ? 1 : 0}]
	    makeSortAndArrowColLists $win
	    adjustColumns $win l$col 1
	}

	-showlinenumbers {
	    #
	    # Save the boolean value specified by val in
	    # data($col$opt), and make sure the line numbers
	    # will be redisplayed at idle time if needed
	    #
	    set val [expr {$val ? 1 : 0}]
	    if {!$data($col$opt) && $val} {
		showLineNumbersWhenIdle $win
	    }
	    set data($col$opt) $val
	}

	-sortmode {
	    #
	    # Save the properly formatted value of val in data($col$opt)
	    #
	    variable sortModes
	    set data($col$opt) [mwutil::fullOpt "sort mode" $val $sortModes]
	}

	-stretchable {
	    set flag [expr {$val ? 1 : 0}]
	    if {$flag} {
		if {[string compare $data(-stretch) "all"] != 0 &&
		    [lsearch -exact $data(-stretch) $col] < 0} {
		    #
		    # col was not found in data(-stretch): add it to the list
		    #
		    lappend data(-stretch) $col
		    sortStretchableColList $win
		    set data(forceAdjust) 1
		    stretchColumnsWhenIdle $win
		}
	    } elseif {[string compare $data(-stretch) "all"] == 0} {
		#
		# Replace the value "all" of data(-stretch) with
		# the list of all column indices different from col
		#
		set data(-stretch) {}
		for {set n 0} {$n < $data(colCount)} {incr n} {
		    if {$n != $col} {
			lappend data(-stretch) $n
		    }
		}
		set data(forceAdjust) 1
		stretchColumnsWhenIdle $win
	    } else {
		#
		# If col is contained in data(-stretch)
		# then remove it from the list
		#
		if {[set n [lsearch -exact $data(-stretch) $col]] >= 0} {
		    set data(-stretch) [lreplace $data(-stretch) $n $n]
		    set data(forceAdjust) 1
		    stretchColumnsWhenIdle $win
		}

		#
		# If col indicates the last column and data(-stretch)
		# contains "end" then remove "end" from the list
		#
		if {$col == $data(lastCol) &&
		    [string compare [lindex $data(-stretch) end] "end"] == 0} {
		    set data(-stretch) [lreplace $data(-stretch) end end]
		    set data(forceAdjust) 1
		    stretchColumnsWhenIdle $win
		}
	    }
	}

	-stripebackground -
	-stripeforeground {
	    set w $data(body)
	    set name $col$opt

	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		}
	    } else {
		#
		# Configure the tag col$opt-$val in the body text widget
		#
		set tag col$opt-$val
		set optTail [string range $opt 7 end]	;# remove the -stripe
		$w tag configure $tag -$optTail $val
		$w tag raise $tag stripe

		#
		# Save val in data($name)
		#
		set data($name) $val
	    }

	    if {!$data(isDisabled)} {
		updateColorsWhenIdle $win
	    }
	}

	-text {
	    if {$data(isDisabled) || $data($col-showlinenumbers)} {
		return ""
	    }

	    #
	    # Replace the column's contents in the internal list
	    #
	    set newItemList {}
	    set row 0
	    foreach item $data(itemList) text [lrange $val 0 $data(lastRow)] {
		set item [lreplace $item $col $col $text]
		lappend newItemList $item
	    }
	    set data(itemList) $newItemList

	    #
	    # Update the list variable if present
	    #
	    condUpdateListVar $win

	    #
	    # Adjust the columns and make sure the specified
	    # column will be redisplayed at idle time
	    #
	    adjustColumns $win $col 1
	    redisplayColWhenIdle $win $col
	    updateViewWhenIdle $win
	}

	-title {
	    #
	    # Save the given value in the corresponding
	    # element of data(-columns) and adjust the columns
	    #
	    set idx [expr {3*$col + 1}]
	    set data(-columns) [lreplace $data(-columns) $idx $idx $val]
	    adjustColumns $win l$col 1
	}

	-valign {
	    #
	    # Save the properly formatted value of val in data($col$opt) and
	    # make sure the given column will be redisplayed at idle time
	    #
	    variable valignments
	    set val [mwutil::fullOpt "vertical alignment" $val $valignments]
	    if {[string compare $val $data($col$opt)] != 0} {
		set data($col$opt) $val
		redisplayColWhenIdle $win $col
	    }
	}

	-width {
	    #
	    # Set up and adjust the columns, and make sure the
	    # given column will be redisplayed at idle time
	    #
	    set idx [expr {3*$col}]
	    if {$val != [lindex $data(-columns) $idx]} {
		setupColumns $win [lreplace $data(-columns) $idx $idx $val] 0
		redisplayColWhenIdle $win $col	;# here before adjustColumns!
		adjustColumns $win $col 1
		updateViewWhenIdle $win
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::doColCget
#
# Returns the value of the column configuration option opt for the col'th
# column of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::doColCget {col win opt} {
    upvar ::tablelist::ns${win}::data data

    switch -- $opt {
	-align {
	    return [lindex $data(-columns) [expr {3*$col + 2}]]
	}

	-stretchable {
	    return [expr {
		[string compare $data(-stretch) "all"] == 0 ||
		[lsearch -exact $data(-stretch) $col] >= 0 ||
		($col == $data(lastCol) && \
		 [string compare [lindex $data(-stretch) end] "end"] == 0)
	    }]
	}

	-text {
	    set result {}
	    foreach item $data(itemList) {
		lappend result [lindex $item $col]
	    }
	    return $result
	}

	-title {
	    return [lindex $data(-columns) [expr {3*$col + 1}]]
	}

	-width {
	    return [lindex $data(-columns) [expr {3*$col}]]
	}

	default {
	    if {[info exists data($col$opt)]} {
		return $data($col$opt)
	    } else {
		return ""
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::doRowConfig
#
# Applies the value val of the row configuration option opt to the row'th row
# of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::doRowConfig {row win opt val} {
    variable canElide
    variable elide
    variable snipSides
    upvar ::tablelist::ns${win}::data data

    set w $data(body)

    switch -- $opt {
	-background -
	-foreground {
	    set key [lindex $data(keyList) $row]
	    set name $key$opt

	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		}
	    } else {
		#
		# Configure the tag row$opt-$val in the body text widget
		#
		set tag row$opt-$val
		$w tag configure $tag $opt $val
		$w tag lower $tag active

		#
		# Save val in data($name)
		#
		set data($name) $val
	    }

	    if {!$data(isDisabled)} {
		updateColorsWhenIdle $win
	    }
	}

	-elide {
	    set val [expr {$val ? 1 : 0}]
	    set item [lindex $data(itemList) $row]
	    set key [lindex $item end]
	    set name $key$opt
	    set line [expr {$row + 1}]
	    set viewChanged 0

	    if {$val} {					;# eliding the row
		if {![info exists data($name)]} {
		    set data($name) 1
		    $w tag add elidedRow $line.0 $line.end+1c

		    if {![info exists data($key-hide)]} {
			incr data(nonViewableRowCount)
			set viewChanged 1

			if {$row == $data(editRow)} {
			    doCancelEditing $win
			}
		    }
		}
	    } else {					;# uneliding the row
		if {[info exists data($name)]} {
		    unset data($name)
		    $w tag remove elidedRow $line.0 $line.end+1c

		    if {![info exists data($key-hide)]} {
			incr data(nonViewableRowCount) -1
			set viewChanged 1
		    }
		}
	    }

	    if {$viewChanged} {
		#
		# Adjust the heights of the body text widget
		# and of the listbox child, if necessary
		#
		if {$data(-height) <= 0} {
		    set viewableRowCount \
			[expr {$data(itemCount) - $data(nonViewableRowCount)}]
		    $w configure -height $viewableRowCount
		    $data(lb) configure -height $viewableRowCount
		}

		#
		# Build the list of those dynamic-width columns
		# whose widths are affected by (un)eliding the row
		#
		set colWidthsChanged 0
		set colIdxList {}
		set displayedItem [lrange $item 0 $data(lastCol)]
		if {$data(hasFmtCmds)} {
		    set displayedItem [formatItem $win $key $row $displayedItem]
		}
		if {[string match "*\t*" $displayedItem]} {
		    set displayedItem [mapTabs $displayedItem]
		}
		set col 0
		foreach text $displayedItem {pixels alignment} $data(colList) {
		    if {($data($col-hide) && !$canElide) || $pixels != 0} {
			incr col
			continue
		    }

		    getAuxData $win $key $col auxType auxWidth
		    getIndentData $win $key $col indentWidth
		    set cellFont [getCellFont $win $key $col]
		    set elemWidth [getElemWidth $win $text $auxWidth \
				   $indentWidth $cellFont]
		    if {$val} {				;# eliding the row
			if {$elemWidth == $data($col-elemWidth) &&
			    [incr data($col-widestCount) -1] == 0} {
			    set colWidthsChanged 1
			    lappend colIdxList $col
			}
		    } else {				;# uneliding the row
			if {$elemWidth == $data($col-elemWidth)} {
			    incr data($col-widestCount)
			} elseif {$elemWidth > $data($col-elemWidth)} {
			    set data($col-elemWidth) $elemWidth
			    set data($col-widestCount) 1
			    if {$elemWidth > $data($col-reqPixels)} {
				set data($col-reqPixels) $elemWidth
				set colWidthsChanged 1
			    }
			}
		    }

		    incr col
		}

		#
		# Invalidate the list of row indices indicating the
		# viewable rows and adjust the columns if necessary
		#
		set data(viewableRowList) {-1}
		if {$colWidthsChanged} {
		    adjustColumns $win $colIdxList 1
		}
	    }
	}

	-font {
	    #
	    # Save the current cell fonts in a temporary array
	    #
	    set item [lindex $data(itemList) $row]
	    set key [lindex $item end]
	    for {set col 0} {$col < $data(colCount)} {incr col} {
		set oldCellFonts($col) [getCellFont $win $key $col]
	    }

	    set name $key$opt
	    if {[info exists data($name)]} {
		#
		# Remove the tag row$opt-$data($name) from the given row
		#
		set line [expr {$row + 1}]
		$w tag remove row$opt-$data($name) $line.0 $line.end
	    }

	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		    incr data(rowTagRefCount) -1
		}
	    } else {
		#
		# Configure the tag row$opt-$val in the body
		# text widget and apply it to the given row
		#
		set tag row$opt-$val
		$w tag configure $tag $opt $val
		$w tag lower $tag active
		set line [expr {$row + 1}]
		$w tag add $tag $line.0 $line.end

		#
		# Save val in data($name)
		#
		if {![info exists data($name)]} {
		    incr data(rowTagRefCount)
		}
		set data($name) $val
	    }

	    set displayedItem [lrange $item 0 $data(lastCol)]
	    if {$data(hasFmtCmds)} {
		set displayedItem [formatItem $win $key $row $displayedItem]
	    }
	    if {[string match "*\t*" $displayedItem]} {
		set displayedItem [mapTabs $displayedItem]
	    }
	    set colWidthsChanged 0
	    set colIdxList {}
	    set line [expr {$row + 1}]
	    set textIdx1 $line.1
	    set col 0
	    foreach text $displayedItem {pixels alignment} $data(colList) {
		if {$data($col-hide) && !$canElide} {
		    incr col
		    continue
		}

		#
		# Adjust the cell text and the image or window width
		#
		set multiline [string match "*\n*" $text]
		set cellFont [getCellFont $win $key $col]
		set workPixels $pixels
		if {$pixels == 0} {		;# convention: dynamic width
		    set textSav $text
		    getAuxData $win $key $col auxType auxWidthSav
		    getIndentData $win $key $col indentWidthSav

		    if {$data($col-maxPixels) > 0} {
			if {$data($col-reqPixels) > $data($col-maxPixels)} {
			    set workPixels $data($col-maxPixels)
			}
		    }
		}
		set aux [getAuxData $win $key $col auxType auxWidth $workPixels]
		set indent [getIndentData $win $key $col indentWidth]
		set maxTextWidth $workPixels
		if {$workPixels != 0} {
		    incr workPixels $data($col-delta)
		    set maxTextWidth \
			[getMaxTextWidth $workPixels $auxWidth $indentWidth]

		    if {$data($col-wrap) && !$multiline} {
			if {[font measure $cellFont -displayof $win $text] >
			    $maxTextWidth} {
			    set multiline 1
			}
		    }
		}
		set snipSide $snipSides($alignment,$data($col-changesnipside))
		if {$multiline} {
		    set list [split $text "\n"]
		    if {$data($col-wrap)} {
			set snipSide ""
		    }
		    adjustMlElem $win list auxWidth indentWidth $cellFont \
				 $workPixels $snipSide $data(-snipstring)
		    set msgScript [list ::tablelist::displayText $win $key \
				   $col [join $list "\n"] $cellFont \
				   $maxTextWidth $alignment]
		} else {
		    adjustElem $win text auxWidth indentWidth $cellFont \
			       $workPixels $snipSide $data(-snipstring)
		}

		if {$row == $data(editRow) && $col == $data(editCol)} {
		    #
		    # Configure the edit window
		    #
		    setEditWinFont $win
		} else {
		    #
		    # Update the text widget's contents between the two tabs
		    #
		    set textIdx2 [$w search $elide "\t" $textIdx1 $line.end]
		    if {$multiline} {
			updateMlCell $w $textIdx1 $textIdx2 $msgScript $aux \
				     $auxType $auxWidth $indent $indentWidth \
				     $alignment [getVAlignment $win $key $col]
		    } else {
			updateCell $w $textIdx1 $textIdx2 $text $aux \
				   $auxType $auxWidth $indent $indentWidth \
				   $alignment [getVAlignment $win $key $col]
		    }
		}

		if {$pixels == 0 && ![info exists data($key-elide)] &&
		    ![info exists data($key-hide)]} {
		    #
		    # Check whether the width of the current column has changed
		    #
		    set text $textSav
		    set auxWidth $auxWidthSav
		    set indentWidth $indentWidthSav
		    set newElemWidth [getElemWidth $win $text $auxWidth \
				      $indentWidth $cellFont]
		    if {$newElemWidth > $data($col-elemWidth)} {
			set data($col-elemWidth) $newElemWidth
			set data($col-widestCount) 1
			if {$newElemWidth > $data($col-reqPixels)} {
			    set data($col-reqPixels) $newElemWidth
			    set colWidthsChanged 1
			}
		    } else {
			set oldElemWidth [getElemWidth $win $text $auxWidth \
					  $indentWidth $oldCellFonts($col)]
			if {$oldElemWidth < $data($col-elemWidth) &&
			    $newElemWidth == $data($col-elemWidth)} {
			    incr data($col-widestCount)
			} elseif {$oldElemWidth == $data($col-elemWidth) &&
				  $newElemWidth < $oldElemWidth &&
				  [incr data($col-widestCount) -1] == 0} {
			    set colWidthsChanged 1
			    lappend colIdxList $col
			}
		    }
		}

		set textIdx1 [$w search $elide "\t" $textIdx1 $line.end]+2c
		incr col
	    }

	    #
	    # Adjust the columns if necessary and schedule
	    # some operations for execution at idle time
	    #
	    if {$colWidthsChanged} {
		adjustColumns $win $colIdxList 1
	    }
	    updateViewWhenIdle $win
	}

	-hide {
	    set val [expr {$val ? 1 : 0}]
	    set item [lindex $data(itemList) $row]
	    set key [lindex $item end]
	    set name $key$opt
	    set line [expr {$row + 1}]
	    set viewChanged 0
	    set callerProc [lindex [info level -1] 0]

	    if {$val} {					;# hiding the row
		if {![info exists data($name)]} {
		    set data($name) 1
		    $w tag add hiddenRow $line.0 $line.end+1c

		    if {![info exists data($key-elide)]} {
			incr data(nonViewableRowCount)
			set viewChanged 1

			#
			# Elide the descendants of this item
			#
			set fromRow [expr {$row + 1}]
			set toRow [nodeRow $win $key end]
			for {set _row $fromRow} {$_row < $toRow} {incr _row} {
			    doRowConfig $_row $win -elide 1
			}

			if {[string match "*configureWidget" $callerProc]} {
			    adjustRowIndex $win data(anchorRow) 1

			    set activeRow $data(activeRow)
			    adjustRowIndex $win activeRow 1
			    set data(activeRow) $activeRow
			}

			if {$row == $data(editRow)} {
			    doCancelEditing $win
			}
		    }
		}
	    } else {					;# unhiding the row
		if {[info exists data($name)]} {
		    unset data($name)
		    $w tag remove hiddenRow $line.0 $line.end+1c

		    if {![info exists data($key-elide)]} {
			incr data(nonViewableRowCount) -1
			set viewChanged 1

			if {[info exists data($key,$data(treeCol)-indent)] &&
			    [string match "*expanded*" \
			     $data($key,$data(treeCol)-indent)]} {
			    expandSubCmd $win [list $row -partly]
			}
		    }
		}
	    }

	    if {$viewChanged} {
		#
		# Adjust the heights of the body text widget
		# and of the listbox child, if necessary
		#
		if {$data(-height) <= 0} {
		    set viewableRowCount \
			[expr {$data(itemCount) - $data(nonViewableRowCount)}]
		    $w configure -height $viewableRowCount
		    $data(lb) configure -height $viewableRowCount
		}

		#
		# Build the list of those dynamic-width columns
		# whose widths are affected by (un)hiding the row
		#
		set colWidthsChanged 0
		set colIdxList {}
		set displayedItem [lrange $item 0 $data(lastCol)]
		if {$data(hasFmtCmds)} {
		    set displayedItem [formatItem $win $key $row $displayedItem]
		}
		if {[string match "*\t*" $displayedItem]} {
		    set displayedItem [mapTabs $displayedItem]
		}
		set col 0
		foreach text $displayedItem {pixels alignment} $data(colList) {
		    if {($data($col-hide) && !$canElide) || $pixels != 0} {
			incr col
			continue
		    }

		    getAuxData $win $key $col auxType auxWidth
		    getIndentData $win $key $col indentWidth
		    set cellFont [getCellFont $win $key $col]
		    set elemWidth [getElemWidth $win $text $auxWidth \
				   $indentWidth $cellFont]
		    if {$val} {				;# hiding the row
			if {$elemWidth == $data($col-elemWidth) &&
			    [incr data($col-widestCount) -1] == 0} {
			    set colWidthsChanged 1
			    lappend colIdxList $col
			}
		    } else {				;# unhiding the row
			if {$elemWidth == $data($col-elemWidth)} {
			    incr data($col-widestCount)
			} elseif {$elemWidth > $data($col-elemWidth)} {
			    set data($col-elemWidth) $elemWidth
			    set data($col-widestCount) 1
			    if {$elemWidth > $data($col-reqPixels)} {
				set data($col-reqPixels) $elemWidth
				set colWidthsChanged 1
			    }
			}
		    }

		    incr col
		}

		#
		# Invalidate the list of row indices indicating the
		# viewable rows and adjust the columns if necessary
		#
		set data(viewableRowList) {-1}
		if {$colWidthsChanged} {
		    adjustColumns $win $colIdxList 1
		}

		#
		# Schedule some operations for execution at idle time
		# and generate a virtual event only if the caller proc
		# is configureWidget, in order to make sure that only
		# one event per caller proc invocation will be generated
		#
		if {[string match "*configureWidget" $callerProc]} {
		    makeStripesWhenIdle $win
		    showLineNumbersWhenIdle $win
		    updateViewWhenIdle $win

		    genVirtualEvent $win <<TablelistRowHiddenStateChanged>> $row
		}
	    }
	}

	-name {
	    set key [lindex $data(keyList) $row]
	    if {[string length $val] == 0} {
		if {[info exists data($key$opt)]} {
		    unset data($key$opt)
		}
	    } else {
		set data($key$opt) $val
	    }
	}

	-selectable {
	    set val [expr {$val ? 1 : 0}]
	    set key [lindex $data(keyList) $row]

	    if {$val} {
		if {[info exists data($key$opt)]} {
		    unset data($key$opt)
		}
	    } else {
		#
		# Set data($key$opt) to 0 and deselect the row
		#
		set data($key$opt) 0
		rowSelection $win clear $row $row
	    }
	}

	-selectbackground -
	-selectforeground {
	    set key [lindex $data(keyList) $row]
	    set name $key$opt

	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		}
	    } else {
		#
		# Configure the tag row$opt-$val in the body text widget
		#
		set tag row$opt-$val
		set optTail [string range $opt 7 end]	;# remove the -select
		$w tag configure $tag -$optTail $val
		$w tag lower $tag active

		#
		# Save val in data($name)
		#
		set data($name) [$w tag cget $tag -$optTail]
	    }

	    if {!$data(isDisabled)} {
		updateColorsWhenIdle $win
	    }
	}

	-text {
	    if {$data(isDisabled)} {
		return ""
	    }

	    set colWidthsChanged 0
	    set colIdxList {}
	    set oldItem [lindex $data(itemList) $row]
	    set key [lindex $oldItem end]
	    set newItem [adjustItem $val $data(colCount)]
	    if {$data(hasFmtCmds)} {
		set displayedItem [formatItem $win $key $row $newItem]
	    } else {
		set displayedItem $newItem
	    }
	    if {[string match "*\t*" $displayedItem]} {
		set displayedItem [mapTabs $displayedItem]
	    }
	    set line [expr {$row + 1}]
	    set textIdx1 $line.1
	    set col 0
	    foreach text $displayedItem {pixels alignment} $data(colList) {
		if {$data($col-hide) && !$canElide} {
		    incr col
		    continue
		}

		#
		# Adjust the cell text and the image or window width
		#
		set multiline [string match "*\n*" $text]
		set cellFont [getCellFont $win $key $col]
		set workPixels $pixels
		if {$pixels == 0} {		;# convention: dynamic width
		    set textSav $text
		    getAuxData $win $key $col auxType auxWidthSav
		    getIndentData $win $key $col indentWidthSav

		    if {$data($col-maxPixels) > 0} {
			if {$data($col-reqPixels) > $data($col-maxPixels)} {
			    set workPixels $data($col-maxPixels)
			}
		    }
		}
		set aux [getAuxData $win $key $col auxType auxWidth $workPixels]
		set indent [getIndentData $win $key $col indentWidth]
		set maxTextWidth $workPixels
		if {$workPixels != 0} {
		    incr workPixels $data($col-delta)
		    set maxTextWidth \
			[getMaxTextWidth $workPixels $auxWidth $indentWidth]

		    if {$data($col-wrap) && !$multiline} {
			if {[font measure $cellFont -displayof $win $text] >
			    $maxTextWidth} {
			    set multiline 1
			}
		    }
		}
		set snipSide $snipSides($alignment,$data($col-changesnipside))
		if {$multiline} {
		    set list [split $text "\n"]
		    if {$data($col-wrap)} {
			set snipSide ""
		    }
		    adjustMlElem $win list auxWidth indentWidth $cellFont \
				 $workPixels $snipSide $data(-snipstring)
		    set msgScript [list ::tablelist::displayText $win $key \
				   $col [join $list "\n"] $cellFont \
				   $maxTextWidth $alignment]
		} else {
		    adjustElem $win text auxWidth indentWidth $cellFont \
			       $workPixels $snipSide $data(-snipstring)
		}

		if {$row != $data(editRow) || $col != $data(editCol)} {
		    #
		    # Update the text widget's contents between the two tabs
		    #
		    set textIdx2 [$w search $elide "\t" $textIdx1 $line.end]
		    if {$multiline} {
			updateMlCell $w $textIdx1 $textIdx2 $msgScript $aux \
				     $auxType $auxWidth $indent $indentWidth \
				     $alignment [getVAlignment $win $key $col]
		    } else {
			updateCell $w $textIdx1 $textIdx2 $text $aux \
				   $auxType $auxWidth $indent $indentWidth \
				   $alignment [getVAlignment $win $key $col]
		    }
		}

		if {$pixels == 0 && ![info exists data($key-elide)] &&
		    ![info exists data($key-hide)]} {
		    #
		    # Check whether the width of the current column has changed
		    #
		    set text $textSav
		    set auxWidth $auxWidthSav
		    set indentWidth $indentWidthSav
		    set newElemWidth [getElemWidth $win $text $auxWidth \
				      $indentWidth $cellFont]
		    if {$newElemWidth > $data($col-elemWidth)} {
			set data($col-elemWidth) $newElemWidth
			set data($col-widestCount) 1
			if {$newElemWidth > $data($col-reqPixels)} {
			    set data($col-reqPixels) $newElemWidth
			    set colWidthsChanged 1
			}
		    } else {
			set oldText [lindex $oldItem $col]
			if {[lindex $data(fmtCmdFlagList) $col]} {
			    set oldText \
				[formatElem $win $key $row $col $oldText]
			}
			if {[string match "*\t*" $oldText]} {
			    set oldText [mapTabs $oldText]
			}
			set oldElemWidth [getElemWidth $win $oldText $auxWidth \
					  $indentWidth $cellFont]
			if {$oldElemWidth < $data($col-elemWidth) &&
			    $newElemWidth == $data($col-elemWidth)} {
			    incr data($col-widestCount)
			} elseif {$oldElemWidth == $data($col-elemWidth) &&
				  $newElemWidth < $oldElemWidth &&
				  [incr data($col-widestCount) -1] == 0} {
			    set colWidthsChanged 1
			    lappend colIdxList $col
			}
		    }
		}

		set textIdx1 [$w search $elide "\t" $textIdx1 $line.end]+2c
		incr col
	    }

	    #
	    # Replace the row contents in the list variable if present
	    #
	    if {$data(hasListVar)} {
		upvar #0 $data(-listvariable) var
		trace vdelete var wu $data(listVarTraceCmd)
		set var [lreplace $var $row $row $newItem]
		trace variable var wu $data(listVarTraceCmd)
	    }

	    #
	    # Replace the row contents in the internal list
	    #
	    lappend newItem $key
	    set data(itemList) [lreplace $data(itemList) $row $row $newItem]

	    #
	    # Adjust the columns if necessary and schedule
	    # some operations for execution at idle time
	    #
	    if {$colWidthsChanged} {
		adjustColumns $win $colIdxList 1
	    }
	    showLineNumbersWhenIdle $win
	    updateViewWhenIdle $win
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::doRowCget
#
# Returns the value of the row configuration option opt for the row'th row of
# the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::doRowCget {row win opt} {
    upvar ::tablelist::ns${win}::data data
    set item [lindex $data(itemList) $row]

    switch -- $opt {
	-text {
	    return [lrange $item 0 $data(lastCol)]
	}

	-elide -
	-hide {
	    set key [lindex $item end]
	    if {[info exists data($key$opt)]} {
		return $data($key$opt)
	    } else {
		return 0
	    }
	}

	-selectable {
	    set key [lindex $item end]
	    if {[info exists data($key$opt)]} {
		return $data($key$opt)
	    } else {
		return 1
	    }
	}

	default {
	    set key [lindex $item end]
	    if {[info exists data($key$opt)]} {
		return $data($key$opt)
	    } else {
		return ""
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::doCellConfig
#
# Applies the value val of the cell configuration option opt to the cell
# row,col of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::doCellConfig {row col win opt val} {
    variable canElide
    variable snipSides
    upvar ::tablelist::ns${win}::data data

    set w $data(body)

    switch -- $opt {
	-background -
	-foreground {
	    set key [lindex $data(keyList) $row]
	    set name $key,$col$opt

	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		}
	    } else {
		#
		# Configure the tag cell$opt-$val in the body text widget
		#
		set tag cell$opt-$val
		$w tag configure $tag $opt $val
		$w tag lower $tag disabled

		#
		# Save val in data($name)
		#
		set data($name) $val
	    }

	    if {!$data(isDisabled)} {
		updateColorsWhenIdle $win
	    }
	}

	-editable {
	    #
	    # Save the boolean value specified by val in data($key,$col$opt)
	    # and invoke the motion handler if necessary
	    #
	    set key [lindex $data(keyList) $row]
	    set data($key,$col$opt) [expr {$val ? 1 : 0}]
	    if {$data(-showeditcursor)} {
		invokeMotionHandler $win
	    }
	}

	-editwindow {
	    variable editWin
	    if {[info exists editWin($val-creationCmd)]} {
		set key [lindex $data(keyList) $row]
		set data($key,$col$opt) $val
	    } else {
		return -code error "name \"$val\" is not registered\
				    for interactive cell editing"
	    }
	}

	-font {
	    #
	    # Save the current cell font
	    #
	    set item [lindex $data(itemList) $row]
	    set key [lindex $item end]
	    set name $key,$col$opt
	    set oldCellFont [getCellFont $win $key $col]

	    if {[info exists data($name)] &&
		(!$data($col-hide) || $canElide)} {
		#
		# Remove the tag cell$opt-$data($name) from the given cell
		#
		findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		$w tag remove cell$opt-$data($name) $tabIdx1 $tabIdx2+1c
	    }

	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		    incr data(cellTagRefCount) -1
		}
	    } else {
		#
		# Configure the tag cell$opt-$val in the body text widget
		#
		set tag cell$opt-$val
		$w tag configure $tag $opt $val
		$w tag lower $tag disabled

		if {!$data($col-hide) || $canElide} {
		    #
		    # Apply the tag to the given cell
		    #
		    findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		    $w tag add $tag $tabIdx1 $tabIdx2+1c
		}

		#
		# Save val in data($name)
		#
		if {![info exists data($name)]} {
		    incr data(cellTagRefCount)
		}
		set data($name) $val
	    }

	    #
	    # Adjust the cell text and the image or window width
	    #
	    set text [lindex $item $col]
	    if {[lindex $data(fmtCmdFlagList) $col]} {
		set text [formatElem $win $key $row $col $text]
	    }
	    if {[string match "*\t*" $text]} {
		set text [mapTabs $text]
	    }
	    set multiline [string match "*\n*" $text]
	    set cellFont [getCellFont $win $key $col]
	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    set workPixels $pixels
	    if {$pixels == 0} {			;# convention: dynamic width
		set textSav $text
		getAuxData $win $key $col auxType auxWidthSav
		getIndentData $win $key $col indentWidthSav

		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set workPixels $data($col-maxPixels)
		    }
		}
	    }
	    set aux [getAuxData $win $key $col auxType auxWidth $workPixels]
	    set indent [getIndentData $win $key $col indentWidth]
	    set maxTextWidth $workPixels
	    if {$workPixels != 0} {
		incr workPixels $data($col-delta)
		set maxTextWidth \
		    [getMaxTextWidth $workPixels $auxWidth $indentWidth]

		if {$data($col-wrap) && !$multiline} {
		    if {[font measure $cellFont -displayof $win $text] >
			$maxTextWidth} {
			set multiline 1
		    }
		}
	    }
	    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
	    set snipSide $snipSides($alignment,$data($col-changesnipside))
	    if {$multiline} {
		set list [split $text "\n"]
		if {$data($col-wrap)} {
		    set snipSide ""
		}
		adjustMlElem $win list auxWidth indentWidth $cellFont \
			     $workPixels $snipSide $data(-snipstring)
		set msgScript [list ::tablelist::displayText $win $key \
			       $col [join $list "\n"] $cellFont \
			       $maxTextWidth $alignment]
	    } else {
		adjustElem $win text auxWidth indentWidth $cellFont \
			   $workPixels $snipSide $data(-snipstring)
	    }

	    if {!$data($col-hide)} {
		if {$row == $data(editRow) && $col == $data(editCol)} {
		    #
		    # Configure the edit window
		    #
		    setEditWinFont $win
		} else {
		    #
		    # Update the text widget's contents between the two tabs
		    #
		    findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		    if {$multiline} {
			updateMlCell $w $tabIdx1+1c $tabIdx2 $msgScript $aux \
				     $auxType $auxWidth $indent $indentWidth \
				     $alignment [getVAlignment $win $key $col]
		    } else {
			updateCell $w $tabIdx1+1c $tabIdx2 $text $aux \
				   $auxType $auxWidth $indent $indentWidth \
				   $alignment [getVAlignment $win $key $col]
		    }
		}
	    }

	    #
	    # Adjust the columns if necessary
	    #
	    if {$pixels == 0 && ![info exists data($key-elide)] &&
		![info exists data($key-hide)]} {
		set text $textSav
		set auxWidth $auxWidthSav
		set indentWidth $indentWidthSav
		set newElemWidth [getElemWidth $win $text $auxWidth \
				  $indentWidth $cellFont]
		if {$newElemWidth > $data($col-elemWidth)} {
		    set data($col-elemWidth) $newElemWidth
		    set data($col-widestCount) 1
		    if {$newElemWidth > $data($col-reqPixels)} {
			set data($col-reqPixels) $newElemWidth
			adjustColumns $win {} 1
		    }
		} else {
		    set oldElemWidth [getElemWidth $win $text $auxWidth \
				      $indentWidth $oldCellFont]
		    if {$oldElemWidth < $data($col-elemWidth) &&
			$newElemWidth == $data($col-elemWidth)} {
			incr data($col-widestCount)
		    } elseif {$oldElemWidth == $data($col-elemWidth) &&
			      $newElemWidth < $oldElemWidth &&
			      [incr data($col-widestCount) -1] == 0} {
			adjustColumns $win $col 1
		    }
		}
	    }

	    updateViewWhenIdle $win
	}

	-image {
	    if {$data(isDisabled)} {
		return ""
	    }

	    #
	    # Save the old image or window width
	    #
	    set item [lindex $data(itemList) $row]
	    set key [lindex $item end]
	    set name $key,$col$opt
	    getAuxData $win $key $col oldAuxType oldAuxWidth

	    #
	    # Delete data($name) or save the specified value in it
	    #
	    set imgLabel $w.img_$key,$col
	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		    incr data(imgCount) -1
		    destroy $imgLabel
		}
	    } else {
		if {![info exists data($name)]} {
		    incr data(imgCount)
		}
		if {[winfo exists $imgLabel] &&
		    [string compare $val $data($name)] != 0} {
		    destroy $imgLabel
		}
		set data($name) $val
	    }

	    #
	    # Adjust the cell text and the image or window width
	    #
	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    set workPixels $pixels
	    set text [lindex $item $col]
	    if {[lindex $data(fmtCmdFlagList) $col]} {
		set text [formatElem $win $key $row $col $text]
	    }
	    if {[string match "*\t*" $text]} {
		set text [mapTabs $text]
	    }
	    set oldText $text
	    set multiline [string match "*\n*" $text]
	    set cellFont [getCellFont $win $key $col]
	    if {$pixels == 0} {			;# convention: dynamic width
		set textSav $text
		getAuxData $win $key $col auxType auxWidthSav
		getIndentData $win $key $col indentWidthSav

		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set workPixels $data($col-maxPixels)
		    }
		}
	    }
	    set aux [getAuxData $win $key $col auxType auxWidth $workPixels]
	    set indent [getIndentData $win $key $col indentWidth]
	    set maxTextWidth $workPixels
	    if {$workPixels != 0} {
		incr workPixels $data($col-delta)
		set maxTextWidth \
		    [getMaxTextWidth $workPixels $auxWidth $indentWidth]

		if {$data($col-wrap) && !$multiline} {
		    if {[font measure $cellFont -displayof $win $text] >
			$maxTextWidth} {
			set multiline 1
		    }
		}
	    }
	    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
	    set snipSide $snipSides($alignment,$data($col-changesnipside))
	    if {$multiline} {
		set list [split $text "\n"]
		if {$data($col-wrap)} {
		    set snipSide ""
		}
		adjustMlElem $win list auxWidth indentWidth $cellFont \
			     $workPixels $snipSide $data(-snipstring)
		set msgScript [list ::tablelist::displayText $win $key \
			       $col [join $list "\n"] $cellFont \
			       $maxTextWidth $alignment]
	    } else {
		adjustElem $win text auxWidth indentWidth $cellFont \
			   $workPixels $snipSide $data(-snipstring)
	    }

	    if {(!$data($col-hide) || $canElide) &&
		!($row == $data(editRow) && $col == $data(editCol))} {
		#
		# Delete the old cell contents between the two tabs,
		# and insert the text and the auxiliary object
		#
		findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		if {$multiline} {
		    updateMlCell $w $tabIdx1+1c $tabIdx2 $msgScript $aux \
				 $auxType $auxWidth $indent $indentWidth \
				 $alignment [getVAlignment $win $key $col]
		} else {
		    updateCell $w $tabIdx1+1c $tabIdx2 $text $aux \
			       $auxType $auxWidth $indent $indentWidth \
			       $alignment [getVAlignment $win $key $col]
		}
	    }

	    #
	    # Adjust the columns if necessary
	    #
	    if {$pixels == 0 && ![info exists data($key-elide)] &&
		![info exists data($key-hide)]} {
		set text $textSav
		set auxWidth $auxWidthSav
		set indentWidth $indentWidthSav
		set newElemWidth [getElemWidth $win $text $auxWidth \
				  $indentWidth $cellFont]
		if {$newElemWidth > $data($col-elemWidth)} {
		    set data($col-elemWidth) $newElemWidth
		    set data($col-widestCount) 1
		    if {$newElemWidth > $data($col-reqPixels)} {
			set data($col-reqPixels) $newElemWidth
			adjustColumns $win {} 1
		    }
		} else {
		    set oldElemWidth [getElemWidth $win $oldText $oldAuxWidth \
				      $indentWidth $cellFont]
		    if {$oldElemWidth < $data($col-elemWidth) &&
			$newElemWidth == $data($col-elemWidth)} {
			incr data($col-widestCount)
		    } elseif {$oldElemWidth == $data($col-elemWidth) &&
			      $newElemWidth < $oldElemWidth &&
			      [incr data($col-widestCount) -1] == 0} {
			adjustColumns $win $col 1
		    }
		}
	    }

	    updateViewWhenIdle $win
	}

	-indent {
	    if {$data(isDisabled)} {
		return ""
	    }

	    #
	    # Save the old indentation width
	    #
	    set item [lindex $data(itemList) $row]
	    set key [lindex $item end]
	    set name $key,$col$opt
	    getIndentData $win $key $col oldIndentWidth

	    #
	    # Delete data($name) or save the specified value in it
	    #
	    set indentLabel $w.ind_$key,$col
	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		    incr data(indentCount) -1
		    destroy $indentLabel
		}
	    } else {
		if {![info exists data($name)]} {
		    incr data(indentCount)
		}
		if {[winfo exists $indentLabel] &&
		    [string compare $val $data($name)] != 0} {
		    destroy $indentLabel
		}
		set data($name) $val
	    }

	    #
	    # Adjust the cell text and the image or window width
	    #
	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    set workPixels $pixels
	    set text [lindex $item $col]
	    if {[lindex $data(fmtCmdFlagList) $col]} {
		set text [formatElem $win $key $row $col $text]
	    }
	    if {[string match "*\t*" $text]} {
		set text [mapTabs $text]
	    }
	    set oldText $text
	    set multiline [string match "*\n*" $text]
	    set cellFont [getCellFont $win $key $col]
	    if {$pixels == 0} {			;# convention: dynamic width
		set textSav $text
		getAuxData $win $key $col auxType auxWidthSav
		getIndentData $win $key $col indentWidthSav

		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set workPixels $data($col-maxPixels)
		    }
		}
	    }
	    set aux [getAuxData $win $key $col auxType auxWidth $workPixels]
	    set indent [getIndentData $win $key $col indentWidth]
	    set maxTextWidth $workPixels
	    if {$workPixels != 0} {
		incr workPixels $data($col-delta)
		set maxTextWidth \
		    [getMaxTextWidth $workPixels $auxWidth $indentWidth]

		if {$data($col-wrap) && !$multiline} {
		    if {[font measure $cellFont -displayof $win $text] >
			$maxTextWidth} {
			set multiline 1
		    }
		}
	    }
	    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
	    set snipSide $snipSides($alignment,$data($col-changesnipside))
	    if {$multiline} {
		set list [split $text "\n"]
		if {$data($col-wrap)} {
		    set snipSide ""
		}
		adjustMlElem $win list auxWidth indentWidth $cellFont \
			     $workPixels $snipSide $data(-snipstring)
		set msgScript [list ::tablelist::displayText $win $key \
			       $col [join $list "\n"] $cellFont \
			       $maxTextWidth $alignment]
	    } else {
		adjustElem $win text auxWidth indentWidth $cellFont \
			   $workPixels $snipSide $data(-snipstring)
	    }

	    if {(!$data($col-hide) || $canElide) &&
		!($row == $data(editRow) && $col == $data(editCol))} {
		#
		# Delete the old cell contents between the two tabs,
		# and insert the text and the auxiliary object
		#
		findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		if {$multiline} {
		    updateMlCell $w $tabIdx1+1c $tabIdx2 $msgScript $aux \
				 $auxType $auxWidth $indent $indentWidth \
				 $alignment [getVAlignment $win $key $col]
		} else {
		    updateCell $w $tabIdx1+1c $tabIdx2 $text $aux \
			       $auxType $auxWidth $indent $indentWidth \
			       $alignment [getVAlignment $win $key $col]
		}
	    }

	    #
	    # Adjust the columns if necessary
	    #
	    if {$pixels == 0 && ![info exists data($key-elide)] &&
		![info exists data($key-hide)]} {
		set text $textSav
		set auxWidth $auxWidthSav
		set indentWidth $indentWidthSav
		set newElemWidth [getElemWidth $win $text $auxWidth \
				  $indentWidth $cellFont]
		if {$newElemWidth > $data($col-elemWidth)} {
		    set data($col-elemWidth) $newElemWidth
		    set data($col-widestCount) 1
		    if {$newElemWidth > $data($col-reqPixels)} {
			set data($col-reqPixels) $newElemWidth
			adjustColumns $win {} 1
		    }
		} else {
		    set oldElemWidth [getElemWidth $win $oldText $auxWidth \
				      $oldIndentWidth $cellFont]
		    if {$oldElemWidth < $data($col-elemWidth) &&
			$newElemWidth == $data($col-elemWidth)} {
			incr data($col-widestCount)
		    } elseif {$oldElemWidth == $data($col-elemWidth) &&
			      $newElemWidth < $oldElemWidth &&
			      [incr data($col-widestCount) -1] == 0} {
			adjustColumns $win $col 1
		    }
		}
	    }

	    updateViewWhenIdle $win
	}

	-selectbackground -
	-selectforeground {
	    set key [lindex $data(keyList) $row]
	    set name $key,$col$opt

	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		}
	    } else {
		#
		# Configure the tag cell$opt-$val in the body text widget
		#
		set tag cell$opt-$val
		set optTail [string range $opt 7 end]	;# remove the -select
		$w tag configure $tag -$optTail $val
		$w tag lower $tag disabled

		#
		# Save val in data($name)
		#
		set data($name) $val
	    }

	    if {!$data(isDisabled)} {
		updateColorsWhenIdle $win
	    }
	}

	-stretchwindow {
	    #
	    # Save the boolean value specified by val in data($key,$col$opt)
	    #
	    set item [lindex $data(itemList) $row]
	    set key [lindex $item end]
	    set name $key,$col$opt
	    if {$val} {
		set data($name) 1
	    } elseif {[info exists data($name)]} {
		unset data($name)
	    }

	    if {($data($col-hide) && !$canElide) ||
		($row == $data(editRow) && $col == $data(editCol))} {
		return ""
	    }

	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    set text [lindex $item $col]
	    if {[lindex $data(fmtCmdFlagList) $col]} {
		set text [formatElem $win $key $row $col $text]
	    }
	    if {[string match "*\t*" $text]} {
		set text [mapTabs $text]
	    }
	    set multiline [string match "*\n*" $text]
	    set cellFont [getCellFont $win $key $col]
	    if {$pixels == 0} {			;# convention: dynamic width
		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set pixels $data($col-maxPixels)
		    }
		}
	    }
	    set aux [getAuxData $win $key $col auxType auxWidth $pixels]
	    set indent [getIndentData $win $key $col indentWidth]
	    set maxTextWidth $pixels
	    if {$pixels != 0} {
		incr pixels $data($col-delta)
		set maxTextWidth \
		    [getMaxTextWidth $pixels $auxWidth $indentWidth]

		if {$data($col-wrap) && !$multiline} {
		    if {[font measure $cellFont -displayof $win $text] >
			$maxTextWidth} {
			set multiline 1
		    }
		}
	    }
	    if {$auxType < 2} {			;# no window
		return ""
	    }

	    #
	    # Adjust the cell text and the window width
	    #
	    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
	    set snipSide $snipSides($alignment,$data($col-changesnipside))
	    if {$multiline} {
		set list [split $text "\n"]
		if {$data($col-wrap)} {
		    set snipSide ""
		}
		adjustMlElem $win list auxWidth indentWidth $cellFont \
			     $pixels $snipSide $data(-snipstring)
		set msgScript [list ::tablelist::displayText $win $key $row \
			       [join $list "\n"] $cellFont \
			       $maxTextWidth $alignment]
	    } else {
		adjustElem $win text auxWidth indentWidth $cellFont \
			   $pixels $snipSide $data(-snipstring)
	    }

	    #
	    # Update the text widget's contents between the two tabs
	    #
	    findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
	    if {$multiline} {
		updateMlCell $w $tabIdx1+1c $tabIdx2 $msgScript $aux \
			     $auxType $auxWidth $indent $indentWidth \
			     $alignment [getVAlignment $win $key $col]
	    } else {
		updateCell $w $tabIdx1+1c $tabIdx2 $text $aux \
			   $auxType $auxWidth $indent $indentWidth \
			   $alignment [getVAlignment $win $key $col]
	    }
	}

	-text {
	    if {$data(isDisabled)} {
		return ""
	    }

	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    set workPixels $pixels
	    set text $val
	    set oldItem [lindex $data(itemList) $row]
	    set key [lindex $oldItem end]
	    set fmtCmdFlag [lindex $data(fmtCmdFlagList) $col]
	    if {$fmtCmdFlag} {
		set text [formatElem $win $key $row $col $text]
	    }
	    if {[string match "*\t*" $text]} {
		set text [mapTabs $text]
	    }
	    set textSav $text
	    set multiline [string match "*\n*" $text]
	    set cellFont [getCellFont $win $key $col]
	    if {$pixels == 0} {			;# convention: dynamic width
		getAuxData $win $key $col auxType auxWidthSav
		getIndentData $win $key $col indentWidthSav

		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set workPixels $data($col-maxPixels)
		    }
		}
	    }
	    set aux [getAuxData $win $key $col auxType auxWidth $workPixels]
	    set indent [getIndentData $win $key $col indentWidth]
	    set maxTextWidth $workPixels
	    if {$workPixels != 0} {
		incr workPixels $data($col-delta)
		set maxTextWidth \
		    [getMaxTextWidth $workPixels $auxWidth $indentWidth]

		if {$data($col-wrap) && !$multiline} {
		    if {[font measure $cellFont -displayof $win $text] >
			$maxTextWidth} {
			set multiline 1
		    }
		}
	    }
	    set alignment [lindex $data(colList) [expr {2*$col + 1}]]

	    #
	    # Adjust the cell text and the image or window width
	    #
	    set snipSide $snipSides($alignment,$data($col-changesnipside))
	    if {$multiline} {
		set list [split $text "\n"]
		if {$data($col-wrap)} {
		    set snipSide ""
		}
		adjustMlElem $win list auxWidth indentWidth $cellFont \
			     $workPixels $snipSide $data(-snipstring)
		set msgScript [list ::tablelist::displayText $win $key \
			       $col [join $list "\n"] $cellFont \
			       $maxTextWidth $alignment]
	    } else {
		adjustElem $win text auxWidth indentWidth $cellFont \
			   $workPixels $snipSide $data(-snipstring)
	    }

	    if {(!$data($col-hide) || $canElide) &&
		!($row == $data(editRow) && $col == $data(editCol))} {
		#
		# Update the text widget's contents between the two tabs
		#
		findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		if {$multiline} {
		    updateMlCell $w $tabIdx1+1c $tabIdx2 $msgScript $aux \
				 $auxType $auxWidth $indent $indentWidth \
				 $alignment [getVAlignment $win $key $col]
		} else {
		    updateCell $w $tabIdx1+1c $tabIdx2 $text $aux \
			       $auxType $auxWidth $indent $indentWidth \
			       $alignment [getVAlignment $win $key $col]
		}
	    }

	    #
	    # Replace the cell contents in the internal list
	    #
	    set newItem [lreplace $oldItem $col $col $val]
	    set data(itemList) [lreplace $data(itemList) $row $row $newItem]

	    #
	    # Replace the cell contents in the list variable if present
	    #
	    if {$data(hasListVar)} {
		upvar #0 $data(-listvariable) var
		trace vdelete var wu $data(listVarTraceCmd)
		set var [lreplace $var $row $row \
			 [lrange $newItem 0 $data(lastCol)]]
		trace variable var wu $data(listVarTraceCmd)
	    }

	    #
	    # Adjust the columns if necessary
	    #
	    if {$pixels == 0 && ![info exists data($key-elide)] &&
		![info exists data($key-hide)]} {
		set text $textSav
		set auxWidth $auxWidthSav
		set indentWidth $indentWidthSav
		set newElemWidth [getElemWidth $win $text $auxWidth \
				  $indentWidth $cellFont]
		if {$newElemWidth > $data($col-elemWidth)} {
		    set data($col-elemWidth) $newElemWidth
		    set data($col-widestCount) 1
		    if {$newElemWidth > $data($col-reqPixels)} {
			set data($col-reqPixels) $newElemWidth
			adjustColumns $win {} 1
		    }
		} else {
		    set oldText [lindex $oldItem $col]
		    if {$fmtCmdFlag} {
			set oldText [formatElem $win $key $row $col $oldText]
		    }
		    if {[string match "*\t*" $oldText]} {
			set oldText [mapTabs $oldText]
		    }
		    set oldElemWidth [getElemWidth $win $oldText $auxWidth \
				      $indentWidth $cellFont]
		    if {$oldElemWidth < $data($col-elemWidth) &&
			$newElemWidth == $data($col-elemWidth)} {
			incr data($col-widestCount)
		    } elseif {$oldElemWidth == $data($col-elemWidth) &&
			      $newElemWidth < $oldElemWidth &&
			      [incr data($col-widestCount) -1] == 0} {
			adjustColumns $win $col 1
		    }
		}
	    }

	    showLineNumbersWhenIdle $win
	    updateViewWhenIdle $win
	}

	-valign {
	    #
	    # Save the properly formatted value of val in
	    # data($key,$col$opt) and redisplay the cell
	    #
	    variable valignments
	    set val [mwutil::fullOpt "vertical alignment" $val $valignments]
	    set key [lindex $data(keyList) $row]
	    set data($key,$col$opt) $val
	    redisplayCol $win $col $row $row
	}

	-window {
	    if {$data(isDisabled)} {
		return ""
	    }

	    #
	    # Save the old image or window width
	    #
	    set item [lindex $data(itemList) $row]
	    set key [lindex $item end]
	    set name $key,$col$opt
	    getAuxData $win $key $col oldAuxType oldAuxWidth
	    getIndentData $win $key $col oldIndentWidth

	    #
	    # Delete data($name) or save the specified value in it
	    #
	    set aux $w.frm_$key,$col
	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		    unset data($key,$col-reqWidth)
		    unset data($key,$col-reqHeight)

		    #
		    # If the cell index is contained in the list
		    # data(cellsToReconfig) then remove it from the list
		    #
		    set n [lsearch -exact $data(cellsToReconfig) $row,$col]
		    if {$n >= 0} {
			set data(cellsToReconfig) \
			    [lreplace $data(cellsToReconfig) $n $n]
		    }
		    incr data(winCount) -1
		    destroy $aux
		}
	    } else {
		if {![info exists data($name)]} {
		    incr data(winCount)
		}
		if {[info exists data($name)] &&
		    [string compare $val $data($name)] != 0} {
		    destroy $aux
		}
		if {![winfo exists $aux]} {
		    #
		    # Create the frame and evaluate the specified script
		    # that creates a child widget within the frame
		    #
		    tk::frame $aux -borderwidth 0 -class TablelistWindow \
				   -container 0 -highlightthickness 0 \
				   -relief flat -takefocus 0
		    catch {$aux configure -padx 0 -pady 0}
		    bindtags $aux [linsert [bindtags $aux] 1 \
				   $data(bodyTag) TablelistBody]
		    uplevel #0 $val [list $win $row $col $aux.w]
		}
		set data($name) $val
		set data($key,$col-reqWidth) [winfo reqwidth $aux.w]
		set data($key,$col-reqHeight) [winfo reqheight $aux.w]
		$aux configure -height $data($key,$col-reqHeight)

		#
		# Add the cell index to the list data(cellsToReconfig) if
		# the window's requested width or height is not yet known
		#
		if {($data($key,$col-reqWidth) == 1 ||
		     $data($key,$col-reqHeight) == 1) &&
		    [lsearch -exact $data(cellsToReconfig) $row,$col] < 0} {
		    lappend data(cellsToReconfig) $row,$col
		    if {![info exists data(reconfigId)]} {
			set data(reconfigId) \
			    [after idle [list tablelist::reconfigWindows $win]]
		    }
		}
	    }

	    #
	    # Adjust the cell text and the image or window width
	    #
	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    set workPixels $pixels
	    set text [lindex $item $col]
	    if {[lindex $data(fmtCmdFlagList) $col]} {
		set text [formatElem $win $key $row $col $text]
	    }
	    if {[string match "*\t*" $text]} {
		set text [mapTabs $text]
	    }
	    set oldText $text
	    set multiline [string match "*\n*" $text]
	    set cellFont [getCellFont $win $key $col]
	    if {$pixels == 0} {			;# convention: dynamic width
		set textSav $text
		getAuxData $win $key $col auxType auxWidthSav
		getIndentData $win $key $col indentWidthSav

		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set workPixels $data($col-maxPixels)
		    }
		}
	    }
	    set aux [getAuxData $win $key $col auxType auxWidth $workPixels]
	    set indent [getIndentData $win $key $col indentWidth]
	    set maxTextWidth $workPixels
	    if {$workPixels != 0} {
		incr workPixels $data($col-delta)
		set maxTextWidth \
		    [getMaxTextWidth $workPixels $auxWidth $indentWidth]

		if {$data($col-wrap) && !$multiline} {
		    if {[font measure $cellFont -displayof $win $text] >
			$maxTextWidth} {
			set multiline 1
		    }
		}
	    }
	    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
	    set snipSide $snipSides($alignment,$data($col-changesnipside))
	    if {$multiline} {
		set list [split $text "\n"]
		if {$data($col-wrap)} {
		    set snipSide ""
		}
		adjustMlElem $win list auxWidth indentWidth $cellFont \
			     $workPixels $snipSide $data(-snipstring)
		set msgScript [list ::tablelist::displayText $win $key \
			       $col [join $list "\n"] $cellFont \
			       $maxTextWidth $alignment]
	    } else {
		adjustElem $win text auxWidth indentWidth $cellFont \
			   $workPixels $snipSide $data(-snipstring)
	    }

	    if {(!$data($col-hide) || $canElide) &&
		!($row == $data(editRow) && $col == $data(editCol))} {
		#
		# Delete the old cell contents between the two tabs,
		# and insert the text and the auxiliary object
		#
		findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		if {$multiline} {
		    updateMlCell $w $tabIdx1+1c $tabIdx2 $msgScript $aux \
				 $auxType $auxWidth $indent $indentWidth \
				 $alignment [getVAlignment $win $key $col]
		} else {
		    updateCell $w $tabIdx1+1c $tabIdx2 $text $aux \
			       $auxType $auxWidth $indent $indentWidth \
			       $alignment [getVAlignment $win $key $col]
		}
	    }

	    #
	    # Adjust the columns if necessary
	    #
	    if {$pixels == 0 && ![info exists data($key-elide)] &&
		![info exists data($key-hide)]} {
		set text $textSav
		set auxWidth $auxWidthSav
		set indentWidth $indentWidthSav
		set newElemWidth [getElemWidth $win $text $auxWidth \
				  $indentWidth $cellFont]
		if {$newElemWidth > $data($col-elemWidth)} {
		    set data($col-elemWidth) $newElemWidth
		    set data($col-widestCount) 1
		    if {$newElemWidth > $data($col-reqPixels)} {
			set data($col-reqPixels) $newElemWidth
			adjustColumns $win {} 1
		    }
		} else {
		    set oldElemWidth [getElemWidth $win $oldText $oldAuxWidth \
				      $oldIndentWidth $cellFont]
		    if {$oldElemWidth < $data($col-elemWidth) &&
			$newElemWidth == $data($col-elemWidth)} {
			incr data($col-widestCount)
		    } elseif {$oldElemWidth == $data($col-elemWidth) &&
			      $newElemWidth < $oldElemWidth &&
			      [incr data($col-widestCount) -1] == 0} {
			adjustColumns $win $col 1
		    }
		}
	    }

	    updateViewWhenIdle $win
	}

	-windowdestroy -
	-windowupdate {
	    set key [lindex $data(keyList) $row]
	    set name $key,$col$opt

	    #
	    # Delete data($name) or save the specified value in it
	    #
	    if {[string length $val] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		}
	    } else {
		set data($name) $val
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::doCellCget
#
# Returns the value of the cell configuration option opt for the cell row,col
# of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::doCellCget {row col win opt} {
    switch -- $opt {
	-editable {
	    return [isCellEditable $win $row $col]
	}

	-editwindow {
	    return [getEditWindow $win $row $col 0]
	}

	-stretchwindow {
	    upvar ::tablelist::ns${win}::data data
	    set key [lindex $data(keyList) $row]
	    if {[info exists data($key,$col$opt)]} {
		return $data($key,$col$opt)
	    } else {
		return 0
	    }
	}

	-text {
	    upvar ::tablelist::ns${win}::data data
	    return [lindex [lindex $data(itemList) $row] $col]
	}

	-valign {
	    upvar ::tablelist::ns${win}::data data
	    set key [lindex $data(keyList) $row]
	    return [getVAlignment $win $key $col]
	}

	default {
	    upvar ::tablelist::ns${win}::data data
	    set key [lindex $data(keyList) $row]
	    if {[info exists data($key,$col$opt)]} {
		return $data($key,$col$opt)
	    } else {
		return ""
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::makeListVar
#
# Arranges for the global variable specified by varName to become the list
# variable associated with the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::makeListVar {win varName} {
    upvar ::tablelist::ns${win}::data data
    if {[string length $varName] == 0} {
	#
	# If there is an old list variable associated with the
	# widget then remove the trace set on this variable
	#
	if {$data(hasListVar)} {
	    synchronize $win
	    upvar #0 $data(-listvariable) var
	    trace vdelete var wu $data(listVarTraceCmd)
	}
	return ""
    }

    #
    # The list variable may be an array element but must not be an array
    #
    if {![regexp {^(.*)\((.*)\)$} $varName dummy name1 name2]} {
	if {[array exists $varName]} {
	    return -code error "variable \"$varName\" is array"
	}
	set name1 $varName
	set name2 ""
    }

    #
    # If there is an old list variable associated with the
    # widget then remove the trace set on this variable
    #
    if {$data(hasListVar)} {
	synchronize $win
	upvar #0 $data(-listvariable) var
	trace vdelete var wu $data(listVarTraceCmd)
    }

    upvar #0 $varName var
    if {[info exists var]} {
	#
	# Invoke the trace procedure associated with the new list variable
	#
	listVarTrace $win $name1 $name2 w
    } else {
	#
	# Set $varName according to the value of data(itemList)
	#
	set var {}
	foreach item $data(itemList) {
	    lappend var [lrange $item 0 $data(lastCol)]
	}
    }

    #
    # Set a trace on the new list variable
    #
    trace variable var wu $data(listVarTraceCmd)
}

#------------------------------------------------------------------------------
# tablelist::isRowViewable
#
# Checks whether the given row of the tablelist widget win is viewable.
#------------------------------------------------------------------------------
proc tablelist::isRowViewable {win row} {
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    return [expr {![info exists data($key-elide)] &&
		  ![info exists data($key-hide)]}]
}

#------------------------------------------------------------------------------
# tablelist::getCellFont
#
# Returns the font to be used in the tablelist cell specified by win, key, and
# col.
#------------------------------------------------------------------------------
proc tablelist::getCellFont {win key col} {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data($key,$col-font)]} {
	return $data($key,$col-font)
    } elseif {[info exists data($key-font)]} {
	return $data($key-font)
    } else {
	return [lindex $data(colFontList) $col]
    }
}

#------------------------------------------------------------------------------
# tablelist::reconfigWindows
#
# Invoked as an after idle callback, this procedure forces any geometry manager
# calculations to be completed and then applies the -window option a second
# time to those cells whose embedded windows' requested widths or heights were
# still unknown.
#------------------------------------------------------------------------------
proc tablelist::reconfigWindows win {
    #
    # Force any geometry manager calculations to be completed first
    #
    update idletasks
    if {![array exists ::tablelist::ns${win}::data]} {
	return ""
    }

    #
    # Reconfigure the cells specified in the list data(cellsToReconfig)
    #
    upvar ::tablelist::ns${win}::data data
    foreach cellIdx $data(cellsToReconfig) {
	foreach {row col} [split $cellIdx ","] {}
	set key [lindex $data(keyList) $row]
	if {[info exists data($key,$col-window)]} {
	    doCellConfig $row $col $win -window $data($key,$col-window)
	}
    }

    unset data(reconfigId)
    set data(cellsToReconfig) {}
}

#------------------------------------------------------------------------------
# tablelist::isCellEditable
#
# Checks whether the given cell of the tablelist widget win is editable.
#------------------------------------------------------------------------------
proc tablelist::isCellEditable {win row col} {
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    if {[info exists data($key,$col-editable)]} {
	return $data($key,$col-editable)
    } else {
	return $data($col-editable)
    }
}

#------------------------------------------------------------------------------
# tablelist::getEditWindow
#
# Returns the value of the -editwindow option at cell or column level for the
# given cell of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::getEditWindow {win row col {skipLeadingColons 1}} {
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    if {[info exists data($key,$col-editwindow)]} {
	set name $data($key,$col-editwindow)
    } elseif {[info exists data($col-editwindow)]} {
	set name $data($col-editwindow)
    } else {
	return "entry"
    }

    if {[regexp {^::ttk::(entry|spinbox|combobox|checkbutton|menubutton)$} \
	 $name] && $skipLeadingColons} {
	set name [string range $name 2 end]
    }

    return $name
}

#------------------------------------------------------------------------------
# tablelist::getVAlignment
#
# Returns the value of the -valign option at cell or column level for the given
# cell of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::getVAlignment {win key col} {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data($key,$col-valign)]} {
	return $data($key,$col-valign)
    } else {
	return $data($col-valign)
    }
}
#==============================================================================
# Contains the implementation of interactive cell editing in tablelist widgets.
#
# Structure of the module:
#   - Namespace initialization
#   - Public procedures related to interactive cell editing
#   - Private procedures implementing the interactive cell editing
#   - Private procedures used in bindings related to interactive cell editing
#
# Copyright (c) 2003-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#
# Namespace initialization
# ========================
#

namespace eval tablelist {
    #
    # Register the Tk core widgets entry, text, checkbutton,
    # menubutton, and spinbox for interactive cell editing
    #
    proc addTkCoreWidgets {} {
	variable editWin

	set name entry
	array set editWin [list \
	    $name-creationCmd	"$name %W -width 0" \
	    $name-putValueCmd	"%W delete 0 end; %W insert 0 %T" \
	    $name-getValueCmd	"%W get" \
	    $name-putTextCmd	"%W delete 0 end; %W insert 0 %T" \
	    $name-getTextCmd	"%W get" \
	    $name-putListCmd	"" \
	    $name-getListCmd	"" \
	    $name-selectCmd	"" \
	    $name-invokeCmd	"" \
	    $name-fontOpt	-font \
	    $name-useFormat	1 \
	    $name-useReqWidth	0 \
	    $name-usePadX	0 \
	    $name-isEntryLike	1 \
	    $name-focusWin	%W \
	    $name-reservedKeys	{Left Right} \
	]

	set name text
	array set editWin [list \
	    $name-creationCmd	"$name %W -padx 2 -pady 2 -wrap none" \
	    $name-putValueCmd	"%W delete 1.0 end; %W insert 1.0 %T" \
	    $name-getValueCmd	"%W get 1.0 end-1c" \
	    $name-putTextCmd	"%W delete 1.0 end; %W insert 1.0 %T" \
	    $name-getTextCmd	"%W get 1.0 end-1c" \
	    $name-putListCmd	"" \
	    $name-getListCmd	"" \
	    $name-selectCmd	"" \
	    $name-invokeCmd	"" \
	    $name-fontOpt	-font \
	    $name-useFormat	1 \
	    $name-useReqWidth	0 \
	    $name-usePadX	0 \
	    $name-isEntryLike	1 \
	    $name-focusWin	%W \
	    $name-reservedKeys	{Left Right Up Down Prior Next
				 Control-Home Control-End Meta-b Meta-f
				 Control-p Control-n Meta-less Meta-greater} \
	]

	set name checkbutton
	array set editWin [list \
	    $name-creationCmd	"createCheckbutton %W" \
	    $name-putValueCmd	{set [%W cget -variable] %T} \
	    $name-getValueCmd	{set [%W cget -variable]} \
	    $name-putTextCmd	{set [%W cget -variable] %T} \
	    $name-getTextCmd	{set [%W cget -variable]} \
	    $name-putListCmd	"" \
	    $name-getListCmd	"" \
	    $name-selectCmd	"" \
	    $name-invokeCmd	"%W invoke" \
	    $name-fontOpt	"" \
	    $name-useFormat	0 \
	    $name-useReqWidth	1 \
	    $name-usePadX	0 \
	    $name-isEntryLike	0 \
	    $name-focusWin	%W \
	    $name-reservedKeys	{} \
	]

	set name menubutton
	array set editWin [list \
	    $name-creationCmd	"createMenubutton %W" \
	    $name-putValueCmd	{set [%W cget -textvariable] %T} \
	    $name-getValueCmd	"%W cget -text" \
	    $name-putTextCmd	{set [%W cget -textvariable] %T} \
	    $name-getTextCmd	"%W cget -text" \
	    $name-putListCmd	"" \
	    $name-getListCmd	"" \
	    $name-selectCmd	"" \
	    $name-invokeCmd	"event generate %W <Button-1>" \
	    $name-fontOpt	-font \
	    $name-useFormat	1 \
	    $name-useReqWidth	0 \
	    $name-usePadX	1 \
	    $name-isEntryLike	0 \
	    $name-focusWin	%W \
	    $name-reservedKeys	{} \
	]

	if {$::tk_version < 8.4} {
	    return ""
	}

	set name spinbox
	array set editWin [list \
	    $name-creationCmd	"$name %W -width 0" \
	    $name-putValueCmd	"%W delete 0 end; %W insert 0 %T" \
	    $name-getValueCmd	"%W get" \
	    $name-putTextCmd	"%W delete 0 end; %W insert 0 %T" \
	    $name-getTextCmd	"%W get" \
	    $name-putListCmd	"" \
	    $name-getListCmd	"" \
	    $name-selectCmd	"" \
	    $name-invokeCmd	"" \
	    $name-fontOpt	-font \
	    $name-useFormat	1 \
	    $name-useReqWidth	0 \
	    $name-usePadX	1 \
	    $name-isEntryLike	1 \
	    $name-focusWin	%W \
	    $name-reservedKeys	{Left Right Up Down} \
	]
    }
    addTkCoreWidgets 

    #
    # Register the tile widgets ttk::entry, ttk::spinbox, ttk::combobox,
    # ttk::checkbutton, and ttk::menubutton for interactive cell editing
    #
    proc addTileWidgets {} {
	variable editWin

	set name ttk::entry
	array set editWin [list \
	    $name-creationCmd	"createTileEntry %W" \
	    $name-putValueCmd	"%W delete 0 end; %W insert 0 %T" \
	    $name-getValueCmd	"%W get" \
	    $name-putTextCmd	"%W delete 0 end; %W insert 0 %T" \
	    $name-getTextCmd	"%W get" \
	    $name-putListCmd	"" \
	    $name-getListCmd	"" \
	    $name-selectCmd	"" \
	    $name-invokeCmd	"" \
	    $name-fontOpt	-font \
	    $name-useFormat	1 \
	    $name-useReqWidth	0 \
	    $name-usePadX	0 \
	    $name-isEntryLike	1 \
	    $name-focusWin	%W \
	    $name-reservedKeys	{Left Right} \
	]

	set name ttk::spinbox
	array set editWin [list \
	    $name-creationCmd	"createTileSpinbox %W" \
	    $name-putValueCmd	"%W delete 0 end; %W insert 0 %T" \
	    $name-getValueCmd	"%W get" \
	    $name-putTextCmd	"%W delete 0 end; %W insert 0 %T" \
	    $name-getTextCmd	"%W get" \
	    $name-putListCmd	"" \
	    $name-getListCmd	"" \
	    $name-selectCmd	"" \
	    $name-invokeCmd	"" \
	    $name-fontOpt	-font \
	    $name-useFormat	1 \
	    $name-useReqWidth	0 \
	    $name-usePadX	1 \
	    $name-isEntryLike	1 \
	    $name-focusWin	%W \
	    $name-reservedKeys	{Left Right Up Down} \
	]

	set name ttk::combobox
	array set editWin [list \
	    $name-creationCmd	"createTileCombobox %W" \
	    $name-putValueCmd	"%W set %T" \
	    $name-getValueCmd	"%W get" \
	    $name-putTextCmd	"%W set %T" \
	    $name-getTextCmd	"%W get" \
	    $name-putListCmd	"" \
	    $name-getListCmd	"" \
	    $name-selectCmd	"" \
	    $name-invokeCmd	"event generate %W <Button-1>" \
	    $name-fontOpt	-font \
	    $name-useFormat	1 \
	    $name-useReqWidth	0 \
	    $name-usePadX	1 \
	    $name-isEntryLike	1 \
	    $name-focusWin	%W \
	    $name-reservedKeys	{Left Right Up Down} \
	]

	set name ttk::checkbutton
	array set editWin [list \
	    $name-creationCmd	"createTileCheckbutton %W" \
	    $name-putValueCmd	{set [%W cget -variable] %T} \
	    $name-getValueCmd	{set [%W cget -variable]} \
	    $name-putTextCmd	{set [%W cget -variable] %T} \
	    $name-getTextCmd	{set [%W cget -variable]} \
	    $name-putListCmd	"" \
	    $name-getListCmd	"" \
	    $name-selectCmd	"" \
	    $name-invokeCmd	{%W instate !pressed {%W invoke}} \
	    $name-fontOpt	"" \
	    $name-useFormat	0 \
	    $name-useReqWidth	1 \
	    $name-usePadX	0 \
	    $name-isEntryLike	0 \
	    $name-focusWin	%W \
	    $name-reservedKeys	{} \
	]

	set name ttk::menubutton
	array set editWin [list \
	    $name-creationCmd	"createTileMenubutton %W" \
	    $name-putValueCmd	{set [%W cget -textvariable] %T} \
	    $name-getValueCmd	"%W cget -text" \
	    $name-putTextCmd	{set [%W cget -textvariable] %T} \
	    $name-getTextCmd	"%W cget -text" \
	    $name-putListCmd	"" \
	    $name-getListCmd	"" \
	    $name-selectCmd	"" \
	    $name-invokeCmd	"event generate %W <Button-1>" \
	    $name-fontOpt	"" \
	    $name-useFormat	1 \
	    $name-useReqWidth	0 \
	    $name-usePadX	1 \
	    $name-isEntryLike	0 \
	    $name-focusWin	%W \
	    $name-reservedKeys	{} \
	]

	foreach {name value} [array get editWin ttk::*-creationCmd] {
	    set editWin(::$name) $value
	}
    }
    if {$::tk_version >= 8.4 && [llength [package versions tile]] > 0} {
	addTileWidgets 
    }
}

#
# Public procedures related to interactive cell editing
# =====================================================
#

#------------------------------------------------------------------------------
# tablelist::addBWidgetEntry
#
# Registers the Entry widget from the BWidget package for interactive cell
# editing.
#------------------------------------------------------------------------------
proc tablelist::addBWidgetEntry {{name Entry}} {
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	"Entry %W -width 0" \
	$name-putValueCmd	"%W delete 0 end; %W insert 0 %T" \
	$name-getValueCmd	"%W get" \
	$name-putTextCmd	"%W delete 0 end; %W insert 0 %T" \
	$name-getTextCmd	"%W get" \
	$name-putListCmd	"" \
	$name-getListCmd	"" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-font \
	$name-useFormat		1 \
	$name-useReqWidth	0 \
	$name-usePadX		0 \
	$name-isEntryLike	1 \
	$name-focusWin		%W \
	$name-reservedKeys	{Left Right} \
    ]

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addBWidgetSpinBox
#
# Registers the SpinBox widget from the BWidget package for interactive cell
# editing.
#------------------------------------------------------------------------------
proc tablelist::addBWidgetSpinBox {{name SpinBox}} {
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	"SpinBox %W -editable 1 -width 0" \
	$name-putValueCmd	"%W configure -text %T" \
	$name-getValueCmd	"%W cget -text" \
	$name-putTextCmd	"%W configure -text %T" \
	$name-getTextCmd	"%W cget -text" \
	$name-putListCmd	"" \
	$name-getListCmd	"" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-font \
	$name-useFormat		1 \
	$name-useReqWidth	0 \
	$name-usePadX		1 \
	$name-isEntryLike	1 \
	$name-focusWin		%W.e \
	$name-reservedKeys	{Left Right Up Down Prior Next} \
    ]

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addBWidgetComboBox
#
# Registers the ComboBox widget from the BWidget package for interactive cell
# editing.
#------------------------------------------------------------------------------
proc tablelist::addBWidgetComboBox {{name ComboBox}} {
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	"createBWidgetComboBox %W" \
	$name-putValueCmd	"%W configure -text %T" \
	$name-getValueCmd	"%W cget -text" \
	$name-putTextCmd	"%W configure -text %T" \
	$name-getTextCmd	"%W cget -text" \
	$name-putListCmd	"" \
	$name-getListCmd	"" \
	$name-selectCmd		"" \
	$name-invokeCmd		"%W.a invoke" \
	$name-fontOpt		-font \
	$name-useFormat		1 \
	$name-useReqWidth	0 \
	$name-usePadX		1 \
	$name-isEntryLike	1 \
	$name-focusWin		%W.e \
	$name-reservedKeys	{Left Right Up Down} \
    ]

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addIncrEntryfield
#
# Registers the entryfield widget from the Iwidgets package for interactive
# cell editing.
#------------------------------------------------------------------------------
proc tablelist::addIncrEntryfield {{name entryfield}} {
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	"iwidgets::entryfield %W -width 0" \
	$name-putValueCmd	"%W clear; %W insert 0 %T" \
	$name-getValueCmd	"%W get" \
	$name-putTextCmd	"%W clear; %W insert 0 %T" \
	$name-getTextCmd	"%W get" \
	$name-putListCmd	"" \
	$name-getListCmd	"" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-textfont \
	$name-useFormat		1 \
	$name-useReqWidth	0 \
	$name-usePadX		0 \
	$name-isEntryLike	1 \
	$name-focusWin		{[%W component entry]} \
	$name-reservedKeys	{Left Right} \
    ]

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addIncrDateTimeWidget
#
# Registers the datefield, dateentry, timefield, or timeentry widget from the
# Iwidgets package, with or without the -clicks option for its get subcommand,
# for interactive cell editing.
#------------------------------------------------------------------------------
proc tablelist::addIncrDateTimeWidget {widgetType args} {
    if {![regexp {^(datefield|dateentry|timefield|timeentry)$} $widgetType]} {
	return -code error \
	       "bad widget type \"$widgetType\": must be\
		datefield, dateentry, timefield, or timeentry"
    }

    switch [llength $args] {
	0 {
	    set useClicks 0
	    set name $widgetType
	}

	1 {
	    set arg [lindex $args 0]
	    if {[string compare $arg "-seconds"] == 0} {
		set useClicks 1
		set name $widgetType
	    } else {
		set useClicks 0
		set name $arg
	    }
	}

	2 {
	    set arg0 [lindex $args 0]
	    if {[string compare $arg0 "-seconds"] != 0} {
		return -code error "bad option \"$arg0\": must be -seconds"
	    }

	    set useClicks 1
	    set name [lindex $args 1]
	}

	default {
	    mwutil::wrongNumArgs "addIncrDateTimeWidget\
		    datefield|dateentry|timefield|timeentry ?-seconds? ?name?"
	}
    }
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	"iwidgets::$widgetType %W" \
	$name-putValueCmd	"%W show %T" \
	$name-getValueCmd	"%W get" \
	$name-putTextCmd	"%W show %T" \
	$name-getTextCmd	"%W get" \
	$name-putListCmd	"" \
	$name-getListCmd	"" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-textfont \
	$name-useReqWidth	1 \
	$name-usePadX		[string match "*entry" $widgetType] \
	$name-useFormat		1 \
	$name-isEntryLike	1 \
	$name-reservedKeys	{Left Right Up Down} \
    ]
    if {$useClicks} {
	lappend editWin($name-getValueCmd) -clicks
	set editWin($name-useFormat) 0
    }
    if {[string match "date*" $widgetType]} {
	set editWin($name-focusWin) {[%W component date]}
    } else {
	set editWin($name-focusWin) {[%W component time]}
    }

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addIncrSpinner
#
# Registers the spinner widget from the Iwidgets package for interactive cell
# editing.
#------------------------------------------------------------------------------
proc tablelist::addIncrSpinner {{name spinner}} {
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	"iwidgets::spinner %W -width 0" \
	$name-putValueCmd	"%W clear; %W insert 0 %T" \
	$name-getValueCmd	"%W get" \
	$name-putTextCmd	"%W clear; %W insert 0 %T" \
	$name-getTextCmd	"%W get" \
	$name-putListCmd	"" \
	$name-getListCmd	"" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-textfont \
	$name-useFormat		1 \
	$name-useReqWidth	0 \
	$name-usePadX		1 \
	$name-isEntryLike	1 \
	$name-focusWin		{[%W component entry]} \
	$name-reservedKeys	{Left Right} \
    ]

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addIncrSpinint
#
# Registers the spinint widget from the Iwidgets package for interactive cell
# editing.
#------------------------------------------------------------------------------
proc tablelist::addIncrSpinint {{name spinint}} {
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	"iwidgets::spinint %W -width 0" \
	$name-putValueCmd	"%W clear; %W insert 0 %T" \
	$name-getValueCmd	"%W get" \
	$name-putTextCmd	"%W clear; %W insert 0 %T" \
	$name-getTextCmd	"%W get" \
	$name-putListCmd	"" \
	$name-getListCmd	"" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-textfont \
	$name-useFormat		1 \
	$name-useReqWidth	0 \
	$name-usePadX		1 \
	$name-isEntryLike	1 \
	$name-focusWin		{[%W component entry]} \
	$name-reservedKeys	{Left Right} \
    ]

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addIncrCombobox
#
# Registers the combobox widget from the Iwidgets package for interactive cell
# editing.
#------------------------------------------------------------------------------
proc tablelist::addIncrCombobox {{name combobox}} {
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	"createIncrCombobox %W" \
	$name-putValueCmd	"%W clear entry; %W insert entry 0 %T" \
	$name-getValueCmd	"%W get" \
	$name-putTextCmd	"%W clear entry; %W insert entry 0 %T" \
	$name-getTextCmd	"%W get" \
	$name-putListCmd	{eval [list %W insert list end] %L} \
	$name-getListCmd	"%W component list get 0 end" \
	$name-selectCmd		"%W selection set %I" \
	$name-invokeCmd		"%W invoke" \
	$name-fontOpt		-textfont \
	$name-useFormat		1 \
	$name-useReqWidth	0 \
	$name-usePadX		1 \
	$name-isEntryLike	1 \
	$name-focusWin		{[%W component entry]} \
	$name-reservedKeys	{Left Right Up Down Control-p Control-n} \
    ]

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addCtext
#
# Registers the ctext widget for interactive cell editing.
#------------------------------------------------------------------------------
proc tablelist::addCtext {{name ctext}} {
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	"ctext %W -padx 2 -pady 2 -wrap none" \
	$name-putValueCmd	"%W delete 1.0 end; %W insert 1.0 %T" \
	$name-getValueCmd	"%W get 1.0 end-1c" \
	$name-putTextCmd	"%W delete 1.0 end; %W insert 1.0 %T" \
	$name-getTextCmd	"%W get 1.0 end-1c" \
	$name-putListCmd	"" \
	$name-getListCmd	"" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-font \
	$name-useFormat		1 \
	$name-useReqWidth	0 \
	$name-usePadX		0 \
	$name-isEntryLike	1 \
	$name-focusWin		%W.t \
	$name-reservedKeys	{Left Right Up Down Prior Next
				 Control-Home Control-End Meta-b Meta-f
				 Control-p Control-n Meta-less Meta-greater} \
    ]

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addOakleyCombobox
#
# Registers Bryan Oakley's combobox widget for interactive cell editing.
#------------------------------------------------------------------------------
proc tablelist::addOakleyCombobox {{name combobox}} {
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	"createOakleyCombobox %W" \
	$name-putValueCmd	"%W delete 0 end; %W insert 0 %T" \
	$name-getValueCmd	"%W get" \
	$name-putTextCmd	"%W delete 0 end; %W insert 0 %T" \
	$name-getTextCmd	"%W get" \
	$name-putListCmd	{eval [list %W list insert end] %L} \
	$name-getListCmd	"%W list get 0 end" \
	$name-selectCmd		"%W select %I" \
	$name-invokeCmd		"%W open" \
	$name-fontOpt		-font \
	$name-useFormat		1 \
	$name-useReqWidth	0 \
	$name-usePadX		1 \
	$name-isEntryLike	1 \
	$name-focusWin		%W.entry \
	$name-reservedKeys	{Left Right Up Down Prior Next} \
    ]

    #
    # Patch the ::combobox::UpdateVisualAttributes procedure to make sure it
    # won't change the background and trough colors of the vertical scrollbar
    #
    catch {combobox::combobox}	;# enforces the evaluation of "combobox.tcl"
    if {[catch {rename ::combobox::UpdateVisualAttributes \
		::combobox::_UpdateVisualAttributes}] == 0} {
	proc ::combobox::UpdateVisualAttributes w {
	    set vsbBackground [$w.top.vsb cget -background]
	    set vsbTroughColor [$w.top.vsb cget -troughcolor]

	    ::combobox::_UpdateVisualAttributes $w

	    $w.top.vsb configure -background $vsbBackground
	    $w.top.vsb configure -troughcolor $vsbTroughColor
	}
    }

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addDateMentry
#
# Registers the widget created by the mentry::dateMentry command from the
# Mentry package, with a given format and separator and with or without the
# "-gmt 1" option for the mentry::putClockVal and mentry::getClockVal commands,
# for interactive cell editing.
#------------------------------------------------------------------------------
proc tablelist::addDateMentry {fmt sep args} {
    #
    # Parse the fmt argument
    #
    if {![regexp {^([dmyY])([dmyY])([dmyY])$} $fmt dummy \
		 fields(0) fields(1) fields(2)]} {
	return -code error \
	       "bad format \"$fmt\": must be a string of length 3,\
		consisting of the letters d, m, and y or Y"
    }

    #
    # Check whether all the three date components are represented in fmt
    #
    for {set n 0} {$n < 3} {incr n} {
	set lfields($n) [string tolower $fields($n)]
    }
    if {[string compare $lfields(0) $lfields(1)] == 0 ||
	[string compare $lfields(0) $lfields(2)] == 0 ||
	[string compare $lfields(1) $lfields(2)] == 0} {
	return -code error \
	       "bad format \"$fmt\": must have unique components for the\
		day, month, and year"
    }

    #
    # Parse the remaining arguments (if any)
    #
    switch [llength $args] {
	0 {
	    set useGMT 0
	    set name dateMentry
	}

	1 {
	    set arg [lindex $args 0]
	    if {[string compare $arg "-gmt"] == 0} {
		set useGMT 1
		set name dateMentry
	    } else {
		set useGMT 0
		set name $arg
	    }
	}

	2 {
	    set arg0 [lindex $args 0]
	    if {[string compare $arg0 "-gmt"] != 0} {
		return -code error "bad option \"$arg0\": must be -gmt"
	    }

	    set useGMT 1
	    set name [lindex $args 1]
	}

	default {
	    mwutil::wrongNumArgs "addDateMentry format separator ?-gmt? ?name?"
	}
    }
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	[list mentry::dateMentry %W $fmt $sep] \
	$name-putValueCmd	"mentry::putClockVal %T %W -gmt $useGMT" \
	$name-getValueCmd	"mentry::getClockVal %W -gmt $useGMT" \
	$name-putTextCmd	"" \
	$name-getTextCmd	"%W getstring" \
	$name-putListCmd	{eval [list %W put 0] %L} \
	$name-getListCmd	"%W getlist" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-font \
	$name-useFormat		0 \
	$name-useReqWidth	1 \
	$name-usePadX		1 \
	$name-isEntryLike	1 \
	$name-focusWin		"" \
	$name-reservedKeys	{Left Right Up Down Prior Next} \
    ]

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addTimeMentry
#
# Registers the widget created by the mentry::timeMentry command from the
# Mentry package, with a given format and separator and with or without the
# "-gmt 1" option for the mentry::putClockVal and mentry::getClockVal commands,
# for interactive cell editing.
#------------------------------------------------------------------------------
proc tablelist::addTimeMentry {fmt sep args} {
    #
    # Parse the fmt argument
    #
    if {![regexp {^(H|I)(M)(S?)$} $fmt dummy fields(0) fields(1) fields(2)]} {
	return -code error \
	       "bad format \"$fmt\": must be a string of length 2 or 3\
		starting with H or I, followed by M and optionally by S"
    }

    #
    # Parse the remaining arguments (if any)
    #
    switch [llength $args] {
	0 {
	    set useGMT 0
	    set name timeMentry
	}

	1 {
	    set arg [lindex $args 0]
	    if {[string compare $arg "-gmt"] == 0} {
		set useGMT 1
		set name timeMentry
	    } else {
		set useGMT 0
		set name $arg
	    }
	}

	2 {
	    set arg0 [lindex $args 0]
	    if {[string compare $arg0 "-gmt"] != 0} {
		return -code error "bad option \"$arg0\": must be -gmt"
	    }

	    set useGMT 1
	    set name [lindex $args 1]
	}

	default {
	    mwutil::wrongNumArgs "addTimeMentry format separator ?-gmt? ?name?"
	}
    }
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	[list mentry::timeMentry %W $fmt $sep] \
	$name-putValueCmd	"mentry::putClockVal %T %W -gmt $useGMT" \
	$name-getValueCmd	"mentry::getClockVal %W -gmt $useGMT" \
	$name-putTextCmd	"" \
	$name-getTextCmd	"%W getstring" \
	$name-putListCmd	{eval [list %W put 0] %L} \
	$name-getListCmd	"%W getlist" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-font \
	$name-useFormat		0 \
	$name-useReqWidth	1 \
	$name-usePadX		1 \
	$name-isEntryLike	1 \
	$name-focusWin		"" \
	$name-reservedKeys	{Left Right Up Down Prior Next} \
    ]

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addDateTimeMentry
#
# Registers the widget created by the mentry::dateTimeMentry command from the
# Mentry package, with a given format and given separators and with or without
# the "-gmt 1" option for the mentry::putClockVal and mentry::getClockVal
# commands, for interactive cell editing.
#------------------------------------------------------------------------------
proc tablelist::addDateTimeMentry {fmt dateSep timeSep args} {
    #
    # Parse the fmt argument
    #
    if {![regexp {^([dmyY])([dmyY])([dmyY])(H|I)(M)(S?)$} $fmt dummy \
		 fields(0) fields(1) fields(2) fields(3) fields(4) fields(5)]} {
	return -code error \
	       "bad format \"$fmt\": must be a string of length 5 or 6,\
		with the first 3 characters consisting of the letters d, m,\
		and y or Y, followed by H or I, then M, and optionally by S"
    }

    #
    # Check whether all the three date components are represented in fmt
    #
    for {set n 0} {$n < 3} {incr n} {
	set lfields($n) [string tolower $fields($n)]
    }
    if {[string compare $lfields(0) $lfields(1)] == 0 ||
	[string compare $lfields(0) $lfields(2)] == 0 ||
	[string compare $lfields(1) $lfields(2)] == 0} {
	return -code error \
	       "bad format \"$fmt\": must have unique components for the\
		day, month, and year"
    }

    #
    # Parse the remaining arguments (if any)
    #
    switch [llength $args] {
	0 {
	    set useGMT 0
	    set name dateTimeMentry
	}

	1 {
	    set arg [lindex $args 0]
	    if {[string compare $arg "-gmt"] == 0} {
		set useGMT 1
		set name dateTimeMentry
	    } else {
		set useGMT 0
		set name $arg
	    }
	}

	2 {
	    set arg0 [lindex $args 0]
	    if {[string compare $arg0 "-gmt"] != 0} {
		return -code error "bad option \"$arg0\": must be -gmt"
	    }

	    set useGMT 1
	    set name [lindex $args 1]
	}

	default {
	    mwutil::wrongNumArgs "addDateTimeMentry format dateSeparator\
				  timeSeparator ?-gmt? ?name?"
	}
    }
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	[list mentry::dateTimeMentry %W $fmt \
				      $dateSep $timeSep] \
	$name-putValueCmd	"mentry::putClockVal %T %W -gmt $useGMT" \
	$name-getValueCmd	"mentry::getClockVal %W -gmt $useGMT" \
	$name-putTextCmd	"" \
	$name-getTextCmd	"%W getstring" \
	$name-putListCmd	{eval [list %W put 0] %L} \
	$name-getListCmd	"%W getlist" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-font \
	$name-useFormat		0 \
	$name-useReqWidth	1 \
	$name-usePadX		1 \
	$name-isEntryLike	1 \
	$name-focusWin		"" \
	$name-reservedKeys	{Left Right Up Down Prior Next} \
    ]

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addFixedPointMentry
#
# Registers the widget created by the mentry::fixedPointMentry command from the
# Mentry package, with a given number of characters before and a given number
# of digits after the decimal point, with or without the -comma option, for
# interactive cell editing.
#------------------------------------------------------------------------------
proc tablelist::addFixedPointMentry {cnt1 cnt2 args} {
    #
    # Check the arguments cnt1 and cnt2
    #
    if {![isInteger $cnt1] || $cnt1 <= 0} {
	return -code error "expected positive integer but got \"$cnt1\""
    }
    if {![isInteger $cnt2] || $cnt2 <= 0} {
	return -code error "expected positive integer but got \"$cnt2\""
    }

    #
    # Parse the remaining arguments (if any)
    #
    switch [llength $args] {
	0 {
	    set useComma 0
	    set name fixedPointMentry_$cnt1.$cnt2
	}

	1 {
	    set arg [lindex $args 0]
	    if {[string compare $arg "-comma"] == 0} {
		set useComma 1
		set name fixedPointMentry_$cnt1,$cnt2
	    } else {
		set useComma 0
		set name $arg
	    }
	}

	2 {
	    set arg0 [lindex $args 0]
	    if {[string compare $arg0 "-comma"] != 0} {
		return -code error "bad option \"$arg0\": must be -comma"
	    }

	    set useComma 1
	    set name [lindex $args 1]
	}

	default {
	    mwutil::wrongNumArgs "addFixedPointMentry count1 count2\
				  ?-comma? ?name?"
	}
    }
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	[list mentry::fixedPointMentry %W $cnt1 $cnt2] \
	$name-putValueCmd	"mentry::putReal %T %W" \
	$name-getValueCmd	"mentry::getReal %W" \
	$name-putTextCmd	"" \
	$name-getTextCmd	"%W getstring" \
	$name-putListCmd	{eval [list %W put 0] %L} \
	$name-getListCmd	"%W getlist" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-font \
	$name-useFormat		0 \
	$name-useReqWidth	1 \
	$name-usePadX		1 \
	$name-isEntryLike	1 \
	$name-focusWin		"" \
	$name-reservedKeys	{Left Right} \
    ]
    if {$useComma} {
	lappend editWin($name-creationCmd) -comma
    }

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addIPAddrMentry
#
# Registers the widget created by the mentry::ipAddrMentry command from the
# Mentry package for interactive cell editing.
#------------------------------------------------------------------------------
proc tablelist::addIPAddrMentry {{name ipAddrMentry}} {
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	"mentry::ipAddrMentry %W" \
	$name-putValueCmd	"mentry::putIPAddr %T %W" \
	$name-getValueCmd	"mentry::getIPAddr %W" \
	$name-putTextCmd	"" \
	$name-getTextCmd	"%W getstring" \
	$name-putListCmd	{eval [list %W put 0] %L} \
	$name-getListCmd	"%W getlist" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-font \
	$name-useFormat		0 \
	$name-useReqWidth	1 \
	$name-usePadX		1 \
	$name-isEntryLike	1 \
	$name-focusWin		"" \
	$name-reservedKeys	{Left Right Up Down Prior Next} \
    ]

    return $name
}

#------------------------------------------------------------------------------
# tablelist::addIPv6AddrMentry
#
# Registers the widget created by the mentry::ipv6AddrMentry command from the
# Mentry package for interactive cell editing.
#------------------------------------------------------------------------------
proc tablelist::addIPv6AddrMentry {{name ipv6AddrMentry}} {
    checkEditWinName $name

    variable editWin
    array set editWin [list \
	$name-creationCmd	"mentry::ipv6AddrMentry %W" \
	$name-putValueCmd	"mentry::putIPv6Addr %T %W" \
	$name-getValueCmd	"mentry::getIPv6Addr %W" \
	$name-putTextCmd	"" \
	$name-getTextCmd	"%W getstring" \
	$name-putListCmd	{eval [list %W put 0] %L} \
	$name-getListCmd	"%W getlist" \
	$name-selectCmd		"" \
	$name-invokeCmd		"" \
	$name-fontOpt		-font \
	$name-useFormat		0 \
	$name-useReqWidth	1 \
	$name-usePadX		1 \
	$name-isEntryLike	1 \
	$name-focusWin		"" \
	$name-reservedKeys	{Left Right Up Down Prior Next} \
    ]

    return $name
}

#
# Private procedures implementing the interactive cell editing
# ============================================================
#

#------------------------------------------------------------------------------
# tablelist::checkEditWinName
#
# Generates an error if the given edit window name is one of "entry", "text",
# "spinbox", "checkbutton", "menubutton", "ttk::entry", "ttk::spinbox",
# "ttk::combobox", "ttk::checkbutton", or "ttk::menubutton".
#------------------------------------------------------------------------------
proc tablelist::checkEditWinName name {
    if {[regexp {^(entry|text|spinbox|checkbutton|menubutton)$} $name]} {
	return -code error \
	       "edit window name \"$name\" is reserved for Tk $name widgets"
    }

    if {[regexp {^(::)?ttk::(entry|spinbox|combobox|checkbutton|menubutton)$} \
	 $name]} {
	return -code error \
	       "edit window name \"$name\" is reserved for tile $name widgets"
    }
}

#------------------------------------------------------------------------------
# tablelist::createCheckbutton
#
# Creates a checkbutton widget with the given path name for interactive cell
# editing in a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::createCheckbutton {w args} {
    variable winSys
    switch $winSys {
	x11 {
	    variable checkedImg
	    variable uncheckedImg
	    if {![info exists checkedImg]} {
		createCheckbuttonImgs 
	    }

	    checkbutton $w -borderwidth 2 -indicatoron 0 -image $uncheckedImg \
			   -selectimage $checkedImg
	    if {$::tk_version >= 8.4} {
		$w configure -offrelief sunken
	    }
	    pack $w
	}

	win32 {
	    checkbutton $w -borderwidth 0 -font {"MS Sans Serif" 8} \
			   -padx 0 -pady 0
	    [winfo parent $w] configure -width 13 -height 13
	    switch [winfo reqheight $w] {
		17	{ set y -1 }
		20	{ set y -3 }
		25	{ set y -5 }
		30 -
		31	{ set y -8 }
		default	{ set y -1 }
	    }
	    place $w -x -1 -y $y
	}

	classic {
	    checkbutton $w -borderwidth 0 -font "system" -padx 0 -pady 0
	    [winfo parent $w] configure -width 16 -height 14
	    place $w -x 0 -y -1
	}

	aqua {
	    checkbutton $w -borderwidth 0 -font "system" -padx 0 -pady 0
	    [winfo parent $w] configure -width 16 -height 16
	    place $w -x -4 -y -3
	}
    }

    foreach {opt val} $args {
	switch -- $opt {
	    -state  { $w configure $opt $val }
	    default {}
	}
    }

    set win [getTablelistPath $w]
    $w configure -variable ::tablelist::ns${win}::data(editText)
}

#------------------------------------------------------------------------------
# tablelist::createMenubutton
#
# Creates a menubutton widget with the given path name for interactive cell
# editing in a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::createMenubutton {w args} {
    set win [getTablelistPath $w]
    menubutton $w -anchor w -indicatoron 1 -justify left -padx 2 -pady 2 \
	-relief raised -textvariable ::tablelist::ns${win}::data(editText)

    foreach {opt val} $args {
	$w configure $opt $val
    }

    variable winSys
    upvar ::tablelist::ns${win}::data data
    if {[string compare $winSys "aqua"] == 0} {
	catch {
	    set data(useCustomMDEFSav) $::tk::mac::useCustomMDEF
	    set ::tk::mac::useCustomMDEF 1
	}
    }

    set menu $w.menu
    menu $menu -tearoff 0 -postcommand [list tablelist::postMenuCmd $w]
    foreach event {<Map> <Unmap>} {
	bind $menu $event {
	    tablelist::invokeMotionHandler [tablelist::getTablelistPath %W]
	}
    }
    if {[string compare $winSys "x11"] == 0} {
	$menu configure -background $data(-background) \
			-foreground $data(-foreground) \
			-activebackground $data(-selectbackground) \
			-activeforeground $data(-selectforeground) \
			-activeborderwidth $data(-selectborderwidth)
    }

    $w configure -menu $menu
}

#------------------------------------------------------------------------------
# tablelist::postMenuCmd
#
# Activates the radiobutton entry of the menu associated with the menubutton
# widget having the given path name whose -value option was set to the
# menubutton's text.
#------------------------------------------------------------------------------
proc tablelist::postMenuCmd w {
    set menu [$w cget -menu]
    variable winSys
    if {[string compare $winSys "x11"] == 0} {
	set last [$menu index last]
	if {[string compare $last "none"] != 0} {
	    set text [$w cget -text]
	    for {set idx 0} {$idx <= $last} {incr idx} {
		if {[string compare [$menu type $idx] "radiobutton"] == 0 &&
		    [string compare [$menu entrycget $idx -value] $text] == 0} {
		    $menu activate $idx
		}
	    }
	}
    } else {
	if {[catch {set ::tk::Priv(postedMb) ""}] != 0} {
	    set ::tkPriv(postedMb) ""
	}

	if {[string compare [winfo class $w] "TMenubutton"] == 0} {
	    if {[catch {set ::tk::Priv(popup) $menu}] != 0} {
		set ::tkPriv(popup) $menu
	    }
	}

	if {[string compare $winSys "aqua"] == 0} {
	    set win [getTablelistPath $w]
	    upvar ::tablelist::ns${win}::data data
	    if {[string compare [$data(body) cget -cursor] $data(-cursor)]
		!= 0} {
		$data(body) configure -cursor $data(-cursor)
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::createTileEntry
#
# Creates a tile entry widget with the given path name for interactive cell
# editing in a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::createTileEntry {w args} {
    if {$::tk_version < 8.5 || [regexp {^8\.5a[1-5]$} $::tk_patchLevel]} {
	package require tile 0.6
    }
    createTileAliases 

    #
    # The style of the tile entry widget should have -borderwidth
    # 2 and -padding 1.  For those themes that don't honor the
    # -borderwidth 2 setting, set the padding to another value.
    #
    set win [getTablelistPath $w]
    switch -- [getCurrentTheme] {
	aqua {
	    set padding {0 0 0 -1}
	}

	tileqt {
	    set padding 3
	}

	xpnative {
	    switch [winfo rgb . SystemHighlight] {
		"12593 27242 50629" -
		"37779 41120 28784" -
		"45746 46260 49087" -
		"13107 39321 65535"	{ set padding 2 }
		default			{ set padding 1 }
	    }
	}

	default {
	    set padding 1
	}
    }
    styleConfig Tablelist.TEntry -borderwidth 2 -highlightthickness 0 \
				 -padding $padding

    ttk::entry $w -style Tablelist.TEntry

    foreach {opt val} $args {
	$w configure $opt $val
    }
}

#------------------------------------------------------------------------------
# tablelist::createTileSpinbox
#
# Creates a tile spinbox widget with the given path name for interactive cell
# editing in a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::createTileSpinbox {w args} {
    if {$::tk_version < 8.5 || [regexp {^8\.5a[1-5]$} $::tk_patchLevel]} {
	package require tile 0.8.3
    }
    createTileAliases 

    #
    # The style of the tile entry widget should have -borderwidth
    # 2 and -padding 1.  For those themes that don't honor the
    # -borderwidth 2 setting, set the padding to another value.
    #
    set win [getTablelistPath $w]
    switch -- [getCurrentTheme] {
	aqua {
	    set padding {0 0 0 -1}
	}

	tileqt {
	    set padding 3
	}

	vista {
	    switch [winfo rgb . SystemHighlight] {
		"13107 39321 65535"	{ set padding 0 }
		default			{ set padding 1 }
	    }
	}

	xpnative {
	    switch [winfo rgb . SystemHighlight] {
		"12593 27242 50629" -
		"37779 41120 28784" -
		"45746 46260 49087" -
		"13107 39321 65535"	{ set padding 2 }
		default			{ set padding 1 }
	    }
	}

	default {
	    set padding 1
	}
    }
    styleConfig Tablelist.TSpinbox -borderwidth 2 -highlightthickness 0 \
				   -padding $padding

    ttk::spinbox $w -style Tablelist.TSpinbox

    foreach {opt val} $args {
	$w configure $opt $val
    }
}

#------------------------------------------------------------------------------
# tablelist::createTileCombobox
#
# Creates a tile combobox widget with the given path name for interactive cell
# editing in a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::createTileCombobox {w args} {
    if {$::tk_version < 8.5 || [regexp {^8\.5a[1-5]$} $::tk_patchLevel]} {
	package require tile 0.6
    }
    createTileAliases 

    set win [getTablelistPath $w]
    if {[string compare [getCurrentTheme] "aqua"] == 0} {
	styleConfig Tablelist.TCombobox -borderwidth 2 -padding {0 0 0 -1}
    } else {
	styleConfig Tablelist.TCombobox -borderwidth 2 -padding 1
    }

    ttk::combobox $w -style Tablelist.TCombobox

    foreach {opt val} $args {
	$w configure $opt $val
    }
}

#------------------------------------------------------------------------------
# tablelist::createTileCheckbutton
#
# Creates a tile checkbutton widget with the given path name for interactive
# cell editing in a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::createTileCheckbutton {w args} {
    if {$::tk_version < 8.5 || [regexp {^8\.5a[1-5]$} $::tk_patchLevel]} {
	package require tile 0.6
    }
    createTileAliases 

    #
    # Define the checkbutton layout; use catch to suppress
    # the error message in case the layout already exists
    #
    set currentTheme [getCurrentTheme]
    if {[string compare $currentTheme "aqua"] == 0} {
	catch {style layout Tablelist.TCheckbutton { Checkbutton.button }}
    } else {
	catch {style layout Tablelist.TCheckbutton { Checkbutton.indicator }}
	styleConfig Tablelist.TCheckbutton -indicatormargin 0
    }

    set win [getTablelistPath $w]
    ttk::checkbutton $w -style Tablelist.TCheckbutton \
			-variable ::tablelist::ns${win}::data(editText)

    foreach {opt val} $args {
	switch -- $opt {
	    -state  { $w configure $opt $val }
	    default {}
	}
    }

    #
    # Adjust the dimensions of the tile checkbutton's parent
    # and manage the checkbutton, depending on the current theme
    #
    switch -- $currentTheme {
	aqua {
	    [winfo parent $w] configure -width 16 -height 16
	    place $w -x -3 -y -3
	}

	Aquativo -
	Arc {
	    [winfo parent $w] configure -width 14 -height 14
	    place $w -x -1 -y -1
	}

	blue -
	winxpblue {
	    set height [winfo reqheight $w]
	    [winfo parent $w] configure -width $height -height $height
	    place $w -x 0
	}

	clam {
	    [winfo parent $w] configure -width 11 -height 11
	    place $w -x 0
	}

	clearlooks {
	    [winfo parent $w] configure -width 13 -height 13
	    place $w -x -2 -y -2
	}

	keramik -
	keramik_alt {
	    [winfo parent $w] configure -width 16 -height 16
	    place $w -x -1 -y -1
	}

	plastik {
	    [winfo parent $w] configure -width 15 -height 15
	    place $w -x -2 -y 1
	}

	sriv -
	srivlg {
	    [winfo parent $w] configure -width 15 -height 16
	    place $w -x -1
	}

	tileqt {
	    switch -- [string tolower [tileqt_currentThemeName]] {
		acqua {
		    [winfo parent $w] configure -width 17 -height 18
		    place $w -x -1 -y -2
		}
		cde -
		cleanlooks -
		motif {
		    [winfo parent $w] configure -width 13 -height 13
		    if {[info exists ::env(KDE_SESSION_VERSION)] &&
			[string length $::env(KDE_SESSION_VERSION)] != 0} {
			place $w -x -2
		    } else {
			place $w -x 0
		    }
		}
		gtk+ {
		    [winfo parent $w] configure -width 15 -height 15
		    place $w -x -1 -y -1
		}
		kde_xp {
		    [winfo parent $w] configure -width 13 -height 13
		    place $w -x 0
		}
		keramik -
		thinkeramik {
		    [winfo parent $w] configure -width 16 -height 16
		    place $w -x 0
		}
		oxygen {
		    [winfo parent $w] configure -width 17 -height 17
		    place $w -x -2 -y -1
		}
		default {
		    set height [winfo reqheight $w]
		    [winfo parent $w] configure -width $height -height $height
		    place $w -x 0
		}
	    }
	}

	vista {
	    set height [winfo reqheight $w]
	    [winfo parent $w] configure -width $height -height $height
	    place $w -x 0
	}

	winnative -
	xpnative {
	    set height [winfo reqheight $w]
	    [winfo parent $w] configure -width $height -height $height
	    if {[info exists tile::patchlevel] &&
		[string compare $tile::patchlevel "0.8.0"] < 0} {
		place $w -x -2
	    } else {
		place $w -x 0
	    }
	}

	default {
	    pack $w
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::createTileMenubutton
#
# Creates a tile menubutton widget with the given path name for interactive
# cell editing in a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::createTileMenubutton {w args} {
    if {$::tk_version < 8.5 || [regexp {^8\.5a[1-5]$} $::tk_patchLevel]} {
	package require tile 0.6
    }
    createTileAliases 

    styleConfig Tablelist.TMenubutton -anchor w -justify left -padding 1 \
				      -relief raised

    set win [getTablelistPath $w]
    ttk::menubutton $w -style Tablelist.TMenubutton \
		       -textvariable ::tablelist::ns${win}::data(editText)

    foreach {opt val} $args {
	switch -- $opt {
	    -state  { $w configure $opt $val }
	    default {}
	}
    }

    variable winSys
    upvar ::tablelist::ns${win}::data data
    if {[string compare $winSys "aqua"] == 0} {
	catch {
	    set data(useCustomMDEFSav) $::tk::mac::useCustomMDEF
	    set ::tk::mac::useCustomMDEF 1
	}
    }

    set menu $w.menu
    menu $menu -tearoff 0 -postcommand [list tablelist::postMenuCmd $w]
    if {[string compare $winSys "x11"] == 0} {
	$menu configure -background $data(-background) \
			-foreground $data(-foreground) \
			-activebackground $data(-selectbackground) \
			-activeforeground $data(-selectforeground) \
			-activeborderwidth $data(-selectborderwidth)
    }

    $w configure -menu $menu
}

#------------------------------------------------------------------------------
# tablelist::createBWidgetComboBox
#
# Creates a BWidget ComboBox widget with the given path name for interactive
# cell editing in a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::createBWidgetComboBox {w args} {
    eval [list ComboBox $w -editable 1 -width 0] $args
    ComboBox::_create_popup $w

    foreach event {<Map> <Unmap>} {
	bind $w.shell.listb $event {
	    tablelist::invokeMotionHandler [tablelist::getTablelistPath %W]
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::createIncrCombobox
#
# Creates an [incr Widgets] combobox with the given path name for interactive
# cell editing in a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::createIncrCombobox {w args} {
    eval [list iwidgets::combobox $w -dropdown 1 -editable 1 -width 0] $args

    foreach event {<Map> <Unmap>} {
	bind [$w component list] $event {+
	    tablelist::invokeMotionHandler [tablelist::getTablelistPath %W]
	}
    }

    #
    # Make sure that the entry component will receive the input focus
    # whenever the list component (a scrolledlistbox widget) gets unmapped
    #
    bind [$w component list] <Unmap> +[list focus [$w component entry]]
}

#------------------------------------------------------------------------------
# tablelist::createOakleyCombobox
#
# Creates an Oakley combobox widget with the given path name for interactive
# cell editing in a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::createOakleyCombobox {w args} {
    eval [list combobox::combobox $w -editable 1 -width 0] $args

    foreach event {<Map> <Unmap>} {
	bind $w.top.list $event {
	    tablelist::invokeMotionHandler [tablelist::getTablelistPath %W]
	}
    }

    #
    # Repack the widget's components, to make sure that the
    # button will remain visible when shrinking the combobox.
    # This patch is needed for combobox versions earlier than 2.3.
    #
    pack forget $w.entry $w.button
    pack $w.button -side right -fill y    -expand 0
    pack $w.entry  -side left  -fill both -expand 1
}

#------------------------------------------------------------------------------
# tablelist::doEditCell
#
# Processes the tablelist editcell subcommand.  cmd may be an empty string,
# "condChangeSelection", or "changeSelection".  charPos stands for the
# character position component of the index in the body text widget of the
# character underneath the mouse cursor if this command was invoked by clicking
# mouse button 1 in the body of the tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::doEditCell {win row col restore {cmd ""} {charPos -1}} {
    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled) || ![isRowViewable $win $row] || $data($col-hide) ||
	![isCellEditable $win $row $col]} {
	return ""
    }
    if {$data(editRow) == $row && $data(editCol) == $col} {
	return ""
    }
    if {$data(editRow) >= 0 && ![doFinishEditing $win]} {
	return ""
    }
    set item [lindex $data(itemList) $row]
    set key [lindex $item end]
    getIndentData $win $key $col indentWidth
    set pixels [colWidth $win $col -stretched]
    if {$indentWidth >= $pixels} {
	return ""
    }

    #
    # Create a frame to be embedded into the tablelist's body, together with
    # a child of column/cell-specific type; replace the binding tag Frame with
    # $data(editwinTag) and TablelistEdit in the frame's list of binding tags
    #
    seeCell $win $row $col
    set netRowHeight [lindex [bboxSubCmd $win $row] 3]
    set frameHeight [expr {$netRowHeight + 6}]	;# because of the -pady -3 below
    set f $data(bodyFrm)
    tk::frame $f -borderwidth 0 -container 0 -height $frameHeight \
		 -highlightthickness 0 -relief flat -takefocus 0
    catch {$f configure -padx 0 -pady 0}
    bindtags $f [lreplace [bindtags $f] 1 1 $data(editwinTag) TablelistEdit]
    set name [getEditWindow $win $row $col]
    variable editWin
    set creationCmd [strMap {"%W" "$w"} $editWin($name-creationCmd)]
    append creationCmd { $editWin($name-fontOpt) [getCellFont $win $key $col]} \
		       { -state normal}
    set w $data(bodyFrmEd)
    if {[catch {eval $creationCmd} result] != 0} {
	destroy $f
	return -code error $result
    }
    catch {$w configure -highlightthickness 0}
    clearTakefocusOpt $w
    set class [winfo class $w]
    set isCheckbtn [string match "*Checkbutton" $class]
    set isMenubtn [string match "*Menubutton" $class]
    set isText [expr {[string compare $class "Text"] == 0 ||
		      [string compare $class "Ctext"] == 0}]
    set isMentry [expr {[string compare $class "Mentry"] == 0}]
    if {!$isCheckbtn && !$isMenubtn} {
	catch {$w configure -relief ridge}
	catch {$w configure -borderwidth 2}
    }
    if {$isText && $data($col-wrap) && $::tk_version >= 8.5} {
	$w configure -wrap word
    }
    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
    if {!$isText && !$isMentry} {
	catch {$w configure -justify $alignment}
    }

    #
    # Define some bindings for the above frame
    #
    bind $f <Enter> {
	set tablelist::W [tablelist::getTablelistPath %W]
	set tablelist::ns${tablelist::W}::data(inEditWin) 1
	tablelist::invokeMotionHandler $tablelist::W
    }
    bind $f <Leave> {
	set tablelist::W [tablelist::getTablelistPath %W]
	set tablelist::ns${tablelist::W}::data(inEditWin) 0
	set tablelist::ns${tablelist::W}::data(prevCell) -1,-1
	tablelist::invokeMotionHandler $tablelist::W
    }
    bind $f <Destroy> {
	set tablelist::W [tablelist::getTablelistPath %W]
	array set tablelist::ns${tablelist::W}::data \
	      {editKey ""  editRow -1  editCol -1  inEditWin 0  prevCell -1,-1}
	if {[catch {tk::CancelRepeat}] != 0} {
	    tkCancelRepeat 
	}
	if {[catch {ttk::CancelRepeat}] != 0} {
	    catch {tile::CancelRepeat}
	}
	tablelist::invokeMotionHandler $tablelist::W
    }

    #
    # Replace the cell's contents between the two tabs with the above frame
    #
    array set data [list editKey $key editRow $row editCol $col]
    findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
    set b $data(body)
    getIndentData $win $data(editKey) $data(editCol) indentWidth
    if {$indentWidth == 0} {
	set textIdx [$b index $tabIdx1+1c]
    } else {
	$b mark set editIndentMark [$b index $tabIdx1+1c]
	set textIdx [$b index $tabIdx1+2c]
    }
    if {$isCheckbtn} {
	set editIdx $textIdx
	$b delete $editIdx $tabIdx2
    } else {
	getAuxData $win $data(editKey) $data(editCol) auxType auxWidth
	if {$auxType == 0 || $auxType > 1} {			;# no image
	    set editIdx $textIdx
	    $b delete $editIdx $tabIdx2
	} elseif {[string compare $alignment "right"] == 0} {
	    $b mark set editAuxMark $tabIdx2-1c
	    set editIdx $textIdx
	    $b delete $editIdx $tabIdx2-1c
	} else {
	    $b mark set editAuxMark $textIdx
	    set editIdx [$b index $textIdx+1c]
	    $b delete $editIdx $tabIdx2
	}
    }
    $b window create $editIdx -padx -3 -pady -3 -window $f
    $b mark set editMark $editIdx

    #
    # Insert the binding tags $data(editwinTag) and TablelistEdit
    # into the list of binding tags of some components
    # of w, just before the respective path names
    #
    if {$isMentry} {
	set compList [$w entries]
    } else {
	set comp [subst [strMap {"%W" "$w"} $editWin($name-focusWin)]]
	set compList [list $comp]
	set data(editFocus) $comp
    }
    foreach comp $compList {
	set bindTags [bindtags $comp]
	set idx [lsearch -exact $bindTags $comp]
	bindtags $comp [linsert $bindTags $idx $data(editwinTag) TablelistEdit]
    }

    #
    # Restore or initialize some of the edit window's data
    #
    if {$restore} {
	restoreEditData $win
    } else {
	#
	# Put the cell's contents to the edit window
	#
	set data(canceled) 0
	set data(invoked) 0
	set text [lindex $item $col]
	if {$editWin($name-useFormat) && [lindex $data(fmtCmdFlagList) $col]} {
	    set text [formatElem $win $key $row $col $text]
	}
	catch {
	    eval [strMap {"%W" "$w"  "%T" "$text"} $editWin($name-putValueCmd)]
	}

	#
	# Save the edit window's text
	#
	set data(origEditText) \
	    [eval [strMap {"%W" "$w"} $editWin($name-getTextCmd)]]

	if {[string length $data(-editstartcommand)] != 0} {
	    set text [uplevel #0 $data(-editstartcommand) \
		      [list $win $row $col $text]]

	    variable winSys
	    if {[string compare $winSys "aqua"] == 0} {
		catch {set ::tk::mac::useCustomMDEF $data(useCustomMDEFSav)}
	    }

	    if {$data(canceled)} {
		return ""
	    }

	    catch {
		eval [strMap {"%W" "$w"  "%T" "$text"} \
		      $editWin($name-putValueCmd)]
	    }
	}

	if {$isMenubtn} {
	    set menu [$w cget -menu]
	    set last [$menu index last]
	    if {[string compare $last "none"] != 0} {
		set varName [$w cget -textvariable]
		for {set idx 0} {$idx <= $last} {incr idx} {
		    if {[string compare [$menu type $idx] "radiobutton"] == 0} {
			$menu entryconfigure $idx -variable $varName
		    }
		}
	    }
	}

	#
	# Save the edit window's text again
	#
	set data(origEditText) \
	    [eval [strMap {"%W" "$w"} $editWin($name-getTextCmd)]]
	set data(rejected) 0

	if {[string length $editWin($name-getListCmd)] != 0 &&
	    [string length $editWin($name-selectCmd)] != 0} {
	    #
	    # Select the edit window's item corresponding to text
	    #
	    set itemList [eval [strMap {"%W" "$w"} $editWin($name-getListCmd)]]
	    if {[set idx [lsearch -exact $itemList $text]] >= 0} {
		eval [strMap {"%W" "$w"  "%I" "$idx"} $editWin($name-selectCmd)]
	    }
	}

	#
	# Evaluate the optional command passed as argument
	#
	if {[string length $cmd] != 0} {
	    eval [list $cmd $win $row $col]
	}

	#
	# Set the focus and the insertion cursor
	#
	if {$charPos >= 0} {
	    if {$isText || !$editWin($name-isEntryLike)} {
		focus $w
	    } else {
		set hasAuxObject [expr {
		    [info exists data($key,$col-image)] ||
		    [info exists data($key,$col-window)]}]
		if {[string compare $alignment "right"] == 0} {
		    scan $tabIdx2 "%d.%d" line tabCharIdx2
		    if {$isMentry} {
			set len [string length [$w getstring]]
		    } else {
			set len [$comp index end]
		    }
		    set number [expr {$len - $tabCharIdx2 + $charPos}]
		    if {$hasAuxObject} {
			incr number 2
		    }
		} else {
		    scan $tabIdx1 "%d.%d" line tabCharIdx1
		    set number [expr {$charPos - $tabCharIdx1 - 1}]
		    if {$hasAuxObject} {
			incr number -2
		    }
		}
		if {$isMentry} {
		    setMentryCursor $w $number
		} else {
		    focus $comp
		    $comp icursor $number
		}
	    }
	} else {
	    if {$isText || $isMentry || !$editWin($name-isEntryLike)} {
		focus $w
	    } else {
		focus $comp
		$comp icursor end
		$comp selection range 0 end
	    }
	}
    }

    if {$data(-autofinishediting)} {
	#
	# Make sure that selecting a combobox or menu
	# entry will automatically finish the editing
	#
	switch $class {
	    TCombobox {
		bind $w <<ComboboxSelected>> \
		    {+ [tablelist::getTablelistPath %W] finishediting}
	    }

	    ComboBox {					;# BWidget
		set cmd [$w cget -modifycmd]
		$w configure -modifycmd [format {
		    eval [list %s]
		    after 0 [list %s finishediting]
		} $cmd $win]
	    }

	    Combobox {					;# IWidgets or Oakley
		if {[catch {$w cget -selectioncommand} cmd] == 0} {  ;# IWidgets
		    set cmd [$w cget -selectioncommand]
		    $w configure -selectioncommand [format {
			eval [list %s]
			after 0 [list %s finishediting]
		    } $cmd $win]
		} elseif {[catch {$w cget -command} cmd] == 0} {     ;# Oakley
		    if {[string length $cmd] == 0} {
			proc ::tablelist::comboboxCmd {w val} [format {
			    after 0 [list %s finishediting]
			} $win]
		    } else {
			proc ::tablelist::comboboxCmd {w val} [format {
			    eval [list %s $w $val]
			    after 0 [list %s finishediting]
			} $cmd $win]
		    }
		    $w configure -command ::tablelist::comboboxCmd
		}
	    }

	    Menubutton -
	    TMenubutton {
		set menu [$w cget -menu]
		set last [$menu index last]
		if {[string compare $last "none"] != 0} {
		    for {set idx 0} {$idx <= $last} {incr idx} {
			if {[regexp {^(command|checkbutton|radiobutton)$} \
			     [$menu type $idx]]} {
			    set cmd [$menu entrycget $idx -command]
			    $menu entryconfigure $idx -command [format {
				eval [list %s]
				after 0 [list %s finishediting]
			    } $cmd $win]
			}
		    }
		}
	    }
	}
    }

    #
    # Adjust the frame's height
    #
    if {$isText} {
	if {[string compare [$w cget -wrap] "none"] == 0 ||
	    $::tk_version < 8.5} {
	    set numLines [expr {int([$w index end-1c])}]
	    $w configure -height $numLines
	    update idletasks				;# needed for ctext
	    if {![array exists ::tablelist::ns${win}::data]} {
		return ""
	    }
	    $f configure -height [winfo reqheight $w]
	} else {
	    bind $w <Configure> {
		%W configure -height [%W count -displaylines 1.0 end]
		[winfo parent %W] configure -height [winfo reqheight %W]
	    }
	}
	if {[info exists ::wcb::version]} {
	    wcb::cbappend $w after insert tablelist::adjustTextHeight
	    wcb::cbappend $w after delete tablelist::adjustTextHeight
	}
    } elseif {!$isCheckbtn} {
	update idletasks
	if {![array exists ::tablelist::ns${win}::data]} {
	    return ""
	}
	$f configure -height [winfo reqheight $w]
    }

    #
    # Adjust the frame's width and paddings
    #
    if {!$isCheckbtn} {
	place $w -relwidth 1.0 -relheight 1.0
	adjustEditWindow $win $pixels
	update idletasks
	if {![array exists ::tablelist::ns${win}::data]} {
	    return ""
	}
    }

    updateViewWhenIdle $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::doCancelEditing
#
# Processes the tablelist cancelediting subcommand.  Aborts the interactive
# cell editing and restores the cell's contents after destroying the edit
# window.
#------------------------------------------------------------------------------
proc tablelist::doCancelEditing win {
    upvar ::tablelist::ns${win}::data data
    if {[set row $data(editRow)] < 0} {
	return ""
    }
    set col $data(editCol)

    #
    # Invoke the command specified by the -editendcommand option if needed
    #
    set data(canceled) 1
    if {$data(-forceeditendcommand) &&
	[string length $data(-editendcommand)] != 0} {
	uplevel #0 $data(-editendcommand) \
		[list $win $row $col $data(origEditText)]
    }

    if {[winfo exists $data(bodyFrm)]} {
	destroy $data(bodyFrm)
	set item [lindex $data(itemList) $row]
	set key [lindex $item end]
	foreach opt {-window -image} {
	    if {[info exists data($key,$col$opt)]} {
		doCellConfig $row $col $win $opt $data($key,$col$opt)
		break
	    }
	}
	doCellConfig $row $col $win -text [lindex $item $col]
    }

    focus $data(body)

    set userData [list $row $col]
    genVirtualEvent $win <<TablelistCellRestored>> $userData

    updateViewWhenIdle $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::doFinishEditing
#
# Processes the tablelist finishediting subcommand.  Invokes the command
# specified by the -editendcommand option if needed, and updates the element
# just edited after destroying the edit window if the latter's content was not
# rejected.  Returns 1 on normal termination and 0 otherwise.
#------------------------------------------------------------------------------
proc tablelist::doFinishEditing win {
    upvar ::tablelist::ns${win}::data data
    if {[set row $data(editRow)] < 0} {
	return 1
    }
    set col $data(editCol)

    #
    # Get the edit window's text, and invoke the command
    # specified by the -editendcommand option if needed
    #
    set w $data(bodyFrmEd)
    set name [getEditWindow $win $row $col]
    variable editWin
    set text [eval [strMap {"%W" "$w"} $editWin($name-getTextCmd)]]
    set item [lindex $data(itemList) $row]
    if {!$data(-forceeditendcommand) &&
	[string compare $text $data(origEditText)] == 0} {
	set text [lindex $item $col]
    } else {
	if {[catch {
	    eval [strMap {"%W" "$w"} $editWin($name-getValueCmd)]
	} text] != 0} {
	    set data(rejected) 1
	}
	if {[string length $data(-editendcommand)] != 0} {
	    set text \
		[uplevel #0 $data(-editendcommand) [list $win $row $col $text]]
	}
    }

    #
    # Check whether the input was rejected (by the above "set data(rejected) 1"
    # statement or within the command specified by the -editendcommand option)
    #
    if {$data(rejected)} {
	if {[winfo exists $data(bodyFrm)]} {
	    seeCell $win $row $col
	    if {[string compare [winfo class $w] "Mentry"] != 0} {
		focus $data(editFocus)
	    }
	} else {
	    focus $data(body)
	}

	set data(rejected) 0
	set result 0
    } else {
	if {[winfo exists $data(bodyFrm)]} {
	    destroy $data(bodyFrm)
	    set key [lindex $item end]
	    foreach opt {-window -image} {
		if {[info exists data($key,$col$opt)]} {
		    doCellConfig $row $col $win $opt $data($key,$col$opt)
		    break
		}
	    }
	    doCellConfig $row $col $win -text $text
	    set result 1
	} else {
	    set result 0
	}

	focus $data(body)

	set userData [list $row $col]
	genVirtualEvent $win <<TablelistCellUpdated>> $userData
    }

    updateViewWhenIdle $win
    return $result
}

#------------------------------------------------------------------------------
# tablelist::clearTakefocusOpt
#
# Sets the -takefocus option of all members of the widget hierarchy starting
# with w to 0.
#------------------------------------------------------------------------------
proc tablelist::clearTakefocusOpt w {
    catch {$w configure -takefocus 0}
    foreach c [winfo children $w] {
	clearTakefocusOpt $c
    }
}

#------------------------------------------------------------------------------
# tablelist::adjustTextHeight
#
# This procedure is an after-insert and after-delete callback asociated with a
# (c)text widget used for interactive cell editing.  It sets the height of the
# edit window to the number of lines currently contained in it.
#------------------------------------------------------------------------------
proc tablelist::adjustTextHeight {w args} {
    if {$::tk_version >= 8.5} {
	#
	# Count the display lines (taking into account the line wraps)
	#
	set numLines [$w count -displaylines 1.0 end]
    } else {
	#
	# We can only count the logical lines (irrespective of wrapping)
	#
	set numLines [expr {int([$w index end-1c])}]
    }
    $w configure -height $numLines

    set path [wcb::pathname $w]
    [winfo parent $path] configure -height [winfo reqheight $path]
}

#------------------------------------------------------------------------------
# tablelist::setMentryCursor
#
# Sets the focus to the entry child of the mentry widget w that contains the
# global character position specified by number, and sets the insertion cursor
# in that entry to the relative character position corresponding to number.  If
# that entry is not enabled then the procedure sets the focus to the last
# enabled entry child preceding the found one and sets the insertion cursor to
# its end.
#------------------------------------------------------------------------------
proc tablelist::setMentryCursor {w number} {
    #
    # Find the entry child containing the given character
    # position; if the latter is contained in a label child
    # then take the entry immediately preceding that label
    #
    set entryIdx -1
    set childIdx 0
    set childCount [llength [$w cget -body]]
    foreach c [winfo children $w] {
	set class [winfo class $c]
	switch $class {
	    Entry {
		set str [$c get]
		set entry $c
		incr entryIdx
	    }
	    Frame {
		set str [$c.e get]
		set entry $c.e
		incr entryIdx
	    }
	    Label { set str [$c cget -text] }
	}
	set len [string length $str]

	if {$number < $len} {
	    break
	} elseif {$childIdx < $childCount - 1} {
	    incr number -$len
	}

	incr childIdx
    }

    #
    # If the entry's state is normal then set the focus to this entry and
    # the insertion cursor to the relative character position corresponding
    # to number; otherwise set the focus to the last enabled entry child
    # preceding the found one and set the insertion cursor to its end
    #
    switch $class {
	Entry -
	Frame { set relIdx $number }
	Label { set relIdx end }
    }
    if {[string compare [$entry cget -state] "normal"] == 0} {
	focus $entry
	$entry icursor $relIdx
    } else {
	for {incr entryIdx -1} {$entryIdx >= 0} {incr entryIdx -1} {
	    set entry [$w entrypath $entryIdx]
	    if {[string compare [$entry cget -state] "normal"] == 0} {
		focus $entry
		$entry icursor end
		return ""
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::adjustEditWindow
#
# Adjusts the width and the horizontal padding of the frame containing the edit
# window associated with the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::adjustEditWindow {win pixels} {
    #
    # Adjust the width of the auxiliary object (if any)
    #
    upvar ::tablelist::ns${win}::data data
    set indent [getIndentData $win $data(editKey) $data(editCol) indentWidth]
    set aux [getAuxData $win $data(editKey) $data(editCol) auxType auxWidth]
    if {$indentWidth >= $pixels} {
	set indentWidth $pixels
	set pixels 0
	set auxWidth 0
    } else {
	incr pixels -$indentWidth
	if {$auxType == 1} {					;# image
	    if {$auxWidth + 5 <= $pixels} {
		incr auxWidth 3
		incr pixels -[expr {$auxWidth + 2}]
	    } elseif {$auxWidth <= $pixels} {
		set pixels 0
	    } else {
		set auxWidth $pixels
		set pixels 0
	    }
	}
    }

    if {$indentWidth != 0} {
	insertOrUpdateIndent $data(body) editIndentMark $indent $indentWidth
    }
    if {$auxType == 1} {					;# image
	setImgLabelWidth $data(body) editAuxMark $auxWidth
    }

    #
    # Compute an appropriate width and horizontal
    # padding for the frame containing the edit window
    #
    set name [getEditWindow $win $data(editRow) $data(editCol)]
    variable editWin
    if {$editWin($name-useReqWidth) &&
	[set reqWidth [winfo reqwidth $data(bodyFrmEd)]] <=
	$pixels + 2*$data(charWidth)} {
	set width $reqWidth
	set padX [expr {$reqWidth <= $pixels ? -3 : ($pixels - $reqWidth) / 2}]
    } else {
	if {$editWin($name-usePadX)} {
	    set amount $data(charWidth)
	} else {
	    switch -- $name {
		text { set amount 4 }
		ttk::entry {
		    if {[string compare [getCurrentTheme] "aqua"] == 0} {
			set amount 5
		    } else {
			set amount 3
		    }
		}
		default { set amount 3 }
	    }
	}
	set width [expr {$pixels + 2*$amount}]
	set padX -$amount
    }

    $data(bodyFrm) configure -width $width
    $data(body) window configure editMark -padx $padX
}

#------------------------------------------------------------------------------
# tablelist::setEditWinFont
#
# Sets the font of the edit window associated with the tablelist widget win to
# that of the cell currently being edited.
#------------------------------------------------------------------------------
proc tablelist::setEditWinFont win {
    upvar ::tablelist::ns${win}::data data
    set name [getEditWindow $win $data(editRow) $data(editCol)]
    variable editWin
    if {[string length $editWin($name-fontOpt)] == 0} {
	return ""
    }

    set key [lindex $data(keyList) $data(editRow)]
    set cellFont [getCellFont $win $key $data(editCol)]
    $data(bodyFrmEd) configure $editWin($name-fontOpt) $cellFont

    $data(bodyFrm) configure -height [winfo reqheight $data(bodyFrmEd)]
}

#------------------------------------------------------------------------------
# tablelist::saveEditData
#
# Saves some data of the edit window associated with the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::saveEditData win {
    upvar ::tablelist::ns${win}::data data
    set w $data(bodyFrmEd)
    set entry $data(editFocus)
    set class [winfo class $w]
    set isText [expr {[string compare $class "Text"] == 0 ||
		      [string compare $class "Ctext"] == 0}]
    set isMentry [expr {[string compare $class "Mentry"] == 0}]

    #
    # Miscellaneous data
    #
    set name [getEditWindow $win $data(editRow) $data(editCol)]
    variable editWin
    set data(editText) [eval [strMap {"%W" "$w"} $editWin($name-getTextCmd)]]
    if {[string length $editWin($name-getListCmd)] != 0} {
	set data(editList) \
	    [eval [strMap {"%W" "$w"} $editWin($name-getListCmd)]]
    }
    if {$isText} {
	set data(editPos) [$w index insert]
	set data(textSelRanges) [$w tag ranges sel]
    } elseif {$editWin($name-isEntryLike)} {
	set data(editPos) [$entry index insert]
	if {[set data(entryHadSel) [$entry selection present]]} {
	    set data(entrySelFrom) [$entry index sel.first]
	    set data(entrySelTo)   [$entry index sel.last]
	}
    }
    set data(editHadFocus) \
	[expr {[string compare [focus -lastfor $entry] $entry] == 0}]

    #
    # Configuration options and widget callbacks
    #
    saveEditConfigOpts $w
    if {[info exists ::wcb::version] &&
	$editWin($name-isEntryLike) && !$isMentry} {
	set wcbOptList {insert delete motion}
	if {$isText} {
	    lappend wcbOptList selset selclear
	    if {$::wcb::version >= 3.2} {
		lappend wcbOptList replace
	    }
	}
	foreach when {before after} {
	    foreach opt $wcbOptList {
		set data(entryCb-$when-$opt) \
		    [::wcb::callback $entry $when $opt]
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::saveEditConfigOpts
#
# Saves the non-default values of the configuration options of the edit window
# w associated with a tablelist widget, as well as those of its descendants.
#------------------------------------------------------------------------------
proc tablelist::saveEditConfigOpts w {
    regexp {^(.+)\.body\.f\.(e.*)$} $w dummy win tail
    upvar ::tablelist::ns${win}::data data

    foreach configSet [$w configure] {
	if {[llength $configSet] != 2} {
	    set default [lindex $configSet 3]
	    set current [lindex $configSet 4]
	    if {[string compare $default $current] != 0} {
		set opt [lindex $configSet 0]
		set data($tail$opt) $current
	    }
	}
    }

    foreach c [winfo children $w] {
	saveEditConfigOpts $c
    }

    if {[string match "*Menubutton" [winfo class $w]]} {
	set menu [$w cget -menu]
	set last [$menu index last]
	set types {}

	if {[string compare $last "none"] != 0} {
	    for {set idx 0} {$idx <= $last} {incr idx} {
		lappend types [$menu type $idx]
		foreach configSet [$menu entryconfigure $idx] {
		    set default [lindex $configSet 3]
		    set current [lindex $configSet 4]
		    if {[string compare $default $current] != 0} {
			set opt [lindex $configSet 0]
			set data($menu,$idx$opt) $current
		    }
		}
	    }
	}

	set data($menu:types) $types
    }
}

#------------------------------------------------------------------------------
# tablelist::restoreEditData
#
# Restores some data of the edit window associated with the tablelist widget
# win.
#------------------------------------------------------------------------------
proc tablelist::restoreEditData win {
    upvar ::tablelist::ns${win}::data data
    set w $data(bodyFrmEd)
    set entry $data(editFocus)
    set class [winfo class $w]
    set isText [expr {[string compare $class "Text"] == 0 ||
		      [string compare $class "Ctext"] == 0}]
    set isMentry [expr {[string compare $class "Mentry"] == 0}]
    set isIncrDateTimeWidget [regexp {^(Date.+|Time.+)$} $class]

    #
    # Miscellaneous data
    #
    set name [getEditWindow $win $data(editRow) $data(editCol)]
    variable editWin
    if {[string length $editWin($name-putTextCmd)] != 0} {
	eval [strMap {"%W" "$w"  "%T" "$data(editText)"} \
	      $editWin($name-putTextCmd)]
    }
    if {[string length $editWin($name-putListCmd)] != 0 &&
	[string length $data(editList)] != 0} {
	eval [strMap {"%W" "$w"  "%L" "$data(editList)"} \
	      $editWin($name-putListCmd)]
    }
    if {[string length $editWin($name-selectCmd)] != 0 &&
	[set idx [lsearch -exact $data(editList) $data(editText)]] >= 0} {
	eval [strMap {"%W" "$w"  "%I" "$idx"} $editWin($name-selectCmd)]
    }
    if {$isText} {
	$w mark set insert $data(editPos)
	if {[llength $data(textSelRanges)] != 0} {
	    eval [list $w tag add sel] $data(textSelRanges)
	}
    } elseif {$editWin($name-isEntryLike)} {
	$entry icursor $data(editPos)
	if {$data(entryHadSel)} {
	    $entry selection range $data(entrySelFrom) $data(entrySelTo)
	}
    }
    if {$data(editHadFocus)} {
	focus $entry
    }

    #
    # Configuration options and widget callbacks
    #
    restoreEditConfigOpts $w
    if {[info exists ::wcb::version] &&
	$editWin($name-isEntryLike) && !$isMentry} {
	set wcbOptList {insert delete motion}
	if {$isText} {
	    lappend wcbOptList selset selclear
	    if {$::wcb::version >= 3.2} {
		lappend wcbOptList replace
	    }
	}
	foreach when {before after} {
	    foreach opt $wcbOptList {
		eval [list ::wcb::callback $entry $when $opt] \
		     $data(entryCb-$when-$opt)
	    }
	}
    }

    #
    # If the edit window is a datefield, dateentry, timefield, or timeentry
    # widget then restore its text here, because otherwise it would be
    # overridden when the above invocation of restoreEditConfigOpts sets
    # the widget's -format option.  Note that this is a special case; in
    # general we must restore the text BEFORE the configuration options.
    #
    if {$isIncrDateTimeWidget} {
	eval [strMap {"%W" "$w"  "%T" "$data(editText)"} \
	      $editWin($name-putTextCmd)]
    }
}

#------------------------------------------------------------------------------
# tablelist::restoreEditConfigOpts
#
# Restores the non-default values of the configuration options of the edit
# window w associated with a tablelist widget, as well as those of its
# descendants.
#------------------------------------------------------------------------------
proc tablelist::restoreEditConfigOpts w {
    regexp {^(.+)\.body\.f\.(e.*)$} $w dummy win tail
    upvar ::tablelist::ns${win}::data data
    set isMentry [expr {[string compare [winfo class $w] "Mentry"] == 0}]

    foreach name [array names data $tail-*] {
	set opt [string range $name [string last "-" $name] end]
	if {!$isMentry || [string compare $opt "-body"] != 0} {
	    $w configure $opt $data($name)
	}
	unset data($name)
    }

    foreach c [winfo children $w] {
	restoreEditConfigOpts $c
    }

    if {[string match "*Menubutton" [winfo class $w]]} {
	set menu [$w cget -menu]
	foreach type $data($menu:types) {
	    $menu add $type
	}
	unset data($menu:types)

	foreach name [array names data $menu,*] {
	    regexp {^.+,(.+)(-.+)$} $name dummy idx opt
	    $menu entryconfigure $idx $opt $data($name)
	    unset data($name)
	}
    }
}

#
# Private procedures used in bindings related to interactive cell editing
# =======================================================================
#

#------------------------------------------------------------------------------
# tablelist::defineTablelistEdit
#
# Defines the bindings for the binding tag TablelistEdit.
#------------------------------------------------------------------------------
proc tablelist::defineTablelistEdit {} {
    #
    # Get the supported modifier keys in the set {Alt, Meta, Command} on
    # the current windowing system ("x11", "win32", "classic", or "aqua")
    #
    variable winSys
    switch $winSys {
	x11	{ set modList {Alt Meta} }
	win32	{ set modList {Alt} }
	classic -
	aqua	{ set modList {Command} }
    }

    #
    # Define some bindings for the binding tag TablelistEdit
    #
    bind TablelistEdit <Button-1> {
	#
	# Very short left-clicks on the tablelist's body are sometimes
	# unexpectedly propagated to the edit window just created - make
	# sure they won't be handled by the latter's default bindings
	#
	if {$tablelist::priv(justReleased)} {
	    break
	}

	set tablelist::priv(clickedInEditWin) 1
	focus %W
    }
    bind TablelistEdit <ButtonRelease-1> {
	if {%X >= 0} {				;# i.e., no generated event
	    foreach {tablelist::W tablelist::x tablelist::y} \
		[tablelist::convEventFields %W %x %y] {}

	    set tablelist::priv(x) ""
	    set tablelist::priv(y) ""
	    after cancel $tablelist::priv(afterId)
	    set tablelist::priv(afterId) ""
	    set tablelist::priv(justReleased) 1
	    after 100 [list set tablelist::priv(justReleased) 0]
	    set tablelist::priv(releasedInEditWin) 1
	    if {!$tablelist::priv(clickedInEditWin)} {
		if {$tablelist::priv(justClicked)} {
		    tablelist::moveOrActivate $tablelist::W \
			$tablelist::priv(row) $tablelist::priv(col) 1
		} else {
		    tablelist::moveOrActivate $tablelist::W \
			[$tablelist::W nearest       $tablelist::y] \
			[$tablelist::W nearestcolumn $tablelist::x] \
			[expr {$tablelist::x >= 0 &&
			       $tablelist::x < [winfo width $tablelist::W] &&
			       $tablelist::y >= [winfo y $tablelist::W.body] &&
			       $tablelist::y < [winfo height $tablelist::W]}]
		}
	    }
	    after 100 [list tablelist::condEvalInvokeCmd $tablelist::W]
	}
    }
    bind TablelistEdit <Control-i>    { tablelist::insertChar %W "\t" }
    bind TablelistEdit <Control-j>    { tablelist::insertChar %W "\n" }
    bind TablelistEdit <Escape>       { tablelist::cancelEditing %W }
    foreach key {Return KP_Enter} {
	bind TablelistEdit <$key> {
	    if {[string compare [winfo class %W] "Text"] == 0 ||
		[string compare [winfo class %W] "Ctext"] == 0} {
		tablelist::insertChar %W "\n"
	    } else {
		tablelist::finishEditing %W
	    }
	}
	bind TablelistEdit <Control-$key> {
	    tablelist::finishEditing %W
	}
    }
    bind TablelistEdit <Tab>	      { tablelist::goToNextPrevCell %W  1 }
    bind TablelistEdit <Shift-Tab>    { tablelist::goToNextPrevCell %W -1 }
    bind TablelistEdit <<PrevWindow>> { tablelist::goToNextPrevCell %W -1 }
    foreach modifier $modList {
	bind TablelistEdit <$modifier-Left> {
	    tablelist::goLeftRight %W -1
	}
	bind TablelistEdit <$modifier-Right> {
	    tablelist::goLeftRight %W 1
	}
	bind TablelistEdit <$modifier-Up> {
	    tablelist::goUpDown %W -1
	}
	bind TablelistEdit <$modifier-Down> {
	    tablelist::goUpDown %W 1
	}
	bind TablelistEdit <$modifier-Prior> {
	    tablelist::goToPriorNextPage %W -1
	}
	bind TablelistEdit <$modifier-Next> {
	    tablelist::goToPriorNextPage %W 1
	}
	bind TablelistEdit <$modifier-Home> {
	    tablelist::goToNextPrevCell %W 1 0 -1
	}
	bind TablelistEdit <$modifier-End> {
	    tablelist::goToNextPrevCell %W -1 0 0
	}
    }
    foreach direction {Left Right} amount {-1 1} {
	bind TablelistEdit <$direction> [format {
	    if {![tablelist::isKeyReserved %%W %%K]} {
		tablelist::goLeftRight %%W %d
	    }
	} $amount]
    }
    foreach direction {Up Down} amount {-1 1} {
	bind TablelistEdit <$direction> [format {
	    if {![tablelist::isKeyReserved %%W %%K]} {
		tablelist::goUpDown %%W %d
	    }
	} $amount]
    }
    foreach page {Prior Next} amount {-1 1} {
	bind TablelistEdit <$page> [format {
	    if {![tablelist::isKeyReserved %%W %%K]} {
		tablelist::goToPriorNextPage %%W %d
	    }
	} $amount]
    }
    bind TablelistEdit <Control-Home> {
	if {![tablelist::isKeyReserved %W Control-Home]} {
	    tablelist::goToNextPrevCell %W 1 0 -1
	}
    }
    bind TablelistEdit <Control-End> {
	if {![tablelist::isKeyReserved %W Control-End]} {
	    tablelist::goToNextPrevCell %W -1 0 0
	}
    }
    foreach pattern {Tab Shift-Tab ISO_Left_Tab hpBackTab} {
	catch {
	    foreach modifier {Control Meta} {
		bind TablelistEdit <$modifier-$pattern> [format {
		    mwutil::processTraversal %%W Tablelist <%s>
		} $pattern]
	    }
	}
    }
    bind TablelistEdit <FocusIn> {
	set tablelist::W [tablelist::getTablelistPath %W]
	set tablelist::ns${tablelist::W}::data(editFocus) %W
    }

    #
    # Define some emacs-like key bindings for the binding tag TablelistEdit
    #
    foreach pattern {Meta-b Meta-f} amount {-1 1} {
	bind TablelistEdit <$pattern> [format {
	    if {!$tk_strictMotif && ![tablelist::isKeyReserved %%W %s]} {
		tablelist::goLeftRight %%W %d
	    }
	} $pattern $amount]
    }
    foreach pattern {Control-p Control-n} amount {-1 1} {
	bind TablelistEdit <$pattern> [format {
	    if {!$tk_strictMotif && ![tablelist::isKeyReserved %%W %s]} {
		tablelist::goUpDown %%W %d
	    }
	} $pattern $amount]
    }
    bind TablelistEdit <Meta-less> {
	if {!$tk_strictMotif &&
	    ![tablelist::isKeyReserved %W Meta-less]} {
	    tablelist::goToNextPrevCell %W 1 0 -1
	}
    }
    bind TablelistEdit <Meta-greater> {
	if {!$tk_strictMotif &&
	    ![tablelist::isKeyReserved %W Meta-greater]} {
	    tablelist::goToNextPrevCell %W -1 0 0
	}
    }

    #
    # Define some bindings for the binding tag TablelistEdit that
    # propagate the mousewheel events to the tablelist's body
    #
    catch {
	bind TablelistEdit <MouseWheel> {
	    if {![tablelist::hasMouseWheelBindings %W] &&
		![tablelist::isComboTopMapped %W]} {
		tablelist::genMouseWheelEvent \
		    [[tablelist::getTablelistPath %W] bodypath] %D
	    }
	}
	bind TablelistEdit <Option-MouseWheel> {
	    if {![tablelist::hasMouseWheelBindings %W] &&
		![tablelist::isComboTopMapped %W]} {
		tablelist::genOptionMouseWheelEvent \
		    [[tablelist::getTablelistPath %W] bodypath] %D
	    }
	}
    }
    foreach detail {4 5} {
	bind TablelistEdit <Button-$detail> [format {
	    if {![tablelist::hasMouseWheelBindings %%W] &&
		![tablelist::isComboTopMapped %%W]} {
		event generate \
		    [[tablelist::getTablelistPath %%W] bodypath] <Button-%s>
	    }
	} $detail]
    }
}

#------------------------------------------------------------------------------
# tablelist::insertChar
#
# Inserts the string str ("\t" or "\n") into the entry-like widget w at the
# point of the insertion cursor.
#------------------------------------------------------------------------------
proc tablelist::insertChar {w str} {
    set class [winfo class $w]
    if {[string compare $class "Text"] == 0 ||
	[string compare $class "Ctext"] == 0} {
	if {[string compare $str "\n"] == 0} {
	    eval [strMap {"%W" "$w"} [bind Text <Return>]]
	} else {
	    eval [strMap {"%W" "$w"} [bind Text <Control-i>]]
	}
	return -code break ""
    } elseif {[regexp {^(T?Entry|TCombobox|T?Spinbox)$} $class]} {
	if {[string match "T*" $class]} {
	    if {[string length [info procs "::ttk::entry::Insert"]] != 0} {
		ttk::entry::Insert $w $str
	    } else {
		tile::entry::Insert $w $str
	    }
	} elseif {[string length [info procs "::tk::EntryInsert"]] != 0} {
	    tk::EntryInsert $w $str
	} else {
	    tkEntryInsert $w $str
	}
	return -code break ""
    }
}

#------------------------------------------------------------------------------
# tablelist::cancelEditing
#
# Invokes the doCancelEditing procedure.
#------------------------------------------------------------------------------
proc tablelist::cancelEditing w {
    if {[isComboTopMapped $w]} {
	return ""
    }

    set win [getTablelistPath $w]
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(sourceRow)]} {	;# move operation in progress
	return ""
    }

    doCancelEditing $win
    return -code break ""
}

#------------------------------------------------------------------------------
# tablelist::finishEditing
#
# Invokes the doFinishEditing procedure.
#------------------------------------------------------------------------------
proc tablelist::finishEditing w {
    if {[isComboTopMapped $w]} {
	return ""
    }

    doFinishEditing [getTablelistPath $w]
    return -code break ""
}

#------------------------------------------------------------------------------
# tablelist::goToNextPrevCell
#
# Moves the edit window into the next or previous editable cell different from
# the one indicated by the given row and column, if there is such a cell.
#------------------------------------------------------------------------------
proc tablelist::goToNextPrevCell {w amount args} {
    if {[isComboTopMapped $w]} {
	return ""
    }

    variable winSys
    if {[string compare $winSys "aqua"] == 0 &&
	([string length $::tk::Priv(postedMb)] != 0 ||
	 [string length $::tk::Priv(popup)] != 0)} {
	return ""
    }

    set win [getTablelistPath $w]
    upvar ::tablelist::ns${win}::data data

    if {[llength $args] == 0} {
	set row $data(editRow)
	set col $data(editCol)
	set cmd condChangeSelection
    } else {
	foreach {row col} $args {}
	set cmd changeSelection
    }

    if {![doFinishEditing $win]} {
	return ""
    }

    set oldRow $row
    set oldCol $col

    while 1 {
	incr col $amount
	if {$col < 0} {
	    incr row $amount
	    if {$row < 0} {
		set row $data(lastRow)
	    }
	    set col $data(lastCol)
	} elseif {$col > $data(lastCol)} {
	    incr row $amount
	    if {$row > $data(lastRow)} {
		set row 0
	    }
	    set col 0
	}

	if {$row == $oldRow && $col == $oldCol} {
	    return -code break ""
	} elseif {[isRowViewable $win $row] && !$data($col-hide) &&
		  [isCellEditable $win $row $col]} {
	    doEditCell $win $row $col 0 $cmd
	    return -code break ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::goLeftRight
#
# Moves the edit window into the previous or next editable cell of the current
# row if the cell being edited is not the first/last editable one within that
# row.
#------------------------------------------------------------------------------
proc tablelist::goLeftRight {w amount} {
    if {[isComboTopMapped $w]} {
	return ""
    }

    set win [getTablelistPath $w]
    upvar ::tablelist::ns${win}::data data

    set row $data(editRow)
    set col $data(editCol)

    if {![doFinishEditing $win]} {
	return ""
    }

    while 1 {
	incr col $amount
	if {$col < 0 || $col > $data(lastCol)} {
	    return -code break ""
	} elseif {!$data($col-hide) && [isCellEditable $win $row $col]} {
	    doEditCell $win $row $col 0 condChangeSelection
	    return -code break ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::goUpDown
#
# Invokes the goToPrevNextLine procedure.
#------------------------------------------------------------------------------
proc tablelist::goUpDown {w amount} {
    if {[isComboTopMapped $w]} {
	return ""
    }

    set win [getTablelistPath $w]
    upvar ::tablelist::ns${win}::data data

    goToPrevNextLine $w $amount $data(editRow) $data(editCol) \
	condChangeSelection
    return -code break ""
}

#------------------------------------------------------------------------------
# tablelist::goToPrevNextLine
#
# Moves the edit window into the last or first editable cell that is located in
# the specified column and has a row index less/greater than the given one, if
# there is such a cell.
#------------------------------------------------------------------------------
proc tablelist::goToPrevNextLine {w amount row col cmd} {
    set win [getTablelistPath $w]
    upvar ::tablelist::ns${win}::data data

    if {![doFinishEditing $win]} {
	return ""
    }

    while 1 {
	incr row $amount
	if {$row < 0 || $row > $data(lastRow)} {
	    return 0
	} elseif {[isRowViewable $win $row] &&
		  [isCellEditable $win $row $col]} {
	    doEditCell $win $row $col 0 $cmd
	    return 1
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::goToPriorNextPage
#
# Moves the edit window up or down by one page within the current column if the
# cell being edited is not the first/last editable one within that column.
#------------------------------------------------------------------------------
proc tablelist::goToPriorNextPage {w amount} {
    if {[isComboTopMapped $w]} {
	return ""
    }

    set win [getTablelistPath $w]
    upvar ::tablelist::ns${win}::data data

    #
    # Check whether there is any viewable editable cell
    # above/below the current one, in the same column
    #
    set row $data(editRow)
    set col $data(editCol)
    while 1 {
	incr row $amount
	if {$row < 0 || $row > $data(lastRow)} {
	    return -code break ""
	} elseif {[isRowViewable $win $row] &&
		  [isCellEditable $win $row $col]} {
	    break
	}
    }

    #
    # Scroll up/down the view by one page and get the corresponding row index
    #
    set row $data(editRow)
    seeRow $win $row
    set bbox [bboxSubCmd $win $row]
    yviewSubCmd $win [list scroll $amount pages]
    set newRow [rowIndex $win @0,[lindex $bbox 1] 0]

    if {$amount < 0} {
	if {$newRow < $row} {
	    if {![goToPrevNextLine $w -1 [expr {$newRow + 1}] $col \
		  changeSelection]} {
		goToPrevNextLine $w 1 $newRow $col changeSelection
	    }
	} else {
	    goToPrevNextLine $w 1 -1 $col changeSelection
	}
    } else {
	if {$newRow > $row} {
	    if {![goToPrevNextLine $w 1 [expr {$newRow - 1}] $col \
		  changeSelection]} {
		goToPrevNextLine $w -1 $newRow $col changeSelection
	    }
	} else {
	    goToPrevNextLine $w -1 $data(itemCount) $col changeSelection
	}
    }

    return -code break ""
}

#------------------------------------------------------------------------------
# tablelist::genMouseWheelEvent
#
# Generates a <MouseWheel> event with the given delta on the widget w.
#------------------------------------------------------------------------------
proc tablelist::genMouseWheelEvent {w delta} {
    set focus [focus -displayof $w]
    focus $w
    event generate $w <MouseWheel> -delta $delta
    focus $focus
}

#------------------------------------------------------------------------------
# tablelist::genOptionMouseWheelEvent
#
# Generates an <Option-MouseWheel> event with the given delta on the widget w.
#------------------------------------------------------------------------------
proc tablelist::genOptionMouseWheelEvent {w delta} {
    set focus [focus -displayof $w]
    focus $w
    event generate $w <Option-MouseWheel> -delta $delta
    focus $focus
}

#------------------------------------------------------------------------------
# tablelist::isKeyReserved
#
# Checks whether the given keysym is used in the standard binding scripts
# associated with the widget w, which is assumed to be the edit window or one
# of its descendants.
#------------------------------------------------------------------------------
proc tablelist::isKeyReserved {w keySym} {
    set win [getTablelistPath $w]
    upvar ::tablelist::ns${win}::data data

    set name [getEditWindow $win $data(editRow) $data(editCol)]
    variable editWin
    return [expr {[lsearch -exact $editWin($name-reservedKeys) $keySym] >= 0}]
}

#------------------------------------------------------------------------------
# tablelist::hasMouseWheelBindings
#
# Checks whether the given widget, which is assumed to be the edit window or
# one of its descendants, has mouse wheel bindings.
#------------------------------------------------------------------------------
proc tablelist::hasMouseWheelBindings w {
    if {[regexp {^(Text|Ctext|TCombobox|TSpinbox)$} [winfo class $w]]} {
	return 1
    } else {
	set bindTags [bindtags $w]
	return [expr {([lsearch -exact $bindTags "MentryDateTime"] >= 0 ||
		       [lsearch -exact $bindTags "MentryMeridian"] >= 0 ||
		       [lsearch -exact $bindTags "MentryIPAddr"] >= 0 ||
		       [lsearch -exact $bindTags "MentryIPv6Addr"] >= 0) &&
		      ($mentry::version >= 3.2)}]
    }
}

#------------------------------------------------------------------------------
# tablelist::isComboTopMapped
#
# Checks whether the given widget is a component of an Oakley combobox having
# its toplevel child mapped.  This is needed in our binding scripts to make
# sure that the interactive cell editing won't be terminated prematurely,
# because Bryan Oakley's combobox keeps the focus on its entry child even if
# its toplevel component is mapped.
#------------------------------------------------------------------------------
proc tablelist::isComboTopMapped w {
    set par [winfo parent $w]
    if {[string compare [winfo class $par] "Combobox"] == 0 &&
	[winfo exists $par.top] && [winfo ismapped $par.top]} {
	return 1
    } else {
	return 0
    }
}
#==============================================================================
# Contains procedures that create various bitmap and photo images.  The
# argument w specifies a canvas displaying a sort arrow, while the argument win
# stands for a tablelist widget.
#
# Copyright (c) 2006-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#------------------------------------------------------------------------------
# tablelist::flat5x3Arrows
#------------------------------------------------------------------------------
proc tablelist::flat5x3Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp5x3_width 5
#define triangleUp5x3_height 3
static unsigned char triangleUp5x3_bits[] = {
   0x04, 0x0e, 0x1f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn5x3_width 5
#define triangleDn5x3_height 3
static unsigned char triangleDn5x3_bits[] = {
   0x1f, 0x0e, 0x04};
"
}

#------------------------------------------------------------------------------
# tablelist::flat5x4Arrows
#------------------------------------------------------------------------------
proc tablelist::flat5x4Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp5x4_width 5
#define triangleUp5x4_height 4
static unsigned char triangleUp5x4_bits[] = {
   0x04, 0x0e, 0x1f, 0x1f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn5x4_width 5
#define triangleDn5x4_height 4
static unsigned char triangleDn5x4_bits[] = {
   0x1f, 0x1f, 0x0e, 0x04};
"
}

#------------------------------------------------------------------------------
# tablelist::flat6x4Arrows
#------------------------------------------------------------------------------
proc tablelist::flat6x4Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp6x4_width 6
#define triangleUp6x4_height 4
static unsigned char triangleUp6x4_bits[] = {
   0x0c, 0x1e, 0x3f, 0x3f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn6x4_width 6
#define triangleDn6x4_height 4
static unsigned char triangleDn7x4_bits[] = {
   0x3f, 0x3f, 0x1e, 0x0c};
"
}

#------------------------------------------------------------------------------
# tablelist::flat7x4Arrows
#------------------------------------------------------------------------------
proc tablelist::flat7x4Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp7x4_width 7
#define triangleUp7x4_height 4
static unsigned char triangleUp7x4_bits[] = {
   0x08, 0x1c, 0x3e, 0x7f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn7x4_width 7
#define triangleDn7x4_height 4
static unsigned char triangleDn7x4_bits[] = {
   0x7f, 0x3e, 0x1c, 0x08};
"
}

#------------------------------------------------------------------------------
# tablelist::flat7x5Arrows
#------------------------------------------------------------------------------
proc tablelist::flat7x5Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp7x5_width 7
#define triangleUp7x5_height 5
static unsigned char triangleUp7x5_bits[] = {
   0x08, 0x1c, 0x3e, 0x7f, 0x7f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn7x5_width 7
#define triangleDn7x5_height 5
static unsigned char triangleDn7x5_bits[] = {
   0x7f, 0x7f, 0x3e, 0x1c, 0x08};
"
}

#------------------------------------------------------------------------------
# tablelist::flat7x7Arrows
#------------------------------------------------------------------------------
proc tablelist::flat7x7Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp7x7_width 7
#define triangleUp7x7_height 7
static unsigned char triangleUp7x7_bits[] = {
   0x08, 0x1c, 0x1c, 0x3e, 0x3e, 0x7f, 0x7f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn7x7_width 7
#define triangleDn7x7_height 7
static unsigned char triangleDn7x7_bits[] = {
   0x7f, 0x7f, 0x3e, 0x3e, 0x1c, 0x1c, 0x08};
"
}

#------------------------------------------------------------------------------
# tablelist::flat8x4Arrows
#------------------------------------------------------------------------------
proc tablelist::flat8x4Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp8x4_width 8
#define triangleUp8x4_height 4
static unsigned char triangleUp8x4_bits[] = {
   0x18, 0x3c, 0x7e, 0xff};
"
    image create bitmap triangleDn$w -data "
#define triangleDn8x4_width 8
#define triangleDn8x4_height 4
static unsigned char triangleDn8x4_bits[] = {
   0xff, 0x7e, 0x3c, 0x18};
"
}

#------------------------------------------------------------------------------
# tablelist::flat8x5Arrows
#------------------------------------------------------------------------------
proc tablelist::flat8x5Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp8x5_width 8
#define triangleUp8x5_height 5
static unsigned char triangleUp8x5_bits[] = {
   0x18, 0x3c, 0x7e, 0xff, 0xff};
"
    image create bitmap triangleDn$w -data "
#define triangleDn8x5_width 8
#define triangleDn8x5_height 5
static unsigned char triangleDn8x5_bits[] = {
   0xff, 0xff, 0x7e, 0x3c, 0x18};
"
}

#------------------------------------------------------------------------------
# tablelist::flat9x5Arrows
#------------------------------------------------------------------------------
proc tablelist::flat9x5Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp9x5_width 9
#define triangleUp9x5_height 5
static unsigned char triangleUp9x5_bits[] = {
   0x10, 0x00, 0x38, 0x00, 0x7c, 0x00, 0xfe, 0x00, 0xff, 0x01};
"
    image create bitmap triangleDn$w -data "
#define triangleDn9x5_width 9
#define triangleDn9x5_height 5
static unsigned char triangleDn9x5_bits[] = {
   0xff, 0x01, 0xfe, 0x00, 0x7c, 0x00, 0x38, 0x00, 0x10, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flat9x6Arrows
#------------------------------------------------------------------------------
proc tablelist::flat9x6Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp9x6_width 9
#define triangleUp9x6_height 6
static unsigned char triangleUp9x6_bits[] = {
   0x10, 0x00, 0x38, 0x00, 0x7c, 0x00, 0xfe, 0x00, 0xff, 0x01, 0xff, 0x01};
"
    image create bitmap triangleDn$w -data "
#define triangleDn9x6_width 9
#define triangleDn9x6_height 6
static unsigned char triangleDn9x6_bits[] = {
   0xff, 0x01, 0xff, 0x01, 0xfe, 0x00, 0x7c, 0x00, 0x38, 0x00, 0x10, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flat11x6Arrows
#------------------------------------------------------------------------------
proc tablelist::flat11x6Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp11x6_width 11
#define triangleUp11x6_height 6
static unsigned char triangleUp11x6_bits[] = {
   0x20, 0x00, 0x70, 0x00, 0xf8, 0x00, 0xfc, 0x01, 0xfe, 0x03, 0xff, 0x07};
"
    image create bitmap triangleDn$w -data "
#define triangleDn11x6_width 11
#define triangleDn11x6_height 6
static unsigned char triangleDn11x6_bits[] = {
   0xff, 0x07, 0xfe, 0x03, 0xfc, 0x01, 0xf8, 0x00, 0x70, 0x00, 0x20, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flat15x8Arrows
#------------------------------------------------------------------------------
proc tablelist::flat15x8Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp15x8_width 15
#define triangleUp15x8_height 8
static unsigned char triangleUp15x8_bits[] = {
   0x80, 0x00, 0xc0, 0x01, 0xe0, 0x03, 0xf0, 0x07, 0xf8, 0x0f, 0xfc, 0x1f,
   0xfe, 0x3f, 0xff, 0x7f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn15x8_width 15
#define triangleDn15x8_height 8
static unsigned char triangleDn15x8_bits[] = {
   0xff, 0x7f, 0xfe, 0x3f, 0xfc, 0x1f, 0xf8, 0x0f, 0xf0, 0x07, 0xe0, 0x03,
   0xc0, 0x01, 0x80, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle7x4Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle7x4Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp7x4_width 7
#define triangleUp7x4_height 4
static unsigned char triangleUp7x4_bits[] = {
   0x08, 0x1c, 0x36, 0x63};
"
    image create bitmap triangleDn$w -data "
#define triangleDn7x4_width 7
#define triangleDn7x4_height 4
static unsigned char triangleDn7x4_bits[] = {
   0x63, 0x36, 0x1c, 0x08};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle7x5Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle7x5Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp7x5_width 7
#define triangleUp7x5_height 5
static unsigned char triangleUp7x5_bits[] = {
   0x08, 0x1c, 0x3e, 0x77, 0x63};
"
    image create bitmap triangleDn$w -data "
#define triangleDn7x5_width 7
#define triangleDn7x5_height 5
static unsigned char triangleDn7x5_bits[] = {
   0x63, 0x77, 0x3e, 0x1c, 0x08};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle9x5Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle9x5Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp9x5_width 9
#define triangleUp9x5_height 5
static unsigned char triangleUp9x5_bits[] = {
   0x10, 0x00, 0x38, 0x00, 0x6c, 0x00, 0xc6, 0x00, 0x83, 0x01};
"
    image create bitmap triangleDn$w -data "
#define triangleDn9x5_width 9
#define triangleDn9x5_height 5
static unsigned char triangleDn9x5_bits[] = {
   0x83, 0x01, 0xc6, 0x00, 0x6c, 0x00, 0x38, 0x00, 0x10, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle9x6Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle9x6Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp9x6_width 9
#define triangleUp9x6_height 6
static unsigned char triangleUp9x6_bits[] = {
   0x10, 0x00, 0x38, 0x00, 0x7c, 0x00, 0xee, 0x00, 0xc7, 0x01, 0x83, 0x01};
"
    image create bitmap triangleDn$w -data "
#define triangleDn9x6_width 9
#define triangleDn9x6_height 6
static unsigned char triangleDn9x6_bits[] = {
   0x83, 0x01, 0xc7, 0x01, 0xee, 0x00, 0x7c, 0x00, 0x38, 0x00, 0x10, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle9x7Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle9x7Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp9x7_width 9
#define triangleUp9x7_height 7
static unsigned char triangleUp9x7_bits[] = {
   0x10, 0x00, 0x38, 0x00, 0x7c, 0x00, 0xfe, 0x00, 0xef, 0x01, 0xc7, 0x01,
   0x83, 0x01};
"
    image create bitmap triangleDn$w -data "
#define triangleDn9x7_width 9
#define triangleDn9x7_height 7
static unsigned char triangleDn9x7_bits[] = {
   0x83, 0x01, 0xc7, 0x01, 0xef, 0x01, 0xfe, 0x00, 0x7c, 0x00, 0x38, 0x00,
   0x10, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle10x6Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle10x6Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp10x6_width 10
#define triangleUp10x6_height 6
static unsigned char triangleUp10x6_bits[] = {
   0x30, 0x00, 0x78, 0x00, 0xfc, 0x00, 0xce, 0x01, 0x87, 0x03, 0x03, 0x03};
"
    image create bitmap triangleDn$w -data "
#define triangleDn10x6_width 10
#define triangleDn10x6_height 6
static unsigned char triangleDn10x6_bits[] = {
   0x03, 0x03, 0x87, 0x03, 0xce, 0x01, 0xfc, 0x00, 0x78, 0x00, 0x30, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle10x7Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle10x7Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp10x7_width 10
#define triangleUp10x7_height 7
static unsigned char triangleUp10x7_bits[] = {
   0x30, 0x00, 0x78, 0x00, 0xfc, 0x00, 0xfe, 0x01, 0xcf, 0x03, 0x87, 0x03,
   0x03, 0x03};
"
    image create bitmap triangleDn$w -data "
#define triangleDn10x7_width 10
#define triangleDn10x7_height 7
static unsigned char triangleDn10x6_bits[] = {
   0x03, 0x03, 0x87, 0x03, 0xcf, 0x03, 0xfe, 0x01, 0xfc, 0x00, 0x78, 0x00,
   0x30, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle11x6Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle11x6Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp11x6_width 11
#define triangleUp11x6_height 6
static unsigned char triangleUp11x6_bits[] = {
   0x20, 0x00, 0x70, 0x00, 0xd8, 0x00, 0x8c, 0x01, 0x06, 0x03, 0x03, 0x06};
"
    image create bitmap triangleDn$w -data "
#define triangleDn11x6_width 11
#define triangleDn11x6_height 6
static unsigned char triangleDn11x6_bits[] = {
   0x03, 0x06, 0x06, 0x03, 0x8c, 0x01, 0xd8, 0x00, 0x70, 0x00, 0x20, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::flatAngle15x8Arrows
#------------------------------------------------------------------------------
proc tablelist::flatAngle15x8Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp15x8_width 15
#define triangleUp15x8_height 8
static unsigned char triangleUp15x8_bits[] = {
   0x80, 0x00, 0xc0, 0x01, 0x60, 0x03, 0x30, 0x06, 0x18, 0x0c, 0x0c, 0x18,
   0x06, 0x30, 0x03, 0x60};
"
    image create bitmap triangleDn$w -data "
#define triangleDn15x8_width 15
#define triangleDn15x8_height 8
static unsigned char triangleDn15x8_bits[] = {
   0x03, 0x60, 0x06, 0x30, 0x0c, 0x18, 0x18, 0x0c, 0x30, 0x06, 0x60, 0x03,
   0xc0, 0x01, 0x80, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::photo7x4Arrows
#------------------------------------------------------------------------------
proc tablelist::photo7x4Arrows w {
    foreach dir {Up Dn} {
	image create photo triangle$dir$w
    }

    triangleUp$w put "
R0lGODlhBwAEAIQRAAAAADxZbDxeckNfb0BidF6IoWGWtlabwIexxZq2xYbI65HL7LXd8rri9MPk
9cTj9Mrm9f///////////////////////////////////////////////////////////yH5BAEK
AB8ALAAAAAAHAAQAAAUS4CcSYikcRRkYypJ8A9IwD+SEADs=
"
    triangleDn$w put "
R0lGODlhBwAEAIQQAAAAADxeclKLq2KauWes03CpxnKrynOy2IO62ZXG4JrH4JrL5pnQ7qbY87Pb
8cTj9P///////////////////////////////////////////////////////////////yH5BAEK
AAAALAAAAAAHAAQAAAUSYDAUBpIogHAwzgO8ROO+70KHADs=
"
}

#------------------------------------------------------------------------------
# tablelist::photo7x7Arrows
#------------------------------------------------------------------------------
proc tablelist::photo7x7Arrows w {
    foreach dir {Up Dn} {
	image create photo triangle$dir$w
    }

    triangleUp$w put "
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAACXBIWXMAAA7DAAAOwwHHb6hk
AAAAGnRFWHRTb2Z0d2FyZQBQYWludC5ORVQgdjMuNS4xMDD0cqEAAABCSURBVBhXXY4BCgAgCAP9
T//R9/Ryc+ZEHCyb40CB3D1n6OAZuQOKi9klPhUsjNJ6VwUp+tOLopOGNkXncToWw6IPjiowJNyp
gu8AAAAASUVORK5CYII=
"
    triangleDn$w put "
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAHCAYAAADEUlfTAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwwAADsMBx2+oZAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAP0lE
QVQYV22LgQ0AIAjD9g//yD1ejoBoFpRkISsUPsMzPwkOIcARmJlvKMGIJq9jt+Uem51Wscfe1hkq
8VAdWKBfMCRjQcZZAAAAAElFTkSuQmCC
"
}

#------------------------------------------------------------------------------
# tablelist::photo9x5Arrows
#------------------------------------------------------------------------------
proc tablelist::photo9x5Arrows w {
    foreach dir {Up Dn} {
	image create photo triangle$dir$w
    }

    triangleUp$w put "
R0lGODlhCQAFAIQTAAAAADxeckBidGaJmlabwG6mw4exxZy9z4bI647M7JvS76HV8KjX8a3a8rPc
8rLe87jf9Lzh9MPk9f///////////////////////////////////////////////////yH5BAEK
AB8ALAAAAAAJAAUAAAUZ4Cd+wWgGhGCSBKIMY1AkSwMdpPEwTiT9IQA7
"
    triangleDn$w put "
R0lGODlhCQAFAIQSAAAAADxeck90imuUrGKauW2jwWes036xzXOy2IO83YO83o++2JrH4JrK5rPZ
7rPZ77TZ7sTj9P///////////////////////////////////////////////////////yH5BAEK
AB8ALAAAAAAJAAUAAAUaYECMxbEwzCcgSNJA0ScPSuPEsmw8eC43vhAAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::photo11x6Arrows
#------------------------------------------------------------------------------
proc tablelist::photo11x6Arrows w {
    foreach dir {Up Dn} {
	image create photo triangle$dir$w
    }

    triangleUp$w put "
R0lGODlhCwAGAKUjAAAAADJdfDJefDFefjRffDhhfC9njDNrjThtjj5xkUJykWuXs2Ogw2ukxHKp
yHusyZrD2o7M7JfQ7qDE2qfH2arJ2aPQ6aLU76Td+6/h/bDi/rrj+bjm/rrn/8Pm+sLr/8Ps/8ro
+szu////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAALAAYAAAYqwJ9Q
WBgahQTF4ohMPCyQYwDhuHA2k6Hg0JBkOh8P5TcwMCIYTQckClWCADs=
"
    triangleDn$w put "
R0lGODlhCwAGAKUkAAAAADl1ml+DnlaRtWGZu2ievXaet2+gvXekvmKfw32owXu314Kqwoiswoey
yo21zIa+3JC2zZ26y5DB3ZjG34fE5ZHJ55/J4ZrN6KTC1KjN4qLb+azf+rrV5rDi/rrn/7/m+8Ps
/8vu/9Pw////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAALAAYAAAYqQEFg
QCgcEApGQ/IzJBaQCeWi6fyujsrG8wmNruCHhfMRgc8RDOjMzrCDADs=
"
}

#------------------------------------------------------------------------------
# tablelist::photo15x8Arrows
#------------------------------------------------------------------------------
proc tablelist::photo15x8Arrows w {
    foreach dir {Up Dn} {
	image create photo triangle$dir$w
    }

    triangleUp$w put "
R0lGODlhDwAIAKU/AAAAAB1YfjJefy1pjjVmhjJrjzppiD1qiTVtkTpwkTxwkT18oUFsikRuilKP
s16Rr1aStFyUtWeHnGKKo2CWtXGhvV6dwnOy1Ha02Hu01YKovommuI2xxIC314S31JGyx5W1x5S3
zJi2yJG915nE2p/F24fD44/I5o7K65bF4JbN7ZjM6J/P6Z3Q7Z7X9abJ3anN4KfS6q/U6azV66zX
76fa9qzb9and+bLb8Lne8rHg+rLi+7fi+bnk+73l+v///yH5BAEKAD8ALAAAAAAPAAgAAAZJwJ9w
+JMQj8QGYYI8NhSPiqYpZCQontSI0zwgIp2WjUb6HA8FSEZV0/FwJdDQMHBcUK7brufLvUQ/AgEL
FhgmJyssMTMyMCEbQQA7
"
    triangleDn$w put "
R0lGODlhDwAIAKU/AAAAACdjiUBtjkKBpkaGqlWFpVaUuFyav2SVtGGdv2Cew2ehwm2jw26tz3Ok
wXOmw3amwnuow3ioxH6pw3Gv0nSz13iz03611ICsxYOux4mtwomxyI2yyIK00oa41Yy815KvwZm5
zJO+2JjC2Z/D2J7E2obC4o/I5o3J6pTM65jM6J/P6ZzP657X9avH2anP5afS6q7U6azV66fa9qnZ
9Knd+bjV5rrc8bHg+rLi+7fi+b/g8rnk+7zl+sXh8v///yH5BAEKAD8ALAAAAAAPAAgAAAZIQEFg
YEgsGA8JJrPhaEC/AkHRsFw8H9GoRHL9vohDxXRSrWCymO3LdlBQrVqO1/Ox7xBLaobT7e6AERcs
NDeAhxMdL4eMIYxBADs=
"
}

#------------------------------------------------------------------------------
# tablelist::sunken8x7Arrows
#------------------------------------------------------------------------------
proc tablelist::sunken8x7Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp8x7_width 8
#define triangleUp8x7_height 7
static unsigned char triangleUp8x7_bits[] = {
   0x18, 0x3c, 0x3c, 0x7e, 0x7e, 0xff, 0xff};
"
    image create bitmap darkLineUp$w -data "
#define darkLineUp8x7_width 8
#define darkLineUp8x7_height 7
static unsigned char darkLineUp8x7_bits[] = {
   0x08, 0x0c, 0x04, 0x06, 0x02, 0x03, 0x00};
"
    image create bitmap lightLineUp$w -data "
#define lightLineUp8x7_width 8
#define lightLineUp8x7_height 7
static unsigned char lightLineUp8x7_bits[] = {
   0x10, 0x30, 0x20, 0x60, 0x40, 0xc0, 0xff};
"
    image create bitmap triangleDn$w -data "
#define triangleDn8x7_width 8
#define triangleDn8x7_height 7
static unsigned char triangleDn8x7_bits[] = {
   0xff, 0xff, 0x7e, 0x7e, 0x3c, 0x3c, 0x18};
"
    image create bitmap darkLineDn$w -data "
#define darkLineDn8x7_width 8
#define darkLineDn8x7_height 7
static unsigned char darkLineDn8x7_bits[] = {
   0xff, 0x03, 0x02, 0x06, 0x04, 0x0c, 0x08};
"
    image create bitmap lightLineDn$w -data "
#define lightLineDn8x7_width 8
#define lightLineDn8x7_height 7
static unsigned char lightLineDn8x7_bits[] = {
   0x00, 0xc0, 0x40, 0x60, 0x20, 0x30, 0x10};
"
}

#------------------------------------------------------------------------------
# tablelist::sunken10x9Arrows
#------------------------------------------------------------------------------
proc tablelist::sunken10x9Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp10x9_width 10
#define triangleUp10x9_height 9
static unsigned char triangleUp10x9_bits[] = {
   0x30, 0x00, 0x78, 0x00, 0x78, 0x00, 0xfc, 0x00, 0xfc, 0x00, 0xfe, 0x01,
   0xfe, 0x01, 0xff, 0x03, 0xff, 0x03};
"
    image create bitmap darkLineUp$w -data "
#define darkLineUp10x9_width 10
#define darkLineUp10x9_height 9
static unsigned char darkLineUp10x9_bits[] = {
   0x10, 0x00, 0x18, 0x00, 0x08, 0x00, 0x0c, 0x00, 0x04, 0x00, 0x06, 0x00,
   0x02, 0x00, 0x03, 0x00, 0x00, 0x00};
"
    image create bitmap lightLineUp$w -data "
#define lightLineUp10x9_width 10
#define lightLineUp10x9_height 9
static unsigned char lightLineUp10x9_bits[] = {
   0x20, 0x00, 0x60, 0x00, 0x40, 0x00, 0xc0, 0x00, 0x80, 0x00, 0x80, 0x01,
   0x00, 0x01, 0x00, 0x03, 0xff, 0x03};
"
    image create bitmap triangleDn$w -data "
#define triangleDn10x9_width 10
#define triangleDn10x9_height 9
static unsigned char triangleDn10x9_bits[] = {
   0xff, 0x03, 0xff, 0x03, 0xfe, 0x01, 0xfe, 0x01, 0xfc, 0x00, 0xfc, 0x00,
   0x78, 0x00, 0x78, 0x00, 0x30, 0x00};
"
    image create bitmap darkLineDn$w -data "
#define darkLineDn10x9_width 10
#define darkLineDn10x9_height 9
static unsigned char darkLineDn10x9_bits[] = {
   0xff, 0x03, 0x03, 0x00, 0x02, 0x00, 0x06, 0x00, 0x04, 0x00, 0x0c, 0x00,
   0x08, 0x00, 0x18, 0x00, 0x10, 0x00};
"
    image create bitmap lightLineDn$w -data "
#define lightLineDn10x9_width 10
#define lightLineDn10x9_height 9
static unsigned char lightLineDn10x9_bits[] = {
   0x00, 0x00, 0x00, 0x03, 0x00, 0x01, 0x80, 0x01, 0x80, 0x00, 0xc0, 0x00,
   0x40, 0x00, 0x60, 0x00, 0x20, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::sunken12x11Arrows
#------------------------------------------------------------------------------
proc tablelist::sunken12x11Arrows w {
    image create bitmap triangleUp$w -data "
#define triangleUp12x11_width 12
#define triangleUp12x11_height 11
static unsigned char triangleUp12x11_bits[] = {
   0x60, 0x00, 0xf0, 0x00, 0xf0, 0x00, 0xf8, 0x01, 0xf8, 0x01, 0xfc, 0x03,
   0xfc, 0x03, 0xfe, 0x07, 0xfe, 0x07, 0xff, 0x0f, 0xff, 0x0f};
"
    image create bitmap darkLineUp$w -data "
#define darkLineUp12x11_width 12
#define darkLineUp12x11_height 11
static unsigned char darkLineUp12x11_bits[] = {
   0x20, 0x00, 0x30, 0x00, 0x10, 0x00, 0x18, 0x00, 0x08, 0x00, 0x0c, 0x00,
   0x04, 0x00, 0x06, 0x00, 0x02, 0x00, 0x03, 0x00, 0x00, 0x00};
"
    image create bitmap lightLineUp$w -data "
#define lightLineUp12x11_width 12
#define lightLineUp12x11_height 11
static unsigned char lightLineUp12x11_bits[] = {
   0x40, 0x00, 0xc0, 0x00, 0x80, 0x00, 0x80, 0x01, 0x00, 0x01, 0x00, 0x03,
   0x00, 0x02, 0x00, 0x06, 0x00, 0x04, 0x00, 0x0c, 0xff, 0x0f};
"
    image create bitmap triangleDn$w -data "
#define triangleDn12x11_width 12
#define triangleDn12x11_height 11
static unsigned char triangleDn12x11_bits[] = {
   0xff, 0x0f, 0xff, 0x0f, 0xfe, 0x07, 0xfe, 0x07, 0xfc, 0x03, 0xfc, 0x03,
   0xf8, 0x01, 0xf8, 0x01, 0xf0, 0x00, 0xf0, 0x00, 0x60, 0x00};
"
    image create bitmap darkLineDn$w -data "
#define darkLineDn12x11_width 12
#define darkLineDn12x11_height 11
static unsigned char darkLineDn12x11_bits[] = {
   0xff, 0x0f, 0x03, 0x00, 0x02, 0x00, 0x06, 0x00, 0x04, 0x00, 0x0c, 0x00,
   0x08, 0x00, 0x18, 0x00, 0x10, 0x00, 0x30, 0x00, 0x20, 0x00};
"
    image create bitmap lightLineDn$w -data "
#define lightLineDn12x11_width 12
#define lightLineDn12x11_height 11
static unsigned char lightLineDn12x11_bits[] = {
   0x00, 0x00, 0x00, 0x0c, 0x00, 0x04, 0x00, 0x06, 0x00, 0x02, 0x00, 0x03,
   0x00, 0x01, 0x80, 0x01, 0x80, 0x00, 0xc0, 0x00, 0x40, 0x00};
"
}

#------------------------------------------------------------------------------
# tablelist::createSortRankImgs
#------------------------------------------------------------------------------
proc tablelist::createSortRankImgs win {
    image create bitmap sortRank1$win -data "
#define sortRank1_width 4
#define sortRank1_height 6
static unsigned char sortRank1_bits[] = {
   0x04, 0x06, 0x04, 0x04, 0x04, 0x04};
"
    image create bitmap sortRank2$win -data "
#define sortRank2_width 4
#define sortRank2_height 6
static unsigned char sortRank2_bits[] = {
   0x06, 0x09, 0x08, 0x04, 0x02, 0x0f};
"
    image create bitmap sortRank3$win -data "
#define sortRank3_width 4
#define sortRank3_height 6
static unsigned char sortRank3_bits[] = {
   0x0f, 0x08, 0x06, 0x08, 0x09, 0x06};
"
    image create bitmap sortRank4$win -data "
#define sortRank4_width 4
#define sortRank4_height 6
static unsigned char sortRank4_bits[] = {
   0x04, 0x06, 0x05, 0x0f, 0x04, 0x04};
"
    image create bitmap sortRank5$win -data "
#define sortRank5_width 4
#define sortRank5_height 6
static unsigned char sortRank5_bits[] = {
   0x0f, 0x01, 0x07, 0x08, 0x09, 0x06};
"
    image create bitmap sortRank6$win -data "
#define sortRank6_width 4
#define sortRank6_height 6
static unsigned char sortRank6_bits[] = {
   0x06, 0x01, 0x07, 0x09, 0x09, 0x06};
"
    image create bitmap sortRank7$win -data "
#define sortRank7_width 4
#define sortRank7_height 6
static unsigned char sortRank7_bits[] = {
   0x0f, 0x08, 0x04, 0x04, 0x02, 0x02};
"
    image create bitmap sortRank8$win -data "
#define sortRank8_width 4
#define sortRank8_height 6
static unsigned char sortRank8_bits[] = {
   0x06, 0x09, 0x06, 0x09, 0x09, 0x06};
"
    image create bitmap sortRank9$win -data "
#define sortRank9_width 4
#define sortRank9_height 6
static unsigned char sortRank9_bits[] = {
   0x06, 0x09, 0x09, 0x0e, 0x08, 0x06};
"
}

#------------------------------------------------------------------------------
# tablelist::createCheckbuttonImgs
#------------------------------------------------------------------------------
proc tablelist::createCheckbuttonImgs {} {
    variable checkedImg [image create bitmap tablelist_checkedImg -data "
#define checked_width 9
#define checked_height 9
static unsigned char checked_bits[] = {
   0x00, 0x00, 0x80, 0x00, 0xc0, 0x00, 0xe2, 0x00, 0x76, 0x00, 0x3e, 0x00,
   0x1c, 0x00, 0x08, 0x00, 0x00, 0x00};
"]

    variable uncheckedImg [image create bitmap tablelist_uncheckedImg -data "
#define unchecked_width 9
#define unchecked_height 9
static unsigned char unchecked_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
"]
}

#------------------------------------------------------------------------------
# tablelist::adwaitaTreeImgs
#------------------------------------------------------------------------------
proc tablelist::adwaitaTreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel
		  collapsedAct expandedAct collapsedSelAct expandedSelAct} {
	variable adwaita_${mode}Img \
		 [image create photo tablelist_adwaita_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_adwaita_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA7CAAAOwgEVKEqAAAAAB3RJTUUH4AoJDhEt8bC0ZgAAAFtJREFUKM+d0rENwCAMRNFzBkoH
u2RCdiFD/fQo2MYnuXwCWycVAuhSMSu8Aa2Tgc3MnsqLktQzeLdjiL3juDi6ajezVoETeE/hBMbp
V120gyH6S6o5uzalSv4B4OI73QHvdNAAAAAASUVORK5CYII=
"
	tablelist_adwaita_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA7CAAAOwgEVKEqAAAAAB3RJTUUH4AoJDhYozpvWLgAAAGNJREFUKM/V0jEKgDAMheE/4mXE
VScv7OA1HATXnue5SMBqinRrIEvIB0kIVIQkOiqjIdgDIzD96D2B5FBSMrMBWArouPueo0ragL2A
1nDHAH+i13EyHCL/gjyBOai7oZ2XuwBMS0yU1CG3NAAAAABJRU5ErkJggg==
"
	tablelist_adwaita_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA7CAAAOwgEVKEqAAAAAB3RJTUUH4AoJDhQOLqAxUQAAAF9JREFUKM+d0rERACEIRNEPVV1u
PVfN1WNte4mRowIyY/hAmIWLkoRzWT51eiQxvxACDXjLE8fUFPbN8iH2w+WO2IOzt7F3DZpZB3oJ
DvSVvhqhJcyg1TFSydmlKRXyH4WQQgoBtm/BAAAAAElFTkSuQmCC
"
	tablelist_adwaita_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA7CAAAOwgEVKEqAAAAAB3RJTUUH4AoJDhkKnGOLBQAAAG9JREFUKM/V0jsKgDAQBNAZ8UIW
1mLrQSw9jKWnsLIUrHOnjI0EzQ9Jl4U02XmQJQsUlCQ0KKyKYCupBzD8yF4kjYMADIBO0pQSJM8n
Fzx1I3lk0JqbMcAp5D7TO7O1dpe0+L23iUFIGmP3H1jPyt3BlV+oCWAAJQAAAABJRU5ErkJggg==
"
	tablelist_adwaita_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA7CAAAOwgEVKEqAAAAAB3RJTUUH4AoJDhI7LklS9AAAAFtJREFUKM+d0kEKwDAIRNGxR+u2
JVcKvVLo/X73oVHjgMtHooxUCKBDxczwBDRPBl5m1isvSlLL4NWOIfaO4+Loqs3M7gocwLsLB/Ds
ftVFKxiiv6Sas2pTquQfhP08Qc94AdgAAAAASUVORK5CYII=
"
	tablelist_adwaita_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA7CAAAOwgEVKEqAAAAAB3RJTUUH4AoJDhctp+oT4AAAAG1JREFUKM/V0rENgCAQheEf41QW
DqCtw1hZWDmMlQUDULvTsyGoEYih45Jr4H0JlwMKShINhVURbIEeGH5kLeAClOSMMR0wZdDhc++n
StqAPYPW5IwJHEVhmc8GZuAElshdMB/oA2Pi/Ib1fLkL9HJfbH+7HUcAAAAASUVORK5CYII=
"
	tablelist_adwaita_collapsedSelActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA7CAAAOwgEVKEqAAAAAB3RJTUUH4AoJDhUZtGiF1wAAAFxJREFUKM+d0ssNgCAQhOE/dGgB
xmBhcLDQ8eKJuC8m4fgtsBnYiCQam2nLpEMS6wkhcAGjfOOXnsHWH0PsLcfF0VY7cO7ACTxVOIG7
+lQXWTBEfx1MNcdqU6rkLw9FNonuw3sOAAAAAElFTkSuQmCC
"
	tablelist_adwaita_expandedSelActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA7CAAAOwgEVKEqAAAAAB3RJTUUH4AoJDhoT0yVwBgAAAFZJREFUKM/V0jEKwCAQRNFvyPVy
g+RWdmlzgxzwpwkioiJ2DmwxMK/boDKTjcksBHfgAM6B7QO8qamo0X7uf5cuL3EUlbCGq6gGc9xE
LYh69ZBKWOflPkhQ7kQX/0qBAAAAAElFTkSuQmCC
"
    } else {
	tablelist_adwaita_collapsedImg put "
R0lGODlhDgAOAMIGAAAAAHBwcJycnKampsrKytHR0f///////yH5BAEKAAcALAAAAAAOAA4AAAMf
eLrc/qvAJsZcItibNQ/g9nQgAZGi06Wqx7GPdM1KAgA7
"
	tablelist_adwaita_expandedImg put "
R0lGODlhDgAOAMIHAAAAAHBwcKCgoKenp6urq8rKytTU1P///yH5BAEKAAcALAAAAAAOAA4AAAMd
eLrc/jDKyYy4GBtGgv/B4HSg+JCh1JlSQb3wlAAAOw==
"
	tablelist_adwaita_collapsedSelImg put "
R0lGODlhDgAOAKECAAAAAP7+/v///////yH5BAEKAAMALAAAAAAOAA4AAAIcnI+pe8Ip3DMiyFft
zJrxrnBXGIBLNZ7pObVHAQA7
"
	tablelist_adwaita_expandedSelImg put "
R0lGODlhDgAOAKECAAAAAP7+/v///////yH5BAEKAAMALAAAAAAOAA4AAAIanI+py+2PhJxUxIBz
sEnozXgYF4IPCaUqUwAAOw==
"
	tablelist_adwaita_collapsedActImg put "
R0lGODlhDgAOAMIGAAAAADIyMnJycoCAgLOzs729vf///////yH5BAEKAAcALAAAAAAOAA4AAAMf
eLrc/qvAJsZcItibNQ/g9nQgAZGi06Wqx7GPdM1KAgA7
"
	tablelist_adwaita_expandedActImg put "
R0lGODlhDgAOAMIHAAAAADMzM3d3d4GBgYeHh7S0tMHBwf///yH5BAEKAAcALAAAAAAOAA4AAAMd
eLrc/jDKyYy4GBtGgv/B4HSg+JCh1JlSQb3wlAAAOw==
"
	tablelist_adwaita_collapsedSelActImg put "
R0lGODlhDgAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAOAA4AAAIYhI+pe8EZ3DNRvmoX
znAz/1WTOHLahB4FADs=
"
	tablelist_adwaita_expandedSelActImg put "
R0lGODlhDgAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAOAA4AAAIVhI+py+2Pgpw0xDoV
tqu6/HDQSDYFADs=
"
    }
}

#------------------------------------------------------------------------------
# tablelist::ambianceTreeImgs
#------------------------------------------------------------------------------
proc tablelist::ambianceTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable ambiance_${mode}Img \
		 [image create photo tablelist_ambiance_${mode}Img]
    }

    tablelist_ambiance_collapsedImg put "
R0lGODlhEgAQAKUxAAAAADw7N9/Wxd/Wxt/WyODYyeLZyuHazeTdz+Pd0eTd0uXf0+Xf1efg1OXg
1ujh0+jg1Onj1+nj2Ork2O3m3Ozm3e7p4e/q4e7s5u/s6PHs5PHs5fHs5vHu6fPw6vTw6vTw6/bz
7vbz7/b07vb07/b08Pb08fj28/n49Pr59fr59vv5+Pv6+Pr6+vz6+fz7+v39/f//////////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAahwJ9w
SCwWD4KkUnkwFjotmHQKa2UKxENmxXK5XmAva4VpCgWmEwqVSqna61NJMBSERKSSyRTYl0gjJHRn
Hx4dHiAgAYkeHh8fgz8CHJQcGhsBGxuVHJECFxcWAaOkAaAXnhUVFKoVAa2tnhMRErUSAbYRExOe
DxC/vwHAEA0PngoIycrLCAuRBwwG0tPUBg5mQgUJBAPd3gMECVhHS+XYQkEAOw==
"
    tablelist_ambiance_expandedImg put "
R0lGODlhEgAQAKUyAAAAADw7N9/Wxd/Wxt/WyODYyeLZyuHazeTdz+Pd0eTd0uXf0+Xf1efg1OXg
1ujh0+jg1Onj1+nj2Ork2O3m3Ozm3e7p4e/q4e7s5u/s6PHs5PHs5fHs5vHu6fPw6vTw6vTw6/bz
7vbz7/b07vb07/b08Pb08fj18fj28/n49Pr59fr59vv5+Pv6+Pr6+vz6+fz7+v39/f//////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAabwJ9w
SCwWD4KkUnkwFjqumHQac2UKxEOG1Xq9YGBvi4VpCgUmVCqlUq3aa1RJMBSERKSSyXTal0gjJHRn
Hx4dHiCJiR4eHx+DPwIckxwaGxwbl5SQAhcXFgGhogGeF5wVFRSoq6wVnBMRErKzshETE5wPELu8
vQ0PnAoIw8TFCAuQBwwGzM3OBg5mQgUJBAPX2AMECVhHS9/SQkEAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::aquaTreeImgs
#------------------------------------------------------------------------------
proc tablelist::aquaTreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable aqua_${mode}Img \
		 [image create photo tablelist_aqua_${mode}Img]
    }

    variable pngSupported
    variable winSys
    scan $::tcl_platform(osVersion) "%d" majorOSVersion
    if {[string compare $winSys "aqua"] == 0 && $majorOSVersion > 10} {
	set osVerPost10 1
    } else {
	set osVerPost10 0
    }

    if {$pngSupported} {
	if {$osVerPost10} {
	    tablelist_aqua_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAAhUlEQVQoz2NgGFaAmYGBgaG4uPih
lZXVvePHj98kxxBGqCH/ofxtDAwMub29vfdIMYQJje/FwMBwvbi4uIoSlyCDawwMDFm9vb0HSXUJ
MtBiYGA4UFxcHECJIdcYGBgcent7NxAyhAWL2C8GBobG3t7eNmLDBN0QsmIHZsgjqOZNQzvZAwA+
LCb4qKbYgQAAAABJRU5ErkJggg==
"
	    tablelist_aqua_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAAiUlEQVQoz+2SsQkCQRREn3t9aO51
sKmZJtYhXDS5HUwzwtnCVqC5NmB+gZgui9wulwlO8vnMZ2b4/8MfJVaSHsB6ZuZpezMnEoChYjRU
kwBIGoH9F/5q+1ATCZnbVHBTSwqADiCl9IoxvoFdxp1tX5oWmzeSbsAWuNvuW68Tiv5U1GWQdPzd
j/0AfOEdPAaC2LoAAAAASUVORK5CYII=
"
	} else {
	    tablelist_aqua_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAAe0lEQVQoz2NgGH6gra3tYVtbmx+5
+hmhhvyH8rcxMDDkVlVV3SPFECY0vhcDA8P1tra2KkpcggyuMTAwZFVVVR0k1SXIQIuBgeFAW1tb
ACWGXGNgYHCoqqraQMgQFixivxgYGBqrqqraiA0TdEPIih2YIY+gmjcN7RQPAIgqI+JZClM5AAAA
AElFTkSuQmCC
"
	    tablelist_aqua_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAAfklEQVQoz+2SsQ2DUAxEX/4gpCeb
hCZzRGKB62huI7IJlJGSMajSJAhZiP9Fh5RrLPusO1s2/BFxsv0Cqo2et6TzlkgC2oxRm50EwHYP
XFf4h6QmJ5IWblPgppIpZhFJT6ALXPetU7TOD7YHoAZGSZfS66SQ30PcB9u3437sB9yMGwQuEm+e
AAAAAElFTkSuQmCC
"
	}

	tablelist_aqua_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAAR0lEQVQoz2NgGH7g////N////+9I
qSEwsOT///8SlBry/////5/+//+fRakhMHD6////ppQaAgPOA+YSisOEotihPJ0MCgAABqWnCWRA
sV8AAAAASUVORK5CYII=
"
	tablelist_aqua_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAAT0lEQVQoz2NgGAUY4P///zf/4wc3
iTHEkYAhjsS6ZgkOA5aQ4iWJ////f0Iz4NP///8lSA2bLDRDssgN5NNQA05TElOmUENMKY1y56Gb
YAGl/KcJzjuWxQAAAABJRU5ErkJggg==
"
    } else {
	if {$osVerPost10} {
	    tablelist_aqua_collapsedImg put "
R0lGODlhEQAOAMIGAAAAAHNzc3Z2doODg4qKipubm////////yH5BAEKAAcALAAAAAARAA4AAAMf
eLrc/jC+IV0Ipa4bhD7cRVQhJ5XjeXnalX3UJ89OAgA7
"
	    tablelist_aqua_expandedImg put "
R0lGODlhEQAOAMIGAAAAAHNzc3Z2doODg4qKipubm////////yH5BAEKAAcALAAAAAARAA4AAAMf
eLrc/jDKqUa4OIyYsSxdMQmYQB3eSQTEqQRuLM9HAgA7
"
	} else {
	    tablelist_aqua_collapsedImg put "
R0lGODlhEQAOAMIGAAAAAIaGhoiIiJSUlJmZmampqf///////yH5BAEKAAcALAAAAAARAA4AAAMf
eLrc/jC+IV0Ipa4bhD7cRVQhJ5XjeXnalX3UJ89OAgA7
"
	    tablelist_aqua_expandedImg put "
R0lGODlhEQAOAMIGAAAAAIaGhoiIiJSUlJmZmampqf///////yH5BAEKAAcALAAAAAARAA4AAAMf
eLrc/jDKqUa4OIyYsSxdMQmYQB3eSQTEqQRuLM9HAgA7
"
	}

	tablelist_aqua_collapsedSelImg put "
R0lGODlhEQAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAARAA4AAAIZhI+py73hVJjxTFrv
jXq3DjlaBXgZiaZLAQA7
"
	tablelist_aqua_expandedSelImg put "
R0lGODlhEQAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAARAA4AAAIXhI+py+1vgpyz0Wpv
eBcCDIGhR5ZmUgAAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::arcTreeImgs
#------------------------------------------------------------------------------
proc tablelist::arcTreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel
		  collapsedAct expandedAct collapsedSelAct expandedSelAct} {
	variable arc_${mode}Img \
		 [image create photo tablelist_arc_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_arc_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAKCAYAAACE2W/HAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAGxJREFUKFONj0EKgDAMBPcVIl69iV7FF3hR/P9v4kYqSWlKGxhINh1IISIfrIms
/9zCGmAmD9n9gxr5AGxJPnweUQadchyaXD07DBXWRW4yhPswBM4kjdFeKYMOSckHk8LzPNYAC9F/
NSURwQtLqlH7qKJBUAAAAABJRU5ErkJggg==
"
	tablelist_arc_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAKCAYAAACE2W/HAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAHRJREFUKFOdjUsKgDAMBbNwqzs/ZxHXFVG8/21i0iaaaECxMLSZl/IAEX8Ryi/w
aYkpChU6I+/dHDTESiQbmIUkee28hNzK4ezC8mkjButzdj4AOlnKzXzL3OuOxQ9X806ETcpTlOaF
CJuUWAJUkbeE8h2EA9B0S9ShJNYAAAAAAElFTkSuQmCC
"
	tablelist_arc_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAKCAYAAACE2W/HAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAGdJREFUKFON0cEJgDAQRNH0YgfixSIsQgTLsBQbEC82OJmFRMa4xhzeYT/MaQOA
bKRZ7io9Jrpok/apDAs1jb3YNHYjrVQduzE56KRO2u0Vkp1sNEh78OLvyJQhj3ppLj3s+U0jACEC
E06wdZnzTFcAAAAASUVORK5CYII=
"
	tablelist_arc_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAKCAYAAACE2W/HAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAHBJREFUKFOdzsEJgDAQRNHc7ELsQAQ7FCxD8OJFvNjgOiNu2IQBxcML5Ou6JjP7
RcYvePQwxyhMwPdy49HBAavHygJ83oaWf5Vf26Ee9qExtFu8cDhu9qHhuRfq4JtPkJucihzeQG5y
MkIjWkHGd5YueOiwF1W1TAUAAAAASUVORK5CYII=
"
	tablelist_arc_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAKCAYAAACE2W/HAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAHNJREFUKFONz10KgCAQBOA5SheInnvvCkEdIuggPRdBd91m+2EVV1T4wB0dUIjI
g6un6Z9LbAMMdNESXsiJB2D+ymuYe9KgsuyHVs4+2w0V104HNe65GwIbndR55yoNKkoqHt6SPq8N
c49tgJH0X8WSiOAGGZpYKjZmcSEAAAAASUVORK5CYII=
"
	tablelist_arc_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAKCAYAAACE2W/HAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAHRJREFUKFOdjUsKgDAMRLP0DHoDRTycCy+hLtxIwbvG6Sc21YBi4EH7JkOImX9h
yi/4acFkhQJm9Hs3Rw3YwaIDtTCnvC58CrsUrkUYSw4M2ofseuRyuIyRS73saMpPLh/AvCQ8RSxv
wLwk2JKosrzGlO8wnchaUd6BhPzVAAAAAElFTkSuQmCC
"
	tablelist_arc_collapsedSelActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAKCAYAAACE2W/HAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAG5JREFUKFONz8EJgDAQRNF0ZQtevNiIhYggVuLFjmxB8LbOQiKTOBoX3mG/LJhg
ZkkPE+2feBnAZwXuUhlm8Nmg/JZR8dexjLCAz+tvyxgdcEJD7fYI0Q5+1FHLqFg9cmVIRy01iZcR
/F3VIzMLF8edtpTOwib0AAAAAElFTkSuQmCC
"
	tablelist_arc_expandedSelActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAKCAYAAACE2W/HAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAHJJREFUKFOdzsEJgDAQRNEUYCWCVYjgxY692It49CYIHtYZcWUTBhSFF8iXZZPM
7BcZv+DRwRSjMEIbG48Gdlg8Fmbg/zq056ncukE5zKEDhtAu8cLhuNk39fc9UwbfzE9ucipyeAW5
yckIlWgZGd9ZOgFo1rYdzDp3awAAAABJRU5ErkJggg==
"
    } else {
	tablelist_arc_collapsedImg put "
R0lGODlhDgAKAOMKAAAAALGxsbOzs7S0tLm5ucfHx8nJydPT09XV1eXl5f//////////////////
/////yH5BAEKAA8ALAAAAAAOAAoAAAQc8L10pL03GMxlKB33hZhGWoNwPoR6tit8IsMZAQA7
"
	tablelist_arc_expandedImg put "
R0lGODlhDgAKAOMJAAAAALGxsbOzs7S0tLa2tri4uLm5ucPDw8XFxf//////////////////////
/////yH5BAEKAA8ALAAAAAAOAAoAAAQd8MlJq73vXFSHqcZgDcVkCJjwnZg0BGgrEXJtTxEAOw==
"
	tablelist_arc_collapsedSelImg put "
R0lGODlhDgAKAKECAAAAAMzMzP///////yH5BAEKAAAALAAAAAAOAAoAAAIUBBKmu8hvHGRyqmox
1I/TZB3gVAAAOw==
"
	tablelist_arc_expandedSelImg put "
R0lGODlhDgAKAKECAAAAAMzMzP///////yH5BAEKAAAALAAAAAAOAAoAAAIUhI+pC7GOAjxSVXOt
y4+zyYSiUgAAOw==
"
	tablelist_arc_collapsedActImg put "
R0lGODlhDgAKAOMLAAAAAGNjY2ZmZmhoaGlpaXNzc4+Pj5KSkqenp6qqqsbGxv//////////////
/////yH5BAEKAA8ALAAAAAAOAAoAAAQc8D2FpL03HMxlMB33hZhGWsRwPoWwtq96JsQZAQA7
"
	tablelist_arc_expandedActImg put "
R0lGODlhDgAKAOMKAAAAAGNjY2ZmZmhoaG1tbXFxcXJycnNzc4iIiIyMjP//////////////////
/////yH5BAEKAA8ALAAAAAAOAAoAAAQd8MlJq70P3VSHqcdgDcV0CJj3hJg0BGgrEXJtTxEAOw==
"
	tablelist_arc_collapsedSelActImg put "
R0lGODlhDgAKAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAOAAoAAAIUBBKmu8hvHGRyqmox
1I/TZB3gVAAAOw==
"
	tablelist_arc_expandedSelActImg put "
R0lGODlhDgAKAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAOAAoAAAIUhI+pC7GOAjxSVXOt
y4+zyYSiUgAAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::baghiraTreeImgs
#------------------------------------------------------------------------------
proc tablelist::baghiraTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable baghira_${mode}Img \
		 [image create photo tablelist_baghira_${mode}Img]
    }

    tablelist_baghira_collapsedImg put "
R0lGODlhDQAIAIABAAAAAP///yH5BAEKAAEALAAAAAANAAgAAAIQjI8JyQHbzoNxUjajeXr3AgA7
"
    tablelist_baghira_expandedImg put "
R0lGODlhDQAIAIABAAAAAP///yH5BAEKAAEALAAAAAANAAgAAAIOjI+pywcPwYqSwWYqxgUAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::bicolor1TreeImgs
#------------------------------------------------------------------------------
proc tablelist::bicolor1TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable bicolor1_${mode}Img \
		 [image create photo tablelist_bicolor1_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_bicolor1_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAKCAYAAACALL/6AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEwYtcCg47AAAACpJREFUGNNjYKAA1BOjiIlUTUyk
2sREqvOYSPUTPg2NpGhoJMVJjVSNBwD8+gSMwdvvHwAAAABJRU5ErkJggg==
"
	tablelist_bicolor1_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAKCAYAAACALL/6AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEwkTNtE5iAAAAC9JREFUGNNjYBh0gJGBgaGeCHWN
yBoYCGhqRLeBAY+mRmxOYsChqZFYf9UPbLACACL9BIS+a6kZAAAAAElFTkSuQmCC
"
    } else {
	tablelist_bicolor1_collapsedImg put "
R0lGODlhDAAKAIABAH9/f////yH5BAEKAAEALAAAAAAMAAoAAAIUjI8IybB83INypmqjhGFzxxkZ
UgAAOw==
"
	tablelist_bicolor1_expandedImg put "
R0lGODlhDAAKAIABAH9/f////yH5BAEKAAEALAAAAAAMAAoAAAIQjI+py+D/EIxpNscMyLyHAgA7
"
    }

    tablelist_bicolor1_collapsedSelImg put "
R0lGODlhDAAKAIAAAP///////yH5BAEKAAEALAAAAAAMAAoAAAIUjI8IybB83INypmqjhGFzxxkZ
UgAAOw==
"
    tablelist_bicolor1_expandedSelImg put "
R0lGODlhDAAKAIAAAP///////yH5BAEKAAEALAAAAAAMAAoAAAIQjI+py+D/EIxpNscMyLyHAgA7
"
}

#------------------------------------------------------------------------------
# tablelist::bicolor2TreeImgs
#------------------------------------------------------------------------------
proc tablelist::bicolor2TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable bicolor2_${mode}Img \
		 [image create photo tablelist_bicolor2_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_bicolor2_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAMCAYAAABSgIzaAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI    
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEwwFv3J4nAAAADJJREFUKM9jYKASaCJWIRO5mpnI    
tZmJXGczketnJnIDjBiNdeRorCPHqXXkBE4dzVIOAPKWBZkKDbb3AAAAAElFTkSuQmCC
"
	tablelist_bicolor2_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAMCAYAAABSgIzaAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEw4I8/VmowAAADZJREFUKM9jYBgygJGBgaGeBPWN
yBoZiNTciG4jAxGaG7E5lYGA5kZcfmTAo7mR1ECrZxg+AAC4iAWFJSdDXQAAAABJRU5ErkJggg==
"
    } else {
	tablelist_bicolor2_collapsedImg put "
R0lGODlhDgAMAIABAH9/f////yH5BAEKAAEALAAAAAAOAAwAAAIXjI9poA3c0IMxTOpuvS/yPVVW
J5KlWAAAOw==
"
	tablelist_bicolor2_expandedImg put "
R0lGODlhDgAMAIABAH9/f////yH5BAEKAAEALAAAAAAOAAwAAAIUjI+pywoPI0AyuspkC3Cb6YWi
WAAAOw==
"
    }

    tablelist_bicolor2_collapsedSelImg put "
R0lGODlhDgAMAIAAAP///////yH5BAEKAAEALAAAAAAOAAwAAAIXjI9poA3c0IMxTOpuvS/yPVVW
J5KlWAAAOw==
"
    tablelist_bicolor2_expandedSelImg put "
R0lGODlhDgAMAIAAAP///////yH5BAEKAAEALAAAAAAOAAwAAAIUjI+pywoPI0AyuspkC3Cb6YWi
WAAAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::bicolor3TreeImgs
#------------------------------------------------------------------------------
proc tablelist::bicolor3TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable bicolor3_${mode}Img \
		 [image create photo tablelist_bicolor3_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_bicolor3_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExAQNNjBKgAAADtJREFUKM9jYKABqCdHExM1DGKi
houYqOE1JmqEERM1ApuJGrFGrCGNlBrSSKl3GikN2EZKo7iR7nkHAKniBpTspddsAAAAAElFTkSu
QmCC
"
	tablelist_bicolor3_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExIRcemTPgAAAD5JREFUKM/t0jsOACAIRMHnycne
3J6IgJa6PRN+8OMzADuok0doQlp1QgNSNA5FSLudUICULZYE0s3l7NGPnffUBoaD5FpzAAAAAElF
TkSuQmCC
"
    } else {
	tablelist_bicolor3_collapsedImg put "
R0lGODlhEQAOAIABAH9/f////yH5BAEKAAEALAAAAAARAA4AAAIdjI+ZoH3AnIJRPmovznTL7jVg
5YBZ0J0opK4tqhYAOw==
"
	tablelist_bicolor3_expandedImg put "
R0lGODlhEQAOAIABAH9/f////yH5BAEKAAEALAAAAAARAA4AAAIYjI+py+1vgJx0pooXtmy/CgVc
CITmiR4FADs=
"
    }

    tablelist_bicolor3_collapsedSelImg put "
R0lGODlhEQAOAIAAAP///////yH5BAEKAAEALAAAAAARAA4AAAIdjI+ZoH3AnIJRPmovznTL7jVg
5YBZ0J0opK4tqhYAOw==
"
    tablelist_bicolor3_expandedSelImg put "
R0lGODlhEQAOAIAAAP///////yH5BAEKAAEALAAAAAARAA4AAAIYjI+py+1vgJx0pooXtmy/CgVc
CITmiR4FADs=
"
}

#------------------------------------------------------------------------------
# tablelist::bicolor4TreeImgs
#------------------------------------------------------------------------------
proc tablelist::bicolor4TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable bicolor4_${mode}Img \
		 [image create photo tablelist_bicolor4_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_bicolor4_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABcAAAASCAYAAACw50UTAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExUCuhZEJwAAAEdJREFUOMu91IsNACAIQ0HSxU03
dwf1ZIBH6IeZz7NegSIXRF4QKVGkB5EmR6YoMqaRPTiBV8GrZKkytCqKVSWqqv8VmP/zDd6/CJzv
kRcqAAAAAElFTkSuQmCC
"
	tablelist_bicolor4_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABcAAAASCAYAAACw50UTAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExY6uTmvegAAAExJREFUOMvtlNsNACAIA8/JSTd3
ApWHfmjsAD1SCvD1lBpgG3w0MqcI0GxyCgCtYiEJkCdzEgB5F0oQoEhbCAAUrSJOgE7cgv13cI86
Y04IiOwcRtoAAAAASUVORK5CYII=
"
    } else {
	tablelist_bicolor4_collapsedImg put "
R0lGODlhFwASAIABAH9/f////yH5BAEKAAEALAAAAAAXABIAAAIojI+pCusL2pshSgotznoj23kV
GIkjeWFoSK1pi5qxDJpGbZ/5/cp5AQA7
"
	tablelist_bicolor4_expandedImg put "
R0lGODlhFwASAIABAH9/f////yH5BAEKAAEALAAAAAAXABIAAAIijI+py+0Po3Sg2ovrylyzjj2g
J3YTNxlhqpJsALzyTNdKAQA7
"
    }

    tablelist_bicolor4_collapsedSelImg put "
R0lGODlhFwASAIAAAP///////yH5BAEKAAEALAAAAAAXABIAAAIojI+pCusL2pshSgotznoj23kV
GIkjeWFoSK1pi5qxDJpGbZ/5/cp5AQA7
"
    tablelist_bicolor4_expandedSelImg put "
R0lGODlhFwASAIAAAP///////yH5BAEKAAEALAAAAAAXABIAAAIijI+py+0Po3Sg2ovrylyzjj2g
J3YTNxlhqpJsALzyTNdKAQA7
"
}

#------------------------------------------------------------------------------
# tablelist::blueMentaTreeImgs
#------------------------------------------------------------------------------
proc tablelist::blueMentaTreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel
		  collapsedAct expandedAct collapsedSelAct expandedSelAct} {
	variable blueMenta_${mode}Img \
		 [image create photo tablelist_blueMenta_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_blueMenta_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAEJJREFUKFNj+P//P1EYwWBgEEeWQMcIBgNDMhBnIksiYwQDovASLsUIBkIhVsW4
FIKwGTEKiTKRKDcS5Ws84fifAQDpge0RK469/gAAAABJRU5ErkJggg==
"
	tablelist_blueMenta_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAARnQU1BAACx    
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41    
LjEwMPRyoQAAAEtJREFUKFONjNEJACAIBZ3EKRqqvtq1hcwkDPMRBQd5HpKIfAElAkrEeqz0B2zh
rqsyAM0v+ifHHoXQhhOHyHZJEJXbmUcSAWVGaALoU+1uRfEIrwAAAABJRU5ErkJggg==
"
	tablelist_blueMenta_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAENJREFUKFNj+P//P1EYmSODxMbAyJwKIG5A4qNgZA5IIQhgVYzMgSkEAQzFyBxk
hSDgCMQEFRJlIlFuJMrXeMLxPwMAd106nOlvcTEAAAAASUVORK5CYII=
"
	tablelist_blueMenta_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAElJREFUKFNj+P//P1EYqyA2jFUQGwYRykDcjgeD5OEm1gIxNtAAxHATcSmGKwJh
ZIUgDFOMogiEUThQbI9FDKtCrBirICb+zwAAb6M7CAs6hmIAAAAASUVORK5CYII=
"
	tablelist_blueMenta_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAEJJREFUKFNj+P//P1EYwWBgEEeWQMcIBgNDMhBnIksiYwQDovASLsUIBkIhVsW4
FIKwGTEKiTKRKDcS5Ws84fifAQDpge0RK469/gAAAABJRU5ErkJggg==
"
	tablelist_blueMenta_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAARnQU1BAACx    
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41    
LjEwMPRyoQAAAEtJREFUKFONjNEJACAIBZ3EKRqqvtq1hcwkDPMRBQd5HpKIfAElAkrEeqz0B2zh
rqsyAM0v+ifHHoXQhhOHyHZJEJXbmUcSAWVGaALoU+1uRfEIrwAAAABJRU5ErkJggg==
"
	tablelist_blueMenta_collapsedSelActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAEJJREFUKFNj+P//P1EYwWBgEEeWQMcIBgNDMhBnIksiYwQDovASLsUIBkIhVsW4
FIKwGTEKiTKRKDcS5Ws84fifAQDpge0RK469/gAAAABJRU5ErkJggg==
"
	tablelist_blueMenta_expandedSelActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAARnQU1BAACx    
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41    
LjEwMPRyoQAAAEtJREFUKFONjNEJACAIBZ3EKRqqvtq1hcwkDPMRBQd5HpKIfAElAkrEeqz0B2zh
rqsyAM0v+ifHHoXQhhOHyHZJEJXbmUcSAWVGaALoU+1uRfEIrwAAAABJRU5ErkJggg==
"
    } else {
	tablelist_blueMenta_collapsedImg put "
R0lGODlhCgAKAMIFAAAAAC0tLZaWlpycnMnJyf///////////yH5BAEKAAcALAAAAAAKAAoAAAMU
eLrcfkM8GKQbod4cSMPaF37W5CQAOw==
"
	tablelist_blueMenta_expandedImg put "
R0lGODlhCgAKAKEDAAAAAC0tLZCQkP///yH5BAEKAAMALAAAAAAKAAoAAAIPnI+pe+IvUJhTURaY
3qwAADs=
"
	tablelist_blueMenta_collapsedSelImg put "
R0lGODlhCgAKAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAKAAoAAAIQhI+pELHcVotp0mPV
lO6tAgA7
"
	tablelist_blueMenta_expandedSelImg put "
R0lGODlhCgAKAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAKAAoAAAIOhI+pe+EfEIzpMcqy
VgUAOw==
"
	tablelist_blueMenta_collapsedActImg put "
R0lGODlhCgAKAMIFAAAAAC0tLZaWlpycnMnJyf///////////yH5BAEKAAcALAAAAAAKAAoAAAMU
eLrcfkM8GKQbod4cSMPaF37W5CQAOw==
"
	tablelist_blueMenta_expandedActImg put "
R0lGODlhCgAKAKEDAAAAAC0tLZCQkP///yH5BAEKAAMALAAAAAAKAAoAAAIPnI+pe+IvUJhTURaY
3qwAADs=
"
	tablelist_blueMenta_collapsedSelActImg put "
R0lGODlhCgAKAMIFAAAAAC0tLZaWlpycnMnJyf///////////yH5BAEKAAcALAAAAAAKAAoAAAMU
eLrcfkM8GKQbod4cSMPaF37W5CQAOw==
"
	tablelist_blueMenta_expandedSelActImg put "
R0lGODlhCgAKAKEDAAAAAC0tLZCQkP///yH5BAEKAAMALAAAAAAKAAoAAAIPnI+pe+IvUJhTURaY
3qwAADs=
"
    }
}

#------------------------------------------------------------------------------
# tablelist::classic1TreeImgs
#------------------------------------------------------------------------------
proc tablelist::classic1TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable classic1_${mode}Img \
		 [image create photo tablelist_classic1_${mode}Img]
    }

    tablelist_classic1_collapsedImg put "
R0lGODlhDAAKAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAMAAoAAAIgnI8Xy4EhohTOwAhk
HVfkuEHAOFKK9JkWqp0T+DQLUgAAOw==
"
    tablelist_classic1_expandedImg put "
R0lGODlhDAAKAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAMAAoAAAIcnI8Xy4EhohTOwBnr
uFhDAIKUgmVk6ZWj0ixIAQA7
"
}

#------------------------------------------------------------------------------
# tablelist::classic2TreeImgs
#------------------------------------------------------------------------------
proc tablelist::classic2TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable classic2_${mode}Img \
		 [image create photo tablelist_classic2_${mode}Img]
    }

    tablelist_classic2_collapsedImg put "
R0lGODlhDgAMAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAOAAwAAAInnI8Zy4whopThQAlm
NTdmak1ftA0QgKZZ2QmjwIpaiM3chJdm0yAFADs=
"
    tablelist_classic2_expandedImg put "
R0lGODlhDgAMAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAOAAwAAAIinI8Zy4whopThwDmr
uTjqwXUfBJQmIIwdZa1e66rx0zRIAQA7
"
}

#------------------------------------------------------------------------------
# tablelist::classic3TreeImgs
#------------------------------------------------------------------------------
proc tablelist::classic3TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable classic3_${mode}Img \
		 [image create photo tablelist_classic3_${mode}Img]
    }

    tablelist_classic3_collapsedImg put "
R0lGODlhEQAOAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAARAA4AAAIwnI95we2Rgpi0Cris
xkZWYHGDR4GVSE4mharAC0/tFyKpsMq2lV+7dvoBdbbHI1EAADs=
"
    tablelist_classic3_expandedImg put "
R0lGODlhEQAOAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAARAA4AAAIrnI95we2Rgpi0Cris
xkbqyg3eN4UjaU7AygIlcn4p+Wb0Bd+4TYfi80gUAAA7
"
}

#------------------------------------------------------------------------------
# tablelist::classic4TreeImgs
#------------------------------------------------------------------------------
proc tablelist::classic4TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable classic4_${mode}Img \
		 [image create photo tablelist_classic4_${mode}Img]
    }

    tablelist_classic4_collapsedImg put "
R0lGODlhFwASAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAXABIAAAJGXI6pMe0hopxUMGeq
lvdpAGhdA1WgiGVmWI0qdbZpCbOUW4L6rkd4xAuyfisUhjaJ3WYf24RYM3qKsuNmA70+U4aF98At
AAA7
"
    tablelist_classic4_expandedImg put "
R0lGODlhFwASAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAXABIAAAI9XI6pMe0hopxUMGeq
lvft3TXQV4UZSZkjymEnG6kRQNc2HbvjzQM5toLJYD8P0aI7IoHKIdEpdBkW1IO0AAA7
"
}

#------------------------------------------------------------------------------
# tablelist::dustTreeImgs
#------------------------------------------------------------------------------
proc tablelist::dustTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable dust_${mode}Img \
		 [image create photo tablelist_dust_${mode}Img]
    }

    tablelist_dust_collapsedImg put "
R0lGODlhEgAQAKU0AAAAADIyMrConLGpncC6scC7ssG8s8K8tMK9tdDMxtDMx9LOyNrVztvVz9vW
ztvWz9vX0NzW0N3Y0d/a0uDd1uHe1+Lf2OPg2uTh2+Xj3efk3+jl4Ojm4enm4unn4+nn5Orn5evo
5Ovo5evq5ezp5e3q5u3q5+7s6O/t6e7t6vDu6/Hv7PHv7fLw7PLw7vT08vf39fj39fn49vn49///
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAakwJ9w
SCwSCQOBcrkcEIiGxQsWk82ushjspTgMB6zSCaVatVYq1GnkGgwFrE6IVDLZS6RQhyV4pzAZGhsc
ARwbGhkYKX1CAiYUFRYXFwGTFhUUJow/AiISnxITAROgEiKbAh0MEQGtrgEPDx2oHbEPDg8BDbay
qB68ucAevsCwvMNvIRHLzM0RIZsDHhDOzRAebkIHCiAi3t/fHwkIR0lMTAMFREEAOw==
"
    tablelist_dust_expandedImg put "
R0lGODlhEgAQAKU0AAAAADIyMrConLGpncS+tcS/tsbBuMfBucfCucfCutfTzdjUztnUz9vWztvW
z9vX0NzW0N3Y0d/a0t/a0+Dd1uHe1+Lf2OPg2uTh2+Xj3efk3+jl4Ojm4enm4unn4+vo5Ovo5evp
5uvq5ezp5e3q5u3q5+7s6O/t6e7t6vDu6/Hv7PLv7fLw7PHw7fLx7vX08vf39fj39fn49vn49///
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAagwJ9w
SCwSCQOBcrkcEIiGxQsWk82ushjspUAMBy2S6ZRSsVSpk0nkGgwFq85nRCrZSaNPZyV4ozAZGhsc
hBsaGRgofUICJRQVFhcXGJIWFRQliz8CIBGeERITEp8RIJoCHQsQAaytAQ4OHacdsA4NsAy1sace
ur6wHry/vsFvHxDIycoQH5oDHw/Lyg8fbkIHDCEg29zdCwlHSUxMAwVEQQA7
"
}

#------------------------------------------------------------------------------
# tablelist::dustSandTreeImgs
#------------------------------------------------------------------------------
proc tablelist::dustSandTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable dustSand_${mode}Img \
		 [image create photo tablelist_dustSand_${mode}Img]
    }

    tablelist_dustSand_collapsedImg put "
R0lGODlhEgAQAKU1AAAAADIyMpuWjJyXjrSxqbWxqre0rbi1rrm2r8K+tsO+t8TAuMXBusbCu8nF
vcnGvsrHv8vHwMnGwcrIwczIwMzIwc3Jw87LxMzKxc/MxdDMxdDMx9HOx9HOyNLPydPPytPQydPQ
y9TRy9TRzNXTzNXSzdfTztbUzNbUzdfVz9nV0NjW0NnW0drY097c2eDe2eXi3uXj3+jm4+nn5Oro
5f///////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAajwJ9w
SCwSCQOBcrkcEIiGCUwmm81oVmpMchgOXqWSSbVirVSm0ug1GApcm85HNKqLPp2NS+BuVSwXGRoB
GhkXFhUtfEICKQ4PEBEUARQREA8OKYs/AiEMnwwNAQ2gDCGbAhwJCgGtrgEKChyoHLGxCQGrtrNu
tbasv7KoHcGwvx2oHgvLzM0LHpsDJc7UJG1CBxgoINzd3ScYCEQFSUxMAwVEQQA7
"
    tablelist_dustSand_expandedImg put "
R0lGODlhEgAQAKU3AAAAADIyMpuWjJyXjrSxqbWxqre0rbi1rrm2r8K+tsO+t8TAuMXBusbCu8bC
vMnFvcnGvsrHv8vHwMnGwcrIwczIwMzIwc3Jw87LxMzKxc/Mxc/MxtDMxdDMx9HOx9HOyNLPydPP
ytPQydPQy9TRy9TRzNXTzNXSzdfTztbUzNbUzdfVz9nV0NjW0NnW0drY097c2eDe2eXi3uXj3+jm
4+nn5Oro5f///////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAagwJ9w
SCwSCQOBcrkcEIgGioxGq9VsVupschgOYqcTitVytVioUyk2GApgnU+IVKqTQp8OTOB+WS4YGhwb
HBoYFxYvfEICKw8QERIVFhUSERAPK4s/AiMMnwwNDg2gDCObAh4JCgGtrgEKCh6oHrGxCbi2srS6
vbGzbh++vR+oIAvIycoLIJsDJ8vRJm1CBxkqItna2ikZCEQFSUxMAwVEQQA7
"
}

#------------------------------------------------------------------------------
# tablelist::gtkTreeImgs
#------------------------------------------------------------------------------
proc tablelist::gtkTreeImgs {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable gtk_${mode}Img \
		 [image create photo tablelist_gtk_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_gtk_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAUUlEQVQoz8XTwQ2AQAhE0T17+jVQ
h/XRGIV9L5p4FsxSwAuZgbV+nHNEARzBACOijwFWVR8DVPvYA7WxN6Samd4FHHs3GslorLWxO5p6
k0/IBbP6VlQP0oOsAAAAAElFTkSuQmCC
"
	tablelist_gtk_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAW0lEQVQoz+3SwQmAQAxE0fHqKTVM
HWt7aWwsKB3Ek4IQYXVBEPzXkJdLgL/XmgA0M1PvQkQsANareSOZkrJKUpJMAK3nWIndRUrsKXLC
3H0IOTAzG0b25m8/5Aai703YBhwgYAAAAABJRU5ErkJggg==
"
	tablelist_gtk_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAa0lEQVQoz7XSMQqAMAyF4d9OAZeM
OYyeXg/TMZN0qwdQKyltxjz4CI/AxNmGKKpah2CqWs0sjKW3ZSkFMzsiWPoKolhqhRFs+Sj7Me6+
AlfXRQAigrvvLeQXEhFyzjtwdncUQYb+0bzP7kVuCWMmCi7K2XoAAAAASUVORK5CYII=
"
	tablelist_gtk_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABIAAAAOCAYAAAAi2ky3AAAAXUlEQVQoz2NgGAV0A4wMDAyZAgIC
04jV8OHDhywGBobp6OLMDAwMZ378+PGKg4PDm1xDYAYxEGMYPkOwgUwBAYH/6JiBgSGTnHCDG6ak
pES2ISiGUWoIDIgM7QQJACRKJBMon0pJAAAAAElFTkSuQmCC
"
    } else {
	tablelist_gtk_collapsedImg put "
R0lGODlhEgAOAMIFAAAAABAQECIiIoaGhsPDw////////////yH5BAEKAAcALAAAAAASAA4AAAMi
eLrc/pCFCIOgLpCLVyhbp3wgh5HFMJ1FKX7hG7/mK95MAgA7
"
	tablelist_gtk_expandedImg put "
R0lGODlhEgAOAMIFAAAAABAQECIiIoaGhsPDw////////////yH5BAEKAAcALAAAAAASAA4AAAMg
eLrc/jDKSWu4OAcoSPkfIUgdKFLlWQnDWCnbK8+0kgAAOw==
"
	tablelist_gtk_collapsedActImg put "
R0lGODlhEgAOAKEDAAAAABAQEBgYGP///yH5BAEKAAMALAAAAAASAA4AAAIdnI+pyxjNgoAqSOrs
xMNq7nlYuFFeaV5ch47raxQAOw==
"
	tablelist_gtk_expandedActImg put "
R0lGODlhEgAOAKEDAAAAABAQECIiIv///yH5BAEKAAMALAAAAAASAA4AAAIYnI+py+0PY5i0Bmar
y/fZOEwCaHTkiZIFADs=
"
    }
}

#------------------------------------------------------------------------------
# tablelist::klearlooksTreeImgs
#------------------------------------------------------------------------------
proc tablelist::klearlooksTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable klearlooks_${mode}Img \
		 [image create photo tablelist_klearlooks_${mode}Img]
    }

    tablelist_klearlooks_collapsedImg put "
R0lGODlhDQAIAIABAAAAAP///yH5BAEKAAEALAAAAAANAAgAAAIPjI8IkL3c1IoSxkcDzjMXADs=
"
    tablelist_klearlooks_expandedImg put "
R0lGODlhDQAIAIABAAAAAP///yH5BAEKAAEALAAAAAANAAgAAAIRjI+pCXCtmpNLwhUoNm57UwAA
Ow==
"
}

#------------------------------------------------------------------------------
# tablelist::mateTreeImgs
#------------------------------------------------------------------------------
proc tablelist::mateTreeImgs {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable mate_${mode}Img \
		 [image create photo tablelist_mate_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_mate_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAOCAYAAAAbvf3sAAAAeUlEQVQoz83RLQ7CUBRE4S+vFQQM
Eo/DlB10Y0gEEnwXQMIq2AChFeygSWUNHtOahv4ISDpmMsk9yUwus9Vm6mHU+BVLPMaA0PgKKW5I
pgDwQokjTn01QyfXKLDH5RsUd/IaWzxxRjUE7LDAAXnfhhZ4447s53/4vz4ZeA6wL/7UqwAAAABJ
RU5ErkJggg==
"
	tablelist_mate_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAOCAYAAAAbvf3sAAAAf0lEQVQoz9XRMQrCYAyG4ccWtdC1
8l/B1at4Cg/iIXqBTr2BOLq4dnEQXJxcnHR3iVBKh64NhDd84UsgYf6xQEKNcqT/xQGvv5CHuMQG
VzwiC5xw6U/IgmesUIW5whrtcGUe/OCOPd7Y4ojn0JD16g437ILdlCMkNMHJkWb26R+bgxLSbl4O
9wAAAABJRU5ErkJggg==
"
	tablelist_mate_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAOCAYAAAAbvf3sAAAAdElEQVQoz83RsQ2CUBQF0AORhoZO
XcHEbZjDECYxhDlMXMDOERxC6WxsbGgwMQTjp/gJt3mveKe4eSw227ngijbkMB3mGztcUIYAeOCF
Gmfs/wED6FCgmeo2BjnWeKLCfQxWX/sGCY44/erwARluOET7Q7z0AZUOkqtBUcIAAAAASUVORK5C
YII=
"
	tablelist_mate_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAOCAYAAAAbvf3sAAAAa0lEQVQoz9XRQQqDUAwE0Ke1Z/A2
f+mid/B0nsCFm55I8QBuWnCTDx/BYpcOhGRgYJIJ90eFFsMPTY8lkzrIHHwrCtZSnB0y3vjigwYP
dEe7upjHEFXRx7MbSkx4hsvrSggpVkv/JNfe7NM710YQSDbaCJ8AAAAASUVORK5CYII=
"
    } else {
	tablelist_mate_collapsedImg put "
R0lGODlhDAAOAOMOAAAAAEBAQEdHR0tLS0xMTFRUVFZWVlxcXG9vb3d3d3p6en9/f4aGhpubm///
/////yH5BAEKAA8ALAAAAAAMAA4AAAQe8MlJq70409F0OEUWMAiRXOOiCIY1lqcLZpxm33cEADs=
"
	tablelist_mate_expandedImg put "
R0lGODlhDAAOAIQQAAAAAEVFRUxMTFBQUFFRUVhYWFlZWVpaWl9fX3V1dXp6en19fYSEhImJiZ6e
nqOjo////////////////////////////////////////////////////////////////yH5BAEK
AAAALAAAAAAMAA4AAAUkICCOZGmeaEoOQdsO5YM0NOKYRsIkBUoshJRCoFAdVMikMhUCADs=
"
	tablelist_mate_collapsedActImg put "
R0lGODlhDAAOAOMLAAAAADs7O0BAQEJCQkNDQ0xMTE9PT1FRUVZWVlpaWmxsbP//////////////
/////yH5BAEKAA8ALAAAAAAMAA4AAAQf8MlJq70406C0IEMmJEVgXCNyCGE1lqf1tRen3TgeAQA7
"
	tablelist_mate_expandedActImg put "
R0lGODlhDAAOAOMKAAAAAEVFRUhISElJSUpKSktLS0xMTE5OTlpaWl1dXf//////////////////
/////yH5BAEKAA8ALAAAAAAMAA4AAAQf8MlJq70408B7qElwjAFiBYIhfFdQsBcRDBqs3XhuRQA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::mentaTreeImgs
#------------------------------------------------------------------------------
proc tablelist::mentaTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable menta_${mode}Img \
		 [image create photo tablelist_menta_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_menta_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAEJJREFUKFNj+P//P1EYwWBgEEeWQMcIBgNDMhBnIksiYwQDovASLsUIBkIhVsW4
FIKwGTEKiTKRKDcS5Ws84fifAQDpge0RK469/gAAAABJRU5ErkJggg==
"
	tablelist_menta_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAKCAYAAACNMs+9AAAAAXNSR0IArs4c6QAAAARnQU1BAACx    
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41    
LjEwMPRyoQAAAEtJREFUKFONjNEJACAIBZ3EKRqqvtq1hcwkDPMRBQd5HpKIfAElAkrEeqz0B2zh
rqsyAM0v+ifHHoXQhhOHyHZJEJXbmUcSAWVGaALoU+1uRfEIrwAAAABJRU5ErkJggg==
"
    } else {
	tablelist_menta_collapsedImg put "
R0lGODlhCgAKAMIFAAAAAC0tLZaWlpycnMnJyf///////////yH5BAEKAAcALAAAAAAKAAoAAAMU
eLrcfkM8GKQbod4cSMPaF37W5CQAOw==
"
	tablelist_menta_expandedImg put "
R0lGODlhCgAKAKEDAAAAAC0tLZCQkP///yH5BAEKAAMALAAAAAAKAAoAAAIPnI+pe+IvUJhTURaY
3qwAADs=
"
    }
}

#------------------------------------------------------------------------------
# tablelist::mintTreeImgs
#------------------------------------------------------------------------------
proc tablelist::mintTreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable mint_${mode}Img \
		 [image create photo tablelist_mint_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_mint_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAOCAYAAAAbvf3sAAAAU0lEQVQoz73RQQ2AMAwF0JfdZodg
AhEo44gITBAkYGNXDIxmCwv/2PQ1acvf2XrBjT1qSJXaFKEayBFKL4MyZhytoGsHKDixtICCC+uQ
s35+3Pg8G2gLGrFw1rcAAAAASUVORK5CYII=
"
	tablelist_mint_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAOCAYAAAAbvf3sAAAAVUlEQVQoz+XRsQmAMBRF0SM6gQOl
dgwLB3OWLGCXMuAWljYKQRTTihd+8/591eOHNAiYK9wRscWKBQO6G3HDhHh9BCTk4tKRP1KWXuWy
lGvlk/5Dw+18fA9T93dmqwAAAABJRU5ErkJggg==
"
	tablelist_mint_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAOCAYAAAAbvf3sAAAATUlEQVQoz2NgoCv4////PFI1vPj/
//9yfGqYsIhZ4NOETQMnPk1MOAyCadpHrAaS/MDAwMDwnYGB4QQjI6MTMaF0n1BIkRSslEUcTQAA
5D0vedmcvmEAAAAASUVORK5CYII=
"
	tablelist_mint_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAOCAYAAAAbvf3sAAAAVUlEQVQoz+WRwQnAIBAEdwPpyTIs
NWXYhV878Dn5JGAkEb+ShfssM3Cw0g9jIEg6JthoO222k6QoqX6A9YYfLRCADJTm8vXBezppDHdS
mYIbaV9ouBPWj0JRP45ECQAAAABJRU5ErkJggg==
"
    } else {
	tablelist_mint_collapsedImg put "
R0lGODlhDAAOAMIHAAAAACEhISgoKCoqKkhISFxcXGRkZP///yH5BAEKAAcALAAAAAAMAA4AAAMd
eLrc7uaxUKQKo8qAteOBQDygSHZbZlHWEbVwmwAAOw==
"
	tablelist_mint_expandedImg put "
R0lGODlhDAAOAKEDAAAAACEhISkpKf///yH5BAEKAAMALAAAAAAMAA4AAAIWnI+py+0aopRIzCCU
jXnZzgTPSJZIAQA7
"
	tablelist_mint_collapsedSelImg put "
R0lGODlhDAAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAMAA4AAAIXhI+pGovRHIBx0Zou
PtpS94FbJpWmUQAAOw==
"
	tablelist_mint_expandedSelImg put "
R0lGODlhDAAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAMAA4AAAIRhI+py+0aopRo0mTZ
1a/7jxQAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::mint2TreeImgs
#------------------------------------------------------------------------------
proc tablelist::mint2TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable mint2_${mode}Img \
		 [image create photo tablelist_mint2_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_mint2_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADr4AAA6+AepCscAAAAAHdElNRQfgBQkTHSnMxpiBAAAAGnRFWHRTb2Z0
d2FyZQBQYWludC5ORVQgdjMuNS4xMDD0cqEAAABRSURBVChTpZGxCQAgDAR/fkdwMitXiYqFPsRE
Y3HFPRwEhYg8o44eLEDa/QQLUDt53zRYZlS8kGVGbsiyIjNk+Yyezws9hBkMWCKfe4s62gga8dTd
YGVViS0AAAAASUVORK5CYII=
"
	tablelist_mint2_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOvgAADr4B6kKxwAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAYklE
QVQoU5XLQQqAMAxE0ZzBW/T+lxDciK49S5rUGiidZrDwFh3yRVV/gyMDRwaODBwZf8Wc5klcpkTU
Sw8Pg4LbRBBREk5Bux0+YwiDdjcNb7ivAodHkQ3tHzgycGTgmFOpl2jLGnIdx90AAAAASUVORK5C
YII=
"
	tablelist_mint2_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOvAAADrwBlbxySQAAAAd0SU1FB+AFCRMdKczGmIEAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAFVJREFUKFOlkDEKwDAMA/N7736If+dZjYcOAlPF6XCEEzkIWQDGtKOC
xN33wRc6SMwMJyFJRREhQ5KKMlOGJG+kQpJf0fh5Vx+hgoLkJCjaUdGO32A9XVwfc0mdLjYAAAAA
SUVORK5CYII=
"
	tablelist_mint2_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOvQAADr0BR/uQrQAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAW0lE
QVQoU5XLwQ3AIAxDUbbPjckyRJbIOcg9VG1xsHp4SHzwqKrfaFRoVGhUaFSuY85ZZtbC+zYCPERE
ZeYN9+8AXpfnsBvAFvDR3dsB0HgaAI0KjQqNCo1nNRZ9ViCcGRAOXQAAAABJRU5ErkJggg==
"
    } else {
	tablelist_mint2_collapsedImg put "
R0lGODlhDQAOAMIFAAAAACEhIScnJ2VlZXV1df///////////yH5BAEKAAcALAAAAAANAA4AAAMc
eLrc/odAFsZUQdgZ8n6dB4XaKI4l90HS5b5HAgA7
"
	tablelist_mint2_expandedImg put "
R0lGODlhDQAOAMIHAAAAACIiIiwsLC0tLS8vLzQ0NDc3N////yH5BAEKAAcALAAAAAANAA4AAAMZ
eLrc/jDKSYK9YbSCg3ic9UHcGBlTqq5RAgA7
"
	tablelist_mint2_collapsedSelImg put "
R0lGODlhDQAOAMIFAAAAAIeHh5KSkq6urvX19f///////////yH5BAEKAAcALAAAAAANAA4AAAMd
eLrc/kdAFuQ8YVgYiJ6dtzXh93TmmZ7j017wlAAAOw==
"
	tablelist_mint2_expandedSelImg put "
R0lGODlhDQAOAMIGAAAAAIeHh46OjszMzODg4PX19f///////yH5BAEKAAcALAAAAAANAA4AAAMa
eLrc/jDKKYK9QTRBiieawxVgJAyhOa1sGyUAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::newWaveTreeImgs
#------------------------------------------------------------------------------
proc tablelist::newWaveTreeImgs {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable newWave_${mode}Img \
		 [image create photo tablelist_newWave_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_newWave_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAABCUlEQVQoz8WSP0vEQBTE561h0SL2
FgFTZHGrlNY2FvJ6K/Ej2F6hvVjZChZWfgCzJ3YBOxftZSFwrRGuEJKT/LVKIQiXs7lpB37Mm3nA
ukXMvA3giogukiT5XBWwoZTaaprmtm3bE621UEq9Oee6sQABAHVd52maXud5ftD3/SszH60EIKK6
qqoPa+29tfamKIoJM0+ZeW/MCZtd151mWfYAYFGW5Xw2mz0LIb5837/UWiul1Itz7vsvgDckADD/
ZXheQURLu/AAQAjRDIAoinbCMJxIKQWAY2PM+1IAEdVBECy01mdSykMA58aYxzElDgl24zh+AnAH
YN8YU49dwQPQAZj+95HWrx8slWOLxRjWjwAAAABJRU5ErkJggg==
"
	tablelist_newWave_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAABBklEQVQoz9VSPUsDQRB9c7dedeSK
LW7/QLgjbHuV3RUiuD/AJtraWdgFUqS1lPwBA4KN3VjaXe0P2NYrrtAELBT2DrFJIITNRyU4MDBv
5s2D+QD+vZExpgcg2MP7YeZPX0EAuO267tw59+EjRFEkhRCPAK68AkQ0BnBSVdWdc67daD4qy/J6
yfFaaK39yvM8SJLkuK7rVwDfKy+K4jSO4ydmftkmsJp9KqXsK6VCAHMAc6VUKKXsA5juWk4AAMzc
EtFIaz0EsACw0FoPiWjEzO3OK6wDY8xz0zT3AKCUumTms31nFBv4Jk3T2TK+OOQPwnVgrX3PsmxA
RG/M/HCIgPDkJn/6yr/4D0fVv4huoQAAAABJRU5ErkJggg==
"
	tablelist_newWave_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAABEElEQVQoz9XRsUoDURAF0DvZl8QQ
iYquy75tLaxsZjv/wMJSEC39AnvBzlIEwc5a/IB0NoKFmGmsRKx3MQGjEkR8u28sRLCRbCrxtsMc
LjPAXydI07QTx/GRtfY6z/O3iQFrbatdw1mTsLMQW5ckiWRZ5qsCNQDoBCi25v172tZ9A71l5rWJ
ABB0qk7F6gyG24s6vdTCOTN3mXm5EkAEDQyVgaFyrkkf6yEeNyKshA3cMPMhM8/+BpjvBoGh4ueA
HOqA6rgG5mufYEytBIBnp+ZioNH9SK8A7IrI3VgABPUBlZd9H/aG/sl5bIpIt8oRDQC8OG2cPJTR
q9MDIjoW6bmqXzAA/KjAKaB7IjLAv8snuPFdR0oRvJ0AAAAASUVORK5CYII=
"
	tablelist_newWave_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAAOCAYAAAAmL5yKAAABDklEQVQoz9VSPUsDQRB9b/fuhKAn
gRA5q/yIq+0s7fwJFtYhbUCxs05pK/4IsbhOcBdNbWOVBUlhDu5E93JjFVC5fFSCAwPz5j0ew8wA
/z6YpmkMQK3R1caYvIkIROSypXASK5k3CfKauqxxBeC00QDAUAHHR3H9GfAnWQlw86YjAMNlo2nn
XNlJ9r3SPOy1WGrNepEP79x5+eCFtfZumYECAJKjccFJSUoQsgpCViUp44ITkqNVy1EAYIzxXjDI
ZmyHkfJhpHw2Y9sLBsYYv8pALwrn3PNWJznobbObz6GzqTxaa8/WnTH4hfu3r3IPAAL0N/kD/R04
56a73WSvqPBkrb3exCBo6J3/6St/AbNWYeq4QB0rAAAAAElFTkSuQmCC
"
    } else {
	tablelist_newWave_collapsedImg put "
R0lGODlhEAAOAIQdAAAAAFJSUl5eXl9fX2JiYmZmZmdnZ2lpaWtra2xsbG5ubnBwcHJycnR0dH19
fX9/f5KSkpSUlJqampycnJ2dnaGhoaenp6ysrLm5ucvLy8zMzN3d3ejo6P///////////yH5BAEK
AB8ALAAAAAAQAA4AAAU44CeOZGmeZYSegbCWAsQgr0hYFqU8r4H9mEpBgkJkjpnLgXhabDYaB2/V
4EwUtc8gkRWpuuDwKAQAOw==
"
	tablelist_newWave_expandedImg put "
R0lGODlhEAAOAIQSAAAAAFJSUltbW19fX2xsbHBwcHh4eHl5eX9/f5KSkpSUlJWVlZqamqenp6ys
rLm5ubq6usrKyv///////////////////////////////////////////////////////yH5BAEK
AB8ALAAAAAAQAA4AAAU04CeOZGmeaKqmSiC8cKCcQ7LcSzKkR+M3BxXB8Xg4CCtDJGJYfRAQCML5
KRSoHwYDy6WGAAA7
"
	tablelist_newWave_collapsedActImg put "
R0lGODlhEAAOAKUgAAAAAEA3NUI6N1A9OFE/OVNAOlNCO1BCPFFDPVRCO1VEPF5EO2JJP29IPU1E
QlBIRFdTU1dVU3lWR21tbZVdSJ9dSJdgS6RbRq1iSqpsUrFoTrRuUrlzVrh4WYWFhYyMjP//////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKAAAALAAAAAAQAA4AAAY8QIBw
SCwaj0UP8hhwLIuDSwPyFBIwmMpi8ixovhrK4YM0bM4bC4J8THA4GQZ3qehIIlWA4JEXKvuAgUNB
ADs=
"
	tablelist_newWave_expandedActImg put "
R0lGODlhEAAOAIQSAAAAAD83NU87NlNGP2FIP29KPk1EQldUU21tbZ1oT6JXRKVYRKNiS6xhSrFo
TrdwU4WFhYyMjP///////////////////////////////////////////////////////yH5BAEK
AB8ALAAAAAAQAA4AAAU04CeOZGmeaKqmUCC8cACdhrLci2KkReM3BdWB4XAwDivC40FYfRCJBML5
GQyon0gEy6WGAAA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::oxygen1TreeImgs
#------------------------------------------------------------------------------
proc tablelist::oxygen1TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable oxygen1_${mode}Img \
		 [image create photo tablelist_oxygen1_${mode}Img]
    }

    tablelist_oxygen1_collapsedImg put "
R0lGODlhDwAGAKECAAAAABQTEv///////yH5BAEKAAAALAAAAAAPAAYAAAINhI95oQ3sVpgwPouq
KwA7
"
    tablelist_oxygen1_expandedImg put "
R0lGODlhDwAGAKECAAAAABQTEv///////yH5BAEKAAAALAAAAAAPAAYAAAIKhI+pyw0BoZtUFQA7
"
}

#------------------------------------------------------------------------------
# tablelist::oxygen2TreeImgs
#------------------------------------------------------------------------------
proc tablelist::oxygen2TreeImgs {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable oxygen2_${mode}Img \
		 [image create photo tablelist_oxygen2_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_oxygen2_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAICAYAAAAm06XyAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AsDFBwlCamtawAAAFVJREFUGNOtzbENQFAYReEv0UgM
YgEVlUQjEttYRfEqu1hBDKCxhuYt8L84za3OPfzAhDUqVXlb7GhwltQ7XDjySZgBL7ao2ONGQh0R
FzwlRRgxR6UPRPkJSYt8DiIAAAAASUVORK5CYII=
"
	tablelist_oxygen2_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAICAYAAAAm06XyAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AsDFB8qsjvjOQAAAFJJREFUGNPF0CsKgEAABNAXF7yO
aU2CZRG8jcmbmDyU2LV4Dcsm02rQaTMwzIc/0aK/aQldiTnhQMy8xo6hNH3EhgYrpqf1Z5xY3mwP
uUH1ydMXx2UJYO9Vo0sAAAAASUVORK5CYII=
"
	tablelist_oxygen2_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAICAYAAAAm06XyAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AsDFB4pMimDwgAAAHZJREFUGNOlkC0Og2AQRN82cJ9P
VKFJECScYR1J0SiOgcTsHRBcArFn6B1auzWIym46ZtTL/MC/Uo9WPYYsd7u8Blb1WDKwfKXfAQNO
YLIir1+TsSInMAId8MjURj0aYAN2YM0c1qvHUz3mzObq8jcwWpEjA38Arr8gUfq42wkAAAAASUVO
RK5CYII=
"
	tablelist_oxygen2_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA8AAAAICAYAAAAm06XyAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AsDFCA0EOr0ZgAAAHJJREFUGNPF0C0OwkAQBtC3BEE4
TQUKR4IhpHeYCiyOI3AF/lQdZ+gt1nOYxawgmFbBqMmXvEm+4W8TuWwil/1XtotctmN2hgWukcu6
whVuWI7hVMEJHQ6449k36TwJ1wMPtBj6JsWUyvOP/YgXLj959hvQPxzKCnzYTQAAAABJRU5ErkJg
gg==
"
    } else {
	tablelist_oxygen2_collapsedImg put "
R0lGODlhDwAIAIABAAAAAP///yH5BAEKAAEALAAAAAAPAAgAAAIQjI8ZAOrcXIJysmoo1jviAgA7
"
	tablelist_oxygen2_expandedImg put "
R0lGODlhDwAIAIABAAAAAP///yH5BAEKAAEALAAAAAAPAAgAAAIRjI+pawDnmHuThRntzfr2fxQA
Ow==
"
	tablelist_oxygen2_collapsedActImg put "
R0lGODlhDwAIAKECAAAAAGDQ/////////yH5BAEKAAAALAAAAAAPAAgAAAIQhI8JEercXIJysmoo
1jviAgA7
"
	tablelist_oxygen2_expandedActImg put "
R0lGODlhDwAIAKECAAAAAGDQ/////////yH5BAEKAAAALAAAAAAPAAgAAAIRhI+paxHnmHuTgRnt
zfr2fxQAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::phaseTreeImgs
#------------------------------------------------------------------------------
proc tablelist::phaseTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable phase_${mode}Img \
		 [image create photo tablelist_phase_${mode}Img]
    }

    tablelist_phase_collapsedImg put "
R0lGODlhDwAKAKECAAAAAMfHx////////yH5BAEKAAAALAAAAAAPAAoAAAIUhI9poQ3BHIJRPmov
lrS6bUHZMhYAOw==
"
    tablelist_phase_expandedImg put "
R0lGODlhDwAKAKECAAAAAMfHx////////yH5BAEKAAAALAAAAAAPAAoAAAIRhI+pyx0P4YqS0WYq
BmH7jxQAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::plain1TreeImgs
#------------------------------------------------------------------------------
proc tablelist::plain1TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable plain1_${mode}Img \
		 [image create photo tablelist_plain1_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_plain1_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAKCAYAAACALL/6AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEwYtcCg47AAAACpJREFUGNNjYKAA1BOjiIlUTUyk
2sREqvOYSPUTPg2NpGhoJMVJjVSNBwD8+gSMwdvvHwAAAABJRU5ErkJggg==
"
	tablelist_plain1_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAwAAAAKCAYAAACALL/6AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEwkTNtE5iAAAAC9JREFUGNNjYBh0gJGBgaGeCHWN
yBoYCGhqRLeBAY+mRmxOYsChqZFYf9UPbLACACL9BIS+a6kZAAAAAElFTkSuQmCC
"
    } else {
	tablelist_plain1_collapsedImg put "
R0lGODlhDAAKAIABAH9/f////yH5BAEKAAEALAAAAAAMAAoAAAIUjI8IybB83INypmqjhGFzxxkZ
UgAAOw==
"
	tablelist_plain1_expandedImg put "
R0lGODlhDAAKAIABAH9/f////yH5BAEKAAEALAAAAAAMAAoAAAIQjI+py+D/EIxpNscMyLyHAgA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::plain2TreeImgs
#------------------------------------------------------------------------------
proc tablelist::plain2TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable plain2_${mode}Img \
		 [image create photo tablelist_plain2_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_plain2_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAMCAYAAABSgIzaAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEwwFv3J4nAAAADJJREFUKM9jYKASaCJWIRO5mpnI
tZmJXGczketnJnIDjBiNdeRorCPHqXXkBE4dzVIOAPKWBZkKDbb3AAAAAElFTkSuQmCC
"
	tablelist_plain2_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAMCAYAAABSgIzaAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKEw4I8/VmowAAADZJREFUKM9jYBgygJGBgaGeBPWN
yBoZiNTciG4jAxGaG7E5lYGA5kZcfmTAo7mR1ECrZxg+AAC4iAWFJSdDXQAAAABJRU5ErkJggg==
"
    } else {
	tablelist_plain2_collapsedImg put "
R0lGODlhDgAMAIABAH9/f////yH5BAEKAAEALAAAAAAOAAwAAAIXjI9poA3c0IMxTOpuvS/yPVVW
J5KlWAAAOw==
"
	tablelist_plain2_expandedImg put "
R0lGODlhDgAMAIABAH9/f////yH5BAEKAAEALAAAAAAOAAwAAAIUjI+pywoPI0AyuspkC3Cb6YWi
WAAAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::plain3TreeImgs
#------------------------------------------------------------------------------
proc tablelist::plain3TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable plain3_${mode}Img \
		 [image create photo tablelist_plain3_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_plain3_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExAQNNjBKgAAADtJREFUKM9jYKABqCdHExM1DGKi
houYqOE1JmqEERM1ApuJGrFGrCGNlBrSSKl3GikN2EZKo7iR7nkHAKniBpTspddsAAAAAElFTkSu
QmCC
"
	tablelist_plain3_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABEAAAAOCAYAAADJ7fe0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExIRcemTPgAAAD5JREFUKM/t0jsOACAIRMHnycne
3J6IgJa6PRN+8OMzADuok0doQlp1QgNSNA5FSLudUICULZYE0s3l7NGPnffUBoaD5FpzAAAAAElF
TkSuQmCC
"
    } else {
	tablelist_plain3_collapsedImg put "
R0lGODlhEQAOAIABAH9/f////yH5BAEKAAEALAAAAAARAA4AAAIdjI+ZoH3AnIJRPmovznTL7jVg
5YBZ0J0opK4tqhYAOw==
"
	tablelist_plain3_expandedImg put "
R0lGODlhEQAOAIABAH9/f////yH5BAEKAAEALAAAAAARAA4AAAIYjI+py+1vgJx0pooXtmy/CgVc
CITmiR4FADs=
"
    }
}

#------------------------------------------------------------------------------
# tablelist::plain4TreeImgs
#------------------------------------------------------------------------------
proc tablelist::plain4TreeImgs {} {
    foreach mode {collapsed expanded} {
	variable plain4_${mode}Img \
		 [image create photo tablelist_plain4_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_plain4_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABcAAAASCAYAAACw50UTAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExUCuhZEJwAAAEdJREFUOMu91IsNACAIQ0HSxU03
dwf1ZIBH6IeZz7NegSIXRF4QKVGkB5EmR6YoMqaRPTiBV8GrZKkytCqKVSWqqv8VmP/zDd6/CJzv
kRcqAAAAAElFTkSuQmCC
"
	tablelist_plain4_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABcAAAASCAYAAACw50UTAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4AUKExY6uTmvegAAAExJREFUOMvtlNsNACAIA8/JSTd3
ApWHfmjsAD1SCvD1lBpgG3w0MqcI0GxyCgCtYiEJkCdzEgB5F0oQoEhbCAAUrSJOgE7cgv13cI86
Y04IiOwcRtoAAAAASUVORK5CYII=
"
    } else {
	tablelist_plain4_collapsedImg put "
R0lGODlhFwASAIABAH9/f////yH5BAEKAAEALAAAAAAXABIAAAIojI+pCusL2pshSgotznoj23kV
GIkjeWFoSK1pi5qxDJpGbZ/5/cp5AQA7
"
	tablelist_plain4_expandedImg put "
R0lGODlhFwASAIABAH9/f////yH5BAEKAAEALAAAAAAXABIAAAIijI+py+0Po3Sg2ovrylyzjj2g
J3YTNxlhqpJsALzyTNdKAQA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::plastikTreeImgs
#------------------------------------------------------------------------------
proc tablelist::plastikTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable plastik_${mode}Img \
		 [image create photo tablelist_plastik_${mode}Img]
    }

    tablelist_plastik_collapsedImg put "
R0lGODlhDgAOAMIDAAAAAHZ2drW1tf///////////////////yH5BAEKAAQALAAAAAAOAA4AAAMp
SLrc/vCJQKlwc2gdLgsbsAUNqIlcOQAsO5BfOKrnzGTb692VFf1ARgIAOw==
"
    tablelist_plastik_expandedImg put "
R0lGODlhDgAOAMIDAAAAAHZ2drW1tf///////////////////yH5BAEKAAQALAAAAAAOAA4AAAMn
SLrc/vCJQKlwc2gdLgtbGDRgyJEDoKrD+JnnC7tLJnrMVHVR7zMJADs=
"
}

#------------------------------------------------------------------------------
# tablelist::plastiqueTreeImgs
#------------------------------------------------------------------------------
proc tablelist::plastiqueTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable plastique_${mode}Img \
		 [image create photo tablelist_plastique_${mode}Img]
    }

    tablelist_plastique_collapsedImg put "
R0lGODlhEQAOAOMLAAAAAHp4eH59fa+trfHx8fPz8/X19ff39/n5+fv7+/39/f//////////////
/////yH5BAEKAA8ALAAAAAARAA4AAAQ+8MlJq7042yG6FwMmKGSpCGKiBmqCXgIiBzLyWsIR7Ptx
VwKDMCA0/CiCgjKgLBwnAoJ0SnhKOJ9OSMPtYiIAOw==
"
    tablelist_plastique_expandedImg put "
R0lGODlhEQAOAOMLAAAAAHp4eH59fa+trfHx8fPz8/X19ff39/n5+fv7+/39/f//////////////
/////yH5BAEKAA8ALAAAAAARAA4AAAQ78MlJq7042yG6FwMmKGSpCGKirgl6CUgsI64lHEGeH3Ul
GMCgoUcRFI7IAnEiIDifhKWE8+mENNgsJgIAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::radianceTreeImgs
#------------------------------------------------------------------------------
proc tablelist::radianceTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable radiance_${mode}Img \
		 [image create photo tablelist_radiance_${mode}Img]
    }

    tablelist_radiance_collapsedImg put "
R0lGODlhEgAQAKUoAAAAAEBAQOTe1eTe1uTf1+bh2ejj2ujk3erl3uvn4Ozo4u3p4+7q5O/r5u/s
5+/t6PDt6PPw7PLw7fXz8Pb08ff18vb18/f28vj28fj28vj28/j39Pj39fj49fn49/n5+Pr6+Pv7
+fz8+fz8+vz8+/39/P39/f7+/f//////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAaZwJ9w
SCwWD4KkUnkwFjAj02k6NY0oBeLBQiKVvuBS19IUCkCgkGjEZotCaMFQ4Kl/7oH7p+6RmzkcGxsc
HQEdgYAcfj8CGhoZGhQVARUVF44aiwIUFBMBn6ABnBSaEhESqBIBqamaEA+wsAGxsBCaC7i5Abm4
DJoJCMHCwwgKiwcNBsrLzAYOZUIFCgQD1dYDBApZR0vd0EJBADs=
"
    tablelist_radiance_expandedImg put "
R0lGODlhEgAQAKUoAAAAAEBAQOTe1eTe1uTf1+bh2ejj2ujk3erl3uvn4Ozo4u3p4+7q5O/r5u/s
5+/t6PDt6PPw7PLw7fXz8Pb08ff18vb18/f28vj28fj28vj28/j39Pj39fj49fn49/n5+Pr6+Pv7
+fz8+fz8+vz8+/39/P39/f7+/f//////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAASABAAAAaTwJ9w
SCwWD4KkUnkwFjAj02k6NY0oBeLBQiKVvuBS19IUCkCgkGjEZotCaMFQ4Kl/7vhP3SM3czgbGxwd
hIB/HH0/AhoaGRoUFRcVkYwaiQIUFBMBnJ0BmRSXEhESpaanEpcQD6ytrg8QlwuztLWzDJcJCLu8
vQgKiQcNBsTFxgYOZUIFCgQDz9ADBApZR0vXykJBADs=
"
}

#------------------------------------------------------------------------------
# tablelist::ubuntuTreeImgs
#------------------------------------------------------------------------------
proc tablelist::ubuntuTreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable ubuntu_${mode}Img \
		 [image create photo tablelist_ubuntu_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_ubuntu_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAsAAAAOCAYAAAD5YeaVAAAAgElEQVQoz73ROwrCUBSE4Q8jATtR
AkoWpZCVuA8xO0gr2LgdF+Cj0CJ1bGyuTUhuECTTzTn/FMMwllaxZ9LyFd64dMGTlk9RoEQ+BMMN
sxAohmCoccUmhNYxGBo8QukDsmkETrHEHXs8++A5Fjji/D12wTle2IWyvTph+5cFf9IH6EoSOPaU
kccAAAAASUVORK5CYII=
"
	tablelist_ubuntu_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAsAAAAOCAYAAAD5YeaVAAAAiklEQVQoz9XRIQoCYRAF4M8VXCzC
j2lFTJ7H5C02eA+bd9BgEBeP4R3MBrVZNFn+hZ8/qEnwwYThvZl5vOH/0EGFFfpvdE8surjjgSlO
uGTVwxbHIk4ecEXINgbcsIciIZYYoIx9iVDX9Sb1nGKGOc4YYYemJYtM3NqZxPPNp4QqrDH+NtLh
bz/4Au5zF3nYGscDAAAAAElFTkSuQmCC
"
	tablelist_ubuntu_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAsAAAAOCAYAAAD5YeaVAAAAiElEQVQoz72SoQoCURREz11YweIv
uFEQo83id+wvWMT/M4nFbhCxLNjXKMixaHks6xPEaQOHO8xw4S9Sp9/AN3WTC9/Vq3roSikSXwIn
YATs05RILwO7lx0CY6AB6og498FvzYAHMC96KgyACXABFhHRdBXcqke1Vde5a1SfpmvVVe7Oy5+9
wxNzbFn4+q5BGgAAAABJRU5ErkJggg==
"
	tablelist_ubuntu_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAsAAAAOCAYAAAD5YeaVAAAAj0lEQVQoz9WRMQ4BARBF30ejICKa
jUg4z15EOMsewC00nEOhlJAoHEDUT7MrCkQl8ZufmXnF/Bn4P0WdAlug/4G7AWUnyUmtgAVwfAHO
gFWSQ5qOugF6wOUJLIBrkhKg9TSYA0OgW9ddYAQsG+ABJzkDFTAG2rVXSU5vk6hrdV+v9Vlqoe7U
yVf3VAe//eAdhJ0u3C54tZ8AAAAASUVORK5CYII=
"
    } else {
	tablelist_ubuntu_collapsedImg put "
R0lGODlhCwAOAKECAAAAAExMTP///////yH5BAEKAAAALAAAAAALAA4AAAIWhI+py8EWYotOUZou
PrrynUmL95RLAQA7
"
	tablelist_ubuntu_expandedImg put "
R0lGODlhCwAOAKECAAAAAExMTP///////yH5BAEKAAAALAAAAAALAA4AAAIThI+pyx0P4Yly0pDo
qor3BoZMAQA7
"
	tablelist_ubuntu_collapsedSelImg put "
R0lGODlhCwAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAALAA4AAAIWhI+py8EWYotOUZou
PrrynUmL95RLAQA7
"
	tablelist_ubuntu_expandedSelImg put "
R0lGODlhCwAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAALAA4AAAIThI+pyx0P4Yly0pDo
qor3BoZMAQA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::ubuntu2TreeImgs
#------------------------------------------------------------------------------
proc tablelist::ubuntu2TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable ubuntu2_${mode}Img \
		 [image create photo tablelist_ubuntu2_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_ubuntu2_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAKCAYAAACJxx+AAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA7DAAAOwwHHb6hkAAAAB3RJTUUH4AsDFAkb/31W1AAAAFhJREFUGNONj7sNgDAMBc/uwhwZ
j5IxKLMLy7BHykdDRGLxO8mF9U7PsnEiiYiZ4d2S+WADsiTaAFcDMAElNnloSVHym1MJWN+ECixP
QgVmSfvvL3qGsAkHUqArtr/xO8MAAAAASUVORK5CYII=
"
	tablelist_ubuntu2_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAKCAYAAACJxx+AAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA7DAAAOwwHHb6hkAAAAB3RJTUUH4AsDFBAHcHyjgwAAAEhJREFUGNO9zLERQEAYBeGPC1Qg
FGlGQwKBAoyCnPTmupJI/pCQDd/uPD6nwYLpxeeEigE9uhAXDmwphoIxohYn9qfLFbN/uQEwZAfr
O7QC9wAAAABJRU5ErkJggg==
"
	tablelist_ubuntu2_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAKCAYAAACJxx+AAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA7DAAAOwwHHb6hkAAAAB3RJTUUH4AsDFAw3sNLOcgAAAF9JREFUGNN9kLENgDAQA89IEKWh
gQkYmH2YgJmoTEGCwgvF1cu+4vSyTS9DPSRNXQBYJI09IAM5Qi2A7aNAqS0popuf7MD69gE4gRlI
v0AcbX8cDFy2r9ZL9VGSUhwBbiXCRsSA6M6gAAAAAElFTkSuQmCC
"
	tablelist_ubuntu2_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAgAAAAKCAYAAACJxx+AAAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAA7DAAAOwwHHb6hkAAAAB3RJTUUH4AsDFBELYNHe6QAAAE1JREFUGNO9zCEKgFAABNFZEAwi
iOAFPIPd63sai+FjGosfk1FfnWXhcwEmoH/pByrAoC4+VqBVyT0gyajOQJdkU0+Apn6pexKAUuNP
LsjVKWqydBSbAAAAAElFTkSuQmCC
"
    } else {
	tablelist_ubuntu2_collapsedImg put "
R0lGODlhCAAKAMIFAAAAAD4+PkdHR0hISE9PT////////////yH5BAEKAAcALAAAAAAIAAoAAAMS
eLrcO+4E4cJsNhBmKfcMFDUJADs=
"
	tablelist_ubuntu2_expandedImg put "
R0lGODlhCAAKAMIEAAAAAD4+PkNDQ0tLS////////////////yH5BAEKAAAALAAAAAAIAAoAAAMO
CLrcziHKNaJo477NewIAOw==
"
	tablelist_ubuntu2_collapsedSelImg put "
R0lGODlhCAAKAMIGAAAAAN3d3d7e3ubm5uvr6/Hx8f///////yH5BAEKAAcALAAAAAAIAAoAAAMS
eLrcO+6E4oKhzBqSb5uOEDkJADs=
"
	tablelist_ubuntu2_expandedSelImg put "
R0lGODlhCAAKAKECAAAAAN3d3f///////yH5BAEKAAMALAAAAAAIAAoAAAINnI+pGO0nokhx2YtH
AQA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::ubuntu3TreeImgs
#------------------------------------------------------------------------------
proc tablelist::ubuntu3TreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel} {
	variable ubuntu3_${mode}Img \
		 [image create photo tablelist_ubuntu3_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_ubuntu3_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAWUlE
QVQoU2P4//8/yRiVw8DgDMQSyGLYMCqHgSEGiFcT0ojKgWg6TEgjKgehCa9GVA6qJpwaUTmYmrBq
pIkmkp1HckDg1ADCqByIJrwaQBiVQ04yIg7/ZwAAgQKZuDdqxHAAAAAASUVORK5CYII=
"
	tablelist_ubuntu3_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAXUlE
QVQoU5XLwQ3AIAxDUcZgLMbobkzCVGmSFhCKhQHpH7DykohcB0cWHFlwZNkr2nNY6ShrVWsku8mO
fsngAAMRuIAF+SfCAPwuDBNC4Ddw/CAEFhxZcGTBcZ+kF8WCmsIy4DnwAAAAAElFTkSuQmCC
"
	tablelist_ubuntu3_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAXUlE
QVQoU62SywnAIBAFLSVdWYcVp5TNziGweX5wgw/m4MCAiMXM0qioch6iojm3cwXXoYKILUMVb8Sm
oYoYsWH4OTgasS6MARyJ0tdLP8Q0ABVEywBU/PpGG1h5AHZuQvcmAx5DAAAAAElFTkSuQmCC
"
	tablelist_ubuntu3_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAOCAYAAAD0f5bSAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAXUlE
QVQoU5XOgQmAMBAEwZRidfZilZby/koSjDlyKozg8QuWiPhNjo4cHTk6vPZ0fMTtHW3pTO7hhtv+
ey7sAVq0CocAzwjvcAowfFQtlAGmoeJYBpCjI0dHjmtRLiHfREV2rBj7AAAAAElFTkSuQmCC
"
    } else {
	tablelist_ubuntu3_collapsedImg put "
R0lGODlhDQAOAMIFAAAAADw8PFRUVKOjo7y8vP///////////yH5BAEKAAcALAAAAAANAA4AAAMf
eLrcR84NEdkItJ6LNe/RBzZiRgaoeY4SK6kRpM1KAgA7
"
	tablelist_ubuntu3_expandedImg put "
R0lGODlhDQAOAMIFAAAAADY2NlRUVJeXl6+vr////////////yH5BAEKAAcALAAAAAANAA4AAAMd
eLrc/jA+Mqq9RInAOxfM5gVgI36QWKar5L5wlAAAOw==
"
	tablelist_ubuntu3_collapsedSelImg put "
R0lGODlhDQAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAANAA4AAAIZhI8JoRrczoNxUmer
vXI3/03R8oykuaBoAQA7
"
	tablelist_ubuntu3_expandedSelImg put "
R0lGODlhDQAOAKEBAAAAAP///////////yH5BAEKAAAALAAAAAANAA4AAAIUhI+py70Bo4RmTmRp
skw67YTi6BQAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::ubuntuMateTreeImgs
#------------------------------------------------------------------------------
proc tablelist::ubuntuMateTreeImgs {} {
    foreach mode {collapsed expanded collapsedSel expandedSel
		  collapsedAct expandedAct collapsedSelAct expandedSelAct} {
	variable ubuntuMate_${mode}Img \
		 [image create photo tablelist_ubuntuMate_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_ubuntuMate_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAICAYAAAA1BOUGAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAADNJREFUGFdj+P//P04MIRgYRNElwOJggoEhBoiT8EkeRleALgnCRrgkcerEaScW
1/5nAAAEbX5FmgjJygAAAABJRU5ErkJggg==
"
	tablelist_ubuntuMate_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAICAYAAAA1BOUGAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAADxJREFUGFdj+P//P06MVRCGsQrCMAgEAHEGGg6ASUoA8WogPgzFILYEWBKqAqYA
LgGXRFIAl0CRxMT/GQDUC3iRKcgrYgAAAABJRU5ErkJggg==
"
	tablelist_ubuntuMate_collapsedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAICAYAAAA1BOUGAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAADRJREFUGFdj+P//P04MY8ggC8IwjFEGxHUwQRhGlgQBFAXokiDgAMRYJXHqxGkn
Ftf+ZwAAuNGwE9a6YwIAAAAASUVORK5CYII=
"
	tablelist_ubuntuMate_expandedSelImg put "
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAICAYAAAA1BOUGAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAD5JREFUGFdj+P//P06MVRCGsQrCMIgoA+LJaBgkBpY0AeKHQAwDIDZIDG4sTAFc
AoRhkjAFcAkQRpZEw/8ZACqWsUulTWk4AAAAAElFTkSuQmCC
"
	tablelist_ubuntuMate_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAICAYAAAA1BOUGAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAADNJREFUGFdj+P//P04MIRgYRNElwOJggoEhBoiT8EkeRleALgnCRrgkcerEaScW
1/5nAAAEbX5FmgjJygAAAABJRU5ErkJggg==
"
	tablelist_ubuntuMate_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAICAYAAAA1BOUGAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAADxJREFUGFdj+P//P06MVRCGsQrCMAgEAHEGGg6ASUoA8WogPgzFILYEWBKqAqYA
LgGXRFIAl0CRxMT/GQDUC3iRKcgrYgAAAABJRU5ErkJggg==
"
	tablelist_ubuntuMate_collapsedSelActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAICAYAAAA1BOUGAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAADNJREFUGFdj+P//P04MIRgYRNElwOJggoEhBoiT8EkeRleALgnCRrgkcerEaScW
1/5nAAAEbX5FmgjJygAAAABJRU5ErkJggg==
"
	tablelist_ubuntuMate_expandedSelActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAcAAAAICAYAAAA1BOUGAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAADxJREFUGFdj+P//P06MVRCGsQrCMAgEAHEGGg6ASUoA8WogPgzFILYEWBKqAqYA
LgGXRFIAl0CRxMT/GQDUC3iRKcgrYgAAAABJRU5ErkJggg==
"
    } else {
	tablelist_ubuntuMate_collapsedImg put "
R0lGODlhBwAIAMIFAAAAADw8PJ2dnaOjo83Nzf///////////yH5BAEKAAcALAAAAAAHAAgAAAMO
eLrcIy7ANUIgVLLXegIAOw==
"
	tablelist_ubuntuMate_expandedImg put "
R0lGODlhBwAIAMIFAAAAADw8PFRUVJeXl6+vr////////////yH5BAEKAAcALAAAAAAHAAgAAAMO
eLrcTiMOokQIgons+koAOw==
"
	tablelist_ubuntuMate_collapsedSelImg put "
R0lGODlhBwAIAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAHAAgAAAIMhG+BqRjvXgMyrmkK
ADs=
"
	tablelist_ubuntuMate_expandedSelImg put "
R0lGODlhBwAIAKEBAAAAAP///////////yH5BAEKAAAALAAAAAAHAAgAAAIKhI+pwW0dEFMUFQA7
"
	tablelist_ubuntuMate_collapsedActImg put "
R0lGODlhBwAIAMIFAAAAADw8PJ2dnaOjo83Nzf///////////yH5BAEKAAcALAAAAAAHAAgAAAMO
eLrcIy7ANUIgVLLXegIAOw==
"
	tablelist_ubuntuMate_expandedActImg put "
R0lGODlhBwAIAMIFAAAAADw8PFRUVJeXl6+vr////////////yH5BAEKAAcALAAAAAAHAAgAAAMO
eLrcTiMOokQIgons+koAOw==
"
	tablelist_ubuntuMate_collapsedSelActImg put "
R0lGODlhBwAIAMIFAAAAADw8PJ2dnaOjo83Nzf///////////yH5BAEKAAcALAAAAAAHAAgAAAMO
eLrcIy7ANUIgVLLXegIAOw==
"
	tablelist_ubuntuMate_expandedSelActImg put "
R0lGODlhBwAIAMIFAAAAADw8PFRUVJeXl6+vr////////////yH5BAEKAAcALAAAAAAHAAgAAAMO
eLrcTiMOokQIgons+koAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::vistaAeroTreeImgs
#------------------------------------------------------------------------------
proc tablelist::vistaAeroTreeImgs {{treeStyle "vistaAero"}} {
    variable scalingpct
    vistaAeroTreeImgs_$scalingpct $treeStyle
}

#------------------------------------------------------------------------------
# tablelist::vistaAeroTreeImgs_100
#------------------------------------------------------------------------------
proc tablelist::vistaAeroTreeImgs_100 {{treeStyle "vistaAero"}} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_${treeStyle}_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAOCAYAAAAWo42rAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAZElE
QVQoU2P4//8/A1GApgotgZgbwsQCkBRGAHE4EAuDeegATaEoEKcAsTRIAAUgK4SyQSbmA7EqiAMH
6AqhfAkgrgViQRAHDLCYKATE+E0EYhEgJuxGICbK10SHI35AnEIGBgDfPzypQe1LowAAAABJRU5E
rkJggg==
"
	tablelist_${treeStyle}_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAOCAYAAAAWo42rAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAASklE
QVQoU2P4//8/A1Fg8Cl0BOJyCBMKsCgEKboCxDfBPBhAUwhWFBERARLEqRCuCJ9CFEX4FIIcDpJA
xpVAjABYPIMdDJRCBgYA0sVCxaUivcEAAAAASUVORK5CYII=
"
	tablelist_${treeStyle}_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAOCAYAAAAWo42rAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAY0lE
QVQoU2P4//8/A1GAdgpljnyfAsSGYA42gKTwExBfB2JnsAA6QFNYAMQvgTgSLIgMkBWC2EA6CYi/
gWiwBAygK4QqTgfi/0CsAZYEAbJMBGLi3AjERPmauHAkCIhTyMAAAJhFf793qI06AAAAAElFTkSu
QmCC
"
	tablelist_${treeStyle}_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAAoAAAAOCAYAAAAWo42rAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAARklE
QVQoU2P4//8/A1FgkCmUOfK9Eog3QrkQgK4Qqug3EKNKICuEKWq6//s/ToXIinAqRFeET+FGkAQa
xu8ZnGCgFDIwAAAYyHMZpMy2ogAAAABJRU5ErkJggg==
"
    } else {
	tablelist_${treeStyle}_collapsedImg put "
R0lGODlhCgAOAMIHAAAAAIKCgpCQkJubm6enp6ioqMbGxv///yH5BAEKAAcALAAAAAAKAA4AAAMa
eLrc/szAQwokZzx8hONH0HDemG3WI03skwAAOw==
"
	tablelist_${treeStyle}_expandedImg put "
R0lGODlhCgAOAMIGAAAAACYmJisrK1hYWIaGhoiIiP///////yH5BAEKAAcALAAAAAAKAA4AAAMY
eLrc/jCeAkV4YtyWNR/gphRBGRBSqkoJADs=
"
	tablelist_${treeStyle}_collapsedActImg put "
R0lGODlhCgAOAMIGAAAAABzE9ybG9y/J9z/N+Hvc+v///////yH5BAEKAAcALAAAAAAKAA4AAAMa
eLrc/qzAIwgUZzxMHT9Bw30LpnnWI03skwAAOw==
"
	tablelist_${treeStyle}_expandedActImg put "
R0lGODlhCgAOAMIEAAAAAB3E92HW+YLf+////////////////yH5BAEKAAAALAAAAAAKAA4AAAMX
CLrc/jACAUN4YdyWNR/gpgiWRUloGiUAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::vistaAeroTreeImgs_125
#------------------------------------------------------------------------------
proc tablelist::vistaAeroTreeImgs_125 {{treeStyle "vistaAero"}} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_${treeStyle}_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAQCAYAAADNo/U5AAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwQAADsEBuJFr7QAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAfElE
QVQ4T6XSSwqAMAwE0NygYBUP4M4jeBK37l269upx0AgZKdag8NCZNogfUdWwYllTLGs4iEyQfFfC
QWQ2ne+fOFwDGRbo/ZrHAUN2bmCFwa/fONiQXSfYYPR7zjUKbshyCztk6in8uROO2DNB/O2Z0HeK
/xFfFct3Kgd7BgT8X0rnFQAAAABJRU5ErkJggg==
"
	tablelist_${treeStyle}_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAQCAYAAADNo/U5AAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAX0lE
QVQ4T5WLwQ3AIAzEWIWF+GcUBuwQnSaECqQqOTiI5Ed8clLVa6BkQMmAkgHlxC4bJXgvJiN4jDds
XnxyBCLSHx79g6PIBzRCwTZaBSwqfVxQYXQLlAwoGVDu0dQApYwcjGzIaS0AAAAASUVORK5CYII=
"
	tablelist_${treeStyle}_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAQCAYAAADNo/U5AAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwQAADsEBuJFr7QAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAjElE
QVQ4T5XSzQ1AQBAFYIVI1KAGFTi67tVFFSpQkj5cXDTAcbxJduWNbNg5fNl9wyN+KhFxyw7/ZId/
TKjXa4GWZzkmoLDDBh3P30yIpREOGPgYM0FLcQ1wwsTHExNSKe6HZr0E68znKBO4FHMPWgw8fzaK
S9j77qRXhvJnAv/bA/d38v8RpbLDb1LdInxaO2Da/xgAAAAASUVORK5CYII=
"
	tablelist_${treeStyle}_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAAA0AAAAQCAYAAADNo/U5AAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAZUlE
QVQ4T5WQsQ2AMAwEMwhTMVI2yg7swQa0FCmMkbAURx+/Ka74s65xEZHfQMmAkgElA0pjO+5dabN3
Y+QLLkWnv7lhWFDPLqloDFLRHNAIBWG0CljU3uOC/MsjoGRAyYAyRsoDbx1o4rZ56f0AAAAASUVO
RK5CYII=
"
    } else {
	tablelist_${treeStyle}_collapsedImg put "
R0lGODlhDQAQAMIHAAAAAIGBgYuLi5OTk56enqenp8XFxf///yH5BAEKAAcALAAAAAANABAAAAMg
eLrc/tCZuEqh5xJ6z4jdIUDhETzhiCofeWxg+UxYjSUAOw==
"
	tablelist_${treeStyle}_expandedImg put "
R0lGODlhDQAQAMIGAAAAACYmJjo6OllZWYaGhrGxsf///////yH5BAEKAAcALAAAAAANABAAAAMe
eLrc/jDKVqYIUgwM9e5DyDWe6JQmUwRsS0xwLDsJADs=
"
	tablelist_${treeStyle}_collapsedActImg put "
R0lGODlhDQAQAMIHAAAAAB7E9yTG9y/J9zTK9zjL+Hvc+v///yH5BAEKAAcALAAAAAANABAAAAMg
eLrc/tCZuEihh5xB9RGRdwSQOD4iiSpguXUXNWE0lgAAOw==
"
	tablelist_${treeStyle}_expandedActImg put "
R0lGODlhDQAQAMIFAAAAABzE9yvH92HW+YLf+////////////yH5BAEKAAcALAAAAAANABAAAAMe
eLrc/jDKNqYIUhAM9e5EyDWe6JQmMwRsW01wLDcJADs=
"
    }
}

#------------------------------------------------------------------------------
# tablelist::vistaAeroTreeImgs_150
#------------------------------------------------------------------------------
proc tablelist::vistaAeroTreeImgs_150 {{treeStyle "vistaAero"}} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_${treeStyle}_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAkklE
QVQ4T63Tqw6AMAwF0GocjwSBIdlv8B84LBKD4evHHVS0S3ltLDmB20JDYJD3PotZ/MIsfqED0QCl
rD3RgWhkjazf0eG8uYIJWtm7ogMG8LGGGTrZt+jAA/g8DFmgl9fEdBADOIchKzhZl3SIBnDNwQZF
3Dv6Kvz5BFjp7wAr/StA3j5gyTsx719IYRbf87QDkkXd7AZZ8UwAAAAASUVORK5CYII=
"
	tablelist_${treeStyle}_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAaklE
QVQ4T6WM0QnAIAwF3a4zOIl0z/50mjSBBkSukkeF+/D0XjOzX6BUQKmAUgGlAsoZP4cz6C1Ambzx
5dz0HqAMMu69x0UbmGN5YI2lAYrLA19xaWAXB5WBEZ82nGuYoFRAqYBSAWUdaw84XP55BTs9TwAA
AABJRU5ErkJggg==
"
	tablelist_${treeStyle}_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAkklE
QVQ4T6WTuw2AMAxEMwjLsAItJQ0l27AQ81BQQGlsyZF8kSG/4sncmTtFIgQi6sI1a3DNGkAMx7Mz
k/VygODwxZzMbP0/QGjBqnOxuy9ASFCnlNwy7d4DRCzQ51iy2XdSQNgC1dkSEGmBelJCzJjuBBBp
gYbbTlASFkDEAhOu/woabr8HTNdN7PsXWnDNcii8/8FGqvnrvTkAAAAASUVORK5CYII=
"
	tablelist_${treeStyle}_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAASCAYAAABSO15qAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwgAADsIBFShKgAAAABp0RVh0U29mdHdhcmUAUGFpbnQuTkVUIHYzLjUuMTAw9HKhAAAAcElE
QVQ4T6WSsQ2AIBQFGcQh7e3ciB1cwziGBcX3k0hCzEn+0+IKDu5VJDP7BUoFlAooFVAqoOyZtnN2
Mt1VUDbuuDh+5DcoKy1e9mLyQB+vhzjwjKUBisMDb3FoYBRHB3J9NODbP4iAUgGlAso4li4fLlnw
8CctEgAAAABJRU5ErkJggg==
"
    } else {
	tablelist_${treeStyle}_collapsedImg put "
R0lGODlhEAASAOMIAAAAAIaGhouLi5CQkJiYmKGhoaioqMPDw///////////////////////////
/////yH5BAEKAAAALAAAAAAQABIAAAQrEMhJq70426OrMd0EFiEAAkR4AkO3AoL2AkH2xvbUylLq
AiTVLMMpGY+ACAA7
"
	tablelist_${treeStyle}_expandedImg put "
R0lGODlhEAASAMIGAAAAACYmJisrK1lZWYaGhoiIiP///////yH5BAEKAAcALAAAAAAQABIAAAMj
eLrc/jDKSWepR4Qqxp6dBw7kB4VlhKbPyjZFIM8Bgd14DiUAOw==
"
	tablelist_${treeStyle}_collapsedActImg put "
R0lGODlhEAASAMIFAAAAABzE9ybG9yvH93jc+v///////////yH5BAEKAAcALAAAAAAQABIAAAMj
eLrc/jA6IpsYdYmzc+8SCELj6JhBVIZa9XlcxmEyJd/4kQAAOw==
"
	tablelist_${treeStyle}_expandedActImg put "
R0lGODlhEAASAMIFAAAAAB3E92HW+Xvd+4Lf+////////////yH5BAEKAAcALAAAAAAQABIAAAMj
eLrc/jDKSaeoJ4Qaxp4d8UWhKJUmhKbOyjKCJmsXZt/4kwAAOw==
"
    }
}

#------------------------------------------------------------------------------
# tablelist::vistaAeroTreeImgs_200
#------------------------------------------------------------------------------
proc tablelist::vistaAeroTreeImgs_200 {{treeStyle "vistaAero"}} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_${treeStyle}_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAASCAYAAAC0EpUuAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwAAADsABataJCQAAAAd0SU1FB98IEBUWORalREAAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAJNJREFUOE+10zsKgDAQBNCt7fyAhY2Qa3gPO1tLGxtPHye4RdgNJpI1
8DBOwiBqyHtvLhnWSoa1dEC0QCvzL3RAtLJBrpXSwVPYwQajXC+hA5TytYcdJrknRwdcyvNQfMAc
78nRQVTK96H4BBfnb3QgSjlzcEEj11J08PeTYti+Uwzbrw/2/ykzPVH2Z99CMqzj6QYGRertj0pe
+AAAAABJRU5ErkJggg==
"
	tablelist_${treeStyle}_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAASCAYAAAC0EpUuAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwAAADsABataJCQAAAAd0SU1FB98IEBUeBx8d0+MAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAGtJREFUOE+tzMEJwCAQRFG7Sw1biaTPXFLNxoUIi3w9OArv4Ii/uPtx
OKpwVOGowlGF46idq6n0RnDM/uDTvPROcOx60Mziokdz8Eh0DMpRCkrRWXA7ugqG3WiNjwt3/riC
owpHFY4qHDVePsGgC4kbm9dDAAAAAElFTkSuQmCC
"
	tablelist_${treeStyle}_collapsedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAASCAYAAAC0EpUuAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwAAADsABataJCQAAAAd0SU1FB98IEBUVIS7kj9UAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAJNJREFUOE+tkzEKgDAMRT2Il/EKro4ujt7GC3keBwcdYwIplPxAW5vh
UX0pj4J2IKJwXNmLK3sBMZ7vwczWtwCCgzdzMYud1QJCo5uuq53XAEJiukr4kdXuKQEiRfU5hfd8
TwkQeVTfm8MgbFSdhImZ7MwDhI1qMO6kf4ICiBTNgjFfX4Ox/ykTfqPi734EruyDhg9wSVOrXMoi
bgAAAABJRU5ErkJggg==
"
	tablelist_${treeStyle}_expandedActImg put "
iVBORw0KGgoAAAANSUhEUgAAABUAAAASCAYAAAC0EpUuAAAABGdBTUEAALGPC/xhBQAAAAlwSFlz
AAAOwAAADsABataJCQAAAAd0SU1FB98IEBUbEg+3w00AAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5F
VCB2My41LjEwMPRyoQAAAHJJREFUOE+t0rENgCAURVEGcUh7OzdiB9cwjmFB8cVEEvJzpeD94hQ+
5FYkMwuHowpHFY4qHFU4estxr1WmM4Jj7wuWqn7yPx6OTQtuZ7GQaB/cr4CoD8pRCkrRv+B0dBRU
ovm9OBD3TmfgqMJRhaPG0gNGBmbxSYGdJwAAAABJRU5ErkJggg==
"
    } else {
	tablelist_${treeStyle}_collapsedImg put "
R0lGODlhFQASAOMIAAAAAIaGhouLi5CQkJiYmKGhoaioqMPDw///////////////////////////
/////yH5BAEKAAAALAAAAAAVABIAAAQvEMhJq7046w0Ox4bxWWIxUiJAnFIKDKwLCKcMBKNM5xNc
S6sYwMQChIoSD3LJjAAAOw==
"
	tablelist_${treeStyle}_expandedImg put "
R0lGODlhFQASAMIGAAAAACYmJisrK1lZWYaGhoiIiP///////yH5BAEKAAcALAAAAAAVABIAAAMl
eLrc/jDKSauV5TIRtBJDp4HhOJxiRaLWylLuiwV0HRBeru97AgA7
"
	tablelist_${treeStyle}_collapsedActImg put "
R0lGODlhFQASAMIFAAAAABzE9ybG9yvH93jc+v///////////yH5BAEKAAcALAAAAAAVABIAAAMn
eLrc/jDKeQiFYlwnTt/L94HjeJnmlAYbSoagp6RUR9darFh67y8JADs=
"
	tablelist_${treeStyle}_expandedActImg put "
R0lGODlhFQASAMIFAAAAAB3E92HW+Xvd+4Lf+////////////yH5BAEKAAcALAAAAAAVABIAAAMl
eLrc/jDKSauV4rIQtApDp4GEaJHlhabVyk7uGwlczWVeru96AgA7
"
    }
}

#------------------------------------------------------------------------------
# tablelist::vistaClassicTreeImgs
#------------------------------------------------------------------------------
proc tablelist::vistaClassicTreeImgs {{treeStyle "vistaClassic"}} {
    variable scalingpct
    vistaClassicTreeImgs_$scalingpct $treeStyle
}

#------------------------------------------------------------------------------
# tablelist::vistaClassicTreeImgs_100
#------------------------------------------------------------------------------
proc tablelist::vistaClassicTreeImgs_100 {{treeStyle "vistaClassic"}} {
    foreach mode {collapsed expanded} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    tablelist_${treeStyle}_collapsedImg put "
R0lGODlhCwAOAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAALAA4AAAIjnI+pm+H/TBC0iiAr
qHhMulHdBJTllYFcKoSoZ60eBDH2UgAAOw==
"
    tablelist_${treeStyle}_expandedImg put "
R0lGODlhCwAOAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAALAA4AAAIfnI+pm+H/TBC0iiBt
xWPqmwGiCHZf6Wlcaq0QxMRLAQA7
"
}

#------------------------------------------------------------------------------
# tablelist::vistaClassicTreeImgs_125
#------------------------------------------------------------------------------
proc tablelist::vistaClassicTreeImgs_125 {{treeStyle "vistaClassic"}} {
    foreach mode {collapsed expanded} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    tablelist_${treeStyle}_collapsedImg put "
R0lGODlhDgAQAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAOABAAAAIrnI+pyxoPYzhB2Hun
qRdgPXCWl1EYaYEVwLaeen5mJ29xaWN1KEnNDxwUAAA7
"
    tablelist_${treeStyle}_expandedImg put "
R0lGODlhDgAQAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAOABAAAAIonI+pyxoPYzhB2Hun
qRjrwXXWF4qkAKQqIJziSL3wJrexTEpSw/dDAQA7
"
}

#------------------------------------------------------------------------------
# tablelist::vistaClassicTreeImgs_150
#------------------------------------------------------------------------------
proc tablelist::vistaClassicTreeImgs_150 {{treeStyle "vistaClassic"}} {
    foreach mode {collapsed expanded} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    tablelist_${treeStyle}_collapsedImg put "
R0lGODlhEQASAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAARABIAAAI3nI+py60Bo4woiIuz
CFUDzR1W9mWhMWIldg7ptV6tBdS2vXUkqKu86PmhgqaehlWZKFuOpnNQAAA7
"
    tablelist_${treeStyle}_expandedImg put "
R0lGODlhEQASAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAARABIAAAIxnI+py60Bo4woiIuz
CFV7flheBhrieJXDiaoWAMfx1qFpbbv2He50v3NNhiqH8TgoAAA7
"
}

#------------------------------------------------------------------------------
# tablelist::vistaClassicTreeImgs_200
#------------------------------------------------------------------------------
proc tablelist::vistaClassicTreeImgs_200 {{treeStyle "vistaClassic"}} {
    foreach mode {collapsed expanded} {
	variable ${treeStyle}_${mode}Img \
		 [image create photo tablelist_${treeStyle}_${mode}Img]
    }

    tablelist_${treeStyle}_collapsedImg put "
R0lGODlhFwASAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAXABIAAAJHnI+pFu0Pmwqi2ovD
xPzqRGHAyH1IeI1AuYlk1qav16q2XZlHePd53cMJdAyOigUyAlawpItJc8qgFuIA1Wmesh1r5PtQ
FAAAOw==
"
    tablelist_${treeStyle}_expandedImg put "
R0lGODlhFwASAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAXABIAAAI+nI+pFu0Pmwqi2ovD
xPzqRHXdh4Ritp0oqK5lBcTyDFTkEdK6neo0z2pZbgzhMGUkDkxCJbPlNAJLkapDUQAAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::win7AeroTreeImgs
#------------------------------------------------------------------------------
proc tablelist::win7AeroTreeImgs {} {
    vistaAeroTreeImgs "win7Aero"
}

#------------------------------------------------------------------------------
# tablelist::win7ClassicTreeImgs
#------------------------------------------------------------------------------
proc tablelist::win7ClassicTreeImgs {} {
    vistaClassicTreeImgs "win7Classic"
}

#------------------------------------------------------------------------------
# tablelist::win10TreeImgs
#------------------------------------------------------------------------------
proc tablelist::win10TreeImgs {} {
    variable scalingpct
    win10TreeImgs_$scalingpct
}

#------------------------------------------------------------------------------
# tablelist::win10TreeImgs_100
#------------------------------------------------------------------------------
proc tablelist::win10TreeImgs_100 {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable win10_${mode}Img \
		 [image create photo tablelist_win10_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_win10_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAAKCAYAAAC9vt6cAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAExJREFUKFNj+P//P0UYwWBg0AFiB2RJYjCCAdQMxJGkGoLKIcMQTAESDcEuyMAQ
DDVEB5s8MsYUoMQFpGoGYQSDDM0gjGCQlQ7+MwAAiH+aQTbAbFoAAAAASUVORK5CYII=
"
	tablelist_win10_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABAAAAAKCAYAAAC9vt6cAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAFRJREFUKFNj+P//P0UYqyApGATigbgDh2QHSB6bHAzDFO0H0WgSWMXRMYRAU4zO
x4cRDKgmHx8fEIcozSCMyiHBZhjGFCAQaOgYqyApGKsg8fg/AwClVaMkbFpt/wAAAABJRU5ErkJg
gg==
"
    } else {
	tablelist_win10_collapsedImg put "
R0lGODlhEAAKAMIGAAAAAKampqysrL+/v9LS0tTU1P///////yH5BAEKAAcALAAAAAAQAAoAAAMZ
eLrcS8PJM0KcrV68NGdCUHyURXof+kFkAgA7
"
	tablelist_win10_expandedImg put "
R0lGODlhEAAKAMIHAAAAAEBAQExMTHd3d5+fn6CgoKGhof///yH5BAEKAAcALAAAAAAQAAoAAAMb
eLrc/oyMNsobYSqsHT8fBAZCJi7hqRhq6z4JADs=
"
    }

    tablelist_win10_collapsedActImg put "
R0lGODlhEAAKAMIGAAAAAE7Q+VjS+Xra+5vh/Jri/P///////yH5BAEKAAcALAAAAAAQAAoAAAMZ
eLrcW8PJM0KcrV68NGdCQHyURXof+kFkAgA7
"
    tablelist_win10_expandedActImg put "
R0lGODlhEAAKAMIGAAAAABzE9yjH+FbS+YDb+4Lc+////////yH5BAEKAAcALAAAAAAQAAoAAAMb
eLrc/oyMNsobYSqsHT8fBAZCJi7hqVhq6zoJADs=
"
}

#------------------------------------------------------------------------------
# tablelist::win10TreeImgs_125
#------------------------------------------------------------------------------
proc tablelist::win10TreeImgs_125 {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable win10_${mode}Img \
		 [image create photo tablelist_win10_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_win10_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAABoAAAAMCAYAAAB8xa1IAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAF1JREFUOE+9lMEJwDAMA71QJ+gG3aD7D+JK0EKN9QlYCdxDl8eRTyIzt1BHxAGu
v5uiDkTA7Yh1YYppaYhJSaZjUn68IXKq+xWkJDj+F01HSBeGCKnDFCF12H6GjAdLF1EmW/vAagAA
AABJRU5ErkJggg==
"
	tablelist_win10_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAABoAAAAMCAYAAAB8xa1IAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAGNJREFUOE+9j4EJwCAMBDNqN3GUjuJosY8Eqf0UqUmFU3MfIoqq/gKVGVCZAdZx
cbLQQI4+lq1iQypOp+E1X6VvzjDPf2FcpqFzvcu9GMONkEfAUwT/xOBSpDC/A5UZUBmPSgPj7VvG
j4QeDgAAAABJRU5ErkJggg==
"
    } else {
	tablelist_win10_collapsedImg put "
R0lGODlhGgAMAMIFAAAAAKamprW1tcTExNLS0v///////////yH5BAEKAAcALAAAAAAaAAwAAAMi
eLrc/ocISJ8Is2p1867dp4UiFQRDaWGqQ7bLCx/yLM1KAgA7
"
	tablelist_win10_expandedImg put "
R0lGODlhGgAMAMIHAAAAAEBAQEFBQWBgYICAgJ+fn6CgoP///yH5BAEKAAcALAAAAAAaAAwAAAMi
eLrc/jDKSct4w9A1wmXdtx0h543gWaKpcLLNCjfEbN9oAgA7
"
    }

    tablelist_win10_collapsedActImg put "
R0lGODlhGgAMAMIGAAAAAE7Q+WfV+mjV+oHc+5ri/P///////yH5BAEKAAcALAAAAAAaAAwAAAMj
eLrc/qcISJ8Is2p1867X8GnhWAUBYVrY6nRuA8fLTCvSfSQAOw==
"
    tablelist_win10_expandedActImg put "
R0lGODlhGgAMAMIGAAAAABzE9z7M+F/U+oDb+4Hc+////////yH5BAEKAAcALAAAAAAaAAwAAAMi
eLrc/jDKSYl4otAlwmXdtx0h543gWaJpcLLNCjfDbN9oAgA7
"
}

#------------------------------------------------------------------------------
# tablelist::win10TreeImgs_150
#------------------------------------------------------------------------------
proc tablelist::win10TreeImgs_150 {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable win10_${mode}Img \
		 [image create photo tablelist_win10_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_win10_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAAB8AAAAQCAYAAADu+KTsAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAIZJREFUSEvNlbENgDAMBD0IDQNQswQLsP8gxi8R5OCvkOMQ6YocSOc0iajqNLgU
WZjPJgqRzTiN/f0tm35jJ77DjaEDRGFBFx86AJdFA1AJEHTxIQNQ2UDQxdMHoNJj63BxsLL/vkBl
w9ackyPkoulhwGVBGERRFAb95gc33Jy7/ZElr5rKBVezH+eTfDdNAAAAAElFTkSuQmCC
"
	tablelist_win10_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAAB8AAAAQCAYAAADu+KTsAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAJVJREFUSEvFkNkNgCAQRLcvCrAIfqzC9iwNmXiwukPiASvJ43i7YVBJKf0GlV5Q
6UXZiARdqHG37w7rJDJm5sx0bdCgvvWNrP4UjLBduEMfAK96wOc/sE724tMDcFY1U39L2VQCsCp3
+BacD5egGCNkl2Bghf3SLsGAS/uA5sGASoDAnsGAyp08BuZbQaUXVHpBpQ9JFsLONZHqquN4AAAA
AElFTkSuQmCC
"
    } else {
	tablelist_win10_collapsedImg put "
R0lGODlhHwAQAOMIAAAAAKamprOzs8jIyNLS0t7e3uPj4+Tk5P//////////////////////////
/////yH5BAEKAAAALAAAAAAfABAAAAQ3EMhJq7344M0lCUMnUkZghuM4mGCqsqjLrafc0a29CWyh
X7jYbxIcVopGIiw5KdWYk48QCtBAIwA7
"
	tablelist_win10_expandedImg put "
R0lGODlhHwAQAOMJAAAAAEBAQFtbW4mJiZ+fn6CgoLi4uMTExMXFxf//////////////////////
/////yH5BAEKAA8ALAAAAAAfABAAAAQ58MlJq7046807RRnoUUQwXENQjNIRvCeVvgf7zOaEx/Z+
vzmbDigA8oQSHAxp8TGbwafFIK1ar9IIADs=
"
    }

    tablelist_win10_collapsedActImg put "
R0lGODlhHwAQAMIHAAAAAE7Q+WTV+oje+5ri/K3m/bbo/f///yH5BAEKAAcALAAAAAAfABAAAAM0
eLrc/tDASRUJo2pmgs/bNnhYKJKgSY2fWrGlOwlkIT9wei/53vQ+Hiq46LSIi4sOeZAgEwA7
"
    tablelist_win10_expandedActImg put "
R0lGODlhHwAQAOMJAAAAABzE9zjK+GnW+oDb+4Hc+5rh/Kfl/ajl/f//////////////////////
/////yH5BAEKAA8ALAAAAAAfABAAAAQ58MlJq7046807RRnoUUQwXENQjNIRvCeVvgf7zOaEx/Z+
vzmbDigA8oQSHAxp8TGbwafFIK1ar9IIADs=
"
}

#------------------------------------------------------------------------------
# tablelist::win10TreeImgs_200
#------------------------------------------------------------------------------
proc tablelist::win10TreeImgs_200 {} {
    foreach mode {collapsed expanded collapsedAct expandedAct} {
	variable win10_${mode}Img \
		 [image create photo tablelist_win10_${mode}Img]
    }

    variable pngSupported
    if {$pngSupported} {
	tablelist_win10_collapsedImg put "
iVBORw0KGgoAAAANSUhEUgAAACgAAAASCAYAAAApH5ymAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAJJJREFUSEvV1rENwCAMRFEGykDZfxGHKyyh45fYIpFe8+PiSkZEoPk91LtxnOOm
V+h/pz0s45LfdOJoA4XuOmAUHyh0Vw1j8oFCd5Uwrnyg0F0VjM4HCt1VwEh8oNDdaRiJjxO6Ow2j
82FCdxUwrnyY0F0VjMmHCd1Vwig+TOiuGsdLxskefvJYuPe5lTSSeq8YH+NamKxWvX/LAAAAAElF
TkSuQmCC
"
	tablelist_win10_expandedImg put "
iVBORw0KGgoAAAANSUhEUgAAACgAAAASCAYAAAApH5ymAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAadEVYdFNvZnR3YXJlAFBhaW50Lk5FVCB2My41
LjEwMPRyoQAAAJFJREFUSEvNzgEKgCAMhWFv2k272nKItdZvWDRa8Ik9J74iIqlhmAmGmRybUhZ7
MOPNnafaUh+qVuUHRvp8FVpSv71cR4OWn6/CSrbl+uCwpJ9TNPeVYzPxsD9XfuZr55+bAj5X9m6U
awBFiL8XhUMoZNGdKBgqX6qj2UgYdn+XUxhaf5ZTGGaCYSYYZoJhHlI2JrC2jqb+LJ4AAAAASUVO
RK5CYII=
"
    } else {
	tablelist_win10_collapsedImg put "
R0lGODlhKAASAMIHAAAAAKampqenp6ioqNLS0tPT09TU1P///yH5BAEKAAcALAAAAAAoABIAAANB
eLq1/jDKV4KYOEMT+tUgJnRWaEajd67LQH7s6ZLxOne1TAZ5ePO9zC8o3BExN9gRklxKUiUnpKKS
RghR61W7SAAAOw==
"
	tablelist_win10_expandedImg put "
R0lGODlhKAASAMIGAAAAAEBAQEJCQp+fn6CgoKGhof///////yH5BAEKAAcALAAAAAAoABIAAAM/
eLrc/jDKSau9qlCN4QiCJARE5xBBGj5jyplLCzryCjM1ns43va+5HusXFA53KqMIaVNCWk3nMyqt
Wq/YrCUBADs=
"
    }

    tablelist_win10_collapsedActImg put "
R0lGODlhKAASAMIFAAAAAE7Q+VHQ+Zrh/Jri/P///////////yH5BAEKAAcALAAAAAAoABIAAAM9
eLqz/jDKN4KYOMMarP6Z0HlgCYndZa4K2rGsG8CrTJv2/eU6xveSH/A0mg2DI9WRmFpGOCQnhBCV
Tq2LBAA7
"
    tablelist_win10_expandedActImg put "
R0lGODlhKAASAMIEAAAAAB3E94Db+4Hc+////////////////yH5BAEKAAAALAAAAAAoABIAAAM6
CLrc/jDKSau9alCNoQiBBHIdM4AghAZkqaxhA7vOvNi0vL57/sA4Xw0YE6qCxh8qSUkxn9CodFpK
AAA7
"
}

#------------------------------------------------------------------------------
# tablelist::winnativeTreeImgs
#------------------------------------------------------------------------------
proc tablelist::winnativeTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable winnative_${mode}Img \
		 [image create photo tablelist_winnative_${mode}Img]
    }

    tablelist_winnative_collapsedImg put "
R0lGODlhDgAOAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAOAA4AAAIlnI+pyxoPYQqiWhGm
BTYjWnGVd1DAeWJa2K2CqH5X+0VRg+dHAQA7
"
    tablelist_winnative_expandedImg put "
R0lGODlhDgAOAKECAAAAAICAgP///////yH5BAEKAAMALAAAAAAOAA4AAAIinI+pyxoPYQqiWhHm
tRnRjWnAOIYeaB7f1qloa0RyQ9dHAQA7
"
}

#------------------------------------------------------------------------------
# tablelist::winxpBlueTreeImgs
#------------------------------------------------------------------------------
proc tablelist::winxpBlueTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable winxpBlue_${mode}Img \
		 [image create photo tablelist_winxpBlue_${mode}Img]
    }

    tablelist_winxpBlue_collapsedImg put "
R0lGODlhDgAOAIQeAAAAAHiYtbDC08C3psG4p8K4qMO6qsa+rs/Iu9LMv9LMwNbRxtjTydvWzNzY
z9/b0uPg2eTh2eXh2urp4+3t5/Hw6/Dw7PLy7vX18ff28/b29Pf39fz8+vz8+////////yH5BAEK
AB8ALAAAAAAOAA4AAAVJ4CeOZGmeqCkEbBsIZeDNtBfEXQ50XHaTgc1GA9BUJL9RAANoNh9JUeBi
oQAmkEb0E4g4GICFArENJA4FAmFg2K5cLFhqTheFAAA7
"
    tablelist_winxpBlue_expandedImg put "
R0lGODlhDgAOAKUgAAAAAHiYtbDC08C3psG4p8K4qMO6qsa+rs/Iu9LMv9LMwNbRxtfSx9jTydvW
zNzYz9/b0uPg2eTh2eXh2urp4+zr5u3t5/Hw6/Dw7PLy7vX18ff28/b29Pf39fz8+vz8+///////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKAD8ALAAAAAAOAA4AAAZNwJ9w
SCwaj0ijIMBsBgTFAGhKBQWin2zWs7kSA50OZ3yZeIcBDWC9hpyFgQzGUqFEHO9fQPJoMBYKCHkB
CQcFBAQDBnlLTkxQSZGSQkEAOw==
"
}

#------------------------------------------------------------------------------
# tablelist::winxpOliveTreeImgs
#------------------------------------------------------------------------------
proc tablelist::winxpOliveTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable winxpOlive_${mode}Img \
		 [image create photo tablelist_winxpOlive_${mode}Img]
    }

    tablelist_winxpOlive_collapsedImg put "
R0lGODlhDgAOAIQdAAAAAI6ZfcC3psG4p8K4qMO6qsa+rs/Iu9LMv9LMwNbRxtjTydvWzNzYz9/b
0uPg2eTh2eXh2urp4+3t5/Hw6/Dw7PLy7vX18ff28/b29Pf39fz8+vz8+////////////yH5BAEK
AB8ALAAAAAAOAA4AAAVF4CeOZGme6BmsbGAGXSx3LhlwOMBtWD0GGk0GkKFEfKLABcBkOpCfgKUy
AUgeDGgA0lgAFImDFmEgDAaCAjTaWqXecFIIADs=
"
    tablelist_winxpOlive_expandedImg put "
R0lGODlhDgAOAKUfAAAAAI6ZfcC3psG4p8K4qMO6qsa+rs/Iu9LMv9LMwNbRxtfSx9jTydvWzNzY
z9/b0uPg2eTh2eXh2urp4+zr5u3t5/Hw6/Dw7PLy7vX18ff28/b29Pf39fz8+vz8+///////////
////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////yH5BAEKACAALAAAAAAOAA4AAAZJQJBw
SCwaj8hjYMkMGAOfqPTjJAY8WGxHUx0GOJyN2CLpCgMZgFr9MIMCmEuFMoE03IGIg7FQJA54CAYE
AwMCBW5vTUtJjY5EQQA7
"
}

#------------------------------------------------------------------------------
# tablelist::winxpSilverTreeImgs
#------------------------------------------------------------------------------
proc tablelist::winxpSilverTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable winxpSilver_${mode}Img \
		 [image create photo tablelist_winxpSilver_${mode}Img]
    }

    tablelist_winxpSilver_collapsedImg put "
R0lGODlhDgAOAIQXAAAAAJSVosTO2MXP2cbO2svT3NPZ4tXb5Nnf5trg593i6d/l6uDm6+bq7ufr
7+zv8+/y9PLz9vT39/b3+ff4+vn6+v39/f///////////////////////////////////yH5BAEK
AB8ALAAAAAAOAA4AAAVD4CeOZGme6BmsbGAGVyxfLhlYOIBT9RhUFQqAEnH0RIEJYLlkHD8BSQQC
eDQUz0BjkQAgDobsoTAoCwhPaGuVartJIQA7
"
    tablelist_winxpSilver_expandedImg put "
R0lGODlhDgAOAIQYAAAAAJSVosTO2MXP2cbO2svT3NPZ4tXb5Nnf5trg593i6d/l6uDm6+bq7ufr
7+zv8+/x8+/y9PLz9vT39/b3+ff4+vn6+v39/f///////////////////////////////yH5BAEK
AB8ALAAAAAAOAA4AAAVC4CeOZGme6BmsbGAGWCxjLhlceF7VY2BZlaDEwRMFKIBkklH8BCaSCOTR
UDQDjUUigTgYrofCYCwgNJ2tVWrNJoUAADs=
"
}

#------------------------------------------------------------------------------
# tablelist::yuyoTreeImgs
#------------------------------------------------------------------------------
proc tablelist::yuyoTreeImgs {} {
    foreach mode {collapsed expanded} {
	variable yuyo_${mode}Img \
		 [image create photo tablelist_yuyo_${mode}Img]
    }

    tablelist_yuyo_collapsedImg put "
R0lGODlhDwAOAOMKAAAAAIiKhby9ur7AvMDBvsrMyd3e3eHi4OHi4f7+/v//////////////////
/////yH5BAEKAA8ALAAAAAAPAA4AAARA8MlJq72zjM1HqQWSKCSZIN80jORRJgM1lEpAxyptl7g0
E4Fg0KDoPWalHcmIJCmLMpZC8DKGpCYUqMNJYb6PCAA7
"
    tablelist_yuyo_expandedImg put "
R0lGODlhDwAOAOMIAAAAAIiKhb7AvMDBvsrMyd3e3eHi4f7+/v//////////////////////////
/////yH5BAEKAA8ALAAAAAAPAA4AAAQ58MlJq72TiM0FqYRxICR5GN8kjGV5CJTQzrA6t7UkD0Hf
F4jcQ3YjCYnFI2v2ooSWJhSow0lhro8IADs=
"
}

#------------------------------------------------------------------------------
# tablelist::createTreeImgs
#------------------------------------------------------------------------------
proc tablelist::createTreeImgs {treeStyle depth} {
    set baseWidth  [image width  tablelist_${treeStyle}_collapsedImg]
    set baseHeight [image height tablelist_${treeStyle}_collapsedImg]

    #
    # Get the width of the images to create for the specified depth and
    # the destination x coordinate for copying the base images into them
    #
    set width [expr {$depth * $baseWidth}]
    set x [expr {($depth - 1) * $baseWidth}]
    switch -regexp -- $treeStyle {
	^win10$ {
	    variable scalingpct
	    switch $scalingpct {
		100 { set factor -8 }
		125 { set factor -16 }
		150 { set factor -19 }
		200 { set factor -24 }
	    }
	}
	^(vistaAero|win7Aero)$ {
	    variable scalingpct
	    switch $scalingpct {
		100 { set factor  0 }
		125 { set factor -3 }
		150 { set factor -6 }
		200 { set factor -11 }
	    }
	}
	^(vistaClassic|win7Classic)$ {
	    variable scalingpct
	    switch $scalingpct {
		100 { set factor -1 }
		125 { set factor -4 }
		150 { set factor -7 }
		200 { set factor -13 }
	    }
	}
	^ubuntu$					{ set factor -2 }
	^(mate|mint2)$					{ set factor -1 }
	^(blueMenta|menta|mint|newWave|ubuntu2)$	{ set factor  1 }
	^(ubuntu3|ubuntuMate)$				{ set factor  2 }
	^plasti.+$					{ set factor  3 }
	^(adwaita|aqua|arc)$				{ set factor  4 }
	^(oxygen.|phase|winnative|winxp.+)$		{ set factor  5 }
	^(baghira|klearlooks)$				{ set factor  7 }
	default						{ set factor  0 }
    }
    set delta [expr {($depth - 1) * $factor}]
    incr width $delta
    incr x $delta

    foreach mode {indented collapsed expanded} {
	image create photo tablelist_${treeStyle}_${mode}Img$depth \
	    -width $width -height $baseHeight
    }

    foreach mode {collapsed expanded} {
	tablelist_${treeStyle}_${mode}Img$depth copy \
	    tablelist_${treeStyle}_${mode}Img -to $x 0

	foreach modif {Sel Act SelAct} {
	    variable ${treeStyle}_${mode}${modif}Img
	    if {[info exists ${treeStyle}_${mode}${modif}Img]} {
		image create photo \
		    tablelist_${treeStyle}_${mode}${modif}Img$depth \
		    -width $width -height $baseHeight
		tablelist_${treeStyle}_${mode}${modif}Img$depth copy \
		    tablelist_${treeStyle}_${mode}${modif}Img -to $x 0
	    }
	}
    }
}
#==============================================================================
# Contains the implementation of the tablelist move and movecolumn subcommands.
#
# Copyright (c) 2003-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#------------------------------------------------------------------------------
# tablelist::moveRow
#
# Processes the 1st form of the tablelist move subcommand.
#------------------------------------------------------------------------------
proc tablelist::moveRow {win source target} {
    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled) || $data(itemCount) == 0} {
	return ""
    }

    #
    # Adjust the indices to fit within the existing items and check them
    #
    if {$source > $data(lastRow)} {
	set source $data(lastRow)
    } elseif {$source < 0} {
	set source 0
    }
    if {$target > $data(itemCount)} {
	set target $data(itemCount)
    } elseif {$target < 0} {
	set target 0
    }

    set sourceItem [lindex $data(itemList) $source]
    set sourceKey [lindex $sourceItem end]
    if {$target == [nodeRow $win $sourceKey end] || $target == $source} {
	return ""
    }

    set parentKey $data($sourceKey-parent)
    set parentEndRow [nodeRow $win $parentKey end]
    if {($target <= [keyToRow $win $parentKey] || $target > $parentEndRow)} {
	return -code error \
	       "cannot move item with index \"$source\" outside its parent"
    }

    if {$target == $parentEndRow} {
	set targetChildIdx end
    } else {
	set targetKey [lindex $data(keyList) $target]
	if {[string compare $data($targetKey-parent) $parentKey] != 0} {
	    return -code error \
		   "cannot move item with index \"$source\" outside its parent"
	}

	set targetChildIdx \
	    [lsearch -exact $data($parentKey-children) $targetKey]
    }

    return [moveNode $win $source $parentKey $targetChildIdx]
}

#------------------------------------------------------------------------------
# tablelist::moveNode
#
# Processes the 2nd form of the tablelist move subcommand.
#------------------------------------------------------------------------------
proc tablelist::moveNode {win source targetParentKey targetChildIdx \
			 {withDescendants 1}} {
    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled) || $data(itemCount) == 0} {
	return ""
    }

    #
    # Adjust the indices to fit within the existing items and check them
    #
    if {$source > $data(lastRow)} {
	set source $data(lastRow)
    } elseif {$source < 0} {
	set source 0
    }
    set target [nodeRow $win $targetParentKey $targetChildIdx]
    if {$target < 0} {
	set target 0
    }

    set sourceItem [lindex $data(itemList) $source]
    set sourceKey [lindex $sourceItem end]
    if {$target == [nodeRow $win $sourceKey end] && $withDescendants} {
	return ""
    }

    set sourceParentKey $data($sourceKey-parent)
    if {[string compare $targetParentKey $sourceParentKey] == 0 &&
	$target == $source && $withDescendants} {
	return ""
    }

    set sourceDescCount [descCount $win $sourceKey]
    if {$target > $source && $target <= $source + $sourceDescCount &&
	$withDescendants} {
	return -code error \
	       "cannot move item with index \"$source\"\
		before one of its descendants"
    }

    set w $data(body)
    if {$data(anchorRow) != $source} {
	$w mark set anchorRowMark [expr {$data(anchorRow) + 1}].0
    }
    if {$data(activeRow) != $source} {
	$w mark set activeRowMark [expr {$data(activeRow) + 1}].0
    }

    #
    # Save some data of the edit window if present
    #
    if {[set editCol $data(editCol)] >= 0} {
	set editRow $data(editRow)
	set editKey $data(editKey)
	saveEditData $win
    }

    #
    # Build the list of column indices of the selected cells
    # within the source line and then delete that line
    #
    set selectedCols {}
    set line [expr {$source + 1}]
    set textIdx $line.0
    variable canElide
    variable elide
    for {set col 0} {$col < $data(colCount)} {incr col} {
	if {$data($col-hide) && !$canElide} {
	    continue
	}

	#
	# Check whether the 2nd tab character of the cell is selected
	#
	set textIdx [$w search $elide "\t" $textIdx+1c $line.end]
	if {[lsearch -exact [$w tag names $textIdx] select] >= 0} {
	    lappend selectedCols $col
	}

	set textIdx $textIdx+1c
    }
    $w delete [expr {$source + 1}].0 [expr {$source + 2}].0

    #
    # Insert the source item before the target one
    #
    set target1 $target
    if {$source < $target} {
	incr target1 -1
    }
    set targetLine [expr {$target1 + 1}]
    $w insert $targetLine.0 "\n"
    set snipStr $data(-snipstring)
    set dispItem [lrange $sourceItem 0 $data(lastCol)]
    if {$data(hasFmtCmds)} {
	set dispItem [formatItem $win $sourceKey $source $dispItem]
    }
    if {[string match "*\t*" $dispItem]} {
	set dispItem [mapTabs $dispItem]
    }
    set col 0
    foreach text $dispItem colTags $data(colTagsList) \
	    {pixels alignment} $data(colList) {
	if {$data($col-hide) && !$canElide} {
	    incr col
	    continue
	}

	#
	# Build the list of tags to be applied to the cell
	#
	set cellFont [getCellFont $win $sourceKey $col]
	set cellTags $colTags
	if {[info exists data($sourceKey,$col-font)]} {
	    lappend cellTags cell-font-$data($sourceKey,$col-font)
	}

	#
	# Append the text and the labels or window (if
	# any) to the target line of the body text widget
	#
	appendComplexElem $win $sourceKey $source $col $text $pixels \
			  $alignment $snipStr $cellFont $cellTags $targetLine

	incr col
    }
    if {[info exists data($sourceKey-font)]} {
	$w tag add row-font-$data($sourceKey-font) $targetLine.0 $targetLine.end
    }
    if {[info exists data($sourceKey-elide)]} {
	$w tag add elidedRow $targetLine.0 $targetLine.end+1c
    }
    if {[info exists data($sourceKey-hide)]} {
	$w tag add hiddenRow $targetLine.0 $targetLine.end+1c
    }

    set treeCol $data(treeCol)
    set treeStyle $data(-treestyle)
    set indentImg [doCellCget $source $treeCol $win -indent]

    #
    # Update the item list and the key -> row mapping
    #
    set data(itemList) [lreplace $data(itemList) $source $source]
    set data(keyList) [lreplace $data(keyList) $source $source]
    if {$target == $data(itemCount)} {
	lappend data(itemList) $sourceItem	;# this works much faster
	lappend data(keyList) $sourceKey	;# this works much faster
    } else {
	set data(itemList) [linsert $data(itemList) $target1 $sourceItem]
	set data(keyList) [linsert $data(keyList) $target1 $sourceKey]
    }
    if {$source < $target} {
	for {set row $source} {$row < $targetLine} {incr row} {
	    set key [lindex $data(keyList) $row]
	    set data($key-row) $row
	}
    } else {
	for {set row $target} {$row <= $source} {incr row} {
	    set key [lindex $data(keyList) $row]
	    set data($key-row) $row
	}
    }

    #
    # Elide the moved item if the target parent is collapsed or non-viewable
    #
    set depth [depth $win $targetParentKey]
    if {([info exists data($targetParentKey,$treeCol-indent)] && \
	 [string compare $data($targetParentKey,$treeCol-indent) \
	  tablelist_${treeStyle}_collapsedImg$depth] == 0) ||
	[info exists data($targetParentKey-elide)] ||
	[info exists data($targetParentKey-hide)]} {
	doRowConfig $target1 $win -elide 1
    }

    if {$withDescendants} {
	#
	# Update the tree information
	#
	set targetBuddyCount [llength $data($targetParentKey-children)]
	set sourceChildIdx \
	    [lsearch -exact $data($sourceParentKey-children) $sourceKey]
	set data($sourceParentKey-children) \
	    [lreplace $data($sourceParentKey-children) \
	     $sourceChildIdx $sourceChildIdx]
	if {[string first $targetChildIdx "end"] == 0} {
	    set targetChildIdx $targetBuddyCount
	}
	if {$targetChildIdx >= $targetBuddyCount} {
	    lappend data($targetParentKey-children) $sourceKey
	} else {
	    if {[string compare $sourceParentKey $targetParentKey] == 0 &&
		$sourceChildIdx < $targetChildIdx} {
		incr targetChildIdx -1
	    }
	    set data($targetParentKey-children) \
		[linsert $data($targetParentKey-children) \
		 $targetChildIdx $sourceKey]
	}
	set data($sourceKey-parent) $targetParentKey

	#
	# If the list of children of the source's parent has become empty
	# then set the parent's indentation image to the indented one
	#
	if {[llength $data($sourceParentKey-children)] == 0 &&
	    [info exists data($sourceParentKey,$treeCol-indent)]} {
	    collapseSubCmd $win [list $sourceParentKey -partly]
	    set data($sourceParentKey,$treeCol-indent) [strMap \
		{"collapsed" "indented" "expanded" "indented"
		 "Act" "" "Sel" ""} $data($sourceParentKey,$treeCol-indent)]
	    if {[winfo exists $w.ind_$sourceParentKey,$treeCol]} {
		$w.ind_$sourceParentKey,$treeCol configure -image \
		    $data($sourceParentKey,$treeCol-indent)
	    }
	}

	#
	# Mark the target parent item as expanded if it was just indented
	#
	if {[info exists data($targetParentKey,$treeCol-indent)] &&
	    [string compare $data($targetParentKey,$treeCol-indent) \
	     tablelist_${treeStyle}_indentedImg$depth] == 0} {
	    set data($targetParentKey,$treeCol-indent) \
		tablelist_${treeStyle}_expandedImg$depth
	    if {[winfo exists $data(body).ind_$targetParentKey,$treeCol]} {
		$data(body).ind_$targetParentKey,$treeCol configure -image \
		    $data($targetParentKey,$treeCol-indent)
	    }
	}

	#
	# Update the indentation of the moved item
	#
	if {[regexp {^(.+Img)([0-9]+)$} $indentImg dummy base sourceDepth]} {
	    incr depth
	    variable maxIndentDepths
	    if {$depth > $maxIndentDepths($treeStyle)} {
		createTreeImgs $treeStyle $depth
		set maxIndentDepths($treeStyle) $depth
	    }
	    doCellConfig $target1 $treeCol $win -indent $base$depth
	}
    }

    #
    # Update the list variable if present
    #
    if {$data(hasListVar)} {
	upvar #0 $data(-listvariable) var
	trace vdelete var wu $data(listVarTraceCmd)
	set var [lreplace $var $source $source]
	set pureSourceItem [lrange $sourceItem 0 $data(lastCol)]
	if {$target == $data(itemCount)} {
	    lappend var $pureSourceItem		;# this works much faster
	} else {
	    set var [linsert $var $target1 $pureSourceItem]
	}
	trace variable var wu $data(listVarTraceCmd)
    }

    #
    # Update anchorRow and activeRow
    #
    if {$data(anchorRow) == $source} {
	set data(anchorRow) $target1
	adjustRowIndex $win data(anchorRow) 1
    } else {
	set anchorTextIdx [$w index anchorRowMark]
	set data(anchorRow) [expr {int($anchorTextIdx) - 1}]
    }
    if {$data(activeRow) == $source} {
	set activeRow $target1
	adjustRowIndex $win activeRow 1
	set data(activeRow) $activeRow
    } else {
	set activeTextIdx [$w index activeRowMark]
	set data(activeRow) [expr {int($activeTextIdx) - 1}]
    }

    #
    # Invalidate the list of row indices indicating the viewable rows
    #
    set data(viewableRowList) {-1}

    #
    # Select those source elements that were selected before
    #
    foreach col $selectedCols {
	cellSelection $win set $target1 $col $target1 $col
    }

    #
    # Restore the edit window if it was present before
    #
    if {$editCol >= 0} {
	if {$editRow == $source} {
	    doEditCell $win $target1 $editCol 1
	} else {
	    set data(editRow) [keyToRow $win $editKey]
	}
    }

    if {$withDescendants} {
	#
	# Save the source node's list of children and temporarily empty it
	#
	set sourceChildList $data($sourceKey-children)
	set data($sourceKey-children) {}

	#
	# Move the source item's descendants
	#
	if {$source < $target} {
	    set lastDescRow [expr {$source + $sourceDescCount - 1}]
	    set increment -1
	} else {
	    set lastDescRow [expr {$source + $sourceDescCount}]
	    set increment 0
	}
	for {set n 0; set descRow $lastDescRow} {$n < $sourceDescCount} \
	    {incr n; incr descRow $increment} {
	    set indentImg [doCellCget $descRow $treeCol $win -indent]
	    if {[regexp {^(.+Img)([0-9]+)$} $indentImg dummy base descDepth]} {
		incr descDepth [expr {$depth - $sourceDepth}]
		if {$descDepth > $maxIndentDepths($treeStyle)} {
		    for {set d $descDepth} {$d > $maxIndentDepths($treeStyle)} \
			{incr d -1} {
			createTreeImgs $treeStyle $d
		    }
		    set maxIndentDepths($treeStyle) $descDepth
		}
		set descKey [lindex $data(keyList) $descRow]
		set data($descKey,$treeCol-indent) $base$descDepth
	    }

	    moveNode $win $descRow $sourceKey end 0
	}

	#
	# Restore the source node's list of children
	#
	set data($sourceKey-children) $sourceChildList

	#
	# Adjust the columns, restore the stripes in the body text widget,
	# redisplay the line numbers (if any), and update the view
	#
	adjustColumns $win $treeCol 1
	adjustElidedText $win
	redisplayVisibleItems $win
	makeStripes $win
	showLineNumbersWhenIdle $win
	adjustSepsWhenIdle $win
	updateVScrlbarWhenIdle $win
    }

    #
    # (Un)hide the newline character that ends the
    # last line if the line itself is (not) hidden
    #
    foreach tag {elidedRow hiddenRow} {
	if {[lsearch -exact [$w tag names end-1l] $tag] >= 0} {
	    $w tag add $tag end-1c
	} else {
	    $w tag remove $tag end-1c
	}
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::moveCol
#
# Processes the tablelist movecolumn subcommand.
#------------------------------------------------------------------------------
proc tablelist::moveCol {win source target} {
    upvar ::tablelist::ns${win}::data data \
	  ::tablelist::ns${win}::attribs attribs
    if {$data(isDisabled)} {
	return ""
    }

    #
    # Check the indices
    #
    if {$target == $source || $target == $source + 1} {
	return ""
    }

    if {[winfo viewable $win]} {
	purgeWidgets $win
	update idletasks
	if {![array exists ::tablelist::ns${win}::data]} {
	    return ""
	}
    }

    #
    # Update the column list
    #
    set source3 [expr {3*$source}]
    set source3Plus2 [expr {$source3 + 2}]
    set target1 $target
    if {$source < $target} {
	incr target1 -1
    }
    set target3 [expr {3*$target1}]
    set sourceRange [lrange $data(-columns) $source3 $source3Plus2]
    set data(-columns) [lreplace $data(-columns) $source3 $source3Plus2]
    set data(-columns) [eval linsert {$data(-columns)} $target3 $sourceRange]

    #
    # Save some elements of data and attribs corresponding to source
    #
    array set tmpData [array get data $source-*]
    array set tmpData [array get data k*,$source-*]
    foreach specialCol {activeCol anchorCol editCol -treecolumn treeCol} {
	set tmpData($specialCol) $data($specialCol)
    }
    array set tmpAttribs [array get attribs $source-*]
    array set tmpAttribs [array get attribs k*,$source-*]
    set selCells [curCellSelection $win]
    set tmpRows [extractColFromCellList $selCells $source]

    #
    # Remove source from the list of stretchable columns
    # if it was explicitly specified as stretchable
    #
    if {[string compare $data(-stretch) "all"] != 0} {
	set sourceIsStretchable 0
	set stretchableCols {}
	foreach elem $data(-stretch) {
	    if {[string first $elem "end"] != 0 && $elem == $source} {
		set sourceIsStretchable 1
	    } else {
		lappend stretchableCols $elem
	    }
	}
	set data(-stretch) $stretchableCols
    }

    #
    # Build two lists of column numbers, needed
    # for shifting some elements of the data array
    #
    if {$source < $target} {
	for {set n $source} {$n < $target1} {incr n} {
	    lappend oldCols [expr {$n + 1}]
	    lappend newCols $n
	}
    } else {
	for {set n $source} {$n > $target} {incr n -1} {
	    lappend oldCols [expr {$n - 1}]
	    lappend newCols $n
	}
    }

    #
    # Remove the trace from the array element data(activeCol) because otherwise
    # the procedure moveColData won't work if the selection type is cell
    #
    trace vdelete data(activeCol) w [list tablelist::activeTrace $win]

    #
    # Move the elements of data and attribs corresponding
    # to the columns in oldCols to the elements corresponding
    # to the columns with the same indices in newCols
    #
    foreach oldCol $oldCols newCol $newCols {
	moveColData data data imgs $oldCol $newCol
	moveColAttribs attribs attribs $oldCol $newCol
	set selCells [replaceColInCellList $selCells $oldCol $newCol]
    }

    #
    # Move the elements of data and attribs corresponding
    # to source to the elements corresponding to target1
    #
    moveColData tmpData data imgs $source $target1
    moveColAttribs tmpAttribs attribs $source $target1
    set selCells [deleteColFromCellList $selCells $target1]
    foreach row $tmpRows {
	lappend selCells $row,$target1
    }

    #
    # If the column given by source was explicitly specified as
    # stretchable then add target1 to the list of stretchable columns
    #
    if {[string compare $data(-stretch) "all"] != 0 && $sourceIsStretchable} {
	lappend data(-stretch) $target1
	sortStretchableColList $win
    }

    #
    # Update the item list
    #
    set newItemList {}
    foreach item $data(itemList) {
	set sourceText [lindex $item $source]
	set item [lreplace $item $source $source]
	set item [linsert $item $target1 $sourceText]
	lappend newItemList $item
    }
    set data(itemList) $newItemList

    #
    # Update the list variable if present
    #
    condUpdateListVar $win

    #
    # Set up and adjust the columns, and rebuild
    # the lists of the column fonts and tag names
    #
    setupColumns $win $data(-columns) 0
    makeColFontAndTagLists $win
    makeSortAndArrowColLists $win
    adjustColumns $win {} 0

    #
    # Redisplay the items
    #
    redisplay $win 0 $selCells
    updateColorsWhenIdle $win

    #
    # Reconfigure the relevant column labels
    #
    foreach col [lappend newCols $target1] {
	reconfigColLabels $win imgs $col
    }

    #
    # Restore the trace set on the array element data(activeCol)
    # and enforce the execution of the activeTrace command
    #
    trace variable data(activeCol) w [list tablelist::activeTrace $win]
    set data(activeCol) $data(activeCol)

    return ""
}
#==============================================================================
# Contains the implementation of the tablelist::sortByColumn and
# tablelist::addToSortColumns commands, as well as of the tablelist sort,
# sortbycolumn, and sortbycolumnlist subcommands.
#
# Structure of the module:
#   - Public procedures related to sorting
#   - Private procedures implementing the sorting
#
# Copyright (c) 2000-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#
# Public procedures related to sorting
# ====================================
#

#------------------------------------------------------------------------------
# tablelist::sortByColumn
#
# Sorts the contents of the tablelist widget win by its col'th column.  Returns
# the sort order (increasing or decreasing).
#------------------------------------------------------------------------------
proc tablelist::sortByColumn {win col} {
    #
    # Check the arguments
    #
    if {![winfo exists $win]} {
	return -code error "bad window path name \"$win\""
    }
    if {[string compare [winfo class $win] "Tablelist"] != 0} {
	return -code error "window \"$win\" is not a tablelist widget"
    }
    if {[catch {::$win columnindex $col} result] != 0} {
	return -code error $result
    }
    if {$result < 0 || $result >= [::$win columncount]} {
	return -code error "column index \"$col\" out of range"
    }
    set col $result
    if {[::$win columncget $col -showlinenumbers]} {
	return ""
    }

    #
    # Determine the sort order
    #
    if {[set idx [lsearch -exact [::$win sortcolumnlist] $col]] >= 0 &&
	[string compare [lindex [::$win sortorderlist] $idx] "increasing"]
	== 0} {
	set sortOrder decreasing
    } else {
	set sortOrder increasing
    }

    #
    # Sort the widget's contents based on the given column
    #
    if {[catch {::$win sortbycolumn $col -$sortOrder} result] == 0} {
	set userData [list $col $sortOrder]
	genVirtualEvent $win <<TablelistColumnSorted>> $userData

	return $sortOrder
    } else {
	return -code error $result
    }
}

#------------------------------------------------------------------------------
# tablelist::addToSortColumns
#
# Adds the col'th column of the tablelist widget win to the latter's list of
# sort columns and sorts the contents of the widget by the modified column
# list.  Returns the specified column's sort order (increasing or decreasing).
#------------------------------------------------------------------------------
proc tablelist::addToSortColumns {win col} {
    #
    # Check the arguments
    #
    if {![winfo exists $win]} {
	return -code error "bad window path name \"$win\""
    }
    if {[string compare [winfo class $win] "Tablelist"] != 0} {
	return -code error "window \"$win\" is not a tablelist widget"
    }
    if {[catch {::$win columnindex $col} result] != 0} {
	return -code error $result
    }
    if {$result < 0 || $result >= [::$win columncount]} {
	return -code error "column index \"$col\" out of range"
    }
    set col $result
    if {[::$win columncget $col -showlinenumbers]} {
	return ""
    }

    #
    # Update the lists of sort columns and orders
    #
    set sortColList [::$win sortcolumnlist]
    set sortOrderList [::$win sortorderlist]
    if {[set idx [lsearch -exact $sortColList $col]] >= 0} {
	if {[string compare [lindex $sortOrderList $idx] "increasing"] == 0} {
	    set sortOrder decreasing
	} else {
	    set sortOrder increasing
	}
	set sortOrderList [lreplace $sortOrderList $idx $idx $sortOrder]
    } else {
	lappend sortColList $col
	lappend sortOrderList increasing
	set sortOrder increasing
    }

    #
    # Sort the widget's contents according to the
    # modified lists of sort columns and orders
    #
    if {[catch {::$win sortbycolumnlist $sortColList $sortOrderList} result]
	== 0} {
	set userData [list $sortColList $sortOrderList]
	genVirtualEvent $win <<TablelistColumnsSorted>> $userData

	return $sortOrder
    } else {
	return -code error $result
    }
}

#
# Private procedures implementing the sorting
# ===========================================
#

#------------------------------------------------------------------------------
# tablelist::sortItems
#
# Processes the tablelist sort, sortbycolumn, and sortbycolumnlist subcommands.
#------------------------------------------------------------------------------
proc tablelist::sortItems {win parentKey sortColList sortOrderList} {
    variable canElide
    variable snipSides
    upvar ::tablelist::ns${win}::data data

    set sortAllItems [expr {[string compare $parentKey "root"] == 0}]
    if {[winfo viewable $win] && $sortAllItems} {
	purgeWidgets $win
	update idletasks
	if {![array exists ::tablelist::ns${win}::data]} {
	    return ""
	}
    }

    #
    # Make sure sortOrderList has the same length as sortColList
    #
    set sortColCount [llength $sortColList]
    set sortOrderCount [llength $sortOrderList]
    if {$sortOrderCount < $sortColCount} {
	for {set n $sortOrderCount} {$n < $sortColCount} {incr n} {
	    lappend sortOrderList increasing
	}
    } else {
	set sortOrderList [lrange $sortOrderList 0 [expr {$sortColCount - 1}]]
    }

    #
    # Save the keys corresponding to anchorRow and activeRow,
    # as well as the indices of the selected cells
    #
    foreach type {anchor active} {
	set ${type}Key [lindex $data(keyList) $data(${type}Row)]
    }
    set selCells [curCellSelection $win 1]

    #
    # Save some data of the edit window if present
    #
    if {[set editCol $data(editCol)] >= 0} {
	set editKey $data(editKey)
	saveEditData $win
    }

    #
    # Update the sort info and sort the item list
    #
    set descItemList {}
    if {[llength $sortColList] == 1 && [lindex $sortColList 0] == -1} {
	if {[string length $data(-sortcommand)] == 0} {
	    return -code error "value of the -sortcommand option is empty"
	}

	set order [lindex $sortOrderList 0]

	if {$sortAllItems} {
	    #
	    # Update the sort info
	    #
	    for {set col 0} {$col < $data(colCount)} {incr col} {
		set data($col-sortRank) 0
		set data($col-sortOrder) ""
	    }
	    set data(sortColList) {}
	    set data(arrowColList) {}
	    set data(sortOrder) $order
	}

	#
	# Sort the child item list
	#
	sortChildren $win $parentKey [list lsort -$order -command \
	    $data(-sortcommand)] descItemList
    } else {					;# sorting by a column (list)
	#
	# Check the specified column indices
	#
	set sortColCount2 $sortColCount
	foreach col $sortColList {
	    if {$data($col-showlinenumbers)} {
		incr sortColCount2 -1
	    }
	}
	if {$sortColCount2 == 0} {
	    return ""
	}

	if {$sortAllItems} {
	    #
	    # Update the sort info
	    #
	    for {set col 0} {$col < $data(colCount)} {incr col} {
		set data($col-sortRank) 0
		set data($col-sortOrder) ""
	    }
	    set rank 1
	    foreach col $sortColList order $sortOrderList {
		if {$data($col-showlinenumbers)} {
		    continue
		}

		set data($col-sortRank) $rank
		set data($col-sortOrder) $order
		incr rank
	    }
	    makeSortAndArrowColLists $win
	}

	#
	# Sort the child item list based on the specified columns
	#
	for {set idx [expr {$sortColCount - 1}]} {$idx >= 0} {incr idx -1} {
	    set col [lindex $sortColList $idx]
	    if {$data($col-showlinenumbers)} {
		continue
	    }

	    set descItemList {}
	    set order [lindex $sortOrderList $idx]
	    if {[string compare $data($col-sortmode) "command"] == 0} {
		if {![info exists data($col-sortcommand)]} {
		    return -code error "value of the -sortcommand option for\
					column $col is missing or empty"
		}

		sortChildren $win $parentKey [list lsort -$order -index $col \
		    -command $data($col-sortcommand)] descItemList
	    } elseif {[string compare $data($col-sortmode) "asciinocase"]
		== 0} {
		if {$::tcl_version >= 8.5} {
		    sortChildren $win $parentKey [list lsort -$order \
			-index $col -ascii -nocase] descItemList
		} else {
		    sortChildren $win $parentKey [list lsort -$order \
			-index $col -command compareNoCase] descItemList
		}
	    } else {
		sortChildren $win $parentKey [list lsort -$order -index $col \
		    -$data($col-sortmode)] descItemList
	    }
	}
    }

    if {$sortAllItems} {
	#
	# Cancel the execution of all delayed
	# redisplay and redisplayCol commands
	#
	foreach name [array names data *redispId] {
	    after cancel $data($name)
	    unset data($name)
	}

	set canvasWidth $data(arrowWidth)
	if {[llength $data(arrowColList)] > 1} {
	    incr canvasWidth 6
	}
	foreach col $data(arrowColList) {
	    #
	    # Make sure the arrow will fit into the column
	    #
	    set idx [expr {2*$col}]
	    set pixels [lindex $data(colList) $idx]
	    if {$pixels == 0 && $data($col-maxPixels) > 0 &&
		$data($col-reqPixels) > $data($col-maxPixels) &&
		$data($col-maxPixels) < $canvasWidth} {
		set data($col-maxPixels) $canvasWidth
		set data($col-maxwidth) -$canvasWidth
	    }
	    if {$pixels != 0 && $pixels < $canvasWidth} {
		set data(colList) \
		    [lreplace $data(colList) $idx $idx $canvasWidth]
		set idx [expr {3*$col}]
		set data(-columns) \
		    [lreplace $data(-columns) $idx $idx -$canvasWidth]
	    }
	}

	#
	# Adjust the columns; this will also place the
	# canvas widgets into the corresponding labels
	#
	adjustColumns $win allLabels 1
    }

    if {[llength $descItemList] == 0} {
	return ""
    }

    set parentRow [keyToRow $win $parentKey]
    set firstDescRow [expr {$parentRow + 1}]
    set lastDescRow [expr {$parentRow + [descCount $win $parentKey]}]
    set firstDescLine [expr {$firstDescRow + 1}]
    set lastDescLine [expr {$lastDescRow + 1}]

    #
    # Update the line numbers (if any)
    #
    for {set col 0} {$col < $data(colCount)} {incr col} {
	if {!$data($col-showlinenumbers)} {
	    continue
	}

	set newDescItemList {}
	set line $firstDescLine
	foreach item $descItemList {
	    set item [lreplace $item $col $col $line]
	    lappend newDescItemList $item
	    set key [lindex $item end]
	    if {![info exists data($key-hide)]} {
		incr line
	    }
	}
	set descItemList $newDescItemList
    }

    set data(itemList) [eval [list lreplace $data(itemList) \
	$firstDescRow $lastDescRow] $descItemList]

    #
    # Replace the contents of the list variable if present
    #
    condUpdateListVar $win

    #
    # Delete the items from the body text widget and insert the sorted ones.
    # Interestingly, for a large number of items it is much more efficient
    # to empty each line individually than to invoke a global delete command.
    #
    set w $data(body)
    $w tag remove elidedRow $firstDescLine.0 $lastDescLine.end+1c
    $w tag remove hiddenRow $firstDescLine.0 $lastDescLine.end+1c
    for {set line $firstDescLine} {$line <= $lastDescLine} {incr line} {
	$w delete $line.0 $line.end
    }
    set snipStr $data(-snipstring)
    set rowTagRefCount $data(rowTagRefCount)
    set cellTagRefCount $data(cellTagRefCount)
    set isSimple [expr {$data(imgCount) == 0 && $data(winCount) == 0 &&
			$data(indentCount) == 0}]
    set padY [expr {[$w cget -spacing1] == 0}]
    set descKeyList {}
    for {set row $firstDescRow; set line $firstDescLine} \
	{$row <= $lastDescRow} {set row $line; incr line} {
	set item [lindex $data(itemList) $row]
	set key [lindex $item end]
	lappend descKeyList $key
	set data($key-row) $row
	set dispItem [lrange $item 0 $data(lastCol)]
	if {$data(hasFmtCmds)} {
	    set dispItem [formatItem $win $key $row $dispItem]
	}
	if {[string match "*\t*" $dispItem]} {
	    set dispItem [mapTabs $dispItem]
	}

	#
	# Clip the elements if necessary and
	# insert them with the corresponding tags
	#
	if {$rowTagRefCount == 0} {
	    set hasRowFont 0
	} else {
	    set hasRowFont [info exists data($key-font)]
	}
	set col 0
	if {$isSimple} {
	    set insertArgs {}
	    set multilineData {}
	    foreach text $dispItem \
		    colFont $data(colFontList) \
		    colTags $data(colTagsList) \
		    {pixels alignment} $data(colList) {
		if {$data($col-hide) && !$canElide} {
		    incr col
		    continue
		}

		#
		# Build the list of tags to be applied to the cell
		#
		if {$hasRowFont} {
		    set cellFont $data($key-font)
		} else {
		    set cellFont $colFont
		}
		set cellTags $colTags
		if {$cellTagRefCount != 0} {
		    if {[info exists data($key,$col-font)]} {
			set cellFont $data($key,$col-font)
			lappend cellTags cell-font-$data($key,$col-font)
		    }
		}

		#
		# Clip the element if necessary
		#
		set multiline [string match "*\n*" $text]
		if {$pixels == 0} {		;# convention: dynamic width
		    if {$data($col-maxPixels) > 0} {
			if {$data($col-reqPixels) > $data($col-maxPixels)} {
			    set pixels $data($col-maxPixels)
			}
		    }
		}
		if {$pixels != 0} {
		    incr pixels $data($col-delta)

		    if {$data($col-wrap) && !$multiline} {
			if {[font measure $cellFont -displayof $win $text] >
			    $pixels} {
			    set multiline 1
			}
		    }

		    set snipSide \
			$snipSides($alignment,$data($col-changesnipside))
		    if {$multiline} {
			set list [split $text "\n"]
			if {$data($col-wrap)} {
			    set snipSide ""
			}
			set text [joinList $win $list $cellFont \
				  $pixels $snipSide $snipStr]
		    } elseif {$data(-displayondemand)} {
			set text ""
		    } else {
			set text [strRange $win $text $cellFont \
				  $pixels $snipSide $snipStr]
		    }
		}

		if {$multiline} {
		    lappend insertArgs "\t\t" $cellTags
		    lappend multilineData $col $text $cellFont $pixels \
					  $alignment
		} else {
		    lappend insertArgs "\t$text\t" $cellTags
		}

		incr col
	    }

	    #
	    # Insert the item into the body text widget
	    #
	    if {[llength $insertArgs] != 0} {
		eval [list $w insert $line.0] $insertArgs
	    }

	    #
	    # Embed the message widgets displaying multiline elements
	    #
	    foreach {col text font pixels alignment} $multilineData {
		findTabs $win $line $col $col tabIdx1 tabIdx2
		set msgScript [list ::tablelist::displayText $win $key \
			       $col $text $font $pixels $alignment]
		$w window create $tabIdx2 \
			  -align top -pady $padY -create $msgScript
		$w tag add elidedWin $tabIdx2
	    }

	} else {
	    foreach text $dispItem \
		    colFont $data(colFontList) \
		    colTags $data(colTagsList) \
		    {pixels alignment} $data(colList) {
		if {$data($col-hide) && !$canElide} {
		    incr col
		    continue
		}

		#
		# Build the list of tags to be applied to the cell
		#
		if {$hasRowFont} {
		    set cellFont $data($key-font)
		} else {
		    set cellFont $colFont
		}
		set cellTags $colTags
		if {$cellTagRefCount != 0} {
		    if {[info exists data($key,$col-font)]} {
			set cellFont $data($key,$col-font)
			lappend cellTags cell-font-$data($key,$col-font)
		    }
		}

		#
		# Insert the text and the label or window
		# (if any) into the body text widget
		#
		appendComplexElem $win $key $row $col $text $pixels \
				  $alignment $snipStr $cellFont $cellTags $line

		incr col
	    }
	}

	if {$rowTagRefCount != 0} {
	    if {[info exists data($key-font)]} {
		$w tag add row-font-$data($key-font) $line.0 $line.end
	    }
	}

	if {[info exists data($key-elide)]} {
	    $w tag add elidedRow $line.0 $line.end+1c
	}
	if {[info exists data($key-hide)]} {
	    $w tag add hiddenRow $line.0 $line.end+1c
	}
    }

    set data(keyList) [eval [list lreplace $data(keyList) \
	$firstDescRow $lastDescRow] $descKeyList]

    if {$sortAllItems} {
	#
	# Validate the key -> row mapping
	#
	set data(keyToRowMapValid) 1
	if {[info exists data(mapId)]} {
	    after cancel $data(mapId)
	    unset data(mapId)
	}
    }

    #
    # Invalidate the list of row indices indicating the viewable rows
    #
    set data(viewableRowList) {-1}

    #
    # Select the cells that were selected before
    #
    foreach {key col} $selCells {
	set row [keyToRow $win $key]
	cellSelection $win set $row $col $row $col
    }

    #
    # Disable the body text widget if it was disabled before
    #
    if {$data(isDisabled)} {
	$w tag add disabled 1.0 end
	$w tag configure select -borderwidth 0
    }

    #
    # Update anchorRow and activeRow
    #
    foreach type {anchor active} {
	upvar 0 ${type}Key key2
	if {[string length $key2] != 0} {
	    set data(${type}Row) [keyToRow $win $key2]
	}
    }

    #
    # Bring the "most important" row into view if appropriate
    #
    if {$editCol >= 0} {
	set editRow [keyToRow $win $editKey]
	if {$editRow >= $firstDescRow && $editRow <= $lastDescRow} {
	    doEditCell $win $editRow $editCol 1
	}
    } else {
	set selRows [curSelection $win]
	if {[llength $selRows] == 1} {
	    set selRow [lindex $selRows 0]
	    set selKey [lindex $data(keyList) $selRow]
	    if {$selRow >= $firstDescRow && $selRow <= $lastDescRow &&
		![info exists data($selKey-elide)]} {
		seeRow $win $selRow
	    }
	} elseif {[string compare [focus -lastfor $w] $w] == 0} {
	    set activeKey [lindex $data(keyList) $data(activeRow)]
	    if {$data(activeRow) >= $firstDescRow &&
		$data(activeRow) <= $lastDescRow &&
		![info exists data($activeKey-elide)]} {
		seeRow $win $data(activeRow)
	    }
	}
    }

    #
    # Adjust the elided text and restore the stripes in the body text widget
    #
    adjustElidedText $win
    redisplayVisibleItems $win
    makeStripes $win
    adjustSepsWhenIdle $win
    updateVScrlbarWhenIdle $win

    #
    # Work around a Tk bug on Mac OS X Aqua
    #
    variable winSys
    if {[string compare $winSys "aqua"] == 0} {
	foreach col $data(arrowColList) {
	    set canvas [list $data(hdrTxtFrmCanv)$col]
	    after idle [list lower $canvas]
	    after idle [list raise $canvas]
	}
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::sortChildren
#
# Sorts the children of a given parent within the tablelist widget win,
# recursively.
#------------------------------------------------------------------------------
proc tablelist::sortChildren {win parentKey sortCmd itemListName} {
    upvar $itemListName itemList ::tablelist::ns${win}::data data

    set childKeyList $data($parentKey-children)
    if {[llength $childKeyList] == 0} {
	return ""
    }

    #
    # Build and sort the list of child items
    #
    set childItemList {}
    foreach childKey $childKeyList {
	lappend childItemList [lindex $data(itemList) [keyToRow $win $childKey]]
    }
    set childItemList [eval $sortCmd [list $childItemList]]

    #
    # Update the lists and invoke the procedure recursively for the children
    #
    set data($parentKey-children) {}
    foreach item $childItemList {
	lappend itemList $item
	set childKey [lindex $item end]
	lappend data($parentKey-children) $childKey

	sortChildren $win $childKey $sortCmd itemList
    }
}

#------------------------------------------------------------------------------
# tablelist::sortList
#
# Sorts the specified list by the current sort columns of the tablelist widget
# win, using their current sort orders.
#------------------------------------------------------------------------------
proc tablelist::sortList {win list} {
    upvar ::tablelist::ns${win}::data data
    set sortColList $data(sortColList)
    set sortOrderList {}
    foreach col $sortColList {
	lappend sortOrderList $data($col-sortOrder)
    }

    if {[llength $sortColList] == 1 && [lindex $sortColList 0] == -1} {
	if {[string length $data(-sortcommand)] == 0} {
	    return -code error "value of the -sortcommand option is empty"
	}

	#
	# Sort the list
	#
	set order [lindex $sortOrderList 0]
	return [lsort -$order -command $data(-sortcommand) $list]
    } else {
	#
	# Sort the list based on the specified columns
	#
	set sortColCount [llength $sortColList]
	for {set idx [expr {$sortColCount - 1}]} {$idx >= 0} {incr idx -1} {
	    set col [lindex $sortColList $idx]
	    set order [lindex $sortOrderList $idx]

	    if {[string compare $data($col-sortmode) "command"] == 0} {
		if {![info exists data($col-sortcommand)]} {
		    return -code error "value of the -sortcommand option for\
					column $col is missing or empty"
		}

		set list [lsort -$order -index $col -command \
			  $data($col-sortcommand) $list]
	    } elseif {[string compare $data($col-sortmode) "asciinocase"]
		== 0} {
		if {$::tcl_version >= 8.5} {
		    set list [lsort -$order -index $col -ascii -nocase $list]
		} else {
		    set list [lsort -$order -index $col -command \
			      compareNoCase $list]
		}
	    } else {
		set list [lsort -$order -index $col -$data($col-sortmode) $list]
	    }
	}

	return $list
    }
}

#------------------------------------------------------------------------------
# tablelist::compareNoCase
#
# Compares the given strings in a case-insensitive manner.
#------------------------------------------------------------------------------
proc tablelist::compareNoCase {str1 str2} {
    return [string compare [string tolower $str1] [string tolower $str2]]
}
#==============================================================================
# Contains procedures that populate the array themeDefaults with theme-specific
# default values of some tablelist configuration options.
#
# Structure of the module:
#   - Public procedures related to tile themes
#   - Private procedures related to tile themes
#   - Private procedures performing RGB <-> HSV conversions
#   - Private procedures related to global KDE configuration options
#
# Copyright (c) 2005-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#
# Public procedures related to tile themes
# ========================================
#

#------------------------------------------------------------------------------
# tablelist::getCurrentTheme
#
# Returns the current tile theme.
#------------------------------------------------------------------------------
proc tablelist::getCurrentTheme {} {
    if {[info exists ttk::currentTheme]} {
	return $ttk::currentTheme
    } else {
	return $tile::currentTheme
    }
}

#------------------------------------------------------------------------------
# tablelist::setThemeDefaults
#
# Populates the array themeDefaults with theme-specific default values of some
# tablelist configuration options and updates the array configSpecs.
#------------------------------------------------------------------------------
proc tablelist::setThemeDefaults {} {
    variable themeDefaults
    if {[catch {[getCurrentTheme]Theme}] != 0} {
	#
	# Fall back to the "default" theme (which is the root of all
	# themes) and then override the options set by the current one
	#
	defaultTheme 
	array set themeDefaults [style configure .]
    }

    if {[string length $themeDefaults(-arrowcolor)] == 0} {
	set themeDefaults(-arrowdisabledcolor) ""
    } else {
	set themeDefaults(-arrowdisabledcolor) $themeDefaults(-labeldisabledFg)
    }

    variable configSpecs
    foreach opt {-background -foreground -disabledforeground -stripebackground
		 -selectbackground -selectforeground -selectborderwidth -font
		 -labelforeground -labelfont -labelborderwidth -labelpady
		 -arrowcolor -arrowdisabledcolor -arrowstyle -treestyle} {
	if {[llength $configSpecs($opt)] < 4} {
	    lappend configSpecs($opt) $themeDefaults($opt)
	} else {
	    lset configSpecs($opt) 3 $themeDefaults($opt)
	}
    }
}

#
# Private procedures related to tile themes
# =========================================
#

#------------------------------------------------------------------------------
# tablelist::altTheme
#------------------------------------------------------------------------------
proc tablelist::altTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	#a3a3a3 \
	-stripebackground	"" \
	-selectbackground	#4a6984 \
	-selectforeground	#ffffff \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelbackground	#d9d9d9 \
	-labeldeactivatedBg	#d9d9d9 \
	-labeldisabledBg	#d9d9d9 \
	-labelactiveBg		#ececec \
	-labelpressedBg		#ececec \
	-labelforeground	black \
	-labeldisabledFg	#a3a3a3 \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		1 \
	-arrowcolor		black \
	-arrowstyle		flat7x5 \
	-treestyle		winnative \
    ]
}

#------------------------------------------------------------------------------
# tablelist::aquaTheme
#------------------------------------------------------------------------------
proc tablelist::aquaTheme {} {
    scan $::tcl_platform(osVersion) "%d" majorOSVersion
    if {$majorOSVersion >= 14} {			;# OS X 10.10 or higher
	set labelBg		#f4f4f4
	set labeldeactivatedBg	#ffffff
	set labeldisabledBg	#ffffff
	set labelpressedBg	#e4e4e4
	set arrowColor		#404040
    } elseif {$majorOSVersion >= 11} {			;# OS X 10.7 or higher
	set labelBg		#efefef
	set labeldeactivatedBg	#efefef
	set labeldisabledBg	#efefef
	set labelpressedBg	#cbcbcb
	set arrowColor		#777777
    } else {
	set labelBg		#e9e8e8
	set labeldeactivatedBg	#e9e8e8
	set labeldisabledBg	#e9e8e8
	set labelpressedBg	#d2d2d2
	set arrowColor		#717171
    }

    switch [winfo rgb . systemMenuActive] {
	"13621 29041 52685" -
	"32256 44288 55552" {				;# Blue Cocoa/Carbon
	    if {$majorOSVersion >= 14} {		;# OS X 10.10 or higher
		set stripeBg			#f2f2f2
		set labelselectedBg		#f4f4f4
		set labelselectedpressedBg	#e4e4e4
	    } elseif {$majorOSVersion >= 11} {		;# OS X 10.7 or higher
		set stripeBg			#f0f4f9
		set labelselectedBg		#80b8f0
		set labelselectedpressedBg	#417ddc
	    } else {
		set stripeBg			#edf3fe
		set labelselectedBg		#7ab2e9
		set labelselectedpressedBg	#679ed5
	    }
	}

	"24415 27499 31354" -
	"39680 43776 48384" {				;# Graphite Cocoa/Carbon
	    if {$majorOSVersion >= 14} {		;# OS X 10.10 or higher
		set stripeBg			#f2f2f2
		set labelselectedBg		#f4f4f4
		set labelselectedpressedBg	#e4e4e4
	    } elseif {$majorOSVersion >= 11} {		;# OS X 10.7 or higher
		set stripeBg			#f4f5f7
		set labelselectedBg		#9ba7b5
		set labelselectedpressedBg	#636e88
	    } else {
		set stripeBg			#f0f0f0
		set labelselectedBg		#b6c2cd
		set labelselectedpressedBg	#a7b3be
	    }
	}
    }

    #
    # Get an approximation of alternateSelectedControlColor
    #
    switch [winfo rgb . systemHighlight] {
	"65535 48058 47288"	{ set selectBg #fc2125 }
	"65535 57311 46003"	{ set selectBg #fd8208 }
	"65535 61423 45231"	{ set selectBg #fec309 }
	"49343 63222 44460"	{ set selectBg #56d72b }
	"45746 55246 65535"	{ set selectBg #0950d0 }
	"63478 54484 65535"	{ set selectBg #bf57da }
	"65535 49087 53969"	{ set selectBg #7b0055 }
	"60909 57053 51914"	{ set selectBg #90714c }
	"55512 55512 56539"	{ set selectBg #5c5c60 }

	"51143 53456 56281"	{ set selectBg #738499 }
	"50887 50887 50887"	{ set selectBg #7f7f7f }
	"46516 54741 65535"	{ set selectBg #3875d7 }
	"64506 60908 29556"	{ set selectBg #ffc11f }
	"65535 45487 35978"	{ set selectBg #f34648 }
	"65535 53968 33154"	{ set selectBg #ff8a22 }
	"50114 63994 37263"	{ set selectBg #66c547 }
	"59879 47290 65535"	{ set selectBg #8c4eb8 }

	default {
	    set rgb [winfo rgb . systemHighlight]
	    foreach {h s v} [eval rgb2hsv $rgb] {}

	    set s [expr {$s*4.0/3.0}]
	    if {$s > 1.0} {
		set s 1.0
	    }

	    set v [expr {$v*3.0/4.0}]
	    if {$v > 1.0} {
		set v 1.0
	    }

	    set rgb [hsv2rgb $h $s $v]
	    set selectBg [eval format "#%04x%04x%04x" $rgb]
	}
    }

    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	#a3a3a3 \
	-stripebackground	$stripeBg \
	-selectbackground	$selectBg \
	-selectforeground	white \
	-selectborderwidth	0 \
	-font			{"Lucida Grande" 12} \
	-labelbackground	$labelBg \
	-labeldeactivatedBg	$labeldeactivatedBg \
	-labeldisabledBg	$labeldisabledBg \
	-labelactiveBg		$labelBg \
	-labelpressedBg		$labelpressedBg \
	-labelselectedBg	$labelselectedBg \
	-labelselectedpressedBg	$labelselectedpressedBg \
	-labelforeground	black \
	-labeldisabledFg	#a3a3a3 \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelselectedFg	black \
	-labelselectedpressedFg	black \
	-labelfont		{"Lucida Grande" 11} \
	-labelborderwidth	1 \
	-labelpady		1 \
	-arrowcolor		$arrowColor \
	-treestyle		aqua \
    ]

    variable pngSupported
    if {$majorOSVersion >= 14} {			;# OS X 10.10 or higher
	set themeDefaults(-arrowstyle) flatAngle7x4
    } elseif {$pngSupported} {
	set themeDefaults(-arrowstyle) photo7x7
    } else {
	set themeDefaults(-arrowstyle) flat7x7
    }
}

#------------------------------------------------------------------------------
# tablelist::AquativoTheme
#------------------------------------------------------------------------------
proc tablelist::AquativoTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	black \
	-stripebackground	#edf3fe \
	-selectbackground	#000000 \
	-selectforeground	#ffffff \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelbackground	#fafafa \
	-labeldeactivatedBg	#fafafa \
	-labeldisabledBg	#fafafa \
	-labelactiveBg		#fafafa \
	-labelpressedBg		#fafafa \
	-labelforeground	black \
	-labeldisabledFg	black \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		1 \
	-arrowcolor		#717171 \
	-arrowstyle		flat7x7 \
	-treestyle		aqua \
    ]
}

#------------------------------------------------------------------------------
# tablelist::ArcTheme
#------------------------------------------------------------------------------
proc tablelist::ArcTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		#5c616c \
	-disabledforeground	#a9acb2 \
	-stripebackground	"" \
	-selectbackground	#5294e2 \
	-selectforeground	#ffffff \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelbackground	#f5f6f7 \
	-labeldeactivatedBg	#f5f6f7 \
	-labeldisabledBg	#fbfcfc \
	-labelactiveBg		#f5f6f7 \
	-labelpressedBg		#f5f6f7 \
	-labelforeground	#5c616c \
	-labeldisabledFg	#a9acb2 \
	-labelactiveFg		#5c616c \
	-labelpressedFg		#5c616c \
	-labelfont		TkDefaultFont \
	-labelborderwidth	0 \
	-labelpady		0 \
	-arrowcolor		#5c616c \
	-arrowstyle		flatAngle10x6 \
	-treestyle		arc \
    ]
}

#------------------------------------------------------------------------------
# tablelist::blueTheme
#------------------------------------------------------------------------------
proc tablelist::blueTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		#e6f3ff \
	-foreground		black \
	-disabledforeground	#666666 \
	-stripebackground	"" \
	-selectbackground	#ffff33 \
	-selectforeground	#000000 \
	-selectborderwidth	1 \
	-font			TkTextFont \
	-labelbackground	#6699cc \
	-labeldeactivatedBg	#6699cc \
	-labeldisabledBg	#6699cc \
	-labelactiveBg		#6699cc \
	-labelpressedBg		#6699cc \
	-labelforeground	black \
	-labeldisabledFg	#666666 \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	1 \
	-labelpady		1 \
	-arrowcolor		#2d2d66 \
	-arrowstyle		flat9x5 \
	-treestyle		gtk \
    ]
}

#------------------------------------------------------------------------------
# tablelist::clamTheme
#------------------------------------------------------------------------------
proc tablelist::clamTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	#999999 \
	-stripebackground	"" \
	-selectbackground	#4a6984 \
	-selectforeground	#ffffff \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelbackground	#dcdad5 \
	-labeldeactivatedBg	#dcdad5 \
	-labeldisabledBg	#dcdad5 \
	-labelactiveBg		#eeebe7 \
	-labelpressedBg		#eeebe7 \
	-labelforeground	black \
	-labeldisabledFg	#999999 \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		3 \
	-arrowcolor		black \
	-arrowstyle		flat7x5 \
	-treestyle		gtk \
    ]
}

#------------------------------------------------------------------------------
# tablelist::classicTheme
#------------------------------------------------------------------------------
proc tablelist::classicTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	#a3a3a3 \
	-stripebackground	"" \
	-selectbackground	#c3c3c3 \
	-selectforeground	#000000 \
	-selectborderwidth	1 \
	-font			TkTextFont \
	-labelbackground	#d9d9d9 \
	-labeldeactivatedBg	#d9d9d9 \
	-labeldisabledBg	#d9d9d9 \
	-labelactiveBg		#ececec \
	-labelpressedBg		#ececec \
	-labelforeground	black \
	-labeldisabledFg	#a3a3a3 \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		1 \
	-arrowcolor		"" \
	-arrowstyle		sunken10x9 \
	-treestyle		gtk \
    ]

    if {[info exists tile::version] &&
	[string compare $tile::version 0.8] < 0} {
	set themeDefaults(-font)	TkClassicDefaultFont
	set themeDefaults(-labelfont)	TkClassicDefaultFont
    }
}

#------------------------------------------------------------------------------
# tablelist::clearlooksTheme
#------------------------------------------------------------------------------
proc tablelist::clearlooksTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	#b5b3ac \
	-stripebackground	"" \
	-selectbackground	#71869e \
	-selectforeground	#ffffff \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelbackground	#efeae6 \
	-labeldeactivatedBg	#efeae6 \
	-labeldisabledBg	#eee9e4 \
	-labelactiveBg		#f4f2ee \
	-labelpressedBg		#d4cfca \
	-labelforeground	black \
	-labeldisabledFg	#b5b3ac \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	0 \
	-labelpady		1 \
	-arrowcolor		black \
	-arrowstyle		flatAngle9x6 \
	-treestyle		gtk \
    ]
}

#------------------------------------------------------------------------------
# tablelist::defaultTheme
#------------------------------------------------------------------------------
proc tablelist::defaultTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	#a3a3a3 \
	-stripebackground	"" \
	-selectbackground	#4a6984 \
	-selectforeground	#ffffff \
	-selectborderwidth	1 \
	-font			TkTextFont \
	-labelbackground	#d9d9d9 \
	-labeldeactivatedBg	#d9d9d9 \
	-labeldisabledBg	#d9d9d9 \
	-labelactiveBg		#ececec \
	-labelpressedBg		#ececec \
	-labelforeground	black \
	-labeldisabledFg	#a3a3a3 \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	1 \
	-labelpady		1 \
	-arrowcolor		black \
	-arrowstyle		flat7x5 \
	-treestyle		gtk \
    ]
}

#------------------------------------------------------------------------------
# tablelist::keramikTheme
#------------------------------------------------------------------------------
proc tablelist::keramikTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	#aaaaaa \
	-stripebackground	"" \
	-selectbackground	#0a5f89 \
	-selectforeground	#ffffff \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelbackground	#e2e4e7 \
	-labeldeactivatedBg	#e2e4e7 \
	-labeldisabledBg	#e2e4e7 \
	-labelactiveBg		#e2e4e7 \
	-labelpressedBg		#c6c8cc \
	-labelforeground	black \
	-labeldisabledFg	#aaaaaa \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	0 \
	-labelpady		1 \
	-arrowcolor		black \
	-arrowstyle		flat8x5 \
	-treestyle		winnative \
    ]
}

#------------------------------------------------------------------------------
# tablelist::keramik_altTheme
#------------------------------------------------------------------------------
proc tablelist::keramik_altTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	#aaaaaa \
	-stripebackground	"" \
	-selectbackground	#0a5f89 \
	-selectforeground	#ffffff \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelbackground	#e2e4e7 \
	-labeldeactivatedBg	#e2e4e7 \
	-labeldisabledBg	#e2e4e7 \
	-labelactiveBg		#e2e4e7 \
	-labelpressedBg		#c6c8cc \
	-labelforeground	black \
	-labeldisabledFg	#aaaaaa \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	0 \
	-labelpady		1 \
	-arrowcolor		black \
	-arrowstyle		flat8x5 \
	-treestyle		winnative \
    ]
}

#------------------------------------------------------------------------------
# tablelist::krocTheme
#------------------------------------------------------------------------------
proc tablelist::krocTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	#b2b2b2 \
	-stripebackground	"" \
	-selectbackground	#000000 \
	-selectforeground	#ffffff \
	-selectborderwidth	1 \
	-font			TkTextFont \
	-labelbackground	#fcb64f \
	-labeldeactivatedBg	#fcb64f \
	-labeldisabledBg	#fcb64f \
	-labelactiveBg		#694418 \
	-labelpressedBg		#694418 \
	-labelforeground	black \
	-labeldisabledFg	#b2b2b2 \
	-labelactiveFg		#ffe7cb \
	-labelpressedFg		#ffe7cb \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		1 \
	-arrowcolor		black \
	-arrowstyle		flat7x5 \
	-treestyle		gtk \
    ]
}

#------------------------------------------------------------------------------
# tablelist::plastikTheme
#------------------------------------------------------------------------------
proc tablelist::plastikTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	#aaaaaa \
	-stripebackground	"" \
	-selectbackground	#657a9e \
	-selectforeground	#ffffff \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelbackground	#dcdde3 \
	-labeldeactivatedBg	#dcdde3 \
	-labeldisabledBg	#dcdde3 \
	-labelactiveBg		#dcdde3 \
	-labelpressedBg		#b9bcc0 \
	-labelforeground	black \
	-labeldisabledFg	#aaaaaa \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	0 \
	-labelpady		1 \
	-arrowcolor		black \
	-arrowstyle		flat7x4 \
	-treestyle		plastik \
    ]
}

#------------------------------------------------------------------------------
# tablelist::srivTheme
#------------------------------------------------------------------------------
proc tablelist::srivTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		#e6f3ff \
	-foreground		black \
	-disabledforeground	#666666 \
	-stripebackground	"" \
	-selectbackground	#ffff33 \
	-selectforeground	#000000 \
	-selectborderwidth	1 \
	-font			TkTextFont \
	-labelbackground	#a0a0a0 \
	-labeldeactivatedBg	#a0a0a0 \
	-labeldisabledBg	#a0a0a0 \
	-labelactiveBg		#a0a0a0 \
	-labelpressedBg		#a0a0a0 \
	-labelforeground	black \
	-labeldisabledFg	#666666 \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		1 \
	-arrowcolor		black \
	-arrowstyle		flat7x5 \
	-treestyle		gtk \
    ]
}

#------------------------------------------------------------------------------
# tablelist::srivlgTheme
#------------------------------------------------------------------------------
proc tablelist::srivlgTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		#e6f3ff \
	-foreground		black \
	-disabledforeground	#666666 \
	-stripebackground	"" \
	-selectbackground	#ffff33 \
	-selectforeground	#000000 \
	-selectborderwidth	1 \
	-font			TkTextFont \
	-labelbackground	#6699cc \
	-labeldeactivatedBg	#6699cc \
	-labeldisabledBg	#6699cc \
	-labelactiveBg		#6699cc \
	-labelpressedBg		#6699cc \
	-labelforeground	black \
	-labeldisabledFg	#666666 \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		1 \
	-arrowcolor		black \
	-arrowstyle		flat7x5 \
	-treestyle		gtk \
    ]
}

#------------------------------------------------------------------------------
# tablelist::stepTheme
#------------------------------------------------------------------------------
proc tablelist::stepTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	#808080 \
	-stripebackground	"" \
	-selectbackground	#fdcd00 \
	-selectforeground	#ffffff \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelbackground	#a0a0a0 \
	-labeldeactivatedBg	#a0a0a0 \
	-labeldisabledBg	#a0a0a0 \
	-labelactiveBg		#aeb2c3 \
	-labelpressedBg		#aeb2c3 \
	-labelforeground	black \
	-labeldisabledFg	#808080 \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		1 \
	-arrowcolor		black \
	-arrowstyle		flat7x5 \
	-treestyle		gtk \
    ]
}

#------------------------------------------------------------------------------
# tablelist::tileqtTheme
#
# Tested with the following Qt styles:
#
#   Acqua              KDE Classic                Motif Plus     RISC OS
#   B3/KDE             KDE_XP                     MS Windows 9x  SGI
#   Baghira            Keramik                    Oxygen         System-Series
#   CDE                Light Style, 2nd revision  Phase          System++
#   Cleanlooks         Light Style, 3rd revision  Plastik        ThinKeramik
#   GTK+ Style         Lipstik                    Plastique
#   HighColor Classic  Marble                     Platinum
#   HighContrast       Motif                      QtCurve
#
# Supported KDE 1/2/3 color schemes:
#
#   Aqua Blue                     Ice (FreddyK)     Point Reyes Green
#   Aqua Graphite                 KDE 1             Pumpkin
#   Atlas Green                   KDE 2             Redmond 2000
#   BeOS                          Keramik           Redmond 95
#   Blue Slate                    Keramik Emerald   Redmond XP
#   CDE                           Keramik White     Solaris
#   Dark Blue                     Lipstik Noble     Storm
#   Desert Red                    Lipstik Standard  SuSE, old & new
#   Digital CDE                   Lipstik White     SUSE-kdm
#   EveX                          Media Peach       System
#   High Contrast Black Text      Next              Thin Keramik, old & new
#   High Contrast Yellow on Blue  Pale Gray         Thin Keramik II
#   High Contrast White Text      Plastik
#
# Supported KDE 4 color schemes:
#
#   Honeycomb       Oxygen (= Standard)  Steel       Zion (Reversed)
#   Norway          Oxygen Cold          Wonton Soup
#   Obsidian Coast  Oxygen-Molecule 3.0  Zion
#------------------------------------------------------------------------------
proc tablelist::tileqtTheme {} {
    set bg		[tileqt_currentThemeColour -background]
    set fg		[tileqt_currentThemeColour -foreground]
    set tableBg		[tileqt_currentThemeColour -base]
    set tableFg		[tileqt_currentThemeColour -text]
    set tableDisFg	[tileqt_currentThemeColour -disabled -text]
    set selectBg	[tileqt_currentThemeColour -highlight]
    set selectFg	[tileqt_currentThemeColour -highlightedText]
    set labelBg		[tileqt_currentThemeColour -button]
    set labelFg		[tileqt_currentThemeColour -buttonText]
    set labelDisFg	[tileqt_currentThemeColour -disabled -buttonText]
    set style		[string tolower [tileqt_currentThemeName]]
    set pressedBg	$labelBg

    #
    # For most Qt styles the label colors depend on the color scheme:
    #
    switch "$bg $labelBg" {
	"#fafafa #6188d7" {	;# color scheme "Aqua Blue"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #d0d0d0 }
		"baghira"	{ set labelBg #f5f5f5;  set pressedBg #9ec2fa }
		"highcolor"	{ set labelBg #628ada;  set pressedBg #6188d7 }
		"keramik"	{ set labelBg #8fabe4;  set pressedBg #7390cc }
		"phase"		{ set labelBg #6188d7;  set pressedBg #d0d0d0 }
		"plastik"	{ set labelBg #666bd6;  set pressedBg #5c7ec2 }
		"qtcurve"	{ set labelBg #f4f4f4;  set pressedBg #d0d0d0 }
		"thinkeramik"	{ set labelBg #f4f4f4;  set pressedBg #dedede }
	    }
	}

	"#ffffff #89919b" {	;# color scheme "Aqua Graphite"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #d4d4d4 }
		"baghira"	{ set labelBg #f5f5f5;  set pressedBg #c3c7cd }
		"highcolor"	{ set labelBg #8b949e;  set pressedBg #89919b }
		"keramik"	{ set labelBg #acb1b8;  set pressedBg #91979e }
		"phase"		{ set labelBg #89919b;  set pressedBg #d4d4d4 }
		"plastik"	{ set labelBg #8c949d;  set pressedBg #7f868e }
		"qtcurve"	{ set labelBg #f6f6f6;  set pressedBg #d4d4d4 }
		"thinkeramik"	{ set labelBg #f4f4f4;  set pressedBg #e2e2e2 }
	    }
	}

	"#afb49f #afb49f" {	;# color scheme "Atlas Green"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #c1c6af }
		"platinum"			      { set pressedBg #929684 }
		"baghira"	{ set labelBg #e5e8dc;  set pressedBg #dadcd0 }
		"highcolor"	{ set labelBg #b2b6a1;  set pressedBg #afb49f }
		"keramik"	{ set labelBg #c7cabb;  set pressedBg #adb1a1 }
		"phase"		{ set labelBg #a7b49f;  set pressedBg #929684 }
		"plastik"	{ set labelBg #acb19c;  set pressedBg #959987 }
		"qtcurve"	{ set labelBg #adb19e;  set pressedBg #939881 }
		"thinkeramik"	{ set labelBg #c1c4b6;  set pressedBg #a5a999 }
	    }
	}

	"#d9d9d9 #d9d9d9" {	;# color scheme "BeOS"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #eeeeee }
		"platinum"			      { set pressedBg #b4b4b4 }
		"baghira"	{ set labelBg #f2f2f2;  set pressedBg #e9e9e9 }
		"highcolor"	{ set labelBg #dcdcdc;  set pressedBg #d9d9d9 }
		"keramik"	{ set labelBg #e5e5e5;  set pressedBg #cdcdcd }
		"phase"		{ set labelBg #dadada;  set pressedBg #b4b4b4 }
		"plastik"	{ set labelBg #d6d6d6;  set pressedBg #b6b6b6 }
		"qtcurve"	{ set labelBg #d6d6d6;  set pressedBg #b5b5b5 }
		"thinkeramik"	{ set labelBg #dddddd;  set pressedBg #c5c5c5 }
	    }
	}

	"#9db9c8 #9db9c8" {	;# color scheme "Blue Slate"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #adcbdc }
		"platinum"			      { set pressedBg #8299a6 }
		"baghira"	{ set labelBg #ddeff6;  set pressedBg #d0e1ea }
		"highcolor"	{ set labelBg #9fbbcb;  set pressedBg #9db9c8 }
		"keramik"	{ set labelBg #baced9;  set pressedBg #a0b5c1 }
		"phase"		{ set labelBg #9db9c9;  set pressedBg #8299a6 }
		"plastik"	{ set labelBg #99b6c5;  set pressedBg #869fab }
		"qtcurve"	{ set labelBg #9bb7c6;  set pressedBg #7c9cad }
		"thinkeramik"	{ set labelBg #b5c8d2;  set pressedBg #98adb8 }
	    }
	}

	"#999999 #999999" {	;# color scheme "CDE"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #a8a8a8 }
		"platinum"			      { set pressedBg #7f7f7f }
		"baghira"	{ set labelBg #d5d5d5;  set pressedBg #cccccc }
		"highcolor"	{ set labelBg #9b9b9b;  set pressedBg #999999 }
		"keramik"	{ set labelBg #b7b7b7;  set pressedBg #9d9d9d }
		"phase"		{ set labelBg #999999;  set pressedBg #7f7f7f }
		"plastik"	{ set labelBg #979797;  set pressedBg #808080 }
		"qtcurve"	{ set labelBg #979797;  set pressedBg #7f7f7f }
		"thinkeramik"	{ set labelBg #b3b3b3;  set pressedBg #959595 }
	    }
	}

	"#426794 #426794" {	;# color scheme "Dark Blue"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #4871a2 }
		"platinum"			      { set pressedBg #37567b }
		"baghira"	{ set labelBg #8aafdc;  set pressedBg #82a3cc }
		"highcolor"	{ set labelBg #436895;  set pressedBg #426794 }
		"keramik"	{ set labelBg #7994b4;  set pressedBg #5b7799 }
		"phase"		{ set labelBg #426795;  set pressedBg #37567b }
		"plastik"	{ set labelBg #406592;  set pressedBg #36547a }
		"qtcurve"	{ set labelBg #416692;  set pressedBg #3c5676 }
		"thinkeramik"	{ set labelBg #7991af;  set pressedBg #546f91 }
	    }
	}

	"#d6cdbb #d6cdbb" {	;# color scheme "Desert Red"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #ebe1ce }
		"platinum"			      { set pressedBg #b2ab9c }
		"baghira"	{ set labelBg #f7f4ec;  set pressedBg #edeae0 }
		"highcolor"	{ set labelBg #d9d0be;  set pressedBg #d6cdbb }
		"keramik"	{ set labelBg #e3dcd0;  set pressedBg #cbc5b7 }
		"phase"		{ set labelBg #d6cdbb;  set pressedBg #b2ab9c }
		"plastik"	{ set labelBg #d3cbb8;  set pressedBg #bab3a3 }
		"qtcurve"	{ set labelBg #d4cbb8;  set pressedBg #b8ac94 }
		"thinkeramik"	{ set labelBg #dbd5ca;  set pressedBg #c2bbae }
	    }
	}

	"#4b7b82 #4b7b82" {	;# color scheme "Digital CDE"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #52878f }
		"platinum"			      { set pressedBg #3e666c }
		"baghira"	{ set labelBg #97c3c9;  set pressedBg #8eb6bc }
		"highcolor"	{ set labelBg #4b7d84;  set pressedBg #4b7b82 }
		"keramik"	{ set labelBg #80a2a7;  set pressedBg #62868c }
		"phase"		{ set labelBg #4b7b82;  set pressedBg #3e666c }
		"plastik"	{ set labelBg #49787f;  set pressedBg #3d666c }
		"qtcurve"	{ set labelBg #4a7980;  set pressedBg #416468 }
		"thinkeramik"	{ set labelBg #7f97a3;  set pressedBg #5a7e83 }
	    }
	}

	"#e6dedc #e4e4e4" {	;# color scheme "EveX"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #fdf4f2 }
		"platinum"			      { set pressedBg #bfb8b7 }
		"baghira"	{ set labelBg #f6f5f5;  set pressedBg #ededed }
		"highcolor"	{ set labelBg #e7e7e7;  set pressedBg #e4e4e4 }
		"keramik"	{ set labelBg #ededed;  set pressedBg #d6d6d6 }
		"phase"		{ set labelBg #e7e0dd;  set pressedBg #bfb8b7 }
		"plastik"	{ set labelBg #e2e2e2;  set pressedBg #c0bfbf }
		"qtcurve"	{ set labelBg #e4dcd9;  set pressedBg #c5b7b4 }
		"thinkeramik"	{ set labelBg #e6e1df;  set pressedBg #c7c9c7 }
	    }
	}

	"#ffffff #ffffff" {	;# color scheme "High Contrast Black Text"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #d4d4d4 }
		"baghira"	{ set labelBg #f5f5f5;  set pressedBg #f2f2f2 }
		"highcolor"	{ set labelBg #f5f5f5;  set pressedBg #ffffff }
		"keramik"	{ set labelBg #fbfbfb;  set pressedBg #e8e8e8 }
		"phase"		{ set labelBg #f7f7f7;  set pressedBg #d4d4d4 }
		"plastik"	{ set labelBg #f8f8f8;  set pressedBg #d8d8d8 }
		"qtcurve"	{ set labelBg #f6f6f6;  set pressedBg #d6d6d6 }
		"thinkeramik"	{ set labelBg #f4f4f4;  set pressedBg #e2e2e2 }
	    }
	}

	"#0000ff #0000ff" {	;# color scheme "High Contrast Yellow on Blue"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #1919ff }
		"platinum"			      { set pressedBg #0000d4 }
		"baghira"	{ set labelBg #4848ff;  set pressedBg #4646ff }
		"highcolor"	{ set labelBg #0e0ef5;  set pressedBg #0000ff }
		"keramik"	{ set labelBg #4949fb;  set pressedBg #2929e8 }
		"phase"		{ set labelBg #0909f7;  set pressedBg #0000d4 }
		"plastik"	{ set labelBg #0505f8;  set pressedBg #0000d8 }
		"qtcurve"	{ set labelBg #0909f2;  set pressedBg #0f0fc5 }
		"thinkeramik"	{ set labelBg #5151f4;  set pressedBg #2222e2 }
	    }
	}

	"#000000 #000000" {	;# color scheme "High Contrast White Text"
	    switch -- $style {  
		"light, 3rd revision"		      { set pressedBg #000000 }
		"platinum"			      { set pressedBg #000000 }
		"baghira"	{ set labelBg #818181;  set pressedBg #7f7f7f }
		"highcolor"	{ set labelBg #000000;  set pressedBg #000000 }
		"keramik"	{ set labelBg #494949;  set pressedBg #292929 }
		"phase"		{ set labelBg #000000;  set pressedBg #000000 }
		"plastik"	{ set labelBg #000000;  set pressedBg #000000 }
		"qtcurve"	{ set labelBg #000000;  set pressedBg #000000 }
		"thinkeramik"	{ set labelBg #4d4d4d;  set pressedBg #222222 }
	    }
	}

	"#f6f6ff #e4eeff" {	;# color scheme "Ice (FreddyK)"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #cdcdd4 }
		"baghira"	{ set labelBg #f6f6f6;  set pressedBg #f2f4f6 }
		"highcolor"	{ set labelBg #e8edf5;  set pressedBg #e4eeff }
		"keramik"	{ set labelBg #edf3fb;  set pressedBg #d6dde8 }
		"phase"		{ set labelBg #f3f3f7;  set pressedBg #cdcdd4 }
		"plastik"	{ set labelBg #e3eaf8;  set pressedBg #c0c9d8 }
		"qtcurve"	{ set labelBg #ebebfc;  set pressedBg #b3b3f0 }
		"thinkeramik"	{ set labelBg #f1f1f4;  set pressedBg #dbdbe2 }
	    }
	}

	"#c0c0c0 #c0c0c0" {	;# color schemes "KDE 1" and "Storm"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #d3d3d3 }
		"platinum"			      { set pressedBg #a0a0a0 }
		"baghira"	{ set labelBg #e9e9e9;  set pressedBg #dedede }
		"highcolor"	{ set labelBg #c2c2c2;  set pressedBg #c0c0c0 }
		"keramik"	{ set labelBg #d3d3d3;  set pressedBg #bababa }
		"phase"		{ set labelBg #c1c1c1;  set pressedBg #a0a0a0 }
		"plastik"	{ set labelBg #bebebe;  set pressedBg #a2a2a2 }
		"qtcurve"	{ set labelBg #bebebe;  set pressedBg #a0a0a0 }
		"thinkeramik"	{ set labelBg #cccccc;  set pressedBg #b2b2b2 }
	    }
	}

	"#dcdcdc #e4e4e4" {	;# color scheme "KDE 2"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #d3d3d3 }
		"platinum"			      { set pressedBg #b7b7b7 }
		"baghira"	{ set labelBg #f3f3f3;  set pressedBg #ededed }
		"highcolor"	{ set labelBg #e7e7e7;  set pressedBg #e4e4e4 }
		"keramik"	{ set labelBg #ededed;  set pressedBg #d6d6d6 }
		"phase"		{ set labelBg #dddddd;  set pressedBg #b7b7b7 }
		"plastik"	{ set labelBg #e2e2e2;  set pressedBg #c0c0c0 }
		"qtcurve"	{ set labelBg #d9d9d9;  set pressedBg #b8b8b8 }
		"thinkeramik"	{ set labelBg #dfdfdf;  set pressedBg #c7c7c7 }
	    }
	}

	"#eae9e8 #e6f0f9" {	;# color scheme "Keramik"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #c3c2c1 }
		"baghira"	{ set labelBg #f4f4f4;  set pressedBg #f1f3f5 }
		"highcolor"	{ set labelBg #eaeef2;  set pressedBg #e6f0f9 }
		"keramik"	{ set labelBg #eef4f8;  set pressedBg #d7dfe5 }
		"phase"		{ set labelBg #ebeae9;  set pressedBg #c3c2c1 }
		"plastik"	{ set labelBg #e3ecf3;  set pressedBg #c0c9d2 }
		"qtcurve"	{ set labelBg #e8e6e6;  set pressedBg #c5c3c1 }
		"thinkeramik"	{ set labelBg #e8e8e7;  set pressedBg #d2d1d0 }
	    }
	}

	"#eeeee6 #eeeade" {	;# color scheme "Keramik Emerald"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #fffffc }
		"platinum"			      { set pressedBg #c6c6bf }
		"baghira"	{ set labelBg #f6f6f6;  set pressedBg #f3f2ee }
		"highcolor"	{ set labelBg #eeeae1;  set pressedBg #eeeade }
		"keramik"	{ set labelBg #f3f1e8;  set pressedBg #dddad1 }
		"phase"		{ set labelBg #efefef;  set pressedBg #c6c6bf }
		"plastik"	{ set labelBg #ebe7dc;  set pressedBg #c9c6bc }
		"qtcurve"	{ set labelBg #ecece3;  set pressedBg #cdcdbb }
		"thinkeramik"	{ set labelBg #ebebe5;  set pressedBg #d5d5cf }
	    }
	}

	"#e9e9e9 #f6f6f6" {	;# color scheme "Keramik White"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #c2c2c2 }
		"baghira"	{ set labelBg #f4f4f4;  set pressedBg #f1f1f1 }
		"highcolor"	{ set labelBg #f1f1f1;  set pressedBg #f6f6f6 }
		"keramik"	{ set labelBg #f7f7f7;  set pressedBg #e3e3e3 }
		"phase"		{ set labelBg #eaeaea;  set pressedBg #c2c2c2 }
		"plastik"	{ set labelBg #f1f1f1;  set pressedBg #cfcfcf }
		"qtcurve"	{ set labelBg #e6e6e6;  set pressedBg #c3c3c3 }
		"thinkeramik"	{ set labelBg #e8e8e8;  set pressedBg #d1d1d1 }
	    }
	}

	"#ebe9e9 #f6f4f4" {	;# color scheme "Lipstik Noble"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #c3c1c1 }
		"baghira"	{ set labelBg #f4f4f4;  set pressedBg #f1f1f1 }
		"highcolor"	{ set labelBg #f1f0f0;  set pressedBg #f6f4f4 }
		"keramik"	{ set labelBg #f7f6f6;  set pressedBg #e3e1e1 }
		"phase"		{ set labelBg #f5f4f4;  set pressedBg #c3c1c1 }
		"plastik"	{ set labelBg #f2f2f2;  set pressedBg #d3d2d2 }
		"qtcurve"	{ set labelBg #e9e6e6;  set pressedBg #c5c1c1 }
		"thinkeramik"	{ set labelBg #e9e8e8;  set pressedBg #d3d1d1 }
	    }
	}

	"#eeeee6 #eeeade" {	;# color scheme "Lipstik Standard"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #fffffc }
		"platinum"			      { set pressedBg #c6c6bf }
		"baghira"	{ set labelBg #f6f6f6;  set pressedBg #f3f2ee }
		"highcolor"	{ set labelBg #eeeae1;  set pressedBg #eeeade }
		"keramik"	{ set labelBg #f3f1e8;  set pressedBg #dddad1 }
		"phase"		{ set labelBg #eeeade;  set pressedBg #c6c6bf }
		"plastik"	{ set labelBg #ebe7dc;  set pressedBg #ccc9c0 }
		"qtcurve"	{ set labelBg #ecece3;  set pressedBg #ccccba }
		"thinkeramik"	{ set labelBg #ebebe5;  set pressedBg #d5d5cf }
	    }
	}

	"#eeeff2 #f7faff" {	;# color scheme "Lipstik White"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #c6c7c9 }
		"baghira"	{ set labelBg #f5f5f5;  set pressedBg #f2f2f3 }
		"highcolor"	{ set labelBg #f1f2f5;  set pressedBg #f1faff }
		"keramik"	{ set labelBg #f8f9fb;  set pressedBg #e3e5e8 }
		"phase"		{ set labelBg #f4f5f7;  set pressedBg #c6c7c9 }
		"plastik"	{ set labelBg #f3f4f7;  set pressedBg #d0d3d8 }
		"qtcurve"	{ set labelBg #ebecf0;  set pressedBg #c4c7ce }
		"thinkeramik"	{ set labelBg #ebecee;  set pressedBg #d5d6d8 }
	    }
	}

	"#f4ddb2 #f4ddb2" {	;# color scheme "Media Peach"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ffebc7 }
		"platinum"			      { set pressedBg #cbb894 }
		"baghira"	{ set labelBg #fcfced;  set pressedBg #faf6df }
		"highcolor"	{ set labelBg #f0dbb6;  set pressedBg #f4ddb2 }
		"keramik"	{ set labelBg #f6e8c9;  set pressedBg #e1d0b0 }
		"phase"		{ set labelBg #f4ddb2;  set pressedBg #cbb894 }
		"plastik"	{ set labelBg #ffdbaf;  set pressedBg #d5c19c }
		"qtcurve"	{ set labelBg #f2dbaf;  set pressedBg #e0bd7f }
		"thinkeramik"	{ set labelBg #efe0c3;  set pressedBg #d9c8a7 }
	    }
	}

	"#a8a8a8 #a8a8a8" {	;# color scheme "Next"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #b8b8b8 }
		"platinum"			      { set pressedBg #8c8c8c }
		"baghira"	{ set labelBg #dedede;  set pressedBg #d3d3d3 }
		"highcolor"	{ set labelBg #aaaaaa;  set pressedBg #a8a8a8 }
		"keramik"	{ set labelBg #c2c2c2;  set pressedBg #a8a8a8 }
		"phase"		{ set labelBg #a9a9a9;  set pressedBg #8c8c8c }
		"plastik"	{ set labelBg #a5a5a5;  set pressedBg #898989 }
		"qtcurve"	{ set labelBg #a6a6a6;  set pressedBg #8d8d8d }
		"thinkeramik"	{ set labelBg #bdbdbd;  set pressedBg #a0a0a0 }
	    }
	}

	"#d6d6d6 #d6d6d6" {	;# color scheme "Pale Gray"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ebebeb }
		"platinum"			      { set pressedBg #b2b2b2 }
		"baghira"	{ set labelBg #f2f2f2;  set pressedBg #e8e8e8 }
		"highcolor"	{ set labelBg #d9d9d9;  set pressedBg #d6d6d6 }
		"keramik"	{ set labelBg #e3e3e3;  set pressedBg #cbcbcb }
		"phase"		{ set labelBg #d6d6d6;  set pressedBg #b2b2b2 }
		"plastik"	{ set labelBg #d3d3d3;  set pressedBg #bababa }
		"qtcurve"	{ set labelBg #d4d4d4;  set pressedBg #b1b1b1 }
		"thinkeramik"	{ set labelBg #dbdbdb;  set pressedBg #c2c2c2 }
	    }
	}

	"#efefef #dddfe4" {	;# color scheme "Plastik"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #c7c7c7 }
		"baghira"	{ set labelBg #f5f5f5;  set pressedBg #ececee }
		"highcolor"	{ set labelBg #e0e1e7;  set pressedBg #dddfe4 }
		"keramik"	{ set labelBg #e8e9ed;  set pressedBg #d0d2d6 }
		"phase"		{ set labelBg #dee0e5;  set pressedBg #c7c7c7 }
		"plastik"	{ set labelBg #dbdde2;  set pressedBg #babcc0 }
		"qtcurve"	{ set labelBg #ececec;  set pressedBg #c9c9c9 }
		"thinkeramik"	{ set labelBg #ececec;  set pressedBg #d6d6d6 }
	    }
	}

	"#d3c5be #aba09a" {	;# color scheme "Point Reyes Green"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #e8d9d1 }
		"platinum"			      { set pressedBg #afa49e }
		"baghira"	{ set labelBg #f5efed;  set pressedBg #d7d0cd }
		"highcolor"	{ set labelBg #ada29d;  set pressedBg #aba09a }
		"keramik"	{ set labelBg #c4bcb8;  set pressedBg #aba29e }
		"phase"		{ set labelBg #d3c5be;  set pressedBg #afa49e }
		"plastik"	{ set labelBg #ab9f99;  set pressedBg #9b908a }
		"qtcurve"	{ set labelBg #d1c3bc;  set pressedBg #b3a197 }
		"thinkeramik"	{ set labelBg #d9d0cc;  set pressedBg #c0b6b1 }
	    }
	}

	"#eed8ae #eed8ae" {	;# color scheme "Pumpkin"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ffe0c0 }
		"platinum"			      { set pressedBg #c6b390 }
		"baghira"	{ set labelBg #fcfbea;  set pressedBg #f9f4dd }
		"highcolor"	{ set labelBg #eed8b1;  set pressedBg #eed8ae }
		"keramik"	{ set labelBg #f3e4c6;  set pressedBg #ddcdad }
		"phase"		{ set labelBg #eed8ae;  set pressedBg #c6b390 }
		"plastik"	{ set labelBg #ebd5ac;  set pressedBg #cfbc96 }
		"qtcurve"	{ set labelBg #ebd6ab;  set pressedBg #d7b980 }
		"thinkeramik"	{ set labelBg #ebdcc0;  set pressedBg #d5c4a4 }
	    }
	}

	"#d4d0c8 #d4d0c8" {	;# color scheme "Redmond 2000"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #e9e5dc }
		"platinum"			      { set pressedBg #b0ada6 }
		"baghira"	{ set labelBg #f3f2ef;  set pressedBg #eae8e4 }
		"highcolor"	{ set labelBg #d7d3cb;  set pressedBg #d4d0c8 }
		"keramik"	{ set labelBg #e1ded9;  set pressedBg #cac7c1 }
		"phase"		{ set labelBg #d5d1c9;  set pressedBg #b0ada6 }
		"plastik"	{ set labelBg #d2cdc5;  set pressedBg #b2afa7 }
		"qtcurve"	{ set labelBg #d2cdc6;  set pressedBg #b4afa4 }
		"thinkeramik"	{ set labelBg #dad7d2;  set pressedBg #c1beb8 }
	    }
	}

	"#c3c3c3 #c3c3c3" {	;# color scheme "Redmond 95"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #d6d6d6 }
		"platinum"			      { set pressedBg #a2a2a2 }
		"baghira"	{ set labelBg #eaeaea;  set pressedBg #dfdfdf }
		"highcolor"	{ set labelBg #c5c5c5;  set pressedBg #c3c3c3 }
		"keramik"	{ set labelBg #d5d5d5;  set pressedBg #bdbdbd }
		"phase"		{ set labelBg #c4c4c4;  set pressedBg #a2a2a2 }
		"plastik"	{ set labelBg #c1c1c1;  set pressedBg #a3a3a3 }
		"qtcurve"	{ set labelBg #c1c1c1;  set pressedBg #a3a3a3 }
		"thinkeramik"	{ set labelBg #cecece;  set pressedBg #b5b5b5 }
	    }
	}

	"#eeeee6 #eeeade" {	;# color scheme "Redmond XP"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #fffffc }
		"platinum"			      { set pressedBg #c6c6bf }
		"baghira"	{ set labelBg #f6f6f6;  set pressedBg #f3f2ee }
		"highcolor"	{ set labelBg #eeeae1;  set pressedBg #eeeade }
		"keramik"	{ set labelBg #f3f1e8;  set pressedBg #dddad1 }
		"phase"		{ set labelBg #efefe7;  set pressedBg #c6c6bf }
		"plastik"	{ set labelBg #ebe7dc;  set pressedBg #c9c6bc }
		"qtcurve"	{ set labelBg #ecece3;  set pressedBg #cdcdbb }
		"thinkeramik"	{ set labelBg #ebebe5;  set pressedBg #d5d5cf }
	    }
	}

	"#aeb2c3 #aeb2c3" {	;# color scheme "Solaris"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #bfc3d6 }
		"platinum"			      { set pressedBg #9194a2 }
		"baghira"	{ set labelBg #e4e7ef;  set pressedBg #d9dbe4 }
		"highcolor"	{ set labelBg #b0b4c5;  set pressedBg #aeb2c3 }
		"keramik"	{ set labelBg #c6c9d5;  set pressedBg #adb0bd }
		"phase"		{ set labelBg #aeb2c3;  set pressedBg #9194a2 }
		"plastik"	{ set labelBg #abafc0;  set pressedBg #969aa9 }
		"qtcurve"	{ set labelBg #acb0c1;  set pressedBg #8d91a5 }
		"thinkeramik"	{ set labelBg #c0c3ce;  set pressedBg #a5a7b5 }
	    }
	}

	"#eeeaee #e6f0f9" {	;# color scheme "SuSE" old
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #c6c3c6 }
		"baghira"	{ set labelBg #f5f5f5;  set pressedBg #f1f3f5 }
		"highcolor"	{ set labelBg #eaeef2;  set pressedBg #e6f0f9 }
		"keramik"	{ set labelBg #eef4f8;  set pressedBg #d7dfe5 }
		"phase"		{ set labelBg #efecef;  set pressedBg #c6c3c6 }
		"plastik"	{ set labelBg #e3ecf3;  set pressedBg #c0c9d2 }
		"qtcurve"	{ set labelBg #ebe7eb;  set pressedBg #cac1ca }
		"thinkeramik"	{ set labelBg #ebe8eb;  set pressedBg #d5d2d5 }
	    }
	}

	"#eeeeee #f4f4f4" {	;# color scheme "SuSE" new
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #c6c6c6 }
		"baghira"	{ set labelBg #f5f5f5;  set pressedBg #f1f1f1 }
		"highcolor"	{ set labelBg #f0f0f0;  set pressedBg #f4f4f4 }
		"keramik"	{ set labelBg #f6f6f6;  set pressedBg #e1e1e1 }
		"phase"		{ set labelBg #efefef;  set pressedBg #c6c6c6 }
		"plastik"	{ set labelBg #f0f0f0;  set pressedBg #cdcdcd }
		"qtcurve"	{ set labelBg #ebebeb;  set pressedBg #c7c7c7 }
		"thinkeramik"	{ set labelBg #ebebeb;  set pressedBg #d5d5d5 }
	    }
	}

	"#eaeaea #eaeaea" {	;# color scheme "SUSE-kdm"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #c3c3c3 }
		"baghira"	{ set labelBg #f4f4f4;  set pressedBg #efefef }
		"highcolor"	{ set labelBg #ececec;  set pressedBg #eaeaea }
		"keramik"	{ set labelBg #f1f1f1;  set pressedBg #dadada }
		"phase"		{ set labelBg #ebebeb;  set pressedBg #c3c3c3 }
		"plastik"	{ set labelBg #e7e7e7;  set pressedBg #c6c6c6 }
		"qtcurve"	{ set labelBg #e7e7e7;  set pressedBg #c4c4c4 }
		"thinkeramik"	{ set labelBg #e8e8e8;  set pressedBg #d2d2d2 }
	    }
	}

	"#d3d3d3 #d3d3d3" {	;# color scheme "System"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #e8e8e8 }
		"platinum"			      { set pressedBg #afafaf }
		"baghira"	{ set labelBg #f0f0f0;  set pressedBg #e6e6e6 }
		"highcolor"	{ set labelBg #d6d6d6;  set pressedBg #d3d3d3 }
		"keramik"	{ set labelBg #e1e1e1;  set pressedBg #c9c9c9 }
		"phase"		{ set labelBg #d2d2d2;  set pressedBg #afafaf }
		"plastik"	{ set labelBg #d0d0d0;  set pressedBg #b9b9b9 }
		"qtcurve"	{ set labelBg #d1d1d1;  set pressedBg #aeaeae }
		"thinkeramik"	{ set labelBg #d9d9d9;  set pressedBg #c0c0c0 }
	    }
	}

	"#e6e6de #f0f0ef" {	;# color scheme "Thin Keramik" old
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #fdfdf4 }
		"platinum"			      { set pressedBg #bfbfb8 }
		"baghira"	{ set labelBg #f6f6f5;  set pressedBg #f0f0f0 }
		"highcolor"	{ set labelBg #eeeeee;  set pressedBg #f0f0ef }
		"keramik"	{ set labelBg #f4f4f4;  set pressedBg #dfdfde }
		"phase"		{ set labelBg #e7e7df;  set pressedBg #bfbfb8 }
		"plastik"	{ set labelBg #ededeb;  set pressedBg #cbcbc9 }
		"qtcurve"	{ set labelBg #e3e3db;  set pressedBg #c4c4b6 }
		"thinkeramik"	{ set labelBg #e6e6e1;  set pressedBg #cfcfc9 }
	    }
	}

	"#edede1 #f6f6e9" {	;# color scheme "Thin Keramik" new
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #fffff7 }
		"platinum"			      { set pressedBg #c5c5bb }
		"baghira"	{ set labelBg #f6f6f5;  set pressedBg #f3f3f1 }
		"highcolor"	{ set labelBg #f1f1ec;  set pressedBg #f6f6e9 }
		"keramik"	{ set labelBg #f7f7f0;  set pressedBg #e3e3da }
		"phase"		{ set labelBg #edede1;  set pressedBg #c5c5bb }
		"plastik"	{ set labelBg #f4f4e6;  set pressedBg #ddddd0 }
		"qtcurve"	{ set labelBg #ebebde;  set pressedBg #cbcbb3 }
		"thinkeramik"	{ set labelBg #eaeae3;  set pressedBg #d4d4cb }
	    }
	}

	"#f6f5e8 #eeeade" {	;# color scheme "Thin Keramik II"
	    switch -- $style {
		"light, 3rd revision"		      { set pressedBg #ffffff }
		"platinum"			      { set pressedBg #cdccc1 }
		"baghira"	{ set labelBg #f7f7f7;  set pressedBg #f3f2ee }
		"highcolor"	{ set labelBg #eeeae1;  set pressedBg #eeeade }
		"keramik"	{ set labelBg #f3f1e8;  set pressedBg #dddad1 }
		"phase"		{ set labelBg #f3f2e9;  set pressedBg #cdccc1 }
		"plastik"	{ set labelBg #ebe7dc;  set pressedBg #c9c6bc }
		"qtcurve"	{ set labelBg #f4f2e5;  set pressedBg #dbd8b6 }
		"thinkeramik"	{ set labelBg #f1f1e8;  set pressedBg #dbdad0 }
	    }
	}

	"#d4d7d0 #babdb7" {	;# color scheme "Honeycomb"
	    switch -- $style {
		"cde" -
		"motif"				      { set pressedBg #b1b4ae }
		"plastique"	{ set labelBg #b8bbb5;  set pressedBg #c1c4be }
	    }
	}

	"#ebe2d2 #f7f2e8" {	;# color scheme "Norway"
	    switch -- $style {
		"cde" -
		"motif"				      { set pressedBg #c8bba3 }
		"plastique"	{ set labelBg #f4f0e6;  set pressedBg #d6cfbf }
	    }
	}

	"#302f2f #403f3e" {	;# color scheme "Obsidian Coast"
	    switch -- $style {
		"cde" -
		"motif"				      { set pressedBg #2a2929 }
		"plastique"	{ set labelBg #3f3e3d;  set pressedBg #2b2a2a }
	    }
	}

	"#d6d2d0 #dfdcd9" {	;# color schemes "Oxygen" and "Standard"
	    switch -- $style {
		"cde" -
		"motif"				      { set pressedBg #b6aeaa }
		"plastique"	{ set labelBg #dddad7;  set pressedBg #c3bfbe }
	    }
	}

	"#e0dfde #e8e7e6" {	;# c. s. "Oxygen Cold" and "Oxygen-Molecule 3.0"
	    switch -- $style {
		"cde" -
		"motif"				      { set pressedBg #bbb9b8 }
		"plastique"	{ set labelBg #e6e5e4;  set pressedBg #cdcccb }
	    }
	}

	"#e0dfd8 #e8e7df" {	;# color scheme "Steel"
	    switch -- $style {
		"cde" -
		"motif"				      { set pressedBg #babab4 }
		"plastique"	{ set labelBg #e6e5dd;  set pressedBg #cdccc5 }
	    }
	}

	"#494e58 #525863" {	;# color scheme "Wonton Soup"
	    switch -- $style {
		"cde" -
		"motif"				      { set pressedBg #3f444c }
		"plastique"	{ set labelBg #515762;  set pressedBg #424650 }
	    }
	}

	"#fcfcfc #ffffff" {	;# color scheme "Zion"
	    switch -- $style {
		"cde" -
		"motif"				      { set pressedBg #dedede }
		"plastique"	{ set labelBg #f9f9f9;  set pressedBg #e5e5e5 }
	    }
	}

	"#101010 #000000" {	;# color scheme "Zion (Reversed)"
	    switch -- $style {
		"cde" -
		"motif"				      { set pressedBg #5e5e5e }
		"plastique"	{ set labelBg #000000;  set pressedBg #0e0e0e }
	    }
	}
    }

    #
    # For some Qt styles the label colors are independent of the color scheme:
    #
    switch -- $style {
	"acqua" {
	    set labelBg #e7e7e7;  set labelFg #000000;  set pressedBg #8fbeec
	}

	"gtk+" {
	    set labelBg #e8e7e6;			set pressedBg $labelBg
	}

	"kde_xp" {
	    set labelBg #ebeadb;  set labelFg #000000;  set pressedBg #faf8f3
	}

	"lipstik" -
	"oxygen" {
	    set labelBg $bg;				set pressedBg $labelBg
	}

	"marble" {
	    set labelBg #cccccc;  set labelFg $fg;      set pressedBg $labelBg
	}

	"riscos" {
	    set labelBg #dddddd;  set labelFg #000000;  set pressedBg $labelBg
	}

	"system" -
	"systemalt" {
	    set labelBg #cbcbcb;  set labelFg #000000;  set pressedBg $labelBg
	}
    }

    #
    # The stripe background color is specified
    # by a global KDE configuration option:
    #
    if {[info exists ::env(KDE_SESSION_VERSION)] &&
	$::env(KDE_SESSION_VERSION) ne ""} {
	set val [getKdeConfigVal "Colors:View" "BackgroundAlternate"]
    } else {
	set val [getKdeConfigVal "General" "alternateBackground"]
    }
    if {$val eq "" || [string index $val 0] eq "#"} {
	set stripeBg $val
    } elseif {[scan $val "%d,%d,%d" r g b] == 3} {
	set stripeBg [format "#%02x%02x%02x" $r $g $b]
    } else {
	set stripeBg ""
    }

    #
    # The arrow color and style depend mainly on the current Qt style:
    #
    switch -- $style {
	"highcontrast" -
	"light, 2nd revision" -
	"light, 3rd revision" -
	"lipstik" -
	"phase" -
	"plastik"	{ set arrowColor $labelFg; set arrowStyle flat7x4 }

	"baghira"	{ set arrowColor $labelFg; set arrowStyle flat7x7 }

	"cleanlooks" -
	"gtk+" -
	"oxygen"	{ set arrowColor $labelFg; set arrowStyle flatAngle9x6 }

	"phase"		{ set arrowColor $labelFg; set arrowStyle flat6x4 }

	"qtcurve"	{ set arrowColor $labelFg; set arrowStyle flatAngle7x5 }

	"keramik" -
	"thinkeramik"	{ set arrowColor $labelFg; set arrowStyle flat8x5 }

	default		{ set arrowColor "";	   set arrowStyle sunken12x11 }
    }

    #
    # The tree style depends on the current Qt style:
    #
    switch -- $style {
	"baghira" -
	"cde" -
	"motif"		{ set treeStyle baghira }
	"gtk+"		{ set treeStyle gtk }
	"oxygen"	{ set treeStyle oxygen2 }
	"phase"		{ set treeStyle phase }
	"plastik"	{ set treeStyle plastik }
	"plastique"	{ set treeStyle plastique }
	"qtcurve"	{ set treeStyle klearlooks }
	default		{ set treeStyle winnative }
    }

    variable themeDefaults
    array set themeDefaults [list \
	-background		$tableBg \
	-foreground		$tableFg \
	-disabledforeground	$tableDisFg \
	-stripebackground	$stripeBg \
	-selectbackground	$selectBg \
	-selectforeground	$selectFg \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelbackground	$labelBg \
	-labeldeactivatedBg	$labelBg \
	-labeldisabledBg	$labelBg \
	-labelactiveBg		$labelBg \
	-labelpressedBg		$pressedBg \
	-labelforeground	$labelFg \
	-labeldisabledFg	$labelDisFg \
	-labelactiveFg		$labelFg \
	-labelpressedFg		$labelFg \
	-labelfont		TkDefaultFont \
	-labelborderwidth	4 \
	-labelpady		0 \
	-arrowcolor		$arrowColor \
	-arrowstyle		$arrowStyle \
	-treestyle		$treeStyle \
    ]
}

#------------------------------------------------------------------------------
# tablelist::vistaTheme
#------------------------------------------------------------------------------
proc tablelist::vistaTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		SystemWindow \
	-foreground		SystemWindowText \
	-disabledforeground	SystemDisabledText \
	-stripebackground	"" \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelforeground	SystemButtonText \
	-labeldisabledFg	SystemDisabledText \
	-labelactiveFg		SystemButtonText \
	-labelpressedFg		SystemButtonText \
	-labelfont		TkDefaultFont \
    ]

    switch [winfo rgb . SystemHighlight] {
	"13107 39321 65535" {					;# Aero
	    set selectFg	SystemWindowText
	    set labelBd		4
	    set labelPadY	4

	    variable scalingpct
	    if {$::tcl_platform(osVersion) < 6.2} {		;# Win Vista/7
		set labelBg	#ffffff
		set activeBg	#e3f7ff
		set pressedBg	#Bce4f9
		set arrowColor	#569bc0

		switch $scalingpct {
		    100 { set arrowStyle	photo7x4 }
		    125 { set arrowStyle	photo9x5 }
		    150 { set arrowStyle	photo11x6 }
		    200 { set arrowStyle	photo15x8 }
		}
	    } elseif {$::tcl_platform(osVersion) < 10.0} {	;# Win 8
		set labelBg	#fcfcfc
		set activeBg	#f4f9ff
		set pressedBg	#f9fafb
		set arrowColor	#569bc0

		switch $scalingpct {
		    100 { set arrowStyle	photo7x4 }
		    125 { set arrowStyle	photo9x5 }
		    150 { set arrowStyle	photo11x6 }
		    200 { set arrowStyle	photo15x8 }
		}
	    } else {						;# Win 10
		set labelBg	#ffffff
		set activeBg	#d9ebf9
		set pressedBg	#bcdcf4
		set arrowColor	#595959

		switch $scalingpct {
		    100 { set arrowStyle	flatAngle7x4 }
		    125 { set arrowStyle	flatAngle9x5 }
		    150 { set arrowStyle	flatAngle11x6 }
		    200 { set arrowStyle	flatAngle15x8 }
		}
	    }

	    if {$::tcl_platform(osVersion) == 6.0} {		;# Win Vista
		set selectBg	#d8effb
		set treeStyle	vistaAero
	    } elseif {$::tcl_platform(osVersion) == 6.1} {	;# Win 7
		set selectBg	#cee2fc
		set treeStyle	win7Aero
	    } elseif {$::tcl_platform(osVersion) < 10.0} {	;# Win 8
		set selectBg	#cbe8f6
		set treeStyle	win7Aero
	    } else {						;# Win 10
		set selectBg	#cce8ff
		set treeStyle	win10
	    }
	}

	default {						;# Win Classic
	    set selectBg	SystemHighlight
	    set selectFg	SystemHighlightText
	    set labelBg		SystemButtonFace
	    set activeBg	SystemButtonFace
	    set pressedBg	SystemButtonFace
	    set labelBd		2
	    set labelPadY	0
	    set arrowColor	SystemButtonShadow

	    variable scalingpct
	    switch $scalingpct {
		100 { set arrowStyle	flat7x4 }
		125 { set arrowStyle	flat9x5 }
		150 { set arrowStyle	flat11x6 }
		200 { set arrowStyle	flat15x8 }
	    }

	    if {$::tcl_platform(osVersion) == 6.0} {		;# Win Vista
		set treeStyle	vistaClassic
	    } else {						;# Win 7/8
		set treeStyle	win7Classic
	    }
	}
    }

    array set themeDefaults [list \
	-selectbackground	$selectBg \
	-selectforeground	$selectFg \
	-labelbackground	$labelBg \
	-labeldeactivatedBg	$labelBg \
	-labeldisabledBg	$labelBg \
	-labelactiveBg		$activeBg \
	-labelpressedBg		$pressedBg \
	-labelborderwidth	$labelBd \
	-labelpady		$labelPadY \
	-arrowcolor		$arrowColor \
	-arrowstyle		$arrowStyle \
	-treestyle		$treeStyle \
    ]
}

#------------------------------------------------------------------------------
# tablelist::winnativeTheme
#------------------------------------------------------------------------------
proc tablelist::winnativeTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		SystemWindow \
	-foreground		SystemWindowText \
	-disabledforeground	SystemDisabledText \
	-stripebackground	"" \
	-selectbackground	SystemHighlight \
	-selectforeground	SystemHighlightText \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelbackground	SystemButtonFace \
	-labeldeactivatedBg	SystemButtonFace \
	-labeldisabledBg	SystemButtonFace \
	-labelactiveBg		SystemButtonFace \
	-labelpressedBg		SystemButtonFace \
	-labelforeground	SystemButtonText \
	-labeldisabledFg	SystemDisabledText \
	-labelactiveFg		SystemButtonText \
	-labelpressedFg		SystemButtonText \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		0 \
	-arrowcolor		"" \
	-arrowstyle		sunken8x7 \
	-treestyle		winnative \
    ]
}

#------------------------------------------------------------------------------
# tablelist::winxpblueTheme
#------------------------------------------------------------------------------
proc tablelist::winxpblueTheme {} {
    variable themeDefaults
    array set themeDefaults [list \
	-background		white \
	-foreground		black \
	-disabledforeground	#565248 \
	-stripebackground	"" \
	-selectbackground	#4a6984 \
	-selectforeground	#ffffff \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelbackground	#ece9d8 \
	-labeldeactivatedBg	#ece9d8 \
	-labeldisabledBg	#e3e1dd \
	-labelactiveBg		#c1d2ee \
	-labelpressedBg		#bab5ab \
	-labelforeground	black \
	-labeldisabledFg	#565248 \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		1 \
	-arrowcolor		#4d6185 \
	-arrowstyle		flat7x4 \
	-treestyle		winxpBlue \
    ]
}

#------------------------------------------------------------------------------
# tablelist::xpnativeTheme
#------------------------------------------------------------------------------
proc tablelist::xpnativeTheme {} {
    variable xpStyle
    variable themeDefaults
    array set themeDefaults [list \
	-background		SystemWindow \
	-foreground		SystemWindowText \
	-disabledforeground	SystemDisabledText \
	-stripebackground	"" \
	-selectborderwidth	0 \
	-font			TkTextFont \
	-labelforeground	SystemButtonText \
	-labeldisabledFg	SystemDisabledText \
	-labelactiveFg		SystemButtonText \
	-labelpressedFg		SystemButtonText \
	-labelfont		TkDefaultFont \
    ]

    switch [winfo rgb . SystemHighlight] {
	"12593 27242 50629" {					;# Win XP Blue
	    set xpStyle		1
	    set selectBg	SystemHighlight
	    set selectFg	SystemHighlightText
	    set labelBg		#ebeadb
	    set activeBg	#faf8f3
	    set pressedBg	#dedfd8
	    set labelBd		4
	    set labelPadY	4
	    set arrowColor	#aca899
	    set arrowStyle	flat9x5
	    set treeStyle	winxpBlue

	    if {[info exists tile::version] &&
		[string compare $tile::version 0.7] < 0} {
		set labelBd 0
	    }
	}

	"37779 41120 28784" {					;# Win XP Olive
	    set xpStyle		1
	    set selectBg	SystemHighlight
	    set selectFg	SystemHighlightText
	    set labelBg		#ebeadb
	    set activeBg	#faf8f3
	    set pressedBg	#dedfd8
	    set labelBd		4
	    set labelPadY	4
	    set arrowColor	#aca899
	    set arrowStyle	flat9x5
	    set treeStyle	winxpOlive

	    if {[info exists tile::version] &&
		[string compare $tile::version 0.7] < 0} {
		set labelBd 0
	    }
	}

	"45746 46260 49087" {					;# Win XP Silver
	    set xpStyle		1
	    set selectBg	SystemHighlight
	    set selectFg	SystemHighlightText
	    set labelBg		#f9fafd
	    set activeBg	#fefefe
	    set pressedBg	#ececf3
	    set labelBd		4
	    set labelPadY	4
	    set arrowColor	#aca899
	    set arrowStyle	flat9x5
	    set treeStyle	winxpSilver

	    if {[info exists tile::version] &&
		[string compare $tile::version 0.7] < 0} {
		set labelBd 0
	    }
	}

	"13107 39321 65535" {					;# Aero
	    set selectFg	SystemWindowText
	    set xpStyle		0
	    set labelBd		4
	    set labelPadY	4

	    variable scalingpct
	    if {$::tcl_platform(osVersion) < 6.2} {		;# Win Vista/7
		set labelBg	#ffffff
		set activeBg	#e3f7ff
		set pressedBg	#Bce4f9
		set arrowColor	#569bc0

		switch $scalingpct {
		    100 { set arrowStyle	photo7x4 }
		    125 { set arrowStyle	photo9x5 }
		    150 { set arrowStyle	photo11x6 }
		    200 { set arrowStyle	photo15x8 }
		}
	    } elseif {$::tcl_platform(osVersion) < 10.0} {	;# Win 8
		set labelBg	#fcfcfc
		set activeBg	#f4f9ff
		set pressedBg	#f9fafb
		set arrowColor	#569bc0

		switch $scalingpct {
		    100 { set arrowStyle	photo7x4 }
		    125 { set arrowStyle	photo9x5 }
		    150 { set arrowStyle	photo11x6 }
		    200 { set arrowStyle	photo15x8 }
		}
	    } else {						;# Win 10
		set labelBg	#ffffff
		set activeBg	#d9ebf9
		set pressedBg	#bcdcf4
		set arrowColor	#595959

		switch $scalingpct {
		    100 { set arrowStyle	flatAngle7x4 }
		    125 { set arrowStyle	flatAngle9x5 }
		    150 { set arrowStyle	flatAngle11x6 }
		    200 { set arrowStyle	flatAngle15x8 }
		}
	    }

	    if {$::tcl_platform(osVersion) == 6.0} {		;# Win Vista
		set selectBg	#d8effb
		set treeStyle	vistaAero
	    } elseif {$::tcl_platform(osVersion) == 6.1} {	;# Win 7
		set selectBg	#cee2fc
		set treeStyle	win7Aero
	    } elseif {$::tcl_platform(osVersion) < 10.0} {	;# Win 8
		set selectBg	#cbe8f6
		set treeStyle	win7Aero
	    } else {						;# Win 10
		set selectBg	#cce8ff
		set treeStyle	win10
	    }
	}

	default {						;# Win Classic
	    set selectBg	SystemHighlight
	    set selectFg	SystemHighlightText
	    set xpStyle		0
	    set labelBg		SystemButtonFace
	    set activeBg	SystemButtonFace
	    set pressedBg	SystemButtonFace
	    set labelBd		2
	    set labelPadY	0
	    set arrowColor	SystemButtonShadow

	    variable scalingpct
	    switch $scalingpct {
		100 { set arrowStyle	flat7x4 }
		125 { set arrowStyle	flat9x5 }
		150 { set arrowStyle	flat11x6 }
		200 { set arrowStyle	flat15x8 }
	    }

	    if {$::tcl_platform(osVersion) == 6.0} {		;# Win Vista
		set treeStyle	vistaClassic
	    } else {						;# Win 7/8
		set treeStyle	win7Classic
	    }
	}
    }

    array set themeDefaults [list \
	-selectbackground	$selectBg \
	-selectforeground	$selectFg \
	-labelbackground	$labelBg \
	-labeldeactivatedBg	$labelBg \
	-labeldisabledBg	$labelBg \
	-labelactiveBg		$activeBg \
	-labelpressedBg		$pressedBg \
	-labelborderwidth	$labelBd \
	-labelpady		$labelPadY \
	-arrowcolor		$arrowColor \
	-arrowstyle		$arrowStyle \
	-treestyle		$treeStyle \
    ]
}

#
# Private procedures performing RGB <-> HSV conversions
# =====================================================
#

#------------------------------------------------------------------------------
# tablelist::rgb2hsv
#
# Converts the specified RGB value to HSV.  The arguments are assumed to be
# integers in the interval [0, 65535].  The return value is a list of the form
# {h s v}, where h in [0.0, 360.0) and s, v in [0.0, 1.0].
#------------------------------------------------------------------------------
proc tablelist::rgb2hsv {r g b} {
    set r [expr {$r/65535.0}]
    set g [expr {$g/65535.0}]
    set b [expr {$b/65535.0}]

    #
    # Compute the value component
    #
    set sortedList [lsort -real [list $r $g $b]]
    set v [lindex $sortedList end]
    set dist [expr {$v - [lindex $sortedList 0]}]

    #
    # Compute the saturation component
    #
    if {$v == 0.0} {
	set s 0.0
    } else {
	set s [expr {$dist/$v}]
    }

    #
    # Compute the hue component
    #
    if {$s == 0.0} {
	set h 0.0
    } else {
	set rc [expr {($v - $r)/$dist}]
	set gc [expr {($v - $g)/$dist}]
	set bc [expr {($v - $b)/$dist}]

	if {$v == $r} {
	    set h [expr {$bc - $gc}]
	} elseif {$v == $g} {
	    set h [expr {2 + $rc - $bc}]
	} else {
	    set h [expr {4 + $gc - $rc}]
	}
	set h [expr {$h*60}]
	if {$h < 0.0} {
	    set h [expr {$h + 360.0}]
	} elseif {$h >= 360.0} {
	    set h 0.0
	}
    }

    return [list $h $s $v]
}

#------------------------------------------------------------------------------
# tablelist::hsv2rgb
#
# Converts the specified HSV value to RGB.  The arguments are assumed to fulfil
# the conditions: h in [0.0, 360.0) and s, v in [0.0, 1.0].  The return value
# is a list of the form {r g b}, where r, g, and b are integers in the interval
# [0, 65535].
#------------------------------------------------------------------------------
proc tablelist::hsv2rgb {h s v} {
    set h [expr {$h/60.0}]
    set f [expr {$h - floor($h)}]

    set p1 [expr {round(65535.0*$v*(1 - $s))}]
    set p2 [expr {round(65535.0*$v*(1 - $s*$f))}]
    set p3 [expr {round(65535.0*$v*(1 - $s*(1 - $f)))}]

    set v  [expr {round(65535.0*$v)}]

    switch [expr {int($h)}] {
	0 { return [list $v  $p3 $p1] }
	1 { return [list $p2 $v  $p1] }
	2 { return [list $p1 $v  $p3] }
	3 { return [list $p1 $p2 $v ] }
	4 { return [list $p3 $p1 $v ] }
	5 { return [list $v  $p1 $p2] }
    }
}

#
# Private procedures related to global KDE configuration options
# ==============================================================
#

#------------------------------------------------------------------------------
# tablelist::getKdeConfigVal
#
# Returns the value of the global KDE configuration option identified by the
# given group (section) and key.
#------------------------------------------------------------------------------
proc tablelist::getKdeConfigVal {group key} {
    variable kdeDirList

    if {![info exists kdeDirList]} {
	makeKdeDirList 
    }

    #
    # Search for the entry corresponding to the given group and key in
    # the file "share/config/kdeglobals" within the KDE directories
    #
    foreach dir $kdeDirList {
	set fileName [file join $dir "share/config/kdeglobals"]
	if {[set val [readKdeConfigVal $fileName $group $key]] ne ""} {
	    return $val
	}
    }
    return ""
}

#------------------------------------------------------------------------------
# tablelist::makeKdeDirList
#
# Builds the list of the directories to be considered when searching for global
# KDE configuration options.
#------------------------------------------------------------------------------
proc tablelist::makeKdeDirList {} {
    variable kdeDirList {}

    if {[info exists ::env(KDE_SESSION_VERSION)]} {
	set ver $::env(KDE_SESSION_VERSION)
    } else {
	set ver ""
    }

    if {[info exists ::env(USER)] && $::env(USER) eq "root"} {
	set name "KDEROOTHOME"
    } else {
	set name "KDEHOME"
    }
    if {[info exists ::env($name)] && $::env($name) ne ""} {
	set localKdeDir [file normalize $::env($name)]
    } elseif {[info exists ::env(HOME)] && $::env(HOME) ne ""} {
	set localKdeDir [file normalize [file join $::env(HOME) ".kde$ver"]]
    }
    if {[info exists localKdeDir] && $localKdeDir ne "-"} {
	lappend kdeDirList $localKdeDir
    }

    if {[info exists ::env(KDEDIRS)] && $::env(KDEDIRS) ne ""} {
	foreach dir [split $::env(KDEDIRS) ":"] {
	    if {$dir ne ""} {
		lappend kdeDirList $dir
	    }
	}
    } elseif {[info exists ::env(KDEDIR)] && $::env(KDEDIR) ne ""} {
	lappend kdeDirList $::env(KDEDIR)
    }

    set prefix [exec kde$ver-config --expandvars --prefix]
    lappend kdeDirList $prefix

    set execPrefix [exec kde$ver-config --expandvars --exec-prefix]
    if {$execPrefix ne $prefix} {
	lappend kdeDirList $execPrefix
    }
}

#------------------------------------------------------------------------------
# tablelist::readKdeConfigVal
#
# Reads the value of the global KDE configuration option identified by the
# given group (section) and key from the specified file.  Note that the
# procedure performs a case-sensitive search and only works as expected for
# "simple" group and key names.
#------------------------------------------------------------------------------
proc tablelist::readKdeConfigVal {fileName group key} {
    if {[catch {open $fileName r} chan] != 0} {
	return ""
    }

    #
    # Search for the specified group
    #
    set groupFound 0
    while {[gets $chan line] >= 0} {
	set line [string trim $line]
	if {$line eq "\[$group\]"} {
	    set groupFound 1
	    break
	}
    }
    if {!$groupFound} {
	close $chan
	return ""
    }

    #
    # Search for the specified key within the group
    #
    set pattern "^$key\\s*=\\s*(.+)$"
    set keyFound 0
    while {[gets $chan line] >= 0} {
	set line [string trim $line]
	if {[string index $line 0] eq "\["} {
	    break
	}

	if {[regexp $pattern $line dummy val]} {
	    set keyFound 1
	    break
	}
    }

    close $chan
    return [expr {$keyFound ? $val : ""}]
}
#==============================================================================
# Contains private utility procedures for tablelist widgets.
#
# Structure of the module:
#   - Namespace initialization
#   - Private utility procedures
#
# Copyright (c) 2000-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#
# Namespace initialization
# ========================
#

namespace eval tablelist {
    #
    # alignment -> anchor mapping
    #
    variable anchors
    array set anchors {
	left	w
	right	e
	center	center
    }

    #
    # <alignment, changeSnipSide> -> snipSide mapping
    #
    variable snipSides
    array set snipSides {
	left,0		r
	left,1		l
	right,0		l
	right,1		r
	center,0	r
	center,1	l
    }

    #
    # <incrArrowType, sortOrder> -> direction mapping
    #
    variable directions
    array set directions {
	up,increasing	Up
	up,decreasing	Dn
	down,increasing	Dn
	down,decreasing	Up
    }
}

#
# Private utility procedures
# ==========================
#

#------------------------------------------------------------------------------
# tablelist::rowIndex
#
# Checks the row index idx and returns either its numerical value or an error.
# endIsSize must be a boolean value: if true, end refers to the number of items
# in the tablelist, i.e., to the element just after the last one; if false, end
# refers to 1 less than the number of items, i.e., to the last element in the
# tablelist.  checkRange must be a boolean value: if true, it is additionally
# checked whether the numerical value corresponding to idx is within the
# allowed range.
#------------------------------------------------------------------------------
proc tablelist::rowIndex {win idx endIsSize {checkRange 0}} {
    upvar ::tablelist::ns${win}::data data

    if {[isInteger $idx]} {
	set index [expr {int($idx)}]
    } elseif {[string first $idx "end"] == 0} {
	if {$endIsSize} {
	    set index $data(itemCount)
	} else {
	    set index $data(lastRow)
	}
    } elseif {[string first $idx "last"] == 0} {
	set index $data(lastRow)
    } elseif {[string first $idx "top"] == 0} {
	displayItems $win
	set textIdx [$data(body) index @0,0]
	set index [expr {int($textIdx) - 1}]
    } elseif {[string first $idx "bottom"] == 0} {
	displayItems $win
	set textIdx [$data(body) index @0,$data(btmY)]
	set index [expr {int($textIdx) - 1}]
	if {$index > $data(lastRow)} {			;# text widget bug
	    set index $data(lastRow)
	}
    } elseif {[string first $idx "active"] == 0 && [string length $idx] >= 2} {
	set index $data(activeRow)
    } elseif {[string first $idx "anchor"] == 0 && [string length $idx] >= 2} {
	set index $data(anchorRow)
    } elseif {[scan $idx "@%d,%d%n" x y count] == 3 &&
	      $count == [string length $idx]} {
	displayItems $win
	incr x -[winfo x $data(body)]
	incr y -[winfo y $data(body)]
	set textIdx [$data(body) index @$x,$y]
	set index [expr {int($textIdx) - 1}]
	if {$index > $data(lastRow)} {			;# text widget bug
	    set index $data(lastRow)
	}
    } elseif {[scan $idx "k%d%n" num count] == 2 &&
	      $count == [string length $idx]} {
	set index [keyToRow $win k$num]
    } else {
	set idxIsEmpty [expr {[string length $idx] == 0}]
	for {set row 0} {$row < $data(itemCount)} {incr row} {
	    set key [lindex $data(keyList) $row]
	    set hasName [info exists data($key-name)]
	    if {($hasName && [string compare $idx $data($key-name)] == 0) ||
		(!$hasName && $idxIsEmpty)} {
		set index $row
		break
	    }
	}
	if {$row == $data(itemCount)} {
	    return -code error \
		   "bad row index \"$idx\": must be active, anchor, end, last,\
		    top, bottom, @x,y, a number, a full key, or a name"
	}
    }

    if {$checkRange && ($index < 0 || $index > $data(lastRow))} {
	return -code error "row index \"$idx\" out of range"
    } else {
	return $index
    }
}

#------------------------------------------------------------------------------
# tablelist::colIndex
#
# Checks the column index idx and returns either its numerical value or an
# error.  checkRange must be a boolean value: if true, it is additionally
# checked whether the numerical value corresponding to idx is within the
# allowed range.
#------------------------------------------------------------------------------
proc tablelist::colIndex {win idx checkRange {decrX 1}} {
    upvar ::tablelist::ns${win}::data data

    if {[isInteger $idx]} {
	set index [expr {int($idx)}]
    } elseif {[string first $idx "end"] == 0 ||
	      [string first $idx "last"] == 0} {
	set index $data(lastCol)
    } elseif {[string first $idx "left"] == 0} {
	return [colIndex $win @0,0 $checkRange 0]
    } elseif {[string first $idx "right"] == 0} {
	return [colIndex $win @$data(rightX),0 $checkRange 0]
    } elseif {[string first $idx "active"] == 0 && [string length $idx] >= 2} {
	set index $data(activeCol)
    } elseif {[string first $idx "anchor"] == 0 && [string length $idx] >= 2} {
	set index $data(anchorCol)
    } elseif {[scan $idx "@%d,%d%n" x y count] == 3 &&
	      $count == [string length $idx]} {
	synchronize $win
	displayItems $win
	if {$decrX} {
	    incr x -[winfo x $data(body)]
	    if {$x > $data(rightX)} {
		set x $data(rightX)
	    } elseif {$x < 0} {
		set x 0
	    }
	}
	incr x [winfo rootx $data(body)]

	#
	# Get the (scheduled) root X coordinate of $data(hdrTxtFrm)
	#
	set  baseX [winfo rootx $data(hdrTxt)]
	incr baseX [lindex [$data(hdrTxt) bbox 1.0] 0]

	set lastVisibleCol -1
	for {set col 0} {$col < $data(colCount)} {incr col} {
	    if {$data($col-elide) || $data($col-hide)} {
		continue
	    }

	    set lastVisibleCol $col
	    set w $data(hdrTxtFrmLbl)$col
	    set wX [expr {$baseX + [lindex [place configure $w -x] 4]}]
	    if {$x >= $wX && $x < $wX + [winfo width $w]} {
		return $col
	    }
	}
	set index $lastVisibleCol
    } else {
	set idxIsEmpty [expr {[string length $idx] == 0}]
	for {set col 0} {$col < $data(colCount)} {incr col} {
	    set hasName [info exists data($col-name)]
	    if {($hasName && [string compare $idx $data($col-name)] == 0) ||
		(!$hasName && $idxIsEmpty)} {
		set index $col
		break
	    }
	}
	if {$col == $data(colCount)} {
	    return -code error \
		   "bad column index \"$idx\": must be active, anchor,\
		    end, last, left, right, @x,y, a number, or a name"
	}
    }

    if {$checkRange && ($index < 0 || $index > $data(lastCol))} {
	return -code error "column index \"$idx\" out of range"
    } else {
	return $index
    }
}

#------------------------------------------------------------------------------
# tablelist::cellIndex
#
# Checks the cell index idx and returns either a list of the form {row col} or
# an error.  checkRange must be a boolean value: if true, it is additionally
# checked whether the two numerical values corresponding to idx are within the
# respective allowed ranges.
#------------------------------------------------------------------------------
proc tablelist::cellIndex {win idx checkRange} {
    upvar ::tablelist::ns${win}::data data

    set lst [split $idx ","]
    if {[llength $lst] == 2 &&
	[catch {rowIndex $win [lindex $lst 0] 0} row] == 0 &&
	[catch {colIndex $win [lindex $lst 1] 0} col] == 0} {
	# nothing
    } elseif {[string first $idx "end"] == 0 ||
	      [string first $idx "last"] == 0} {
	set row [rowIndex $win $idx 0]
	set col [colIndex $win $idx 0]
    } elseif {[string first $idx "active"] == 0 && [string length $idx] >= 2} {
	set row $data(activeRow)
	set col $data(activeCol)
    } elseif {[string first $idx "anchor"] == 0 && [string length $idx] >= 2} {
	set row $data(anchorRow)
	set col $data(anchorCol)
    } elseif {[string compare [string index $idx 0] "@"] == 0 &&
	      [catch {rowIndex $win $idx 0} row] == 0 &&
	      [catch {colIndex $win $idx 0} col] == 0} {
	# nothing
    } else {
	return -code error \
	       "bad cell index \"$idx\": must be active, anchor, end, last,\
	        @x,y, or row,col, where row must be active, anchor, end, last,\
		top, bottom, a number, a full key, or a name, and col must be\
		active, anchor, end, last, left, right, a number, or a name"
    }

    if {$checkRange && ($row < 0 || $row > $data(lastRow) ||
	$col < 0 || $col > $data(lastCol))} {
	return -code error "cell index \"$idx\" out of range"
    } else {
	return [list $row $col]
    }
}

#------------------------------------------------------------------------------
# tablelist::adjustRowIndex
#
# Sets the row index specified by $rowName to the index of the nearest
# (viewable) row.
#------------------------------------------------------------------------------
proc tablelist::adjustRowIndex {win rowName {forceViewable 0}} {
    upvar ::tablelist::ns${win}::data data $rowName row

    #
    # Don't operate on row directly, because $rowName might
    # be data(activeRow), in which case any temporary changes
    # made on row would trigger the activeTrace procedure
    #
    set _row $row
    if {$_row > $data(lastRow)} {
	set _row $data(lastRow)
    }
    if {$_row < 0} {
	set _row 0
    }

    if {$forceViewable} {
	set _rowSav $_row
	for {} {$_row < $data(itemCount)} {incr _row} {
	    set key [lindex $data(keyList) $_row]
	    if {![info exists data($key-elide)] &&
		![info exists data($key-hide)]} {
		set row $_row
		return ""
	    }
	}
	for {set _row [expr {$_rowSav - 1}]} {$_row >= 0} {incr _row -1} {
	    set key [lindex $data(keyList) $_row]
	    if {![info exists data($key-elide)] &&
		![info exists data($key-hide)]} {
		set row $_row
		return ""
	    }
	}
	set row 0
    } else {
	set row $_row
    }
}

#------------------------------------------------------------------------------
# tablelist::adjustColIndex
#
# Sets the column index specified by $colName to the index of the nearest
# (viewable) column.
#------------------------------------------------------------------------------
proc tablelist::adjustColIndex {win colName {forceViewable 0}} {
    upvar ::tablelist::ns${win}::data data $colName col

    #
    # Don't operate on col directly, because $colName might
    # be data(activeCol), in which case any temporary changes
    # made on col would trigger the activeTrace procedure
    #
    set _col $col
    if {$_col > $data(lastCol)} {
	set _col $data(lastCol)
    }
    if {$_col < 0} {
	set _col 0
    }

    if {$forceViewable} {
	set _colSav $_col
	for {} {$_col < $data(colCount)} {incr _col} {
	    if {!$data($_col-hide)} {
		set col $_col
		return ""
	    }
	}
	for {set _col [expr {$_colSav - 1}]} {$_col >= 0} {incr _col -1} {
	    if {!$data($_col-hide)} {
		set col $_col
		return ""
	    }
	}
	set _col 0
    } else {
	set col $_col
    }
}

#------------------------------------------------------------------------------
# tablelist::nodeIndexToKey
#
# Checks the node index idx and returns either the corresponding full key or
# "root", or an error.
#------------------------------------------------------------------------------
proc tablelist::nodeIndexToKey {win idx} {
    if {[string first $idx "root"] == 0} {
	return "root"
    } elseif {[catch {rowIndex $win $idx 0} row] == 0} {
	upvar ::tablelist::ns${win}::data data
	if {$row < 0 || $row > $data(lastRow)} {
	    return -code error "node index \"$idx\" out of range"
	} else {
	    return [lindex $data(keyList) $row]
	}
    } else {
	return -code error \
	       "bad node index \"$idx\": must be root, active, anchor, end,\
		last, top, bottom, @x,y, a number, a full key, or a name"
    }
}

#------------------------------------------------------------------------------
# tablelist::depth
#
# Returns the number of steps from the node with the given full key to the root
# node of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::depth {win key} {
    upvar ::tablelist::ns${win}::data data

    set depth 0
    while {[string compare $key "root"] != 0} {
	incr depth
	set key $data($key-parent)
    }

    return $depth
}

#------------------------------------------------------------------------------
# tablelist::topLevelKey
#
# Returns the full key of the top-level item of the tablelist widget win having
# the item with the given key as descendant.
#------------------------------------------------------------------------------
proc tablelist::topLevelKey {win key} {
    upvar ::tablelist::ns${win}::data data

    set parentKey $data($key-parent)
    while {[string compare $parentKey "root"] != 0} {
	set key $data($key-parent)
	set parentKey $data($key-parent)
    }

    return $key
}

#------------------------------------------------------------------------------
# tablelist::descCount
#
# Returns the number of descendants of the node with the given full key of the
# tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::descCount {win key} {
    upvar ::tablelist::ns${win}::data data

    if {[string compare $key "root"] == 0} {
	return $data(itemCount)
    } else {
	set count [llength $data($key-children)]
	foreach child $data($key-children) {
	    incr count [descCount $win $child]
	}
	return $count
    }
}

#------------------------------------------------------------------------------
# tablelist::nodeRow
#
# Returns the row of the child item identified by childIdx of the node given by
# parentKey within the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::nodeRow {win parentKey childIdx} {
    upvar ::tablelist::ns${win}::data data

    if {[isInteger $childIdx]} {
	if {$childIdx < [llength $data($parentKey-children)]} {
	    set childKey [lindex $data($parentKey-children) $childIdx]
	    return [keyToRow $win $childKey]
	} else {
	    return [expr {[keyToRow $win $parentKey] +
			  [descCount $win $parentKey] + 1}]
	}
    } elseif {[string first $childIdx "end"] == 0} {
	return [expr {[keyToRow $win $parentKey] +
		      [descCount $win $parentKey] + 1}]
    } elseif {[string first $childIdx "last"] == 0} {
	set childKey [lindex $data($parentKey-children) end]
	return [keyToRow $win $childKey]
    } else {
	return -code error \
	       "bad child index \"$childIdx\": must be end, last, or a number"
    }
}

#------------------------------------------------------------------------------
# tablelist::keyToRow
#
# Returns the row corresponding to the given full key within the tablelist
# widget win.
#------------------------------------------------------------------------------
proc tablelist::keyToRow {win key} {
    upvar ::tablelist::ns${win}::data data
    if {[string compare $key "root"] == 0} {
	return -1
    } elseif {$data(keyToRowMapValid) && [info exists data($key-row)]} {
	return $data($key-row)
    } else {
	if {$::tcl_version >= 8.4} {
	    #
	    # Speed up the search by starting at the last found position
	    #
	    set row [lsearch -exact -start $data(searchStartIdx) \
		     $data(keyList) $key]
	    if {$row < 0 && $data(searchStartIdx) != 0} {
		set row [lsearch -exact $data(keyList) $key]
	    }
	    if {$row >= 0} {
		set data(searchStartIdx) $row
	    }

	    return $row
	} else {
	    return [lsearch -exact $data(keyList) $key]
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::updateKeyToRowMap
#
# Updates the key -> row map associated with the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::updateKeyToRowMap win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(mapId)]} {
	after cancel $data(mapId)
	unset data(mapId)
    }

    set row 0
    foreach key $data(keyList) {
	set data($key-row) $row
	incr row
    }

    set data(keyToRowMapValid) 1
}

#------------------------------------------------------------------------------
# tablelist::findTabs
#
# Searches for the first and last occurrences of the tab character in the cell
# range specified by firstCol and lastCol in the given line of the body text
# child of the tablelist widget win.  Assigns the index of the first tab to
# $idx1Name and the index of the last tab to $idx2Name.  It is assumed that
# both columns are non-hidden (but there may be hidden ones between them).
#------------------------------------------------------------------------------
proc tablelist::findTabs {win line firstCol lastCol idx1Name idx2Name} {
    upvar ::tablelist::ns${win}::data data $idx1Name idx1 $idx2Name idx2
    set w $data(body)

    if {$::tk_version >= 8.5} {
	set idxList [$w search -all -elide "\t" $line.0 $line.end]
	if {[llength $idxList] == 0} {
	    return 0
	}

	set idx1 [lindex $idxList [expr {2*$firstCol}]]
	set idx2 [lindex $idxList [expr {2*$lastCol + 1}]]
	return 1
    } else {
	variable canElide
	variable elide
	set endIdx $line.end

	set idx $line.1
	for {set col 0} {$col < $firstCol} {incr col} {
	    if {!$data($col-hide) || $canElide} {
		set idx [$w search $elide "\t" $idx $endIdx]+2c
		if {[string compare $idx "+2c"] == 0} {
		    return 0
		}
	    }
	}
	set idx1 [$w index $idx-1c]

	for {} {$col < $lastCol} {incr col} {
	    if {!$data($col-hide) || $canElide} {
		set idx [$w search $elide "\t" $idx $endIdx]+2c
		if {[string compare $idx "+2c"] == 0} {
		    return 0
		}
	    }
	}
	set idx2 [$w search $elide "\t" $idx $endIdx]
	if {[string length $idx2] == 0} {
	    return 0
	}

	return 1
    }
}

#------------------------------------------------------------------------------
# tablelist::sortStretchableColList
#
# Replaces the column indices different from end in the list of the stretchable
# columns of the tablelist widget win with their numerical equivalents and
# sorts the resulting list.
#------------------------------------------------------------------------------
proc tablelist::sortStretchableColList win {
    upvar ::tablelist::ns${win}::data data
    if {[llength $data(-stretch)] == 0 ||
	[string compare $data(-stretch) "all"] == 0} {
	return ""
    }

    set containsEnd 0
    foreach elem $data(-stretch) {
	if {[string first $elem "end"] == 0 ||
	    [string first $elem "last"] == 0} {
	    set containsEnd 1
	} else {
	    set tmp([colIndex $win $elem 0]) ""
	}
    }

    set data(-stretch) [lsort -integer [array names tmp]]
    if {$containsEnd} {
	lappend data(-stretch) end
    }
}

#------------------------------------------------------------------------------
# tablelist::deleteColData
#
# Cleans up the data associated with the col'th column of the tablelist widget
# win.
#------------------------------------------------------------------------------
proc tablelist::deleteColData {win col} {
    upvar ::tablelist::ns${win}::data data
    if {$data(editCol) == $col} {
	set data(editCol) -1
	set data(editRow) -1
    }

    #
    # Remove the elements with names of the form $col-*
    #
    if {[info exists data($col-redispId)]} {
	after cancel $data($col-redispId)
    }
    foreach name [array names data $col-*] {
	unset data($name)
    }

    #
    # Remove the elements with names of the form k*,$col-*
    #
    foreach name [array names data k*,$col-*] {
	unset data($name)
	if {[string match "k*,$col-font" $name]} {
	    incr data(cellTagRefCount) -1
	} elseif {[string match "k*,$col-image" $name]} {
	    incr data(imgCount) -1
	} elseif {[string match "k*,$col-window" $name]} {
	    incr data(winCount) -1
	} elseif {[string match "k*,$col-indent" $name]} {
	    incr data(indentCount) -1
	}
    }

    #
    # Remove col from the list of stretchable columns if explicitly specified
    #
    if {[string compare $data(-stretch) "all"] != 0} {
	set stretchableCols {}
	foreach elem $data(-stretch) {
	    if {$elem != $col} {
		lappend stretchableCols $elem
	    }
	}
	set data(-stretch) $stretchableCols
    }
}

#------------------------------------------------------------------------------
# tablelist::deleteColAttribs
#
# Cleans up the attributes associated with the col'th column of the tablelist
# widget win.
#------------------------------------------------------------------------------
proc tablelist::deleteColAttribs {win col} {
    upvar ::tablelist::ns${win}::attribs attribs

    #
    # Remove the elements with names of the form $col-*
    #
    foreach name [array names attribs $col-*] {
	unset attribs($name)
    }

    #
    # Remove the elements with names of the form k*,$col-*
    #
    foreach name [array names attribs k*,$col-*] {
	unset attribs($name)
    }
}

#------------------------------------------------------------------------------
# tablelist::moveColData
#
# Moves the elements of oldArrName corresponding to oldCol to those of
# newArrName corresponding to newCol.
#------------------------------------------------------------------------------
proc tablelist::moveColData {oldArrName newArrName imgArrName oldCol newCol} {
    upvar $oldArrName oldArr $newArrName newArr $imgArrName imgArr

    foreach specialCol {editCol -treecolumn treeCol} {
	if {$oldArr($specialCol) == $oldCol} {
	    set newArr($specialCol) $newCol
	}
    }

    set callerProc [lindex [info level -1] 0]
    if {[string compare $callerProc "moveCol"] == 0} {
	foreach specialCol {activeCol anchorCol} {
	    if {$oldArr($specialCol) == $oldCol} {
		set newArr($specialCol) $newCol
	    }
	}
    }

    if {$newCol < $newArr(colCount)} {
	foreach l [getSublabels $newArr(hdrTxtFrmLbl)$newCol] {
	    destroy $l
	}
	set newArr(fmtCmdFlagList) \
	    [lreplace $newArr(fmtCmdFlagList) $newCol $newCol 0]
    }

    #
    # Move the elements of oldArr with names of the form $oldCol-*
    # to those of newArr with names of the form $newCol-*
    #
    foreach newName [array names newArr $newCol-*] {
	unset newArr($newName)
    }
    foreach oldName [array names oldArr $oldCol-*] {
	regsub "$oldCol-" $oldName "$newCol-" newName
	set newArr($newName) $oldArr($oldName)
	unset oldArr($oldName)

	set tail [lindex [split $newName "-"] 1]
	switch $tail {
	    formatcommand {
		if {$newCol < $newArr(colCount)} {
		    set newArr(fmtCmdFlagList) \
			[lreplace $newArr(fmtCmdFlagList) $newCol $newCol 1]
		}
	    }
	    labelimage {
		set imgArr($newCol-$tail) $newArr($newName)
		unset newArr($newName)
	    }
	}
    }

    #
    # Move the elements of oldArr with names of the form k*,$oldCol-*
    # to those of newArr with names of the form k*,$newCol-*
    #
    foreach newName [array names newArr k*,$newCol-*] {
	unset newArr($newName)
    }
    foreach oldName [array names oldArr k*,$oldCol-*] {
	regsub -- ",$oldCol-" $oldName ",$newCol-" newName
	set newArr($newName) $oldArr($oldName)
	unset oldArr($oldName)
    }

    #
    # Replace oldCol with newCol in the list of
    # stretchable columns if explicitly specified
    #
    if {[info exists oldArr(-stretch)] &&
	[string compare $oldArr(-stretch) "all"] != 0} {
	set stretchableCols {}
	foreach elem $oldArr(-stretch) {
	    if {$elem == $oldCol} {
		lappend stretchableCols $newCol
	    } else {
		lappend stretchableCols $elem
	    }
	}
	set newArr(-stretch) $stretchableCols
    }
}

#------------------------------------------------------------------------------
# tablelist::moveColAttribs
#
# Moves the elements of oldArrName corresponding to oldCol to those of
# newArrName corresponding to newCol.
#------------------------------------------------------------------------------
proc tablelist::moveColAttribs {oldArrName newArrName oldCol newCol} {
    upvar $oldArrName oldArr $newArrName newArr

    #
    # Move the elements of oldArr with names of the form $oldCol-*
    # to those of newArr with names of the form $newCol-*
    #
    foreach newName [array names newArr $newCol-*] {
	unset newArr($newName)
    }
    foreach oldName [array names oldArr $oldCol-*] {
	regsub "$oldCol-" $oldName "$newCol-" newName
	set newArr($newName) $oldArr($oldName)
	unset oldArr($oldName)
    }

    #
    # Move the elements of oldArr with names of the form k*,$oldCol-*
    # to those of newArr with names of the form k*,$newCol-*
    #
    foreach newName [array names newArr k*,$newCol-*] {
	unset newArr($newName)
    }
    foreach oldName [array names oldArr k*,$oldCol-*] {
	regsub -- ",$oldCol-" $oldName ",$newCol-" newName
	set newArr($newName) $oldArr($oldName)
	unset oldArr($oldName)
    }
}

#------------------------------------------------------------------------------
# tablelist::deleteColFromCellList
#
# Returns the list obtained from a given list of cell indices by removing the
# elements whose column component equals a given column number.
#------------------------------------------------------------------------------
proc tablelist::deleteColFromCellList {cellList col} {
    set newCellList {}
    foreach cellIdx $cellList {
	scan $cellIdx "%d,%d" cellRow cellCol
	if {$cellCol != $col} {
	    lappend newCellList $cellIdx
	}
    }

    return $newCellList
}

#------------------------------------------------------------------------------
# tablelist::extractColFromCellList
#
# Returns the list of row indices obtained from those elements of a given list
# of cell indices whose column component equals a given column number.
#------------------------------------------------------------------------------
proc tablelist::extractColFromCellList {cellList col} {
    set rowList {}
    foreach cellIdx $cellList {
	scan $cellIdx "%d,%d" cellRow cellCol
	if {$cellCol == $col} {
	    lappend rowList $cellRow
	}
    }

    return $rowList
}

#------------------------------------------------------------------------------
# tablelist::replaceColInCellList
#
# Returns the list obtained from a given list of cell indices by replacing the
# occurrences of oldCol in the column components with newCol.
#------------------------------------------------------------------------------
proc tablelist::replaceColInCellList {cellList oldCol newCol} {
    set cellList [deleteColFromCellList $cellList $newCol]
    set newCellList {}
    foreach cellIdx $cellList {
	scan $cellIdx "%d,%d" cellRow cellCol
	if {$cellCol == $oldCol} {
	    lappend newCellList $cellRow,$newCol
	} else {
	    lappend newCellList $cellIdx
	}
    }

    return $newCellList
}

#------------------------------------------------------------------------------
# tablelist::condUpdateListVar
#
# Updates the list variable of the tablelist widget win if present.
#------------------------------------------------------------------------------
proc tablelist::condUpdateListVar win {
    upvar ::tablelist::ns${win}::data data
    if {$data(hasListVar)} {
	upvar #0 $data(-listvariable) var
	trace vdelete var wu $data(listVarTraceCmd)
	set var {}
	foreach item $data(itemList) {
	    lappend var [lrange $item 0 $data(lastCol)]
	}
	trace variable var wu $data(listVarTraceCmd)
    }
}

#------------------------------------------------------------------------------
# tablelist::reconfigColLabels
#
# Reconfigures the labels of the col'th column of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::reconfigColLabels {win imgArrName col} {
    upvar ::tablelist::ns${win}::data data $imgArrName imgArr

    set optList {-labelalign -labelborderwidth -labelfont
		 -labelforeground -labelpady -labelrelief}
    variable usingTile
    if {!$usingTile} {
	lappend optList -labelbackground -labelheight
    }

    foreach opt $optList {
	if {[info exists data($col$opt)]} {
	    doColConfig $col $win $opt $data($col$opt)
	} else {
	    doColConfig $col $win $opt ""
	}
    }

    if {[info exists imgArr($col-labelimage)]} {
	doColConfig $col $win -labelimage $imgArr($col-labelimage)
    }
}

#------------------------------------------------------------------------------
# tablelist::charsToPixels
#
# Returns the width in pixels of the string consisting of a given number of "0"
# characters.
#------------------------------------------------------------------------------
proc tablelist::charsToPixels {win font charCount} {
    ### set str [string repeat "0" $charCount]
    set str ""
    for {set n 0} {$n < $charCount} {incr n} {
	append str 0
    }

    return [font measure $font -displayof $win $str]
}

#------------------------------------------------------------------------------
# tablelist::strRange
#
# Gets the largest initial (for snipSide = r) or final (for snipSide = l) range
# of characters from str whose width, when displayed in the given font, is no
# greater than pixels decremented by the width of snipStr.  Returns a string
# obtained from this substring by appending (for snipSide = r) or prepending
# (for snipSide = l) (part of) snipStr to it.
#------------------------------------------------------------------------------
proc tablelist::strRange {win str font pixels snipSide snipStr} {
    if {$pixels < 0} {
	return ""
    }

    if {[string length $snipSide] == 0} {
	return $str
    }


    set width [font measure $font -displayof $win $str]
    if {$width <= $pixels} {
	return $str
    }

    set snipWidth [font measure $font -displayof $win $snipStr]
    if {$pixels <= $snipWidth} {
	set str $snipStr
	set snipStr ""
    } else {
	incr pixels -$snipWidth
    }

    if {[string compare $snipSide "r"] == 0} {
	set idx [expr {[string length $str]*$pixels/$width - 1}]
	set subStr [string range $str 0 $idx]
	set width [font measure $font -displayof $win $subStr]
	if {$width < $pixels} {
	    while 1 {
		incr idx
		set subStr [string range $str 0 $idx]
		set width [font measure $font -displayof $win $subStr]
		if {$width > $pixels} {
		    incr idx -1
		    set subStr [string range $str 0 $idx]
		    return $subStr$snipStr
		} elseif {$width == $pixels} {
		    return $subStr$snipStr
		}
	    }
	} elseif {$width == $pixels} {
	    return $subStr$snipStr
	} else {
	    while 1 {
		incr idx -1
		set subStr [string range $str 0 $idx]
		set width [font measure $font -displayof $win $subStr]
		if {$width <= $pixels} {
		    return $subStr$snipStr
		}
	    }
	}

    } else {
	set idx [expr {[string length $str]*($width - $pixels)/$width}]
	set subStr [string range $str $idx end]
	set width [font measure $font -displayof $win $subStr]
	if {$width < $pixels} {
	    while 1 {
		incr idx -1
		set subStr [string range $str $idx end]
		set width [font measure $font -displayof $win $subStr]
		if {$width > $pixels} {
		    incr idx
		    set subStr [string range $str $idx end]
		    return $snipStr$subStr
		} elseif {$width == $pixels} {
		    return $snipStr$subStr
		}
	    }
	} elseif {$width == $pixels} {
	    return $snipStr$subStr
	} else {
	    while 1 {
		incr idx
		set subStr [string range $str $idx end]
		set width [font measure $font -displayof $win $subStr]
		if {$width <= $pixels} {
		    return $snipStr$subStr
		}
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::adjustItem
#
# Returns the list obtained by adjusting the list specified by item to the
# length expLen.
#------------------------------------------------------------------------------
proc tablelist::adjustItem {item expLen} {
    set len [llength $item]
    if {$len == $expLen} {
	return $item
    } elseif {$len > $expLen} {
	return [lrange $item 0 [expr {$expLen - 1}]]
    } else {
	for {set n $len} {$n < $expLen} {incr n} {
	    lappend item ""
	}
	return $item
    }
}

#------------------------------------------------------------------------------
# tablelist::formatElem
#
# Returns the string obtained by formatting the last argument.
#------------------------------------------------------------------------------
proc tablelist::formatElem {win key row col text} {
    upvar ::tablelist::ns${win}::data data
    array set data [list fmtKey $key fmtRow $row fmtCol $col]

    return [uplevel #0 $data($col-formatcommand) [list $text]]
}

#------------------------------------------------------------------------------
# tablelist::formatItem
#
# Returns the list obtained by formatting the elements of the last argument.
#------------------------------------------------------------------------------
proc tablelist::formatItem {win key row item} {
    upvar ::tablelist::ns${win}::data data
    array set data [list fmtKey $key fmtRow $row]
    set formattedItem {}
    set col 0
    foreach text $item fmtCmdFlag $data(fmtCmdFlagList) {
	if {$fmtCmdFlag} {
	    set data(fmtCol) $col
	    set text [uplevel #0 $data($col-formatcommand) [list $text]]
	}
	lappend formattedItem $text
	incr col
    }

    return $formattedItem
}

#------------------------------------------------------------------------------
# tablelist::hasChars
#
# Checks whether at least one element of the given list is a nonempty string.
#------------------------------------------------------------------------------
proc tablelist::hasChars list {
    foreach str $list {
	if {[string length $str] != 0} {
	    return 1
	}
    }

    return 0
}

#------------------------------------------------------------------------------
# tablelist::getListWidth
#
# Returns the max. number of pixels that the elements of the given list would
# use in the specified font when displayed in the window win.
#------------------------------------------------------------------------------
proc tablelist::getListWidth {win list font} {
    set width 0
    foreach str $list {
	set strWidth [font measure $font -displayof $win $str]
	if {$strWidth > $width} {
	    set width $strWidth
	}
    }

    return $width
}

#------------------------------------------------------------------------------
# tablelist::joinList
#
# Returns the string formed by joining together with "\n" the strings obtained 
# by applying strRange to the elements of the given list, with the specified
# arguments.
#------------------------------------------------------------------------------
proc tablelist::joinList {win list font pixels snipSide snipStr} {
    set list2 {}
    foreach str $list {
	lappend list2 [strRange $win $str $font $pixels $snipSide $snipStr]
    }

    return [join $list2 "\n"]
}

#------------------------------------------------------------------------------
# tablelist::displayIndent
#
# Displays an indentation image in a label widget to be embedded into the
# specified cell of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::displayIndent {win key col width} {
    #
    # Create a label widget and replace the binding tag Label with
    # $data(bodyTag) and TablelistBody in the list of its binding tags
    #
    upvar ::tablelist::ns${win}::data data
    set w $data(body).ind_$key,$col
    if {![winfo exists $w]} {
	tk::label $w -anchor w -borderwidth 0 -height 0 -highlightthickness 0 \
		     -image $data($key,$col-indent) -padx 0 -pady 0 \
		     -relief flat -takefocus 0 -width $width
	bindtags $w [lreplace [bindtags $w] 1 1 $data(bodyTag) TablelistBody]
    }

    updateColorsWhenIdle $win
    return $w
}

#------------------------------------------------------------------------------
# tablelist::displayImage
#
# Displays an image in a label widget to be embedded into the specified cell of
# the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::displayImage {win key col anchor width} {
    #
    # Create a label widget and replace the binding tag Label with
    # $data(bodyTag) and TablelistBody in the list of its binding tags
    #
    upvar ::tablelist::ns${win}::data data
    set w $data(body).img_$key,$col
    if {![winfo exists $w]} {
	tk::label $w -anchor $anchor -borderwidth 0 -height 0 \
		     -highlightthickness 0 -image $data($key,$col-image) \
		     -padx 0 -pady 0 -relief flat -takefocus 0 -width $width
	bindtags $w [lreplace [bindtags $w] 1 1 $data(bodyTag) TablelistBody]
    }

    updateColorsWhenIdle $win
    return $w
}

#------------------------------------------------------------------------------
# tablelist::displayText
#
# Displays the given text in a message widget to be embedded into the specified
# cell of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::displayText {win key col text font pixels alignment} {
    upvar ::tablelist::ns${win}::data data
    set w $data(body).msg_$key,$col
    if {![winfo exists $w]} {
	#
	# Create a message widget and replace the binding tag Message with
	# $data(bodyTag) and TablelistBody in the list of its binding tags
	#
	message $w -borderwidth 0 -highlightthickness 0 -padx 0 -pady 0 \
		   -relief flat -takefocus 0
	bindtags $w [lreplace [bindtags $w] 1 1 $data(bodyTag) TablelistBody]
    }

    variable anchors
    set width $pixels
    if {$pixels == 0} {
	set width 1000000
    }
    $w configure -anchor $anchors($alignment) -font $font \
		 -justify $alignment -text $text -width $width

    updateColorsWhenIdle $win
    return $w
}

#------------------------------------------------------------------------------
# tablelist::getAuxData
#
# Gets the name, type, and width of the image or window associated with the
# specified cell of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::getAuxData {win key col auxTypeName auxWidthName {pixels 0}} {
    upvar ::tablelist::ns${win}::data data \
	  $auxTypeName auxType $auxWidthName auxWidth

    if {[info exists data($key,$col-window)]} {
	if {$pixels != 0 && [info exists data($key,$col-stretchwindow)]} {
	    set auxType 3				;# dynamic-width window
	    set auxWidth [expr {$pixels + $data($col-delta)}]
	} else {
	    set auxType 2				;# static-width window
	    set auxWidth $data($key,$col-reqWidth)
	}
	return $data(body).frm_$key,$col
    } elseif {[info exists data($key,$col-image)]} {
	set auxType 1					;# image
	set auxWidth [image width $data($key,$col-image)]
	return [list ::tablelist::displayImage $win $key $col w 0]
    } else {
	set auxType 0					;# none
	set auxWidth 0
	return ""
    }
}

#------------------------------------------------------------------------------
# tablelist::getIndentData
#
# Gets the creation script and width of the label displaying the indentation
# image associated with the specified cell of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::getIndentData {win key col indentWidthName} {
    upvar ::tablelist::ns${win}::data data $indentWidthName indentWidth

    if {[info exists data($key,$col-indent)]} {
	set indentWidth [image width $data($key,$col-indent)]
	return [list ::tablelist::displayIndent $win $key $col 0]
    } else {
	set indentWidth 0
	return ""
    }
}

#------------------------------------------------------------------------------
# tablelist::getMaxTextWidth
#
# Returns the number of pixels available for displaying the text of a static-
# width tablelist cell.
#------------------------------------------------------------------------------
proc tablelist::getMaxTextWidth {pixels auxWidth indentWidth} {
    if {$indentWidth != 0} {
	incr pixels -$indentWidth
	if {$pixels <= 0} {
	    set pixels 1
	}
    }

    if {$auxWidth == 0} {
	return $pixels
    } else {
	set lessPixels [expr {$pixels - $auxWidth - 5}]
	if {$lessPixels > 0} {
	    return $lessPixels
	} else {
	    return 1
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::adjustElem
#
# Prepares the text specified by $textName and the auxiliary object width
# specified by $auxWidthName for insertion into a cell of the tablelist widget
# win.
#------------------------------------------------------------------------------
proc tablelist::adjustElem {win textName auxWidthName indentWidthName font
			    pixels snipSide snipStr} {
    upvar $textName text $auxWidthName auxWidth $indentWidthName indentWidth

    if {$pixels == 0} {				;# convention: dynamic width
	if {$auxWidth != 0 && [string length $text] != 0} {
	    incr auxWidth 3
	}
    } elseif {$indentWidth >= $pixels} {
	set indentWidth $pixels
	set text ""				;# can't display the text
	set auxWidth 0				;# can't display the aux. object
    } else {
	incr pixels -$indentWidth
	if {$auxWidth == 0} {			;# no image or window
	    set text [strRange $win $text $font $pixels $snipSide $snipStr]
	} elseif {[string length $text] == 0} {	;# aux. object w/o text
	    if {$auxWidth > $pixels} {
		set auxWidth $pixels
	    }
	} else {				;# both aux. object and text
	    if {$auxWidth + 5 <= $pixels} {
		incr auxWidth 3
		incr pixels -[expr {$auxWidth + 2}]
		set text [strRange $win $text $font $pixels $snipSide $snipStr]
	    } elseif {$auxWidth <= $pixels} {
		set text ""			;# can't display the text
	    } else {
		set auxWidth $pixels
		set text ""			;# can't display the text
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::adjustMlElem
#
# Prepares the list specified by $listName and the auxiliary object width
# specified by $auxWidthName for insertion into a multiline cell of the
# tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::adjustMlElem {win listName auxWidthName indentWidthName font
			      pixels snipSide snipStr} {
    upvar $listName list $auxWidthName auxWidth $indentWidthName indentWidth

    set list2 {}
    if {$pixels == 0} {				;# convention: dynamic width
	if {$auxWidth != 0 && [hasChars $list]} {
	    incr auxWidth 3
	}
    } elseif {$indentWidth >= $pixels} {
	set indentWidth $pixels
	foreach str $list {
	    lappend list2 ""
	}
	set list $list2				;# can't display the text
	set auxWidth 0				;# can't display the aux. object
    } else {
	incr pixels -$indentWidth
	if {$auxWidth == 0} {			;# no image or window
	    foreach str $list {
		lappend list2 \
		    [strRange $win $str $font $pixels $snipSide $snipStr]
	    }
	    set list $list2
	} elseif {![hasChars $list]} {		;# aux. object w/o text
	    if {$auxWidth > $pixels} {
		set auxWidth $pixels
	    }
	} else {				;# both aux. object and text
	    if {$auxWidth + 5 <= $pixels} {
		incr auxWidth 3
		incr pixels -[expr {$auxWidth + 2}]
		foreach str $list {
		    lappend list2 \
			[strRange $win $str $font $pixels $snipSide $snipStr]
		}
		set list $list2
	    } elseif {$auxWidth <= $pixels} {
		foreach str $list {
		    lappend list2 ""
		}
		set list $list2			;# can't display the text
	    } else {
		set auxWidth $pixels
		foreach str $list {
		    lappend list2 ""
		}
		set list $list2			;# can't display the text
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::getElemWidth
#
# Returns the number of pixels that the given text together with the aux.
# object (image or window) of the specified width would use when displayed in a
# cell of a dynamic-width column of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::getElemWidth {win text auxWidth indentWidth cellFont} {
    if {[string match "*\n*" $text]} {
	set list [split $text "\n"]
	if {$auxWidth != 0 && [hasChars $list]} {
	    incr auxWidth 5
	}
	return [expr {[getListWidth $win $list $cellFont] +
		      $auxWidth + $indentWidth}]
    } else {
	if {$auxWidth != 0 && [string length $text] != 0} {
	    incr auxWidth 5
	}
	return [expr {[font measure $cellFont -displayof $win $text] +
		      $auxWidth + $indentWidth}]
    }
}

#------------------------------------------------------------------------------
# tablelist::insertOrUpdateIndent
#
# Sets the width of the indentation label embedded into the text widget w at
# the given index to the specified value, after inserting the label if needed.
# Returns 1 if the label had to be inserted and 0 otherwise.
#------------------------------------------------------------------------------
proc tablelist::insertOrUpdateIndent {w index indent indentWidth} {
    if {[catch {$w window cget $index -create} script] == 0 &&
	[string match "::tablelist::displayIndent *" $script]} {
	if {$indentWidth != [lindex $script end]} {
	    set padY [expr {[$w cget -spacing1] == 0}]
	    set script [lreplace $script end end $indentWidth]
	    $w window configure $index -pady $padY -create $script

	    set path [lindex [$w dump -window $index] 1]
	    if {[string length $path] != 0} {
		$path configure -width $indentWidth
	    }
	}
	return 0
    } else {
	set padY [expr {[$w cget -spacing1] == 0}]
	set indent [lreplace $indent end end $indentWidth]
	$w window create $index -pady $padY -create $indent
	$w tag add elidedWin $index
	return 1
    }
}

#------------------------------------------------------------------------------
# tablelist::insertElem
#
# Inserts the given text and auxiliary object (image or window) into the text
# widget w, just before the character position specified by index.  The object
# will follow the text if alignment is "right", and will precede it otherwise.
#------------------------------------------------------------------------------
proc tablelist::insertElem {w index text aux auxType alignment valignment} {
    set index [$w index $index]

    if {$auxType == 0} {				;# no image or window
	$w insert $index $text
    } elseif {[string compare $alignment "right"] == 0} {
	set padY [expr {[$w cget -spacing1] == 0}]
	if {$auxType == 1} {					;# image
	    set aux [lreplace $aux 4 4 e]
	    $w window create $index -align $valignment -padx 1 -pady $padY \
				    -create $aux
	    $w tag add elidedWin $index
	} else {						;# window
	    if {$auxType == 2} {				;# static width
		place $aux.w -anchor ne -relwidth "" -relx 1.0
	    } else {						;# dynamic width
		place $aux.w -anchor ne -relwidth 1.0 -relx 1.0
	    }
	    $w window create $index -align $valignment -padx 1 -pady $padY \
				    -window $aux
	}
	$w insert $index $text
    } else {
	$w insert $index $text
	set padY [expr {[$w cget -spacing1] == 0}]
	if {$auxType == 1} {					;# image
	    set aux [lreplace $aux 4 4 w]
	    $w window create $index -align $valignment -padx 1 -pady $padY \
				    -create $aux
	    $w tag add elidedWin $index
	} else {						;# window
	    if {$auxType == 2} {				;# static width
		place $aux.w -anchor nw -relwidth "" -relx 0.0
	    } else {						;# dynamic width
		place $aux.w -anchor nw -relwidth 1.0 -relx 0.0
	    }
	    $w window create $index -align $valignment -padx 1 -pady $padY \
				    -window $aux
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::insertMlElem
#
# Inserts the given message widget and auxiliary object (image or window) into
# the text widget w, just before the character position specified by index.
# The object will follow the message widget if alignment is "right", and will
# precede it otherwise.
#------------------------------------------------------------------------------
proc tablelist::insertMlElem {w index msgScript aux auxType alignment
			      valignment} {
    set index [$w index $index]
    set padY [expr {[$w cget -spacing1] == 0}]

    if {$auxType == 0} {				;# no image or window
	$w window create $index -align top -pady $padY -create $msgScript
	$w tag add elidedWin $index
    } elseif {[string compare $alignment "right"] == 0} {
	if {$auxType == 1} {					;# image
	    set aux [lreplace $aux 4 4 e]
	    $w window create $index -align $valignment -padx 1 -pady $padY \
				    -create $aux
	    $w tag add elidedWin $index
	} else {						;# window
	    if {$auxType == 2} {				;# static width
		place $aux.w -anchor ne -relwidth "" -relx 1.0
	    } else {						;# dynamic width
		place $aux.w -anchor ne -relwidth 1.0 -relx 1.0
	    }
	    $w window create $index -align $valignment -padx 1 -pady $padY \
				    -window $aux
	}
	$w window create $index -align top -pady $padY -create $msgScript
	$w tag add elidedWin $index
    } else {
	$w window create $index -align top -pady $padY -create $msgScript
	$w tag add elidedWin $index
	if {$auxType == 1} {					;# image
	    set aux [lreplace $aux 4 4 w]
	    $w window create $index -align $valignment -padx 1 -pady $padY \
				    -create $aux
	    $w tag add elidedWin $index
	} else {						;# window
	    if {$auxType == 2} {				;# static width
		place $aux.w -anchor nw -relwidth "" -relx 0.0
	    } else {						;# dynamic width
		place $aux.w -anchor nw -relwidth 1.0 -relx 0.0
	    }
	    $w window create $index -align $valignment -padx 1 -pady $padY \
				    -window $aux
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::updateCell
#
# Updates the contents of the text widget w starting at index1 and ending just
# before index2 by keeping the auxiliary object (image or window) (if any) and
# replacing only the text between the two character positions.
#------------------------------------------------------------------------------
proc tablelist::updateCell {w index1 index2 text aux auxType auxWidth
			    indent indentWidth alignment valignment} {
    set tagNames [$w tag names $index2]
    if {[lsearch -exact $tagNames select] >= 0} {		;# selected
	$w tag add select $index1 $index2
    }

    if {$indentWidth != 0} {
	if {[insertOrUpdateIndent $w $index1 $indent $indentWidth]} {
	    set index2 $index2+1c
	}
	set index1 $index1+1c
    }

    if {$auxWidth == 0} {				;# no image or window
	#
	# Work around a Tk peculiarity on Windows, related to deleting
	# an embedded window while resizing a text widget interactively
	#
	set path [lindex [$w dump -window $index1] 1]
	if {[string length $path] != 0 &&
	    [string compare [winfo class $path] "Message"] == 0} {
	    $path configure -text ""
	    $w window configure $index1 -window ""
	}

	if {$::tk_version >= 8.5} {
	    $w replace $index1 $index2 $text
	} else {
	    $w delete $index1 $index2
	    $w insert $index1 $text
	}
    } else {
	#
	# Check whether the image label or the frame containing a
	# window is mapped at the first or last position of the cell
	#
	if {$auxType == 1} {					;# image
	    if {[setImgLabelWidth $w $index1 $auxWidth]} {
		set auxFound 1
		set fromIdx $index1+1c
		set toIdx $index2
	    } elseif {[setImgLabelWidth $w $index2-1c $auxWidth]} {
		set auxFound 1
		set fromIdx $index1
		set toIdx $index2-1c
	    } else {
		set auxFound 0
		set fromIdx $index1
		set toIdx $index2
	    }
	} else {						;# window
	    if {[$aux cget -width] != $auxWidth} {
		$aux configure -width $auxWidth
	    }

	    if {[string compare [lindex [$w dump -window $index1] 1] \
		 $aux] == 0} {
		set auxFound 1
		set fromIdx $index1+1c
		set toIdx $index2
	    } elseif {[string compare [lindex [$w dump -window $index2-1c] 1] \
		       $aux] == 0} {
		set auxFound 1
		set fromIdx $index1
		set toIdx $index2-1c
	    } else {
		set auxFound 0
		set fromIdx $index1
		set toIdx $index2
	    }
	}

	#
	# Work around a Tk peculiarity on Windows, related to deleting
	# an embedded window while resizing a text widget interactively
	#
	set path [lindex [$w dump -window $fromIdx] 1]
	if {[string length $path] != 0 &&
	    [string compare [winfo class $path] "Message"] == 0} {
	    $path configure -text ""
	    $w window configure $fromIdx -window ""
	}

	$w delete $fromIdx $toIdx

	if {$auxFound} {
	    #
	    # Adjust the aux. window and insert the text
	    #
	    if {[string compare $alignment "right"] == 0} {
		if {$auxType == 1} {				;# image
		    setImgLabelAnchor $w $index1 e
		} else {					;# window
		    if {$auxType == 2} {			;# static width
			place $aux.w -anchor ne -relwidth "" -relx 1.0
		    } else {					;# dynamic width
			place $aux.w -anchor ne -relwidth 1.0 -relx 1.0
		    }
		}
		set index $index1
	    } else {
		if {$auxType == 1} {				;# image
		    setImgLabelAnchor $w $index1 w
		} else {					;# window
		    if {$auxType == 2} {			;# static width
			place $aux.w -anchor nw -relwidth "" -relx 0.0
		    } else {					;# dynamic width
			place $aux.w -anchor nw -relwidth 1.0 -relx 0.0
		    }
		}
		set index $index1+1c
	    }
	    if {[string compare $valignment [$w window cget $index1 -align]]
		!= 0} {
		$w window configure $index1 -align $valignment
	    }
	    $w insert $index $text
	} else {
	    #
	    # Insert the text and the aux. window
	    #
	    if {$auxType == 1} {				;# image
		set aux [lreplace $aux end end $auxWidth]
	    } else {						;# window
		if {[$aux cget -width] != $auxWidth} {
		    $aux configure -width $auxWidth
		}
	    }
	    insertElem $w $index1 $text $aux $auxType $alignment $valignment
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::updateMlCell
#
# Updates the contents of the text widget w starting at index1 and ending just
# before index2 by keeping the auxiliary object (image or window) (if any) and
# replacing only the multiline text between the two character positions.
#------------------------------------------------------------------------------
proc tablelist::updateMlCell {w index1 index2 msgScript aux auxType auxWidth
			      indent indentWidth alignment valignment} {
    set tagNames [$w tag names $index2]
    if {[lsearch -exact $tagNames select] >= 0} {		;# selected
	$w tag add select $index1 $index2
    }

    if {$indentWidth != 0} {
	if {[insertOrUpdateIndent $w $index1 $indent $indentWidth]} {
	    set index2 $index2+1c
	}
	set index1 $index1+1c
    }

    if {$auxWidth == 0} {				;# no image or window
	set areEqual [$w compare $index1 == $index2]
	$w delete $index1+1c $index2
	set padY [expr {[$w cget -spacing1] == 0}]
	if {[catch {$w window cget $index1 -create} script] == 0 &&
	    [string match "::tablelist::displayText*" $script]} {
	    $w window configure $index1 \
		      -align top -pady $padY -create $msgScript

	    set path [lindex [$w dump -window $index1] 1]
	    if {[string length $path] != 0 &&
		[string compare [winfo class $path] "Message"] == 0} {
		eval $msgScript
	    }
	} else {
	    if {!$areEqual} {
		$w delete $index1
	    }
	    $w window create $index1 -align top -pady $padY -create $msgScript
	    $w tag add elidedWin $index1
	}
    } else {
	#
	# Check whether the image label or the frame containing a
	# window is mapped at the first or last position of the cell
	#
	$w mark set index2Mark $index2
	if {$auxType == 1} {					;# image
	    if {[setImgLabelWidth $w $index1 $auxWidth]} {
		set auxFound 1
		if {[string compare $alignment "right"] == 0} {
		    $w delete $index1+1c $index2
		}
	    } elseif {[setImgLabelWidth $w $index2-1c $auxWidth]} {
		set auxFound 1
		if {[string compare $alignment "right"] != 0} {
		    $w delete $index1 $index2-1c
		}
	    } else {
		set auxFound 0
		$w delete $index1 $index2
	    }
	} else {						;# window
	    if {[$aux cget -width] != $auxWidth} {
		$aux configure -width $auxWidth
	    }

	    if {[string compare [lindex [$w dump -window $index1] 1] \
		 $aux] == 0} {
		set auxFound 1
		if {[string compare $alignment "right"] == 0} {
		    $w delete $index1+1c $index2
		}
	    } elseif {[string compare [lindex [$w dump -window $index2-1c] 1] \
		       $aux] == 0} {
		set auxFound 1
		if {[string compare $alignment "right"] != 0} {
		    $w delete $index1 $index2-1c
		}
	    } else {
		set auxFound 0
		$w delete $index1 $index2
	    }
	}

	if {$auxFound} {
	    #
	    # Adjust the aux. window and insert the message widget
	    #
	    if {[string compare $alignment "right"] == 0} {
		if {$auxType == 1} {				;# image
		    setImgLabelAnchor $w index2Mark-1c e
		} else {					;# window
		    if {$auxType == 2} {			;# static width
			place $aux.w -anchor ne -relwidth "" -relx 1.0
		    } else {					;# dynamic width
			place $aux.w -anchor ne -relwidth 1.0 -relx 1.0
		    }
		}
		set auxIdx index2Mark-1c
		set msgIdx index2Mark-2c
	    } else {
		if {$auxType == 1} {				;# image
		    setImgLabelAnchor $w $index1 w
		} else {					;# window
		    if {$auxType == 2} {			;# static width
			place $aux.w -anchor nw -relwidth "" -relx 0.0
		    } else {					;# dynamic width
			place $aux.w -anchor nw -relwidth 1.0 -relx 0.0
		    }
		}
		set auxIdx $index1
		set msgIdx $index1+1c
	    }
	    if {[string compare $valignment [$w window cget $auxIdx -align]]
		!= 0} {
		$w window configure $auxIdx -align $valignment
	    }

	    set padY [expr {[$w cget -spacing1] == 0}]
	    if {[catch {$w window cget $msgIdx -create} script] == 0 &&
		[string match "::tablelist::displayText*" $script]} {
		$w window configure $msgIdx \
			  -align top -pady $padY -create $msgScript

		set path [lindex [$w dump -window $msgIdx] 1]
		if {[string length $path] != 0 &&
		    [string compare [winfo class $path] "Message"] == 0} {
		    eval $msgScript
		}
	    } elseif {[string compare $alignment "right"] == 0} {
		$w window create index2Mark-1c \
			  -align top -pady $padY -create $msgScript
		$w tag add elidedWin index2Mark-1c
		$w delete $index1 index2Mark-2c
	    } else {
		$w window create $index1+1c \
			  -align top -pady $padY -create $msgScript
		$w tag add elidedWin $index1+1c
		$w delete $index1+2c index2Mark
	    }
	} else {
	    #
	    # Insert the message and aux. windows
	    #
	    if {$auxType == 1} {				;# image
		set aux [lreplace $aux end end $auxWidth]
	    } else {						;# window
		if {[$aux cget -width] != $auxWidth} {
		    $aux configure -width $auxWidth
		}
	    }
	    insertMlElem $w $index1 $msgScript $aux $auxType $alignment \
			 $valignment
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::setImgLabelWidth
#
# Sets the width of the image label embedded into the text widget w at the
# given index to the specified value.
#------------------------------------------------------------------------------
proc tablelist::setImgLabelWidth {w index width} {
    if {[catch {$w window cget $index -create} script] == 0 &&
	[string match "::tablelist::displayImage *" $script]} {
	if {$width != [lindex $script end]} {
	    set padY [expr {[$w cget -spacing1] == 0}]
	    set script [lreplace $script end end $width]
	    $w window configure $index -pady $padY -create $script

	    set path [lindex [$w dump -window $index] 1]
	    if {[string length $path] != 0} {
		$path configure -width $width
	    }
	}

	return 1
    } else {
	return 0
    }
}

#------------------------------------------------------------------------------
# tablelist::setImgLabelAnchor
#
# Sets the anchor of the image label embedded into the text widget w at the
# given index to the specified value.
#------------------------------------------------------------------------------
proc tablelist::setImgLabelAnchor {w index anchor} {
    set script [$w window cget $index -create]
    if {[string compare $anchor [lindex $script 4]] != 0} {
	set padY [expr {[$w cget -spacing1] == 0}]
	set script [lreplace $script 4 4 $anchor]
	$w window configure $index -pady $padY -create $script

	set path [lindex [$w dump -window $index] 1]
	if {[string length $path] != 0} {
	    $path configure -anchor $anchor
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::appendComplexElem
#
# Adjusts the given text and the width of the auxiliary object (image or
# window) corresponding to the specified cell of the tablelist widget win, and
# inserts the text and the auxiliary object (if any) just before the newline
# character at the end of the specified line of the tablelist's body.
#------------------------------------------------------------------------------
proc tablelist::appendComplexElem {win key row col text pixels alignment
				   snipStr cellFont cellTags line} {
    #
    # Adjust the cell text and the image or window width
    #
    set multiline [string match "*\n*" $text]
    upvar ::tablelist::ns${win}::data data
    if {$pixels == 0} {				;# convention: dynamic width
	if {$data($col-maxPixels) > 0} {
	    if {$data($col-reqPixels) > $data($col-maxPixels)} {
		set pixels $data($col-maxPixels)
	    }
	}
    }
    set aux [getAuxData $win $key $col auxType auxWidth $pixels]
    set indent [getIndentData $win $key $col indentWidth]
    set maxTextWidth $pixels
    if {$pixels != 0} {
	incr pixels $data($col-delta)
	set maxTextWidth [getMaxTextWidth $pixels $auxWidth $indentWidth]

	if {$data($col-wrap) && !$multiline} {
	    if {[font measure $cellFont -displayof $win $text] >
		$maxTextWidth} {
		set multiline 1
	    }
	}
    }
    variable snipSides
    set snipSide $snipSides($alignment,$data($col-changesnipside))
    if {$multiline} {
	set list [split $text "\n"]
	if {$data($col-wrap)} {
	    set snipSide ""
	}
	adjustMlElem $win list auxWidth indentWidth $cellFont $pixels \
		     $snipSide $snipStr
	set msgScript [list ::tablelist::displayText $win $key $col \
		       [join $list "\n"] $cellFont $maxTextWidth $alignment]
    } else {
	adjustElem $win text auxWidth indentWidth $cellFont $pixels \
		   $snipSide $snipStr
    }

    #
    # Insert the text and the auxiliary object (if any) just before the newline
    #
    set w $data(body)
    set idx [$w index $line.end]
    if {$auxWidth == 0} {				;# no image or window
	if {$multiline} {
	    $w insert $line.end "\t\t" $cellTags
	    set padY [expr {[$w cget -spacing1] == 0}]
	    $w window create $line.end-1c \
		      -align top -pady $padY -create $msgScript
	    $w tag add elidedWin $line.end-1c
	} else {
	    $w insert $line.end "\t$text\t" $cellTags
	}
    } else {
	$w insert $line.end "\t\t" $cellTags
	if {$auxType == 1} {					;# image
	    #
	    # Update the creation script for the image label
	    #
	    set aux [lreplace $aux end end $auxWidth]
	} else {						;# window
	    #
	    # Create a frame and evaluate the script that
	    # creates a child window within the frame
	    #
	    tk::frame $aux -borderwidth 0 -class TablelistWindow -container 0 \
			   -height $data($key,$col-reqHeight) \
			   -highlightthickness 0 -relief flat \
			   -takefocus 0 -width $auxWidth
	    catch {$aux configure -padx 0 -pady 0}
	    bindtags $aux [linsert [bindtags $aux] 1 \
			   $data(bodyTag) TablelistBody]
	    uplevel #0 $data($key,$col-window) [list $win $row $col $aux.w]
	}
	if {$multiline} {
	    insertMlElem $w $line.end-1c $msgScript $aux $auxType $alignment \
			 [getVAlignment $win $key $col]
	} else {
	    insertElem $w $line.end-1c $text $aux $auxType $alignment \
		       [getVAlignment $win $key $col]
	}
    }

    #
    # Insert the indentation image, if any
    #
    if {$indentWidth != 0} {
	insertOrUpdateIndent $w $idx+1c $indent $indentWidth
    }
}

#------------------------------------------------------------------------------
# tablelist::makeColFontAndTagLists
#
# Builds the lists data(colFontList) of the column fonts and data(colTagsList)
# of the column tag names for the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::makeColFontAndTagLists win {
    upvar ::tablelist::ns${win}::data data
    set widgetFont $data(-font)
    set data(colFontList) {}
    set data(colTagsList) {}
    set data(hasColTags) 0
    set viewable [winfo viewable $win]
    variable canElide

    for {set col 0} {$col < $data(colCount)} {incr col} {
	set tagNames {}

	if {[info exists data($col-font)]} {
	    lappend data(colFontList) $data($col-font)
	    lappend tagNames col-font-$data($col-font)
	    set data(hasColTags) 1
	} else {
	    lappend data(colFontList) $widgetFont
	}

	if {$viewable && $data($col-hide) && $canElide} {
	    lappend tagNames hiddenCol
	    set data(hasColTags) 1
	}

	lappend data(colTagsList) $tagNames
    }
}

#------------------------------------------------------------------------------
# tablelist::makeSortAndArrowColLists
#
# Builds the lists data(sortColList) of the sort columns and data(arrowColList)
# of the arrow columns for the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::makeSortAndArrowColLists win {
    upvar ::tablelist::ns${win}::data data
    set data(sortColList) {}
    set data(arrowColList) {}

    #
    # Build a list of {col sortRank} pairs and sort it based on sortRank
    #
    set pairList {}
    for {set col 0} {$col < $data(colCount)} {incr col} {
	if {$data($col-sortRank) > 0} {
	    lappend pairList [list $col $data($col-sortRank)]
	}
    }
    set pairList [lsort -integer -index 1 $pairList]

    #
    # Build data(sortColList) and data(arrowColList), and update
    # the sort ranks to have values from 1 to [llength $pairList]
    #
    set sortRank 1
    foreach pair $pairList {
	set col [lindex $pair 0]
	lappend data(sortColList) $col
	set data($col-sortRank) $sortRank
	if {$sortRank < 10 && $data(-showarrow) && $data($col-showarrow)} {
	    lappend data(arrowColList) $col
	    configCanvas $win $col
	    raiseArrow $win $col
	}
	incr sortRank
    }

    #
    # Special handling for the "aqua" theme if Cocoa is being used:
    # Deselect all header labels and select that of the main sort column
    #
    variable specialAquaHandling
    if {$specialAquaHandling &&
	[string compare [getCurrentTheme] "aqua"] == 0} {
	for {set col 0} {$col < $data(colCount)} {incr col} {
	    configLabel $data(hdrTxtFrmLbl)$col -selected 0
	}

	if {[llength $data(sortColList)] != 0} {
	    set col [lindex $data(sortColList) 0]
	    configLabel $data(hdrTxtFrmLbl)$col -selected 1
	    raise $data(hdrTxtFrmLbl)$col
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::setupColumns
#
# Updates the value of the -colums configuration option for the tablelist
# widget win by using the width, title, and alignment specifications given in
# the columns argument, and creates the corresponding label (and separator)
# widgets if createLabels is true.
#------------------------------------------------------------------------------
proc tablelist::setupColumns {win columns createLabels} {
    variable usingTile
    variable configSpecs
    variable configOpts
    variable alignments
    upvar ::tablelist::ns${win}::data data

    set argCount [llength $columns]
    set colConfigVals {}

    #
    # Check the syntax of columns before performing any changes
    #
    for {set n 0} {$n < $argCount} {incr n} {
	#
	# Get the column width
	#
	set width [lindex $columns $n]
	set width [format "%d" $width]	;# integer check with error message

	#
	# Get the column title
	#
	if {[incr n] == $argCount} {
	    return -code error "column title missing"
	}
	set title [lindex $columns $n]

	#
	# Get the column alignment
	#
	set alignment left
	if {[incr n] < $argCount} {
	    set next [lindex $columns $n]
	    if {[isInteger $next]} {
		incr n -1
	    } else {
		set alignment [mwutil::fullOpt "alignment" $next $alignments]
	    }
	}

	#
	# Append the properly formatted values of width,
	# title, and alignment to the list colConfigVals
	#
	lappend colConfigVals $width $title $alignment
    }

    #
    # Save the value of colConfigVals in data(-columns)
    #
    set data(-columns) $colConfigVals

    #
    # Delete the labels, canvases, and separators if requested
    #
    if {$createLabels} {
	foreach w [winfo children $data(hdrTxtFrm)] {
	    destroy $w
	}
	foreach w [winfo children $win] {
	    if {[regexp {^(vsep[0-9]+|hsep)$} [winfo name $w]]} {
		destroy $w
	    }
	}
	set data(fmtCmdFlagList) {}
	set data(hiddenColCount) 0
    }

    #
    # Build the list data(colList), and create
    # the labels and canvases if requested
    #
    regexp {^(flat|flatAngle|sunken|photo)([0-9]+)x([0-9]+)$} \
	   $data(-arrowstyle) dummy arrowRelief arrowWidth arrowHeight
    set widgetFont $data(-font)
    set oldColCount $data(colCount)
    set data(colList) {}
    set data(colCount) 0
    set data(lastCol) -1
    set col 0
    foreach {width title alignment} $data(-columns) {
	#
	# Append the width in pixels and the
	# alignment to the list data(colList)
	#
	if {$width > 0} {		;# convention: width in characters
	    set pixels [charsToPixels $win $widgetFont $width]
	    set data($col-lastStaticWidth) $pixels
	} elseif {$width < 0} {		;# convention: width in pixels
	    set pixels [expr {(-1)*$width}]
	    set data($col-lastStaticWidth) $pixels
	} else {			;# convention: dynamic width
	    set pixels 0
	}
	lappend data(colList) $pixels $alignment
	incr data(colCount)
	set data(lastCol) $col

	if {$createLabels} {
	    set data($col-elide) 0
	    foreach {name val} {delta 0  lastStaticWidth 0  maxPixels 0
				sortOrder ""  sortRank 0  isSnipped 0
				changesnipside 0  changetitlesnipside 0
				editable 0  editwindow entry  hide 0
				maxwidth 0  resizable 1  showarrow 1
				showlinenumbers 0  sortmode ascii
				valign center  wrap 0} {
		if {![info exists data($col-$name)]} {
		    set data($col-$name) $val
		}
	    }
	    lappend data(fmtCmdFlagList) [info exists data($col-formatcommand)]
	    incr data(hiddenColCount) $data($col-hide)

	    #
	    # Create the label
	    #
	    set w $data(hdrTxtFrmLbl)$col
	    if {$usingTile} {
		ttk::label $w -style TablelistHeader.TLabel -image "" \
			      -padding {1 1 1 1} -takefocus 0 -text "" \
			      -textvariable "" -underline -1 -wraplength 0
	    } else {
		tk::label $w -bitmap "" -highlightthickness 0 -image "" \
			     -takefocus 0 -text "" -textvariable "" \
			     -underline -1 -wraplength 0
	    }

	    #
	    # Apply to it the current configuration options
	    #
	    foreach opt $configOpts {
		set optGrp [lindex $configSpecs($opt) 2]
		if {[string compare $optGrp "l"] == 0} {
		    set optTail [string range $opt 6 end]
		    if {[info exists data($col$opt)]} {
			configLabel $w -$optTail $data($col$opt)
		    } else {
			configLabel $w -$optTail $data($opt)
		    }
		} elseif {[string compare $optGrp "c"] == 0} {
		    configLabel $w $opt $data($opt)
		}
	    }
	    catch {configLabel $w -state $data(-state)}

	    #
	    # Replace the binding tag (T)Label with $data(labelTag) and
	    # TablelistLabel in the list of binding tags of the label
	    #
	    bindtags $w [lreplace [bindtags $w] 1 1 \
			 $data(labelTag) TablelistLabel]

	    #
	    # Create a canvas containing the sort arrows
	    #
	    set w $data(hdrTxtFrmCanv)$col
	    canvas $w -borderwidth 0 -highlightthickness 0 \
		      -relief flat -takefocus 0
	    createArrows $w $arrowWidth $arrowHeight $arrowRelief

	    #
	    # Apply to it the current configuration options
	    #
	    foreach opt $configOpts {
		if {[string compare [lindex $configSpecs($opt) 2] "c"] == 0} {
		    $w configure $opt $data($opt)
		}
	    }

	    #
	    # Replace the binding tag Canvas with $data(labelTag) and
	    # TablelistArrow in the list of binding tags of the canvas
	    #
	    bindtags $w [lreplace [bindtags $w] 1 1 \
			 $data(labelTag) TablelistArrow]

	    if {[info exists data($col-labelimage)]} {
		doColConfig $col $win -labelimage $data($col-labelimage)
	    }
	}

	#
	# Configure the edit window if present
	#
	if {$col == $data(editCol) &&
	    [string compare [winfo class $data(bodyFrmEd)] "Mentry"] != 0} {
	    catch {$data(bodyFrmEd) configure -justify $alignment}
	}

	incr col
    }
    set data(hasFmtCmds) [expr {[lsearch -exact $data(fmtCmdFlagList) 1] >= 0}]

    #
    # Clean up the images, data, and attributes
    # associated with the deleted columns
    #
    set imgNames [image names]
    for {set col $data(colCount)} {$col < $oldColCount} {incr col} {
	set w $data(hdrTxtFrmCanv)$col
	foreach shape {triangleUp darkLineUp lightLineUp
		       triangleDn darkLineDn lightLineDn} {
	    if {[lsearch -exact $imgNames $shape$w] >= 0} {
		image delete $shape$w
	    }
	}

	deleteColData $win $col
	deleteColAttribs $win $col
    }

    #
    # Update data(-treecolumn) and data(treeCol) if needed
    #
    if {$createLabels} {
	set treeCol $data(-treecolumn)
	adjustColIndex $win treeCol
	set data(treeCol) $treeCol
	if {$data(colCount) != 0} { 
	    set data(-treecolumn) $treeCol
	}
    }

    #
    # Create the separators if needed
    #
    if {$createLabels && $data(-showseparators)} {
	createSeps $win
    }
}

#------------------------------------------------------------------------------
# tablelist::createSeps
#
# Creates and manages the separators in the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::createSeps win {
    upvar ::tablelist::ns${win}::data data
    variable usingTile
    set sepX [getSepX]

    for {set col 0} {$col < $data(colCount)} {incr col} {
	#
	# Create the col'th separator and attach it to
	# the right edge of the col'th header label
	#
	set w $data(vsep)$col
	if {$usingTile} {
	    ttk::separator $w -style Seps$win.TSeparator \
			      -cursor $data(-cursor) -orient vertical \
			      -takefocus 0
	} else {
	    tk::frame $w -background $data(-background) -borderwidth 1 \
			 -container 0 -cursor $data(-cursor) \
			 -highlightthickness 0 -relief sunken \
			 -takefocus 0 -width 2
	}
	place $w -in $data(hdrTxtFrmLbl)$col -anchor ne -bordermode outside \
		 -relx 1.0 -x $sepX

	#
	# Replace the binding tag TSeparator or Frame with $data(bodyTag)
	# and TablelistBody in the list of binding tags of the separator
	#
	bindtags $w [lreplace [bindtags $w] 1 1 $data(bodyTag) TablelistBody]
    }

    #
    # Create the horizontal separator
    #
    set w $data(hsep)
    if {$usingTile} {
	ttk::separator $w -style Seps$win.TSeparator -cursor $data(-cursor) \
			  -takefocus 0
    } else {
	tk::frame $w -background $data(-background) -borderwidth 1 \
		     -container 0 -cursor $data(-cursor) -height 2 \
		     -highlightthickness 0 -relief sunken -takefocus 0
    }

    #
    # Replace the binding tag TSeparator or Frame with $data(bodyTag) and
    # TablelistBody in the list of binding tags of the horizontal separator
    #
    bindtags $w [lreplace [bindtags $w] 1 1 $data(bodyTag) TablelistBody]
    
    adjustSepsWhenIdle $win
}

#------------------------------------------------------------------------------
# tablelist::adjustSepsWhenIdle
#
# Arranges for the height and vertical position of each separator in the
# tablelist widget win to be adjusted at idle time.
#------------------------------------------------------------------------------
proc tablelist::adjustSepsWhenIdle win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(sepsId)]} {
	return ""
    }

    set data(sepsId) [after idle [list tablelist::adjustSeps $win]]
}

#------------------------------------------------------------------------------
# tablelist::adjustSeps
#
# Adjusts the height and position of each separator in the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::adjustSeps win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(sepsId)]} {
	after cancel $data(sepsId)
	unset data(sepsId)
    }

    variable winSys
    set onWindows [expr {[string compare $winSys "win32"] == 0}]
    variable usingTile
    set sepX [getSepX]

    #
    # Get the height to be applied to the column separators
    # and place or unmanage the horizontal separator
    #
    set w $data(body)
    if {$data(-fullseparators)} {
	set sepHeight [winfo height $w]

	if {[winfo exists $data(hsep)]} {
	    place forget $data(hsep)
	}
    } else {
	set btmTextIdx [$w index @0,$data(btmY)]
	set btmLine [expr {int($btmTextIdx)}]
	if {$btmLine > $data(itemCount)} {		;# text widget bug
	    set btmLine $data(itemCount)
	    set btmTextIdx $btmLine.0
	}
	set dlineinfo [$w dlineinfo $btmTextIdx]
	if {$data(itemCount) == 0 || [llength $dlineinfo] == 0} {
	    set sepHeight 0
	} else {
	    foreach {x y width height baselinePos} $dlineinfo {}
	    set sepHeight [expr {$y + $height}]
	}

	if {$data(-showhorizseparator) && $data(-showseparators) &&
	    $sepHeight > 0 && $sepHeight < [winfo height $w]} {
	    set width [expr {[winfo reqwidth $data(hdrTxtFrm)] + $sepX -
			     [winfo reqheight $data(hsep)] + 1}]
	    if {$onWindows && !$usingTile} {
		incr width
	    }
	    place $data(hsep) -in $w -y $sepHeight -width $width
	} elseif {[winfo exists $data(hsep)]} {
	    place forget $data(hsep)
	}
    }

    #
    # Set the height of the main separator (if any) and attach the
    # latter to the right edge of the last non-hidden title column
    #
    set startCol [expr {$data(-titlecolumns) - 1}]
    if {$startCol > $data(lastCol)} {
	set startCol $data(lastCol)
    }
    for {set col $startCol} {$col >= 0} {incr col -1} {
	if {!$data($col-hide)} {
	    break
	}
    }
    set mainSepHeight [expr {$sepHeight + [winfo height $data(hdr)] - 1}]
    set w $data(vsep)
    if {$col < 0 || $mainSepHeight == 0} {
	if {[winfo exists $w]} {
	    place forget $w
	}
    } else {
	if {!$data(-showlabels)} {
	    incr mainSepHeight
	}
	place $w -in $data(hdrTxtFrmLbl)$col -anchor ne -bordermode outside \
		 -height $mainSepHeight -relx 1.0 -x $sepX -y 1
	raise $w
    }

    #
    # Set the height and vertical position of the other column separators
    #
    if {$sepHeight == 0} {
	set relY 0.0
	set y -10
    } elseif {$data(-showlabels)} {
	set relY 1.0
	if {$usingTile || $onWindows} {
	    set y 0
	    incr sepHeight 1
	} else {
	    set y -1
	    incr sepHeight 2
	}
    } else {
	set relY 0.0
	if {$usingTile || $onWindows} {
	    set y 1
	    incr sepHeight 2
	} else {
	    set y 0
	    incr sepHeight 3
	}
    }
    foreach w [winfo children $win] {
	if {[regexp {^vsep[0-9]+$} [winfo name $w]]} {
	    place configure $w -height $sepHeight -rely $relY -y $y
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::getSepX
#
# Returns the value of the -x option to be used when placing a separator
# relative to the corresponding header label, with -anchor ne.
#------------------------------------------------------------------------------
proc tablelist::getSepX {} {
    set x 1
    variable usingTile
    if {$usingTile} {
	set currentTheme [getCurrentTheme]
	variable xpStyle
	if {([string compare $currentTheme "aqua"] == 0) ||
	    ([string compare $currentTheme "xpnative"] == 0 && $xpStyle)} {
	    set x 0
	} elseif {[string compare $currentTheme "tileqt"] == 0} {
	    switch -- [string tolower [tileqt_currentThemeName]] {
		cleanlooks -
		gtk+ -
		oxygen	{ set x 0 }
		qtcurve	{ set x 2 }
	    }
	}
    }

    return $x
}

#------------------------------------------------------------------------------
# tablelist::adjustColumns
#
# Applies some configuration options to the labels of the tablelist widget win,
# places them in the header frame, computes and sets the tab stops for the body
# text widget, and adjusts the width and height of the header frame.  The
# whichWidths argument specifies the dynamic-width columns or labels whose
# widths are to be computed when performing these operations.  The stretchCols
# argument specifies whether to stretch the stretchable columns.
#------------------------------------------------------------------------------
proc tablelist::adjustColumns {win whichWidths stretchCols} {
    set compAllColWidths [expr {[string compare $whichWidths "allCols"] == 0}]
    set compAllLabelWidths \
	[expr {[string compare $whichWidths "allLabels"] == 0}]

    variable usingTile
    set usingAquaTheme \
	[expr {$usingTile && [string compare [getCurrentTheme] "aqua"] == 0}]

    #
    # Configure the labels and compute the positions of
    # the tab stops to be set in the body text widget
    #
    upvar ::tablelist::ns${win}::data data
    set data(hdrPixels) 0
    variable canElide
    variable centerArrows
    set tabs {}
    set col 0
    set x 0
    foreach {pixels alignment} $data(colList) {
	set w $data(hdrTxtFrmLbl)$col
	if {$data($col-hide) && !$canElide} {
	    place forget $w
	    incr col
	    continue
	}

	#
	# Adjust the col'th label
	#
	if {[info exists data($col-labelalign)]} {
	    set labelAlignment $data($col-labelalign)
	} else {
	    set labelAlignment $alignment
	}
	if {$pixels != 0} {			;# convention: static width
	    incr pixels $data($col-delta)
	}
	adjustLabel $win $col $pixels $labelAlignment

	if {$pixels == 0} {			;# convention: dynamic width
	    #
	    # Compute the column or label width if requested
	    #
	    if {$compAllColWidths || [lsearch -exact $whichWidths $col] >= 0} {
		computeColWidth $win $col
	    } elseif {$compAllLabelWidths ||
		      [lsearch -exact $whichWidths l$col] >= 0} {
		computeLabelWidth $win $col
	    }

	    set pixels $data($col-reqPixels)
	    if {$data($col-maxPixels) > 0 && $pixels > $data($col-maxPixels)} {
		set pixels $data($col-maxPixels)
		incr pixels $data($col-delta)
		adjustLabel $win $col $pixels $labelAlignment
	    } else {
		incr pixels $data($col-delta)
	    }
	}

	if {$col == $data(editCol) &&
	    ![string match "*Checkbutton" [winfo class $data(bodyFrmEd)]]} {
	    adjustEditWindow $win $pixels
	}

	set canvas $data(hdrTxtFrmCanv)$col
	if {[lsearch -exact $data(arrowColList) $col] >= 0 &&
	    !$data($col-elide) && !$data($col-hide)} {
	    #
	    # Center the canvas horizontally just below the upper edge of
	    # the label, or place it to the left side of the label if the
	    # latter is right-justified and to its right side otherwise
	    #
	    if {$centerArrows} {
		place $canvas -in $w -anchor n -bordermode outside \
			      -relx 0.5 -y 1
	    } else {
		set y 0
		if {([winfo reqheight $w] - [winfo reqheight $canvas]) % 2 == 0
		    && $data(arrowHeight) == 5} {
		    set y -1
		}
		if {[string compare $labelAlignment "right"] == 0} {
		    place $canvas -in $w -anchor w -bordermode outside \
				  -relx 0.0 -x $data(charWidth) \
				  -rely 0.49 -y $y
		} else {
		    place $canvas -in $w -anchor e -bordermode outside \
				  -relx 1.0 -x -$data(charWidth) \
				  -rely 0.49 -y $y
		}
	    }
	    raise $canvas
	} else {
	    place forget $canvas
	}

	#
	# Place the label in the header frame
	#
	if {$data($col-elide) || $data($col-hide)} {
	    foreach l [getSublabels $w] {
		place forget $l
	    }
	    place $w -x [expr {$x - 1}] -relheight 1.0 -width 1
	    lower $w
	} else {
	    set x2 $x
	    set labelPixels [expr {$pixels + 2*$data(charWidth)}]
	    if {$usingAquaTheme} {
		incr x2 -1
		incr labelPixels
		if {$col == 0} {
		    incr x2 -1
		    incr labelPixels
		}
	    }
	    place $w -x $x2 -relheight 1.0 -width $labelPixels
	}

	#
	# Append a tab stop and the alignment to the tabs list
	#
	if {!$data($col-elide) && !$data($col-hide)} {
	    incr x $data(charWidth)
	    switch $alignment {
		left {
		    lappend tabs $x left
		    incr x $pixels
		}
		right {
		    incr x $pixels
		    lappend tabs $x right
		}
		center {
		    lappend tabs [expr {$x + $pixels/2}] center
		    incr x $pixels
		}
	    }
	    incr x $data(charWidth)
	    lappend tabs $x left
	}

	incr col
    }
    place configure $data(hdrFrm) -x $x

    #
    # Apply the value of tabs to the body text widget
    #
    if {[info exists data(colBeingResized)]} {
	$data(body) tag configure visibleLines -tabs $tabs
    } else {
	$data(body) configure -tabs $tabs
    }

    #
    # Adjust the width and height of the frames data(hdrTxtFrm) and data(hdr)
    #
    $data(hdrTxtFrm) configure -width $x
    if {$data(-width) <= 0} {
	if {$stretchCols} {
	    $data(hdr) configure -width $x
	    $data(lb) configure -width [expr {$x / $data(charWidth)}]
	}
    } else {
	$data(hdr) configure -width 0
    }
    set data(hdrPixels) $x
    adjustHeaderHeight $win

    #
    # Stretch the stretchable columns if requested, and update
    # the scrolled column offset and the horizontal scrollbar
    #
    if {$stretchCols} {
	stretchColumnsWhenIdle $win
    }
    if {![info exists data(colBeingResized)]} {
	updateScrlColOffsetWhenIdle $win
    }
    updateHScrlbarWhenIdle $win
}

#------------------------------------------------------------------------------
# tablelist::adjustLabel
#
# Applies some configuration options to the col'th label of the tablelist
# widget win as well as to the label's sublabels (if any), and places the
# sublabels.
#------------------------------------------------------------------------------
proc tablelist::adjustLabel {win col pixels alignment} {
    variable usingTile
    set usingAquaTheme \
	[expr {$usingTile && [string compare [getCurrentTheme] "aqua"] == 0}]

    #
    # Apply some configuration options to the label and its sublabels (if any)
    #
    upvar ::tablelist::ns${win}::data data
    set w $data(hdrTxtFrmLbl)$col
    variable anchors
    set anchor $anchors($alignment)
    set borderWidth [winfo pixels $w [$w cget -borderwidth]]
    if {$borderWidth < 0} {
	set borderWidth 0
    }
    set padX [expr {$data(charWidth) - $borderWidth}]
    if {$padX < 0} {
	set padX 0
    }
    set padL $padX
    set padR $padX
    set marginL $data(charWidth)
    set marginR $data(charWidth)
    if {$usingAquaTheme} {
	incr padL
	incr marginL
	if {$col == 0} {
	    incr padL
	    incr marginL
	}
	set padding [$w cget -padding]
	lset padding 0 $padL
	lset padding 2 $padR
	$w configure -anchor $anchor -justify $alignment -padding $padding
    } else {
	configLabel $w -anchor $anchor -justify $alignment -padx $padX
    }
    if {[info exists data($col-labelimage)]} {
	set imageWidth [image width $data($col-labelimage)]
	$w-tl configure -anchor $anchor -justify $alignment
    } else {
	set imageWidth 0
    }

    #
    # Make room for the canvas displaying an up- or down-arrow if needed
    #
    set title [lindex $data(-columns) [expr {3*$col + 1}]]
    set labelFont [$w cget -font]
    set spaces ""
    set spacePixels 0
    if {[lsearch -exact $data(arrowColList) $col] >= 0} {
	set canvas $data(hdrTxtFrmCanv)$col
	set canvasWidth $data(arrowWidth)
	if {[llength $data(arrowColList)] > 1} {
	    incr canvasWidth 6
	    $canvas itemconfigure sortRank \
		    -image sortRank$data($col-sortRank)$win
	}
	$canvas configure -width $canvasWidth

	variable centerArrows
	if {!$centerArrows} {
	    set spaceWidth [font measure $labelFont -displayof $w " "]
	    set spaces "  "
	    set n 2
	    while {$n*$spaceWidth < $canvasWidth + $data(charWidth)} {
		append spaces " "
		incr n
	    }
	    set spacePixels [expr {$n * $spaceWidth}]
	}
    }

    set data($col-isSnipped) 0
    if {$pixels == 0} {				;# convention: dynamic width
	#
	# Set the label text
	#
	if {$imageWidth == 0} {				;# no image
	    if {[string length $title] == 0} {
		set text $spaces
	    } else {
		set lines {}
		foreach line [split $title "\n"] {
		    if {[string compare $alignment "right"] == 0} {
			lappend lines $spaces$line
		    } else {
			lappend lines $line$spaces
		    }
		}
		set text [join $lines "\n"]
	    }
	    $w configure -text $text
	} elseif {[string length $title] == 0} {	;# image w/o text
	    $w configure -text ""
	    set text $spaces
	    $w-tl configure -text $text
	    $w-il configure -width $imageWidth
	} else {					;# both image and text
	    $w configure -text ""
	    set lines {}
	    foreach line [split $title "\n"] {
		if {[string compare $alignment "right"] == 0} {
		    lappend lines "$spaces$line "
		} else {
		    lappend lines " $line$spaces"
		}
	    }
	    set text [join $lines "\n"]
	    $w-tl configure -text $text
	    $w-il configure -width $imageWidth
	}
    } else {
	#
	# Clip each line of title according to pixels and alignment
	#
	set lessPixels [expr {$pixels - $spacePixels}]
	variable snipSides
	set snipSide $snipSides($alignment,$data($col-changetitlesnipside))
	if {$imageWidth == 0} {				;# no image
	    if {[string length $title] == 0} {
		set text $spaces
	    } else {
		set lines {}
		foreach line [split $title "\n"] {
		    set lineSav $line
		    set line [strRange $win $line $labelFont \
			      $lessPixels $snipSide $data(-snipstring)]
		    if {[string compare $line $lineSav] != 0} {
			set data($col-isSnipped) 1
		    }
		    if {[string compare $alignment "right"] == 0} {
			lappend lines $spaces$line
		    } else {
			lappend lines $line$spaces
		    }
		}
		set text [join $lines "\n"]
	    }
	    $w configure -text $text
	} elseif {[string length $title] == 0} {	;# image w/o text
	    $w configure -text ""
	    if {$imageWidth + $spacePixels <= $pixels} {
		set text $spaces
		$w-tl configure -text $text
		$w-il configure -width $imageWidth
	    } elseif {$spacePixels < $pixels} {
		set text $spaces
		$w-tl configure -text $text
		$w-il configure -width [expr {$pixels - $spacePixels}]
	    } else {
		set imageWidth 0			;# can't disp. the image
		set text ""
	    }
	} else {					;# both image and text
	    $w configure -text ""
	    set gap [font measure $labelFont -displayof $win " "]
	    if {$imageWidth + $gap + $spacePixels <= $pixels} {
		incr lessPixels -[expr {$imageWidth + $gap}]
		set lines {}
		foreach line [split $title "\n"] {
		    set lineSav $line
		    set line [strRange $win $line $labelFont \
			      $lessPixels $snipSide $data(-snipstring)]
		    if {[string compare $line $lineSav] != 0} {
			set data($col-isSnipped) 1
		    }
		    if {[string compare $alignment "right"] == 0} {
			lappend lines "$spaces$line "
		    } else {
			lappend lines " $line$spaces"
		    }
		}
		set text [join $lines "\n"]
		$w-tl configure -text $text
		$w-il configure -width $imageWidth
	    } elseif {$imageWidth + $spacePixels <= $pixels} {	
		set data($col-isSnipped) 1
		set text $spaces		;# can't display the orig. text
		$w-tl configure -text $text
		$w-il configure -width $imageWidth
	    } elseif {$spacePixels < $pixels} {
		set data($col-isSnipped) 1
		set text $spaces		;# can't display the orig. text
		$w-tl configure -text $text
		$w-il configure -width [expr {$pixels - $spacePixels}]
	    } else {
		set data($col-isSnipped) 1
		set imageWidth 0		;# can't display the image
		set text ""			;# can't display the text
	    }
	}
    }

    #
    # Place the label's sublabels (if any)
    #
    if {$imageWidth == 0} {
	if {[info exists data($col-labelimage)]} {
	    place forget $w-il
	    place forget $w-tl
	}
    } else {
	if {[string length $text] == 0} {
	    place forget $w-tl
	}

	variable usingTile
	switch $alignment {
	    left {
		place $w-il -in $w -anchor w -bordermode outside \
			    -relx 0.0 -x $marginL -rely 0.49
		raise $w-il
		if {$usingTile} {
		    set padding [$w cget -padding]
		    lset padding 0 [incr padL [winfo reqwidth $w-il]]
		    $w configure -padding $padding -text $text
		} elseif {[string length $text] != 0} {
		    set textX [expr {$marginL + [winfo reqwidth $w-il]}]
		    place $w-tl -in $w -anchor w -bordermode outside \
				-relx 0.0 -x $textX -rely 0.49
		}
	    }

	    right {
		place $w-il -in $w -anchor e -bordermode outside \
			    -relx 1.0 -x -$marginR -rely 0.49
		raise $w-il
		if {$usingTile} {
		    set padding [$w cget -padding]
		    lset padding 2 [incr padR [winfo reqwidth $w-il]]
		    $w configure -padding $padding -text $text
		} elseif {[string length $text] != 0} {
		    set textX [expr {-$marginR - [winfo reqwidth $w-il]}]
		    place $w-tl -in $w -anchor e -bordermode outside \
				-relx 1.0 -x $textX -rely 0.49
		}
	    }

	    center {
		if {$usingTile} {
		    set padding [$w cget -padding]
		    lset padding 0 [incr padL [winfo reqwidth $w-il]]
		    $w configure -padding $padding -text $text
		}

		if {[string length $text] == 0} {
		    place $w-il -in $w -anchor center -relx 0.5 -x 0 -rely 0.49
		} else {
		    set reqWidth [expr {[winfo reqwidth $w-il] +
					[winfo reqwidth $w-tl]}]
		    set iX [expr {-$reqWidth/2}]
		    place $w-il -in $w -anchor w -relx 0.5 -x $iX -rely 0.49
		    if {!$usingTile} {
			set tX [expr {$reqWidth + $iX}]
			place $w-tl -in $w -anchor e -relx 0.5 -x $tX -rely 0.49
		    }
		}
		raise $w-il
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::computeColWidth
#
# Computes the width of the col'th column of the tablelist widget win to be just
# large enough to hold all the elements of the column (including its label).
#------------------------------------------------------------------------------
proc tablelist::computeColWidth {win col} {
    upvar ::tablelist::ns${win}::data data
    set fmtCmdFlag [lindex $data(fmtCmdFlagList) $col]
    set data($col-elemWidth) 0
    set data($col-widestCount) 0

    #
    # Column elements
    #
    set row -1
    foreach item $data(itemList) {
	incr row

	if {$col >= [llength $item] - 1} {
	    continue
	}

	set key [lindex $item end]
	if {[info exists data($key-elide)] || [info exists data($key-hide)]} {
	    continue
	}

	set text [lindex $item $col]
	if {$fmtCmdFlag} {
	    set text [formatElem $win $key $row $col $text]
	}
	if {[string match "*\t*" $text]} {
	    set text [mapTabs $text]
	}
	getAuxData $win $key $col auxType auxWidth
	getIndentData $win $key $col indentWidth
	set cellFont [getCellFont $win $key $col]
	set elemWidth [getElemWidth $win $text $auxWidth $indentWidth $cellFont]
	if {$elemWidth == $data($col-elemWidth)} {
	    incr data($col-widestCount)
	} elseif {$elemWidth > $data($col-elemWidth)} {
	    set data($col-elemWidth) $elemWidth
	    set data($col-widestCount) 1
	}
    }
    set data($col-reqPixels) $data($col-elemWidth)

    #
    # Column label
    #
    computeLabelWidth $win $col
}

#------------------------------------------------------------------------------
# tablelist::computeLabelWidth
#
# Computes the width of the col'th label of the tablelist widget win and
# adjusts the column's width accordingly.
#------------------------------------------------------------------------------
proc tablelist::computeLabelWidth {win col} {
    upvar ::tablelist::ns${win}::data data
    set w $data(hdrTxtFrmLbl)$col
    if {[info exists data($col-labelimage)]} {
	variable usingTile
	if {$usingTile} {
	    set netLabelWidth [expr {[winfo reqwidth $w] - 2*$data(charWidth)}]
	} else {
	    set netLabelWidth \
		[expr {[winfo reqwidth $w-il] + [winfo reqwidth $w-tl]}]
	}
    } else {
	set netLabelWidth [expr {[winfo reqwidth $w] - 2*$data(charWidth)}]
    }

    if {$netLabelWidth < $data($col-elemWidth)} {
	set data($col-reqPixels) $data($col-elemWidth)
    } else {
	set data($col-reqPixels) $netLabelWidth
    }
}

#------------------------------------------------------------------------------
# tablelist::adjustHeaderHeight
#
# Sets the height of the header frame of the tablelist widget win to the max.
# height of its children.
#------------------------------------------------------------------------------
proc tablelist::adjustHeaderHeight win {
    #
    # Compute the max. label height
    #
    upvar ::tablelist::ns${win}::data data
    set maxLabelHeight [winfo reqheight $data(hdrFrmLbl)]
    for {set col 0} {$col < $data(colCount)} {incr col} {
	set w $data(hdrTxtFrmLbl)$col
	if {[string length [winfo manager $w]] == 0} {
	    continue
	}

	set reqHeight [winfo reqheight $w]
	if {$reqHeight > $maxLabelHeight} {
	    set maxLabelHeight $reqHeight
	}

	foreach l [getSublabels $w] {
	    if {[string length [winfo manager $l]] == 0} {
		continue
	    }

	    set borderWidth [winfo pixels $w [$w cget -borderwidth]]
	    if {$borderWidth < 0} {
		set borderWidth 0
	    }
	    set reqHeight [expr {[winfo reqheight $l] + 2*$borderWidth}]
	    if {$reqHeight > $maxLabelHeight} {
		set maxLabelHeight $reqHeight
	    }
	}
    }

    #
    # Set the height of the header frame and adjust the separators
    #
    $data(hdrTxtFrm) configure -height $maxLabelHeight
    if {$data(-showlabels)} {
	$data(hdr) configure -height $maxLabelHeight
	place configure $data(hdrTxt) -y 0
	place configure $data(hdrFrm) -y 0

	$data(corner) configure -height $maxLabelHeight
	place configure $data(cornerLbl) -y 0
    } else {
	$data(hdr) configure -height 1
	place configure $data(hdrTxt) -y -1
	place configure $data(hdrFrm) -y -1

	$data(corner) configure -height 1
	place configure $data(cornerLbl) -y -1
    }
    adjustSepsWhenIdle $win
}

#------------------------------------------------------------------------------
# tablelist::stretchColumnsWhenIdle
#
# Arranges for the stretchable columns of the tablelist widget win to be
# stretched at idle time.
#------------------------------------------------------------------------------
proc tablelist::stretchColumnsWhenIdle win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(stretchId)]} {
	return ""
    }

    set data(stretchId) [after idle [list tablelist::stretchColumns $win -1]]
}

#------------------------------------------------------------------------------
# tablelist::stretchColumns
#
# Stretches the stretchable columns to fill the tablelist window win
# horizontally.  The colOfFixedDelta argument specifies the column for which
# the stretching is to be made using a precomputed amount of pixels.
#------------------------------------------------------------------------------
proc tablelist::stretchColumns {win colOfFixedDelta} {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(stretchId)]} {
	after cancel $data(stretchId)
	unset data(stretchId)
    }

    set forceAdjust $data(forceAdjust)
    set data(forceAdjust) 0

    if {$data(hdrPixels) == 0 || $data(-width) <= 0} {
	return ""
    }

    #
    # Get the list data(stretchableCols) of the
    # numerical indices of the stretchable columns
    #
    set data(stretchableCols) {}
    if {[string compare $data(-stretch) "all"] == 0} {
	for {set col 0} {$col < $data(colCount)} {incr col} {
	    lappend data(stretchableCols) $col
	}
    } else {
	foreach col $data(-stretch) {
	    lappend data(stretchableCols) [colIndex $win $col 0]
	}
    }

    #
    # Compute the total number data(delta) of pixels by which the
    # columns are to be stretched and the total amount
    # data(stretchablePixels) of stretchable column widths in pixels
    #
    set data(delta) [winfo width $data(hdr)]
    set data(stretchablePixels) 0
    set lastColToStretch -1
    set col 0
    foreach {pixels alignment} $data(colList) {
	if {$data($col-hide)} {
	    incr col
	    continue
	}

	if {$pixels == 0} {			;# convention: dynamic width
	    set pixels $data($col-reqPixels)
	    if {$data($col-maxPixels) > 0} {
		if {$pixels > $data($col-maxPixels)} {
		    set pixels $data($col-maxPixels)
		}
	    }
	}
	incr data(delta) -[expr {$pixels + 2*$data(charWidth)}]
	if {[lsearch -exact $data(stretchableCols) $col] >= 0} {
	    incr data(stretchablePixels) $pixels
	    set lastColToStretch $col
	}

	incr col
    }
    if {$data(delta) < 0} {
	set delta 0
    } else {
	set delta $data(delta)
    }
    if {$data(stretchablePixels) == 0 && !$forceAdjust} {
	return ""
    }

    #
    # Distribute the value of delta to the stretchable
    # columns, proportionally to their widths in pixels
    #
    set rest $delta
    set col 0
    foreach {pixels alignment} $data(colList) {
	if {$data($col-hide) ||
	    [lsearch -exact $data(stretchableCols) $col] < 0} {
	    set data($col-delta) 0
	} else {
	    set oldDelta $data($col-delta)
	    if {$pixels == 0} {			;# convention: dynamic width
		set dynamic 1
		set pixels $data($col-reqPixels)
		if {$data($col-maxPixels) > 0} {
		    if {$pixels > $data($col-maxPixels)} {
			set pixels $data($col-maxPixels)
			set dynamic 0
		    }
		}
	    } else {
		set dynamic 0
	    }
	    if {$data(stretchablePixels) == 0} {
		set data($col-delta) 0
	    } else {
		if {$col != $colOfFixedDelta} {
		    set data($col-delta) \
			[expr {$delta*$pixels/$data(stretchablePixels)}]
		}
		incr rest -$data($col-delta)
	    }
	    if {$col == $lastColToStretch} {
		incr data($col-delta) $rest
	    }
	    if {!$dynamic && $data($col-delta) != $oldDelta} {
		redisplayColWhenIdle $win $col
	    }
	}

	incr col
    }

    #
    # Adjust the columns and schedule a view update for execution at idle time
    #
    adjustColumns $win {} 0
    updateViewWhenIdle $win 1
}

#------------------------------------------------------------------------------
# tablelist::moveActiveTag
#
# Moves the "active" tag to the line or cell that displays the active item or
# element of the tablelist widget win in its body text child.
#------------------------------------------------------------------------------
proc tablelist::moveActiveTag win {
    upvar ::tablelist::ns${win}::data data
    set w $data(body)
    $w tag remove curRow 1.0 end
    $w tag remove active 1.0 end

    if {$data(itemCount) == 0 || $data(colCount) == 0} {
	return ""
    }

    set activeLine [expr {$data(activeRow) + 1}]
    set activeCol $data(activeCol)
    if {[string compare $data(-selecttype) "row"] == 0} {
	$w tag add active $activeLine.0 $activeLine.end
	updateColors $win $activeLine.0 $activeLine.end
    } elseif {$activeLine > 0 && $activeCol < $data(colCount) &&
	      !$data($activeCol-hide)} {
	$w tag add curRow $activeLine.0 $activeLine.end
	findTabs $win $activeLine $activeCol $activeCol tabIdx1 tabIdx2
	$w tag add active $tabIdx1 $tabIdx2+1c
	updateColors $win $activeLine.0 $activeLine.end
    }
}

#------------------------------------------------------------------------------
# tablelist::updateColorsWhenIdle
#
# Arranges for the background and foreground colors of the label, frame, and
# message widgets containing the currently visible images, embedded windows,
# and multiline elements of the tablelist widget win to be updated at idle
# time.
#------------------------------------------------------------------------------
proc tablelist::updateColorsWhenIdle win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(colorsId)]} {
	return ""
    }

    set data(colorsId) [after idle [list tablelist::updateColors $win]]
}

#------------------------------------------------------------------------------
# tablelist::updateColors
#
# Updates the background and foreground colors of the label, frame, and message
# widgets containing the currently visible images, embedded windows, and
# multiline elements of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::updateColors {win {fromTextIdx ""} {toTextIdx ""}} {
    upvar ::tablelist::ns${win}::data data
    if {[string length $fromTextIdx] == 0} {
	set updateAll 1

	if {[info exists data(colorsId)]} {
	    after cancel $data(colorsId)
	    unset data(colorsId)
	}
    } else {
	set updateAll 0
    }

    if {$data(itemCount) == 0 || [info exists data(dispId)]} {
	return ""
    }

    set leftCol [colIndex $win @0,0 0 0]
    if {$leftCol < 0} {
	return ""
    }

    set w $data(body)
    if {$updateAll} {
	set topTextIdx [$w index @0,0]
	set btmTextIdx [$w index @0,$data(btmY)]
	set fromTextIdx "$topTextIdx linestart"
	set toTextIdx   "$btmTextIdx lineend"

	if {$data(isDisabled)} {
	    $w tag add disabled $fromTextIdx $toTextIdx
	}

	if {[string length $data(-colorizecommand)] == 0} {
	    set hasColorizeCmd 0
	} else {
	    set hasColorizeCmd 1
	    set colorizeCmd $data(-colorizecommand)
	}

	variable canElide
	variable elide
	set rightCol [colIndex $win @$data(rightX),0 0 0]
	set topLine [expr {int($topTextIdx)}]
	set btmLine [expr {int($btmTextIdx)}]
	if {$btmLine > $data(itemCount)} {		;# text widget bug
	    set btmLine $data(itemCount)
	}
	for {set line $topLine; set row [expr {$line - 1}]} \
	    {$line <= $btmLine} {set row $line; incr line} {
	    set key [lindex $data(keyList) $row]
	    if {[info exists data($key-elide)] ||
		[info exists data($key-hide)]} {
		continue
	    }

	    #
	    # Handle the -stripebackground and -stripeforeground
	    # column configuration options, as well as the
	    # -(select)background and -(select)foreground column,
	    # row, and cell configuration options in this row
	    #
	    findTabs $win $line $leftCol $leftCol tabIdx1 tabIdx2
	    set lineTagNames [$w tag names $tabIdx1]
	    set inStripe [expr {[lsearch -exact $lineTagNames stripe] >= 0}]
	    for {set col $leftCol} {$col <= $rightCol} {incr col} {
		if {$data($col-hide) && !$canElide} {
		    continue
		}

		set textIdx2 [$w index $tabIdx2+1c]

		set cellTagNames [$w tag names $tabIdx2]
		foreach tag $cellTagNames {
		    if {[string match "*-*ground-*" $tag]} {
			$w tag remove $tag $tabIdx1 $textIdx2
		    }
		}

		if {$inStripe} {
		    foreach opt {-stripebackground -stripeforeground} {
			set name $col$opt
			if {[info exists data($name)]} {
			    $w tag add col$opt-$data($name) $tabIdx1 $textIdx2
			}
		    }
		}

		set selected [expr {[lsearch -exact $cellTagNames select] >= 0}]
		foreach optTail {background foreground} {
		    set normalOpt -$optTail
		    set selectOpt -select$optTail
		    foreach level      [list col row cell] \
			    normalName [list $col$normalOpt $key$normalOpt \
					$key,$col$normalOpt] \
			    selectName [list $col$selectOpt $key$selectOpt \
					$key,$col$selectOpt] {
			if {$selected} {
			    if {[info exists data($selectName)]} {
				$w tag add $level$selectOpt-$data($selectName) \
				       $tabIdx1 $textIdx2
			    }
			} else {
			    if {[info exists data($normalName)]} {
				$w tag add $level$normalOpt-$data($normalName) \
				       $tabIdx1 $textIdx2
			    }
			}
		    }
		}

		if {$hasColorizeCmd} {
		    uplevel #0 $colorizeCmd [list $win $w $key $row $col \
			$tabIdx1 $tabIdx2 $inStripe $selected]
		}

		set tabIdx1 $textIdx2
		set tabIdx2 [$w search $elide "\t" $tabIdx1+1c $line.end]
	    }
	}
    }

    set hasExpCollCtrlSelImgs [expr {$::tk_version >= 8.3 &&
	[info exists tablelist::$data(-treestyle)_collapsedSelImg]}]

    foreach {dummy path textIdx} [$w dump -window $fromTextIdx $toTextIdx] {
	if {[string length $path] == 0} {
	    continue
	}

	set class [winfo class $path]
	set isLabel [expr {[string compare $class "Label"] == 0}]
	set isTblWin [expr {[string compare $class "TablelistWindow"] == 0}]
	set isMessage [expr {[string compare $class "Message"] == 0}]
	if {!$isLabel && !$isTblWin && !$isMessage} {
	    continue
	}

	set name [winfo name $path]
	foreach {key col} [split [string range $name 4 end] ","] {}
	if {[info exists data($key-elide)] || [info exists data($key-hide)]} {
	    continue
	}

	set tagNames [$w tag names $textIdx]
	set selected [expr {[lsearch -exact $tagNames select] >= 0}]

	#
	# If the widget is an indentation label then conditionally remove the
	# "active" and "select" tags from its text position and the preceding
	# one, or change its image to become the "normal" or "selected" one
	#
	if {[string compare $path $w.ind_$key,$col] == 0} {
	    if {$data(protectIndents)} {
		set fromTextIdx [$w index $textIdx-1c]
		set toTextIdx   [$w index $textIdx+1c]

		$w tag remove curRow $fromTextIdx $toTextIdx
		$w tag remove active $fromTextIdx $toTextIdx

		if {$updateAll && $selected} {
		    $w tag remove select $fromTextIdx $toTextIdx
		    foreach tag [$w tag names $fromTextIdx] {
			if {[string match "*-selectbackground-*" $tag] ||
			    [string match "*-selectforeground-*" $tag]} {
			    $w tag remove $tag $fromTextIdx $toTextIdx
			}
		    }
		    set selected 0
		    foreach optTail {background foreground} {
			set opt -$optTail
			foreach level [list col row cell] \
				name  [list $col$opt $key$opt $key,$col$opt] {
			    if {[info exists data($name)]} {
				$w tag add $level$opt-$data($name) \
				       $fromTextIdx $toTextIdx
			    }
			}
		    }
		}
	    } elseif {$hasExpCollCtrlSelImgs} {
		set curImgName [$path cget -image]
		if {$selected} {
		    set newImgName [strMap {
			"SelActImg" "SelActImg" "ActImg" "SelActImg"
			"SelImg" "SelImg" "collapsedImg" "collapsedSelImg"
			"expandedImg" "expandedSelImg"
		    } $curImgName]
		} else {
		    set newImgName [strMap {"Sel" ""} $curImgName]
		}

		if {[string compare $curImgName $newImgName] != 0} {
		    set data($key,$col-indent) $newImgName
		    $path configure -image $data($key,$col-indent)
		}
	    }
	}

	if {!$updateAll} {
	    continue
	}

	#
	# Set the widget's background and foreground
	# colors to those of the containing cell
	#
	if {$data(isDisabled)} {
	    set bg $data(-background)
	    set fg $data(-disabledforeground)
	} elseif {$selected} {
	    if {[info exists data($key,$col-selectbackground)]} {
		set bg $data($key,$col-selectbackground)
	    } elseif {[info exists data($key-selectbackground)]} {
		set bg $data($key-selectbackground)
	    } elseif {[info exists data($col-selectbackground)]} {
		set bg $data($col-selectbackground)
	    } else {
		set bg $data(-selectbackground)
	    }

	    if {$isMessage || $isTblWin} {
		if {[info exists data($key,$col-selectforeground)]} {
		    set fg $data($key,$col-selectforeground)
		} elseif {[info exists data($key-selectforeground)]} {
		    set fg $data($key-selectforeground)
		} elseif {[info exists data($col-selectforeground)]} {
		    set fg $data($col-selectforeground)
		} else {
		    set fg $data(-selectforeground)
		}
	    }
	} else {
	    if {[info exists data($key,$col-background)]} {
		set bg $data($key,$col-background)
	    } elseif {[info exists data($key-background)]} {
		set bg $data($key-background)
	    } elseif {[lsearch -exact $tagNames stripe] >= 0} {
		if {[info exists data($col-stripebackground)]} {
		    set bg $data($col-stripebackground)
		} elseif {[string length $data(-stripebackground)] != 0} {
		    set bg $data(-stripebackground)
		} else {
		    set bg $data(-background)
		}
	    } else {
		if {[info exists data($col-background)]} {
		    set bg $data($col-background)
		} else {
		    set bg $data(-background)
		}
	    }

	    if {$isMessage || $isTblWin} {
		if {[info exists data($key,$col-foreground)]} {
		    set fg $data($key,$col-foreground)
		} elseif {[info exists data($key-foreground)]} {
		    set fg $data($key-foreground)
		} elseif {[lsearch -exact $tagNames stripe] >= 0} {
		    if {[info exists data($col-stripeforeground)]} {
			set fg $data($col-stripeforeground)
		    } elseif {[string length $data(-stripeforeground)] != 0} {
			set fg $data(-stripeforeground)
		    } else {
			set fg $data(-foreground)
		    }
		} else {
		    if {[info exists data($col-foreground)]} {
			set fg $data($col-foreground)
		    } else {
			set fg $data(-foreground)
		    }
		}
	    }
	}
	if {[string compare [$path cget -background] $bg] != 0} {
	    $path configure -background $bg
	}
	if {$isMessage && [string compare [$path cget -foreground] $fg] != 0} {
	    $path configure -foreground $fg
	}
	if {$isTblWin && [info exists data($key,$col-windowupdate)]} {
	    uplevel #0 $data($key,$col-windowupdate) [list \
		$win [keyToRow $win $key] $col $path.w \
		-background $bg -foreground $fg]
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::updateScrlColOffsetWhenIdle
#
# Arranges for the scrolled column offset of the tablelist widget win to be
# updated at idle time.
#------------------------------------------------------------------------------
proc tablelist::updateScrlColOffsetWhenIdle win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(offsetId)]} {
	return ""
    }

    set data(offsetId) [after idle [list tablelist::updateScrlColOffset $win]]
}

#------------------------------------------------------------------------------
# tablelist::updateScrlColOffset
#
# Updates the scrolled column offset of the tablelist widget win to fit into
# the allowed range.
#------------------------------------------------------------------------------
proc tablelist::updateScrlColOffset win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(offsetId)]} {
	after cancel $data(offsetId)
	unset data(offsetId)
    }

    set maxScrlColOffset [getMaxScrlColOffset $win]
    if {$data(scrlColOffset) > $maxScrlColOffset} {
	set data(scrlColOffset) $maxScrlColOffset
	adjustElidedText $win
	redisplayVisibleItems $win
    }
}

#------------------------------------------------------------------------------
# tablelist::updateHScrlbarWhenIdle
#
# Arranges for the horizontal scrollbar associated with the tablelist widget
# win to be updated at idle time.
#------------------------------------------------------------------------------
proc tablelist::updateHScrlbarWhenIdle win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(hScrlbarId)]} {
	return ""
    }

    set data(hScrlbarId) [after idle [list tablelist::updateHScrlbar $win]]
}

#------------------------------------------------------------------------------
# tablelist::updateHScrlbar
#
# Updates the horizontal scrollbar associated with the tablelist widget win by
# invoking the command specified as the value of the -xscrollcommand option.
#------------------------------------------------------------------------------
proc tablelist::updateHScrlbar win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(hScrlbarId)]} {
	after cancel $data(hScrlbarId)
	unset data(hScrlbarId)
    }

    if {$data(-titlecolumns) > 0 &&
	[string length $data(-xscrollcommand)] != 0} {
	eval $data(-xscrollcommand) [xviewSubCmd $win {}]
    }
}

#------------------------------------------------------------------------------
# tablelist::updateVScrlbarWhenIdle
#
# Arranges for the vertical scrollbar associated with the tablelist widget win
# to be updated at idle time.
#------------------------------------------------------------------------------
proc tablelist::updateVScrlbarWhenIdle win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(vScrlbarId)]} {
	return ""
    }

    set data(vScrlbarId) [after idle [list tablelist::updateVScrlbar $win]]
}

#------------------------------------------------------------------------------
# tablelist::updateVScrlbar
#
# Updates the vertical scrollbar associated with the tablelist widget win by
# invoking the command specified as the value of the -yscrollcommand option.
#------------------------------------------------------------------------------
proc tablelist::updateVScrlbar win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(vScrlbarId)]} {
	after cancel $data(vScrlbarId)
	unset data(vScrlbarId)
    }

    if {[string length $data(-yscrollcommand)] != 0} {
	eval $data(-yscrollcommand) [yviewSubCmd $win {}]
    }

    if {[winfo viewable $win] && ![info exists data(colBeingResized)] &&
	![info exists data(redrawId)]} {
	set data(redrawId) [after 50 [list tablelist::forceRedraw $win]]
    }

    if {$data(gotResizeEvent)} {
	set data(gotResizeEvent) 0
    } else {
	purgeWidgets $win
    }

    event generate $win <<TablelistViewUpdated>>
}

#------------------------------------------------------------------------------
# tablelist::forceRedraw
#
# Enforces a redraw of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::forceRedraw win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(redrawId)]} {
	after cancel $data(redrawId)
	unset data(redrawId)
    }

    set w $data(body)
    set fromTextIdx "[$w index @0,0] linestart"
    set toTextIdx "[$w index @0,$data(btmY)] lineend"
    $w tag add redraw $fromTextIdx $toTextIdx
    $w tag remove redraw $fromTextIdx $toTextIdx

    variable winSys
    if {[string compare $winSys "aqua"] == 0} {
	#
	# Work around some Tk bugs on Mac OS X Aqua
	#
	raise $w
	lower $w
	if {[winfo exists $data(bodyFrm)]} {
	    lower $data(bodyFrm)
	    raise $data(bodyFrm)
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::purgeWidgets
#
# Destroys those label widgets containing embedded images and those message
# widgets containing multiline elements that are outside the currently visible
# range of lines of the body of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::purgeWidgets win {
    upvar ::tablelist::ns${win}::data data
    set w $data(body)
    set fromTextIdx "[$w index @0,0] linestart"
    set toTextIdx "[$w index @0,$data(btmY)] lineend"

    foreach {dummy path textIdx} [$w dump -window 1.0 end] {
	if {[string length $path] == 0} {
	    continue
	}

	set class [winfo class $path]
	if {([string compare $class "Label"] == 0 ||
	     [string compare $class "Message"] == 0) &&
	    ([$w compare $textIdx < $fromTextIdx] ||
	     [$w compare $textIdx > $toTextIdx])} {
	    $w tag add elidedWin $textIdx
	    destroy $path
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::adjustElidedText
#
# Updates the elided text ranges of the body text child of the tablelist widget
# win.
#------------------------------------------------------------------------------
proc tablelist::adjustElidedText win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(dispId)]} {
	return ""
    }

    #
    # Remove the "hiddenCol" tag
    #
    set w $data(body)
    $w tag remove hiddenCol 1.0 end

    #
    # Add the "hiddenCol" tag to the contents of the hidden
    # columns from the top to the bottom window line
    #
    variable canElide
    variable elide
    if {$canElide && $data(hiddenColCount) > 0 && $data(itemCount) > 0} {
	set topLine [expr {int([$w index @0,0])}]
	set btmLine [expr {int([$w index @0,$data(btmY)])}]
	if {$btmLine > $data(itemCount)} {		;# text widget bug
	    set btmLine $data(itemCount)
	}
	for {set line $topLine; set row [expr {$line - 1}]} \
	    {$line <= $btmLine} {set row $line; incr line} {
	    set key [lindex $data(keyList) $row]
	    if {[info exists data($key-elide)] ||
		[info exists data($key-hide)]} {
		continue
	    }

	    set textIdx1 $line.0
	    for {set col 0; set count 0} \
		{$col < $data(colCount) && $count < $data(hiddenColCount)} \
		{incr col} {
		set textIdx2 \
		    [$w search $elide "\t" $textIdx1+1c $line.end]+1c
		if {[string compare $textIdx2 "+1c"] == 0} {
		    break
		}
		if {$data($col-hide)} {
		    incr count
		    $w tag add hiddenCol $textIdx1 $textIdx2
		}
		set textIdx1 $textIdx2
	    }

	    #
	    # Update btmLine because it may
	    # change due to the "hiddenCol" tag
	    #
	    set btmLine [expr {int([$w index @0,$data(btmY)])}]
	    if {$btmLine > $data(itemCount)} {		;# text widget bug
		set btmLine $data(itemCount)
	    }
	}

	if {[lindex [$w yview] 1] == 1} {
	    for {set line $btmLine; set row [expr {$line - 1}]} \
		{$line >= $topLine} {set line $row; incr row -1} {
		set key [lindex $data(keyList) $row]
		if {[info exists data($key-elide)] ||
		    [info exists data($key-hide)]} {
		    continue
		}

		set textIdx1 $line.0
		for {set col 0; set count 0} \
		    {$col < $data(colCount) && $count < $data(hiddenColCount)} \
		    {incr col} {
		    set textIdx2 \
			[$w search $elide "\t" $textIdx1+1c $line.end]+1c
		    if {[string compare $textIdx2 "+1c"] == 0} {
			break
		    }
		    if {$data($col-hide)} {
			incr count
			$w tag add hiddenCol $textIdx1 $textIdx2
		    }
		    set textIdx1 $textIdx2
		}

		#
		# Update topLine because it may
		# change due to the "hiddenCol" tag
		#
		set topLine [expr {int([$w index @0,0])}]
	    }
	}
    }

    if {$data(-titlecolumns) == 0} {
	return ""
    }

    #
    # Remove the "elidedCol" tag
    #
    $w tag remove elidedCol 1.0 end
    for {set col 0} {$col < $data(colCount)} {incr col} {
	set data($col-elide) 0
    }

    if {$data(scrlColOffset) == 0} {
	adjustColumns $win {} 0
	return ""
    }

    #
    # Find max. $data(scrlColOffset) non-hidden columns with indices >=
    # $data(-titlecolumns) and retain the first and last of these indices
    #
    set firstCol $data(-titlecolumns)
    while {$firstCol < $data(colCount) && $data($firstCol-hide)} {
	incr firstCol
    }
    if {$firstCol >= $data(colCount)} {
	return ""
    }
    set lastCol $firstCol
    set nonHiddenCount 1
    while {$nonHiddenCount < $data(scrlColOffset) &&
	   $lastCol < $data(colCount)} {
	incr lastCol
	if {!$data($lastCol-hide)} {
	    incr nonHiddenCount
	}
    }

    #
    # Add the "elidedCol" tag to the contents of these
    # columns from the top to the bottom window line
    #
    if {$data(itemCount) > 0} {
	set topLine [expr {int([$w index @0,0])}]
	set btmLine [expr {int([$w index @0,$data(btmY)])}]
	if {$btmLine > $data(itemCount)} {		;# text widget bug
	    set btmLine $data(itemCount)
	}
	for {set line $topLine; set row [expr {$line - 1}]} \
	    {$line <= $btmLine} {set row $line; incr line} {
	    set key [lindex $data(keyList) $row]
	    if {![info exists data($key-elide)] &&
		![info exists data($key-hide)]} {
		if {[findTabs $win $line $firstCol $lastCol tabIdx1 tabIdx2]} {
		    $w tag add elidedCol $tabIdx1 $tabIdx2+1c
		}
	    }

	    #
	    # Update btmLine because it may change due to the "elidedCol" tag
	    #
	    set btmLine [expr {int([$w index @0,$data(btmY)])}]
	    if {$btmLine > $data(itemCount)} {		;# text widget bug
		set btmLine $data(itemCount)
	    }
	}

	if {[lindex [$w yview] 1] == 1} {
	    for {set line $btmLine; set row [expr {$line - 1}]} \
		{$line >= $topLine} {set line $row; incr row -1} {
		set key [lindex $data(keyList) $row]
		if {![info exists data($key-elide)] &&
		    ![info exists data($key-hide)]} {
		    if {[findTabs $win $line $firstCol $lastCol \
			 tabIdx1 tabIdx2]} {
			$w tag add elidedCol $tabIdx1 $tabIdx2+1c
		    }
		}

		#
		# Update topLine because it may
		# change due to the "elidedCol" tag
		#
		set topLine [expr {int([$w index @0,0])}]
	    }
	}
    }

    #
    # Adjust the columns
    #
    for {set col $firstCol} {$col <= $lastCol} {incr col} {
	set data($col-elide) 1
    }
    adjustColumns $win {} 0
}

#------------------------------------------------------------------------------
# tablelist::redisplayWhenIdle
#
# Arranges for the items of the tablelist widget win to be redisplayed at idle
# time.
#------------------------------------------------------------------------------
proc tablelist::redisplayWhenIdle win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(redispId)] || $data(itemCount) == 0} {
	return ""
    }

    set data(redispId) [after idle [list tablelist::redisplay $win]]

    #
    # Cancel the execution of all delayed redisplayCol commands
    #
    foreach name [array names data *-redispId] {
	after cancel $data($name)
	unset data($name)
    }
}

#------------------------------------------------------------------------------
# tablelist::redisplay
#
# Redisplays the items of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::redisplay {win {getSelCells 1} {selCells {}}} {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(redispId)]} {
	after cancel $data(redispId)
	unset data(redispId)
    }

    #
    # Save the indices of the selected cells
    #
    if {$getSelCells} {
	set selCells [curCellSelection $win]
    }

    #
    # Save some data of the edit window if present
    #
    if {[set editCol $data(editCol)] >= 0} {
	set editRow $data(editRow)
	saveEditData $win
    }

    set w $data(body)
    set snipStr $data(-snipstring)
    set rowTagRefCount $data(rowTagRefCount)
    set cellTagRefCount $data(cellTagRefCount)
    set isSimple [expr {$data(imgCount) == 0 && $data(winCount) == 0 &&
			$data(indentCount) == 0}]
    set padY [expr {[$w cget -spacing1] == 0}]
    variable canElide
    variable snipSides
    set newItemList {}
    set row 0
    set line 1
    foreach item $data(itemList) {
	#
	# Empty the line, clip the elements if necessary,
	# and insert them with the corresponding tags
	#
	$w delete $line.0 $line.end
	set keyIdx [expr {[llength $item] - 1}]
	set key [lindex $item end]
	if {$rowTagRefCount == 0} {
	    set hasRowFont 0
	} else {
	    set hasRowFont [info exists data($key-font)]
	}
	set newItem {}
	set col 0
	if {$isSimple} {
	    set insertArgs {}
	    set multilineData {}
	    foreach fmtCmdFlag $data(fmtCmdFlagList) \
		    colFont $data(colFontList) \
		    colTags $data(colTagsList) \
		    {pixels alignment} $data(colList) {
		if {$col < $keyIdx} {
		    set text [lindex $item $col]
		} else {
		    set text ""
		}
		lappend newItem $text

		if {$data($col-hide) && !$canElide} {
		    incr col
		    continue
		}

		if {$fmtCmdFlag} {
		    set text [formatElem $win $key $row $col $text]
		}
		if {[string match "*\t*" $text]} {
		    set text [mapTabs $text]
		}

		#
		# Build the list of tags to be applied to the cell
		#
		if {$hasRowFont} {
		    set cellFont $data($key-font)
		} else {
		    set cellFont $colFont
		}
		set cellTags $colTags
		if {$cellTagRefCount != 0} {
		    if {[info exists data($key,$col-font)]} {
			set cellFont $data($key,$col-font)
			lappend cellTags cell-font-$data($key,$col-font)
		    }
		}

		#
		# Clip the element if necessary
		#
		set multiline [string match "*\n*" $text]
		if {$pixels == 0} {		;# convention: dynamic width
		    if {$data($col-maxPixels) > 0} {
			if {$data($col-reqPixels) > $data($col-maxPixels)} {
			    set pixels $data($col-maxPixels)
			}
		    }
		}
		if {$pixels != 0} {
		    incr pixels $data($col-delta)

		    if {$data($col-wrap) && !$multiline} {
			if {[font measure $cellFont -displayof $win $text] >
			    $pixels} {
			    set multiline 1
			}
		    }

		    set snipSide \
			$snipSides($alignment,$data($col-changesnipside))
		    if {$multiline} {
			set list [split $text "\n"]
			if {$data($col-wrap)} {
			    set snipSide ""
			}
			set text [joinList $win $list $cellFont \
				  $pixels $snipSide $snipStr]
		    } elseif {$data(-displayondemand)} {
			set text ""
		    } else {
			set text [strRange $win $text $cellFont \
				  $pixels $snipSide $snipStr]
		    }
		}

		if {$multiline} {
		    lappend insertArgs "\t\t" $cellTags
		    lappend multilineData $col $text $cellFont $pixels \
					  $alignment
		} else {
		    lappend insertArgs "\t$text\t" $cellTags
		}

		incr col
	    }

	    #
	    # Insert the item into the body text widget
	    #
	    if {[llength $insertArgs] != 0} {
		eval [list $w insert $line.0] $insertArgs
	    }

	    #
	    # Embed the message widgets displaying multiline elements
	    #
	    foreach {col text font pixels alignment} $multilineData {
		if {[findTabs $win $line $col $col tabIdx1 tabIdx2]} {
		    set msgScript [list ::tablelist::displayText $win $key \
				   $col $text $font $pixels $alignment]
		    $w window create $tabIdx2 \
			      -align top -pady $padY -create $msgScript
		    $w tag add elidedWin $tabIdx2
		}
	    }

	} else {
	    foreach fmtCmdFlag $data(fmtCmdFlagList) \
		    colFont $data(colFontList) \
		    colTags $data(colTagsList) \
		    {pixels alignment} $data(colList) {
		if {$col < $keyIdx} {
		    set text [lindex $item $col]
		} else {
		    set text ""
		}
		lappend newItem $text

		if {$data($col-hide) && !$canElide} {
		    incr col
		    continue
		}

		if {$fmtCmdFlag} {
		    set text [formatElem $win $key $row $col $text]
		}
		if {[string match "*\t*" $text]} {
		    set text [mapTabs $text]
		}

		#
		# Build the list of tags to be applied to the cell
		#
		if {$hasRowFont} {
		    set cellFont $data($key-font)
		} else {
		    set cellFont $colFont
		}
		set cellTags $colTags
		if {$cellTagRefCount != 0} {
		    if {[info exists data($key,$col-font)]} {
			set cellFont $data($key,$col-font)
			lappend cellTags cell-font-$data($key,$col-font)
		    }
		}

		#
		# Insert the text and the label or window
		# (if any) into the body text widget
		#
		appendComplexElem $win $key $row $col $text $pixels \
				  $alignment $snipStr $cellFont $cellTags $line

		incr col
	    }
	}

	if {$rowTagRefCount != 0} {
	    if {[info exists data($key-font)]} {
		$w tag add row-font-$data($key-font) $line.0 $line.end
	    }
	}

	if {[info exists data($key-elide)]} {
	    $w tag add elidedRow $line.0 $line.end+1c
	}
	if {[info exists data($key-hide)]} {
	    $w tag add hiddenRow $line.0 $line.end+1c
	}

	lappend newItem $key
	lappend newItemList $newItem

	set row $line
	incr line
    }

    set data(itemList) $newItemList

    #
    # Select the cells that were selected before
    #
    foreach cellIdx $selCells {
	scan $cellIdx "%d,%d" row col
	if {$col < $data(colCount)} {
	    cellSelection $win set $row $col $row $col
	}
    }

    #
    # Conditionally move the "active" tag to the active line or cell
    #
    if {$data(ownsFocus)} {
	moveActiveTag $win
    }

    #
    # Adjust the elided text and restore the stripes in the body text widget
    #
    adjustElidedText $win
    redisplayVisibleItems $win
    makeStripes $win

    #
    # Restore the edit window if it was present before
    #
    if {$editCol >= 0} {
	doEditCell $win $editRow $editCol 1
    }
}

#------------------------------------------------------------------------------
# tablelist::redisplayVisibleItems
#
# Redisplays the visible items of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::redisplayVisibleItems win {
    upvar ::tablelist::ns${win}::data data
    if {!$data(-displayondemand) || $data(itemCount) == 0} {
	return ""
    }

    set leftCol [colIndex $win @0,0 0 0]
    if {$leftCol < 0} {
	return ""
    }

    variable canElide
    variable elide
    variable snipSides

    displayItems $win
    set w $data(body)

    set topTextIdx [$w index @0,0]
    set btmTextIdx [$w index @0,$data(btmY)]
    set fromTextIdx "$topTextIdx linestart"
    set toTextIdx   "$btmTextIdx lineend"
    $w tag remove elidedWin $fromTextIdx $toTextIdx

    set rightCol [colIndex $win @$data(rightX),0 0 0]
    set topLine [expr {int($topTextIdx)}]
    set btmLine [expr {int($btmTextIdx)}]
    if {$btmLine > $data(itemCount)} {			;# text widget bug
	set btmLine $data(itemCount)
    }
    set snipStr $data(-snipstring)

    for {set line $topLine; set row [expr {$line - 1}]} \
	{$line <= $btmLine} {set row $line; incr line} {
	set item [lindex $data(itemList) $row]
	set key [lindex $item end]
	if {[info exists data($key-elide)] || [info exists data($key-hide)]} {
	    continue
	}

	#
	# Format the item
	#
	set dispItem [lrange $item 0 $data(lastCol)]
	if {$data(hasFmtCmds)} {
	    set dispItem [formatItem $win $key $row $dispItem]
	}
	if {[string match "*\t*" $dispItem]} {
	    set dispItem [mapTabs $dispItem]
	}

	findTabs $win $line $leftCol $leftCol tabIdx1 tabIdx2
	set textIdx1 [$w index $tabIdx1+1c]
	for {set col $leftCol} {$col <= $rightCol} {incr col} {
	    if {$data($col-hide) && !$canElide} {
		continue
	    }

	    #
	    # Nothing to do if the text is empty or is already displayed,
	    # or interactive editing for this cell is in progress
	    #
	    set text [lindex $dispItem $col]
	    if {[string length $text] == 0 ||
		[string length [$w get $textIdx1 $tabIdx2]] != 0 ||
		($row == $data(editRow) && $col == $data(editCol))} {
		set textIdx1 [$w index $tabIdx2+2c]
		set tabIdx2 [$w search $elide "\t" $textIdx1 $line.end]
		continue
	    }

	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    if {$pixels == 0} {			;# convention: dynamic width
		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set pixels $data($col-maxPixels)
		    }
		}
	    }
	    if {$pixels != 0} {
		incr pixels $data($col-delta)
	    }

	    #
	    # Nothing to do if the cell has an (indentation)
	    # image or window, or contains multiline text
	    #
	    set aux [getAuxData $win $key $col auxType auxWidth $pixels]
	    set indent [getIndentData $win $key $col indentWidth]
	    set multiline [string match "*\n*" $text]
	    if {$auxWidth != 0 || $indentWidth != 0 || $multiline} {
		set textIdx1 [$w index $tabIdx2+2c]
		set tabIdx2 [$w search $elide "\t" $textIdx1 $line.end]
		continue
	    }

	    #
	    # Adjust the cell text
	    #
	    set maxTextWidth $pixels
	    if {[info exists data($key,$col-font)]} {
		set cellFont $data($key,$col-font)
	    } elseif {[info exists data($key-font)]} {
		set cellFont $data($key-font)
	    } else {
		set cellFont [lindex $data(colFontList) $col]
	    }
	    if {$pixels != 0} {
		set maxTextWidth \
		    [getMaxTextWidth $pixels $auxWidth $indentWidth]

		if {$data($col-wrap) && !$multiline} {
		    if {[font measure $cellFont -displayof $win $text] >
			$maxTextWidth} {
			#
			# The element is displayed as multiline text
			#
			set textIdx1 [$w index $tabIdx2+2c]
			set tabIdx2 [$w search $elide "\t" $textIdx1 $line.end]
			continue
		    }
		}
	    }
	    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
	    set snipSide $snipSides($alignment,$data($col-changesnipside))
	    adjustElem $win text auxWidth indentWidth $cellFont $pixels \
		       $snipSide $snipStr

	    #
	    # Update the text widget's contents between the two tabs
	    #
	    $w mark set tabMark2 [$w index $tabIdx2]
	    updateCell $w $textIdx1 $tabIdx2 $text $aux $auxType $auxWidth \
		       $indent $indentWidth $alignment ""

	    set textIdx1 [$w index tabMark2+2c]
	    set tabIdx2 [$w search $elide "\t" $textIdx1 $line.end]
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::redisplayColWhenIdle
#
# Arranges for the elements of the col'th column of the tablelist widget win to
# be redisplayed at idle time.
#------------------------------------------------------------------------------
proc tablelist::redisplayColWhenIdle {win col} {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data($col-redispId)] || [info exists data(redispId)] ||
	$data(itemCount) == 0} {
	return ""
    }

    set data($col-redispId) \
	[after idle [list tablelist::redisplayCol $win $col 0 last]]
}

#------------------------------------------------------------------------------
# tablelist::redisplayCol
#
# Redisplays the elements of the col'th column of the tablelist widget win, in
# the range specified by first and last.
#------------------------------------------------------------------------------
proc tablelist::redisplayCol {win col first last} {
    upvar ::tablelist::ns${win}::data data
    set allRows [expr {$first == 0 && [string compare $last "last"] == 0}]
    if {$allRows && [info exists data($col-redispId)]} {
	after cancel $data($col-redispId)
	unset data($col-redispId)
    }

    if {$data(itemCount) == 0 || $first < 0 ||
	$col > $data(lastCol) || $data($col-hide)} {
	return ""
    }
    if {[string compare $last "last"] == 0} {
	set last $data(lastRow)
    }

    displayItems $win
    set fmtCmdFlag [lindex $data(fmtCmdFlagList) $col]
    set colFont [lindex $data(colFontList) $col]
    set snipStr $data(-snipstring)

    set w $data(body)
    set pixels [lindex $data(colList) [expr {2*$col}]]
    if {$pixels == 0} {				;# convention: dynamic width
	if {$data($col-maxPixels) > 0} {
	    if {$data($col-reqPixels) > $data($col-maxPixels)} {
		set pixels $data($col-maxPixels)
	    }
	}
    }
    if {$pixels != 0} {
	incr pixels $data($col-delta)
    }
    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
    variable snipSides
    set snipSide $snipSides($alignment,$data($col-changesnipside))

    for {set row $first; set line [expr {$first + 1}]} {$row <= $last} \
	{set row $line; incr line} {
	if {$row == $data(editRow) && $col == $data(editCol)} {
	    continue
	}

	set item [lindex $data(itemList) $row]
	set key [lindex $item end]
	if {!$allRows &&
	    ([info exists data($key-elide)] ||
	     [info exists data($key-hide)])} {
	    continue
	}

	#
	# Adjust the cell text and the image or window width
	#
	set text [lindex $item $col]
	if {$fmtCmdFlag} {
	    set text [formatElem $win $key $row $col $text]
	}
	if {[string match "*\t*" $text]} {
	    set text [mapTabs $text]
	}
	set multiline [string match "*\n*" $text]
	set aux [getAuxData $win $key $col auxType auxWidth $pixels]
	set indent [getIndentData $win $key $col indentWidth]
	set maxTextWidth $pixels
	if {[info exists data($key,$col-font)]} {
	    set cellFont $data($key,$col-font)
	} elseif {[info exists data($key-font)]} {
	    set cellFont $data($key-font)
	} else {
	    set cellFont $colFont
	}
	if {$pixels != 0} {
	    set maxTextWidth [getMaxTextWidth $pixels $auxWidth $indentWidth]

	    if {$data($col-wrap) && !$multiline} {
		if {[font measure $cellFont -displayof $win $text] >
		    $maxTextWidth} {
		    set multiline 1
		}
	    }
	}
	if {$multiline} {
	    set list [split $text "\n"]
	    set snipSide2 $snipSide
	    if {$data($col-wrap)} {
		set snipSide2 ""
	    }
	    adjustMlElem $win list auxWidth indentWidth $cellFont \
			 $pixels $snipSide2 $snipStr
	    set msgScript [list ::tablelist::displayText $win $key $col \
			   [join $list "\n"] $cellFont $maxTextWidth $alignment]
	} else {
	    adjustElem $win text auxWidth indentWidth $cellFont \
		       $pixels $snipSide $snipStr
	}

	#
	# Update the text widget's contents between the two tabs
	#
	if {[findTabs $win $line $col $col tabIdx1 tabIdx2]} {
	    if {$auxType > 1 && $auxWidth > 0 && ![winfo exists $aux]} {
		#
		# Create a frame and evaluate the script that
		# creates a child window within the frame
		#
		tk::frame $aux -borderwidth 0 -class TablelistWindow \
			       -container 0 -height $data($key,$col-reqHeight) \
			       -highlightthickness 0 -relief flat \
			       -takefocus 0 -width $auxWidth
		catch {$aux configure -padx 0 -pady 0}
		bindtags $aux [linsert [bindtags $aux] 1 \
			       $data(bodyTag) TablelistBody]
		uplevel #0 $data($key,$col-window) [list $win $row $col $aux.w]
	    }

	    if {$multiline} {
		updateMlCell $w $tabIdx1+1c $tabIdx2 $msgScript $aux $auxType \
			     $auxWidth $indent $indentWidth $alignment \
			     [getVAlignment $win $key $col]
	    } else {
		updateCell $w $tabIdx1+1c $tabIdx2 $text $aux $auxType \
			   $auxWidth $indent $indentWidth $alignment \
			   [getVAlignment $win $key $col]
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::makeStripesWhenIdle
#
# Arranges for the stripes in the body of the tablelist widget win to be
# redrawn at idle time.
#------------------------------------------------------------------------------
proc tablelist::makeStripesWhenIdle win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(stripesId)] || $data(itemCount) == 0} {
	return ""
    }

    set data(stripesId) [after idle [list tablelist::makeStripes $win]]
}

#------------------------------------------------------------------------------
# tablelist::makeStripes
#
# Redraws the stripes in the body of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::makeStripes win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(stripesId)]} {
	after cancel $data(stripesId)
	unset data(stripesId)
    }

    if {[info exists data(dispId)]} {
	return ""
    }

    set w $data(body)
    $w tag remove stripe 1.0 end
    if {[string length $data(-stripebackground)] != 0 ||
	[string length $data(-stripeforeground)] != 0} {
	set count 0
	set inStripe 0
	for {set row 0; set line 1} {$row < $data(itemCount)} \
	    {set row $line; incr line} {
	    set key [lindex $data(keyList) $row]
	    if {![info exists data($key-elide)] &&
		![info exists data($key-hide)]} {
		if {$inStripe} {
		    $w tag add stripe $line.0 $line.end
		}

		if {[incr count] == $data(-stripeheight)} {
		    set count 0
		    set inStripe [expr {!$inStripe}]
		}
	    }
	}
    }

    updateColors $win
}

#------------------------------------------------------------------------------
# tablelist::showLineNumbersWhenIdle
#
# Arranges for the line numbers in the tablelist widget win to be redisplayed
# at idle time.
#------------------------------------------------------------------------------
proc tablelist::showLineNumbersWhenIdle win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(lineNumsId)] || $data(itemCount) == 0} {
	return ""
    }

    set data(lineNumsId) [after idle [list tablelist::showLineNumbers $win]]
}

#------------------------------------------------------------------------------
# tablelist::showLineNumbers
#
# Redisplays the line numbers (if any) in the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::showLineNumbers win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(lineNumsId)]} {
	after cancel $data(lineNumsId)
	unset data(lineNumsId)
    }

    #
    # Update the item list
    #
    set colIdxList {}
    for {set col 0} {$col < $data(colCount)} {incr col} {
	if {!$data($col-showlinenumbers)} {
	    continue
	}

	lappend colIdxList $col

	set newItemList {}
	set line 1
	foreach item $data(itemList) {
	    set item [lreplace $item $col $col $line]
	    lappend newItemList $item
	    set key [lindex $item end]
	    if {![info exists data($key-hide)]} {
		incr line
	    }
	}
	set data(itemList) $newItemList

	redisplayColWhenIdle $win $col
    }

    if {[llength $colIdxList] == 0} {
	return ""
    }

    #
    # Update the list variable if present, and adjust the columns
    #
    condUpdateListVar $win
    adjustColumns $win $colIdxList 1
    return ""
}

#------------------------------------------------------------------------------
# tablelist::updateViewWhenIdle
#
# Arranges for the visible part of the tablelist widget win to be updated
# at idle time.
#------------------------------------------------------------------------------
proc tablelist::updateViewWhenIdle {win {reschedule 0}} {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(viewId)]} {
	if {$reschedule} {
	    after cancel $data(viewId)
	} else {
	    return ""
	}
    }

    set data(viewId) [after idle [list tablelist::updateView $win]]
}

#------------------------------------------------------------------------------
# tablelist::updateView
#
# Updates the visible part of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::updateView win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(viewId)]} {
	after cancel $data(viewId)
	unset data(viewId)
    }

    adjustElidedText $win
    redisplayVisibleItems $win
    updateColors $win
    adjustSeps $win
    updateVScrlbar $win
}

#------------------------------------------------------------------------------
# tablelist::destroyWidgets
#
# Destroys a list of widgets embedded into the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::destroyWidgets win {
    upvar ::tablelist::ns${win}::data data
    set destroyId [lindex $data(destroyIdList) 0]

    eval destroy $data(widgets-$destroyId)

    set data(destroyIdList) [lrange $data(destroyIdList) 1 end]
    unset data(widgets-$destroyId)
}

#------------------------------------------------------------------------------
# tablelist::synchronize
#
# This procedure is invoked either as an idle callback after the list variable
# associated with the tablelist widget win was written, or directly, upon
# execution of some widget commands.  It makes sure that the content of the
# widget is synchronized with the value of the list variable.
#------------------------------------------------------------------------------
proc tablelist::synchronize win {
    #
    # Nothing to do if the list variable was not written
    #
    upvar ::tablelist::ns${win}::data data
    if {![info exists data(syncId)]} {
	return ""
    }

    #
    # Here we are in the case that the procedure was scheduled for
    # execution at idle time.  However, it might have been invoked
    # directly, before the idle time occured; in this case we should
    # cancel the execution of the previously scheduled idle callback.
    #
    after cancel $data(syncId)	;# no harm if data(syncId) is no longer valid
    unset data(syncId)

    upvar #0 $data(-listvariable) var
    set newCount [llength $var]
    if {$newCount < $data(itemCount)} {
	#
	# Delete the items with indices >= newCount from the widget
	#
	set updateCount $newCount
	deleteRows $win $newCount $data(lastRow) 0
    } elseif {$newCount > $data(itemCount)} {
	#
	# Insert the items of var with indices
	# >= data(itemCount) into the widget
	#
	set updateCount $data(itemCount)
	insertRows $win $data(itemCount) [lrange $var $data(itemCount) end] 0 \
		   root $data(itemCount)
    } else {
	set updateCount $newCount
    }

    #
    # Update the first updateCount items of the internal list
    #
    set itemsChanged 0
    for {set row 0} {$row < $updateCount} {incr row} {
	set oldItem [lindex $data(itemList) $row]
	set newItem [adjustItem [lindex $var $row] $data(colCount)]
	lappend newItem [lindex $oldItem end]

	if {[string compare $oldItem $newItem] != 0} {
	    set data(itemList) [lreplace $data(itemList) $row $row $newItem]
	    set itemsChanged 1
	}
    }

    #
    # If necessary, adjust the columns and make sure
    # that the items will be redisplayed at idle time
    #
    if {$itemsChanged} {
	adjustColumns $win allCols 1
	redisplayWhenIdle $win
	showLineNumbersWhenIdle $win
	updateViewWhenIdle $win
    }
}

#------------------------------------------------------------------------------
# tablelist::getSublabels
#
# Returns the list of the existing sublabels $w-il and $w-tl associated with
# the label widget w.
#------------------------------------------------------------------------------
proc tablelist::getSublabels w {
    set lst {}
    foreach lbl [list $w-il $w-tl] {
	if {[winfo exists $lbl]} {
	    lappend lst $lbl
	}
    }

    return $lst
}

#------------------------------------------------------------------------------
# tablelist::parseLabelPath
#
# Extracts the path name of the tablelist widget as well as the column number
# from the path name w of a header label.
#------------------------------------------------------------------------------
proc tablelist::parseLabelPath {w winName colName} {
    if {![winfo exists $w]} {
	return 0
    }

    upvar $winName win $colName col
    return [regexp {^(\..+)\.hdr\.t\.f\.l([0-9]+)$} $w dummy win col]
}

#------------------------------------------------------------------------------
# tablelist::configLabel
#
# This procedure configures the label widget w according to the options and
# their values given in args.  It is needed for label widgets with sublabels.
#------------------------------------------------------------------------------
proc tablelist::configLabel {w args} {
    foreach {opt val} $args {
	switch -- $opt {
	    -active {
		if {[string compare [winfo class $w] "TLabel"] == 0} {
		    $w instate !selected {
			set state [expr {$val ? "active" : "!active"}]
			$w state $state
			variable themeDefaults
			if {$val} {
			    set bg $themeDefaults(-labelactiveBg)
			} else {
			    set bg $themeDefaults(-labelbackground)
			}
			foreach l [getSublabels $w] {
			    $l configure -background $bg
			}
		    }
		} else {
		    set state [expr {$val ? "active" : "normal"}]
		    catch {
			$w configure -state $state
			foreach l [getSublabels $w] {
			    $l configure -state $state
			}
		    }
		}

		parseLabelPath $w win col
		upvar ::tablelist::ns${win}::data data
		if {[lsearch -exact $data(arrowColList) $col] >= 0} {
		    configCanvas $win $col
		}
	    }

	    -activebackground -
	    -activeforeground -
	    -disabledforeground -
	    -cursor {
		$w configure $opt $val
		foreach l [getSublabels $w] {
		    $l configure $opt $val
		}
	    }

	    -background -
	    -font {
		if {[string compare [winfo class $w] "TLabel"] == 0 &&
		    [string length $val] == 0} {
		    variable themeDefaults
		    set val $themeDefaults(-label[string range $opt 1 end])
		}
		$w configure $opt $val
		foreach l [getSublabels $w] {
		    $l configure $opt $val
		}
	    }

	    -foreground {
		if {[string compare [winfo class $w] "TLabel"] == 0} {
		    variable themeDefaults
		    if {[string compare [winfo rgb $w $val] [winfo rgb $w \
			 $themeDefaults(-labelforeground)]] == 0} {
			set val ""    ;# for automatic adaptation to the states
		    }
		    $w instate !disabled {
			$w configure $opt $val
		    }
		} else {
		    $w configure $opt $val
		    foreach l [getSublabels $w] {
			$l configure $opt $val
		    }
		}
	    }

	    -padx {
		if {[string compare [winfo class $w] "TLabel"] == 0} {
		    set padding [$w cget -padding]
		    lset padding 0 $val
		    lset padding 2 $val
		    $w configure -padding $padding
		} else {
		    $w configure $opt $val
		}
	    }

	    -pady {
		if {[string compare [winfo class $w] "TLabel"] == 0} {
		    set val [winfo pixels $w $val]
		    set padding [$w cget -padding]
		    lset padding 1 $val
		    lset padding 3 $val
		    $w configure -padding $padding
		} else {
		    $w configure $opt $val
		}
	    }

	    -pressed {
		if {[string compare [winfo class $w] "TLabel"] == 0} {
		    set state [expr {$val ? "pressed" : "!pressed"}]
		    $w state $state
		    variable themeDefaults
		    if {$val} {
			if {[$w instate selected]} {
			    set bg $themeDefaults(-labelselectedpressedBg)
			} else {
			    set bg $themeDefaults(-labelpressedBg)
			}
		    } else {
			if {[$w instate selected]} {
			    set bg $themeDefaults(-labelselectedBg)
			} elseif {[$w instate active]} {
			    set bg $themeDefaults(-labelactiveBg)
			} else {
			    set bg $themeDefaults(-labelbackground)
			}
		    }
		    foreach l [getSublabels $w] {
			$l configure -background $bg
		    }

		    parseLabelPath $w win col
		    upvar ::tablelist::ns${win}::data data
		    if {[lsearch -exact $data(arrowColList) $col] >= 0} {
			configCanvas $win $col
		    }
		}
	    }

	    -selected {
		if {[string compare [winfo class $w] "TLabel"] == 0} {
		    set state [expr {$val ? "selected" : "!selected"}]
		    $w state $state
		    variable themeDefaults
		    if {$val} {
			if {[$w instate pressed]} {
			    set bg $themeDefaults(-labelselectedpressedBg)
			} else {
			    set bg $themeDefaults(-labelselectedBg)
			}
		    } else {
			if {[$w instate pressed]} {
			    set bg $themeDefaults(-labelpressedBg)
			} else {
			    set bg $themeDefaults(-labelbackground)
			}
		    }
		    foreach l [getSublabels $w] {
			$l configure -background $bg
		    }

		    parseLabelPath $w win col
		    upvar ::tablelist::ns${win}::data data
		    if {[lsearch -exact $data(arrowColList) $col] >= 0} {
			configCanvas $win $col
		    }
		}
	    }

	    -state {
		$w configure $opt $val
		if {[string compare [winfo class $w] "TLabel"] == 0} {
		    variable themeDefaults
		    if {[string compare $val "disabled"] == 0} {
			#
			# Set the label's foreground color to the theme-
			# specific one (needed for current tile versions)
			#
			$w configure -foreground ""

			set bg $themeDefaults(-labeldisabledBg)
		    } else {
			#
			# Restore the label's foreground color
			# (needed for current tile versions)
			#
			if {[parseLabelPath $w win col]} {
			    upvar ::tablelist::ns${win}::data data
			    if {[info exists data($col-labelforeground)]} {
				set fg $data($col-labelforeground)
			    } else {
				set fg $data(-labelforeground)
			    }
			    configLabel $w -foreground $fg
			}

			set bg $themeDefaults(-labelbackground)
		    }
		    foreach l [getSublabels $w] {
			$l configure -background $bg
		    }
		} else {
		    foreach l [getSublabels $w] {
			$l configure $opt $val
		    }
		}
	    }

	    default {
		if {[string compare $val [$w cget $opt]] != 0} {
		    $w configure $opt $val
		}
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::createArrows
#
# Creates two arrows in the canvas w.
#------------------------------------------------------------------------------
proc tablelist::createArrows {w width height relief} {
    if {$height < 6} {
	set wHeight 6
	variable centerArrows
	set y [expr {$centerArrows ? 0 : 1}]
    } else {
	set wHeight $height
	set y 0
    }

    $w configure -width $width -height $wHeight

    #
    # Delete any existing arrow image items from
    # the canvas and the corresponding images
    #
    set imgNames [image names]
    foreach shape {triangleUp darkLineUp lightLineUp
		   triangleDn darkLineDn lightLineDn} {
	$w delete $shape
	if {[lsearch -exact $imgNames $shape$w] >= 0} {
	    image delete $shape$w
	}
    }

    #
    # Create the arrow images and canvas image items
    # corresponding to the procedure's arguments
    #
    $relief${width}x${height}Arrows $w
    set imgNames [image names]
    foreach shape {triangleUp darkLineUp lightLineUp
		   triangleDn darkLineDn lightLineDn} {
	if {[lsearch -exact $imgNames $shape$w] >= 0} {
	    $w create image 0 $y -anchor nw -image $shape$w -tags $shape
	}
    }

    #
    # Create the sort rank image item
    #
    $w delete sortRank
    set x [expr {$width + 2}]
    set y [expr {$wHeight - 6}]
    $w create image $x $y -anchor nw -tags sortRank
}

#------------------------------------------------------------------------------
# tablelist::configCanvas
#
# Sets the background color of the canvas displaying an up- or down-arrow for
# the given column, and fills the two arrows contained in the canvas.
#------------------------------------------------------------------------------
proc tablelist::configCanvas {win col} {
    upvar ::tablelist::ns${win}::data data
    set w $data(hdrTxtFrmLbl)$col

    if {[string compare [winfo class $w] "TLabel"] == 0} {
	variable themeDefaults
	set labelBg $themeDefaults(-labelbackground)
	set fg [$w cget -foreground]
	set labelFg $fg
	if {[string length $fg] == 0} {
	    set labelFg $themeDefaults(-labelforeground)
	}

	if {[$w instate disabled]} {
	    set labelBg $themeDefaults(-labeldisabledBg)
	    set labelFg $themeDefaults(-labeldisabledFg)
	} elseif {[$win instate background]} {
	    set labelBg $themeDefaults(-labeldeactivatedBg)
	} else {
	    foreach state {active pressed selected} {
		$w instate $state {
		    set labelBg $themeDefaults(-label${state}Bg)
		    if {[string length $fg] == 0} {
			set labelFg $themeDefaults(-label${state}Fg)
		    }
		}
	    }
	    $w instate {selected pressed} {
		set labelBg $themeDefaults(-labelselectedpressedBg)
		if {[string length $fg] == 0} {
		    set labelFg $themeDefaults(-labelselectedpressedFg)
		}
	    }
	}
    } else {
	set labelBg [$w cget -background]
	set labelFg [$w cget -foreground]

	catch {
	    set state [$w cget -state]
	    if {[string compare $state "disabled"] == 0} {
		set labelFg [$w cget -disabledforeground]
	    } elseif {[string compare $state "active"] == 0} {
		variable winSys
		if {!([string compare $winSys "classic"] == 0 ||
		      [string compare $winSys "aqua"] == 0) ||
		    $::tk_version > 8.4} {
		    set labelBg [$w cget -activebackground]
		    set labelFg [$w cget -activeforeground]
		}
	    }
	}
    }

    set canvas $data(hdrTxtFrmCanv)$col
    $canvas configure -background $labelBg
    sortRank$data($col-sortRank)$win configure -foreground $labelFg

    if {$data(isDisabled)} {
	fillArrows $canvas $data(-arrowdisabledcolor) $data(-arrowstyle)
    } else {
	fillArrows $canvas $data(-arrowcolor) $data(-arrowstyle)
    }
}

#------------------------------------------------------------------------------
# tablelist::fillArrows
#
# Fills the two arrows contained in the canvas w with the given color, or with
# the background color of the canvas if color is an empty string.  Also fills
# the arrow's borders (if any) with the corresponding 3-D shadow colors.
#------------------------------------------------------------------------------
proc tablelist::fillArrows {w color arrowStyle} {
    set bgColor [$w cget -background]
    if {[string length $color] == 0} {
	set color $bgColor
    }

    getShadows $w $color darkColor lightColor

    foreach dir {Up Dn} {
	if {[string compare [image type triangle$dir$w] "bitmap"] == 0} {
	    triangle$dir$w configure -foreground $color -background $bgColor
	}

	if {[string match "sunken*" $arrowStyle]} {
	    darkLine$dir$w  configure -foreground $darkColor
	    lightLine$dir$w configure -foreground $lightColor
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::getShadows
#
# Computes the shadow colors for a 3-D border from a given (background) color.
# This is the Tcl-counterpart of the function TkpGetShadows() in the Tk
# distribution file unix/tkUnix3d.c.
#------------------------------------------------------------------------------
proc tablelist::getShadows {w color darkColorName lightColorName} {
    upvar $darkColorName darkColor $lightColorName lightColor

    set rgb [winfo rgb $w $color]
    foreach {r g b} $rgb {}
    set maxIntens [lindex [winfo rgb $w white] 0]

    #
    # Compute the dark shadow color
    #
    if {[string compare $::tk_patchLevel "8.3.1"] >= 0 &&
	$r*0.5*$r + $g*1.0*$g + $b*0.28*$b < $maxIntens*0.05*$maxIntens} {
	#
	# The background is already very dark: make the dark
	# color a little lighter than the background by increasing
	# each color component 1/4th of the way to $maxIntens
	#
	foreach comp $rgb {
	    lappend darkRGB [expr {($maxIntens + 3*$comp)/4}]
	}
    } else {
	#
	# Compute the dark color by cutting 40% from
	# each of the background color components.
	#
	foreach comp $rgb {
	    lappend darkRGB [expr {60*$comp/100}]
	}
    }
    set darkColor [eval format "#%04x%04x%04x" $darkRGB]

    #
    # Compute the light shadow color
    #
    if {[string compare $::tk_patchLevel "8.3.1"] >= 0 &&
	$g > $maxIntens*0.95} {
	#
	# The background is already very bright: make the
	# light color a little darker than the background
	# by reducing each color component by 10%
	#
	foreach comp $rgb {
	    lappend lightRGB [expr {90*$comp/100}]
	}
    } else {
	#
	# Compute the light color by boosting each background
	# color component by 40% or half-way to white, whichever
	# is greater (the first approach works better for
	# unsaturated colors, the second for saturated ones)
	#
	foreach comp $rgb {
	    set comp1 [expr {140*$comp/100}]
	    if {$comp1 > $maxIntens} {
		set comp1 $maxIntens
	    }
	    set comp2 [expr {($maxIntens + $comp)/2}]
	    lappend lightRGB [expr {($comp1 > $comp2) ? $comp1 : $comp2}]
	}
    }
    set lightColor [eval format "#%04x%04x%04x" $lightRGB]
}

#------------------------------------------------------------------------------
# tablelist::raiseArrow
#
# Raises one of the two arrows contained in the canvas associated with the
# given column of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::raiseArrow {win col} {
    upvar ::tablelist::ns${win}::data data
    set w $data(hdrTxtFrmCanv)$col
    variable directions
    set dir $directions($data(-incrarrowtype),$data($col-sortOrder))

    if {[string match "photo*" $data(-arrowstyle)]} {
	$w itemconfigure triangle$dir -state normal
	set dir [expr {([string compare $dir "Up"] == 0) ? "Dn" : "Up"}]
	$w itemconfigure triangle$dir -state hidden
    } else {
	$w raise triangle$dir
	$w raise darkLine$dir
	$w raise lightLine$dir
    }
}

#------------------------------------------------------------------------------
# tablelist::isHdrTxtFrXPosVisible
#
# Checks whether the given x position in the header text child of the tablelist
# widget win is visible.
#------------------------------------------------------------------------------
proc tablelist::isHdrTxtFrXPosVisible {win x} {
    upvar ::tablelist::ns${win}::data data
    foreach {fraction1 fraction2} [$data(hdrTxt) xview] {}
    return [expr {$x >= $fraction1 * $data(hdrPixels) &&
		  $x <  $fraction2 * $data(hdrPixels)}]
}

#------------------------------------------------------------------------------
# tablelist::getScrlContentWidth
#
# Returns the total width of the non-hidden scrollable columns of the tablelist
# widget win, in the specified range.
#------------------------------------------------------------------------------
proc tablelist::getScrlContentWidth {win scrlColOffset lastCol} {
    upvar ::tablelist::ns${win}::data data
    set scrlContentWidth 0
    set nonHiddenCount 0
    for {set col $data(-titlecolumns)} {$col <= $lastCol} {incr col} {
	if {!$data($col-hide) && [incr nonHiddenCount] > $scrlColOffset} {
	    incr scrlContentWidth [colWidth $win $col -total]
	}
    }

    return $scrlContentWidth
}

#------------------------------------------------------------------------------
# tablelist::getScrlWindowWidth
#
# Returns the number of pixels obtained by subtracting the widths of the non-
# hidden title columns from the width of the header frame of the tablelist
# widget win.
#------------------------------------------------------------------------------
proc tablelist::getScrlWindowWidth win {
    upvar ::tablelist::ns${win}::data data
    set scrlWindowWidth [winfo width $data(hdr)]
    for {set col 0} {$col < $data(-titlecolumns) && $col < $data(colCount)} \
	{incr col} {
	if {!$data($col-hide)} {
	    incr scrlWindowWidth -[colWidth $win $col -total]
	}
    }

    return $scrlWindowWidth
}

#------------------------------------------------------------------------------
# tablelist::getMaxScrlColOffset
#
# Returns the max. scrolled column offset of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::getMaxScrlColOffset win {
    #
    # Get the number of non-hidden scrollable columns
    #
    upvar ::tablelist::ns${win}::data data
    set maxScrlColOffset 0
    for {set col $data(-titlecolumns)} {$col < $data(colCount)} {incr col} {
	if {!$data($col-hide)} {
	    incr maxScrlColOffset
	}
    }

    #
    # Decrement maxScrlColOffset while the total width of the
    # non-hidden scrollable columns starting with this offset
    # is less than the width of the window's scrollable part
    #
    set scrlWindowWidth [getScrlWindowWidth $win]
    if {$scrlWindowWidth > 0} {
	while {$maxScrlColOffset > 0} {
	    incr maxScrlColOffset -1
	    set scrlContentWidth \
		[getScrlContentWidth $win $maxScrlColOffset $data(lastCol)]
	    if {$scrlContentWidth == $scrlWindowWidth} {
		break
	    } elseif {$scrlContentWidth > $scrlWindowWidth} {
		incr maxScrlColOffset
		break
	    }
	}
    }

    return $maxScrlColOffset
}

#------------------------------------------------------------------------------
# tablelist::changeScrlColOffset
#
# Changes the scrolled column offset of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::changeScrlColOffset {win scrlColOffset} {
    #
    # Make sure the offset is non-negative and no
    # greater than the max. scrolled column offset
    #
    if {$scrlColOffset < 0} {
	set scrlColOffset 0
    } else {
	set maxScrlColOffset [getMaxScrlColOffset $win]
	if {$scrlColOffset > $maxScrlColOffset} {
	    set scrlColOffset $maxScrlColOffset
	}
    }

    #
    # Update data(scrlColOffset) and adjust the
    # elided text in the tablelist's body if necessary
    #
    upvar ::tablelist::ns${win}::data data
    if {$scrlColOffset != $data(scrlColOffset)} {
	set data(scrlColOffset) $scrlColOffset
	adjustElidedText $win
	redisplayVisibleItems $win
    }
}

#------------------------------------------------------------------------------
# tablelist::scrlXOffsetToColOffset
#
# Returns the scrolled column offset of the tablelist widget win, corresponding
# to the desired x offset.
#------------------------------------------------------------------------------
proc tablelist::scrlXOffsetToColOffset {win scrlXOffset} {
    upvar ::tablelist::ns${win}::data data
    set scrlColOffset 0
    set scrlContentWidth 0
    for {set col $data(-titlecolumns)} {$col < $data(colCount)} {incr col} {
	if {$data($col-hide)} {
	    continue
	}

	incr scrlContentWidth [colWidth $win $col -total]
	if {$scrlContentWidth > $scrlXOffset} {
	    break
	} else {
	    incr scrlColOffset
	}
    }

    return $scrlColOffset
}

#------------------------------------------------------------------------------
# tablelist::scrlColOffsetToXOffset
#
# Returns the x offset corresponding to the specified scrolled column offset of
# the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::scrlColOffsetToXOffset {win scrlColOffset} {
    upvar ::tablelist::ns${win}::data data
    set scrlXOffset 0
    set nonHiddenCount 0
    for {set col $data(-titlecolumns)} {$col < $data(colCount)} {incr col} {
	if {$data($col-hide)} {
	    continue
	}

	if {[incr nonHiddenCount] > $scrlColOffset} {
	    break
	} else {
	    incr scrlXOffset [colWidth $win $col -total]
	}
    }

    return $scrlXOffset
}

#------------------------------------------------------------------------------
# tablelist::getVertComplTopRow
#
# Returns the row number of the topmost vertically complete item visible in the
# tablelist window win.
#------------------------------------------------------------------------------
proc tablelist::getVertComplTopRow win {
    upvar ::tablelist::ns${win}::data data
    set w $data(body)

    set topTextIdx [$w index @0,0]
    set topRow [expr {int($topTextIdx) - 1}]

    foreach {x y width height baselinePos} [$w dlineinfo $topTextIdx] {}
    if {$y < 0} {
	incr topRow		;# top row incomplete in vertical direction
    }

    return $topRow
}

#------------------------------------------------------------------------------
# tablelist::getVertComplBtmRow
#
# Returns the row number of the bottommost vertically complete item visible in
# the tablelist window win.
#------------------------------------------------------------------------------
proc tablelist::getVertComplBtmRow win {
    upvar ::tablelist::ns${win}::data data
    set w $data(body)

    set btmTextIdx [$w index @0,$data(btmY)]
    set btmRow [expr {int($btmTextIdx) - 1}]
    if {$btmRow > $data(lastRow)} {			;# text widget bug
	set btmRow $data(lastRow)
    }

    foreach {x y width height baselinePos} [$w dlineinfo $btmTextIdx] {}
    set y2 [expr {$y + $height}]
    if {[$w compare [$w index @0,$y] == [$w index @0,$y2]]} {
	incr btmRow -1		;# btm row incomplete in vertical direction
    }

    return $btmRow
}

#------------------------------------------------------------------------------
# tablelist::getViewableRowCount
#
# Returns the number of viewable rows of the tablelist widget win in the
# specified range.
#------------------------------------------------------------------------------
proc tablelist::getViewableRowCount {win first last} {
    upvar ::tablelist::ns${win}::data data
    if {$data(nonViewableRowCount) == 0} {
	#
	# Speed optimization
	#
	set count [expr {$last - $first + 1}]
	if {$count < 0} {
	    return 0
	} else {
	    return $count
	}
    } elseif {$first == 0 && $last == $data(lastRow)} {
	#
	# Speed optimization
	#
	return [expr {$data(itemCount) - $data(nonViewableRowCount)}]
    } else {
	set count 0
	for {set row $first} {$row <= $last} {incr row} {
	    set key [lindex $data(keyList) $row]
	    if {![info exists data($key-elide)] &&
		![info exists data($key-hide)]} {
		incr count
	    }
	}
	return $count
    }
}

#------------------------------------------------------------------------------
# tablelist::viewableRowOffsetToRowIndex
#
# Returns the row index corresponding to the given viewable row offset in the
# tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::viewableRowOffsetToRowIndex {win offset} {
    upvar ::tablelist::ns${win}::data data
    if {$data(nonViewableRowCount) == 0} {
	return $offset
    } else {
	#
	# Rebuild the list data(viewableRowList) of the row
	# indices indicating the viewable rows if needed
	#
	if {[lindex $data(viewableRowList) 0] == -1} {
	    set data(viewableRowList) {}
	    for {set row 0} {$row < $data(itemCount)} {incr row} {
		set key [lindex $data(keyList) $row]
		if {![info exists data($key-elide)] &&
		    ![info exists data($key-hide)]} {
		    lappend data(viewableRowList) $row
		}
	    }
	}

	if {$offset >= [llength $data(viewableRowList)]} {
	    return $data(itemCount)			;# this is out of range
	} else {
	    if {$offset < 0} {
		set offset 0
	    }
	    return [lindex $data(viewableRowList) $offset]
	}
    }
}
#==============================================================================
# Contains the implementation of the tablelist widget.
#
# Structure of the module:
#   - Namespace initialization
#   - Private procedure creating the default bindings
#   - Public procedure creating a new tablelist widget
#   - Private procedures implementing the tablelist widget command
#   - Private callback procedures
#
# Copyright (c) 2000-2017  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#
# Namespace initialization
# ========================
#

namespace eval tablelist {
    #
    # Get the current windowing system ("x11", "win32", "classic", or "aqua")
    #
    variable winSys
    if {[catch {tk windowingsystem} winSys] != 0} {
	switch $::tcl_platform(platform) {
	    unix	{ set winSys x11 }
	    windows	{ set winSys win32 }
	    macintosh	{ set winSys classic }
	}
    }

    #
    # Create aliases for a few tile commands if not yet present
    #
    proc createTileAliases {} {
	if {[string length [interp alias {} ::tablelist::style]] != 0} {
	    return ""
	}

	if {[llength [info commands ::ttk::style]] == 0} {
	    interp alias {} ::tablelist::style      {} ::style
	    if {[string compare $::tile::version "0.7"] >= 0} {
		interp alias {} ::tablelist::styleConfig {} ::style configure
	    } else {
		interp alias {} ::tablelist::styleConfig {} ::style default
	    }
	    interp alias {} ::tablelist::getThemes  {} ::tile::availableThemes
	    interp alias {} ::tablelist::setTheme   {} ::tile::setTheme

	    interp alias {} ::tablelist::tileqt_kdeStyleChangeNotification \
			 {} ::tile::theme::tileqt::kdeStyleChangeNotification
	    interp alias {} ::tablelist::tileqt_currentThemeName \
			 {} ::tile::theme::tileqt::currentThemeName
	    interp alias {} ::tablelist::tileqt_currentThemeColour \
			 {} ::tile::theme::tileqt::currentThemeColour
	} else {
	    interp alias {} ::tablelist::style	      {} ::ttk::style
	    interp alias {} ::tablelist::styleConfig  {} ::ttk::style configure
	    interp alias {} ::tablelist::getThemes    {} ::ttk::themes
	    interp alias {} ::tablelist::setTheme     {} ::ttk::setTheme

	    interp alias {} ::tablelist::tileqt_kdeStyleChangeNotification \
			 {} ::ttk::theme::tileqt::kdeStyleChangeNotification
	    interp alias {} ::tablelist::tileqt_currentThemeName \
			 {} ::ttk::theme::tileqt::currentThemeName
	    interp alias {} ::tablelist::tileqt_currentThemeColour \
			 {} ::ttk::theme::tileqt::currentThemeColour
	}
    }
    if {$usingTile} {
	createTileAliases 
    }

    variable pngSupported [expr {($::tk_version >= 8.6 &&
	![regexp {^8\.6(a[1-3]|b1)$} $::tk_patchLevel]) ||
	($::tk_version >= 8.5 && [catch {package require img::png}] == 0)}]

    variable specialAquaHandling [expr {$usingTile && ($::tk_version >= 8.6 ||
	[regexp {^8\.5\.(9|[1-9][0-9])$} $::tk_patchLevel]) &&
	[lsearch -exact [winfo server .] "AppKit"] >= 0}]

    #
    # The array configSpecs is used to handle configuration options.  The
    # names of its elements are the configuration options for the Tablelist
    # class.  The value of an array element is either an alias name or a list
    # containing the database name and class as well as an indicator specifying
    # the widget(s) to which the option applies: c stands for all children
    # (text widgets and labels), b for the body text widget, l for the labels,
    # f for the frame, and w for the widget itself.
    #
    #	Command-Line Name	 {Database Name		  Database Class      W}
    #	------------------------------------------------------------------------
    #
    variable configSpecs
    array set configSpecs {
	-acceptchildcommand	 {acceptChildCommand	  AcceptChildCommand  w}
	-acceptdropcommand	 {acceptDropCommand	  AcceptDropCommand   w}
	-activestyle		 {activeStyle		  ActiveStyle	      w}
	-arrowcolor		 {arrowColor		  ArrowColor	      w}
	-arrowdisabledcolor	 {arrowDisabledColor	  ArrowDisabledColor  w}
	-arrowstyle		 {arrowStyle		  ArrowStyle	      w}
	-autofinishediting	 {autoFinishEditing	  AutoFinishEditing   w}
	-autoscan		 {autoScan		  AutoScan	      w}
	-background		 {background		  Background	      b}
	-bg			 -background
	-borderwidth		 {borderWidth		  BorderWidth	      f}
	-bd			 -borderwidth
	-collapsecommand	 {collapseCommand	  CollapseCommand     w}
	-colorizecommand	 {colorizeCommand	  ColorizeCommand     w}
	-columns		 {columns		  Columns	      w}
	-columntitles		 {columnTitles		  ColumnTitles	      w}
	-cursor			 {cursor		  Cursor	      c}
	-customdragsource	 {customDragSource	  CustomDragSource    w}
	-disabledforeground	 {disabledForeground	  DisabledForeground  w}
	-displayondemand	 {displayOnDemand	  DisplayOnDemand     w}
	-editendcommand		 {editEndCommand	  EditEndCommand      w}
	-editselectedonly	 {editSelectedOnly	  EditSelectedOnly    w}
	-editstartcommand	 {editStartCommand	  EditStartCommand    w}
	-expandcommand		 {expandCommand		  ExpandCommand       w}
	-exportselection	 {exportSelection	  ExportSelection     w}
	-font			 {font			  Font		      b}
	-forceeditendcommand	 {forceEditEndCommand	  ForceEditEndCommand w}
	-foreground		 {foreground		  Foreground	      b}
	-fg			 -foreground
	-fullseparators		 {fullSeparators	  FullSeparators      w}
	-height			 {height		  Height	      w}
	-highlightbackground	 {highlightBackground	  HighlightBackground f}
	-highlightcolor		 {highlightColor	  HighlightColor      f}
	-highlightthickness	 {highlightThickness	  HighlightThickness  f}
	-incrarrowtype		 {incrArrowType		  IncrArrowType	      w}
	-instanttoggle		 {instantToggle		  InstantToggle	      w}
	-labelactivebackground	 {labelActiveBackground	  Foreground	      l}
	-labelactiveforeground	 {labelActiveForeground	  Background	      l}
	-labelbackground	 {labelBackground	  Background	      l}
	-labelbg		 -labelbackground
	-labelborderwidth	 {labelBorderWidth	  BorderWidth	      l}
	-labelbd		 -labelborderwidth
	-labelcommand		 {labelCommand		  LabelCommand	      w}
	-labelcommand2		 {labelCommand2		  LabelCommand2	      w}
	-labeldisabledforeground {labelDisabledForeground DisabledForeground  l}
	-labelfont		 {labelFont		  Font		      l}
	-labelforeground	 {labelForeground	  Foreground	      l}
	-labelfg		 -labelforeground
	-labelheight		 {labelHeight		  Height	      l}
	-labelpady		 {labelPadY		  Pad		      l}
	-labelrelief		 {labelRelief		  Relief	      l}
	-listvariable		 {listVariable		  Variable	      w}
	-movablecolumns	 	 {movableColumns	  MovableColumns      w}
	-movablerows		 {movableRows		  MovableRows	      w}
	-movecolumncursor	 {moveColumnCursor	  MoveColumnCursor    w}
	-movecursor		 {moveCursor		  MoveCursor	      w}
	-populatecommand	 {populateCommand	  PopulateCommand     w}
	-protecttitlecolumns	 {protectTitleColumns	  ProtectTitleColumns w}
	-relief			 {relief		  Relief	      f}
	-resizablecolumns	 {resizableColumns	  ResizableColumns    w}
	-resizecursor		 {resizeCursor		  ResizeCursor	      w}
	-selectbackground	 {selectBackground	  Foreground	      w}
	-selectborderwidth	 {selectBorderWidth	  BorderWidth	      w}
	-selectforeground	 {selectForeground	  Background	      w}
	-selectmode		 {selectMode		  SelectMode	      w}
	-selecttype		 {selectType		  SelectType	      w}
	-setfocus		 {setFocus		  SetFocus	      w}
	-setgrid		 {setGrid		  SetGrid	      w}
	-showarrow		 {showArrow		  ShowArrow	      w}
	-showeditcursor		 {showEditCursor	  ShowEditCursor      w}
	-showhorizseparator	 {showHorizSeparator	  ShowHorizSeparator  w}
	-showlabels		 {showLabels		  ShowLabels	      w}
	-showseparators		 {showSeparators	  ShowSeparators      w}
	-snipstring		 {snipString		  SnipString	      w}
	-sortcommand		 {sortCommand		  SortCommand	      w}
	-spacing		 {spacing		  Spacing	      w}
	-state			 {state			  State		      w}
	-stretch		 {stretch		  Stretch	      w}
	-stripebackground	 {stripeBackground	  Background	      w}
	-stripebg		 -stripebackground
	-stripeforeground	 {stripeForeground	  Foreground	      w}
	-stripefg		 -stripeforeground
	-stripeheight		 {stripeHeight		  StripeHeight	      w}
	-takefocus		 {takeFocus		  TakeFocus	      f}
	-targetcolor		 {targetColor		  TargetColor	      w}
	-tight			 {tight			  Tight		      w}
	-titlecolumns		 {titleColumns	  	  TitleColumns	      w}
	-tooltipaddcommand	 {tooltipAddCommand	  TooltipAddCommand   w}
	-tooltipdelcommand	 {tooltipDelCommand	  TooltipDelCommand   w}
	-treecolumn		 {treeColumn		  TreeColumn	      w}
	-treestyle		 {treeStyle		  TreeStyle	      w}
	-width			 {width			  Width		      w}
	-xscrollcommand		 {xScrollCommand	  ScrollCommand	      w}
	-yscrollcommand		 {yScrollCommand	  ScrollCommand	      w}
    }

    #
    # Extend the elements of the array configSpecs
    #
    extendConfigSpecs 

    variable configOpts [lsort [array names configSpecs]]

    #
    # The array colConfigSpecs is used to handle column configuration options.
    # The names of its elements are the column configuration options for the
    # Tablelist widget class.  The value of an array element is either an alias
    # name or a list containing the database name and class.
    #
    #	Command-Line Name	{Database Name		Database Class	    }
    #	---------------------------------------------------------------------
    #
    variable colConfigSpecs
    array set colConfigSpecs {
	-align			{align			Align		    }
	-background		{background		Background	    }
	-bg			-background
	-changesnipside		{changeSnipSide		ChangeSnipSide	    }
	-changetitlesnipside	{changeTitleSnipSide	ChangeTitleSnipSide }
	-editable		{editable		Editable	    }
	-editwindow		{editWindow		EditWindow	    }
	-font			{font			Font		    }
	-foreground		{foreground		Foreground	    }
	-fg			-foreground
	-formatcommand		{formatCommand		FormatCommand	    }
	-hide			{hide			Hide		    }
	-labelalign		{labelAlign		Align		    }
	-labelbackground	{labelBackground	Background	    }
	-labelbg		-labelbackground
	-labelborderwidth	{labelBorderWidth	BorderWidth	    }
	-labelbd		-labelborderwidth
	-labelcommand		{labelCommand		LabelCommand	    }
	-labelcommand2		{labelCommand2		LabelCommand2	    }
	-labelfont		{labelFont		Font		    }
	-labelforeground	{labelForeground	Foreground	    }
	-labelfg		-labelforeground
	-labelheight		{labelHeight		Height		    }
	-labelimage		{labelImage		Image		    }
	-labelpady		{labelPadY		Pad		    }
	-labelrelief		{labelRelief		Relief		    }
	-maxwidth		{maxWidth		MaxWidth	    }
	-name			{name			Name		    }
	-resizable		{resizable		Resizable	    }
	-selectbackground	{selectBackground	Foreground	    }
	-selectforeground	{selectForeground	Background	    }
	-showarrow		{showArrow		ShowArrow	    }
	-showlinenumbers	{showLineNumbers	ShowLineNumbers	    }
	-sortcommand		{sortCommand		SortCommand	    }
	-sortmode		{sortMode		SortMode	    }
	-stretchable		{stretchable		Stretchable	    }
	-stripebackground	{stripeBackground	Background	    }
	-stripeforeground	{stripeForeground	Foreground	    }
	-text			{text			Text		    }
	-title			{title			Title		    }
	-valign			{valign			Valign		    }
	-width			{width			Width		    }
	-wrap			{wrap			Wrap		    }
    }

    #
    # Extend some elements of the array colConfigSpecs
    #
    lappend colConfigSpecs(-align)			- left
    lappend colConfigSpecs(-changesnipside)		- 0
    lappend colConfigSpecs(-changetitlesnipside)	- 0
    lappend colConfigSpecs(-editable)			- 0
    lappend colConfigSpecs(-editwindow)			- entry
    lappend colConfigSpecs(-hide)			- 0
    lappend colConfigSpecs(-maxwidth)			- 0
    lappend colConfigSpecs(-resizable)			- 1
    lappend colConfigSpecs(-showarrow)			- 1
    lappend colConfigSpecs(-showlinenumbers)		- 0
    lappend colConfigSpecs(-sortmode)			- ascii
    lappend colConfigSpecs(-stretchable)		- 0
    lappend colConfigSpecs(-valign)			- center
    lappend colConfigSpecs(-width)			- 0
    lappend colConfigSpecs(-wrap)			- 0

    if {$usingTile} {
	unset colConfigSpecs(-labelbackground)
	unset colConfigSpecs(-labelbg)
	unset colConfigSpecs(-labelheight)
    }

    #
    # The array rowConfigSpecs is used to handle row configuration options.
    # The names of its elements are the row configuration options for the
    # Tablelist widget class.  The value of an array element is either an alias
    # name or a list containing the database name and class.
    #
    #	Command-Line Name	{Database Name		Database Class	}
    #	-----------------------------------------------------------------
    #
    variable rowConfigSpecs
    array set rowConfigSpecs {
	-background		{background		Background	}
	-bg			-background
	-font			{font			Font		}
	-foreground		{foreground		Foreground	}
	-fg			-foreground
	-hide			{hide			Hide		}
	-name			{name			Name		}
	-selectable		{selectable		Selectable	}
	-selectbackground	{selectBackground	Foreground	}
	-selectforeground	{selectForeground	Background	}
	-text			{text			Text		}
    }

    #
    # Check whether the -elide text widget tag option is available
    #
    variable canElide
    variable elide
    if {$::tk_version >= 8.3} {
	set canElide 1
	set elide -elide
    } else {
	set canElide 0
	set elide --
    }

    #
    # Extend some elements of the array rowConfigSpecs
    #
    if {$canElide} {
	lappend rowConfigSpecs(-hide)	- 0
    } else {
	unset rowConfigSpecs(-hide)
    }
    lappend rowConfigSpecs(-selectable)	- 1

    #
    # The array cellConfigSpecs is used to handle cell configuration options.
    # The names of its elements are the cell configuration options for the
    # Tablelist widget class.  The value of an array element is either an alias
    # name or a list containing the database name and class.
    #
    #	Command-Line Name	{Database Name		Database Class	}
    #	-----------------------------------------------------------------
    #
    variable cellConfigSpecs
    array set cellConfigSpecs {
	-background		{background		Background	}
	-bg			-background
	-editable		{editable		Editable	}
	-editwindow		{editWindow		EditWindow	}
	-font			{font			Font		}
	-foreground		{foreground		Foreground	}
	-fg			-foreground
	-image			{image			Image		}
	-selectbackground	{selectBackground	Foreground	}
	-selectforeground	{selectForeground	Background	}
	-stretchwindow		{stretchWindow		StretchWindow	}
	-text			{text			Text		}
	-valign			{valign			Valign		}
	-window			{window			Window		}
	-windowdestroy		{windowDestroy		WindowDestroy	}
	-windowupdate		{windowUpdate		WindowUpdate	}
    }

    #
    # Extend some elements of the array cellConfigSpecs
    #
    lappend cellConfigSpecs(-editable)		- 0
    lappend cellConfigSpecs(-editwindow)	- entry
    lappend cellConfigSpecs(-stretchwindow)	- 0
    lappend cellConfigSpecs(-valign)		- center

    #
    # Use a list to facilitate the handling of the command options 
    #
    variable cmdOpts [list \
	activate activatecell applysorting attrib bbox bodypath bodytag \
	canceledediting cancelediting cellattrib cellbbox cellcget \
	cellconfigure cellindex cellselection cget childcount childindex \
	childkeys collapse collapseall columnattrib columncget \
	columnconfigure columncount columnindex columnwidth config \
	configcelllist configcells configcolumnlist configcolumns \
	configrowlist configrows configure containing containingcell \
	containingcolumn cornerlabelpath cornerpath curcellselection \
	curselection depth delete deletecolumns descendantcount dicttoitem \
	editcell editinfo editwinpath editwintag entrypath expand expandall \
	expandedkeys fillcolumn findcolumnname findrowname finishediting \
	formatinfo get getcells getcolumns getformatted getformattedcells \
	getformattedcolumns getfullkeys getkeys hasattrib hascellattrib \
	hascolumnattrib hasrowattrib hidetargetmark imagelabelpath index \
	insert insertchild insertchildlist insertchildren insertcolumnlist \
	insertcolumns insertlist iselemsnipped isexpanded istitlesnipped \
	isviewable itemlistvar itemtodict labelpath labels labeltag move \
	movecolumn nearest nearestcell nearestcolumn noderow parentkey \
	refreshsorting rejectinput resetsortinfo rowattrib rowcget \
	rowconfigure scan searchcolumn see seecell seecolumn selection \
	separatorpath separators showtargetmark size sort sortbycolumn \
	sortbycolumnlist sortcolumn sortcolumnlist sortorder sortorderlist \
	targetmarkpath targetmarkpos togglecolumnhide togglerowhide \
	toplevelkey unsetattrib unsetcellattrib unsetcolumnattrib \
	unsetrowattrib viewablerowcount windowpath xview yview]

    proc restrictCmdOpts {} {
	variable canElide
	variable cmdOpts
	if {!$canElide} {
	    foreach opt [list collapse collapseall expand expandall \
			 insertchild insertchildlist insertchildren \
			 togglerowhide] {
		set idx [lsearch -exact $cmdOpts $opt]
		set cmdOpts [lreplace $cmdOpts $idx $idx]
	    }
	}

	if {$::tk_version < 8.5} {
	    foreach opt [list dicttoitem itemtodict] {
		set idx [lsearch -exact $cmdOpts $opt]
		set cmdOpts [lreplace $cmdOpts $idx $idx]
	    }
	}
    }
    restrictCmdOpts 

    #
    # Use lists to facilitate the handling of miscellaneous options
    #
    variable activeStyles  [list frame none underline]
    variable alignments    [list left right center]
    variable arrowStyles   [list flat5x3 flat5x4 flat6x4 flat7x4 flat7x5 \
				 flat7x7 flat8x4 flat8x5 flat9x5 flat9x6 \
				 flat11x6 flat15x8 flatAngle7x4 flatAngle7x5 \
				 flatAngle9x5 flatAngle9x6 flatAngle9x7 \
				 flatAngle10x6 flatAngle10x7 flatAngle11x6 \
				 flatAngle15x8 photo7x4 photo7x7 photo9x5 \
				 photo11x6 photo15x8 sunken8x7 sunken10x9 \
				 sunken12x11]
    variable arrowTypes    [list up down]
    variable colWidthOpts  [list -requested -stretched -total]
    variable curSelOpts    [list -all -nonhidden -viewable]
    variable expCollOpts   [list -fully -partly]
    variable findOpts      [list -descend -parent]
    variable gapTypeOpts   [list -any -horizontal -vertical]
    variable scanOpts      [list mark dragto]
    variable searchOpts    [list -all -backwards -check -descend -exact \
				 -formatted -glob -nocase -not -numeric \
				 -parent -regexp -start]
    variable selectionOpts [list anchor clear includes set]
    variable selectTypes   [list row cell]
    variable targetOpts    [list before inside]
    variable sortModes     [list ascii asciinocase command dictionary \
				 integer real]
    variable sortOpts      [list -increasing -decreasing]
    variable sortOrders    [list increasing decreasing]
    variable states	   [list disabled normal]
    variable treeStyles    [list adwaita ambiance aqua arc baghira bicolor1 \
				 bicolor2 bicolor3 bicolor4 blueMenta \
				 classic1 classic2 classic3 classic4 dust \
				 dustSand gtk klearlooks mate menta mint \
				 mint2 newWave oxygen1 oxygen2 phase plain1 \
				 plain2 plain3 plain4 plastik plastique \
				 radiance ubuntu ubuntu2 ubuntu3 ubuntuMate \
				 vistaAero vistaClassic win7Aero win7Classic \
				 win10 winnative winxpBlue winxpOlive \
				 winxpSilver yuyo]
    variable valignments   [list center top bottom]

    proc restrictArrowStyles {} {
	variable pngSupported
	if {!$pngSupported} {
	    variable arrowStyles
	    set idx [lsearch -exact $arrowStyles "photo7x7"]
	    set arrowStyles [lreplace $arrowStyles $idx $idx]
	}
    }
    restrictArrowStyles 

    #
    # The array maxIndentDepths holds the current max.
    # indentation depth for every tree style in use
    #
    variable maxIndentDepths

    #
    # Whether to support strictly Tk core listbox compatible bindings only
    #
    variable strictTk 0

    #
    # Define the command mapTabs, which returns the string obtained by
    # replacing all \t characters in its argument with \\t, as well as
    # the commands strMap and isInteger, needed because the "string map"
    # and "string is" commands were not available in Tcl 8.0 and 8.1.0
    #
    if {[catch {string map {} ""}] == 0} {
	interp alias {} ::tablelist::mapTabs {} string map {"\t" "\\t"}
	interp alias {} ::tablelist::strMap  {} string map
    } else {
	proc mapTabs str {
	    regsub -all "\t" $str "\\t" str
	    return $str
	}

	proc strMap {charMap str} {
	    foreach {key val} $charMap {
		#
		# We will only need this for noncritical key and str values
		#
		regsub -all $key $str $val str
	    }

	    return $str
	}
    }
    if {[catch {string is integer "0"}] == 0} {
	interp alias {} ::tablelist::isInteger {} string is integer -strict
    } else {
	proc isInteger str {
	    return [expr {[catch {format "%d" $str}] == 0}]
	}
    }

    #
    # Define the command genVirtualEvent, needed because the -data option of the
    # "event generate" command was not available in Tk versions earlier than 8.5
    #
    if {[catch {event generate . <<__>> -data ""}] == 0} {
	proc genVirtualEvent {win event userData} {
	    event generate $win $event -data $userData
	}
    } else {
	proc genVirtualEvent {win event userData} {
	    event generate $win $event
	}
    }

    interp alias {} ::tablelist::configSubCmd \
		 {} ::tablelist::configureSubCmd
    interp alias {} ::tablelist::insertchildSubCmd \
		 {} ::tablelist::insertchildrenSubCmd
}

#
# Private procedure creating the default bindings
# ===============================================
#

#------------------------------------------------------------------------------
# tablelist::createBindings
#
# Creates the default bindings for the binding tags Tablelist, TablelistWindow,
# TablelistKeyNav, TablelistBody, TablelistLabel, TablelistSubLabel,
# TablelistArrow, and TablelistEdit.
#------------------------------------------------------------------------------
proc tablelist::createBindings {} {
    #
    # Define some Tablelist class bindings
    #
    bind Tablelist <KeyPress> continue
    bind Tablelist <FocusIn> {
	tablelist::addActiveTag %W
	if {[string compare [focus -lastfor %W] %W] == 0} {
	    if {[winfo exists [%W editwinpath]]} {
		focus [set tablelist::ns%W::data(editFocus)]
	    } else {
		focus [%W bodypath]
	    }
	}
    }
    bind Tablelist <FocusOut>		{ tablelist::removeActiveTag %W }
    bind Tablelist <<TablelistSelect>>	{ event generate %W <<ListboxSelect>> }
    bind Tablelist <Destroy>		{ tablelist::cleanup %W }
    variable usingTile
    if {$usingTile} {
	bind Tablelist <Activate>	{ tablelist::updateCanvases %W }
	bind Tablelist <Deactivate>	{ tablelist::updateCanvases %W }
	bind Tablelist <<ThemeChanged>>	{
	    after idle [list tablelist::updateConfigSpecs %W]
	}
    }

    #
    # Define some TablelistWindow class bindings
    #
    bind TablelistWindow <Destroy>	{ tablelist::cleanupWindow %W }

    #
    # Define the binding tags TablelistKeyNav and TablelistBody
    #
    mwutil::defineKeyNav Tablelist
    defineTablelistBody 

    #
    # Define the virtual events <<Button3>> and <<ShiftButton3>>
    #
    event add <<Button3>> <Button-3>
    event add <<ShiftButton3>> <Shift-Button-3>
    variable winSys
    if {[string compare $winSys "classic"] == 0 ||
	[string compare $winSys "aqua"] == 0} {
	event add <<Button3>> <Control-Button-1>
	event add <<ShiftButton3>> <Shift-Control-Button-1>
    }

    #
    # Define some mouse bindings for the binding tag TablelistLabel
    #
    bind TablelistLabel <Enter>		  { tablelist::labelEnter  %W %X %Y %x }
    bind TablelistLabel <Motion>	  { tablelist::labelEnter  %W %X %Y %x }
    bind TablelistLabel <Leave>		  { tablelist::labelLeave  %W %X %x %y }
    bind TablelistLabel <Button-1>	  { tablelist::labelB1Down %W %x 0 }
    bind TablelistLabel <Shift-Button-1>  { tablelist::labelB1Down %W %x 1 }
    bind TablelistLabel <B1-Motion>	{ tablelist::labelB1Motion %W %X %x %y }
    bind TablelistLabel <B1-Enter>	{ tablelist::labelB1Enter  %W }
    bind TablelistLabel <B1-Leave>	{ tablelist::labelB1Leave  %W %x %y }
    bind TablelistLabel <ButtonRelease-1> { tablelist::labelB1Up   %W %X}
    bind TablelistLabel <<Button3>>	  { tablelist::labelB3Down %W 0 }
    bind TablelistLabel <<ShiftButton3>>  { tablelist::labelB3Down %W 1 }
    bind TablelistLabel <Double-Button-1>	{ tablelist::labelDblB1 %W %x 0}
    bind TablelistLabel <Shift-Double-Button-1> { tablelist::labelDblB1 %W %x 1}

    #
    # Define the binding tags TablelistSubLabel and TablelistArrow
    #
    defineTablelistSubLabel 
    defineTablelistArrow 

    #
    # Define the binding tag TablelistEdit if the file tablelistEdit.tcl exists
    #
    catch {defineTablelistEdit}
}

#
# Public procedure creating a new tablelist widget
# ================================================
#

#------------------------------------------------------------------------------
# tablelist::tablelist
#
# Creates a new tablelist widget whose name is specified as the first command-
# line argument, and configures it according to the options and their values
# given on the command line.  Returns the name of the newly created widget.
#------------------------------------------------------------------------------
proc tablelist::tablelist args {
    variable usingTile
    variable configSpecs
    variable configOpts
    variable canElide

    if {[llength $args] == 0} {
	mwutil::wrongNumArgs "tablelist pathName ?options?"
    }

    #
    # Create a frame of the class Tablelist
    #
    set win [lindex $args 0]
    if {[catch {
	if {$usingTile} {
	    ttk::frame $win -style Frame$win.TFrame -class Tablelist \
			    -height 0 -width 0 -padding 0
	} else {
	    tk::frame $win -class Tablelist -container 0 -height 0 -width 0
	    catch {$win configure -padx 0 -pady 0}
	}
    } result] != 0} {
	return -code error $result
    }

    #
    # Create a namespace within the current one to hold the data of the widget
    #
    namespace eval ns$win {
	#
	# The folowing array holds various data for this widget
	#
	variable data
	array set data {
	    arrowWidth		 10
	    arrowHeight		 9
	    hasListVar		 0
	    isDisabled		 0
	    ownsFocus		 0
	    charWidth		 1
	    hdrPixels		 0
	    activeRow		 0
	    activeCol		 0
	    anchorRow		 0
	    anchorCol		 0
	    seqNum		-1
	    freeKeyList		 {}
	    keyList		 {}
	    itemList		 {}
	    itemCount		 0
	    lastRow		-1
	    colList		 {}
	    colCount		 0
	    lastCol		-1
	    treeCol		 0
	    gotResizeEvent	 0
	    rightX		 0
	    btmY		 0
	    rowTagRefCount	 0
	    cellTagRefCount	 0
	    imgCount		 0
	    winCount		 0
	    indentCount		 0
	    afterId		 ""
	    labelClicked	 0
	    arrowColList	 {}
	    sortColList		 {}
	    sortOrder		 ""
	    editKey		 ""
	    editRow		-1
	    editCol		-1
	    canceled		 0
	    fmtKey		 ""
	    fmtRow		-1
	    fmtCol		-1
	    prevCell		 ""
	    prevCol		-1
	    forceAdjust		 0
	    fmtCmdFlagList	 {}
	    hasFmtCmds		 0
	    scrlColOffset	 0
	    cellsToReconfig	 {}
	    nonViewableRowCount	 0
	    viewableRowList	 {-1}
	    hiddenColCount	 0
	    root-row		-1
	    root-parent		 ""
	    root-children	 {}
	    keyToRowMapValid	 1
	    searchStartIdx	 0
	    keyBeingExpanded	 ""
	    destroyIdList	 {}
	    justEntered		 0
	    inEditWin		 0
	}

	#
	# The following array is used to hold arbitrary
	# attributes and their values for this widget
	#
	variable attribs
    }

    #
    # Initialize some further components of data
    #
    upvar ::tablelist::ns${win}::data data
    foreach opt $configOpts {
	set data($opt) [lindex $configSpecs($opt) 3]
    }
    if {$usingTile} {
	setThemeDefaults
	variable themeDefaults
	set data(currentTheme) [getCurrentTheme]
	set data(themeDefaults) [array get themeDefaults]
	if {[string compare $data(currentTheme) "tileqt"] == 0} {
	    set data(widgetStyle) [tileqt_currentThemeName]
	    if {[info exists ::env(KDE_SESSION_VERSION)] &&
		[string length $::env(KDE_SESSION_VERSION)] != 0} {
		set data(colorScheme) [getKdeConfigVal "General" "ColorScheme"]
	    } else {
		set data(colorScheme) [getKdeConfigVal "KDE" "colorScheme"]
	    }
	} else {
	    set data(widgetStyle) ""
	    set data(colorScheme) ""
	}
    }
    set data(-titlecolumns)	0		;# for Tk versions < 8.3
    set data(-treecolumn)	0		;# for Tk versions < 8.3
    set data(-treestyle)	""		;# for Tk versions < 8.3
    set data(colFontList)	[list $data(-font)]
    set data(listVarTraceCmd)	[list tablelist::listVarTrace $win]
    set data(bodyTag)		body$win
    set data(labelTag)		label$win
    set data(editwinTag)	editwin$win
    set data(body)		$win.body
    set data(bodyFrm)		$data(body).f
    set data(bodyFrmEd)		$data(bodyFrm).e
    set data(rowGap)		$data(body).g
    set data(hdr)		$win.hdr
    set data(hdrTxt)		$data(hdr).t
    set data(hdrTxtFrm)		$data(hdrTxt).f
    set data(hdrTxtFrmCanv)	$data(hdrTxtFrm).c
    set data(hdrTxtFrmLbl)	$data(hdrTxtFrm).l
    set data(hdrFrm)		$data(hdr).f
    set data(hdrFrmLbl)		$data(hdrFrm).l
    set data(colGap)		$data(hdr).g
    set data(lb)		$win.lb
    set data(vsep)		$win.vsep
    set data(hsep)		$win.hsep

    #
    # Get a unique name for the corner frame (a sibling of the tablelist widget)
    #
    set data(corner) $win-corner
    for {set n 2} {[winfo exists $data(corner)]} {incr n} {
	set data(corner) $data(corner)$n
    }
    set data(cornerLbl) $data(corner).l

    #
    # Create a child hierarchy used to hold the column labels.  The
    # labels will be created as children of the frame data(hdrTxtFrm),
    # which is embedded into the text widget data(hdrTxt) (in order
    # to make it scrollable), which in turn fills the frame data(hdr)
    # (whose width and height can be set arbitrarily in pixels).
    #

    set w $data(hdr)			;# header frame
    tk::frame $w -borderwidth 0 -container 0 -height 0 -highlightthickness 0 \
		 -relief flat -takefocus 0 -width 0
    catch {$w configure -padx 0 -pady 0}
    bind $w <Configure> { tablelist::hdrConfigure %W %w }
    pack $w -fill x

    set w $data(hdrTxt)			;# text widget within the header frame
    text $w -borderwidth 0 -highlightthickness 0 -insertwidth 0 \
	    -padx 0 -pady 0 -state normal -takefocus 0 -wrap none
    place $w -relheight 1.0 -relwidth 1.0
    bindtags $w [lreplace [bindtags $w] 1 1]
    tk::frame $data(hdrTxtFrm) -borderwidth 0 -container 0 -height 0 \
			      -highlightthickness 0 -relief flat \
			      -takefocus 0 -width 0
    catch {$data(hdrTxtFrm) configure -padx 0 -pady 0}
    $w window create 1.0 -window $data(hdrTxtFrm)

    set w $data(hdrFrm)			;# filler frame within the header frame
    tk::frame $w -borderwidth 0 -container 0 -height 0 -highlightthickness 0 \
		 -relief flat -takefocus 0 -width 0
    catch {$w configure -padx 0 -pady 0}
    place $w -relheight 1.0 -relwidth 1.0

    set w $data(hdrFrmLbl)		;# label within the filler frame
    set x 0
    if {$usingTile} {
	ttk::label $w -style TablelistHeader.TLabel -image "" \
		      -padding {1 1 1 1} -takefocus 0 -text "" \
		      -textvariable "" -underline -1 -wraplength 0
	if {[string compare [getCurrentTheme] "aqua"] == 0} {
	    set x -1
	}
    } else {
	tk::label $w -bitmap "" -highlightthickness 0 -image "" \
		     -takefocus 0 -text "" -textvariable "" -underline -1 \
		     -wraplength 0
    }
    place $w -x $x -relheight 1.0 -relwidth 1.0

    set w $data(corner)			;# corner frame (outside the tablelist)
    tk::frame $w -borderwidth 0 -container 0 -height 0 -highlightthickness 0 \
		 -relief flat -takefocus 0 -width 0
    catch {$w configure -padx 0 -pady 0}

    set w $data(cornerLbl)		;# label within the corner frame
    if {$usingTile} {
	ttk::label $w -style TablelistHeader.TLabel -image "" \
		      -padding {1 1 1 1} -takefocus 0 -text "" \
		      -textvariable "" -underline -1 -wraplength 0
    } else {
	tk::label $w -bitmap "" -highlightthickness 0 -image "" \
		     -takefocus 0 -text "" -textvariable "" -underline -1 \
		     -wraplength 0
    }
    place $w -relheight 1.0 -relwidth 1.0

    #
    # Create the body text widget within the main frame
    #
    set w $data(body)
    text $w -borderwidth 0 -exportselection 0 -highlightthickness 0 \
	    -insertwidth 0 -padx 0 -pady 0 -state normal -takefocus 0 -wrap none
    catch {$w configure -undo 0};  # because of a text widget issue in Tk 8.6.6
    bind $w <Configure> { tablelist::bodyConfigure %W %w %h }
    pack $w -expand 1 -fill both

    #
    # Modify the list of binding tags of the body text widget
    #
    bindtags $w [list $w $data(bodyTag) TablelistBody [winfo toplevel $w] \
		 TablelistKeyNav all]

    #
    # Create the "stripe", "select", "curRow", "active", "disabled", "redraw",
    # "hiddenRow", "elidedRow", "hiddenCol", and "elidedCol" tags in the body
    # text widget.  Don't use the built-in "sel" tag because on Windows the
    # selection in a text widget only becomes visible when the window gets
    # the input focus.  DO NOT CHANGE the order of creation of these tags!
    #
    $w tag configure stripe -background "" -foreground ""    ;# will be changed
    $w tag configure select -relief raised
    $w tag configure curRow -borderwidth 1 -relief raised
    $w tag configure active -borderwidth ""		     ;# will be changed
    $w tag configure disabled -foreground ""		     ;# will be changed
    $w tag configure redraw -relief sunken
    if {$canElide} {
	$w tag configure hiddenRow -elide 1	;# used for hiding a row
	$w tag configure elidedRow -elide 1	;# used when collapsing a node
	$w tag configure hiddenCol -elide 1	;# used for hiding a column
	$w tag configure elidedCol -elide 1	;# used for horizontal scrolling
    }
    if {$::tk_version >= 8.5} {
	$w tag configure elidedWin -elide 1	;# used for eliding a window
    }

    #
    # Create two frames used to display a gap between two consecutive
    # rows/columns when moving a row/column interactively
    #
    tk::frame $data(rowGap) -borderwidth 1 -container 0 -highlightthickness 0 \
			    -relief sunken -takefocus 0 -height 4
    tk::frame $data(colGap) -borderwidth 1 -container 0 -highlightthickness 0 \
			    -relief sunken -takefocus 0 -width 4

    #
    # Create an unmanaged listbox child, used to handle the -setgrid option
    #
    listbox $data(lb)

    #
    # Create the bitmaps needed to display the sort ranks
    #
    createSortRankImgs $win

    #
    # Take into account that some scripts start by
    # destroying all children of the root window
    #
    variable helpLabel
    if {![winfo exists $helpLabel]} {
	if {$usingTile} {
	    ttk::label $helpLabel -takefocus 0
	} else {
	    tk::label $helpLabel -takefocus 0
	}
    }

    #
    # Configure the widget according to the command-line
    # arguments and to the available database options
    #
    if {[catch {
	mwutil::configureWidget $win configSpecs tablelist::doConfig \
				tablelist::doCget [lrange $args 1 end] 1
    } result] != 0} {
	destroy $win
	return -code error $result
    }

    #
    # Move the original widget command into the current namespace and
    # create an alias of the original name for a new widget procedure
    #
    rename ::$win $win
    interp alias {} ::$win {} tablelist::tablelistWidgetCmd $win

    #
    # Register a callback to be invoked whenever the PRIMARY
    # selection is owned by the window win and someone
    # attempts to retrieve it as a UTF8_STRING or STRING
    #
    selection handle -type UTF8_STRING $win \
	[list ::tablelist::fetchSelection $win]
    selection handle -type STRING $win \
	[list ::tablelist::fetchSelection $win]

    #
    # Set a trace on the array elements data(activeRow),
    # data(avtiveCol), and data(-selecttype)
    #
    foreach name {activeRow activeCol -selecttype} {
	trace variable data($name) w [list tablelist::activeTrace $win]
    }

    return $win
}

#
# Private procedures implementing the tablelist widget command
# ============================================================
#

#------------------------------------------------------------------------------
# tablelist::tablelistWidgetCmd
#
# Processes the Tcl command corresponding to a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::tablelistWidgetCmd {win args} {
    if {[llength $args] == 0} {
	mwutil::wrongNumArgs "$win option ?arg arg ...?"
    }

    variable cmdOpts
    set cmd [mwutil::fullOpt "option" [lindex $args 0] $cmdOpts]
    return [${cmd}SubCmd $win [lrange $args 1 end]]
}

#------------------------------------------------------------------------------
# tablelist::activateSubCmd
#------------------------------------------------------------------------------
proc tablelist::activateSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win activate index"
    }

    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled)} {
	return ""
    }

    synchronize $win
    displayItems $win
    set index [rowIndex $win [lindex $argList 0] 0]

    #
    # Adjust the index to fit within the existing viewable items
    #
    adjustRowIndex $win index 1

    set data(activeRow) $index
    return ""
}

#------------------------------------------------------------------------------
# tablelist::activatecellSubCmd
#------------------------------------------------------------------------------
proc tablelist::activatecellSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win activatecell cellIndex"
    }

    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled)} {
	return ""
    }

    synchronize $win
    displayItems $win
    foreach {row col} [cellIndex $win [lindex $argList 0] 0] {}

    #
    # Adjust the row and column indices to fit
    # within the existing viewable elements
    #
    adjustRowIndex $win row 1
    adjustColIndex $win col 1

    set data(activeRow) $row
    set data(activeCol) $col
    return ""
}

#------------------------------------------------------------------------------
# tablelist::applysortingSubCmd
#------------------------------------------------------------------------------
proc tablelist::applysortingSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win applysorting itemList"
    }

    return [sortList $win [lindex $argList 0]]
}

#------------------------------------------------------------------------------
# tablelist::attribSubCmd
#------------------------------------------------------------------------------
proc tablelist::attribSubCmd {win argList} {
    return [mwutil::attribSubCmd $win "widget" $argList]
}

#------------------------------------------------------------------------------
# tablelist::bboxSubCmd
#------------------------------------------------------------------------------
proc tablelist::bboxSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win bbox index"
    }

    synchronize $win
    displayItems $win
    set index [rowIndex $win [lindex $argList 0] 0]

    upvar ::tablelist::ns${win}::data data
    set w $data(body)
    set dlineinfo [$w dlineinfo [expr {$index + 1}].0]
    if {$data(itemCount) == 0 || [llength $dlineinfo] == 0} {
	return {}
    }

    set spacing1 [$w cget -spacing1]
    set spacing3 [$w cget -spacing3]
    foreach {x y width height baselinePos} $dlineinfo {}
    incr height -[expr {$spacing1 + $spacing3}]
    if {$height < 0} {
	set height 0
    }
    return [list [expr {$x + [winfo x $w]}] \
		 [expr {$y + [winfo y $w] + $spacing1}] $width $height]
}

#------------------------------------------------------------------------------
# tablelist::bodypathSubCmd
#------------------------------------------------------------------------------
proc tablelist::bodypathSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win bodypath"
    }

    upvar ::tablelist::ns${win}::data data
    return $data(body)
}

#------------------------------------------------------------------------------
# tablelist::bodytagSubCmd
#------------------------------------------------------------------------------
proc tablelist::bodytagSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win bodytag"
    }

    upvar ::tablelist::ns${win}::data data
    return $data(bodyTag)
}

#------------------------------------------------------------------------------
# tablelist::cancelededitingSubCmd
#------------------------------------------------------------------------------
proc tablelist::cancelededitingSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win canceledediting"
    }

    upvar ::tablelist::ns${win}::data data
    return $data(canceled)
}

#------------------------------------------------------------------------------
# tablelist::canceleditingSubCmd
#------------------------------------------------------------------------------
proc tablelist::canceleditingSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win cancelediting"
    }

    synchronize $win
    return [doCancelEditing $win]
}

#------------------------------------------------------------------------------
# tablelist::cellattribSubCmd
#------------------------------------------------------------------------------
proc tablelist::cellattribSubCmd {win argList} {
    if {[llength $argList] < 1} {
	mwutil::wrongNumArgs "$win cellattrib cellIndex ?name? ?value\
			      name value ...?"
    }

    synchronize $win
    foreach {row col} [cellIndex $win [lindex $argList 0] 1] {}
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    return [mwutil::attribSubCmd $win $key,$col [lrange $argList 1 end]]
}

#------------------------------------------------------------------------------
# tablelist::cellbboxSubCmd
#------------------------------------------------------------------------------
proc tablelist::cellbboxSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win cellbbox cellIndex"
    }

    synchronize $win
    foreach {row col} [cellIndex $win [lindex $argList 0] 0] {}
    upvar ::tablelist::ns${win}::data data
    if {$row < 0 || $row > $data(lastRow) ||
	$col < 0 || $col > $data(lastCol)} {
	return {}
    }

    foreach {x y width height} [bboxSubCmd $win $row] {}
    set w $data(hdrTxtFrmLbl)$col
    return [list [expr {[winfo rootx $w] - [winfo rootx $win]}] $y \
		 [winfo width $w] $height]
}

#------------------------------------------------------------------------------
# tablelist::cellcgetSubCmd
#------------------------------------------------------------------------------
proc tablelist::cellcgetSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win cellcget cellIndex option"
    }

    synchronize $win
    foreach {row col} [cellIndex $win [lindex $argList 0] 1] {}
    variable cellConfigSpecs
    set opt [mwutil::fullConfigOpt [lindex $argList 1] cellConfigSpecs]
    return [doCellCget $row $col $win $opt]
}

#------------------------------------------------------------------------------
# tablelist::cellconfigureSubCmd
#------------------------------------------------------------------------------
proc tablelist::cellconfigureSubCmd {win argList} {
    if {[llength $argList] < 1} {
	mwutil::wrongNumArgs "$win cellconfigure cellIndex ?option? ?value\
			      option value ...?"
    }

    synchronize $win
    displayItems $win
    variable cellConfigSpecs
    foreach {row col} [cellIndex $win [lindex $argList 0] 1] {}
    return [mwutil::configureSubCmd $win cellConfigSpecs \
	    "tablelist::doCellConfig $row $col" \
	    "tablelist::doCellCget $row $col" [lrange $argList 1 end]]
}

#------------------------------------------------------------------------------
# tablelist::cellindexSubCmd
#------------------------------------------------------------------------------
proc tablelist::cellindexSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win cellindex cellIndex"
    }

    synchronize $win
    return [join [cellIndex $win [lindex $argList 0] 0] ","]
}

#------------------------------------------------------------------------------
# tablelist::cellselectionSubCmd
#------------------------------------------------------------------------------
proc tablelist::cellselectionSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 2 || $argCount > 3} {
	mwutil::wrongNumArgs \
		"$win cellselection option firstCellIndex lastCellIndex" \
		"$win cellselection option cellIndexList"
    }

    synchronize $win
    displayItems $win
    variable selectionOpts
    set opt [mwutil::fullOpt "option" [lindex $argList 0] $selectionOpts]
    set first [lindex $argList 1]

    switch $opt {
	anchor -
	includes {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win cellselection $opt cellIndex"
	    }
	    foreach {row col} [cellIndex $win $first 0] {}
	    return [cellSelection $win $opt $row $col $row $col]
	}

	clear -
	set {
	    if {$argCount == 2} {
		foreach elem $first {
		    foreach {row col} [cellIndex $win $elem 0] {}
		    cellSelection $win $opt $row $col $row $col
		}
	    } else {
		foreach {firstRow firstCol} [cellIndex $win $first 0] {}
		foreach {lastRow lastCol} \
			[cellIndex $win [lindex $argList 2] 0] {}
		cellSelection $win $opt $firstRow $firstCol $lastRow $lastCol
	    }

	    updateColors $win
	    invokeMotionHandler $win
	    return ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::cgetSubCmd
#------------------------------------------------------------------------------
proc tablelist::cgetSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win cget option"
    }

    #
    # Return the value of the specified configuration option
    #
    variable configSpecs
    set opt [mwutil::fullConfigOpt [lindex $argList 0] configSpecs]
    return [doCget $win $opt]
}

#------------------------------------------------------------------------------
# tablelist::childcountSubCmd
#------------------------------------------------------------------------------
proc tablelist::childcountSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win childcount nodeIndex"
    }

    synchronize $win
    set key [nodeIndexToKey $win [lindex $argList 0]]
    upvar ::tablelist::ns${win}::data data
    return [llength $data($key-children)]
}

#------------------------------------------------------------------------------
# tablelist::childindexSubCmd
#------------------------------------------------------------------------------
proc tablelist::childindexSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win childindex index"
    }

    synchronize $win
    set row [rowIndex $win [lindex $argList 0] 0 1]
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    set parentKey $data($key-parent)
    return [lsearch -exact $data($parentKey-children) $key]
}

#------------------------------------------------------------------------------
# tablelist::childkeysSubCmd
#------------------------------------------------------------------------------
proc tablelist::childkeysSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win childkeys nodeIndex"
    }

    synchronize $win
    set key [nodeIndexToKey $win [lindex $argList 0]]
    upvar ::tablelist::ns${win}::data data
    return $data($key-children)
}

#------------------------------------------------------------------------------
# tablelist::collapseSubCmd
#------------------------------------------------------------------------------
proc tablelist::collapseSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win collapse index ?-fully|-partly?"
    }

    synchronize $win
    displayItems $win
    set index [rowIndex $win [lindex $argList 0] 0 1]

    if {$argCount == 1} {
	set fullCollapsion 1
    } else {
	variable expCollOpts
	set opt [mwutil::fullOpt "option" [lindex $argList 1] $expCollOpts]
	set fullCollapsion [expr {[string compare $opt "-fully"] == 0}]
    }

    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $index]
    set col $data(treeCol)
    if {![info exists data($key,$col-indent)]} {
	return ""
    }

    if {[string length $data(-collapsecommand)] != 0} {
	uplevel #0 $data(-collapsecommand) [list $win $index]
    }

    #
    # Set the indentation image to the collapsed one
    #
    set data($key,$col-indent) [strMap \
	{"indented" "collapsed" "expanded" "collapsed"} $data($key,$col-indent)]
    if {[winfo exists $data(body).ind_$key,$col]} {
	$data(body).ind_$key,$col configure -image $data($key,$col-indent)
    }

    if {[llength $data($key-children)] == 0} {
	return ""
    }

    #
    # Elide the descendants of this item
    #
    set fromRow [expr {$index + 1}]
    set toRow [nodeRow $win $key end]
    for {set row $fromRow} {$row < $toRow} {incr row} {
	doRowConfig $row $win -elide 1

	if {$fullCollapsion} {
	    set descKey [lindex $data(keyList) $row]
	    if {[llength $data($descKey-children)] != 0} {
		if {[string length $data(-collapsecommand)] != 0} {
		    uplevel #0 $data(-collapsecommand) \
			[list $win [keyToRow $win $descKey]]
		}

		#
		# Change the descendant's indentation image
		# from the expanded to the collapsed one
		#
		set data($descKey,$col-indent) [strMap \
		    {"expanded" "collapsed"} $data($descKey,$col-indent)]
		if {[winfo exists $data(body).ind_$descKey,$col]} {
		    $data(body).ind_$descKey,$col configure -image \
			$data($descKey,$col-indent)
		}
	    }
	}
    }

    set callerProc [lindex [info level -1] 0]
    if {![string match "collapse*SubCmd" $callerProc]} {
	#
	# Destroy the label and messsage widgets
	# embedded into the descendants just elided
	#
	set widgets {}
	set fromTextIdx [expr {$fromRow + 1}].0
	set toTextIdx [expr {$toRow + 1}].0
	foreach {dummy path textIdx} \
		[$data(body) dump -window $fromTextIdx $toTextIdx] {
	    if {[string length $path] != 0} {
		set class [winfo class $path]
		if {[string compare $class "Label"] == 0 ||
		    [string compare $class "Message"] == 0} {
		    lappend widgets $path
		}
	    }
	}
	set destroyId [after 300 [list tablelist::destroyWidgets $win]]
	lappend data(destroyIdList) $destroyId
	set data(widgets-$destroyId) $widgets

	adjustRowIndex $win data(anchorRow) 1

	set activeRow $data(activeRow)
	adjustRowIndex $win activeRow 1
	set data(activeRow) $activeRow

	adjustElidedText $win
	redisplayVisibleItems $win
	makeStripes $win
	adjustSepsWhenIdle $win
	updateVScrlbarWhenIdle $win
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::collapseallSubCmd
#------------------------------------------------------------------------------
proc tablelist::collapseallSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount > 1} {
	mwutil::wrongNumArgs "$win collapseall ?-fully|-partly?"
    }

    if {$argCount == 0} {
	set fullCollapsion 1
    } else {
	variable expCollOpts
	set opt [mwutil::fullOpt "option" [lindex $argList 0] $expCollOpts]
	set fullCollapsion [expr {[string compare $opt "-fully"] == 0}]
    }

    synchronize $win
    displayItems $win

    upvar ::tablelist::ns${win}::data data
    set col $data(treeCol)

    if {[winfo viewable $win]} {
	purgeWidgets $win
	update idletasks
	if {![array exists ::tablelist::ns${win}::data]} {
	    return ""
	}
    }

    set childIdx 0
    set childCount [llength $data(root-children)]
    foreach key $data(root-children) {
	if {[llength $data($key-children)] == 0} {
	    incr childIdx
	    continue
	}

	if {[string length $data(-collapsecommand)] != 0} {
	    uplevel #0 $data(-collapsecommand) [list $win [keyToRow $win $key]]
	}

	#
	# Change the indentation image from the expanded to the collapsed one
	#
	set data($key,$col-indent) \
	    [strMap {"expanded" "collapsed"} $data($key,$col-indent)]
	if {[winfo exists $data(body).ind_$key,$col]} {
	    $data(body).ind_$key,$col configure -image $data($key,$col-indent)
	}

	#
	# Elide the descendants of this item
	#
	incr childIdx
	if {[llength $data($key-children)] != 0} {
	    set fromRow [expr {[keyToRow $win $key] + 1}]
	    if {$childIdx < $childCount} {
		set nextChildKey [lindex $data(root-children) $childIdx]
		set toRow [keyToRow $win $nextChildKey]
	    } else {
		set toRow $data(itemCount)
	    }
	    for {set row $fromRow} {$row < $toRow} {incr row} {
		doRowConfig $row $win -elide 1

		if {$fullCollapsion} {
		    set descKey [lindex $data(keyList) $row]
		    if {[llength $data($descKey-children)] != 0} {
			if {[string length $data(-collapsecommand)] != 0} {
			    uplevel #0 $data(-collapsecommand) \
				[list $win [keyToRow $win $descKey]]
			}

			#
			# Change the descendant's indentation image
			# from the expanded to the collapsed one
			#
			set data($descKey,$col-indent) \
			    [strMap {"expanded" "collapsed"} \
				    $data($descKey,$col-indent)]
			if {[winfo exists $data(body).ind_$descKey,$col]} {
			    $data(body).ind_$descKey,$col configure -image \
				$data($descKey,$col-indent)
			}
		    }
		}
	    }

	    #
	    # Destroy the label and messsage widgets
	    # embedded into the descendants just elided
	    #
	    set widgets {}
	    set fromTextIdx [expr {$fromRow + 1}].0
	    set toTextIdx [expr {$toRow + 1}].0
	    foreach {dummy path textIdx} \
		    [$data(body) dump -window $fromTextIdx $toTextIdx] {
		if {[string length $path] != 0} {
		    set class [winfo class $path]
		    if {[string compare $class "Label"] == 0 ||
			[string compare $class "Message"] == 0} {
			lappend widgets $path
		    }
		}
	    }
	    set destroyId [after 300 [list tablelist::destroyWidgets $win]]
	    lappend data(destroyIdList) $destroyId
	    set data(widgets-$destroyId) $widgets
	}
    }

    adjustRowIndex $win data(anchorRow) 1

    set activeRow $data(activeRow)
    adjustRowIndex $win activeRow 1
    set data(activeRow) $activeRow

    adjustElidedText $win
    redisplayVisibleItems $win
    makeStripes $win
    adjustSepsWhenIdle $win
    updateVScrlbarWhenIdle $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::columnattribSubCmd
#------------------------------------------------------------------------------
proc tablelist::columnattribSubCmd {win argList} {
    if {[llength $argList] < 1} {
	mwutil::wrongNumArgs "$win columnattrib columnIndex ?name? ?value\
			      name value ...?"
    }

    set col [colIndex $win [lindex $argList 0] 1]
    return [mwutil::attribSubCmd $win $col [lrange $argList 1 end]]
}

#------------------------------------------------------------------------------
# tablelist::columncgetSubCmd
#------------------------------------------------------------------------------
proc tablelist::columncgetSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win columncget columnIndex option"
    }

    set col [colIndex $win [lindex $argList 0] 1]
    variable colConfigSpecs
    set opt [mwutil::fullConfigOpt [lindex $argList 1] colConfigSpecs]
    return [doColCget $col $win $opt]
}

#------------------------------------------------------------------------------
# tablelist::columnconfigureSubCmd
#------------------------------------------------------------------------------
proc tablelist::columnconfigureSubCmd {win argList} {
    if {[llength $argList] < 1} {
	mwutil::wrongNumArgs "$win columnconfigure columnIndex ?option? ?value\
			      option value ...?"
    }

    synchronize $win
    displayItems $win
    variable colConfigSpecs
    set col [colIndex $win [lindex $argList 0] 1]
    return [mwutil::configureSubCmd $win colConfigSpecs \
	    "tablelist::doColConfig $col" "tablelist::doColCget $col" \
	    [lrange $argList 1 end]]
}

#------------------------------------------------------------------------------
# tablelist::columncountSubCmd
#------------------------------------------------------------------------------
proc tablelist::columncountSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win columncount"
    }

    upvar ::tablelist::ns${win}::data data
    return $data(colCount)
}

#------------------------------------------------------------------------------
# tablelist::columnindexSubCmd
#------------------------------------------------------------------------------
proc tablelist::columnindexSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win columnindex columnIndex"
    }

    return [colIndex $win [lindex $argList 0] 0]
}

#------------------------------------------------------------------------------
# tablelist::columnwidthSubCmd
#------------------------------------------------------------------------------
proc tablelist::columnwidthSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win columnwidth columnIndex\
			      ?-requested|-stretched|-total?"
    }

    synchronize $win
    set col [colIndex $win [lindex $argList 0] 1]
    if {$argCount == 1} {
	set opt -requested
    } else {
	variable colWidthOpts
	set opt [mwutil::fullOpt "option" [lindex $argList 1] $colWidthOpts]
    }

    return [colWidth $win $col $opt]
}

#------------------------------------------------------------------------------
# tablelist::configcelllistSubCmd
#------------------------------------------------------------------------------
proc tablelist::configcelllistSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win configcelllist cellConfigSpecList"
    }

    return [configcellsSubCmd $win [lindex $argList 0]]
}

#------------------------------------------------------------------------------
# tablelist::configcellsSubCmd
#------------------------------------------------------------------------------
proc tablelist::configcellsSubCmd {win argList} {
    synchronize $win
    displayItems $win
    variable cellConfigSpecs

    set argCount [llength $argList]
    foreach {cell opt val} $argList {
	if {$argCount == 1} {
	    return -code error "option and value for \"$cell\" missing"
	} elseif {$argCount == 2} {
	    return -code error "value for \"$opt\" missing"
	}
	foreach {row col} [cellIndex $win $cell 1] {}
	mwutil::configureWidget $win cellConfigSpecs \
		"tablelist::doCellConfig $row $col" \
		"tablelist::doCellCget $row $col" [list $opt $val] 0
	incr argCount -3
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::configcolumnlistSubCmd
#------------------------------------------------------------------------------
proc tablelist::configcolumnlistSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win configcolumnlist columnConfigSpecList"
    }

    return [configcolumnsSubCmd $win [lindex $argList 0]]
}

#------------------------------------------------------------------------------
# tablelist::configcolumnsSubCmd
#------------------------------------------------------------------------------
proc tablelist::configcolumnsSubCmd {win argList} {
    synchronize $win
    displayItems $win
    variable colConfigSpecs

    set argCount [llength $argList]
    foreach {col opt val} $argList {
	if {$argCount == 1} {
	    return -code error "option and value for \"$col\" missing"
	} elseif {$argCount == 2} {
	    return -code error "value for \"$opt\" missing"
	}
	set col [colIndex $win $col 1]
	mwutil::configureWidget $win colConfigSpecs \
		"tablelist::doColConfig $col" "tablelist::doColCget $col" \
		[list $opt $val] 0
	incr argCount -3
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::configrowlistSubCmd
#------------------------------------------------------------------------------
proc tablelist::configrowlistSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win configrowlist rowConfigSpecList"
    }

    return [configrowsSubCmd $win [lindex $argList 0]]
}

#------------------------------------------------------------------------------
# tablelist::configrowsSubCmd
#------------------------------------------------------------------------------
proc tablelist::configrowsSubCmd {win argList} {
    synchronize $win
    displayItems $win
    variable rowConfigSpecs

    set argCount [llength $argList]
    foreach {rowSpec opt val} $argList {
	if {$argCount == 1} {
	    return -code error "option and value for \"$rowSpec\" missing"
	} elseif {$argCount == 2} {
	    return -code error "value for \"$opt\" missing"
	}
	set row [rowIndex $win $rowSpec 0 1]
	mwutil::configureWidget $win rowConfigSpecs \
		"tablelist::doRowConfig $row" "tablelist::doRowCget $row" \
		[list $opt $val] 0
	incr argCount -3
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::configureSubCmd
#------------------------------------------------------------------------------
proc tablelist::configureSubCmd {win argList} {
    variable configSpecs
    return [mwutil::configureSubCmd $win configSpecs tablelist::doConfig \
	    tablelist::doCget $argList]
}

#------------------------------------------------------------------------------
# tablelist::containingSubCmd
#------------------------------------------------------------------------------
proc tablelist::containingSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win containing y"
    }

    set y [format "%d" [lindex $argList 0]]
    synchronize $win
    displayItems $win
    return [containingRow $win $y]
}

#------------------------------------------------------------------------------
# tablelist::containingcellSubCmd
#------------------------------------------------------------------------------
proc tablelist::containingcellSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win containingcell x y"
    }

    set x [format "%d" [lindex $argList 0]]
    set y [format "%d" [lindex $argList 1]]
    synchronize $win
    displayItems $win
    return [containingRow $win $y],[containingCol $win $x]
}

#------------------------------------------------------------------------------
# tablelist::containingcolumnSubCmd
#------------------------------------------------------------------------------
proc tablelist::containingcolumnSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win containingcolumn x"
    }

    set x [format "%d" [lindex $argList 0]]
    synchronize $win
    displayItems $win
    return [containingCol $win $x]
}

#------------------------------------------------------------------------------
# tablelist::cornerlabelpathSubCmd
#------------------------------------------------------------------------------
proc tablelist::cornerlabelpathSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win cornerlabelpath"
    }

    upvar ::tablelist::ns${win}::data data
    return $data(cornerLbl)
}

#------------------------------------------------------------------------------
# tablelist::cornerpathSubCmd
#------------------------------------------------------------------------------
proc tablelist::cornerpathSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win cornerpath"
    }

    upvar ::tablelist::ns${win}::data data
    return $data(corner)
}

#------------------------------------------------------------------------------
# tablelist::curcellselectionSubCmd
#------------------------------------------------------------------------------
proc tablelist::curcellselectionSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount > 1} {
	mwutil::wrongNumArgs "$win curcellselection\
			      ?-all|-nonhidden||-viewable?"
    }

    if {$argCount == 0} {
	set constraint 0
    } else {
	variable curSelOpts
	set opt [mwutil::fullOpt "option" [lindex $argList 0] $curSelOpts]
	set constraint [lsearch -exact $curSelOpts $opt]
    }
    

    synchronize $win
    displayItems $win
    return [curCellSelection $win 0 $constraint]
}

#------------------------------------------------------------------------------
# tablelist::curselectionSubCmd
#------------------------------------------------------------------------------
proc tablelist::curselectionSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount > 1} {
	mwutil::wrongNumArgs "$win curselection\
			      ?-all|-nonhidden||-viewable?"
    }

    if {$argCount == 0} {
	set constraint 0
    } else {
	variable curSelOpts
	set opt [mwutil::fullOpt "option" [lindex $argList 0] $curSelOpts]
	set constraint [lsearch -exact $curSelOpts $opt]
    }

    synchronize $win
    displayItems $win
    return [curSelection $win $constraint]
}

#------------------------------------------------------------------------------
# tablelist::deleteSubCmd
#------------------------------------------------------------------------------
proc tablelist::deleteSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win delete firstIndex lastIndex" \
			     "$win delete indexList"
    }

    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled)} {
	return ""
    }

    synchronize $win
    displayItems $win
    set first [lindex $argList 0]

    if {$argCount == 1} {
	if {[llength $first] == 1} {			;# just to save time
	    set index [rowIndex $win [lindex $first 0] 0]
	    return [deleteRows $win $index $index $data(hasListVar)]
	} elseif {$data(itemCount) == 0} {		;# no items present
	    return ""
	} else {					;# a bit more work
	    #
	    # Sort the numerical equivalents of the
	    # specified indices in decreasing order
	    #
	    set indexList {}
	    foreach elem $first {
		set index [rowIndex $win $elem 0]
		if {$index < 0} {
		    set index 0
		} elseif {$index > $data(lastRow)} {
		    set index $data(lastRow)
		}
		lappend indexList $index
	    }
	    set indexList [lsort -integer -decreasing $indexList]

	    #
	    # Traverse the sorted index list and ignore any duplicates
	    #
	    set prevIndex -1
	    foreach index $indexList {
		if {$index != $prevIndex} {
		    deleteRows $win $index $index $data(hasListVar)
		    set prevIndex $index
		}
	    }
	    return ""
	}
    } else {
	set first [rowIndex $win $first 0]
	set last [rowIndex $win [lindex $argList 1] 0]
	return [deleteRows $win $first $last $data(hasListVar)]
    }
}

#------------------------------------------------------------------------------
# tablelist::deletecolumnsSubCmd
#------------------------------------------------------------------------------
proc tablelist::deletecolumnsSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs \
		"$win deletecolumns firstColumnIndex lastColumnIndex" \
		"$win deletecolumns columnIndexList"
    }

    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled)} {
	return ""
    }

    synchronize $win
    displayItems $win
    set first [lindex $argList 0]

    if {$argCount == 1} {
	if {[llength $first] == 1} {			;# just to save time
	    set col [colIndex $win [lindex $first 0] 1]
	    set selCells [curCellSelection $win]
	    deleteCols $win $col $col selCells
	    redisplay $win 0 $selCells
	} elseif {$data(colCount) == 0} {		;# no columns present
	    return ""
	} else {					;# a bit more work
	    #
	    # Sort the numerical equivalents of the
	    # specified column indices in decreasing order
	    #
	    set colList {}
	    foreach elem $first {
		lappend colList [colIndex $win $elem 1]
	    }
	    set colList [lsort -integer -decreasing $colList]

	    #
	    # Traverse the sorted column index list and ignore any duplicates
	    #
	    set selCells [curCellSelection $win]
	    set deleted 0
	    set prevCol -1
	    foreach col $colList {
		if {$col != $prevCol} {
		    deleteCols $win $col $col selCells
		    set deleted 1
		    set prevCol $col
		}
	    }
	    if {$deleted} {
		redisplay $win 0 $selCells
	    }
	}
    } else {
	set first [colIndex $win $first 1]
	set last [colIndex $win [lindex $argList 1] 1]
	if {$first <= $last} {
	    set selCells [curCellSelection $win]
	    deleteCols $win $first $last selCells
	    redisplay $win 0 $selCells
	}
    }

    updateViewWhenIdle $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::depthSubCmd
#------------------------------------------------------------------------------
proc tablelist::depthSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win depth nodeIndex"
    }

    synchronize $win
    set key [nodeIndexToKey $win [lindex $argList 0]]
    return [depth $win $key]
}

#------------------------------------------------------------------------------
# tablelist::descendantcountSubCmd
#------------------------------------------------------------------------------
proc tablelist::descendantcountSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win descendantcount nodeIndex"
    }

    synchronize $win
    set key [nodeIndexToKey $win [lindex $argList 0]]
    return [descCount $win $key]
}

#------------------------------------------------------------------------------
# tablelist::dicttoitemSubCmd
#------------------------------------------------------------------------------
proc tablelist::dicttoitemSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win dicttoitem dictionary"
    }

    set origDict [lindex $argList 0]
    set newDict {}
    dict for {key val} $origDict {
	set col [colIndex $win $key 1]
	dict set newDict $col $val
    }

    set item {}
    upvar ::tablelist::ns${win}::data data
    for {set col 0} {$col < $data(colCount)} {incr col} {
	if {[dict exists $newDict $col]} {
	    set elem [dict get $newDict $col]
	} else {
	    set elem ""
	}
	lappend item $elem
    }

    return $item
}

#------------------------------------------------------------------------------
# tablelist::editcellSubCmd
#------------------------------------------------------------------------------
proc tablelist::editcellSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win editcell cellIndex"
    }

    synchronize $win
    displayItems $win
    foreach {row col} [cellIndex $win [lindex $argList 0] 1] {}
    return [doEditCell $win $row $col 0]
}

#------------------------------------------------------------------------------
# tablelist::editinfoSubCmd
#------------------------------------------------------------------------------
proc tablelist::editinfoSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win editinfo"
    }

    upvar ::tablelist::ns${win}::data data
    return [list $data(editKey) $data(editRow) $data(editCol)]
}

#------------------------------------------------------------------------------
# tablelist::editwinpathSubCmd
#------------------------------------------------------------------------------
proc tablelist::editwinpathSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win editwinpath"
    }

    upvar ::tablelist::ns${win}::data data
    if {[winfo exists $data(bodyFrmEd)]} {
	return $data(bodyFrmEd)
    } else {
	return ""
    }
}

#------------------------------------------------------------------------------
# tablelist::editwintagSubCmd
#------------------------------------------------------------------------------
proc tablelist::editwintagSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win editwintag"
    }

    upvar ::tablelist::ns${win}::data data
    return $data(editwinTag)
}

#------------------------------------------------------------------------------
# tablelist::entrypathSubCmd
#------------------------------------------------------------------------------
proc tablelist::entrypathSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win entrypath"
    }

    upvar ::tablelist::ns${win}::data data
    if {[winfo exists $data(bodyFrmEd)]} {
	set class [winfo class $data(bodyFrmEd)]
	if {[regexp {^(Mentry|T?Checkbutton|T?Menubutton)$} $class]} {
	    return ""
	} else {
	    return $data(editFocus)
	}
    } else {
	return ""
    }
}

#------------------------------------------------------------------------------
# tablelist::expandSubCmd
#------------------------------------------------------------------------------
proc tablelist::expandSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win expand index ?-fully|-partly?"
    }

    synchronize $win
    displayItems $win
    set index [rowIndex $win [lindex $argList 0] 0 1]

    if {$argCount == 1} {
	set fullExpansion 1
    } else {
	variable expCollOpts
	set opt [mwutil::fullOpt "option" [lindex $argList 1] $expCollOpts]
	set fullExpansion [expr {[string compare $opt "-fully"] == 0}]
    }

    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $index]
    set col $data(treeCol)
    if {![info exists data($key,$col-indent)] ||
	[string match "*indented*" $data($key,$col-indent)]} {
	return ""
    }

    set callerProc [lindex [info level -1] 0]
    if {[string compare $callerProc "doRowConfig"] != 0 &&
	[string length $data(-expandcommand)] != 0} {
	set data(keyBeingExpanded) $key
	uplevel #0 $data(-expandcommand) [list $win $index]
	set data(keyBeingExpanded) ""
    }

    #
    # Set the indentation image to the indented or expanded one
    #
    set childCount [llength $data($key-children)]
    set state [expr {($childCount == 0) ? "indented" : "expanded"}]
    set data($key,$col-indent) [strMap \
	[list "collapsed" $state "expanded" $state] $data($key,$col-indent)]
    if {[string compare $state "indented"] == 0} {
	set data($key,$col-indent) [strMap \
	    {"Act" "" "Sel" ""} $data($key,$col-indent)]
    }
    if {[winfo exists $data(body).ind_$key,$col]} {
	$data(body).ind_$key,$col configure -image $data($key,$col-indent)
    }

    #
    # Unelide the children if appropriate and
    # invoke this procedure recursively on them
    #
    set isViewable [expr {![info exists data($key-elide)] &&
			  ![info exists data($key-hide)]}]
    foreach childKey $data($key-children) {
	set childRow [keyToRow $win $childKey]
	if {$isViewable} {
	    doRowConfig $childRow $win -elide 0
	}
	if {$fullExpansion} {
	    expandSubCmd $win [list $childRow -fully]
	} elseif {[string match "*expanded*" $data($childKey,$col-indent)]} {
	    expandSubCmd $win [list $childRow -partly]
	}
    }

    if {![string match "expand*SubCmd" $callerProc]} {
	adjustElidedText $win
	redisplayVisibleItems $win
	makeStripes $win
	adjustSepsWhenIdle $win
	updateVScrlbarWhenIdle $win
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::expandallSubCmd
#------------------------------------------------------------------------------
proc tablelist::expandallSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount > 1} {
	mwutil::wrongNumArgs "$win expandall ?-fully|-partly?"
    }

    if {$argCount == 0} {
	set fullExpansion 1
    } else {
	variable expCollOpts
	set opt [mwutil::fullOpt "option" [lindex $argList 0] $expCollOpts]
	set fullExpansion [expr {[string compare $opt "-fully"] == 0}]
    }

    synchronize $win
    displayItems $win

    upvar ::tablelist::ns${win}::data data
    set col $data(treeCol)

    foreach key $data(root-children) {
	if {![info exists data($key,$col-indent)] ||
	    [string match "*indented*" $data($key,$col-indent)]} {
	    continue
	}

	if {[string length $data(-expandcommand)] != 0} {
	    set data(keyBeingExpanded) $key
	    uplevel #0 $data(-expandcommand) [list $win [keyToRow $win $key]]
	    set data(keyBeingExpanded) ""
	}

	#
	# Set the indentation image to the indented or expanded one
	#
	set childCount [llength $data($key-children)]
	set state [expr {($childCount == 0) ? "indented" : "expanded"}]
	set data($key,$col-indent) [strMap \
	    [list "collapsed" $state "expanded" $state] $data($key,$col-indent)]
	if {[string compare $state "indented"] == 0} {
	    set data($key,$col-indent) [strMap \
		{"Act" "" "Sel" ""} $data($key,$col-indent)]
	}
	if {[winfo exists $data(body).ind_$key,$col]} {
	    $data(body).ind_$key,$col configure -image $data($key,$col-indent)
	}

	#
	# Unelide the children and invoke expandSubCmd on them
	#
	foreach childKey $data($key-children) {
	    set childRow [keyToRow $win $childKey]
	    doRowConfig $childRow $win -elide 0
	    if {$fullExpansion} {
		expandSubCmd $win [list $childRow -fully]
	    } elseif {[string match "*expanded*" \
		       $data($childKey,$col-indent)]} {
		expandSubCmd $win [list $childRow -partly]
	    }
	}
    }

    adjustElidedText $win
    redisplayVisibleItems $win
    makeStripes $win
    adjustSepsWhenIdle $win
    updateVScrlbarWhenIdle $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::expandedkeysSubCmd
#------------------------------------------------------------------------------
proc tablelist::expandedkeysSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win expandedkeys"
    }

    upvar ::tablelist::ns${win}::data data
    set result {}
    foreach name [array names data "*,$data(treeCol)-indent"] {
	if {[string match "tablelist_*_expanded*Img*" $data($name)]} {
	    set commaPos [string first "," $name]
	    lappend result [string range $name 0 [expr {$commaPos - 1}]]
	}
    }
    return $result
}

#------------------------------------------------------------------------------
# tablelist::fillcolumnSubCmd
#------------------------------------------------------------------------------
proc tablelist::fillcolumnSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win fillcolumn columnIndex text"
    }

    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled)} {
	return ""
    }

    synchronize $win
    displayItems $win
    set colIdx [colIndex $win [lindex $argList 0] 1]
    set text [lindex $argList 1]

    #
    # Update the item list
    #
    set newItemList {}
    foreach item $data(itemList) {
	set item [lreplace $item $colIdx $colIdx $text]
	lappend newItemList $item
    }
    set data(itemList) $newItemList

    #
    # Update the list variable if present
    #
    condUpdateListVar $win

    #
    # Adjust the columns and make sure the specified
    # column will be redisplayed at idle time
    #
    adjustColumns $win $colIdx 1
    redisplayColWhenIdle $win $colIdx
    updateViewWhenIdle $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::findcolumnnameSubCmd
#------------------------------------------------------------------------------
proc tablelist::findcolumnnameSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win findcolumnname name"
    }

    set name [lindex $argList 0]
    set nameIsEmpty [expr {[string length $name] == 0}]

    upvar ::tablelist::ns${win}::data data
    for {set col 0} {$col < $data(colCount)} {incr col} {
	set hasName [info exists data($col-name)]
	if {($hasName && [string compare $name $data($col-name)] == 0) ||
	    (!$hasName && $nameIsEmpty)} {
	    return $col
	}
    }

    return -1
}

#------------------------------------------------------------------------------
# tablelist::findrownameSubCmd
#------------------------------------------------------------------------------
proc tablelist::findrownameSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1} {
	mwutil::wrongNumArgs "$win findrowname name ?-descend?\
			      ?-parent nodeIndex?"
    }

    synchronize $win
    set name [lindex $argList 0]
    set nameIsEmpty [expr {[string length $name] == 0}]

    #
    # Initialize some processing parameters
    #
    set parentKey root
    set descend 0						;# boolean

    #
    # Parse the argument list
    #
    variable findOpts
    for {set n 1} {$n < $argCount} {incr n} {
	set arg [lindex $argList $n]
	set opt [mwutil::fullOpt "option" $arg $findOpts]
	switch -- $opt {
	    -descend { set descend 1 }
	    -parent {
		if {$n == $argCount - 1} {
		    return -code error "value for \"$arg\" missing"
		}

		incr n
		set parentKey [nodeIndexToKey $win [lindex $argList $n]]
	    }
	}
    }

    upvar ::tablelist::ns${win}::data data
    set childCount [llength $data($parentKey-children)]
    if {$childCount == 0} {
	return -1
    }

    if {$descend} {
	set fromChildKey [lindex $data($parentKey-children) 0]
	set fromRow [keyToRow $win $fromChildKey]
	set toRow [nodeRow $win $parentKey end]
	for {set row $fromRow} {$row < $toRow} {incr row} {
	    set key [lindex $data(keyList) $row]
	    set hasName [info exists data($key-name)]
	    if {($hasName && [string compare $name $data($key-name)] == 0) ||
		(!$hasName && $nameIsEmpty)} {
		return $row
	    }
	}
    } else {
	for {set childIdx 0} {$childIdx < $childCount} {incr childIdx} {
	    set key [lindex $data($parentKey-children) $childIdx]
	    set hasName [info exists data($key-name)]
	    if {($hasName && [string compare $name $data($key-name)] == 0) ||
		(!$hasName && $nameIsEmpty)} {
		return [keyToRow $win $key]
	    }
	}
    }

    return -1
}

#------------------------------------------------------------------------------
# tablelist::finisheditingSubCmd
#------------------------------------------------------------------------------
proc tablelist::finisheditingSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win finishediting"
    }

    synchronize $win
    return [doFinishEditing $win]
}

#------------------------------------------------------------------------------
# tablelist::formatinfoSubCmd
#------------------------------------------------------------------------------
proc tablelist::formatinfoSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win formatinfo"
    }

    upvar ::tablelist::ns${win}::data data
    return [list $data(fmtKey) $data(fmtRow) $data(fmtCol)]
}

#------------------------------------------------------------------------------
# tablelist::getSubCmd
#------------------------------------------------------------------------------
proc tablelist::getSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win get firstIndex lastIndex" \
			     "$win get indexList"
    }

    synchronize $win
    set first [lindex $argList 0]

    #
    # Get the specified items from the internal list
    #
    upvar ::tablelist::ns${win}::data data
    set result {}
    if {$argCount == 1} {
	foreach elem $first {
	    set row [rowIndex $win $elem 0]
	    if {$row >= 0 && $row < $data(itemCount)} {
		set item [lindex $data(itemList) $row]
		lappend result [lrange $item 0 $data(lastCol)]
	    }
	}

	if {[llength $first] == 1} {
	    return [lindex $result 0]
	} else {
	    return $result
	}
    } else {
	set first [rowIndex $win $first 0]
	set last [rowIndex $win [lindex $argList 1] 0]
	if {$last < $first} {
	    return {}
	}

	#
	# Adjust the range to fit within the existing items
	#
	if {$first < 0} {
	    set first 0
	}
	if {$last > $data(lastRow)} {
	    set last $data(lastRow)
	}

	foreach item [lrange $data(itemList) $first $last] {
	    lappend result [lrange $item 0 $data(lastCol)]
	}
	return $result
    }
}

#------------------------------------------------------------------------------
# tablelist::getcellsSubCmd
#------------------------------------------------------------------------------
proc tablelist::getcellsSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win getcells firstCellIndex lastCellIndex" \
			     "$win getcells cellIndexList"
    }

    synchronize $win
    set first [lindex $argList 0]

    #
    # Get the specified elements from the internal list
    #
    upvar ::tablelist::ns${win}::data data
    set result {}
    if {$argCount == 1} {
	foreach elem $first {
	    foreach {row col} [cellIndex $win $elem 1] {}
	    lappend result [lindex [lindex $data(itemList) $row] $col]
	}

	if {[llength $first] == 1} {
	    return [lindex $result 0]
	} else {
	    return $result
	}
    } else {
	foreach {firstRow firstCol} [cellIndex $win $first 1] {}
	foreach {lastRow lastCol} [cellIndex $win [lindex $argList 1] 1] {}

	foreach item [lrange $data(itemList) $firstRow $lastRow] {
	    foreach elem [lrange $item $firstCol $lastCol] {
		lappend result $elem
	    }
	}
	return $result
    }
}

#------------------------------------------------------------------------------
# tablelist::getcolumnsSubCmd
#------------------------------------------------------------------------------
proc tablelist::getcolumnsSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs \
		"$win getcolumns firstColumnIndex lastColumnIndex" \
		"$win getcolumns columnIndexList"
    }

    synchronize $win
    set first [lindex $argList 0]

    #
    # Get the specified columns from the internal list
    #
    upvar ::tablelist::ns${win}::data data
    set result {}
    if {$argCount == 1} {
	foreach elem $first {
	    set col [colIndex $win $elem 1]
	    set colResult {}
	    foreach item $data(itemList) {
		lappend colResult [lindex $item $col]
	    }
	    lappend result $colResult
	}

	if {[llength $first] == 1} {
	    return [lindex $result 0]
	} else {
	    return $result
	}
    } else {
	set first [colIndex $win $first 1]
	set last [colIndex $win [lindex $argList 1] 1]

	for {set col $first} {$col <= $last} {incr col} {
	    set colResult {}
	    foreach item $data(itemList) {
		lappend colResult [lindex $item $col]
	    }
	    lappend result $colResult
	}
	return $result
    }
}

#------------------------------------------------------------------------------
# tablelist::getformattedSubCmd
#------------------------------------------------------------------------------
proc tablelist::getformattedSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win getformatted firstIndex lastIndex" \
			     "$win getformatted indexList"
    }

    synchronize $win
    set first [lindex $argList 0]

    #
    # Get the specified items from the internal list
    #
    upvar ::tablelist::ns${win}::data data
    set result {}
    if {$argCount == 1} {
	foreach elem $first {
	    set row [rowIndex $win $elem 0]
	    if {$row >= 0 && $row < $data(itemCount)} {
		set item [lindex $data(itemList) $row]
		set key [lindex $item end]
		set item [lrange $item 0 $data(lastCol)]
		lappend result [formatItem $win $key $row $item]
	    }
	}

	if {[llength $first] == 1} {
	    return [lindex $result 0]
	} else {
	    return $result
	}
    } else {
	set first [rowIndex $win $first 0]
	set last [rowIndex $win [lindex $argList 1] 0]
	if {$last < $first} {
	    return {}
	}

	#
	# Adjust the range to fit within the existing items
	#
	if {$first < 0} {
	    set first 0
	}
	if {$last > $data(lastRow)} {
	    set last $data(lastRow)
	}

	set row $first
	foreach item [lrange $data(itemList) $first $last] {
	    set key [lindex $item end]
	    set item [lrange $item 0 $data(lastCol)]
	    lappend result [formatItem $win $key $row $item]
	    incr row
	}
	return $result
    }
}

#------------------------------------------------------------------------------
# tablelist::getformattedcellsSubCmd
#------------------------------------------------------------------------------
proc tablelist::getformattedcellsSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs \
		"$win getformattedcells firstCellIndex lastCellIndex" \
		"$win getformattedcells cellIndexList"
    }

    synchronize $win
    set first [lindex $argList 0]

    #
    # Get the specified elements from the internal list
    #
    upvar ::tablelist::ns${win}::data data
    set result {}
    if {$argCount == 1} {
	foreach elem $first {
	    foreach {row col} [cellIndex $win $elem 1] {}
	    set item [lindex $data(itemList) $row]
	    set key [lindex $item end]
	    set text [lindex $item $col]
	    if {[lindex $data(fmtCmdFlagList) $col]} {
		set text [formatElem $win $key $row $col $text]
	    }
	    lappend result $text
	}

	if {[llength $first] == 1} {
	    return [lindex $result 0]
	} else {
	    return $result
	}
    } else {
	foreach {firstRow firstCol} [cellIndex $win $first 1] {}
	foreach {lastRow lastCol} [cellIndex $win [lindex $argList 1] 1] {}

	set row $firstRow
	foreach item [lrange $data(itemList) $firstRow $lastRow] {
	    set key [lindex $item end]
	    set col $firstCol
	    foreach text [lrange $item $firstCol $lastCol] {
		if {[lindex $data(fmtCmdFlagList) $col]} {
		    set text [formatElem $win $key $row $col $text]
		}
		lappend result $text
		incr col
	    }
	    incr row
	}
	return $result
    }
}

#------------------------------------------------------------------------------
# tablelist::getformattedcolumnsSubCmd
#------------------------------------------------------------------------------
proc tablelist::getformattedcolumnsSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs \
		"$win getformattedcolumns firstColumnIndex lastColumnIndex" \
		"$win getformattedcolumns columnIndexList"
    }

    synchronize $win
    set first [lindex $argList 0]

    #
    # Get the specified columns from the internal list
    #
    upvar ::tablelist::ns${win}::data data
    set result {}
    if {$argCount == 1} {
	foreach elem $first {
	    set col [colIndex $win $elem 1]
	    set fmtCmdFlag [lindex $data(fmtCmdFlagList) $col]
	    set colResult {}
	    set row 0
	    foreach item $data(itemList) {
		set key [lindex $item end]
		set text [lindex $item $col]
		if {$fmtCmdFlag} {
		    set text [formatElem $win $key $row $col $text]
		}
		lappend colResult $text
		incr row
	    }
	    lappend result $colResult
	}

	if {[llength $first] == 1} {
	    return [lindex $result 0]
	} else {
	    return $result
	}
    } else {
	set first [colIndex $win $first 1]
	set last [colIndex $win [lindex $argList 1] 1]

	for {set col $first} {$col <= $last} {incr col} {
	    set fmtCmdFlag [lindex $data(fmtCmdFlagList) $col]
	    set colResult {}
	    set row 0
	    foreach item $data(itemList) {
		set key [lindex $item end]
		set text [lindex $item $col]
		if {$fmtCmdFlag} {
		    set text [formatElem $win $key $row $col $text]
		}
		lappend colResult $text
		incr row
	    }
	    lappend result $colResult
	}
	return $result
    }
}

#------------------------------------------------------------------------------
# tablelist::getfullkeysSubCmd
#------------------------------------------------------------------------------
proc tablelist::getfullkeysSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win getfullkeys firstIndex lastIndex" \
			     "$win getfullkeys indexList"
    }

    synchronize $win
    set first [lindex $argList 0]

    #
    # Get the specified keys from the internal list
    #
    upvar ::tablelist::ns${win}::data data
    set result {}
    if {$argCount == 1} {
	foreach elem $first {
	    set row [rowIndex $win $elem 0]
	    if {$row >= 0 && $row < $data(itemCount)} {
		lappend result [lindex [lindex $data(itemList) $row] end]
	    }
	}

	if {[llength $first] == 1} {
	    return [lindex $result 0]
	} else {
	    return $result
	}
    } else {
	set first [rowIndex $win $first 0]
	set last [rowIndex $win [lindex $argList 1] 0]
	if {$last < $first} {
	    return {}
	}

	#
	# Adjust the range to fit within the existing items
	#
	if {$first < 0} {
	    set first 0
	}
	if {$last > $data(lastRow)} {
	    set last $data(lastRow)
	}

	foreach item [lrange $data(itemList) $first $last] {
	    lappend result [lindex $item end]
	}
	return $result
    }
}

#------------------------------------------------------------------------------
# tablelist::getkeysSubCmd
#------------------------------------------------------------------------------
proc tablelist::getkeysSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win getkeys firstIndex lastIndex" \
			     "$win getkeys indexList"
    }

    synchronize $win
    set first [lindex $argList 0]

    #
    # Get the specified keys from the internal list
    #
    upvar ::tablelist::ns${win}::data data
    set result {}
    if {$argCount == 1} {
	foreach elem $first {
	    set row [rowIndex $win $elem 0]
	    if {$row >= 0 && $row < $data(itemCount)} {
		set item [lindex $data(itemList) $row]
		lappend result [string range [lindex $item end] 1 end]
	    }
	}

	if {[llength $first] == 1} {
	    return [lindex $result 0]
	} else {
	    return $result
	}
    } else {
	set first [rowIndex $win $first 0]
	set last [rowIndex $win [lindex $argList 1] 0]
	if {$last < $first} {
	    return {}
	}

	#
	# Adjust the range to fit within the existing items
	#
	if {$first < 0} {
	    set first 0
	}
	if {$last > $data(lastRow)} {
	    set last $data(lastRow)
	}

	foreach item [lrange $data(itemList) $first $last] {
	    lappend result [string range [lindex $item end] 1 end]
	}
	return $result
    }
}

#------------------------------------------------------------------------------
# tablelist::hasattribSubCmd
#------------------------------------------------------------------------------
proc tablelist::hasattribSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win hasattrib name"
    }

    return [mwutil::hasattribSubCmd $win "widget" [lindex $argList 0]]
}

#------------------------------------------------------------------------------
# tablelist::hascellattribSubCmd
#------------------------------------------------------------------------------
proc tablelist::hascellattribSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win hascellattrib cellIndex name"
    }

    synchronize $win
    foreach {row col} [cellIndex $win [lindex $argList 0] 1] {}
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    return [mwutil::hasattribSubCmd $win $key,$col [lindex $argList 1]]
}

#------------------------------------------------------------------------------
# tablelist::hascolumnattribSubCmd
#------------------------------------------------------------------------------
proc tablelist::hascolumnattribSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win hascolumnattrib columnIndex name"
    }

    set col [colIndex $win [lindex $argList 0] 1]
    return [mwutil::hasattribSubCmd $win $col [lindex $argList 1]]
}

#------------------------------------------------------------------------------
# tablelist::hasrowattribSubCmd
#------------------------------------------------------------------------------
proc tablelist::hasrowattribSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win hasrowattrib index name"
    }

    synchronize $win
    set row [rowIndex $win [lindex $argList 0] 0 1]
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    return [mwutil::hasattribSubCmd $win $key [lindex $argList 1]]
}

#------------------------------------------------------------------------------
# tablelist::hidetargetmarkSubCmd
#------------------------------------------------------------------------------
proc tablelist::hidetargetmarkSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win hidetargetmark"
    }

    upvar ::tablelist::ns${win}::data data
    place forget $data(rowGap)
    return ""
}

#------------------------------------------------------------------------------
# tablelist::imagelabelpathSubCmd
#------------------------------------------------------------------------------
proc tablelist::imagelabelpathSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win imagelabelpath cellIndex"
    }

    synchronize $win
    foreach {row col} [cellIndex $win [lindex $argList 0] 1] {}
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    set w $data(body).img_$key,$col
    if {[winfo exists $w]} {
	return $w
    } else {
	return ""
    }
}

#------------------------------------------------------------------------------
# tablelist::indexSubCmd
#------------------------------------------------------------------------------
proc tablelist::indexSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win index index"
    }

    synchronize $win
    return [rowIndex $win [lindex $argList 0] 1]
}

#------------------------------------------------------------------------------
# tablelist::insertSubCmd
#------------------------------------------------------------------------------
proc tablelist::insertSubCmd {win argList} {
    if {[llength $argList] < 1} {
	mwutil::wrongNumArgs "$win insert index ?item item ...?"
    }

    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled)} {
	return ""
    }

    synchronize $win
    set index [rowIndex $win [lindex $argList 0] 1]
    return [insertRows $win $index [lrange $argList 1 end] \
	    $data(hasListVar) root $index]
}

#------------------------------------------------------------------------------
# tablelist::insertchildlistSubCmd
#------------------------------------------------------------------------------
proc tablelist::insertchildlistSubCmd {win argList} {
    if {[llength $argList] != 3} {
	mwutil::wrongNumArgs "$win insertchildlist parentNodeIndex childIndex\
			      itemList"
    }

    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled)} {
	return ""
    }

    synchronize $win
    set parentKey [nodeIndexToKey $win [lindex $argList 0]]
    set childIdx [lindex $argList 1]
    set listIdx [nodeRow $win $parentKey $childIdx]
    set itemList [lindex $argList 2]
    set result [insertRows $win $listIdx $itemList $data(hasListVar) \
		$parentKey $childIdx]

    if {$data(colCount) == 0} {
	return $result
    }

    displayItems $win
    set treeCol $data(treeCol)
    set treeStyle $data(-treestyle)

    #
    # Mark the parent item as expanded if it was just indented
    #
    set depth [depth $win $parentKey]
    if {[info exists data($parentKey,$treeCol-indent)] &&
	[string compare $data($parentKey,$treeCol-indent) \
	 tablelist_${treeStyle}_indentedImg$depth] == 0} {
	set data($parentKey,$treeCol-indent) \
	    tablelist_${treeStyle}_expandedImg$depth
	if {[winfo exists $data(body).ind_$parentKey,$treeCol]} {
	    $data(body).ind_$parentKey,$treeCol configure -image \
		$data($parentKey,$treeCol-indent)
	}
    }

    #
    # Elide the new items if the parent is collapsed or non-viewable
    #
    set itemCount [llength $itemList]
    if {[string compare $parentKey $data(keyBeingExpanded)] != 0 &&
	(([info exists data($parentKey,$treeCol-indent)] && \
	  [string compare $data($parentKey,$treeCol-indent) \
	   tablelist_${treeStyle}_collapsedImg$depth] == 0) || \
	 [info exists data($parentKey-elide)] || \
	 [info exists data($parentKey-hide)])} {
	for {set n 0; set row $listIdx} {$n < $itemCount} {incr n; incr row} {
	    doRowConfig $row $win -elide 1
	}
    }

    #
    # Mark the new items as indented
    #
    incr depth
    variable maxIndentDepths
    if {$depth > $maxIndentDepths($treeStyle)} {
	createTreeImgs $treeStyle $depth
	set maxIndentDepths($treeStyle) $depth
    }
    for {set n 0; set row $listIdx} {$n < $itemCount} {incr n; incr row} {
	doCellConfig $row $treeCol $win -indent \
		     tablelist_${treeStyle}_indentedImg$depth
    }

    return $result
}

#------------------------------------------------------------------------------
# tablelist::insertchildrenSubCmd
#------------------------------------------------------------------------------
proc tablelist::insertchildrenSubCmd {win argList} {
    if {[llength $argList] < 2} {
	mwutil::wrongNumArgs "$win insertchildren parentNodeIndex childIndex\
			      ?item item ...?"
    }

    return [insertchildlistSubCmd $win [list [lindex $argList 0] \
	    [lindex $argList 1] [lrange $argList 2 end]]]
}

#------------------------------------------------------------------------------
# tablelist::insertcolumnlistSubCmd
#------------------------------------------------------------------------------
proc tablelist::insertcolumnlistSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win insertcolumnlist columnIndex columnList"
    }

    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled)} {
	return ""
    }

    synchronize $win
    displayItems $win
    set arg0 [lindex $argList 0]
    if {[string first $arg0 "end"] == 0 || $arg0 == $data(colCount)} {
	set col $data(colCount)
    } else {
	set col [colIndex $win $arg0 1]
    }

    return [insertCols $win $col [lindex $argList 1]]
}

#------------------------------------------------------------------------------
# tablelist::insertcolumnsSubCmd
#------------------------------------------------------------------------------
proc tablelist::insertcolumnsSubCmd {win argList} {
    if {[llength $argList] < 1} {
	mwutil::wrongNumArgs "$win insertcolumns columnIndex\
		?width title ?alignment? width title ?alignment? ...?"
    }

    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled)} {
	return ""
    }

    synchronize $win
    displayItems $win
    set arg0 [lindex $argList 0]
    if {[string first $arg0 "end"] == 0 || $arg0 == $data(colCount)} {
	set col $data(colCount)
    } else {
	set col [colIndex $win $arg0 1]
    }

    return [insertCols $win $col [lrange $argList 1 end]]
}

#------------------------------------------------------------------------------
# tablelist::insertlistSubCmd
#------------------------------------------------------------------------------
proc tablelist::insertlistSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win insertlist index itemList"
    }

    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled)} {
	return ""
    }

    synchronize $win
    set index [rowIndex $win [lindex $argList 0] 1]
    return [insertRows $win $index [lindex $argList 1] \
	    $data(hasListVar) root $index]
}

#------------------------------------------------------------------------------
# tablelist::iselemsnippedSubCmd
#------------------------------------------------------------------------------
proc tablelist::iselemsnippedSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win iselemsnipped cellIndex fullTextName"
    }

    synchronize $win
    foreach {row col} [cellIndex $win [lindex $argList 0] 1] {}
    set fullTextName [lindex $argList 1]
    upvar 2 $fullTextName fullText

    upvar ::tablelist::ns${win}::data data
    set item [lindex $data(itemList) $row]
    set key [lindex $item end]
    set fullText [lindex $item $col]
    if {[lindex $data(fmtCmdFlagList) $col]} {
	set fullText [formatElem $win $key $row $col $fullText]
    }
    if {[string match "*\t*" $fullText]} {
	set fullText [mapTabs $fullText]
    }

    set pixels [lindex $data(colList) [expr {2*$col}]]
    if {$pixels == 0} {				;# convention: dynamic width
	if {$data($col-maxPixels) > 0 &&
	    $data($col-reqPixels) > $data($col-maxPixels)} {
	    set pixels $data($col-maxPixels)
	}
    }
    if {$pixels == 0 || $data($col-wrap)} {
	return 0
    }

    set text $fullText
    getAuxData $win $key $col auxType auxWidth $pixels
    getIndentData $win $key $col indentWidth
    set cellFont [getCellFont $win $key $col]
    incr pixels $data($col-delta)

    if {[string match "*\n*" $text]} {
	set list [split $text "\n"]
	adjustMlElem $win list auxWidth indentWidth $cellFont $pixels "r" ""
	set text [join $list "\n"]
    } else {
	adjustElem $win text auxWidth indentWidth $cellFont $pixels "r" ""
    }

    return [expr {[string compare $text $fullText] != 0}]
}

#------------------------------------------------------------------------------
# tablelist::isexpandedSubCmd
#------------------------------------------------------------------------------
proc tablelist::isexpandedSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win isexpanded index"
    }

    synchronize $win
    set row [rowIndex $win [lindex $argList 0] 0]
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    set treeCol $data(treeCol)
    if {[info exists data($key,$treeCol-indent)]} {
	return [string match "*expanded*" $data($key,$treeCol-indent)]
    } else {
	return 0
    }
}

#------------------------------------------------------------------------------
# tablelist::istitlesnippedSubCmd
#------------------------------------------------------------------------------
proc tablelist::istitlesnippedSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win istitlesnipped columnIndex fullTextName"
    }

    set col [colIndex $win [lindex $argList 0] 1]
    set fullTextName [lindex $argList 1]
    upvar 2 $fullTextName fullText

    upvar ::tablelist::ns${win}::data data
    set fullText [lindex $data(-columns) [expr {3*$col + 1}]]
    return $data($col-isSnipped)
}

#------------------------------------------------------------------------------
# tablelist::isviewableSubCmd
#------------------------------------------------------------------------------
proc tablelist::isviewableSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win isviewable index"
    }

    synchronize $win
    set row [rowIndex $win [lindex $argList 0] 0 1]
    return [isRowViewable $win $row]
}

#------------------------------------------------------------------------------
# tablelist::itemlistvarSubCmd
#------------------------------------------------------------------------------
proc tablelist::itemlistvarSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win itemlistvar"
    }

    return ::tablelist::ns${win}::data(itemList)
}

#------------------------------------------------------------------------------
# tablelist::itemtodictSubCmd
#------------------------------------------------------------------------------
proc tablelist::itemtodictSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win itemtodict item"
    }

    set item [lindex $argList 0]
    set dictionary {}
    upvar ::tablelist::ns${win}::data data
    for {set col 0} {$col < $data(colCount)} {incr col} {
	if {[info exists data($col-name)]} {
	    set key $data($col-name)
	} else {
	    set key $col
	}
	dict set dictionary $key [lindex $item $col]
    }

    return $dictionary
}

#------------------------------------------------------------------------------
# tablelist::labelpathSubCmd
#------------------------------------------------------------------------------
proc tablelist::labelpathSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win labelpath columnIndex"
    }

    set col [colIndex $win [lindex $argList 0] 1]
    upvar ::tablelist::ns${win}::data data
    return $data(hdrTxtFrmLbl)$col
}

#------------------------------------------------------------------------------
# tablelist::labelsSubCmd
#------------------------------------------------------------------------------
proc tablelist::labelsSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win labels"
    }

    upvar ::tablelist::ns${win}::data data
    set labelList {}
    for {set col 0} {$col < $data(colCount)} {incr col} {
	lappend labelList $data(hdrTxtFrmLbl)$col
    }

    return $labelList
}

#------------------------------------------------------------------------------
# tablelist::labeltagSubCmd
#------------------------------------------------------------------------------
proc tablelist::labeltagSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win labeltag"
    }

    upvar ::tablelist::ns${win}::data data
    return $data(labelTag)
}

#------------------------------------------------------------------------------
# tablelist::moveSubCmd
#------------------------------------------------------------------------------
proc tablelist::moveSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 2 || $argCount > 3} {
	mwutil::wrongNumArgs \
		"$win move sourceIndex targetIndex" \
		"$win move sourceIndex targetParentNodeIndex targetChildIndex"
    }

    synchronize $win
    displayItems $win
    set source [rowIndex $win [lindex $argList 0] 0]
    if {$argCount == 2} {
	set target [rowIndex $win [lindex $argList 1] 1]
	return [moveRow $win $source $target]
    } else {
	set targetParentKey [nodeIndexToKey $win [lindex $argList 1]]
	set targetChildIdx [lindex $argList 2]
	return [moveNode $win $source $targetParentKey $targetChildIdx]
    }
}

#------------------------------------------------------------------------------
# tablelist::movecolumnSubCmd
#------------------------------------------------------------------------------
proc tablelist::movecolumnSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win movecolumn sourceColumnIndex\
			      targetColumnIndex"
    }

    synchronize $win
    displayItems $win
    set arg0 [lindex $argList 0]
    set source [colIndex $win $arg0 1]
    set arg1 [lindex $argList 1]
    upvar ::tablelist::ns${win}::data data
    if {[string first $arg1 "end"] == 0 || $arg1 == $data(colCount)} {
	set target $data(colCount)
    } else {
	set target [colIndex $win $arg1 1]
    }

    return [moveCol $win $source $target]
}

#------------------------------------------------------------------------------
# tablelist::nearestSubCmd
#------------------------------------------------------------------------------
proc tablelist::nearestSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win nearest y"
    }

    set y [format "%d" [lindex $argList 0]]
    synchronize $win
    displayItems $win
    return [rowIndex $win @0,$y 0]
}

#------------------------------------------------------------------------------
# tablelist::nearestcellSubCmd
#------------------------------------------------------------------------------
proc tablelist::nearestcellSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win nearestcell x y"
    }

    set x [format "%d" [lindex $argList 0]]
    set y [format "%d" [lindex $argList 1]]
    synchronize $win
    displayItems $win
    return [join [cellIndex $win @$x,$y 0] ","]
}

#------------------------------------------------------------------------------
# tablelist::nearestcolumnSubCmd
#------------------------------------------------------------------------------
proc tablelist::nearestcolumnSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win nearestcolumn x"
    }

    set x [format "%d" [lindex $argList 0]]
    return [colIndex $win @$x,0 0]
}

#------------------------------------------------------------------------------
# tablelist::noderowSubCmd
#------------------------------------------------------------------------------
proc tablelist::noderowSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win noderow parentNodeIndex childIndex"
    }

    synchronize $win
    set parentKey [nodeIndexToKey $win [lindex $argList 0]]
    set childIdx [lindex $argList 1]
    return [nodeRow $win $parentKey $childIdx]
}

#------------------------------------------------------------------------------
# tablelist::parentkeySubCmd
#------------------------------------------------------------------------------
proc tablelist::parentkeySubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win parentkey nodeIndex"
    }

    synchronize $win
    set key [nodeIndexToKey $win [lindex $argList 0]]
    upvar ::tablelist::ns${win}::data data
    return $data($key-parent)
}

#------------------------------------------------------------------------------
# tablelist::refreshsortingSubCmd
#------------------------------------------------------------------------------
proc tablelist::refreshsortingSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount > 1} {
	mwutil::wrongNumArgs "$win refreshsorting ?parentNodeIndex?"
    }

    synchronize $win
    displayItems $win
    if {$argCount == 0} {
	set parentKey root
    } else {
	set parentKey [nodeIndexToKey $win [lindex $argList 0]]
    }

    upvar ::tablelist::ns${win}::data data
    set sortOrderList {}
    foreach col $data(sortColList) {
	lappend sortOrderList $data($col-sortOrder)
    }

    return [sortItems $win $parentKey $data(sortColList) $sortOrderList]
}

#------------------------------------------------------------------------------
# tablelist::rejectinputSubCmd
#------------------------------------------------------------------------------
proc tablelist::rejectinputSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win rejectinput"
    }

    upvar ::tablelist::ns${win}::data data
    set data(rejected) 1
    return ""
}

#------------------------------------------------------------------------------
# tablelist::resetsortinfoSubCmd
#------------------------------------------------------------------------------
proc tablelist::resetsortinfoSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win resetsortinfo"
    }

    upvar ::tablelist::ns${win}::data data

    foreach col $data(sortColList) {
	set data($col-sortRank) 0
	set data($col-sortOrder) ""
    }

    set whichWidths {}
    foreach col $data(arrowColList) {
	lappend whichWidths l$col
    }

    set data(sortColList) {}
    set data(arrowColList) {}
    set data(sortOrder) {}

    if {[llength $whichWidths] > 0} {
	synchronize $win
	displayItems $win
	adjustColumns $win $whichWidths 1
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::rowattribSubCmd
#------------------------------------------------------------------------------
proc tablelist::rowattribSubCmd {win argList} {
    if {[llength $argList] < 1} {
	mwutil::wrongNumArgs "$win rowattrib index ?name? ?value\
			      name value ...?"
    }

    synchronize $win
    set row [rowIndex $win [lindex $argList 0] 0 1]
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    return [mwutil::attribSubCmd $win $key [lrange $argList 1 end]]
}

#------------------------------------------------------------------------------
# tablelist::rowcgetSubCmd
#------------------------------------------------------------------------------
proc tablelist::rowcgetSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win rowcget index option"
    }

    synchronize $win
    set row [rowIndex $win [lindex $argList 0] 0 1]
    variable rowConfigSpecs
    set opt [mwutil::fullConfigOpt [lindex $argList 1] rowConfigSpecs]
    return [doRowCget $row $win $opt]
}

#------------------------------------------------------------------------------
# tablelist::rowconfigureSubCmd
#------------------------------------------------------------------------------
proc tablelist::rowconfigureSubCmd {win argList} {
    if {[llength $argList] < 1} {
	mwutil::wrongNumArgs "$win rowconfigure index ?option? ?value\
			      option value ...?"
    }

    synchronize $win
    displayItems $win
    variable rowConfigSpecs
    set row [rowIndex $win [lindex $argList 0] 0 1]
    return [mwutil::configureSubCmd $win rowConfigSpecs \
	    "tablelist::doRowConfig $row" "tablelist::doRowCget $row" \
	    [lrange $argList 1 end]]
}

#------------------------------------------------------------------------------
# tablelist::scanSubCmd
#------------------------------------------------------------------------------
proc tablelist::scanSubCmd {win argList} {
    if {[llength $argList] != 3} {
	mwutil::wrongNumArgs "$win scan mark|dragto x y"
    }

    set x [format "%d" [lindex $argList 1]]
    set y [format "%d" [lindex $argList 2]]
    variable scanOpts
    set opt [mwutil::fullOpt "option" [lindex $argList 0] $scanOpts]
    synchronize $win
    displayItems $win
    return [doScan $win $opt $x $y]
}

#------------------------------------------------------------------------------
# tablelist::searchcolumnSubCmd
#------------------------------------------------------------------------------
proc tablelist::searchcolumnSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 2} {
	mwutil::wrongNumArgs "$win searchcolumn columnIndex pattern ?options?"
    }

    synchronize $win
    set col [colIndex $win [lindex $argList 0] 1]
    set pattern [lindex $argList 1]

    #
    # Initialize some processing parameters
    #
    set mode -glob		;# possible values: -exact, -glob, -regexp
    set checkCmd ""
    set parentKey root
    set allMatches 0						;# boolean
    set backwards 0						;# boolean
    set descend 0						;# boolean
    set formatted 0						;# boolean
    set noCase 0						;# boolean
    set negated 0						;# boolean
    set numeric 0						;# boolean
    set gotStartRow 0						;# boolean

    #
    # Parse the argument list
    #
    variable searchOpts
    for {set n 2} {$n < $argCount} {incr n} {
	set arg [lindex $argList $n]
	set opt [mwutil::fullOpt "option" $arg $searchOpts]
	switch -- $opt {
	    -all	{ set allMatches 1}
	    -backwards	{ set backwards 1 }
	    -check {
		if {$n == $argCount - 1} {
		    return -code error "value for \"$arg\" missing"
		}

		incr n
		set checkCmd [lindex $argList $n]
	    }
	    -descend	{ set descend 1 }
	    -exact	{ set mode -exact }
	    -formatted	{ set formatted 1 }
	    -glob	{ set mode -glob }
	    -nocase	{ set noCase 1 }
	    -not	{ set negated 1 }
	    -numeric	{ set numeric 1 }
	    -parent {
		if {$n == $argCount - 1} {
		    return -code error "value for \"$arg\" missing"
		}

		incr n
		set parentKey [nodeIndexToKey $win [lindex $argList $n]]
	    }
	    -regexp	{ set mode -regexp }
	    -start {
		if {$n == $argCount - 1} {
		    return -code error "value for \"$arg\" missing"
		}

		incr n
		set startRow [rowIndex $win [lindex $argList $n] 0]
		set gotStartRow 1
	    }
	}
    }

    if {([string compare $mode "-exact"] == 0 && !$numeric && $noCase) ||
	([string compare $mode "-glob"] == 0 && $noCase)} {
	set pattern [string tolower $pattern]
    }

    upvar ::tablelist::ns${win}::data data
    if {[string length $data(-populatecommand)] != 0} {
	#
	# Populate the relevant subtree(s) if necessary
	#
	if {[string compare $parentKey "root"] == 0} {
	    if {$descend} {
		for {set row 0} {$row < $data(itemCount)} {incr row} {
		    populate $win $row 1
		}
	    }
	} else {
	    populate $win [keyToRow $win $parentKey] $descend
	}
    }

    #
    # Build the list of row indices of the matching elements
    #
    set rowList {}
    set useFormatCmd [expr {$formatted && [lindex $data(fmtCmdFlagList) $col]}]
    set childCount [llength $data($parentKey-children)]
    if {$childCount != 0} {
	if {$backwards} {
	    set childIdx [expr {$childCount - 1}]
	    if {$descend} {
		set childKey [lindex $data($parentKey-children) $childIdx]
		set maxRow [expr {[nodeRow $win $childKey end] - 1}]
		if {$gotStartRow && $maxRow > $startRow} {
		    set maxRow $startRow
		}
		set minRow [nodeRow $win $parentKey 0]
		for {set row $maxRow} {$row >= $minRow} {incr row -1} {
		    set item [lindex $data(itemList) $row]
		    set elem [lindex $item $col]
		    if {$useFormatCmd} {
			set key [lindex $item end]
			set elem [formatElem $win $key $row $col $elem]
		    }
		    if {[doesMatch $win $row $col $pattern $elem $mode \
			 $numeric $noCase $checkCmd] != $negated} {
			lappend rowList $row
			if {!$allMatches} {
			    break
			}
		    }
		}
	    } else {
		for {} {$childIdx >= 0} {incr childIdx -1} {
		    set key [lindex $data($parentKey-children) $childIdx]
		    set row [keyToRow $win $key]
		    if {$gotStartRow && $row > $startRow} {
			continue
		    }
		    set elem [lindex [lindex $data(itemList) $row] $col]
		    if {$useFormatCmd} {
			set elem [formatElem $win $key $row $col $elem]
		    }
		    if {[doesMatch $win $row $col $pattern $elem $mode \
			 $numeric $noCase $checkCmd] != $negated} {
			lappend rowList $row
			if {!$allMatches} {
			    break
			}
		    }
		}
	    }
	} else {
	    set childIdx 0
	    if {$descend} {
		set childKey [lindex $data($parentKey-children) $childIdx]
		set fromRow [keyToRow $win $childKey]
		if {$gotStartRow && $fromRow < $startRow} {
		    set fromRow $startRow
		}
		set toRow [nodeRow $win $parentKey end]
		for {set row $fromRow} {$row < $toRow} {incr row} {
		    set item [lindex $data(itemList) $row]
		    set elem [lindex $item $col]
		    if {$useFormatCmd} {
			set key [lindex $item end]
			set elem [formatElem $win $key $row $col $elem]
		    }
		    if {[doesMatch $win $row $col $pattern $elem $mode \
			 $numeric $noCase $checkCmd] != $negated} {
			lappend rowList $row
			if {!$allMatches} {
			    break
			}
		    }
		}
	    } else {
		for {} {$childIdx < $childCount} {incr childIdx} {
		    set key [lindex $data($parentKey-children) $childIdx]
		    set row [keyToRow $win $key]
		    if {$gotStartRow && $row < $startRow} {
			continue
		    }
		    set elem [lindex [lindex $data(itemList) $row] $col]
		    if {$useFormatCmd} {
			set elem [formatElem $win $key $row $col $elem]
		    }
		    if {[doesMatch $win $row $col $pattern $elem $mode \
			 $numeric $noCase $checkCmd] != $negated} {
			lappend rowList $row
			if {!$allMatches} {
			    break
			}
		    }
		}
	    }
	}
    }

    if {$allMatches} {
	return $rowList
    } elseif {[llength $rowList] == 0} {
	return -1
    } else {
	return [lindex $rowList 0]
    }
}

#------------------------------------------------------------------------------
# tablelist::seeSubCmd
#------------------------------------------------------------------------------
proc tablelist::seeSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win see index"
    }

    synchronize $win
    displayItems $win
    set index [rowIndex $win [lindex $argList 0] 0]
    if {[winfo viewable $win] ||
	[llength [$win.body tag nextrange elidedWin 1.0]] == 0} {
	return [seeRow $win $index]
    } else {
	after 0 [list tablelist::seeRow $win $index]
	return ""
    }
}

#------------------------------------------------------------------------------
# tablelist::seecellSubCmd
#------------------------------------------------------------------------------
proc tablelist::seecellSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win seecell cellIndex"
    }

    synchronize $win
    displayItems $win
    foreach {row col} [cellIndex $win [lindex $argList 0] 0] {}
    if {[winfo viewable $win] &&
	[llength [$win.body tag nextrange elidedWin 1.0]] == 0} {
	return [seeCell $win $row $col]
    } else {
	after 0 [list tablelist::seeCell $win $row $col]
	return ""
    }
}

#------------------------------------------------------------------------------
# tablelist::seecolumnSubCmd
#------------------------------------------------------------------------------
proc tablelist::seecolumnSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win seecolumn columnIndex"
    }

    synchronize $win
    displayItems $win
    set col [colIndex $win [lindex $argList 0] 0]
    if {[winfo viewable $win] &&
	[llength [$win.body tag nextrange elidedWin 1.0]] == 0} {
	return [seeCell $win [rowIndex $win @0,0 0] $col]
    } else {
	after 0 [list tablelist::seeCell $win [rowIndex $win @0,0 0] $col]
	return ""
    }
}

#------------------------------------------------------------------------------
# tablelist::selectionSubCmd
#------------------------------------------------------------------------------
proc tablelist::selectionSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 2 || $argCount > 3} {
	mwutil::wrongNumArgs "$win selection option firstIndex lastIndex" \
			     "$win selection option indexList"
    }

    synchronize $win
    displayItems $win
    variable selectionOpts
    set opt [mwutil::fullOpt "option" [lindex $argList 0] $selectionOpts]
    set first [lindex $argList 1]

    switch $opt {
	anchor -
	includes {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win selection $opt index"
	    }
	    set index [rowIndex $win $first 0]
	    return [rowSelection $win $opt $index $index]
	}

	clear -
	set {
	    if {$argCount == 2} {
		foreach elem $first {
		    set index [rowIndex $win $elem 0]
		    rowSelection $win $opt $index $index
		}
	    } else {
		set first [rowIndex $win $first 0]
		set last [rowIndex $win [lindex $argList 2] 0]
		rowSelection $win $opt $first $last
	    }

	    updateColors $win
	    invokeMotionHandler $win
	    return ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::separatorpathSubCmd
#------------------------------------------------------------------------------
proc tablelist::separatorpathSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount > 1} {
	mwutil::wrongNumArgs "$win separatorpath ?columnIndex?"
    }

    upvar ::tablelist::ns${win}::data data
    if {$argCount == 0} {
	if {[winfo exists $data(vsep)]} {
	    return $data(vsep)
	} else {
	    return ""
	}
    } else {
	set col [colIndex $win [lindex $argList 0] 1]
	if {$data(-showseparators)} {
	    return $data(vsep)$col
	} else {
	    return ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::separatorsSubCmd
#------------------------------------------------------------------------------
proc tablelist::separatorsSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win separators"
    }

    set sepList {}
    foreach w [winfo children $win] {
	if {[regexp {^vsep([0-9]+)?$} [winfo name $w]]} {
	    lappend sepList $w
	}
    }

    return [lsort -dictionary $sepList]
}

#------------------------------------------------------------------------------
# tablelist::showtargetmarkSubCmd
#------------------------------------------------------------------------------
proc tablelist::showtargetmarkSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win showtargetmark before|inside index"
    }

    variable targetOpts
    set opt [mwutil::fullOpt "option" [lindex $argList 0] $targetOpts]
    set index [lindex $argList 1]

    upvar ::tablelist::ns${win}::data data
    set w $data(body)

    switch $opt {
	before {
	    set row [rowIndex $win $index 1]
	    if {$data(itemCount) == 0} {
		set y 0
	    } elseif {$row >= $data(itemCount)} {
		set dlineinfo [$w dlineinfo $data(itemCount).0]
		if {[llength $dlineinfo] == 0} {
		    return ""
		}

		set lineY [lindex $dlineinfo 1]
		set lineHeight [lindex $dlineinfo 3]
		set y [expr {$lineY + $lineHeight}]
	    } else {
		if {$row < 0} {
		    set row 0
		}
		set dlineinfo [$w dlineinfo [expr {$row + 1}].0]
		if {[llength $dlineinfo] == 0} {
		    return ""
		}

		set y [lindex $dlineinfo 1]
	    }

	    place $data(rowGap) -anchor w -y $y -height 4 \
				-width [winfo width $data(hdrTxtFrm)]
	}

	inside {
	    set row [rowIndex $win $index 0 1]
	    set dlineinfo [$w dlineinfo [expr {$row + 1}].0]
	    if {[llength $dlineinfo] == 0} {
		return ""
	    }

	    set lineY [lindex $dlineinfo 1]
	    set lineHeight [lindex $dlineinfo 3]
	    set y [expr {$lineY + $lineHeight/2}]

	    place $data(rowGap) -anchor w -y $y -height $lineHeight -width 6
	}
    }

    raise $data(rowGap)
    return ""
}

#------------------------------------------------------------------------------
# tablelist::sizeSubCmd
#------------------------------------------------------------------------------
proc tablelist::sizeSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win size"
    }

    synchronize $win
    upvar ::tablelist::ns${win}::data data
    return $data(itemCount)
}

#------------------------------------------------------------------------------
# tablelist::sortSubCmd
#------------------------------------------------------------------------------
proc tablelist::sortSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount > 1} {
	mwutil::wrongNumArgs "$win sort ?-increasing|-decreasing?"
    }

    if {$argCount == 0} {
	set order -increasing
    } else {
	variable sortOpts
	set order [mwutil::fullOpt "option" [lindex $argList 0] $sortOpts]
    }

    synchronize $win
    displayItems $win
    return [sortItems $win root -1 [string range $order 1 end]]
}

#------------------------------------------------------------------------------
# tablelist::sortbycolumnSubCmd
#------------------------------------------------------------------------------
proc tablelist::sortbycolumnSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win sortbycolumn columnIndex\
			      ?-increasing|-decreasing?"
    }

    synchronize $win
    displayItems $win
    set col [colIndex $win [lindex $argList 0] 1]
    if {$argCount == 1} {
	set order -increasing
    } else {
	variable sortOpts
	set order [mwutil::fullOpt "option" [lindex $argList 1] $sortOpts]
    }

    return [sortItems $win root $col [string range $order 1 end]]
}

#------------------------------------------------------------------------------
# tablelist::sortbycolumnlistSubCmd
#------------------------------------------------------------------------------
proc tablelist::sortbycolumnlistSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win sortbycolumnlist columnIndexList\
			      ?sortOrderList?"
    }

    synchronize $win
    displayItems $win
    set sortColList {}
    foreach elem [lindex $argList 0] {
	set col [colIndex $win $elem 1]
	if {[lsearch -exact $sortColList $col] >= 0} {
	    return -code error "duplicate column index \"$elem\""
	}
	lappend sortColList $col
    }

    set sortOrderList {}
    if {$argCount == 2} {
	variable sortOrders
	foreach elem [lindex $argList 1] {
	    lappend sortOrderList [mwutil::fullOpt "option" $elem $sortOrders]
	}
    }

    return [sortItems $win root $sortColList $sortOrderList]
}

#------------------------------------------------------------------------------
# tablelist::sortcolumnSubCmd
#------------------------------------------------------------------------------
proc tablelist::sortcolumnSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win sortcolumn"
    }

    upvar ::tablelist::ns${win}::data data
    if {[llength $data(sortColList)] == 0} {
	return -1
    } else {
	return [lindex $data(sortColList) 0]
    }
}

#------------------------------------------------------------------------------
# tablelist::sortcolumnlistSubCmd
#------------------------------------------------------------------------------
proc tablelist::sortcolumnlistSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win sortcolumnlist"
    }

    upvar ::tablelist::ns${win}::data data
    return $data(sortColList)
}

#------------------------------------------------------------------------------
# tablelist::sortorderSubCmd
#------------------------------------------------------------------------------
proc tablelist::sortorderSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win sortorder"
    }

    upvar ::tablelist::ns${win}::data data
    if {[llength $data(sortColList)] == 0} {
	return $data(sortOrder)
    } else {
	set col [lindex $data(sortColList) 0]
	return $data($col-sortOrder)
    }
}

#------------------------------------------------------------------------------
# tablelist::sortorderlistSubCmd
#------------------------------------------------------------------------------
proc tablelist::sortorderlistSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win sortorderlist"
    }

    upvar ::tablelist::ns${win}::data data
    set sortOrderList {}
    foreach col $data(sortColList) {
	lappend sortOrderList $data($col-sortOrder)
    }

    return $sortOrderList
}

#------------------------------------------------------------------------------
# tablelist::targetmarkpathSubCmd
#------------------------------------------------------------------------------
proc tablelist::targetmarkpathSubCmd {win argList} {
    if {[llength $argList] != 0} {
	mwutil::wrongNumArgs "$win targetmarkpath"
    }

    upvar ::tablelist::ns${win}::data data
    return $data(rowGap)
}

#------------------------------------------------------------------------------
# tablelist::targetmarkposSubCmd
#------------------------------------------------------------------------------
proc tablelist::targetmarkposSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win targetmarkpos y ?-any|-horizontal|-vertical?"
    }

    set y [format "%d" [lindex $argList 0]]
    if {$argCount == 1} {
	set opt -any
    } else {
	variable gapTypeOpts
	set opt [mwutil::fullOpt "option" [lindex $argList 1] $gapTypeOpts]
    }

    synchronize $win
    displayItems $win

    switch -- $opt {
	-any {
	    set row [containingRow $win $y relOffset]
	    if {$row < 0} {
		set place before
		upvar ::tablelist::ns${win}::data data
		set row [expr {
		    ($y < [winfo y $data(body)]) ? 0 : $data(itemCount)
		}]
	    } elseif {$relOffset < 0.25} {
		set place before
	    } elseif {$relOffset < 0.75} {
		set place inside
	    } else {
		set place before
		if {[isexpandedSubCmd $win $row]} {
		    incr row
		} else {
		    #
		    # Get the containing row's next sibling
		    #
		    set childIdx [childindexSubCmd $win $row]
		    set row [noderowSubCmd $win [list \
			     [parentkeySubCmd $win $row] [incr childIdx]]]
		}
	    }

	    return [list $place $row]
	}

	-horizontal {
	    set row [containingRow $win $y relOffset]
	    if {$row < 0} {
		upvar ::tablelist::ns${win}::data data
		set row [expr {
		    ($y < [winfo y $data(body)]) ? 0 : $data(itemCount)
		}]
	    } elseif {$relOffset >= 0.5} {
		if {[isexpandedSubCmd $win $row]} {
		    incr row
		} else {
		    #
		    # Get the containing row's next sibling
		    #
		    set childIdx [childindexSubCmd $win $row]
		    set row [noderowSubCmd $win [list \
			     [parentkeySubCmd $win $row] [incr childIdx]]]
		}
	    }

	    return [list before $row]
	}

	-vertical {
	    set row [containingRow $win $y]
	    return [list inside $row]
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::togglecolumnhideSubCmd
#------------------------------------------------------------------------------
proc tablelist::togglecolumnhideSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs \
		"$win togglecolumnhide firstColumnIndex lastColumnIndex" \
		"$win togglecolumnhide columnIndexList"
    }

    synchronize $win
    displayItems $win
    set first [lindex $argList 0]

    #
    # Toggle the value of the -hide option of the specified columns
    #
    variable canElide
    if {!$canElide} {
	set selCells [curCellSelection $win]
    }
    upvar ::tablelist::ns${win}::data data
    set colIdxList {}
    if {$argCount == 1} {
	foreach elem $first {
	    set col [colIndex $win $elem 1]
	    set data($col-hide) [expr {!$data($col-hide)}]
	    if {$data($col-hide)} {
		incr data(hiddenColCount)
		if {$col == $data(editCol)} {
		    doCancelEditing $win
		}
	    } else {
		incr data(hiddenColCount) -1
	    }
	    lappend colIdxList $col
	}
    } else {
	set first [colIndex $win $first 1]
	set last [colIndex $win [lindex $argList 1] 1]

	for {set col $first} {$col <= $last} {incr col} {
	    set data($col-hide) [expr {!$data($col-hide)}]
	    if {$data($col-hide)} {
		incr data(hiddenColCount)
		if {$col == $data(editCol)} {
		    doCancelEditing $win
		}
	    } else {
		incr data(hiddenColCount) -1
	    }
	    lappend colIdxList $col
	}
    }

    if {[llength $colIdxList] == 0} {
	return ""
    }

    #
    # Adjust the columns and redisplay the items
    #
    makeColFontAndTagLists $win
    adjustColumns $win $colIdxList 1
    adjustColIndex $win data(anchorCol) 1
    adjustColIndex $win data(activeCol) 1
    if {!$canElide} {
	redisplay $win 0 $selCells
    }
    if {[string compare $data(-selecttype) "row"] == 0} {
	foreach row [curSelection $win] {
	    rowSelection $win set $row $row
	}
    }

    updateViewWhenIdle $win
    genVirtualEvent $win <<TablelistColHiddenStateChanged>> $colIdxList
    return ""
}

#------------------------------------------------------------------------------
# tablelist::togglerowhideSubCmd
#------------------------------------------------------------------------------
proc tablelist::togglerowhideSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount < 1 || $argCount > 2} {
	mwutil::wrongNumArgs "$win togglerowhide firstIndex lastIndex" \
			     "$win togglerowhide indexList"
    }

    synchronize $win
    displayItems $win
    set first [lindex $argList 0]

    #
    # Toggle the value of the -hide option of the specified rows
    #
    set rowIdxList {}
    set count 0
    if {$argCount == 1} {
	foreach elem $first {
	    set row [rowIndex $win $elem 0 1]
	    doRowConfig $row $win -hide [expr {![doRowCget $row $win -hide]}]
	    incr count
	    lappend rowIdxList $row
	}
    } else {
	set firstRow [rowIndex $win $first 0 1]
	set lastRow [rowIndex $win [lindex $argList 1] 0 1]
	for {set row $firstRow} {$row <= $lastRow} {incr row} {
	    doRowConfig $row $win -hide [expr {![doRowCget $row $win -hide]}]
	    incr count
	    lappend rowIdxList $row
	}
    }

    if {$count != 0} {
	makeStripesWhenIdle $win
	showLineNumbersWhenIdle $win
	updateViewWhenIdle $win
	genVirtualEvent $win <<TablelistRowHiddenStateChanged>> $rowIdxList
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::toplevelkeySubCmd
#------------------------------------------------------------------------------
proc tablelist::toplevelkeySubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win toplevelkey index"
    }

    synchronize $win
    set row [rowIndex $win [lindex $argList 0] 0 1]
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    return [topLevelKey $win $key]
}

#------------------------------------------------------------------------------
# tablelist::unsetattribSubCmd
#------------------------------------------------------------------------------
proc tablelist::unsetattribSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win unsetattrib name"
    }

    return [mwutil::unsetattribSubCmd $win "widget" [lindex $argList 0]]
}

#------------------------------------------------------------------------------
# tablelist::unsetcellattribSubCmd
#------------------------------------------------------------------------------
proc tablelist::unsetcellattribSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win unsetcellattrib cellIndex name"
    }

    synchronize $win
    foreach {row col} [cellIndex $win [lindex $argList 0] 1] {}
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    return [mwutil::unsetattribSubCmd $win $key,$col [lindex $argList 1]]
}

#------------------------------------------------------------------------------
# tablelist::unsetcolumnattribSubCmd
#------------------------------------------------------------------------------
proc tablelist::unsetcolumnattribSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win unsetcolumnattrib columnIndex name"
    }

    set col [colIndex $win [lindex $argList 0] 1]
    return [mwutil::unsetattribSubCmd $win $col [lindex $argList 1]]
}

#------------------------------------------------------------------------------
# tablelist::unsetrowattribSubCmd
#------------------------------------------------------------------------------
proc tablelist::unsetrowattribSubCmd {win argList} {
    if {[llength $argList] != 2} {
	mwutil::wrongNumArgs "$win unsetrowattrib index name"
    }

    synchronize $win
    set row [rowIndex $win [lindex $argList 0] 0]
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    return [mwutil::unsetattribSubCmd $win $key [lindex $argList 1]]
}

#------------------------------------------------------------------------------
# tablelist::viewablerowcountSubCmd
#------------------------------------------------------------------------------
proc tablelist::viewablerowcountSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount != 0 && $argCount != 2} {
	mwutil::wrongNumArgs "$win viewablerowcount ?firstIndex lastIndex?"
    }

    synchronize $win
    upvar ::tablelist::ns${win}::data data
    if {$argCount == 0} {
	set first 0
	set last $data(lastRow)
    } else {
	set first [rowIndex $win [lindex $argList 0] 0]
	set last [rowIndex $win [lindex $argList 1] 0]
    }
    if {$last < $first} {
	return 0
    }

    #
    # Adjust the range to fit within the existing items
    #
    if {$first < 0} {
	set first 0
    }
    if {$last > $data(lastRow)} {
	set last $data(lastRow)
    }

    return [getViewableRowCount $win $first $last]
}

#------------------------------------------------------------------------------
# tablelist::windowpathSubCmd
#------------------------------------------------------------------------------
proc tablelist::windowpathSubCmd {win argList} {
    if {[llength $argList] != 1} {
	mwutil::wrongNumArgs "$win windowpath cellIndex"
    }

    synchronize $win
    foreach {row col} [cellIndex $win [lindex $argList 0] 1] {}
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    set w $data(body).frm_$key,$col.w
    if {[winfo exists $w]} {
	return $w
    } else {
	return ""
    }
}

#------------------------------------------------------------------------------
# tablelist::xviewSubCmd
#------------------------------------------------------------------------------
proc tablelist::xviewSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount != 1 || [lindex $argList 0] != 0} {
	synchronize $win
	displayItems $win
    }
    upvar ::tablelist::ns${win}::data data

    switch $argCount {
	0 {
	    #
	    # Command: $win xview
	    #
	    if {$data(-titlecolumns) == 0} {
		return [$data(hdrTxt) xview]
	    } else {
		set scrlWindowWidth [getScrlWindowWidth $win]
		if {$scrlWindowWidth <= 0} {
		    return [list 0 0]
		}

		set scrlContentWidth [getScrlContentWidth $win 0 $data(lastCol)]
		if {$scrlContentWidth == 0} {
		    return [list 0 1]
		}

		set scrlXOffset \
		    [scrlColOffsetToXOffset $win $data(scrlColOffset)]
		set fraction1 [expr {$scrlXOffset/double($scrlContentWidth)}]
		set fraction2 [expr {($scrlXOffset + $scrlWindowWidth)/
				     double($scrlContentWidth)}]
		if {$fraction2 > 1.0} {
		    set fraction2 1.0
		}
		return [list [format "%g" $fraction1] [format "%g" $fraction2]]
	    }
	}

	1 {
	    #
	    # Command: $win xview <units>
	    #
	    set units [format "%d" [lindex $argList 0]]
	    if {$data(-titlecolumns) == 0} {
		foreach w [list $data(hdrTxt) $data(body)] {
		    $w xview moveto 0
		    $w xview scroll $units units
		}
		redisplayVisibleItems $win
	    } else {
		changeScrlColOffset $win $units
	    }
	    updateColors $win
	    return ""
	}

	default {
	    #
	    # Command: $win xview moveto <fraction>
	    #	       $win xview scroll <number> units|pages
	    #
	    set argList [mwutil::getScrollInfo $argList]
	    if {$data(-titlecolumns) == 0} {
		if {[string compare [lindex $argList 0] "moveto"] == 0} {
		    set data(fraction) [lindex $argList 1]
		    if {![info exists data(moveToId)]} {
			variable winSys
			if {[string compare $winSys "x11"] == 0} {
			    set delay [expr {($data(colCount) + 7) / 8}]
			} else {
			    set delay [expr {($data(colCount) + 1) / 2}]
			}
			set data(moveToId) \
			    [after $delay [list tablelist::horizMoveTo $win]]
		    }
		    return ""
		} else {
		    foreach w [list $data(hdrTxt) $data(body)] {
			eval [list $w xview] $argList
		    }
		    redisplayVisibleItems $win
		    updateColors $win
		}
	    } else {
		if {[string compare [lindex $argList 0] "moveto"] == 0} {
		    #
		    # Compute the new scrolled column offset
		    #
		    set fraction [lindex $argList 1]
		    set scrlContentWidth \
			[getScrlContentWidth $win 0 $data(lastCol)]
		    set pixels [expr {int($fraction*$scrlContentWidth + 0.5)}]
		    set scrlColOffset [scrlXOffsetToColOffset $win $pixels]

		    #
		    # Increase the new scrolled column offset if necessary
		    #
		    if {$pixels + [getScrlWindowWidth $win] >=
			$scrlContentWidth} {
			incr scrlColOffset
		    }

		    changeScrlColOffset $win $scrlColOffset
		} else {
		    set number [lindex $argList 1]
		    if {[string compare [lindex $argList 2] "units"] == 0} {
			changeScrlColOffset $win \
			    [expr {$data(scrlColOffset) + $number}]
		    } else {
			#
			# Compute the new scrolled column offset
			#
			set scrlXOffset \
			    [scrlColOffsetToXOffset $win $data(scrlColOffset)]
			set scrlWindowWidth [getScrlWindowWidth $win]
			set deltaPixels [expr {$number*$scrlWindowWidth}]
			set pixels [expr {$scrlXOffset + $deltaPixels}]
			set scrlColOffset [scrlXOffsetToColOffset $win $pixels]

			#
			# Adjust the new scrolled column offset if necessary
			#
			if {$number < 0 &&
			    [getScrlContentWidth $win $scrlColOffset \
			     $data(lastCol)] -
			    [getScrlContentWidth $win $data(scrlColOffset) \
			     $data(lastCol)] > -$deltaPixels} {
			    incr scrlColOffset
			}
			if {$scrlColOffset == $data(scrlColOffset)} {
			    if {$number < 0} {
				incr scrlColOffset -1
			    } elseif {$number > 0} {
				incr scrlColOffset
			    }
			}

			changeScrlColOffset $win $scrlColOffset
		    }
		}
		updateColors $win
	    }
	    variable winSys
	    if {[string compare $winSys "aqua"] == 0 && [winfo viewable $win]} {
		#
		# Work around a Tk bug on Mac OS X Aqua
		#
		if {[winfo exists $data(bodyFrm)]} {
		    lower $data(bodyFrm)
		    raise $data(bodyFrm)
		}
	    }
	    return ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::yviewSubCmd
#------------------------------------------------------------------------------
proc tablelist::yviewSubCmd {win argList} {
    set argCount [llength $argList]
    if {$argCount != 1 || [lindex $argList 0] != 0} {
	synchronize $win
	displayItems $win
    }
    upvar ::tablelist::ns${win}::data data
    set w $data(body)

    switch $argCount {
	0 {
	    #
	    # Command: $win yview
	    #
	    set totalViewableCount [getViewableRowCount $win 0 $data(lastRow)]
	    if {$totalViewableCount == 0} {
		return [list 0 1]
	    }
	    set topRow [getVertComplTopRow $win]
	    set btmRow [getVertComplBtmRow $win]
	    set upperViewableCount \
		[getViewableRowCount $win 0 [expr {$topRow - 1}]]
	    set winViewableCount [getViewableRowCount $win $topRow $btmRow]
	    set fraction1 [expr {$upperViewableCount/
				 double($totalViewableCount)}]
	    set fraction2 [expr {($upperViewableCount + $winViewableCount)/
				 double($totalViewableCount)}]
	    return [list [format "%g" $fraction1] [format "%g" $fraction2]]
	}

	1 {
	    #
	    # Command: $win yview <units>
	    #
	    set units [format "%d" [lindex $argList 0]]
	    set row [viewableRowOffsetToRowIndex $win $units]
	    $w yview $row
	    adjustElidedText $win
	    redisplayVisibleItems $win
	    updateColors $win
	    adjustSepsWhenIdle $win
	    updateVScrlbarWhenIdle $win
	    updateIdletasksDelayed 
	    return ""
	}

	default {
	    #
	    # Command: $win yview moveto <fraction>
	    #	       $win yview scroll <number> units|pages
	    #
	    set argList [mwutil::getScrollInfo $argList]
	    if {[string compare [lindex $argList 0] "moveto"] == 0} {
		set data(fraction) [lindex $argList 1]
		if {![info exists data(moveToId)]} {
		    variable winSys
		    if {[string compare $winSys "x11"] == 0} {
			set delay [expr {($data(colCount) + 3) / 4}]
		    } else {
			set delay [expr {$data(colCount) * 2}]
		    }
		    set data(moveToId) \
			[after $delay [list tablelist::vertMoveTo $win]]
		}
		return ""
	    } else {
		set number [lindex $argList 1]
		if {[string compare [lindex $argList 2] "units"] == 0} {
		    set topRow [getVertComplTopRow $win]
		    set upperViewableCount \
			[getViewableRowCount $win 0 [expr {$topRow - 1}]]
		    set offset [expr {$upperViewableCount + $number}]
		    set row [viewableRowOffsetToRowIndex $win $offset]
		    $w yview $row
		} else {
		    set absNumber [expr {abs($number)}]
		    for {set n 0} {$n < $absNumber} {incr n} {
			set topRow [getVertComplTopRow $win]
			set btmRow [getVertComplBtmRow $win]
			set upperViewableCount \
			    [getViewableRowCount $win 0 [expr {$topRow - 1}]]
			set winViewableCount \
			    [getViewableRowCount $win $topRow $btmRow]
			set delta [expr {$winViewableCount - 2}]
			if {$delta <= 0} {
			    set delta 1
			}
			if {$number < 0} {
			    set delta [expr {(-1)*$delta}]
			}
			set offset [expr {$upperViewableCount + $delta}]
			set row [viewableRowOffsetToRowIndex $win $offset]
			$w yview $row
		    }
		}

		adjustElidedText $win
		redisplayVisibleItems $win
		updateColors $win
		adjustSepsWhenIdle $win
		updateVScrlbarWhenIdle $win
		updateIdletasksDelayed 
		return ""
	    }
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::cellSelection
#
# Processes the tablelist cellselection subcommand.
#------------------------------------------------------------------------------
proc tablelist::cellSelection {win opt firstRow firstCol lastRow lastCol} {
    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled) && [string compare $opt "includes"] != 0} {
	return ""
    }

    switch $opt {
	anchor {
	    #
	    # Adjust the row and column indices to fit
	    # within the existing viewable elements
	    #
	    adjustRowIndex $win firstRow 1
	    adjustColIndex $win firstCol 1

	    set data(anchorRow) $firstRow
	    set data(anchorCol) $firstCol
	    return ""
	}

	clear {
	    #
	    # Adjust the row and column indices
	    # to fit within the existing elements
	    #
	    if {$data(itemCount) == 0 || $data(colCount) == 0} {
		return ""
	    }
	    adjustRowIndex $win firstRow
	    adjustColIndex $win firstCol
	    adjustRowIndex $win lastRow
	    adjustColIndex $win lastCol

	    #
	    # Swap the indices if necessary
	    #
	    if {$lastRow < $firstRow} {
		set tmp $firstRow
		set firstRow $lastRow
		set lastRow $tmp
	    }
	    if {$lastCol < $firstCol} {
		set tmp $firstCol
		set firstCol $lastCol
		set lastCol $tmp
	    }

	    set fromTextIdx [expr {$firstRow + 1}].0
	    set toTextIdx [expr {$lastRow + 1}].end

	    #
	    # Find the (partly) selected lines of the body text widget
	    # in the text range specified by the two cell indices
	    #
	    set w $data(body)
	    variable canElide
	    variable elide
	    set selRange [$w tag nextrange select $fromTextIdx $toTextIdx]
	    while {[llength $selRange] != 0} {
		set selStart [lindex $selRange 0]
		set line [expr {int($selStart)}]
		set row [expr {$line - 1}]
		set key [lindex $data(keyList) $row]

		#
		# Deselect the relevant elements of the row
		#
		findTabs $win $line $firstCol $lastCol firstTabIdx lastTabIdx
		set textIdx1 $firstTabIdx
		for {set col $firstCol} {$col <= $lastCol} {incr col} {
		    if {$data($col-hide) && !$canElide} {
			continue
		    }

		    set textIdx2 \
			[$w search $elide "\t" $textIdx1+1c $lastTabIdx+1c]+1c
		    $w tag remove select $textIdx1 $textIdx2
		    set textIdx1 $textIdx2
		}

		set selRange \
		    [$w tag nextrange select "$selStart lineend" $toTextIdx]
	    }

	    updateColorsWhenIdle $win
	    return ""
	}

	includes {
	    variable canElide
	    if {$firstRow < 0 || $firstRow > $data(lastRow) || \
		$firstCol < 0 || $firstCol > $data(lastCol) ||
		($data($firstCol-hide) && !$canElide)} {
		return 0
	    }

	    findTabs $win [expr {$firstRow + 1}] $firstCol $firstCol \
		     tabIdx1 tabIdx2
	    if {[lsearch -exact [$data(body) tag names $tabIdx2] select] < 0} {
		return 0
	    } else {
		return 1
	    }
	}

	set {
	    #
	    # Adjust the row and column indices
	    # to fit within the existing elements
	    #
	    if {$data(itemCount) == 0 || $data(colCount) == 0} {
		return ""
	    }
	    adjustRowIndex $win firstRow
	    adjustColIndex $win firstCol
	    adjustRowIndex $win lastRow
	    adjustColIndex $win lastCol

	    #
	    # Swap the indices if necessary
	    #
	    if {$lastRow < $firstRow} {
		set tmp $firstRow
		set firstRow $lastRow
		set lastRow $tmp
	    }
	    if {$lastCol < $firstCol} {
		set tmp $firstCol
		set firstCol $lastCol
		set lastCol $tmp
	    }

	    set w $data(body)
	    variable canElide
	    variable elide
	    for {set row $firstRow; set line [expr {$firstRow + 1}]} \
		{$row <= $lastRow} {set row $line; incr line} {
		#
		# Check whether the row is selectable
		#
		set key [lindex $data(keyList) $row]
		if {[info exists data($key-selectable)]} {
		    continue
		}

		#
		# Select the relevant elements of the row
		#
		findTabs $win $line $firstCol $lastCol firstTabIdx lastTabIdx
		set textIdx1 $firstTabIdx
		for {set col $firstCol} {$col <= $lastCol} {incr col} {
		    if {$data($col-hide) && !$canElide} {
			continue
		    }

		    set textIdx2 \
			[$w search $elide "\t" $textIdx1+1c $lastTabIdx+1c]+1c
		    $w tag add select $textIdx1 $textIdx2
		    set textIdx1 $textIdx2
		}
	    }

	    #
	    # If the selection is exported and there are any selected
	    # cells in the widget then make win the new owner of the
	    # PRIMARY selection and register a callback to be invoked
	    # when it loses ownership of the PRIMARY selection
	    #
	    if {$data(-exportselection) &&
		[llength [$w tag nextrange select 1.0]] != 0} {
		selection own -command \
			[list ::tablelist::lostSelection $win] $win
	    }

	    updateColorsWhenIdle $win
	    return ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::colWidth
#
# Processes the tablelist columnwidth subcommand.
#------------------------------------------------------------------------------
proc tablelist::colWidth {win col opt} {
    upvar ::tablelist::ns${win}::data data
    set pixels [lindex $data(colList) [expr {2*$col}]]
    if {$pixels == 0} {				;# convention: dynamic width
	set pixels $data($col-reqPixels)
	if {$data($col-maxPixels) > 0} {
	    if {$pixels > $data($col-maxPixels)} {
		set pixels $data($col-maxPixels)
	    }
	}
    }

    switch -- $opt {
	-requested { return $pixels }
	-stretched { return [expr {$pixels + $data($col-delta)}] }
	-total {
	    return [expr {$pixels + $data($col-delta) + 2*$data(charWidth)}]
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::containingRow
#
# Processes the tablelist containing subcommand.
#------------------------------------------------------------------------------
proc tablelist::containingRow {win y {relOffsetName ""}} {
    upvar ::tablelist::ns${win}::data data
    if {$data(itemCount) == 0} {
	return -1
    }

    set row [rowIndex $win @0,$y 0]
    set w $data(body)
    incr y -[winfo y $w]
    if {$y < 0} {
	return -1
    }

    set dlineinfo [$w dlineinfo [expr {$row + 1}].0]
    set lineY [lindex $dlineinfo 1]
    set lineHeight [lindex $dlineinfo 3]
    if {[llength $dlineinfo] != 0 && $y < $lineY + $lineHeight} {
	if {[string length $relOffsetName] != 0} {
	    upvar $relOffsetName relOffset
	    if {$y == $lineY + $lineHeight -1} {
		set relOffset 1.0
	    } else {
		set relOffset [expr {double($y - $lineY) / $lineHeight}]
	    }
	}
	return $row
    } else {
	return -1
    }
}

#------------------------------------------------------------------------------
# tablelist::containingCol
#
# Processes the tablelist containingcolumn subcommand.
#------------------------------------------------------------------------------
proc tablelist::containingCol {win x} {
    upvar ::tablelist::ns${win}::data data
    if {$x < [winfo x $data(body)]} {
	return -1
    }

    set col [colIndex $win @$x,0 0]
    if {$col < 0} {
	return -1
    }

    set lbl $data(hdrTxtFrmLbl)$col
    if {$x + [winfo rootx $win] < [winfo width $lbl] + [winfo rootx $lbl]} {
	return $col
    } else {
	return -1
    }
}

#------------------------------------------------------------------------------
# tablelist::curCellSelection
#
# Processes the tablelist curcellselection subcommand.  Meaning of the last
# optional argument: 0: all; 1: nonhidden only; 2: viewable only.
#------------------------------------------------------------------------------
proc tablelist::curCellSelection {win {getKeys 0} {constraint 0}} {
    variable canElide
    variable elide
    upvar ::tablelist::ns${win}::data data

    #
    # Find the (partly) selected lines of the body text widget
    #
    set result {}
    set w $data(body)
    for {set selRange [$w tag nextrange select 1.0]} \
	{[llength $selRange] != 0} \
	{set selRange [$w tag nextrange select $selEnd]} {
	foreach {selStart selEnd} $selRange {}
	set line [expr {int($selStart)}]
	set row [expr {$line - 1}]
	if {$getKeys || $constraint != 0} {
	    set key [lindex $data(keyList) $row]
	}
	if {($constraint == 1 && [info exists data($key-hide)]) ||
	    ($constraint == 2 && ([info exists data($key-hide)] ||
	     [info exists data($key-elide)]))} {
	    continue
	}

	#
	# Get the index of the column containing the text position selStart
	#
	set tabIdx1 $line.0
	for {set col 0} {$col < $data(colCount)} {incr col} {
	    if {$data($col-hide) && !$canElide} {
		continue
	    }

	    set tabIdx2 [$w search $elide "\t" $tabIdx1+1c $selEnd]
	    if {[$w compare $selStart >= $tabIdx1] &&
		[$w compare $selStart <= $tabIdx2]} {
		set firstCol $col
		break
	    } else {
		set tabIdx1 [$w index $tabIdx2+1c]
	    }
	}

	#
	# Process the columns, starting at the found one
	# and ending just before the text position selEnd
	#
	set textIdx $tabIdx2+1c
	for {set col $firstCol} {$col < $data(colCount)} {incr col} {
	    if {$data($col-hide) && !$canElide} {
		continue
	    }

	    if {$constraint == 0 || !$data($col-hide)} {
		if {$getKeys} {
		    lappend result $key $col
		} else {
		    lappend result $row,$col
		}
	    }
	    if {[$w compare $textIdx == $selEnd]} {
		break
	    } else {
		set textIdx [$w search $elide "\t" $textIdx+1c $selEnd]+1c
	    }
	}
    }

    return $result
}

#------------------------------------------------------------------------------
# tablelist::curSelection
#
# Processes the tablelist curselection subcommand.  Meaning of the optional
# argument: 0: all; 1: nonhidden only; 2: viewable only.
#------------------------------------------------------------------------------
proc tablelist::curSelection {win {constraint 0}} {
    #
    # Find the (partly) selected lines of the body text widget
    #
    set result {}
    upvar ::tablelist::ns${win}::data data
    set w $data(body)
    set selRange [$w tag nextrange select 1.0]
    while {[llength $selRange] != 0} {
	set selStart [lindex $selRange 0]
	set row [expr {int($selStart) - 1}]
	if {$constraint == 0} {
	    lappend result $row
	} else {
	    set key [lindex $data(keyList) $row]
	    if {($constraint == 1 && ![info exists data($key-hide)]) ||
		($constraint == 2 && ![info exists data($key-hide)] &&
		 ![info exists data($key-elide)])} {
		lappend result $row
	    }
	}

	set selRange [$w tag nextrange select "$selStart lineend"]
    }

    return $result
}

#------------------------------------------------------------------------------
# tablelist::deleteRows
#
# Processes the tablelist delete subcommand.
#------------------------------------------------------------------------------
proc tablelist::deleteRows {win first last updateListVar} {
    #
    # Adjust the range to fit within the existing items
    #
    if {$first < 0} {
	set first 0
    }
    upvar ::tablelist::ns${win}::data data \
	  ::tablelist::ns${win}::attribs attribs
    if {$last > $data(lastRow)} {
	set last $data(lastRow)
    }
    if {$last < $first} {
	return ""
    }

    #
    # Increase the last index if necessary, to make sure that all
    # descendants of the corresponding item will get deleted, too
    #
    set lastKey [lindex $data(keyList) $last]
    set last [expr {[nodeRow $win $lastKey end] - 1}]
    set count [expr {$last - $first + 1}]

    #
    # Check whether the width of any dynamic-width
    # column might be affected by the deletion
    #
    set w $data(body)
    if {$count == $data(itemCount)} {
	set colWidthsChanged 1				;# just to save time
	set data(seqNum) -1
	set data(freeKeyList) {}
    } else {
	variable canElide
	set colWidthsChanged 0
	set snipStr $data(-snipstring)
	set row 0
	set itemListRange [lrange $data(itemList) $first $last]
	foreach item $itemListRange {
	    #
	    # Format the item
	    #
	    set key [lindex $item end]
	    set dispItem [lrange $item 0 $data(lastCol)]
	    if {$data(hasFmtCmds)} {
		set dispItem [formatItem $win $key $row $dispItem]
	    }
	    if {[string match "*\t*" $dispItem]} {
		set dispItem [mapTabs $dispItem]
	    }

	    set col 0
	    foreach text $dispItem {pixels alignment} $data(colList) {
		if {($data($col-hide) && !$canElide) || $pixels != 0} {
		    incr col
		    continue
		}

		getAuxData $win $key $col auxType auxWidth
		getIndentData $win $key $col indentWidth
		set cellFont [getCellFont $win $key $col]
		set elemWidth \
		    [getElemWidth $win $text $auxWidth $indentWidth $cellFont]
		if {$elemWidth == $data($col-elemWidth) &&
		    [incr data($col-widestCount) -1] == 0} {
		    set colWidthsChanged 1
		    break
		}

		incr col
	    }

	    if {$colWidthsChanged} {
		break
	    }

	    incr row
	}
    }

    #
    # Delete the given items from the body text widget.  Interestingly,
    # for a large number of items it is much more efficient to delete
    # the lines in chunks than to invoke a global delete command.
    #
    for {set toLine [expr {$last + 2}]; set fromLine [expr {$toLine - 50}]} \
	{$fromLine > $first} {set toLine $fromLine; incr fromLine -50} {
	$w delete $fromLine.0 $toLine.0
    }
    set rest [expr {$count % 50}]
    $w delete [expr {$first + 1}].0 [expr {$first + $rest + 1}].0

    if {$last == $data(lastRow)} {
	#
	# Delete the newline character that ends
	# the line preceding the first deleted one
	#
	$w delete $first.end

	#
	# Work around a peculiarity of the text widget:  Hide
	# the newline character that ends the line preceding
	# the first deleted one if it was hidden before
	#
	set textIdx $first.0
	foreach tag {elidedRow hiddenRow} {
	    if {[lsearch -exact [$w tag names $textIdx] $tag] >= 0} {
		$w tag add $tag $first.end
	    }
	}
    }

    #
    # Unset the elements of data corresponding to the deleted items
    #
    for {set row $first} {$row <= $last} {incr row} {
	set item [lindex $data(itemList) $row]
	set key [lindex $item end]
	if {$count != $data(itemCount)} {
	    lappend data(freeKeyList) $key
	}

	foreach opt {-background -foreground -name -selectable
		     -selectbackground -selectforeground} {
	    if {[info exists data($key$opt)]} {
		unset data($key$opt)
	    }
	}

	if {[info exists data($key-font)]} {
	    unset data($key-font)
	    incr data(rowTagRefCount) -1
	}

	set isElided [info exists data($key-elide)]
	set isHidden [info exists data($key-hide)]
	if {$isElided} {
	    unset data($key-elide)
	}
	if {$isHidden} {
	    unset data($key-hide)
	}
	if {$isElided || $isHidden} {
	    incr data(nonViewableRowCount) -1
	}

	if {$count != $data(itemCount)} {
	    #
	    # Remove the key from the list of children of its parent
	    #
	    set parentKey $data($key-parent)
	    if {[info exists data($parentKey-children)]} {
		set childIdx [lsearch -exact $data($parentKey-children) $key]
		set data($parentKey-children) \
		    [lreplace $data($parentKey-children) $childIdx $childIdx]

		#
		# If the parent's list of children has become empty
		# then set its indentation image to the indented one
		#
		set col $data(treeCol)
		if {[llength $data($parentKey-children)] == 0 &&
		    [info exists data($parentKey,$col-indent)]} {
		    collapseSubCmd $win [list $parentKey -partly]
		    set data($parentKey,$col-indent) [strMap \
			{"collapsed" "indented" "expanded" "indented"
			 "Act" "" "Sel" ""} $data($parentKey,$col-indent)]
		    if {[winfo exists $data(body).ind_$parentKey,$col]} {
			$data(body).ind_$parentKey,$col configure -image \
			    $data($parentKey,$col-indent)
		    }
		}
	    }
	}

	foreach prop {-row -parent -children} {
	    unset data($key$prop)
	}

	foreach name [array names attribs $key-*] {
	    unset attribs($name)
	}

	for {set col 0} {$col < $data(colCount)} {incr col} {
	    foreach opt {-background -foreground -editable -editwindow
			 -selectbackground -selectforeground -valign
			 -windowdestroy -windowupdate} {
		if {[info exists data($key,$col$opt)]} {
		    unset data($key,$col$opt)
		}
	    }

	    if {[info exists data($key,$col-font)]} {
		unset data($key,$col-font)
		incr data(cellTagRefCount) -1
	    }

	    if {[info exists data($key,$col-image)]} {
		unset data($key,$col-image)
		incr data(imgCount) -1
	    }

	    if {[info exists data($key,$col-window)]} {
		unset data($key,$col-window)
		unset data($key,$col-reqWidth)
		unset data($key,$col-reqHeight)
		incr data(winCount) -1
	    }

	    if {[info exists data($key,$col-indent)]} {
		unset data($key,$col-indent)
		incr data(indentCount) -1
	    }
	}

	foreach name [array names attribs $key,*-*] {
	    unset attribs($name)
	}
    }

    if {$count == $data(itemCount)} {
	set data(root-children) {}
    }

    #
    # Delete the given items from the internal list
    #
    set data(itemList) [lreplace $data(itemList) $first $last]
    set data(keyList) [lreplace $data(keyList) $first $last]
    incr data(itemCount) -$count

    #
    # Delete the given items from the list variable if needed
    #
    if {$updateListVar} {
	upvar #0 $data(-listvariable) var
	trace vdelete var wu $data(listVarTraceCmd)
	set var [lreplace $var $first $last]
	trace variable var wu $data(listVarTraceCmd)
    }

    #
    # Update the key -> row mapping at idle time if needed
    #
    if {$last != $data(lastRow)} {
	set data(keyToRowMapValid) 0
	if {![info exists data(mapId)]} {
	    set data(mapId) \
		[after idle [list tablelist::updateKeyToRowMap $win]]
	}
    }

    incr data(lastRow) -$count

    #
    # Update the indices anchorRow and activeRow
    #
    if {$first <= $data(anchorRow)} {
	incr data(anchorRow) -$count
	if {$data(anchorRow) < $first} {
	    set data(anchorRow) $first
	}
	adjustRowIndex $win data(anchorRow) 1
    }
    if {$last < $data(activeRow)} {
	set activeRow $data(activeRow)
	incr activeRow -$count
	adjustRowIndex $win activeRow 1
	set data(activeRow) $activeRow
    } elseif {$first <= $data(activeRow)} {
	set activeRow $first
	adjustRowIndex $win activeRow 1
	set data(activeRow) $activeRow
    }

    #
    # Update data(editRow) if the edit window is present
    #
    if {$data(editRow) >= 0} {
	set data(editRow) [keyToRow $win $data(editKey)]
    }

    #
    # Adjust the heights of the body text widget
    # and of the listbox child, if necessary
    #
    if {$data(-height) <= 0} {
	set viewableRowCount \
	    [expr {$data(itemCount) - $data(nonViewableRowCount)}]
	$w configure -height $viewableRowCount
	$data(lb) configure -height $viewableRowCount
    }

    #
    # Invalidate the list of row indices indicating the
    # viewable rows, adjust the columns if necessary, and
    # schedule some operations for execution at idle time
    #
    set data(viewableRowList) {-1}
    if {$colWidthsChanged} {
	adjustColumns $win allCols 1
    }
    makeStripesWhenIdle $win
    showLineNumbersWhenIdle $win
    updateViewWhenIdle $win

    return ""
}

#------------------------------------------------------------------------------
# tablelist::deleteCols
#
# Processes the tablelist deletecolumns subcommand.
#------------------------------------------------------------------------------
proc tablelist::deleteCols {win first last selCellsName} {
    upvar ::tablelist::ns${win}::data data \
	  ::tablelist::ns${win}::attribs attribs $selCellsName selCells

    #
    # Delete the data and attributes corresponding to the given range
    #
    for {set col $first} {$col <= $last} {incr col} {
	if {$data($col-hide)} {
	    incr data(hiddenColCount) -1
	}
	deleteColData $win $col
	deleteColAttribs $win $col
	set selCells [deleteColFromCellList $selCells $col]
    }

    #
    # Shift the elements of data and attribs corresponding to the
    # column indices > last to the left by last - first + 1 positions
    #
    for {set oldCol [expr {$last + 1}]; set newCol $first} \
	{$oldCol < $data(colCount)} {incr oldCol; incr newCol} {
	moveColData data data imgs $oldCol $newCol
	moveColAttribs attribs attribs $oldCol $newCol
	set selCells [replaceColInCellList $selCells $oldCol $newCol]
    }

    #
    # Update the item list
    #
    set newItemList {}
    foreach item $data(itemList) {
	set item [lreplace $item $first $last]
	lappend newItemList $item
    }
    set data(itemList) $newItemList

    #
    # Update the list variable if present
    #
    condUpdateListVar $win

    #
    # Set up and adjust the columns, and rebuild some columns-related lists
    #
    setupColumns $win \
	[lreplace $data(-columns) [expr {3*$first}] [expr {3*$last + 2}]] 1
    makeColFontAndTagLists $win
    makeSortAndArrowColLists $win
    adjustColumns $win {} 1
    updateViewWhenIdle $win

    #
    # Reconfigure the relevant column labels
    #
    for {set col $first} {$col < $data(colCount)} {incr col} {
	reconfigColLabels $win imgs $col
    }

    #
    # Update the indices anchorCol and activeCol
    #
    set count [expr {$last - $first + 1}]
    if {$first <= $data(anchorCol)} {
	incr data(anchorCol) -$count
	if {$data(anchorCol) < $first} {
	    set data(anchorCol) $first
	}
	adjustColIndex $win data(anchorCol) 1
    }
    if {$last < $data(activeCol)} {
	incr data(activeCol) -$count
	adjustColIndex $win data(activeCol) 1
    } elseif {$first <= $data(activeCol)} {
	set data(activeCol) $first
	adjustColIndex $win data(activeCol) 1
    }
}

#------------------------------------------------------------------------------
# tablelist::insertRows
#
# Processes the tablelist insert and insertlist subcommands.
#------------------------------------------------------------------------------
proc tablelist::insertRows {win index argList updateListVar parentKey \
			    childIdx} {
    set argCount [llength $argList]
    if {$argCount == 0} {
	return {}
    }

    upvar ::tablelist::ns${win}::data data
    if {$index < $data(itemCount)} {
	displayItems $win
    }

    if {$index < 0} {
	set index 0
    } elseif {$index > $data(itemCount)} {
	set index $data(itemCount)
    }

    set childCount [llength $data($parentKey-children)]
    if {$childIdx < 0} {
	set childIdx 0
    } elseif {$childIdx > $childCount} {	;# e.g., if $childIdx is "end"
	set childIdx $childCount
    }

    #
    # Insert the items into the internal list
    #
    set result {}
    set appendingItems [expr {$index == $data(itemCount)}]
    set appendingChildren [expr {$childIdx == $childCount}]
    set row $index
    foreach item $argList {
	#
	# Adjust the item
	#
	set item [adjustItem $item $data(colCount)]

	#
	# Insert the item into the list variable if needed
	#
	if {$updateListVar} {
	    upvar #0 $data(-listvariable) var
	    trace vdelete var wu $data(listVarTraceCmd)
	    if {$appendingItems} {
		lappend var $item    		;# this works much faster
	    } else {
		set var [linsert $var $row $item]
	    }
	    trace variable var wu $data(listVarTraceCmd)
	}

	#
	# Get a free key for the new item
	#
	if {[llength $data(freeKeyList)] == 0} {
	    set key k[incr data(seqNum)]
	} else {
	    set key [lindex $data(freeKeyList) 0]
	    set data(freeKeyList) [lrange $data(freeKeyList) 1 end]
	}

	#
	# Insert the extended item into the internal list
	#
	lappend item $key
	if {$appendingItems} {
	    lappend data(itemList) $item	;# this works much faster
	    lappend data(keyList) $key		;# this works much faster
	} else {
	    set data(itemList) [linsert $data(itemList) $row $item]
	    set data(keyList) [linsert $data(keyList) $row $key]
	}

	array set data \
	      [list $key-row $row  $key-parent $parentKey  $key-children {}]

	#
	# Insert the key into the parent's list of children
	#
	if {$appendingChildren} {
	    lappend data($parentKey-children) $key    ;# this works much faster
	} else {
	    set data($parentKey-children) \
		[linsert $data($parentKey-children) $childIdx $key]
	}

	lappend data(rowsToDisplay) $row
	lappend result $key

	incr row
	incr childIdx
    }
    incr data(itemCount) $argCount
    set data(lastRow) [expr {$data(itemCount) - 1}]

    #
    # Update the key -> row mapping at idle time if needed
    #
    if {!$appendingItems} {
	set data(keyToRowMapValid) 0
	if {![info exists data(mapId)]} {
	    set data(mapId) \
		[after idle [list tablelist::updateKeyToRowMap $win]]
	}
    }

    if {![info exists data(dispId)]} {
	#
	# Arrange for the inserted items to be displayed at idle time
	#
	set data(dispId) [after idle [list tablelist::displayItems $win]]
    }

    #
    # Update the indices anchorRow and activeRow
    #
    if {$index <= $data(anchorRow)} {
	incr data(anchorRow) $argCount
	adjustRowIndex $win data(anchorRow) 1
    }
    if {$index <= $data(activeRow)} {
	set activeRow $data(activeRow)
	incr activeRow $argCount
	adjustRowIndex $win activeRow 1
	set data(activeRow) $activeRow
    }

    #
    # Update data(editRow) if the edit window is present
    #
    if {$data(editRow) >= 0} {
	set data(editRow) [keyToRow $win $data(editKey)]
    }

    return $result
}

#------------------------------------------------------------------------------
# tablelist::displayItems
#
# This procedure is invoked either as an idle callback after inserting some
# items into the internal list of the tablelist widget win, or directly, upon
# execution of some widget commands.  It displays the inserted items.
#------------------------------------------------------------------------------
proc tablelist::displayItems win {
    #
    # Nothing to do if there are no items to display
    #
    upvar ::tablelist::ns${win}::data data
    if {![info exists data(dispId)]} {
	return ""
    }

    #
    # Here we are in the case that the procedure was scheduled for
    # execution at idle time.  However, it might have been invoked
    # directly, before the idle time occured; in this case we should
    # cancel the execution of the previously scheduled idle callback.
    #
    after cancel $data(dispId)	;# no harm if data(dispId) is no longer valid
    unset data(dispId)

    #
    # Insert the items into the body text widget
    #
    variable canElide
    variable snipSides
    set w $data(body)
    set widgetFont $data(-font)
    set snipStr $data(-snipstring)
    set padY [expr {[$w cget -spacing1] == 0}]
    set wasEmpty [expr {[llength $data(rowsToDisplay)] == $data(itemCount)}]
    set isEmpty $wasEmpty
    foreach row $data(rowsToDisplay) {
	set line [expr {$row + 1}]
	set item [lindex $data(itemList) $row]
	set key [lindex $item end]

	#
	# Format the item
	#
	set dispItem [lrange $item 0 $data(lastCol)]
	if {$data(hasFmtCmds)} {
	    set dispItem [formatItem $win $key $row $dispItem]
	}
	if {[string match "*\t*" $dispItem]} {
	    set dispItem [mapTabs $dispItem]
	}

	if {$isEmpty} {
	    set isEmpty 0
	} else {
	    $w insert $line.0 "\n"
	}
	if {$data(nonViewableRowCount) != 0} {
	    $w tag remove elidedRow $line.0
	    $w tag remove hiddenRow $line.0
	}
	set multilineData {}
	set col 0
	if {$data(hasColTags)} {
	    set insertArgs {}
	    foreach text $dispItem \
		    colFont $data(colFontList) \
		    colTags $data(colTagsList) \
		    {pixels alignment} $data(colList) {
		if {$data($col-hide) && !$canElide} {
		    incr col
		    continue
		}

		#
		# Update the column width or clip the element if necessary
		#
		set multiline [string match "*\n*" $text]
		if {$pixels == 0} {		;# convention: dynamic width
		    if {$multiline} {
			set list [split $text "\n"]
			set textWidth [getListWidth $win $list $colFont]
		    } else {
			set textWidth \
			    [font measure $colFont -displayof $win $text]
		    }
		    if {$data($col-maxPixels) > 0} {
			if {$textWidth > $data($col-maxPixels)} {
			    set pixels $data($col-maxPixels)
			}
		    }
		    if {$textWidth == $data($col-elemWidth)} {
			incr data($col-widestCount)
		    } elseif {$textWidth > $data($col-elemWidth)} {
			set data($col-elemWidth) $textWidth
			set data($col-widestCount) 1
		    }
		}
		if {$pixels != 0} {
		    incr pixels $data($col-delta)

		    if {$data($col-wrap) && !$multiline} {
			if {[font measure $colFont -displayof $win $text] >
			    $pixels} {
			    set multiline 1
			}
		    }

		    set snipSide \
			$snipSides($alignment,$data($col-changesnipside))
		    if {$multiline} {
			set list [split $text "\n"]
			if {$data($col-wrap)} {
			    set snipSide ""
			}
			set text [joinList $win $list $colFont \
				  $pixels $snipSide $snipStr]
		    } elseif {$data(-displayondemand)} {
			set text ""
		    } else {
			set text [strRange $win $text $colFont \
				  $pixels $snipSide $snipStr]
		    }
		}

		if {$multiline} {
		    lappend insertArgs "\t\t" $colTags
		    lappend multilineData $col $text $colFont $pixels $alignment
		} else {
		    lappend insertArgs "\t$text\t" $colTags
		}
		incr col
	    }

	    #
	    # Insert the item into the body text widget
	    #
	    if {[llength $insertArgs] != 0} {
		eval [list $w insert $line.0] $insertArgs
	    }

	} else {
	    set insertStr ""
	    foreach text $dispItem {pixels alignment} $data(colList) {
		if {$data($col-hide) && !$canElide} {
		    incr col
		    continue
		}

		#
		# Update the column width or clip the element if necessary
		#
		set multiline [string match "*\n*" $text]
		if {$pixels == 0} {		;# convention: dynamic width
		    if {$multiline} {
			set list [split $text "\n"]
			set textWidth [getListWidth $win $list $widgetFont]
		    } else {
			set textWidth \
			    [font measure $widgetFont -displayof $win $text]
		    }
		    if {$data($col-maxPixels) > 0} {
			if {$textWidth > $data($col-maxPixels)} {
			    set pixels $data($col-maxPixels)
			}
		    }
		    if {$textWidth == $data($col-elemWidth)} {
			incr data($col-widestCount)
		    } elseif {$textWidth > $data($col-elemWidth)} {
			set data($col-elemWidth) $textWidth
			set data($col-widestCount) 1
		    }
		}
		if {$pixels != 0} {
		    incr pixels $data($col-delta)

		    if {$data($col-wrap) && !$multiline} {
			if {[font measure $widgetFont -displayof $win $text] >
			    $pixels} {
			    set multiline 1
			}
		    }

		    set snipSide \
			$snipSides($alignment,$data($col-changesnipside))
		    if {$multiline} {
			set list [split $text "\n"]
			if {$data($col-wrap)} {
			    set snipSide ""
			}
			set text [joinList $win $list $widgetFont \
				  $pixels $snipSide $snipStr]
		    } elseif {$data(-displayondemand)} {
			set text ""
		    } else {
			set text [strRange $win $text $widgetFont \
				  $pixels $snipSide $snipStr]
		    }
		}

		if {$multiline} {
		    append insertStr "\t\t"
		    lappend multilineData $col $text $widgetFont \
					  $pixels $alignment
		} else {
		    append insertStr "\t$text\t"
		}
		incr col
	    }

	    #
	    # Insert the item into the body text widget
	    #
	    $w insert $line.0 $insertStr
	}

	#
	# Embed the message widgets displaying multiline elements
	#
	foreach {col text font pixels alignment} $multilineData {
	    findTabs $win $line $col $col tabIdx1 tabIdx2
	    set msgScript [list ::tablelist::displayText $win $key \
			   $col $text $font $pixels $alignment]
	    $w window create $tabIdx2 -align top -pady $padY -create $msgScript
	    $w tag add elidedWin $tabIdx2
	}
    }
    unset data(rowsToDisplay)

    #
    # Adjust the heights of the body text widget
    # and of the listbox child, if necessary
    #
    if {$data(-height) <= 0} {
	set viewableRowCount \
	    [expr {$data(itemCount) - $data(nonViewableRowCount)}]
	$w configure -height $viewableRowCount
	$data(lb) configure -height $viewableRowCount
    }

    #
    # Check whether the width of any column has changed
    #
    set colWidthsChanged 0
    set col 0
    foreach {pixels alignment} $data(colList) {
	if {$pixels == 0} {			;# convention: dynamic width
	    if {$data($col-elemWidth) > $data($col-reqPixels)} {
		set data($col-reqPixels) $data($col-elemWidth)
		set colWidthsChanged 1
	    }
	}
	incr col
    }

    #
    # Invalidate the list of row indices indicating the
    # viewable rows, adjust the columns if necessary, and
    # schedule some operations for execution at idle time
    #
    set data(viewableRowList) {-1}
    if {$colWidthsChanged} {
	adjustColumns $win {} 1
    }
    makeStripesWhenIdle $win
    showLineNumbersWhenIdle $win
    updateViewWhenIdle $win

    if {$wasEmpty} {
	$w xview moveto [lindex [$data(hdrTxt) xview] 0]
    }
}

#------------------------------------------------------------------------------
# tablelist::insertCols
#
# Processes the tablelist insertcolumns and insertcolumnlist subcommands.
#------------------------------------------------------------------------------
proc tablelist::insertCols {win colIdx argList} {
    set argCount [llength $argList]
    if {$argCount == 0} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data \
	  ::tablelist::ns${win}::attribs attribs

    #
    # Check the syntax of argList and get the number of columns to be inserted
    #
    variable alignments
    set count 0
    for {set n 0} {$n < $argCount} {incr n} {
	#
	# Check the column width
	#
	format "%d" [lindex $argList $n]    ;# integer check with error message

	#
	# Check whether the column title is present
	#
	if {[incr n] == $argCount} {
	    return -code error "column title missing"
	}

	#
	# Check the column alignment
	#
	set alignment left
	if {[incr n] < $argCount} {
	    set next [lindex $argList $n]
	    if {[isInteger $next]} {
		incr n -1
	    } else {
		mwutil::fullOpt "alignment" $next $alignments
	    }
	}

	incr count
    }

    #
    # Shift the elements of data and attribs corresponding to the
    # column indices >= colIdx to the right by count positions
    #
    set selCells [curCellSelection $win]
    for {set oldCol $data(lastCol); set newCol [expr {$oldCol + $count}]} \
	{$oldCol >= $colIdx} {incr oldCol -1; incr newCol -1} {
	moveColData data data imgs $oldCol $newCol
	moveColAttribs attribs attribs $oldCol $newCol
	set selCells [replaceColInCellList $selCells $oldCol $newCol]
    }

    #
    # Update the item list
    #
    set emptyStrs {}
    for {set n 0} {$n < $count} {incr n} {
	lappend emptyStrs ""
    }
    set newItemList {}
    foreach item $data(itemList) {
	set item [eval [list linsert $item $colIdx] $emptyStrs]
	lappend newItemList $item
    }
    set data(itemList) $newItemList

    #
    # Update the list variable if present
    #
    condUpdateListVar $win

    #
    # Set up and adjust the columns, and rebuild some columns-related lists
    #
    setupColumns $win \
	[eval [list linsert $data(-columns) [expr {3*$colIdx}]] $argList] 1
    makeColFontAndTagLists $win
    makeSortAndArrowColLists $win
    set limit [expr {$colIdx + $count}]
    set colIdxList {}
    for {set col $colIdx} {$col < $limit} {incr col} {
	lappend colIdxList $col
    }
    adjustColumns $win $colIdxList 1

    #
    # Redisplay the items
    #
    redisplay $win 0 $selCells

    #
    # Reconfigure the relevant column labels
    #
    for {set col $limit} {$col < $data(colCount)} {incr col} {
	reconfigColLabels $win imgs $col
    }

    #
    # Update the indices anchorCol and activeCol
    #
    if {$colIdx <= $data(anchorCol)} {
	incr data(anchorCol) $argCount
	adjustColIndex $win data(anchorCol) 1
    }
    if {$colIdx <= $data(activeCol)} {
	incr data(activeCol) $argCount
	adjustColIndex $win data(activeCol) 1
    }

    updateViewWhenIdle $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::doScan
#
# Processes the tablelist scan subcommand.
#------------------------------------------------------------------------------
proc tablelist::doScan {win opt x y} {
    upvar ::tablelist::ns${win}::data data
    set w $data(body)
    incr x -[winfo x $w]
    incr y -[winfo y $w]

    if {$data(-titlecolumns) == 0} {
	set textIdx [$data(body) index @0,$y]
	set row [expr {int($textIdx) - 1}]
	$w scan $opt $x $y
	$data(hdrTxt) scan $opt $x 0

	if {[string compare $opt "dragto"] == 0} {
	    adjustElidedText $win
	    redisplayVisibleItems $win
	    updateColors $win
	    adjustSepsWhenIdle $win
	    updateVScrlbarWhenIdle $win
	    updateIdletasksDelayed 
	}
    } elseif {[string compare $opt "mark"] == 0} {
	$w scan mark 0 $y

	set data(scanMarkX) $x
	set data(scanMarkXOffset) \
	    [scrlColOffsetToXOffset $win $data(scrlColOffset)]
    } else {
	set textIdx [$data(body) index @0,$y]
	set row [expr {int($textIdx) - 1}]
	$w scan dragto 0 $y

	#
	# Compute the new scrolled x offset by amplifying the
	# difference between the current horizontal position and
	# the place where the scan started (the "mark" position)
	#
	set scrlXOffset \
	    [expr {$data(scanMarkXOffset) - 10*($x - $data(scanMarkX))}]
	set maxScrlXOffset [scrlColOffsetToXOffset $win \
			    [getMaxScrlColOffset $win]]
	if {$scrlXOffset > $maxScrlXOffset} {
	    set scrlXOffset $maxScrlXOffset
	    set data(scanMarkX) $x
	    set data(scanMarkXOffset) $maxScrlXOffset
	} elseif {$scrlXOffset < 0} {
	    set scrlXOffset 0
	    set data(scanMarkX) $x
	    set data(scanMarkXOffset) 0
	}

	#
	# Change the scrolled column offset and adjust the elided text
	#
	changeScrlColOffset $win [scrlXOffsetToColOffset $win $scrlXOffset]
	adjustElidedText $win
	redisplayVisibleItems $win
	updateColors $win
	adjustSepsWhenIdle $win
	updateVScrlbarWhenIdle $win
	updateIdletasksDelayed 
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::populate
#
# Helper procedure invoked in searchcolumnSubCmd.
#------------------------------------------------------------------------------
proc tablelist::populate {win index fully} {
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $index]
    set col $data(treeCol)
    if {![info exists data($key,$col-indent)] ||
	[string match "*indented*" $data($key,$col-indent)]} {
	return ""
    }

    if {[llength $data($key-children)] == 0} {
	uplevel #0 $data(-populatecommand) [list $win $index]
    }

    if {$fully} {
	#
	# Invoke this procedure recursively on the children
	#
	foreach childKey $data($key-children) {
	    populate $win [keyToRow $win $childKey] 1
	}
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::doesMatch
#
# Helper procedure invoked in searchcolumnSubCmd.
#------------------------------------------------------------------------------
proc doesMatch {win row col pattern value mode numeric noCase checkCmd} {
    switch -- $mode {
	-exact {
	    if {$numeric} {
		set result [expr {$pattern == $value}]
	    } else {
		if {$noCase} {
		    set value [string tolower $value]
		}
		set result [expr {[string compare $pattern $value] == 0}]
	    }
	}

	-glob {
	    if {$noCase} {
		set value [string tolower $value]
	    }
	    set result [string match $pattern $value]
	}

	-regexp {
	    if {$noCase} {
		set result [regexp -nocase $pattern $value]
	    } else {
		set result [regexp $pattern $value]
	    }
	}
    }

    if {!$result || [string length $checkCmd] == 0} {
	return $result
    } else {
	return [uplevel #0 $checkCmd [list $win $row $col $value]]
    }
}

#------------------------------------------------------------------------------
# tablelist::seeRow
#
# Processes the tablelist see subcommand.
#------------------------------------------------------------------------------
proc tablelist::seeRow {win index} {
    #
    # This might be an "after 0" callback; check whether the window exists
    #
    if {![array exists ::tablelist::ns${win}::data]} {
	return ""
    }

    #
    # Adjust the index to fit within the existing items
    #
    adjustRowIndex $win index
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $index]
    if {$data(itemCount) == 0 || [info exists data($key-hide)]} {
	return ""
    }

    #
    # Expand as many ancestors as needed
    #
    while {[info exists data($key-elide)]} {
	set key $data($key-parent)
	expandSubCmd $win [list $key -partly]
    }

    #
    # Bring the given row into the window and restore
    # the horizontal view in the body text widget
    #
    if {![seeTextIdx $win [expr {$index + 1}].0]} {
	return ""
    }
    $data(body) xview moveto [lindex [$data(hdrTxt) xview] 0]

    updateView $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::seeCell
#
# Processes the tablelist seecell subcommand.
#------------------------------------------------------------------------------
proc tablelist::seeCell {win row col} {
    #
    # This might be an "after 0" callback; check whether the window exists
    #
    if {![array exists ::tablelist::ns${win}::data]} {
	return ""
    }

    #
    # Adjust the row and column indices to fit within the existing elements
    #
    adjustRowIndex $win row
    adjustColIndex $win col
    upvar ::tablelist::ns${win}::data data
    set key [lindex $data(keyList) $row]
    if {[info exists data($key-hide)] ||
	($data(colCount) != 0 && $data($col-hide))} {
	return ""
    }

    #
    # Expand as many ancestors as needed
    #
    while {[info exists data($key-elide)]} {
	set key $data($key-parent)
	expandSubCmd $win [list $key -partly]
    }

    set b $data(body)
    if {$data(colCount) == 0} {
	$b see [expr {$row + 1}].0
	return ""
    }

    #
    # Force any geometry manager calculations to be completed first
    #
    update idletasks
    if {![array exists ::tablelist::ns${win}::data]} {
	return ""
    }

    #
    # If the tablelist is empty then insert a temporary row
    #
    set h $data(hdrTxt)
    if {$data(itemCount) == 0} {
	variable canElide
	for {set n 0} {$n < $data(colCount)} {incr n} {
	    if {!$data($n-hide) || $canElide} {
		$b insert end "\t\t"
	    }
	}

	$b xview moveto [lindex [$h xview] 0]
    }

    if {$data(-titlecolumns) == 0} {
	findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
	set nextIdx [$b index $tabIdx2+1c]
	set alignment [lindex $data(colList) [expr {2*$col + 1}]]
	set lX [winfo x $data(hdrTxtFrmLbl)$col]
	set rX [expr {$lX + [winfo width $data(hdrTxtFrmLbl)$col] - 1}]

	switch $alignment {
	    left {
		#
		# Bring the cell's left edge into view
		#
		if {![seeTextIdx $win $tabIdx1]} {
		    return ""
		}
		$h xview moveto [lindex [$b xview] 0]

		#
		# Shift the view in the header text widget until the right
		# edge of the cell becomes visible but finish the scrolling
		# before the cell's left edge would become invisible
		#
		while {![isHdrTxtFrXPosVisible $win $rX]} {
		    $h xview scroll 1 units
		    if {![isHdrTxtFrXPosVisible $win $lX]} {
			$h xview scroll -1 units
			break
		    }
		}
	    }

	    center {
		#
		# Bring the cell's left edge into view
		#
		if {![seeTextIdx $win $tabIdx1]} {
		    return ""
		}
		set winWidth [winfo width $h]
		if {[winfo width $data(hdrTxtFrmLbl)$col] > $winWidth} {
		    #
		    # The cell doesn't fit into the window:  Bring its
		    # center into the window's middle horizontal position
		    #
		    $h xview moveto \
		       [expr {double($lX + $rX - $winWidth)/2/$data(hdrPixels)}]
		} else {
		    #
		    # Shift the view in the header text widget until
		    # the right edge of the cell becomes visible
		    #
		    $h xview moveto [lindex [$b xview] 0]
		    while {![isHdrTxtFrXPosVisible $win $rX]} {
			$h xview scroll 1 units
		    }
		}
	    }

	    right {
		#
		# Bring the cell's right edge into view
		#
		if {![seeTextIdx $win $nextIdx]} {
		    return ""
		}
		$h xview moveto [lindex [$b xview] 0]

		#
		# Shift the view in the header text widget until the left
		# edge of the cell becomes visible but finish the scrolling
		# before the cell's right edge would become invisible
		#
		while {![isHdrTxtFrXPosVisible $win $lX]} {
		    $h xview scroll -1 units
		    if {![isHdrTxtFrXPosVisible $win $rX]} {
			$h xview scroll 1 units
			break
		    }
		}
	    }
	}

	$b xview moveto [lindex [$h xview] 0]

    } else {
	#
	# Bring the cell's row into view
	#
	if {![seeTextIdx $win [expr {$row + 1}].0]} {
	    return ""
	}

	set scrlWindowWidth [getScrlWindowWidth $win]

	if {($col < $data(-titlecolumns)) ||
	    (!$data($col-elide) &&
	     [getScrlContentWidth $win $data(scrlColOffset) $col] <=
	     $scrlWindowWidth)} {
	    #
	    # The given column index specifies either a title column or
	    # one that is fully visible; restore the horizontal view
	    #
	    $b xview moveto [lindex [$h xview] 0]
	} elseif {$data($col-elide) ||
		  [winfo width $data(hdrTxtFrmLbl)$col] > $scrlWindowWidth} {
	    #
	    # The given column index specifies either an elided column or one
	    # that doesn't fit into the window; shift the horizontal view to
	    # make the column the first visible one among all scrollable columns
	    #
	    set scrlColOffset 0
	    for {incr col -1} {$col >= $data(-titlecolumns)} {incr col -1} {
		if {!$data($col-hide)} {
		    incr scrlColOffset
		}
	    }
	    changeScrlColOffset $win $scrlColOffset
	} else {
	    #
	    # The given column index specifies a non-elided
	    # scrollable column; shift the horizontal view
	    # repeatedly until the column becomes visible
	    #
	    set scrlColOffset [expr {$data(scrlColOffset) + 1}]
	    while {[getScrlContentWidth $win $scrlColOffset $col] >
		   $scrlWindowWidth} {
		incr scrlColOffset
	    }
	    changeScrlColOffset $win $scrlColOffset
	}
    }

    #
    # Delete the temporary row if any
    #
    if {$data(itemCount) == 0} {
	$b delete 1.0 end
    }

    updateView $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::rowSelection
#
# Processes the tablelist selection subcommand.
#------------------------------------------------------------------------------
proc tablelist::rowSelection {win opt first last} {
    upvar ::tablelist::ns${win}::data data
    if {$data(isDisabled) && [string compare $opt "includes"] != 0} {
	return ""
    }

    switch $opt {
	anchor {
	    #
	    # Adjust the index to fit within the existing viewable items
	    #
	    adjustRowIndex $win first 1

	    set data(anchorRow) $first
	    return ""
	}

	clear {
	    #
	    # Swap the indices if necessary
	    #
	    if {$last < $first} {
		set tmp $first
		set first $last
		set last $tmp
	    }

	    set fromTextIdx [expr {$first + 1}].0
	    set toTextIdx [expr {$last + 1}].end
	    $data(body) tag remove select $fromTextIdx $toTextIdx

	    updateColorsWhenIdle $win
	    return ""
	}

	includes {
	    set w $data(body)
	    set line [expr {$first + 1}]
	    set selRange [$w tag nextrange select $line.0 $line.end]
	    return [expr {[llength $selRange] > 0}]
	}

	set {
	    #
	    # Swap the indices if necessary and adjust
	    # the range to fit within the existing items
	    #
	    if {$last < $first} {
		set tmp $first
		set first $last
		set last $tmp
	    }
	    if {$first < 0} {
		set first 0
	    }
	    if {$last > $data(lastRow)} {
		set last $data(lastRow)
	    }

	    set w $data(body)
	    variable canElide
	    variable elide
	    for {set row $first; set line [expr {$first + 1}]} \
		{$row <= $last} {set row $line; incr line} {
		#
		# Check whether the row is selectable
		#
		set key [lindex $data(keyList) $row]
		if {![info exists data($key-selectable)]} {
		    $w tag add select $line.0 $line.end
		}
	    }

	    #
	    # If the selection is exported and there are any selected
	    # cells in the widget then make win the new owner of the
	    # PRIMARY selection and register a callback to be invoked
	    # when it loses ownership of the PRIMARY selection
	    #
	    if {$data(-exportselection) &&
		[llength [$w tag nextrange select 1.0]] != 0} {
		selection own -command \
			[list ::tablelist::lostSelection $win] $win
	    }

	    updateColorsWhenIdle $win
	    return ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::horizMoveTo
#
# Adjusts the view in the tablelist window win so that data(fraction) of the
# horizontal span of the text is off-screen to the left.
#------------------------------------------------------------------------------
proc tablelist::horizMoveTo win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(moveToId)]} {
	after cancel $data(moveToId)
	unset data(moveToId)
    }

    foreach w [list $data(hdrTxt) $data(body)] {
	$w xview moveto $data(fraction)
    }

    redisplayVisibleItems $win
    updateColors $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::vertMoveTo
#
# Adjusts the view in the tablelist window win so that the non-hidden item
# given by data(fraction) appears at the top of the window.  
#------------------------------------------------------------------------------
proc tablelist::vertMoveTo win {
    upvar ::tablelist::ns${win}::data data
    if {[info exists data(moveToId)]} {
	after cancel $data(moveToId)
	unset data(moveToId)
    }

    set totalViewableCount [getViewableRowCount $win 0 $data(lastRow)]
    set offset [expr {int($data(fraction)*$totalViewableCount + 0.5)}]
    set row [viewableRowOffsetToRowIndex $win $offset]

    set w $data(body)
    set topRow [getVertComplTopRow $win]

    if {$row != $topRow} {
	$w yview $row
	updateView $win
	updateIdletasksDelayed 
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::seeTextIdx
#
# Wraps the "see" command of the body text widget of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::seeTextIdx {win textIdx} {
    upvar ::tablelist::ns${win}::data data
    set w $data(body)
    $w see $textIdx

    if {[llength [$w tag nextrange elidedWin 1.0]] == 0} {
	return 1
    }

    set fromTextIdx "[$w index @0,0] linestart"
    set toTextIdx "[$w index @0,$data(btmY)] lineend"
    $w tag remove elidedWin $fromTextIdx $toTextIdx
    update idletasks
    if {![array exists ::tablelist::ns${win}::data]} {
	return 0
    }

    $w see $textIdx
    return 1
}

#------------------------------------------------------------------------------
# tablelist::updateIdletasksDelayed
#
# Schedules the execution of "update idletasks" 100 ms later.
#------------------------------------------------------------------------------
proc tablelist::updateIdletasksDelayed {} {
    variable idletasksId
    if {![info exists idletasksId]} {
	set idletasksId [after 100 [list tablelist::updateIdletasks]]
    }
}

#------------------------------------------------------------------------------
# tablelist::updateIdletasks
#
# Invokes "update idletasks".
#------------------------------------------------------------------------------
proc tablelist::updateIdletasks {} {
    variable idletasksId
    if {[info exists idletasksId]} {
	after cancel $idletasksId
	unset idletasksId
    }

    update idletasks
}

#
# Private callback procedures
# ===========================
#

#------------------------------------------------------------------------------
# tablelist::hdrConfigure
#
# <Configure> callback for the header component of a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::hdrConfigure {w width} {
    set win [winfo parent $w]
    upvar ::tablelist::ns${win}::data data

    if {$width - 1 != $data(rightX)} {
	stretchColumnsWhenIdle $win
	updateScrlColOffsetWhenIdle $win
	updateHScrlbarWhenIdle $win
    }
}

#------------------------------------------------------------------------------
# tablelist::bodyConfigure
#
# <Configure> callback for the body component of a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::bodyConfigure {w width height} {
    set win [winfo parent $w]
    upvar ::tablelist::ns${win}::data data

    set rightX [expr {$width - 1}]
    set btmY [expr {$height - 1}]
    if {$rightX != $data(rightX) || $btmY != $data(btmY)} {
	set data(gotResizeEvent) 1
	set data(rightX) $rightX
	set data(btmY) $btmY
	makeColFontAndTagLists $win
	updateViewWhenIdle $win
    }
}

#------------------------------------------------------------------------------
# tablelist::fetchSelection
#
# This procedure is invoked when the PRIMARY selection is owned by the
# tablelist widget win and someone attempts to retrieve it as a STRING.  It
# returns part or all of the selection, as given by offset and maxChars.  The
# string which is to be (partially) returned is built by joining all of the
# selected viewable elements of the (partly) selected viewable rows together
# with tabs and the rows themselves with newlines.
#------------------------------------------------------------------------------
proc tablelist::fetchSelection {win offset maxChars} {
    upvar ::tablelist::ns${win}::data data
    if {!$data(-exportselection)} {
	return ""
    }

    set selection ""
    set prevRow -1
    foreach cellIdx [curCellSelection $win 0 2] {
	scan $cellIdx "%d,%d" row col
	if {$row != $prevRow} {
	    if {$prevRow != -1} {
		append selection "\n"
	    }

	    set prevRow $row
	    set item [lindex $data(itemList) $row]
	    set key [lindex $item end]
	    set isFirstCol 1
	}

	set text [lindex $item $col]
	if {[lindex $data(fmtCmdFlagList) $col]} {
	    set text [formatElem $win $key $row $col $text]
	}

	if {!$isFirstCol} {
	    append selection "\t"
	}
	append selection $text

	set isFirstCol 0
    }

    return [string range $selection $offset [expr {$offset + $maxChars - 1}]]
}

#------------------------------------------------------------------------------
# tablelist::lostSelection
#
# This procedure is invoked when the tablelist widget win loses ownership of
# the PRIMARY selection.  It deselects all items of the widget with the aid of
# the rowSelection procedure if the selection is exported.
#------------------------------------------------------------------------------
proc tablelist::lostSelection win {
    upvar ::tablelist::ns${win}::data data
    if {$data(-exportselection)} {
	rowSelection $win clear 0 $data(lastRow)
	event generate $win <<TablelistSelectionLost>>
    }
}

#------------------------------------------------------------------------------
# tablelist::activeTrace
#
# This procedure is executed whenever the array element data(activeRow),
# data(activeCol), or data(-selecttype) is written.  It moves the "active" tag
# to the line or cell that displays the active item or element of the widget in
# its body text child if the latter has the keyboard focus.
#------------------------------------------------------------------------------
proc tablelist::activeTrace {win varName index op} {
    #
    # Conditionally move the "active" tag to the line
    # or cell that displays the active item or element
    #
    upvar ::tablelist::ns${win}::data data
    if {$data(ownsFocus) && ![info exists data(dispId)]} {
	moveActiveTag $win
    }
}

#------------------------------------------------------------------------------
# tablelist::listVarTrace
#
# This procedure is executed whenever the global variable specified by varName
# is written or unset.  It makes sure that the contents of the widget will be
# synchronized with the value of the variable at idle time, and that the
# variable is recreated if it was unset.
#------------------------------------------------------------------------------
proc tablelist::listVarTrace {win varName index op} {
    upvar ::tablelist::ns${win}::data data
    switch $op {
	w {
	    if {![info exists data(syncId)]} {
		#
		# Arrange for the contents of the widget to be synchronized
		# with the value of the variable ::$varName at idle time
		#
		set data(syncId) [after idle [list tablelist::synchronize $win]]
	    }
	}

	u {
	    #
	    # Recreate the variable ::$varName by setting it according to
	    # the value of data(itemList), and set the trace on it again
	    #
	    if {[string length $index] != 0} {
		set varName ${varName}($index)
	    }
	    set ::$varName {}
	    foreach item $data(itemList) {
		lappend ::$varName [lrange $item 0 $data(lastCol)]
	    }
	    trace variable ::$varName wu $data(listVarTraceCmd)
	}
    }
}
::tablelist::createBindings
