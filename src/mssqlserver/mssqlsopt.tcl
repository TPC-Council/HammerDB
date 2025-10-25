#Configure transaction counter options
proc countmssqlsopts { bm } {
    upvar #0 icons icons
    upvar #0 configmssqlserver configmssqlserver
    upvar #0 genericdict genericdict
    global afval interval tclog uniquelog tcstamp
    dict with genericdict { dict with transaction_counter {   
            #variables for button options need to be global
            set interval $tc_refresh_rate
            set tclog $tc_log_to_temp
            set uniquelog $tc_unique_log_name
            set tcstamp $tc_log_timestamps
    }}
    setlocaltcountvars $configmssqlserver 0
    variable mssqloptsfields 
    if {![string match windows $::tcl_platform(platform)]} {
        set platform "lin"
        set mssqloptsfields [ dict create connection { mssqls_linux_server {.countopt.c1.e1 get} mssqls_port {.countopt.c1.e2 get} mssqls_linux_odbc {.countopt.c1.e3 get} mssqls_uid {.countopt.c1.e4 get} mssqls_pass {.countopt.c1.e5 get} mssqls_tcp $mssqls_tcp mssqls_azure $mssqls_azure mssqls_encrypt_connection $mssqls_encrypt_connection mssqls_trust_server_cert $mssqls_trust_server_cert mssqls_linux_authent $mssqls_linux_authent mssqls_msi_object_id $mssqls_msi_object_id} ]
    } else {
        set platform "win"
        set mssqloptsfields [ dict create connection { mssqls_server {.countopt.c1.e1 get} mssqls_port {.countopt.c1.e2 get} mssqls_odbc_driver {.countopt.c1.e3 get} mssqls_uid {.countopt.c1.e4 get} mssqls_pass {.countopt.c1.e5 get} mssqls_tcp $mssqls_tcp mssqls_azure $mssqls_azure mssqls_encrypt_connection $mssqls_encrypt_connection mssqls_trust_server_cert $mssqls_trust_server_cert mssqls_authentication $mssqls_authentication mssqls_msi_object_id $mssqls_msi_object_id} ]
    }

    if { [ info exists afval ] } {
        after cancel $afval
        unset afval
    }

    catch "destroy .countopt"
    ttk::toplevel .countopt
    wm transient .countopt .ed_mainFrame
    wm withdraw .countopt
    wm title .countopt {SQL Server TX Counter Options}
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
    ttk::label $Prompt -text "SQL Server :"
    if { $platform eq "lin" } {
        ttk::entry $Name -width 30 -textvariable mssqls_linux_server
    } else {
        ttk::entry $Name -width 30 -textvariable mssqls_server
    }
    grid $Prompt -column 0 -row 1 -sticky e
    grid $Name -column 1 -row 1 -sticky ew
    set Prompt $Parent.c1.p1a
    ttk::label $Prompt -text "TCP :"
    set Name $Parent.c1.e1a
    ttk::checkbutton $Name -text "" -variable mssqls_tcp -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 2 -sticky e
    grid $Name -column 1 -row 2 -sticky w
    bind .countopt.c1.e1a <ButtonPress-1> {
        if { $mssqls_tcp eq "false" } {
            catch {.countopt.c1.e2 configure -state normal}
        } else {
            catch {.countopt.c1.e2 configure -state disabled}
        }
    }
    set Name $Parent.c1.e2
    set Prompt $Parent.c1.p2
    ttk::label $Prompt -text "SQL Server Port :"   
    ttk::entry $Name  -width 30 -textvariable mssqls_port
    grid $Prompt -column 0 -row 3 -sticky e
    grid $Name -column 1 -row 3 -sticky ew
    if { $mssqls_tcp eq "true" } {
        catch {.countopt.c1.e2 configure -state normal}
    } else {
        catch {.countopt.c1.e2 configure -state disabled}
    }
    set Prompt $Parent.c1.p2a
    ttk::label $Prompt -text "Azure :"
    set Name $Parent.c1.e2a
    ttk::checkbutton $Name -text "" -variable mssqls_azure -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 4 -sticky e
    grid $Name -column 1 -row 4 -sticky w
    set Prompt $Parent.c1.p2b
    ttk::label $Prompt -text "Encrypt Connection :"
    set Name $Parent.c1.e2b
    ttk::checkbutton $Name -text "" -variable mssqls_encrypt_connection -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 5 -sticky e
    grid $Name -column 1 -row 5 -sticky w
    set Prompt $Parent.c1.p2c
    ttk::label $Prompt -text "Trust Server Certificate :"
    set Name $Parent.c1.e2c
    ttk::checkbutton $Name -text "" -variable mssqls_trust_server_cert -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 6 -sticky e
    grid $Name -column 1 -row 6 -sticky w
    set Name $Parent.c1.e3
    set Prompt $Parent.c1.p3
    ttk::label $Prompt -text "SQL Server ODBC Driver :"   
    if { $platform eq "lin" } {
        ttk::entry $Name  -width 30 -textvariable mssqls_linux_odbc
    } else {
        ttk::entry $Name  -width 30 -textvariable mssqls_odbc_driver
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
    set Prompt $Parent.c1.pa
    ttk::label $Prompt -text "Authentication :"
    grid $Prompt -column 0 -row 8 -sticky e
    set Name $Parent.c1.r1
    if { $platform eq "lin" } {
        ttk::radiobutton $Name -value "windows" -text "Windows" -variable mssqls_linux_authent
    } else {
        ttk::radiobutton $Name -value "windows" -text "Windows" -variable mssqls_authentication
    }
    grid $Name -column 1 -row 8 -sticky w
    bind .countopt.c1.r1 <ButtonPress-1> {
        .countopt.c1.e4 configure -state disabled
        .countopt.c1.e5 configure -state disabled
        .countopt.c1.e5a configure -state disabled
    }
    set Name $Parent.c1.r2
    if { $platform eq "lin" } {
        ttk::radiobutton $Name -value "sql" -text "SQL Server" -variable mssqls_linux_authent
    } else {
        ttk::radiobutton $Name -value "sql" -text "SQL Server" -variable mssqls_authentication
    }
    grid $Name -column 1 -row 9 -sticky w
    bind .countopt.c1.r2 <ButtonPress-1> {
        .countopt.c1.e4 configure -state normal
        .countopt.c1.e5 configure -state normal
        .countopt.c1.e5a configure -state disabled
    }
    set Name $Parent.c1.r3
    if { $platform eq "lin" } {
        ttk::radiobutton $Name -value "entra" -text "Entra" -variable mssqls_linux_authent
    } else {
        ttk::radiobutton $Name -value "entra" -text "Entra" -variable mssqls_authentication
    }
    grid $Name -column 1 -row 10 -sticky w
    bind .countopt.c1.r3 <ButtonPress-1> {
        .countopt.c1.e4 configure -state disabled
        .countopt.c1.e5 configure -state disabled
        .countopt.c1.e5a configure -state normal
    }

    set Name $Parent.c1.e4
    set Prompt $Parent.c1.p4
    ttk::label $Prompt -text "SQL Server User ID :"
    ttk::entry $Name  -width 30 -textvariable mssqls_uid
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
    if {($platform eq "win" && ($mssqls_authentication == "windows" || $mssqls_authentication == "entra") ) || ($platform eq "lin" && ($mssqls_linux_authent == "windows" || $mssqls_linux_authent == "entra") )} {
        $Name configure -state disabled
    }
    set Name $Parent.c1.e5
    set Prompt $Parent.c1.p5
    ttk::label $Prompt -text "SQL Server User Password :"   
    ttk::entry $Name -show * -width 30 -textvariable mssqls_pass
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew
    if {($platform eq "win" && ($mssqls_authentication == "windows" || $mssqls_authentication == "entra") ) || ($platform eq "lin" && ($mssqls_linux_authent == "windows" || $mssqls_linux_authent == "entra") )} {
        $Name configure -state disabled
    }
    set Name $Parent.c1.e5a
    set Prompt $Parent.c1.p5a
    ttk::label $Prompt -text "MSI Object ID :"   
    ttk::entry $Name -width 30 -textvariable mssqls_msi_object_id
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky ew
    if {($platform eq "win" && ($mssqls_authentication == "windows" || $mssqls_authentication == "sql")) || ($platform eq "lin" && ($mssqls_linux_authent == "windows"  || $mssqls_linux_authent == "sql" ) )} {
        $Name configure -state disabled
    }
    set Name $Parent.f1.e6
    set Prompt $Parent.f1.p6
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

    bind .countopt.c1.e1 <Delete> {
        if [%W selection present] {
            %W delete sel.first sel.last
        } else {
            %W delete insert
        }
    }

    set Name $Parent.b2
    ttk::button $Name  -command {
        unset mssqloptsfields
        destroy .countopt
    } -text Cancel
    pack $Name -anchor nw -side right -padx 3 -pady 3

    set Name $Parent.b1
    ttk::button $Name -command {
        copyfieldstoconfig configmssqlserver [ subst $mssqloptsfields ] tpcc
        Dict2SQLite "mssqlserver" $configmssqlserver
        unset mssqloptsfields
        if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs" 
            dict set genericdict transaction_counter tc_refresh_rate 10
        } else {
	if { ![ regexp {[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}|\ynull\y} $mssqls_msi_object_id ] } {
		tk_messageBox -message "MSI Object ID is not a valid format" 
		dict set configmssqlserver connection mssqls_msi_object_id "null" 
                Dict2SQLite "mssqlserver" $configmssqlserver
	} else {
            dict with genericdict { dict with transaction_counter {
                    set tc_refresh_rate [.countopt.f1.e6 get]
                    set tc_log_to_temp $tclog
                    set tc_unique_log_name $uniquelog
                    set tc_log_timestamps $tcstamp 
            }}
        }}
        destroy .countopt
        catch "destroy .tc"
    } -text {OK}
    pack $Name -anchor nw -side right -padx 3 -pady 3

    wm geometry .countopt +50+50
    wm deiconify .countopt
    raise .countopt
    update
}

