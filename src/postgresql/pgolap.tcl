proc build_pgtpch {} {
global maxvuser suppo ntimes threadscreated _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict postgresql library ]} {
        set library [ dict get $dbdict postgresql library ]
} else { set library "Pgtcl" }
upvar #0 configpostgresql configpostgresql
#set variables to values in dict
setlocaltpchvars $configpostgresql
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a Scale Factor $pg_scale_fact TPC-H schema\n in host [string toupper $pg_host:$pg_port] under user [ string toupper $pg_tpch_user ] in database [ string toupper $pg_tpch_dbase ]?" -type yesno ] == yes} {
if { $pg_num_tpch_threads eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $pg_num_tpch_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "PostgreSQL TPC-H creation"
if { [catch {load_virtual} message]} {
puts "Failed to create threads for schema creation: $message"
        return
        }
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#LOAD LIBRARIES AND MODULES
set library $library
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpchcommon} ] { error "Failed to load tpch common functions" } else { namespace import tpchcommon::* }

proc GatherStatistics { lda } {
puts "GATHERING SCHEMA STATISTICS"
set sql(1) "ANALYZE ORDERS"
set sql(2) "ANALYZE PARTSUPP"
set sql(3) "ANALYZE CUSTOMER"
set sql(4) "ANALYZE PART"
set sql(5) "ANALYZE SUPPLIER"
set sql(6) "ANALYZE NATION"
set sql(7) "ANALYZE REGION"
set sql(8) "ANALYZE LINEITEM"
for { set i 1 } { $i <= 8 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
return
}

proc ConnectToPostgres { host port user password dbname } {
global tcl_platform
if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]} message]} {
set lda "Failed" ; puts $message
error $message
 } else {
if {$tcl_platform(platform) == "windows"} {
#Workaround for Bug #95 where first connection fails on Windows
catch {pg_disconnect $lda}
set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]
        }
pg_notice_handler $lda puts
set result [ pg_exec $lda "set CLIENT_MIN_MESSAGES TO 'ERROR'" ]
pg_result $result -clear
        }
return $lda
}

proc CreateUserDatabase { lda db superuser user password } {
puts "CREATING DATABASE $db under OWNER $user"
set sql(1) "CREATE USER $user PASSWORD '$password'"
set sql(2) "GRANT $user to $superuser"
set sql(3) "CREATE DATABASE $db OWNER $user"
for { set i 1 } { $i <= 3 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
        } else {
pg_result $result -clear
        }
    }
return
}

proc CreateTables { lda greenplum gpcompress } {
puts "CREATING TPCH TABLES"
if { $greenplum } {
if { $gpcompress } {
set compression "WITH (appendonly=true, orientation=column, compresstype=zlib, compresslevel=5)"
	} else {
set compression ""
	}
set sql(1) "CREATE TABLE ORDERS (O_ORDERDATE TIMESTAMP, O_ORDERKEY NUMERIC NOT NULL, O_CUSTKEY NUMERIC NOT NULL, O_ORDERPRIORITY CHAR(15), O_SHIPPRIORITY NUMERIC, O_CLERK CHAR(15), O_ORDERSTATUS CHAR(1), O_TOTALPRICE NUMERIC, O_COMMENT VARCHAR(79)) $compression DISTRIBUTED BY (O_ORDERKEY)"
set sql(2) "CREATE TABLE PARTSUPP (PS_PARTKEY NUMERIC NOT NULL, PS_SUPPKEY NUMERIC NOT NULL, PS_SUPPLYCOST NUMERIC NOT NULL, PS_AVAILQTY NUMERIC, PS_COMMENT VARCHAR(199)) $compression DISTRIBUTED BY (PS_PARTKEY,PS_SUPPKEY)"
set sql(3) "CREATE TABLE CUSTOMER(C_CUSTKEY NUMERIC NOT NULL, C_MKTSEGMENT CHAR(10), C_NATIONKEY NUMERIC, C_NAME VARCHAR(25), C_ADDRESS VARCHAR(40), C_PHONE CHAR(15), C_ACCTBAL NUMERIC, C_COMMENT VARCHAR(118)) $compression DISTRIBUTED BY (C_CUSTKEY)"
set sql(4) "CREATE TABLE PART(P_PARTKEY NUMERIC NOT NULL, P_TYPE VARCHAR(25), P_SIZE NUMERIC, P_BRAND CHAR(10), P_NAME VARCHAR(55), P_CONTAINER CHAR(10), P_MFGR CHAR(25), P_RETAILPRICE NUMERIC, P_COMMENT VARCHAR(23)) $compression DISTRIBUTED BY (P_PARTKEY)"
set sql(5) "CREATE TABLE SUPPLIER(S_SUPPKEY NUMERIC NOT NULL, S_NATIONKEY NUMERIC, S_COMMENT VARCHAR(102), S_NAME CHAR(25), S_ADDRESS VARCHAR(40), S_PHONE CHAR(15), S_ACCTBAL NUMERIC)  $compression DISTRIBUTED BY (S_SUPPKEY)"
set sql(6) "CREATE TABLE NATION(N_NATIONKEY NUMERIC NOT NULL, N_NAME CHAR(25), N_REGIONKEY NUMERIC, N_COMMENT VARCHAR(152)) $compression DISTRIBUTED BY (N_NATIONKEY)" 
set sql(7) "CREATE TABLE REGION(R_REGIONKEY NUMERIC, R_NAME CHAR(25), R_COMMENT VARCHAR(152)) $compression DISTRIBUTED BY (R_REGIONKEY)"
set sql(8) "CREATE TABLE LINEITEM(L_SHIPDATE TIMESTAMP, L_ORDERKEY NUMERIC NOT NULL, L_DISCOUNT NUMERIC NOT NULL, L_EXTENDEDPRICE NUMERIC NOT NULL, L_SUPPKEY NUMERIC NOT NULL, L_QUANTITY NUMERIC NOT NULL, L_RETURNFLAG CHAR(1), L_PARTKEY NUMERIC NOT NULL, L_LINESTATUS CHAR(1), L_TAX NUMERIC NOT NULL, L_COMMITDATE TIMESTAMP, L_RECEIPTDATE TIMESTAMP, L_SHIPMODE CHAR(10), L_LINENUMBER NUMERIC NOT NULL, L_SHIPINSTRUCT CHAR(25), L_COMMENT VARCHAR(44)) $compression DISTRIBUTED BY (L_LINENUMBER, L_ORDERKEY)"
	} else {
set sql(1) "CREATE TABLE ORDERS (O_ORDERDATE TIMESTAMP, O_ORDERKEY NUMERIC NOT NULL, O_CUSTKEY NUMERIC NOT NULL, O_ORDERPRIORITY CHAR(15), O_SHIPPRIORITY NUMERIC, O_CLERK CHAR(15), O_ORDERSTATUS CHAR(1), O_TOTALPRICE NUMERIC, O_COMMENT VARCHAR(79))"
set sql(2) "CREATE TABLE PARTSUPP (PS_PARTKEY NUMERIC NOT NULL, PS_SUPPKEY NUMERIC NOT NULL, PS_SUPPLYCOST NUMERIC NOT NULL, PS_AVAILQTY NUMERIC, PS_COMMENT VARCHAR(199))"
set sql(3) "CREATE TABLE CUSTOMER(C_CUSTKEY NUMERIC NOT NULL, C_MKTSEGMENT CHAR(10), C_NATIONKEY NUMERIC, C_NAME VARCHAR(25), C_ADDRESS VARCHAR(40), C_PHONE CHAR(15), C_ACCTBAL NUMERIC, C_COMMENT VARCHAR(118))"
set sql(4) "CREATE TABLE PART(P_PARTKEY NUMERIC NOT NULL, P_TYPE VARCHAR(25), P_SIZE NUMERIC, P_BRAND CHAR(10), P_NAME VARCHAR(55), P_CONTAINER CHAR(10), P_MFGR CHAR(25), P_RETAILPRICE NUMERIC, P_COMMENT VARCHAR(23))"
set sql(5) "CREATE TABLE SUPPLIER(S_SUPPKEY NUMERIC NOT NULL, S_NATIONKEY NUMERIC, S_COMMENT VARCHAR(102), S_NAME CHAR(25), S_ADDRESS VARCHAR(40), S_PHONE CHAR(15), S_ACCTBAL NUMERIC)"
set sql(6) "CREATE TABLE NATION(N_NATIONKEY NUMERIC NOT NULL, N_NAME CHAR(25), N_REGIONKEY NUMERIC, N_COMMENT VARCHAR(152))" 
set sql(7) "CREATE TABLE REGION(R_REGIONKEY NUMERIC, R_NAME CHAR(25), R_COMMENT VARCHAR(152))"
set sql(8) "CREATE TABLE LINEITEM(L_SHIPDATE TIMESTAMP, L_ORDERKEY NUMERIC NOT NULL, L_DISCOUNT NUMERIC NOT NULL, L_EXTENDEDPRICE NUMERIC NOT NULL, L_SUPPKEY NUMERIC NOT NULL, L_QUANTITY NUMERIC NOT NULL, L_RETURNFLAG CHAR(1), L_PARTKEY NUMERIC NOT NULL, L_LINESTATUS CHAR(1), L_TAX NUMERIC NOT NULL, L_COMMITDATE TIMESTAMP, L_RECEIPTDATE TIMESTAMP, L_SHIPMODE CHAR(10), L_LINENUMBER NUMERIC NOT NULL, L_SHIPINSTRUCT CHAR(25), L_COMMENT VARCHAR(44))"
	}
for { set i 1 } { $i <= 8 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
}

proc mk_region { lda } {
for { set i 1 } { $i <= 5 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists regions ] [ expr {$i - 1} ] ] 0 ]
set comment [ TEXT_1 72 ]
set result [ pg_exec $lda "INSERT INTO REGION (R_REGIONKEY, R_NAME, R_COMMENT) VALUES ('$code','$text','$comment')" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
	    return
        } else {
	pg_result $result -clear
	}
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	puts "Region done"
	return
}

