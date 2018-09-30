proc countpgopts { bm } { 
upvar #0 icons icons
upvar #0 configpostgresql configpostgresql
upvar #0 genericdict genericdict
global afval interval

setlocaltcountvars $configpostgresql 1
variable pgoptsfields
if { $bm eq "TPC-C" } {
variable pg_oracompat
if {[dict exists configpostgresql tpcc pg_oracompat ]} {
set pg_oracompat [ dict get configpostgresql tpcc pg_oracompat ]
	}
set pgoptsfields [ dict create connection {pg_host {.countopt.f1.e1 get} pg_port {.countopt.f1.e2 get}} tpcc {pg_superuser {.countopt.f1.e3 get} pg_superuserpass {.countopt.f1.e4 get} pg_defaultdbase {.countopt.f1.e5 get}} ]
} else {
set pgoptsfields [ dict create connection {pg_host {.countopt.f1.e1 get} pg_port {.countopt.f1.e2 get}} tpch {pg_tpch_superuser {.countopt.f1.e3 get} pg_tpch_superuserpass {.countopt.f1.e4 get} pg_tpch_defaultdbase {.countopt.f1.e5 get}} ]
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
   wm withdraw .countopt
   wm title .countopt {PostgreSQL TX Counter Options}
   set Parent .countopt
   set Name $Parent.f1
   ttk::frame $Name 
   pack $Name -anchor nw -fill x -side top -padx 5
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data [ dict get $icons pencil]]
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
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh 
rate must be more than 0 secs and less than 60 secs" 
	set interval 10 } else {
	dict set genericdict transaction_counter refresh_rate [.countopt.f1.e6 get]
	}
         destroy .countopt
	   catch "destroy .tc"
            } -text {OK}
} else {
   ttk::button $Name -command {
copyfieldstoconfig configpostgresql [ subst $pgoptsfields ] tpch
unset pgoptsfields
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh 
rate must be more than 0 secs and less than 60 secs" 
	set interval 10 } else {
	dict set genericdict transaction_counter refresh_rate [.countopt.f1.e6 get]
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
set pgfields [ dict create connection {pg_host {.tpc.f1.e1 get} pg_port {.tpc.f1.e2 get}} tpcc {pg_superuser {.tpc.f1.e3 get} pg_superuserpass {.tpc.f1.e4 get} pg_defaultdbase {.tpc.f1.e5 get} pg_user {.tpc.f1.e6 get} pg_pass {.tpc.f1.e7 get} pg_dbase {.tpc.f1.e8 get} pg_total_iterations {.tpc.f1.e15 get} pg_rampup {.tpc.f1.e21 get} pg_duration {.tpc.f1.e22 get} pg_count_ware $pg_count_ware pg_vacuum $pg_vacuum pg_dritasnap $pg_dritasnap pg_oracompat $pg_oracompat pg_num_vu $pg_num_vu pg_total_iterations $pg_total_iterations pg_raiseerror $pg_raiseerror pg_keyandthink $pg_keyandthink pg_driver $pg_driver pg_rampup $pg_rampup pg_duration $pg_duration pg_allwarehouse $pg_allwarehouse pg_timeprofile $pg_timeprofile}]
set whlist [ get_warehouse_list_for_spinbox ]
if { $pg_oracompat eq "true" } {
if { $pg_port eq "5432" } { set pg_port "5444" }
if { $pg_superuser eq "postgres" } { set pg_superuser "enterprisedb" }
if { $pg_defaultdbase eq "postgres" } { set pg_defaultdbase "edb" }
	} else {
if { $pg_port eq "5444" } { set pg_port "5432" }
if { $pg_superuser eq "enterprisedb" } { set pg_superuser "postgres" }
if { $pg_defaultdbase eq "edb" } { set pg_defaultdbase "postgres" }
	}
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {PostgreSQL TPC-C Schema Options} }
"build" { wm title .tpc {PostgreSQL TPC-C Build Options} }
"drive" {  wm title .tpc {PostgreSQL TPC-C Driver Options} }
	}
   set Parent .tpc
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data [ dict get $icons boxes ]]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data [ dict get $icons driveroptlo ]]
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
   ttk::label $Prompt -text "PostgreSQL User :"
   ttk::entry $Name  -width 30 -textvariable pg_user
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7
   ttk::label $Prompt -text "PostgreSQL User Password :"   
   ttk::entry $Name  -width 30 -textvariable pg_pass
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
set Name $Parent.f1.e8
   set Prompt $Parent.f1.p8
   ttk::label $Prompt -text "PostgreSQL Database :"
   ttk::entry $Name -width 30 -textvariable pg_dbase
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky ew
set Prompt $Parent.f1.p9
ttk::label $Prompt -text "EnterpriseDB Oracle Compatible :"
set Name $Parent.f1.e9
ttk::checkbutton $Name -text "" -variable pg_oracompat -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 9 -sticky e
   grid $Name -column 1 -row 9 -sticky w
