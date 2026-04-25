package provide jobs 1.0
namespace eval jobs {
  namespace export init_job_tables_gui init_job_tables init_job_tables_ws jobmain jobs job hdbjobs jobs_ws job_disable job_disable_check job_format wapp-page-jobs wapp-page-logo.png wapp-page-logo-full.png wapp-page-tick.png wapp-page-cross.png wapp-page-star.png wapp-page-nostatus.png getjob savechart home-common-header common-header common-footer getdatabasefile
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
      set q [expr {round($q)}]
    }


    return "[commify $q] MB"
  }

  proc init_job_tables_gui { } {
    #rename jobs {}
    #uplevel #0 {proc hdbjobs { args } { return "" }}
    #If we want to fully disable jobs output in the GUI uncomment previous 2 lines and comment the following line
    init_job_tables
  }

  proc huddle_escape_double {huddleObj} {
    # huddleObj looks like: HUDDLE {L { {s ...} {s ...} ... } }
    set outerTag [lindex $huddleObj 0]
    set innerList [lindex $huddleObj 1]
    set tag [lindex $innerList 0]
    set pairs [lindex $innerList 1]

    set newPairs {}
    foreach pair $pairs {
        set sTag [lindex $pair 0]
        set str [lindex $pair 1]
        # Escape all internal double quotes
        regsub -all {\"} $str {\\"} escapedStr
        lappend newPairs [list $sTag $escapedStr]
    }

    # Rebuild the HUDDLE structure
    return [list $outerTag [list $tag $newPairs]]
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
      puts "Error initializing Jobs database : $message"
      return
    } else {
      catch {hdbjobs timeout 30000}
      #hdbjobs eval {PRAGMA foreign_keys=ON}
      if { $sqlite_db eq ":memory:" } {
        catch {hdbjobs eval {DROP TABLE JOBMAIN}}
        catch {hdbjobs eval {DROP TABLE JOBTIMING}}
        catch {hdbjobs eval {DROP TABLE JOBTCOUNT}}
        catch {hdbjobs eval {DROP TABLE JOBMETRIC}}
        catch {hdbjobs eval {DROP TABLE JOBSYSTEM}}
        catch {hdbjobs eval {DROP TABLE JOBOUTPUT}}
        catch {hdbjobs eval {DROP TABLE JOBCHART}}
        catch {hdbjobs eval {DROP TABLE JOBCI}}
        if [catch {hdbjobs eval {CREATE TABLE JOBMAIN(jobid TEXT primary key, db TEXT, bm TEXT, jobdict TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')),profile_id INTEGER NOT NULL DEFAULT 0)}} message ] {
          puts "Error creating JOBMAIN table in SQLite in-memory database : $message"
          return
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBTIMING(jobid TEXT, vu INTEGER, procname TEXT, calls INTEGER, min_ms REAL, avg_ms REAL, max_ms REAL, total_ms REAL, p99_ms REAL, p95_ms REAL, p75_ms REAL, p50_ms REAL, p25_ms REAL, sd REAL, ratio_pct REAL, summary INTEGER, elapsed_ms REAL, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBTIMING table in SQLite in-memory database : $message"
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBTCOUNT(jobid TEXT, counter INTEGER, metric TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBTCOUNT table in SQLite in-memory database : $message"
          return
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBMETRIC (jobid TEXT, usr REAL, sys REAL, irq REAL, idle REAL, iops REAL, mbps REAL, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBMETRIC table in SQLite in-memory database : $message"
          return
	      } elseif [ catch {hdbjobs eval {CREATE TABLE JOBSYSTEM (jobid TEXT primary key, hostname TEXT, cpumodel TEXT, cpucount INTEGER, system_vendor TEXT, system_type TEXT, os_name TEXT, memory TEXT, nic TEXT, storage TEXT, cloud_instance TEXT, other_software TEXT, extra TEXT, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBSYSTEM table in SQLite in-memory database : $message"
          return
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBOUTPUT(jobid TEXT, vu INTEGER, output TEXT, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBOUTPUT table in SQLite in-memory database : $message"
          return
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBCHART(jobid TEXT, chart TEXT, html TEXT, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBCHART table in SQLite in-memory database : $message"
          return
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBCI (ci_id INTEGER PRIMARY KEY AUTOINCREMENT, refname TEXT NOT NULL, dbprefix TEXT NOT NULL, pipeline TEXT NOT NULL DEFAULT 'TEST',  io_intensive INTEGER NOT NULL DEFAULT 0, profile_id INTEGER NULL, cidict TEXT, clone_cmd TEXT, clone_output TEXT, build_cmd TEXT, build_output TEXT, install_cmd TEXT, install_output TEXT, package_cmd TEXT, commit_msg TEXT, config_file TEXT, start_cmd TEXT, status TEXT NOT NULL DEFAULT 'PENDING', timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), end_timestamp DATETIME NULL)}} message ] {
          puts "Error creating JOBCI table in SQLite in-memory database : $message"
          return
        } else {
          catch {hdbjobs eval {CREATE INDEX JOBMAIN_IDX ON JOBMAIN(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBTIMING_IDX ON JOBTIMING(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBTCOUNT_IDX ON JOBTCOUNT(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBMETRIC_IDX ON JOBMETRIC(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBSYSTEM_IDX ON JOBSYSTEM(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBOUTPUT_IDX ON JOBOUTPUT(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBCHART_IDX ON JOBCHART(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBCI_REF_IDX ON JOBCI(refname)}}
          catch {hdbjobs eval {CREATE INDEX JOBCI_PROFILE_IDX ON JOBCI(profile_id)}}

          puts "Initialized new Jobs in-memory database"
        }
      } else {
        if [catch {set tblname [ hdbjobs eval {SELECT name FROM sqlite_master WHERE type='table' AND name='JOBMAIN'}]} message ] {
          puts "Error querying  JOBOUTPUT table in SQLite on-disk database : $message"
          return
        } else {
          if { $tblname eq "" } {
            if [catch {hdbjobs eval {CREATE TABLE JOBMAIN(jobid TEXT primary key, db TEXT, bm TEXT, jobdict TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')),profile_id INTEGER NOT NULL DEFAULT 0)}} message ] {
              puts "Error creating JOBMAIN table in SQLite on-disk database : $message"
              return
            } elseif [ catch {hdbjobs eval {CREATE TABLE JOBTIMING(jobid TEXT, vu INTEGER, procname TEXT, calls INTEGER, min_ms REAL, avg_ms REAL, max_ms REAL, total_ms REAL, p99_ms REAL, p95_ms REAL, p75_ms REAL, p50_ms REAL, p25_ms REAL, sd REAL, ratio_pct REAL, summary INTEGER, elapsed_ms REAL, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
              puts "Error creating JOBTIMING table in SQLite on-disk database : $message"
              return
            } elseif [ catch {hdbjobs eval {CREATE TABLE JOBTCOUNT(jobid TEXT, counter INTEGER, metric TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
              puts "Error creating JOBTCOUNT table in SQLite on-disk database : $message"
              return
            } elseif [ catch {hdbjobs eval {CREATE TABLE JOBMETRIC (jobid TEXT, usr REAL, sys REAL, irq REAL, idle REAL, iops REAL, mbps REAL, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
             puts "Error creating JOBMETRIC table in SQLite on-disk database : $message"
             return
	          } elseif [ catch {hdbjobs eval {CREATE TABLE JOBSYSTEM (jobid TEXT primary key, hostname TEXT, cpumodel TEXT, cpucount INTEGER, system_vendor TEXT, system_type TEXT, os_name TEXT, memory TEXT, nic TEXT, storage TEXT, cloud_instance TEXT, other_software TEXT, extra TEXT, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
              puts "Error creating JOBSYSTEM table in SQLite on-disk database : $message"
              return
            } elseif [catch {hdbjobs eval {CREATE TABLE JOBOUTPUT(jobid TEXT, vu INTEGER, output TEXT)}} message ] {
              puts "Error creating JOBOUTPUT table in SQLite on-disk database : $message"
              return
            } elseif [ catch {hdbjobs eval {CREATE TABLE JOBCHART(jobid TEXT, chart TEXT, html TEXT, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
              puts "Error creating JOBCHART table in SQLite on-disk database : $message"
              return
            } elseif [ catch {hdbjobs eval {CREATE TABLE JOBCI (ci_id INTEGER PRIMARY KEY AUTOINCREMENT, refname TEXT NOT NULL, dbprefix TEXT NOT NULL, pipeline TEXT NOT NULL DEFAULT 'TEST', io_intensive INTEGER NOT NULL DEFAULT 0, profile_id INTEGER NULL, cidict TEXT, clone_cmd TEXT, clone_output TEXT, build_cmd TEXT, build_output TEXT, install_cmd TEXT, install_output TEXT, package_cmd TEXT, commit_msg TEXT, config_file TEXT, start_cmd TEXT, status TEXT NOT NULL DEFAULT 'PENDING', timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), end_timestamp DATETIME NULL)}} message ] {
              puts "Error creating JOBCI table in SQLite on-disk database : $message"
              return
            } else {
              catch {hdbjobs eval {CREATE INDEX JOBMAIN_IDX ON JOBMAIN(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBTIMING_IDX ON JOBTIMING(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBTCOUNT_IDX ON JOBTCOUNT(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBMETRIC_IDX ON JOBMETRIC(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBSYSTEM_IDX ON JOBSYSTEM(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBOUTPUT_IDX ON JOBOUTPUT(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBCHART_IDX ON JOBCHART(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBCI_REF_IDX ON JOBCI(refname)}}
              catch {hdbjobs eval {CREATE INDEX JOBCI_PROFILE_IDX ON JOBCI(profile_id)}}
              puts "Initialized new Jobs on-disk database $sqlite_db"
            }
          } else {
            set size "[ commify [ hdbjobs eval {SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()} ]] bytes" 
            puts "Initialized Jobs on-disk database $sqlite_db using existing tables ($size)"
            if [catch {set chartname [ hdbjobs eval {SELECT name FROM sqlite_master WHERE type='table' AND name='JOBCHART'}]} message ] {
            puts "Error querying  JOBCHART table in SQLite on-disk database : $message"
	    return
		} else {
	  if { $chartname eq "" } {
          if [ catch {hdbjobs eval {CREATE TABLE JOBCHART(jobid TEXT, chart TEXT, html TEXT, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
              puts "Error upgrading database with Job Charts: $message"
              return
          } else {
              catch {hdbjobs eval {CREATE INDEX JOBCHART_IDX ON JOBCHART(jobid)}}
              puts "Upgraded database $sqlite_db with Job Charts"
		       }
		  }
	   #Upgrade existing JOBSYSTEM table with new system discovery columns if not present
           if { [catch {
               set colinfo [hdbjobs eval {PRAGMA table_info(JOBSYSTEM)}]
               set colnames [list]
               foreach {cid name type notnull dfltval pk} $colinfo {
                   lappend colnames $name
               }
               foreach newcol {system_vendor system_type os_name memory nic storage cloud_instance other_software extra} {
                   if { $newcol ni $colnames } {
                       hdbjobs eval "ALTER TABLE JOBSYSTEM ADD COLUMN $newcol TEXT"
                   }
               }
               if { "system_vendor" ni $colnames } {
                   puts "Upgraded database $sqlite_db JOBSYSTEM table with system discovery fields"
               }
           } message] } {
               puts "Error upgrading JOBSYSTEM table with system discovery fields: $message"
           }
           if { [catch {
               set metriccol_iops [hdbjobs eval {SELECT COUNT(*) FROM pragma_table_info('JOBMETRIC') WHERE name='iops'}]
               if { $metriccol_iops eq 0 } {
                   hdbjobs eval {ALTER TABLE JOBMETRIC ADD COLUMN iops REAL}
               }
               set metriccol_mbps [hdbjobs eval {SELECT COUNT(*) FROM pragma_table_info('JOBMETRIC') WHERE name='mbps'}]
               if { $metriccol_mbps eq 0 } {
                   hdbjobs eval {ALTER TABLE JOBMETRIC ADD COLUMN mbps REAL}
               }
           } message] } {
               puts "Error upgrading JOBMETRIC table with I/O fields: $message"
           }
	   }}}}
      tsv::set commandline sqldb $sqlite_db
    }
  }

  proc init_job_tables_ws { } {
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
        } 
      }
    } else {
      set sqlite_db ":memory:"
    }
    if [catch {sqlite3 hdbjobs $sqlite_db} message ] {} else {
      catch {hdbjobs timeout 30000}
      if [catch {set tblname [ hdbjobs eval {SELECT name FROM sqlite_master WHERE type='table' AND name='JOBMAIN'}]} message ] {
        puts "Error querying  JOBOUTPUT table in SQLite on-disk database : $message"
        return
      } elseif { $tblname eq "" } {
      if [catch {init_job_tables} message ] {
          puts "Error: Job tables not created:$message"
          exit
	  }
      } else {
         puts "Web Service using $sqlite_db database"
       }
    }
  }

proc _latest_workload_logname {} {
    set tmpdir [findtempdir]
    if {$tmpdir eq "notmpdir"} {
        return "nologfile"
    }

    # Match both default and unique workload logs:
    #   hammerdb.log
    #   hammerdb_<GUID>.log
    set logfiles [glob -nocomplain -types f -directory $tmpdir "hammerdb*.log"]
    set logfiles [lsearch -all -inline -not -glob $logfiles "*hammerdbci.log"]

    if {[llength $logfiles] == 0} {
        return "nologfile"
    }

    set newest "nologfile"
    set newest_mtime -1
    foreach f $logfiles {
        set mtime [file mtime $f]
        if {$mtime > $newest_mtime} {
            set newest_mtime $mtime
            set newest $f
        }
    }

    return $newest
}

proc jobmain { jobid jobtype } {
    global rdbms bm
    upvar #0 genericdict genericdict
    if [ job_disable_check ] { return 0 }

    set tmpdictforpt [ find_current_dict ]

    set ci_mode 0
    if {[dict exists $tmpdictforpt pipeline]} {
        set ci_mode 1
    } elseif {[dict exists $tmpdictforpt commandline pipeline]} {
        set ci_mode 1
    }

    if {$ci_mode} {
        set jobs_profile_id 0
        set pl ""
        if {[dict exists $tmpdictforpt pipeline]} {
            set pl [string tolower [dict get $tmpdictforpt pipeline]]
        } elseif {[dict exists $tmpdictforpt commandline pipeline]} {
            set pl [string tolower [dict get $tmpdictforpt commandline pipeline]]
        }

        if {$bm eq "TPC-C" && $pl eq "profile"} {
            if {[catch {set jobs_profile_id [dict get $genericdict commandline jobs_profile_id]}]} {
                set jobs_profile_id 0
            }
            # sanity clamp
            if {![string is integer -strict $jobs_profile_id] || $jobs_profile_id < 1000} {
                set jobs_profile_id 1000
            }
        }
    } else {
        if {$jobtype in {check build delete} || $bm != "TPC-C" } {
            set jobs_profile_id 0
        } else {
            if [catch {set jobs_profile_id [ dict get $genericdict commandline jobs_profile_id ]} message ] {
                set jobs_profile_id 0
            }
        }
    }

    set query [ hdbjobs eval {SELECT COUNT(*) FROM JOBMAIN WHERE JOBID=$jobid} ]
    if { $query eq 0 } {
        hdbjobs eval {INSERT INTO JOBMAIN(jobid,db,bm,jobdict,profile_id) VALUES($jobid,$rdbms,$bm,$tmpdictforpt,$jobs_profile_id)}
        return 0
    } else {
        return 1
    }
}

# Usage summary:
#   jobs
#   jobs result|timestamp|joblist|profileid
#   jobs <jobid>
#   jobs format <fmt>
#   jobs disable <0|1>
#   jobs profileid [<id>]
#   jobs profile <id>
#   jobs <jobid> <cmd>            (cmd may be integer vu -> vu=<n>)
#   jobs <jobid> timing <vuid|vu=<n>>
#   jobs <jobid> getchart <type>  (result|timing|tcount|metrics|profile|diff:<pid>)
#   jobs diff <basepid> <comppid> [true|false]

proc jobs {args} {
    upvar #0 genericdict genericdict

    # disabled
    if {[catch {set jobs_disabled [dict get $genericdict commandline jobs_disable]} msg]} {
        puts "Error: Detecting Jobs Enable/Disable: $msg"
    } else {
        # only allow jobs disable
        set tokens $args
        set first [expr {[llength $tokens] ? [lindex $tokens 0] : ""}]
        if {$jobs_disabled && ![string equal -nocase $first "disable"]} {
            puts "Error: Jobs Disabled: enable with command \"jobs disable 0\" and restart HammerDB"
            return
        }
    }

    # token list
    set tokens $args
    set nt [llength $tokens]

    proc ::_jobs_usage_error {msg} {
        puts $msg
        puts "Error: Usage: \[ jobs | jobs format <fmt> | jobs disable <0|1> | jobs jobid | jobs jobid <command> \[option\] | jobs jobid timing <vuid|vu=n> | jobs jobid getchart \[result|timing|tcount|metrics|profile|diff:pid\] | jobs profileid \[id\] | jobs profile <id> | jobs diff basepid comppid \[true|false\] \] - type \"help jobs\""
    }

    # 0 args
    if {$nt == 0} {
        return [getjob ""]
    }

    # diff
    set opt [lindex $tokens 0]
    if {[string equal -nocase $opt "diff"]} {
        if {$nt < 3 || $nt > 4} {
            ::_jobs_usage_error "Error: Usage: jobs diff basepid comppid \[true|false\]"
            return
        }
        set base_pid  [lindex $tokens 1]
        set comp_pid  [lindex $tokens 2]
        set weighting [expr {$nt == 4 ? [lindex $tokens 3] : "false"}]

        if {![string is boolean -strict $weighting]} {
            ::_jobs_usage_error "Error: Usage: jobs diff basepid comppid \[true|false\]"
            return
        }
        set ratio [jobs_profile_diff $base_pid $comp_pid $weighting]
        if {$ratio ne ""} {
            return $ratio
        } else {
            return "null"
        }
    }

    # route on first token
    # global commands
    switch -nocase -- $opt {
        result {
            if {$nt != 1} { ::_jobs_usage_error "Error: Usage: jobs result"; return }
            return [getjob "allresults"]
        }
        timestamp {
            if {$nt != 1} { ::_jobs_usage_error "Error: Usage: jobs timestamp"; return }
            return [getjob "alltimestamps"]
        }
        joblist {
            if {$nt != 1} { ::_jobs_usage_error "Error: Usage: jobs joblist"; return }
            return [getjob "joblist"]
        }
        profileid {
            # jobs profileid
            # jobs profileid <id>
            if {$nt == 1} {
                return [job_profile_id]
            } elseif {$nt == 2} {
                return [job_profile_id [lindex $tokens 1]]
            } else {
                ::_jobs_usage_error "Error: Usage: jobs profileid \[id\]"
                return
            }
        }
        format {
            if {$nt != 2} { ::_jobs_usage_error "Error: Usage: jobs format <fmt>"; return }
            return [job_format [lindex $tokens 1]]
        }
        disable {
            if {$nt != 2} { ::_jobs_usage_error "Error: Usage: jobs disable <0|1>"; return }
            return [job_disable [lindex $tokens 1]]
        }
        profile {
            if {$nt != 2} { ::_jobs_usage_error "Error: Usage: jobs profile <id>"; return }
            return [job_profile [lindex $tokens 1]]
        }
        default {
            # else jobid
        }
    }

    # jobid commands
    set jobid $opt

    # jobs <jobid>
    if {$nt == 1} {
        set res [getjob "jobid=$jobid"]
        puts $res
        return
    }

    # jobs <jobid> <cmd> [arg]
    set cmd [lindex $tokens 1]

# jobs <jobid> timing [vu]
if {[string equal -nocase $cmd "timing"]} {

    # 2 tokens
    if {$nt == 2} {
        set res [getjob "jobid=$jobid&timing"]
        puts $res
        return
    }

    # 3 tokens
    if {$nt == 3} {
        set vusel [lindex $tokens 2]
        if {[string is integer -strict $vusel]} { set vusel "vu=$vusel" }
        set res [getjob "jobid=$jobid&timing&$vusel"]
        puts $res
        return
    }

    ::_jobs_usage_error "Error: Usage: jobs jobid timing | jobs jobid timing vuid | jobs jobid timing vu=n"
    return
}

    # jobs <jobid> getchart
    if {[string equal -nocase $cmd "getchart"]} {
        if {$nt != 3} {
            ::_jobs_usage_error "Error: Usage: jobs jobid getchart \[result|timing|tcount|metrics|profile|diff:pid\]"
            return
        }
        set charttype [lindex $tokens 2]
        if {![string equal -nocase $charttype "result"]
            && ![string equal -nocase $charttype "timing"]
            && ![string equal -nocase $charttype "tcount"]
            && ![string equal -nocase $charttype "metrics"]
            && ![string equal -nocase $charttype "profile"]
            && ![string match -nocase "diff:*" $charttype]} {
            ::_jobs_usage_error "Error: Usage: jobs jobid getchart \[ result | timing | tcount | metrics | profile | diff:pid \]"
            return
        }
        set ctype "chart=$charttype"
        return [getjob "jobid=$jobid&getchart&$ctype"]
    }

    # jobs <jobid> <cmd>
    # integer cmd => vu
    if {$nt == 2} {
        if {[string is integer -strict $cmd]} { set cmd "vu=$cmd" }
        set res [getjob "jobid=$jobid&$cmd"]
        puts $res
        return
    }

    # jobs <jobid> <cmd> <arg>
    if {$nt == 3} {
        set arg [lindex $tokens 2]
        # integer arg => vu
        if {[string is integer -strict $arg]} { set arg "vu=$arg" }
        set res [getjob "jobid=$jobid&$cmd&$arg"]
        puts $res
        return
    }

    # too many args
    ::_jobs_usage_error "Error: Too many arguments to jobs"
    return
}

  proc old-jobs { args } {
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
    set tokens [split $args]
    set opt [expr {[llength $tokens] > 0 ? [lindex $tokens 0] : ""}]
    if {[llength $tokens] >= 1 && [string equal -nocase $opt "diff"]} {
        set argc [llength $tokens]
        if {$argc < 3 || $argc > 4} {
            puts "Error: Usage: jobs diff basepid comppid \[true|false\]"
            return
        }
        set base_pid  [lindex $tokens 1]
        set comp_pid  [lindex $tokens 2]
        set weighting [expr {$argc == 4 ? [lindex $tokens 3] : "false"}]
	if {![string is boolean -strict $weighting]} {
            puts "Error: Usage: jobs diff basepid comppid \[true|false\]"
            return
        }
        set ratio [jobs_profile_diff $base_pid $comp_pid $weighting]
        if {$ratio ne ""} { 
	return $ratio 
	} else {
        return "null"
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
          set res [ getjob "allresults" ]
        } elseif [ string equal $param "timestamp" ] {
          set res [ getjob "alltimestamps" ]
        } elseif [ string equal $param "joblist" ] {
          return [ getjob "joblist" ]
        } elseif [ string equal $param "profileid" ] {
          return [ job_profile_id ]
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
        } elseif { $jobid == "profileid" } {
          job_profile_id $cmd
        } elseif { $jobid == "profile" } {
          job_profile $cmd
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
          if { ![string equal $charttype "result" ] && ![string equal $charttype "timing" ] && ![string equal $charttype "tcount" ]  && ![string equal $charttype "metrics" ] && ![string equal $charttype "profile" ] && ![string match "diff:*" $charttype] } {
            puts "Error: Jobs Three Parameter Usage: jobs jobid getchart \[ result | timing | tcount | metrics | profile | diff:pid \]"
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
        puts "Error: Usage: \[ jobs | jobs format | jobs jobid | jobs jobid command | jobs jobid command option | jobs profileid | jobs profileid id | jobs profile id | jobs diff basepid comppid \[true|false\]\] - type \"help jobs\""
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
        set jobid $param
        set res [rest::get http://localhost:$ws_port/jobs?jobid=$jobid "" ]
        puts $res
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

  proc job_disable_check {} {
	if [catch {hdbjobs} message ] { 
	return false
	} else {
	return true
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

proc __auto_refresh_js {{ms 120000}} {
    set ms [string trim $ms]
    if {![string is integer -strict $ms] || $ms < 2000} { set ms 120000 }

    wapp-subst "<script>\n"
    wapp-subst "(function(){\n"
    wapp-subst "  var REFRESH_MS = $ms;\n"
    wapp-subst "  setInterval(function(){\n"
    wapp-subst "    var url = window.location.pathname + window.location.search + window.location.hash;\n"
    wapp-subst "    window.location.replace(url);\n"
    wapp-subst "  }, REFRESH_MS);\n"
    wapp-subst "})();\n"
    wapp-subst "</script>\n"
}

proc home-common-header {} {
    wapp-content-security-policy { default-src 'self'; style-src 'self' 'unsafe-inline' *; img-src * data:; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; }

    set B [wapp-param BASE_URL]
    set url "/style.css"
    set logoimg "$B/logo.png"
    set pipelines_url "$B/pipelines"

    wapp-subst {
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
<link href="%url($url)" rel="stylesheet">
<title>HammerDB Jobs</title>
}
__auto_refresh_js 120000
    wapp-subst {
</head>
<body>

<p style="margin:12px 16px 6px 16px;">
  <img src="%unsafe($logoimg)" width="55" height="60">
</p>

<div style="margin:0 16px 18px 16px; padding-bottom:8px; border-bottom:1px solid #ddd;">
  <div style="display:flex; justify-content:flex-start; align-items:center; gap:12px;">
    <h3 class="title" style="margin:0;">HammerDB Jobs</h3>
    <a href="%html($pipelines_url)"
       style="margin-top:2px;
              padding:6px 14px;
              border:1px solid #bbb;
              border-radius:4px;
              text-decoration:none;
              font-weight:500;">
     Pipelines
    </a>
  </div>
</div>
}
}

  proc common-header {} {
    wapp-content-security-policy { default-src 'self'; style-src 'self' 'unsafe-inline' *; img-src * data:; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; }
    set url "/style.css"
    set logoimg "[wapp-param BASE_URL]/logo.png"
    wapp-subst {
      <!DOCTYPE html>
      <html>
      <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="content-type" content="text/html; charset=UTF-8">
      <link href="%url($url)" rel="stylesheet">
      <title>HammerDB Jobs</title>
      </head>
      <body>
      <p><img src='%unsafe($logoimg)' width='55' height='60'></p>
    }
  }

  proc summary-header {jobid} {
    set logoimg "[wapp-param BASE_URL]/logo.png"
    set url "/style.css"
    wapp-subst {
      <!DOCTYPE html>
      <html>
      <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="content-type" content="text/html; charset=UTF-8">
      <link href="%url($url)" rel="stylesheet">
      <title>hdb_%html($jobid)</title>
      </head>
      <body>
      <p><img src='%unsafe($logoimg)' width='55' height='60'></p>
    }
  }

  proc main-footer {} {
    set B [wapp-param BASE_URL]
    set dbfile [ getdatabasefile ]
    set size "[ commify [ hdbjobs eval {SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()} ]]" 
    wapp-subst {<h3 class="title">ENV</h3>}
      wapp-subst {<table>\n}
      wapp-subst {<th>SQLite</th><th>Size (bytes)</th><th>Web Service</th>\n}
      wapp-subst {<tr><td>%html($dbfile)</td><td>%html($size)</td></td><td><a href='%html($B)/env'>Configuration</a></td></tr>\n}
      wapp-subst {</table>\n}
    wapp-trim {
      <br>
      </body>
      </html>
    }
  }

 proc common-footer {} {
    set B [wapp-param BASE_URL]
    wapp-subst { <a href='%html($B)/jobs'>Job Index</a><br> }
    wapp-trim {
      <br>
      </body>
      </html>
    }
  }

  proc wapp-page-tick.png {} {
    wapp-mimetype image/png
    wapp-cache-control max-age=3600
    wapp-unsafe [ binary decode base64 {
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwABZ/QAAWf0AWMpoScAAAGnSURBVDhPtdRPaxNRFIbx31QiVGrTulCh1K0L
Fy4FTcG4CF1UaBT8JkJ145+FFtSvoiIRkVBd2NiNn8CdZCeknWAoxmrGxWQmM9NEo+gDWdz33Ptw
Zubk8o8JikFKUxnrBioCZ4ZpW2TbvufqwsIJxgo/KOnYwE2B48XykC94LLTphm/ZQl7YsKjkhUAl
l0+mZdZVK/aSYCSMO3vzB7KEltCVpNOZNO7Y+AsZXDLvVrKIO2wqi7SZ+M6y/EAHJ9Mk0nPUsqow
7nCgPqWsb2BdyRI+pmlgzoG69JGne9Q+rlvV8NVZnC7UKzLvcDlf89l35/FwuI5lNS+9cs4RW5jP
nYjiWR19lCyRAyWf1NzGnTGyU8UjCYmwnUsDSyKvNZXV3J9S1pYKI9vFKi6k0t/LmIkd8dg8s+CY
tsBccR92MTv8jefQ2NSFAo+K+4ac+KUs5olqfFmMPkpoU+R9dtdURHZ0PUiW+cvhnUX7GgIXc/kk
Ijsia1btJlF+bFbs6arirkgvV8vTE7in63JW5lCHWd5a0HdNoCIYDn78f2858NTa6Mr6r/wEzJFz
C8GtSUkAAAAASUVORK5CYII=
    }]
  }

  proc wapp-page-cross.png {} {
    wapp-mimetype image/png
    wapp-cache-control max-age=3600
    wapp-unsafe [ binary decode base64 {
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAACxMAAAsTAQCanBgAAAH6SURBVDhPrZVBTxNhEIaf+XZRpAFiwBgt0TR6
8U49YRtbTXqURNT/QMKBEi6QNHCUcCHpfxA51OMeLEkb9dL+BBOikV48EMBiQbrjYWm7fG2sEJ7T
fvPOvNmZfDsr9GAnmRwcdxovBZ1WmET0LoCo1IAqyoef/o2tWKnUsGvFDhymJ1+DrAsStbUwiu6C
ZoeL1c1wvG2oOUz9U3wDZDac0B/NR6Yqc7KCD2Ba4cuZAchsUHt24qxNwbw7l3dBFP/NcLG6KTvJ
5OC4e/S138z6oehuZGDsgbllfs/0MnNX13AXlsFxOkHHwV1Yxl1dC6cCIEi0frI3YxBe2CIAB/uY
dAZ3MReYOg7uYg6TzsDBvp0NgKDT8iv1+BvCPVtsGyRS+OVtgPbz6dsVaDbtClT5Lofp+B9BXFuE
86bAP80I5njavjZXhSH4nLqxWvbL25hEqjPTXqjUnKVY9AnCI1tzs0uYp8/bbfqfS8jEfUwihdy+
g/+lbJcAFI0iBTsKwMgoftHrzKzZDIyLHoyM2tlnSOHKLjboj6GBsYcmVio1HGHeli+KEbLG844N
wNDHynvQvJ30/2g+8Ahtm8hUZe5ypsH6ap26FuzRs/grX1kHmbC1MIruOsJ8681adBkC+JnM9frJ
3gzoNKFfACo1gaoihci1m1vG847t2r87XMAQUQqvWAAAAABJRU5ErkJggg==
    }]
  }

  proc wapp-page-nostatus.png {} {
    wapp-mimetype image/png
    wapp-cache-control max-age=3600
    wapp-unsafe [ binary decode base64 {
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAJUSURBVDhPvZTNS1RhFMZ/586MX43DOBrRLiQl
DKOFSBARVLgIXAW1FIIEaeF/kOY+ZhVFQUjtoqiNEVhIQdGiIr8WBUHt/MCKQJw7933PaTFzR+eq
QRQ9cHi55z7neZ9zDvfCP4YkE0mYIe4DJwHSR3khgiU5fwQ/x6TOYv69mH+bmky+T+K3DnWW0wjP
8ILF4TiTOe6fJ7kxgmQihs2QRiiigqlANUSlODNDOsmPsbtggWGM3igKuDd9iLvT3bgowDToPSGN
w0l+jB0FdYGCwYSp8Gp+P7emurgx1cnL+b2ggjomfjzNFZJ17CZonnExaUeFTOCIojJRFJIRX209
aG82N56sYydBXaAHkxHzAl4o7ClRdiFRFNKeDTEFVDDPSOlJtidZv00QTxEljYKp0JGtuCtHZTqy
UcWhB1FJS0gxWV4nqPMMojIQbxSFfIvD+xDVEoUWD35z66YyUHrQOrhVoyZoCzSYl2tbyKBCAORb
1sk3lwisTqxyuuCa3adhu6BnFKWrjqyVOY6dX+XqhTWozi8RXRth22isIwA6xz5z8gmVXPxV4ALM
C1+Wcly+08dGaZ2bQ4sc7AgxH1Rad5ULzfGzyWW6g0sry0HFnYxhktvqKt7mu895Vr6HLH8r8eZj
Y9U9mK9uWwUsyJXQK7WWTelHq87qhg6nepbpO7DEsc41zh5Zhyqn0i61MajSvzlDlUdUb0xGvslx
fegrty+u0NZsm67qTkB5XJuhGeJep86JTx02b6IagAPi0wUkc/Gz+ZSpl8XWkdWHwl/+K/8LfgF7
51H30c40eAAAAABJRU5ErkJggg==
    }]
  }

  proc wapp-page-star.png {} {
    wapp-mimetype image/png
    wapp-cache-control max-age=3600
    wapp-unsafe [ binary decode base64 {
iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAARnQU1BAACx
jwv8YQUAAAAJcEhZcwAADsQAAA7EAZUrDhsAAAHwSURBVDhP5ZNBS1RRGIaf90z3Xq6jDEJYERFU
C6kgbZM7NSOinyG1aeVC3I7uhaCgXfQzBAsaBS1FsoikRS4igmgWjjYzMjPe87W4zjReonDts3y/
53znfIdz4MShbJDFNihYNZoFkDXmNE4l63TjskEWq0VFiSmJKVNUzNazOL8czvhSVPel8JVfJc4K
WDY4il8l9kvhS1+K6n45nHF4zUrEkiY4CCe6ZdsgQDbUlQzZBkG3Qyu8LXRHIsZr1iFb6RS9Htjr
nrMAZsiq4ROh8XZZ0phVw6dm6d37N/kzmB521stW5FeJaYXzQo8O411g0eCKYLgjd2GwKfgC3AUK
aWbPCJrT6U7L0T0ZC9mFx8HM7rux5oIjHWUrKxwX5dwn2u/QDNlStCvR98cIIBeDC4HcYZiAb0Ky
D9bqqGb80mijIGGdh+1L4Vud6r1FfBFy/dBoQaMGrQb4JJVcDoIIojxEASQ7sP8VS2prbrQxQvdP
8WuXn8tdmOT7Z9j9Cebbpb8jB4UBOD+IJd9euJHtSY78lPz1deoV2Cv/vxmkzl4ZahXoubbejjsn
NCs623o/zUFzSnvlc1R3/j1ybz/Wd/oHQfRYV4fmpTl/pGEbs6Lj44dhc/4m0iWMAbB82lA1JVa2
HNuSe8fgjc12oxPMb5bIwls9AintAAAAAElFTkSuQmCC
    }]
  }

  proc wapp-page-logo.png {} {
  #uses width 55, height 60
    wapp-mimetype image/png
    wapp-cache-control max-age=3600
    wapp-unsafe [ binary decode base64 {
      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
      XmHAAAAAAElFTkSuQmCC
    }]
  }

  proc wapp-page-logo-full.png {} {
  #uses width 347, height 60
    wapp-mimetype image/png
    wapp-cache-control max-age=3600
    wapp-unsafe [ binary decode base64 {
      R0lGODlhtgJ4AOf7AAchTgAjVgAjXAMlUQwiVwUlYwInWgQoYQUqUQ4pSwArYhkmSwkqVwAt
      WQoqXgAtYAAsagAtZgArfRMrSQsqcQwrZQAvZwAucwAwYwAvbg8rawAwaA8tWxAtYQIyXxEt
      ZwQxagMyZBEvXRAwWAAzagQ0WwAzcQA0bAYzZhMyVQgzbAA1cwgzdAA2bgA3aQw0bhk0Shgy
      ZwA4dws3ZA42agE6cxc4YBQ4chM5bB83Zh88XyU7WhY+ch4+aSlAWSlHcy5IZyxIbS9ShTdU
      dzpWgUNVfENZckBafVNZiUhiiEFkiUdkhFBhiT9llU9jhE5lgWJqiFZwmFlxhlJyolxzkmF/
      pm2AlWaBoG5/n4WDh3SLq3eLo36Kr2+QuomRmY2RoIOTsn6Ws4aVp4KWrYebsXOf0viMEf+M
      BIidu5Obs4WexP+OAPCRD/SPHvWQEu+RHPKPKP+NF/+MJfuPI/6SB/2RGPqQLPmTF/SVFvKU
      KpCjue2WKfmTJPyVCPSVIu+XIeqXMv+THPGYFeuZIPiULfWUN/iYB+2aFPyVG+uZK+mZPuee
      HvWcCfmZG/+YHumeLZaqwfycKuihN6Gqw+uhRJGu1fahNJmuzfWiPOinR62vrJ+yyfKnVO+p
      X/upT6q3wv+pW6a4z/GxQ/uvUvGyUqW93+62XO+2Y/mzaP2zX67A1vG4bfDAgfm/gsbHyrbL
      5LHM6+LEqrrL3snJxsHJ3sLK0r7L2f7DcMDL5v3Eer7O4f/GmPzJivzLlfnQkPzRgvfQn/3P
      oerUqcDZ+/rTmsra8P7Rstnb2NHd6v/ZrP3ZzP7etv7grvbhvd3l7ufk6f7hxe7k2tzn9erm
      193m/v/jwNfp/v/lzv7ovP7pxvzp4P/p2P3s0/vvyt3z/+Xx//zu2/L08Ob4/+32//v08/32
      2vT1//f1+fL3+vz0///37//2/fr58P765Pj69//5+Or//vb8/v36//L///v9+vX/+v/8+/r/
      7fj/9P/+7v/+9P/9//n///z/+///9v7//CH+EUNyZWF0ZWQgd2l0aCBHSU1QACwAAAAAtgJ4
      AAAI/gD/CRxIsKDBgwgTKlzIsKHDhxAjSpxIsaLFixgzatzIsaPHjyBDihxJsqTJkyhTqlzJ
      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
      gAAAOw==
    }]
  }

  proc string_occurrences {needleString haystackString} {
    set j [string first $needleString $haystackString 0]
    if {$j == -1} {return 0}
    set i 0
    while {$j != -1 } {
      set j [string first $needleString $haystackString [incr j]]
      incr i
    }
    return $i
  }

  proc _tail_log_file {filename {maxbytes 65536}} {
      if {$filename eq "" || $filename eq "nologfile" || ![file exists $filename] || ![file readable $filename]} {
          return "No active workload log"
      }

      set fsize [file size $filename]
      if {$fsize < 0} {
          return "No active workload log"
      }

      set fh [open $filename r]
      fconfigure $fh -translation binary -encoding iso8859-1

      if {$fsize > $maxbytes} {
          seek $fh [expr {$fsize - $maxbytes}] start
      }

      set data [read $fh]
      close $fh

      return [encoding convertfrom utf-8 $data]
  }

proc wapp-page-jobs {} {
    global bm hdb_version

    proc __norm_pre {s} {
        # normalise newlines
        regsub -all {\r\n} $s "\n" s
        regsub -all {\r}   $s "\n" s
        return $s
    }

    proc __fmt_job_output {s} {
        # format VU0
        set s [__norm_pre $s]
        if {[string first "\n" $s] < 0} {
            if {[string match "*User *:*" $s]} {
                # split User N:
                regsub -all { ?User ([0-9]+):} $s "\nUser \\1:" s
                set s [string trim $s]
                # split final marker
                regsub -all { ?ALL VIRTUAL USERS COMPLETE} $s "\nALL VIRTUAL USERS COMPLETE" s
            }
        }
        return $s
    }

    proc __is_true {v} {
        set v [string tolower [string trim $v]]
        expr {$v eq "1" || $v eq "true" || $v eq "yes" || $v eq "on"}
    }

    proc __pre_block {s} {
        # truncate large output
        set max 2000000
        set total [string length $s]
        if {$total > $max} {
            wapp-subst "<p><i>Showing first %html($max) bytes of %html($total).</i></p>\n"
            set s [string range $s 0 [expr {$max-1}]]
        }
	wapp-unsafe "<pre style=\"white-space:pre-wrap; overflow-wrap:anywhere;\">$s</pre>\n"
    }

    proc __job_exists {jobid} {
        expr {[hdbjobs eval {SELECT COUNT(*) FROM JOBMAIN WHERE JOBID=$jobid}] > 0}
    }

    proc __job_field_link {B jobid name label} {
        set url "$B/jobs?jobid=$jobid&$name"
        wapp-subst "<li><a href='%html($url)'>%html($label)</a></li>\n"
    }

    set B [wapp-param BASE_URL]
    set query  [wapp-param QUERY_STRING]
    set params [split $query &]
    set paramlen [llength $params]

    set paramdict [dict create]
    if {$paramlen >= 1 && $query ne ""} {
        foreach a $params {
            if {$a eq ""} continue
            lassign [split $a =] key value
            if {$key eq "diff"} {
                dict lappend paramdict $key $value
            } else {
                dict set paramdict $key $value
            }
        }
    }

    if {[dict exists $paramdict tailworkload] && [dict get $paramdict tailworkload] eq "1"} {
        set logfile [_latest_workload_logname]
        set logtxt [_tail_log_file $logfile 65536]

        wapp-mimetype "text/plain; charset=utf-8"
        wapp-unsafe $logtxt
        return
    }

    set rawmode 0
    if {[dict exists $paramdict raw]} {
        set rawmode [__is_true [dict get $paramdict raw]]
    }

    if {$paramlen eq 0 || $query eq ""} {
        set topjobs [gettopjobs]
        home-common-header
        wapp-subst {<h3 class="title">TPROC-C</h3>}
        wapp-trim {<div class='hammerdb' data-title='TPROC-C'>}

        set tprocccombined {}
        set tprochcombined {}

        wapp-subst {<table>\n}
        wapp-subst {<th>Jobid</th><th>Database</th><th>Date</th><th>Workload</th><th>NOPM</th><th>Status</th>\n}

        foreach job [ lreverse [getjob joblist] ] {
            set nopm "--"
            set geo  "--"
            set url  "$B/jobs?jobid=$job&index"
            set db   [join [hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$job}]]
            set bm   [string map {TPC TPROC} [join [hdbjobs eval {SELECT bm FROM JOBMAIN WHERE JOBID=$job}]]]
            set date [join [hdbjobs eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$job}]]

            set output  [join [hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$job AND VU=0}]]
            set output1 [join [hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$job AND VU=1}]]

            if {[string match -nocase "*creating*" $output1]} {
                set jobtype "Schema Build"
            } elseif {[string match -nocase "*delete*" $output1]} {
                set jobtype "Schema Delete"
            } elseif {[string match -nocase "*checking*" $output1]} {
                set jobtype "Schema Check"
            } elseif {[string match -nocase "*rampup*" $output1] || [string match -nocase "*scale factor*" $output1]} {
                set jobtype "Benchmark Run"

                # add version if present in VU1 output
                if {[string match "*DBVersion*" $output1]} {
                    set matcheddbversion [regexp {(DBVersion:)(\d.+?)\s} $output1 match header version]
                    if {$matcheddbversion} { set db "$db ($version)" }
                }

                set jobresult [getjobresult $job 1]
                if {![llength $jobresult] eq 2 || ![string match [lindex $jobresult 1] "Jobid has no test result"]} {
                    if {$bm eq "TPROC-C"} {
                        lassign [getnopmtpm $jobresult] jobid tstamp activevu nopm tpm dbdescription
                    } else {
                        set ctind 0
                        foreach ct {jobid tstamp geomean queryset} {
                            set $ct [lindex $jobresult $ctind]
                            incr ctind
                        }
                        set numbers [regexp -all -inline -- {[0-9]*\.?[0-9]+} $geomean]
                        set geo [format "%.2f" [lindex $numbers 1]]
                    }
                }
            } else {
                set jobtype "--"
            }

            # status icon
            set statusimg ""
            if {[string match "*ALL VIRTUAL USERS COMPLETE*" $output]} {
                if {[string match "*FINISHED FAILED*" $output]} {
                    set statusimg "<img src='$B/cross.png'>"
                } else {
                    if {[llength [string_occurrences ":RUNNING" $output]] eq [llength [string_occurrences ":FINISHED SUCCESS" $output]]} {
                        set statusimg "<img src='$B/tick.png'>"
                        if {[dict values $topjobs $job] eq $job} {
                            set statusimg "<img src='$B/star.png'>"
                        }
                    }
                }
            } else {
                if {[string match "*FINISHED FAILED*" $output]} {
                    set statusimg "<img src='$B/cross.png'>"
                } else {
                    set output_vu1 [join [hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$job AND VU=1}]]
                    if {[string match "*TEST RESULT*" $output_vu1]} {
                        if {[dict values $topjobs $job] eq $job} {
                            set statusimg "<img src='$B/star.png'>"
                        } else {
                            set statusimg "<img src='$B/tick.png'>"
                        }
                    } else {
                        set statusimg "<img src='$B/nostatus.png'>"
                    }
                }
            }

            if {$bm eq "TPROC-C"} {
                append tprocccombined [subst {<tr><td><a href='%html($url)'>%html($job)</a></td><td>%html($db)</td><td>%html($date)</td><td>%html($jobtype)</td><td>%html($nopm)</td><td class='status'>%unsafe($statusimg)</td></tr>\n}]
            } else {
                append tprochcombined [subst {<tr><td><a href='%html($url)'>%html($job)</a></td><td>%html($db)</td><td>%html($date)</td><td>%html($jobtype)</td><td>%html($geo)</td><td class='status'>%unsafe($statusimg)</td></tr>\n}]
            }
        }

        wapp-subst $tprocccombined
        if {$tprocccombined eq {}} {
            wapp-subst {<tr><td colspan="6">No TPROC-C runs found in database file %html([getdatabasefile])</td></tr>\n}
        }
        wapp-subst {</table>\n}

        # Profiles table
        set profcount 0
        if {![info exists ::profile_dbdesc]} {
            set ::profile_dbdesc [dict create]
        }
        wapp-subst {<h3 class="title">TPROC-C Performance Profiles</h3>}
        wapp-subst {<p style="margin:0 0 6px 0; opacity:0.75;">Select one <b>Base</b> profile and one <b>New</b> profile, click <b>Compare Profiles</b> to compare.</p>}
        wapp-subst {<form method="GET" action="%html([wapp-param BASE_URL]/jobs)">}
        wapp-subst {<input type="hidden" name="cmd" value="profilediff">}
        wapp-subst {<div style="display:inline-block; max-width:100%;">}
        wapp-subst {<div style="overflow-x:auto;">}
        wapp-subst {<table style="width:100%; font-size:0.92em;">\n}
        wapp-subst {<tr><th>Profile ID</th><th>Jobs</th><th>Database</th><th>Max Job</th><th>Max NOPM</th><th>Max TPM</th><th>Max AVU</th><th>Base</th><th>New</th></tr>\n}

        set profileids [lreverse [join [hdbjobs eval {select distinct(profile_id) from jobmain where profile_id > 0 order by profile_id asc}]]]
        foreach profileid $profileids {
            set url "$B/jobs?profileid=$profileid"
            set profiles [get_job_profile $profileid]
            if {![huddle isHuddle $profiles] || [huddle llength $profiles] eq 0} {
                continue
            }
            incr profcount
            set profdict [huddle get_stripped $profiles]
            set maxnopm -1
            set maxjob ""
            set maxdb  ""
            set maxtpm ""
            set maxavu ""
            dict for {job profiledata} $profdict {
                set jobcount [dict size $profdict]
                dict for {k v} $profiledata {
                    if {$k eq "nopm"} {
                        if {$v > $maxnopm} {
                            set maxjob $job
                            set maxnopm $v
                            set maxdb [dict get $profiledata db]
                            set temp_db [join [hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$maxjob AND VU=1}]]
                            if {[string match "*DBVersion*" $temp_db]} {
                                set matcheddbversion [regexp {(DBVersion:)(\d.+?)\s} $temp_db match header version]
                                if {$matcheddbversion} { set maxdb "$maxdb ($version)" }
                            }
                            set maxtpm [dict get $profiledata tpm]
                            set maxavu [dict get $profiledata activevu]
                        }
                    }
                }
            }
            if {$maxdb ne ""} {
                dict set ::profile_dbdesc $profileid $maxdb
            }
            set maxurl "$B/jobs?jobid=$maxjob&index"
            wapp-subst {<tr><td><a href='%html($url)'>%html(Profile $profileid)</a></td><td>%html($jobcount)</td><td style="white-space:nowrap;">%html($maxdb)</td><td><a href='%html($maxurl)'>%html($maxjob)</a></td><td>%html($maxnopm)</td><td>%html($maxtpm)</td><td>%html($maxavu)</td><td style="text-align:center;"><input type="radio" name="base_pid" value="%html($profileid)"></td><td style="text-align:center;"><input type="radio" name="new_pid" value="%html($profileid)"></td></tr>\n}
        }

        if {$profcount eq 0} {
            wapp-subst {<tr><td colspan="9">No performance profiles found in database file %html([getdatabasefile])</td></tr>\n}
        }
        wapp-subst {</table>\n}
        wapp-subst {</div>}
        wapp-subst {<div style="margin-top:6px; text-align:right;"><button type="submit" style="padding:4px 10px;">Compare Profiles</button></div>}
        wapp-subst {</div></form>\n}

        # TPROC-H
        wapp-subst {<h3 class="title">TPROC-H</h3>}
        wapp-trim {<div class='hammerdb' data-title='TPROC-H'>}
        wapp-subst {<table>\n}
        wapp-subst {<th>Jobid</th><th>Database</th><th>Date</th><th>Workload</th><th>Geomean</th><th>Status</th>\n}
        wapp-subst $tprochcombined
        if {$tprochcombined eq {}} {
            wapp-subst {<tr><td colspan="6">No TPROC-H jobs found in database file %html([getdatabasefile])</td></tr>\n}
        }
        wapp-subst {</table>\n}
        # Benchmark Activity
        wapp-subst {
        <div style="margin:18px 0 20px 0; max-width:800px; border-radius:6px; background:#eef6ff; border:1px solid #d0d7de;">
          <details id="workload-log-panel">
            <summary style="cursor:pointer; padding:10px 14px; font-weight:600; color:#0a3d62; border-left:4px solid #0969da;">
              Benchmark Activity
            </summary>

            <div style="padding:12px;">
              <pre id="workload-log-box"
                   style="margin:0;
                          padding:12px;
                          height:320px;
                          overflow:auto;
                          background:#eef6ff;
                          color:#0a3d62;
                          border:1px solid #d0d7de;
                          border-radius:6px;
                          font-family:monospace;
                          font-size:13px;
                          line-height:1.35;
                          white-space:pre-wrap;">
              </pre>
            </div>

          </details>
        </div>
        }

        wapp-subst "<script>
        (function () {

          const panel = document.getElementById('workload-log-panel');
          const box = document.getElementById('workload-log-box');

          let timer = null;

          async function refreshWorkloadLog() {
            try {
              const res = await fetch('/jobs?tailworkload=1', {cache:'no-store'});
              const txt = await res.text();

              box.textContent = txt;
              box.scrollTop = box.scrollHeight;

            } catch(e) {
              box.textContent = 'Unable to load workload log';
            }
          }

          panel.addEventListener('toggle', function () {

            if (panel.open) {

                refreshWorkloadLog();
                timer = setInterval(refreshWorkloadLog, 3000);

            } else {

                if (timer) {
                    clearInterval(timer);
                    timer = null;
                }

            }

          });

        })();
        </script>"
        main-footer
        return
    }

    if {[dict exists $paramdict cmd] && [dict get $paramdict cmd] eq "profilediff"} {
        if {![dict exists $paramdict base_pid] || ![dict exists $paramdict new_pid]} {
            common-header
            wapp-subst {<p style="color:#b00; font-weight:600;">Please select one Base profile and one New profile to compare.</p>}
            common-footer
            return
        }
        set base_pid [dict get $paramdict base_pid]
        set new_pid [dict get $paramdict new_pid]
        if {![string is integer -strict $base_pid] || ![string is integer -strict $new_pid]} {
            common-header
            wapp-subst {<p style="color:#b00; font-weight:600;">Invalid profile selection.</p>}
            common-footer
            return
        }
        if {$base_pid == $new_pid} {
            common-header
            wapp-subst {<p style="color:#b00; font-weight:600;">Base and New profiles must be different.</p>}
            common-footer
            return
        }
        set chart [jobs $base_pid getchart diff:$new_pid]
        wapp-content-security-policy { default-src 'self'; style-src 'self' 'unsafe-inline' *; img-src * data:; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; }
        wapp-subst {<link href="%url(/style.css)" rel="stylesheet">}
        set d ""
        foreach l [split $chart \n] {
            if {[string match "*Compare summary*" $l]} {
                set d "<div style=\"margin:10px 0 10px 60px; padding:8px 12px; background:transparent; color:inherit; border-left:4px solid #d0d7de; font-weight:600; max-width:900px;\">$l</div>"
                continue
            }
            if {[string equal [string trim $l] "<body>"]} {
                set l "\t<body>\n\t<p><img src='$B/logo.png' width='55' height='60'></p>\n\t$d"
            }
            wapp-subst {%unsafe($l)\n}
        }
        common-footer
        return
    }

    if {[dict exists $paramdict jobid] && [dict exists $paramdict index]} {
        set jobid [dict get $paramdict jobid]
        if {![__job_exists $jobid]} {
            dict set jsondict error message "Jobid $jobid does not exist"
            wapp-2-json 2 $jsondict
            return
        }

        common-header
        wapp-subst "<h3 class='title'>Job:%html($jobid)</h3>\n"
        wapp-trim {<div class='hammerdb' data-title='Jobs Index'>}
        wapp-subst {<div><ol style='column-width: 20ex;'>\n}

        # summary link
        set jobresult [getjobresult $jobid 1]
        if {![llength $jobresult] eq 2 || ![string match [lindex $jobresult 1] "Jobid has no test result"]} {
            set url "$B/jobs?jobid=$jobid&summary"
            wapp-subst "<li><a href='%html($url)'>%html(summary)</a></li>\n"
        }

        # output (human readable default)
        set url "$B/jobs?jobid=$jobid"
        wapp-subst "<li><a href='%html($url)'>%html(output)</a></li>\n"

        foreach option "bm db dict result status tcount system metrics timestamp timing delete" {
            set url "$B/jobs?jobid=$jobid&$option"
            switch $option {
                bm       { wapp-subst "<li><a href='%html($url)'>%html(benchmark)</a></li>\n" }
                db       { wapp-subst "<li><a href='%html($url)'>%html(database)</a></li>\n" }
                dict     { wapp-subst "<li><a href='%html($url)'>%html(dict configuration)</a></li>\n" }
                result {
                    set jr [getjobresult $jobid 1]
                    if {![llength $jr] eq 2 || ![string match [lindex $jr 1] "Jobid has no test result"]} {
                        wapp-subst "<li><a href='%html($url)'>%html(result)</a></li>\n"
                    }
                }
                tcount {
                    set jt [getjobtcount $jobid]
                    if {![llength $jt] eq 2 || ![string match [lindex $jt 1] "Jobid has no transaction counter data"]} {
                        wapp-subst "<li><a href='%html($url)'>%html(transaction count)</a></li>\n"
                    }
                }
                system {
                    set js [getjobsystem $jobid]
                    if {![llength $js] eq 2 || ![string match [lindex $js 1] "Jobid has no system data"]} {
                        wapp-subst "<li><a href='%html($url)'>%html(system)</a></li>\n"
                    }
                }
                metrics {
                    set jm [getjobmetrics $jobid]
                    if {![llength $jm] eq 2 || ![string match [lindex $jm 1] "Jobid has no metric data"]} {
                        wapp-subst "<li><a href='%html($url)'>%html(metrics)</a></li>\n"
                    }
                }
                timing {
                    set jr [getjobresult $jobid 1]
                    if {[string match "Geometric*" [lindex $jr 2]]} {
                        wapp-subst "<li><a href='%html($url)'>%html(response times)</a></li>\n"
                    } else {
                        set jt [getjobtiming $jobid]
                        if {![llength $jt] eq 2 || ![string match [lindex $jt 1] "Jobid has no timing data"]} {
                            wapp-subst "<li><a href='%html($url)'>%html(response times)</a></li>\n"
                        }
                    }
                }
                default { wapp-subst "<li><a href='%html($url)'>%html($option)</a></li>\n" }
            }
        }

        wapp-subst {</ol></div>\n}
        common-footer
        return
    }

    proc strip_jobid_ts {chart} {
        regsub {[ ]+[0-9A-F]{16,}} $chart {} chart
        return $chart
    }


    if {[dict exists $paramdict jobid] && [dict exists $paramdict summary]} {
        set jobid [dict get $paramdict jobid]
        summary-header $jobid

        set jobresult [getjobresult $jobid 1]
        set db [join [hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid}]]
        set bm [string map {TPC TPROC} [join [hdbjobs eval {SELECT bm FROM JOBMAIN WHERE JOBID=$jobid}]]]

        if {$bm eq "TPROC-C"} {
            if {[llength $jobresult] eq 2 && [string match [lindex $jobresult 1] "Jobid has no test result"]} { return }
            lassign [getnopmtpm $jobresult] jobid tstamp activevu nopm tpm dbdescription
            set avu [regexp -all -inline -- {[0-9]*\.?[0-9]+} $activevu]
            set dbversion [get_dbversion $jobid]
            set jobsystem [getjobsystem $jobid]

            wapp-subst {<h3 class="title">Job %html($jobid) %html($bm) Summary %html($tstamp)</h3>}
            wapp-trim {<div class='hammerdb' data-title='Jobs Summary'>}

            wapp-subst {<table style="font-size: 150%;">\n}
            wapp-subst {<th>HDB</th><th>Database</th><th>Release</th><th>Benchmark</th><th>NOPM</th><th>TPM</th><th>Active VU</th>\n}
            wapp-subst {<tr><td>%html($hdb_version)</td><td>%html($db)</td><td>%html($dbversion)</td><td>%html($bm)</td><td>%html($nopm)</td><td>%html($tpm)</td><td>%html($avu)</td></tr>\n}
            wapp-subst {</table>\n}

            if {![llength $jobsystem] eq 2 || ![string match [lindex $jobsystem 1] "Jobid has no system data"]} {
                wapp-subst {<h3 class="title">System</h3>\n}
                wapp-subst {<table>\n}
                foreach field {hostname cpumodel cpucount system_vendor system_type os_name memory nic storage cloud_instance other_software extra} {
                    if {[dict exists $jobsystem $field]} {
                        set label [string map {_ { }} $field]
                        set value [dict get $jobsystem $field]
                        if {$value ne ""} {
                            wapp-subst {<tr><th>%html($label)</th><td>%html($value)</td></tr>\n}
                        }
                    }
                }
                wapp-subst {</table>\n}
            }

            wapp-content-security-policy { default-src 'self'; style-src 'self' 'unsafe-inline' *; img-src * data:; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; }
            foreach l [split [strip_jobid_ts [getchart $jobid 1 "result"]] \n] { wapp-subst {%unsafe($l)\n} }

            set jobtcount [getjobtcount $jobid]
            if {![llength $jobtcount] eq 2 || ![string match [lindex $jobtcount 1] "Jobid has no transaction counter data"]} {
                foreach l [split [strip_jobid_ts [getchart $jobid 1 "tcount"]] \n] { wapp-subst {%unsafe($l)\n} }
            }

            set jobtiming [getjobtiming $jobid]
            if {![llength $jobtiming] eq 2 || ![string match [lindex $jobtiming 1] "Jobid has no timing data"]} {
                foreach l [split [strip_jobid_ts [getchart $jobid 1 "timing"]] \n] { wapp-subst {%unsafe($l)\n} }
            }

            set jobmetrics [getjobmetrics $jobid]
            if {![llength $jobmetrics] eq 2 || ![string match [lindex $jobmetrics 1] "Jobid has no metric data"]} {
                foreach l [split [strip_jobid_ts [getchart $jobid 1 "metrics"]] \n] { wapp-subst {%unsafe($l)\n} }
            }
        } else {
            if {[llength $jobresult] eq 2 && [string match [lindex $jobresult 1] "Jobid has no test result"]} { return }
            set ctind 0
            foreach ct {jobid tstamp geomean queryset} {
                set $ct [lindex $jobresult $ctind]
                incr ctind
            }
            set numbers [regexp -all -inline -- {[0-9]*\.?[0-9]+} $geomean]
            set geo [format "%.2f" [lindex $numbers 1]]
            regsub -all "Completed " $queryset "" queryset
            regsub -all "query set" $queryset "qset" queryset
            regsub -all "seconds" $queryset "secs" queryset

            set dbversion [get_dbversion $jobid]
            set jobsystem [getjobsystem $jobid]

            wapp-subst {<h3 class="title">Job %html($jobid) %html($bm) Summary %html($tstamp)</h3>}
            wapp-trim {<div class='hammerdb' data-title='Jobs Summary'>}

            wapp-subst {<table style="font-size: 150%;">\n}
            wapp-subst {<th>HDB</th><th>Database</th><th>Release</th><th>Benchmark</th><th>Geomean</th><th>Query Time</th>\n}
            wapp-subst {<tr><td>%html($hdb_version)</td><td>%html($db)</td><td>%html($dbversion)</td><td>%html($bm)</td><td>%html($geo)</td><td>%html($queryset)</td></tr>\n}
            wapp-subst {</table>\n}

            if {![llength $jobsystem] eq 2 || ![string match [lindex $jobsystem 1] "Jobid has no system data"]} {
                wapp-subst {<h3 class="title">System</h3>\n}
                wapp-subst {<table>\n}
                foreach field {hostname cpumodel cpucount system_vendor system_type os_name memory nic storage cloud_instance other_software extra} {
                    if {[dict exists $jobsystem $field]} {
                        set label [string map {_ { }} $field]
                        set value [dict get $jobsystem $field]
                        if {$value ne ""} {
                            wapp-subst {<tr><th>%html($label)</th><td>%html($value)</td></tr>\n}
                        }
                    }
                }
                wapp-subst {</table>\n}
            }

            wapp-content-security-policy { default-src 'self'; style-src 'self' 'unsafe-inline' *; img-src * data:; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; }
            foreach l [split [getchart $jobid 1 "result"] \n] { wapp-subst {%unsafe($l)\n} }

            if {[string match "Geometric*" [lindex $jobresult 2]]} {
                foreach l [split [getchart $jobid 1 "timing"] \n] { wapp-subst {%unsafe($l)\n} }
            }

            set jobmetrics [getjobmetrics $jobid]
            if {![llength $jobmetrics] eq 2 || ![string match [lindex $jobmetrics 1] "Jobid has no metric data"]} {
                foreach l [split [getchart $jobid 1 "metrics"] \n] { wapp-subst {%unsafe($l)\n} }
            }
        }

        common-footer
        return
    }

    if {[dict exists $paramdict profileid] && ![dict exists $paramdict jobid]} {
        set profileid [dict get $paramdict profileid]

        if {[dict exists $paramdict profiledata]} {
            # profiledata is JSON
            set huddleobj [huddle_escape_double [get_job_profile $profileid]]
            wapp-mimetype application/json
            wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
            return
        }

        wapp-content-security-policy { default-src 'self'; style-src 'self' 'unsafe-inline' *; img-src * data:; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; }
        wapp-subst {<link href="%url(/style.css)" rel="stylesheet">}
        foreach l [split [getchart $profileid 0 "profile"] \n] {
            if {[string equal [string trim $l] "<body>"]} {
                set l "\t<body>\n\t<p><img src='$B/logo.png' width='55' height='60'></p>"
            }
            wapp-subst {%unsafe($l)\n}
        }
        set url "$B/jobs?profileid=$profileid&profiledata"
        wapp-subst "<a href='%html($url)'>%html(Profile Data)</a><br>\n"
        common-footer
        return
    }

    if {![dict exists $paramdict jobid]} {
        dict set jsondict error message "Usage: /jobs or jobs?jobid=JOBID or jobs?profileid=ID"
        wapp-2-json 2 $jsondict
        return
    }

    set jobid [dict get $paramdict jobid]
    if {![__job_exists $jobid]} {
        dict set jsondict error message "Jobid $jobid does not exist"
        wapp-2-json 2 $jsondict
        return
    }

if {$rawmode} {

    # JSON escape
    proc __json_escape {s} {
        set s [__norm_pre $s]
        set s [string map {\\ \\\\ \" \\\" \n \\n \t \\t} $s]
        return $s
    }

    # section
    set section "output"
    foreach s {bm db dict status system timestamp} {
        if {[dict exists $paramdict $s]} { set section $s; break }
    }

    # OUTPUT as-is
    if {$section eq "output"} {
        set joboutput [hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid}]
        set huddleobj [huddle_escape_double [huddle compile {list} $joboutput]]
        wapp-mimetype application/json
        wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
        return
    }

    # Otherwise: fetch raw value for the requested section
    set v ""
    switch $section {
        bm {
            set v [join [hdbjobs eval {SELECT bm FROM JOBMAIN WHERE JOBID=$jobid}]]
            set v [string map {TPC TPROC} $v]
        }
        db {
            set v [join [hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid}]]
        }
        dict {
            set v [join [hdbjobs eval {SELECT jobdict FROM JOBMAIN WHERE JOBID=$jobid}]]
        }
        status {
            set v [join [hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=0}]]
        }
       system {
       set js [getjobsystem $jobid]
       set v "No system data available"
       if {![dict exists $js message]} {
           set lines {}
           foreach field {jobid hostname cpumodel cpucount system_vendor system_type os_name memory nic storage cloud_instance other_software extra} {
               if {[dict exists $js $field]} {
                   set val [dict get $js $field]
                   if {$val ne ""} {
                       lappend lines "$field: $val"
                   }
               }
           }
           if {[llength $lines] > 0} {
               set v [join $lines "\n"]
           }
        }
      } 
        timestamp {
            set v [join [hdbjobs eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$jobid}]]
        }
        default {
            set v ""
        }
    }

    # Emit strict JSON with string values (no dict auto-detection)
    set j_jobid   [__json_escape $jobid]
    set j_section [__json_escape $section]
    set j_value   [__json_escape $v]

    set json "{\"jobid\":\"$j_jobid\",\"section\":\"$j_section\",\"value\":\"$j_value\"}"

    wapp-mimetype application/json
    wapp-trim $json
    return
}


    # Default (jobid only): show the same content as Raw JSON but human-readable
    # grouped by VU
    if {[llength [dict keys $paramdict]] eq 1} {
        common-header
        wapp-subst "<h3 class='title'>Job:%html($jobid)</h3>\n"
        set back "$B/jobs?jobid=$jobid&index"
        set raw  "$B/jobs?jobid=$jobid&raw=1"
        wapp-subst "<p><a href='%html($back)'>Back</a> | <a href='%html($raw)'>Raw</a></p>\n"

        # same rows as raw JSON
        set rows [hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid}]
        if {[llength $rows] < 2} {
            wapp-subst "<h4>Output</h4>\n"
            __pre_block "(empty)"
            common-footer
            return
        }

        # group by VU
        set vudict [dict create]
        for {set i 0} {$i < [llength $rows]} {incr i 2} {
            set vu  [lindex $rows $i]
            set out [lindex $rows [expr {$i+1}]]
            dict lappend vudict $vu $out
        }

        wapp-subst "<h4>Output</h4>\n"

        # numeric VU order
        set vu_keys [lsort -integer [dict keys $vudict]]
        foreach vu $vu_keys {
            set outlist [dict get $vudict $vu]
            set text [join $outlist "\n"]
            if {$vu == 0} {
                set text [__fmt_job_output $text]
            } else {
                set text [__norm_pre $text]
            }
            wapp-subst "<h5>VU %html($vu)</h5>\n"
            __pre_block $text
        }

        common-footer
        return
    }

    # vu=N readable output
    if {[dict exists $paramdict vu]} {
        set vuid [dict get $paramdict vu]
        if {![string is integer -strict $vuid]} {
            dict set jsondict error message "Usage: jobs?jobid=JOBID&vu=INTEGER"
            wapp-2-json 2 $jsondict
            return
        }
        common-header
        wapp-subst "<h3 class='title'>Job:%html($jobid)</h3>\n"
        set back "$B/jobs?jobid=$jobid&index"
        set raw  "$B/jobs?jobid=$jobid&raw=1"
        wapp-subst "<p><a href='%html($back)'>Back</a> | <a href='%html($raw)'>Raw</a></p>\n"
        set out [join [hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid}]]
        if {$vuid == 0} { set out [__fmt_job_output $out] } else { set out [__norm_pre $out] }
        wapp-subst "<h4>Output (VU %html($vuid))</h4>\n"
        __pre_block $out
        common-footer
        return
    }

    # readable fields
    # keep Raw JSON link
    set keys [dict keys $paramdict]

    # delete stays JSON
    if {[dict exists $paramdict delete]} {
        common-header
        wapp-trim {<div class='hammerdb' data-title='Job Delete'>}
        wapp-subst {<div><ol style='column-width: 20ex;'>\n}
        set url "$B/jobs?jobid=$jobid&DELETE"
        wapp-subst "<li><a href='%html($url)'>%html(Confirm Delete Job $jobid)</a></li>\n"
        wapp-subst {</ol></div>\n}
        common-footer
        return
    }
    if {[dict exists $paramdict DELETE]} {
        set date [join [hdbjobs eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$jobid}]]
        set current_time [clock format [clock seconds] -format "%y-%m-%d %H:%M:%S"]
        set job_age_hrs [expr {([clock scan $current_time] - [clock scan $date]) / 3600}]
        set jobstatus [hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=0}]
        if {[string match "*ALL VIRTUAL USERS COMPLETE*" $jobstatus] || $job_age_hrs > 24} {
            hdbjobs eval {DELETE FROM JOBMAIN   WHERE JOBID=$jobid}
            hdbjobs eval {DELETE FROM JOBTIMING WHERE JOBID=$jobid}
            hdbjobs eval {DELETE FROM JOBTCOUNT WHERE JOBID=$jobid}
            hdbjobs eval {DELETE FROM JOBMETRIC WHERE JOBID=$jobid}
            hdbjobs eval {DELETE FROM JOBSYSTEM WHERE JOBID=$jobid}
            hdbjobs eval {DELETE FROM JOBOUTPUT WHERE JOBID=$jobid}
            hdbjobs eval {DELETE FROM JOBCHART  WHERE JOBID=$jobid}
            dict set jsondict success message "Deleted Jobid $jobid"
            global discardedjobs
            unset -nocomplain discardedjobs
            wapp-2-json 2 $jsondict
        } else {
            dict set jsondict error message "Cannot delete Jobid $jobid from $date did not complete and ran less than 24 hours ago"
            wapp-2-json 2 $jsondict
        }
        return
    }

    # render readable fields
    foreach {k label} {
        bm        "Benchmark"
        db        "Database"
        dict      "Dict configuration"
        status    "Status"
        system    "System"
        timestamp "Timestamp"
    } {
        if {[dict exists $paramdict $k]} {
            common-header
            wapp-subst "<h3 class='title'>Job:%html($jobid)</h3>\n"
            set back "$B/jobs?jobid=$jobid&index"
            set raw  "$B/jobs?jobid=$jobid&$k&raw=1"
            wapp-subst "<p><a href='%html($back)'>Back</a> | <a href='%html($raw)'>Raw</a></p>\n"
            wapp-subst "<h4>%html($label)</h4>\n"

            switch $k {
                bm {
                    set v [join [hdbjobs eval {SELECT bm FROM JOBMAIN WHERE JOBID=$jobid}]]
                    set v [string map {TPC TPROC} $v]
                    __pre_block $v
                }
                db {
                    set temp_output [join [hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=1}]]
                    set dbv [join [hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid}]]

                    if {[string match "*DBVersion*" $temp_output]} {
                        set matcheddbversion [regexp {(DBVersion:)(\d.+?)\s} $temp_output match header version]
                        if {$matcheddbversion} { set dbv "$dbv ($version)" }
                    }
                    __pre_block $dbv
                }
                dict {
                     set v [join [hdbjobs eval {SELECT jobdict FROM JOBMAIN WHERE JOBID=$jobid}]]
                     set v [__norm_pre $v]
                     if {[info commands is-dict] ne ""} {
                         if {[is-dict $v]} { set v [pretty_tcl_dict $v] }
                     } else {
                         if {![catch {dict size $v}]} { set v [pretty_tcl_dict $v] }
                     }
                     __pre_block $v
                }
                status {
                    set v [join [hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=0}]]
                        # break before User/Vuser
                        regsub -all { ?(User [0-9]+:)}  $v "\n\\1" v
                        regsub -all { ?(Vuser [0-9]+:)} $v "\n\\1" v
                        regsub -all { ?(ALL VIRTUAL USERS COMPLETE)} $v "\n\\1" v
                        set v [string trim $v]
                    __pre_block $v
                }
                system {
                    set js [getjobsystem $jobid]
                    set v "No system data available"
                    if {![dict exists $js message]} {
                        set lines {}
                        foreach field {jobid hostname cpumodel cpucount system_vendor system_type os_name memory nic storage cloud_instance other_software extra} {
                            if {[dict exists $js $field]} {
                                set val [dict get $js $field]
                                if {$val ne ""} {
                                    lappend lines "$field: $val"
                                }
                            }
                        }
                        if {[llength $lines] > 0} {
                            set v [join $lines "\n"]
                        }
                    }
                    __pre_block $v
                }
                timestamp {
                    set ts [join [hdbjobs eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$jobid}]]
                    __pre_block $ts
                }
            }

            common-footer
            return
        }
    }

    # existing chart/data endpoints
    # result/tcount/metrics/timing unchanged
    if {[dict exists $paramdict result]} {
        wapp-content-security-policy { default-src 'self'; style-src 'self' 'unsafe-inline' *; img-src * data:; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; }
        wapp-subst {<link href="%url(/style.css)" rel="stylesheet">}
        foreach l [split [getchart $jobid 1 "result"] \n] {
            if {[string equal [string trim $l] "<body>"]} {
                set l "\t<body>\n\t<p><img src='$B/logo.png' width='55' height='60'></p>"
            }
            wapp-subst {%unsafe($l)\n}
        }
        set url "$B/jobs?jobid=$jobid&resultdata"
        wapp-subst "<a href='%html($url)'>%html(Result Data)</a><br>\n"
        common-footer
        return
    }

    if {[dict exists $paramdict timing]} {
        wapp-content-security-policy { default-src 'self'; style-src 'self' 'unsafe-inline' *; img-src * data:; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; }
        wapp-subst {<link href="%url(/style.css)" rel="stylesheet">}
        foreach l [split [getchart $jobid 1 "timing"] \n] {
            if {[string equal [string trim $l] "<body>"]} {
                set l "\t<body>\n\t<p><img src='$B/logo.png' width='55' height='60'></p>"
            }
            wapp-subst {%unsafe($l)\n}
        }
        set url "$B/jobs?jobid=$jobid&timingdata"
        wapp-subst "<a href='%html($url)'>%html(Timing Data)</a><br>\n"
        common-footer
        return
    }

    if {[dict exists $paramdict tcount]} {
        wapp-content-security-policy { default-src 'self'; style-src 'self' 'unsafe-inline' *; img-src * data:; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; }
        wapp-subst {<link href="%url(/style.css)" rel="stylesheet">}
        foreach l [split [getchart $jobid 1 "tcount"] \n] {
            if {[string equal [string trim $l] "<body>"]} {
                set l "\t<body>\n\t<p><img src='$B/logo.png' width='55' height='60'></p>"
            }
            wapp-subst {%unsafe($l)\n}
        }
        set url "$B/jobs?jobid=$jobid&tcountdata"
        wapp-subst "<a href='%html($url)'>%html(Transaction Count Data)</a><br>\n"
        common-footer
        return
    }

    if {[dict exists $paramdict metrics]} {
        wapp-content-security-policy { default-src 'self'; style-src 'self' 'unsafe-inline' *; img-src * data:; script-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; }
        wapp-subst {<link href="%url(/style.css)" rel="stylesheet">}
        foreach l [split [getchart $jobid 1 "metrics"] \n] {
            if {[string equal [string trim $l] "<body>"]} {
                set l "\t<body>\n\t<p><img src='$B/logo.png' width='55' height='60'></p>"
            }
            wapp-subst {%unsafe($l)\n}
        }
        set url "$B/jobs?jobid=$jobid&metricsdata"
        wapp-subst "<a href='%html($url)'>%html(Metrics Data)</a><br>\n"
        common-footer
        return
    }

    if {[dict exists $paramdict resultdata]} {
        set joboutput [getjobresult $jobid 1]
        wapp-2-json 2 $joboutput
        return
    }

    if {[dict exists $paramdict timingdata]} {
        set jobresult [getjobresult $jobid 1]
        if {[string match "Geometric*" [lindex $jobresult 2]]} {
            set jobtiming [hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=1}]
            set huddleobj [huddle_escape_double [huddle compile {list} $jobtiming]]
            wapp-mimetype application/json
            wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
        } else {
            set jobtiming [getjobtiming $jobid]
            wapp-2-json 2 $jobtiming
        }
        return
    }

    if {[dict exists $paramdict tcountdata]} {
        set jsondict [getjobtcount $jobid]
        wapp-2-json 2 $jsondict
        return
    }

    if {[dict exists $paramdict metricsdata]} {
        set jsondict [getjobmetrics $jobid]
        wapp-2-json 2 $jsondict
        return
    }

    # 3-param timing JSON
    if {[dict exists $paramdict timing] && [dict exists $paramdict vu] && [dict exists $paramdict jobid]} {
        # else JSON fallback
        dict set jsondict error message "Usage: jobs?jobid=JOBID&timing or jobs?jobid=JOBID&vu=VUID"
        wapp-2-json 2 $jsondict
        return
    }

    # usage
    dict set jsondict error message "Usage: /jobs | jobs?jobid=JOBID | jobs?jobid=JOBID&index | jobs?jobid=JOBID&summary | jobs?jobid=JOBID&bm|db|dict|status|system|timestamp | add &raw=1 for JSON"
    wapp-2-json 2 $jsondict
    return
}

  proc getdatabasefile {} {
    set dbfile [ join [ hdbjobs eval {select file from pragma_database_list where name='main'} ] ]
    return $dbfile
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
      if { [ string match "*Active Sessions*" $joboutput ] } {
      set activevu [ lsearch -glob -inline $joboutput "*Active Sessions*" ]
	} else {
      set activevu [ lsearch -glob -inline $joboutput "*Active Virtual Users*" ]
        }
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
    hdbjobs eval {SELECT procname,elapsed_ms,calls,min_ms,avg_ms,max_ms,total_ms,p99_ms,p95_ms,p75_ms,p50_ms,p25_ms,sd,ratio_pct FROM JOBTIMING WHERE JOBID=$jobid and SUMMARY=1 ORDER BY RATIO_PCT DESC}  {
    set timing "elapsed_ms $elapsed_ms calls $calls min_ms $min_ms avg_ms $avg_ms max_ms $max_ms total_ms $total_ms p99_ms $p99_ms p95_ms $p95_ms p75_ms $p75_ms p50_ms $p50_ms p25_ms $p25_ms sd $sd ratio_pct $ratio_pct"
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
    set joboutput [ hdbjobs eval {select JOBTCOUNT.timestamp, counter from JOBTCOUNT WHERE JOBTCOUNT.JOBID=$jobid order by JOBTCOUNT.timestamp asc} ]
    dict append jobtcount $jobheader $joboutput
    if { $jobheader eq "" && $joboutput eq "" } {
      set jobtcount [ list $jobid "Jobid has no transaction counter data" ]
    }
    return $jobtcount
  }

  proc getjobmetrics { jobid } {
    set jobmetric [ dict create ]
    hdbjobs eval {select JOBMETRIC.timestamp, usr, sys, irq, idle, coalesce(iops,0) as iops, coalesce(mbps,0) as mbps from JOBMETRIC WHERE JOBMETRIC.JOBID=$jobid order by JOBMETRIC.timestamp asc} {
    set metrics "usr% $usr sys% $sys irq% $irq idle% $idle iops $iops mbps $mbps" 
	if { [dict keys $jobmetric $timestamp] eq {} } {
    	dict append jobmetric $timestamp $metrics
		}
	}
    if { $jobmetric eq "" } {
      set jobmetric [ list $jobid "Jobid has no metric data" ]
    }
    return $jobmetric
  }

   proc get_dbversion { jobid } {
   set dbversion ""
   set output1 [join [hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=1}]]
   if {[string match "*DBVersion*" $output1]} {
      set matcheddbversion [regexp {(DBVersion:)(\d.+?)\s} $output1 match header version]
      if {$matcheddbversion} { set dbversion $version }
   }
   return $dbversion
  }

  proc filter_storage_display { os_name storage_text } {
   if {$storage_text eq ""} {
      return ""
   }

   if {![regexp -nocase {linux|ubuntu|debian|rhel|red hat|centos|suse} $os_name]} {
      return $storage_text
   }

   set out {}
   foreach dev [split $storage_text ";"] {
      set dev [string trim $dev]
      if {$dev eq ""} continue

      # Remove loop devices explicitly
      if {[string match {loop*} $dev]} continue

      # Remove tiny / useless devices
      if {[string first "(0 GB)" $dev] != -1} continue
      if {[string first "(1 GB)" $dev] != -1} continue

      lappend out $dev
   }

   return [join $out "; "]
  }

   proc getjobsystem { jobid } {
   set jobsystem [dict create]

   hdbjobs eval {SELECT * FROM JOBSYSTEM WHERE JOBID=$jobid} row {
      foreach col $row(*) {
         if {$col eq "*"} continue
         set val $row($col)
         if {$val eq ""} continue
         dict set jobsystem $col $val
      }
   }

   if {[dict size $jobsystem] == 0} {
      return [dict create jobid $jobid message "Jobid has no system data"]
   }

   if {[dict exists $jobsystem storage]} {
      set os_name ""
      if {[dict exists $jobsystem os_name]} {
         set os_name [dict get $jobsystem os_name]
      }
      dict set jobsystem storage [filter_storage_display $os_name [dict get $jobsystem storage]]
   }

   return $jobsystem
  }

  proc getnopmtpm { jobresult } {
  #Returns NOPM, TPM and database description from result string
	set ctind 0
        foreach ct {jobid tstamp activevu result} {
          set $ct [ lindex $jobresult $ctind ]
          incr ctind
        }
        set splitresult [ split $result ]
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
	return [ list $jobid $tstamp $activevu $nopm $tpm $dbdescription ]
 }

  proc gettopjobs {} {
    #Get the top TPROC-C and TPROC-H jobs. Maintain a list of results that are not top so search is quicker
    #If a job is deleted the discarded job list is reset in case the top job was deleted
    global discardedjobs
    if { ![info exists discardedjobs] } { set discardedjobs [list] }
    set topscores [ list nopm 0 geo 2147483648.0 ]
    set topjobs [ list tprocc 0 tproch 0 ]
    set joblist [ getjob joblist ]
    set lastjob [ lindex $joblist end ]
    foreach jobid $joblist {
      if { [ lsearch $discardedjobs $jobid ] != -1  } {
        continue
      }
      set jobresult [ getjobresult $jobid 1 ]
      if { [ lindex $jobresult 1 ] eq "Jobid has no test result" } {
	if { $jobid != $lastjob } {
        lappend discardedjobs $jobid
		}
        continue
      } elseif { [ string match "Geometric*" [ lindex $jobresult 2 ] ] } {
        set ctind 0
        foreach ct {jobid tstamp geomean queryset} { 
          set $ct [ lindex $jobresult $ctind ] 
          incr ctind
        }
        set numbers [regexp -all -inline -- {[0-9]*\.?[0-9]+} $geomean]
        set geo [ lindex $numbers 1]
        if { $geo < [ dict get $topscores geo ] } {
          set previous [ dict get $topjobs tproch ]
          if { $previous != 0 } { 
            lappend discardedjobs $previous
          }
          dict set topjobs tproch $jobid
          dict set topscores geo $geo
        }
      } elseif { [ string match "TEST RESULT*" [ lindex $jobresult 3 ] ] } {
        lassign [ getnopmtpm $jobresult ] jobid tstamp activevu nopm tpm dbdescription
        if { $nopm > [ dict get $topscores nopm ] } {
          set previous [ dict get $topjobs tprocc ]
          if { $previous != 0 } { 
            lappend discardedjobs $previous
          }
          dict set topjobs tprocc $jobid
          dict set topscores nopm $nopm
        }
      } else {
	if { $jobid != $lastjob } {
        lappend discardedjobs $jobid
		}
        continue
      }
    }
    return $topjobs
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
    set chartcolors [ list MariaDB { color1 "#42ADB6" color2 "#9fd7dc" } PostgreSQL { color1 "#062671" color2 "#457af5" } \
	Db2 { color1 "#00CC00" color2 "#66ff66" } MSSQLServer { color1 "#FFFF00" color2 "#ffff80" } \
	Oracle { color1 "#D00000" color2 "#ff6868" } MySQL {color1 "#FF7900" color2 "#ffbc80" } ]
    set color1 "#808080"
    set color2 "#bfbfbf"
    switch -glob $chart {
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
            foreach colour {color1 color2} {set $colour [ dict get $chartcolors $dbdescription $colour ]}
            if { $dbdescription eq "MSSQLServer" } { set dbdescription "SQL Server" }
            set qsetcount [ llength [regexp -all -inline (?=Geometric) $chartdata] ]
            #Create chart and insert into JOBCHART for future retrieval
            set ctind 0
            foreach ct {jobid tstamp geomean queryset} { 
              set $ct [ lindex $chartdata  $ctind ] 
              incr ctind
            }
            #geomean and queryset may have multiple entries
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
            $bar SetOptions -title [ subst {text "$dbdescription TPROC-H Result $jobid"} ] -tooltip {show "True"} -legend {bottom "5%" left "45%"}
            $bar Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
            $bar Yaxis -name "Seconds" -position "left" -axisLabel {formatter {"{value}"}}
            $bar Add "barSeries" -name GEOMEAN -data [list "$geomeantime "] -itemStyle [ subst {color $color1 opacity 0.90} ]
            $bar Add "barSeries" -name "QUERY SET" -data [list "$qsettime "] -itemStyle [ subst {color $color2 opacity 0.90} ]
            set html [ $bar toHTML -title "$jobid Result" ]
            hdbjobs eval {INSERT INTO JOBCHART(jobid,chart,html) VALUES($jobid,'result',$html)}
            return $html
          } else {
            #TPROC-C
            #Create chart and insert into JOBCHART for future retrieval
            set vus [ lindex $chartdata 2 ]
            lassign [ getnopmtpm $chartdata ] jobid tstamp activevu nopm tpm dbdescription
            if { $dbdescription eq "SQL" } { set dbdescription "MSSQLServer" }
            foreach colour {color1 color2} {set $colour [ dict get $chartcolors $dbdescription $colour ]}
            if { $dbdescription eq "MSSQLServer" } { set dbdescription "SQL Server" }
            set bar [ticklecharts::chart new]
            set ::ticklecharts::htmlstdout "True" ; 
            $bar SetOptions -title [ subst {text "$dbdescription TPROC-C Result $jobid"} ] -tooltip {show "True"} -legend {bottom "5%" left "45%"}
            $bar Xaxis -data [list [ subst {"$dbdescription $vus"}]] -axisLabel [list show "True"]
            $bar Yaxis -name "Transactions" -position "left" -axisLabel {formatter {"{value}"}}
            $bar Add "barSeries" -name NOPM -data [list "$nopm "] -itemStyle [ subst {color $color1 opacity 0.90} ]
            $bar Add "barSeries" -name TPM -data [list "$tpm "] -itemStyle [ subst {color $color2 opacity 0.90} ]            
            set html [ $bar toHTML -title "$jobid Result" ]
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
          foreach colour {color1 color2} {set $colour [ dict get $chartcolors $dbdescription $colour ]}
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
            set ::ticklecharts::htmlstdout "True"
            $bar SetOptions -title [ subst {text "$dbdescription TPROC-H Power Query Times $jobid"} ] -tooltip {show "True"} -legend {bottom "5%" left "45%"}
            $bar Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
            $bar Yaxis -name "Seconds" -position "left" -axisLabel {formatter {"{value}"}}
            $bar Add "barSeries" -name "VU 1 Query Set" -data [list $barseries] -itemStyle [ subst {color $color1 opacity 0.90} ]
            set html [ $bar toHTML -title "$jobid Query Times" ]
            hdbjobs eval {INSERT INTO JOBCHART(jobid,chart,html) VALUES($jobid,'timing',$html)}
            return $html
          } else {
            #CREATE TPROC-C Timing charts

            #X axis
            set xaxisvals {}
            foreach sp {NEWORD PAYMENT DELIVERY SLEV OSTAT} {
              lappend xaxisvals $sp
            }

            #Series data for existing bar chart
            set P25_MS {}
            set P50_MS {}
            set P75_MS {}
            set P95_MS {}
            set P99_MS {}
            set AVG_MS {}

            #Series data for new box plot
            set boxdata {}

            foreach sp {NEWORD PAYMENT DELIVERY SLEV OSTAT} {
              set spdata [dict get $chartdata $sp]

              lappend P25_MS [dict get $spdata p25_ms]
              lappend P50_MS [dict get $spdata p50_ms]
              lappend P75_MS [dict get $spdata p75_ms]
              lappend P95_MS [dict get $spdata p95_ms]
              lappend P99_MS [dict get $spdata p99_ms]
              lappend AVG_MS [dict get $spdata avg_ms]

              #Boxplot format: min, q1, median, q3, max
            # Use p99 instead of max_ms as max only shows whiskers due to extended scale
            # [dict get $spdata max_ms]
              lappend boxdata [list \
                [dict get $spdata min_ms] \
                [dict get $spdata p25_ms] \
                [dict get $spdata p50_ms] \
                [dict get $spdata p75_ms] \
                [dict get $spdata p99_ms] \
              ]
            }

            #boxplot chart
            set dbdescription [ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]
            set boxdescription $dbdescription
            foreach colour {color1 color2} {set $colour [ dict get $chartcolors $dbdescription $colour ]}
            set box [ticklecharts::chart new]
            set ::ticklecharts::htmlstdout "True"
            $box SetOptions -title [ subst {text "$boxdescription TPROC-C Box Plot $jobid"} ] -tooltip {show "True"} -legend {show "False"}
            $box Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
            $box Yaxis -name "Milliseconds" -position "left" -axisLabel {formatter {"{value}"}}
            $box Add "boxPlotSeries" -name "Response Distribution" -data $boxdata -itemStyle [ subst {color $color1 opacity 0.70} ]
            set boxhtml [ $box toHTML -title "$jobid Response Time Distribution" ]

            #original percentile/average chart
            set bar [ticklecharts::chart new]
            set ::ticklecharts::htmlstdout "True"
            $bar SetOptions -title [ subst {text "$dbdescription TPROC-C Latency Summary"} ] -tooltip {show "True"} -legend {bottom "5%" left "30%"}
            $bar Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
            $bar Yaxis -name "Milliseconds" -position "left" -axisLabel {formatter {"{value}"}}
            #$bar Add "barSeries" -name P25_MS -data [list $P25_MS]
            $bar Add "barSeries" -name P50_MS -data [list $P50_MS]
            #$bar Add "barSeries" -name P75_MS -data [list $P75_MS]
            $bar Add "barSeries" -name P95_MS -data [list $P95_MS]
            $bar Add "barSeries" -name P99_MS -data [list $P99_MS]
            $bar Add "barSeries" -name AVG_MS -data [list $AVG_MS]
            set barhtml [ $bar toHTML -title "$jobid Response Times" ]

            regsub -all {(?is)^.*?<body[^>]*>} $barhtml "" barhtml
            regsub -all {(?is)</body>\s*</html>\s*$} $barhtml "" barhtml
            regsub -all {(?is)<p><img[^>]*logo\.png[^>]*></p>} $barhtml "" barhtml
            regsub -all {(?is)^.*?(\bchart_[A-Za-z0-9]+\s*=\s*echarts\.init)} $barhtml {\1} barhtml
            #Return both charts in one HTML payload
            set html "$boxhtml $barhtml"
            regsub -all {(?is)</script>\s*</body>\s*</html>\s*<br><br>} $html "" html
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
          foreach colour {color1 color2} {set $colour [ dict get $chartcolors $dbdescription $colour ]}
          if { $dbdescription eq "MSSQLServer" } { set dbdescription "SQL Server" }
          set header [ dict keys $chartdata ]
	if { [ string match "*qph*" $header ] } {
	set workload "TPROC-H Query"
	set axisname "QPH"
	} else {
	set workload "TPROC-C Transaction"
	set axisname "TPM"
	}
          set xaxisvals [ dict keys [ join [ dict values $chartdata ]]]
          set lineseries [ dict values [ join [ dict values $chartdata ]]]
          #Delete the first and trailing values if it is 0, so we start from the first measurement and only chart when running
          if { [ lindex $lineseries 0 ] eq 0 } {
            set lineseries [ lreplace $lineseries 0 0 ]
            set xaxisvals [ lreplace $xaxisvals 0 0 ]
          }
          while { [ lindex $lineseries end ] eq 0 } {
            set lineseries [ lreplace $lineseries end end ]
            set xaxisvals [ lreplace $xaxisvals end end ]
          }
          set line [ticklecharts::chart new]
          set ::ticklecharts::htmlstdout "True" ; 
          $line SetOptions -title [ subst {text "$dbdescription $workload Count $jobid"} ] -tooltip {show "True"} -legend {bottom "5%" left "40%"}
          $line Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
          $line Yaxis -name "$axisname" -position "left" -axisLabel {formatter {"{value}"}}
          $line Add "lineSeries" -name [ join $header ] -data [ list $lineseries ] -itemStyle [ subst {color $color1 opacity 0.90} ]
          set html [ $line toHTML -title "$jobid Transaction Count" ]
          #If we query the tcount chart while the job is running it will not be generated again
          #meaning the output will be truncated
          #only save the chart once the job is complete
          set jobstatus [ hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=0} ]
          if { [ string match "*ALL VIRTUAL USERS COMPLETE*" $jobstatus ] } {
            hdbjobs eval {INSERT INTO JOBCHART(jobid,chart,html) VALUES($jobid,'tcount',$html)}
          }
         return $html
        }
      }
      "metrics" {
        set date [ join [ hdbjobs eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$jobid} ]]
        set chartdata [ getjobmetrics $jobid ]
        if { [ llength $chartdata ] eq 2 && [ string match [ lindex $chartdata 1 ] "Jobid has no metrics data" ] } {
          putscli "Chart for jobid $jobid not available, Jobid has no metrics data"
          return
        } else {
          set query [ hdbjobs eval {SELECT COUNT(*) FROM JOBCHART WHERE JOBID=$jobid AND CHART="metrics"} ]
          if { $query eq 0 } {
            #No result chart exists create one and insert into JOBCHART table
          } else {
            #Return existing results chart from JOBCHART table
            set html [ join [ hdbjobs eval {SELECT html FROM JOBCHART WHERE JOBID=$jobid AND CHART="metrics"} ]]
            return $html
          }
          set dbdescription [ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]
          hdbjobs eval {SELECT cpucount,cpumodel from JOBSYSTEM WHERE JOBID=$jobid} {
	  set cpudescription "$cpucount x $cpumodel"
		}
	if {[ dict size $chartdata ] <= 1} {
          putscli "Chart for jobid $jobid not available, Jobid has insufficient metrics data"
	  return
	}
	  set axisname "CPU %"
          set ioaxisname "I/O"
          set xaxisvals [ dict keys $chartdata ]
          dict for {tstamp cpuvalues} $chartdata {
          dict with cpuvalues {
            lappend usrseries ${usr%}
            lappend sysseries ${sys%}
            lappend irqseries ${irq%}
            lappend iopsseries $iops
            lappend mbpsseries $mbps
          }}
          #Delete the first and trailing values if usr utilisation is 0, so we start from the first measurement and only chart when running
          if { [ lindex $usrseries 0 ] eq 0.0 } {
            set usrseries [ lreplace $usrseries 0 0 ]
            set sysseries [ lreplace $sysseries 0 0 ]
            set irqseries [ lreplace $irqseries 0 0 ]
            set iopsseries [ lreplace $iopsseries 0 0 ]
            set mbpsseries [ lreplace $mbpsseries 0 0 ]
            set xaxisvals [ lreplace $xaxisvals 0 0 ]
          }
          while { [ lindex $usrseries end ] eq 0.0 } {
            set usrseries [ lreplace $usrseries end end ]
            set sysseries [ lreplace $sysseries end end ]
            set irqseries [ lreplace $irqseries end end ]
            set iopsseries [ lreplace $iopsseries end end ]
            set mbpsseries [ lreplace $mbpsseries end end ]
            set xaxisvals [ lreplace $xaxisvals end end ]
          }
	  if { ![ info exists dbdescription ] } { set dbdescription "Generic CPU" }
          set line [ticklecharts::chart new]
          set ::ticklecharts::htmlstdout "True" ; 
          set irqSeriesName "irq%"
          # Set 'showIrqSeries' to True to show the IRQ series in the chart (default is 'False').
          set showIrqSeries "False"
          # Use 'irqJS' to toggle the visibility of the IRQ series in the chart.
          set irqJS [ticklecharts::jsfunc new [subst {{'$irqSeriesName': [string tolower $showIrqSeries]}}]]
          $line SetOptions -title [ subst {text "$dbdescription Metrics $jobid $cpudescription"} ] \
                           -tooltip {show "True"} \
                           -legend [list bottom "5%" left "40%" selected $irqJS]
          $line Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
          $line Yaxis -name "$axisname" -position "left" -axisLabel {formatter {"{value}"}}
          $line Yaxis -name "$ioaxisname" -position "right" -axisLabel {formatter {"{value}"}}
          $line Add "lineSeries" -name "usr%" -data [ list $usrseries ] -itemStyle [ subst {color green opacity 0.90} ]
          $line Add "lineSeries" -name "sys%" -data [ list $sysseries ] -itemStyle [ subst {color red opacity 0.90} ]
	        # 'irqseries' is included but hidden by default with 'showIrqSeries' variable set.
          $line Add "lineSeries" -name $irqSeriesName -data [ list $irqseries ] -itemStyle [ subst {color blue opacity 0.90} ]
          $line Add "lineSeries" -name "IOPS" -yAxisIndex 1 -data [ list $iopsseries ] -itemStyle [ subst {color orange opacity 0.90} ]
          $line Add "lineSeries" -name "MB/s" -yAxisIndex 1 -data [ list $mbpsseries ] -itemStyle [ subst {color purple opacity 0.90} ]
          set html [ $line toHTML -title "$jobid " ]
          #If we query the metrics chart while the job is running it will not be generated again
          #meaning the output will be truncated
          #only save the chart once the job is complete
          set jobstatus [ hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=0} ]
          if { [ string match "*ALL VIRTUAL USERS COMPLETE*" $jobstatus ] } {
            hdbjobs eval {INSERT INTO JOBCHART(jobid,chart,html) VALUES($jobid,'metrics',$html)}
          }
          return $html
        }
      }
	profile {
	set profileid $jobid
	set lineseries1 [ list ]
	set lineseries2 [ list ]
	set xaxisvals [ list ]
	set profiles [ get_job_profile $profileid ]
	if {$profiles eq {}} {return}
	set profdict [ huddle get_stripped $profiles ]
        dict for {job profiledata} $profdict {
        dict for {k v} $profiledata {
	set dbdescription [ dict get $profiledata db ]
	set timestamp [ dict get $profiledata tstamp ]
	switch $k {
	"nopm" {
	lappend lineseries1 $v
	}
	"tpm" {
	lappend lineseries2 $v
	}
	"activevu" {
	lappend xaxisvals $v
	}
        default {
	;
	}}}
	set jobid $job
	}
          if { [ llength $xaxisvals ] < 2 } {
        set html "Error: Not enough data for performance profile chart type"
        return
	}
          set line [ticklecharts::chart new]
          set ::ticklecharts::htmlstdout "True" ; 
          foreach colour {color1 color2} {set $colour [ dict get $chartcolors $dbdescription $colour ]}
          $line SetOptions -title [ subst {text "$dbdescription Performance Profile $profileid $timestamp"} ] -tooltip {show "True"} -legend {bottom "5%" left "40%"}
          $line Xaxis -name "Active VU" -data [list $xaxisvals] -axisLabel [list show "True"]
          $line Yaxis -name "Transactions" -position "left" -axisLabel {formatter {"{value}"}}
          $line Add "lineSeries" -name "NOPM" -data [ list $lineseries1 ] -itemStyle [ subst {color $color1 opacity 0.90} ]
          $line Add "lineSeries" -name "TPM" -data [ list $lineseries2 ] -itemStyle [ subst {color $color2 opacity 0.90} ]
          set html [ $line toHTML -title "Performance Profile $profileid" ]
          #If we query the profile chart while the job is running it will not be generated again
          #meaning the output will be truncated
          #only save the chart once the last job is complete
          set jobstatus [ hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=0} ]
          if { [ string match "*ALL VIRTUAL USERS COMPLETE*" $jobstatus ] } {
            hdbjobs eval {INSERT INTO JOBCHART(jobid,chart,html) VALUES($jobid,'profile',$html)}
          }
         return $html
      }
         diff:* {
             # chart = "diff:<other_profileid>"
             set parts [split $chart ":"]
             if {[llength $parts] != 2} {
                 set html "Error: chart type diff should be diff:profileid"
                 return
             }

             # base/reference profile from jobid
             set base_pid $jobid
             # new/compared profile from diff:PROFILEID
             set new_pid [lindex $parts 1]

             # retain local names used by the comparison logic
             set profileid1 $base_pid
             set profileid2 $new_pid

             # --- get base profile series ---
             set lineseries1_1 [list]
             set lineseries2_1 [list]
             set xaxisvals1    [list]
             set profiles1 [get_job_profile $profileid1]
             if {$profiles1 eq {}} {
                 set html "Error: Not enough data for performance profile chart type"
                 return
             }
             set profdict1 [huddle get_stripped $profiles1]
             dict for {job profiledata} $profdict1 {
                 set dbdescription1 [dict get $profiledata db]
                 set timestamp1     [dict get $profiledata tstamp]
                 dict for {k v} $profiledata {
                     switch $k {
                         "nopm"     { lappend lineseries1_1 $v }
                         "tpm"      { lappend lineseries2_1 $v }
                         "activevu" { lappend xaxisvals1    $v }
                         default    { ; }
                     }
                 }
             }
             if {[llength $xaxisvals1] < 2} {
                 set html "Error: Not enough data for performance profile chart type"
                 return
             }

             # --- get new profile series ---
             set lineseries1_2 [list]
             set lineseries2_2 [list]
             set xaxisvals2    [list]
             set profiles2 [get_job_profile $profileid2]
             if {$profiles2 eq {}} {
                 set html "Error: Not enough data for performance profile chart type"
                 return
             }
             set profdict2 [huddle get_stripped $profiles2]
             dict for {job profiledata} $profdict2 {
                 set dbdescription2 [dict get $profiledata db]
                 set timestamp2     [dict get $profiledata tstamp]
                 dict for {k v} $profiledata {
                     switch $k {
                         "nopm"     { lappend lineseries1_2 $v }
                         "tpm"      { lappend lineseries2_2 $v }
                         "activevu" { lappend xaxisvals2    $v }
                         default    { ; }
                     }
                 }
             }
             if {[llength $xaxisvals2] < 2} {
                 set html "Error: Not enough data for performance profile chart type"
                 return
             }

             # ---- align Active VU sets (intersection) ----
             set map_nopm1 [dict create]
             set map_tpm1  [dict create]
             for {set i 0} {$i < [llength $xaxisvals1]} {incr i} {
                 dict set map_nopm1 [lindex $xaxisvals1 $i] [lindex $lineseries1_1 $i]
                 dict set map_tpm1  [lindex $xaxisvals1 $i] [lindex $lineseries2_1 $i]
             }

             set map_nopm2 [dict create]
             set map_tpm2  [dict create]
             for {set i 0} {$i < [llength $xaxisvals2]} {incr i} {
                 dict set map_nopm2 [lindex $xaxisvals2 $i] [lindex $lineseries1_2 $i]
                 dict set map_tpm2  [lindex $xaxisvals2 $i] [lindex $lineseries2_2 $i]
             }

             set xaxisvals [list]
             set lineseries1_1_f [list]; set lineseries2_1_f [list]
             set lineseries1_2_f [list]; set lineseries2_2_f [list]

             foreach av $xaxisvals1 {
                 if {[dict exists $map_nopm2 $av]} {
                     lappend xaxisvals $av
                     lappend lineseries1_1_f [dict get $map_nopm1 $av]
                     lappend lineseries2_1_f [dict get $map_tpm1  $av]
                     lappend lineseries1_2_f [dict get $map_nopm2 $av]
                     lappend lineseries2_2_f [dict get $map_tpm2  $av]
                 }
             }

             set lineseries1_1 $lineseries1_1_f
             set lineseries2_1 $lineseries2_1_f
             set lineseries1_2 $lineseries1_2_f
             set lineseries2_2 $lineseries2_2_f

             if {[llength $xaxisvals] < 2} {
                 set html "Error: Not enough overlapping Active VU points to compare"
                 return
             }

             set dbdescription $dbdescription1
             foreach colour {color1 color2} {set $colour [dict get $chartcolors $dbdescription $colour]}

             set line [ticklecharts::chart new]
             set ::ticklecharts::htmlstdout "True"

             set pdesc1 ""
             set pdesc2 ""
             catch {upvar #0 profile_dbdesc profile_dbdesc}

             if {[info exists profile_dbdesc]} {
                 if {[dict exists $profile_dbdesc $profileid1]} {
                     set pdesc1 [dict get $profile_dbdesc $profileid1]
                 }
                 if {[dict exists $profile_dbdesc $profileid2]} {
                     set pdesc2 [dict get $profile_dbdesc $profileid2]
                 }
             }

             $line SetOptions \
                 -title  [subst {text "Performance Profile Compare New $new_pid $pdesc2 relative to Base $base_pid $pdesc1"}] \
                 -tooltip {show "True"} \
                 -legend  {bottom "5%" left "36%"}

             $line Xaxis -name "Active VU" -data [list $xaxisvals] -axisLabel [list show "True"]
             $line Yaxis -name "Transactions" -position "left" -axisLabel {formatter {"{value}"}}

             # Base: solid
             $line Add "lineSeries" -name "NOPM Base $profileid1" -data [list $lineseries1_1] \
                 -itemStyle [subst {color $color1 opacity 0.90}]
             $line Add "lineSeries" -name "TPM Base $profileid1" -data [list $lineseries2_1] \
                 -itemStyle [subst {color $color2 opacity 0.90}]

             # New: dashed
             $line Add "lineSeries" -name "NOPM New $profileid2" -data [list $lineseries1_2] \
                 -itemStyle [subst {color $color1 opacity 0.60}] \
                 -lineStyle {type "dashed"}
             $line Add "lineSeries" -name "TPM New $profileid2" -data [list $lineseries2_2] \
                 -itemStyle [subst {color $color2 opacity 0.60}] \
                 -lineStyle {type "dashed"}

             # --- Numeric summary using jobs_profile_diff (new relative to base) ---
             set ratio [jobs_profile_diff $profileid1 $profileid2 true]
             set summary ""
             if {$ratio ne ""} {
                 regsub {%$} $ratio "" cleanRatio
                 catch { set r [expr {double($cleanRatio)}] }
                 if {[info exists r]} {

                     # threshold (ratio) from cidict, default 0.025
                     upvar #0 cidict cidict
                     if {![info exists cidict]} {
                         set cidict [ SQLite2Dict "ci" ]
                     }
                     set threshold_value 0.025
                     if {[dict exists $cidict common diff_threshold]} {
                         set threshold_value [dict get $cidict common diff_threshold]
                     }
                     if {![string is double -strict $threshold_value] || $threshold_value < 0.0} {
                         set threshold_value 0.025
                     }

                     if {$r < (0.0 - $threshold_value)} {
                         set status "FAIL"
                     } else {
                         set status "PASS"
                     }

                     set delta [format "%+.2f" $r]
                     set summary "Compare summary: New $new_pid relative to Base $base_pid: Δ = $delta $status (threshold $threshold_value)"
                 } else {
                     set summary "Compare summary: New $new_pid relative to Base $base_pid: $cleanRatio"
                 }
             }
             set html [$line toHTML -title "Performance Profile Compare New $new_pid to Base $base_pid"]

             # Neutralise the green "success" wrapper emitted by toHTML (first <div ...>)
             if {[regexp {^<div([^>]*)>} $html -> attrs]} {
                 if {[regexp {style="([^"]*)"} $attrs -> st]} {
                     set newst "background-color: transparent !important; border-left: 0 !important; $st"
                     set newattrs [regsub {style="[^"]*"} $attrs "style=\"$newst\""]
                 } else {
                     set newattrs "$attrs style=\"background-color: transparent !important; border-left: 0 !important;\""
                 }
                 regsub {^<div[^>]*>} $html "<div$newattrs>" html
             }

             if {$summary ne ""} {
                 if {[info exists status] && $status eq "FAIL"} {
                     set bannerStyle "font-family:sans-serif; margin-bottom:0.5em; padding:10px; font-weight:bold; background-color:#fdecea; color:#b00020; border-left:6px solid #e74c3c;"
                 } else {
                     set bannerStyle "font-family:sans-serif; margin-bottom:0.5em; padding:10px; font-weight:bold; background-color:#e6f4ea; color:#1e7e34; border-left:6px solid #2ecc71;"
                 }
                 set html "<div style=\"$bannerStyle\">$summary</div>\n$html"
             }
             return $html
       }


      default {
        set html "Error: chart type should be metrics, profile, result, tcount, timing, diff:pid1:pid2"
        return
      }
    }
  }

proc getjob { query } {
    global bm
    upvar #0 genericdict genericdict

    # Output format (HammerDB uses "JSON" in places, keep both cases tolerant)
    if {[dict exists $genericdict commandline jobsoutput]} {
        set outputformat [dict get $genericdict commandline jobsoutput]
    } else {
        set outputformat "text"
    }

    # parse query string
    set params   [split $query &]
    set paramlen [llength $params]

    # 0 params
    if {$paramlen == 0} {
        set joboutput [hdbjobs eval {SELECT DISTINCT JOBID FROM JOBMAIN}]
        set huddleobj [huddle compile {list} $joboutput]
        if {[string equal -nocase $outputformat "JSON"]} {
            puts [huddle jsondump $huddleobj]
        } else {
            puts [join $joboutput "\n"]
        }
        return
    }

    if {$paramlen < 1 || $paramlen > 3} {
        puts "Error: Usage: \[ jobs | jobs format | jobs jobid | jobs jobid command | jobs jobid command option | jobs profileid | jobs profileid id\] - type \"help jobs\""
        return
    }

    # reset paramdict
    set paramdict [dict create]
    foreach a $params {
        if {$a eq ""} continue
        # bare tokens and key=value
        set parts [split $a =]
        set key   [lindex $parts 0]
        set value ""
        if {[llength $parts] > 1} {
            set value [join [lrange $parts 1 end] "="]
        }
        dict set paramdict $key $value
    }

    #   jobid=JOBID&timing&vu=VUID
    #   jobid=JOBID&timing&VUID            (old CLI paths)
    #   jobid=JOBID&getchart&chart=NAME
    if {$paramlen == 3} {

        # timing per VU
        if {[dict exists $paramdict jobid] && [dict exists $paramdict timing]} {

            set jobid [dict get $paramdict jobid]

            # accept
            # vu=2
            # bare VUID token
            set vuid ""

            if {[dict exists $paramdict vu]} {
                set vuid [dict get $paramdict vu]
            } else {
                # integer key => VUID
                foreach k [dict keys $paramdict] {
                    if {[string is integer -strict $k]} {
                        set vuid $k
                        break
                    }
                }
            }

            # also accept vu=2 value
            if {$vuid ne "" && [regexp -nocase {^vu=(\d+)$} $vuid -> vv]} {
                set vuid $vv
            }

            if {$vuid eq "" || ![string is integer -strict $vuid]} {
                puts "Error: Jobs Three Parameter Usage: \[ jobs jobid timing vuid | jobs jobid timing vu=n \]"
                return
            }

            unset -nocomplain jobtiming
            set jobtiming [dict create]

            # JOBTIMING for VU
	    hdbjobs eval {
                SELECT procname,elapsed_ms,calls,min_ms,avg_ms,max_ms,total_ms,p99_ms,p95_ms,p75_ms,p50_ms,p25_ms,sd,ratio_pct
                FROM JOBTIMING
                WHERE JOBID=$jobid AND VU=$vuid AND SUMMARY=0
                ORDER BY RATIO_PCT DESC
            } {
                set timing "elapsed_ms $elapsed_ms calls $calls min_ms $min_ms avg_ms $avg_ms max_ms $max_ms total_ms $total_ms p99_ms $p99_ms p95_ms $p95_ms p75_ms $p75_ms p50_ms $p50_ms p25_ms $p25_ms sd $sd ratio_pct $ratio_pct"
                dict append jobtiming $procname $timing
            }


            if {[dict size $jobtiming] != 0} {
                set huddleobj [huddle compile {dict * dict} $jobtiming]
                if {[string equal -nocase $outputformat "JSON"]} {
                    return [huddle jsondump $huddleobj]
                } else {
                    return $jobtiming
                }
            } else {
                puts "No Timing Data for VU $vuid for JOB $jobid: jobs jobid timing vuid"
                return
            }
        }

        # getchart
        if {[dict exists $paramdict jobid] && [dict exists $paramdict getchart] && [dict exists $paramdict chart]} {
            set html [getchart [dict get $paramdict jobid] 1 [dict get $paramdict chart]]
            return $html
        }

        puts "Error: Jobs Three Parameter Usage: \[ jobs jobid timing vuid | jobs jobid timing vu=n | jobs jobid getchart chart \]"
        return
    }

    if {$paramlen == 1} {
        if {[dict exists $paramdict joblist]} {
            return [hdbjobs eval {SELECT DISTINCT JOBID FROM JOBMAIN}]
        } elseif {[dict exists $paramdict allresults]} {
            set alljobs [hdbjobs eval {SELECT DISTINCT JOBID FROM JOBMAIN}]
            set huddleobj [huddle create]
            foreach jobres $alljobs {
                hdbjobs eval {SELECT bm, db, timestamp FROM JOBMAIN WHERE JOBID=$jobres} {
                    set jobresult [getjobresult $jobres 1]
                    if {[lindex $jobresult 1] eq "Jobid has no test result"} {
                        set huddleobj [huddle combine $huddleobj [huddle compile {dict} $jobresult]]
                        continue
                    } elseif {[string match "Geometric*" [lindex $jobresult 2]]} {
                        # TPROC-H first result only
                        set ctind 0
                        foreach ct {jobid tstamp geomean queryset} {
                            set $ct [lindex $jobresult $ctind]
                            incr ctind
                        }
                        set numbers [regexp -all -inline -- {[0-9]*\.?[0-9]+} $geomean]
                        set geo     [lindex $numbers 1]
                        set queries  [lindex $numbers 0]
                        set numbers  [regexp -all -inline -- {[0-9]*\.?[0-9]+} $queryset]
                        set querysets [lindex $numbers 0]
                        set querytime [lindex $numbers 1]
                        set tprochresult [list $jobres [subst {db $db bm $bm tstamp {$timestamp} queries $queries querysets $querysets geomean $geo querytime $querytime}]]
                        set huddleobj [huddle combine $huddleobj [huddle compile {dict * dict} $tprochresult]]
                        continue
                    } elseif {[string match "TEST RESULT*" [lindex $jobresult 3]]} {
                        # TPROC-C result
                        lassign [getnopmtpm $jobresult] jobid tstamp activevu nopm tpm dbdescription
                        set avu [regexp -all -inline -- {[0-9]*\.?[0-9]+} $activevu]
                        set tproccresult [list $jobres [subst {db $db bm $bm tstamp {$timestamp} activevu $avu nopm $nopm tpm $tpm}]]
                        set huddleobj [huddle combine $huddleobj [huddle compile {dict * dict} $tproccresult]]
                        continue
                    }
                }
            }
            if {[string equal -nocase $outputformat "JSON"]} {
                puts [huddle jsondump $huddleobj]
            } else {
                puts [huddle get_stripped $huddleobj]
            }
            return
        } elseif {[dict exists $paramdict alltimestamps]} {
            set alljobs [hdbjobs eval {SELECT DISTINCT JOBID FROM JOBMAIN}]
            set huddleobj [huddle create]
            foreach jobres $alljobs {
                set joboutput [hdbjobs eval {SELECT jobid, timestamp FROM JOBMAIN WHERE JOBID=$jobres}]
                set huddleobj [huddle combine $huddleobj [huddle compile {dict} $joboutput]]
            }
            if {[string equal -nocase $outputformat "JSON"]} {
                puts [huddle jsondump $huddleobj]
            } else {
                puts [huddle get_stripped $huddleobj]
            }
            return
        } elseif {[dict exists $paramdict jobid]} {
            set jobid [dict get $paramdict jobid]
            set q [hdbjobs eval {SELECT COUNT(*) FROM JOBOUTPUT WHERE JOBID=$jobid}]
            if {$q == 0} {
                puts "Jobid $jobid does not exist"
                return
            }
            set joboutput [hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid}]
            set huddleobj [huddle compile {list} $joboutput]
            if {[string equal -nocase $outputformat "JSON"]} {
                puts [huddle jsondump $huddleobj]
            } else {
                set res ""
                set num 0
                foreach row $joboutput {
                    if {$num == 0} {
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
        } else {
            puts "Jobs One Parameter Usage: jobs jobid=TEXT"
            return
        }
    }

    # order-independent
    if {$paramlen == 2} {

        # need jobid
        if {![dict exists $paramdict jobid]} {
            puts "Jobs Two Parameter Usage: jobs jobid status or jobs jobid db or jobs jobid bm or jobid system or jobs jobid timestamp or jobs jobid dict or jobs jobid vuid or jobs jobid result or jobs jobid timing or jobs jobid delete or jobs jobid metrics or jobs jobid system"
            return
        }

        set jobid [dict get $paramdict jobid]

        # select VU rows
        if {[dict exists $paramdict vu]} {
            set vuid [dict get $paramdict vu]
        } elseif {[dict exists $paramdict result]} {
            set vuid 1
        } else {
            set vuid 0
        }

        set q [hdbjobs eval {SELECT COUNT(*) FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid}]
        if {$q == 0} {
            puts "Jobid $jobid for virtual user $vuid does not exist"
            return
        }

        # jobid + (vu|status)
        if {[dict exists $paramdict vu] || [dict exists $paramdict status]} {
            set joboutput [hdbjobs eval {SELECT VU,OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=$vuid}]
            set huddleobj [huddle compile {list} $joboutput]
            if {[string equal -nocase $outputformat "JSON"]} {
                puts [huddle jsondump $huddleobj]
            } else {
                set res ""
                set num 0
                foreach row $joboutput {
                    if {$num == 0} {
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

        # jobid + delete
        if {[dict exists $paramdict delete]} {
            hdbjobs eval {DELETE FROM JOBMAIN   WHERE JOBID=$jobid}
            hdbjobs eval {DELETE FROM JOBTIMING WHERE JOBID=$jobid}
            hdbjobs eval {DELETE FROM JOBTCOUNT WHERE JOBID=$jobid}
            hdbjobs eval {DELETE FROM JOBMETRIC WHERE JOBID=$jobid}
            hdbjobs eval {DELETE FROM JOBSYSTEM WHERE JOBID=$jobid}
            hdbjobs eval {DELETE FROM JOBOUTPUT WHERE JOBID=$jobid}
            hdbjobs eval {DELETE FROM JOBCHART  WHERE JOBID=$jobid}
            puts "Deleted Jobid $jobid"
            return
        }

        # jobid + result
        if {[dict exists $paramdict result]} {
            set joboutput [getjobresult $jobid $vuid]
            set huddleobj [huddle compile {list} $joboutput]
            if {[string equal -nocase $outputformat "JSON"]} {
                puts [huddle jsondump $huddleobj]
            } else {
                puts [join $joboutput "\n"]
            }
            return
        }

        # jobid + timing  (SUMMARY across VUs)
        if {[dict exists $paramdict timing]} {
            set jobtiming [getjobtiming $jobid]
            set huddleobj [huddle compile {dict * dict} $jobtiming]
            if {[string equal -nocase $outputformat "JSON"]} {
                puts [huddle jsondump $huddleobj]
            } else {
                puts $jobtiming
            }
            return
        }

        # jobid + timestamp
        if {[dict exists $paramdict timestamp]} {
            set joboutput [hdbjobs eval {SELECT jobid, timestamp FROM JOBMAIN WHERE JOBID=$jobid}]
            set huddleobj [huddle compile {dict} $joboutput]
            if {[string equal -nocase $outputformat "JSON"]} {
                puts [huddle jsondump $huddleobj]
            } else {
                puts $joboutput
            }
            return
        }

        # jobid + dict
        if {[dict exists $paramdict dict]} {
            set joboutput [join [hdbjobs eval {SELECT jobdict FROM JOBMAIN WHERE JOBID=$jobid}]]
            set huddleobj [huddle compile {dict * dict} $joboutput]
            if {[string equal -nocase $outputformat "JSON"]} {
                puts [huddle jsondump $huddleobj]
            } else {
                puts $joboutput
            }
            return
        }

        # jobid + tcount
        if {[dict exists $paramdict tcount]} {
            set jsondict [getjobtcount $jobid]
            set huddleobj [huddle compile {dict * dict} $jsondict]
            if {[string equal -nocase $outputformat "JSON"]} {
                puts [huddle jsondump $huddleobj]
            } else {
                puts $jsondict
            }
            return
        }

        # jobid + metrics
        if {[dict exists $paramdict metrics]} {
            set jsondict [getjobmetrics $jobid]
            set huddleobj [huddle compile {dict * dict} $jsondict]
            if {[string equal -nocase $outputformat "JSON"]} {
                puts [huddle jsondump $huddleobj]
            } else {
                puts $jsondict
            }
            return
        }

        # jobid + system
        if {[dict exists $paramdict system]} {
           set jsondict [getjobsystem $jobid]
           if { [llength $jsondict] == 2 && [lindex $jsondict 1] eq "Jobid has no system data" } {
              set huddleobj [huddle compile {list} $jsondict]
           } else {
              set huddleobj [huddle compile {dict * string} $jsondict]
           }
           if {[string equal -nocase $outputformat "JSON"]} {
              puts [huddle jsondump $huddleobj]
           } else {
              puts $jsondict
           }
           return
        }

        # jobid + db
        if {[dict exists $paramdict db]} {
            # A Timed run will include a query for a version string, add the version if we find it
            set temp_output [join [hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=1}]]
            if {[string match "*DBVersion*" $temp_output]} {
                set matcheddbversion [regexp {(DBVersion:)(\d.+?)\s} $temp_output match header version]
                if {$matcheddbversion} {
                    set joboutput "[join [hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid}]] $version"
                } else {
                    set joboutput "[join [hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid}]]"
                }
            } else {
                set joboutput "[join [hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid}]]"
            }
            set huddleobj [huddle compile {list} $joboutput]
            if {[string equal -nocase $outputformat "JSON"]} {
                puts [huddle jsondump $huddleobj]
            } else {
                puts [join $joboutput "\n"]
            }
            return
        }

        # jobid + bm
        if {[dict exists $paramdict bm]} {
            set joboutput [join [hdbjobs eval {SELECT bm FROM JOBMAIN WHERE JOBID=$jobid}]]
            set huddleobj [huddle compile {list} $joboutput]
            if {[string equal -nocase $outputformat "JSON"]} {
                puts [huddle jsondump $huddleobj]
            } else {
                puts [join $joboutput "\n"]
            }
            return
        }

        puts "Jobs Two Parameter Usage: jobs jobid status or jobs jobid db or jobs jobid bm or jobid system or jobs jobid timestamp or jobs jobid dict or jobs jobid vuid or jobs jobid result or jobs jobid timing or jobs jobid delete or jobs jobid metrics or jobs jobid system"
        return
    }
}

proc job_get_ppid {} {
        global jobs_profile_id
 upvar #0 genericdict genericdict
    if {[dict exists $genericdict commandline jobs_profile_id ]} {
        set jobs_profile_id [ dict get $genericdict commandline jobs_profile_id ]
        if { ![string is integer -strict $jobs_profile_id ] } {
            putscli "Warning performance profile id not set to integer in config setting to 0"
            set jobs_profile_id 0
        }
    } else {
        putscli "Warning performance profile id not found in config setting to default"
            set jobs_profile_id 0
    }
return $jobs_profile_id
}

proc job_profile_id { args } {
    global jobs_profile_id
    upvar #0 genericdict genericdict
    if { ![info exists jobs_profile_id ] } {
        set jobs_profile_id [ job_get_ppid ]
    } else {
        dict set genericdict commandline jobs_profile_id $jobs_profile_id
        Dict2SQLite "generic" $genericdict
    }
    switch [ llength $args ] {
        0 {
            putscli "Performance profile id set to $jobs_profile_id"
        }
        1 {
            set tmp_ppid $args
            # profileid all: returns all used profile ids.
            if {[string equal -nocase $tmp_ppid "all"]} {
                # match 'jobs' output style
                if {[dict exists $genericdict commandline jobsoutput]} {
                    set outputformat [dict get $genericdict commandline jobsoutput]
                } else {
                    set outputformat "text"
                }

                set profileids {}
                if {[catch {
                    set profileids [hdbjobs eval {
                        SELECT DISTINCT(profile_id)
                        FROM JOBMAIN
                        WHERE profile_id > 0
                        ORDER BY profile_id ASC
                    }]
                } err]} {
                    putscli "Error querying profile ids: $err"
                    return
                }

                if {[llength $profileids] == 0} {
                    putscli "No performance profiles found"
                    return
                }

                if {[string equal -nocase $outputformat "JSON"]} {
                    # print as JSON array like 'jobs'
                    if {[catch {package require huddle}]} {}
                    if {[catch {package require json}]} {}
                    set h [huddle compile {list} $profileids]
                    puts [huddle jsondump $h]
                } else {
                    # plain list, one per line (like 'jobs' text mode)
                    puts [join $profileids "\n"]
                }
                return
            }

            if { ![string is integer -strict $tmp_ppid ] } {
                putscli "Error: Performance profile id should be an integer"
            } else {
                set jobs_profile_id $tmp_ppid
                putscli "Setting performance profile id to $jobs_profile_id"
                dict set genericdict "commandline" "jobs_profile_id" $jobs_profile_id
                Dict2SQLite "generic" $genericdict
            }
        }
        default {
            putscli "Error :profileid accepts none or one integer argument"
        }
    }
}

proc job_profile { args } {
    upvar #0 genericdict genericdict
    if {[dict exists $genericdict commandline jobsoutput]} {
      set outputformat [ dict get $genericdict commandline jobsoutput ]
    } else {
      set outputformat "text"
    }
	set huddleobj [ get_job_profile $args ]
	if { [ huddle llength $huddleobj ] > 0 } {
                  if { $outputformat eq "JSON" } {
                  puts [ huddle jsondump $huddleobj ]
                  } else {
                    puts [ huddle get_stripped $huddleobj ]
		}
	}
}

proc get_job_profile { args } {
 switch [ llength $args ] {
        1 {
            set tmp_ppid $args
            if { ![string is integer -strict $tmp_ppid ] || $tmp_ppid < 1 } {
                putscli "Error: Performance profile id should be an integer greater than 0"
            } else {

                set jobs_profile_id $tmp_ppid
        set alljobs [ hdbjobs eval {SELECT DISTINCT JOBID FROM JOBMAIN where profile_id=$tmp_ppid} ]
	   if { [ llength $alljobs ] eq 0 } {
                putscli "Error: No jobs found with performance profile id of $tmp_ppid"
		return
	   } else {
#Jobs found with chosen performance profile id
	set huddleobj [ huddle create ]
        foreach jobres $alljobs {	
    	hdbjobs eval {SELECT bm, db, timestamp FROM JOBMAIN WHERE JOBID=$jobres order by timestamp} {
	set jobresult [ getjobresult $jobres 1 ]
    if { [ lindex $jobresult 1 ] eq "Jobid has no test result" } {
#NO RESULT - should not happen as profile id should only be set for a TPROC-C run so should be 0, ignore
        continue
      } elseif { [ string match "Geometric*" [ lindex $jobresult 2 ] ] } {
#TPROC-H RESULT - should not happen as profile id should only be set for a TPROC-C run so should be 0, ignore
        continue
      } elseif { [ string match "TEST RESULT*" [ lindex $jobresult 3 ] ] } {
#TPROC-C RESULT 
        lassign [ getnopmtpm $jobresult ] jobid tstamp activevu nopm tpm dbdescription
        set avu [regexp -all -inline -- {[0-9]*\.?[0-9]+} $activevu]
	set tproccresult [list $jobres [ subst {db $db bm $bm tstamp {$timestamp} activevu $avu nopm $nopm tpm $tpm} ]]
	set huddleobj [ huddle combine $huddleobj [ huddle compile {dict * dict} $tproccresult ]]
        continue
}}}
return $huddleobj
            }
        }
    }
        default {
            putscli "Error :profile accepts one integer argument"
        }
}	
}
# Compare two performance profiles and return signed ratio:
# Always prints an unweighted summary. If weighting=true, also prints a weighted summary
# using w = max(1.0, activevu / phys_cores) with phys_cores = ceil(logical/2), no upper cap.

# Compare two performance profiles and return signed ratio:
#   ratio = (avg_comp - avg_base) / avg_base
# Weighting:
#   weighting = "true"  → weighted, phys_cores auto = ceil(logical/2)
#             = "false" → unweighted
# Weighted w = max(1.0, activevu / phys_cores)  (no cap)

proc jobs_profile_diff {good_pid bad_pid weighting} {
    # ---- validate ids ----
    if {![string is integer -strict $good_pid] || $good_pid < 1} {
        putscli "Error: good profile id must be an integer > 0"
        return
    }
    if {![string is integer -strict $bad_pid] || $bad_pid < 1} {
        putscli "Error: bad profile id must be an integer > 0"
        return
    }
    # ---- boolean weighting only ----
    if {![string is true $weighting] && ![string is false $weighting]} {
        putscli "Error: weighting must be true or false"
        return
    }
    set do_weight [string is true $weighting]

    # ---- helpers ----
    proc __collect_profile_points {pid mapVar jobsVar} {
        upvar 1 $mapVar m
        upvar 1 $jobsVar jl
        set m [dict create]
        set jl {}
        set jobs [hdbjobs eval "SELECT DISTINCT JOBID FROM JOBMAIN WHERE profile_id=$pid"]
        if {[llength $jobs] == 0} { return "empty" }
        foreach jid $jobs {
            hdbjobs eval {SELECT bm, db, timestamp FROM JOBMAIN WHERE JOBID=$jid ORDER BY timestamp} {
                set jr [getjobresult $jid 1]
                if {[lindex $jr 1] eq "Jobid has no test result"} { continue }
                if {[string match "Geometric*" [lindex $jr 2]]} { continue }
                if {![string match "TEST RESULT*" [lindex $jr 3]]} { continue }
                lassign [getnopmtpm $jr] _jid _ts avu_str nopm _tpm _desc
                if {![regexp -- {\d+} $avu_str avu_num]} { continue }
                scan $avu_num "%d" avu
                if {![string is integer -strict $nopm]} {
                    if {![regexp -- {\d+} $nopm nopm_num]} { continue }
                    scan $nopm_num "%d" nopm
                }
                dict set m $avu $nopm
                lappend jl $jid
            }
        }
        return "ok"
    }

        proc __logical_cpus {jobid} {
        if {![catch {
            set cpucount [join [hdbjobs eval {
                SELECT cpucount FROM JOBSYSTEM WHERE JOBID=$jobid
            }]]
        }]} {
            set cpucount [string trim $cpucount]
            if {[string is integer -strict $cpucount] && $cpucount > 0} {
                return $cpucount
            }
        }
        return ""
        }

    # Format ratio with sign; avoid ±0.00 by bumping precision if needed
    proc __fmt_ratio {r {decs 2}} {
        set s [format "%.*f" $decs $r]
        if {$s eq "0.00" || $s eq "-0.00" || $s eq "+0.00"} {
            if {$r == 0.0} { return "0.00" }
            set s4 [format "%+.4f" $r]
            if {$s4 eq "+0.0000" || $s4 eq "-0.0000"} { return "0.0000" }
            return $s4
        }
        if {$r > 0} { return "+$s" }
        return $s
    }

    # ---- collect points ----
    if {[__collect_profile_points $good_pid good_map good_jobs] eq "empty"} {
        putscli "Error: no jobs found for good profile id $good_pid"
        return
    }
    if {[__collect_profile_points $bad_pid bad_map bad_jobs] eq "empty"} {
        putscli "Error: no jobs found for bad profile id $bad_pid"
        return
    }

    # ---- intersect VU points ----
    array set seen {}
    foreach av [dict keys $good_map] { set seen($av) 1 }
    set matched {}
    foreach av [dict keys $bad_map] {
        if {[info exists seen($av)]} { lappend matched $av }
    }
    if {[llength $matched] == 0} {
        putscli "Error: the two profiles have no overlapping activevu points"
        return
    }
    set matched [lsort -integer -unique $matched]

    # ---- unweighted (always print) ----
    set g_sum_u 0.0
    set b_sum_u 0.0
    foreach av $matched {
        set g_sum_u [expr {$g_sum_u + [dict get $good_map $av]}]
        set b_sum_u [expr {$b_sum_u + [dict get $bad_map  $av]}]
    }
    set n [llength $matched]
    set g_avg_u [expr {$g_sum_u / $n}]
    set b_avg_u [expr {$b_sum_u / $n}]
    if {$g_avg_u <= 0.0} {
        putscli "Error: good profile average NOPM is zero; cannot compute ratio"
        return
    }
    set ratio_u [expr {($b_avg_u - $g_avg_u) / $g_avg_u}]
    putscli [format "Profiles compared (unweighted): matched=%d, avg_base=%.0f, avg_comp=%.0f" $n $g_avg_u $b_avg_u]

    # ---- weighted (optional) ----
    if {$do_weight} {
        set logical [__logical_cpus [lindex $good_jobs 0]]
        if {$logical eq ""} {
            putscli "Error: CPU-weighted requested but logical CPU count not found; using unweighted only"
            return [__fmt_ratio $ratio_u 2]
        }
        set phys_cores [expr {int(ceil($logical / 2.0))}]
        set g_sum 0.0
        set b_sum 0.0
        set w_sum 0.0
        foreach av $matched {
            set w [expr {max(1.0, double($av)/double($phys_cores))}]  ;# linear, no cap
            set g_sum [expr {$g_sum + $w * [dict get $good_map $av]}]
            set b_sum [expr {$b_sum + $w * [dict get $bad_map  $av]}]
            set w_sum [expr {$w_sum + $w}]
        }
        if {$w_sum > 0.0} {
            set g_avg [expr {$g_sum / $w_sum}]
            set b_avg [expr {$b_sum / $w_sum}]
            if {$g_avg > 0.0} {
                set ratio_w [expr {($b_avg - $g_avg) / $g_avg}]
                putscli [format "Profiles compared (weighted linear, no cap): matched=%d, phys_cores=%d, avg_base=%.0f, avg_comp=%.0f" \
                                 $n $phys_cores $g_avg $b_avg]
                return [__fmt_ratio $ratio_w 2]
            }
        }
        # fallback
        return [__fmt_ratio $ratio_u 2]
    }

    # return unweighted result
    return [__fmt_ratio $ratio_u 2]
}
}
namespace import jobs::*
