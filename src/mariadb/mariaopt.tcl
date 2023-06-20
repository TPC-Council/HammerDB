proc check_maria_ssl { configdict } {
global maria_ssl_options
unset -nocomplain maria_ssl_options
upvar #0 configmariadb configmariadb
#set local variables to dict for checking
foreach key [ dict keys [ dict get $configdict connection ] *ssl* ] {
set $key [ dict get $configdict connection $key ]
	}
#Use correct directory
if {![string match windows $::tcl_platform(platform)]} {
set capath $maria_ssl_linux_capath
} else {
set capath $maria_ssl_windows_capath
}
#If SSL not enabled return
if { $maria_ssl != "true" } { 
#nothing to check, maria_ssl_options is not set
set maria_ssl_options " -ssl false "
return	
} else {
#SSL is enabled, check that capath is valid
if { [ file isdirectory $capath ] } {
if { $maria_ssl_ca eq "" && $maria_ssl_cert eq "" && $maria_ssl_key eq "" } {
#All of the file entries are blank, use capath only
} else {
#Two scenarios:
#-CApath is valid, file entries are not blank, so check CA
#-CApath is empty when we only want to use cert+key to authenthicate
#but we don't want to verify CA certificate (useful for self signing scenarios)
if { $maria_ssl_ca eq "" || [ file readable [ file join $capath $maria_ssl_ca ]] } {
} else {
tk_messageBox -message "[ file join $capath $maria_ssl_ca ] is not readable, disabling SSL"
dict set configmariadb connection maria_ssl "false"
return
}
#capath and ca are readable
if { $maria_ssl_two_way eq "true" } {
#Also check Cert and Key readable
foreach sslfile [ list $maria_ssl_cert $maria_ssl_key ] {
if { [ file readable [ file join $capath $sslfile ]] } {
} else {
tk_messageBox -message "[ file join $capath $sslfile ] is not readable, disabling SSL"
dict set configmariadb connection maria_ssl "false"
return
}
}
}
}
} else {
tk_messageBox -message "SSL CApath is not a valid directory, disabling SSL"
#Set SSL to false
dict set configmariadb connection maria_ssl "false"
return
}
}
#SSL is true and all files needed are readable, build options
append maria_ssl_options " -ssl true "
if { $maria_ssl_ca eq "" && $maria_ssl_cert eq "" && $maria_ssl_key eq "" } {
#No files given as an argument use -capath only
append maria_ssl_options " -sslcapath $capath "
} else {
#for one-way use -sslca only if exists
if { $maria_ssl_ca != "" } {
append maria_ssl_options " -sslca [ file join $capath $maria_ssl_ca ] "
}
if { $maria_ssl_two_way eq "true" } {
#for two-way add -sslcert & -sslkey
append maria_ssl_options " -sslcert [ file join $capath $maria_ssl_cert ] "
append maria_ssl_options " -sslkey [ file join $capath $maria_ssl_key ] "
	} 
}
#if ssl_cipher has changed add the option
if { $maria_ssl_cipher != "server" } { append maria_ssl_options " -sslcipher $maria_ssl_cipher " } 
}

