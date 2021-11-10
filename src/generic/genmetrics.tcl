proc ConfigureNetworkDisplay {agentid agenthostname} {
#set up port
if { [catch {::comm new DisplayMetrics -listen 1 -local 0 -silent "TRUE" -port {}} b] } {
puts "Creation of Port Failed : $b" 
} else {
set displayid [ DisplayMetrics self ]
set displayhost [ info hostname ]
puts "Metric receive port open @ $displayid on $displayhost"
DisplayMetrics hook lost {
if { [catch { DisplayMetrics destroy } b] } {
puts "Agent Connection lost but Failed to close network port : $b" 
		} else {
ed_kill_cpu_metrics
puts "Metrics Connection closed"
		}
    }
#Test Agent Port
namespace import socktest::*
puts "Connecting to HammerDB Agent @ $agenthostname:$agentid" 
puts -nonewline "Testing Agent Connectivity..."
set result [ sockmesg [ socktest $agenthostname $agentid 1000 ]]
#Test is OK so call agent to call back
if { $result eq "OK" } {
puts $result
puts "Metrics Connected"
if { [catch {::comm send -async "$agentid $agenthostname" "catch {Agent connect \"$displayid $displayhost\"} "} b] } {
puts "Connection to agent lost: $b"
catch { DisplayMetrics destroy }
	}
     } else {
puts $result
puts "Connection failed verify hostname and id @ $agenthostname:$agentid" 
DoDisplay 1 "AGENT CONNECTION FAILED" local
return
     } 
  }
}

