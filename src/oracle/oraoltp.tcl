proc build_oratpcc {} {
global maxvuser suppo ntimes threadscreated _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict oracle library ]} {
set library [ dict get $dbdict oracle library ]
} else { set library "Oratcl" } 
upvar #0 configoracle configoracle
setlocaltpccvars $configoracle
if { $tpcc_tt_compat eq "true" } {
set install_message "Ready to create a $count_ware Warehouse TimesTen TPROC-C schema\nin the existing database [string toupper $instance] under existing user [ string toupper $tpcc_user ]?" 
	} else {
set install_message "Ready to create a $count_ware Warehouse Oracle TPROC-C schema\nin database [string toupper $instance] under user [ string toupper $tpcc_user ] in tablespace [ string toupper $tpcc_def_tab]?" 
	}
if {[ tk_messageBox -title "Create Schema" -icon question -message $install_message -type yesno ] == yes} { 
if { $num_vu eq 1 || $count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $num_vu + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "TPROC-C creation"
if { [catch {load_virtual} message]} {
puts "Failed to create thread(s) for schema creation: $message"
	return 1
	}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#LOAD LIBRARIES AND MODULES
set library $library
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }
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
no_w_id		BINARY_INTEGER,
no_max_w_id		BINARY_INTEGER,
no_d_id		    BINARY_INTEGER,
no_c_id		    BINARY_INTEGER,
no_o_ol_cnt		BINARY_INTEGER,
no_c_discount	OUT NUMBER,
no_c_last		OUT VARCHAR2,
no_c_credit		OUT VARCHAR2,
no_d_tax		OUT NUMBER,
no_w_tax		OUT NUMBER,
no_d_next_o_id	OUT BINARY_INTEGER,
timestamp		IN DATE )
IS
order_amount        NUMBER;
no_o_all_local		BINARY_INTEGER;
loop_counter        BINARY_INTEGER;
not_serializable		EXCEPTION;
PRAGMA EXCEPTION_INIT(not_serializable,-8177);
deadlock			EXCEPTION;
PRAGMA EXCEPTION_INIT(deadlock,-60);
snapshot_too_old		EXCEPTION;
PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
integrity_viol			EXCEPTION;
PRAGMA EXCEPTION_INIT(integrity_viol,-1);
TYPE intarray IS TABLE OF INTEGER index by binary_integer;
TYPE numarray IS TABLE OF NUMBER index by binary_integer;
TYPE distarray IS TABLE OF VARCHAR(24) index by binary_integer;
o_id_array intarray;
w_id_array intarray;
o_quantity_array intarray;
s_quantity_array intarray;
ol_line_number_array intarray;
amount_array numarray;
district_info distarray;
BEGIN
    SELECT c_discount, c_last, c_credit, w_tax
      INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
      FROM customer, warehouse
     WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND customer.c_d_id = no_d_id AND customer.c_id = no_c_id;

    --#2.4.1.5
    no_o_all_local := 1;
    FOR loop_counter IN 1 .. no_o_ol_cnt
    LOOP
        o_id_array(loop_counter) := round(DBMS_RANDOM.value(low => 1, high => 100000));

        --#2.4.1.5.2
        IF ( DBMS_RANDOM.value >= 0.01 )
        THEN
            w_id_array(loop_counter) := no_w_id;
        ELSE
            no_o_all_local := 0;
            w_id_array(loop_counter) := 1 + mod(no_w_id + round(DBMS_RANDOM.value(low => 0, high => no_max_w_id-1)),no_max_w_id);
        END IF;

        --#2.4.1.5.3
        o_quantity_array(loop_counter) := round(DBMS_RANDOM.value(low => 1, high => 10));

        -- Take advantage of the fact that I'm looping to populate the array used to record order lines at the end
        ol_line_number_array(loop_counter) := loop_counter;
    END LOOP;

    UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = no_d_id AND d_w_id = no_w_id RETURNING d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax;

    INSERT INTO ORDERS (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (no_d_next_o_id, no_d_id, no_w_id, no_c_id, timestamp, no_o_ol_cnt, no_o_all_local);
    INSERT INTO NEW_ORDER (no_o_id, no_d_id, no_w_id) VALUES (no_d_next_o_id, no_d_id, no_w_id);

    -- The HammerDB implementation doesn't do the check for ORIGINAL (which should be done against i_data and s_data)
    IF no_d_id = 1 THEN
        FORALL i IN 1 .. no_o_ol_cnt
            UPDATE stock_item
               SET s_quantity = (CASE WHEN s_quantity < ( o_quantity_array(i) + 10 ) THEN s_quantity + 91 ELSE s_quantity END) - o_quantity_array(i)
             WHERE i_id = o_id_array(i)
               AND s_w_id = w_id_array(i)
               AND i_id = o_id_array(i)
            RETURNING s_dist_01, s_quantity, i_price * o_quantity_array(i) BULK COLLECT INTO district_info, s_quantity_array, amount_array;
    ELSIF no_d_id = 2 THEN
        FORALL i IN 1 .. no_o_ol_cnt
            UPDATE stock_item
               SET s_quantity = (CASE WHEN s_quantity < ( o_quantity_array(i) + 10 ) THEN s_quantity + 91 ELSE s_quantity END) - o_quantity_array(i)
             WHERE i_id = o_id_array(i)
               AND s_w_id = w_id_array(i)
               AND i_id = o_id_array(i)
            RETURNING s_dist_02, s_quantity, i_price * o_quantity_array(i) BULK COLLECT INTO district_info, s_quantity_array,amount_array;
    ELSIF no_d_id = 3 THEN
        FORALL i IN 1 .. no_o_ol_cnt
            UPDATE stock_item
               SET s_quantity = (CASE WHEN s_quantity < ( o_quantity_array(i) + 10 ) THEN s_quantity + 91 ELSE s_quantity END) - o_quantity_array(i)
             WHERE i_id = o_id_array(i)
               AND s_w_id = w_id_array(i)
               AND i_id = o_id_array(i)
            RETURNING s_dist_03, s_quantity, i_price * o_quantity_array(i) BULK COLLECT INTO district_info, s_quantity_array,amount_array;
    ELSIF no_d_id = 4 THEN
        FORALL i IN 1 .. no_o_ol_cnt
            UPDATE stock_item
               SET s_quantity = (CASE WHEN s_quantity < ( o_quantity_array(i) + 10 ) THEN s_quantity + 91 ELSE s_quantity END) - o_quantity_array(i)
             WHERE i_id = o_id_array(i)
               AND s_w_id = w_id_array(i)
               AND i_id = o_id_array(i)
            RETURNING s_dist_04, s_quantity, i_price * o_quantity_array(i) BULK COLLECT INTO district_info, s_quantity_array,amount_array;
    ELSIF no_d_id = 5 THEN
        FORALL i IN 1 .. no_o_ol_cnt
            UPDATE stock_item
               SET s_quantity = (CASE WHEN s_quantity < ( o_quantity_array(i) + 10 ) THEN s_quantity + 91 ELSE s_quantity END) - o_quantity_array(i)
             WHERE i_id = o_id_array(i)
               AND s_w_id = w_id_array(i)
               AND i_id = o_id_array(i)
            RETURNING s_dist_05, s_quantity, i_price * o_quantity_array(i) BULK COLLECT INTO district_info, s_quantity_array,amount_array;
    ELSIF no_d_id = 6 THEN
        FORALL i IN 1 .. no_o_ol_cnt
            UPDATE stock_item
               SET s_quantity = (CASE WHEN s_quantity < ( o_quantity_array(i) + 10 ) THEN s_quantity + 91 ELSE s_quantity END) - o_quantity_array(i)
             WHERE i_id = o_id_array(i)
               AND s_w_id = w_id_array(i)
               AND i_id = o_id_array(i)
            RETURNING s_dist_06, s_quantity, i_price * o_quantity_array(i) BULK COLLECT INTO district_info, s_quantity_array,amount_array;
    ELSIF no_d_id = 7 THEN
        FORALL i IN 1 .. no_o_ol_cnt
            UPDATE stock_item
               SET s_quantity = (CASE WHEN s_quantity < ( o_quantity_array(i) + 10 ) THEN s_quantity + 91 ELSE s_quantity END) - o_quantity_array(i)
             WHERE i_id = o_id_array(i)
               AND s_w_id = w_id_array(i)
               AND i_id = o_id_array(i)
            RETURNING s_dist_07, s_quantity, i_price * o_quantity_array(i) BULK COLLECT INTO district_info, s_quantity_array,amount_array;
    ELSIF no_d_id = 8 THEN
        FORALL i IN 1 .. no_o_ol_cnt
            UPDATE stock_item
               SET s_quantity = (CASE WHEN s_quantity < ( o_quantity_array(i) + 10 ) THEN s_quantity + 91 ELSE s_quantity END) - o_quantity_array(i)
             WHERE i_id = o_id_array(i)
               AND s_w_id = w_id_array(i)
               AND i_id = o_id_array(i)
            RETURNING s_dist_08, s_quantity, i_price * o_quantity_array(i) BULK COLLECT INTO district_info, s_quantity_array,amount_array;
    ELSIF no_d_id = 9 THEN
        FORALL i IN 1 .. no_o_ol_cnt
            UPDATE stock_item
               SET s_quantity = (CASE WHEN s_quantity < ( o_quantity_array(i) + 10 ) THEN s_quantity + 91 ELSE s_quantity END) - o_quantity_array(i)
             WHERE i_id = o_id_array(i)
               AND s_w_id = w_id_array(i)
               AND i_id = o_id_array(i)
            RETURNING s_dist_09, s_quantity, i_price * o_quantity_array(i) BULK COLLECT INTO district_info, s_quantity_array,amount_array;
    ELSIF no_d_id = 10 THEN
        FORALL i IN 1 .. no_o_ol_cnt
            UPDATE stock_item
               SET s_quantity = (CASE WHEN s_quantity < ( o_quantity_array(i) + 10 ) THEN s_quantity + 91 ELSE s_quantity END) - o_quantity_array(i)
             WHERE i_id = o_id_array(i)
               AND s_w_id = w_id_array(i)
               AND i_id = o_id_array(i)
            RETURNING s_dist_10, s_quantity, i_price * o_quantity_array(i) BULK COLLECT INTO district_info, s_quantity_array,amount_array;
    END IF;

    -- Oracle return the TAX information to the client, presumably to do the calculation there.  HammerDB doesn't return it at all so I'll just calculate it here and do nothing with it
    order_amount := 0;
    FOR loop_counter IN 1 .. no_o_ol_cnt
    LOOP
        order_amount := order_amount + ( amount_array(loop_counter) );
    END LOOP;
    order_amount := order_amount * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount );

    FORALL i IN 1 .. no_o_ol_cnt
        INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
        VALUES (no_d_next_o_id, no_d_id, no_w_id, ol_line_number_array(i), o_id_array(i), w_id_array(i), o_quantity_array(i), amount_array(i), district_info(i));

    -- Rollback 1% of transactions
    IF DBMS_RANDOM.value < 0.01 THEN
        dbms_output.put_line('Rolling back');
        ROLLBACK;
    ELSE
        COMMIT;
    END IF;

    EXCEPTION
    WHEN not_serializable OR deadlock OR snapshot_too_old OR integrity_viol --OR no_data_found
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
    d_o_carrier_id	INTEGER,
    timestamp		DATE
)
IS
    TYPE intarray IS TABLE OF INTEGER index by binary_integer;
    dist_id_in_array    intarray;
    dist_id_array       intarray;
    o_id_array          intarray;
    order_c_id          intarray;
    sums                intarray;
    ordcnt              INTEGER;

    not_serializable		EXCEPTION;
    PRAGMA EXCEPTION_INIT(not_serializable,-8177);
    deadlock			EXCEPTION;
    PRAGMA EXCEPTION_INIT(deadlock,-60);
    snapshot_too_old		EXCEPTION;
    PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
    FOR i in 1 .. 10 LOOP
        dist_id_in_array(i) := i;
    END LOOP;

    FORALL d IN 1..10
        DELETE
         FROM new_order
        WHERE no_d_id = dist_id_in_array(d)
          AND no_w_id = d_w_id
          AND no_o_id = (select min (no_o_id)
                           from new_order
                          where no_d_id = dist_id_in_array(d)
                            and no_w_id = d_w_id)
        RETURNING no_d_id, no_o_id BULK COLLECT INTO dist_id_array, o_id_array;

    ordcnt := SQL%ROWCOUNT;

    FORALL o in 1.. ordcnt
        UPDATE orders
           SET o_carrier_id = d_o_carrier_id
         WHERE o_id = o_id_array (o)
          AND o_d_id = dist_id_array(o)
          AND o_w_id = d_w_id
        RETURNING o_c_id BULK COLLECT INTO order_c_id;

    FORALL o in 1.. ordcnt
        UPDATE order_line
           SET ol_delivery_d = timestamp
         WHERE ol_w_id = d_w_id
          AND ol_d_id = dist_id_array(o)
          AND ol_o_id = o_id_array (o)
        RETURNING sum(ol_amount) BULK COLLECT INTO sums;

    FORALL c IN 1.. ordcnt
        UPDATE customer
           SET c_balance = c_balance + sums(c)
             -- Added this in for the refactor but it's not in the original (although it should be) so I've removed it, to be true to the original
             --, c_delivery_cnt = c_delivery_cnt + 1
         WHERE c_w_id = d_w_id
           AND c_d_id = dist_id_array(c)
           AND c_id = order_c_id(c);

    COMMIT;

    EXCEPTION
        WHEN not_serializable OR deadlock OR snapshot_too_old THEN
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
    p_w_street_1	OUT VARCHAR2,
    p_w_street_2	OUT VARCHAR2,
    p_w_city		OUT VARCHAR2,
    p_w_state		OUT VARCHAR2,
    p_w_zip			OUT VARCHAR2,
    p_d_street_1	OUT VARCHAR2,
    p_d_street_2	OUT VARCHAR2,
    p_d_city		OUT VARCHAR2,
    p_d_state		OUT VARCHAR2,
    p_d_zip			OUT VARCHAR2,
    p_c_first		OUT VARCHAR2,
    p_c_middle		OUT VARCHAR2,
    p_c_street_1	OUT VARCHAR2,
    p_c_street_2	OUT VARCHAR2,
    p_c_city		OUT VARCHAR2,
    p_c_state		OUT VARCHAR2,
    p_c_zip			OUT VARCHAR2,
    p_c_phone		OUT VARCHAR2,
    p_c_since		OUT DATE,
    p_c_credit		IN OUT VARCHAR2,
    p_c_credit_lim	OUT NUMBER,
    p_c_discount	OUT NUMBER,
    p_c_balance		IN OUT NUMBER,
    p_c_data		OUT VARCHAR2,
    timestamp		IN DATE
)
IS
    p_d_name		VARCHAR2(11);
    p_w_name		VARCHAR2(11);
    p_c_new_data	VARCHAR2(500);
    h_data			VARCHAR2(30);

    TYPE rowidarray IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    cust_rowid ROWID;
    row_id rowidarray;
    c_num BINARY_INTEGER;

    CURSOR c_byname IS
    SELECT rowid
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
    IF ( byname = 1 )
    THEN
        c_num := 0;
        FOR c_id_rec IN c_byname LOOP
            c_num := c_num + 1;
            row_id(c_num) := c_id_rec.rowid;
        END LOOP;
        cust_rowid := row_id ((c_num + 1) / 2);

        UPDATE customer
        SET c_balance = c_balance - p_h_amount
            --c_ytd_payment = c_ytd_payment + hist_amount,
            --c_payment_cnt = c_payment_cnt + 1
        WHERE rowid = cust_rowid
        RETURNING c_id, c_first, c_middle, c_last, c_street_1, c_street_2,
                  c_city, c_state, c_zip, c_phone,
                  c_since, c_credit, c_credit_lim,
                  c_discount, c_balance
        INTO p_c_id, p_c_first, p_c_middle, p_c_last, p_c_street_1, p_c_street_2,
             p_c_city, p_c_state, p_c_zip, p_c_phone,
             p_c_since, p_c_credit, p_c_credit_lim,
             p_c_discount, p_c_balance;
    ELSE
        UPDATE customer
           SET c_balance = c_balance - p_h_amount
               --c_ytd_payment = c_ytd_payment + hist_amount,
               --c_payment_cnt = c_payment_cnt + 1
        WHERE c_id = p_c_id AND c_d_id = p_c_d_id AND c_w_id = p_c_w_id
        RETURNING rowid, c_first, c_middle, c_last, c_street_1, c_street_2,
                  c_city, c_state, c_zip, c_phone,
                  c_since, c_credit, c_credit_lim,
                  c_discount, c_balance
        INTO cust_rowid, p_c_first, p_c_middle, p_c_last, p_c_street_1, p_c_street_2,
             p_c_city, p_c_state, p_c_zip, p_c_phone,
             p_c_since, p_c_credit, p_c_credit_lim,
             p_c_discount, p_c_balance;
    END IF;

    IF p_c_credit = 'BC' THEN
        UPDATE customer
           SET c_data = substr ((to_char (p_c_id) || ' ' ||
                                 to_char (p_c_d_id) || ' ' ||
                                 to_char (p_c_w_id) || ' ' ||
                                 to_char (p_d_id) || ' ' ||
                                 to_char (p_w_id) || ' ' ||
                                 to_char (p_h_amount, '9999.99') || ' | ') || c_data, 1, 500)
         WHERE rowid = cust_rowid
        RETURNING substr (c_data, 1, 200) INTO p_c_data;
    ELSE
        p_c_data := ' ';
    END IF;

    UPDATE district
      SET d_ytd = d_ytd + p_h_amount
     WHERE d_id = p_d_id
       AND d_w_id = p_w_id
    RETURNING d_name, d_street_1, d_street_2, d_city,d_state, d_zip
    INTO p_d_name, p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip;

    UPDATE warehouse
       SET w_ytd = w_ytd + p_h_amount
     WHERE w_id = p_w_id
    RETURNING w_name, w_street_1, w_street_2, w_city, w_state, w_zip
    INTO p_w_name, p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip;

    INSERT INTO history
    (h_c_id, h_c_d_id, h_c_w_id, h_d_id, h_w_id, h_date,h_amount,h_data)
    VALUES
    (p_c_id, p_c_d_id, p_c_w_id, p_d_id, p_w_id, timestamp, p_h_amount, p_w_name || ' ' || p_d_name);

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
    os_o_carrier_id		OUT INTEGER
)
IS
    TYPE rowidarray IS TABLE OF ROWID INDEX BY BINARY_INTEGER;
    cust_rowid ROWID;
    row_id rowidarray;
    c_num BINARY_INTEGER;

    CURSOR c_byname
    IS
    SELECT rowid
      FROM customer
     WHERE c_w_id = os_w_id AND c_d_id = os_d_id AND c_last = os_c_last
    ORDER BY c_first;

    i			BINARY_INTEGER;
    CURSOR c_line IS
    SELECT ol_i_id, ol_supply_w_id, ol_quantity,
           ol_amount, ol_delivery_d
      FROM order_line
     WHERE ol_o_id = os_o_id AND ol_d_id = os_d_id AND ol_w_id = os_w_id;


    TYPE intarray IS TABLE OF INTEGER index by binary_integer;
    os_ol_i_id intarray;
    os_ol_supply_w_id intarray;
    os_ol_quantity intarray;

    TYPE datetable IS TABLE OF DATE INDEX BY BINARY_INTEGER;
    os_ol_delivery_d datetable;

    TYPE numarray IS TABLE OF NUMBER index by binary_integer;
    os_ol_amount numarray;

    not_serializable		EXCEPTION;
    PRAGMA EXCEPTION_INIT(not_serializable,-8177);
    deadlock			EXCEPTION;
    PRAGMA EXCEPTION_INIT(deadlock,-60);
    snapshot_too_old		EXCEPTION;
    PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
    IF ( byname = 1 )
    THEN
        c_num := 0;
        FOR c_id_rec IN c_byname LOOP
            c_num := c_num + 1;
            row_id(c_num) := c_id_rec.rowid;
        END LOOP;
        cust_rowid := row_id ((c_num + 1) / 2);

        SELECT c_balance, c_first, c_middle, c_last, c_id
          INTO os_c_balance, os_c_first, os_c_middle, os_c_last, os_c_id
         FROM customer
        WHERE rowid = cust_rowid;
    ELSE
        SELECT c_balance, c_first, c_middle, c_last, rowid
          INTO os_c_balance, os_c_first, os_c_middle, os_c_last, cust_rowid
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
          FROM (SELECT o_id, o_carrier_id, o_entry_d
                  FROM orders
                 WHERE o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id=os_c_id
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
        i := i + 1;
    END LOOP;
    COMMIT;

    EXCEPTION WHEN not_serializable OR deadlock OR snapshot_too_old THEN
        ROLLBACK;
END; }
set sql(5) { CREATE OR REPLACE PROCEDURE SLEV (
    st_w_id			INTEGER,
    st_d_id			INTEGER,
    threshold		INTEGER,
    stock_count		OUT INTEGER
)
IS
    st_o_id			NUMBER;
    not_serializable		EXCEPTION;
    PRAGMA EXCEPTION_INIT(not_serializable,-8177);
    deadlock			EXCEPTION;
    PRAGMA EXCEPTION_INIT(deadlock,-60);
    snapshot_too_old		EXCEPTION;
    PRAGMA EXCEPTION_INIT(snapshot_too_old,-1555);
BEGIN
    SELECT COUNT(DISTINCT (s_i_id))
      INTO stock_count
      FROM order_line, stock, district
     WHERE d_id=st_d_id
       AND d_w_id=st_w_id
       AND d_id = ol_d_id
       AND d_w_id = ol_w_id
       AND ol_i_id = s_i_id
       AND ol_w_id = s_w_id
       AND s_quantity < threshold
       AND ol_o_id BETWEEN (d_next_o_id - 20) AND (d_next_o_id - 1);

    COMMIT;
EXCEPTION
    WHEN not_serializable OR deadlock OR snapshot_too_old THEN
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
set sql(2) "grant connect,resource,create view to $tpcc_user\n"
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

proc CreateTables { lda num_part tpcc_ol_tab timesten hash_clusters count_ware } {
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
set sql(10) "CREATE OR REPLACE VIEW TPCC.STOCK_ITEM (I_ID, S_W_ID, I_PRICE, I_NAME, I_DATA, S_DATA, S_QUANTITY, S_ORDER_CNT, S_YTD, S_REMOTE_CNT, S_DIST_01, S_DIST_02, S_DIST_03, S_DIST_04, S_DIST_05, S_DIST_06, S_DIST_07, S_DIST_08, S_DIST_09, S_DIST_10) AS SELECT /*+ LEADING(S) USE_NL(I) */ I.I_ID, S_W_ID, I.I_PRICE, I.I_NAME, I.I_DATA, S_DATA, S_QUANTITY, S_ORDER_CNT, S_YTD, S_REMOTE_CNT, S_DIST_01, S_DIST_02, S_DIST_03, S_DIST_04, S_DIST_05, S_DIST_06, S_DIST_07, S_DIST_08, S_DIST_09, S_DIST_10 FROM STOCK S, ITEM I WHERE I.I_ID = S.S_I_ID"
	} else {
if  { $hash_clusters } {
set blocksize 8000
while 1 { if { ![ expr {$count_ware % 100} ] } { break } else { incr count_ware } } 
set ware_hkeys $count_ware
set dist_hkeys [ expr {$ware_hkeys * 10} ]
set cust_hkeys [ expr {$count_ware * 30000} ]
set cust_mult [ expr {$cust_hkeys / 3000} ]
set stock_hkeys [ expr {$count_ware * 100000} ]
set stock_mult $count_ware
set sqlclust(1) "CREATE CLUSTER CUSTCLUSTER (C_ID NUMBER(5, 0), C_D_ID NUMBER(2, 0), C_W_ID NUMBER(6, 0)) SINGLE TABLE HASHKEYS $cust_hkeys hash is ((c_id * $cust_mult)+(c_w_id * 10) + c_d_id) size 650 INITRANS 4 PCTFREE 0"
set sqlclust(2) "CREATE CLUSTER DISTCLUSTER (D_W_ID NUMBER(6, 0), D_ID NUMBER(2, 0)) SINGLE TABLE HASHKEYS $dist_hkeys hash is ((d_w_id) * 10 + d_id) size $blocksize INITRANS 4 PCTFREE 0"
set sqlclust(3) "CREATE CLUSTER ITEMCLUSTER (I_ID NUMBER(6, 0)) SINGLE TABLE HASHKEYS 100000 hash is i_id size 120 INITRANS 4 PCTFREE 0"
set sqlclust(4) "CREATE CLUSTER WARECLUSTER (W_ID NUMBER(6, 0)) SINGLE TABLE HASHKEYS $ware_hkeys hash is w_id size $blocksize INITRANS 4 PCTFREE 0"
set sqlclust(5) "CREATE CLUSTER STOCKCLUSTER (S_I_ID NUMBER(6, 0), S_W_ID NUMBER(6, 0)) SINGLE TABLE HASHKEYS $stock_hkeys hash is (s_i_id * $stock_mult + s_w_id) size 350 INITRANS 4 PCTFREE 0"
set sql(1) "CREATE TABLE CUSTOMER (C_ID NUMBER(5, 0), C_D_ID NUMBER(2, 0), C_W_ID NUMBER(6, 0), C_FIRST VARCHAR2(16), C_MIDDLE CHAR(2), C_LAST VARCHAR2(16), C_STREET_1 VARCHAR2(20), C_STREET_2 VARCHAR2(20), C_CITY VARCHAR2(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE DATE, C_CREDIT CHAR(2), C_CREDIT_LIM NUMBER(12, 2), C_DISCOUNT NUMBER(4, 4), C_BALANCE NUMBER(12, 2), C_YTD_PAYMENT NUMBER(12, 2), C_PAYMENT_CNT NUMBER(8, 0), C_DELIVERY_CNT NUMBER(8, 0), C_DATA VARCHAR2(500)) CLUSTER CUSTCLUSTER (C_ID, C_D_ID, C_W_ID)"
set sql(2) "CREATE TABLE DISTRICT (D_ID NUMBER(2, 0), D_W_ID NUMBER(6, 0), D_YTD NUMBER(12, 2), D_TAX NUMBER(4, 4), D_NEXT_O_ID NUMBER, D_NAME VARCHAR2(10), D_STREET_1 VARCHAR2(20), D_STREET_2 VARCHAR2(20), D_CITY VARCHAR2(20), D_STATE CHAR(2), D_ZIP CHAR(9)) CLUSTER DISTCLUSTER (D_W_ID, D_ID)"
set sql(3) "CREATE TABLE HISTORY (H_C_ID NUMBER, H_C_D_ID NUMBER, H_C_W_ID NUMBER, H_D_ID NUMBER, H_W_ID NUMBER, H_DATE DATE, H_AMOUNT NUMBER(6, 2), H_DATA VARCHAR2(24)) INITRANS 4 PCTFREE 10 PARTITION BY HASH(H_W_ID) PARTITIONS $num_part"
set sql(4) "CREATE TABLE ITEM (I_ID NUMBER(6, 0), I_IM_ID NUMBER, I_NAME VARCHAR2(24), I_PRICE NUMBER(5, 2), I_DATA VARCHAR2(50)) CLUSTER ITEMCLUSTER(I_ID)"
set sql(5) "CREATE TABLE WAREHOUSE (W_ID NUMBER(6, 0), W_YTD NUMBER(12, 2), W_TAX NUMBER(4, 4), W_NAME VARCHAR2(10), W_STREET_1 VARCHAR2(20), W_STREET_2 VARCHAR2(20), W_CITY VARCHAR2(20), W_STATE CHAR(2), W_ZIP CHAR(9)) CLUSTER WARECLUSTER(W_ID)"
set sql(6) "CREATE TABLE STOCK (S_I_ID NUMBER(6, 0), S_W_ID NUMBER(6, 0), S_QUANTITY NUMBER(6, 0), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD NUMBER(10, 0), S_ORDER_CNT NUMBER(6, 0), S_REMOTE_CNT NUMBER(6, 0), S_DATA VARCHAR2(50)) CLUSTER STOCKCLUSTER(S_I_ID, S_W_ID)"
set sql(7) "CREATE TABLE NEW_ORDER (NO_W_ID NUMBER, NO_D_ID NUMBER, NO_O_ID NUMBER, CONSTRAINT INORD PRIMARY KEY (NO_W_ID, NO_D_ID, NO_O_ID) ENABLE) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 PCTFREE 10"
set sql(8) "CREATE TABLE ORDERS (O_ID NUMBER, O_W_ID NUMBER, O_D_ID NUMBER, O_C_ID NUMBER, O_CARRIER_ID NUMBER, O_OL_CNT NUMBER, O_ALL_LOCAL NUMBER, O_ENTRY_D DATE) INITRANS 4 PCTFREE 10 PARTITION BY HASH(O_W_ID) PARTITIONS $num_part"
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID NUMBER, OL_D_ID NUMBER, OL_O_ID NUMBER, OL_NUMBER NUMBER, OL_I_ID NUMBER, OL_DELIVERY_D DATE, OL_AMOUNT NUMBER, OL_SUPPLY_W_ID NUMBER, OL_QUANTITY NUMBER, OL_DIST_INFO CHAR(24), CONSTRAINT IORDL PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER) ENABLE) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 PCTFREE 10 PARTITION BY HASH(OL_W_ID) PARTITIONS $num_part TABLESPACE $tpcc_ol_tab"
set sql(10) "CREATE OR REPLACE VIEW STOCK_ITEM (I_ID, S_W_ID, I_PRICE, I_NAME, I_DATA, S_DATA, S_QUANTITY, S_ORDER_CNT, S_YTD, S_REMOTE_CNT, S_DIST_01, S_DIST_02, S_DIST_03, S_DIST_04, S_DIST_05, S_DIST_06, S_DIST_07, S_DIST_08, S_DIST_09, S_DIST_10) AS SELECT /*+ LEADING(S) USE_NL(I) */ I.I_ID, S_W_ID, I.I_PRICE, I.I_NAME, I.I_DATA, S_DATA, S_QUANTITY, S_ORDER_CNT, S_YTD, S_REMOTE_CNT, S_DIST_01, S_DIST_02, S_DIST_03, S_DIST_04, S_DIST_05, S_DIST_06, S_DIST_07, S_DIST_08, S_DIST_09, S_DIST_10 FROM STOCK S, ITEM I WHERE I.I_ID = S.S_I_ID"
	} else {
set sql(1) "CREATE TABLE CUSTOMER (C_ID NUMBER(5, 0), C_D_ID NUMBER(2, 0), C_W_ID NUMBER(6, 0), C_FIRST VARCHAR2(16), C_MIDDLE CHAR(2), C_LAST VARCHAR2(16), C_STREET_1 VARCHAR2(20), C_STREET_2 VARCHAR2(20), C_CITY VARCHAR2(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE DATE, C_CREDIT CHAR(2), C_CREDIT_LIM NUMBER(12, 2), C_DISCOUNT NUMBER(4, 4), C_BALANCE NUMBER(12, 2), C_YTD_PAYMENT NUMBER(12, 2), C_PAYMENT_CNT NUMBER(8, 0), C_DELIVERY_CNT NUMBER(8, 0), C_DATA VARCHAR2(500)) INITRANS 4 PCTFREE 10"
set sql(2) "CREATE TABLE DISTRICT (D_ID NUMBER(2, 0), D_W_ID NUMBER(6, 0), D_YTD NUMBER(12, 2), D_TAX NUMBER(4, 4), D_NEXT_O_ID NUMBER, D_NAME VARCHAR2(10), D_STREET_1 VARCHAR2(20), D_STREET_2 VARCHAR2(20), D_CITY VARCHAR2(20), D_STATE CHAR(2), D_ZIP CHAR(9)) INITRANS 4 PCTFREE 99 PCTUSED 1"
set sql(4) "CREATE TABLE ITEM (I_ID NUMBER(6, 0), I_IM_ID NUMBER, I_NAME VARCHAR2(24), I_PRICE NUMBER(5, 2), I_DATA VARCHAR2(50)) INITRANS 4 PCTFREE 10"
set sql(5) "CREATE TABLE WAREHOUSE (W_ID NUMBER(6, 0), W_YTD NUMBER(12, 2), W_TAX NUMBER(4, 4), W_NAME VARCHAR2(10), W_STREET_1 VARCHAR2(20), W_STREET_2 VARCHAR2(20), W_CITY VARCHAR2(20), W_STATE CHAR(2), W_ZIP CHAR(9)) INITRANS 4 PCTFREE 99 PCTUSED 1"
set sql(6) "CREATE TABLE STOCK (S_I_ID NUMBER(6, 0), S_W_ID NUMBER(6, 0), S_QUANTITY NUMBER(6, 0), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_YTD NUMBER(10, 0), S_ORDER_CNT NUMBER(6, 0), S_REMOTE_CNT NUMBER(6, 0), S_DATA VARCHAR2(50)) INITRANS 4 PCTFREE 10"
set sql(7) "CREATE TABLE NEW_ORDER (NO_W_ID NUMBER, NO_D_ID NUMBER, NO_O_ID NUMBER, CONSTRAINT INORD PRIMARY KEY (NO_W_ID, NO_D_ID, NO_O_ID) ENABLE ) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 PCTFREE 10"
if {$num_part eq 0} {
set sql(3) "CREATE TABLE HISTORY (H_C_ID NUMBER, H_C_D_ID NUMBER, H_C_W_ID NUMBER, H_D_ID NUMBER, H_W_ID NUMBER, H_DATE DATE, H_AMOUNT NUMBER(6, 2), H_DATA VARCHAR2(24)) INITRANS 4 PCTFREE 10"
set sql(8) "CREATE TABLE ORDERS (O_ID NUMBER, O_W_ID NUMBER, O_D_ID NUMBER, O_C_ID NUMBER, O_CARRIER_ID NUMBER, O_OL_CNT NUMBER, O_ALL_LOCAL NUMBER, O_ENTRY_D DATE) INITRANS 4 PCTFREE 10"
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID NUMBER, OL_D_ID NUMBER, OL_O_ID NUMBER, OL_NUMBER NUMBER, OL_I_ID NUMBER, OL_DELIVERY_D DATE, OL_AMOUNT NUMBER, OL_SUPPLY_W_ID NUMBER, OL_QUANTITY NUMBER, OL_DIST_INFO CHAR(24), CONSTRAINT IORDL PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER) ENABLE) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 PCTFREE 10"
	} else {
set sql(3) "CREATE TABLE HISTORY (H_C_ID NUMBER, H_C_D_ID NUMBER, H_C_W_ID NUMBER, H_D_ID NUMBER, H_W_ID NUMBER, H_DATE DATE, H_AMOUNT NUMBER(6, 2), H_DATA VARCHAR2(24)) INITRANS 4 PCTFREE 10 PARTITION BY HASH(H_W_ID) PARTITIONS $num_part"
set sql(8) "CREATE TABLE ORDERS (O_ID NUMBER, O_W_ID NUMBER, O_D_ID NUMBER, O_C_ID NUMBER, O_CARRIER_ID NUMBER, O_OL_CNT NUMBER, O_ALL_LOCAL NUMBER, O_ENTRY_D DATE) INITRANS 4 PCTFREE 10 PARTITION BY HASH(O_W_ID) PARTITIONS $num_part"
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID NUMBER, OL_D_ID NUMBER, OL_O_ID NUMBER, OL_NUMBER NUMBER, OL_I_ID NUMBER, OL_DELIVERY_D DATE, OL_AMOUNT NUMBER, OL_SUPPLY_W_ID NUMBER, OL_QUANTITY NUMBER, OL_DIST_INFO CHAR(24), CONSTRAINT IORDL PRIMARY KEY (OL_W_ID, OL_D_ID, OL_O_ID, OL_NUMBER) ENABLE) ORGANIZATION INDEX NOCOMPRESS INITRANS 4 PCTFREE 10 PARTITION BY HASH(OL_W_ID) PARTITIONS $num_part TABLESPACE $tpcc_ol_tab"
	}
