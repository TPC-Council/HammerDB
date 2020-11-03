proc build_mssqlstpch {} {
global maxvuser suppo ntimes threadscreated _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict mssqlserver library ]} {
        set library [ dict get $dbdict mssqlserver library ]
} else { set library "tdbc::odbc 1.0.6" }
if { [ llength $library ] > 1 } {
set version [ lindex $library 1 ]
set library [ lindex $library 0 ]
        }
upvar #0 configmssqlserver configmssqlserver
#set variables to values in dict
setlocaltpchvars $configmssqlserver
if {![string match windows $::tcl_platform(platform)]} {
set mssqls_server $mssqls_linux_server
set mssqls_odbc_driver $mssqls_linux_odbc
set mssqls_authentication $mssqls_linux_authent
        }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a Scale Factor $mssqls_scale_fact MS SQL Server TPROC-H schema\nin host [string toupper $mssqls_server ] in database [ string toupper $mssqls_tpch_dbase ]?" -type yesno ] == yes} { 
if { $mssqls_num_tpch_threads eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $mssqls_num_tpch_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "SQL Server TPROC-H creation"
if { [catch {load_virtual} message]} {
puts "Failed to create threads for schema creation: $message"
	return
	}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#LOAD LIBRARIES AND MODULES
set library $library
set version $version
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {if [catch {package require $library $version} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpchcommon} ] { error "Failed to load tpch common functions" } else { namespace import tpchcommon::* }
proc UpdateStatistics { odbc db azure } {
puts "UPDATING SCHEMA STATISTICS"
if {!$azure} {
$odbc evaldirect "CREATE OR ALTER PROCEDURE dbo.sp_updstats
with execute as 'dbo'
as
exec sp_updatestats
"
$odbc evaldirect "EXEC dbo.sp_updstats"
} else {
set sql(1) "USE $db"
set sql(2) "EXEC sp_updatestats"
for { set i 1 } { $i <= 2 } { incr i } {
$odbc evaldirect $sql($i)
                }
        }
return
}

proc CreateDatabase { odbc db azure } {
set table_count 0
puts "CHECKING IF DATABASE $db EXISTS"
set rows [ odbc allrows "IF DB_ID('$db') is not null SELECT 1 AS res ELSE SELECT 0 AS res" ]
set db_exists [ lindex {*}$rows 1 ]
if { $db_exists } {
if {!$azure} {$odbc evaldirect "use $db"}
set rows [ odbc allrows "select COUNT(*) from sys.tables" ]
set table_count [ lindex {*}$rows 1 ]
if { $table_count == 0 } {
puts "Empty database $db exists"
puts "Using existing empty Database $db for Schema build"
        } else {
puts "Database with tables $db exists"
error "Database $db exists but is not empty, specify a new or empty database name"
        }
} else {
puts "CREATING DATABASE $db"
$odbc evaldirect "create database $db"
        }
}

proc CreateTables { odbc colstore } {
puts "CREATING TPCH TABLES"
if { $colstore } {
set sql(1) "create table dbo.customer (c_custkey bigint not null, c_mktsegment char(10) null, c_nationkey int null, c_name varchar(25) null, c_address varchar(40) null, c_phone char(15) null, c_acctbal money null, c_comment varchar(118) null, index cust_cs clustered columnstore)" 
set sql(2) "create table dbo.lineitem (l_shipdate date null, l_orderkey bigint not null, l_discount money not null, l_extendedprice money not null, l_suppkey int not null, l_quantity bigint not null, l_returnflag char(1) null, l_partkey bigint not null, l_linestatus char(1) null, l_tax money not null, l_commitdate date null, l_receiptdate date null, l_shipmode char(10) null, l_linenumber bigint not null, l_shipinstruct char(25) null, l_comment varchar(44) null, index lineit_cs clustered columnstore)" 
set sql(3) "create table dbo.nation(n_nationkey int not null, n_name char(25) null, n_regionkey int null, n_comment varchar(152) null, index nation_cs clustered columnstore)" 
set sql(4) "create table dbo.part( p_partkey bigint not null, p_type varchar(25) null, p_size int null, p_brand char(10) null, p_name varchar(55) null, p_container char(10) null, p_mfgr char(25) null, p_retailprice money null, p_comment varchar(23) null, index part_cs clustered columnstore)" 
set sql(5) "create table dbo.partsupp( ps_partkey bigint not null, ps_suppkey int not null, ps_supplycost money not null, ps_availqty int null, ps_comment varchar(199) null, index psupp_cs clustered columnstore)" 
set sql(6) "create table dbo.region(r_regionkey int not null, r_name char(25) null, r_comment varchar(152) null, index region_cs clustered columnstore)"
set sql(7) "create table dbo.supplier( s_suppkey int not null, s_nationkey int null, s_comment varchar(102) null, s_name char(25) null, s_address varchar(40) null, s_phone char(15) null, s_acctbal money null, index suppl_cs clustered columnstore)" 
set sql(8) "create table dbo.orders( o_orderdate date null, o_orderkey bigint not null, o_custkey bigint not null, o_orderpriority char(15) null, o_shippriority int null, o_clerk char(15) null, o_orderstatus char(1) null, o_totalprice money null, o_comment varchar(79) null, index ord_cs clustered columnstore)"
	} else {
set sql(1) "create table dbo.customer (c_custkey bigint not null, c_mktsegment char(10) null, c_nationkey int null, c_name varchar(25) null, c_address varchar(40) null, c_phone char(15) null, c_acctbal money null, c_comment varchar(118) null)" 
set sql(2) "create table dbo.lineitem (l_shipdate date null, l_orderkey bigint not null, l_discount money not null, l_extendedprice money not null, l_suppkey int not null, l_quantity bigint not null, l_returnflag char(1) null, l_partkey bigint not null, l_linestatus char(1) null, l_tax money not null, l_commitdate date null, l_receiptdate date null, l_shipmode char(10) null, l_linenumber bigint not null, l_shipinstruct char(25) null, l_comment varchar(44) null)" 
set sql(3) "create table dbo.nation(n_nationkey int not null, n_name char(25) null, n_regionkey int null, n_comment varchar(152) null)" 
set sql(4) "create table dbo.part( p_partkey bigint not null, p_type varchar(25) null, p_size int null, p_brand char(10) null, p_name varchar(55) null, p_container char(10) null, p_mfgr char(25) null, p_retailprice money null, p_comment varchar(23) null)" 
set sql(5) "create table dbo.partsupp( ps_partkey bigint not null, ps_suppkey int not null, ps_supplycost money not null, ps_availqty int null, ps_comment varchar(199) null)" 
set sql(6) "create table dbo.region(r_regionkey int not null, r_name char(25) null, r_comment varchar(152) null)"
set sql(7) "create table dbo.supplier( s_suppkey int not null, s_nationkey int null, s_comment varchar(102) null, s_name char(25) null, s_address varchar(40) null, s_phone char(15) null, s_acctbal money null)" 
set sql(8) "create table dbo.orders( o_orderdate date null, o_orderkey bigint not null, o_custkey bigint not null, o_orderpriority char(15) null, o_shippriority int null, o_clerk char(15) null, o_orderstatus char(1) null, o_totalprice money null, o_comment varchar(79) null)"
}
for { set i 1 } { $i <= 8 } { incr i } {
$odbc evaldirect $sql($i)
		}
return
	}

proc CreateIndexes { odbc maxdop colstore } {
puts "CREATING TPCH INDEXES"
if { $colstore } {
set sql(1) "create unique index nation_pk on dbo.nation(n_nationkey)"
set sql(2) "create unique index region_pk on dbo.region(r_regionkey)"
set sql(3) "create unique index customer_pk on dbo.customer(c_custkey) with (maxdop=$maxdop)"
set sql(4) "create unique index part_pk on dbo.part(p_partkey) with (maxdop=$maxdop)"
set sql(5) "create unique index partsupp_pk on dbo.partsupp(ps_partkey, ps_suppkey) with (maxdop=$maxdop)"
set sql(6) "create unique index supplier_pk on dbo.supplier(s_suppkey) with (maxdop=$maxdop)"
set sql(7) "create index o_orderdate_ind on orders(o_orderdate) with (fillfactor=95, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(8) "create unique index orders_pk on dbo.orders(o_orderkey) with (fillfactor = 95, maxdop=$maxdop)"
set sql(9) "create index n_regionkey_ind on dbo.nation(n_regionkey) with (fillfactor=100, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(10) "create index ps_suppkey_ind on dbo.partsupp(ps_suppkey) with(fillfactor=100, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(11) "create index s_nationkey_ind on dbo.supplier(s_nationkey) with (fillfactor=100, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(12) "create index l_shipdate_ind on dbo.lineitem(l_shipdate) with (fillfactor=95, sort_in_tempdb=off, maxdop=$maxdop)"
set sql(13) "create index l_orderkey_ind on dbo.lineitem(l_orderkey) with ( fillfactor=95, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(14) "create index l_partkey_ind on dbo.lineitem(l_partkey) with (fillfactor=95, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(15) "alter table dbo.customer with nocheck add  constraint customer_nation_fk foreign key(c_nationkey) references dbo.nation (n_nationkey)"
set sql(16) "alter table dbo.lineitem with nocheck add  constraint lineitem_order_fk foreign key(l_orderkey) references dbo.orders (o_orderkey)"
set sql(17) "alter table dbo.lineitem with nocheck add constraint lineitem_partkey_fk foreign key (l_partkey) references dbo.part(p_partkey)"
set sql(18) "alter table dbo.lineitem with nocheck add constraint lineitem_suppkey_fk foreign key (l_suppkey) references dbo.supplier(s_suppkey)"
set sql(19) "alter table dbo.lineitem with nocheck add  constraint lineitem_partsupp_fk foreign key(l_partkey,l_suppkey) references partsupp(ps_partkey, ps_suppkey)"
set sql(20) "alter table dbo.nation  with nocheck add  constraint nation_region_fk foreign key(n_regionkey) references dbo.region (r_regionkey)"
set sql(21) "alter table dbo.partsupp  with nocheck add  constraint partsupp_part_fk foreign key(ps_partkey) references dbo.part (p_partkey)"
set sql(22) "alter table dbo.partsupp  with nocheck add  constraint partsupp_supplier_fk foreign key(ps_suppkey) references dbo.supplier (s_suppkey)"
set sql(23) "alter table dbo.supplier  with nocheck add  constraint supplier_nation_fk foreign key(s_nationkey) references dbo.nation (n_nationkey)"
set sql(24) "alter table dbo.orders  with nocheck add  constraint order_customer_fk foreign key(o_custkey) references dbo.customer (c_custkey)"
set sql(25) "alter table dbo.customer check constraint customer_nation_fk"
set sql(26) "alter table dbo.lineitem check constraint lineitem_order_fk"
set sql(27) "alter table dbo.lineitem check constraint lineitem_partkey_fk"
set sql(28) "alter table dbo.lineitem check constraint lineitem_suppkey_fk"
set sql(29) "alter table dbo.lineitem check constraint lineitem_partsupp_fk"
set sql(30) "alter table dbo.nation check constraint nation_region_fk"
set sql(31) "alter table dbo.partsupp check constraint partsupp_part_fk"
set sql(32) "alter table dbo.partsupp check constraint partsupp_part_fk"
set sql(33) "alter table dbo.supplier check constraint supplier_nation_fk"
set sql(34) "alter table dbo.orders check constraint order_customer_fk"
	} else {
set sql(1) "alter table dbo.nation add constraint nation_pk primary key (n_nationkey)"
set sql(2) "alter table dbo.region add constraint region_pk primary key (r_regionkey)"
set sql(3) "alter table dbo.customer add constraint customer_pk primary key (c_custkey) with (maxdop=$maxdop)"
set sql(4) "alter table dbo.part add constraint part_pk primary key (p_partkey) with (maxdop=$maxdop)"
set sql(5) "alter table dbo.partsupp add constraint partsupp_pk primary key (ps_partkey, ps_suppkey) with (maxdop=$maxdop)"
set sql(6) "alter table dbo.supplier add constraint supplier_pk primary key (s_suppkey) with (maxdop=$maxdop)"
set sql(7) "create clustered index o_orderdate_ind on orders(o_orderdate) with (fillfactor=95, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(8) "alter table dbo.orders add constraint orders_pk primary key (o_orderkey) with (fillfactor = 95, maxdop=$maxdop)"
set sql(9) "create index n_regionkey_ind on dbo.nation(n_regionkey) with (fillfactor=100, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(10) "create index ps_suppkey_ind on dbo.partsupp(ps_suppkey) with(fillfactor=100, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(11) "create index s_nationkey_ind on dbo.supplier(s_nationkey) with (fillfactor=100, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(12) "create clustered index l_shipdate_ind on dbo.lineitem(l_shipdate) with (fillfactor=95, sort_in_tempdb=off, maxdop=$maxdop)"
set sql(13) "create index l_orderkey_ind on dbo.lineitem(l_orderkey) with ( fillfactor=95, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(14) "create index l_partkey_ind on dbo.lineitem(l_partkey) with (fillfactor=95, sort_in_tempdb=on, maxdop=$maxdop)"
set sql(15) "alter table dbo.customer with nocheck add  constraint customer_nation_fk foreign key(c_nationkey) references dbo.nation (n_nationkey)"
set sql(16) "alter table dbo.lineitem with nocheck add  constraint lineitem_order_fk foreign key(l_orderkey) references dbo.orders (o_orderkey)"
set sql(17) "alter table dbo.lineitem with nocheck add constraint lineitem_partkey_fk foreign key (l_partkey) references dbo.part(p_partkey)"
set sql(18) "alter table dbo.lineitem with nocheck add constraint lineitem_suppkey_fk foreign key (l_suppkey) references dbo.supplier(s_suppkey)"
set sql(19) "alter table dbo.lineitem with nocheck add  constraint lineitem_partsupp_fk foreign key(l_partkey,l_suppkey) references partsupp(ps_partkey, ps_suppkey)"
set sql(20) "alter table dbo.nation  with nocheck add  constraint nation_region_fk foreign key(n_regionkey) references dbo.region (r_regionkey)"
set sql(21) "alter table dbo.partsupp  with nocheck add  constraint partsupp_part_fk foreign key(ps_partkey) references dbo.part (p_partkey)"
set sql(22) "alter table dbo.partsupp  with nocheck add  constraint partsupp_supplier_fk foreign key(ps_suppkey) references dbo.supplier (s_suppkey)"
set sql(23) "alter table dbo.supplier  with nocheck add  constraint supplier_nation_fk foreign key(s_nationkey) references dbo.nation (n_nationkey)"
set sql(24) "alter table dbo.orders  with nocheck add  constraint order_customer_fk foreign key(o_custkey) references dbo.customer (c_custkey)"
set sql(25) "alter table dbo.customer check constraint customer_nation_fk"
set sql(26) "alter table dbo.lineitem check constraint lineitem_order_fk"
set sql(27) "alter table dbo.lineitem check constraint lineitem_partkey_fk"
set sql(28) "alter table dbo.lineitem check constraint lineitem_suppkey_fk"
set sql(29) "alter table dbo.lineitem check constraint lineitem_partsupp_fk"
set sql(30) "alter table dbo.nation check constraint nation_region_fk"
set sql(31) "alter table dbo.partsupp check constraint partsupp_part_fk"
set sql(32) "alter table dbo.partsupp check constraint partsupp_part_fk"
set sql(33) "alter table dbo.supplier check constraint supplier_nation_fk"
set sql(34) "alter table dbo.orders check constraint order_customer_fk"
	}
for { set i 1 } { $i <= 34 } { incr i } {
$odbc evaldirect $sql($i)
		}
return
	}

proc mk_region { odbc } {
for { set i 1 } { $i <= 5 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists regions ] [ expr {$i - 1} ] ] 0 ]
set comment [ TEXT_1 72 ]
$odbc evaldirect "INSERT INTO region (r_regionkey,r_name,r_comment) VALUES ('$code' , '$text' , '$comment')"
	}
 }

proc mk_nation { odbc } {
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
$odbc evaldirect "INSERT INTO nation (n_nationkey, n_name, n_regionkey, n_comment) VALUES ('$code' , '$text' , '$join' , '$comment')"
	}
}