proc mk_nation { lda } {
for { set i 1 } { $i <= 25 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists nations ] [ expr {$i - 1} ] ] 0 ]
set nind [ lsearch -glob [ get_dists nations ] \*$text\* ]
switch $nind {
0 - 4 - 5 - 14 - 15 - 16 { set join 0 }
1 - 2 - 3 - 17 - 24 { set join 1 }
8 - 9 - 12 - 18 - 21 { set join 2 }
6 - 7 - 19 - 22 - 23 { set join 3 }
10 - 11 - 13 - 20 { set join 4 }
}
set comment [ TEXT_1 72 ]
set result [ pg_exec $lda "INSERT INTO NATION (N_NATIONKEY, N_NAME, N_REGIONKEY, N_COMMENT) VALUES ('$code','$text','$join','$comment')" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
	    return
        } else {
	pg_result $result -clear
	}
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	puts "Nation done"
	return
}

proc mk_supp { lda start_rows end_rows greenplum } {
set BBB_COMMEND   "Recommends"
set BBB_COMPLAIN  "Complaints"
if { $greenplum } { set rowcount 1 } else { set rowcount 1000 }
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set suppkey $i
set name [ concat Supplier#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
#random format to 2 floating point places 1681.00
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set comment [ TEXT_1 63 ]
set bad_press [ RandomNumber 1 10000 ]
set type [ RandomNumber 0 100 ]
set noise [ RandomNumber 0 19 ]
set offset [ RandomNumber 0 [ expr {19 + $noise} ] ]
if { $bad_press <= 10 } {
set st [ expr {9 + $offset + $noise} ]
set fi [ expr {$st + 10} ]
if { $type < 50 } {
set comment [ string replace $comment $st $fi $BBB_COMPLAIN ]
} else {
set comment [ string replace $comment $st $fi $BBB_COMMEND ]
	}
}
append supp_val_list ('$suppkey', '$nation_code', '$comment', '$name', '$address', '$phone', '$acctbal')
if { ![ expr {$i % $rowcount} ] || $i eq $end_rows } {    
set result [ pg_exec $lda "INSERT INTO SUPPLIER (S_SUPPKEY, S_NATIONKEY, S_COMMENT, S_NAME, S_ADDRESS, S_PHONE, S_ACCTBAL) VALUES $supp_val_list" ]
	if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
if {!$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
	unset supp_val_list
	} else {
if {!$greenplum} {
append supp_val_list ,
		} 
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading SUPPLIER...$i"
if {$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
     }
   }
puts "SUPPLIER Done Rows $start_rows..$end_rows"
return
}

proc mk_cust { lda start_rows end_rows greenplum } {
if { $greenplum } { set rowcount 1 } else { set rowcount 1000 }
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set custkey $i
set name [ concat Customer#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set mktsegment [ pick_str_1 msegmnt ]
set comment [ TEXT_1 73 ]
append cust_val_list ('$custkey', '$mktsegment', '$nation_code', '$name', '$address', '$phone', '$acctbal', '$comment') 
if { ![ expr {$i % $rowcount} ] || $i eq $end_rows } {    
set result [ pg_exec $lda "INSERT INTO CUSTOMER (C_CUSTKEY, C_MKTSEGMENT, C_NATIONKEY, C_NAME, C_ADDRESS, C_PHONE, C_ACCTBAL, C_COMMENT) values $cust_val_list" ]
	if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
if {!$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
	unset cust_val_list
	} else {
if {!$greenplum} {
append cust_val_list ,
 		}
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading CUSTOMER...$i"
if {$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
    }
}
puts "Customer Done Rows $start_rows..$end_rows"
return
}

proc mk_part { lda start_rows end_rows scale_factor greenplum } {
if { $greenplum } { set rowcount 1 } else { set rowcount 1000 }
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set partkey $i
unset -nocomplain name
for {set j 0} {$j < [ expr {5 - 1} ] } {incr j } {
append name [ pick_str_1 colors ] " "
}
append name [ pick_str_1 colors ]
set mf [ RandomNumber 1 5 ]
set mfgr [ concat Manufacturer#$mf ]
set brand [ concat Brand#[ expr {$mf * 10 + [ RandomNumber 1 5 ]} ] ]
set type [ pick_str_1 p_types ] 
set size [ RandomNumber 1 50 ]
set container [ pick_str_1 p_cntr ] 
set price [ rpb_routine $i ]
set comment [ TEXT_1 14 ]
append part_val_list ('$partkey', '$type', '$size', '$brand', '$name', '$container', '$mfgr', '$price', '$comment')
#Part Supp Loop
for {set k 0} {$k < 4 } {incr k } {
set psupp_pkey $partkey
set psupp_suppkey [ PART_SUPP_BRIDGE $i $k $scale_factor ]
set psupp_qty [ RandomNumber 1 9999 ]
set psupp_scost [format %4.2f [ expr {double([ RandomNumber 100 100000 ]) / 100} ] ]
set psupp_comment [ TEXT_1 124 ]
append psupp_val_list ('$psupp_pkey', '$psupp_suppkey', '$psupp_scost', '$psupp_qty', '$psupp_comment')
if {!$greenplum} {
if { $k<=2 } {
append psupp_val_list ,
        }
    }
if {!$greenplum} {
#PostgreSQL does multi-line inserts later, Greenplum does line-by-line
 } else { 
set result [ pg_exec $lda "INSERT INTO PARTSUPP (PS_PARTKEY, PS_SUPPKEY, PS_SUPPLYCOST, PS_AVAILQTY, PS_COMMENT) VALUES $psupp_val_list" ]
	if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
        unset psupp_val_list
	}
   }
# end of psupp loop
if { ![ expr {$i % $rowcount} ]  || $i eq $end_rows } {     
set result [ pg_exec $lda "INSERT INTO PART (P_PARTKEY, P_TYPE, P_SIZE, P_BRAND, P_NAME, P_CONTAINER, P_MFGR, P_RETAILPRICE, P_COMMENT) VALUES $part_val_list" ]
	if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
if {!$greenplum} {
set result [ pg_exec $lda "INSERT INTO PARTSUPP (PS_PARTKEY, PS_SUPPKEY, PS_SUPPLYCOST, PS_AVAILQTY, PS_COMMENT) VALUES $psupp_val_list" ]
	if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	}
if {!$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
        unset part_val_list
        unset -nocomplain psupp_val_list
	} else {
if {!$greenplum} {
append part_val_list ,
append psupp_val_list ,
		}
	}
if { ![ expr {$i % 10000} ] } {
        puts "Loading PART/PARTSUPP...$i"
if {$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
		}
        }
}
puts "PART and PARTSUPP Done Rows $start_rows..$end_rows"
return
}

proc mk_order { lda start_rows end_rows upd_num scale_factor greenplum } {
if { $greenplum } { set rowcount 1 } else { set rowcount 1000 }
proc date_function {} {
set df "to_timestamp"
return $df
	}
set refresh 100
set delta 1
set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
for { set i $start_rows } { $i <= $end_rows } { incr i } {
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
}
set custkey [ RandomNumber 1 $O_CKEY_MAX ]
while { $custkey % 3 == 0 } {
set custkey [ expr {$custkey + $delta} ]
if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
set custkey $min
set delta [ expr {$delta * -1} ]
}
if { ![ array exists ascdate ] } {
for { set d 1 } { $d <= 2557 } {incr d} {
set ascdate($d) [ mk_time $d ]
	}
}
set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
set date $ascdate([ expr {$tmp_date - 92001} ])
set opriority [ pick_str_1 o_oprio ] 
set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
set clerk [ concat Clerk#[format %1.9d $clk_num]]
set comment [ TEXT_1 49 ]
set spriority 0
set totalprice 0
set orderstatus "O"
set ocnt 0
set lcnt [ RandomNumber 1 7 ]
#Lineitem Loop
for { set l 0 } { $l < $lcnt } {incr l} {
set lokey $okey
set llcnt [ expr {$l + 1} ]
set lquantity [ RandomNumber 1 50 ]
set ldiscount [format %1.2f [ expr [ RandomNumber 0 10 ] / 100.00 ]]
set ltax [format %1.2f [ expr [ RandomNumber 0 8 ] / 100.00 ]]
set linstruct [ pick_str_1 instruct ] 
set lsmode [ pick_str_1 smode ] 
set lcomment [ TEXT_1 27 ]
set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
set rprice [ rpb_routine $lpartkey ]
set supp_num [ RandomNumber 0 3 ]
set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
set s_date [ RandomNumber 1 121 ]
set s_date [ expr {$s_date + $tmp_date} ] 
set c_date [ RandomNumber 30 90 ]
set c_date [ expr {$c_date + $tmp_date} ]
set r_date [ RandomNumber 1 30 ]
set r_date [ expr {$r_date + $s_date} ]
set lsdate $ascdate([ expr {$s_date - 92001} ])
set lcdate $ascdate([ expr {$c_date - 92001} ])
set lrdate $ascdate([ expr {$r_date - 92001} ])
if { [ julian $r_date ] <= 95168 } {
set lrflag [ pick_str_1 rflag ] 
} else { set lrflag "N" }
if { [ julian $s_date ] <= 95168 } {
incr ocnt
set lstatus "F"
} else { set lstatus "O" }
append lineit_val_list ([ date_function ]('$lsdate','YYYY-Mon-DD'),'$lokey', '$ldiscount', '$leprice', '$lsuppkey', '$lquantity', '$lrflag', '$lpartkey', '$lstatus', '$ltax', [ date_function ]('$lcdate','YYYY-Mon-DD'), [ date_function ]('$lrdate','YYYY-Mon-DD'), '$lsmode', '$llcnt', '$linstruct', '$lcomment') 
if {!$greenplum} {
if { $l < [ expr $lcnt - 1 ] } { 
append lineit_val_list ,
	} 
      } else {
set result [ pg_exec $lda "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) VALUES $lineit_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	unset lineit_val_list
    }
}
#End Lineitem Loop
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
append order_val_list ([ date_function ]('$date','YYYY-Mon-DD'), '$okey', '$custkey', '$opriority', '$spriority', '$clerk', '$orderstatus', '$totalprice', '$comment') 
if { ![ expr {$i % $rowcount} ]  || $i eq $end_rows } {     
if {!$greenplum} {
set result [ pg_exec $lda "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) VALUES $lineit_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
   }
set result [ pg_exec $lda "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) VALUES $order_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	if {!$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
	unset -nocomplain lineit_val_list
	unset order_val_list	
   	} else {
	if {!$greenplum} {
	append order_val_list ,
	append lineit_val_list ,
		}
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading ORDERS/LINEITEM...$i"
if {$greenplum} {
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
		}
	}
}
puts "ORDERS and LINEITEM Done Rows $start_rows..$end_rows"
return
}

proc CreateIndexes { lda greenplum gpcompress } {
puts "CREATING TPCH INDEXES"
if { $greenplum && $gpcompress } {
set ind_cnt 8
set sql(1) "CREATE INDEX REGION_PK ON REGION (R_REGIONKEY)"
set sql(2) "CREATE INDEX NATION_PK ON NATION (N_NATIONKEY)"
set sql(3) "CREATE INDEX SUPPLIER_PK ON SUPPLIER (S_SUPPKEY)"
set sql(4) "CREATE INDEX PARTSUPP_PK ON PARTSUPP (PS_PARTKEY,PS_SUPPKEY)"
set sql(5) "CREATE INDEX PART_PK ON PART (P_PARTKEY)"
set sql(6) "CREATE INDEX ORDERS_PK ON ORDERS (O_ORDERKEY)"
set sql(7) "CREATE INDEX LINEITEM_PK ON LINEITEM (L_LINENUMBER, L_ORDERKEY)"
set sql(8) "CREATE INDEX CUSTOMER_PK ON CUSTOMER (C_CUSTKEY)"
	} else {
set ind_cnt 16
set sql(1) "ALTER TABLE REGION ADD CONSTRAINT REGION_PK PRIMARY KEY (R_REGIONKEY)"
set sql(2) "ALTER TABLE NATION ADD CONSTRAINT NATION_PK PRIMARY KEY (N_NATIONKEY)"
set sql(3) "ALTER TABLE SUPPLIER ADD CONSTRAINT SUPPLIER_PK PRIMARY KEY (S_SUPPKEY)"
set sql(4) "ALTER TABLE PARTSUPP ADD CONSTRAINT PARTSUPP_PK PRIMARY KEY (PS_PARTKEY,PS_SUPPKEY)"
set sql(5) "ALTER TABLE PART ADD CONSTRAINT PART_PK PRIMARY KEY (P_PARTKEY)"
set sql(6) "ALTER TABLE ORDERS ADD CONSTRAINT ORDERS_PK PRIMARY KEY (O_ORDERKEY)"
set sql(7) "ALTER TABLE LINEITEM ADD CONSTRAINT LINEITEM_PK PRIMARY KEY (L_LINENUMBER, L_ORDERKEY)"
set sql(8) "ALTER TABLE CUSTOMER ADD CONSTRAINT CUSTOMER_PK PRIMARY KEY (C_CUSTKEY)"
set sql(9) "ALTER TABLE LINEITEM ADD CONSTRAINT LINEITEM_PARTSUPP_FK FOREIGN KEY (L_PARTKEY, L_SUPPKEY) REFERENCES PARTSUPP(PS_PARTKEY, PS_SUPPKEY) NOT DEFERRABLE"
set sql(10) "ALTER TABLE ORDERS ADD CONSTRAINT ORDER_CUSTOMER_FK FOREIGN KEY (O_CUSTKEY) REFERENCES CUSTOMER (C_CUSTKEY) NOT DEFERRABLE"
set sql(11) "ALTER TABLE PARTSUPP ADD CONSTRAINT PARTSUPP_PART_FK FOREIGN KEY (PS_PARTKEY) REFERENCES PART (P_PARTKEY) NOT DEFERRABLE"
set sql(12) "ALTER TABLE PARTSUPP ADD CONSTRAINT PARTSUPP_SUPPLIER_FK FOREIGN KEY (PS_SUPPKEY) REFERENCES SUPPLIER (S_SUPPKEY) NOT DEFERRABLE"
set sql(13) "ALTER TABLE SUPPLIER ADD CONSTRAINT SUPPLIER_NATION_FK FOREIGN KEY (S_NATIONKEY) REFERENCES NATION (N_NATIONKEY) NOT DEFERRABLE"
set sql(14) "ALTER TABLE CUSTOMER ADD CONSTRAINT CUSTOMER_NATION_FK FOREIGN KEY (C_NATIONKEY) REFERENCES NATION (N_NATIONKEY) NOT DEFERRABLE"
set sql(15) "ALTER TABLE NATION ADD CONSTRAINT NATION_REGION_FK FOREIGN KEY (N_REGIONKEY) REFERENCES REGION (R_REGIONKEY) NOT DEFERRABLE"
set sql(16) "ALTER TABLE LINEITEM ADD CONSTRAINT LINEITEM_ORDER_FK FOREIGN KEY (L_ORDERKEY) REFERENCES ORDERS (O_ORDERKEY) NOT DEFERRABLE"
	}
for { set i 1 } { $i <= $ind_cnt } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	}  else {
	pg_result $result -clear
	}
    }
return
}

proc do_tpch { host port scale_fact superuser superuser_password defaultdb db user password greenplum gpcompress num_vu } {
global dist_names dist_weights weights dists weights
###############################################
#Generating following rows
#5 rows in region table
#25 rows in nation table
#SF * 10K rows in Supplier table
#SF * 150K rows in Customer table
#SF * 200K rows in Part table
#SF * 800K rows in Partsupp table
#SF * 1500K rows in Orders table
#SF * 6000K rows in Lineitem table
###############################################
#update number always zero for first load
set upd_num 0
if { ![ array exists dists ] } { set_dists }
foreach i [ array names dists ] {
set_dist_list $i
}
set sup_rows [ expr {$scale_fact * 10000} ]
set max_threads 256
set sf_mult 1
set cust_mult 15
set part_mult 20
set ord_mult 150
if { [ string toupper $greenplum ] eq "TRUE"} { set greenplum 1 } else { set greenplum 0 }
if { [ string toupper $gpcompress ] eq "TRUE"} { set gpcompress 1 } else { set gpcompress 0 }
if { $num_vu > $max_threads } { set num_vu $max_threads }
if { $num_vu > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set rema [ lassign [ findvuhposition ] myposition totalvirtualusers ]
switch $myposition {
	1 { 
puts "Monitor Thread"
if { $threaded eq "MULTI-THREADED" } {
tsv::lappend common thrdlst monitor
for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
tsv::lappend common thrdlst idle
			}
tsv::set application load "WAIT"
		}
	}
	default { 
puts "Worker Thread"
if { [ expr $myposition - 1 ] > $max_threads } { puts "No Data to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_vu 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING [ string toupper $user ] SCHEMA"
set lda [ ConnectToPostgres $host $port $superuser $superuser_password $defaultdb ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 } else {
CreateUserDatabase $lda $db $superuser $user $password
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
pg_disconnect $lda
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 } else {
CreateTables $lda $greenplum $gpcompress
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
	}
}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
puts "Loading REGION..."
mk_region $lda
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation $lda
puts "Loading NATION COMPLETE"
puts "Monitoring Workers..."
after 10000
set prevactive 0
while 1 {
set idlcnt 0; set lvcnt 0; set dncnt 0;
for {set th 2} {$th <= $totalvirtualusers } {incr th} {
switch [tsv::lindex common thrdlst $th] {
idle { incr idlcnt }
active { incr lvcnt }
done { incr dncnt }
        }
}
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
        }
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000
}} else {
puts "Loading REGION..."
mk_region $lda
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation $lda
puts "Loading NATION COMPLETE"
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if {  [ tsv::get application abort ]  } { return }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
after 5000
}
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 }
if { [ expr $myposition - 1 ] > $max_threads } { puts "No Data to Create"; return }
if { [ expr $num_vu + 1 ] > $max_threads } { set num_vu $max_threads }
set sf_chunk [ split [ start_end $sup_rows $myposition $sf_mult $num_vu ] ":" ]
set cust_chunk [ split [ start_end $sup_rows $myposition $cust_mult $num_vu ] ":" ]
set part_chunk [ split [ start_end $sup_rows $myposition $part_mult $num_vu ] ":" ]
set ord_chunk [ split [ start_end $sup_rows $myposition $ord_mult $num_vu ] ":" ]
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set sf_chunk "1 $sup_rows"
set cust_chunk "1 [ expr {$sup_rows * $cust_mult} ]" 
set part_chunk "1 [ expr {$sup_rows * $part_mult} ]" 
set ord_chunk "1 [ expr {$sup_rows * $ord_mult} ]"
}
puts "Start:[ clock format [ clock seconds ] ]"
puts "Loading SUPPLIER..."
mk_supp $lda [ lindex $sf_chunk 0 ] [ lindex $sf_chunk 1 ] $greenplum
puts "Loading CUSTOMER..."
mk_cust $lda [ lindex $cust_chunk 0 ] [ lindex $cust_chunk 1 ] $greenplum
puts "Loading PART and PARTSUPP..."
mk_part $lda [ lindex $part_chunk 0 ] [ lindex $part_chunk 1 ] $scale_fact $greenplum
puts "Loading ORDERS and LINEITEM..."
mk_order $lda [ lindex $ord_chunk 0 ] [ lindex $ord_chunk 1 ] [ expr {$upd_num % 10000} ] $scale_fact $greenplum
puts "Loading TPCH TABLES COMPLETE"
puts "End:[ clock format [ clock seconds ] ]"
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateIndexes $lda $greenplum $gpcompress
GatherStatistics $lda
puts "[ string toupper $user ] SCHEMA COMPLETE"
pg_disconnect $lda
return
		}
	}
}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "do_tpch $pg_host $pg_port $pg_scale_fact $pg_tpch_superuser $pg_tpch_superuserpass $pg_tpch_defaultdbase $pg_tpch_dbase $pg_tpch_user $pg_tpch_pass $pg_tpch_gpcompat $pg_tpch_gpcompress $pg_num_tpch_threads"
	} else { return }
}

proc loadpgtpch {} {
global _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict postgresql library ]} {
        set library [ dict get $dbdict postgresql library ]
} else { set library "Pgtcl" }
upvar #0 configpostgresql configpostgresql
#set variables to values in dict
setlocaltpchvars $configpostgresql
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "PostgreSQL TPC-H"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# PostgreSQL Library
set total_querysets $pg_total_querysets ;# Number of query sets before logging off
set RAISEERROR \"$pg_raise_query_error\" ;# Exit script on PostgreSQL query error (true or false)
set VERBOSE \"$pg_verbose\" ;# Show query text and output
set degree_of_parallel \"$pg_degree_of_parallel\" ;# Degree of Parallelism
set scale_factor $pg_scale_fact ;#Scale factor of the tpc-h schema
set host \"$pg_host\" ;# Address of the server hosting PostgreSQL
set port \"$pg_port\" ;# Port of the PostgreSQL Server
set user \"$pg_tpch_user\" ;# PostgreSQL user
set password \"$pg_tpch_pass\" ;# Password for the PostgreSQL user
set db \"$pg_tpch_dbase\" ;# Database containing the TPC Schema
set refresh_on \"$pg_refresh_on\" ;#First User does refresh function
set update_sets $pg_update_sets ;#Number of sets of refresh function to complete
set trickle_refresh $pg_trickle_refresh ;#time delay (ms) to trickle refresh function
set REFRESH_VERBOSE \"$pg_refresh_verbose\" ;#report refresh function activity
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpchcommon} ] { error "Failed to load tpch common functions" } else { namespace import tpchcommon::* }

