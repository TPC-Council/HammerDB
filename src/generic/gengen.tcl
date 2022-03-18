proc gendata_tpcc {} {
global rdbms gen_count_ware gen_directory gen_num_vu num_vu maxvuser virtual_users lprefix suppo ntimes threadscreated _ED
if {  ![ info exists gen_count_ware ] } { set gen_count_ware "1" }
if {  ![ info exists gen_directory ] } { set gen_directory [ findtempdir ] }
if {  ![ info exists gen_num_vu ] } { set gen_num_vu "1" }
if {  ![ info exists rdbms ] } { set rdbms "Oracle" }
if {  [ info exists lprefix ] } { ; } else { set lprefix "load" }
if {  [ info exists virtual_users ] } { ; } else { set virtual_users 1 }

switch $rdbms {
        "Oracle" { set db "oracle" }
        "MSSQLServer" { set db "mssql" }
        "Db2" { set db "db2" }
        "MySQL" { set db "mysql" }
        "MariaDB" { set db "maria" }
        "PostgreSQL" { set db "pg" }
        "Redis" { set db "redis" }
        "Trafodion" { set db "traf" }
	}
set install_message "Ready to generate the data for a $gen_count_ware Warehouse $rdbms TPROC-C schema\nin directory $gen_directory ?" 
if {[ tk_messageBox -title "Generate Data" -icon question -message $install_message -type yesno ] == yes} { 
if { $gen_num_vu eq 1 || $gen_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $gen_num_vu + 1 ]
}
set lprefix "load"
set virtual_users $maxvuser
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPROC-C generation"
if { [catch {load_virtual} message]} {
puts "Failed to create thread(s) for data generation: $message"
	return 1
	}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#!/usr/local/bin/tclsh8.6
#LOAD MODULES
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

proc set_filename { dirtowrite filename myposition } {
if {[file isdirectory $dirtowrite ] && [file writable $dirtowrite]} {
set filename [ concat $filename\_$myposition.tbl ] 
set filenameb [ file join $dirtowrite $filename ]
 if {[file exists $filenameb]} {
     error "File $filenameb already exists"
	}
 if {[catch {set filetowrite [open $filenameb w ]}]} {
     error "Could not open file to write $filenameb"
                } else {
 if {[catch {fconfigure $filetowrite -buffering full}]} {
     error "Could not set buffering on $filetowrite"
                }
 if {[catch {fconfigure $filetowrite -buffersize 1000000}]} {
     error "Could not set buffersize on $filetowrite"
                }
puts "Opened File $filenameb"
return $filetowrite
	}
      } else {
error "Directory $dirtowrite is not a writable location"
	}
}

proc gettimestamp { db } {
switch $db {
oracle {
return [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
}
default {
return [ clock format [ clock seconds ] -format "%Y-%m-%d %H:%M:%S" ]
		}
	}
}

proc Customer { file1 file2 d_id w_id CUST_PER_DIST db } {
#file1 customer file2 history
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
set chalen [ llength $globArray ]
set c_d_id $d_id
set c_w_id $w_id
set c_middle "OE"
set c_balance -10.0
set c_credit_lim 50000
set h_amount 10.0
if { $db eq "mssql" } { 
set statement {_puts $file1 $c_id|$c_d_id|$c_w_id|$c_discount|$c_credit_lim|$c_last|$c_first|$c_credit|$c_balance|10.0|1|0|[ lindex $c_add 0 ]|[ lindex $c_add 1 ]|[ lindex $c_add 2 ]|[ lindex $c_add 3 ]|[ lindex $c_add 4 ]|$c_phone|[ gettimestamp $db ]|$c_middle|$c_data}
	} else {
set statement {_puts $file1 $c_id|$c_d_id|$c_w_id|$c_first|$c_middle|$c_last|[ lindex $c_add 0 ]|[ lindex $c_add 1 ]|[ lindex $c_add 2 ]|[ lindex $c_add 3 ]|[ lindex $c_add 4 ]|$c_phone|[ gettimestamp $db ]|$c_credit|$c_credit_lim|$c_discount|$c_balance|10.0|1|0|$c_data}
	}
set statement2 {_puts $file2 $c_id|$c_d_id|$c_w_id|$c_d_id|$c_w_id|[ gettimestamp $db ]|$h_amount|$h_data}
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
eval $statement
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
eval $statement2
	}
return
}

proc Orders { file1 file2 file3 d_id w_id MAXITEMS ORD_PER_DIST db } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
#file1 Orders file2 New_Order file3 Order_Line
#Note field o_carrier_id in Orders is NULL
if { $db eq "mssql" } {
set statement {_puts $file1 $o_id|$o_d_id|$o_w_id|$o_c_id||$o_ol_cnt|1|[ gettimestamp $db ]}
set statement1 {_puts $file2 $o_id|$o_d_id|$o_w_id}
set statement2 {_puts $file1 $o_id|$o_d_id|$o_w_id|$o_c_id|$o_carrier_id|$o_ol_cnt|1|[ gettimestamp $db ]}
	} else {	
set statement {_puts $file1 $o_id|$o_w_id|$o_d_id|$o_c_id||$o_ol_cnt|1|[ gettimestamp $db ]}
set statement1 {_puts $file2 $o_w_id|$o_d_id|$o_id}
set statement2 {_puts $file1 $o_id|$o_w_id|$o_d_id|$o_c_id|$o_carrier_id|$o_ol_cnt|1|[ gettimestamp $db ]}
}
#Note field ol_delivery_d in order_line is NULL
set statement3 {_puts $file3 $o_id|$o_d_id|$o_w_id|$ol|$ol_i_id||$ol_amount|$ol_supply_w_id|$ol_quantity|$ol_dist_info}
#Note field ol_delivery_d in order_line is not NULL
set statement4 {_puts $file3 $o_id|$o_d_id|$o_w_id|$ol|$ol_i_id|[ gettimestamp $db ]|$ol_amount|$ol_supply_w_id|$ol_quantity|$ol_dist_info}
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
eval $statement
set e "no1"
eval $statement1
  } else {
  set e "o3"
eval $statement2
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
eval $statement3
   } else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