proc mk_supp { odbc start_rows end_rows } {
set bld_cnt 1
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
incr bld_cnt
if { ![ expr {$i % 2} ] || $i eq $end_rows } {    
$odbc evaldirect "INSERT INTO supplier (s_suppkey, s_nationkey, s_comment, s_name, s_address, s_phone, s_acctbal) VALUES $supp_val_list"
	set bld_cnt 1
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

proc mk_cust { odbc start_rows end_rows } {
set bld_cnt 1
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
incr bld_cnt
if { ![ expr {$i % 2} ] || $i eq $end_rows } {    
$odbc evaldirect "INSERT INTO customer (c_custkey, c_mktsegment, c_nationkey, c_name, c_address, c_phone, c_acctbal, c_comment) values $cust_val_list"
	set bld_cnt 1
	unset cust_val_list
   	} else {
	append cust_val_list ,
        }
if { ![ expr {$i % 10000} ] } {
	puts "Loading CUSTOMER...$i"
	}
}
puts "CUSTOMER Done Rows $start_rows..$end_rows"
return
}

proc mk_part { odbc start_rows end_rows scale_factor } {
set bld_cnt 1
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
incr bld_cnt
# end of psupp loop
if { ![ expr {$i % 2} ]  || $i eq $end_rows } {     
$odbc evaldirect "INSERT INTO part (p_partkey, p_type, p_size, p_brand, p_name, p_container, p_mfgr, p_retailprice, p_comment) VALUES $part_val_list"
$odbc evaldirect "INSERT INTO partsupp (ps_partkey, ps_suppkey, ps_supplycost, ps_availqty, ps_comment) VALUES $psupp_val_list"
	set bld_cnt 1
	unset part_val_list
	unset psupp_val_list
	} else {
	append psupp_val_list ,
	append part_val_list ,
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading PART/PARTSUPP...$i"
	}
}
puts "PART and PARTSUPP Done Rows $start_rows..$end_rows"
return
}

