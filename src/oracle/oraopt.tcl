#Configure transaction counter options
proc countoraopts { bm } {
upvar #0 icons icons
upvar #0 configoracle configoracle
upvar #0 genericdict genericdict
global afval interval tclog uniquelog tcstamp
dict with genericdict { dict with transaction_counter {   
#variables for button options need to be global
set interval $tc_refresh_rate
set tclog $tc_log_to_temp
set uniquelog $tc_unique_log_name
set tcstamp $tc_log_timestamps
}}
setlocaltcountvars $configoracle 1
variable tpcc_tt_compat tpch_tt_compat
if {[dict exists $configoracle tpcc tpcc_tt_compat ]} {
set tpcc_tt_compat [ dict get $configoracle tpcc tpcc_tt_compat ]
	} else { set tpcc_tt_compat "false" }
if {[dict exists $configoracle tpch tpch_tt_compat ]} {
set tpch_tt_compat [ dict get $configoracle tpch tpch_tt_compat ]
	} else { set tpch_tt_compat "false" }
if {[dict exists $genericdict transaction_counter tc_refresh_rate]} {
set interval [ dict get $genericdict transaction_counter tc_refresh_rate ]
	} else { set interval 10 }

variable oraoptsfields
if { $bm eq "TPC-C" } { 
set bm_for_count "tpcc_tt_compat" 
set oraoptsfields [ dict create connection {system_user {.countopt.f1.e2 get} system_password {.countopt.f1.e3 get} instance {.countopt.f1.e1 get} rac $rac} tpcc {tpcc_tt_compat $tpcc_tt_compat} ]
} else { 
set bm_for_count "tpch_tt_compat" 
set oraoptsfields [ dict create connection {system_user {.countopt.f1.e2 get} system_password {.countopt.f1.e3 get} instance {.countopt.f1.e1 get} rac $rac} tpch {tpch_tt_compat $tpch_tt_compat} ]
}

if { [ info exists afval ] } {
	after cancel $afval
	unset afval
}
   catch "destroy .countopt"
   ttk::toplevel .countopt
   wm transient .countopt .ed_mainFrame
   wm withdraw .countopt
   wm title .countopt {Oracle TX Counter Options}

   set Parent .countopt

   set Name $Parent.f1
   ttk::frame $Name 
   pack $Name -anchor nw -fill x -side top -padx 5

set Prompt $Parent.f1.h1
ttk::label $Prompt -image [ create_image pencil icons ]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Transaction Counter Options"
grid $Prompt -column 1 -row 0 -sticky w

   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Oracle Service Name :"
   ttk::entry $Name -width 30 -textvariable instance
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "System User :"   
   ttk::entry $Name  -width 30 -textvariable system_user
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
   set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "System User Password :"   
   ttk::entry $Name  -width 30 -textvariable system_password
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
   set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "Refresh Rate(secs) :"
   ttk::entry $Name -width 30 -textvariable interval
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4

   set Name $Parent.f1.e5
ttk::checkbutton $Name -text "TimesTen Database Compatible" -variable $bm_for_count -onvalue "true" -offvalue "false"
   grid $Name -column 1 -row 5 -sticky w
bind .countopt.f1.e5 <Any-ButtonRelease> {
if { $bm eq "TPC-C" && $tpcc_tt_compat eq "false" || $bm eq "TPC-H" && $tpch_tt_compat eq "false" } {
set rac 0
.countopt.f1.e6 configure -state disabled
		} else {
.countopt.f1.e6 configure -state normal
		}
	}

   set Name $Parent.f1.e6
ttk::checkbutton $Name -text "RAC Global Transactions" -variable rac -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 6 -sticky w
if { $bm eq "TPC-C" && $tpcc_tt_compat eq "true" || $bm eq "TPC-H" && $tpch_tt_compat eq "true" } {
	$Name configure -state disabled
	}

  set Name $Parent.f1.e7
ttk::checkbutton $Name -text "Log Output to Temp" -variable tclog -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 7 -sticky w
bind .countopt.f1.e7 <Button> {
set opst [ .countopt.f1.e7 cget -state ]
if {$opst != "disabled" && $tclog == 0} {
.countopt.f1.e8 configure -state active
.countopt.f1.e9 configure -state active
        } else {
set uniquelog 0
set tcstamp 0
.countopt.f1.e8 configure -state disabled
.countopt.f1.e9 configure -state disabled
                        }
                }
  set Name $Parent.f1.e8
ttk::checkbutton $Name -text "Use Unique Log Name" -variable uniquelog -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 8 -sticky w
        if {$tclog == 0} {
        $Name configure -state disabled
        }

   set Name $Parent.f1.e9
ttk::checkbutton $Name -text "Log Timestamps" -variable tcstamp -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 9 -sticky w
        if {$tclog == 0} {
        $Name configure -state disabled
        }

   bind .countopt.f1.e1 <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }

 set Name $Parent.b2
 ttk::button $Name  -command {
unset oraoptsfields
destroy .countopt
} -text Cancel
 pack $Name -anchor nw -side right -padx 3 -pady 3

 set Name $Parent.b1
   ttk::button $Name -command {
if { $bm eq "TPC-C" } { 
copyfieldstoconfig configoracle [ subst $oraoptsfields ] tpcc
} else { 
copyfieldstoconfig configoracle [ subst $oraoptsfields ] tpch
}
unset oraoptsfields
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs" 
	dict set genericdict transaction_counter tc_refresh_rate 10
	   } else {
	dict with genericdict { dict with transaction_counter {
	set tc_refresh_rate [.countopt.f1.e4 get]
       	set tc_log_to_temp $tclog
        set tc_unique_log_name $uniquelog
        set tc_log_timestamps $tcstamp 
	}}
	}
         destroy .countopt
	   catch "destroy .tc"
            } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3

   wm geometry .countopt +50+50
   wm deiconify .countopt
   raise .countopt
   update
}