set sql(10) "CREATE OR REPLACE VIEW STOCK_ITEM (I_ID, S_W_ID, I_PRICE, I_NAME, I_DATA, S_DATA, S_QUANTITY, S_ORDER_CNT, S_YTD, S_REMOTE_CNT, S_DIST_01, S_DIST_02, S_DIST_03, S_DIST_04, S_DIST_05, S_DIST_06, S_DIST_07, S_DIST_08, S_DIST_09, S_DIST_10) AS SELECT /*+ LEADING(S) USE_NL(I) */ I.I_ID, S_W_ID, I.I_PRICE, I.I_NAME, I.I_DATA, S_DATA, S_QUANTITY, S_ORDER_CNT, S_YTD, S_REMOTE_CNT, S_DIST_01, S_DIST_02, S_DIST_03, S_DIST_04, S_DIST_05, S_DIST_06, S_DIST_07, S_DIST_08, S_DIST_09, S_DIST_10 FROM STOCK S, ITEM I WHERE I.I_ID = S.S_I_ID"
    }
}   
if { $hash_clusters } {
for { set j 1 } { $j <= 5 } { incr j } {
if {[ catch {orasql $curn1 $sqlclust($j)} message ] } {
puts "$message $sql($j)"
puts [ oramsg $curn1 all ]
			}
		}
	}
