proc build_db2tpcc {} {
global maxvuser suppo ntimes threadscreated _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict db2 library ]} {
        set library [ dict get $dbdict db2 library ]
} else { set library "db2tcl" }
upvar #0 configdb2 configdb2
#set variables to values in dict
setlocaltpccvars $configdb2
if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a $db2_count_ware Warehouse Db2 TPROC-C schema\nunder user [ string toupper $db2_user ] in existing database [ string toupper $db2_dbase ]?" -type yesno ] == yes} { 
if { $db2_num_vu eq 1 || $db2_count_ware eq 1 } {
set maxvuser 1
} else {
set maxvuser [ expr $db2_num_vu + 1 ]
}
set suppo 1
set ntimes 1
ed_edit_clear
set _ED(packagekeyname) "Db2 TPROC-C creation"
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

proc CreateStoredProcs { db_handle } {
puts "CREATING TPCC STORED PROCEDURES"
set sql(1) { CREATE OR REPLACE PROCEDURE NEWORD (
no_w_id		INTEGER,
no_max_w_id	INTEGER,
no_d_id		INTEGER,
no_c_id		INTEGER,
no_o_ol_cnt		INTEGER,
OUT no_c_discount 	DECIMAL(4,4),
OUT no_c_last 		VARCHAR(16),
OUT no_c_credit		VARCHAR(2),
OUT no_d_tax 		DECIMAL(4,4),
OUT no_w_tax 		DECIMAL(4,4),
INOUT no_d_next_o_id 	INTEGER,
IN timestamp 		DATE
)
MODIFIES SQL DATA NO EXTERNAL ACTION DETERMINISTIC LANGUAGE SQL
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
SET no_o_all_local = 0;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND
customer.c_d_id = no_d_id AND customer.c_id = no_c_id;
SELECT d_next_o_id, d_tax INTO no_d_next_o_id, no_d_tax
FROM OLD TABLE ( UPDATE district 
SET d_next_o_id = d_next_o_id + 1 
WHERE d_id = no_d_id 
AND d_w_id = no_w_id );
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
FROM NEW TABLE (UPDATE STOCK
SET s_quantity = CASE WHEN ( s_quantity > no_ol_quantity )
THEN ( s_quantity - no_ol_quantity )
ELSE ( s_quantity - no_ol_quantity + 91 )
END
WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id
) AS US;
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
END }
set sql(2) { CREATE OR REPLACE PROCEDURE PAYMENT (
IN p_w_id               INTEGER,
IN p_d_id               INTEGER,
IN p_c_w_id             INTEGER,
IN p_c_d_id             INTEGER,
INOUT p_c_id            INTEGER,
IN byname               INTEGER,
IN p_h_amount           DECIMAL(6,2),
INOUT p_c_last          VARCHAR(16),
OUT p_w_street_1        VARCHAR(20),
OUT p_w_street_2        VARCHAR(20),
OUT p_w_city            VARCHAR(20),
OUT p_w_state           CHAR(2),
OUT p_w_zip             CHAR(9),
OUT p_d_street_1        VARCHAR(20),
OUT p_d_street_2        VARCHAR(20),
OUT p_d_city            VARCHAR(20),
OUT p_d_state           CHAR(2),
OUT p_d_zip             CHAR(9),
OUT p_c_first           VARCHAR(16),
OUT p_c_middle          CHAR(2),
OUT p_c_street_1        VARCHAR(20),
OUT p_c_street_2        VARCHAR(20),
OUT p_c_city            VARCHAR(20),
OUT p_c_state           CHAR(2),
OUT p_c_zip             CHAR(9),
OUT p_c_phone           CHAR(16),
OUT p_c_since           DATE,
INOUT p_c_credit        CHAR(2),
OUT p_c_credit_lim      DECIMAL(12,2),
OUT p_c_discount        DECIMAL(4,4),
INOUT p_c_balance       DECIMAL(12,2),
OUT p_c_data            VARCHAR(500),
IN timestamp            DATE
)
MODIFIES SQL DATA NO EXTERNAL ACTION DETERMINISTIC LANGUAGE SQL
BEGIN
DECLARE done                    INT DEFAULT 0;
DECLARE namecnt                 INTEGER;
DECLARE p_d_name                VARCHAR(11);
DECLARE p_w_name                VARCHAR(11);
DECLARE p_c_new_data    VARCHAR(500);
DECLARE h_data                  VARCHAR(30);
DECLARE loop_counter    INT;
DECLARE c_byname CURSOR FOR
SELECT c_first, c_middle, c_id, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last
ORDER BY c_first;
SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name
INTO p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip, p_w_name
FROM OLD TABLE ( UPDATE warehouse SET w_ytd = w_ytd + p_h_amount
WHERE w_id = p_w_id ) AS UP;
SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name
INTO p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip, p_d_name
FROM OLD TABLE ( UPDATE district SET d_ytd = d_ytd + p_h_amount
WHERE d_w_id = p_w_id AND d_id = p_d_id ) AS UP;
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
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id WITH RR USE AND KEEP UPDATE LOCKS;
END IF;
SET p_c_balance = ( p_c_balance + p_h_amount );
IF p_c_credit = 'BC'
THEN
 SELECT c_data INTO p_c_data
FROM customer
WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
SET h_data = ( p_w_name || ' ' || p_d_name );
SET p_c_new_data = (TO_CHAR(p_c_id) || ' ' || TO_CHAR(p_c_d_id) || ' ' || TO_CHAR(p_c_w_id) || ' ' || TO_CHAR(p_d_id) || ' ' || TO_CHAR(p_w_id) || ' ' || VARCHAR_FORMAT(p_h_amount,'9999.99') || VARCHAR_FORMAT(timestamp,'YYYYMMDDHH24MISS') || h_data);
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
SET h_data = ( p_w_name || ' ' || p_d_name );
INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data)
VALUES (p_c_d_id, p_c_w_id, p_c_id, p_d_id, p_w_id, timestamp, p_h_amount, h_data);
END }
set sql(3) { CREATE TYPE DELIVARRAY AS INTEGER ARRAY[10] }
set sql(4) { CREATE OR REPLACE PROCEDURE DELIVERY (
IN d_w_id                       INTEGER,
IN d_o_carrier_id               INTEGER,
IN tstamp                       TIMESTAMP,
OUT deliv_data                  DELIVARRAY
        )
MODIFIES SQL DATA NO EXTERNAL ACTION DETERMINISTIC LANGUAGE SQL
BEGIN
DECLARE d_no_o_id               INTEGER;
DECLARE d_d_id                  INTEGER;
DECLARE d_c_id                  INTEGER;
DECLARE d_ol_total              DECIMAL(12,2);
DECLARE loop_counter            INTEGER DEFAULT 1;
WHILE loop_counter <= 10 DO
SET d_d_id = loop_counter;
SELECT no_o_id INTO d_no_o_id FROM OLD TABLE ( DELETE FROM (
SELECT no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id 
ORDER BY no_o_id ASC 
FETCH FIRST 1 ROW ONLY ) 
);
SELECT o_c_id INTO d_c_id FROM OLD TABLE (
UPDATE orders SET o_carrier_id = d_o_carrier_id
WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND
o_w_id = d_w_id ); 
SELECT SUM(ol_amount) INTO d_ol_total 
FROM OLD TABLE ( UPDATE order_line 
SET ol_delivery_d = tstamp
WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND
ol_w_id = d_w_id);
UPDATE customer SET c_balance = c_balance + d_ol_total
WHERE c_id = d_c_id AND c_d_id = d_d_id AND
c_w_id = d_w_id;
set deliv_data[loop_counter] = d_no_o_id;
set loop_counter = loop_counter + 1;
END WHILE;
END }
set sql(5) { CREATE OR REPLACE PROCEDURE OSTAT (
IN os_w_id                 INTEGER,
IN os_d_id                 INTEGER,
INOUT os_c_id              INTEGER,
IN byname                  INTEGER,
INOUT os_c_last            VARCHAR(16),
OUT os_c_first             VARCHAR(16),
OUT os_c_middle            VARCHAR(16),
OUT os_c_balance           DECIMAL(12,2),
OUT os_o_id                INTEGER,
OUT os_entdate             TIMESTAMP,
OUT os_o_carrier_id        INTEGER 
	)
READS SQL DATA NO EXTERNAL ACTION DETERMINISTIC LANGUAGE SQL
BEGIN
DECLARE sqlstate		CHAR(5) DEFAULT '00000';
DECLARE namecnt			INTEGER;
DECLARE i			INTEGER;
DECLARE loop_counter    	INTEGER;
DECLARE done		    	INTEGER;
DECLARE os_ol_i_id INTEGER;	
DECLARE os_ol_supply_w_id INTEGER;	
DECLARE os_ol_quantity INTEGER;	
DECLARE os_ol_amount DECIMAL(6,2);
DECLARE os_ol_delivery_d TIMESTAMP;
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
WHILE loop_counter <= (namecnt/2) DO
FETCH FROM c_name
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
SELECT o_id, o_carrier_id, o_entry_d
INTO os_o_id, os_o_carrier_id, os_entdate
FROM
(SELECT o_id, o_carrier_id, o_entry_d
FROM orders where o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id = os_c_id
ORDER BY o_id DESC FETCH FIRST 1 ROW ONLY);
IF SQLSTATE = '02000'
THEN 
SET os_c_first = 'NO CUST ORDERS';
END IF;
OPEN c_line;
FETCH FROM c_line INTO os_ol_i_id, os_ol_supply_w_id, os_ol_quantity, os_ol_amount, os_ol_delivery_d;
WHILE (SQLSTATE = '00000') DO
FETCH FROM c_line INTO os_ol_i_id, os_ol_supply_w_id, os_ol_quantity, os_ol_amount, os_ol_delivery_d;
END WHILE;
CLOSE c_line;
END }
set sql(6) { CREATE OR REPLACE PROCEDURE SLEV (
IN st_w_id			INTEGER,
IN st_d_id			INTEGER,
IN threshold 			INTEGER, 
OUT stock_count			INTEGER
)
READS SQL DATA NO EXTERNAL ACTION DETERMINISTIC LANGUAGE SQL
BEGIN
DECLARE st_o_id			INTEGER;	
SELECT d_next_o_id INTO st_o_id
FROM district
WHERE d_w_id=st_w_id AND d_id=st_d_id;
SELECT COUNT(DISTINCT (s_i_id)) INTO stock_count
FROM order_line, stock
WHERE ol_w_id = st_w_id AND
ol_d_id = st_d_id AND (ol_o_id < st_o_id) AND
ol_o_id >= (st_o_id - 20) AND s_w_id = st_w_id AND
s_i_id = ol_i_id AND s_quantity < threshold WITH CS;
END }
for { set i 1 } { $i <= 6 } { incr i } {
db2_exec_direct $db_handle $sql($i)
    }
return
}