bind .tpc.f1.e9 <Button> { 
if { $pg_oracompat != "true" } {
if { $pg_port eq "5432" } { set pg_port "5444" }
if { $pg_superuser eq "postgres" } { set pg_superuser "enterprisedb" }
if { $pg_defaultdbase eq "postgres" } { set pg_defaultdbase "edb" }
	} else {
if { $pg_port eq "5444" } { set pg_port "5432" }
if { $pg_superuser eq "enterprisedb" } { set pg_superuser "postgres" }
if { $pg_defaultdbase eq "edb" } { set pg_defaultdbase "postgres" }
	}
}
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e10
ttk::spinbox $Name -value $whlist -textvariable pg_count_ware
bind .tpc.f1.e10 <<Any-Button-Any-Key>> {
if {$pg_num_vu > $pg_count_ware} {
set pg_num_vu $pg_count_ware
		}
}
	grid $Prompt -column 0 -row 10 -sticky e
	grid $Name -column 1 -row 10 -sticky ew
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
grid $Prompt -column 0 -row 12 -sticky e
grid $Name -column 1 -row 12 -sticky ew
}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data [ dict get $icons driveroptlo ]]
grid $Prompt -column 0 -row 13 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 13 -sticky w
	}
set Prompt $Parent.f1.p14
ttk::label $Prompt -text "TPC-C Driver Script :"
grid $Prompt -column 0 -row 13 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "test" -text "Test Driver Script" -variable pg_driver
grid $Name -column 1 -row 13 -sticky w
bind .tpc.f1.r1 <ButtonPress-1> {
set pg_vacuum "false"
set pg_dritasnap "false"
set pg_allwarehouse "false"
set pg_timeprofile "false"
.tpc.f1.e19 configure -state disabled
.tpc.f1.e20 configure -state disabled
.tpc.f1.e21 configure -state disabled
.tpc.f1.e22 configure -state disabled
.tpc.f1.e23 configure -state disabled
.tpc.f1.e24 configure -state disabled
}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "timed" -text "Timed Driver Script" -variable pg_driver
grid $Name -column 1 -row 14 -sticky w
bind .tpc.f1.r2 <ButtonPress-1> {
.tpc.f1.e19 configure -state normal
.tpc.f1.e20 configure -state normal
.tpc.f1.e21 configure -state normal
.tpc.f1.e22 configure -state normal
.tpc.f1.e23 configure -state normal
.tpc.f1.e24 configure -state normal
}
set Name $Parent.f1.e15
   set Prompt $Parent.f1.p15
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable pg_total_iterations
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky ew
 set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Exit on PostgreSQL Error :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable pg_raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16 -sticky w
 set Prompt $Parent.f1.p17
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.e17
ttk::checkbutton $Name -text "" -variable pg_keyandthink -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky w
set Prompt $Parent.f1.p19
ttk::label $Prompt -text "Vacuum when complete :"
set Name $Parent.f1.e19
ttk::checkbutton $Name -text "" -variable pg_vacuum -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky w
if {$pg_driver == "test" } {
	$Name configure -state disabled
	}
