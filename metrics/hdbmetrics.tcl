#!/bin/sh
########################################################################
# \
export LD_LIBRARY_PATH=.././lib:.././lib64:$LD_LIBRARY_PATH
# \
export PATH=.././bin:$PATH
# \
exec .././bin/wish8.6 -file $0 ${1+"$@"}
# \
exit
########################################################################
# HammerDB Metrics
#
# Adpated from http://wiki.tcl.tk/37820
# mpstatPlot -- visual display of mpstat idle value for all processors
# by Keith Vetter
#
# Copyright (C) 2003-2014 Steve Shaw
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
set version 2.16
if {$tcl_platform(platform) == "windows"} { 
ttk::setTheme xpnative 
} else {
ttk::setTheme clam
}
font create smallfont -family  SansSerif -size -8 
option add *font smallfont
font create mydefaultfont -family Helvetica -size 10 
option add *font mydefaultfont
#load files
puts "Initializing HammerDB Metric Display $version"
set UserDefaultDir [ file dirname [ info script ] ]
append loadlist { hdb_logo.tcl hdb_comm.tcl }
for { set loadcount 0 } { $loadcount < [llength $loadlist] } { incr loadcount } {
    set f [lindex $loadlist $loadcount]
	if [catch {source [ file join $UserDefaultDir ../hdb-components $f ]}] {
                puts stderr "While loading component file\
                        \"$f\"...\n$errorInfo"
        }
    }
set icont [ image create photo -height 120 -width 97 -data $icontrans ]
wm title     . "HammerDB Metrics"
wm iconphoto . -default $icont
#Change Colours of background, user time and text and system time
set CLR(bg) black
set CLR(usr) green
set CLR(sys) red
#
ttk::style configure TMenubutton -background $CLR(usr) -foreground $CLR(bg) -borderwidth 0 -font {mydefaultfont}
ttk::style map TMenubutton -background [ list active $CLR(usr) ]
ttk::style map TMenubutton -foreground [ list active $CLR(bg) ]
#
set S(bar,width) 20
set S(bar,height) 87
set S(padding) 3
set S(border) 5

proc construct_menu {Name label cmd_list} {
   global CLR
   set menucount 0
   ttk::menubutton $Name -text $label -underline 0 -width [ string length $label ]
   set newmenu $Name.[ incr menucount ]
   $Name configure -menu $newmenu
   catch "destroy $newmenu"
   eval "menu $newmenu"
   eval [list add_items_to_menu $newmenu $cmd_list]
   $newmenu configure -background $CLR(usr) -foreground $CLR(bg) -borderwidth 0
   pack $Name -side left -anchor w
  }

proc add_items_to_menu {menubutton cmdList} {
global CLR
  foreach cmd $cmdList {
    switch [lindex $cmd 0] {
      "separator" {
         set doit "$menubutton add separator [lindex $cmd 2]"
         eval $doit
         }
      "tearoff"  {
         if {[string match [lindex $cmd 2] "no"]} {
           $menubutton configure -tearoff no
           }
         }
        "radio" {
 set doit "$menubutton add radio -label {[lindex $cmd 1]} \
             -variable [lindex $cmd 2] -value on"
         eval $doit
           }
      "command"  {
         set doit "$menubutton add [lindex $cmd 0] -background $CLR(usr) -activebackground $CLR(bg) -foreground $CLR(bg) -activeforeground $CLR(usr) -font {mydefaultfont} -label {[lindex $cmd 1]} [lindex $cmd 2]"
         eval $doit
         }
      }
    }
  }

proc close_display {} {
::comm destroy;
exit
	}

proc conn_to_agent {} {
if {  [ info exists hostname ] } { ; } else { set hostname "localhost" }
if {  [ info exists id ] } { ; } else { set id 0 }
   catch "destroy .mode"
   toplevel .mode
   wm withdraw .mode
   wm title .mode {Connect to Agent Options}
   set Parent .mode
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5                                                                           
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Agent ID and Hostname"
grid $Prompt -column 1 -row 0 -sticky w

   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Agent ID :"
   ttk::entry $Name -width 30 -textvariable id
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Agent Hostname :"
   ttk::entry $Name -width 30 -textvariable hostname
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5
   set Name $Parent.b4
   ttk::button $Name -command {destroy .mode} -text Cancel
   pack $Name -anchor w -side right -padx 3 -pady 3
   set Name $Parent.b5
   ttk::button $Name -command {
         set id [.mode.f1.e1 get]
         set hostname [.mode.f1.e2 get]
	 catch "destroy .mode"
 if {[ tk_messageBox -icon question -title "Confirm Connection" -message "Connect to Agent ID $id\nat Hostname $hostname?" -type yesno ] == yes} { 
ConfigureNetworkDisplay $id $hostname 
		}  else { ; } 
        } -text {OK}     
   pack $Name -anchor w -side right -padx 3 -pady 3
   wm geometry .mode +50+50
   wm deiconify .mode
   raise .mode
   update
}