proc CreateDb2GlobalVars  { db_handle } {
puts "CREATING Db2 GLOBAL VARIABLES"
foreach vars {{no_c_discount DECIMAL(4,4)} {no_c_last VARCHAR(16)} {no_c_credit VARCHAR(2)} {no_d_tax DECIMAL(4,4)} {no_w_tax DECIMAL(4,4)} {no_d_next_o_id INTEGER} {p_c_id INTEGER} {p_c_last VARCHAR(16)} {p_w_street_1 VARCHAR(20)} {p_w_street_2 VARCHAR(20)} {p_w_city VARCHAR(20)} {p_w_state CHAR(2)} {p_w_zip CHAR(9)} {p_d_street_1 VARCHAR(20)} {p_d_street_2 VARCHAR(20)} {p_d_city VARCHAR(20)} {p_d_state CHAR(2)} {p_d_zip CHAR(9)} {p_c_first VARCHAR(16)} {p_c_middle CHAR(2)} {p_c_street_1 VARCHAR(20)} {p_c_street_2 VARCHAR(20)} {p_c_city VARCHAR(20)} {p_c_state CHAR(2)} {p_c_zip CHAR(9)} {p_c_phone CHAR(16)} {p_c_since TIMESTAMP} {p_c_credit CHAR(2)} {p_c_credit_lim DECIMAL(12, 2)} {p_c_discount DECIMAL(4,4)} {p_c_balance DECIMAL(12, 2)} {p_c_data VARCHAR(500)} {os_c_id INTEGER} {os_c_last VARCHAR(16)} {os_c_first VARCHAR(16)} {os_c_middle CHAR(2)} {os_c_balance DECIMAL(12, 2)} {os_o_id INTEGER} {os_entdate TIMESTAMP} {os_o_carrier_id INTEGER} {stock_count INTEGER} {deliv_data DELIVARRAY}} {
db2_exec_direct $db_handle "CREATE OR REPLACE VARIABLE $vars"
        }
}

proc GatherStatistics { db_handle num_part } {
puts "GATHERING SCHEMA STATISTICS"
set sql(1) "call admin_cmd('runstats on table warehouse with distribution and detailed indexes all')"
set sql(2) "call admin_cmd('runstats on table district with distribution and detailed indexes all')"
set sql(3) "call admin_cmd('runstats on table new_order with distribution and detailed indexes all')"
set sql(4) "call admin_cmd('runstats on table history with distribution and detailed indexes all')"
set sql(5) "call admin_cmd('runstats on table item with distribution and detailed indexes all')"
for { set i 1 } { $i <= 5 } { incr i } {
puts -nonewline "$i.."
db2_exec_direct $db_handle $sql($i)
    }
if { $num_part eq 0 } {
set sql(1) "call admin_cmd('runstats on table customer with distribution and detailed indexes all')"
set sql(2) "call admin_cmd('runstats on table orders with distribution and detailed indexes all')"
set sql(3) "call admin_cmd('runstats on table order_line with distribution and detailed indexes all')"
set sql(4) "call admin_cmd('runstats on table stock with distribution and detailed indexes all')"
for { set i 1 } { $i <= 4 } { incr i } {
puts -nonewline "$i.."
db2_exec_direct $db_handle $sql($i)
    	} 
    } else {
set partidx [ list a b c d e f g h i j ]
for { set p 1 } { $p <= 10 } { incr p } {
set idx [ lindex $partidx [ expr $p - 1]]
db2_exec_direct $db_handle "call admin_cmd('runstats on table customer_$p with distribution and detailed indexes all')"
db2_exec_direct $db_handle "call admin_cmd('runstats on table orders_$p with distribution and detailed indexes all')"
db2_exec_direct $db_handle "call admin_cmd('runstats on table order_line_$p with distribution and detailed indexes all')"
db2_exec_direct $db_handle "call admin_cmd('runstats on table stock_$p with distribution and detailed indexes all')"
	}
     }
puts "Statistics Complete"
return
}

proc ConnectToDb2 { dbname user password } {
puts "Connecting to database $dbname"
if {[catch {set db_handle [db2_connect $dbname $user $password ]} message]} {
error $message
 } else {
puts "Connection established"
return $db_handle
}}

proc CreateTables { db_handle num_part count_ware tspace_dict } {
puts "CREATING TPCC TABLES"
set sql(2) "CREATE TABLE DISTRICT (D_NEXT_O_ID INTEGER, D_TAX REAL, D_YTD DECIMAL(12, 2), D_NAME CHAR(10), D_STREET_1 CHAR(20), D_STREET_2 CHAR(20), D_CITY CHAR(20), D_STATE CHAR(2), D_ZIP CHAR(9), D_ID SMALLINT NOT NULL, D_W_ID INTEGER NOT NULL) IN [ dict get $tspace_dict D ] INDEX IN [ dict get $tspace_dict D ] ORGANIZE BY KEY SEQUENCE ( D_ID STARTING FROM 1 ENDING AT 10, D_W_ID STARTING FROM 1 ENDING AT $count_ware ) ALLOW OVERFLOW"
set sql(3) "CREATE TABLE HISTORY (H_C_ID INTEGER, H_C_D_ID SMALLINT, H_C_W_ID INTEGER, H_D_ID SMALLINT, H_W_ID INTEGER, H_DATE TIMESTAMP, H_AMOUNT DECIMAL(6,2), H_DATA CHAR(24)) IN [ dict get $tspace_dict H ] INDEX IN [ dict get $tspace_dict H ]"
set sql(4) "CREATE TABLE ITEM (I_NAME CHAR(24) NOT NULL, I_PRICE DECIMAL(5,2) NOT NULL, I_DATA VARCHAR(50) NOT NULL, I_IM_ID INTEGER NOT NULL, I_ID INTEGER NOT NULL) IN [ dict get $tspace_dict I ] INDEX IN [ dict get $tspace_dict I ] ORGANIZE BY KEY SEQUENCE ( I_ID STARTING FROM 1 ENDING AT 100000) ALLOW OVERFLOW"
set sql(5) "CREATE TABLE WAREHOUSE (W_NAME CHAR(10), W_STREET_1 CHAR(20), W_STREET_2 CHAR(20), W_CITY CHAR(20), W_STATE CHAR(2), W_ZIP CHAR(9), W_TAX REAL, W_YTD DECIMAL(12, 2), W_ID INTEGER NOT NULL) IN [ dict get $tspace_dict W ] INDEX IN [ dict get $tspace_dict W ] ORGANIZE BY KEY SEQUENCE ( W_ID STARTING FROM 1 ENDING AT $count_ware ) ALLOW OVERFLOW"
set sql(7) "CREATE TABLE NEW_ORDER (NO_W_ID INTEGER NOT NULL, NO_D_ID SMALLINT NOT NULL, NO_O_ID INTEGER NOT NULL, PRIMARY KEY (NO_W_ID, NO_D_ID, NO_O_ID)) IN [ dict get $tspace_dict NO ] INDEX IN [ dict get $tspace_dict NO ]"
if {$num_part eq 0} {
set sql(1) "CREATE TABLE CUSTOMER (C_ID INTEGER NOT NULL, C_D_ID SMALLINT NOT NULL, C_W_ID INTEGER NOT NULL, C_FIRST VARCHAR(16), C_MIDDLE CHAR(2), C_LAST VARCHAR(16), C_STREET_1 VARCHAR(20), C_STREET_2 VARCHAR(20), C_CITY VARCHAR(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE TIMESTAMP, C_CREDIT CHAR(2), C_CREDIT_LIM DECIMAL(12, 2), C_DISCOUNT REAL, C_BALANCE NUMERIC(12, 2), C_YTD_PAYMENT NUMERIC(12, 2), C_PAYMENT_CNT NUMERIC(8,0), C_DELIVERY_CNT INTEGER, C_DATA VARCHAR(500)) IN [ dict get $tspace_dict C ] INDEX IN [ dict get $tspace_dict C ] ORGANIZE BY KEY SEQUENCE ( C_ID STARTING FROM 1 ENDING AT 3000, C_W_ID STARTING FROM 1 ENDING at $count_ware, C_D_ID STARTING FROM 1 ENDING AT 10 ) ALLOW OVERFLOW"
set sql(6) "CREATE TABLE STOCK (S_REMOTE_CNT INTEGER, S_QUANTITY INTEGER, S_ORDER_CNT INTEGER, S_YTD INTEGER, S_DATA VARCHAR(50), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_I_ID INTEGER NOT NULL, S_W_ID INTEGER NOT NULL) IN [ dict get $tspace_dict S ] INDEX IN [ dict get $tspace_dict S ] ORGANIZE BY KEY SEQUENCE ( S_I_ID STARTING FROM 1 ENDING AT 100000, S_W_ID STARTING FROM 1 ENDING at $count_ware ) ALLOW OVERFLOW"
set sql(8) "CREATE TABLE ORDERS (O_ID INTEGER NOT NULL, O_W_ID INTEGER NOT NULL, O_D_ID SMALLINT NOT NULL, O_C_ID INTEGER, O_CARRIER_ID SMALLINT, O_OL_CNT SMALLINT, O_ALL_LOCAL SMALLINT, O_ENTRY_D TIMESTAMP, PRIMARY KEY (O_ID, O_W_ID, O_D_ID)) IN [ dict get $tspace_dict OR ] INDEX IN [ dict get $tspace_dict OR ]"
set sql(9) "CREATE TABLE ORDER_LINE (OL_W_ID INTEGER NOT NULL, OL_D_ID SMALLINT NOT NULL, OL_O_ID INTEGER NOT NULL, OL_NUMBER SMALLINT NOT NULL, OL_I_ID INTEGER, OL_DELIVERY_D TIMESTAMP, OL_AMOUNT DECIMAL(6,2), OL_SUPPLY_W_ID INTEGER, OL_QUANTITY SMALLINT, OL_DIST_INFO CHAR(24), PRIMARY KEY (OL_O_ID, OL_W_ID, OL_D_ID, OL_NUMBER)) IN [ dict get $tspace_dict OL ] INDEX IN [ dict get $tspace_dict OL ]"
	} else {
#Manual Partition Db2
set partdiv [ expr round(ceil(double($count_ware)/10)) ]
set partidx [ list a b c d e f g h i j ]
for { set p 1 } { $p <= 10 } { incr p } {
set startpart [ expr (($partdiv * $p)-$partdiv) + 1 ]
set endpart [ expr $partdiv * $p ]
set idx [ lindex $partidx [ expr $p - 1]]
set sql(1$idx) "CREATE TABLE CUSTOMER_$p (C_ID INTEGER NOT NULL, C_D_ID SMALLINT NOT NULL, C_W_ID INTEGER NOT NULL, C_FIRST VARCHAR(16), C_MIDDLE CHAR(2), C_LAST VARCHAR(16), C_STREET_1 VARCHAR(20), C_STREET_2 VARCHAR(20), C_CITY VARCHAR(20), C_STATE CHAR(2), C_ZIP CHAR(9), C_PHONE CHAR(16), C_SINCE TIMESTAMP, C_CREDIT CHAR(2), C_CREDIT_LIM DECIMAL(12, 2), C_DISCOUNT REAL, C_BALANCE NUMERIC(12, 2), C_YTD_PAYMENT NUMERIC(12, 2), C_PAYMENT_CNT NUMERIC(8,0), C_DELIVERY_CNT INTEGER, C_DATA VARCHAR(500)) IN [ dict get $tspace_dict C ] INDEX IN [ dict get $tspace_dict C ] ORGANIZE BY KEY SEQUENCE ( C_ID STARTING FROM 1 ENDING AT 3000, C_W_ID STARTING FROM $startpart ENDING at $endpart, C_D_ID STARTING FROM 1 ENDING AT 10 ) ALLOW OVERFLOW"
set sql(6$idx) "CREATE TABLE STOCK_$p (S_REMOTE_CNT INTEGER, S_QUANTITY INTEGER, S_ORDER_CNT INTEGER, S_YTD INTEGER, S_DATA VARCHAR(50), S_DIST_01 CHAR(24), S_DIST_02 CHAR(24), S_DIST_03 CHAR(24), S_DIST_04 CHAR(24), S_DIST_05 CHAR(24), S_DIST_06 CHAR(24), S_DIST_07 CHAR(24), S_DIST_08 CHAR(24), S_DIST_09 CHAR(24), S_DIST_10 CHAR(24), S_I_ID INTEGER NOT NULL, S_W_ID INTEGER NOT NULL) IN [ dict get $tspace_dict S ] INDEX IN [ dict get $tspace_dict S ] ORGANIZE BY KEY SEQUENCE ( S_I_ID STARTING FROM 1 ENDING AT 100000, S_W_ID STARTING FROM $startpart ENDING at $endpart ) ALLOW OVERFLOW"
set sql(8$idx) "CREATE TABLE ORDERS_$p (O_ID INTEGER NOT NULL, O_W_ID INTEGER NOT NULL, O_D_ID SMALLINT NOT NULL, O_C_ID INTEGER, O_CARRIER_ID SMALLINT, O_OL_CNT SMALLINT, O_ALL_LOCAL SMALLINT, O_ENTRY_D TIMESTAMP, PRIMARY KEY (O_ID, O_W_ID, O_D_ID)) IN [ dict get $tspace_dict OR ] INDEX IN [ dict get $tspace_dict OR ]"
set sql(9$idx) "CREATE TABLE ORDER_LINE_$p (OL_W_ID INTEGER NOT NULL, OL_D_ID SMALLINT NOT NULL, OL_O_ID INTEGER NOT NULL, OL_NUMBER SMALLINT NOT NULL, OL_I_ID INTEGER, OL_DELIVERY_D TIMESTAMP, OL_AMOUNT DECIMAL(6,2), OL_SUPPLY_W_ID INTEGER, OL_QUANTITY SMALLINT, OL_DIST_INFO CHAR(24), PRIMARY KEY (OL_O_ID, OL_W_ID, OL_D_ID, OL_NUMBER)) IN [ dict get $tspace_dict OL ] INDEX IN [ dict get $tspace_dict OL ]"
if { $idx eq "j" } {
#Last constraint
set sql(1$idx-CHECK) "ALTER TABLE CUSTOMER_$p ADD CONSTRAINT C_CHK_$p CHECK (C_W_ID >= $startpart)"
set sql(6$idx-CHECK) "ALTER TABLE STOCK_$p ADD CONSTRAINT ST_CHK_$p CHECK (S_W_ID >= $startpart)"
set sql(8$idx-CHECK) "ALTER TABLE ORDERS_$p ADD CONSTRAINT ORD_CHK_$p CHECK (O_W_ID >= $startpart)"
set sql(9$idx-CHECK) "ALTER TABLE ORDER_LINE_$p ADD CONSTRAINT OL_CHK_$p CHECK (OL_W_ID >= $startpart)"
        } else {
set sql(1$idx-CHECK) "ALTER TABLE CUSTOMER_$p ADD CONSTRAINT C_CHK_$p CHECK (C_W_ID BETWEEN $startpart AND $endpart)"
set sql(6$idx-CHECK) "ALTER TABLE STOCK_$p ADD CONSTRAINT ST_CHK_$p CHECK (S_W_ID BETWEEN $startpart AND $endpart)"
set sql(8$idx-CHECK) "ALTER TABLE ORDERS_$p ADD CONSTRAINT ORD_CHK_$p CHECK (O_W_ID BETWEEN $startpart AND $endpart)"
set sql(9$idx-CHECK) "ALTER TABLE ORDER_LINE_$p ADD CONSTRAINT OL_CHK_$p CHECK (OL_W_ID BETWEEN $startpart AND $endpart)"
                }
           }
set idx k
set sql(1$idx) "create view CUSTOMER AS "
set sql(6$idx) "create view STOCK AS "
set sql(8$idx) "create view ORDERS AS "
set sql(9$idx) "create view ORDER_LINE AS "
for { set p 1 } { $p <= 9 } { incr p } {
set startpart [ expr (($partdiv * $p)-$partdiv) + 1 ]
set endpart [ expr $partdiv * $p ]
set sql(1$idx) "$sql(1$idx) SELECT * FROM CUSTOMER_$p UNION ALL"
set sql(6$idx) "$sql(6$idx) SELECT * FROM STOCK_$p UNION ALL"
set sql(8$idx) "$sql(8$idx) SELECT * FROM ORDERS_$p UNION ALL"
set sql(9$idx) "$sql(9$idx) SELECT * FROM ORDER_LINE_$p UNION ALL"
                }
set p 10
set startpart [ expr (($partdiv * $p)-$partdiv) + 1 ]
set endpart [ expr $partdiv * $p ]
set sql(1$idx) "$sql(1$idx) SELECT * FROM CUSTOMER_$p WITH ROW MOVEMENT WITH CASCADED CHECK OPTION"
set sql(6$idx) "$sql(6$idx) SELECT * FROM STOCK_$p WITH ROW MOVEMENT WITH CASCADED CHECK OPTION"
set sql(8$idx) "$sql(8$idx) SELECT * FROM ORDERS_$p WITH ROW MOVEMENT WITH CASCADED CHECK OPTION"
set sql(9$idx) "$sql(9$idx) SELECT * FROM ORDER_LINE_$p WITH ROW MOVEMENT WITH CASCADED CHECK OPTION"
        }
for { set i 1 } { $i <= 9 } { incr i } {
if {(($i eq 1)||($i eq 9)||($i eq 6)||($i eq 8)) && $num_part eq 10 } {
set parttype $i
set partidx [ list a b c d e f g h i j k ]
for { set p 1 } { $p <= 11 } { incr p } {
set idx [ lindex $partidx [ expr $p - 1]]
db2_exec_direct $db_handle $sql($parttype$idx)
if { $idx != "k" } {
db2_exec_direct $db_handle $sql($parttype$idx-CHECK)
	}
     }
 } else {
db2_exec_direct $db_handle $sql($i)
    }
  }
}

