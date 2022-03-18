proc countdb2opts { bm } {
upvar #0 icons icons
upvar #0 configdb2 configdb2
upvar #0 genericdict genericdict
global afval interval tclog uniquelog tcstamp
dict with genericdict { dict with transaction_counter {
#variables for button options need to be global
set interval $tc_refresh_rate
set tclog $tc_log_to_temp
set uniquelog $tc_unique_log_name
set tcstamp $tc_log_timestamps
}}
setlocaltcountvars $configdb2 1
variable db2optsfields
if { $bm eq "TPC-C" } {
set db2optsfields [ dict create connection {db2_def_user {} db2_def_pass {} db2_def_dbase {}} tpcc {db2_user {.countopt.f1.e1 get} db2_pass {.countopt.f1.e2 get} db2_dbase {.countopt.f1.e3 get}} ]
        } else {
set db2optsfields [ dict create connection {db2_def_user {} db2_def_pass {} db2_def_dbase {}} tpch {db2_tpch_user {.countopt.f1.e1 get} db2_tpch_pass {.countopt.f1.e2 get} db2_tpch_dbase {.countopt.f1.e3 get}} ]
}

if { [ info exists afval ] } {
        after cancel $afval
        unset afval
}

if { $bm eq "TPC-C" } {
set tmp_db2_user db2_user
set tmp_db2_pass db2_pass
set tmp_db2_dbase db2_dbase
set tval 60
        } else {
set tmp_db2_user db2_tpch_user
set tmp_db2_pass db2_tpch_pass
set tmp_db2_dbase db2_tpch_dbase
        }
   catch "destroy .countopt"
   ttk::toplevel .countopt
   wm transient .countopt .ed_mainFrame
   wm withdraw .countopt
   wm title .countopt {Db2 TX Counter Options}
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
   ttk::label $Prompt -text "TPROC-C Db2 User :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable $tmp_db2_user
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "TPROC-C Db2 User Password :" -image [ create_image hdbicon icons ] -compound left 
   ttk::entry $Name  -width 30 -textvariable $tmp_db2_pass
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "TPROC-C Db2 Database :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name  -width 30 -textvariable $tmp_db2_dbase
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
   set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "Refresh Rate(secs) :"
   ttk::entry $Name -width 30 -textvariable interval
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew

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
unset db2optsfields
destroy .countopt
} -text Cancel
 pack $Name -anchor nw -side right -padx 3 -pady 3

 set Name $Parent.b1
