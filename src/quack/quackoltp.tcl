#########################################################################
# HammerDB
# Copyright (C) HammerDB Ltd
# Hosted by the TPC-Council
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#########################################################################
#
# quackoltp.tcl - TPROC-C (OLTP) schema build and driver for the sqlxtc
# "Quack" database, spoken over the quacktcl pure-Tcl client package.
#
# sqlxtc is the networked SQL engine shipped as the libxtc 06_sqlxtc
# example.  It parses a SQLite-flavoured SQL dialect but its native
# execution engine is a subset.  This driver is adapted from the MySQL
# "no stored procedures" client-SQL driver, which is the closest fit,
# with the statements rewritten to the subset sqlxtc actually executes:
#
#   * transactions use BEGIN / COMMIT / ROLLBACK (no START TRANSACTION,
#     no SELECT ... FOR UPDATE - sqlxtc rejects both);
#   * multi-table selects are written as explicit JOIN ... ON (sqlxtc
#     rejects the comma-join / implicit cross-join form);
#   * timestamps are stored as bare YYYYMMDDHHMMSS integers (no
#     str_to_date());
#   * CREATE INDEX is omitted - sqlxtc has no secondary index DDL yet,
#     so all lookups run as table scans (correct, just slower);
#   * TPM is counted client-side (each committed business transaction
#     bumps a shared tsv counter) because sqlxtc exposes no server-side
#     commit statistic; NOPM is derived from sum(d_next_o_id) exactly as
#     the other drivers do.
#
# See the driver's PR / README for the precise sqlxtc SQL gap list.
#

