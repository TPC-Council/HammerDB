proc countredisopts { bm } {
upvar #0 icons icons
upvar #0 configredis configredis
upvar #0 genericdict genericdict
global afval interval

setlocaltcountvars $configredis 1
variable redoptsfields
set redoptsfields [ dict create connection {redis_host {.countopt.f1.e1 get} redis_port {.countopt.f1.e2 get}} ]
if { [ info exists afval ] } {
	after cancel $afval
	unset afval
}
   catch "destroy .countopt"
   ttk::toplevel .countopt
   wm transient .countopt .ed_mainFrame
   wm withdraw .countopt
   wm title .countopt {Redis TX Counter Options}
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
   ttk::label $Prompt -text "Redis Host :"
   ttk::entry $Name -width 30 -textvariable redis_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Redis Port :"   
   ttk::entry $Name  -width 30 -textvariable redis_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
   set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "Refresh Rate(secs) :"
   ttk::entry $Name -width 30 -textvariable interval
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew

   bind .countopt.f1.e1 <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }

set Name $Parent.b2
ttk::button $Name  -command {
unset redoptsfields
destroy .countopt
} -text Cancel
pack $Name -anchor nw -side right -padx 3 -pady 3

 set Name $Parent.b1
 ttk::button $Name -command {
copyfieldstoconfig configredis [ subst $redoptsfields ] tpcc
unset redoptsfields
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs"
        set interval 10 } else {
        dict set genericdict transaction_counter refresh_rate [.countopt.f1.e3 get]
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

proc configredistpcc { option } {
upvar #0 icons icons
upvar #0 configredis configredis
#set variables to values in dict
setlocaltpccvars $configredis
dict for {descriptor attributes} $configredis  {
if {$descriptor eq "connection" || $descriptor eq "tpcc" } {
foreach { val } [ dict keys $attributes ] {
variable $val
if {[dict exists $attributes $val ]} {
set $val [ dict get $attributes $val ]
}}}}
#set matching fields in dialog to temporary dict
variable redfields
set redfields [ dict create connection {redis_host {.tpc.f1.e1 get} redis_port {.tpc.f1.e2 get}} tpcc {redis_namespace {.tpc.f1.e3 get} redis_total_iterations {.tpc.f1.e8 get} redis_rampup {.tpc.f1.e11 get} redis_duration {.tpc.f1.e12 get} redis_async_client {.tpc.f1.e16 get} redis_async_delay {.tpc.f1.e17 get}  redis_count_ware $redis_count_ware redis_num_vu $redis_num_vu redis_total_iterations $redis_total_iterations redis_raiseerror $redis_raiseerror redis_keyandthink $redis_keyandthink redis_driver $redis_driver redis_rampup $redis_rampup redis_duration $redis_duration redis_allwarehouse $redis_allwarehouse redis_timeprofile $redis_timeprofile redis_async_scale $redis_async_scale redis_async_verbose $redis_async_verbose}]
set whlist [ get_warehouse_list_for_spinbox ]
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm transient .tpc .ed_mainFrame
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {Redis TPROC-C Schema Options} }
"build" { wm title .tpc {Redis TPROC-C Build Options} }
"drive" {  wm title .tpc {Redis TPROC-C Driver Options} }
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
   ttk::label $Prompt -text "Redis Host :"
   ttk::entry $Name -width 30 -textvariable redis_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Redis Port :"   
   ttk::entry $Name  -width 30 -textvariable redis_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "Redis Namespace :"
   ttk::entry $Name  -width 30 -textvariable redis_namespace
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.p4
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e4
ttk::spinbox $Name -value $whlist -textvariable redis_count_ware
bind .tpc.f1.e4 <<Any-Button-Any-Key>> {
if {$redis_num_vu > $redis_count_ware} {
set redis_num_vu $redis_count_ware
		}
	}
	grid $Prompt -column 0 -row 4 -sticky e
	grid $Name -column 1 -row 4 -sticky ew
set Prompt $Parent.f1.p5
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e5
ttk::spinbox $Name -from 1 -to 512 -textvariable redis_num_vu
bind .tpc.f1.e5 <<Any-Button-Any-Key>> {
if {$redis_num_vu > $redis_count_ware} {
set redis_num_vu $redis_count_ware
                }
        }
event add <<Any-Button-Any-Key>> <Any-ButtonRelease>
event add <<Any-Button-Any-Key>> <KeyRelease>
grid $Prompt -column 0 -row 5 -sticky e
grid $Name -column 1 -row 5 -sticky ew
}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [ create_image driveroptlo icons ]
grid $Prompt -column 0 -row 6 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 6 -sticky w
	}
