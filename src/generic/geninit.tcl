package require sqlite3
global hdb_version

#Get generic config data
set genericdict [ ::XML::To_Dict config/generic.xml ]

#Get global variable sqlitedb_dir from generic.xml
if { [ dict exists $genericdict sqlitedb sqlitedb_dir ] } {
    set sqlitedb_dir [ dict get $genericdict sqlitedb sqlitedb_dir ]
} else {
    set sqlitedb_dir ""
}

#Set hammerdb version to genericdict
set hdb_version_dict [ dict create version $hdb_version ]
dict append genericdict hdb_version $hdb_version_dict

#Try to get generic config data from SQLite
set genericdictdb [ SQLite2Dict "generic" ]
if { $genericdictdb eq "" } {
    #No SQLite found, save genericdict from XML to SQLite
    Dict2SQLite "generic" $genericdict
} else {
    if { [ dict exists $genericdictdb hdb_version version ] } {
        set sqlite_hdb_version [ dict get $genericdictdb hdb_version version ]
    } else {
        set sqlite_hdb_version "unknown"
    }

    #SQLite found, check whether the schema versions from SQLite and XML are consistent
    if { $sqlite_hdb_version ne $hdb_version } {
        puts "The existing SQLite DBs are from version $sqlite_hdb_version. SQLite DBs will be reset to $hdb_version."
        foreach { dbname } { generic database db2 mariadb mssqlserver mysql oracle postgresql } {
            set dbfile [ CheckSQLiteDB $dbname ]
            #Remove SQLite file
            file delete $dbfile
        }
        #After remove old SQLite, save genericdict to SQLite DB
        Dict2SQLite "generic" $genericdict
    } else {
        #Use configration from SQLite
        set genericdict $genericdictdb
    }
}

#Load database config from SQLite database.db
set dbdict [ SQLite2Dict "database" ]
if { $dbdict eq "" } {
    #Load database config from database.xml
    set dbdict [ ::XML::To_Dict config/database.xml ]

    #Change  TPROC-x terminology to working TPC-x
    set dbdict [ regsub -all {(TP)(RO)(C-[CH])} $dbdict {\1\3} ]

    #Save XML content to SQLite - database.db
    Dict2SQLite "database" $dbdict
}

#Start the GUI using database config
ed_start_gui $dbdict $icons $iconalt
wm positionfrom .
raise .ed_mainFrame

#Load database details in dict named configdbname
foreach { key } [ dict keys $dbdict ] {
    set dictname config$key
    set dbconfdict [ SQLite2Dict $key ]
    if { $dbconfdict eq "" } {
        set dbconfdict [ ::XML::To_Dict config/$key.xml ]
        Dict2SQLite $key $dbconfdict
    }
    set $dictname $dbconfdict
    set prefix [ dict get $dbdict $key prefix ]
    lappend dbsrclist "$key/$prefix\opt.tcl" "$key/$prefix\oltp.tcl" "$key/$prefix\olap.tcl" "$key/$prefix\otc.tcl" "$key/$prefix\met.tcl"
}

#get_xml_data
set_global_config $genericdict

#Make generics global
tsv::set application genericdict $genericdict

