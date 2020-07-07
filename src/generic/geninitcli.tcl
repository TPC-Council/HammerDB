#Load database config
set dbdict [ ::XML::To_Dict config/database.xml ]
#Change formal OSS-TPC-x terminology to working TPC-x
set dbdict [ regsub -all {(OSS-)(TPC-[CH])} $dbdict {\2} ]
#Load database details in dict named configdbname
foreach { key } [ dict keys $dbdict ] {
set dictname config$key
set $dictname [ ::XML::To_Dict config/$key.xml ]
set prefix [ dict get $dbdict $key prefix ]
lappend dbsrclist "$key/$prefix\opt.tcl" "$key/$prefix\oltp.tcl" "$key/$prefix\olap.tcl" "$key/$prefix\otc.tcl"
	}
#Get generic config data
set genericdict [ ::XML::To_Dict config/generic.xml ]
get_xml_data
guid_init
#Make generics global
