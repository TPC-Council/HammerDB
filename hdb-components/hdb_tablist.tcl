#==============================================================================
# Main Tablelist and Tablelist_tile package module.
#
# Copyright (c) 2000-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

namespace eval ::tablelist {
    #
    # Public variables:
    #
    variable version	4.6
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
    namespace export	getTablelistPath convEventFields

    #
    # Register various widgets for interactive cell editing:
    #
    namespace export	addBWidgetEntry addBWidgetSpinBox addBWidgetComboBox
    namespace export    addIncrEntryfield addIncrDateTimeWidget \
			addIncrSpinner addIncrSpinint addIncrCombobox
    namespace export	addOakleyCombobox
    namespace export	addDateMentry addTimeMentry addFixedPointMentry \
    			addIPAddrMentry
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

#
# Everything else needed is lazily loaded on demand, via the dispatcher
# set up in the subdirectory "scripts" (see the file "tclIndex").
#
#==============================================================================
# Main Tablelist and Tablelist_tile package module.
#
# Copyright (c) 2000-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================
#
namespace eval ::tablelist {
    #
    # Public variables:
    #
    variable version	4.6
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
    namespace export	getTablelistPath convEventFields

    #
    # Register various widgets for interactive cell editing:
    #
    namespace export	addBWidgetEntry addBWidgetSpinBox addBWidgetComboBox
    namespace export    addIncrEntryfield addIncrDateTimeWidget \
			addIncrSpinner addIncrSpinint addIncrCombobox
    namespace export	addOakleyCombobox
    namespace export	addDateMentry addTimeMentry addFixedPointMentry \
    			addIPAddrMentry
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

#
# Everything else needed is lazily loaded on demand, via the dispatcher
# set up in the subdirectory "scripts" (see the file "tclIndex").
#
#==============================================================================
# Main Tablelist_tile package module.
#
# Copyright (c) 2000-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

package require Tcl 8.4
package require Tk  8.4
if {$::tk_version < 8.5 || [regexp {^8\.5a[1-5]$} $::tk_patchLevel]} {
    package require tile 0.6
}
package require tablelist::common

package provide Tablelist_tile $::tablelist::version
package provide tablelist_tile $::tablelist::version

::tablelist::useTile 1

#
# Define some aliases
#
if {[info commands ::ttk::style] ne ""} {
    interp alias {} ::tablelist::style		 {} ::ttk::style
    interp alias {} ::tablelist::styleConfig	 {} ::ttk::style configure
    interp alias {} ::tablelist::getThemes	 {} ::ttk::themes
    interp alias {} ::tablelist::setTheme	 {} ::ttk::setTheme

    interp alias {} ::tablelist::tileqt_currentThemeName \
		 {} ::ttk::theme::tileqt::currentThemeName
    interp alias {} ::tablelist::tileqt_currentThemeColour \
		 {} ::ttk::theme::tileqt::currentThemeColour
} else {
    interp alias {} ::tablelist::style		 {} ::style
    if {[string compare $::tile::version "0.7"] >= 0} {
	interp alias {} ::tablelist::styleConfig {} ::style configure
    } else {
	interp alias {} ::tablelist::styleConfig {} ::style default
    }
    interp alias {} ::tablelist::getThemes	 {} ::tile::availableThemes
    interp alias {} ::tablelist::setTheme	 {} ::tile::setTheme

    interp alias {} ::tablelist::tileqt_currentThemeName \
		 {} ::tile::theme::tileqt::currentThemeName
    interp alias {} ::tablelist::tileqt_currentThemeColour \
		 {} ::tile::theme::tileqt::currentThemeColour
}

namespace eval ::tablelist {
    #
    # Commands related to tile themes:
    #
    namespace export	getThemes getCurrentTheme setTheme setThemeDefaults
}
#==============================================================================
# Main Tablelist_tile package module.
#
# Copyright (c) 2000-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

package require Tcl 8.4
package require Tk  8.4
if {$::tk_version < 8.5 || [regexp {^8\.5a[1-5]$} $::tk_patchLevel]} {
    package require tile 0.6
}
package require tablelist::common

package provide Tablelist_tile $::tablelist::version
package provide tablelist_tile $::tablelist::version
#
# Define some aliases
#
if {[info commands ::ttk::style] ne ""} {
    interp alias {} ::tablelist::style		 {} ::ttk::style
    interp alias {} ::tablelist::styleConfig	 {} ::ttk::style configure
    interp alias {} ::tablelist::getThemes	 {} ::ttk::themes
    interp alias {} ::tablelist::setTheme	 {} ::ttk::setTheme

    interp alias {} ::tablelist::tileqt_currentThemeName \
		 {} ::ttk::theme::tileqt::currentThemeName
    interp alias {} ::tablelist::tileqt_currentThemeColour \
		 {} ::ttk::theme::tileqt::currentThemeColour
} else {
    interp alias {} ::tablelist::style		 {} ::style
    if {[string compare $::tile::version "0.7"] >= 0} {
	interp alias {} ::tablelist::styleConfig {} ::style configure
    } else {
	interp alias {} ::tablelist::styleConfig {} ::style default
    }
    interp alias {} ::tablelist::getThemes	 {} ::tile::availableThemes
    interp alias {} ::tablelist::setTheme	 {} ::tile::setTheme

    interp alias {} ::tablelist::tileqt_currentThemeName \
		 {} ::tile::theme::tileqt::currentThemeName
    interp alias {} ::tablelist::tileqt_currentThemeColour \
		 {} ::tile::theme::tileqt::currentThemeColour
}

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
# Copyright (c) 2000-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
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
    variable version	2.3
    variable library	[file dirname [info script]]

