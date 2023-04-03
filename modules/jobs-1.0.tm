package provide jobs 1.0
namespace eval jobs {
  namespace export init_job_tables_gui init_job_tables jobmain jobs job hdbjobs jobs_ws job_disable job_format wapp-page-jobs getjob savechart
  interp alias {} job {} jobs

  proc commify {x} {
    set trailer ""
    set pix [string last "." $x]
    if {$pix != -1} {
      # there is a decimal trailer
      set trailer [string range $x $pix end]
      set x [string range $x 0 [expr {$pix - 1}]]
    }

    set z {}
    foreach {a b c} [lreverse [split $x ""]] {
      lappend z [join [list $c $b $a] ""]
    }
    set ret [join [lreverse $z] ","]
    append ret $trailer
  }

  proc hformat {x} {

    # megabytes
    set q [expr {($x * 1.0) / pow(2,20)}]

    if {$q < 7} {
      # 0.XY show two decimal places
      set q [expr {entier($q * 100) / 100.0}]
    } else {
      # r$ctypeound it out, its big
      set q [expr {round($q)}]
    }


    return "[commify $q] MB"
  }

  proc init_job_tables_gui { } {
    #In the GUI, we disable the jobs output even though it works by running the jobs command in the console
    rename jobs {}
    uplevel #0 {proc hdbjobs { args } { return "" }}
    #If we want to enable jobs output in the GUI comment out previous 2 lines and uncomment the following line
    #init_job_tables
  }

