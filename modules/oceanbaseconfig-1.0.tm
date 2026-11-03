# OceanBase defaults are applied after XML or SQLite loading. The shared XML
# parser deliberately retains its existing handling of empty elements.
namespace eval oceanbaseconfig {
    proc merge_registry {saved defaults} {
        # Preserve saved categories, add new ones and migrate the old OB binding.
        set defaults [regsub -all {(TP)(RO)(C-[CH])} $defaults {\1\3}]
        set missing {}
        dict for {name values} $defaults {
            if {![dict exists $saved $name]} {
                dict set missing $name $values
            }
        }
        set binding_update {}
        if {[dict exists $saved oceanbase library] &&
            [dict get $saved oceanbase library] eq "mysqltcl" &&
            [dict exists $defaults oceanbase library] &&
            [dict get $defaults oceanbase library] eq "obmysqltcl"} {
            foreach key {library commands} {
                if {[dict exists $defaults oceanbase $key]} {
                    dict set binding_update $key [dict get $defaults oceanbase $key]
                }
            }
        }
        if {[dict size $missing] || [dict size $binding_update]} {
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
                    dict for {key value} $binding_update {
                        registrydb eval {DELETE FROM oceanbase WHERE key=$key}
                        registrydb eval {INSERT INTO oceanbase(key,val) VALUES($key,$value)}
                    }
                }
            } finally {
                registrydb close
            }
        }
        dict for {key value} $binding_update {dict set saved oceanbase $key $value}
        return [dict merge $saved $missing]
    }

    proc save {configuration {counter {}}} {
        set configuration [normalize $configuration]
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
            # Persist additions and removals together so XML, GUI and CLI see
            # the same configuration after the next SQLite-backed startup.
            save $normalized
        }
        return $normalized
    }

    proc remove_legacy_mysql_options {configuration} {
        set removed {}
        foreach {group key} {
            connection mysql_oceanbase_port
            tpch mysql_ob_tenant_name
            tpch mysql_tpch_obcompat
            tpch mysql_ob_partition_num
        } {
            if {[dict exists $configuration $group $key]} {
                dict unset configuration $group $key
                lappend removed $group $key
            }
        }
        if {[llength $removed]} {
            package require sqlite3
            sqlite3 ::oceanbaseconfig::legacydb [CheckSQLiteDB mysql]
            try {
                legacydb timeout 30000
                legacydb transaction {
                    foreach {group key} $removed {
                        if {[legacydb onecolumn {SELECT count(*) FROM sqlite_master WHERE type='table' AND name=$group}]} {
                            legacydb eval "DELETE FROM ${group} WHERE key=\$key"
                        }
                    }
                }
            } finally {
                legacydb close
            }
        }
        return $configuration
    }

    proc normalize {configuration} {
        foreach {group key} {
            connection ob_socket
            tpcc ob_partition
            tpcc ob_storage_engine
            tpch ob_tpch_storage_engine
        } {
            if {[dict exists $configuration $group $key]} {dict unset configuration $group $key}
        }
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