    #
    # Public procedures:
    #
    namespace export	wrongNumArgs getAncestorByClass convEventFields \
			defineKeyNav processTraversal focusNext focusPrev \
			configureWidget fullConfigOpt fullOpt enumOpts \
			configureSubCmd attribSubCmd getScrollInfo

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
    regexp {^(.+)\..+$} $w dummy win
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
	    if {[string compare $dbValue ""] == 0} {
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
		if {$::tk_version < 8.1} {
		    set dbName [lindex $configSpecs($alias) 0]
		    lappend result [list $opt $dbName]
		} else {
		    lappend result [list $opt $alias]
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
# This procedure is invoked to process the attrib subcommand.
#------------------------------------------------------------------------------
proc mwutil::attribSubCmd {win argList} {
    set classNs [string tolower [winfo class $win]]
    upvar ::${classNs}::ns${win}::attribVals attribVals

    set argCount [llength $argList]
    if {$argCount > 1} {
	#
	# Set the specified attributes to the given values
	#
	if {$argCount % 2 != 0} {
	    return -code error "value for \"[lindex $argList end]\" missing"
	}
	array set attribVals $argList
	return ""
    } elseif {$argCount == 1} {
	#
	# Return the value of the specified attribute
	#
	set attr [lindex $argList 0]
	if {[info exists attribVals($attr)]} {
	    return $attribVals($attr)
	} else {
	    return ""
	}
    } else {
	#
	# Return the current list of attribute names and values
	#
	set result {}
	foreach attr [lsort [array names attribVals]] {
	    lappend result [list $attr $attribVals($attr)]
	}
	return $result
    }
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
# Contains utility procedures for mega-widgets.
#
# Structure of the module:
#   - Namespace initialization
#   - Public utility procedures
#
# Copyright (c) 2000-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
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
    variable version	2.3
    variable library	[file dirname [info script]]

    #
    # Public procedures:
    #
    namespace export	wrongNumArgs getAncestorByClass convEventFields \
			defineKeyNav processTraversal focusNext focusPrev \
			configureWidget fullConfigOpt fullOpt enumOpts \
			configureSubCmd attribSubCmd getScrollInfo

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
    regexp {^(.+)\..+$} $w dummy win
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
	    if {[string compare $dbValue ""] == 0} {
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
		if {$::tk_version < 8.1} {
		    set dbName [lindex $configSpecs($alias) 0]
		    lappend result [list $opt $dbName]
		} else {
		    lappend result [list $opt $alias]
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
# This procedure is invoked to process the attrib subcommand.
#------------------------------------------------------------------------------
proc mwutil::attribSubCmd {win argList} {
    set classNs [string tolower [winfo class $win]]
    upvar ::${classNs}::ns${win}::attribVals attribVals

    set argCount [llength $argList]
    if {$argCount > 1} {
	#
	# Set the specified attributes to the given values
	#
	if {$argCount % 2 != 0} {
	    return -code error "value for \"[lindex $argList end]\" missing"
	}
	array set attribVals $argList
	return ""
    } elseif {$argCount == 1} {
	#
	# Return the value of the specified attribute
	#
	set attr [lindex $argList 0]
	if {[info exists attribVals($attr)]} {
	    return $attribVals($attr)
	} else {
	    return ""
	}
    } else {
	#
	# Return the current list of attribute names and values
	#
	set result {}
	foreach attr [lsort [array names attribVals]] {
	    lappend result [list $attr $attribVals($attr)]
	}
	return $result
    }
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

#==============================================================================
# Contains utility procedures for mega-widgets.
#
# Structure of the module:
#   - Namespace initialization
#   - Public utility procedures
#
# Copyright (c) 2000-2007  Csaba Nem#==============================================================================
# Contains public and private procedures used in tablelist bindings.
#
# Structure of the module:
#   - Public helper procedures
#   - Binding tag Tablelist
#   - Binding tag TablelistWindow
#   - Binding tag TablelistBody
#   - Binding tags TablelistLabel, TablelistSubLabel, and TablelistArrow
#
# Copyright (c) 2000-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#
# Public helper procedures
# ========================
#

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

#
# Binding tag Tablelist
# =====================
#

#------------------------------------------------------------------------------
# tablelist::addActiveTag
#
# This procedure is invoked when the tablelist widget win gains the keyboard
# focus.  It adds the "active" tag to the line or cell that displays the active
# item or element of the widget in its body text child.
#------------------------------------------------------------------------------
proc tablelist::addActiveTag win {
    upvar ::tablelist::ns${win}::data data

    set line [expr {$data(activeRow) + 1}]
    set col $data(activeCol)
    if {[string compare $data(-selecttype) "row"] == 0} {
	$data(body) tag add active $line.0 $line.end
    } elseif {$data(itemCount) > 0 && $data(colCount) > 0 &&
	      !$data($col-hide)} {
	findTabs $win $line $col $col tabIdx1 tabIdx2
	$data(body) tag add active $tabIdx1 $tabIdx2+1c
    }

    set data(ownsFocus) 1
}

#------------------------------------------------------------------------------
# tablelist::removeActiveTag
#
# This procedure is invoked when the tablelist widget win loses the keyboard
# focus.  It removes the "active" tag from the body text child of the widget.
#------------------------------------------------------------------------------
proc tablelist::removeActiveTag win {
    upvar ::tablelist::ns${win}::data data

    $data(body) tag remove active 1.0 end

    set data(ownsFocus) 0
}

#------------------------------------------------------------------------------
# tablelist::cleanup
#
# This procedure is invoked when the tablelist widget win is destroyed.  It
# executes some cleanup operations.
#------------------------------------------------------------------------------
proc tablelist::cleanup win {
    upvar ::tablelist::ns${win}::data data

    #
    # Cancel the execution of all delayed adjustSeps, makeStripes,
    # showLineNumbers, stretchColumns, updateColors, updateScrlColOffset,
    # updateHScrlbar, updateVScrlbar, adjustElidedText, synchronize,
    # horizAutoScan, doCellConfig, redisplay, and redisplayCol commands
    #
    foreach id {sepsId stripesId lineNumsId stretchId colorId offsetId \
		hScrlbarId vScrlbarId elidedId syncId afterId reconfigId} {
	if {[info exists data($id)]} {
	    after cancel $data($id)
	}
    }
    foreach name [array names data *redispId] {
	after cancel $data($name)
    }

    #
    # If there is a list variable associated with the
    # widget then remove the trace set on this variable
    #
    if {$data(hasListVar) && [info exists $data(-listvariable)]} {
	upvar #0 $data(-listvariable) var
	trace vdelete var wu $data(listVarTraceCmd)
    }

    namespace delete ::tablelist::ns$win
    catch {rename ::$win ""}
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
    if {![winfo exists $win]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data

    set currentTheme [getCurrentTheme]
    if {[string compare $currentTheme $data(currentTheme)] == 0} {
	if {[string compare $currentTheme "tileqt"] == 0} {
	    set widgetStyle [tileqt_currentThemeName]
	    set colorScheme [getKdeConfigVal "KDE" "colorScheme"]
	    if {[string compare $widgetStyle $data(widgetStyle)] == 0 &&
		[string compare $colorScheme $data(colorScheme)] == 0} {
		return ""
	    }
	} else {
	    return ""
	}
    }

    variable themeDefaults
    variable configSpecs

    #
    # Populate the array tmp with values corresponding to the old theme
    # and the array themeDefaults with values corresponding to the new one
    #
    array set tmp $data(themeDefaults)
    setThemeDefaults

    #
    # Update the default values in the array configSpecs and
    # set those configuration options whose values equal the old
    # theme-specific defaults to the new theme-specific ones
    #
    foreach opt {-background -foreground -disabledforeground -stripebackground
		 -selectbackground -selectforeground -selectborderwidth -font
		 -labelbackground -labelforeground -labelfont
		 -labelborderwidth -labelpady
		 -arrowcolor -arrowdisabledcolor -arrowstyle} {
	lset configSpecs($opt) 3 $themeDefaults($opt)
	if {[string compare $data($opt) $tmp($opt)] == 0} {
	    doConfig $win $opt $themeDefaults($opt)
	}
    }
    foreach opt {-background -foreground} {
	doConfig $win $opt $data($opt)	;# sets the bg color of the separators
    }

    #
    # Destroy and recreate the edit window if present
    #
    if {[set editCol $data(editCol)] >= 0} {
	set editRow $data(editRow)
	saveEditData $win
	destroy $data(bodyFr)
	editcellSubCmd $win $editRow $editCol 1
    }

    #
    # Destroy and recreate the embedded windows
    #
    if {$data(winCount) != 0} {
	for {set row 0} {$row < $data(itemCount)} {incr row} {
	    for {set col 0} {$col < $data(colCount)} {incr col} {
		set key [lindex [lindex $data(itemList) $row] end]
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
	set data(colorScheme) [getKdeConfigVal "KDE" "colorScheme"]
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
    regexp {^(.+)\.body\.f(k[0-9]+),([0-9]+)$} $aux dummy win key col
    upvar ::tablelist::ns${win}::data data

    if {[info exists data($key,$col-windowdestroy)]} {
	set row [lsearch $data(itemList) "* $key"]
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
	selection		{}
	clicked			0
	clickTime		0
	clickedInEditWin	0
    }

    bind TablelistBody <Button-1> {
	if {[winfo exists %W]} {
	    foreach {tablelist::W tablelist::x tablelist::y} \
		[tablelist::convEventFields %W %x %y] {}

	    set tablelist::priv(x) $tablelist::x
	    set tablelist::priv(y) $tablelist::y
	    set tablelist::priv(row) [$tablelist::W nearest       $tablelist::y]
	    set tablelist::priv(col) [$tablelist::W nearestcolumn $tablelist::x]
	    set tablelist::priv(clicked) 1
	    set tablelist::priv(clickTime) %t
	    set tablelist::priv(clickedInEditWin) 0
	    if {[$tablelist::W cget -setfocus]} {
		focus [$tablelist::W bodypath]
	    }
	    tablelist::condEditContainingCell $tablelist::W \
		$tablelist::x $tablelist::y
	    tablelist::condBeginMove $tablelist::W $tablelist::priv(row)
	    tablelist::beginSelect $tablelist::W \
		$tablelist::priv(row) $tablelist::priv(col)
	}
    }
    bind TablelistBody <Double-Button-1> {
	# Empty script
    }
    bind TablelistBody <B1-Motion> {
	if {$tablelist::priv(clicked) &&
	    %t - $tablelist::priv(clickTime) < 300} {
	    continue
	}
	foreach {tablelist::W tablelist::x tablelist::y} \
	    [tablelist::convEventFields %W %x %y] {}

	if {[string compare $tablelist::priv(x) ""] == 0 ||
	    [string compare $tablelist::priv(y) ""] == 0} {
	    set tablelist::priv(x) $tablelist::x
	    set tablelist::priv(y) $tablelist::y
	}
	set tablelist::priv(prevX) $tablelist::priv(x)
	set tablelist::priv(prevY) $tablelist::priv(y)
	set tablelist::priv(x) $tablelist::x
	set tablelist::priv(y) $tablelist::y
	tablelist::condAutoScan $tablelist::W
	tablelist::motion $tablelist::W \
	    [$tablelist::W nearest       $tablelist::y] \
	    [$tablelist::W nearestcolumn $tablelist::x]
	tablelist::condShowTarget $tablelist::W $tablelist::y
    }
    bind TablelistBody <ButtonRelease-1> {
	foreach {tablelist::W tablelist::x tablelist::y} \
	    [tablelist::convEventFields %W %x %y] {}

	set tablelist::priv(x) ""
	set tablelist::priv(y) ""
	set tablelist::priv(clicked) 0
	after cancel $tablelist::priv(afterId)
	set tablelist::priv(afterId) ""
	set tablelist::priv(releasedInEditWin) 0
	if {$tablelist::priv(clicked) &&
	    %t - $tablelist::priv(clickTime) < 300} {
	    tablelist::moveOrActivate $tablelist::W \
		$tablelist::priv(row) $tablelist::priv(col)
	} else {
	    tablelist::moveOrActivate $tablelist::W \
		[$tablelist::W nearest       $tablelist::y] \
		[$tablelist::W nearestcolumn $tablelist::x]
	}
	tablelist::condEvalInvokeCmd $tablelist::W
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
    bind TablelistBody <Up> {
	tablelist::upDown [tablelist::getTablelistPath %W] -1
    }
    bind TablelistBody <Down> {
	tablelist::upDown [tablelist::getTablelistPath %W] 1
    }
    bind TablelistBody <Left> {
	tablelist::leftRight [tablelist::getTablelistPath %W] -1
    }
    bind TablelistBody <Right> {
	tablelist::leftRight [tablelist::getTablelistPath %W] 1
    }
    bind TablelistBody <Prior> {
	tablelist::priorNext [tablelist::getTablelistPath %W] -1
    }
    bind TablelistBody <Next> {
	tablelist::priorNext [tablelist::getTablelistPath %W] 1
    }
    bind TablelistBody <Home> {
	tablelist::homeEnd [tablelist::getTablelistPath %W] Home
    }
    bind TablelistBody <End> {
	tablelist::homeEnd [tablelist::getTablelistPath %W] End
    }
    bind TablelistBody <Control-Home> {
	tablelist::firstLast [tablelist::getTablelistPath %W] first
    }
    bind TablelistBody <Control-End> {
	tablelist::firstLast [tablelist::getTablelistPath %W] last
    }
    bind TablelistBody <Shift-Up> {
	tablelist::extendUpDown [tablelist::getTablelistPath %W] -1
    }
    bind TablelistBody <Shift-Down> {
	tablelist::extendUpDown [tablelist::getTablelistPath %W] 1
    }
    bind TablelistBody <Shift-Left> {
	tablelist::extendLeftRight [tablelist::getTablelistPath %W] -1
    }
    bind TablelistBody <Shift-Right> {
	tablelist::extendLeftRight [tablelist::getTablelistPath %W] 1
    }
    bind TablelistBody <Shift-Home> {
	tablelist::extendToHomeEnd [tablelist::getTablelistPath %W] Home
    }
    bind TablelistBody <Shift-End> {
	tablelist::extendToHomeEnd [tablelist::getTablelistPath %W] End
    }
    bind TablelistBody <Shift-Control-Home> {
	tablelist::extendToFirstLast [tablelist::getTablelistPath %W] first
    }
    bind TablelistBody <Shift-Control-End> {
	tablelist::extendToFirstLast [tablelist::getTablelistPath %W] last
    }
    bind TablelistBody <space> {
	set tablelist::W [tablelist::getTablelistPath %W]

	tablelist::beginSelect $tablelist::W \
	    [$tablelist::W index active] [$tablelist::W columnindex active]
    }
    bind TablelistBody <Select> {
	set tablelist::W [tablelist::getTablelistPath %W]

	tablelist::beginSelect $tablelist::W \
	    [$tablelist::W index active] [$tablelist::W columnindex active]
    }
    bind TablelistBody <Control-Shift-space> {
	set tablelist::W [tablelist::getTablelistPath %W]

	tablelist::beginExtend $tablelist::W \
	    [$tablelist::W index active] [$tablelist::W columnindex active]
    }
    bind TablelistBody <Shift-Select> {
	set tablelist::W [tablelist::getTablelistPath %W]

	tablelist::beginExtend $tablelist::W \
	    [$tablelist::W index active] [$tablelist::W columnindex active]
    }
    bind TablelistBody <Escape> {
	tablelist::cancelSelection [tablelist::getTablelistPath %W]
    }
    bind TablelistBody <Control-slash> {
	tablelist::selectAll [tablelist::getTablelistPath %W]
    }
    bind TablelistBody <Control-backslash> {
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

    foreach event {<<Copy>> <Control-Left> <Control-Right>
		   <Control-Prior> <Control-Next> <Button-2> <B2-Motion>
		   <MouseWheel> <Button-4> <Button-5>} {
	set script [strMap {
	    "%W" "$tablelist::W"  "%x" "$tablelist::x"  "%y" "$tablelist::y"
	} [bind Listbox $event]]

	if {[string compare $script ""] != 0} {
	    bind TablelistBody $event [format {
		foreach {tablelist::W tablelist::x tablelist::y} \
		    [tablelist::convEventFields %%W %%x %%y] {}
		%s
	    } $script]
	}
    }
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
    upvar ::tablelist::ns${win}::data data

    #
    # Get the containing cell from the coordinates relative to the parent
    #
    set row [containingSubCmd $win $y]
    set col [containingcolumnSubCmd $win $x]

    if {$row >= 0 && $col >= 0 && [isCellEditable $win $row $col]} {
	#
	# Get the coordinates relative to the
	# tablelist body and invoke editcellSubCmd
	#
	set w $data(body)
	incr x -[winfo x $w]
	incr y -[winfo y $w]
	scan [$w index @$x,$y] "%d.%d" line charPos
	editcellSubCmd $win $row $col 0 "" $charPos
    } else {
	#
	# Finish a possibly active cell editing
	#
	if {$data(editRow) >= 0} {
	    finisheditingSubCmd $win
	}
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
    set data(targetRow) $row

    set topWin [winfo toplevel $win]
    set data(topEscBinding) [bind $topWin <Escape>]
    bind $topWin <Escape> \
	[list tablelist::cancelMove [strMap {"%" "%%"} $win]]
}

#------------------------------------------------------------------------------
# tablelist::beginSelect
#
# This procedure is typically invoked on button-1 presses in the body of a
# tablelist widget or in one of its separators.  It begins the process of
# making a selection in the widget.  Its exact behavior depends on the
# selection mode currently in effect for the widget.
#------------------------------------------------------------------------------
proc tablelist::beginSelect {win row col} {
    upvar ::tablelist::ns${win}::data data

    switch $data(-selecttype) {
	row {
	    if {[string compare $data(-selectmode) "multiple"] == 0} {
		if {[::$win selection includes $row]} {
		    ::$win selection clear $row
		} else {
		    ::$win selection set $row
		}
	    } else {
		::$win selection clear 0 end
		::$win selection set $row
		::$win selection anchor $row
		variable priv
		set priv(selection) {}
		set priv(prevRow) $row
	    }
	}

	cell {
	    if {[string compare $data(-selectmode) "multiple"] == 0} {
		if {[::$win cellselection includes $row,$col]} {
		    ::$win cellselection clear $row,$col
		} else {
		    ::$win cellselection set $row,$col
		}
	    } else {
		::$win cellselection clear 0,0 end
		::$win cellselection set $row,$col
		::$win cellselection anchor $row,$col
		variable priv
		set priv(selection) {}
		set priv(prevRow) $row
		set priv(prevCol) $col
	    }
	}
    }

    event generate $win <<TablelistSelect>>
}

#------------------------------------------------------------------------------
# tablelist::condAutoScan
#
# This procedure is invoked when the mouse leaves or enters the scrollable part
# of a tablelist widget's body text child.  It either invokes the autoScan
# procedure or cancels its invocation as an "after" command.
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
	if {[string compare $priv(afterId) ""] == 0} {
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
# tablelist widget's body text child.  It scrolls the child up, down, left, or
# right, depending on where the mouse left the scrollable part of the
# tablelist's body, and reschedules itself as an "after" command so that the
# child continues to scroll until the mouse moves back into the window or the
# mouse button is released.
#------------------------------------------------------------------------------
proc tablelist::autoScan win {
    if {![winfo exists $win] || [string compare [::$win editwinpath] ""] != 0} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
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

    motion $win [::$win nearest $priv(y)] [::$win nearestcolumn $priv(x)]
    set priv(afterId) [after $ms [list tablelist::autoScan $win]]
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
proc tablelist::motion {win row col} {
    upvar ::tablelist::ns${win}::data data
    variable priv

    switch $data(-selecttype) {
	row {
	    if {$row == $priv(prevRow)} {
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
		    if {[string compare $priv(prevRow) ""] != 0} {
			::$win selection clear anchor $priv(prevRow)
		    }
		    ::$win selection set anchor $row
		    set priv(prevRow) $row
		    event generate $win <<TablelistSelect>>
		}
	    }
	}

	cell {
	    if {$row == $priv(prevRow) && $col == $priv(prevCol)} {
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
		    if {[string compare $priv(prevRow) ""] != 0 &&
			[string compare $priv(prevCol) ""] != 0} {
			::$win cellselection clear anchor \
			       $priv(prevRow),$priv(prevCol)
		    }
		    ::$win cellselection set anchor $row,$col
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

    set w $data(body)
    incr y -[winfo y $w]
    set textIdx [$w index @0,$y]
    set row [expr {int($textIdx) - 1}]
    set dlineinfo [$w dlineinfo $textIdx]
    set lineY [lindex $dlineinfo 1]
    set lineHeight [lindex $dlineinfo 3]
    if {$y < $lineY + $lineHeight/2} {
	set data(targetRow) $row
	set gapY $lineY
    } else {
	set data(targetRow) [expr {$row + 1}]
	set gapY [expr {$lineY + $lineHeight}]
    }

    if {$row == $data(sourceRow)} {
	$w configure -cursor $data(-cursor)
	place forget $data(rowGap)
    } else {
	$w configure -cursor $data(-movecursor)
	place $data(rowGap) -anchor w -relwidth 1.0 -y $gapY
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
proc tablelist::moveOrActivate {win row col} {
    #
    # Return if both <Button-1> and <ButtonRelease-1> occurred in the
    # temporary embedded widget used for interactive cell editing
    #
    variable priv
    if {$priv(clickedInEditWin) && $priv(releasedInEditWin)} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data

    if {[info exists data(sourceRow)]} {
	set sourceRow $data(sourceRow)
	unset data(sourceRow)
	bind [winfo toplevel $win] <Escape> $data(topEscBinding)
	$data(body) configure -cursor $data(-cursor)
	place forget $data(rowGap)

	if {$data(targetRow) != $sourceRow &&
	    $data(targetRow) != $sourceRow + 1} {
	    ::$win move $sourceRow $data(targetRow)
	    event generate $win <<TablelistRowMoved>>
	}
    } else {
	switch $data(-selecttype) {
	    row  { ::$win activate $row }
	    cell { ::$win activatecell $row,$col }
	}
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
    upvar ::tablelist::ns${win}::data data

    if {$data(editCol) < 0} {
	return ""
    }

    variable editWin
    set name [getEditWindow $win $data(editRow) $data(editCol)]
    if {[string compare $editWin($name-invokeCmd) ""] == 0 || $data(invoked)} {
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
    # Evaluate the edit window's invoke command
    #
    update 
    eval [strMap {"%W" "$data(bodyFrEd)"} $editWin($name-invokeCmd)]
    set data(invoked) 1
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

    if {[string compare $data(-selectmode) "extended"] != 0} {
	return ""
    }

    variable priv
    switch $data(-selecttype) {
	row {
	    set priv(selection) [::$win curselection]
	    set priv(prevRow) $row
	    ::$win selection anchor $row
	    if {[::$win selection includes $row]} {
		::$win selection clear $row
	    } else {
		::$win selection set $row
	    }
	}

	cell {
	    set priv(selection) [::$win curcellselection]
	    set priv(prevRow) $row
	    set priv(prevCol) $col
	    ::$win cellselection anchor $row,$col
	    if {[::$win cellselection includes $row,$col]} {
		::$win cellselection clear $row,$col
	    } else {
		::$win cellselection set $row,$col
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
	[firstVisibleRow $win] < 0 || [firstVisibleCol $win] < 0} {
	return ""
    }

    set row $data(activeRow)
    set col $data(activeCol)
    if {[isCellEditable $win $row $col]} {
	editcellSubCmd $win $row $col 0
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
		} elseif {![doRowCget $row $win -hide] && !$data($col-hide)} {
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
	} elseif {![doRowCget $row $win -hide]} {
	    condChangeSelection $win $row $col
	    return ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::leftRight
#
# If the tablelist widget's selection type is "row" then this procedure scrolls
# the widget's view left or right by the width of the character "0".  Otherwise
# it moves the location cursor (active element) left or right by one column,
# and changes the selection if we are in browse or extended selection mode.
#------------------------------------------------------------------------------
proc tablelist::leftRight {win amount} {
    upvar ::tablelist::ns${win}::data data

    switch $data(-selecttype) {
	row {
	    ::$win xview scroll $amount units
	}

	cell {
	    if {$data(editRow) >= 0} {
		return ""
	    }

	    set row $data(activeRow)
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
}

#------------------------------------------------------------------------------
# tablelist::homeEnd
#
# If selecttype is row then the procedure scrolls the tablelist widget
# horizontally to its left or right edge.  Otherwise it sets the location
# cursor (active element) to the first/last element of the active row, selects
# that element, and deselects everything else in the widget.
#------------------------------------------------------------------------------
proc tablelist::homeEnd {win key} {
    upvar ::tablelist::ns${win}::data data

    switch $data(-selecttype) {
	row {
	    switch $key {
		Home { ::$win xview moveto 0 }
		End  { ::$win xview moveto 1 }
	    }
	}

	cell {
	    set row $data(activeRow)
	    switch $key {
		Home { set col [firstVisibleCol $win] }
		End  { set col [ lastVisibleCol $win] }
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
    upvar ::tablelist::ns${win}::data data

    switch $target {
	first {
	    set row [firstVisibleRow $win]
	    set col [firstVisibleCol $win]
	}

	last {
	    set row [lastVisibleRow $win]
	    set col [lastVisibleCol $win]
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
		} elseif {![doRowCget $row $win -hide]} {
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
		} elseif {![doRowCget $row $win -hide]} {
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
proc tablelist::extendToHomeEnd {win key} {
    upvar ::tablelist::ns${win}::data data

    switch $data(-selecttype) {
	row {
	    # Nothing
	}

	cell {
	    set row $data(activeRow)
	    switch $key {
		Home { set col [firstVisibleCol $win] }
		End  { set col [ lastVisibleCol $win] }
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
    upvar ::tablelist::ns${win}::data data

    switch $target {
	first {
	    set row [firstVisibleRow $win]
	    set col [firstVisibleCol $win]
	}

	last {
	    set row [lastVisibleRow $win]
	    set col [lastVisibleCol $win]
	}
    }

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
# there is an extended selection in progress, it restores all of the items or
# elements between the active one and the anchor to their previous selection
# state.
#------------------------------------------------------------------------------
proc tablelist::cancelSelection win {
    upvar ::tablelist::ns${win}::data data

    if {[string compare $data(-selectmode) "extended"] != 0} {
	return ""
    }

    variable priv
    switch $data(-selecttype) {
	row {
	    set first $data(anchorRow)
	    set last $priv(prevRow)
	    if {[string compare $last ""] == 0} {
		return ""
	    }

	    if {$last < $first} {
		set tmp $first
		set first $last
		set last $tmp
	    }

	    ::$win selection clear $first $last
	    for {set row $first} {$row <= $last} {incr row} {
		if {[lsearch -exact $priv(selection) $row] >= 0} {
		    ::$win selection set $row
		}
	    }
	    event generate $win <<TablelistSelect>>
	}

	cell {
	    set firstRow $data(anchorRow)
	    set firstCol $data(anchorCol)
	    set lastRow $priv(prevRow)
	    set lastCol $priv(prevCol)
	    if {[string compare $lastRow ""] == 0 ||
		[string compare $lastCol ""] == 0} {
		return ""
	    }

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

	    ::$win cellselection clear $firstRow,$firstCol $lastRow,$lastCol
	    for {set row $firstRow} {$row <= $lastRow} {incr row} {
		for {set col $firstCol} {$col <= $lastCol} {incr col} {
		    if {[lsearch -exact $priv(selection) $row,$col] >= 0} {
			::$win cellselection set $row,$col
		    }
		}
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
# tablelist::firstVisibleRow
#
# Returns the index of the first non-hidden row of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::firstVisibleRow win {
    upvar ::tablelist::ns${win}::data data

    for {set row 0} {$row < $data(itemCount)} {incr row} {
	if {![doRowCget $row $win -hide]} {
	    return $row
	}
    }

    return -1
}

#------------------------------------------------------------------------------
# tablelist::lastVisibleRow
#
# Returns the index of the last non-hidden row of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::lastVisibleRow win {
    upvar ::tablelist::ns${win}::data data

    for {set row $data(lastRow)} {$row >= 0} {incr row -1} {
	if {![doRowCget $row $win -hide]} {
	    return $row
	}
    }

    return -1
}

#------------------------------------------------------------------------------
# tablelist::firstVisibleCol
#
# Returns the index of the first non-hidden column of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::firstVisibleCol win {
    upvar ::tablelist::ns${win}::data data

    for {set col 0} {$col < $data(colCount)} {incr col} {
	if {!$data($col-hide)} {
	    return $col
	}
    }

    return -1
}

#------------------------------------------------------------------------------
# tablelist::lastVisibleCol
#
# Returns the index of the last non-hidden column of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::lastVisibleCol win {
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
# a tablelist widget, or is moving within that label.  It updates the cursor
# and activates or deactivates the label, depending on whether the pointer is
# on its right border or not.
#------------------------------------------------------------------------------
proc tablelist::labelEnter {w x} {
    parseLabelPath $w win col
    upvar ::tablelist::ns${win}::data data

    configLabel $w -cursor $data(-cursor)
    if {$data(isDisabled)} {
	return ""
    }

    if {$x >= [winfo width $w] - 5} {
	set inResizeArea 1
	set col2 $col
    } elseif {$x < 5} {
	set X [expr {[winfo rootx $w] - 3}]
	set contW [winfo containing -displayof $w $X [winfo rooty $w]]
	set inResizeArea [parseLabelPath $contW dummy col2]
    } else {
	set inResizeArea 0
    }

    if {$inResizeArea && $data(-resizablecolumns) && $data($col2-resizable)} {
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
# a tablelist widget.  It deactivates the label.
#------------------------------------------------------------------------------
proc tablelist::labelLeave {w X x y} {
    parseLabelPath $w win col
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled)} {
	return ""
    }

    #
    # The following code is needed because the event
    # can also occur in a widget placed into the label
    #
    set hdrX [winfo rootx $data(hdr)]
    if {$X >= $hdrX && $X < $hdrX + [winfo width $data(hdr)] &&
	$x >= 1 && $x < [winfo width $w] - 1 &&
	$y >= 0 && $y < [winfo height $w]} {
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
    parseLabelPath $w win col
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled) ||
	[info exists data(colBeingResized)]} {	;# resize operation in progress
	return ""
    }

    set data(labelClicked) 1
    set data(X) [expr {[winfo rootx $w] + $x}]
    set data(shiftPressed) $shiftPressed

    if {$x >= [winfo width $w] - 5} {
	set inResizeArea 1
	set col2 $col
    } elseif {$x < 5} {
	set X [expr {[winfo rootx $w] - 3}]
	set contW [winfo containing -displayof $w $X [winfo rooty $w]]
	set inResizeArea [parseLabelPath $contW dummy col2]
    } else {
	set inResizeArea 0
    }

    if {$inResizeArea && $data(-resizablecolumns) && $data($col2-resizable)} {
	set data(colBeingResized) $col2
	set data(topRow) [rowIndex $win @0,0 0]
	set data(btmRow) [rowIndex $win @0,[expr {[winfo height $win] - 1}] 0]

	set w $data(hdrTxtFrLbl)$col2
	set labelWidth [winfo width $w]
	set data(oldStretchedColWidth) [expr {$labelWidth - 2*$data(charWidth)}]
	set data(oldColDelta) $data($col2-delta)
	set data(configColWidth) [lindex $data(-columns) [expr {3*$col2}]]

	if {[lsearch -exact $data(arrowColList) $col2] >= 0} {
	    set canvasWidth $data(arrowWidth)
	    if {[llength $data(arrowColList)] > 1} {
		incr canvasWidth 6
	    }
	    set data(minColWidth) $canvasWidth
	} else {
	    set data(minColWidth) 1
	}

	set data(focus) [focus -displayof $win]
	set topWin [winfo toplevel $win]
	focus $topWin
	set data(topEscBinding) [bind $topWin <Escape>]
	bind $topWin <Escape> \
	     [list tablelist::escape [strMap {"%" "%%"} $win] $col2]
    } else {
	set data(inClickedLabel) 1
	set data(relief) [$w cget -relief]

	if {[info exists data($col-labelcommand)] ||
	    [string compare $data(-labelcommand) ""] != 0} {
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
    parseLabelPath $w win col
    upvar ::tablelist::ns${win}::data data

    if {!$data(labelClicked)} {
	return ""
    }

    if {[info exists data(colBeingResized)]} {	;# resize operation in progress
	set width [expr {$data(oldStretchedColWidth) + $X - $data(X)}]
	if {$width >= $data(minColWidth)} {
	    set col $data(colBeingResized)
	    set idx [expr {3*$col}]
	    set data(-columns) [lreplace $data(-columns) $idx $idx -$width]
	    set idx [expr {2*$col}]
	    set data(colList) [lreplace $data(colList) $idx $idx $width]
	    set data($col-lastStaticWidth) $width
	    set data($col-delta) 0
	    adjustColumns $win {} 0
	    redisplayCol $win $col $data(topRow) $data(btmRow)
	}
    } else {
	#
	# Scroll the window horizontally if needed
	#
	set hdrX [winfo rootx $data(hdr)]
	if {$data(-titlecolumns) == 0 || ![winfo viewable $data(sep)]} {
	    set leftX $hdrX
	} else {
	    set leftX [expr {[winfo rootx $data(sep)] + 1}]
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
	    $data(hdrTxtFrCanv)$col configure -cursor $data(-cursor)
	    configLabel $w -cursor $data(-cursor)
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
		    set master $data(hdrTxtFr)
		    set relx 1.0
		} else {
		    for {set targetCol 0} {$targetCol < $data(colCount)} \
			{incr targetCol} {
			if {!$data($targetCol-hide)} {
			    break
			}
		    }
		    set master $data(hdrTxtFr)
		    set relx 0.0
		}

		#
		# Visualize the would-be target position
		# of the clicked label if appropriate
		#
		if {$data(-protecttitlecolumns) &&
		    (($col >= $data(-titlecolumns) &&
		      $targetCol < $data(-titlecolumns)) ||
		     ($col < $data(-titlecolumns) &&
		      $targetCol > $data(-titlecolumns)))} {
		    set data(targetCol) -1
		    configLabel $w -cursor $data(-cursor)
		    $data(hdrTxtFrCanv)$col configure -cursor $data(-cursor)
		    place forget $data(colGap)
		} else {
		    set data(targetCol) $targetCol
		    set data(master) $master
		    set data(relx) $relx
		    configLabel $w -cursor $data(-movecolumncursor)
		    $data(hdrTxtFrCanv)$col configure -cursor \
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
    parseLabelPath $w win col
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
    parseLabelPath $w win col
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
    parseLabelPath $w win col
    upvar ::tablelist::ns${win}::data data

    if {!$data(labelClicked)} {
	return ""
    }

    if {[info exists data(colBeingResized)]} {	;# resize operation in progress
	configLabel $w -cursor $data(-cursor)
	focus $data(focus)
	bind [winfo toplevel $win] <Escape> $data(topEscBinding)
	set col $data(colBeingResized)
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
		# Compute the new column width, using the following equations:
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
		set data(colList) [lreplace $data(colList) $idx $idx $colWidth]
		set data($col-delta) [expr {$stretchedColWidth - $colWidth}]
	    }
	}
	redisplayCol $win $col 0 end
	stretchColumns $win $col
	updateScrlColOffset $win
	unset data(colBeingResized)
	event generate $win <<TablelistColumnResized>>
    } else {
	if {[info exists data(X)]} {
	    unset data(X)
	    after cancel $data(afterId)
	    set data(afterId) ""
	}
    	if {$data(-movablecolumns)} {
	    focus $data(focus)
	    bind [winfo toplevel $win] <Escape> $data(topEscBinding)
	    place forget $data(colGap)
	}
	if {$data(inClickedLabel)} {
	    configLabel $w -relief $data(relief) -pressed 0
	    if {$data(shiftPressed)} {
		if {[info exists data($col-labelcommand2)]} {
		    uplevel #0 $data($col-labelcommand2) [list $win $col]
		} elseif {[string compare $data(-labelcommand2) ""] != 0} {
		    uplevel #0 $data(-labelcommand2) [list $win $col]
		}
	    } else {
		if {[info exists data($col-labelcommand)]} {
		    uplevel #0 $data($col-labelcommand) [list $win $col]
		} elseif {[string compare $data(-labelcommand) ""] != 0} {
		    uplevel #0 $data(-labelcommand) [list $win $col]
		}
	    }
	} elseif {$data(-movablecolumns)} {
	    $data(hdrTxtFrCanv)$col configure -cursor $data(-cursor)
	    if {[info exists data(targetCol)] && $data(targetCol) != -1 &&
		$data(targetCol) != $col && $data(targetCol) != $col + 1} {
		movecolumnSubCmd $win $col $data(targetCol)
		event generate $win <<TablelistColumnMoved>>
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
    parseLabelPath $w win col
    upvar ::tablelist::ns${win}::data data

    if {!$data(isDisabled) &&
	$data(-resizablecolumns) && $data($col-resizable)} {
	if {$shiftPressed} {
	    doColConfig $col $win -width -$data($col-lastStaticWidth)
	} else {
	    doColConfig $col $win -width 0
	}
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

    set w $data(hdrTxtFrLbl)$col
    if {[info exists data(colBeingResized)]} {	;# resize operation in progress
	configLabel $w -cursor $data(-cursor)
	update idletasks
	focus $data(focus)
	bind [winfo toplevel $win] <Escape> $data(topEscBinding)
	set data(labelClicked) 0
	set col $data(colBeingResized)
	set idx [expr {3*$col}]
	setupColumns $win [lreplace $data(-columns) $idx $idx \
				    $data(configColWidth)] 0
	adjustColumns $win $col 1
	redisplayCol $win $col $data(topRow) $data(btmRow)
	unset data(colBeingResized)
    } elseif {!$data(inClickedLabel)} {
	configLabel $w -cursor $data(-cursor)
	$data(hdrTxtFrCanv)$col configure -cursor $data(-cursor)
	focus $data(focus)
	bind [winfo toplevel $win] <Escape> $data(topEscBinding)
	place forget $data(colGap)
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
# tablelist widget's header frame.  It scrolls the header and reschedules
# itself as an after command so that the header continues to scroll until the
# mouse moves back into the window or the mouse button is released.
#------------------------------------------------------------------------------
proc tablelist::horizAutoScan win {
    if {![winfo exists $win]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    if {![info exists data(X)]} {
	return ""
    }

    set X $data(X)
    set hdrX [winfo rootx $data(hdr)]
    if {$data(-titlecolumns) == 0 || ![winfo viewable $data(sep)]} {
	set leftX $hdrX
    } else {
	set leftX [expr {[winfo rootx $data(sep)] + 1}]
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
#==============================================================================
# Contains procedures that create various bitmap images.  The argument w
# specifies a canvas displaying a sort arrow, while the argument win stands for
# a tablelist widget.
#
# Copyright (c) 2006-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

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
   0x08, 0x1c, 0x3e, 0x7f, 0x22};
"
    image create bitmap triangleDn$w -data "
#define triangleDn7x5_width 7
#define triangleDn7x5_height 5
static unsigned char triangleDn7x5_bits[] = {
   0x22, 0x7f, 0x3e, 0x1c, 0x08};
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
    variable checkedImg
    variable uncheckedImg

    set checkedImg [image create bitmap -data "
#define checked_width 9
#define checked_height 9
static unsigned char checked_bits[] = {
   0x00, 0x00, 0x80, 0x00, 0xc0, 0x00, 0xe2, 0x00, 0x76, 0x00, 0x3e, 0x00,
   0x1c, 0x00, 0x08, 0x00, 0x00, 0x00};
"]
    set uncheckedImg [image create bitmap -data "
#define unchecked_width 9
#define unchecked_height 9
static unsigned char unchecked_bits[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
"]
}
#==============================================================================
# Contains private configuration procedures for tablelist widgets.
#
# Copyright (c) 2000-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
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
    lappend configSpecs(-activestyle)		underline
    lappend configSpecs(-columns)		{}
    lappend configSpecs(-editendcommand)	{}
    lappend configSpecs(-editstartcommand)	{}
    lappend configSpecs(-forceeditendcommand)	0
    lappend configSpecs(-incrarrowtype)		up
    lappend configSpecs(-labelcommand)		{}
    lappend configSpecs(-labelcommand2)		{}
    lappend configSpecs(-labelrelief)		raised
    lappend configSpecs(-listvariable)		{}
    lappend configSpecs(-movablecolumns)	0
    lappend configSpecs(-movablerows)		0
    lappend configSpecs(-movecolumncursor)	icon
    lappend configSpecs(-movecursor)		hand2
    lappend configSpecs(-protecttitlecolumns)	0
    lappend configSpecs(-resizablecolumns)	1
    lappend configSpecs(-resizecursor)		sb_h_double_arrow
    lappend configSpecs(-selecttype)		row
    lappend configSpecs(-setfocus)		0
    lappend configSpecs(-showarrow)		1
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
    lappend configSpecs(-titlecolumns)		0

    #
    # Append the default values of the configuration options
    # of a temporary, invisible listbox widget to the values
    # of the corresponding elements of the array configSpecs
    #
    set helpListbox .__helpListbox
    for {set n 0} {[winfo exists $helpListbox]} {incr n} {
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
		     -labeldisabledforeground -labelheight} {
	    unset configSpecs($opt)
	}

	#
	# Append theme-specific values to some elements of the array configSpecs
	#
	ttk::label $helpLabel -takefocus 0
	variable themeDefaults
	setThemeDefaults		;# pupulates the array themeDefaults
	foreach opt {-labelbackground -labelforeground -labelfont
		     -labelborderwidth -labelpady
		     -arrowcolor -arrowdisabledcolor -arrowstyle} {
	    lappend configSpecs($opt) $themeDefaults($opt)
	}
	foreach opt {-background -foreground -disabledforeground
		     -stripebackground -selectbackground -selectforeground
		     -selectborderwidth -font} {
	    lset configSpecs($opt) 3 $themeDefaults($opt)
	}

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
	if {[string compare [package provide ttk::theme::aqua] ""] != 0 ||
	    [string compare [package provide tile::theme::aqua] ""] != 0} {
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
	    unset configSpecs(-titlecolumns)
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
	# -arrowdisabledcolor, and -arrowstyle options
	#
	switch $winSys {
	    x11 {
		lappend configSpecs(-arrowcolor)	      {}
		lappend configSpecs(-arrowdisabledcolor)      {}
		lappend configSpecs(-arrowstyle)	      sunken10x9
	    }

	    win32 {
		if {$::tcl_platform(osVersion) < 5.1} {
		    lappend configSpecs(-arrowcolor)	      {}
		    lappend configSpecs(-arrowdisabledcolor)  {}
		    lappend configSpecs(-arrowstyle)	      sunken8x7
		} else {
		    lappend configSpecs(-arrowcolor)	      #aca899
		    lappend configSpecs(-arrowdisabledcolor)  SystemDisabledText
		    lappend configSpecs(-arrowstyle)	      flat9x5
		}
	    }

	    classic -
	    aqua {
		lappend configSpecs(-arrowcolor)	      #777777
		lappend configSpecs(-arrowdisabledcolor)      #a3a3a3
		lappend configSpecs(-arrowstyle)	      flat7x7
	    }
	}
	lappend configSpecs(-arrowdisabledcolor) \
		[lindex $configSpecs(-arrowcolor) 3]
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
		if {[regexp {^(body|hdr|sep([0-9]+)?)$} [winfo name $w]]} {
		    $w configure $opt $val
		}
	    }
	    $data(hdrTxt) configure $opt $val
	    $data(hdrLbl) configure $opt $val
	    foreach w [winfo children $data(hdrTxtFr)] {
		$w configure $opt $val
	    }
	    set data($opt) [$data(hdrLbl) cget $opt]
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
		    # Apply the value to the frame (because of
		    # the shadow colors of its 3-D border), to
		    # the separators, and to the "disabled" tag
		    #
		    if {$usingTile} {
			styleConfig Frame$win.TFrame $opt $val
			styleConfig Seps$win.TSeparator $opt $val
		    } else {
			$win configure $opt $val
			foreach c [winfo children $win] {
			    if {[regexp {^sep[0-9]+$} [winfo name $c]]} {
				$c configure $opt $val
			    }
			}
		    }
		    $w tag configure disabled $opt $val
		    updateColorsWhenIdle $win
		}
		-font {
		    #
		    # Apply the value to the header text widget and to
		    # the listbox child, rebuild the lists of the column
		    # fonts and tag names, configure the edit window if
		    # present, set up and adjust the columns, and make
		    # sure the items will be redisplayed at idle time
		    #
		    $data(hdrTxt) configure $opt $val
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
		}
		-foreground {
		    #
		    # Set the background color of the main separator
		    # frame (if any) to the specified value, and apply
		    # this value to the "disabled" tag if needed
		    #
		    if {$usingTile} {
			styleConfig Sep$win.TSeparator -background $val
		    } else {
			if {[winfo exists $data(sep)]} {
			    $data(sep) configure -background $val
			}
		    }
		    if {[string compare $data(-disabledforeground) ""] == 0} {
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
	    configLabel $data(hdrLbl) -$optTail $val
	    for {set col 0} {$col < $data(colCount)} {incr col} {
		set w $data(hdrTxtFrLbl)$col
		if {![info exists data($col$opt)]} {
		    configLabel $w -$optTail $val
		}
	    }
	    if {$usingTile && [string compare $opt "-labelpady"] == 0} {
		set data($opt) $val
	    } else {
		set data($opt) [$data(hdrLbl) cget -$optTail]
	    }

	    switch -- $opt {
		-labelbackground -
		-labelforeground {
		    #
		    # Apply the value to $data(hdrTxt) and conditionally
		    # to the canvases displaying up- or down-arrows
		    #
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
		    # Adjust the columns (including
		    # the height of the header frame)
		    #
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
		    if {[string compare $val ""] == 0} {
			set data($opt) ""
		    } else {
			$helpLabel configure -foreground $val
			set data($opt) [$helpLabel cget -foreground]
		    }
		    if {([string compare $opt "-arrowcolor"] == 0 &&
			 !$data(isDisabled)) ||
			([string compare $opt "-arrowdisabledcolor"] == 0 &&
			 $data(isDisabled))} {
			foreach w [info commands $data(hdrTxtFrCanv)*] {
			    fillArrows $w $val
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
		    regexp {^(flat|sunken)([0-9]+)x([0-9]+)$} $data($opt) \
			   dummy relief width height
		    set data(arrowWidth) $width
		    foreach w [info commands $data(hdrTxtFrCanv)*] {
			createArrows $w $width $height $relief
			if {$data(isDisabled)} {
			    fillArrows $w $data(-arrowdisabledcolor)
			} else {
			    fillArrows $w $data(-arrowcolor)
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
		-columns {
		    #
		    # Set up and adjust the columns, rebuild
		    # the lists of the column fonts and tag
		    # names, and redisplay the items
		    #
		    set selCells [curcellselectionSubCmd $win]
		    setupColumns $win $val 1
		    adjustColumns $win allCols 1
		    adjustColIndex $win data(anchorCol) 1
		    adjustColIndex $win data(activeCol) 1
		    makeColFontAndTagLists $win
		    redisplay $win 0 $selCells
		}
		-disabledforeground {
		    #
		    # Configure the "disabled" tag in the body text widget and
		    # save the properly formatted value of val in data($opt)
		    #
		    set w $data(body)
		    if {[string compare $val ""] == 0} {
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
		-editendcommand -
		-editstartcommand -
		-labelcommand -
		-labelcommand2 -
		-selectmode -
		-sortcommand -
		-yscrollcommand {
		    set data($opt) $val
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
		-forceeditendcommand -
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
		-height {
		    #
		    # Adjust the heights of the body text widget
		    # and of the listbox child, and save the
		    # properly formatted value of val in data($opt)
		    #
		    set val [format "%d" $val]	;# integer check with error msg
		    if {$val <= 0} {
			set nonHiddenRowCount \
			    [expr {$data(itemCount) - $data(hiddenRowCount)}]
			$data(body) configure $opt $nonHiddenRowCount
			$data(lb) configure $opt $nonHiddenRowCount
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
		    if {[string compare $val ""] == 0} {
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
				 -spacing3 [expr {$spacing + $pixVal + 1}]
		    $data(lb) configure $opt $val
		    updateColorsWhenIdle $win
		    adjustSepsWhenIdle $win
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
			    if {[regexp {^sep[0-9]+$} [winfo name $w]]} {
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
				 -spacing3 [expr {$pixVal + $selectBd + 1}]
		    set data($opt) $val
		    updateColorsWhenIdle $win
		    adjustSepsWhenIdle $win
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
			configLabel $data(hdrLbl) $opt $val
			for {set col 0} {$col < $data(colCount)} {incr col} {
			    configLabel $data(hdrTxtFrLbl)$col $opt $val
			}
		    }
		    if {$data(editRow) >= 0} {
			catch {$data(bodyFrEd) configure $opt $val}
		    }
		    set w $data(body)
		    switch $val {
			disabled {
			    $w tag add disabled 1.0 end
			    $w tag configure select -relief flat
			    set data(isDisabled) 1
			}
			normal {
			    $w tag remove disabled 1.0 end
			    $w tag configure select -relief raised
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
		    set w $data(sep)
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
		    xviewSubCmd $win 0
		    updateHScrlbarWhenIdle $win
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

    return $data($opt)
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

	    if {[string compare $val ""] == 0} {
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
			if {[lsearch -exact [$w tag names $tabIdx1] select]
			    < 0} {
			    $w tag add $tag $tabIdx1 $tabIdx2+1c
			}
		    }
		}

		#
		# Save val in data($name)
		#
		set data($name) $val
	    }

	    if {!$data(isDisabled)} {
		updateColorsWhenIdle $win
	    }

	    #
	    # Rebuild the lists of the column fonts and tag names
	    #
	    makeColFontAndTagLists $win
	}

	-changesnipside {
	    #
	    # Save the boolean value specified by val in data($col$opt) and
	    # make sure the given column will be redisplayed at idle time
	    #
	    set data($col$opt) [expr {$val ? 1 : 0}]
	    if {[lindex $data(-columns) [expr {3*$col}]] != 0} {
		redisplayColWhenIdle $win $col
	    }
	}

	-editable -
	-resizable {
	    #
	    # Save the boolean value specified by val in data($col$opt)
	    #
	    set data($col$opt) [expr {$val ? 1 : 0}]
	}

	-editwindow {
	    variable editWin
	    if {[info exists editWin($val-registered)] ||
		[info exists editWin($val-creationCmd)]} {
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

	    if {[string compare $val ""] == 0} {
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

	    adjustElidedTextWhenIdle $win

	    if {$col == $data(editCol)} {
		#
		# Configure the edit window
		#
		setEditWinFont $win
	    }
	}

	-formatcommand {
	    if {[string compare $val ""] == 0} {
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

	    #
	    # Adjust the columns and make sure the specified
	    # column will be redisplayed at idle time
	    #
	    adjustColumns $win $col 1
	    redisplayColWhenIdle $win $col
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
		    set selCells [curcellselectionSubCmd $win]
		} elseif {$newVal} {
		    cellselectionSubCmd $win clear 0 $col $data(lastRow) $col
		}
		set data($col$opt) $newVal
		if {$newVal} {				;# hiding the column
		    incr data(hiddenColCount)
		    adjustColIndex $win data(anchorCol) 1
		    adjustColIndex $win data(activeCol) 1
		    if {$col == $data(editCol)} {
			canceleditingSubCmd $win
		    }
		} else {
		    incr data(hiddenColCount) -1
		}
		makeColFontAndTagLists $win
		adjustColumns $win $col 1
		if {$canElide} {
		    adjustElidedTextWhenIdle $win
		} else {
		    redisplay $win 0 $selCells
		}
		if {!$newVal &&
		    [string compare $data(-selecttype) "row"] == 0} {
		    foreach row [curselectionSubCmd $win] {
			selectionSubCmd $win set $row $row
		    }
		}
	    }
	}

	-labelalign {
	    if {[string compare $val ""] == 0} {
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
	    set w $data(hdrTxtFrLbl)$col
	    set optTail [string range $opt 6 end]	;# remove the -label
	    if {[string compare $val ""] == 0} {
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

	    if {[lsearch -exact $data(arrowColList) $col] >= 0} {
		configCanvas $win $col
	    }
	}

	-labelborderwidth {
	    set w $data(hdrTxtFrLbl)$col
	    set optTail [string range $opt 6 end]	;# remove the -label
	    if {[string compare $val ""] == 0} {
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
	    if {[string compare $val ""] == 0} {
		if {[info exists data($col$opt)]} {
		    unset data($col$opt)
		}
	    } else {
		set data($col$opt) $val
	    }
	}

	-labelfont {
	    set w $data(hdrTxtFrLbl)$col
	    set optTail [string range $opt 6 end]	;# remove the -label
	    if {[string compare $val ""] == 0} {
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
	    set w $data(hdrTxtFrLbl)$col
	    set optTail [string range $opt 6 end]	;# remove the -label
	    if {[string compare $val ""] == 0} {
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
	    set w $data(hdrTxtFrLbl)$col
	    if {[string compare $val ""] == 0} {
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
			foreach opt2 {-background -foreground -font} {
			    $l configure $opt2 [$w cget $opt2]
			}
			foreach opt2 {-activebackground -activeforeground
				      -disabledforeground -state} {
			    catch {$l configure $opt2 [$w cget $opt2]}
			}

			#
			# Replace the binding tag Label with
			# $w and TablelistSubLabel in the
			# list of binding tags of the label $l
			#
			bindtags $l [lreplace [bindtags $l] 1 1 \
				     $w TablelistSubLabel]
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
	    set w $data(hdrTxtFrLbl)$col
	    set optTail [string range $opt 6 end]	;# remove the -label
	    if {[string compare $val ""] == 0} {
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
	}

	-selectbackground -
	-selectforeground {
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

	    if {[string compare $val ""] == 0} {
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

		if {!$data($col-hide) || $canElide} {
		    #
		    # Apply the tag to the selected elements of the given column
		    #
		    set selRange [$w tag nextrange select 1.0]
		    while {[llength $selRange] != 0} {
			set selStart [lindex $selRange 0]
			set line [expr {int($selStart)}]
			findTabs $win $line $col $col tabIdx1 tabIdx2
			if {[lsearch -exact [$w tag names $tabIdx1] select]
			    >= 0} {
			    $w tag add $tag $tabIdx1 $tabIdx2+1c
			}

			set selRange \
			    [$w tag nextrange select "$selStart lineend"]
		    }
		}

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

	-text {
	    if {$data(isDisabled)} {
		return ""
	    }

	    #
	    # Replace the column's contents in the internal list
	    #
	    set newItemList {}
	    set row 0
	    foreach item $data(itemList) text [lrange $val 0 $data(itemCount)] {
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

	-width {
	    #
	    # Set up and adjust the columns, and make sure the
	    # given column will be redisplayed at idle time
	    #
	    set idx [expr {3*$col}]
	    if {$val != [lindex $data(-columns) $idx]} {
		setupColumns $win [lreplace $data(-columns) $idx $idx $val] 0
		adjustColumns $win $col 1
		redisplayColWhenIdle $win $col
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
	    set key [lindex [lindex $data(itemList) $row] end]
	    set name $key$opt

	    if {[info exists data($name)]} {
		#
		# Remove the tag row$opt-$data($name) from the given row
		#
		set line [expr {$row + 1}]
		$w tag remove row$opt-$data($name) $line.0 $line.end
	    }

	    if {[string compare $val ""] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		    incr data(tagRefCount) -1
		}
	    } else {
		#
		# Configure the tag row$opt-$val in the body text widget and
		# apply it to the non-selected elements of the given row
		#
		set tag row$opt-$val
		$w tag configure $tag $opt $val
		$w tag lower $tag active
		set line [expr {$row + 1}]
		set textIdx1 [expr {double($line)}]
		for {set col 0} {$col < $data(colCount)} {incr col} {
		    if {$data($col-hide) && !$canElide} {
			continue
		    }

		    set textIdx2 \
			[$w search $elide "\t" $textIdx1+1c $line.end]+1c
		    if {[lsearch -exact [$w tag names $textIdx1] select] < 0} {
			$w tag add $tag $textIdx1 $textIdx2
		    }
		    set textIdx1 $textIdx2
		}

		#
		# Save val in data($name)
		#
		if {![info exists data($name)]} {
		    incr data(tagRefCount)
		}
		set data($name) $val
	    }

	    if {!$data(isDisabled)} {
		updateColorsWhenIdle $win
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

	    if {[string compare $val ""] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		    incr data(tagRefCount) -1
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
		    incr data(tagRefCount)
		}
		set data($name) $val
	    }

	    if {[lsearch -exact $data(fmtCmdFlagList) 1] >= 0} {
		set formattedItem \
		    [formatItem $win [lrange $item 0 $data(lastCol)]]
	    } else {
		set formattedItem [lrange $item 0 $data(lastCol)]
	    }
	    set colWidthsChanged 0
	    set colIdxList {}
	    set line [expr {$row + 1}]
	    set textIdx1 $line.1
	    set col 0
	    foreach text [strToDispStr $formattedItem] \
		    {pixels alignment} $data(colList) {
		if {$data($col-hide) && !$canElide} {
		    incr col
		    continue
		}

		#
		# Adjust the cell text and the image or window width
		#
		if {[string match "*\n*" $text]} {
		    set multiline 1
		    set list [split $text "\n"]
		} else {
		    set multiline 0
		}
		set aux [getAuxData $win $key $col auxType auxWidth]
		set textSav $text
		set auxWidthSav $auxWidth
		set cellFont [getCellFont $win $key $col]
		set workPixels $pixels
		if {$pixels == 0} {		;# convention: dynamic width
		    if {$data($col-maxPixels) > 0} {
			if {$data($col-reqPixels) > $data($col-maxPixels)} {
			    set workPixels $data($col-maxPixels)
			}
		    }
		}
		if {$workPixels != 0} {
		    incr workPixels $data($col-delta)
		}
		set snipSide $snipSides($alignment,$data($col-changesnipside))
		if {$multiline} {
		    adjustMlElem $win list auxWidth $cellFont $workPixels \
				 $snipSide $data(-snipstring)
		    set msgScript [list ::tablelist::displayText $win $key \
				   $col [join $list "\n"] $cellFont $alignment]
		} else {
		    adjustElem $win text auxWidth $cellFont $workPixels \
			       $snipSide $data(-snipstring)
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
			updateMlCell $w $textIdx1 $textIdx2 $msgScript \
				     $aux $auxType $auxWidth $alignment
		    } else {
			updateCell $w $textIdx1 $textIdx2 $text \
				   $aux $auxType $auxWidth $alignment
		    }
		}

		if {$pixels == 0} {		;# convention: dynamic width
		    #
		    # Check whether the width of the current column has changed
		    #
		    set text $textSav
		    set auxWidth $auxWidthSav
		    set newElemWidth \
			[getElemWidth $win $text $auxWidth $cellFont]
		    if {$newElemWidth > $data($col-elemWidth)} {
			set data($col-elemWidth) $newElemWidth
			set data($col-widestCount) 1
			if {$newElemWidth > $data($col-reqPixels)} {
			    set data($col-reqPixels) $newElemWidth
			    set colWidthsChanged 1
			}
		    } else {
			set oldElemWidth [getElemWidth $win $text \
					  $auxWidth $oldCellFonts($col)]
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
	    adjustElidedTextWhenIdle $win
	    updateColorsWhenIdle $win
	    adjustSepsWhenIdle $win
	}

	-hide {
	    set val [expr {$val ? 1 : 0}]
	    set item [lindex $data(itemList) $row]
	    set key [lindex $item end]
	    set name $key$opt
	    set line [expr {$row + 1}]
	    set viewChanged 0

	    if {$val} {					;# hiding the row
		if {![info exists data($name)]} {
		    selectionSubCmd $win clear $row $row
		    set data($name) 1
		    incr data(hiddenRowCount)
		    $w tag add hiddenRow $line.0 $line.end+1c
		    set viewChanged 1
		    adjustRowIndex $win data(anchorRow) 1
		    adjustRowIndex $win data(activeRow) 1
		    if {$row == $data(editRow)} {
			canceleditingSubCmd $win
		    }
		}
	    } else {					;# unhiding the row
		if {[info exists data($name)]} {
		    unset data($name)
		    incr data(hiddenRowCount) -1
		    $w tag remove hiddenRow $line.0 $line.end+1c
		    set viewChanged 1
		}
	    }

	    if {$viewChanged} {
		#
		# Adjust the heights of the body text widget
		# and of the listbox child, if necessary
		#
		if {$data(-height) <= 0} {
		    set nonHiddenRowCount \
			[expr {$data(itemCount) - $data(hiddenRowCount)}]
		    $w configure -height $nonHiddenRowCount
		    $data(lb) configure -height $nonHiddenRowCount
		}

		#
		# Build the list of those dynamic-width columns
		# whose widths are affected by (un)hiding the row
		#
		set colWidthsChanged 0
		set colIdxList {}
		if {[lsearch -exact $data(fmtCmdFlagList) 1] >= 0} {
		    set formattedItem \
			[formatItem $win [lrange $item 0 $data(lastCol)]]
		} else {
		    set formattedItem [lrange $item 0 $data(lastCol)]
		}
		set col 0
		foreach text [strToDispStr $formattedItem] \
			{pixels alignment} $data(colList) {
		    if {($data($col-hide) && !$canElide) || $pixels != 0} {
			incr col
			continue
		    }

		    getAuxData $win $key $col auxType auxWidth
		    set cellFont [getCellFont $win $key $col]
		    set elemWidth [getElemWidth $win $text $auxWidth $cellFont]
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
		# Invalidate the list of the row indices indicating the
		# non-hidden rows, adjust the columns if necessary, and
		# schedule some operations for execution at idle time
		#
		set data(nonHiddenRowList) {-1}
		if {$colWidthsChanged} {
		    adjustColumns $win $colIdxList 1
		}
		adjustElidedTextWhenIdle $win
		makeStripesWhenIdle $win
		adjustSepsWhenIdle $win
		updateVScrlbarWhenIdle $win
		showLineNumbersWhenIdle $win
	    }
	}

	-name {
	    set key [lindex [lindex $data(itemList) $row] end]
	    if {[string compare $val ""] == 0} {
		if {[info exists data($key$opt)]} {
		    unset data($key$opt)
		}
	    } else {
		set data($key$opt) $val
	    }
	}

	-selectable {
	    set val [expr {$val ? 1 : 0}]
	    set key [lindex [lindex $data(itemList) $row] end]

	    if {$val} {
		if {[info exists data($key$opt)]} {
		    unset data($key$opt)
		}
	    } else {
		#
		# Set data($key$opt) to 0 and deselect the row
		#
		set data($key$opt) 0
		selectionSubCmd $win clear $row $row
	    }
	}

	-selectbackground -
	-selectforeground {
	    set key [lindex [lindex $data(itemList) $row] end]
	    set name $key$opt

	    if {[info exists data($name)]} {
		#
		# Remove the tag row$opt-$data($name) from the given row
		#
		set line [expr {$row + 1}]
		$w tag remove row$opt-$data($name) $line.0 $line.end
	    }

	    if {[string compare $val ""] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		}
	    } else {
		#
		# Configure the tag row$opt-$val in the body text widget
		# and apply it to the selected elements of the given row
		#
		set tag row$opt-$val
		set optTail [string range $opt 7 end]	;# remove the -select
		$w tag configure $tag -$optTail $val
		$w tag lower $tag active
		set line [expr {$row + 1}]
		set textIdx1 [expr {double($line)}]
		for {set col 0} {$col < $data(colCount)} {incr col} {
		    if {$data($col-hide) && !$canElide} {
			continue
		    }

		    set textIdx2 \
			[$w search $elide "\t" $textIdx1+1c $line.end]+1c
		    if {[lsearch -exact [$w tag names $textIdx1] select] >= 0} {
			$w tag add $tag $textIdx1 $textIdx2
		    }
		    set textIdx1 $textIdx2
		}

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
	    if {[lsearch -exact $data(fmtCmdFlagList) 1] >= 0} {
		set formattedItem [formatItem $win $newItem]
	    } else {
		set formattedItem $newItem
	    }
	    set line [expr {$row + 1}]
	    set textIdx1 $line.1
	    set col 0
	    foreach text [strToDispStr $formattedItem] \
		    {pixels alignment} $data(colList) {
		if {$data($col-hide) && !$canElide} {
		    incr col
		    continue
		}

		#
		# Adjust the cell text and the image or window width
		#
		if {[string match "*\n*" $text]} {
		    set multiline 1
		    set list [split $text "\n"]
		} else {
		    set multiline 0
		}
		set aux [getAuxData $win $key $col auxType auxWidth]
		set textSav $text
		set auxWidthSav $auxWidth
		set cellFont [getCellFont $win $key $col]
		set workPixels $pixels
		if {$pixels == 0} {		;# convention: dynamic width
		    if {$data($col-maxPixels) > 0} {
			if {$data($col-reqPixels) > $data($col-maxPixels)} {
			    set workPixels $data($col-maxPixels)
			}
		    }
		}
		if {$workPixels != 0} {
		    incr workPixels $data($col-delta)
		}
		set snipSide $snipSides($alignment,$data($col-changesnipside))
		if {$multiline} {
		    adjustMlElem $win list auxWidth $cellFont $workPixels \
				 $snipSide $data(-snipstring)
		    set msgScript [list ::tablelist::displayText $win $key \
				   $col [join $list "\n"] $cellFont $alignment]
		} else {
		    adjustElem $win text auxWidth $cellFont $workPixels \
			       $snipSide $data(-snipstring)
		}

		if {$row != $data(editRow) || $col != $data(editCol)} {
		    #
		    # Update the text widget's contents between the two tabs
		    #
		    set textIdx2 [$w search $elide "\t" $textIdx1 $line.end]
		    if {$multiline} {
			updateMlCell $w $textIdx1 $textIdx2 $msgScript \
				     $aux $auxType $auxWidth $alignment
		    } else {
			updateCell $w $textIdx1 $textIdx2 $text \
				   $aux $auxType $auxWidth $alignment
		    }
		}

		if {$pixels == 0} {		;# convention: dynamic width
		    #
		    # Check whether the width of the current column has changed
		    #
		    set text $textSav
		    set auxWidth $auxWidthSav
		    set newElemWidth \
			[getElemWidth $win $text $auxWidth $cellFont]
		    if {$newElemWidth > $data($col-elemWidth)} {
			set data($col-elemWidth) $newElemWidth
			set data($col-widestCount) 1
			if {$newElemWidth > $data($col-reqPixels)} {
			    set data($col-reqPixels) $newElemWidth
			    set colWidthsChanged 1
			}
		    } else {
			set oldText [lindex $oldItem $col]
			if {[info exists data($col-formatcommand)]} {
			    set oldText [uplevel #0 $data($col-formatcommand) \
					 [list $oldText]]
			}
			set oldText [strToDispStr $oldText]
			set oldElemWidth \
			    [getElemWidth $win $oldText $auxWidth $cellFont]
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
	    lappend newItem [lindex $oldItem end]
	    set data(itemList) [lreplace $data(itemList) $row $row $newItem]

	    #
	    # Adjust the columns if necessary and schedule
	    # some operations for execution at idle time
	    #
	    if {$colWidthsChanged} {
		adjustColumns $win $colIdxList 1
	    }
	    adjustElidedTextWhenIdle $win
	    updateColorsWhenIdle $win
	    adjustSepsWhenIdle $win
	    showLineNumbersWhenIdle $win
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

    #
    # Return the value of the specified row configuration option
    #
    set item [lindex $data(itemList) $row]
    switch -- $opt {
	-text {
	    return [lrange $item 0 $data(lastCol)]
	}

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
	    set key [lindex [lindex $data(itemList) $row] end]
	    set name $key,$col$opt

	    if {[info exists data($name)] &&
		(!$data($col-hide) || $canElide)} {
		#
		# Remove the tag cell$opt-$data($name) from the given cell
		#
		findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		$w tag remove cell$opt-$data($name) $tabIdx1 $tabIdx2+1c
	    }

	    if {[string compare $val ""] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		    incr data(tagRefCount) -1
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
		    # Apply the tag to the given cell if it is not selected
		    #
		    findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		    if {[lsearch -exact [$w tag names $tabIdx1] select] < 0} {
			$w tag add $tag $tabIdx1 $tabIdx2+1c
		    }
		}

		#
		# Save val in data($name)
		#
		if {![info exists data($name)]} {
		    incr data(tagRefCount)
		}
		set data($name) $val
	    }

	    if {!$data(isDisabled)} {
		updateColorsWhenIdle $win
	    }
	}

	-editable {
	    #
	    # Save the boolean value specified by val in data($key,$col$opt)
	    #
	    set key [lindex [lindex $data(itemList) $row] end]
	    set data($key,$col$opt) [expr {$val ? 1 : 0}]
	}

	-editwindow {
	    variable editWin
	    if {[info exists editWin($val-registered)] ||
		[info exists editWin($val-creationCmd)]} {
		set key [lindex [lindex $data(itemList) $row] end]
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

	    if {[string compare $val ""] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		    incr data(tagRefCount) -1
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
		    incr data(tagRefCount)
		}
		set data($name) $val
	    }

	    #
	    # Adjust the cell text and the image or window width
	    #
	    set text [lindex $item $col]
	    if {[info exists data($col-formatcommand)]} {
		set text [uplevel #0 $data($col-formatcommand) [list $text]]
	    }
	    set text [strToDispStr $text]
	    if {[string match "*\n*" $text]} {
		set multiline 1
		set list [split $text "\n"]
	    } else {
		set multiline 0
	    }
	    set aux [getAuxData $win $key $col auxType auxWidth]
	    set textSav $text
	    set auxWidthSav $auxWidth
	    set cellFont [getCellFont $win $key $col]
	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    set workPixels $pixels
	    if {$pixels == 0} {			;# convention: dynamic width
		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set workPixels $data($col-maxPixels)
		    }
		}
	    }
	    if {$workPixels != 0} {
		incr workPixels $data($col-delta)
	    }
	    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
	    set snipSide $snipSides($alignment,$data($col-changesnipside))
	    if {$multiline} {
		adjustMlElem $win list auxWidth $cellFont $workPixels \
			     $snipSide $data(-snipstring)
		set msgScript [list ::tablelist::displayText $win $key \
			       $col [join $list "\n"] $cellFont $alignment]
	    } else {
		adjustElem $win text auxWidth $cellFont $workPixels \
			   $snipSide $data(-snipstring)
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
			updateMlCell $w $tabIdx1+1c $tabIdx2 $msgScript \
				     $aux $auxType $auxWidth $alignment
		    } else {
			updateCell $w $tabIdx1+1c $tabIdx2 $text \
				   $aux $auxType $auxWidth $alignment
		    }
		}
	    }

	    #
	    # Adjust the columns if necessary
	    #
	    if {$pixels == 0} {			;# convention: dynamic width
		set text $textSav
		set auxWidth $auxWidthSav
		set newElemWidth [getElemWidth $win $text $auxWidth $cellFont]
		if {$newElemWidth > $data($col-elemWidth)} {
		    set data($col-elemWidth) $newElemWidth
		    set data($col-widestCount) 1
		    if {$newElemWidth > $data($col-reqPixels)} {
			set data($col-reqPixels) $newElemWidth
			adjustColumns $win {} 1
		    }
		} else {
		    set oldElemWidth \
			[getElemWidth $win $text $auxWidth $oldCellFont]
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

	    adjustElidedTextWhenIdle $win
	    updateColorsWhenIdle $win
	    adjustSepsWhenIdle $win
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
	    if {[string compare $val ""] == 0} {
		if {[info exists data($name)]} {
		    unset data($name)
		    incr data(imgCount) -1
		}
	    } else {
		if {![info exists data($name)]} {
		    incr data(imgCount)
		}
		set imgLabel $w.l$key,$col
		set existsImgLabel [winfo exists $imgLabel]
		if {$existsImgLabel && [info exists data($name)] &&
		    [string compare $val $data($name)] == 0} {
		    set keepAux 1
		} else {
		    set keepAux 0
		    if {$existsImgLabel} {
			destroy $imgLabel
		    }
		}
		set data($name) $val
	    }

	    #
	    # Adjust the cell text and the image or window width
	    #
	    set text [lindex $item $col]
	    if {[info exists data($col-formatcommand)]} {
		set text [uplevel #0 $data($col-formatcommand) [list $text]]
	    }
	    set text [strToDispStr $text]
	    set oldText $text
	    if {[string match "*\n*" $text]} {
		set multiline 1
		set list [split $text "\n"]
	    } else {
		set multiline 0
	    }
	    set aux [getAuxData $win $key $col auxType auxWidth]
	    set textSav $text
	    set auxWidthSav $auxWidth
	    set cellFont [getCellFont $win $key $col]
	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    set workPixels $pixels
	    if {$pixels == 0} {			;# convention: dynamic width
		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set workPixels $data($col-maxPixels)
		    }
		}
	    }
	    if {$workPixels != 0} {
		incr workPixels $data($col-delta)
	    }
	    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
	    set snipSide $snipSides($alignment,$data($col-changesnipside))
	    if {$multiline} {
		adjustMlElem $win list auxWidth $cellFont $workPixels \
			     $snipSide $data(-snipstring)
		set msgScript [list ::tablelist::displayText $win $key \
			       $col [join $list "\n"] $cellFont $alignment]
	    } else {
		adjustElem $win text auxWidth $cellFont $workPixels \
			   $snipSide $data(-snipstring)
	    }

	    if {(!$data($col-hide) || $canElide) &&
		!($row == $data(editRow) && $col == $data(editCol))} {
		#
		# Delete the old cell contents between the two tabs,
		# and insert the text and the auxiliary object
		#
		findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		if {$auxType != 1 || $keepAux} {
		    if {$multiline} {
			updateMlCell $w $tabIdx1+1c $tabIdx2 $msgScript \
				     $aux $auxType $auxWidth $alignment
		    } else {
			updateCell $w $tabIdx1+1c $tabIdx2 $text \
				   $aux $auxType $auxWidth $alignment
		    }
		} else {
		    set aux [lreplace $aux end end $auxWidth]
		    $w delete $tabIdx1+1c $tabIdx2
		    if {$multiline} {
			insertMlElem $w $tabIdx1+1c $msgScript \
				     $aux $auxType $alignment
		    } else {
			insertElem $w $tabIdx1+1c $text $aux $auxType $alignment
		    }
		}
	    }

	    #
	    # Adjust the columns if necessary
	    #
	    if {$pixels == 0} {			;# convention: dynamic width
		set text $textSav
		set auxWidth $auxWidthSav
		set newElemWidth [getElemWidth $win $text $auxWidth $cellFont]
		if {$newElemWidth > $data($col-elemWidth)} {
		    set data($col-elemWidth) $newElemWidth
		    set data($col-widestCount) 1
		    if {$newElemWidth > $data($col-reqPixels)} {
			set data($col-reqPixels) $newElemWidth
			adjustColumns $win {} 1
		    }
		} else {
		    set oldElemWidth \
			[getElemWidth $win $oldText $oldAuxWidth $cellFont]
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

	    adjustElidedTextWhenIdle $win
	    updateColorsWhenIdle $win
	    adjustSepsWhenIdle $win
	}

	-selectbackground -
	-selectforeground {
	    set key [lindex [lindex $data(itemList) $row] end]
	    set name $key,$col$opt

	    if {[info exists data($name)] &&
		(!$data($col-hide) || $canElide)} {
		#
		# Remove the tag cell$opt-$data($name) from the given cell
		#
		findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		$w tag remove cell$opt-$data($name) $tabIdx1 $tabIdx2+1c
	    }

	    if {[string compare $val ""] == 0} {
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

		if {!$data($col-hide) || $canElide} {
		    #
		    # Apply the tag to the given cell if it is selected
		    #
		    findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		    if {[lsearch -exact [$w tag names $tabIdx1] select] >= 0} {
			$w tag add $tag $tabIdx1 $tabIdx2+1c
		    }
		}

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
	    if {$data(isDisabled)} {
		return ""
	    }

	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    set workPixels $pixels
	    if {$pixels == 0} {			;# convention: dynamic width
		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set workPixels $data($col-maxPixels)
		    }
		}
	    }
	    if {$workPixels != 0} {
		incr workPixels $data($col-delta)
	    }
	    set alignment [lindex $data(colList) [expr {2*$col + 1}]]

	    #
	    # Adjust the cell text and the image or window width
	    #
	    set text $val
	    set fmtCmdFlag [info exists data($col-formatcommand)]
	    if {$fmtCmdFlag} {
		set text [uplevel #0 $data($col-formatcommand) [list $text]]
	    }
	    set text [strToDispStr $text]
	    set textSav $text
	    if {[string match "*\n*" $text]} {
		set multiline 1
		set list [split $text "\n"]
	    } else {
		set multiline 0
	    }
	    set oldItem [lindex $data(itemList) $row]
	    set key [lindex $oldItem end]
	    set aux [getAuxData $win $key $col auxType auxWidth]
	    set auxWidthSav $auxWidth
	    set cellFont [getCellFont $win $key $col]
	    set snipSide $snipSides($alignment,$data($col-changesnipside))
	    if {$multiline} {
		adjustMlElem $win list auxWidth $cellFont $workPixels \
			     $snipSide $data(-snipstring)
		set msgScript [list ::tablelist::displayText $win $key \
			       $col [join $list "\n"] $cellFont $alignment]
	    } else {
		adjustElem $win text auxWidth $cellFont $workPixels \
			   $snipSide $data(-snipstring)
	    }

	    if {(!$data($col-hide) || $canElide) &&
		!($row == $data(editRow) && $col == $data(editCol))} {
		#
		# Update the text widget's contents between the two tabs
		#
		findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		if {$multiline} {
		    updateMlCell $w $tabIdx1+1c $tabIdx2 $msgScript \
				 $aux $auxType $auxWidth $alignment
		} else {
		    updateCell $w $tabIdx1+1c $tabIdx2 $text \
			       $aux $auxType $auxWidth $alignment
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
	    if {$pixels == 0} {			;# convention: dynamic width
		set text $textSav
		set auxWidth $auxWidthSav
		set newElemWidth [getElemWidth $win $text $auxWidth $cellFont]
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
			set oldText [uplevel #0 $data($col-formatcommand) \
				     [list $oldText]]
		    }
		    set oldText [strToDispStr $oldText]
		    set oldElemWidth \
			[getElemWidth $win $oldText $auxWidth $cellFont]
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

	    adjustElidedTextWhenIdle $win
	    updateColorsWhenIdle $win
	    adjustSepsWhenIdle $win
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

	    #
	    # Delete data($name) or save the specified value in it
	    #
	    if {[string compare $val ""] == 0} {
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
		}
	    } else {
		if {![info exists data($name)]} {
		    incr data(winCount)
		}
		set aux $w.f$key,$col
		set existsAux [winfo exists $aux]
		if {$existsAux && [info exists data($name)] &&
		    [string compare $val $data($name)] == 0} {
		    set keepAux 1
		} else {
		    set keepAux 0
		    if {$existsAux} {
			destroy $aux
		    }

		    #
		    # Create the frame and evaluate the specified script
		    # that creates a child widget within the frame
		    #
		    tk::frame $aux -borderwidth 0 -class TablelistWindow \
				   -container 0 -highlightthickness 0 \
				    -relief flat -takefocus 0
		    catch {$aux configure -padx 0 -pady 0}
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
	    set text [lindex $item $col]
	    if {[info exists data($col-formatcommand)]} {
		set text [uplevel #0 $data($col-formatcommand) [list $text]]
	    }
	    set text [strToDispStr $text]
	    set oldText $text
	    if {[string match "*\n*" $text]} {
		set multiline 1
		set list [split $text "\n"]
	    } else {
		set multiline 0
	    }
	    set aux [getAuxData $win $key $col auxType auxWidth]
	    set textSav $text
	    set auxWidthSav $auxWidth
	    set cellFont [getCellFont $win $key $col]
	    set pixels [lindex $data(colList) [expr {2*$col}]]
	    set workPixels $pixels
	    if {$pixels == 0} {			;# convention: dynamic width
		if {$data($col-maxPixels) > 0} {
		    if {$data($col-reqPixels) > $data($col-maxPixels)} {
			set workPixels $data($col-maxPixels)
		    }
		}
	    }
	    if {$workPixels != 0} {
		incr workPixels $data($col-delta)
	    }
	    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
	    set snipSide $snipSides($alignment,$data($col-changesnipside))
	    if {$multiline} {
		adjustMlElem $win list auxWidth $cellFont $workPixels \
			     $snipSide $data(-snipstring)
		set msgScript [list ::tablelist::displayText $win $key \
			       $col [join $list "\n"] $cellFont $alignment]
	    } else {
		adjustElem $win text auxWidth $cellFont $workPixels \
			   $snipSide $data(-snipstring)
	    }

	    if {(!$data($col-hide) || $canElide) &&
		!($row == $data(editRow) && $col == $data(editCol))} {
		#
		# Delete the old cell contents between the two tabs,
		# and insert the text and the auxiliary object
		#
		findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
		if {$auxType != 2 || $keepAux} {
		    if {$multiline} {
			updateMlCell $w $tabIdx1+1c $tabIdx2 $msgScript \
				     $aux $auxType $auxWidth $alignment
		    } else {
			updateCell $w $tabIdx1+1c $tabIdx2 $text \
				   $aux $auxType $auxWidth $alignment
		    }
		} else {
		    $aux configure -width $auxWidth
		    $w delete $tabIdx1+1c $tabIdx2
		    if {$multiline} {
			insertMlElem $w $tabIdx1+1c $msgScript \
				     $aux $auxType $alignment
		    } else {
			insertElem $w $tabIdx1+1c $text $aux $auxType $alignment
		    }
		}
	    }

	    #
	    # Adjust the columns if necessary
	    #
	    if {$pixels == 0} {			;# convention: dynamic width
		set text $textSav
		set auxWidth $auxWidthSav
		set newElemWidth [getElemWidth $win $text $auxWidth $cellFont]
		if {$newElemWidth > $data($col-elemWidth)} {
		    set data($col-elemWidth) $newElemWidth
		    set data($col-widestCount) 1
		    if {$newElemWidth > $data($col-reqPixels)} {
			set data($col-reqPixels) $newElemWidth
			adjustColumns $win {} 1
		    }
		} else {
		    set oldElemWidth \
			[getElemWidth $win $oldText $oldAuxWidth $cellFont]
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

	    adjustElidedTextWhenIdle $win
	    updateColorsWhenIdle $win
	    adjustSepsWhenIdle $win
	}

	-windowdestroy {
	    set key [lindex [lindex $data(itemList) $row] end]
	    set name $key,$col$opt

	    #
	    # Delete data($name) or save the specified value in it
	    #
	    if {[string compare $val ""] == 0} {
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
    upvar ::tablelist::ns${win}::data data

    #
    # Return the value of the specified cell configuration option
    #
    switch -- $opt {
	-editable {
	    return [isCellEditable $win $row $col]
	}

	-editwindow {
	    return [getEditWindow $win $row $col]
	}

	-text {
	    return [lindex [lindex $data(itemList) $row] $col]
	}

	default {
	    set key [lindex [lindex $data(itemList) $row] end]
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

    if {[string compare $varName ""] == 0} {
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
    upvar ::tablelist::ns${win}::data data

    #
    # Force any geometry manager calculations to be completed first
    #
    update idletasks

    #
    # Reconfigure the cells specified in the list data(cellsToReconfig)
    #
    foreach cellIdx $data(cellsToReconfig) {
	foreach {row col} [split $cellIdx ","] {}
	set key [lindex [lindex $data(itemList) $row] end]
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

    set key [lindex [lindex $data(itemList) $row] end]
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
proc tablelist::getEditWindow {win row col} {
    upvar ::tablelist::ns${win}::data data

    set key [lindex [lindex $data(itemList) $row] end]
    if {[info exists data($key,$col-editwindow)]} {
	return $data($key,$col-editwindow)
    } elseif {[info exists data($col-editwindow)]} {
	return $data($col-editwindow)
    } else {
	return "entry"
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
# Copyright (c) 2003-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#
# Namespace initialization
# ========================
#

namespace eval tablelist {
    #
    # Define the binding tag TablelistEdit
    #
    proc defineTablelistEdit {} {
	#
	# Get the supported modifier keys in the set {Alt, Meta, Command} on
	# the current windowing system ("x11", "win32", "classic", or "aqua")
	#
	variable winSys
	if {[catch {tk windowingsystem} winSys] != 0} {
	    switch $::tcl_platform(platform) {
		unix      { set winSys x11 }
		windows   { set winSys win32 }
		macintosh { set winSys classic }
	    }
	}
	switch $winSys {
	    x11		{ set modList {Alt Meta} }
	    win32	{ set modList {Alt} }
	    classic -
	    aqua	{ set modList {Command} }
	}

	#
	# Define some bindings for the binding tag TablelistEdit
	#
	bind TablelistEdit <Button-1> {
	    set tablelist::priv(clicked) 1
	    set tablelist::priv(clickedInEditWin) 1
	    focus %W
	}
	bind TablelistEdit <ButtonRelease-1> {
	    if {%t != 0} {			;# i.e., no generated event
		foreach {tablelist::W tablelist::x tablelist::y} \
		    [tablelist::convEventFields %W %x %y] {}

		set tablelist::priv(x) ""
		set tablelist::priv(y) ""
		set tablelist::priv(clicked) 0
		after cancel $tablelist::priv(afterId)
		set tablelist::priv(afterId) ""
		set tablelist::priv(releasedInEditWin) 1
		if {%t - $tablelist::priv(clickTime) < 300} {
		    tablelist::moveOrActivate $tablelist::W \
			$tablelist::priv(row) $tablelist::priv(col)
		} else {
		    tablelist::moveOrActivate $tablelist::W \
			[$tablelist::W nearest       $tablelist::y] \
			[$tablelist::W nearestcolumn $tablelist::x]
		}
		tablelist::condEvalInvokeCmd $tablelist::W
	    }
	}
	bind TablelistEdit <Control-i>    { tablelist::insertChar %W "\t" }
	bind TablelistEdit <Control-j>    { tablelist::insertChar %W "\n" }
	bind TablelistEdit <Escape>       { tablelist::cancelEditing %W }
	foreach key {Return KP_Enter} {
	    bind TablelistEdit <$key> {
		if {[string compare [winfo class %W] "Text"] == 0} {
		    tablelist::insertChar %W "\n"
		} else {
		    tablelist::finishEditing %W
		}
	    }
	    bind TablelistEdit <Control-$key> {
		tablelist::finishEditing %W
	    }
	}
	bind TablelistEdit <Tab>          { tablelist::goToNextPrevCell %W  1 }
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
		if {![tablelist::isComboTopMapped %W]} {
		    tablelist::genMouseWheelEvent \
			[[tablelist::getTablelistPath %W] bodypath] %D
		}
	    }
	}
	foreach detail {4 5} {
	    bind TablelistEdit <Button-$detail> [format {
		if {![tablelist::isComboTopMapped %%W]} {
		    event generate \
			[[tablelist::getTablelistPath %%W] bodypath] <Button-%s>
		}
	    } $detail]
	}
    }
    defineTablelistEdit 

    #
    # Register the Tk core widgets entry, text, checkbutton,
    # and spinbox for interactive cell editing
    #
    proc addTkCoreWidgets {} {
	set name entry
	array set ::tablelist::editWin [list \
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
	array set ::tablelist::editWin [list \
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
	array set ::tablelist::editWin [list \
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

	if {$::tk_version < 8.4} {
	    return ""
	}

	set name spinbox
	array set ::tablelist::editWin [list \
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
    # Register the tile widgets ttk::entry, ttk::combobox,
    # and ttk::checkbutton for interactive cell editing
    #
    proc addTileWidgets {} {
	set name ttk::entry
	array set ::tablelist::editWin [list \
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

	set name ttk::combobox
	array set ::tablelist::editWin [list \
	    $name-creationCmd	"createTileCombobox %W" \
	    $name-putValueCmd	"%W set %T" \
	    $name-getValueCmd	"%W get" \
	    $name-putTextCmd	"%W set %T" \
	    $name-getTextCmd	"%W get" \
	    $name-putListCmd	"" \
	    $name-getListCmd	"" \
	    $name-selectCmd	"" \
	    $name-invokeCmd	"event generate %W <Down>" \
	    $name-fontOpt	-font \
	    $name-useFormat	1 \
	    $name-useReqWidth	0 \
	    $name-usePadX	1 \
	    $name-isEntryLike	1 \
	    $name-focusWin	%W \
	    $name-reservedKeys	{Left Right Up Down} \
	]

	set name ttk::checkbutton
	array set ::tablelist::editWin [list \
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

    array set ::tablelist::editWin [list \
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

    array set ::tablelist::editWin [list \
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

    array set ::tablelist::editWin [list \
	$name-creationCmd	"ComboBox %W -editable 1 -width 0" \
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

    array set ::tablelist::editWin [list \
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
				  datefield|dateentry|timefield|timeentry\
				  ?-seconds? ?name?"
	}
    }
    checkEditWinName $name

    array set ::tablelist::editWin [list \
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
	lappend ::tablelist::editWin($name-getValueCmd) -clicks
	set ::tablelist::editWin($name-useFormat) 0
    }
    if {[string match "date*" $widgetType]} {
	set ::tablelist::editWin($name-focusWin) {[%W component date]}
    } else {
	set ::tablelist::editWin($name-focusWin) {[%W component time]}
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

    array set ::tablelist::editWin [list \
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

    array set ::tablelist::editWin [list \
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

    array set ::tablelist::editWin [list \
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
# tablelist::addOakleyCombobox
#
# Registers Bryan Oakley's combobox widget for interactive cell editing.
#------------------------------------------------------------------------------
proc tablelist::addOakleyCombobox {{name combobox}} {
    checkEditWinName $name

    array set ::tablelist::editWin [list \
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

    array set ::tablelist::editWin [list \
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

    array set ::tablelist::editWin [list \
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
    if {[catch {format %d $cnt1}] != 0 || $cnt1 <= 0} {
	return -code error "expected positive integer but got \"$cnt1\""
    }
    if {[catch {format %d $cnt2}] != 0 || $cnt2 <= 0} {
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

    array set ::tablelist::editWin [list \
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
	lappend ::tablelist::editWin($name-creationCmd) -comma
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

    array set ::tablelist::editWin [list \
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

#
# Private procedures implementing the interactive cell editing
# ============================================================
#

#------------------------------------------------------------------------------
# tablelist::checkEditWinName
#
# Generates an error if the given edit window name is one of "entry", "text",
# "spinbox", "checkbutton", "ttk::entry", "ttk::combobox", or
# "ttk::checkbutton".
#------------------------------------------------------------------------------
proc tablelist::checkEditWinName name {
    if {[regexp {^(entry|text|spinbox|checkbutton)$} $name]} {
	return -code error \
	       "edit window name \"$name\" is reserved for Tk $name widgets"
    }

    if {[regexp {^ttk::(entry|combobox|checkbutton)$} $name dummy name]} {
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
			   -selectimage $checkedImg -selectcolor ""
	    if {$::tk_version >= 8.4} {
		$w configure -offrelief sunken
	    }
	    pack $w
	}

	win32 {
	    checkbutton $w -borderwidth 0 -font {"MS Sans Serif" 8} \
			   -padx 0 -pady 0
	    [winfo parent $w] configure -width 13 -height 13
	    place $w -x -1 -y -1
	}

	classic {
	    checkbutton $w -borderwidth 0 -font "system" -padx 0 -pady 0
	    [winfo parent $w] configure -width 16 -height 14
	    place $w -x 0 -y -1
	}

	aqua {
	    checkbutton $w -borderwidth 0 -font "system" -padx 0 -pady 0
	    [winfo parent $w] configure -width 16 -height 17
	    place $w -x -3 -y -1
	}
    }

    foreach {opt val} $args {
	switch -- $opt {
	    -font  {}
	    -state { $w configure $opt $val }
	}
    }

    set win [getTablelistPath $w]
    $w configure -variable ::tablelist::ns${win}::data(editText)
}

#------------------------------------------------------------------------------
# tablelist::createTileEntry
#
# Creates a tile entry widget with the given path name for interactive cell
# editing in a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::createTileEntry {w args} {
    if {$::tk_version < 8.5 || [regexp {^8\.5a.$} $::tk_patchLevel]} {
	package require tile 0.6
    }

    #
    # The style of the tile entry widget should have -borderwidth
    # 2 and -padding 1.  For those themes that don't honor the
    # -borderwidth 2 setting, set the padding to another value.
    #
    set win [getTablelistPath $w]
    switch [getCurrentTheme] {
	aqua {
	    set padding {0 0 0 -1}
	}

	tileqt {
	    set padding 3
	}

	xpnative {
	    switch [winfo rgb . SystemButtonFace] {
		"60652 59881 55512" -
		"57568 57311 58339"	{ set padding 2 }
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
# tablelist::createTileCombobox
#
# Creates a tile combobox widget with the given path name for interactive cell
# editing in a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::createTileCombobox {w args} {
    if {$::tk_version < 8.5 || [regexp {^8\.5a.$} $::tk_patchLevel]} {
	package require tile 0.6
    }

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
    if {$::tk_version < 8.5 || [regexp {^8\.5a.$} $::tk_patchLevel]} {
	package require tile 0.6
    }

    #
    # Define the checkbutton layout; use catch to suppress
    # the error message in case the layout already exists
    #
    set currentTheme [getCurrentTheme]
    if {[string compare $currentTheme "aqua"] == 0} {
	catch { style layout Tablelist.TCheckbutton { Checkbutton.button } }
    } else {
	catch { style layout Tablelist.TCheckbutton { Checkbutton.indicator } }
	styleConfig Tablelist.TCheckbutton -indicatormargin 0
    }

    set win [getTablelistPath $w]
    ttk::checkbutton $w -style Tablelist.TCheckbutton \
			-variable ::tablelist::ns${win}::data(editText)

    foreach {opt val} $args {
	switch -- $opt {
	    -font  {}
	    -state { $w configure $opt $val }
	}
    }

    #
    # Adjust the dimensions of the tile checkbutton's parent
    # and manage the checkbutton, depending on the current theme
    #
    switch $currentTheme {
	aqua {
	    [winfo parent $w] configure -width 16 -height 17
	    place $w -x -3 -y -2
	}

	Aquativo {
	    [winfo parent $w] configure -width 14 -height 14
	    place $w -x -1 -y -1
	}

	blue -
	winxpblue {
	    set height [winfo reqheight $w]
	    [winfo parent $w] configure -width $height -height $height
	    place $w -x 0
	}

	keramik {
	    [winfo parent $w] configure -width 16 -height 16
	    place $w -x -1 -y -1
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
		kde_xp {
		    [winfo parent $w] configure -width 13 -height 13
		    place $w -x 0
		}
		keramik -
		thinkeramik {
		    [winfo parent $w] configure -width 16 -height 16
		    place $w -x 0
		}
		default {
		    set height [winfo reqheight $w]
		    [winfo parent $w] configure -width $height -height $height
		    place $w -x 0
		}
	    }
	}

	winnative -
	xpnative {
	    set height [winfo reqheight $w]
	    [winfo parent $w] configure -width $height -height $height
	    place $w -x -2
	}

	default {
	    pack $w
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
# tablelist::editcellSubCmd
#
# This procedure is invoked to process the tablelist editcell subcommand.  cmd
# may be an empty string, condChangeSelection, or changeSelection.  charPos
# stands for the character position component of the index in the body text
# widget of the character underneath the mouse cursor if this command was
# invoked by clicking mouse button 1 in the body of the tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::editcellSubCmd {win row col restore {cmd ""} {charPos -1}} {
    variable editWin
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled) || [doRowCget $row $win -hide] || $data($col-hide) ||
	![isCellEditable $win $row $col]} {
	return ""
    }
    if {$data(editRow) == $row && $data(editCol) == $col} {
	return ""
    }
    if {$data(editRow) >= 0 && ![finisheditingSubCmd $win]} {
	return ""
    }

    #
    # Create a frame to be embedded into the tablelist's body, together
    # with a child of column-specific type; replace the binding tag
    # Frame with TablelistEdit in the list of binding tags of the frame
    #
    seecellSubCmd $win $row $col
    set netRowHeight [lindex [bboxSubCmd $win $row] 3]
    set frameHeight [expr {$netRowHeight + 6}]	;# + 6 because of -pady -3 below
    set f $data(bodyFr)
    tk::frame $f -borderwidth 0 -container 0 -height $frameHeight \
		 -highlightthickness 0 -relief flat -takefocus 0
    catch {$f configure -padx 0 -pady 0}
    bindtags $f [lreplace [bindtags $f] 1 1 TablelistEdit]
    bind $f <Destroy> {
	array set tablelist::ns[winfo parent [winfo parent %W]]::data \
		  {editRow -1  editCol -1}
	if {[catch {tk::CancelRepeat}] != 0} {
	    tkCancelRepeat 
	}
	if {[catch {ttk::CancelRepeat}] != 0} {
	    catch {tile::CancelRepeat}
	}
    }
    set name [getEditWindow $win $row $col]
    set creationCmd [strMap {"%W" "$w"} $editWin($name-creationCmd)]
    set item [lindex $data(itemList) $row]
    set key [lindex $item end]
    append creationCmd { $editWin($name-fontOpt) [getCellFont $win $key $col]} \
		       { -state normal}
    set w $data(bodyFrEd)
    if {[catch {eval $creationCmd} result] != 0} {
	destroy $f
	return -code error $result
    }
    set class [winfo class $w]
    set isCheckbtn [string match "*Checkbutton" $class]
    set isText [expr {[string compare $class "Text"] == 0}]
    set isMentry [expr {[string compare $class "Mentry"] == 0}]
    catch {$w configure -relief ridge}
    catch {$w configure -highlightthickness 0}
    if {!$isCheckbtn} {
	catch {$w configure -borderwidth 2}
    }
    set alignment [lindex $data(colList) [expr {2*$col + 1}]]
    if {!$isText && !$isMentry} {
	catch {$w configure -justify $alignment}
    }
    clearTakefocusOpt $w

    #
    # Replace the cell contents between the two tabs with the above frame
    #
    set b $data(body)
    set data(editKey) $key
    set data(editRow) $row
    set data(editCol) $col
    findTabs $win [expr {$row + 1}] $col $col tabIdx1 tabIdx2
    if {$isCheckbtn} {
	set editIdx [$b index $tabIdx1+1c]
	$b delete $editIdx $tabIdx2
    } else {
	getAuxData $win $data(editKey) $data(editCol) auxType auxWidth
	if {$auxType == 0} {				;# no image or window
	    set editIdx [$b index $tabIdx1+1c]
	    $b delete $editIdx $tabIdx2
	} elseif {[string compare $alignment "right"] == 0} {
	    $b mark set editAuxMark $tabIdx2-1c
	    set editIdx [$b index $tabIdx1+1c]
	    $b delete $editIdx $tabIdx2-1c
	} else {
	    $b mark set editAuxMark $tabIdx1+1c
	    set editIdx [$b index $tabIdx1+2c]
	    $b delete $editIdx $tabIdx2
	}
    }
    $b window create $editIdx -padx -3 -pady -3 -window $f
    $b mark set editMark $editIdx

    #
    # Insert the binding tag TablelistEdit in the list of binding tags
    # of some components of w, just before the respective path names
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
	bindtags $comp [linsert $bindTags $idx TablelistEdit]
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
	if {$editWin($name-useFormat) &&
	    [info exists data($col-formatcommand)]} {
	    set text [uplevel #0 $data($col-formatcommand) [list $text]]
	}
	catch {
	    eval [strMap {"%W" "$w"  "%T" "$text"} $editWin($name-putValueCmd)]
	}
	if {[string compare $data(-editstartcommand) ""] != 0} {
	    set text [uplevel #0 $data(-editstartcommand) \
		      [list $win $row $col $text]]
	    if {$data(canceled)} {
		return ""
	    }
	    catch {
		eval [strMap {"%W" "$w"  "%T" "$text"} \
		      $editWin($name-putValueCmd)]
	    }
	}

	#
	# Save the edit window's text
	#
	set data(origEditText) \
	    [eval [strMap {"%W" "$w"} $editWin($name-getTextCmd)]]
	set data(rejected) 0

	if {$isText} {
	    #
	    # Adjust the edit window's height
	    #
	    scan [$w index end-1c] "%d" numLines
	    $w configure -height $numLines
	    if {[info exists ::wcb::version]} {
		wcb::callback $w after insert tablelist::adjustTextHeight
		wcb::callback $w after delete tablelist::adjustTextHeight
	    }
	}

	if {[string compare $editWin($name-getListCmd) ""] != 0 &&
	    [string compare $editWin($name-selectCmd) ""] != 0} {
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
	if {[string compare $cmd ""] != 0} {
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

    #
    # Adjust the frame's dimensions and paddings
    #
    update idletasks
    if {!$isCheckbtn} {
	$f configure -height [winfo reqheight $w]
	place $w -relwidth 1.0 -relheight 1.0
	set pixels [lindex $data(colList) [expr {2*$col}]]
	if {$pixels == 0} {			;# convention: dynamic width
	    set pixels $data($col-reqPixels)
	    if {$data($col-maxPixels) > 0} {
		if {$pixels > $data($col-maxPixels)} {
		    set pixels $data($col-maxPixels)
		}
	    }
	}
	incr pixels $data($col-delta)
	adjustEditWindow $win $pixels
	update idletasks
    }

    adjustElidedTextWhenIdle $win
    updateColorsWhenIdle $win
    adjustSepsWhenIdle $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::canceleditingSubCmd
#
# This procedure is invoked to process the tablelist cancelediting subcommand.
# Aborts the interactive cell editing and restores the cell's contents after
# destroying the edit window.
#------------------------------------------------------------------------------
proc tablelist::canceleditingSubCmd win {
    upvar ::tablelist::ns${win}::data data

    if {[set row $data(editRow)] < 0} {
	return ""
    }
    set col $data(editCol)

    #
    # Invoke the command specified by the -editendcommand option if needed
    #
    if {$data(-forceeditendcommand) &&
	[string compare $data(-editendcommand) ""] != 0} {
	uplevel #0 $data(-editendcommand) \
		[list $win $row $col $data(origEditText)]
    }

    if {[winfo exists $data(bodyFr)]} {
	destroy $data(bodyFr)
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
    set data(canceled) 1
    event generate $win <<TablelistCellRestored>>

    adjustElidedTextWhenIdle $win
    updateColorsWhenIdle $win
    adjustSepsWhenIdle $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::finisheditingSubCmd
#
# This procedure is invoked to process the tablelist finishediting subcommand.
# Invokes the command specified by the -editendcommand option if needed, and
# updates the element just edited after destroying the edit window if the
# latter's content was not rejected.  Returns 1 on normal termination and 0
# otherwise.
#------------------------------------------------------------------------------
proc tablelist::finisheditingSubCmd win {
    variable editWin
    upvar ::tablelist::ns${win}::data data

    if {[set row $data(editRow)] < 0} {
	return 1
    }
    set col $data(editCol)

    #
    # Get the edit window's text, and invoke the command
    # specified by the -editendcommand option if needed
    #
    set w $data(bodyFrEd)
    set name [getEditWindow $win $row $col]
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
	if {[string compare $data(-editendcommand) ""] != 0} {
	    set text \
		[uplevel #0 $data(-editendcommand) [list $win $row $col $text]]
	}
    }

    #
    # Check whether the input was rejected (by the above "set data(rejected) 1"
    # statement or within the command specified by the -editendcommand option)
    #
    if {$data(rejected)} {
	if {[winfo exists $data(bodyFr)]} {
	    seecellSubCmd $win $row $col
	    if {[string compare [winfo class $w] "Mentry"] != 0} {
		focus $data(editFocus)
	    }
	} else {
	    focus $data(body)
	}

	set data(rejected) 0
	set result 0
    } else {
	if {[winfo exists $data(bodyFr)]} {
	    destroy $data(bodyFr)
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
	event generate $win <<TablelistCellUpdated>>
    }

    adjustElidedTextWhenIdle $win
    updateColorsWhenIdle $win
    adjustSepsWhenIdle $win
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
# text widget used for interactive cell editing.  It sets the height of the
# edit window to the number of lines currently contained in it.
#------------------------------------------------------------------------------
proc tablelist::adjustTextHeight {w args} {
    scan [$w index end-1c] "%d" numLines
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
    variable editWin
    upvar ::tablelist::ns${win}::data data

    #
    # Adjust the width of the auxiliary object (if any)
    #
    set aux [getAuxData $win $data(editKey) $data(editCol) auxType auxWidth]
    if {$auxType != 0} {				;# image or window
	if {$auxWidth + 4 <= $pixels} {
	    incr auxWidth 4
	    incr pixels -$auxWidth
	} elseif {$auxWidth <= $pixels} {
	    set pixels 0
	} else {
	    set auxWidth $pixels
	    set pixels 0
	}

	if {$auxType == 1} {					;# image
	    setImgLabelWidth $data(body) editAuxMark $auxWidth
	} else {						;# window
	    if {[$aux cget -width] != $auxWidth} {
		$aux configure -width $auxWidth
	    }
	}
    }

    #
    # Compute an appropriate width and horizontal
    # padding for the frame containing the edit window
    #
    set name [getEditWindow $win $data(editRow) $data(editCol)]
    if {$editWin($name-useReqWidth) &&
	[set reqWidth [winfo reqwidth $data(bodyFrEd)]] <=
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

    $data(bodyFr) configure -width $width
    $data(body) window configure editMark -padx $padX
}

#------------------------------------------------------------------------------
# tablelist::setEditWinFont
#
# Sets the font of the edit window associated with the tablelist widget win to
# that of the cell currently being edited.
#------------------------------------------------------------------------------
proc tablelist::setEditWinFont win {
    variable editWin
    upvar ::tablelist::ns${win}::data data

    set name [getEditWindow $win $data(editRow) $data(editCol)]
    if {[string compare $editWin($name-fontOpt) ""] == 0} {
	return ""
    }

    set key [lindex [lindex $data(itemList) $data(editRow)] end] 
    set cellFont [getCellFont $win $key $data(editCol)]
    $data(bodyFrEd) configure $editWin($name-fontOpt) $cellFont

    $data(bodyFr) configure -height [winfo reqheight $data(bodyFrEd)]
}

#------------------------------------------------------------------------------
# tablelist::saveEditData
#
# Saves some data of the edit window associated with the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::saveEditData win {
    variable editWin
    upvar ::tablelist::ns${win}::data data

    set w $data(bodyFrEd)
    set entry $data(editFocus)
    set class [winfo class $w]
    set isText [expr {[string compare $class "Text"] == 0}]
    set isMentry [expr {[string compare $class "Mentry"] == 0}]

    #
    # Miscellaneous data
    #
    set name [getEditWindow $win $data(editRow) $data(editCol)]
    set data(editText) [eval [strMap {"%W" "$w"} $editWin($name-getTextCmd)]]
    if {[string compare $editWin($name-getListCmd) ""] != 0} {
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
	foreach when {before after} {
	    foreach opt {insert delete motion} {
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
		set data($tail$opt) [lindex $configSet 4]
	    }
	}
    }

    foreach c [winfo children $w] {
	saveEditConfigOpts $c
    }
}

#------------------------------------------------------------------------------
# tablelist::restoreEditData
#
# Restores some data of the edit window associated with the tablelist widget
# win.
#------------------------------------------------------------------------------
proc tablelist::restoreEditData win {
    variable editWin
    upvar ::tablelist::ns${win}::data data

    set w $data(bodyFrEd)
    set entry $data(editFocus)
    set class [winfo class $w]
    set isText [expr {[string compare $class "Text"] == 0}]
    set isMentry [expr {[string compare $class "Mentry"] == 0}]
    set isIncrDateTimeWidget [regexp {^(Date.+|Time.+)$} $class]

    #
    # Miscellaneous data
    #
    set name [getEditWindow $win $data(editRow) $data(editCol)]
    if {[string compare $editWin($name-putTextCmd) ""] != 0} {
	eval [strMap {"%W" "$w"  "%T" "$data(editText)"} \
	      $editWin($name-putTextCmd)]
    }
    if {[string compare $editWin($name-putListCmd) ""] != 0 &&
	[string compare $data(editList) ""] != 0} {
	eval [strMap {"%W" "$w"  "%L" "$data(editList)"} \
	      $editWin($name-putListCmd)]
    }
    if {[string compare $editWin($name-selectCmd) ""] != 0 &&
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
	foreach when {before after} {
	    foreach opt {insert delete motion} {
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
}

#
# Private procedures used in bindings related to interactive cell editing
# =======================================================================
#

#------------------------------------------------------------------------------
# tablelist::insertChar
#
# Inserts the string str ("\t" or "\n") into the entry-like widget w at the
# point of the insertion cursor.
#------------------------------------------------------------------------------
proc tablelist::insertChar {w str} {
    set class [winfo class $w]
    if {[string compare $class "Text"] == 0} {
	if {[string compare $str "\n"] == 0} {
	    eval [strMap {"%W" "$w"} [bind Text <Return>]]
	} else {
	    eval [strMap {"%W" "$w"} [bind Text <Control-i>]]
	}
	return -code break ""
    } elseif {[regexp {^(T?Entry|TCombobox|Spinbox)$} $class]} {
	if {[string match "T*" $class]} {
	    if {[string compare [info procs "::ttk::entry::Insert"] ""] != 0} {
		ttk::entry::Insert $w $str
	    } else {
		tile::entry::Insert $w $str
	    }
	} elseif {[string compare [info procs "::tk::EntryInsert"] ""] != 0} {
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
# Invokes the canceleditingSubCmd procedure.
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

    canceleditingSubCmd $win
    return -code break ""
}

#------------------------------------------------------------------------------
# tablelist::finishEditing
#
# Invokes the finisheditingSubCmd procedure.
#------------------------------------------------------------------------------
proc tablelist::finishEditing w {
    if {[isComboTopMapped $w]} {
	return ""
    }

    finisheditingSubCmd [getTablelistPath $w]
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

    set win [getTablelistPath $w]
    upvar ::tablelist::ns${win}::data data

    if {[llength $args] == 0} {
	set row $data(editRow)
	set col $data(editCol)
	set cmd condChangeSelection
    } else {
	set row [lindex $args 0]
	set col [lindex $args 1]
	set cmd changeSelection
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
	} elseif {![doRowCget $row $win -hide] && !$data($col-hide) &&
		  [isCellEditable $win $row $col]} {
	    editcellSubCmd $win $row $col 0 $cmd
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

    while 1 {
	incr col $amount
	if {$col < 0 || $col > $data(lastCol)} {
	    return -code break ""
	} elseif {!$data($col-hide) && [isCellEditable $win $row $col]} {
	    editcellSubCmd $win $row $col 0 condChangeSelection
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

    while 1 {
	incr row $amount
	if {$row < 0 || $row > $data(lastRow)} {
	    return 0
	} elseif {![doRowCget $row $win -hide] &&
		  [isCellEditable $win $row $col]} {
	    editcellSubCmd $win $row $col 0 $cmd
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
    # Check whether there is any non-hidden editable cell
    # above/below the current one, in the same column
    #
    set row $data(editRow)
    set col $data(editCol)
    while 1 {
	incr row $amount
	if {$row < 0 || $row > $data(lastRow)} {
	    return -code break ""
	} elseif {![doRowCget $row $win -hide] &&
		  [isCellEditable $win $row $col]} {
	    break
	}
    }

    #
    # Scroll up/down the view by one page and get the corresponding row index
    #
    set row $data(editRow)
    seeSubCmd $win $row
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
# tablelist::isKeyReserved
#
# Checks whether the given keysym is used in the standard binding scripts
# associated with the widget w, which is assumed to be the edit window or one
# of its descendants.
#------------------------------------------------------------------------------
proc tablelist::isKeyReserved {w keySym} {
    variable editWin
    set win [getTablelistPath $w]
    upvar ::tablelist::ns${win}::data data

    set name [getEditWindow $win $data(editRow) $data(editCol)]
    return [expr {[lsearch -exact $editWin($name-reservedKeys) $keySym] >= 0}]
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
# Contains the implementation of the tablelist move and movecolumn subcommands.
#
# Copyright (c) 2003-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#------------------------------------------------------------------------------
# tablelist::moveSubCmd
#
# This procedure is invoked to process the tablelist move subcommand.
#------------------------------------------------------------------------------
proc tablelist::moveSubCmd {win source target} {
    variable canElide
    variable elide
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
    if {$target == $source} {
	return -code error \
	       "cannot move item with index \"$source\" before itself"
    } elseif {$target == $source + 1} {
	return ""
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
    set w $data(body)
    set selectedCols {}
    set line [expr {$source + 1}]
    set textIdx [expr {double($line)}]
    for {set col 0} {$col < $data(colCount)} {incr col} {
	if {$data($col-hide) && !$canElide} {
	    continue
	}

	if {[lsearch -exact [$w tag names $textIdx] select] >= 0} {
	    lappend selectedCols $col
	}
	set textIdx [$w search $elide "\t" $textIdx+1c $line.end]+1c
    }
    $w delete [expr {double($source + 1)}] [expr {double($source + 2)}]

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
    set sourceItem [lindex $data(itemList) $source]
    if {[lsearch -exact $data(fmtCmdFlagList) 1] >= 0} {
	set formattedItem \
	    [formatItem $win [lrange $sourceItem 0 $data(lastCol)]]
    } else {
	set formattedItem [lrange $sourceItem 0 $data(lastCol)]
    }
    set key [lindex $sourceItem end]
    set col 0
    foreach text [strToDispStr $formattedItem] \
	    colTags $data(colTagsList) \
	    {pixels alignment} $data(colList) {
	if {$data($col-hide) && !$canElide} {
	    incr col
	    continue
	}

	#
	# Build the list of tags to be applied to the cell
	#
	set cellTags $colTags
	foreach opt {-background -foreground -font} {
	    if {[info exists data($key,$col$opt)]} {
		lappend cellTags cell$opt-$data($key,$col$opt)
	    }
	}

	#
	# Append the text and the label or window
	# (if any) to the target line of body text widget
	#
	appendComplexElem $win $key $source $col $text $pixels \
			  $alignment $snipStr $cellTags $targetLine

	incr col
    }
    foreach opt {-background -foreground -font} {
	if {[info exists data($key$opt)]} {
	    $w tag add row$opt-$data($key$opt) $targetLine.0 $targetLine.end
	}
    }

    #
    # Update the item list
    #
    set data(itemList) [lreplace $data(itemList) $source $source]
    if {$target == $data(itemCount)} {
	lappend data(itemList) $sourceItem	;# this works much faster
    } else {
	set data(itemList) [linsert $data(itemList) $target1 $sourceItem]
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
    # Update anchorRow and activeRow if needed
    #
    if {$data(anchorRow) == $source} {
	set data(anchorRow) $target1
    }
    if {$data(activeRow) == $source} {
	set data(activeRow) $target1
    }

    #
    # Invalidate the list of the row indices indicating the non-hidden rows
    #
    set data(nonHiddenRowList) {-1}

    #
    # Select those source elements that were selected before
    #
    foreach col $selectedCols {
	cellselectionSubCmd $win set $target1 $col $target1 $col
    }

    #
    # Adjust the elided text, restore the stripes in the body
    # text widget, and redisplay the line numbers (if any)
    #
    adjustElidedText $win
    makeStripes $win
    showLineNumbersWhenIdle $win

    #
    # Restore the edit window if it was present before
    #
    if {$editCol >= 0} {
	if {$editRow == $source} {
	    editcellSubCmd $win $target1 $editCol 1
	} else {
	    set data(editRow) [lsearch $data(itemList) "* $editKey"]
	}
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::movecolumnSubCmd
#
# This procedure is invoked to process the tablelist movecolumn subcommand.
#------------------------------------------------------------------------------
proc tablelist::movecolumnSubCmd {win source target} {
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled)} {
	return ""
    }

    #
    # Check the indices
    #
    if {$target == $source} {
	return -code error \
	       "cannot move column with index \"$source\" before itself"
    } elseif {$target == $source + 1} {
	return ""
    }

    #
    # Update the column list
    #
    set source3 [expr {3*$source}]
    set source3Plus2 [expr {$source3 + 2}]
    set target1 $target
    set target3 [expr {3*$target}]
    if {$source < $target} {
	incr target1 -1
	incr target3 -3
    }
    set sourceRange [lrange $data(-columns) $source3 $source3Plus2]
    set data(-columns) [lreplace $data(-columns) $source3 $source3Plus2]
    set data(-columns) [eval linsert {$data(-columns)} $target3 $sourceRange]

    #
    # Save some elements of data corresponding to source
    #
    array set tmp [array get data $source-*]
    array set tmp [array get data k*,$source-*]
    foreach specialCol {activeCol anchorCol editCol} {
	set tmp($specialCol) $data($specialCol)
    }
    set selCells [curcellselectionSubCmd $win]
    set tmpRows [extractColFromCellList $selCells $source]

    #
    # Remove source from the list of stretchable columns
    # if it was explicitly specified as stretchable
    #
    if {[string first $data(-stretch) "all"] != 0} {
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
    # Build two lists of column numbers, neeeded
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
    # Move the elements of data corresponding to the columns in oldCols to the
    # elements corresponding to the columns with the same indices in newCols
    #
    foreach oldCol $oldCols newCol $newCols {
	moveColData $win data data imgs $oldCol $newCol
	set selCells [replaceColInCellList $selCells $oldCol $newCol]
    }

    #
    # Move the elements of data corresponding to
    # source to the elements corresponding to target1
    #
    moveColData $win tmp data imgs $source $target1
    set selCells [deleteColFromCellList $selCells $target1]
    foreach row $tmpRows {
	lappend selCells $row,$target1
    }

    #
    # If the column given by source was explicitly specified as
    # stretchable then add target1 to the list of stretchable columns
    #
    if {[string first $data(-stretch) "all"] != 0 && $sourceIsStretchable} {
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
    # Reconfigure the relevant column labels
    #
    foreach col [lappend newCols $target1] {
	reconfigColLabels $win imgs $col
    }

    #
    # Redisplay the items
    #
    redisplay $win 0 $selCells

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
# Copyright (c) 2000-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
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
	event generate $win <<TablelistColumnSorted>>
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
	event generate $win <<TablelistColumnsSorted>>
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
# tablelist::sortSubCmd
#
# This procedure is invoked to process the tablelist sort, sortbycolumn, and
# sortbycolumnlist subcommands.
#------------------------------------------------------------------------------
proc tablelist::sortSubCmd {win sortColList sortOrderList} {
    variable canElide
    variable snipSides
    upvar ::tablelist::ns${win}::data data

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
	set ${type}Key [lindex [lindex $data(itemList) $data(${type}Row)] end]
    }
    set selCells [curcellselectionSubCmd $win 1]

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
    if {[llength $sortColList] == 1 && [lindex $sortColList 0] == -1} {
	if {[string compare $data(-sortcommand) ""] == 0} {
	    return -code error "value of the -sortcommand option is empty"
	}

	#
	# Update the sort info
	#
	for {set col 0} {$col < $data(colCount)} {incr col} {
	    set data($col-sortRank) 0
	    set data($col-sortOrder) ""
	}
	set data(sortColList) {}
	set data(arrowColList) {}
	set order [lindex $sortOrderList 0]
	set data(sortOrder) $order

	#
	# Sort the item list
	#
	set data(itemList) \
	    [lsort -$order -command $data(-sortcommand) $data(itemList)]
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

	#
	# Sort the item list based on the specified columns
	#
	for {set idx [expr {$sortColCount - 1}]} {$idx >= 0} {incr idx -1} {
	    set col [lindex $sortColList $idx]
	    if {$data($col-showlinenumbers)} {
		continue
	    }

	    set order $data($col-sortOrder)
	    if {[string compare $data($col-sortmode) "command"] == 0} {
		if {![info exists data($col-sortcommand)]} {
		    return -code error "value of the -sortcommand option for\
					column $col is missing or empty"
		}

		set data(itemList) [lsort -$order -index $col \
		    -command $data($col-sortcommand) $data(itemList)]
	    } else {
		set data(itemList) [lsort -$order -index $col \
		    -$data($col-sortmode) $data(itemList)]
	    }
	}
    }

    #
    # Update the line numbers (if any)
    #
    for {set col 0} {$col < $data(colCount)} {incr col} {
	if {!$data($col-showlinenumbers)} {
	    continue
	}

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
    }

    #
    # Replace the contents of the list variable if present
    #
    condUpdateListVar $win

    #
    # Update anchorRow and activeRow
    #
    foreach type {anchor active} {
	upvar 0 ${type}Key key2
	if {[string compare $key2 ""] != 0} {
	    set data(${type}Row) [lsearch $data(itemList) "* $key2"]
	}
    }

    #
    # Cancel the execution of all delayed redisplay and redisplayCol commands
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
	    set data(colList) [lreplace $data(colList) $idx $idx $canvasWidth]
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

    #
    # Delete the items from the body text widget and insert the sorted ones.
    # Interestingly, for a large number of items it is much more efficient
    # to empty each line individually than to invoke a global delete command.
    #
    set w $data(body)
    $w tag remove hiddenRow 1.0 end
    for {set line 1} {$line <= $data(itemCount)} {incr line} {
	$w delete $line.0 $line.end
    }
    set snipStr $data(-snipstring)
    set tagRefCount $data(tagRefCount)
    set isSimple [expr {$data(imgCount) == 0 && $data(winCount) == 0}]
    set hasFmtCmds [expr {[lsearch -exact $data(fmtCmdFlagList) 1] >= 0}]
    set row 0
    set line 1
    foreach item $data(itemList) {
	if {$hasFmtCmds} {
	    set formattedItem [formatItem $win [lrange $item 0 $data(lastCol)]]
	} else {
	    set formattedItem [lrange $item 0 $data(lastCol)]
	}

	#
	# Clip the elements if necessary and
	# insert them with the corresponding tags
	#
	set key [lindex $item end]
	set col 0
	if {$isSimple} {
	    set insertArgs {}
	    set multilineData {}
	    foreach text [strToDispStr $formattedItem] \
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
		set cellFont $colFont
		set cellTags $colTags
		if {$tagRefCount != 0} {
		    set cellFont [getCellFont $win $key $col]
		    foreach opt {-background -foreground -font} {
			if {[info exists data($key,$col$opt)]} {
			    lappend cellTags cell$opt-$data($key,$col$opt)
			}
		    }
		}

		#
		# Clip the element if necessary
		#
		if {[string match "*\n*" $text]} {
		    set multiline 1
		    set list [split $text "\n"]
		} else {
		    set multiline 0
		}
		if {$pixels == 0} {		;# convention: dynamic width
		    if {$data($col-maxPixels) > 0} {
			if {$data($col-reqPixels) > $data($col-maxPixels)} {
			    set pixels $data($col-maxPixels)
			}
		    }
		}
		if {$pixels != 0} {
		    incr pixels $data($col-delta)
		    set snipSide \
			$snipSides($alignment,$data($col-changesnipside))
		    if {$multiline} {
			set text [joinList $win $list $cellFont \
				  $pixels $snipSide $snipStr]
		    } else {
			set text [strRange $win $text $cellFont \
				  $pixels $snipSide $snipStr]
		    }
		}

		if {$multiline} {
		    lappend insertArgs "\t\t" $cellTags
		    lappend multilineData $col $text $colFont $alignment
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
	    foreach {col text font alignment} $multilineData {
		findTabs $win $line $col $col tabIdx1 tabIdx2
		set msgScript [list ::tablelist::displayText $win $key \
			       $col $text $font $alignment]
		$w window create $tabIdx2 -pady 1 -create $msgScript
	    }

	} else {
	    foreach text [strToDispStr $formattedItem] \
		    colTags $data(colTagsList) \
		    {pixels alignment} $data(colList) {
		if {$data($col-hide) && !$canElide} {
		    incr col
		    continue
		}

		#
		# Build the list of tags to be applied to the cell
		#
		set cellTags $colTags
		if {$tagRefCount != 0} {
		    foreach opt {-background -foreground -font} {
			if {[info exists data($key,$col$opt)]} {
			    lappend cellTags cell$opt-$data($key,$col$opt)
			}
		    }
		}

		#
		# Insert the text and the label or window
		# (if any) into the body text widget
		#
		appendComplexElem $win $key $row $col $text $pixels \
				  $alignment $snipStr $cellTags $line

		incr col
	    }
	}

	if {$tagRefCount != 0} {
	    foreach opt {-background -foreground -font} {
		if {[info exists data($key$opt)]} {
		    $w tag add row$opt-$data($key$opt) $line.0 $line.end
		}
	    }
	}

	if {[info exists data($key-hide)]} {
	    $w tag add hiddenRow $line.0 $line.end+1c
	}

	set row $line
	incr line
    }

    #
    # Invalidate the list of the row indices indicating the non-hidden rows
    #
    set data(nonHiddenRowList) {-1}

    #
    # Select the cells that were selected before
    #
    foreach {key col} $selCells {
	set row [lsearch $data(itemList) "* $key"]
	cellselectionSubCmd $win set $row $col $row $col
    }

    #
    # Disable the body text widget if it was disabled before
    #
    if {$data(isDisabled)} {
	$w tag add disabled 1.0 end
	$w tag configure select -borderwidth 0
    }

    #
    # Bring the "most important" row into view
    #
    if {$editCol >= 0} {
	set editRow [lsearch $data(itemList) "* $editKey"]
	seeSubCmd $win $editRow
    } else {
	set selRows [curselectionSubCmd $win]
	if {[llength $selRows] == 1} {
	    seeSubCmd $win $selRows
	} elseif {[string compare [focus -lastfor $w] $w] == 0} {
	    seeSubCmd $win $data(activeRow)
	}
    }

    #
    # Adjust the elided text and restore the stripes in the body text widget
    #
    adjustElidedText $win
    makeStripes $win

    #
    # Restore the edit window if it was present before
    #
    if {$editCol >= 0} {
	editcellSubCmd $win $editRow $editCol 1
    }

    #
    # Work around a Tk bug on Mac OS X Aqua
    #
    variable winSys
    if {[string compare $winSys "aqua"] == 0} {
	foreach col $data(arrowColList) {
	    set canvas [list $data(hdrTxtFrCanv)$col]
	    after idle "lower $canvas; raise $canvas"
	}
    }

    return ""
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
# Copyright (c) 2005-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
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
# tablelist configuration options.
#------------------------------------------------------------------------------
proc tablelist::setThemeDefaults {} {
    set currentTheme [getCurrentTheme]
    if {[catch {${currentTheme}Theme}] != 0} {
	return -code error "theme \"$currentTheme\" not supported"
    }

    variable themeDefaults
    if {[string compare $themeDefaults(-arrowcolor) ""] == 0} {
	set themeDefaults(-arrowdisabledcolor) ""
    } else {
	set themeDefaults(-arrowdisabledcolor) $themeDefaults(-labeldisabledFg)
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
    ]
}

#------------------------------------------------------------------------------
# tablelist::aquaTheme
#------------------------------------------------------------------------------
proc tablelist::aquaTheme {} {
    #
    # Get an approximation of alternateSelectedControlColor
    #
    switch [winfo rgb . systemHighlight] {
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
	-stripebackground	"" \
	-selectbackground	$selectBg \
	-selectforeground	white \
	-selectborderwidth	0 \
	-font			TkTooltipFont \
        -labelbackground	#f4f4f4 \
	-labeldisabledBg	#f4f4f4 \
	-labelactiveBg		#f4f4f4 \
	-labelpressedBg		#e4e4e4 \
	-labelforeground	black \
	-labeldisabledFg	#a3a3a3 \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkHeadingFont \
	-labelborderwidth	1 \
	-labelpady		1 \
	-arrowcolor		#777777 \
	-arrowstyle		flat7x7 \
    ]
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
	-stripebackground	"" \
	-selectbackground	#000000 \
	-selectforeground	#ffffff \
	-selectborderwidth	0 \
	-font			TkTextFont \
        -labelbackground	#fafafa \
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
	-arrowcolor		#777777 \
	-arrowstyle		flat7x7 \
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
	-arrowcolor		"" \
	-arrowstyle		sunken10x9 \
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
	-labeldisabledBg	#dcdad5 \
	-labelactiveBg		#eeebe7 \
	-labelpressedBg		#eeebe7 \
	-labelforeground	black \
	-labeldisabledFg	#999999 \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		1 \
	-arrowcolor		"" \
	-arrowstyle		sunken10x9 \
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
    ]

    if {[info exists tile::version] &&
	[string compare $tile::version 0.8] < 0} {
	set themeDefaults(-font)	TkClassicDefaultFont
	set themeDefaults(-labelfont)	TkClassicDefaultFont
    }
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
	-arrowcolor		"" \
	-arrowstyle		sunken10x9 \
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
	-selectbackground	#000000 \
	-selectforeground	#ffffff \
	-selectborderwidth	0 \
	-font			TkTextFont \
        -labelbackground	#cccccc \
	-labeldisabledBg	#cccccc \
	-labelactiveBg		#cccccc \
	-labelpressedBg		#cccccc \
	-labelforeground	black \
	-labeldisabledFg	#aaaaaa \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		1 \
	-arrowcolor		black \
	-arrowstyle		flat8x5 \
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
	-arrowcolor		"" \
	-arrowstyle		sunken10x9 \
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
        -labelbackground	#cccccc \
	-labeldisabledBg	#cccccc \
	-labelactiveBg		#cccccc \
	-labelpressedBg		#cccccc \
	-labelforeground	black \
	-labeldisabledFg	#aaaaaa \
	-labelactiveFg		black \
	-labelpressedFg		black \
	-labelfont		TkDefaultFont \
	-labelborderwidth	2 \
	-labelpady		1 \
	-arrowcolor		black \
	-arrowstyle		flat7x4 \
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
	-arrowcolor		"" \
	-arrowstyle		sunken10x9 \
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
	-arrowcolor		"" \
	-arrowstyle		sunken10x9 \
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
	-arrowcolor		"" \
	-arrowstyle		sunken10x9 \
    ]
}

#------------------------------------------------------------------------------
# tablelist::tileqtTheme
#
# Tested with the following Qt styles:
#
#   Acqua              KDE_XP                     Motif Plus     SGI
#   B3/KDE             Keramik                    MS Windows 9x  System-Series
#   Baghira            Light Style, 2nd revision  Phase          System++
#   CDE                Light Style, 3rd revision  Plastik        ThinKeramik
#   HighColor Classic  Lipstik                    Platinum
#   HighContrast       Marble                     QtCurve
#   KDE Classic        Motif                      RISC OS
#
# Supported color schemes:
#
#   Aqua Blue                     Ice (FreddyK)      Point Reyes Green
#   Aqua Graphite                 KDE 1              Pumpkin
#   Atlas Green                   KDE 2              Redmond 2000
#   BeOS                          Keramik            Redmond 95
#   Blue Slate                    Keramik Emerald    Redmond XP
#   CDE                           Keramik White      Solaris
#   Dark Blue                     Lipstik Noble      Storm
#   Desert Red                    Lipstik Standard   SuSE, old & new
#   Digital CDE                   Lipstik White      SUSE-kdm
#   EveX                          Media Peach        System
#   High Contrast Black Text      Next               Thin Keramik, old & new
#   High Contrast Yellow on Blue  Pale Gray          Thin Keramik II
#   High Contrast White Text      Plastik
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
    }

    #
    # For some Qt styles the label colors are independent of the color scheme:
    #
    switch -- $style {
	"acqua" {
	    set labelBg #e7e7e7;  set labelFg #000000;  set pressedBg #8fbeec
	}

	"kde_xp" {
	    set labelBg #ebeadb;  set labelFg #000000;  set pressedBg #faf8f3
	}

	"lipstik" {
	    set labelBg $bg;                            set pressedBg $labelBg
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
    if {[set val [getKdeConfigVal "General" "alternateBackground"]] eq ""} {
	set stripeBg ""
    } elseif {[string range $val 0 0] eq "#"} {
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
	"plastik"	{ set arrowColor $labelFg;  set arrowStyle flat7x4 }

	"baghira"	{ set arrowColor $labelFg;  set arrowStyle flat7x7 }

	"qtcurve"	{ set arrowColor $labelFg;  set arrowStyle flat7x5 }

	"keramik" -
	"thinkeramik"	{ set arrowColor $labelFg;  set arrowStyle flat8x5 }

	default		{ set arrowColor "";	    set arrowStyle sunken12x11 }
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
	-arrowcolor		#aca899 \
	-arrowstyle		flat9x5 \
    ]
}

#------------------------------------------------------------------------------
# tablelist::xpnativeTheme
#------------------------------------------------------------------------------
proc tablelist::xpnativeTheme {} {
    variable xpStyle
    switch [winfo rgb . SystemButtonFace] {
	"60652 59881 55512" {
	    set xpStyle		1
	    set labelBg		#ebeadb
	    set activeBg	#faf8f3
	    set pressedBg	#dedfd8
	    set labelBd		4
	    set labelPadY	4
	    set arrowColor	#aca899
	    set arrowStyle	flat9x5

	    if {[info exists tile::version] &&
		[string compare $tile::version 0.7] < 0} {
		set labelBd 0
	    }
	}

	"57568 57311 58339" {
	    set xpStyle		1
	    set labelBg		#f9fafd
	    set activeBg	#fefefe
	    set pressedBg	#ececf3
	    set labelBd		4
	    set labelPadY	4
	    set arrowColor	#aca899
	    set arrowStyle	flat9x5

	    if {[info exists tile::version] &&
		[string compare $tile::version 0.7] < 0} {
		set labelBd 0
	    }
	}

	default {
	    set xpStyle		0
	    set labelBg		SystemButtonFace
	    set activeBg	SystemButtonFace
	    set pressedBg	SystemButtonFace
	    set labelBd		2
	    set labelPadY	0
	    set arrowColor	SystemButtonShadow
	    set arrowStyle	flat7x4
	}
    }

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
        -labelbackground	$labelBg \
	-labeldisabledBg	$labelBg \
	-labelactiveBg		$activeBg \
	-labelpressedBg		$pressedBg \
	-labelforeground	SystemButtonText \
	-labeldisabledFg	SystemDisabledText \
	-labelactiveFg		SystemButtonText \
	-labelpressedFg		SystemButtonText \
	-labelfont		TkDefaultFont \
	-labelborderwidth	$labelBd \
	-labelpady		$labelPadY \
	-arrowcolor		$arrowColor \
	-arrowstyle		$arrowStyle \
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
    set sortedLst [lsort -real [list $r $g $b]]
    set v [lindex $sortedLst end]
    set dist [expr {$v - [lindex $sortedLst 0]}]

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

    if {[info exists ::env(USER)] && $::env(USER) eq "root"} {
	set name "KDEROOTHOME"
    } else {
	set name "KDEHOME"
    }
    if {[info exists ::env($name)] && $::env($name) ne ""} {
	set localKdeDir [file normalize $::env($name)]
    } elseif {[info exists ::env(HOME)] && $::env(HOME) ne ""} {
	set localKdeDir [file normalize [file join $::env(HOME) ".kde"]]
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

    set prefix [exec kde-config --prefix]
    lappend kdeDirList $prefix

    set execPrefix [exec kde-config --expandvars --exec-prefix]
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
	if {[string range $line 0 0] eq "\["} {
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
# Copyright (c) 2000-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
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
	right,0		r
	center,0	r
	center,0	l
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
# tablelist.
#------------------------------------------------------------------------------
proc tablelist::rowIndex {win idx endIsSize} {
    upvar ::tablelist::ns${win}::data data

    if {[catch {format "%d" $idx} index] == 0} {
	return $index
    } elseif {[string first $idx "end"] == 0} {
	if {$endIsSize} {
	    return $data(itemCount)
	} else {
	    return $data(lastRow)
	}
    } elseif {[string first $idx "active"] == 0 && [string length $idx] >= 2} {
	return $data(activeRow)
    } elseif {[string first $idx "anchor"] == 0 && [string length $idx] >= 2} {
	return $data(anchorRow)
    } elseif {[scan $idx "@%d,%d" x y] == 2} {
	incr x -[winfo x $data(body)]
	incr y -[winfo y $data(body)]
	set textIdx [$data(body) index @$x,$y]
	return [expr {int($textIdx) - 1}]
    } elseif {[string compare [string index $idx 0] "k"] == 0 &&
	      [set index [lsearch $data(itemList) "* $idx"]] >= 0} {
	return $index
    } else {
	for {set row 0} {$row < $data(itemCount)} {incr row} {
	    set key [lindex [lindex $data(itemList) $row] end]
	    set hasName [info exists data($key-name)]
	    if {$hasName && [string compare $idx $data($key-name)] == 0 ||
		!$hasName && [string compare $idx ""] == 0} {
		return $row
	    }
	}
	return -code error \
	       "bad row index \"$idx\": must be active, anchor,\
	        end, @x,y, a number, a full key, or a name"
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
proc tablelist::colIndex {win idx checkRange} {
    upvar ::tablelist::ns${win}::data data

    if {[catch {format "%d" $idx} index] == 0} {
	# nothing
    } elseif {[string first $idx "end"] == 0} {
	set index $data(lastCol)
    } elseif {[string first $idx "active"] == 0 && [string length $idx] >= 2} {
	set index $data(activeCol)
    } elseif {[string first $idx "anchor"] == 0 && [string length $idx] >= 2} {
	set index $data(anchorCol)
    } elseif {[scan $idx "@%d,%d" x y] == 2} {
	incr x -[winfo x $data(body)]
	set bodyWidth [winfo width $data(body)]
	if {$x >= $bodyWidth} {
	    set x [expr {$bodyWidth - 1}]
	} elseif {$x < 0} {
	    set x 0
	}
	set x [expr {$x + [winfo rootx $data(body)]}]

	set lastVisibleCol -1
	for {set col 0} {$col < $data(colCount)} {incr col} {
	    if {$data($col-hide) || $data($col-elide)} {
		continue
	    }

	    set lastVisibleCol $col
	    set w $data(hdrTxtFrLbl)$col
	    set wX [winfo rootx $w]
	    if {$x >= $wX && $x < $wX + [winfo width $w]} {
		return $col
	    }
	}
	set index $lastVisibleCol
    } else {
	for {set col 0} {$col < $data(colCount)} {incr col} {
	    set hasName [info exists data($col-name)]
	    if {($hasName && [string compare $idx $data($col-name)] == 0) ||
		(!$hasName && [string compare $idx ""] == 0)} {
		set index $col
		break
	    }
	}
	if {$col == $data(colCount)} {
	    return -code error \
		   "bad column index \"$idx\": must be active, anchor,\
		    end, @x,y, a number, or a name"
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
    } elseif {[string first $idx "end"] == 0} {
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
	       "bad cell index \"$idx\": must be active, anchor,\
		end, @x,y, or row,col, where row must be active,\
		anchor, end, a number, a full key, or a name, and\
		col must be active, anchor, end, a number, or a name"
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
# (non-hidden) row.
#------------------------------------------------------------------------------
proc tablelist::adjustRowIndex {win rowName {forceVisible 0}} {
    upvar ::tablelist::ns${win}::data data
    upvar $rowName row

    if {$row > $data(lastRow)} {
	set row $data(lastRow)
    }
    if {$row < 0} {
	set row 0
    }

    if {$forceVisible} {
	set origRow $row
	for {} {$row < $data(itemCount)} {incr row} {
	    set key [lindex [lindex $data(itemList) $row] end]
	    if {![info exists data($key-hide)]} {
		return ""
	    }
	}
	for {set row [expr {$origRow - 1}]} {$row >= 0} {incr row -1} {
	    set key [lindex [lindex $data(itemList) $row] end]
	    if {![info exists data($key-hide)]} {
		return ""
	    }
	}
	set row 0
    }
}

#------------------------------------------------------------------------------
# tablelist::adjustColIndex
#
# Sets the column index specified by $colName to the index of the nearest
# (non-hidden) column.
#------------------------------------------------------------------------------
proc tablelist::adjustColIndex {win colName {forceVisible 0}} {
    upvar ::tablelist::ns${win}::data data
    upvar $colName col

    if {$col > $data(lastCol)} {
	set col $data(lastCol)
    }
    if {$col < 0} {
	set col 0
    }

    if {$forceVisible} {
	set origCol $col
	for {} {$col < $data(colCount)} {incr col} {
	    if {!$data($col-hide)} {
		return ""
	    }
	}
	for {set col [expr {$origCol - 1}]} {$col >= 0} {incr col -1} {
	    if {!$data($col-hide)} {
		return ""
	    }
	}
	set col 0
    }
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
    variable canElide
    variable elide
    upvar ::tablelist::ns${win}::data data
    upvar $idx1Name idx1 $idx2Name idx2

    set w $data(body)
    set endIdx $line.end

    set idx $line.1
    for {set col 0} {$col < $firstCol} {incr col} {
	if {!$data($col-hide) || $canElide} {
	    set idx [$w search $elide "\t" $idx $endIdx]+2c
	}
    }
    set idx1 [$w index $idx-1c]

    for {} {$col < $lastCol} {incr col} {
	if {!$data($col-hide) || $canElide} {
	    set idx [$w search $elide "\t" $idx $endIdx]+2c
	}
    }
    set idx2 [$w search $elide "\t" $idx $endIdx]
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
	[string first $data(-stretch) "all"] == 0} {
	return ""
    }

    set containsEnd 0
    foreach elem $data(-stretch) {
	if {[string first $elem "end"] == 0} {
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
    set w $data(body)
    foreach name [array names data $col-*] {
	unset data($name)
    }

    #
    # Remove the elements with names of the form k*,$col-*
    #
    foreach name [array names data k*,$col-*] {
	unset data($name)
	if {[string match "k*,$col-\[bf\]*" $name]} {
	    incr data(tagRefCount) -1
	} elseif {[string match "k*,$col-image" $name]} {
	    incr data(imgCount) -1
	} elseif {[string match "k*,$col-window" $name]} {
	    incr data(winCount) -1
	}
    }

    #
    # Remove col from the list of stretchable columns if explicitly specified
    #
    if {[string first $data(-stretch) "all"] != 0} {
	set stretchableCols {}
	foreach elem $data(-stretch) {
	    if {[string first $elem "end"] == 0 || $elem != $col} {
		lappend stretchableCols $elem
	    }
	}
	set data(-stretch) $stretchableCols
    }
}

#------------------------------------------------------------------------------
# tablelist::moveColData
#
# Moves the elements of oldArrName corresponding to oldCol to those of
# newArrName corresponding to newCol.
#------------------------------------------------------------------------------
proc tablelist::moveColData {win oldArrName newArrName imgArrName
			     oldCol newCol} {
    upvar $oldArrName oldArr $newArrName newArr $imgArrName imgArr

    foreach specialCol {activeCol anchorCol editCol} {
	if {$oldArr($specialCol) == $oldCol} {
	    set newArr($specialCol) $newCol
	}
    }

    if {$newCol < $newArr(colCount)} {
	foreach l [getSublabels $newArr(hdrTxtFrLbl)$newCol] {
	    destroy $l
	}
	set newArr(fmtCmdFlagList) \
	    [lreplace $newArr(fmtCmdFlagList) $newCol $newCol 0]
    }

    #
    # Move the elements of oldArr with names of the form $oldCol-*
    # to those of newArr with names of the form $newCol-*
    #
    set w $newArr(body)
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
	[string first $oldArr(-stretch) "all"] != 0} {
	set stretchableCols {}
	foreach elem $oldArr(-stretch) {
	    if {[string first $elem "end"] != 0 && $elem == $oldCol} {
		lappend stretchableCols $newCol
	    } else {
		lappend stretchableCols $elem
	    }
	}
	set newArr(-stretch) $stretchableCols
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
    variable usingTile
    upvar ::tablelist::ns${win}::data data
    upvar $imgArrName imgArr

    set optList {-labelalign -labelbackground -labelborderwidth -labelfont
		 -labelforeground -labelpady -labelrelief}
    if {!$usingTile} {
	lappend optList -labelheight
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
    if {$len < $expLen} {
	for {set n $len} {$n < $expLen} {incr n} {
	    lappend item ""
	}
	return $item
    } else {
	return [lrange $item 0 [expr {$expLen - 1}]]
    }
}

#------------------------------------------------------------------------------
# tablelist::formatItem
#
# Returns the list obtained by formatting the elements of the item argument.
#------------------------------------------------------------------------------
proc tablelist::formatItem {win item} {
    upvar ::tablelist::ns${win}::data data

    set formattedItem {}
    set col 0
    foreach text $item fmtCmdFlag $data(fmtCmdFlagList) {
	if {$fmtCmdFlag} {
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
	if {[string compare $str ""] != 0} {
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
# tablelist::displayText
#
# Displays the given text in a message widget to be embedded into the specified
# cell of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::displayText {win key col text font alignment} {
    variable anchors
    upvar ::tablelist::ns${win}::data data

    set w $data(body).m$key,$col
    if {![winfo exists $w]} {
	#
	# Create a message widget and replace the binding tag Message with
	# $data(bodyTag) and TablelistBody in the list of its binding tags
	#
	message $w -borderwidth 0 -highlightthickness 0 -padx 0 -pady 0 \
		   -relief flat -takefocus 0 -width 1000000
	bindtags $w [lreplace [bindtags $w] 1 1 $data(bodyTag) TablelistBody]
    }

    $w configure -anchor $anchors($alignment) -font $font \
		 -justify $alignment -text $text

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
    upvar ::tablelist::ns${win}::data data

    #
    # Create a label widget and replace the binding tag Label with
    # $data(bodyTag) and TablelistBody in the list of its binding tags
    #
    set w $data(body).l$key,$col
    tk::label $w -anchor $anchor -borderwidth 0 -height 0 \
		 -highlightthickness 0 -image $data($key,$col-image) \
		 -padx 0 -pady 0 -relief flat -takefocus 0 -width $width
    bindtags $w [lreplace [bindtags $w] 1 1 $data(bodyTag) TablelistBody]

    updateColorsWhenIdle $win
    return $w
}

#------------------------------------------------------------------------------
# tablelist::getAuxData
#
# Gets the name, type, and width of the image or window associated with the
# specified cell of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::getAuxData {win key col auxTypeName auxWidthName} {
    upvar ::tablelist::ns${win}::data data
    upvar $auxTypeName auxType $auxWidthName auxWidth

    if {[info exists data($key,$col-window)]} {
	set auxType 2
	set auxWidth $data($key,$col-reqWidth)
	return $data(body).f$key,$col
    } elseif {[info exists data($key,$col-image)]} {
	set auxType 1
	set auxWidth [image width $data($key,$col-image)]
	return [list ::tablelist::displayImage $win $key $col w 0]
    } else {
	set auxType 0
	set auxWidth 0
	return ""
    }
}

#------------------------------------------------------------------------------
# tablelist::adjustElem
#
# Prepares the text specified by $textName and the auxiliary object width
# specified by $auxWidthName for insertion into a cell of the tablelist widget
# win.
#------------------------------------------------------------------------------
proc tablelist::adjustElem {win textName auxWidthName font pixels
			    snipSide snipStr} {
    upvar $textName text $auxWidthName auxWidth

    if {$pixels == 0} {				;# convention: dynamic width
	if {$auxWidth != 0 && [string compare $text ""] != 0} {
	    incr auxWidth 4
	}
    } elseif {$auxWidth == 0} {			;# no image or window
	set text [strRange $win $text $font $pixels $snipSide $snipStr]
    } elseif {[string compare $text ""] == 0} {	;# aux. object w/o text
	if {$auxWidth > $pixels} {
	    set auxWidth $pixels
	}
    } else {					;# both aux. object and text
	if {$auxWidth + 4 <= $pixels} {
	    incr auxWidth 4
	    incr pixels -$auxWidth
	    set text [strRange $win $text $font $pixels $snipSide $snipStr]
	} elseif {$auxWidth <= $pixels} {
	    set text ""				;# can't display the text
	} else {
	    set auxWidth $pixels
	    set text ""				;# can't display the text
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
proc tablelist::adjustMlElem {win listName auxWidthName font pixels
			      snipSide snipStr} {
    upvar $listName list $auxWidthName auxWidth

    set list2 {}
    if {$pixels == 0} {				;# convention: dynamic width
	if {$auxWidth != 0 && [hasChars $list]} {
	    incr auxWidth 4
	}
    } elseif {$auxWidth == 0} {			;# no image or window
	foreach str $list {
	    lappend list2 [strRange $win $str $font $pixels $snipSide $snipStr]
	}
	set list $list2
    } elseif {![hasChars $list]} {		;# aux. object w/o text
	if {$auxWidth > $pixels} {
	    set auxWidth $pixels
	}
    } else {					;# both aux. object and text
	if {$auxWidth + 4 <= $pixels} {
	    incr auxWidth 4
	    incr pixels -$auxWidth
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

#------------------------------------------------------------------------------
# tablelist::getElemWidth
#
# Returns the number of pixels that the given text together with the aux.
# object (image or window) of the specified width would use when displayed in a
# cell of a dynamic-width column of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::getElemWidth {win text auxWidth cellFont} {
    if {[string match "*\n*" $text]} {
	set list [split $text "\n"]
	if {$auxWidth != 0 && [hasChars $list]} {
	    incr auxWidth 4
	}
	return [expr {[getListWidth $win $list $cellFont] + $auxWidth}]
    } else {
	if {$auxWidth != 0 && [string compare $text ""] != 0} {
	    incr auxWidth 4
	}
	return [expr {[font measure $cellFont -displayof $win $text] +
		      $auxWidth}]
    }
}

#------------------------------------------------------------------------------
# tablelist::insertElem
#
# Inserts the given text and auxiliary object (image or window) into the text
# widget w, just before the character position specified by index.  The object
# will follow the text if alignment is "right", and will precede it otherwise.
#------------------------------------------------------------------------------
proc tablelist::insertElem {w index text aux auxType alignment} {
    set index [$w index $index]

    if {$auxType == 0} {				;# no image or window
	$w insert $index $text
    } elseif {[string compare $alignment "right"] == 0} {
	if {$auxType == 1} {					;# image
	    set aux [lreplace $aux 4 4 e]
	    $w window create $index -pady 1 -create $aux
	} else {						;# window
	    place $aux.w -relx 1.0 -anchor ne
	    $w window create $index -pady 1 -window $aux
	}
	$w insert $index $text
    } else {
	$w insert $index $text
	if {$auxType == 1} {					;# image
	    set aux [lreplace $aux 4 4 w]
	    $w window create $index -pady 1 -create $aux
	} else {						;# window
	    place $aux.w -relx 0.0 -anchor nw
	    $w window create $index -pady 1 -window $aux
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
proc tablelist::insertMlElem {w index msgScript aux auxType alignment} {
    set index [$w index $index]

    if {$auxType == 0} {				;# no image or window
	$w window create $index -pady 1 -create $msgScript
    } elseif {[string compare $alignment "right"] == 0} {
	if {$auxType == 1} {					;# image
	    set aux [lreplace $aux 4 4 e]
	    $w window create $index -pady 1 -create $aux
	} else {						;# window
	    place $aux.w -relx 1.0 -anchor ne
	    $w window create $index -pady 1 -window $aux
	}
	$w window create $index -pady 1 -create $msgScript
    } else {
	$w window create $index -pady 1 -create $msgScript
	if {$auxType == 1} {					;# image
	    set aux [lreplace $aux 4 4 w]
	    $w window create $index -pady 1 -create $aux
	} else {						;# window
	    place $aux.w -relx 0.0 -anchor nw
	    $w window create $index -pady 1 -window $aux
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
			    alignment} {
    if {$auxType == 0} {				;# no image or window
	$w delete $index1 $index2
	$w insert $index1 $text
    } else {
	#
	# Check whether the image label or the frame containing a
	# window is mapped at the first or last position of the cell
	#
	if {$auxType == 1} {					;# image
	    if {[setImgLabelWidth $w $index1 $auxWidth]} {
		set auxFound 1
		$w delete $index1+1c $index2
	    } elseif {[setImgLabelWidth $w $index2-1c $auxWidth]} {
		set auxFound 1
		$w delete $index1 $index2-1c
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
		$w delete $index1+1c $index2
	    } elseif {[string compare [lindex [$w dump -window $index2-1c] 1] \
		       $aux] == 0} {
		set auxFound 1
		$w delete $index1 $index2-1c
	    } else {
		set auxFound 0
		$w delete $index1 $index2
	    }
	}

	if {$auxFound} {
	    #
	    # Adjust the aux. window and insert the text
	    #
	    if {[string compare $alignment "right"] == 0} {
		if {$auxType == 1} {				;# image
		    setImgLabelAnchor $w $index1 e
		} else {					;# window
		    place $aux.w -relx 1.0 -anchor ne
		}
		set index $index1
	    } else {
		if {$auxType == 1} {				;# image
		    setImgLabelAnchor $w $index1 w
		} else {					;# window
		    place $aux.w -relx 0.0 -anchor nw
		}
		set index $index1+1c
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
	    insertElem $w $index1 $text $aux $auxType $alignment
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
			      alignment} {
    if {$auxType == 0} {				;# no image or window
	$w delete $index1+1c $index2
	if {[catch {$w window cget $index1 -create} script] == 0 &&
	    [string match "::tablelist::displayText*" $script]} {
	    $w window configure $index1 -pady 1 -create $msgScript

	    set path [lindex [$w dump -window $index1] 1]
	    if {[string compare $path ""] != 0 &&
		[string compare [winfo class $path] "Message"] == 0} {
		eval $msgScript
	    }
	} else {
	    $w delete $index1
	    $w window create $index1 -pady 1 -create $msgScript
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
		    place $aux.w -relx 1.0 -anchor ne
		}
		set index index2Mark-2c
	    } else {
		if {$auxType == 1} {				;# image
		    setImgLabelAnchor $w $index1 w
		} else {					;# window
		    place $aux.w -relx 0.0 -anchor nw
		}
		set index $index1+1c
	    }

	    if {[catch {$w window cget $index -create} script] == 0 &&
		[string match "::tablelist::displayText*" $script]} {
		$w window configure $index -pady 1 -create $msgScript

		set path [lindex [$w dump -window $index] 1]
		if {[string compare $path ""] != 0 &&
		    [string compare [winfo class $path] "Message"] == 0} {
		    eval $msgScript
		}
	    } elseif {[string compare $alignment "right"] == 0} {
		$w window create index2Mark-1c -pady 1 -create $msgScript
		$w delete $index1 index2Mark-2c
	    } else {
		$w window create $index1+1c -pady 1 -create $msgScript
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
	    insertMlElem $w $index1 $msgScript $aux $auxType $alignment
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
	    set script [lreplace $script end end $width]
	    $w window configure $index -pady 1 -create $script

	    set path [lindex [$w dump -window $index] 1]
	    if {[string compare $path ""] != 0} {
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
	set script [lreplace $script 4 4 $anchor]
	$w window configure $index -pady 1 -create $script

	set path [lindex [$w dump -window $index] 1]
	if {[string compare $path ""] != 0} {
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
				   snipStr cellTags line} {
    variable snipSides
    upvar ::tablelist::ns${win}::data data

    #
    # Adjust the cell text and the image or window width
    #
    if {[string match "*\n*" $text]} {
	set multiline 1
	set list [split $text "\n"]
    } else {
	set multiline 0
    }
    set aux [getAuxData $win $key $col auxType auxWidth]
    set cellFont [getCellFont $win $key $col]
    if {$pixels == 0} {		;# convention: dynamic width
	if {$data($col-maxPixels) > 0} {
	    if {$data($col-reqPixels) > $data($col-maxPixels)} {
		set pixels $data($col-maxPixels)
	    }
	}
    }
    if {$pixels != 0} {
	incr pixels $data($col-delta)
    }
    set snipSide $snipSides($alignment,$data($col-changesnipside))
    if {$multiline} {
	adjustMlElem $win list auxWidth $cellFont $pixels $snipSide $snipStr
	set msgScript [list ::tablelist::displayText $win $key $col \
		       [join $list "\n"] $cellFont $alignment]
    } else {
	adjustElem $win text auxWidth $cellFont $pixels $snipSide $snipStr
    }

    #
    # Insert the text and the auxiliary object (if any) just before the newline
    #
    set w $data(body)
    if {$auxType == 0} {				;# no image or window
	if {$multiline} {
	    $w insert $line.end "\t\t" $cellTags
	    $w window create $line.end-1c -pady 1 -create $msgScript
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
	    uplevel #0 $data($key,$col-window) [list $win $row $col $aux.w]
	}
	if {$multiline} {
	    insertMlElem $w $line.end-1c $msgScript $aux $auxType $alignment
	} else {
	    insertElem $w $line.end-1c $text $aux $auxType $alignment
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::makeColFontAndTagLists
#
# Builds the lists data(colFontList) of the column fonts and data(colTagsList)
# of the column tag names for the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::makeColFontAndTagLists win {
    variable canElide
    upvar ::tablelist::ns${win}::data data

    set widgetFont $data(-font)
    set data(colFontList) {}
    set data(colTagsList) {}
    set data(hasColTags) 0
    set viewable [winfo viewable $win]

    for {set col 0} {$col < $data(colCount)} {incr col} {
	set tagNames {}

	if {[info exists data($col-font)]} {
	    lappend data(colFontList) $data($col-font)
	    lappend tagNames col-font-$data($col-font)
	    set data(hasColTags) 1
	} else {
	    lappend data(colFontList) $widgetFont
	}

	foreach opt {-background -foreground} {
	    if {[info exists data($col$opt)]} {
		lappend tagNames col$opt-$data($col$opt)
		set data(hasColTags) 1
	    }
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
	    if {[catch {format "%d" $next}] == 0} {	;# integer check
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
	foreach w [winfo children $data(hdrTxtFr)] {
	    destroy $w
	}
	foreach w [winfo children $win] {
	    if {[regexp {^sep[0-9]+$} [winfo name $w]]} {
		destroy $w
	    }
	}
	set data(fmtCmdFlagList) {}
    }

    #
    # Build the list data(colList), and create
    # the labels and canvases if requested
    #
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
				sortOrder ""  sortRank 0  changesnipside 0
				editable 0  editwindow entry  hide 0
				maxwidth 0  resizable 1  showarrow 1
				showlinenumbers 0  sortmode ascii} {
		if {![info exists data($col-$name)]} {
		    set data($col-$name) $val
		}
	    }
	    lappend data(fmtCmdFlagList) [info exists data($col-formatcommand)]

	    #
	    # Create the label
	    #
	    set w $data(hdrTxtFrLbl)$col
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
	    # Replace the binding tag (T)Label with TablelistLabel
	    # in the list of binding tags of the label
	    #
	    bindtags $w [lreplace [bindtags $w] 1 1 TablelistLabel]

	    #
	    # Create a canvas containing the sort arrows
	    #
	    set w $data(hdrTxtFrCanv)$col
	    canvas $w -borderwidth 0 -highlightthickness 0 \
		      -relief flat -takefocus 0
	    regexp {^(flat|sunken)([0-9]+)x([0-9]+)$} $data(-arrowstyle) \
		   dummy relief width height
	    createArrows $w $width $height $relief

	    #
	    # Apply to it the current configuration options
	    #
	    foreach opt $configOpts {
		if {[string compare [lindex $configSpecs($opt) 2] "c"] == 0} {
		    $w configure $opt $data($opt)
		}
	    }
	    
	    #
	    # Replace the binding tag Canvas with TablelistArrow
	    # in the list of binding tags of the canvas
	    #
	    bindtags $w [lreplace [bindtags $w] 1 1 TablelistArrow]

	    if {[info exists data($col-labelimage)]} {
		doColConfig $col $win -labelimage $data($col-labelimage)
	    }
	}

	#
	# Configure the edit window if present
	#
	if {$col == $data(editCol) &&
	    [string compare [winfo class $data(bodyFrEd)] "Mentry"] != 0} {
	    catch {$data(bodyFrEd) configure -justify $alignment}
	}

	incr col
    }

    #
    # Clean up the data associated with the deleted columns
    #
    for {set col $data(colCount)} {$col < $oldColCount} {incr col} {
	deleteColData $win $col
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
    variable usingTile
    upvar ::tablelist::ns${win}::data data

    set sepX [getSepX]
    for {set col 0} {$col < $data(colCount)} {incr col} {
	#
	# Create the col'th separator and attach it to
	# the right edge of the col'th header label
	#
	set w $data(sep)$col
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
	place $w -in $data(hdrTxtFrLbl)$col -anchor ne -bordermode outside \
		 -relx 1.0 -x $sepX

	#
	# Replace the binding tag TSeparator or Frame with $data(bodyTag)
	# and TablelistBody in the list of binding tags of the separator
	#
	bindtags $w [lreplace [bindtags $w] 1 1 $data(bodyTag) TablelistBody]
    }
    
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
# Adjusts the height and vertical position of each separator in the tablelist
# widget win.
#------------------------------------------------------------------------------
proc tablelist::adjustSeps win {
    variable usingTile
    upvar ::tablelist::ns${win}::data data

    if {[info exists data(sepsId)]} {
	after cancel $data(sepsId)
	unset data(sepsId)
    }

    #
    # Get the height to be applied to the separators
    #
    set w $data(body)
    set textIdx [$w index @0,[expr {[winfo height $w] - 1}]]
    set dlineinfo [$w dlineinfo $textIdx]
    if {$data(itemCount) == 0 || [string compare $dlineinfo ""] == 0} {
	set sepHeight 1
    } else {
	foreach {x y width height baselinePos} $dlineinfo {}
	set sepHeight [expr {$y + $height}]
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
    set w $data(sep)
    if {$col < 0} {
	if {[winfo exists $w]} {
	    place forget $w
	}
    } else {
	place $w -in $data(hdrTxtFrLbl)$col -anchor ne -bordermode outside \
		 -height [expr {$sepHeight + [winfo height $data(hdr)] - 1}] \
		 -relx 1.0 -x [getSepX] -y 1
	raise $w
    }

    #
    # Set the height and vertical position of each separator
    #
    if {!$usingTile && $data(-showlabels)} {
	incr sepHeight
    }
    foreach w [winfo children $win] {
	if {[regexp {^sep[0-9]+$} [winfo name $w]]} {
	    if {$data(-showlabels)} {
		if {$usingTile} {
		    place configure $w -height $sepHeight -rely 1.0 -y 0
		} else {
		    place configure $w -height $sepHeight -rely 1.0 -y -1
		}
	    } else {
		if {$usingTile} {
		    place configure $w -height $sepHeight -rely 0.0 -y 1
		} else {
		    place configure $w -height $sepHeight -rely 0.0 -y 0
		}
	    }
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
    variable usingTile

    set x 1
    if {$usingTile} {
	set currentTheme [getCurrentTheme]
	variable xpStyle
	if {[string compare $currentTheme "xpnative"] == 0 && $xpStyle} {
	    set x 0
	} elseif {[string compare $currentTheme "tileqt"] == 0 &&
		  [string compare [string tolower [tileqt_currentThemeName]] \
		   "qtcurve"] == 0} {
	    set x 2
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
    variable canElide
    upvar ::tablelist::ns${win}::data data

    set compAllColWidths [expr {[string compare $whichWidths "allCols"] == 0}]
    set compAllLabelWidths \
	[expr {[string compare $whichWidths "allLabels"] == 0}]

    #
    # Configure the labels and compute the positions of
    # the tab stops to be set in the body text widget
    #
    set data(hdrPixels) 0
    set tabs {}
    set col 0
    set x 0
    foreach {pixels alignment} $data(colList) {
	set w $data(hdrTxtFrLbl)$col
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
	    if {$compAllColWidths} {
		computeColWidth $win $col
	    } elseif {$compAllLabelWidths} {
		computeLabelWidth $win $col
	    } elseif {[lsearch -exact $whichWidths $col] >= 0} {
		computeColWidth $win $col
	    } elseif {[lsearch -exact $whichWidths l$col] >= 0} {
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
	    ![string match "*Checkbutton" [winfo class $data(bodyFrEd)]]} {
	    adjustEditWindow $win $pixels
	}

	set canvas $data(hdrTxtFrCanv)$col
	if {[lsearch -exact $data(arrowColList) $col] >= 0 &&
	    !$data($col-elide) && !$data($col-hide)} {
	    #
	    # Place the canvas to the left side of the label if the
	    # latter is right-justified and to its right side otherwise
	    #
	    if {[string compare $labelAlignment "right"] == 0} {
		place $canvas -in $w -anchor w -bordermode outside \
			      -relx 0.0 -x $data(charWidth) -rely 0.499 -y -1
	    } else {
		place $canvas -in $w -anchor e -bordermode outside \
			      -relx 1.0 -x -$data(charWidth) -rely 0.499 -y -1
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
	    set labelPixels [expr {$pixels + 2*$data(charWidth)}]
	    place $w -x $x -relheight 1.0 -width $labelPixels
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
    place $data(hdrLbl) -x $x

    #
    # Apply the value of tabs to the body text widget
    #
    $data(body) configure -tabs $tabs

    #
    # Adjust the width and height of the frames data(hdrTxtFr) and data(hdr)
    #
    set data(hdrPixels) $x
    $data(hdrTxtFr) configure -width $data(hdrPixels)
    if {$data(-width) <= 0} {
	if {$stretchCols} {
	    $data(hdr) configure -width $data(hdrPixels)
	    $data(lb) configure -width \
		      [expr {$data(hdrPixels) / $data(charWidth)}]
	}
    } else {
	$data(hdr) configure -width 0
    }
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
    variable anchors
    variable usingTile
    upvar ::tablelist::ns${win}::data data

    #
    # Apply some configuration options to the label and its sublabels (if any)
    #
    set w $data(hdrTxtFrLbl)$col
    set anchor $anchors($alignment)
    set borderWidth [winfo pixels $w [$w cget -borderwidth]]
    if {$borderWidth < 0} {
	set borderWidth 0
    }
    set padX [expr {$data(charWidth) - $borderWidth}]
    configLabel $w -anchor $anchor -justify $alignment -padx $padX
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
    if {[lsearch -exact $data(arrowColList) $col] >= 0} {
	set spaceWidth [font measure $labelFont -displayof $w " "]
	set canvas $data(hdrTxtFrCanv)$col
	set canvasWidth $data(arrowWidth)
	if {[llength $data(arrowColList)] > 1} {
	    incr canvasWidth 6
	    $canvas itemconfigure sortRank \
		    -image sortRank$data($col-sortRank)$win
	}
	$canvas configure -width $canvasWidth
	set spaces "  "
	set n 2
	while {$n*$spaceWidth < $canvasWidth + $data(charWidth)} {
	    append spaces " "
	    incr n
	}
	set spacePixels [expr {$n * $spaceWidth}]
    } else {
	set spaces ""
	set spacePixels 0
    }

    if {$pixels == 0} {				;# convention: dynamic width
	#
	# Set the label text
	#
	if {$imageWidth == 0} {				;# no image
	    if {[string compare $title ""] == 0} {
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
	} elseif {[string compare $title ""] == 0} {	;# image w/o text
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
	set snipSide $snipSides($alignment,0)
	if {$imageWidth == 0} {				;# no image
	    if {[string compare $title ""] == 0} {
		set text $spaces
	    } else {
		set lines {}
		foreach line [split $title "\n"] {
		    set line [strRange $win $line $labelFont \
			      $lessPixels $snipSide $data(-snipstring)]
		    if {[string compare $alignment "right"] == 0} {
			lappend lines $spaces$line
		    } else {
			lappend lines $line$spaces
		    }
		}
		set text [join $lines "\n"]
	    }
	    $w configure -text $text
	} elseif {[string compare $title ""] == 0} {	;# image w/o text
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
		    set line [strRange $win $line $labelFont \
			      $lessPixels $snipSide $data(-snipstring)]
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
		set text $spaces		;# can't display the orig. text
		$w-tl configure -text $text
		$w-il configure -width $imageWidth
	    } elseif {$spacePixels < $pixels} {
		set text $spaces		;# can't display the orig. text
		$w-tl configure -text $text
		$w-il configure -width [expr {$pixels - $spacePixels}]
	    } else {
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
	if {[string compare $text ""] == 0} {
	    place forget $w-tl
	}

	set margin $data(charWidth)
	switch $alignment {
	    left {
		place $w-il -in $w -anchor w -bordermode outside \
			    -relx 0.0 -x $margin -rely 0.499
		if {[string compare $text ""] != 0} {
		    if {$usingTile} {
			set padding [$w cget -padding]
			lset padding 0 [expr {$padX + [winfo reqwidth $w-il]}]
			$w configure -padding $padding -text $text
		    } else {
			set textX [expr {$margin + [winfo reqwidth $w-il]}]
			place $w-tl -in $w -anchor w -bordermode outside \
				    -relx 0.0 -x $textX -rely 0.499
		    }
		}
	    }

	    right {
		place $w-il -in $w -anchor e -bordermode outside \
			    -relx 1.0 -x -$margin -rely 0.499
		if {[string compare $text ""] != 0} {
		    if {$usingTile} {
			set padding [$w cget -padding]
			lset padding 2 [expr {$padX + [winfo reqwidth $w-il]}]
			$w configure -padding $padding -text $text
		    } else {
			set textX [expr {-$margin - [winfo reqwidth $w-il]}]
			place $w-tl -in $w -anchor e -bordermode outside \
				    -relx 1.0 -x $textX -rely 0.499
		    }
		}
	    }

	    center {
		if {[string compare $text ""] == 0} {
		    place $w-il -in $w -anchor center -relx 0.5 -x 0 -rely 0.499
		} else {
		    set reqWidth [expr {[winfo reqwidth $w-il] +
					[winfo reqwidth $w-tl]}]
		    set iX [expr {-$reqWidth/2}]
		    place $w-il -in $w -anchor w -relx 0.5 -x $iX -rely 0.499
		    if {$usingTile} {
			set padding [$w cget -padding]
			lset padding 0 [expr {$padX + [winfo reqwidth $w-il]}]
			$w configure -padding $padding -text $text
		    } else {
			set tX [expr {$reqWidth + $iX}]
			place $w-tl -in $w -anchor e -relx 0.5 -x $tX \
				    -rely 0.499
		    }
		}
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

    set fmtCmdFlag [info exists data($col-formatcommand)]

    set data($col-elemWidth) 0
    set data($col-widestCount) 0

    #
    # Column elements
    #
    foreach item $data(itemList) {
	if {$col >= [llength $item] - 1} {
	    continue
	}

	set key [lindex $item end]
	if {[info exists data($key-hide)]} {
	    continue
	}

	set text [lindex $item $col]
	if {$fmtCmdFlag} {
	    set text [uplevel #0 $data($col-formatcommand) [list $text]]
	}
	set text [strToDispStr $text]
	getAuxData $win $key $col auxType auxWidth
	set cellFont [getCellFont $win $key $col]
	set elemWidth [getElemWidth $win $text $auxWidth $cellFont]
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

    set w $data(hdrTxtFrLbl)$col
    if {[info exists data($col-labelimage)]} {
	set netLabelWidth \
	    [expr {[winfo reqwidth $w-il] + [winfo reqwidth $w-tl]}]
    } else {							;# no image
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
    upvar ::tablelist::ns${win}::data data

    #
    # Compute the max. label height
    #
    set maxLabelHeight [winfo reqheight $data(hdrLbl)]
    for {set col 0} {$col < $data(colCount)} {incr col} {
	set w $data(hdrTxtFrLbl)$col
	if {[string compare [winfo manager $w] ""] == 0} {
	    continue
	}

	set reqHeight [winfo reqheight $w]
	if {$reqHeight > $maxLabelHeight} {
	    set maxLabelHeight $reqHeight
	}

	foreach l [getSublabels $w] {
	    if {[string compare [winfo manager $l] ""] == 0} {
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
    # Set the height of the header frame, update
    # the colors, and adjust the separators
    #
    $data(hdrTxtFr) configure -height $maxLabelHeight
    if {$data(-showlabels)} {
	$data(hdr) configure -height $maxLabelHeight
    } else {
	$data(hdr) configure -height 1
    }
    updateColorsWhenIdle $win
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
    if {[string first $data(-stretch) "all"] == 0} {
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
    # Adjust the columns
    #
    adjustColumns $win {} 0
}

#------------------------------------------------------------------------------
# tablelist::updateColorsWhenIdle
#
# Arranges for the background and foreground colors of the label, frame, and
# message widgets containing the currently visible images and multiline
# elements of the tablelist widget win to be updated at idle time.
#------------------------------------------------------------------------------
proc tablelist::updateColorsWhenIdle win {
    upvar ::tablelist::ns${win}::data data

    if {[info exists data(colorId)]} {
	return ""
    }

    set data(colorId) [after idle [list tablelist::updateColors $win]]
}

#------------------------------------------------------------------------------
# tablelist::updateColors
#
# Updates the background and foreground colors of the label, frame, and message
# widgets containing the currently visible images, embedded windows, and
# multiline elements of the tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::updateColors win {
    upvar ::tablelist::ns${win}::data data

    if {[info exists data(colorId)]} {
	after cancel $data(colorId)
	unset data(colorId)
    }

    set w $data(body)
    set topLeftIdx "[$w index @0,0] linestart"
    set btmRightIdx "[$w index @0,[expr {[winfo height $w] - 1}]] lineend"
    foreach {dummy path textIdx} [$w dump -window $topLeftIdx $btmRightIdx] {
	if {[string compare $path ""] == 0} {
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
	foreach {key col} [split [string range $name 1 end] ","] {}
	set tagNames [$w tag names $textIdx]

	#
	# Set the widget's background and foreground
	# colors to those of the containing cell
	#
	if {$data(isDisabled)} {
	    set bg $data(-background)
	    set fg $data(-disabledforeground)
	} elseif {[lsearch -exact $tagNames select] < 0} {	;# not selected
	    if {[info exists data($key,$col-background)]} {
		set bg $data($key,$col-background)
	    } elseif {[info exists data($key-background)]} {
		set bg $data($key-background)
	    } elseif {[lsearch -exact $tagNames stripe] < 0 ||
		      [string compare $data(-stripebackground) ""] == 0} {
		if {[info exists data($col-background)]} {
		    set bg $data($col-background)
		} else {
		    set bg $data(-background)
		}
	    } else {
		set bg $data(-stripebackground)
	    }

	    if {$isMessage} {
		if {[info exists data($key,$col-foreground)]} {
		    set fg $data($key,$col-foreground)
		} elseif {[info exists data($key-foreground)]} {
		    set fg $data($key-foreground)
		} elseif {[lsearch -exact $tagNames stripe] < 0 ||
			  [string compare $data(-stripeforeground) ""] == 0} {
		    if {[info exists data($col-foreground)]} {
			set fg $data($col-foreground)
		    } else {
			set fg $data(-foreground)
		    }
		} else {
		    set fg $data(-stripeforeground)
		}
	    }
	} else {						;# selected
	    if {[info exists data($key,$col-selectbackground)]} {
		set bg $data($key,$col-selectbackground)
	    } elseif {[info exists data($key-selectbackground)]} {
		set bg $data($key-selectbackground)
	    } elseif {[info exists data($col-selectbackground)]} {
		set bg $data($col-selectbackground)
	    } else {
		set bg $data(-selectbackground)
	    }

	    if {$isMessage} {
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
	}
	if {[string compare [$path cget -background] $bg] != 0} {
	    $path configure -background $bg
	}
	if {$isMessage && [string compare [$path cget -foreground] $fg] != 0} {
	    $path configure -foreground $fg
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
	adjustElidedTextWhenIdle $win
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
	[string compare $data(-xscrollcommand) ""] != 0} {
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

    if {[string compare $data(-yscrollcommand) ""] != 0} {
	eval $data(-yscrollcommand) [yviewSubCmd $win {}]
    }

    if {[winfo exists $data(bodyFr)]} {
	raise $data(bodyFr)
    }

    if {[winfo viewable $win]} {
	update idletasks
    }

    if {$data(winCount) != 0 || $::tk_version > 8.4} {
	return ""
    }

    #
    # Destroy those label widgets containing embedded images
    # and those message widgets containing multiline elements
    # that are outside the currently visible range of text lines
    #
    set w $data(body)
    foreach path [$w window names] {
	set class [winfo class $path]
	if {[string compare $class "Label"] == 0 ||
	    [string compare $class "Message"] == 0} {
	    set widgets($path) 1
	}
    }
    set topLeftIdx "[$w index @0,0] linestart"
    set btmRightIdx "[$w index @0,[expr {[winfo height $w] - 1}]] lineend"
    foreach {dummy path textIdx} [$w dump -window $topLeftIdx $btmRightIdx] {
	set widgets($path) 0
    }
    foreach path [array names widgets] {
	if {$widgets($path)} {
	    destroy $path
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::adjustElidedTextWhenIdle
#
# Arranges for the elided text ranges of the body text child of the tablelist
# widget win to be updated at idle time.
#------------------------------------------------------------------------------
proc tablelist::adjustElidedTextWhenIdle win {
    upvar ::tablelist::ns${win}::data data

    if {[info exists data(elidedId)]} {
	return ""
    }

    set data(elidedId) [after idle [list tablelist::adjustElidedText $win]]
}

#------------------------------------------------------------------------------
# tablelist::adjustElidedText
#
# Updates the elided text ranges of the body text child of the tablelist widget
# win.
#------------------------------------------------------------------------------
proc tablelist::adjustElidedText win {
    upvar ::tablelist::ns${win}::data data

    if {[info exists data(elidedId)]} {
	after cancel $data(elidedId)
	unset data(elidedId)
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
    if {$canElide && $data(hiddenColCount) > 0 && $data(itemCount) > 0} {
	set btmY [expr {[winfo height $w] - 1}]
	set topLine [expr {int([$w index @0,0])}]
	set btmLine [expr {int([$w index @0,$btmY])}]
	for {set line $topLine; set row [expr {$line - 1}]} \
	    {$line <= $btmLine} {set row $line; incr line} {
	    set key [lindex [lindex $data(itemList) $row] end]
	    if {[info exists data($key-hide)]} {
		continue
	    }

	    set textIdx1 $line.0
	    for {set col 0; set count 0} \
		{$col < $data(colCount) && $count < $data(hiddenColCount)} \
		{incr col} {
		set textIdx2 \
		    [$w search -elide "\t" $textIdx1+1c $line.end]+1c
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
	    set btmLine [expr {int([$w index @0,$btmY])}]
	}

	if {[lindex [$w yview] 1] == 1} {
	    for {set line $btmLine; set row [expr {$line - 1}]} \
		{$line >= $topLine} {set line $row; incr row -1} {
		set key [lindex [lindex $data(itemList) $row] end]
		if {[info exists data($key-hide)]} {
		    continue
		}

		set textIdx1 $line.0
		for {set col 0; set count 0} \
		    {$col < $data(colCount) && $count < $data(hiddenColCount)} \
		    {incr col} {
		    set textIdx2 \
			[$w search -elide "\t" $textIdx1+1c $line.end]+1c
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
	set btmY [expr {[winfo height $w] - 1}]
	set topLine [expr {int([$w index @0,0])}]
	set btmLine [expr {int([$w index @0,$btmY])}]
	for {set line $topLine; set row [expr {$line - 1}]} \
	    {$line <= $btmLine} {set row $line; incr line} {
	    set key [lindex [lindex $data(itemList) $row] end]
	    if {![info exists data($key-hide)]} {
		findTabs $win $line $firstCol $lastCol tabIdx1 tabIdx2
		$w tag add elidedCol $tabIdx1 $tabIdx2+1c
	    }

	    #
	    # Update btmLine because it may
	    # change due to the "elidedCol" tag
	    #
	    set btmLine [expr {int([$w index @0,$btmY])}]
	}

	if {[lindex [$w yview] 1] == 1} {
	    for {set line $btmLine; set row [expr {$line - 1}]} \
		{$line >= $topLine} {set line $row; incr row -1} {
		set key [lindex [lindex $data(itemList) $row] end]
		if {![info exists data($key-hide)]} {
		    findTabs $win $line $firstCol $lastCol tabIdx1 tabIdx2
		    $w tag add elidedCol $tabIdx1 $tabIdx2+1c
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
    variable canElide
    variable snipSides
    upvar ::tablelist::ns${win}::data data

    if {[info exists data(redispId)]} {
	after cancel $data(redispId)
	unset data(redispId)
    }

    #
    # Save the indices of the selected cells
    #
    if {$getSelCells} {
	set selCells [curcellselectionSubCmd $win]
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
    set tagRefCount $data(tagRefCount)
    set isSimple [expr {$data(imgCount) == 0 && $data(winCount) == 0}]
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
		    set text [uplevel #0 $data($col-formatcommand) [list $text]]
		}

		#
		# Build the list of tags to be applied to the cell
		#
		set cellFont $colFont
		set cellTags $colTags
		if {$tagRefCount != 0} {
		    set cellFont [getCellFont $win $key $col]
		    foreach opt {-background -foreground -font} {
			if {[info exists data($key,$col$opt)]} {
			    lappend cellTags cell$opt-$data($key,$col$opt)
			}
		    }
		}

		#
		# Clip the element if necessary
		#
		set text [strToDispStr $text]
		if {[string match "*\n*" $text]} {
		    set multiline 1
		    set list [split $text "\n"]
		} else {
		    set multiline 0
		}
		if {$pixels == 0} {		;# convention: dynamic width
		    if {$data($col-maxPixels) > 0} {
			if {$data($col-reqPixels) > $data($col-maxPixels)} {
			    set pixels $data($col-maxPixels)
			}
		    }
		}
		if {$pixels != 0} {
		    incr pixels $data($col-delta)
		    set snipSide \
			$snipSides($alignment,$data($col-changesnipside))
		    if {$multiline} {
			set text [joinList $win $list $cellFont \
				  $pixels $snipSide $snipStr]
		    } else {
			set text [strRange $win $text $cellFont \
				  $pixels $snipSide $snipStr]
		    }
		}

		if {$multiline} {
		    lappend insertArgs "\t\t" $cellTags
		    lappend multilineData $col $text $cellFont $alignment
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
	    foreach {col text font alignment} $multilineData {
		findTabs $win $line $col $col tabIdx1 tabIdx2
		set msgScript [list ::tablelist::displayText $win $key \
			       $col $text $font $alignment]
		$w window create $tabIdx2 -pady 1 -create $msgScript
	    }

	} else {
	    foreach fmtCmdFlag $data(fmtCmdFlagList) \
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
		    set text [uplevel #0 $data($col-formatcommand) [list $text]]
		}

		#
		# Build the list of tags to be applied to the cell
		#
		set cellTags $colTags
		if {$tagRefCount != 0} {
		    foreach opt {-background -foreground -font} {
			if {[info exists data($key,$col$opt)]} {
			    lappend cellTags cell$opt-$data($key,$col$opt)
			}
		    }
		}

		#
		# Insert the text and the label or window
		# (if any) into the body text widget
		#
		appendComplexElem $win $key $row $col $text $pixels \
				  $alignment $snipStr $cellTags $line

		incr col
	    }
	}

	if {$tagRefCount != 0} {
	    foreach opt {-background -foreground -font} {
		if {[info exists data($key$opt)]} {
		    $w tag add row$opt-$data($key$opt) $line.0 $line.end
		}
	    }
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
	    cellselectionSubCmd $win set $row $col $row $col
	}
    }

    #
    # Adjust the elided text and restore the stripes in the body text widget
    #
    adjustElidedText $win
    makeStripes $win

    #
    # Restore the edit window if it was present before
    #
    if {$editCol >= 0} {
	editcellSubCmd $win $editRow $editCol 1
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
	[after idle [list tablelist::redisplayCol $win $col 0 end]]
}

#------------------------------------------------------------------------------
# tablelist::redisplayCol
#
# Redisplays the elements of the col'th column of the tablelist widget win, in
# the range specified by first and last.
#------------------------------------------------------------------------------
proc tablelist::redisplayCol {win col first last} {
    variable snipSides
    upvar ::tablelist::ns${win}::data data

    if {$first == 0 && [string first $last "end"] == 0 &&
	[info exists data($col-redispId)]} {
	after cancel $data($col-redispId)
	unset data($col-redispId)
    }

    if {$data(itemCount) == 0 || $data($col-hide) || $first < 0} {
	return ""
    }
    if {[string first $last "end"] == 0} {
	set last $data(lastRow)
    }

    set snipStr $data(-snipstring)
    set fmtCmdFlag [info exists data($col-formatcommand)]

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
    set snipSide $snipSides($alignment,$data($col-changesnipside))

    for {set row $first; set line [expr {$first + 1}]} {$row <= $last} \
	{set row $line; incr line} {
	if {$row == $data(editRow) && $col == $data(editCol)} {
	    continue
	}

	#
	# Adjust the cell text and the image or window width
	#
	set item [lindex $data(itemList) $row]
	set text [lindex $item $col]
	if {$fmtCmdFlag} {
	    set text [uplevel #0 $data($col-formatcommand) [list $text]]
	}
	set text [strToDispStr $text]
	if {[string match "*\n*" $text]} {
	    set multiline 1
	    set list [split $text "\n"]
	} else {
	    set multiline 0
	}
	set key [lindex $item end]
	set aux [getAuxData $win $key $col auxType auxWidth]
	set cellFont [getCellFont $win $key $col]
	if {$multiline} {
	    adjustMlElem $win list auxWidth $cellFont \
			 $pixels $snipSide $snipStr
	    set msgScript [list ::tablelist::displayText $win $key \
			   $col [join $list "\n"] $cellFont $alignment]
	} else {
	    adjustElem $win text auxWidth $cellFont $pixels $snipSide $snipStr
	}

	#
	# Update the text widget's contents between the two tabs
	#
	findTabs $win $line $col $col tabIdx1 tabIdx2
	if {$multiline} {
	    updateMlCell $w $tabIdx1+1c $tabIdx2 $msgScript \
			 $aux $auxType $auxWidth $alignment
	} else {
	    updateCell $w $tabIdx1+1c $tabIdx2 $text \
		       $aux $auxType $auxWidth $alignment
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

    set w $data(body)
    $w tag remove stripe 1.0 end
    if {[string compare $data(-stripebackground) ""] != 0 ||
	[string compare $data(-stripeforeground) ""] != 0} {
	set count 0
	set inStripe 0
	for {set row 0; set line 1} {$row < $data(itemCount)} \
	    {set row $line; incr line} {
	    set key [lindex [lindex $data(itemList) $row] end]
	    if {![info exists data($key-hide)]} {
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

    if {[info exists data(lineNumsId)]} {
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
    # Update the list variable if present
    #
    condUpdateListVar $win

    #
    # Adjust the columns
    #
    adjustColumns $win $colIdxList 1
    return ""
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
    upvar ::tablelist::ns${win}::data data

    #
    # Nothing to do if the list variable was not written
    #
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
	insertSubCmd $win $data(itemCount) [lrange $var $data(itemCount) end] 0
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
    upvar $winName win $colName col
    return [regexp {^(.+)\.hdr\.t\.f\.l([0-9]+)$} $w dummy win col]
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
		    set state [expr {$val ? "active" : "!active"}]
		    $w state $state
		    if {$val} {
			variable themeDefaults
			set bg $themeDefaults(-labelactiveBg)
		    } else {
			set bg [$w cget -background]
		    }
		    foreach l [getSublabels $w] {
			$l configure -background $bg
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
	    -disabledforeground {
		$w configure $opt $val
		foreach l [getSublabels $w] {
		    $l configure $opt $val
		}
	    }

	    -background -
	    -foreground -
	    -font {
		if {[string compare $val ""] == 0 &&
		    [string compare [winfo class $w] "TLabel"] == 0} {
		    variable themeDefaults
		    set val $themeDefaults(-label[string range $opt 1 end])
		}
		$w configure $opt $val
		foreach l [getSublabels $w] {
		    $l configure $opt $val
		}
	    }

	    -padx {
		if {[string compare [winfo class $w] "TLabel"] == 0} {
		    set padding [$w cget -padding]
		    $w configure -padding \
			[list $val [lindex $padding 1] $val [lindex $padding 3]]
		} else {
		    $w configure $opt $val
		}
	    }

	    -pady {
		if {[string compare [winfo class $w] "TLabel"] == 0} {
		    set val [winfo pixels $w $val]
		    set padding [$w cget -padding]
		    $w configure -padding \
			[list [lindex $padding 0] $val [lindex $padding 2] $val]
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
			set bg $themeDefaults(-labelpressedBg)
		    } else {
			set bg $themeDefaults(-labelactiveBg)
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
		    if {[string compare $val "disabled"] == 0} {
			variable themeDefaults
			set bg $themeDefaults(-labeldisabledBg)
		    } else {
			set bg [$w cget -background]
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
	set y 1
    } else {
	set wHeight $height
	set y 0
    }

    $w configure -width $width -height $wHeight

    #
    # Delete any existing arrow image items from
    # the canvas and the corresponding images
    #
    foreach shape {triangleUp darkLineUp lightLineUp
		   triangleDn darkLineDn lightLineDn} {
	$w delete $shape
	catch {image delete $shape$w}
    }

    #
    # Create the arrow images and canvas image items
    # corresponding to the procedure's arguments
    #
    $relief${width}x${height}Arrows $w
    foreach shape {triangleUp darkLineUp lightLineUp
		   triangleDn darkLineDn lightLineDn} {
	catch {$w create image 0 $y -anchor nw -image $shape$w -tags $shape}
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

    set w $data(hdrTxtFrLbl)$col
    set labelBg [$w cget -background]
    set labelFg [$w cget -foreground]

    if {[string compare [winfo class $w] "TLabel"] == 0} {
	variable themeDefaults
	foreach state {disabled active pressed} {
	    $w instate $state {
		set labelBg $themeDefaults(-label${state}Bg)
		set labelFg $themeDefaults(-label${state}Fg)
	    }
	}
    } else {
	catch {
	    set state [$w cget -state]
	    variable winSys
	    if {[string compare $state "disabled"] == 0} {
		set labelFg [$w cget -disabledforeground]
	    } elseif {[string compare $state "active"] == 0 &&
		      [string compare $winSys "classic"] != 0 &&
		      [string compare $winSys "aqua"] != 0} {
		set labelBg [$w cget -activebackground]
		set labelFg [$w cget -activeforeground]
	    }
	}
    }

    set w $data(hdrTxtFrCanv)$col
    $w configure -background $labelBg
    sortRank$data($col-sortRank)$win configure -foreground $labelFg

    if {$data(isDisabled)} {
	fillArrows $w $data(-arrowdisabledcolor)
    } else {
	fillArrows $w $data(-arrowcolor)
    }
}

#------------------------------------------------------------------------------
# tablelist::fillArrows
#
# Fills the two arrows contained in the canvas w with the given color, or with
# the background color of the canvas if color is an empty string.  Also fills
# the arrow's borders with the corresponding 3-D shadow colors.
#------------------------------------------------------------------------------
proc tablelist::fillArrows {w color} {
    set bgColor [$w cget -background]
    if {[string compare $color ""] == 0} {
	set color $bgColor
    }

    getShadows $w $color darkColor lightColor

    foreach dir {Up Dn} {
	triangle$dir$w configure -foreground $color -background $bgColor
	catch {
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
    variable directions
    upvar ::tablelist::ns${win}::data data

    set w $data(hdrTxtFrCanv)$col
    set dir $directions($data(-incrarrowtype),$data($col-sortOrder))

    $w raise triangle$dir
    $w raise darkLine$dir
    $w raise lightLine$dir
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
	    incr scrlContentWidth [columnwidthSubCmd $win $col -total]
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
	    incr scrlWindowWidth -[columnwidthSubCmd $win $col -total]
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
    upvar ::tablelist::ns${win}::data data

    #
    # Get the number of non-hidden scrollable columns
    #
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
    upvar ::tablelist::ns${win}::data data

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
    if {$scrlColOffset != $data(scrlColOffset)} {
	set data(scrlColOffset) $scrlColOffset
	adjustElidedText $win
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

	incr scrlContentWidth [columnwidthSubCmd $win $col -total]
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
	    incr scrlXOffset [columnwidthSubCmd $win $col -total]
	}
    }

    return $scrlXOffset
}

#------------------------------------------------------------------------------
# tablelist::getNonHiddenRowCount
#
# Returns the number of non-hidden rows of the tablelist widget win in the
# specified range.
#------------------------------------------------------------------------------
proc tablelist::getNonHiddenRowCount {win first last} {
    upvar ::tablelist::ns${win}::data data

    if {$data(hiddenRowCount) == 0} {
	return [expr {$last - $first + 1}]
    } else {
	set count 0
	for {set row $first} {$row <= $last} {incr row} {
	    set key [lindex [lindex $data(itemList) $row] end]
	    if {![info exists data($key-hide)]} {
		incr count
	    }
	}
    }

    return $count
}

#------------------------------------------------------------------------------
# tablelist::nonHiddenRowOffsetToRowIndex
#
# Returns the row index corresponding to the given non-hidden row offset in the
# tablelist widget win.
#------------------------------------------------------------------------------
proc tablelist::nonHiddenRowOffsetToRowIndex {win offset} {
    upvar ::tablelist::ns${win}::data data

    if {$data(hiddenRowCount) == 0} {
	return $offset
    } else {
	#
	# Rebuild the list data(nonHiddenRowList) of the row
	# indices indicating the non-hidden rows if needed
	#
	if {[lindex $data(nonHiddenRowList) 0] == -1} {
	    set data(nonHiddenRowList) {}
	    for {set row 0} {$row < $data(itemCount)} {incr row} {
		set key [lindex [lindex $data(itemList) $row] end]
		if {![info exists data($key-hide)]} {
		    lappend data(nonHiddenRowList) $row
		}
	    }
	}

	set nonHiddenCount [llength $data(nonHiddenRowList)]
	if {$nonHiddenCount == 0} {
	    return 0
	} else {
	    if {$offset >= $nonHiddenCount} {
		set offset [expr {$nonHiddenCount - 1}]
	    }
	    if {$offset < 0} {
		set offset 0
	    }
	    return [lindex $data(nonHiddenRowList) $offset]
	}
    }
}
#==============================================================================
# Contains the implementation of the tablelist widget.
#
# Structure of the module:
#   - Namespace initialization
#   - Public procedure creating a new tablelist widget
#   - Private procedures implementing the tablelist widget command
#   - Private callback procedures
#
# Copyright (c) 2000-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================

#
# Namespace initialization
# ========================
#

namespace eval tablelist {
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
	-activestyle		 {activeStyle		  ActiveStyle	      w}
	-arrowcolor		 {arrowColor		  ArrowColor	      w}
	-arrowstyle		 {arrowStyle		  ArrowStyle	      w}
	-arrowdisabledcolor	 {arrowDisabledColor	  ArrowDisabledColor  w}
	-background		 {background		  Background	      b}
	-bg			 -background
	-borderwidth		 {borderWidth		  BorderWidth	      f}
	-bd			 -borderwidth
	-columns		 {columns		  Columns	      w}
	-cursor			 {cursor		  Cursor	      c}
	-disabledforeground	 {disabledForeground	  DisabledForeground  w}
	-editendcommand		 {editEndCommand	  EditEndCommand      w}
	-editstartcommand	 {editStartCommand	  EditStartCommand    w}
	-exportselection	 {exportSelection	  ExportSelection     w}
	-font			 {font			  Font		      b}
	-forceeditendcommand	 {forceEditEndCommand	  ForceEditEndCommand w}
	-foreground		 {foreground		  Foreground	      b}
	-fg			 -foreground
	-height			 {height		  Height	      w}
	-highlightbackground	 {highlightBackground	  HighlightBackground f}
	-highlightcolor		 {highlightColor	  HighlightColor      f}
	-highlightthickness	 {highlightThickness	  HighlightThickness  f}
	-incrarrowtype		 {incrArrowType		  IncrArrowType	      w}
	-labelactivebackground	 {labelActiveBackground	  Foreground          l}
	-labelactiveforeground	 {labelActiveForeground	  Background          l}
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
	-titlecolumns		 {titleColumns	  	  TitleColumns	      w}
	-width			 {width			  Width		      w}
	-xscrollcommand		 {xScrollCommand	  ScrollCommand	      w}
	-yscrollcommand		 {yScrollCommand	  ScrollCommand	      w}
    }

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
    #	Command-Line Name	{Database Name		Database Class	}
    #	-----------------------------------------------------------------
    #
    variable colConfigSpecs
    array set colConfigSpecs {
	-align			{align			Align		}
	-background		{background		Background	}
	-bg			-background
	-changesnipside		{changeSnipSide		ChangeSnipSide	}
	-editable		{editable		Editable	}
	-editwindow		{editWindow		EditWindow	}
	-font			{font			Font		}
	-foreground		{foreground		Foreground	}
	-fg			-foreground
	-formatcommand		{formatCommand		FormatCommand	}
	-hide			{hide			Hide		}
	-labelalign		{labelAlign		Align		}
	-labelbackground	{labelBackground	Background	}
	-labelbg		-labelbackground
	-labelborderwidth	{labelBorderWidth	BorderWidth	}
	-labelbd		-labelborderwidth
	-labelcommand		{labelCommand		LabelCommand	}
	-labelcommand2		{labelCommand2		LabelCommand2	}
	-labelfont		{labelFont		Font		}
	-labelforeground	{labelForeground	Foreground	}
	-labelfg		-labelforeground
	-labelheight		{labelHeight		Height		}
	-labelimage		{labelImage		Image		}
	-labelpady		{labelPadY		Pad		}
	-labelrelief		{labelRelief		Relief		}
	-maxwidth		{maxWidth		MaxWidth	}
	-name			{name			Name		}
	-resizable		{resizable		Resizable	}
	-selectbackground	{selectBackground	Foreground	}
	-selectforeground	{selectForeground	Background	}
	-showarrow		{showArrow		ShowArrow	}
	-showlinenumbers	{showLineNumbers	ShowLineNumbers }
	-sortcommand		{sortCommand		SortCommand	}
	-sortmode		{sortMode		SortMode	}
	-stretchable		{stretchable		Stretchable	}
	-text			{text			Text		}
	-title			{title			Title		}
	-width			{width			Width		}
    }

    #
    # Extend some elements of the array colConfigSpecs
    #
    lappend colConfigSpecs(-align)		- left
    lappend colConfigSpecs(-editable)		- 0
    lappend colConfigSpecs(-editwindow)		- entry
    lappend colConfigSpecs(-hide)		- 0
    lappend colConfigSpecs(-maxwidth)		- 0
    lappend colConfigSpecs(-resizable)		- 1
    lappend colConfigSpecs(-showarrow)		- 1
    lappend colConfigSpecs(-showlinenumbers)	- 0
    lappend colConfigSpecs(-sortmode)		- ascii
    lappend colConfigSpecs(-stretchable)	- 0
    lappend colConfigSpecs(-width)		- 0

    if {$usingTile} {
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
	-text			{text			Text		}
	-window			{window			Window		}
	-windowdestroy		{windowDestroy		WindowDestroy	}
    }

    #
    # Extend some elements of the array cellConfigSpecs
    #
    lappend cellConfigSpecs(-editable)		- 0
    lappend cellConfigSpecs(-editwindow)	- entry

    #
    # Use a list to facilitate the handling of the command options 
    #
    variable cmdOpts [list \
	activate activatecell attrib bbox bodypath bodytag cancelediting \
	cellcget cellconfigure cellindex cellselection cget columncget \
	columnconfigure columncount columnindex columnwidth configure \
	containing containingcell containingcolumn curcellselection \
	curselection delete deletecolumns editcell editwinpath entrypath \
	fillcolumn finishediting get getcells getcolumns getkeys \
	imagelabelpath index insert insertcolumnlist insertcolumns insertlist \
	itemlistvar labelpath labels move movecolumn nearest nearestcell \
	nearestcolumn rejectinput resetsortinfo rowcget rowconfigure scan see \
	seecell seecolumn selection separatorpath separators size sort \
	sortbycolumn sortbycolumnlist sortcolumn sortcolumnlist sortorder \
	sortorderlist togglecolumnhide togglerowhide windowpath xview yview]
    if {!$canElide} {
	set idx [lsearch -exact $cmdOpts togglerowhide]
	set cmdOpts [lreplace $cmdOpts $idx $idx]
    }

    #
    # Use lists to facilitate the handling of miscellaneous options
    #
    variable activeStyles	[list frame none underline]
    variable alignments		[list left right center]
    variable arrowStyles	[list flat7x4 flat7x5 flat7x7 flat8x5 flat9x5 \
				      sunken8x7 sunken10x9 sunken12x11]
    variable arrowTypes		[list up down]
    variable colWidthOpts	[list -requested -stretched -total]
    variable states		[list disabled normal]
    variable selectTypes	[list row cell]
    variable sortModes		[list ascii command dictionary integer real]
    variable sortOrders		[list increasing decreasing]
    variable _sortOrders	[list -increasing -decreasing]
    variable scanCmdOpts	[list mark dragto]
    variable selCmdOpts		[list anchor clear includes set]

    #
    # Define the procedure strToDispStr, which returns the string
    # obtained by replacing all \t characters in its argument with
    # \\t, as well as the procedure strMap, needed because the
    # "string map" command is not available in Tcl 8.0 and 8.1.0.
    #
    if {[catch {string map {} ""}] == 0} {
	proc strToDispStr str {
	    if {[string match "*\t*" $str]} {
		return [string map {"\t" "\\t"} $str]
	    } else {
		return $str
	    }
	}

	interp alias {} ::tablelist::strMap {} string map
    } else {
	proc strToDispStr str {
	    if {[string match "*\t*" $str]} {
		regsub -all "\t" $str "\\t" str
	    }

	    return $str
	}

	proc strMap {charMap str} {
	    foreach {key val} $charMap {
		#
		# We will only need this for noncritical key values
		#
		regsub -all $key $str $val str
	    }

	    return $str
	}
    }

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
    if {$usingTile} {
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
    if {[string compare $winSys "classic"] == 0 ||
	[string compare $winSys "aqua"] == 0} {
	event add <<Button3>> <Control-Button-1>
	event add <<ShiftButton3>> <Shift-Control-Button-1>
    }

    #
    # Define some mouse bindings for the binding tag TablelistLabel
    #
    bind TablelistLabel <Enter>		{ tablelist::labelEnter    %W %x }
    bind TablelistLabel <Motion>	{ tablelist::labelEnter    %W %x }
    bind TablelistLabel <Leave>		{ tablelist::labelLeave    %W %X %x %y }
    bind TablelistLabel <Button-1>	{ tablelist::labelB1Down   %W %x 0 }
    bind TablelistLabel <Shift-Button-1>  { tablelist::labelB1Down %W %x 1 }
    bind TablelistLabel <B1-Motion>	{ tablelist::labelB1Motion %W %X %x %y }
    bind TablelistLabel <B1-Enter>	{ tablelist::labelB1Enter  %W }
    bind TablelistLabel <B1-Leave>	{ tablelist::labelB1Leave  %W %x %y }
    bind TablelistLabel <ButtonRelease-1> { tablelist::labelB1Up   %W %X}
    bind TablelistLabel <<Button3>>	  { tablelist::labelB3Down %W 0 }
    bind TablelistLabel <<ShiftButton3>>  { tablelist::labelB3Down %W 1 }

    #
    # Define the binding tags TablelistSubLabel and TablelistArrow
    #
    defineTablelistSubLabel 
    defineTablelistArrow 

    #
    # Pre-register some widgets for interactive cell editing
    #
    variable editWin
    array set editWin {
	entry-registered			1
	text-registered				1
	checkbutton-registered			1
    }
    if {$::tk_version >= 8.4} {
	array set editWin {
	    spinbox-registered			1
	}
	if {[llength [package versions tile]] > 0} {
	    array set editWin {
		ttk::entry-registered		1
		ttk::combobox-registered	1
		ttk::checkbutton-registered	1
	    }
	}
    }
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
	    arrowWidth		 9
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
	    itemList		 {}
	    itemCount		 0
	    lastRow		-1
	    colList		 {}
	    colCount		 0
	    lastCol		-1
	    tagRefCount		 0
	    imgCount		 0
	    winCount		 0
	    afterId		 {}
	    labelClicked	 0
	    arrowColList	 {}
	    sortColList		 {}
	    sortOrder		 {}
	    editRow		-1
	    editCol		-1
	    forceAdjust		 0
	    fmtCmdFlagList	 {}
	    scrlColOffset	 0
	    cellsToReconfig	 {}
	    hiddenRowCount	 0
	    nonHiddenRowList	 {-1}
	    hiddenColCount	 0
	}

	#
	# The following array is used to hold arbitrary
	# attributes and their values for this widget
	#
	variable attribVals
    }

    #
    # Initialize some further components of data
    #
    upvar ::tablelist::ns${win}::data data
    foreach opt $configOpts {
	set data($opt) [lindex $configSpecs($opt) 3]
    }
    if {$usingTile} {
	variable themeDefaults
	set data(currentTheme) [getCurrentTheme]
	set data(themeDefaults) [array get themeDefaults]
	if {[string compare $data(currentTheme) "tileqt"] == 0} {
	    set data(widgetStyle) [tileqt_currentThemeName]
	    set data(colorScheme) [getKdeConfigVal "KDE" "colorScheme"]
	} else {
	    set data(widgetStyle) ""
	    set data(colorScheme) ""
	}
    }
    set data(-titlecolumns)	0		;# for Tk versions < 8.3
    set data(colFontList)	[list $data(-font)]
    set data(listVarTraceCmd)	[list tablelist::listVarTrace $win]
    set data(bodyTag)		body$win
    set data(body)		$win.body
    set data(bodyFr)		$data(body).f
    set data(bodyFrEd)		$data(bodyFr).e
    set data(rowGap)		$data(body).g
    set data(hdr)		$win.hdr
    set data(hdrTxt)		$data(hdr).t
    set data(hdrTxtFr)		$data(hdrTxt).f
    set data(hdrTxtFrCanv)	$data(hdrTxtFr).c
    set data(hdrTxtFrLbl)	$data(hdrTxtFr).l
    set data(hdrLbl)		$data(hdr).l
    set data(colGap)		$data(hdr).g
    set data(lb)		$win.lb
    set data(sep)		$win.sep

    #
    # Create a child hierarchy used to hold the column labels.  The
    # labels will be created as children of the frame data(hdrTxtFr),
    # which is embedded into the text widget data(hdrTxt) (in order
    # to make it scrollable), which in turn fills the frame data(hdr)
    # (whose width and height can be set arbitrarily in pixels).
    #
    set w $data(hdr)			;# header frame
    tk::frame $w -borderwidth 0 -container 0 -height 0 -highlightthickness 0 \
		 -relief flat -takefocus 0 -width 0
    catch {$w configure -padx 0 -pady 0}
    bind $w <Configure> {
	set tablelist::W [winfo parent %W]
	tablelist::stretchColumnsWhenIdle $tablelist::W
	tablelist::updateScrlColOffsetWhenIdle $tablelist::W
	tablelist::updateHScrlbarWhenIdle $tablelist::W
    }
    pack $w -fill x
    set w $data(hdrTxt)			;# text widget within the header frame
    text $w -borderwidth 0 -highlightthickness 0 -insertwidth 0 \
	    -padx 0 -pady 0 -state normal -takefocus 0 -wrap none
    place $w -relheight 1.0 -relwidth 1.0
    bindtags $w [lreplace [bindtags $w] 1 1]
    tk::frame $data(hdrTxtFr) -borderwidth 0 -container 0 -height 0 \
			      -highlightthickness 0 -relief flat \
			      -takefocus 0 -width 0
    catch {$data(hdrTxtFr) configure -padx 0 -pady 0}
    $w window create 1.0 -window $data(hdrTxtFr)
    set w $data(hdrLbl)			;# filler label within the header frame
    if {$usingTile} {
	ttk::label $data(hdrTxtFrLbl)0 -style TablelistHeader.TLabel
	ttk::label $w -style TablelistHeader.TLabel -image "" \
		      -padding {1 1 1 1} -takefocus 0 -text "" \
		      -textvariable "" -underline -1 -wraplength 0
    } else {
	tk::label $data(hdrTxtFrLbl)0 
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
    bind $w <Configure> {
	set tablelist::W [winfo parent %W]
	tablelist::makeColFontAndTagLists $tablelist::W
	tablelist::adjustElidedTextWhenIdle $tablelist::W
	tablelist::updateColorsWhenIdle $tablelist::W
	tablelist::adjustSepsWhenIdle $tablelist::W
	tablelist::updateVScrlbarWhenIdle $tablelist::W
    }
    pack $w -expand 1 -fill both

    #
    # Modify the list of binding tags of the body text widget
    #
    bindtags $w [list $w $data(bodyTag) TablelistBody [winfo toplevel $w] \
		 TablelistKeyNav all]

    #
    # Create the "stripe", "select", "active", "disabled", "hiddenRow",
    # "hiddenCol", and "elidedCol" tags in the body text widget.  Don't
    # use the built-in "sel" tag because on Windows the selection in a
    # text widget only becomes visible when the window gets the input
    # focus.  DO NOT CHANGE the order of creation of these tags!
    #
    $w tag configure stripe -background "" -foreground ""    ;# will be changed
    $w tag configure select -relief raised
    $w tag configure active -borderwidth ""		     ;# will be changed
    $w tag configure disabled -foreground ""		     ;# will be changed
    if {$canElide} {
	$w tag configure hiddenRow -elide 1
	$w tag configure hiddenCol -elide 1
	$w tag configure elidedCol -elide 1
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
    # Move the original widget command into the current namespace
    # and build a new widget procedure in the global one
    #
    rename ::$win $win
    proc ::$win args [format {
	if {[catch {tablelist::tablelistWidgetCmd %s $args} result] == 0} {
	    return $result
	} else {
	    return -code error $result
	}
    } [list $win]]

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
# This procedure is invoked to process the Tcl command corresponding to a
# tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::tablelistWidgetCmd {win argList} {
    variable cmdOpts
    upvar ::tablelist::ns${win}::data data

    set argCount [llength $argList]
    if {$argCount == 0} {
	mwutil::wrongNumArgs "$win option ?arg arg ...?"
    }

    set cmd [mwutil::fullOpt "option" [lindex $argList 0] $cmdOpts]
    switch $cmd {
	activate -
	bbox -
	see {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd index"
	    }

	    synchronize $win
	    set index [rowIndex $win [lindex $argList 1] 0]
	    return [${cmd}SubCmd $win $index]
	}

	activatecell {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd cellIndex"
	    }

	    synchronize $win
	    foreach {row col} [cellIndex $win [lindex $argList 1] 0] {}
	    return [activatecellSubCmd $win $row $col]
	}

	attrib {
	    return [mwutil::attribSubCmd $win [lrange $argList 1 end]]
	}

	bodypath {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    return $data(body)
	}

	bodytag {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    return $data(bodyTag)
	}

	cancelediting -
	curcellselection -
	curselection -
	finishediting {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    synchronize $win
	    return [${cmd}SubCmd $win]
	}

	cellcget {
	    if {$argCount != 3} {
		mwutil::wrongNumArgs "$win $cmd cellIndex option"
	    }

	    synchronize $win
	    foreach {row col} [cellIndex $win [lindex $argList 1] 1] {}
	    variable cellConfigSpecs
	    set opt [mwutil::fullConfigOpt [lindex $argList 2] cellConfigSpecs]
	    return [doCellCget $row $col $win $opt]
	}

	cellconfigure {
	    if {$argCount < 2} {
		mwutil::wrongNumArgs "$win $cmd cellIndex ?option? ?value\
				      option value ...?"
	    }

	    synchronize $win
	    foreach {row col} [cellIndex $win [lindex $argList 1] 1] {}
	    variable cellConfigSpecs
	    set argList [lrange $argList 2 end]
	    return [mwutil::configureSubCmd $win cellConfigSpecs \
		    "tablelist::doCellConfig $row $col" \
		    "tablelist::doCellCget $row $col" $argList]
	}

	cellindex {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd cellIndex"
	    }

	    synchronize $win
	    return [join [cellIndex $win [lindex $argList 1] 0] ","]
	}

	cellselection {
	    if {$argCount < 3 || $argCount > 4} {
		mwutil::wrongNumArgs \
			"$win $cmd option firstCellIndex lastCellIndex" \
			"$win $cmd option cellIndexList"
	    }

	    synchronize $win
	    variable selCmdOpts
	    set opt [mwutil::fullOpt "option" [lindex $argList 1] $selCmdOpts]
	    set first [lindex $argList 2]
	    switch $opt {
		anchor -
		includes {
		    if {$argCount != 3} {
			mwutil::wrongNumArgs "$win cellselection $opt cellIndex"
		    }
		    foreach {row col} [cellIndex $win $first 0] {}
		    return [cellselectionSubCmd $win $opt $row $col $row $col]
		}
		clear -
		set {
		    if {$argCount == 3} {
			foreach elem $first {
			    foreach {row col} [cellIndex $win $elem 0] {}
			    cellselectionSubCmd $win $opt $row $col $row $col
			}
			return ""
		    } else {
			foreach {firstRow firstCol} \
				[cellIndex $win $first 0] {}
			foreach {lastRow lastCol} \
				[cellIndex $win [lindex $argList 3] 0] {}
			return [cellselectionSubCmd $win $opt \
				$firstRow $firstCol $lastRow $lastCol]
		    }
		}
	    }
	}

	cget {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd option"
	    }

	    #
	    # Return the value of the specified configuration option
	    #
	    variable configSpecs
	    set opt [mwutil::fullConfigOpt [lindex $argList 1] configSpecs]
	    return $data($opt)
	}

	columncget {
	    if {$argCount != 3} {
		mwutil::wrongNumArgs "$win $cmd columnIndex option"
	    }

	    synchronize $win
	    set col [colIndex $win [lindex $argList 1] 1]
	    variable colConfigSpecs
	    set opt [mwutil::fullConfigOpt [lindex $argList 2] colConfigSpecs]
	    return [doColCget $col $win $opt]
	}

	columnconfigure {
	    if {$argCount < 2} {
		mwutil::wrongNumArgs "$win $cmd columnIndex ?option? ?value\
				      option value ...?"
	    }

	    synchronize $win
	    set col [colIndex $win [lindex $argList 1] 1]
	    variable colConfigSpecs
	    set argList [lrange $argList 2 end]
	    return [mwutil::configureSubCmd $win colConfigSpecs \
		    "tablelist::doColConfig $col" \
		    "tablelist::doColCget $col" $argList]
	}

	columncount {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    return $data(colCount)
	}

	columnindex {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd columnIndex"
	    }

	    synchronize $win
	    return [colIndex $win [lindex $argList 1] 0]
	}

	columnwidth {
	    if {$argCount < 2 || $argCount > 3} {
		mwutil::wrongNumArgs "$win $cmd columnIndex\
				      ?-requested|-stretched|-total?"
	    }

	    synchronize $win
	    set col [colIndex $win [lindex $argList 1] 1]
	    if {$argCount == 2} {
		set opt -requested
	    } else {
		variable colWidthOpts
		set opt [mwutil::fullOpt "option" \
			 [lindex $argList 2] $colWidthOpts]
	    }
	    return [columnwidthSubCmd $win $col $opt]
	}

	configure {
	    variable configSpecs
	    return [mwutil::configureSubCmd $win configSpecs \
		    tablelist::doConfig tablelist::doCget \
		    [lrange $argList 1 end]]
	}

	containing {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd y"
	    }

	    set y [format "%d" [lindex $argList 1]]
	    synchronize $win
	    return [containingSubCmd $win $y]
	}

	containingcell {
	    if {$argCount != 3} {
		mwutil::wrongNumArgs "$win $cmd x y"
	    }

	    set x [format "%d" [lindex $argList 1]]
	    set y [format "%d" [lindex $argList 2]]
	    synchronize $win
	    return [containingSubCmd $win $y],[containingcolumnSubCmd $win $x]
	}

	containingcolumn {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd x"
	    }

	    set x [format "%d" [lindex $argList 1]]
	    synchronize $win
	    return [containingcolumnSubCmd $win $x]
	}

	delete -
	get -
	getkeys -
	togglerowhide {
	    if {$argCount < 2 || $argCount > 3} {
		mwutil::wrongNumArgs "$win $cmd firstIndex lastIndex" \
				     "$win $cmd indexList"
	    }

	    synchronize $win
	    set first [lindex $argList 1]
	    if {$argCount == 3} {
		set last [lindex $argList 2]
	    } else {
		set last $first
	    }
	    incr argCount -1
	    return [${cmd}SubCmd $win $first $last $argCount]
	}

	deletecolumns -
	getcolumns -
	togglecolumnhide {
	    if {$argCount < 2 || $argCount > 3} {
		mwutil::wrongNumArgs \
			"$win $cmd firstColumnIndex lastColumnIndex" \
			"$win $cmd columnIndexList"
	    }

	    synchronize $win
	    set first [lindex $argList 1]
	    if {$argCount == 3} {
		set last [lindex $argList 2]
	    } else {
		set last $first
	    }
	    incr argCount -1
	    return [${cmd}SubCmd $win $first $last $argCount]
	}

	editcell {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd cellIndex"
	    }

	    synchronize $win
	    foreach {row col} [cellIndex $win [lindex $argList 1] 1] {}
	    return [editcellSubCmd $win $row $col 0]
	}

	editwinpath {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    if {[winfo exists $data(bodyFrEd)]} {
		return $data(bodyFrEd)
	    } else {
		return ""
	    }
	}

	entrypath {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    if {[winfo exists $data(bodyFrEd)]} {
		set class [winfo class $data(bodyFrEd)]
		if {[regexp {^(Mentry|T?Checkbutton)$} $class]} {
		    return ""
		} else {
		    return $data(editFocus)
		}
	    } else {
		return ""
	    }
	}

	fillcolumn {
	    if {$argCount != 3} {
		mwutil::wrongNumArgs "$win $cmd columnIndex text"
	    }

	    synchronize $win
	    set col [colIndex $win [lindex $argList 1] 1]
	    return [fillcolumnSubCmd $win $col [lindex $argList 2]]
	}

	getcells {
	    if {$argCount < 2 || $argCount > 3} {
		mwutil::wrongNumArgs \
			"$win $cmd firstCellIndex lastCellIndex" \
			"$win $cmd cellIndexList"
	    }

	    synchronize $win
	    set first [lindex $argList 1]
	    if {$argCount == 3} {
		set last [lindex $argList 2]
	    } else {
		set last $first
	    }
	    incr argCount -1
	    return [${cmd}SubCmd $win $first $last $argCount]
	}

	imagelabelpath {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd cellIndex"
	    }

	    synchronize $win
	    foreach {row col} [cellIndex $win [lindex $argList 1] 1] {}
	    set key [lindex [lindex $data(itemList) $row] end]
	    set w $data(body).l$key,$col
	    if {[winfo exists $w]} {
		return $w
	    } else {
		return ""
	    }
	}

	index {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd index"
	    }

	    synchronize $win
	    return [rowIndex $win [lindex $argList 1] 1]
	}

	insert {
	    if {$argCount < 2} {
		mwutil::wrongNumArgs "$win $cmd index ?item item ...?"
	    }

	    synchronize $win
	    set index [rowIndex $win [lindex $argList 1] 1]
	    return [insertSubCmd $win $index [lrange $argList 2 end] \
		    $data(hasListVar)]
	}

	insertcolumnlist {
	    if {$argCount != 3} {
		mwutil::wrongNumArgs "$win $cmd columnIndex columnList"
	    }

	    synchronize $win
	    set arg1 [lindex $argList 1]
	    if {[string first $arg1 "end"] == 0 || $arg1 == $data(colCount)} {
		set col $data(colCount)
	    } else {
		set col [colIndex $win $arg1 1]
	    }
	    return [insertcolumnsSubCmd $win $col [lindex $argList 2]]
	}

	insertcolumns {
	    if {$argCount < 2} {
		mwutil::wrongNumArgs "$win $cmd columnIndex\
			?width title ?alignment? width title ?alignment? ...?"
	    }

	    synchronize $win
	    set arg1 [lindex $argList 1]
	    if {[string first $arg1 "end"] == 0 || $arg1 == $data(colCount)} {
		set col $data(colCount)
	    } else {
		set col [colIndex $win $arg1 1]
	    }
	    return [insertcolumnsSubCmd $win $col [lrange $argList 2 end]]
	}

	insertlist {
	    if {$argCount != 3} {
		mwutil::wrongNumArgs "$win $cmd index list"
	    }

	    synchronize $win
	    set index [rowIndex $win [lindex $argList 1] 1]
	    return [insertSubCmd $win $index [lindex $argList 2] \
		    $data(hasListVar)]
	}

	itemlistvar {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    return ::tablelist::ns${win}::data(itemList)
	}

	labelpath {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd columnIndex"
	    }

	    synchronize $win
	    set col [colIndex $win [lindex $argList 1] 1]
	    return $data(hdrTxtFrLbl)$col
	}

	labels {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    set labelList {}
	    for {set col 0} {$col < $data(colCount)} {incr col} {
		lappend labelList $data(hdrTxtFrLbl)$col
	    }
	    return $labelList
	}

	move {
	    if {$argCount != 3} {
		mwutil::wrongNumArgs "$win $cmd sourceIndex targetIndex"
	    }

	    synchronize $win
	    set source [rowIndex $win [lindex $argList 1] 0]
	    set target [rowIndex $win [lindex $argList 2] 1]
	    return [moveSubCmd $win $source $target]
	}

	movecolumn {
	    if {$argCount != 3} {
		mwutil::wrongNumArgs "$win $cmd sourceColumnIndex\
				      targetColumnIndex"
	    }

	    synchronize $win
	    set arg1 [lindex $argList 1]
	    set source [colIndex $win $arg1 1]
	    set arg2 [lindex $argList 2]
	    if {[string first $arg2 "end"] == 0 || $arg2 == $data(colCount)} {
		set target $data(colCount)
	    } else {
		set target [colIndex $win $arg2 1]
	    }
	    return [movecolumnSubCmd $win $source $target]
	}

	nearest {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd y"
	    }

	    set y [format "%d" [lindex $argList 1]]
	    synchronize $win
	    return [rowIndex $win @0,$y 0]
	}

	nearestcell {
	    if {$argCount != 3} {
		mwutil::wrongNumArgs "$win $cmd x y"
	    }

	    set x [format "%d" [lindex $argList 1]]
	    set y [format "%d" [lindex $argList 2]]
	    synchronize $win
	    return [join [cellIndex $win @$x,$y 0] ","]
	}

	nearestcolumn {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd x"
	    }

	    set x [format "%d" [lindex $argList 1]]
	    synchronize $win
	    return [colIndex $win @$x,0 0]
	}

	rejectinput {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    set data(rejected) 1
	}

	resetsortinfo {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

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
		adjustColumns $win $whichWidths 1
	    }
	    return ""
	}

	rowcget {
	    if {$argCount != 3} {
		mwutil::wrongNumArgs "$win $cmd index option"
	    }

	    #
	    # Check the row index
	    #
	    synchronize $win
	    set rowArg [lindex $argList 1]
	    set row [rowIndex $win $rowArg 0]
	    if {$row < 0 || $row > $data(lastRow)} {
		return -code error "row index \"$rowArg\" out of range"
	    }

	    variable rowConfigSpecs
	    set opt [mwutil::fullConfigOpt [lindex $argList 2] rowConfigSpecs]
	    return [doRowCget $row $win $opt]
	}

	rowconfigure {
	    if {$argCount < 2} {
		mwutil::wrongNumArgs "$win $cmd index ?option? ?value\
				      option value ...?"
	    }

	    #
	    # Check the row index
	    #
	    synchronize $win
	    set rowArg [lindex $argList 1]
	    set row [rowIndex $win $rowArg 0]
	    if {$row < 0 || $row > $data(lastRow)} {
		return -code error "row index \"$rowArg\" out of range"
	    }

	    variable rowConfigSpecs
	    set argList [lrange $argList 2 end]
	    return [mwutil::configureSubCmd $win rowConfigSpecs \
		    "tablelist::doRowConfig $row" \
		    "tablelist::doRowCget $row" $argList]
	}

	scan {
	    if {$argCount != 4} {
		mwutil::wrongNumArgs "$win $cmd mark|dragto x y"
	    }

	    set x [format "%d" [lindex $argList 2]]
	    set y [format "%d" [lindex $argList 3]]
	    variable scanCmdOpts
	    set opt [mwutil::fullOpt "option" [lindex $argList 1] $scanCmdOpts]
	    synchronize $win
	    return [scanSubCmd $win $opt $x $y]
	}

	seecell {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd cellIndex"
	    }

	    synchronize $win
	    foreach {row col} [cellIndex $win [lindex $argList 1] 0] {}
	    if {[winfo viewable $win]} {
		return [seecellSubCmd $win $row $col]
	    } else {
		after idle [list tablelist::seecellSubCmd $win $row $col]
		return ""
	    }
	}

	seecolumn {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd columnIndex"
	    }

	    synchronize $win
	    set col [colIndex $win [lindex $argList 1] 0]
	    if {[winfo viewable $win]} {
		return [seecellSubCmd $win [rowIndex $win @0,0 0] $col]
	    } else {
		after idle [list tablelist::seecellSubCmd \
			    $win [rowIndex $win @0,0 0] $col]
		return ""
	    }
	}

	selection {
	    if {$argCount < 3 || $argCount > 4} {
		mwutil::wrongNumArgs "$win $cmd option firstIndex lastIndex" \
				     "$win $cmd option indexList"
	    }

	    synchronize $win
	    variable selCmdOpts
	    set opt [mwutil::fullOpt "option" [lindex $argList 1] $selCmdOpts]
	    set first [lindex $argList 2]
	    switch $opt {
		anchor -
		includes {
		    if {$argCount != 3} {
			mwutil::wrongNumArgs "$win selection $opt index"
		    }
		    set index [rowIndex $win $first 0]
		    return [selectionSubCmd $win $opt $index $index]
		}
		clear -
		set {
		    if {$argCount == 3} {
			foreach elem $first {
			    set index [rowIndex $win $elem 0]
			    selectionSubCmd $win $opt $index $index
			}
			return ""
		    } else {
			set first [rowIndex $win $first 0]
			set last [rowIndex $win [lindex $argList 3] 0]
			return [selectionSubCmd $win $opt $first $last]
		    }
		}
	    }
	}

	separatorpath {
	    if {$argCount < 1 || $argCount > 2} {
		mwutil::wrongNumArgs "$win $cmd ?columnIndex?"
	    }

	    if {$argCount == 1} {
		if {[winfo exists $data(sep)]} {
		    return $data(sep)
		} else {
		    return ""
		}
	    } else {
		synchronize $win
		set col [colIndex $win [lindex $argList 1] 1]
		if {$data(-showseparators)} {
		    return $data(sep)$col
		} else {
		    return ""
		}
	    }
	}

	separators {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    set sepList {}
	    foreach w [winfo children $win] {
		if {[regexp {^sep([0-9]+)?$} [winfo name $w]]} {
		    lappend sepList $w
		}
	    }
	    return [lsort -dictionary $sepList]
	}

	size {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    synchronize $win
	    return $data(itemCount)
	}

	sort {
	    if {$argCount < 1 || $argCount > 2} {
		mwutil::wrongNumArgs "$win $cmd  ?-increasing|-decreasing?"
	    }

	    if {$argCount == 1} {
		set order -increasing
	    } else {
		variable _sortOrders
		set order [mwutil::fullOpt "option" \
			   [lindex $argList 2] $_sortOrders]
	    }
	    synchronize $win
	    return [sortSubCmd $win -1 [string range $order 1 end]]
	}

	sortbycolumn {
	    if {$argCount < 2 || $argCount > 3} {
		mwutil::wrongNumArgs "$win $cmd columnIndex\
				      ?-increasing|-decreasing?"
	    }

	    synchronize $win
	    set col [colIndex $win [lindex $argList 1] 1]
	    if {$argCount == 2} {
		set order -increasing
	    } else {
		variable _sortOrders
		set order [mwutil::fullOpt "option" \
			   [lindex $argList 2] $_sortOrders]
	    }
	    return [sortSubCmd $win $col [string range $order 1 end]]
	}

	sortbycolumnlist {
	    if {$argCount < 2 || $argCount > 3} {
		mwutil::wrongNumArgs "$win $cmd columnIndexList ?sortOrderList?"
	    }

	    synchronize $win
	    set sortColList {}
	    foreach elem [lindex $argList 1] {
		set col [colIndex $win $elem 1]
		if {[lsearch -exact $sortColList $col] >= 0} {
		    return -code error "duplicate column index \"$elem\""
		}
		lappend sortColList $col
	    }
	    set sortOrderList {}
	    if {$argCount == 3} {
		variable sortOrders
		foreach elem [lindex $argList 2] {
		    lappend sortOrderList \
			    [mwutil::fullOpt "option" $elem $sortOrders]
		}
	    }
	    return [sortSubCmd $win $sortColList $sortOrderList]
	}

	sortcolumn {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    if {[llength $data(sortColList)] == 0} {
		return -1
	    } else {
		return [lindex $data(sortColList) 0]
	    }
	}

	sortcolumnlist {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    return $data(sortColList)
	}

	sortorder {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    if {[llength $data(sortColList)] == 0} {
		return $data(sortOrder)
	    } else {
		set col [lindex $data(sortColList) 0]
		return $data($col-sortOrder)
	    }
	}

	sortorderlist {
	    if {$argCount != 1} {
		mwutil::wrongNumArgs "$win $cmd"
	    }

	    set sortOrderList {}
	    foreach col $data(sortColList) {
		lappend sortOrderList $data($col-sortOrder)
	    }
	    return $sortOrderList
	}

	windowpath {
	    if {$argCount != 2} {
		mwutil::wrongNumArgs "$win $cmd cellIndex"
	    }

	    synchronize $win
	    foreach {row col} [cellIndex $win [lindex $argList 1] 1] {}
	    set key [lindex [lindex $data(itemList) $row] end]
	    set w $data(body).f$key,$col.w
	    if {[winfo exists $w]} {
		return $w
	    } else {
		return ""
	    }
	}

	xview -
	yview {
	    synchronize $win
	    return [${cmd}SubCmd $win [lrange $argList 1 end]]
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::activateSubCmd
#
# This procedure is invoked to process the tablelist activate subcommand.
#------------------------------------------------------------------------------
proc tablelist::activateSubCmd {win index} {
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled)} {
	return ""
    }

    #
    # Adjust the index to fit within the existing non-hidden items
    #
    adjustRowIndex $win index 1

    set data(activeRow) $index
    return ""
}

#------------------------------------------------------------------------------
# tablelist::activatecellSubCmd
#
# This procedure is invoked to process the tablelist activatecell subcommand.
#------------------------------------------------------------------------------
proc tablelist::activatecellSubCmd {win row col} {
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled)} {
	return ""
    }

    #
    # Adjust the row and column indices to fit
    # within the existing non-hidden elements
    #
    adjustRowIndex $win row 1
    adjustColIndex $win col 1

    set data(activeRow) $row
    set data(activeCol) $col
    return ""
}

#------------------------------------------------------------------------------
# tablelist::bboxSubCmd
#
# This procedure is invoked to process the tablelist bbox subcommand.
#------------------------------------------------------------------------------
proc tablelist::bboxSubCmd {win index} {
    upvar ::tablelist::ns${win}::data data

    set w $data(body)
    set dlineinfo [$w dlineinfo [expr {double($index + 1)}]]
    if {$data(itemCount) == 0 || [string compare $dlineinfo ""] == 0} {
	return {}
    }

    set spacing1 [$w cget -spacing1]
    set spacing3 [$w cget -spacing3]
    foreach {x y width height baselinePos} $dlineinfo {}
    lappend bbox [expr {$x + [winfo x $w]}] \
		 [expr {$y + [winfo y $w] + $spacing1}] \
		 $width [expr {$height - $spacing1 - $spacing3}]
    return $bbox
}

#------------------------------------------------------------------------------
# tablelist::cellselectionSubCmd
#
# This procedure is invoked to process the tablelist cellselection subcommand.
#------------------------------------------------------------------------------
proc tablelist::cellselectionSubCmd {win opt firstRow firstCol \
				     lastRow lastCol} {
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled) && [string compare $opt "includes"] != 0} {
	return ""
    }

    switch $opt {
	anchor {
	    #
	    # Adjust the row and column indices to fit
	    # within the existing non-hidden elements
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

	    #
	    # Shrink the column range to be delimited by non-hidden columns
	    #
	    while {$firstCol <= $lastCol && $data($firstCol-hide)} {
		incr firstCol
	    }
	    if {$firstCol > $lastCol} {
		return ""
	    }
	    while {$lastCol >= $firstCol && $data($lastCol-hide)} {
		incr lastCol -1
	    }

	    set firstTextIdx [expr {$firstRow + 1}].0
	    set lastTextIdx [expr {$lastRow + 1}].end

	    #
	    # Find the (partly) selected lines of the body text
	    # widget in the text range specified by the two indices
	    #
	    set w $data(body)
	    variable canElide
	    variable elide
	    set selRange [$w tag nextrange select $firstTextIdx $lastTextIdx]
	    while {[llength $selRange] != 0} {
		set selStart [lindex $selRange 0]
		set line [expr {int($selStart)}]
		set row [expr {$line - 1}]
		set key [lindex [lindex $data(itemList) $row] end]

		#
		# Deselect the relevant elements of the row and handle
		# the -(select)background and -(select)foreground
		# cell and column configuration options for them
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
		    foreach optTail {background foreground} {
			set opt -select$optTail
			foreach name  [list $col$opt $key$opt $key,$col$opt] \
				level [list col row cell] {
			    if {[info exists data($name)]} {
				$w tag remove $level$opt-$data($name) \
				       $textIdx1 $textIdx2
			    }
			}
			foreach name  [list $col-$optTail $key-$optTail \
				       $key,$col-$optTail] \
				level [list col row cell] {
			    if {[info exists data($name)]} {
				$w tag add $level-$optTail-$data($name) \
				       $textIdx1 $textIdx2
			    }
			}
		    }
		    set textIdx1 $textIdx2
		}

		set selRange \
		    [$w tag nextrange select "$selStart lineend" $lastTextIdx]
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
	    if {[lsearch -exact [$data(body) tag names $tabIdx1] select] < 0} {
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

	    #
	    # Shrink the column range to be delimited by non-hidden columns
	    #
	    while {$firstCol <= $lastCol && $data($firstCol-hide)} {
		incr firstCol
	    }
	    if {$firstCol > $lastCol} {
		return ""
	    }
	    while {$lastCol >= $firstCol && $data($lastCol-hide)} {
		incr lastCol -1
	    }

	    set w $data(body)
	    variable canElide
	    variable elide
	    for {set row $firstRow; set line [expr {$firstRow + 1}]} \
		{$row <= $lastRow} {set row $line; incr line} {
		#
		# Check whether the row is selectable and non-hidden
		#
		set key [lindex [lindex $data(itemList) $row] end]
		if {[info exists data($key-selectable)] ||
		    [info exists data($key-hide)]} {
		    continue
		}

		#
		# Select the relevant non-hidden elements of the row and
		# handle the -(select)background and -(select)foreground
		# cell and column configuration options for them
		#
		findTabs $win $line $firstCol $lastCol firstTabIdx lastTabIdx
		set textIdx1 $firstTabIdx
		for {set col $firstCol} {$col <= $lastCol} {incr col} {
		    if {$data($col-hide) && !$canElide} {
			continue
		    }

		    set textIdx2 \
			[$w search $elide "\t" $textIdx1+1c $lastTabIdx+1c]+1c
		    if {$data($col-hide)} {
			set textIdx1 $textIdx2
			continue
		    }

		    $w tag add select $textIdx1 $textIdx2
		    foreach optTail {background foreground} {
			set opt -select$optTail
			foreach name  [list $col$opt $key$opt $key,$col$opt] \
				level [list col row cell] {
			    if {[info exists data($name)]} {
				$w tag add $level$opt-$data($name) \
				       $textIdx1 $textIdx2
			    }
			}
			foreach name  [list $col-$optTail $key-$optTail \
				       $key,$col-$optTail] \
				level [list col row cell] {
			    if {[info exists data($name)]} {
				set tag $level-$optTail-$data($name)
				$w tag remove $level-$optTail-$data($name) \
				       $textIdx1 $textIdx2
			    }
			}
		    }
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
# tablelist::columnwidthSubCmd
#
# This procedure is invoked to process the tablelist columnwidth subcommand.
#------------------------------------------------------------------------------
proc tablelist::columnwidthSubCmd {win col opt} {
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
# tablelist::containingSubCmd
#
# This procedure is invoked to process the tablelist containing subcommand.
#------------------------------------------------------------------------------
proc tablelist::containingSubCmd {win y} {
    upvar ::tablelist::ns${win}::data data

    if {$data(itemCount) == 0} {
	return -1
    }

    set row [rowIndex $win @0,$y 0]

    set w $data(body)
    incr y -[winfo y $w]
    set dlineinfo [$w dlineinfo [expr {double($row + 1)}]]
    if {$y < [lindex $dlineinfo 1] + [lindex $dlineinfo 3]} {
	return $row
    } else {
	return -1
    }
}

#------------------------------------------------------------------------------
# tablelist::containingcolumnSubCmd
#
# This procedure is invoked to process the tablelist containingcolumn
# subcommand.
#------------------------------------------------------------------------------
proc tablelist::containingcolumnSubCmd {win x} {
    upvar ::tablelist::ns${win}::data data

    set col [colIndex $win @$x,0 0]
    if {$col < 0} {
	return -1
    }

    set lbl $data(hdrTxtFrLbl)$col
    if {$x + [winfo rootx $win] < [winfo width $lbl] + [winfo rootx $lbl]} {
	return $col
    } else {
	return -1
    }
}

#------------------------------------------------------------------------------
# tablelist::curcellselectionSubCmd
#
# This procedure is invoked to process the tablelist curcellselection
# subcommand.
#------------------------------------------------------------------------------
proc tablelist::curcellselectionSubCmd {win {getKeys 0}} {
    variable canElide
    variable elide
    upvar ::tablelist::ns${win}::data data

    #
    # Find the (partly) selected lines of the body text widget
    #
    set result {}
    set w $data(body)
    set selRange [$w tag nextrange select 1.0]
    while {[llength $selRange] != 0} {
	set selStart [lindex $selRange 0]
	set selEnd [lindex $selRange 1]
	set line [expr {int($selStart)}]
	set row [expr {$line - 1}]

	#
	# Get the index of the column starting at the text position selStart
	#
	set textIdx $line.0
	for {set col 0} {$col < $data(colCount)} {incr col} {
	    if {!$data($col-hide) || $canElide} {
		if {[$w compare $textIdx == $selStart]} {
		    set firstCol $col
		    break
		} else {
		    set textIdx [$w search $elide "\t" $textIdx+1c $selEnd]+1c
		}
	    }
	}

	#
	# Process the columns, starting at the found one
	# and ending just before the text position selEnd
	#
	if {$getKeys} {
	    set key [lindex [lindex $data(itemList) $row] end]
	}
	set textIdx [$w search $elide "\t" $textIdx+1c $selEnd]+1c
	for {set col $firstCol} {$col < $data(colCount)} {incr col} {
	    if {!$data($col-hide) || $canElide} {
		if {$getKeys} {
		    lappend result $key $col
		} else {
		    lappend result $row,$col
		}
		if {[$w compare $textIdx == $selEnd]} {
		    break
		} else {
		    set textIdx [$w search $elide "\t" $textIdx+1c $selEnd]+1c
		}
	    }
	}

	set selRange [$w tag nextrange select $selEnd]
    }
    return $result
}

#------------------------------------------------------------------------------
# tablelist::curselectionSubCmd
#
# This procedure is invoked to process the tablelist curselection subcommand.
#------------------------------------------------------------------------------
proc tablelist::curselectionSubCmd win {
    upvar ::tablelist::ns${win}::data data

    #
    # Find the (partly) selected lines of the body text widget
    #
    set result {}
    set w $data(body)
    set selRange [$w tag nextrange select 1.0]
    while {[llength $selRange] != 0} {
	set selStart [lindex $selRange 0]
	lappend result [expr {int($selStart) - 1}]

	set selRange [$w tag nextrange select "$selStart lineend"]
    }
    return $result
}

#------------------------------------------------------------------------------
# tablelist::deleteSubCmd
#
# This procedure is invoked to process the tablelist delete subcommand.
#------------------------------------------------------------------------------
proc tablelist::deleteSubCmd {win first last argCount} {
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled)} {
	return ""
    }

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
	set last [rowIndex $win $last 0]
	return [deleteRows $win $first $last $data(hasListVar)]
    }
}

#------------------------------------------------------------------------------
# tablelist::deleteRows
#
# Deletes a given range of rows of a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::deleteRows {win first last updateListVar} {
    upvar ::tablelist::ns${win}::data data

    #
    # Adjust the range to fit within the existing items
    #
    if {$first < 0} {
	set first 0
    }
    if {$last > $data(lastRow)} {
	set last $data(lastRow)
    }
    set count [expr {$last - $first + 1}]
    if {$count <= 0} {
	return ""
    }

    #
    # Check whether the width of any dynamic-width
    # column might be affected by the deletion
    #
    set w $data(body)
    set itemListRange [lrange $data(itemList) $first $last]
    if {$count == $data(itemCount)} {
	set colWidthsChanged 1				;# just to save time
	set data(seqNum) -1
	set data(freeKeyList) {}
    } else {
	variable canElide
	set colWidthsChanged 0
	set snipStr $data(-snipstring)
	set hasFmtCmds [expr {[lsearch -exact $data(fmtCmdFlagList) 1] >= 0}]
	foreach item $itemListRange {
	    #
	    # Format the item
	    #
	    if {$hasFmtCmds} {
		set formattedItem \
		    [formatItem $win [lrange $item 0 $data(lastCol)]]
	    } else {
		set formattedItem [lrange $item 0 $data(lastCol)]
	    }

	    set key [lindex $item end]
	    set col 0
	    foreach text [strToDispStr $formattedItem] \
		    {pixels alignment} $data(colList) {
		if {($data($col-hide) && !$canElide) || $pixels != 0} {
		    incr col
		    continue
		}

		getAuxData $win $key $col auxType auxWidth
		set cellFont [getCellFont $win $key $col]
		set elemWidth [getElemWidth $win $text $auxWidth $cellFont]
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
	}
    }

    #
    # Delete the given items from the body text widget.  Interestingly,
    # for a large number of items it is much more efficient to delete
    # each line individually than to invoke a global delete command.
    #
    set textIdx1 [expr {double($first + 1)}]
    set textIdx2 [expr {double($first + 2)}]
    foreach item $itemListRange {
	$w delete $textIdx1 $textIdx2

	set key [lindex $item end]
	if {$count != $data(itemCount)} {
	    lappend data(freeKeyList) $key
	}

	foreach opt {-background -foreground -font} {
	    if {[info exists data($key$opt)]} {
		unset data($key$opt)
		incr data(tagRefCount) -1
	    }
	}
	if {[info exists data($key-hide)]} {
	    unset data($key-hide)
	    incr data(hiddenRowCount) -1
	}
	foreach opt {-name -selectable -selectbackground -selectforeground} {
	    if {[info exists data($key$opt)]} {
		unset data($key$opt)
	    }
	}

	for {set col 0} {$col < $data(colCount)} {incr col} {
	    foreach opt {-background -foreground -font} {
		if {[info exists data($key,$col$opt)]} {
		    unset data($key,$col$opt)
		    incr data(tagRefCount) -1
		}
	    }
	    foreach opt {-editable -editwindow -selectbackground
			 -selectforeground -windowdestroy} {
		if {[info exists data($key,$col$opt)]} {
		    unset data($key,$col$opt)
		}
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
	}
    }

    #
    # Delete the given items from the internal list
    #
    set data(itemList) [lreplace $data(itemList) $first $last]
    incr data(itemCount) -$count
    incr data(lastRow) -$count

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
    # Adjust the heights of the body text widget
    # and of the listbox child, if necessary
    #
    if {$data(-height) <= 0} {
	set nonHiddenRowCount [expr {$data(itemCount) - $data(hiddenRowCount)}]
	$w configure -height $nonHiddenRowCount
	$data(lb) configure -height $nonHiddenRowCount
    }

    #
    # Invalidate the list of the row indices indicating the
    # non-hidden rows, adjust the columns if necessary, and
    # schedule some operations for exection at idle time
    #
    set data(nonHiddenRowList) {-1}
    if {$colWidthsChanged} {
	adjustColumns $win allCols 1
    }
    adjustElidedTextWhenIdle $win
    makeStripesWhenIdle $win
    adjustSepsWhenIdle $win
    updateVScrlbarWhenIdle $win
    showLineNumbersWhenIdle $win

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
	incr data(activeRow) -$count
	adjustRowIndex $win data(activeRow) 1
    } elseif {$first <= $data(activeRow)} {
	set data(activeRow) $first
	adjustRowIndex $win data(activeRow) 1
    }

    #
    # Update data(editRow) if the edit window is present
    #
    if {$data(editRow) >= 0} {
	set data(editRow) [lsearch $data(itemList) "* $data(editKey)"]
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::deletecolumnsSubCmd
#
# This procedure is invoked to process the tablelist deletecolumns subcommand.
#------------------------------------------------------------------------------
proc tablelist::deletecolumnsSubCmd {win first last argCount} {
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled)} {
	return ""
    }

    if {$argCount == 1} {
	if {[llength $first] == 1} {			;# just to save time
	    set col [colIndex $win [lindex $first 0] 1]
	    set selCells [curcellselectionSubCmd $win]
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
	    # Traverse the sorted column index
	    # list and ignore any duplicates
	    #
	    set selCells [curcellselectionSubCmd $win]
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
	set last [colIndex $win $last 1]
	if {$first <= $last} {
	    set selCells [curcellselectionSubCmd $win]
	    deleteCols $win $first $last selCells
	    redisplay $win 0 $selCells
	}
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::deleteCols
#
# Deletes a given range of columns of a tablelist widget.
#------------------------------------------------------------------------------
proc tablelist::deleteCols {win first last selCellsName} {
    upvar ::tablelist::ns${win}::data data
    upvar $selCellsName selCells

    #
    # Delete the data corresponding to the given range
    #
    for {set col $first} {$col <= $last} {incr col} {
	if {$data($col-hide)} {
	    incr data(hiddenColCount) -1
	}
	deleteColData $win $col
	set selCells [deleteColFromCellList $selCells $col]
    }

    #
    # Shift the elements of data corresponding to the column
    # indices > last to the left by last - first + 1 positions
    #
    for {set oldCol [expr {$last + 1}]; set newCol $first} \
	{$oldCol < $data(colCount)} {incr oldCol; incr newCol} {
	moveColData $win data data imgs $oldCol $newCol
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
# tablelist::fillcolumnSubCmd
#
# This procedure is invoked to process the tablelist fillcolumn subcommand.
#------------------------------------------------------------------------------
proc tablelist::fillcolumnSubCmd {win colIdx text} {
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled)} {
	return ""
    }

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
    return ""
}

#------------------------------------------------------------------------------
# tablelist::getSubCmd
#
# This procedure is invoked to process the tablelist get subcommand.
#------------------------------------------------------------------------------
proc tablelist::getSubCmd {win first last argCount} {
    upvar ::tablelist::ns${win}::data data

    #
    # Get the specified items from the internal list
    #
    set result {}
    if {$argCount == 1} {
	foreach elem $first {
	    set index [rowIndex $win $elem 0]
	    if {$index >= 0 && $index < $data(itemCount)} {
		set item [lindex $data(itemList) $index]
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
	set last [rowIndex $win $last 0]

	#
	# Adjust the range to fit within the existing items
	#
	if {$first > $data(lastRow)} {
	    return {}
	}
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
#
# This procedure is invoked to process the tablelist getcells subcommand.
#------------------------------------------------------------------------------
proc tablelist::getcellsSubCmd {win first last argCount} {
    upvar ::tablelist::ns${win}::data data

    #
    # Get the specified elements from the internal list
    #
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
	foreach {lastRow lastCol} [cellIndex $win $last 1] {}

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
#
# This procedure is invoked to process the tablelist getcolumns subcommand.
#------------------------------------------------------------------------------
proc tablelist::getcolumnsSubCmd {win first last argCount} {
    upvar ::tablelist::ns${win}::data data

    #
    # Get the specified columns from the internal list
    #
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
	set last [colIndex $win $last 1]

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
# tablelist::getkeysSubCmd
#
# This procedure is invoked to process the tablelist getkeys subcommand.
#------------------------------------------------------------------------------
proc tablelist::getkeysSubCmd {win first last argCount} {
    upvar ::tablelist::ns${win}::data data

    #
    # Get the specified keys from the internal list
    #
    set result {}
    if {$argCount == 1} {
	foreach elem $first {
	    set index [rowIndex $win $elem 0]
	    if {$index >= 0 && $index < $data(itemCount)} {
		set item [lindex $data(itemList) $index]
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
	set last [rowIndex $win $last 0]

	#
	# Adjust the range to fit within the existing items
	#
	if {$first > $data(lastRow)} {
	    return {}
	}
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
# tablelist::insertSubCmd
#
# This procedure is invoked to process the tablelist insert and insertlist
# subcommands.
#------------------------------------------------------------------------------
proc tablelist::insertSubCmd {win index argList updateListVar} {
    variable snipSides
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled)} {
	return ""
    }

    set argCount [llength $argList]
    if {$argCount == 0} {
	return ""
    }

    if {$index < 0} {
	set index 0
    }

    #
    # Insert the items into the body text widget and into the internal list
    #
    variable canElide
    set w $data(body)
    set widgetFont $data(-font)
    set snipStr $data(-snipstring)
    set savedCount $data(itemCount)
    set appending [expr {$index >= $savedCount}]
    set colWidthsChanged 0
    set row $index
    set line [expr {$index + 1}]
    set hasFmtCmds [expr {[lsearch -exact $data(fmtCmdFlagList) 1] >= 0}]
    foreach item $argList {
	#
	# Adjust and format the item
	#
	set item [adjustItem $item $data(colCount)]
	if {$hasFmtCmds} {
	    set formattedItem [formatItem $win $item]
	} else {
	    set formattedItem $item
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

	set multilineData {}
	if {$data(itemCount) != 0} {
	     $w insert $line.0 "\n"
	}
	if {$data(hiddenRowCount) != 0} {
	    $w tag remove hiddenRow $line.0
	}

	set col 0
	if {$data(hasColTags)} {
	    set insertArgs {}
	    foreach text [strToDispStr $formattedItem] \
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
		if {[string match "*\n*" $text]} {
		    set multiline 1
		    set list [split $text "\n"]
		} else {
		    set multiline 0
		}
		if {$pixels == 0} {		;# convention: dynamic width
		    if {$multiline} {
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
			if {$textWidth > $data($col-reqPixels)} {
			    set data($col-reqPixels) $textWidth
			    if {$pixels == 0} {
				set colWidthsChanged 1
			    }
			}
		    }
		}
		if {$pixels != 0} {
		    incr pixels $data($col-delta)
		    set snipSide \
			$snipSides($alignment,$data($col-changesnipside))
		    if {$multiline} {
			set text [joinList $win $list $colFont \
				  $pixels $snipSide $snipStr]
		    } else {
			set text [strRange $win $text $colFont \
				  $pixels $snipSide $snipStr]
		    }
		}

		if {$multiline} {
		    lappend insertArgs "\t\t" $colTags
		    lappend multilineData $col $text $colFont $alignment
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
	    foreach text [strToDispStr $formattedItem] \
		    {pixels alignment} $data(colList) {
		if {$data($col-hide) && !$canElide} {
		    incr col
		    continue
		}

		#
		# Update the column width or clip the element if necessary
		#
		if {[string match "*\n*" $text]} {
		    set multiline 1
		    set list [split $text "\n"]
		} else {
		    set multiline 0
		}
		if {$pixels == 0} {		;# convention: dynamic width
		    if {$multiline} {
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
			if {$textWidth > $data($col-reqPixels)} {
			    set data($col-reqPixels) $textWidth
			    if {$pixels == 0} {
				set colWidthsChanged 1
			    }
			}
		    }
		}
		if {$pixels != 0} {
		    incr pixels $data($col-delta)
		    set snipSide \
			$snipSides($alignment,$data($col-changesnipside))
		    if {$multiline} {
			set text [joinList $win $list $widgetFont \
				  $pixels $snipSide $snipStr]
		    } else {
			set text [strRange $win $text $widgetFont \
				  $pixels $snipSide $snipStr]
		    }
		}

		if {$multiline} {
		    append insertStr "\t\t"
		    lappend multilineData $col $text $widgetFont $alignment
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
	foreach {col text font alignment} $multilineData {
	    findTabs $win $line $col $col tabIdx1 tabIdx2
	    set msgScript [list ::tablelist::displayText $win \
			   $key $col $text $font $alignment]
	    $w window create $tabIdx2 -pady 1 -create $msgScript
	}

	#
	# Insert the item into the list variable if needed
	#
	if {$updateListVar} {
	    upvar #0 $data(-listvariable) var
	    trace vdelete var wu $data(listVarTraceCmd)
	    if {$appending} {
		lappend var $item    		;# this works much faster
	    } else {
		set var [linsert $var $row $item]
	    }
	    trace variable var wu $data(listVarTraceCmd)
	}

	#
	# Insert the item into the internal list
	#
	lappend item $key
	if {$appending} {
	    lappend data(itemList) $item	;# this works much faster
	} else {
	    set data(itemList) [linsert $data(itemList) $row $item]
	}

	set row $line
	incr line
	incr data(itemCount)
    }
    set data(lastRow) [expr {$data(itemCount) - 1}]

    #
    # Adjust the heights of the body text widget
    # and of the listbox child, if necessary
    #
    if {$data(-height) <= 0} {
	set nonHiddenRowCount [expr {$data(itemCount) - $data(hiddenRowCount)}]
	$w configure -height $nonHiddenRowCount
	$data(lb) configure -height $nonHiddenRowCount
    }

    #
    # Adjust the horizontal view in the body text 
    # widget if the tablelist was previously empty
    #
    if {$savedCount == 0} {
	$w xview moveto [lindex [$data(hdrTxt) xview] 0]
    }

    #
    # Invalidate the list of the row indices indicating the
    # non-hidden rows, adjust the columns if necessary, and
    # schedule some operations for execution at idle time
    #
    set data(nonHiddenRowList) {-1}
    if {$colWidthsChanged} {
	adjustColumns $win {} 1
    }
    adjustElidedTextWhenIdle $win
    makeStripesWhenIdle $win
    adjustSepsWhenIdle $win
    updateVScrlbarWhenIdle $win
    showLineNumbersWhenIdle $win

    #
    # Update the indices anchorRow and activeRow
    #
    if {$index <= $data(anchorRow)} {
	incr data(anchorRow) $argCount
	adjustRowIndex $win data(anchorRow) 1
    }
    if {$index <= $data(activeRow)} {
	incr data(activeRow) $argCount
	adjustRowIndex $win data(activeRow) 1
    }

    #
    # Update data(editRow) if the edit window is present
    #
    if {$data(editRow) >= 0} {
	set data(editRow) [lsearch $data(itemList) "* $data(editKey)"]
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::insertcolumnsSubCmd
#
# This procedure is invoked to process the tablelist insertcolumns and
# insertcolumnlist subcommands.
#------------------------------------------------------------------------------
proc tablelist::insertcolumnsSubCmd {win colIdx argList} {
    variable alignments
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled)} {
	return ""
    }

    set argCount [llength $argList]
    if {$argCount == 0} {
	return ""
    }

    #
    # Check the syntax of argList and get the number of columns to be inserted
    #
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
	    if {[catch {format "%d" $next}] == 0} {	;# integer check
		incr n -1
	    } else {
		mwutil::fullOpt "alignment" $next $alignments
	    }
	}

	incr count
    }

    #
    # Shift the elements of data corresponding to the column
    # indices >= colIdx to the right by count positions
    #
    set selCells [curcellselectionSubCmd $win]
    for {set oldCol $data(lastCol); set newCol [expr {$oldCol + $count}]} \
	{$oldCol >= $colIdx} {incr oldCol -1; incr newCol -1} {
	moveColData $win data data imgs $oldCol $newCol
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
    # Reconfigure the relevant column labels
    #
    for {set col $limit} {$col < $data(colCount)} {incr col} {
	reconfigColLabels $win imgs $col
    }

    #
    # Redisplay the items
    #
    redisplay $win 0 $selCells

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

    return ""
}

#------------------------------------------------------------------------------
# tablelist::scanSubCmd
#
# This procedure is invoked to process the tablelist scan subcommand.
#------------------------------------------------------------------------------
proc tablelist::scanSubCmd {win opt x y} {
    upvar ::tablelist::ns${win}::data data

    set w $data(body)
    incr x -[winfo x $w]
    incr y -[winfo y $w]

    if {$data(-titlecolumns) == 0} {
	$w scan $opt $x $y
	$data(hdrTxt) scan $opt $x 0

	if {[string compare $opt "dragto"] == 0} {
	    adjustElidedText $win
	    updateColorsWhenIdle $win
	    adjustSepsWhenIdle $win
	    updateVScrlbarWhenIdle $win
	}
    } elseif {[string compare $opt "mark"] == 0} {
	$w scan mark 0 $y

	set data(scanMarkX) $x
	set data(scanMarkXOffset) \
	    [scrlColOffsetToXOffset $win $data(scrlColOffset)]
    } else {
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
	updateColorsWhenIdle $win
	adjustSepsWhenIdle $win
	updateVScrlbarWhenIdle $win
    }

    return ""
}

#------------------------------------------------------------------------------
# tablelist::seeSubCmd
#
# This procedure is invoked to process the tablelist see subcommand.
#------------------------------------------------------------------------------
proc tablelist::seeSubCmd {win index} {
    upvar ::tablelist::ns${win}::data data

    #
    # Adjust the index to fit within the existing items
    #
    adjustRowIndex $win index
    set key [lindex [lindex $data(itemList) $index] end]
    if {$data(itemCount) == 0 || [info exists data($key-hide)]} {
	return ""
    }

    #
    # Bring the given row into the window and restore
    # the horizontal view in the body text widget
    #
    $data(body) see [expr {double($index + 1)}]
    $data(body) xview moveto [lindex [$data(hdrTxt) xview] 0]

    adjustElidedText $win
    updateColorsWhenIdle $win
    adjustSepsWhenIdle $win
    updateVScrlbarWhenIdle $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::seecellSubCmd
#
# This procedure is invoked to process the tablelist seecell subcommand.
#------------------------------------------------------------------------------
proc tablelist::seecellSubCmd {win row col} {
    #
    # This might be an "after idle" callback; check whether the window exists
    #
    if {![winfo exists $win]} {
	return ""
    }

    upvar ::tablelist::ns${win}::data data
    set h $data(hdrTxt)
    set b $data(body)

    #
    # Adjust the row and column indices to fit within the existing elements
    #
    adjustRowIndex $win row
    adjustColIndex $win col
    set key [lindex [lindex $data(itemList) $row] end]
    if {[info exists data($key-hide)]} {
	return ""
    }
    if {$data(colCount) == 0} {
	$b see [expr {double($row + 1)}]
	return ""
    } elseif {$data($col-hide)} {
	return ""
    }

    #
    # Force any geometry manager calculations to be completed first
    #
    update idletasks

    #
    # If the tablelist is empty then insert a temporary row
    #
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
	set lX [winfo x $data(hdrTxtFrLbl)$col]
	set rX [expr {$lX + [winfo width $data(hdrTxtFrLbl)$col] - 1}]

	switch $alignment {
	    left {
		#
		# Bring the cell's left edge into view
		#
		$b see $tabIdx1
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
		$b see $tabIdx1
		set winWidth [winfo width $h]
		if {[winfo width $data(hdrTxtFrLbl)$col] > $winWidth} {
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
		$b see $nextIdx
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
	$b see [expr {double($row + 1)}]

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
	    adjustElidedText $win
	} elseif {$data($col-elide) ||
		  [winfo width $data(hdrTxtFrLbl)$col] > $scrlWindowWidth} {
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

    updateColorsWhenIdle $win
    adjustSepsWhenIdle $win
    updateVScrlbarWhenIdle $win
    return ""
}

#------------------------------------------------------------------------------
# tablelist::selectionSubCmd
#
# This procedure is invoked to process the tablelist selection subcommand.
#------------------------------------------------------------------------------
proc tablelist::selectionSubCmd {win opt first last} {
    upvar ::tablelist::ns${win}::data data

    if {$data(isDisabled) && [string compare $opt "includes"] != 0} {
	return ""
    }

    switch $opt {
	anchor {
	    #
	    # Adjust the index to fit within the existing non-hidden items
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

	    set firstTextIdx [expr {$first + 1}].0
	    set lastTextIdx [expr {$last + 1}].end

	    #
	    # Find the (partly) selected lines of the body text
	    # widget in the text range specified by the two indices
	    #
	    set w $data(body)
	    variable canElide
	    variable elide
	    set selRange [$w tag nextrange select $firstTextIdx $lastTextIdx]
	    while {[llength $selRange] != 0} {
		set selStart [lindex $selRange 0]

		$w tag remove select $selStart "$selStart lineend"

		#
		# Handle the -(select)background and -(select)foreground cell
		# and column configuration options for each element of the row
		#
		set row [expr {int($selStart) - 1}]
		set key [lindex [lindex $data(itemList) $row] end]
		set textIdx1 "$selStart linestart"
		for {set col 0} {$col < $data(colCount)} {incr col} {
		    if {$data($col-hide) && !$canElide} {
			continue
		    }

		    set textIdx2 [$w search $elide "\t" \
				  $textIdx1+1c "$selStart lineend"]+1c
		    foreach optTail {background foreground} {
			set opt -select$optTail
			foreach name  [list $col$opt $key$opt $key,$col$opt] \
				level [list col row cell] {
			    if {[info exists data($name)]} {
				$w tag remove $level$opt-$data($name) \
				       $textIdx1 $textIdx2
			    }
			}
			foreach name  [list $col-$optTail $key-$optTail \
				       $key,$col-$optTail] \
				level [list col row cell] {
			    if {[info exists data($name)]} {
				$w tag add $level-$optTail-$data($name) \
				       $textIdx1 $textIdx2
			    }
			}
		    }
		    set textIdx1 $textIdx2
		}

		set selRange \
		    [$w tag nextrange select "$selStart lineend" $lastTextIdx]
	    }

	    updateColorsWhenIdle $win
	    return ""
	}

	includes {
	    set w $data(body)
	    set textIdx [expr {double($first + 1)}]
	    set selRange [$w tag nextrange select $textIdx "$textIdx lineend"]
	    if {[llength $selRange] > 0} {
		return 1
	    } else {
		return 0
	    }
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
		# Check whether the row is selectable and non-hidden
		#
		set key [lindex [lindex $data(itemList) $row] end]
		if {[info exists data($key-selectable)] ||
		    [info exists data($key-hide)]} {
		    continue
		}

		#
		# Select the non-hidden elements of the row and handle
		# the -(select)background and -(select)foreground
		# cell and column configuration options for them
		#
		set textIdx1 $line.0
		for {set col 0} {$col < $data(colCount)} {incr col} {
		    if {$data($col-hide) && !$canElide} {
			continue
		    }

		    set textIdx2 \
			[$w search $elide "\t" $textIdx1+1c $line.end]+1c
		    if {$data($col-hide)} {
			set textIdx1 $textIdx2
			continue
		    }

		    $w tag add select $textIdx1 $textIdx2
		    foreach optTail {background foreground} {
			set opt -select$optTail
			foreach name  [list $col$opt $key$opt $key,$col$opt] \
				level [list col row cell] {
			    if {[info exists data($name)]} {
				$w tag add $level$opt-$data($name) \
				       $textIdx1 $textIdx2
			    }
			}
			foreach name  [list $col-$optTail $key-$optTail \
				       $key,$col-$optTail] \
				level [list col row cell] {
			    if {[info exists data($name)]} {
				$w tag remove $level-$optTail-$data($name) \
				       $textIdx1 $textIdx2
			    }
			}
		    }
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
# tablelist::togglecolumnhideSubCmd
#
# This procedure is invoked to process the tablelist togglecolumnhide
# subcommand.
#------------------------------------------------------------------------------
proc tablelist::togglecolumnhideSubCmd {win first last argCount} {
    variable canElide
    upvar ::tablelist::ns${win}::data data

    #
    # Toggle the value of the -hide option of the specified columns
    #
    if {!$canElide} {
	set selCells [curcellselectionSubCmd $win]
    }
    set colIdxList {}
    if {$argCount == 1} {
	foreach elem $first {
	    set col [colIndex $win $elem 1]
	    if {$canElide && !$data($col-hide)} {
		cellselectionSubCmd $win clear 0 $col $data(lastRow) $col
	    }
	    set data($col-hide) [expr {!$data($col-hide)}]
	    if {$data($col-hide)} {
		incr data(hiddenColCount)
		if {$col == $data(editCol)} {
		    canceleditingSubCmd $win
		}
	    } else {
		incr data(hiddenColCount) -1
	    }
	    lappend colIdxList $col
	}
    } else {
	set first [colIndex $win $first 1]
	set last [colIndex $win $last 1]

	for {set col $first} {$col <= $last} {incr col} {
	    if {$canElide && !$data($col-hide)} {
		cellselectionSubCmd $win clear 0 $col $data(lastRow) $col
	    }
	    set data($col-hide) [expr {!$data($col-hide)}]
	    if {$data($col-hide)} {
		incr data(hiddenColCount)
		if {$col == $data(editCol)} {
		    canceleditingSubCmd $win
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
    if {$canElide} {
	adjustElidedTextWhenIdle $win
    } else {
	redisplay $win 0 $selCells
    }
    if {[string compare $data(-selecttype) "row"] == 0} {
	foreach row [curselectionSubCmd $win] {
	    selectionSubCmd $win set $row $row
	}
    }
    return ""
}

#------------------------------------------------------------------------------
# tablelist::togglerowhideSubCmd
#
# This procedure is invoked to process the tablelist togglerowhide subcommand.
#------------------------------------------------------------------------------
proc tablelist::togglerowhideSubCmd {win first last argCount} {
    upvar ::tablelist::ns${win}::data data

    #
    # Toggle the value of the -hide option of the specified rows
    #
    if {$argCount == 1} {
	foreach elem $first {
	    set row [rowIndex $win $elem 0]
	    if {$row < 0 || $row > $data(lastRow)} {
		return -code error "row index \"$elem\" out of range"
	    }

	    doRowConfig $row $win -hide [expr {![doRowCget $row $win -hide]}]
	}
    } else {
	set firstRow [rowIndex $win $first 0]
	if {$firstRow < 0 || $firstRow > $data(lastRow)} {
	    return -code error "row index \"$first\" out of range"
	}

	set lastRow [rowIndex $win $last 0]
	if {$lastRow < 0 || $lastRow > $data(lastRow)} {
	    return -code error "row index \"$last\" out of range"
	}

	for {set row $firstRow} {$row <= $lastRow} {incr row} {
	    doRowConfig $row $win -hide [expr {![doRowCget $row $win -hide]}]
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::xviewSubCmd
#
# This procedure is invoked to process the tablelist xview subcommand.
#------------------------------------------------------------------------------
proc tablelist::xviewSubCmd {win argList} {
    variable winSys
    upvar ::tablelist::ns${win}::data data

    switch [llength $argList] {
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
	    } else {
		changeScrlColOffset $win $units
		updateColorsWhenIdle $win
	    }
	    return ""
	}

	default {
	    #
	    # Command: $win xview moveto <fraction>
	    #	       $win xview scroll <number> units|pages
	    #
	    set argList [mwutil::getScrollInfo $argList]
	    if {$data(-titlecolumns) == 0} {
		foreach w [list $data(hdrTxt) $data(body)] {
		    eval [list $w xview] $argList
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
		updateColorsWhenIdle $win
	    }
	    if {[string compare $winSys "aqua"] == 0 && [winfo viewable $win]} {
		#
		# Work around some Tk bugs on Mac OS X Aqua
		#
		if {[winfo exists $data(bodyFr)]} {
		    lower $data(bodyFr)
		    raise $data(bodyFr)
		}
		update 
	    }
	    return ""
	}
    }
}

#------------------------------------------------------------------------------
# tablelist::yviewSubCmd
#
# This procedure is invoked to process the tablelist yview subcommand.
#------------------------------------------------------------------------------
proc tablelist::yviewSubCmd {win argList} {
    variable winSys
    upvar ::tablelist::ns${win}::data data

    set w $data(body)
    set argCount [llength $argList]
    switch $argCount {
	0 {
	    #
	    # Command: $win yview
	    #
	    set totalNonHiddenCount \
		[expr {$data(itemCount) - $data(hiddenRowCount)}]
	    if {$totalNonHiddenCount == 0} {
		return [list 0 1]
	    }
	    set btmY [expr {[winfo height $w] - 1}]
	    set topTextIdx [$w index @0,0]
	    set btmTextIdx [$w index @0,$btmY]
	    set topRow [expr {int($topTextIdx) - 1}]
	    set btmRow [expr {int($btmTextIdx) - 1}]
	    foreach {x y width height baselinePos} [$w dlineinfo $btmTextIdx] {}
	    if {$y < 0} {				 ;# top row incomplete
		incr topRow
	    }
	    foreach {x y width height baselinePos} [$w dlineinfo $btmTextIdx] {}
	    set y2 [expr {$y + $height}]
	    if {[$w index @0,$y] == [$w index @0,$y2]} { ;# btm row incomplete
		incr btmRow -1
	    }
	    set upperNonHiddenCount \
		[getNonHiddenRowCount $win 0 [expr {$topRow - 1}]]
	    set winNonHiddenCount [getNonHiddenRowCount $win $topRow $btmRow]
	    set fraction1 [expr {$upperNonHiddenCount/
				 double($totalNonHiddenCount)}]
	    set fraction2 [expr {($upperNonHiddenCount + $winNonHiddenCount)/
				 double($totalNonHiddenCount)}]
	    return [list [format "%g" $fraction1] [format "%g" $fraction2]]
	}

	1 {
	    #
	    # Command: $win yview <units>
	    #
	    set units [format "%d" [lindex $argList 0]]
	    $w yview [nonHiddenRowOffsetToRowIndex $win $units]
	    adjustElidedText $win
	    updateColorsWhenIdle $win
	    adjustSepsWhenIdle $win
	    updateVScrlbarWhenIdle $win
	    return ""
	}

	default {
	    #
	    # Command: $win yview moveto <fraction>
	    #	       $win yview scroll <number> units|pages
	    #
	    set argList [mwutil::getScrollInfo $argList]
	    if {[string compare [lindex $argList 0] "moveto"] == 0} {
		set fraction [lindex $argList 1]
		set totalNonHiddenCount \
		    [expr {$data(itemCount) - $data(hiddenRowCount)}]
		set offset [expr {int($fraction*$totalNonHiddenCount + 0.5)}]
		$w yview [nonHiddenRowOffsetToRowIndex $win $offset]
	    } else {
		set number [lindex $argList 1]
		if {[string compare [lindex $argList 2] "units"] == 0} {
		    set topRow [expr {int([$w index @0,0]) - 1}]
		    set upperNonHiddenCount \
			[getNonHiddenRowCount $win 0 [expr {$topRow - 1}]]
		    set offset [expr {$upperNonHiddenCount + $number}]
		    $w yview [nonHiddenRowOffsetToRowIndex $win $offset]
		} else {
		    set absNumber [expr {abs($number)}]
		    set btmY [expr {[winfo height $w] - 1}]
		    for {set n 0} {$n < $absNumber} {incr n} {
			set topRow [expr {int([$w index @0,0]) - 1}]
			set btmRow [expr {int([$w index @0,$btmY]) - 1}]
			set upperNonHiddenCount \
			    [getNonHiddenRowCount $win 0 [expr {$topRow - 1}]]
			set winNonHiddenCount \
			    [getNonHiddenRowCount $win $topRow $btmRow]
			set delta [expr {$winNonHiddenCount - 2}]
			if {$number < 0} {
			    set delta [expr {(-1)*$delta}]
			}
			set offset [expr {$upperNonHiddenCount + $delta}]
			$w yview [nonHiddenRowOffsetToRowIndex $win $offset]
		    }
		}
	    }
	    adjustElidedText $win
	    updateColorsWhenIdle $win
	    adjustSepsWhenIdle $win
	    updateVScrlbarWhenIdle $win
	    if {[string compare $winSys "aqua"] == 0 && [winfo viewable $win]} {
		#
		# Work around some Tk bugs on Mac OS X Aqua
		#
		if {[winfo exists $data(bodyFr)]} {
		    lower $data(bodyFr)
		    raise $data(bodyFr)
		}
		update 
	    }
	    return ""
	}
    }
}

#
# Private callback procedures
# ===========================
#

#------------------------------------------------------------------------------
# tablelist::fetchSelection
#
# This procedure is invoked when the PRIMARY selection is owned by the
# tablelist widget win and someone attempts to retrieve it as a STRING.  It
# returns part or all of the selection, as given by offset and maxChars.  The
# string which is to be (partially) returned is built by joining all of the
# selected elements of the (partly) selected rows together with tabs and the
# rows themselves with newlines.
#------------------------------------------------------------------------------
proc tablelist::fetchSelection {win offset maxChars} {
    upvar ::tablelist::ns${win}::data data

    if {!$data(-exportselection)} {
	return ""
    }

    set selection ""
    set prevRow -1
    foreach cellIdx [curcellselectionSubCmd $win] {
	scan $cellIdx "%d,%d" row col
	if {$row != $prevRow} {
	    if {$prevRow != -1} {
		append selection "\n"
	    }

	    set prevRow $row
	    set item [lindex $data(itemList) $row]
	    set isFirstCol 1
	}

	set text [lindex $item $col]
	if {[info exists data($col-formatcommand)]} {
	    set text [uplevel #0 $data($col-formatcommand) [list $text]]
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
# the selectionSubCmd procedure if the selection is exported.
#------------------------------------------------------------------------------
proc tablelist::lostSelection win {
    upvar ::tablelist::ns${win}::data data

    if {$data(-exportselection)} {
	selectionSubCmd $win clear 0 $data(lastRow)
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
    upvar ::tablelist::ns${win}::data data

    set w $data(body)
    if {$data(ownsFocus)} {
	$w tag remove active 1.0 end

	set line [expr {$data(activeRow) + 1}]
	set col $data(activeCol)
	if {[string compare $data(-selecttype) "row"] == 0} {
	    $w tag add active $line.0 $line.end
	} elseif {$data(itemCount) > 0 && $data(colCount) > 0 &&
		  !$data($col-hide)} {
	    findTabs $win $line $data(activeCol) $data(activeCol) \
		     tabIdx1 tabIdx2
	    $w tag add active $tabIdx1 $tabIdx2+1c
	}
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
	    if {[string compare $index ""] != 0} {
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
#==============================================================================
# Tablelist and Tablelist_tile package index file.
#
# Copyright (c) 2000-2007  Csaba Nemethi (E-mail: csaba.nemethi@t-online.de)
#==============================================================================
package ifneeded Tablelist_tile    4.6 { package require tablelist_tile }
