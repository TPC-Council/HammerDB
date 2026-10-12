# OceanBase MySQL tenant session settings and transaction counters.
namespace eval oceanbasecommon {
    variable query_timeout 0

    proc configure {timeout} {
        variable query_timeout
        if {![string is integer -strict $timeout] || $timeout < 0} {
            error "Query timeout must be a non-negative number of seconds"
        }
        set query_timeout $timeout
    }

    proc configure_session {handle} {
        variable query_timeout
        if {$query_timeout > 0} {
            mysql::exec $handle "SET SESSION ob_query_timeout = [expr {wide($query_timeout) * 1000000}]"
        }
    }

    proc ssl_options {configuration} {
        set c [dict get $configuration connection]
        if {[dict get $c ob_ssl] ne "true"} {return {-ssl false}}
        set result {-ssl true}
        set key [expr {$::tcl_platform(platform) eq "windows" ? "ob_ssl_windows_capath" : "ob_ssl_linux_capath"}]
        set path [dict get $c $key]
        set ca [dict get $c ob_ssl_ca]
        set two_way [expr {[dict get $c ob_ssl_two_way] eq "true"}]
        if {$ca ne ""} {
            set file [file join $path $ca]
            if {![file readable $file]} {error "SSL CA file is not readable: $file"}
            lappend result -sslca $file
        } elseif {$path ne ""} {
            if {![file isdirectory $path]} {error "SSL CApath is not a directory: $path"}
            lappend result -sslcapath $path
        }
        if {$two_way} {
            foreach {field flag} {ob_ssl_cert -sslcert ob_ssl_key -sslkey} {
                set file [file join $path [dict get $c $field]]
                if {![file isfile $file] || ![file readable $file]} {error "SSL client file is not readable: $file"}
                lappend result $flag $file
            }
        }
        if {[dict get $c ob_ssl_cipher] ne "server"} {lappend result -sslcipher [dict get $c ob_ssl_cipher]}
        return $result
    }

    proc pool_connection {configuration} {
        foreach key {ob_pass ob_tenant ob_cluster} {
            if {![dict exists $configuration $key]} {dict set configuration $key {}}
        }
        foreach key {ob_host ob_port ob_user ob_dbase ob_ssl_options} {
            if {![dict exists $configuration $key]} {error "OceanBase connect pool is missing $key"}
        }
        set user [dict get $configuration ob_user]
        set tenant [dict get $configuration ob_tenant]
        set cluster [dict get $configuration ob_cluster]
        foreach part [list $user $tenant $cluster] {
            if {[regexp {[@#:\s]} $part]} {error "Connect pool requires separate user, tenant and cluster fields"}
        }
        if {$user eq "" || ($cluster ne "" && $tenant eq "")} {error "Invalid OceanBase connect pool user or tenant"}
        if {$tenant ne ""} {append user @$tenant}
        if {$cluster ne ""} {append user #$cluster}
        set port [dict get $configuration ob_port]
        if {![string is integer -strict $port] || $port < 1 || $port > 65535} {error "Invalid OceanBase connect pool port"}
        set mapped [dict create mysql_user $user mysql_socket null]
        foreach key {host port pass dbase ssl_options} {dict set mapped mysql_$key [dict get $configuration ob_$key]}
        # Validate the option list before it enters generated connection code.
        dict size [dict get $mapped mysql_ssl_options]
        return $mapped
    }

    proc counter_sql {} {
        # A MySQL tenant sees its own server statistics. Aggregate across its OBServers.
        return {SELECT NAME, SUM(VALUE) FROM oceanbase.GV$SYSSTAT
                WHERE NAME IN ('trans commit count', 'trans rollback count') GROUP BY NAME}
    }

    proc transaction_count {handle} {
        return [parse_transaction_count [mysql::sel $handle [counter_sql] -list]]
    }

    proc parse_transaction_count {rows} {
        set counters [dict create]
        foreach row $rows {
            if {[llength $row] != 2} {error "Unexpected OceanBase transaction counter row"}
            lassign $row name value
            if {![string is entier -strict $value] || $value < 0} {
                error "Invalid OceanBase transaction counter: $name"
            }
            dict set counters [string tolower $name] $value
        }
        set names {{trans commit count} {trans rollback count}}
        set total 0
        foreach name $names {
            if {![dict exists $counters $name]} {error "OceanBase transaction counter unavailable: $name"}
            incr total [dict get $counters $name]
        }
        return $total
    }
}
package provide oceanbasecommon 1.0
