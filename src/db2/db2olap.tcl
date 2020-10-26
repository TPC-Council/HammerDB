proc build_db2tpch {} {
global maxvuser suppo ntimes threadscreated _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict db2 library ]} {
        set library [ dict get $dbdict db2 library ]
} else { set library "db2tcl" }
upvar #0 configdb2 configdb2
#set variables to values in dict
setlocaltpchvars $configdb2
if { $db2_tpch_organizeby eq "COL" } { set db2_tpch_organizeby "COLUMN" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a Scale Factor $db2_scale_fact TPROC-H schema under user [ string toupper $db2_tpch_user ]\n in database [ string toupper $db2_tpch_dbase ]?" -type yesno ] == yes} {
if { $db2_num_tpch_threads eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $db2_num_tpch_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "Db2 TPROC-H creation"
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

proc GatherStatistics { db_handle } {
puts "GATHERING SCHEMA STATISTICS"
set sql(1) "call admin_cmd('runstats on table ORDERS with distribution and detailed indexes all')"
set sql(2) "call admin_cmd('runstats on table PARTSUPP with distribution and detailed indexes all')"
set sql(3) "call admin_cmd('runstats on table CUSTOMER with distribution and detailed indexes all')"
set sql(4) "call admin_cmd('runstats on table PART with distribution and detailed indexes all')"
set sql(5) "call admin_cmd('runstats on table SUPPLIER with distribution and detailed indexes all')"
set sql(6) "call admin_cmd('runstats on table NATION with distribution and detailed indexes all')"
set sql(7) "call admin_cmd('runstats on table REGION with distribution and detailed indexes all')"
set sql(8) "call admin_cmd('runstats on table LINEITEM with distribution and detailed indexes all')"
for { set i 1 } { $i <= 8 } { incr i } {
puts -nonewline "$i.."
db2_exec_direct $db_handle $sql($i)
    }
}

proc ConnectToDb2 { dbname user password } {
puts "Connecting to database $dbname"
if {[catch {set db_handle [db2_connect $dbname $user $password ]} message]} {
error $message
 } else {
puts "Connection established"
return $db_handle
}}

proc CreateTables { db_handle tspace organization } {
puts "CREATING TPCH TABLES"
if { $organization eq "DATE" } { 
set ord_organization "organize by (O_ORDERDATE)"
set lin_organization "organize by (L_SHIPDATE)"
set organization ""
} else {
set ord_organization $organization
set lin_organization $organization
	}
if { $organization eq "DATE" } { set lin_organization "organize by (L_SHIPDATE)" } else {

set organization ""
	}
set sql(1) "CREATE TABLE ORDERS (
O_ORDERKEY INTEGER NOT NULL,
O_CUSTKEY INTEGER NOT NULL,
O_ORDERSTATUS CHAR(1) NOT NULL,
O_TOTALPRICE FLOAT NOT NULL,
O_ORDERDATE DATE NOT NULL,
O_ORDERPRIORITY CHAR(15) NOT NULL,
O_CLERK CHAR(15) NOT NULL,
O_SHIPPRIORITY INTEGER NULL,
O_COMMENT VARCHAR(79) NOT NULL) IN $tspace $ord_organization"
set sql(2) "CREATE TABLE PARTSUPP (
PS_PARTKEY INTEGER NOT NULL,
PS_SUPPKEY INTEGER NOT NULL,
PS_AVAILQTY INTEGER NOT NULL,
PS_SUPPLYCOST FLOAT NOT NULL,
PS_COMMENT VARCHAR(199) NOT NULL) IN $tspace $organization"
set sql(3) "CREATE TABLE CUSTOMER (
C_CUSTKEY INTEGER NOT NULL,
C_NAME VARCHAR(25) NOT NULL,
C_ADDRESS VARCHAR(40) NOT NULL,
C_NATIONKEY INTEGER NOT NULL,
C_PHONE CHAR(15) NOT NULL,
C_ACCTBAL FLOAT NOT NULL,
C_MKTSEGMENT CHAR(10) NOT NULL,
C_COMMENT VARCHAR(118) NOT NULL) IN $tspace $organization"
set sql(4) "CREATE TABLE PART (
P_PARTKEY INTEGER NOT NULL,
P_NAME VARCHAR(55) NOT NULL,
P_MFGR CHAR(25) NOT NULL,
P_BRAND CHAR(10) NOT NULL,
P_TYPE VARCHAR(25) NOT NULL,
P_SIZE INTEGER NOT NULL,
P_CONTAINER CHAR(10) NOT NULL,
P_RETAILPRICE FLOAT NOT NULL,
P_COMMENT VARCHAR(23) NULL) IN $tspace $organization"
set sql(5) "CREATE TABLE SUPPLIER (
S_SUPPKEY INTEGER NOT NULL,
S_NAME CHAR(25) NOT NULL,
S_ADDRESS VARCHAR(40) NOT NULL,
S_NATIONKEY INTEGER NOT NULL,
S_PHONE CHAR(15) NOT NULL,
S_ACCTBAL FLOAT NOT NULL,
S_COMMENT VARCHAR(102) NOT NULL) IN $tspace $organization"
set sql(6) "CREATE TABLE NATION (
N_NATIONKEY INTEGER NOT NULL,
N_NAME CHAR(25) NOT NULL,
N_REGIONKEY INTEGER NOT NULL,
N_COMMENT VARCHAR(152)) IN $tspace $organization"
set sql(7) "CREATE TABLE REGION (
R_REGIONKEY INTEGER NOT NULL,
R_NAME CHAR(25) NOT NULL,
R_COMMENT VARCHAR(152)) IN $tspace $organization"
set sql(8) "CREATE TABLE LINEITEM (
L_ORDERKEY INTEGER NOT NULL,
L_PARTKEY INTEGER NOT NULL,
L_SUPPKEY INTEGER NOT NULL,
L_LINENUMBER INTEGER NOT NULL,
L_QUANTITY FLOAT NOT NULL,
L_EXTENDEDPRICE FLOAT NOT NULL,
L_DISCOUNT FLOAT NOT NULL,
L_TAX FLOAT NOT NULL,
L_RETURNFLAG CHAR(1) NOT NULL,
L_LINESTATUS CHAR(1) NOT NULL,
L_SHIPDATE DATE NULL,
L_COMMITDATE DATE NULL,
L_RECEIPTDATE DATE NULL,
L_SHIPINSTRUCT CHAR(25) NOT NULL,
L_SHIPMODE CHAR(10) NOT NULL,
L_COMMENT VARCHAR(44) NOT NULL) IN $tspace $lin_organization"
for { set i 1 } { $i <= 8 } { incr i } {
db2_exec_direct $db_handle $sql($i)
                }