proc ConfigureNetworkDisplay {agentid agenthostname} {
set chanlist [ lindex [ ::comm channels ] end ]
if { [catch {::comm new DisplaySide -listen 1 -local 0 -port {}} b] } {
puts "Creation Failed : $b" 
} else {
puts "HammerDB Metric Display active"
puts -nonewline "Connecting to HammerDB Metric Agent from Display @ "
update idletasks
DisplaySide hook lost {
if { [ llength [ ::comm interps ]] > 1 } {
if { [catch { DisplaySide destroy } b] } {
;
} 
		}
    }
set displayid [ DisplaySide self ]
set displayhost [ info hostname ]
puts "$displayid $displayhost"
puts -nonewline "HammerDB Agent @ $agentid $agenthostname "
if { [catch {::comm connect "$agentid $agenthostname"} b] } {
puts "Connection Failed : $b"
catch { DisplaySide destroy }
} else {
puts "Connection suceeded"
if { [catch {::comm send "$agentid $agenthostname" "catch {Agent connect \"$displayid $displayhost\"} "} b] } {
puts "Connection to agent lost: $b"
puts "Exited HammerDB Metric Display"
exit
} else {
puts "Connection maintained"
			}
		}
	}
}

proc DoDisplay {maxcpu cpu_model caller} {
    global S CLR cputobars cputotxt
foreach wind {.f .menu .header .c .d .e .g .h .i .j .k .l .m .n .o .p .q .r .s .t .u .v .w .x .y .z} {
catch { destroy $wind }
	}
set S(cpus) $maxcpu
set maxrows 4
if { $maxcpu <= 48 } { set maxrows 3 }
if { $maxcpu <= 32 } { set maxrows 2 }
if { $maxcpu <= 16 } { set maxrows 1 }
    set maxperrow [ expr $maxcpu / $maxrows ]
    set cpuperrow [ expr $maxcpu / $maxperrow ]
    set newrow 0
    set width [expr {max($maxperrow * ($S(bar,width)+$S(padding)) + $S(padding),375)}]
    set height [expr {$S(bar,height)}]

    frame .f -bd $S(border) -relief flat -bg $CLR(bg)
    set canvidx 0
    set canvlist {.c .d .e .g .h .i .j .k .l .m .n .o .p .q .r .s .t .u .v .w .x .y .z}
    set canvforbars [ lindex $canvlist $canvidx ] 
    set canvfortxt [ lindex $canvlist $canvidx+1 ] 
    canvas .menu -highlightthickness 0 -bd 0 -width $width -height 25 -bg $CLR(bg)
    canvas .header -highlightthickness 0 -bd 0 -width $width -height 25 -bg $CLR(bg)
    .header create text 180 12 -text "$cpu_model ($maxcpu CPUs)" -fill $CLR(usr) -font {mydefaultfont} -tags "cpumodel"
    canvas $canvforbars -highlightthickness 0 -bd 0 -width $width -height $height -bg $CLR(bg)
    canvas $canvfortxt -highlightthickness 0 -bd 0 -width $width -height 20 -bg $CLR(bg)
    pack .f
    pack .menu -in .f -fill x -expand 1
    pack .header -in .f 
    pack $canvforbars -in .f
    pack $canvfortxt -in .f
    
    bind . <Button-3> exit
    bind . <Control-Button-1> Hide

    set Name .menu.metricmenu

   set Menu_string($Name) {
    {{command} {Connect to Agent}  {-command conn_to_agent -underline 0}}
    {{separator} {} {}}
    {{command} {Exit} {-command close_display -underline 0}}
    }

    construct_menu $Name Options $Menu_string($Name)

	if { $caller eq "agent" } {
#Now made a connection and agent has setup display so disable menu to connect
	$Name.1 entryconfigure 1 -state disabled
	} else {
#No connection yet so enable menu to connect
	$Name.1 entryconfigure 1 -state normal
	}

    for {set cpu 0} {$cpu < $S(cpus)} {incr cpu} {
    set x0 [expr {$cpu * ($S(bar,width) + $S(padding)) + $S(padding)}]
    if { ($canvidx eq 0) && ($cpu < $maxperrow)} {
    set barlocation($cpu) $x0
	} 
    set x1 [expr {$x0 + $S(bar,width)}]
    set cputobars($cpu) $canvforbars
    set cputotxt($cpu) $canvfortxt
    if { $cpu > 0 && [ expr $cpu % $maxperrow ] eq 0 } {
    set newrow 0
    incr canvidx 2
    set canvforbars [ lindex $canvlist $canvidx ] 
    set canvfortxt [ lindex $canvlist $canvidx+1 ] 
    set cputobars($cpu) $canvforbars
    set cputotxt($cpu) $canvfortxt
    canvas $canvforbars -highlightthickness 0 -bd 0 -width $width -height $height -bg $CLR(bg)
    canvas $canvfortxt -highlightthickness 0 -bd 0 -width $width -height 25 -bg $CLR(bg)
    pack $canvforbars -in .f
    pack $canvfortxt -in .f
	}
if { $canvidx > 0 } {
   set x0 $barlocation($newrow)   
    set x1 [expr {$x0 + $S(bar,width)}]
   incr newrow
}
        set y0 $S(bar,height)
        set y1 0
        $canvforbars create rect $x0 $y0 $x1 $y1 -tag bar$cpu-sys -fill $CLR(sys)
        $canvforbars create rect $x0 $y0 $x1 $y1 -tag bar$cpu-usr -fill $CLR(usr)
	for { set ymask 3 } { $ymask <= 100 } { incr ymask 4 } {
        $canvforbars create rect $x0 $ymask $x1 [ expr $ymask + 1 ] -tag bar$cpu-mask -fill $CLR(bg) -outline $CLR(bg)
	}
        $canvfortxt create text  [ expr $x0 + 12 ] 10 -text "100%" -fill $CLR(usr) -font {smallfont} -tags "pcent$cpu"
    }
}