if { $bm eq "TPC-C" } {
   ttk::button $Name -command {
copyfieldstoconfig configdb2 [ subst $db2optsfields ] tpcc
unset db2optsfields
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
} else {
   ttk::button $Name -command {
copyfieldstoconfig configdb2 [ subst $db2optsfields ] tpch
unset db2optsfields
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
}
   pack $Name -anchor nw -side right -padx 3 -pady 3

 wm geometry .countopt +50+50
   wm deiconify .countopt
   raise .countopt
   update
}

proc configdb2tpcc {option} {
upvar #0 icons icons
upvar #0 configdb2 configdb2
#set variables to values in dict
setlocaltpccvars $configdb2
#set matching fields in dialog to temporary dict
variable db2fields
set db2fields [ dict create connection {db2_def_user {} db2_def_pass {} db2_def_dbase {}} tpcc {db2_user {.tpc.f1.e1 get} db2_pass {.tpc.f1.e2 get} db2_dbase {.tpc.f1.e3 get} db2_def_tab {.tpc.f1.e4 get} db2_tab_list {.tpc.f1.e5 get} db2_total_iterations {.tpc.f1.e14 get} db2_rampup {.tpc.f1.e17 get} db2_duration {.tpc.f1.e18 get} db2_monreport {.tpc.f1.e19 get} db2_async_client {.tpc.f1.e23 get} db2_async_delay {.tpc.f1.e24 get} db2_count_ware $db2_count_ware db2_num_vu $db2_num_vu db2_partition $db2_partition db2_driver $db2_driver db2_raiseerror $db2_raiseerror db2_keyandthink $db2_keyandthink db2_allwarehouse $db2_allwarehouse db2_timeprofile $db2_timeprofile db2_async_scale $db2_async_scale db2_async_verbose $db2_async_verbose db2_connect_pool $db2_connect_pool} ]
set whlist [ get_warehouse_list_for_spinbox ]
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm transient .tpc .ed_mainFrame
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {Db2 TPROC-C Schema Options} }
"build" { wm title .tpc {Db2 TPROC-C Build Options} }
"drive" {  wm title .tpc {Db2 TPROC-C Driver Options} }
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
   ttk::label $Prompt -text "TPROC-C Db2 User :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable db2_user
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "TPROC-C Db2 User Password :" -image [ create_image hdbicon icons ] -compound left 
   ttk::entry $Name  -width 30 -textvariable db2_pass
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "TPROC-C Db2 Database :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name  -width 30 -textvariable db2_dbase
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "TPROC-C Db2 Default Tablespace :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable db2_def_tab
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "TPROC-C Db2 Tablespace List (Space Separated Values) :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable db2_tab_list
if { $db2_partition eq "false" } {
	.tpc.f1.e5 configure -state disabled
		} 
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
set Prompt $Parent.f1.p8
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e8
ttk::spinbox $Name -value $whlist -textvariable db2_count_ware
bind .tpc.f1.e8 <<Any-Button-Any-Key>> {
if {$db2_num_vu > $db2_count_ware} {
set db2_num_vu $db2_count_ware
		}
if {$db2_count_ware < 10} {
.tpc.f1.e5 configure -state disabled
.tpc.f1.e10 configure -state disabled
set db2_partition "false"
        } else {
if { $db2_partition eq "true" } {
.tpc.f1.e5 configure -state normal
	} else {
.tpc.f1.e5 configure -state disabled
	}
.tpc.f1.e10 configure -state enabled
        }
}
	grid $Prompt -column 0 -row 8 -sticky e
	grid $Name -column 1 -row 8 -sticky ew
set Prompt $Parent.f1.p9
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e9
ttk::spinbox $Name -value $whlist -textvariable db2_num_vu
bind .tpc.f1.e9 <<Any-Button-Any-Key>> {
if {$db2_num_vu > $db2_count_ware} {
set db2_num_vu $db2_count_ware
                }
        }
event add <<Any-Button-Any-Key>> <Any-ButtonRelease>
event add <<Any-Button-Any-Key>> <KeyRelease>
grid $Prompt -column 0 -row 9 -sticky e
grid $Name -column 1 -row 9 -sticky ew
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Partition Tables :"
set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable db2_partition -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
if {$db2_count_ware < 10 } {
	set db2_partition "false"
        $Name configure -state disabled
	.tpc.f1.e5 configure -state disabled
        }
bind .tpc.f1.e10 <ButtonPress-1> {
if { $db2_count_ware >= 10 } {
if { $db2_partition eq "true" } {
	.tpc.f1.e5 configure -state disabled
		} else {
	.tpc.f1.e5 configure -state normal
		}
	}
   }
}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [ create_image driveroptlo icons ]
grid $Prompt -column 0 -row 11 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 11 -sticky w
	}
set Prompt $Parent.f1.p12
ttk::label $Prompt -text "TPROC-C Driver Script :" -image [ create_image hdbicon icons ] -compound left
grid $Prompt -column 0 -row 12 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "test" -text "Test Driver Script" -variable db2_driver
grid $Name -column 1 -row 12 -sticky w
bind .tpc.f1.r1 <ButtonPress-1> {
set db2_allwarehouse "false"
set db2_timeprofile "false"
set db2_async_scale "false"
set db2_async_verbose "false"
.tpc.f1.e17 configure -state disabled
.tpc.f1.e18 configure -state disabled
.tpc.f1.e19 configure -state disabled
.tpc.f1.e20 configure -state disabled
.tpc.f1.e21 configure -state disabled
.tpc.f1.e22 configure -state disabled
.tpc.f1.e23 configure -state disabled
.tpc.f1.e24 configure -state disabled
.tpc.f1.e25 configure -state disabled
if {$db2_monreport >= $db2_duration} {
set db2_monreport 0
                }
}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "timed" -text "Timed Driver Script" -variable db2_driver
grid $Name -column 1 -row 13 -sticky w
bind .tpc.f1.r2 <ButtonPress-1> {
.tpc.f1.e17 configure -state normal
.tpc.f1.e18 configure -state normal
.tpc.f1.e19 configure -state normal
.tpc.f1.e20 configure -state normal
.tpc.f1.e21 configure -state normal
.tpc.f1.e22 configure -state normal
if { $db2_async_scale eq "true" } {
.tpc.f1.e23 configure -state normal
.tpc.f1.e24 configure -state normal
.tpc.f1.e25 configure -state normal
	}
if {$db2_monreport >= $db2_duration} {
set db2_monreport 0
                }
}
set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable db2_total_iterations
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky ew
 set Prompt $Parent.f1.p15
