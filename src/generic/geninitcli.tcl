#Load database config
set dbdict [ ::XML::To_Dict config/database.xml ]
set dbdict [ regsub -all {(TP)(RO)(C-[CH])} $dbdict {\1\3} ]
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
#Make generics global
tsv::set application genericdict $genericdict
guid_init