proc build_quacktpcc {} {
    global maxvuser suppo ntimes threadscreated _ED
    upvar #0 dbdict dbdict
    if {[dict exists $dbdict quack library ]} {
        set library [ dict get $dbdict quack library ]
    } else { set library "quacktcl" }
    upvar #0 configquack configquack
    setlocaltpccvars $configquack
    if { [ ::tcl::info::commands tk_messageBox ] ne "" && $::tcl_interactive } { }
    if { $quack_num_vu eq 1 || $quack_count_ware eq 1 } {
        set maxvuser 1
    } else {
        set maxvuser [ expr $quack_num_vu + 1 ]
    }
    set suppo 1
    set ntimes 1
    ed_edit_clear
    set _ED(packagekeyname) "TPROC-C creation"
    if { [catch {load_virtual} message]} {
        puts "Failed to create thread for schema creation: $message"
        return
    }
    .ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh
#LOAD LIBRARIES AND MODULES
set library $library
"
    .ed_mainFrame.mainwin.textFrame.left.text fastinsert end {if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

proc gettimestamp { } {
    return [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
}

proc ConnectToQuack { host port } {
    if {[catch {set lda [ quackconnect $host $port ]} message]} {
        error "connection failed: $message"
    }
    return $lda
}

proc CreateTables { lda } {
    puts "CREATING TPCC TABLES"
    set sql(1) "CREATE TABLE customer (c_id INTEGER, c_d_id INTEGER, c_w_id INTEGER, c_first TEXT, c_middle TEXT, c_last TEXT, c_street_1 TEXT, c_street_2 TEXT, c_city TEXT, c_state TEXT, c_zip TEXT, c_phone TEXT, c_since INTEGER, c_credit TEXT, c_credit_lim REAL, c_discount REAL, c_balance REAL, c_data TEXT, c_ytd_payment REAL, c_payment_cnt INTEGER, c_delivery_cnt INTEGER, PRIMARY KEY (c_w_id, c_d_id, c_id))"
    set sql(2) "CREATE TABLE district (d_id INTEGER, d_w_id INTEGER, d_ytd REAL, d_tax REAL, d_next_o_id INTEGER, d_name TEXT, d_street_1 TEXT, d_street_2 TEXT, d_city TEXT, d_state TEXT, d_zip TEXT, PRIMARY KEY (d_w_id, d_id))"
    set sql(3) "CREATE TABLE history (h_c_id INTEGER, h_c_d_id INTEGER, h_c_w_id INTEGER, h_d_id INTEGER, h_w_id INTEGER, h_date INTEGER, h_amount REAL, h_data TEXT)"
    set sql(4) "CREATE TABLE item (i_id INTEGER PRIMARY KEY, i_im_id INTEGER, i_name TEXT, i_price REAL, i_data TEXT)"
    set sql(5) "CREATE TABLE new_order (no_w_id INTEGER, no_d_id INTEGER, no_o_id INTEGER, PRIMARY KEY (no_w_id, no_d_id, no_o_id))"
    set sql(6) "CREATE TABLE orders (o_id INTEGER, o_w_id INTEGER, o_d_id INTEGER, o_c_id INTEGER, o_carrier_id INTEGER, o_ol_cnt INTEGER, o_all_local INTEGER, o_entry_d INTEGER, PRIMARY KEY (o_w_id, o_d_id, o_id))"
    set sql(7) "CREATE TABLE order_line (ol_w_id INTEGER, ol_d_id INTEGER, ol_o_id INTEGER, ol_number INTEGER, ol_i_id INTEGER, ol_delivery_d INTEGER, ol_amount REAL, ol_supply_w_id INTEGER, ol_quantity INTEGER, ol_dist_info TEXT, PRIMARY KEY (ol_w_id, ol_d_id, ol_o_id, ol_number))"
    set sql(8) "CREATE TABLE stock (s_i_id INTEGER, s_w_id INTEGER, s_quantity INTEGER, s_dist_01 TEXT, s_dist_02 TEXT, s_dist_03 TEXT, s_dist_04 TEXT, s_dist_05 TEXT, s_dist_06 TEXT, s_dist_07 TEXT, s_dist_08 TEXT, s_dist_09 TEXT, s_dist_10 TEXT, s_ytd INTEGER, s_order_cnt INTEGER, s_remote_cnt INTEGER, s_data TEXT, PRIMARY KEY (s_w_id, s_i_id))"
    set sql(9) "CREATE TABLE warehouse (w_id INTEGER PRIMARY KEY, w_ytd REAL, w_tax REAL, w_name TEXT, w_street_1 TEXT, w_street_2 TEXT, w_city TEXT, w_state TEXT, w_zip TEXT)"
    for { set i 1 } { $i <= 9 } { incr i } {
        quackexec $lda $sql($i)
    }
    return
}

proc Customer { lda d_id w_id CUST_PER_DIST } {
    set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
    set namearr [list BAR OUGHT ABLE PRI PRES ESE ANTI CALLY ATION EING]
    set chalen [ llength $globArray ]
    set bld_cnt 1
    set c_d_id $d_id
    set c_w_id $w_id
    set c_middle "OE"
    set c_balance -10.0
    set c_credit_lim 50000
    set h_amount 10.0
    puts "Loading Customer for DID=$d_id WID=$w_id"
    quackexec $lda "BEGIN"
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
        if { [RandomNumber 0 1] eq 1 } { set c_credit "GC" } else { set c_credit "BC" }
        set disc_ran [ RandomNumber 0 50 ]
        set c_discount [ expr {$disc_ran / 100.0} ]
        set c_data [ MakeAlphaString 300 500 $globArray $chalen ]
        set ts [ gettimestamp ]
        append c_val_list "($c_id, $c_d_id, $c_w_id, '$c_first', '$c_middle', '$c_last', '[ lindex $c_add 0 ]', '[ lindex $c_add 1 ]', '[ lindex $c_add 2 ]', '[ lindex $c_add 3 ]', '[ lindex $c_add 4 ]', '$c_phone', $ts, '$c_credit', $c_credit_lim, $c_discount, $c_balance, '$c_data', 10.0, 1, 0)"
        set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
        append h_val_list "($c_id, $c_d_id, $c_w_id, $c_w_id, $c_d_id, $ts, $h_amount, '$h_data')"
        if { $bld_cnt <= 999 } {
            append c_val_list ,
            append h_val_list ,
        }
        incr bld_cnt
        if { ![ expr {$c_id % 1000} ] } {
            quackexec $lda "INSERT INTO customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) VALUES $c_val_list"
            quackexec $lda "INSERT INTO history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) VALUES $h_val_list"
            quackexec $lda "COMMIT"
            quackexec $lda "BEGIN"
            set bld_cnt 1
            unset c_val_list
            unset h_val_list
        }
    }
    quackexec $lda "COMMIT"
    puts "Customer Done"
    return
}

proc Orders { lda d_id w_id MAXITEMS ORD_PER_DIST } {
    set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
    set chalen [ llength $globArray ]
    set bld_cnt 1
    puts "Loading Orders for D=$d_id W=$w_id"
    set o_d_id $d_id
    set o_w_id $w_id
    for {set i 1} {$i <= $ORD_PER_DIST } {incr i } { set cust($i) $i }
    for {set i 1} {$i <= $ORD_PER_DIST } {incr i } {
        set r [ RandomNumber $i $ORD_PER_DIST ]
        set t $cust($i)
        set cust($i) $cust($r)
        set $cust($r) $t
    }
    quackexec $lda "BEGIN"
    for {set o_id 1} {$o_id <= $ORD_PER_DIST } {incr o_id } {
        set o_c_id $cust($o_id)
        set o_carrier_id [ RandomNumber 1 10 ]
        set o_ol_cnt [ RandomNumber 5 15 ]
        set ts [ gettimestamp ]
        if { $o_id > 2100 } {
            append o_val_list "($o_id, $o_c_id, $o_d_id, $o_w_id, $ts, null, $o_ol_cnt, 1)"
            append no_val_list "($o_id, $o_d_id, $o_w_id)"
        } else {
            append o_val_list "($o_id, $o_c_id, $o_d_id, $o_w_id, $ts, $o_carrier_id, $o_ol_cnt, 1)"
        }
        for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
            set ol_i_id [ RandomNumber 1 $MAXITEMS ]
            set ol_supply_w_id $o_w_id
            set ol_quantity 5
            set ol_amount 0.0
            set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
            if { $o_id > 2100 } {
                append ol_val_list "($o_id, $o_d_id, $o_w_id, $ol, $ol_i_id, $ol_supply_w_id, $ol_quantity, $ol_amount, '$ol_dist_info', null)"
            } else {
                set amt_ran [ RandomNumber 10 10000 ]
                set ol_amount [ expr {$amt_ran / 100.0} ]
                append ol_val_list "($o_id, $o_d_id, $o_w_id, $ol, $ol_i_id, $ol_supply_w_id, $ol_quantity, $ol_amount, '$ol_dist_info', $ts)"
            }
            if { $bld_cnt <= 99 } { append ol_val_list , } else {
                if { $ol != $o_ol_cnt } { append ol_val_list , }
            }
        }
        if { $bld_cnt <= 99 } {
            append o_val_list ,
            if { $o_id > 2100 } { append no_val_list , }
        }
        incr bld_cnt
        if { ![ expr {$o_id % 100} ] } {
            if { ![ expr {$o_id % 1000} ] } { puts "...$o_id" }
            quackexec $lda "INSERT INTO orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) VALUES $o_val_list"
            if { $o_id > 2100 } {
                quackexec $lda "INSERT INTO new_order (no_o_id, no_d_id, no_w_id) VALUES $no_val_list"
            }
            quackexec $lda "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) VALUES $ol_val_list"
            quackexec $lda "COMMIT"
            quackexec $lda "BEGIN"
            set bld_cnt 1
            unset o_val_list
            unset -nocomplain no_val_list
            unset ol_val_list
        }
    }
    quackexec $lda "COMMIT"
    puts "Orders Done"
    return
}

proc LoadItems { lda MAXITEMS } {
    set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
    set chalen [ llength $globArray ]
    puts "Loading Item"
    for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } { set orig($i) 0 }
    for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
        set pos [ RandomNumber 0 $MAXITEMS ]
        set orig($pos) 1
    }
    set bld_cnt 1
    quackexec $lda "BEGIN"
    for {set i_id 1} {$i_id <= $MAXITEMS } {incr i_id } {
        set i_im_id [ RandomNumber 1 10000 ]
        set i_name [ MakeAlphaString 14 24 $globArray $chalen ]
        set i_price_ran [ RandomNumber 100 10000 ]
        set i_price [ format "%4.2f" [ expr {$i_price_ran / 100.0} ] ]
        set i_data [ MakeAlphaString 26 50 $globArray $chalen ]
        if { [ info exists orig($i_id) ] && $orig($i_id) eq 1 } {
            set first [ RandomNumber 0 [ expr {[ string length $i_data] - 8}] ]
            set last [ expr {$first + 8} ]
            set i_data [ string replace $i_data $first $last "original" ]
        }
        append val_list "($i_id, $i_im_id, '$i_name', $i_price, '$i_data')"
        if { $bld_cnt <= 999 } { append val_list , }
        incr bld_cnt
        if { ![ expr {$i_id % 1000} ] } {
            quackexec $lda "INSERT INTO item (i_id, i_im_id, i_name, i_price, i_data) VALUES $val_list"
            quackexec $lda "COMMIT"
            quackexec $lda "BEGIN"
            set bld_cnt 1
            unset val_list
        }
        if { ![ expr {$i_id % 50000} ] } { puts "Loading Items - $i_id" }
    }
    quackexec $lda "COMMIT"
    puts "Item done"
    return
}