for { set i 1 } { $i <= 10 } { incr i } {
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

proc CreateIndexes { lda timesten num_part hash_clusters } {
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
if { $hash_clusters } {
set stmt_cnt 18
set sql(1) "alter session set sort_area_size=5000000"
set sql(2) "CREATE UNIQUE INDEX CUSTOMER_I1 ON CUSTOMER (C_W_ID, C_D_ID, C_ID) INITRANS 4 PCTFREE 1"
set sql(3) "CREATE UNIQUE INDEX CUSTOMER_I2 ON CUSTOMER (C_LAST, C_D_ID, C_W_ID, C_FIRST) INITRANS 4 PCTFREE 1"
set sql(4) "CREATE UNIQUE INDEX DISTRICT_I1 ON DISTRICT (D_W_ID, D_ID) INITRANS 4 PCTFREE 5"
set sql(5) "CREATE UNIQUE INDEX ITEM_I1 ON ITEM (I_ID) INITRANS 4 PCTFREE 5"
set sql(6) "CREATE UNIQUE INDEX ORDERS_I1 ON ORDERS (O_W_ID, O_D_ID, O_ID) INITRANS 4 PCTFREE 10 LOCAL"
set sql(7) "CREATE UNIQUE INDEX ORDERS_I2 ON ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID) INITRANS 4 PCTFREE 10 LOCAL"
set sql(8) "CREATE UNIQUE INDEX STOCK_I1 ON STOCK (S_I_ID, S_W_ID) INITRANS 4 PCTFREE 1"
set sql(9) "CREATE UNIQUE INDEX WAREHOUSE_I1 ON WAREHOUSE (W_ID) INITRANS 4 PCTFREE 1"
set sql(10) "ALTER TABLE WAREHOUSE DISABLE TABLE LOCK"
set sql(11) "ALTER TABLE DISTRICT DISABLE TABLE LOCK"
set sql(12) "ALTER TABLE CUSTOMER DISABLE TABLE LOCK"
set sql(13) "ALTER TABLE ITEM DISABLE TABLE LOCK"
set sql(14) "ALTER TABLE STOCK DISABLE TABLE LOCK"
set sql(15) "ALTER TABLE ORDERS DISABLE TABLE LOCK"
set sql(16) "ALTER TABLE NEW_ORDER DISABLE TABLE LOCK"
set sql(17) "ALTER TABLE ORDER_LINE DISABLE TABLE LOCK"
set sql(18) "ALTER TABLE HISTORY DISABLE TABLE LOCK"
	} else {
set sql(1) "alter session set sort_area_size=5000000"
set sql(2) "CREATE UNIQUE INDEX CUSTOMER_I1 ON CUSTOMER ( C_W_ID, C_D_ID, C_ID) INITRANS 4 PCTFREE 10"
set sql(3) "CREATE UNIQUE INDEX CUSTOMER_I2 ON CUSTOMER ( C_LAST, C_W_ID, C_D_ID, C_FIRST, C_ID) INITRANS 4 PCTFREE 10"
set sql(4) "CREATE UNIQUE INDEX DISTRICT_I1 ON DISTRICT ( D_W_ID, D_ID) INITRANS 4 PCTFREE 10"
set sql(5) "CREATE UNIQUE INDEX ITEM_I1 ON ITEM (I_ID) INITRANS 4 PCTFREE 10"
if { $num_part eq 0 } {
set sql(6) "CREATE UNIQUE INDEX ORDERS_I1 ON ORDERS (O_W_ID, O_D_ID, O_ID) INITRANS 4 PCTFREE 10"
set sql(7) "CREATE UNIQUE INDEX ORDERS_I2 ON ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID) INITRANS 4 PCTFREE 10"
        } else {
set sql(6) "CREATE UNIQUE INDEX ORDERS_I1 ON ORDERS (O_W_ID, O_D_ID, O_ID) INITRANS 4 PCTFREE 10 LOCAL"
set sql(7) "CREATE UNIQUE INDEX ORDERS_I2 ON ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID) INITRANS 4 PCTFREE 10 LOCAL"
        }
set sql(8) "CREATE UNIQUE INDEX STOCK_I1 ON STOCK (S_I_ID, S_W_ID) INITRANS 4 PCTFREE 10"
set sql(9) "CREATE UNIQUE INDEX WAREHOUSE_I1 ON WAREHOUSE (W_ID) INITRANS 4 PCTFREE 10"
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

proc gettimestamp { } {
	set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
	return $tstamp
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

proc do_tpcc { system_user system_password instance count_ware tpcc_user tpcc_pass tpcc_def_tab tpcc_ol_tab tpcc_def_temp partition timesten hash_clusters num_vu } {
set MAXITEMS 100000
set CUST_PER_DIST 3000
set DIST_PER_WARE 10
set ORD_PER_DIST 3000
if { [ string toupper $timesten ] eq "TRUE"} { set timesten 1 } else { set timesten 0 }
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
puts "CREATING [ string toupper $tpcc_user ] SCHEMA"
if { $timesten } {
puts "TimesTen expects the Database [ string toupper $instance ] and User [ string toupper $tpcc_user ] to have been created by the instance administrator in advance and be granted create table, session, procedure, view (and admin for checkpoints) privileges"
	} else {
set connect $system_user/$system_password@$instance
set lda [ oralogon $connect ]
SetNLS $lda
CreateUser $lda $tpcc_user $tpcc_pass $tpcc_def_tab $tpcc_def_temp $tpcc_ol_tab $partition
oralogoff $lda
	}
set connect $tpcc_user/$tpcc_pass@$instance
set lda [ oralogon $connect ]
if { $timesten } {
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
set hash_clusters "false"
	} else {
set num_part [ expr round($count_ware/100) ]
	}
	} else {
set num_part 0
set hash_clusters "false"
}}
CreateTables $lda $num_part $tpcc_ol_tab $timesten $hash_clusters $count_ware
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
set connect $tpcc_user/$tpcc_pass@$instance
set lda [ oralogon $connect ]
if { $timesten } {
	;
	} else {
SetNLS $lda
	}
set remb [ lassign [ findchunk $num_vu $count_ware $myposition ] chunk mystart myend ]
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
CreateIndexes $lda $timesten $num_part $hash_clusters
if { $timesten } { TTPLSQLSettings $lda }
CreateStoredProcs $lda $timesten $num_part
GatherStatistics $lda [ string toupper $tpcc_user ] $timesten $num_part
puts "[ string toupper $tpcc_user ] SCHEMA COMPLETE"
oralogoff $lda
return
	}
    }
}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "do_tpcc $system_user $system_password $instance  $count_ware $tpcc_user $tpcc_pass $tpcc_def_tab $tpcc_ol_tab $tpcc_def_temp $partition $tpcc_tt_compat $hash_clusters $num_vu"
	} else { return }
}