proc mk_order { odbc start_rows end_rows upd_num scale_factor } {
set bld_cnt 1
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
append lineit_val_list ('$lsdate','$lokey', '$ldiscount', '$leprice', '$lsuppkey', '$lquantity', '$lrflag', '$lpartkey', '$lstatus', '$ltax', '$lcdate', '$lrdate', '$lsmode', '$llcnt', '$linstruct', '$lcomment') 
if { $l < [ expr $lcnt - 1 ] } { 
append lineit_val_list ,
	} 
  }
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
append order_val_list ('$date', '$okey', '$custkey', '$opriority', '$spriority', '$clerk', '$orderstatus', '$totalprice', '$comment') 
incr bld_cnt
if { ![ expr {$i % 2} ]  || $i eq $end_rows } {     
$odbc evaldirect "INSERT INTO lineitem (l_shipdate, l_orderkey, l_discount, l_extendedprice, l_suppkey, l_quantity, l_returnflag, l_partkey, l_linestatus, l_tax, l_commitdate, l_receiptdate, l_shipmode, l_linenumber, l_shipinstruct, l_comment) VALUES $lineit_val_list"
$odbc evaldirect "INSERT INTO orders (o_orderdate, o_orderkey, o_custkey, o_orderpriority, o_shippriority, o_clerk, o_orderstatus, o_totalprice, o_comment) VALUES $order_val_list"
	set bld_cnt 1
	unset lineit_val_list
	unset order_val_list
   	} else {
	append order_val_list ,
	append lineit_val_list ,
	}