eval $statement4
			}
		}
 if { ![ expr {$o_id % 500000} ] } {
	puts "...$o_id"
			}
		}
	return;
	}

proc Stock { file w_id MAXITEMS db } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Generating Stock Wid=$w_id"
if { $db eq "mssql" } {
set statement {_puts $file $s_i_id|$s_w_id|$s_quantity|0|0|0|$s_data|$s_dist_01|$s_dist_02|$s_dist_03|$s_dist_04|$s_dist_05|$s_dist_06|$s_dist_07|$s_dist_08|$s_dist_09|$s_dist_10}
	} else {
if { $db eq "db2" } {
set statement {_puts $file 0|$s_quantity|0|0|$s_data|$s_dist_01|$s_dist_02|$s_dist_03|$s_dist_04|$s_dist_05|$s_dist_06|$s_dist_07|$s_dist_08|$s_dist_09|$s_dist_10|$s_i_id|$s_w_id}
} else {
set statement {_puts $file $s_i_id|$s_w_id|$s_quantity|$s_dist_01|$s_dist_02|$s_dist_03|$s_dist_04|$s_dist_05|$s_dist_06|$s_dist_07|$s_dist_08|$s_dist_09|$s_dist_10|0|0|0|$s_data}
}}
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
eval $statement
      if { ![ expr {$s_i_id % 500000} ] } {
	puts "Generating Stock - $s_i_id"
			}
	}
	puts "Stock done"
	return
}

proc LoadItems { file MAXITEMS db } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
if { $db eq "mssql" } {
set statement {_puts $file $i_id|$i_name|$i_price|$i_data|$i_im_id}
	} else {
if { $db eq "db2" } {
set statement {_puts $file $i_name|$i_price|$i_data|$i_im_id|$i_id}
	} else {
set statement {_puts $file $i_id|$i_im_id|$i_name|$i_price|$i_data}
	}
 }
