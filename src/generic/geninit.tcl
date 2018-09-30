#Load database config
set dbdict [ xml_to_dict config/database.xml ]
#Start the GUI using database config
ed_start_gui $dbdict $icons $iconalt
wm positionfrom .
raise .ed_mainFrame
#Load database details in dict named configdbname
foreach { key } [ dict keys $dbdict ] {
set dictname config$key
set $dictname [ xml_to_dict config/$key.xml ]
set prefix [ dict get $dbdict $key prefix ]
lappend dbsrclist "$key/$prefix\opt.tcl" "$key/$prefix\oltp.tcl" "$key/$prefix\olap.tcl" "$key/$prefix\otc.tcl" "$key/$prefix\met.tcl"
	}
#Get generic config data
set genericdict [ xml_to_dict config/generic.xml ]
get_xml_data
#Make generics global
#Complete GUI using database config
disable_bm_menu
guid_init
