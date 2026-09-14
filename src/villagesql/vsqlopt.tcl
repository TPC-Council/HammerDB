proc check_vsql_ssl { configdict } {
    global vsql_ssl_options
    unset -nocomplain vsql_ssl_options
    upvar #0 configvillagesql configvillagesql
    #set local variables to dict for checking
    foreach key [ dict keys [ dict get $configdict connection ] *ssl* ] {
        set $key [ dict get $configdict connection $key ]
    }
    #Use correct directory
    if {![string match windows $::tcl_platform(platform)]} {
        set capath $vsql_ssl_linux_capath
    } else {
        set capath $vsql_ssl_windows_capath
    }
    #If SSL not enabled return
    if { $vsql_ssl != "true" } {
        #nothing to check, vsql_ssl_options is not set
        set vsql_ssl_options " -ssl false "
        return
    } else {
        #SSL is enabled, check that capath is valid
        if { [ file isdirectory $capath ] } {
            if { $vsql_ssl_ca eq "" && $vsql_ssl_cert eq "" && $vsql_ssl_key eq "" } {
                #All of the file entries are blank, use capath only
            } else {
                #CApath is valid, file entries are not blank, always check CA
                if { [ file readable [ file join $capath $vsql_ssl_ca ]] } {
                } else {
                    tk_messageBox -message "[ file join $capath $vsql_ssl_ca ] is not readable, disabling SSL"
                    dict set configvillagesql connection vsql_ssl "false"
                    return
                }
                #capath and ca are readable
                if { $vsql_ssl_two_way eq "true" } {
                    #Also check Cert and Key readable
                    foreach sslfile [ list $vsql_ssl_cert $vsql_ssl_key ] {
                        if { [ file readable [ file join $capath $sslfile ]] } {
                        } else {
                            tk_messageBox -message "[ file join $capath $sslfile ] is not readable, disabling SSL"
                            dict set configvillagesql connection vsql_ssl "false"
                            return
                        }
                    }
                }
            }
        } else {
            tk_messageBox -message "SSL CApath is not a valid directory, disabling SSL"
            #Set SSL to false
            dict set configvillagesql connection vsql_ssl "false"
            return
        }
    }
    #SSL is true and all files needed are readable, build options
    append vsql_ssl_options " -ssl true "
    if { $vsql_ssl_ca eq "" && $vsql_ssl_cert eq "" && $vsql_ssl_key eq "" } {
        #No files given as an argument use -capath only
        append vsql_ssl_options " -sslcapath $capath "
    } else {
        #for one-way use -sslca only
        append vsql_ssl_options " -sslca [ file join $capath $vsql_ssl_ca ] "
        if { $vsql_ssl_two_way eq "true" } {
            #for two-way add -sslcert & -sslkey
            append vsql_ssl_options " -sslcert [ file join $capath $vsql_ssl_cert ] "
            append vsql_ssl_options " -sslkey [ file join $capath $vsql_ssl_key ] "
        }
    }
    #if ssl_cipher has changed add the option
    if { $vsql_ssl_cipher != "server" } { append vsql_ssl_options " -sslcipher $vsql_ssl_cipher " }
}

