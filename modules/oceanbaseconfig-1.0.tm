# OceanBase defaults are applied after XML or SQLite loading. The shared XML
# parser deliberately retains its existing handling of empty elements.
namespace eval oceanbaseconfig {
    proc merge_registry {saved defaults} {
        # Keep saved categories intact; add only categories introduced by XML.
        set defaults [regsub -all {(TP)(RO)(C-[CH])} $defaults {\1\3}]
        set missing {}
        dict for {name values} $defaults {
            if {![dict exists $saved $name]} {
                dict set missing $name $values
            }
        }
        if {[dict size $missing]} {
            package require sqlite3
            sqlite3 ::oceanbaseconfig::registrydb [CheckSQLiteDB database]
            try {
                registrydb timeout 30000
                registrydb transaction {
                    dict for {name values} $missing {
                        if {![regexp {^[a-z][a-z0-9_]*$} $name]} {error "Invalid database category: $name"}
                        registrydb eval "CREATE TABLE IF NOT EXISTS ${name}(key TEXT, val TEXT)"
                        dict for {key value} $values {
                            registrydb eval "INSERT INTO ${name}(key,val) VALUES(\$key,\$value)"
                        }
                    }
                }
            } finally {
                registrydb close
            }
        }
        return [dict merge $saved $missing]
    }

    proc save {configuration {counter {}}} {
        package require sqlite3
        sqlite3 ::oceanbaseconfig::savedb [CheckSQLiteDB oceanbase]
        try {
            savedb timeout 30000
            if {[dict size $counter]} {
                set generic_file [CheckSQLiteDB generic]
                savedb eval {ATTACH DATABASE $generic_file AS generic_config}
            }
            savedb transaction {
                dict for {group values} $configuration {
                    if {$group ni {connection tpcc tpch}} {error "Unknown OceanBase configuration group: $group"}
                    savedb eval "CREATE TABLE IF NOT EXISTS ${group}(key TEXT, val TEXT)"
                    savedb eval "DELETE FROM ${group}"
                    dict for {key value} $values {
                        savedb eval "INSERT INTO ${group}(key,val) VALUES(\$key,\$value)"
                    }
                }
                dict for {key value} $counter {
                    if {$key ni {tc_refresh_rate tc_log_to_temp tc_unique_log_name tc_log_timestamps} || ![string is integer -strict $value]} {
                        error "Invalid transaction counter option: $key"
                    }
                    savedb eval {UPDATE generic_config.transaction_counter SET val=$value WHERE key=$key}
                    if {[savedb changes] == 0} {savedb eval {INSERT INTO generic_config.transaction_counter(key,val) VALUES($key,$value)}}
                }
            }
        } finally {
            savedb close
        }
    }

    proc initialize {configuration} {
        set normalized [normalize $configuration]
        if {$normalized ne $configuration} {
            package require sqlite3
            sqlite3 ::oceanbaseconfig::defaultsdb [CheckSQLiteDB oceanbase]
            try {
                defaultsdb transaction {
                    dict for {group values} $normalized {
                        dict for {key value} $values {
                            if {![dict exists $configuration $group $key]} {
                                # Groups are the fixed connection/tpcc/tpch defaults.
                                defaultsdb eval "CREATE TABLE IF NOT EXISTS ${group}(key TEXT, val TEXT)"
                                defaultsdb eval "INSERT INTO ${group}(key,val) VALUES(\$key,\$value)"
                            }
                        }
                    }
                }
            } finally {
                defaultsdb close
            }
        }
        return $normalized
    }

    proc normalize {configuration} {
        set defaults {connection {ob_compatibility_mode mysql ob_cluster {}}}
        set mode mysql
        if {[dict exists $configuration connection ob_compatibility_mode]} {
            set mode [string tolower [dict get $configuration connection ob_compatibility_mode]]
        }
        if {$mode eq "mysql"} {
            dict set defaults tpcc ob_pass ""
            dict set defaults tpcc ob_distributed_schema false
            dict set defaults tpcc ob_partition_count 24
            foreach {key value} {ob_history_pk false ob_async_scale false ob_async_client 10 ob_async_verbose false ob_async_delay 1000 ob_connect_pool false} {
                dict set defaults tpcc $key $value
            }
            dict set defaults tpch ob_tpch_pass ""
            dict set defaults tpch ob_tpch_optimized_schema false
            dict set defaults tpch ob_tpch_partition_count 24
            dict set defaults tpch ob_cloud_query false
        }
        dict for {group values} $defaults {
            dict for {key value} $values {
                if {![dict exists $configuration $group $key]} {
                    dict set configuration $group $key $value
                }
            }
        }
        return $configuration
    }
}
package provide oceanbaseconfig 1.0
