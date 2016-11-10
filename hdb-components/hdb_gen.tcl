proc gendata_tpcc {} {
global rdbms gen_count_ware gen_directory gen_num_threads num_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists gen_count_ware ] } { set gen_count_ware "1" }
if {  ![ info exists gen_directory ] } { set gen_directory [ findtempdir ] }
if {  ![ info exists gen_num_threads ] } { set gen_num_threads "1" }
if {  ![ info exists rdbms ] } { set rdbms "Oracle" }
switch $rdbms {
        "Oracle" { set db "oracle" }
        "MSSQLServer" { set db "mssql" }
        "DB2" { set db "db2" }
        "MySQL" { set db "mysql" }
        "PostgreSQL" { set db "pg" }
        "Redis" { set db "redis" }
        "Trafodion" { set db "traf" }
	}
set install_message "Ready to generate the data for a $gen_count_ware Warehouse $rdbms TPC-C schema\nin directory $gen_directory ?" 
if {[ tk_messageBox -title "Generate Data" -icon question -message $install_message -type yesno ] == yes} { 
if { $gen_num_threads eq 1 || $gen_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $gen_num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C generation"
if { [catch {load_virtual} message]} {
puts "Failed to create thread(s) for data generation: $message"
	return 1
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }

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

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

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

proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}

proc Lastname { num namearr } {
set name [ concat [ lindex $namearr [ expr {( $num / 100 ) % 10 }] ][ lindex $namearr [ expr {( $num / 10 ) % 10 }] ][ lindex $namearr [ expr {( $num / 1 ) % 10 }]]]
return $name
}

proc MakeAlphaString { x y chArray chalen } {
set len [ RandomNumber $x $y ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}

proc Makezip { } {
set zip "000011111"
set ranz [ RandomNumber 0 9999 ]
set len [ expr {[ string length $ranz ] - 1} ]
set zip [ string replace $zip 0 $len $ranz ]
return $zip
}

proc MakeAddress { chArray chalen } {
return [ list [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 2 2 $chArray $chalen ] [ Makezip ] ]
}

proc MakeNumberString { } {
set zeroed "00000000"
set a [ RandomNumber 0 99999999 ] 
set b [ RandomNumber 0 99999999 ] 
set lena [ expr {[ string length $a ] - 1} ]
set lenb [ expr {[ string length $b ] - 1} ]
set c_pa [ string replace $zeroed 0 $lena $a ]
set c_pb [ string replace $zeroed 0 $lenb $b ]
set numberstring [ concat $c_pa$c_pb ]
return $numberstring
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

proc gen_tpcc { count_ware directory num_threads db } {
set start [ clock seconds ]
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
if { $num_threads > $count_ware } { set num_threads $count_ware }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
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
set num_threads 1
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
if { [ expr $num_threads + 1 ] > $count_ware } { set num_threads $count_ware }
set chunk [ expr $count_ware / $num_threads ]
set rem [ expr $count_ware % $num_threads ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_threads + 1 } { set myend $count_ware }
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
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 485.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "gen_tpcc $gen_count_ware {$gen_directory} $gen_num_threads $db"
} else { return }
}

proc gendata_tpch {} {
global rdbms gen_scale_fact gen_directory gen_num_threads num_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists gen_scale_fact ] } { set gen_scale_fact "1" }
if {  ![ info exists gen_directory ] } { set gen_directory [ findtempdir ] }
if {  ![ info exists gen_num_threads ] } { set gen_num_threads "1" }
if {  ![ info exists rdbms ] } { set rdbms "Oracle" }
switch $rdbms {
        "Oracle" { set db "oracle" }
        "MSSQLServer" { set db "mssql" }
        "DB2" { set db "db2" }
        "MySQL" { set db "mysql" }
        "PostgreSQL" { set db "pg" }
        "Redis" { set db "redis" }
        "Trafodion" { set db "traf" }
	}
set install_message "Ready to generate the data for a $gen_scale_fact Scale Factor $rdbms TPC-H schema\nin directory $gen_directory ?" 
if {[ tk_messageBox -title "Generate Data" -icon question -message $install_message -type yesno ] == yes} { 
if { $gen_num_threads eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $gen_num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-H generation"
if { [catch {load_virtual} message]} {
puts "Failed to create thread(s) for data generation: $message"
	return 1
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }

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

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc set_dists {} { 
global dists
set dists(category) {{FURNITURE 1} {{STORAGE EQUIP} 1} {TOOLS 1} {{MACHINE TOOLS} 1} {OTHER 1}}
set dists(p_cntr) {{{SM CASE} 1} {{SM BOX} 1} {{SM BAG} 1} {{SM JAR} 1} {{SM PACK} 1} {{SM PKG} 1} {{SM CAN} 1} {{SM DRUM} 1} {{LG CASE} 1} {{LG BOX} 1} {{LG BAG} 1} {{LG JAR} 1} {{LG PACK} 1} {{LG PKG} 1} {{LG CAN} 1} {{LG DRUM} 1} {{MED CASE} 1} {{MED BOX} 1} {{MED BAG} 1} {{MED JAR} 1} {{MED PACK} 1} {{MED PKG} 1} {{MED CAN} 1} {{MED DRUM} 1} {{JUMBO CASE} 1} {{JUMBO BOX} 1} {{JUMBO BAG} 1} {{JUMBO JAR} 1} {{JUMBO PACK} 1} {{JUMBO PKG} 1} {{JUMBO CAN} 1} {{JUMBO DRUM} 1} {{WRAP CASE} 1} {{WRAP BOX} 1} {{WRAP BAG} 1} {{WRAP JAR} 1} {{WRAP PACK} 1} {{WRAP PKG} 1} {{WRAP CAN} 1} {{WRAP DRUM} 1}}
set dists(instruct) {{{DELIVER IN PERSON} 1} {{COLLECT COD} 1} {{TAKE BACK RETURN} 1} {NONE 1}}
set dists(msegmnt) {{AUTOMOBILE 1} {BUILDING 1} {FURNITURE 1} {HOUSEHOLD 1} {MACHINERY 1}}
set dists(p_names) {{CLEANER 1} {SOAP 1} {DETERGENT 1} {EXTRA 1}}
set dists(nations) {{ALGERIA 0} {ARGENTINA 1} {BRAZIL 0} {CANADA 0} {EGYPT 3} {ETHIOPIA -4} {FRANCE 3} {GERMANY 0} {INDIA -1} {INDONESIA 0} {IRAN 2} {IRAQ 0} {JAPAN -2} {JORDAN 2} {KENYA -4} {MOROCCO 0} {MOZAMBIQUE 0} {PERU 1} {CHINA 1} {ROMANIA 1} {{SAUDI ARABIA} 1} {VIETNAM -2} {RUSSIA 1} {{UNITED KINGDOM} 0} {{UNITED STATES} -2}}
set dists(nations2) {{ALGERIA 1} {ARGENTINA 1} {BRAZIL 1} {CANADA 1} {EGYPT 1} {ETHIOPIA 1} {FRANCE 1} {GERMANY 1} {INDIA 1} {INDONESIA 1} {IRAN 1} {IRAQ 1} {JAPAN 1} {JORDAN 1} {KENYA 1} {MOROCCO 1} {MOZAMBIQUE 1} {PERU 1} {CHINA 1} {ROMANIA 1} {{SAUDI ARABIA} 1} {VIETNAM 1} {RUSSIA 1} {{UNITED KINGDOM} 1} {{UNITED STATES} 1}}
set dists(regions) {{AFRICA 1} {AMERICA 1} {ASIA 1} {EUROPE 1} {{MIDDLE EAST} 1}}
set dists(o_oprio) {{1-URGENT 1} {2-HIGH 1} {3-MEDIUM 1} {{4-NOT SPECIFIED} 1} {5-LOW 1}}
set dists(rflag) {{R 1} {A 1}}
set dists(smode) {{{REG AIR} 1} {AIR 1} {RAIL 1} {TRUCK 1} {MAIL 1} {FOB 1} {SHIP 1}}
set dists(p_types) {{{STANDARD ANODIZED TIN} 1} {{STANDARD ANODIZED NICKEL} 1} {{STANDARD ANODIZED BRASS} 1} {{STANDARD ANODIZED STEEL} 1} {{STANDARD ANODIZED COPPER} 1} {{STANDARD BURNISHED TIN} 1} {{STANDARD BURNISHED NICKEL} 1} {{STANDARD BURNISHED BRASS} 1} {{STANDARD BURNISHED STEEL} 1} {{STANDARD BURNISHED COPPER} 1} {{STANDARD PLATED TIN} 1} {{STANDARD PLATED NICKEL} 1} {{STANDARD PLATED BRASS} 1} {{STANDARD PLATED STEEL} 1} {{STANDARD PLATED COPPER} 1} {{STANDARD POLISHED TIN} 1} {{STANDARD POLISHED NICKEL} 1} {{STANDARD POLISHED BRASS} 1} {{STANDARD POLISHED STEEL} 1} {{STANDARD POLISHED COPPER} 1} {{STANDARD BRUSHED TIN} 1} {{STANDARD BRUSHED NICKEL} 1} {{STANDARD BRUSHED BRASS} 1} {{STANDARD BRUSHED STEEL} 1} {{STANDARD BRUSHED COPPER} 1} {{SMALL ANODIZED TIN} 1} {{SMALL ANODIZED NICKEL} 1} {{SMALL ANODIZED BRASS} 1} {{SMALL ANODIZED STEEL} 1} {{SMALL ANODIZED COPPER} 1} {{SMALL BURNISHED TIN} 1} {{SMALL BURNISHED NICKEL} 1} {{SMALL BURNISHED BRASS} 1} {{SMALL BURNISHED STEEL} 1} {{SMALL BURNISHED COPPER} 1} {{SMALL PLATED TIN} 1} {{SMALL PLATED NICKEL} 1} {{SMALL PLATED BRASS} 1} {{SMALL PLATED STEEL} 1} {{SMALL PLATED COPPER} 1} {{SMALL POLISHED TIN} 1} {{SMALL POLISHED NICKEL} 1} {{SMALL POLISHED BRASS} 1} {{SMALL POLISHED STEEL} 1} {{SMALL POLISHED COPPER} 1} {{SMALL BRUSHED TIN} 1} {{SMALL BRUSHED NICKEL} 1} {{SMALL BRUSHED BRASS} 1} {{SMALL BRUSHED STEEL} 1} {{SMALL BRUSHED COPPER} 1} {{MEDIUM ANODIZED TIN} 1} {{MEDIUM ANODIZED NICKEL} 1} {{MEDIUM ANODIZED BRASS} 1} {{MEDIUM ANODIZED STEEL} 1} {{MEDIUM ANODIZED COPPER} 1} {{MEDIUM BURNISHED TIN} 1} {{MEDIUM BURNISHED NICKEL} 1} {{MEDIUM BURNISHED BRASS} 1} {{MEDIUM BURNISHED STEEL} 1} {{MEDIUM BURNISHED COPPER} 1} {{MEDIUM PLATED TIN} 1} {{MEDIUM PLATED NICKEL} 1} {{MEDIUM PLATED BRASS} 1} {{MEDIUM PLATED STEEL} 1} {{MEDIUM PLATED COPPER} 1} {{MEDIUM POLISHED TIN} 1} {{MEDIUM POLISHED NICKEL} 1} {{MEDIUM POLISHED BRASS} 1} {{MEDIUM POLISHED STEEL} 1} {{MEDIUM POLISHED COPPER} 1} {{MEDIUM BRUSHED TIN} 1} {{MEDIUM BRUSHED NICKEL} 1} {{MEDIUM BRUSHED BRASS} 1} {{MEDIUM BRUSHED STEEL} 1} {{MEDIUM BRUSHED COPPER} 1} {{LARGE ANODIZED TIN} 1} {{LARGE ANODIZED NICKEL} 1} {{LARGE ANODIZED BRASS} 1} {{LARGE ANODIZED STEEL} 1} {{LARGE ANODIZED COPPER} 1} {{LARGE BURNISHED TIN} 1} {{LARGE BURNISHED NICKEL} 1} {{LARGE BURNISHED BRASS} 1} {{LARGE BURNISHED STEEL} 1} {{LARGE BURNISHED COPPER} 1} {{LARGE PLATED TIN} 1} {{LARGE PLATED NICKEL} 1} {{LARGE PLATED BRASS} 1} {{LARGE PLATED STEEL} 1} {{LARGE PLATED COPPER} 1} {{LARGE POLISHED TIN} 1} {{LARGE POLISHED NICKEL} 1} {{LARGE POLISHED BRASS} 1} {{LARGE POLISHED STEEL} 1} {{LARGE POLISHED COPPER} 1} {{LARGE BRUSHED TIN} 1} {{LARGE BRUSHED NICKEL} 1} {{LARGE BRUSHED BRASS} 1} {{LARGE BRUSHED STEEL} 1} {{LARGE BRUSHED COPPER} 1} {{ECONOMY ANODIZED TIN} 1} {{ECONOMY ANODIZED NICKEL} 1} {{ECONOMY ANODIZED BRASS} 1} {{ECONOMY ANODIZED STEEL} 1} {{ECONOMY ANODIZED COPPER} 1} {{ECONOMY BURNISHED TIN} 1} {{ECONOMY BURNISHED NICKEL} 1} {{ECONOMY BURNISHED BRASS} 1} {{ECONOMY BURNISHED STEEL} 1} {{ECONOMY BURNISHED COPPER} 1} {{ECONOMY PLATED TIN} 1} {{ECONOMY PLATED NICKEL} 1} {{ECONOMY PLATED BRASS} 1} {{ECONOMY PLATED STEEL} 1} {{ECONOMY PLATED COPPER} 1} {{ECONOMY POLISHED TIN} 1} {{ECONOMY POLISHED NICKEL} 1} {{ECONOMY POLISHED BRASS} 1} {{ECONOMY POLISHED STEEL} 1} {{ECONOMY POLISHED COPPER} 1} {{ECONOMY BRUSHED TIN} 1} {{ECONOMY BRUSHED NICKEL} 1} {{ECONOMY BRUSHED BRASS} 1} {{ECONOMY BRUSHED STEEL} 1} {{ECONOMY BRUSHED COPPER} 1} {{PROMO ANODIZED TIN} 1} {{PROMO ANODIZED NICKEL} 1} {{PROMO ANODIZED BRASS} 1} {{PROMO ANODIZED STEEL} 1} {{PROMO ANODIZED COPPER} 1} {{PROMO BURNISHED TIN} 1} {{PROMO BURNISHED NICKEL} 1} {{PROMO BURNISHED BRASS} 1} {{PROMO BURNISHED STEEL} 1} {{PROMO BURNISHED COPPER} 1} {{PROMO PLATED TIN} 1} {{PROMO PLATED NICKEL} 1} {{PROMO PLATED BRASS} 1} {{PROMO PLATED STEEL} 1} {{PROMO PLATED COPPER} 1} {{PROMO POLISHED TIN} 1} {{PROMO POLISHED NICKEL} 1} {{PROMO POLISHED BRASS} 1} {{PROMO POLISHED STEEL} 1} {{PROMO POLISHED COPPER} 1} {{PROMO BRUSHED TIN} 1} {{PROMO BRUSHED NICKEL} 1} {{PROMO BRUSHED BRASS} 1} {{PROMO BRUSHED STEEL} 1} {{PROMO BRUSHED COPPER} 1}}
set dists(colors) {{almond 1} {antique 1} {aquamarine 1} {azure 1} {beige 1} {bisque 1} {black 1} {blanched 1} {blue 1} {blush 1} {brown 1} {burlywood 1} {burnished 1} {chartreuse 1} {chiffon 1} {chocolate 1} {coral 1} {cornflower 1} {cornsilk 1} {cream 1} {cyan 1} {dark 1} {deep 1} {dim 1} {dodger 1} {drab 1} {firebrick 1} {floral 1} {forest 1} {frosted 1} {gainsboro 1} {ghost 1} {goldenrod 1} {green 1} {grey 1} {honeydew 1} {hot 1} {indian 1} {ivory 1} {khaki 1} {lace 1} {lavender 1} {lawn 1} {lemon 1} {light 1} {lime 1} {linen 1} {magenta 1} {maroon 1} {medium 1} {metallic 1} {midnight 1} {mint 1} {misty 1} {moccasin 1} {navajo 1} {navy 1} {olive 1} {orange 1} {orchid 1} {pale 1} {papaya 1} {peach 1} {peru 1} {pink 1} {plum 1} {powder 1} {puff 1} {purple 1} {red 1} {rose 1} {rosy 1} {royal 1} {saddle 1} {salmon 1} {sandy 1} {seashell 1} {sienna 1} {sky 1} {slate 1} {smoke 1} {snow 1} {spring 1} {steel 1} {tan 1} {thistle 1} {tomato 1} {turquoise 1} {violet 1} {wheat 1} {white 1} {yellow 1}}
set dists(nouns) {{packages 40} {requests 40} {accounts 40} {deposits 40} {foxes 20} {ideas 20} {theodolites 20} {{pinto beans} 20} {instructions 20} {dependencies 10} {excuses 10} {platelets 10} {asymptotes 10} {courts 5} {dolphins 5} {multipliers 1} {sauternes 1} {warthogs 1} {frets 1} {dinos 1} {attainments 1} {somas 1} {Tiresias 1} {patterns 1} {forges 1} {braids 1} {frays 1} {warhorses 1} {dugouts 1} {notornis 1} {epitaphs 1} {pearls 1} {tithes 1} {waters 1} {orbits 1} {gifts 1} {sheaves 1} {depths 1} {sentiments 1} {decoys 1} {realms 1} {pains 1} {grouches 1} {escapades 1} {{hockey players} 1}}
set dists(verbs) {{sleep 20} {wake 20} {are 20} {cajole 20} {haggle 20} {nag 10} {use 10} {boost 10} {affix 5} {detect 5} {integrate 5} {maintain 1} {nod 1} {was 1} {lose 1} {sublate 1} {solve 1} {thrash 1} {promise 1} {engage 1} {hinder 1} {print 1} {x-ray 1} {breach 1} {eat 1} {grow 1} {impress 1} {mold 1} {poach 1} {serve 1} {run 1} {dazzle 1} {snooze 1} {doze 1} {unwind 1} {kindle 1} {play 1} {hang 1} {believe 1} {doubt 1}}
set dists(adverbs) {{sometimes 1} {always 1} {never 1} {furiously 50} {slyly 50} {carefully 50} {blithely 40} {quickly 30} {fluffily 20} {slowly 1} {quietly 1} {ruthlessly 1} {thinly 1} {closely 1} {doggedly 1} {daringly 1} {bravely 1} {stealthily 1} {permanently 1} {enticingly 1} {idly 1} {busily 1} {regularly 1} {finally 1} {ironically 1} {evenly 1} {boldly 1} {silently 1}}
set dists(articles) {{the 50} {a 20} {an 5}}
set dists(prepositions) {{about 50} {above 50} {{according to} 50} {across 50} {after 50} {against 40} {along 40} {{alongside of} 30} {among 30} {around 20} {at 10} {atop 1} {before 1} {behind 1} {beneath 1} {beside 1} {besides 1} {between 1} {beyond 1} {by 1} {despite 1} {during 1} {except 1} {for 1} {from 1} {{in place of} 1} {inside 1} {{instead of} 1} {into 1} {near 1} {of 1} {on 1} {outside 1} {over {1 }} {past 1} {since 1} {through 1} {throughout 1} {to 1} {toward 1} {under 1} {until 1} {up {1 }} {upon 1} {whithout 1} {with 1} {within 1}}
set dists(auxillaries) {{do 1} {may 1} {might 1} {shall 1} {will 1} {would 1} {can 1} {could 1} {should 1} {{ought to} 1} {must 1} {{will have to} 1} {{shall have to} 1} {{could have to} 1} {{should have to} 1} {{must have to} 1} {{need to} 1} {{try to} 1}}
set dists(terminators) {{. 50} {{;} 1} {: 1} {? 1} {! 1} {-- 1}}
set dists(adjectives) {{special 20} {pending 20} {unusual 20} {express 20} {furious 1} {sly 1} {careful 1} {blithe 1} {quick 1} {fluffy 1} {slow 1} {quiet 1} {ruthless 1} {thin 1} {close 1} {dogged 1} {daring 1} {brave 1} {stealthy 1} {permanent 1} {enticing 1} {idle 1} {busy 1} {regular 50} {final 40} {ironic 40} {even 30} {bold 20} {silent 10}}
set dists(grammar) {{{N V T} 3} {{N V P T} 3} {{N V N T} 3} {{N P V N T} 1} {{N P V P T} 1}}
set dists(np) {{N 10} {{J N} 20} {{J J N} 10} {{D J N} 50}}
set dists(vp) {{V 30} {{X V} 1} {{V D} 40} {{X V D} 1}}
set dists(Q13a) {{special 20} {pending 20} {unusual 20} {express 20}}
set dists(Q13b) {{packages 40} {requests 40} {accounts 40} {deposits 40}}
}

proc get_dists { dist_type } {
global dists
if { ![ array exists dists ] } { set_dists }
return $dists($dist_type)
}

proc set_dist_list {dist_type} {
global dists weights dist_names dist_weights
set name $dist_type
set dist_list $dists($dist_type)
set dist_list_length [ llength $dist_list ]
if { [ array get weights $name ] != "" } { set max_weight $weights($name) } else {
set max_weight [ calc_weight $dist_list $name ]
	}
set i 0
while {$i < $dist_list_length} {
set dist_name [ lindex [lindex $dist_list $i ] 0 ]
set dist_value [ lindex [ join [lindex $dist_list $i ] ] end ]
lappend dist_names($dist_type) $dist_name
lappend dist_weights($dist_type) $dist_value 
incr i
	}
}

proc LEAP { y } {
return [ expr {(!($y % 4 ) && ($y % 100))} ] 
}

proc LEAP_ADJ { yr mnth } {
if { [ LEAP $yr ] && $mnth >=2 } { return 1 } else { return 0 }
}

proc julian { date } {
set offset [ expr {$date - 92001} ]
set result 92001
while { 1 eq 1 } {
set yr [ expr {$result / 1000} ]
set yend [ expr {$yr * 1000 + 365 + [ LEAP $yr ]} ]
if { [ expr {$result + $offset > $yend} ] } {
set offset [ expr {$offset - ($yend - $result + 1)} ]
set result [ expr {$result + 1000} ]
continue
	} else { break }
}
return [ expr {$result + $offset} ]
}

proc mk_time { index } {
set list {JAN 31 31 FEB 28 59 MAR 31 90 APR 30 120 MAY 31 151 JUN 30 181 JUL 31 212 AUG 31 243 SEP 30 273 OCT 31 304 NOV 30 334 DEC 31 365}
set timekey [ expr {$index + 8035} ]
set jyd [ julian [ expr {($index + 92001 - 1)} ] ] 
set y [ expr {$jyd / 1000} ]
set d [ expr {$jyd % 1000} ]
set year [ expr {1900 + $y} ]
set m 2
set n [ llength $list ]
set month [ lindex $list [ expr {$m - 2} ] ]
set day $d
while { ($d > [ expr {[ lindex $list $m ] + [ LEAP_ADJ $y [ expr {($m + 1) / 3} ]]}]) } {
set month [ lindex $list [ expr $m + 1 ] ]
set day [ expr {$d - [ lindex $list $m ] - [ LEAP_ADJ $y [ expr ($m + 1) / 3 ] ]} ]
incr m +3
}
set day [ format %02d $day ]
return [ concat $year-$month-$day ]
}

proc mk_sparse { i seq } {
set ok $i
set low_bits [ expr {$i & ((1 << 3) - 1)} ]
set ok [ expr {$ok >> 3} ]
set ok [ expr {$ok << 2} ]
set ok [ expr {$ok + $seq} ]
set ok [ expr {$ok << 3} ]
set ok [ expr {$ok + $low_bits} ]
return $ok
}

proc PART_SUPP_BRIDGE { p s scale_factor } {
set tot_scnt [ expr {10000 * $scale_factor} ]
set suppkey [ expr {($p + $s * ($tot_scnt / 4 + ($p - 1) / $tot_scnt)) % $tot_scnt + 1} ] 
return $suppkey
}

proc rpb_routine { p } {
set price 90000
set price [ expr {$price + [ expr {($p/10) % 20001} ]} ]
set price [ format %4.2f [ expr {double($price + [ expr {($p % 1000) * 100} ]) / 100} ] ]
return $price
}

proc gen_phone {} {
set acode [ RandomNumber 100 999 ]
set exchg [ RandomNumber 100 999 ]
set number [ RandomNumber 1000 9999 ]
return [ concat $acode-$exchg-$number ]
}

proc MakeAlphaString { min max chArray chalen } {
set len [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
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

proc pick_str { name } {
global weights dist_names dist_weights
set total 0
set i 0
set ran_weight [ RandomNumber 1  $weights($name) ]
while {$total < $ran_weight} {
set total [ expr {$total + [lindex $dist_weights($name) $i ]} ]
incr i
}
return  [lindex $dist_names($name) [ expr {$i - 1} ]]
}

proc txt_vp {} {
set verb_list [ split [ pick_str vp ] ]
set c 0
set n [ expr {[llength $verb_list] - 1} ]
while {$c <= $n } {
set interim [lindex $verb_list $c]
switch $interim {
D { set src adverbs }
V { set src verbs }
X { set src auxillaries }
}
append verb_p [ pick_str $src ] " "
incr c
}
return $verb_p
}

proc txt_np {} {
set noun_list [ split [ pick_str np ] ]
set c 0
set n [ expr {[llength $noun_list] - 1} ]
while {$c <= $n } {
set interim [lindex $noun_list $c]
switch $interim {
A { set src articles }
J { set src adjectives }
D { set src adverbs }
N { set src nouns }
}
append verb_p [ pick_str $src ] " "
incr c
}
return $verb_p
}

proc txt_sentence {} {
set sen_list [ split [ pick_str grammar ] ]
set c 0
set n [ expr {[llength $sen_list] - 1} ]
while {$c <= $n } {
set interim [lindex $sen_list $c]
switch $interim {
V { append txt [ txt_vp ] }
N { append txt [ txt_np ] }
P { append txt [ pick_str prepositions ] " the "
append txt [ txt_np ] }
T { set txt [ string trimright $txt ]
append txt [ pick_str terminators ] }
}
incr c
}
return $txt
}

proc dbg_text {min max} {
set wordlen 0
set needed false
set length [ RandomNumber [ expr {round($min)} ] [ expr {round($max)} ] ]
while { $wordlen < $length } {
set part_sen [ txt_sentence ] 
set s_len [ string length $part_sen ]
set needed [ expr {$length - $wordlen} ]
if { $needed >= [ expr {$s_len + 1} ] } {
append sentence "$part_sen "
set wordlen [ expr {$wordlen + $s_len + 1}]
	} else {
append sentence [ string range $part_sen 0 $needed ] 
set wordlen [ expr {$wordlen + $needed} ]
	}
}
return $sentence
}

proc V_STR { avg } {
set globArray [ list , \  0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
return [ MakeAlphaString [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] $globArray $chalen ] 
}

proc TEXT { avg } {
return [ dbg_text [ expr {$avg * 0.4} ] [ expr {$avg * 1.6} ] ] 
}

proc mk_region { file } {
set statement {_puts $file "$code|$text|$comment"}
for { set i 1 } { $i <= 5 } {incr i} {
set code [ expr {$i - 1} ]
set text [ lindex [ lindex [ get_dists regions ] [ expr {$i - 1} ] ] 0 ]
set comment [ TEXT 72 ]
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
set comment [ TEXT 72 ]
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
set comment [ TEXT 63 ]
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
set mktsegment [ pick_str msegmnt ]
set comment [ TEXT 73 ]
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
append name [ pick_str colors ] " "
}
append name [ pick_str colors ]
set mf [ RandomNumber 1 5 ]
set mfgr [ concat Manufacturer#$mf ]
set brand [ concat Brand#[ expr {$mf * 10 + [ RandomNumber 1 5 ]} ] ]
set type [ pick_str p_types ] 
set size [ RandomNumber 1 50 ]
set container [ pick_str p_cntr ] 
set price [ rpb_routine $i ]
set comment [ TEXT 14 ]
eval $statement
#Part Supp Loop
for {set k 0} {$k < 4 } {incr k } {
set psupp_pkey $partkey
set psupp_suppkey [ PART_SUPP_BRIDGE $i $k $scale_factor ]
set psupp_qty [ RandomNumber 1 9999 ]
set psupp_scost [format %4.2f [ expr {double([ RandomNumber 100 100000 ]) / 100} ] ]
set psupp_comment [ TEXT 124 ]
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
set opriority [ pick_str o_oprio ] 
set clk_num [ RandomNumber 1 [ expr {$scale_factor * 1000} ] ]
set clerk [ concat Clerk#[format %1.9d $clk_num]]
set comment [ TEXT 49 ]
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
set linstruct [ pick_str instruct ] 
set lsmode [ pick_str smode ] 
set lcomment [ TEXT 27 ]
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
set lrflag [ pick_str rflag ] 
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

proc start_end { sup_rows myposition my_mult num_threads } {
set sf_chunk [ expr $sup_rows / $num_threads ]
set sf_rem [ expr $sup_rows % $num_threads ]
set chunk [ expr {$sf_chunk * $my_mult} ]
set rem [ expr {$sf_rem * $my_mult} ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_threads + 1 } { set myend [ expr {$sup_rows * $my_mult} ] }
return $mystart:$myend
}

proc gen_tpch { scale_fact directory num_threads db } {
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
if { $num_threads > $max_threads } { set num_threads $max_threads }
if { $num_threads > 1 && [ chk_thread ] eq "TRUE" } {
set threaded "MULTI-THREADED"
set mythread [thread::id]
set allthreads [split [thread::names]]
set totalvirtualusers [expr [llength $allthreads] - 1]
set myposition [expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } { 
set totalvirtualusers [ expr $totalvirtualusers - 1 ] 
set myposition [ expr $myposition - 1 ]
	}
}
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
set num_threads 1
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
if { [ expr $num_threads + 1 ] > $max_threads } { set num_threads $max_threads }
set sf_chunk [ split [ start_end $sup_rows $myposition $sf_mult $num_threads ] ":" ]
set cust_chunk [ split [ start_end $sup_rows $myposition $cust_mult $num_threads ] ":" ]
set part_chunk [ split [ start_end $sup_rows $myposition $part_mult $num_threads ] ":" ]
set ord_chunk [ split [ start_end $sup_rows $myposition $ord_mult $num_threads ] ":" ]
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
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 682.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "gen_tpch $gen_scale_fact {$gen_directory} $gen_num_threads $db"
} else { return }
}