return
}

proc mk_region { db_handle } {
for { set i 1 } { $i <= 5 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists regions ] [ expr {$i - 1} ] ] 0 ]
set comment [ TEXT_1 72 ]
db2_exec_direct $db_handle "INSERT INTO REGION (R_REGIONKEY,R_NAME,R_COMMENT) VALUES ('$code' , '$text' , '$comment')"
	}
 }

proc mk_nation { db_handle } {
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
db2_exec_direct $db_handle "INSERT INTO NATION (N_NATIONKEY, N_NAME, N_REGIONKEY, N_COMMENT) VALUES ('$code' , '$text' , '$join' , '$comment')"
	}
}

proc mk_supp { db_handle start_rows end_rows } {
set BBB_COMMEND   "Recommends"
set BBB_COMPLAIN  "Complaints"
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
if { ![ expr {$i % 1000} ] || $i eq $end_rows } {    
db2_exec_direct $db_handle "INSERT INTO SUPPLIER (S_SUPPKEY, S_NATIONKEY, S_COMMENT, S_NAME, S_ADDRESS, S_PHONE, S_ACCTBAL) VALUES $supp_val_list"
	unset supp_val_list
	} else {
	append supp_val_list ,
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading SUPPLIER...$i"
	}
   }
puts "SUPPLIER Done Rows $start_rows..$end_rows"
return
}

proc mk_cust { db_handle start_rows end_rows } {
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
if { ![ expr {$i % 1000} ] || $i eq $end_rows } {    
db2_exec_direct $db_handle "INSERT INTO CUSTOMER (C_CUSTKEY, C_MKTSEGMENT, C_NATIONKEY, C_NAME, C_ADDRESS, C_PHONE, C_ACCTBAL, C_COMMENT) values $cust_val_list"
	unset cust_val_list
   	} else { 
	append cust_val_list ,
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading CUSTOMER...$i"
	}
}
puts "Customer Done Rows $start_rows..$end_rows"
return
}

proc mk_part { db_handle start_rows end_rows scale_factor } {
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
if { $k<=2 } { 
append psupp_val_list ,
	}
}
# end of psupp loop
if { ![ expr {$i % 10} ]  || $i eq $end_rows } {     
db2_exec_direct $db_handle "INSERT INTO PART (P_PARTKEY, P_TYPE, P_SIZE, P_BRAND, P_NAME, P_CONTAINER, P_MFGR, P_RETAILPRICE, P_COMMENT) VALUES $part_val_list"
db2_exec_direct $db_handle "INSERT INTO PARTSUPP (PS_PARTKEY, PS_SUPPKEY, PS_SUPPLYCOST, PS_AVAILQTY, PS_COMMENT) VALUES $psupp_val_list"
	unset part_val_list
	unset psupp_val_list
	} else {
	append part_val_list ,
	append psupp_val_list ,
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading PART/PARTSUPP...$i"
	}
}
puts "PART and PARTSUPP Done Rows $start_rows..$end_rows"
return
}