proc standsql { lda sql RAISEERROR VERBOSE } {
if {[catch { pg_select $lda $sql var { if { $VERBOSE } { 
foreach index [array names var] { if { $index > 2} {puts $var($index)} } } } } message]} {
if { $RAISEERROR } {
error "Query Error : $message"
	} else {
puts "Query Failed : $sql : $message"
	}
      } 
}

proc ConnectToPostgres { host port user password dbname } {
global tcl_platform
if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]} message]} {
set lda "Failed" ; puts $message
error $message
 } else {
if {$tcl_platform(platform) == "windows"} {
#Workaround for Bug #95 where first connection fails on Windows
catch {pg_disconnect $lda}
set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]
        }
pg_notice_handler $lda puts
set result [ pg_exec $lda "set CLIENT_MIN_MESSAGES TO 'ERROR'" ]
pg_result $result -clear
        }
return $lda
}
#########################
#TPCH REFRESH PROCEDURE
proc mk_order_ref { lda upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
#2.27.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#INSERT a new row into the ORDERS table
#LOOP RANDOM(1, 7) TIMES
#INSERT a new row into the LINEITEM table
#END LOOP
#END LOOP
proc date_function {} {
set df "to_timestamp"
return $df
	}
set refresh 100
set delta 1
set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
set sfrows [ expr {$scale_factor * 1500} ] 
set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
set endindex [ expr {$upd_num * $sfrows} ]
for { set i $startindex } { $i <= $endindex } { incr i } {
after $trickle_refresh
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {1 + $upd_num / (10000 / $refresh)} ] ]
}
set custkey [ RandomNumber 1 $O_CKEY_MAX ]
while { $custkey % 3 == 0 } {
set custkey [ expr {$custkey + $delta} ]
if { $custkey < $O_CKEY_MAX } { set min $custkey } else { set min $O_CKEY_MAX }
set custkey $min
set delta [ expr {$delta * -1} ]
}
if { ![ array exists ascdate ] } {
for { set d 1 } { $d <= 2557 } {incr d} {
set ascdate($d) [ mk_time $d ]
	}
}
set tmp_date [ RandomNumber 92002 $O_ODATE_MAX ]
set date $ascdate([ expr {$tmp_date - 92001} ])
set opriority [ pick_str_2 [ get_dists o_oprio ] o_oprio ] 
set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
set clerk [ concat Clerk#[format %1.9d $clk_num]]
set comment [ TEXT_2 49 ]
set spriority 0
set totalprice 0
set orderstatus "O"
set ocnt 0
set lcnt [ RandomNumber 1 7 ]
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
if { $REFRESH_VERBOSE } {
puts "Refresh Insert Orderkey $okey..."
	}
set result [ pg_exec $lda "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) VALUES ([ date_function ]('$date','YYYY-Mon-DD'), '$okey', '$custkey', '$opriority', '$spriority', '$clerk', '$orderstatus', '$totalprice', '$comment')" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
#Lineitem Loop
for { set l 0 } { $l < $lcnt } {incr l} {
set lokey $okey
set llcnt [ expr {$l + 1} ]
set lquantity [ RandomNumber 1 50 ]
set ldiscount [format %1.2f [ expr [ RandomNumber 0 10 ] / 100.00 ]]
set ltax [format %1.2f [ expr [ RandomNumber 0 8 ] / 100.00 ]]
set linstruct [ pick_str_2 [ get_dists instruct ] instruct ] 
set lsmode [ pick_str_2 [ get_dists smode ] smode ] 
set lcomment [ TEXT_2 27 ]
set lpartkey [ RandomNumber 1 $L_PKEY_MAX ]
set rprice [ rpb_routine $lpartkey ]
set supp_num [ RandomNumber 0 3 ]
set lsuppkey [ PART_SUPP_BRIDGE $lpartkey $supp_num $scale_factor ]
set leprice [format %4.2f [ expr {$rprice * $lquantity} ]]
set totalprice [format %4.2f [ expr {$totalprice + [ expr {(($leprice * (100 - $ldiscount)) / 100) * (100 + $ltax) / 100} ]}]]
set s_date [ RandomNumber 1 121 ]
set s_date [ expr {$s_date + $tmp_date} ] 
set c_date [ RandomNumber 30 90 ]
set c_date [ expr {$c_date + $tmp_date} ]
set r_date [ RandomNumber 1 30 ]
set r_date [ expr {$r_date + $s_date} ]
set lsdate $ascdate([ expr {$s_date - 92001} ])
set lcdate $ascdate([ expr {$c_date - 92001} ])
set lrdate $ascdate([ expr {$r_date - 92001} ])
if { [ julian $r_date ] <= 95168 } {
set lrflag [ pick_str_2 [ get_dists rflag ] rflag ] 
} else { set lrflag "N" }
if { [ julian $s_date ] <= 95168 } {
incr ocnt
set lstatus "F"
} else { set lstatus "O" }
set result [ pg_exec $lda "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) VALUES ([ date_function ]('$lsdate','YYYY-Mon-DD'),'$lokey', '$ldiscount', '$leprice', '$lsuppkey', '$lquantity', '$lrflag', '$lpartkey', '$lstatus', '$ltax', [ date_function ]('$lcdate','YYYY-Mon-DD'), [ date_function ]('$lrdate','YYYY-Mon-DD'), '$lsmode', '$llcnt', '$linstruct', '$lcomment')" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
  }
if { ![ expr {$i % 1000} ] } {     
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear	
   }
}
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
}

proc del_order_ref { lda upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
#2.28.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#DELETE FROM ORDERS WHERE O_ORDERKEY = [value]
#DELETE FROM LINEITEM WHERE L_ORDERKEY = [value]
#END LOOP
set refresh 100
set sfrows [ expr {$scale_factor * 1500} ] 
set startindex [ expr {(($upd_num * $sfrows) - $sfrows) + 1 } ]
set endindex [ expr {$upd_num * $sfrows} ]
for { set i $startindex } { $i <= $endindex } { incr i } {
after $trickle_refresh
if { $upd_num == 0 } {
set okey [ mk_sparse $i $upd_num ]
} else {
set okey [ mk_sparse $i [ expr {$upd_num / (10000 / $refresh)} ] ]
}
set result [ pg_exec $lda "DELETE FROM LINEITEM WHERE L_ORDERKEY = $okey" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
set result [ pg_exec $lda "DELETE FROM ORDERS WHERE O_ORDERKEY = $okey" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
if { $REFRESH_VERBOSE } {
puts "Refresh Delete Orderkey $okey..."
	}
if { ![ expr {$i % 1000} ] } {     
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
   }
}
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
}

proc do_refresh { host port db user password scale_factor update_sets trickle_refresh REFRESH_VERBOSE RF_SET } {
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 	}
set upd_num 1
for { set set_counter 1 } {$set_counter <= $update_sets } {incr set_counter} {
if {  [ tsv::get application abort ]  } { break }
if { $RF_SET eq "RF1" || $RF_SET eq "BOTH" } {
puts "New Sales refresh"
set r0 [clock clicks -millisec]
mk_order_ref $lda $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE 
set r1 [clock clicks -millisec]
set rvalnew [expr {double($r1-$r0)/1000}]
puts "New Sales refresh complete in $rvalnew seconds"
	}
if { $RF_SET eq "RF2" || $RF_SET eq "BOTH" } {
puts "Old Sales refresh"
set r3 [clock clicks -millisec]
del_order_ref $lda $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE 
set r4 [clock clicks -millisec]
set rvalold [expr {double($r4-$r3)/1000}]
puts "Old Sales refresh complete in $rvalold seconds"
	}
if { $RF_SET eq "BOTH" } {
set rvaltot [expr {double($r4-$r0)/1000}]
puts "Completed update set(s) $set_counter in $rvaltot seconds"
	}
incr upd_num
	}
puts "Completed $update_sets update set(s)"
pg_disconnect $lda
}
#########################
#TPCH QUERY GENERATION
proc set_query { myposition } {
global sql
set sql(1) "select l_returnflag, l_linestatus, sum(l_quantity) as sum_qty, sum(l_extendedprice) as sum_base_price, sum(l_extendedprice * (1 - l_discount)) as sum_disc_price, sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge, avg(l_quantity) as avg_qty, avg(l_extendedprice) as avg_price, avg(l_discount) as avg_disc, count(*) as count_order from lineitem where l_shipdate <= date '1998-12-01' - interval ':1 day' group by l_returnflag, l_linestatus order by l_returnflag, l_linestatus"
set sql(2) "select s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment from part, supplier, partsupp, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and p_size = :1 and p_type like '%:2' and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3' and ps_supplycost = ( select min(ps_supplycost) from partsupp, supplier, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3') order by s_acctbal desc, n_name, s_name, p_partkey"
set sql(3) "select l_orderkey, sum(l_extendedprice * (1 - l_discount)) as revenue, o_orderdate, o_shippriority from customer, orders, lineitem where c_mktsegment = ':1' and c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate < date ':2' and l_shipdate > date ':2' group by l_orderkey, o_orderdate, o_shippriority order by revenue desc, o_orderdate"
set sql(4) "select o_orderpriority, count(*) as order_count from orders where o_orderdate >= date ':1' and o_orderdate < date ':1' + interval '3 month' and exists ( select * from lineitem where l_orderkey = o_orderkey and l_commitdate < l_receiptdate) group by o_orderpriority order by o_orderpriority"
set sql(5) "select n_name, sum(l_extendedprice * (1 - l_discount)) as revenue from customer, orders, lineitem, supplier, nation, region where c_custkey = o_custkey and l_orderkey = o_orderkey and l_suppkey = s_suppkey and c_nationkey = s_nationkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':1' and o_orderdate >= date ':2' and o_orderdate < date ':2' + interval '1 year' group by n_name order by revenue desc"
set sql(6) "select sum(l_extendedprice * l_discount) as revenue from lineitem where l_shipdate >= date ':1' and l_shipdate < date ':1' + interval '1 year' and l_discount between :2 - 0.01 and :2 + 0.01 and l_quantity < :3"
set sql(7) "select supp_nation, cust_nation, l_year, sum(volume) as revenue from ( select n1.n_name as supp_nation, n2.n_name as cust_nation, extract(year from l_shipdate) as l_year, l_extendedprice * (1 - l_discount) as volume from supplier, lineitem, orders, customer, nation n1, nation n2 where s_suppkey = l_suppkey and o_orderkey = l_orderkey and c_custkey = o_custkey and s_nationkey = n1.n_nationkey and c_nationkey = n2.n_nationkey and ( (n1.n_name = ':1' and n2.n_name = ':2') or (n1.n_name = ':2' and n2.n_name = ':1')) and l_shipdate between date '1995-01-01' and date '1996-12-31') shipping group by supp_nation, cust_nation, l_year order by supp_nation, cust_nation, l_year"
set sql(8) "select o_year, sum(case when nation = ':1' then volume else 0 end) / sum(volume) as mkt_share from ( select extract(year from o_orderdate) as o_year, l_extendedprice * (1 - l_discount) as volume, n2.n_name as nation from part, supplier, lineitem, orders, customer, nation n1, nation n2, region where p_partkey = l_partkey and s_suppkey = l_suppkey and l_orderkey = o_orderkey and o_custkey = c_custkey and c_nationkey = n1.n_nationkey and n1.n_regionkey = r_regionkey and r_name = ':2' and s_nationkey = n2.n_nationkey and o_orderdate between date '1995-01-01' and date '1996-12-31' and p_type = ':3') all_nations group by o_year order by o_year"
set sql(9) "select nation, o_year, sum(amount) as sum_profit from ( select n_name as nation, extract(year from o_orderdate) as o_year, l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount from part, supplier, lineitem, partsupp, orders, nation where s_suppkey = l_suppkey and ps_suppkey = l_suppkey and ps_partkey = l_partkey and p_partkey = l_partkey and o_orderkey = l_orderkey and s_nationkey = n_nationkey and p_name like '%:1%') profit group by nation, o_year order by nation, o_year desc"
set sql(10) "select c_custkey, c_name, sum(l_extendedprice * (1 - l_discount)) as revenue, c_acctbal, n_name, c_address, c_phone, c_comment from customer, orders, lineitem, nation where c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate >= date ':1' and o_orderdate < date ':1' + interval '3 month' and l_returnflag = 'R' and c_nationkey = n_nationkey group by c_custkey, c_name, c_acctbal, c_phone, n_name, c_address, c_comment order by revenue desc"
set sql(11) "select ps_partkey, sum(ps_supplycost * ps_availqty) as value from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1' group by ps_partkey having sum(ps_supplycost * ps_availqty) > ( select sum(ps_supplycost * ps_availqty) * :2 from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1') order by value desc"
set sql(12) "select l_shipmode, sum(case when o_orderpriority = '1-URGENT' or o_orderpriority = '2-HIGH' then 1 else 0 end) as high_line_count, sum(case when o_orderpriority <> '1-URGENT' and o_orderpriority <> '2-HIGH' then 1 else 0 end) as low_line_count from orders, lineitem where o_orderkey = l_orderkey and l_shipmode in (':1', ':2') and l_commitdate < l_receiptdate and l_shipdate < l_commitdate and l_receiptdate >= date ':3' and l_receiptdate < date ':3' + interval '1 year' group by l_shipmode order by l_shipmode"
set sql(13) "select c_count, count(*) as custdist from ( select c_custkey, count(o_orderkey) as c_count from customer left outer join orders on c_custkey = o_custkey and o_comment not like '%:1%:2%' group by c_custkey) c_orders group by c_count order by custdist desc, c_count desc"
set sql(14) "select 100.00 * sum(case when p_type like 'PROMO%' then l_extendedprice * (1 - l_discount) else 0 end) / sum(l_extendedprice * (1 - l_discount)) as promo_revenue from lineitem, part where l_partkey = p_partkey and l_shipdate >= date ':1' and l_shipdate < date ':1' + interval '1 month'"
set sql(15) "create or replace view revenue$myposition (supplier_no, total_revenue) as select l_suppkey, sum(l_extendedprice * (1 - l_discount)) from lineitem where l_shipdate >= to_date( ':1', 'YYYY-MM-DD') and l_shipdate < (to_date (':1', 'YYYY-MM-DD') + interval '3 month') group by l_suppkey; select s_suppkey, s_name, s_address, s_phone, total_revenue from supplier, revenue$myposition where s_suppkey = supplier_no and total_revenue = ( select max(total_revenue) from revenue$myposition) order by s_suppkey; drop view revenue$myposition"
set sql(16) "select p_brand, p_type, p_size, count(distinct ps_suppkey) as supplier_cnt from partsupp, part where p_partkey = ps_partkey and p_brand <> ':1' and p_type not like ':2%' and p_size in (:3, :4, :5, :6, :7, :8, :9, :10) and ps_suppkey not in ( select s_suppkey from supplier where s_comment like '%Customer%Complaints%') group by p_brand, p_type, p_size order by supplier_cnt desc, p_brand, p_type, p_size"
set sql(17) "select sum(l_extendedprice) / 7.0 as avg_yearly from lineitem, part where p_partkey = l_partkey and p_brand = ':1' and p_container = ':2' and l_quantity < ( select 0.2 * avg(l_quantity) from lineitem where l_partkey = p_partkey)"
set sql(18) "select c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice, sum(l_quantity) from customer, orders, lineitem where o_orderkey in ( select l_orderkey from lineitem group by l_orderkey having sum(l_quantity) > :1) and c_custkey = o_custkey and o_orderkey = l_orderkey group by c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice order by o_totalprice desc, o_orderdate"
set sql(19) "select sum(l_extendedprice* (1 - l_discount)) as revenue from lineitem, part where ( p_partkey = l_partkey and p_brand = ':1' and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') and l_quantity >= :4 and l_quantity <= :4 + 10 and p_size between 1 and 5 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':2' and p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') and l_quantity >= :5 and l_quantity <= :5 + 10 and p_size between 1 and 10 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':3' and p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') and l_quantity >= :6 and l_quantity <= :6 + 10 and p_size between 1 and 15 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON')"
set sql(20) "select s_name, s_address from supplier, nation where s_suppkey in ( select ps_suppkey from partsupp where ps_partkey in ( select p_partkey from part where p_name like ':1%') and ps_availqty > ( select 0.5 * sum(l_quantity) from lineitem where l_partkey = ps_partkey and l_suppkey = ps_suppkey and l_shipdate >= date ':2' and l_shipdate < date ':2' + interval '1 year')) and s_nationkey = n_nationkey and n_name = ':3' order by s_name"
set sql(21) "select s_name, count(*) as numwait from supplier, lineitem l1, orders, nation where s_suppkey = l1.l_suppkey and o_orderkey = l1.l_orderkey and o_orderstatus = 'F' and l1.l_receiptdate > l1.l_commitdate and exists ( select * from lineitem l2 where l2.l_orderkey = l1.l_orderkey and l2.l_suppkey <> l1.l_suppkey) and not exists ( select * from lineitem l3 where l3.l_orderkey = l1.l_orderkey and l3.l_suppkey <> l1.l_suppkey and l3.l_receiptdate > l3.l_commitdate) and s_nationkey = n_nationkey and n_name = ':1' group by s_name order by numwait desc, s_name"
set sql(22) "select cntrycode, count(*) as numcust, sum(c_acctbal) as totacctbal from ( select substr(c_phone, 1, 2) as cntrycode, c_acctbal from customer where substr(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7') and c_acctbal > ( select avg(c_acctbal) from customer where c_acctbal > 0.00 and substr(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7')) and not exists ( select * from orders where o_custkey = c_custkey)) custsale group by cntrycode order by cntrycode"
}

proc get_query { query_no myposition } {
global sql
if { ![ array exists sql ] } { set_query $myposition }
return $sql($query_no)
}

proc sub_query { query_no scale_factor myposition } {
set P_SIZE_MIN 1
set P_SIZE_MAX 50
set MAX_PARAM 10
set q2sub [get_query $query_no $myposition ]
switch $query_no {
1 {
regsub -all {:1} $q2sub [RandomNumber 60 120] q2sub
  }
2 {
regsub -all {:1} $q2sub [RandomNumber $P_SIZE_MIN $P_SIZE_MAX] q2sub
set qc [ lindex [ split [ pick_str_2 [ get_dists p_types ] p_types ] ] 2 ]
regsub -all {:2} $q2sub $qc q2sub
set qc [ pick_str_2 [ get_dists regions ] regions ]
regsub -all {:3} $q2sub $qc q2sub
  }
3 {
set qc [ pick_str_2 [ get_dists msegmnt ] msegmnt ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 1 31]
if { [ string length $tmp_date ] eq 1 } {set tmp_date [ concat 0$tmp_date ]  }
regsub -all {:2} $q2sub [concat 1995-03-$tmp_date] q2sub
  }
4 {
set tmp_date [RandomNumber 1 58]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
  }
5 {
set qc [ pick_str_2 [ get_dists regions ] regions ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:2} $q2sub [concat 19$tmp_date-01-01] q2sub
  }
6 {
set tmp_date [RandomNumber 93 97]
regsub -all {:1} $q2sub [concat 19$tmp_date-01-01] q2sub
regsub -all {:2} $q2sub [concat 0.0[RandomNumber 2 9]] q2sub
regsub -all {:3} $q2sub [RandomNumber 24 25] q2sub
  }
7 {
set qc [ pick_str_2 [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
set qc2 $qc
while { $qc2 eq $qc } { set qc2 [ pick_str_2 [ get_dists nations2 ] nations2 ] }
regsub -all {:2} $q2sub $qc2 q2sub
  }
8 {
set nationlist [ get_dists nations2 ]
set regionlist [ get_dists regions ]
set qc [ pick_str_2 $nationlist nations2 ] 
regsub -all {:1} $q2sub $qc q2sub
set nind [ lsearch -glob $nationlist [concat \*$qc\*] ]
switch $nind {
0 - 4 - 5 - 14 - 15 - 16 { set qc "AFRICA" }
1 - 2 - 3 - 17 - 24 { set qc "AMERICA" }
8 - 9 - 12 - 18 - 21 { set qc "ASIA" }
6 - 7 - 19 - 22 - 23 { set qc "EUROPE"}
10 - 11 - 13 - 20 { set qc "MIDDLE EAST"}
}
regsub -all {:2} $q2sub $qc q2sub
set qc [ pick_str_2 [ get_dists p_types ] p_types ]
regsub -all {:3} $q2sub $qc q2sub
  }
9 {
set qc [ pick_str_2 [ get_dists colors ] colors ]
regsub -all {:1} $q2sub $qc q2sub
  }
10 {
set tmp_date [RandomNumber 1 24]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
   }
11 {
set qc [ pick_str_2 [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
set q11_fract [ format %11.10f [ expr 0.0001 / $scale_factor ] ]
regsub -all {:2} $q2sub $q11_fract q2sub
}
12 {
set qc [ pick_str_2 [ get_dists smode ] smode ]
regsub -all {:1} $q2sub $qc q2sub
set qc2 $qc
while { $qc2 eq $qc } { set qc2 [ pick_str_2 [ get_dists smode ] smode ] }
regsub -all {:2} $q2sub $qc2 q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:3} $q2sub [concat 19$tmp_date-01-01] q2sub
}
13 {
set qc [ pick_str_2 [ get_dists Q13a ] Q13a ]
regsub -all {:1} $q2sub $qc q2sub
set qc [ pick_str_2 [ get_dists Q13b ] Q13b ]
regsub -all {:2} $q2sub $qc q2sub
}
14 {
set tmp_date [RandomNumber 1 60]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
}
15 {
set tmp_date [RandomNumber 1 58]
set yr [ expr 93 + $tmp_date/12 ]
set mon [ expr $tmp_date % 12 + 1 ]
if { [ string length $mon ] eq 1 } {set mon [ concat 0$mon ] }
set tmp_date [ concat 19$yr-$mon-01 ]
regsub -all {:1} $q2sub $tmp_date q2sub
}
16 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set p_type [ split [ pick_str_2 [ get_dists p_types ] p_types ] ]
set qc [ concat [ lindex $p_type 0 ] [ lindex $p_type 1 ] ]
regsub -all {:2} $q2sub $qc q2sub
set permute [list]
for {set i 3} {$i <= $MAX_PARAM} {incr i} {
set tmp3 [RandomNumber 1 50] 
while { [ lsearch $permute $tmp3 ] != -1  } {
set tmp3 [RandomNumber 1 50] 
} 
lappend permute $tmp3
set qc $tmp3
regsub -all ":$i" $q2sub $qc q2sub
	}
   }
17 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set qc [ pick_str_2 [ get_dists p_cntr ] p_cntr ]
regsub -all {:2} $q2sub $qc q2sub
 }
18 {
regsub -all {:1} $q2sub [RandomNumber 312 315] q2sub
}
19 {
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:1} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:2} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
set tmp1 [RandomNumber 1 5] 
set tmp2 [RandomNumber 1 5] 
regsub {:3} $q2sub [ concat Brand\#$tmp1$tmp2 ] q2sub
regsub -all {:4} $q2sub [RandomNumber 1 10] q2sub
regsub -all {:5} $q2sub [RandomNumber 10 20] q2sub
regsub -all {:6} $q2sub [RandomNumber 20 30] q2sub
}
20 {
set qc [ pick_str_2 [ get_dists colors ] colors ]
regsub -all {:1} $q2sub $qc q2sub
set tmp_date [RandomNumber 93 97]
regsub -all {:2} $q2sub [concat 19$tmp_date-01-01] q2sub
set qc [ pick_str_2 [ get_dists nations2 ] nations2 ]
regsub -all {:3} $q2sub $qc q2sub
	}
21 {
set qc [ pick_str_2 [ get_dists nations2 ] nations2 ]
regsub -all {:1} $q2sub $qc q2sub
}
22 {
set permute [list]
for {set i 0} {$i <= 7} {incr i} {
set tmp3 [RandomNumber 10 34] 
while { [ lsearch $permute $tmp3 ] != -1  } {
set tmp3 [RandomNumber 10 34] 
} 
lappend permute $tmp3
set qc $tmp3
regsub -all ":$i" $q2sub $qc q2sub
	}
    }
}
return $q2sub
}
#########################
#TPCH QUERY SETS PROCEDURE
proc do_tpch { host port db user password scale_factor RAISEERROR VERBOSE degree_of_parallel total_querysets myposition } {
#Queries 17 and 20 are long running on PostgreSQL
set SKIP_QUERY_17_20 "false" 
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 	}
set result [ pg_exec $lda "set max_parallel_workers_per_gather=$degree_of_parallel"]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
        pg_result $result -clear
        }
for {set it 0} {$it < $total_querysets} {incr it} {
if {  [ tsv::get application abort ]  } { break }
set start [ clock seconds ]
for { set q 1 } { $q <= 22 } { incr q } {
set dssquery($q)  [sub_query $q $scale_factor $myposition ]
if {$q != 15} {
	;
} else {
set query15list [split $dssquery($q) "\;"]
            set q15length [llength $query15list]
            set q15c 0
            while {$q15c <= [expr $q15length - 1]} {
            set dssquery($q,$q15c) [lindex $query15list $q15c]
            incr q15c
		}
	}
}
set o_s_list [ ordered_set $myposition ]
for { set q 1 } { $q <= 22 } { incr q } {
if {  [ tsv::get application abort ]  } { break }
set qos [ lindex $o_s_list [ expr $q - 1 ] ]
puts "Executing Query $qos ($q of 22)"
if {$VERBOSE} { puts $dssquery($qos) }
if {$qos != 15} {
if {(($qos eq 17) || ($qos eq 20))  && $SKIP_QUERY_17_20 eq "true" } { 
puts "Long Running Queries 17 and 20 Not Executed"
	} else {
set t0 [clock clicks -millisec]
standsql $lda $dssquery($qos) $RAISEERROR $VERBOSE
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
puts "query $qos completed in $value seconds"
		}
	      } else {
            set q15c 0
            while {$q15c <= [expr $q15length - 1] } {
	if { $q15c != 1 } {
set result [ pg_exec $lda "$dssquery($qos,$q15c)" ]
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Query 15 view error set RAISEERROR for Details"
		}  
	} else {
pg_result $result -clear
	}
	} else {
set t0 [clock clicks -millisec]
if {[catch { pg_select $lda $dssquery($qos,$q15c) var { if { $VERBOSE } { 
foreach index [array names var] { if { $index > 2} {puts $var($index)} } } } } message]} {
if { $RAISEERROR } {
error "Query Error : $message"
	} else {
puts "Query Failed : $dssquery($qos,$q15c) : $message"
	}
      } 
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
puts "query $qos completed in $value seconds"
		}
            incr q15c
		}
        }
  }
