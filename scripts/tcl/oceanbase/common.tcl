# Shared helpers for the standalone OceanBase Tcl and Python examples.
namespace eval ::ob_examples {
    proc env_value {name fallback} {
        if {[info exists ::env($name)]} {return $::env($name)}
        return $fallback
    }

    proc required_env {name} {
        set value [env_value $name {}]
        if {$value eq ""} {error "Set $name before running this example"}
        return $value
    }

    proc number {name fallback {minimum 1}} {
        set value [env_value $name $fallback]
        if {![string is integer -strict $value] || $value < $minimum} {
            error "$name must be an integer of at least $minimum"
        }
        return $value
    }

    proc configure {workload} {
        dbset db ob
        dbset bm $workload
        diset connection ob_compatibility_mode mysql
        diset connection ob_host [required_env OB_HOST]
        diset connection ob_port [number OB_PORT 2881]
        diset connection ob_tenant [env_value OB_TENANT {}]
        diset connection ob_cluster [env_value OB_CLUSTER {}]
        diset connection ob_query_timeout [number OB_QUERY_TIMEOUT 120]
        set user [required_env OB_USER]
        set password [env_value OB_PASSWORD {}]
        set database [required_env OB_DATABASE]
        if {$workload eq "TPROC-C"} {
            diset tpcc ob_user $user
            diset tpcc ob_pass $password
            diset tpcc ob_dbase $database
            diset tpcc ob_count_ware [number OB_WAREHOUSES 1]
            diset tpcc ob_num_vu [number OB_BUILD_USERS 1]
            diset tpcc ob_distributed_schema false
            diset tpcc ob_prepared false
            diset tpcc ob_no_stored_procs false
            diset tpcc ob_connect_pool false
            diset tpcc ob_async_scale false
            diset tpcc ob_driver timed
            diset tpcc ob_total_iterations 10000000
            diset tpcc ob_keyandthink false
            diset tpcc ob_rampup [number OB_RAMPUP 1 0]
            diset tpcc ob_duration [number OB_DURATION 1]
            diset tpcc ob_timeprofile true
            diset tpcc ob_raiseerror true
        } else {
            diset tpch ob_tpch_user $user
            diset tpch ob_tpch_pass $password
            diset tpch ob_tpch_dbase $database
            diset tpch ob_scale_fact [number OB_SCALE_FACTOR 1]
            diset tpch ob_num_tpch_threads [number OB_BUILD_USERS 1]
            diset tpch ob_tpch_optimized_schema false
            diset tpch ob_total_querysets [number OB_QUERYSETS 1]
            diset tpch ob_refresh_on false
            diset tpch ob_cloud_query false
            diset tpch ob_raise_query_error true
        }
    }

    proc assert_success {phase} {
        if {![info exists ::vustatus] || [dict size $::vustatus] == 0} {
            error "$phase did not run"
        }
        dict for {vu status} $::vustatus {
            if {$status ne "FINISH SUCCESS"} {
                error "$phase failed: virtual user $vu ($status)"
            }
        }
    }

    proc require_jobs {} {
        if {[job_disable_check]} {
            error {Enable the Jobs repository with "jobs disable 0", then restart HammerDB before running this example}
        }
    }

    proc job_file {workload} {
        set directory [findtempdir]
        if {$directory eq "notmpdir"} {error "No writable HammerDB temporary directory"}
        set benchmark [expr {$workload eq "TPROC-C" ? "tprocc" : "tproch"}]
        return [file join $directory "ob_${benchmark}.jobid"]
    }

    proc save_job {workload run_result} {
        if {![regexp {jobid=([[:xdigit:]]+)$} $run_result -> jobid]} {
            error "Run completed without a saved job ID: $run_result"
        }
        set filename [job_file $workload]
        set fd [open $filename w]
        try {puts $fd $jobid} finally {close $fd}
        puts "Saved OceanBase job ID to $filename"
    }

    proc capture_job_output {jobid query} {
        variable stdout_capture
        set stdout_capture {}
        rename ::puts ::ob_examples::saved_puts
        proc ::puts {args} {
            set words $args
            set newline true
            if {[lindex $words 0] eq "-nonewline"} {
                set newline false
                set words [lrange $words 1 end]
            }
            if {[llength $words] == 1} {
                set channel stdout
                set message [lindex $words 0]
            } elseif {[llength $words] == 2} {
                lassign $words channel message
            } else {
                tailcall ::ob_examples::saved_puts {*}$args
            }
            if {$channel ne "stdout"} {
                tailcall ::ob_examples::saved_puts {*}$args
            }
            append ::ob_examples::stdout_capture $message
            if {$newline} {append ::ob_examples::stdout_capture \n}
        }
        try {
            # Jobs emits some results directly and returns an empty string.
            # Capture its stdout just as the existing generic examples do.
            jobs $jobid $query
        } finally {
            rename ::puts {}
            rename ::ob_examples::saved_puts ::puts
        }
        return $stdout_capture
    }

    proc result {workload} {
        require_jobs
        set jobid [env_value OB_JOB_ID {}]
        if {$jobid eq ""} {
            set filename [job_file $workload]
            if {![file exists $filename]} {error "Run the benchmark first, or set OB_JOB_ID"}
            set fd [open $filename r]
            try {set jobid [string trim [read $fd]]} finally {close $fd}
        }
        if {![string is xdigit -strict $jobid]} {error "Invalid OceanBase job ID"}
        if {[hdbjobs eval {SELECT COUNT(*) FROM JOBMAIN WHERE JOBID=$jobid}] == 0} {
            error "Job $jobid was not found; use the same Jobs repository as the run"
        }
        set benchmark [expr {$workload eq "TPROC-C" ? "tprocc" : "tproch"}]
        set report [file join [findtempdir] "ob_${benchmark}_${jobid}.out"]
        if {$workload eq "TPROC-C"} {
            set sections {timing {TRANSACTION RESPONSE TIMES} tcount {TRANSACTION COUNT} result {HAMMERDB RESULT}}
        } else {
            set sections {1 {HAMMERDB RESULT}}
        }
        set results {}
        foreach {query label} $sections {
            set output [capture_job_output $jobid $query]
            if {[string trim $output] eq ""} {error "No $query output for job $jobid"}
            lappend results $label $output
        }
        set fd [open $report w]
        try {
            foreach {label output} $results {
                puts $label
                puts $output
                puts $fd $label
                puts $fd $output
            }
        } finally {close $fd}
        puts "Saved OceanBase result to $report"
    }

    proc main {workload phase} {
        if {$phase eq "result"} {
            result $workload
        } else {
            configure $workload
            try {
                switch -- $phase {
                    build {buildschema; assert_success Build}
                    check {checkschema; assert_success Check}
                    delete {deleteschema; assert_success Delete}
                    run {
                        require_jobs
                        loadscript
                        set default_users [expr {$workload eq "TPROC-C" ? 2 : 1}]
                        vuset vu [number OB_USERS $default_users]
                        vucreate
                        if {$workload eq "TPROC-C"} {tcstart}
                        set run_result [vurun]
                        assert_success Run
                        save_job $workload $run_result
                    }
                    default {error "Unknown OceanBase example phase: $phase"}
                }
            } finally {
                if {$phase eq "run" && $workload eq "TPROC-C"} {catch {tcstop}}
                catch {vudestroy}
            }
        }
        puts "OCEANBASE_EXAMPLE_SUCCESS $workload $phase"
    }
}
