proc countpgopts { bm } { 
upvar #0 icons icons
upvar #0 configpostgresql configpostgresql
upvar #0 genericdict genericdict
global afval interval tclog uniquelog tcstamp
dict with genericdict { dict with transaction_counter {   
#variables for button options need to be global
set interval $tc_refresh_rate
set tclog $tc_log_to_temp
set uniquelog $tc_unique_log_name
set tcstamp $tc_log_timestamps
}}
setlocaltcountvars $configpostgresql 1
variable pgoptsfields
if { $bm eq "TPC-C" } {
variable pg_oracompat
if {[dict exists configpostgresql tpcc pg_oracompat ]} {
set pg_oracompat [ dict get configpostgresql tpcc pg_oracompat ]
	}
set pgoptsfields [ dict create connection {pg_host {.countopt.f1.e1 get} pg_port {.countopt.f1.e2 get} pg_sslmode $pg_sslmode} tpcc {pg_superuser {.countopt.f1.e3 get} pg_superuserpass {.countopt.f1.e4 get} pg_defaultdbase {.countopt.f1.e5 get}} ]
} else {
set pgoptsfields [ dict create connection {pg_host {.countopt.f1.e1 get} pg_port {.countopt.f1.e2 get} pg_sslmode $pg_sslmode} tpch {pg_tpch_superuser {.countopt.f1.e3 get} pg_tpch_superuserpass {.countopt.f1.e4 get} pg_tpch_defaultdbase {.countopt.f1.e5 get}} ]
}
if { [ info exists afval ] } {
        after cancel $afval
        unset afval
}

if { $bm eq "TPC-C" } {
if { $pg_oracompat eq "true" } {
if { $pg_port eq "5432" } { set pg_port "5444" }
if { $pg_superuser eq "postgres" } { set pg_superuser "enterprisedb" }
if { $pg_defaultdbase eq "postgres" } { set pg_defaultdbase "edb" }
	} else {
if { $pg_port eq "5444" } { set pg_port "5432" }
if { $pg_superuser eq "enterprisedb" } { set pg_superuser "postgres" }
if { $pg_defaultdbase eq "edb" } { set pg_defaultdbase "postgres" }
	}
} 

   catch "destroy .countopt"
   ttk::toplevel .countopt
   wm transient .countopt .ed_mainFrame
   wm withdraw .countopt
   wm title .countopt {PostgreSQL TX Counter Options}
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
   ttk::label $Prompt -text "PostgreSQL Host :"
   ttk::entry $Name -width 30 -textvariable pg_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "PostgreSQL Port :"   
   ttk::entry $Name  -width 30 -textvariable pg_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "PostgreSQL Superuser :"
if { $bm eq "TPC-C" } {
   ttk::entry $Name  -width 30 -textvariable pg_superuser
	} else {
   ttk::entry $Name  -width 30 -textvariable pg_tpch_superuser
	}
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "PostgreSQL Superuser Password :"   
if { $bm eq "TPC-C" } {
   ttk::entry $Name  -width 30 -textvariable pg_superuserpass
	} else {
   ttk::entry $Name  -width 30 -textvariable pg_tpch_superuserpass
	}
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "PostgreSQL Default Database :"
if { $bm eq "TPC-C" } {
   ttk::entry $Name -width 30 -textvariable pg_defaultdbase
	} else {
   ttk::entry $Name -width 30 -textvariable pg_tpch_defaultdbase
	}
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew

set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "Refresh Rate(secs) :"
   ttk::entry $Name -width 30 -textvariable interval
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew

set Prompt $Parent.f1.p6a
ttk::label $Prompt -text "Prefer PostgreSQL SSL Mode :"
set Name $Parent.f1.e6a
ttk::checkbutton $Name -text "" -variable pg_sslmode -onvalue "prefer" -offvalue "disable"
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky w

  set Name $Parent.f1.e7
ttk::checkbutton $Name -text "Log Output to Temp" -variable tclog -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 8 -sticky w
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
   grid $Name -column 1 -row 9 -sticky w
        if {$tclog == 0} {
        $Name configure -state disabled
        }

   set Name $Parent.f1.e9
ttk::checkbutton $Name -text "Log Timestamps" -variable tcstamp -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 10 -sticky w
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
unset pgoptsfields
destroy .countopt
} -text Cancel
 pack $Name -anchor nw -side right -padx 3 -pady 3

 set Name $Parent.b1