set end [ clock seconds ]
set wall [ expr $end - $start ]
set qsets [ expr $it + 1 ]
puts "Completed $qsets query set(s) in $wall seconds"
	}
pg_disconnect $lda
 }
#########################
#RUN TPC-H
set rema [ lassign [ findvuhposition ] myposition totalvirtualusers ]
set power_test "false"
if { $totalvirtualusers eq 1 } {
#Power Test
set power_test "true"
set myposition 0
        }
if { $refresh_on } {
if { $power_test } {
set trickle_refresh 0
set update_sets 1
set REFRESH_VERBOSE "false"
do_refresh $host $port $db $user $password $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE RF1
do_tpch $host $port $db $user $password $scale_factor $RAISEERROR $VERBOSE $degree_of_parallel $total_querysets 0
do_refresh $host $port $db $user $password $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE RF2
	} else {
switch $myposition {
1 { 
do_refresh $host $port $db $user $password $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE BOTH
	}
default { 
do_tpch $host $port $db $user $password $scale_factor $RAISEERROR $VERBOSE $degree_of_parallel $total_querysets [ expr $myposition - 1 ] 
	}
    }
 }
} else {
do_tpch $host $port $db $user $password $scale_factor $RAISEERROR $VERBOSE $degree_of_parallel $total_querysets $myposition 
	}}
}

