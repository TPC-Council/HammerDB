##+##########################################################################
 #
 # xml.tcl -- Simple XML parser
 # by Keith Vetter, March 2004
 #

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

proc get_xml_data {} {
global rdbms bm instance system_user system_password count_ware tpcc_user tpcc_pass tpcc_def_tab tpcc_def_temp count_ware num_threads plsql partition tpcc_tt_compat directory total_iterations rasieerror keyandthink checkpoint oradriver mysqldriver rampup duration tpch_user tpch_pass tpch_def_tab tpch_def_temp num_tpch_threads tpch_tt_compat scale_fact total_querysets raise_query_error verbose degree_of_parallel refresh_on update_sets trickle_refresh refresh_verbose maxvuser delayms conpause ntimes suppo optlog unique_log_name no_log_buffer unwind connectstr interval autor rac hostname id mysql_host mysql_port my_count_ware mysql_user mysql_pass mysql_dbase storage_engine mysql_partition mysql_num_threads my_total_iterations my_raiseerror my_keyandthink my_rampup my_duration mysql_scale_fact mysql_tpch_user mysql_tpch_pass mysql_tpch_dbase mysql_num_tpch_threads mysql_tpch_storage_engine mysql_refresh_on mysql_total_querysets mysql_raise_query_error mysql_verbose mysql_update_sets mysql_trickle_refresh mysql_refresh_verbose apmode apduration apsequence mssqls_server mssqls_port mssqls_authentication mssqls_odbc_driver mssqls_count_ware mssqls_schema mssqls_num_threads mssqls_uid mssqls_pass mssqls_dbase mssqls_total_iterations mssqls_raiseerror mssqls_keyandthink mssqlsdriver mssqls_rampup mssqls_duration mssqls_checkpoint mssqls_scale_fact mssqls_maxdop mssqls_uid mssqls_pass mssqls_tpch_dbase mssqls_num_tpch_threads mssqls_refresh_on mssqls_total_querysets mssqls_raise_query_error mssqls_verbose mssqls_update_sets mssqls_trickle_refresh mssqls_refresh_verbose pg_host pg_port pg_count_ware pg_superuser pg_superuserpass pg_defaultdbase pg_user pg_pass pg_dbase pg_vacuum pg_dritasnap pg_oracompat pg_num_threads pg_total_iterations pg_raiseerror pg_keyandthink pg_driver pg_rampup pg_duration pg_scale_fact pg_tpch_superuser pg_tpch_superuserpass pg_tpch_defaultdbase pg_tpch_user pg_tpch_pass pg_tpch_dbase pg_tpch_gpcompat pg_tpch_gpcompress pg_num_tpch_threads pg_total_querysets pg_raise_query_error pg_verbose pg_refresh_on pg_update_sets pg_trickle_refresh pg_refresh_verbose redis_host redis_port redis_namespace redis_count_ware redis_num_threads redis_total_iterations redis_raiseerror redis_keyandthink redis_driver redis_rampup redis_duration
if {[catch {set xml_fd [open "config.xml" r]}]} {
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
    puts "The xml in config.xml is well-formed, applying variables"
    while {1} {
       foreach {type val attr etype} [::XML::NextToken] break
       #puts "looking at: $type '$val' '$attr' '$etype'"
       if {$type == "XML" && $etype == "START"} {
	set myvariable $val
	switch $myvariable {
	virtual_users { set myvariable maxvuser }
	user_delay { set myvariable delayms }
	repeat_delay { set myvariable conpause }
	iterations { set myvariable ntimes }
	show_output { set myvariable suppo }
	log_to_temp { set myvariable optlog }
	unwind_threads { set myvariable unwind }
	connect_string { set myvariable connectstr }
	refresh_rate { set myvariable interval }
	autorange { set myvariable autor }
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
