proc build_redistpcc { } {
global virtual_users maxvuser suppo ntimes threadscreated _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict redis library ]} {
        set library [ dict get $dbdict redis library ]
} else { set library "redis" }
upvar #0 configredis configredis
#set variables to values in dict
setlocaltpccvars $configredis
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a $redis_count_ware Warehouse Redis TPROC-C schema\nin host [string toupper $redis_host:$redis_port] in namespace $redis_namespace?" -type yesno ] == yes} { 
if { $redis_num_vu eq 1 || $redis_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $redis_num_vu + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPROC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to created thread for schema creation: $message"
	return
	}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#LOAD LIBRARIES AND MODULES
set library $library
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}

proc Customer { redis d_id w_id CUST_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
set chalen [ llength $globArray ]
set c_d_id $d_id
set c_w_id $w_id
set c_middle "OE"
set c_balance -10.0
set c_credit_lim 50000
set h_amount 10.0
puts "Loading Customer for DID=$d_id WID=$w_id"
for {set c_id 1} {$c_id <= $CUST_PER_DIST } {incr c_id } {
set c_first [ MakeAlphaString 8 16 $globArray $chalen ]
if { $c_id <= 1000 } {
set c_last [ Lastname [ expr {$c_id - 1} ] $namearr ]
	} else {
set nrnd [ NURand 255 0 999 123 ]
set c_last [ Lastname $nrnd $namearr ]
	}
set c_add [ MakeAddress $globArray $chalen ]
set c_phone [ MakeNumberString ]
if { [RandomNumber 0 1] eq 1 } {
set c_credit "GC"
	} else {
set c_credit "BC"
	}
set disc_ran [ RandomNumber 0 50 ]
set c_discount [ expr {$disc_ran / 100.0} ]
set c_data [ MakeAlphaString 300 500 $globArray $chalen ]
$redis HMSET CUSTOMER:$c_w_id:$c_d_id:$c_id C_ID $c_id C_D_ID $c_d_id C_W_ID $c_w_id C_FIRST $c_first C_MIDDLE $c_middle C_LAST $c_last C_STREET_1 [ lindex $c_add 0 ] C_STREET_2 [ lindex $c_add 1 ] C_CITY [ lindex $c_add 2 ] C_STATE [ lindex $c_add 3 ] C_ZIP [ lindex $c_add 4 ] C_PHONE $c_phone C_SINCE [ gettimestamp ] C_CREDIT $c_credit C_CREDIT_LIM $c_credit_lim C_DISCOUNT $c_discount C_BALANCE $c_balance C_DATA $c_data C_YTD_PAYMENT 10.0 C_PAYMENT_CNT 1 C_DELIVERY_CNT 0
$redis LPUSH CUSTOMER_OSTAT_PMT_QUERY:$c_w_id:$c_d_id:$c_last $c_id
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
set tstamp [ gettimestamp ]
$redis HMSET HISTORY:$c_w_id:$c_d_id:$c_id:$tstamp H_C_ID $c_id H_C_D_ID $c_d_id H_C_W_ID $c_w_id H_W_ID $c_w_id H_D_ID $c_d_id H_DATE $tstamp H_AMOUNT $h_amount H_DATA $h_data
	}
puts "Customer Done"
return
}

proc Orders { redis d_id w_id MAXITEMS ORD_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Orders for D=$d_id W=$w_id"
set o_d_id $d_id
set o_w_id $w_id
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set cust($i) $i
}
for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
set r [ RandomNumber $i $ORD_PER_DIST ]
set t $cust($i)
set cust($i) $cust($r)
set $cust($r) $t
}
set e ""
for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
set o_c_id $cust($o_id)
set o_carrier_id [ RandomNumber 1 10 ]
set o_ol_cnt [ RandomNumber 5 15 ]
if { $o_id > 2100 } {
set e "o1"
$redis HMSET ORDERS:$o_w_id:$o_d_id:$o_id O_ID $o_id O_C_ID $o_c_id O_D_ID $o_d_id O_W_ID $o_w_id O_ENTRY_D [ gettimestamp ] O_CARRIER_ID "" O_OL_CNT $o_ol_cnt O_ALL_LOCAL 1
#Maintain list of orders per customer for Order Status
$redis LPUSH ORDERS_OSTAT_QUERY:$o_w_id:$o_d_id:$o_c_id $o_id
set e "no1"
$redis HMSET NEW_ORDER:$o_w_id:$o_d_id:$o_id NO_O_ID $o_id NO_D_ID $o_d_id NO_W_ID $o_w_id 
$redis LPUSH NEW_ORDER_IDS:$o_w_id:$o_d_id $o_id
  } else {
  set e "o3"
$redis HMSET ORDERS:$o_w_id:$o_d_id:$o_id O_ID $o_id O_C_ID $o_c_id O_D_ID $o_d_id O_W_ID $o_w_id O_ENTRY_D [ gettimestamp ] O_CARRIER_ID $o_carrier_id O_OL_CNT $o_ol_cnt O_ALL_LOCAL 1
#Maintain list of orders per customer for Order Status
$redis LPUSH ORDERS_OSTAT_QUERY:$o_w_id:$o_d_id:$o_c_id $o_id
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
$redis HMSET ORDER_LINE:$o_w_id:$o_d_id:$o_id:$ol OL_O_ID $o_id OL_D_ID $o_d_id OL_W_ID $o_w_id OL_NUMBER $ol OL_I_ID $ol_i_id OL_SUPPLY_W_ID $ol_supply_w_id OL_QUANTITY $ol_quantity OL_AMOUNT $ol_amount OL_DIST_INFO $ol_dist_info OL_DELIVERY_D ""
#Maintain a list of order line numbers for delivery procedure to update
$redis LPUSH ORDER_LINE_NUMBERS:$o_w_id:$o_d_id:$o_id $ol 
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
$redis HMSET ORDER_LINE:$o_w_id:$o_d_id:$o_id:$ol OL_O_ID $o_id OL_D_ID $o_d_id OL_W_ID $o_w_id OL_NUMBER $ol OL_I_ID $ol_i_id OL_SUPPLY_W_ID $ol_supply_w_id OL_QUANTITY $ol_quantity OL_AMOUNT $ol_amount OL_DIST_INFO $ol_dist_info OL_DELIVERY_D [ gettimestamp ]
	}
#maintain a sorted set of order lines with order id as score and item id as element so slev procedure can get item_ids from 20 most recent orders 
$redis ZADD ORDER_LINE_SLEV_QUERY:$o_w_id:$o_d_id $o_id $ol_i_id
}
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
			}
		}
	puts "Orders Done"
	return
}

proc LoadItems { redis MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Item"
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set i_id 1} {$i_id <= $MAXITEMS } {incr i_id } {
set i_im_id [ RandomNumber 1 10000 ] 
set i_name [ MakeAlphaString 14 24 $globArray $chalen ]
set i_price_ran [ RandomNumber 100 10000 ]
set i_price [ format "%4.2f" [ expr {$i_price_ran / 100.0} ] ]
set i_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($i_id) ] } {
if { $orig($i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $i_data] - 8}] ]
set last [ expr {$first + 8} ]
set i_data [ string replace $i_data $first $last "original" ]
	}
}
$redis HMSET ITEM:$i_id I_ID $i_id I_IM_ID $i_im_id I_NAME $i_name I_PRICE $i_price I_DATA $i_data
      if { ![ expr {$i_id % 50000} ] } {
	puts "Loading Items - $i_id"
			}
		}
	puts "Item done"
	return
	}

proc Stock { redis w_id MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Stock Wid=$w_id"
set s_w_id $w_id
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set orig($i) 0
}
for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
set pos [ RandomNumber 0 $MAXITEMS ] 
set orig($pos) 1
	}
for {set s_i_id 1} {$s_i_id <= $MAXITEMS } {incr s_i_id } {
set s_quantity [ RandomNumber 10 100 ]
set s_dist_01 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_02 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_03 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_04 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_05 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_06 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_07 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_08 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_09 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_dist_10 [ MakeAlphaString 24 24 $globArray $chalen ]
set s_data [ MakeAlphaString 26 50 $globArray $chalen ]
if { [ info exists orig($s_i_id) ] } {
if { $orig($s_i_id) eq 1 } {
set first [ RandomNumber 0 [ expr {[ string length $s_data]} - 8 ] ]
set last [ expr {$first + 8} ]
set s_data [ string replace $s_data $first $last "original" ]
		}
	}
$redis HMSET STOCK:$s_w_id:$s_i_id S_I_ID $s_i_id S_W_ID $s_w_id S_QUANTITY $s_quantity S_DIST_01 $s_dist_01 S_DIST_02 $s_dist_02 S_DIST_03 $s_dist_03 S_DIST_04 $s_dist_04 S_DIST_05 $s_dist_05 S_DIST_06 $s_dist_06 S_DIST_07 $s_dist_07 S_DIST_08 $s_dist_08 S_DIST_09 $s_dist_09 S_DIST_10 $s_dist_10 S_DATA $s_data S_YTD 0 S_ORDER_CNT 0 S_REMOTE_CNT 0
      if { ![ expr {$s_i_id % 20000} ] } {
	puts "Loading Stock - $s_i_id"
			}
	}
	puts "Stock done"
	return
}