puts "Generating Item"
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
eval $statement
       if { ![ expr {$i_id % 100000} ] } {
	puts "Generating Items - $i_id"
		}
	}
	puts "Item done"
	return
}

proc District { file w_id DIST_PER_WARE db } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Generating District"
if { $db eq "mssql" } {
#Note additional field for District for paddinga remove last | for original
set statement {_puts $file $d_id|$d_w_id|$d_ytd|$d_next_o_id|$d_tax|$d_name|[ lindex $d_add 0 ]|[ lindex $d_add 1 ]|[ lindex $d_add 2 ]|[ lindex $d_add 3 ]|[ lindex $d_add 4 ]|}
	} else {
if { $db eq "db2" } {
set statement {_puts $file $d_next_o_id|$d_tax|$d_ytd|$d_name|[ lindex $d_add 0 ]|[ lindex $d_add 1 ]|[ lindex $d_add 2 ]|[ lindex $d_add 3 ]|[ lindex $d_add 4 ]|$d_id|$d_w_id}
	} else {
set statement {_puts $file $d_id|$d_w_id|$d_ytd|$d_tax|$d_next_o_id|$d_name|[ lindex $d_add 0 ]|[ lindex $d_add 1 ]|[ lindex $d_add 2 ]|[ lindex $d_add 3 ]|[ lindex $d_add 4 ]}
	}
 }
set d_w_id $w_id
set d_ytd 30000.0
set d_next_o_id 3001
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
eval $statement
	}
	puts "District done"
	return
}

proc LoadWare { file1 file2 file3 ware_start count_ware MAXITEMS DIST_PER_WARE db } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Generating Warehouse"
if { $db eq "mssql" } {
#Note additional field for District for paddinga remove last | for original
set statement {_puts $file1 $w_id|$w_ytd|$w_tax|$w_name|[ lindex $add 0 ]|[ lindex $add 1 ]|[ lindex $add 2 ]|[ lindex $add 3 ]|[ lindex $add 4 ]|}
	} else {
if { $db eq "db2" } {
set statement {_puts $file1 $w_name|[ lindex $add 0 ]|[ lindex $add 1 ]|[ lindex $add 2 ]|[ lindex $add 3 ]|[ lindex $add 4 ]|$w_tax|$w_ytd|$w_id}
	} else {
set statement {_puts $file1 $w_id|$w_ytd|$w_tax|$w_name|[ lindex $add 0 ]|[ lindex $add 1 ]|[ lindex $add 2 ]|[ lindex $add 3 ]|[ lindex $add 4 ]}
	}
  }
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
	eval $statement
	Stock $file2 $w_id $MAXITEMS $db
	District $file3 $w_id $DIST_PER_WARE $db
}}

proc LoadCust { file1 file2 ware_start count_ware CUST_PER_DIST DIST_PER_WARE db } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
puts "Generating Customer for Wid=$w_id"
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer $file1 $file2 $d_id $w_id $CUST_PER_DIST $db
	}
	}
	return
}

proc LoadOrd { file1 file2 file3 ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE db } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
puts "Generating Orders for Wid=$w_id"
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {	
	Orders $file1 $file2 $file3 $d_id $w_id $MAXITEMS $ORD_PER_DIST $db
	}
	}
	puts "Orders Done"
	return
}