set Prompt $Parent.f1.p20
ttk::label $Prompt -text "EnterpriseDB DRITA Snapshots :"
set Name $Parent.f1.e20
ttk::checkbutton $Name -text "" -variable pg_dritasnap -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky w
if {$pg_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e21
   set Prompt $Parent.f1.p21
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable pg_rampup
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21 -sticky ew
if {$pg_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e22
   set Prompt $Parent.f1.p22
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable pg_duration
   grid $Prompt -column 0 -row 22 -sticky e
   grid $Name -column 1 -row 22 -sticky ew
if {$pg_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e23
   set Prompt $Parent.f1.p23
   ttk::label $Prompt -text "Use All Warehouses :"
   ttk::checkbutton $Name -text "" -variable pg_allwarehouse -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 23 -sticky e
   grid $Name -column 1 -row 23 -sticky ew
if {$pg_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e24
   set Prompt $Parent.f1.p24
   ttk::label $Prompt -text "Time Profile :"
   ttk::checkbutton $Name -text "" -variable pg_timeprofile -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 24 -sticky e
   grid $Name -column 1 -row 24 -sticky ew
if {$pg_driver == "test" } {
	$Name configure -state disabled
	}
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
set pg_count_ware [ verify_warehouse $pg_count_ware 5000 ]
set pg_num_vu [ verify_build_threads $pg_num_vu $pg_count_ware 512 ]
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
set pgfields [ dict create connection {pg_host {.pgtpch.f1.e1 get} pg_port {.pgtpch.f1.e2 get}} tpch {pg_tpch_superuser {.pgtpch.f1.e3 get} pg_tpch_superuserpass {.pgtpch.f1.e4 get} pg_tpch_defaultdbase {.pgtpch.f1.e5 get} pg_tpch_user {.pgtpch.f1.e6 get} pg_tpch_pass {.pgtpch.f1.e7 get} pg_tpch_dbase {.pgtpch.f1.e8 get} pg_num_tpch_threads {.pgtpch.f1.e12 get} pg_total_querysets {.pgtpch.f1.e14 get} pg_degree_of_parallel {.pgtpch.f1.e16a get} pg_update_sets {.pgtpch.f1.e18 get} pg_trickle_refresh {.pgtpch.f1.e19 get} pg_scale_fact $pg_scale_fact pg_tpch_gpcompat $pg_tpch_gpcompat pg_tpch_gpcompress $pg_tpch_gpcompress pg_raise_query_error $pg_raise_query_error pg_verbose $pg_verbose pg_refresh_on $pg_refresh_on pg_refresh_verbose $pg_refresh_verbose pg_cloud_query $pg_cloud_query pg_rs_compat $pg_rs_compat}]
   catch "destroy .pgtpch"
   ttk::toplevel .pgtpch
   wm withdraw .pgtpch
switch $option {
"all" { wm title .pgtpch {PostgreSQL TPC-H Schema Options} }
"build" { wm title .pgtpch {PostgreSQL TPC-H Build Options} }
"drive" {  wm title .pgtpch {PostgreSQL TPC-H Driver Options} }
	}
   set Parent .pgtpch
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data [ dict get $icons boxes ]]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data [ dict get $icons driveroptlo ]]
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
 ttk::label $Prompt -text "PostgreSQL User :"
   ttk::entry $Name  -width 30 -textvariable pg_tpch_user
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7
   ttk::label $Prompt -text "PostgreSQL User Password :"
   ttk::entry $Name  -width 30 -textvariable pg_tpch_pass
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
set Name $Parent.f1.e8
   set Prompt $Parent.f1.p8
   ttk::label $Prompt -text "PostgreSQL Database :"
   ttk::entry $Name -width 30 -textvariable pg_tpch_dbase
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky ew
if { $option eq "all" || $option eq "build" } {
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
   grid $Prompt -column 0 -row 9 -sticky e
   grid $Name -column 1 -row 9 -sticky w
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Greenplum Compressed Columns :"
set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable pg_tpch_gpcompress -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
if {$pg_tpch_gpcompat == "false" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e11
   set Prompt $Parent.f1.p11
   ttk::label $Prompt -text "Scale Factor :"
   grid $Prompt -column 0 -row 11 -sticky e
   set Name $Parent.f1.f2
   ttk::frame $Name -width 30
   grid $Name -column 1 -row 11 -sticky ew
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
	grid $Prompt -column 0 -row 12 -sticky e
	grid $Name -column 1 -row 12 -sticky ew
	}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data [ dict get $icons driveroptlo ]]
grid $Prompt -column 0 -row 13 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 13 -sticky w
	}
   set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Total Query Sets per User :"
   ttk::entry $Name -width 30 -textvariable pg_total_querysets
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14  -columnspan 4 -sticky ew
 set Prompt $Parent.f1.p15
ttk::label $Prompt -text "Exit on PostgreSQL Error :"
  set Name $Parent.f1.e15
ttk::checkbutton $Name -text "" -variable pg_raise_query_error -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky w
 set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Verbose Output :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable pg_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16 -sticky w
set Name $Parent.f1.e16a
   set Prompt $Parent.f1.p16a
   ttk::label $Prompt -text "Degree of Parallelism :"
   ttk::entry $Name  -width 30 -textvariable pg_degree_of_parallel
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17 -sticky ew
 set Prompt $Parent.f1.p17
ttk::label $Prompt -text "Refresh Function :"
  set Name $Parent.f1.e17
ttk::checkbutton $Name -text "" -variable pg_refresh_on -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky w
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
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19  -columnspan 4 -sticky ew
if {$pg_refresh_on == "false" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e19
   set Prompt $Parent.f1.p19
   ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable pg_trickle_refresh
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20  -columnspan 4 -sticky ew
if {$pg_refresh_on == "false" } {
	$Name configure -state disabled
	}
 set Prompt $Parent.f1.p20
ttk::label $Prompt -text "Refresh Verbose :"
  set Name $Parent.f1.e20
ttk::checkbutton $Name -text "" -variable pg_refresh_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21 -sticky w
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
   grid $Prompt -column 0 -row 22 -sticky e
   grid $Name -column 1 -row 22 -sticky w
set Prompt $Parent.f1.p22
ttk::label $Prompt -text "Redshift Compatible :"
set Name $Parent.f1.e22
ttk::checkbutton $Name -text "" -variable pg_rs_compat -onvalue "true" -offvalue "false"
if {$pg_cloud_query == "false" } {
	$Name configure -state disabled
	}
grid $Prompt -column 0 -row 23 -sticky e
grid $Name -column 1 -row 23 -sticky w
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
