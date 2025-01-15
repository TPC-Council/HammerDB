proc tcount_maria {bm interval masterthread} {
    global tc_threadID maria_ssl_options
    upvar #0 dbdict dbdict
    if {[dict exists $dbdict maria library ]} {
        set library [ dict get $dbdict maria library ]
    } else { set library "mariatcl" }

    #Setup Transaction Counter Thread
    set tc_threadID [thread::create {
    proc chk_socket { host socket } {
    if { ![string match windows $::tcl_platform(platform)] && ($host eq "127.0.0.1" || [ string tolower $host ] eq "localhost") && [ string tolower $socket ] != "null" } {
        return "TRUE"
    } else {
        return "FALSE"
    		}
	}

    proc ConnectToMaria { MASTER host port socket ssl_options user password } {
    global mariastatus
    #ssl_options is variable length so build a connectstring
    if { [ chk_socket $host $socket ] eq "TRUE" } {
        set use_socket "true"
        append connectstring " -socket $socket"
         } else {
        set use_socket "false"
        append connectstring " -host $host -port $port"
        }
        foreach key [ dict keys $ssl_options ] {
        append connectstring " $key [ dict get $ssl_options $key ] "
        }
        append connectstring " -user $user"
        if { [ string tolower $password ] != "null" } {
        append connectstring " -password $password"
        }
        set login_command "mariaconnect [ dict get $connectstring ]"
        #eval the login command
        if [catch {set maria_handler [eval $login_command]} message ] {
        set connected "false"
        } else {
        set connected "true"
        }
    if {$connected} {
        return $maria_handler
    } else {
                    tsv::set application tc_errmsg $message
                    eval [subst {thread::send $MASTER show_tc_errmsg}]
                    thread::release
                    return
    }
}

        proc read_more { MASTER library maria_host maria_port maria_socket maria_ssl_options maria_user maria_pass maria_tpch_user maria_tpch_pass interval old tce bm } {
            set timeout 0
            set iconflag 0
            if { $interval <= 0 } { set interval 10 } 
            set gcol "#42ADB6"
            if { ![ info exists tcdata ] } { set tcdata {} }
            if { ![ info exists timedata ] } { set timedata {} }
            if { $bm eq "TPC-C" } {
                set sqc "show global status where Variable_name = 'Com_commit' or Variable_name =  'Com_rollback'"
                set tmp_maria_user $maria_user
                set tmp_maria_pass $maria_pass
                set tval 60
            } else {
                set sqc "show global status where Variable_name = 'Queries' or Variable_name = 'Com_show_status'"
                set tmp_maria_user $maria_tpch_user
                set tmp_maria_pass $maria_tpch_pass
                set tval 3600
            }
            set mplier [ expr {$tval / $interval} ]
            if {[catch {package require $library} message]} {
                tsv::set application tc_errmsg "failed to load library $message"
                eval [subst {thread::send $MASTER show_tc_errmsg}]
                thread::release
                return
            }
            if [catch {package require tcountcommon} message ] {
                tsv::set application tc_errmsg "failed to load common transaction counter functions $message"
                eval [subst {thread::send $MASTER show_tc_errmsg}]
                thread::release
                return
            } else {
                namespace import tcountcommon::*
            }
	    set maria_handler [ ConnectToMaria $MASTER $maria_host $maria_port $maria_socket $maria_ssl_options $tmp_maria_user $tmp_maria_pass ]
            #Enter loop until stop button pressed
            while { $timeout eq 0 } {
                set timeout [ tsv::get application timeout ]
                if { $timeout != 0 } { break }

                if {[catch {set handler_stat [ list [ maria::sel $maria_handler $sqc -list ] ]} message]} {
                    tsv::set application tc_errmsg "sql failed $message"
                    eval [subst {thread::send $MASTER show_tc_errmsg}]
                    catch { mariaclose $maria_handler }
                    break
                } else {
                    if { $bm eq "TPC-C" } {
                        regexp {\{\{Com_commit\ ([0-9]+)\}\ \{Com_rollback\ ([0-9]+)\}\}} $handler_stat all com_comm com_roll
                        set outc [ expr $com_comm + $com_roll ]
                    } else {
                        regexp {\{\{Com_show_status\ ([0-9]+)\}\ \{Queries\ ([0-9]+)\}\}} $handler_stat all show_stat queries
                        regexp {\{\{Queries\ ([0-9]+)\}\}} $handler_stat all show_stat queries
                        set outc [ expr $queries - $show_stat ]
                    }
                }
                set new $outc
                set tstamp [ clock format [ clock seconds ] -format %H:%M:%S ]
                set tcsize [ llength $tcdata ]
                if { $tcsize eq 0 } { 
                    set newtick 1 
                    lappend tcdata $newtick 0
                    lappend timedata $newtick $tstamp
                    if { [ catch {thread::send -async $MASTER {::showLCD 0 }}] } { break } 
                } else { 
                    if { $tcsize >= 40 } {
                        set tcdata [ downshift $tcdata ]
                        set timedata [ downshift $timedata ]
                        set newtick 20
                    } else {
                        set newtick [ expr {$tcsize / 2 + 1} ] 
                        if { $newtick eq 2 } {
                            set tcdata [ lreplace $tcdata 0 1 1 [expr {[expr {abs($new - $old)}] * $mplier}] ]
                        }
                    }
                    lappend tcdata $newtick [expr {[expr {abs($new - $old)}] * $mplier}]
                    lappend timedata $newtick $tstamp
                    if { ![ isdiff $tcdata ] } {
                        set tcdata [ lreplace $tcdata 1 1 0 ]
                    }
                    set transval [expr {[expr {abs($new - $old)}] * $mplier}]
                    if { [ catch [ subst {thread::send -async $MASTER {::showLCD $transval }} ] ] } { break }
                } 
                if { $tcsize >= 2 } { 
                    if { $iconflag eq 0 } {
                        if { [ catch [ subst {thread::send -async $MASTER { .ed_mainFrame.tc.g delete "all" }} ] ] } { break }
                        set iconflag 1
                    }
                    if { [ zeroes $tcdata ] eq 0 } {
                        set tcdata {}
                        set timedata {}
                        if { [ catch {thread::send -async $MASTER { tce destroy }}]} { break }
                    } else {
                        if { [ catch [ subst {thread::send -async $MASTER { tce data d1 -colour $gcol -points 0 -lines 1 -coords {$tcdata} -time {$timedata} }} ] ] } { break } 
                    }
                }
                set old $new
                set pauseval $interval
                for {set pausecount $pauseval} {$pausecount > 0} {incr pausecount -1} {
                    if { [ tsv::get application timeout ] } { break } else { after 1000 }
                }
            }
            eval  [ subst {thread::send -async $MASTER { post_kill_transcount_cleanup }} ]
            thread::release
        }
        thread::wait 
    }]
    #Setup Transaction Counter Connection Variables
    upvar #0 configmariadb configmariadb
    setlocaltcountvars $configmariadb 1
    #If the options menu has been run under the GUI maria_ssl_options is set
    #If build is run under the GUI, CLI or WS maria_ssl_options is not set
    #Set it now if it doesn't exist
    if ![ info exists maria_ssl_options ] { check_maria_ssl $configmariadb }
    set old 0
    #add zipfs paths to thread
    catch {eval [ subst {thread::send $tc_threadID {lappend ::auto_path [zipfs root]app/lib}}]}
    catch {eval [ subst {thread::send $tc_threadID {::tcl::tm::path add [zipfs root]app/modules modules}}]}
    #Call Transaction Counter to start read_more loop
    eval [ subst {thread::send -async $tc_threadID { read_more $masterthread $library $maria_host $maria_port $maria_socket {$maria_ssl_options} $maria_user [ quotemeta $maria_pass ] $maria_tpch_user [ quotemeta $maria_tpch_pass ] $interval $old tce $bm }}]
} 
