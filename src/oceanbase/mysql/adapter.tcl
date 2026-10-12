# MySQL tenant backend. Oracle-specific options, connections and SQL belong in a separate backend.
source [file join [file dirname [info script]] tprocc.tcl]
source [file join [file dirname [info script]] tproch.tcl]
source [file join [file dirname [info script]] runtime.tcl]
source [file join [file dirname [info script]] counter.tcl]
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
        set commands [dict create tpcc [dict create build build_mysqltpcc test loadmysqltpcc timed loadtimedmysqltpcc check check_mysqltpcc delete delete_mysqltpcc] tpch [dict create build build_mysqltpch test loadmysqltpch check check_mysqltpch delete delete_mysqltpch]]
        if {![dict exists $commands $workload $action]} {error "Unsupported OceanBase MySQL operation: $workload $action"}
        set command [dict get $commands $workload $action]
        global configoceanbase _ED
        set normalized [::oceanbaseconfig::normalize $configoceanbase]
        with_config $command
        set graphical [info exists ::tk_version]
        if {$graphical} {ed_edit_commit}
        if {[string length [string trim $_ED(package)]] > 0} {
            set timeout [dict get $normalized connection ob_query_timeout]
            set _ED(package) [rewrite_runtime $_ED(package) $timeout]
            if {$action in {build check delete}} {
                set _ED(package) [rewrite_schema_entry $_ED(package) $workload $action [config $normalized]]
            }
            if {$action in {test timed}} {
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
        set updated $configoceanbase
        foreach entry [array names options] {
            lassign [split $entry ,] group key
            set value $options($entry)
            if {$key in {ob_pass ob_tpch_pass}} {set value [quotemeta $value]}
            dict set updated $group $key $value
        }
        if {[catch {::oceanbase::validate $updated} message]} {
            tk_messageBox -parent .oboptions -icon error -message $message
            return
        }
        if {[catch {::oceanbaseconfig::save $updated} message]} {
            tk_messageBox -parent .oboptions -icon error -message "Cannot save OceanBase options: $message"
            return
        }
        set configoceanbase $updated
        destroy .oboptions
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
            ob_raise_query_error ob_verbose ob_refresh_on ob_refresh_verbose}}
    }

    proc options {group option} {
        global configoceanbase
        variable options
        set configoceanbase [::oceanbaseconfig::normalize $configoceanbase]
        catch {destroy .oboptions}
        array unset options
        ttk::toplevel .oboptions
        wm title .oboptions "OceanBase MySQL Tenant Options"
        wm transient .oboptions .ed_mainFrame
        ttk::notebook .oboptions.tabs
        pack .oboptions.tabs -fill both -expand 1 -padx 8 -pady 8
        set schema_keys {ob_user ob_pass ob_dbase ob_count_ware ob_num_vu ob_partition ob_distributed_schema ob_partition_count ob_storage_engine ob_tpch_user ob_tpch_pass ob_tpch_dbase ob_scale_fact ob_num_tpch_threads ob_tpch_storage_engine ob_tpch_optimized_schema ob_tpch_partition_count}
        foreach page {connection schema driver} {
            ttk::frame .oboptions.tabs.$page -padding 8
            .oboptions.tabs add .oboptions.tabs.$page -text [string totitle $page]
            set row($page) 0
        }
        dict for {section values} $configoceanbase {
            if {$section ni [list connection $group]} {continue}
            dict for {key value} $values {
                # Keep the legacy key in saved configurations and CLI scripts.
                if {$key eq "ob_partition"} {continue}
                if {$section eq "connection"} {set page connection} elseif {$key in $schema_keys} {set page schema} else {set page driver}
                set frame .oboptions.tabs.$page
                set i [incr row($page)]
                if {$key in {ob_pass ob_tpch_pass}} {set value [decode_password $value]}
                set options($section,$key) $value
                set label [string totitle [string map {_ " "} [string range $key 3 end]]]
                if {$key eq "ob_tpch_optimized_schema"} {set label "Distributed schema"}
                if {$key eq "ob_tpch_partition_count"} {set label "Partition count"}
                ttk::label $frame.l$i -text $label
                if {$key eq "ob_compatibility_mode"} {
                    ttk::combobox $frame.e$i -textvariable ::oceanbase::mysql::options($section,$key) -values [::oceanbase::supported_modes] -state readonly
                } elseif {[boolean_option $key]} {
                    ttk::checkbutton $frame.e$i -variable ::oceanbase::mysql::options($section,$key) -onvalue true -offvalue false
                } elseif {$key eq "ob_driver"} {
                    ttk::combobox $frame.e$i -textvariable ::oceanbase::mysql::options($section,$key) -values {test timed} -state readonly
                } else {
                    ttk::entry $frame.e$i -textvariable ::oceanbase::mysql::options($section,$key) -width 30
                    if {[string match *pass $key]} {$frame.e$i configure -show *}
                }
                if {$key eq "ob_distributed_schema"} {set distributed_widget $frame.e$i}
                if {$key eq "ob_partition_count"} {set partition_count_widget $frame.e$i}
                if {$key eq "ob_tpch_optimized_schema"} {set h_optimized_widget $frame.e$i}
                if {$key eq "ob_tpch_partition_count"} {set h_partition_widget $frame.e$i}
                grid $frame.l$i -row $i -column 0 -sticky e -padx 5 -pady 2
                grid $frame.e$i -row $i -column 1 -sticky ew -padx 5 -pady 2
            }
        }
        if {$group eq "tpcc"} {
            $distributed_widget configure -command [list ::oceanbase::mysql::update_partition_count_state $partition_count_widget]
            update_partition_count_state $partition_count_widget
        } elseif {$group eq "tpch"} {
            $h_optimized_widget configure -command [list ::oceanbase::mysql::update_partition_count_state $h_partition_widget tpch ob_tpch_optimized_schema]
            update_partition_count_state $h_partition_widget tpch ob_tpch_optimized_schema
        }
        if {$option eq "drive"} {.oboptions.tabs select .oboptions.tabs.driver}
        ttk::frame .oboptions.buttons
        ttk::button .oboptions.buttons.ok -text OK -command ::oceanbase::mysql::save_options
        ttk::button .oboptions.buttons.cancel -text Cancel -command {destroy .oboptions}
        pack .oboptions.buttons.cancel .oboptions.buttons.ok -side right -padx 5 -pady 5
        pack .oboptions.buttons -fill x
    }
    proc validate {configuration} {config $configuration}
    proc counter {bm interval masterthread} {
        global configoceanbase
        with_config tcount_oceanbase_mysql $bm $interval $masterthread [dict get $configoceanbase connection ob_query_timeout]
    }

}