proc CreateIndexes { db_handle num_part } {
puts "CREATING TPCC INDEXES"
#Db2 I1 indexes implemented as primary keys
set sql(1) "ALTER TABLE HISTORY APPEND ON"
set sql(2) "ALTER TABLE ITEM LOCKSIZE TABLE"
if { $num_part eq 0 } {
set stmt_cnt 5
set sql(3) "create index ORDERS_I2 on ORDERS (O_W_ID, O_D_ID, O_C_ID, O_ID)"
set sql(4) "create index CUSTOMER_I2 on CUSTOMER (C_LAST, C_W_ID, C_D_ID, C_FIRST, C_ID)"
set sql(5) "ALTER TABLE ORDER_LINE APPEND ON"
		} else {
set stmt_cnt 32
for { set p 1 } { $p <= 10 } { incr p } {
set sql([ expr $p + 2]) "create index ORDERS_I2_$p on ORDERS_$p (O_W_ID, O_D_ID, O_C_ID, O_ID)"
set sql([ expr $p + 12]) "create index CUSTOMER_I2_$p on CUSTOMER_$p (C_LAST, C_W_ID, C_D_ID, C_FIRST, C_ID)"
set sql([ expr $p + 22]) "ALTER TABLE ORDER_LINE_$p APPEND ON"
		}
	}
for { set i 1 } { $i <= $stmt_cnt } { incr i } {
db2_exec_direct $db_handle $sql($i)
	}
return
}

proc gettimestamp { } {
set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
return $tstamp
}

proc Customer { db_handle d_id w_id CUST_PER_DIST } {
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
proc date_function {} {
set df "timestamp_format('[ gettimestamp ]','YYYYMMDDHH24MISS')"
return $df
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
if { $bld_cnt<= 99 } { 
append c_val_list ,
append h_val_list ,
	}
incr bld_cnt
if { ![ expr {$c_id % 100} ] } {
db2_exec_direct $db_handle "insert into customer (c_id, c_d_id, c_w_id, c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_since, c_credit, c_credit_lim, c_discount, c_balance, c_data, c_ytd_payment, c_payment_cnt, c_delivery_cnt) values $c_val_list" 
db2_exec_direct $db_handle "insert into history (h_c_id, h_c_d_id, h_c_w_id, h_w_id, h_d_id, h_date, h_amount, h_data) values $h_val_list"
	set bld_cnt 1
	unset c_val_list
	unset h_val_list
		}
	}
puts "Customer Done"
return
}

proc Orders { db_handle d_id w_id MAXITEMS ORD_PER_DIST } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
set bld_cnt 1
proc date_function {} {
set df "timestamp_format('[ gettimestamp ]','YYYYMMDDHH24MISS')"
return $df
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
if { $bld_cnt<= 9 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	} else {
set amt_ran [ RandomNumber 10 10000 ]
set ol_amount [ expr {$amt_ran / 100.0} ]
set e "ol2"
append ol_val_list ('$o_id', '$o_d_id', '$o_w_id', '$ol', '$ol_i_id', '$ol_supply_w_id', '$ol_quantity', '$ol_amount', '$ol_dist_info', [ date_function ])
if { $bld_cnt<= 9 } { append ol_val_list , } else {
if { $ol != $o_ol_cnt } { append ol_val_list , }
		}
	}
}
if { $bld_cnt<= 9 } {
append o_val_list ,
if { $o_id > 2100 } {
append no_val_list ,
		}
        }
incr bld_cnt
 if { ![ expr {$o_id % 10} ] } {
 if { ![ expr {$o_id % 1000} ] } {
	puts "...$o_id"
	}
db2_exec_direct $db_handle "insert into orders (o_id, o_c_id, o_d_id, o_w_id, o_entry_d, o_carrier_id, o_ol_cnt, o_all_local) values $o_val_list"
if { $o_id > 2100 } {
db2_exec_direct $db_handle "insert into new_order (no_o_id, no_d_id, no_w_id) values $no_val_list"
	}
db2_exec_direct $db_handle "insert into order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info, ol_delivery_d) values $ol_val_list"
	set bld_cnt 1
	unset o_val_list
	unset -nocomplain no_val_list
	unset ol_val_list
			}
		}
	puts "Orders Done"
	return
}

proc LoadItems { db_handle MAXITEMS } {
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
db2_exec_direct $db_handle "insert into item (i_id, i_im_id, i_name, i_price, i_data) VALUES ('$i_id', '$i_im_id', '$i_name', '$i_price', '$i_data')"
      if { ![ expr {$i_id % 10000} ] } {
	puts "Loading Items - $i_id"
			}
		}
puts "Item done"
return
	}

proc Stock { db_handle w_id MAXITEMS } {
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
if { $bld_cnt<= 99 } { 
append val_list ,
}
incr bld_cnt
      if { ![ expr {$s_i_id % 100} ] } {
db2_exec_direct $db_handle "insert into stock (s_i_id, s_w_id, s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10, s_data, s_ytd, s_order_cnt, s_remote_cnt) values $val_list"
	set bld_cnt 1
	unset val_list
	}
      if { ![ expr {$s_i_id % 20000} ] } {
	puts "Loading Stock - $s_i_id"
			}
	}
	puts "Stock done"
	return
}

proc District { db_handle w_id DIST_PER_WARE } {
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
db2_exec_direct $db_handle "insert into district (d_id, d_w_id, d_name, d_street_1, d_street_2, d_city, d_state, d_zip, d_tax, d_ytd, d_next_o_id) values ('$d_id', '$d_w_id', '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', '$d_tax', '$d_ytd', '$d_next_o_id')"
	}
	puts "District done"
	return
}