proc District { redis w_id DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading District"
set d_w_id $w_id
set d_ytd 30000.0
set d_next_o_id 3001
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
$redis HMSET DISTRICT:$d_w_id:$d_id D_ID $d_id D_W_ID $d_w_id D_NAME $d_name D_STREET_1 [ lindex $d_add 0 ] D_STREET_2 [ lindex $d_add 1 ] D_CITY [ lindex $d_add 2 ] D_STATE [ lindex $d_add 3 ] D_ZIP [ lindex $d_add 4 ] D_TAX $d_tax D_YTD $d_ytd D_NEXT_O_ID $d_next_o_id
	}
	puts "District done"
	return
}

proc LoadWare { redis ware_start count_ware MAXITEMS DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
$redis HMSET WAREHOUSE:$w_id W_ID $w_id W_NAME $w_name W_STREET_1 [ lindex $add 0 ] W_STREET_2 [ lindex $add 1 ] W_CITY [ lindex $add 2 ] W_STATE [ lindex $add 3 ] W_ZIP [ lindex $add 4 ] W_TAX $w_tax W_YTD $w_ytd
	Stock $redis $w_id $MAXITEMS
	District $redis $w_id $DIST_PER_WARE
	}
}

proc LoadCust { redis ware_start count_ware CUST_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer $redis $d_id $w_id $CUST_PER_DIST
		}
	}
	return
}

proc LoadOrd { redis ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Orders $redis $d_id $w_id $MAXITEMS $ORD_PER_DIST
		}
	}
	return
}

proc do_tpcc { host port namespace count_ware num_vu } {
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
if { $num_vu > $count_ware } { set num_vu $count_ware }
if { $num_vu > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set rema [ lassign [ findvuposition ] myposition totalvirtualusers ]
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
if { [ expr $myposition - 1 ] > $count_ware } { puts "No Warehouses to Create"; return }
     }
   }
} else {
set threaded "SINGLE-THREADED"
set num_vu 1
  }
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "CREATING REDIS SCHEMA IN NAMESPACE $namespace"
if {[catch {set redis [redis $host $port ]}]} {
puts stderr "Error, the connection to $host:$port could not be established"
return
 } else {
if {[ $redis ping ] eq "PONG" }  {
puts "Connection made to Redis at $host:$port"
if { [ string is integer -strict $namespace ]} {
puts "Selecting Namespace $namespace"
$redis SELECT $namespace
$redis SET COUNT_WARE $count_ware
$redis SET DIST_PER_WARE $DIST_PER_WARE
	}
	} else {
puts stderr "Error, No response from redis server at $host:$port"
	}
    }
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems $redis $MAXITEMS
puts "Monitoring Workers..."
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
LoadItems $redis $MAXITEMS
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
if { [ tsv::exists application load ] } {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
}
after 5000
}
if {[catch {set redis [redis $host $port ]}]} {
puts stderr "Error, the connection to $host:$port could not be established"
return
 } else {
if {[ $redis ping ] eq "PONG" }  {
puts "Connection made to Redis at $host:$port"
if { [ string is integer -strict $namespace ]} {
puts "Selecting Namespace $namespace"
$redis SELECT $namespace
	}
	} else {
puts stderr "Error, No response from redis server at $host:$port"
	}
    }
set remb [ lassign [ findchunk $num_vu $count_ware $myposition ] chunk mystart myend ]
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare $redis $mystart $myend $MAXITEMS $DIST_PER_WARE
LoadCust $redis $mystart $myend $CUST_PER_DIST $DIST_PER_WARE
LoadOrd $redis $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE
puts "End:[ clock format [ clock seconds ] ]"
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
puts "REDIS SCHEMA COMPLETE"
$redis QUIT
return
		}
	}
}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "do_tpcc $redis_host $redis_port $redis_namespace $redis_count_ware $redis_num_vu"
	} else { return }
}

proc loadredistpcc {} {
global _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict redis library ]} {
        set library [ dict get $dbdict redis library ]
} else { set library "redis" }
upvar #0 configredis configredis
#set variables to values in dict
setlocaltpccvars $configredis
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "Redis TPROC-C"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# Redis Library
set total_iterations $redis_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$redis_raiseerror\" ;# Exit script on Redis error (true or false)
set KEYANDTHINK \"$redis_keyandthink\" ;# Time for user thinking and keying (true or false)
set host \"$redis_host\" ;# Address of the server hosting Redis 
set port \"$redis_port\" ;# Port of the Redis Server, defaults to 6379
set namespace \"$redis_namespace\" ;# Namespace containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}

#NEW ORDER
proc neword { redis no_w_id w_id_input RAISEERROR } {
set no_d_id [ RandomNumber 1 10 ]
set no_c_id [ RandomNumber 1 3000 ]
set ol_cnt [ RandomNumber 5 15 ]
set date [ gettimestamp ]
set no_o_all_local 0
foreach { no_c_discount no_c_last no_c_credit } [ $redis HMGET CUSTOMER:$no_w_id:$no_d_id:$no_c_id C_DISCOUNT C_LAST C_CREDIT ] {}
set no_w_tax [ $redis HMGET WAREHOUSE:$no_w_id W_TAX ]
set no_d_tax [ $redis HMGET DISTRICT:$no_w_id:$no_d_id D_TAX ]
set d_next_o_id [ $redis HINCRBY DISTRICT:$no_w_id:$no_d_id D_NEXT_O_ID 1 ]
set o_id $d_next_o_id
$redis HMSET ORDERS:$no_w_id:$no_d_id:$o_id O_ID $o_id O_C_ID $no_c_id O_D_ID $no_d_id O_W_ID $no_w_id O_ENTRY_D $date O_CARRIER_ID "" O_OL_CNT $ol_cnt NO_ALL_LOCAL $no_o_all_local
$redis LPUSH ORDERS_OSTAT_QUERY:$no_w_id:$no_d_id:$no_c_id $o_id
$redis HMSET NEW_ORDER:$no_w_id:$no_d_id:$o_id NO_O_ID $o_id NO_D_ID $no_d_id NO_W_ID $no_w_id
$redis LPUSH NEW_ORDER_IDS:$no_w_id:$no_d_id $o_id
set rbk [ RandomNumber 1 100 ]  
for {set loop_counter 1} {$loop_counter <= $ol_cnt} {incr loop_counter} {
if { ($loop_counter eq $ol_cnt) && ($rbk eq 1) } {
#No Rollback Support in Redis
set no_ol_i_id 100001
puts "New Order:Invalid Item id:$no_ol_i_id (intentional error)" 
return
	     } else {
set no_ol_i_id [ RandomNumber 1 100000 ]  
		}
set x [ RandomNumber 1 100 ]  
if { $x > 1 } {
set no_ol_supply_w_id $no_w_id
	} else {
set no_ol_supply_w_id $no_w_id
set no_o_all_local 0
while { ($no_ol_supply_w_id eq $no_w_id) && ($w_id_input != 1) } {
set no_ol_supply_w_id [ RandomNumber 1 $w_id_input ]  
		}
	}
set no_ol_quantity [ RandomNumber 1 10 ]  
foreach { no_i_name no_i_price no_i_data } [ $redis HMGET ITEM:$no_ol_i_id I_NAME I_PRICE I_DATA ] {}
foreach { no_s_quantity no_s_data no_s_dist_01 no_s_dist_02 no_s_dist_03 no_s_dist_04 no_s_dist_05 no_s_dist_06 no_s_dist_07 no_s_dist_08 no_s_dist_09 no_s_dist_10 } [ $redis HMGET STOCK:$no_ol_supply_w_id:$no_ol_i_id S_QUANTITY S_DATA S_DIST_01 S_DIST_02 S_DIST_03 S_DIST_04 S_DIST_05 S_DIST_06 S_DIST_07 S_DIST_08 S_DIST_09 S_DIST_10 ] {}
if { $no_s_quantity > $no_ol_quantity } {
set no_s_quantity [ expr $no_s_quantity - $no_ol_quantity ]
	} else {
set no_s_quantity [ expr ($no_s_quantity - $no_ol_quantity) + 91 ]
	}
$redis HMSET STOCK:$no_ol_supply_w_id:$no_ol_i_id  S_QUANTITY $no_s_quantity 
set no_ol_amount [ expr $no_ol_quantity * $no_i_price * ( 1 + $no_w_tax + $no_d_tax ) * ( 1 - $no_c_discount ) ]
switch $no_d_id {
1 { set no_ol_dist_info $no_s_dist_01 }
2 { set no_ol_dist_info $no_s_dist_02 }
3 { set no_ol_dist_info $no_s_dist_03 }
4 { set no_ol_dist_info $no_s_dist_04 }
5 { set no_ol_dist_info $no_s_dist_05 }
6 { set no_ol_dist_info $no_s_dist_06 }
7 { set no_ol_dist_info $no_s_dist_07 }
8 { set no_ol_dist_info $no_s_dist_08 }
9 { set no_ol_dist_info $no_s_dist_09 }
10 { set no_ol_dist_info $no_s_dist_10 }
	     }
$redis HMSET ORDER_LINE:$no_w_id:$no_d_id:$o_id:$loop_counter OL_O_ID $o_id OL_D_ID $no_d_id OL_W_ID $no_w_id OL_NUMBER $loop_counter OL_I_ID $no_ol_i_id OL_SUPPLY_W_ID $no_ol_supply_w_id OL_QUANTITY $no_ol_quantity OL_AMOUNT $no_ol_amount OL_DIST_INFO $no_ol_dist_info OL_DELIVERY_D ""
$redis LPUSH ORDER_LINE_NUMBERS:$no_w_id:$no_d_id:$o_id $loop_counter 
$redis ZADD ORDER_LINE_SLEV_QUERY:$no_w_id:$no_d_id $o_id $no_ol_i_id
	}
puts "$no_c_discount $no_c_last $no_c_credit $no_w_tax $no_d_tax $d_next_o_id" 
   }

