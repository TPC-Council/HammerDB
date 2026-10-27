# OceanBase-specific TPROC-C schema generation. Keep this separate from the
# native MySQL implementation so MySQL DDL and behavior remain unchanged.
namespace eval oceanbase::mysql {
    proc rewrite_tprocc_schema {script} {
        # OceanBase treats prefix keys differently from full-column keys even
        # when the prefix spans the declared VARCHAR length.
        set prefix_index {KEY c_w_id (`c_w_id`,`c_d_id`,`c_last`(16),`c_first`(16))}
        set full_index {KEY c_w_id (`c_w_id`,`c_d_id`,`c_last`,`c_first`)}
        set marker {    puts "CREATING TPCC STORED PROCEDURES"}
        foreach anchor [list $prefix_index $marker] {
            if {[string first $anchor $script] < 0} {
                error "Cannot locate the OceanBase TPROC-C schema anchor: $anchor"
            }
        }
        # Procedure string parameters inherit the creation session's collation.
        # Match the actual columns, including builds into an existing database,
        # so name predicates can use the customer index without conversion.
        set charset_setup {
    set name_columns [mysql::sel $mysql_handler {SELECT COLUMN_NAME, CHARACTER_SET_NAME, COLLATION_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'customer' AND COLUMN_NAME IN ('c_first', 'c_last') ORDER BY COLUMN_NAME} -list]
    if {[llength $name_columns] != 2 || [lindex $name_columns 0 0] ne "c_first" || [lindex $name_columns 1 0] ne "c_last"} {
        error "Cannot determine the OceanBase customer name character set"
    }
    lassign [lindex $name_columns 0] column_name name_charset name_collation
    if {[lrange [lindex $name_columns 1] 1 end] ne [list $name_charset $name_collation] || ![regexp {^[a-zA-Z0-9_]+$} $name_charset] || ![regexp {^[a-zA-Z0-9_]+$} $name_collation]} {
        error "OceanBase customer name columns must have matching character sets and collations"
    }
    mysql::exec $mysql_handler "SET NAMES $name_charset COLLATE $name_collation"
}
        return [string map [list $prefix_index $full_index $marker "$marker$charset_setup"] $script]
    }