#Configure TPC-C Options
proc configoratpcc {option} {
upvar #0 icons icons
upvar #0 configoracle configoracle
#set variables to values in dict
setlocaltpccvars $configoracle
#set matching fields in dialog to temporary dict
variable orafields
set orafields [ dict create connection {system_user {.tpc.f1.e2 get} system_password {.tpc.f1.e3 get} instance {.tpc.f1.e1 get}} tpcc {tpcc_user {.tpc.f1.e4 get} tpcc_pass {.tpc.f1.e5 get} tpcc_def_tab {.tpc.f1.e6 get} tpcc_ol_tab {.tpc.f1.e6a get} tpcc_def_temp {.tpc.f1.e7 get} total_iterations {.tpc.f1.e17 get} rampup {.tpc.f1.e21 get} duration {.tpc.f1.e22 get} async_client {.tpc.f1.e26 get} async_delay {.tpc.f1.e27 get} tpcc_tt_compat $tpcc_tt_compat hash_clusters $hash_clusters partition $partition count_ware $count_ware num_vu $num_vu ora_driver $ora_driver raiseerror $raiseerror keyandthink $keyandthink checkpoint $checkpoint allwarehouse $allwarehouse ora_timeprofile $ora_timeprofile async_scale $async_scale async_verbose $async_verbose connect_pool $connect_pool}]
set whlist [ get_warehouse_list_for_spinbox ]
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm transient .tpc .ed_mainFrame
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {Oracle TPROC-C Schema Options} }
"build" { wm title .tpc {Oracle TPROC-C Build Options} }
"drive" {  wm title .tpc {Oracle TPROC-C Driver Options} }
	}
   set Parent .tpc
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5  
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [ create_image boxes icons ]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [ create_image driveroptlo icons ]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Oracle Service Name :"
   ttk::entry $Name -width 30 -textvariable instance
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "System User :"   
   ttk::entry $Name  -width 30 -textvariable system_user
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
   set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "System User Password :"   
   ttk::entry $Name  -width 30 -textvariable system_password
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "TPROC-C User :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name  -width 30 -textvariable tpcc_user
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "TPROC-C User Password :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name  -width 30 -textvariable tpcc_pass
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "TPROC-C Default Tablespace :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable tpcc_def_tab
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Name $Parent.f1.e6a
   set Prompt $Parent.f1.p6a
   ttk::label $Prompt -text "TPROC-C Order Line Tablespace :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable tpcc_ol_tab
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7
   ttk::label $Prompt -text "TPROC-C Temporary Tablespace :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable tpcc_def_temp
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky ew
	}
   set Prompt $Parent.f1.p8
ttk::label $Prompt -text "TimesTen Database Compatible :"
   set Name $Parent.f1.e8
