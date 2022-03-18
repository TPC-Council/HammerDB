proc countmysqlopts { bm } {
upvar #0 icons icons
upvar #0 configmysql configmysql
upvar #0 genericdict genericdict
global afval interval tclog uniquelog tcstamp
dict with genericdict { dict with transaction_counter {
#variables for button options need to be global
set interval $tc_refresh_rate
set tclog $tc_log_to_temp
set uniquelog $tc_unique_log_name
set tcstamp $tc_log_timestamps
}}
setlocaltcountvars $configmysql 1 
variable myoptsfields 
if { $bm eq "TPC-C" } {
set myoptsfields [ dict create connection {mysql_host {.countopt.f1.e1 get} mysql_port {.countopt.f1.e2 get} mysql_socket {.countopt.f1.e2a get}} tpcc {mysql_user {.countopt.f1.e3 get} mysql_pass {.countopt.f1.e4 get}} ]
	} else {
set myoptsfields [ dict create connection {mysql_host {.countopt.f1.e1 get} mysql_port {.countopt.f1.e2 get} mysql_socket {.countopt.f1.e2a get}} tpch {mysql_tpch_user {.countopt.f1.e3 get} mysql_tpch_pass {.countopt.f1.e4 get}} ]
}
if { [ info exists afval ] } {
	after cancel $afval
	unset afval
}

   catch "destroy .countopt"
   ttk::toplevel .countopt
   wm transient .countopt .ed_mainFrame
   wm withdraw .countopt
   wm title .countopt {MySQL TX Counter Options}
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
   ttk::label $Prompt -text "MySQL Host :"
   ttk::entry $Name -width 30 -textvariable mysql_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "MySQL Port :"   
   ttk::entry $Name  -width 30 -textvariable mysql_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
   set Name $Parent.f1.e2a
   set Prompt $Parent.f1.p2a
   ttk::label $Prompt -text "MySQL Socket :"   
   ttk::entry $Name  -width 30 -textvariable mysql_socket
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
   if {[string match windows $::tcl_platform(platform)]} {
	set mysql_socket "null"
	.countopt.f1.e2a configure -state disabled
   }
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "MySQL User :"
if { $bm eq "TPC-C" } {
   ttk::entry $Name  -width 30 -textvariable mysql_user
	} else {
   ttk::entry $Name  -width 30 -textvariable mysql_tpch_user
	}
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "MySQL User Password :"   
if { $bm eq "TPC-C" } {
   ttk::entry $Name  -width 30 -textvariable mysql_pass
	} else {
   ttk::entry $Name  -width 30 -textvariable mysql_tpch_pass
	}
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
   set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "Refresh Rate(secs) :"
   ttk::entry $Name -width 30 -textvariable interval
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew

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
unset myoptsfields
destroy .countopt
} -text Cancel
 pack $Name -anchor nw -side right -padx 3 -pady 3

 set Name $Parent.b1
