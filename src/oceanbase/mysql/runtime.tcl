# Adapt only scripts generated for the OceanBase category.
namespace eval oceanbase::mysql {
    proc schema_entry_index {script entry} {
        # Recognize only a top-level invocation, never an entry-like line in a
        # procedure, SQL literal or multiline credential. The invocation itself
        # may still contain the generator's raw, not-yet-serialized password.
        set offset 0
        set pending {}
        foreach line [split $script \n] {
            if {$pending eq {} && [string first "$entry " $line] == 0} {return $offset}
            append pending $line \n
            incr offset [expr {[string length $line] + 1}]
            if {[info complete $pending]} {set pending {}}
        }
        error "OceanBase adapter: missing schema entry point $entry"
    }

    proc rewrite_binding {script {entry {}}} {
        # Keep generated configuration/credentials out of command translation.
        # A password, database name or certificate path can itself contain a
        # driver command name. Only the generated program uses the OB binding.
        set options_start -1
        if {[regexp {\A(?:#![^\n]*\n)?#OPTIONS\n} $script]} {
            set options_start [string first "#OPTIONS\n" $script]
        }
        set options {}
        if {$options_start >= 0} {
            set offset [expr {$options_start + 9}]
            set pending {}
            set options_end -1
            foreach line [split [string range $script $offset end] \n] {
                if {$pending eq {} && $line eq "#OPTIONS"} {
                    set options_end [expr {$offset + [string length $line]}]
                    break
                }
                append pending $line \n
                incr offset [expr {[string length $line] + 1}]
                if {[info complete $pending]} {set pending {}}
            }
            if {$options_end < 0} {error "OceanBase adapter: missing options boundary"}
            set options [string range $script $options_start $options_end]
            set library_end [string first \n $options 9]
            set options [string replace $options 9 $library_end "set library obmysqltcl ;# OceanBase client binding\n"]
            # This declaration immediately follows the library, before any data.
            set prefix "#OPTIONS\nset library obmysqltcl ;# OceanBase client binding\nglobal mysqlstatus\n"
            if {[string first $prefix $options] == 0} {
                set options [string replace $options 0 [expr {[string length $prefix] - 1}] \
                    "#OPTIONS\nset library obmysqltcl ;# OceanBase client binding\nglobal obmysqlstatus\n"]
            }
            set before [string range $script 0 [expr {$options_start - 1}]]
            set program [string range $script [expr {$options_end + 1}] end]
        } else {
            set before {}
            set program $script
            if {![regsub -line {^set library [^\n]+} $program {set library obmysqltcl} program]} {
                error "OceanBase adapter: missing binding selection"
            }
        }
        set invocation {}
        if {$entry ne {}} {
            set start [schema_entry_index $program $entry]
            set invocation [string range $program $start end]
            set program [string range $program 0 [expr {$start - 1}]]
        }
        set program [string map {
            mysql:: obmysql::
            mysqlconnect obmysqlconnect
            mysqlclose obmysqlclose
            mysqlexec obmysqlexec
            mysqluse obmysqluse
            mysqlstatus obmysqlstatus
        } $program]
        return "$before$options$program$invocation"
    }

    proc decode_password {value} {
        # diset/GUI store quotemeta escapes. Decode only that alphabet, leaving
        # literal backslashes (for example in a password containing \n) alone.
        if {[info exists ::quote_passwords] && !$::quote_passwords} {return $value}
        return [regsub -all {\\([][#$;{}])} $value {\1}]
    }

    proc rewrite_workload_credentials {script workload configuration} {
        set user_key [expr {$workload eq "tpcc" ? "mysql_user" : "mysql_tpch_user"}]
        set password_key [expr {$workload eq "tpcc" ? "mysql_pass" : "mysql_tpch_pass"}]
        set user [dict get $configuration $workload $user_key]
        set stored [dict get $configuration $workload $password_key]
        set password [decode_password $stored]
        # Match complete generator assignments, including any newlines. Their
        # interpolated values need not be valid Tcl before list serialization.
        foreach {variable value generated comment} [list \
            user $user $user {MySQL user} \
            password $password [quotemeta $stored] {Password for the MySQL user}] {
            set original "set $variable \"$generated\" ;# $comment"
            if {[string first $original $script] < 0} {error "OceanBase adapter: missing workload $variable assignment"}
            set script [string map [list $original "[list set $variable $value] ;# $comment"] $script]
        }
        return $script
    }

    proc rewrite_schema_entry {script workload action configuration} {
        set entry [dict get [dict create build do_$workload check check_$workload delete drop_schema] $action]
        set index [schema_entry_index $script $entry]
        set line [string range $script $index end]
        set user_key [expr {$workload eq "tpcc" ? "mysql_user" : "mysql_tpch_user"}]
        set password_key [expr {$workload eq "tpcc" ? "mysql_pass" : "mysql_tpch_pass"}]
        set database_key [expr {$workload eq "tpcc" ? "mysql_dbase" : "mysql_tpch_dbase"}]
        set user [dict get $configuration $workload $user_key]
        set encoded [quotemeta [dict get $configuration $workload $password_key]]
        # Decode the generator's backslash quoting without command or variable
        # substitution, then serialize all entry arguments as a Tcl list.
        set password [decode_password [dict get $configuration $workload $password_key]]
        set database [dict get $configuration $workload $database_key]
        set original "$user $encoded $database"
        if {[string first $original $line] < 0} {error "OceanBase adapter: missing schema credentials"}
        set line [string map [list $original [list $user $password $database]] $line]
        return "[string range $script 0 [expr {$index - 1}]][list {*}$line]"
    }

    proc rewrite_runtime {script timeout} {
        set library_check {if [catch {package require $library} message] { error "Failed to load $library - $message" }}
        if {[string first $library_check $script] < 0} {error "OceanBase adapter: missing generated library check"}
        append library_check "\n"
        set setup "package require oceanbasecommon\noceanbasecommon::load_client\n"
        append setup [list oceanbasecommon::configure $timeout] "\n"
        set script [string map [list $library_check $setup \
            {append connectstring " -host $host -port $port"} {lappend connectstring -host $host -port $port} \
            {append connectstring " $key [ dict get $ssl_options $key ] "} {lappend connectstring $key [dict get $ssl_options $key]} \
            {append connectstring " -user $user -password $password"} {lappend connectstring -user $user -password $password} \
            {set login_command "mysqlconnect [ dict get $connectstring ]"} {set login_command [linsert $connectstring 0 mysqlconnect]} \
            {puts "login_command $login_command"} {} \
            {return $mysql_handler} {oceanbasecommon::configure_session $mysql_handler
        return $mysql_handler} \
            {testresult $nopm $tpm MySQL} {testresult $nopm $tpm OceanBase} \
            {lsearch $table_exists $table} {lsearch -nocase $table_exists $table}] $script]
        foreach boundary {start end} {
            set original [string map [list @boundary@ $boundary] {            if {[catch {set handler_stat [ list [ mysql::sel $mysql_handler "show global status where Variable_name = 'Com_commit' or Variable_name =  'Com_rollback'" -list ] ]}]} {
                puts stderr {error, failed to query transaction statistics}
                return
            } else {
                regexp {\{\{Com_commit\ ([0-9]+)\}\ \{Com_rollback\ ([0-9]+)\}\}} $handler_stat all com_comm com_roll
                set @boundary@_trans [ expr $com_comm + $com_roll ]
            }}]
            set replacement [string map [list @boundary@ $boundary] {            if {[catch {set @boundary@_trans [oceanbasecommon::transaction_count $mysql_handler]} message]} {
                tsv::set application abort 1
                catch {mysqlclose $mysql_handler}
                error "Transaction statistics failed: $message"
            }}]
            set script [string map [list $original $replacement] $script]
        }
        return $script
    }

    proc rewrite_connect_pool {script} {
        set original {set cpool [ get_connect_xml mysql ]}
        if {[string first $original $script] < 0} {error "Cannot locate cluster connect pool configuration"}
        set marker {dict with conparams }
        append marker "\{"
        set replacement "set conparams \[oceanbasecommon::pool_connection \$conparams\]\n            $marker"
        if {[string first $marker $script] < 0} {error "Cannot locate cluster connect pool endpoints"}
        return [string map [list $original {set cpool [ get_connect_xml ob ]} $marker $replacement] $script]
    }

    proc rewrite_history_pk {script distributed} {
        if {$distributed eq "true"} {
            set original {`h_data` VARCHAR(24) BINARY NULL
)}
            set replacement {`h_data` VARCHAR(24) BINARY NULL,
  `id` INT NOT NULL AUTO_INCREMENT INVISIBLE,
PRIMARY KEY (`h_w_id`, `id`)
)}
            if {[string first $original $script] < 0} {error "Cannot locate distributed HISTORY table"}
            return [string map [list $original $replacement {`h_w_id` INT NULL} {`h_w_id` INT NOT NULL}] $script]
        }
        # OB's compatibility VERSION() is not a MySQL server version. Try the
        # requested native DDL and let the server report unsupported syntax.
        set original {if { [ string toupper $mysql_storage_engine ] eq "INNODB" && $history_pk }}
        append original " \{"
        set start [string first $original $script]
        set end [string first {    set sql(1)} $script $start]
        if {$start < 0 || $end < 0} {error "Cannot locate MySQL HISTORY primary-key capability gate"}
        return [string replace $script $start [expr {$end - 1}] {}]
    }
}