if { $bm eq "TPC-C" } {
   ttk::button $Name -command {
copyfieldstoconfig configpostgresql [ subst $pgoptsfields ] tpcc
unset pgoptsfields
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs" 
	dict set genericdict transaction_counter tc_refresh_rate 10
	   } else {
	dict with genericdict { dict with transaction_counter {
	set tc_refresh_rate [.countopt.f1.e6 get]
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
copyfieldstoconfig configpostgresql [ subst $pgoptsfields ] tpch
unset pgoptsfields
if { ($interval >= 60) || ($interval <= 0)  } { 
	tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs" 
	dict set genericdict transaction_counter tc_refresh_rate 10
	  } else {
	dict with genericdict { dict with transaction_counter {
	set tc_refresh_rate [.countopt.f1.e6 get]
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

proc configpgtpcc {option} {
upvar #0 icons icons
upvar #0 configpostgresql configpostgresql
#set variables to values in dict
setlocaltpccvars $configpostgresql
#set matching fields in dialog to temporary dict
variable pgfields
set pgfields [ dict create connection {pg_host {.tpc.f1.e1 get} pg_port {.tpc.f1.e2 get} pg_sslmode $pg_sslmode} tpcc {pg_superuser {.tpc.f1.e3 get} pg_superuserpass {.tpc.f1.e4 get} pg_defaultdbase {.tpc.f1.e5 get} pg_user {.tpc.f1.e6 get} pg_pass {.tpc.f1.e7 get} pg_dbase {.tpc.f1.e8 get} pg_tspace {.tpc.f1.e8a get} pg_total_iterations {.tpc.f1.e15 get} pg_rampup {.tpc.f1.e21 get} pg_duration {.tpc.f1.e22 get} pg_async_client {.tpc.f1.e26 get} pg_async_delay {.tpc.f1.e27 get} pg_count_ware $pg_count_ware pg_vacuum $pg_vacuum pg_dritasnap $pg_dritasnap pg_oracompat $pg_oracompat pg_storedprocs $pg_storedprocs pg_partition $pg_partition pg_num_vu $pg_num_vu pg_total_iterations $pg_total_iterations pg_raiseerror $pg_raiseerror pg_keyandthink $pg_keyandthink pg_driver $pg_driver pg_rampup $pg_rampup pg_duration $pg_duration pg_allwarehouse $pg_allwarehouse pg_timeprofile $pg_timeprofile pg_async_scale $pg_async_scale pg_connect_pool $pg_connect_pool pg_async_verbose $pg_async_verbose}]
set whlist [ get_warehouse_list_for_spinbox ]
if { $pg_oracompat eq "true" } {
if { $pg_port eq "5432" } { set pg_port "5444" }
if { $pg_superuser eq "postgres" } { set pg_superuser "enterprisedb" }
if { $pg_defaultdbase eq "postgres" } { set pg_defaultdbase "edb" }
if { $pg_storedprocs eq "true" } { set pg_storedprocs "false" }
	} else {
if { $pg_port eq "5444" } { set pg_port "5432" }
if { $pg_superuser eq "enterprisedb" } { set pg_superuser "postgres" }
if { $pg_defaultdbase eq "edb" } { set pg_defaultdbase "postgres" }
	}
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm transient .tpc .ed_mainFrame
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {PostgreSQL TPROC-C Schema Options} }
"build" { wm title .tpc {PostgreSQL TPROC-C Build Options} }
"drive" {  wm title .tpc {PostgreSQL TPROC-C Driver Options} }
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
   ttk::label $Prompt -text "PostgreSQL Host :"
   ttk::entry $Name -width 30 -textvariable pg_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "PostgreSQL Port :"   
   ttk::entry $Name  -width 30 -textvariable pg_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "PostgreSQL Superuser :"
   ttk::entry $Name  -width 30 -textvariable pg_superuser
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "PostgreSQL Superuser Password :"   
   ttk::entry $Name  -width 30 -textvariable pg_superuserpass
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "PostgreSQL Default Database :"
   ttk::entry $Name -width 30 -textvariable pg_defaultdbase
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "TPROC-C PostgreSQL User :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name  -width 30 -textvariable pg_user
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7
   ttk::label $Prompt -text "TPROC-C PostgreSQL User Password :" -image [ create_image hdbicon icons ] -compound left 
   ttk::entry $Name  -width 30 -textvariable pg_pass
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
set Name $Parent.f1.e8
   set Prompt $Parent.f1.p8
   ttk::label $Prompt -text "TPROC-C PostgreSQL Database :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable pg_dbase
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e8a
   set Prompt $Parent.f1.p8a
   ttk::label $Prompt -text "TPROC-C PostgreSQL Tablespace :" -image [ create_image hdbicon icons ] -compound left 
   ttk::entry $Name -width 30 -textvariable pg_tspace
   grid $Prompt -column 0 -row 9 -sticky e
   grid $Name -column 1 -row 9 -sticky ew
   }
set Prompt $Parent.f1.p9
ttk::label $Prompt -text "EnterpriseDB Oracle Compatible :"
set Name $Parent.f1.e9
ttk::checkbutton $Name -text "" -variable pg_oracompat -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
bind .tpc.f1.e9 <Button> { 
if { $pg_oracompat != "true" } {
if { $pg_port eq "5432" } { set pg_port "5444" }
if { $pg_superuser eq "postgres" } { set pg_superuser "enterprisedb" }
if { $pg_defaultdbase eq "postgres" } { set pg_defaultdbase "edb" }
if { $pg_storedprocs eq "true" } { set pg_storedprocs "false" }
.tpc.f1.e9a configure -state disabled
	} else {
if { $pg_port eq "5444" } { set pg_port "5432" }
if { $pg_superuser eq "enterprisedb" } { set pg_superuser "postgres" }
if { $pg_defaultdbase eq "edb" } { set pg_defaultdbase "postgres" }
.tpc.f1.e9a configure -state normal
	}
}
set Prompt $Parent.f1.p9a
ttk::label $Prompt -text "PostgreSQL Stored Procedures :"
set Name $Parent.f1.e9a
ttk::checkbutton $Name -text "" -variable pg_storedprocs -onvalue "true" -offvalue "false"
if {$pg_oracompat == "true" } {
	$Name configure -state disabled
	}
   grid $Prompt -column 0 -row 11 -sticky e
   grid $Name -column 1 -row 11 -sticky w
set Prompt $Parent.f1.p9b
ttk::label $Prompt -text "Prefer PostgreSQL SSL Mode :"
set Name $Parent.f1.e9b
ttk::checkbutton $Name -text "" -variable pg_sslmode -onvalue "prefer" -offvalue "disable"
   grid $Prompt -column 0 -row 12 -sticky e
   grid $Name -column 1 -row 12 -sticky w
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e10
ttk::spinbox $Name -value $whlist -textvariable pg_count_ware
bind .tpc.f1.e10 <<Any-Button-Any-Key>> {
if {$pg_num_vu > $pg_count_ware} {
set pg_num_vu $pg_count_ware
		}
if {$pg_count_ware < 200} {
.tpc.f1.e11a configure -state disabled
set pg_partition "false"
        } else {
.tpc.f1.e11a configure -state enabled
        }
}
	grid $Prompt -column 0 -row 13 -sticky e
	grid $Name -column 1 -row 13 -sticky ew
set Prompt $Parent.f1.p11
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e11
ttk::spinbox $Name -from 1 -to 512 -textvariable pg_num_vu
bind .tpc.f1.e11 <<Any-Button-Any-Key>> {
if {$pg_num_vu > $pg_count_ware} {
set pg_num_vu $pg_count_ware
                }
        }
event add <<Any-Button-Any-Key>> <Any-ButtonRelease>
event add <<Any-Button-Any-Key>> <KeyRelease>
grid $Prompt -column 0 -row 14 -sticky e
grid $Name -column 1 -row 14 -sticky ew
set Prompt $Parent.f1.p11a
ttk::label $Prompt -text "Partition Order Line Table :"
set Name $Parent.f1.e11a
ttk::checkbutton $Name -text "" -variable pg_partition -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky w
if {$pg_count_ware < 200 } {
        $Name configure -state disabled
        }
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
set Prompt $Parent.f1.p14
ttk::label $Prompt -text "TPROC-C Driver Script :" -image [ create_image hdbicon icons ] -compound left
grid $Prompt -column 0 -row 17 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "test" -text "Test Driver Script" -variable pg_driver
grid $Name -column 1 -row 17 -sticky w
bind .tpc.f1.r1 <ButtonPress-1> {
set pg_vacuum "false"
set pg_dritasnap "false"
set pg_allwarehouse "false"
set pg_timeprofile "false"
set pg_async_scale "false"
set pg_async_verbose "false"
.tpc.f1.e19 configure -state disabled
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
ttk::radiobutton $Name -value "timed" -text "Timed Driver Script" -variable pg_driver
grid $Name -column 1 -row 18 -sticky w
bind .tpc.f1.r2 <ButtonPress-1> {
.tpc.f1.e19 configure -state normal
.tpc.f1.e20 configure -state normal
.tpc.f1.e21 configure -state normal
.tpc.f1.e22 configure -state normal
.tpc.f1.e23 configure -state normal
.tpc.f1.e24 configure -state normal
.tpc.f1.e25 configure -state normal
if { $pg_async_scale eq "true" } {
.tpc.f1.e26 configure -state normal
.tpc.f1.e27 configure -state normal
.tpc.f1.e28 configure -state normal
    }
}
set Name $Parent.f1.e15
   set Prompt $Parent.f1.p15
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable pg_total_iterations
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky ew
 set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Exit on PostgreSQL Error :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable pg_raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky w
 set Prompt $Parent.f1.p17
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.e17
ttk::checkbutton $Name -text "" -variable pg_keyandthink -onvalue "true" -offvalue "false"
bind .tpc.f1.e17 <Any-ButtonRelease> {
if { $pg_driver eq "timed" } {
if { $pg_keyandthink eq "true" } {
set pg_async_scale "false"
set pg_async_verbose "false"
.tpc.f1.e26 configure -state disabled
.tpc.f1.e27 configure -state disabled
.tpc.f1.e28 configure -state disabled
        }
    }
}
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21 -sticky w
set Prompt $Parent.f1.p19
ttk::label $Prompt -text "Vacuum when complete :"
set Name $Parent.f1.e19
ttk::checkbutton $Name -text "" -variable pg_vacuum -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 22 -sticky e
   grid $Name -column 1 -row 22 -sticky w
if {$pg_driver == "test" } {
	$Name configure -state disabled
	}
set Prompt $Parent.f1.p20
ttk::label $Prompt -text "EnterpriseDB DRITA Snapshots :"
set Name $Parent.f1.e20
ttk::checkbutton $Name -text "" -variable pg_dritasnap -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 23 -sticky e
   grid $Name -column 1 -row 23 -sticky w
if {$pg_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e21
   set Prompt $Parent.f1.p21
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable pg_rampup
   grid $Prompt -column 0 -row 24 -sticky e
   grid $Name -column 1 -row 24 -sticky ew
if {$pg_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e22
   set Prompt $Parent.f1.p22
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable pg_duration
   grid $Prompt -column 0 -row 25 -sticky e
   grid $Name -column 1 -row 25 -sticky ew
if {$pg_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e23
   set Prompt $Parent.f1.p23
   ttk::label $Prompt -text "Use All Warehouses :"
   ttk::checkbutton $Name -text "" -variable pg_allwarehouse -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 26 -sticky e
   grid $Name -column 1 -row 26 -sticky ew
if {$pg_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e24
   set Prompt $Parent.f1.p24
   ttk::label $Prompt -text "Time Profile :"
   ttk::checkbutton $Name -text "" -variable pg_timeprofile -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 27 -sticky e
   grid $Name -column 1 -row 27 -sticky ew
if {$pg_driver == "test" } {
	$Name configure -state disabled
	}
  set Name $Parent.f1.e25
   set Prompt $Parent.f1.p25
   ttk::label $Prompt -text "Asynchronous Scaling :"
ttk::checkbutton $Name -text "" -variable pg_async_scale -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 28 -sticky e
   grid $Name -column 1 -row 28 -sticky ew
if {$pg_driver == "test" } {
        set pg_async_scale "false"
        $Name configure -state disabled
        }
bind .tpc.f1.e25 <Any-ButtonRelease> {
if { $pg_async_scale eq "true" } {
set pg_async_verbose "false"
.tpc.f1.e26 configure -state disabled
.tpc.f1.e27 configure -state disabled
.tpc.f1.e28 configure -state disabled
        } else {
if { $pg_driver eq "timed" } {
set pg_keyandthink "true"
.tpc.f1.e26 configure -state normal
.tpc.f1.e27 configure -state normal
.tpc.f1.e28 configure -state normal
                }
        }
}
set Name $Parent.f1.e26
   set Prompt $Parent.f1.p26
   ttk::label $Prompt -text "Asynch Clients per Virtual User :"
   ttk::entry $Name -width 30 -textvariable pg_async_client
   grid $Prompt -column 0 -row 29 -sticky e
   grid $Name -column 1 -row 29 -sticky ew
if {$pg_driver == "test" || $pg_async_scale == "false" } {
        $Name configure -state disabled
        }
set Name $Parent.f1.e27
   set Prompt $Parent.f1.p27
   ttk::label $Prompt -text "Asynch Client Login Delay :"
   ttk::entry $Name -width 30 -textvariable pg_async_delay
   grid $Prompt -column 0 -row 30 -sticky e
   grid $Name -column 1 -row 30 -sticky ew
if {$pg_driver == "test" || $pg_async_scale == "false" } {
        $Name configure -state disabled
        }
   set Name $Parent.f1.e28
   set Prompt $Parent.f1.p28
   ttk::label $Prompt -text "Asynchronous Verbose :"
ttk::checkbutton $Name -text "" -variable pg_async_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 31 -sticky e
   grid $Name -column 1 -row 31 -sticky ew
if {$pg_driver == "test" || $pg_async_scale == "false" } {
        set pg_async_verbose "false"
        $Name configure -state disabled
        }
   set Name $Parent.f1.e29
   set Prompt $Parent.f1.p29
   ttk::label $Prompt -text "XML Connect Pool :"
ttk::checkbutton $Name -text "" -variable pg_connect_pool -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 32 -sticky e
   grid $Name -column 1 -row 32 -sticky ew
}
#This is the Cancel button variables stay as before
set Name $Parent.b2
   ttk::button $Name -command {
   unset pgfields
   destroy .tpc
} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
#This is the OK button all variables loaded back into config dict
set Name $Parent.b1
switch $option {
"drive" {
ttk::button $Name -command {
copyfieldstoconfig configpostgresql [ subst $pgfields ] tpcc
unset pgfields
destroy .tpc
loadtpcc
} -text {OK}
        }
"default" {
   ttk::button $Name -command {
set pg_count_ware [ verify_warehouse $pg_count_ware 100000 ]
set pg_num_vu [ verify_build_threads $pg_num_vu $pg_count_ware 1024 ]
copyfieldstoconfig configpostgresql [ subst $pgfields ] tpcc
unset pgfields
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

proc configpgtpch {option} {
upvar #0 icons icons
upvar #0 configpostgresql configpostgresql
#set variables to values in dict
setlocaltpchvars $configpostgresql
#set matching fields in dialog to temporary dict
variable pgfields
set pgfields [ dict create connection {pg_host {.pgtpch.f1.e1 get} pg_port {.pgtpch.f1.e2 get} pg_sslmode $pg_sslmode} tpch {pg_tpch_superuser {.pgtpch.f1.e3 get} pg_tpch_superuserpass {.pgtpch.f1.e4 get} pg_tpch_defaultdbase {.pgtpch.f1.e5 get} pg_tpch_user {.pgtpch.f1.e6 get} pg_tpch_pass {.pgtpch.f1.e7 get} pg_tpch_dbase {.pgtpch.f1.e8 get} pg_tpch_tspace {.pgtpch.f1.e8a get} pg_num_tpch_threads {.pgtpch.f1.e12 get} pg_total_querysets {.pgtpch.f1.e14 get} pg_degree_of_parallel {.pgtpch.f1.e16a get} pg_update_sets {.pgtpch.f1.e18 get} pg_trickle_refresh {.pgtpch.f1.e19 get} pg_scale_fact $pg_scale_fact pg_tpch_gpcompat $pg_tpch_gpcompat pg_tpch_gpcompress $pg_tpch_gpcompress pg_raise_query_error $pg_raise_query_error pg_verbose $pg_verbose pg_refresh_on $pg_refresh_on pg_refresh_verbose $pg_refresh_verbose pg_cloud_query $pg_cloud_query pg_rs_compat $pg_rs_compat}]
   catch "destroy .pgtpch"
   ttk::toplevel .pgtpch
   wm transient .pgtpch .ed_mainFrame
   wm withdraw .pgtpch
switch $option {
"all" { wm title .pgtpch {PostgreSQL TPROC-H Schema Options} }
"build" { wm title .pgtpch {PostgreSQL TPROC-H Build Options} }
"drive" {  wm title .pgtpch {PostgreSQL TPROC-H Driver Options} }
	}
   set Parent .pgtpch
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
   ttk::label $Prompt -text "PostgreSQL Host :"
   ttk::entry $Name -width 30 -textvariable pg_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "PostgreSQL Port :"
   ttk::entry $Name  -width 30 -textvariable pg_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "PostgreSQL Superuser :"
   ttk::entry $Name  -width 30 -textvariable pg_tpch_superuser
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "PostgreSQL Superuser Password :"
   ttk::entry $Name  -width 30 -textvariable pg_tpch_superuserpass
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "PostgreSQL Default Database :"
   ttk::entry $Name -width 30 -textvariable pg_tpch_defaultdbase
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
	}
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
 ttk::label $Prompt -text "TPROC-H PostgreSQL User :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name  -width 30 -textvariable pg_tpch_user
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7
   ttk::label $Prompt -text "TPROC-H PostgreSQL User Password :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name  -width 30 -textvariable pg_tpch_pass
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
set Name $Parent.f1.e8
   set Prompt $Parent.f1.p8
   ttk::label $Prompt -text "TPROC-H PostgreSQL Database :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable pg_tpch_dbase
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky ew
set Prompt $Parent.f1.p8b
ttk::label $Prompt -text "Prefer PostgreSQL SSL Mode :"
set Name $Parent.f1.e8b
ttk::checkbutton $Name -text "" -variable pg_sslmode -onvalue "prefer" -offvalue "disable"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e8a
   set Prompt $Parent.f1.p8a
   ttk::label $Prompt -text "TPROC-H PostgreSQL Tablespace :" -image [ create_image hdbicon icons ] -compound left
   ttk::entry $Name -width 30 -textvariable pg_tpch_tspace
   grid $Prompt -column 0 -row 9 -sticky e
   grid $Name -column 1 -row 9 -sticky ew
set Prompt $Parent.f1.p9
ttk::label $Prompt -text "Greenplum Database Compatible :"
set Name $Parent.f1.e9
ttk::checkbutton $Name -text "" -variable pg_tpch_gpcompat -onvalue "true" -offvalue "false"
bind $Parent.f1.e9 <Button> {
if {$pg_tpch_gpcompat eq "true"} { 
.pgtpch.f1.e10 configure -state disabled 
set pg_tpch_gpcompress "false"
} else {
.pgtpch.f1.e10 configure -state normal
                }
	}
   grid $Prompt -column 0 -row 11 -sticky e
   grid $Name -column 1 -row 11 -sticky w
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Greenplum Compressed Columns :"
set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable pg_tpch_gpcompress -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 12 -sticky e
   grid $Name -column 1 -row 12 -sticky w
if {$pg_tpch_gpcompat == "false" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e11
   set Prompt $Parent.f1.p11
   ttk::label $Prompt -text "Scale Factor :"
   grid $Prompt -column 0 -row 13 -sticky e
   set Name $Parent.f1.f2
   ttk::frame $Name -width 30
   grid $Name -column 1 -row 13 -sticky ew
	set rcnt 1
	foreach item {1} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable pg_scale_fact -text $item -value $item -width 1
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 2
	foreach item {10 30} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable pg_scale_fact -text $item -value $item -width 2
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 4
	foreach item {100 300} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable pg_scale_fact -text $item -value $item -width 3
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 6
	foreach item {1000} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable pg_scale_fact -text $item -value $item -width 4
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
set Prompt $Parent.f1.p12
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e12
ttk::spinbox $Name -from 1 -to 512 -textvariable pg_num_tpch_threads
	grid $Prompt -column 0 -row 14 -sticky e
	grid $Name -column 1 -row 14 -sticky ew
	}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [ create_image driveroptlo icons ]
grid $Prompt -column 0 -row 15 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 15 -sticky w
	}
   set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Total Query Sets per User :"
   ttk::entry $Name -width 30 -textvariable pg_total_querysets
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16  -columnspan 4 -sticky ew
 set Prompt $Parent.f1.p15
ttk::label $Prompt -text "Exit on PostgreSQL Error :"
  set Name $Parent.f1.e15
ttk::checkbutton $Name -text "" -variable pg_raise_query_error -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17 -sticky w
 set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Verbose Output :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable pg_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky w
set Name $Parent.f1.e16a
   set Prompt $Parent.f1.p16a
   ttk::label $Prompt -text "Degree of Parallelism :"
   ttk::entry $Name  -width 30 -textvariable pg_degree_of_parallel
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky ew
 set Prompt $Parent.f1.p17
ttk::label $Prompt -text "Refresh Function :"
  set Name $Parent.f1.e17
ttk::checkbutton $Name -text "" -variable pg_refresh_on -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky w
bind $Parent.f1.e17 <Button> {
if {$pg_refresh_on eq "true"} { 
set pg_refresh_verbose "false"
foreach field {e18 e19 e20} {
.pgtpch.f1.$field configure -state disabled 
		}
} else {
foreach field {e18 e19 e20} {
.pgtpch.f1.$field configure -state normal
                        }
                }
	}
   set Name $Parent.f1.e18
   set Prompt $Parent.f1.p18
   ttk::label $Prompt -text "Number of Update Sets :"
   ttk::entry $Name -width 30 -textvariable pg_update_sets
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21  -columnspan 4 -sticky ew
if {$pg_refresh_on == "false" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e19
   set Prompt $Parent.f1.p19
   ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable pg_trickle_refresh
   grid $Prompt -column 0 -row 22 -sticky e
   grid $Name -column 1 -row 22  -columnspan 4 -sticky ew
if {$pg_refresh_on == "false" } {
	$Name configure -state disabled
	}
 set Prompt $Parent.f1.p20
ttk::label $Prompt -text "Refresh Verbose :"
  set Name $Parent.f1.e20
ttk::checkbutton $Name -text "" -variable pg_refresh_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 23 -sticky e
   grid $Name -column 1 -row 23 -sticky w
if {$pg_refresh_on == "false" } {
	$Name configure -state disabled
	}
set Prompt $Parent.f1.p21
ttk::label $Prompt -text "Cloud Analytic Queries :"
  set Name $Parent.f1.e21
ttk::checkbutton $Name -text "" -variable pg_cloud_query -onvalue "true" -offvalue "false"
bind $Parent.f1.e21 <Button> {
if {$pg_cloud_query eq "true"} { 
.pgtpch.f1.e22 configure -state disabled 
set pg_rs_compat "false"
} else {
.pgtpch.f1.e22 configure -state normal
                }
	}
   grid $Prompt -column 0 -row 24 -sticky e
   grid $Name -column 1 -row 24 -sticky w
set Prompt $Parent.f1.p22
ttk::label $Prompt -text "Redshift Compatible :"
set Name $Parent.f1.e22
ttk::checkbutton $Name -text "" -variable pg_rs_compat -onvalue "true" -offvalue "false"
if {$pg_cloud_query == "false" } {
	$Name configure -state disabled
	}
grid $Prompt -column 0 -row 25 -sticky e
grid $Name -column 1 -row 25 -sticky w
}
   set Name $Parent.b2
 ttk::button $Name -command {
unset pgfields
destroy .pgtpch
} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
#This is the OK button all variables loaded back into config dict
   set Name $Parent.b1
switch $option {
"drive" {
ttk::button $Name -command {
copyfieldstoconfig configpostgresql [ subst $pgfields ] tpch
unset pgfields
destroy .pgtpch
loadtpch
} -text {OK}
        }
"default" {
   ttk::button $Name -command {
set pg_num_tpch_threads [ verify_build_threads $pg_num_tpch_threads 512 512 ]
copyfieldstoconfig configpostgresql [ subst $pgfields ] tpch
unset pgfields
destroy .pgtpch
} -text {OK}
        }
}
   pack $Name -anchor nw -side right -padx 3 -pady 3
   wm geometry .pgtpch +50+50
   wm deiconify .pgtpch
   raise .pgtpch
   update
}

proc metpgopts {} { 
global agent_hostname agent_id bm
upvar #0 icons icons
upvar #0 configpostgresql configpostgresql
setlocaltcountvars $configpostgresql 1
variable pgoptsfields
if { $bm eq "TPC-C" } {
variable pg_oracompat
if {[dict exists configpostgresql tpcc pg_oracompat ]} {
set pg_oracompat [ dict get configpostgresql tpcc pg_oracompat ]
	}
set pgoptsfields [ dict create connection {pg_host {.metric.f1.e1 get} pg_port {.metric.f1.e2 get} pg_sslmode $pg_sslmode} tpcc {pg_superuser {.metric.f1.e3 get} pg_superuserpass {.metric.f1.e4 get} pg_defaultdbase {.metric.f1.e5 get}} ]
} else {
set pgoptsfields [ dict create connection {pg_host {.metric.f1.e1 get} pg_port {.metric.f1.e2 get} pg_sslmode $pg_sslmode} tpch {pg_tpch_superuser {.metric.f1.e3 get} pg_tpch_superuserpass {.metric.f1.e4 get} pg_tpch_defaultdbase {.metric.f1.e5 get}} ]
}
if { $bm eq "TPC-C" } {
if { $pg_oracompat eq "true" } {
if { $pg_port eq "5432" } { set pg_port "5444" }
if { $pg_superuser eq "postgres" } { set pg_superuser "enterprisedb" }
if { $pg_defaultdbase eq "postgres" } { set pg_defaultdbase "edb" }
	} else {
if { $pg_port eq "5444" } { set pg_port "5432" }
if { $pg_tpch_superuser eq "enterprisedb" } { set pg_tpch_superuser "postgres" }
if { $pg_defaultdbase eq "edb" } { set pg_defaultdbase "postgres" }
	}
} 
if {  [ info exists agent_hostname ] } { ; } else { set agent_hostname "localhost" }
if {  [ info exists agent_id ] } { ; } else { set agent_id 0 }
set old_agent $agent_hostname
set old_id $agent_id
   catch "destroy .metric"
   ttk::toplevel .metric
   wm transient .metric .ed_mainFrame
   wm withdraw .metric
   wm title .metric {PostgreSQL Metrics Options}
   set Parent .metric
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [ create_image dashboard icons ]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "PostgreSQL and OS Agent"
grid $Prompt -column 1 -row 0 -sticky w
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "PostgreSQL Host :"
   ttk::entry $Name -width 30 -textvariable pg_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "PostgreSQL Port :"   
   ttk::entry $Name  -width 30 -textvariable pg_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "PostgreSQL Superuser :"
if { $bm eq "TPC-C" } {
   ttk::entry $Name  -width 30 -textvariable pg_superuser
	} else {
   ttk::entry $Name  -width 30 -textvariable pg_tpch_superuser
	}
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "PostgreSQL Superuser Password :"   
if { $bm eq "TPC-C" } {
   ttk::entry $Name  -width 30 -textvariable pg_superuserpass
	} else {
   ttk::entry $Name  -width 30 -textvariable pg_tpch_superuserpass
	}
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "PostgreSQL Default Database :"
if { $bm eq "TPC-C" } {
   ttk::entry $Name -width 30 -textvariable pg_defaultdbase
	} else {
   ttk::entry $Name -width 30 -textvariable pg_tpch_defaultdbase
	}
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
set Prompt $Parent.f1.p6
ttk::label $Prompt -text "Prefer PostgreSQL SSL Mode :"
set Name $Parent.f1.e6
ttk::checkbutton $Name -text "" -variable pg_sslmode -onvalue "prefer" -offvalue "disable"
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky w
   set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7
   ttk::label $Prompt -text "Agent ID :"
   ttk::entry $Name -width 30 -textvariable agent_id
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7
   set Name $Parent.f1.e8
   set Prompt $Parent.f1.p8
   ttk::label $Prompt -text "Agent Hostname :"
   ttk::entry $Name -width 30 -textvariable agent_hostname
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8
set Name $Parent.b4
   ttk::button $Name -command { destroy .metric } -text Cancel
   pack $Name -anchor w -side right -padx 3 -pady 3
   set Name $Parent.b5
   ttk::button $Name -command {
         set agent_id [.metric.f1.e7 get]
         set agent_hostname [.metric.f1.e8 get]
if { $bm eq "TPC-C" } {
copyfieldstoconfig configpostgresql [ subst $pgoptsfields ] tpcc
unset pgoptsfields
} else {
copyfieldstoconfig configpostgresql [ subst $pgoptsfields ] tpch
unset pgoptsfields
	}
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