proc countmariaopts { bm } {
    upvar #0 icons icons
    upvar #0 configmariadb configmariadb
    upvar #0 genericdict genericdict
    global afval interval tclog uniquelog tcstamp
    dict with genericdict { dict with transaction_counter {
            #variables for button options need to be global
            set interval $tc_refresh_rate
            set tclog $tc_log_to_temp
            set uniquelog $tc_unique_log_name
            set tcstamp $tc_log_timestamps
    }}
    setlocaltcountvars $configmariadb 1 
    variable mariaoptsfields 
    if { $bm eq "TPC-C" } {
   if {![string match windows $::tcl_platform(platform)]} {
        set platform "lin"
        set mariaoptsfields [ dict create connection {maria_host {.countopt.f1.e1 get} maria_port {.countopt.f1.e2 get} maria_socket {.countopt.f1.e2a get} maria_ssl_ca {.countopt.f1.e2d get} maria_ssl_cert {.countopt.f1.e2e get} maria_ssl_key {.countopt.f1.e2f get} maria_ssl_cipher {.countopt.f1.e2g get} maria_ssl $maria_ssl maria_ssl_two_way $maria_ssl_two_way maria_ssl_linux_capath $maria_ssl_linux_capath} tpcc {maria_user {.countopt.f1.e3 get} maria_pass {.countopt.f1.e4 get}} ]
        } else {
        set platform "win"
        set mariaoptsfields [ dict create connection {maria_host {.countopt.f1.e1 get} maria_port {.countopt.f1.e2 get} maria_socket {.countopt.f1.e2a get} maria_ssl_ca {.countopt.f1.e2d get} maria_ssl_cert {.countopt.f1.e2e get} maria_ssl_key {.countopt.f1.e2f get} maria_ssl_cipher {.countopt.f1.e2g get} maria_ssl $maria_ssl maria_ssl_two_way $maria_ssl_two_way maria_ssl_windows_capath {$maria_ssl_windows_capath}} tpcc {maria_user {.countopt.f1.e3 get} maria_pass {.countopt.f1.e4 get}} ]
        }
    } else {
   if {![string match windows $::tcl_platform(platform)]} {
        set platform "lin"
        set mariaoptsfields [ dict create connection {maria_host {.countopt.f1.e1 get} maria_port {.countopt.f1.e2 get} maria_socket {.countopt.f1.e2a get} maria_ssl_ca {.countopt.f1.e2d get} maria_ssl_cert {.countopt.f1.e2e get} maria_ssl_key {.countopt.f1.e2f get} maria_ssl_cipher {.countopt.f1.e2g get} maria_ssl $maria_ssl maria_ssl_two_way $maria_ssl_two_way maria_ssl_linux_capath $maria_ssl_linux_capath} tpch {maria_tpch_user {.countopt.f1.e3 get} maria_tpch_pass {.countopt.f1.e4 get}} ]
        } else {
        set platform "win"
        set mariaoptsfields [ dict create connection {maria_host {.countopt.f1.e1 get} maria_port {.countopt.f1.e2 get} maria_socket {.countopt.f1.e2a get} maria_ssl_ca {.countopt.f1.e2d get} maria_ssl_cert {.countopt.f1.e2e get} maria_ssl_key {.countopt.f1.e2f get} maria_ssl_cipher {.countopt.f1.e2g get} maria_ssl $maria_ssl maria_ssl_two_way $maria_ssl_two_way maria_ssl_windows_capath {$maria_ssl_windows_capath}} tpch {maria_tpch_user {.countopt.f1.e3 get} maria_tpch_pass {.countopt.f1.e4 get}} ]
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
    wm title .countopt {MariaDB TX Counter Options}
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
    ttk::label $Prompt -text "MariaDB Host :"
    ttk::entry $Name -width 30 -textvariable maria_host
    grid $Prompt -column 0 -row 1 -sticky e
    grid $Name -column 1 -row 1 -sticky ew
    set Name $Parent.f1.e2
    set Prompt $Parent.f1.p2
    ttk::label $Prompt -text "MariaDB Port :"   
    ttk::entry $Name  -width 30 -textvariable maria_port
    grid $Prompt -column 0 -row 2 -sticky e
    grid $Name -column 1 -row 2 -sticky ew
    set Name $Parent.f1.e2a
    set Prompt $Parent.f1.p2a
    ttk::label $Prompt -text "MariaDB Socket :"   
    ttk::entry $Name  -width 30 -textvariable maria_socket
    grid $Prompt -column 0 -row 3 -sticky e
    grid $Name -column 1 -row 3 -sticky ew

    if {[string match windows $::tcl_platform(platform)]} {
        set maria_socket "null"
        .countopt.f1.e2a configure -state disabled
    }

    set Name $Parent.f1.e2b
        set Prompt $Parent.f1.p2b
        ttk::label $Prompt -text "Enable SSL :"
        ttk::checkbutton $Name -text "" -variable maria_ssl -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 4 -sticky e
        grid $Name -column 1 -row 4 -sticky w

         bind .countopt.f1.e2b <Any-ButtonRelease> {
            if { $maria_ssl eq "true" } {
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
                if { $maria_ssl_two_way eq "true" } {
                .countopt.f1.e2e configure -state normal
                .countopt.f1.e2f configure -state normal
                        }
                .countopt.f1.e2g configure -state normal
                }
            }

	    set Name $Parent.f1.e2ba
        ttk::radiobutton $Name -value "false" -text "SSL One-Way" -variable maria_ssl_two_way
        grid $Name -column 1 -row 5 -sticky w
        if { $maria_ssl eq "false" } {
                .countopt.f1.e2ba configure -state disabled
        }
        bind .countopt.f1.e2ba <ButtonPress-1> {
                .countopt.f1.e2e configure -state disabled
                .countopt.f1.e2f configure -state disabled
        }

        set Name $Parent.f1.e2bb
        ttk::radiobutton $Name -value "true" -text "SSL Two-Way" -variable maria_ssl_two_way
        grid $Name -column 1 -row 6 -sticky w
        if { $maria_ssl eq "false" } {
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
        ttk::entry $Name -width 30 -textvariable maria_ssl_linux_capath
    } else {
        ttk::entry $Name -width 30 -textvariable maria_ssl_windows_capath
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e2d
    set Prompt $Parent.f1.p2d
    ttk::label $Prompt -text "SSL CA :"
    ttk::entry $Name  -width 30 -textvariable maria_ssl_ca
    grid $Prompt -column 0 -row 8 -sticky e
    grid $Name -column 1 -row 8 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e2e
    set Prompt $Parent.f1.p2e
    ttk::label $Prompt -text "SSL Cert :"
    ttk::entry $Name  -width 30 -textvariable maria_ssl_cert
    grid $Prompt -column 0 -row 9 -sticky e
    grid $Name -column 1 -row 9 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

	  set Name $Parent.f1.e2f
    set Prompt $Parent.f1.p2f
    ttk::label $Prompt -text "SSL Key :"
    ttk::entry $Name  -width 30 -textvariable maria_ssl_key
    grid $Prompt -column 0 -row 10 -sticky e
    grid $Name -column 1 -row 10 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e2g
    set Prompt $Parent.f1.p2g
    ttk::label $Prompt -text "SSL Cipher :"
    ttk::entry $Name  -width 30 -textvariable maria_ssl_cipher
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e3
    set Prompt $Parent.f1.p3
    ttk::label $Prompt -text "MariaDB User :"

    if { $bm eq "TPC-C" } {
        ttk::entry $Name  -width 30 -textvariable maria_user
    } else {
        ttk::entry $Name  -width 30 -textvariable maria_tpch_user
    }

    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew
    set Name $Parent.f1.e4
    set Prompt $Parent.f1.p4
    ttk::label $Prompt -text "MariaDB User Password :"   

    if { $bm eq "TPC-C" } {
        ttk::entry $Name -show * -width 30 -textvariable maria_pass
    } else {
        ttk::entry $Name -show * -width 30 -textvariable maria_tpch_pass
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
        unset mariaoptsfields
        destroy .countopt
    } -text Cancel

    pack $Name -anchor nw -side right -padx 3 -pady 3

    set Name $Parent.b1
    if { $bm eq "TPC-C" } {
        ttk::button $Name -command {
            copyfieldstoconfig configmariadb [ subst $mariaoptsfields ] tpcc
            Dict2SQLite "mariadb" $configmariadb
            unset mariaoptsfields
	    check_maria_ssl $configmariadb
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
            copyfieldstoconfig configmariadb [ subst $mariaoptsfields ] tpch
            Dict2SQLite "mariadb" $configmariadb
            unset mariaoptsfields
	    check_maria_ssl $configmariadb
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

proc configmariatpcc {option} {
    upvar #0 icons icons
    upvar #0 configmariadb configmariadb

    #set variables to values in dict
    setlocaltpccvars $configmariadb
    set tpccfields [ dict create tpcc {maria_user {.tpc.f1.e3 get} maria_pass {.tpc.f1.e4 get} maria_dbase {.tpc.f1.e5 get} maria_storage_engine {.tpc.f1.e6 get} maria_total_iterations {.tpc.f1.e14 get} maria_rampup {.tpc.f1.e17 get} maria_duration {.tpc.f1.e18 get} maria_async_client {.tpc.f1.e22 get} maria_async_delay {.tpc.f1.e23 get} maria_count_ware $maria_count_ware maria_num_vu $maria_num_vu maria_partition $maria_partition maria_driver $maria_driver maria_raiseerror $maria_raiseerror maria_keyandthink $maria_keyandthink maria_allwarehouse $maria_allwarehouse maria_timeprofile $maria_timeprofile maria_async_scale $maria_async_scale maria_async_verbose $maria_async_verbose maria_prepared $maria_prepared maria_connect_pool $maria_connect_pool} ]
    if {![string match windows $::tcl_platform(platform)]} {
        set platform "lin"
    set mariaconn [ dict create connection {maria_host {.tpc.f1.e1 get} maria_port {.tpc.f1.e2 get} maria_socket {.tpc.f1.e2a get} maria_ssl_ca {.tpc.f1.e2d get} maria_ssl_cert {.tpc.f1.e2e get} maria_ssl_key {.tpc.f1.e2f get} maria_ssl_cipher {.tpc.f1.e2g get} maria_ssl $maria_ssl maria_ssl_two_way $maria_ssl_two_way maria_ssl_linux_capath $maria_ssl_linux_capath} ]
        } else {
        set platform "win"
    set mariaconn [ dict create connection {maria_host {.tpc.f1.e1 get} maria_port {.tpc.f1.e2 get} maria_socket {.tpc.f1.e2a get} maria_ssl_ca {.tpc.f1.e2d get} maria_ssl_cert {.tpc.f1.e2e get} maria_ssl_key {.tpc.f1.e2f get} maria_ssl_cipher {.tpc.f1.e2g get} maria_ssl $maria_ssl maria_ssl_two_way $maria_ssl_two_way maria_ssl_windows_capath {$maria_ssl_windows_capath}} ]
        }
    variable mariafields
    set mariafields [ dict merge $mariaconn $tpccfields ]
    set whlist [ get_warehouse_list_for_spinbox ]

    catch "destroy .tpc"
    ttk::toplevel .tpc
    wm transient .tpc .ed_mainFrame
    wm withdraw .tpc

    switch $option {
        "all" { wm title .tpc {MariaDB TPROC-C Schema Options} }
        "build" { wm title .tpc {MariaDB TPROC-C Build Options} }
        "drive" {  wm title .tpc {MariaDB TPROC-C Driver Options} }
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
    ttk::label $Prompt -text "MariaDB Host :"
    ttk::entry $Name -width 30 -textvariable maria_host
    grid $Prompt -column 0 -row 1 -sticky e
    grid $Name -column 1 -row 1 -sticky ew
    set Name $Parent.f1.e2
    set Prompt $Parent.f1.p2
    ttk::label $Prompt -text "MariaDB Port :"   
    ttk::entry $Name  -width 30 -textvariable maria_port
    grid $Prompt -column 0 -row 2 -sticky e
    grid $Name -column 1 -row 2 -sticky ew
    set Name $Parent.f1.e2a
    set Prompt $Parent.f1.p2a
    ttk::label $Prompt -text "MariaDB Socket :"
    ttk::entry $Name  -width 30 -textvariable maria_socket
    grid $Prompt -column 0 -row 3 -sticky e
    grid $Name -column 1 -row 3 -sticky ew

    if {[string match windows $::tcl_platform(platform)]} {
	set maria_socket "null"
        .tpc.f1.e2a configure -state disabled
    }

 	set Name $Parent.f1.e2b
        set Prompt $Parent.f1.p2b
        ttk::label $Prompt -text "Enable SSL :"
        ttk::checkbutton $Name -text "" -variable maria_ssl -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 4 -sticky e
        grid $Name -column 1 -row 4 -sticky w

	 bind .tpc.f1.e2b <Any-ButtonRelease> {
            if { $maria_ssl eq "true" } {
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
		if { $maria_ssl_two_way eq "true" } {
                .tpc.f1.e2e configure -state normal
                .tpc.f1.e2f configure -state normal
			}
                .tpc.f1.e2g configure -state normal
                }
            }

	set Name $Parent.f1.e2ba
        ttk::radiobutton $Name -value "false" -text "SSL One-Way" -variable maria_ssl_two_way
        grid $Name -column 1 -row 5 -sticky w
	if { $maria_ssl eq "false" } {
                .tpc.f1.e2ba configure -state disabled
	}
        bind .tpc.f1.e2ba <ButtonPress-1> {
                .tpc.f1.e2e configure -state disabled
                .tpc.f1.e2f configure -state disabled
        }

        set Name $Parent.f1.e2bb
        ttk::radiobutton $Name -value "true" -text "SSL Two-Way" -variable maria_ssl_two_way
        grid $Name -column 1 -row 6 -sticky w
	if { $maria_ssl eq "false" } {
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
        ttk::entry $Name -width 30 -textvariable maria_ssl_linux_capath
    } else {
        ttk::entry $Name -width 30 -textvariable maria_ssl_windows_capath
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e2d
    set Prompt $Parent.f1.p2d
    ttk::label $Prompt -text "SSL CA :"
    ttk::entry $Name  -width 30 -textvariable maria_ssl_ca
    grid $Prompt -column 0 -row 8 -sticky e
    grid $Name -column 1 -row 8 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e2e
    set Prompt $Parent.f1.p2e
    ttk::label $Prompt -text "SSL Cert :"
    ttk::entry $Name  -width 30 -textvariable maria_ssl_cert
    grid $Prompt -column 0 -row 9 -sticky e
    grid $Name -column 1 -row 9 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e2f
    set Prompt $Parent.f1.p2f
    ttk::label $Prompt -text "SSL Key :"
    ttk::entry $Name  -width 30 -textvariable maria_ssl_key
    grid $Prompt -column 0 -row 10 -sticky e
    grid $Name -column 1 -row 10 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e2g
    set Prompt $Parent.f1.p2g
    ttk::label $Prompt -text "SSL Cipher :"
    ttk::entry $Name  -width 30 -textvariable maria_ssl_cipher
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e3
    set Prompt $Parent.f1.p3
    ttk::label $Prompt -text "MariaDB User :"
    ttk::entry $Name  -width 30 -textvariable maria_user
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew
    set Name $Parent.f1.e4
    set Prompt $Parent.f1.p4
    ttk::label $Prompt -text "MariaDB User Password :"   
    ttk::entry $Name -show * -width 30 -textvariable maria_pass
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky ew
    set Name $Parent.f1.e5
    set Prompt $Parent.f1.p5
    ttk::label $Prompt -text "TPROC-C MariaDB Database :" -image [ create_image hdbicon icons ] -compound left
    ttk::entry $Name -width 30 -textvariable maria_dbase
    grid $Prompt -column 0 -row 14 -sticky e
    grid $Name -column 1 -row 14 -sticky ew

    if { $option eq "all" || $option eq "build" } {
        set Name $Parent.f1.e6
        set Prompt $Parent.f1.p6
        ttk::label $Prompt -text "Transactional Storage Engine :"
        ttk::entry $Name -width 30 -textvariable maria_storage_engine
        grid $Prompt -column 0 -row 15 -sticky e
        grid $Name -column 1 -row 15 -sticky ew
        set Prompt $Parent.f1.p8
        ttk::label $Prompt -text "Number of Warehouses :"
        set Name $Parent.f1.e8
        ttk::spinbox $Name -value $whlist -textvariable maria_count_ware

        bind .tpc.f1.e8 <<Any-Button-Any-Key>> {
            if {$maria_num_vu > $maria_count_ware} {
                set maria_num_vu $maria_count_ware
            }
            if {$maria_count_ware < 200} {
                .tpc.f1.e10 configure -state disabled
                set maria_partition "false"
            } else {
                .tpc.f1.e10 configure -state enabled
            }
        }

        grid $Prompt -column 0 -row 16 -sticky e
        grid $Name -column 1 -row 16 -sticky ew
        set Prompt $Parent.f1.p9
        ttk::label $Prompt -text "Virtual Users to Build Schema :"
        set Name $Parent.f1.e9
        ttk::spinbox $Name -from 1 -to 512 -textvariable maria_num_vu

        bind .tpc.f1.e9 <<Any-Button-Any-Key>> {
            if {$maria_num_vu > $maria_count_ware} {
                set maria_num_vu $maria_count_ware
            }
        }

        event add <<Any-Button-Any-Key>> <Any-ButtonRelease>
        event add <<Any-Button-Any-Key>> <KeyRelease>
        grid $Prompt -column 0 -row 17 -sticky e
        grid $Name -column 1 -row 17 -sticky ew
        set Prompt $Parent.f1.p10
        ttk::label $Prompt -text "Partition Order Line Table :"
        set Name $Parent.f1.e10
        ttk::checkbutton $Name -text "" -variable maria_partition -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 18 -sticky e
        grid $Name -column 1 -row 18 -sticky w

        if {$maria_count_ware <= 200 } {
            $Name configure -state disabled
        }
    }

    if { $option eq "all" || $option eq "drive" } {
        if { $option eq "all" } {
            set Prompt $Parent.f1.h3
            ttk::label $Prompt -image [ create_image driveroptlo icons ]
            grid $Prompt -column 0 -row 19 -sticky e
            set Prompt $Parent.f1.h4
            ttk::label $Prompt -text "Driver Options"
            grid $Prompt -column 1 -row 19 -sticky w
        }

        set Prompt $Parent.f1.p12
        ttk::label $Prompt -text "TPROC-C Driver Script :" -image [ create_image hdbicon icons ] -compound left
        grid $Prompt -column 0 -row 20 -sticky e
        set Name $Parent.f1.r1
        ttk::radiobutton $Name -value "test" -text "Test Driver Script" -variable maria_driver
        grid $Name -column 1 -row 20 -sticky w

        bind .tpc.f1.r1 <ButtonPress-1> {
            set maria_allwarehouse "false"
            set maria_timeprofile "false"
            set maria_async_scale "false"
            set maria_async_verbose "false"
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
        ttk::radiobutton $Name -value "timed" -text "Timed Driver Script" -variable maria_driver
        grid $Name -column 1 -row 21 -sticky w

        bind .tpc.f1.r2 <ButtonPress-1> {
            .tpc.f1.e17 configure -state normal
            .tpc.f1.e18 configure -state normal
            .tpc.f1.e19 configure -state normal
            .tpc.f1.e20 configure -state normal
            .tpc.f1.e21 configure -state normal
            if { $maria_async_scale eq "true" } {
                .tpc.f1.e22 configure -state normal
                .tpc.f1.e23 configure -state normal
                .tpc.f1.e24 configure -state normal
            }
        }

        set Name $Parent.f1.e14
        set Prompt $Parent.f1.p14
        ttk::label $Prompt -text "Total Transactions per User :"
        ttk::entry $Name -width 30 -textvariable maria_total_iterations
        grid $Prompt -column 0 -row 22 -sticky e
        grid $Name -column 1 -row 22 -sticky ew
        set Prompt $Parent.f1.p15
        ttk::label $Prompt -text "Exit on MariaDB Error :"
        set Name $Parent.f1.e15
        ttk::checkbutton $Name -text "" -variable maria_raiseerror -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 23 -sticky e
        grid $Name -column 1 -row 23 -sticky w
        set Prompt $Parent.f1.p16
        ttk::label $Prompt -text "Keying and Thinking Time :"
        set Name $Parent.f1.e16
        ttk::checkbutton $Name -text "" -variable maria_keyandthink -onvalue "true" -offvalue "false"
        bind .tpc.f1.e16 <Any-ButtonRelease> {
            if { $maria_driver eq "timed" } {
                if { $maria_keyandthink eq "true" } {
                    set maria_async_scale "false"
                    set maria_async_verbose "false"
                    .tpc.f1.e22 configure -state disabled
                    .tpc.f1.e23 configure -state disabled
                    .tpc.f1.e24 configure -state disabled
                }
            }
        }

        grid $Prompt -column 0 -row 24 -sticky e
        grid $Name -column 1 -row 24 -sticky w
        set Prompt $Parent.f1.p16a
        ttk::label $Prompt -text "Prepare Statements :"
        set Name $Parent.f1.e16a
        ttk::checkbutton $Name -text "" -variable maria_prepared -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 25 -sticky e
        grid $Name -column 1 -row 25 -sticky w
        set Name $Parent.f1.e17
        set Prompt $Parent.f1.p17
        ttk::label $Prompt -text "Minutes of Rampup Time :"
        ttk::entry $Name -width 30 -textvariable maria_rampup
        grid $Prompt -column 0 -row 26 -sticky e
        grid $Name -column 1 -row 26 -sticky ew

        if {$maria_driver == "test" } {
            $Name configure -state disabled
        }

        set Name $Parent.f1.e18
        set Prompt $Parent.f1.p18
        ttk::label $Prompt -text "Minutes for Test Duration :"
        ttk::entry $Name -width 30 -textvariable maria_duration
        grid $Prompt -column 0 -row 27 -sticky e
        grid $Name -column 1 -row 27 -sticky ew

        if {$maria_driver == "test" } {
            $Name configure -state disabled
        }

        set Name $Parent.f1.e19
        set Prompt $Parent.f1.p19
        ttk::label $Prompt -text "Use All Warehouses :"
        ttk::checkbutton $Name -text "" -variable maria_allwarehouse -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 28 -sticky e
        grid $Name -column 1 -row 28 -sticky ew

        if {$maria_driver == "test" } {
            $Name configure -state disabled
        }

        set Name $Parent.f1.e20
        set Prompt $Parent.f1.p20
        ttk::label $Prompt -text "Time Profile :"
        ttk::checkbutton $Name -text "" -variable maria_timeprofile -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 29 -sticky e
        grid $Name -column 1 -row 29 -sticky ew

        if {$maria_driver == "test" } {
            $Name configure -state disabled
        }

        set Name $Parent.f1.e21
        set Prompt $Parent.f1.p21
        ttk::label $Prompt -text "Asynchronous Scaling :"
        ttk::checkbutton $Name -text "" -variable maria_async_scale -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 30 -sticky e
        grid $Name -column 1 -row 30 -sticky ew

        if {$maria_driver == "test" } {
            set maria_async_scale "false"
            $Name configure -state disabled
        }

        bind .tpc.f1.e21 <Any-ButtonRelease> {
            if { $maria_async_scale eq "true" } {
                set maria_async_verbose "false"
                .tpc.f1.e22 configure -state disabled
                .tpc.f1.e23 configure -state disabled
                .tpc.f1.e24 configure -state disabled
            } else {
                if { $maria_driver eq "timed" } {
                    set maria_keyandthink "true"
                    .tpc.f1.e22 configure -state normal
                    .tpc.f1.e23 configure -state normal
                    .tpc.f1.e24 configure -state normal
                }
            }
        }

        set Name $Parent.f1.e22
        set Prompt $Parent.f1.p22
        ttk::label $Prompt -text "Asynch Clients per Virtual User :"
        ttk::entry $Name -width 30 -textvariable maria_async_client
        grid $Prompt -column 0 -row 31 -sticky e
        grid $Name -column 1 -row 31 -sticky ew

        if {$maria_driver == "test" || $maria_async_scale == "false" } {
            $Name configure -state disabled
        }

        set Name $Parent.f1.e23
        set Prompt $Parent.f1.p23
        ttk::label $Prompt -text "Asynch Client Login Delay :"
        ttk::entry $Name -width 30 -textvariable maria_async_delay
        grid $Prompt -column 0 -row 32 -sticky e
        grid $Name -column 1 -row 32 -sticky ew

        if {$maria_driver == "test" || $maria_async_scale == "false" } {
            $Name configure -state disabled
        }

        set Name $Parent.f1.e24
        set Prompt $Parent.f1.p24
        ttk::label $Prompt -text "Asynchronous Verbose :"
        ttk::checkbutton $Name -text "" -variable maria_async_verbose -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 33 -sticky e
        grid $Name -column 1 -row 33 -sticky ew

        if {$maria_driver == "test" || $maria_async_scale == "false" } {
            set maria_async_verbose "false"
            $Name configure -state disabled
        }

        set Name $Parent.f1.e25
        set Prompt $Parent.f1.p25
        ttk::label $Prompt -text "XML Connect Pool :"
        ttk::checkbutton $Name -text "" -variable maria_connect_pool -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 34 -sticky e
        grid $Name -column 1 -row 34 -sticky ew
    }

    #This is the Cancel button variables stay as before
    set Name $Parent.b2
    ttk::button $Name -command {
        unset mariafields
        destroy .tpc
    } -text Cancel

    pack $Name -anchor nw -side right -padx 3 -pady 3

    #This is the OK button all variables loaded back into config dict
    set Name $Parent.b1
    switch $option {
        "drive" {
            ttk::button $Name -command {
                copyfieldstoconfig configmariadb [ subst $mariafields ] tpcc
                Dict2SQLite "mariadb" $configmariadb
                unset mariafields
	        check_maria_ssl $configmariadb
                destroy .tpc
                loadtpcc
            } -text {OK}
        }
        "default" {
            ttk::button $Name -command {
                set maria_count_ware [ verify_warehouse $maria_count_ware 100000 ]
                set maria_num_vu [ verify_build_threads $maria_num_vu $maria_count_ware 1024 ]
                copyfieldstoconfig configmariadb [ subst $mariafields ] tpcc
                Dict2SQLite "mariadb" $configmariadb
                unset mariafields
	        check_maria_ssl $configmariadb
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

proc configmariatpch {option} {
    upvar #0 icons icons
    upvar #0 configmariadb configmariadb

    #set variables to values in dict
    setlocaltpchvars $configmariadb
    set tpchfields [ dict create tpch {maria_tpch_user {.mytpch.f1.e3 get} maria_tpch_pass {.mytpch.f1.e4 get} maria_tpch_dbase {.mytpch.f1.e5 get} maria_tpch_storage_engine {.mytpch.f1.e6 get} maria_total_querysets {.mytpch.f1.e9 get} maria_update_sets {.mytpch.f1.e13 get} maria_trickle_refresh {.mytpch.f1.e14 get} maria_scale_fact $maria_scale_fact  maria_num_tpch_threads $maria_num_tpch_threads maria_refresh_on $maria_refresh_on maria_raise_query_error $maria_raise_query_error maria_verbose $maria_verbose maria_refresh_verbose $maria_refresh_verbose maria_cloud_query $maria_cloud_query} ]
    #set matching fields in dialog to temporary dict
       if {![string match windows $::tcl_platform(platform)]} {
        set platform "lin"
    set mariaconn [ dict create connection {maria_host {.mytpch.f1.e1 get} maria_port {.mytpch.f1.e2 get} maria_socket {.mytpch.f1.e2a get} maria_ssl_ca {.mytpch.f1.e2d get} maria_ssl_cert {.mytpch.f1.e2e get} maria_ssl_key {.mytpch.f1.e2f get} maria_ssl_cipher {.mytpch.f1.e2g get} maria_ssl $maria_ssl maria_ssl_two_way $maria_ssl_two_way maria_ssl_linux_capath {$maria_ssl_linux_capath}} ]
        } else {
        set platform "win"
    set mariaconn [ dict create connection {maria_host {.mytpch.f1.e1 get} maria_port {.mytpch.f1.e2 get} maria_socket {.mytpch.f1.e2a get} maria_ssl_ca {.mytpch.f1.e2d get} maria_ssl_cert {.mytpch.f1.e2e get} maria_ssl_key {.mytpch.f1.e2f get} maria_ssl_cipher {.mytpch.f1.e2g get} maria_ssl $maria_ssl maria_ssl_two_way $maria_ssl_two_way maria_ssl_windows_capath {$maria_ssl_windows_capath}} ]
        }
    variable mariafields
    set mariafields [ dict merge $mariaconn $tpchfields ]
    catch "destroy .mytpch"
    ttk::toplevel .mytpch
    wm transient .mytpch .ed_mainFrame
    wm withdraw .mytpch

    switch $option {
        "all" { wm title .mytpch {MariaDB TPROC-H Schema Options} }
        "build" { wm title .mytpch {MariaDB TPROC-H Build Options} }
        "drive" { wm title .mytpch {MariaDB TPROC-H Driver Options} }
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
    ttk::label $Prompt -text "MariaDB Host :"
    ttk::entry $Name -width 30 -textvariable maria_host
    grid $Prompt -column 0 -row 1 -sticky e
    grid $Name -column 1 -row 1 -sticky ew
    set Name $Parent.f1.e2
    set Prompt $Parent.f1.p2
    ttk::label $Prompt -text "MariaDB Port :"   
    ttk::entry $Name  -width 30 -textvariable maria_port
    grid $Prompt -column 0 -row 2 -sticky e
    grid $Name -column 1 -row 2 -sticky ew
    set Name $Parent.f1.e2a
    set Prompt $Parent.f1.p2a
    ttk::label $Prompt -text "MariaDB Socket :"
    ttk::entry $Name  -width 30 -textvariable maria_socket
    grid $Prompt -column 0 -row 3 -sticky e
    grid $Name -column 1 -row 3 -sticky ew

    if {[string match windows $::tcl_platform(platform)]} {
        set maria_socket "null"
        .mytpch.f1.e2a configure -state disabled
    }

     set Name $Parent.f1.e2b
        set Prompt $Parent.f1.p2b
        ttk::label $Prompt -text "Enable SSL :"
        ttk::checkbutton $Name -text "" -variable maria_ssl -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 4 -sticky e
        grid $Name -column 1 -row 4 -sticky w

         bind .mytpch.f1.e2b <Any-ButtonRelease> {
            if { $maria_ssl eq "true" } {
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
                if { $maria_ssl_two_way eq "true" } {
                .mytpch.f1.e2e configure -state normal
                .mytpch.f1.e2f configure -state normal
                        }
                .mytpch.f1.e2g configure -state normal
                }
            }

  set Name $Parent.f1.e2ba
        ttk::radiobutton $Name -value "false" -text "SSL One-Way" -variable maria_ssl_two_way
        grid $Name -column 1 -row 5 -sticky w
        if { $maria_ssl eq "false" } {
                .mytpch.f1.e2ba configure -state disabled
        }
        bind .mytpch.f1.e2ba <ButtonPress-1> {
                .mytpch.f1.e2e configure -state disabled
                .mytpch.f1.e2f configure -state disabled
        }

        set Name $Parent.f1.e2bb
        ttk::radiobutton $Name -value "true" -text "SSL Two-Way" -variable maria_ssl_two_way
        grid $Name -column 1 -row 6 -sticky w
        if { $maria_ssl eq "false" } {
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
        ttk::entry $Name -width 30 -textvariable maria_ssl_linux_capath
    } else {
        ttk::entry $Name -width 30 -textvariable maria_ssl_windows_capath
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e2d
    set Prompt $Parent.f1.p2d
    ttk::label $Prompt -text "SSL CA :"
    ttk::entry $Name  -width 30 -textvariable maria_ssl_ca
    grid $Prompt -column 0 -row 8 -sticky e
    grid $Name -column 1 -row 8 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

 set Name $Parent.f1.e2e
    set Prompt $Parent.f1.p2e
    ttk::label $Prompt -text "SSL Cert :"
    ttk::entry $Name  -width 30 -textvariable maria_ssl_cert
    grid $Prompt -column 0 -row 9 -sticky e
    grid $Name -column 1 -row 9 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e2f
    set Prompt $Parent.f1.p2f
    ttk::label $Prompt -text "SSL Key :"
    ttk::entry $Name  -width 30 -textvariable maria_ssl_key
    grid $Prompt -column 0 -row 10 -sticky e
    grid $Name -column 1 -row 10 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e2g
    set Prompt $Parent.f1.p2g
    ttk::label $Prompt -text "SSL Cipher :"
    ttk::entry $Name  -width 30 -textvariable maria_ssl_cipher
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
      if { $maria_ssl == "false" } {
            $Name configure -state disabled
        }

    set Name $Parent.f1.e3
    set Prompt $Parent.f1.p3
    ttk::label $Prompt -text "MariaDB User :"
    ttk::entry $Name  -width 30 -textvariable maria_tpch_user
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew
    set Name $Parent.f1.e4
    set Prompt $Parent.f1.p4
    ttk::label $Prompt -text "MariaDB User Password :"   
    ttk::entry $Name -show * -width 30 -textvariable maria_tpch_pass
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky ew
    set Name $Parent.f1.e5
    set Prompt $Parent.f1.p5
    ttk::label $Prompt -text "TPROC-H MariaDB Database :" -image [ create_image hdbicon icons ] -compound left
    ttk::entry $Name -width 30 -textvariable maria_tpch_dbase
    grid $Prompt -column 0 -row 14 -sticky e
    grid $Name -column 1 -row 14 -sticky ew

    if { $option eq "all" || $option eq "build" } {
        set Name $Parent.f1.e6
        set Prompt $Parent.f1.p6
        ttk::label $Prompt -text "Data Warehouse Storage Engine :"
        ttk::entry $Name -width 30 -textvariable maria_tpch_storage_engine
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
            ttk::radiobutton $Name -variable maria_scale_fact -text $item -value $item -width 1
            grid $Name -column $rcnt -row 0 
            incr rcnt
        }

        set rcnt 2
        foreach item {10 30} {
            set Name $Parent.f1.f2.r$rcnt
            ttk::radiobutton $Name -variable maria_scale_fact -text $item -value $item -width 2
            grid $Name -column $rcnt -row 0 
            incr rcnt
        }

        set rcnt 4
        foreach item {100 300} {
            set Name $Parent.f1.f2.r$rcnt
            ttk::radiobutton $Name -variable maria_scale_fact -text $item -value $item -width 3
            grid $Name -column $rcnt -row 0 
            incr rcnt
        }

        set rcnt 6
        foreach item {1000} {
            set Name $Parent.f1.f2.r$rcnt
            ttk::radiobutton $Name -variable maria_scale_fact -text $item -value $item -width 4
            grid $Name -column $rcnt -row 0 
            incr rcnt
        }

        set Prompt $Parent.f1.p8
        ttk::label $Prompt -text "Virtual Users to Build Schema :"
        set Name $Parent.f1.e8
        ttk::spinbox $Name -from 1 -to 512 -textvariable maria_num_tpch_threads
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
        ttk::entry $Name -width 30 -textvariable maria_total_querysets
        grid $Prompt -column 0 -row 19 -sticky e
        grid $Name -column 1 -row 19  -columnspan 4 -sticky ew
        set Prompt $Parent.f1.p10
        ttk::label $Prompt -text "Exit on MariaDB Error :"
        set Name $Parent.f1.e10
        ttk::checkbutton $Name -text "" -variable maria_raise_query_error -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 20 -sticky e
        grid $Name -column 1 -row 20 -sticky w
        set Prompt $Parent.f1.p11
        ttk::label $Prompt -text "Verbose Output :"
        set Name $Parent.f1.e11
        ttk::checkbutton $Name -text "" -variable maria_verbose -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 21 -sticky e
        grid $Name -column 1 -row 21 -sticky w
        set Prompt $Parent.f1.p12
        ttk::label $Prompt -text "Refresh Function :"
        set Name $Parent.f1.e12
        ttk::checkbutton $Name -text "" -variable maria_refresh_on -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 22 -sticky e
        grid $Name -column 1 -row 22 -sticky w

        bind $Parent.f1.e12 <Button> {
            if {$maria_refresh_on eq "true"} { 
                set maria_refresh_verbose "false"
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
        ttk::entry $Name -width 30 -textvariable maria_update_sets
        grid $Prompt -column 0 -row 23 -sticky e
        grid $Name -column 1 -row 23  -columnspan 4 -sticky ew

        if {$maria_refresh_on == "false" } {
            $Name configure -state disabled
        }

        set Name $Parent.f1.e14
        set Prompt $Parent.f1.p14
        ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
        ttk::entry $Name -width 30 -textvariable maria_trickle_refresh
        grid $Prompt -column 0 -row 24 -sticky e
        grid $Name -column 1 -row 24  -columnspan 4 -sticky ew

        if {$maria_refresh_on == "false" } {
            $Name configure -state disabled
        }

        set Prompt $Parent.f1.p15
        ttk::label $Prompt -text "Refresh Verbose :"
        set Name $Parent.f1.e15
        ttk::checkbutton $Name -text "" -variable maria_refresh_verbose -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 25 -sticky e
        grid $Name -column 1 -row 25 -sticky w

        if {$maria_refresh_on == "false" } {
            $Name configure -state disabled
        }

        set Prompt $Parent.f1.p16
        ttk::label $Prompt -text "Cloud Analytic Queries :"
        set Name $Parent.f1.e16
        ttk::checkbutton $Name -text "" -variable maria_cloud_query -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 26 -sticky e
        grid $Name -column 1 -row 26 -sticky w
    }

    #This is the Cancel button variables stay as before
    set Name $Parent.b2
    ttk::button $Name -command {
        unset mariafields
        destroy .mytpch
    } -text Cancel
    pack $Name -anchor nw -side right -padx 3 -pady 3

    #This is the OK button all variables loaded back into config dict
    set Name $Parent.b1
    switch $option {
        "drive" {
            ttk::button $Name -command {
                copyfieldstoconfig configmariadb [ subst $mariafields ] tpch
                Dict2SQLite "mariadb" $configmariadb
                unset mariafields
	        check_maria_ssl $configmariadb
                destroy .mytpch
                loadtpch
            } -text {OK}
        }
        "default" {
            ttk::button $Name -command {
                set maria_num_tpch_threads [ verify_build_threads $maria_num_tpch_threads 512 512 ]
                copyfieldstoconfig configmariadb [ subst $mariafields ] tpch
                Dict2SQLite "mariadb" $configmariadb
                unset mariafields
	        check_maria_ssl $configmariadb
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