if { ![ expr {$i % 10000} ] } {
	puts "Loading ORDERS/LINEITEM...$i"
	}
}
puts "ORDERS and LINEITEM Done Rows $start_rows..$end_rows"
return
}

proc connect_string { server port odbc_driver authentication uid pwd tcp azure db } {
if { $tcp eq "true" } { set server tcp:$server,$port }
if {[ string toupper $authentication ] eq "WINDOWS" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;TRUSTED_CONNECTION=YES"
} else {
if {[ string toupper $authentication ] eq "SQL" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;UID=$uid;PWD=$pwd"
        } else {
puts stderr "Error: neither WINDOWS or SQL Authentication has been specified"
set connection "DRIVER=$odbc_driver;SERVER=$server"
        }
}
if { $azure eq "true" } { append connection ";" "DATABASE=$db" }
return $connection
}

proc do_tpch { server port scale_fact odbc_driver authentication uid pwd tcp azure db maxdop colstore num_vu } {
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
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd $tcp $azure $db ]
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
puts "CREATING [ string toupper $db ] SCHEMA"
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
error "Connection to $connection could not be established : $message"
 } else {
CreateDatabase odbc $db $azure
if {!$azure} {odbc evaldirect "use $db"}
CreateTables odbc $colstore
}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
puts "Loading REGION..."
mk_region odbc
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation odbc
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
mk_region odbc
puts "Loading REGION COMPLETE"
puts "Loading NATION..."
mk_nation odbc
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
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
error "Connection to $connection could not be established : $message"
 } else {
if {!$azure} {odbc evaldirect "use $db"}
odbc evaldirect "set implicit_transactions OFF"
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
mk_supp odbc [ lindex $sf_chunk 0 ] [ lindex $sf_chunk 1 ]
puts "Loading CUSTOMER..."
mk_cust odbc [ lindex $cust_chunk 0 ] [ lindex $cust_chunk 1 ]
puts "Loading PART and PARTSUPP..."
mk_part odbc [ lindex $part_chunk 0 ] [ lindex $part_chunk 1 ] $scale_fact
puts "Loading ORDERS and LINEITEM..."
mk_order odbc [ lindex $ord_chunk 0 ] [ lindex $ord_chunk 1 ] [ expr {$upd_num % 10000} ] $scale_fact 
puts "Loading TPCH TABLES COMPLETE"
puts "End:[ clock format [ clock seconds ] ]"
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateIndexes odbc $maxdop $colstore
UpdateStatistics odbc $db $azure
puts "[ string toupper $db ] SCHEMA COMPLETE"
odbc close
return
		}
	}
}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "do_tpch {$mssqls_server} $mssqls_port $mssqls_scale_fact {$mssqls_odbc_driver} $mssqls_authentication $mssqls_uid $mssqls_pass $mssqls_tcp $mssqls_azure $mssqls_tpch_dbase $mssqls_maxdop $mssqls_colstore $mssqls_num_tpch_threads"
	} else { return }
}