ttk::checkbutton $Name -text "" -variable tpcc_tt_compat -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 9 -sticky e
   grid $Name -column 1 -row 9 -sticky w
if { $tpcc_tt_compat eq "false" } {
foreach field {e2 e3 e6 e7} {
catch {.tpc.f1.$field configure -state normal}
		}
if { $partition eq "true" } {
catch {.tpc.f1.e6a configure -state normal}
catch {.tpc.f1.e9a configure -state normal}
	}
   } else {
set hash_clusters "false"
foreach field {e2 e3 e6 e6a e7} {
catch {.tpc.f1.$field configure -state disabled}
	}
	}
bind .tpc.f1.e8 <ButtonPress-1> {
if { $tpcc_tt_compat eq "true" } {
foreach field {e2 e3 e6 e7} {
catch {.tpc.f1.$field configure -state normal}
	}
if { $partition eq "true" } {
catch {.tpc.f1.e6a configure -state normal}
.tpc.f1.e9a configure -state normal
	} else {
catch {.tpc.f1.e9a configure -state disabled}
set hash_clusters "false"
	}
if {$count_ware < 200 } {
catch {.tpc.f1.e9 configure -state disabled}
catch {.tpc.f1.e6a configure -state disabled}
catch {.tpc.f1.e9a configure -state disabled}
set partition "false"
set hash_clusters "false"
	}
	} else {
set hash_clusters "false"
foreach field {e2 e3 e6 e6a e7 e9a} {
catch {.tpc.f1.$field configure -state disabled}
   	}
if {$count_ware >= 200 } {
catch {.tpc.f1.e9 configure -state normal}
	}
    }   
}
if { $option eq "all" || $option eq "build" } {
 set Prompt $Parent.f1.p9a
ttk::label $Prompt -text "Use Hash Clusters :"
  set Name $Parent.f1.e9a
ttk::checkbutton $Name -text "" -variable hash_clusters -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
 set Prompt $Parent.f1.p9
ttk::label $Prompt -text "Partition Tables :"
  set Name $Parent.f1.e9
ttk::checkbutton $Name -text "" -variable partition -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 11 -sticky e
   grid $Name -column 1 -row 11 -sticky w
if {$count_ware < 200 && $tpcc_tt_compat eq "false" } {
	set partition false
	$Name configure -state disabled
	.tpc.f1.e6a configure -state disabled
	.tpc.f1.e9a configure -state disabled
	}
if { $partition eq "false" } {
	set hash_clusters false
	.tpc.f1.e6a configure -state disabled
	.tpc.f1.e9a configure -state disabled
	}
bind .tpc.f1.e9 <Any-ButtonRelease> {
set hash_clusters false
.tpc.f1.e9a configure -state disabled
if { $partition eq "true" && $tpcc_tt_compat eq "false" } {
.tpc.f1.e6a configure -state disabled
.tpc.f1.e9a configure -state disabled
			} else {
if { $partition eq "false" && $count_ware >= 200 && $tpcc_tt_compat eq "false" } {
.tpc.f1.e6a configure -state normal
.tpc.f1.e9a configure -state normal
			}
			}
	}
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e10
ttk::spinbox $Name -value $whlist -textvariable count_ware
bind .tpc.f1.e10 <<Any-Button-Any-Key>> {
if {$num_vu > $count_ware} {
set num_vu $count_ware
	}
if {$count_ware < 200 && $tpcc_tt_compat eq "false" } {
.tpc.f1.e9 configure -state disabled
.tpc.f1.e9a configure -state disabled
.tpc.f1.e6a configure -state disabled
set partition "false"
set hash_clusters "false"
	} else {
.tpc.f1.e9 configure -state enabled
	}
}
	grid $Prompt -column 0 -row 12 -sticky e
	grid $Name -column 1 -row 12 -sticky ew
set Prompt $Parent.f1.p11
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e11
ttk::spinbox $Name -from 1 -to 512 -textvariable num_vu
bind .tpc.f1.e11 <<Any-Button-Any-Key>> {
if {$num_vu > $count_ware} {
set num_vu $count_ware
		}
	}
event add <<Any-Button-Any-Key>> <Any-ButtonRelease>
event add <<Any-Button-Any-Key>> <KeyRelease>
grid $Prompt -column 0 -row 13 -sticky e
grid $Name -column 1 -row 13 -sticky ew
}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [ create_image driveroptlo icons ]
grid $Prompt -column 0 -row 16 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 16 -sticky w
	}
