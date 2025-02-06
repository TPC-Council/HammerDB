proc find_config_dir {} {
#Find a Valid XML Config Directory using info script, argv, current directory and zipfilesystem
 if [ catch {set ISConfigDir [ file join  {*}[ lrange [ file split [ file normalize [ file dirname [ info script ] ]]] 0 end-2 ] config ]} message ] { set ISConfigDir "" }
#Running under Python argv0 does not exist and will error if referenced
if { [ info exists argv0 ] } {
set AGConfigDir [ file join  {*}[ file split [ file normalize [ file dirname $argv0 ]]] config ]
        } else {
set AGConfigDir .
        }
set PWConfigDir [ file join [ pwd ] config ]
if { [ lindex [zipfs mount] 0 ] eq "//zipfs:/app" } {
set ZIConfigDir [ file join [zipfs root]/app config ]
   } else {
set ZIConfigDir ""
 }
foreach CD { ISConfigDir AGConfigDir PWConfigDir ZIConfigDir } {
        if { [ file isdirectory [ set $CD ]] } {
        if { [ file exists [ file join [ set $CD ] generic.xml ]] && [ file exists [ file join [ set $CD ] database.xml ]] } {
             return [ set $CD ]
        }
    }
}
return "FNF"
}

proc find_exec_dir {} {
#Find a Valid XML Config Directory using info script, argv, current directory and zipfilesystem
if [ catch {set ISExecDir [ file join  {*}[ lrange [ file split [ file normalize [ file dirname [ info script ] ]]] 0 end-2 ]]} message ] { set ISExecDir "" }
#Running under Python argv0 does not exist and will error if referenced
if { [ info exists argv0 ] } {
set AGExecDir [ file join  {*}[ file split [ file normalize [ file dirname $argv0 ]]]]
        } else {
set AGExecDir .
        }
set PWExecDir [ pwd ]
if { [ lindex [zipfs mount] 0 ] eq "//zipfs:/app" && $tcl_platform(platform) == "windows" } {
	set ftail ".exe"
   } else {
	set ftail ""
   }
foreach CD { ISExecDir AGExecDir PWExecDir } {
        if { [ file isdirectory [ set $CD ]] } {
        if { [ file exists [ file join [ set $CD ] hammerdb$ftail ]] && [ file exists [ file join [ set $CD ] hammerdbcli$ftail ]] && [ file exists [ file join [ set $CD ] hammerdbws$ftail ]] } {
             return [ set $CD ]
        }
    }
}
return "FNF"
}

proc get_xml_data {} {
#proc get_xml_data not called when using SQLite
    global rdbms bm virtual_users maxvuser delayms conpause ntimes suppo optlog apmode apduration apsequence unique_log_name no_log_buffer log_timestamps interval hostname id agent_hostname agent_id highlight quote_passwords gen_count_ware gen_scale_fact gen_directory gen_num_vu 
    set dirname [ file dirname [ file normalize $argv0 ]]
    if { $dirname eq "[zipfs root]app" } {
    #Is a zip directory
    set dirname [ file dirname [ lindex [ split [ zipfs mount ]] end ]]
    }
    if {[catch {set xml_fd [open "$dirname/config/generic.xml" r]}]} {
        puts "Could not open XML config file using default values"
        return
    } else {
        set xml "[read $xml_fd]"
        close $xml_fd
    }
    ::XML::Init $xml
    set wellFormed [::XML::IsWellFormed]
    if {$wellFormed ne ""} {
        puts "The xml is not well-formed: $wellFormed"
    } else {
        puts "The xml is well-formed, applying configuration"
        while {1} {
            foreach {type val attr etype} [::XML::NextToken] break
            #puts "looking at: $type '$val' '$attr' '$etype'"
            if {$type == "XML" && $etype == "START"} {
                set myvariable $val
                switch $myvariable {
                    user_delay { set myvariable delayms }
                    repeat_delay { set myvariable conpause }
                    iterations { set myvariable ntimes }
                    show_output { set myvariable suppo }
                    log_to_temp { set myvariable optlog }
                    refresh_rate { set myvariable interval }
                    autopilot_mode { set myvariable apmode }
                    autopilot_duration { set myvariable apduration }
                    autopilot_sequence { set myvariable apsequence }
                }
            } else {
                if {$type == "XML" && $etype == "END"} { 
                    unset -nocomplain myvariable 
                } else {
                    if {$type == "TXT" && $etype == "" && [info exists myvariable] } { 
                        set [ set myvariable ] $val
                    }
                }
            } 
            if {$type == "EOF"} break
        }
    }
}

proc xmlopts {} {
    #Placeholder procedure for enabling of Save Configuration button
    global rdbms
    puts "This function to write out XML data for database $rdbms"
}