proc loadmssqlstpch {} {
global _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict mssqlserver library ]} {
        set library [ dict get $dbdict mssqlserver library ]
} else { set library "tdbc::odbc 1.0.6" }
if { [ llength $library ] > 1 } {
set version [ lindex $library 1 ]
set library [ lindex $library 0 ]
        }
upvar #0 configmssqlserver configmssqlserver
#set variables to values in dict
setlocaltpchvars $configmssqlserver
if {![string match windows $::tcl_platform(platform)]} {
set mssqls_server $mssqls_linux_server
set mssqls_odbc_driver $mssqls_linux_odbc
set mssqls_authentication $mssqls_linux_authent
        }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "SQL Server TPROC-H"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# SQL Server Library
set version $version ;# SQL Server Library Version
set total_querysets $mssqls_total_querysets ;# Number of query sets before logging off
set RAISEERROR \"$mssqls_raise_query_error\" ;# Exit script on SQL Server query error (true or false)
set VERBOSE \"$mssqls_verbose\" ;# Show query text and output
set maxdop $mssqls_maxdop ;# Maximum Degree of Parallelism
set scale_factor $mssqls_scale_fact ;#Scale factor of the tpc-h schema
set authentication \"$mssqls_authentication\";# Authentication Mode (WINDOWS or SQL)
set server {$mssqls_server};# Microsoft SQL Server Database Server
set port \"$mssqls_port\";# Microsoft SQL Server Port 
set odbc_driver {$mssqls_odbc_driver};# ODBC Driver
set uid \"$mssqls_uid\";#User ID for SQL Server Authentication
set pwd \"$mssqls_pass\";#Password for SQL Server Authentication
set tcp \"$mssqls_tcp\";#Specify TCP Protocol
set azure \"$mssqls_azure\";#Azure Type Connection
set database \"$mssqls_tpch_dbase\";# Database containing the TPC Schema
set refresh_on \"$mssqls_refresh_on\" ;#First User does refresh function
set update_sets $mssqls_update_sets ;#Number of sets of refresh function to complete
set trickle_refresh $mssqls_trickle_refresh ;#time delay (ms) to trickle refresh function
set REFRESH_VERBOSE \"$mssqls_refresh_verbose\" ;#report refresh function activity
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library $version} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpchcommon} ] { error "Failed to load tpch common functions" } else { namespace import tpchcommon::* }

proc connect_string { server port odbc_driver authentication uid pwd tcp azure db } {
if { $tcp eq "true" } { set server tcp:$server,$port }
if {[ string toupper $authentication ] eq "WINDOWS" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;TRUSTED_CONNECTION=YES"
} else {
if {[ string toupper $authentication ] eq "SQL" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;UID=$uid;PWD=$pwd"
        } else {
puts stderr "Error: neither WINDOWS or SQL Authentication has been specified"
set connection "DRIVER=$odbc_driver;SERVER=$server"
        }
}
if { $azure eq "true" } { append connection ";" "DATABASE=$db" }
return $connection
}

proc standsql { odbc sql RAISEERROR } {
if {[ catch {set rows [$odbc allrows $sql ]} message]} {
if { $RAISEERROR } {
error "Query Error :$message"
	} else {
puts "$message"
	}
} else {
return $rows
	}
} 
#########################
#TPCH REFRESH PROCEDURE
proc mk_order_ref { odbc upd_num scale_factor trickle_refresh REFRESH_VERBOSE } { 
#2.27.2 Refresh Function Definition
#LOOP (SF * 1500) TIMES
#INSERT a new row into the ORDERS table
#LOOP RANDOM(1, 7) TIMES
#INSERT a new row into the LINEITEM table
#END LOOP
#END LOOP
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
$odbc evaldirect "INSERT INTO orders (o_orderdate, o_orderkey, o_custkey, o_orderpriority, o_shippriority, o_clerk, o_orderstatus, o_totalprice, o_comment) VALUES ('$date', '$okey', '$custkey', '$opriority', '$spriority', '$clerk', '$orderstatus', '$totalprice', '$comment')"
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
odbc evaldirect "INSERT INTO lineitem (l_shipdate, l_orderkey, l_discount, l_extendedprice, l_suppkey, l_quantity, l_returnflag, l_partkey, l_linestatus, l_tax, l_commitdate, l_receiptdate, l_shipmode, l_linenumber, l_shipinstruct, l_comment) VALUES ('$lsdate','$lokey', '$ldiscount', '$leprice', '$lsuppkey', '$lquantity', '$lrflag', '$lpartkey', '$lstatus', '$ltax', '$lcdate', '$lrdate', '$lsmode', '$llcnt', '$linstruct', '$lcomment')"
  }
if { ![ expr {$i % 1000} ] } {     
   }
}
}