proc loadpgcloud {} {
global _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict postgresql library ]} {
        set library [ dict get $dbdict postgresql library ]
} else { set library "Pgtcl" }
upvar #0 configpostgresql configpostgresql
#set variables to values in dict
setlocaltpchvars $configpostgresql
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "PostgreSQL Cloud"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# PostgreSQL Library
set RAISEERROR \"$pg_raise_query_error\" ;# Exit script on PostgreSQL query error (true or false)
set VERBOSE \"$pg_verbose\" ;# Show query text and output
set degree_of_parallel \"$pg_degree_of_parallel\" ;# Degree of Parallelism
set redshift_compat \"$pg_rs_compat\" ;# Queries to run against redshift (true or false)
set host \"$pg_host\" ;# Address of the server hosting PostgreSQL
set port \"$pg_port\" ;# Port of the PostgreSQL Server
set user \"$pg_tpch_user\" ;# PostgreSQL user
set password \"$pg_tpch_pass\" ;# Password for the PostgreSQL user
set db \"$pg_tpch_dbase\" ;# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpchcommon} ] { error "Failed to load tpch common functions" } else { namespace import tpchcommon::* }

proc standsql { lda sql RAISEERROR VERBOSE } {
set rowcount 0
if {[catch { pg_select $lda $sql var { 
set rowcount [ expr $var(.tupno) + 1 ]
if { $VERBOSE } { 
foreach index [array names var] { if { $index > 2} {puts $var($index)} } } } } message]} {
if { $RAISEERROR } {
error "Query Error : $message"
	} else {
puts "Query Failed : $sql : $message"
	}
   } 
return [ expr $rowcount ]
}

