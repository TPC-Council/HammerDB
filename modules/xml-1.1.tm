##+##########################################################################
 #
 # xml.tcl -- Simple XML parser
 # by Keith Vetter, March 2004
 #
package provide xml 1.1

namespace eval ::XML { variable XML "" loc 0}

 proc ::XML::Init {xmlData} {
    variable XML
    variable loc

    set XML [string trim $xmlData];
    regsub -all {<!--.*?-->} $XML {} XML        ;# Remove all comments
    set loc 0
 }

 # Returns {XML|TXT|EOF|PI value attributes START|END|EMPTY}
 proc ::XML::NextToken {{peek 0}} {
    variable XML
    variable loc

    set n [regexp -start $loc -indices {(.*?)\s*?<(/?)(.*?)(/?)>} \
               $XML all txt stok tok etok]
    if {! $n} {return [list EOF]}
    foreach {all0 all1} $all {txt0 txt1} $txt \
        {stok0 stok1} $stok {tok0 tok1} $tok {etok0 etok1} $etok break

    if {$txt1 >= $txt0} {                       ;# Got text
        set txt [string range $XML $txt0 $txt1]
        if {! $peek} {set loc [expr {$txt1 + 1}]}
        return [list TXT $txt]
    }

    set token [string range $XML $tok0 $tok1]   ;# Got something in brackets
    if {! $peek} {set loc [expr {$all1 + 1}]}
    if {[regexp {^!\[CDATA\[(.*)\]\]} $token => txt]} { ;# Is it CDATA stuff?
        return [list TXT $txt]
    }

    # Check for Processing Instruction <?...?>
    set type XML
    if {[regexp {^\?(.*)\?$} $token => token]} {
        set type PI
    }
    set attr ""
    regexp {^(.*?)\s+(.*?)$} $token => token attr

    set etype START                             ;# Entity type
    if {$etok0 <= $etok1} {
        if {$stok0 <= $stok1} { set token "/$token"} ;# Bad XML
        set etype EMPTY
    } elseif {$stok0 <= $stok1} {
        set etype END
    }
    return [list $type $token $attr $etype]
 }
 # ::XML::IsWellFormed
 #  checks if the XML is well-formed )http://www.w3.org/TR/1998/REC-xml-19980210)
 #
 # Returns "" if well-formed, error message otherwise
 # missing:
 #  characters: doesn't check valid extended characters
 #  attributes: doesn't check anything: quotes, equals, unique, etc.
 #  text stuff: references, entities, parameters, etc.
 #  doctype internal stuff
 #
 proc ::XML::IsWellFormed {} {
    set result [::XML::_IsWellFormed]
    set ::XML::loc 0
    return $result
 }
 ;proc ::XML::_IsWellFormed {} {
    array set emsg {
        XMLDECLFIRST "The XML declaration must come first"
        MULTIDOCTYPE "Only one DOCTYPE is allowed"
        INVALID "Invalid document structure"
        MISMATCH "Ending tag '$val' doesn't match starting tag"
        BADELEMENT "Bad element name '$val'"
        EOD "Only processing instructions allowed at end of document"
        BADNAME "Bad name '$val'"
        BADPI "No processing instruction starts with 'xml'"
    }

    # [1] document ::= prolog element Misc*
    # [22] prolog ::= XMLDecl? Misc* (doctypedecl Misc*)?
    # [27] Misc ::= Comment | PI | S
    # [28] doctypedecl ::= <!DOCTYPE...>
    # [16] PI ::= <? Name ...?>
    set seen 0                                  ;# 1 xml, 2 pi, 4 doctype
    while {1} {
        foreach {type val attr etype} [::XML::NextToken] break
        if {$type eq "PI"} {
            if {! [regexp {^[a-zA-Z_:][a-zA-Z0-9.-_:\xB7]+$} $val]} {
                return [subst $emsg(BADNAME)]
            }
            if {$val eq "xml"} {                ;# XMLDecl
                if {$seen != 0} { return $emsg(XMLDECLFIRST) }
                # TODO: check version number exist and only encoding and
                # standalone attributes are allowed
                incr seen                       ;# Mark as seen XMLDecl
                continue
            }
            if {[string equal -nocase "xml" $val]} {return $emsg(BADPI)}
            set seen [expr {$seen | 2}]         ;# Mark as seen PI
            continue
        } elseif {$type eq "XML" && $val eq "!DOCTYPE"} { ;# Doctype
            if {$seen & 4} { return $emsg(MULTIDOCTYPE) }
            set seen [expr {$seen | 4}]
            continue
        }
        break
    }

    # [39] element ::= EmptyElemTag | STag content ETag
    # [40] STag ::= < Name (S Attribute)* S? >
    # [42] ETag ::= </ Name S? >
    # [43] content ::= CharData? ((element | Reference | CDSect | PI | Comment) CharData?)*
    # [44] EmptyElemTag ::= < Name (S Attribute)* S? />
    #

    set stack {}
    set first 1
    while {1} {
        if {! $first} {                         ;# Skip first time in
            foreach {type val attr etype} [::XML::NextToken] break
        } else {
            if {$type ne "XML" && $type ne "EOF"} { return $emsg(INVALID) }
            set first 0
        }

        if {$type eq "EOF"} break
        ;# TODO: check attributes: quotes, equals and unique

        if {$type eq "TXT"} continue
        if {! [regexp {^[a-zA-Z_:][a-zA-Z0-9.-_:\xB7]+$} $val]} {
            return [subst $emsg(BADNAME)]
        }

        if {$type eq "PI"} {
            if {[string equal -nocase xml $val]} { return $emsg(BADPI) }
            continue
        }
        if {$etype eq "START"} {                ;# Starting tag
            lappend stack $val
        } elseif {$etype eq "END"} {            ;# </tag>
            if {$val ne [lindex $stack end]} { return [subst $emsg(MISMATCH)] }
            set stack [lrange $stack 0 end-1]
            if {[llength $stack] == 0} break    ;# Empty stack
        } elseif {$etype eq "EMPTY"} {          ;# <tag/>
        }
    }

    # End-of-Document can only contain processing instructions
    while {1} {
        foreach {type val attr etype} [::XML::NextToken] break
        if {$type eq "EOF"} break
        if {$type eq "PI"} {
            if {[string equal -nocase xml $val]} { return $emsg(BADPI) }
            continue
        }
        return $emsg(EOD)
    }
    return ""
}