proc init_job_tables { } {
    upvar #0 genericdict genericdict

    if {[dict exists $genericdict sqlitedb sqlitedb_dir ]} {
        set sqlite_db [ dict get $genericdict sqlitedb sqlitedb_dir ]
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
    if [catch {sqlite3 hdbgui $sqlite_db} message ] {
        puts "Error initializing SQLite database : $message"
        return
    } else {
        catch {hdbgui timeout 30000}
        #hdbgui eval {PRAGMA foreign_keys=ON}
        if { $sqlite_db eq ":memory:" } {
            catch {hdbgui eval {DROP TABLE JOBMAIN}}
            catch {hdbgui eval {DROP TABLE JOBTIMING}}
            catch {hdbgui eval {DROP TABLE JOBTCOUNT}}
            catch {hdbgui eval {DROP TABLE JOBOUTPUT}}
            if [catch {hdbgui eval {CREATE TABLE JOBMAIN(jobid TEXT, db TEXT, bm TEXT, jobdict TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')))}} message ] {
                puts "Error creating JOBMAIN table in SQLite in-memory database : $message"
                return
            } elseif [ catch {hdbgui eval {CREATE TABLE JOBTIMING(jobid TEXT, vu INTEGER, procname TEXT, calls INTEGER, min_ms REAL, avg_ms REAL, max_ms REAL, total_ms REAL, p99_ms REAL, p95_ms REAL, p50_ms REAL, sd REAL, ratio_pct REAL, summary INTEGER, elapsed_ms REAL, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
                puts "Error creating JOBTIMING table in SQLite in-memory database : $message"
            } elseif [ catch {hdbgui eval {CREATE TABLE JOBTCOUNT(jobid TEXT, counter INTEGER, metric TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
                puts "Error creating JOBTCOUNT table in SQLite in-memory database : $message"
                return
            } elseif [ catch {hdbgui eval {CREATE TABLE JOBOUTPUT(jobid TEXT, vu INTEGER, output TEXT, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
                puts "Error creating JOBOUTPUT table in SQLite in-memory database : $message"
                return
            } else {
                catch {hdbgui eval {CREATE INDEX JOBMAIN_IDX ON JOBMAIN(jobid)}}
                catch {hdbgui eval {CREATE INDEX JOBTIMING_IDX ON JOBTIMING(jobid)}}
                catch {hdbgui eval {CREATE INDEX JOBTCOUNT_IDX ON JOBTCOUNT(jobid)}}
                catch {hdbgui eval {CREATE INDEX JOBOUTPUT_IDX ON JOBOUTPUT(jobid)}}
                puts "Initialized new SQLite in-memory database"
            }
        } else {
            if [catch {set tblname [ hdbgui eval {SELECT name FROM sqlite_master WHERE type='table' AND name='JOBMAIN'}]} message ] {
                puts "Error querying  JOBOUTPUT table in SQLite on-disk database : $message"
                return
            } else {
                if { $tblname eq "" } {
                    if [catch {hdbgui eval {CREATE TABLE JOBMAIN(jobid TEXT, db TEXT, bm TEXT, jobdict TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')))}} message ] {
                        puts "Error creating JOBMAIN table in SQLite in-memory database : $message"
                        return
                    } elseif [ catch {hdbgui eval {CREATE TABLE JOBTIMING(jobid TEXT, vu INTEGER, procname TEXT, calls INTEGER, min_ms REAL, avg_ms REAL, max_ms REAL, total_ms REAL, p99_ms REAL, p95_ms REAL, p50_ms REAL, sd REAL, ratio_pct REAL, summary INTEGER, elapsed_ms REAL, FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
                        puts "Error creating JOBTIMING table in SQLite in-memory database : $message"
                        return
                    } elseif [ catch {hdbgui eval {CREATE TABLE JOBTCOUNT(jobid TEXT, counter INTEGER, metric TEXT, timestamp DATETIME NOT NULL DEFAULT (datetime(CURRENT_TIMESTAMP, 'localtime')), FOREIGN KEY(jobid) REFERENCES JOBMAIN(jobid))}} message ] {
                        puts "Error creating JOBTCOUNT table in SQLite in-memory database : $message"
                        return
                    } elseif [catch {hdbgui eval {CREATE TABLE JOBOUTPUT(jobid TEXT, vu INTEGER, output TEXT)}} message ] {
                        puts "Error creating JOBOUTPUT table in SQLite on-disk database : $message"
                        return
                    } else {
                        catch {hdbgui eval {CREATE INDEX JOBMAIN_IDX ON JOBMAIN(jobid)}}
                        catch {hdbgui eval {CREATE INDEX JOBTIMING_IDX ON JOBTIMING(jobid)}}
                        catch {hdbgui eval {CREATE INDEX JOBTCOUNT_IDX ON JOBTCOUNT(jobid)}}
                        catch {hdbgui eval {CREATE INDEX JOBOUTPUT_IDX ON JOBOUTPUT(jobid)}}
                        puts "Initialized new SQLite on-disk database $sqlite_db"
                    }
                } else {
                    puts "Initialized SQLite on-disk database $sqlite_db using existing tables"
                }
            }
        }
    }
}

#Init hammer.db for storing job information
init_job_tables

#Complete GUI using database config
disable_bm_menu
guid_init



