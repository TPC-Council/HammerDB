proc build_mariatpcc {} {
    global maxvuser suppo ntimes threadscreated _ED maria_ssl_options
    upvar #0 dbdict dbdict

    if {[dict exists $dbdict maria library ]} {
        set library [ dict get $dbdict maria library ]
    } else {
        set library "mariatcl" 
    }

    upvar #0 configmariadb configmariadb
    #set variables to values in dict
    setlocaltpccvars $configmariadb
    #If the options menu has been run under the GUI maria_ssl_options is set
    #If build is run under the GUI, CLI or WS maria_ssl_options is not set
    #Set it now if it doesn't exist
    if ![ info exists maria_ssl_options ] { check_maria_ssl $configmariadb } 
    if { ![string match windows $::tcl_platform(platform)] && ($maria_host eq "127.0.0.1" || [ string tolower $maria_host ] eq "localhost") && [ string tolower $maria_socket ] != "null" } { set maria_connector "$maria_host:$maria_socket" } else { 
        set maria_connector "$maria_host:$maria_port" 
    }

    if {[ tk_messageBox -title "Create Schema" -icon question -message "Ready to create a $maria_count_ware Warehouse MariaDB TPROC-C schema\nin host [string toupper $maria_connector] under user [ string toupper $maria_user ] in database [ string toupper $maria_dbase ] with storage engine [ string toupper $maria_storage_engine ]?" -type yesno ] == yes} { 
        if { $maria_num_vu eq 1 || $maria_count_ware eq 1 } {
            set maxvuser 1
        } else {
            set maxvuser [ expr $maria_num_vu + 1 ]
        }
        set suppo 1
        set ntimes 1
        ed_edit_clear
        set _ED(packagekeyname) "TPROC-C creation"
        if { [catch {load_virtual} message]} {
            puts "Failed to created thread for schema creation: $message"
            return
        }
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh9.0
#LOAD LIBRARIES AND MODULES
set library $library
"
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end {
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }
proc CreateStoredProcs { maria_handler } {
    puts "CREATING TPCC STORED PROCEDURES"
    set sql(1) {
        CREATE PROCEDURE `NEWORD` (
        no_w_id    INTEGER,
        no_max_w_id    INTEGER,
        no_d_id    INTEGER,
        no_c_id    INTEGER,
        no_o_ol_cnt    INTEGER,
        OUT no_c_discount   DECIMAL(4,4),
        OUT no_c_last     VARCHAR(16),
        OUT no_c_credit     VARCHAR(2),
        OUT no_d_tax     DECIMAL(4,4),
        OUT no_w_tax     DECIMAL(4,4),
        INOUT no_d_next_o_id   INTEGER,
        IN timestamp     DATETIME
        )
        BEGIN
        DECLARE no_ol_supply_w_id  INTEGER;
        DECLARE no_ol_i_id    INTEGER;
        DECLARE no_ol_quantity     INTEGER;
        DECLARE no_o_all_local     INTEGER;
        DECLARE o_id       INTEGER;
        DECLARE no_i_name    VARCHAR(24);
        DECLARE no_i_price    DECIMAL(5,2);
        DECLARE no_i_data    VARCHAR(50);
        DECLARE no_s_quantity    DECIMAL(6);
        DECLARE no_ol_amount    DECIMAL(6,2);
        DECLARE no_s_dist_01    CHAR(24);
        DECLARE no_s_dist_02    CHAR(24);
        DECLARE no_s_dist_03    CHAR(24);
        DECLARE no_s_dist_04    CHAR(24);
        DECLARE no_s_dist_05    CHAR(24);
        DECLARE no_s_dist_06    CHAR(24);
        DECLARE no_s_dist_07    CHAR(24);
        DECLARE no_s_dist_08    CHAR(24);
        DECLARE no_s_dist_09    CHAR(24);
        DECLARE no_s_dist_10    CHAR(24);
        DECLARE no_ol_dist_info   CHAR(24);
        DECLARE no_s_data       VARCHAR(50);
        DECLARE x        INTEGER;
        DECLARE rbk           INTEGER;
        DECLARE loop_counter    INT;
        DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
        DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
        DECLARE EXIT HANDLER FOR NOT FOUND ROLLBACK;
        SET no_o_all_local = 1;
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
        INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES (o_id, no_d_id, no_w_id, no_c_id, timestamp, no_o_ol_cnt, no_o_all_local);
        INSERT INTO new_order (no_o_id, no_d_id, no_w_id) VALUES (o_id, no_d_id, no_w_id);
        COMMIT;
        END 
    }
    set sql(2) { 
        CREATE PROCEDURE `DELIVERY`(
        d_w_id      INTEGER,
        d_o_carrier_id    INTEGER,
        IN timestamp     DATETIME
        )
        BEGIN
        DECLARE d_no_o_id  INTEGER;
        DECLARE current_rowid   INTEGER;
        DECLARE d_d_id      INTEGER;
        DECLARE d_c_id      INTEGER;
        DECLARE d_ol_total  INTEGER;
        DECLARE deliv_data  VARCHAR(100);
        DECLARE loop_counter    INT;
        DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
        DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
        SET loop_counter = 1;
        START TRANSACTION;
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
        set loop_counter = loop_counter + 1;
        END WHILE;
        COMMIT;
        END 
    }
    set sql(3) { 
        CREATE PROCEDURE `PAYMENT` (
        p_w_id      INTEGER,
        p_d_id      INTEGER,
        p_c_w_id    INTEGER,
        p_c_d_id    INTEGER,
        INOUT p_c_id    INTEGER,
        byname      INTEGER,
        p_h_amount    DECIMAL(6,2),
        INOUT p_c_last      VARCHAR(16),
        OUT p_w_street_1    VARCHAR(20),
        OUT p_w_street_2    VARCHAR(20),
        OUT p_w_city    VARCHAR(20),
        OUT p_w_state    CHAR(2),
        OUT p_w_zip    CHAR(9),
        OUT p_d_street_1  VARCHAR(20),
        OUT p_d_street_2  VARCHAR(20),
        OUT p_d_city    VARCHAR(20),
        OUT p_d_state    CHAR(2),
        OUT p_d_zip    CHAR(9),
        OUT p_c_first    VARCHAR(16),
        OUT p_c_middle    CHAR(2),
        OUT p_c_street_1  VARCHAR(20),
        OUT p_c_street_2  VARCHAR(20),
        OUT p_c_city    VARCHAR(20),
        OUT p_c_state    CHAR(2),
        OUT p_c_zip    CHAR(9),
        OUT p_c_phone    CHAR(16),
        OUT p_c_since    DATETIME,
        INOUT p_c_credit  CHAR(2),
        OUT p_c_credit_lim   DECIMAL(12,2),
        OUT p_c_discount  DECIMAL(4,4),
        INOUT p_c_balance   DECIMAL(12,2),
        OUT p_c_data    VARCHAR(500),
        IN timestamp    DATETIME
        )
        BEGIN
        DECLARE done      INT DEFAULT 0;
        DECLARE  namecnt    INTEGER;
        DECLARE p_d_name  VARCHAR(11);
        DECLARE p_w_name  VARCHAR(11);
        DECLARE p_c_new_data  VARCHAR(500);
        DECLARE h_data    VARCHAR(30);
        DECLARE loop_counter    INT;
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
        END 
    }
    set sql(4) {
        CREATE PROCEDURE `OSTAT` (
        os_w_id         INTEGER,
        os_d_id         INTEGER,
        INOUT os_c_id       INTEGER,
        byname          INTEGER,
        INOUT os_c_last     VARCHAR(16),
        OUT os_c_first      VARCHAR(16),
        OUT os_c_middle     CHAR(2),
        OUT os_c_balance    DECIMAL(12,2),
        OUT os_o_id       INTEGER,
        OUT os_entdate      DATETIME,
        OUT os_o_carrier_id   INTEGER
        )
        BEGIN 
        DECLARE  os_ol_i_id   INTEGER;
        DECLARE  os_ol_supply_w_id INTEGER;
        DECLARE  os_ol_quantity INTEGER;
        DECLARE  os_ol_amount   INTEGER;
        DECLARE  os_ol_delivery_d   DATETIME;
        DECLARE done      INT DEFAULT 0;
        DECLARE namecnt     INTEGER;
        DECLARE i         INTEGER;
        DECLARE loop_counter  INT;
        DECLARE no_order_status VARCHAR(100);
        DECLARE os_ol_i_id_array VARCHAR(200);
        DECLARE os_ol_supply_w_id_array VARCHAR(200);
        DECLARE os_ol_quantity_array VARCHAR(200);
        DECLARE os_ol_amount_array VARCHAR(200);
        DECLARE os_ol_delivery_d_array VARCHAR(420);
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
        START TRANSACTION;
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
        COMMIT;
        END
    }
    set sql(5) {
        CREATE PROCEDURE `SLEV` (
        st_w_id         INTEGER,
        st_d_id         INTEGER,
        threshold         INTEGER,
        OUT stock_count    INTEGER
        )
        BEGIN 
        DECLARE st_o_id     INTEGER;
        DECLARE `Constraint Violation` CONDITION FOR SQLSTATE '23000';
        DECLARE EXIT HANDLER FOR `Constraint Violation` ROLLBACK;
        DECLARE EXIT HANDLER FOR NOT FOUND ROLLBACK;
        START TRANSACTION;
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
        END
    }
    for { set i 1 } { $i <= 5 } { incr i } {
        mariaexec $maria_handler $sql($i)
    }
    return
}

proc ConnectToMaria { host port socket ssl_options user password } {
    global mariastatus
    #ssl_options is variable length so build a connectstring
    if { [ chk_socket $host $socket ] eq "TRUE" } {
	set use_socket "true"
	append connectstring " -socket $socket"
	 } else {
	set use_socket "false"
	append connectstring " -host $host -port $port"
	}
	foreach key [ dict keys $ssl_options ] {
	append connectstring " $key [ dict get $ssl_options $key ] "
	}
	append connectstring " -user $user"
	if { [ string tolower $password ] != "null" } {
	append connectstring " -password $password"
	}
	set login_command "mariaconnect [ dict get $connectstring ]"
	#eval the login command
        if [catch {set maria_handler [eval $login_command]}] {
		if $use_socket {
            puts "the local socket connection to $socket could not be established"
    } else {
            puts "the tcp connection to $host:$port could not be established"
    }
        set connected "false"
        } else {
        set connected "true"
        }
    if {$connected} {
        maria::autocommit $maria_handler 0
	catch {set ssl_status [ maria::sel $maria_handler "show session status like 'ssl_cipher'" -list ]}
	if { [ info exists ssl_status ] } {
	puts [ join $ssl_status ]
	}
        return $maria_handler
    } else {
        error $mariastatus(message)
        return
    }
}

proc GatherStatistics { maria_handler } {
    puts "GATHERING SCHEMA STATISTICS"
    set sql(1) "analyze table customer, district, history, item, new_order, orders, order_line, stock, warehouse"
    mariaexec $maria_handler $sql(1)
    return
}

proc CreateDatabase { maria_handler db } {
    puts "CHECKING IF DATABASE $db EXISTS"
    set db_exists [ maria::sel $maria_handler "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '$db'" -flatlist ]
    if { $db_exists } {
        set table_count [ maria::sel $maria_handler "SELECT COUNT(DISTINCT TABLE_NAME) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '$db'" -flatlist ]
        if { $table_count == 0 } {
            puts "Empty database $db exists"
            puts "Using existing empty Database $db for Schema build"
        } else {
            puts "Database $db exists but is not empty, specify a new or empty database name"
            return false
        }
    } else {
        puts "CREATING DATABASE $db"
        set sql(1) "SET FOREIGN_KEY_CHECKS = 0"
        set sql(2) "CREATE DATABASE IF NOT EXISTS `$db` CHARACTER SET latin1 COLLATE latin1_swedish_ci"
        for { set i 1 } { $i <= 2 } { incr i } {
            mariaexec $maria_handler $sql($i)
        }
    }
    return true
}

proc CreateTables { maria_handler maria_storage_engine num_part history_pk } {
    puts "CREATING TPCC TABLES"
    if { [ string toupper $maria_storage_engine ] eq "INNODB" && $history_pk } {
    set pkmin_version "10.3.3"
    set version [ lindex [ split [ list [ maria::sel $maria_handler "select version()" -list ] ] - ] 0 ]
    if { [ package vcompare $version $pkmin_version ]  eq -1 } {
            puts "Minimum MariaDB version for invisible PK is $pkmin_version"
            set history_pk "false"
    }
    } else {
    set history_pk "false"
    }
    set sql(1) "CREATE TABLE `customer` (
`c_id` INT(5) NOT NULL,
`c_d_id` INT(2) NOT NULL,
`c_w_id` INT(6) NOT NULL,
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
ENGINE = $maria_storage_engine"
    set sql(2) "CREATE TABLE `district` (
`d_id` INT(2) NOT NULL,
`d_w_id` INT(6) NOT NULL,
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
ENGINE = $maria_storage_engine"
if $history_pk {
    set sql(3) "CREATE TABLE `history` (
  `h_c_id` INT NULL,
  `h_c_d_id` INT NULL,
  `h_c_w_id` INT NULL,
  `h_d_id` INT NULL,
  `h_w_id` INT NULL,
  `h_date` DATETIME NULL,
  `h_amount` DECIMAL(6, 2) NULL,
  `h_data` VARCHAR(24) BINARY NULL,
  `id` INT NOT NULL AUTO_INCREMENT INVISIBLE,
PRIMARY KEY (`id`)
)
ENGINE = $maria_storage_engine"
        } else {
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
ENGINE = $maria_storage_engine"
	}
    set sql(4) "CREATE TABLE `item` (
`i_id` INT(6) NOT NULL,
`i_im_id` INT NULL,
`i_name` VARCHAR(24) BINARY NULL,
`i_price` DECIMAL(5, 2) NULL,
`i_data` VARCHAR(50) BINARY NULL,
PRIMARY KEY (`i_id`)
)
ENGINE = $maria_storage_engine"
    set sql(5) "CREATE TABLE `new_order` (
`no_w_id` INT NOT NULL,
`no_d_id` INT NOT NULL,
`no_o_id` INT NOT NULL,
PRIMARY KEY (`no_w_id`, `no_d_id`, `no_o_id`)
)
ENGINE = $maria_storage_engine"
    set sql(6) "CREATE TABLE `orders` (
`o_id` INT NOT NULL,
`o_w_id` INT NOT NULL,
`o_d_id` INT NOT NULL,
`o_c_id` INT NULL,
`o_carrier_id` INT NULL,
`o_ol_cnt` INT NULL,
`o_all_local` INT NULL,
`o_entry_d` DATETIME NULL,
PRIMARY KEY (`o_w_id`,`o_d_id`,`o_id`),
KEY o_w_id (`o_w_id`,`o_d_id`,`o_c_id`,`o_id`)
)
ENGINE = $maria_storage_engine"
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
ENGINE = $maria_storage_engine"
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
ENGINE = $maria_storage_engine
PARTITION BY HASH (`ol_w_id`)
PARTITIONS $num_part"
    }
    set sql(8) "CREATE TABLE `stock` (
`s_i_id` INT(6) NOT NULL,
`s_w_id` INT(6) NOT NULL,
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
ENGINE = $maria_storage_engine"
    set sql(9) "CREATE TABLE `warehouse` (
`w_id` INT(6) NOT NULL,
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
ENGINE = $maria_storage_engine"
    for { set i 1 } { $i <= 9 } { incr i } {
        mariaexec $maria_handler $sql($i)
    }
    return
}

proc gettimestamp { } {
    set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
    return $tstamp
}

proc Customer { maria_handler d_id w_id CUST_PER_DIST } {
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
            maria::exec $maria_handler "insert into customer (`c_id`, `c_d_id`, `c_w_id`, `c_first`, `c_middle`, `c_last`, `c_street_1`, `c_street_2`, `c_city`, `c_state`, `c_zip`, `c_phone`, `c_since`, `c_credit`, `c_credit_lim`, `c_discount`, `c_balance`, `c_data`, `c_ytd_payment`, `c_payment_cnt`, `c_delivery_cnt`) values $c_val_list"
            maria::exec $maria_handler "insert into history (`h_c_id`, `h_c_d_id`, `h_c_w_id`, `h_w_id`, `h_d_id`, `h_date`, `h_amount`, `h_data`) values $h_val_list"
            maria::commit $maria_handler
            set bld_cnt 1
            unset c_val_list
            unset h_val_list
        }
    }
    puts "Customer Done"
    return
}

proc Orders { maria_handler d_id w_id MAXITEMS ORD_PER_DIST } {
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
            maria::exec $maria_handler "insert into orders (`o_id`, `o_c_id`, `o_d_id`, `o_w_id`, `o_entry_d`, `o_carrier_id`, `o_ol_cnt`, `o_all_local`) values $o_val_list"
            if { $o_id > 2100 } {
                maria::exec $maria_handler "insert into new_order (`no_o_id`, `no_d_id`, `no_w_id`) values $no_val_list"
            }
            maria::exec $maria_handler "insert into order_line (`ol_o_id`, `ol_d_id`, `ol_w_id`, `ol_number`, `ol_i_id`, `ol_supply_w_id`, `ol_quantity`, `ol_amount`, `ol_dist_info`, `ol_delivery_d`) values $ol_val_list"
            maria::commit $maria_handler 
            set bld_cnt 1
            unset o_val_list
            unset -nocomplain no_val_list
            unset ol_val_list
        }
    }
    maria::commit $maria_handler 
    puts "Orders Done"
    return
}

