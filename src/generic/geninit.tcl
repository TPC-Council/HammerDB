global hdb_version

proc find_config_dir {} {
#Find a Valid XML Config Directory using info script, argv, current directory and zipfilesystem
set ISConfigDir [ file join  {*}[ lrange [ file split [ file normalize [ file dirname [ info script ] ]]] 0 end-2 ] config ]
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

set dirname [ find_config_dir ]
if { $dirname eq "FNF" } {
        puts "Error: Cannot find a Valid XML Config Directory"
        exit
}

#Get generic config data
if { [ file exists $dirname/generic.xml ] } {
set genericdict [ ::XML::To_Dict $dirname/generic.xml ]
        } else {
set genericdict {}
        }
#Get global variable sqlitedb_dir from generic.xml
if { [ dict exists $genericdict sqlitedb sqlitedb_dir ] } {
    set sqlitedb_dir [ dict get $genericdict sqlitedb sqlitedb_dir ]
} else {
    set sqlitedb_dir ""
}

#Set hammerdb version to genericdict
set hdb_version_dict [ dict create version $hdb_version ]
if { [ dict size $genericdict ] != 0 } {
dict append genericdict hdb_version $hdb_version_dict
	}

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
	#Close SQLite before deleting else get permission denied on Windows
	if { [catch {hdb close} message]} { 
		puts "Failed to close SQLite: $message" 
	}
        foreach { dbname } { generic database db2 mariadb mssqlserver mysql oracle postgresql } {
            set dbfile [ CheckSQLiteDB $dbname ]
            #Remove SQLite file
	    if { [catch {file delete $dbfile} message]} { 
		    puts "Error deleting SQLite file from $sqlite_hdb_version: $message" 
	    }
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
    set dbdict [ ::XML::To_Dict $dirname/database.xml ]

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
        set dbconfdict [ ::XML::To_Dict $dirname/$key.xml ]
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

#Init hammer.db for storing job information
init_job_tables_gui

#Complete GUI using database config
disable_bm_menu
guid_init
