package require sqlite3

#Get generic config data
set genericdict [ ::XML::To_Dict config/generic.xml ]

#Get global variable sqlitedb_dir from generic.xml
if { [ dict exists $genericdict sqlitedb sqlitedb_dir ] } {
  set sqlitedb_dir [ dict get $genericdict sqlitedb sqlitedb_dir ]
} else {
  set sqlitedb_dir ""
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
  lappend dbsrclist "$key/$prefix\opt.tcl" "$key/$prefix\oltp.tcl" "$key/$prefix\olap.tcl" "$key/$prefix\otc.tcl"
}

#Get generic config data
set genericdictdb [ SQLite2Dict "generic" ]
if { $genericdictdb eq "" } {
  Dict2SQLite "generic" $genericdict
} else {
  set genericdict $genericdictdb
}

#get_xml_data
set_globle_config $genericdict

#Make generics global
tsv::set application genericdict $genericdict
guid_init