proc Stock { lda w_id MAXITEMS } {
    set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
    set chalen [ llength $globArray ]
    set bld_cnt 1
    puts "Loading Stock Wid=$w_id"
    set s_w_id $w_id
    for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } { set orig($i) 0 }
    for {set i 0} {$i < [ expr {$MAXITEMS/10} ] } {incr i } {
        set pos [ RandomNumber 0 $MAXITEMS ]
        set orig($pos) 1
    }
    quackexec $lda "BEGIN"
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
        if { [ info exists orig($s_i_id) ] && $orig($s_i_id) eq 1 } {
            set first [ RandomNumber 0 [ expr {[ string length $s_data] - 8} ] ]
            set last [ expr {$first + 8} ]
            set s_data [ string replace $s_data $first $last "original" ]
        }
        append val_list "($s_i_id, $s_w_id, $s_quantity, '$s_dist_01', '$s_dist_02', '$s_dist_03', '$s_dist_04', '$s_dist_05', '$s_dist_06', '$s_dist_07', '$s_dist_08', '$s_dist_09', '$s_dist_10', '$s_data', 0, 0, 0)"
        if { $bld_cnt <= 999 } { append val_list , }
        incr bld_cnt
        if { ![ expr {$s_i_id % 1000} ] } {
            quackexec $lda "INSERT INTO stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) VALUES $val_list"
            quackexec $lda "COMMIT"
            quackexec $lda "BEGIN"
            set bld_cnt 1
            unset val_list
        }
        if { ![ expr {$s_i_id % 20000} ] } { puts "Loading Stock - $s_i_id" }
    }
    quackexec $lda "COMMIT"
    puts "Stock done"
    return
}