proc LoadWare { db_handle ware_start count_ware MAXITEMS DIST_PER_WARE } {
set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
set chalen [ llength $globArray ]
puts "Loading Warehouse"
set w_ytd 3000000.00
for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
set add [ MakeAddress $globArray $chalen ]
set w_tax_ran [ RandomNumber 10 20 ]
set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
db2_exec_direct $db_handle "insert into warehouse (w_id, w_name, w_street_1, w_street_2, w_city, w_state, w_zip, w_tax, w_ytd) values ('$w_id', '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , '[ lindex $add 3 ]', '[ lindex $add 4 ]', '$w_tax', '$w_ytd')"
	Stock $db_handle $w_id $MAXITEMS
	District $db_handle $w_id $DIST_PER_WARE
	}
}

proc LoadCust { db_handle ware_start count_ware CUST_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Customer $db_handle $d_id $w_id $CUST_PER_DIST
		}
	}
	return
}

proc LoadOrd { db_handle ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE } {
for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
	Orders $db_handle $d_id $w_id $MAXITEMS $ORD_PER_DIST
		}
	}
	return
}
proc do_tpcc { dbname user password count_ware partition num_vu tpcc_def_tab tpcc_part_tabs} {
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
set db_handle [ ConnectToDb2 $dbname $user $password ]
if { $partition eq "true" && [ expr $count_ware >= 10 ] } {
set num_part 10
set tspace_dict $tpcc_part_tabs
dict for {tbl tblspc} $tspace_dict {
if { $tblspc eq "" } { dict set tspace_dict $tbl $tpcc_def_tab }
	}
	} else {
set num_part 0
#All tablespaces are default
set tspace_dict [ dict create ]
foreach tbl {C D H I W S NO OR OL} {
dict set tspace_dict $tbl $tpcc_def_tab
		}
	}
if { [ dict size $tspace_dict ] != 9 } {
error "Incorrect number of tablspaces defined"
	}
CreateTables $db_handle $num_part $count_ware $tspace_dict
if { $threaded eq "MULTI-THREADED" } {
tsv::set application load "READY"
LoadItems $db_handle $MAXITEMS
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
LoadItems $db_handle $MAXITEMS
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
if { $mtcnt eq 480 } { 
puts "Monitor failed to notify ready state" 
return
	}
}
after 5000 
}
set db_handle [ ConnectToDb2 $dbname $user $password ]
if { $partition eq "true" && [ expr $count_ware >= 10 ] } {
set num_part 10
	} else {
set num_part 0
	}
set remb [ lassign [ findchunk $num_vu $count_ware $myposition ] chunk mystart myend ]
puts "Loading $chunk Warehouses start:$mystart end:$myend"
tsv::lreplace common thrdlst $myposition $myposition active
} else {
set mystart 1
set myend $count_ware
}
puts "Start:[ clock format [ clock seconds ] ]"
LoadWare $db_handle $mystart $myend $MAXITEMS $DIST_PER_WARE
LoadCust $db_handle $mystart $myend $CUST_PER_DIST $DIST_PER_WARE 
LoadOrd $db_handle $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE
puts "End:[ clock format [ clock seconds ] ]"
db2_disconnect $db_handle
if { $threaded eq "MULTI-THREADED" } {
tsv::lreplace common thrdlst $myposition $myposition done
	}
}
if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
#108 Monitoring Virtual User disconnects during Db2 TPCC schema build
catch {db2_disconnect $db_handle}
set db_handle [ ConnectToDb2 $dbname $user $password ]
CreateIndexes $db_handle $num_part
CreateStoredProcs $db_handle 
CreateDb2GlobalVars $db_handle 
GatherStatistics $db_handle $num_part 
puts "[ string toupper $user ] SCHEMA COMPLETE"
db2_disconnect $db_handle
return
	}
    }
}
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "do_tpcc $db2_dbase $db2_user $db2_pass $db2_count_ware $db2_partition $db2_num_vu $db2_def_tab \{$db2_tab_list\}"
	} else { return }
}

proc insert_db2connectpool_drivescript { testtype timedtype } {
#When using connect pooling delete the existing portions of the script and replace with new connect pool version
set syncdrvt(1) {
#RUN TPC-C
#Get Connect data as a dict
set cpool [ get_connect_xml db2 ]
#Extract connect data only from dict
set connectonly [ dict filter [ dict get $cpool connections ] key c? ]
#Extract the keys, this will be c1, c2 etc and determines number of connections
set conkeys [ dict keys $connectonly ]
#Loop through the keys of the connection parameters
dict for {id conparams} $connectonly {
#Set the parameters to variables named from the keys, this allows us to build the connect strings according to the database
dict with conparams {
#set Db2 connect string
set $id [ list $db2_dbase $db2_user $db2_pass ]
        }
    }
#For the connect keys c1, c2 etc make a connection
foreach id [ split $conkeys ] {
        lassign [ set $id ] 1 2 3
dict set connlist $id [ set db_handle$id [ ConnectToDb2 $1 $2 $3 ] ]
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
#Prepare statements, select handles and global variables multiple times for stored procedure for each connection and add to cursor list
foreach stmnt_handle {stmnt_handle_no stmnt_handle_py stmnt_handle_dl stmnt_handle_sl stmnt_handle_os} cslist {csneworder cspayment csdelivery csstocklevel csorderstatus} cursor_list { neworder_cursors payment_cursors delivery_cursors stocklevel_cursors orderstatus_cursors } sel_handle {select_handle_no select_handle_py select_handle_dl select_handle_sl select_handle_os} sel_handle_list {neworder_selhandles payment_selhandles delivery_selhandles stocklevel_selhandles orderstatus_selhandles} gv_handle {set_handle_no set_handle_py set_handle_dl set_sl set_handle_os} gv_handle_list {neworder_gvhandles payment_gvhandles delivery_gvhandles stocklevel_gvhandles orderstatus_gvhandles} len { nolen pylen dllen sllen oslen } cnt { nocnt pycnt dlcnt slcnt oscnt } {
unset -nocomplain $cursor_list
unset -nocomplain $sel_handle_list
set curcnt 0
#For all of the connections
foreach db2sql [ join [ set $cslist ] ] {
#Create a cursor name
set cursor [ concat $stmnt_handle\_$curcnt ]
set select_hdl [ concat $sel_handle\_$curcnt ]
set set_hdl [ concat $gv_handle\_$curcnt ]
#Prepare a statement under the cursor name
set $cursor [ prep_statement $db2sql $stmnt_handle ]
#Prepare a select handle under the select handle name
set $select_hdl [ prep_select $db2sql $sel_handle ]
#Prepare a set handle under the global variable handle name
set $set_hdl [ prep_set_db2_global_var $db2sql $gv_handle ]
incr curcnt
#Add it to a list of cursors for that stored procedure
lappend $cursor_list [ set $cursor ]
#Add it to a list of select handles for that stored procedure
lappend $sel_handle_list [ set $select_hdl ]
#Add it to a list of set handles for  global variables
lappend $gv_handle_list [ set $set_hdl ]
        }
#Record the number of cursors
set $len [ llength  [ set $cursor_list ] ]
#Initialise number of executions 
set $cnt 0
#For delivery and stock level sprocs set handles are expected to be an empty list
#puts "sproc_cur:$stmnt_handle:$sel_handle:$gv_handle connections:[ set $cslist ] cursors:[set $cursor_list] select handles:[set $sel_handle_list] set handles:[set $gv_handle_list] number of cursors/select/global var handles:[set $len] execs:[set $cnt]"
    }
#Open standalone connect to determine highest warehouse id for all connections
set mdb_handle [ ConnectToDb2 $dbname $user $password ]
set stmnt_handle1 [ db2_select_direct $mdb_handle "select max(w_id) from warehouse" ] 
set w_id_input [ db2_fetchrow $stmnt_handle1 ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set stmnt_handle2 [ db2_select_direct $mdb_handle "select max(d_id) from district" ] 
set d_id_input [ db2_fetchrow $stmnt_handle2 ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
set stmnt_handle_no [ pick_cursor $neworder_policy $neworder_cursors $nocnt $nolen ]
#find cursor chosen and use select handle and set handle from same position
set cursor_position [ lsearch $neworder_cursors $stmnt_handle_no ]
set select_handle_no [ lindex $neworder_selhandles $cursor_position ]
set set_handle_no [ lindex $neworder_gvhandles $cursor_position ]
neword $set_handle_no $stmnt_handle_no $select_handle_no $w_id $w_id_input $RAISEERROR
incr nocnt
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
set stmnt_handle_py [ pick_cursor $payment_policy $payment_cursors $pycnt $pylen ]
#find cursor chosen and use select handle and set handle from same position
set cursor_position [ lsearch $payment_cursors $stmnt_handle_py ]
set select_handle_py [ lindex $payment_selhandles $cursor_position ]
set set_handle_py [ lindex $payment_gvhandles $cursor_position ]
payment $set_handle_py $stmnt_handle_py $select_handle_py $w_id $w_id_input $RAISEERROR
incr pycnt
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
set stmnt_handle_dl [ pick_cursor $delivery_policy $delivery_cursors $dlcnt $dllen ]
#find cursor chosen and use select handle from same position
set cursor_position [ lsearch $delivery_cursors $stmnt_handle_dl ]
set select_handle_dl [ lindex $delivery_selhandles $cursor_position ]
delivery $stmnt_handle_dl $select_handle_dl $w_id $RAISEERROR
incr dlcnt
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
set stmnt_handle_sl [ pick_cursor $stocklevel_policy $stocklevel_cursors $slcnt $sllen ]
#find cursor chosen and use select handle from same position
set cursor_position [ lsearch $stocklevel_cursors $stmnt_handle_sl ]
set select_handle_sl [ lindex $stocklevel_selhandles $cursor_position ]
slev $stmnt_handle_sl $select_handle_sl $w_id $stock_level_d_id $RAISEERROR 
incr slcnt
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
set stmnt_handle_os [ pick_cursor $orderstatus_policy $orderstatus_cursors $oscnt $oslen ]
#find cursor chosen and use select handle and set handle from same position
set cursor_position [ lsearch $orderstatus_cursors $stmnt_handle_os ]
set select_handle_os [ lindex $orderstatus_selhandles $cursor_position ]
set set_handle_os [ lindex $orderstatus_gvhandles $cursor_position ]
ostat $set_handle_os $stmnt_handle_os $select_handle_os $w_id $RAISEERROR
incr oscnt
if { $KEYANDTHINK } { thinktime 5 }
	}
}
foreach cursor $neworder_cursors { db2_finish $cursor }
foreach cursor $payment_cursors { db2_finish $cursor }
foreach cursor $delivery_cursors { db2_finish $cursor }
foreach cursor $stocklevel_cursors { db2_finish $cursor }
foreach cursor $orderstatus_cursors { db2_finish $cursor }
foreach handle $neworder_selhandles { db2_finish $handle }
foreach handle $payment_selhandles { db2_finish $handle }
foreach handle $delivery_selhandles { db2_finish $handle }
foreach handle $stocklevel_selhandles { db2_finish $handle }
foreach handle $orderstatus_selhandles { db2_finish $handle }
foreach gvhandle $neworder_gvhandles { db2_finish $gvhandle }
foreach gvhandle $payment_gvhandles { db2_finish $gvhandle }
foreach gvhandle $orderstatus_gvhandles { db2_finish $gvhandle }
foreach db_handle [ dict values $connlist ] { db2_disconnect $db_handle }
db2_disconnect $mdb_handle
}
#Find single connection start and end points
set syncdrvi(1a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "#RUN TPC-C" end ]
set syncdrvi(1b) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "db2_disconnect \$db_handle" end ]
#puts "indexes are $syncdrvi(1a) and $syncdrvi(1b)"
#Delete text from start and end points
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $syncdrvi(1a) $syncdrvi(1b)+1l
#Replace with connect pool version
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(1a) $syncdrvt(1)
if { $testtype eq "timed" } {
#Diff between test and time sync scripts are the "puts stored proc lines", output suppressed
foreach line { {puts "new order"} {puts "payment"} {puts "delivery"} {puts "stock level"} {puts "order status"} } {
#find start of line
set index [.ed_mainFrame.mainwin.textFrame.left.text search -backwards $line end ]
#delete to end of line including newline
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $index "$index lineend + 1 char"
		}
foreach line {{"Processing $total_iterations transactions without output suppressed..."}} timedline {{"Processing $total_iterations transactions with output suppressed..."}} {
set index [.ed_mainFrame.mainwin.textFrame.left.text search -backwards $line end ]
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $index "$index lineend + 1 char"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $index "$timedline \n"
		}
if { $timedtype eq "async" } {
set syncdrvt(3) {for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:neword" }
if { $KEYANDTHINK } { async_keytime 18  $clientname neword $async_verbose }
set stmnt_handle_no [ pick_cursor $neworder_policy $neworder_cursors $nocnt $nolen ]
#find cursor chosen and use select handle and set handle from same position
set cursor_position [ lsearch $neworder_cursors $stmnt_handle_no ]
set select_handle_no [ lindex $neworder_selhandles $cursor_position ]
set set_handle_no [ lindex $neworder_gvhandles $cursor_position ]
neword $set_handle_no $stmnt_handle_no $select_handle_no $w_id $w_id_input $RAISEERROR $clientname
incr nocnt
if { $KEYANDTHINK } { async_thinktime 12 $clientname neword $async_verbose }
} elseif {$choice <= 20} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:payment" }
if { $KEYANDTHINK } { async_keytime 3 $clientname payment $async_verbose }
set stmnt_handle_py [ pick_cursor $payment_policy $payment_cursors $pycnt $pylen ]
#find cursor chosen and use select handle and set handle from same position
set cursor_position [ lsearch $payment_cursors $stmnt_handle_py ]
set select_handle_py [ lindex $payment_selhandles $cursor_position ]
set set_handle_py [ lindex $payment_gvhandles $cursor_position ]
payment $set_handle_py $stmnt_handle_py $select_handle_py $w_id $w_id_input $RAISEERROR $clientname
incr pycnt
if { $KEYANDTHINK } { async_thinktime 12 $clientname payment $async_verbose }
} elseif {$choice <= 21} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:delivery" }
if { $KEYANDTHINK } { async_keytime 2 $clientname delivery $async_verbose }
set stmnt_handle_dl [ pick_cursor $delivery_policy $delivery_cursors $dlcnt $dllen ]
#find cursor chosen and use select handle from same position
set cursor_position [ lsearch $delivery_cursors $stmnt_handle_dl ]
set select_handle_dl [ lindex $delivery_selhandles $cursor_position ]
delivery $stmnt_handle_dl $select_handle_dl $w_id $RAISEERROR $clientname
incr dlcnt
if { $KEYANDTHINK } { async_thinktime 10 $clientname delivery $async_verbose }
} elseif {$choice <= 22} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:slev" }
if { $KEYANDTHINK } { async_keytime 2 $clientname slev $async_verbose }
set stmnt_handle_sl [ pick_cursor $stocklevel_policy $stocklevel_cursors $slcnt $sllen ]
#find cursor chosen and use select handle from same position
set cursor_position [ lsearch $stocklevel_cursors $stmnt_handle_sl ]
set select_handle_sl [ lindex $stocklevel_selhandles $cursor_position ]
slev $stmnt_handle_sl $select_handle_sl $w_id $stock_level_d_id $RAISEERROR $clientname
incr slcnt
if { $KEYANDTHINK } { async_thinktime 5 $clientname slev $async_verbose }
} elseif {$choice <= 23} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:ostat" }
if { $KEYANDTHINK } { async_keytime 2 $clientname ostat $async_verbose }
set stmnt_handle_os [ pick_cursor $orderstatus_policy $orderstatus_cursors $oscnt $oslen ]
#find cursor chosen and use select handle and set handle from same position
set cursor_position [ lsearch $orderstatus_cursors $stmnt_handle_os ]
set select_handle_os [ lindex $orderstatus_selhandles $cursor_position ]
set set_handle_os [ lindex $orderstatus_gvhandles $cursor_position ]
ostat $set_handle_os $stmnt_handle_os $select_handle_os $w_id $RAISEERROR $clientname
incr oscnt
if { $KEYANDTHINK } { async_thinktime 5 $clientname ostat $async_verbose }
	}
   }
}
set syncdrvi(3a) [.ed_mainFrame.mainwin.textFrame.left.text search -forwards "for {set it 0}" 1.0 ]
set syncdrvi(3b) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "foreach cursor \$neworder_cursors { db2_finish \$cursor }" end ]
#End of run loop is previous line
set syncdrvi(3b) [ expr $syncdrvi(3b) - 1 ]
#Delete run loop
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $syncdrvi(3a) $syncdrvi(3b)+1l
#Replace with asynchronous connect pool version
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(3a) $syncdrvt(3)
#Remove extra async connection
set syncdrvi(7a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "#Open standalone connect to determine highest warehouse id for all connections" end ]
set syncdrvi(7b) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards {set mdb_handle [ ConnectToDb2 $dbname $user $password ]} end ]
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $syncdrvi(7a) $syncdrvi(7b)+1l
#Replace individual lines for Asynch
foreach line {{set db_handle [ ConnectToDb2Asynch $dbname $user $password $RAISEERROR $clientname $async_verbose ]} {dict set connlist $id [ set db_handle$id [ ConnectToDb2 $1 $2 $3 ] ]} {#puts "sproc_cur:$stmnt_handle:$sel_handle:$gv_handle connections:[ set $cslist ] cursors:[set $cursor_list] select handles:[set $sel_handle_list] set handles:[set $gv_handle_list] number of cursors/select/global var handles:[set $len] execs:[set $cnt]"}} asynchline {{set mdb_handle [ ConnectToDb2Asynch $dbname $user $password $RAISEERROR $clientname $async_verbose ]} {dict set connlist $id [ set db_handle$id [ ConnectToDb2Asynch $1 $2 $3 $RAISEERROR $clientname $async_verbose ] ]} {#puts "$clientname:sproc_cur:$stmnt_handle:$sel_handle:$gv_handle connections:[ set $cslist ] cursors:[set $cursor_list] select handles:[set $sel_handle_list] set handles:[set $gv_handle_list] number of cursors/select/global var handles:[set $len] execs:[set $cnt]"}} {
set index [.ed_mainFrame.mainwin.textFrame.left.text search -backwards $line end ]
.ed_mainFrame.mainwin.textFrame.left.text fastdelete $index "$index lineend + 1 char"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $index "$asynchline \n"
                }
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
set syncdrvi(6a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards {foreach cursor $neworder_cursors { db2_finish $cursor }} end ]
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
set syncdrvi(6a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards {foreach cursor $neworder_cursors { db2_finish $cursor }} end ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(6a) $syncdrvt(6)
	}
    }
}