  proc init_job_tables { } {
    upvar #0 genericdict genericdict
    if {[dict exists $genericdict commandline jobs_disable ]} {
      if { [ dict get $genericdict commandline jobs_disable ] eq 1 } {
        uplevel #0 {proc hdbjobs { args } { return "" }}
        return 
      }
    }
    if {[dict exists $genericdict commandline sqlite_db ]} {
      set sqlite_db [ dict get $genericdict commandline sqlite_db ]
      if { [string toupper $sqlite_db] eq "TMP" || [string toupper $sqlite_db] eq "TEMP" } {
        set tmpdir [ findtempdir ]
        if { $tmpdir != "notmpdir" } {
          set sqlite_db [ file join $tmpdir hammer.DB ]
        } else {
          puts "Error Database Directory set to TMP but couldn't find temp directory"
        }
      }
    } else {
      set sqlite_db ":memory:"
    }
    if [catch {sqlite3 hdbjobs $sqlite_db} message ] {
      puts "Error initializing SQLite database : $message"
      return
    } else {
      catch {hdbjobs timeout 30000}
      #hdbjobs eval {PRAGMA foreign_keys=ON}
      if { $sqlite_db eq ":memory:" } {
        catch {hdbjobs eval {DROP TABLE JOBMAIN}}
        catch {hdbjobs eval {DROP TABLE JOBTIMING}}
        catch {hdbjobs eval {DROP TABLE JOBTCOUNT}}
        catch {hdbjobs eval {DROP TABLE JOBOUTPUT}}
        catch {hdbjobs eval {DROP TABLE JOBCHART}}
        if [catch {hdbjobs eval {CREATE TABLE JOBMAIN(jobid TEXT, db TEXT, bm TEXT, jobdict TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')))}} message ] {
          puts "Error creating JOBMAIN table in SQLite in-memory database : $message"
          return
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBTIMING(jobid TEXT, vu INTEGER, procname TEXT, calls INTEGER, min_ms REAL, avg_ms REAL, max_ms REAL, total_ms REAL, p99_ms REAL, p95_ms REAL, p50_ms REAL, sd REAL, ratio_pct REAL, summary INTEGER, elapsed_ms REAL, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBTIMING table in SQLite in-memory database : $message"
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBTCOUNT(jobid TEXT, counter INTEGER, metric TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBTCOUNT table in SQLite in-memory database : $message"
          return
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBOUTPUT(jobid TEXT, vu INTEGER, output TEXT, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBOUTPUT table in SQLite in-memory database : $message"
          return
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBCHART(jobid TEXT, chart TEXT, html TEXT, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBCHART table in SQLite in-memory database : $message"

          return
        } else {
          catch {hdbjobs eval {CREATE INDEX JOBMAIN_IDX ON JOBMAIN(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBTIMING_IDX ON JOBTIMING(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBTCOUNT_IDX ON JOBTCOUNT(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBOUTPUT_IDX ON JOBOUTPUT(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBCHART_IDX ON JOBCHART(jobid)}}
          puts "Initialized new SQLite in-memory database"
        }
      } else {
        if [catch {set tblname [ hdbjobs eval {SELECT name FROM sqlite_master WHERE type='table' AND name='JOBMAIN'}]} message ] {
          puts "Error querying  JOBOUTPUT table in SQLite on-disk database : $message"
          return
        } else {
          if { $tblname eq "" } {
            if [catch {hdbjobs eval {CREATE TABLE JOBMAIN(jobid TEXT, db TEXT, bm TEXT, jobdict TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')))}} message ] {
              puts "Error creating JOBMAIN table in SQLite on-disk database : $message"
              return
            } elseif [ catch {hdbjobs eval {CREATE TABLE JOBTIMING(jobid TEXT, vu INTEGER, procname TEXT, calls INTEGER, min_ms REAL, avg_ms REAL, max_ms REAL, total_ms REAL, p99_ms REAL, p95_ms REAL, p50_ms REAL, sd REAL, ratio_pct REAL, summary INTEGER, elapsed_ms REAL, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
              puts "Error creating JOBTIMING table in SQLite on-disk database : $message"
              return
            } elseif [ catch {hdbjobs eval {CREATE TABLE JOBTCOUNT(jobid TEXT, counter INTEGER, metric TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
              puts "Error creating JOBTCOUNT table in SQLite on-disk database : $message"
              return
            } elseif [catch {hdbjobs eval {CREATE TABLE JOBOUTPUT(jobid TEXT, vu INTEGER, output TEXT)}} message ] {
              puts "Error creating JOBOUTPUT table in SQLite on-disk database : $message"
              return
            } elseif [ catch {hdbjobs eval {CREATE TABLE JOBCHART(jobid TEXT, chart TEXT, html TEXT, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
              puts "Error creating JOBCHART table in SQLite on-disk database : $message"
              return
            } else {
              catch {hdbjobs eval {CREATE INDEX JOBMAIN_IDX ON JOBMAIN(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBTIMING_IDX ON JOBTIMING(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBTCOUNT_IDX ON JOBTCOUNT(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBOUTPUT_IDX ON JOBOUTPUT(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBCHART_IDX ON JOBCHART(jobid)}}
              puts "Initialized new SQLite on-disk database $sqlite_db"
            }
          } else {
            set size "[ commify [ hdbjobs eval {SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()} ]] KB" 
            puts "Initialized SQLite on-disk database $sqlite_db using existing tables ($size)"
          }
        }
      }
      tsv::set commandline sqldb $sqlite_db
    }
  }

  proc jobmain { jobid } {
    global rdbms bm
    set query [ hdbjobs eval {SELECT COUNT(*) FROM JOBMAIN WHERE JOBID=$jobid} ]
    if { $query eq 0 } {
      set tmpdictforpt [ find_current_dict ]
      hdbjobs eval {INSERT INTO JOBMAIN(jobid,db,bm,jobdict) VALUES($jobid,$rdbms,$bm,$tmpdictforpt)}
      return 0
    } else {
      return 1
    }
  }

  proc jobs { args } {
    upvar #0 genericdict genericdict
    if [catch {set jobs_disabled [ dict get $genericdict commandline jobs_disable ]} message ] {
      puts "Error: Detecting Jobs Enable/Disable: $message"
    } else {
      set opt [ lindex [ split  $args ]  0 ]
      if { $jobs_disabled &&  $opt != "disable" } {
        puts "Error: Jobs Disabled: enable with command \"jobs disable 0\" and restart HammerDB"
        return
      }
    } 
    switch [ llength $args ] {
      0 {
        set res [ getjob "" ]
        return $res
      }
      1 {
        set param [ lindex [ split  $args ]  0 ]
        if [ string equal $param "result" ] {
          set alljobs [ getjob "joblist" ]
          foreach jobres $alljobs {
            set res [ getjob "jobid=$jobres&result" ]
            puts $res
          }
        } elseif [ string equal $param "timestamp" ] {
          set alljobs [ getjob "joblist" ]
          foreach jobres $alljobs {
            set res [ getjob "jobid=$jobres&timestamp" ]
            puts $res
          }	
        } elseif [ string equal $param "joblist" ] {
          return [ getjob "joblist" ]
        } else {
          set jobid $param
          set res [getjob "jobid=$jobid" ]
          puts $res
        }
      }
      2 {
        set jobid [ lindex [ split  $args ]  0 ]
        set cmd [ lindex [ split  $args ]  1 ]
        if { $jobid == "format" } {
          job_format $cmd
        } elseif { $jobid == "disable" } {
          job_disable $cmd
        } else {
          if [ string is entier $cmd ] { set cmd "vu=$cmd" }
          set res [getjob "jobid=$jobid&$cmd" ]
          puts $res
        }
      }
      3 {
        set jobid [ lindex [ split  $args ]  0 ]
        set cmd [ lindex [ split  $args ]  1 ]
        set param3 [ lindex [ split  $args ]  2 ]
        if { ![string equal $cmd "timing" ] && ![ string equal $cmd "getchart" ] } {
          puts "Error: Jobs Three Parameter Usage: jobs jobid timing vuid | jobs jobid getchart charttype"
        } elseif { [ string equal $cmd "timing" ] } {
          set vusel $param3
          if { [ string is entier $vusel ] } { set vusel "vu=$vusel" }
          set res [getjob "jobid=$jobid&$cmd&$vusel" ]
          puts $res
        } elseif { [ string equal $cmd "getchart" ] } {
          set charttype $param3
          if { ![string equal $charttype "result" ] && ![string equal $charttype "timing" ] && ![string equal $charttype "tcount" ]  } {
            puts "Error: Jobs Three Parameter Usage: jobs jobid getchart \[ result | timing | tcount \]"
          } else {
            set ctype "chart=$charttype"
            set res [getjob "jobid=$jobid&$cmd&$ctype" ]
            #return the html rather than puts so we can set a variable with the content
            #puts $res
            return $res
          }
        } 
      }
      default {
        puts "Error: Usage: \[ jobs | jobs format | jobs jobid | jobs jobid command | jobs jobid command option \] - type \"help jobs\""
      }
    }
  }

  proc jobs_ws { args } {
    global ws_port
    switch [ llength $args ] {
      0 {
        set res [rest::get http://localhost:$ws_port/jobs "" ]
        return $res
      }
      1 {
        set param [ lindex [ split  $args ]  0 ]
        if [ string equal $param "result" ] {
          set alljobs [ rest::format_json [ jobs ]]
          foreach jobres $alljobs {
            set res [rest::get http://localhost:$ws_port/jobs?jobid=$jobres&result "" ]
            puts $res
          }
        } elseif [ string equal $param "timestamp" ] {
          set alljobs [ rest::format_json [ jobs ]]
          foreach jobres $alljobs {
            set res [rest::get http://localhost:$ws_port/jobs?jobid=$jobres&timestamp "" ]
            puts $res
          }	
        } else {
          set jobid $param
          set res [rest::get http://localhost:$ws_port/jobs?jobid=$jobid "" ]
          puts $res
        }
      }
      2 {
        set jobid [ lindex [ split  $args ]  0 ]
        set cmd [ lindex [ split  $args ]  1 ]
        if [ string is entier $cmd ] { set cmd "vu=$cmd" }
        set res [rest::get http://localhost:$ws_port/jobs?jobid=$jobid&$cmd "" ]
        puts $res
      }
      3 {
        set jobid [ lindex [ split  $args ]  0 ]
        set cmd [ lindex [ split  $args ]  1 ]
        set vusel [ lindex [ split  $args ]  2 ]
        if { $cmd != "timing" } {
          set body { "type": "error", "key": "message", "value": "Jobs Three Parameter Usage: jobs?jobid=JOBID&timing&vu=VUID" } 
          set res [rest::post http://localhost:$ws_port/echo $body ]
          puts $res
        } else {
          #Three arguments 2nd parameter is timing
          if [ string is entier $vusel ] { set vusel "vu=$vusel" }
          set res [rest::get http://localhost:$ws_port/jobs?jobid=$jobid&$cmd&$vusel "" ]
          puts $res
        }
      }
      default {
        set body { "type": "error", "key": "message", "value": "Usage: jobs?query=parameter" } 
        set res [rest::post http://localhost:$ws_port/echo $body ]
        puts $res
      }
    }
  }

  proc job_disable { val } {
    upvar #0 genericdict genericdict
    if { $val != 0 && $val != 1 } {
      puts {Error: Usage: jobs disable [ 0 | 1 ]}
      return
    } else {
      if { $val eq 0 } {
        puts "Enabling jobs repository, restart HammerDB to take effect"
      } else {
        puts "Disabling jobs repository, restart HammerDB to take effect"
      }
      if [catch {dict set genericdict commandline jobs_disable $val} message ] {
        puts "Error: Enabling/Disabling jobs functionality $message"
      } else { 
        Dict2SQLite "generic" $genericdict
      }
    }
  }

  proc job_format { format } {
    upvar #0 genericdict genericdict
    if { [ string tolower $format ] != "text" && [ string toupper $format ] != "JSON" } {
      puts {Error: Usage: jobs format [ text | JSON ]}
      return
    } else {
      if { [ string tolower $format ] == "text" } { 
        set format "text" 
      } else  { 
        set format "JSON" 
      }
      puts "Setting jobs output format to $format"
      if [catch {dict set genericdict commandline jobsoutput $format} message ] {
        puts "Error: Setting jobs format $message"
      } else { 
        Dict2SQLite "generic" $genericdict
      }
    }
  }

  proc wapp-page-jobs {} {
    global bm
    set query [ wapp-param QUERY_STRING ]
    set params [ split $query & ]
    set paramlen [ llength $params ]
    #No parameters list jobids
    if { $paramlen eq 0 } {
      set joboutput [ hdbjobs eval {SELECT DISTINCT JOBID FROM JOBMAIN} ]
      set huddleobj [ huddle compile {list} $joboutput ]
      wapp-mimetype application/json
      wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
      return
    } else {
      if { $paramlen >= 1 && $paramlen <= 3 } {
        foreach a $params {
          lassign [split $a =] key value
          dict append paramdict $key $value
        }
      } else {
        dict set jsondict error message "Usage: jobs?query=parameter"
        wapp-2-json 2 $jsondict
        return
      }
      if { $paramlen eq 3 } {
        if { [ dict keys $paramdict ] != "jobid timing vu" } {
          dict set jsondict error message "Jobs Three Parameter Usage: jobs?jobid=JOBID&timing&vu=VUID"
          wapp-2-json 2 $jsondict
          return
        } else {
          #3 parameter case of 1-jobid 2-timing 3-vu
          set jobid [ dict get $paramdict jobid ]
          set vuid [ dict get $paramdict vu ]
          if [ string is entier $vuid ] {
            unset -nocomplain jobtiming
            set jobtiming [ dict create ]
            hdbjobs eval {SELECT procname,elapsed_ms,calls,min_ms,avg_ms,max_ms,total_ms,p99_ms,p95_ms,p50_ms,sd,ratio_pct FROM JOBTIMING WHERE JOBID=$jobid and VU=$vuid and SUMMARY=0 ORDER BY RATIO_PCT DESC}  {
              set timing "elapsed_ms $elapsed_ms calls $calls min_ms $min_ms avg_ms $avg_ms max_ms $max_ms total_ms $total_ms p99_ms $p99_ms p95_ms $p95_ms p50_ms $p50_ms sd $sd ratio_pct $ratio_pct"
              dict append jobtiming $procname $timing
            }
            if { ![ dict size $jobtiming ] eq 0 } {
              wapp-2-json 2 $jobtiming
              return
            } else {
              dict set jsondict error message "No Timing Data for VU $vuid for JOB $jobid: jobs?jobid=JOBID&timing&vu=VUID"
              wapp-2-json 2 $jsondict
              return
            }
          } else {
            dict set jsondict error message "Jobs Three Parameter Usage: jobs?jobid=JOBID&timing&vu=VUID"
            wapp-2-json 2 $jsondict
            return
          }
        }
      }
    }
    #1 parameter
    if { $paramlen eq 1 } {
      if { [ dict keys $paramdict ] eq "jobid" } {
        set jobid [ dict get $paramdict jobid ]
        set query [ hdbjobs eval {SELECT COUNT(*) FROM JOBOUTPUT WHERE JOBID=$jobid} ]
        if { $query eq 0 } {
          dict set jsondict error message "Jobid $jobid does not exist"
          wapp-2-json 2 $jsondict
          return
        } else {
          set joboutput [ hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid} ]
          set huddleobj [ huddle compile {list} $joboutput ]
          wapp-mimetype application/json
          wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
        }
      } else {
        dict set jsondict error message "Jobs One Parameter Usage: jobs?jobid=TEXT"
        wapp-2-json 2 $jsondict
        return
      }
      #2 or more parameters
    } else {
      if { [ dict keys $paramdict ] eq "jobid vu" || [ dict keys $paramdict ] eq "jobid status" || [ dict keys $paramdict ] eq "jobid result" || [ dict keys $paramdict ] eq "jobid delete" || [ dict keys $paramdict ] eq "jobid timestamp" || [ dict keys $paramdict ] eq "jobid dict" || [ dict keys $paramdict ] eq "jobid timing" || [ dict keys $paramdict ] eq "jobid db" ||  [ dict keys $paramdict ] eq "jobid bm" || [ dict keys $paramdict ] eq "jobid tcount" } {
        set jobid [ dict get $paramdict jobid ]
        if { [ dict keys $paramdict ] eq "jobid vu" } {
          set vuid [ dict get $paramdict vu ]
        } else {
          if { [ dict keys $paramdict ] eq "jobid result" } {
            set vuid 1
          } else {
            set vuid 0
          }
        }
        set query [ hdbjobs eval {SELECT COUNT(*) FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
        if { $query eq 0 } {
          dict set jsondict error message "Jobid $jobid for virtual user $vuid does not exist"
          wapp-2-json 2 $jsondict
          return
        } else {
          if { [ dict keys $paramdict ] eq "jobid vu" || [ dict keys $paramdict ] eq "jobid status" } {
            set joboutput [ hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
            set huddleobj [ huddle compile {list} $joboutput ]
            wapp-mimetype application/json
            wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
            return
          }
          if { [ dict keys $paramdict ] eq "jobid delete" } {
            set joboutput [ hdbjobs eval {DELETE FROM JOBMAIN WHERE JOBID=$jobid} ]
            set joboutput [ hdbjobs eval {DELETE FROM JOBTIMING WHERE JOBID=$jobid} ]
            set joboutput [ hdbjobs eval {DELETE FROM JOBTCOUNT WHERE JOBID=$jobid} ]
            set joboutput [ hdbjobs eval {DELETE FROM JOBOUTPUT WHERE JOBID=$jobid} ]
            set joboutput [ hdbjobs eval {DELETE FROM JOBCHART WHERE JOBID=$jobid} ]
            dict set jsondict success message "Deleted Jobid $jobid"
            wapp-2-json 2 $jsondict
          } else {
            if { [ dict keys $paramdict ] eq "jobid result" } {
              if { $bm eq "TPC-C" } { 
                set tstamp ""
                set tstamp [ join [ hdbjobs eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$jobid} ]]
                set joboutput [ hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
                set activevu [ lsearch -glob -inline $joboutput "*Active Virtual Users*" ]
                set result [ lsearch -glob -inline $joboutput "TEST RESULT*" ]
              } else {
                set joboutput [ hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid} ]
                set result [ lsearch -all -glob -inline $joboutput "Completed*" ]
              }
              if { $result eq {} } {
                set joboutput [ list $jobid "Jobid has no test result" ]
              } else {
                if { $activevu eq {} } {
                  set joboutput [ list $jobid $tstamp $result ]
                } else {
                  set joboutput [ list $jobid $tstamp $activevu $result ]
                }
              }
            } else {
              if { [ dict keys $paramdict ] eq "jobid timing" } {
                unset -nocomplain jobtiming
                set jobtiming [ dict create ]
                hdbjobs eval {SELECT procname,elapsed_ms,calls,min_ms,avg_ms,max_ms,total_ms,p99_ms,p95_ms,p50_ms,sd,ratio_pct FROM JOBTIMING WHERE JOBID=$jobid and SUMMARY=1 ORDER BY RATIO_PCT DESC}  {
                  set timing "elapsed_ms $elapsed_ms calls $calls min_ms $min_ms avg_ms $avg_ms max_ms $max_ms total_ms $total_ms p99_ms $p99_ms p95_ms $p95_ms p50_ms $p50_ms sd $sd ratio_pct $ratio_pct"
                  dict append jobtiming $procname $timing
                }
                if { ![ dict size $jobtiming ] eq 0 } {
                  wapp-2-json 2 $jobtiming
                  return
                } else {
                  dict set jsondict error message "No Timing Data for JOB $jobid: jobs?jobid=JOBID&timing"
                  wapp-2-json 2 $jsondict
                  return
                }
              } else {
                if { [ dict keys $paramdict ] eq "jobid timestamp" } {
                  set joboutput [ hdbjobs eval {SELECT jobid, timestamp FROM JOBMAIN WHERE JOBID=$jobid} ]
                  wapp-2-json 2 $joboutput
                  return
                } else {
                  if { [ dict keys $paramdict ] eq "jobid dict" } {
                    set joboutput [ join [ hdbjobs eval {SELECT jobdict FROM JOBMAIN WHERE JOBID=$jobid} ]]
                    wapp-2-json 2 $joboutput
                    return
                  } else {
                    if { [ dict keys $paramdict ] eq "jobid tcount" } {
                      set jobheader [ hdbjobs eval {select distinct(db), metric from JOBTCOUNT, JOBMAIN WHERE JOBTCOUNT.JOBID=$jobid AND JOBMAIN.JOBID=$jobid} ]
                      set joboutput [ hdbjobs eval {select counter, JOBTCOUNT.timestamp from JOBTCOUNT WHERE JOBTCOUNT.JOBID=$jobid order by JOBTCOUNT.timestamp asc} ]
                      dict append jsondict $jobheader $joboutput 
                      wapp-2-json 2 $jsondict
                      return
                    } else {
                      if { [ dict keys $paramdict ] eq "jobid db" } {
                        set joboutput [ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]
                      } else {
                        if { [ dict keys $paramdict ] eq "jobid bm" } {
                          set joboutput [ join [ hdbjobs eval {SELECT bm FROM JOBMAIN WHERE JOBID=$jobid} ]]
                        } else {
                          set joboutput [ list $jobid "Cannot find Jobid output" ]
                        }
            }}}}}}
            set huddleobj [ huddle compile {list} $joboutput ]
            wapp-mimetype application/json
            wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
          }
        }
      } else {
        dict set jsondict error message "Jobs Two Parameter Usage: jobs?jobid=TEXT&status or jobs?jobid=TEXT&db or jobs?jobid=TEXT&bm or jobs?jobid=TEXT&timestamp or jobs?jobid=TEXT&dict or jobs?jobid=TEXT&vu=INTEGER or jobs?jobid=TEXT&result or jobs?jobid=TEXT&timing or jobs?jobid=TEXT&delete" 
        wapp-2-json 2 $jsondict
        return
      }
    }
  }

  proc getjobresult { jobid vuid } {
    set jobbm ""
    set jobbm [ join [ hdbjobs eval {SELECT bm FROM JOBMAIN WHERE JOBID=$jobid} ]]
    if { $jobbm != "TPC-C" && $jobbm != "TPC-H" } {
      set joboutput [ list $jobid "Jobid has no test result" ]
      return $joboutput
    }
    set tstamp ""
    set tstamp [ join [ hdbjobs eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$jobid} ]]
    if { $jobbm eq "TPC-C" } { 
      set joboutput [ hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
      set activevu [ lsearch -glob -inline $joboutput "*Active Virtual Users*" ]
      set result [ lsearch -glob -inline $joboutput "TEST RESULT*" ]
    } else {
      set joboutput [ hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid} ]
      set geomean [ lsearch -all -glob -inline $joboutput "*Geometric mean*" ]
      set result [ lsearch -all -glob -inline $joboutput "Completed*" ]
    }
    if { $result eq {} } {
      set joboutput [ list $jobid "Jobid has no test result" ]
      return $joboutput
    } else {
      if { $jobbm eq "TPC-C" } { 
        if { $activevu eq {} } {
          set joboutput [ list $jobid $tstamp $result ]
        } else {
          set joboutput [ list $jobid $tstamp $activevu $result ]
        }
      } else {
        if { $geomean eq {} } {
          set joboutput [ list $jobid $tstamp [ join $result ] ]
        } else {
          set joboutput [ list $jobid $tstamp [ join $geomean ] [ join $result ] ]
        }
      }
    }
    return $joboutput
  }

  proc getjobtiming { jobid } {
    set jobtiming [ dict create ]
    hdbjobs eval {SELECT procname,elapsed_ms,calls,min_ms,avg_ms,max_ms,total_ms,p99_ms,p95_ms,p50_ms,sd,ratio_pct FROM JOBTIMING WHERE JOBID=$jobid and SUMMARY=1 ORDER BY RATIO_PCT DESC}  {
      set timing "elapsed_ms $elapsed_ms calls $calls min_ms $min_ms avg_ms $avg_ms max_ms $max_ms total_ms $total_ms p99_ms $p99_ms p95_ms $p95_ms p50_ms $p50_ms sd $sd ratio_pct $ratio_pct"
      dict append jobtiming $procname $timing
    }
    if { [ dict size $jobtiming ] eq 0 } {
      set jobtiming [ list $jobid "Jobid has no timing data" ]
    }
    return $jobtiming
  }

  proc getjobtcount { jobid } {
    set jobtcount [ dict create ]
    set jobheader [ hdbjobs eval {select distinct(db), metric from JOBTCOUNT, JOBMAIN WHERE JOBTCOUNT.JOBID=$jobid AND JOBMAIN.JOBID=$jobid} ]
    set joboutput [ hdbjobs eval {select counter, JOBTCOUNT.timestamp from JOBTCOUNT WHERE JOBTCOUNT.JOBID=$jobid order by JOBTCOUNT.timestamp asc} ]
    dict append jobtcount $jobheader $joboutput
    if { $jobheader eq "" && $joboutput eq "" } {
      set jobtcount [ list $jobid "Jobid has no transaction counter data" ]
    }
    return $jobtcount
  }

  proc savechart { html file } {
  #undocumented helper process for debug
    if [catch {set fp [open $file w] } errmsg] {
      puts stderr "Unable to open the file: $fp \n $errmsg"
    } else {
      puts $fp $html
      close $fp
      puts "Saved chart html to $file"
    }
  }

  proc getchart { jobid vuid chart } {
    switch $chart {
      "result" {
        set chartdata [ getjobresult $jobid $vuid ]
        if { [ llength $chartdata ] eq 2 && [ string match [ lindex $chartdata 1 ] "Jobid has no test result" ] } {
          putscli "Chart for jobid $jobid not available, Jobid has no test result"
          return
        } else {
          set query [ hdbjobs eval {SELECT COUNT(*) FROM JOBCHART WHERE JOBID=$jobid AND CHART="result"} ]
          if { $query eq 0 } {
            #No result chart exists create one and insert into JOBCHART table
          } else {
            #Return existing results chart from JOBCHART table
            set html [ join [ hdbjobs eval {SELECT html FROM JOBCHART WHERE JOBID=$jobid AND CHART="result"} ]]
            return $html
          }
          set date [ lindex $chartdata 1 ]
          if { [ string match "Geometric*" [ lindex $chartdata 2 ] ] } {
            #TPROC-H result
            set dbdescription [ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]
            if { $dbdescription eq "MSSQLServer" } { set dbdescription "SQL Server" }
            set qsetcount [ llength [regexp -all -inline (?=Geometric) $chartdata] ]
            #Create chart and insert into JOBCHART for future retrieval
            #puts "qsetcount is $qsetcount"
            set ctind 0
            foreach ct {jobid tstamp geomean queryset} { 
              set $ct [ lindex $chartdata  $ctind ] 
              incr ctind
            }
            #geomean and queryset may have mutliple entries
            #puts "RESULT OF FOREACH IS jobid:$jobid\n tstamp:$tstamp\n geomean:$geomean\n queryset:$queryset\n"
            set numbers [regexp -all -inline -- {[0-9]*\.?[0-9]+} $geomean]
            set qsettimes [regexp -all -inline -- {[0-9]+} $queryset]
            foreach {a b} $numbers {c d} $qsettimes {
              #build xaxis and barseries from data
              append xaxisvals \"QS\ $c\ $a\ rows\"\ 
              append geomeantime \"$b\"\ 
              append qsettime \"$d\"\ 
            }
            set bar [ticklecharts::chart new]
            set ::ticklecharts::htmlstdout "True" ; 
            $bar SetOptions -title [ subst {text "$dbdescription TPROC-H Result $jobid @ $date"} ] -tooltip {show "True"} -legend {bottom "5%" left "45%"}
            $bar Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
            $bar Yaxis -name "Seconds" -position "left" -axisLabel {formatter "<0123>value<0125>"}
            $bar AddBarSeries -name GEOMEAN -data [list "$geomeantime "] 
            $bar AddBarSeries -name "QUERY SET" -data [list "$qsettime "]              
            set html [ $bar RenderX -title "$jobid Result" ]
            hdbjobs eval {INSERT INTO JOBCHART(jobid,chart,html) VALUES($jobid,'result',$html)}
            return $html
          } else {
            #TPROC-C
            #Create chart and insert into JOBCHART for future retrieval
            set ctind 0
            foreach ct {jobid tstamp activevu result} { 
              set $ct [ lindex $chartdata  $ctind ] 
              incr ctind
            }
            set splitresult [ split $result ]
            set vus [ lindex $chartdata 2 ]
            set firstdigit [ lindex $splitresult 5 ]
            set firstmet [ lindex $splitresult 6 ]
            set seconddigit [ lindex $splitresult 8 ] 
            set dbdescription [ lindex $splitresult 9 ] 
            set secondmet [ lindex $splitresult end ]
            #NOPM and TPM may be reversed if using old format
            if { $firstmet eq "NOPM" } { 
              set nopm $firstdigit
              set tpm $seconddigit
            } else { 
              set nopm $seconddigit
              set tpm $firstdigit
            }
            if { $dbdescription eq "SQL" } { set dbdescription "SQL Server" }
            set bar [ticklecharts::chart new]
            set ::ticklecharts::htmlstdout "True" ; 
            $bar SetOptions -title [ subst {text "$dbdescription TPROC-C Result $jobid @ $date"} ] -tooltip {show "True"} -legend {bottom "5%" left "45%"}
            $bar Xaxis -data [list [ subst {"$dbdescription $vus"}]] -axisLabel [list show "True"]
            $bar Yaxis -name "Transactions" -position "left" -axisLabel {formatter "<0123>value<0125>"}
            $bar AddBarSeries -name NOPM -data [list "$nopm "]    
            $bar AddBarSeries -name TPM -data [list "$tpm "]              
            set html [ $bar RenderX -title "$jobid Result" ]
            hdbjobs eval {INSERT INTO JOBCHART(jobid,chart,html) VALUES($jobid,'result',$html)}
            return $html
          }
        }
      }
      "timing" {
        set chartdata [ getjobresult $jobid 1 ]
        set tproch 0
        if { [ string match "Geometric*" [ lindex $chartdata 2 ] ] } {
          #TPROC-H
          #Timing data is the Job Output, report VU 1 only
          #We've matched Geometric already in this output so will have timing data captured to calculate this, so no need to check
          set tproch 1
          set query [ hdbjobs eval {SELECT COUNT(*) FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
          if { $query eq 0 } {
            putscli "Chart for jobid $jobid not available, Jobid has no timing data"
            return
          } else {
            set chartdata [ hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=1} ]
          }
        } else {
          #TPROC-C
          set chartdata [ getjobtiming $jobid ]
        }
        if { [ llength $chartdata ] eq 2 && [ string match [ lindex $chartdata 1 ] "Jobid has no timing data" ] } {
          putscli "Chart for jobid $jobid not available, Jobid has no timing data"
          return
        } else {
          set query [ hdbjobs eval {SELECT COUNT(*) FROM JOBCHART WHERE JOBID=$jobid AND CHART="timing"} ]
          if { $query eq 0 } {
            #No result chart exists create one and insert into JOBCHART table
          } else {
            #Return existing results chart from JOBCHART table
            set html [ join [ hdbjobs eval {SELECT html FROM JOBCHART WHERE JOBID=$jobid AND CHART="timing"} ]]
            return $html
          }
          set dbdescription [ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]
          if { $dbdescription eq "MSSQLServer" } { set dbdescription "SQL Server" }
          set date [ join [ hdbjobs eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$jobid} ]]
          if { $tproch } {
            #CREATE TPROC-H timing chart
            foreach queryoutput $chartdata {
              if { [ string match "query*" $queryoutput ] } { 
                set numbers [regexp -all -inline -- {\d?\.?\d+} $queryoutput]
                if { [ string match "*completed*" $queryoutput ] } {
                  lassign $numbers querypos querytime
                  lappend xaxisvals $querypos
                  lappend barseries $querytime
                }
              }
            }
            #Create chart showing timing for each Query 
            set bar [ticklecharts::chart new]
            set ::ticklecharts::htmlstdout "True" ; 
            $bar SetOptions -title [ subst {text "$dbdescription TPROC-H Power Query Times $jobid @ $date"} ] -tooltip {show "True"} -legend {bottom "5%" left "45%"}
            $bar Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
            $bar Yaxis -name "Seconds" -position "left" -axisLabel {formatter "<0123>value<0125>"}
            $bar AddBarSeries -name "VU 1 Query Set" -data [list $barseries ]    
            set html [ $bar RenderX -title "$jobid Query Times" ]
            hdbjobs eval {INSERT INTO JOBCHART(jobid,chart,html) VALUES($jobid,'timing',$html)}
            return $html
          } else {
            #CREATE TPROC-C Timing chart
            #Create Xaxis and extract p50,p95, p99, avg
            foreach sp {NEWORD PAYMENT DELIVERY SLEV OSTAT} { 
              append xaxisvals \"$sp\"\ 
              set $sp\_rs [ dict filter [ dict get $chartdata $sp ] script {key value} { regexp {p50_ms|p95_ms|p99_ms|avg_ms} $key } ]
            }
            #Create series for each timing for each stored proc
            foreach rs {NEWORD_rs PAYMENT_rs DELIVERY_rs SLEV_rs OSTAT_rs} {
              foreach ms {p50_ms p95_ms p99_ms avg_ms} {
                append [ string toupper $ms ] \"[ dict get [ set $rs ] $ms ]\"\ 
              }
            }
            #Create chart showing timing for each stored proc
            set bar [ticklecharts::chart new]
            set ::ticklecharts::htmlstdout "True" ; 
            $bar SetOptions -title [ subst {text "$dbdescription TPROC-C Response Times $jobid @ $date"} ] -tooltip {show "True"} -legend {bottom "5%" left "30%"}
            $bar Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
            $bar Yaxis -name "Milliseconds" -position "left" -axisLabel {formatter "<0123>value<0125>"}
            $bar AddBarSeries -name P50_MS -data [list "$P50_MS "]    
            $bar AddBarSeries -name P95_MS -data [list "$P95_MS "]    
            $bar AddBarSeries -name P99_MS -data [list "$P99_MS "]    
            $bar AddBarSeries -name AVG_MS -data [list "$AVG_MS "]    
            set html [ $bar RenderX -title "$jobid Response Times" ]
            hdbjobs eval {INSERT INTO JOBCHART(jobid,chart,html) VALUES($jobid,'timing',$html)}
            return $html
          }
        }
      }
      "tcount" {
        set date [ join [ hdbjobs eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$jobid} ]]
        set chartdata [ getjobtcount $jobid ]
        if { [ llength $chartdata ] eq 2 && [ string match [ lindex $chartdata 1 ] "Jobid has no transaction counter data" ] } {
          putscli "Chart for jobid $jobid not available, Jobid has no transaction counter data"
          return
        } else {
          set query [ hdbjobs eval {SELECT COUNT(*) FROM JOBCHART WHERE JOBID=$jobid AND CHART="tcount"} ]
          if { $query eq 0 } {
            #No result chart exists create one and insert into JOBCHART table
          } else {
            #Return existing results chart from JOBCHART table
            set html [ join [ hdbjobs eval {SELECT html FROM JOBCHART WHERE JOBID=$jobid AND CHART="tcount"} ]]
            return $html
          }
          set dbdescription [ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]
          if { $dbdescription eq "MSSQLServer" } { set dbdescription "SQL Server" }
          set header [ dict keys $chartdata ]
          set xaxisvals [ dict values [ join [ dict values $chartdata ]]]
          set lineseries [ dict keys [ join [ dict values $chartdata ]]]
          set line [ticklecharts::chart new]
          set ::ticklecharts::htmlstdout "True" ; 
          $line SetOptions -title [ subst {text "$dbdescription TPROC-C Transaction Count $jobid @ $date"} ] -tooltip {show "True"} -legend {bottom "5%" left "40%"}
          $line Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
          $line Yaxis -name "TPM" -position "left" -axisLabel {formatter "<0123>value<0125>"}
          $line AddLineSeries -name [ join $header ] -data [ list $lineseries ]
          set html [ $line RenderX -title "$jobid Transaction Count" ]
          hdbjobs eval {INSERT INTO JOBCHART(jobid,chart,html) VALUES($jobid,'tcount',$html)}
          return $html
        }
      }
      default {
        set html "Error: chart type should be result, timing or tcount"
        return
      }
    }
  }

  proc getjob { query } {
    global bm
    upvar #0 genericdict genericdict
    if {[dict exists $genericdict commandline jobsoutput]} {
      set outputformat [ dict get $genericdict commandline jobsoutput ]
    } else {
      set outputformat "text"
    }

    set params [ split $query & ]
    set paramlen [ llength $params ]
    if { $paramlen eq 0 } {
      set joboutput [ hdbjobs eval {SELECT DISTINCT JOBID FROM JOBMAIN} ]
      set huddleobj [ huddle compile {list} $joboutput ]
      if { $outputformat eq "JSON" } {
        puts [ huddle jsondump $huddleobj ]
      } else {
        puts [ join $joboutput "\n" ]
      }
      return
    } else {
      if { $paramlen >= 1 && $paramlen <= 3 } {
        foreach a $params {
          lassign [split $a =] key value
          dict append paramdict $key $value
        }
      } else {
        puts "Error: Usage: \[ jobs | jobs format | jobs jobid | jobs jobid command | jobs jobid command option \] - type \"help jobs\""
        return
      }
      if { $paramlen eq 3 } {
        if { [ dict keys $paramdict ] != "jobid timing vu" && [ dict keys $paramdict ] != "jobid getchart chart" } {
          puts "Error: Jobs Three Parameter Usage: \[ jobs jobid timing vuid | jobs jobid getchart chart \]"
          return
        } else {
          if { [ dict keys $paramdict ] eq "jobid timing vu" } {
            set jobid [ dict get $paramdict jobid ]
            set vuid [ dict get $paramdict vu ]
            if [ string is entier $vuid ] {
              unset -nocomplain jobtiming
              set jobtiming [ dict create ]
              hdbjobs eval {SELECT procname,elapsed_ms,calls,min_ms,avg_ms,max_ms,total_ms,p99_ms,p95_ms,p50_ms,sd,ratio_pct FROM JOBTIMING WHERE JOBID=$jobid and VU=$vuid and SUMMARY=0 ORDER BY RATIO_PCT DESC}  {
                set timing "elapsed_ms $elapsed_ms calls $calls min_ms $min_ms avg_ms $avg_ms max_ms $max_ms total_ms $total_ms p99_ms $p99_ms p95_ms $p95_ms p50_ms $p50_ms sd $sd ratio_pct $ratio_pct"
                dict append jobtiming $procname $timing
              }
              if { ![ dict size $jobtiming ] eq 0 } {
                set huddleobj [ huddle compile {dict * dict} $jobtiming ]
                if { $outputformat eq "JSON" } {
                  return [ huddle jsondump $huddleobj ]
                } else {
                  return $jobtiming
                }
              } else {
                puts "No Timing Data for VU $vuid for JOB $jobid: jobs jobid timing vuid"
                return
              }
            } else {
              puts "Jobs Three Parameter Usage: jobs jobid timing vuid"
              return
            }
          } else {
            if { [ dict keys $paramdict ] eq "jobid getchart chart" } {
              set html [ getchart [ dict get $paramdict jobid ] 1 [ dict get $paramdict chart ] ]
              return $html
            } else {
              puts "Jobs Three Parameter Usage: jobs jobid getchart chart"
              return
            }
          }
        }
      }
    }
    if { $paramlen eq 1 } {
      if { [ dict keys $paramdict ] eq "joblist" } {
        return [ hdbjobs eval {SELECT DISTINCT JOBID FROM JOBMAIN} ]
      } elseif { [ dict keys $paramdict ] eq "jobid" } {
        set jobid [ dict get $paramdict jobid ]
        set query [ hdbjobs eval {SELECT COUNT(*) FROM JOBOUTPUT WHERE JOBID=$jobid} ]
        if { $query eq 0 } {
          puts "Jobid $jobid does not exist"
          return
        } else {
          set joboutput [ hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid} ]
          set huddleobj [ huddle compile {list} $joboutput ]
          if { $outputformat eq "JSON" } {
            puts [ huddle jsondump $huddleobj ]
          } else {
            set res ""
            set num 0
            foreach row $joboutput {
              if { $num == 0 } {
                set res "Virtual User $row:"
                incr num
              } else {
                set res "$res $row"
                puts $res
                set num 0
              }
            }
          }
        }
      } else {
        puts "Jobs One Parameter Usage: jobs jobid=TEXT"
        return
      }
    } else {
      if { [ dict keys $paramdict ] eq "jobid vu" || [ dict keys $paramdict ] eq "jobid status" || [ dict keys $paramdict ] eq "jobid result" || [ dict keys $paramdict ] eq "jobid delete" || [ dict keys $paramdict ] eq "jobid timestamp" || [ dict keys $paramdict ] eq "jobid dict" || [ dict keys $paramdict ] eq "jobid timing" || [ dict keys $paramdict ] eq "jobid db" ||  [ dict keys $paramdict ] eq "jobid bm" || [ dict keys $paramdict ] eq "jobid tcount" } {
        set jobid [ dict get $paramdict jobid ]
        if { [ dict keys $paramdict ] eq "jobid vu" } {
          set vuid [ dict get $paramdict vu ]
        } else {
          if { [ dict keys $paramdict ] eq "jobid result" } {
            set vuid 1
          } else {
            set vuid 0
          }
        }
        set query [ hdbjobs eval {SELECT COUNT(*) FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
        if { $query eq 0 } {
          puts "Jobid $jobid for virtual user $vuid does not exist"
          return
        } else {
          if { [ dict keys $paramdict ] eq "jobid vu" || [ dict keys $paramdict ] eq "jobid status" } {
            set joboutput [ hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid} ]
            set huddleobj [ huddle compile {list} $joboutput ]
            if { $outputformat eq "JSON" } {
              puts [ huddle jsondump $huddleobj ]
            } else {
              set res ""
              set num 0
              foreach row $joboutput {
                if { $num == 0 } {
                  set res "Virtual User $row:"
                  incr num
                } else {
                  set res "$res $row"
                  puts $res
                  set num 0
                }
              }
            }
            return
          }
          if { [ dict keys $paramdict ] eq "jobid delete" } {
            set joboutput [ hdbjobs eval {DELETE FROM JOBMAIN WHERE JOBID=$jobid} ]
            set joboutput [ hdbjobs eval {DELETE FROM JOBTIMING WHERE JOBID=$jobid} ]
            set joboutput [ hdbjobs eval {DELETE FROM JOBTCOUNT WHERE JOBID=$jobid} ]
            set joboutput [ hdbjobs eval {DELETE FROM JOBOUTPUT WHERE JOBID=$jobid} ]
            set joboutput [ hdbjobs eval {DELETE FROM JOBCHART WHERE JOBID=$jobid} ]
            puts "Deleted Jobid $jobid"
          } else {
            if { [ dict keys $paramdict ] eq "jobid result" } {
              set joboutput [ getjobresult $jobid $vuid ]
              #huddle JSON is list return at end
            } else {
              if { [ dict keys $paramdict ] eq "jobid timing" } {
                set jobtiming [ getjobtiming $jobid ]
                set huddleobj [ huddle compile {dict * dict} $jobtiming ]
                if { $outputformat eq "JSON" } {
                  puts [ huddle jsondump $huddleobj ]
                } else {
                  puts $jobtiming
                }
                return
              } else {
                if { [ dict keys $paramdict ] eq "jobid timestamp" } {
                  set joboutput [ hdbjobs eval {SELECT jobid, timestamp FROM JOBMAIN WHERE JOBID=$jobid} ]
                  #huddle JSON is dict*dict return here
                  set huddleobj [ huddle compile {dict * dict} $joboutput ]
                  if { $outputformat eq "JSON" } {
                    puts [ huddle jsondump $huddleobj ]
                  } else {
                    puts $joboutput
                  }
                  return
                } else {
                  if { [ dict keys $paramdict ] eq "jobid dict" } {
                    set joboutput [ join [ hdbjobs eval {SELECT jobdict FROM JOBMAIN WHERE JOBID=$jobid} ]]
                    #huddle JSON is dict*dict return here
                    set huddleobj [ huddle compile {dict * dict} $joboutput ]
                    if { $outputformat eq "JSON" } {
                      puts [ huddle jsondump $huddleobj ]
                    } else {
                      puts $joboutput
                    }
                    return
                  } else {
                    if { [ dict keys $paramdict ] eq "jobid tcount" } {
                      set jsondict [ getjobtcount $jobid ]
                      #huddle JSON is dict*dict return here
                      set huddleobj [ huddle compile {dict * dict} $jsondict ]
                      if { $outputformat eq "JSON" } {
                        puts [ huddle jsondump $huddleobj ]
                      } else {
                        puts $jsondict
                      }
                      return
                    } else {
                      if { [ dict keys $paramdict ] eq "jobid db" } {
                        set joboutput [ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]
                        #huddle JSON is list return at end
                      } else {
                        if { [ dict keys $paramdict ] eq "jobid bm" } {
                          set joboutput [ join [ hdbjobs eval {SELECT bm FROM JOBMAIN WHERE JOBID=$jobid} ]]
                          #huddle JSON is list return at end
                        } else {
                          set joboutput [ list $jobid "Cannot find Jobid output" ]
                          #huddle JSON is list return at end
                        }
                      }
                    }
                  }
                }
              }
            }
            #huddle list
            set huddleobj [ huddle compile {list} $joboutput ]
            if { $outputformat eq "JSON" } {
              puts [ huddle jsondump $huddleobj ]
            } else {
              puts [ join $joboutput "\n" ]
            }
          }
        }
      } else {
        puts "Jobs Two Parameter Usage: jobs jobid status or jobs jobid db or jobs jobid bm or jobs jobid timestamp or jobs jobid dict or jobs jobid vuid or jobs jobid result or jobs jobid timing or jobs jobid delete"
        return
      }
    }
  }
}
namespace import jobs::*