proc District { lda w_id DIST_PER_WARE } {
    set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
    set chalen [ llength $globArray ]
    puts "Loading District"
    set d_w_id $w_id
    set d_ytd 30000.0
    set d_next_o_id 3001
    quackexec $lda "BEGIN"
    for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
        set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
        set d_add [ MakeAddress $globArray $chalen ]
        set d_tax_ran [ RandomNumber 10 20 ]
        set d_tax [ expr {$d_tax_ran / 100.0} ]
        quackexec $lda "INSERT INTO district (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) VALUES ($d_id, $d_w_id, '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', $d_tax, $d_ytd, $d_next_o_id)"
    }
    quackexec $lda "COMMIT"
    puts "District done"
    return
}

proc LoadWare { lda ware_start count_ware MAXITEMS DIST_PER_WARE } {
    set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
    set chalen [ llength $globArray ]
    puts "Loading Warehouse"
    set w_ytd 300000.00
    for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
        set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
        set add [ MakeAddress $globArray $chalen ]
        set w_tax_ran [ RandomNumber 10 20 ]
        set w_tax [ expr {$w_tax_ran / 100.0} ]
        quackexec $lda "BEGIN"
        quackexec $lda "INSERT INTO warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) VALUES ($w_id, '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]', '[ lindex $add 3 ]', '[ lindex $add 4 ]', $w_tax, $w_ytd)"
        quackexec $lda "COMMIT"
        Stock $lda $w_id $MAXITEMS
        District $lda $w_id $DIST_PER_WARE
    }
}

proc LoadCust { lda ware_start count_ware CUST_PER_DIST DIST_PER_WARE } {
    for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
        for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
            Customer $lda $d_id $w_id $CUST_PER_DIST
        }
    }
    return
}

proc LoadOrd { lda ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE } {
    for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
        for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
            Orders $lda $d_id $w_id $MAXITEMS $ORD_PER_DIST
        }
    }
    return
}

proc do_tpcc { host port count_ware num_vu } {
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
                tsv::lappend common thrdlst monitor
                for { set th 1 } { $th <= $totalvirtualusers } { incr th } {
                    tsv::lappend common thrdlst idle
                }
                tsv::set application load "WAIT"
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
        puts "CREATING QUACK (sqlxtc) SCHEMA"
        set lda [ ConnectToQuack $host $port ]
        CreateTables $lda
        if { $threaded eq "MULTI-THREADED" } {
            tsv::set application load "READY"
            LoadItems $lda $MAXITEMS
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
                if { $lvcnt != $prevactive } { puts "Workers: $lvcnt Active $dncnt Done" }
                set prevactive $lvcnt
                if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
                after 10000
            }
        } else {
            LoadItems $lda $MAXITEMS
        }
    }
    if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
        if { $threaded eq "MULTI-THREADED" } {
            puts "Waiting for Monitor Thread..."
            set mtcnt 0
            while 1 {
                if { [ tsv::get application abort ] } { return }
                if { [ tsv::exists application load ] } {
                    incr mtcnt
                    if { [ tsv::get application load ] eq "READY" } { break }
                    if { $mtcnt eq 48 } { puts "Monitor failed to notify ready state"; return }
                }
                after 5000
            }
            set lda [ ConnectToQuack $host $port ]
            set remb [ lassign [ findchunk $num_vu $count_ware $myposition ] chunk mystart myend ]
            puts "Loading $chunk Warehouses start:$mystart end:$myend"
            tsv::lreplace common thrdlst $myposition $myposition active
        } else {
            set mystart 1
            set myend $count_ware
        }
        puts "Start:[ clock format [ clock seconds ] ]"
        LoadWare $lda $mystart $myend $MAXITEMS $DIST_PER_WARE
        LoadCust $lda $mystart $myend $CUST_PER_DIST $DIST_PER_WARE
        LoadOrd $lda $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE
        puts "End:[ clock format [ clock seconds ] ]"
        if { $threaded eq "MULTI-THREADED" } {
            tsv::lreplace common thrdlst $myposition $myposition done
        }
    }
    if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
        puts "QUACK (sqlxtc) SCHEMA COMPLETE"
        quackclose $lda
        return
    }
}
}
    .ed_mainFrame.mainwin.textFrame.left.text fastinsert end "do_tpcc $quack_host $quack_port $quack_count_ware $quack_num_vu"
    return
}

# ----------------------------------------------------------------------
# TPROC-C run driver.  The timed workload emits the monitor VU (which
# times the run and reports NOPM / TPM) plus worker VUs that drive the
# transaction mix.  The test workload is the same mix without timing.
# ----------------------------------------------------------------------
proc loadquacktpcc { } { quack_tpcc_driver "test" }
proc loadtimedquacktpcc { } { quack_tpcc_driver "timed" }