set Prompt $Parent.f1.p6
ttk::label $Prompt -text "TPROC-C Driver Script :" -image [ create_image hdbicon icons ] -compound left
grid $Prompt -column 0 -row 7 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "test" -text "Test Driver Script" -variable redis_driver
grid $Name -column 1 -row 7 -sticky w
bind .tpc.f1.r1 <ButtonPress-1> {
set redis_allwarehouse "false"
set redis_timeprofile "false"
set redis_async_scale "false"
set redis_async_verbose "false"
.tpc.f1.e11 configure -state disabled
.tpc.f1.e12 configure -state disabled
.tpc.f1.e13 configure -state disabled
.tpc.f1.e14 configure -state disabled
.tpc.f1.e15 configure -state disabled
.tpc.f1.e16 configure -state disabled
.tpc.f1.e17 configure -state disabled
.tpc.f1.e18 configure -state disabled

}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "timed" -text "Timed Driver Script" -variable redis_driver
grid $Name -column 1 -row 8 -sticky w
bind .tpc.f1.r2 <ButtonPress-1> {
.tpc.f1.e11 configure -state normal
.tpc.f1.e12 configure -state normal
.tpc.f1.e13 configure -state normal
.tpc.f1.e14 configure -state normal
.tpc.f1.e15 configure -state normal
if { $redis_async_scale eq "true" } {
.tpc.f1.e16 configure -state normal
.tpc.f1.e17 configure -state normal
.tpc.f1.e18 configure -state normal
	}
}
set Name $Parent.f1.e8
   set Prompt $Parent.f1.p8
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable redis_total_iterations
   grid $Prompt -column 0 -row 9 -sticky e
   grid $Name -column 1 -row 9 -sticky ew
 set Prompt $Parent.f1.p9
ttk::label $Prompt -text "Exit on Redis Error :"
  set Name $Parent.f1.e9
ttk::checkbutton $Name -text "" -variable redis_raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
 set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable redis_keyandthink -onvalue "true" -offvalue "false"
bind .tpc.f1.e10 <Any-ButtonRelease> {
if { $redis_driver eq "timed" } {
if { $redis_keyandthink eq "true" } {
set redis_async_scale "false"
set redis_async_verbose "false"
.tpc.f1.e16 configure -state disabled
.tpc.f1.e17 configure -state disabled
.tpc.f1.e18 configure -state disabled
        }
    }
}
   grid $Prompt -column 0 -row 11 -sticky e
   grid $Name -column 1 -row 11 -sticky w
set Name $Parent.f1.e11
   set Prompt $Parent.f1.p11
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable redis_rampup
   grid $Prompt -column 0 -row 12 -sticky e
   grid $Name -column 1 -row 12 -sticky ew
if {$redis_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e12
   set Prompt $Parent.f1.p12
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable redis_duration
   grid $Prompt -column 0 -row 13 -sticky e
   grid $Name -column 1 -row 13 -sticky ew
if {$redis_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e13
   set Prompt $Parent.f1.p13
   ttk::label $Prompt -text "Use All Warehouses :"
ttk::checkbutton $Name -text "" -variable redis_allwarehouse -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky ew
if {$redis_driver == "test" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Time Profile :"
ttk::checkbutton $Name -text "" -variable redis_timeprofile -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky ew
if {$redis_driver == "test" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e15
   set Prompt $Parent.f1.p15
   ttk::label $Prompt -text "Asynchronous Scaling :"
ttk::checkbutton $Name -text "" -variable redis_async_scale -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16 -sticky ew
if {$redis_driver == "test" } {
        set redis_async_scale "false"
        $Name configure -state disabled
        }
bind .tpc.f1.e15 <Any-ButtonRelease> {
if { $redis_async_scale eq "true" } {
set redis_async_verbose "false"
.tpc.f1.e16 configure -state disabled
.tpc.f1.e17 configure -state disabled
.tpc.f1.e18 configure -state disabled
        } else {
if { $redis_driver eq "timed" } {
set redis_keyandthink "true"
.tpc.f1.e16 configure -state normal
.tpc.f1.e17 configure -state normal
.tpc.f1.e18 configure -state normal
                }
        }
}
   set Name $Parent.f1.e16
   set Prompt $Parent.f1.p16
   ttk::label $Prompt -text "Asynch Clients per Virtual User :"
   ttk::entry $Name -width 30 -textvariable redis_async_client
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17 -sticky ew
if {$redis_driver == "test" || $redis_async_scale == "false" } {
        $Name configure -state disabled
        }
set Name $Parent.f1.e17
   set Prompt $Parent.f1.p17
   ttk::label $Prompt -text "Asynch Client Login Delay :"
   ttk::entry $Name -width 30 -textvariable redis_async_delay
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky ew
if {$redis_driver == "test" || $redis_async_scale == "false" } {
        $Name configure -state disabled
        }
   set Name $Parent.f1.e18
   set Prompt $Parent.f1.p18
   ttk::label $Prompt -text "Asynchronous Verbose :"
ttk::checkbutton $Name -text "" -variable redis_async_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky ew
if {$redis_driver == "test" || $redis_async_scale == "false" } {
        set redis_async_verbose "false"
        $Name configure -state disabled
        }
}
set Name $Parent.b2
  ttk::button $Name -command {
   unset redfields
   destroy .tpc
} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
set Name $Parent.b1
switch $option {
"drive" {
ttk::button $Name -command {
copyfieldstoconfig configredis [ subst $redfields ] tpcc
unset redfields
destroy .tpc
loadtpcc
} -text {OK}
        }
"default" {
   ttk::button $Name -command {
set redis_count_ware [ verify_warehouse $redis_count_ware 100000 ]
set redis_num_vu [ verify_build_threads $redis_num_vu $redis_count_ware 1024 ]
copyfieldstoconfig configredis [ subst $redfields ] tpcc
unset redfields
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

proc configredistpch {option} { }