proc mk_order { db_handle start_rows end_rows upd_num scale_factor } {
for {set j 1} {$j <=70} { incr j} {
for {set k 1} {$k <=70} { incr k} {
append livallist (timestamp_format(?,'YYYY-MON-DD'), ?, ?, ?, ?, ?, ?, ?, ?, ?, timestamp_format(?,'YYYY-MON-DD'), timestamp_format(?,'YYYY-MON-DD'), ?, ?, ?, ?)
if ($k<$j) { append livallist ,} else {
if { $k eq $j } {
set j2 [ concat $start_rows$j ]
set stmnt_handle_li_$j2 [ db2_prepare $db_handle "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) VALUES $livallist" ]
unset livallist
break }
}}}
for {set k 1} {$k <=10} { incr k} {
append orvallist (timestamp_format(?,'YYYY-MON-DD'), ?, ?, ?, ?, ?, ?, ?, ?) 
if ($k<10) { append orvallist ,}
}
set stmnt_handle_or [ db2_prepare $db_handle "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) VALUES $orvallist" ]
set refresh 100
set delta 1
set L_PKEY_MAX   [ expr {200000 * $scale_factor} ]
set O_CKEY_MAX [ expr {150000 * $scale_factor} ]
set O_ODATE_MAX [ expr {(92001 + 2557 - (121 + 30) - 1)} ]
set lcnt_total 0
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
set lcnt_total [ expr $lcnt_total + $lcnt ]
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
lappend lineit_val_list $lsdate $lokey $ldiscount $leprice $lsuppkey $lquantity $lrflag $lpartkey $lstatus $ltax $lcdate $lrdate $lsmode $llcnt $linstruct $lcomment
  }
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
lappend order_val_list $date $okey $custkey $opriority $spriority $clerk $orderstatus $totalprice $comment
if { ![ expr {$i % 10} ]  || $i eq $end_rows } {     
set lcnt2 [ concat $start_rows$lcnt_total ]
set stmnt stmnt_handle_li_$lcnt2
db2_bind_exec [ set $stmnt ] "$lineit_val_list"
db2_bind_exec $stmnt_handle_or "$order_val_list"
	unset lineit_val_list
	unset order_val_list
        set lcnt_total 0
   	} 
if { ![ expr {$i % 10000} ] } {
	puts "Loading ORDERS/LINEITEM...$i"
	}
}
puts "ORDERS and LINEITEM Done Rows $start_rows..$end_rows"
return
}

proc CreateIndexes { db_handle } {
puts "CREATING TPCH INDEXES"
set sql(1) "ALTER TABLE REGION ADD PRIMARY KEY (R_REGIONKEY)"
set sql(2) "ALTER TABLE NATION ADD PRIMARY KEY (N_NATIONKEY)"
set sql(3) "ALTER TABLE SUPPLIER ADD PRIMARY KEY (S_SUPPKEY)"
set sql(4) "ALTER TABLE PARTSUPP ADD PRIMARY KEY(PS_PARTKEY,PS_SUPPKEY)"
set sql(5) "ALTER TABLE PART ADD PRIMARY KEY (P_PARTKEY)"
set sql(6) "ALTER TABLE ORDERS ADD PRIMARY KEY (O_ORDERKEY)"
set sql(7) "ALTER TABLE LINEITEM ADD PRIMARY KEY (L_LINENUMBER, L_ORDERKEY)"
set sql(8) "ALTER TABLE CUSTOMER ADD PRIMARY KEY (C_CUSTKEY)"
set sql(9) "ALTER TABLE LINEITEM ADD FOREIGN KEY (L_PARTKEY, L_SUPPKEY) REFERENCES PARTSUPP(PS_PARTKEY, PS_SUPPKEY)"
set sql(10) "ALTER TABLE ORDERS ADD FOREIGN KEY (O_CUSTKEY) REFERENCES CUSTOMER (C_CUSTKEY)"
set sql(11) "ALTER TABLE PARTSUPP ADD FOREIGN KEY (PS_PARTKEY) REFERENCES PART (P_PARTKEY)"
set sql(12) "ALTER TABLE PARTSUPP ADD FOREIGN KEY (PS_SUPPKEY) REFERENCES SUPPLIER (S_SUPPKEY)"
set sql(13) "ALTER TABLE SUPPLIER ADD FOREIGN KEY (S_NATIONKEY) REFERENCES NATION (N_NATIONKEY)"
set sql(14) "ALTER TABLE CUSTOMER ADD FOREIGN KEY (C_NATIONKEY) REFERENCES NATION (N_NATIONKEY)"
set sql(15) "ALTER TABLE NATION ADD FOREIGN KEY N_REGIONKEY) REFERENCES REGION (R_REGIONKEY)"
set sql(16) "ALTER TABLE LINEITEM ADD FOREIGN KEY (L_ORDERKEY) REFERENCES ORDERS (O_ORDERKEY)"
for { set i 1 } { $i <= 8 } { incr i } {
db2_exec_direct $db_handle $sql($i)
                }
return
}

