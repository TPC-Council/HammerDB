proc counttrafopts { bm } {
tk_messageBox -title "No Statistics" -message "Trafodion does not have transaction statistics that can be queried at the current release"
}

proc configtraftpcc { option } {
upvar #0 icons icons
upvar #0 configtrafodion configtrafodion
#set variables to values in dict
setlocaltpccvars $configtrafodion 
#set matching fields in dialog to temporary dict
variable traffields
set traffields [ dict create connection {trafodion_dsn {.tpc.f1.e1 get} trafodion_odbc_driver {.tpc.f1.e2 get} trafodion_server {.tpc.f1.e3 get} trafodion_port {.tpc.f1.e4 get} trafodion_userid {.tpc.f1.e5 get} trafodion_password {.tpc.f1.e6 get} trafodion_schema {.tpc.f1.e7 get}} tpcc{trafodion_count_ware $trafodion_count_ware trafodion_num_vu $trafodion_num_vu trafodion_load_type $trafodion_load_type trafodion_load_data $trafodion_load_data trafodion_node_list $trafodion_node_list trafodion_copy_remote $trafodion_copy_remote trafodion_build_jsps $trafodion_build_jsps trafodion_total_iterations $trafodion_total_iterations trafodion_raiseerror $trafodion_raiseerror trafodion_keyandthink $trafodion_keyandthink traf_driver $traf_driver trafodion_rampup $trafodion_rampup trafodion_duration $trafodion_duration trafodion_allwarehouse $trafodion_allwarehouse trafodion_timeprofile $trafodion_timeprofile}]
set whlist [ get_warehouse_list_for_spinbox ]
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm transient .tpc .ed_mainFrame
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {Trafodion TPROC-C Schema Options} }
"build" { wm title .tpc {Trafodion TPROC-C Build Options} }
"drive" {  wm title .tpc {Trafodion TPROC-C Driver Options} }
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
   ttk::label $Prompt -text "Trafodion DSN :"
   ttk::entry $Name -width 30 -textvariable trafodion_dsn
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Trafodion ODBC Driver :"   
   ttk::entry $Name  -width 30 -textvariable trafodion_odbc_driver
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "Trafodion Server :"
   ttk::entry $Name  -width 30 -textvariable trafodion_server
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "Trafodion Port :"
   ttk::entry $Name  -width 30 -textvariable trafodion_port
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "Trafodion User ID :"
   ttk::entry $Name  -width 30 -textvariable trafodion_userid
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "Trafodion Password :"
   ttk::entry $Name  -width 30 -textvariable trafodion_password
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7
   ttk::label $Prompt -text "Trafodion Schema :"
   ttk::entry $Name  -width 30 -textvariable trafodion_schema
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.p8
ttk::label $Prompt -text "Load Data into Tables :"
set Name $Parent.f1.e8
ttk::checkbutton $Name -text "" -variable trafodion_load_data -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky w
bind .tpc.f1.e8 <Any-ButtonRelease> {
if { $trafodion_load_data == "false" } {
.tpc.f1.r1 configure -state normal
.tpc.f1.r2 configure -state normal
	} else {
.tpc.f1.r1 configure -state disabled
.tpc.f1.r2 configure -state disabled
set trafodion_num_vu 1
set trafodion_count_ware 1
	}
 }
set Prompt $Parent.f1.pa
ttk::label $Prompt -text "Load Type :"
grid $Prompt -column 0 -row 9 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "upsert" -text "Upsert" -variable trafodion_load_type
grid $Name -column 1 -row 9 -sticky w
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "insert" -text "Insert" -variable trafodion_load_type 
grid $Name -column 1 -row 10 -sticky w
if { $trafodion_load_data == "false" } {
set trafodion_num_vu 1
set trafodion_count_ware 1
.tpc.f1.r1 configure -state disabled
.tpc.f1.r2 configure -state disabled
	} else {
.tpc.f1.r1 configure -state normal
.tpc.f1.r2 configure -state normal
	}
set Prompt $Parent.f1.p11
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e11
ttk::spinbox $Name -value $whlist -textvariable trafodion_count_ware
bind .tpc.f1.e11 <<Any-Button-Any-Key>> {
if {$trafodion_num_vu > $trafodion_count_ware} {
set trafodion_num_vu $trafodion_count_ware
		}
if { $trafodion_load_data == "false" } {
set trafodion_num_vu 1
set trafodion_count_ware 1
		}
	}
	grid $Prompt -column 0 -row 11 -sticky e
	grid $Name -column 1 -row 11 -sticky ew
set Prompt $Parent.f1.p12
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e12
ttk::spinbox $Name -from 1 -to 512 -textvariable trafodion_num_vu
bind .tpc.f1.e12 <<Any-Button-Any-Key>> {
if {$trafodion_num_vu > $trafodion_count_ware} {
set trafodion_num_vu $trafodion_count_ware
                }
if { $trafodion_load_data == "false" } {
set trafodion_num_vu 1
set trafodion_count_ware 1
		}
        }
event add <<Any-Button-Any-Key>> <Any-ButtonRelease>
event add <<Any-Button-Any-Key>> <KeyRelease>
grid $Prompt -column 0 -row 12 -sticky e
grid $Name -column 1 -row 12 -sticky ew
set Prompt $Parent.f1.p13
ttk::label $Prompt -text "Build Java Stored Procedures Locally:"
set Name $Parent.f1.e13
ttk::checkbutton $Name -text "" -variable trafodion_build_jsps -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 13 -sticky e
   grid $Name -column 1 -row 13 -sticky w