proc gen_tpcc { count_ware directory num_vu db } {
set start [ clock seconds ]
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
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
set item_file [ set_filename $directory item 1 ]
LoadItems $item_file $MAXITEMS $db
catch { close $item_file }
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
set item_file [ set_filename $directory item 1 ]
LoadItems $item_file $MAXITEMS $db
catch { flush $item_file ; close $item_file }
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
set remb [ lassign [ findchunk $num_vu $count_ware $myposition ] chunk mystart myend ]
puts "Generating $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set myposition 1
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
if { $myposition > 1 } { set myno [ expr $myposition - 1] } else { set myno $myposition }
foreach f [list ware_file stock_file district_file cust_file hist_file ord_file neword_file ordline_file] t [list warehouse stock district customer history orders new_order order_line] { 
set $f [ set_filename $directory $t $myno ]
	}
LoadWare $ware_file $stock_file $district_file $mystart $myend $MAXITEMS $DIST_PER_WARE $db
close $ware_file; close $stock_file; close $district_file
LoadCust $cust_file $hist_file $mystart $myend $CUST_PER_DIST $DIST_PER_WARE $db
close $cust_file; close $hist_file
LoadOrd $ord_file $neword_file $ordline_file $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE $db
close $ord_file; close $neword_file; close $ordline_file
puts "End:[ clock format [ clock seconds ] ]"
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
	}
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
set end [ clock seconds ]
set wall [ expr ($end - $start)/60 ]
puts "$count_ware WAREHOUSE SCHEMA GENERATED in $wall MINUTES"
return
	}
    }
}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "gen_tpcc $gen_count_ware {$gen_directory} $gen_num_vu $db"
} else { return }
}

proc gendata_tpch {} {
global rdbms gen_scale_fact gen_directory gen_num_vu num_vu maxvuser virtual_users lprefix suppo ntimes threadscreated _ED
if {  ![ info exists gen_scale_fact ] } { set gen_scale_fact "1" }
if {  ![ info exists gen_directory ] } { set gen_directory [ findtempdir ] }
if {  ![ info exists gen_num_vu ] } { set gen_num_vu "1" }
if {  ![ info exists rdbms ] } { set rdbms "Oracle" }
if {  [ info exists lprefix ] } { ; } else { set lprefix "load" }
if {  [ info exists virtual_users ] } { ; } else { set virtual_users 1 }
switch $rdbms {
        "Oracle" { set db "oracle" }
        "MSSQLServer" { set db "mssql" }
        "Db2" { set db "db2" }
        "MySQL" { set db "mysql" }
        "MariaDB" { set db "maria" }
        "PostgreSQL" { set db "pg" }
        "Redis" { set db "redis" }
        "Trafodion" { set db "traf" }
	}
set install_message "Ready to generate the data for a $gen_scale_fact Scale Factor $rdbms TPROC-H schema\nin directory $gen_directory ?" 
if {[ tk_messageBox -title "Generate Data" -icon question -message $install_message -type yesno ] == yes} { 
if { $gen_num_vu eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $gen_num_vu + 1 ]
}
set lprefix "load"
set virtual_users $maxvuser
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPROC-H generation"
if { [catch {load_virtual} message]} {
puts "Failed to create thread(s) for data generation: $message"
	return 1
	}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#!/usr/local/bin/tclsh8.6
#LOAD MODULES
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpchcommon} ] { error "Failed to load tpch common functions" } else { namespace import tpchcommon::* }
	
proc set_filename { dirtowrite filename myposition } {
if {[file isdirectory $dirtowrite ] && [file writable $dirtowrite]} {
set filename [ concat $filename\_$myposition.tbl ] 
set filenameb [ file join $dirtowrite $filename ]
 if {[file exists $filenameb]} {
     error "File $filenameb already exists"
        }
 if {[catch {set filetowrite [open $filenameb w ]}]} {
     error "Could not open file to write $filenameb"
                } else {
 if {[catch {fconfigure $filetowrite -buffering full}]} {
     error "Could not set buffering on $filetowrite"
                }
 if {[catch {fconfigure $filetowrite -buffersize 1000000}]} {
     error "Could not set buffersize on $filetowrite"
                }
puts "Opened File $filenameb"
return $filetowrite
	}
      } else {
error "Directory $dirtowrite is not a writable location"
	}
}

proc calc_weight { list name } {
global weights
set total 0
set n [ expr {[llength $list] - 1} ]
while {$n >= 0} {
set interim [ lindex [ join [lindex $list $n] ] end ]
set total [ expr {$total + $interim} ]
incr n -1
	}
set weights($name) $total
return $total
}