proc DoReOrg { db_handle } {
puts "REORGANIZING TPCH TABLES"
set sql(1) "ALTER TABLE REGION PCTFREE 0"
set sql(2) "ALTER TABLE NATION PCTFREE 0"
set sql(3) "ALTER TABLE SUPPLIER PCTFREE 0"
set sql(4) "ALTER TABLE PARTSUPP PCTFREE 0"
set sql(5) "ALTER TABLE PART PCTFREE 0"
set sql(6) "ALTER TABLE ORDERS PCTFREE 0"
set sql(7) "ALTER TABLE LINEITEM PCTFREE 0"
set sql(8) "ALTER TABLE CUSTOMER PCTFREE 0"
set sql(9) "ALTER TABLE REGION LOCKSIZE TABLE"
set sql(10) "ALTER TABLE NATION LOCKSIZE TABLE"
set sql(11) "ALTER TABLE SUPPLIER LOCKSIZE TABLE"
set sql(12) "ALTER TABLE PARTSUPP LOCKSIZE TABLE"
set sql(13) "ALTER TABLE PART LOCKSIZE TABLE"
set sql(14) "ALTER TABLE CUSTOMER LOCKSIZE TABLE"
set sql(15) "CALL SYSPROC.ADMIN_CMD('REORG TABLE REGION')"
set sql(16) "CALL SYSPROC.ADMIN_CMD('REORG TABLE NATION')"
set sql(17) "CALL SYSPROC.ADMIN_CMD('REORG TABLE SUPPLIER')"
set sql(18) "CALL SYSPROC.ADMIN_CMD('REORG TABLE PARTSUPP')"
set sql(19) "CALL SYSPROC.ADMIN_CMD('REORG TABLE PART')"
set sql(20) "CALL SYSPROC.ADMIN_CMD('REORG TABLE ORDERS')"
set sql(21) "CALL SYSPROC.ADMIN_CMD('REORG TABLE LINEITEM')"
set sql(22) "CALL SYSPROC.ADMIN_CMD('REORG TABLE CUSTOMER')"
for { set i 1 } { $i <= 22 } { incr i } {
puts "...$i"
db2_exec_direct $db_handle $sql($i)
                }
return
}

proc do_tpch { dbname scale_fact user password tpch_def_tab column_based num_vu } {
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
set db_handle [ ConnectToDb2 $dbname $user $password ]
switch [ string toupper $column_based ] {
COLUMN { set organization "organize by column" }
ROW { set organization "organize by row" }
DATE { set organization "DATE" }
NONE { set organization "" }
default { set organization "" }
}
CreateTables $db_handle $tpch_def_tab $organization
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
puts "Loading REGION..."
mk_region $db_handle
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation $db_handle
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
mk_region $db_handle
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation $db_handle
puts "Loading NATION COMPLETE"
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
if { [ tsv::exists application load ] } {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if {  [ tsv::get application abort ]  } { return }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
}
after 5000
}
set db_handle [ ConnectToDb2 $dbname $user $password ]
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
mk_supp $db_handle [ lindex $sf_chunk 0 ] [ lindex $sf_chunk 1 ]
puts "Loading CUSTOMER..."
mk_cust $db_handle [ lindex $cust_chunk 0 ] [ lindex $cust_chunk 1 ]
puts "Loading PART and PARTSUPP..."
mk_part $db_handle [ lindex $part_chunk 0 ] [ lindex $part_chunk 1 ] $scale_fact
puts "Loading ORDERS and LINEITEM..."
mk_order $db_handle [ lindex $ord_chunk 0 ] [ lindex $ord_chunk 1 ] [ expr {$upd_num % 10000} ] $scale_fact 
puts "Loading TPCH TABLES COMPLETE"
puts "End:[ clock format [ clock seconds ] ]"
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
catch {db2_disconnect $db_handle}
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
catch {db2_disconnect $db_handle}
set db_handle [ ConnectToDb2 $dbname $user $password ]
if {[catch {set stmnt_handle1 [ db2_select_direct $db_handle "select tableorg from syscat.tables where tabname='NATION'" ]} message]} {  
if {[string match {*TABLEORG*} $message]} {
set col_org "R"
        }
} else {
set col_org [ db2_fetchrow $stmnt_handle1 ]
        }
