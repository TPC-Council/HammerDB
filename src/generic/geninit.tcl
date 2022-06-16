package require sqlite3

#Get generic config data
set genericdict [ ::XML::To_Dict config/generic.xml ]

#Get global variable sqlitedb_dir from generic.xml
if { [ dict exists $genericdict sqlitedb sqlitedb_dir ] } {
    set sqlitedb_dir [ dict get $genericdict sqlitedb sqlitedb_dir ]
} else {
    set sqlitedb_dir ""
}

#Get xml_schema_version
if { [ dict exists $genericdict xml_schema version ] } {
    set xml_schema_version [ dict get $genericdict xml_schema version ]
} else {
    set xml_schema_version ""
}

#Try to get generic config data from SQLite
set genericdictdb [ SQLite2Dict "generic" ]
if { $genericdictdb eq "" } {
    #No SQLite found, save genericdict from XML to SQLite
    Dict2SQLite "generic" $genericdict
} else {
    if { [ dict exists $genericdictdb xml_schema version ] } {
        set db_schema_version [ dict get $genericdictdb xml_schema version ]
    } else {
        set db_schema_version ""
    }

    #SQLite found, check whether the schema versions from SQLite and XML are consistent
    if { $xml_schema_version ne $db_schema_version } {
        puts "The existed SQLite DBs are incompatible with current HammerDB. SQLite DBs will be cleared."
        foreach { dbname } { generic database db2 mariadb mssqlserver mysql oracle postgresql } {
            set dbfile [ CheckSQLiteDB $dbname ]
            #Remove SQLite file, if need to keep old file, use 'file rename'
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
set_globle_config $genericdict

#Make generics global
tsv::set application genericdict $genericdict
#Complete GUI using database config
disable_bm_menu
guid_init