proc mk_region { file } {
set statement {_puts $file "$code|$text|$comment"}
for { set i 1 } { $i <= 5 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists regions ] [ expr {$i - 1} ] ] 0 ]
set comment [ TEXT_1 72 ]
eval $statement
     }
}

proc mk_nation { file } {
set statement {_puts $file "$code|$text|$join|$comment"}
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
eval $statement
	}
}

proc mk_supp { file start_rows end_rows db } {
if { $db eq "db2" } {
set statement {_puts $file "$suppkey|$name|$address|$nation_code|$phone|$acctbal|$comment"}
	} else {
set statement {_puts $file "$suppkey|$nation_code|$comment|$name|$address|$phone|$acctbal"}
	}
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
eval $statement
if { ![ expr {$i % 10000} ] } {
	puts "Generating SUPPLIER...$i"
	}
   }
puts "SUPPLIER Done Rows $start_rows..$end_rows"
return
}

proc mk_cust { file start_rows end_rows db } {
if { $db eq "db2" } {
set statement {_puts $file $custkey|$name|$address|$nation_code|$phone|$acctbal|$mktsegment|$comment}
	} else {
set statement {_puts $file $custkey|$mktsegment|$nation_code|$name|$address|$phone|$acctbal|$comment}
	}
for { set i $start_rows } { $i <= $end_rows } { incr i } {
set custkey $i
set name [ concat Customer#[format %1.9d $i]]
set address [ V_STR 25 ]
set nation_code [ RandomNumber 0 24 ]
set phone [ gen_phone ]
set acctbal [format %4.2f [ expr {[ expr {double([ RandomNumber -99999 999999 ])} ] / 100} ] ]
set mktsegment [ pick_str_1 msegmnt ]
set comment [ TEXT_1 73 ]
eval $statement
if { ![ expr {$i % 100000} ] } {
	puts "Generating CUSTOMER...$i"
	}
}
puts "Customer Done Rows $start_rows..$end_rows"
return
}

proc mk_part { file1 file2 start_rows end_rows scale_factor db } {
if { $db eq "db2" } {
set statement {_puts $file1 $partkey|$name|$mfgr|$brand|$type|$size|$container|$price|$comment }
	} else {
set statement {_puts $file1 $partkey|$type|$size|$brand|$name|$container|$mfgr|$price|$comment }
	}
set statement2 {_puts $file2 $psupp_pkey|$psupp_suppkey|$psupp_scost|$psupp_qty|$psupp_comment }
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
eval $statement
#Part Supp Loop
for {set k 0} {$k < 4 } {incr k } {
set psupp_pkey $partkey
set psupp_suppkey [ PART_SUPP_BRIDGE $i $k $scale_factor ]
set psupp_qty [ RandomNumber 1 9999 ]
set psupp_scost [format %4.2f [ expr {double([ RandomNumber 100 100000 ]) / 100} ] ]
set psupp_comment [ TEXT_1 124 ]
eval $statement2
}
# end of psupp loop
if { ![ expr {$i % 100000} ] } {
	puts "Generating PART/PARTSUPP...$i"
	}
 }
puts "PART and PARTSUPP Done Rows $start_rows..$end_rows"
return
}

proc mk_order { file1 file2 start_rows end_rows upd_num scale_factor db } {
if { $db eq "db2" } {
set statement {_puts $file1 $okey|$custkey|$orderstatus|$totalprice|$date|$opriority|$clerk|$spriority|$comment}
set statement2 {_puts $file2 $lokey|$lpartkey|$lsuppkey|$llcnt|$lquantity|$leprice|$ldiscount|$ltax|$lrflag|$lstatus|$lsdate|$lcdate|$lrdate|$linstruct|$lsmode|$lcomment}
	} else {
set statement {_puts $file1 $date|$okey|$custkey|$opriority|$spriority|$clerk|$orderstatus|$totalprice|$comment}
set statement2 {_puts $file2 $lsdate|$lokey|$ldiscount|$leprice|$lsuppkey|$lquantity|$lrflag|$lpartkey|$lstatus|$ltax|$lcdate|$lrdate|$lsmode|$llcnt|$linstruct|$lcomment}
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
eval $statement2
  }
if { $ocnt > 0} { set orderstatus "P" }
if { $ocnt == $lcnt } { set orderstatus "F" }
eval $statement
if { ![ expr {$i % 100000} ] } {
	puts "Generating ORDERS/LINEITEM...$i"
	}
}
puts "ORDERS and LINEITEM Done Rows $start_rows..$end_rows"
return
}