set Prompt $Parent.f1.p15
ttk::label $Prompt -text "TPROC-C Driver Script :" -image [ create_image hdbicon icons ] -compound left
grid $Prompt -column 0 -row 17 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "test" -text "Test Driver Script" -variable ora_driver
grid $Name -column 1 -row 17 -sticky w
bind .tpc.f1.r1 <ButtonPress-1> {
set checkpoint "false"
set allwarehouse "false"
set ora_timeprofile "false"
set async_scale "false"
set async_verbose "false"
.tpc.f1.e20 configure -state disabled
.tpc.f1.e21 configure -state disabled
.tpc.f1.e22 configure -state disabled
.tpc.f1.e23 configure -state disabled
.tpc.f1.e24 configure -state disabled
.tpc.f1.e25 configure -state disabled
.tpc.f1.e26 configure -state disabled
.tpc.f1.e27 configure -state disabled
.tpc.f1.e28 configure -state disabled
}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "timed" -text "Timed Driver Script" -variable ora_driver
grid $Name -column 1 -row 18 -sticky w
bind .tpc.f1.r2 <ButtonPress-1> {
.tpc.f1.e20 configure -state normal
.tpc.f1.e21 configure -state normal
.tpc.f1.e22 configure -state normal
.tpc.f1.e23 configure -state normal
.tpc.f1.e24 configure -state normal
.tpc.f1.e25 configure -state normal
if { $async_scale eq "true" } {
.tpc.f1.e26 configure -state normal
.tpc.f1.e27 configure -state normal
.tpc.f1.e28 configure -state normal
	}
}
set Name $Parent.f1.e17
   set Prompt $Parent.f1.p17
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable total_iterations
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky ew
 set Prompt $Parent.f1.p18
ttk::label $Prompt -text "Exit on Oracle Error :"
  set Name $Parent.f1.e18
ttk::checkbutton $Name -text "" -variable raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky w
 set Prompt $Parent.f1.p19
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.e19
ttk::checkbutton $Name -text "" -variable keyandthink -onvalue "true" -offvalue "false"
bind .tpc.f1.e19 <Any-ButtonRelease> {
if { $ora_driver eq "timed" } {
if { $keyandthink eq "true" } {
set async_scale "false"
set async_verbose "false"
.tpc.f1.e26 configure -state disabled
.tpc.f1.e27 configure -state disabled
.tpc.f1.e28 configure -state disabled
        } 
    }
}
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21 -sticky w
 set Prompt $Parent.f1.p20
ttk::label $Prompt -text "Checkpoint when complete :"
  set Name $Parent.f1.e20
ttk::checkbutton $Name -text "" -variable checkpoint -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 22 -sticky e
   grid $Name -column 1 -row 22 -sticky w