proc countvsqlopts { bm } {
    upvar #0 icons icons
    upvar #0 configvillagesql configvillagesql
    upvar #0 genericdict genericdict
    global afval interval tclog uniquelog tcstamp
    dict with genericdict { dict with transaction_counter {
            #variables for button options need to be global
            set interval $tc_refresh_rate
            set tclog $tc_log_to_temp
            set uniquelog $tc_unique_log_name
            set tcstamp $tc_log_timestamps
    }}
    setlocaltcountvars $configvillagesql 1
    global default_vsql_port
    set default_vsql_port $vsql_port
    variable myoptsfields
    if { $bm eq "TPC-C" } {
        if {![string match windows $::tcl_platform(platform)]} {
            set platform "lin"
            set myoptsfields [ dict create connection {vsql_host {.countopt.c1.e1 get} vsql_port {.countopt.c1.e2 get} vsql_socket {.countopt.c1.e2a get} vsql_ssl_ca {.countopt.c1.e2d get} vsql_ssl_cert {.countopt.c1.e2e get} vsql_ssl_key {.countopt.c1.e2f get} vsql_ssl_cipher {.countopt.c1.e2g get} vsql_ssl $vsql_ssl vsql_ssl_two_way $vsql_ssl_two_way vsql_ssl_linux_capath $vsql_ssl_linux_capath} tpcc {vsql_user {.countopt.c1.e3 get} vsql_pass {.countopt.c1.e4 get}} ]
        } else {
            set platform "win"
            set myoptsfields [ dict create connection {vsql_host {.countopt.c1.e1 get} vsql_port {.countopt.c1.e2 get} vsql_socket {.countopt.c1.e2a get} vsql_ssl_ca {.countopt.c1.e2d get} vsql_ssl_cert {.countopt.c1.e2e get} vsql_ssl_key {.countopt.c1.e2f get} vsql_ssl_cipher {.countopt.c1.e2g get} vsql_ssl $vsql_ssl vsql_ssl_two_way $vsql_ssl_two_way vsql_ssl_windows_capath {$vsql_ssl_windows_capath}} tpcc {vsql_user {.countopt.c1.e3 get} vsql_pass {.countopt.c1.e4 get}} ]
        }
    } else {
        if {![string match windows $::tcl_platform(platform)]} {
            set platform "lin"
            set myoptsfields [ dict create connection {vsql_host {.countopt.c1.e1 get} vsql_port {.countopt.c1.e2 get} vsql_socket {.countopt.c1.e2a get} vsql_ssl_ca {.countopt.c1.e2d get} vsql_ssl_cert {.countopt.c1.e2e get} vsql_ssl_key {.countopt.c1.e2f get} vsql_ssl_cipher {.countopt.c1.e2g get} vsql_ssl $vsql_ssl vsql_ssl_two_way $vsql_ssl_two_way vsql_ssl_linux_capath $vsql_ssl_linux_capath} tpch {vsql_tpch_user {.countopt.c1.e3 get} vsql_tpch_pass {.countopt.c1.e4 get}} ]
        } else {
            set platform "win"
            set myoptsfields [ dict create connection {vsql_host {.countopt.c1.e1 get} vsql_port {.countopt.c1.e2 get} vsql_socket {.countopt.c1.e2a get} vsql_ssl_ca {.countopt.c1.e2d get} vsql_ssl_cert {.countopt.c1.e2e get} vsql_ssl_key {.countopt.c1.e2f get} vsql_ssl_cipher {.countopt.c1.e2g get} vsql_ssl $vsql_ssl vsql_ssl_two_way $vsql_ssl_two_way vsql_ssl_windows_capath {$vsql_ssl_windows_capath}} tpch {vsql_tpch_user {.countopt.c1.e3 get} vsql_tpch_pass {.countopt.c1.e4 get}} ]
        }
    }
    if { [ info exists afval ] } {
        after cancel $afval
        unset afval
    }
    catch "destroy .countopt"
    ttk::toplevel .countopt
    wm transient .countopt .ed_mainFrame
    wm withdraw .countopt
    wm title .countopt {VillageSQL TX Counter Options}
    set Parent .countopt
    set Prompt $Parent.h1
    ttk::label $Prompt -compound left -text "Transaction Counter Options" -image [ create_image pencil icons ]
    pack $Prompt -anchor center -side top
    set Name $Parent.notebook
    ttk::notebook $Name
    $Name add [ ttk::frame $Parent.c1 ] -text "Connection" -sticky ne
    $Name add [ ttk::frame $Parent.f1 ] -text "Settings" -sticky ne
    pack $Name -anchor nw -fill x -side top -padx 5
    set Name $Parent.c1.e1
    set Prompt $Parent.c1.p1
    ttk::label $Prompt -text "VillageSQL Host :"
    ttk::entry $Name -width 30 -textvariable vsql_host
    grid $Prompt -column 0 -row 1 -sticky e
    grid $Name -column 1 -row 1 -sticky ew
    set Name $Parent.c1.e2
    set Prompt $Parent.c1.p2
    ttk::label $Prompt -text "VillageSQL Port :"
    ttk::entry $Name  -width 30 -textvariable vsql_port
    grid $Prompt -column 0 -row 2 -sticky e
    grid $Name -column 1 -row 2 -sticky ew
    set Name $Parent.c1.e2a
    set Prompt $Parent.c1.p2a
    ttk::label $Prompt -text "VillageSQL Socket :"
    ttk::entry $Name  -width 30 -textvariable vsql_socket
    grid $Prompt -column 0 -row 3 -sticky e
    grid $Name -column 1 -row 3 -sticky ew
    if {[string match windows $::tcl_platform(platform)]} {
        set vsql_socket "null"
        .countopt.c1.e2a configure -state disabled
    }

    set Name $Parent.c1.e2b
    set Prompt $Parent.c1.p2b
    ttk::label $Prompt -text "Enable SSL :"
    ttk::checkbutton $Name -text "" -variable vsql_ssl -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 4 -sticky e
    grid $Name -column 1 -row 4 -sticky w

    bind .countopt.c1.e2b <Any-ButtonRelease> {
        if { $vsql_ssl eq "true" } {
            .countopt.c1.e2ba configure -state disabled
            .countopt.c1.e2bb configure -state disabled
            .countopt.c1.e2c configure -state disabled
            .countopt.c1.e2d configure -state disabled
            .countopt.c1.e2e configure -state disabled
            .countopt.c1.e2f configure -state disabled
            .countopt.c1.e2g configure -state disabled
        } else {
            .countopt.c1.e2ba configure -state normal
            .countopt.c1.e2bb configure -state normal
            .countopt.c1.e2c configure -state normal
            .countopt.c1.e2d configure -state normal
            if { $vsql_ssl_two_way eq "true" } {
                .countopt.c1.e2e configure -state normal
                .countopt.c1.e2f configure -state normal
            }
            .countopt.c1.e2g configure -state normal
        }
    }

    set Name $Parent.c1.e2ba
    ttk::radiobutton $Name -value "false" -text "SSL One-Way" -variable vsql_ssl_two_way
    grid $Name -column 1 -row 5 -sticky w
    if { $vsql_ssl eq "false" } {
        .countopt.c1.e2ba configure -state disabled
    }
    bind .countopt.c1.e2ba <ButtonPress-1> {
    if { $vsql_ssl eq "true" } {
        .countopt.c1.e2e configure -state disabled
        .countopt.c1.e2f configure -state disabled
	}
    }

    set Name $Parent.c1.e2bb
    ttk::radiobutton $Name -value "true" -text "SSL Two-Way" -variable vsql_ssl_two_way
    grid $Name -column 1 -row 6 -sticky w
    if { $vsql_ssl eq "false" } {
        .countopt.c1.e2bb configure -state disabled
    }

    bind .countopt.c1.e2bb <ButtonPress-1> {
    if { $vsql_ssl eq "true" } {
        .countopt.c1.e2bb configure -state disabled
        .countopt.c1.e2e configure -state normal
        .countopt.c1.e2f configure -state normal
	}
    }

    set Name $Parent.c1.e2c
    set Prompt $Parent.c1.p2c
    ttk::label $Prompt -text "SSL CApath :"
    if { $platform eq "lin" } {
        ttk::entry $Name -width 30 -textvariable vsql_ssl_linux_capath
    } else {
        ttk::entry $Name -width 30 -textvariable vsql_ssl_windows_capath
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2d
    set Prompt $Parent.c1.p2d
    ttk::label $Prompt -text "SSL CA :"
    ttk::entry $Name  -width 30 -textvariable vsql_ssl_ca
    grid $Prompt -column 0 -row 8 -sticky e
    grid $Name -column 1 -row 8 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2e
    set Prompt $Parent.c1.p2e
    ttk::label $Prompt -text "SSL Cert :"
    ttk::entry $Name  -width 30 -textvariable vsql_ssl_cert
    grid $Prompt -column 0 -row 9 -sticky e
    grid $Name -column 1 -row 9 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2f
    set Prompt $Parent.c1.p2f
    ttk::label $Prompt -text "SSL Key :"
    ttk::entry $Name  -width 30 -textvariable vsql_ssl_key
    grid $Prompt -column 0 -row 10 -sticky e
    grid $Name -column 1 -row 10 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2g
    set Prompt $Parent.c1.p2g
    ttk::label $Prompt -text "SSL Cipher :"
    ttk::entry $Name  -width 30 -textvariable vsql_ssl_cipher
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e3
    set Prompt $Parent.c1.p3
    ttk::label $Prompt -text "VillageSQL User :"
    if { $bm eq "TPC-C" } {
        ttk::entry $Name  -width 30 -textvariable vsql_user
    } else {
        ttk::entry $Name  -width 30 -textvariable vsql_tpch_user
    }
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew
    set Name $Parent.c1.e4
    set Prompt $Parent.c1.p4
    ttk::label $Prompt -text "VillageSQL User Password :"
    if { $bm eq "TPC-C" } {
        ttk::entry $Name -show * -width 30 -textvariable vsql_pass
    } else {
        ttk::entry $Name -show * -width 30 -textvariable vsql_tpch_pass
    }
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky ew

    set Name $Parent.f1.e5
    set Prompt $Parent.f1.p5
    ttk::label $Prompt -text "Refresh Rate(secs) :"
    ttk::entry $Name -width 30 -textvariable interval
    grid $Prompt -column 0 -row 16 -sticky e
    grid $Name -column 1 -row 16 -sticky ew

    set Name $Parent.f1.e7
    ttk::checkbutton $Name -text "Log Output to Temp" -variable tclog -onvalue 1 -offvalue 0
    grid $Name -column 1 -row 17 -sticky w
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
    grid $Name -column 1 -row 18 -sticky w
    if {$tclog == 0} {
        $Name configure -state disabled
    }

    set Name $Parent.f1.e9
    ttk::checkbutton $Name -text "Log Timestamps" -variable tcstamp -onvalue 1 -offvalue 0
    grid $Name -column 1 -row 19 -sticky w
    if {$tclog == 0} {
        $Name configure -state disabled
    }

    bind .countopt.c1.e1 <Delete> {
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
            copyfieldstoconfig configvillagesql [ subst $myoptsfields ] tpcc
            Dict2SQLite "villagesql" $configvillagesql
            unset myoptsfields
            check_vsql_ssl $configvillagesql
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
            copyfieldstoconfig configvillagesql [ subst $myoptsfields ] tpch
            Dict2SQLite "villagesql" $configvillagesql
            unset myoptsfields
            check_vsql_ssl $configvillagesql
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

proc configvsqltpcc {option} {
    upvar #0 icons icons
    upvar #0 configvillagesql configvillagesql
    #set variables to values in dict
    setlocaltpccvars $configvillagesql
    set tpccfields [ dict create tpcc {vsql_user {.tpc.c1.e3 get} vsql_pass {.tpc.c1.e4 get} vsql_dbase {.tpc.c1.e5 get} vsql_storage_engine {.tpc.f1.e6 get} vsql_total_iterations {.tpc.f1.e14 get} vsql_rampup {.tpc.f1.e17 get} vsql_duration {.tpc.f1.e18 get} vsql_async_client {.tpc.f1.e22 get} vsql_async_delay {.tpc.f1.e23 get} vsql_count_ware $vsql_count_ware vsql_num_vu $vsql_num_vu vsql_partition $vsql_partition vsql_driver $vsql_driver vsql_raiseerror $vsql_raiseerror vsql_keyandthink $vsql_keyandthink vsql_allwarehouse $vsql_allwarehouse vsql_timeprofile $vsql_timeprofile vsql_async_scale $vsql_async_scale vsql_async_verbose $vsql_async_verbose vsql_prepared $vsql_prepared vsql_no_stored_procs $vsql_no_stored_procs vsql_connect_pool $vsql_connect_pool vsql_history_pk $vsql_history_pk} ]
    if {![string match windows $::tcl_platform(platform)]} {
        set platform "lin"
        set vsqlconn [ dict create connection {vsql_host {.tpc.c1.e1 get} vsql_port {.tpc.c1.e2 get} vsql_socket {.tpc.c1.e2a get} vsql_ssl_ca {.tpc.c1.e2d get} vsql_ssl_cert {.tpc.c1.e2e get} vsql_ssl_key {.tpc.c1.e2f get} vsql_ssl_cipher {.tpc.c1.e2g get} vsql_ssl $vsql_ssl vsql_ssl_two_way $vsql_ssl_two_way vsql_ssl_linux_capath $vsql_ssl_linux_capath} ]
    } else {
        set platform "win"
        set vsqlconn [ dict create connection {vsql_host {.tpc.c1.e1 get} vsql_port {.tpc.c1.e2 get} vsql_socket {.tpc.c1.e2a get} vsql_ssl_ca {.tpc.c1.e2d get} vsql_ssl_cert {.tpc.c1.e2e get} vsql_ssl_key {.tpc.c1.e2f get} vsql_ssl_cipher {.tpc.c1.e2g get} vsql_ssl $vsql_ssl vsql_ssl_two_way $vsql_ssl_two_way vsql_ssl_windows_capath {$vsql_ssl_windows_capath}} ]
    }
    variable myfields
    set myfields [ dict merge $vsqlconn $tpccfields ]
    set whlist [ get_warehouse_list_for_spinbox ]

    catch "destroy .tpc"
    ttk::toplevel .tpc
    wm transient .tpc .ed_mainFrame
    wm withdraw .tpc
    switch $option {
        "all" { wm title .tpc {VillageSQL TPROC-C Schema Options} }
        "build" { wm title .tpc {VillageSQL TPROC-C Build Options} }
        "drive" {  wm title .tpc {VillageSQL TPROC-C Driver Options} }
    }
    set Parent .tpc
    if { $option eq "all" || $option eq "build" } {
        set Prompt $Parent.h1
	ttk::label $Prompt -compound left -text "Build Options" -image [ create_image boxes icons ]
    	pack $Prompt -anchor center -side top
    } else {
        set Prompt $Parent.h2
	ttk::label $Prompt -compound left -text "Driver Options" -image [ create_image driveroptlo icons ]
    	pack $Prompt -anchor center -side top
    }
    set Name $Parent.notebook
    ttk::notebook $Name
    $Name add [ ttk::frame $Parent.c1 ] -text "Connection" -sticky ne
    $Name add [ ttk::frame $Parent.f1 ] -text "Settings" -sticky ne
    pack $Name -anchor nw -fill x -side top -padx 5
    set Name $Parent.c1.e1
    set Prompt $Parent.c1.p1
    ttk::label $Prompt -text "VillageSQL Host :"
    ttk::entry $Name -width 30 -textvariable vsql_host
    grid $Prompt -column 0 -row 1 -sticky e
    grid $Name -column 1 -row 1 -sticky ew
    set Name $Parent.c1.e2
    set Prompt $Parent.c1.p2
    ttk::label $Prompt -text "VillageSQL Port :"
    ttk::entry $Name  -width 30 -textvariable vsql_port
    grid $Prompt -column 0 -row 2 -sticky e
    grid $Name -column 1 -row 2 -sticky ew
    set Name $Parent.c1.e2a
    set Prompt $Parent.c1.p2a
    ttk::label $Prompt -text "VillageSQL Socket :"
    ttk::entry $Name  -width 30 -textvariable vsql_socket
    grid $Prompt -column 0 -row 3 -sticky e
    grid $Name -column 1 -row 3 -sticky ew
    if {[string match windows $::tcl_platform(platform)]} {
        set vsql_socket "null"
        .tpc.c1.e2a configure -state disabled
    }

    set Name $Parent.c1.e2b
    set Prompt $Parent.c1.p2b
    ttk::label $Prompt -text "Enable SSL :"
    ttk::checkbutton $Name -text "" -variable vsql_ssl -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 4 -sticky e
    grid $Name -column 1 -row 4 -sticky w

    bind .tpc.c1.e2b <Any-ButtonRelease> {
        if { $vsql_ssl eq "true" } {
            .tpc.c1.e2ba configure -state disabled
            .tpc.c1.e2bb configure -state disabled
            .tpc.c1.e2c configure -state disabled
            .tpc.c1.e2d configure -state disabled
            .tpc.c1.e2e configure -state disabled
            .tpc.c1.e2f configure -state disabled
            .tpc.c1.e2g configure -state disabled
        } else {
            .tpc.c1.e2ba configure -state normal
            .tpc.c1.e2bb configure -state normal
            .tpc.c1.e2c configure -state normal
            .tpc.c1.e2d configure -state normal
            if { $vsql_ssl_two_way eq "true" } {
                .tpc.c1.e2e configure -state normal
                .tpc.c1.e2f configure -state normal
            }
            .tpc.c1.e2g configure -state normal
        }
    }

    set Name $Parent.c1.e2ba
    ttk::radiobutton $Name -value "false" -text "SSL One-Way" -variable vsql_ssl_two_way
    grid $Name -column 1 -row 5 -sticky w
    if { $vsql_ssl eq "false" } {
        .tpc.c1.e2ba configure -state disabled
    }
    bind .tpc.c1.e2ba <ButtonPress-1> {
    if { $vsql_ssl eq "true" } {
        .tpc.c1.e2e configure -state disabled
        .tpc.c1.e2f configure -state disabled
       }
    }

    set Name $Parent.c1.e2bb
    ttk::radiobutton $Name -value "true" -text "SSL Two-Way" -variable vsql_ssl_two_way
    grid $Name -column 1 -row 6 -sticky w
    if { $vsql_ssl eq "false" } {
        .tpc.c1.e2bb configure -state disabled
    }

    bind .tpc.c1.e2bb <ButtonPress-1> {
    if { $vsql_ssl eq "true" } {
        .tpc.c1.e2e configure -state normal
        .tpc.c1.e2f configure -state normal
       }
    }

    set Name $Parent.c1.e2c
    set Prompt $Parent.c1.p2c
    ttk::label $Prompt -text "SSL CApath :"
    if { $platform eq "lin" } {
        ttk::entry $Name -width 30 -textvariable vsql_ssl_linux_capath
    } else {
        ttk::entry $Name -width 30 -textvariable vsql_ssl_windows_capath
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2d
    set Prompt $Parent.c1.p2d
    ttk::label $Prompt -text "SSL CA :"
    ttk::entry $Name  -width 30 -textvariable vsql_ssl_ca
    grid $Prompt -column 0 -row 8 -sticky e
    grid $Name -column 1 -row 8 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2e
    set Prompt $Parent.c1.p2e
    ttk::label $Prompt -text "SSL Cert :"
    ttk::entry $Name  -width 30 -textvariable vsql_ssl_cert
    grid $Prompt -column 0 -row 9 -sticky e
    grid $Name -column 1 -row 9 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2f
    set Prompt $Parent.c1.p2f
    ttk::label $Prompt -text "SSL Key :"
    ttk::entry $Name  -width 30 -textvariable vsql_ssl_key
    grid $Prompt -column 0 -row 10 -sticky e
    grid $Name -column 1 -row 10 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2g
    set Prompt $Parent.c1.p2g
    ttk::label $Prompt -text "SSL Cipher :"
    ttk::entry $Name  -width 30 -textvariable vsql_ssl_cipher
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e3
    set Prompt $Parent.c1.p3
    ttk::label $Prompt -text "VillageSQL User :"
    ttk::entry $Name  -width 30 -textvariable vsql_user
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew
    set Name $Parent.c1.e4
    set Prompt $Parent.c1.p4
    ttk::label $Prompt -text "VillageSQL User Password :"
    ttk::entry $Name -show * -width 30 -textvariable vsql_pass
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky ew
    set Name $Parent.c1.e5
    set Prompt $Parent.c1.p5
    ttk::label $Prompt -text "TPROC-C VillageSQL Database :" -image [ create_image hdbicon icons ] -compound left
    ttk::entry $Name -width 30 -textvariable vsql_dbase
    grid $Prompt -column 0 -row 14 -sticky e
    grid $Name -column 1 -row 14 -sticky ew
    if { $option eq "all" || $option eq "build" } {
        set Name $Parent.f1.e6
        set Prompt $Parent.f1.p6
        ttk::label $Prompt -text "Transactional Storage Engine :"
        ttk::entry $Name -width 30 -textvariable vsql_storage_engine
        grid $Prompt -column 0 -row 15 -sticky e
        grid $Name -column 1 -row 15 -sticky ew
        set Prompt $Parent.f1.p8
        ttk::label $Prompt -text "Number of Warehouses :"
        set Name $Parent.f1.e8
        ttk::spinbox $Name -value $whlist -textvariable vsql_count_ware
        bind .tpc.f1.e8 <<Any-Button-Any-Key>> {
            if {$vsql_num_vu > $vsql_count_ware} {
                set vsql_num_vu $vsql_count_ware
            }
            if {$vsql_count_ware < 200} {
                .tpc.f1.e10 configure -state disabled
                set vsql_partition "false"
            } else {
                .tpc.f1.e10 configure -state enabled
            }
        }
        grid $Prompt -column 0 -row 16 -sticky e
        grid $Name -column 1 -row 16 -sticky ew
        set Prompt $Parent.f1.p9
        ttk::label $Prompt -text "Virtual Users to Build Schema :"
        set Name $Parent.f1.e9
        ttk::spinbox $Name -from 1 -to 100000 -textvariable vsql_num_vu
        bind .tpc.f1.e9 <<Any-Button-Any-Key>> {
            if {$vsql_num_vu > $vsql_count_ware} {
                set vsql_num_vu $vsql_count_ware
            }
        }
        event add <<Any-Button-Any-Key>> <Any-ButtonRelease>
        event add <<Any-Button-Any-Key>> <KeyRelease>
        grid $Prompt -column 0 -row 17 -sticky e
        grid $Name -column 1 -row 17 -sticky ew
        set Prompt $Parent.f1.p10
        ttk::label $Prompt -text "Partition Order Line Table :"
        set Name $Parent.f1.e10
        ttk::checkbutton $Name -text "" -variable vsql_partition -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 18 -sticky e
        grid $Name -column 1 -row 18 -sticky w
        if {$vsql_count_ware <= 200 } {
            $Name configure -state disabled
        }
	grid $Prompt -column 0 -row 19 -sticky e
        grid $Name -column 1 -row 19 -sticky ew
        set Prompt $Parent.f1.p11
        ttk::label $Prompt -text "History Table Primary Key :"
        set Name $Parent.f1.e11
        ttk::checkbutton $Name -text "" -variable vsql_history_pk -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 20 -sticky e
        grid $Name -column 1 -row 20 -sticky w
    }
    if { $option eq "all" || $option eq "drive" } {
        if { $option eq "all" } {
            set Prompt $Parent.f1.h3
            ttk::label $Prompt -image [ create_image driveroptlo icons ]
            grid $Prompt -column 0 -row 21 -sticky e
            set Prompt $Parent.f1.h4
            ttk::label $Prompt -text "Driver Options"
            grid $Prompt -column 1 -row 21 -sticky w
        }
        set Prompt $Parent.f1.p12
        ttk::label $Prompt -text "TPROC-C Driver Script :" -image [ create_image hdbicon icons ] -compound left
        grid $Prompt -column 0 -row 22 -sticky e
        set Name $Parent.f1.r1
        ttk::radiobutton $Name -value "test" -text "Test Driver Script" -variable vsql_driver
        grid $Name -column 1 -row 22 -sticky w
        bind .tpc.f1.r1 <ButtonPress-1> {
            set vsql_allwarehouse "false"
            set vsql_timeprofile "false"
            set vsql_async_scale "false"
            set vsql_async_verbose "false"
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
        ttk::radiobutton $Name -value "timed" -text "Timed Driver Script" -variable vsql_driver
        grid $Name -column 1 -row 23 -sticky w
        bind .tpc.f1.r2 <ButtonPress-1> {
            .tpc.f1.e17 configure -state normal
            .tpc.f1.e18 configure -state normal
            .tpc.f1.e19 configure -state normal
            .tpc.f1.e20 configure -state normal
            .tpc.f1.e21 configure -state normal
            if { $vsql_async_scale eq "true" } {
                .tpc.f1.e22 configure -state normal
                .tpc.f1.e23 configure -state normal
                .tpc.f1.e24 configure -state normal
            }
        }
        set Name $Parent.f1.e14
        set Prompt $Parent.f1.p14
        ttk::label $Prompt -text "Total Transactions per User :"
        ttk::entry $Name -width 30 -textvariable vsql_total_iterations
        grid $Prompt -column 0 -row 24 -sticky e
        grid $Name -column 1 -row 24 -sticky ew
        set Prompt $Parent.f1.p15
        ttk::label $Prompt -text "Exit on VillageSQL Error :"
        set Name $Parent.f1.e15
        ttk::checkbutton $Name -text "" -variable vsql_raiseerror -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 25 -sticky e
        grid $Name -column 1 -row 25 -sticky w
        set Prompt $Parent.f1.p16
        ttk::label $Prompt -text "Keying and Thinking Time :"
        set Name $Parent.f1.e16
        ttk::checkbutton $Name -text "" -variable vsql_keyandthink -onvalue "true" -offvalue "false"
        bind .tpc.f1.e16 <Any-ButtonRelease> {
            if { $vsql_driver eq "timed" } {
                if { $vsql_keyandthink eq "true" } {
                    set vsql_async_scale "false"
                    set vsql_async_verbose "false"
                    .tpc.f1.e22 configure -state disabled
                    .tpc.f1.e23 configure -state disabled
                    .tpc.f1.e24 configure -state disabled
                }
            }
        }
        grid $Prompt -column 0 -row 26 -sticky e
        grid $Name -column 1 -row 26 -sticky w
        set Prompt $Parent.f1.p16a
        ttk::label $Prompt -text "Prepare Statements :"
        set Name $Parent.f1.e16a
        ttk::checkbutton $Name -text "" -variable vsql_prepared -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 27 -sticky e
        grid $Name -column 1 -row 27 -sticky w
	 if { $vsql_connect_pool } { set vsql_prepared "true"
        .tpc.f1.e16a configure -state disabled
        }
         bind .tpc.f1.e16a <Any-ButtonRelease> {
            if { $vsql_prepared eq "false" } {
                set vsql_no_stored_procs "false"
                .tpc.f1.e16b configure -state disabled
            } else {
                    if { $vsql_connect_pool eq "false" } {
                .tpc.f1.e16b configure -state normal
                        }
            }
    }
	set Prompt $Parent.f1.p16b
        ttk::label $Prompt -text "No Stored Procedures :"
        set Name $Parent.f1.e16b
        ttk::checkbutton $Name -text "" -variable vsql_no_stored_procs -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 28 -sticky e
        grid $Name -column 1 -row 28 -sticky w
        if { $vsql_connect_pool || $vsql_prepared } {
	set vsql_no_stored_procs "false"
        .tpc.f1.e16b configure -state disabled
        }

        set Name $Parent.f1.e17
        set Prompt $Parent.f1.p17
        ttk::label $Prompt -text "Minutes of Rampup Time :"
        ttk::entry $Name -width 30 -textvariable vsql_rampup
        grid $Prompt -column 0 -row 29 -sticky e
        grid $Name -column 1 -row 29 -sticky ew
        if {$vsql_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e18
        set Prompt $Parent.f1.p18
        ttk::label $Prompt -text "Minutes for Test Duration :"
        ttk::entry $Name -width 30 -textvariable vsql_duration
        grid $Prompt -column 0 -row 30 -sticky e
        grid $Name -column 1 -row 30 -sticky ew
        if {$vsql_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e19
        set Prompt $Parent.f1.p19
        ttk::label $Prompt -text "Use All Warehouses :"
        ttk::checkbutton $Name -text "" -variable vsql_allwarehouse -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 31 -sticky e
        grid $Name -column 1 -row 31 -sticky ew
        if {$vsql_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e20
        set Prompt $Parent.f1.p20
        ttk::label $Prompt -text "Time Profile :"
        ttk::checkbutton $Name -text "" -variable vsql_timeprofile -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 32 -sticky e
        grid $Name -column 1 -row 32 -sticky ew
        if {$vsql_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e21
        set Prompt $Parent.f1.p21
        ttk::label $Prompt -text "Asynchronous Scaling :"
        ttk::checkbutton $Name -text "" -variable vsql_async_scale -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 33 -sticky e
        grid $Name -column 1 -row 33 -sticky ew
        if {$vsql_driver == "test" } {
            set vsql_async_scale "false"
            $Name configure -state disabled
        }
        bind .tpc.f1.e21 <Any-ButtonRelease> {
            if { $vsql_async_scale eq "true" } {
                set vsql_async_verbose "false"
                .tpc.f1.e22 configure -state disabled
                .tpc.f1.e23 configure -state disabled
                .tpc.f1.e24 configure -state disabled
            } else {
                if { $vsql_driver eq "timed" } {
                    set vsql_keyandthink "true"
                    .tpc.f1.e22 configure -state normal
                    .tpc.f1.e23 configure -state normal
                    .tpc.f1.e24 configure -state normal
                }
            }
        }
        set Name $Parent.f1.e22
        set Prompt $Parent.f1.p22
        ttk::label $Prompt -text "Asynch Clients per Virtual User :"
        ttk::entry $Name -width 30 -textvariable vsql_async_client
        grid $Prompt -column 0 -row 34 -sticky e
        grid $Name -column 1 -row 34 -sticky ew
        if {$vsql_driver == "test" || $vsql_async_scale == "false" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e23
        set Prompt $Parent.f1.p23
        ttk::label $Prompt -text "Asynch Client Login Delay :"
        ttk::entry $Name -width 30 -textvariable vsql_async_delay
        grid $Prompt -column 0 -row 35 -sticky e
        grid $Name -column 1 -row 35 -sticky ew
        if {$vsql_driver == "test" || $vsql_async_scale == "false" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e24
        set Prompt $Parent.f1.p24
        ttk::label $Prompt -text "Asynchronous Verbose :"
        ttk::checkbutton $Name -text "" -variable vsql_async_verbose -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 36 -sticky e
        grid $Name -column 1 -row 36 -sticky ew
        if {$vsql_driver == "test" || $vsql_async_scale == "false" } {
            set vsql_async_verbose "false"
            $Name configure -state disabled
        }
        set Name $Parent.c1.e25
        set Prompt $Parent.c1.p25
        ttk::label $Prompt -text "Cluster Connect Pool :"
        ttk::checkbutton $Name -text "" -variable vsql_connect_pool -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 37 -sticky e
        grid $Name -column 1 -row 37 -sticky ew

	    if {$vsql_connect_pool == "true" } {
        set vsql_prepared "true"
        set vsql_no_stored_procs "false"
        }

         bind .tpc.c1.e25 <Any-ButtonRelease> {
            if { $vsql_connect_pool eq "false" } {
                set vsql_prepared "true"
                set vsql_no_stored_procs "false"
                .tpc.f1.e16a configure -state disabled
                if { $vsql_prepared eq "true" } {
                .tpc.f1.e16b configure -state disabled
                        }
            } else {
                set vsql_no_stored_procs "false"
                .tpc.f1.e16a configure -state normal
            }
    }
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
                copyfieldstoconfig configvillagesql [ subst $myfields ] tpcc
                Dict2SQLite "villagesql" $configvillagesql
                unset myfields
                check_vsql_ssl $configvillagesql
                destroy .tpc
                loadtpcc
            } -text {OK}
        }
        "default" {
            ttk::button $Name -command {
                set vsql_count_ware [ verify_warehouse $vsql_count_ware 100000 ]
                set vsql_num_vu [ verify_build_threads $vsql_num_vu $vsql_count_ware ]
                copyfieldstoconfig configvillagesql [ subst $myfields ] tpcc
                Dict2SQLite "villagesql" $configvillagesql
                unset myfields
                check_vsql_ssl $configvillagesql
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

proc configvsqltpch {option} {
    upvar #0 icons icons
    upvar #0 configvillagesql configvillagesql
    #set variables to values in dict
    setlocaltpchvars $configvillagesql
    global default_vsql_port
    set default_vsql_port $vsql_port
    set tpchfields [ dict create tpch {vsql_tpch_user {.mytpch.c1.e3 get} vsql_tpch_pass {.mytpch.c1.e4 get} vsql_tpch_dbase {.mytpch.c1.e5 get} vsql_tpch_storage_engine {.mytpch.f1.e6 get} vsql_total_querysets {.mytpch.f1.e9 get} vsql_update_sets {.mytpch.f1.e13 get} vsql_trickle_refresh {.mytpch.f1.e14 get} vsql_scale_fact $vsql_scale_fact  vsql_num_tpch_threads $vsql_num_tpch_threads vsql_refresh_on $vsql_refresh_on vsql_raise_query_error $vsql_raise_query_error vsql_verbose $vsql_verbose vsql_refresh_verbose $vsql_refresh_verbose vsql_cloud_query $vsql_cloud_query} ]
    #set matching fields in dialog to temporary dict
    if {![string match windows $::tcl_platform(platform)]} {
        set platform "lin"
    set vsqlconn [ dict create connection {vsql_host {.mytpch.c1.e1 get} vsql_port {.mytpch.c1.e2 get} vsql_socket {.mytpch.c1.e2a get} vsql_ssl_ca {.mytpch.c1.e2d get} vsql_ssl_cert {.mytpch.c1.e2e get} vsql_ssl_key {.mytpch.c1.e2f get} vsql_ssl_cipher {.mytpch.c1.e2g get} vsql_ssl $vsql_ssl vsql_ssl_two_way $vsql_ssl_two_way vsql_ssl_linux_capath {$vsql_ssl_linux_capath}} ]
        } else {
        set platform "win"
    set vsqlconn [ dict create connection {vsql_host {.mytpch.c1.e1 get} vsql_port {.mytpch.c1.e2 get} vsql_socket {.mytpch.c1.e2a get} vsql_ssl_ca {.mytpch.c1.e2d get} vsql_ssl_cert {.mytpch.c1.e2e get} vsql_ssl_key {.mytpch.c1.e2f get} vsql_ssl_cipher {.mytpch.c1.e2g get} vsql_ssl $vsql_ssl vsql_ssl_two_way $vsql_ssl_two_way vsql_ssl_windows_capath {$vsql_ssl_windows_capath}} ]
        }
    variable myfields
    set myfields [ dict merge $vsqlconn $tpchfields ]
    catch "destroy .mytpch"
    ttk::toplevel .mytpch
    wm transient .mytpch .ed_mainFrame
    wm withdraw .mytpch
    switch $option {
        "all" { wm title .mytpch {VillageSQL TPROC-H Schema Options} }
        "build" { wm title .mytpch {VillageSQL TPROC-H Build Options} }
        "drive" {  wm title .mytpch {VillageSQL TPROC-H Driver Options} }
    }
    set Parent .mytpch
    if { $option eq "all" || $option eq "build" } {
        set Prompt $Parent.h1
	ttk::label $Prompt -compound left -text "Build Options" -image [ create_image boxes icons ]
    	pack $Prompt -anchor center -side top
    } else {
        set Prompt $Parent.h2
	ttk::label $Prompt -compound left -text "Driver Options" -image [ create_image driveroptlo icons ]
    	pack $Prompt -anchor center -side top
    }
    set Name $Parent.notebook
    ttk::notebook $Name
    $Name add [ ttk::frame $Parent.c1 ] -text "Connection" -sticky ne
    $Name add [ ttk::frame $Parent.f1 ] -text "Settings" -sticky ne
    pack $Name -anchor nw -fill x -side top -padx 5
    set Name $Parent.c1.e1
    set Prompt $Parent.c1.p1
    ttk::label $Prompt -text "VillageSQL Host :"
    ttk::entry $Name -width 30 -textvariable vsql_host
    grid $Prompt -column 0 -row 1 -sticky e
    grid $Name -column 1 -row 1 -sticky ew
    set Name $Parent.c1.e2
    set Prompt $Parent.c1.p2
    ttk::label $Prompt -text "VillageSQL Port :"
    ttk::entry $Name  -width 30 -textvariable vsql_port
    grid $Prompt -column 0 -row 2 -sticky e
    grid $Name -column 1 -row 2 -sticky ew
    set Name $Parent.c1.e2a
    set Prompt $Parent.c1.p2a
    ttk::label $Prompt -text "VillageSQL Socket :"
    ttk::entry $Name  -width 30 -textvariable vsql_socket
    grid $Prompt -column 0 -row 3 -sticky e
    grid $Name -column 1 -row 3 -sticky ew

    if {[string match windows $::tcl_platform(platform)]} {
        set vsql_socket "null"
        .mytpch.c1.e2a configure -state disabled
    }

    set Name $Parent.c1.e2b
    set Prompt $Parent.c1.p2b
    ttk::label $Prompt -text "Enable SSL :"
    ttk::checkbutton $Name -text "" -variable vsql_ssl -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 4 -sticky e
    grid $Name -column 1 -row 4 -sticky w

    bind .mytpch.c1.e2b <Any-ButtonRelease> {
        if { $vsql_ssl eq "true" } {
            .mytpch.c1.e2ba configure -state disabled
            .mytpch.c1.e2bb configure -state disabled
            .mytpch.c1.e2c configure -state disabled
            .mytpch.c1.e2d configure -state disabled
            .mytpch.c1.e2e configure -state disabled
            .mytpch.c1.e2f configure -state disabled
            .mytpch.c1.e2g configure -state disabled
        } else {
            .mytpch.c1.e2ba configure -state normal
            .mytpch.c1.e2bb configure -state normal
            .mytpch.c1.e2c configure -state normal
            .mytpch.c1.e2d configure -state normal
            if { $vsql_ssl_two_way eq "true" } {
                .mytpch.c1.e2e configure -state normal
                .mytpch.c1.e2f configure -state normal
            }
            .mytpch.c1.e2g configure -state normal
        }
    }

    set Name $Parent.c1.e2ba
    ttk::radiobutton $Name -value "false" -text "SSL One-Way" -variable vsql_ssl_two_way
    grid $Name -column 1 -row 5 -sticky w
    if { $vsql_ssl eq "false" } {
        .mytpch.c1.e2ba configure -state disabled
    }
    bind .mytpch.c1.e2ba <ButtonPress-1> {
    if { $vsql_ssl eq "true" } {
        .mytpch.c1.e2e configure -state disabled
        .mytpch.c1.e2f configure -state disabled
       }
    }

    set Name $Parent.c1.e2bb
    ttk::radiobutton $Name -value "true" -text "SSL Two-Way" -variable vsql_ssl_two_way
    grid $Name -column 1 -row 6 -sticky w
    if { $vsql_ssl eq "false" } {
        .mytpch.c1.e2bb configure -state disabled
    }

    bind .mytpch.c1.e2bb <ButtonPress-1> {
    if { $vsql_ssl eq "true" } {
        .mytpch.c1.e2e configure -state normal
        .mytpch.c1.e2f configure -state normal
       }
    }

    set Name $Parent.c1.e2c
    set Prompt $Parent.c1.p2c
    ttk::label $Prompt -text "SSL CApath :"
    if { $platform eq "lin" } {
        ttk::entry $Name -width 30 -textvariable vsql_ssl_linux_capath
    } else {
        ttk::entry $Name -width 30 -textvariable vsql_ssl_windows_capath
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2d
    set Prompt $Parent.c1.p2d
    ttk::label $Prompt -text "SSL CA :"
    ttk::entry $Name  -width 30 -textvariable vsql_ssl_ca
    grid $Prompt -column 0 -row 8 -sticky e
    grid $Name -column 1 -row 8 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2e
    set Prompt $Parent.c1.p2e
    ttk::label $Prompt -text "SSL Cert :"
    ttk::entry $Name  -width 30 -textvariable vsql_ssl_cert
    grid $Prompt -column 0 -row 9 -sticky e
    grid $Name -column 1 -row 9 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2f
    set Prompt $Parent.c1.p2f
    ttk::label $Prompt -text "SSL Key :"
    ttk::entry $Name  -width 30 -textvariable vsql_ssl_key
    grid $Prompt -column 0 -row 10 -sticky e
    grid $Name -column 1 -row 10 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2g
    set Prompt $Parent.c1.p2g
    ttk::label $Prompt -text "SSL Cipher :"
    ttk::entry $Name  -width 30 -textvariable vsql_ssl_cipher
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e3
    set Prompt $Parent.c1.p3
    ttk::label $Prompt -text "VillageSQL User :"
    ttk::entry $Name  -width 30 -textvariable vsql_tpch_user
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew
    set Name $Parent.c1.e4
    set Prompt $Parent.c1.p4
    ttk::label $Prompt -text "VillageSQL User Password :"
    ttk::entry $Name -show * -width 30 -textvariable vsql_tpch_pass
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky ew
    set Name $Parent.c1.e5
    set Prompt $Parent.c1.p5
    ttk::label $Prompt -text "TPROC-H VillageSQL Database :" -image [ create_image hdbicon icons ] -compound left
    ttk::entry $Name -width 30 -textvariable vsql_tpch_dbase
    grid $Prompt -column 0 -row 14 -sticky e
    grid $Name -column 1 -row 14 -sticky ew
    if { $option eq "all" || $option eq "build" } {

        set Name $Parent.f1.e6
        set Prompt $Parent.f1.p6
        ttk::label $Prompt -text "Data Warehouse Storage Engine :"
        ttk::entry $Name -width 30 -textvariable vsql_tpch_storage_engine
        grid $Prompt -column 0 -row 18 -sticky e
        grid $Name -column 1 -row 18 -sticky ew
        set Name $Parent.f1.e7
        set Prompt $Parent.f1.p7
        ttk::label $Prompt -text "Scale Factor :"
        grid $Prompt -column 0 -row 19 -sticky e
        set Name $Parent.f1.f2
        ttk::frame $Name -width 30
        grid $Name -column 1 -row 19 -sticky ew
        # top row
        set rcnt 1
        foreach item {1} {
            set Name $Parent.f1.f2.r$rcnt
            set width [string length $item]
            ttk::radiobutton $Name -variable vsql_scale_fact -text $item -value $item -width $width
            grid $Name -column $rcnt -row 0 -sticky w
            incr rcnt
        }
        set rcnt 2
        foreach item {10 30} {
            set Name $Parent.f1.f2.r$rcnt
            set width [string length $item]
            ttk::radiobutton $Name -variable vsql_scale_fact -text $item -value $item -width $width
            grid $Name -column $rcnt -row 0 -sticky w
            incr rcnt
        }
        set rcnt 4
        foreach item {100 300} {
            set Name $Parent.f1.f2.r$rcnt
            set width [string length $item]
            ttk::radiobutton $Name -variable vsql_scale_fact -text $item -value $item -width $width
            grid $Name -column $rcnt -row 0 -sticky w
            incr rcnt
        }
        # bottom row
        set rcnt 1
        foreach item {1000 3000} {
            set Name $Parent.f1.f2.ra$rcnt
            set width [string length $item]
            ttk::radiobutton $Name -variable vsql_scale_fact -text $item -value $item -width $width
            grid $Name -column $rcnt -row 1 -sticky w
            incr rcnt
        }
        set rcnt 3
        foreach item {10000 30000 100000} {
            set Name $Parent.f1.f2.ra$rcnt
            set width [string length $item]
            ttk::radiobutton $Name -variable vsql_scale_fact -text $item -value $item -width $width
            grid $Name -column $rcnt -row 1 -sticky w
            incr rcnt
        }
        set Prompt $Parent.f1.p8
        ttk::label $Prompt -text "Virtual Users to Build Schema :"
        set Name $Parent.f1.e8
        ttk::spinbox $Name -from 1 -to 512 -textvariable vsql_num_tpch_threads
        grid $Prompt -column 0 -row 20 -sticky e
        grid $Name -column 1 -row 20 -sticky ew
    }

     if { $option eq "all" || $option eq "drive" } {
        if { $option eq "all" } {
            set Prompt $Parent.f1.h3
            ttk::label $Prompt -image [ create_image driveroptlo icons ]
            grid $Prompt -column 0 -row 21 -sticky e
            set Prompt $Parent.f1.h4
            ttk::label $Prompt -text "Driver Options"
            grid $Prompt -column 1 -row 21 -sticky w
        }
        set Name $Parent.f1.e9
        set Prompt $Parent.f1.p9
        ttk::label $Prompt -text "Total Query Sets per User :"


        ttk::entry $Name -width 30 -textvariable vsql_total_querysets
        grid $Prompt -column 0 -row 22 -sticky e
        grid $Name -column 1 -row 22  -columnspan 4 -sticky ew
        set Prompt $Parent.f1.p10
        ttk::label $Prompt -text "Exit on VillageSQL Error :"
        set Name $Parent.f1.e10
        ttk::checkbutton $Name -text "" -variable vsql_raise_query_error -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 23 -sticky e
        grid $Name -column 1 -row 23 -sticky w
        set Prompt $Parent.f1.p11
        ttk::label $Prompt -text "Verbose Output :"
        set Name $Parent.f1.e11
        ttk::checkbutton $Name -text "" -variable vsql_verbose -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 24 -sticky e
        grid $Name -column 1 -row 24 -sticky w
        set Prompt $Parent.f1.p12
        ttk::label $Prompt -text "Refresh Function :"
        set Name $Parent.f1.e12
        ttk::checkbutton $Name -text "" -variable vsql_refresh_on -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 25 -sticky e
        grid $Name -column 1 -row 25 -sticky w
        bind $Parent.f1.e12 <Button> {
            if {$vsql_refresh_on eq "true"} {
                set vsql_refresh_verbose "false"
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
        ttk::entry $Name -width 30 -textvariable vsql_update_sets
        grid $Prompt -column 0 -row 26 -sticky e
        grid $Name -column 1 -row 26  -columnspan 4 -sticky ew
        if {$vsql_refresh_on == "false" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e14
        set Prompt $Parent.f1.p14
        ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
        ttk::entry $Name -width 30 -textvariable vsql_trickle_refresh
        grid $Prompt -column 0 -row 27 -sticky e
        grid $Name -column 1 -row 27  -columnspan 4 -sticky ew
        if {$vsql_refresh_on == "false" } {
            $Name configure -state disabled
        }
        set Prompt $Parent.f1.p15
        ttk::label $Prompt -text "Refresh Verbose :"
        set Name $Parent.f1.e15
        ttk::checkbutton $Name -text "" -variable vsql_refresh_verbose -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 28 -sticky e
        grid $Name -column 1 -row 28 -sticky w
        if {$vsql_refresh_on == "false" } {
            $Name configure -state disabled
        }
        set Prompt $Parent.f1.p16
        ttk::label $Prompt -text "Cloud Analytic Queries :"
        set Name $Parent.f1.e16
        ttk::checkbutton $Name -text "" -variable vsql_cloud_query -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 29 -sticky e
        grid $Name -column 1 -row 29 -sticky w
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
                copyfieldstoconfig configvillagesql [ subst $myfields ] tpch
                Dict2SQLite "villagesql" $configvillagesql
                unset myfields
                check_vsql_ssl $configvillagesql
                destroy .mytpch
                loadtpch
            } -text {OK}
        }
        "default" {
            ttk::button $Name -command {
                set vsql_num_tpch_threads [ verify_build_threads $vsql_num_tpch_threads 512 ]
                copyfieldstoconfig configvillagesql [ subst $myfields ] tpch
                Dict2SQLite "villagesql" $configvillagesql
                unset myfields
                check_vsql_ssl $configvillagesql
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

proc metvsqlopts {} {
    global agent_hostname agent_id bm start_display cpu_only
    global default_vsql_port
    upvar #0 icons icons
    upvar #0 configvillagesql configvillagesql

    setlocaltcountvars $configvillagesql 1

    set default_vsql_port $vsql_port

    variable myoptsfields
    if { $bm eq "TPC-C" } {
        if {![string match windows $::tcl_platform(platform)]} {
            set platform "lin"
            set myoptsfields [ dict create connection {vsql_host {.metric.c1.e1 get} vsql_port {.metric.c1.e2 get} vsql_socket {.metric.c1.e2a get} vsql_ssl_ca {.metric.c1.e2d get} vsql_ssl_cert {.metric.c1.e2e get} vsql_ssl_key {.metric.c1.e2f get} vsql_ssl_cipher {.metric.c1.e2g get} vsql_ssl $vsql_ssl vsql_ssl_two_way $vsql_ssl_two_way vsql_ssl_linux_capath $vsql_ssl_linux_capath} tpcc {vsql_user {.metric.c1.e3 get} vsql_pass {.metric.c1.e4 get}} ]
        } else {
            set platform "win"
            set myoptsfields [ dict create connection {vsql_host {.metric.c1.e1 get} vsql_port {.metric.c1.e2 get} vsql_socket {.metric.c1.e2a get} vsql_ssl_ca {.metric.c1.e2d get} vsql_ssl_cert {.metric.c1.e2e get} vsql_ssl_key {.metric.c1.e2f get} vsql_ssl_cipher {.metric.c1.e2g get} vsql_ssl $vsql_ssl vsql_ssl_two_way $vsql_ssl_two_way vsql_ssl_windows_capath {$vsql_ssl_windows_capath}} tpcc {vsql_user {.metric.c1.e3 get} vsql_pass {.metric.c1.e4 get}} ]
        }
    } else {
        if {![string match windows $::tcl_platform(platform)]} {
            set platform "lin"
            set myoptsfields [ dict create connection {vsql_host {.metric.c1.e1 get} vsql_port {.metric.c1.e2 get} vsql_socket {.metric.c1.e2a get} vsql_ssl_ca {.metric.c1.e2d get} vsql_ssl_cert {.metric.c1.e2e get} vsql_ssl_key {.metric.c1.e2f get} vsql_ssl_cipher {.metric.c1.e2g get} vsql_ssl $vsql_ssl vsql_ssl_two_way $vsql_ssl_two_way vsql_ssl_linux_capath $vsql_ssl_linux_capath} tpch {vsql_tpch_user {.metric.c1.e3 get} vsql_tpch_pass {.metric.c1.e4 get}} ]
        } else {
            set platform "win"
            set myoptsfields [ dict create connection {vsql_host {.metric.c1.e1 get} vsql_port {.metric.c1.e2 get} vsql_socket {.metric.c1.e2a get} vsql_ssl_ca {.metric.c1.e2d get} vsql_ssl_cert {.metric.c1.e2e get} vsql_ssl_key {.metric.c1.e2f get} vsql_ssl_cipher {.metric.c1.e2g get} vsql_ssl $vsql_ssl vsql_ssl_two_way $vsql_ssl_two_way vsql_ssl_windows_capath {$vsql_ssl_windows_capath}} tpch {vsql_tpch_user {.metric.c1.e3 get} vsql_tpch_pass {.metric.c1.e4 get}} ]
        }
    }

    if { [ info exists agent_hostname ] } { ; } else { set agent_hostname "localhost" }
    if { [ info exists agent_id ] } { ; } else { set agent_id 0 }
    if { [ info exists cpu_only ] } { ; } else { set cpu_only "false" }
    if { [ info exists start_display ] } { ; } else { set start_display "true" }

    catch "destroy .metric"
    ttk::toplevel .metric
    wm transient .metric .ed_mainFrame
    wm withdraw .metric
    wm title .metric {VillageSQL Metrics Options}

    set Parent .metric
    set Prompt $Parent.h1
    ttk::label $Prompt -compound left -text "VillageSQL Metrics Options" -image [ create_image dashboard icons ]
    pack $Prompt -anchor center -side top

    set Name $Parent.notebook
    ttk::notebook $Name
    $Name add [ ttk::frame $Parent.c1 ] -text "Connection" -sticky ne
    $Name add [ ttk::frame $Parent.f1 ] -text "Settings" -sticky ne
    pack $Name -anchor nw -fill x -side top -padx 5

    set Name $Parent.c1.e1
    set Prompt $Parent.c1.p1
    ttk::label $Prompt -text "VillageSQL Host :"
    ttk::entry $Name -width 30 -textvariable vsql_host
    grid $Prompt -column 0 -row 1 -sticky e
    grid $Name -column 1 -row 1 -sticky ew

    set Name $Parent.c1.e2
    set Prompt $Parent.c1.p2
    ttk::label $Prompt -text "VillageSQL Port :"
    ttk::entry $Name -width 30 -textvariable vsql_port
    grid $Prompt -column 0 -row 2 -sticky e
    grid $Name -column 1 -row 2 -sticky ew

    set Name $Parent.c1.e2a
    set Prompt $Parent.c1.p2a
    ttk::label $Prompt -text "VillageSQL Socket :"
    ttk::entry $Name -width 30 -textvariable vsql_socket
    grid $Prompt -column 0 -row 3 -sticky e
    grid $Name -column 1 -row 3 -sticky ew
    if {[string match windows $::tcl_platform(platform)]} {
        set vsql_socket "null"
        .metric.c1.e2a configure -state disabled
    }

    set Name $Parent.c1.e2b
    set Prompt $Parent.c1.p2b
    ttk::label $Prompt -text "Enable SSL :"
    ttk::checkbutton $Name -text "" -variable vsql_ssl -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 4 -sticky e
    grid $Name -column 1 -row 4 -sticky w

    bind .metric.c1.e2b <Any-ButtonRelease> {
        if { $vsql_ssl eq "true" } {
            .metric.c1.e2ba configure -state disabled
            .metric.c1.e2bb configure -state disabled
            .metric.c1.e2c configure -state disabled
            .metric.c1.e2d configure -state disabled
            .metric.c1.e2e configure -state disabled
            .metric.c1.e2f configure -state disabled
            .metric.c1.e2g configure -state disabled
        } else {
            .metric.c1.e2ba configure -state normal
            .metric.c1.e2bb configure -state normal
            .metric.c1.e2c configure -state normal
            .metric.c1.e2d configure -state normal
            if { $vsql_ssl_two_way eq "true" } {
                .metric.c1.e2e configure -state normal
                .metric.c1.e2f configure -state normal
            }
            .metric.c1.e2g configure -state normal
        }
    }

    set Name $Parent.c1.e2ba
    ttk::radiobutton $Name -value "false" -text "SSL One-Way" -variable vsql_ssl_two_way
    grid $Name -column 1 -row 5 -sticky w
    if { $vsql_ssl eq "false" } {
        .metric.c1.e2ba configure -state disabled
    }
    bind .metric.c1.e2ba <ButtonPress-1> {
        if { $vsql_ssl eq "true" } {
            .metric.c1.e2e configure -state disabled
            .metric.c1.e2f configure -state disabled
        }
    }

    set Name $Parent.c1.e2bb
    ttk::radiobutton $Name -value "true" -text "SSL Two-Way" -variable vsql_ssl_two_way
    grid $Name -column 1 -row 6 -sticky w
    if { $vsql_ssl eq "false" } {
        .metric.c1.e2bb configure -state disabled
    }
    bind .metric.c1.e2bb <ButtonPress-1> {
        if { $vsql_ssl eq "true" } {
            .metric.c1.e2e configure -state normal
            .metric.c1.e2f configure -state normal
        }
    }

    set Name $Parent.c1.e2c
    set Prompt $Parent.c1.p2c
    ttk::label $Prompt -text "SSL CApath :"
    if { $platform eq "lin" } {
        ttk::entry $Name -width 30 -textvariable vsql_ssl_linux_capath
    } else {
        ttk::entry $Name -width 30 -textvariable vsql_ssl_windows_capath
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2d
    set Prompt $Parent.c1.p2d
    ttk::label $Prompt -text "SSL CA :"
    ttk::entry $Name -width 30 -textvariable vsql_ssl_ca
    grid $Prompt -column 0 -row 8 -sticky e
    grid $Name -column 1 -row 8 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2e
    set Prompt $Parent.c1.p2e
    ttk::label $Prompt -text "SSL Cert :"
    ttk::entry $Name -width 30 -textvariable vsql_ssl_cert
    grid $Prompt -column 0 -row 9 -sticky e
    grid $Name -column 1 -row 9 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2f
    set Prompt $Parent.c1.p2f
    ttk::label $Prompt -text "SSL Key :"
    ttk::entry $Name -width 30 -textvariable vsql_ssl_key
    grid $Prompt -column 0 -row 10 -sticky e
    grid $Name -column 1 -row 10 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e2g
    set Prompt $Parent.c1.p2g
    ttk::label $Prompt -text "SSL Cipher :"
    ttk::entry $Name -width 30 -textvariable vsql_ssl_cipher
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
    if { $vsql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.c1.e3
    set Prompt $Parent.c1.p3
    ttk::label $Prompt -text "VillageSQL User :"
    if { $bm eq "TPC-C" } {
        ttk::entry $Name -width 30 -textvariable vsql_user
    } else {
        ttk::entry $Name -width 30 -textvariable vsql_tpch_user
    }
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew

    set Name $Parent.c1.e4
    set Prompt $Parent.c1.p4
    ttk::label $Prompt -text "VillageSQL User Password :"
    if { $bm eq "TPC-C" } {
        ttk::entry $Name -show * -width 30 -textvariable vsql_pass
    } else {
        ttk::entry $Name -show * -width 30 -textvariable vsql_tpch_pass
    }
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky ew

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

    set Name $Parent.f1.e9
    set Prompt $Parent.f1.p9
    ttk::label $Prompt -text "Agent Start :"
    ttk::button $Name -command {
        if { $agent_hostname eq "localhost" || $agent_hostname eq [ info hostname ] } {
            agstart $agent_id $start_display
        } else {
            tk_messageBox -message "Agent hostname must be local to start, start manually on remote hosts"
        }
    } -text Start
    grid $Prompt -column 0 -row 9 -sticky e
    grid $Name -column 1 -row 9 -sticky w
    if { !($agent_hostname eq "localhost" || $agent_hostname eq [ info hostname ]) } {
        $Name configure -state disabled
    }

    set Name $Parent.f1.e10
    set Prompt $Parent.f1.p10
    ttk::label $Prompt -text "Agent Stop :"
    ttk::button $Name -command {
        agstop $agent_hostname $agent_id
    } -text Stop
    grid $Prompt -column 0 -row 10 -sticky e
    grid $Name -column 1 -row 10 -sticky w

    set Name $Parent.f1.e11
    set Prompt $Parent.f1.p11
    ttk::label $Prompt -text "Agent Status :"
    ttk::button $Name -command {
        agstatus $agent_hostname $agent_id
    } -text Status
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky w

    set Name $Parent.f1.e12
    set Prompt $Parent.f1.p12
    ttk::label $Prompt -text "CPU Metrics Only :"
    ttk::checkbutton $Name -text "" -variable cpu_only -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky w

    set Name $Parent.f1.e13
    set Prompt $Parent.f1.p13
    ttk::label $Prompt -text "Start Display with Local Agent :"
    ttk::checkbutton $Name -text "" -variable start_display -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky w
    if { !($agent_hostname eq "localhost" || $agent_hostname eq [ info hostname ]) } {
        set start_display false
        $Name configure -state disabled
    }

    bind .metric.c1.e1 <Delete> {
        if [%W selection present] {
            %W delete sel.first sel.last
        } else {
            %W delete insert
        }
    }

    set Name $Parent.b4
    ttk::button $Name -command {
        unset -nocomplain myoptsfields
        destroy .metric
    } -text Cancel
    pack $Name -anchor w -side right -padx 3 -pady 3

    set Name $Parent.b5
    ttk::button $Name -command {
        set agent_id [.metric.f1.e7 get]
        set agent_hostname [.metric.f1.e8 get]
        if { $bm eq "TPC-C" } {
            copyfieldstoconfig configvillagesql [ subst $myoptsfields ] tpcc
            unset myoptsfields
        } else {
            copyfieldstoconfig configvillagesql [ subst $myoptsfields ] tpch
            unset myoptsfields
        }
        Dict2SQLite "villagesql" $configvillagesql
        check_vsql_ssl $configvillagesql
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