proc quack_tpcc_driver { testtype } {
    global opmode _ED
    upvar #0 dbdict dbdict
    if {[dict exists $dbdict quack library ]} {
        set library [ dict get $dbdict quack library ]
    } else { set library "quacktcl" }
    upvar #0 configquack configquack
    setlocaltpccvars $configquack
    ed_edit_clear
    .ed_mainFrame.notebook select .ed_mainFrame.mainwin
    set _ED(packagekeyname) "Quack TPROC-C"
    .ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh
#OPTIONS
set library $library ;# Quack (sqlxtc) client library
set total_iterations $quack_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$quack_raiseerror\" ;# Exit script on Quack error (true or false)
set KEYANDTHINK \"$quack_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $quack_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $quack_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set host \"$quack_host\" ;# Address of the server hosting sqlxtc
set port \"$quack_port\" ;# Port of the sqlxtc Quack server (default 15432)
set testtype \"$testtype\" ;# test or timed
#OPTIONS
"
    .ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

proc gettimestamp { } {
    return [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
}

proc ConnectToQuack { host port } {
    if {[catch {set lda [ quackconnect $host $port ]} message]} {
        error "connection failed: $message"
    }
    return $lda
}

# Count a committed business transaction for client-side TPM.
proc bumptxn {} { tsv::incr application quack_txn 1 }

#NEW ORDER
proc neword { lda no_w_id w_id_input RAISEERROR } {
    set no_d_id [ RandomNumber 1 10 ]
    set no_c_id [ RandomNumber 1 3000 ]
    set ol_cnt [ RandomNumber 5 15 ]
    set date [ gettimestamp ]
    set no_max_w_id $w_id_input
    set no_o_all_local 1
    # Explicit JOIN form - sqlxtc rejects the comma-join used by the
    # MySQL driver here.  Columns are table-qualified: sqlxtc's native
    # engine resolves join projections only when each column names its
    # table.
    set cust_ware [ quacksel $lda "SELECT customer.c_discount, customer.c_last, customer.c_credit, warehouse.w_tax FROM customer JOIN warehouse ON warehouse.w_id = customer.c_w_id WHERE customer.c_w_id = $no_w_id AND customer.c_d_id = $no_d_id AND customer.c_id = $no_c_id" -flatlist ]
    lassign $cust_ware discount last credit wtax
    quackexec $lda "BEGIN"
    set o_id_tax_list [ quacksel $lda "SELECT d_next_o_id, d_tax FROM district WHERE d_id = $no_d_id AND d_w_id = $no_w_id" -flatlist ]
    lassign $o_id_tax_list next_o_id dtax
    quackexec $lda "UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = $no_d_id AND d_w_id = $no_w_id"
    set o_id [ lindex $o_id_tax_list 0 ]
    set no_c_discount [ lindex $cust_ware 0 ]
    set no_w_tax [ lindex $cust_ware 3 ]
    set no_d_tax [ lindex $o_id_tax_list 1 ]
    set rbk [ RandomNumber 1 99 ]
    set loop_counter 1
    while { $loop_counter <= $ol_cnt } {
        if { ($loop_counter eq $ol_cnt) && $rbk eq 1 } {
            set no_ol_i_id 100001
        } else {
            set no_ol_i_id [ RandomNumber 1 100000 ]
        }
        set x [ RandomNumber 1 100 ]
        set no_ol_supply_w_id $no_w_id
        if { $x <= 1 } {
            set no_o_all_local 0
            while { ($no_ol_supply_w_id eq $no_w_id) && ($no_max_w_id != 1) } {
                set no_ol_supply_w_id [ RandomNumber 1 $no_max_w_id ]
            }
        }
        set no_ol_quantity [ RandomNumber 1 10 ]
        set price_name_data [ quacksel $lda "SELECT i_price, i_name, i_data FROM item WHERE i_id = $no_ol_i_id" -flatlist ]
        if { [ llength $price_name_data ] eq 0 } {
            quackrollback $lda
            return
        }
        set quantity_data_dist [ quacksel $lda "SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10 FROM stock WHERE s_i_id = $no_ol_i_id AND s_w_id = $no_ol_supply_w_id" -flatlist ]
        set no_i_price [ lindex $price_name_data 0 ]
        set no_s_quantity [ lindex $quantity_data_dist 0 ]
        if { $no_s_quantity > $no_ol_quantity } {
            set no_s_quantity [ expr {$no_s_quantity - $no_ol_quantity} ]
        } else {
            set no_s_quantity [ expr {$no_s_quantity - $no_ol_quantity + 91} ]
        }
        quackexec $lda "UPDATE stock SET s_quantity = $no_s_quantity WHERE s_i_id = $no_ol_i_id AND s_w_id = $no_ol_supply_w_id"
        set no_ol_amount [ expr {($no_ol_quantity * $no_i_price * ( 1 + $no_w_tax + $no_d_tax ) * ( 1 - $no_c_discount ))} ]
        set no_ol_dist_info [ lindex $quantity_data_dist [ expr {$no_d_id + 1} ] ]
        quackexec $lda "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info) VALUES ($o_id, $no_d_id, $no_w_id, $loop_counter, $no_ol_i_id, $no_ol_supply_w_id, $no_ol_quantity, $no_ol_amount, '$no_ol_dist_info')"
        incr loop_counter
    }
    quackexec $lda "INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES ($o_id, $no_d_id, $no_w_id, $no_c_id, $date, $ol_cnt, $no_o_all_local)"
    quackexec $lda "INSERT INTO new_order (no_o_id, no_d_id, no_w_id) VALUES ($o_id, $no_d_id, $no_w_id)"
    quackcommit $lda
    bumptxn
}

#PAYMENT
proc payment { lda p_w_id w_id_input RAISEERROR } {
    set p_d_id [ RandomNumber 1 10 ]
    set x [ RandomNumber 1 100 ]
    set y [ RandomNumber 1 100 ]
    if { $x <= 85 } {
        set p_c_d_id $p_d_id
        set p_c_w_id $p_w_id
    } else {
        set p_c_d_id [ RandomNumber 1 10 ]
        set p_c_w_id [ RandomNumber 1 $w_id_input ]
        while { ($p_c_w_id == $p_w_id) && ($w_id_input != 1) } {
            set p_c_w_id [ RandomNumber 1  $w_id_input ]
        }
    }
    set nrnd [ NURand 255 0 999 123 ]
    set name [ randname $nrnd ]
    set p_c_id [ RandomNumber 1 3000 ]
    set p_c_id_fallback $p_c_id
    if { $y <= 60 } { set byname 1 } else { set byname 0; set name {} }
    set p_h_amount [ RandomNumber 1 5000 ]
    set h_date [ gettimestamp ]
    quackexec $lda "BEGIN"
    quackexec $lda "UPDATE warehouse SET w_ytd = w_ytd + $p_h_amount WHERE w_id = $p_w_id"
    set w_address_list [ quacksel $lda "SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name FROM warehouse WHERE w_id = $p_w_id" -flatlist ]
    lassign $w_address_list p_w_street_1 p_w_street_2 p_w_city p_w_state p_w_zip p_w_name
    quackexec $lda "UPDATE district SET d_ytd = d_ytd + $p_h_amount WHERE d_w_id = $p_w_id AND d_id = $p_d_id"
    set d_address_list [ quacksel $lda "SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name FROM district WHERE d_w_id = $p_w_id AND d_id = $p_d_id" -flatlist ]
    lassign $d_address_list p_d_street_1 p_d_street_2 p_d_city p_d_state p_d_zip p_d_name
    if { $byname } {
        set namecnt [ quacksel $lda "SELECT count(c_id) FROM customer WHERE c_last = '$name' AND c_d_id = $p_c_d_id AND c_w_id = $p_c_w_id" -flatlist ]
        set cust_list [ quacksel $lda "SELECT c_first, c_middle, c_id, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since FROM customer WHERE c_w_id = $p_c_w_id AND c_d_id = $p_c_d_id AND c_last = '$name' ORDER BY c_first" -list ]
        if { [ expr {$namecnt % 2} ] eq 1 } { set namecnt [ expr {$namecnt + 1} ] }
        set cust_id_to_query [ lindex $cust_list [ expr {$namecnt / 2} ] ]
        lassign $cust_id_to_query p_c_first p_c_middle p_c_id p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since
        set p_c_last $name
        # By-name lookup can miss (the NURand-generated last name may match
        # no customer, or the (namecnt/2) middle index can fall outside
        # the returned list); fall back to a by-number lookup so p_c_id is
        # never empty (an empty c_id would build invalid SQL).
        if { $p_c_id eq "" } {
            set cust_id_to_query [ quacksel $lda "SELECT c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since FROM customer WHERE c_w_id = $p_c_w_id AND c_d_id = $p_c_d_id AND c_id = $p_c_id_fallback" -flatlist ]
            lassign $cust_id_to_query p_c_first p_c_middle p_c_last p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since
            set p_c_id $p_c_id_fallback
        }
    } else {
        set cust_id_to_query [ quacksel $lda "SELECT c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since FROM customer WHERE c_w_id = $p_c_w_id AND c_d_id = $p_c_d_id AND c_id = $p_c_id" -flatlist ]
        lassign $cust_id_to_query p_c_first p_c_middle p_c_last p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since
    }
    if { $p_c_balance eq "" } { set p_c_balance 0 }
    set p_c_balance [ expr {$p_c_balance + $p_h_amount} ]
    if { $p_c_credit eq "BC" } {
        set c_data [ join [ quacksel $lda "SELECT c_data FROM customer WHERE c_w_id = $p_c_w_id AND c_d_id = $p_c_d_id AND c_id = $p_c_id" -flatlist ]]
        set h_data [ concat $p_w_name $p_d_name ]
        set p_c_new_data [ concat p_c_id $p_c_id p_c_d_id $p_c_d_id p_c_w_id $p_c_w_id p_d_id $p_d_id p_w_id $p_w_id p_h_amount [ format %4.2f $p_h_amount ] h_date $h_date h_data $h_data ]
        set p_c_new_data [ string range [ concat $p_c_new_data $c_data ] 1 [ expr 500 - [ string length $p_c_new_data ] ] ]
        set p_c_new_data [ quackescape $p_c_new_data ]
        quackexec $lda "UPDATE customer SET c_balance = $p_c_balance, c_data = '$p_c_new_data' WHERE c_w_id = $p_c_w_id AND c_d_id = $p_c_d_id AND c_id = $p_c_id"
    } else {
        quackexec $lda "UPDATE customer SET c_balance = $p_c_balance WHERE c_w_id = $p_c_w_id AND c_d_id = $p_c_d_id AND c_id = $p_c_id"
    }
    set h_data [ concat $p_w_name $p_d_name ]
    quackexec $lda "INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data) VALUES ($p_c_d_id, $p_c_w_id, $p_c_id, $p_d_id, $p_w_id, $h_date, $p_h_amount, '$h_data')"
    quackcommit $lda
    bumptxn
}

#ORDER_STATUS
proc ostat { lda w_id RAISEERROR } {
    set d_id [ RandomNumber 1 10 ]
    set nrnd [ NURand 255 0 999 123 ]
    set name [ randname $nrnd ]
    set c_id [ RandomNumber 1 3000 ]
    set y [ RandomNumber 1 100 ]
    if { $y <= 60 } { set byname 1 } else { set byname 0; set name {} }
    quackexec $lda "BEGIN"
    if { $byname eq 1 } {
        set namecnt [ quacksel $lda "SELECT count(c_id) FROM customer WHERE c_last = '$name' AND c_d_id = $d_id AND c_w_id = $w_id" -flatlist ]
        if { [ expr {$namecnt % 2} ] eq 1 } { incr namecnt }
        set cust_list [ quacksel $lda "SELECT c_balance, c_first, c_middle, c_id FROM customer WHERE c_last = '$name' AND c_d_id = $d_id AND c_w_id = $w_id ORDER BY c_first" -list ]
        set cust_id_to_query [ lindex $cust_list [ expr {($namecnt/2)-1} ] ]
    } else {
        set cust_id_to_query [ quacksel $lda "SELECT c_balance, c_first, c_middle, c_last FROM customer WHERE c_id = $c_id AND c_d_id = $d_id AND c_w_id = $w_id" -list ]
    }
    lassign $cust_id_to_query os_c_balance os_c_first os_c_middle os_c_last
    set cust_orders [ quacksel $lda "SELECT o_id, o_carrier_id, o_entry_d FROM orders WHERE o_d_id = $d_id AND o_w_id = $w_id AND o_c_id = $c_id ORDER BY o_id DESC LIMIT 1" -flatlist ]
    if { [ llength $cust_orders ] eq 0 } {
        set o_id 0
    } else {
        lassign $cust_orders o_id o_carrier_id o_entry_d
    }
    set c_line [ quacksel $lda "SELECT ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_delivery_d FROM order_line WHERE ol_o_id = $o_id AND ol_d_id = $d_id AND ol_w_id = $w_id" -flatlist ]
    quackcommit $lda
    bumptxn
}

#DELIVERY
proc delivery { lda w_id RAISEERROR } {
    set carrier_id [ RandomNumber 1 10 ]
    set date [ gettimestamp ]
    set loop_counter 1
    quackexec $lda "BEGIN"
    while { $loop_counter <= 10 } {
        set d_d_id $loop_counter
        set no_o_id [ quacksel $lda "SELECT no_o_id FROM new_order WHERE no_w_id = $w_id AND no_d_id = $d_d_id ORDER BY no_o_id LIMIT 1" -flatlist ]
        if { $no_o_id eq "" } { incr loop_counter; continue }
        quackexec $lda "DELETE FROM new_order WHERE no_w_id = $w_id AND no_d_id = $d_d_id AND no_o_id = $no_o_id"
        set o_c_id [ quacksel $lda "SELECT o_c_id FROM orders WHERE o_id = $no_o_id AND o_d_id = $d_d_id AND o_w_id = $w_id" -flatlist ]
        quackexec $lda "UPDATE orders SET o_carrier_id = $carrier_id WHERE o_id = $no_o_id AND o_d_id = $d_d_id AND o_w_id = $w_id"
        quackexec $lda "UPDATE order_line SET ol_delivery_d = $date WHERE ol_o_id = $no_o_id AND ol_d_id = $d_d_id AND ol_w_id = $w_id"
        set d_ol_total [ quacksel $lda "SELECT SUM(ol_amount) FROM order_line WHERE ol_o_id = $no_o_id AND ol_d_id = $d_d_id AND ol_w_id = $w_id" -flatlist ]
        if { $d_ol_total eq "" } { set d_ol_total 0 }
        quackexec $lda "UPDATE customer SET c_balance = c_balance + $d_ol_total WHERE c_id = $o_c_id AND c_d_id = $d_d_id AND c_w_id = $w_id"
        incr loop_counter
    }
    quackcommit $lda
    bumptxn
}

#STOCK LEVEL
proc slev { lda w_id stock_level_d_id RAISEERROR } {
    set threshold [ RandomNumber 10 20 ]
    quackexec $lda "BEGIN"
    set d_next_o_id [ quacksel $lda "SELECT d_next_o_id FROM district WHERE d_w_id = $w_id AND d_id = $stock_level_d_id" -flatlist ]
    if { $d_next_o_id eq "" } { set d_next_o_id 1 }
    # Subquery-IN form - sqlxtc's native engine supports single-table
    # aggregation but not JOIN combined with an aggregate, so the
    # standard stock-level join is expressed as a semantically
    # equivalent COUNT(DISTINCT ...) over stock with an IN subquery on
    # the recent order lines.
    set stock_count [ quacksel $lda "SELECT COUNT(DISTINCT s_i_id) FROM stock WHERE s_w_id = $w_id AND s_quantity < $threshold AND s_i_id IN (SELECT ol_i_id FROM order_line WHERE ol_w_id = $w_id AND ol_d_id = $stock_level_d_id AND ol_o_id < $d_next_o_id AND ol_o_id >= ($d_next_o_id - 20))" -flatlist ]
    quackcommit $lda
    bumptxn
}

set rema [ lassign [ findvuposition ] myposition totalvirtualusers ]
switch $myposition {
    1 {
        if { $mode eq "Local" || $mode eq "Primary" } {
            if { $testtype eq "timed" } {
                set lda [ ConnectToQuack $host $port ]
                set ramptime 0
                puts "Beginning rampup time of $rampup minutes"
                set rampup [ expr $rampup*60000 ]
                while {$ramptime != $rampup} {
                    if { [ tsv::get application abort ] } { break } else { after 6000 }
                    set ramptime [ expr $ramptime+6000 ]
                    if { ![ expr {$ramptime % 60000} ] } { puts "Rampup [ expr $ramptime / 60000 ] minutes complete ..." }
                }
                if { [ tsv::get application abort ] } { break }
                puts "Rampup complete, Taking start Transaction Count."
                if { ![ tsv::exists application quack_txn ] } { tsv::set application quack_txn 0 }
                set start_trans [ tsv::get application quack_txn ]
                if {[catch {set start_nopm [ quacksel $lda "SELECT sum(d_next_o_id) FROM district" -flatlist ]}]} {
                    puts stderr {error, failed to query district table}
                    return
                }
                puts "Timing test period of $duration in minutes"
                set testtime 0
                set durmin $duration
                set duration [ expr $duration*60000 ]
                while {$testtime != $duration} {
                    if { [ tsv::get application abort ] } { break } else { after 6000 }
                    set testtime [ expr $testtime+6000 ]
                    if { ![ expr {$testtime % 60000} ] } { puts -nonewline  "[ expr $testtime / 60000 ]  ...," }
                }
                if { [ tsv::get application abort ] } { break }
                puts "Test complete, Taking end Transaction Count."
                set end_trans [ tsv::get application quack_txn ]
                if {[catch {set end_nopm [ quacksel $lda "SELECT sum(d_next_o_id) FROM district" -flatlist ]}]} {
                    puts stderr {error, failed to query district table}
                    return
                }
                if { $durmin <= 0 } { set durmin 1 }
                set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
                set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
                puts "[ expr $totalvirtualusers - 1 ] Active Virtual Users configured"
                puts [ testresult $nopm $tpm Quack ]
                tsv::set application abort 1
                if { $mode eq "Primary" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
                catch { quackclose $lda }
            }
        } else {
            puts "Operating in Replica Mode, No Snapshots taken..."
        }
    }
    default {
        set lda [ ConnectToQuack $host $port ]
        set w_id_input [ quacksel $lda "SELECT max(w_id) FROM warehouse" -flatlist ]
        set w_id  [ RandomNumber 1 $w_id_input ]
        set d_id_input [ quacksel $lda "SELECT max(d_id) FROM district" -flatlist ]
        set stock_level_d_id  [ RandomNumber 1 $d_id_input ]
        if { $testtype eq "timed" } {
            puts "Processing $total_iterations transactions with output suppressed..."
        } else {
            puts "Processing $total_iterations transactions without output suppressed..."
        }
        for {set it 0} {$it < $total_iterations} {incr it} {
            if { [ tsv::get application abort ] } { break }
            set choice [ RandomNumber 1 23 ]
            if {$choice <= 10} {
                if { $KEYANDTHINK } { keytime 18 }
                if { [ catch { neword $lda $w_id $w_id_input $RAISEERROR } message ] } { if { $RAISEERROR } { error "New Order : $message" } else { puts $message } }
                if { $KEYANDTHINK } { thinktime 12 }
            } elseif {$choice <= 20} {
                if { $KEYANDTHINK } { keytime 3 }
                if { [ catch { payment $lda $w_id $w_id_input $RAISEERROR } message ] } { if { $RAISEERROR } { error "Payment : $message" } else { puts $message } }
                if { $KEYANDTHINK } { thinktime 12 }
            } elseif {$choice <= 21} {
                if { $KEYANDTHINK } { keytime 2 }
                if { [ catch { delivery $lda $w_id $RAISEERROR } message ] } { if { $RAISEERROR } { error "Delivery : $message" } else { puts $message } }
                if { $KEYANDTHINK } { thinktime 10 }
            } elseif {$choice <= 22} {
                if { $KEYANDTHINK } { keytime 2 }
                if { [ catch { slev $lda $w_id $stock_level_d_id $RAISEERROR } message ] } { if { $RAISEERROR } { error "Stock Level : $message" } else { puts $message } }
                if { $KEYANDTHINK } { thinktime 5 }
            } elseif {$choice <= 23} {
                if { $KEYANDTHINK } { keytime 2 }
                if { [ catch { ostat $lda $w_id $RAISEERROR } message ] } { if { $RAISEERROR } { error "Order Status : $message" } else { puts $message } }
                if { $KEYANDTHINK } { thinktime 5 }
            }
        }
        quackclose $lda
    }
}
}
    return
}