proc LoadItems { maria_handler MAXITEMS } {
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
        maria::exec $maria_handler "insert into item (`i_id`, `i_im_id`, `i_name`, `i_price`, `i_data`) VALUES ('$i_id', '$i_im_id', '$i_name', '$i_price', '$i_data')"
        if { ![ expr {$i_id % 50000} ] } {
            puts "Loading Items - $i_id"
        }
    }
    maria::commit $maria_handler 
    puts "Item done"
    return
}

proc Stock { maria_handler w_id MAXITEMS } {
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
            maria::exec $maria_handler "insert into stock (`s_i_id`, `s_w_id`, `s_quantity`, `s_dist_01`, `s_dist_02`, `s_dist_03`, `s_dist_04`, `s_dist_05`, `s_dist_06`, `s_dist_07`, `s_dist_08`, `s_dist_09`, `s_dist_10`, `s_data`, `s_ytd`, `s_order_cnt`, `s_remote_cnt`) values $val_list"
            maria::commit $maria_handler
            set bld_cnt 1
            unset val_list
        }
        if { ![ expr {$s_i_id % 20000} ] } {
            puts "Loading Stock - $s_i_id"
        }
    }
    maria::commit $maria_handler
    puts "Stock done"
    return
}

proc District { maria_handler w_id DIST_PER_WARE } {
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
        maria::exec $maria_handler "insert into district (`d_id`, `d_w_id`, `d_name`, `d_street_1`, `d_street_2`, `d_city`, `d_state`, `d_zip`, `d_tax`, `d_ytd`, `d_next_o_id`) values ('$d_id', '$d_w_id', '$d_name', '[ lindex $d_add 0 ]', '[ lindex $d_add 1 ]', '[ lindex $d_add 2 ]', '[ lindex $d_add 3 ]', '[ lindex $d_add 4 ]', '$d_tax', '$d_ytd', '$d_next_o_id')"
    }
    maria::commit $maria_handler 
    puts "District done"
    return
}

proc LoadWare { maria_handler ware_start count_ware MAXITEMS DIST_PER_WARE } {
    set globArray [ list 0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z ]
    set chalen [ llength $globArray ]
    puts "Loading Warehouse"
    set w_ytd 300000.00
    for {set w_id $ware_start } {$w_id <= $count_ware } {incr w_id } {
        set w_name [ MakeAlphaString 6 10 $globArray $chalen ]
        set add [ MakeAddress $globArray $chalen ]
        set w_tax_ran [ RandomNumber 10 20 ]
        set w_tax [ string replace [ format "%.2f" [ expr {$w_tax_ran / 100.0} ] ] 0 0 "" ]
        maria::exec $maria_handler "insert into warehouse (`w_id`, `w_name`, `w_street_1`, `w_street_2`, `w_city`, `w_state`, `w_zip`, `w_tax`, `w_ytd`) values ('$w_id', '$w_name', '[ lindex $add 0 ]', '[ lindex $add 1 ]', '[ lindex $add 2 ]' , '[ lindex $add 3 ]', '[ lindex $add 4 ]', '$w_tax', '$w_ytd')"
        Stock $maria_handler $w_id $MAXITEMS
        District $maria_handler $w_id $DIST_PER_WARE
        maria::commit $maria_handler 
    }
}

proc LoadCust { maria_handler ware_start count_ware CUST_PER_DIST DIST_PER_WARE } {
    for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
        for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
            Customer $maria_handler $d_id $w_id $CUST_PER_DIST
        }
    }
    maria::commit $maria_handler 
    return
}

proc LoadOrd { maria_handler ware_start count_ware MAXITEMS ORD_PER_DIST DIST_PER_WARE } {
    for {set w_id $ware_start} {$w_id <= $count_ware } {incr w_id } {
        for {set d_id 1} {$d_id <= $DIST_PER_WARE } {incr d_id } {
            Orders $maria_handler $d_id $w_id $MAXITEMS $ORD_PER_DIST
        }
    }
    maria::commit $maria_handler 
    return
}

proc chk_socket { host socket } {
    if { ![string match windows $::tcl_platform(platform)] && ($host eq "127.0.0.1" || [ string tolower $host ] eq "localhost") && [ string tolower $socket ] != "null" } {
        return "TRUE"
    } else {
        return "FALSE"
    }
}

proc do_tpcc { host port socket ssl_options count_ware user password db maria_storage_engine partition history_pk num_vu } {
    global mariastatus
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
        puts "CREATING [ string toupper $db ] SCHEMA"
        set maria_handler [ ConnectToMaria $host $port $socket $ssl_options $user $password ]
        set db_created [ CreateDatabase $maria_handler $db ]
        if { !$db_created } {
            tsv::set application abort 1
            error "Database not created"
        }
        mariause $maria_handler $db
        maria::autocommit $maria_handler 0
        if { $partition eq "true" } {
            if {$count_ware < 200} {
                set num_part 0
            } else {
                set num_part [ expr round($count_ware/100) ]
            }
        } else {
            set num_part 0
        }
        CreateTables $maria_handler $maria_storage_engine $num_part $history_pk
        if { $threaded eq "MULTI-THREADED" } {
            tsv::set application load "READY"
            LoadItems $maria_handler $MAXITEMS
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
            }
        } else {
            LoadItems $maria_handler $MAXITEMS
        }
    }
    if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition != 1 } {
        if { $threaded eq "MULTI-THREADED" } {
            puts "Waiting for Monitor Thread..."
            set mtcnt 0
            while 1 {
                if { [ tsv::get application abort ] } { return }
                if { [ tsv::exists application load ] } {
                    incr mtcnt
                    if { [ tsv::get application load ] eq "READY" } { break }
                    if { $mtcnt eq 48 } {
                        puts "Monitor failed to notify ready state"
                        return
                    }
                }
                after 5000
            }
            set maria_handler [ ConnectToMaria $host $port $socket $ssl_options $user $password ]
            mariause $maria_handler $db
            set remb [ lassign [ findchunk $num_vu $count_ware $myposition ] chunk mystart myend ]
            puts "Loading $chunk Warehouses start:$mystart end:$myend"
            tsv::lreplace common thrdlst $myposition $myposition active
        } else {
            set mystart 1
            set myend $count_ware
        }
        puts "Start:[ clock format [ clock seconds ] ]"
        LoadWare $maria_handler $mystart $myend $MAXITEMS $DIST_PER_WARE
        LoadCust $maria_handler $mystart $myend $CUST_PER_DIST $DIST_PER_WARE
        LoadOrd $maria_handler $mystart $myend $MAXITEMS $ORD_PER_DIST $DIST_PER_WARE
        puts "End:[ clock format [ clock seconds ] ]"
        maria::commit $maria_handler
        if { $threaded eq "MULTI-THREADED" } {
            tsv::lreplace common thrdlst $myposition $myposition done
        }
    }
    if { $threaded eq "SINGLE-THREADED" || $threaded eq "MULTI-THREADED" && $myposition eq 1 } {
        CreateStoredProcs $maria_handler
        GatherStatistics $maria_handler
        puts "[ string toupper $db ] SCHEMA COMPLETE"
        mariaclose $maria_handler
        return
}
}
}
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end "do_tpcc $maria_host $maria_port $maria_socket {$maria_ssl_options} $maria_count_ware $maria_user [ quotemeta $maria_pass ] $maria_dbase $maria_storage_engine $maria_partition $maria_history_pk $maria_num_vu" 
    } else {
        return 
    }
}

proc insert_mariaconnectpool_drivescript { testtype timedtype } {
    #When using connect pooling delete the existing portions of the script and replace with new connect pool version
    set syncdrvt(1) {
        #RUN TPC-C
        #Maria connect pool uses prepared statements
        set prepare true
        #Get Connect data as a dict
        set cpool [ get_connect_xml maria ]
        #Extract connect data only from dict
        set connectonly [ dict filter [ dict get $cpool connections ] key c? ]
        #Extract the keys, this will be c1, c2 etc and determines number of connections
        set conkeys [ dict keys $connectonly ]
        #Loop through the keys of the connection parameters
        dict for {id conparams} $connectonly {
            #Set the parameters to variables named from the keys, this allows us to build the connect strings according to the database
            dict with conparams {
                #set Maria connect string
                set $id [ list $maria_host $maria_port $maria_socket $maria_ssl_options $maria_user $maria_pass $maria_dbase ]
            }
        }
        #For the connect keys c1, c2 etc make a connection
        foreach id [ split $conkeys ] {
            lassign [ set $id ] 1 2 3 4 5 6 7
            dict set connlist $id [ set maria_handler$id [ ConnectToMaria $1 $2 $3 $4 $5 $6 $7 ] ]
            if {  [ set maria_handler$id ] eq "Failed" } {
                puts "error, the database connection to $1 could not be established"
            }
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
        foreach st {neword_st payment_st delivery_st slev_st ostat_st} cslist {csneworder cspayment csdelivery csstocklevel csorderstatus} cursor_list { neworder_cursors payment_cursors delivery_cursors stocklevel_cursors orderstatus_cursors } len { nolen pylen dllen sllen oslen } cnt { nocnt pycnt dlcnt slcnt oscnt } {
            unset -nocomplain $cursor_list
            set curcnt 0
            #For all of the connections
            foreach maria_handler [ join [ set $cslist ] ] {
                #Create a cursor name
                set cursor [ concat $st\_$curcnt ]
                #Prepare a statement under the cursor name
                set $st [ prep_statement $maria_handler $st ]
                incr curcnt
                #Add it to a list of cursors for that stored procedure
                lappend $cursor_list $cursor
            }
            #Record the number of cursors
            set $len [ llength  [ set $cursor_list ] ]
            #Initialise number of executions 
            set $cnt 0
            #For Maria cursor names are placeholders to choose the correct policy. The placeholder is then used to select the connection. The prepared statements are always called neword_st, payment_st etc for each connection
            #puts "sproc_cur:$st connections:[ set $cslist ] cursors:[set $cursor_list] number of cursors:[set $len] execs:[set $cnt]"
        }
        #Open standalone connect to determine highest warehouse id for all connections
        set mmaria_handler [ ConnectToMaria $host $port $socket $ssl_options $user $password $db ]
        set w_id_input [ list [ maria::sel $mmaria_handler "select max(w_id) from warehouse" -list ] ]
        #2.4.1.1 set warehouse_id stays constant for a given terminal
        set w_id  [ RandomNumber 1 $w_id_input ]  
        set d_id_input [ list [ maria::sel $mmaria_handler "select max(d_id) from district" -list ] ]
        set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
        puts "Processing $total_iterations transactions without output suppressed..."
        set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
        for {set it 0} {$it < $total_iterations} {incr it} {
            if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
            set choice [ RandomNumber 1 23 ]
            if {$choice <= 10} {
                puts "new order"
                if { $KEYANDTHINK } { keytime 18 }
                set curn_no [ pick_cursor $neworder_policy [ join $neworder_cursors ] $nocnt $nolen ]
                set cursor_position [ lsearch $neworder_cursors $curn_no ]
                set maria_handler_no [ lindex [ join $csneworder ] $cursor_position ]
                neword $maria_handler_no $w_id $w_id_input $prepare $RAISEERROR
                incr nocnt
                if { $KEYANDTHINK } { thinktime 12 }
            } elseif {$choice <= 20} {
                puts "payment"
                if { $KEYANDTHINK } { keytime 3 }
                set curn_py [ pick_cursor $payment_policy [ join $payment_cursors ] $pycnt $pylen ]
                set cursor_position [ lsearch $payment_cursors $curn_py ]
                set maria_handler_py [ lindex [ join $cspayment ] $cursor_position ]
                payment $maria_handler_py $w_id $w_id_input $prepare $RAISEERROR
                incr pycnt
                if { $KEYANDTHINK } { thinktime 12 }
            } elseif {$choice <= 21} {
                puts "delivery"
                if { $KEYANDTHINK } { keytime 2 }
                set curn_dl [ pick_cursor $delivery_policy [ join $delivery_cursors ] $dlcnt $dllen ]
                set cursor_position [ lsearch $delivery_cursors $curn_dl ]
                set maria_handler_dl [ lindex [ join $csdelivery ] $cursor_position ]
                delivery $maria_handler_dl $w_id $prepare $RAISEERROR
                incr dlcnt
                if { $KEYANDTHINK } { thinktime 10 }
            } elseif {$choice <= 22} {
                puts "stock level"
                if { $KEYANDTHINK } { keytime 2 }
                set curn_sl [ pick_cursor $stocklevel_policy [ join $stocklevel_cursors ] $slcnt $sllen ]
                set cursor_position [ lsearch $stocklevel_cursors $curn_sl ]
                set maria_handler_sl [ lindex [ join $csstocklevel ] $cursor_position ]
                slev $maria_handler_sl $w_id $stock_level_d_id $prepare $RAISEERROR
                incr slcnt
                if { $KEYANDTHINK } { thinktime 5 }
            } elseif {$choice <= 23} {
                puts "order status"
                if { $KEYANDTHINK } { keytime 2 }
                set curn_os [ pick_cursor $orderstatus_policy [ join $orderstatus_cursors ] $oscnt $oslen ]
                set cursor_position [ lsearch $orderstatus_cursors $curn_os ]
                set maria_handler_os [ lindex [ join $csorderstatus ] $cursor_position ]
                ostat $maria_handler_os $w_id $prepare $RAISEERROR
                incr oscnt
                if { $KEYANDTHINK } { thinktime 5 }
            }
        }
        foreach maria_handler [ dict values $connlist ] { 
            if {$prepare} {
                foreach st {neword_st payment_st delivery_st slev_st ostat_st} {
                    catch {mariaexec $maria_handler "deallocate prepare $st"}
}
}
mariaclose $maria_handler
}
mariaclose $mmaria_handler
}
    #Find single connection start and end points
    set syncdrvi(1a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "#RUN TPC-C" end ]
    set syncdrvi(1b) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "mariaclose \$maria_handler" end ]
    #puts "indexes are $syncdrvi(1a) and $syncdrvi(1b)"
    #Delete text from start and end points
    #Bug introduced by reformatting of Tcl #292 remove +1l below
    .ed_mainFrame.mainwin.textFrame.left.text fastdelete $syncdrvi(1a) $syncdrvi(1b)+1l
    #.ed_mainFrame.mainwin.textFrame.left.text fastdelete $syncdrvi(1a) $syncdrvi(1b)
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
            set syncdrvt(3) {
                for {set it 0} {$it < $total_iterations} {incr it} {
                    if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
                    set choice [ RandomNumber 1 23 ]
                    if {$choice <= 10} {
                        if { $async_verbose } { puts "$clientname:w_id:$w_id:neword" }
                        if { $KEYANDTHINK } { async_keytime 18  $clientname neword $async_verbose }
                        set curn_no [ pick_cursor $neworder_policy [ join $neworder_cursors ] $nocnt $nolen ]
                        set cursor_position [ lsearch $neworder_cursors $curn_no ]
                        set maria_handler_no [ lindex [ join $csneworder ] $cursor_position ]
                        neword $maria_handler_no $w_id $w_id_input $prepare $RAISEERROR $clientname
                        incr nocnt
                        if { $KEYANDTHINK } { async_thinktime 12 $clientname neword $async_verbose }
                    } elseif {$choice <= 20} {
                        if { $async_verbose } { puts "$clientname:w_id:$w_id:payment" }
                        if { $KEYANDTHINK } { async_keytime 3 $clientname payment $async_verbose }
                        set curn_py [ pick_cursor $payment_policy [ join $payment_cursors ] $pycnt $pylen ]
                        set cursor_position [ lsearch $payment_cursors $curn_py ]
                        set maria_handler_py [ lindex [ join $cspayment ] $cursor_position ]
                        payment $maria_handler_py $w_id $w_id_input $prepare $RAISEERROR $clientname
                        incr pycnt
                        if { $KEYANDTHINK } { async_thinktime 12 $clientname payment $async_verbose }
                    } elseif {$choice <= 21} {
                        if { $async_verbose } { puts "$clientname:w_id:$w_id:delivery" }
                        if { $KEYANDTHINK } { async_keytime 2 $clientname delivery $async_verbose }
                        set curn_dl [ pick_cursor $delivery_policy [ join $delivery_cursors ] $dlcnt $dllen ]
                        set cursor_position [ lsearch $delivery_cursors $curn_dl ]
                        set maria_handler_dl [ lindex [ join $csdelivery ] $cursor_position ]
                        delivery $maria_handler_dl $w_id $prepare $RAISEERROR $clientname
                        incr dlcnt
                        if { $KEYANDTHINK } { async_thinktime 10 $clientname delivery $async_verbose }
                    } elseif {$choice <= 22} {
                        if { $async_verbose } { puts "$clientname:w_id:$w_id:slev" }
                        if { $KEYANDTHINK } { async_keytime 2 $clientname slev $async_verbose }
                        set curn_sl [ pick_cursor $stocklevel_policy [ join $stocklevel_cursors ] $slcnt $sllen ]
                        set cursor_position [ lsearch $stocklevel_cursors $curn_sl ]
                        set maria_handler_sl [ lindex [ join $csstocklevel ] $cursor_position ]
                        slev $maria_handler_sl $w_id $stock_level_d_id $prepare $RAISEERROR $clientname
                        incr slcnt
                        if { $KEYANDTHINK } { async_thinktime 5 $clientname slev $async_verbose }
                    } elseif {$choice <= 23} {
                        if { $async_verbose } { puts "$clientname:w_id:$w_id:ostat" }
                        if { $KEYANDTHINK } { async_keytime 2 $clientname ostat $async_verbose }
                        set curn_os [ pick_cursor $orderstatus_policy [ join $orderstatus_cursors ] $oscnt $oslen ]
                        set cursor_position [ lsearch $orderstatus_cursors $curn_os ]
                        set maria_handler_os [ lindex [ join $csorderstatus ] $cursor_position ]
                        ostat $maria_handler_os $w_id $prepare $RAISEERROR $clientname
                        incr oscnt
                        if { $KEYANDTHINK } { async_thinktime 5 $clientname ostat $async_verbose }
                    }
                }
            }
            set syncdrvi(3a) [.ed_mainFrame.mainwin.textFrame.left.text search -forwards "for {set it 0}" 1.0 ]
            set syncdrvi(3b) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "foreach maria_handler \[ dict values \$connlist \]" end ]
            #End of run loop is previous line
            set syncdrvi(3b) [ expr $syncdrvi(3b) - 1 ]
            #Delete run loop
	      if { [ string is entier $syncdrvi(3b) ] } {
            #CLI
            .ed_mainFrame.mainwin.textFrame.left.text fastdelete $syncdrvi(3a) $syncdrvi(3b)
                } else {
            #GUI
            .ed_mainFrame.mainwin.textFrame.left.text fastdelete $syncdrvi(3a) $syncdrvi(3b)+1l
                }
            #Replace with asynchronous connect pool version
            .ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(3a) $syncdrvt(3)
            #Remove extra async connection
            set syncdrvi(7a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "#Open standalone connect to determine highest warehouse id for all connections" end ]
            set syncdrvi(7b) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards {set mmaria_handler [ ConnectToMaria $host $port $socket $ssl_options $user $password $db ]} end ]
            .ed_mainFrame.mainwin.textFrame.left.text fastdelete $syncdrvi(7a) $syncdrvi(7b)+1l
            #Replace individual lines for Asynch
            foreach line {{set maria_handler [ ConnectToMariaAsynch $host $port $socket $ssl_options $user $password $db $clientname $async_verbose ]} {dict set connlist $id [ set maria_handler$id [ ConnectToMaria $1 $2 $3 $4 $5 $6 $7 ] ]} {#puts "sproc_cur:$st connections:[ set $cslist ] cursors:[set $cursor_list] number of cursors:[set $len] execs:[set $cnt]"}} asynchline {{set mmaria_handler [ ConnectToMariaAsynch $host $port $socket $ssl_options $user $password $db $clientname $async_verbose ]} {dict set connlist $id [ set maria_handler$id [ ConnectToMariaAsynch $1 $2 $3 $4 $5 $6 $7 $clientname $async_verbose ] ]} {#puts "$clientname:sproc_cur:$st connections:[ set $cslist ] cursors:[set $cursor_list] number of cursors:[set $len] execs:[set $cnt]"}} {
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
            set syncdrvi(6a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards {foreach maria_handler [ dict values $connlist ]} end ]
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
            set syncdrvi(6a) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards {foreach maria_handler [ dict values $connlist ]} end ]
            .ed_mainFrame.mainwin.textFrame.left.text fastinsert $syncdrvi(6a) $syncdrvt(6)
        }
    }
}