proc ConnectToPostgres { host port user password dbname } {
global tcl_platform
if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]} message]} {
puts $message
error $message
 } else {
if {$tcl_platform(platform) == "windows"} {
#Workaround for Bug #95 where first connection fails on Windows
catch {pg_disconnect $lda}
set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]
        }
pg_notice_handler $lda puts
set result [ pg_exec $lda "set CLIENT_MIN_MESSAGES TO 'ERROR'" ]
pg_result $result -clear
        }
return $lda
}

proc create_median_and_percentile { lda } {
#create median and percentile with pg prefix as median or percentile exists in some versions but not all
set sql(1) { CREATE OR REPLACE FUNCTION _final_pgmedian(anyarray) RETURNS float8 AS $$ WITH q AS ( SELECT val FROM unnest($1) val WHERE VAL IS NOT NULL ORDER BY 1), cnt AS ( SELECT COUNT(*) AS c FROM q) SELECT AVG(val)::float8 FROM ( SELECT val FROM q LIMIT  2 - MOD((SELECT c FROM cnt), 2) OFFSET GREATEST(CEIL((SELECT c FROM cnt) / 2.0) - 1,0)  ) q2;
$$ LANGUAGE SQL IMMUTABLE; }
set sql(2) { DROP AGGREGATE IF EXISTS pgmedian(anyelement) }
set sql(3) { CREATE AGGREGATE pgmedian(anyelement) ( SFUNC=array_append, STYPE=anyarray, FINALFUNC=_final_pgmedian, INITCOND='{}'); }
set sql(4) { CREATE OR REPLACE FUNCTION pgarray_sort (ANYARRAY) RETURNS ANYARRAY LANGUAGE SQL AS $$ SELECT ARRAY( SELECT $1[s.i] AS "ast" FROM generate_series(array_lower($1,1), array_upper($1,1)) AS s(i) ORDER BY ast); $$; }
set sql(5) { CREATE OR REPLACE FUNCTION pgpercentile_cont(myarray real[], percentile real) RETURNS real AS $$ DECLARE ary_cnt INTEGER; row_num real; crn real; frn real; calc_result real; new_array real[]; BEGIN ary_cnt = array_length(myarray,1); row_num = 1 + ( percentile * ( ary_cnt - 1 )); new_array = pgarray_sort(myarray); crn = ceiling(row_num); frn = floor(row_num); if crn = frn and frn = row_num then calc_result = new_array[row_num]; else calc_result = (crn - row_num) * new_array[frn] + (row_num - frn) * new_array[crn]; end if; RETURN calc_result; END; $$ LANGUAGE 'plpgsql' IMMUTABLE; }
for { set i 1 } { $i <= 5 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	}  else {
	pg_result $result -clear
	}
    }
