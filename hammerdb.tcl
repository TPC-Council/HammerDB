#!/bin/sh
########################################################################
# \
export LD_LIBRARY_PATH=./lib:./lib64:$LD_LIBRARY_PATH
# \
export PATH=./bin:$PATH
# \
exec wish8.6 -file $0 ${1+"$@"}
# \
exit
########################################################################
# HammerDB
#
# Copyright (C) 2003-2015 Steve Shaw
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
# 
# You should have received a copy of the GNU General Public
# License along with this program; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA  02111-1307, USA.
#
# Author contact information: smshaw@users.sourceforge.net
######################################################################   
#This loader program loads the following components in order:
#hdb_logo.tcl	 - HammerDB Logo image
#hdb_theme.tcl	 - GUI Themes
#hdb_vu.tcl 	 - Virtual user TCL threads
#hdb_tpcc.tcl	 - TPC-C schema creation and driver
#hdb_tpch.tcl	 - TPC-H schema creation and driver
#hdb_modes.tcl   - Remote Modes and Autopilot
#hdb_tab.tcl 	 - Virtual user display tablelist
#hdb_cnv.tcl 	 - Tracefile to oratcl conversion
#hdb_tc.tcl 	 - Transaction counter
#hdb_im.tcl 	 - Image data
#hdb_ed.tcl 	 - Editor
#hdb_xml.tcl	 - XML Configuration
#hdb_metrics.tcl - Metrics
#hdb_go.tcl 	 - Run HammerDB
######################################################################
global hdb_version
set hdb_version "v2.18"
set mainGeometry +10+10
set UserDefaultDir [ file dirname [ info script ] ]
::tcl::tm::path add "$UserDefaultDir/hdb-modules"

namespace eval autostart {
    set autostartap "false"
    if {$argc == 0} { ; } else {
    if {$argc != 2 || [lindex $argv 0] != "auto" } {
puts {Usage: hammerdb.tcl [ auto [ script_to_autoload.tcl  ] ]}
exit
	} else {
        set autostartap "true"
        set autoloadscript [lindex $argv 1]
if { [ file exists $autoloadscript ] && [ file isfile $autoloadscript ] && [ file extension $autoloadscript ] eq ".tcl" } {
;# autostart selected and tcl file exists
	     } else {
puts {Usage: hammerdb.tcl [ auto [ script_to_autoload.tcl  ] ]}
exit
		}
        } 
   }
}

namespace eval LoadingProgressMeter {
    set max 14

    wm title            . "Loading HammerDB"
    wm protocol         . WM_DELETE_WINDOW {#Do nothing}
    wm overrideredirect . 1
    wm geometry         . +100+120
    wm transient	.
    tk appname "HammerDB Splash Screen"

      set logo_file hdb_logo.tcl
if [catch {source [ file join $UserDefaultDir hdb-components $logo_file ]}] {
                puts stderr "While loading image file\
                        \"$logo_file\"...\n$errorInfo"
        }

    set logim [ image create photo -height 120 -width 694 -data $logo ]

    set gbg white;
    set big   {Helvetica -24 {bold italic}}
    set mid   {Helvetica -18 {bold}} 
    set small {Helvetica -10} 
    set load  {Helvetica -12}

    . conf  -bg $gbg  -cursor watch
    set icont [ image create photo -height 120 -width 97 -data $icontrans ]
    wm iconphoto . -default $icont
    frame .progress -bg $gbg
  label .title -text " $hdb_version "  -font $mid \
            -bg $gbg  -fg #f99317  -padx 0
    label .progress.loadmsg  -textvariable loadtext \
            -anchor s  -bg $gbg  -font $load
    set disp_canv [ canvas .progress.canv -highlightthickness 0 -bg $gbg -height 120 -width 694 ]	
    $disp_canv create image 350 70 -image $logim

	pack $disp_canv 
	pack .progress.loadmsg

    scale .progress.bar  -from 0  -to 1  -label {}  -bd 0 \
            -orient horizontal  -length 20  -showvalue 0 \
            -background #003068  -troughcolor $gbg  -state normal \
            -tickinterval 0  -width 10  -takefocus 0  -cursor {} \
            -relief flat  -sliderrelief flat  -sliderlength 4
    .progress.bar set 0

    bindtags .progress.bar {. all}
    pack .progress.bar -fill x -expand 1

    grid .title   -          -padx 1.5m -pady 1m -sticky ew
    if [winfo exist .evalmsg] {grid .evalmsg  -columnspan 3}
    grid .progress  -sticky nsew

    variable count -1
    variable len 0
    proc updateprogress {args} {
        global loadtext
        variable count
        variable max

        incr count
        set width [winfo width .progress.bar]
        .progress.bar conf -sliderlength \
                [expr {int(($width-4)*$count/$max)+4}]
        if {$count%5 == 0} {
            update; 
        } else {
            update idletasks
        }
    }
    trace variable ::loadtext w [namespace code updateprogress]
    set ::loadtext ""

    namespace export check_progress_length
    proc check_progress_length {} {
        variable count
        variable max
        variable len
        if {$count!=$max} {
            puts stderr "[namespace current]::max not correctly\
                    adjusted - FIX to be [expr {$count-$len}]"
        }
        catch {unset loadtext}
    }
}
namespace import LoadingProgressMeter::*

if [info exist env(Load_List)] {
    foreach {sofile description} $env(Load_List) {
        set loadtext "Loading Object Code: $description"
        if [catch {load $sofile} s] {
            puts stderr "Failed to load $sofile\nPerhaps\
                    it should be built?\n$s"
            exit 1
        }
    }
}

append modulelist { Thread msgcat tablelist_tile tkcon xml ctext comm emu_graph socktest ttk_theme_black }

set loadtext "Loading hammerdb modules"
after 100
for { set modcount 0 } { $modcount < [llength $modulelist] } { incr modcount } {
    set m [lindex $modulelist $modcount]
		set loadtext $m
	if [catch { package require $m }] {
                puts stderr "While loading module\
                        \"$m\"...\n$errorInfo"
                exit 1
        }
    }

append loadlist { hdb_theme.tcl hdb_vu.tcl hdb_tpcc.tcl hdb_tpch.tcl hdb_modes.tcl hdb_tab.tcl hdb_cnv.tcl hdb_tc.tcl hdb_metrics.tcl hdb_im.tcl hdb_ed.tcl hdb_xml.tcl hdb_go.tcl }

set loadtext "Loading hammerdb components"
after 100
for { set loadcount 0 } { $loadcount < [llength $loadlist] } { incr loadcount } {
    set f [lindex $loadlist $loadcount]
		set loadtext $f
	if [catch {source [ file join $UserDefaultDir hdb-components $f ]}] {
                puts stderr "While loading component file\
                        \"$f\"...\n$errorInfo"
                exit 1
        }
    }
after 100
set loadtext "Starting HammerDB"
update
#pause to display splash screen
after 2000 
wm withdraw .
wm deiconify .ed_mainFrame
ed_edit
if { $autostart::autostartap == "true" } {
    ed_file_load
    start_autopilot
	}
tkwait window .ed_mainFrame
exit