proc del_order_ref { odbc upd_num scale_factor trickle_refresh REFRESH_VERBOSE } {
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
$odbc evaldirect "DELETE FROM lineitem WHERE l_orderkey = $okey"
$odbc evaldirect "DELETE FROM orders WHERE o_orderkey = $okey"
if { $REFRESH_VERBOSE } {
puts "Refresh Delete Orderkey $okey..."
	}
if { ![ expr {$i % 1000} ] } {     
   }
 }
}

proc do_refresh { server port scale_factor odbc_driver authentication uid pwd tcp azure database update_sets trickle_refresh REFRESH_VERBOSE RF_SET } {
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd $tcp $azure $database ]
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
error "Connection to $connection could not be established : $message"
 } else {
if {!$azure} {odbc evaldirect "use $database"}
odbc evaldirect "set implicit_transactions OFF"
}
set upd_num 1
for { set set_counter 1 } {$set_counter <= $update_sets } {incr set_counter} {
if {  [ tsv::get application abort ]  } { break }
if { $RF_SET eq "RF1" || $RF_SET eq "BOTH" } {
puts "New Sales refresh"
set r0 [clock clicks -millisec]
mk_order_ref odbc $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE
set r1 [clock clicks -millisec]
set rvalnew [expr {double($r1-$r0)/1000}]
puts "New Sales refresh complete in $rvalnew seconds"
        }
if { $RF_SET eq "RF2" || $RF_SET eq "BOTH" } {
puts "Old Sales refresh"
set r3 [clock clicks -millisec]
del_order_ref odbc $upd_num $scale_factor $trickle_refresh $REFRESH_VERBOSE
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
odbc close
}
#########################
#TPCH QUERY GENERATION
proc set_query { maxdop myposition } {
global sql
set sql(1) "select l_returnflag, l_linestatus, sum(cast(l_quantity as bigint)) as sum_qty, sum(l_extendedprice) as sum_base_price, sum(l_extendedprice * (1 - l_discount)) as sum_disc_price, sum(l_extendedprice * (1 - l_discount) * (1 + l_tax)) as sum_charge, avg(cast(l_quantity as bigint)) as avg_qty, avg(l_extendedprice) as avg_price, avg(l_discount) as avg_disc, count_big(*) as count_order from lineitem where l_shipdate <= dateadd(dd,-:1,cast('1998-12-01'as datetime)) group by l_returnflag, l_linestatus order by l_returnflag, l_linestatus option (maxdop $maxdop)"
set sql(2) "select top 100 s_acctbal, s_name, n_name, p_partkey, p_mfgr, s_address, s_phone, s_comment from part, supplier, partsupp, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and p_size = :1 and p_type like '%:2' and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3' and ps_supplycost = ( select min(ps_supplycost) from partsupp, supplier, nation, region where p_partkey = ps_partkey and s_suppkey = ps_suppkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':3') order by s_acctbal desc, n_name, s_name, p_partkey option (maxdop $maxdop)"
set sql(3) "select top 10 l_orderkey, sum(l_extendedprice * (1 - l_discount)) as revenue, o_orderdate, o_shippriority from customer, orders, lineitem where c_mktsegment = ':1' and c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate < ':2' and l_shipdate > ':2' group by l_orderkey, o_orderdate, o_shippriority order by revenue desc, o_orderdate option (maxdop $maxdop)"
set sql(4) "select o_orderpriority, count_big(*) as order_count from orders where o_orderdate >= ':1' and o_orderdate < dateadd(mm,3,cast(':1'as datetime)) and exists ( select * from lineitem where l_orderkey = o_orderkey and l_commitdate < l_receiptdate) group by o_orderpriority order by o_orderpriority option (maxdop $maxdop)"
set sql(5) "select n_name, sum(l_extendedprice * (1 - l_discount)) as revenue from customer, orders, lineitem, supplier, nation, region where c_custkey = o_custkey and l_orderkey = o_orderkey and l_suppkey = s_suppkey and c_nationkey = s_nationkey and s_nationkey = n_nationkey and n_regionkey = r_regionkey and r_name = ':1' and o_orderdate >= ':2' and o_orderdate < dateadd(yy,1,cast(':2'as datetime)) group by n_name order by revenue desc option (maxdop $maxdop)"
set sql(6) "select sum(l_extendedprice * l_discount) as revenue from lineitem where l_shipdate >= ':1' and l_shipdate < dateadd(yy,1,cast(':1'as datetime)) and l_discount between :2 - 0.01 and :2 + 0.01 and l_quantity < :3 option (maxdop $maxdop)"
set sql(7) "select supp_nation, cust_nation, l_year, sum(volume) as revenue from ( select n1.n_name as supp_nation, n2.n_name as cust_nation, datepart(yy,l_shipdate) as l_year, l_extendedprice * (1 - l_discount) as volume from supplier, lineitem, orders, customer, nation n1, nation n2 where s_suppkey = l_suppkey and o_orderkey = l_orderkey and c_custkey = o_custkey and s_nationkey = n1.n_nationkey and c_nationkey = n2.n_nationkey and ( (n1.n_name = ':1' and n2.n_name = ':2') or (n1.n_name = ':2' and n2.n_name = ':1')) and l_shipdate between '1995-01-01' and '1996-12-31') shipping group by supp_nation, cust_nation, l_year order by supp_nation, cust_nation, l_year option (maxdop $maxdop)"
set sql(8) "select o_year, sum(case when nation = ':1' then volume else 0 end) / sum(volume) as mkt_share from (select datepart(yy,o_orderdate) as o_year, l_extendedprice * (1 - l_discount) as volume, n2.n_name as nation from part, supplier, lineitem, orders, customer, nation n1, nation n2, region where p_partkey = l_partkey and s_suppkey = l_suppkey and l_orderkey = o_orderkey and o_custkey = c_custkey and c_nationkey = n1.n_nationkey and n1.n_regionkey = r_regionkey and r_name = ':2' and s_nationkey = n2.n_nationkey and o_orderdate between '1995-01-01' and '1996-12-31' and p_type = ':3') all_nations group by o_year order by o_year option (maxdop $maxdop)"
set sql(9) "select nation, o_year, sum(amount) as sum_profit from ( select n_name as nation, datepart(yy,o_orderdate) as o_year, l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount from part, supplier, lineitem, partsupp, orders, nation where s_suppkey = l_suppkey and ps_suppkey = l_suppkey and ps_partkey = l_partkey and p_partkey = l_partkey and o_orderkey = l_orderkey and s_nationkey = n_nationkey and p_name like '%:1%') profit group by nation, o_year order by nation, o_year desc option (maxdop $maxdop)"
set sql(10) "select top 20 c_custkey, c_name, sum(l_extendedprice * (1 - l_discount)) as revenue, c_acctbal, n_name, c_address, c_phone, c_comment from customer, orders, lineitem, nation where c_custkey = o_custkey and l_orderkey = o_orderkey and o_orderdate >= ':1' and o_orderdate < dateadd(mm,3,cast(':1'as datetime)) and l_returnflag = 'R' and c_nationkey = n_nationkey group by c_custkey, c_name, c_acctbal, c_phone, n_name, c_address, c_comment order by revenue desc option (maxdop $maxdop)"
set sql(11) "select ps_partkey, sum(ps_supplycost * ps_availqty) as value from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1' group by ps_partkey having sum(ps_supplycost * ps_availqty) > ( select sum(ps_supplycost * ps_availqty) * :2 from partsupp, supplier, nation where ps_suppkey = s_suppkey and s_nationkey = n_nationkey and n_name = ':1') order by value desc option (maxdop $maxdop)"
set sql(12) "select l_shipmode, sum(case when o_orderpriority = '1-URGENT' or o_orderpriority = '2-HIGH' then 1 else 0 end) as high_line_count, sum(case when o_orderpriority <> '1-URGENT' and o_orderpriority <> '2-HIGH' then 1 else 0 end) as low_line_count from orders, lineitem where o_orderkey = l_orderkey and l_shipmode in (':1', ':2') and l_commitdate < l_receiptdate and l_shipdate < l_commitdate and l_receiptdate >= ':3' and l_receiptdate < dateadd(mm,1,cast(':3' as datetime)) group by l_shipmode order by l_shipmode option (maxdop $maxdop)"
set sql(13) "select c_count, count_big(*) as custdist from ( select c_custkey, count(o_orderkey) as c_count from customer left outer join orders on c_custkey = o_custkey and o_comment not like '%:1%:2%' group by c_custkey) c_orders group by c_count order by custdist desc, c_count desc option (maxdop $maxdop)"
set sql(14) "select 100.00 * sum(case when p_type like 'PROMO%' then l_extendedprice * (1 - l_discount) else 0 end) / sum(l_extendedprice * (1 - l_discount)) as promo_revenue from lineitem, part where l_partkey = p_partkey and l_shipdate >= ':1' and l_shipdate < dateadd(mm,1,':1') option (maxdop $maxdop)"
set sql(15) "create view revenue$myposition (supplier_no, total_revenue) as select l_suppkey, sum(l_extendedprice * (1 - l_discount)) from lineitem where l_shipdate >= ':1' and l_shipdate < dateadd(mm,3,cast(':1' as datetime)) group by l_suppkey; select s_suppkey, s_name, s_address, s_phone, total_revenue from supplier, revenue$myposition where s_suppkey = supplier_no and total_revenue = ( select max(total_revenue) from revenue$myposition) order by s_suppkey option (maxdop $maxdop); drop view revenue$myposition"
set sql(16) "select p_brand, p_type, p_size, count(distinct ps_suppkey) as supplier_cnt from partsupp, part where p_partkey = ps_partkey and p_brand <> ':1' and p_type not like ':2%' and p_size in (:3, :4, :5, :6, :7, :8, :9, :10) and ps_suppkey not in ( select s_suppkey from supplier where s_comment like '%Customer%Complaints%') group by p_brand, p_type, p_size order by supplier_cnt desc, p_brand, p_type, p_size option (maxdop $maxdop)"
set sql(17) "select sum(l_extendedprice) / 7.0 as avg_yearly from lineitem, part where p_partkey = l_partkey and p_brand = ':1' and p_container = ':2' and l_quantity < ( select 0.2 * avg(l_quantity) from lineitem where l_partkey = p_partkey) option (maxdop $maxdop)"
set sql(18) "select top 100 c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice, sum(l_quantity) from customer, orders, lineitem where o_orderkey in ( select l_orderkey from lineitem group by l_orderkey having sum(l_quantity) > :1) and c_custkey = o_custkey and o_orderkey = l_orderkey group by c_name, c_custkey, o_orderkey, o_orderdate, o_totalprice order by o_totalprice desc, o_orderdate option (maxdop $maxdop)"
set sql(19) "select sum(l_extendedprice* (1 - l_discount)) as revenue from lineitem, part where ( p_partkey = l_partkey and p_brand = ':1' and p_container in ('SM CASE', 'SM BOX', 'SM PACK', 'SM PKG') and l_quantity >= :4 and l_quantity <= :4 + 10 and p_size between 1 and 5 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':2' and p_container in ('MED BAG', 'MED BOX', 'MED PKG', 'MED PACK') and l_quantity >= :5 and l_quantity <= :5 + 10 and p_size between 1 and 10 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') or ( p_partkey = l_partkey and p_brand = ':3' and p_container in ('LG CASE', 'LG BOX', 'LG PACK', 'LG PKG') and l_quantity >= :6 and l_quantity <= :6 + 10 and p_size between 1 and 15 and l_shipmode in ('AIR', 'AIR REG') and l_shipinstruct = 'DELIVER IN PERSON') option (maxdop $maxdop)"
set sql(20) "select s_name, s_address from supplier, nation where s_suppkey in ( select ps_suppkey from partsupp where ps_partkey in ( select p_partkey from part where p_name like ':1%') and ps_availqty > ( select 0.5 * sum(l_quantity) from lineitem where l_partkey = ps_partkey and l_suppkey = ps_suppkey and l_shipdate >= ':2' and l_shipdate < dateadd(yy,1,':2'))) and s_nationkey = n_nationkey and n_name = ':3' order by s_name option (maxdop $maxdop)"
set sql(21) "select top 100 s_name, count_big(*) as numwait from supplier, lineitem l1, orders, nation where s_suppkey = l1.l_suppkey and o_orderkey = l1.l_orderkey and o_orderstatus = 'F' and l1.l_receiptdate > l1.l_commitdate and exists ( select * from lineitem l2 where l2.l_orderkey = l1.l_orderkey and l2.l_suppkey <> l1.l_suppkey) and not exists ( select * from lineitem l3 where l3.l_orderkey = l1.l_orderkey and l3.l_suppkey <> l1.l_suppkey and l3.l_receiptdate > l3.l_commitdate) and s_nationkey = n_nationkey and n_name = ':1' group by s_name order by numwait desc, s_name option (maxdop $maxdop)"
set sql(22) "select cntrycode, count_big(*) as numcust, sum(c_acctbal) as totacctbal from ( select substring(c_phone, 1, 2) as cntrycode, c_acctbal from customer where substring(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7') and c_acctbal > ( select avg(c_acctbal) from customer where c_acctbal > 0.00 and substring(c_phone, 1, 2) in (':1', ':2', ':3', ':4', ':5', ':6', ':7')) and not exists ( select * from orders where o_custkey = c_custkey)) custsale group by cntrycode order by cntrycode option (maxdop $maxdop)"
}

proc get_query { query_no maxdop myposition } {
global sql
if { ![ array exists sql ] } { set_query $maxdop $myposition }
return $sql($query_no)
}

proc sub_query { query_no scale_factor maxdop myposition } {
set P_SIZE_MIN 1
set P_SIZE_MAX 50
set MAX_PARAM 10
set q2sub [get_query $query_no $maxdop $myposition ]
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
proc do_tpch { server port scale_factor odbc_driver authentication uid pwd tcp azure db RAISEERROR VERBOSE maxdop total_querysets myposition } {
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd $tcp $azure $db ]
if [catch {tdbc::odbc::connection create odbc $connection} message ] {
error "Connection to $connection could not be established : $message"
 } else {
if {!$azure} {odbc evaldirect "use $db"}
odbc evaldirect "set implicit_transactions OFF"
}
for {set it 0} {$it < $total_querysets} {incr it} {
if {  [ tsv::get application abort ]  } { break }
unset -nocomplain qlist
set start [ clock seconds ]
for { set q 1 } { $q <= 22 } { incr q } {
set dssquery($q)  [sub_query $q $scale_factor $maxdop $myposition ]
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
set oput [ standsql odbc $dssquery($qos) $RAISEERROR ]
set t1 [clock clicks -millisec]
set value [expr {double($t1-$t0)/1000}]
if {$VERBOSE} { printlist $oput }
if { [ llength $oput ] > 0 } { lappend qlist $value }
puts "query $qos completed in $value seconds"
	      } else {
            set q15c 0
            while {$q15c <= [expr $q15length - 1] } {
	if { $q15c != 1 } {
if {[ catch {set sql_output [odbc evaldirect $dssquery($qos,$q15c)]} message]} {
if { $RAISEERROR } {
error "Query Error :$message"
	} else {
puts "$message"
		}
	  }
	} else {
set t0 [clock clicks -millisec]
set oput [ standsql odbc $dssquery($qos,$q15c) $RAISEERROR ]
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
odbc close
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
do_refresh $server $port $scale_factor $odbc_driver $authentication $uid $pwd $tcp $azure $database $update_sets $trickle_refresh $REFRESH_VERBOSE RF1
do_tpch $server $port $scale_factor $odbc_driver $authentication $uid $pwd $tcp $azure $database $RAISEERROR $VERBOSE $maxdop $total_querysets 0
do_refresh $server $port $scale_factor $odbc_driver $authentication $uid $pwd $tcp $azure $database $update_sets $trickle_refresh $REFRESH_VERBOSE RF2
        } else {
switch $myposition {
1 {
do_refresh $server $port $scale_factor $odbc_driver $authentication $uid $pwd $tcp $azure $database $update_sets $trickle_refresh $REFRESH_VERBOSE BOTH
        }
default {
do_tpch $server $port $scale_factor $odbc_driver $authentication $uid $pwd $tcp $azure $database $RAISEERROR $VERBOSE $maxdop $total_querysets [ expr $myposition - 1 ]
        }
    }
 }
} else {
do_tpch $server $port $scale_factor $odbc_driver $authentication $uid $pwd $tcp $azure $database $RAISEERROR $VERBOSE $maxdop $total_querysets $myposition
		}}
}