#PAYMENT
proc payment { redis p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT WAREHOUSE:$p_w_id W_YTD $p_h_amount
$redis HMSET WAREHOUSE:$p_w_id W_YTD [ expr  [ $redis HMGET WAREHOUSE:$p_w_id W_YTD ] + $p_h_amount ]
foreach { p_w_street_1 p_w_street_2 p_w_city p_w_state p_w_zip p_w_name } [ $redis HMGET WAREHOUSE:$p_w_id W_STREET_1 W_STREET_2 W_CITY W_STATE W_ZIP W_NAME ] {}
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT DISTRICT:$p_w_id:$p_d_id D_YTD $p_h_amount
$redis HMSET DISTRICT:$p_w_id:$p_d_id D_YTD [ expr  [ $redis HMGET DISTRICT:$p_w_id:$p_d_id D_YTD ] + $p_h_amount ]
foreach { p_d_street_1 p_d_street_2 p_d_city p_d_state p_d_zip p_d_name } [ $redis HMGET DISTRICT:$p_w_id:$p_d_id D_STREET_1 D_STREET_2 D_CITY D_STATE D_ZIP D_NAME ]  {}
if { $byname eq 1 } {
set namecnt [ $redis LLEN CUSTOMER_OSTAT_PMT_QUERY:$p_w_id:$p_d_id:$name ]
set cust_last_list [ $redis LRANGE CUSTOMER_OSTAT_PMT_QUERY:$p_w_id:$p_d_id:$name 0 $namecnt ] 
if { [ expr {$namecnt % 2} ] eq 1 } {
incr namecnt
	}
foreach cust_id $cust_last_list {
set first_name [ $redis HMGET CUSTOMER:$p_w_id:$p_d_id:$cust_id C_FIRST ]
lappend cust_first_list $first_name
set first_to_id($first_name) $cust_id
	}
set cust_first_list [ lsort $cust_first_list ]
set id_to_query $first_to_id([ lindex $cust_first_list [ expr ($namecnt/2)-1 ] ])
foreach { p_c_first p_c_middle p_c_id p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since } [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$id_to_query C_FIRST C_MIDDLE C_ID C_STREET_1 C_STREET_2 C_CITY C_STATE C_ZIP C_PHONE C_CREDIT C_CREDIT_LIM C_DISCOUNT C_BALANCE C_SINCE ] {}
set p_c_last $name
	} else {
foreach { p_c_first p_c_middle p_c_last p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since } [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_FIRST C_MIDDLE C_LAST C_STREET_1 C_STREET_2 C_CITY C_STATE C_ZIP C_PHONE C_CREDIT C_CREDIT_LIM C_DISCOUNT C_BALANCE C_SINCE ] {}
	}
set p_c_balance [ expr $p_c_balance + $p_h_amount ]
set p_c_data [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_DATA ] 
set tstamp [ gettimestamp ]
if { $p_c_credit eq "BC" } {
set h_data "$p_w_name $p_d_name"
set p_c_new_data "$p_c_id $p_c_d_id $p_c_w_id $p_d_id $p_w_id $p_h_amount $tstamp $h_data"
set p_c_new_data [ string range "$p_c_new_data $p_c_data" 0 [ expr 500 - [ string length $p_c_new_data ] ] ]
$redis HMSET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_BALANCE $p_c_balance C_DATA $p_c_new_data
	} else {
$redis HMSET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_BALANCE $p_c_balance
set h_data "$p_w_name $p_d_name"
	}
$redis HMSET HISTORY:$p_c_w_id:$p_c_d_id:$p_c_id:$tstamp H_C_ID $p_c_id H_C_D_ID $p_c_d_id H_C_W_ID $p_c_w_id H_W_ID $p_w_id H_D_ID $p_d_id H_DATE $tstamp H_AMOUNT $p_h_amount H_DATA $h_data
puts "$p_c_id,$p_c_last,$p_w_street_1,$p_w_street_2,$p_w_city,$p_w_state,$p_w_zip,$p_d_street_1,$p_d_street_2,$p_d_city,$p_d_state,$p_d_zip,$p_c_first,$p_c_middle,$p_c_street_1,$p_c_street_2,$p_c_city,$p_c_state,$p_c_zip,$p_c_phone,$p_c_since,$p_c_credit,$p_c_credit_lim,$p_c_discount,$p_c_balance,$p_c_data"
	}

#ORDER_STATUS
proc ostat { redis w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if { $byname eq 1 } {
set namecnt [ $redis LLEN CUSTOMER_OSTAT_PMT_QUERY:$w_id:$d_id:$name ]
set cust_last_list [ $redis LRANGE CUSTOMER_OSTAT_PMT_QUERY:$w_id:$d_id:$name 0 $namecnt ] 
if { [ expr {$namecnt % 2} ] eq 1 } {
incr namecnt
	}
foreach cust_id $cust_last_list {
set first_name [ $redis HMGET CUSTOMER:$w_id:$d_id:$cust_id C_FIRST ]
lappend cust_first_list $first_name
set first_to_id($first_name) $cust_id
	}
set cust_first_list [ lsort $cust_first_list ]
set id_to_query $first_to_id([ lindex $cust_first_list [ expr ($namecnt/2)-1 ] ])
foreach { os_c_balance os_c_first os_c_middle os_c_id } [ $redis HMGET CUSTOMER:$w_id:$d_id:$id_to_query C_BALANCE C_FIRST C_MIDDLE C_ID ] {}
set os_c_last $name
	} else {
foreach { os_c_balance os_c_first os_c_middle os_c_last } [ $redis HMGET CUSTOMER:$w_id:$d_id:$c_id C_BALANCE C_FIRST C_MIDDLE C_LAST ] {}
set os_c_id $c_id
	}
set o_id_len [ $redis LLEN ORDERS_OSTAT_QUERY:$w_id:$d_id:$c_id ]
if { $o_id_len eq 0 } {
puts "No orders for customer"
	} else {
set o_id_list [ lindex [ lsort [ $redis LRANGE ORDERS_OSTAT_QUERY:$w_id:$d_id:$c_id 0 $o_id_len ] ] end ]
foreach { o_id o_carrier_id o_entry_d } [ $redis HMGET ORDERS:$w_id:$d_id:$o_id_list O_ID O_CARRIER_ID O_ENTRY_D ] {}
set os_cline_len [ $redis LLEN ORDER_LINE_NUMBERS:$w_id:$d_id:$o_id ]
set os_cline_list [ lsort -integer [ $redis LRANGE ORDER_LINE_NUMBERS:$w_id:$d_id:$o_id 0 $os_cline_len ] ]
set i 0
foreach ol [ split $os_cline_list ] { 
foreach { ol_i_id ol_supply_w_id ol_quantity ol_amount ol_delivery_d } [ $redis HMGET ORDER_LINE:$w_id:$d_id:$o_id:$ol OL_I_ID OL_SUPPLY_W_ID OL_QUANTITY OL_AMOUNT OL_DELIVERY_D ] {}
set os_ol_i_id($i) $ol_i_id
set os_ol_supply_w_id($i) $ol_supply_w_id
set os_ol_quantity($i) $ol_quantity
set os_ol_amount($i) $ol_amount
set os_ol_delivery_d($i) $ol_delivery_d
incr i
#puts "Item Status $i:$ol_i_id $ol_supply_w_id $ol_quantity $ol_amount $ol_delivery_d"
	}
puts "$os_c_id,$os_c_last,$os_c_first,$os_c_middle,$os_c_balance,$o_id,$o_entry_d,$o_carrier_id"
  }
}
#DELIVERY
proc delivery { redis w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
for {set loop_counter 1} {$loop_counter <= 10} {incr loop_counter} {
set d_d_id $loop_counter 
set d_no_o_id [ $redis LPOP NEW_ORDER_IDS:$w_id:$d_d_id ]
$redis DEL NEW_ORDER:$w_id:$d_d_id:$d_no_o_id
set d_c_id [ $redis HMGET ORDERS:$w_id:$d_d_id:$d_no_o_id O_C_ID ]
$redis HMSET ORDERS:$w_id:$d_d_id:$d_no_o_id O_CARRIER_ID $carrier_id
set ol_deliv_len [ $redis LLEN ORDER_LINE_NUMBERS:$w_id:$d_d_id:$d_no_o_id ]
set ol_deliv_list [ $redis LRANGE ORDER_LINE_NUMBERS:$w_id:$d_d_id:$d_no_o_id 0 $ol_deliv_len ] 
set d_ol_total 0
foreach ol [ split $ol_deliv_list ] { 
set d_ol_total [expr $d_ol_total + [ $redis HMGET ORDER_LINE:$w_id:$d_d_id:$d_no_o_id:$ol OL_AMOUNT ]]
$redis HMSET ORDER_LINE:$w_id:$d_d_id:$d_no_o_id:$ol OL_DELIVERY_D $date
	}
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE $d_ol_total 
$redis HMSET CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE [ expr [ $redis HMGET CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE ] + $d_ol_total ]
	}
puts "W:$w_id D:$d_d_id O:$d_no_o_id C:$carrier_id time:$date"
}
#STOCK LEVEL
proc slev { redis w_id stock_level_d_id RAISEERROR } {
set stock_level 0
set threshold [ RandomNumber 10 20 ]
set st_o_id [ $redis HMGET DISTRICT:$w_id:$stock_level_d_id D_NEXT_O_ID ]
set item_id_list [ $redis ZRANGE ORDER_LINE_SLEV_QUERY:$w_id:$stock_level_d_id [ expr $st_o_id - 19 ] $st_o_id ]
foreach item_id [ split [ lsort -unique $item_id_list ] ] { 
	if { [ $redis HMGET STOCK:$w_id:$item_id S_QUANTITY ] < $threshold } { incr stock_level } }
puts "$w_id $stock_level_d_id $threshold: $stock_level"
	}

