proc get_xml_data {} {
global rdbms bm instance system_user system_password count_ware tpcc_user tpcc_pass tpcc_def_tab tpcc_def_temp count_ware num_threads plsql partition tpcc_tt_compat directory total_iterations rasieerror keyandthink checkpoint oradriver mysqldriver rampup duration tpch_user tpch_pass tpch_def_tab tpch_def_temp num_tpch_threads tpch_tt_compat scale_fact total_querysets raise_query_error verbose degree_of_parallel refresh_on update_sets trickle_refresh refresh_verbose maxvuser delayms conpause ntimes suppo optlog unique_log_name no_log_buffer unwind connectstr interval autor rac hostname id agent_hostname agent_id mysql_host mysql_port my_count_ware mysql_user mysql_pass mysql_dbase storage_engine mysql_partition mysql_num_threads my_total_iterations my_raiseerror my_keyandthink my_rampup my_duration mysql_scale_fact mysql_tpch_user mysql_tpch_pass mysql_tpch_dbase mysql_num_tpch_threads mysql_tpch_storage_engine mysql_refresh_on mysql_total_querysets mysql_raise_query_error mysql_verbose mysql_update_sets mysql_trickle_refresh mysql_refresh_verbose apmode apduration apsequence mssqls_server mssqls_port mssqls_authentication mssqls_odbc_driver mssqls_count_ware mssqls_schema mssqls_num_threads mssqls_uid mssqls_pass mssqls_dbase mssqls_total_iterations mssqls_raiseerror mssqls_keyandthink mssqlsdriver mssqls_rampup mssqls_duration mssqls_checkpoint mssqls_scale_fact mssqls_maxdop mssqls_uid mssqls_pass mssqls_tpch_dbase mssqls_num_tpch_threads mssqls_refresh_on mssqls_total_querysets mssqls_raise_query_error mssqls_verbose mssqls_update_sets mssqls_trickle_refresh mssqls_refresh_verbose pg_host pg_port pg_count_ware pg_superuser pg_superuserpass pg_defaultdbase pg_user pg_pass pg_dbase pg_vacuum pg_dritasnap pg_oracompat pg_num_threads pg_total_iterations pg_raiseerror pg_keyandthink pg_driver pg_rampup pg_duration pg_scale_fact pg_tpch_superuser pg_tpch_superuserpass pg_tpch_defaultdbase pg_tpch_user pg_tpch_pass pg_tpch_dbase pg_tpch_gpcompat pg_tpch_gpcompress pg_num_tpch_threads pg_total_querysets pg_raise_query_error pg_verbose pg_refresh_on pg_update_sets pg_trickle_refresh pg_refresh_verbose redis_host redis_port redis_namespace redis_count_ware redis_num_threads redis_total_iterations redis_raiseerror redis_keyandthink redis_driver redis_rampup redis_duration trafodion_dsn trafodion_odbc_driver trafodion_server trafodion_port trafodion_userid trafodion_password trafodion_schema trafodion_count_ware trafodion_num_threads trafodion_load_type trafodion_load_data trafodion_node_list trafodion_copy_remote trafodion_build_jsps trafodion_total_iterations trafodion_raiseerror trafodion_keyandthink trafodion_driver trafodion_rampup trafodion_duration db2_count_ware db2_num_threads db2_user db2_pass db2_dbase db2_def_tab  db2_tab_list db2_partition db2_total_iterations db2_raiseerror db2_keyandthink db2driver db2_rampup db2_duration db2_monreport highlight
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