proc configmssqlstpcc {option} {
    upvar #0 icons icons
    upvar #0 configmssqlserver configmssqlserver
    #set variables to values in dict
    setlocaltpccvars $configmssqlserver
    set tpccfields [ dict create tpcc {mssqls_dbase {.tpc.c1.e6 get} mssqls_bucket {.tpc.f1.e8 get} mssqls_total_iterations {.tpc.f1.e14 get} mssqls_rampup {.tpc.f1.e18 get} mssqls_duration {.tpc.f1.e19 get} mssqls_async_client {.tpc.f1.e23 get} mssqls_async_delay {.tpc.f1.e24 get} mssqls_imdb $mssqls_imdb mssqls_durability $mssqls_durability mssqls_count_ware $mssqls_count_ware mssqls_num_vu $mssqls_num_vu mssqls_driver $mssqls_driver mssqls_raiseerror $mssqls_raiseerror mssqls_keyandthink $mssqls_keyandthink mssqls_checkpoint $mssqls_checkpoint mssqls_allwarehouse $mssqls_allwarehouse mssqls_timeprofile $mssqls_timeprofile mssqls_async_scale $mssqls_async_scale mssqls_async_verbose $mssqls_async_verbose mssqls_connect_pool $mssqls_connect_pool mssqls_use_bcp $mssqls_use_bcp} ]
    if {![string match windows $::tcl_platform(platform)]} {
        set platform "lin"
        set mssqlsconn [ dict create connection { mssqls_linux_server {.tpc.c1.e1 get} mssqls_port {.tpc.c1.e2 get} mssqls_linux_odbc {.tpc.c1.e3 get} mssqls_uid {.tpc.c1.e4 get} mssqls_pass {.tpc.c1.e5 get} mssqls_tcp $mssqls_tcp mssqls_azure $mssqls_azure mssqls_encrypt_connection $mssqls_encrypt_connection mssqls_trust_server_cert $mssqls_trust_server_cert mssqls_linux_authent $mssqls_linux_authent mssqls_msi_object_id $mssqls_msi_object_id} ]
    } else {
        set platform "win"
        set mssqlsconn [ dict create connection { mssqls_server {.tpc.c1.e1 get} mssqls_port {.tpc.c1.e2 get} mssqls_odbc_driver {.tpc.c1.e3 get} mssqls_uid {.tpc.c1.e4 get} mssqls_pass {.tpc.c1.e5 get} mssqls_tcp $mssqls_tcp mssqls_azure $mssqls_azure mssqls_encrypt_connection $mssqls_encrypt_connection mssqls_trust_server_cert $mssqls_trust_server_cert mssqls_authentication $mssqls_authentication mssqls_msi_object_id $mssqls_msi_object_id} ]
    }
    variable mssqlsfields
    set mssqlsfields [ dict merge $mssqlsconn $tpccfields ]
    set whlist [ get_warehouse_list_for_spinbox ]
    catch "destroy .tpc"
    ttk::toplevel .tpc
    wm transient .tpc .ed_mainFrame
    wm withdraw .tpc
    switch $option {
        "all" { wm title .tpc {Microsoft SQL Server TPROC-C Schema Options} }
        "build" { wm title .tpc {Microsoft SQL Server TPROC-C Build Options} }
        "drive" { wm title .tpc {Microsoft SQL Server TPROC-C Driver Options} }
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
    ttk::label $Prompt -text "SQL Server :"
    if { $platform eq "lin" } {
        ttk::entry $Name -width 30 -textvariable mssqls_linux_server
    } else {
        ttk::entry $Name -width 30 -textvariable mssqls_server
    }
    grid $Prompt -column 0 -row 1 -sticky e
    grid $Name -column 1 -row 1 -sticky ew
    set Prompt $Parent.c1.p1a
    ttk::label $Prompt -text "TCP :"
    set Name $Parent.c1.e1a
    ttk::checkbutton $Name -text "" -variable mssqls_tcp -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 2 -sticky e
    grid $Name -column 1 -row 2 -sticky w
    bind .tpc.c1.e1a <ButtonPress-1> {
        if { $mssqls_tcp eq "false" } {
            catch {.tpc.c1.e2 configure -state normal}
        } else {
            catch {.tpc.c1.e2 configure -state disabled}
        }
    }
    set Name $Parent.c1.e2
    set Prompt $Parent.c1.p2
    ttk::label $Prompt -text "SQL Server Port :"   
    ttk::entry $Name  -width 30 -textvariable mssqls_port
    grid $Prompt -column 0 -row 3 -sticky e
    grid $Name -column 1 -row 3 -sticky ew
    if { $mssqls_tcp eq "true" } {
        catch {.tpc.c1.e2 configure -state normal}
    } else {
        catch {.tpc.c1.e2 configure -state disabled}
    }
    set Prompt $Parent.c1.p2a
    ttk::label $Prompt -text "Azure :"
    set Name $Parent.c1.e2a
    ttk::checkbutton $Name -text "" -variable mssqls_azure -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 4 -sticky e
    grid $Name -column 1 -row 4 -sticky w
    set Prompt $Parent.c1.p2b
    ttk::label $Prompt -text "Encrypt Connection :"
    set Name $Parent.c1.e2b
    ttk::checkbutton $Name -text "" -variable mssqls_encrypt_connection -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 5 -sticky e
    grid $Name -column 1 -row 5 -sticky w
    set Prompt $Parent.c1.p2c
    ttk::label $Prompt -text "Trust Server Certificate :"
    set Name $Parent.c1.e2c
    ttk::checkbutton $Name -text "" -variable mssqls_trust_server_cert -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 6 -sticky e
    grid $Name -column 1 -row 6 -sticky w
    set Name $Parent.c1.e3
    set Prompt $Parent.c1.p3
    ttk::label $Prompt -text "SQL Server ODBC Driver :"   
    if { $platform eq "lin" } {
        ttk::entry $Name  -width 30 -textvariable mssqls_linux_odbc
    } else {
        ttk::entry $Name  -width 30 -textvariable mssqls_odbc_driver
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
    set Prompt $Parent.c1.pa
    ttk::label $Prompt -text "Authentication :"
    grid $Prompt -column 0 -row 8 -sticky e
    set Name $Parent.c1.r1
    if { $platform eq "lin" } {
        ttk::radiobutton $Name -value "windows" -text "Windows" -variable mssqls_linux_authent
    } else {
        ttk::radiobutton $Name -value "windows" -text "Windows" -variable mssqls_authentication
    }
    grid $Name -column 1 -row 8 -sticky w
    bind .tpc.c1.r1 <ButtonPress-1> {
        .tpc.c1.e4 configure -state disabled
        .tpc.c1.e5 configure -state disabled
        .tpc.c1.e5a configure -state disabled
    }
    set Name $Parent.c1.r2
    if { $platform eq "lin" } {
        ttk::radiobutton $Name -value "sql" -text "SQL Server" -variable mssqls_linux_authent
    } else {
        ttk::radiobutton $Name -value "sql" -text "SQL Server" -variable mssqls_authentication
    }
    grid $Name -column 1 -row 9 -sticky w
    bind .tpc.c1.r2 <ButtonPress-1> {
        .tpc.c1.e4 configure -state normal
        .tpc.c1.e5 configure -state normal
        .tpc.c1.e5a configure -state disabled
    }
    set Name $Parent.c1.r3
    if { $platform eq "lin" } {
        ttk::radiobutton $Name -value "entra" -text "Entra" -variable mssqls_linux_authent
    } else {
        ttk::radiobutton $Name -value "entra" -text "Entra" -variable mssqls_authentication
    }
    grid $Name -column 1 -row 10 -sticky w
    bind .tpc.c1.r3 <ButtonPress-1> {
        .tpc.c1.e4 configure -state disabled
        .tpc.c1.e5 configure -state disabled
        .tpc.c1.e5a configure -state normal
    }
    set Name $Parent.c1.e4
    set Prompt $Parent.c1.p4
    ttk::label $Prompt -text "SQL Server User ID :"
    ttk::entry $Name  -width 30 -textvariable mssqls_uid
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
    if {($platform eq "win" && ($mssqls_authentication == "windows" || $mssqls_authentication == "entra") ) || ($platform eq "lin" && ($mssqls_linux_authent == "windows" || $mssqls_linux_authent == "entra") )} {
        $Name configure -state disabled
    }
    set Name $Parent.c1.e5
    set Prompt $Parent.c1.p5
    ttk::label $Prompt -text "SQL Server User Password :"   
    ttk::entry $Name -show * -width 30 -textvariable mssqls_pass
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew
    if {($platform eq "win" && ($mssqls_authentication == "windows" || $mssqls_authentication == "entra") ) || ($platform eq "lin" && ($mssqls_linux_authent == "windows" || $mssqls_linux_authent == "entra") )} {
        $Name configure -state disabled
    }
     set Name $Parent.c1.e5a
    set Prompt $Parent.c1.p5a
    ttk::label $Prompt -text "MSI Object ID :"   
    ttk::entry $Name -width 30 -textvariable mssqls_msi_object_id
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky ew
    if {($platform eq "win" && ($mssqls_authentication == "windows" || $mssqls_authentication == "sql")) || ($platform eq "lin" && ($mssqls_linux_authent == "windows"  || $mssqls_linux_authent == "sql" ) )} {
        $Name configure -state disabled
    }
    set Name $Parent.c1.e6
    set Prompt $Parent.c1.p6
    ttk::label $Prompt -text "TPROC-C SQL Server Database :" -image [ create_image hdbicon icons ] -compound left
    ttk::entry $Name -width 30 -textvariable mssqls_dbase
    grid $Prompt -column 0 -row 14 -sticky e
    grid $Name -column 1 -row 14 -sticky ew
    if { $option eq "all" || $option eq "build" } {
        set Prompt $Parent.f1.p7
        ttk::label $Prompt -text "In-Memory OLTP :"
        set Name $Parent.f1.e7
        ttk::checkbutton $Name -text "" -variable mssqls_imdb -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 15 -sticky e
        grid $Name -column 1 -row 15 -sticky w
        bind .tpc.f1.e7 <ButtonPress-1> {
            if { $mssqls_imdb eq "false" } {
                foreach field {r5 r6 e8} {
                    catch {.tpc.f1.$field configure -state normal}
                }
            } else {
                foreach field {r5 r6 e8} {
                    catch {.tpc.f1.$field configure -state disabled}
                    set mssqls_bucket 1
                }
            }
        }
        set Name $Parent.f1.e8
        set Prompt $Parent.f1.p8
        ttk::label $Prompt -text "In-Memory Hash Bucket Multiplier :"   
        ttk::entry $Name  -width 30 -textvariable mssqls_bucket
        grid $Prompt -column 0 -row 16 -sticky e
        grid $Name -column 1 -row 16 -sticky ew
        set Name $Parent.f1.e9
        set Prompt $Parent.f1.p9
        ttk::label $Prompt -text "In-Memory Durability :"
        grid $Prompt -column 0 -row 17 -sticky e
        set Name $Parent.f1.r5
        ttk::radiobutton $Name -value "SCHEMA_AND_DATA" -text "SCHEMA_AND_DATA" -variable mssqls_durability
        grid $Name -column 1 -row 17 -sticky w
        set Name $Parent.f1.r6
        ttk::radiobutton $Name -value "SCHEMA_ONLY" -text "SCHEMA_ONLY" -variable mssqls_durability
        grid $Name -column 1 -row 18 -sticky w
        if { $mssqls_imdb eq "true" } {
            foreach field {r5 r6 e8} {
                catch {.tpc.f1.$field configure -state normal}
            }
        } else {
            foreach field {r5 r6 e8} {
                catch {.tpc.f1.$field configure -state disabled}
                set mssqls_bucket 1
            }
        }
        set Prompt $Parent.f1.p10
        ttk::label $Prompt -text "Number of Warehouses :"
        set Name $Parent.f1.e10
        ttk::spinbox $Name -value $whlist -textvariable mssqls_count_ware
        bind .tpc.f1.e10 <<Any-Button-Any-Key>> {
            if {$mssqls_num_vu > $mssqls_count_ware} {
                set mssqls_num_vu $mssqls_count_ware
            }
        }
        grid $Prompt -column 0 -row 19 -sticky e
        grid $Name -column 1 -row 19 -sticky ew
        set Prompt $Parent.f1.p11
        ttk::label $Prompt -text "Virtual Users to Build Schema :"
        set Name $Parent.f1.e11
        ttk::spinbox $Name -from 1 -to 512 -textvariable mssqls_num_vu
        bind .tpc.f1.e11 <<Any-Button-Any-Key>> {
            if {$mssqls_num_vu > $mssqls_count_ware} {
                set mssqls_num_vu $mssqls_count_ware
            }
        }
        event add <<Any-Button-Any-Key>> <Any-ButtonRelease>
        event add <<Any-Button-Any-Key>> <KeyRelease>
        grid $Prompt -column 0 -row 20 -sticky e
        grid $Name -column 1 -row 20 -sticky ew

        set Prompt $Parent.f1.p12
        set Name $Parent.f1.e12     
        ttk::label $Prompt -text "Use BCP Option :"
        ttk::checkbutton $Name -text "" -variable mssqls_use_bcp -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 21 -sticky e
        grid $Name -column 1 -row 21 -sticky ew
    }
    if { $option eq "all" || $option eq "drive" } {
        if { $option eq "all" } {
            set Prompt $Parent.f1.h3
            ttk::label $Prompt -image [ create_image driveroptlo icons ]
            grid $Prompt -column 0 -row 22 -sticky e
            set Prompt $Parent.f1.h4
            ttk::label $Prompt -text "Driver Options"
            grid $Prompt -column 1 -row 22 -sticky w
        }
        set Prompt $Parent.f1.p12
        ttk::label $Prompt -text "TPROC-C Driver Script :" -image [ create_image hdbicon icons ] -compound left
        grid $Prompt -column 0 -row 23 -sticky e
        set Name $Parent.f1.r4
        ttk::radiobutton $Name -value "test" -text "Test Driver Script" -variable mssqls_driver
        grid $Name -column 1 -row 23 -sticky w
        bind .tpc.f1.r4 <ButtonPress-1> {
            set mssqls_checkpoint "false"
            set mssqls_allwarehouse "false"
            set mssqls_timeprofile "false"
            set mssqls_async_scale "false"
            set mssqls_async_verbose "false"
            .tpc.f1.e17 configure -state disabled
            .tpc.f1.e18 configure -state disabled
            .tpc.f1.e19 configure -state disabled
            .tpc.f1.e20 configure -state disabled
            .tpc.f1.e21 configure -state disabled
            .tpc.f1.e22 configure -state disabled
            .tpc.f1.e23 configure -state disabled
            .tpc.f1.e24 configure -state disabled
            .tpc.f1.e25 configure -state disabled
        }
        set Name $Parent.f1.r5
        ttk::radiobutton $Name -value "timed" -text "Timed Driver Script" -variable mssqls_driver
        grid $Name -column 1 -row 24 -sticky w
        bind .tpc.f1.r5 <ButtonPress-1> {
            .tpc.f1.e17 configure -state normal
            .tpc.f1.e18 configure -state normal
            .tpc.f1.e19 configure -state normal
            .tpc.f1.e20 configure -state normal
            .tpc.f1.e21 configure -state normal
            .tpc.f1.e22 configure -state normal
            if { $mssqls_async_scale eq "true" } {
                .tpc.f1.e23 configure -state normal
                .tpc.f1.e24 configure -state normal
                .tpc.f1.e25 configure -state normal
            }
        }
        set Name $Parent.f1.e14
        set Prompt $Parent.f1.p14
        ttk::label $Prompt -text "Total Transactions per User :"
        ttk::entry $Name -width 30 -textvariable mssqls_total_iterations
        grid $Prompt -column 0 -row 25 -sticky e
        grid $Name -column 1 -row 25 -sticky ew
        set Prompt $Parent.f1.p15
        ttk::label $Prompt -text "Exit on SQL Server Error :"
        set Name $Parent.f1.e15
        ttk::checkbutton $Name -text "" -variable mssqls_raiseerror -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 26 -sticky e
        grid $Name -column 1 -row 26 -sticky w
        set Prompt $Parent.f1.p16
        ttk::label $Prompt -text "Keying and Thinking Time :"
        set Name $Parent.f1.e16
        ttk::checkbutton $Name -text "" -variable mssqls_keyandthink -onvalue "true" -offvalue "false"
        bind .tpc.f1.e16 <Any-ButtonRelease> {
            if { $mssqls_driver eq "timed" } {
                if { $mssqls_keyandthink eq "true" } {
                    set mssqls_async_scale "false"
                    set mssqls_async_verbose "false"
                    .tpc.f1.e23 configure -state disabled
                    .tpc.f1.e24 configure -state disabled
                    .tpc.f1.e25 configure -state disabled
                }
            }
        }
        grid $Prompt -column 0 -row 27 -sticky e
        grid $Name -column 1 -row 27 -sticky w
        set Prompt $Parent.f1.p17
        ttk::label $Prompt -text "Checkpoint when complete :"
        set Name $Parent.f1.e17
        ttk::checkbutton $Name -text "" -variable mssqls_checkpoint -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 28 -sticky e
        grid $Name -column 1 -row 28 -sticky w
        if {$mssqls_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e18
        set Prompt $Parent.f1.p18
        ttk::label $Prompt -text "Minutes of Rampup Time :"
        ttk::entry $Name -width 30 -textvariable mssqls_rampup
        grid $Prompt -column 0 -row 29 -sticky e
        grid $Name -column 1 -row 29 -sticky ew
        if {$mssqls_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e19
        set Prompt $Parent.f1.p19
        ttk::label $Prompt -text "Minutes for Test Duration :"
        ttk::entry $Name -width 30 -textvariable mssqls_duration
        grid $Prompt -column 0 -row 30 -sticky e
        grid $Name -column 1 -row 30 -sticky ew
        if {$mssqls_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e20
        set Prompt $Parent.f1.p20
        ttk::label $Prompt -text "Use All Warehouses :"
        ttk::checkbutton $Name -text "" -variable mssqls_allwarehouse -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 31 -sticky e
        grid $Name -column 1 -row 31 -sticky ew
        if {$mssqls_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e21
        set Prompt $Parent.f1.p21
        ttk::label $Prompt -text "Time Profile :"
        ttk::checkbutton $Name -text "" -variable mssqls_timeprofile -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 32 -sticky e
        grid $Name -column 1 -row 32 -sticky ew
        if {$mssqls_driver == "test" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e22
        set Prompt $Parent.f1.p22
        ttk::label $Prompt -text "Asynchronous Scaling :"
        ttk::checkbutton $Name -text "" -variable mssqls_async_scale -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 33 -sticky e
        grid $Name -column 1 -row 33 -sticky ew
        if {$mssqls_driver == "test" } {
            set mssqls_async_scale "false"
            $Name configure -state disabled
        }
        bind .tpc.f1.e22 <Any-ButtonRelease> {
            if { $mssqls_async_scale eq "true" } {
                set mssqls_async_verbose "false"
                .tpc.f1.e23 configure -state disabled
                .tpc.f1.e24 configure -state disabled
                .tpc.f1.e25 configure -state disabled
            } else {
                if { $mssqls_driver eq "timed" } {
                    set mssqls_keyandthink "true"
                    .tpc.f1.e23 configure -state normal
                    .tpc.f1.e24 configure -state normal
                    .tpc.f1.e25 configure -state normal
                }
            }
        }
        set Name $Parent.f1.e23
        set Prompt $Parent.f1.p23
        ttk::label $Prompt -text "Asynch Clients per Virtual User :"
        ttk::entry $Name -width 30 -textvariable mssqls_async_client
        grid $Prompt -column 0 -row 34 -sticky e
        grid $Name -column 1 -row 34 -sticky ew
        if {$mssqls_driver == "test" || $mssqls_async_scale == "false" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e24
        set Prompt $Parent.f1.p24
        ttk::label $Prompt -text "Asynch Client Login Delay :"
        ttk::entry $Name -width 30 -textvariable mssqls_async_delay
        grid $Prompt -column 0 -row 35 -sticky e
        grid $Name -column 1 -row 35 -sticky ew
        if {$mssqls_driver == "test" || $mssqls_async_scale == "false" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e25
        set Prompt $Parent.f1.p25
        ttk::label $Prompt -text "Asynchronous Verbose :"
        ttk::checkbutton $Name -text "" -variable mssqls_async_verbose -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 36 -sticky e
        grid $Name -column 1 -row 36 -sticky ew
        if {$mssqls_driver == "test" || $mssqls_async_scale == "false" } {
            set mssqls_async_verbose "false"
            $Name configure -state disabled
        }
        set Name $Parent.c1.e26
        set Prompt $Parent.c1.p26
        ttk::label $Prompt -text "XML Connect Pool :"
        ttk::checkbutton $Name -text "" -variable mssqls_connect_pool -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 37 -sticky e
        grid $Name -column 1 -row 37 -sticky ew
    }
    #This is the Cancel button variables stay as before
    set Name $Parent.b2
    ttk::button $Name -command {
        unset mssqlsfields
        destroy .tpc
    } -text Cancel
    pack $Name -anchor nw -side right -padx 3 -pady 3
    #This is the OK button all variables loaded back into config dict
    set Name $Parent.b1
    switch $option {
        "drive" {
            ttk::button $Name -command {
	        if { ![ regexp {[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}|\ynull\y} $mssqls_msi_object_id ] } {
		tk_messageBox -message "MSI Object ID is not a valid format" 
		set mssqls_msi_object_id "null" 
	        }
                copyfieldstoconfig configmssqlserver [ subst $mssqlsfields ] tpcc
                Dict2SQLite "mssqlserver" $configmssqlserver
                unset mssqlsfields
                destroy .tpc
                loadtpcc
            } -text {OK}
        }
        "default" {
            ttk::button $Name -command {
	        if { ![ regexp {[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}|\ynull\y} $mssqls_msi_object_id ] } {
		tk_messageBox -message "MSI Object ID is not a valid format" 
		set mssqls_msi_object_id "null" 
	        }
                set mssqls_count_ware [ verify_warehouse $mssqls_count_ware 100000 ]
                set mssqls_num_vu [ verify_build_threads $mssqls_num_vu $mssqls_count_ware 1024 ]
                copyfieldstoconfig configmssqlserver [ subst $mssqlsfields ] tpcc
                Dict2SQLite "mssqlserver" $configmssqlserver
                unset mssqlsfields
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

proc configmssqlstpch {option} {
    upvar #0 icons icons
    upvar #0 configmssqlserver configmssqlserver

    #set variables to values in dict
    setlocaltpchvars $configmssqlserver
    
    set tpchfields [ dict create tpch {mssqls_tpch_dbase {.mssqlstpch.c1.e6 get} mssqls_maxdop {.mssqlstpch.f1.e6a get} mssqls_total_querysets {.mssqlstpch.f1.e10 get} mssqls_update_sets {.mssqlstpch.f1.e14 get} mssqls_trickle_refresh {.mssqlstpch.f1.e15 get} mssqls_colstore $mssqls_colstore mssqls_scale_fact $mssqls_scale_fact mssqls_num_tpch_threads $mssqls_num_tpch_threads mssqls_raise_query_error $mssqls_raise_query_error mssqls_verbose $mssqls_verbose mssqls_refresh_on $mssqls_refresh_on mssqls_refresh_verbose $mssqls_refresh_verbose mssqls_tpch_use_bcp $mssqls_tpch_use_bcp mssqls_tpch_partition_orders_and_lineitems $mssqls_tpch_partition_orders_and_lineitems mssqls_tpch_advanced_stats $mssqls_tpch_advanced_stats} ]

    if {![string match windows $::tcl_platform(platform)]} {
        set platform "lin"
        set mssqlsconn [ dict create connection { mssqls_linux_server {.mssqlstpch.c1.e1 get} mssqls_port {.mssqlstpch.c1.e2 get} mssqls_linux_odbc {.mssqlstpch.c1.e3 get} mssqls_uid {.mssqlstpch.c1.e4 get} mssqls_pass {.mssqlstpch.c1.e5 get} mssqls_tcp $mssqls_tcp mssqls_azure $mssqls_azure mssqls_encrypt_connection $mssqls_encrypt_connection mssqls_trust_server_cert $mssqls_trust_server_cert mssqls_linux_authent $mssqls_linux_authent mssqls_msi_object_id $mssqls_msi_object_id} ]
    } else {
        set platform "win"
        set mssqlsconn [ dict create connection { mssqls_server {.mssqlstpch.c1.e1 get} mssqls_port {.mssqlstpch.c1.e2 get} mssqls_odbc_driver {.mssqlstpch.c1.e3 get} mssqls_uid {.mssqlstpch.c1.e4 get} mssqls_pass {.mssqlstpch.c1.e5 get} mssqls_tcp $mssqls_tcp mssqls_azure $mssqls_azure mssqls_encrypt_connection $mssqls_encrypt_connection mssqls_trust_server_cert $mssqls_trust_server_cert mssqls_authentication $mssqls_authentication mssqls_msi_object_id $mssqls_msi_object_id} ]
    }
    variable mssqlsfields
    set mssqlsfields [ dict merge $mssqlsconn $tpchfields ]
    catch "destroy .mssqlstpch"
    ttk::toplevel .mssqlstpch
    wm transient .mssqlstpch .ed_mainFrame
    wm withdraw .mssqlstpch
    switch $option {
        "all" { wm title .mssqlstpch {SQL Server TPROC-H Schema Options} }
        "build" { wm title .mssqlstpch {SQL Server TPROC-H Build Options} }
        "drive" {  wm title .mssqlstpch {SQL Server TPROC-H Driver Options} }
    }
    set Parent .mssqlstpch
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
    ttk::label $Prompt -text "SQL Server :"
    if { $platform eq "lin" } {
        ttk::entry $Name -width 30 -textvariable mssqls_linux_server
    } else {
        ttk::entry $Name -width 30 -textvariable mssqls_server
    }
    grid $Prompt -column 0 -row 1 -sticky e
    grid $Name -column 1 -row 1 -sticky ew
    set Prompt $Parent.c1.p1a
    ttk::label $Prompt -text "TCP :"
    set Name $Parent.c1.e1a
    ttk::checkbutton $Name -text "" -variable mssqls_tcp -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 2 -sticky e
    grid $Name -column 1 -row 2 -sticky w
    bind .mssqlstpch.c1.e1a <ButtonPress-1> {
        if { $mssqls_tcp eq "false" } {
            catch {.mssqlstpch.c1.e2 configure -state normal}
        } else {
            catch {.mssqlstpch.c1.e2 configure -state disabled}
        }
    }
    set Name $Parent.c1.e2
    set Prompt $Parent.c1.p2
    ttk::label $Prompt -text "SQL Server Port :"
    ttk::entry $Name  -width 30 -textvariable mssqls_port
    grid $Prompt -column 0 -row 3 -sticky e
    grid $Name -column 1 -row 3 -sticky ew
    if { $mssqls_tcp eq "true" } {
        catch {.mssqlstpch.c1.e2 configure -state normal}
    } else {
        catch {.mssqlstpch.c1.e2 configure -state disabled}
    }
    set Prompt $Parent.c1.p2a
    ttk::label $Prompt -text "Azure :"
    set Name $Parent.c1.e2a
    ttk::checkbutton $Name -text "" -variable mssqls_azure -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 4 -sticky e
    grid $Name -column 1 -row 4 -sticky w
    set Prompt $Parent.c1.p2b
    ttk::label $Prompt -text "Encrypt Connection :"
    set Name $Parent.c1.e2b
    ttk::checkbutton $Name -text "" -variable mssqls_encrypt_connection -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 5 -sticky e
    grid $Name -column 1 -row 5 -sticky w
    set Prompt $Parent.c1.p2c
    ttk::label $Prompt -text "Trust Server Certificate :"
    set Name $Parent.c1.e2c
    ttk::checkbutton $Name -text "" -variable mssqls_trust_server_cert -onvalue "true" -offvalue "false"
    grid $Prompt -column 0 -row 6 -sticky e
    grid $Name -column 1 -row 6 -sticky w
    set Name $Parent.c1.e3
    set Prompt $Parent.c1.p3
    ttk::label $Prompt -text "SQL Server ODBC Driver :"
    if { $platform eq "lin" } {
        ttk::entry $Name  -width 30 -textvariable mssqls_linux_odbc
    } else {
        ttk::entry $Name  -width 30 -textvariable mssqls_odbc_driver
    }
    grid $Prompt -column 0 -row 7 -sticky e
    grid $Name -column 1 -row 7 -sticky ew
    set Prompt $Parent.c1.pa
    ttk::label $Prompt -text "Authentication :"
    grid $Prompt -column 0 -row 8 -sticky e
    set Name $Parent.c1.r1
    if { $platform eq "lin" } {
        ttk::radiobutton $Name -value "windows" -text "Windows" -variable mssqls_linux_authent
    } else {
        ttk::radiobutton $Name -value "windows" -text "Windows" -variable mssqls_authentication
    }
    grid $Name -column 1 -row 8 -sticky w
    bind .mssqlstpch.c1.r1 <ButtonPress-1> {
        .mssqlstpch.c1.e4 configure -state disabled
        .mssqlstpch.c1.e5 configure -state disabled
        .mssqlstpch.c1.e5a configure -state disabled
    }
    set Name $Parent.c1.r2
    if { $platform eq "lin" } {
        ttk::radiobutton $Name -value "sql" -text "SQL Server" -variable mssqls_linux_authent
    } else {
        ttk::radiobutton $Name -value "sql" -text "SQL Server" -variable mssqls_authentication
    }
    grid $Name -column 1 -row 9 -sticky w
    bind .mssqlstpch.c1.r2 <ButtonPress-1> {
        .mssqlstpch.c1.e4 configure -state normal
        .mssqlstpch.c1.e5 configure -state normal
        .mssqlstpch.c1.e5a configure -state disabled
    }
    set Name $Parent.c1.r3
    if { $platform eq "lin" } {
        ttk::radiobutton $Name -value "entra" -text "Entra" -variable mssqls_linux_authent
    } else {
        ttk::radiobutton $Name -value "entra" -text "Entra" -variable mssqls_authentication
    }
    grid $Name -column 1 -row 10 -sticky w
    bind .mssqlstpch.c1.r3 <ButtonPress-1> {
        .mssqlstpch.c1.e4 configure -state disabled
        .mssqlstpch.c1.e5 configure -state disabled
        .mssqlstpch.c1.e5a configure -state normal
    }
    set Name $Parent.c1.e4
    set Prompt $Parent.c1.p4
    ttk::label $Prompt -text "SQL Server User ID :"
    ttk::entry $Name  -width 30 -textvariable mssqls_uid
    grid $Prompt -column 0 -row 11 -sticky e
    grid $Name -column 1 -row 11 -sticky ew
      if {($platform eq "win" && ($mssqls_authentication == "windows" || $mssqls_authentication == "entra") ) || ($platform eq "lin" && ($mssqls_linux_authent == "windows" || $mssqls_linux_authent == "entra") )} {
        $Name configure -state disabled
    }
    set Name $Parent.c1.e5
    set Prompt $Parent.c1.p5
    ttk::label $Prompt -text "SQL Server User Password :"
    ttk::entry $Name -show * -width 30 -textvariable mssqls_pass
    grid $Prompt -column 0 -row 12 -sticky e
    grid $Name -column 1 -row 12 -sticky ew
      if {($platform eq "win" && ($mssqls_authentication == "windows" || $mssqls_authentication == "entra") ) || ($platform eq "lin" && ($mssqls_linux_authent == "windows" || $mssqls_linux_authent == "entra") )} {
        $Name configure -state disabled
    }
    set Name $Parent.c1.e5a
    set Prompt $Parent.c1.p5a
    ttk::label $Prompt -text "MSI Object ID :"   
    ttk::entry $Name -width 30 -textvariable mssqls_msi_object_id
    grid $Prompt -column 0 -row 13 -sticky e
    grid $Name -column 1 -row 13 -sticky ew
    if {($platform eq "win" && ($mssqls_authentication == "windows" || $mssqls_authentication == "sql")) || ($platform eq "lin" && ($mssqls_linux_authent == "windows"  || $mssqls_linux_authent == "sql" ) )} {
        $Name configure -state disabled
    }
    set Name $Parent.c1.e6
    set Prompt $Parent.c1.p6
    ttk::label $Prompt -text "TPROC-H SQL Server Database :" -image [ create_image hdbicon icons ] -compound left
    ttk::entry $Name -width 30 -textvariable mssqls_tpch_dbase
    grid $Prompt -column 0 -row 14 -sticky e
    grid $Name -column 1 -row 14 -sticky ew
    set Name $Parent.f1.e6a
    set Prompt $Parent.f1.p6a
    ttk::label $Prompt -text "MAXDOP :"
    ttk::entry $Name -width 30 -textvariable mssqls_maxdop
    grid $Prompt -column 0 -row 15 -sticky e
    grid $Name -column 1 -row 15 -columnspan 4 -sticky ew
    if { $option eq "all" || $option eq "build" } {
        set Prompt $Parent.f1.p7
        ttk::label $Prompt -text "Clustered Columnstore :"
        set Name $Parent.f1.e7
        ttk::checkbutton $Name -text "" -variable mssqls_colstore -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 16 -sticky e
        grid $Name -column 1 -row 16 -sticky w
        set Name $Parent.f1.e8
        set Prompt $Parent.f1.p8 
        ttk::label $Prompt -text "Scale Factor :"
        grid $Prompt -column 0 -row 17 -sticky e
        set Name $Parent.f1.f2
        ttk::frame $Name -width 30
        grid $Name -column 1 -row 17 -sticky ew
        # top row
        set rcnt 1
        foreach item {1} {
            set Name $Parent.f1.f2.r$rcnt
            set width [string length $item]
            ttk::radiobutton $Name -variable db2_scale_fact -text $item -value $item -width $width
            grid $Name -column $rcnt -row 0 -sticky w
            incr rcnt
        }
        set rcnt 2
        foreach item {10 30} {
            set Name $Parent.f1.f2.r$rcnt
            set width [string length $item]
            ttk::radiobutton $Name -variable db2_scale_fact -text $item -value $item -width $width
            grid $Name -column $rcnt -row 0 -sticky w
            incr rcnt
        }
        set rcnt 4
        foreach item {100 300} {
            set Name $Parent.f1.f2.r$rcnt
            set width [string length $item]
            ttk::radiobutton $Name -variable db2_scale_fact -text $item -value $item -width $width
            grid $Name -column $rcnt -row 0 -sticky w
            incr rcnt
        }
        # bottom row
        set rcnt 1
        foreach item {1000 3000} {
            set Name $Parent.f1.f2.ra$rcnt
            set width [string length $item]
            ttk::radiobutton $Name -variable db2_scale_fact -text $item -value $item -width $width
            grid $Name -column $rcnt -row 1 -sticky w
            incr rcnt
        }
        set rcnt 3
        foreach item {10000 30000 100000} {
            set Name $Parent.f1.f2.ra$rcnt
            set width [string length $item]
            ttk::radiobutton $Name -variable db2_scale_fact -text $item -value $item -width $width
            grid $Name -column $rcnt -row 1 -sticky w
            incr rcnt
        }
        set Prompt $Parent.f1.p9
        ttk::label $Prompt -text "Virtual Users to Build Schema :"
        set Name $Parent.f1.e9
        ttk::spinbox $Name -from 1 -to 512 -textvariable mssqls_num_tpch_threads
        grid $Prompt -column 0 -row 18 -sticky e
        grid $Name -column 1 -row 18 -sticky ew

        set Prompt $Parent.f1.p10
        set Name $Parent.f1.e10
        ttk::label $Prompt -text "Use BCP Option:"
        ttk::checkbutton $Name -text "" -variable mssqls_tpch_use_bcp -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 19 -sticky e
        grid $Name -column 1 -row 19 -sticky w


        set Prompt $Parent.f1.p11
        set Name $Parent.f1.e11
        ttk::label $Prompt -text "Partition Orders and Lineitems:"
        ttk::checkbutton $Name -text "" -variable mssqls_tpch_partition_orders_and_lineitems -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 20 -sticky e
        grid $Name -column 1 -row 20 -sticky w
        
        set Prompt $Parent.f1.p12
        set Name $Parent.f1.e12
        ttk::label $Prompt -text "Create Advanced Statistics:"
        ttk::checkbutton $Name -text "" -variable mssqls_tpch_advanced_stats -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 21 -sticky e
        grid $Name -column 1 -row 21 -sticky w

        
    }
    if { $option eq "all" || $option eq "drive" } {
        if { $option eq "all" } {
            set Prompt $Parent.f1.h3
            ttk::label $Prompt -image [ create_image driveroptlo icons ]
            grid $Prompt -column 0 -row 22 -sticky e
            set Prompt $Parent.f1.h4
            ttk::label $Prompt -text "Driver Options"
            grid $Prompt -column 1 -row 22 -sticky w
        }
        set Name $Parent.f1.e10
        set Prompt $Parent.f1.p10
        ttk::label $Prompt -text "Total Query Sets per User :"
        ttk::entry $Name -width 30 -textvariable mssqls_total_querysets
        grid $Prompt -column 0 -row 23 -sticky e
        grid $Name -column 1 -row 23 -columnspan 4 -sticky ew
        set Prompt $Parent.f1.p11
        ttk::label $Prompt -text "Exit on SQL Server Error :"
        set Name $Parent.f1.e11
        ttk::checkbutton $Name -text "" -variable mssqls_raise_query_error -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 24 -sticky e
        grid $Name -column 1 -row 24 -sticky w
        set Prompt $Parent.f1.p12
        ttk::label $Prompt -text "Verbose Output :"
        set Name $Parent.f1.e12
        ttk::checkbutton $Name -text "" -variable mssqls_verbose -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 25 -sticky e
        grid $Name -column 1 -row 25 -sticky w
        set Prompt $Parent.f1.p13
        ttk::label $Prompt -text "Refresh Function :"
        set Name $Parent.f1.e13
        ttk::checkbutton $Name -text "" -variable mssqls_refresh_on -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 26 -sticky e
        grid $Name -column 1 -row 26 -sticky w
        bind $Parent.f1.e13 <Button> {
            if {$mssqls_refresh_on eq "true"} { 
                set mssqls_refresh_verbose "false"
                foreach field {e14 e15 e16} {
                    .mssqlstpch.f1.$field configure -state disabled 
                }
            } else {
                foreach field {e14 e15 e16} {
                    .mssqlstpch.f1.$field configure -state normal
                }
            }
        }
        set Name $Parent.f1.e14
        set Prompt $Parent.f1.p14
        ttk::label $Prompt -text "Number of Update Sets :"
        ttk::entry $Name -width 30 -textvariable mssqls_update_sets
        grid $Prompt -column 0 -row 27 -sticky e
        grid $Name -column 1 -row 27  -columnspan 4 -sticky ew
        if {$mssqls_refresh_on == "false" } {
            $Name configure -state disabled
        }
        set Name $Parent.f1.e15
        set Prompt $Parent.f1.p15
        ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
        ttk::entry $Name -width 30 -textvariable mssqls_trickle_refresh
        grid $Prompt -column 0 -row 28 -sticky e
        grid $Name -column 1 -row 28  -columnspan 4 -sticky ew
        if {$mssqls_refresh_on == "false" } {
            $Name configure -state disabled
        }
        set Prompt $Parent.f1.p16
        ttk::label $Prompt -text "Refresh Verbose :"
        set Name $Parent.f1.e16
        ttk::checkbutton $Name -text "" -variable mssqls_refresh_verbose -onvalue "true" -offvalue "false"
        grid $Prompt -column 0 -row 29 -sticky e
        grid $Name -column 1 -row 29 -sticky w
        if {$mssqls_refresh_on == "false" } {
            $Name configure -state disabled
        }
    }
    set Name $Parent.b2
    ttk::button $Name -command {
        unset mssqlsfields
        destroy .mssqlstpch
    } -text Cancel
    pack $Name -anchor nw -side right -padx 3 -pady 3
    set Name $Parent.b1
    switch $option {
        "drive" {
            ttk::button $Name -command {
	        if { ![ regexp {[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}|\ynull\y} $mssqls_msi_object_id ] } {
		tk_messageBox -message "MSI Object ID is not a valid format" 
		set mssqls_msi_object_id "null" 
	        }
                copyfieldstoconfig configmssqlserver [ subst $mssqlsfields ] tpch
                Dict2SQLite "mssqlserver" $configmssqlserver
                unset mssqlsfields
                destroy .mssqlstpch
                loadtpch
            } -text {OK}
        }
        "default" {
            ttk::button $Name -command {
		if { ![ regexp {[[:xdigit:]]{8}(-[[:xdigit:]]{4}){3}-[[:xdigit:]]{12}|\ynull\y} $mssqls_msi_object_id ] } {
		tk_messageBox -message "MSI Object ID is not a valid format" 
		set mssqls_msi_object_id "null" 
	        }
                set mssqls_num_tpch_threads [ verify_build_threads $mssqls_num_tpch_threads 512 512 ]
                copyfieldstoconfig configmssqlserver [ subst $mssqlsfields ] tpch
                Dict2SQLite "mssqlserver" $configmssqlserver
                unset mssqlsfields
                destroy .mssqlstpch
            } -text {OK}
        }
    }
    pack $Name -anchor nw -side right -padx 3 -pady 3
    wm geometry .mssqlstpch +50+50
    wm deiconify .mssqlstpch
    raise .mssqlstpch
    update
}