proc loaddb2tpcc {} {
global _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict db2 library ]} {
        set library [ dict get $dbdict db2 library ]
} else { set library "db2tcl" }
upvar #0 configdb2 configdb2
#set variables to values in dict
setlocaltpccvars $configdb2
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "Db2 TPROC-C"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# Db2 Library
set total_iterations $db2_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$db2_raiseerror\" ;# Exit script on Db2 Error (true or false)
set KEYANDTHINK \"$db2_keyandthink\" ;# Time for user thinking and keying (true or false)
set user \"$db2_user\" ;# Db2 user
set password \"$db2_pass\" ;# Password for the Db2 user
set dbname \"$db2_dbase\" ;#Database containing the TPC Schema
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

#Db2 CONNECTION
proc ConnectToDb2 { dbname user password } {
puts "Connecting to database $dbname"
if {[catch {set db_handle [db2_connect $dbname $user $password]} message]} {
error $message
 } else {
puts "Connection established"
return $db_handle
}}
#NEW ORDER
proc neword { set_handle_no stmnt_handle_no select_handle_no no_w_id w_id_input RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
db2_exec_prepared $set_handle_no
if {[ catch {db2_bind_exec $stmnt_handle_no "$no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt $date"} message]} {
if {$RAISEERROR} {
error "New Order: $message"
	}
	} else {
set stmnt_fetch [ db2_select_prepared $select_handle_no ]
puts "New Order: $no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt 0 [ db2_fetchrow $stmnt_fetch ]"
	}
}
#PAYMENT
proc payment { set_handle_py stmnt_handle_py select_handle_py p_w_id w_id_input RAISEERROR } {
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
set name NULL
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#change following to correct values
db2_bind_exec $set_handle_py "$p_c_id $name"
if {[ catch {db2_bind_exec $stmnt_handle_py "$p_w_id $p_d_id $p_c_w_id $p_c_d_id $byname $p_h_amount $h_date"} message]} {
if {$RAISEERROR} {
error "Payment: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_py ]
puts "Payment: $p_w_id $p_d_id $p_c_w_id $p_c_d_id $p_c_id $byname $p_h_amount $name 0 0 [ db2_fetchrow $stmnt_fetch ]"
	}
}
#ORDER_STATUS
proc ostat { set_handle_os stmnt_handle_os select_handle_os w_id RAISEERROR } {
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
set name NULL
}
db2_bind_exec $set_handle_os "$c_id $name"
if {[ catch {db2_bind_exec $stmnt_handle_os "$w_id $d_id $byname"} message]} {
if {$RAISEERROR} {
error "Order Status: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_os ]
puts "Order Status: $w_id $d_id $c_id $byname $name [ db2_fetchrow $stmnt_fetch ]"
	}
}
#DELIVERY
proc delivery { stmnt_handle_dl select_handle_dl w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if {[ catch {db2_bind_exec $stmnt_handle_dl "$w_id $carrier_id $date"} message]} {
if {$RAISEERROR} {
error "Delivery: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_dl ]
while {[set line [ db2_fetchrow $stmnt_fetch]] != ""} { lappend deliv_data $line }
}
puts "Delivery: $w_id $carrier_id $date $deliv_data"
}
#STOCK LEVEL
proc slev { stmnt_handle_sl select_handle_sl w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
if {[ catch {db2_bind_exec $stmnt_handle_sl "$w_id $stock_level_d_id $threshold"} message]} {
if {$RAISEERROR} {
error "Stock Level: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_sl ]
puts "Stock Level: $w_id $stock_level_d_id $threshold [ db2_fetchrow $stmnt_fetch ]"
	}
}

proc prep_statement { db_handle handle_st } {
set dummy "SYSIBM.SYSDUMMY1"
switch $handle_st {
stmnt_handle_sl {
set stmnt_handle_sl [ db2_prepare $db_handle "CALL SLEV(?,?,?,stock_count)" ]
return $stmnt_handle_sl
}
stmnt_handle_dl {
set stmnt_handle_dl [ db2_prepare $db_handle "CALL DELIVERY(?,?,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'),deliv_data)" ]
return $stmnt_handle_dl
	}
stmnt_handle_os {
set stmnt_handle_os [ db2_prepare $db_handle "CALL OSTAT (?,?,os_c_id,?,os_c_last,os_c_first,os_c_middle,os_c_balance,os_o_id,os_entdate,os_o_carrier_id)" ]
return $stmnt_handle_os
	}
stmnt_handle_py {
set stmnt_handle_py [ db2_prepare $db_handle "CALL PAYMENT (?,?,?,?,p_c_id,?,?,p_c_last,p_w_street_1,p_w_street_2,p_w_city,p_w_state,p_w_zip,p_d_street_1,p_d_street_2,p_d_city,p_d_state,p_d_zip,p_c_first,p_c_middle,p_c_street_1,p_c_street_2,p_c_city,p_c_state,p_c_zip,p_c_phone,p_c_since,p_c_credit,p_c_credit_lim,p_c_discount,p_c_balance,p_c_data,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'))" ]
return $stmnt_handle_py
	}
stmnt_handle_no {
set stmnt_handle_no [ db2_prepare $db_handle "CALL NEWORD (?,?,?,?,?,no_c_discount,no_c_last,no_c_credit,no_d_tax,no_w_tax,no_d_next_o_id,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'))" ]
return $stmnt_handle_no
	}
    }
}

proc prep_select { db_handle handle_se } {
set dummy "SYSIBM.SYSDUMMY1"
switch $handle_se {
select_handle_sl {
set select_handle_sl [ db2_prepare $db_handle "select stock_count from $dummy" ]
return $select_handle_sl
	}
select_handle_dl {
set select_handle_dl [ db2_prepare $db_handle "select * from UNNEST(deliv_data)" ]
return $select_handle_dl
     }
select_handle_os {
set select_handle_os [ db2_prepare $db_handle "select os_c_id, os_c_last, os_c_first,os_c_middle,os_c_balance,os_o_id,VARCHAR_FORMAT(os_entdate, 'YYYY-MM-DD HH24:MI:SS'),os_o_carrier_id from $dummy" ]
return $select_handle_os
	}
select_handle_py {
set select_handle_py [ db2_prepare $db_handle "select p_c_id,p_c_last,p_w_street_1,p_w_street_2,p_w_city,p_w_state,p_w_zip,p_d_street_1,p_d_street_2,p_d_city,p_d_state,p_d_zip,p_c_first,p_c_middle,p_c_street_1,p_c_street_2,p_c_city,p_c_state,p_c_zip,p_c_phone,VARCHAR_FORMAT(p_c_since, 'YYYY-MM-DD HH24:MI:SS'),p_c_credit,p_c_credit_lim,p_c_discount,p_c_balance,p_c_data from $dummy" ]
return $select_handle_py
	}
select_handle_no {
set select_handle_no [ db2_prepare $db_handle "select no_c_discount, no_c_last, no_c_credit, no_d_tax, no_w_tax, no_d_next_o_id from $dummy" ]
return $select_handle_no
	}
    }
}

proc prep_set_db2_global_var { db_handle handle_gv } {
switch $handle_gv {
set_handle_os {
set set_handle_os [ db2_prepare $db_handle "SET (os_c_id,os_c_last)=(?,?)" ]
return $set_handle_os
}
set_handle_py {
set set_handle_py [ db2_prepare $db_handle "SET (p_c_id,p_c_last,p_c_credit,p_c_balance)=(?,?,'0',0.0)" ]
return $set_handle_py
}
set_handle_no {
set set_handle_no [ db2_prepare $db_handle "SET (no_d_next_o_id)=(0)" ]
return $set_handle_no
       }
   }
}
#RUN TPC-C
set db_handle [ ConnectToDb2 $dbname $user $password ]
foreach handle_gv {set_handle_os set_handle_py set_handle_no} {set $handle_gv [ prep_set_db2_global_var $db_handle $handle_gv ]}
foreach handle_st {stmnt_handle_dl stmnt_handle_sl stmnt_handle_os stmnt_handle_py stmnt_handle_no} {set $handle_st [ prep_statement $db_handle $handle_st ]}
foreach handle_se {select_handle_sl select_handle_dl select_handle_os select_handle_py select_handle_no} {set $handle_se [ prep_select $db_handle $handle_se ]}
set stmnt_handle1 [ db2_select_direct $db_handle "select max(w_id) from warehouse" ] 
set w_id_input [ db2_fetchrow $stmnt_handle1 ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set stmnt_handle2 [ db2_select_direct $db_handle "select max(d_id) from district" ] 
set d_id_input [ db2_fetchrow $stmnt_handle2 ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
puts "new order"
if { $KEYANDTHINK } { keytime 18 }
neword $set_handle_no $stmnt_handle_no $select_handle_no $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
puts "payment"
if { $KEYANDTHINK } { keytime 3 }
payment $set_handle_py $stmnt_handle_py $select_handle_py $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
puts "delivery"
if { $KEYANDTHINK } { keytime 2 }
delivery $stmnt_handle_dl $select_handle_dl $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
puts "stock level"
if { $KEYANDTHINK } { keytime 2 }
slev $stmnt_handle_sl $select_handle_sl $w_id $stock_level_d_id $RAISEERROR 
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
puts "order status"
if { $KEYANDTHINK } { keytime 2 }
ostat $set_handle_os $stmnt_handle_os $select_handle_os $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
}
db2_finish $set_handle_os
db2_finish $set_handle_py
db2_finish $set_handle_no
db2_finish $stmnt_handle_sl
db2_finish $stmnt_handle_dl
db2_finish $stmnt_handle_os
db2_finish $stmnt_handle_py
db2_finish $stmnt_handle_no
db2_finish $select_handle_sl
db2_finish $select_handle_os
db2_finish $select_handle_py
db2_finish $select_handle_no
db2_finish $select_handle_dl
db2_disconnect $db_handle}
if { $db2_connect_pool } {
insert_db2connectpool_drivescript test sync
        }
}

proc loadtimeddb2tpcc {} {
global opmode _ED
upvar #0 dbdict dbdict
if {[dict exists $dbdict db2 library ]} {
        set library [ dict get $dbdict db2 library ]
} else { set library "db2tcl" }
upvar #0 configdb2 configdb2
#set variables to values in dict
setlocaltpccvars $configdb2
if { $db2_monreport >= $db2_duration } {
set db2_monreport 0
	}
ed_edit_clear
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
set _ED(packagekeyname) "Db2 TPROC-C Timed"
if { !$db2_async_scale } {
#REGULAR TIMED SCRIPT
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# Db2 Library
set total_iterations $db2_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$db2_raiseerror\" ;# Exit script on Db2 (true or false)
set KEYANDTHINK \"$db2_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $db2_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $db2_duration;  # Duration in minutes before second Transaction Count is taken
set monreportinterval $db2_monreport; #Portion of duration to capture monreport
set mode \"$opmode\" ;# HammerDB operational mode
set user \"$db2_user\" ;# Db2 user
set password \"$db2_pass\" ;# Password for the Db2 user
set dbname \"$db2_dbase\" ;#Database containing the TPC Schema
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

if { [ chk_thread ] eq "FALSE" } {
error "Db2 Timed Script must be run in Thread Enabled Interpreter"
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
set rema [ lassign [ findvuposition ] myposition totalvirtualusers ]
switch $myposition {
1 {
if { $mode eq "Local" || $mode eq "Primary" } {
set db_handle [ ConnectToDb2 $dbname $user $password ]
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
set stmnt_handle1 [ db2_select_direct $db_handle "select total_app_commits + total_app_rollbacks from sysibmadm.mon_db_summary" ]
set start_trans [ db2_fetchrow $stmnt_handle1 ]
db2_finish $stmnt_handle1
set stmnt_handle2 [ db2_select_direct $db_handle "select sum(d_next_o_id) from district" ]
set start_nopm [ db2_fetchrow $stmnt_handle2 ]
db2_finish $stmnt_handle2
set durmin $duration
set testtime 0
set doingmonreport "false"
if { $monreportinterval > 0 } { 
if { $monreportinterval >= $duration } { 
set monreportinterval 0 
puts "Timing test period of $duration in minutes"
	} else {
set doingmonreport "true"
set monreportsecs [ expr $monreportinterval * 60 ] 
set duration [ expr $duration - $monreportinterval ]
puts "Capturing MONREPORT DBSUMMARY for $monreportsecs seconds (This Virtual User cannot be terminated while capturing report)"
set monreport_handle [ db2_select_direct $db_handle "call monreport.dbsummary($monreportsecs)" ]
while {[set line [db2_fetchrow $monreport_handle]] != ""} {
append monreport [ join $line ] 
append monreport "\\n"
}
db2_finish $monreport_handle
puts "MONREPORT duration complete"
puts "Timing remaining test period of $duration in minutes"
}}
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
set stmnt_handle3 [ db2_select_direct $db_handle "select total_app_commits + total_app_rollbacks from sysibmadm.mon_db_summary" ]
set end_trans [ db2_fetchrow $stmnt_handle3 ]
db2_finish $stmnt_handle3
set stmnt_handle4 [ db2_select_direct $db_handle "select sum(d_next_o_id) from district" ]
set end_nopm [ db2_fetchrow $stmnt_handle4 ]
db2_finish $stmnt_handle4
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "[ expr $totalvirtualusers - 1 ] Active Virtual Users configured"
puts [ testresult $nopm $tpm Db2 ]
if { $doingmonreport eq "true" } {
puts "---MONREPORT OUTPUT---"
puts $monreport
	}
tsv::set application abort 1
if { $mode eq "Primary" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
db2_disconnect $db_handle
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
#Db2 CONNECTION
proc ConnectToDb2 { dbname user password } {
puts "Connecting to database $dbname"
if {[catch {set db_handle [db2_connect $dbname $user $password]} message]} {
error $message
 } else {
puts "Connection established"
return $db_handle
}}
#NEW ORDER
proc neword { set_handle_no stmnt_handle_no select_handle_no no_w_id w_id_input RAISEERROR } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
db2_exec_prepared $set_handle_no
if {[ catch {db2_bind_exec $stmnt_handle_no "$no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt $date"} message]} {
if {$RAISEERROR} {
error "New Order: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_no ]
	}
}
#PAYMENT
proc payment { set_handle_py stmnt_handle_py select_handle_py p_w_id w_id_input RAISEERROR } {
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
set name NULL
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#change following to correct values
db2_bind_exec $set_handle_py "$p_c_id $name"
if {[ catch {db2_bind_exec $stmnt_handle_py "$p_w_id $p_d_id $p_c_w_id $p_c_d_id $byname $p_h_amount $h_date"} message]} {
if {$RAISEERROR} {
error "Payment: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_py ]
	}
}
#ORDER_STATUS
proc ostat { set_handle_os stmnt_handle_os select_handle_os w_id RAISEERROR } {
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
set name NULL
}
db2_bind_exec $set_handle_os "$c_id $name"
if {[ catch {db2_bind_exec $stmnt_handle_os "$w_id $d_id $byname"} message]} {
if {$RAISEERROR} {
error "Order Status: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_os ]
	}
}
#DELIVERY
proc delivery { stmnt_handle_dl select_handle_dl w_id RAISEERROR } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if {[ catch {db2_bind_exec $stmnt_handle_dl "$w_id $carrier_id $date"} message]} {
if {$RAISEERROR} {
error "Delivery: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_dl ]
	}
}
#STOCK LEVEL
proc slev { stmnt_handle_sl select_handle_sl w_id stock_level_d_id RAISEERROR } {
set threshold [ RandomNumber 10 20 ]
if {[ catch {db2_bind_exec $stmnt_handle_sl "$w_id $stock_level_d_id $threshold"} message]} {
if {$RAISEERROR} {
error "Stock Level: $message"
        }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_sl ]
	}
}

proc prep_statement { db_handle handle_st } {
set dummy "SYSIBM.SYSDUMMY1"
switch $handle_st {
stmnt_handle_sl {
set stmnt_handle_sl [ db2_prepare $db_handle "CALL SLEV(?,?,?,stock_count)" ]
return $stmnt_handle_sl
}
stmnt_handle_dl {
set stmnt_handle_dl [ db2_prepare $db_handle "CALL DELIVERY(?,?,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'),deliv_data)" ]
return $stmnt_handle_dl
}
stmnt_handle_os {
set stmnt_handle_os [ db2_prepare $db_handle "CALL OSTAT (?,?,os_c_id,?,os_c_last,os_c_first,os_c_middle,os_c_balance,os_o_id,os_entdate,os_o_carrier_id)" ]
return $stmnt_handle_os
	}
stmnt_handle_py {
set stmnt_handle_py [ db2_prepare $db_handle "CALL PAYMENT (?,?,?,?,p_c_id,?,?,p_c_last,p_w_street_1,p_w_street_2,p_w_city,p_w_state,p_w_zip,p_d_street_1,p_d_street_2,p_d_city,p_d_state,p_d_zip,p_c_first,p_c_middle,p_c_street_1,p_c_street_2,p_c_city,p_c_state,p_c_zip,p_c_phone,p_c_since,p_c_credit,p_c_credit_lim,p_c_discount,p_c_balance,p_c_data,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'))" ]
return $stmnt_handle_py
	}
stmnt_handle_no {
set stmnt_handle_no [ db2_prepare $db_handle "CALL NEWORD (?,?,?,?,?,no_c_discount,no_c_last,no_c_credit,no_d_tax,no_w_tax,no_d_next_o_id,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'))" ]
return $stmnt_handle_no
	}
    }
}

proc prep_select { db_handle handle_se } {
set dummy "SYSIBM.SYSDUMMY1"
switch $handle_se {
select_handle_sl {
set select_handle_sl [ db2_prepare $db_handle "select stock_count from $dummy" ]
return $select_handle_sl
	}
select_handle_dl {
set select_handle_dl [ db2_prepare $db_handle "select * from UNNEST(deliv_data)" ]
return $select_handle_dl
        }
select_handle_os {
set select_handle_os [ db2_prepare $db_handle "select os_c_id, os_c_last, os_c_first,os_c_middle,os_c_balance,os_o_id,VARCHAR_FORMAT(os_entdate, 'YYYY-MM-DD HH24:MI:SS'),os_o_carrier_id from $dummy" ]
return $select_handle_os
	}
select_handle_py {
set select_handle_py [ db2_prepare $db_handle "select p_c_id,p_c_last,p_w_street_1,p_w_street_2,p_w_city,p_w_state,p_w_zip,p_d_street_1,p_d_street_2,p_d_city,p_d_state,p_d_zip,p_c_first,p_c_middle,p_c_street_1,p_c_street_2,p_c_city,p_c_state,p_c_zip,p_c_phone,VARCHAR_FORMAT(p_c_since, 'YYYY-MM-DD HH24:MI:SS'),p_c_credit,p_c_credit_lim,p_c_discount,p_c_balance,p_c_data from $dummy" ]
return $select_handle_py
	}
select_handle_no {
set select_handle_no [ db2_prepare $db_handle "select no_c_discount, no_c_last, no_c_credit, no_d_tax, no_w_tax, no_d_next_o_id from $dummy" ]
return $select_handle_no
	}
   }
}

proc prep_set_db2_global_var { db_handle handle_gv } {
switch $handle_gv {
set_handle_os {
set set_handle_os [ db2_prepare $db_handle "SET (os_c_id,os_c_last)=(?,?)" ]
return $set_handle_os
}
set_handle_py {
set set_handle_py [ db2_prepare $db_handle "SET (p_c_id,p_c_last,p_c_credit,p_c_balance)=(?,?,'0',0.0)" ]
return $set_handle_py
}
set_handle_no {
set set_handle_no [ db2_prepare $db_handle "SET (no_d_next_o_id)=(0)" ]
return $set_handle_no
       }
   }
}
#RUN TPC-C
set db_handle [ ConnectToDb2 $dbname $user $password ]
foreach handle_gv {set_handle_os set_handle_py set_handle_no} {set $handle_gv [ prep_set_db2_global_var $db_handle $handle_gv ]}
foreach handle_st {stmnt_handle_dl stmnt_handle_sl stmnt_handle_os stmnt_handle_py stmnt_handle_no} {set $handle_st [ prep_statement $db_handle $handle_st ]}
foreach handle_se {select_handle_sl select_handle_dl select_handle_os select_handle_py select_handle_no} {set $handle_se [ prep_select $db_handle $handle_se ]}
set stmnt_handle1 [ db2_select_direct $db_handle "select max(w_id) from warehouse" ] 
set w_id_input [ db2_fetchrow $stmnt_handle1 ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set stmnt_handle2 [ db2_select_direct $db_handle "select max(d_id) from district" ] 
set d_id_input [ db2_fetchrow $stmnt_handle2 ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $KEYANDTHINK } { keytime 18 }
neword $set_handle_no $stmnt_handle_no $select_handle_no $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 20} {
if { $KEYANDTHINK } { keytime 3 }
payment $set_handle_py $stmnt_handle_py $select_handle_py $w_id $w_id_input $RAISEERROR
if { $KEYANDTHINK } { thinktime 12 }
} elseif {$choice <= 21} {
if { $KEYANDTHINK } { keytime 2 }
delivery $stmnt_handle_dl $select_handle_dl $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 10 }
} elseif {$choice <= 22} {
if { $KEYANDTHINK } { keytime 2 }
slev $stmnt_handle_sl $select_handle_sl $w_id $stock_level_d_id $RAISEERROR 
if { $KEYANDTHINK } { thinktime 5 }
} elseif {$choice <= 23} {
if { $KEYANDTHINK } { keytime 2 }
ostat $set_handle_os $stmnt_handle_os $select_handle_os $w_id $RAISEERROR
if { $KEYANDTHINK } { thinktime 5 }
	}
  }
db2_finish $set_handle_os
db2_finish $set_handle_py
db2_finish $set_handle_no
db2_finish $stmnt_handle_sl
db2_finish $stmnt_handle_dl
db2_finish $stmnt_handle_os
db2_finish $stmnt_handle_py
db2_finish $stmnt_handle_no
db2_finish $select_handle_sl
db2_finish $select_handle_os
db2_finish $select_handle_py
db2_finish $select_handle_no
db2_finish $select_handle_dl
db2_disconnect $db_handle
	}
   }}
if { $db2_connect_pool } {
insert_db2connectpool_drivescript timed sync
        }
} else {
#ASYNCHRONOUS TIMED SCRIPT
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh8.6
#EDITABLE OPTIONS##################################################
set library $library ;# Db2 Library
set total_iterations $db2_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$db2_raiseerror\" ;# Exit script on Db2 (true or false)
set KEYANDTHINK \"$db2_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $db2_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $db2_duration;  # Duration in minutes before second Transaction Count is taken
set monreportinterval $db2_monreport; #Portion of duration to capture monreport
set mode \"$opmode\" ;# HammerDB operational mode
set user \"$db2_user\" ;# Db2 user
set password \"$db2_pass\" ;# Password for the Db2 user
set dbname \"$db2_dbase\" ;#Database containing the TPC Schema
set async_client $db2_async_client;# Number of asynchronous clients per Vuser
set async_verbose $db2_async_verbose;# Report activity of asynchronous clients
set async_delay $db2_async_delay;# Delay in ms between logins of asynchronous clients
#EDITABLE OPTIONS##################################################
"
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end {#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {::tcl::tm::path add modules} ] { error "Failed to find modules directory" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }
if [catch {package require promise } message] { error "Failed to load promise package for asynchronous clients" }

if { [ chk_thread ] eq "FALSE" } {
error "Db2 Timed Script must be run in Thread Enabled Interpreter"
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
set rema [ lassign [ findvuposition ] myposition totalvirtualusers ]
switch $myposition {
1 {
if { $mode eq "Local" || $mode eq "Primary" } {
set db_handle [ ConnectToDb2 $dbname $user $password ]
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
set stmnt_handle1 [ db2_select_direct $db_handle "select total_app_commits + total_app_rollbacks from sysibmadm.mon_db_summary" ]
set start_trans [ db2_fetchrow $stmnt_handle1 ]
db2_finish $stmnt_handle1
set stmnt_handle2 [ db2_select_direct $db_handle "select sum(d_next_o_id) from district" ]
set start_nopm [ db2_fetchrow $stmnt_handle2 ]
db2_finish $stmnt_handle2
set durmin $duration
set testtime 0
set doingmonreport "false"
if { $monreportinterval > 0 } { 
if { $monreportinterval >= $duration } { 
set monreportinterval 0 
puts "Timing test period of $duration in minutes"
	} else {
set doingmonreport "true"
set monreportsecs [ expr $monreportinterval * 60 ] 
set duration [ expr $duration - $monreportinterval ]
puts "Capturing MONREPORT DBSUMMARY for $monreportsecs seconds (This Virtual User cannot be terminated while capturing report)"
set monreport_handle [ db2_select_direct $db_handle "call monreport.dbsummary($monreportsecs)" ]
while {[set line [db2_fetchrow $monreport_handle]] != ""} {
append monreport [ join $line ] 
append monreport "\\n"
}
db2_finish $monreport_handle
puts "MONREPORT duration complete"
puts "Timing remaining test period of $duration in minutes"
}}
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
set stmnt_handle3 [ db2_select_direct $db_handle "select total_app_commits + total_app_rollbacks from sysibmadm.mon_db_summary" ]
set end_trans [ db2_fetchrow $stmnt_handle3 ]
db2_finish $stmnt_handle3
set stmnt_handle4 [ db2_select_direct $db_handle "select sum(d_next_o_id) from district" ]
set end_nopm [ db2_fetchrow $stmnt_handle4 ]
db2_finish $stmnt_handle4
set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
puts "[ expr $totalvirtualusers - 1 ] VU \* $async_client AC \= [ expr ($totalvirtualusers - 1) * $async_client ] Active Sessions configured"
puts [ testresult $nopm $tpm Db2 ]
if { $doingmonreport eq "true" } {
puts "---MONREPORT OUTPUT---"
puts $monreport
	}
tsv::set application abort 1
if { $mode eq "Primary" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
db2_disconnect $db_handle
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
#Db2 CONNECTION
proc ConnectToDb2Asynch { dbname user password RAISEERROR clientname async_verbose } {
puts "Connecting to database $dbname"
if {[catch {set db_handle [db2_connect $dbname $user $password]} message]} {
if { $RAISEERROR } {
puts "$clientname:login failed:$message"
return "$clientname:login failed:$message"
	} 
 } else {
if { $async_verbose } { puts "Connected $clientname:$db_handle" }
return $db_handle
}}
#NEW ORDER
proc neword { set_handle_no stmnt_handle_no select_handle_no no_w_id w_id_input RAISEERROR clientname } {
#2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
set no_d_id [ RandomNumber 1 10 ]
#2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
set no_c_id [ RandomNumber 1 3000 ]
#2.4.1.3 Items in the order randomly selected from 5 to 15
set ol_cnt [ RandomNumber 5 15 ]
#2.4.1.6 order entry date O_ENTRY_D generated by SUT
set date [ gettimestamp ]
db2_exec_prepared $set_handle_no
if {[ catch {db2_bind_exec $stmnt_handle_no "$no_w_id $w_id_input $no_d_id $no_c_id $ol_cnt $date"} message]} {
if {$RAISEERROR} {
error "New Order in $clientname : $message"
        } else {
puts "New Order in $clientname : $message"
	  }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_no ]
	}
}
#PAYMENT
proc payment { set_handle_py stmnt_handle_py select_handle_py p_w_id w_id_input RAISEERROR clientname } {
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
set name NULL
 }
#2.5.1.3 random amount from 1 to 5000
set p_h_amount [ RandomNumber 1 5000 ]
#2.5.1.4 date selected from SUT
set h_date [ gettimestamp ]
#2.5.2.1 Payment Transaction
#change following to correct values
db2_bind_exec $set_handle_py "$p_c_id $name"
if {[ catch {db2_bind_exec $stmnt_handle_py "$p_w_id $p_d_id $p_c_w_id $p_c_d_id $byname $p_h_amount $h_date"} message]} {
if {$RAISEERROR} {
error "Payment in $clientname : $message"
        } else {
puts "Payment in $clientname : $message"
	  }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_py ]
	}
}
#ORDER_STATUS
proc ostat { set_handle_os stmnt_handle_os select_handle_os w_id RAISEERROR clientname } {
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
set name NULL
}
db2_bind_exec $set_handle_os "$c_id $name"
if {[ catch {db2_bind_exec $stmnt_handle_os "$w_id $d_id $byname"} message]} {
	if {$RAISEERROR} {
error "Order Status in $clientname : $message"
        } else {
puts "Order Status in $clientname : $message"
	  }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_os ]
	}
}
#DELIVERY
proc delivery { stmnt_handle_dl select_handle_dl w_id RAISEERROR clientname } {
set carrier_id [ RandomNumber 1 10 ]
set date [ gettimestamp ]
if {[ catch {db2_bind_exec $stmnt_handle_dl "$w_id $carrier_id $date"} message]} {
	if {$RAISEERROR} {
error "Delivery in $clientname : $message"
        } else {
puts "Delivery in $clientname : $message"
	  }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_dl ]
	}
}
#STOCK LEVEL
proc slev { stmnt_handle_sl select_handle_sl w_id stock_level_d_id RAISEERROR clientname } {
set threshold [ RandomNumber 10 20 ]
if {[ catch {db2_bind_exec $stmnt_handle_sl "$w_id $stock_level_d_id $threshold"} message]} {
	if {$RAISEERROR} {
error "Stock Level in $clientname : $message"
        } else {
puts "Stock Level in $clientname : $message"
	  }
        } else {
set stmnt_fetch [ db2_select_prepared $select_handle_sl ]
	}
}

proc prep_statement { db_handle handle_st } {
set dummy "SYSIBM.SYSDUMMY1"
switch $handle_st {
stmnt_handle_sl {
set stmnt_handle_sl [ db2_prepare $db_handle "CALL SLEV(?,?,?,stock_count)" ]
return $stmnt_handle_sl
}
stmnt_handle_dl {
set stmnt_handle_dl [ db2_prepare $db_handle "CALL DELIVERY(?,?,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'),deliv_data)" ]
return $stmnt_handle_dl
}
stmnt_handle_os {
set stmnt_handle_os [ db2_prepare $db_handle "CALL OSTAT (?,?,os_c_id,?,os_c_last,os_c_first,os_c_middle,os_c_balance,os_o_id,os_entdate,os_o_carrier_id)" ]
return $stmnt_handle_os
	}
stmnt_handle_py {
set stmnt_handle_py [ db2_prepare $db_handle "CALL PAYMENT (?,?,?,?,p_c_id,?,?,p_c_last,p_w_street_1,p_w_street_2,p_w_city,p_w_state,p_w_zip,p_d_street_1,p_d_street_2,p_d_city,p_d_state,p_d_zip,p_c_first,p_c_middle,p_c_street_1,p_c_street_2,p_c_city,p_c_state,p_c_zip,p_c_phone,p_c_since,p_c_credit,p_c_credit_lim,p_c_discount,p_c_balance,p_c_data,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'))" ]
return $stmnt_handle_py
	}
stmnt_handle_no {
set stmnt_handle_no [ db2_prepare $db_handle "CALL NEWORD (?,?,?,?,?,no_c_discount,no_c_last,no_c_credit,no_d_tax,no_w_tax,no_d_next_o_id,TIMESTAMP_FORMAT(?,'YYYYMMDDHH24MISS'))" ]
return $stmnt_handle_no
	}
    }
}

proc prep_select { db_handle handle_se } {
set dummy "SYSIBM.SYSDUMMY1"
switch $handle_se {
select_handle_sl {
set select_handle_sl [ db2_prepare $db_handle "select stock_count from $dummy" ]
return $select_handle_sl
	}
select_handle_dl {
set select_handle_dl [ db2_prepare $db_handle "select * from UNNEST(deliv_data)" ]
return $select_handle_dl
        }
select_handle_os {
set select_handle_os [ db2_prepare $db_handle "select os_c_id, os_c_last, os_c_first,os_c_middle,os_c_balance,os_o_id,VARCHAR_FORMAT(os_entdate, 'YYYY-MM-DD HH24:MI:SS'),os_o_carrier_id from $dummy" ]
return $select_handle_os
	}
select_handle_py {
set select_handle_py [ db2_prepare $db_handle "select p_c_id,p_c_last,p_w_street_1,p_w_street_2,p_w_city,p_w_state,p_w_zip,p_d_street_1,p_d_street_2,p_d_city,p_d_state,p_d_zip,p_c_first,p_c_middle,p_c_street_1,p_c_street_2,p_c_city,p_c_state,p_c_zip,p_c_phone,VARCHAR_FORMAT(p_c_since, 'YYYY-MM-DD HH24:MI:SS'),p_c_credit,p_c_credit_lim,p_c_discount,p_c_balance,p_c_data from $dummy" ]
return $select_handle_py
	}
select_handle_no {
set select_handle_no [ db2_prepare $db_handle "select no_c_discount, no_c_last, no_c_credit, no_d_tax, no_w_tax, no_d_next_o_id from $dummy" ]
return $select_handle_no
	}
   }
}

proc prep_set_db2_global_var { db_handle handle_gv } {
switch $handle_gv {
set_handle_os {
set set_handle_os [ db2_prepare $db_handle "SET (os_c_id,os_c_last)=(?,?)" ]
return $set_handle_os
}
set_handle_py {
set set_handle_py [ db2_prepare $db_handle "SET (p_c_id,p_c_last,p_c_credit,p_c_balance)=(?,?,'0',0.0)" ]
return $set_handle_py
}
set_handle_no {
set set_handle_no [ db2_prepare $db_handle "SET (no_d_next_o_id)=(0)" ]
return $set_handle_no
       }
   }
}

#CONNECT ASYNC
promise::async simulate_client { clientname total_iterations user password dbname RAISEERROR KEYANDTHINK async_verbose async_delay } {
set acno [ expr [ string trimleft [ lindex [ split $clientname ":" ] 1 ] ac ] * $async_delay ]
if { $async_verbose } { puts "Delaying login of $clientname for $acno ms" } 
async_time $acno
if {  [ tsv::get application abort ]  } { return "$clientname:abort before login" }
if { $async_verbose } { puts "Logging in $clientname" }
set db_handle [ ConnectToDb2Asynch $dbname $user $password $RAISEERROR $clientname $async_verbose ]
#RUN TPC-C
foreach handle_gv {set_handle_os set_handle_py set_handle_no} {set $handle_gv [ prep_set_db2_global_var $db_handle $handle_gv ]}
foreach handle_st {stmnt_handle_dl stmnt_handle_sl stmnt_handle_os stmnt_handle_py stmnt_handle_no} {set $handle_st [ prep_statement $db_handle $handle_st ]}
foreach handle_se {select_handle_sl select_handle_dl select_handle_os select_handle_py select_handle_no} {set $handle_se [ prep_select $db_handle $handle_se ]}
set stmnt_handle1 [ db2_select_direct $db_handle "select max(w_id) from warehouse" ] 
set w_id_input [ db2_fetchrow $stmnt_handle1 ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set stmnt_handle2 [ db2_select_direct $db_handle "select max(d_id) from district" ] 
set d_id_input [ db2_fetchrow $stmnt_handle2 ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions with output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
set choice [ RandomNumber 1 23 ]
if {$choice <= 10} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:neword" }
if { $KEYANDTHINK } { async_keytime 18  $clientname neword $async_verbose }
neword $set_handle_no $stmnt_handle_no $select_handle_no $w_id $w_id_input $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 12 $clientname neword $async_verbose }
} elseif {$choice <= 20} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:payment" }
if { $KEYANDTHINK } { async_keytime 3 $clientname payment $async_verbose }
payment $set_handle_py $stmnt_handle_py $select_handle_py $w_id $w_id_input $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 12 $clientname payment $async_verbose }
} elseif {$choice <= 21} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:delivery" }
if { $KEYANDTHINK } { async_keytime 2 $clientname delivery $async_verbose }
delivery $stmnt_handle_dl $select_handle_dl $w_id $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 10 $clientname delivery $async_verbose }
} elseif {$choice <= 22} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:slev" }
if { $KEYANDTHINK } { async_keytime 2 $clientname slev $async_verbose }
slev $stmnt_handle_sl $select_handle_sl $w_id $stock_level_d_id $RAISEERROR $clientname 
if { $KEYANDTHINK } { async_thinktime 5 $clientname slev $async_verbose }
} elseif {$choice <= 23} {
if { $async_verbose } { puts "$clientname:w_id:$w_id:ostat" }
if { $KEYANDTHINK } { async_keytime 2 $clientname ostat $async_verbose }
ostat $set_handle_os $stmnt_handle_os $select_handle_os $w_id $RAISEERROR $clientname
if { $KEYANDTHINK } { async_thinktime 5 $clientname ostat $async_verbose }
	}
  }
db2_finish $set_handle_os
db2_finish $set_handle_py
db2_finish $set_handle_no
db2_finish $stmnt_handle_sl
db2_finish $stmnt_handle_dl
db2_finish $stmnt_handle_os
db2_finish $stmnt_handle_py
db2_finish $stmnt_handle_no
db2_finish $select_handle_sl
db2_finish $select_handle_os
db2_finish $select_handle_py
db2_finish $select_handle_no
db2_finish $select_handle_dl
db2_disconnect $db_handle
if { $async_verbose } { puts "$clientname:complete" }
return $clientname:complete
	  }
for {set ac 1} {$ac <= $async_client} {incr ac} { 
set clientdesc "vuser$myposition:ac$ac"
lappend clientlist $clientdesc
lappend clients [simulate_client $clientdesc $total_iterations $user $password $dbname $RAISEERROR $KEYANDTHINK $async_verbose $async_delay]
		}
puts "Started asynchronous clients:$clientlist"
set acprom [ promise::eventloop [ promise::all $clients ] ] 
puts "All asynchronous clients complete" 
if { $async_verbose } {
foreach client $acprom { puts $client }
      }
   }
}}
if { $db2_connect_pool } {
insert_db2connectpool_drivescript timed async
        }
}
}
