# OceanBase tenant counter, independent of the native MySQL counter.
proc tcount_oceanbase_mysql {bm interval masterthread query_timeout} {
    global tc_threadID mysql_ssl_options
    upvar #0 dbdict dbdict
    if {[dict exists $dbdict mysql library ]} {
        set library [ dict get $dbdict mysql library ]
    } else { set library "mysqltcl" }
    #Setup Transaction Counter Thread
    set tc_threadID [thread::create {
        proc ConnectToMySQL { MASTER host port ssl_options user password} {
            global mysqlstatus
            #ssl_options is variable length so build a connectstring
            set connectstring [list -host $host -port $port]

            foreach key [ dict keys $ssl_options ] {
                lappend connectstring $key [dict get $ssl_options $key]
            }
            lappend connectstring -user $user -password $password
            set login_command [linsert $connectstring 0 mysqlconnect]
            #eval the login command
            if [catch {set mysql_handler [eval $login_command]} message ] {
                set connected "false"
            } else {
                set connected "true"
            }
            if {$connected} {
                oceanbasecommon::configure_session $mysql_handler
                return $mysql_handler
            } else {
                tsv::set application tc_errmsg $message
                eval [subst {thread::send $MASTER show_tc_errmsg}]
                thread::release
                return
            }
        }

        proc read_more { MASTER library mysql_host mysql_port mysql_ssl_options mysql_user mysql_pass mysql_tpch_user mysql_tpch_pass interval old tce bm query_timeout} {
            package require oceanbasecommon
            oceanbasecommon::configure $query_timeout
            set counter_reads 0
            set timeout 0
            set iconflag 0
            if { $interval <= 0 } { set interval 10 }
            set gcol "#0066CC"
            if { ![ info exists tcdata ] } { set tcdata {} }
            if { ![ info exists timedata ] } { set timedata {} }
            if { $bm eq "TPC-C" } {
                set sqc [oceanbasecommon::counter_sql]
                set tmp_mysql_user $mysql_user
                set tmp_mysql_pass $mysql_pass
                set tval 60
            } else {
                set sqc {SELECT 'Queries', SUM(VALUE) FROM oceanbase.GV$SYSSTAT WHERE NAME = 'sql select count'}
                set tmp_mysql_user $mysql_tpch_user
                set tmp_mysql_pass $mysql_tpch_pass
                set tval 3600
            }
            set mplier [ expr {double($tval) / $interval} ]
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
            set mysql_handler [ ConnectToMySQL $MASTER $mysql_host $mysql_port $mysql_ssl_options $tmp_mysql_user $tmp_mysql_pass]
            #Enter loop until stop button pressed
            while { $timeout eq 0 } {
                set timeout [ tsv::get application timeout ]
                if { $timeout != 0 } { break }

                if {[catch {set handler_stat [ list [ mysql::sel $mysql_handler $sqc -list ] ]} message]} {
                    tsv::set application tc_errmsg "sql failed $message"
                    eval [subst {thread::send $MASTER show_tc_errmsg}]
                    catch { mysqlclose $mysql_handler }
                    break
                } else {
                    if { $bm eq "TPC-C" } {
                        if {[catch {set outc [oceanbasecommon::parse_transaction_count [lindex $handler_stat 0]]} message]} {
                            tsv::set application tc_errmsg $message
                            thread::send $MASTER show_tc_errmsg
                            catch {mysqlclose $mysql_handler}
                            break
                        }
                    } else {
                        set outc [lindex $handler_stat 0 0 1]
                        if {![string is entier -strict $outc]} {
                            tsv::set application tc_errmsg "OceanBase SQL select counter unavailable"
                            thread::send $MASTER show_tc_errmsg
                            catch {mysqlclose $mysql_handler}
                            break
                        }
                        # Exclude the counter's own SELECT requests from its delta.
                        incr counter_reads
                        incr outc -$counter_reads

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
                            set tcdata [ lreplace $tcdata 0 1 1 [expr {round(abs($new - $old) * $mplier)}] ]
                        }
                    }
                    lappend tcdata $newtick [expr {round(abs($new - $old) * $mplier)}]
                    lappend timedata $newtick $tstamp
                    if { ![ isdiff $tcdata ] } {
                        set tcdata [ lreplace $tcdata 1 1 0 ]
                    }
                    set transval [expr {round(abs($new - $old) * $mplier)}]
                if { [ catch [ subst {thread::send -async $MASTER {::showLCD $transval }} ] ] } { break }}
                if { $tcsize >= 2 } {
                    if { $iconflag eq 0 } {
                        if { [ catch [ subst {thread::send -async $MASTER { .ed_mainFrame.tc.g delete "all" }} ] ] } { break }
                        set iconflag 1
                    }
                    if { [ zeroes $tcdata ] eq 0 } {
                        # Keep a baseline through idle periods. Clearing the
                        # samples loses the first activity burst after idle.
                        set tcdata [list 1 0]
                        set timedata [list 1 $tstamp]
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
    upvar #0 configmysql configmysql
    setlocaltcountvars $configmysql 1
    set mysql_pass [::oceanbase::mysql::decode_password $mysql_pass]
    set mysql_tpch_pass [::oceanbase::mysql::decode_password $mysql_tpch_pass]
    #If the options menu has been run under the GUI mysql_ssl_options is set
    #If build is run under the GUI, CLI or WS mysql_ssl_options is not set
    #Set it now if it doesn't exist
    if ![ info exists mysql_ssl_options ] { check_mysql_ssl $configmysql }
    set old 0
    #add zipfs paths to thread
    catch {eval [ subst {thread::send $tc_threadID {lappend ::auto_path [zipfs root]app/lib}}]}
    catch {eval [ subst {thread::send $tc_threadID {::tcl::tm::path add [zipfs root]app/modules modules}}]}
    #Call Transaction Counter to start read_more loop
    # Keep empty passwords and values containing Tcl syntax as single arguments.
    thread::send -async $tc_threadID [list read_more $masterthread $library \
        $mysql_host $mysql_port $mysql_ssl_options $mysql_user $mysql_pass \
        $mysql_tpch_user $mysql_tpch_pass $interval $old tce $bm \
        $query_timeout]
}