if { $bm eq "TPC-C" } {
   ttk::button $Name -command {
copyfieldstoconfig configmysql [ subst $myoptsfields ] tpcc
unset myoptsfields
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs"
        dict set genericdict transaction_counter tc_refresh_rate 10
           } else {
        dict with genericdict { dict with transaction_counter {
        set tc_refresh_rate [.countopt.f1.e5 get]
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
copyfieldstoconfig configmysql [ subst $myoptsfields ] tpch
unset myoptsfields
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs"
        dict set genericdict transaction_counter tc_refresh_rate 10
           } else {
        dict with genericdict { dict with transaction_counter {
        set tc_refresh_rate [.countopt.f1.e5 get]
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

proc configmysqltpcc {option} {
upvar #0 icons icons
upvar #0 configmysql configmysql
#set variables to values in dict
setlocaltpccvars $configmysql
#set matching fields in dialog to temporary dict
variable myfields
set myfields [ dict create connection {mysql_host {.tpc.f1.e1 get} mysql_port {.tpc.f1.e2 get} mysql_socket {.tpc.f1.e2a get}} tpcc {mysql_user {.tpc.f1.e3 get} mysql_pass {.tpc.f1.e4 get} mysql_dbase {.tpc.f1.e5 get} mysql_storage_engine {.tpc.f1.e6 get} mysql_total_iterations {.tpc.f1.e14 get} mysql_rampup {.tpc.f1.e17 get} mysql_duration {.tpc.f1.e18 get} mysql_async_client {.tpc.f1.e22 get} mysql_async_delay {.tpc.f1.e23 get} mysql_count_ware $mysql_count_ware mysql_num_vu $mysql_num_vu mysql_partition $mysql_partition mysql_driver $mysql_driver mysql_raiseerror $mysql_raiseerror mysql_keyandthink $mysql_keyandthink mysql_allwarehouse $mysql_allwarehouse mysql_timeprofile $mysql_timeprofile mysql_async_scale $mysql_async_scale mysql_async_verbose $mysql_async_verbose mysql_prepared $mysql_prepared mysql_connect_pool $mysql_connect_pool} ]
set whlist [ get_warehouse_list_for_spinbox ]
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm transient .tpc .ed_mainFrame
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {MySQL TPROC-C Schema Options} }
"build" { wm title .tpc {MySQL TPROC-C Build Options} }
"drive" {  wm title .tpc {MySQL TPROC-C Driver Options} }
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
   ttk::label $Prompt -text "MySQL Host :"
   ttk::entry $Name -width 30 -textvariable mysql_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "MySQL Port :"   
   ttk::entry $Name  -width 30 -textvariable mysql_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
   set Name $Parent.f1.e2a
   set Prompt $Parent.f1.p2a
   ttk::label $Prompt -text "MySQL Socket :"
   ttk::entry $Name  -width 30 -textvariable mysql_socket
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
   if {[string match windows $::tcl_platform(platform)]} {
      .tpc.f1.e2a configure -state disabled
   }
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "MySQL User :"
   ttk::entry $Name  -width 30 -textvariable mysql_user
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "MySQL User Password :"   
   ttk::entry $Name  -width 30 -textvariable mysql_pass
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "TPROC-C MySQL Database :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable mysql_dbase
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "Transactional Storage Engine :"
   ttk::entry $Name -width 30 -textvariable mysql_storage_engine
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
set Prompt $Parent.f1.p8
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e8
ttk::spinbox $Name -value $whlist -textvariable mysql_count_ware
bind .tpc.f1.e8 <<Any-Button-Any-Key>> {
if {$mysql_num_vu > $mysql_count_ware} {
set mysql_num_vu $mysql_count_ware
		}
if {$mysql_count_ware < 200} {
.tpc.f1.e10 configure -state disabled
set mysql_partition "false"
        } else {
.tpc.f1.e10 configure -state enabled
        }
}
	grid $Prompt -column 0 -row 8 -sticky e
	grid $Name -column 1 -row 8 -sticky ew
set Prompt $Parent.f1.p9
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e9
ttk::spinbox $Name -from 1 -to 512 -textvariable mysql_num_vu
bind .tpc.f1.e9 <<Any-Button-Any-Key>> {
if {$mysql_num_vu > $mysql_count_ware} {
set mysql_num_vu $mysql_count_ware
                }
        }
event add <<Any-Button-Any-Key>> <Any-ButtonRelease>
event add <<Any-Button-Any-Key>> <KeyRelease>
grid $Prompt -column 0 -row 9 -sticky e
grid $Name -column 1 -row 9 -sticky ew
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Partition Order Line Table :"
set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable mysql_partition -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
if {$mysql_count_ware <= 200 } {
        $Name configure -state disabled
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
ttk::radiobutton $Name -value "test" -text "Test Driver Script" -variable mysql_driver
grid $Name -column 1 -row 12 -sticky w
bind .tpc.f1.r1 <ButtonPress-1> {
set mysql_allwarehouse "false"
set mysql_timeprofile "false"
set mysql_async_scale "false"
set mysql_async_verbose "false"
.tpc.f1.e17 configure -state disabled
.tpc.f1.e18 configure -state disabled
.tpc.f1.e19 configure -state disabled
.tpc.f1.e20 configure -state disabled
.tpc.f1.e21 configure -state disabled
.tpc.f1.e22 configure -state disabled
.tpc.f1.e23 configure -state disabled
.tpc.f1.e24 configure -state disabled
}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "timed" -text "Timed Driver Script" -variable mysql_driver
grid $Name -column 1 -row 13 -sticky w
bind .tpc.f1.r2 <ButtonPress-1> {
.tpc.f1.e17 configure -state normal
.tpc.f1.e18 configure -state normal
.tpc.f1.e19 configure -state normal
.tpc.f1.e20 configure -state normal
.tpc.f1.e21 configure -state normal
if { $mysql_async_scale eq "true" } {
.tpc.f1.e22 configure -state normal
.tpc.f1.e23 configure -state normal
.tpc.f1.e24 configure -state normal
	}
}
set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable mysql_total_iterations
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky ew
 set Prompt $Parent.f1.p15
ttk::label $Prompt -text "Exit on MySQL Error :"
  set Name $Parent.f1.e15
ttk::checkbutton $Name -text "" -variable mysql_raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky w
 set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable mysql_keyandthink -onvalue "true" -offvalue "false"
bind .tpc.f1.e16 <Any-ButtonRelease> {
if { $mysql_driver eq "timed" } {
if { $mysql_keyandthink eq "true" } {
set mysql_async_scale "false"
set mysql_async_verbose "false"
.tpc.f1.e22 configure -state disabled
.tpc.f1.e23 configure -state disabled
.tpc.f1.e24 configure -state disabled
        }
    }
}
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16 -sticky w
 set Prompt $Parent.f1.p16a
ttk::label $Prompt -text "Prepare Statements :"
  set Name $Parent.f1.e16a
ttk::checkbutton $Name -text "" -variable mysql_prepared -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17 -sticky w
set Name $Parent.f1.e17
   set Prompt $Parent.f1.p17
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable mysql_rampup
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky ew
if {$mysql_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e18
   set Prompt $Parent.f1.p18
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable mysql_duration
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky ew
if {$mysql_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e19
   set Prompt $Parent.f1.p19
   ttk::label $Prompt -text "Use All Warehouses :"
ttk::checkbutton $Name -text "" -variable mysql_allwarehouse -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky ew
if {$mysql_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e20
   set Prompt $Parent.f1.p20
   ttk::label $Prompt -text "Time Profile :"
ttk::checkbutton $Name -text "" -variable mysql_timeprofile -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21 -sticky ew
if {$mysql_driver == "test" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e21
   set Prompt $Parent.f1.p21
   ttk::label $Prompt -text "Asynchronous Scaling :"
ttk::checkbutton $Name -text "" -variable mysql_async_scale -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 22 -sticky e
   grid $Name -column 1 -row 22 -sticky ew
if {$mysql_driver == "test" } {
        set mysql_async_scale "false"
        $Name configure -state disabled
        }
bind .tpc.f1.e21 <Any-ButtonRelease> {
if { $mysql_async_scale eq "true" } {
set mysql_async_verbose "false"
.tpc.f1.e22 configure -state disabled
.tpc.f1.e23 configure -state disabled
.tpc.f1.e24 configure -state disabled
        } else {
if { $mysql_driver eq "timed" } {
set mysql_keyandthink "true"
.tpc.f1.e22 configure -state normal
.tpc.f1.e23 configure -state normal
.tpc.f1.e24 configure -state normal
                }
        }
}
set Name $Parent.f1.e22
   set Prompt $Parent.f1.p22
   ttk::label $Prompt -text "Asynch Clients per Virtual User :"
   ttk::entry $Name -width 30 -textvariable mysql_async_client
   grid $Prompt -column 0 -row 23 -sticky e
   grid $Name -column 1 -row 23 -sticky ew
if {$mysql_driver == "test" || $mysql_async_scale == "false" } {
        $Name configure -state disabled
        }
set Name $Parent.f1.e23
   set Prompt $Parent.f1.p23
   ttk::label $Prompt -text "Asynch Client Login Delay :"
   ttk::entry $Name -width 30 -textvariable mysql_async_delay
   grid $Prompt -column 0 -row 24 -sticky e
   grid $Name -column 1 -row 24 -sticky ew
if {$mysql_driver == "test" || $mysql_async_scale == "false" } {
        $Name configure -state disabled
        }
   set Name $Parent.f1.e24
   set Prompt $Parent.f1.p24
   ttk::label $Prompt -text "Asynchronous Verbose :"
ttk::checkbutton $Name -text "" -variable mysql_async_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 25 -sticky e
   grid $Name -column 1 -row 25 -sticky ew
if {$mysql_driver == "test" || $mysql_async_scale == "false" } {
        set mysql_async_verbose "false"
        $Name configure -state disabled
        }
   set Name $Parent.f1.e25
   set Prompt $Parent.f1.p25
   ttk::label $Prompt -text "XML Connect Pool :"
ttk::checkbutton $Name -text "" -variable mysql_connect_pool -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 26 -sticky e
   grid $Name -column 1 -row 26 -sticky ew
}
#This is the Cancel button variables stay as before
set Name $Parent.b2
   ttk::button $Name -command {
   unset myfields
   destroy .tpc
} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
#This is the OK button all variables loaded back into config dict
set Name $Parent.b1
switch $option {
"drive" {
ttk::button $Name -command {
copyfieldstoconfig configmysql [ subst $myfields ] tpcc
unset myfields
destroy .tpc
loadtpcc
} -text {OK}
        }
"default" {
   ttk::button $Name -command {
set mysql_count_ware [ verify_warehouse $mysql_count_ware 100000 ]
set mysql_num_vu [ verify_build_threads $mysql_num_vu $mysql_count_ware 1024 ]
copyfieldstoconfig configmysql [ subst $myfields ] tpcc
unset myfields
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

proc configmysqltpch {option} {
upvar #0 icons icons
upvar #0 configmysql configmysql
#set variables to values in dict
setlocaltpchvars $configmysql
#set matching fields in dialog to temporary dict
variable myfields
set myfields [ dict create connection {mysql_host {.mytpch.f1.e1 get} mysql_port {.mytpch.f1.e2 get} mysql_socket {.mytpch.f1.e2a get}} tpch {mysql_tpch_user {.mytpch.f1.e3 get} mysql_tpch_pass {.mytpch.f1.e4 get} mysql_tpch_dbase {.mytpch.f1.e5 get} mysql_tpch_storage_engine {.mytpch.f1.e6 get} mysql_total_querysets {.mytpch.f1.e9 get} mysql_update_sets {.mytpch.f1.e13 get} mysql_trickle_refresh {.mytpch.f1.e14 get} mysql_scale_fact $mysql_scale_fact  mysql_num_tpch_threads $mysql_num_tpch_threads mysql_refresh_on $mysql_refresh_on mysql_raise_query_error $mysql_raise_query_error mysql_verbose $mysql_verbose mysql_refresh_verbose $mysql_refresh_verbose mysql_cloud_query $mysql_cloud_query} ]
   catch "destroy .mytpch"
   ttk::toplevel .mytpch
   wm transient .mytpch .ed_mainFrame
   wm withdraw .mytpch
switch $option {
"all" { wm title .mytpch {MySQL TPROC-H Schema Options} }
"build" { wm title .mytpch {MySQL TPROC-H Build Options} }
"drive" {  wm title .mytpch {MySQL TPROC-H Driver Options} }
	}
   set Parent .mytpch
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
   ttk::label $Prompt -text "MySQL Host :"
   ttk::entry $Name -width 30 -textvariable mysql_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "MySQL Port :"   
   ttk::entry $Name  -width 30 -textvariable mysql_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
   set Name $Parent.f1.e2a
   set Prompt $Parent.f1.p2a
   ttk::label $Prompt -text "MySQL Socket :"
   ttk::entry $Name  -width 30 -textvariable mysql_socket
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
   if {[string match windows $::tcl_platform(platform)]} {
        .mytpch.f1.e2a configure -state disabled
   }
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "MySQL User :"
   ttk::entry $Name  -width 30 -textvariable mysql_tpch_user
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "MySQL User Password :"   
   ttk::entry $Name  -width 30 -textvariable mysql_tpch_pass
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "TPROC-H MySQL Database :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable mysql_tpch_dbase
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "Data Warehouse Storage Engine :"
   ttk::entry $Name -width 30 -textvariable mysql_tpch_storage_engine
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7 
   ttk::label $Prompt -text "Scale Factor :"
   grid $Prompt -column 0 -row 8 -sticky e
   set Name $Parent.f1.f2
   ttk::frame $Name -width 30
   grid $Name -column 1 -row 8 -sticky ew
	set rcnt 1
	foreach item {1} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable mysql_scale_fact -text $item -value $item -width 1
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 2
	foreach item {10 30} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable mysql_scale_fact -text $item -value $item -width 2
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 4
	foreach item {100 300} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable mysql_scale_fact -text $item -value $item -width 3
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 6
	foreach item {1000} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable mysql_scale_fact -text $item -value $item -width 4
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
set Prompt $Parent.f1.p8
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e8
ttk::spinbox $Name -from 1 -to 512 -textvariable mysql_num_tpch_threads
	grid $Prompt -column 0 -row 9 -sticky e
	grid $Name -column 1 -row 9 -sticky ew
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
   set Name $Parent.f1.e9
   set Prompt $Parent.f1.p9
   ttk::label $Prompt -text "Total Query Sets per User :"
   ttk::entry $Name -width 30 -textvariable mysql_total_querysets
   grid $Prompt -column 0 -row 12 -sticky e
   grid $Name -column 1 -row 12  -columnspan 4 -sticky ew
 set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Exit on MySQL Error :"
  set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable mysql_raise_query_error -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 13 -sticky e
   grid $Name -column 1 -row 13 -sticky w
 set Prompt $Parent.f1.p11
ttk::label $Prompt -text "Verbose Output :"
  set Name $Parent.f1.e11
ttk::checkbutton $Name -text "" -variable mysql_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky w
 set Prompt $Parent.f1.p12
ttk::label $Prompt -text "Refresh Function :"
  set Name $Parent.f1.e12
ttk::checkbutton $Name -text "" -variable mysql_refresh_on -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky w
bind $Parent.f1.e12 <Button> {
if {$mysql_refresh_on eq "true"} { 
set mysql_refresh_verbose "false"
foreach field {e13 e14 e15} {
.mytpch.f1.$field configure -state disabled 
		}
} else {
foreach field {e13 e14 e15} {
.mytpch.f1.$field configure -state normal
                        }
                }
	}
   set Name $Parent.f1.e13
   set Prompt $Parent.f1.p13
   ttk::label $Prompt -text "Number of Update Sets :"
   ttk::entry $Name -width 30 -textvariable mysql_update_sets
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16  -columnspan 4 -sticky ew
if {$mysql_refresh_on == "false" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable mysql_trickle_refresh
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17  -columnspan 4 -sticky ew
if {$mysql_refresh_on == "false" } {
	$Name configure -state disabled
	}
 set Prompt $Parent.f1.p15
ttk::label $Prompt -text "Refresh Verbose :"
  set Name $Parent.f1.e15
ttk::checkbutton $Name -text "" -variable mysql_refresh_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky w
if {$mysql_refresh_on == "false" } {
	$Name configure -state disabled
	}
set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Cloud Analytic Queries :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable mysql_cloud_query -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky w
}
#This is the Cancel button variables stay as before
   set Name $Parent.b2
   ttk::button $Name -command {
unset myfields
destroy .mytpch
} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
#This is the OK button all variables loaded back into config dict
   set Name $Parent.b1
switch $option {
"drive" {
ttk::button $Name -command {
copyfieldstoconfig configmysql [ subst $myfields ] tpch
unset myfields
destroy .mytpch
loadtpch
} -text {OK}
        }
"default" {
   ttk::button $Name -command {
set mysql_num_tpch_threads [ verify_build_threads $mysql_num_tpch_threads 512 512 ]
copyfieldstoconfig configmysql [ subst $myfields ] tpch
unset myfields
destroy .mytpch
} -text {OK}
	}
}
   pack $Name -anchor nw -side right -padx 3 -pady 3
   wm geometry .mytpch +50+50
   wm deiconify .mytpch
   raise .mytpch
   update
}
