# Independent OceanBase dialogs, following the native MySQL Connection/Settings
# layout, control types and option dependencies. No MySQL configuration is edited.
namespace eval oceanbase::mysql {
    variable options_context
    variable option_widgets

    proc option_fields {group option} {
        if {$option eq "counter"} {
            return {{tc_refresh_rate {Refresh Rate (secs)} entry} {tc_log_to_temp {Log Output to Temp} boolean}
                {tc_unique_log_name {Use Unique Log Name} boolean} {tc_log_timestamps {Log Timestamps} boolean}}
        }
        if {$group eq "tpcc"} {
            set schema {{ob_count_ware {Warehouses} warehouse} {ob_num_vu {Virtual Users to Build Schema} spin}
                {ob_storage_engine {Data Warehouse Storage Engine} engine} {ob_history_pk {History Primary Key} boolean}
                {ob_distributed_schema {Distributed schema} boolean} {ob_partition_count {Partition count} entry}}
            set driver {{ob_driver {Driver Script} driver} {ob_total_iterations {Total Transactions per User} entry}
                {ob_raiseerror {Exit on OceanBase Error} boolean} {ob_keyandthink {Keying and Thinking Time} boolean}
                {ob_prepared {Prepare Statements} boolean} {ob_no_stored_procs {No Stored Procedures} boolean}
                {ob_rampup {Minutes of Rampup Time} entry} {ob_duration {Minutes for Test Duration} entry}
                {ob_allwarehouse {Use All Warehouses} boolean} {ob_timeprofile {Time Profile} boolean}
                {ob_async_scale {Asynchronous Scaling} boolean} {ob_async_client {Asynch Clients per Virtual User} entry}
                {ob_async_delay {Asynch Client Login Delay (ms)} entry} {ob_async_verbose {Asynchronous Verbose} boolean}
                {ob_connect_pool {Cluster Connect Pool} boolean}}
        } else {
            set schema {{ob_tpch_storage_engine {Data Warehouse Storage Engine} engine} {ob_scale_fact {Scale Factor} scale}
                {ob_num_tpch_threads {Virtual Users to Build Schema} spin}
                {ob_tpch_optimized_schema {Distributed schema} boolean} {ob_tpch_partition_count {Partition count} entry}}
            set driver {{ob_total_querysets {Total Query Sets per User} entry} {ob_raise_query_error {Exit on OceanBase Error} boolean}
                {ob_verbose {Verbose Output} boolean} {ob_refresh_on {Refresh Function} boolean}
                {ob_update_sets {Number of Update Sets} entry} {ob_trickle_refresh {Trickle Refresh Delay (ms)} entry}
                {ob_refresh_verbose {Refresh Verbose} boolean} {ob_cloud_query {Cloud Analytic Queries} boolean}}
        }
        switch $option {
            build {return $schema}
            drive {return $driver}
            all {return [concat $schema $driver]}
            default {error "Unknown OceanBase options: $option"}
        }
    }

    proc option_row {frame row section key label kind} {
        variable options
        variable option_widgets
        ttk::label $frame.l$row -text "$label :"
        set widget $frame.e$row
        set valuevar ::oceanbase::mysql::options($section,$key)
        switch $kind {
            boolean {ttk::checkbutton $widget -variable $valuevar -onvalue true -offvalue false -command [list ::oceanbase::mysql::option_changed $key]}
            flag {ttk::checkbutton $widget -variable $valuevar -onvalue 1 -offvalue 0 -command [list ::oceanbase::mysql::option_changed $key]}
            driver {
                ttk::frame $widget
                foreach {value text} {test {Test Driver Script} timed {Timed Driver Script}} {
                    ttk::radiobutton $widget.$value -text $text -value $value -variable $valuevar -command [list ::oceanbase::mysql::option_changed $key]
                    pack $widget.$value -anchor w
                }
            }
            sslmode {
                ttk::frame $widget
                foreach {value text} {false {SSL One-Way} true {SSL Two-Way}} {
                    ttk::radiobutton $widget.$value -text $text -value $value -variable $valuevar -command [list ::oceanbase::mysql::option_changed $key]
                    pack $widget.$value -side left -padx 2
                }
            }
            engine {ttk::combobox $widget -textvariable $valuevar -values {innodb} -state readonly -width 28}
            scale {ttk::combobox $widget -textvariable $valuevar -values {1 10 30 100 300 1000 3000 10000 30000 100000} -width 28}
            warehouse {ttk::spinbox $widget -textvariable $valuevar -values [get_warehouse_list_for_spinbox] -width 28}
            spin {ttk::spinbox $widget -textvariable $valuevar -from 1 -to 512 -width 28}
            mode {ttk::combobox $widget -textvariable $valuevar -values [::oceanbase::supported_modes] -state readonly -width 28}
            default {
                ttk::entry $widget -textvariable $valuevar -width 30
                if {$kind eq "password"} {$widget configure -show *}
            }
        }
        grid $frame.l$row -row $row -column 0 -sticky e -padx 5 -pady 3
        grid $widget -row $row -column 1 -sticky ew -padx 5 -pady 3
        set option_widgets($key) $widget
    }

