#########################################################################
# HammerDB
# Copyright (C) HammerDB Ltd
# Hosted by the TPC-Council
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#########################################################################
#
# quackopt.tcl - GUI configuration dialogs for the Quack (sqlxtc)
# database.  The Quack connection surface is deliberately tiny (host +
# port; sqlxtc has no users, passwords, databases or tablespaces), so
# these dialogs expose only the fields that apply.  Under the CLI these
# procs are not invoked - configuration comes from config/quack.xml and
# the "diset" command - so they simply provide GUI parity.
#

proc configquacktpcc {option} {
    upvar #0 icons icons
    upvar #0 configquack configquack
    setlocaltpccvars $configquack
    variable quackfields
    set quackfields [ dict create connection {quack_host {.tpc.c1.e1 get} quack_port {.tpc.c1.e2 get}} tpcc {quack_count_ware $quack_count_ware quack_num_vu $quack_num_vu quack_total_iterations {.tpc.f1.e15 get} quack_raiseerror $quack_raiseerror quack_keyandthink $quack_keyandthink quack_driver $quack_driver quack_rampup {.tpc.f1.e21 get} quack_duration {.tpc.f1.e22 get} quack_allwarehouse $quack_allwarehouse quack_timeprofile $quack_timeprofile}]
    set whlist [ get_warehouse_list_for_spinbox ]
    catch "destroy .tpc"
    ttk::toplevel .tpc
    wm transient .tpc .ed_mainFrame
    wm withdraw .tpc
    switch $option {
        "all" { wm title .tpc {Quack TPROC-C Schema Options} }
        "build" { wm title .tpc {Quack TPROC-C Build Options} }
        "drive" { wm title .tpc {Quack TPROC-C Driver Options} }
    }
    set Parent .tpc
    set Name $Parent.notebook
    ttk::notebook $Name
    $Name add [ ttk::frame $Parent.c1 ] -text "Connection" -sticky ne
    $Name add [ ttk::frame $Parent.f1 ] -text "Settings" -sticky ne
    pack $Name -anchor nw -fill x -side top -padx 5
    ttk::label $Parent.c1.p1 -text "sqlxtc Host :"
    ttk::entry $Parent.c1.e1 -width 30 -textvariable quack_host
    grid $Parent.c1.p1 -column 0 -row 1 -sticky e
    grid $Parent.c1.e1 -column 1 -row 1 -sticky ew
    ttk::label $Parent.c1.p2 -text "sqlxtc Port :"
    ttk::entry $Parent.c1.e2 -width 30 -textvariable quack_port
    grid $Parent.c1.p2 -column 0 -row 2 -sticky e
    grid $Parent.c1.e2 -column 1 -row 2 -sticky ew
    if { $option eq "all" || $option eq "build" } {
        ttk::label $Parent.f1.p10 -text "Number of Warehouses :"
        ttk::spinbox $Parent.f1.e10 -value $whlist -textvariable quack_count_ware
        grid $Parent.f1.p10 -column 0 -row 14 -sticky e
        grid $Parent.f1.e10 -column 1 -row 14 -sticky ew
        ttk::label $Parent.f1.p11 -text "Virtual Users to Build Schema :"
        ttk::spinbox $Parent.f1.e11 -from 1 -to 100000 -textvariable quack_num_vu
        grid $Parent.f1.p11 -column 0 -row 15 -sticky e
        grid $Parent.f1.e11 -column 1 -row 15 -sticky ew
    }
    if { $option eq "all" || $option eq "drive" } {
        ttk::label $Parent.f1.p14 -text "TPROC-C Driver Script :"
        grid $Parent.f1.p14 -column 0 -row 18 -sticky e
        ttk::radiobutton $Parent.f1.r1 -value "test" -text "Test Driver Script" -variable quack_driver
        grid $Parent.f1.r1 -column 1 -row 18 -sticky w
        ttk::radiobutton $Parent.f1.r2 -value "timed" -text "Timed Driver Script" -variable quack_driver
        grid $Parent.f1.r2 -column 1 -row 19 -sticky w
        ttk::label $Parent.f1.p15 -text "Total Transactions per User :"
        ttk::entry $Parent.f1.e15 -width 30 -textvariable quack_total_iterations
        grid $Parent.f1.p15 -column 0 -row 20 -sticky e
        grid $Parent.f1.e15 -column 1 -row 20 -sticky ew
        ttk::label $Parent.f1.p16 -text "Exit on Quack Error :"
        ttk::checkbutton $Parent.f1.e16 -text "" -variable quack_raiseerror -onvalue "true" -offvalue "false"
        grid $Parent.f1.p16 -column 0 -row 21 -sticky e
        grid $Parent.f1.e16 -column 1 -row 21 -sticky w
        ttk::label $Parent.f1.p17 -text "Keying and Thinking Time :"
        ttk::checkbutton $Parent.f1.e17 -text "" -variable quack_keyandthink -onvalue "true" -offvalue "false"
        grid $Parent.f1.p17 -column 0 -row 22 -sticky e
        grid $Parent.f1.e17 -column 1 -row 22 -sticky w
        ttk::label $Parent.f1.p21 -text "Minutes of Rampup Time :"
        ttk::entry $Parent.f1.e21 -width 30 -textvariable quack_rampup
        grid $Parent.f1.p21 -column 0 -row 26 -sticky e
        grid $Parent.f1.e21 -column 1 -row 26 -sticky ew
        ttk::label $Parent.f1.p22 -text "Minutes for Test Duration :"
        ttk::entry $Parent.f1.e22 -width 30 -textvariable quack_duration
        grid $Parent.f1.p22 -column 0 -row 27 -sticky e
        grid $Parent.f1.e22 -column 1 -row 27 -sticky ew
    }
    ttk::button $Parent.b2 -command { unset quackfields; destroy .tpc } -text Cancel
    pack $Parent.b2 -anchor nw -side right -padx 3 -pady 3
    switch $option {
        "drive" {
            ttk::button $Parent.b1 -command {
                copyfieldstoconfig configquack [ subst $quackfields ] tpcc
                Dict2SQLite "quack" $configquack
                unset quackfields
                destroy .tpc
                loadtpcc
            } -text {OK}
        }
        "default" {
            ttk::button $Parent.b1 -command {
                copyfieldstoconfig configquack [ subst $quackfields ] tpcc
                Dict2SQLite "quack" $configquack
                unset quackfields
                destroy .tpc
            } -text {OK}
        }
    }
    pack $Parent.b1 -anchor nw -side right -padx 3 -pady 3
    wm geometry .tpc +50+50
    wm deiconify .tpc
    raise .tpc
    update
}

