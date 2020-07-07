#Load database config
set dbdict [ ::XML::To_Dict config/database.xml ]
#Change formal OSS-TPC-x terminology to working TPC-x
set dbdict [ regsub -all {(OSS-)(TPC-[CH])} $dbdict {\2} ]
#Start the GUI using database config
ed_start_gui $dbdict $icons $iconalt
wm positionfrom .
raise .ed_mainFrame
#Load database details in dict named configdbname
foreach { key } [ dict keys $dbdict ] {
set dictname config$key
set $dictname [ ::XML::To_Dict config/$key.xml ]
set prefix [ dict get $dbdict $key prefix ]
lappend dbsrclist "$key/$prefix\opt.tcl" "$key/$prefix\oltp.tcl" "$key/$prefix\olap.tcl" "$key/$prefix\otc.tcl" "$key/$prefix\met.tcl"
	}
#Get generic config data
set genericdict [ ::XML::To_Dict config/generic.xml ]
get_xml_data
#Make generics global
#Complete GUI using database config
disable_bm_menu
guid_init