    proc option_enabled {key enabled} {
        variable option_widgets
        if {![info exists option_widgets($key)]} {return}
        set widget $option_widgets($key)
        if {$enabled} {$widget state !disabled} else {$widget state disabled}
        foreach child [winfo children $widget] {
            if {$enabled} {$child state !disabled} else {$child state disabled}
        }
    }

    proc option_changed {key} {
        variable options
        variable options_context
        set group [lindex $options_context 0]
        if {$group eq "tpcc"} {
            switch $key {
                ob_driver {
                    if {$options(tpcc,ob_driver) eq "test"} {
                        set options(tpcc,ob_async_scale) false
                        set options(tpcc,ob_async_verbose) false
                        set options(tpcc,ob_timeprofile) false
                        set options(tpcc,ob_allwarehouse) false
                    }
                }
                ob_async_scale {if {$options(tpcc,ob_async_scale) eq "true"} {set options(tpcc,ob_keyandthink) true}}
                ob_keyandthink {if {$options(tpcc,ob_keyandthink) eq "false"} {set options(tpcc,ob_async_scale) false}}
                ob_connect_pool {
                    if {$options(tpcc,ob_connect_pool) eq "true"} {
                        set options(tpcc,ob_prepared) true
                        set options(tpcc,ob_no_stored_procs) false
                    }
                }
                ob_prepared {if {$options(tpcc,ob_prepared) eq "true"} {set options(tpcc,ob_no_stored_procs) false}}
                ob_no_stored_procs {if {$options(tpcc,ob_no_stored_procs) eq "true"} {set options(tpcc,ob_prepared) false}}
            }
        }
        update_option_states
    }

    proc update_option_states {} {
        variable options
        variable options_context
        lassign $options_context group option
        set ssl [expr {$options(connection,ob_ssl) eq "true"}]
        foreach key {ob_ssl_two_way ob_ssl_linux_capath ob_ssl_windows_capath ob_ssl_ca ob_ssl_cipher} {option_enabled $key $ssl}
        foreach key {ob_ssl_cert ob_ssl_key} {option_enabled $key [expr {$ssl && $options(connection,ob_ssl_two_way) eq "true"}]}
        if {$option eq "counter"} {
            foreach key {tc_unique_log_name tc_log_timestamps} {option_enabled $key $options(counter,tc_log_to_temp)}
        } elseif {$group eq "tpcc"} {
            set timed [expr {$options(tpcc,ob_driver) eq "timed"}]
            foreach key {ob_rampup ob_duration ob_allwarehouse ob_timeprofile ob_async_scale} {option_enabled $key $timed}
            foreach key {ob_async_client ob_async_delay ob_async_verbose} {option_enabled $key [expr {$timed && $options(tpcc,ob_async_scale) eq "true"}]}
            option_enabled ob_keyandthink [expr {$options(tpcc,ob_async_scale) ne "true"}]
            option_enabled ob_prepared [expr {$options(tpcc,ob_connect_pool) ne "true" && $options(tpcc,ob_no_stored_procs) ne "true"}]
            option_enabled ob_no_stored_procs [expr {$options(tpcc,ob_connect_pool) ne "true" && $options(tpcc,ob_prepared) ne "true"}]
            option_enabled ob_partition_count [expr {$options(tpcc,ob_distributed_schema) eq "true"}]
        } else {
            foreach key {ob_update_sets ob_trickle_refresh ob_refresh_verbose} {option_enabled $key [expr {$options(tpch,ob_refresh_on) eq "true"}]}
            option_enabled ob_tpch_partition_count [expr {$options(tpch,ob_tpch_optimized_schema) eq "true"}]
        }
    }