proc insert_maria_no_stored_procs { testtype timedtype } {
	#No stored procedure code is different in arguments and whether output is printed
	#for timed and test workloads and sync and async
	#body is the same
	#Build up procs so body is not repeated
	#Replace existing stored proc calls with client version
	if { $timedtype eq "sync" } {
	set newordargs "#NEW ORDER
    proc neword { maria_handler no_w_id w_id_input prepare RAISEERROR } \{
	"
	set payargs "#PAYMENT
    proc payment { maria_handler p_w_id w_id_input prepare RAISEERROR } \{
	"
	set ostatargs "#ORDER_STATUS
    proc ostat { maria_handler w_id prepare RAISEERROR } \{
	"
	set delivargs "#DELIVERY
    proc delivery { maria_handler w_id prepare RAISEERROR } \{
	"
	set stockargs "#STOCK LEVEL
    proc slev { maria_handler w_id stock_level_d_id prepare RAISEERROR } \{
	"
	} else {
	set newordargs "#NEW ORDER
    proc neword { maria_handler no_w_id w_id_input prepare RAISEERROR clientname} \{
	"
	set payargs "#PAYMENT
    proc payment { maria_handler p_w_id w_id_input prepare RAISEERROR clientname} \{
	"
	set ostatargs "#ORDER_STATUS
    proc ostat { maria_handler w_id prepare RAISEERROR clientname} \{
	"
	set delivargs "#DELIVERY
    proc delivery { maria_handler w_id prepare RAISEERROR clientname} \{
	"
	set stockargs "#STOCK LEVEL
    proc slev { maria_handler w_id stock_level_d_id prepare RAISEERROR clientname} \{
	"
	}

	set newordbody {
    global mariastatus
    #open new order cursor
    #2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
    set no_d_id [ RandomNumber 1 10 ]
    #2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
    set no_c_id [ RandomNumber 1 3000 ]
    #2.4.1.3 Items in the order randomly selected from 5 to 15
    set ol_cnt [ RandomNumber 5 15 ]
    #2.4.1.6 order entry date O_ENTRY_D generated by SUT
    set date [ gettimestamp ]
    set no_max_w_id $w_id_input

    set no_o_all_local 1
    set cust_ware [ maria::sel $maria_handler "SELECT c_discount, c_last, c_credit, w_tax FROM customer, warehouse WHERE warehouse.w_id = $no_w_id AND customer.c_w_id = $no_w_id AND customer.c_d_id = $no_d_id AND customer.c_id = $no_c_id" -flatlist ]
    lassign $cust_ware discount last credit wtax
    mariaexec $maria_handler "start transaction"
    set o_id_tax_list [ maria::sel $maria_handler "SELECT d_next_o_id, d_tax FROM district WHERE d_id = $no_d_id AND d_w_id = $no_w_id FOR UPDATE" -flatlist ]
    lassign $o_id_tax_list next_o_id dtax
    mariaexec $maria_handler "UPDATE district SET d_next_o_id = d_next_o_id + 1 WHERE d_id = $no_d_id AND d_w_id = $no_w_id"
    set o_id [ lindex  $o_id_tax_list 0 ]
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
      if { $x > 1 } {
        set no_ol_supply_w_id $no_w_id
      } else {
        set no_ol_supply_w_id $no_w_id
        set no_o_all_local 0
        while { ($no_ol_supply_w_id eq $no_w_id) && ($no_max_w_id != 1) } {
          set no_ol_supply_w_id [ RandomNumber 1 $no_max_w_id ]
        }
      }
      set no_ol_quantity [ RandomNumber 1 10 ] 
      set price_name_data [ maria::sel $maria_handler "SELECT i_price, i_name, i_data FROM item WHERE i_id = $no_ol_i_id" -flatlist ]
      if { [ llength $price_name_data ] eq 0 } {
        maria::rollback $maria_handler
        return
      }
      set quantity_data_dist [ maria::sel $maria_handler "SELECT s_quantity, s_data, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10 FROM stock WHERE s_i_id = $no_ol_i_id AND s_w_id = $no_ol_supply_w_id" -flatlist ]
      set no_i_price [ lindex $price_name_data 0 ]
      set no_s_quantity [ lindex $quantity_data_dist 0 ]
      if { $no_s_quantity > $no_ol_quantity } {
        set no_s_quantity [ expr {$no_s_quantity - $no_ol_quantity} ]
      } else {
        set no_s_quantity [ expr {$no_s_quantity - $no_ol_quantity + 91} ]
      }
      mariaexec $maria_handler "UPDATE stock SET s_quantity = $no_s_quantity WHERE s_i_id = $no_ol_i_id AND s_w_id = $no_ol_supply_w_id"
      set no_ol_amount [ expr {($no_ol_quantity * $no_i_price * ( 1 + $no_w_tax + $no_d_tax ) * ( 1 - $no_c_discount ))} ]
      switch $no_d_id {
        1 { set no_ol_dist_info [ lindex $quantity_data_dist 2 ] }
        2 { set no_ol_dist_info [ lindex $quantity_data_dist 3 ] }
        3 { set no_ol_dist_info [ lindex $quantity_data_dist 4 ] }
        4 { set no_ol_dist_info [ lindex $quantity_data_dist 5 ] }
        5 { set no_ol_dist_info [ lindex $quantity_data_dist 6 ] }
        6 { set no_ol_dist_info [ lindex $quantity_data_dist 7 ] }
        7 { set no_ol_dist_info [ lindex $quantity_data_dist 8 ] }
        8 { set no_ol_dist_info [ lindex $quantity_data_dist 9 ] }
        9 { set no_ol_dist_info [ lindex $quantity_data_dist 10 ] }
        10 { set no_ol_dist_info [ lindex $quantity_data_dist 11 ] } 
      }
      mariaexec $maria_handler "INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info) VALUES ($o_id, $no_d_id, $no_w_id, $loop_counter, $no_ol_i_id, $no_ol_supply_w_id, $no_ol_quantity, $no_ol_amount, '$no_ol_dist_info')"
      incr loop_counter 
    }
    mariaexec $maria_handler "INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local) VALUES ($o_id, $no_d_id, $no_w_id, $no_c_id, $date, $ol_cnt, $no_o_all_local)"
    mariaexec $maria_handler "INSERT INTO new_order (no_o_id, no_d_id, no_w_id) VALUES ($o_id, $no_d_id, $no_w_id)"
    maria::commit $maria_handler
    }
    set paybody {
    global mariastatus
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
    mariaexec $maria_handler "start transaction"
    mariaexec $maria_handler "UPDATE warehouse SET w_ytd = w_ytd + $p_h_amount WHERE w_id = $p_w_id"
    set w_address_list [ maria::sel $maria_handler "SELECT w_street_1, w_street_2, w_city, w_state, w_zip, w_name FROM warehouse WHERE w_id = $p_w_id" -flatlist ]
    lassign $w_address_list p_w_street_1 p_w_street_2 p_w_city p_w_state p_w_zip p_w_name
    set p_w_name [ lindex $w_address_list 5 ]
    mariaexec $maria_handler "UPDATE district SET d_ytd = d_ytd + $p_h_amount WHERE d_w_id = $p_w_id AND d_id = $p_d_id"
    set d_address_list [ maria::sel $maria_handler "SELECT d_street_1, d_street_2, d_city, d_state, d_zip, d_name FROM district WHERE d_w_id = $p_w_id AND d_id = $p_d_id" -flatlist ]
    lassign $d_address_list p_d_street_1 p_d_street_2 p_d_city p_d_state p_d_zip p_d_name
    set p_d_name [ lindex $d_address_list 5 ]
    if { $byname } {
      set namecnt [ maria::sel $maria_handler "SELECT count(c_id) FROM customer WHERE c_last = '$name' AND c_d_id = $p_c_d_id AND c_w_id = $p_c_w_id" -flatlist ]
      set cust_list [ maria::sel $maria_handler "SELECT c_first, c_middle, c_id, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since FROM customer WHERE c_w_id = $p_c_w_id AND c_d_id = $p_c_d_id AND c_last = '$name' ORDER BY c_first" -list ]
      if { [ expr {$namecnt % 2} ] eq 1 } {
        set $namecnt [ expr {$namecnt + 1} ]
      }
      set cust_id_to_query [ lindex $cust_list [ expr {$namecnt / 2} ] ]
      lassign $cust_id_to_query p_c_first p_c_middle p_c_id p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since
      set p_c_last $name
    } else {
      set cust_id_to_query [ maria::sel $maria_handler "SELECT c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since FROM customer WHERE c_w_id = $p_c_w_id AND c_d_id = $p_c_d_id AND c_id = $p_c_id" -flatlist ]
      lassign $cust_id_to_query p_c_first p_c_middle p_c_last p_c_street_1 p_c_street_2 p_c_city p_c_state p_c_zip p_c_phone p_c_credit p_c_credit_lim p_c_discount p_c_balance p_c_since
    }
    if { $p_c_balance eq "" } { set p_c_balance 0 }
    set p_c_balance [ expr {$p_c_balance + $p_h_amount} ]
    if { $p_c_credit eq "BC" } {
      set c_data [ join [ maria::sel $maria_handler "SELECT c_data FROM customer WHERE c_w_id = $p_c_w_id AND c_d_id = $p_c_d_id AND c_id = $p_c_id" -flatlist ]]
      set h_data [ concat $p_w_name $p_d_name ]
      set p_c_new_data [ concat p_c_id $p_c_id p_c_d_id $p_c_d_id p_c_w_id $p_c_w_id p_d_id $p_d_id p_w_id $p_w_id p_h_amount [ format %4.2f $p_h_amount ] h_date $h_date h_data $h_data ]
      set p_c_new_data [ string range [ concat $p_c_new_data $c_data ] 1 [ expr 500 - [ string length $p_c_new_data ] ] ]
      mariaexec $maria_handler "UPDATE customer SET c_balance = $p_c_balance, c_data = '$p_c_new_data' WHERE c_w_id = $p_c_w_id AND c_d_id = $p_c_d_id AND c_id = $p_c_id"
    } else {
      mariaexec $maria_handler "UPDATE customer SET c_balance = $p_c_balance WHERE c_w_id = $p_c_w_id AND c_d_id = $p_c_d_id AND c_id = $p_c_id"
      set c_data ""
    }
    set h_data [ concat $p_w_name $p_d_name ]
    mariaexec $maria_handler "INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id, h_w_id, h_date, h_amount, h_data) VALUES ($p_c_d_id, $p_c_w_id, $p_c_id, $p_d_id, $p_w_id, $h_date, $p_h_amount, '$h_data')"
    maria::commit $maria_handler
    }
    set ostatbody {
    global mariastatus
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
    mariaexec $maria_handler "start transaction"
    if { $byname eq 1 } {
      set  namecnt [ list [ maria::sel $maria_handler "SELECT count(c_id) FROM customer WHERE c_last = '$name' AND c_d_id = $d_id AND c_w_id = $w_id" -list ]]
      if { [ expr {$namecnt % 2} ] eq 1 } {
        incr namecnt
      }
      set cust_list [ maria::sel $maria_handler "SELECT c_balance, c_first, c_middle, c_id FROM customer WHERE c_last = '$name' AND c_d_id = $d_id AND c_w_id = $w_id ORDER BY c_first" -list ]
      set cust_id_to_query [ lindex $cust_list [ expr ($namecnt/2)-1 ] ]
    } else {
      set cust_id_to_query [ maria::sel $maria_handler "SELECT c_balance, c_first, c_middle, c_last FROM customer WHERE c_id = $c_id AND c_d_id = $d_id AND c_w_id = $w_id" -list ]
    }
    lassign $cust_id_to_query os_c_balance os_c_first os_c_middle os_c_last
    set cust_orders [ maria::sel $maria_handler "SELECT o_id, o_carrier_id, o_entry_d FROM (SELECT o_id, o_carrier_id, o_entry_d FROM orders where o_d_id = $d_id AND o_w_id = $w_id and o_c_id = $c_id ORDER BY o_id DESC) AS sb LIMIT 1" -flatlist ]
    if { [ llength $cust_orders ] eq 0 } {
      set no_order_status "No orders for customer"
      set o_id 0
    } else {
      lassign $cust_orders o_id o_carrier_id o_entry_d
    }
    set c_line [ maria::sel $maria_handler "SELECT ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_delivery_d FROM order_line WHERE ol_o_id = $o_id AND ol_d_id = $d_id AND ol_w_id = $w_id" -flatlist ]
    foreach arr {os_ol_i_id_array os_ol_supply_w_id_array os_ol_quantity_array os_ol_amount_array os_ol_delivery_d_array os_ol_i_id_array } { set $arr "CSV," }
    foreach {ol_i_id ol_supply_w_id ol_quantity ol_amount ol_delivery_d} $c_line {
      lappend os_ol_i_id_array "$ol_i_id,"
      lappend os_ol_supply_w_id_array "$ol_supply_w_id,"
      lappend os_ol_quantity_array "$ol_quantity,"
      lappend os_ol_amount_array "$ol_amount,"
      lappend os_ol_delivery_d_array "$ol_delivery_d,"
}
      maria::commit $maria_handler
}
      set delivbody {
    global mariastatus
    set carrier_id [ RandomNumber 1 10 ]
    set date [ gettimestamp ]
    set loop_counter 1
    mariaexec $maria_handler "start transaction"
    while { $loop_counter <= 10 } {
	set d_d_id $loop_counter
	set no_o_id [ maria::sel $maria_handler "SELECT no_o_id FROM new_order WHERE no_w_id = $w_id AND no_d_id = $d_d_id LIMIT 1" -flatlist ]
	if { $no_o_id eq "" } { break }
	mariaexec $maria_handler "DELETE FROM new_order WHERE no_w_id = $w_id AND no_d_id = $d_d_id AND no_o_id = $no_o_id"
	set o_c_id [ list [ maria::sel $maria_handler "SELECT o_c_id FROM orders WHERE o_id = $no_o_id AND o_d_id = $d_d_id AND o_w_id = $w_id" -list ]]
	mariaexec $maria_handler "UPDATE orders SET o_carrier_id = $carrier_id WHERE o_id = $no_o_id AND o_d_id = $d_d_id AND o_w_id = $w_id"
	mariaexec $maria_handler "UPDATE order_line SET ol_delivery_d = str_to_date($date,'%Y%m%d%H%i%s') WHERE ol_o_id = $no_o_id AND ol_d_id = $d_d_id AND ol_w_id = $w_id"
   	set d_ol_total [ list [ maria::sel $maria_handler "SELECT SUM(ol_amount) FROM order_line WHERE ol_o_id = $no_o_id AND ol_d_id = $d_d_id AND ol_w_id = $w_id" -list ]]
	mariaexec $maria_handler "UPDATE customer SET c_balance = c_balance + $d_ol_total WHERE c_id = $o_c_id AND c_d_id = $d_d_id AND c_w_id = $w_id"
	incr loop_counter
       	}
	maria::commit $maria_handler
	}
	 set stockbody {
    global mariastatus
    set threshold [ RandomNumber 10 20 ]
    mariaexec $maria_handler "start transaction"
    set d_next_o_id [ list [ maria::sel $maria_handler "SELECT d_next_o_id FROM district WHERE d_w_id=$w_id AND d_id=$stock_level_d_id" -list ]]
     set stock_count [ list [ maria::sel $maria_handler "SELECT COUNT(DISTINCT (s_i_id)) FROM order_line, stock WHERE ol_w_id = $w_id AND ol_d_id = $stock_level_d_id AND (ol_o_id < $d_next_o_id) AND ol_o_id >= ($d_next_o_id - 20) AND s_w_id = $w_id AND s_i_id = ol_i_id AND s_quantity < $threshold" -list ]]
     maria::commit $maria_handler
     }
	if { $testtype eq "test" } {
	set newordtail {puts "$discount,$last,$credit,$dtax,$wtax,$next_o_id"
	}
	set paytail {puts "$p_c_id,$p_c_last,$p_w_street_1,$p_w_street_2,$p_w_city,$p_w_state,$p_w_zip,$p_d_street_1,$p_d_street_2,$p_d_city,$p_d_state,$p_d_zip,$p_c_first,$p_c_middle,$p_c_street_1,$p_c_street_2,$p_c_city,$p_c_state,$p_c_zip,$p_c_phone,$p_c_since,$p_c_credit,$p_c_credit_lim,$p_c_discount,$p_c_balance,$c_data"
	}
	set ostattail {puts "$c_id,$os_c_last,$os_c_first,$os_c_middle,$os_c_balance,$o_id,$o_entry_d,$o_carrier_id"
	}
	set delivtail {puts "$w_id $carrier_id $date"
	}
	set stocktail {puts "$stock_count"
	}
	} else {
	foreach tl {newordtail paytail ostattail delivtail stocktail} { set $tl ""}
	}
	#Build procs for correct workload
	append neword_no_sp $newordargs $newordbody $newordtail "\}"
	append pay_no_sp $payargs $paybody $paytail "\}" 
	append ostat_no_sp $ostatargs $ostatbody $ostattail "\}" 
	append deliv_no_sp $delivargs $delivbody $delivtail "\}" 
	append stock_no_sp $stockargs $stockbody $stocktail "\}" 

        set index_sp_1 [.ed_mainFrame.mainwin.textFrame.left.text search -forwards "\#NEW ORDER" 1.0 ]
        set index_sp_2 [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "proc prep_statement" end ]
        #End of run loop is previous line
	#CLI indexes are characters in the string and integers GUI indexes are based on lines and position. Move back 1 line
	if { [ string is entier $index_sp_2 ] } {
       set index_sp_2 [ expr $index_sp_2 - 10 ]
       	} else {
       set index_sp_2 [ expr $index_sp_2 - 1 ]
	}
        #Delete stored procedures
        .ed_mainFrame.mainwin.textFrame.left.text fastdelete $index_sp_1 $index_sp_2+1l
        #Insert no stored procedures version
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert $index_sp_1 "$neword_no_sp \n\n $pay_no_sp \n\n $ostat_no_sp \n\n $deliv_no_sp \n\n $stock_no_sp \n\n"
}

proc loadmariatpcc { } {
    global _ED maria_ssl_options
    upvar #0 dbdict dbdict
    if {[dict exists $dbdict maria library ]} {
        set library [ dict get $dbdict maria library ]
    } else { set library "mariatcl" }
    upvar #0 configmariadb configmariadb
    #set variables to values in dict
    setlocaltpccvars $configmariadb
     #If the options menu has been run under the GUI maria_ssl_options is set
    #If build is run under the GUI, CLI or WS maria_ssl_options is not set
    #Set it now if it doesn't exist
    if ![ info exists maria_ssl_options ] { check_maria_ssl $configmariadb }
    ed_edit_clear
    .ed_mainFrame.notebook select .ed_mainFrame.mainwin
    set _ED(packagekeyname) "MariaDB TPROC-C"
    .ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh9.0
#OPTIONS
set library $library ;# Maria Library
global mariastatus
set total_iterations $maria_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$maria_raiseerror\" ;# Exit script on Maria error (true or false)
set KEYANDTHINK \"$maria_keyandthink\" ;# Time for user thinking and keying (true or false)
set host \"$maria_host\" ;# Address of the server hosting Maria 
set port \"$maria_port\" ;# Port of the Maria Server, defaults to 3306
set socket \"$maria_socket\" ;# Maria Socket for local connections
set ssl_options {$maria_ssl_options} ;# Maria SSL/TLS options
set user \"$maria_user\" ;# Maria user
set password \"[ quotemeta $maria_pass ]\" ;# Password for the Maria user
set db \"$maria_dbase\" ;# Database containing the TPC Schema
set prepare \"$maria_prepared\" ;# Use prepared statements
#OPTIONS
"
    .ed_mainFrame.mainwin.textFrame.left.text fastinsert end {
#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }
#TIMESTAMP
proc gettimestamp { } {
    set tstamp [ clock format [ clock seconds ] -format %Y%m%d%H%M%S ]
    return $tstamp
}
proc chk_socket { host socket } {
    if { ![string match windows $::tcl_platform(platform)] && ($host eq "127.0.0.1" || [ string tolower $host ] eq "localhost") && [ string tolower $socket ] != "null" } {
        return "TRUE"
    } else {
        return "FALSE"
    }
}

proc ConnectToMaria { host port socket ssl_options user password db } {
    global mariastatus
    #ssl_options is variable length so build a connectstring
    if { [ chk_socket $host $socket ] eq "TRUE" } {
	set use_socket "true"
	append connectstring " -socket $socket"
	 } else {
	set use_socket "false"
	append connectstring " -host $host -port $port"
	}
	foreach key [ dict keys $ssl_options ] {
	append connectstring " $key [ dict get $ssl_options $key ] "
	}
	append connectstring " -user $user"
	if { [ string tolower $password ] != "null" } {
	append connectstring " -password $password"
	}
	set login_command "mariaconnect [ dict get $connectstring ]"
	#eval the login command
        if [catch {set maria_handler [eval $login_command]}] {
		if $use_socket {
            puts "the local socket connection to $socket could not be established"
    } else {
            puts "the tcp connection to $host:$port could not be established"
    }
        set connected "false"
        } else {
        set connected "true"
        }
    if {$connected} {
        mariause $maria_handler $db
        maria::autocommit $maria_handler 0
        set isi [maria::sel $maria_handler "show variables like 'innodb_snapshot_isolation'" -list]
        if {[llength $isi] > 0} { catch {maria::exec $maria_handler "set session innodb_snapshot_isolation=0"} }
	catch {set ssl_status [ maria::sel $maria_handler "show session status like 'ssl_cipher'" -list ]}
	if { [ info exists ssl_status ] } {
	puts [ join $ssl_status ]
	}
        return $maria_handler
    } else {
        error $mariastatus(message)
        return
    }
}
#NEW ORDER
proc neword { maria_handler no_w_id w_id_input prepare RAISEERROR } {
    global mariastatus
    #open new order cursor
    #2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
    set no_d_id [ RandomNumber 1 10 ]
    #2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
    set no_c_id [ RandomNumber 1 3000 ]
    #2.4.1.3 Items in the order randomly selected from 5 to 15
    set ol_cnt [ RandomNumber 5 15 ]
    #2.4.1.6 order entry date O_ENTRY_D generated by SUT
    set date [ gettimestamp ]
    if {$prepare} {
        catch {mariaexec $maria_handler "set @no_w_id=$no_w_id,@w_id_input=$w_id_input,@no_d_id=$no_d_id,@no_c_id=$no_c_id,@ol_cnt=$ol_cnt,@next_o_id=0,@date=str_to_date($date,'%Y%m%d%H%i%s')"}
        catch {mariaexec $maria_handler "execute neword_st using @no_w_id,@w_id_input,@no_d_id,@no_c_id,@ol_cnt,@next_o_id,@date"}
    } else {
        mariaexec $maria_handler "set @next_o_id = 0"
        catch { mariaexec $maria_handler "CALL NEWORD($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,@disc,@last,@credit,@dtax,@wtax,@next_o_id,str_to_date($date,'%Y%m%d%H%i%s'))" }
    }
    if { $mariastatus(code)  } {
        if { $RAISEERROR } {
            error "New Order : $mariastatus(message)"
        } else {
            puts $mariastatus(message) 
        } 
    } else {
        puts [ join [ maria::sel $maria_handler "select @disc,@last,@credit,@dtax,@wtax,@next_o_id" -list ] ]
    }
}

#PAYMENT
proc payment { maria_handler p_w_id w_id_input prepare RAISEERROR } {
    global mariastatus
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
    if {$prepare} {
        catch {mariaexec $maria_handler "set @p_w_id=$p_w_id,@p_d_id=$p_d_id,@p_c_w_id=$p_c_w_id,@p_c_d_id=$p_c_d_id,@p_c_id=$p_c_id,@byname=$byname,@p_h_amount=$p_h_amount,@p_c_last='$name',@p_c_credit=0,@p_c_balance=0,@h_date=str_to_date($h_date,'%Y%m%d%H%i%s')"}
        catch { mariaexec $maria_handler "execute payment_st using @p_w_id,@p_d_id,@p_c_w_id,@p_c_d_id,@p_c_id,@byname,@p_h_amount,@p_c_last,@p_c_credit,@p_c_balance,@h_date"}
    } else {
        mariaexec $maria_handler "set @p_c_id = $p_c_id, @p_c_last = '$name', @p_c_credit = 0, @p_c_balance = 0"
        catch { mariaexec $maria_handler "CALL PAYMENT($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,@p_c_id,$byname,$p_h_amount,@p_c_last,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,@p_c_credit,@p_c_credit_lim,@p_c_discount,@p_c_balance,@p_c_data,str_to_date($h_date,'%Y%m%d%H%i%s'))"}
    }
    if { $mariastatus(code) } {
        if { $RAISEERROR } {
            error "Payment : $mariastatus(message)"
        } else {
            puts $mariastatus(message) 
        } 
    } else {
        puts [ join [ maria::sel $maria_handler "select @p_c_id,@p_c_last,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,@p_c_credit,@p_c_credit_lim,@p_c_discount,@p_c_balance,@p_c_data" -list ] ]
    }
}

#ORDER_STATUS
proc ostat { maria_handler w_id prepare RAISEERROR } {
    global mariastatus
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
    if {$prepare} {
        catch {mariaexec $maria_handler "set @os_w_id=$w_id,@dos_d_id=$d_id,@os_c_id=$c_id,@byname=$byname,@os_c_last='$name'"}
        catch {mariaexec $maria_handler "execute ostat_st using @os_w_id,@dos_d_id,@os_c_id,@byname,@os_c_last"}
    } else {
        mariaexec $maria_handler "set @os_c_id = $c_id, @os_c_last = '$name'"
        catch { mariaexec $maria_handler "CALL OSTAT($w_id,$d_id,@os_c_id,$byname,@os_c_last,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id)"}
    }
    if { $mariastatus(code) } {
        if { $RAISEERROR } {
            error "Order Status : $mariastatus(message)"
        } else {
            puts $mariastatus(message) 
        } 
    } else {
        puts [ join [ maria::sel $maria_handler "select @os_c_id,@os_c_last,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id" -list ] ]
    }
}

#DELIVERY
proc delivery { maria_handler w_id prepare RAISEERROR } {
    global mariastatus
    set carrier_id [ RandomNumber 1 10 ]
    set date [ gettimestamp ]
    if {$prepare} {
        catch {mariaexec $maria_handler "set @d_w_id=$w_id,@d_o_carrier_id=$carrier_id,@timestamp=str_to_date($date,'%Y%m%d%H%i%s')"}
        catch {mariaexec $maria_handler "execute delivery_st using @d_w_id,@d_o_carrier_id,@timestamp"}
    } else {
        catch { mariaexec $maria_handler "CALL DELIVERY($w_id,$carrier_id,str_to_date($date,'%Y%m%d%H%i%s'))"}
    }
    if { $mariastatus(code) } {
        if { $RAISEERROR } {
            error "Delivery : $mariastatus(message)"
        } else {
            puts $mariastatus(message) 
        } 
    } else {
        puts "$w_id $carrier_id $date"
    }
}

#STOCK LEVEL
proc slev { maria_handler w_id stock_level_d_id prepare RAISEERROR } {
    global mariastatus
    set threshold [ RandomNumber 10 20 ]
    if {$prepare} {
        catch {mariaexec $maria_handler "set @st_w_id=$w_id,@st_d_id=$stock_level_d_id,@threshold=$threshold"}
        catch {mariaexec $maria_handler "execute slev_st using @st_w_id,@st_d_id,@threshold"}
    } else {
        catch {mariaexec $maria_handler "CALL SLEV($w_id,$stock_level_d_id,$threshold,@stock_count)"}
    }
    if { $mariastatus(code) } {
        if { $RAISEERROR } {
            error "Stock Level : $mariastatus(message)"
        } else {
            puts $mariastatus(message) 
        } 
    } else {
        puts [ join [ maria::sel $maria_handler "select @stock_count" -list ] ]
    }
}

proc prep_statement { maria_handler statement_st } {
    switch $statement_st {
        slev_st {
            mariaexec $maria_handler "prepare slev_st from 'CALL SLEV(?,?,?,@stock_count)'"
        }
        delivery_st {
            mariaexec $maria_handler "prepare delivery_st from 'CALL DELIVERY(?,?,?)'"
        }
        ostat_st {
            mariaexec $maria_handler "prepare ostat_st from 'CALL OSTAT(?,?,?,?,?,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id)'"
        }
        payment_st {
            mariaexec $maria_handler "prepare payment_st from 'CALL PAYMENT(?,?,?,?,?,?,?,?,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,?,@p_c_credit_lim,@p_c_discount,?,@p_c_data,?)'"
        }
        neword_st {
            mariaexec $maria_handler "prepare neword_st from 'CALL NEWORD(?,?,?,?,?,@disc,@last,@credit,@dtax,@wtax,?,?)'"
        }
    }
}

#RUN TPC-C
set maria_handler [ ConnectToMaria $host $port $socket $ssl_options $user $password $db ]
if {$prepare} {
    foreach st {neword_st payment_st delivery_st slev_st ostat_st} { set $st [ prep_statement $maria_handler $st ] }
}
set w_id_input [ list [ maria::sel $maria_handler "select max(w_id) from warehouse" -list ] ]
#2.4.1.1 set warehouse_id stays constant for a given terminal
set w_id  [ RandomNumber 1 $w_id_input ]  
set d_id_input [ list [ maria::sel $maria_handler "select max(d_id) from district" -list ] ]
set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
puts "Processing $total_iterations transactions without output suppressed..."
set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
for {set it 0} {$it < $total_iterations} {incr it} {
    if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
    set choice [ RandomNumber 1 23 ]
    if {$choice <= 10} {
        puts "new order"
        if { $KEYANDTHINK } { keytime 18 }
        neword $maria_handler $w_id $w_id_input $prepare $RAISEERROR
        if { $KEYANDTHINK } { thinktime 12 }
    } elseif {$choice <= 20} {
        puts "payment"
        if { $KEYANDTHINK } { keytime 3 }
        payment $maria_handler $w_id $w_id_input $prepare $RAISEERROR
        if { $KEYANDTHINK } { thinktime 12 }
    } elseif {$choice <= 21} {
        puts "delivery"
        if { $KEYANDTHINK } { keytime 2 }
        delivery $maria_handler $w_id $prepare $RAISEERROR
        if { $KEYANDTHINK } { thinktime 10 }
    } elseif {$choice <= 22} {
        puts "stock level"
        if { $KEYANDTHINK } { keytime 2 }
        slev $maria_handler $w_id $stock_level_d_id $prepare $RAISEERROR
        if { $KEYANDTHINK } { thinktime 5 }
    } elseif {$choice <= 23} {
        puts "order status"
        if { $KEYANDTHINK } { keytime 2 }
        ostat $maria_handler $w_id $prepare $RAISEERROR
        if { $KEYANDTHINK } { thinktime 5 }
    }
}
if {$prepare} {
    foreach st {neword_st payment_st delivery_st slev_st ostat_st} {
        catch {mariaexec $maria_handler "deallocate prepare $st"}
    }
}
mariaclose $maria_handler
}
if { $maria_connect_pool } {
insert_mariaconnectpool_drivescript test sync
} else {
if { $maria_no_stored_procs } {
insert_maria_no_stored_procs test sync
}
}
}

proc loadtimedmariatpcc { } {
    global opmode _ED maria_ssl_options
    upvar #0 dbdict dbdict
    if {[dict exists $dbdict maria library ]} {
        set library [ dict get $dbdict maria library ]
    } else { set library "mariatcl" }
    upvar #0 configmariadb configmariadb
    #set variables to values in dict
    setlocaltpccvars $configmariadb
    #If the options menu has been run under the GUI maria_ssl_options is set
    #If build is run under the GUI, CLI or WS maria_ssl_options is not set
    #Set it now if it doesn't exist
    if ![ info exists maria_ssl_options ] { check_maria_ssl $configmariadb }
    ed_edit_clear
    .ed_mainFrame.notebook select .ed_mainFrame.mainwin
    set _ED(packagekeyname) "MariaDB TPROC-C Timed"
    if { !$maria_async_scale } {
        #REGULAR TIMED SCRIPT
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh9.0
#OPTIONS
set library $library ;# MariaDB Library
global mariastatus
set total_iterations $maria_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$maria_raiseerror\" ;# Exit script on Maria error (true or false)
set KEYANDTHINK \"$maria_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $maria_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $maria_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set host \"$maria_host\" ;# Address of the server hosting Maria 
set port \"$maria_port\" ;# Port of the Maria Server, defaults to 3306
set socket \"$maria_socket\" ;# Maria Socket for local connections
set ssl_options {$maria_ssl_options} ;# Maria SSL/TLS options
set user \"$maria_user\" ;# Maria user
set password \"[ quotemeta $maria_pass ]\" ;# Password for the Maria user
set db \"$maria_dbase\" ;# Database containing the TPC Schema
set prepare \"$maria_prepared\" ;# Use prepared statements
set purge \"$maria_purge\" ;# Purge undo when complete
#OPTIONS
"
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end {
#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

if { [ chk_thread ] eq "FALSE" } {
    error "MariaDB Timed Script must be run in Thread Enabled Interpreter"
}

proc chk_socket { host socket } {
    if { ![string match windows $::tcl_platform(platform)] && ($host eq "127.0.0.1" || [ string tolower $host ] eq "localhost") && [ string tolower $socket ] != "null" } {
        return "TRUE"
    } else {
        return "FALSE"
    }
}

proc ConnectToMaria { host port socket ssl_options user password db } {
    global mariastatus
    #ssl_options is variable length so build a connectstring
    if { [ chk_socket $host $socket ] eq "TRUE" } {
	set use_socket "true"
	append connectstring " -socket $socket"
	 } else {
	set use_socket "false"
	append connectstring " -host $host -port $port"
	}
	foreach key [ dict keys $ssl_options ] {
	append connectstring " $key [ dict get $ssl_options $key ] "
	}
	append connectstring " -user $user"
	if { [ string tolower $password ] != "null" } {
	append connectstring " -password $password"
	}
	set login_command "mariaconnect [ dict get $connectstring ]"
	#eval the login command
        if [catch {set maria_handler [eval $login_command]}] {
		if $use_socket {
            puts "the local socket connection to $socket could not be established"
    } else {
            puts "the tcp connection to $host:$port could not be established"
    }
        set connected "false"
        } else {
        set connected "true"
        }
    if {$connected} {
        mariause $maria_handler $db
        maria::autocommit $maria_handler 0
        set isi [maria::sel $maria_handler "show variables like 'innodb_snapshot_isolation'" -list]
        if {[llength $isi] > 0} { catch {maria::exec $maria_handler "set session innodb_snapshot_isolation=0"} }
	catch {set ssl_status [ maria::sel $maria_handler "show session status like 'ssl_cipher'" -list ]}
	if { [ info exists ssl_status ] } {
	puts [ join $ssl_status ]
	}
        return $maria_handler
    } else {
        error $mariastatus(message)
        return
    }
}

proc purge { maria_handler verbose } {
            set pgmin_version "10.7.0"
            set version [ lindex [ split [ list [ maria::sel $maria_handler "select version()" -list ] ] - ] 0 ]
            if { [ package vcompare $version $pgmin_version ]  eq -1 } {
            puts "Minimum MariaDB version for dynamic innodb_purge_threads is $pgmin_version, not purging"
	    return
            }
	    if {[catch {set history_list_length [ list [ maria::sel $maria_handler "select variable_value from information_schema.global_status where variable_name = 'INNODB_HISTORY_LIST_LENGTH'" -list ]]}]} {
		set history_list_length 0
	    }
	    puts "Starting purge: history list length $history_list_length"
	    if { [ string is entier $history_list_length ] && $history_list_length > 0 } {
	    if { $verbose } { puts "wait for transactions to settle before doing purge" }
	    set commit_rate 101
	    set old_com_comm 0
	    while { $commit_rate > 100 } {
	    if { $verbose } { puts "transaction rate @ $commit_rate" }
            if {[catch {set transactions [ list [ maria::sel $maria_handler "show global status where Variable_name = 'Com_commit'" -list ] ]}]} {
                puts stderr {error, failed to query transaction rate}
                return
            } else {
                regexp {\{\{Com_commit\ ([0-9]+)\}\}} $transactions all com_comm
                set commit_rate [ expr {$com_comm - $old_com_comm} ]
		set old_com_comm $com_comm
            }
	    after 1000
    	    }
	    if { $verbose } { puts "transaction rate settled" }
	    if { $verbose } { puts "starting purge history list length is $history_list_length" }
	    if { $verbose } { puts "saving and setting purge settings" }
            if {[ catch {mariaexec $maria_handler "SET @save_threads=@@innodb_purge_threads"}]} {puts stderr {error, saving purge_threads setting}}
	    if { $verbose } { puts "saving batch size" }
            if {[ catch {mariaexec $maria_handler "SET @save_batch=@@innodb_purge_batch_size"}]} {puts stderr {error, saving batch_size setting}}
	    if { $verbose } { puts "setting purge threads" }
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_purge_threads=32"}]} {puts stderr {error, setting purge_threads setting}}
	     if { $verbose } { puts "setting batch size" }
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_purge_batch_size=5000"}]} {puts stderr {error, setting batch_size setting}}
	     if { $verbose } { puts "setting lag wait" }
	     if { $verbose } { puts "waiting for history list length $history_list_length to reach 0" }
	    set loop_counter 1
	    set freezecount 0
	    while { $history_list_length > 0 } {
            set old_history_list $history_list_length
	    if {[ catch {set history_list_length [ list [ maria::sel $maria_handler "select variable_value from information_schema.global_status where variable_name = 'INNODB_HISTORY_LIST_LENGTH'" -list ]]}]} {
                puts stderr {error, failed to query history list}
		break
	    } 
	    after 1000
	    if { $old_history_list eq $history_list_length } {
	    if { $verbose } { puts "history list has frozen for $freezecount" }
	    incr freezecount
	    if { $freezecount eq 10 } {
	    puts "history list length $history_list_length has not reduced in 10 seconds, ending purge"
	    break
	    	}
	    } else {
	    set freezecount 0
	    }
	    incr loop_counter
	    if {[expr {$loop_counter % 300}] eq 0} {
	    puts "history list length $history_list_length"
	    		}
    		}
	     if { $verbose } { puts "restoring purge settings" }
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_purge_threads=@save_threads"}]} {puts stderr {error, restoring purge_threads setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_purge_batch_size=@save_batch"}]} {puts stderr {error, restoring batch_size setting}}
	    set purge_secs [expr { $loop_counter % 60 }]
	    set purge_hrs  [expr { $loop_counter / 3600}]
            set purge_mins [expr { ($loop_counter / 60) % 60 }]
            puts [format "Purge complete in %d hrs:%02d mins:%02d secs" $purge_hrs $purge_mins $purge_secs]
    	} else {
		puts "History list is 0 or cannot be queried, not purging"
	}
	    if {[catch {set bp_pages_dirty [ list [ maria::sel $maria_handler "SELECT variable_value FROM information_schema.global_status WHERE variable_name = 'INNODB_BUFFER_POOL_PAGES_DIRTY'" -list ]]}]} {
		set bp_pages_dirty 0
	    }
	    if { [ string is entier $bp_pages_dirty ] && $bp_pages_dirty > 0 } {
	    puts "Starting write back: dirty buffer pages $bp_pages_dirty"
	    if { $verbose } { puts "saving and setting write back settings" }
            if {[ catch {mariaexec $maria_handler "SET @save_pct= @@GLOBAL.innodb_max_dirty_pages_pct"}]} {puts stderr {error, saving max_dirty_pages_pct setting}}
            if {[ catch {mariaexec $maria_handler "SET @save_pct_lwm= @@GLOBAL.innodb_max_dirty_pages_pct_lwm"}]} {puts stderr {error, saving max_dirty_pages_pct_lwm setting}}
            if {[ catch {mariaexec $maria_handler "SET @save_lru_flush_size= @@GLOBAL.innodb_lru_flush_size"}]} {puts stderr {error, saving lru_flush_size setting}}
            if {[ catch {mariaexec $maria_handler "SET @save_lru_scan_depth= @@GLOBAL.innodb_lru_scan_depth"}]} {puts stderr {error, saving lru_scan_depth setting}}
            if {[ catch {mariaexec $maria_handler "SET @save_io_capacity= @@GLOBAL.innodb_io_capacity"}]} {puts stderr {error, saving io_capacity setting}}
            if {[ catch {mariaexec $maria_handler "SET @save_io_capacity_max= @@GLOBAL.innodb_io_capacity_max"}]} {puts stderr {error, saving io_capacity_max setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_max_dirty_pages_pct=0.0"}]} {puts stderr {error, setting max_dirty_pages_pct setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_max_dirty_pages_pct_lwm=0.0"}]} {puts stderr {error, setting max_dirty_pages_pct_lwm setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_lru_flush_size=2048"}]} {puts stderr {error, setting lru_flush_size setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_lru_scan_depth=4096"}]} {puts stderr {error, setting lru_scan_depth setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_io_capacity=120000"}]} {puts stderr {error, setting io_capacity setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_io_capacity_max=120000"}]} {puts stderr {error, setting io_capacity_max setting}}
	    set bp_pages_dirty [ list [ maria::sel $maria_handler "SELECT variable_value FROM information_schema.global_status WHERE variable_name = 'INNODB_BUFFER_POOL_PAGES_DIRTY'" -list ]]
	    set loop_counter 1
	    set freezecount 0
	    while { $bp_pages_dirty > 0 } {
            set old_bp_pages_dirty $bp_pages_dirty
	    set bp_pages_dirty [ list [ maria::sel $maria_handler "SELECT variable_value FROM information_schema.global_status WHERE variable_name = 'INNODB_BUFFER_POOL_PAGES_DIRTY'" -list ]]
	    after 1000
	    if { $old_bp_pages_dirty eq $bp_pages_dirty } {
	    if { $verbose } { puts "dirty buffer pages has frozen for $freezecount" }
	    incr freezecount
	    if { $freezecount eq 10 } {
	    puts "dirty buffer pages has not reduced in 10 seconds, ending write back"
	    break
	    	}
	    } else {
	    set freezecount 0
	    }
	    incr loop_counter
	    if {[expr {$loop_counter % 300}] eq 0} {
	    puts "dirty buffer pages $bp_pages_dirty"
	    		}
    		}
	     if { $verbose } { puts "restoring write back settings" }
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_max_dirty_pages_pct=@save_pct"}]} {puts stderr {error, restoring max_dirty_pages_pct setting}}
            if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_max_dirty_pages_pct_lwm=@save_pct_lwm"}]} {puts stderr {error, restoring max_dirty_pages_pct_lwm setting}}
            if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_lru_flush_size=@save_lru_flush_size"}]} {puts stderr {error, restoring lru_flush_size setting}}
            if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_lru_scan_depth=@save_lru_scan_depth"}]} {puts stderr {error, restoring lru_scan_depth setting}}
            if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_io_capacity=@save_io_capacity"}]} {puts stderr {error, restoring io_capacity setting}}
            if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_io_capacity_max=@save_io_capacity_max"}]} {puts stderr {error, restoring io_capacity_max setting}}
	    set wb_secs [expr { $loop_counter % 60 }]
	    set wb_hrs  [expr { $loop_counter / 3600}]
            set wb_mins [expr { ($loop_counter / 60) % 60 }]
            puts [format "Write back complete in %d hrs:%02d mins:%02d secs" $wb_hrs $wb_mins $wb_secs]
	    return
    } else {
                puts "Dirty buffer pool pages is 0 or cannot be queried, not writing back"
        }
}

proc CheckDBVersion { maria_handler } {
           if {[catch {set dbversion [ lindex [ split [ list [ maria::sel $maria_handler "select version()" -list ] ] - ] 0 ]}]} {
		set dbversion "DBVersion:NULL"
	   } else {
		set dbversion "DBVersion:$dbversion"
	   }	
	   return "$dbversion"
	}

set rema [ lassign [ findvuposition ] myposition totalvirtualusers ]
switch $myposition {
    1 { 
        if { $mode eq "Local" || $mode eq "Primary" } {
	set maria_handler [ ConnectToMaria $host $port $socket $ssl_options $user $password $db ]
        maria::autocommit $maria_handler 1
            set ramptime 0
	    puts [ CheckDBVersion $maria_handler ]
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
            if {[catch {set handler_stat [ list [ maria::sel $maria_handler "show global status where Variable_name = 'Com_commit' or Variable_name =  'Com_rollback'" -list ] ]}]} {
                puts stderr {error, failed to query transaction statistics}
                return
            } else {
                regexp {\{\{Com_commit\ ([0-9]+)\}\ \{Com_rollback\ ([0-9]+)\}\}} $handler_stat all com_comm com_roll
                set start_trans [ expr $com_comm + $com_roll ]
            }
            if {[catch {set start_nopm [ list [ maria::sel $maria_handler "select sum(d_next_o_id) from district" -list ] ]}]} {
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
            if {[catch {set handler_stat [ list [ maria::sel $maria_handler "show global status where Variable_name = 'Com_commit' or Variable_name =  'Com_rollback'" -list ] ]}]} {
                puts stderr {error, failed to query transaction statistics}
                return
            } else {
                regexp {\{\{Com_commit\ ([0-9]+)\}\ \{Com_rollback\ ([0-9]+)\}\}} $handler_stat all com_comm com_roll
                set end_trans [ expr $com_comm + $com_roll ]
            }
            if {[catch {set end_nopm [ list [ maria::sel $maria_handler "select sum(d_next_o_id) from district" -list ] ]}]} {
                puts stderr {error, failed to query district table}
                return
            }
            set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
            set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
            puts "[ expr $totalvirtualusers - 1 ] Active Virtual Users configured"
            puts [ testresult $nopm $tpm MariaDB ]
            tsv::set application abort 1
            if { $mode eq "Primary" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
	    if { $purge } { purge $maria_handler false }
            catch { mariaclose $maria_handler }
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
        proc neword { maria_handler no_w_id w_id_input prepare RAISEERROR } {
            global mariastatus
            #open new order cursor
            #2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
            set no_d_id [ RandomNumber 1 10 ]
            #2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
            set no_c_id [ RandomNumber 1 3000 ]
            #2.4.1.3 Items in the order randomly selected from 5 to 15
            set ol_cnt [ RandomNumber 5 15 ]
            #2.4.1.6 order entry date O_ENTRY_D generated by SUT
            set date [ gettimestamp ]
            if {$prepare} {
                catch {mariaexec $maria_handler "set @no_w_id=$no_w_id,@w_id_input=$w_id_input,@no_d_id=$no_d_id,@no_c_id=$no_c_id,@ol_cnt=$ol_cnt,@next_o_id=0,@date=str_to_date($date,'%Y%m%d%H%i%s')"}
                catch {mariaexec $maria_handler "execute neword_st using @no_w_id,@w_id_input,@no_d_id,@no_c_id,@ol_cnt,@next_o_id,@date"}
            } else {
                mariaexec $maria_handler "set @next_o_id = 0"
                catch { mariaexec $maria_handler "CALL NEWORD($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,@disc,@last,@credit,@dtax,@wtax,@next_o_id,str_to_date($date,'%Y%m%d%H%i%s'))" }
            }
            if { $mariastatus(code)  } {
                if { $RAISEERROR } {
                    error "New Order : $mariastatus(message)"
                } else {
                    puts $mariastatus(message) 
                } 
            } else {
                catch {maria::sel $maria_handler "select @disc,@last,@credit,@dtax,@wtax,@next_o_id" -list}
            }
        }

        #PAYMENT
        proc payment { maria_handler p_w_id w_id_input prepare RAISEERROR } {
            global mariastatus
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
            if {$prepare} {
                catch {mariaexec $maria_handler "set @p_w_id=$p_w_id,@p_d_id=$p_d_id,@p_c_w_id=$p_c_w_id,@p_c_d_id=$p_c_d_id,@p_c_id=$p_c_id,@byname=$byname,@p_h_amount=$p_h_amount,@p_c_last='$name',@p_c_credit=0,@p_c_balance=0,@h_date=str_to_date($h_date,'%Y%m%d%H%i%s')"}
                catch { mariaexec $maria_handler "execute payment_st using @p_w_id,@p_d_id,@p_c_w_id,@p_c_d_id,@p_c_id,@byname,@p_h_amount,@p_c_last,@p_c_credit,@p_c_balance,@h_date"}
            } else {
                mariaexec $maria_handler "set @p_c_id = $p_c_id, @p_c_last = '$name', @p_c_credit = 0, @p_c_balance = 0"
                catch { mariaexec $maria_handler "CALL PAYMENT($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,@p_c_id,$byname,$p_h_amount,@p_c_last,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,@p_c_credit,@p_c_credit_lim,@p_c_discount,@p_c_balance,@p_c_data,str_to_date($h_date,'%Y%m%d%H%i%s'))"}
            }
            if { $mariastatus(code) } {
                if { $RAISEERROR } {
                    error "Payment : $mariastatus(message)"
                } else {
                    puts $mariastatus(message) 
                } 
            } else {
                catch {maria::sel $maria_handler "select @p_c_id,@p_c_last,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,@p_c_credit,@p_c_credit_lim,@p_c_discount,@p_c_balance,@p_c_data" -list}
            }
        }

        #ORDER_STATUS
        proc ostat { maria_handler w_id prepare RAISEERROR } {
            global mariastatus
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
            if {$prepare} {
                catch {mariaexec $maria_handler "set @os_w_id=$w_id,@dos_d_id=$d_id,@os_c_id=$c_id,@byname=$byname,@os_c_last='$name'"}
                catch {mariaexec $maria_handler "execute ostat_st using @os_w_id,@dos_d_id,@os_c_id,@byname,@os_c_last"}
            } else {
                mariaexec $maria_handler "set @os_c_id = $c_id, @os_c_last = '$name'"
                catch { mariaexec $maria_handler "CALL OSTAT($w_id,$d_id,@os_c_id,$byname,@os_c_last,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id)"}
            }
            if { $mariastatus(code) } {
                if { $RAISEERROR } {
                    error "Order Status : $mariastatus(message)"
                } else {
                    puts $mariastatus(message) 
                } 
            } else {
                catch {maria::sel $maria_handler "select @os_c_id,@os_c_last,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id" -list}
            }
        }

        #DELIVERY
        proc delivery { maria_handler w_id prepare RAISEERROR } {
            global mariastatus
            set carrier_id [ RandomNumber 1 10 ]
            set date [ gettimestamp ]
            if {$prepare} {
                catch {mariaexec $maria_handler "set @d_w_id=$w_id,@d_o_carrier_id=$carrier_id,@timestamp=str_to_date($date,'%Y%m%d%H%i%s')"}
                catch {mariaexec $maria_handler "execute delivery_st using @d_w_id,@d_o_carrier_id,@timestamp"}
            } else {
                catch { mariaexec $maria_handler "CALL DELIVERY($w_id,$carrier_id,str_to_date($date,'%Y%m%d%H%i%s'))"}
            }
            if { $mariastatus(code) } {
                if { $RAISEERROR } {
                    error "Delivery : $mariastatus(message)"
                } else {
                    puts $mariastatus(message) 
                } 
            } else {
                ;
            }
        }

        #STOCK LEVEL
        proc slev { maria_handler w_id stock_level_d_id prepare RAISEERROR } {
            global mariastatus
            set threshold [ RandomNumber 10 20 ]
            if {$prepare} {
                catch {mariaexec $maria_handler "set @st_w_id=$w_id,@st_d_id=$stock_level_d_id,@threshold=$threshold"}
                catch {mariaexec $maria_handler "execute slev_st using @st_w_id,@st_d_id,@threshold"}
            } else {
                catch {mariaexec $maria_handler "CALL SLEV($w_id,$stock_level_d_id,$threshold,@stock_count)"}
            }
            if { $mariastatus(code) } {
                if { $RAISEERROR } {
                    error "Stock Level : $mariastatus(message)"
                } else {
                    puts $mariastatus(message) 
                } 
            } else {
                catch {maria::sel $maria_handler "select @stock_count" -list}
            }
        }

        proc prep_statement { maria_handler statement_st } {
            switch $statement_st {
                slev_st {
                    mariaexec $maria_handler "prepare slev_st from 'CALL SLEV(?,?,?,@stock_count)'"
                }
                delivery_st {
                    mariaexec $maria_handler "prepare delivery_st from 'CALL DELIVERY(?,?,?)'"
                }
                ostat_st {
                    mariaexec $maria_handler "prepare ostat_st from 'CALL OSTAT(?,?,?,?,?,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id)'"
                }
                payment_st {
                    mariaexec $maria_handler "prepare payment_st from 'CALL PAYMENT(?,?,?,?,?,?,?,?,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,?,@p_c_credit_lim,@p_c_discount,?,@p_c_data,?)'"
                }
                neword_st {
                    mariaexec $maria_handler "prepare neword_st from 'CALL NEWORD(?,?,?,?,?,@disc,@last,@credit,@dtax,@wtax,?,?)'"
                }
            }
        }

        #RUN TPC-C
        set maria_handler [ ConnectToMaria $host $port $socket $ssl_options $user $password $db ]
        if {$prepare} {
            foreach st {neword_st payment_st delivery_st slev_st ostat_st} { set $st [ prep_statement $maria_handler $st ] }
        }
        set w_id_input [ list [ maria::sel $maria_handler "select max(w_id) from warehouse" -list ] ]
        #2.4.1.1 set warehouse_id stays constant for a given terminal
        set w_id  [ RandomNumber 1 $w_id_input ]  
        set d_id_input [ list [ maria::sel $maria_handler "select max(d_id) from district" -list ] ]
        set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
        puts "Processing $total_iterations transactions with output suppressed..."
        set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
        for {set it 0} {$it < $total_iterations} {incr it} {
            if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
            set choice [ RandomNumber 1 23 ]
            if {$choice <= 10} {
                if { $KEYANDTHINK } { keytime 18 }
                neword $maria_handler $w_id $w_id_input $prepare $RAISEERROR
                if { $KEYANDTHINK } { thinktime 12 }
            } elseif {$choice <= 20} {
                if { $KEYANDTHINK } { keytime 3 }
                payment $maria_handler $w_id $w_id_input $prepare $RAISEERROR
                if { $KEYANDTHINK } { thinktime 12 }
            } elseif {$choice <= 21} {
                if { $KEYANDTHINK } { keytime 2 }
                delivery $maria_handler $w_id $prepare $RAISEERROR
                if { $KEYANDTHINK } { thinktime 10 }
            } elseif {$choice <= 22} {
                if { $KEYANDTHINK } { keytime 2 }
                slev $maria_handler $w_id $stock_level_d_id $prepare $RAISEERROR
                if { $KEYANDTHINK } { thinktime 5 }
            } elseif {$choice <= 23} {
                if { $KEYANDTHINK } { keytime 2 }
                ostat $maria_handler $w_id $prepare $RAISEERROR
                if { $KEYANDTHINK } { thinktime 5 }
            }
        }
        if {$prepare} {
            foreach st {neword_st payment_st delivery_st slev_st ostat_st} {
                catch {mariaexec $maria_handler "deallocate prepare $st"}
            }
        }
mariaclose $maria_handler 
}
}}
if { $maria_connect_pool } {
insert_mariaconnectpool_drivescript timed sync
} else {
if { $maria_no_stored_procs } {
insert_maria_no_stored_procs timed sync
}
}
} else {
        #ASYNCHRONOUS TIMED SCRIPT
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh9.0
#OPTIONS
set library $library ;# Maria Library
global mariastatus
set total_iterations $maria_total_iterations ;# Number of transactions before logging off
set RAISEERROR \"$maria_raiseerror\" ;# Exit script on Maria error (true or false)
set KEYANDTHINK \"$maria_keyandthink\" ;# Time for user thinking and keying (true or false)
set rampup $maria_rampup;  # Rampup time in minutes before first Transaction Count is taken
set duration $maria_duration;  # Duration in minutes before second Transaction Count is taken
set mode \"$opmode\" ;# HammerDB operational mode
set host \"$maria_host\" ;# Address of the server hosting Maria 
set port \"$maria_port\" ;# Port of the Maria Server, defaults to 3306
set socket \"$maria_socket\" ;# Maria Socket for local connections
set ssl_options {$maria_ssl_options} ;# Maria SSL/TLS options
set user \"$maria_user\" ;# Maria user
set password \"[ quotemeta $maria_pass ]\" ;# Password for the Maria user
set db \"$maria_dbase\" ;# Database containing the TPC Schema
set prepare \"$maria_prepared\" ;# Use prepared statements
set purge \"$maria_purge\" ;# Purge undo when complete
set async_client $maria_async_client;# Number of asynchronous clients per Vuser
set async_verbose $maria_async_verbose;# Report activity of asynchronous clients
set async_delay $maria_async_delay;# Delay in ms between logins of asynchronous clients
#OPTIONS
"
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end {
#LOAD LIBRARIES AND MODULES
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }
if [catch {package require promise } message] { error "Failed to load promise package for asynchronous clients" }

if { [ chk_thread ] eq "FALSE" } {
    error "MariaDB Timed Script must be run in Thread Enabled Interpreter"
}

proc chk_socket { host socket } {
    if { ![string match windows $::tcl_platform(platform)] && ($host eq "127.0.0.1" || [ string tolower $host ] eq "localhost") && [ string tolower $socket ] != "null" } {
        return "TRUE"
    } else {
        return "FALSE"
    }
}

proc ConnectToMaria { host port socket ssl_options user password db } {
#Used for Monitor Connection
    global mariastatus
    #ssl_options is variable length so build a connectstring
    if { [ chk_socket $host $socket ] eq "TRUE" } {
	set use_socket "true"
	append connectstring " -socket $socket"
	 } else {
	set use_socket "false"
	append connectstring " -host $host -port $port"
	}
	foreach key [ dict keys $ssl_options ] {
	append connectstring " $key [ dict get $ssl_options $key ] "
	}
	append connectstring " -user $user"
	if { [ string tolower $password ] != "null" } {
	append connectstring " -password $password"
	}
	set login_command "mariaconnect [ dict get $connectstring ]"
	#eval the login command
        if [catch {set maria_handler [eval $login_command]}] {
		if $use_socket {
            puts "the local socket connection to $socket could not be established"
    } else {
            puts "the tcp connection to $host:$port could not be established"
    }
        set connected "false"
        } else {
        set connected "true"
        }
    if {$connected} {
        mariause $maria_handler $db
        maria::autocommit $maria_handler 0
	catch {set ssl_status [ maria::sel $maria_handler "show session status like 'ssl_cipher'" -list ]}
	if { [ info exists ssl_status ] } {
	puts [ join $ssl_status ]
	}
        return $maria_handler
    } else {
        error $mariastatus(message)
        return
    }
}

proc ConnectToMariaAsynch { host port socket ssl_options user password db clientname async_verbose } {
    global mariastatus
    #ssl_options is variable length so build a connectstring
    if { [ chk_socket $host $socket ] eq "TRUE" } {
	set use_socket "true"
	append connectstring " -socket $socket"
	 } else {
	set use_socket "false"
	append connectstring " -host $host -port $port"
	}
	foreach key [ dict keys $ssl_options ] {
	append connectstring " $key [ dict get $ssl_options $key ] "
	}
	append connectstring " -user $user"
	if { [ string tolower $password ] != "null" } {
	append connectstring " -password $password"
	}
	set login_command "mariaconnect [ dict get $connectstring ]"
	#eval the login command
        if [catch {set maria_handler [eval $login_command]}] {
	if $use_socket {
	if $async_verbose {
	    puts "$clientname:socket login failed:$mariastatus(message)"
    		}
    } else {
	if $async_verbose {
	    puts "$clientname:tcp login failed:$mariastatus(message)"
    		}
    }
        set connected "false"
        } else {
        set connected "true"
        }
    if {$connected} {
	if { $async_verbose } { 
	puts "Connected $clientname:$maria_handler" 
	catch {set ssl_status [ maria::sel $maria_handler "show session status like 'ssl_cipher'" -list ]}
	if { [ info exists ssl_status ] } {
	puts "$clientname:[ join $ssl_status ]"
	}}
        mariause $maria_handler $db
        maria::autocommit $maria_handler 0
        set isi [maria::sel $maria_handler "show variables like 'innodb_snapshot_isolation'" -list]
        if {[llength $isi] > 0} { catch {maria::exec $maria_handler "set session innodb_snapshot_isolation=0"} }
        return $maria_handler
    } else {
	return "$clientname:login failed:$mariastatus(message)"
    }
}

proc purge { maria_handler verbose } {
            set pgmin_version "10.7.0"
            set version [ lindex [ split [ list [ maria::sel $maria_handler "select version()" -list ] ] - ] 0 ]
            if { [ package vcompare $version $pgmin_version ]  eq -1 } {
            puts "Minimum MariaDB version for dynamic innodb_purge_threads is $pgmin_version, not purging"
	    return
            }
	    if {[catch {set history_list_length [ list [ maria::sel $maria_handler "select variable_value from information_schema.global_status where variable_name = 'INNODB_HISTORY_LIST_LENGTH'" -list ]]}]} {
		set history_list_length 0
	    }
	    puts "Starting purge: history list length $history_list_length"
	    if { [ string is entier $history_list_length ] && $history_list_length > 0 } {
	    if { $verbose } { puts "wait for transactions to settle before doing purge" }
	    set commit_rate 101
	    set old_com_comm 0
	    while { $commit_rate > 100 } {
	    if { $verbose } { puts "transaction rate @ $commit_rate" }
            if {[catch {set transactions [ list [ maria::sel $maria_handler "show global status where Variable_name = 'Com_commit'" -list ] ]}]} {
                puts stderr {error, failed to query transaction rate}
                return
            } else {
                regexp {\{\{Com_commit\ ([0-9]+)\}\}} $transactions all com_comm
                set commit_rate [ expr {$com_comm - $old_com_comm} ]
		set old_com_comm $com_comm
            }
	    after 1000
    	    }
	    if { $verbose } { puts "transaction rate settled" }
	    if { $verbose } { puts "starting purge history list length is $history_list_length" }
	    if { $verbose } { puts "saving and setting purge settings" }
            if {[ catch {mariaexec $maria_handler "SET @save_threads=@@innodb_purge_threads"}]} {puts stderr {error, saving purge_threads setting}}
	    if { $verbose } { puts "saving batch size" }
            if {[ catch {mariaexec $maria_handler "SET @save_batch=@@innodb_purge_batch_size"}]} {puts stderr {error, saving batch_size setting}}
	    if { $verbose } { puts "setting purge threads" }
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_purge_threads=32"}]} {puts stderr {error, setting purge_threads setting}}
	     if { $verbose } { puts "setting batch size" }
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_purge_batch_size=5000"}]} {puts stderr {error, setting batch_size setting}}
	     if { $verbose } { puts "setting lag wait" }
	     if { $verbose } { puts "waiting for history list length $history_list_length to reach 0" }
	    set loop_counter 1
	    set freezecount 0
	    while { $history_list_length > 0 } {
            set old_history_list $history_list_length
	    if {[ catch {set history_list_length [ list [ maria::sel $maria_handler "select variable_value from information_schema.global_status where variable_name = 'INNODB_HISTORY_LIST_LENGTH'" -list ]]}]} {
                puts stderr {error, failed to query history list}
		break
	    } 
	    after 1000
	    if { $old_history_list eq $history_list_length } {
	    if { $verbose } { puts "history list has frozen for $freezecount" }
	    incr freezecount
	    if { $freezecount eq 10 } {
	    puts "history list length $history_list_length has not reduced in 10 seconds, ending purge"
	    break
	    	}
	    } else {
	    set freezecount 0
	    }
	    incr loop_counter
	    if {[expr {$loop_counter % 300}] eq 0} {
	    puts "history list length $history_list_length"
	    		}
    		}
	     if { $verbose } { puts "restoring purge settings" }
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_purge_threads=@save_threads"}]} {puts stderr {error, restoring purge_threads setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_purge_batch_size=@save_batch"}]} {puts stderr {error, restoring batch_size setting}}
	    set purge_secs [expr { $loop_counter % 60 }]
	    set purge_hrs  [expr { $loop_counter / 3600}]
            set purge_mins [expr { ($loop_counter / 60) % 60 }]
            puts [format "Purge complete in %d hrs:%02d mins:%02d secs" $purge_hrs $purge_mins $purge_secs]
    	} else {
		puts "History list is 0 or cannot be queried, not purging"
	}
	    if {[catch {set bp_pages_dirty [ list [ maria::sel $maria_handler "SELECT variable_value FROM information_schema.global_status WHERE variable_name = 'INNODB_BUFFER_POOL_PAGES_DIRTY'" -list ]]}]} {
		set bp_pages_dirty 0
	    }
	    if { [ string is entier $bp_pages_dirty ] && $bp_pages_dirty > 0 } {
	    puts "Starting write back: dirty buffer pages $bp_pages_dirty"
	    if { $verbose } { puts "saving and setting write back settings" }
            if {[ catch {mariaexec $maria_handler "SET @save_pct= @@GLOBAL.innodb_max_dirty_pages_pct"}]} {puts stderr {error, saving max_dirty_pages_pct setting}}
            if {[ catch {mariaexec $maria_handler "SET @save_pct_lwm= @@GLOBAL.innodb_max_dirty_pages_pct_lwm"}]} {puts stderr {error, saving max_dirty_pages_pct_lwm setting}}
            if {[ catch {mariaexec $maria_handler "SET @save_lru_flush_size= @@GLOBAL.innodb_lru_flush_size"}]} {puts stderr {error, saving lru_flush_size setting}}
            if {[ catch {mariaexec $maria_handler "SET @save_lru_scan_depth= @@GLOBAL.innodb_lru_scan_depth"}]} {puts stderr {error, saving lru_scan_depth setting}}
            if {[ catch {mariaexec $maria_handler "SET @save_io_capacity= @@GLOBAL.innodb_io_capacity"}]} {puts stderr {error, saving io_capacity setting}}
            if {[ catch {mariaexec $maria_handler "SET @save_io_capacity_max= @@GLOBAL.innodb_io_capacity_max"}]} {puts stderr {error, saving io_capacity_max setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_max_dirty_pages_pct=0.0"}]} {puts stderr {error, setting max_dirty_pages_pct setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_max_dirty_pages_pct_lwm=0.0"}]} {puts stderr {error, setting max_dirty_pages_pct_lwm setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_lru_flush_size=2048"}]} {puts stderr {error, setting lru_flush_size setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_lru_scan_depth=4096"}]} {puts stderr {error, setting lru_scan_depth setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_io_capacity=120000"}]} {puts stderr {error, setting io_capacity setting}}
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_io_capacity_max=120000"}]} {puts stderr {error, setting io_capacity_max setting}}
	    set bp_pages_dirty [ list [ maria::sel $maria_handler "SELECT variable_value FROM information_schema.global_status WHERE variable_name = 'INNODB_BUFFER_POOL_PAGES_DIRTY'" -list ]]
	    set loop_counter 1
	    set freezecount 0
	    while { $bp_pages_dirty > 0 } {
            set old_bp_pages_dirty $bp_pages_dirty
	    set bp_pages_dirty [ list [ maria::sel $maria_handler "SELECT variable_value FROM information_schema.global_status WHERE variable_name = 'INNODB_BUFFER_POOL_PAGES_DIRTY'" -list ]]
	    after 1000
	    if { $old_bp_pages_dirty eq $bp_pages_dirty } {
	    if { $verbose } { puts "dirty buffer pages has frozen for $freezecount" }
	    incr freezecount
	    if { $freezecount eq 10 } {
	    puts "dirty buffer pages has not reduced in 10 seconds, ending write back"
	    break
	    	}
	    } else {
	    set freezecount 0
	    }
	    incr loop_counter
	    if {[expr {$loop_counter % 300}] eq 0} {
	    puts "dirty buffer pages $bp_pages_dirty"
	    		}
    		}
	     if { $verbose } { puts "restoring write back settings" }
             if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_max_dirty_pages_pct=@save_pct"}]} {puts stderr {error, restoring max_dirty_pages_pct setting}}
            if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_max_dirty_pages_pct_lwm=@save_pct_lwm"}]} {puts stderr {error, restoring max_dirty_pages_pct_lwm setting}}
            if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_lru_flush_size=@save_lru_flush_size"}]} {puts stderr {error, restoring lru_flush_size setting}}
            if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_lru_scan_depth=@save_lru_scan_depth"}]} {puts stderr {error, restoring lru_scan_depth setting}}
            if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_io_capacity=@save_io_capacity"}]} {puts stderr {error, restoring io_capacity setting}}
            if {[ catch {mariaexec $maria_handler "SET GLOBAL innodb_io_capacity_max=@save_io_capacity_max"}]} {puts stderr {error, restoring io_capacity_max setting}}
	    set wb_secs [expr { $loop_counter % 60 }]
	    set wb_hrs  [expr { $loop_counter / 3600}]
            set wb_mins [expr { ($loop_counter / 60) % 60 }]
            puts [format "Write back complete in %d hrs:%02d mins:%02d secs" $wb_hrs $wb_mins $wb_secs]
	    return
    } else {
                puts "Dirty buffer pool pages is 0 or cannot be queried, not writing back"
        }
}

proc CheckDBVersion { maria_handler } {
           if {[catch {set dbversion [ lindex [ split [ list [ maria::sel $maria_handler "select version()" -list ] ] - ] 0 ]}]} {
		set dbversion "DBVersion:NULL"
	   } else {
		set dbversion "DBVersion:$dbversion"
	   }	
	   return "$dbversion"
	}

set rema [ lassign [ findvuposition ] myposition totalvirtualusers ]
switch $myposition {
    1 { 
        if { $mode eq "Local" || $mode eq "Primary" } {
	set maria_handler [ ConnectToMaria $host $port $socket $ssl_options $user $password $db ]
        maria::autocommit $maria_handler 1
            set ramptime 0
	    puts [ CheckDBVersion $maria_handler ]
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
            if {[catch {set handler_stat [ list [ maria::sel $maria_handler "show global status where Variable_name = 'Com_commit' or Variable_name =  'Com_rollback'" -list ] ]}]} {
                puts stderr {error, failed to query transaction statistics}
                return
            } else {
                regexp {\{\{Com_commit\ ([0-9]+)\}\ \{Com_rollback\ ([0-9]+)\}\}} $handler_stat all com_comm com_roll
                set start_trans [ expr $com_comm + $com_roll ]
            }
            if {[catch {set start_nopm [ list [ maria::sel $maria_handler "select sum(d_next_o_id) from district" -list ] ]}]} {
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
            if {[catch {set handler_stat [ list [ maria::sel $maria_handler "show global status where Variable_name = 'Com_commit' or Variable_name =  'Com_rollback'" -list ] ]}]} {
                puts stderr {error, failed to query transaction statistics}
                return
            } else {
                regexp {\{\{Com_commit\ ([0-9]+)\}\ \{Com_rollback\ ([0-9]+)\}\}} $handler_stat all com_comm com_roll
                set end_trans [ expr $com_comm + $com_roll ]
            }
            if {[catch {set end_nopm [ list [ maria::sel $maria_handler "select sum(d_next_o_id) from district" -list ] ]}]} {
                puts stderr {error, failed to query district table}
                return
            }
            set tpm [ expr {($end_trans - $start_trans)/$durmin} ]
            set nopm [ expr {($end_nopm - $start_nopm)/$durmin} ]
            puts "[ expr $totalvirtualusers - 1 ] VU \* $async_client AC \= [ expr ($totalvirtualusers - 1) * $async_client ] Active Sessions configured"
            puts [ testresult $nopm $tpm MariaDB ]
            tsv::set application abort 1
            if { $mode eq "Primary" } { eval [subst {thread::send -async $MASTER { remote_command ed_kill_vusers }}] }
	    if { $purge } { purge $maria_handler false }
            catch { mariaclose $maria_handler }
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
        proc neword { maria_handler no_w_id w_id_input prepare RAISEERROR clientname } {
            global mariastatus
            #open new order cursor
            #2.4.1.2 select district id randomly from home warehouse where d_w_id = d_id
            set no_d_id [ RandomNumber 1 10 ]
            #2.4.1.2 Customer id randomly selected where c_d_id = d_id and c_w_id = w_id
            set no_c_id [ RandomNumber 1 3000 ]
            #2.4.1.3 Items in the order randomly selected from 5 to 15
            set ol_cnt [ RandomNumber 5 15 ]
            #2.4.1.6 order entry date O_ENTRY_D generated by SUT
            set date [ gettimestamp ]
            if {$prepare} {
                catch {mariaexec $maria_handler "set @no_w_id=$no_w_id,@w_id_input=$w_id_input,@no_d_id=$no_d_id,@no_c_id=$no_c_id,@ol_cnt=$ol_cnt,@next_o_id=0,@date=str_to_date($date,'%Y%m%d%H%i%s')"}
                catch {mariaexec $maria_handler "execute neword_st using @no_w_id,@w_id_input,@no_d_id,@no_c_id,@ol_cnt,@next_o_id,@date"}
            } else {
                mariaexec $maria_handler "set @next_o_id = 0"
                catch { mariaexec $maria_handler "CALL NEWORD($no_w_id,$w_id_input,$no_d_id,$no_c_id,$ol_cnt,@disc,@last,@credit,@dtax,@wtax,@next_o_id,str_to_date($date,'%Y%m%d%H%i%s'))" }
            }
            if { $mariastatus(code)  } {
                if { $RAISEERROR } {
                    error "New Order in $clientname : $mariastatus(message)"
                } else {
                    puts "New Order in $clientname : $mariastatus(message)"
                }
            } else {
                catch {maria::sel $maria_handler "select @disc,@last,@credit,@dtax,@wtax,@next_o_id" -list}
            }
        }

        #PAYMENT
        proc payment { maria_handler p_w_id w_id_input prepare RAISEERROR clientname } {
            global mariastatus
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
            if {$prepare} {
                catch {mariaexec $maria_handler "set @p_w_id=$p_w_id,@p_d_id=$p_d_id,@p_c_w_id=$p_c_w_id,@p_c_d_id=$p_c_d_id,@p_c_id=$p_c_id,@byname=$byname,@p_h_amount=$p_h_amount,@p_c_last='$name',@p_c_credit=0,@p_c_balance=0,@h_date=str_to_date($h_date,'%Y%m%d%H%i%s')"}
                catch { mariaexec $maria_handler "execute payment_st using @p_w_id,@p_d_id,@p_c_w_id,@p_c_d_id,@p_c_id,@byname,@p_h_amount,@p_c_last,@p_c_credit,@p_c_balance,@h_date"}
            } else {
                mariaexec $maria_handler "set @p_c_id = $p_c_id, @p_c_last = '$name', @p_c_credit = 0, @p_c_balance = 0"
                catch { mariaexec $maria_handler "CALL PAYMENT($p_w_id,$p_d_id,$p_c_w_id,$p_c_d_id,@p_c_id,$byname,$p_h_amount,@p_c_last,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,@p_c_credit,@p_c_credit_lim,@p_c_discount,@p_c_balance,@p_c_data,str_to_date($h_date,'%Y%m%d%H%i%s'))"}
            }
            if { $mariastatus(code) } {
                if { $RAISEERROR } {
                    error "Payment in $clientname : $mariastatus(message)"
                } else {
                    puts "Payment in $clientname : $mariastatus(message)"
                }
            } else {
                catch {maria::sel $maria_handler "select @p_c_id,@p_c_last,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,@p_c_credit,@p_c_credit_lim,@p_c_discount,@p_c_balance,@p_c_data" -list}
            }
        }

        #ORDER_STATUS
        proc ostat { maria_handler w_id prepare RAISEERROR clientname } {
            global mariastatus
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
            if {$prepare} {
                catch {mariaexec $maria_handler "set @os_w_id=$w_id,@dos_d_id=$d_id,@os_c_id=$c_id,@byname=$byname,@os_c_last='$name'"}
                catch {mariaexec $maria_handler "execute ostat_st using @os_w_id,@dos_d_id,@os_c_id,@byname,@os_c_last"}
            } else {
                mariaexec $maria_handler "set @os_c_id = $c_id, @os_c_last = '$name'"
                catch { mariaexec $maria_handler "CALL OSTAT($w_id,$d_id,@os_c_id,$byname,@os_c_last,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id)"}
            }
            if { $mariastatus(code) } {
                if { $RAISEERROR } {
                    error "Order Status in $clientname : $mariastatus(message)"
                } else {
                    puts "Order Status in $clientname : $mariastatus(message)"
                }
            } else {
                catch {maria::sel $maria_handler "select @os_c_id,@os_c_last,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id" -list}
            }
        }

        #DELIVERY
        proc delivery { maria_handler w_id prepare RAISEERROR clientname } {
            global mariastatus
            set carrier_id [ RandomNumber 1 10 ]
            set date [ gettimestamp ]
            if {$prepare} {
                catch {mariaexec $maria_handler "set @d_w_id=$w_id,@d_o_carrier_id=$carrier_id,@timestamp=str_to_date($date,'%Y%m%d%H%i%s')"}
                catch {mariaexec $maria_handler "execute delivery_st using @d_w_id,@d_o_carrier_id,@timestamp"}
            } else {
                catch { mariaexec $maria_handler "CALL DELIVERY($w_id,$carrier_id,str_to_date($date,'%Y%m%d%H%i%s'))"}
            }
            if { $mariastatus(code) } {
                if { $RAISEERROR } {
                    error "Delivery in $clientname : $mariastatus(message)"
                } else {
                    puts "Delivery in $clientname : $mariastatus(message)"
                }
            } else {
                ;
            }
        }

        #STOCK LEVEL
        proc slev { maria_handler w_id stock_level_d_id prepare RAISEERROR clientname } {
            global mariastatus
            set threshold [ RandomNumber 10 20 ]
            if {$prepare} {
                catch {mariaexec $maria_handler "set @st_w_id=$w_id,@st_d_id=$stock_level_d_id,@threshold=$threshold"}
                catch {mariaexec $maria_handler "execute slev_st using @st_w_id,@st_d_id,@threshold"}
            } else {
                catch {mariaexec $maria_handler "CALL SLEV($w_id,$stock_level_d_id,$threshold,@stock_count)"}
            }
            if { $mariastatus(code) } {
                if { $RAISEERROR } {
                    error "Stock Level in $clientname : $mariastatus(message)"
                } else {
                    puts "Stock Level in $clientname : $mariastatus(message)"
                }
            } else {
                catch {maria::sel $maria_handler "select @stock_count" -list}
            }
        }

        proc prep_statement { maria_handler statement_st } {
            switch $statement_st {
                slev_st {
                    mariaexec $maria_handler "prepare slev_st from 'CALL SLEV(?,?,?,@stock_count)'"
                }
                delivery_st {
                    mariaexec $maria_handler "prepare delivery_st from 'CALL DELIVERY(?,?,?)'"
                }
                ostat_st {
                    mariaexec $maria_handler "prepare ostat_st from 'CALL OSTAT(?,?,?,?,?,@os_c_first,@os_c_middle,@os_c_balance,@os_o_id,@os_entdate,@os_o_carrier_id)'"
                }
                payment_st {
                    mariaexec $maria_handler "prepare payment_st from 'CALL PAYMENT(?,?,?,?,?,?,?,?,@p_w_street_1,@p_w_street_2,@p_w_city,@p_w_state,@p_w_zip,@p_d_street_1,@p_d_street_2,@p_d_city,@p_d_state,@p_d_zip,@p_c_first,@p_c_middle,@p_c_street_1,@p_c_street_2,@p_c_city,@p_c_state,@p_c_zip,@p_c_phone,@p_c_since,?,@p_c_credit_lim,@p_c_discount,?,@p_c_data,?)'"
                }
                neword_st {
                    mariaexec $maria_handler "prepare neword_st from 'CALL NEWORD(?,?,?,?,?,@disc,@last,@credit,@dtax,@wtax,?,?)'"
                }
            }
        }

        #CONNECT ASYNC
        promise::async simulate_client { clientname total_iterations host port socket ssl_options user password RAISEERROR KEYANDTHINK db prepare async_verbose async_delay } {
            global mariastatus
            set acno [ expr [ string trimleft [ lindex [ split $clientname ":" ] 1 ] ac ] * $async_delay ]
            if { $async_verbose } { puts "Delaying login of $clientname for $acno ms" }
            async_time $acno
            if { [ tsv::get application abort ] } { return "$clientname:abort before login" }
            if { $async_verbose } { puts "Logging in $clientname" }
            set maria_handler [ ConnectToMariaAsynch $host $port $socket $ssl_options $user $password $db $clientname $async_verbose ]
            #RUN TPC-C
            if {$prepare} {
                foreach st {neword_st payment_st delivery_st slev_st ostat_st} { set $st [ prep_statement $maria_handler $st ] }
            }
            set w_id_input [ list [ maria::sel $maria_handler "select max(w_id) from warehouse" -list ] ]
            #2.4.1.1 set warehouse_id stays constant for a given terminal
            set w_id  [ RandomNumber 1 $w_id_input ]  
            set d_id_input [ list [ maria::sel $maria_handler "select max(d_id) from district" -list ] ]
            set stock_level_d_id  [ RandomNumber 1 $d_id_input ]  
            puts "Processing $total_iterations transactions with output suppressed..."
            set abchk 1; set abchk_mx 1024; set hi_t [ expr {pow([ lindex [ time {if {  [ tsv::get application abort ]  } { break }} ] 0 ],2)}]
            for {set it 0} {$it < $total_iterations} {incr it} {
                if { [expr {$it % $abchk}] eq 0 } { if { [ time {if {  [ tsv::get application abort ]  } { break }} ] > $hi_t }  {  set  abchk [ expr {min(($abchk * 2), $abchk_mx)}]; set hi_t [ expr {$hi_t * 2} ] } }
                set choice [ RandomNumber 1 23 ]
                if {$choice <= 10} {
                    if { $async_verbose } { puts "$clientname:w_id:$w_id:neword" }
                    if { $KEYANDTHINK } { async_keytime 18  $clientname neword $async_verbose }
                    neword $maria_handler $w_id $w_id_input $prepare $RAISEERROR $clientname
                    if { $KEYANDTHINK } { async_thinktime 12 $clientname neword $async_verbose }
                } elseif {$choice <= 20} {
                    if { $async_verbose } { puts "$clientname:w_id:$w_id:payment" }
                    if { $KEYANDTHINK } { async_keytime 3 $clientname payment $async_verbose }
                    payment $maria_handler $w_id $w_id_input $prepare $RAISEERROR $clientname
                    if { $KEYANDTHINK } { async_thinktime 12 $clientname payment $async_verbose }
                } elseif {$choice <= 21} {
                    if { $async_verbose } { puts "$clientname:w_id:$w_id:delivery" }
                    if { $KEYANDTHINK } { async_keytime 2 $clientname delivery $async_verbose }
                    delivery $maria_handler $w_id $prepare $RAISEERROR $clientname
                    if { $KEYANDTHINK } { async_thinktime 10 $clientname delivery $async_verbose }
                } elseif {$choice <= 22} {
                    if { $async_verbose } { puts "$clientname:w_id:$w_id:slev" }
                    if { $KEYANDTHINK } { async_keytime 2 $clientname slev $async_verbose }
                    slev $maria_handler $w_id $stock_level_d_id $prepare $RAISEERROR $clientname
                    if { $KEYANDTHINK } { async_thinktime 5 $clientname slev $async_verbose }
                } elseif {$choice <= 23} {
                    if { $async_verbose } { puts "$clientname:w_id:$w_id:ostat" }
                    if { $KEYANDTHINK } { async_keytime 2 $clientname ostat $async_verbose }
                    ostat $maria_handler $w_id $prepare $RAISEERROR $clientname
                    if { $KEYANDTHINK } { async_thinktime 5 $clientname ostat $async_verbose }
                }
            }
            if {$prepare} {
                foreach st {neword_st payment_st delivery_st slev_st ostat_st} {
                    catch {mariaexec $maria_handler "deallocate prepare $st"}
                }
            }
            mariaclose $maria_handler
            if { $async_verbose } { puts "$clientname:complete" }
            return $clientname:complete
        }
        for {set ac 1} {$ac <= $async_client} {incr ac} {
            set clientdesc "vuser$myposition:ac$ac"
            lappend clientlist $clientdesc
            lappend clients [simulate_client $clientdesc $total_iterations $host $port $socket $ssl_options $user $password $RAISEERROR $KEYANDTHINK $db $prepare $async_verbose $async_delay]
        }
        puts "Started asynchronous clients:$clientlist"
        set acprom [ promise::eventloop [ promise::all $clients ] ]
        puts "All asynchronous clients complete"
        if { $async_verbose } {
            foreach client $acprom { puts $client }
}
}
}}
#Reformatting src causes error when inserting timeprofile
#Do not modify double close bracket above
#Close bracket of fast insert must come directly after inserted code without newline
if { $maria_connect_pool } {
insert_mariaconnectpool_drivescript timed async
} else {
if { $maria_no_stored_procs } {
insert_maria_no_stored_procs timed async
}
}
}
}

proc delete_mariatpcc {} {
    global maxvuser suppo ntimes threadscreated _ED maria_ssl_options
    upvar #0 dbdict dbdict

    if {[dict exists $dbdict maria library ]} {
        set library [ dict get $dbdict maria library ]
    } else {
        set library "mariatcl" 
    }

    upvar #0 configmariadb configmariadb
    #set variables to values in dict
    setlocaltpccvars $configmariadb
    #If the options menu has been run under the GUI maria_ssl_options is set
    #If build is run under the GUI, CLI or WS maria_ssl_options is not set
    #Set it now if it doesn't exist
    if ![ info exists maria_ssl_options ] { check_maria_ssl $configmariadb } 
    if { ![string match windows $::tcl_platform(platform)] && ($maria_host eq "127.0.0.1" || [ string tolower $maria_host ] eq "localhost") && [ string tolower $maria_socket ] != "null" } { set maria_connector "$maria_host:$maria_socket" } else { 
        set maria_connector "$maria_host:$maria_port" 
    }

    if {[ tk_messageBox -title "Delete Schema" -icon question -message "Do you want to delete the [ string toupper $maria_dbase ] TPROC-C schema\n in host [string toupper $maria_connector] under user [ string toupper $maria_user ]?" -type yesno ] == yes} {
        set maxvuser 1
        set suppo 1
        set ntimes 1
        ed_edit_clear
        set _ED(packagekeyname) "TPROC-C deletion"
        if { [catch {load_virtual} message]} {
            puts "Failed to create threads for schema deletion: $message"
            return
        }
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh9.0
#LOAD LIBRARIES AND MODULES
set library $library
"
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end {
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

proc chk_socket { host socket } {
    if { ![string match windows $::tcl_platform(platform)] && ($host eq "127.0.0.1" || [ string tolower $host ] eq "localhost") && [ string tolower $socket ] != "null" } {
        return "TRUE"
    } else {
        return "FALSE"
    }
}

proc ConnectToMaria { host port socket ssl_options user password } {
    global mariastatus
    #ssl_options is variable length so build a connectstring
    if { [ chk_socket $host $socket ] eq "TRUE" } {
	set use_socket "true"
	append connectstring " -socket $socket"
	 } else {
	set use_socket "false"
	append connectstring " -host $host -port $port"
	}
	foreach key [ dict keys $ssl_options ] {
	append connectstring " $key [ dict get $ssl_options $key ] "
	}
	append connectstring " -user $user -password $password"
	set login_command "mariaconnect [ dict get $connectstring ]"
	#eval the login command
        if [catch {set maria_handler [eval $login_command]}] {
		if $use_socket {
            puts "the local socket connection to $socket could not be established"
    } else {
            puts "the tcp connection to $host:$port could not be established"
    }
        set connected "false"
        } else {
        set connected "true"
        }
    if {$connected} {
        maria::autocommit $maria_handler 0
	catch {set ssl_status [ maria::sel $maria_handler "show session status like 'ssl_cipher'" -list ]}
	if { [ info exists ssl_status ] } {
	puts [ join $ssl_status ]
	}
        return $maria_handler
    } else {
        error $mariastatus(message)
        return
    }
}

proc drop_schema { host port socket ssl_options user password dbase } {
    global mariastatus

    set maria_handler [ ConnectToMaria $host $port $socket $ssl_options $user $password ]
    if {[ catch {mariaexec $maria_handler "drop database $dbase"} message ] } {
        puts "$message"
    } else {
        puts "$dbase TPROC-C Schema has been deleted successfully."
    }
    mariaclose $maria_handler

    return
}
}
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end "drop_schema $maria_host $maria_port $maria_socket {$maria_ssl_options} $maria_user [ quotemeta $maria_pass ] $maria_dbase"
    } else { return }
}

proc check_mariatpcc {} {
    global maxvuser suppo ntimes threadscreated _ED maria_ssl_options
    upvar #0 dbdict dbdict

    if {[dict exists $dbdict maria library ]} {
        set library [ dict get $dbdict maria library ]
    } else {
        set library "mariatcl" 
    }

    upvar #0 configmariadb configmariadb
    #set variables to values in dict
    setlocaltpccvars $configmariadb
    #If the options menu has been run under the GUI maria_ssl_options is set
    #If build is run under the GUI, CLI or WS maria_ssl_options is not set
    #Set it now if it doesn't exist
    if ![ info exists maria_ssl_options ] { check_maria_ssl $configmariadb } 
    if { ![string match windows $::tcl_platform(platform)] && ($maria_host eq "127.0.0.1" || [ string tolower $maria_host ] eq "localhost") && [ string tolower $maria_socket ] != "null" } { set maria_connector "$maria_host:$maria_socket" } else { 
        set maria_connector "$maria_host:$maria_port" 
    }

    if {[ tk_messageBox -title "Check Schema" -icon question -message "Do you want to check the [ string toupper $maria_dbase ] TPROC-C schema\n in host [string toupper $maria_connector] under user [ string toupper $maria_user ]?" -type yesno ] == yes} {
        set maxvuser 1
        set suppo 1
        set ntimes 1
        ed_edit_clear
        set _ED(packagekeyname) "TPROC-C check"
        if { [catch {load_virtual} message]} {
            puts "Failed to create thread for schema check: $message"
            return
        }
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end "#!/usr/local/bin/tclsh9.0
#LOAD LIBRARIES AND MODULES
set library $library
"
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end {
if [catch {package require $library} message] { error "Failed to load $library - $message" }
if [catch {package require tpcccommon} ] { error "Failed to load tpcc common functions" } else { namespace import tpcccommon::* }

proc chk_socket { host socket } {
    if { ![string match windows $::tcl_platform(platform)] && ($host eq "127.0.0.1" || [ string tolower $host ] eq "localhost") && [ string tolower $socket ] != "null" } {
        return "TRUE"
    } else {
        return "FALSE"
    }
}

proc ConnectToMaria { host port socket ssl_options user password } {
    global mariastatus
    #ssl_options is variable length so build a connectstring
    if { [ chk_socket $host $socket ] eq "TRUE" } {
	set use_socket "true"
	append connectstring " -socket $socket"
	 } else {
	set use_socket "false"
	append connectstring " -host $host -port $port"
	}
	foreach key [ dict keys $ssl_options ] {
	append connectstring " $key [ dict get $ssl_options $key ] "
	}
	append connectstring " -user $user -password $password"
	set login_command "mariaconnect [ dict get $connectstring ]"
	#eval the login command
        if [catch {set maria_handler [eval $login_command]}] {
		if $use_socket {
            puts "the local socket connection to $socket could not be established"
    } else {
            puts "the tcp connection to $host:$port could not be established"
    }
        set connected "false"
        } else {
        set connected "true"
        }
    if {$connected} {
        maria::autocommit $maria_handler 0
	catch {set ssl_status [ maria::sel $maria_handler "show session status like 'ssl_cipher'" -list ]}
	if { [ info exists ssl_status ] } {
	puts [ join $ssl_status ]
	}
        return $maria_handler
    } else {
        error $mariastatus(message)
        return
    }
}

proc check_tpcc { host port socket ssl_options user password dbase count_ware } {
    global mariastatus
    puts "Checking $dbase TPROC-C schema"
    set tables [ dict create warehouse $count_ware customer [ expr {$count_ware * 30000} ] district [ expr {$count_ware * 10} ] history [ expr {$count_ware * 30000} ] item 100000 new_order [ expr {$count_ware * 9000 * 0.90} ] order_line [ expr {$count_ware * 300000 * 0.99} ] orders [ expr {$count_ware * 30000} ] stock [ expr {$count_ware * 100000} ] ]
    set sps [ list delivery neword ostat payment slev ]
    set maria_handler [ ConnectToMaria $host $port $socket $ssl_options $user $password ]
   #Check 1 Database Exists
    puts "Check database"
        set db_exists [ maria::sel $maria_handler "select schema_name from information_schema.schemata where schema_name = '$dbase'" -flatlist  ]
	if { [ string length $db_exists ] > 0 } {
            mariause $maria_handler $dbase
        set table_exists [ maria::sel $maria_handler "show tables" -flatlist  ]
	if {[ llength $table_exists ] == 0 } {
	error "TPROC-C Schema check failed $dbase schema is empty"
	} else {
	#Check 2 Tables Exist
	puts "Check tables and indices"
	foreach table [dict keys $tables] {
	set match [ lsearch $table_exists $table ]
	if { $match == -1 } {
	error "TPROC-C Schema check failed $dbase schema is missing table $table"
	} else {
	if { $table eq "warehouse" } {
	#Check 3 Warehouse count in schema is the same as dict setting
        set w_id_input [  maria::sel $maria_handler "select max(w_id) from warehouse" -flatlist ]
	if { $count_ware != $w_id_input } {
	error "TPROC-C Schema check failed $dbase schema warehouse count $w_id_input does not equal dict warehouse count of $count_ware"
	}
	}
        #Check 4 Tables are indexed
    	set is_indexed [  maria::sel $maria_handler "show index from $table" -flatlist ]
        if { [ llength $is_indexed ] eq 0 } {
	if { $table != "history" } {
	error "TPROC-C Schema check failed $dbase schema on table $table no indices"
		}
	}
	#Check 5 Tables are populated
	set expected_rows [ dict get $tables $table ]
        set row_count [  maria::sel $maria_handler "select count(*) from $table" -flatlist ]
        if { $row_count < $expected_rows } {
	error "TPROC-C Schema check failed $dbase schema on table $table row count of $row_count is less than expected count of $expected_rows"
	} 
	}
	}
        }
        #Check 6 Stored Procedures Exist
	puts "Check procedures"
	foreach sp $sps {
        set sp_exists [ maria::sel $maria_handler "show create procedure $sp" -flatlist  ]
        if {  [ llength $sp_exists ] == 0 } {
	error "TPROC-C Schema check failed $dbase schema is missing stored procedure $sp"
	} 
	}
        #Create temporary sample table
	mariaexec $maria_handler "create or replace temporary table `temp_w` (`t_w_id` smallint null)"
	if { $w_id_input <= 10 } {
	for  {set i 1} {$i <= $w_id_input} { incr i} {
 	mariaexec $maria_handler "insert into temp_w values ($i)"
	}
	} else {
	foreach statement {{insert into temp_w values (1)} {insert into temp_w values ([expr {0.1 * $w_id_input}])} {insert into temp_w values ([expr {0.2 * $w_id_input}])} {insert into temp_w values ([expr {0.3 * $w_id_input}])} {insert into temp_w values ([expr {0.4 * $w_id_input}])} {insert into temp_w values ([expr {0.5 * $w_id_input}])} {insert into temp_w values ([expr {0.6 * $w_id_input}])} {insert into temp_w values ([expr {0.7 * $w_id_input}])} {insert into temp_w values ([expr {0.8 * $w_id_input}])} {insert into temp_w values ([expr {0.9 * $w_id_input}])} {insert into temp_w values ($w_id_input)}} {
	mariaexec $maria_handler [ subst $statement ]
	}
	}
	   #Consistency check 1
	puts "Check consistency 1"
	set rows [ maria::sel $maria_handler "select d_w_id, (w_ytd - sum(d_ytd)) diff from warehouse, district where d_w_id=w_id group by d_w_id, w_ytd having (w_ytd - sum(d_ytd)) != 0" -flatlist ]
	if {[ llength $rows ] > 0} {
	error "TPROC-C Schema check failed $dbase schema consistency check 1 failed"
	} 
	   #Consistency check 2
	puts "Check consistency 2"
	set rows [ maria::sel $maria_handler "select * from (select d_w_id, d_id, max(o_id) AS ORDER_MAX, (d_next_o_id - 1) AS ORDER_NEXT from district, orders where d_w_id = o_w_id and d_id = o_d_id and d_w_id in (select t_w_id from temp_w) group by d_w_id, d_id, (d_next_o_id - 1)) dt where dt.ORDER_NEXT != dt.ORDER_MAX" -flatlist ]
	if {[ llength $rows ] > 0} {
	error "TPROC-C Schema check failed $dbase schema consistency check 2 failed"
	} 
	   #Consistency check 3
	puts "Check consistency 3"
	set rows [ maria::sel $maria_handler "select * from (select count(*) as nocount, (max(no_o_id) - min(no_o_id) + 1) as total from new_order group by no_w_id, no_d_id) dt where nocount != total" -flatlist ]
	if {[ llength $rows ] > 0} {
	error "TPROC-C Schema check failed $dbase schema consistency check 3 failed"
	} 
	   #Consistency check 4
	puts "Check consistency 4"
	set rows [ maria::sel $maria_handler "select * from (select o_w_id, o_d_id, sum(o_ol_cnt) as ol_sum from orders, temp_w where o_w_id = t_w_id group by o_w_id, o_d_id) consist1, (select ol_w_id, ol_d_id, count(*) as ol_count from order_line, temp_w where ol_w_id = t_w_id group by ol_w_id, ol_d_id) consist2 where o_w_id = ol_w_id and o_d_id = ol_d_id and ol_sum != ol_count" -flatlist ]
	if {[ llength $rows ] > 0} {
	error "TPROC-C Schema check failed $dbase schema consistency check 4 failed"
	} 
	mariaexec $maria_handler "drop table `temp_w`"
        puts "$dbase TPROC-C Schema has been checked successfully."
	} else {
	error "Schema check failed $dbase TPROC-C schema does not exist"
	}
    mariaclose $maria_handler
    return
}
}
        .ed_mainFrame.mainwin.textFrame.left.text fastinsert end "check_tpcc $maria_host $maria_port $maria_socket {$maria_ssl_options} $maria_user [ quotemeta $maria_pass ] $maria_dbase $maria_count_ware"
    } else { return }
}