#RUN TPC-C
if {[catch {set redis [redis $host $port ]}]} {
puts stderr "Error, the connection to $host:$port could not be established"
return
 } else {
if {[ $redis ping ] eq "PONG" }  {
puts "Connection made to Redis at $host:$port"
if { [ string is integer -strict $namespace ]} {
puts "Selecting Namespace $namespace"
$redis SELECT $namespace
	}
	} else {
puts stderr "Error, No response from redis server at $host:$port"
	}
    }
set w_id_input [ $redis GET COUNT_WARE ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ $redis GET DIST_PER_WARE ]
set stock_level_d_id [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword $redis $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment $redis $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery $redis $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev $redis $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat $redis $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
$redis QUIT}
}

proc loadtimedredistpcc {} {
global opmode _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict redis library ]} {
        set library [ dict get $dbdict redis library ]
} else { set library "redis" }
upvar #0 configredis configredis
#set variables to values in dict
setlocaltpccvars $configredis
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "Redis TPROC-C"
if { !$redis_async_scale } {
#REGULAR TIMED SCRIPT
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# Redis Library
set total_iterations $redis_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$redis_raiseerror\" ;# Exit script on Redis error (true or false)
set KEYANDTHINK \"$redis_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $redis_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $redis_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set host \"$redis_host\" ;# Address of the server hosting Redis 
set port \"$redis_port\" ;# Port of the Redis Server, defaults to 6379
set namespace \"$redis_namespace\" ;# Namespace containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

if { [ chk_thread ] eq "FALSE" } {
error "Redis Timed Script must be run in Thread Enabled Interpreter"
}
set rema [ lassign [ findvuposition ] myposition totalvirtualusers ]
switch $myposition {
1 { 
if { $mode eq "Local" || $mode eq "Primary" } {
if {[catch {set redis [redis $host $port ]}]} {
puts stderr "Error, the connection to $host:$port could not be established"
return
 } else {
if {[ $redis ping ] eq "PONG" }  {
puts "Connection made to Redis at $host:$port"
if { [ string is integer -strict $namespace ]} {
puts "Selecting Namespace $namespace"
$redis SELECT $namespace
	}
	} else {
puts stderr "Error, No response from redis server at $host:$port"
	}
    }
set ramptime 0
puts "Beginning rampup time of $rampup minutes"
set rampup [ expr $rampup*60000 ]
while {$ramptime != $rampup} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set ramptime [ expr $ramptime+6000 ]
if { ![ expr {$ramptime % 60000} ] } {
puts "Rampup [ expr $ramptime / 60000 ] minutes complete ..."
	}
}
if { [ tsv::get application abort ] } { break }
puts "Rampup complete, Taking start Transaction Count."
set info_list [ split [ $redis info ] "\n" ] 
foreach line $info_list { 
    if {[string match {total_commands_processed:*} $line]} {
regexp {\:([0-9]+)} $line all start_trans
	}
}
set COUNT_WARE [ $redis GET COUNT_WARE ]
set DIST_PER_WARE [ $redis GET DIST_PER_WARE ]
set start_nopm 0
for {set w_id 1} {$w_id <= $COUNT_WARE } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
incr start_nopm [ $redis HMGET DISTRICT:$w_id:$d_id D_NEXT_O_ID ]
	}
}
puts "Timing test period of $duration in minutes"
set testtime 0
set durmin $duration
set duration [ expr $duration*60000 ]
while {$testtime != $duration} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set testtime [ expr $testtime+6000 ]
if { ![ expr {$testtime % 60000} ] } {
puts -nonewline  "[ expr $testtime / 60000 ]  ...,"
	}
}
if { [ tsv::get application abort ] } { break }
puts "Test complete, Taking end Transaction Count."
set info_list [ split [ $redis info ] "\n" ] 
foreach line $info_list { 
    if {[string match {total_commands_processed:*} $line]} {
regexp {\:([0-9]+)} $line all end_trans
	}
}
set end_nopm 0
for {set w_id 1} {$w_id <= $COUNT_WARE } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
incr end_nopm [ $redis HMGET DISTRICT:$w_id:$d_id D_NEXT_O_ID ]
	}
}
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "[ expr $totalvirtualusers - 1 ] Active Virtual Users configured"
puts [ testresult $nopm $tpm Redis ]
tsv::set application abort 1
if { $mode eq "Primary" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
		} else {
puts "Operating in Replica Mode, No Snapshots taken..."
		}
$redis QUIT
	}