proc configquacktpch {option} {
    upvar #0 icons icons
    upvar #0 configquack configquack
    setlocaltpchvars $configquack
    variable quackfields
    set quackfields [ dict create connection {quack_host {.qtpch.c1.e1 get} quack_port {.qtpch.c1.e2 get}} tpch {quack_scale_fact $quack_scale_fact quack_num_tpch_threads $quack_num_tpch_threads quack_total_querysets {.qtpch.f1.e14 get} quack_raise_query_error $quack_raise_query_error quack_verbose $quack_verbose}]
    catch "destroy .qtpch"
    ttk::toplevel .qtpch
    wm transient .qtpch .ed_mainFrame
    wm withdraw .qtpch
    wm title .qtpch {Quack TPROC-H Options}
    set Parent .qtpch
    set Name $Parent.notebook
    ttk::notebook $Name
    $Name add [ ttk::frame $Parent.c1 ] -text "Connection" -sticky ne
    $Name add [ ttk::frame $Parent.f1 ] -text "Settings" -sticky ne
    pack $Name -anchor nw -fill x -side top -padx 5
    ttk::label $Parent.c1.p1 -text "sqlxtc Host :"
    ttk::entry $Parent.c1.e1 -width 30 -textvariable quack_host
    grid $Parent.c1.p1 -column 0 -row 1 -sticky e
    grid $Parent.c1.e1 -column 1 -row 1 -sticky ew
    ttk::label $Parent.c1.p2 -text "sqlxtc Port :"
    ttk::entry $Parent.c1.e2 -width 30 -textvariable quack_port
    grid $Parent.c1.p2 -column 0 -row 2 -sticky e
    grid $Parent.c1.e2 -column 1 -row 2 -sticky ew
    if { $option eq "all" || $option eq "build" } {
        ttk::label $Parent.f1.p12 -text "Scale Factor :"
        ttk::spinbox $Parent.f1.e12 -values {1 10 30 100 300} -textvariable quack_scale_fact
        grid $Parent.f1.p12 -column 0 -row 13 -sticky e
        grid $Parent.f1.e12 -column 1 -row 13 -sticky ew
        ttk::label $Parent.f1.p13 -text "Virtual Users to Build Schema :"
        ttk::spinbox $Parent.f1.e13 -from 1 -to 512 -textvariable quack_num_tpch_threads
        grid $Parent.f1.p13 -column 0 -row 14 -sticky e
        grid $Parent.f1.e13 -column 1 -row 14 -sticky ew
    }
    if { $option eq "all" || $option eq "drive" } {
        ttk::label $Parent.f1.p14 -text "Total Query Sets per User :"
        ttk::entry $Parent.f1.e14 -width 30 -textvariable quack_total_querysets
        grid $Parent.f1.p14 -column 0 -row 16 -sticky e
        grid $Parent.f1.e14 -column 1 -row 16 -sticky ew
        ttk::label $Parent.f1.p15 -text "Exit on Quack Error :"
        ttk::checkbutton $Parent.f1.e15 -text "" -variable quack_raise_query_error -onvalue "true" -offvalue "false"
        grid $Parent.f1.p15 -column 0 -row 17 -sticky e
        grid $Parent.f1.e15 -column 1 -row 17 -sticky w
        ttk::label $Parent.f1.p16 -text "Verbose Output :"
        ttk::checkbutton $Parent.f1.e16 -text "" -variable quack_verbose -onvalue "true" -offvalue "false"
        grid $Parent.f1.p16 -column 0 -row 18 -sticky e
        grid $Parent.f1.e16 -column 1 -row 18 -sticky w
    }
    ttk::button $Parent.b2 -command { unset quackfields; destroy .qtpch } -text Cancel
    pack $Parent.b2 -anchor nw -side right -padx 3 -pady 3
    switch $option {
        "drive" {
            ttk::button $Parent.b1 -command {
                copyfieldstoconfig configquack [ subst $quackfields ] tpch
                Dict2SQLite "quack" $configquack
                unset quackfields
                destroy .qtpch
                loadtpch
            } -text {OK}
        }
        "default" {
            ttk::button $Parent.b1 -command {
                copyfieldstoconfig configquack [ subst $quackfields ] tpch
                Dict2SQLite "quack" $configquack
                unset quackfields
                destroy .qtpch
            } -text {OK}
        }
    }
    pack $Parent.b1 -anchor nw -side right -padx 3 -pady 3
    wm geometry .qtpch +50+50
    wm deiconify .qtpch
    raise .qtpch
    update
}