proc StatsOneLine {line} {
#Called by agent remotely
#Different formats some include AMPM some don't
if { [ llength $line ] eq 12 } {
lassign $line when ampm cpu usr nice sys iowait irq soft steal guest idle
	} else {
if { [ llength $line ] eq 11 } {
    lassign $line when cpu usr nice sys iowait irq soft steal guest idle
	} else {
puts "CPU Metrics error: expecting 11 or 12 columns in mpstat data but got [ llength $line ]"
set cpu 0
	}
   }
    if {[string is integer -strict $cpu]} {
 catch { AdjustBarHeight $cpu $usr $sys [ expr $usr + $sys ] }
    } else {
    if {[string is double -strict $cpu]} {
 catch { AdjustBarHeight [expr int($cpu)] [expr int($usr)] [expr int($sys)] [expr int($usr + $sys)] }
		}
	}
}

proc AdjustBarHeight {cpu usr sys percent} {
    global cputobars cputotxt CLR
    set usrtag bar$cpu-usr
    set systag bar$cpu-sys
    set canvforbars $cputobars($cpu)
    set canvfortxt $cputotxt($cpu)
    lassign [$canvforbars coords $usrtag] x0 y0 x1 y1
    set newYusr [expr {$::S(bar,height) - $::S(bar,height)*$usr/100}]
    set newYsys [expr {$::S(bar,height) - $::S(bar,height)*$sys/100}]
    $canvforbars coords $usrtag $x0 $newYusr $x1 $y1
    $canvforbars coords $systag $x0 [ expr $::S(bar,height) - (($::S(bar,height) - $newYsys) + ($::S(bar,height) - $newYusr)) ] $x1 $newYusr
    $canvfortxt delete pcent$cpu
    $canvfortxt create text  [ expr $x0 + 12 ] 10 -text "[ expr int($percent) ]%" -fill $CLR(usr) -font {smallfont} -tags "pcent$cpu"
}

proc Hide {} {
    wm withdraw .
    after 1000 wm deiconify .
}
DoDisplay 1 "Connect to Agent to Display CPU Metrics" local
AdjustBarHeight 0 0 0 0
#Agent runs the Display from here
update
return