default {
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#NEW ORDER
proc neword { redis no_w_id w_id_input RAISEERROR } {
set no_d_id [ RandomNumber 1 10 ]
set no_c_id [ RandomNumber 1 3000 ]
set ol_cnt [ RandomNumber 5 15 ]
set date [ gettimestamp ]
set no_o_all_local 0
foreach { no_c_discount no_c_last no_c_credit } [ $redis HMGET CUSTOMER:$no_w_id:$no_d_id:$no_c_id C_DISCOUNT C_LAST C_CREDIT ] {}
set no_w_tax [ $redis HMGET WAREHOUSE:$no_w_id W_TAX ]
set no_d_tax [ $redis HMGET DISTRICT:$no_w_id:$no_d_id D_TAX ]
set d_next_o_id [ $redis HINCRBY DISTRICT:$no_w_id:$no_d_id D_NEXT_O_ID 1 ]
set o_id $d_next_o_id
$redis HMSET ORDERS:$no_w_id:$no_d_id:$o_id O_ID $o_id O_C_ID $no_c_id O_D_ID $no_d_id O_W_ID $no_w_id O_ENTRY_D $date O_CARRIER_ID "" O_OL_CNT $ol_cnt NO_ALL_LOCAL $no_o_all_local
$redis LPUSH ORDERS_OSTAT_QUERY:$no_w_id:$no_d_id:$no_c_id $o_id
$redis HMSET NEW_ORDER:$no_w_id:$no_d_id:$o_id NO_O_ID $o_id NO_D_ID $no_d_id NO_W_ID $no_w_id
$redis LPUSH NEW_ORDER_IDS:$no_w_id:$no_d_id $o_id
set rbk [ RandomNumber 1 100 ]  
for {set loop_counter 1} {$loop_counter <= $ol_cnt} {incr loop_counter} {
if { ($loop_counter eq $ol_cnt) && ($rbk eq 1) } {
#No Rollback Support in Redis
set no_ol_i_id 100001
#puts "New Order:Invalid Item id:$no_ol_i_id (intentional error)" 
return
	     } else {
set no_ol_i_id [ RandomNumber 1 100000 ]  
		}
set x [ RandomNumber 1 100 ]  
if { $x > 1 } {
set no_ol_supply_w_id $no_w_id
	} else {
set no_ol_supply_w_id $no_w_id
set no_o_all_local 0
while { ($no_ol_supply_w_id eq $no_w_id) && ($w_id_input != 1) } {
set no_ol_supply_w_id [ RandomNumber 1 $w_id_input ]  
		}
	}
set no_ol_quantity [ RandomNumber 1 10 ]  
foreach { no_i_name no_i_price no_i_data } [ $redis HMGET ITEM:$no_ol_i_id I_NAME I_PRICE I_DATA ] {}
foreach { no_s_quantity no_s_data no_s_dist_01 no_s_dist_02 no_s_dist_03 no_s_dist_04 no_s_dist_05 no_s_dist_06 no_s_dist_07 no_s_dist_08 no_s_dist_09 no_s_dist_10 } [ $redis HMGET STOCK:$no_ol_supply_w_id:$no_ol_i_id S_QUANTITY S_DATA S_DIST_01 S_DIST_02 S_DIST_03 S_DIST_04 S_DIST_05 S_DIST_06 S_DIST_07 S_DIST_08 S_DIST_09 S_DIST_10 ] {}
if { $no_s_quantity > $no_ol_quantity } {
set no_s_quantity [ expr $no_s_quantity - $no_ol_quantity ]
	} else {
set no_s_quantity [ expr ($no_s_quantity - $no_ol_quantity) + 91 ]
	}
$redis HMSET STOCK:$no_ol_supply_w_id:$no_ol_i_id  S_QUANTITY $no_s_quantity 
set no_ol_amount [ expr $no_ol_quantity * $no_i_price * ( 1 + $no_w_tax + $no_d_tax ) * ( 1 - $no_c_discount ) ]
switch $no_d_id {
1 { set no_ol_dist_info $no_s_dist_01 }
2 { set no_ol_dist_info $no_s_dist_02 }
3 { set no_ol_dist_info $no_s_dist_03 }
4 { set no_ol_dist_info $no_s_dist_04 }
5 { set no_ol_dist_info $no_s_dist_05 }
6 { set no_ol_dist_info $no_s_dist_06 }
7 { set no_ol_dist_info $no_s_dist_07 }
8 { set no_ol_dist_info $no_s_dist_08 }
9 { set no_ol_dist_info $no_s_dist_09 }
10 { set no_ol_dist_info $no_s_dist_10 }
	     }
$redis HMSET ORDER_LINE:$no_w_id:$no_d_id:$o_id:$loop_counter OL_O_ID $o_id OL_D_ID $no_d_id OL_W_ID $no_w_id OL_NUMBER $loop_counter OL_I_ID $no_ol_i_id OL_SUPPLY_W_ID $no_ol_supply_w_id OL_QUANTITY $no_ol_quantity OL_AMOUNT $no_ol_amount OL_DIST_INFO $no_ol_dist_info OL_DELIVERY_D ""
$redis LPUSH ORDER_LINE_NUMBERS:$no_w_id:$no_d_id:$o_id $loop_counter 
$redis ZADD ORDER_LINE_SLEV_QUERY:$no_w_id:$no_d_id $o_id $no_ol_i_id
	}
	;
   }

#PAYMENT
proc payment { redis p_w_id w_id_input RAISEERROR } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT WAREHOUSE:$p_w_id W_YTD $p_h_amount
$redis HMSET WAREHOUSE:$p_w_id W_YTD [ expr  [ $redis HMGET WAREHOUSE:$p_w_id W_YTD ] + $p_h_amount ]
foreach { p_w_street_1 p_w_street_2 p_w_city p_w_state p_w_zip p_w_name } [ $redis HMGET WAREHOUSE:$p_w_id W_STREET_1 W_STREET_2 W_CITY W_STATE W_ZIP W_NAME ] {}
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT DISTRICT:$p_w_id:$p_d_id D_YTD $p_h_amount
$redis HMSET DISTRICT:$p_w_id:$p_d_id D_YTD [ expr  [ $redis HMGET DISTRICT:$p_w_id:$p_d_id D_YTD ] + $p_h_amount ]
foreach { p_d_street_1 p_d_street_2 p_d_city p_d_state p_d_zip p_d_name } [ $redis HMGET DISTRICT:$p_w_id:$p_d_id D_STREET_1 D_STREET_2 D_CITY D_STATE D_ZIP D_NAME ]  {}
if { $byname eq 1 } {
set namecnt [ $redis LLEN CUSTOMER_OSTAT_PMT_QUERY:$p_w_id:$p_d_id:$name ]
set cust_last_list [ $redis LRANGE CUSTOMER_OSTAT_PMT_QUERY:$p_w_id:$p_d_id:$name 0 $namecnt ] 
if { [ expr {$namecnt % 2} ] eq 1 } {
incr namecnt
	}
foreach cust_id $cust_last_list {
set first_name [ $redis HMGET CUSTOMER:$p_w_id:$p_d_id:$cust_id C_FIRST ]
lappend cust_first_list $first_name
set first_to_id($first_name) $cust_id
	}
set cust_first_list [ lsort $cust_first_list ]
set id_to_query $first_to_id([ lindex $cust_first_list [ expr ($namecnt/2)-1 ] ])
foreach { p_c_first p_c_middle p_c_id p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since } [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$id_to_query C_FIRST C_MIDDLE C_ID C_STREET_1 C_STREET_2 C_CITY C_STATE C_ZIP C_PHONE C_CREDIT C_CREDIT_LIM C_DISCOUNT C_BALANCE C_SINCE ] {}
set p_c_last $name
	} else {
foreach { p_c_first p_c_middle p_c_last p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since } [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_FIRST C_MIDDLE C_LAST C_STREET_1 C_STREET_2 C_CITY C_STATE C_ZIP C_PHONE C_CREDIT C_CREDIT_LIM C_DISCOUNT C_BALANCE C_SINCE ] {}
	}
set p_c_balance [ expr $p_c_balance + $p_h_amount ]
set p_c_data [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_DATA ] 
set tstamp [ gettimestamp ]
if { $p_c_credit eq "BC" } {
set h_data "$p_w_name $p_d_name"
set p_c_new_data "$p_c_id $p_c_d_id $p_c_w_id $p_d_id $p_w_id $p_h_amount $tstamp $h_data"
set p_c_new_data [ string range "$p_c_new_data $p_c_data" 0 [ expr 500 - [ string length $p_c_new_data ] ] ]
$redis HMSET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_BALANCE $p_c_balance C_DATA $p_c_new_data
	} else {
$redis HMSET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_BALANCE $p_c_balance
set h_data "$p_w_name $p_d_name"
	}
$redis HMSET HISTORY:$p_c_w_id:$p_c_d_id:$p_c_id:$tstamp H_C_ID $p_c_id H_C_D_ID $p_c_d_id H_C_W_ID $p_c_w_id H_W_ID $p_w_id H_D_ID $p_d_id H_DATE $tstamp H_AMOUNT $p_h_amount H_DATA $h_data
	;
	}

#ORDER_STATUS
proc ostat { redis w_id RAISEERROR } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if { $byname eq 1 } {
set namecnt [ $redis LLEN CUSTOMER_OSTAT_PMT_QUERY:$w_id:$d_id:$name ]
set cust_last_list [ $redis LRANGE CUSTOMER_OSTAT_PMT_QUERY:$w_id:$d_id:$name 0 $namecnt ] 
if { [ expr {$namecnt % 2} ] eq 1 } {
incr namecnt
	}
foreach cust_id $cust_last_list {
set first_name [ $redis HMGET CUSTOMER:$w_id:$d_id:$cust_id C_FIRST ]
lappend cust_first_list $first_name
set first_to_id($first_name) $cust_id
	}
set cust_first_list [ lsort $cust_first_list ]
set id_to_query $first_to_id([ lindex $cust_first_list [ expr ($namecnt/2)-1 ] ])
foreach { os_c_balance os_c_first os_c_middle os_c_id } [ $redis HMGET CUSTOMER:$w_id:$d_id:$id_to_query C_BALANCE C_FIRST C_MIDDLE C_ID ] {}
set os_c_last $name
	} else {
foreach { os_c_balance os_c_first os_c_middle os_c_last } [ $redis HMGET CUSTOMER:$w_id:$d_id:$c_id C_BALANCE C_FIRST C_MIDDLE C_LAST ] {}
set os_c_id $c_id
	}