    variable distributed_tprocc_procedure {
proc CreateOceanBaseTables {mysql_handler mysql_storage_engine database partition_count host port socket ssl_options user password} {
    puts "CREATING DISTRIBUTED OCEANBASE TPROC-C TABLES"
    set database_name [string tolower $database]
    regsub -all {[^a-z0-9_]} $database_name _ database_name
    set tablegroup "hdb_[string range $database_name 0 55]_tg"
    mysqlexec $mysql_handler "CREATE TABLEGROUP IF NOT EXISTS $tablegroup SHARDING = 'PARTITION'"
    mysqlexec $mysql_handler "ALTER TABLEGROUP $tablegroup SHARDING = 'PARTITION'"

    set distribution "TABLEGROUP = $tablegroup
PARTITION BY HASH (%s)
PARTITIONS $partition_count"
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
ENGINE = $mysql_storage_engine
[format $distribution `c_w_id`]"
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
ENGINE = $mysql_storage_engine
[format $distribution `d_w_id`]"
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
ENGINE = $mysql_storage_engine
[format $distribution `h_w_id`]"
    set sql(4) "CREATE TABLE `item` (
  `i_id` INT(6) NOT NULL,
  `i_im_id` INT NULL,
  `i_name` VARCHAR(24) BINARY NULL,
  `i_price` DECIMAL(5, 2) NULL,
  `i_data` VARCHAR(50) BINARY NULL,
PRIMARY KEY (`i_id`)
)
ENGINE = $mysql_storage_engine
DUPLICATE_SCOPE = 'CLUSTER'"
    set sql(5) "CREATE TABLE `new_order` (
  `no_w_id` INT NOT NULL,
  `no_d_id` INT NOT NULL,
  `no_o_id` INT NOT NULL,
PRIMARY KEY (`no_w_id`, `no_d_id`, `no_o_id`)
)
ENGINE = $mysql_storage_engine
[format $distribution `no_w_id`]"
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
ENGINE = $mysql_storage_engine
[format $distribution `o_w_id`]"
    set sql(7) "CREATE TABLE `order_line` (
  `ol_w_id` INT NOT NULL,
  `ol_d_id` INT NOT NULL,
  `ol_o_id` INT NOT NULL,
  `ol_number` INT NOT NULL,
  `ol_i_id` INT NULL,
  `ol_delivery_d` DATETIME NULL,
  `ol_amount` INT NULL,
  `ol_supply_w_id` INT NULL,
  `ol_quantity` INT NULL,
  `ol_dist_info` CHAR(24) BINARY NULL,
PRIMARY KEY (`ol_w_id`,`ol_d_id`,`ol_o_id`,`ol_number`)
)
ENGINE = $mysql_storage_engine
[format $distribution `ol_w_id`]"
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
ENGINE = $mysql_storage_engine
[format $distribution `s_w_id`]"
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
ENGINE = $mysql_storage_engine
[format $distribution `w_id`]"
    foreach i {1 2 3 5 6 7 8 9} {
        mysqlexec $mysql_handler $sql($i)
    }
    # Creating the first duplicate table initializes the broadcast log stream.
    # Some OBProxy versions close that session even though the DDL succeeds, so
    # isolate it from the schema loader connection and verify after reconnecting.
    set item_handler [ConnectToMySQL $host $port $socket $ssl_options $user $password]
    mysqluse $item_handler $database
    if {[catch {mysqlexec $item_handler $sql(4)} item_message item_options]} {
        catch {mysqlclose $item_handler}
        set item_handler [ConnectToMySQL $host $port $socket $ssl_options $user $password]
        mysqluse $item_handler $database
        set item_definition [mysql::sel $item_handler "SHOW CREATE TABLE `item`" -list]
        if {![string match {*DUPLICATE_SCOPE = 'CLUSTER'*} [lindex $item_definition 0 1]]} {
            catch {mysqlclose $item_handler}
            return -options $item_options $item_message
        }
    }
    mysqlclose $item_handler
}
}

    proc distributed_tprocc_script {} {
        variable distributed_tprocc_procedure
        return $distributed_tprocc_procedure
    }

    proc rewrite_distributed_tprocc {script partition_count} {
        if {![string is integer -strict $partition_count] || $partition_count < 1 || $partition_count > 8192} {
            error "OceanBase TPROC-C partition count must be an integer from 1 to 8192"
        }
        set original {CreateTables $mysql_handler $mysql_storage_engine $num_part $history_pk}
        if {[string first $original $script] < 0} {
            error "Cannot locate the TPROC-C table creation call in the generated script"
        }
        set replacement "CreateOceanBaseTables \$mysql_handler \$mysql_storage_engine \$db $partition_count \$host \$port \$socket \$ssl_options \$user \$password"
        set script [string map [list $original $replacement] $script]
        set marker "\ndo_tpcc "
        set index [string last $marker $script]
        if {$index < 0} {
            error "Cannot locate the TPROC-C entry point in the generated script"
        }
        set prefix [string range $script 0 [expr {$index - 1}]]
        set suffix [string range $script $index end]
        return "$prefix\n[distributed_tprocc_script]\n$suffix"
    }

    proc rewrite_distributed_tprocc_queries {script} {
        # Route over the full positive INT warehouse-ID domain, not the configured
        # build count: an existing schema can contain more warehouses.
        set warehouse_range "where w_id between 1 and 2147483647"
        set district_range "where d_w_id between 1 and 2147483647"
        return [string map [list \
            {select max(w_id) from warehouse} "select max(w_id) from warehouse $warehouse_range" \
            {select max(d_id) from district} "select max(d_id) from district $district_range" \
            {select sum(d_next_o_id) from district} "select sum(d_next_o_id) from district $district_range"] $script]
    }

}