proc set_global_config {genericdict} {
    global rdbms bm virtual_users maxvuser delayms conpause ntimes suppo optlog apmode apduration apsequence unique_log_name no_log_buffer log_timestamps interval hostname id agent_hostname agent_id highlight quote_passwords gen_count_ware gen_scale_fact gen_directory gen_num_vu 

    if { $genericdict eq "" } {
        puts "Error: empty genericdict"
    }

    dict for {key attributes} $genericdict {
        set tablename $key
        dict for {subkey subattributes} $attributes {
            set myvariable $subkey
            switch $myvariable {
                user_delay { set myvariable delayms }
                repeat_delay { set myvariable conpause }
                iterations { set myvariable ntimes }
                show_output { set myvariable suppo }
                log_to_temp { set myvariable optlog }
                refresh_rate { set myvariable interval }
                autopilot_mode { set myvariable apmode }
                autopilot_duration { set myvariable apduration }
                autopilot_sequence { set myvariable apsequence }
            }
            set [ set myvariable ] $subattributes
        }
    }
}

proc Dict2SQLite {dbname dbdict} {
    set sqlitedb [ CheckSQLiteDB $dbname ]

    if [catch {sqlite3 hdb $sqlitedb} message ] {
        puts "Error initializing SQLite database : $message"
        return
    } else {
        catch {hdb timeout 30000}
        #puts "Initializing SQLite database : $sqlitedb"
        if { $sqlitedb ne "" } {
            dict for {key attributes} $dbdict {
                set tablename $key
                set sqlcmd "DROP TABLE $tablename"
                catch {hdb eval $sqlcmd}
                set sqlcmd "CREATE TABLE $tablename\(key TEXT, val TEXT)"
                if [catch {hdb eval $sqlcmd} message ] {
                    puts "Error creating $tablename table in $sqlitedb : $message"
                    return
                }
                dict for {subkey subattributes} $attributes {
                    set sqlcmd "INSERT INTO $tablename\(key, val) VALUES(\'$subkey\', \'$subattributes\')"
                    hdb eval $sqlcmd
                    #puts "sqlcmd: $sqlcmd\n"
                }
            }
        }
    }
}

proc SQLiteUpdateKeyValue {dbname table keyname value} {
    set sqlitedb [ CheckSQLiteDB $dbname ]
  
    if [catch {sqlite3 hdb $sqlitedb} message ] {
        puts "Error initializing SQLite database : $message"
        return
    } else {
        catch {hdb timeout 30000}
        if { $sqlitedb ne "" } {
            set sqlcmd "UPDATE $table SET val = \'$value\' WHERE key = \'$keyname\'"
            if [catch {hdb eval $sqlcmd} message ] {
                puts "Error creating $table table in $sqlitedb : $message"
                return
            }
        }
    }
    return
}

proc SQLite2Dict {dbname} {
    set sqlitedb [ CheckSQLiteDB $dbname ]

    if { $sqlitedb eq "" || ![file exists $sqlitedb] } {
        #puts "No $sqlitedb found."
        return
    }
    
    if [catch {sqlite3 hdb $sqlitedb} message ] {
        puts "Error initializing SQLite database : $message"
        return
    } else {
        catch {hdb timeout 30000}
        set sqlcmd "SELECT tbl_name FROM sqlite_master WHERE type=table"
        catch {hdb eval $sqlcmd}
        if [catch {set tbllist [ hdb eval {SELECT name FROM sqlite_master WHERE type='table'}]} message ] {
            puts "Error querying table name in SQLite on-disk database : $message"
            return
        } else {
            set maindict [ dict create ]
            foreach tbl $tbllist {
                set subdict [ dict create ]
                set sqlcmd "SELECT key, val FROM $tbl"
                hdb eval $sqlcmd {
                    dict append subdict $key $val
                }
                dict append maindict $tbl $subdict
            }
            return $maindict
        }
    }
}

proc CheckSQLiteDB {dbname} {
    global sqlitedb_dir

    if {$sqlitedb_dir eq ""} {
        #Parameter sqlitedb_dir in generic.xml is empty. Use temp directory
        set sqlitedb_dir "TMP"
    }

    if {$sqlitedb_dir ne "TMP"} {
        if {(![file exists $sqlitedb_dir]) || 
            (![file readable $sqlitedb_dir]) ||
            (![file writable $sqlitedb_dir])} {
            puts "Access $sqlitedb_dir exception. Use temp directory."
            set tmpdir [ findtempdir ]
        } else {
            set tmpdir $sqlitedb_dir
        }
    } else {
        set tmpdir [ findtempdir ]
    }

    if { $tmpdir != "notmpdir" } {
        set sqlitedb [ file join $tmpdir "$dbname\.db" ]
    } else {
        puts "Error Database Directory set to TMP but couldn't find temp directory"
        return
    }

    return $sqlitedb
}

proc SetKeyAsFirst { olddict keyname } {
    if { [ dict exists $olddict $keyname ] } {
        set val [ dict get $olddict $keyname ]
        dict remove $olddict $keyname
        set newdict [ dict create $keyname $val ]
        return [ dict merge $newdict $olddict ]
    } else {
        return
    }
}