set o_id_len [ $redis LLEN ORDERS_OSTAT_QUERY:$w_id:$d_id:$c_id ]
if { $o_id_len eq 0 } {
#puts "No orders for customer"
	} else {
set o_id_list [ lindex [ lsort [ $redis LRANGE ORDERS_OSTAT_QUERY:$w_id:$d_id:$c_id 0 $o_id_len ] ] end ]
foreach { o_id o_carrier_id o_entry_d } [ $redis HMGET ORDERS:$w_id:$d_id:$o_id_list O_ID O_CARRIER_ID O_ENTRY_D ] {}
set os_cline_len [ $redis LLEN ORDER_LINE_NUMBERS:$w_id:$d_id:$o_id ]
set os_cline_list [ lsort -integer [ $redis LRANGE ORDER_LINE_NUMBERS:$w_id:$d_id:$o_id 0 $os_cline_len ] ]
set i 0
foreach ol [ split $os_cline_list ] { 
foreach { ol_i_id ol_supply_w_id ol_quantity ol_amount ol_delivery_d } [ $redis HMGET ORDER_LINE:$w_id:$d_id:$o_id:$ol OL_I_ID OL_SUPPLY_W_ID OL_QUANTITY OL_AMOUNT OL_DELIVERY_D ] {}
set os_ol_i_id($i) $ol_i_id
set os_ol_supply_w_id($i) $ol_supply_w_id
set os_ol_quantity($i) $ol_quantity
set os_ol_amount($i) $ol_amount
set os_ol_delivery_d($i) $ol_delivery_d
incr i
#puts "Item Status $i:$ol_i_id $ol_supply_w_id $ol_quantity $ol_amount $ol_delivery_d"
	}
	;
  }
}
#DELIVERY
proc delivery { redis w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
for {set loop_counter 1} {$loop_counter <= 10} {incr loop_counter} {
set d_d_id $loop_counter 
set d_no_o_id [ $redis LPOP NEW_ORDER_IDS:$w_id:$d_d_id ]
$redis DEL NEW_ORDER:$w_id:$d_d_id:$d_no_o_id
set d_c_id [ $redis HMGET ORDERS:$w_id:$d_d_id:$d_no_o_id O_C_ID ]
$redis HMSET ORDERS:$w_id:$d_d_id:$d_no_o_id O_CARRIER_ID $carrier_id
set ol_deliv_len [ $redis LLEN ORDER_LINE_NUMBERS:$w_id:$d_d_id:$d_no_o_id ]
set ol_deliv_list [ $redis LRANGE ORDER_LINE_NUMBERS:$w_id:$d_d_id:$d_no_o_id 0 $ol_deliv_len ] 
set d_ol_total 0
foreach ol [ split $ol_deliv_list ] { 
set d_ol_total [expr $d_ol_total + [ $redis HMGET ORDER_LINE:$w_id:$d_d_id:$d_no_o_id:$ol OL_AMOUNT ]]
$redis HMSET ORDER_LINE:$w_id:$d_d_id:$d_no_o_id:$ol OL_DELIVERY_D $date
	}
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE $d_ol_total 
$redis HMSET CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE [ expr [ $redis HMGET CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE ] + $d_ol_total ]
	}
	;
}
#STOCK LEVEL
proc slev { redis w_id stock_level_d_id RAISEERROR } {
set stock_level 0
set threshold [ RandomNumber 10 20 ]
set st_o_id [ $redis HMGET DISTRICT:$w_id:$stock_level_d_id D_NEXT_O_ID ]
set item_id_list [ $redis ZRANGE ORDER_LINE_SLEV_QUERY:$w_id:$stock_level_d_id [ expr $st_o_id - 19 ] $st_o_id ]
foreach item_id [ split [ lsort -unique $item_id_list ] ] { 
	if { [ $redis HMGET STOCK:$w_id:$item_id S_QUANTITY ] < $threshold } { incr stock_level } }
	;
	}

#RUN TPC-C
if {[catch {set redis [redis $host $port ]}]} {
puts stderr "Error, the connection to $host:$port could not be established"
return
 } else {
if {[ $redis ping ] eq "PONG" }  {
puts "Connection made to Redis at $host:$port"
if { [ string is integer -strict $namespace ]} {
puts "Selecting Namespace $namespace"
$redis SELECT $namespace
	}
	} else {
puts stderr "Error, No response from redis server at $host:$port"
	}
    }
set w_id_input [ $redis GET COUNT_WARE ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ $redis GET DIST_PER_WARE ]
set stock_level_d_id [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword $redis $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment $redis $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery $redis $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev $redis $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat $redis $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	      }
	}
$redis QUIT
     }
}}
} else {
#ASYNCHRONOUS TIMED SCRIPT
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# Redis Library
set total_iterations $redis_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$redis_raiseerror\" ;# Exit script on Redis error (true or false)
set KEYANDTHINK \"$redis_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $redis_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $redis_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set host \"$redis_host\" ;# Address of the server hosting Redis 
set port \"$redis_port\" ;# Port of the Redis Server, defaults to 6379
set namespace \"$redis_namespace\" ;# Namespace containing the TPC Schema
set async_client $redis_async_client;# Number of asynchronous clients per Vuser
set async_verbose $redis_async_verbose;# Report activity of asynchronous clients
set async_delay $redis_async_delay;# Delay in ms between logins of asynchronous clients
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }
if [catch {package require promise } message] { error "Failed to load promise package for asynchronous clients" }

if { [ chk_thread ] eq "FALSE" } {
error "Redis Timed Script must be run in Thread Enabled Interpreter"
}
set rema [ lassign [ findvuposition ] myposition totalvirtualusers ]
switch $myposition {
1 { 
if { $mode eq "Local" || $mode eq "Primary" } {
if {[catch {set redis [redis $host $port ]}]} {
puts stderr "Error, the connection to $host:$port could not be established"
return
 } else {
if {[ $redis ping ] eq "PONG" }  {
puts "Connection made to Redis at $host:$port"
if { [ string is integer -strict $namespace ]} {
puts "Selecting Namespace $namespace"
$redis SELECT $namespace
	}
	} else {
puts stderr "Error, No response from redis server at $host:$port"
	}
    }
set ramptime 0
puts "Beginning rampup time of $rampup minutes"
set rampup [ expr $rampup*60000 ]
while {$ramptime != $rampup} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set ramptime [ expr $ramptime+6000 ]
if { ![ expr {$ramptime % 60000} ] } {
puts "Rampup [ expr $ramptime / 60000 ] minutes complete ..."
	}
}
if { [ tsv::get application abort ] } { break }
puts "Rampup complete, Taking start Transaction Count."
set info_list [ split [ $redis info ] "\n" ] 
foreach line $info_list { 
    if {[string match {total_commands_processed:*} $line]} {
regexp {\:([0-9]+)} $line all start_trans
	}
}
set COUNT_WARE [ $redis GET COUNT_WARE ]
set DIST_PER_WARE [ $redis GET DIST_PER_WARE ]
set start_nopm 0
for {set w_id 1} {$w_id <= $COUNT_WARE } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
incr start_nopm [ $redis HMGET DISTRICT:$w_id:$d_id D_NEXT_O_ID ]
	}
}
puts "Timing test period of $duration in minutes"
set testtime 0
set durmin $duration
set duration [ expr $duration*60000 ]
while {$testtime != $duration} {
if { [ tsv::get application abort ] } { break } else { after 6000 }
set testtime [ expr $testtime+6000 ]
if { ![ expr {$testtime % 60000} ] } {
puts -nonewline  "[ expr $testtime / 60000 ]  ...,"
	}
}
if { [ tsv::get application abort ] } { break }
puts "Test complete, Taking end Transaction Count."
set info_list [ split [ $redis info ] "\n" ] 
foreach line $info_list { 
    if {[string match {total_commands_processed:*} $line]} {
regexp {\:([0-9]+)} $line all end_trans
	}
}
set end_nopm 0
for {set w_id 1} {$w_id <= $COUNT_WARE } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
incr end_nopm [ $redis HMGET DISTRICT:$w_id:$d_id D_NEXT_O_ID ]
	}
}
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "[ expr $totalvirtualusers - 1 ] VU \* $async_client AC \= [ expr ($totalvirtualusers - 1) * $async_client ] Active Sessions configured"
puts [ testresult $nopm $tpm Redis ]
tsv::set application abort 1
if { $mode eq "Primary" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
		} else {
puts "Operating in Replica Mode, No Snapshots taken..."
		}
$redis QUIT
	}