proc countquackopts { bm } {
    upvar #0 configquack configquack
    global afval interval tclog uniquelog tcstamp
    upvar #0 genericdict genericdict
    dict with genericdict { dict with transaction_counter {
        set interval $tc_refresh_rate
        set tclog $tc_log_to_temp
        set uniquelog $tc_unique_log_name
        set tcstamp $tc_log_timestamps
    }}
    variable quackoptsfields
    set quackoptsfields [ dict create connection {quack_host {.countopt.c1.e1 get} quack_port {.countopt.c1.e2 get}} ]
    if { [ info exists afval ] } { after cancel $afval; unset afval }
    catch "destroy .countopt"
    ttk::toplevel .countopt
    wm transient .countopt .ed_mainFrame
    wm withdraw .countopt
    wm title .countopt {Quack TX Counter Options}
    set Parent .countopt
    set Name $Parent.notebook
    ttk::notebook $Name
    $Name add [ ttk::frame $Parent.c1 ] -text "Connection" -sticky ne
    $Name add [ ttk::frame $Parent.f1 ] -text "Settings" -sticky ne
    pack $Name -anchor nw -fill x -side top -padx 5
    ttk::label $Parent.c1.p1 -text "sqlxtc Host :"
    ttk::entry $Parent.c1.e1 -width 30 -textvariable quack_host
    grid $Parent.c1.p1 -column 0 -row 1 -sticky e
    grid $Parent.c1.e1 -column 1 -row 1 -sticky ew
    ttk::label $Parent.c1.p2 -text "sqlxtc Port :"
    ttk::entry $Parent.c1.e2 -width 30 -textvariable quack_port
    grid $Parent.c1.p2 -column 0 -row 2 -sticky e
    grid $Parent.c1.e2 -column 1 -row 2 -sticky ew
    ttk::label $Parent.f1.p6 -text "Refresh Rate(secs) :"
    ttk::entry $Parent.f1.e6 -width 30 -textvariable interval
    grid $Parent.f1.p6 -column 0 -row 6 -sticky e
    grid $Parent.f1.e6 -column 1 -row 6 -sticky ew
    ttk::button $Parent.b2 -command { unset quackoptsfields; destroy .countopt } -text Cancel
    pack $Parent.b2 -anchor nw -side right -padx 3 -pady 3
    ttk::button $Parent.b1 -command {
        copyfieldstoconfig configquack [ subst $quackoptsfields ] connection
        Dict2SQLite "quack" $configquack
        unset quackoptsfields
        dict with genericdict { dict with transaction_counter {
            set tc_refresh_rate [.countopt.f1.e6 get]
        }}
        destroy .countopt
        catch "destroy .tc"
    } -text {OK}
    pack $Parent.b1 -anchor nw -side right -padx 3 -pady 3
    wm geometry .countopt +50+50
    wm deiconify .countopt
    raise .countopt
    update
}