if {$ora_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e21
   set Prompt $Parent.f1.p21
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable rampup
   grid $Prompt -column 0 -row 23 -sticky e
   grid $Name -column 1 -row 23 -sticky ew
if {$ora_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e22
   set Prompt $Parent.f1.p22
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable duration
   grid $Prompt -column 0 -row 24 -sticky e
   grid $Name -column 1 -row 24 -sticky ew
if {$ora_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e23
   set Prompt $Parent.f1.p23
   ttk::label $Prompt -text "Use All Warehouses :"
ttk::checkbutton $Name -text "" -variable allwarehouse -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 25 -sticky e
   grid $Name -column 1 -row 25 -sticky ew
if {$ora_driver == "test" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e24
   set Prompt $Parent.f1.p24
   ttk::label $Prompt -text "Time Profile :"
ttk::checkbutton $Name -text "" -variable ora_timeprofile -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 26 -sticky e
   grid $Name -column 1 -row 26 -sticky ew
if {$ora_driver == "test" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e25
   set Prompt $Parent.f1.p25
   ttk::label $Prompt -text "Asynchronous Scaling :"
ttk::checkbutton $Name -text "" -variable async_scale -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 27 -sticky e
   grid $Name -column 1 -row 27 -sticky ew
if {$ora_driver == "test" } {
	set async_scale "false"
	$Name configure -state disabled
	}
bind .tpc.f1.e25 <Any-ButtonRelease> {
if { $async_scale eq "true" } {
set async_verbose "false"
.tpc.f1.e26 configure -state disabled
.tpc.f1.e27 configure -state disabled
.tpc.f1.e28 configure -state disabled
	} else {
if { $ora_driver eq "timed" } {
set keyandthink "true"
.tpc.f1.e26 configure -state normal
.tpc.f1.e27 configure -state normal
.tpc.f1.e28 configure -state normal
		}
	}
}
set Name $Parent.f1.e26
   set Prompt $Parent.f1.p26
   ttk::label $Prompt -text "Asynch Clients per Virtual User :"
   ttk::entry $Name -width 30 -textvariable async_client
   grid $Prompt -column 0 -row 28 -sticky e
   grid $Name -column 1 -row 28 -sticky ew
if {$ora_driver == "test" || $async_scale == "false" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e27
   set Prompt $Parent.f1.p27
   ttk::label $Prompt -text "Asynch Client Login Delay :"
   ttk::entry $Name -width 30 -textvariable async_delay
   grid $Prompt -column 0 -row 29 -sticky e
   grid $Name -column 1 -row 29 -sticky ew
if {$ora_driver == "test" || $async_scale == "false" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e28
   set Prompt $Parent.f1.p28
   ttk::label $Prompt -text "Asynchronous Verbose :"
ttk::checkbutton $Name -text "" -variable async_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 30 -sticky e
   grid $Name -column 1 -row 30 -sticky ew
if {$ora_driver == "test" || $async_scale == "false" } {
	set async_verbose "false"
	$Name configure -state disabled
	}
   set Name $Parent.f1.e29
   set Prompt $Parent.f1.p29
   ttk::label $Prompt -text "XML Connect Pool :"
ttk::checkbutton $Name -text "" -variable connect_pool -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 31 -sticky e
   grid $Name -column 1 -row 31 -sticky ew
}
#This is the Cancel button variables stay as before
set Name $Parent.b2
   ttk::button $Name -command {
unset orafields
destroy .tpc
} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
#This is the OK button all variables loaded back into config dict
set Name $Parent.b1
switch $option {
"drive" {
ttk::button $Name -command {
copyfieldstoconfig configoracle [ subst $orafields ] tpcc
unset orafields
destroy .tpc
loadtpcc
} -text {OK}
        }
"default" {
   ttk::button $Name -command {
set count_ware [ verify_warehouse $count_ware 100000 ]
set num_vu [ verify_build_threads $num_vu $count_ware 1024 ]
copyfieldstoconfig configoracle [ subst $orafields ] tpcc
unset orafields
destroy .tpc
} -text {OK}
        }
   }
   pack $Name -anchor nw -side right -padx 3 -pady 3
   
   wm geometry .tpc +50+50
   wm deiconify .tpc
   raise .tpc
   update
}

#Configure TPC-H Options
proc configoratpch {option} {
upvar #0 icons icons
upvar #0 configoracle configoracle
#set variables to values in dict
setlocaltpchvars $configoracle
variable orafields
set orafields [ dict create connection {instance {.tpch.f1.e1 get} system_user {.tpch.f1.e1a get} system_password {.tpch.f1.e2 get}} tpch {tpch_user {.tpch.f1.e3 get} tpch_pass {.tpch.f1.e4 get} tpch_def_tab {.tpch.f1.e5 get} tpch_def_temp {.tpch.f1.e6 get} total_querysets {.tpch.f1.e10 get} degree_of_parallel {.tpch.f1.e13 get} update_sets {.tpch.f1.e15 get} trickle_refresh {.tpch.f1.e16 get} tpch_tt_compat $tpch_tt_compat scale_fact $scale_fact num_tpch_threads $num_tpch_threads raise_query_error $raise_query_error verbose $verbose refresh_on $refresh_on refresh_verbose $refresh_verbose cloud_query $cloud_query}]
   catch "destroy .tpch"
   ttk::toplevel .tpch
   wm transient .tpch .ed_mainFrame
   wm withdraw .tpch
	switch $option {
	"all" { wm title .tpch {Oracle TPROC-H Schema Options} }
	"build" { wm title .tpch {Oracle TPROC-H Build Options} }
	"drive" {  wm title .tpch {Oracle TPROC-H Driver Options} }
	}
   set Parent .tpch
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
   if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [ create_image boxes icons ]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [ create_image driveroptlo icons ]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Oracle Service Name :"
   ttk::entry $Name -width 30 -textvariable instance
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -columnspan 4 -sticky ew
   set Name $Parent.f1.e1a
   set Prompt $Parent.f1.p1a
   ttk::label $Prompt -text "System User :"   
   ttk::entry $Name  -width 30 -textvariable system_user
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "System User Password :"
   ttk::entry $Name -width 30 -textvariable system_password
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -columnspan 4 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "TPROC-H User :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable tpch_user
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -columnspan 4 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "TPROC-H User Password :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name  -width 30 -textvariable tpch_pass
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -columnspan 4 -sticky ew
   if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "TPROC-H Default Tablespace :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable tpch_def_tab
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -columnspan 4 -sticky ew
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "TPROC-H Temporary Tablespace :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable tpch_def_temp
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -columnspan 4 -sticky ew
	}
set Prompt $Parent.f1.p7
ttk::label $Prompt -text "TimesTen Database Compatible :"
   set Name $Parent.f1.e7
ttk::checkbutton $Name -text "" -variable tpch_tt_compat -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky w
if { $tpch_tt_compat eq "false" } {
foreach field {e2 e5 e6} {
catch {.tpch.f1.$field configure -state normal}
        }
        } else {
foreach field {e2 e5 e6} {
catch {.tpch.f1.$field configure -state disabled}
        }
        }
bind .tpch.f1.e7 <ButtonPress-1> {
if { $tpch_tt_compat eq "true" } {
foreach field {e2 e5 e6 e13} {
catch {.tpch.f1.$field configure -state normal}
        }
    } else {
foreach field {e2 e5 e6 e13} {
catch {.tpch.f1.$field configure -state disabled}
        } }
}
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e8
   set Prompt $Parent.f1.p8 
   ttk::label $Prompt -text "Scale Factor :"
   grid $Prompt -column 0 -row 9 -sticky e
   set Name $Parent.f1.f2
   ttk::frame $Name -width 30
   grid $Name -column 1 -row 9 -sticky ew
	set rcnt 1
	foreach item {1} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable scale_fact -text $item -value $item -width 1
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 2
	foreach item {10 30} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable scale_fact -text $item -value $item -width 2
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 4
	foreach item {100 300} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable scale_fact -text $item -value $item -width 3
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 6
	foreach item {1000} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable scale_fact -text $item -value $item -width 4
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
set Prompt $Parent.f1.p9
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e9
ttk::spinbox $Name -from 1 -to 512 -textvariable num_tpch_threads
	grid $Prompt -column 0 -row 10 -sticky e
	grid $Name -column 1 -row 10 -sticky ew
	}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [ create_image driveroptlo icons ]
grid $Prompt -column 0 -row 12 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 12 -sticky w
	}
   set Name $Parent.f1.e10
   set Prompt $Parent.f1.p10
   ttk::label $Prompt -text "Total Query Sets per User :"
   ttk::entry $Name -width 30 -textvariable total_querysets
   grid $Prompt -column 0 -row 13 -sticky e
   grid $Name -column 1 -row 13  -columnspan 4 -sticky ew
 set Prompt $Parent.f1.p11
ttk::label $Prompt -text "Exit on Oracle Error :"
  set Name $Parent.f1.e11
ttk::checkbutton $Name -text "" -variable raise_query_error -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky w
 set Prompt $Parent.f1.p12
ttk::label $Prompt -text "Verbose Output :"
  set Name $Parent.f1.e12
ttk::checkbutton $Name -text "" -variable verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky w
   set Name $Parent.f1.e13
   set Prompt $Parent.f1.p13
   ttk::label $Prompt -text "Degree of Parallelism :"
   ttk::entry $Name -width 30 -textvariable degree_of_parallel
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16  -columnspan 4 -sticky ew
if { $tpch_tt_compat eq "false" } {
catch {.tpch.f1.e13 configure -state normal}
        } else {
catch {.tpch.f1.e13 configure -state disabled}
        }
 set Prompt $Parent.f1.p14
ttk::label $Prompt -text "Refresh Function :"
  set Name $Parent.f1.e14
ttk::checkbutton $Name -text "" -variable refresh_on -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17 -sticky w
bind $Parent.f1.e14 <Button> {
if {$refresh_on eq "true"} { 
set refresh_verbose "false"
foreach field {e15 e16 e17} {
.tpch.f1.$field configure -state disabled 
		}
} else {
foreach field {e15 e16 e17} {
.tpch.f1.$field configure -state normal
                        }
                }
	}
   set Name $Parent.f1.e15
   set Prompt $Parent.f1.p15
   ttk::label $Prompt -text "Number of Update Sets :"
   ttk::entry $Name -width 30 -textvariable update_sets
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18  -columnspan 4 -sticky ew
if {$refresh_on == "false" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e16
   set Prompt $Parent.f1.p16
   ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable trickle_refresh
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19  -columnspan 4 -sticky ew
if {$refresh_on == "false" } {
	$Name configure -state disabled
	}
 set Prompt $Parent.f1.p17
ttk::label $Prompt -text "Refresh Verbose :"
  set Name $Parent.f1.e17
ttk::checkbutton $Name -text "" -variable refresh_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky w
if {$refresh_on == "false" } {
	$Name configure -state disabled
	}
set Prompt $Parent.f1.p18
ttk::label $Prompt -text "Cloud Analytic Queries :"
  set Name $Parent.f1.e18
ttk::checkbutton $Name -text "" -variable cloud_query -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21 -sticky w
}
#This is the Cancel button variables stay as before
   set Name $Parent.b2
   ttk::button $Name -command {
unset orafields
destroy .tpch
} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
#This is the OK button all variables loaded back into config dict
set Name $Parent.b1
switch $option {
"drive" {
ttk::button $Name -command {
copyfieldstoconfig configoracle [ subst $orafields ] tpch
unset orafields
destroy .tpch
loadtpch
} -text {OK}
        }
"default" {
   ttk::button $Name -command {
set num_tpch_threads [ verify_build_threads $num_tpch_threads 512 512 ]
copyfieldstoconfig configoracle [ subst $orafields ] tpch
unset orafields
destroy .tpch
} -text {OK}
        }
   }
   pack $Name -anchor nw -side right -padx 3 -pady 3
   wm geometry .tpch +50+50
   wm deiconify .tpch
   raise .tpch
   update
}
#Configure Embedded Metrics Options
proc metoraopts {} {
global agent_hostname agent_id
upvar #0 icons icons
upvar #0 configoracle configoracle
#use same parameters as transaction counter
setlocaltcountvars $configoracle 1
variable oraoptsfields
set oraoptsfields [ dict create connection {system_user {.metric.f1.e4 get} system_password {.metric.f1.e5 get} instance {.metric.f1.e3 get}} ]
if {  [ info exists agent_hostname ] } { ; } else { set agent_hostname "localhost" }
if {  [ info exists agent_id ] } { ; } else { set agent_id 0 }
set old_agent $agent_hostname
set old_id $agent_id
   catch "destroy .metric"
   ttk::toplevel .metric
   wm transient .metric .ed_mainFrame
   wm withdraw .metric
   wm title .metric {Oracle Metrics Options}
   set Parent .metric
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [ create_image dashboard icons ]
grid $Prompt -column 0 -row 0 -sticky e

set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Oracle and OS Agent"
grid $Prompt -column 1 -row 0 -sticky w

   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Agent ID :"
   ttk::entry $Name -width 30 -textvariable agent_id
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Agent Hostname :"
   ttk::entry $Name -width 30 -textvariable agent_hostname
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8
   set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "Oracle Service Name :"
   ttk::entry $Name -width 30 -textvariable instance
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
   set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "System User :"
   ttk::entry $Name  -width 30 -textvariable system_user
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
   set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "System User Password :"
   ttk::entry $Name  -width 30 -textvariable system_password
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
   set Name $Parent.b4
   ttk::button $Name -command { destroy .metric } -text Cancel

pack $Name -anchor w -side right -padx 3 -pady 3
   set Name $Parent.b5
   ttk::button $Name -command {
         set agent_id [.metric.f1.e1 get]
         set agent_hostname [.metric.f1.e2 get]
copyfieldstoconfig configoracle [ subst $oraoptsfields ] tpcc
unset oraoptsfields
         catch "destroy .metric"
if { ![string is integer -strict $agent_id] } {
tk_messageBox -message "Agent id must be an integer"
set agent_id 0
          }
        } -text {OK}
   pack $Name -anchor w -side right -padx 3 -pady 3
   wm geometry .metric +50+50
   wm deiconify .metric
   raise .metric
   update
}