if { $col_org eq "C" } {
#Do not ReOrg as Column organized
	} else {
DoReOrg $db_handle 
CreateIndexes $db_handle
	}
GatherStatistics $db_handle
puts "[ string toupper $dbname ] SCHEMA COMPLETE"
return
		}
	}
}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "do_tpch $db2_tpch_dbase $db2_scale_fact $db2_tpch_user $db2_tpch_pass $db2_tpch_def_tab $db2_tpch_organizeby $db2_num_tpch_threads"
	} else { return }
}

proc loaddb2tpch {} {
global _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict db2 library ]} {
        set library [ dict get $dbdict db2 library ]
} else { set library "db2tcl" }
upvar #0 configdb2 configdb2
#set variables to values in dict
setlocaltpchvars $configdb2
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "Db2 TPROC-H"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# Db2 Library
set total_querysets $db2_total_querysets ;# Number of query sets before logging off
set RAISEERROR \"$db2_raise_query_error\" ;# Exit script on Db2 query error (true or false)
set VERBOSE \"$db2_verbose\" ;# Show query text and output
set degree_of_parallel \"$db2_degree_of_parallel\" ;# Degree of Parallelism
set scale_factor $db2_scale_fact ;#Scale factor of the tpc-h schema
set user \"$db2_tpch_user\" ;# Db2 user
set password \"$db2_tpch_pass\" ;# Password for the Db2 user
set dbname \"$db2_tpch_dbase\" ;#Database containing the TPC Schema
set refresh_on \"$db2_refresh_on\" ;#First User does refresh function
set update_sets $db2_update_sets ;#Number of sets of refresh function to complete
set trickle_refresh $db2_trickle_refresh ;#time delay (ms) to trickle refresh function
set REFRESH_VERBOSE \"$db2_refresh_verbose\" ;#report refresh function activity
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpchcommon} ] { error "Failed to load tpch common functions" } else { namespace import tpchcommon::* }

proc standsql { db_handle sql RAISEERROR } {
set ftch ""
if {[catch {set stmnt_handle [db2_select_direct $db_handle $sql]} message]} {
if { $RAISEERROR } {
error "Query Error : $message"
	} else {
puts "Query Failed: $sql : $message"
	}
} else {
while {[set line [ db2_fetchrow $stmnt_handle]] != ""} { lappend ftch $line }
   }
return $ftch
}

#Db2 CONNECTION
proc ConnectToDb2 { dbname user password } {
puts "Connecting to database $dbname"
if {[catch {set db_handle [db2_connect $dbname $user $password]} message]} {
error $message
 } else {
puts "Connection established"
return $db_handle
}}
#########################
#TPCH REFRESH PROCEDURE
proc mk_order_ref { db_handle upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
#2.27.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#INSERT a new row into the ORDERS table
#LOOP RANDOM(1, 7) TIMES
#INSERT a new row into the LINEITEM table
#END LOOP
#END LOOP
set stmnt_handle_or [ db2_prepare $db_handle "INSERT INTO ORDERS (O_ORDERDATE, O_ORDERKEY, O_CUSTKEY, O_ORDERPRIORITY, O_SHIPPRIORITY, O_CLERK, O_ORDERSTATUS, O_TOTALPRICE, O_COMMENT) VALUES (timestamp_format(?,'YYYY-MON-DD'), ?, ?, ?, ?, ?, ?, ?, ?)" ]
set stmnt_handle_li [ db2_prepare $db_handle "INSERT INTO LINEITEM (L_SHIPDATE, L_ORDERKEY, L_DISCOUNT, L_EXTENDEDPRICE, L_SUPPKEY, L_QUANTITY, L_RETURNFLAG, L_PARTKEY, L_LINESTATUS, L_TAX, L_COMMITDATE, L_RECEIPTDATE, L_SHIPMODE, L_LINENUMBER, L_SHIPINSTRUCT, L_COMMENT) VALUES (timestamp_format(?,'YYYY-MON-DD'), ?, ?, ?, ?, ?, ?, ?, ?, ?, timestamp_format(?,'YYYY-MON-DD'), timestamp_format(?,'YYYY-MON-DD'), ?, ?, ?, ?)" ]
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
lappend order_val_list $date $okey $custkey $opriority $spriority $clerk $orderstatus $totalprice $comment
if {[ catch {db2_bind_exec $stmnt_handle_or "$order_val_list"} message ] } {
puts "Error in statement: $message"
unset -nocomplain order_val_list
	} else {
unset order_val_list
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
lappend lineit_val_list $lsdate $lokey $ldiscount $leprice $lsuppkey $lquantity $lrflag $lpartkey $lstatus $ltax $lcdate $lrdate $lsmode $llcnt $linstruct $lcomment
if {[ catch {db2_bind_exec $stmnt_handle_li "$lineit_val_list"} message ] } {
puts "Error in statement: $message"
unset -nocomplain lineit_val_list
        } else {
unset lineit_val_list
	}
   }
}
db2_finish $stmnt_handle_or
db2_finish $stmnt_handle_li 
}