proc metquackopts {} {
    global agent_hostname agent_id bm start_display cpu_only
    upvar #0 configquack configquack
    if { ![ info exists agent_hostname ] } { set agent_hostname "localhost" }
    if { ![ info exists agent_id ] } { set agent_id 0 }
    if { ![ info exists cpu_only ] } { set cpu_only "false" }
    if { ![ info exists start_display ] } { set start_display "true" }
    catch "destroy .metric"
    ttk::toplevel .metric
    wm transient .metric .ed_mainFrame
    wm withdraw .metric
    wm title .metric {Quack Metrics Options}
    set Parent .metric
    ttk::label $Parent.f1p7 -text "Agent ID :"
    ttk::entry $Parent.f1e7 -width 30 -textvariable agent_id
    grid $Parent.f1p7 -column 0 -row 7 -sticky e
    grid $Parent.f1e7 -column 1 -row 7
    ttk::label $Parent.f1p8 -text "Agent Hostname :"
    ttk::entry $Parent.f1e8 -width 30 -textvariable agent_hostname
    grid $Parent.f1p8 -column 0 -row 8 -sticky e
    grid $Parent.f1e8 -column 1 -row 8
    ttk::button $Parent.b4 -command { destroy .metric } -text Cancel
    pack $Parent.b4 -anchor w -side right -padx 3 -pady 3
    ttk::button $Parent.b5 -command {
        set agent_id [.metric.f1e7 get]
        set agent_hostname [.metric.f1e8 get]
        catch "destroy .metric"
    } -text OK
    pack $Parent.b5 -anchor w -side right -padx 3 -pady 3
    wm geometry .metric +50+50
    wm deiconify .metric
    raise .metric
    update
}