return
 }
#########################
#CLOUD ANALYTIC TPCH QUERY GENERATION
proc set_query { VERSION } {
global sql
if { $VERSION eq "postgres" } {
set sql(1) "SELECT * FROM (SELECT p_brand , SUM(l_extendedprice * ( 1 - l_discount)) AS revenue FROM LINEITEM , PART WHERE l_partkey = p_partkey AND l_shipdate >= date '1997-01-01' AND l_shipdate < date '1997-01-01'  + interval '1' year GROUP BY p_brand ORDER BY revenue DESC) AS SUBQ LIMIT 10"
#No Median or Percentile functions in some versions of PostgreSQL
set sql(2) "SELECT pgmedian(o_totalprice) FROM ORDERS , CUSTOMER , NATION WHERE c_custkey = o_custkey AND c_nationkey = n_nationkey AND n_name = 'GERMANY'"
set sql(3) "SELECT pgpercentile_cont(array_agg(o_totalprice), 0.75) as percentile from (SELECT o_totalprice FROM ORDERS , CUSTOMER , NATION WHERE c_custkey = o_custkey AND c_nationkey = n_nationkey AND n_name = 'GERMANY') AS SUBQ"
set sql(4) "SELECT pgmedian(l_discount) FROM ORDERS , CUSTOMER , LINEITEM , NATION WHERE c_custkey = o_custkey AND o_orderkey = l_orderkey AND c_nationkey = n_nationkey AND n_name = 'GERMANY' AND o_orderdate BETWEEN date '1995-01-01' AND date '1995-12-31'"
set sql(5) "SELECT SUM(l_quantity) AS sum_qty , SUM(l_extendedprice) AS sum_base_price , SUM(l_extendedprice * ( 1 - l_discount)) AS sum_disc_price , SUM(l_extendedprice * ( 1 - l_discount) * ( 1 + l_tax)) AS sum_charge , Avg(l_quantity) AS avg_qty , Avg(l_extendedprice) AS avg_price , Avg(l_discount) AS avg_disc , Count(*) AS count_order FROM LINEITEM WHERE l_orderkey IN (SELECT o_orderkey FROM ORDERS WHERE o_orderdate >= date '1995-01-01' AND o_orderdate < date '1995-01-01' + interval '6' day AND o_clerk = 'Clerk#007373565')"
set sql(6) "SELECT * FROM (SELECT c_name , Count(*) ocount FROM ORDERS , CUSTOMER WHERE o_custkey = c_custkey AND o_orderStatus = 'F' AND ( EXISTS ( SELECT 1 FROM LINEITEM , PART WHERE l_orderkey = o_orderkey AND l_partkey = p_partkey AND p_size < 5) OR EXISTS ( SELECT 1 FROM LINEITEM , PART WHERE l_orderkey = o_orderkey AND l_partkey = p_partkey AND p_type = 'STANDARD PLATED TIN' )) GROUP BY c_name ORDER BY 1 , 2) AS SUBQ LIMIT 100"
set sql(7) "SELECT * FROM (SELECT p_partkey , Count(*) ocount FROM LINEITEM , SUPPLIER , ORDERS , PART WHERE l_orderkey = o_orderkey AND l_partkey = p_partkey AND l_suppkey = s_suppkey AND l_discount < 0.02 AND p_size < 41 GROUP BY p_partkey ORDER BY 1,2) AS SUBQ LIMIT 100"
set sql(8) "SELECT * FROM (SELECT p_name , p_mfgr , p_brand , p_type , p_size , p_container , p_retailprice , p_comment , qty , qty * p_retailprice FROM ( SELECT l_partkey PARTkey , SUM(l_quantity) qty FROM LINEITEM WHERE l_orderkey IN (SELECT o_orderkey FROM ORDERS WHERE o_orderdate = date '1996-04-30' AND o_orderpriority = '1 - URGENT' AND o_totalprice > 480000) GROUP BY l_partkey) PartiallyFullfiledOrders , PART WHERE p_partkey = PartiallyFullfiledOrders .  PARTkey ORDER BY qty * p_retailprice) AS SUBQ LIMIT 10"
set sql(9) "SELECT l.l_shipdate , l.l_discount , l.l_extendedprice , l.l_quantity , l.l_returnflag , l.l_linestatus , l.l_tax , l.l_commitdate , l.l_receiptdate , l.l_shipmode , l.l_linenumber , l.l_shipinstruct , l.l_comment , s.s_comment , s.s_name , s.s_address , s.s_phone , s.s_acctbal FROM (SELECT l_orderkey , l_suppkey , SUM(l_quantity) sqty , SUM(ps_availqty) aqty FROM LINEITEM, PARTSUPP WHERE l_orderkey IN (SELECT o_orderkey FROM ORDERS WHERE o_orderdate BETWEEN date '1996-04-01' AND date '1996-04-01' + interval '1' month AND o_orderpriority = '4 - NOT SPECIFIED' AND o_totalprice < 850) AND l_partkey = ps_partkey GROUP BY l_orderkey , l_suppkey) t , LINEITEM l , SUPPLIER s WHERE t.l_orderkey = l.l_orderkey AND t.l_suppkey = s .  s_suppkey AND sqty < aqty"
set sql(10) "SELECT * FROM (SELECT p_partkey , Count(*) ocount FROM LINEITEM , PART WHERE l_partkey = p_partkey AND NOT EXISTS (SELECT o_orderkey FROM ORDERS WHERE o_orderkey = l_orderkey) AND NOT EXISTS ( SELECT 1 FROM SUPPLIER WHERE l_suppkey = s_suppkey) AND l_discount < 1.1 AND p_size < 45 GROUP BY p_partkey ORDER BY 1 , 2) AS SUBQ"
set sql(11) "SELECT * FROM (SELECT p_partkey , Count(*) ocount FROM LINEITEM , PART WHERE l_orderkey NOT IN ( SELECT o_orderkey FROM ORDERS) AND l_partkey = p_partkey AND l_suppkey NOT IN ( SELECT s_suppkey FROM SUPPLIER) AND l_discount < 0.5 AND p_size < 41 GROUP BY p_partkey ORDER BY 1, 2) AS SUBQ LIMIT 100"
set sql(12) "SELECT * FROM (SELECT o_orderkey, o_custkey, o_orderdate, o_orderstatus, o_totalprice, o_orderpriority FROM ORDERS WHERE o_totalprice < 50005 AND o_orderdate >= date '1995-01-01' AND o_orderdate < date '1995-01-01' + interval '12' month AND (o_orderkey, (o_orderdate - interval '1' month)) NOT IN(SELECT CASE WHEN l_orderkey > 5 THEN l_orderkey ELSE NULL END, l_commitdate FROM LINEITEM WHERE l_extendedprice < 1001 AND l_shipdate >= date '1995-01-01' AND l_shipdate < date '1995-01-01' + interval '12' month) ORDER BY 1,2,3,4,5) AS SUBQ LIMIT 100"
#No HyperLogLog Approx_count_distinct function in PostgreSQL replaced with count(distinct)
set sql(13) "SELECT p_brand , p_type , p_size , count(distinct ps_suppkey) AS supplier_cnt FROM PARTSUPP , PART WHERE p_partkey = ps_partkey AND p_brand <> 'Brand#15' AND p_type NOT LIKE 'LARGE PLATED%' AND p_size IN ( 21) AND ps_suppkey NOT IN ( SELECT s_suppkey FROM SUPPLIER WHERE s_comment LIKE '%Customer%Complaints%') GROUP BY p_brand , p_type , p_size ORDER BY supplier_cnt DESC , p_brand , p_type , p_size"
	} else {
set sql(1) "SELECT p_brand, SUM (l_extendedprice * (1 - l_discount)) AS revenue FROM lineitem, part WHERE l_partkey = p_partkey AND l_shipdate >= To_date ('1997-01-01','YYYY-MM-DD') AND l_shipdate < Add_months (To_date('1997-01-01','YYYY-MM-DD'),24) GROUP BY p_brand ORDER BY revenue DESC LIMIT 10"
set sql(2) "SELECT top 1 Median (o_totalprice) over() FROM orders, customer, nation WHERE c_custkey = o_custkey AND c_nationkey = n_nationkey AND n_name = 'GERMANY'"
set sql(3) "SELECT top 1 Percentile_cont(0.75) WITHIN GROUP (ORDER BY o_totalprice) over() FROM orders, customer, nation WHERE c_custkey = o_custkey AND c_nationkey = n_nationkey AND n_name = 'GERMANY'"
set sql(4) "SELECT top 1 Median (l_discount) over() FROM orders, customer, lineitem, nation WHERE c_custkey = o_custkey AND o_orderkey = l_orderkey AND c_nationkey = n_nationkey AND n_name = 'GERMANY' AND o_orderdate BETWEEN To_date('1995-01-01','YYYY-MM-DD') AND To_date('1995-12-31','YYYY-MM-DD')"
set sql(5) "SELECT SUM (l_quantity) AS sum_qty, SUM (l_extendedprice) AS sum_base_price, SUM (l_extendedprice * (1-l_discount)) AS sum_disc_price, SUM (l_extendedprice * (1-l_discount) * (1 + l_tax)) AS sum_charge, Avg (l_quantity) AS avg_qty, Avg (l_extendedprice) AS avg_price, Avg (l_discount) AS avg_disc, Count (*) AS count_order FROM lineitem WHERE l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderdate >= To_date ('1995-01-01','YYYY-MM-DD') AND o_orderdate < To_date ('1995-01-01','YYYY-MM-DD') + 6 AND o_clerk = 'Clerk#007373565')"
set sql(6) "SELECT c_name, Count (*) ocount FROM orders , customer WHERE o_custkey = c_custkey AND o_orderstatus = 'F' AND (EXISTS (SELECT 1 FROM lineitem, part WHERE l_orderkey = o_orderkey AND l_partkey = p_partkey AND p_size < 5) OR EXISTS (SELECT 1 FROM lineitem, part WHERE l_orderkey = o_orderkey AND l_partkey = p_partkey AND p_type = 'STANDARD PLATED TIN')) GROUP BY c_name ORDER BY 1, 2 LIMIT 100"
set sql(7) "SELECT p_partkey, Count (*) ocount FROM lineitem, supplier, orders, part WHERE l_orderkey = o_orderkey AND l_partkey = p_partkey AND l_suppkey = s_suppkey AND l_discount < 0.02 AND p_size < 41 GROUP BY p_partkey ORDER BY 1, 2 LIMIT 100"
set sql(8) "SELECT p_name, p_mfgr, p_brand, p_type, p_size, p_container, p_retailprice, p_comment, qty, qty * p_retailprice FROM (SELECT l_partkey partkey, SUM (l_quantity) qty FROM lineitem WHERE l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderdate = To_date ('1996-04-30', 'YYYY-MM-DD') AND o_orderpriority = '1 - URGENT' AND o_totalprice > 480000) GROUP BY l_partkey) PartiallyFullfiledOrders, part WHERE p_partkey = PartiallyFullfiledOrders.partkey ORDER BY qty * p_retailprice LIMIT 10"
set sql(9) "SELECT l.l_shipdate, l.l_discount, l.l_extendedprice, l.l_quantity, l.l_returnflag, l.l_linestatus, l.l_tax, l.l_commitdate, l.l_receiptdate, l.l_shipmode,l .l_linenumber, l.l_shipinstruct, l.l_comment, s.s_comment, s.s_name, s.s_address, s.s_phone, s.s_acctbal FROM (SELECT l_orderkey, l_suppkey, SUM(l_quantity) sqty, SUM (ps_availqty) aqty FROM lineitem, partsupp WHERE l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_orderdate BETWEEN To_date ('1996-04-01', 'YYYY-MM-DD') AND Add_months (To_date ('1996-04-01','YYYY-MM-DD'), 1) AND o_orderpriority = '4 - NOT SPECIFIED' AND o_totalprice < 850) AND l_partkey = ps_partkey GROUP BY l_orderkey, l_suppkey) t, lineitem l, supplier s WHERE t.l_orderkey = l.l_orderkey AND t.l_suppkey = s.s_suppkey AND sqty < aqty"
set sql(10) "SELECT p_partkey, Count (*) ocount FROM lineitem, part WHERE l_partkey = p_partkey AND NOT EXISTS (SELECT o_orderkey FROM orders WHERE o_orderkey = l_orderkey) AND NOT EXISTS (SELECT 1 FROM supplier WHERE l_suppkey = s_suppkey) AND l_discount < 1.1 AND p_size < 45 GROUP BY p_partkey ORDER BY 1, 2 LIMIT 100"
set sql(11) "SELECT p_partkey, Count (*) ocount FROM lineitem, part WHERE l_orderkey NOT IN (SELECT o_orderkey FROM orders) AND l_partkey = p_partkey AND l_suppkey NOT IN (SELECT s_suppkey FROM supplier) AND l_discount < 0.5 AND p_size < 41 GROUP BY p_partkey ORDER BY 1, 2 LIMIT 100"
set sql(12) "SELECT o_orderkey, o_custkey, o_orderdate, o_orderstatus, o_totalprice, o_orderpriority FROM orders WHERE o_totalprice < 50005 AND o_orderdate >= To_date('1995-01-01','YYYY-MM-DD') AND o_orderdate < Add_months(To_date('1995-01-01','YYYY-MM-DD'),12) AND (o_orderkey, Add_months(o_orderdate,-1)) NOT IN (SELECT CASE WHEN l_orderkey > 5 THEN l_orderkey ELSE NULL END, l_commitdate FROM lineitem WHERE l_extendedprice < 1001 AND l_shipdate >= To_date('1995-01-01','YYYY-MM-DD') AND l_shipdate < Add_months (To_date('1995-01-01','YYYY-MM-DD'),12)) ORDER BY 1, 2, 3, 4, 5 LIMIT 100"
set sql(13) "SELECT p_brand, p_type, p_size, Approximate count(distinct ps_suppkey) AS supplier_cnt FROM partsupp, part WHERE p_partkey = ps_partkey AND p_brand <> 'Brand#15' AND p_type NOT LIKE 'LARGE PLATED%' AND p_size IN (21) AND ps_suppkey NOT IN (SELECT s_suppkey FROM supplier WHERE s_comment LIKE '%Customer%Complaints%') GROUP BY p_brand, p_type, p_size ORDER BY supplier_cnt DESC, p_brand, p_type, p_size"
	}
}