proc del_order_ref { db_handle upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
#2.28.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#DELETE FROM ORDERS WHERE O_ORDERKEY = [value]
#DELETE FROM LINEITEM WHERE L_ORDERKEY = [value]
#END LOOP
set stmnt_handle_or [ db2_prepare $db_handle "DELETE FROM ORDERS WHERE O_ORDERKEY = ?" ]
set stmnt_handle_li [ db2_prepare $db_handle "DELETE FROM LINEITEM WHERE L_ORDERKEY = ?" ]
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
if {[ catch {db2_bind_exec $stmnt_handle_li "$okey"} message ] } {
puts "Error in statement: $message"
        }
if {[ catch {db2_bind_exec $stmnt_handle_or "$okey"} message ] } {
puts "Error in statement: $message"
        }
if { $REFRESH_VERBOSE } {
puts "Refresh Delete Orderkey $okey..."
	}
}
db2_finish $stmnt_handle_or
db2_finish $stmnt_handle_li 
}

proc do_refresh { dbname user password scale_factor update_sets trickle_refresh REFRESH_VERBOSE RF_SET } {
set db_handle [ ConnectToDb2 $dbname $user $password ]
set upd_num 1
for { set set_counter 1 } {$set_counter <= $update_sets } {incr set_counter} {
if {  [ tsv::get application abort ]  } { break }
if { $RF_SET eq "RF1" || $RF_SET eq "BOTH" } {
puts "New Sales refresh"
set r0 [clock clicks -millisec]
mk_order_ref $db_handle $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE
set r1 [clock clicks -millisec]
set rvalnew [expr {double($r1-$r0)/1000}]
puts "New Sales refresh complete in $rvalnew seconds"
        }
if { $RF_SET eq "RF2" || $RF_SET eq "BOTH" } {
puts "Old Sales refresh"
set r3 [clock clicks -millisec]
del_order_ref $db_handle $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE
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
db2_disconnect $db_handle
}
#########################
#TPCH QUERY GENERATION
proc set_query { myposition } {
global sql
#alternative queries depend on Db2 format
set sql(1) "select l_returnflag, l_linestatus, sum(l_quantity) as sum_qty, sum(l_extendedprice) as sum_base_price, sum(l_extendedprice * (1 - l_discount)) as sum_disc_price, sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge, avg(l_quantity) as avg_qty, avg(l_extendedprice) as avg_price, avg(l_discount) as avg_disc, count(*) as count_order from lineitem where l_shipdate <= date '1998-12-01' - :1 days group by l_returnflag, l_linestatus order by l_returnflag, l_linestatus"
set sql(2) "select s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment from part, supplier, partsupp, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and p_size = :1 and p_type like '%:2' and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3' and ps_supplycost = ( select min(ps_supplycost) from partsupp, supplier, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3') order by s_acctbal desc, n_name, s_name, p_partkey"
set sql(3) "select l_orderkey, sum(l_extendedprice * (1 - l_discount)) as revenue, o_orderdate, o_shippriority from customer, orders, lineitem where c_mktsegment = ':1' and c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate < date ':2' and l_shipdate > date ':2' group by l_orderkey, o_orderdate, o_shippriority order by revenue desc, o_orderdate"
set sql(4) "select o_orderpriority, count(*) as order_count from orders where o_orderdate >= date ':1' and o_orderdate < date ':1' + 3 months and exists ( select * from lineitem where l_orderkey = o_orderkey and l_commitdate < l_receiptdate) group by o_orderpriority order by o_orderpriority"
set sql(5) "select n_name, sum(l_extendedprice * (1 - l_discount)) as revenue from customer, orders, lineitem, supplier, nation, region where c_custkey = o_custkey and l_orderkey = o_orderkey and l_suppkey = s_suppkey and c_nationkey = s_nationkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':1' and o_orderdate >= date ':2' and o_orderdate < date ':2' + 1 year group by n_name order by revenue desc"
set sql(6) "select sum(l_extendedprice * l_discount) as revenue from lineitem where l_shipdate >= date ':1' and l_shipdate < date ':1' + 1 year and l_discount between :2 - 0.01 and :2 + 0.01 and l_quantity < :3"
set sql(7) "select supp_nation, cust_nation, l_year, sum(volume) as revenue from ( select n1.n_name as supp_nation, n2.n_name as cust_nation, extract(year from l_shipdate) as l_year, l_extendedprice * (1 - l_discount) as volume from supplier, lineitem, orders, customer, nation n1, nation n2 where s_suppkey = l_suppkey and o_orderkey = l_orderkey and c_custkey = o_custkey and s_nationkey = n1.n_nationkey and c_nationkey = n2.n_nationkey and ( (n1.n_name = ':1' and n2.n_name = ':2') or (n1.n_name = ':2' and n2.n_name = ':1')) and l_shipdate between date '1995-01-01' and date '1996-12-31') shipping group by supp_nation, cust_nation, l_year order by supp_nation, cust_nation, l_year"
set sql(8) "select o_year, sum(case when nation = ':1' then volume else 0 end) / sum(volume) as mkt_share from ( select extract(year from o_orderdate) as o_year, l_extendedprice * (1 - l_discount) as volume, n2.n_name as nation from part, supplier, lineitem, orders, customer, nation n1, nation n2, region where p_partkey = l_partkey and s_suppkey = l_suppkey and l_orderkey = o_orderkey and o_custkey = c_custkey and c_nationkey = n1.n_nationkey and n1.n_regionkey = r_regionkey and r_name = ':2' and s_nationkey = n2.n_nationkey and o_orderdate between date '1995-01-01' and date '1996-12-31' and p_type = ':3') all_nations group by o_year order by o_year"
set sql(9) "select nation, o_year, sum(amount) as sum_profit from ( select n_name as nation, extract(year from o_orderdate) as o_year, l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount from part, supplier, lineitem, partsupp, orders, nation where s_suppkey = l_suppkey and ps_suppkey = l_suppkey and ps_partkey = l_partkey and p_partkey = l_partkey and o_orderkey = l_orderkey and s_nationkey = n_nationkey and p_name like '%:1%') profit group by nation, o_year order by nation, o_year desc"
set sql(10) "select c_custkey, c_name, sum(l_extendedprice * (1 - l_discount)) as revenue, c_acctbal, n_name, c_address, c_phone, c_comment from customer, orders, lineitem, nation where c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate >= date ':1' and o_orderdate < date ':1' + 3 months and l_returnflag = 'R' and c_nationkey = n_nationkey group by c_custkey, c_name, c_acctbal, c_phone, n_name, c_address, c_comment order by revenue desc"
set sql(11) "select ps_partkey, sum(ps_supplycost * ps_availqty) as value from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1' group by ps_partkey having sum(ps_supplycost * ps_availqty) > ( select sum(ps_supplycost * ps_availqty) * :2 from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1') order by value desc"
set sql(12) "select l_shipmode, sum(case when o_orderpriority = '1-URGENT' or o_orderpriority = '2-HIGH' then 1 else 0 end) as high_line_count, sum(case when o_orderpriority <> '1-URGENT' and o_orderpriority <> '2-HIGH' then 1 else 0 end) as low_line_count from orders, lineitem where o_orderkey = l_orderkey and l_shipmode in (':1', ':2') and l_commitdate < l_receiptdate and l_shipdate < l_commitdate and l_receiptdate >= date ':3' and l_receiptdate < date ':3' + 1 year group by l_shipmode order by l_shipmode"
#Query 13 error: SQLSTATE 01003: Null values were eliminated from the argument of a column function.
#to fix set following in db2cli.ini 
#[TPCH]
#IgnoreWarnList="'01003'"
set sql(13) "select c_count, count(*) as custdist from ( select c_custkey, count(o_orderkey) as c_count from customer left outer join orders on c_custkey = o_custkey and o_comment not like '%:1%:2%' group by c_custkey) c_orders group by c_count order by custdist desc, c_count desc"
set sql(14) "select 100.00 * sum(case when p_type like 'PROMO%' then l_extendedprice * (1 - l_discount) else 0 end) / sum(l_extendedprice * (1 - l_discount)) as promo_revenue from lineitem, part where l_partkey = p_partkey and l_shipdate >= date ':1' and l_shipdate < date ':1' + 1 month"
set sql(15) "create or replace view revenue$myposition (supplier_no, total_revenue) as select l_suppkey, sum(l_extendedprice * (1 - l_discount)) from lineitem where l_shipdate >= to_date( ':1', 'YYYY-MM-DD') and l_shipdate < add_months( to_date (':1', 'YYYY-MM-DD'), 3) group by l_suppkey; select s_suppkey, s_name, s_address, s_phone, total_revenue from supplier, revenue$myposition where s_suppkey = supplier_no and total_revenue = ( select max(total_revenue) from revenue$myposition) order by s_suppkey; drop view revenue$myposition"
set sql(16) "select p_brand, p_type, p_size, count(distinct ps_suppkey) as supplier_cnt from partsupp, part where p_partkey = ps_partkey and p_brand <> ':1' and p_type not like ':2%' and p_size in (:3, :4, :5, :6, :7, :8, :9, :10) and ps_suppkey not in ( select s_suppkey from supplier where s_comment like '%Customer%Complaints%') group by p_brand, p_type, p_size order by supplier_cnt desc, p_brand, p_type, p_size"
set sql(17) "select sum(l_extendedprice) / 7.0 as avg_yearly from lineitem, part where p_partkey = l_partkey and p_brand = ':1' and p_container = ':2' and l_quantity < ( select 0.2 * avg(l_quantity) from lineitem where l_partkey = p_partkey)"
set sql(18) "select c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice, sum(l_quantity) from customer, orders, lineitem where o_orderkey in ( select l_orderkey from lineitem group by l_orderkey having sum(l_quantity) > :1) and c_custkey = o_custkey and o_orderkey = l_orderkey group by c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice order by o_totalprice desc, o_orderdate"
set sql(19) "select sum(l_extendedprice* (1 - l_discount)) as revenue from lineitem, part where ( p_partkey = l_partkey and p_brand = ':1' and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') and l_quantity >= :4 and l_quantity <= :4 + 10 and p_size between 1 and 5 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':2' and p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') and l_quantity >= :5 and l_quantity <= :5 + 10 and p_size between 1 and 10 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':3' and p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') and l_quantity >= :6 and l_quantity <= :6 + 10 and p_size between 1 and 15 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON')"
set sql(20) "select s_name, s_address from supplier, nation where s_suppkey in ( select ps_suppkey from partsupp where ps_partkey in ( select p_partkey from part where p_name like ':1%') and ps_availqty > ( select 0.5 * sum(l_quantity) from lineitem where l_partkey = ps_partkey and l_suppkey = ps_suppkey and l_shipdate >= date ':2' and l_shipdate < date ':2' + 1 year)) and s_nationkey = n_nationkey and n_name = ':3' order by s_name"
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
proc do_tpch { dbname user password scale_factor RAISEERROR VERBOSE degree_of_parallel total_querysets myposition } {
set db_handle [ ConnectToDb2 $dbname $user $password ]
db2_exec_direct $db_handle "SET CURRENT DEGREE '$degree_of_parallel'"
for {set it 0} {$it < $total_querysets} {incr it} {
if {  [ tsv::get application abort ]  } { break }
unset -nocomplain qlist
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
set t0 [clock clicks -millisec]
set oput [ standsql $db_handle $dssquery($qos) $RAISEERROR ]
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
if {$VERBOSE} { printlist $oput }
if { [ llength $oput ] > 0 } { lappend qlist $value }
puts "query $qos completed in $value seconds"
	      } else {
            set q15c 0
            while {$q15c <= [expr $q15length - 1] } {
	if { $q15c != 1 } {
if {[ catch {db2_exec_direct $db_handle $dssquery($qos,$q15c)} message ] } {
puts "$message $dssquery($qos,$q15c)"
	  }
	} else {
set t0 [clock clicks -millisec]
set oput [ standsql $db_handle $dssquery($qos,$q15c) $RAISEERROR ]
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
if {$VERBOSE} { printlist $oput }
if { [ llength $oput ] > 0 } { lappend qlist $value }
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
puts "Geometric mean of query times returning rows ([llength $qlist]) is [ format \"%.5f\" [ gmean $qlist ]]"
	}
db2_disconnect $db_handle
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
do_refresh $dbname $user $password $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE RF1
do_tpch $dbname $user $password $scale_factor $RAISEERROR $VERBOSE $degree_of_parallel $total_querysets 0
do_refresh $dbname $user $password $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE RF2
        } else {
switch $myposition {
1 {
do_refresh $dbname $user $password $scale_factor $update_sets $trickle_refresh $REFRESH_VERBOSE BOTH 
        }
default {
do_tpch $dbname $user $password $scale_factor $RAISEERROR $VERBOSE $degree_of_parallel $total_querysets [ expr $myposition - 1 ]
        }
    }
 }
} else {
do_tpch $dbname $user $password $scale_factor $RAISEERROR $VERBOSE $degree_of_parallel $total_querysets $myposition
		}}
}