proc ::XML::To_Dict { xml_file } {
#XML to dict squashes config data to 2 level dict
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

proc ::XML::To_Dict_Ml { xml_file } {
#XML to dict ml returns up to 5 levels as parsed
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
# puts "$refctr"
	if { $refctr > 5 } {
	puts "Error parsing XML $xml_file: too many levels $refctr"
	break 
	}
        set myvariable $val
	if {$refctr == 1} {
	set dictname $val
	}
	if {$refctr == 2} {
	set 2ndlevel $val
	}
	if {$refctr == 3} {
	set 3rdlevel $val
	}
	if {$refctr == 4} {
	set 4thlevel $val
	}
	if {$refctr == 5} {
	set 5thlevel $val
	}
    } else {
       if {$type == "XML" && $etype == "END"} {
    unset -nocomplain myvariable
        incr refctr -1
                } else {
if {$type == "TXT" && $etype == "" && [info exists myvariable] } {
 if {$refctr == 3} {
	dict set $dictname $2ndlevel $myvariable $val
        }
 if {$refctr == 4} {
	dict set $dictname $2ndlevel $3rdlevel $myvariable $val
	}
 if {$refctr == 5} {
	dict set $dictname $2ndlevel $3rdlevel $4thlevel $myvariable $val
	}
                        }
                }
        }
       if {$type == "EOF"} break
    }
  }
return [ set $dictname ]
}
