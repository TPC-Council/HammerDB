package provide jobs 1.0
namespace eval jobs {
  namespace export init_job_tables_gui init_job_tables init_job_tables_ws jobmain jobs job hdbjobs jobs_ws job_disable job_disable_check job_format wapp-page-jobs wapp-page-logo.png wapp-page-tick.png wapp-page-cross.png wapp-page-star.png wapp-page-nostatus.png getjob savechart
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
    #rename jobs {}
    #uplevel #0 {proc hdbjobs { args } { return "" }}
    #If we want to fully disable jobs output in the GUI uncomment previous 2 lines and comment the following line
    init_job_tables
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
        if [catch {hdbjobs eval {CREATE TABLE JOBMAIN(jobid TEXT primary key, db TEXT, bm TEXT, jobdict TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')),profile_id INTEGER NOT NULL DEFAULT 0)}} message ] {
          puts "Error creating JOBMAIN table in SQLite in-memory database : $message"
          return
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBTIMING(jobid TEXT, vu INTEGER, procname TEXT, calls INTEGER, min_ms REAL, avg_ms REAL, max_ms REAL, total_ms REAL, p99_ms REAL, p95_ms REAL, p50_ms REAL, sd REAL, ratio_pct REAL, summary INTEGER, elapsed_ms REAL, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBTIMING table in SQLite in-memory database : $message"
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBTCOUNT(jobid TEXT, counter INTEGER, metric TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBTCOUNT table in SQLite in-memory database : $message"
          return
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBMETRIC (jobid TEXT, usr REAL, sys REAL, irq REAL, idle REAL, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBMETRIC table in SQLite in-memory database : $message"
          return
        } elseif [ catch {hdbjobs eval {CREATE TABLE JOBSYSTEM (jobid TEXT primary key, hostname TEXT, cpumodel TEXT, cpucount INTEGER, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
          puts "Error creating JOBSYSTEM table in SQLite in-memory database : $message"
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
          catch {hdbjobs eval {CREATE INDEX JOBMETRIC_IDX ON JOBMETRIC(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBSYSTEM_IDX ON JOBSYSTEM(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBOUTPUT_IDX ON JOBOUTPUT(jobid)}}
          catch {hdbjobs eval {CREATE INDEX JOBCHART_IDX ON JOBCHART(jobid)}}
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
            } elseif [ catch {hdbjobs eval {CREATE TABLE JOBTIMING(jobid TEXT, vu INTEGER, procname TEXT, calls INTEGER, min_ms REAL, avg_ms REAL, max_ms REAL, total_ms REAL, p99_ms REAL, p95_ms REAL, p50_ms REAL, sd REAL, ratio_pct REAL, summary INTEGER, elapsed_ms REAL, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
              puts "Error creating JOBTIMING table in SQLite on-disk database : $message"
              return
            } elseif [ catch {hdbjobs eval {CREATE TABLE JOBTCOUNT(jobid TEXT, counter INTEGER, metric TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
              puts "Error creating JOBTCOUNT table in SQLite on-disk database : $message"
              return
            } elseif [ catch {hdbjobs eval {CREATE TABLE JOBMETRIC (jobid TEXT, usr REAL, sys REAL, irq REAL, idle REAL, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
             puts "Error creating JOBMETRIC table in SQLite on-disk database : $message"
             return
            } elseif [ catch {hdbjobs eval {CREATE TABLE JOBSYSTEM (jobid TEXT primary key, hostname TEXT, cpumodel TEXT, cpucount INTEGER, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
              puts "Error creating JOBSYSTEM table in SQLite on-disk database : $message"
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
              catch {hdbjobs eval {CREATE INDEX JOBMETRIC_IDX ON JOBMETRIC(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBSYSTEM_IDX ON JOBSYSTEM(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBOUTPUT_IDX ON JOBOUTPUT(jobid)}}
              catch {hdbjobs eval {CREATE INDEX JOBCHART_IDX ON JOBCHART(jobid)}}
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
           }}}}}
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
      } else {
        if { $tblname eq "" } {
          puts "Error: Job tables not created, create and populate Jobs database with GUI or CLI and run Web Service to browse Jobs"
          exit
        }
      }
    }
  }

  proc jobmain { jobid jobtype } {
    global rdbms bm
    upvar #0 genericdict genericdict
    if [ job_disable_check ] { return 0 }
    if {$jobtype in {check build check delete} || $bm != "TPC-C" } {
	set jobs_profile_id 0
	} else {
    if [catch {set jobs_profile_id [ dict get $genericdict commandline jobs_profile_id ]} message ] {
	set jobs_profile_id 0
    	 }
	}
    set query [ hdbjobs eval {SELECT COUNT(*) FROM JOBMAIN WHERE JOBID=$jobid} ]
    if { $query eq 0 } {
      set tmpdictforpt [ find_current_dict ]
      hdbjobs eval {INSERT INTO JOBMAIN(jobid,db,bm,jobdict,profile_id) VALUES($jobid,$rdbms,$bm,$tmpdictforpt,$jobs_profile_id)}
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
          if { ![string equal $charttype "result" ] && ![string equal $charttype "timing" ] && ![string equal $charttype "tcount" ]  && ![string equal $charttype "metrics" ] && ![string equal $charttype "profile" ] } {
            puts "Error: Jobs Three Parameter Usage: jobs jobid getchart \[ result | timing | tcount | metrics | profile \]"
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
        puts "Error: Usage: \[ jobs | jobs format | jobs jobid | jobs jobid command | jobs jobid command option | jobs profileid | jobs profileid id | jobs profile id \] - type \"help jobs\""
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

  proc common-header {} {
    wapp-trim {
      <html>
      <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="content-type" content="text/html; charset=UTF-8">
      <link href="%url([wapp-param BASE_URL]/style.css)" rel="stylesheet">
      <title>HammerDB Results</title>
      </head>
      <body>
      <p><img src='[wapp-param BASE_URL]/logo.png' width='347' height='60'></p>
    }
  }

  proc summary-header {jobid} {
    wapp-trim {
      <html>
      <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <meta http-equiv="content-type" content="text/html; charset=UTF-8">
      <link href="%url([wapp-param BASE_URL]/style.css)" rel="stylesheet">
      <title>hdb_%html($jobid)</title>
      </head>
      <body>
      <p><img src='[wapp-param BASE_URL]/logo.png' width='347' height='60'></p>
    }
  }

  proc main-footer {} {
    set B [wapp-param BASE_URL]
    set dbfile [ getdatabasefile ]
    set size "[ commify [ hdbjobs eval {SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()} ]]" 
    wapp-subst {<h3 class="title">Env</h3><br>}
      wapp-subst {<div><ol style='column-width: 20ex;'>\n}
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
      R0lGODlhEAAQAIIAAPwCBMT+xATCBASCBARCBAQCBEQCBAAAACH5BAEAAAAA
      LAAAAAAQABAAAAM2CLrc/itAF8RkdVyVye4FpzUgJwijORCGUhDDOZbLG6Nd
      2xjwibIQ2y80sRGIl4IBuWk6Af4EACH+aENyZWF0ZWQgYnkgQk1QVG9HSUYg
      UHJvIHZlcnNpb24gMi41DQqpIERldmVsQ29yIDE5OTcsMTk5OC4gQWxsIHJp
      Z2h0cyByZXNlcnZlZC4NCmh0dHA6Ly93d3cuZGV2ZWxjb3IuY29tADs=
    }]
  }

  proc wapp-page-cross.png {} {
    wapp-mimetype image/png
    wapp-cache-control max-age=3600
    wapp-unsafe [ binary decode base64 {
      R0lGODlhEAAQAIIAAASC/PwCBMQCBEQCBIQCBAAAAAAAAAAAACH5BAEAAAAA
      LAAAAAAQABAAAAMuCLrc/hCGFyYLQjQsquLDQ2ScEEJjZkYfyQKlJa2j7AQn
      MM7NfucLze1FLD78CQAh/mhDcmVhdGVkIGJ5IEJNUFRvR0lGIFBybyB2ZXJz
      aW9uIDIuNQ0KqSBEZXZlbENvciAxOTk3LDE5OTguIEFsbCByaWdodHMgcmVz
      ZXJ2ZWQuDQpodHRwOi8vd3d3LmRldmVsY29yLmNvbQA7
    }]
  }

  proc wapp-page-nostatus.png {} {
    wapp-mimetype image/png
    wapp-cache-control max-age=3600
    wapp-unsafe [ binary decode base64 {
   R0lGODlhEAAQAIIAAPwCBDRy7AQ2rFyq/EyWzEyW3Jzi9KTK/CH5BAEAAAAA
   LAAAAAAQABAAAAM7CArRLiuyQYQtxcpg8goDBn3VRo1KQAzo5EUg+4WtYo3B
   UUpbV/OcF28mHKZORokmyWQ2minDrrmU+BMAIf5oQ3JlYXRlZCBieSBCTVBU
   b0dJRiBQcm8gdmVyc2lvbiAyLjUNCqkgRGV2ZWxDb3IgMTk5NywxOTk4LiBB
   bGwgcmlnaHRzIHJlc2VydmVkLg0KaHR0cDovL3d3dy5kZXZlbGNvci5jb20A
   Ow==
    }]
  }

  proc wapp-page-star.png {} {
    wapp-mimetype image/png
    wapp-cache-control max-age=3600
    wapp-unsafe [ binary decode base64 {
      R0lGODlhEAAQAIUAAPwCBPy2BPSqBPSeBPS6HPSyDPSmBPzSXPzGNOyOBPSy
      FPzujPzaPOyWBPy+DPyyDPy+LPzKTPzmZPzeTPSaFOSGBNxuBNxmBPzWVPzq
      dPzmXPzePPzaRPzeRPS2FNxqBPzWNOyeBPTCLPzOJNxyBPzGHNReBOR6BOR2
      BNRmBMxOBMxWBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
      AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAAALAAAAAAQABAAAAZz
      QIBwSCwahYHA8SgYLIuEguFJFBwQCSpAMVgwEo2iI/mAECKSCYFCqVguF0BA
      gFlkNBsGZ9PxXD5EAwQTEwwMICAhcUYJInkgIyEWSwMRh5ACJEsVE5EhJQQm
      S40nKCQWAilHCSelQhcqsUatRisqWkt+QQAh/mhDcmVhdGVkIGJ5IEJNUFRv
      R0lGIFBybyB2ZXJzaW9uIDIuNQ0KqSBEZXZlbENvciAxOTk3LDE5OTguIEFs
      bCByaWdodHMgcmVzZXJ2ZWQuDQpodHRwOi8vd3d3LmRldmVsY29yLmNvbQA7
    }]
  }

  proc wapp-page-logo.png {} {
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

  proc wapp-page-jobs {} {
    global bm hdb_version
    set query [ wapp-param QUERY_STRING ]
    set params [ split $query & ]
    set paramlen [ llength $params ]
    set tprocccombined {}
    set tprochcombined {}
    if { $paramlen eq 0 } {
      set topjobs [ gettopjobs ]
      common-header
      wapp-subst {<h3 class="title">TPROC-C</h3>}
      wapp-trim {
        <div class='hammerdb' data-title='TPROC-C'>
      }
      set jcount 0
      wapp-subst {<div><ol style='column-width: 20ex;'>\n}
      wapp-subst {<br><table>\n}
      wapp-subst {<th>Jobid</th><th>Database</th><th>Date</th><th>Workload</th><th>NOPM</th><th>Status</th>\n}
      #one loop builds data for both TPROC-C and TPROC-H tables
      foreach job [ getjob joblist ] {
        incr jcount
	set nopm "--"
	set geo "--"
        set url "[wapp-param BASE_URL]/jobs?jobid=$job&index"
        set db [ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$job} ]]
        set bm [ string map {TPC TPROC} [ join [ hdbjobs eval {SELECT bm FROM JOBMAIN WHERE JOBID=$job} ]]]
        set date [ join [ hdbjobs eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$job} ]]
        set output [ join [ hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$job AND VU=0} ]]
        set output1 [ join [ hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$job AND VU=1} ]]
        if { [ string match -nocase "*creating*" $output1 ] } {
          set jobtype "Schema Build"
        } elseif { [ string match -nocase "*delete*" $output1 ] } {
          set jobtype "Schema Delete"
        } elseif { [ string match -nocase "*checking*" $output1 ] } {
          set jobtype "Schema Check"
        } elseif { [ string match -nocase "*rampup*" $output1 ] || [ string match -nocase "*scale\ factor*" $output1 ]} {
          set jobtype "Benchmark Run"
          set jobresult [ getjobresult $job 1 ]
          if { [ llength $jobresult ] eq 2 && [ string match [ lindex $jobresult 1 ] "Jobid has no test result" ] } {
		;
		} else {
          if { $bm eq "TPROC-C" } {
           lassign [ getnopmtpm $jobresult ] jobid tstamp activevu nopm tpm dbdescription
	    
		} else {
           set ctind 0
           foreach ct {jobid tstamp geomean queryset} { 
           set $ct [ lindex $jobresult $ctind ] 
           incr ctind
           }
           set numbers [regexp -all -inline -- {[0-9]*\.?[0-9]+} $geomean]
           set geo [ format "%.2f" [ lindex $numbers 1]]
		}
            }
        } else {
          set jobtype "--"
	}
        set statusimg ""
        if { [ string match "*ALL VIRTUAL USERS COMPLETE*" $output ] } {
          if { [ string match "*FINISHED FAILED*" $output ] } {
            set statusimg "<img src='[wapp-param BASE_URL]/cross.png'>"
          } else {
            if { [ llength [string_occurrences ":RUNNING" $output] ] eq [ llength [string_occurrences ":FINISHED SUCCESS" $output] ] } {
              set statusimg "<img src='[wapp-param BASE_URL]/tick.png'>"
              if { [ dict values $topjobs $job ] eq $job } {
                set statusimg "<img src='[wapp-param BASE_URL]/star.png'>"
              }
            }
          }
	#Didn't get ALL VU COMPLETE MESSAGE, usually threads waiting to close, check to see if we got a result and mark as complete if we did
        } else {
	if { [ string match "*FINISHED FAILED*" $output ] } {
            set statusimg "<img src='[wapp-param BASE_URL]/cross.png'>"
          } else {
        set output [ join [ hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$job AND VU=1} ]]
        if { [ string match "*TEST RESULT*" $output ] } {
              if { [ dict values $topjobs $job ] eq $job } {
                set statusimg "<img src='[wapp-param BASE_URL]/star.png'>"
              } else {
              set statusimg "<img src='[wapp-param BASE_URL]/tick.png'>"
		}
	} else {
              set statusimg "<img src='[wapp-param BASE_URL]/nostatus.png'>"
	}
	}
	}
	if {$bm eq "TPROC-C"} { append tprocccombined [ subst {<tr><td><a href='%html($url)'>%html($job)</a></td><td>%html($db)</td><td>%html($date)</td><td>%html($jobtype)</td><td>%html($nopm)</td><td>%unsafe($statusimg)</td></tr>\n} ]
           } else { append tprochcombined [ subst {<tr><td><a href='%html($url)'>%html($job)</a></td><td>%html($db)</td><td>%html($date)</td><td>%html($jobtype)</td><td>%html($geo)</td><td>%unsafe($statusimg)</td></tr>\n} ]
	   }
	}
      wapp-subst $tprocccombined
      wapp-subst {</table>\n}
      if { $tprocccombined eq {} } {
        wapp-subst {%html(No TPROC-C jobs found)\ in database file %html([ getdatabasefile ])}
      }
      wapp-subst {</ol></div>\n}
      set profcount 0
      wapp-subst {<h3 class="title">TPROC-C Performance Profiles</h3>}
      wapp-subst {<div><ol style='column-width: 20ex;'>\n}
      wapp-subst {<br><table>\n}
      wapp-subst {<th>Profile ID</th><th>Jobs</th><th>Database</th><th>Max Job</th><th>Max NOPM</th><th>Max TPM</th><th>Max AVU</th>\n}
        set profileids [ join [ hdbjobs eval {select distinct(profile_id) from jobmain where profile_id > 0 order by profile_id asc} ]]
      foreach profileid $profileids {
        incr profcount
	set url "[wapp-param BASE_URL]/jobs?profileid=$profileid"
	set profiles [ get_job_profile $profileid ]
	if { ![ huddle isHuddle $profiles ] || [ huddle llength $profiles ] eq 0 } {
	# likely job is currently running so data is incomplete	
	continue
	} else {
	set profdict [ huddle get_stripped $profiles ]
        set maxnopm -1
        dict for {job profiledata} $profdict {
        set jobcount [ dict size $profdict ]
        dict for {k v} $profiledata {
        if { $k eq "nopm" } {
        if {$v > $maxnopm} {
	set maxjob $job
        set maxurl "[wapp-param BASE_URL]/jobs?jobid=$maxjob&index"
        set maxnopm $v
	set maxdb [ dict get $profiledata db ]
        set maxtpm [ dict get $profiledata tpm ]
        set maxavu [ dict get $profiledata activevu ]
	}}}}
        wapp-subst {<tr><td><a href='%html($url)'>%html(Profile $profileid)</a></td><td>%html($jobcount)</td><td>%html($maxdb)</td><td><a href='%html($maxurl)'>%html($maxjob)</a></td><td>%html($maxnopm)</td><td>%html($maxtpm)</td><td>%html($maxavu)</td></td></tr>\n}
	}
	}
      wapp-subst {</table>\n}
      if { $profcount eq 0 } {
        wapp-subst {%html(No performance profiles found)\ in database file %html([ getdatabasefile ])}
      }
      wapp-subst {</ol></div>\n}
      wapp-subst {<h3 class="title">TPROC-H</h3>}
      wapp-trim {
        <div class='hammerdb' data-title='TPROC-H'>
      }
      set jcount 0
      wapp-subst {<div><ol style='column-width: 20ex;'>\n}
      wapp-subst {<br><table>\n}
      wapp-subst {<th>Jobid</th><th>Database</th><th>Date</th><th>Workload</th><th>Geomean</th><th>Status</th>\n}
      wapp-subst $tprochcombined
      wapp-subst {</table>\n}
      if { $tprochcombined eq {} } {
        wapp-subst {%html(No TPROC-H jobs found)\ in database file %html([ getdatabasefile ])}
      }
      wapp-subst {</ol></div>\n}
      main-footer
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
            #query on jobtiming and VU=vuid so do not replace with call to getjobtiming
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
      } elseif { [ dict keys $paramdict ] eq "profileid" } {
        set profileid [ dict get $paramdict profileid ]
        wapp-content-security-policy off
        wapp-subst {<link href="%url([wapp-param BASE_URL]/style.css)" rel="stylesheet">}
             foreach l [ split [ getchart $profileid 0 "profile" ] \n] {
             if { [ string match [ string trim $l ] <body> ] } {
                    set l "\t<body>\n\t<p><img src='[wapp-param BASE_URL]/logo.png' width='347' height='60'></p>"
                }
        wapp-subst {%unsafe($l)\n}
	}
	set url "[wapp-param BASE_URL]/jobs?profileid=$profileid&profiledata"
        set text "Profile Data"
        wapp-subst {<a href='%html($url)'>%html($text)</a><br>\n}
        common-footer
        return
      } else {
        dict set jsondict error message "Jobs One Parameter Usage: jobs?jobid=TEXT | jobs?profileid=INTEGER"
        wapp-2-json 2 $jsondict
        return
      }
      #2 or more parameters
    } else {
      if { [ dict keys $paramdict ] eq "jobid index" || [ dict keys $paramdict ] eq "jobid summary" || [ dict keys $paramdict ] eq "jobid vu" || [ dict keys $paramdict ] eq "jobid status" || [ dict keys $paramdict ] eq "jobid result" || [ dict keys $paramdict ] eq "jobid resultdata" || [ dict keys $paramdict ] eq "jobid DELETE" || [ dict keys $paramdict ] eq "jobid delete" || [ dict keys $paramdict ] eq "jobid timestamp" || [ dict keys $paramdict ] eq "jobid dict" || [ dict keys $paramdict ] eq "jobid timing" || [ dict keys $paramdict ] eq "jobid timingdata" || [ dict keys $paramdict ] eq "jobid db" ||  [ dict keys $paramdict ] eq "jobid bm" || [ dict keys $paramdict ] eq "jobid tcount" || [ dict keys $paramdict ] eq "jobid tcountdata" || [ dict keys $paramdict ] eq "jobid metrics"  || [ dict keys $paramdict ] eq "jobid metricsdata" ||  [ dict keys $paramdict ] eq "jobid system" ||  [ dict keys $paramdict ] eq "profileid profiledata"  } {
	if { [ lindex [ dict keys $paramdict ] 0 ] eq "profileid" } {
        set profileid [ dict get $paramdict profileid ]
        if { [ dict keys $paramdict ] eq "profileid profiledata" } {
        set huddleobj [ get_job_profile $profileid ]
            wapp-mimetype application/json
            wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
        return
	}
	} else {
        set jobid [ dict get $paramdict jobid ]
	}
        if { [ dict keys $paramdict ] eq "jobid vu" } {
          set vuid [ dict get $paramdict vu ]
        } else {
          if { [ dict keys $paramdict ] eq "jobid result" || [ dict keys $paramdict ] eq "jobid resultdata" } {
            set vuid 1
          } else {
            set vuid 0
          }
        }
	#Summary page with all available charts
        if { [ dict keys $paramdict ] eq "jobid summary" } {
          summary-header $jobid
        set jobresult [ getjobresult $jobid 1 ]
        set db [ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]
        set bm [ string map {TPC TPROC} [ join [ hdbjobs eval {SELECT bm FROM JOBMAIN WHERE JOBID=$jobid} ]]]
          if { $bm eq "TPROC-C" } {
	#TPROC-C Summary
          if { !([ llength $jobresult ] eq 2 && [ string match [ lindex $jobresult 1 ] "Jobid has no test result" ]) } {
           lassign [ getnopmtpm $jobresult ] jobid tstamp activevu nopm tpm dbdescription
           set avu [regexp -all -inline -- {[0-9]*\.?[0-9]+} $activevu]
		} else {
             ;#No result exclude summary
	   return
		}
      wapp-subst {<h3 class="title">Job %html($jobid) %html($bm) Summary %html($tstamp)</h3><br>}
      wapp-trim {
            <div class='hammerdb' data-title='Jobs Summary'>
          }
	#Summary Table
      wapp-subst {<table style="font-size: 150%;">\n}
      wapp-subst {<th>HDB Version</th><th>Database</th><th>Benchmark</th><th>NOPM</th><th>TPM</th><th>Active VU</th>\n}
      wapp-subst {<tr><td>%html($hdb_version)</td><td>%html($db)</td><td>%html($bm)</td><td>%html($nopm)</td><td>%html($tpm)</td><td>%html($avu)</td></tr>\n}
      wapp-subst {</table>\n}
	#Results chart - check for existence of result already done
              wapp-content-security-policy off
              foreach l [ split [ getchart $jobid 1 "result" ] \n] {
                if { [ string match "*TPROC-C Result*" $l  ] } {
                set l {"text": "Result",}
                # continue 
                }
                wapp-subst {%unsafe($l)\n}
              }
	#Tcount chart - check for existence first
                set jobtcount [ getjobtcount $jobid ]
                if { [ llength $jobtcount ] eq 2 && [ string match [ lindex $jobtcount 1 ] "Jobid has no transaction counter data" ] } {
                  ;#No tcount data exclude link
                } else {
              foreach l [ split [ getchart $jobid 1 "tcount" ] \n] {
                if { [ string match "*TPROC-C Transaction*" $l  ] } {
                set l {"text": "Transaction Count",}
                }
                wapp-subst {%unsafe($l)\n}
              }
                }
	#Timing chart - check for existence first
                  set jobtiming [ getjobtiming $jobid ]
                  if { [ llength $jobtiming ] eq 2 && [ string match [ lindex $jobtiming 1 ] "Jobid has no timing data" ] } {
                    ;#No timing data exclude link
                  } else {
              foreach l [ split [ getchart $jobid 1 "timing" ] \n] {
                if { [ string match "*TPROC-C Response*" $l  ] } {
                set l {"text": "Response Times",}
                }
                wapp-subst {%unsafe($l)\n}
              }
                  }
	#Metrics chart - check for existence first
                set jobmetrics [ getjobmetrics $jobid ]
                if { [ llength $jobmetrics ] eq 2 && [ string match [ lindex $jobmetrics 1 ] "Jobid has no metric data" ] } {
                  ;#No metrics data exclude link
                } else {
              foreach l [ split [ getchart $jobid 1 "metrics" ] \n] {
                if { [ string match "*text*:*$jobid*" $l  ] } {
		#strip jobid from chart title only show CPU
		regsub $jobid $l "" l
                }
                wapp-subst {%unsafe($l)\n}
              }
                }
		} else {
	#TPROC-H Summary
          if { !([ llength $jobresult ] eq 2 && [ string match [ lindex $jobresult 1 ] "Jobid has no test result" ]) } {
           set ctind 0
           foreach ct {jobid tstamp geomean queryset} { 
           set $ct [ lindex $jobresult $ctind ] 
           incr ctind
           }
           set numbers [regexp -all -inline -- {[0-9]*\.?[0-9]+} $geomean]
           set geo [ format "%.2f" [ lindex $numbers 1]]
	   regsub -all "Completed " $queryset "" queryset
	   regsub -all "query set" $queryset "qset" queryset
	   regsub -all "seconds" $queryset "secs" queryset
                } else {
             ;#No result exclude summary
           return
                }
      wapp-subst {<h3 class="title">Job %html($jobid) %html($bm) Summary %html($tstamp)</h3><br>}
      wapp-trim {
            <div class='hammerdb' data-title='Jobs Summary'>
          }
        #Summary Table
      wapp-subst {<table style="font-size: 150%;">\n}
      wapp-subst {<th>HDB Version</th><th>Database</th><th>Benchmark</th><th>Geomean</th><th>Query Time</th>\n}
      wapp-subst {<tr><td>%html($hdb_version)</td><td>%html($db)</td><td>%html($bm)</td><td>%html($geo)</td><td>%html($queryset)</td></tr>\n }
      wapp-subst {</table>\n}
	#Results chart - check for existence of result already done
              wapp-content-security-policy off
              foreach l [ split [ getchart $jobid 1 "result" ] \n] {
                if { [ string match "*TPROC-H Result*" $l  ] } {
                set l {"text": "Result",}
                # continue 
                }
                wapp-subst {%unsafe($l)\n}
              }
	#Timing chart - check for existence first - note TPROC-H timing comes from the output
        if { ![ string match "Geometric*" [ lindex $jobresult 2 ] ] } {
                    ;#No timing data exclude link
                  } else {
              foreach l [ split [ getchart $jobid 1 "timing" ] \n] {
                if { [ string match "*TPROC-H Power*" $l  ] } {
                set l {"text": "Power Query Times",}
                }
                wapp-subst {%unsafe($l)\n}
              }
                  }
	#Metrics chart - check for existence first
                set jobmetrics [ getjobmetrics $jobid ]
                if { [ llength $jobmetrics ] eq 2 && [ string match [ lindex $jobmetrics 1 ] "Jobid has no metric data" ] } {
                  ;#No metrics data exclude link
                } else {
              foreach l [ split [ getchart $jobid 1 "metrics" ] \n] {
                if { [ string match "*text*:*$jobid*" $l  ] } {
		#strip jobid from chart title only show CPU
		regsub $jobid $l "" l
                }
                wapp-subst {%unsafe($l)\n}
                }
                }
		}
	common-footer
	return
	} else {
        if { [ dict keys $paramdict ] eq "jobid index" } {
          common-header
          wapp-subst {<h3 class="title">Job:%html($jobid)</h3><br>}
          wapp-trim {
            <div class='hammerdb' data-title='Jobs Index'>
          }
          wapp-subst {<div><ol style='column-width: 20ex;'>\n}
          set jobresult [ getjobresult $jobid 1 ]
          if { [ llength $jobresult ] eq 2 && [ string match [ lindex $jobresult 1 ] "Jobid has no test result" ] } {
             ;#No result exclude summary
	     } else {
          set url "[wapp-param BASE_URL]/jobs?jobid=$jobid&summary"
          set text "summary"
          wapp-subst {<li><a href='%html($url)'>%html($text)</a>\n}
          }
          set url "[wapp-param BASE_URL]/jobs?jobid=$jobid"
          set text "output"
          wapp-subst {<li><a href='%html($url)'>%html($text)</a>\n}
          foreach option "bm db dict result status tcount system metrics timestamp timing delete" {
            set url "[wapp-param BASE_URL]/jobs?jobid=$jobid&$option"
            switch $option {
              bm {
                wapp-subst {<li><a href='%html($url)'>%html(benchmark)</a>\n}
              }
              db {
                wapp-subst {<li><a href='%html($url)'>%html(database)</a>\n}
              }
              dict {
                wapp-subst {<li><a href='%html($url)'>%html(dict configuration)</a>\n}
              }
              result {
                set jobresult [ getjobresult $jobid 1 ]
                if { [ llength $jobresult ] eq 2 && [ string match [ lindex $jobresult 1 ] "Jobid has no test result" ] } {
                  ;#No result exclude link
                } else {
                  wapp-subst {<li><a href='%html($url)'>%html($option)</a>\n}
                }
              }
              tcount {
                set jobtcount [ getjobtcount $jobid ]
                if { [ llength $jobtcount ] eq 2 && [ string match [ lindex $jobtcount 1 ] "Jobid has no transaction counter data" ] } {
                  ;#No result exclude link
                } else {
                  wapp-subst {<li><a href='%html($url)'>%html(transaction count)</a>\n}
                }
              }
              system {
                set jobsystem [ getjobsystem $jobid ]
                if { [ llength $jobsystem ] eq 2 && [ string match [ lindex $jobsystem 1 ] "Jobid has no system data" ] } {
                  ;#No result exclude link
                } else {
                wapp-subst {<li><a href='%html($url)'>%html(system)</a>\n}
                }
              }
              metrics {
                set jobmetrics [ getjobmetrics $jobid ]
                if { [ llength $jobmetrics ] eq 2 && [ string match [ lindex $jobmetrics 1 ] "Jobid has no metric data" ] } {
                  ;#No result exclude link
                } else {
                  wapp-subst {<li><a href='%html($url)'>%html(metrics)</a>\n}
                }
              }
              timing {
                set jobresult [ getjobresult $jobid 1 ]
                set tproch 0
                if { [ string match "Geometric*" [ lindex $jobresult 2 ] ] } {
                  #TPROC-H
                  set tproch 1
                  wapp-subst {<li><a href='%html($url)'>%html(timing data)</a>\n}
                } else {
                  #TPROC-C
                  set jobtiming [ getjobtiming $jobid ]
                  if { [ llength $jobtiming ] eq 2 && [ string match [ lindex $jobtiming 1 ] "Jobid has no timing data" ] } {
                    ;#No result exclude link
                  } else {
                    wapp-subst {<li><a href='%html($url)'>%html(timing data)</a>\n}
                  }
                }
              }
              default {
                wapp-subst {<li><a href='%html($url)'>%html($option)</a>\n}
              }
            }
          }
          wapp-subst {</ol></div>\n}
          common-footer
          return
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
            common-header
            wapp-trim {
              <div class='hammerdb' data-title='Job Delete'>
            }
            wapp-subst {<div><ol style='column-width: 20ex;'>\n}
            set url "[wapp-param BASE_URL]/jobs?jobid=$jobid&DELETE"
            set text "Confirm Delete Job $jobid"
            wapp-subst {<li><a href='%html($url)'>%html($text)</a>\n}
            wapp-subst {</ol></div>\n}
            common-footer
            return
          }
          if { [ dict keys $paramdict ] eq "jobid DELETE" } {
            set date [ join [ hdbjobs eval {SELECT timestamp FROM JOBMAIN WHERE JOBID=$jobid} ]]
            set current_time [ clock format [clock seconds] -format "%y-%m-%d %H:%M:%S"] 
            set job_age_hrs [expr {([clock scan $current_time ] - [clock scan $date])/3600}]
            set jobstatus [ hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=0} ]
            if { [ string match "*ALL VIRTUAL USERS COMPLETE*" $jobstatus ] || $job_age_hrs > 24 } {
              set joboutput [ hdbjobs eval {DELETE FROM JOBMAIN WHERE JOBID=$jobid} ]
              set joboutput [ hdbjobs eval {DELETE FROM JOBTIMING WHERE JOBID=$jobid} ]
              set joboutput [ hdbjobs eval {DELETE FROM JOBTCOUNT WHERE JOBID=$jobid} ]
              set joboutput [ hdbjobs eval {DELETE FROM JOBMETRIC WHERE JOBID=$jobid} ]
              set joboutput [ hdbjobs eval {DELETE FROM JOBSYSTEM WHERE JOBID=$jobid} ]
              set joboutput [ hdbjobs eval {DELETE FROM JOBOUTPUT WHERE JOBID=$jobid} ]
              set joboutput [ hdbjobs eval {DELETE FROM JOBCHART WHERE JOBID=$jobid} ]
              dict set jsondict success message "Deleted Jobid $jobid"
              global discardedjobs
              unset -nocomplain discardedjobs
              wapp-2-json 2 $jsondict
            } else {
              dict set jsondict error message "Cannot delete Jobid $jobid from $date did not complete and ran less than 24 hours ago"
              wapp-2-json 2 $jsondict
            }
          } else {
            if { [ dict keys $paramdict ] eq "jobid result" } {
              wapp-content-security-policy off
              wapp-subst {<link href="%url([wapp-param BASE_URL]/style.css)" rel="stylesheet">}
              foreach l [ split [ getchart $jobid $vuid "result" ] \n] {
                if { [ string match [ string trim $l ] <body> ] } {
                  set l "\t<body>\n\t<p><img src='[wapp-param BASE_URL]/logo.png' width='347' height='60'></p>"
                }
                wapp-subst {%unsafe($l)\n}
              }
              set url "[wapp-param BASE_URL]/jobs?jobid=$jobid&resultdata"
              set text "Result Data"
              wapp-subst {<a href='%html($url)'>%html($text)</a><br>\n}
              common-footer
              return
            } else {
              if { [ dict keys $paramdict ] eq "jobid timing" } {
                wapp-content-security-policy off
                wapp-subst {<link href="%url([wapp-param BASE_URL]/style.css)" rel="stylesheet">}
                foreach l [ split [ getchart $jobid $vuid "timing" ] \n] {
                  if { [ string match [ string trim $l ] <body> ] } {
                    set l "\t<body>\n\t<p><img src='[wapp-param BASE_URL]/logo.png' width='347' height='60'></p>"
                  }
                  wapp-subst {%unsafe($l)\n}
                }
                set url "[wapp-param BASE_URL]/jobs?jobid=$jobid&timingdata"
                set text "Timing Data"
                wapp-subst {<a href='%html($url)'>%html($text)</a><br>\n}
                common-footer
                return
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
                      wapp-content-security-policy off
                      wapp-subst {<link href="%url([wapp-param BASE_URL]/style.css)" rel="stylesheet">}
                      foreach l [ split [ getchart $jobid $vuid "tcount" ] \n] {
                        if { [ string match [ string trim $l ] <body> ] } {
                          set l "\t<body>\n\t<p><img src='[wapp-param BASE_URL]/logo.png' width='347' height='60'></p>"
                        }
                        wapp-subst {%unsafe($l)\n}
                      }
                      set url "[wapp-param BASE_URL]/jobs?jobid=$jobid&tcountdata"
                      set text "Transaction Count Data"
                      wapp-subst {<a href='%html($url)'>%html($text)</a><br>\n}
                      common-footer
                      return
                  } else {
                    if { [ dict keys $paramdict ] eq "jobid metrics" } {
                      wapp-content-security-policy off
                      wapp-subst {<link href="%url([wapp-param BASE_URL]/style.css)" rel="stylesheet">}
                      foreach l [ split [ getchart $jobid $vuid "metrics" ] \n] {
                        if { [ string match [ string trim $l ] <body> ] } {
                          set l "\t<body>\n\t<p><img src='[wapp-param BASE_URL]/logo.png' width='347' height='60'></p>"
                        }
                        wapp-subst {%unsafe($l)\n}
                      }
                      set url "[wapp-param BASE_URL]/jobs?jobid=$jobid&metricsdata"
                      set text "Metrics Data"
                      wapp-subst {<a href='%html($url)'>%html($text)</a><br>\n}
                      common-footer
                      return
                    } else {
                      if { [ dict keys $paramdict ] eq "jobid resultdata" } {
                        set joboutput [ getjobresult $jobid $vuid ]
                      } else {
                        if { [ dict keys $paramdict ] eq "jobid timingdata" } {
                          set jobresult [ getjobresult $jobid 1 ]
                          if { [ string match "Geometric*" [ lindex $jobresult 2 ] ] } {
                            #TPROC-H
                            set jobtiming [ hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=1} ]
                            set huddleobj [ huddle compile {list} $jobtiming ]
                            wapp-mimetype application/json
                            wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
                          } else {
                            set jobtiming [ getjobtiming $jobid ]
                            wapp-2-json 2 $jobtiming
                          }
                          return
                        } else {
                          if { [ dict keys $paramdict ] eq "jobid tcountdata" } {
                            set jsondict [ getjobtcount $jobid ]
                            wapp-2-json 2 $jsondict
                            return
                        } else {
                          if { [ dict keys $paramdict ] eq "jobid metricsdata" } {
                            set jsondict [ getjobmetrics $jobid ]
                            wapp-2-json 2 $jsondict
                            return
                          } else {
                            if { [ dict keys $paramdict ] eq "jobid db" } {
                            #A Timed run will include a query for a version string, add the version if we find it
		            set temp_output [ join [ hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=1} ]]
		            if { [ string match "*DBVersion*" $temp_output ] } {
        		    set matcheddbversion [regexp {(DBVersion:)(\d.+?)\s} $temp_output match header version ]
			    if { $matcheddbversion } {
                            set joboutput "[ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]] $version"
			    } else {
                            set joboutput "[ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]"
			    }
			    } else {
                            set joboutput "[ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]"
				}
                            } else {
                              if { [ dict keys $paramdict ] eq "jobid bm" } {
                                set joboutput [ join [ hdbjobs eval {SELECT bm FROM JOBMAIN WHERE JOBID=$jobid} ]]
                            } else {
                              if { [ dict keys $paramdict ] eq "jobid system" } {
				set joboutput [ list "No system data available" ]
                                hdbjobs eval {SELECT hostname,cpucount,cpumodel FROM JOBSYSTEM WHERE JOBID=$jobid} {
				set joboutput [ list $hostname $cpucount $cpumodel ]
				}
                              } else {
                                set joboutput [ list $jobid "Cannot find Jobid output" ]
                              }
            }}}}}}}}}}}}
            set huddleobj [ huddle compile {list} $joboutput ]
            wapp-mimetype application/json
            wapp-trim { %unsafe([huddle jsondump $huddleobj]) }
          }
        }
      } else {
        dict set jsondict error message "Jobs Two Parameter Usage: jobs?jobid=TEXT&index jobs?jobid=TEXT&summary jobs?jobid=TEXT&status or jobs?jobid=TEXT&db or jobs?jobid=TEXT&bm or jobs?jobid=TEXT&system or jobs?jobid=TEXT&timestamp or jobs?jobid=TEXT&dict or jobs?jobid=TEXT&vu=INTEGER or jobs?jobid=TEXT&result or jobs?jobid=TEXT&timing or jobs?jobid=TEXT&delete jobs?profileid=INTEGER&profiledata" 
        wapp-2-json 2 $jsondict
        return
      }
    }
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
    set joboutput [ hdbjobs eval {select JOBTCOUNT.timestamp, counter from JOBTCOUNT WHERE JOBTCOUNT.JOBID=$jobid order by JOBTCOUNT.timestamp asc} ]
    dict append jobtcount $jobheader $joboutput
    if { $jobheader eq "" && $joboutput eq "" } {
      set jobtcount [ list $jobid "Jobid has no transaction counter data" ]
    }
    return $jobtcount
  }

  proc getjobmetrics { jobid } {
    set jobmetric [ dict create ]
    hdbjobs eval {select JOBMETRIC.timestamp, usr, sys, irq, idle from JOBMETRIC WHERE JOBMETRIC.JOBID=$jobid order by JOBMETRIC.timestamp asc} {
    set metrics "usr% $usr sys% $sys irq% $irq idle% $idle" 
	if { [dict keys $jobmetric $timestamp] eq {} } {
    	dict append jobmetric $timestamp $metrics
		}
	}
    if { $jobmetric eq "" } {
      set jobmetric [ list $jobid "Jobid has no metric data" ]
    }
    return $jobmetric
  }

  proc getjobsystem { jobid } {
    set jobsystem [ dict create ]
	hdbjobs eval {select hostname,cpumodel,cpucount FROM JOBSYSTEM WHERE JOBID=$jobid} {
        dict append jobsystem $cpumodel $cpucount
	}
    if { $jobsystem eq "" } {
      set jobsystem [ list $jobid "Jobid has no system data" ]
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
            foreach colour {color1 color2} {set $colour [ dict get $chartcolors $dbdescription $colour ]}
            if { $dbdescription eq "MSSQLServer" } { set dbdescription "SQL Server" }
            set qsetcount [ llength [regexp -all -inline (?=Geometric) $chartdata] ]
            #Create chart and insert into JOBCHART for future retrieval
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
            $bar SetOptions -title [ subst {text "$dbdescription TPROC-H Result $jobid $date"} ] -tooltip {show "True"} -legend {bottom "5%" left "45%"}
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
            $bar SetOptions -title [ subst {text "$dbdescription TPROC-C Result $jobid $date"} ] -tooltip {show "True"} -legend {bottom "5%" left "45%"}
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
            set ::ticklecharts::htmlstdout "True" ; 
            $bar SetOptions -title [ subst {text "$dbdescription TPROC-H Power Query Times $jobid $date"} ] -tooltip {show "True"} -legend {bottom "5%" left "45%"}
            $bar Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
            $bar Yaxis -name "Seconds" -position "left" -axisLabel {formatter {"{value}"}}
            $bar Add "barSeries" -name "VU 1 Query Set" -data [list $barseries ] -itemStyle [ subst {color $color1 opacity 0.90} ]
            set html [ $bar toHTML -title "$jobid Query Times" ]
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
            $bar SetOptions -title [ subst {text "$dbdescription TPROC-C Response Times $jobid $date"} ] -tooltip {show "True"} -legend {bottom "5%" left "30%"}
            $bar Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
            $bar Yaxis -name "Milliseconds" -position "left" -axisLabel {formatter {"{value}"}}
            $bar Add "barSeries" -name P50_MS -data [list "$P50_MS "]    
            $bar Add "barSeries" -name P95_MS -data [list "$P95_MS "]    
            $bar Add "barSeries" -name P99_MS -data [list "$P99_MS "]    
            $bar Add "barSeries" -name AVG_MS -data [list "$AVG_MS "]    
            set html [ $bar toHTML -title "$jobid Response Times" ]
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
          $line SetOptions -title [ subst {text "$dbdescription $workload Count $jobid $date"} ] -tooltip {show "True"} -legend {bottom "5%" left "40%"}
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
          hdbjobs eval {SELECT cpucount,cpumodel from JOBSYSTEM WHERE JOBID=$jobid} {
	  set dbdescription "$cpucount $cpumodel"
		}
	if {[ dict size $chartdata ] <= 1} {
          putscli "Chart for jobid $jobid not available, Jobid has insufficient metrics data"
	  return
	}
	  set axisname "CPU %"
          set xaxisvals [ dict keys $chartdata ]
          dict for {tstamp cpuvalues} $chartdata {
          dict with cpuvalues {
            lappend usrseries ${usr%}
            lappend sysseries ${sys%}
            lappend irqseries ${irq%}
          }}
          #Delete the first and trailing values if usr utilisation is 0, so we start from the first measurement and only chart when running
          if { [ lindex $usrseries 0 ] eq 0.0 } {
            set usrseries [ lreplace $usrseries 0 0 ]
            set sysseries [ lreplace $sysseries 0 0 ]
            set irqseries [ lreplace $irqseries 0 0 ]
            set xaxisvals [ lreplace $xaxisvals 0 0 ]
          }
          while { [ lindex $usrseries end ] eq 0.0 } {
            set usrseries [ lreplace $usrseries end end ]
            set sysseries [ lreplace $sysseries end end ]
            set irqseries [ lreplace $irqseries end end ]
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
          $line SetOptions -title [ subst {text "$dbdescription $jobid"} ] \
                           -tooltip {show "True"} \
                           -legend [list bottom "5%" left "40%" selected $irqJS]
          $line Xaxis -data [list $xaxisvals] -axisLabel [list show "True"]
          $line Yaxis -name "$axisname" -position "left" -axisLabel {formatter {"{value}"}}
          $line Add "lineSeries" -name "usr%" -data [ list $usrseries ] -itemStyle [ subst {color green opacity 0.90} ]
          $line Add "lineSeries" -name "sys%" -data [ list $sysseries ] -itemStyle [ subst {color red opacity 0.90} ]
	        # 'irqseries' is included but hidden by default with 'showIrqSeries' variable set.
          $line Add "lineSeries" -name $irqSeriesName -data [ list $irqseries ] -itemStyle [ subst {color blue opacity 0.90} ]
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
      default {
        set html "Error: chart type should be metrics, profile, result, tcount or timing"
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
        puts "Error: Usage: \[ jobs | jobs format | jobs jobid | jobs jobid command | jobs jobid command option | jobs profileid | jobs profileid id\] - type \"help jobs\""
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
      } elseif { [ dict keys $paramdict ] eq "allresults" } {
        set alljobs [ hdbjobs eval {SELECT DISTINCT JOBID FROM JOBMAIN} ]
	  set huddleobj [ huddle create ]
        foreach jobres $alljobs {	
    	hdbjobs eval {SELECT bm, db, timestamp FROM JOBMAIN WHERE JOBID=$jobres} {
	set jobresult [ getjobresult $jobres 1 ]
    if { [ lindex $jobresult 1 ] eq "Jobid has no test result" } {
#NO RESULT 
	set huddleobj [ huddle combine $huddleobj [ huddle compile {dict} $jobresult ]]
        continue
      } elseif { [ string match "Geometric*" [ lindex $jobresult 2 ] ] } {
#TPROC-H RESULT only report first result for first VU
        set ctind 0
        foreach ct {jobid tstamp geomean queryset} {
          set $ct [ lindex $jobresult $ctind ]
          incr ctind
        }
        set numbers [regexp -all -inline -- {[0-9]*\.?[0-9]+} $geomean]
        set geo [ lindex $numbers 1]
        set queries [ lindex $numbers 0]
        set numbers [regexp -all -inline -- {[0-9]*\.?[0-9]+} $queryset]
	set querysets [ lindex $numbers 0]
	set querytime [ lindex $numbers 1]
	set tprochresult [list $jobres [ subst {db $db bm $bm tstamp {$timestamp} queries $queries querysets $querysets geomean $geo querytime $querytime} ]]
	set huddleobj [ huddle combine $huddleobj [ huddle compile {dict * dict} $tprochresult ]]
        continue
      } elseif { [ string match "TEST RESULT*" [ lindex $jobresult 3 ] ] } {
#TPROC-C RESULT 
        lassign [ getnopmtpm $jobresult ] jobid tstamp activevu nopm tpm dbdescription
        set avu [regexp -all -inline -- {[0-9]*\.?[0-9]+} $activevu]
	set tproccresult [list $jobres [ subst {db $db bm $bm tstamp {$timestamp} activevu $avu nopm $nopm tpm $tpm} ]]
	set huddleobj [ huddle combine $huddleobj [ huddle compile {dict * dict} $tproccresult ]]
        continue
}}}
                  if { $outputformat eq "JSON" } {
                  puts [ huddle jsondump $huddleobj ]
                  } else {
                    puts [ huddle get_stripped $huddleobj ]
                  }
      } elseif { [ dict keys $paramdict ] eq "alltimestamps" } {
        set alljobs [ hdbjobs eval {SELECT DISTINCT JOBID FROM JOBMAIN} ]
	  set huddleobj [ huddle create ]
          foreach jobres $alljobs {
 		set joboutput [ hdbjobs eval {SELECT jobid, timestamp FROM JOBMAIN WHERE JOBID=$jobres} ]
		set huddleobj [ huddle combine $huddleobj [ huddle compile {dict} $joboutput ]]
		}
                  if { $outputformat eq "JSON" } {
                  puts [ huddle jsondump $huddleobj ]
                  } else {
                    puts [ huddle get_stripped $huddleobj ]
                  }
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
      if { [ dict keys $paramdict ] eq "jobid vu" || [ dict keys $paramdict ] eq "jobid status" || [ dict keys $paramdict ] eq "jobid result" || [ dict keys $paramdict ] eq "jobid delete" || [ dict keys $paramdict ] eq "jobid timestamp" || [ dict keys $paramdict ] eq "jobid dict" || [ dict keys $paramdict ] eq "jobid timing" || [ dict keys $paramdict ] eq "jobid db" ||  [ dict keys $paramdict ] eq "jobid bm" || [ dict keys $paramdict ] eq "jobid tcount"  || [ dict keys $paramdict ] eq "jobid metrics"  ||  [ dict keys $paramdict ] eq "jobid system" } {
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
            set joboutput [ hdbjobs eval {DELETE FROM JOBMETRIC WHERE JOBID=$jobid} ]
            set joboutput [ hdbjobs eval {DELETE FROM JOBSYSTEM WHERE JOBID=$jobid} ]
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
                  #huddle JSON is dict return here
                  set huddleobj [ huddle compile {dict} $joboutput ]
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
                    if { [ dict keys $paramdict ] eq "jobid metrics" } {
                      set jsondict [ getjobmetrics $jobid ]
                      #huddle JSON is dict*dict return here
                      set huddleobj [ huddle compile {dict * dict} $jsondict ]
                      if { $outputformat eq "JSON" } {
                        puts [ huddle jsondump $huddleobj ]
                      } else {
                        puts $jsondict
                      }
                      return
                  } else {
                    if { [ dict keys $paramdict ] eq "jobid system" } {
                      set jsondict [ getjobsystem $jobid ]
                      #huddle JSON is dict*dict return here
                      set huddleobj [ huddle compile {list} $jsondict ]
                      if { $outputformat eq "JSON" } {
                        puts [ huddle jsondump $huddleobj ]
                      } else {
                        puts $jsondict
                      }
                      return
                    } else {
                      if { [ dict keys $paramdict ] eq "jobid db" } {
                      #A Timed run will include a query for a version string, add the version if we find it
		      set temp_output [ join [ hdbjobs eval {SELECT OUTPUT FROM JOBOUTPUT WHERE JOBID=$jobid AND VU=1} ]]
		      if { [ string match "*DBVersion*" $temp_output ] } {
        		set matcheddbversion [regexp {(DBVersion:)(\d.+?)\s} $temp_output match header version ]
			if { $matcheddbversion } {
                        set joboutput "[ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]] $version"
			} else {
                        set joboutput "[ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]"
			}
			} else {
                        set joboutput "[ join [ hdbjobs eval {SELECT db FROM JOBMAIN WHERE JOBID=$jobid} ]]"
			}
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
        puts "Jobs Two Parameter Usage: jobs jobid status or jobs jobid db or jobs jobid bm or jobid system or jobs jobid timestamp or jobs jobid dict or jobs jobid vuid or jobs jobid result or jobs jobid timing or jobs jobid delete or jobs jobid metrics or jobs jobid system"
        return
      }
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
}
namespace import jobs::*
