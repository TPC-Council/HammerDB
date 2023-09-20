proc check_mysql_ssl { configdict } {
    global mysql_ssl_options
    unset -nocomplain mysql_ssl_options
    upvar #0 configmysql configmysql
    #set local variables to dict for checking
    foreach key [ dict keys [ dict get $configdict connection ] *ssl* ] {
        set $key [ dict get $configdict connection $key ]
    }
    #Use correct directory
    if {![string match windows $::tcl_platform(platform)]} {
        set capath $mysql_ssl_linux_capath
    } else {
        set capath $mysql_ssl_windows_capath
    }
    #If SSL not enabled return
    if { $mysql_ssl != "true" } { 
        #nothing to check, mysql_ssl_options is not set
        set mysql_ssl_options " -ssl false "
        return	
    } else {
        #SSL is enabled, check that capath is valid
        if { [ file isdirectory $capath ] } {
            if { $mysql_ssl_ca eq "" && $mysql_ssl_cert eq "" && $mysql_ssl_key eq "" } {
                #All of the file entries are blank, use capath only
            } else {
                #CApath is valid, file entries are not blank, always check CA
                if { [ file readable [ file join $capath $mysql_ssl_ca ]] } {
                } else {
                    tk_messageBox -message "[ file join $capath $mysql_ssl_ca ] is not readable, disabling SSL"
                    dict set configmysql connection mysql_ssl "false"
                    return
                }
                #capath and ca are readable
                if { $mysql_ssl_two_way eq "true" } {
                    #Also check Cert and Key readable
                    foreach sslfile [ list $mysql_ssl_cert $mysql_ssl_key ] {
                        if { [ file readable [ file join $capath $sslfile ]] } {
                        } else {
                            tk_messageBox -message "[ file join $capath $sslfile ] is not readable, disabling SSL"
                            dict set configmysql connection mysql_ssl "false"
                            return
                        }
                    }
                }
            }
        } else {
            tk_messageBox -message "SSL CApath is not a valid directory, disabling SSL"
            #Set SSL to false
            dict set configmysql connection mysql_ssl "false"
            return
        }
    }
    #SSL is true and all files needed are readable, build options
    append mysql_ssl_options " -ssl true "
    if { $mysql_ssl_ca eq "" && $mysql_ssl_cert eq "" && $mysql_ssl_key eq "" } {
        #No files given as an argument use -capath only
        append mysql_ssl_options " -sslcapath $capath "
    } else {
        #for one-way use -sslca only
        append mysql_ssl_options " -sslca [ file join $capath $mysql_ssl_ca ] "
        if { $mysql_ssl_two_way eq "true" } {
            #for two-way add -sslcert & -sslkey
            append mysql_ssl_options " -sslcert [ file join $capath $mysql_ssl_cert ] "
            append mysql_ssl_options " -sslkey [ file join $capath $mysql_ssl_key ] "
        } 
    }
    #if ssl_cipher has changed add the option
    if { $mysql_ssl_cipher != "server" } { append mysql_ssl_options " -sslcipher $mysql_ssl_cipher " } 
}

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
        if {![string match windows $::tcl_platform(platform)]} {
            set platform "lin"
            set mysqloptsfields [ dict create connection {mysql_host {.countopt.f1.e1 get} mysql_port {.countopt.f1.e2 get} mysql_socket {.countopt.f1.e2a get} mysql_ssl_ca {.countopt.f1.e2d get} mysql_ssl_cert {.countopt.f1.e2e get} mysql_ssl_key {.countopt.f1.e2f get} mysql_ssl_cipher {.countopt.f1.e2g get} mysql_ssl $mysql_ssl mysql_ssl_two_way $mysql_ssl_two_way mysql_ssl_linux_capath $mysql_ssl_linux_capath} tpcc {mysql_user {.countopt.f1.e3 get} mysql_pass {.countopt.f1.e4 get}} ]
        } else {
            set platform "win"
            set mysqloptsfields [ dict create connection {mysql_host {.countopt.f1.e1 get} mysql_port {.countopt.f1.e2 get} mysql_socket {.countopt.f1.e2a get} mysql_ssl_ca {.countopt.f1.e2d get} mysql_ssl_cert {.countopt.f1.e2e get} mysql_ssl_key {.countopt.f1.e2f get} mysql_ssl_cipher {.countopt.f1.e2g get} mysql_ssl $mysql_ssl mysql_ssl_two_way $mysql_ssl_two_way mysql_ssl_windows_capath {$mysql_ssl_windows_capath}} tpcc {mysql_user {.countopt.f1.e3 get} mysql_pass {.countopt.f1.e4 get}} ]
        }
    } else {
        if {![string match windows $::tcl_platform(platform)]} {
            set platform "lin"
            set mysqloptsfields [ dict create connection {mysql_host {.countopt.f1.e1 get} mysql_port {.countopt.f1.e2 get} mysql_socket {.countopt.f1.e2a get} mysql_ssl_ca {.countopt.f1.e2d get} mysql_ssl_cert {.countopt.f1.e2e get} mysql_ssl_key {.countopt.f1.e2f get} mysql_ssl_cipher {.countopt.f1.e2g get} mysql_ssl $mysql_ssl mysql_ssl_two_way $mysql_ssl_two_way mysql_ssl_linux_capath $mysql_ssl_linux_capath} tpch {mysql_tpch_user {.countopt.f1.e3 get} mysql_tpch_pass {.countopt.f1.e4 get}} ]
        } else {
            set platform "win"
            set mysqloptsfields [ dict create connection {mysql_host {.countopt.f1.e1 get} mysql_port {.countopt.f1.e2 get} mysql_socket {.countopt.f1.e2a get} mysql_ssl_ca {.countopt.f1.e2d get} mysql_ssl_cert {.countopt.f1.e2e get} mysql_ssl_key {.countopt.f1.e2f get} mysql_ssl_cipher {.countopt.f1.e2g get} mysql_ssl $mysql_ssl mysql_ssl_two_way $mysql_ssl_two_way mysql_ssl_windows_capath {$mysql_ssl_windows_capath}} tpch {mysql_tpch_user {.countopt.f1.e3 get} mysql_tpch_pass {.countopt.f1.e4 get}} ]
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

    set Name $Parent.f1.e2b
    set Prompt $Parent.f1.p2b
    ttk::label $Prompt -text "Enable SSL :"
    ttk::checkbutton $Name -text "" -variable mysql_ssl -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 4 -sticky e
    grid $Name -column 1 -row 4 -sticky w
    
    bind .countopt.f1.e2b <Any-ButtonRelease> {
        if { $mysql_ssl eq "true" } {
            .countopt.f1.e2ba configure -state disabled
            .countopt.f1.e2bb configure -state disabled
            .countopt.f1.e2c configure -state disabled
            .countopt.f1.e2d configure -state disabled
            .countopt.f1.e2e configure -state disabled
            .countopt.f1.e2f configure -state disabled
            .countopt.f1.e2g configure -state disabled
        } else {
            .countopt.f1.e2ba configure -state normal
            .countopt.f1.e2bb configure -state normal
            .countopt.f1.e2c configure -state normal
            .countopt.f1.e2d configure -state normal
            if { $mysql_ssl_two_way eq "true" } {
                .countopt.f1.e2e configure -state normal
                .countopt.f1.e2f configure -state normal
            }
            .countopt.f1.e2g configure -state normal
        }
    }
    
    set Name $Parent.f1.e2ba
    ttk::radiobutton $Name -value "false" -text "SSL One-Way" -variable mysql_ssl_two_way
    grid $Name -column 1 -row 5 -sticky w
    if { $mysql_ssl eq "false" } {
        .countopt.f1.e2ba configure -state disabled
    }
    bind .countopt.f1.e2ba <ButtonPress-1> {
        .countopt.f1.e2e configure -state disabled
        .countopt.f1.e2f configure -state disabled
    }
    
    set Name $Parent.f1.e2bb
    ttk::radiobutton $Name -value "true" -text "SSL Two-Way" -variable mysql_ssl_two_way
    grid $Name -column 1 -row 6 -sticky w
    if { $mysql_ssl eq "false" } {
        .countopt.f1.e2bb configure -state disabled
    }
    
    bind .countopt.f1.e2bb <ButtonPress-1> {
        .countopt.f1.e2e configure -state normal
        .countopt.f1.e2f configure -state normal
    }
    
    set Name $Parent.f1.e2c
    set Prompt $Parent.f1.p2c
    ttk::label $Prompt -text "SSL CApath :"
    if { $platform eq "lin" } {
        ttk::entry $Name -width 30 -textvariable mysql_ssl_linux_capath
    } else {
        ttk::entry $Name -width 30 -textvariable mysql_ssl_windows_capath
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }
    
    set Name $Parent.f1.e2d
    set Prompt $Parent.f1.p2d
    ttk::label $Prompt -text "SSL CA :"
    ttk::entry $Name  -width 30 -textvariable mysql_ssl_ca
    grid $Prompt -column 0 -row 8 -sticky e
    grid $Name -column 1 -row 8 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }
    
    set Name $Parent.f1.e2e
    set Prompt $Parent.f1.p2e
    ttk::label $Prompt -text "SSL Cert :"
    ttk::entry $Name  -width 30 -textvariable mysql_ssl_cert
    grid $Prompt -column 0 -row 9 -sticky e
    grid $Name -column 1 -row 9 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }
    
    set Name $Parent.f1.e2f
    set Prompt $Parent.f1.p2f
    ttk::label $Prompt -text "SSL Key :"
    ttk::entry $Name  -width 30 -textvariable mysql_ssl_key
    grid $Prompt -column 0 -row 10 -sticky e
    grid $Name -column 1 -row 10 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }
    
    set Name $Parent.f1.e2g
    set Prompt $Parent.f1.p2g
    ttk::label $Prompt -text "SSL Cipher :"
    ttk::entry $Name  -width 30 -textvariable mysql_ssl_cipher
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.f1.e3
    set Prompt $Parent.f1.p3
    ttk::label $Prompt -text "MySQL User :"
    if { $bm eq "TPC-C" } {
        ttk::entry $Name  -width 30 -textvariable mysql_user
    } else {
        ttk::entry $Name  -width 30 -textvariable mysql_tpch_user
    }
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew
    set Name $Parent.f1.e4
    set Prompt $Parent.f1.p4
    ttk::label $Prompt -text "MySQL User Password :"   
    if { $bm eq "TPC-C" } {
        ttk::entry $Name -show * -width 30 -textvariable mysql_pass
    } else {
        ttk::entry $Name -show * -width 30 -textvariable mysql_tpch_pass
    }
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky ew
    set Name $Parent.f1.e5
    set Prompt $Parent.f1.p5
    ttk::label $Prompt -text "Refresh Rate(secs) :"
    ttk::entry $Name -width 30 -textvariable interval
    grid $Prompt -column 0 -row 14 -sticky e
    grid $Name -column 1 -row 14 -sticky ew

    set Name $Parent.f1.e7
    ttk::checkbutton $Name -text "Log Output to Temp" -variable tclog -onvalue 1 -offvalue 0
    grid $Name -column 1 -row 15 -sticky w
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
    grid $Name -column 1 -row 16 -sticky w
    if {$tclog == 0} {
        $Name configure -state disabled
    }

    set Name $Parent.f1.e9
    ttk::checkbutton $Name -text "Log Timestamps" -variable tcstamp -onvalue 1 -offvalue 0
    grid $Name -column 1 -row 17 -sticky w
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
            Dict2SQLite "mysql" $configmysql
            unset myoptsfields
            check_mysql_ssl $configmysql
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
            Dict2SQLite "mysql" $configmysql
            unset myoptsfields
            check_mysql_ssl $configmysql
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
    set tpccfields [ dict create tpcc {mysql_user {.tpc.f1.e3 get} mysql_pass {.tpc.f1.e4 get} mysql_dbase {.tpc.f1.e5 get} mysql_storage_engine {.tpc.f1.e6 get} mysql_total_iterations {.tpc.f1.e14 get} mysql_rampup {.tpc.f1.e17 get} mysql_duration {.tpc.f1.e18 get} mysql_async_client {.tpc.f1.e22 get} mysql_async_delay {.tpc.f1.e23 get} mysql_count_ware $mysql_count_ware mysql_num_vu $mysql_num_vu mysql_partition $mysql_partition mysql_driver $mysql_driver mysql_raiseerror $mysql_raiseerror mysql_keyandthink $mysql_keyandthink mysql_allwarehouse $mysql_allwarehouse mysql_timeprofile $mysql_timeprofile mysql_async_scale $mysql_async_scale mysql_async_verbose $mysql_async_verbose mysql_prepared $mysql_prepared mysql_no_stored_procs $mysql_no_stored_procs mysql_connect_pool $mysql_connect_pool mysql_history_pk $mysql_history_pk} ]
    if {![string match windows $::tcl_platform(platform)]} {
        set platform "lin"
        set mysqlconn [ dict create connection {mysql_host {.tpc.f1.e1 get} mysql_port {.tpc.f1.e2 get} mysql_socket {.tpc.f1.e2a get} mysql_ssl_ca {.tpc.f1.e2d get} mysql_ssl_cert {.tpc.f1.e2e get} mysql_ssl_key {.tpc.f1.e2f get} mysql_ssl_cipher {.tpc.f1.e2g get} mysql_ssl $mysql_ssl mysql_ssl_two_way $mysql_ssl_two_way mysql_ssl_linux_capath $mysql_ssl_linux_capath} ]
    } else {
        set platform "win"
        set mysqlconn [ dict create connection {mysql_host {.tpc.f1.e1 get} mysql_port {.tpc.f1.e2 get} mysql_socket {.tpc.f1.e2a get} mysql_ssl_ca {.tpc.f1.e2d get} mysql_ssl_cert {.tpc.f1.e2e get} mysql_ssl_key {.tpc.f1.e2f get} mysql_ssl_cipher {.tpc.f1.e2g get} mysql_ssl $mysql_ssl mysql_ssl_two_way $mysql_ssl_two_way mysql_ssl_windows_capath {$mysql_ssl_windows_capath}} ]
    }
    variable myfields
    set myfields [ dict merge $mysqlconn $tpccfields ]
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
        set mysql_socket "null"
        .tpc.f1.e2a configure -state disabled
    }

    set Name $Parent.f1.e2b
    set Prompt $Parent.f1.p2b
    ttk::label $Prompt -text "Enable SSL :"
    ttk::checkbutton $Name -text "" -variable mysql_ssl -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 4 -sticky e
    grid $Name -column 1 -row 4 -sticky w
    
    bind .tpc.f1.e2b <Any-ButtonRelease> {
        if { $mysql_ssl eq "true" } {
            .tpc.f1.e2ba configure -state disabled
            .tpc.f1.e2bb configure -state disabled
            .tpc.f1.e2c configure -state disabled
            .tpc.f1.e2d configure -state disabled
            .tpc.f1.e2e configure -state disabled
            .tpc.f1.e2f configure -state disabled
            .tpc.f1.e2g configure -state disabled
        } else {
            .tpc.f1.e2ba configure -state normal
            .tpc.f1.e2bb configure -state normal
            .tpc.f1.e2c configure -state normal
            .tpc.f1.e2d configure -state normal
            if { $mysql_ssl_two_way eq "true" } {
                .tpc.f1.e2e configure -state normal
                .tpc.f1.e2f configure -state normal
            }
            .tpc.f1.e2g configure -state normal
        }
    }
    
    set Name $Parent.f1.e2ba
    ttk::radiobutton $Name -value "false" -text "SSL One-Way" -variable mysql_ssl_two_way
    grid $Name -column 1 -row 5 -sticky w
    if { $mysql_ssl eq "false" } {
        .tpc.f1.e2ba configure -state disabled
    }
    bind .tpc.f1.e2ba <ButtonPress-1> {
        .tpc.f1.e2e configure -state disabled
        .tpc.f1.e2f configure -state disabled
    }
    
    set Name $Parent.f1.e2bb
    ttk::radiobutton $Name -value "true" -text "SSL Two-Way" -variable mysql_ssl_two_way
    grid $Name -column 1 -row 6 -sticky w
    if { $mysql_ssl eq "false" } {
        .tpc.f1.e2bb configure -state disabled
    }
    
    bind .tpc.f1.e2bb <ButtonPress-1> {
        .tpc.f1.e2e configure -state normal
        .tpc.f1.e2f configure -state normal
    }
    
    set Name $Parent.f1.e2c
    set Prompt $Parent.f1.p2c
    ttk::label $Prompt -text "SSL CApath :"
    if { $platform eq "lin" } {
        ttk::entry $Name -width 30 -textvariable mysql_ssl_linux_capath
    } else {
        ttk::entry $Name -width 30 -textvariable mysql_ssl_windows_capath
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }
    
    set Name $Parent.f1.e2d
    set Prompt $Parent.f1.p2d
    ttk::label $Prompt -text "SSL CA :"
    ttk::entry $Name  -width 30 -textvariable mysql_ssl_ca
    grid $Prompt -column 0 -row 8 -sticky e
    grid $Name -column 1 -row 8 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }
    
    set Name $Parent.f1.e2e
    set Prompt $Parent.f1.p2e
    ttk::label $Prompt -text "SSL Cert :"
    ttk::entry $Name  -width 30 -textvariable mysql_ssl_cert
    grid $Prompt -column 0 -row 9 -sticky e
    grid $Name -column 1 -row 9 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }
    
    set Name $Parent.f1.e2f
    set Prompt $Parent.f1.p2f
    ttk::label $Prompt -text "SSL Key :"
    ttk::entry $Name  -width 30 -textvariable mysql_ssl_key
    grid $Prompt -column 0 -row 10 -sticky e
    grid $Name -column 1 -row 10 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }
    
    set Name $Parent.f1.e2g
    set Prompt $Parent.f1.p2g
    ttk::label $Prompt -text "SSL Cipher :"
    ttk::entry $Name  -width 30 -textvariable mysql_ssl_cipher
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.f1.e3
    set Prompt $Parent.f1.p3
    ttk::label $Prompt -text "MySQL User :"
    ttk::entry $Name  -width 30 -textvariable mysql_user
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew
    set Name $Parent.f1.e4
    set Prompt $Parent.f1.p4
    ttk::label $Prompt -text "MySQL User Password :"   
    ttk::entry $Name -show * -width 30 -textvariable mysql_pass
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky ew
    set Name $Parent.f1.e5
    set Prompt $Parent.f1.p5
    ttk::label $Prompt -text "TPROC-C MySQL Database :" -image [ create_image hdbicon icons ] -compound left
    ttk::entry $Name -width 30 -textvariable mysql_dbase
    grid $Prompt -column 0 -row 14 -sticky e
    grid $Name -column 1 -row 14 -sticky ew
    if { $option eq "all" || $option eq "build" } {
        set Name $Parent.f1.e6
        set Prompt $Parent.f1.p6
        ttk::label $Prompt -text "Transactional Storage Engine :"
        ttk::entry $Name -width 30 -textvariable mysql_storage_engine
        grid $Prompt -column 0 -row 15 -sticky e
        grid $Name -column 1 -row 15 -sticky ew
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
        grid $Prompt -column 0 -row 16 -sticky e
        grid $Name -column 1 -row 16 -sticky ew
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
        grid $Prompt -column 0 -row 17 -sticky e
        grid $Name -column 1 -row 17 -sticky ew
        set Prompt $Parent.f1.p10
        ttk::label $Prompt -text "Partition Order Line Table :"
        set Name $Parent.f1.e10
        ttk::checkbutton $Name -text "" -variable mysql_partition -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 18 -sticky e
        grid $Name -column 1 -row 18 -sticky w
        if {$mysql_count_ware <= 200 } {
            $Name configure -state disabled
        }
	grid $Prompt -column 0 -row 19 -sticky e
        grid $Name -column 1 -row 19 -sticky ew
        set Prompt $Parent.f1.p11
        ttk::label $Prompt -text "History Table Primary Key :"
        set Name $Parent.f1.e11
        ttk::checkbutton $Name -text "" -variable mysql_history_pk -onvalue "true" -offvalue "false"
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
        ttk::radiobutton $Name -value "test" -text "Test Driver Script" -variable mysql_driver
        grid $Name -column 1 -row 22 -sticky w
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
        grid $Name -column 1 -row 23 -sticky w
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
        grid $Prompt -column 0 -row 24 -sticky e
        grid $Name -column 1 -row 24 -sticky ew
        set Prompt $Parent.f1.p15
        ttk::label $Prompt -text "Exit on MySQL Error :"
        set Name $Parent.f1.e15
        ttk::checkbutton $Name -text "" -variable mysql_raiseerror -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 25 -sticky e
        grid $Name -column 1 -row 25 -sticky w
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
        grid $Prompt -column 0 -row 26 -sticky e
        grid $Name -column 1 -row 26 -sticky w
        set Prompt $Parent.f1.p16a
        ttk::label $Prompt -text "Prepare Statements :"
        set Name $Parent.f1.e16a
        ttk::checkbutton $Name -text "" -variable mysql_prepared -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 27 -sticky e
        grid $Name -column 1 -row 27 -sticky w
	 if { $mysql_connect_pool } { set mysql_prepared "true"
        .tpc.f1.e16a configure -state disabled
        }
         bind .tpc.f1.e16a <Any-ButtonRelease> {
            if { $mysql_prepared eq "false" } {
                set mysql_no_stored_procs "false"
                .tpc.f1.e16b configure -state disabled
            } else {
                    if { $mysql_connect_pool eq "false" } {
                .tpc.f1.e16b configure -state normal
                        }
            }
    }
	set Prompt $Parent.f1.p16b
        ttk::label $Prompt -text "No Stored Procedures :"
        set Name $Parent.f1.e16b
        ttk::checkbutton $Name -text "" -variable mysql_no_stored_procs -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 28 -sticky e
        grid $Name -column 1 -row 28 -sticky w
        if { $mysql_connect_pool || $mysql_prepared } {
	set mysql_no_stored_procs "false"
        .tpc.f1.e16b configure -state disabled
        }

        set Name $Parent.f1.e17
        set Prompt $Parent.f1.p17
        ttk::label $Prompt -text "Minutes of Rampup Time :"
        ttk::entry $Name -width 30 -textvariable mysql_rampup
        grid $Prompt -column 0 -row 29 -sticky e
        grid $Name -column 1 -row 29 -sticky ew
        if {$mysql_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e18
        set Prompt $Parent.f1.p18
        ttk::label $Prompt -text "Minutes for Test Duration :"
        ttk::entry $Name -width 30 -textvariable mysql_duration
        grid $Prompt -column 0 -row 30 -sticky e
        grid $Name -column 1 -row 30 -sticky ew
        if {$mysql_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e19
        set Prompt $Parent.f1.p19
        ttk::label $Prompt -text "Use All Warehouses :"
        ttk::checkbutton $Name -text "" -variable mysql_allwarehouse -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 31 -sticky e
        grid $Name -column 1 -row 31 -sticky ew
        if {$mysql_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e20
        set Prompt $Parent.f1.p20
        ttk::label $Prompt -text "Time Profile :"
        ttk::checkbutton $Name -text "" -variable mysql_timeprofile -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 32 -sticky e
        grid $Name -column 1 -row 32 -sticky ew
        if {$mysql_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e21
        set Prompt $Parent.f1.p21
        ttk::label $Prompt -text "Asynchronous Scaling :"
        ttk::checkbutton $Name -text "" -variable mysql_async_scale -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 33 -sticky e
        grid $Name -column 1 -row 33 -sticky ew
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
        grid $Prompt -column 0 -row 34 -sticky e
        grid $Name -column 1 -row 34 -sticky ew
        if {$mysql_driver == "test" || $mysql_async_scale == "false" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e23
        set Prompt $Parent.f1.p23
        ttk::label $Prompt -text "Asynch Client Login Delay :"
        ttk::entry $Name -width 30 -textvariable mysql_async_delay
        grid $Prompt -column 0 -row 35 -sticky e
        grid $Name -column 1 -row 35 -sticky ew
        if {$mysql_driver == "test" || $mysql_async_scale == "false" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e24
        set Prompt $Parent.f1.p24
        ttk::label $Prompt -text "Asynchronous Verbose :"
        ttk::checkbutton $Name -text "" -variable mysql_async_verbose -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 36 -sticky e
        grid $Name -column 1 -row 36 -sticky ew
        if {$mysql_driver == "test" || $mysql_async_scale == "false" } {
            set mysql_async_verbose "false"
            $Name configure -state disabled
        }
        set Name $Parent.f1.e25
        set Prompt $Parent.f1.p25
        ttk::label $Prompt -text "XML Connect Pool :"
        ttk::checkbutton $Name -text "" -variable mysql_connect_pool -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 37 -sticky e
        grid $Name -column 1 -row 37 -sticky ew

	    if {$mysql_connect_pool == "true" } {
        set mysql_prepared "true"
        set mysql_no_stored_procs "false"
        }

         bind .tpc.f1.e25 <Any-ButtonRelease> {
            if { $mysql_connect_pool eq "false" } {
                set mysql_prepared "true"
                set mysql_no_stored_procs "false"
                .tpc.f1.e16a configure -state disabled
                if { $mysql_prepared eq "true" } {
                .tpc.f1.e16b configure -state disabled
                        }
            } else {
                set mysql_no_stored_procs "false"
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
                copyfieldstoconfig configmysql [ subst $myfields ] tpcc
                Dict2SQLite "mysql" $configmysql
                unset myfields
                check_mysql_ssl $configmysql
                destroy .tpc
                loadtpcc
            } -text {OK}
        }
        "default" {
            ttk::button $Name -command {
                set mysql_count_ware [ verify_warehouse $mysql_count_ware 100000 ]
                set mysql_num_vu [ verify_build_threads $mysql_num_vu $mysql_count_ware 1024 ]
                copyfieldstoconfig configmysql [ subst $myfields ] tpcc
                Dict2SQLite "mysql" $configmysql
                unset myfields
                check_mysql_ssl $configmysql
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
    set tpchfields [ dict create tpch {mysql_tpch_user {.mytpch.f1.e3 get} mysql_tpch_pass {.mytpch.f1.e4 get} mysql_tpch_dbase {.mytpch.f1.e5 get} mysql_tpch_storage_engine {.mytpch.f1.e6 get} mysql_total_querysets {.mytpch.f1.e9 get} mysql_update_sets {.mytpch.f1.e13 get} mysql_trickle_refresh {.mytpch.f1.e14 get} mysql_scale_fact $mysql_scale_fact  mysql_num_tpch_threads $mysql_num_tpch_threads mysql_refresh_on $mysql_refresh_on mysql_raise_query_error $mysql_raise_query_error mysql_verbose $mysql_verbose mysql_refresh_verbose $mysql_refresh_verbose mysql_cloud_query $mysql_cloud_query} ]
    #set matching fields in dialog to temporary dict
       if {![string match windows $::tcl_platform(platform)]} {
        set platform "lin"
    set mysqlconn [ dict create connection {mysql_host {.mytpch.f1.e1 get} mysql_port {.mytpch.f1.e2 get} mysql_socket {.mytpch.f1.e2a get} mysql_ssl_ca {.mytpch.f1.e2d get} mysql_ssl_cert {.mytpch.f1.e2e get} mysql_ssl_key {.mytpch.f1.e2f get} mysql_ssl_cipher {.mytpch.f1.e2g get} mysql_ssl $mysql_ssl mysql_ssl_two_way $mysql_ssl_two_way mysql_ssl_linux_capath {$mysql_ssl_linux_capath}} ]
        } else {
        set platform "win"
    set mysqlconn [ dict create connection {mysql_host {.mytpch.f1.e1 get} mysql_port {.mytpch.f1.e2 get} mysql_socket {.mytpch.f1.e2a get} mysql_ssl_ca {.mytpch.f1.e2d get} mysql_ssl_cert {.mytpch.f1.e2e get} mysql_ssl_key {.mytpch.f1.e2f get} mysql_ssl_cipher {.mytpch.f1.e2g get} mysql_ssl $mysql_ssl mysql_ssl_two_way $mysql_ssl_two_way mysql_ssl_windows_capath {$mysql_ssl_windows_capath}} ]
        }
    variable myfields
    set myfields [ dict merge $mysqlconn $tpchfields ]
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
        set mysql_socket "null"
        .mytpch.f1.e2a configure -state disabled
    }

    set Name $Parent.f1.e2b
    set Prompt $Parent.f1.p2b
    ttk::label $Prompt -text "Enable SSL :"
    ttk::checkbutton $Name -text "" -variable mysql_ssl -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 4 -sticky e
    grid $Name -column 1 -row 4 -sticky w
    
    bind .mytpch.f1.e2b <Any-ButtonRelease> {
        if { $mysql_ssl eq "true" } {
            .mytpch.f1.e2ba configure -state disabled
            .mytpch.f1.e2bb configure -state disabled
            .mytpch.f1.e2c configure -state disabled
            .mytpch.f1.e2d configure -state disabled
            .mytpch.f1.e2e configure -state disabled
            .mytpch.f1.e2f configure -state disabled
            .mytpch.f1.e2g configure -state disabled
        } else {
            .mytpch.f1.e2ba configure -state normal
            .mytpch.f1.e2bb configure -state normal
            .mytpch.f1.e2c configure -state normal
            .mytpch.f1.e2d configure -state normal
            if { $mysql_ssl_two_way eq "true" } {
                .mytpch.f1.e2e configure -state normal
                .mytpch.f1.e2f configure -state normal
            }
            .mytpch.f1.e2g configure -state normal
        }
    }
    
    set Name $Parent.f1.e2ba
    ttk::radiobutton $Name -value "false" -text "SSL One-Way" -variable mysql_ssl_two_way
    grid $Name -column 1 -row 5 -sticky w
    if { $mysql_ssl eq "false" } {
        .mytpch.f1.e2ba configure -state disabled
    }
    bind .mytpch.f1.e2ba <ButtonPress-1> {
        .mytpch.f1.e2e configure -state disabled
        .mytpch.f1.e2f configure -state disabled
    }
    
    set Name $Parent.f1.e2bb
    ttk::radiobutton $Name -value "true" -text "SSL Two-Way" -variable mysql_ssl_two_way
    grid $Name -column 1 -row 6 -sticky w
    if { $mysql_ssl eq "false" } {
        .mytpch.f1.e2bb configure -state disabled
    }
    
    bind .mytpch.f1.e2bb <ButtonPress-1> {
        .mytpch.f1.e2e configure -state normal
        .mytpch.f1.e2f configure -state normal
    }
    
    set Name $Parent.f1.e2c
    set Prompt $Parent.f1.p2c
    ttk::label $Prompt -text "SSL CApath :"
    if { $platform eq "lin" } {
        ttk::entry $Name -width 30 -textvariable mysql_ssl_linux_capath
    } else {
        ttk::entry $Name -width 30 -textvariable mysql_ssl_windows_capath
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }
    
    set Name $Parent.f1.e2d
    set Prompt $Parent.f1.p2d
    ttk::label $Prompt -text "SSL CA :"
    ttk::entry $Name  -width 30 -textvariable mysql_ssl_ca
    grid $Prompt -column 0 -row 8 -sticky e
    grid $Name -column 1 -row 8 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }
    
    set Name $Parent.f1.e2e
    set Prompt $Parent.f1.p2e
    ttk::label $Prompt -text "SSL Cert :"
    ttk::entry $Name  -width 30 -textvariable mysql_ssl_cert
    grid $Prompt -column 0 -row 9 -sticky e
    grid $Name -column 1 -row 9 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }
    
    set Name $Parent.f1.e2f
    set Prompt $Parent.f1.p2f
    ttk::label $Prompt -text "SSL Key :"
    ttk::entry $Name  -width 30 -textvariable mysql_ssl_key
    grid $Prompt -column 0 -row 10 -sticky e
    grid $Name -column 1 -row 10 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }
    
    set Name $Parent.f1.e2g
    set Prompt $Parent.f1.p2g
    ttk::label $Prompt -text "SSL Cipher :"
    ttk::entry $Name  -width 30 -textvariable mysql_ssl_cipher
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
    if { $mysql_ssl == "false" } {
        $Name configure -state disabled
    }

    set Name $Parent.f1.e3
    set Prompt $Parent.f1.p3
    ttk::label $Prompt -text "MySQL User :"
    ttk::entry $Name  -width 30 -textvariable mysql_tpch_user
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew
    set Name $Parent.f1.e4
    set Prompt $Parent.f1.p4
    ttk::label $Prompt -text "MySQL User Password :"   
    ttk::entry $Name -show * -width 30 -textvariable mysql_tpch_pass
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky ew
    set Name $Parent.f1.e5
    set Prompt $Parent.f1.p5
    ttk::label $Prompt -text "TPROC-H MySQL Database :" -image [ create_image hdbicon icons ] -compound left
    ttk::entry $Name -width 30 -textvariable mysql_tpch_dbase
    grid $Prompt -column 0 -row 14 -sticky e
    grid $Name -column 1 -row 14 -sticky ew
    if { $option eq "all" || $option eq "build" } {
        set Name $Parent.f1.e6
        set Prompt $Parent.f1.p6
        ttk::label $Prompt -text "Data Warehouse Storage Engine :"
        ttk::entry $Name -width 30 -textvariable mysql_tpch_storage_engine
        grid $Prompt -column 0 -row 15 -sticky e
        grid $Name -column 1 -row 15 -sticky ew
        set Name $Parent.f1.e7
        set Prompt $Parent.f1.p7 
        ttk::label $Prompt -text "Scale Factor :"
        grid $Prompt -column 0 -row 16 -sticky e
        set Name $Parent.f1.f2
        ttk::frame $Name -width 30
        grid $Name -column 1 -row 16 -sticky ew
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
        grid $Prompt -column 0 -row 17 -sticky e
        grid $Name -column 1 -row 17 -sticky ew
    }
    if { $option eq "all" || $option eq "drive" } {
        if { $option eq "all" } {
            set Prompt $Parent.f1.h3
            ttk::label $Prompt -image [ create_image driveroptlo icons ]
            grid $Prompt -column 0 -row 18 -sticky e
            set Prompt $Parent.f1.h4
            ttk::label $Prompt -text "Driver Options"
            grid $Prompt -column 1 -row 18 -sticky w
        }
        set Name $Parent.f1.e9
        set Prompt $Parent.f1.p9
        ttk::label $Prompt -text "Total Query Sets per User :"
        ttk::entry $Name -width 30 -textvariable mysql_total_querysets
        grid $Prompt -column 0 -row 19 -sticky e
        grid $Name -column 1 -row 19  -columnspan 4 -sticky ew
        set Prompt $Parent.f1.p10
        ttk::label $Prompt -text "Exit on MySQL Error :"
        set Name $Parent.f1.e10
        ttk::checkbutton $Name -text "" -variable mysql_raise_query_error -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 20 -sticky e
        grid $Name -column 1 -row 20 -sticky w
        set Prompt $Parent.f1.p11
        ttk::label $Prompt -text "Verbose Output :"
        set Name $Parent.f1.e11
        ttk::checkbutton $Name -text "" -variable mysql_verbose -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 21 -sticky e
        grid $Name -column 1 -row 21 -sticky w
        set Prompt $Parent.f1.p12
        ttk::label $Prompt -text "Refresh Function :"
        set Name $Parent.f1.e12
        ttk::checkbutton $Name -text "" -variable mysql_refresh_on -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 22 -sticky e
        grid $Name -column 1 -row 22 -sticky w
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
        grid $Prompt -column 0 -row 23 -sticky e
        grid $Name -column 1 -row 23  -columnspan 4 -sticky ew
        if {$mysql_refresh_on == "false" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e14
        set Prompt $Parent.f1.p14
        ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
        ttk::entry $Name -width 30 -textvariable mysql_trickle_refresh
        grid $Prompt -column 0 -row 24 -sticky e
        grid $Name -column 1 -row 24  -columnspan 4 -sticky ew
        if {$mysql_refresh_on == "false" } {
            $Name configure -state disabled
        }
        set Prompt $Parent.f1.p15
        ttk::label $Prompt -text "Refresh Verbose :"
        set Name $Parent.f1.e15
        ttk::checkbutton $Name -text "" -variable mysql_refresh_verbose -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 25 -sticky e
        grid $Name -column 1 -row 25 -sticky w
        if {$mysql_refresh_on == "false" } {
            $Name configure -state disabled
        }
        set Prompt $Parent.f1.p16
        ttk::label $Prompt -text "Cloud Analytic Queries :"
        set Name $Parent.f1.e16
        ttk::checkbutton $Name -text "" -variable mysql_cloud_query -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 26 -sticky e
        grid $Name -column 1 -row 26 -sticky w
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
                Dict2SQLite "mysql" $configmysql
                unset myfields
                check_mysql_ssl $configmysql
                destroy .mytpch
                loadtpch
            } -text {OK}
        }
        "default" {
            ttk::button $Name -command {
                set mysql_num_tpch_threads [ verify_build_threads $mysql_num_tpch_threads 512 512 ]
                copyfieldstoconfig configmysql [ subst $myfields ] tpch
                Dict2SQLite "mysql" $configmysql
                unset myfields
                check_mysql_ssl $configmysql
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
