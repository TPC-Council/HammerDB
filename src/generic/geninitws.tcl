#Load database config
set dbdict [ xml_to_dict config/database.xml ]
#Load database details in dict named configdbname
foreach { key } [ dict keys $dbdict ] {
set dictname config$key
set $dictname [ xml_to_dict config/$key.xml ]
set prefix [ dict get $dbdict $key prefix ]
lappend dbsrclist "$key/$prefix\opt.tcl" "$key/$prefix\oltp.tcl" "$key/$prefix\olap.tcl" "$key/$prefix\otc.tcl"
	}
#Get generic config data
set genericdict [ xml_to_dict config/generic.xml ]
get_xml_data
guid_init
#Make generics global
