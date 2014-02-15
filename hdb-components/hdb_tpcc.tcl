proc check_oratpcc {} {
global instance system_user system_password count_ware tpcc_user tpcc_pass tpcc_def_tab tpcc_ol_tab tpcc_def_temp count_ware plsql directory partition tpcc_tt_compat num_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists system_user ] } { set system_user "system" }
if {  ![ info exists system_password ] } { set system_password "manager" }
if {  ![ info exists instance ] } { set instance "oracle" }
if {  ![ info exists count_ware ] } { set count_ware "1" }
if {  ![ info exists tpcc_user ] } { set tpcc_user "tpcc" }
if {  ![ info exists tpcc_pass ] } { set tpcc_pass "tpcc" }
if {  ![ info exists tpcc_def_tab ] } { set tpcc_def_tab "tpcctab" }
if {  ![ info exists tpcc_ol_tab ] } { set tpcc_ol_tab $tpcc_def_tab }
if {  ![ info exists tpcc_def_temp ] } { set tpcc_def_temp "temp" }
if {  ![ info exists count_ware ] } { set count_ware 1 }
if {  ![ info exists plsql ] } { set plsql 0 }
if {  ![ info exists directory ] } { set directory [ findtempdir ] }
if {  ![ info exists partition ] } { set partition "false" }
if {  ![ info exists tpcc_tt_compat ] } { set tpcc_tt_compat "false" }
if {  ![ info exists num_threads ] } { set num_threads "1" }
if { $tpcc_tt_compat eq "true" } {
set install_message "Ready to create a $count_ware Warehouse TimesTen TPC-C schema\nin the existing database [string toupper $instance] under existing user [ string toupper $tpcc_user ]?" 
	} else {
set install_message "Ready to create a $count_ware Warehouse Oracle TPC-C schema\nin database [string toupper $instance] under user [ string toupper $tpcc_user ] in tablespace [ string toupper $tpcc_def_tab]?" 
	}
if {[ tk_messageBox -title "Create Schema" -icon question -message $install_message -type yesno ] == yes} { 
if { $num_threads eq 1 || $count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to create thread(s) for schema creation: $message"
	return 1
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act { #!/usr/local/bin/tclsh8.6
if [catch {package require Oratcl} ] { error "Failed to load Oratcl - Oracle OCI Library Error" }
proc CreateStoredProcs { lda timesten num_part } {
puts "CREATING TPCC STORED PROCEDURES"
set curn1 [ oraopen $lda ]
if { $timesten && $num_part != 0 } {
set sql(1) { CREATE OR REPLACE PROCEDURE NEWORD (
no_w_id		INTEGER,
no_max_w_id		INTEGER,
no_d_id		INTEGER,
no_c_id		INTEGER,
no_o_ol_cnt		INTEGER,
no_c_discount		OUT NUMBER,
no_c_last		OUT VARCHAR2,
no_c_credit		OUT VARCHAR2,
no_d_tax		OUT NUMBER,
no_w_tax		OUT NUMBER,
no_d_next_o_id		IN OUT INTEGER,
timestamp		IN DATE )
IS
no_ol_supply_w_id	INTEGER;
no_ol_i_id		NUMBER;
no_ol_quantity		NUMBER;
no_o_all_local		INTEGER;
o_id			INTEGER;
no_i_name		VARCHAR2(24);
no_i_price		NUMBER(5,2);
no_i_data		VARCHAR2(50);
no_s_quantity		NUMBER(6);
no_ol_amount		NUMBER(6,2);
no_s_dist_01		CHAR(24);
no_s_dist_02		CHAR(24);
no_s_dist_03		CHAR(24);
no_s_dist_04		CHAR(24);
no_s_dist_05		CHAR(24);
no_s_dist_06		CHAR(24);
no_s_dist_07		CHAR(24);
no_s_dist_08		CHAR(24);
no_s_dist_09		CHAR(24);
no_s_dist_10		CHAR(24);
no_ol_dist_info		CHAR(24);
no_s_data		VARCHAR2(50);
x			NUMBER;
rbk			NUMBER;
stmt_str		VARCHAR2(512);
mywid			INTEGER;

not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
integrity_viol			EXCEPTION;
PRAGMA EXCEPTION_INIT(integrity_viol,-1);
BEGIN
--assignment below added due to error in appendix code
no_o_all_local := 0;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND
customer.c_d_id = no_d_id AND customer.c_id = no_c_id;
UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = no_d_id AND d_w_id = no_w_id RETURNING d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax;
o_id := no_d_next_o_id;
INSERT INTO ORDERS (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (o_id, no_d_id, no_w_id, no_c_id, timestamp, no_o_ol_cnt, no_o_all_local);
INSERT INTO NEW_ORDER (no_o_id, no_d_id, no_w_id) VALUES (o_id, no_d_id, no_w_id);
--#2.4.1.4
rbk := round(DBMS_RANDOM.value(low => 1, high => 100));
--#2.4.1.5
FOR loop_counter IN 1 .. no_o_ol_cnt
LOOP
IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1))
THEN
no_ol_i_id := 100001;
ELSE
no_ol_i_id := round(DBMS_RANDOM.value(low => 1, high => 100000));
END IF;
--#2.4.1.5.2
x := round(DBMS_RANDOM.value(low => 1, high => 100));
IF ( x > 1 )
THEN
no_ol_supply_w_id := no_w_id;
ELSE
no_ol_supply_w_id := no_w_id;
--no_all_local is actually used before this point so following not beneficial
no_o_all_local := 0;
WHILE ((no_ol_supply_w_id = no_w_id) AND (no_max_w_id != 1))
LOOP
no_ol_supply_w_id := round(DBMS_RANDOM.value(low => 1, high => no_max_w_id));
END LOOP;
END IF;
--#2.4.1.5.3
no_ol_quantity := round(DBMS_RANDOM.value(low => 1, high => 10));
SELECT i_price, i_name, i_data INTO no_i_price, no_i_name, no_i_data
FROM item WHERE i_id = no_ol_i_id;
SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10
INTO no_s_quantity, no_s_data, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10 FROM stock WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id;
IF ( no_s_quantity > no_ol_quantity )
THEN
no_s_quantity := ( no_s_quantity - no_ol_quantity );
ELSE
no_s_quantity := ( no_s_quantity - no_ol_quantity + 91 );
END IF;
UPDATE stock SET s_quantity = no_s_quantity
WHERE s_i_id = no_ol_i_id
AND s_w_id = no_ol_supply_w_id;

no_ol_amount := (  no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );

IF no_d_id = 1
THEN 
no_ol_dist_info := no_s_dist_01; 

ELSIF no_d_id = 2
THEN
no_ol_dist_info := no_s_dist_02;

ELSIF no_d_id = 3
THEN
no_ol_dist_info := no_s_dist_03;

ELSIF no_d_id = 4
THEN
no_ol_dist_info := no_s_dist_04;

ELSIF no_d_id = 5
THEN
no_ol_dist_info := no_s_dist_05;

ELSIF no_d_id = 6
THEN
no_ol_dist_info := no_s_dist_06;

ELSIF no_d_id = 7
THEN
no_ol_dist_info := no_s_dist_07;

ELSIF no_d_id = 8
THEN
no_ol_dist_info := no_s_dist_08;

ELSIF no_d_id = 9
THEN
no_ol_dist_info := no_s_dist_09;

ELSIF no_d_id = 10
THEN
no_ol_dist_info := no_s_dist_10;
END IF;

mywid := mod(no_w_id, 10);
IF ( mywid = 0 )
THEN
mywid := 10;
END IF;

stmt_str := 'INSERT INTO order_line_'||mywid||'(ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info) VALUES (:o_id, :no_d_id, :no_w_id, :loop_counter, :no_ol_i_id, :no_ol_supply_w_id, :no_ol_quantity, :no_ol_amount, :no_ol_dist_info)';
--dbms_output.put_line(stmt_str);
EXECUTE IMMEDIATE stmt_str USING o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info;

END LOOP;

COMMIT;

EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old OR integrity_viol OR no_data_found
THEN
ROLLBACK;

END; }
} else {
set sql(1) { CREATE OR REPLACE PROCEDURE NEWORD (
no_w_id		INTEGER,
no_max_w_id		INTEGER,
no_d_id		INTEGER,
no_c_id		INTEGER,
no_o_ol_cnt		INTEGER,
no_c_discount		OUT NUMBER,
no_c_last		OUT VARCHAR2,
no_c_credit		OUT VARCHAR2,
no_d_tax		OUT NUMBER,
no_w_tax		OUT NUMBER,
no_d_next_o_id		IN OUT INTEGER,
timestamp		IN DATE )
IS
no_ol_supply_w_id	INTEGER;
no_ol_i_id		NUMBER;
no_ol_quantity		NUMBER;
no_o_all_local		INTEGER;
o_id			INTEGER;
no_i_name		VARCHAR2(24);
no_i_price		NUMBER(5,2);
no_i_data		VARCHAR2(50);
no_s_quantity		NUMBER(6);
no_ol_amount		NUMBER(6,2);
no_s_dist_01		CHAR(24);
no_s_dist_02		CHAR(24);
no_s_dist_03		CHAR(24);
no_s_dist_04		CHAR(24);
no_s_dist_05		CHAR(24);
no_s_dist_06		CHAR(24);
no_s_dist_07		CHAR(24);
no_s_dist_08		CHAR(24);
no_s_dist_09		CHAR(24);
no_s_dist_10		CHAR(24);
no_ol_dist_info		CHAR(24);
no_s_data		VARCHAR2(50);
x			NUMBER;
rbk			NUMBER;
not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
integrity_viol			EXCEPTION;
PRAGMA EXCEPTION_INIT(integrity_viol,-1);
BEGIN
--assignment below added due to error in appendix code
no_o_all_local := 0;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND
customer.c_d_id = no_d_id AND customer.c_id = no_c_id;
UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = no_d_id AND d_w_id = no_w_id RETURNING d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax;
o_id := no_d_next_o_id;
INSERT INTO ORDERS (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (o_id, no_d_id, no_w_id, no_c_id, timestamp, no_o_ol_cnt, no_o_all_local);
INSERT INTO NEW_ORDER (no_o_id, no_d_id, no_w_id) VALUES (o_id, no_d_id, no_w_id);
--#2.4.1.4
rbk := round(DBMS_RANDOM.value(low => 1, high => 100));
--#2.4.1.5
FOR loop_counter IN 1 .. no_o_ol_cnt
LOOP
IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1))
THEN
no_ol_i_id := 100001;
ELSE
no_ol_i_id := round(DBMS_RANDOM.value(low => 1, high => 100000));
END IF;
--#2.4.1.5.2
x := round(DBMS_RANDOM.value(low => 1, high => 100));
IF ( x > 1 )
THEN
no_ol_supply_w_id := no_w_id;
ELSE
no_ol_supply_w_id := no_w_id;
--no_all_local is actually used before this point so following not beneficial
no_o_all_local := 0;
WHILE ((no_ol_supply_w_id = no_w_id) AND (no_max_w_id != 1))
LOOP
no_ol_supply_w_id := round(DBMS_RANDOM.value(low => 1, high => no_max_w_id));
END LOOP;
END IF;
--#2.4.1.5.3
no_ol_quantity := round(DBMS_RANDOM.value(low => 1, high => 10));
SELECT i_price, i_name, i_data INTO no_i_price, no_i_name, no_i_data
FROM item WHERE i_id = no_ol_i_id;
SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10
INTO no_s_quantity, no_s_data, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10 FROM stock WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id;
IF ( no_s_quantity > no_ol_quantity )
THEN
no_s_quantity := ( no_s_quantity - no_ol_quantity );
ELSE
no_s_quantity := ( no_s_quantity - no_ol_quantity + 91 );
END IF;
UPDATE stock SET s_quantity = no_s_quantity
WHERE s_i_id = no_ol_i_id
AND s_w_id = no_ol_supply_w_id;

no_ol_amount := (  no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );

IF no_d_id = 1
THEN 
no_ol_dist_info := no_s_dist_01; 

ELSIF no_d_id = 2
THEN
no_ol_dist_info := no_s_dist_02;

ELSIF no_d_id = 3
THEN
no_ol_dist_info := no_s_dist_03;

ELSIF no_d_id = 4
THEN
no_ol_dist_info := no_s_dist_04;

ELSIF no_d_id = 5
THEN
no_ol_dist_info := no_s_dist_05;

ELSIF no_d_id = 6
THEN
no_ol_dist_info := no_s_dist_06;

ELSIF no_d_id = 7
THEN
no_ol_dist_info := no_s_dist_07;

ELSIF no_d_id = 8
THEN
no_ol_dist_info := no_s_dist_08;

ELSIF no_d_id = 9
THEN
no_ol_dist_info := no_s_dist_09;

ELSIF no_d_id = 10
THEN
no_ol_dist_info := no_s_dist_10;
END IF;

INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES (o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info);

END LOOP;

COMMIT;

EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old OR integrity_viol OR no_data_found
THEN
ROLLBACK;

END; }
}
if { $timesten } {
if { $num_part != 0 } { 
set sql(2) { CREATE OR REPLACE PROCEDURE DELIVERY (
d_w_id			INTEGER,
d_o_carrier_id		INTEGER,
timestamp		IN DATE )
IS
d_no_o_id		INTEGER;
d_d_id	           	INTEGER;
d_c_id	           	NUMBER;
d_ol_total		NUMBER;
stmt_str		VARCHAR2(512);
mywid			INTEGER;

not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
FOR loop_counter IN 1 .. 10
LOOP
d_d_id := loop_counter;
SELECT no_o_id INTO d_no_o_id from (SELECT no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id ORDER BY no_o_id ASC) where rownum = 1;
DELETE FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id AND no_o_id = d_no_o_id;
SELECT o_c_id INTO d_c_id FROM orders
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
 UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;

mywid := mod(d_w_id, 10);
IF ( mywid = 0 )
THEN
mywid := 10;
END IF;

stmt_str := 'UPDATE order_line_'||mywid||' SET ol_delivery_d = :timestamp WHERE ol_o_id = :d_no_o_id AND ol_d_id = :d_d_id AND ol_w_id = :d_w_id';
EXECUTE IMMEDIATE stmt_str USING timestamp, d_no_o_id, d_d_id, d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total
FROM order_line
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
COMMIT;
DBMS_OUTPUT.PUT_LINE('D: ' || d_d_id || 'O: ' || d_no_o_id || 'time ' || timestamp);
END LOOP;
EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old
THEN
ROLLBACK;
END;
	}
} else {
set sql(2) { CREATE OR REPLACE PROCEDURE DELIVERY (
d_w_id			INTEGER,
d_o_carrier_id		INTEGER,
timestamp		IN DATE )
IS
d_no_o_id		INTEGER;
d_d_id	           	INTEGER;
d_c_id	           	NUMBER;
d_ol_total		NUMBER;

not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
FOR loop_counter IN 1 .. 10
LOOP
d_d_id := loop_counter;
SELECT no_o_id INTO d_no_o_id from (SELECT no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id ORDER BY no_o_id ASC) where rownum = 1;
DELETE FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id AND no_o_id = d_no_o_id;
SELECT o_c_id INTO d_c_id FROM orders
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
 UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
UPDATE order_line SET ol_delivery_d = timestamp
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND
ol_w_id = d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total
FROM order_line
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
COMMIT;
DBMS_OUTPUT.PUT_LINE('D: ' || d_d_id || 'O: ' || d_no_o_id || 'time ' || timestamp);
END LOOP;
EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old
THEN
ROLLBACK;
END; }
  }
} else {
set sql(2) { CREATE OR REPLACE PROCEDURE DELIVERY (
d_w_id			INTEGER,
d_o_carrier_id		INTEGER,
timestamp		IN DATE )
IS
d_no_o_id		INTEGER;
d_d_id	           	INTEGER;
d_c_id	           	NUMBER;
d_ol_total		NUMBER;
current_ROWID		UROWID;
--WHERE CURRENT OF CLAUSE IN SPECIFICATION GAVE VERY POOR PERFORMANCE
--USED ROWID AS GIVEN IN DOC CDOUG Tricks and Treats by Shahs Upadhye
CURSOR c_no IS
SELECT no_o_id,ROWID
FROM new_order
WHERE no_d_id = d_d_id AND no_w_id = d_w_id
ORDER BY no_o_id ASC;

not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);

BEGIN
FOR loop_counter IN 1 .. 10
LOOP
d_d_id := loop_counter;
open c_no;
FETCH c_no INTO d_no_o_id,current_ROWID;
EXIT WHEN c_no%NOTFOUND;
DELETE FROM new_order WHERE rowid = current_ROWID;
close c_no;
SELECT o_c_id INTO d_c_id FROM orders
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
 UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
UPDATE order_line SET ol_delivery_d = timestamp
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND
ol_w_id = d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total
FROM order_line
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
COMMIT;
DBMS_OUTPUT.PUT_LINE('D: ' || d_d_id || 'O: ' || d_no_o_id || 'time ' || timestamp);
END LOOP;
EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old
THEN
ROLLBACK;
END; }
 }
set sql(3) { CREATE OR REPLACE PROCEDURE PAYMENT (
p_w_id			INTEGER,
p_d_id			INTEGER,
p_c_w_id		INTEGER,
p_c_d_id		INTEGER,
p_c_id			IN OUT INTEGER,
byname			INTEGER,
p_h_amount		NUMBER,
p_c_last		IN OUT VARCHAR2,
p_w_street_1		OUT VARCHAR2,
p_w_street_2		OUT VARCHAR2,
p_w_city		OUT VARCHAR2,
p_w_state		OUT VARCHAR2,
p_w_zip			OUT VARCHAR2,
p_d_street_1		OUT VARCHAR2,
p_d_street_2		OUT VARCHAR2,
p_d_city		OUT VARCHAR2,
p_d_state		OUT VARCHAR2,
p_d_zip			OUT VARCHAR2,
p_c_first		OUT VARCHAR2,
p_c_middle		OUT VARCHAR2,
p_c_street_1		OUT VARCHAR2,
p_c_street_2		OUT VARCHAR2,
p_c_city		OUT VARCHAR2,
p_c_state		OUT VARCHAR2,
p_c_zip			OUT VARCHAR2,
p_c_phone		OUT VARCHAR2,
p_c_since		OUT DATE,
p_c_credit		IN OUT VARCHAR2,
p_c_credit_lim		OUT NUMBER,
p_c_discount		OUT NUMBER,
p_c_balance		IN OUT NUMBER,
p_c_data		OUT VARCHAR2,
timestamp		IN DATE )
IS
namecnt			INTEGER;
p_d_name		VARCHAR2(11);
p_w_name		VARCHAR2(11);
p_c_new_data		VARCHAR2(500);
h_data			VARCHAR2(30);
CURSOR c_byname IS
SELECT c_first, c_middle, c_id,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last
ORDER BY c_first;
not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);

BEGIN
UPDATE warehouse SET w_ytd = w_ytd + p_h_amount
WHERE w_id = p_w_id;
SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name
INTO p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip, p_w_name
FROM warehouse
WHERE w_id = p_w_id;
UPDATE district SET d_ytd = d_ytd + p_h_amount
WHERE d_w_id = p_w_id AND d_id = p_d_id;
SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name
INTO p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip, p_d_name
FROM district
WHERE d_w_id = p_w_id AND d_id = p_d_id;
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = p_c_last AND c_d_id = p_c_d_id AND c_w_id = p_c_w_id;
OPEN c_byname;
IF ( MOD (namecnt, 2) = 1 )
THEN
namecnt := (namecnt + 1);
END IF;
FOR loop_counter IN 0 .. (namecnt/2)
LOOP
FETCH c_byname
INTO p_c_first, p_c_middle, p_c_id, p_c_street_1, p_c_street_2, p_c_city,
p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since;
END LOOP;
CLOSE c_byname;
ELSE
SELECT c_first, c_middle, c_last,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
INTO p_c_first, p_c_middle, p_c_last,
p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip,
p_c_phone, p_c_credit, p_c_credit_lim,
p_c_discount, p_c_balance, p_c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
END IF;
p_c_balance := ( p_c_balance + p_h_amount );
IF p_c_credit = 'BC' 
THEN
 SELECT c_data INTO p_c_data
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
-- The following statement in the TPC-C specification appendix is incorrect
-- copied setting of h_data from later on in the procedure to here as well
h_data := ( p_w_name || ' ' || p_d_name );
p_c_new_data := (TO_CHAR(p_c_id) || ' ' || TO_CHAR(p_c_d_id) || ' ' ||
TO_CHAR(p_c_w_id) || ' ' || TO_CHAR(p_d_id) || ' ' || TO_CHAR(p_w_id) || ' ' || TO_CHAR(p_h_amount,'9999.99') || TO_CHAR(timestamp) || h_data);
p_c_new_data := substr(CONCAT(p_c_new_data,p_c_data),1,500-(LENGTH(p_c_new_data)));
UPDATE customer
SET c_balance = p_c_balance, c_data = p_c_new_data
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
ELSE
UPDATE customer SET c_balance = p_c_balance
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
END IF;
--setting of h_data is here in the TPC-C appendix
h_data := ( p_w_name|| ' ' || p_d_name );
INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id,
h_w_id, h_date, h_amount, h_data)
VALUES (p_c_d_id, p_c_w_id, p_c_id, p_d_id,
p_w_id, timestamp, p_h_amount, h_data);
COMMIT;
EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old
THEN
ROLLBACK;
END; }
set sql(4) { CREATE OR REPLACE PROCEDURE OSTAT (
os_w_id			INTEGER,
os_d_id			INTEGER,
os_c_id			IN OUT INTEGER,
byname			INTEGER,
os_c_last		IN OUT VARCHAR2,
os_c_first		OUT VARCHAR2,
os_c_middle		OUT VARCHAR2,
os_c_balance		OUT NUMBER,
os_o_id			OUT INTEGER,
os_entdate		OUT DATE,
os_o_carrier_id		OUT INTEGER )
IS
TYPE numbertable IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
os_ol_i_id numbertable;	
os_ol_supply_w_id numbertable;	
os_ol_quantity numbertable;	
TYPE amounttable IS TABLE OF NUMBER(6,2) INDEX BY BINARY_INTEGER;
os_ol_amount amounttable;
TYPE datetable IS TABLE OF DATE INDEX BY BINARY_INTEGER;
os_ol_delivery_d datetable;
namecnt			INTEGER;
i			BINARY_INTEGER;
CURSOR c_name IS
SELECT c_balance, c_first, c_middle, c_id
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id
ORDER BY c_first;
CURSOR c_line IS
SELECT ol_i_id, ol_supply_w_id, ol_quantity,
ol_amount, ol_delivery_d
FROM order_line
WHERE ol_o_id = os_o_id AND ol_d_id = os_d_id AND ol_w_id = os_w_id;
os_c_line c_line%ROWTYPE;
not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id;
IF ( MOD (namecnt, 2) = 1 )
THEN
namecnt := (namecnt + 1);
END IF;
OPEN c_name;
FOR loop_counter IN 0 .. (namecnt/2)
LOOP
FETCH c_name  
INTO os_c_balance, os_c_first, os_c_middle, os_c_id;
END LOOP;
close c_name;
ELSE
SELECT c_balance, c_first, c_middle, c_last
INTO os_c_balance, os_c_first, os_c_middle, os_c_last
FROM customer
WHERE c_id = os_c_id AND c_d_id = os_d_id AND c_w_id = os_w_id;
END IF;
-- The following statement in the TPC-C specification appendix is incorrect
-- as it does not include the where clause and does not restrict the 
-- results set giving an ORA-01422.
-- The statement has been modified in accordance with the
-- descriptive specification as follows:
-- The row in the ORDER table with matching O_W_ID (equals C_W_ID),
-- O_D_ID (equals C_D_ID), O_C_ID (equals C_ID), and with the largest
-- existing O_ID, is selected. This is the most recent order placed by that
-- customer. O_ID, O_ENTRY_D, and O_CARRIER_ID are retrieved.
BEGIN
SELECT o_id, o_carrier_id, o_entry_d 
INTO os_o_id, os_o_carrier_id, os_entdate
FROM
(SELECT o_id, o_carrier_id, o_entry_d
FROM orders where o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id=os_c_id
ORDER BY o_id DESC)
WHERE ROWNUM = 1;
EXCEPTION
WHEN NO_DATA_FOUND THEN
dbms_output.put_line('No orders for customer');
END;
i := 0;
FOR os_c_line IN c_line
LOOP
os_ol_i_id(i) := os_c_line.ol_i_id;
os_ol_supply_w_id(i) := os_c_line.ol_supply_w_id;
os_ol_quantity(i) := os_c_line.ol_quantity;
os_ol_amount(i) := os_c_line.ol_amount;
os_ol_delivery_d(i) := os_c_line.ol_delivery_d;
i := i+1;
END LOOP;
EXCEPTION WHEN not_serializable OR deadlock OR snapshot_too_old THEN
ROLLBACK;
END; }
set sql(5) { CREATE OR REPLACE PROCEDURE SLEV (
st_w_id			INTEGER,
st_d_id			INTEGER,
threshold		INTEGER )
IS 
st_o_id			NUMBER;	
stock_count		INTEGER;
not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
SELECT d_next_o_id INTO st_o_id
FROM district
WHERE d_w_id=st_w_id AND d_id=st_d_id;

SELECT COUNT(DISTINCT (s_i_id)) INTO stock_count
FROM order_line, stock
WHERE ol_w_id = st_w_id AND
ol_d_id = st_d_id AND (ol_o_id < st_o_id) AND
ol_o_id >= (st_o_id - 20) AND s_w_id = st_w_id AND
s_i_id = ol_i_id AND s_quantity < threshold;
COMMIT;
EXCEPTION
WHEN not_serializable OR deadlock OR snapshot_too_old
THEN
ROLLBACK;
END; }
for { set i 1 } { $i <= 5 } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc TTPLSQLSettings { lda } {
set curn1 [ oraopen $lda ]
set sql(1) "alter session set PLSQL_OPTIMIZE_LEVEL = 2"
set sql(2) "alter session set PLSQL_CODE_TYPE = INTERPRETED"
set sql(3) "alter session set NLS_LENGTH_SEMANTICS = BYTE"
set sql(4) "alter session set PLSQL_CCFLAGS = ''"
set sql(5) "alter session set PLSCOPE_SETTINGS = 'IDENTIFIERS:NONE'"
for { set i 1 } { $i <= 5 } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc GatherStatistics { lda tpcc_user timesten num_part } {
puts "GATHERING SCHEMA STATISTICS"
set curn1 [ oraopen $lda ]
if { $timesten } {
set sql(1) "call ttOptUpdateStats('WAREHOUSE',1)"
set sql(2) "call ttOptUpdateStats('DISTRICT',1)"
set sql(3) "call ttOptUpdateStats('ITEM',1)"
set sql(4) "call ttOptUpdateStats('STOCK',1)"
set sql(5) "call ttOptUpdateStats('CUSTOMER',1)"
set sql(6) "call ttOptUpdateStats('ORDERS',1)"
set sql(7) "call ttOptUpdateStats('NEW_ORDER',1)"
set sql(8) "call ttOptUpdateStats('HISTORY',1)"
for { set i 1 } { $i <= 8 } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
if { $num_part eq 0 } {
set sql(9) "call ttOptUpdateStats('ORDER_LINE',1)"
set i 9
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
          }
	} else {
set sql(9a) "call ttOptUpdateStats('ORDER_LINE_1',1)"
set sql(9b) "call ttOptUpdateStats('ORDER_LINE_2',1)"
set sql(9c) "call ttOptUpdateStats('ORDER_LINE_3',1)"
set sql(9d) "call ttOptUpdateStats('ORDER_LINE_4',1)"
set sql(9e) "call ttOptUpdateStats('ORDER_LINE_5',1)"
set sql(9f) "call ttOptUpdateStats('ORDER_LINE_6',1)"
set sql(9g) "call ttOptUpdateStats('ORDER_LINE_7',1)"
set sql(9h) "call ttOptUpdateStats('ORDER_LINE_8',1)"
set sql(9i) "call ttOptUpdateStats('ORDER_LINE_9',1)"
set sql(9j) "call ttOptUpdateStats('ORDER_LINE_10',1)"
set partidx [ list a b c d e f g h i j ]
for { set p 1 } { $p <= 10 } { incr p } {
set idx [ lindex $partidx [ expr $p - 1]] 
if {[ catch {orasql $curn1 $sql(9$idx)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
          }
        }
     }
   } else {
set sql(1) "BEGIN dbms_stats.gather_schema_stats('$tpcc_user'); END;"
if {[ catch {orasql $curn1 $sql(1)} message ] } {
puts "$message $sql(1)"
puts [ oramsg $curn1 all ]
	}
}
oraclose $curn1
return
}

proc CreateUser { lda tpcc_user tpcc_pass tpcc_def_tab tpcc_def_temp tpcc_ol_tab partition} {
puts "CREATING USER $tpcc_user"
set stmt_cnt 3
set curn1 [ oraopen $lda ]
set sql(1) "create user $tpcc_user identified by $tpcc_pass default tablespace $tpcc_def_tab temporary tablespace $tpcc_def_temp\n"
set sql(2) "grant connect,resource to $tpcc_user\n"
set sql(3) "alter user $tpcc_user quota unlimited on $tpcc_def_tab\n"
if { $partition eq "true" } {
if { $tpcc_def_tab != $tpcc_ol_tab } { 
set stmt_cnt 4
set sql(4) "alter user $tpcc_user quota unlimited on $tpcc_ol_tab\n"
	}
  }
for { set i 1 } { $i <= $stmt_cnt } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc CreateTables { lda num_part tpcc_ol_tab timesten } {
puts "CREATING TPCC TABLES"
set curn1 [ oraopen $lda ]
if { $timesten } {
set sql(1) "create table TPCC.CUSTOMER (C_ID TT_BIGINT, C_D_ID TT_INTEGER, C_W_ID TT_INTEGER, C_FIRST CHAR(16), C_MIDDLE CHAR(2), C_LAST CHAR(16), C_STREET_1 CHAR(20), C_STREET_2 CHAR(20), C_CITY CHAR(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE DATE, C_CREDIT CHAR(2), C_CREDIT_LIM BINARY_DOUBLE, C_DISCOUNT BINARY_DOUBLE, C_BALANCE BINARY_DOUBLE, C_YTD_PAYMENT BINARY_DOUBLE, C_PAYMENT_CNT TT_INTEGER, C_DELIVERY_CNT TT_INTEGER, C_DATA VARCHAR2(500))"
set sql(2) "create table TPCC.DISTRICT (D_ID TT_INTEGER, D_W_ID TT_INTEGER, D_YTD BINARY_DOUBLE, D_TAX BINARY_DOUBLE, D_NEXT_O_ID TT_BIGINT, D_NAME CHAR(10), D_STREET_1 CHAR(20), D_STREET_2 CHAR(20), D_CITY CHAR(20), D_STATE CHAR(2), D_ZIP CHAR(9))"
set sql(3) "create table TPCC.HISTORY (H_C_ID TT_BIGINT, H_C_D_ID TT_INTEGER, H_C_W_ID TT_INTEGER, H_D_ID TT_INTEGER, H_W_ID TT_INTEGER, H_DATE DATE, H_AMOUNT BINARY_DOUBLE, H_DATA CHAR(24))"
set sql(4) "create table TPCC.ITEM (I_ID TT_BIGINT, I_IM_ID TT_BIGINT, I_NAME CHAR(24), I_PRICE BINARY_DOUBLE, I_DATA CHAR(50))"
set sql(5) "create table TPCC.NEW_ORDER (NO_W_ID TT_BIGINT, NO_D_ID TT_INTEGER, NO_O_ID TT_INTEGER)"
set sql(6) "create table TPCC.ORDERS (O_ID TT_BIGINT, O_W_ID TT_BIGINT, O_D_ID TT_INTEGER, O_C_ID TT_INTEGER, O_CARRIER_ID TT_INTEGER, O_OL_CNT TT_INTEGER, O_ALL_LOCAL TT_INTEGER, O_ENTRY_D DATE)"
if {$num_part eq 0} {
set sql(7) "create table TPCC.ORDER_LINE (OL_W_ID TT_BIGINT, OL_D_ID TT_INTEGER, OL_O_ID TT_INTEGER, OL_NUMBER TT_INTEGER, OL_I_ID TT_BIGINT, OL_DELIVERY_D DATE, OL_AMOUNT BINARY_DOUBLE, OL_SUPPLY_W_ID TT_INTEGER, OL_QUANTITY TT_INTEGER, OL_DIST_INFO CHAR(24))"
	} else {
set partidx [ list a b c d e f g h i j ]
for { set p 1 } { $p <= 10 } { incr p } {
set idx [ lindex $partidx [ expr $p - 1]] 
set sql(7$idx) "create table TPCC.ORDER_LINE_$p (OL_W_ID TT_BIGINT, OL_D_ID TT_INTEGER, OL_O_ID TT_INTEGER, OL_NUMBER TT_INTEGER, OL_I_ID TT_BIGINT, OL_DELIVERY_D DATE, OL_AMOUNT BINARY_DOUBLE, OL_SUPPLY_W_ID TT_INTEGER, OL_QUANTITY TT_INTEGER, OL_DIST_INFO CHAR(24))"
		}
set idx k
set sql(7$idx) "create view ORDER_LINE AS ("
for { set p 1 } { $p <= 9 } { incr p } {
set sql(7$idx) "$sql(7$idx) SELECT * FROM ORDER_LINE_$p UNION ALL" 
		}
set p 10
set sql(7$idx) "$sql(7$idx) SELECT * FROM ORDER_LINE_$p )"
	}
set sql(8) "create table TPCC.STOCK (S_I_ID TT_BIGINT, S_W_ID TT_INTEGER, S_QUANTITY TT_INTEGER, S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD TT_BIGINT, S_ORDER_CNT TT_INTEGER, S_REMOTE_CNT TT_INTEGER, S_DATA CHAR(50))"
set sql(9) "create table TPCC.WAREHOUSE (W_ID TT_INTEGER, W_YTD BINARY_DOUBLE, W_TAX BINARY_DOUBLE, W_NAME CHAR(10), W_STREET_1 CHAR(20), W_STREET_2 CHAR(20), W_CITY CHAR(20), W_STATE CHAR(2), W_ZIP CHAR(9))"
	} else {
set sql(1) "CREATE TABLE CUSTOMER (C_ID NUMBER(5, 0), C_D_ID NUMBER(2, 0), C_W_ID NUMBER(4, 0), C_FIRST VARCHAR2(16), C_MIDDLE CHAR(2), C_LAST VARCHAR2(16), C_STREET_1 VARCHAR2(20), C_STREET_2 VARCHAR2(20), C_CITY VARCHAR2(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE DATE, C_CREDIT CHAR(2), C_CREDIT_LIM NUMBER(12, 2), C_DISCOUNT NUMBER(4, 4), C_BALANCE NUMBER(12, 2), C_YTD_PAYMENT NUMBER(12, 2), C_PAYMENT_CNT NUMBER(8, 0), C_DELIVERY_CNT NUMBER(8, 0), C_DATA VARCHAR2(500)) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(2) "CREATE TABLE DISTRICT (D_ID NUMBER(2, 0), D_W_ID NUMBER(4, 0), D_YTD NUMBER(12, 2), D_TAX NUMBER(4, 4), D_NEXT_O_ID NUMBER, D_NAME VARCHAR2(10), D_STREET_1 VARCHAR2(20), D_STREET_2 VARCHAR2(20), D_CITY VARCHAR2(20), D_STATE CHAR(2), D_ZIP CHAR(9)) INITRANS 4 MAXTRANS 16 PCTFREE 99 PCTUSED 1"
set sql(3) "CREATE TABLE HISTORY (H_C_ID NUMBER, H_C_D_ID NUMBER, H_C_W_ID NUMBER, H_D_ID NUMBER, H_W_ID NUMBER, H_DATE DATE, H_AMOUNT NUMBER(6, 2), H_DATA VARCHAR2(24)) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(4) "CREATE TABLE ITEM (I_ID NUMBER(6, 0), I_IM_ID NUMBER, I_NAME VARCHAR2(24), I_PRICE NUMBER(5, 2), I_DATA VARCHAR2(50)) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(5) "CREATE TABLE WAREHOUSE (W_ID NUMBER(4, 0), W_YTD NUMBER(12, 2), W_TAX NUMBER(4, 4), W_NAME VARCHAR2(10), W_STREET_1 VARCHAR2(20), W_STREET_2 VARCHAR2(20), W_CITY VARCHAR2(20), W_STATE CHAR(2), W_ZIP CHAR(9)) INITRANS 4 MAXTRANS 16 PCTFREE 99 PCTUSED 1"
set sql(6) "CREATE TABLE STOCK (S_I_ID NUMBER(6, 0), S_W_ID NUMBER(4, 0), S_QUANTITY NUMBER(6, 0), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD NUMBER(10, 0), S_ORDER_CNT NUMBER(6, 0), S_REMOTE_CNT NUMBER(6, 0), S_DATA VARCHAR2(50)) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(7) "CREATE TABLE NEW_ORDER (NO_W_ID NUMBER, NO_D_ID NUMBER, NO_O_ID NUMBER, CONSTRAINT INORD PRIMARY KEY (NO_W_ID, NO_D_ID, NO_O_ID) ENABLE ) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(8) "CREATE TABLE ORDERS (O_ID NUMBER, O_W_ID NUMBER, O_D_ID NUMBER, O_C_ID NUMBER, O_CARRIER_ID NUMBER, O_OL_CNT NUMBER, O_ALL_LOCAL NUMBER, O_ENTRY_D DATE) INITRANS 4 MAXTRANS 16 PCTFREE 10"
if {$num_part eq 0} {
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID NUMBER, OL_D_ID NUMBER, OL_O_ID NUMBER, OL_NUMBER NUMBER, OL_I_ID NUMBER, OL_DELIVERY_D DATE, OL_AMOUNT NUMBER, OL_SUPPLY_W_ID NUMBER, OL_QUANTITY NUMBER, OL_DIST_INFO CHAR(24), CONSTRAINT IORDL PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER) ENABLE) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 MAXTRANS 16 PCTFREE 10"
	} else {
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID NUMBER, OL_D_ID NUMBER, OL_O_ID NUMBER, OL_NUMBER NUMBER, OL_I_ID NUMBER, OL_DELIVERY_D DATE, OL_AMOUNT NUMBER, OL_SUPPLY_W_ID NUMBER, OL_QUANTITY NUMBER, OL_DIST_INFO CHAR(24), CONSTRAINT IORDL PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER) ENABLE) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 MAXTRANS 16 PCTFREE 10 PARTITION BY HASH(OL_W_ID) PARTITIONS $num_part TABLESPACE $tpcc_ol_tab"
	}
   }

for { set i 1 } { $i <= 9 } { incr i } {
if { $i eq 7 && $timesten && $num_part eq 10 } {
set partidx [ list a b c d e f g h i j k ]
for { set p 1 } { $p <= 11 } { incr p } {
set idx [ lindex $partidx [ expr $p - 1]] 
if {[ catch {orasql $curn1 $sql(7$idx)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
	}}} else {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
	}
oraclose $curn1
return
}

proc CreateIndexes { lda timesten num_part } {
puts "CREATING TPCC INDEXES"
set curn1 [ oraopen $lda ]
set stmt_cnt 9
if { $timesten } {
if { $num_part eq 0 } {
set stmt_cnt 10
set sql(1) "create unique index TPCC.WAREHOUSE_I1 on TPCC.WAREHOUSE (W_ID)"
set sql(2) "create unique index TPCC.STOCK_I1 on TPCC.STOCK (S_I_ID, S_W_ID)"
set sql(3) "create unique index TPCC.ORDER_LINE_I1 on TPCC.ORDER_LINE (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(4) "create unique index TPCC.ORDERS_I1 on TPCC.ORDERS (O_W_ID, O_D_ID, O_ID)"
set sql(5) "create unique index TPCC.ORDERS_I2 on TPCC.ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID)"
set sql(6) "create unique index TPCC.NEW_ORDER_I1 on TPCC.NEW_ORDER (NO_W_ID, NO_D_ID, NO_O_ID)"
set sql(7) "create unique index TPCC.ITEM_I1 on TPCC.ITEM (I_ID)"
set sql(8) "create unique index TPCC.DISTRICT_I1 on TPCC.DISTRICT (D_W_ID, D_ID)"
set sql(9) "create unique index TPCC.CUSTOMER_I1 on TPCC.CUSTOMER (C_W_ID, C_D_ID, C_ID)"
set sql(10) "create unique index TPCC.CUSTOMER_I2 on TPCC.CUSTOMER (C_LAST, C_W_ID, C_D_ID, C_FIRST, C_ID)"
	  } else {
set stmt_cnt 19
set sql(1) "create unique index TPCC.WAREHOUSE_I1 on TPCC.WAREHOUSE (W_ID)"
set sql(2) "create unique index TPCC.STOCK_I1 on TPCC.STOCK (S_I_ID, S_W_ID)"
set sql(3) "create unique index TPCC.ORDER_LINE_I1 on TPCC.ORDER_LINE_1 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(4) "create unique index TPCC.ORDER_LINE_I2 on TPCC.ORDER_LINE_2 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(5) "create unique index TPCC.ORDER_LINE_I3 on TPCC.ORDER_LINE_3 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(6) "create unique index TPCC.ORDER_LINE_I4 on TPCC.ORDER_LINE_4 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(7) "create unique index TPCC.ORDER_LINE_I5 on TPCC.ORDER_LINE_5 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(8) "create unique index TPCC.ORDER_LINE_I6 on TPCC.ORDER_LINE_6 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(9) "create unique index TPCC.ORDER_LINE_I7 on TPCC.ORDER_LINE_7 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(10) "create unique index TPCC.ORDER_LINE_I8 on TPCC.ORDER_LINE_8 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(11) "create unique index TPCC.ORDER_LINE_I9 on TPCC.ORDER_LINE_9 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(12) "create unique index TPCC.ORDER_LINE_I10 on TPCC.ORDER_LINE_10 (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(13) "create unique index TPCC.ORDERS_I1 on TPCC.ORDERS (O_W_ID, O_D_ID, O_ID)"
set sql(14) "create unique index TPCC.ORDERS_I2 on TPCC.ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID)"
set sql(15) "create unique index TPCC.NEW_ORDER_I1 on TPCC.NEW_ORDER (NO_W_ID, NO_D_ID, NO_O_ID)"
set sql(16) "create unique index TPCC.ITEM_I1 on TPCC.ITEM (I_ID)"
set sql(17) "create unique index TPCC.DISTRICT_I1 on TPCC.DISTRICT (D_W_ID, D_ID)"
set sql(18) "create unique index TPCC.CUSTOMER_I1 on TPCC.CUSTOMER (C_W_ID, C_D_ID, C_ID)"
set sql(19) "create unique index TPCC.CUSTOMER_I2 on TPCC.CUSTOMER (C_LAST, C_W_ID, C_D_ID, C_FIRST, C_ID)"
	}
   } else {
set sql(1) "alter session set sort_area_size=5000000"
set sql(2) "CREATE UNIQUE INDEX CUSTOMER_I1 ON CUSTOMER ( C_W_ID, C_D_ID, C_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(3) "CREATE UNIQUE INDEX CUSTOMER_I2 ON CUSTOMER ( C_LAST, C_W_ID, C_D_ID, C_FIRST, C_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(4) "CREATE UNIQUE INDEX DISTRICT_I1 ON DISTRICT ( D_W_ID, D_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(5) "CREATE UNIQUE INDEX ITEM_I1 ON ITEM (I_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(6) "CREATE UNIQUE INDEX ORDERS_I1 ON ORDERS (O_W_ID, O_D_ID, O_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(7) "CREATE UNIQUE INDEX ORDERS_I2 ON ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(8) "CREATE UNIQUE INDEX STOCK_I1 ON STOCK (S_I_ID, S_W_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
set sql(9) "CREATE UNIQUE INDEX WAREHOUSE_I1 ON WAREHOUSE (W_ID) INITRANS 4 MAXTRANS 16 PCTFREE 10"
	}
for { set i 1 } { $i <= $stmt_cnt } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc CreateDirectory { lda directory tpcc_user } {
set curn1 [ oraopen $lda ]
set sql(1) "CREATE OR REPLACE DIRECTORY tpcc_log AS '$directory'"
set sql(2) "GRANT READ,WRITE ON DIRECTORY tpcc_log TO $tpcc_user"
for { set i 1 } { $i <= 2 } { incr i } {
if {[ catch {orasql $curn1 $sql($i)} message ] } {
puts "$message $sql($i)"
puts [ oramsg $curn1 all ]
			}
		}
oraclose $curn1
return
}

proc ServerSidePackage { lda count_ware } {
set curn1 [ oraopen $lda ]
set sql(1) "CREATE OR REPLACE PACKAGE tpcc_server_side
AUTHID CURRENT_USER 
IS
  PROCEDURE LoadSchema(count_ware NUMBER);
  FUNCTION RandomNumber (p_min NUMBER, p_max NUMBER) RETURN NUMBER;
  FUNCTION NURand (p_const NUMBER, p_x NUMBER, p_y NUMBER, p_c NUMBER)
  RETURN NUMBER;
  FUNCTION Lastname (num NUMBER) RETURN VARCHAR;
  FUNCTION MakeAlphaString (p_x NUMBER, p_y NUMBER) RETURN VARCHAR;
  FUNCTION MakeZip RETURN VARCHAR;
  FUNCTION MakeNumberString RETURN VARCHAR;
END;"
if {[ catch {orasql $curn1 $sql(1)} message ] } {
puts "$message $sql(1)"
puts [ oramsg $curn1 all ]
}

set sql(2) "CREATE OR REPLACE PACKAGE BODY tpcc_server_side
IS
  c_maxitems CONSTANT NUMBER := 100000;
  c_customers_per_district CONSTANT NUMBER := 3000;
  c_districts_per_warehouse CONSTANT NUMBER := 10;
  c_orders_per_district CONSTANT NUMBER := 3000;

  trace_file UTL_FILE.FILE_TYPE;
  trace_directory VARCHAR2(30) := 'TPCC_LOG';

  TYPE namearray IS TABLE OF VARCHAR2(10)
    INDEX BY BINARY_INTEGER;
  namearr namearray;

  TYPE globarray IS TABLE OF CHAR
    INDEX BY BINARY_INTEGER;
  list globarray;

  TYPE numarray IS TABLE OF BINARY_INTEGER
    INDEX BY BINARY_INTEGER;

  TYPE address IS RECORD
  (
    street_1 VARCHAR2(20),
    street_2 VARCHAR2(20),
    city     VARCHAR2(20),
    state    CHAR(2),
    zip      CHAR(9)
  );

  PROCEDURE OpenTrace 
  (
    directory_name VARCHAR2,
    file_name VARCHAR2
  )
  IS
  BEGIN
    trace_file := utl_file.fopen (directory_name,file_name,'a');
  END;
 
  PROCEDURE WriteTrace (s VARCHAR2)
  IS
  BEGIN
    utl_file.put (trace_file,TO_CHAR (SYSDATE,'HH24:MI:SS '));
    utl_file.put_line (trace_file,s);
    utl_file.fflush (trace_file);
  END;

  PROCEDURE CloseTrace
  IS
  BEGIN
    utl_file.fclose (trace_file);
  END;

  FUNCTION RandomNumber (p_min NUMBER, p_max NUMBER) 
  RETURN NUMBER
  IS
  BEGIN
    RETURN TRUNC (ABS (dbms_random.value (p_min,p_max)));
  END;

  FUNCTION NURand (p_const NUMBER, p_x NUMBER, p_y NUMBER, p_c NUMBER)
  RETURN NUMBER
  IS
    l_rand_num NUMBER;
    l_ran1 NUMBER;
    l_ran2 NUMBER;
  BEGIN
    l_ran1 := RandomNumber (0,p_Const); 
    l_ran2 := RandomNumber (p_x,p_y);
    l_rand_num := MOD (l_ran1+l_ran2-BITAND(l_ran1,l_ran2)+p_c, p_y-p_x+1) + p_x;
    RETURN l_rand_num;
  END;

  FUNCTION Lastname (num NUMBER) RETURN VARCHAR
  IS
    name VARCHAR2(20);
  BEGIN
    name := namearr (TRUNC (MOD ((num / 100),10)))||
    namearr (TRUNC (MOD ((num / 10),10)))||
    namearr (TRUNC (MOD ((num / 1),10)));
  
    RETURN name; 
  END;


  FUNCTION MakeAlphaString (p_x NUMBER, p_y NUMBER)
  RETURN VARCHAR
  IS
    l_len NUMBER := RandomNumber (p_x,p_y);
    l_string VARCHAR2(4000) := '';
    l_ch CHAR;
  BEGIN
    FOR i IN 0..l_len - 1 LOOP
      l_ch := list (TRUNC (ABS (dbms_random.value (0,list.COUNT -1))));  
      l_string := l_string || l_ch; 
    END LOOP;
    RETURN l_string;
  END;

  FUNCTION MakeZip 
  RETURN VARCHAR
  IS 
    l_zip VARCHAR2(10) := '000011111';
    l_ranz NUMBER := RandomNumber (0,9999);
    l_len NUMBER := LENGTH (TO_CHAR (l_ranz));
  BEGIN
    l_zip := TO_CHAR (l_ranz) || SUBSTR (l_zip,l_len + 1,9);
    return l_zip;
  END;

  FUNCTION  MakeAddress RETURN address
  IS 
    add address;
  BEGIN
    add.street_1 := MakeAlphaString (10,20);
    add.street_2 := MakeAlphaString (10,20);
    add.city     := MakeAlphaString (10,20);
    add.state    := MakeAlphaString (2,2);
    add.zip      := MakeZip;
    return add;
  END;

  FUNCTION MakeNumberString
  RETURN VARCHAR
  IS
    l_zeroed VARCHAR2(8);
    l_a NUMBER;
    l_b NUMBER;
    l_lena NUMBER;
    l_lenb NUMBER;
    l_c_pa VARCHAR2(8);
    l_c_pb VARCHAR2(8);
  BEGIN
    l_zeroed := '00000000';
    l_a := RandomNumber (0,99999999);
    l_b := RandomNumber (0,99999999);
    l_lena := LENGTH (TO_CHAR (l_a)); 
    l_lenb := LENGTH (TO_CHAR (l_b)); 
    l_c_pa := TO_CHAR (l_a)||SUBSTR (l_zeroed,l_lena + 1);
    l_c_pb := TO_CHAR (l_b)||SUBSTR (l_zeroed,l_lenb + 1);
    RETURN l_c_pa||l_c_pb;
  END;

  PROCEDURE Customer 
  (
    p_d_id NUMBER,
    p_w_id NUMBER,
    p_customers_per_district NUMBER
  )
  IS
    indx PLS_INTEGER := 0;
    lst_indx PLS_INTEGER := 0;
    end_cust PLS_INTEGER := 1;
    l_nrnd NUMBER;
    l_c_add address;

    TYPE l_c_id_aat IS TABLE OF NUMBER(5) INDEX BY PLS_INTEGER;
    TYPE l_c_d_id_aat IS TABLE OF NUMBER(2) INDEX BY PLS_INTEGER;
    TYPE l_c_w_id_aat IS TABLE OF NUMBER(4) INDEX BY PLS_INTEGER;
    TYPE l_c_first_aat IS TABLE OF VARCHAR(16) INDEX BY PLS_INTEGER;
    TYPE l_c_middle_aat IS TABLE OF CHAR(2) INDEX BY PLS_INTEGER;
    TYPE l_c_last_aat IS TABLE OF VARCHAR2(16) INDEX BY PLS_INTEGER;
    TYPE l_c_street_1_aat IS TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;
    TYPE l_c_street_2_aat IS TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;
    TYPE l_c_city_aat IS TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;
    TYPE l_c_state_aat IS TABLE OF CHAR(2) INDEX BY PLS_INTEGER;
    TYPE l_c_zip_aat IS TABLE OF CHAR(9) INDEX BY PLS_INTEGER;
    TYPE l_c_phone_aat IS TABLE OF CHAR(16) INDEX BY PLS_INTEGER;
    TYPE l_c_credit_aat IS TABLE OF CHAR(2) INDEX BY PLS_INTEGER;
    TYPE l_c_credit_lim_aat IS TABLE OF NUMBER(12,2) INDEX BY PLS_INTEGER;
    TYPE l_c_discount_aat IS TABLE OF NUMBER(4,4) INDEX BY PLS_INTEGER;
    TYPE l_c_balance_aat IS TABLE OF NUMBER(12,2) INDEX BY PLS_INTEGER;
    TYPE l_c_data_aat IS TABLE OF VARCHAR2(500) INDEX BY PLS_INTEGER;
    TYPE l_h_amount_aat IS TABLE OF HISTORY.H_AMOUNT%TYPE INDEX BY PLS_INTEGER;
    TYPE l_h_data_aat IS TABLE OF HISTORY.H_DATA%TYPE INDEX BY PLS_INTEGER;

l_c_id l_c_id_aat;
l_c_d_id l_c_d_id_aat;
l_c_w_id l_c_w_id_aat;
l_c_first l_c_first_aat;
l_c_middle l_c_middle_aat;
l_c_last l_c_last_aat;
l_c_street_1 l_c_street_1_aat;
l_c_street_2 l_c_street_2_aat;
l_c_city l_c_city_aat;
l_c_state l_c_state_aat;
l_c_zip l_c_zip_aat;
l_c_phone l_c_phone_aat;
l_c_credit l_c_credit_aat; 
l_c_credit_lim l_c_credit_lim_aat;
l_c_discount l_c_discount_aat;
l_c_balance l_c_balance_aat;
l_c_data l_c_data_aat;
l_h_amount l_h_amount_aat;
l_h_data l_h_data_aat;

  BEGIN
    WriteTrace ('Loading Customer for D='||p_d_id||' W='||p_w_id);

    FOR i IN 1 ..p_customers_per_district LOOP
      l_c_id(i) := i;
      l_c_d_id(i) := p_d_id;
      l_c_w_id(i) := p_w_id;
      l_c_first(i) := MakeAlphaString (8,16);
      l_c_middle(i) := 'OE';
      IF l_c_id(i) <= 1000 THEN
        l_c_last(i) := LastName (l_c_id(i) - 1);
      ELSE
        l_nrnd := NURand (255,0,999,123);
        l_c_last(i) := LastName (l_nrnd);
      END IF;
      l_c_add := MakeAddress;
        l_c_street_1(i) := l_c_add.street_1;
        l_c_street_2(i) := l_c_add.street_2;
        l_c_city(i) := l_c_add.city;
        l_c_state(i) := l_c_add.state;
        l_c_zip(i) := l_c_add.zip; 

      l_c_phone(i) := MakeNumberString;
      IF RandomNumber (0,1) = 1  THEN
        l_c_credit(i) := 'GC';
      ELSE
        l_c_credit(i) := 'BC';
      END IF;
      l_c_credit_lim(i) := 50000;
      l_c_discount(i) := RandomNumber (0,50) / 100.0;
      l_c_balance(i) := -10;
      l_c_data(i) := MakeAlphaString (300,500);

      l_h_amount(i) := 10;
      l_h_data(i) := MakeAlphastring (12,24);
   
      IF MOD (l_c_id(i) ,1000) = 0 THEN

IF
l_c_id(i) = p_customers_per_district
THEN
end_cust := 0;
END IF;

	FORALL indx IN l_c_id.FIRST .. l_c_id.LAST - end_cust
 INSERT INTO customer 
      (
        c_id, 
        c_d_id, 
        c_w_id, 
        c_first, 
        c_middle, 
        c_last, 
        c_street_1, 
        c_street_2, 
        c_city, 
        c_state, 
        c_zip, 
        c_phone, 
        c_since, 
        c_credit, 
        c_credit_lim, 
        c_discount, 
        c_balance, 
        c_data, 
        c_ytd_payment, 
        c_payment_cnt, 
        c_delivery_cnt
      ) 
      VALUES 
      (
        l_c_id(indx), 
        l_c_d_id(indx), 
        l_c_w_id(indx), 
        l_c_first(indx), 
        l_c_middle(indx), 
        l_c_last(indx), 
        l_c_street_1(indx), 
        l_c_street_2(indx), 
        l_c_city(indx), 
        l_c_state(indx), 
        l_c_zip(indx), 
        l_c_phone(indx), 
        SYSDATE,
        l_c_credit(indx), 
        l_c_credit_lim(indx), 
        l_c_discount(indx), 
        l_c_balance(indx), 
        l_c_data(indx), 
        10.0, 
        1, 
        0
      );
COMMIT;

FORALL indx IN l_c_id.FIRST .. l_c_id.LAST - end_cust
      INSERT INTO history 
      (
        h_c_id, 
        h_c_d_id, 
        h_c_w_id, 
        h_w_id, 
        h_d_id, 
        h_date, 
        h_amount, 
        h_data
      ) 
      VALUES 
      ( 
        l_c_id(indx),  
        l_c_d_id(indx),  
        l_c_w_id(indx),  
        l_c_w_id(indx),  
        l_c_d_id(indx),  
        SYSDATE,
        l_h_amount(indx),  
        l_h_data(indx)
      );
COMMIT;

l_c_id.delete(lst_indx,i-1);
l_c_d_id.delete(lst_indx,i-1);
l_c_w_id.delete(lst_indx,i-1);
l_c_first.delete(lst_indx,i-1);
l_c_middle.delete(lst_indx,i-1);
l_c_last.delete(lst_indx,i-1);
l_c_street_1.delete(lst_indx,i-1);
l_c_street_2.delete(lst_indx,i-1);
l_c_city.delete(lst_indx,i-1);
l_c_state.delete(lst_indx,i-1);
l_c_zip.delete(lst_indx,i-1);
l_c_phone.delete(lst_indx,i-1);
l_c_credit.delete(lst_indx,i-1);
l_c_credit_lim.delete(lst_indx,i-1);
l_c_discount.delete(lst_indx,i-1);
l_c_balance.delete(lst_indx,i-1);
l_c_data.delete(lst_indx,i-1);
l_h_amount.delete(lst_indx,i-1);
l_h_data.delete(lst_indx,i-1);

	lst_indx :=i-1;

      END IF;
 
      IF MOD (l_c_id(i) ,1000) = 0 THEN
	WriteTrace ('Loading Customer '||l_c_id(i));
      END IF;
    END LOOP;
    WriteTrace ('Customer Done');
  END;



  PROCEDURE Orders 
  (
    p_d_id NUMBER, 
    p_w_id NUMBER, 
    p_maxitems NUMBER,
    p_orders_per_district NUMBER
  )
  IS
  indx PLS_INTEGER := 0;
  jndx PLS_INTEGER := 0;
    lst_indx PLS_INTEGER := 0;
    lst_jndx PLS_INTEGER := 0;
    ol_total PLS_INTEGER := 0;
    end_order PLS_INTEGER := 1;
   end_ol PLS_INTEGER := 1;
    l_cust numarray;
    l_r NUMBER;
    l_t NUMBER;
TYPE l_o_d_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_o_w_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_o_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_o_c_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_o_carrier_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_o_ol_cnt_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_ol_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_ol_i_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_ol_supply_w_id_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_ol_quantity_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_ol_amount_aat IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
TYPE l_ol_dist_info_aat IS TABLE OF CHAR(24) INDEX BY PLS_INTEGER;
TYPE l_ol_delivery_d_aat IS TABLE OF DATE INDEX BY PLS_INTEGER;
    l_o_d_id l_o_d_id_aat;
    l_o_w_id l_o_w_id_aat;
    l_o_id l_o_id_aat;
    no_l_o_d_id l_o_d_id_aat;
    no_l_o_w_id l_o_w_id_aat;
    no_l_o_id l_o_id_aat;
    oli_l_o_id l_o_id_aat;
    oli_l_o_d_id l_o_d_id_aat;
    oli_l_o_w_id l_o_w_id_aat;
    l_o_c_id l_o_c_id_aat;
    l_o_carrier_id l_o_carrier_id_aat;
    l_o_ol_cnt l_o_ol_cnt_aat; 
    l_ol l_ol_aat;
    l_ol_i_id l_ol_i_id_aat; 
    l_ol_supply_w_id l_ol_supply_w_id_aat;
    l_ol_quantity l_ol_quantity_aat;
    l_ol_amount l_ol_amount_aat;
    l_ol_dist_info l_ol_dist_info_aat;
    l_ol_delivery_d l_ol_delivery_d_aat;
  BEGIN
    WriteTrace ('Loading Orders for D='||p_d_id||' W='||p_w_id);

    FOR i IN 0..p_orders_per_district LOOP
      l_cust (i) := 1;
    END LOOP;

    FOR i IN 0..p_orders_per_district LOOP
      l_r := RandomNumber (i,p_orders_per_district);
      l_t := l_cust(i);
      l_cust (i) := l_cust (l_r);
      l_cust (l_r) := l_t;
    END LOOP;

    FOR i IN 1..p_orders_per_district LOOP
l_o_d_id(i) := p_d_id;
l_o_w_id(i) := p_w_id;
      l_o_id(i) := i;
      l_o_c_id(i) := l_cust (l_o_id(i));

IF l_o_id(i) > 2100 THEN
 no_l_o_d_id(i) := l_o_d_id(i);
 no_l_o_w_id(i) := l_o_w_id(i);
 no_l_o_id(i) := l_o_id(i);
 l_o_carrier_id(i) := NULL;
ELSE
      l_o_carrier_id(i) := RandomNumber (1,10);
END IF;
 
     l_o_ol_cnt(i) := RandomNumber (5,15);  

FOR j IN 1 ..l_o_ol_cnt(i) LOOP
ol_total := ol_total + 1;
IF l_o_id(i) > 2100 THEN
l_ol_amount(ol_total) := 0;
l_ol_delivery_d(ol_total) := NULL;
ELSE
l_ol_amount(ol_total) := RandomNumber (10,10000) / 100;
l_ol_delivery_d(ol_total) := SYSDATE;
END IF;
    oli_l_o_id(ol_total) := l_o_id(i);
    oli_l_o_d_id(ol_total) := l_o_d_id(i);
    oli_l_o_w_id(ol_total) := l_o_w_id(i);
        l_ol(ol_total) := j;	
        l_ol_i_id(ol_total) := RandomNumber (1,p_maxitems);
        l_ol_supply_w_id(ol_total) := l_o_w_id(i);
        l_ol_quantity(ol_total) := 5;
        l_ol_dist_info(ol_total) := MakeAlphaString (24,24);
END LOOP;

    IF MOD (l_o_id(i),1000) = 0 THEN
        WriteTrace ('...'||l_o_id(i));
IF
l_o_id(i) = p_orders_per_district
THEN
end_order := 0;
END IF;
FORALL indx IN l_o_id.FIRST .. l_o_id.LAST - end_order
        INSERT INTO orders 
        (
          o_id, 
          o_c_id, 
          o_d_id, 
          o_w_id, 
          o_entry_d, 
          o_carrier_id, 
          o_ol_cnt, 
          o_all_local
        ) 
        VALUES 
        ( 
          l_o_id(indx), 
          l_o_c_id(indx), 
          l_o_d_id(indx), 
          l_o_w_id(indx), 
          SYSDATE,
          l_o_carrier_id(indx), 
          l_o_ol_cnt(indx), 
          1
        );

COMMIT;

FORALL indx IN no_l_o_id.FIRST .. no_l_o_id.LAST - end_order
      INSERT INTO new_order 
        (
          no_o_id, 
          no_d_id, 
          no_w_id
        ) 
        VALUES 
        (
          no_l_o_id(indx), 
          no_l_o_d_id(indx), 
          no_l_o_w_id(indx)
        );

COMMIT;
     
FORALL jndx IN oli_l_o_id.FIRST .. oli_l_o_id.LAST - end_order
       INSERT INTO order_line 
         (
           ol_o_id, 
           ol_d_id, 
           ol_w_id, 
           ol_number, 
           ol_i_id, 
            ol_supply_w_id, 
           ol_quantity, 
          ol_amount, 
          ol_dist_info, 
            ol_delivery_d
         ) 
         VALUES 
         (
           oli_l_o_id(jndx), 
           oli_l_o_d_id(jndx), 
            oli_l_o_w_id(jndx), 
            l_ol(jndx), 
           l_ol_i_id(jndx), 
           l_ol_supply_w_id(jndx), 
           l_ol_quantity(jndx), 
          l_ol_amount(jndx), 
           l_ol_dist_info(jndx), 
	l_ol_delivery_d(jndx)
         );

      COMMIT;

 	oli_l_o_id.delete(lst_jndx,ol_total-1); 
        oli_l_o_d_id.delete(lst_jndx,ol_total-1); 
        oli_l_o_w_id.delete(lst_jndx,ol_total-1);  
        l_ol.delete(lst_jndx,ol_total-1); 
        l_ol_i_id.delete(lst_jndx,ol_total-1); 
        l_ol_supply_w_id.delete(lst_jndx,ol_total-1);  
        l_ol_quantity.delete(lst_jndx,ol_total-1); 
        l_ol_amount.delete(lst_jndx,ol_total-1);  
        l_ol_dist_info.delete(lst_jndx,ol_total-1);  
	l_ol_delivery_d.delete(lst_jndx,ol_total-1); 

	lst_jndx := ol_total-1;

    l_o_d_id.delete(lst_indx,i-1);
    l_o_w_id.delete(lst_indx,i-1);
    l_o_id.delete(lst_indx,i-1);
    l_o_c_id.delete(lst_indx,i-1);
    l_o_carrier_id.delete(lst_indx,i-1);
    l_o_ol_cnt.delete(lst_indx,i-1); 
	
	lst_indx := i-1;


END IF;
    END LOOP;

    COMMIT;

    WriteTrace ('Orders Done');
  END;

PROCEDURE LoadItems (p_maxitems NUMBER)
  IS
    indx PLS_INTEGER := 0;
    lst_indx PLS_INTEGER := 0;
    end_item PLS_INTEGER := 1;
    l_orig numarray;
    l_first NUMBER;
    TYPE l_i_id_aat IS TABLE OF ITEM.I_ID%TYPE 
    INDEX BY PLS_INTEGER;
    TYPE l_i_im_id_aat IS TABLE OF ITEM.I_IM_ID%TYPE 
    INDEX BY PLS_INTEGER;
    TYPE l_i_name_aat IS TABLE OF ITEM.I_NAME%TYPE 
    INDEX BY PLS_INTEGER;
    TYPE l_i_price_aat IS TABLE OF ITEM.I_PRICE%TYPE 
    INDEX BY PLS_INTEGER;
    TYPE l_i_data_aat IS TABLE OF ITEM.I_DATA%TYPE 
    INDEX BY PLS_INTEGER;

    l_i_id	l_i_id_aat;
    l_i_im_id   l_i_im_id_aat;
    l_i_name	l_i_name_aat;
    l_i_price	l_i_price_aat;
    l_i_data	l_i_data_aat;

  BEGIN
    WriteTrace ('Loading Items');
  
    FOR i IN 0..p_maxitems - 1 LOOP
      l_orig(i) := 0;
    END LOOP;

    FOR i IN 0..(p_maxitems / 10) - 1 LOOP
      l_orig(RandomNumber (0,p_maxitems - 1)) := 1;
    END LOOP;

    FOR i IN 1..p_maxitems LOOP

      l_i_id(i)    := i;
      l_i_im_id(i) := RandomNumber (1,10000);
      l_i_name(i)  := MakeAlphaString (14,24);
      l_i_price(i) := TRUNC (RandomNumber (100,10000) / 100,2);
      l_i_data(i)  := MakeAlphaString (26,50);
      IF l_orig (i - 1) = 1 THEN
        l_first := RandomNumber (0,LENGTH (l_i_data(i)) - 8);
        l_i_data(i) := SUBSTR (l_i_data(i),0,l_first)||
        'original'||SUBSTR (l_i_data(i),l_first + 8);
      END IF;

IF MOD (l_i_id(i),10000) = 0
      THEN 
IF
l_i_id(i) = p_maxitems
THEN
end_item := 0;
END IF;
	FORALL indx IN l_i_id.FIRST .. l_i_id.LAST - end_item
      INSERT INTO item 
      (i_id, i_im_id, i_name, i_price, i_data) VALUES (l_i_id(indx), l_i_im_id(indx), l_i_name(indx), l_i_price(indx), l_i_data(indx));

      COMMIT;

l_i_id.delete(lst_indx,i-1);
l_i_im_id.delete(lst_indx,i-1);
l_i_name.delete(lst_indx,i-1);
l_i_price.delete(lst_indx,i-1);
l_i_data.delete(lst_indx,i-1);
lst_indx := i-1;
      
END IF;
     
      IF MOD (l_i_id(i),20000) = 0
      THEN  
        WriteTrace ('Loading Items - '||l_i_id(i));
      END IF;
    END LOOP;

    WriteTrace ('Items Done');
  END;


  PROCEDURE LoadStock (p_w_id NUMBER,p_maxitems NUMBER)
  IS
    indx PLS_INTEGER := 0;
    lst_indx PLS_INTEGER := 0;
    end_stock PLS_INTEGER := 1;
    l_orig numarray;
    l_first NUMBER;
    TYPE l_s_w_id_aat IS TABLE OF STOCK.S_W_ID%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_i_id_aat IS TABLE OF STOCK.S_I_ID%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_quantity_aat IS TABLE OF STOCK.S_QUANTITY%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_01_aat IS TABLE OF STOCK.S_DIST_01%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_02_aat IS TABLE OF STOCK.S_DIST_02%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_03_aat IS TABLE OF STOCK.S_DIST_03%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_04_aat IS TABLE OF STOCK.S_DIST_04%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_05_aat IS TABLE OF STOCK.S_DIST_05%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_06_aat IS TABLE OF STOCK.S_DIST_06%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_07_aat IS TABLE OF STOCK.S_DIST_07%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_08_aat IS TABLE OF STOCK.S_DIST_08%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_09_aat IS TABLE OF STOCK.S_DIST_09%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_dist_10_aat IS TABLE OF STOCK.S_DIST_10%TYPE INDEX BY PLS_INTEGER;
    TYPE l_s_data_aat IS TABLE OF STOCK.S_DATA%TYPE INDEX BY PLS_INTEGER;  
  
    l_s_w_id l_s_w_id_aat;
    l_s_i_id l_s_i_id_aat;
    l_s_quantity l_s_quantity_aat;
    l_s_dist_01 l_s_dist_01_aat;
    l_s_dist_02 l_s_dist_02_aat;
    l_s_dist_03 l_s_dist_03_aat;
    l_s_dist_04 l_s_dist_04_aat;
    l_s_dist_05 l_s_dist_05_aat;
    l_s_dist_06 l_s_dist_06_aat;
    l_s_dist_07 l_s_dist_07_aat;
    l_s_dist_08 l_s_dist_08_aat;
    l_s_dist_09 l_s_dist_09_aat;
    l_s_dist_10 l_s_dist_10_aat;
    l_s_data l_s_data_aat;
  

  BEGIN
    WriteTrace ('Loading Stock W='||p_w_id);
  
    FOR i IN 0..p_maxitems - 1 LOOP
      l_orig(i) := 0;
    END LOOP;

    FOR i IN 0..(p_maxitems / 10) - 1 LOOP
      l_orig(RandomNumber (0,p_maxitems - 1)) := 1;
    END LOOP;

    FOR i IN 1..p_maxitems LOOP
      l_s_w_id(i) := p_w_id;
      l_s_i_id(i) := i;
      l_s_quantity(i) := RandomNumber (10,100);
      l_s_dist_01(i) := MakeAlphaString (24,24);
      l_s_dist_02(i) := MakeAlphaString (24,24);
      l_s_dist_03(i) := MakeAlphaString (24,24);
      l_s_dist_04(i) := MakeAlphaString (24,24);
      l_s_dist_05(i) := MakeAlphaString (24,24);
      l_s_dist_06(i) := MakeAlphaString (24,24);
      l_s_dist_07(i) := MakeAlphaString (24,24);
      l_s_dist_08(i) := MakeAlphaString (24,24);
      l_s_dist_09(i) := MakeAlphaString (24,24);
      l_s_dist_10(i) := MakeAlphaString (24,24);
      l_s_data(i) := MakeAlphaString (26,50);
      IF l_orig (i - 1) = 1 THEN
        l_first := RandomNumber (0,LENGTH (l_s_data(i)) - 8);
        l_s_data(i) := SUBSTR (l_s_data(i),0,l_first) || 'original' || SUBSTR (l_s_data(i),l_first + 8);
      END IF;
 
      IF MOD (l_s_i_id(i),10000) = 0
      THEN 
IF
l_s_i_id(i) = p_maxitems
THEN
end_stock := 0;
END IF;
      FORALL indx IN l_s_i_id.FIRST .. l_s_i_id.LAST - end_stock
      INSERT INTO STOCK  
      (
        s_i_id, 
        s_w_id, 
        s_quantity, 
        s_dist_01, 
        s_dist_02, 
        s_dist_03, 
        s_dist_04, 
        s_dist_05, 
        s_dist_06, 
        s_dist_07, 
        s_dist_08, 
        s_dist_09, 
        s_dist_10, 
        s_data, 
        s_ytd, 
        s_order_cnt, 
        s_remote_cnt
      ) 
      VALUES 
      (
        l_s_i_id(indx), 
        l_s_w_id(indx), 
        l_s_quantity(indx), 
        l_s_dist_01(indx), 
        l_s_dist_02(indx), 
        l_s_dist_03(indx), 
        l_s_dist_04(indx), 
        l_s_dist_05(indx), 
        l_s_dist_06(indx), 
        l_s_dist_07(indx), 
        l_s_dist_08(indx), 
        l_s_dist_09(indx), 
        l_s_dist_10(indx), 
        l_s_data(indx), 
        0, 
        0, 
        0
      );

	COMMIT;

    	l_s_i_id.delete(lst_indx,i-1); 
        l_s_w_id.delete(lst_indx,i-1); 
        l_s_quantity.delete(lst_indx,i-1); 
        l_s_dist_01.delete(lst_indx,i-1);
        l_s_dist_02.delete(lst_indx,i-1); 
        l_s_dist_03.delete(lst_indx,i-1); 
        l_s_dist_04.delete(lst_indx,i-1); 
        l_s_dist_05.delete(lst_indx,i-1); 
        l_s_dist_06.delete(lst_indx,i-1); 
        l_s_dist_07.delete(lst_indx,i-1); 
        l_s_dist_08.delete(lst_indx,i-1); 
        l_s_dist_09.delete(lst_indx,i-1); 
        l_s_dist_10.delete(lst_indx,i-1); 
        l_s_data.delete(lst_indx,i-1);

	lst_indx := i-1;

      END IF;
 
      IF MOD (l_s_i_id(i),20000) = 0
      THEN 
        WriteTrace ('Loading Stock '|| l_s_i_id(i));        
      END IF;

    END LOOP;

    COMMIT;
    WriteTrace ('Stock Done');
  END;

  PROCEDURE LoadDistrict (p_w_id NUMBER,p_districts_per_warehouse NUMBER)
  IS
    l_d_w_id NUMBER;
    l_d_ytd NUMBER;
    l_d_next_o_id NUMBER;
    l_d_id NUMBER;
    l_d_name VARCHAR2(10);
    l_d_add address;
    l_d_tax NUMBER;
  BEGIN
    WriteTrace ('Loading District');

    l_d_w_id := p_w_id;
    l_d_ytd := 30000;
    l_d_next_o_id := 3001;
    FOR i IN 1 .. p_districts_per_warehouse LOOP
      l_d_id := i;
      l_d_name := MakeAlphaString (6,10);
      l_d_add  := MakeAddress;
      l_d_tax := TRUNC (RandomNumber (10,20) / 100.0,2);

      INSERT INTO DISTRICT 
      (
        d_id, 
        d_w_id, 
        d_name, 
        d_street_1, 
        d_street_2, 
        d_city, 
        d_state, 
        d_zip, 
        d_tax, 
        d_ytd, 
        d_next_o_id
      ) 
      VALUES 
      (
        l_d_id, 
        l_d_w_id, 
        l_d_name, 
        l_d_add.street_1, 
        l_d_add.street_2, 
        l_d_add.city, 
        l_d_add.state, 
        l_d_add.zip, 
        l_d_tax, 
        l_d_ytd, 
        l_d_next_o_id
      );
    END LOOP;

    COMMIT;
    WriteTrace ('District done');
  END;

  PROCEDURE LoadWarehouses
  (
    p_count_ware NUMBER,
    p_maxitems NUMBER,
    p_districts_per_warehouse NUMBER
  )
  IS
    w_id NUMBER;
    w_name VARCHAR2(10);
    w_tax NUMBER;
    w_ytd NUMBER;
    w_add ADDRESS;
  BEGIN
    WriteTrace ('Loading Warehouses');

    FOR i IN 1..p_count_ware LOOP
      w_id := i;
      w_name := MakeAlphaString (6,10);
      w_add  := MakeAddress;
      w_tax := TRUNC (RandomNumber (10,20) / 100.0,2);
      w_ytd := 3000000;

      INSERT INTO WAREHOUSE 
      (
        w_id, 
        w_name, 
        w_street_1, 
        w_street_2, 
        w_city, 
        w_state, 
        w_zip, 
        w_tax, 
        w_ytd
      ) 
      VALUES 
      (
        w_id, 
        w_name, 
        w_add.street_1, 
        w_add.street_2, 
        w_add.city, 
        w_add.state, 
        w_add.zip, 
        w_tax, 
        w_ytd
      );
      LoadStock (w_id,c_maxitems);
      LoadDistrict (w_id,c_districts_per_warehouse);
      COMMIT;
    END LOOP;

    WriteTrace ('Warehouses done');
  END;

  PROCEDURE LoadCustomers 
  ( 
    p_count_ware NUMBER,
    p_customers_per_district NUMBER,
    p_districts_per_warehouse NUMBER
  )
  IS
    l_w_id NUMBER;
    l_d_id NUMBER;
  BEGIN
    WriteTrace ('Loading Customers');

    FOR i IN 1..p_count_ware LOOP
      l_w_id := i;
      FOR j IN 1..p_districts_per_warehouse LOOP
        l_d_id := j;
        Customer (l_d_id,l_w_id,p_customers_per_district);
      END LOOP;
    END LOOP;
    COMMIT;
    WriteTrace ('Customers done');
  END;

  PROCEDURE LoadOrders 
  ( 
    p_count_ware NUMBER,
    p_maxitems NUMBER,
    p_orders_per_district NUMBER,
    p_districts_per_warehouse NUMBER
  )
  IS
    l_w_id NUMBER;
    l_d_id NUMBER;
  BEGIN
    WriteTrace ('Loading Orders');
    FOR i IN 1..p_count_ware LOOP
      l_w_id := i;
      FOR j IN 1..p_districts_per_warehouse LOOP 
        l_d_id := j;
        Orders (l_d_id,l_w_id,p_maxitems,p_orders_per_district);
      END LOOP;
    END LOOP;
    COMMIT;
    WriteTrace ('Orders done');
  END;

  PROCEDURE LoadSchema(count_ware NUMBER) IS 
  BEGIN
    OpenTrace ('TPCC_LOG','tpcc_load.log');

    WriteTrace ('Loading Schema');

    LoadItems (c_maxitems);
    LoadWarehouses (count_ware,c_maxitems,c_districts_per_warehouse);
    LoadCustomers (count_ware,c_customers_per_district,c_districts_per_warehouse);
    LoadOrders (count_ware,c_maxitems,c_orders_per_district,c_districts_per_warehouse);
  
    WriteTrace ('Schema Load done');

    CloseTrace;
  END;

BEGIN
  namearr(0) := 'BAR';
  namearr(1) := 'OUGHT';
  namearr(2) := 'ABLE';
  namearr(3) := 'PRI';
  namearr(4) := 'PRES';
  namearr(5) := 'ESE';
  namearr(6) := 'ANTI';
  namearr(7) := 'CALLY';
  namearr(8) := 'ATION';
  namearr(9) := 'EING';

  list(0) := '0';
  list(1) := '1';
  list(2) := '2';
  list(3) := '3';
  list(4) := '4';
  list(5) := '5';
  list(6) := '6';
  list(7) := '7';
  list(8) := '8';
  list(9) := '9';
  list(10) := 'A';
  list(11) := 'B';
  list(12) := 'C';
  list(13) := 'D';
  list(14) := 'E';
  list(15) := 'F';
  list(16) := 'G';
  list(17) := 'H';
  list(18) := 'I';
  list(19) := 'J';
  list(20) := 'K';
  list(21) := 'L';
  list(22) := 'M';
  list(23) := 'N';
  list(24) := 'O';
  list(25) := 'P';
  list(26) := 'Q';
  list(27) := 'R';
  list(28) := 'S';
  list(29) := 'T';
  list(30) := 'U';
  list(31) := 'V';
  list(32) := 'W';
  list(33) := 'X';
  list(34) := 'Y';
  list(35) := 'Z';
  list(36) := 'a';
  list(37) := 'b';
  list(38) := 'c';
  list(39) := 'd';
  list(40) := 'e';
  list(41) := 'f';
  list(42) := 'g';
  list(43) := 'h';
  list(44) := 'i';
  list(45) := 'j';
  list(46) := 'k';
  list(47) := 'l';
  list(48) := 'm';
  list(49) := 'n';
  list(50) := 'o';
  list(51) := 'p';
  list(52) := 'q';
  list(53) := 'r';
  list(54) := 's';
  list(55) := 't';
  list(56) := 'u';
  list(57) := 'v';
  list(58) := 'w';
  list(59) := 'x';
  list(60) := 'y';
  list(61) := 'z';
END;"
if {[ catch {orasql $curn1 $sql(2)} message ] } {
puts "$message $sql(2)"
puts [ oramsg $curn1 all ]
}
set sql(3) "BEGIN tpcc_server_side.loadschema('$count_ware'); END;"
if {[ catch {orasql $curn1 $sql(3)} message ] } {
puts "$message $sql(3)"
puts [ oramsg $curn1 all ]
}
oraclose $curn1
return
}

proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }

proc SetNLS { lda } {
set curn_nls [oraopen $lda ]
set nls(1) "alter session set NLS_LANGUAGE = AMERICAN"
set nls(2) "alter session set NLS_TERRITORY = AMERICA"
for { set i 1 } { $i <= 2 } { incr i } {
if {[ catch {orasql $curn_nls $nls($i)} message ] } {
puts "$message $nls($i)"
puts [ oramsg $curn_nls all ]
			}
	}
oraclose $curn_nls
}

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
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

proc TTCustomer { lda d_id w_id CUST_PER_DIST } {
#Single Row Insert Procedure kept distinct in event of OCI Batch Inserts work against TimesTen 
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
set curn5 [oraopen $lda ]
set sql "INSERT INTO customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) values (:c_id, :c_d_id, :c_w_id, :c_first, :c_middle, :c_last, :c_street_1, :c_street_2, :c_city, :c_state, :c_zip, :c_phone, to_date(:timestamp,'YYYYMMDDHH24MISS'), :c_credit, :c_credit_lim, :c_discount, :c_balance, :c_data, 10.0, 1, 0)"
oraparse $curn5 $sql
set curn6 [oraopen $lda ]
set sql2 "INSERT INTO history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) values (:c_id, :c_d_id, :c_w_id, :c_w_id, :c_d_id, to_date(:timestamp,'YYYYMMDDHH24MISS'), :h_amount, :h_data)"
oraparse $curn6 $sql2
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
orabind $curn5 :c_id $c_id :c_d_id $c_d_id :c_w_id $c_w_id :c_first $c_first :c_middle $c_middle :c_last $c_last :c_street_1 [ lindex $c_add 0 ] :c_street_2 [ lindex $c_add 1 ] :c_city [ lindex $c_add 2 ] :c_state [ lindex $c_add 3 ] :c_zip [ lindex $c_add 4 ] :c_phone $c_phone :timestamp [ gettimestamp ] :c_credit $c_credit :c_credit_lim $c_credit_lim :c_discount $c_discount :c_balance $c_balance :c_data $c_data
if {[ catch {oraexec $curn5} message ] } {
puts "Error in cursor 5:$curn5 $message"
puts [ oramsg $curn5 all ]
}
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
orabind $curn6 :c_id $c_id :c_d_id $c_d_id :c_w_id $c_w_id :c_w_id $c_w_id :c_d_id $c_d_id :timestamp [ gettimestamp ] :h_amount $h_amount :h_data $h_data
if {[ catch {oraexec $curn6} message ] } {
puts "Error in cursor 6:$curn6 $message"
puts [ oramsg $curn6 all ]
		}
	}
oracommit $lda
oraclose $curn5
oraclose $curn6
puts "Customer Done"
return
}

proc TTOrders { lda d_id w_id MAXITEMS ORD_PER_DIST num_part } {
#Single Row Insert Procedure kept distinct in event of OCI Batch Inserts work against TimesTen 
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Orders for D=$d_id W=$w_id"
if { $num_part != 0 } {
set mywid $w_id
if { $mywid > 10 } { set mywid [ expr $mywid % 10 ] }
if { $mywid eq 0 } { set mywid 10 }
	}
set curn7 [ oraopen $lda ]
set sql "INSERT INTO orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values (:o_id, :o_c_id, :o_d_id, :o_w_id, to_date(:timestamp,'YYYYMMDDHH24MISS'), NULL, :o_ol_cnt, 1)"
oraparse $curn7 $sql
set curn8 [ oraopen $lda ]
set sql2 "INSERT INTO new_order (no_o_id, no_d_id, no_w_id) values (:o_id, :o_d_id, :o_w_id)"
oraparse $curn8 $sql2
set curn9 [ oraopen $lda ]
set sql3 "INSERT INTO orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values (:o_id, :o_c_id, :o_d_id, :o_w_id, to_date(:timestamp,'YYYYMMDDHH24MISS'), :o_carrier_id, :o_ol_cnt, 1)"
oraparse $curn9 $sql3
if { $num_part eq 0 } {
set curn10 [ oraopen $lda ]
set sql4 "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values (:o_id, :o_d_id, :o_w_id, :ol, :ol_i_id, :ol_supply_w_id, :ol_quantity, :ol_amount, :ol_dist_info, NULL)"
oraparse $curn10 $sql4
set curn11 [ oraopen $lda ]
set sql5 "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values (:o_id, :o_d_id, :o_w_id, :ol, :ol_i_id, :ol_supply_w_id, :ol_quantity, :ol_amount, :ol_dist_info, to_date(:timestamp,'YYYYMMDDHH24MISS'))"
oraparse $curn11 $sql5
	} else {
set curn10 [ oraopen $lda ]
set sql4 "INSERT INTO order_line_$mywid (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values (:o_id, :o_d_id, :o_w_id, :ol, :ol_i_id, :ol_supply_w_id, :ol_quantity, :ol_amount, :ol_dist_info, NULL)"
oraparse $curn10 $sql4
set curn11 [ oraopen $lda ]
set sql5 "INSERT INTO order_line_$mywid (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values (:o_id, :o_d_id, :o_w_id, :ol, :ol_i_id, :ol_supply_w_id, :ol_quantity, :ol_amount, :ol_dist_info, to_date(:timestamp,'YYYYMMDDHH24MISS'))"
oraparse $curn11 $sql5
	}
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
orabind $curn7 :o_id $o_id :o_c_id $o_c_id :o_d_id $o_d_id :o_w_id $o_w_id :timestamp [ gettimestamp ] :o_ol_cnt $o_ol_cnt
if {[ catch {oraexec $curn7} message ] } {
puts "Error in cursor 7:$curn7 $message"
puts [ oramsg $curn7 all ]
}
set e "no1"
orabind $curn8 :o_id $o_id :o_d_id $o_d_id :o_w_id $o_w_id
if {[ catch {oraexec $curn8} message ] } {
puts "Error in cursor 8:$curn8 $message"
puts [ oramsg $curn8 all ]
}
  } else {
  set e "o3"
orabind $curn9 :o_id $o_id :o_c_id $o_c_id :o_d_id $o_d_id :o_w_id $o_w_id :timestamp [ gettimestamp ] :o_carrier_id $o_carrier_id :o_ol_cnt $o_ol_cnt
if {[ catch {oraexec $curn9} message ] } {
puts "Error in cursor 9:$curn9 $message"
puts [ oramsg $curn9 all ]
		}
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
orabind $curn10 :o_id $o_id :o_d_id $o_d_id :o_w_id $o_w_id :ol $ol :ol_i_id $ol_i_id :ol_supply_w_id $ol_supply_w_id :ol_quantity $ol_quantity :ol_amount $ol_amount :ol_dist_info $ol_dist_info
if {[ catch {oraexec $curn10} message ] } {
puts "Error in cursor 10:$curn10 $message"
puts [ oramsg $curn10 all ]
	}
   } else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
orabind $curn11 :o_id $o_id :o_d_id $o_d_id :o_w_id $o_w_id :ol $ol :ol_i_id $ol_i_id :ol_supply_w_id $ol_supply_w_id :ol_quantity $ol_quantity :ol_amount $ol_amount :ol_dist_info $ol_dist_info :timestamp [ gettimestamp ]
if {[ catch {oraexec $curn11} message ] } {
puts "Error in cursor 11:$curn11 $message"
puts [ oramsg $curn11 all ]
				}
			}
		}
 if { ![ expr {$o_id % 50000} ] } {
	puts "...$o_id"
	oracommit $lda
			}
		}
	oracommit $lda
        oraclose $curn7
        oraclose $curn8
        oraclose $curn9
        oraclose $curn10
        oraclose $curn11
	puts "Orders Done"
	return;
	}

proc TTStock { lda w_id MAXITEMS } {
#Single Row Insert Procedure kept distinct in event of OCI Batch Inserts work against TimesTen 
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Stock Wid=$w_id"
set curn3 [oraopen $lda ]
set sql "INSERT INTO STOCK (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) values (:s_i_id, :s_w_id, :s_quantity, :s_dist_01, :s_dist_02, :s_dist_03, :s_dist_04, :s_dist_05, :s_dist_06, :s_dist_07, :s_dist_08, :s_dist_09, :s_dist_10, :s_data, 0, 0, 0)"
oraparse $curn3 $sql
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
orabind $curn3 :s_i_id $s_i_id :s_w_id $s_w_id :s_quantity $s_quantity :s_dist_01 $s_dist_01 :s_dist_02 $s_dist_02 :s_dist_03 $s_dist_03 :s_dist_04 $s_dist_04 :s_dist_05 $s_dist_05 :s_dist_06 $s_dist_06 :s_dist_07 $s_dist_07 :s_dist_08 $s_dist_08 :s_dist_09 $s_dist_09 :s_dist_10 $s_dist_10 :s_data $s_data
if {[ catch {oraexec $curn3} message ] } {
puts "Error in cursor 3:$curn3 $message"
puts [ oramsg $curn3 all ]
                                }
      if { ![ expr {$s_i_id % 50000} ] } {
	puts "Loading Stock - $s_i_id"
	oracommit $lda
			}
	}
	oracommit $lda
	oraclose $curn3
	puts "Stock done"
	return
}

proc Customer { lda d_id w_id CUST_PER_DIST } {
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
set curn5 [oraopen $lda ]
set sql "INSERT INTO customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) values (:c_id, :c_d_id, :c_w_id, :c_first, :c_middle, :c_last, :c_street_1, :c_street_2, :c_city, :c_state, :c_zip, :c_phone, to_date(:timestamp,'YYYYMMDDHH24MISS'), :c_credit, :c_credit_lim, :c_discount, :c_balance, :c_data, 10.0, 1, 0)"
oraparse $curn5 $sql
set curn6 [oraopen $lda ]
set sql2 "INSERT INTO history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) values (:c_id, :c_d_id, :c_w_id, :c_w_id, :c_d_id, to_date(:timestamp,'YYYYMMDDHH24MISS'), :h_amount, :h_data)"
oraparse $curn6 $sql2
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
foreach  i {c_id_c5 c_d_id_c5 c_w_id_c5 c_first_c5 c_middle_c5 c_last_c5 c_phone_c5 c_credit_c5 c_credit_lim_c5 c_discount_c5 c_balance_c5 c_data_c5} j {c_id c_d_id c_w_id c_first c_middle c_last c_phone c_credit c_credit_lim c_discount c_balance c_data} {
lappend $i [set $j] 
}
foreach i {c_street_1_c5 c_street_2_c5 c_city_c5 c_state_c5 c_zip_c5 timestamp_c5} j "[ lindex $c_add 0 ] [ lindex $c_add 1 ] [ lindex $c_add 2 ] [ lindex $c_add 3 ] [ lindex $c_add 4 ] [ gettimestamp ]" {
lappend $i $j
}
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
foreach i {h_c_id_c6 h_c_d_id_c6 h_c_w_id_c6 h_w_id_c6 h_d_id_c6 h_amount_c6 h_data_c6} j {c_id c_d_id c_w_id c_w_id c_d_id h_amount h_data} {
lappend $i [set $j]
}
lappend h_date_c6 [ gettimestamp ]
if { ![ expr {$c_id % 1000} ] } {
oraparse $curn5 $sql
orabind $curn5 -arraydml :c_id $c_id_c5 :c_d_id $c_d_id_c5 :c_w_id $c_w_id_c5 :c_first $c_first_c5 :c_middle $c_middle_c5 :c_last $c_last_c5 :c_street_1 $c_street_1_c5 :c_street_2 $c_street_2_c5 :c_city $c_city_c5 :c_state $c_state_c5 :c_zip $c_zip_c5 :c_phone $c_phone_c5 :timestamp $timestamp_c5 :c_credit $c_credit_c5 :c_credit_lim $c_credit_lim_c5 :c_discount $c_discount_c5 :c_balance $c_balance_c5 :c_data $c_data_c5
if {[ catch {oraexec $curn5} message ] } {
puts "Error in cursor 5:$curn5 $message"
puts [ oramsg $curn5 all ]
			}
oraparse $curn6 $sql2
orabind $curn6 -arraydml :c_id $h_c_id_c6 :c_d_id $h_c_d_id_c6 :c_w_id $h_c_w_id_c6 :c_w_id $h_w_id_c6 :c_d_id $h_d_id_c6 :timestamp $h_date_c6 :h_amount $h_amount_c6 :h_data $h_data_c6
if {[ catch {oraexec $curn6} message ] } {
puts "Error in cursor 6:$curn6 $message"
puts [ oramsg $curn6 all ]
			}
unset c_id_c5 c_d_id_c5 c_w_id_c5 c_first_c5 c_middle_c5 c_last_c5 c_phone_c5 c_credit_c5 c_credit_lim_c5 c_discount_c5 c_balance_c5 c_data_c5 c_street_1_c5 c_street_2_c5 c_city_c5 c_state_c5 c_zip_c5 timestamp_c5 h_c_id_c6 h_c_d_id_c6 h_c_w_id_c6 h_w_id_c6 h_d_id_c6 h_amount_c6 h_data_c6 h_date_c6
		}		
	}
oracommit $lda
oraclose $curn5
oraclose $curn6
puts "Customer Done"
return
}

proc Orders { lda d_id w_id MAXITEMS ORD_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Orders for D=$d_id W=$w_id"
set curn7 [ oraopen $lda ]
set sql "INSERT INTO orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values (:o_id, :o_c_id, :o_d_id, :o_w_id, to_date(:timestamp,'YYYYMMDDHH24MISS'), NULL, :o_ol_cnt, 1)"
oraparse $curn7 $sql
set curn8 [ oraopen $lda ]
set sql2 "INSERT INTO new_order (no_o_id, no_d_id, no_w_id) values (:o_id, :o_d_id, :o_w_id)"
oraparse $curn8 $sql2
set curn9 [ oraopen $lda ]
set sql3 "INSERT INTO orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values (:o_id, :o_c_id, :o_d_id, :o_w_id, to_date(:timestamp,'YYYYMMDDHH24MISS'), :o_carrier_id, :o_ol_cnt, 1)"
oraparse $curn9 $sql3
set curn10 [ oraopen $lda ]
set sql4 "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values (:o_id, :o_d_id, :o_w_id, :ol, :ol_i_id, :ol_supply_w_id, :ol_quantity, :ol_amount, :ol_dist_info, NULL)"
oraparse $curn10 $sql4
set curn11 [ oraopen $lda ]
set sql5 "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values (:o_id, :o_d_id, :o_w_id, :ol, :ol_i_id, :ol_supply_w_id, :ol_quantity, :ol_amount, :ol_dist_info, to_date(:timestamp,'YYYYMMDDHH24MISS'))"
oraparse $curn11 $sql5
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
foreach i {o_id_c7 o_c_id_c7 o_d_id_c7 o_w_id_c7 o_ol_cnt_c7} j {o_id o_c_id o_d_id o_w_id o_ol_cnt} {
lappend $i [set $j]
}
lappend timestamp_c7 [ gettimestamp ]
set e "no1"
foreach i {o_id_c8 o_d_id_c8 o_w_id_c8} j {o_id o_d_id o_w_id} {
lappend $i [set $j]
}
  } else {
  set e "o3"
foreach i {o_id_c9 o_c_id_c9 o_d_id_c9 o_w_id_c9 o_carrier_id_c9 o_ol_cnt_c9} j {o_id o_c_id o_d_id o_w_id o_carrier_id o_ol_cnt} {
lappend $i [set $j]
}
lappend timestamp_c9 [ gettimestamp ]
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
foreach i {o_id_c10 o_d_id_c10 o_w_id_c10 ol_c10 ol_i_id_c10 ol_supply_w_id_c10 ol_quantity_c10 ol_amount_c10 ol_dist_info_c10} j {o_id o_d_id o_w_id ol ol_i_id ol_supply_w_id ol_quantity ol_amount ol_dist_info} {
lappend $i [set $j]
}
		} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
foreach i {o_id_c11 o_d_id_c11 o_w_id_c11 ol_c11 ol_i_id_c11 ol_supply_w_id_c11 ol_quantity_c11 ol_amount_c11 ol_dist_info_c11} j {o_id o_d_id o_w_id ol ol_i_id ol_supply_w_id ol_quantity ol_amount ol_dist_info} {
lappend $i [set $j]
}
lappend timestamp_c11 [ gettimestamp ]
			}
		}
 if { ![ expr {$o_id % 100} ] } {
 if { ![ expr {$o_id % 50000} ] } {
	puts "...$o_id"
	oracommit $lda
			}
if { $o_id > 2100 } {
oraparse $curn7 $sql
oraparse $curn8 $sql2
oraparse $curn10 $sql4
orabind $curn7 -arraydml :o_id $o_id_c7 :o_c_id $o_c_id_c7 :o_d_id $o_d_id_c7 :o_w_id $o_w_id_c7 :timestamp $timestamp_c7 :o_ol_cnt $o_ol_cnt_c7
if {[ catch {oraexec $curn7} message ] } {
puts "Error in cursor 7:$curn7 $message"
puts [ oramsg $curn7 all ]
}
orabind $curn8 -arraydml :o_id $o_id_c8 :o_d_id $o_d_id_c8 :o_w_id $o_w_id_c8
if {[ catch {oraexec $curn8} message ] } {
puts "Error in cursor 8:$curn8 $message"
puts [ oramsg $curn8 all ]
}
orabind $curn10 -arraydml :o_id $o_id_c10 :o_d_id $o_d_id_c10 :o_w_id $o_w_id_c10 :ol $ol_c10 :ol_i_id $ol_i_id_c10 :ol_supply_w_id $ol_supply_w_id_c10 :ol_quantity $ol_quantity_c10 :ol_amount $ol_amount_c10 :ol_dist_info $ol_dist_info_c10
if {[ catch {oraexec $curn10} message ] } {
puts "Error in cursor 10:$curn10 $message"
puts [ oramsg $curn10 all ]
		}
unset o_id_c7 o_c_id_c7 o_d_id_c7 o_w_id_c7 timestamp_c7 o_ol_cnt_c7 o_id_c8 o_d_id_c8 o_w_id_c8 o_id_c10 o_d_id_c10 o_w_id_c10 ol_c10 ol_i_id_c10 ol_supply_w_id_c10 ol_quantity_c10 ol_amount_c10 ol_dist_info_c10
} else {
oraparse $curn9 $sql3
oraparse $curn11 $sql5
orabind $curn9 -arraydml :o_id $o_id_c9 :o_c_id $o_c_id_c9 :o_d_id $o_d_id_c9 :o_w_id $o_w_id_c9 :timestamp $timestamp_c9 :o_carrier_id $o_carrier_id_c9 :o_ol_cnt $o_ol_cnt_c9
if {[ catch {oraexec $curn9} message ] } {
puts "Error in cursor 9:$curn9 $message"
puts [ oramsg $curn9 all ]
               }
orabind $curn11 -arraydml :o_id $o_id_c11 :o_d_id $o_d_id_c11 :o_w_id $o_w_id_c11 :ol $ol_c11 :ol_i_id $ol_i_id_c11 :ol_supply_w_id $ol_supply_w_id_c11 :ol_quantity $ol_quantity_c11 :ol_amount $ol_amount_c11 :ol_dist_info $ol_dist_info_c11 :timestamp $timestamp_c11
if {[ catch {oraexec $curn11} message ] } {
puts "Error in cursor 11:$curn11 $message"
puts [ oramsg $curn11 all ]
				}
unset o_id_c9 o_c_id_c9 o_d_id_c9 o_w_id_c9 timestamp_c9 o_carrier_id_c9 o_ol_cnt_c9 o_id_c11 o_d_id_c11 o_w_id_c11 ol_c11 ol_i_id_c11 ol_supply_w_id_c11 ol_quantity_c11 ol_amount_c11 ol_dist_info_c11 timestamp_c11
			}
		}
	}
	oracommit $lda
        oraclose $curn7
        oraclose $curn8
        oraclose $curn9
        oraclose $curn10
        oraclose $curn11
	puts "Orders Done"
	return;
	}

proc LoadItems { lda MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Item"
set curn1 [oraopen $lda ]
set sql "INSERT INTO item (i_id, i_im_id, i_name, i_price, i_data) values (:i_id, :i_im_id, :i_name, :i_price, :i_data)"
oraparse $curn1 $sql
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
orabind $curn1 :i_id $i_id :i_im_id $i_im_id :i_name $i_name :i_price $i_price :i_data $i_data
if {[ catch {oraexec $curn1} message ] } {
puts "Error in cursor 1:$curn1 $message"
puts [ oramsg $curn1 all ]
        }
       if { ![ expr {$i_id % 50000} ] } {
	puts "Loading Items - $i_id"
	oracommit $lda
		}
	}
	oracommit $lda
	oraclose $curn1
	puts "Item done"
	return
	}

proc Stock { lda w_id MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Stock Wid=$w_id"
set curn3 [oraopen $lda ]
set sql "INSERT INTO STOCK (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) values (:s_i_id, :s_w_id, :s_quantity, :s_dist_01, :s_dist_02, :s_dist_03, :s_dist_04, :s_dist_05, :s_dist_06, :s_dist_07, :s_dist_08, :s_dist_09, :s_dist_10, :s_data, 0, 0, 0)"
oraparse $curn3 $sql
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
foreach  i {s_i_id_c3 s_w_id_c3 s_quantity_c3 s_dist_01_c3 s_dist_02_c3 s_dist_03_c3 s_dist_04_c3 s_dist_05_c3 s_dist_06_c3 s_dist_07_c3 s_dist_08_c3 s_dist_09_c3 s_dist_10_c3 s_data_c3} j {s_i_id s_w_id s_quantity s_dist_01 s_dist_02 s_dist_03 s_dist_04 s_dist_05 s_dist_06 s_dist_07 s_dist_08 s_dist_09 s_dist_10 s_data} {
lappend $i [set $j] 
}
if { ![ expr {$s_i_id % 1000} ] } {
oraparse $curn3 $sql
orabind $curn3 -arraydml :s_i_id $s_i_id_c3 :s_w_id $s_w_id_c3 :s_quantity $s_quantity_c3 :s_dist_01 $s_dist_01_c3 :s_dist_02 $s_dist_02_c3 :s_dist_03 $s_dist_03_c3 :s_dist_04 $s_dist_04_c3 :s_dist_05 $s_dist_05_c3 :s_dist_06 $s_dist_06_c3 :s_dist_07 $s_dist_07_c3 :s_dist_08 $s_dist_08_c3 :s_dist_09 $s_dist_09_c3 :s_dist_10 $s_dist_10_c3 :s_data $s_data_c3
if {[ catch {oraexec $curn3} message ] } {
puts "Error in cursor 3:$curn3 $message"
puts [ oramsg $curn3 all ]
                                }
unset s_i_id_c3 s_w_id_c3 s_quantity_c3 s_dist_01_c3 s_dist_02_c3 s_dist_03_c3 s_dist_04_c3 s_dist_05_c3 s_dist_06_c3 s_dist_07_c3 s_dist_08_c3 s_dist_09_c3 s_dist_10_c3 s_data_c3
		}
      if { ![ expr {$s_i_id % 50000} ] } {
	puts "Loading Stock - $s_i_id"
	oracommit $lda
			}
	}
	oracommit $lda
	oraclose $curn3
	puts "Stock done"
	return
}

proc District { lda w_id DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading District"
set curn4 [oraopen $lda ]
set sql "INSERT INTO DISTRICT (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) values (:d_id, :d_w_id, :d_name, :d_street_1, :d_street_2, :d_city, :d_state, :d_zip, :d_tax, :d_ytd, :d_next_o_id)"
oraparse $curn4 $sql
set d_w_id $w_id
set d_ytd 30000.0
set d_next_o_id 3001
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
orabind $curn4 :d_id $d_id :d_w_id $d_w_id :d_name $d_name :d_street_1 [ lindex $d_add 0 ] :d_street_2 [ lindex $d_add 1 ] :d_city [ lindex $d_add 2 ] :d_state [ lindex $d_add 3 ] :d_zip [ lindex $d_add 4 ] :d_tax $d_tax :d_ytd $d_ytd :d_next_o_id $d_next_o_id
if {[ catch {oraexec $curn4} message ] } {
puts "Error in cursor 4:$curn4 $message"
puts [ oramsg $curn4 all ]
                                }
	}
	oracommit $lda
	oraclose $curn4
	puts "District done"
	return
}

proc LoadWare { lda ware_start count_ware MAXITEMS DIST_PER_WARE timesten } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set curn2 [oraopen $lda ]
set sql "INSERT INTO WAREHOUSE (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values (:w_id, :w_name, :w_street_1, :w_street_2, :w_city, :w_state, :w_zip, :w_tax, :w_ytd)"
oraparse $curn2 $sql
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
orabind $curn2 :w_id $w_id :w_name $w_name :w_street_1 [ lindex $add 0 ] :w_street_2 [ lindex $add 1 ] :w_city [ lindex $add 2 ] :w_state [ lindex $add 3 ] :w_zip [ lindex $add 4 ] :w_tax $w_tax :w_ytd $w_ytd
if {[ catch {oraexec $curn2} message ] } {
puts "Error in cursor 2:$curn2 $message"
puts [ oramsg $curn2 all ]
         }
	if { $timesten } { 
	TTStock $lda $w_id $MAXITEMS
	} else {
	Stock $lda $w_id $MAXITEMS
	}
	District $lda $w_id $DIST_PER_WARE
	oracommit $lda
	}
	oraclose $curn2
}

proc LoadCust { lda ware_start count_ware CUST_PER_DIST DIST_PER_WARE timesten } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	if { $timesten } { 
	TTCustomer $lda $d_id $w_id $CUST_PER_DIST
	} else {
	Customer $lda $d_id $w_id $CUST_PER_DIST
	}
	}
	}
	oracommit $lda
	return
}

proc LoadOrd { lda ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE timesten num_part } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {	
	if { $timesten } { 
	TTOrders $lda $d_id $w_id $MAXITEMS $ORD_PER_DIST $num_part
	} else {
	Orders $lda $d_id $w_id $MAXITEMS $ORD_PER_DIST
	}
	}
	}
	oracommit $lda
	return
}

proc do_tpcc { system_user system_password instance count_ware tpcc_user tpcc_pass tpcc_def_tab tpcc_ol_tab tpcc_def_temp plsql directory partition timesten num_threads } {
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
if { [ string toupper $timesten ] eq "TRUE"} { set timesten 1 } else { set timesten 0 }
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
puts "CREATING [ string toupper $tpcc_user ] SCHEMA"
if { $timesten } {
puts "TimesTen expects the Database [ string toupper $instance ] and User [ string toupper $tpcc_user ] to have been created by the instance administrator in advance and be granted create table, session, procedure, view (and admin for checkpoints) privileges"
	} else {
set connect $system_user/$system_password@$instance
set lda [ oralogon $connect ]
SetNLS $lda
CreateUser $lda $tpcc_user $tpcc_pass $tpcc_def_tab $tpcc_def_temp $tpcc_ol_tab $partition
if { $plsql eq 1 } { CreateDirectory $lda $directory $tpcc_user }
oralogoff $lda
	}
set connect $tpcc_user/$tpcc_pass@$instance
set lda [ oralogon $connect ]
if { $timesten } {
set plsql 0
if { $partition eq "true" } {
set num_part 10
	} else {
set num_part 0
	}
   } else {
SetNLS $lda
if { $partition eq "true" } {
if {$count_ware < 200} {
set num_part 0
	} else {
set num_part [ expr round($count_ware/100) ]
	}
	} else {
set num_part 0
}}
CreateTables $lda $num_part $tpcc_ol_tab $timesten
if { $plsql eq 1 } { 
puts "DOING PL/SQL SERVER SIDE LOAD LOGGING TO $directory/tpcc_load.log"
set timesten 0
ServerSidePackage $lda $count_ware 
CreateIndexes $lda $timesten $num_part
CreateStoredProcs $lda $timesten $num_part
GatherStatistics $lda [ string toupper $tpcc_user ] $timesten $num_part
puts "[ string toupper $tpcc_user ] SCHEMA COMPLETE"
oralogoff $lda
return
	} else {
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
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
	}
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000 
}} else {
LoadItems $lda $MAXITEMS
}}}
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
set connect $tpcc_user/$tpcc_pass@$instance
set lda [ oralogon $connect ]
if { $timesten } {
	;
	} else {
SetNLS $lda
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
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
if { $timesten } { if { $partition eq "true" } { set num_part 10 } else { set num_part 0 }} else { set num_part 0 }
LoadWare $lda $mystart $myend $MAXITEMS $DIST_PER_WARE $timesten
LoadCust $lda $mystart $myend $CUST_PER_DIST $DIST_PER_WARE $timesten
LoadOrd $lda $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE $timesten $num_part
puts "End:[ clock format [ clock seconds ] ]"
oracommit $lda
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
	}
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateIndexes $lda $timesten $num_part
if { $timesten } { TTPLSQLSettings $lda }
CreateStoredProcs $lda $timesten $num_part
GatherStatistics $lda [ string toupper $tpcc_user ] $timesten $num_part
puts "[ string toupper $tpcc_user ] SCHEMA COMPLETE"
oralogoff $lda
return
	}
    }
}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 2894.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "do_tpcc $system_user $system_password $instance  $count_ware $tpcc_user $tpcc_pass $tpcc_def_tab $tpcc_ol_tab $tpcc_def_temp $plsql $directory $partition $tpcc_tt_compat $num_threads"
	} else { return }
}

proc loadoratpcc { } {
global instance tpcc_user tpcc_pass total_iterations raiseerror keyandthink _ED
if {  ![ info exists instance ] } { set instance "oracle" }
if {  ![ info exists tpcc_user ] } { set tpcc_user "tpcc" }
if {  ![ info exists tpcc_pass ] } { set tpcc_pass "tpcc" }
if {  ![ info exists total_iterations ] } { set total_iterations 1000 }
if {  ![ info exists raiseerror ] } { set raiseerror "false" }
if {  ![ info exists keyandthink ] } { set keyandthink "true" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require Oratcl} \] { error \"Failed to load Oratcl - Oracle OCI Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$raiseerror\" ;# Exit script on Oracle error (true or false)
set KEYANDTHINK \"$keyandthink\" ;# Time for user thinking and keying (true or false)
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 7.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "set connect $tpcc_user/$tpcc_pass@$instance ;# Oracle connect string for tpc-c user
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 9.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#STANDARD SQL
proc standsql { curn sql } {
set ftch ""
if {[catch {orasql $curn $sql} message]} {
error "SQL statement failed: $sql : $message"
} else {
orafetch  $curn -datavariable output
while { [ oramsg  $curn ] == 0 } {
lappend ftch $output
orafetch  $curn -datavariable output
	}
return $ftch
    }
}
#Default NLS
proc SetNLS { lda } {
set curn_nls [oraopen $lda ]
set nls(1) "alter session set NLS_LANGUAGE = AMERICAN"
set nls(2) "alter session set NLS_TERRITORY = AMERICA"
for { set i 1 } { $i <= 2 } { incr i } {
if {[ catch {orasql $curn_nls $nls($i)} message ] } {
puts "$message $nls($i)"
puts [ oramsg $curn_nls all ]
			}
	}
oraclose $curn_nls
}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { curn_no no_w_id w_id_input RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
orabind $curn_no :no_w_id $no_w_id :no_max_w_id $w_id_input :no_d_id $no_d_id :no_c_id $no_c_id :no_o_ol_cnt $ol_cnt :no_c_discount {} :no_c_last {} :no_c_credit {} :no_d_tax {} :no_w_tax {} :no_d_next_o_id {0} :timestamp $date
if {[catch {oraexec $curn_no} message]} {
if { $RAISEERROR } {
error "New Order : $message [ oramsg $curn_no all ]"
	} else {
puts $message
	} } else {
orafetch  $curn_no -datavariable output
puts $output
	}
}
#PAYMENT
proc payment { curn_py p_w_id w_id_input RAISEERROR } {
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
#change following to correct values
orabind $curn_py :p_w_id $p_w_id :p_d_id $p_d_id :p_c_w_id $p_c_w_id :p_c_d_id $p_c_d_id :p_c_id $p_c_id :byname $byname :p_h_amount $p_h_amount :p_c_last $name :p_w_street_1 {} :p_w_street_2 {} :p_w_city {} :p_w_state {} :p_w_zip {} :p_d_street_1 {} :p_d_street_2 {} :p_d_city {} :p_d_state {} :p_d_zip {} :p_c_first {} :p_c_middle {} :p_c_street_1 {} :p_c_street_2 {} :p_c_city {} :p_c_state {} :p_c_zip {} :p_c_phone {} :p_c_since {} :p_c_credit {0} :p_c_credit_lim {} :p_c_discount {} :p_c_balance {0} :p_c_data {} :timestamp $h_date
if {[ catch {oraexec $curn_py} message]} {
if { $RAISEERROR } {
error "Payment : $message [ oramsg $curn_py all ]"
	} else {
puts $message
} } else {
orafetch  $curn_py -datavariable output
puts $output
	}
}
#ORDER_STATUS
proc ostat { curn_os w_id RAISEERROR } {
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
orabind $curn_os :os_w_id $w_id :os_d_id $d_id :os_c_id $c_id :byname $byname :os_c_last $name :os_c_first {} :os_c_middle {} :os_c_balance {0} :os_o_id {} :os_entdate {} :os_o_carrier_id {}
if {[catch {oraexec $curn_os} message]} {
if { $RAISEERROR } {
error "Order Status : $message [ oramsg $curn_os all ]"
	} else {
puts $message
} } else {
orafetch  $curn_os -datavariable output
puts $output
	}
}
#DELIVERY
proc delivery { curn_dl w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
orabind $curn_dl :d_w_id $w_id :d_o_carrier_id $carrier_id :timestamp $date
if {[ catch {oraexec $curn_dl} message ]} {
if { $RAISEERROR } {
error "Delivery : $message [ oramsg $curn_dl all ]"
	} else {
puts $message
} } else {
orafetch  $curn_dl -datavariable output
puts $output
	}
}
#STOCK LEVEL
proc slev { curn_sl w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
orabind $curn_sl :st_w_id $w_id :st_d_id $stock_level_d_id :THRESHOLD $threshold 
if {[catch {oraexec $curn_sl} message]} { 
if { $RAISEERROR } {
error "Stock Level : $message [ oramsg $curn_sl all ]"
	} else {
puts $message
} } else {
orafetch  $curn_sl -datavariable output
puts $output
	}
}

proc prep_statement { lda curn_st } {
switch $curn_st {
curn_sl {
set curn_sl [oraopen $lda ]
set sql_sl "BEGIN slev(:st_w_id,:st_d_id,:threshold); END;"
oraparse $curn_sl $sql_sl
return $curn_sl
	}
curn_dl {
set curn_dl [oraopen $lda ]
set sql_dl "BEGIN delivery(:d_w_id,:d_o_carrier_id,TO_DATE(:timestamp,'YYYYMMDDHH24MISS')); END;"
oraparse $curn_dl $sql_dl
return $curn_dl
	}
curn_os {
set curn_os [oraopen $lda ]
set sql_os "BEGIN ostat(:os_w_id,:os_d_id,:os_c_id,:byname,:os_c_last,:os_c_first,:os_c_middle,:os_c_balance,:os_o_id,:os_entdate,:os_o_carrier_id); END;"
oraparse $curn_os $sql_os
return $curn_os
	}
curn_py {
set curn_py [oraopen $lda ]
set sql_py "BEGIN payment(:p_w_id,:p_d_id,:p_c_w_id,:p_c_d_id,:p_c_id,:byname,:p_h_amount,:p_c_last,:p_w_street_1,:p_w_street_2,:p_w_city,:p_w_state,:p_w_zip,:p_d_street_1,:p_d_street_2,:p_d_city,:p_d_state,:p_d_zip,:p_c_first,:p_c_middle,:p_c_street_1,:p_c_street_2,:p_c_city,:p_c_state,:p_c_zip,:p_c_phone,:p_c_since,:p_c_credit,:p_c_credit_lim,:p_c_discount,:p_c_balance,:p_c_data,TO_DATE(:timestamp,'YYYYMMDDHH24MISS')); END;"
oraparse $curn_py $sql_py
return $curn_py
	}
curn_no {
set curn_no [oraopen $lda ]
set sql_no "begin neword(:no_w_id,:no_max_w_id,:no_d_id,:no_c_id,:no_o_ol_cnt,:no_c_discount,:no_c_last,:no_c_credit,:no_d_tax,:no_w_tax,:no_d_next_o_id,TO_DATE(:timestamp,'YYYYMMDDHH24MISS')); END;"
oraparse $curn_no $sql_no
return $curn_no
	}
    }
}
#RUN TPC-C
set lda [oralogon $connect]
SetNLS $lda
oraautocom $lda on
foreach curn_st {curn_no curn_py curn_dl curn_sl curn_os} { set $curn_st [ prep_statement $lda $curn_st ] }
set curn1 [oraopen $lda ]
set sql1 "select max(w_id) from warehouse"
set w_id_input [ standsql $curn1 $sql1 ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set sql2 "select max(d_id) from district"
set d_id_input [ standsql $curn1 $sql2 ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
set sql3 "BEGIN DBMS_RANDOM.initialize (val => TO_NUMBER(TO_CHAR(SYSDATE,'MMSS')) * (USERENV('SESSIONID') - TRUNC(USERENV('SESSIONID'),-5))); END;"
oraparse $curn1 $sql3
if {[catch {oraplexec $curn1 $sql3} message]} {
error "Failed to initialise DBMS_RANDOM $message have you run catoctk.sql as sys?" }
oraclose $curn1
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword $curn_no $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment $curn_py $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery $curn_dl $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev $curn_sl $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat $curn_os $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
oraclose $curn_no
oraclose $curn_py
oraclose $curn_dl
oraclose $curn_sl
oraclose $curn_os
oralogoff $lda
	}
}

proc loadoraawrtpcc { } {
global system_user system_password instance tpcc_user tpcc_pass total_iterations raiseerror keyandthink rampup duration opmode checkpoint tpcc_tt_compat _ED
if {  ![ info exists system_user ] } { set system_user "system" }
if {  ![ info exists system_password ] } { set system_password "manager" }
if {  ![ info exists instance ] } { set instance "oracle" }
if {  ![ info exists tpcc_user ] } { set tpcc_user "tpcc" }
if {  ![ info exists tpcc_pass ] } { set tpcc_pass "tpcc" }
if {  ![ info exists total_iterations ] } { set total_iterations 1000 }
if {  ![ info exists raiseerror ] } { set raiseerror "false" }
if {  ![ info exists keyandthink ] } { set keyandthink "true" }
if {  ![ info exists rampup ] } { set rampup "2" }
if {  ![ info exists duration ] } { set duration "5" }
if {  ![ info exists opmode ] } { set opmode "Local" }
if {  ![ info exists checkpoint ] } { set checkpoint "false" }
if {  ![ info exists tpcc_tt_compat ] } { set tpcc_tt_compat "false" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C AWR"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require Oratcl} \] { error \"Failed to load Oratcl - Oracle OCI Library Error\" }
#AWR SNAPSHOT DRIVER SCRIPT#######################################
#THIS SCRIPT TO BE RUN WITH VIRTUAL USER OUTPUT ENABLED
#EDITABLE OPTIONS##################################################
set total_iterations $total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$raiseerror\" ;# Exit script on Oracle error (true or false)
set KEYANDTHINK \"$keyandthink\" ;# Time for user thinking and keying (true or false)
set CHECKPOINT \"$checkpoint\" ;# Perform Oracle checkpoint when complete (true or false)
set rampup $rampup;  # Rampup time in minutes before first snapshot is taken
set duration $duration;  # Duration in minutes before second AWR snapshot is taken
set mode \"$opmode\" ;# HammerDB operational mode
set timesten \"$tpcc_tt_compat\" ;# Database is TimesTen
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 14.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "set systemconnect $system_user/$system_password@$instance ;# Oracle connect string for system user
set connect $tpcc_user/$tpcc_pass@$instance ;# Oracle connect string for tpc-c user
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 17.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#CHECK THREAD STATUS
proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }
#STANDARD SQL
proc standsql { curn sql } {
set ftch ""
if {[catch {orasql $curn $sql} message]} {
error "SQL statement failed: $sql : $message"
} else {
orafetch  $curn -datavariable output
while { [ oramsg  $curn ] == 0 } {
lappend ftch $output
orafetch  $curn -datavariable output
	}
return $ftch
    }
}
#Default NLS
proc SetNLS { lda } {
set curn_nls [oraopen $lda ]
set nls(1) "alter session set NLS_LANGUAGE = AMERICAN"
set nls(2) "alter session set NLS_TERRITORY = AMERICA"
for { set i 1 } { $i <= 2 } { incr i } {
if {[ catch {orasql $curn_nls $nls($i)} message ] } {
puts "$message $nls($i)"
puts [ oramsg $curn_nls all ]
			}
	}
oraclose $curn_nls
}

if { [ chk_thread ] eq "FALSE" } {
error "AWR Snapshot Script must be run in Thread Enabled Interpreter"
}
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
if { [ string toupper $timesten ] eq "TRUE"} { 
set timesten 1 
set systemconnect $connect
} else { 
set timesten 0 
}
switch $myposition {
1 { 
if { $mode eq "Local" || $mode eq "Master" } {
set lda [oralogon $systemconnect]
if { !$timesten } { SetNLS $lda }
set lda1 [oralogon $connect]
if { !$timesten } { SetNLS $lda1 }
oraautocom $lda on
oraautocom $lda1 on
set curn1 [oraopen $lda ] 
set curn2 [oraopen $lda1 ]
if { $timesten } {
puts "For TimesTen use external ttStats utility for performance reports"
set sql1 "select (xact_commits + xact_rollbacks) from sys.monitor"
	} else {
set sql1 "BEGIN dbms_workload_repository.create_snapshot(); END;"
oraparse $curn1 $sql1
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
if { $timesten } {
puts "Rampup complete, Taking start Transaction Count."
set start_trans [ standsql $curn2 $sql1 ]
	} else {
puts "Rampup complete, Taking start AWR snapshot."
if {[catch {oraplexec $curn1 $sql1} message]} { error "Failed to create snapshot : $message" }
set sql2 "SELECT INSTANCE_NUMBER, INSTANCE_NAME, DB_NAME, DBID, SNAP_ID, TO_CHAR(END_INTERVAL_TIME,'DD MON YYYY HH24:MI') FROM (SELECT DI.INSTANCE_NUMBER, DI.INSTANCE_NAME, DI.DB_NAME, DI.DBID, DS.SNAP_ID, DS.END_INTERVAL_TIME FROM DBA_HIST_SNAPSHOT DS, DBA_HIST_DATABASE_INSTANCE DI WHERE DS.DBID=DI.DBID AND DS.INSTANCE_NUMBER=DI.INSTANCE_NUMBER AND DS.STARTUP_TIME=DI.STARTUP_TIME ORDER BY DS.SNAP_ID DESC) WHERE ROWNUM=1"
if {[catch {orasql $curn1 $sql2} message]} {
error "SQL statement failed: $sql2 : $message"
} else {
orafetch  $curn1 -datavariable firstsnap
split  $firstsnap " "
puts "Start Snapshot [ lindex $firstsnap 4 ] taken at [ lindex $firstsnap 5 ] of instance [ lindex $firstsnap 1 ] ([lindex $firstsnap 0]) of database [ lindex $firstsnap 2 ] ([lindex $firstsnap 3])"
}}
set sql4 "select sum(d_next_o_id) from district"
set start_nopm [ standsql $curn2 $sql4 ]
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
if { $timesten } {
puts "Test complete, Taking end Transaction Count."
set end_trans [ standsql $curn2 $sql1 ]
set end_nopm [ standsql $curn2 $sql4 ]
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm TimesTen TPM at $nopm NOPM"
	} else {
puts "Test complete, Taking end AWR snapshot."
oraparse $curn1 $sql1
if {[catch {oraplexec $curn1 $sql1} message]} { error "Failed to create snapshot : $message" }
if {[catch {orasql $curn1 $sql2} message]} {
error "SQL statement failed: $sql2 : $message"
} else {
orafetch  $curn1 -datavariable endsnap
split  $endsnap " "
puts "End Snapshot [ lindex $endsnap 4 ] taken at [ lindex $endsnap 5 ] of instance [ lindex $endsnap 1 ] ([lindex $endsnap 0]) of database [ lindex $endsnap 2 ] ([lindex $endsnap 3])"
puts "Test complete: view report from SNAPID  [ lindex $firstsnap 4 ] to [ lindex $endsnap 4 ]"
set sql3 "select round((sum(tps)*60)) as TPM from (select e.stat_name, (e.value - b.value) / (select avg( extract( day from (e1.end_interval_time-b1.end_interval_time) )*24*60*60+ extract( hour from (e1.end_interval_time-b1.end_interval_time) )*60*60+ extract( minute from (e1.end_interval_time-b1.end_interval_time) )*60+ extract( second from (e1.end_interval_time-b1.end_interval_time)) ) from dba_hist_snapshot b1, dba_hist_snapshot e1 where b1.snap_id = [ lindex $firstsnap 4 ] and e1.snap_id = [ lindex $endsnap 4 ] and b1.dbid = [lindex $firstsnap 3] and e1.dbid = [lindex $endsnap 3] and b1.instance_number = [lindex $firstsnap 0] and e1.instance_number = [lindex $endsnap 0] and b1.startup_time = e1.startup_time and b1.end_interval_time < e1.end_interval_time) as tps from dba_hist_sysstat b, dba_hist_sysstat e where b.snap_id = [ lindex $firstsnap 4 ] and e.snap_id = [ lindex $endsnap 4 ] and b.dbid = [lindex $firstsnap 3] and e.dbid = [lindex $endsnap 3] and b.instance_number = [lindex $firstsnap 0] and e.instance_number = [lindex $endsnap 0] and b.stat_id = e.stat_id and b.stat_name in ('user commits','user rollbacks') and e.stat_name in ('user commits','user rollbacks') order by 1 asc)"
set tpm [ standsql $curn1 $sql3 ]
set end_nopm [ standsql $curn2 $sql4 ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm Oracle TPM at $nopm NOPM"
	}
}
tsv::set application abort 1
if { $CHECKPOINT } {
puts "Checkpoint"
if { $timesten } {
set sql4 "call ttCkptBlocking"
      }	else {
set sql4 "alter system checkpoint"
if {[catch {orasql $curn1 $sql4} message]} {
error "SQL statement failed: $sql4 : $message"
}
set sql5 "alter system switch logfile"
if {[catch {orasql $curn1 $sql5} message]} {
error "SQL statement failed: $sql5 : $message"
	}}
puts "Checkpoint Complete"
        }
oraclose $curn1
oraclose $curn2
oralogoff $lda
oralogoff $lda1
		} else {
puts "Operating in Slave Mode, No Snapshots taken..."
		}
	}
default {
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { curn_no no_w_id w_id_input RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
orabind $curn_no :no_w_id $no_w_id :no_max_w_id $w_id_input :no_d_id $no_d_id :no_c_id $no_c_id :no_o_ol_cnt $ol_cnt :no_c_discount {} :no_c_last {} :no_c_credit {} :no_d_tax {} :no_w_tax {} :no_d_next_o_id {0} :timestamp $date
if {[catch {oraexec $curn_no} message]} {
if { $RAISEERROR } {
error "New Order : $message [ oramsg $curn_no all ]"
	} else {
;
	} } else {
orafetch  $curn_no -datavariable output
;
	}
}
#PAYMENT
proc payment { curn_py p_w_id w_id_input RAISEERROR } {
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
#change following to correct values
orabind $curn_py :p_w_id $p_w_id :p_d_id $p_d_id :p_c_w_id $p_c_w_id :p_c_d_id $p_c_d_id :p_c_id $p_c_id :byname $byname :p_h_amount $p_h_amount :p_c_last $name :p_w_street_1 {} :p_w_street_2 {} :p_w_city {} :p_w_state {} :p_w_zip {} :p_d_street_1 {} :p_d_street_2 {} :p_d_city {} :p_d_state {} :p_d_zip {} :p_c_first {} :p_c_middle {} :p_c_street_1 {} :p_c_street_2 {} :p_c_city {} :p_c_state {} :p_c_zip {} :p_c_phone {} :p_c_since {} :p_c_credit {0} :p_c_credit_lim {} :p_c_discount {} :p_c_balance {0} :p_c_data {} :timestamp $h_date
if {[ catch {oraexec $curn_py} message]} {
if { $RAISEERROR } {
error "Payment : $message [ oramsg $curn_py all ]"
	} else {
;
} } else {
orafetch  $curn_py -datavariable output
;
	}
}
#ORDER_STATUS
proc ostat { curn_os w_id RAISEERROR } {
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
orabind $curn_os :os_w_id $w_id :os_d_id $d_id :os_c_id $c_id :byname $byname :os_c_last $name :os_c_first {} :os_c_middle {} :os_c_balance {0} :os_o_id {} :os_entdate {} :os_o_carrier_id {}
if {[catch {oraexec $curn_os} message]} {
if { $RAISEERROR } {
error "Order Status : $message [ oramsg $curn_os all ]"
	} else {
;
} } else {
orafetch  $curn_os -datavariable output
;
	}
}
#DELIVERY
proc delivery { curn_dl w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
orabind $curn_dl :d_w_id $w_id :d_o_carrier_id $carrier_id :timestamp $date
if {[ catch {oraexec $curn_dl} message ]} {
if { $RAISEERROR } {
error "Delivery : $message [ oramsg $curn_dl all ]"
	} else {
;
} } else {
orafetch  $curn_dl -datavariable output
;
	}
}
#STOCK LEVEL
proc slev { curn_sl w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
orabind $curn_sl :st_w_id $w_id :st_d_id $stock_level_d_id :THRESHOLD $threshold 
if {[catch {oraexec $curn_sl} message]} { 
if { $RAISEERROR } {
error "Stock Level : $message [ oramsg $curn_sl all ]"
	} else {
;
} } else {
orafetch  $curn_sl -datavariable output
;
	}
}

proc prep_statement { lda curn_st } {
switch $curn_st {
curn_sl {
set curn_sl [oraopen $lda ]
set sql_sl "BEGIN slev(:st_w_id,:st_d_id,:threshold); END;"
oraparse $curn_sl $sql_sl
return $curn_sl
	}
curn_dl {
set curn_dl [oraopen $lda ]
set sql_dl "BEGIN delivery(:d_w_id,:d_o_carrier_id,TO_DATE(:timestamp,'YYYYMMDDHH24MISS')); END;"
oraparse $curn_dl $sql_dl
return $curn_dl
	}
curn_os {
set curn_os [oraopen $lda ]
set sql_os "BEGIN ostat(:os_w_id,:os_d_id,:os_c_id,:byname,:os_c_last,:os_c_first,:os_c_middle,:os_c_balance,:os_o_id,:os_entdate,:os_o_carrier_id); END;"
oraparse $curn_os $sql_os
return $curn_os
	}
curn_py {
set curn_py [oraopen $lda ]
set sql_py "BEGIN payment(:p_w_id,:p_d_id,:p_c_w_id,:p_c_d_id,:p_c_id,:byname,:p_h_amount,:p_c_last,:p_w_street_1,:p_w_street_2,:p_w_city,:p_w_state,:p_w_zip,:p_d_street_1,:p_d_street_2,:p_d_city,:p_d_state,:p_d_zip,:p_c_first,:p_c_middle,:p_c_street_1,:p_c_street_2,:p_c_city,:p_c_state,:p_c_zip,:p_c_phone,:p_c_since,:p_c_credit,:p_c_credit_lim,:p_c_discount,:p_c_balance,:p_c_data,TO_DATE(:timestamp,'YYYYMMDDHH24MISS')); END;"
oraparse $curn_py $sql_py
return $curn_py
	}
curn_no {
set curn_no [oraopen $lda ]
set sql_no "begin neword(:no_w_id,:no_max_w_id,:no_d_id,:no_c_id,:no_o_ol_cnt,:no_c_discount,:no_c_last,:no_c_credit,:no_d_tax,:no_w_tax,:no_d_next_o_id,TO_DATE(:timestamp,'YYYYMMDDHH24MISS')); END;"
oraparse $curn_no $sql_no
return $curn_no
	}
    }
}
#RUN TPC-C
set lda [oralogon $connect]
if { !$timesten } { SetNLS $lda }
oraautocom $lda on
foreach curn_st {curn_no curn_py curn_dl curn_sl curn_os} { set $curn_st [ prep_statement $lda $curn_st ] }
set curn1 [oraopen $lda ]
set sql1 "select max(w_id) from warehouse"
set w_id_input [ standsql $curn1 $sql1 ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set sql2 "select max(d_id) from district"
set d_id_input [ standsql $curn1 $sql2 ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
set sql3 "BEGIN DBMS_RANDOM.initialize (val => TO_NUMBER(TO_CHAR(SYSDATE,'MMSS')) * (USERENV('SESSIONID') - TRUNC(USERENV('SESSIONID'),-5))); END;"
oraparse $curn1 $sql3
if {[catch {oraplexec $curn1 $sql3} message]} {
error "Failed to initialise DBMS_RANDOM $message have you run catoctk.sql as sys?" }
oraclose $curn1
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword $curn_no $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment $curn_py $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery $curn_dl $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev $curn_sl $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat $curn_os $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
oraclose $curn_no
oraclose $curn_py
oraclose $curn_dl
oraclose $curn_sl
oraclose $curn_os
oralogoff $lda
	}
     }
  } 
}

proc check_mssqltpcc {} {
global mssqls_server mssqls_port mssqls_authentication mssqls_odbc_driver mssqls_count_ware mssqls_schema mssqls_num_threads mssqls_uid mssqls_pass mssqls_dbase maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists mssqls_server ] } { set mssqls_server "(local)" }
if {  ![ info exists mssqls_port ] } { set mssqls_port "1433" }
if {  ![ info exists mssqls_count_ware ] } { set mssqls_count_ware "1" }
if {  ![ info exists mssqls_authentication ] } { set mssqls_authentication "windows" }
if {  ![ info exists mssqls_odbc_driver ] } { set mssqls_odbc_driver "SQL Server Native Client 10.0" }
if {  ![ info exists mssqls_uid ] } { set mssqls_uid "sa" }
if {  ![ info exists mssqls_pass ] } { set mssqls_pass "admin" }
if {  ![ info exists mssqls_dbase ] } { set mssqls_dbase "tpcc" }
if {  ![ info exists mssqls_schema ] } { set mssqls_schema "updated" }
if {  ![ info exists mssqls_num_threads ] } { set mssqls_num_threads "1" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a $mssqls_count_ware Warehouse MS SQL Server TPC-C schema\nin host [string toupper $mssqls_server:$mssqls_port] in database [ string toupper $mssqls_dbase ]?" -type yesno ] == yes} { 
if { $mssqls_num_threads eq 1 || $mssqls_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $mssqls_num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to created thread for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require tclodbc 2.5.1} ] { error "Failed to load tclodbc - ODBC Library Error" }
proc CreateStoredProcs { odbc schema } {
if { $schema != "updated" } {
#original stored procedures from SSMA
puts "CREATING TPCC STORED PROCEDURES"
set sql(1) {CREATE PROCEDURE dbo.NEWORD  
@no_w_id int,
@no_max_w_id int,
@no_d_id int,
@no_c_id int,
@no_o_ol_cnt int,
@TIMESTAMP datetime2(0)
AS 
BEGIN
DECLARE
@no_c_discount smallmoney,
@no_c_last char(16),
@no_c_credit char(2),
@no_d_tax smallmoney,
@no_w_tax smallmoney,
@no_d_next_o_id int,
@no_ol_supply_w_id int, 
@no_ol_i_id int, 
@no_ol_quantity int, 
@no_o_all_local int, 
@o_id int, 
@no_i_name char(24), 
@no_i_price smallmoney, 
@no_i_data char(50), 
@no_s_quantity int, 
@no_ol_amount int, 
@no_s_dist_01 char(24), 
@no_s_dist_02 char(24), 
@no_s_dist_03 char(24), 
@no_s_dist_04 char(24), 
@no_s_dist_05 char(24), 
@no_s_dist_06 char(24), 
@no_s_dist_07 char(24), 
@no_s_dist_08 char(24), 
@no_s_dist_09 char(24), 
@no_s_dist_10 char(24), 
@no_ol_dist_info char(24), 
@no_s_data char(50), 
@x int, 
@rbk int
BEGIN TRANSACTION
BEGIN TRY
SET @no_o_all_local = 0
SELECT @no_c_discount = CUSTOMER.C_DISCOUNT, @no_c_last = CUSTOMER.C_LAST, @no_c_credit = CUSTOMER.C_CREDIT, @no_w_tax = WAREHOUSE.W_TAX FROM dbo.CUSTOMER, dbo.WAREHOUSE WHERE WAREHOUSE.W_ID = @no_w_id AND CUSTOMER.C_W_ID = @no_w_id AND CUSTOMER.C_D_ID = @no_d_id AND CUSTOMER.C_ID = @no_c_id
UPDATE dbo.DISTRICT SET @no_d_tax = d_tax, @o_id = D_NEXT_O_ID,  D_NEXT_O_ID = DISTRICT.D_NEXT_O_ID + 1 WHERE DISTRICT.D_ID = @no_d_id AND DISTRICT.D_W_ID = @no_w_id
INSERT dbo.ORDERS( O_ID, O_D_ID, O_W_ID, O_C_ID, O_ENTRY_D, O_OL_CNT, O_ALL_LOCAL) VALUES ( @o_id, @no_d_id, @no_w_id, @no_c_id, @TIMESTAMP, @no_o_ol_cnt, @no_o_all_local)
INSERT dbo.NEW_ORDER(NO_O_ID, NO_D_ID, NO_W_ID) VALUES (@o_id, @no_d_id, @no_w_id)
SET @rbk = CAST(100 * RAND() + 1 AS INT)
DECLARE
@loop_counter int
SET @loop_counter = 1
DECLARE
@loop$bound int
SET @loop$bound = @no_o_ol_cnt
WHILE @loop_counter <= @loop$bound
BEGIN
IF ((@loop_counter = @no_o_ol_cnt) AND (@rbk = 1))
SET @no_ol_i_id = 100001
ELSE 
SET @no_ol_i_id =  CAST(1000000 * RAND() + 1 AS INT)
SET @x = CAST(100 * RAND() + 1 AS INT)
IF (@x > 1)
SET @no_ol_supply_w_id = @no_w_id
ELSE 
BEGIN
SET @no_ol_supply_w_id = @no_w_id
SET @no_o_all_local = 0
WHILE ((@no_ol_supply_w_id = @no_w_id) AND (@no_max_w_id != 1))
BEGIN
SET @no_ol_supply_w_id = CAST(@no_max_w_id * RAND() + 1 AS INT)
DECLARE
@db_null_statement$2 int
END
END
SET @no_ol_quantity = CAST(10 * RAND() + 1 AS INT)
SELECT @no_i_price = ITEM.I_PRICE, @no_i_name = ITEM.I_NAME, @no_i_data = ITEM.I_DATA FROM dbo.ITEM WHERE ITEM.I_ID = @no_ol_i_id
SELECT @no_s_quantity = STOCK.S_QUANTITY, @no_s_data = STOCK.S_DATA, @no_s_dist_01 = STOCK.S_DIST_01, @no_s_dist_02 = STOCK.S_DIST_02, @no_s_dist_03 = STOCK.S_DIST_03, @no_s_dist_04 = STOCK.S_DIST_04, @no_s_dist_05 = STOCK.S_DIST_05, @no_s_dist_06 = STOCK.S_DIST_06, @no_s_dist_07 = STOCK.S_DIST_07, @no_s_dist_08 = STOCK.S_DIST_08, @no_s_dist_09 = STOCK.S_DIST_09, @no_s_dist_10 = STOCK.S_DIST_10 FROM dbo.STOCK WHERE STOCK.S_I_ID = @no_ol_i_id AND STOCK.S_W_ID = @no_ol_supply_w_id
IF (@no_s_quantity > @no_ol_quantity)
SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity)
ELSE 
SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity + 91)
UPDATE dbo.STOCK SET S_QUANTITY = @no_s_quantity WHERE STOCK.S_I_ID = @no_ol_i_id AND STOCK.S_W_ID = @no_ol_supply_w_id
SET @no_ol_amount = (@no_ol_quantity * @no_i_price * (1 + @no_w_tax + @no_d_tax) * (1 - @no_c_discount))
IF @no_d_id = 1
SET @no_ol_dist_info = @no_s_dist_01
ELSE 
IF @no_d_id = 2
SET @no_ol_dist_info = @no_s_dist_02
ELSE 
IF @no_d_id = 3
SET @no_ol_dist_info = @no_s_dist_03
ELSE 
IF @no_d_id = 4
SET @no_ol_dist_info = @no_s_dist_04
ELSE 
IF @no_d_id = 5
SET @no_ol_dist_info = @no_s_dist_05
ELSE 
IF @no_d_id = 6
SET @no_ol_dist_info = @no_s_dist_06
ELSE 
IF @no_d_id = 7
SET @no_ol_dist_info = @no_s_dist_07
ELSE 
IF @no_d_id = 8
SET @no_ol_dist_info = @no_s_dist_08
ELSE 
IF @no_d_id = 9
SET @no_ol_dist_info = @no_s_dist_09
ELSE 
BEGIN
IF @no_d_id = 10
SET @no_ol_dist_info = @no_s_dist_10
END
INSERT dbo.ORDER_LINE( OL_O_ID, OL_D_ID, OL_W_ID, OL_NUMBER, OL_I_ID, OL_SUPPLY_W_ID, OL_QUANTITY, OL_AMOUNT, OL_DIST_INFO) VALUES ( @o_id, @no_d_id, @no_w_id, @loop_counter, @no_ol_i_id, @no_ol_supply_w_id, @no_ol_quantity, @no_ol_amount, @no_ol_dist_info)
SET @loop_counter = @loop_counter + 1
END
SELECT convert(char(8), @no_c_discount) as N'@no_c_discount', @no_c_last as N'@no_c_last', @no_c_credit as N'@no_c_credit', convert(char(8),@no_d_tax) as N'@no_d_tax', convert(char(8),@no_w_tax) as N'@no_w_tax', @no_d_next_o_id as N'@no_d_next_o_id'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(2) {CREATE PROCEDURE dbo.DELIVERY  
@d_w_id int,
@d_o_carrier_id int,
@TIMESTAMP datetime2(0)
AS 
BEGIN
DECLARE
@d_no_o_id int, 
@d_d_id int, 
@d_c_id int, 
@d_ol_total int
BEGIN TRANSACTION
BEGIN TRY
DECLARE
@loop_counter int
SET @loop_counter = 1
WHILE @loop_counter <= 10
BEGIN
SET @d_d_id = @loop_counter
SELECT TOP (1) @d_no_o_id = NEW_ORDER.NO_O_ID FROM dbo.NEW_ORDER WITH (serializable updlock) WHERE  NEW_ORDER.NO_W_ID = @d_w_id AND NEW_ORDER.NO_D_ID = @d_d_id
DELETE dbo.NEW_ORDER WHERE NEW_ORDER.NO_W_ID = @d_w_id AND NEW_ORDER.NO_D_ID = @d_d_id AND NEW_ORDER.NO_O_ID =  @d_no_o_id
SELECT @d_c_id = ORDERS.O_C_ID FROM dbo.ORDERS WHERE ORDERS.O_ID = @d_no_o_id AND ORDERS.O_D_ID = @d_d_id AND ORDERS.O_W_ID = @d_w_id
UPDATE dbo.ORDERS SET O_CARRIER_ID = @d_o_carrier_id WHERE ORDERS.O_ID = @d_no_o_id AND ORDERS.O_D_ID = @d_d_id AND ORDERS.O_W_ID = @d_w_id
UPDATE dbo.ORDER_LINE SET OL_DELIVERY_D = @TIMESTAMP WHERE ORDER_LINE.OL_O_ID = @d_no_o_id AND ORDER_LINE.OL_D_ID = @d_d_id AND ORDER_LINE.OL_W_ID = @d_w_id
SELECT @d_ol_total = sum(ORDER_LINE.OL_AMOUNT) FROM dbo.ORDER_LINE WHERE ORDER_LINE.OL_O_ID = @d_no_o_id AND ORDER_LINE.OL_D_ID = @d_d_id AND ORDER_LINE.OL_W_ID = @d_w_id
UPDATE dbo.CUSTOMER SET C_BALANCE = CUSTOMER.C_BALANCE + @d_ol_total WHERE CUSTOMER.C_ID = @d_c_id AND CUSTOMER.C_D_ID = @d_d_id AND CUSTOMER.C_W_ID = @d_w_id
IF @@TRANCOUNT > 0
COMMIT WORK 
PRINT 
'D: '
+ 
ISNULL(CAST(@d_d_id AS nvarchar(max)), '')
+ 
'O: '
+ 
ISNULL(CAST(@d_no_o_id AS nvarchar(max)), '')
+ 
'time '
+ 
ISNULL(CAST(@TIMESTAMP AS nvarchar(max)), '')
SET @loop_counter = @loop_counter + 1
END
SELECT	@d_w_id as N'@d_w_id', @d_o_carrier_id as N'@d_o_carrier_id', @TIMESTAMP as N'@TIMESTAMP'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(3) {CREATE PROCEDURE dbo.PAYMENT  
@p_w_id int,
@p_d_id int,
@p_c_w_id int,
@p_c_d_id int,
@p_c_id int,
@byname int,
@p_h_amount numeric(6,2),
@p_c_last char(16),
@TIMESTAMP datetime2(0)
AS 
BEGIN
DECLARE
@p_w_street_1 char(20),
@p_w_street_2 char(20),
@p_w_city char(20),
@p_w_state char(2),
@p_w_zip char(10),
@p_d_street_1 char(20),
@p_d_street_2 char(20),
@p_d_city char(20),
@p_d_state char(20),
@p_d_zip char(10),
@p_c_first char(16),
@p_c_middle char(2),
@p_c_street_1 char(20),
@p_c_street_2 char(20),
@p_c_city char(20),
@p_c_state char(20),
@p_c_zip char(9),
@p_c_phone char(16),
@p_c_since datetime2(0),
@p_c_credit char(32),
@p_c_credit_lim  numeric(12,2), 
@p_c_discount  numeric(4,4),
@p_c_balance numeric(12,2),
@p_c_data varchar(500),
@namecnt int, 
@p_d_name char(11), 
@p_w_name char(11), 
@p_c_new_data varchar(500), 
@h_data varchar(30)
BEGIN TRANSACTION
BEGIN TRY
UPDATE dbo.WAREHOUSE SET W_YTD = WAREHOUSE.W_YTD + @p_h_amount WHERE WAREHOUSE.W_ID = @p_w_id
SELECT @p_w_street_1 = WAREHOUSE.W_STREET_1, @p_w_street_2 = WAREHOUSE.W_STREET_2, @p_w_city = WAREHOUSE.W_CITY, @p_w_state = WAREHOUSE.W_STATE, @p_w_zip = WAREHOUSE.W_ZIP, @p_w_name = WAREHOUSE.W_NAME FROM dbo.WAREHOUSE WHERE WAREHOUSE.W_ID = @p_w_id
UPDATE dbo.DISTRICT SET D_YTD = DISTRICT.D_YTD + @p_h_amount WHERE DISTRICT.D_W_ID = @p_w_id AND DISTRICT.D_ID = @p_d_id
SELECT @p_d_street_1 = DISTRICT.D_STREET_1, @p_d_street_2 = DISTRICT.D_STREET_2, @p_d_city = DISTRICT.D_CITY, @p_d_state = DISTRICT.D_STATE, @p_d_zip = DISTRICT.D_ZIP, @p_d_name = DISTRICT.D_NAME FROM dbo.DISTRICT WHERE DISTRICT.D_W_ID = @p_w_id AND DISTRICT.D_ID = @p_d_id
IF (@byname = 1)
BEGIN
SELECT @namecnt = count(CUSTOMER.C_ID) FROM dbo.CUSTOMER WITH (repeatableread) WHERE CUSTOMER.C_LAST = @p_c_last AND CUSTOMER.C_D_ID = @p_c_d_id AND CUSTOMER.C_W_ID = @p_c_w_id
DECLARE
c_byname CURSOR LOCAL FOR 
SELECT CUSTOMER.C_FIRST, CUSTOMER.C_MIDDLE, CUSTOMER.C_ID, CUSTOMER.C_STREET_1, CUSTOMER.C_STREET_2, CUSTOMER.C_CITY, CUSTOMER.C_STATE, CUSTOMER.C_ZIP, CUSTOMER.C_PHONE, CUSTOMER.C_CREDIT, CUSTOMER.C_CREDIT_LIM, CUSTOMER.C_DISCOUNT, CUSTOMER.C_BALANCE, CUSTOMER.C_SINCE FROM dbo.CUSTOMER WITH (repeatableread) WHERE CUSTOMER.C_W_ID = @p_c_w_id AND CUSTOMER.C_D_ID = @p_c_d_id AND CUSTOMER.C_LAST = @p_c_last ORDER BY CUSTOMER.C_FIRST
OPEN c_byname
IF ((@namecnt % 2) = 1)
SET @namecnt = (@namecnt + 1)
BEGIN
DECLARE
@loop_counter int
SET @loop_counter = 0
DECLARE
@loop$bound int
SET @loop$bound = (@namecnt / 2)
WHILE @loop_counter <= @loop$bound
BEGIN
FETCH c_byname
INTO 
@p_c_first, 
@p_c_middle, 
@p_c_id, 
@p_c_street_1, 
@p_c_street_2, 
@p_c_city, 
@p_c_state, 
@p_c_zip, 
@p_c_phone, 
@p_c_credit, 
@p_c_credit_lim, 
@p_c_discount, 
@p_c_balance, 
@p_c_since
SET @loop_counter = @loop_counter + 1
END
END
CLOSE c_byname
DEALLOCATE c_byname
END
ELSE 
BEGIN
SELECT @p_c_first = CUSTOMER.C_FIRST, @p_c_middle = CUSTOMER.C_MIDDLE, @p_c_last = CUSTOMER.C_LAST, @p_c_street_1 = CUSTOMER.C_STREET_1, @p_c_street_2 = CUSTOMER.C_STREET_2, @p_c_city = CUSTOMER.C_CITY, @p_c_state = CUSTOMER.C_STATE, @p_c_zip = CUSTOMER.C_ZIP, @p_c_phone = CUSTOMER.C_PHONE, @p_c_credit = CUSTOMER.C_CREDIT, @p_c_credit_lim = CUSTOMER.C_CREDIT_LIM, @p_c_discount = CUSTOMER.C_DISCOUNT, @p_c_balance = CUSTOMER.C_BALANCE, @p_c_since = CUSTOMER.C_SINCE FROM dbo.CUSTOMER WHERE CUSTOMER.C_W_ID = @p_c_w_id AND CUSTOMER.C_D_ID = @p_c_d_id AND CUSTOMER.C_ID = @p_c_id 
END
SET @p_c_balance = (@p_c_balance + @p_h_amount)
IF @p_c_credit = 'BC'
BEGIN
SELECT @p_c_data = CUSTOMER.C_DATA FROM dbo.CUSTOMER WHERE CUSTOMER.C_W_ID = @p_c_w_id AND CUSTOMER.C_D_ID = @p_c_d_id AND CUSTOMER.C_ID = @p_c_id
SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))
SET @p_c_new_data = (
ISNULL(CAST(@p_c_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_c_d_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_c_w_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_d_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_w_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_h_amount AS CHAR(8)), '')
 + 
ISNULL(CAST(@TIMESTAMP AS char), '')
 + 
ISNULL(@h_data, ''))
SET @p_c_new_data = substring((@p_c_new_data + @p_c_data), 1, 500 - LEN(@p_c_new_data))
UPDATE dbo.CUSTOMER SET C_BALANCE = @p_c_balance, C_DATA = @p_c_new_data WHERE CUSTOMER.C_W_ID = @p_c_w_id AND CUSTOMER.C_D_ID = @p_c_d_id AND CUSTOMER.C_ID = @p_c_id
END
ELSE 
UPDATE dbo.CUSTOMER SET C_BALANCE = @p_c_balance WHERE CUSTOMER.C_W_ID = @p_c_w_id AND CUSTOMER.C_D_ID = @p_c_d_id AND CUSTOMER.C_ID = @p_c_id
SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))
INSERT dbo.HISTORY( H_C_D_ID, H_C_W_ID, H_C_ID, H_D_ID, H_W_ID, H_DATE, H_AMOUNT, H_DATA) VALUES ( @p_c_d_id, @p_c_w_id, @p_c_id, @p_d_id, @p_w_id, @TIMESTAMP, @p_h_amount, @h_data)
SELECT	@p_c_id as N'@p_c_id', @p_c_last as N'@p_c_last', @p_w_street_1 as N'@p_w_street_1', @p_w_street_2 as N'@p_w_street_2', @p_w_city as N'@p_w_city', @p_w_state as N'@p_w_state', @p_w_zip as N'@p_w_zip', @p_d_street_1 as N'@p_d_street_1', @p_d_street_2 as N'@p_d_street_2', @p_d_city as N'@p_d_city', @p_d_state as N'@p_d_state', @p_d_zip as N'@p_d_zip', @p_c_first as N'@p_c_first', @p_c_middle as N'@p_c_middle', @p_c_street_1 as N'@p_c_street_1', @p_c_street_2 as N'@p_c_street_2', @p_c_city as N'@p_c_city', @p_c_state as N'@p_c_state', @p_c_zip as N'@p_c_zip', @p_c_phone as N'@p_c_phone', @p_c_since as N'@p_c_since', @p_c_credit as N'@p_c_credit', @p_c_credit_lim as N'@p_c_credit_lim', @p_c_discount as N'@p_c_discount', @p_c_balance as N'@p_c_balance', @p_c_data as N'@p_c_data'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(4) {CREATE PROCEDURE dbo.OSTAT 
@os_w_id int,
@os_d_id int,
@os_c_id int,
@byname int,
@os_c_last char(20)
AS 
BEGIN
DECLARE
@os_c_first char(16),
@os_c_middle char(2),
@os_c_balance money,
@os_o_id int,
@os_entdate datetime2(0),
@os_o_carrier_id int,
@os_ol_i_id 	INT,
@os_ol_supply_w_id INT,
@os_ol_quantity INT,
@os_ol_amount 	INT,
@os_ol_delivery_d DATE,
@namecnt int, 
@i int,
@os_ol_i_id_array VARCHAR(200),
@os_ol_supply_w_id_array VARCHAR(200),
@os_ol_quantity_array VARCHAR(200),
@os_ol_amount_array VARCHAR(200),
@os_ol_delivery_d_array VARCHAR(210)
BEGIN TRANSACTION
BEGIN TRY
SET @os_ol_i_id_array = 'CSV,'
SET @os_ol_supply_w_id_array = 'CSV,'
SET @os_ol_quantity_array = 'CSV,'
SET @os_ol_amount_array = 'CSV,'
SET @os_ol_delivery_d_array = 'CSV,'
IF (@byname = 1)
BEGIN
SELECT @namecnt = count_big(CUSTOMER.C_ID) FROM dbo.CUSTOMER WHERE CUSTOMER.C_LAST = @os_c_last AND CUSTOMER.C_D_ID = @os_d_id AND CUSTOMER.C_W_ID = @os_w_id
IF ((@namecnt % 2) = 1)
SET @namecnt = (@namecnt + 1)
DECLARE
c_name CURSOR LOCAL FOR 
SELECT CUSTOMER.C_BALANCE, CUSTOMER.C_FIRST, CUSTOMER.C_MIDDLE, CUSTOMER.C_ID FROM dbo.CUSTOMER WHERE CUSTOMER.C_LAST = @os_c_last AND CUSTOMER.C_D_ID = @os_d_id AND CUSTOMER.C_W_ID = @os_w_id ORDER BY CUSTOMER.C_FIRST
OPEN c_name
BEGIN
DECLARE
@loop_counter int
SET @loop_counter = 0
DECLARE
@loop$bound int
SET @loop$bound = (@namecnt / 2)
WHILE @loop_counter <= @loop$bound
BEGIN
FETCH c_name
INTO @os_c_balance, @os_c_first, @os_c_middle, @os_c_id
SET @loop_counter = @loop_counter + 1
END
END
CLOSE c_name
DEALLOCATE c_name
END
ELSE 
BEGIN
SELECT @os_c_balance = CUSTOMER.C_BALANCE, @os_c_first = CUSTOMER.C_FIRST, @os_c_middle = CUSTOMER.C_MIDDLE, @os_c_last = CUSTOMER.C_LAST FROM dbo.CUSTOMER WITH (repeatableread) WHERE CUSTOMER.C_ID = @os_c_id AND CUSTOMER.C_D_ID = @os_d_id AND CUSTOMER.C_W_ID = @os_w_id
END
BEGIN
SELECT TOP (1) @os_o_id = fci.O_ID, @os_o_carrier_id = fci.O_CARRIER_ID, @os_entdate = fci.O_ENTRY_D
FROM 
(SELECT TOP 9223372036854775807 ORDERS.O_ID, ORDERS.O_CARRIER_ID, ORDERS.O_ENTRY_D FROM dbo.ORDERS WITH (serializable) WHERE ORDERS.O_D_ID = @os_d_id AND ORDERS.O_W_ID = @os_w_id AND ORDERS.O_C_ID = @os_c_id ORDER BY ORDERS.O_ID DESC)  AS fci
IF @@ROWCOUNT = 0
PRINT 'No orders for customer';
END
SET @i = 0
DECLARE
c_line CURSOR LOCAL FORWARD_ONLY FOR 
SELECT ORDER_LINE.OL_I_ID, ORDER_LINE.OL_SUPPLY_W_ID, ORDER_LINE.OL_QUANTITY, ORDER_LINE.OL_AMOUNT, ORDER_LINE.OL_DELIVERY_D FROM dbo.ORDER_LINE WITH (repeatableread) WHERE ORDER_LINE.OL_O_ID = @os_o_id AND ORDER_LINE.OL_D_ID = @os_d_id AND ORDER_LINE.OL_W_ID = @os_w_id
OPEN c_line
WHILE 1 = 1
BEGIN
FETCH c_line
INTO 
@os_ol_i_id,
@os_ol_supply_w_id,
@os_ol_quantity,
@os_ol_amount,
@os_ol_delivery_d
IF @@FETCH_STATUS = -1
BREAK
set @os_ol_i_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_i_id AS CHAR)
set @os_ol_supply_w_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_supply_w_id AS CHAR)
set @os_ol_quantity_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_quantity AS CHAR)
set @os_ol_amount_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_amount AS CHAR);
set @os_ol_delivery_d_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_delivery_d AS CHAR)
SET @i = @i + 1
END
CLOSE c_line
DEALLOCATE c_line
SELECT	@os_c_id as N'@os_c_id', @os_c_last as N'@os_c_last', @os_c_first as N'@os_c_first', @os_c_middle as N'@os_c_middle', @os_c_balance as N'@os_c_balance', @os_o_id as N'@os_o_id', @os_entdate as N'@os_entdate', @os_o_carrier_id as N'@os_o_carrier_id'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(5) {CREATE PROCEDURE dbo.SLEV  
@st_w_id int,
@st_d_id int,
@threshold int
AS 
BEGIN
DECLARE
@st_o_id int, 
@stock_count int 
BEGIN TRANSACTION
BEGIN TRY
SELECT @st_o_id = DISTRICT.D_NEXT_O_ID FROM dbo.DISTRICT WHERE DISTRICT.D_W_ID = @st_w_id AND DISTRICT.D_ID = @st_d_id
SELECT @stock_count = count_big(DISTINCT STOCK.S_I_ID) FROM dbo.ORDER_LINE, dbo.STOCK WHERE ORDER_LINE.OL_W_ID = @st_w_id AND ORDER_LINE.OL_D_ID = @st_d_id AND (ORDER_LINE.OL_O_ID < @st_o_id) AND ORDER_LINE.OL_O_ID >= (@st_o_id - 20) AND STOCK.S_W_ID = @st_w_id AND STOCK.S_I_ID = ORDER_LINE.OL_I_ID AND STOCK.S_QUANTITY < @threshold
SELECT	@st_o_id as N'@st_o_id', @stock_count as N'@stock_count'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
for { set i 1 } { $i <= 5 } { incr i } {
odbc  $sql($i)
		}
return
	} else {
#Updated stored procedures provided by Thomas Kejser
puts "CREATING TPCC STORED PROCEDURES"
set sql(1) {CREATE PROCEDURE [dbo].[NEWORD]  
@no_w_id int,
@no_max_w_id int,
@no_d_id int,
@no_c_id int,
@no_o_ol_cnt int,
@TIMESTAMP datetime2(0)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@no_c_discount smallmoney,
@no_c_last char(16),
@no_c_credit char(2),
@no_d_tax smallmoney,
@no_w_tax smallmoney,
@no_d_next_o_id int,
@no_ol_supply_w_id int, 
@no_ol_i_id int, 
@no_ol_quantity int, 
@no_o_all_local int, 
@o_id int, 
@no_i_name char(24), 
@no_i_price smallmoney, 
@no_i_data char(50), 
@no_s_quantity int, 
@no_ol_amount int, 
@no_s_dist_01 char(24), 
@no_s_dist_02 char(24), 
@no_s_dist_03 char(24), 
@no_s_dist_04 char(24), 
@no_s_dist_05 char(24), 
@no_s_dist_06 char(24), 
@no_s_dist_07 char(24), 
@no_s_dist_08 char(24), 
@no_s_dist_09 char(24), 
@no_s_dist_10 char(24), 
@no_ol_dist_info char(24), 
@no_s_data char(50), 
@x int, 
@rbk int
BEGIN TRANSACTION
BEGIN TRY

SET @no_o_all_local = 0
SELECT @no_c_discount = CUSTOMER.c_discount
, @no_c_last = CUSTOMER.c_last
, @no_c_credit = CUSTOMER.c_credit
, @no_w_tax = WAREHOUSE.w_tax 
FROM dbo.CUSTOMER, dbo.WAREHOUSE WITH (INDEX = W_Details)
WHERE WAREHOUSE.w_id = @no_w_id 
AND CUSTOMER.c_w_id = @no_w_id 
AND CUSTOMER.c_d_id = @no_d_id 
AND CUSTOMER.c_id = @no_c_id

UPDATE dbo.DISTRICT 
SET @no_d_tax = d_tax
, @o_id = d_next_o_id
,  d_next_o_id = DISTRICT.d_next_o_id + 1 
WHERE DISTRICT.d_id = @no_d_id 
AND DISTRICT.d_w_id = @no_w_id

INSERT dbo.ORDERS( o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) 
VALUES ( @o_id, @no_d_id, @no_w_id, @no_c_id, @TIMESTAMP, @no_o_ol_cnt, @no_o_all_local)

INSERT dbo.NEW_ORDER(no_o_id, no_d_id, no_w_id) 
VALUES (@o_id, @no_d_id, @no_w_id)

SET @rbk = CAST(100 * RAND() + 1 AS INT)
DECLARE
@loop_counter int
SET @loop_counter = 1
DECLARE
@loop$bound int
SET @loop$bound = @no_o_ol_cnt
WHILE @loop_counter <= @loop$bound
BEGIN
IF ((@loop_counter = @no_o_ol_cnt) AND (@rbk = 1))
SET @no_ol_i_id = 100001
ELSE 
SET @no_ol_i_id =  CAST(1000000 * RAND() + 1 AS INT)
SET @x = CAST(100 * RAND() + 1 AS INT)
IF (@x > 1)
SET @no_ol_supply_w_id = @no_w_id
ELSE 
BEGIN
SET @no_ol_supply_w_id = @no_w_id
SET @no_o_all_local = 0
WHILE ((@no_ol_supply_w_id = @no_w_id) AND (@no_max_w_id != 1))
BEGIN
SET @no_ol_supply_w_id = CAST(@no_max_w_id * RAND() + 1 AS INT)
DECLARE
@db_null_statement$2 int
END
END
SET @no_ol_quantity = CAST(10 * RAND() + 1 AS INT)

SELECT @no_i_price = ITEM.i_price
, @no_i_name = ITEM.i_name
, @no_i_data = ITEM.i_data 
FROM dbo.ITEM 
WHERE ITEM.i_id = @no_ol_i_id

SELECT @no_s_quantity = STOCK.s_quantity
, @no_s_data = STOCK.s_data
, @no_s_dist_01 = STOCK.s_dist_01
, @no_s_dist_02 = STOCK.s_dist_02
, @no_s_dist_03 = STOCK.s_dist_03
, @no_s_dist_04 = STOCK.s_dist_04
, @no_s_dist_05 = STOCK.s_dist_05
, @no_s_dist_06 = STOCK.s_dist_06
, @no_s_dist_07 = STOCK.s_dist_07
, @no_s_dist_08 = STOCK.s_dist_08
, @no_s_dist_09 = STOCK.s_dist_09
, @no_s_dist_10 = STOCK.s_dist_10 
FROM dbo.STOCK
WHERE STOCK.s_i_id = @no_ol_i_id 
AND STOCK.s_w_id = @no_ol_supply_w_id


IF (@no_s_quantity > @no_ol_quantity)
SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity)
ELSE 
SET @no_s_quantity = (@no_s_quantity - @no_ol_quantity + 91)

UPDATE dbo.STOCK
SET s_quantity = @no_s_quantity 
WHERE STOCK.s_i_id = @no_ol_i_id 
AND STOCK.s_w_id = @no_ol_supply_w_id

SET @no_ol_amount = (@no_ol_quantity * @no_i_price * (1 + @no_w_tax + @no_d_tax) * (1 - @no_c_discount))
IF @no_d_id = 1
SET @no_ol_dist_info = @no_s_dist_01
ELSE 
IF @no_d_id = 2
SET @no_ol_dist_info = @no_s_dist_02
ELSE 
IF @no_d_id = 3
SET @no_ol_dist_info = @no_s_dist_03
ELSE 
IF @no_d_id = 4
SET @no_ol_dist_info = @no_s_dist_04
ELSE 
IF @no_d_id = 5
SET @no_ol_dist_info = @no_s_dist_05
ELSE 
IF @no_d_id = 6
SET @no_ol_dist_info = @no_s_dist_06
ELSE 
IF @no_d_id = 7
SET @no_ol_dist_info = @no_s_dist_07
ELSE 
IF @no_d_id = 8
SET @no_ol_dist_info = @no_s_dist_08
ELSE 
IF @no_d_id = 9
SET @no_ol_dist_info = @no_s_dist_09
ELSE 
BEGIN
IF @no_d_id = 10
SET @no_ol_dist_info = @no_s_dist_10
END
INSERT dbo.ORDER_LINE( ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES ( @o_id, @no_d_id, @no_w_id, @loop_counter, @no_ol_i_id, @no_ol_supply_w_id, @no_ol_quantity, @no_ol_amount, @no_ol_dist_info)
SET @loop_counter = @loop_counter + 1
END
SELECT convert(char(8), @no_c_discount) as N'@no_c_discount', @no_c_last as N'@no_c_last', @no_c_credit as N'@no_c_credit', convert(char(8),@no_d_tax) as N'@no_d_tax', convert(char(8),@no_w_tax) as N'@no_w_tax', @no_d_next_o_id as N'@no_d_next_o_id'

END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;

END}
set sql(2) {CREATE PROCEDURE [dbo].[DELIVERY]  
@d_w_id int,
@d_o_carrier_id int,
@timestamp datetime2(0)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@d_no_o_id int, 
@d_d_id int, 
@d_c_id int, 
@d_ol_total int
BEGIN TRANSACTION
BEGIN TRY
DECLARE
@loop_counter int
SET @loop_counter = 1
WHILE @loop_counter <= 10
BEGIN
SET @d_d_id = @loop_counter


DECLARE @d_out TABLE (d_no_o_id INT)

DELETE TOP (1) 
FROM dbo.NEW_ORDER 
OUTPUT deleted.no_o_id INTO @d_out -- @d_no_o_id
WHERE NEW_ORDER.no_w_id = @d_w_id 
AND NEW_ORDER.no_d_id = @d_d_id 
AND NEW_ORDER.no_o_id =  @d_no_o_id

SELECT @d_no_o_id = d_no_o_id FROM @d_out
 

UPDATE dbo.ORDERS 
SET o_carrier_id = @d_o_carrier_id 
, @d_c_id = ORDERS.o_c_id 
WHERE ORDERS.o_id = @d_no_o_id 
AND ORDERS.o_d_id = @d_d_id 
AND ORDERS.o_w_id = @d_w_id


 SET @d_ol_total = 0

UPDATE dbo.ORDER_LINE 
SET ol_delivery_d = @timestamp
	, @d_ol_total = @d_ol_total + ol_amount
WHERE ORDER_LINE.ol_o_id = @d_no_o_id 
AND ORDER_LINE.ol_d_id = @d_d_id 
AND ORDER_LINE.ol_w_id = @d_w_id


UPDATE dbo.CUSTOMER SET c_balance = CUSTOMER.c_balance + @d_ol_total 
WHERE CUSTOMER.c_id = @d_c_id 
AND CUSTOMER.c_d_id = @d_d_id 
AND CUSTOMER.c_w_id = @d_w_id


PRINT 
'D: '
+ 
ISNULL(CAST(@d_d_id AS nvarchar(4000)), '')
+ 
'O: '
+ 
ISNULL(CAST(@d_no_o_id AS nvarchar(4000)), '')
+ 
'time '
+ 
ISNULL(CAST(@timestamp AS nvarchar(4000)), '')
SET @loop_counter = @loop_counter + 1
END
SELECT	@d_w_id as N'@d_w_id', @d_o_carrier_id as N'@d_o_carrier_id', @timestamp as N'@TIMESTAMP'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(3) {CREATE PROCEDURE [dbo].[PAYMENT]  
@p_w_id int,
@p_d_id int,
@p_c_w_id int,
@p_c_d_id int,
@p_c_id int,
@byname int,
@p_h_amount numeric(6,2),
@p_c_last char(16),
@TIMESTAMP datetime2(0)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@p_w_street_1 char(20),
@p_w_street_2 char(20),
@p_w_city char(20),
@p_w_state char(2),
@p_w_zip char(10),
@p_d_street_1 char(20),
@p_d_street_2 char(20),
@p_d_city char(20),
@p_d_state char(20),
@p_d_zip char(10),
@p_c_first char(16),
@p_c_middle char(2),
@p_c_street_1 char(20),
@p_c_street_2 char(20),
@p_c_city char(20),
@p_c_state char(20),
@p_c_zip char(9),
@p_c_phone char(16),
@p_c_since datetime2(0),
@p_c_credit char(32),
@p_c_credit_lim  numeric(12,2), 
@p_c_discount  numeric(4,4),
@p_c_balance numeric(12,2),
@p_c_data varchar(500),
@namecnt int, 
@p_d_name char(11), 
@p_w_name char(11), 
@p_c_new_data varchar(500), 
@h_data varchar(30)
BEGIN TRANSACTION
BEGIN TRY

SELECT @p_w_street_1 = WAREHOUSE.w_street_1
, @p_w_street_2 = WAREHOUSE.w_street_2
, @p_w_city = WAREHOUSE.w_city
, @p_w_state = WAREHOUSE.w_state
, @p_w_zip = WAREHOUSE.w_zip
, @p_w_name = WAREHOUSE.w_name 
FROM dbo.WAREHOUSE WITH (INDEX = [W_Details])
WHERE WAREHOUSE.w_id = @p_w_id

UPDATE dbo.DISTRICT 
SET d_ytd = DISTRICT.d_ytd + @p_h_amount 
WHERE DISTRICT.d_w_id = @p_w_id 
AND DISTRICT.d_id = @p_d_id

SELECT @p_d_street_1 = DISTRICT.d_street_1
, @p_d_street_2 = DISTRICT.d_street_2
, @p_d_city = DISTRICT.d_city
, @p_d_state = DISTRICT.d_state
, @p_d_zip = DISTRICT.d_zip
, @p_d_name = DISTRICT.d_name 
FROM dbo.DISTRICT WITH (INDEX = D_Details)
WHERE DISTRICT.d_w_id = @p_w_id 
AND DISTRICT.d_id = @p_d_id
IF (@byname = 1)
BEGIN
SELECT @namecnt = count(CUSTOMER.c_id) 
FROM dbo.CUSTOMER WITH (repeatableread) 
WHERE CUSTOMER.c_last = @p_c_last 
AND CUSTOMER.c_d_id = @p_c_d_id 
AND CUSTOMER.c_w_id = @p_c_w_id

DECLARE
c_byname CURSOR STATIC LOCAL FOR 
SELECT CUSTOMER.c_first
, CUSTOMER.c_middle
, CUSTOMER.c_id
, CUSTOMER.c_street_1
, CUSTOMER.c_street_2
, CUSTOMER.c_city
, CUSTOMER.c_state
, CUSTOMER.c_zip
, CUSTOMER.c_phone
, CUSTOMER.c_credit
, CUSTOMER.c_credit_lim
, CUSTOMER.c_discount
, C_BAL.c_balance
, CUSTOMER.c_since 
FROM dbo.CUSTOMER  AS CUSTOMER WITH (INDEX = [CUSTOMER_I2], repeatableread)
INNER LOOP JOIN dbo.CUSTOMER AS C_BAL WITH (INDEX = [CUSTOMER_I1], repeatableread) 
ON C_BAL.c_w_id = CUSTOMER.c_w_id
  AND C_BAL.c_d_id = CUSTOMER.c_d_id
  AND C_BAL.c_id = CUSTOMER.c_id
WHERE CUSTOMER.c_w_id = @p_c_w_id 
  AND CUSTOMER.c_d_id = @p_c_d_id 
  AND CUSTOMER.c_last = @p_c_last 
ORDER BY CUSTOMER.c_first
OPTION ( MAXDOP 1)
OPEN c_byname
IF ((@namecnt % 2) = 1)
SET @namecnt = (@namecnt + 1)
BEGIN
DECLARE
@loop_counter int
SET @loop_counter = 0
DECLARE
@loop$bound int
SET @loop$bound = (@namecnt / 2)
WHILE @loop_counter <= @loop$bound
BEGIN
FETCH c_byname
INTO 
@p_c_first, 
@p_c_middle, 
@p_c_id, 
@p_c_street_1, 
@p_c_street_2, 
@p_c_city, 
@p_c_state, 
@p_c_zip, 
@p_c_phone, 
@p_c_credit, 
@p_c_credit_lim, 
@p_c_discount, 
@p_c_balance, 
@p_c_since
SET @loop_counter = @loop_counter + 1
END
END
CLOSE c_byname
DEALLOCATE c_byname
END
ELSE 
BEGIN
SELECT @p_c_first = CUSTOMER.c_first, @p_c_middle = CUSTOMER.c_middle, @p_c_last = CUSTOMER.c_last
, @p_c_street_1 = CUSTOMER.c_street_1, @p_c_street_2 = CUSTOMER.c_street_2
, @p_c_city = CUSTOMER.c_city, @p_c_state = CUSTOMER.c_state
, @p_c_zip = CUSTOMER.c_zip, @p_c_phone = CUSTOMER.c_phone
, @p_c_credit = CUSTOMER.c_credit, @p_c_credit_lim = CUSTOMER.c_credit_lim
, @p_c_discount = CUSTOMER.c_discount, @p_c_balance = CUSTOMER.c_balance
, @p_c_since = CUSTOMER.c_since 
FROM dbo.CUSTOMER 
WHERE CUSTOMER.c_w_id = @p_c_w_id 
AND CUSTOMER.c_d_id = @p_c_d_id 
AND CUSTOMER.c_id = @p_c_id 

END
SET @p_c_balance = (@p_c_balance + @p_h_amount)
IF @p_c_credit = 'BC'
BEGIN
SELECT @p_c_data = CUSTOMER.c_data FROM dbo.CUSTOMER WHERE CUSTOMER.c_w_id = @p_c_w_id 
AND CUSTOMER.c_d_id = @p_c_d_id AND CUSTOMER.c_id = @p_c_id
SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))
SET @p_c_new_data = (
ISNULL(CAST(@p_c_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_c_d_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_c_w_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_d_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_w_id AS char), '')
 + 
' '
 + 
ISNULL(CAST(@p_h_amount AS CHAR(8)), '')
 + 
ISNULL(CAST(@TIMESTAMP AS char), '')
 + 
ISNULL(@h_data, ''))
SET @p_c_new_data = substring((@p_c_new_data + @p_c_data), 1, 500 - LEN(@p_c_new_data))
UPDATE dbo.CUSTOMER SET c_balance = @p_c_balance, c_data = @p_c_new_data 
WHERE CUSTOMER.c_w_id = @p_c_w_id 
AND CUSTOMER.c_d_id = @p_c_d_id AND CUSTOMER.c_id = @p_c_id
END
ELSE 
UPDATE dbo.CUSTOMER SET c_balance = @p_c_balance 
WHERE CUSTOMER.c_w_id = @p_c_w_id 
AND CUSTOMER.c_d_id = @p_c_d_id 
AND CUSTOMER.c_id = @p_c_id

SET @h_data = (ISNULL(@p_w_name, '') + ' ' + ISNULL(@p_d_name, ''))

INSERT dbo.HISTORY( h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data) 
VALUES ( @p_c_d_id, @p_c_w_id, @p_c_id, @p_d_id, @p_w_id, @TIMESTAMP, @p_h_amount, @h_data)
SELECT	@p_c_id as N'@p_c_id', @p_c_last as N'@p_c_last', @p_w_street_1 as N'@p_w_street_1'
, @p_w_street_2 as N'@p_w_street_2', @p_w_city as N'@p_w_city'
, @p_w_state as N'@p_w_state', @p_w_zip as N'@p_w_zip'
, @p_d_street_1 as N'@p_d_street_1', @p_d_street_2 as N'@p_d_street_2'
, @p_d_city as N'@p_d_city', @p_d_state as N'@p_d_state'
, @p_d_zip as N'@p_d_zip', @p_c_first as N'@p_c_first'
, @p_c_middle as N'@p_c_middle', @p_c_street_1 as N'@p_c_street_1'
, @p_c_street_2 as N'@p_c_street_2'
, @p_c_city as N'@p_c_city', @p_c_state as N'@p_c_state', @p_c_zip as N'@p_c_zip'
, @p_c_phone as N'@p_c_phone', @p_c_since as N'@p_c_since', @p_c_credit as N'@p_c_credit'
, @p_c_credit_lim as N'@p_c_credit_lim', @p_c_discount as N'@p_c_discount', @p_c_balance as N'@p_c_balance'
, @p_c_data as N'@p_c_data'


UPDATE dbo.WAREHOUSE WITH (XLOCK)
SET w_ytd = WAREHOUSE.w_ytd + @p_h_amount 
WHERE WAREHOUSE.w_id = @p_w_id

END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(4) {CREATE PROCEDURE [dbo].[OSTAT] 
@os_w_id int,
@os_d_id int,
@os_c_id int,
@byname int,
@os_c_last char(20)
AS 
BEGIN
SET ANSI_WARNINGS OFF
DECLARE
@os_c_first char(16),
@os_c_middle char(2),
@os_c_balance money,
@os_o_id int,
@os_entdate datetime2(0),
@os_o_carrier_id int,
@os_ol_i_id 	INT,
@os_ol_supply_w_id INT,
@os_ol_quantity INT,
@os_ol_amount 	INT,
@os_ol_delivery_d DATE,
@namecnt int, 
@i int,
@os_ol_i_id_array VARCHAR(200),
@os_ol_supply_w_id_array VARCHAR(200),
@os_ol_quantity_array VARCHAR(200),
@os_ol_amount_array VARCHAR(200),
@os_ol_delivery_d_array VARCHAR(210)
BEGIN TRANSACTION
BEGIN TRY
SET @os_ol_i_id_array = 'CSV,'
SET @os_ol_supply_w_id_array = 'CSV,'
SET @os_ol_quantity_array = 'CSV,'
SET @os_ol_amount_array = 'CSV,'
SET @os_ol_delivery_d_array = 'CSV,'
IF (@byname = 1)
BEGIN

SELECT @namecnt = count_big(CUSTOMER.c_id) 
FROM dbo.CUSTOMER 
WHERE CUSTOMER.c_last = @os_c_last AND CUSTOMER.c_d_id = @os_d_id AND CUSTOMER.c_w_id = @os_w_id

IF ((@namecnt % 2) = 1)
SET @namecnt = (@namecnt + 1)
DECLARE
c_name CURSOR LOCAL FOR 
SELECT CUSTOMER.c_balance
, CUSTOMER.c_first
, CUSTOMER.c_middle
, CUSTOMER.c_id 
FROM dbo.CUSTOMER 
WHERE CUSTOMER.c_last = @os_c_last 
AND CUSTOMER.c_d_id = @os_d_id 
AND CUSTOMER.c_w_id = @os_w_id 
ORDER BY CUSTOMER.c_first

OPEN c_name
BEGIN
DECLARE
@loop_counter int
SET @loop_counter = 0
DECLARE
@loop$bound int
SET @loop$bound = (@namecnt / 2)
WHILE @loop_counter <= @loop$bound
BEGIN
FETCH c_name
INTO @os_c_balance, @os_c_first, @os_c_middle, @os_c_id
SET @loop_counter = @loop_counter + 1
END
END
CLOSE c_name
DEALLOCATE c_name
END
ELSE 
BEGIN
SELECT @os_c_balance = CUSTOMER.c_balance, @os_c_first = CUSTOMER.c_first
, @os_c_middle = CUSTOMER.c_middle, @os_c_last = CUSTOMER.c_last 
FROM dbo.CUSTOMER WITH (repeatableread) 
WHERE CUSTOMER.c_id = @os_c_id AND CUSTOMER.c_d_id = @os_d_id AND CUSTOMER.c_w_id = @os_w_id
END
BEGIN
SELECT TOP (1) @os_o_id = fci.o_id, @os_o_carrier_id = fci.o_carrier_id, @os_entdate = fci.o_entry_d
FROM 
(SELECT TOP 9223372036854775807 ORDERS.o_id, ORDERS.o_carrier_id, ORDERS.o_entry_d 
FROM dbo.ORDERS WITH (serializable) 
WHERE ORDERS.o_d_id = @os_d_id 
AND ORDERS.o_w_id = @os_w_id 
AND ORDERS.o_c_id = @os_c_id 
ORDER BY ORDERS.o_id DESC)  AS fci
IF @@ROWCOUNT = 0
PRINT 'No orders for customer';
END
SET @i = 0
DECLARE
c_line CURSOR LOCAL FORWARD_ONLY FOR 
SELECT ORDER_LINE.ol_i_id
, ORDER_LINE.ol_supply_w_id
, ORDER_LINE.ol_quantity
, ORDER_LINE.ol_amount
, ORDER_LINE.ol_delivery_d 
FROM dbo.ORDER_LINE WITH (repeatableread) 
WHERE ORDER_LINE.ol_o_id = @os_o_id 
AND ORDER_LINE.ol_d_id = @os_d_id 
AND ORDER_LINE.ol_w_id = @os_w_id
OPEN c_line
WHILE 1 = 1
BEGIN
FETCH c_line
INTO 
@os_ol_i_id,
@os_ol_supply_w_id,
@os_ol_quantity,
@os_ol_amount,
@os_ol_delivery_d
IF @@FETCH_STATUS = -1
BREAK
set @os_ol_i_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_i_id AS CHAR)
set @os_ol_supply_w_id_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_supply_w_id AS CHAR)
set @os_ol_quantity_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_quantity AS CHAR)
set @os_ol_amount_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_amount AS CHAR);
set @os_ol_delivery_d_array += CAST(@i AS CHAR) + ',' + CAST(@os_ol_delivery_d AS CHAR)
SET @i = @i + 1
END
CLOSE c_line
DEALLOCATE c_line
SELECT	@os_c_id as N'@os_c_id', @os_c_last as N'@os_c_last', @os_c_first as N'@os_c_first', @os_c_middle as N'@os_c_middle', @os_c_balance as N'@os_c_balance', @os_o_id as N'@os_o_id', @os_entdate as N'@os_entdate', @os_o_carrier_id as N'@os_o_carrier_id'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
set sql(5) {CREATE PROCEDURE [dbo].[SLEV]  
@st_w_id int,
@st_d_id int,
@threshold int
AS 
BEGIN
DECLARE
@st_o_id int, 
@stock_count int 
BEGIN TRANSACTION
BEGIN TRY

SELECT @st_o_id = DISTRICT.d_next_o_id 
FROM dbo.DISTRICT 
WHERE DISTRICT.d_w_id = @st_w_id AND DISTRICT.d_id = @st_d_id

SELECT @stock_count = count_big(DISTINCT STOCK.s_i_id) 
FROM dbo.ORDER_LINE
, dbo.STOCK
WHERE ORDER_LINE.ol_w_id = @st_w_id 
AND ORDER_LINE.ol_d_id = @st_d_id 
AND (ORDER_LINE.ol_o_id < @st_o_id) 
AND ORDER_LINE.ol_o_id >= (@st_o_id - 20) 
AND STOCK.s_w_id = @st_w_id 
AND STOCK.s_i_id = ORDER_LINE.ol_i_id 
AND STOCK.s_quantity < @threshold
OPTION (LOOP JOIN, MAXDOP 1)

SELECT	@st_o_id as N'@st_o_id', @stock_count as N'@stock_count'
END TRY
BEGIN CATCH
SELECT 
ERROR_NUMBER() AS ErrorNumber
,ERROR_SEVERITY() AS ErrorSeverity
,ERROR_STATE() AS ErrorState
,ERROR_PROCEDURE() AS ErrorProcedure
,ERROR_LINE() AS ErrorLine
,ERROR_MESSAGE() AS ErrorMessage;
IF @@TRANCOUNT > 0
ROLLBACK TRANSACTION;
END CATCH;
IF @@TRANCOUNT > 0
COMMIT TRANSACTION;
END}
for { set i 1 } { $i <= 5 } { incr i } {
odbc  $sql($i)
		}
return
	}
}

proc UpdateStatistics { odbc db } {
puts "UPDATING SCHEMA STATISTICS"
set sql(1) "USE $db"
set sql(2) "EXEC sp_updatestats"
for { set i 1 } { $i <= 2 } { incr i } {
odbc  $sql($i)
		}
return
}

proc CreateDatabase { odbc db } {
set table_count 0
puts "CHECKING IF DATABASE $db EXISTS"
set db_exists [ odbc "IF DB_ID('$db') is not null SELECT 1 AS res ELSE SELECT 0 AS res" ]
if { $db_exists } {
odbc "use $db"
set table_count [ odbc "select COUNT(*) from sys.tables" ]
if { $table_count == 0 } {
puts "Empty database $db exists"
puts "Using existing empty Database $db for Schema build"
        } else {
puts "Database with tables $db exists"
error "Database $db exists but is not empty, specify a new or empty database name"
        }
} else {
puts "CREATING DATABASE $db"
odbc "create database $db"
        }
}

proc CreateTables { odbc schema } {
if { $schema != "updated" } {
#original Tables from SSMA
puts "CREATING TPCC TABLES"
set sql(1) "create table dbo.CUSTOMER (c_id int, c_d_id tinyint, c_w_id int, c_discount smallmoney, c_credit_lim money, c_last char(16), c_first char(16), c_credit char(2), c_balance money, c_ytd_payment money, c_payment_cnt smallint, c_delivery_cnt smallint, c_street_1 char(20), c_street_2 char(20), c_city char(20), c_state char(2), c_zip char(9), c_phone char(16), c_since datetime, c_middle char(2), c_data char(500))"
set sql(2) "create table dbo.DISTRICT (d_id tinyint, d_w_id int, d_ytd money, d_next_o_id int, d_tax smallmoney, d_name char(10), d_street_1 char(20), d_street_2 char(20), d_city char(20), d_state char(2), d_zip char(9))"
set sql(3) "create table dbo.HISTORY (h_c_id int, h_c_d_id tinyint, h_c_w_id int, h_d_id tinyint, h_w_id int, h_date datetime, h_amount smallmoney, h_data char(24))"
set sql(4) "create table dbo.ITEM (i_id int, i_name char(24), i_price smallmoney, i_data char(50), i_im_id int)"
set sql(5) "create table dbo.NEW_ORDER (no_o_id int, no_d_id tinyint, no_w_id int)"
set sql(6) " create table dbo.ORDER_LINE (ol_o_id int, ol_d_id tinyint, ol_w_id int, ol_number tinyint, ol_i_id int, ol_delivery_d datetime, ol_amount smallmoney, ol_supply_w_id int, ol_quantity smallint, ol_dist_info char(24))"
set sql(7) "create table dbo.ORDERS (o_id int, o_d_id tinyint, o_w_id int, o_c_id int, o_carrier_id tinyint, o_ol_cnt tinyint, o_all_local tinyint, o_entry_d datetime)"
set sql(8) "create table dbo.STOCK (s_i_id int, s_w_id int, s_quantity smallint, s_ytd int, s_order_cnt smallint, s_remote_cnt smallint, s_data char(50), s_dist_01 char(24), s_dist_02 char(24), s_dist_03 char(24), s_dist_04 char(24), s_dist_05 char(24), s_dist_06 char(24), s_dist_07 char(24), s_dist_08 char(24), s_dist_09 char(24), s_dist_10 char(24))" 
set sql(9) "create table dbo.WAREHOUSE(W_ID int, w_ytd money, w_tax smallmoney, w_name char(10), w_street_1 char(20), w_street_2 char(20), w_city char(20), w_state char(2), w_zip char(9))"
for { set i 1 } { $i <= 9 } { incr i } {
odbc  $sql($i)
		}
return
	} else {
puts "CREATING TPCC TABLES"
#Updated Tables provided by Thomas Kejser
set sql(1) {CREATE TABLE [dbo].[CUSTOMER]( [c_id] [int] NOT NULL, [c_d_id] [tinyint] NOT NULL, [c_w_id] [int] NOT NULL, [c_discount] [smallmoney] NULL, [c_credit_lim] [money] NULL, [c_last] [char](16) NULL, [c_first] [char](16) NULL, [c_credit] [char](2) NULL, [c_balance] [money] NULL, [c_ytd_payment] [money] NULL, [c_payment_cnt] [smallint] NULL, [c_delivery_cnt] [smallint] NULL, [c_street_1] [char](20) NULL, [c_street_2] [char](20) NULL, [c_city] [char](20) NULL, [c_state] [char](2) NULL, [c_zip] [char](9) NULL, [c_phone] [char](16) NULL, [c_since] [datetime] NULL, [c_middle] [char](2) NULL, [c_data] [char](500) NULL)}
set sql(2) {CREATE TABLE [dbo].[DISTRICT]( [d_id] [tinyint] NOT NULL, [d_w_id] [int] NOT NULL, [d_ytd] [money] NOT NULL, [d_next_o_id] [int] NULL, [d_tax] [smallmoney] NULL, [d_name] [char](10) NULL, [d_street_1] [char](20) NULL, [d_street_2] [char](20) NULL, [d_city] [char](20) NULL, [d_state] [char](2) NULL, [d_zip] [char](9) NULL, [padding] [char](6000) NOT NULL, CONSTRAINT [PK_DISTRICT] PRIMARY KEY CLUSTERED ( [d_w_id] ASC, [d_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON))}
set sql(3) {CREATE TABLE [dbo].[HISTORY]( [h_c_id] [int] NULL, [h_c_d_id] [tinyint] NULL, [h_c_w_id] [int] NULL, [h_d_id] [tinyint] NULL, [h_w_id] [int] NULL, [h_date] [datetime] NULL, [h_amount] [smallmoney] NULL, [h_data] [char](24) NULL)} 
set sql(4) {CREATE TABLE [dbo].[ITEM]( [i_id] [int] NOT NULL, [i_name] [char](24) NULL, [i_price] [smallmoney] NULL, [i_data] [char](50) NULL, [i_im_id] [int] NULL, CONSTRAINT [PK_ITEM] PRIMARY KEY CLUSTERED ( [i_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON))} 
set sql(5) {CREATE TABLE [dbo].[NEW_ORDER]( [no_o_id] [int] NOT NULL, [no_d_id] [tinyint] NOT NULL, [no_w_id] [int] NOT NULL)} 
set sql(6) {CREATE TABLE [dbo].[ORDERS]( [o_id] [int] NOT NULL, [o_d_id] [tinyint] NOT NULL, [o_w_id] [int] NOT NULL, [o_c_id] [int] NOT NULL, [o_carrier_id] [tinyint] NULL, [o_ol_cnt] [tinyint] NULL, [o_all_local] [tinyint] NULL, [o_entry_d] [datetime] NULL)} 
set sql(7) {CREATE TABLE [dbo].[ORDER_LINE]( [ol_o_id] [int] NOT NULL, [ol_d_id] [tinyint] NOT NULL, [ol_w_id] [int] NOT NULL, [ol_number] [tinyint] NOT NULL, [ol_i_id] [int] NULL, [ol_delivery_d] [datetime] NULL, [ol_amount] [smallmoney] NULL, [ol_supply_w_id] [int] NULL, [ol_quantity] [smallint] NULL, [ol_dist_info] [char](24) NULL)} 
set sql(8) {CREATE TABLE [dbo].[STOCK]( [s_i_id] [int] NOT NULL, [s_w_id] [int] NOT NULL, [s_quantity] [smallint] NOT NULL, [s_ytd] [int] NOT NULL, [s_order_cnt] [smallint] NULL, [s_remote_cnt] [smallint] NULL, [s_data] [char](50) NULL, [s_dist_01] [char](24) NULL, [s_dist_02] [char](24) NULL, [s_dist_03] [char](24) NULL, [s_dist_04] [char](24) NULL, [s_dist_05] [char](24) NULL, [s_dist_06] [char](24) NULL, [s_dist_07] [char](24) NULL, [s_dist_08] [char](24) NULL, [s_dist_09] [char](24) NULL, [s_dist_10] [char](24) NULL, CONSTRAINT [PK_STOCK] PRIMARY KEY CLUSTERED ( [s_w_id] ASC, [s_i_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON))}
set sql(9) {CREATE TABLE [dbo].[WAREHOUSE]( [w_id] [int] NOT NULL, [w_ytd] [money] NOT NULL, [w_tax] [smallmoney] NOT NULL, [w_name] [char](10) NULL, [w_street_1] [char](20) NULL, [w_street_2] [char](20) NULL, [w_city] [char](20) NULL, [w_state] [char](2) NULL, [w_zip] [char](9) NULL, [padding] [char](4000) NOT NULL, CONSTRAINT [PK_WAREHOUSE] PRIMARY KEY CLUSTERED ( [w_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON))} 
set sql(10) {ALTER TABLE [dbo].[CUSTOMER] SET (LOCK_ESCALATION = DISABLE)}
set sql(11) {ALTER TABLE [dbo].[DISTRICT] SET (LOCK_ESCALATION = DISABLE)}
set sql(12) {ALTER TABLE [dbo].[HISTORY] SET (LOCK_ESCALATION = DISABLE)}
set sql(13) {ALTER TABLE [dbo].[ITEM] SET (LOCK_ESCALATION = DISABLE)}
set sql(14) {ALTER TABLE [dbo].[NEW_ORDER] SET (LOCK_ESCALATION = DISABLE)}
set sql(15) {ALTER TABLE [dbo].[ORDERS] SET (LOCK_ESCALATION = DISABLE)}
set sql(16) {ALTER TABLE [dbo].[ORDER_LINE] SET (LOCK_ESCALATION = DISABLE)}
set sql(17) {ALTER TABLE [dbo].[STOCK] SET (LOCK_ESCALATION = DISABLE)}
set sql(18) {ALTER TABLE [dbo].[WAREHOUSE] SET (LOCK_ESCALATION = DISABLE)}
set sql(19) {ALTER TABLE [dbo].[DISTRICT] ADD  CONSTRAINT [DF__DISTRICT__paddin__282DF8C2]  DEFAULT (replicate('X',(6000))) FOR [padding]}
set sql(20) {ALTER TABLE [dbo].[WAREHOUSE] ADD  CONSTRAINT [DF__WAREHOUSE__paddi__14270015]  DEFAULT (replicate('x',(4000))) FOR [padding]}
for { set i 1 } { $i <= 20 } { incr i } {
odbc  $sql($i)
		}
return
	}
}

proc CreateIndexes { odbc schema } {
if { $schema != "updated" } {
#original Indexes from SSMA
puts "CREATING TPCC INDEXES"
set sql(1) "CREATE UNIQUE CLUSTERED INDEX CUSTOMER_I1 ON CUSTOMER(c_w_id, c_d_id, c_id)"
set sql(2) "CREATE UNIQUE NONCLUSTERED INDEX CUSTOMER_I2 ON CUSTOMER(c_w_id, c_d_id, c_last, c_first, c_id)"
set sql(3) "CREATE UNIQUE CLUSTERED INDEX DISTRICT_I1 ON DISTRICT(d_w_id, d_id) WITH FILLFACTOR=100"
set sql(4) "CREATE UNIQUE CLUSTERED INDEX ITEM_I1 ON ITEM(i_id)"
set sql(5) "CREATE UNIQUE CLUSTERED INDEX NEW_ORDER_I1 ON NEW_ORDER(no_w_id, no_d_id, no_o_id)"
set sql(6) "CREATE UNIQUE CLUSTERED INDEX ORDER_LINE_I1 ON ORDER_LINE(ol_w_id, ol_d_id, ol_o_id, ol_number)"
set sql(7) "CREATE UNIQUE CLUSTERED INDEX ORDERS_I1 ON ORDERS(o_w_id, o_d_id, o_id)"
set sql(8) "CREATE INDEX ORDERS_I2 ON ORDERS(o_w_id, o_d_id, o_c_id, o_id)"
set sql(9) "CREATE UNIQUE INDEX STOCK_I1 ON STOCK(s_i_id, s_w_id)"
set sql(10) "CREATE UNIQUE CLUSTERED INDEX WAREHOUSE_C1 ON WAREHOUSE(w_id) WITH FILLFACTOR=100"
for { set i 1 } { $i <= 10 } { incr i } {
odbc  $sql($i)
		}
return
	} else {
#Updated Indexes provided by Thomas Kejser
puts "CREATING TPCC INDEXES"
set sql(1) {CREATE UNIQUE CLUSTERED INDEX [CUSTOMER_I1] ON [dbo].[CUSTOMER] ( [c_w_id] ASC, [c_d_id] ASC, [c_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(2) {CREATE UNIQUE CLUSTERED INDEX [NEW_ORDER_I1] ON [dbo].[NEW_ORDER] ( [no_w_id] ASC, [no_d_id] ASC, [no_o_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(3) {CREATE UNIQUE CLUSTERED INDEX [ORDERS_I1] ON [dbo].[ORDERS] ( [o_w_id] ASC, [o_d_id] ASC, [o_id] ASC) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(4) {CREATE UNIQUE CLUSTERED INDEX [ORDER_LINE_I1] ON [dbo].[ORDER_LINE] ( [ol_w_id] ASC, [ol_d_id] ASC, [ol_o_id] ASC, [ol_number] ASC)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)} 
set sql(5) {CREATE UNIQUE NONCLUSTERED INDEX [CUSTOMER_I2] ON [dbo].[CUSTOMER] ( [c_w_id] ASC, [c_d_id] ASC, [c_last] ASC, [c_id] ASC) INCLUDE ([c_credit], [c_street_1], [c_street_2], [c_city], [c_state], [c_zip], [c_phone], [c_middle], [c_credit_lim], [c_since], [c_discount], [c_first]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(6) {CREATE NONCLUSTERED INDEX [D_Details] ON [dbo].[DISTRICT] ( [d_id] ASC, [d_w_id] ASC) INCLUDE ([d_name], [d_street_1], [d_street_2], [d_city], [d_state], [d_zip], [padding]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)}
set sql(7) {CREATE NONCLUSTERED INDEX [ORDERS_I2] ON [dbo].[ORDERS] ( [o_w_id] ASC, [o_d_id] ASC, [o_c_id] ASC, [o_id] ASC)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
set sql(8) {CREATE UNIQUE NONCLUSTERED INDEX [W_Details] ON [dbo].[WAREHOUSE] ( [w_id] ASC) INCLUDE ([w_tax], [w_name], [w_street_1], [w_street_2], [w_city], [w_state], [w_zip], [padding]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = OFF)}
for { set i 1 } { $i <= 8 } { incr i } {
odbc  $sql($i)
		}
return
	}
}

proc chk_thread {} {
        set chk [package provide Thread]
        if {[string length $chk]} {
            return "TRUE"
            } else {
            return "FALSE"
        }
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
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

proc Customer { odbc d_id w_id CUST_PER_DIST } {
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
append c_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_first', '$c_middle', '$c_last', '[ lindex $c_add 0 ]', '[ lindex $c_add 1 ]', '[ lindex $$c_add 2 ]', '[ lindex $c_add 3 ]', '[ lindex $c_add 4 ]', '$c_phone', getdate(), '$c_credit', '$c_credit_lim', '$c_discount', '$c_balance', '$c_data', '10.0', '1', '0')
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
append h_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_w_id', '$c_d_id', getdate(), '$h_amount', '$h_data')
if { $bld_cnt<= 1 } { 
append c_val_list ,
append h_val_list ,
	}
incr bld_cnt
if { ![ expr {$c_id % 2} ] } {
odbc "insert into customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) values $c_val_list"
odbc "insert into history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) values $h_val_list"
	odbc commit
	set bld_cnt 1
	unset c_val_list
	unset h_val_list
		}
	}
puts "Customer Done"
return
}

proc Orders { odbc d_id w_id MAXITEMS ORD_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
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
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', getdate(), null, '$o_ol_cnt', '1')
set e "no1"
append no_val_list ('$o_id', '$o_d_id', '$o_w_id')
  } else {
  set e "o3"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', getdate(), '$o_carrier_id', '$o_ol_cnt', '1')
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', null)
if { $bld_cnt<= 1 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', getdate())
if { $bld_cnt<= 1 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	}
}
if { $bld_cnt<= 1 } {
append o_val_list ,
if { $o_id > 2100 } {
append no_val_list ,
		}
        }
incr bld_cnt
 if { ![ expr {$o_id % 2} ] } {
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
	}
odbc "insert into orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values $o_val_list"
if { $o_id > 2100 } {
odbc "insert into new_order (no_o_id, no_d_id, no_w_id) values $no_val_list"
	}
odbc "insert into order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values $ol_val_list"
	odbc commit 
	set bld_cnt 1
	unset o_val_list
	unset -nocomplain no_val_list
	unset ol_val_list
			}
		}
	odbc commit
	puts "Orders Done"
	return
}

proc LoadItems { odbc MAXITEMS } {
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
	odbc "insert into item (i_id, i_im_id, i_name, i_price, i_data) VALUES ('$i_id', '$i_im_id', '$i_name', '$i_price', '$i_data')"
      if { ![ expr {$i_id % 50000} ] } {
	puts "Loading Items - $i_id"
			}
		}
	odbc commit 
	puts "Item done"
	return
	}

proc Stock { odbc w_id MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
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
append val_list ('$s_i_id', '$s_w_id', '$s_quantity', '$s_dist_01', '$s_dist_02', '$s_dist_03', '$s_dist_04', '$s_dist_05', '$s_dist_06', '$s_dist_07', '$s_dist_08', '$s_dist_09', '$s_dist_10', '$s_data', '0', '0', '0')
if { $bld_cnt<= 1 } { 
append val_list ,
}
incr bld_cnt
      if { ![ expr {$s_i_id % 2} ] } {
odbc "insert into stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) values $val_list"
	odbc commit
	set bld_cnt 1
	unset val_list
	}
      if { ![ expr {$s_i_id % 20000} ] } {
	puts "Loading Stock - $s_i_id"
			}
	}
	odbc commit
	puts "Stock done"
	return
}

proc District { odbc w_id DIST_PER_WARE } {
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
odbc "insert into district (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) values ('$d_id', '$d_w_id', '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', '$d_tax', '$d_ytd', '$d_next_o_id')"
	}
	odbc commit
	puts "District done"
	return
}

proc LoadWare { odbc ware_start count_ware MAXITEMS DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
odbc "insert into warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values ('$w_id', '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , '[ lindex $add 3 ]', '[ lindex $add 4 ]', '$w_tax', '$w_ytd')"
	Stock odbc $w_id $MAXITEMS
	District odbc $w_id $DIST_PER_WARE
	odbc commit 
	}
}

proc LoadCust { odbc ware_start count_ware CUST_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer odbc $d_id $w_id $CUST_PER_DIST
		}
	}
	odbc commit 
	return
}

proc LoadOrd { odbc ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Orders odbc $d_id $w_id $MAXITEMS $ORD_PER_DIST
		}
	}
	odbc commit 
	return
}

proc connect_string { server port odbc_driver authentication uid pwd } {
if {[ string toupper $authentication ] eq "WINDOWS" } { 
if {[ string match -nocase {*native*} $odbc_driver ] } { 
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;TRUSTED_CONNECTION=YES"
} else {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
} else {
if {[ string toupper $authentication ] eq "SQL" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;UID=$uid;PWD=$pwd"
	} else {
puts stderr "Error: neither WINDOWS or SQL Authentication has been specified"
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
}
return $connection
}

proc do_tpcc { server port odbc_driver authentication uid pwd count_ware db schema num_threads } {
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd ]
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
puts "CREATING [ string toupper $db ] SCHEMA"
if [catch {database connect odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
 } else {
CreateDatabase odbc $db
odbc "use $db"
CreateTables odbc $schema
}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems odbc $MAXITEMS
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
LoadItems odbc $MAXITEMS
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
after 5000
}
if [catch {database connect odbc $connection} message ] {
puts stderr "error, the database connection to $connection could not be established"
error $message
return
 } else {
odbc "use $db"
odbc set autocommit off 
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
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare odbc $mystart $myend $MAXITEMS $DIST_PER_WARE
LoadCust odbc $mystart $myend $CUST_PER_DIST $DIST_PER_WARE
LoadOrd odbc $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE
puts "End:[ clock format [ clock seconds ] ]"
odbc commit 
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateIndexes odbc $schema
CreateStoredProcs odbc $schema
UpdateStatistics odbc $db
puts "[ string toupper $db ] SCHEMA COMPLETE"
odbc disconnect
return
		}
	}
}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1788.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "do_tpcc {$mssqls_server} $mssqls_port {$mssqls_odbc_driver} $mssqls_authentication $mssqls_uid $mssqls_pass $mssqls_count_ware $mssqls_dbase $mssqls_schema $mssqls_num_threads"
        } else { return }
}

proc loadmssqlstpcc { } {
global mssqls_server mssqls_port mssqls_authentication mssqls_odbc_driver mssqls_uid mssqls_pass mssqls_dbase mssqls_total_iterations mssqls_raiseerror mssqls_keyandthink mssqlsdriver _ED
if {  ![ info exists mssqls_server ] } { set mssqls_server "(local)" }
if {  ![ info exists mssqls_port ] } { set mssqls_port "1433" }
if {  ![ info exists mssqls_authentication ] } { set mssqls_authentication "windows" }
if {  ![ info exists mssqls_odbc_driver ] } { set mssqls_odbc_driver "SQL Server Native Client 10.0" }
if {  ![ info exists mssqls_uid ] } { set mssqls_uid "sa" }
if {  ![ info exists mssqls_pass ] } { set mssqls_pass "admin" }
if {  ![ info exists mssqls_dbase ] } { set mssqls_dbase "tpcc" }
if {  ![ info exists mssqls_total_iterations ] } { set mssqls_total_iterations 1000000 }
if {  ![ info exists mssqls_raiseerror ] } { set mssqls_raiseerror "false" }
if {  ![ info exists mssqls_keyandthink ] } { set mssqls_keyandthink "false" }
if {  ![ info exists mssqlsdriver ] } { set mssqlsdriver "standard" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require tclodbc 2.5.1} \] { error \"Failed to load tclodbc - ODBC Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $mssqls_total_iterations;# Number of transactions before logging off
set RAISEERROR \"$mssqls_raiseerror\" ;# Exit script on SQL Server error (true or false)
set KEYANDTHINK \"$mssqls_keyandthink\" ;# Time for user thinking and keying (true or false)
set authentication \"$mssqls_authentication\";# Authentication Mode (WINDOWS or SQL)
set server \{$mssqls_server\};# Microsoft SQL Server Database Server
set port \"$mssqls_port\";# Microsoft SQL Server Port 
set odbc_driver \{$mssqls_odbc_driver\};# ODBC Driver
set uid \"$mssqls_uid\";#User ID for SQL Server Authentication
set pwd \"$mssqls_pass\";#Password for SQL Server Authentication
set database \"$mssqls_dbase\";# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 16.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {proc connect_string { server port odbc_driver authentication uid pwd } {
if {[ string toupper $authentication ] eq "WINDOWS" } { 
if {[ string match -nocase {*native*} $odbc_driver ] } { 
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;TRUSTED_CONNECTION=YES"
} else {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
} else {
if {[ string toupper $authentication ] eq "SQL" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;UID=$uid;PWD=$pwd"
	} else {
puts stderr "Error: neither WINDOWS or SQL Authentication has been specified"
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
}
return $connection
}
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format "%Y-%m-%d %H:%M:%S" ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { neword_st no_w_id w_id_input RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
if {[ catch {neword_st execute [ list $no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt $date ]} message]} {
if { $RAISEERROR } {
error "New Order : $message"
	} else {
puts $message
} } else {
neword_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
	}
puts [ join $oput ]
}
odbc commit
}
#PAYMENT
proc payment { payment_st p_w_id w_id_input RAISEERROR } {
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
if {[ catch {payment_st execute [ list $p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $name $h_date ]} message]} {
if { $RAISEERROR } {
error "Payment : $message"
	} else {
puts $message
} } else {
payment_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
	}
puts [ join $oput ]
}
odbc commit
}
#ORDER_STATUS
proc ostat { ostat_st w_id RAISEERROR } {
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
if {[ catch {ostat_st execute [ list $w_id $d_id $c_id $byname $name ]} message]} {
if { $RAISEERROR } {
error "Order Status : $message"
	} else {
puts $message
} } else {
ostat_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
	}
puts [ join $oput ]
}
odbc commit
}
#DELIVERY
proc delivery { delivery_st w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if {[ catch {delivery_st execute [ list $w_id $carrier_id $date ]} message]} {
if { $RAISEERROR } {
error "Delivery : $message"
	} else {
puts $message
} } else {
delivery_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
	}
puts [ join $oput ]
}
odbc commit
}
#STOCK LEVEL
proc slev { slev_st w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
if {[ catch {slev_st execute [ list $w_id $stock_level_d_id $threshold ]} message]} {
if { $RAISEERROR } {
error "Stock Level : $message"
	} else {
puts $message
} } else {
slev_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
	}
puts [ join $oput ]
}
odbc commit
}
proc prep_statement { odbc statement_st } {
switch $statement_st {
slev_st {
odbc statement slev_st "EXEC SLEV @st_w_id = ?, @st_d_id = ?, @threshold = ?" {INTEGER INTEGER INTEGER} 
return slev_st
	}
delivery_st {
odbc statement delivery_st "EXEC DELIVERY @d_w_id = ?, @d_o_carrier_id = ?, @timestamp = ?" {INTEGER INTEGER TIMESTAMP}
return delivery_st
	}
ostat_st {
odbc statement ostat_st "EXEC OSTAT @os_w_id = ?, @os_d_id = ?, @os_c_id = ?, @byname = ?, @os_c_last = ?" {INTEGER INTEGER INTEGER INTEGER {CHAR 16}}
return ostat_st
	}
payment_st {
odbc statement payment_st "EXEC PAYMENT @p_w_id = ?, @p_d_id = ?, @p_c_w_id = ?, @p_c_d_id = ?, @p_c_id = ?, @byname = ?, @p_h_amount = ?, @p_c_last = ?, @TIMESTAMP =?" {INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER {CHAR 16} TIMESTAMP}
return payment_st
	}
neword_st {
odbc statement neword_st "EXEC NEWORD @no_w_id = ?, @no_max_w_id = ?, @no_d_id = ?, @no_c_id = ?, @no_o_ol_cnt = ?, @TIMESTAMP = ?" {INTEGER INTEGER INTEGER INTEGER INTEGER TIMESTAMP}
return neword_st
	}
    }
}

#RUN TPC-C
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd ]
if [catch {database connect odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
} else {
database connect odbc $connection
odbc "use $database"
odbc set autocommit off
}
foreach st {neword_st payment_st ostat_st delivery_st slev_st} { set $st [ prep_statement odbc $st ] }
set w_id_input [ odbc  "select max(w_id) from WAREHOUSE" ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ odbc "select max(d_id) from DISTRICT" ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword neword_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment payment_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery delivery_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev slev_st $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat ostat_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
odbc commit
neword_st drop 
payment_st drop
delivery_st drop
slev_st drop
ostat_st drop
odbc disconnect
	}
}

proc loadtimedmssqlstpcc { } {
global mssqls_server mssqls_port mssqls_authentication mssqls_odbc_driver mssqls_uid mssqls_pass mssqls_dbase mssqls_total_iterations mssqls_raiseerror mssqls_keyandthink mssqlsdriver mssqls_rampup mssqls_duration mssqls_checkpoint _ED
if {  ![ info exists mssqls_server ] } { set mssqls_server "(local)" }
if {  ![ info exists mssqls_port ] } { set mssqls_port "1433" }
if {  ![ info exists mssqls_authentication ] } { set mssqls_authentication "windows" }
if {  ![ info exists mssqls_odbc_driver ] } { set mssqls_odbc_driver "SQL Server Native Client 10.0" }
if {  ![ info exists mssqls_uid ] } { set mssqls_uid "sa" }
if {  ![ info exists mssqls_pass ] } { set mssqls_pass "admin" }
if {  ![ info exists mssqls_dbase ] } { set mssqls_dbase "tpcc" }
if {  ![ info exists mssqls_total_iterations ] } { set mssqls_total_iterations 1000000 }
if {  ![ info exists mssqls_raiseerror ] } { set mssqls_raiseerror "false" }
if {  ![ info exists mssqls_keyandthink ] } { set mssqls_keyandthink "false" }
if {  ![ info exists mssqlsdriver ] } { set mssqlsdriver "timed" }
if {  ![ info exists mssqls_rampup ] } { set mssqls_rampup "2" }
if {  ![ info exists mssqls_duration ] } { set mssqls_duration "5" }
if {  ![ info exists mssqls_checkpoint ] } { set mssqls_checkpoint "false" }
if {  ![ info exists opmode ] } { set opmode "Local" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require tclodbc 2.5.1} \] { error \"Failed to load tclodbc - ODBC Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $mssqls_total_iterations;# Number of transactions before logging off
set RAISEERROR \"$mssqls_raiseerror\" ;# Exit script on Oracle error (true or false)
set KEYANDTHINK \"$mssqls_keyandthink\" ;# Time for user thinking and keying (true or false)
set CHECKPOINT \"$mssqls_checkpoint\" ;# Perform SQL Server checkpoint when complete (true or false)
set rampup $mssqls_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $mssqls_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set authentication \"$mssqls_authentication\";# Authentication Mode (WINDOWS or SQL)
set server \{$mssqls_server\};# Microsoft SQL Server Database Server
set port \"$mssqls_port\";# Microsoft SQL Server Port 
set odbc_driver \{$mssqls_odbc_driver\};# ODBC Driver
set uid \"$mssqls_uid\";#User ID for SQL Server Authentication
set pwd \"$mssqls_pass\";#Password for SQL Server Authentication
set database \"$mssqls_dbase\";# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 19.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#CHECK THREAD STATUS
proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }
if { [ chk_thread ] eq "FALSE" } {
error "SQL Server Timed Test Script must be run in Thread Enabled Interpreter"
}

proc connect_string { server port odbc_driver authentication uid pwd } {
if {[ string toupper $authentication ] eq "WINDOWS" } { 
if {[ string match -nocase {*native*} $odbc_driver ] } { 
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;TRUSTED_CONNECTION=YES"
} else {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
} else {
if {[ string toupper $authentication ] eq "SQL" } {
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port;UID=$uid;PWD=$pwd"
	} else {
puts stderr "Error: neither WINDOWS or SQL Authentication has been specified"
set connection "DRIVER=$odbc_driver;SERVER=$server;PORT=$port"
	}
}
return $connection
}

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
if { $mode eq "Local" || $mode eq "Master" } {
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd ]
if [catch {database connect odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
} else {
database connect odbc $connection
odbc "use $database"
odbc set autocommit off
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
if {[catch {set start_nopm [ odbc "select sum(d_next_o_id) from district" ]}]} {
puts stderr {error, failed to query district table}
return
}
if {[catch {set start_trans [ odbc "select cntr_value from sys.dm_os_performance_counters where counter_name = 'Batch Requests/sec'" ]}]} {
puts stderr {error, failed to query transaction statistics}
return
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
if {[catch {set end_nopm [ odbc "select sum(d_next_o_id) from district" ]}]} {
puts stderr {error, failed to query district table}
return
}
if {[catch {set end_trans [ odbc "select cntr_value from sys.dm_os_performance_counters where counter_name = 'Batch Requests/sec'" ]}]} {
puts stderr {error, failed to query transaction statistics}
return
} 
if { [ string is integer -strict $end_trans ] && [ string is integer -strict $start_trans ] } {
if { $start_trans < $end_trans }  {
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
	} else {
puts "Error: SQL Server returned end transaction count data greater than start data"
set tpm 0
	} 
} else {
puts "Error: SQL Server returned non-numeric transaction count data"
set tpm 0
	}
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm SQL Server TPM at $nopm NOPM"
tsv::set application abort 1
if { $CHECKPOINT } {
puts "Checkpoint"
if  [catch {odbc "checkpoint"} message ]  {
puts stderr {error, failed to execute checkpoint}
error message
return
	}
puts "Checkpoint Complete"
        }
odbc commit
odbc disconnect
		} else {
puts "Operating in Slave Mode, No Snapshots taken..."
		}
	}
default {
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format "%Y-%m-%d %H:%M:%S" ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { neword_st no_w_id w_id_input RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
if {[ catch {neword_st execute [ list $no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt $date ]} message]} {
if { $RAISEERROR } {
error "New Order : $message"
	} else {
puts $message
} } else {
neword_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
}
;
}
odbc commit
}
#PAYMENT
proc payment { payment_st p_w_id w_id_input RAISEERROR } {
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
if {[ catch {payment_st execute [ list $p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $name $h_date ]} message]} {
if { $RAISEERROR } {
error "Payment : $message"
	} else {
puts $message
} } else {
payment_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
}
;
}
odbc commit
}
#ORDER_STATUS
proc ostat { ostat_st w_id RAISEERROR } {
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
if {[ catch {ostat_st execute [ list $w_id $d_id $c_id $byname $name ]} message]} {
if { $RAISEERROR } {
error "Order Status : $message"
	} else {
puts $message
} } else {
ostat_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
}
;
}
odbc commit
}
#DELIVERY
proc delivery { delivery_st w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if {[ catch {delivery_st execute [ list $w_id $carrier_id $date ]} message]} {
if { $RAISEERROR } {
error "Delivery : $message"
	} else {
puts $message
} } else {
delivery_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
}
;
}
odbc commit
}
#STOCK LEVEL
proc slev { slev_st w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
if {[ catch {slev_st execute [ list $w_id $stock_level_d_id $threshold ]} message]} {
if { $RAISEERROR } {
error "Stock Level : $message"
	} else {
puts $message
} } else {
slev_st fetch op_params
foreach or [array names op_params] {
lappend oput $op_params($or)
	}
;
}
odbc commit
}
proc prep_statement { odbc statement_st } {
switch $statement_st {
slev_st {
odbc statement slev_st "EXEC SLEV @st_w_id = ?, @st_d_id = ?, @threshold = ?" {INTEGER INTEGER INTEGER} 
return slev_st
	}
delivery_st {
odbc statement delivery_st "EXEC DELIVERY @d_w_id = ?, @d_o_carrier_id = ?, @timestamp = ?" {INTEGER INTEGER TIMESTAMP}
return delivery_st
	}
ostat_st {
odbc statement ostat_st "EXEC OSTAT @os_w_id = ?, @os_d_id = ?, @os_c_id = ?, @byname = ?, @os_c_last = ?" {INTEGER INTEGER INTEGER INTEGER {CHAR 16}}
return ostat_st
	}
payment_st {
odbc statement payment_st "EXEC PAYMENT @p_w_id = ?, @p_d_id = ?, @p_c_w_id = ?, @p_c_d_id = ?, @p_c_id = ?, @byname = ?, @p_h_amount = ?, @p_c_last = ?, @TIMESTAMP =?" {INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER {CHAR 16} TIMESTAMP}
return payment_st
	}
neword_st {
odbc statement neword_st "EXEC NEWORD @no_w_id = ?, @no_max_w_id = ?, @no_d_id = ?, @no_c_id = ?, @no_o_ol_cnt = ?, @TIMESTAMP = ?" {INTEGER INTEGER INTEGER INTEGER INTEGER TIMESTAMP}
return neword_st
	}
    }
}

#RUN TPC-C
set connection [ connect_string $server $port $odbc_driver $authentication $uid $pwd ]
if [catch {database connect odbc $connection} message ] {
puts stderr "Error: the database connection to $connection could not be established"
error $message
return
} else {
database connect odbc $connection
odbc "use $database"
odbc set autocommit off
}
foreach st {neword_st payment_st ostat_st delivery_st slev_st} { set $st [ prep_statement odbc $st ] }
set w_id_input [ odbc  "select max(w_id) from WAREHOUSE" ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ odbc "select max(d_id) from DISTRICT" ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword neword_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment payment_st $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery delivery_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev slev_st $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat ostat_st $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
odbc commit
neword_st drop 
payment_st drop
delivery_st drop
slev_st drop
ostat_st drop
odbc disconnect
	}
     }
  }
}

proc check_mytpcc {} {
global mysql_host mysql_port my_count_ware mysql_user mysql_pass mysql_dbase storage_engine mysql_partition mysql_num_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists mysql_host ] } { set mysql_host "127.0.0.1" }
if {  ![ info exists mysql_port ] } { set mysql_port "3306" }
if {  ![ info exists my_count_ware ] } { set my_count_ware "1" }
if {  ![ info exists mysql_user ] } { set mysql_user "root" }
if {  ![ info exists mysql_pass ] } { set mysql_pass "mysql" }
if {  ![ info exists mysql_dbase ] } { set mysql_dbase "tpcc" }
if {  ![ info exists storage_engine ] } { set storage_engine "innodb" }
if {  ![ info exists mysql_partition ] } { set mysql_partition "false" }
if {  ![ info exists mysql_num_threads ] } { set mysql_num_threads "1" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a $my_count_ware Warehouse MySQL TPC-C schema\nin host [string toupper $mysql_host:$mysql_port] under user [ string toupper $mysql_user ] in database [ string toupper $mysql_dbase ] with storage engine [ string toupper $storage_engine ]?" -type yesno ] == yes} { 
if { $mysql_num_threads eq 1 || $my_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $mysql_num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to created thread for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require mysqltcl} ] { error "Failed to load mysqltcl - MySQL Library Error" }
proc CreateStoredProcs { mysql_handler } {
puts "CREATING TPCC STORED PROCEDURES"
set sql(1) { CREATE PROCEDURE `NEWORD` (
no_w_id		INTEGER,
no_max_w_id		INTEGER,
no_d_id		INTEGER,
no_c_id		INTEGER,
no_o_ol_cnt		INTEGER,
OUT no_c_discount 	DECIMAL(4,4),
OUT no_c_last 		VARCHAR(16),
OUT no_c_credit 		VARCHAR(2),
OUT no_d_tax 		DECIMAL(4,4),
OUT no_w_tax 		DECIMAL(4,4),
INOUT no_d_next_o_id 	INTEGER,
IN timestamp 		DATE
)
BEGIN
DECLARE no_ol_supply_w_id	INTEGER;
DECLARE no_ol_i_id		INTEGER;
DECLARE no_ol_quantity 		INTEGER;
DECLARE no_o_all_local 		INTEGER;
DECLARE o_id 			INTEGER;
DECLARE no_i_name		VARCHAR(24);
DECLARE no_i_price		DECIMAL(5,2);
DECLARE no_i_data		VARCHAR(50);
DECLARE no_s_quantity		DECIMAL(6);
DECLARE no_ol_amount		DECIMAL(6,2);
DECLARE no_s_dist_01		CHAR(24);
DECLARE no_s_dist_02		CHAR(24);
DECLARE no_s_dist_03		CHAR(24);
DECLARE no_s_dist_04		CHAR(24);
DECLARE no_s_dist_05		CHAR(24);
DECLARE no_s_dist_06		CHAR(24);
DECLARE no_s_dist_07		CHAR(24);
DECLARE no_s_dist_08		CHAR(24);
DECLARE no_s_dist_09		CHAR(24);
DECLARE no_s_dist_10		CHAR(24);
DECLARE no_ol_dist_info 	CHAR(24);
DECLARE no_s_data	   	VARCHAR(50);
DECLARE x		        INTEGER;
DECLARE rbk		       	INTEGER;
DECLARE loop_counter    	INT;
DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
DECLARE EXIT HANDLER FOR NOT FOUND ROLLBACK;
SET no_o_all_local = 0;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND
customer.c_d_id = no_d_id AND customer.c_id = no_c_id;
START TRANSACTION;
SELECT d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax
FROM district
WHERE d_id = no_d_id AND d_w_id = no_w_id FOR UPDATE;
UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = no_d_id AND d_w_id = no_w_id;
SET o_id = no_d_next_o_id;
INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (o_id, no_d_id, no_w_id, no_c_id, timestamp, no_o_ol_cnt, no_o_all_local);
INSERT INTO new_order (no_o_id, no_d_id, no_w_id) VALUES (o_id, no_d_id, no_w_id);
SET rbk = FLOOR(1 + (RAND() * 99));
SET loop_counter = 1;
WHILE loop_counter <= no_o_ol_cnt DO
IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1))
THEN
SET no_ol_i_id = 100001;
ELSE
SET no_ol_i_id = FLOOR(1 + (RAND() * 100000));
END IF;
SET x = FLOOR(1 + (RAND() * 100));
IF ( x > 1 )
THEN
SET no_ol_supply_w_id = no_w_id;
ELSE
SET no_ol_supply_w_id = no_w_id;
SET no_o_all_local = 0;
WHILE ((no_ol_supply_w_id = no_w_id) AND (no_max_w_id != 1)) DO
SET no_ol_supply_w_id = FLOOR(1 + (RAND() * no_max_w_id));
END WHILE;
END IF;
SET no_ol_quantity = FLOOR(1 + (RAND() * 10));
SELECT i_price, i_name, i_data INTO no_i_price, no_i_name, no_i_data
FROM item WHERE i_id = no_ol_i_id;
SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10
INTO no_s_quantity, no_s_data, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10
FROM stock WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id;
IF ( no_s_quantity > no_ol_quantity )
THEN
SET no_s_quantity = ( no_s_quantity - no_ol_quantity );
ELSE
SET no_s_quantity = ( no_s_quantity - no_ol_quantity + 91 );
END IF;
UPDATE stock SET s_quantity = no_s_quantity
WHERE s_i_id = no_ol_i_id
AND s_w_id = no_ol_supply_w_id;
SET no_ol_amount = (  no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );
CASE no_d_id
WHEN 1 THEN
SET no_ol_dist_info = no_s_dist_01;
WHEN 2 THEN
SET no_ol_dist_info = no_s_dist_02;
WHEN 3 THEN
SET no_ol_dist_info = no_s_dist_03;
WHEN 4 THEN
SET no_ol_dist_info = no_s_dist_04;
WHEN 5 THEN
SET no_ol_dist_info = no_s_dist_05;
WHEN 6 THEN
SET no_ol_dist_info = no_s_dist_06;
WHEN 7 THEN
SET no_ol_dist_info = no_s_dist_07;
WHEN 8 THEN
SET no_ol_dist_info = no_s_dist_08;
WHEN 9 THEN
SET no_ol_dist_info = no_s_dist_09;
WHEN 10 THEN
SET no_ol_dist_info = no_s_dist_10;
END CASE;
INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES (o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info);
set loop_counter = loop_counter + 1;
END WHILE;
COMMIT;
END }
set sql(2) { CREATE PROCEDURE `DELIVERY`(
d_w_id			INTEGER,
d_o_carrier_id  	INTEGER,
IN timestamp 		DATE
)
BEGIN
DECLARE d_no_o_id	INTEGER;
DECLARE current_rowid 	INTEGER;
DECLARE d_d_id	    	INTEGER;
DECLARE d_c_id        	INTEGER;
DECLARE d_ol_total	INTEGER;
DECLARE deliv_data	VARCHAR(100);
DECLARE loop_counter  	INT;
DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
SET loop_counter = 1;
WHILE loop_counter <= 10 DO
SET d_d_id = loop_counter;
SELECT no_o_id INTO d_no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id LIMIT 1;
DELETE FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id AND no_o_id = d_no_o_id;
SELECT o_c_id INTO d_c_id FROM orders
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
 UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
UPDATE order_line SET ol_delivery_d = timestamp
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND
ol_w_id = d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total
FROM order_line
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
SET deliv_data = CONCAT(d_d_id,' ',d_no_o_id,' ',timestamp);
COMMIT;
set loop_counter = loop_counter + 1;
END WHILE;
END }
set sql(3) { CREATE PROCEDURE `PAYMENT` (
p_w_id			INTEGER,
p_d_id			INTEGER,
p_c_w_id		INTEGER,
p_c_d_id		INTEGER,
INOUT p_c_id		INTEGER,
byname			INTEGER,
p_h_amount		DECIMAL(6,2),
INOUT p_c_last	  	VARCHAR(16),
OUT p_w_street_1  	VARCHAR(20),
OUT p_w_street_2  	VARCHAR(20),
OUT p_w_city		VARCHAR(20),
OUT p_w_state		CHAR(2),
OUT p_w_zip		CHAR(9),
OUT p_d_street_1	VARCHAR(20),
OUT p_d_street_2	VARCHAR(20),
OUT p_d_city		VARCHAR(20),
OUT p_d_state		CHAR(2),
OUT p_d_zip		CHAR(9),
OUT p_c_first		VARCHAR(16),
OUT p_c_middle		CHAR(2),
OUT p_c_street_1	VARCHAR(20),
OUT p_c_street_2	VARCHAR(20),
OUT p_c_city		VARCHAR(20),
OUT p_c_state		CHAR(2),
OUT p_c_zip		CHAR(9),
OUT p_c_phone		CHAR(16),
OUT p_c_since		DATE,
INOUT p_c_credit	CHAR(2),
OUT p_c_credit_lim 	DECIMAL(12,2),
OUT p_c_discount	DECIMAL(4,4),
INOUT p_c_balance 	DECIMAL(12,2),
OUT p_c_data		VARCHAR(500),
IN timestamp		DATE
)
BEGIN
DECLARE done      	INT DEFAULT 0;
DECLARE	namecnt		INTEGER;
DECLARE p_d_name	VARCHAR(11);
DECLARE p_w_name	VARCHAR(11);
DECLARE p_c_new_data	VARCHAR(500);
DECLARE h_data		VARCHAR(30);
DECLARE loop_counter  	INT;
DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
DECLARE c_byname CURSOR FOR
SELECT c_first, c_middle, c_id, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last
ORDER BY c_first;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
START TRANSACTION;
UPDATE warehouse SET w_ytd = w_ytd + p_h_amount
WHERE w_id = p_w_id;
SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name
INTO p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip, p_w_name
FROM warehouse
WHERE w_id = p_w_id;
UPDATE district SET d_ytd = d_ytd + p_h_amount
WHERE d_w_id = p_w_id AND d_id = p_d_id;
SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name
INTO p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip, p_d_name
FROM district
WHERE d_w_id = p_w_id AND d_id = p_d_id;
IF (byname = 1)
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = p_c_last AND c_d_id = p_c_d_id AND c_w_id = p_c_w_id;
OPEN c_byname;
IF ( MOD (namecnt, 2) = 1 )
THEN
SET namecnt = (namecnt + 1);
END IF;
SET loop_counter = 0;
WHILE loop_counter <= (namecnt/2) DO
FETCH c_byname
INTO p_c_first, p_c_middle, p_c_id, p_c_street_1, p_c_street_2, p_c_city,
p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since;
set loop_counter = loop_counter + 1;
END WHILE;
CLOSE c_byname;
ELSE
SELECT c_first, c_middle, c_last,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
INTO p_c_first, p_c_middle, p_c_last,
p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip,
p_c_phone, p_c_credit, p_c_credit_lim,
p_c_discount, p_c_balance, p_c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
END IF;
SET p_c_balance = ( p_c_balance + p_h_amount );
IF p_c_credit = 'BC'
THEN
 SELECT c_data INTO p_c_data
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
SET h_data = CONCAT(p_w_name,' ',p_d_name);
SET p_c_new_data = CONCAT(CAST(p_c_id AS CHAR),' ',CAST(p_c_d_id AS CHAR),' ',CAST(p_c_w_id AS CHAR),' ',CAST(p_d_id AS CHAR),' ',CAST(p_w_id AS CHAR),' ',CAST(FORMAT(p_h_amount,2) AS CHAR),CAST(timestamp AS CHAR),h_data);
SET p_c_new_data = SUBSTR(CONCAT(p_c_new_data,p_c_data),1,500-(LENGTH(p_c_new_data)));
UPDATE customer
SET c_balance = p_c_balance, c_data = p_c_new_data
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
ELSE
UPDATE customer SET c_balance = p_c_balance
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
END IF;
SET h_data = CONCAT(p_w_name,' ',p_d_name);
INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data)
VALUES (p_c_d_id, p_c_w_id, p_c_id, p_d_id, p_w_id, timestamp, p_h_amount, h_data);
COMMIT;
END }
set sql(4) { CREATE PROCEDURE `OSTAT` (
os_w_id                 INTEGER,
os_d_id                 INTEGER,
INOUT os_c_id           INTEGER,
byname                  INTEGER,
INOUT os_c_last         VARCHAR(16),
OUT os_c_first          VARCHAR(16),
OUT os_c_middle         CHAR(2),
OUT os_c_balance        DECIMAL(12,2),
OUT os_o_id             INTEGER,
OUT os_entdate          DATE,
OUT os_o_carrier_id     INTEGER
)
BEGIN 
DECLARE  os_ol_i_id 	INTEGER;
DECLARE  os_ol_supply_w_id INTEGER;
DECLARE  os_ol_quantity INTEGER;
DECLARE  os_ol_amount 	INTEGER;
DECLARE  os_ol_delivery_d 	DATE;
DECLARE done            INT DEFAULT 0;
DECLARE namecnt         INTEGER;
DECLARE i               INTEGER;
DECLARE loop_counter    INT;
DECLARE no_order_status VARCHAR(100);
DECLARE os_ol_i_id_array VARCHAR(200);
DECLARE os_ol_supply_w_id_array VARCHAR(200);
DECLARE os_ol_quantity_array VARCHAR(200);
DECLARE os_ol_amount_array VARCHAR(200);
DECLARE os_ol_delivery_d_array VARCHAR(210);
DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
DECLARE c_name CURSOR FOR
SELECT c_balance, c_first, c_middle, c_id
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id
ORDER BY c_first;
DECLARE c_line CURSOR FOR
SELECT ol_i_id, ol_supply_w_id, ol_quantity,
ol_amount, ol_delivery_d
FROM order_line
WHERE ol_o_id = os_o_id AND ol_d_id = os_d_id AND ol_w_id = os_w_id;
DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
set no_order_status = '';
set os_ol_i_id_array = 'CSV,';
set os_ol_supply_w_id_array = 'CSV,';
set os_ol_quantity_array = 'CSV,';
set os_ol_amount_array = 'CSV,';
set os_ol_delivery_d_array = 'CSV,';
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id;
IF ( MOD (namecnt, 2) = 1 )
THEN
SET namecnt = (namecnt + 1);
END IF;
OPEN c_name;
SET loop_counter = 0;
WHILE loop_counter <= (namecnt/2) DO
FETCH c_name
INTO os_c_balance, os_c_first, os_c_middle, os_c_id;
set loop_counter = loop_counter + 1;
END WHILE;
close c_name;
ELSE
SELECT c_balance, c_first, c_middle, c_last
INTO os_c_balance, os_c_first, os_c_middle, os_c_last
FROM customer
WHERE c_id = os_c_id AND c_d_id = os_d_id AND c_w_id = os_w_id;
END IF;
set done = 0;
SELECT o_id, o_carrier_id, o_entry_d
INTO os_o_id, os_o_carrier_id, os_entdate
FROM
(SELECT o_id, o_carrier_id, o_entry_d
FROM orders where o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id = os_c_id
ORDER BY o_id DESC) AS sb LIMIT 1;
IF done THEN
set no_order_status = 'No orders for customer';
END IF;
set done = 0;
set i = 0;
OPEN c_line;
REPEAT
FETCH c_line INTO os_ol_i_id, os_ol_supply_w_id, os_ol_quantity, os_ol_amount, os_ol_delivery_d;
IF NOT done THEN
set os_ol_i_id_array = CONCAT(os_ol_i_id_array,',',CAST(i AS CHAR),',',CAST(os_ol_i_id AS CHAR));
set os_ol_supply_w_id_array = CONCAT(os_ol_supply_w_id_array,',',CAST(i AS CHAR),',',CAST(os_ol_supply_w_id AS CHAR));
set os_ol_quantity_array = CONCAT(os_ol_quantity_array,',',CAST(i AS CHAR),',',CAST(os_ol_quantity AS CHAR));
set os_ol_amount_array = CONCAT(os_ol_amount_array,',',CAST(i AS CHAR),',',CAST(os_ol_amount AS CHAR));
set os_ol_delivery_d_array = CONCAT(os_ol_delivery_d_array,',',CAST(i AS CHAR),',',CAST(os_ol_delivery_d AS CHAR));
set i = i+1;
END IF;
UNTIL done END REPEAT;
CLOSE c_line;
END }
set sql(5) { CREATE PROCEDURE `SLEV` (
st_w_id                 INTEGER,
st_d_id                 INTEGER,
threshold               INTEGER
)
BEGIN 
DECLARE st_o_id         INTEGER;
DECLARE stock_count     INTEGER;
DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
DECLARE EXIT HANDLER FOR NOT FOUND ROLLBACK;
SELECT d_next_o_id INTO st_o_id
FROM district
WHERE d_w_id=st_w_id AND d_id=st_d_id;
SELECT COUNT(DISTINCT (s_i_id)) INTO stock_count
FROM order_line, stock
WHERE ol_w_id = st_w_id AND
ol_d_id = st_d_id AND (ol_o_id < st_o_id) AND
ol_o_id >= (st_o_id - 20) AND s_w_id = st_w_id AND
s_i_id = ol_i_id AND s_quantity < threshold;
END }
for { set i 1 } { $i <= 5 } { incr i } {
mysqlexec $mysql_handler $sql($i)
		}
return
}

proc GatherStatistics { mysql_handler } {
puts "GATHERING SCHEMA STATISTICS"
set sql(1) "analyze table customer, district, history, item, new_order, orders, order_line, stock, warehouse"
mysqlexec $mysql_handler $sql(1)
return
}

proc CreateDatabase { mysql_handler db } {
puts "CREATING DATABASE $db"
set sql(1) "SET FOREIGN_KEY_CHECKS = 0"
set sql(2) "CREATE DATABASE IF NOT EXISTS `$db` CHARACTER SET latin1 COLLATE latin1_swedish_ci"
for { set i 1 } { $i <= 2 } { incr i } {
mysqlexec $mysql_handler $sql($i)
		}
return
}

proc CreateTables { mysql_handler storage_engine num_part } {
puts "CREATING TPCC TABLES"
set sql(1) "CREATE TABLE `customer` (
  `c_id` INT(5) NULL,
  `c_d_id` INT(2) NULL,
  `c_w_id` INT(4) NULL,
  `c_first` VARCHAR(16) BINARY NULL,
  `c_middle` CHAR(2) BINARY NULL,
  `c_last` VARCHAR(16) BINARY NULL,
  `c_street_1` VARCHAR(20) BINARY NULL,
  `c_street_2` VARCHAR(20) BINARY NULL,
  `c_city` VARCHAR(20) BINARY NULL,
  `c_state` CHAR(2) BINARY NULL,
  `c_zip` CHAR(9) BINARY NULL,
  `c_phone` CHAR(16) BINARY NULL,
  `c_since` DATETIME NULL,
  `c_credit` CHAR(2) BINARY NULL,
  `c_credit_lim` DECIMAL(12, 2) NULL,
  `c_discount` DECIMAL(4, 4) NULL,
  `c_balance` DECIMAL(12, 2) NULL,
  `c_ytd_payment` DECIMAL(12, 2) NULL,
  `c_payment_cnt` INT(8) NULL,
  `c_delivery_cnt` INT(8) NULL,
  `c_data` VARCHAR(500) BINARY NULL,
PRIMARY KEY (`c_w_id`,`c_d_id`,`c_id`),
KEY c_w_id (`c_w_id`,`c_d_id`,`c_last`(16),`c_first`(16))
)
ENGINE = $storage_engine"
set sql(2) "CREATE TABLE `district` (
  `d_id` INT(2) NULL,
  `d_w_id` INT(4) NULL,
  `d_ytd` DECIMAL(12, 2) NULL,
  `d_tax` DECIMAL(4, 4) NULL,
  `d_next_o_id` INT NULL,
  `d_name` VARCHAR(10) BINARY NULL,
  `d_street_1` VARCHAR(20) BINARY NULL,
  `d_street_2` VARCHAR(20) BINARY NULL,
  `d_city` VARCHAR(20) BINARY NULL,
  `d_state` CHAR(2) BINARY NULL,
  `d_zip` CHAR(9) BINARY NULL,
PRIMARY KEY (`d_w_id`,`d_id`)
)
ENGINE = $storage_engine"
set sql(3) "CREATE TABLE `history` (
  `h_c_id` INT NULL,
  `h_c_d_id` INT NULL,
  `h_c_w_id` INT NULL,
  `h_d_id` INT NULL,
  `h_w_id` INT NULL,
  `h_date` DATETIME NULL,
  `h_amount` DECIMAL(6, 2) NULL,
  `h_data` VARCHAR(24) BINARY NULL
)
ENGINE = $storage_engine"
set sql(4) "CREATE TABLE `item` (
  `i_id` INT(6) NULL,
  `i_im_id` INT NULL,
  `i_name` VARCHAR(24) BINARY NULL,
  `i_price` DECIMAL(5, 2) NULL,
  `i_data` VARCHAR(50) BINARY NULL,
PRIMARY KEY (`i_id`)
)
ENGINE = $storage_engine"
set sql(5) "CREATE TABLE `new_order` (
  `no_w_id` INT NOT NULL,
  `no_d_id` INT NOT NULL,
  `no_o_id` INT NOT NULL,
PRIMARY KEY (`no_w_id`, `no_d_id`, `no_o_id`)
)
ENGINE = $storage_engine"
set sql(6) "CREATE TABLE `orders` (
  `o_id` INT NULL,
  `o_w_id` INT NULL,
  `o_d_id` INT NULL,
  `o_c_id` INT NULL,
  `o_carrier_id` INT NULL,
  `o_ol_cnt` INT NULL,
  `o_all_local` INT NULL,
  `o_entry_d` DATETIME NULL,
PRIMARY KEY (`o_w_id`,`o_d_id`,`o_id`),
KEY o_w_id (`o_w_id`,`o_d_id`,`o_c_id`,`o_id`)
)
ENGINE = $storage_engine"
if {$num_part eq 0} {
set sql(7) "CREATE TABLE `order_line` (
  `ol_w_id` INT NOT NULL,
  `ol_d_id` INT NOT NULL,
  `ol_o_id` iNT NOT NULL,
  `ol_number` INT NOT NULL,
  `ol_i_id` INT NULL,
  `ol_delivery_d` DATETIME NULL,
  `ol_amount` INT NULL,
  `ol_supply_w_id` INT NULL,
  `ol_quantity` INT NULL,
  `ol_dist_info` CHAR(24) BINARY NULL,
PRIMARY KEY (`ol_w_id`,`ol_d_id`,`ol_o_id`,`ol_number`)
)
ENGINE = $storage_engine"
	} else {
set sql(7) "CREATE TABLE `order_line` (
  `ol_w_id` INT NOT NULL,
  `ol_d_id` INT NOT NULL,
  `ol_o_id` iNT NOT NULL,
  `ol_number` INT NOT NULL,
  `ol_i_id` INT NULL,
  `ol_delivery_d` DATETIME NULL,
  `ol_amount` INT NULL,
  `ol_supply_w_id` INT NULL,
  `ol_quantity` INT NULL,
  `ol_dist_info` CHAR(24) BINARY NULL,
PRIMARY KEY (`ol_w_id`,`ol_d_id`,`ol_o_id`,`ol_number`)
)
ENGINE = $storage_engine
PARTITION BY HASH (`ol_w_id`)
PARTITIONS $num_part"
	}
set sql(8) "CREATE TABLE `stock` (
  `s_i_id` INT(6) NULL,
  `s_w_id` INT(4) NULL,
  `s_quantity` INT(6) NULL,
  `s_dist_01` CHAR(24) BINARY NULL,
  `s_dist_02` CHAR(24) BINARY NULL,
  `s_dist_03` CHAR(24) BINARY NULL,
  `s_dist_04` CHAR(24) BINARY NULL,
  `s_dist_05` CHAR(24) BINARY NULL,
  `s_dist_06` CHAR(24) BINARY NULL,
  `s_dist_07` CHAR(24) BINARY NULL,
  `s_dist_08` CHAR(24) BINARY NULL,
  `s_dist_09` CHAR(24) BINARY NULL,
  `s_dist_10` CHAR(24) BINARY NULL,
  `s_ytd` BIGINT(10) NULL,
  `s_order_cnt` INT(6) NULL,
  `s_remote_cnt` INT(6) NULL,
  `s_data` VARCHAR(50) BINARY NULL,
PRIMARY KEY (`s_w_id`,`s_i_id`)
)
ENGINE = $storage_engine"
set sql(9) "CREATE TABLE `warehouse` (
  `w_id` INT(4) NULL,
  `w_ytd` DECIMAL(12, 2) NULL,
  `w_tax` DECIMAL(4, 4) NULL,
  `w_name` VARCHAR(10) BINARY NULL,
  `w_street_1` VARCHAR(20) BINARY NULL,
  `w_street_2` VARCHAR(20) BINARY NULL,
  `w_city` VARCHAR(20) BINARY NULL,
  `w_state` CHAR(2) BINARY NULL,
  `w_zip` CHAR(9) BINARY NULL,
PRIMARY KEY (`w_id`)
)
ENGINE = $storage_engine"
for { set i 1 } { $i <= 9 } { incr i } {
mysqlexec $mysql_handler $sql($i)
		}
return
}

proc chk_thread {} {
        set chk [package provide Thread]
        if {[string length $chk]} {
            return "TRUE"
            } else {
            return "FALSE"
        }
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
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

proc Customer { mysql_handler d_id w_id CUST_PER_DIST } {
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
append c_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_first', '$c_middle', '$c_last', '[ lindex $c_add 0 ]', '[ lindex $c_add 1 ]', '[ lindex $c_add 2 ]', '[ lindex $c_add 3 ]', '[ lindex $c_add 4 ]', '$c_phone', str_to_date('[ gettimestamp ]','%Y%m%d%H%i%s'), '$c_credit', '$c_credit_lim', '$c_discount', '$c_balance', '$c_data', '10.0', '1', '0')
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
append h_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_w_id', '$c_d_id', str_to_date([ gettimestamp ],'%Y%m%d%H%i%s'), '$h_amount', '$h_data')
if { $bld_cnt<= 999 } { 
append c_val_list ,
append h_val_list ,
	}
incr bld_cnt
if { ![ expr {$c_id % 1000} ] } {
mysql::exec $mysql_handler "insert into customer (`c_id`, `c_d_id`, `c_w_id`, `c_first`, `c_middle`, `c_last`, `c_street_1`, `c_street_2`, `c_city`, `c_state`, `c_zip`, `c_phone`, `c_since`, `c_credit`, `c_credit_lim`, `c_discount`, `c_balance`, `c_data`, `c_ytd_payment`, `c_payment_cnt`, `c_delivery_cnt`) values $c_val_list"
mysql::exec $mysql_handler "insert into history (`h_c_id`, `h_c_d_id`, `h_c_w_id`, `h_w_id`, `h_d_id`, `h_date`, `h_amount`, `h_data`) values $h_val_list"
	mysql::commit $mysql_handler
	set bld_cnt 1
	unset c_val_list
	unset h_val_list
		}
	}
puts "Customer Done"
return
}

proc Orders { mysql_handler d_id w_id MAXITEMS ORD_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
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
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', str_to_date([ gettimestamp ],'%Y%m%d%H%i%s'), null, '$o_ol_cnt', '1')
set e "no1"
append no_val_list ('$o_id', '$o_d_id', '$o_w_id')
  } else {
  set e "o3"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', str_to_date([ gettimestamp ],'%Y%m%d%H%i%s'), '$o_carrier_id', '$o_ol_cnt', '1')
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', null)
if { $bld_cnt<= 99 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', str_to_date([ gettimestamp ],'%Y%m%d%H%i%s'))
if { $bld_cnt<= 99 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	}
}
if { $bld_cnt<= 99 } {
append o_val_list ,
if { $o_id > 2100 } {
append no_val_list ,
		}
        }
incr bld_cnt
 if { ![ expr {$o_id % 100} ] } {
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
	}
mysql::exec $mysql_handler "insert into orders (`o_id`, `o_c_id`, `o_d_id`, `o_w_id`, `o_entry_d`, `o_carrier_id`, `o_ol_cnt`, `o_all_local`) values $o_val_list"
if { $o_id > 2100 } {
mysql::exec $mysql_handler "insert into new_order (`no_o_id`, `no_d_id`, `no_w_id`) values $no_val_list"
	}
mysql::exec $mysql_handler "insert into order_line (`ol_o_id`, `ol_d_id`, `ol_w_id`, `ol_number`, `ol_i_id`, `ol_supply_w_id`, `ol_quantity`, `ol_amount`, `ol_dist_info`, `ol_delivery_d`) values $ol_val_list"
	mysql::commit $mysql_handler 
	set bld_cnt 1
	unset o_val_list
	unset -nocomplain no_val_list
	unset ol_val_list
			}
		}
	mysql::commit $mysql_handler 
	puts "Orders Done"
	return
}

proc LoadItems { mysql_handler MAXITEMS } {
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
	mysql::exec $mysql_handler "insert into item (`i_id`, `i_im_id`, `i_name`, `i_price`, `i_data`) VALUES ('$i_id', '$i_im_id', '$i_name', '$i_price', '$i_data')"
      if { ![ expr {$i_id % 50000} ] } {
	puts "Loading Items - $i_id"
			}
		}
	mysql::commit $mysql_handler 
	puts "Item done"
	return
	}

proc Stock { mysql_handler w_id MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
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
append val_list ('$s_i_id', '$s_w_id', '$s_quantity', '$s_dist_01', '$s_dist_02', '$s_dist_03', '$s_dist_04', '$s_dist_05', '$s_dist_06', '$s_dist_07', '$s_dist_08', '$s_dist_09', '$s_dist_10', '$s_data', '0', '0', '0')
if { $bld_cnt<= 999 } { 
append val_list ,
}
incr bld_cnt
      if { ![ expr {$s_i_id % 1000} ] } {
mysql::exec $mysql_handler "insert into stock (`s_i_id`, `s_w_id`, `s_quantity`, `s_dist_01`, `s_dist_02`, `s_dist_03`, `s_dist_04`, `s_dist_05`, `s_dist_06`, `s_dist_07`, `s_dist_08`, `s_dist_09`, `s_dist_10`, `s_data`, `s_ytd`, `s_order_cnt`, `s_remote_cnt`) values $val_list"
	mysql::commit $mysql_handler
	set bld_cnt 1
	unset val_list
	}
      if { ![ expr {$s_i_id % 20000} ] } {
	puts "Loading Stock - $s_i_id"
			}
	}
	mysql::commit $mysql_handler
	puts "Stock done"
	return
}

proc District { mysql_handler w_id DIST_PER_WARE } {
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
mysql::exec $mysql_handler "insert into district (`d_id`, `d_w_id`, `d_name`, `d_street_1`, `d_street_2`, `d_city`, `d_state`, `d_zip`, `d_tax`, `d_ytd`, `d_next_o_id`) values ('$d_id', '$d_w_id', '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', '$d_tax', '$d_ytd', '$d_next_o_id')"
	}
	mysql::commit $mysql_handler 
	puts "District done"
	return
}

proc LoadWare { mysql_handler ware_start count_ware MAXITEMS DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
mysql::exec $mysql_handler "insert into warehouse (`w_id`, `w_name`, `w_street_1`, `w_street_2`, `w_city`, `w_state`, `w_zip`, `w_tax`, `w_ytd`) values ('$w_id', '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , '[ lindex $add 3 ]', '[ lindex $add 4 ]', '$w_tax', '$w_ytd')"
	Stock $mysql_handler $w_id $MAXITEMS
	District $mysql_handler $w_id $DIST_PER_WARE
	mysql::commit $mysql_handler 
	}
}

proc LoadCust { mysql_handler ware_start count_ware CUST_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer $mysql_handler $d_id $w_id $CUST_PER_DIST
		}
	}
	mysql::commit $mysql_handler 
	return
}

proc LoadOrd { mysql_handler ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Orders $mysql_handler $d_id $w_id $MAXITEMS $ORD_PER_DIST
		}
	}
	mysql::commit $mysql_handler 
	return
}

proc do_tpcc { host port count_ware user password db storage_engine partition num_threads } {
global mysqlstatus
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
puts "CREATING [ string toupper $db ] SCHEMA"
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts stderr "error, the database connection to $host could not be established"
return
 } else {
CreateDatabase $mysql_handler $db
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 0
if { $partition eq "true" } {
if {$count_ware < 200} {
set num_part 0
        } else {
set num_part [ expr round($count_ware/100) ]
        }
        } else {
set num_part 0
}
CreateTables $mysql_handler $storage_engine $num_part
}
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems $mysql_handler $MAXITEMS
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
LoadItems $mysql_handler $MAXITEMS
}}
if { $threaded eq "SINGLE-THREADED" ||  $threaded eq "MULTI-THREADED" && $myposition != 1 } {
if { $threaded eq "MULTI-THREADED" } {
puts "Waiting for Monitor Thread..."
set mtcnt 0
while 1 {
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
        }
after 5000
}
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts stderr "error, the database connection to $host could not be established"
return
 } else {
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 0
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
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare $mysql_handler $mystart $myend $MAXITEMS $DIST_PER_WARE
LoadCust $mysql_handler $mystart $myend $CUST_PER_DIST $DIST_PER_WARE
LoadOrd $mysql_handler $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE
puts "End:[ clock format [ clock seconds ] ]"
mysql::commit $mysql_handler 
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
        }
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateStoredProcs $mysql_handler
GatherStatistics $mysql_handler
puts "[ string toupper $db ] SCHEMA COMPLETE"
mysqlclose $mysql_handler
return
		}
	}
}

set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1070.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "do_tpcc $mysql_host $mysql_port $my_count_ware $mysql_user $mysql_pass $mysql_dbase $storage_engine $mysql_partition $mysql_num_threads"
	} else { return }
}

proc loadmytpcc { } {
global  mysql_host mysql_port mysql_user mysql_pass mysql_dbase my_total_iterations my_raiseerror my_keyandthink _ED
if {  ![ info exists mysql_host ] } { set mysql_host "127.0.0.1" }
if {  ![ info exists mysql_port ] } { set mysql_port "3306" }
if {  ![ info exists mysql_user ] } { set mysql_user "root" }
if {  ![ info exists mysql_pass ] } { set mysql_pass "mysql" }
if {  ![ info exists mysql_dbase ] } { set mysql_dbase "tpcc" }
if {  ![ info exists my_total_iterations ] } { set my_total_iterations 1000 }
if {  ![ info exists my_raiseerror ] } { set my_raiseerror "false" }
if {  ![ info exists my_keyandthink ] } { set my_keyandthink "true" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require mysqltcl} \] { error \"Failed to load mysqltcl - MySQL Library Error\" }
global mysqlstatus
#EDITABLE OPTIONS##################################################
set total_iterations $my_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$my_raiseerror\" ;# Exit script on MySQL error (true or false)
set KEYANDTHINK \"$my_keyandthink\" ;# Time for user thinking and keying (true or false)
set host \"$mysql_host\" ;# Address of the server hosting MySQL 
set port \"$mysql_port\" ;# Port of the MySQL Server, defaults to 3306
set user \"$mysql_user\" ;# MySQL user
set password \"$mysql_pass\" ;# Password for the MySQL user
set db \"$mysql_dbase\" ;# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 14.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { mysql_handler no_w_id w_id_input RAISEERROR } {
global mysqlstatus
#open new order cursor
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
mysqlexec $mysql_handler "set @next_o_id = 0"
catch { mysqlexec $mysql_handler "CALL NEWORD($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,@disc,@last,@credit,@dtax,@wtax,@next_o_id,$date)" }
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "New Order : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
      } 
  } else {
puts [ join [ mysql::sel $mysql_handler "select @disc,@last,@credit,@dtax,@wtax,@next_o_id" -list ] ]
   }
}
#PAYMENT
proc payment { mysql_handler p_w_id w_id_input RAISEERROR } {
global mysqlstatus
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
mysqlexec $mysql_handler "set @p_c_id = $p_c_id, @p_c_last = '$name', @p_c_credit = 0, @p_c_balance = 0"
catch { mysqlexec $mysql_handler "CALL PAYMENT($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,@p_c_id,$byname,$p_h_amount,@p_c_last,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,@p_c_credit,@p_c_credit_lim,@p_c_discount,@p_c_balance,@p_c_data,$h_date)"}
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Payment : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
puts [ join [ mysql::sel $mysql_handler "select @p_c_id,@p_c_last,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,@p_c_credit,@p_c_credit_lim,@p_c_discount,@p_c_balance,@p_c_data" -list ] ]
    }
}
#ORDER_STATUS
proc ostat { mysql_handler w_id RAISEERROR } {
global mysqlstatus
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
mysqlexec $mysql_handler "set @os_c_id = $c_id, @os_c_last = '$name'"
catch { mysqlexec $mysql_handler "CALL OSTAT($w_id,$d_id,@os_c_id,$byname,@os_c_last,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id)"}
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Order Status : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
puts [ join [ mysql::sel $mysql_handler "select @os_c_id,@os_c_last,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id" -list ] ]
    }
}
#DELIVERY
proc delivery { mysql_handler w_id RAISEERROR } {
global mysqlstatus
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
catch { mysqlexec $mysql_handler "CALL DELIVERY($w_id,$carrier_id,$date)"}
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Delivery : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
puts "$w_id $carrier_id $date"
    }
}
#STOCK LEVEL
proc slev { mysql_handler w_id stock_level_d_id RAISEERROR } {
global mysqlstatus
set threshold [ RandomNumber 10 20 ]
mysqlexec $mysql_handler "CALL SLEV($w_id,$stock_level_d_id,$threshold)"
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Stock Level : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
puts "$w_id $stock_level_d_id $threshold"
    }
}
#RUN TPC-C
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts stderr "error, the database connection to $host could not be established"
return
 } else {
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 0
}
set w_id_input [ list [ mysql::sel $mysql_handler "select max(w_id) from warehouse" -list ] ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ list [ mysql::sel $mysql_handler "select max(d_id) from district" -list ] ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword $mysql_handler $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment $mysql_handler $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery $mysql_handler $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev $mysql_handler $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat $mysql_handler $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
mysqlclose $mysql_handler
	}
}

proc loadtimedmytpcc { } {
global  mysql_host mysql_port mysql_user mysql_pass mysql_dbase my_total_iterations my_raiseerror my_keyandthink my_rampup my_duration opmode _ED
if {  ![ info exists mysql_host ] } { set mysql_host "127.0.0.1" }
if {  ![ info exists mysql_port ] } { set mysql_port "3306" }
if {  ![ info exists mysql_user ] } { set mysql_user "root" }
if {  ![ info exists mysql_pass ] } { set mysql_pass "mysql" }
if {  ![ info exists mysql_dbase ] } { set mysql_dbase "tpcc" }
if {  ![ info exists my_total_iterations ] } { set my_total_iterations 1000 }
if {  ![ info exists my_raiseerror ] } { set my_raiseerror "false" }
if {  ![ info exists my_keyandthink ] } { set my_keyandthink "true" }
if {  ![ info exists my_rampup ] } { set my_rampup "2" }
if {  ![ info exists my_duration ] } { set my_duration "5" }
if {  ![ info exists opmode ] } { set opmode "Local" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C Timed Test"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[ catch {package require mysqltcl} \] { error \"Failed to load mysqltcl - MySQL Library Error\" }
global mysqlstatus
#EDITABLE OPTIONS##################################################
set total_iterations $my_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$my_raiseerror\" ;# Exit script on MySQL error (true or false)
set KEYANDTHINK \"$my_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $my_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $my_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set host \"$mysql_host\" ;# Address of the server hosting MySQL 
set port \"$mysql_port\" ;# Port of the MySQL Server, defaults to 3306
set user \"$mysql_user\" ;# MySQL user
set password \"$mysql_pass\" ;# Password for the MySQL user
set db \"$mysql_dbase\" ;# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 17.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#CHECK THREAD STATUS
proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }
if { [ chk_thread ] eq "FALSE" } {
error "MYSQL Timed Test Script must be run in Thread Enabled Interpreter"
}
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
if { $mode eq "Local" || $mode eq "Master" } {
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts stderr "error, the database connection to $host could not be established"
return
 } else {
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 1
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
if {[catch {set handler_stat [ list [ mysql::sel $mysql_handler "show global status where Variable_name = 'Handler_commit' or Variable_name =  'Handler_rollback'" -list ] ]}]} {
puts stderr {error, failed to query transaction statistics}
return
} else {
regexp {\{\{Handler_commit\ ([0-9]+)\}\ \{Handler_rollback\ ([0-9]+)\}\}} $handler_stat all handler_comm handler_roll
set start_trans [ expr $handler_comm + $handler_roll ]
	}
if {[catch {set start_nopm [ list [ mysql::sel $mysql_handler "select sum(d_next_o_id) from district" -list ] ]}]} {
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
if { ![ expr {$testtime % 60000} ] } {
puts -nonewline  "[ expr $testtime / 60000 ]  ...,"
	}
}
if { [ tsv::get application abort ] } { break }
puts "Test complete, Taking end Transaction Count."
if {[catch {set handler_stat [ list [ mysql::sel $mysql_handler "show global status where Variable_name = 'Handler_commit' or Variable_name =  'Handler_rollback'" -list ] ]}]} {
puts stderr {error, failed to query transaction statistics}
return
} else {
regexp {\{\{Handler_commit\ ([0-9]+)\}\ \{Handler_rollback\ ([0-9]+)\}\}} $handler_stat all handler_comm handler_roll
set end_trans [ expr $handler_comm + $handler_roll ]
	}
if {[catch {set end_nopm [ list [ mysql::sel $mysql_handler "select sum(d_next_o_id) from district" -list ] ]}]} {
puts stderr {error, failed to query district table}
return
}
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm MySQL TPM at $nopm NOPM"
tsv::set application abort 1
catch { mysqlclose $mysql_handler }
		} else {
puts "Operating in Slave Mode, No Snapshots taken..."
		}
	}
default {
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { mysql_handler no_w_id w_id_input RAISEERROR } {
global mysqlstatus
#open new order cursor
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
mysqlexec $mysql_handler "set @next_o_id = 0"
catch { mysqlexec $mysql_handler "CALL NEWORD($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,@disc,@last,@credit,@dtax,@wtax,@next_o_id,$date)" }
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "New Order : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
      } 
  } else {
;
   }
}
#PAYMENT
proc payment { mysql_handler p_w_id w_id_input RAISEERROR } {
global mysqlstatus
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
mysqlexec $mysql_handler "set @p_c_id = $p_c_id, @p_c_last = '$name', @p_c_credit = 0, @p_c_balance = 0"
catch { mysqlexec $mysql_handler "CALL PAYMENT($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,@p_c_id,$byname,$p_h_amount,@p_c_last,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,@p_c_credit,@p_c_credit_lim,@p_c_discount,@p_c_balance,@p_c_data,$h_date)"}
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Payment : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
;
    }
}
#ORDER_STATUS
proc ostat { mysql_handler w_id RAISEERROR } {
global mysqlstatus
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
mysqlexec $mysql_handler "set @os_c_id = $c_id, @os_c_last = '$name'"
catch { mysqlexec $mysql_handler "CALL OSTAT($w_id,$d_id,@os_c_id,$byname,@os_c_last,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id)"}
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Order Status : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
;
    }
}
#DELIVERY
proc delivery { mysql_handler w_id RAISEERROR } {
global mysqlstatus
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
catch { mysqlexec $mysql_handler "CALL DELIVERY($w_id,$carrier_id,$date)"}
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Delivery : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
;
    }
}
#STOCK LEVEL
proc slev { mysql_handler w_id stock_level_d_id RAISEERROR } {
global mysqlstatus
set threshold [ RandomNumber 10 20 ]
mysqlexec $mysql_handler "CALL SLEV($w_id,$stock_level_d_id,$threshold)"
if { $mysqlstatus(code)  } {
if { $RAISEERROR } {
error "Stock Level : $mysqlstatus(message)"
	} else { puts $mysqlstatus(message) 
       } 
  } else {
;
    }
}
#RUN TPC-C
if [catch {mysqlconnect -host $host -port $port -user $user -password $password} mysql_handler] {
puts stderr "error, the database connection to $host could not be established"
return
 } else {
mysqluse $mysql_handler $db
mysql::autocommit $mysql_handler 0
}
set w_id_input [ list [ mysql::sel $mysql_handler "select max(w_id) from warehouse" -list ] ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ list [ mysql::sel $mysql_handler "select max(d_id) from district" -list ] ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword $mysql_handler $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment $mysql_handler $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery $mysql_handler $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev $mysql_handler $w_id $stock_level_d_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat $mysql_handler $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
mysqlclose $mysql_handler
	}
     }
  }
}

proc check_pgtpcc {} {
global pg_host pg_port pg_count_ware pg_superuser pg_superuserpass pg_defaultdbase pg_user pg_pass pg_dbase pg_oracompat pg_num_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists pg_host ] } { set pg_host "localhost" }
if {  ![ info exists pg_port ] } { set pg_port "5432" }
if {  ![ info exists pg_count_ware ] } { set pg_count_ware "1" }
if {  ![ info exists pg_superuser ] } { set pg_superuser "postgres" }
if {  ![ info exists pg_superuserpass ] } { set pg_superuserpass "postgres" }
if {  ![ info exists pg_defaultdbase ] } { set pg_defaultdbase "postgres" }
if {  ![ info exists pg_user ] } { set pg_user "tpcc" }
if {  ![ info exists pg_pass ] } { set pg_pass "tpcc" }
if {  ![ info exists pg_dbase ] } { set pg_dbase "tpcc" }
if {  ![ info exists pg_oracompat ] } { set pg_oracompat "false" }
if {  ![ info exists pg_num_threads ] } { set pg_num_threads "1" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a $pg_count_ware Warehouse PostgreSQL TPC-C schema\nin host [string toupper $pg_host:$pg_port] under user [ string toupper $pg_user ] in database [ string toupper $pg_dbase ]?" -type yesno ] == yes} { 
if { $pg_num_threads eq 1 || $pg_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $pg_num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to created thread for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require Pgtcl} ] { error "Failed to load Pgtcl - Postgres Library Error" }
proc CreateStoredProcs { lda ora_compatible } {
puts "CREATING TPCC STORED PROCEDURES"
if { $ora_compatible eq "true" } {
set sql(1) { CREATE OR REPLACE FUNCTION DBMS_RANDOM (INTEGER, INTEGER) RETURNS INTEGER AS $$
DECLARE
    start_int ALIAS FOR $1;
    end_int ALIAS FOR $2;
BEGIN
    RETURN trunc(random() * (end_int-start_int) + start_int);
END;
$$ LANGUAGE 'plpgsql' STRICT;
}
set sql(2) { CREATE OR REPLACE PROCEDURE NEWORD (
no_w_id		INTEGER,
no_max_w_id		INTEGER,
no_d_id		INTEGER,
no_c_id		INTEGER,
no_o_ol_cnt		INTEGER,
no_c_discount		OUT NUMBER,
no_c_last		OUT VARCHAR2,
no_c_credit		OUT VARCHAR2,
no_d_tax		OUT NUMBER,
no_w_tax		OUT NUMBER,
no_d_next_o_id		IN OUT INTEGER,
tstamp		IN DATE )
IS
no_ol_supply_w_id	INTEGER;
no_ol_i_id		NUMBER;
no_ol_quantity		NUMBER;
no_o_all_local		INTEGER;
o_id			INTEGER;
no_i_name		VARCHAR2(24);
no_i_price		NUMBER(5,2);
no_i_data		VARCHAR2(50);
no_s_quantity		NUMBER(6);
no_ol_amount		NUMBER(6,2);
no_s_dist_01		CHAR(24);
no_s_dist_02		CHAR(24);
no_s_dist_03		CHAR(24);
no_s_dist_04		CHAR(24);
no_s_dist_05		CHAR(24);
no_s_dist_06		CHAR(24);
no_s_dist_07		CHAR(24);
no_s_dist_08		CHAR(24);
no_s_dist_09		CHAR(24);
no_s_dist_10		CHAR(24);
no_ol_dist_info		CHAR(24);
no_s_data		VARCHAR2(50);
x			NUMBER;
rbk			NUMBER;
BEGIN
--assignment below added due to error in appendix code
no_o_all_local := 0;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND
customer.c_d_id = no_d_id AND customer.c_id = no_c_id;
UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = no_d_id AND d_w_id = no_w_id RETURNING d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax;
o_id := no_d_next_o_id;
INSERT INTO ORDERS (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (o_id, no_d_id, no_w_id, no_c_id, tstamp, no_o_ol_cnt, no_o_all_local);
INSERT INTO NEW_ORDER (no_o_id, no_d_id, no_w_id) VALUES (o_id, no_d_id, no_w_id);
--#2.4.1.4
rbk := round(DBMS_RANDOM(1,100));
--#2.4.1.5
FOR loop_counter IN 1 .. no_o_ol_cnt
LOOP
IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1))
THEN
no_ol_i_id := 100001;
ELSE
no_ol_i_id := round(DBMS_RANDOM(1,100000));
END IF;
--#2.4.1.5.2
x := round(DBMS_RANDOM(1,100));
IF ( x > 1 )
THEN
no_ol_supply_w_id := no_w_id;
ELSE
no_ol_supply_w_id := no_w_id;
--no_all_local is actually used before this point so following not beneficial
no_o_all_local := 0;
WHILE ((no_ol_supply_w_id = no_w_id) AND (no_max_w_id != 1))
LOOP
no_ol_supply_w_id := round(DBMS_RANDOM(1,no_max_w_id));
END LOOP;
END IF;
--#2.4.1.5.3
no_ol_quantity := round(DBMS_RANDOM(1,10));
SELECT i_price, i_name, i_data INTO no_i_price, no_i_name, no_i_data
FROM item WHERE i_id = no_ol_i_id;
SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10
INTO no_s_quantity, no_s_data, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10 FROM stock WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id;
IF ( no_s_quantity > no_ol_quantity )
THEN
no_s_quantity := ( no_s_quantity - no_ol_quantity );
ELSE
no_s_quantity := ( no_s_quantity - no_ol_quantity + 91 );
END IF;
UPDATE stock SET s_quantity = no_s_quantity
WHERE s_i_id = no_ol_i_id
AND s_w_id = no_ol_supply_w_id;

no_ol_amount := (  no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );

IF no_d_id = 1
THEN 
no_ol_dist_info := no_s_dist_01; 

ELSIF no_d_id = 2
THEN
no_ol_dist_info := no_s_dist_02;

ELSIF no_d_id = 3
THEN
no_ol_dist_info := no_s_dist_03;

ELSIF no_d_id = 4
THEN
no_ol_dist_info := no_s_dist_04;

ELSIF no_d_id = 5
THEN
no_ol_dist_info := no_s_dist_05;

ELSIF no_d_id = 6
THEN
no_ol_dist_info := no_s_dist_06;

ELSIF no_d_id = 7
THEN
no_ol_dist_info := no_s_dist_07;

ELSIF no_d_id = 8
THEN
no_ol_dist_info := no_s_dist_08;

ELSIF no_d_id = 9
THEN
no_ol_dist_info := no_s_dist_09;

ELSIF no_d_id = 10
THEN
no_ol_dist_info := no_s_dist_10;
END IF;

INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES (o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info);

END LOOP;

COMMIT;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; }
set sql(3) { CREATE OR REPLACE PROCEDURE DELIVERY (
d_w_id			INTEGER,
d_o_carrier_id		INTEGER,
tstamp		IN DATE )
IS
d_no_o_id		INTEGER;
d_d_id	           	INTEGER;
d_c_id	           	NUMBER;
d_ol_total		NUMBER;
loop_counter            INTEGER;
BEGIN
FOR loop_counter IN 1 .. 10
LOOP
d_d_id := loop_counter;
SELECT no_o_id INTO d_no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id ORDER BY no_o_id ASC LIMIT 1;
DELETE FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id AND no_o_id = d_no_o_id;
SELECT o_c_id INTO d_c_id FROM orders
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
 UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
UPDATE order_line SET ol_delivery_d = tstamp
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND
ol_w_id = d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total
FROM order_line
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
COMMIT;
DBMS_OUTPUT.PUT_LINE('D: ' || d_d_id || 'O: ' || d_no_o_id || 'time ' || tstamp);
END LOOP;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; }
set sql(4) { CREATE OR REPLACE PROCEDURE PAYMENT (
p_w_id			INTEGER,
p_d_id			INTEGER,
p_c_w_id		INTEGER,
p_c_d_id		INTEGER,
p_c_id			IN OUT NUMBER(5,0),
byname			INTEGER,
p_h_amount		NUMBER,
p_c_last		IN OUT VARCHAR2(16),
p_w_street_1		OUT VARCHAR2(20),
p_w_street_2		OUT VARCHAR2(20),
p_w_city		OUT VARCHAR2(20),
p_w_state		OUT CHAR(2),
p_w_zip			OUT CHAR(9),
p_d_street_1		OUT VARCHAR2(20),
p_d_street_2		OUT VARCHAR2(20),
p_d_city		OUT VARCHAR2(20),
p_d_state		OUT CHAR(2),
p_d_zip			OUT CHAR(9),
p_c_first		OUT VARCHAR2(16),
p_c_middle		OUT CHAR(2),
p_c_street_1		OUT VARCHAR2(20),
p_c_street_2		OUT VARCHAR2(20),
p_c_city		OUT VARCHAR2(20),
p_c_state		OUT CHAR(2),
p_c_zip			OUT CHAR(9),
p_c_phone		OUT CHAR(16),
p_c_since		OUT DATE,
p_c_credit		IN OUT CHAR(2),
p_c_credit_lim		OUT NUMBER(12, 2),
p_c_discount		OUT NUMBER(4, 4),
p_c_balance		IN OUT NUMBER(12, 2),
p_c_data		OUT VARCHAR2(500),
tstamp		IN DATE )
IS
namecnt			INTEGER;
p_d_name		VARCHAR2(11);
p_w_name		VARCHAR2(11);
p_c_new_data		VARCHAR2(500);
h_data			VARCHAR2(30);
CURSOR c_byname IS
SELECT c_first, c_middle, c_id,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last
ORDER BY c_first;
BEGIN
UPDATE warehouse SET w_ytd = w_ytd + p_h_amount
WHERE w_id = p_w_id;
SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name
INTO p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip, p_w_name
FROM warehouse
WHERE w_id = p_w_id;
UPDATE district SET d_ytd = d_ytd + p_h_amount
WHERE d_w_id = p_w_id AND d_id = p_d_id;
SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name
INTO p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip, p_d_name
FROM district
WHERE d_w_id = p_w_id AND d_id = p_d_id;
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = p_c_last AND c_d_id = p_c_d_id AND c_w_id = p_c_w_id;
OPEN c_byname;
IF ( MOD (namecnt, 2) = 1 )
THEN
namecnt := (namecnt + 1);
END IF;
FOR loop_counter IN 0 .. cast((namecnt/2) AS INTEGER)
LOOP
FETCH c_byname
INTO p_c_first, p_c_middle, p_c_id, p_c_street_1, p_c_street_2, p_c_city,
p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since;
END LOOP;
CLOSE c_byname;
ELSE
SELECT c_first, c_middle, c_last,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
INTO p_c_first, p_c_middle, p_c_last,
p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip,
p_c_phone, p_c_credit, p_c_credit_lim,
p_c_discount, p_c_balance, p_c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
END IF;
p_c_balance := ( p_c_balance + p_h_amount );
IF p_c_credit = 'BC' 
THEN
 SELECT c_data INTO p_c_data
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
-- The following statement in the TPC-C specification appendix is incorrect
-- copied setting of h_data from later on in the procedure to here as well
h_data := ( p_w_name || ' ' || p_d_name );
p_c_new_data := (TO_CHAR(p_c_id) || ' ' || TO_CHAR(p_c_d_id) || ' ' ||
TO_CHAR(p_c_w_id) || ' ' || TO_CHAR(p_d_id) || ' ' || TO_CHAR(p_w_id) || ' ' || TO_CHAR(p_h_amount,'9999.99') || TO_CHAR(tstamp) || h_data);
p_c_new_data := substr(CONCAT(p_c_new_data,p_c_data),1,500-(LENGTH(p_c_new_data)));
UPDATE customer
SET c_balance = p_c_balance, c_data = p_c_new_data
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
ELSE
UPDATE customer SET c_balance = p_c_balance
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
END IF;
--setting of h_data is here in the TPC-C appendix
h_data := ( p_w_name|| ' ' || p_d_name );
INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id,
h_w_id, h_date, h_amount, h_data)
VALUES (p_c_d_id, p_c_w_id, p_c_id, p_d_id,
p_w_id, tstamp, p_h_amount, h_data);
COMMIT;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; }
set sql(5) { CREATE OR REPLACE PROCEDURE OSTAT (
os_w_id			INTEGER,
os_d_id			INTEGER,
os_c_id			IN OUT INTEGER,
byname			INTEGER,
os_c_last		IN OUT VARCHAR2,
os_c_first		OUT VARCHAR2,
os_c_middle		OUT VARCHAR2,
os_c_balance		OUT NUMBER,
os_o_id			OUT INTEGER,
os_entdate		OUT DATE,
os_o_carrier_id		OUT INTEGER )
IS
TYPE numbertable IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
os_ol_i_id numbertable;	
os_ol_supply_w_id numbertable;	
os_ol_quantity numbertable;	
TYPE amounttable IS TABLE OF NUMBER(6,2) INDEX BY BINARY_INTEGER;
os_ol_amount amounttable;
TYPE datetable IS TABLE OF DATE INDEX BY BINARY_INTEGER;
os_ol_delivery_d datetable;
namecnt			INTEGER;
i			BINARY_INTEGER;
CURSOR c_name IS
SELECT c_balance, c_first, c_middle, c_id
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id
ORDER BY c_first;
CURSOR c_line IS
SELECT ol_i_id, ol_supply_w_id, ol_quantity,
ol_amount, ol_delivery_d
FROM order_line
WHERE ol_o_id = os_o_id AND ol_d_id = os_d_id AND ol_w_id = os_w_id;
os_c_line c_line%ROWTYPE;
BEGIN
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id;
IF ( MOD (namecnt, 2) = 1 )
THEN
namecnt := (namecnt + 1);
END IF;
OPEN c_name;
FOR loop_counter IN 0 .. cast((namecnt/2) AS INTEGER)
LOOP
FETCH c_name  
INTO os_c_balance, os_c_first, os_c_middle, os_c_id;
END LOOP;
close c_name;
ELSE
SELECT c_balance, c_first, c_middle, c_last
INTO os_c_balance, os_c_first, os_c_middle, os_c_last
FROM customer
WHERE c_id = os_c_id AND c_d_id = os_d_id AND c_w_id = os_w_id;
END IF;
BEGIN
SELECT o_id, o_carrier_id, o_entry_d 
INTO os_o_id, os_o_carrier_id, os_entdate
FROM
(SELECT o_id, o_carrier_id, o_entry_d
FROM orders where o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id=os_c_id
ORDER BY o_id DESC)
WHERE ROWNUM = 1;
EXCEPTION
WHEN NO_DATA_FOUND THEN
dbms_output.put_line('No orders for customer');
END;
i := 0;
FOR os_c_line IN c_line
LOOP
os_ol_i_id(i) := os_c_line.ol_i_id;
os_ol_supply_w_id(i) := os_c_line.ol_supply_w_id;
os_ol_quantity(i) := os_c_line.ol_quantity;
os_ol_amount(i) := os_c_line.ol_amount;
os_ol_delivery_d(i) := os_c_line.ol_delivery_d;
i := i+1;
END LOOP;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; }
set sql(6) { CREATE OR REPLACE PROCEDURE SLEV (
st_w_id			INTEGER,
st_d_id			INTEGER,
threshold		INTEGER )
IS 
st_o_id			NUMBER;	
stock_count		INTEGER;
BEGIN
SELECT d_next_o_id INTO st_o_id
FROM district
WHERE d_w_id=st_w_id AND d_id=st_d_id;
SELECT COUNT(DISTINCT (s_i_id)) INTO stock_count
FROM order_line, stock
WHERE ol_w_id = st_w_id AND
ol_d_id = st_d_id AND (ol_o_id < st_o_id) AND
ol_o_id >= (st_o_id - 20) AND s_w_id = st_w_id AND
s_i_id = ol_i_id AND s_quantity < threshold;
COMMIT;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; }
for { set i 1 } { $i <= 6 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
} else {
set sql(1) { CREATE OR REPLACE FUNCTION DBMS_RANDOM (INTEGER, INTEGER) RETURNS INTEGER AS $$
DECLARE
    start_int ALIAS FOR $1;
    end_int ALIAS FOR $2;
BEGIN
    RETURN trunc(random() * (end_int-start_int) + start_int);
END;
$$ LANGUAGE 'plpgsql' STRICT;
}
set sql(2) { CREATE OR REPLACE FUNCTION NEWORD (INTEGER, INTEGER, INTEGER, INTEGER, INTEGER, INTEGER) RETURNS NUMERIC AS '
DECLARE
no_w_id		ALIAS FOR $1;	
no_max_w_id	ALIAS FOR $2;
no_d_id		ALIAS FOR $3;
no_c_id		ALIAS FOR $4;
no_o_ol_cnt	ALIAS FOR $5;
no_d_next_o_id	ALIAS FOR $6;
no_c_discount	NUMERIC;
no_c_last	VARCHAR;
no_c_credit	VARCHAR;
no_d_tax	NUMERIC;
no_w_tax	NUMERIC;
tstamp		TIMESTAMP;
no_ol_supply_w_id	INTEGER;
no_ol_i_id		NUMERIC;
no_ol_quantity		NUMERIC;
no_o_all_local		INTEGER;
o_id			INTEGER;
no_i_name		VARCHAR(24);
no_i_price		NUMERIC(5,2);
no_i_data		VARCHAR(50);
no_s_quantity		NUMERIC(6);
no_ol_amount		NUMERIC(6,2);
no_s_dist_01		CHAR(24);
no_s_dist_02		CHAR(24);
no_s_dist_03		CHAR(24);
no_s_dist_04		CHAR(24);
no_s_dist_05		CHAR(24);
no_s_dist_06		CHAR(24);
no_s_dist_07		CHAR(24);
no_s_dist_08		CHAR(24);
no_s_dist_09		CHAR(24);
no_s_dist_10		CHAR(24);
no_ol_dist_info		CHAR(24);
no_s_data		VARCHAR(50);
x			NUMERIC;
rbk			NUMERIC;
BEGIN
--assignment below added due to error in appendix code
no_o_all_local := 0;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND
customer.c_d_id = no_d_id AND customer.c_id = no_c_id;
UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = no_d_id AND d_w_id = no_w_id RETURNING d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax;
o_id := no_d_next_o_id;
INSERT INTO ORDERS (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (o_id, no_d_id, no_w_id, no_c_id, current_timestamp, no_o_ol_cnt, no_o_all_local);
INSERT INTO NEW_ORDER (no_o_id, no_d_id, no_w_id) VALUES (o_id, no_d_id, no_w_id);
--#2.4.1.4
rbk := round(DBMS_RANDOM(1,100));
--#2.4.1.5
FOR loop_counter IN 1 .. no_o_ol_cnt
LOOP
IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1))
THEN
no_ol_i_id := 100001;
ELSE
no_ol_i_id := round(DBMS_RANDOM(1,100000));
END IF;
--#2.4.1.5.2
x := round(DBMS_RANDOM(1,100));
IF ( x > 1 )
THEN
no_ol_supply_w_id := no_w_id;
ELSE
no_ol_supply_w_id := no_w_id;
--no_all_local is actually used before this point so following not beneficial
no_o_all_local := 0;
WHILE ((no_ol_supply_w_id = no_w_id) AND (no_max_w_id != 1))
LOOP
no_ol_supply_w_id := round(DBMS_RANDOM(1,no_max_w_id));
END LOOP;
END IF;
--#2.4.1.5.3
no_ol_quantity := round(DBMS_RANDOM(1,10));
SELECT i_price, i_name, i_data INTO no_i_price, no_i_name, no_i_data
FROM item WHERE i_id = no_ol_i_id;
SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10
INTO no_s_quantity, no_s_data, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10 FROM stock WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id;
IF ( no_s_quantity > no_ol_quantity )
THEN
no_s_quantity := ( no_s_quantity - no_ol_quantity );
ELSE
no_s_quantity := ( no_s_quantity - no_ol_quantity + 91 );
END IF;
UPDATE stock SET s_quantity = no_s_quantity
WHERE s_i_id = no_ol_i_id
AND s_w_id = no_ol_supply_w_id;

no_ol_amount := (  no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );

IF no_d_id = 1
THEN 
no_ol_dist_info := no_s_dist_01; 

ELSIF no_d_id = 2
THEN
no_ol_dist_info := no_s_dist_02;

ELSIF no_d_id = 3
THEN
no_ol_dist_info := no_s_dist_03;

ELSIF no_d_id = 4
THEN
no_ol_dist_info := no_s_dist_04;

ELSIF no_d_id = 5
THEN
no_ol_dist_info := no_s_dist_05;

ELSIF no_d_id = 6
THEN
no_ol_dist_info := no_s_dist_06;

ELSIF no_d_id = 7
THEN
no_ol_dist_info := no_s_dist_07;

ELSIF no_d_id = 8
THEN
no_ol_dist_info := no_s_dist_08;

ELSIF no_d_id = 9
THEN
no_ol_dist_info := no_s_dist_09;

ELSIF no_d_id = 10
THEN
no_ol_dist_info := no_s_dist_10;
END IF;

INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES (o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info);

END LOOP;
RETURN no_s_quantity;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; 
' LANGUAGE 'plpgsql';
	}
set sql(3) { CREATE OR REPLACE FUNCTION DELIVERY (INTEGER, INTEGER) RETURNS INTEGER AS '
DECLARE
d_w_id		ALIAS FOR $1;	
d_o_carrier_id  ALIAS FOR $2;	
d_d_id	       	INTEGER;
d_c_id	       	NUMERIC;
d_no_o_id		INTEGER;
d_ol_total		NUMERIC;
loop_counter		INTEGER;
BEGIN
FOR loop_counter IN 1 .. 10
LOOP
d_d_id := loop_counter;
SELECT no_o_id INTO d_no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id ORDER BY no_o_id ASC LIMIT 1;
DELETE FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id AND no_o_id = d_no_o_id;
SELECT o_c_id INTO d_c_id FROM orders
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
 UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id;
UPDATE order_line SET ol_delivery_d = current_timestamp
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND
ol_w_id = d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total
FROM order_line
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id
AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
END LOOP;
RETURN 1;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; 
' LANGUAGE 'plpgsql';
}
set sql(4) { CREATE OR REPLACE FUNCTION PAYMENT (INTEGER, INTEGER, INTEGER, INTEGER, NUMERIC, INTEGER, NUMERIC, VARCHAR, VARCHAR, NUMERIC ) RETURNS INTEGER AS '
DECLARE
p_w_id			ALIAS FOR $1;
p_d_id			ALIAS FOR $2;
p_c_w_id		ALIAS FOR $3;
p_c_d_id		ALIAS FOR $4;
p_c_id_in		ALIAS FOR $5;
byname			ALIAS FOR $6;
p_h_amount		ALIAS FOR $7;
p_c_last_in		ALIAS FOR $8;
p_c_credit_in		ALIAS FOR $9;
p_c_balance_in		ALIAS FOR $10;
p_c_balance             NUMERIC(12, 2);
p_c_credit              CHAR(2);
p_c_last		VARCHAR(16);
p_c_id			NUMERIC(5,0);
p_w_street_1            VARCHAR(20);
p_w_street_2            VARCHAR(20);
p_w_city                VARCHAR(20);
p_w_state               CHAR(2);
p_w_zip                 CHAR(9);
p_d_street_1            VARCHAR(20);
p_d_street_2            VARCHAR(20);
p_d_city                VARCHAR(20);
p_d_state               CHAR(2);
p_d_zip                 CHAR(9);
p_c_first               VARCHAR(16);
p_c_middle              CHAR(2);
p_c_street_1            VARCHAR(20);
p_c_street_2            VARCHAR(20);
p_c_city                VARCHAR(20);
p_c_state               CHAR(2);
p_c_zip                 CHAR(9);
p_c_phone               CHAR(16);
p_c_since		TIMESTAMP;
p_c_credit_lim          NUMERIC(12, 2);
p_c_discount            NUMERIC(4, 4);
p_c_data                VARCHAR(500);
tstamp			TIMESTAMP;
namecnt			INTEGER;
p_d_name		VARCHAR(11);
p_w_name		VARCHAR(11);
p_c_new_data		VARCHAR(500);
h_data			VARCHAR(30);
c_byname CURSOR FOR
SELECT c_first, c_middle, c_id,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last
ORDER BY c_first;
BEGIN
p_c_balance := p_c_balance_in;
p_c_id := p_c_id_in;
p_c_last := p_c_last_in;
p_c_credit := p_c_credit_in;
tstamp := current_timestamp;
UPDATE warehouse SET w_ytd = w_ytd + p_h_amount
WHERE w_id = p_w_id;
SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name
INTO p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip, p_w_name
FROM warehouse
WHERE w_id = p_w_id;
UPDATE district SET d_ytd = d_ytd + p_h_amount
WHERE d_w_id = p_w_id AND d_id = p_d_id;
SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name
INTO p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip, p_d_name
FROM district
WHERE d_w_id = p_w_id AND d_id = p_d_id;
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = p_c_last AND c_d_id = p_c_d_id AND c_w_id = p_c_w_id;
OPEN c_byname;
IF ( MOD (namecnt, 2) = 1 )
THEN
namecnt := (namecnt + 1);
END IF;
FOR loop_counter IN 0 .. cast((namecnt/2) AS INTEGER)
LOOP
FETCH c_byname
INTO p_c_first, p_c_middle, p_c_id, p_c_street_1, p_c_street_2, p_c_city,
p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since;
END LOOP;
CLOSE c_byname;
ELSE
SELECT c_first, c_middle, c_last,
c_street_1, c_street_2, c_city, c_state, c_zip,
c_phone, c_credit, c_credit_lim,
c_discount, c_balance, c_since
INTO p_c_first, p_c_middle, p_c_last,
p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip,
p_c_phone, p_c_credit, p_c_credit_lim,
p_c_discount, p_c_balance, p_c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
END IF;
p_c_balance := ( p_c_balance + p_h_amount );
IF p_c_credit = ''BC'' 
THEN
 SELECT c_data INTO p_c_data
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
h_data := p_w_name || '' '' || p_d_name;
p_c_new_data := (p_c_id || '' '' || p_c_d_id || '' '' || p_c_w_id || '' '' || p_d_id || '' '' || p_w_id || '' '' || TO_CHAR(p_h_amount,''9999.99'') || TO_CHAR(tstamp,''YYYYMMDDHH24MISS'') || h_data);
p_c_new_data := substr(CONCAT(p_c_new_data,p_c_data),1,500-(LENGTH(p_c_new_data)));
UPDATE customer
SET c_balance = p_c_balance, c_data = p_c_new_data
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
ELSE
UPDATE customer SET c_balance = p_c_balance
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND
c_id = p_c_id;
END IF;
h_data := p_w_name || '' '' || p_d_name;
INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id,
h_w_id, h_date, h_amount, h_data)
VALUES (p_c_d_id, p_c_w_id, p_c_id, p_d_id,
p_w_id, tstamp, p_h_amount, h_data);
RETURN p_c_id;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; 
' LANGUAGE 'plpgsql';
	}
set sql(5) { CREATE OR REPLACE FUNCTION OSTAT (INTEGER, INTEGER, INTEGER, INTEGER, VARCHAR) RETURNS SETOF record AS '
DECLARE
os_w_id		ALIAS FOR $1;
os_d_id		ALIAS FOR $2;		
os_c_id	 	ALIAS FOR $3;
byname		ALIAS FOR $4;	
os_c_last	ALIAS FOR $5;
out_os_c_id	INTEGER;
out_os_c_last	VARCHAR;
os_c_first	VARCHAR;
os_c_middle	VARCHAR;
os_c_balance	NUMERIC;
os_o_id		INTEGER;
os_entdate	TIMESTAMP;
os_o_carrier_id	INTEGER;
os_ol 		RECORD;
namecnt		INTEGER;
c_name CURSOR FOR
SELECT c_balance, c_first, c_middle, c_id
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id
ORDER BY c_first;
BEGIN
IF ( byname = 1 )
THEN
SELECT count(c_id) INTO namecnt
FROM customer
WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id;
IF ( MOD (namecnt, 2) = 1 )
THEN
namecnt := (namecnt + 1);
END IF;
OPEN c_name;
FOR loop_counter IN 0 .. cast((namecnt/2) AS INTEGER)
LOOP
FETCH c_name  
INTO os_c_balance, os_c_first, os_c_middle, os_c_id;
END LOOP;
close c_name;
ELSE
SELECT c_balance, c_first, c_middle, c_last
INTO os_c_balance, os_c_first, os_c_middle, os_c_last
FROM customer
WHERE c_id = os_c_id AND c_d_id = os_d_id AND c_w_id = os_w_id;
END IF;
SELECT o_id, o_carrier_id, o_entry_d 
INTO os_o_id, os_o_carrier_id, os_entdate
FROM
(SELECT o_id, o_carrier_id, o_entry_d
FROM orders where o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id=os_c_id
ORDER BY o_id DESC) AS SUBQUERY
LIMIT 1;
FOR os_ol IN
SELECT ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_delivery_d, out_os_c_id, out_os_c_last, os_c_first, os_c_middle, os_c_balance, os_o_id, os_entdate, os_o_carrier_id	
FROM order_line
WHERE ol_o_id = os_o_id AND ol_d_id = os_d_id AND ol_w_id = os_w_id
LOOP
RETURN NEXT os_ol;
END LOOP;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; 
' LANGUAGE 'plpgsql';
}
set sql(6) { CREATE OR REPLACE FUNCTION SLEV (INTEGER, INTEGER, INTEGER) RETURNS INTEGER AS '
DECLARE
st_w_id			ALIAS FOR $1;
st_d_id			ALIAS FOR $2;
threshold		ALIAS FOR $3; 

st_o_id			NUMERIC;	
stock_count		INTEGER;
BEGIN
SELECT d_next_o_id INTO st_o_id
FROM district
WHERE d_w_id=st_w_id AND d_id=st_d_id;

SELECT COUNT(DISTINCT (s_i_id)) INTO stock_count
FROM order_line, stock
WHERE ol_w_id = st_w_id AND
ol_d_id = st_d_id AND (ol_o_id < st_o_id) AND
ol_o_id >= (st_o_id - 20) AND s_w_id = st_w_id AND
s_i_id = ol_i_id AND s_quantity < threshold;
RETURN stock_count;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END; 
' LANGUAGE 'plpgsql';
	}
for { set i 1 } { $i <= 6 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
}
return
}

proc GatherStatistics { lda } {
puts "GATHERING SCHEMA STATISTICS"
set sql(1) "ANALYZE"
for { set i 1 } { $i <= 1 } { incr i } {
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
if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]}]} {
puts stderr "Error, the database connection to $host could not be established"
set lda "Failed"
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

proc CreateUserDatabase { lda db user password } {
puts "CREATING DATABASE $db under OWNER $user"  
set sql(1) "CREATE USER $user PASSWORD '$password'"
set sql(2) "CREATE DATABASE $db OWNER $user"
for { set i 1 } { $i <= 2 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
return
}

proc CreateTables { lda ora_compatible } {
puts "CREATING TPCC TABLES"
if { $ora_compatible eq "true" } {
set sql(1) "CREATE TABLE CUSTOMER (C_ID NUMBER(5, 0), C_D_ID NUMBER(2, 0), C_W_ID NUMBER(4, 0), C_FIRST VARCHAR2(16), C_MIDDLE CHAR(2), C_LAST VARCHAR2(16), C_STREET_1 VARCHAR2(20), C_STREET_2 VARCHAR2(20), C_CITY VARCHAR2(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE DATE, C_CREDIT CHAR(2), C_CREDIT_LIM NUMBER(12, 2), C_DISCOUNT NUMBER(4, 4), C_BALANCE NUMBER(12, 2), C_YTD_PAYMENT NUMBER(12, 2), C_PAYMENT_CNT NUMBER(8, 0), C_DELIVERY_CNT NUMBER(8, 0), C_DATA VARCHAR2(500))"
set sql(2) "CREATE TABLE DISTRICT (D_ID NUMBER(2, 0), D_W_ID NUMBER(4, 0), D_YTD NUMBER(12, 2), D_TAX NUMBER(4, 4), D_NEXT_O_ID NUMBER, D_NAME VARCHAR2(10), D_STREET_1 VARCHAR2(20), D_STREET_2 VARCHAR2(20), D_CITY VARCHAR2(20), D_STATE CHAR(2), D_ZIP CHAR(9))"
set sql(3) "CREATE TABLE HISTORY (H_C_ID NUMBER, H_C_D_ID NUMBER, H_C_W_ID NUMBER, H_D_ID NUMBER, H_W_ID NUMBER, H_DATE DATE, H_AMOUNT NUMBER(6, 2), H_DATA VARCHAR2(24))"
set sql(4) "CREATE TABLE ITEM (I_ID NUMBER(6, 0), I_IM_ID NUMBER, I_NAME VARCHAR2(24), I_PRICE NUMBER(5, 2), I_DATA VARCHAR2(50))"
set sql(5) "CREATE TABLE WAREHOUSE (W_ID NUMBER(4, 0), W_YTD NUMBER(12, 2), W_TAX NUMBER(4, 4), W_NAME VARCHAR2(10), W_STREET_1 VARCHAR2(20), W_STREET_2 VARCHAR2(20), W_CITY VARCHAR2(20), W_STATE CHAR(2), W_ZIP CHAR(9))"
set sql(6) "CREATE TABLE STOCK (S_I_ID NUMBER(6, 0), S_W_ID NUMBER(4, 0), S_QUANTITY NUMBER(6, 0), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD NUMBER(10, 0), S_ORDER_CNT NUMBER(6, 0), S_REMOTE_CNT NUMBER(6, 0), S_DATA VARCHAR2(50))"
set sql(7) "CREATE TABLE NEW_ORDER (NO_W_ID NUMBER, NO_D_ID NUMBER, NO_O_ID NUMBER)"
set sql(8) "CREATE TABLE ORDERS (O_ID NUMBER, O_W_ID NUMBER, O_D_ID NUMBER, O_C_ID NUMBER, O_CARRIER_ID NUMBER, O_OL_CNT NUMBER, O_ALL_LOCAL NUMBER, O_ENTRY_D DATE)"
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID NUMBER, OL_D_ID NUMBER, OL_O_ID NUMBER, OL_NUMBER NUMBER, OL_I_ID NUMBER, OL_DELIVERY_D DATE, OL_AMOUNT NUMBER, OL_SUPPLY_W_ID NUMBER, OL_QUANTITY NUMBER, OL_DIST_INFO CHAR(24))"
	} else {
set sql(1) "CREATE TABLE CUSTOMER (C_ID NUMERIC(5,0), C_D_ID NUMERIC(2,0), C_W_ID NUMERIC(4,0), C_FIRST VARCHAR(16), C_MIDDLE CHAR(2), C_LAST VARCHAR(16), C_STREET_1 VARCHAR(20), C_STREET_2 VARCHAR(20), C_CITY VARCHAR(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE TIMESTAMP, C_CREDIT CHAR(2), C_CREDIT_LIM NUMERIC(12, 2), C_DISCOUNT NUMERIC(4,4), C_BALANCE NUMERIC(12, 2), C_YTD_PAYMENT NUMERIC(12, 2), C_PAYMENT_CNT NUMERIC(8,0), C_DELIVERY_CNT NUMERIC(8,0), C_DATA VARCHAR(500))"
set sql(2) "CREATE TABLE DISTRICT (D_ID NUMERIC(2,0), D_W_ID NUMERIC(4,0), D_YTD NUMERIC(12, 2), D_TAX NUMERIC(4,4), D_NEXT_O_ID NUMERIC, D_NAME VARCHAR(10), D_STREET_1 VARCHAR(20), D_STREET_2 VARCHAR(20), D_CITY VARCHAR(20), D_STATE CHAR(2), D_ZIP CHAR(9))"
set sql(3) "CREATE TABLE HISTORY (H_C_ID NUMERIC, H_C_D_ID NUMERIC, H_C_W_ID NUMERIC, H_D_ID NUMERIC, H_W_ID NUMERIC, H_DATE TIMESTAMP, H_AMOUNT NUMERIC(6,2), H_DATA VARCHAR(24))"
set sql(4) "CREATE TABLE ITEM (I_ID NUMERIC(6,0), I_IM_ID NUMERIC, I_NAME VARCHAR(24), I_PRICE NUMERIC(5,2), I_DATA VARCHAR(50))"
set sql(5) "CREATE TABLE WAREHOUSE (W_ID NUMERIC(4,0), W_YTD NUMERIC(12, 2), W_TAX NUMERIC(4,4), W_NAME VARCHAR(10), W_STREET_1 VARCHAR(20), W_STREET_2 VARCHAR(20), W_CITY VARCHAR(20), W_STATE CHAR(2), W_ZIP CHAR(9))"
set sql(6) "CREATE TABLE STOCK (S_I_ID NUMERIC(6,0), S_W_ID NUMERIC(4,0), S_QUANTITY NUMERIC(6,0), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD NUMERIC(10, 0), S_ORDER_CNT NUMERIC(6,0), S_REMOTE_CNT NUMERIC(6,0), S_DATA VARCHAR(50))"
set sql(7) "CREATE TABLE NEW_ORDER (NO_W_ID NUMERIC, NO_D_ID NUMERIC, NO_O_ID NUMERIC)"
set sql(8) "CREATE TABLE ORDERS (O_ID NUMERIC, O_W_ID NUMERIC, O_D_ID NUMERIC, O_C_ID NUMERIC, O_CARRIER_ID NUMERIC, O_OL_CNT NUMERIC, O_ALL_LOCAL NUMERIC, O_ENTRY_D TIMESTAMP)"
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID NUMERIC, OL_D_ID NUMERIC, OL_O_ID NUMERIC, OL_NUMBER NUMERIC, OL_I_ID NUMERIC, OL_DELIVERY_D TIMESTAMP, OL_AMOUNT NUMERIC, OL_SUPPLY_W_ID NUMERIC, OL_QUANTITY NUMERIC, OL_DIST_INFO CHAR(24))"
	}
for { set i 1 } { $i <= 9 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	} else {
pg_result $result -clear
	}
    }
}

proc CreateIndexes { lda } {
puts "CREATING TPCC INDEXES"
set sql(1) "ALTER TABLE CUSTOMER ADD CONSTRAINT CUSTOMER_I1 PRIMARY KEY (C_W_ID, C_D_ID, C_ID)"
set sql(2) "CREATE UNIQUE INDEX CUSTOMER_I2 ON CUSTOMER (C_W_ID, C_D_ID, C_LAST, C_FIRST, C_ID)"
set sql(3) "ALTER TABLE DISTRICT ADD CONSTRAINT DISTRICT_I1 PRIMARY KEY (D_W_ID, D_ID) WITH (FILLFACTOR = 100)"
set sql(4) "ALTER TABLE NEW_ORDER ADD CONSTRAINT NEW_ORDER_I1 PRIMARY KEY (NO_W_ID, NO_D_ID, NO_O_ID)"
set sql(5) "ALTER TABLE ITEM ADD CONSTRAINT ITEM_I1 PRIMARY KEY (I_ID)"
set sql(6) "ALTER TABLE ORDERS ADD CONSTRAINT ORDERS_I1 PRIMARY KEY (O_W_ID, O_D_ID, O_ID)"
set sql(7) "CREATE UNIQUE INDEX ORDERS_I2 ON ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID)"
set sql(8) "ALTER TABLE ORDER_LINE ADD CONSTRAINT ORDER_LINE_I1 PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER)"
set sql(9) "ALTER TABLE STOCK ADD CONSTRAINT STOCK_I1 PRIMARY KEY (S_W_ID, S_I_ID)"
set sql(10) "ALTER TABLE WAREHOUSE ADD CONSTRAINT WAREHOUSE_I1 PRIMARY KEY (W_ID) WITH (FILLFACTOR = 100)"
for { set i 1 } { $i <= 10 } { incr i } {
set result [ pg_exec $lda $sql($i) ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
error "[pg_result $result -error]"
	}  else {
	pg_result $result -clear
	}
    }
return
}

proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
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

proc Customer { lda d_id w_id CUST_PER_DIST ora_compatible } {
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
if { $ora_compatible eq "true" } {
proc date_function {} {
set df "to_date('[ gettimestamp ]','YYYYMMDDHH24MISS')"
return $df
}
	} else {
proc date_function {} {
set df "to_timestamp('[ gettimestamp ]','YYYYMMDDHH24MISS')"
return $df
}
	}
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
append c_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_first', '$c_middle', '$c_last', '[ lindex $c_add 0 ]', '[ lindex $c_add 1 ]', '[ lindex $c_add 2 ]', '[ lindex $c_add 3 ]', '[ lindex $c_add 4 ]', '$c_phone', [ date_function ], '$c_credit', '$c_credit_lim', '$c_discount', '$c_balance', '$c_data', '10.0', '1', '0')
set h_data [ MakeAlphaString 12 24 $globArray $chalen ]
append h_val_list ('$c_id', '$c_d_id', '$c_w_id', '$c_w_id', '$c_d_id', [ date_function ], '$h_amount', '$h_data')
if { $bld_cnt<= 999 } { 
append c_val_list ,
append h_val_list ,
	}
incr bld_cnt
if { ![ expr {$c_id % 1000} ] } {
set result [ pg_exec $lda "insert into customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) values $c_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
set result [ pg_exec $lda "insert into history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) values $h_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	set bld_cnt 1
	unset c_val_list
	unset h_val_list
		}
	}
puts "Customer Done"
return
}

proc Orders { lda d_id w_id MAXITEMS ORD_PER_DIST ora_compatible } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
if { $ora_compatible eq "true" } {
proc date_function {} {
set df "to_date('[ gettimestamp ]','YYYYMMDDHH24MISS')"
return $df
}
	} else {
proc date_function {} {
set df "to_timestamp('[ gettimestamp ]','YYYYMMDDHH24MISS')"
return $df
}
	}
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
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', [ date_function ], null, '$o_ol_cnt', '1')
set e "no1"
append no_val_list ('$o_id', '$o_d_id', '$o_w_id')
  } else {
  set e "o3"
append o_val_list ('$o_id', '$o_c_id', '$o_d_id', '$o_w_id', [ date_function ], '$o_carrier_id', '$o_ol_cnt', '1')
	}
for {set ol 1} {$ol <= $o_ol_cnt } {incr ol } {
set ol_i_id [ RandomNumber 1 $MAXITEMS ]
set ol_supply_w_id $o_w_id
set ol_quantity 5
set ol_amount 0.0
set ol_dist_info [ MakeAlphaString 24 24 $globArray $chalen ]
if { $o_id > 2100 } {
set e "ol1"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', null)
if { $bld_cnt<= 99 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', [ date_function ])
if { $bld_cnt<= 99 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	}
}
if { $bld_cnt<= 99 } {
append o_val_list ,
if { $o_id > 2100 } {
append no_val_list ,
		}
        }
incr bld_cnt
 if { ![ expr {$o_id % 100} ] } {
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
	}
set result [ pg_exec $lda  "insert into orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values $o_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
if { $o_id > 2100 } {
set result [ pg_exec $lda "insert into new_order (no_o_id, no_d_id, no_w_id) values $no_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	}
set result [ pg_exec $lda "insert into order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values $ol_val_list" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	set bld_cnt 1
	unset o_val_list
	unset -nocomplain no_val_list
	unset ol_val_list
			}
		}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	puts "Orders Done"
	return
}

proc LoadItems { lda MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Item"
set result [ pg_exec $lda "begin" ]
pg_result $result -clear
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
set result [ pg_exec $lda "insert into item (i_id, i_im_id, i_name, i_price, i_data) VALUES ('$i_id', '$i_im_id', '$i_name', '$i_price', '$i_data')" ]
 if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
	    return
        } else {
	pg_result $result -clear
	}
      if { ![ expr {$i_id % 10000} ] } {
	puts "Loading Items - $i_id"
			}
		}
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
puts "Item done"
return
	}

proc Stock { lda w_id MAXITEMS } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
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
append val_list ('$s_i_id', '$s_w_id', '$s_quantity', '$s_dist_01', '$s_dist_02', '$s_dist_03', '$s_dist_04', '$s_dist_05', '$s_dist_06', '$s_dist_07', '$s_dist_08', '$s_dist_09', '$s_dist_10', '$s_data', '0', '0', '0')
if { $bld_cnt<= 999 } { 
append val_list ,
}
incr bld_cnt
      if { ![ expr {$s_i_id % 1000} ] } {
set result [ pg_exec $lda "insert into stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) values $val_list" ]
	if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	set bld_cnt 1
	unset val_list
	}
      if { ![ expr {$s_i_id % 20000} ] } {
	puts "Loading Stock - $s_i_id"
			}
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
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
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
set d_name [ MakeAlphaString 6 10 $globArray $chalen ]
set d_add [ MakeAddress $globArray $chalen ]
set d_tax_ran [ RandomNumber 10 20 ]
set d_tax [ string replace [ format "%.2f" [ expr {$d_tax_ran / 100.0} ] ] 0 0 "" ]
set result [ pg_exec $lda "insert into district (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) values ('$d_id', '$d_w_id', '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', '$d_tax', '$d_ytd', '$d_next_o_id')" ]
if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
	    return
        } else {
	pg_result $result -clear
	}
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	puts "District done"
	return
}

proc LoadWare { lda ware_start count_ware MAXITEMS DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
set result [ pg_exec $lda "insert into warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values ('$w_id', '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , '[ lindex $add 3 ]', '[ lindex $add 4 ]', '$w_tax', '$w_ytd')" ]
 if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
            error "[pg_result $result -error]"
        } else {
	pg_result $result -clear
	}
	Stock $lda $w_id $MAXITEMS
	District $lda $w_id $DIST_PER_WARE
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	}
}

proc LoadCust { lda ware_start count_ware CUST_PER_DIST DIST_PER_WARE ora_compatible } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer $lda $d_id $w_id $CUST_PER_DIST $ora_compatible
		}
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	return
}

proc LoadOrd { lda ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE ora_compatible } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Orders $lda $d_id $w_id $MAXITEMS $ORD_PER_DIST $ora_compatible
		}
	}
	set result [ pg_exec $lda "commit" ]
	pg_result $result -clear
	return
}
proc do_tpcc { host port count_ware superuser superuser_password defaultdb db user password ora_compatible num_threads } {
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
puts "CREATING [ string toupper $superuser ] SCHEMA"
set lda [ ConnectToPostgres $host $port $superuser $superuser_password $defaultdb ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 } else {
CreateUserDatabase $lda $db $user $password
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
pg_disconnect $lda
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 } else {
CreateTables $lda $ora_compatible
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
        }
}
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
if { $lvcnt != $prevactive } {
puts "Workers: $lvcnt Active $dncnt Done"
	}
set prevactive $lvcnt
if { $dncnt eq [expr  $totalvirtualusers - 1] } { break }
after 10000 
}} else {
LoadItems $lda $MAXITEMS
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
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare $lda $mystart $myend $MAXITEMS $DIST_PER_WARE
LoadCust $lda $mystart $myend $CUST_PER_DIST $DIST_PER_WARE $ora_compatible
LoadOrd $lda $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE $ora_compatible
puts "End:[ clock format [ clock seconds ] ]"
set result [ pg_exec $lda "commit" ]
pg_result $result -clear
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
	}
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
CreateIndexes $lda
CreateStoredProcs $lda $ora_compatible
GatherStatistics $lda 
puts "[ string toupper $user ] SCHEMA COMPLETE"
pg_disconnect $lda
return
	}
    }
}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1510.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "do_tpcc $pg_host $pg_port $pg_count_ware $pg_superuser $pg_superuserpass $pg_defaultdbase $pg_user $pg_pass $pg_dbase $pg_oracompat $pg_num_threads"
	} else { return }
}

proc loadpgtpcc { } {
global pg_host pg_port pg_user pg_pass pg_dbase pg_oracompat pg_total_iterations pg_raiseerror pg_keyandthink _ED
if {  ![ info exists pg_host ] } { set pg_host "localhost" }
if {  ![ info exists pg_port ] } { set pg_port "5432" }
if {  ![ info exists pg_user ] } { set pg_user "tpcc" }
if {  ![ info exists pg_pass ] } { set pg_pass "tpcc" }
if {  ![ info exists pg_dbase ] } { set pg_dbase "tpcc" }
if {  ![ info exists pg_oracompat ] } { set pg_oracompat "false" }
if {  ![ info exists pg_total_iterations ] } { set pg_total_iterations 1000000 }
if {  ![ info exists pg_raiseerror ] } { set pg_raiseerror "false" }
if {  ![ info exists pg_keyandthink ] } { set pg_keyandthink "false" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require Pgtcl} \] { error \"Failed to load Pgtcl - Postgres Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $pg_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$pg_raiseerror\" ;# Exit script on PostgreSQL (true or false)
set KEYANDTHINK \"$pg_keyandthink\" ;# Time for user thinking and keying (true or false)
set ora_compatible \"$pg_oracompat\" ;#Postgres Plus Oracle Compatible Schema
set host \"$pg_host\" ;# Address of the server hosting PostgreSQL
set port \"$pg_port\" ;# Port of the PostgreSQL Server
set user \"$pg_user\" ;# PostgreSQL user
set password \"$pg_pass\" ;# Password for the PostgreSQL user
set db \"$pg_dbase\" ;# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 14.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#POSTGRES CONNECTION
proc ConnectToPostgres { host port user password dbname } {
global tcl_platform
if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]}]} {
puts stderr "Error, the database connection to $host could not be established"
set lda "Failed"
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
#NEW ORDER
proc neword { lda no_w_id w_id_input RAISEERROR ora_compatible } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec neword($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,0,TO_TIMESTAMP($date,'YYYYMMDDHH24MISS'))" ]
} else {
set result [pg_exec $lda "select neword($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,0)" ]
}
if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "New Order Procedure Error set RAISEERROR for Details"
		}
	} else {
puts "New Order: $no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt 0 [ pg_result $result -list ]"
pg_result $result -clear
	}
}
#PAYMENT
proc payment { lda p_w_id w_id_input RAISEERROR ora_compatible } {
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
#change following to correct values
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec payment($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,$p_c_id,$byname,$p_h_amount,'$name','0',0,TO_TIMESTAMP($h_date,'YYYYMMDDHH24MISS'))" ]
} else {
set result [pg_exec $lda "select payment($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,$p_c_id,$byname,$p_h_amount,'$name','0',0)" ]
}
if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Payment Procedure Error set RAISEERROR for Details"
		}
	} else {
puts "Payment: $p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $name 0 0 [ pg_result $result -list ]"
pg_result $result -clear
	}
}
#ORDER_STATUS
proc ostat { lda w_id RAISEERROR ora_compatible } {
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
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec ostat($w_id,$d_id,$c_id,$byname,'$name')" ]
} else {
set result [pg_exec $lda "select * from ostat($w_id,$d_id,$c_id,$byname,'$name') as (ol_i_id NUMERIC,  ol_supply_w_id NUMERIC, ol_quantity NUMERIC, ol_amount NUMERIC, ol_delivery_d TIMESTAMP,  out_os_c_id INTEGER, out_os_c_last VARCHAR, os_c_first VARCHAR, os_c_middle VARCHAR, os_c_balance NUMERIC, os_o_id INTEGER, os_entdate TIMESTAMP, os_o_carrier_id INTEGER)" ]
}
if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Order Status Procedure Error set RAISEERROR for Details"
		}
	} else {
puts "Order Status: $w_id $d_id $c_id $byname $name [ pg_result $result -list ]"
pg_result $result -clear
	}
}
#DELIVERY
proc delivery { lda w_id RAISEERROR ora_compatible } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec delivery($w_id,$carrier_id,TO_TIMESTAMP($date,'YYYYMMDDHH24MISS'))" ]
} else {
set result [pg_exec $lda "select delivery($w_id,$carrier_id)" ]
}
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Delivery Procedure Error set RAISEERROR for Details"
		}
	} else {
puts "Delivery: $w_id $carrier_id [ pg_result $result -list ]"
pg_result $result -clear
	}
}
#STOCK LEVEL
proc slev { lda w_id stock_level_d_id RAISEERROR ora_compatible } {
set threshold [ RandomNumber 10 20 ]
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec slev($w_id,$stock_level_d_id,$threshold)" ]
} else {
set result [pg_exec $lda "select slev($w_id,$stock_level_d_id,$threshold)" ]
}
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Stock Level Procedure Error set RAISEERROR for Details"
		}
	} else {
puts "Stock Level: $w_id $stock_level_d_id $threshold [ pg_result $result -list ]"
pg_result $result -clear
	}
}
#RUN TPC-C
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 } else {
if { $ora_compatible eq "true" } {
set result [ pg_exec $lda "exec dbms_output.disable" ]
pg_result $result -clear
	}
 }
pg_select $lda "select max(w_id) from warehouse" w_id_input_arr {
set w_id_input $w_id_input_arr(max)
	}
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
pg_select $lda "select max(d_id) from district" d_id_input_arr {
set d_id_input $d_id_input_arr(max)
}
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword $lda $w_id $w_id_input $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment $lda $w_id $w_id_input $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery $lda $w_id $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev $lda $w_id $stock_level_d_id $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat $lda $w_id $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 5 }
	}
}
pg_disconnect $lda
	}
}

proc loadtimedpgtpcc { } {
global pg_host pg_port pg_superuser pg_superuserpass pg_defaultdbase pg_user pg_pass pg_dbase pg_vacuum pg_dritasnap pg_oracompat pg_total_iterations pg_raiseerror pg_keyandthink pg_rampup pg_duration opmode _ED
if {  ![ info exists pg_host ] } { set pg_host "localhost" }
if {  ![ info exists pg_port ] } { set pg_port "5432" }
if {  ![ info exists pg_superuser ] } { set pg_superuser "postgres" }
if {  ![ info exists pg_superuserpass ] } { set pg_superuserpass "postgres" }
if {  ![ info exists pg_defaultdbase ] } { set pg_defaultdbase "postgres" }
if {  ![ info exists pg_user ] } { set pg_user "tpcc" }
if {  ![ info exists pg_pass ] } { set pg_pass "tpcc" }
if {  ![ info exists pg_dbase ] } { set pg_dbase "tpcc" }
if {  ![ info exists pg_vacuum ] } { set pg_vacuum "false" }
if {  ![ info exists pg_dritasnap ] } { set pg_dritasnap "false" }
if {  ![ info exists pg_oracompat ] } { set pg_oracompat "false" }
if {  ![ info exists pg_total_iterations ] } { set pg_total_iterations 1000000 }
if {  ![ info exists pg_raiseerror ] } { set pg_raiseerror "false" }
if {  ![ info exists pg_keyandthink ] } { set pg_keyandthink "false" }
if {  ![ info exists pg_rampup ] } { set pg_rampup "2" }
if {  ![ info exists pg_duration ] } { set pg_duration "5" }
if {  ![ info exists opmode ] } { set opmode "Local" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require Pgtcl} \] { error \"Failed to load Pgtcl - Postgres Library Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $pg_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$pg_raiseerror\" ;# Exit script on PostgreSQL (true or false)
set KEYANDTHINK \"$pg_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $pg_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $pg_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set VACUUM \"$pg_vacuum\" ;# Perform checkpoint and vacuuum when complete (true or false)
set DRITA_SNAPSHOTS \"$pg_dritasnap\";#Take DRITA Snapshots
set ora_compatible \"$pg_oracompat\" ;#Postgres Plus Oracle Compatible Schema
set host \"$pg_host\" ;# Address of the server hosting PostgreSQL
set port \"$pg_port\" ;# Port of the PostgreSQL server
set superuser \"$pg_superuser\" ;# Superuser privilege user
set superuser_password \"$pg_superuserpass\" ;# Password for Superuser
set default_database \"$pg_defaultdbase\" ;# Default Database for Superuser
set user \"$pg_user\" ;# PostgreSQL user
set password \"$pg_pass\" ;# Password for the PostgreSQL user
set db \"$pg_dbase\" ;# Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 22.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#CHECK THREAD STATUS
proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }
if { [ chk_thread ] eq "FALSE" } {
error "PostgreSQL Timed Test Script must be run in Thread Enabled Interpreter"
}

proc ConnectToPostgres { host port user password dbname } {
global tcl_platform
if {[catch {set lda [pg_connect -conninfo [list host = $host port = $port user = $user password = $password dbname = $dbname ]]}]} {
puts stderr "Error, the database connection to $host could not be established"
set lda "Failed"
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
if { $mode eq "Local" || $mode eq "Master" } {
if { ($DRITA_SNAPSHOTS eq "true") || ($VACUUM eq "true") } {
set lda [ ConnectToPostgres $host $port $superuser $superuser_password $default_database ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 	} 
}
set lda1 [ ConnectToPostgres $host $port $user $password $db ]
if { $lda1 eq "Failed" } {
error "error, the database connection to $host could not be established"
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
if { $DRITA_SNAPSHOTS eq "true" } {
puts "Rampup complete, Taking start DRITA snapshot."
set result [pg_exec $lda "select * from edbsnap()" ]
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "DRITA Snapshot Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
pg_select $lda {select edb_id,snap_tm from edb$snap order by edb_id desc limit 1} snap_arr {
set firstsnap $snap_arr(edb_id)
set first_snaptime $snap_arr(snap_tm)
	}
puts "Start Snapshot $firstsnap taken at $first_snaptime"
	}
   } else {
puts "Rampup complete, Taking start Transaction Count."
	}
pg_select $lda1 "select sum(xact_commit + xact_rollback) from pg_stat_database" tx_arr {
set start_trans $tx_arr(sum)
	}
pg_select $lda1 "select sum(d_next_o_id) from district" o_id_arr {
set start_nopm $o_id_arr(sum)
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
if { $DRITA_SNAPSHOTS eq "true" } {
puts "Test complete, Taking end DRITA snapshot."
set result [pg_exec $lda "select * from edbsnap()" ]
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Snapshot Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
pg_select $lda {select edb_id,snap_tm from edb$snap order by edb_id desc limit 1} snap_arr  {
set endsnap $snap_arr(edb_id)
set end_snaptime $snap_arr(snap_tm)
	}
puts "End Snapshot $endsnap taken at $end_snaptime"
puts "Test complete: view DRITA report from SNAPID $firstsnap to $endsnap"
	}
   } else {
puts "Test complete, Taking end Transaction Count."
	}
pg_select $lda1 "select sum(xact_commit + xact_rollback) from pg_stat_database" tx_arr {
set end_trans $tx_arr(sum)
	}
pg_select $lda1 "select sum(d_next_o_id) from district" o_id_arr {
set end_nopm $o_id_arr(sum)
	}
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm PostgreSQL TPM at $nopm NOPM"
tsv::set application abort 1
if { $VACUUM } {
	set RAISEERROR "true"
puts "Checkpoint and Vacuum"
set result [pg_exec $lda "checkpoint" ]
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Checkpoint Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
	}
set result [pg_exec $lda "vacuum" ]
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Vacuum Error set RAISEERROR for Details"
		}
	} else {
puts "Checkpoint and Vacuum Complete"
pg_result $result -clear
	}
}
if { ($DRITA_SNAPSHOTS eq "true") || ($VACUUM eq "true") } {
pg_disconnect $lda
	}
pg_disconnect $lda1
		} else {
puts "Operating in Slave Mode, No Snapshots taken..."
		}
	}
default {
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#NEW ORDER
proc neword { lda no_w_id w_id_input RAISEERROR ora_compatible } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec neword($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,0,TO_TIMESTAMP($date,'YYYYMMDDHH24MISS'))" ]
} else {
set result [pg_exec $lda "select neword($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,0)" ]
}
if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "New Order Procedure Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
	}
}
#PAYMENT
proc payment { lda p_w_id w_id_input RAISEERROR ora_compatible } {
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
#change following to correct values
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec payment($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,$p_c_id,$byname,$p_h_amount,'$name','0',0,TO_TIMESTAMP($h_date,'YYYYMMDDHH24MISS'))" ]
} else {
set result [pg_exec $lda "select payment($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,$p_c_id,$byname,$p_h_amount,'$name','0',0)" ]
}
if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Payment Procedure Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
	}
}
#ORDER_STATUS
proc ostat { lda w_id RAISEERROR ora_compatible } {
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
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec ostat($w_id,$d_id,$c_id,$byname,'$name')" ]
} else {
set result [pg_exec $lda "select * from ostat($w_id,$d_id,$c_id,$byname,'$name') as (ol_i_id NUMERIC,  ol_supply_w_id NUMERIC, ol_quantity NUMERIC, ol_amount NUMERIC, ol_delivery_d TIMESTAMP,  out_os_c_id INTEGER, out_os_c_last VARCHAR, os_c_first VARCHAR, os_c_middle VARCHAR, os_c_balance NUMERIC, os_o_id INTEGER, os_entdate TIMESTAMP, os_o_carrier_id INTEGER)" ]
}
if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Order Status Procedure Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
	}
}
#DELIVERY
proc delivery { lda w_id RAISEERROR ora_compatible } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec delivery($w_id,$carrier_id,TO_TIMESTAMP($date,'YYYYMMDDHH24MISS'))" ]
} else {
set result [pg_exec $lda "select delivery($w_id,$carrier_id)" ]
}
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Delivery Procedure Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
	}
}
#STOCK LEVEL
proc slev { lda w_id stock_level_d_id RAISEERROR ora_compatible } {
set threshold [ RandomNumber 10 20 ]
if { $ora_compatible eq "true" } {
set result [pg_exec $lda "exec slev($w_id,$stock_level_d_id,$threshold)" ]
} else {
set result [pg_exec $lda "select slev($w_id,$stock_level_d_id,$threshold)" ]
}
if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
if { $RAISEERROR } {
error "[pg_result $result -error]"
		} else {
puts "Stock Level Procedure Error set RAISEERROR for Details"
		}
	} else {
pg_result $result -clear
	}
}
#RUN TPC-C
set lda [ ConnectToPostgres $host $port $user $password $db ]
if { $lda eq "Failed" } {
error "error, the database connection to $host could not be established"
 } else {
if { $ora_compatible eq "true" } {
set result [ pg_exec $lda "exec dbms_output.disable" ]
pg_result $result -clear
	}
 }
pg_select $lda "select max(w_id) from warehouse" w_id_input_arr {
set w_id_input $w_id_input_arr(max)
	}
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
pg_select $lda "select max(d_id) from district" d_id_input_arr {
set d_id_input $d_id_input_arr(max)
}
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword $lda $w_id $w_id_input $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment $lda $w_id $w_id_input $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery $lda $w_id $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev $lda $w_id $stock_level_d_id $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat $lda $w_id $RAISEERROR $ora_compatible
if { $KEYANDTHINK } { thinktime 5 }
	}
}
pg_disconnect $lda
		}
	}
    }
}

proc check_redistpcc { } {
global redis_host redis_port redis_namespace redis_count_ware redis_num_threads maxvuser suppo ntimes threadscreated _ED
if {  ![ info exists redis_host ] } { set redis_host "127.0.0.1" }
if {  ![ info exists redis_port ] } { set redis_port "6379" }
if {  ![ info exists redis_namespace ] } { set redis_namespace "1" }
if {  ![ info exists redis_count_ware ] } { set redis_count_ware "1" }
if {  ![ info exists redis_num_threads ] } { set redis_num_threads "1" }
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a $redis_count_ware Warehouse Redis TPC-C schema\nin host [string toupper $redis_host:$redis_port] in namespace $redis_namespace?" -type yesno ] == yes} { 
if { $redis_num_threads eq 1 || $redis_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $redis_num_threads + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to created thread for schema creation: $message"
	return
	}
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#!/usr/local/bin/tclsh8.6
if [catch {package require redis} ] { error "Failed to load Redis - Redis Package Error" }
proc chk_thread {} {
        set chk [package provide Thread]
        if {[string length $chk]} {
            return "TRUE"
            } else {
            return "FALSE"
        }
    }

proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
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

proc do_tpcc { host port namespace count_ware num_threads } {
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
incr mtcnt
if {  [ tsv::get application load ] eq "READY" } { break }
if { $mtcnt eq 48 } {
puts "Monitor failed to notify ready state"
return
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
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 429.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "do_tpcc $redis_host $redis_port $redis_namespace $redis_count_ware $redis_num_threads"
	} else { return }
}

proc loadredistpcc {} {
global redis_host redis_port redis_namespace redis_total_iterations redis_raiseerror redis_keyandthink redis_driver _ED
if {  ![ info exists redis_host ] } { set redis_host "127.0.0.1" }
if {  ![ info exists redis_port ] } { set redis_port "6379" }
if {  ![ info exists redis_namespace ] } { set redis_namespace "1" }
if {  ![ info exists redis_total_iterations ] } { set redis_total_iterations 1000000 }
if {  ![ info exists redis_raiseerror ] } { set redis_raiseerror "false" }
if {  ![ info exists redis_keyandthink ] } { set redis_keyandthink "false" }
if {  ![ info exists redis_driver ] } { set redis_driver "standard" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require redis} \] { error \"Failed to load Redis - Redis Package Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $redis_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$redis_raiseerror\" ;# Exit script on Redis error (true or false)
set KEYANDTHINK \"$redis_keyandthink\" ;# Time for user thinking and keying (true or false)
set host \"$redis_host\" ;# Address of the server hosting Redis 
set port \"$redis_port\" ;# Port of the Redis Server, defaults to 6379
set namespace \"$redis_namespace\" ;# Namespace containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 11.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
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
$redis QUIT
	}
}

proc loadtimedredistpcc {} {
global redis_host redis_port redis_namespace redis_total_iterations redis_raiseerror redis_keyandthink redis_driver redis_rampup redis_duration opmode _ED
if {  ![ info exists redis_host ] } { set redis_host "127.0.0.1" }
if {  ![ info exists redis_port ] } { set redis_port "6379" }
if {  ![ info exists redis_namespace ] } { set redis_namespace "1" }
if {  ![ info exists redis_total_iterations ] } { set redis_total_iterations 1000000 }
if {  ![ info exists redis_raiseerror ] } { set redis_raiseerror "false" }
if {  ![ info exists redis_keyandthink ] } { set redis_keyandthink "false" }
if {  ![ info exists redis_driver ] } { set redis_driver "standard" }
if {  ![ info exists redis_rampup ] } { set redis_rampup "2" }
if {  ![ info exists redis_duration ] } { set redis_duration "5" }
if {  ![ info exists opmode ] } { set opmode "Local" }
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "TPC-C"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act "#!/usr/local/bin/tclsh8.6
if \[catch {package require redis} \] { error \"Failed to load Redis - Redis Package Error\" }
#EDITABLE OPTIONS##################################################
set total_iterations $redis_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$redis_raiseerror\" ;# Exit script on Redis error (true or false)
set KEYANDTHINK \"$redis_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $redis_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $redis_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# Hammerora operational mode
set host \"$redis_host\" ;# Address of the server hosting Redis 
set port \"$redis_port\" ;# Port of the Redis Server, defaults to 6379
set namespace \"$redis_namespace\" ;# Namespace containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
set act [ .ed_mainFrame.mainwin.textFrame.left.text index 14.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $act {proc chk_thread {} {
	set chk [package provide Thread]
	if {[string length $chk]} {
	    return "TRUE"
	    } else {
	    return "FALSE"
	}
    }
if { [ chk_thread ] eq "FALSE" } {
error "Redis Timed Test Script must be run in Thread Enabled Interpreter"
}
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
if { $mode eq "Local" || $mode eq "Master" } {
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
puts "$totalvirtualusers Virtual Users configured"
puts "TEST RESULT : System achieved $tpm Redis TPM at $nopm NOPM"
tsv::set application abort 1
catch { mysqlclose $mysql_handler }
		} else {
puts "Operating in Slave Mode, No Snapshots taken..."
		}
	}
default {
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NURand function
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
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
    }
}
$redis QUIT
	}
}