default {
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#NEW ORDER
proc neword { redis no_w_id w_id_input RAISEERROR clientname } {
set no_d_id [ RandomNumber 1 10 ]
set no_c_id [ RandomNumber 1 3000 ]
set ol_cnt [ RandomNumber 5 15 ]
set date [ gettimestamp ]
set no_o_all_local 0
foreach { no_c_discount no_c_last no_c_credit } [ $redis HMGET CUSTOMER:$no_w_id:$no_d_id:$no_c_id C_DISCOUNT C_LAST C_CREDIT ] {}
set no_w_tax [ $redis HMGET WAREHOUSE:$no_w_id W_TAX ]
set no_d_tax [ $redis HMGET DISTRICT:$no_w_id:$no_d_id D_TAX ]
set d_next_o_id [ $redis HINCRBY DISTRICT:$no_w_id:$no_d_id D_NEXT_O_ID 1 ]
set o_id $d_next_o_id
$redis HMSET ORDERS:$no_w_id:$no_d_id:$o_id O_ID $o_id O_C_ID $no_c_id O_D_ID $no_d_id O_W_ID $no_w_id O_ENTRY_D $date O_CARRIER_ID "" O_OL_CNT $ol_cnt NO_ALL_LOCAL $no_o_all_local
$redis LPUSH ORDERS_OSTAT_QUERY:$no_w_id:$no_d_id:$no_c_id $o_id
$redis HMSET NEW_ORDER:$no_w_id:$no_d_id:$o_id NO_O_ID $o_id NO_D_ID $no_d_id NO_W_ID $no_w_id
$redis LPUSH NEW_ORDER_IDS:$no_w_id:$no_d_id $o_id
set rbk [ RandomNumber 1 100 ]  
for {set loop_counter 1} {$loop_counter <= $ol_cnt} {incr loop_counter} {
if { ($loop_counter eq $ol_cnt) && ($rbk eq 1) } {
#No Rollback Support in Redis
set no_ol_i_id 100001
#puts "New Order:Invalid Item id:$no_ol_i_id (intentional error)" 
return
	     } else {
set no_ol_i_id [ RandomNumber 1 100000 ]  
		}
set x [ RandomNumber 1 100 ]  
if { $x > 1 } {
set no_ol_supply_w_id $no_w_id
	} else {
set no_ol_supply_w_id $no_w_id
set no_o_all_local 0
while { ($no_ol_supply_w_id eq $no_w_id) && ($w_id_input != 1) } {
set no_ol_supply_w_id [ RandomNumber 1 $w_id_input ]  
		}
	}
set no_ol_quantity [ RandomNumber 1 10 ]  
foreach { no_i_name no_i_price no_i_data } [ $redis HMGET ITEM:$no_ol_i_id I_NAME I_PRICE I_DATA ] {}
foreach { no_s_quantity no_s_data no_s_dist_01 no_s_dist_02 no_s_dist_03 no_s_dist_04 no_s_dist_05 no_s_dist_06 no_s_dist_07 no_s_dist_08 no_s_dist_09 no_s_dist_10 } [ $redis HMGET STOCK:$no_ol_supply_w_id:$no_ol_i_id S_QUANTITY S_DATA S_DIST_01 S_DIST_02 S_DIST_03 S_DIST_04 S_DIST_05 S_DIST_06 S_DIST_07 S_DIST_08 S_DIST_09 S_DIST_10 ] {}
if { $no_s_quantity > $no_ol_quantity } {
set no_s_quantity [ expr $no_s_quantity - $no_ol_quantity ]
	} else {
set no_s_quantity [ expr ($no_s_quantity - $no_ol_quantity) + 91 ]
	}
$redis HMSET STOCK:$no_ol_supply_w_id:$no_ol_i_id  S_QUANTITY $no_s_quantity 
set no_ol_amount [ expr $no_ol_quantity * $no_i_price * ( 1 + $no_w_tax + $no_d_tax ) * ( 1 - $no_c_discount ) ]
switch $no_d_id {
1 { set no_ol_dist_info $no_s_dist_01 }
2 { set no_ol_dist_info $no_s_dist_02 }
3 { set no_ol_dist_info $no_s_dist_03 }
4 { set no_ol_dist_info $no_s_dist_04 }
5 { set no_ol_dist_info $no_s_dist_05 }
6 { set no_ol_dist_info $no_s_dist_06 }
7 { set no_ol_dist_info $no_s_dist_07 }
8 { set no_ol_dist_info $no_s_dist_08 }
9 { set no_ol_dist_info $no_s_dist_09 }
10 { set no_ol_dist_info $no_s_dist_10 }
	     }
$redis HMSET ORDER_LINE:$no_w_id:$no_d_id:$o_id:$loop_counter OL_O_ID $o_id OL_D_ID $no_d_id OL_W_ID $no_w_id OL_NUMBER $loop_counter OL_I_ID $no_ol_i_id OL_SUPPLY_W_ID $no_ol_supply_w_id OL_QUANTITY $no_ol_quantity OL_AMOUNT $no_ol_amount OL_DIST_INFO $no_ol_dist_info OL_DELIVERY_D ""
$redis LPUSH ORDER_LINE_NUMBERS:$no_w_id:$no_d_id:$o_id $loop_counter 
$redis ZADD ORDER_LINE_SLEV_QUERY:$no_w_id:$no_d_id $o_id $no_ol_i_id
	}
	;
   }

#PAYMENT
proc payment { redis p_w_id w_id_input RAISEERROR clientname } {
#2.5.1.1 The home warehouse id remains the same for each terminal
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set p_d_id [ RandomNumber 1 10 ]
#2.5.1.2 customer selected 60% of time by name and 40% of time by number
set x [ RandomNumber 1 100 ]
set y [ RandomNumber 1 100 ]
if { $x <= 85 } {
set p_c_d_id $p_d_id
set p_c_w_id $p_w_id
} else {
#use a remote warehouse
set p_c_d_id [ RandomNumber 1 10 ]
set p_c_w_id [ RandomNumber 1 $w_id_input ]
while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
set p_c_w_id [ RandomNumber 1  $w_id_input ]
	}
}
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set p_c_id [ RandomNumber 1 3000 ]
if { $y <= 60 } {
#use customer name
#C_LAST is generated
set byname 1
 } else {
#use customer number
set byname 0
set name {}
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT WAREHOUSE:$p_w_id W_YTD $p_h_amount
$redis HMSET WAREHOUSE:$p_w_id W_YTD [ expr  [ $redis HMGET WAREHOUSE:$p_w_id W_YTD ] + $p_h_amount ]
foreach { p_w_street_1 p_w_street_2 p_w_city p_w_state p_w_zip p_w_name } [ $redis HMGET WAREHOUSE:$p_w_id W_STREET_1 W_STREET_2 W_CITY W_STATE W_ZIP W_NAME ] {}
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT DISTRICT:$p_w_id:$p_d_id D_YTD $p_h_amount
$redis HMSET DISTRICT:$p_w_id:$p_d_id D_YTD [ expr  [ $redis HMGET DISTRICT:$p_w_id:$p_d_id D_YTD ] + $p_h_amount ]
foreach { p_d_street_1 p_d_street_2 p_d_city p_d_state p_d_zip p_d_name } [ $redis HMGET DISTRICT:$p_w_id:$p_d_id D_STREET_1 D_STREET_2 D_CITY D_STATE D_ZIP D_NAME ]  {}
if { $byname eq 1 } {
set namecnt [ $redis LLEN CUSTOMER_OSTAT_PMT_QUERY:$p_w_id:$p_d_id:$name ]
set cust_last_list [ $redis LRANGE CUSTOMER_OSTAT_PMT_QUERY:$p_w_id:$p_d_id:$name 0 $namecnt ] 
if { [ expr {$namecnt % 2} ] eq 1 } {
incr namecnt
	}
foreach cust_id $cust_last_list {
set first_name [ $redis HMGET CUSTOMER:$p_w_id:$p_d_id:$cust_id C_FIRST ]
lappend cust_first_list $first_name
set first_to_id($first_name) $cust_id
	}
set cust_first_list [ lsort $cust_first_list ]
set id_to_query $first_to_id([ lindex $cust_first_list [ expr ($namecnt/2)-1 ] ])
foreach { p_c_first p_c_middle p_c_id p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since } [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$id_to_query C_FIRST C_MIDDLE C_ID C_STREET_1 C_STREET_2 C_CITY C_STATE C_ZIP C_PHONE C_CREDIT C_CREDIT_LIM C_DISCOUNT C_BALANCE C_SINCE ] {}
set p_c_last $name
	} else {
foreach { p_c_first p_c_middle p_c_last p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since } [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_FIRST C_MIDDLE C_LAST C_STREET_1 C_STREET_2 C_CITY C_STATE C_ZIP C_PHONE C_CREDIT C_CREDIT_LIM C_DISCOUNT C_BALANCE C_SINCE ] {}
	}
set p_c_balance [ expr $p_c_balance + $p_h_amount ]
set p_c_data [ $redis HMGET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_DATA ] 
set tstamp [ gettimestamp ]
if { $p_c_credit eq "BC" } {
set h_data "$p_w_name $p_d_name"
set p_c_new_data "$p_c_id $p_c_d_id $p_c_w_id $p_d_id $p_w_id $p_h_amount $tstamp $h_data"
set p_c_new_data [ string range "$p_c_new_data $p_c_data" 0 [ expr 500 - [ string length $p_c_new_data ] ] ]
$redis HMSET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_BALANCE $p_c_balance C_DATA $p_c_new_data
	} else {
$redis HMSET CUSTOMER:$p_c_w_id:$p_c_d_id:$p_c_id C_BALANCE $p_c_balance
set h_data "$p_w_name $p_d_name"
	}
$redis HMSET HISTORY:$p_c_w_id:$p_c_d_id:$p_c_id:$tstamp H_C_ID $p_c_id H_C_D_ID $p_c_d_id H_C_W_ID $p_c_w_id H_W_ID $p_w_id H_D_ID $p_d_id H_DATE $tstamp H_AMOUNT $p_h_amount H_DATA $h_data
	;
	}

#ORDER_STATUS
proc ostat { redis w_id RAISEERROR clientname } {
#2.5.1.1 select district id randomly from home warehouse where d_w_id = d_id
set d_id [ RandomNumber 1 10 ]
set nrnd [ NURand 255 0 999 123 ]
set name [ randname $nrnd ]
set c_id [ RandomNumber 1 3000 ]
set y [ RandomNumber 1 100 ]
if { $y <= 60 } {
set byname 1
 } else {
set byname 0
set name {}
}
if { $byname eq 1 } {
set namecnt [ $redis LLEN CUSTOMER_OSTAT_PMT_QUERY:$w_id:$d_id:$name ]
set cust_last_list [ $redis LRANGE CUSTOMER_OSTAT_PMT_QUERY:$w_id:$d_id:$name 0 $namecnt ] 
if { [ expr {$namecnt % 2} ] eq 1 } {
incr namecnt
	}
foreach cust_id $cust_last_list {
set first_name [ $redis HMGET CUSTOMER:$w_id:$d_id:$cust_id C_FIRST ]
lappend cust_first_list $first_name
set first_to_id($first_name) $cust_id
	}
set cust_first_list [ lsort $cust_first_list ]
set id_to_query $first_to_id([ lindex $cust_first_list [ expr ($namecnt/2)-1 ] ])
foreach { os_c_balance os_c_first os_c_middle os_c_id } [ $redis HMGET CUSTOMER:$w_id:$d_id:$id_to_query C_BALANCE C_FIRST C_MIDDLE C_ID ] {}
set os_c_last $name
	} else {
foreach { os_c_balance os_c_first os_c_middle os_c_last } [ $redis HMGET CUSTOMER:$w_id:$d_id:$c_id C_BALANCE C_FIRST C_MIDDLE C_LAST ] {}
set os_c_id $c_id
	}
set o_id_len [ $redis LLEN ORDERS_OSTAT_QUERY:$w_id:$d_id:$c_id ]
if { $o_id_len eq 0 } {
#puts "No orders for customer"
	} else {
set o_id_list [ lindex [ lsort [ $redis LRANGE ORDERS_OSTAT_QUERY:$w_id:$d_id:$c_id 0 $o_id_len ] ] end ]
foreach { o_id o_carrier_id o_entry_d } [ $redis HMGET ORDERS:$w_id:$d_id:$o_id_list O_ID O_CARRIER_ID O_ENTRY_D ] {}
set os_cline_len [ $redis LLEN ORDER_LINE_NUMBERS:$w_id:$d_id:$o_id ]
set os_cline_list [ lsort -integer [ $redis LRANGE ORDER_LINE_NUMBERS:$w_id:$d_id:$o_id 0 $os_cline_len ] ]
set i 0
foreach ol [ split $os_cline_list ] { 
foreach { ol_i_id ol_supply_w_id ol_quantity ol_amount ol_delivery_d } [ $redis HMGET ORDER_LINE:$w_id:$d_id:$o_id:$ol OL_I_ID OL_SUPPLY_W_ID OL_QUANTITY OL_AMOUNT OL_DELIVERY_D ] {}
set os_ol_i_id($i) $ol_i_id
set os_ol_supply_w_id($i) $ol_supply_w_id
set os_ol_quantity($i) $ol_quantity
set os_ol_amount($i) $ol_amount
set os_ol_delivery_d($i) $ol_delivery_d
incr i
#puts "Item Status $i:$ol_i_id $ol_supply_w_id $ol_quantity $ol_amount $ol_delivery_d"
	}
	;
  }
}
#DELIVERY
proc delivery { redis w_id RAISEERROR clientname } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
for {set loop_counter 1} {$loop_counter <= 10} {incr loop_counter} {
set d_d_id $loop_counter 
set d_no_o_id [ $redis LPOP NEW_ORDER_IDS:$w_id:$d_d_id ]
$redis DEL NEW_ORDER:$w_id:$d_d_id:$d_no_o_id
set d_c_id [ $redis HMGET ORDERS:$w_id:$d_d_id:$d_no_o_id O_C_ID ]
$redis HMSET ORDERS:$w_id:$d_d_id:$d_no_o_id O_CARRIER_ID $carrier_id
set ol_deliv_len [ $redis LLEN ORDER_LINE_NUMBERS:$w_id:$d_d_id:$d_no_o_id ]
set ol_deliv_list [ $redis LRANGE ORDER_LINE_NUMBERS:$w_id:$d_d_id:$d_no_o_id 0 $ol_deliv_len ] 
set d_ol_total 0
foreach ol [ split $ol_deliv_list ] { 
set d_ol_total [expr $d_ol_total + [ $redis HMGET ORDER_LINE:$w_id:$d_d_id:$d_no_o_id:$ol OL_AMOUNT ]]
$redis HMSET ORDER_LINE:$w_id:$d_d_id:$d_no_o_id:$ol OL_DELIVERY_D $date
	}
#From Redis 2.6 can do the following
#$redis HINCRBYFLOAT CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE $d_ol_total 
$redis HMSET CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE [ expr [ $redis HMGET CUSTOMER:$w_id:$d_d_id:$d_c_id C_BALANCE ] + $d_ol_total ]
	}
	;
}
#STOCK LEVEL
proc slev { redis w_id stock_level_d_id RAISEERROR clientname } {
set stock_level 0
set threshold [ RandomNumber 10 20 ]
set st_o_id [ $redis HMGET DISTRICT:$w_id:$stock_level_d_id D_NEXT_O_ID ]
set item_id_list [ $redis ZRANGE ORDER_LINE_SLEV_QUERY:$w_id:$stock_level_d_id [ expr $st_o_id - 19 ] $st_o_id ]
foreach item_id [ split [ lsort -unique $item_id_list ] ] { 
	if { [ $redis HMGET STOCK:$w_id:$item_id S_QUANTITY ] < $threshold } { incr stock_level } }
	;
	}

