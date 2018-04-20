proc xml_to_dict { xml_file } {
if {[catch {set xml_fd [open "$xml_file" r]}]} {
     puts "Could not open XML file $xml_file"
     return 1
                } else {
set xml "[read $xml_fd]"
close $xml_fd
    }
 ::XML::Init $xml
 set wellFormed [::XML::IsWellFormed]
 if {$wellFormed ne ""} {
    puts "The xml is in $xml_file is not well-formed: $wellFormed"
return
 } else {
#    puts "The xml in $xml_file is well-formed, applying variables"
       set refctr 0
    while {1} {
       foreach {type val attr etype} [::XML::NextToken] break
       if {$type == "XML" && $etype == "START"} {
        incr refctr
        set myvariable $val
	if {$refctr == 1} {
	set dictname $val
	}
	if {$refctr == 2} {
	set 2ndlevel $val
	}
    } else {
       if {$type == "XML" && $etype == "END"} {
    unset -nocomplain myvariable
        incr refctr -1
                } else {
if {$type == "TXT" && $etype == "" && [info exists myvariable] } {
	dict set $dictname $2ndlevel $myvariable $val
                        }
                }
        }
       if {$type == "EOF"} break
    }
  }
return [ set $dictname ]
}