proc DoDisplay {maxcpu cpu_model caller} {
global S CLR cputobars cputotxt cpucoords metframe win_scale_fact
set CLR(bg) black
set CLR(usr) green
set CLR(sys) red
set S(bar,width) [ expr {round((20/1.333333)*$win_scale_fact)} ]
set S(bar,height) [ expr {round((87/1.333333)*$win_scale_fact)} ]
set S(col,padding) [ expr {round((24/1.333333)*$win_scale_fact)} ]
set S(padding) [ expr {round((3/1.333333)*$win_scale_fact)} ]
set S(border) [ expr {round((5/1.333333)*$win_scale_fact)} ]
set S(mask) [ expr {round((4/1.333333)*$win_scale_fact)} ]
set S(maskplus) [ expr {round((1/1.333333)*$win_scale_fact)} ]
set S(widscl) [ expr {round((375/1.333333)*$win_scale_fact)} ]
set S(hdscl) [ expr {round((25/1.333333)*$win_scale_fact)} ]
set S(txtalign) [ expr {round((12/1.333333)*$win_scale_fact)} ]
set S(hdralign) [ expr {round((15/1.333333)*$win_scale_fact)} ]
#Remove descriptive name from CPU so does not overrun buffer
regsub -all {Platinum|Gold|Silver|Bronze} $cpu_model "" cpu_model
set cnvpth $metframe.f
foreach wind "$metframe.f $metframe.sv $cnvpth.c" {
catch { destroy $wind }
	}
set S(cpus) $maxcpu
set maxrows 8
if { $maxcpu <= 64 } { set maxrows 4 }
if { $maxcpu <= 48 } { set maxrows 3 }
if { $maxcpu <= 32 } { set maxrows 2 }
if { $maxcpu <= 16 } { set maxrows 1 }
    set maxperrow [ expr $maxcpu / $maxrows ]
    set cpuperrow [ expr round(ceil($maxperrow)) ]
    set rowdeduction 0
    set coladdition 0
    set newrow 0
    set width [expr {max($maxperrow * ($S(bar,width)+$S(padding)) + $S(padding),$S(widscl))}]
    set height [ expr {($S(bar,height)+$S(col,padding))*$maxrows} ]
    set scrollheight [ expr {$height*2} ]
    frame $metframe.f -bd $S(border) -relief flat -bg $CLR(bg)
if { $ttk::currentTheme eq "black" } {
	set cnv1 [ canvas $metframe.sv -width 11 -highlightthickness 0 -background #424242 ]
        } else {
	set cnv1 [ canvas $metframe.sv -width 11 -highlightthickness 0 -background #dcdad5 ]
        }
    pack $cnv1 -expand 0 -fill y -ipadx 0 -ipady 0 -padx 0 -pady 0 -side right
    pack $metframe.f -fill both -expand 1
#Create fixed header
    canvas $metframe.f.header -highlightthickness 0 -bd 0 -width $width -height $S(hdscl) -bg $CLR(bg)
    $metframe.f.header create text [ expr {$width/2 - $S(hdralign)} ] $S(txtalign) -text "$cpu_model ($maxcpu CPUs)" -fill $CLR(usr) -font {basic} -tags "cpumodel"
    pack $metframe.f.header
#Height for all objects is the height of the bar and text multiplied by all cpus add header
    set canvforbars $cnvpth.c 
    canvas $canvforbars -highlightthickness 0 -bd 0 -width $width -height $height -bg $CLR(bg) -scrollregion "0 0 $width $scrollheight" -yscrollcommand "$metframe.sv.scrollY set" -yscrollincrement 10
#Add scrollbar but now can't scroll multiple canvases or a frame so have to put all ojects in one canvas to scroll
    set scr1 [ ttk::scrollbar $metframe.sv.scrollY -orient vertical -command "$canvforbars yview" ]
    pack $canvforbars -expand 0 -fill y -ipadx 0 -ipady 0 -padx 0 -pady 0
    pack $scr1 -expand 1 -fill y -ipadx 0 -ipady 0 -padx 0 -pady 0 -side right
    set y1 $S(bar,height)
    set y0 0
    for {set cpu 0} {$cpu < $S(cpus)} {incr cpu} {
    set x0 [expr {$cpu * ($S(bar,width) + $S(padding)) + $S(padding)}]
    set x1 [expr {$x0 + $S(bar,width)}]
#Check is this is seconds row or higher to change coords
    if { $cpu > 0 && [ expr ($cpu) % $cpuperrow ] eq 0 } {
incr newrow
set rowdeduction [ expr $x0 - $S(padding) ]  
set coladdition [ expr {($S(col,padding) + $S(bar,height))*($newrow +1)-$S(col,padding)} ]
#Y coordinates stay fixed per row
   set y1 $coladdition
   set y0 [ expr {$y1 - $S(bar,height)} ]
	}
if { $newrow > 0 } {
#X coordinates change per CPU
   set x0 [ expr {$x0 - $rowdeduction} ]
   set x1 [expr {$x0 + $S(bar,width)}]
	}
#hold array of coords for each CPU for later update
set cpucoords($cpu) [ list $x0 $y0 $x1 $y1 ]
        $canvforbars create rect $x0 $y1 $x1 $y1 -tag bar$cpu-sys -fill $CLR(sys)
        $canvforbars create rect $x0 $y1 $x1 $y1 -tag bar$cpu-usr -fill $CLR(usr)
	for { set ymask $y0 } { $ymask <= $y1 } { incr ymask $S(mask) } {
        $canvforbars create rect $x0 $ymask $x1 [ expr $ymask + $S(maskplus) ] -tag bar$cpu-mask -fill $CLR(bg) -outline $CLR(bg)
	}
#Set CPU utilisation % value and hide with same as background colour
        $canvforbars create text  [ expr $x0 + $S(txtalign) ]  [ expr $y1 + $S(txtalign) ] -text "0%" -fill $CLR(bg) -font [ list basic [ expr [ font actual basic -size ] - 2 ] ]  -tags "pcent$cpu"
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
    global S cputobars cputotxt CLR cpucoords metframe
    set usrtag bar$cpu-usr
    set systag bar$cpu-sys
    set canvforbars $metframe.f.c
#Assign original coordinates for rectangle saved at first draw
    lassign $cpucoords($cpu) x0 y0 x1 y1
#Set new bar height - y coords goes down the canvas 
    set newYusr [expr {$y0+($::S(bar,height) - $::S(bar,height)*$usr/100)}]
    set newYsys [expr {$y0+($::S(bar,height) - $::S(bar,height)*$sys/100)}]
#Create User rectangle with new coordinates
    $canvforbars coords $usrtag $x0 $newYusr $x1 $y1
#Create Sys rectangle starting from top of usr up to max of top of bar
    $canvforbars coords $systag $x0 [ expr {$newYusr - ($y1 - $newYsys)} ] $x1 $newYusr
    $canvforbars delete pcent$cpu
    $canvforbars create text  [ expr $x0 + $S(txtalign) ] [ expr $y1 + $S(txtalign) ] -text "[ expr int($percent) ]%" -fill $CLR(usr) -font [ list basic [ expr [ font actual basic -size ] - 2 ] ] -tags "pcent$cpu"
	}

proc metrics {} {
  global rdbms
if { [catch {
  namespace import comm::*
  namespace import blt::*
  } message ] } {
puts "Metrics error loading comm and blt packages"
return
  }
  if { $rdbms eq "Oracle" } {
    namespace forget pgmet::*
    namespace import oramet::*
    orametrics
  } elseif { $rdbms eq "PostgreSQL" } {
    namespace forget oramet::*
    namespace import pgmet::*
    pgmetrics
  } else {
    genmetrics
  }
}

proc genmetrics {} {
global agent_hostname agent_id metframe
set metframe .ed_mainFrame.me
if {  [ info exists hostname ] } { ; } else { set hostname "localhost" }
if {  [ info exists id ] } { ; } else { set id 0 }
ed_stop_metrics
.ed_mainFrame.notebook tab .ed_mainFrame.me -state normal
.ed_mainFrame.notebook select .ed_mainFrame.me 
DoDisplay 1 "Connecting to Agent to Display CPU Metrics" local
if { [ interp exists metrics_interp ] } {
interp delete metrics_interp
	}
interp create metrics_interp
after 0 {interp eval {metrics_interp} [ConfigureNetworkDisplay $agent_id $agent_hostname]}
#Agent runs the Display from here so additional threads not required
return
	}

proc cpumetrics { previous } {
global agent_hostname agent_id metframe 
set metframe .ed_mainFrame.me.m.f.a.topdetails.output
if { [ interp exists metrics_interp ] } {
if { $previous eq "cpu" } {
interp delete metrics_interp
catch { DisplayMetrics destroy } 
if { [ winfo exists $metframe.f ] } {
catch {destroy $metframe.sv}
catch {destroy $metframe.f} 
return
	} 
} else {
if { [ winfo exists $metframe.f ] } {
pack $metframe.sv -anchor e -expand 0 -fill y -side right
pack $metframe.f -fill both -expand 1 -anchor w
return
}}
}
if { [ winfo exists $metframe.f ] } {
pack $metframe.sv -anchor e -expand 0 -fill y -side right
pack $metframe.f -fill both -expand 1 -anchor w
return
	} else {
if {  [ info exists hostname ] } { ; } else { set hostname "localhost" }
if {  [ info exists id ] } { ; } else { set id 0 }
DoDisplay 1 "Connecting to Agent to Display CPU Metrics" local
if { [ interp exists metrics_interp ] } {
interp delete metrics_interp
	}
interp create metrics_interp
after 0 {interp eval {metrics_interp} [ConfigureNetworkDisplay $agent_id $agent_hostname]}
#Agent runs the Display from here so additional threads not required
return
		}
	}

proc ed_kill_metrics {args} {
   global _ED rdbms 
if { $rdbms == "Oracle" } {
	post_kill_dbmon_cleanup 
	} elseif { $rdbms == "PostgreSQL" } {
	pg_post_kill_dbmon_cleanup 
	}
   ed_status_message -show "... Stopping Metrics ..."
   ed_metrics_button
if { [ interp exists metrics_interp ] } {
interp delete metrics_interp
	}
catch { DisplayMetrics destroy } 
if ![ string match "*.ed_mainFrame.me*" [ .ed_mainFrame.notebook tabs ]] {
#transaction counter has been detached so reattach before disabling
Attach .ed_mainFrame.notebook .ed_mainFrame.me 3
}
.ed_mainFrame.notebook tab .ed_mainFrame.me -state disabled
ed_status_message -finish "Metrics Stopped"
   update
}

proc ed_kill_cpu_metrics {args} {
   global _ED rdbms 
if { $rdbms == "Oracle" } { 
if { [ interp exists metrics_interp ] } {
interp delete metrics_interp
	}
catch { DisplayMetrics destroy } 
} else {
   ed_status_message -show "... Stopping Metrics ..."
   ed_metrics_button
if { [ interp exists metrics_interp ] } {
interp delete metrics_interp
	}
catch { DisplayMetrics destroy } 
if ![ string match "*.ed_mainFrame.me*" [ .ed_mainFrame.notebook tabs ]] {
#transaction counter has been detached so reattach before disabling
Attach .ed_mainFrame.notebook .ed_mainFrame.me 3
}
.ed_mainFrame.notebook tab .ed_mainFrame.me -state disabled
ed_status_message -finish "Metrics Stopped"
   update
	}
}