proc gen_tpch { scale_fact directory num_vu db } {
set start [ clock seconds ]
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
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
puts "Generating REGION..."
set reg_file [ set_filename $directory region 1 ] 
mk_region $reg_file
puts "Generating REGION COMPLETE"
close $reg_file
puts "Generating NATION..."
set nat_file [ set_filename $directory nation 1 ]
mk_nation $nat_file
puts "Generating NATION COMPLETE"
close $nat_file
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
puts "Generating REGION..."
set reg_file [ set_filename $directory region 1 ] 
mk_region $reg_file
puts "Generating REGION COMPLETE"
close $reg_file
puts "Generating NATION..."
set nat_file [ set_filename $directory nation 1 ]
mk_nation $nat_file
puts "Generating NATION COMPLETE"
close $nat_file
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
if { [ expr $myposition - 1 ] > $max_threads } { puts "No Data to Create"; return }
if { [ expr $num_vu + 1 ] > $max_threads } { set num_vu $max_threads }
set sf_chunk [ split [ start_end $sup_rows $myposition $sf_mult $num_vu ] ":" ]
set cust_chunk [ split [ start_end $sup_rows $myposition $cust_mult $num_vu ] ":" ]
set part_chunk [ split [ start_end $sup_rows $myposition $part_mult $num_vu ] ":" ]
set ord_chunk [ split [ start_end $sup_rows $myposition $ord_mult $num_vu ] ":" ]
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set myposition 1
set sf_chunk "1 $sup_rows"
set cust_chunk "1 [ expr {$sup_rows * $cust_mult} ]" 
set part_chunk "1 [ expr {$sup_rows * $part_mult} ]" 
set ord_chunk "1 [ expr {$sup_rows * $ord_mult} ]"
}
if { $myposition > 1 } { set myno [ expr $myposition - 1] } else { set myno $myposition }
puts "Generating SUPPLIER..."
set supp_file [ set_filename $directory supplier $myno ] 
mk_supp $supp_file [ lindex $sf_chunk 0 ] [ lindex $sf_chunk 1 ] $db
close $supp_file
puts "Generating CUSTOMER..."
set cust_file [ set_filename $directory customer $myno ] 
mk_cust $cust_file [ lindex $cust_chunk 0 ] [ lindex $cust_chunk 1 ] $db
close $cust_file
puts "Generating PART and PARTSUPP..."
set part_file [ set_filename $directory part $myno ] 
set partsupp_file [ set_filename $directory partsupp $myno ] 
mk_part $part_file $partsupp_file [ lindex $part_chunk 0 ] [ lindex $part_chunk 1 ] $scale_fact $db
close $part_file
close $partsupp_file
puts "Generating ORDERS and LINEITEM..."
set ord_file [ set_filename $directory orders $myno ] 
set lineit_file [ set_filename $directory lineitem $myno ] 
mk_order $ord_file $lineit_file [ lindex $ord_chunk 0 ] [ lindex $ord_chunk 1 ] [ expr {$upd_num % 10000} ] $scale_fact $db
close $ord_file
close $lineit_file
puts "Generating TPCH FILES COMPLETE"
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
set end [ clock seconds ]
set wall [ expr ($end - $start)/60 ]
puts "Scale Factor [ string toupper $scale_fact ] SCHEMA GENERATED in $wall MINUTES"
return
		}
	}
}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "gen_tpch $gen_scale_fact {$gen_directory} $gen_num_vu $db"
} else { return }
}