proc insert_oraconnectpool_drivescript { testtype timedtype } {
#When using connect pooling delete the existing portions of the script and replace with new connect pool version
set syncdrvt(1) {
#RUN TPC-C
#Get Connect data as a dict
set cpool [ get_connect_xml ora ]
#Extract connect data only from dict
set connectonly [ dict filter [ dict get $cpool connections ] key c? ]
#Extract the keys, this will be c1, c2 etc and determines number of connections
set conkeys [ dict keys $connectonly ]
#Loop through the keys of the connection parameters
dict for {id conparams} $connectonly {
#Set the parameters to variables named from the keys, this allows us to build the connect strings according to the database
dict with conparams {
#set Oracle connect string
set $id "$tpcc_user/$tpcc_pass@$instance"
	}
    }
#For the connect keys c1, c2 etc make a connection
foreach id [ split $conkeys ] {
dict set connlist $id [ set lda$id [ OracleLogon [ set $id ] lda$id ] ]
	}
#Extract which storedprocedures use which connection
foreach sproc [ dict keys [ dict get $cpool sprocs ] ] { 
unset -nocomplain clist
#Extract the policy for the storedprocedures
set $sproc\_policy [ dict get $cpool sprocs $sproc policy ]
foreach sp [ dict get $cpool sprocs $sproc connections ] {
lappend clist [ dict get $connlist $sp ]
}
set newname "cs$sproc"
unset -nocomplain $newname
lappend $newname $clist
}
#Prepare statements multiple times for stored procedure for each connection and add to cursor list
foreach curn_st {curn_no curn_py curn_dl curn_sl curn_os} cslist {csneworder cspayment csdelivery csstocklevel csorderstatus} cursor_list { neworder_cursors payment_cursors delivery_cursors stocklevel_cursors orderstatus_cursors } len { nolen pylen dllen sllen oslen } cnt { nocnt pycnt dlcnt slcnt oscnt } { 
unset -nocomplain $cursor_list
set curcnt 0
#For all of the connections
foreach lda [ join [ set $cslist ] ] {
#Create a cursor name
set cursor [ concat $curn_st\_$curcnt ]
#Prepare a statement under the cursor name
set $cursor [ prep_statement $lda $curn_st ] 
incr curcnt
#Add it to a list of cursors for that stored procedure
lappend $cursor_list [ set $cursor ]
	}
#Record the number of cursors
set $len [ llength  [ set $cursor_list ] ]
#Initialise number of executions 
set $cnt 0
#puts "sproc_cur:$curn_st connections:[ set $cslist ] cursors:[set $cursor_list] number of cursors:[set $len] execs:[set $cnt]"
    }
#Open standalone connect to determine highest warehouse id for all connections
set mlda [ OracleLogon $connect mlda ]
set curn1 [ oraopen $mlda ]
set sql1 "select max(w_id) from warehouse"
set w_id_input [ standsql $curn1 $sql1 ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set sql2 "select max(d_id) from district"
set d_id_input [ standsql $curn1 $sql2 ]
oraclose $curn1
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
#Initialize DBMS_RANDOM for all connections
set sql3 "BEGIN DBMS_RANDOM.initialize (val => TO_NUMBER(TO_CHAR(SYSDATE,'MMSS')) * (USERENV('SESSIONID') - TRUNC(USERENV('SESSIONID'),-5))); END;"
foreach conn [ dict values $connlist ]  {
set curn1 [ oraopen $conn ]
oraparse $curn1 $sql3
if {[catch {oraplexec $curn1 $sql3} message]} {
error "Failed to initialise DBMS_RANDOM $message have you run catoctk.sql as sys?" }
oraclose $curn1
}
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
set curn_no [ pick_cursor $neworder_policy $neworder_cursors $nocnt $nolen ]
neword $curn_no $w_id $w_id_input $RAISEERROR
incr nocnt
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
set curn_py [ pick_cursor $payment_policy $payment_cursors $pycnt $pylen ]
payment $curn_py $w_id $w_id_input $RAISEERROR
incr pycnt
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
set curn_dl [ pick_cursor $delivery_policy $delivery_cursors $dlcnt $dllen ]
delivery $curn_dl $w_id $RAISEERROR
incr dlcnt
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
set curn_sl [ pick_cursor $stocklevel_policy $stocklevel_cursors $slcnt $sllen ]
slev $curn_sl $w_id $stock_level_d_id $RAISEERROR
incr slcnt
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
set curn_os [ pick_cursor $orderstatus_policy $orderstatus_cursors $oscnt $oslen ]
ostat $curn_os $w_id $RAISEERROR
incr oscnt
if { $KEYANDTHINK } { thinktime 5 }
	}
}
foreach cursor $neworder_cursors { oraclose $cursor }
foreach cursor $payment_cursors { oraclose $cursor }
foreach cursor $delivery_cursors { oraclose $cursor }
foreach cursor $stocklevel_cursors { oraclose $cursor }
foreach cursor $orderstatus_cursors { oraclose $cursor }
foreach lda [ dict values $connlist ] { oralogoff $lda }
oralogoff $mlda
}
#Find single connection start and end points
set syncdrvi(1a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "#RUN TPC-C" end ]
set syncdrvi(1b) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "oralogoff \$lda" end ]
#puts "indexes are $syncdrvi(1a) and $syncdrvi(1b)"
#Delete text from start and end points
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $syncdrvi(1a) $syncdrvi(1b)+1l
#Replace with connect pool version
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(1a) $syncdrvt(1)
if { $testtype eq "timed" } {
#Diff between test and time sync scripts are the "puts stored proc lines", timesten login and output suppressed, delete stored proc lines and replace login and output lines
foreach line { {puts "new order"} {puts "payment"} {puts "delivery"} {puts "stock level"} {puts "order status"} } {
#find start of line
set index [.ed_mainFrame.mainwin.textFrame.left.text search -backwards $line end ]
#delete to end of line including newline
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $index "$index lineend + 1 char"
		}
foreach line {{dict set connlist $id [ set lda$id [ OracleLogon [ set $id ] lda$id ] ]} {set mlda [ OracleLogon $connect mlda ]} {"Processing $total_iterations transactions without output suppressed..."}} timedline {{dict set connlist $id [ set lda$id [ OracleLogon [ set $id ] lda$id $timesten ] ]} {set mlda [ OracleLogon $connect mlda $timesten ]} {"Processing $total_iterations transactions with output suppressed..."}} {
set index [.ed_mainFrame.mainwin.textFrame.left.text search -backwards $line end ]
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $index "$index lineend + 1 char"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $index "$timedline \n"
		}
if { $timedtype eq "async" } {
set syncdrvt(2) {proc AsyncClientLogon { connectstring lda timesten RAISEERROR clientname async_verbose } {
if {[catch {set lda [oralogon $connectstring]} message]} {
if { $RAISEERROR } {
puts "$clientname:login failed:$message"
return "$clientname:login failed:$message"
                 }
        } else {
if { !$timesten } { SetNLS $lda }
oraautocom $lda on
if { $async_verbose } { puts "Connected $clientname:$lda" }
return $lda
   }
}
}
set syncdrvt(3) {for {set it 0} {$it < $total_iterations} {incr it} { 
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
set curn_no [ pick_cursor $neworder_policy $neworder_cursors $nocnt $nolen ]
if { $async_verbose } { puts "$clientname:w_id:$w_id:$curn_no:neword" }
if { $KEYANDTHINK } { async_keytime 18  $clientname neword $async_verbose }
neword $curn_no $w_id $w_id_input $RAISEERROR $clientname
incr nocnt
if { $KEYANDTHINK } { async_thinktime 12 $clientname neword $async_verbose }
} elseif {$choice <= 20} {
set curn_py [ pick_cursor $payment_policy $payment_cursors $pycnt $pylen ]
if { $async_verbose } { puts "$clientname:w_id:$w_id:$curn_py:payment" }
if { $KEYANDTHINK } { async_keytime 3 $clientname payment $async_verbose }
payment $curn_py $w_id $w_id_input $RAISEERROR $clientname
incr pycnt
if { $KEYANDTHINK } { async_thinktime 12 $clientname payment $async_verbose }
} elseif {$choice <= 21} {
set curn_dl [ pick_cursor $delivery_policy $delivery_cursors $dlcnt $dllen ]
if { $async_verbose } { puts "$clientname:w_id:$w_id:$curn_dl:delivery" }
if { $KEYANDTHINK } { async_keytime 2 $clientname delivery $async_verbose }
delivery $curn_dl $w_id $RAISEERROR $clientname
incr dlcnt
if { $KEYANDTHINK } { async_thinktime 10 $clientname delivery $async_verbose }
} elseif {$choice <= 22} {
set curn_sl [ pick_cursor $stocklevel_policy $stocklevel_cursors $slcnt $sllen ]
if { $async_verbose } { puts "$clientname:w_id:$w_id:$curn_sl:slev" }
if { $KEYANDTHINK } { async_keytime 2 $clientname slev $async_verbose }
slev $curn_sl $w_id $stock_level_d_id $RAISEERROR $clientname
incr slcnt
if { $KEYANDTHINK } { async_thinktime 5 $clientname slev $async_verbose }
} elseif {$choice <= 23} {
set curn_os [ pick_cursor $orderstatus_policy $orderstatus_cursors $oscnt $oslen ]
if { $async_verbose } { puts "$clientname:w_id:$w_id:$curn_os:ostat" }
if { $KEYANDTHINK } { async_keytime 2 $clientname ostat $async_verbose }
ostat $curn_os $w_id $RAISEERROR $clientname
incr oscnt
if { $KEYANDTHINK } { async_thinktime 5 $clientname ostat $async_verbose }
        }
    }
}
set syncdrvi(2a) [.ed_mainFrame.mainwin.textFrame.left.text search -forwards "#STANDARD SQL" 1.0 ]
#Insert Asynch Login procedure
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(2a) $syncdrvt(2)
#Change Run Loop for Asynchronous
set syncdrvi(3a) [.ed_mainFrame.mainwin.textFrame.left.text search -forwards "for {set it 0}" 1.0 ]
set syncdrvi(3b) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "foreach cursor \$neworder_cursors { oraclose \$cursor }" end ]
#End of run loop is previous line
set syncdrvi(3b) [ expr $syncdrvi(3b) - 1 ]
#Delete run loop
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $syncdrvi(3a) $syncdrvi(3b)+1l
#Replace with asynchronous connect pool version
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(3a) $syncdrvt(3)
#Remove extra async connection
set syncdrvi(7a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "#Open standalone connect to determine highest warehouse id for all connections" end ]
set syncdrvi(7b) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards {set mlda [ OracleLogon $connect mlda $timesten ]} end ]
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $syncdrvi(7a) $syncdrvi(7b)+1l
#Replace individual lines for Asynch
foreach line {{if { $async_verbose } { puts "Connected $clientname:$lda" }} {dict set connlist $id [ set lda$id [ OracleLogon [ set $id ] lda$id $timesten ]} {#puts "sproc_cur:$curn_st connections:[ set $cslist ] cursors:[set $cursor_list] number of cursors:[set $len] execs:[set $cnt]"} {puts "Processing $total_iterations transactions with output suppressed..."}} asynchline {{if { $async_verbose } { puts "Connected $clientname:$mlda" }} {dict set connlist $id [ set lda$id [ AsyncClientLogon [ set $id ] lda$id $timesten $RAISEERROR $clientname $async_verbose ] ]} {#puts "$clientname:sproc_cur:$curn_st connections:[ set $cslist ] cursors:[set $cursor_list] number of cursors:[set $len] execs:[set $cnt]"} {if { $async_verbose } { puts "Processing $total_iterations transactions with output suppressed..." }}} {
set index [.ed_mainFrame.mainwin.textFrame.left.text search -backwards $line end ]
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $index "$index lineend + 1 char"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $index "$asynchline \n"
                }
#Edit line with additional curly bracket needs additional subst command so cannot go in loop
set index [.ed_mainFrame.mainwin.textFrame.left.text search -backwards [ subst -nocommands -novariables {if {[catch {set lda [ OracleLogon $connect lda $timesten ]} message]} \{} ] end ]
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $index "$index lineend + 1 char"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $index "[ subst -nocommands -novariables {if {[catch {set mlda [ OracleLogon $connect mlda $timesten ]} message]} \{} ] \n"
#Add client side counters for timed async only this is different from non-async
set syncdrvt(4) {initializeclientcountasync $totalvirtualusers $async_client
}
set syncdrvt(5) {getclienttpmasync $rampup $duration $totalvirtualusers $async_client
}
set syncdrvt(6) {printclientcountasync $clientname $nocnt $pycnt $dlcnt $slcnt $oscnt
}
set syncdrvi(4a) [.ed_mainFrame.mainwin.textFrame.left.text search -forwards "set ramptime 0" 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(4a) $syncdrvt(4)
set syncdrvi(5a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "tsv::set application abort 1" end ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(5a)+1l $syncdrvt(5)
set syncdrvi(6a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards {foreach cursor $neworder_cursors { oraclose $cursor }} end ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(6a) $syncdrvt(6)
} else {
#Add client side counters for timed non-async only
set syncdrvt(4) {initializeclientcountsync $totalvirtualusers
}
set syncdrvt(5) {getclienttpmsync $rampup $duration $totalvirtualusers
}
set syncdrvt(6) {printclientcountsync $myposition $nocnt $pycnt $dlcnt $slcnt $oscnt
}
set syncdrvi(4a) [.ed_mainFrame.mainwin.textFrame.left.text search -forwards "set ramptime 0" 1.0 ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(4a) $syncdrvt(4)
set syncdrvi(5a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "tsv::set application abort 1" end ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(5a)+1l $syncdrvt(5)
set syncdrvi(6a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards {foreach cursor $neworder_cursors { oraclose $cursor }} end ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(6a) $syncdrvt(6)
	}
    }
}

proc loadoratpcc { } {
global _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict oracle library ]} {
set library [ dict get $dbdict oracle library ]
} else { set library "Oratcl" } 
upvar #0 configoracle configoracle
setlocaltpccvars $configoracle
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "Oracle TPROC-C"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# Oracle OCI Library
set total_iterations $total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$raiseerror\" ;# Exit script on Oracle error (true or false)
set KEYANDTHINK \"$keyandthink\" ;# Time for user thinking and keying (true or false)
set connect $tpcc_user/$tpcc_pass@$instance ;# Oracle connect string for tpc-c user
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

#LOGON
proc OracleLogon { connectstring lda } {
set lda [oralogon $connectstring ]
SetNLS $lda
oraautocom $lda on
return $lda
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
#NLS
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
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
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
orabind $curn_sl :st_w_id $w_id :st_d_id $stock_level_d_id :THRESHOLD $threshold :stocklevel {}
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
set sql_sl "BEGIN slev(:st_w_id,:st_d_id,:threshold,:stocklevel); END;"
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
set lda [ OracleLogon $connect lda ]
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
oralogoff $lda}
if { $connect_pool } { 
insert_oraconnectpool_drivescript test sync 
	} 
}

proc loadtimedoratpcc { } {
global opmode _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict oracle library ]} {
set library [ dict get $dbdict oracle library ]
} else { set library "Oratcl" }
upvar #0 configoracle configoracle
setlocaltpccvars $configoracle
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "Oracle Timed TPROC-C"
if { !$async_scale } {
#REGULAR TIMED SCRIPT
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# Oracle OCI Library
set total_iterations $total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$raiseerror\" ;# Exit script on Oracle error (true or false)
set KEYANDTHINK \"$keyandthink\" ;# Time for user thinking and keying (true or false)
set CHECKPOINT \"$checkpoint\" ;# Perform Oracle checkpoint when complete (true or false)
set rampup $rampup;  # Rampup time in minutes before first snapshot is taken
set duration $duration;  # Duration in minutes before second AWR snapshot is taken
set mode \"$opmode\" ;# HammerDB operational mode
set timesten \"$tpcc_tt_compat\" ;# Database is TimesTen
set systemconnect $system_user/$system_password@$instance ;# Oracle connect string for system user
set connect $tpcc_user/$tpcc_pass@$instance ;# Oracle connect string for tpc-c user
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

#LOGON
proc OracleLogon { connectstring lda timesten } {
set lda [oralogon $connectstring ]
if { !$timesten } { SetNLS $lda }
oraautocom $lda on
return $lda
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
set rema [ lassign [ findvuposition ] myposition totalvirtualusers ]
if { [ string toupper $timesten ] eq "TRUE"} { 
set timesten 1 
set systemconnect $connect
} else { 
set timesten 0 
}
switch $myposition {
1 { 
if { $mode eq "Local" || $mode eq "Primary" } {
set lda [ OracleLogon $systemconnect lda $timesten ]
set curn1 [oraopen $lda ] 
set lda1 [ OracleLogon $connect lda1 $timesten ]
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
set sql2 "SELECT INSTANCE_NUMBER, INSTANCE_NAME, DB_NAME, DBID, SNAP_ID, TO_CHAR(END_INTERVAL_TIME,'DD MON YYYY HH24:MI') FROM (SELECT DI.INSTANCE_NUMBER, DI.INSTANCE_NAME, DI.DB_NAME, DI.DBID, DS.SNAP_ID, DS.END_INTERVAL_TIME FROM DBA_HIST_SNAPSHOT DS, DBA_HIST_DATABASE_INSTANCE DI WHERE DS.DBID=DI.DBID AND DS.INSTANCE_NUMBER=DI.INSTANCE_NUMBER AND DS.STARTUP_TIME=DI.STARTUP_TIME ORDER BY DS.END_INTERVAL_TIME DESC) WHERE ROWNUM=1"
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
puts "[ expr $totalvirtualusers - 1 ] Active Virtual Users configured"
puts [ testresult $nopm $tpm TimesTen ]
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
set sql6 {select value from v$parameter where name = 'cluster_database'}
oraparse $curn1 $sql6
set israc [ standsql $curn1 $sql6 ]
if { $israc != "FALSE" } {
set ractpm 0
set sql7 {select max(inst_number) from v$active_instances}
oraparse $curn1 $sql7
set activinst [ standsql $curn1 $sql7 ]
for { set a 1 } { $a <= $activinst } { incr a } {
set firstsnap [ lreplace $firstsnap 0 0 $a ]
set endsnap [ lreplace $endsnap 0 0 $a ]
set sqlrac "select round((sum(tps)*60)) as TPM from (select e.stat_name, (e.value - b.value) / (select avg( extract( day from (e1.end_interval_time-b1.end_interval_time) )*24*60*60+ extract( hour from (e1.end_interval_time-b1.end_interval_time) )*60*60+ extract( minute from (e1.end_interval_time-b1.end_interval_time) )*60+ extract( second from (e1.end_interval_time-b1.end_interval_time)) ) from dba_hist_snapshot b1, dba_hist_snapshot e1 where b1.snap_id = [ lindex $firstsnap 4 ] and e1.snap_id = [ lindex $endsnap 4 ] and b1.dbid = [lindex $firstsnap 3] and e1.dbid = [lindex $endsnap 3] and b1.instance_number = [lindex $firstsnap 0] and e1.instance_number = [lindex $endsnap 0] and b1.startup_time = e1.startup_time and b1.end_interval_time < e1.end_interval_time) as tps from dba_hist_sysstat b, dba_hist_sysstat e where b.snap_id = [ lindex $firstsnap 4 ] and e.snap_id = [ lindex $endsnap 4 ] and b.dbid = [lindex $firstsnap 3] and e.dbid = [lindex $endsnap 3] and b.instance_number = [lindex $firstsnap 0] and e.instance_number = [lindex $endsnap 0] and b.stat_id = e.stat_id and b.stat_name in ('user commits','user rollbacks') and e.stat_name in ('user commits','user rollbacks') order by 1 asc)"
set ractpm [ expr $ractpm + [ standsql $curn1 $sqlrac ]]
                }
set tpm $ractpm
        }
puts "[ expr $totalvirtualusers - 1 ] Active Virtual Users configured"
puts [ testresult $nopm $tpm Oracle ]
	}
}
tsv::set application abort 1
if { $mode eq "Primary" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
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
puts "Operating in Replica Mode, No Snapshots taken..."
		}
	}
default {
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
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
orabind $curn_sl :st_w_id $w_id :st_d_id $stock_level_d_id :THRESHOLD $threshold :stocklevel {} 
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
set sql_sl "BEGIN slev(:st_w_id,:st_d_id,:threshold,:stocklevel); END;"
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
set lda [ OracleLogon $connect lda $timesten ]
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
     }} 
if { $connect_pool } { 
insert_oraconnectpool_drivescript timed sync 
	} 
} else {
#ASYNCHRONOUS TIMED SCRIPT
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# Oracle OCI Library
set total_iterations $total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$raiseerror\" ;# Exit script on Oracle error (true or false)
set KEYANDTHINK \"true\" ;# Time for user thinking and keying (true or false)
set CHECKPOINT \"$checkpoint\" ;# Perform Oracle checkpoint when complete (true or false)
set rampup $rampup;  # Rampup time in minutes before first snapshot is taken
set duration $duration;  # Duration in minutes before second AWR snapshot is taken
set mode \"$opmode\" ;# HammerDB operational mode
set timesten \"$tpcc_tt_compat\" ;# Database is TimesTen
set systemconnect $system_user/$system_password@$instance ;# Oracle connect string for system user
set connect $tpcc_user/$tpcc_pass@$instance ;# Oracle connect string for tpc-c user
set async_client $async_client;# Number of asynchronous clients per Vuser
set async_verbose $async_verbose;# Report activity of asynchronous clients
set async_delay $async_delay;# Delay in ms between logins of asynchronous clients
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }
if [catch {package require promise } message] { error "Failed to load promise package for asynchronous clients" }

#LOGON
proc OracleLogon { connectstring lda timesten } {
set lda [oralogon $connectstring ]
if { !$timesten } { SetNLS $lda }
oraautocom $lda on
return $lda
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
set rema [ lassign [ findvuposition ] myposition totalvirtualusers ]
if { [ string toupper $timesten ] eq "TRUE"} { 
set timesten 1 
set systemconnect $connect
} else { 
set timesten 0 
}
switch $myposition {
1 { 
if { $mode eq "Local" || $mode eq "Primary" } {
set lda [ OracleLogon $systemconnect lda $timesten ]
set curn1 [oraopen $lda ]
set lda1 [ OracleLogon $connect lda1 $timesten ]
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
set sql2 "SELECT INSTANCE_NUMBER, INSTANCE_NAME, DB_NAME, DBID, SNAP_ID, TO_CHAR(END_INTERVAL_TIME,'DD MON YYYY HH24:MI') FROM (SELECT DI.INSTANCE_NUMBER, DI.INSTANCE_NAME, DI.DB_NAME, DI.DBID, DS.SNAP_ID, DS.END_INTERVAL_TIME FROM DBA_HIST_SNAPSHOT DS, DBA_HIST_DATABASE_INSTANCE DI WHERE DS.DBID=DI.DBID AND DS.INSTANCE_NUMBER=DI.INSTANCE_NUMBER AND DS.STARTUP_TIME=DI.STARTUP_TIME ORDER BY DS.END_INTERVAL_TIME DESC) WHERE ROWNUM=1"
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
puts "[ expr $totalvirtualusers - 1 ] VU \* $async_client AC \= [ expr ($totalvirtualusers - 1) * $async_client ] Active Sessions configured"
puts [ testresult $nopm $tpm TimesTen ]
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
set sql6 {select value from v$parameter where name = 'cluster_database'}
oraparse $curn1 $sql6
set israc [ standsql $curn1 $sql6 ]
if { $israc != "FALSE" } {
set ractpm 0
set sql7 {select max(inst_number) from v$active_instances}
oraparse $curn1 $sql7
set activinst [ standsql $curn1 $sql7 ]
for { set a 1 } { $a <= $activinst } { incr a } {
set firstsnap [ lreplace $firstsnap 0 0 $a ]
set endsnap [ lreplace $endsnap 0 0 $a ]
set sqlrac "select round((sum(tps)*60)) as TPM from (select e.stat_name, (e.value - b.value) / (select avg( extract( day from (e1.end_interval_time-b1.end_interval_time) )*24*60*60+ extract( hour from (e1.end_interval_time-b1.end_interval_time) )*60*60+ extract( minute from (e1.end_interval_time-b1.end_interval_time) )*60+ extract( second from (e1.end_interval_time-b1.end_interval_time)) ) from dba_hist_snapshot b1, dba_hist_snapshot e1 where b1.snap_id = [ lindex $firstsnap 4 ] and e1.snap_id = [ lindex $endsnap 4 ] and b1.dbid = [lindex $firstsnap 3] and e1.dbid = [lindex $endsnap 3] and b1.instance_number = [lindex $firstsnap 0] and e1.instance_number = [lindex $endsnap 0] and b1.startup_time = e1.startup_time and b1.end_interval_time < e1.end_interval_time) as tps from dba_hist_sysstat b, dba_hist_sysstat e where b.snap_id = [ lindex $firstsnap 4 ] and e.snap_id = [ lindex $endsnap 4 ] and b.dbid = [lindex $firstsnap 3] and e.dbid = [lindex $endsnap 3] and b.instance_number = [lindex $firstsnap 0] and e.instance_number = [lindex $endsnap 0] and b.stat_id = e.stat_id and b.stat_name in ('user commits','user rollbacks') and e.stat_name in ('user commits','user rollbacks') order by 1 asc)"
set ractpm [ expr $ractpm + [ standsql $curn1 $sqlrac ]]
                }
set tpm $ractpm
        }
puts "[ expr $totalvirtualusers - 1 ] VU \* $async_client AC \= [ expr ($totalvirtualusers - 1) * $async_client ] Active Sessions configured"
puts [ testresult $nopm $tpm Oracle ]
	}
}
tsv::set application abort 1
if { $mode eq "Primary" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
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
puts "Operating in Replica Mode, No Snapshots taken..."
		}
	}
default {
#TIMESTAMP
proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}
#NEW ORDER
proc neword { curn_no no_w_id w_id_input RAISEERROR clientname } {
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
puts "Error in $clientname New Order : $message [ oramsg $curn_no all ]"
	} else {
;
	} } else {
orafetch  $curn_no -datavariable output
;
	}
}
#PAYMENT
proc payment { curn_py p_w_id w_id_input RAISEERROR clientname } {
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
puts "Error in $clientname Payment : $message [ oramsg $curn_py all ]"
	} else {
;
} } else {
orafetch  $curn_py -datavariable output
;
	}
}
#ORDER_STATUS
proc ostat { curn_os w_id RAISEERROR clientname } {
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
puts "Error in $clientname Order Status : $message [ oramsg $curn_os all ]"
	} else {
;
} } else {
orafetch  $curn_os -datavariable output
;
	}
}
#DELIVERY
proc delivery { curn_dl w_id RAISEERROR clientname } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
orabind $curn_dl :d_w_id $w_id :d_o_carrier_id $carrier_id :timestamp $date
if {[ catch {oraexec $curn_dl} message ]} {
if { $RAISEERROR } {
puts "Error in $clientname Delivery : $message [ oramsg $curn_dl all ]"
	} else {
;
} } else {
orafetch  $curn_dl -datavariable output
;
	}
}
#STOCK LEVEL
proc slev { curn_sl w_id stock_level_d_id RAISEERROR clientname } {
set threshold [ RandomNumber 10 20 ]
orabind $curn_sl :st_w_id $w_id :st_d_id $stock_level_d_id :THRESHOLD $threshold :stocklevel {} 
if {[catch {oraexec $curn_sl} message]} { 
if { $RAISEERROR } {
puts "Error in $clientname Stock Level : $message [ oramsg $curn_sl all ]"
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
set sql_sl "BEGIN slev(:st_w_id,:st_d_id,:threshold,:stocklevel); END;"
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
#CONNECT ASYNC
promise::async simulate_client { clientname total_iterations connect RAISEERROR KEYANDTHINK timesten async_verbose async_delay } {
set acno [ expr [ string trimleft [ lindex [ split $clientname ":" ] 1 ] ac ] * $async_delay ]
if { $async_verbose } { puts "Delaying login of $clientname for $acno ms" } 
async_time $acno
if {  [ tsv::get application abort ]  } { return "$clientname:abort before login" }
if { $async_verbose } { puts "Logging in $clientname" } 
if {[catch {set lda [ OracleLogon $connect lda $timesten ]} message]} {
if { $RAISEERROR } {
puts "$clientname:login failed:$message"
return "$clientname:login failed:$message"
	         }
        } else {
if { $async_verbose } { puts "Connected $clientname:$lda" }
   }
#RUN TPC-C
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
if { $async_verbose } { puts "Processing $total_iterations transactions with output suppressed..." }
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:neword" }
if { $KEYANDTHINK } { async_keytime 18  $clientname neword $async_verbose }
neword $curn_no $w_id $w_id_input $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 12 $clientname neword $async_verbose }
} elseif {$choice <= 20} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:payment" }
if { $KEYANDTHINK } { async_keytime 3 $clientname payment $async_verbose }
payment $curn_py $w_id $w_id_input $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 12 $clientname payment $async_verbose }
} elseif {$choice <= 21} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:delivery" }
if { $KEYANDTHINK } { async_keytime 2 $clientname delivery $async_verbose }
delivery $curn_dl $w_id $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 10 $clientname delivery $async_verbose }
} elseif {$choice <= 22} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:slev" }
if { $KEYANDTHINK } { async_keytime 2 $clientname slev $async_verbose }
slev $curn_sl $w_id $stock_level_d_id $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 5 $clientname slev $async_verbose }
} elseif {$choice <= 23} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:ostat" }
if { $KEYANDTHINK } { async_keytime 2 $clientname ostat $async_verbose }
ostat $curn_os $w_id $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 5 $clientname ostat $async_verbose }
	}
}
oraclose $curn_no
oraclose $curn_py
oraclose $curn_dl
oraclose $curn_sl
oraclose $curn_os
oralogoff $lda
if { $async_verbose } { puts "$clientname:complete" }
return $clientname:complete
	  }
for {set ac 1} {$ac <= $async_client} {incr ac} { 
set clientdesc "vuser$myposition:ac$ac"
lappend clientlist $clientdesc
lappend clients [simulate_client $clientdesc $total_iterations $connect $RAISEERROR $KEYANDTHINK $timesten $async_verbose $async_delay]
		}
puts "Started asynchronous clients:$clientlist"
set acprom [ promise::eventloop [ promise::all $clients ] ] 
puts "All asynchronous clients complete" 
if { $async_verbose } {
foreach client $acprom { puts $client }
       }
   }
}} 
if { $connect_pool } { 
insert_oraconnectpool_drivescript timed async 
	} 
}
}