bind .tpc.f1.e13 <Any-ButtonRelease> {
if { $trafodion_build_jsps == "false" } {
.tpc.f1.e14 configure -state normal
if { $trafodion_copy_remote == "true" } {
.tpc.f1.e15 configure -state normal
	}
} else {
.tpc.f1.e14 configure -state disabled
.tpc.f1.e15 configure -state disabled
set trafodion_copy_remote "false"
                        }
                }
set Prompt $Parent.f1.p14
ttk::label $Prompt -text "Copy Stored Procedures to Remote Nodes :"
set Name $Parent.f1.e14
ttk::checkbutton $Name -text "" -variable trafodion_copy_remote -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky w
if { $trafodion_copy_remote == "false" && $trafodion_build_jsps == "false" } {
.tpc.f1.e14 configure -state disabled
	}
bind .tpc.f1.e14 <Any-ButtonRelease> {
if { $trafodion_copy_remote == "false" } { 
if { $trafodion_build_jsps == "true" } {
.tpc.f1.e15 configure -state normal
	}
} else {
.tpc.f1.e15 configure -state disabled
                        }
                }
   set Name $Parent.f1.e15
   set Prompt $Parent.f1.p15
   ttk::label $Prompt -text "Node List (Space Separated Values) :"
   ttk::entry $Name -width 30 -textvariable trafodion_node_list
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky ew
if {$trafodion_build_jsps == "true" && $trafodion_copy_remote == "true"} {
        $Name configure -state normal
        } else {
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
set Prompt $Parent.f1.p17
ttk::label $Prompt -text "TPROC-C Driver Script :" -image [ create_image hdbicon icons ] -compound left
grid $Prompt -column 0 -row 17 -sticky e
set Name $Parent.f1.r3
ttk::radiobutton $Name -value "test" -text "Test Driver Script" -variable traf_driver
grid $Name -column 1 -row 17 -sticky w
bind .tpc.f1.r3 <ButtonPress-1> {
set trafodion_allwarehouse "false"
set trafodion_timeprofile "false"
.tpc.f1.e22 configure -state disabled
.tpc.f1.e23 configure -state disabled
.tpc.f1.e24 configure -state disabled
.tpc.f1.e25 configure -state disabled
}
set Name $Parent.f1.r4
ttk::radiobutton $Name -value "timed" -text "Timed Driver Script" -variable traf_driver
grid $Name -column 1 -row 18 -sticky w
bind .tpc.f1.r4 <ButtonPress-1> {
.tpc.f1.e22 configure -state normal
.tpc.f1.e23 configure -state normal
.tpc.f1.e24 configure -state normal
.tpc.f1.e25 configure -state normal
}
set Name $Parent.f1.e19
   set Prompt $Parent.f1.p19
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable trafodion_total_iterations
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky ew
 set Prompt $Parent.f1.p20
ttk::label $Prompt -text "Exit on Trafodion Error :"
  set Name $Parent.f1.e20
ttk::checkbutton $Name -text "" -variable trafodion_raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky w
 set Prompt $Parent.f1.p21
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.21
ttk::checkbutton $Name -text "" -variable trafodion_keyandthink -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21 -sticky w
set Name $Parent.f1.e22
   set Prompt $Parent.f1.p22
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable trafodion_rampup
   grid $Prompt -column 0 -row 22 -sticky e
   grid $Name -column 1 -row 22 -sticky ew
if {$traf_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e23
   set Prompt $Parent.f1.p23
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable trafodion_duration
   grid $Prompt -column 0 -row 23 -sticky e
   grid $Name -column 1 -row 23 -sticky ew
if {$traf_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e24
   set Prompt $Parent.f1.p24
   ttk::label $Prompt -text "Use All Warehouses :"
ttk::checkbutton $Name -text "" -variable trafodion_allwarehouse -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 24 -sticky e
   grid $Name -column 1 -row 24 -sticky ew
if {$traf_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e25
   set Prompt $Parent.f1.p25
   ttk::label $Prompt -text "Time Profile :"
ttk::checkbutton $Name -text "" -variable trafodion_timeprofile -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 25 -sticky e
   grid $Name -column 1 -row 25 -sticky ew
if {$traf_driver == "test" } {
	$Name configure -state disabled
	}
}
set Name $Parent.b2
 ttk::button $Name -command {
   unset traffields
   destroy .tpc
} -text Cancel
set Name $Parent.b1
switch $option {
"drive" {
ttk::button $Name -command {
copyfieldstoconfig configtrafodion [ subst $traffields ] tpcc
unset traffields
destroy .tpc
loadtpcc
} -text {OK}
        }
"default" {
   ttk::button $Name -command {
set trafodion_count_ware [ verify_warehouse $trafodion_count_ware 100000 ]
set trafodion_num_vu [ verify_build_threads $trafodion_num_vu $trafodion_count_ware 1024 ]
copyfieldstoconfig configtrafodion [ subst $traffields ] tpcc
unset traffields
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

proc configtraftpch {option} { }
