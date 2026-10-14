# MySQL tenant backend. Oracle-specific options, connections and SQL belong in a separate backend.
if {[catch {package require oceanbasecommon}]} {
    # Source-tree test interpreters do not inherit the application's tm paths.
    source [file join [file dirname [info script]] .. .. .. modules oceanbasecommon-1.0.tm]
}
source [file join [file dirname [info script]] tprocc.tcl]
source [file join [file dirname [info script]] tproch.tcl]
source [file join [file dirname [info script]] runtime.tcl]
source [file join [file dirname [info script]] counter.tcl]
source [file join [file dirname [info script]] options.tcl]
namespace eval oceanbase::mysql {
    proc username {user tenant cluster} {
        foreach part [list $user $tenant $cluster] {
            if {[regexp {[@#:\s]} $part]} {error "Use separate user, tenant and cluster fields without @, #, : or whitespace"}
        }
        if {$user eq ""} {error "OceanBase user is required"}
        if {$cluster ne ""} {
            if {$tenant eq ""} {error "OceanBase tenant is required with a cluster"}
            return "$user@$tenant#$cluster"
        }
        # OB Cloud endpoints already identify the tenant, so a bare user is valid.
        if {$tenant eq ""} {return $user}
        return "$user@$tenant"
    }

    proc config {config} {
        set config [::oceanbaseconfig::normalize $config]
        foreach {group key minimum maximum} {
            connection ob_port 1 65535
            tpcc ob_count_ware 1 100000
            tpcc ob_num_vu 1 512
            tpcc ob_total_iterations 1 2147483647
            tpcc ob_rampup 0 2147483647
            tpcc ob_duration 1 2147483647
            tpch ob_num_tpch_threads 1 512
            tpch ob_total_querysets 1 2147483647
            tpch ob_update_sets 1 2147483647
            tpch ob_trickle_refresh 0 2147483647
        } {
            if {[dict exists $config $group $key]} {
                set value [dict get $config $group $key]
                if {![string is integer -strict $value] || $value < $minimum || $value > $maximum} {
                    error "$key must be an integer from $minimum to $maximum"
                }
            }
        }
        dict for {group values} $config {
            dict for {key value} $values {
                if {[boolean_option $key] && $value ni {true false}} {error "$key must be true or false"}
            }
        }
        if {[dict exists $config tpcc ob_driver] && [dict get $config tpcc ob_driver] ni {test timed}} {error "Driver must be test or timed"}
        if {[dict exists $config tpch ob_scale_fact] && [dict get $config tpch ob_scale_fact] ni {1 10 30 100 300 1000 3000 10000 30000 100000}} {
            error "Unsupported TPROC-H scale factor"
        }
        # Start with MySQL defaults, not the user's current MySQL configuration.
        set mapped [::XML::To_Dict [file join [find_config_dir] mysql.xml]]
        dict for {group values} $config {
            dict for {key value} $values {
                set mysql_key mysql_[string range $key 3 end]
                if {[dict exists $mapped $group $mysql_key]} {dict set mapped $group $mysql_key $value}
            }
        }
        set timeout [dict get $config connection ob_query_timeout]
        if {![string is integer -strict $timeout] || $timeout < 1 || $timeout > 86400} {
            error "OceanBase query timeout must be 1 to 86400 seconds"
        }
        set tenant [dict get $config connection ob_tenant]
        set cluster [dict get $config connection ob_cluster]
        foreach {group key} {tpcc user tpch tpch_user} {
            dict set mapped $group mysql_$key [username [dict get $config $group ob_$key] $tenant $cluster]
        }
        foreach {group key} {tpcc storage_engine tpch tpch_storage_engine} {
            if {[string tolower [dict get $mapped $group mysql_$key]] ne "innodb"} {
                error "OceanBase MySQL workloads require the innodb-compatible schema"
            }
        }
        set distributed [dict get $config tpcc ob_distributed_schema]
        set optimized [dict get $config tpch ob_tpch_optimized_schema]
        if {$optimized ni {true false}} {error "OceanBase TPROC-H optimized schema must be true or false"}
        set h_partitions [dict get $config tpch ob_tpch_partition_count]
        if {![string is integer -strict $h_partitions] || $h_partitions < 1 || $h_partitions > 8192} {
            error "OceanBase TPROC-H partition count must be an integer from 1 to 8192"
        }
        if {$distributed ni {true false}} {
            error "OceanBase distributed schema must be true or false"
        }
        set partition_count [dict get $config tpcc ob_partition_count]
        if {![string is integer -strict $partition_count] || $partition_count < 1 || $partition_count > 8192} {
            error "OceanBase TPROC-C partition count must be an integer from 1 to 8192"
        }
        if {$distributed eq "true"} {
            # The native MySQL option partitions only ORDER_LINE. OceanBase
            # replaces the full table DDL instead.
            dict set mapped tpcc mysql_partition false
        }
        foreach {key minimum} {ob_async_client 1 ob_async_delay 0} {
            set value [dict get $config tpcc $key]
            if {![string is integer -strict $value] || $value < $minimum} {error "$key must be an integer >= $minimum"}
        }
        if {[dict get $config tpcc ob_connect_pool] eq "true"} {
            if {[dict get $config tpcc ob_no_stored_procs] eq "true"} {error "Cluster Connect Pool requires stored procedures"}
            dict set mapped tpcc mysql_prepared true
        }
        if {[dict get $config tpcc ob_async_scale] eq "true"} {dict set mapped tpcc mysql_keyandthink true}
        # The legacy OceanBase option under MySQL prepares sys settings and uses
        # different DDL. The new category needs only the business tenant login.
        dict set mapped tpch mysql_tpch_obcompat false
        dict set mapped connection mysql_socket null
        return $mapped
    }

    proc with_config {command args} {
        global configmysql configoceanbase mysql_ssl_options mysql_ssl_config
        set mapped [config $configoceanbase]
        set saved $configmysql
        set saved_ssl {}
        foreach name {mysql_ssl_options mysql_ssl_config} {
            if {[info exists $name]} {dict set saved_ssl $name [set $name]}
            unset -nocomplain $name
        }
        set configmysql $mapped
        try {
            # Match the native SSL cache key while retaining list-safe OB options.
            set c [dict get $configoceanbase connection]
            set capath_key [expr {$::tcl_platform(platform) eq "windows" ? "ob_ssl_windows_capath" : "ob_ssl_linux_capath"}]
            set mysql_ssl_options [::oceanbasecommon::ssl_options $configoceanbase]
            set mysql_ssl_config [list [dict get $c ob_ssl] [dict get $c ob_ssl_two_way] [dict get $c $capath_key] \
                [dict get $c ob_ssl_ca] [dict get $c ob_ssl_cert] [dict get $c ob_ssl_key] [dict get $c ob_ssl_cipher]]
            # Preserve schema-operation callers so GUI load_virtual uses the loader count.
            return [uplevel 1 [list $command {*}$args]]
        } finally {
            set configmysql $saved
            foreach name {mysql_ssl_options mysql_ssl_config} {
                if {[dict exists $saved_ssl $name]} {
                    set $name [dict get $saved_ssl $name]
                } else {
                    unset -nocomplain $name
                }
            }
        }
    }

    proc generate {workload action} {
        set commands [dict create tpcc [dict create build build_mysqltpcc test loadmysqltpcc timed loadtimedmysqltpcc check check_mysqltpcc delete delete_mysqltpcc] tpch [dict create build build_mysqltpch test loadmysqltpch cloud loadmysqlcloud check check_mysqltpch delete delete_mysqltpch]]
        if {![dict exists $commands $workload $action]} {error "Unsupported OceanBase MySQL operation: $workload $action"}
        set command [dict get $commands $workload $action]
        global configoceanbase _ED
        set normalized [::oceanbaseconfig::normalize $configoceanbase]
        if {$workload eq "tpcc" && $action eq "test" && [dict get $normalized tpcc ob_allwarehouse] eq "true"} {
            error "Use All Warehouses requires the Timed Driver Script"
        }
        if {$workload eq "tpcc" && $action eq "test" && [dict get $normalized tpcc ob_async_scale] eq "true"} {
            error "Asynchronous Scaling requires the Timed Driver Script"
        }
        with_config $command
        set graphical [info exists ::tk_version]
        if {$graphical} {ed_edit_commit}
        if {[string length [string trim $_ED(package)]] > 0} {
            set timeout [dict get $normalized connection ob_query_timeout]
            set _ED(package) [rewrite_runtime $_ED(package) $timeout]
            if {$action in {build check delete}} {
                set _ED(package) [rewrite_schema_entry $_ED(package) $workload $action [config $normalized]]
            }
            if {$action in {test timed cloud}} {
                set _ED(package) [rewrite_workload_credentials $_ED(package) $workload [config $normalized]]
            }
            if {$workload eq "tpch" && $action eq "build" && [dict get $normalized tpch ob_tpch_optimized_schema] eq "true"} {
                set _ED(package) [rewrite_optimized_tproch $_ED(package) [dict get $normalized tpch ob_tpch_partition_count]]
            }
            if {$workload eq "tpch" && $action in {build test}} {
                # OceanBase requires abbreviated-month parsing for generated TPROC-H dates.
                # Keep the shared MySQL generator on its existing full-month parser path.
                set _ED(package) [string map [list {'%Y-%M-%d'} {'%Y-%b-%d'}] $_ED(package)]
            }
            if {$workload eq "tpcc" && [dict get $normalized tpcc ob_distributed_schema] eq "true"} {
                if {$action eq "build"} {
                    set _ED(package) [rewrite_distributed_tprocc $_ED(package) [dict get $normalized tpcc ob_partition_count]]
                }
                set _ED(package) [rewrite_distributed_tprocc_queries $_ED(package)]
            }
            if {$workload eq "tpcc" && $action eq "build"} {
                set _ED(package) [rewrite_tprocc_schema $_ED(package)]
            }
            if {$workload eq "tpcc" && $action eq "build" && [dict get $normalized tpcc ob_history_pk] eq "true"} {
                set _ED(package) [rewrite_history_pk $_ED(package) [dict get $normalized tpcc ob_distributed_schema]]
            }
            if {$workload eq "tpcc" && $action in {test timed} && [dict get $normalized tpcc ob_connect_pool] eq "true"} {
                set _ED(package) [rewrite_connect_pool $_ED(package)]
            }
            if {$graphical} {
                .ed_mainFrame.mainwin.textFrame.left.text fastdelete 1.0 end
                .ed_mainFrame.mainwin.textFrame.left.text fastinsert end $_ED(package)
            }
            set _ED(packagekeyname) "OceanBase MySQL tenant"
        }
    }

    proc save_options {} {
        global configoceanbase
        variable options
        variable options_context
        set updated $configoceanbase
        foreach entry [array names options] {
            lassign [split $entry ,] group key
            if {$group eq "counter"} {continue}
            set value $options($entry)
            if {$key in {ob_pass ob_tpch_pass}} {set value [quotemeta $value]}
            dict set updated $group $key $value
        }
        if {[catch {::oceanbase::validate $updated} message]} {
            tk_messageBox -parent .oboptions -icon error -message $message
            return
        }
        if {[catch {::oceanbasecommon::ssl_options $updated} message]} {
            tk_messageBox -parent .oboptions -icon error -message $message
            return
        }
        if {[info exists options_context] && [lindex $options_context 1] eq "counter"} {
            set interval $options(counter,tc_refresh_rate)
            if {![string is integer -strict $interval] || $interval < 1 || $interval >= 60} {
                tk_messageBox -parent .oboptions -icon error -message "Refresh rate must be more than 0 secs and less than 60 secs"
                return
            }
        }
        set counter_settings {}
        if {[info exists options_context] && [lindex $options_context 1] eq "counter"} {
            foreach key {tc_refresh_rate tc_log_to_temp tc_unique_log_name tc_log_timestamps} {
                set value $options(counter,$key)
                if {$key in {tc_unique_log_name tc_log_timestamps} && !$options(counter,tc_log_to_temp)} {set value 0}
                dict set counter_settings $key $value
            }
        }
        if {[catch {::oceanbaseconfig::save $updated $counter_settings} message]} {
            tk_messageBox -parent .oboptions -icon error -message "Cannot save OceanBase options: $message"
            return
        }
        set configoceanbase $updated
        if {[info exists options_context] && [lindex $options_context 1] eq "counter"} {
            global genericdict
            dict for {key value} $counter_settings {
                dict set genericdict transaction_counter $key $value
            }
        }
        destroy .oboptions
        if {[info exists options_context] && [lindex $options_context 1] eq "drive"} {
            if {[lindex $options_context 0] eq "tpcc"} {loadtpcc} else {loadtpch}
        }
    }

    proc update_partition_count_state {widget {group tpcc} {key ob_distributed_schema}} {
        variable options
        if {$options($group,$key) eq "true"} {
            $widget state !disabled
        } else {
            $widget state disabled
        }
    }

    proc boolean_option {key} {
        expr {$key in {ob_ssl ob_ssl_two_way ob_partition ob_distributed_schema
            ob_prepared ob_no_stored_procs ob_raiseerror ob_keyandthink
            ob_allwarehouse ob_timeprofile ob_tpch_optimized_schema
            ob_raise_query_error ob_verbose ob_refresh_on ob_refresh_verbose
            ob_history_pk ob_async_scale ob_async_verbose ob_connect_pool ob_cloud_query}}
    }

    proc options {group option} {show_options $group $option}
    proc validate {configuration} {config $configuration}
    proc counter {bm interval masterthread} {
        global configoceanbase
        with_config tcount_oceanbase_mysql $bm $interval $masterthread [dict get $configoceanbase connection ob_query_timeout]
    }

}