proc get_query { query_no VERSION } {
global sql
if { ![ array exists sql ] } { set_query $VERSION }
return $sql($query_no)
}
#########################
#CLOUD ANALYTIC TPCH QUERY SETS PROCEDURE
proc do_cloud { host port user password db RAISEERROR VERBOSE degree_of_parallel redshift_compat } {
if { $redshift_compat } {
set VERSION "redshift"	
	} else {
set VERSION "postgres"	
	}
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $VERSION eq "postgres" } {
create_median_and_percentile $lda
set result [ pg_exec $lda "set max_parallel_workers_per_gather=$degree_of_parallel"]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
        pg_result $result -clear
        }
	}
unset -nocomplain qlist
set start [ clock seconds ]
for { set q 1 } { $q <= 13 } { incr q } {
if {  [ tsv::get application abort ]  } { break }
unset -nocomplain query
set query [ get_query $q $VERSION ]
puts "Executing Query ($q of 13)"
if {$VERBOSE} { puts $query }
set t0 [clock clicks -millisec]
set oput [ standsql $lda $query $RAISEERROR $VERBOSE ]
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
set rowcount $oput
puts "$rowcount rows returned in $value seconds"
if {$VERBOSE} { printlist $oput }
if { $rowcount > 0 } { lappend qlist $value }
	      } 
set end [ clock seconds ]
set wall [ expr $end - $start ]
puts "Completed query set in $wall seconds"
puts "Geometric mean of query times returning rows is [ format \"%.5f\" [ gmean $qlist ]]"
pg_disconnect $lda
 }
#########################
#RUN CLOUD ANALYTIC TPC-H
do_cloud $host $port $user $password $db $RAISEERROR $VERBOSE $degree_of_parallel $redshift_compat}
}