    proc show_options {group option} {
        global configoceanbase genericdict
        variable options
        variable options_context
        variable option_widgets
        set normalized [::oceanbaseconfig::normalize $configoceanbase]
        catch {destroy .oboptions}
        array unset options
        array unset option_widgets
        set options_context [list $group $option]
        dict for {section values} $normalized {
            dict for {key value} $values {
                if {$key in {ob_pass ob_tpch_pass}} {set value [decode_password $value]}
                set options($section,$key) $value
            }
        }
        if {$option eq "counter"} {
            dict for {key value} [dict get $genericdict transaction_counter] {set options(counter,$key) $value}
        }
        ttk::toplevel .oboptions
        wm transient .oboptions .ed_mainFrame
        set workload [expr {$group eq "tpcc" ? "TPROC-C" : "TPROC-H"}]
        set caption [dict get {all Schema build Build drive Driver counter {Transaction Counter}} $option]
        wm title .oboptions "OceanBase $workload $caption Options"
        ttk::notebook .oboptions.tabs
        ttk::frame .oboptions.tabs.connection -padding 8
        ttk::frame .oboptions.tabs.settings -padding 8
        .oboptions.tabs add .oboptions.tabs.connection -text Connection
        .oboptions.tabs add .oboptions.tabs.settings -text Settings
        pack .oboptions.tabs -fill both -expand 1 -padx 5 -pady 5
        set frame .oboptions.tabs.connection
        set fields {{ob_compatibility_mode {Tenant Mode} mode} {ob_host {OceanBase Host} entry} {ob_port {OceanBase Port} entry}
            {ob_ssl {SSL} boolean} {ob_ssl_two_way {SSL Mode} sslmode}}
        set capath [expr {$::tcl_platform(platform) eq "windows" ? "ob_ssl_windows_capath" : "ob_ssl_linux_capath"}]
        lappend fields [list $capath {SSL CApath} entry]
        set fields [concat $fields {{ob_ssl_ca {SSL CA} entry} {ob_ssl_cert {SSL Cert} entry} {ob_ssl_key {SSL Key} entry}
            {ob_ssl_cipher {SSL Cipher} entry} {ob_tenant {Tenant Name} entry} {ob_cluster {Cluster Name} entry}
            {ob_query_timeout {Query Timeout (secs)} entry}}]
        set row 0
        foreach field $fields {lassign $field key label kind; option_row $frame [incr row] connection $key $label $kind}
        foreach {key label kind} [expr {$group eq "tpcc" ?
            {ob_user {OceanBase User} entry ob_pass {OceanBase User Password} password ob_dbase {TPROC-C OceanBase Database} entry} :
            {ob_tpch_user {OceanBase User} entry ob_tpch_pass {OceanBase User Password} password ob_tpch_dbase {TPROC-H OceanBase Database} entry}}] {
            if {$option eq "counter" && $kind eq "entry" && [string match *dbase $key]} {continue}
            option_row $frame [incr row] $group $key $label $kind
        }
        grid columnconfigure $frame 1 -weight 1
        # Settings follow MySQL's ordering and controls; scrolling keeps the full
        # schema+driver dialog usable on a standard 900-pixel remote desktop.
        set parent .oboptions.tabs.settings
        set background [ttk::style lookup TFrame -background]
        if {$background eq ""} {set background [option get . background Background]}
        canvas $parent.canvas -highlightthickness 0 -width 470 -height 480 -background $background
        ttk::scrollbar $parent.scroll -orient vertical -command [list $parent.canvas yview]
        $parent.canvas configure -yscrollcommand [list $parent.scroll set]
        ttk::frame $parent.canvas.fields -padding 4
        $parent.canvas create window 0 0 -anchor nw -window $parent.canvas.fields
        bind $parent.canvas.fields <Configure> [list ::oceanbase::mysql::resize_settings $parent.canvas]
        pack $parent.scroll -side right -fill y
        pack $parent.canvas -side left -fill both -expand 1
        set frame $parent.canvas.fields
        set row 0
        foreach field [option_fields $group $option] {
            lassign $field key label kind
            set section $group
            if {$option eq "counter"} {
                set section counter
                if {$kind eq "boolean"} {set kind flag}
            }
            option_row $frame [incr row] $section $key $label $kind
        }
        if {$group eq "tpcc" && $option in {all drive}} {
            ttk::label $frame.poolhelp -text "Pool endpoints: config/connectpool/obcpool.xml" -wraplength 440
            grid $frame.poolhelp -row [incr row] -column 0 -columnspan 2 -sticky w -padx 5 -pady 5
        }
        grid columnconfigure $frame 1 -weight 1
        ttk::frame .oboptions.buttons
        ttk::button .oboptions.buttons.cancel -text Cancel -command {destroy .oboptions}
        ttk::button .oboptions.buttons.ok -text OK -command ::oceanbase::mysql::save_options
        pack .oboptions.buttons.cancel .oboptions.buttons.ok -side right -padx 5 -pady 5
        pack .oboptions.buttons -fill x
        update_option_states
        if {$option eq "drive" || $option eq "counter"} {.oboptions.tabs select .oboptions.tabs.settings}
        wm geometry .oboptions +50+50
    }

    proc resize_settings {canvas} {$canvas configure -scrollregion [$canvas bbox all]}
    proc counter_options {bm} {show_options [expr {$bm eq "TPC-C" ? "tpcc" : "tpch"}] counter}
}
