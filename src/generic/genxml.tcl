proc get_xml_data {} {
global rdbms bm virtual_users maxvuser delayms conpause ntimes suppo optlog apmode apduration apsequence unique_log_name no_log_buffer log_timestamps interval hostname id agent_hostname agent_id highlight gen_count_ware gen_scale_fact gen_directory gen_num_vu 
if {[catch {set xml_fd [open "config/generic.xml" r]}]} {
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