ttk::label $Prompt -text "Exit on Db2 Error :"
  set Name $Parent.f1.e15
ttk::checkbutton $Name -text "" -variable db2_raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky w
 set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable db2_keyandthink -onvalue "true" -offvalue "false"
bind .tpc.f1.e16 <Any-ButtonRelease> {
if { $db2_driver eq "timed" } {
if { $db2_keyandthink eq "true" } {
set db2_async_scale "false"
set db2_async_verbose "false"
.tpc.f1.e23 configure -state disabled
.tpc.f1.e24 configure -state disabled
.tpc.f1.e25 configure -state disabled
        }
    }
}
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16 -sticky w
set Name $Parent.f1.e17
   set Prompt $Parent.f1.p17
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable db2_rampup
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17 -sticky ew
if {$db2_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e18
   set Prompt $Parent.f1.p18
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable db2_duration
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky ew
if {$db2_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e19
   set Prompt $Parent.f1.p19
   ttk::label $Prompt -text "Minutes for MONREPORT :"
   ttk::entry $Name -width 30 -textvariable db2_monreport
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky ew
if {$db2_driver == "test" } {
	$Name configure -state disabled
	}
if {$db2_monreport >= $db2_duration} {
set db2_monreport [ expr $db2_duration - 1 ]
                }
set Name $Parent.f1.e20
   set Prompt $Parent.f1.p20
   ttk::label $Prompt -text "Use All Warehouses :"
ttk::checkbutton $Name -text "" -variable db2_allwarehouse -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky ew
if {$db2_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e21
   set Prompt $Parent.f1.p21
   ttk::label $Prompt -text "Time Profile :"
ttk::checkbutton $Name -text "" -variable db2_timeprofile -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21 -sticky ew
if {$db2_driver == "test" } {
	$Name configure -state disabled
	}
  set Name $Parent.f1.e22
   set Prompt $Parent.f1.p22
   ttk::label $Prompt -text "Asynchronous Scaling :"
ttk::checkbutton $Name -text "" -variable db2_async_scale -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 22 -sticky e
   grid $Name -column 1 -row 22 -sticky ew
if {$db2_driver == "test" } {
        set db2_async_scale "false"
        $Name configure -state disabled
        }
bind .tpc.f1.e22 <Any-ButtonRelease> {
if { $db2_async_scale eq "true" } {
set db2_async_verbose "false"
.tpc.f1.e23 configure -state disabled
.tpc.f1.e24 configure -state disabled
.tpc.f1.e25 configure -state disabled
        } else {
if { $db2_driver eq "timed" } {
set db2_keyandthink "true"
.tpc.f1.e23 configure -state normal
.tpc.f1.e24 configure -state normal
.tpc.f1.e25 configure -state normal
                }
        }
}
set Name $Parent.f1.e23
   set Prompt $Parent.f1.p23
   ttk::label $Prompt -text "Asynch Clients per Virtual User :"
   ttk::entry $Name -width 30 -textvariable db2_async_client
   grid $Prompt -column 0 -row 23 -sticky e
   grid $Name -column 1 -row 23 -sticky ew
if {$db2_driver == "test" || $db2_async_scale == "false" } {
        $Name configure -state disabled
        }
set Name $Parent.f1.e24
   set Prompt $Parent.f1.p24
   ttk::label $Prompt -text "Asynch Client Login Delay :"
   ttk::entry $Name -width 30 -textvariable db2_async_delay
   grid $Prompt -column 0 -row 24 -sticky e
   grid $Name -column 1 -row 24 -sticky ew
if {$db2_driver == "test" || $db2_async_scale == "false" } {
        $Name configure -state disabled
        }
   set Name $Parent.f1.e25
   set Prompt $Parent.f1.p25
   ttk::label $Prompt -text "Asynchronous Verbose :"
ttk::checkbutton $Name -text "" -variable db2_async_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 25 -sticky e
   grid $Name -column 1 -row 25 -sticky ew
if {$db2_driver == "test" || $db2_async_scale == "false" } {
        set db2_async_verbose "false"
        $Name configure -state disabled
        }
   set Name $Parent.f1.e26
   set Prompt $Parent.f1.p26
   ttk::label $Prompt -text "XML Connect Pool :"
ttk::checkbutton $Name -text "" -variable db2_connect_pool -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 26 -sticky e
   grid $Name -column 1 -row 26 -sticky ew
}
#This is the Cancel button variables stay as before
set Name $Parent.b2
   ttk::button $Name -command {
   unset db2fields
   destroy .tpc
} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
#This is the OK button all variables loaded back into config dict
set Name $Parent.b1
switch $option {
"drive" {
if {$db2_monreport >= $db2_duration} { set db2_monreport 0 }
ttk::button $Name -command {
copyfieldstoconfig configdb2 [ subst $db2fields ] tpcc
unset db2fields
destroy .tpc
loadtpcc
} -text {OK}
        }
"default" {
   ttk::button $Name -command {
set db2_count_ware [ verify_warehouse $db2_count_ware 100000 ]
set db2_num_vu [ verify_build_threads $db2_num_vu $db2_count_ware 1024 ]
copyfieldstoconfig configdb2 [ subst $db2fields ] tpcc
unset db2fields
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

proc configdb2tpch {option} {
upvar #0 icons icons
upvar #0 configdb2 configdb2
#set variables to values in dict
setlocaltpchvars $configdb2
#set matching fields in dialog to temporary dict
variable db2fields
set db2fields [ dict create connection {db2_def_user {} db2_def_pass {} db2_def_dbase {}} tpch {db2_tpch_user {.db2tpch.f1.e1 get} db2_tpch_pass {.db2tpch.f1.e2 get} db2_tpch_dbase {.db2tpch.f1.e3 get} db2_tpch_def_tab {.db2tpch.f1.e4 get} db2_total_querysets {.db2tpch.f1.e9 get} db2_degree_of_parallel {.db2tpch.f1.e12 get} db2_update_sets {.db2tpch.f1.e14 get} db2_trickle_refresh {.db2tpch.f1.e15 get} db2_scale_fact $db2_scale_fact db2_num_tpch_threads $db2_num_tpch_threads db2_tpch_organizeby $db2_tpch_organizeby db2_raise_query_error $db2_raise_query_error db2_verbose $db2_verbose db2_refresh_on $db2_refresh_on db2_refresh_verbose $db2_refresh_verbose} ]
   catch "destroy .db2tpch"
   ttk::toplevel .db2tpch
   wm transient .db2tpch .ed_mainFrame
   wm withdraw .db2tpch
switch $option {
"all" { wm title .db2tpch {Db2 TPROC-H Schema Options} }
"build" { wm title .db2tpch {Db2 TPROC-H Build Options} }
"drive" {  wm title .db2tpch {Db2 TPROC-H Driver Options} }
	}
   set Parent .db2tpch
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
   ttk::label $Prompt -text "TPROC-H Db2 User :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable db2_tpch_user
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "TPROC-H Db2 User Password :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name  -width 30 -textvariable db2_tpch_pass
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "TPROC-H Db2 Database :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name  -width 30 -textvariable db2_tpch_dbase
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "TPROC-H Db2 Default Tablespace :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name  -width 30 -textvariable db2_tpch_def_tab
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "Db2 Organize By :"
   grid $Prompt -column 0 -row 5 -sticky e
   set Name $Parent.f1.f1
   ttk::frame $Name -width 30
   grid $Name -column 1 -row 5 -sticky ew
        set rcnt 1
        foreach item {NONE ROW COL DATE} {
        set Name $Parent.f1.f1.r$rcnt
	ttk::radiobutton $Name -variable db2_tpch_organizeby -text $item -value $item -width 6
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "Scale Factor :"
   grid $Prompt -column 0 -row 6 -sticky e
   set Name $Parent.f1.f2
   ttk::frame $Name -width 30
   grid $Name -column 1 -row 6 -sticky ew
	set rcnt 1
	foreach item {1} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable db2_scale_fact -text $item -value $item -width 1
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 2
	foreach item {10 30} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable db2_scale_fact -text $item -value $item -width 2
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 4
	foreach item {100 300} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable db2_scale_fact -text $item -value $item -width 3
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 6
	foreach item {1000} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable db2_scale_fact -text $item -value $item -width 4
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
set Prompt $Parent.f1.p7
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e7
ttk::spinbox $Name -from 1 -to 512 -textvariable db2_num_tpch_threads
	grid $Prompt -column 0 -row 7 -sticky e
	grid $Name -column 1 -row 7 -sticky ew
	}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [ create_image driveroptlo icons ]
grid $Prompt -column 0 -row 8 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 8 -sticky w
	}
   set Name $Parent.f1.e9
   set Prompt $Parent.f1.p9
   ttk::label $Prompt -text "Total Query Sets per User :"
   ttk::entry $Name -width 30 -textvariable db2_total_querysets
   grid $Prompt -column 0 -row 9 -sticky e
   grid $Name -column 1 -row 9  -columnspan 4 -sticky ew
 set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Exit on Db2 Error :"
  set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable db2_raise_query_error -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
 set Prompt $Parent.f1.p11
ttk::label $Prompt -text "Verbose Output :"
  set Name $Parent.f1.e11
ttk::checkbutton $Name -text "" -variable db2_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 11 -sticky e
   grid $Name -column 1 -row 11 -sticky w
set Name $Parent.f1.e12
   set Prompt $Parent.f1.p12
   ttk::label $Prompt -text "Degree of Parallelism :"
   ttk::entry $Name  -width 30 -textvariable db2_degree_of_parallel
   grid $Prompt -column 0 -row 12 -sticky e
   grid $Name -column 1 -row 12 -sticky ew
 set Prompt $Parent.f1.p13
ttk::label $Prompt -text "Refresh Function :"
  set Name $Parent.f1.e13
ttk::checkbutton $Name -text "" -variable db2_refresh_on -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 13 -sticky e
   grid $Name -column 1 -row 13 -sticky w
bind $Parent.f1.e13 <Button> {
if {$db2_refresh_on eq "true"} { 
set db2_refresh_verbose "false"
foreach field {e14 e15 e16} {
.db2tpch.f1.$field configure -state disabled 
		}
} else {
foreach field {e14 e15 e16} {
.db2tpch.f1.$field configure -state normal
                        }
                }
	}
   set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Number of Update Sets :"
   ttk::entry $Name -width 30 -textvariable db2_update_sets
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14  -columnspan 4 -sticky ew
if {$db2_refresh_on == "false" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e15
   set Prompt $Parent.f1.p15
   ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable db2_trickle_refresh
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15  -columnspan 4 -sticky ew
if {$db2_refresh_on == "false" } {
	$Name configure -state disabled
	}
 set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Refresh Verbose :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable db2_refresh_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16 -sticky w
if {$db2_refresh_on == "false" } {
	$Name configure -state disabled
	}
}
#This is the Cancel button variables stay as before
   set Name $Parent.b2
   ttk::button $Name -command {
unset db2fields
destroy .db2tpch
} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
#This is the OK button all variables loaded back into config dict
   set Name $Parent.b1
switch $option {
"drive" {
ttk::button $Name -command {
copyfieldstoconfig configdb2 [ subst $db2fields ] tpch
unset db2fields
destroy .db2tpch
loadtpch
} -text {OK}
        }
"default" {
   ttk::button $Name -command {
set db2_num_tpch_threads [ verify_build_threads $db2_num_tpch_threads 512 512 ]
copyfieldstoconfig configdb2 [ subst $db2fields ] tpch
unset db2fields
destroy .db2tpch
} -text {OK}
        }
}
   pack $Name -anchor nw -side right -padx 3 -pady 3
   wm geometry .db2tpch +50+50
   wm deiconify .db2tpch
   raise .db2tpch
   update
}