#RUN TPC-C
promise::async simulate_client { clientname total_iterations host port namespace RAISEERROR KEYANDTHINK async_verbose async_delay } {
set acno [ expr [ string trimleft [ lindex [ split $clientname ":" ] 1 ] ac ] * $async_delay ]
if { $async_verbose } { puts "Delaying login of $clientname for $acno ms" }
async_time $acno
if {  [ tsv::get application abort ]  } { return "$clientname:abort before login" }
if { $async_verbose } { puts "Logging in $clientname" }
if {[catch {set redis [redis $host $port ]} message]} {
if { $RAISEERROR } {
puts "$clientname:login failed:$message"
return "$clientname:login failed:$message"
        }
 } else {
if {[ $redis ping ] eq "PONG" }  {
if { $async_verbose } { puts "Connection made to Redis at $clientname:$host:$port" }
if { [ string is integer -strict $namespace ]} {
if { $async_verbose } { puts "Selecting Namespace $clientname:$namespace" }
$redis SELECT $namespace
	}
	} else {
puts "$clientname:No response from redis server at $host:$port"
return "$clientname:No response from redis server at $host:$port"
	}
    }
set w_id_input [ $redis GET COUNT_WARE ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ $redis GET DIST_PER_WARE ]
set stock_level_d_id [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:neword" }
if { $KEYANDTHINK } { async_keytime 18  $clientname neword $async_verbose }
neword $redis $w_id $w_id_input $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 12 $clientname neword $async_verbose }
} elseif {$choice <= 20} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:payment" }
if { $KEYANDTHINK } { async_keytime 3 $clientname payment $async_verbose }
payment $redis $w_id $w_id_input $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 12 $clientname payment $async_verbose }
} elseif {$choice <= 21} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:delivery" }
if { $KEYANDTHINK } { async_keytime 2 $clientname delivery $async_verbose }
delivery $redis $w_id $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 10 $clientname delivery $async_verbose }
} elseif {$choice <= 22} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:slev" }
if { $KEYANDTHINK } { async_keytime 2 $clientname slev $async_verbose }
slev $redis $w_id $stock_level_d_id $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 5 $clientname slev $async_verbose }
} elseif {$choice <= 23} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:ostat" }
if { $KEYANDTHINK } { async_keytime 2 $clientname ostat $async_verbose }
ostat $redis $w_id $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 5 $clientname ostat $async_verbose }
        }
  }
$redis QUIT
if { $async_verbose } { puts "$clientname:complete" }
return $clientname:complete
          }
for {set ac 1} {$ac <= $async_client} {incr ac} {
set clientdesc "vuser$myposition:ac$ac"
lappend clientlist $clientdesc
lappend clients [simulate_client $clientdesc $total_iterations $host $port $namespace $RAISEERROR $KEYANDTHINK $async_verbose $async_delay]
                }
puts "Started asynchronous clients:$clientlist"
set acprom [ promise::eventloop [ promise::all $clients ] ]
puts "All asynchronous clients complete"
if { $async_verbose } {
foreach client $acprom { puts $client }
      }
   }
}}
}
}
