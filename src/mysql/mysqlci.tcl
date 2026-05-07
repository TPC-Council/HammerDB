proc mysql_ci_id {cidict refname} {
    global rdbms
    set dbprefix [find_prefix $rdbms]
    # ensure JOBCI row
    set ci_id [ci_latest_id $refname]
    if {$ci_id eq ""} {
        hdbjobs eval {INSERT INTO JOBCI (refname,dbprefix,cidict) VALUES ($refname,$dbprefix,$cidict)}
        set ci_id [ci_latest_id $refname]
    }
    return $ci_id
}

proc calc_redo_mb {} {
    # derive from buffer pool
    set bp_mb [calc_buffer_pool_mb]

    if {$bp_mb <= 0} {
        return 2048
    }

    # 25% of buffer pool
    set redo_mb [expr {$bp_mb / 4}]

    # range 2GB–32GB
    if {$redo_mb < 2048}  { set redo_mb 2048 }
    if {$redo_mb > 32768} { set redo_mb 32768 }

    return $redo_mb
}

proc mysql_ci_safe_ref {refname} {
    # safe path part
    return [string map {/ _} $refname]
}

proc mysql_get_io_intensive {ci_id} {
    set io 0
    catch {
        set io [hdbjobs eval {
            SELECT io_intensive
            FROM JOBCI
            WHERE ci_id = $ci_id
        }]
    }
    if {$io ni {0 1 "0" "1"}} {
        set io 0
    }
    return $io
}

proc mysql_set_uaw_env {cidict refname} {
    set ci_id [mysql_ci_id $cidict $refname]
    set io_intensive [mysql_get_io_intensive $ci_id]

    if {$io_intensive == 1} {
        set ::env(UAW) 1
        putsci "HammerDB UAW enabled for $refname"
    } else {
        set ::env(UAW) 0
        putsci "HammerDB UAW disabled for $refname"
    }
}

proc mysql_normpath {p} {
    # normalise path
    if {$p eq ""} {
        return ""
    }
    return [file join {*}[file split $p]]
}


proc mysql_clone {cidict refname} {
    global rdbms
    set build_dir [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set repo_url       [string map {\" {}} [dict get $cidict $rdbms build repo_url]]
    set ci_id [mysql_ci_id $cidict $refname]
    set safe_ref [mysql_ci_safe_ref $refname]
    set local_dir "$build_dir/ci_${ci_id}_${safe_ref}"
    file mkdir $local_dir

    set is_commit 0
    set ref_trim [string trim $refname]

    # detect commit
    if {[regexp {^[0-9a-fA-F]{7,40}$} $ref_trim]} {
        set is_commit 1
    }

    if {$is_commit} {
        putsci "Cloning repository for commit $ref_trim into $local_dir"
    } else {
        set branch [file tail $ref_trim]
        putsci "Cloning branch $branch into $local_dir"
    }
    putsci "repo_url is $repo_url"

    if {$is_commit} {
        # clone commit
        set shell_cmd "cd \"$local_dir\" && git clone \"$repo_url\" . && git checkout $ref_trim 2>&1"
    } else {
        # clone branch/tag
        set raw_cmd  [dict get $cidict common clone_cmd]
        set raw_args [dict get $cidict common clone_cmd_args]
        set branch   [file tail $ref_trim]
        set args_sub [string map [list ":branch" $branch ":repo_url" $repo_url] $raw_args]
        set cmd_full "$raw_cmd $args_sub"
        set shell_cmd "cd \"$local_dir\" && $cmd_full 2>&1"
    }

    # save command
   if {[catch {
       set ci_id [ci_latest_id $refname]
       if {$ci_id ne ""} {
           hdbjobs eval { UPDATE JOBCI SET clone_cmd = $shell_cmd WHERE ci_id = $ci_id }
       } else {
           putsci "Error saving clone_cmd: no JOBCI row found for refname $refname"
       }
   } err]} {
       putsci "Error saving clone_cmd: $err"
   }

    putsci "Running clone command..."
    putsci $shell_cmd

    # escape quotes
    set safe_cmd [string map {\" \\\"} $shell_cmd]

    set pipe_output ""
    set clone_status "CLONE SUCCEEDED"

    if {[catch {
        set pipe [open "|bash -c \"$safe_cmd\"" "r"]
        fconfigure $pipe -blocking 1 -buffering line
        while {[gets $pipe line] >= 0} {
            append pipe_output "$line\n"
            putsci $line
            if {[regexp -nocase {fatal:|error:} $line]} {
                # failure
                set clone_status "CLONE FAILED"
            }
        }

        if {[catch {close $pipe} close_err]} {
            append pipe_output "\rError closing pipe: $close_err\n"
        }

    } clone_err]} {
        set clone_status "CLONE FAILED"
        append pipe_output "\rFailed to start clone: $clone_err\n"
    }

   if {$clone_status eq "CLONE FAILED"} {
      putsci "Clone failed."
      putsci "Full clone output:"
      putsci $pipe_output
      catch {
         set ci_id [ci_latest_id $refname]
         if {$ci_id ne ""} {
            hdbjobs eval { UPDATE JOBCI SET status = 'CLONE FAILED', clone_output = $pipe_output WHERE ci_id = $ci_id }
         }
      }
   } else {
      putsci "Clone succeeded."
      catch {
         set ci_id [ci_latest_id $refname]
         if {$ci_id ne ""} {
            hdbjobs eval { UPDATE JOBCI SET clone_output = $pipe_output WHERE ci_id = $ci_id }
         }
      }
   }
    return $clone_status
}

proc mysql_build {cidict refname} {
    global rdbms
    set build_dir [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set ci_id [mysql_ci_id $cidict $refname]
    set safe_ref [mysql_ci_safe_ref $refname]
    set local_dir "$build_dir/ci_${ci_id}_${safe_ref}"

    # build command
    set raw_cmd  [dict get $cidict $rdbms build build_cmd]
    # build args
    set raw_args ""
    if {[dict exists $cidict $rdbms build build_cmd_args]} {
        set raw_args [string trim [dict get $cidict $rdbms build build_cmd_args]]
    }
    # tune --parallel
    # else keep setting
    if {[info commands numberOfCPUs] ne ""} {
        set cpu ""
        catch { set cpu [numberOfCPUs] }
        set cpu [string trim $cpu]

        if {[string is integer -strict $cpu] && $cpu > 0} {
            # only default args
            if {$raw_args eq "--parallel 8"} {
                if {$cpu <= 2} {
                    set raw_args ""
                } elseif {$cpu <= 4} {
                    set raw_args "--parallel 2"
                } elseif {$cpu <= 8} {
                    set raw_args "--parallel 4"
                } else {
                    # cpu-4 max 64
                    set p [expr {$cpu - 4}]
                    if {$p < 1}  { set p 1 }
                    if {$p > 64} { set p 64 }
                    set raw_args "--parallel $p"
                }
            }
        }
    }
    # build command
    set cmd_full [string trim "$raw_cmd $raw_args"]
    set shell_cmd "cd \"$local_dir\" && $cmd_full 2>&1"

    # save command
    if {[catch {
       set ci_id [ci_latest_id $refname]
       if {$ci_id ne ""} {
          hdbjobs eval { UPDATE JOBCI SET build_cmd = $shell_cmd WHERE ci_id = $ci_id }
       } else {
          putsci "Error saving build_cmd: no JOBCI row found for refname $refname"
       }
    } err]} {
       putsci "Error saving build_cmd: $err"
    }

    putsci "Running build command..."
    putsci $shell_cmd

    set safe_cmd [string map {\" \\\"} $shell_cmd]

    set pipe_output ""
    set build_status "BUILD SUCCEEDED"
    set failed_line ""

    if {[catch {
        set pipe [open "|bash -c \"$safe_cmd\"" "r"]
        fconfigure $pipe -blocking 1 -buffering line

        while {[gets $pipe line] >= 0} {
            append pipe_output "$line\n"
            putsci $line

            if {$failed_line eq "" && ![regexp {^troff:} $line] && [regexp -nocase {fatal:|error:} $line]} {
                set failed_line $line
            }
        }

        if {[catch {close $pipe} close_err close_opts]} {
            if {[dict exists $close_opts -errorcode]} {
                set ec [dict get $close_opts -errorcode]

                if {[llength $ec] > 0 && [lindex $ec 0] eq "CHILDSTATUS"} {
                    append pipe_output "Error closing pipe: $close_err\n"
                    append pipe_output "errorcode: $ec\n"
                    set failed_line "Error closing pipe: $close_err (errorcode: $ec)"
                    set build_status "BUILD FAILED"
                }
            }
        }
    } build_err]} {
        append pipe_output "Build runner error: $build_err\n"
        set failed_line "Build runner error: $build_err"
        set build_status "BUILD FAILED"
    }

    if {$build_status eq "BUILD FAILED"} {
        putsci "Build failed at line: $failed_line"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval { UPDATE JOBCI SET status = 'BUILD FAILED', build_output = $pipe_output WHERE ci_id = $ci_id }
            }
        }
    } else {
        putsci "Build succeeded."
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval { UPDATE JOBCI SET build_output = $pipe_output WHERE ci_id = $ci_id }
            }
        }
    }
    return $build_status
}

proc mysql_package {cidict refname} {
    global rdbms
    set build_dir [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set ci_id [mysql_ci_id $cidict $refname]
    set safe_ref [mysql_ci_safe_ref $refname]
    set local_dir "$build_dir/ci_${ci_id}_${safe_ref}"

    # package command
    set raw_cmd   [dict get $cidict $rdbms build package_cmd]
    set shell_cmd "cd \"$local_dir\" && $raw_cmd 2>&1"

    # save command
    if {[catch {
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval { UPDATE JOBCI SET package_cmd = $shell_cmd WHERE ci_id = $ci_id }
        } else {
            putsci "Error saving package_cmd: no JOBCI row found for refname $refname"
        }
    } err]} {
        putsci "Error saving package_cmd: $err"
    }

    putsci "Running package command..."
    putsci $shell_cmd

    set safe_cmd [string map {\" \\\"} $shell_cmd]

    set pipe_output ""
    set package_status "PACKAGE SUCCEEDED"

    if {[catch {
        set pipe [open "|bash -c \"$safe_cmd\"" "r"]
        fconfigure $pipe -blocking 1 -buffering line
        while {[gets $pipe line] >= 0} {
            append pipe_output "$line\n"
            putsci $line
        }
        if {[catch {close $pipe} close_err]} {
            append pipe_output "Packaging command exited with error: $close_err\n"
            set failed_line "Packaging failed: $close_err"
            set package_status "PACKAGE FAILED"
        }
    } package_err]} {
        append pipe_output "Failed to start packaging command: $package_err\n"
        set failed_line "Failed to start packaging command: $package_err"
        set package_status "PACKAGE FAILED"
    }
    if {$package_status eq "PACKAGE FAILED"} {
        putsci "Packaging failed at line: $failed_line"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval { UPDATE JOBCI SET status = 'PACKAGE FAILED', package_output = $pipe_output WHERE ci_id = $ci_id }
            }
        }
    } else {
        putsci "Packaging succeeded."
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval { UPDATE JOBCI SET package_output = $pipe_output WHERE ci_id = $ci_id }
            }
        }
    }
    return $package_status
}

proc mysql_commit_msg {cidict refname} {
    global rdbms
    set build_dir [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set ci_id [mysql_ci_id $cidict $refname]
    set safe_ref [mysql_ci_safe_ref $refname]
    set local_dir "$build_dir/ci_${ci_id}_${safe_ref}"

    # commit msg command
    set raw_commit_cmd [dict get $cidict common commit_msg_cmd]
    set shell_cmd      "cd \"$local_dir\" && $raw_commit_cmd 2>&1"

    # save command
    catch {
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            # ignore missing column
            hdbjobs eval { UPDATE JOBCI SET commit_msg_cmd = $shell_cmd WHERE ci_id = $ci_id }
        } else {
            putsci "Error saving commit_msg_cmd: no JOBCI row found for refname $refname"
        }
    }

    putsci "Fetching commit message..."
    putsci $shell_cmd

    set safe_cmd [string map {\" \\\"} $shell_cmd]

    set pipe_output ""
    set commit_msg ""
    set status "COMMIT_MSG SUCCEEDED"

    if {[catch {
        set pipe [open "|bash -c \"$safe_cmd\"" "r"]
        fconfigure $pipe -blocking 1 -buffering line
        while {[gets $pipe line] >= 0} {
            append pipe_output "$line\n"
            # don't spam putsci
            putsci $line
        }
        if {[catch {close $pipe} close_err]} {
            append pipe_output "Commit msg command exited with error: $close_err\n"
            set status "COMMIT_MSG FAILED"
        }
    } commit_err]} {
        append pipe_output "Failed to start commit msg command: $commit_err\n"
        set status "COMMIT_MSG FAILED"
    }

    # commit msg output
    if {$status eq "COMMIT_MSG SUCCEEDED"} {
        set commit_msg [string trim $pipe_output]
        if {$commit_msg eq ""} {
            # empty = failure
            set status "COMMIT_MSG FAILED"
        }
    }

    # save results
    if {$status eq "COMMIT_MSG FAILED"} {
        putsci "Commit message fetch failed."
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                # ignore missing column
                hdbjobs eval { UPDATE JOBCI SET status = 'COMMIT_MSG FAILED', commit_msg_output = $pipe_output WHERE ci_id = $ci_id }
            }
        }
        return "Could not fetch commit message: [string trim $pipe_output]"
    } else {
        putsci "Commit message fetched."
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval { UPDATE JOBCI SET commit_msg = $commit_msg WHERE ci_id = $ci_id }
                catch { hdbjobs eval { UPDATE JOBCI SET commit_msg_output = $pipe_output WHERE ci_id = $ci_id } }
            }
        }
        return "Commit message: $commit_msg"
    }
}

proc mysql_install {cidict refname} {
    global rdbms

    set build_dir [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set ci_id [mysql_ci_id $cidict $refname]
    set safe_ref [mysql_ci_safe_ref $refname]
    set local_dir "$build_dir/ci_${ci_id}_${safe_ref}"
    set install_root [mysql_normpath [dict get $cidict $rdbms install install_dir]]
    set install_dir  [file join $install_root "ci_${ci_id}_${safe_ref}"]
    # validate target
    if {![file exists $install_root] || ![file isdirectory $install_root] || ![file writable $install_root]} {
        putsci "Error: $install_root missing, not a directory, or not writable"
        return "INSTALL FAILED"
    }

    file mkdir $install_dir

    # package file
    set files [glob -nocomplain -directory $local_dir *.tar.gz]
    if {[llength $files] > 0} {
        set first_file [file tail [lindex $files 0]]
    } else {
        return "INSTALL FAILED"
    }

    # command
    set raw_cmd   [dict get $cidict $rdbms install install_package]
    set shell_cmd "cd \"$local_dir\" && $raw_cmd $first_file -C $install_dir 2>&1"
    set safe_cmd  [string map {\" \\\"} $shell_cmd]

    putsci "Installing package $first_file to $install_dir"

    # save command
    catch {
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval { UPDATE JOBCI SET install_cmd = $shell_cmd WHERE ci_id = $ci_id }
        } else {
            putsci "Error saving install_cmd: no JOBCI row found for refname $refname"
        }
    } err
    if {[info exists err] && $err ne ""} {
        putsci "Error saving install_cmd: $err"
    }

    putsci "Running install command..."
    putsci $shell_cmd

    # capture output
    set doneVar "::pipe_done_install_[clock milliseconds]"
    set $doneVar 0
    set ::pipe_output ""
    if {[catch {
        set pipe [open "|bash -c \"$safe_cmd\"" "r"]
        fconfigure $pipe -translation lf -blocking 1 -buffering line
        while {[gets $pipe line] >= 0} {
            append ::pipe_output "$line\n"
            putsci $line
        }
        close $pipe
    } install_err]} {

        putsci "Install failed: $install_err"

        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                set out $::pipe_output
                if {$out ne ""} { append out "\n" }
                append out "ERROR: $install_err"
                hdbjobs eval { UPDATE JOBCI SET status = 'INSTALL FAILED', install_output = $out WHERE ci_id = $ci_id }
            }
        }
        return "INSTALL FAILED"
    } else {
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                set out $::pipe_output
                if {$out ne ""} { append out "\n" }
                hdbjobs eval { UPDATE JOBCI SET status = 'INSTALLED', install_output = $out WHERE ci_id = $ci_id }
            }
        }
        return "INSTALL SUCCEEDED"
    }
}

proc mysql_init {cidict refname} {
    global rdbms
    set install_section [dict get $cidict $rdbms install]
    set ci_id [mysql_ci_id $cidict $refname]
    set safe_ref [mysql_ci_safe_ref $refname]

    # basedir
    if {![dict exists $install_section install_dir]} {
        putsci "DB init failed: <install_dir> missing in XML"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'INIT FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "INIT FAILED"
    }
    set install_root [dict get $install_section install_dir]
    set parent "$install_root/ci_${ci_id}_${safe_ref}"
    set candidates [glob -nocomplain -types d -directory $parent mysql-*]
    if {[llength $candidates] == 0} {
        putsci "DB init failed: no mysql-* directories under $parent"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'INIT FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "INIT FAILED"
    }
    set basedir ""; set newest -1
    foreach d $candidates {
        set m [file mtime $d]
        if {$m > $newest} { set newest $m ; set basedir $d }
    }

    # validate installer
    if {![dict exists $install_section installer]} {
        putsci "DB init failed: <installer> missing in XML"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'INIT FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "INIT FAILED"
    }
    set installer      [dict get $install_section installer]
    set installer_path [file join $basedir $installer]
    if {![file exists $installer_path]} {
        putsci "DB init failed: installer not found at $installer_path"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'INIT FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "INIT FAILED"
    }

    # check exists and copy config
    if {![dict exists $install_section defaults_file]} {
        putsci "INIT FAILED: <defaults_file> missing in XML"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'INIT FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "INIT FAILED"
    }

    set defaults_src [dict get $install_section defaults_file]

    if {![file exists $defaults_src]} {
        putsci "INIT FAILED: defaults file not found: $defaults_src"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'INIT FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "INIT FAILED"
    }

    set defaults_name "my.cnf"
    if {[dict exists $install_section defaults_file]} {
        set defaults_name [file tail [dict get $install_section defaults_file]]
    }

    set defaults_dst [file join $basedir $defaults_name]

    if {![file exists [file dirname $defaults_dst]]} {
        catch {file mkdir [file dirname $defaults_dst]}
    }

    if {[catch {file copy -force $defaults_src $defaults_dst} err]} {
        putsci "INIT FAILED: could not copy defaults file $defaults_src to $defaults_dst : $err"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'INIT FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "INIT FAILED"
    }
    putsci "Copied defaults file $defaults_src to $defaults_dst"

    set io_src $defaults_src
    set io_name "myio.cnf"
    if {[dict exists $install_section io_config_file]} {
        set io_src [dict get $install_section io_config_file]
        set io_name [file tail $io_src]
    }

    if {![file exists $io_src]} {
        putsci "INIT FAILED: IO config file not found: $io_src"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'INIT FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "INIT FAILED"
    }

    set io_dst [file join $basedir $io_name]
    if {[catch {file copy -force $io_src $io_dst} err]} {
        putsci "INIT FAILED: could not copy IO config file $io_src to $io_dst : $err"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'INIT FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "INIT FAILED"
    }
    putsci "Copied IO config file $io_src to $io_dst"

    set io_dst [file join $basedir $io_name]
    catch {file copy -force $io_src $io_dst}
    putsci "Copied IO config file $io_src to $io_dst"

    # data/redo dirs
    set datadir_val ""
    if {[dict exists $install_section datadir]} { set datadir_val [dict get $install_section datadir] }
    if {$datadir_val ne "" && [file pathtype $datadir_val] ne "absolute"} {
        set datadir_val [file join $basedir $datadir_val]
    }
    if {$datadir_val ne ""} { catch {file mkdir $datadir_val} }

    set redo_val ""
    if {[dict exists $install_section innodb_log_group_home_dir]} {
        set redo_val [dict get $install_section innodb_log_group_home_dir]
    }
    if {$redo_val ne "" && [file pathtype $redo_val] ne "absolute"} {
        set redo_val [file join $basedir $redo_val]
    }
    if {$redo_val ne ""} { catch {file mkdir $redo_val} }

    # installer args
    set arglist {}
    set want_basedir 1
    if {[dict exists $install_section init_args]} {
        foreach argname [dict get $install_section init_args] {
            set lname [string tolower $argname]
            if {$lname eq "basedir"} {
                lappend arglist "--basedir=\"$basedir\""
                set want_basedir 0
                continue
            }
            set val ""
            if {$lname eq "defaults_file"} {
                set val $defaults_dst
            } elseif {$lname eq "datadir"} {
                if {$datadir_val ne ""} { set val $datadir_val }
            } elseif {$lname eq "innodb_log_group_home_dir"} {
                if {$redo_val ne ""} { set val $redo_val }
            } else {
                if {[dict exists $install_section $argname]} {
                    set val [dict get $install_section $argname]
                } elseif {[dict exists $install_section [string map {- _} $argname]]} {
                    set val [dict get $install_section [string map {- _} $argname]]
                } elseif {[dict exists $install_section [string map {_ -} $argname]]} {
                    set val [dict get $install_section [string map {_ -} $argname]]
                }
            }
            if {$val eq ""} {
                putsci "Warning: init_args '$argname' has no value in XML"
                continue
            }
            set flag "--[string map {_ -} $argname]=\"[string map {\" \\\"} $val]\""
            lappend arglist $flag
        }
    }
    if {$want_basedir} {
        lappend arglist "--basedir=\"$basedir\""
    }
        lappend arglist "--innodb-redo-log-capacity=[calc_redo_mb]M"

    # MySQL-specific: mysqld needs --initialize-insecure to perform first-time
    # data directory initialization (MariaDB uses scripts/mariadb-install-db
    # which implies initialize mode; MySQL reuses bin/mysqld for both init and
    # server and requires this explicit boolean flag).
    lappend arglist "--initialize-insecure"

    # run installer
    set args_str  [join $arglist " "]
    set init_cmd  "cd \"$basedir\" && ./[dict get $install_section installer] $args_str 2>&1"
    set safe_cmd  [string map {\" \\\"} $init_cmd]

    putsci "Initializing MySQL with command:"
    putsci $init_cmd

    set init_status "INIT SUCCEEDED"
    # capture output
    set doneVar "::pipe_done_init_[clock milliseconds]"
    set $doneVar 0
    set ::pipe_output ""
    set init_status "INIT SUCCEEDED"

    if {[catch {
        set pipe [open "|bash -c \"$safe_cmd\"" "r"]
        fconfigure $pipe -translation lf -blocking 1 -buffering line

        while {[gets $pipe line] >= 0} {
            append ::pipe_output "$line\n"
            putsci $line
        }

        close $pipe
    } init_err]} {

        putsci "DB init failed: $init_err"
        set init_status "INIT FAILED"

    }
    if {$init_status eq "INIT FAILED"} {
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'INIT FAILED' WHERE ci_id = $ci_id}
            }
        }
    } else {
        set init_status "INIT SUCCEEDED"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval { UPDATE JOBCI SET status = 'INITIALIZED' WHERE ci_id = $ci_id }
            }
        }
    }
    return $init_status 
}

proc mysql_start {cidict refname} {
    global rdbms
    set install [dict get $cidict $rdbms install]
    set ci_id [mysql_ci_id $cidict $refname]
    set safe_ref [mysql_ci_safe_ref $refname]
    set io_intensive [mysql_get_io_intensive $ci_id]

    # basedir
    set install_root [dict get $install install_dir]
    set parent "$install_root/ci_${ci_id}_${safe_ref}"
    set candidates [glob -nocomplain -types d -directory $parent mysql-*]
    if {[llength $candidates] == 0} {
        putsci "DB start failed: no mysql-* directories under $parent"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'START FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "START FAILED"
    }
    set basedir ""
    set newest -1
    foreach d $candidates {
        set m [file mtime $d]
        if {$m > $newest} {
            set newest $m
            set basedir $d
        }
    }

    # Validate start command
    if {![dict exists $install start_cmd]} {
        putsci "DB start failed: <start_cmd> missing in XML"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'START FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "START FAILED"
    }
    set start_cmd [dict get $install start_cmd]

    # defaults file
    if {$io_intensive == 1 && [dict exists $install io_config_file]} {
        set defaults_src [dict get $install io_config_file]
        putsci "Using Durable / I/O intensive config: $defaults_src"
    } else {
        set defaults_src [dict get $install defaults_file]
        putsci "Using default config: $defaults_src"
    }

    set defaults_name [file tail $defaults_src]
    set defaults_dst [file join $basedir $defaults_name]

    # datadir/redo
    set datadir_val ""
    if {[dict exists $install datadir]} {
        set datadir_val [dict get $install datadir]
    }
    if {$datadir_val ne "" && [file pathtype $datadir_val] ne "absolute"} {
        set datadir_val [file join $basedir $datadir_val]
    }

    set redo_val ""
    if {[dict exists $install innodb_log_group_home_dir]} {
        set redo_val [dict get $install innodb_log_group_home_dir]
    }
    if {$redo_val ne "" && [file pathtype $redo_val] ne "absolute"} {
        set redo_val [file join $basedir $redo_val]
    }

    # buffer pool
    set bp_cfg ""
    if {[dict exists $install innodb_buffer_pool_size]} {
        set bp_cfg [string trim [dict get $install innodb_buffer_pool_size]]
    }

    # args
    set argnames [expr {[dict exists $install start_args] ? [dict get $install start_args] : {defaults_file basedir datadir innodb_log_group_home_dir}}]
    set arglist {}
    set want_basedir 1
    set socket_requested 0
    set port_requested 0
    set socket_val ""
    set port_val ""

    foreach argname $argnames {
        set lname [string tolower $argname]

        if {$lname eq "socket"} {
            set socket_requested 1
            if {[dict exists $install socket]} {
                set socket_val [dict get $install socket]
            }
            continue
        }
        if {$lname eq "port"} {
            set port_requested 1
            if {[dict exists $install port]} {
                set port_val [dict get $install port]
            }
            continue
        }

        set val ""
        if {$lname eq "defaults_file"} {
            set val $defaults_dst
        } elseif {$lname eq "basedir"} {
            set val $basedir
            set want_basedir 0
        } elseif {$lname eq "datadir"} {
            if {$datadir_val ne ""} {
                set val $datadir_val
            }
        } elseif {$lname eq "innodb_log_group_home_dir"} {
            if {$redo_val ne ""} {
                set val $redo_val
            }
        } elseif {[dict exists $install $argname]} {
            set raw [dict get $install $argname]
            if {[string is integer -strict $raw]} {
                set val $raw
            } elseif {[file pathtype $raw] ne "absolute"} {
                set val [file join $basedir $raw]
            } else {
                set val $raw
            }
        }

        if {$val ne ""} {
            set flag "--[string map {_ -} $argname]=\"[string map {\" \\\"} $val]\""
            lappend arglist $flag
        } else {
            putsci "Warning: start_args '$argname' has no value in XML"
        }
    }

    # start-time override
    set bp_mb 1000
    if {$bp_cfg eq "" || [string equal -nocase $bp_cfg "auto"]} {
        set bp_mb [calc_buffer_pool_mb]
        if {$bp_mb > 0} {
            putsci "Auto-tune: innodb_buffer_pool_size=${bp_mb}M"
        }
    } elseif {[string is integer -strict $bp_cfg]} {
        set bp_mb $bp_cfg
        putsci "User override: innodb_buffer_pool_size=${bp_mb}M"
    } else {
        putsci "WARNING: invalid innodb_buffer_pool_size='$bp_cfg' (expected auto or MB integer)"
    }
    if {$bp_mb > 0} {
        lappend arglist "--innodb-buffer-pool-size=${bp_mb}M"
    }

    if {$want_basedir} {
        lappend arglist "--basedir=\"$basedir\""
    }
        lappend arglist "--innodb-redo-log-capacity=[calc_redo_mb]M"
    # Note: --thread-pool-size is intentionally omitted here. The thread_pool
    # plugin is only bundled with MySQL Enterprise Edition; Community builds
    # (what cipush compiles from source) abort startup with "Plugin 'thread_pool'
    # is not loaded" when this flag is provided. MariaDB ships thread_pool in
    # its default build, which is why mariaci.tcl can include it.

    # prefer socket
    if {$socket_requested && $socket_val ne ""} {
        lappend arglist "--socket=\"[string map {\" \\\"} $socket_val]\""
    } elseif {$port_requested && $port_val ne ""} {
        if {![string is integer -strict $port_val]} {
            putsci "Warning: <port> must be integer; ignoring"
        } else {
            lappend arglist "--port=$port_val"
        }
    }

    # MySQL requires --defaults-file to appear before any other option,
    # otherwise it is parsed as an unknown variable. Hoist it to the front.
    set defaults_flag ""
    set rest_args {}
    foreach a $arglist {
        if {[string match "--defaults-file=*" $a] && $defaults_flag eq ""} {
            set defaults_flag $a
        } else {
            lappend rest_args $a
        }
    }
    set args_str [join $rest_args " "]
    # MySQL 8.0+: --daemonize forks mysqld to background so it survives
    # the parent pipe being closed when the cipush worker exits.
    set full_cmd "cd \"$basedir\" && $start_cmd"
    if {$defaults_flag ne ""} { append full_cmd " $defaults_flag" }
    append full_cmd " --daemonize $args_str"
    regsub -all {"} $full_cmd {\\"} full_cmd

    putsci "Starting MySQL:"
    putsci $full_cmd
    # Save parameters and start command
    set config_file ""
    if {[file exists $defaults_dst]} {
        if {[catch {
            set fh [open $defaults_dst r]
            set config_file [read $fh]
            close $fh
        } err]} {
            putsci "WARNING: could not read config file $defaults_dst : $err"
            set config_file ""
        }
    } else {
        putsci "WARNING: config file not found: $defaults_dst"
    }

    set safe_cmd [string map {' ''} $full_cmd]
    set safe_cfg [string map {' ''} $config_file]

    catch {
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval "
                UPDATE JOBCI
                SET config_file = '$safe_cfg',
                    start_cmd   = '$safe_cmd'
                WHERE ci_id = $ci_id
            "
        }
    }

    set ::pipe_done 0
    if {[catch {
        set pipe [open "|bash -c \"$full_cmd\"" "r"]
        fconfigure $pipe -blocking 0 -buffering line
        fileevent $pipe readable [list handle_output $pipe]
        after 10000 {set ::pipe_done 1}
        vwait ::pipe_done
    } err]} {
        putsci "DB start failed to spawn: $err"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'START FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "START FAILED"
    }

    return "START SUCCEEDED"
}


proc mysql_run_sql {cidict refname key} {
    global rdbms
    set install [dict get $cidict $rdbms install]

    set KEY    [string toupper $key]
    set FAILED "${KEY} FAILED"
    set OK     "${KEY} SUCCEEDED"

    if {![dict exists $install $key]} {
        putsci "RUN_SQL $key: missing <$key> in XML"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status=$FAILED WHERE ci_id=$ci_id}
            }
        }
        return $FAILED
    }

    # basedir
    set ci_id     [mysql_ci_id $cidict $refname]
    set safe_ref  [mysql_ci_safe_ref $refname]
    set install_root [mysql_normpath [dict get $install install_dir]]
    set parent    [file join $install_root "ci_${ci_id}_${safe_ref}"]
    set dirs      [glob -nocomplain -types d -directory $parent mysql-*]
    if {[llength $dirs] == 0} {
        putsci "RUN_SQL $key: no mysql-* under $parent"
        catch {
            set ci_id2 [ci_latest_id $refname]
            if {$ci_id2 ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status=$FAILED WHERE ci_id=$ci_id2}
            }
        }
        return $FAILED
    }

    set basedir ""; set newest -1
    foreach d $dirs {
        set m [file mtime $d]
        if {$m > $newest} { set newest $m; set basedir $d }
    }

    # socket path
    set socket "/tmp/mysql.sock"
    if {[dict exists $install socket]} {
        set socket [mysql_normpath [dict get $install socket]]
    }

    # client command — try passwordless first, fall back to -pmysql after change_password
    set sql     [dict get $install $key]
    set cli     "./bin/mysql -S $socket --ssl-mode=DISABLED -u root"
    set sql_cmd "$cli -vvv -e \\\"$sql\\\" || $cli -pmysql -vvv -e \\\"$sql\\\""

    putsci "RUN_SQL $key:"
    putsci $sql_cmd

    set ::pipe_done 0
    set close_status OK

    if {[catch {
        set pipe [open "|bash -c \"cd $basedir && $sql_cmd\"" "r"]
        fconfigure $pipe -blocking 0 -buffering line
        fileevent $pipe readable [list handle_output $pipe]
        after 15000 { if {$::pipe_done == 0} { set ::pipe_done 1 } }
        vwait ::pipe_done
        if {[catch {close $pipe} errMsg]} { set close_status $errMsg }
    } errMsg]} {
        putsci "RUN_SQL $key failed to spawn: $errMsg"
        catch {
            set ci_id2 [ci_latest_id $refname]
            if {$ci_id2 ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status=$FAILED WHERE ci_id=$ci_id2}
            }
        }
        return $FAILED
    }

    if {$close_status ne "OK"} {
        putsci "RUN_SQL $key error: $close_status"
        catch {
            set ci_id2 [ci_latest_id $refname]
            if {$ci_id2 ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status=$FAILED WHERE ci_id=$ci_id2}
            }
        }
        return $FAILED
    }

    return $OK
}

# capture output
proc _mysql_ping_capture {pipe} {
    global ::pipe_done ::_mysql_ping_output
    if {[eof $pipe]} {
        set ::pipe_done 1
        return
    }
    if {[gets $pipe line] >= 0} {
        putsci $line
        append ::_mysql_ping_output $line "\n"
    }
}

proc mysql_ping {cidict refname} {
    global rdbms
    set install [dict get $cidict $rdbms install]

    # basedir
    set ci_id [mysql_ci_id $cidict $refname]
    set safe_ref [mysql_ci_safe_ref $refname]
    set install_root [mysql_normpath [dict get $install install_dir]]
    set parent [file join $install_root "ci_${ci_id}_${safe_ref}"]
    set dirs   [glob -nocomplain -types d -directory $parent mysql-*]
    if {[llength $dirs] == 0} {
        putsci "PING: no mysql-* under $parent"
        return "PING FAILED"
    }
    set basedir ""; set newest -1
    foreach d $dirs {
        set m [file mtime $d]
        if {$m > $newest} { set newest $m; set basedir $d }
    }

    # socket path
    set socket "/tmp/mysql.sock"
    if {[dict exists $cidict $rdbms install socket]} {
        set socket [mysql_normpath [dict get $cidict $rdbms install socket]]
    }

    # command
    set sql "SELECT @@version"
    if {[dict exists $cidict $rdbms ping]} {
        set sql [string trim [dict get $cidict $rdbms ping]]
    }
    set cli "./bin/mysql -S $socket --ssl-mode=DISABLED -u root"
    set sql_cmd "$cli -vvv -e \\\"$sql\\\" || $cli -pmysql -vvv -e \\\"$sql\\\""

    putsci "PING:"
    putsci $sql_cmd

    set attempts 30
    set wait_ms 2000

    for {set attempt 1} {$attempt <= $attempts} {incr attempt} {
        set ::_mysql_ping_output ""
        set ::pipe_done 0
        set close_status OK

        if {[catch {
            set pipe [open "|bash -c \"cd $basedir && $sql_cmd\"" "r"]
            fconfigure $pipe -blocking 0 -buffering line
            fileevent $pipe readable [list _mysql_ping_capture $pipe]
            after 3000 { if {$::pipe_done == 0} { set ::pipe_done 1 } }
            vwait ::pipe_done
            if {[catch {close $pipe} errMsg]} { set close_status $errMsg }
        } errMsg]} {
            set close_status $errMsg
        }

        if {$close_status eq "OK" && [string trim $::_mysql_ping_output] ne ""} {
            return "PING SUCCEEDED"
        }

        if {$attempt < $attempts} {
            after $wait_ms
        }
    }

    putsci "PING FAILED: no version returned"
    putsci $::_mysql_ping_output
    return "PING FAILED"
}

# run test
proc mysql_start_tests {cidict refname workload} {
    global rdbms
    set ci_id [ci_latest_id $refname]
    # set io intensive
    set ::env(UAW) [mysql_get_io_intensive $ci_id]

    hdbjobs eval {UPDATE JOBCI SET status = 'RUNNING' WHERE ci_id = $ci_id}
    putsci "MySQL is up and running for $refname"

    # script path
    set key [string tolower $workload]
    if {$key ni {"oltp" "olap"}} {
        putsci "Test failed: workload must be 'oltp' or 'olap' (got '$workload')"
        if {$ci_id ne ""} {
            hdbjobs eval {UPDATE JOBCI SET status = 'TEST FAILED' WHERE ci_id = $ci_id}
        }
        return "TEST FAILED"
    }
    if {![dict exists $cidict $rdbms test $key]} {
        putsci "Test failed: <$key> missing under <$rdbms>/<test> in XML"
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval {UPDATE JOBCI SET status = 'TEST FAILED' WHERE ci_id = $ci_id}
        }
        return "TEST FAILED"
    }
    set script_raw [string map {\" {}} [dict get $cidict $rdbms test $key]]
    if {[file pathtype $script_raw] eq "relative"} {
        set script_abs [file join [pwd] $script_raw]
    } else {
        set script_abs $script_raw
    }
    if {![file exists $script_abs]} {
        putsci "Test failed: script not found: $script_abs"
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval {UPDATE JOBCI SET status = 'TEST FAILED' WHERE ci_id = $ci_id}
        }
        return "TEST FAILED"
    }
    catch {exec chmod +x -- $script_abs}

    putsci "Running Tests ($key)"
    # root needs sudo
    set sudo ""
    if {[info exists cidict] && [dict exists $cidict common use_sudo]} {
        if {[string is true [dict get $cidict common use_sudo]]} {
            set sudo "sudo -n "
        }
    }
    putsci "${sudo}bash -c \"$script_abs\""
    set doneVar "::pipe_done_tests_[clock milliseconds]"
    set $doneVar 0
    if {[catch {
        set pipe [open "|${sudo}bash -c \"$script_abs 2>&1\"" "r"]
        fconfigure $pipe -translation binary -buffering none -blocking 0
        fileevent $pipe readable [list handle_test_output $pipe $doneVar]
        vwait $doneVar
        close $pipe
    } err]} {
        putsci "Test failed: $err"
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval {UPDATE JOBCI SET status = 'TEST FAILED' WHERE ci_id = $ci_id}
        }
        return "TEST FAILED"
    }
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval {UPDATE JOBCI SET status='COMPLETE', end_timestamp=datetime(CURRENT_TIMESTAMP,'localtime') WHERE ci_id = $ci_id}
        }
putsci "refname is $refname"
    putsci "Test sequence complete ($key)"
    return "TEST COMPLETE"
}

proc mysql_profile {cidict refname} {
    global rdbms
    if {(![info exists ::env(TMP)] || $::env(TMP) eq "") &&
        [info exists ::env(TMPDIR)] && $::env(TMPDIR) ne ""} {
        set ::env(TMP) $::env(TMPDIR)
    }
    ci_check_tmp

    # build root/tag
    if {![dict exists $cidict $rdbms build build_dir]} {
        putsci "PROFILE FAILED: <$rdbms>/<build>/<build_dir> missing"
        return "PROFILE FAILED"
    }
    set build_root [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set bad_tag [expr {[string match "refs/tags/*" $refname] ? [file tail $refname] : $refname}]

    # ensure JOBCI row
    set dbprefix [find_prefix $rdbms]
    set ci_id [ci_latest_id $bad_tag]
    if {$ci_id eq ""} {
        hdbjobs eval {INSERT INTO JOBCI (refname,dbprefix,cidict) VALUES ($bad_tag,$dbprefix,$cidict)}
        set ci_id [ci_latest_id $bad_tag]
    }
    if {$ci_id ne ""} {
        hdbjobs eval {UPDATE JOBCI SET status = 'BUILDING' WHERE ci_id = $ci_id}
    } else {
        putsci "PROFILE FAILED: could not create/find JOBCI row for $bad_tag"
        return "PROFILE FAILED"
    }
    # I/O intensive set UAW
    set io_intensive [mysql_get_io_intensive $ci_id]
    set uaw [expr {$io_intensive == 1 ? 1 : 0}]

    set repo [file join $build_root "ci_${ci_id}_${bad_tag}"]
    set is_commit 0
    if {![string match "refs/tags/*" $refname] && ![string match "refs/heads/*" $refname]} {
        if {[regexp {^[0-9a-fA-F]{7,40}$} $bad_tag]} {
            set is_commit 1
        }
    }
    if {[file isdirectory $repo]} {
        putsci "PROFILE FAILED: repo already exists: $repo"
        return "PROFILE FAILED"
    }

    # runner script
    if {![dict exists $cidict $rdbms test profile]} {
        putsci "PROFILE FAILED: <$rdbms>/<test>/<profile> missing in XML"
        return "PROFILE FAILED"
    }
    set runner_raw [string map {\" {}} [dict get $cidict $rdbms test profile]]
    set ham_root [pwd]  ;# runner expects ./hammerdbcli in cwd
    if {[file pathtype $runner_raw] eq "relative"} {
        set runner_abs [file join $ham_root $runner_raw]
    } else {
        set runner_abs $runner_raw
    }
    if {![file exists $runner_abs]} {
        putsci "PROFILE FAILED: runner not found: $runner_abs"
        return "PROFILE FAILED"
    }
    catch {exec chmod +x -- $runner_abs}
    # detect Single
    set pipeline_mode ""
    catch {
        set pipeline_mode [string trim [hdbjobs eval \
            "SELECT pipeline FROM JOBCI WHERE ci_id=$ci_id LIMIT 1"]]
    }
    set pipeline_mode [string tolower $pipeline_mode]

    if {$pipeline_mode in {"single" "single_c" "single_h"}} {
        # reset profile id
        set bad_pid 0
        set ::jobs_profile_id 0
        catch { hdbjobs eval \
            "UPDATE JOBCI SET profile_id=0 WHERE ci_id=$ci_id" }
        putsci "PROFILEIDS 0"
    } else {
    # base profile id
    set pid_base 1000
    if {[dict exists $cidict $rdbms pipeline profileid]} {
        set pid_base [dict get $cidict $rdbms pipeline profileid]
    }
    if {$pid_base < 1000} { set pid_base 1000 }

    set bad_pid $pid_base

    # bump profile id
    set maxpid ""
    catch { set maxpid [ hdbjobs eval {SELECT COALESCE(MAX(profile_id),0) FROM JOBMAIN} ] }
    set maxpid [string trim $maxpid]

    if {[string is integer -strict $maxpid] && $maxpid >= 1000} {
        set bad_pid [expr {$maxpid + 1}]
    } else {
        set bad_pid $pid_base
    }

    set ci_id [ci_latest_id $bad_tag]
    if {$ci_id ne ""} {
	hdbjobs eval {UPDATE JOBCI SET profile_id = $bad_pid WHERE ci_id = $ci_id}
    }

    putsci "PROFILEIDS $bad_pid"
    }

    # run runner once
    proc _profile_run_once {ham_root runner_abs tag pid uaw} {
        set run "cd $ham_root && env REFNAME=$tag PROFILEID=$pid UAW=$uaw $runner_abs"
        putsci "RUNNING BENCHMARK: $run"
        set ci_id [ci_latest_id $tag]
        if {$ci_id ne ""} {
            hdbjobs eval {UPDATE JOBCI SET status = 'RUNNING' WHERE ci_id = $ci_id}
        }

        set doneVar "::profile_run_done_[clock milliseconds]"
        set $doneVar 0
        if {[catch {
            set pipe [open "|bash -c \"$run\"" "r"]
            fconfigure $pipe -translation binary -buffering none -blocking 0
            fileevent  $pipe readable [list handle_test_output $pipe $doneVar]
            vwait $doneVar
            close $pipe
        } rerr]} {
            putsci "PROFILE FAILED: $rerr"
            return 0
        }
        set ci_id [ci_latest_id $tag]
        if {$ci_id ne ""} {
            hdbjobs eval {UPDATE JOBCI SET status='COMPLETE', end_timestamp=datetime(CURRENT_TIMESTAMP,'localtime') WHERE ci_id = $ci_id}
        }
        putsci "TEST COMPLETE"
        return 1
    }

    set co_bad "cd $repo && git checkout -f $bad_tag"
    putsci $co_bad
    set ::pipe_done 0
    if {[catch {
        set p [open "|bash -c \"$co_bad\"" "r"]
        fconfigure $p -blocking 0 -buffering line
        fileevent  $p readable [list handle_output $p]
        vwait ::pipe_done
        close $p
    } err]} {
        putsci "CHECKOUT FAILED: $err"
        return "PROFILE FAILED"
    }

    catch { hdbjobs eval { UPDATE JOBCI SET status='CLONING' WHERE ci_id=$ci_id } }
    set cst [mysql_clone $cidict $bad_tag]
    if {$cst eq "CLONE FAILED"}   { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='COMMIT MSG' WHERE ci_id=$ci_id } }
    set cmst [mysql_commit_msg $cidict $bad_tag]
    if {$cmst eq "COMMIT_MSG FAILED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='BUILDING' WHERE ci_id=$ci_id } }
    set bst [mysql_build $cidict $bad_tag]
    if {$bst eq "BUILD FAILED"}   { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='PACKAGING' WHERE ci_id=$ci_id } }
    set pst [mysql_package $cidict $bad_tag]
    if {$pst eq "PACKAGE FAILED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='INSTALLING' WHERE ci_id=$ci_id } }
    set ist [mysql_install $cidict $bad_tag]
    if {$ist eq "INSTALL FAILED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='INIT' WHERE ci_id=$ci_id } }
    set int [mysql_init $cidict $bad_tag]
    if {$int eq "INIT FAILED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='STOPPING' WHERE ci_id=$ci_id } }
    set stop_st [mysql_run_sql $cidict $bad_tag shutdown]
    if {$stop_st ne "SHUTDOWN SUCCEEDED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='STARTING' WHERE ci_id=$ci_id } }
    set sst [mysql_start $cidict $bad_tag]
    if {$sst eq "START FAILED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='PING' WHERE ci_id=$ci_id } }
    set pst [mysql_ping $cidict $bad_tag]
    if {$pst eq "PING FAILED"} { return "PROFILE FAILED" } 
    catch { hdbjobs eval { UPDATE JOBCI SET status='RUNNING' WHERE ci_id=$ci_id } }
    set rsy [mysql_run_sql $cidict $bad_tag change_password]
    if {$rsy eq "CHANGE_PASSWORD FAILED"} { return "PROFILE FAILED" }
    if {![_profile_run_once $ham_root $runner_abs $bad_tag $bad_pid $uaw]} {
        return "PROFILE FAILED"
    }

    set stop_st [mysql_run_sql $cidict $bad_tag shutdown]
    putsci $stop_st
    if {$stop_st ne "SHUTDOWN SUCCEEDED"} {
        putsci "COMPARE FAILED: shutdown failed after profile"
        return "COMPARE FAILED"
    }
}

proc mysql_compare {cidict refname} {
    global rdbms
    if {(![info exists ::env(TMP)] || $::env(TMP) eq "") &&
        [info exists ::env(TMPDIR)] && $::env(TMPDIR) ne ""} {
        set ::env(TMP) $::env(TMPDIR)
    }
    ci_check_tmp

    set dbprefix [find_prefix $rdbms]

    # build root/tag
    if {![dict exists $cidict $rdbms build build_dir]} {
        putsci "COMPARE FAILED: <$rdbms>/<build>/<build_dir> missing"
        return "COMPARE FAILED"
    }
    set build_root [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set bad_tag [expr {[string match "refs/tags/*" $refname] ? [file tail $refname] : $refname}]

    # ensure JOBCI row
    set ci_id [ci_latest_id $bad_tag]
    if {$ci_id eq ""} {
        hdbjobs eval {INSERT INTO JOBCI (refname,dbprefix,cidict) VALUES ($bad_tag,$dbprefix,$cidict)}
        set ci_id [hdbjobs eval {SELECT last_insert_rowid()}]
    }
    if {$ci_id ne ""} {
        hdbjobs eval {UPDATE JOBCI SET status = 'BUILDING' WHERE ci_id = $ci_id}
        hdbjobs eval {UPDATE JOBCI SET pipeline = 'COMPARE' WHERE ci_id = $ci_id}
    } else {
        putsci "COMPARE FAILED: could not create/find JOBCI row for $bad_tag"
        return "COMPARE FAILED"
    }

    # I/O intensive set UAW
    set io_intensive [mysql_get_io_intensive $ci_id]
    set uaw [expr {$io_intensive == 1 ? 1 : 0}]

    set repo [file join $build_root "ci_${ci_id}_${bad_tag}"]
    set is_commit 0
    if {![string match "refs/tags/*" $refname] && ![string match "refs/heads/*" $refname]} {
        if {[regexp {^[0-9a-fA-F]{7,40}$} $bad_tag]} {
            set is_commit 1
        }
    }
    if {[file isdirectory $repo]} {
        putsci "COMPARE FAILED: repo already exists: $repo"
        return "COMPARE FAILED"
    }

    # runner script
    if {![dict exists $cidict $rdbms test compare]} {
        putsci "COMPARE FAILED: <$rdbms>/<test>/<compare> missing in XML"
        return "COMPARE FAILED"
    }
    set runner_raw [string map {\" {}} [dict get $cidict $rdbms test compare]]
    set ham_root [pwd]
    if {[file pathtype $runner_raw] eq "relative"} {
        set runner_abs [file join $ham_root $runner_raw]
    } else {
        set runner_abs $runner_raw
    }
    if {![file exists $runner_abs]} {
        putsci "COMPARE FAILED: runner not found: $runner_abs"
        return "COMPARE FAILED"
    }
    catch {exec chmod +x -- $runner_abs}

    # base profile id
    set pid_base 1000
    if {[dict exists $cidict $rdbms pipeline compare_profileid]} {
        set pid_base [dict get $cidict $rdbms pipeline compare_profileid]
    }
    set bad_pid  $pid_base
    set good_pid [expr {$pid_base + 1}]

    # bump profile id
    set maxpid ""
    if {![catch { set maxpid [hdbjobs eval {SELECT COALESCE(MAX(profile_id),0) FROM JOBMAIN}] }]} {
        set maxpid [string trim $maxpid]
        if {[string is integer -strict $maxpid] && $maxpid >= 1000} {
            set bad_pid  [expr {$maxpid + 1}]
            set good_pid [expr {$maxpid + 2}]
        }
    }

    set ci_id [ci_latest_id $bad_tag]
    if {$ci_id ne ""} {
        hdbjobs eval {UPDATE JOBCI SET profile_id = $bad_pid WHERE ci_id = $ci_id}
    }
    putsci "COMPARE PROFILEIDS $bad_pid $good_pid"

    # update selected/current tree
    set cmd "cd $repo && git fetch --all --tags"
    putsci $cmd
    set ::pipe_done 0
    if {[catch {
        set p [open "|bash -c \"$cmd\"" "r"]
        fconfigure $p -blocking 0 -buffering line
        fileevent  $p readable [list handle_output $p]
        vwait ::pipe_done
        close $p
    } err]} {
        putsci "COMPARE FAILED: $err"
        return "COMPARE FAILED"
    }

    # run runner once
    proc _compare_run_once {ham_root runner_abs tag pid ci_id uaw} {
        set run "cd $ham_root && env REFNAME=$tag PROFILEID=$pid UAW=$uaw $runner_abs"
        putsci "RUNNING BENCHMARK: $run"
        if {$ci_id ne ""} {
            hdbjobs eval {UPDATE JOBCI SET status = 'RUNNING' WHERE ci_id = $ci_id}
        }

        set doneVar "::compare_run_done_[clock milliseconds]"
        set $doneVar 0
        if {[catch {
            set pipe [open "|bash -c \"$run\"" "r"]
            fconfigure $pipe -translation binary -buffering none -blocking 0
            fileevent  $pipe readable [list handle_test_output $pipe $doneVar]
            vwait $doneVar
            close $pipe
        } rerr]} {
            putsci "COMPARE FAILED: $rerr"
            return 0
        }
        set ci_id [ci_latest_id $tag]
        if {$ci_id ne ""} {
            hdbjobs eval {UPDATE JOBCI SET status='COMPLETE', end_timestamp=datetime(CURRENT_TIMESTAMP,'localtime') WHERE ci_id = $ci_id}
        }
        putsci "TEST COMPLETE"
        return 1
    }

    # ensure selected/current tree is on bad_tag
    set co_bad "cd $repo && git checkout -f $bad_tag"
    putsci $co_bad
    set ::pipe_done 0
    if {[catch {
        set p [open "|bash -c \"$co_bad\"" "r"]
        fconfigure $p -blocking 0 -buffering line
        fileevent  $p readable [list handle_output $p]
        vwait ::pipe_done
        close $p
    } err]} {
        putsci "CHECKOUT FAILED: $err"
        return "COMPARE FAILED"
    }

    # 1) Run profile on selected/current tag
    catch { hdbjobs eval { UPDATE JOBCI SET status='CLONING' WHERE ci_id=$ci_id } }
    set cst [mysql_clone $cidict $bad_tag]
    if {$cst eq "CLONE FAILED"}   { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='COMMIT MSG' WHERE ci_id=$ci_id } }
    set cmst [mysql_commit_msg $cidict $bad_tag]
    if {$cmst eq "COMMIT_MSG FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='BUILDING' WHERE ci_id=$ci_id } }
    set bst [mysql_build $cidict $bad_tag]
    if {$bst eq "BUILD FAILED"}   { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='PACKAGING' WHERE ci_id=$ci_id } }
    set pst [mysql_package $cidict $bad_tag]
    if {$pst eq "PACKAGE FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='INSTALLING' WHERE ci_id=$ci_id } }
    set ist [mysql_install $cidict $bad_tag]
    if {$ist eq "INSTALL FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='INIT' WHERE ci_id=$ci_id } }
    set int [mysql_init $cidict $bad_tag]
    if {$int eq "INIT FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='STOPPING' WHERE ci_id=$ci_id } }
    set stop_st [mysql_run_sql $cidict $bad_tag shutdown]
    if {$stop_st ne "SHUTDOWN SUCCEEDED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='STARTING' WHERE ci_id=$ci_id } }
    set sst [mysql_start $cidict $bad_tag]
    if {$sst eq "START FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='PING' WHERE ci_id=$ci_id } }
    set pst [mysql_ping $cidict $bad_tag]
    if {$pst eq "PING FAILED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='RUNNING' WHERE ci_id=$ci_id } }
    set rsy [mysql_run_sql $cidict $bad_tag change_password]
    if {$rsy eq "CHANGE_PASSWORD FAILED"} { return "COMPARE FAILED" }
    if {![_compare_run_once $ham_root $runner_abs $bad_tag $bad_pid $ci_id $uaw]} {
        return "COMPARE FAILED"
    }

    set stop_st [mysql_run_sql $cidict $bad_tag shutdown]
    if {$stop_st ne "SHUTDOWN SUCCEEDED"} {
        putsci "COMPARE FAILED: shutdown failed before switching binaries"
        return "COMPARE FAILED"
    }

    # detect commit/tag baseline
    set is_commit 0
    if {[regexp {^[0-9a-f]{7,40}$} $bad_tag]} {
        set is_commit 1
    }

    catch {cd $ham_root}

    if {$is_commit} {
        # baseline = parent commit
        set desc_cmd "cd $repo && git rev-list --max-count=1 $bad_tag^"
        putsci "COMPARE PRECHECK: $desc_cmd"

        if {[catch { set good_tag [exec bash -c "$desc_cmd"] } derr]} {
            putsci "COMPARE FAILED: could not find previous commit of $bad_tag: $derr"
            return "COMPARE FAILED"
        }

        set good_tag [string trim $good_tag]
    } else {
        # baseline = previous tag
        if {[catch { set alltags [exec git -C $repo tag -l "mysql-*" --sort=v:refname] } derr]} {
            putsci "COMPARE FAILED: could not list tags in $repo: $derr"
            return "COMPARE FAILED"
        }

        set taglist {}
        foreach t [split $alltags "\n"] {
            set t [string trim $t]
            if {$t ne ""} { lappend taglist $t }
        }

        set idx [lsearch -exact $taglist $bad_tag]
        if {$idx < 0} {
            putsci "COMPARE FAILED: bad_tag '$bad_tag' not found in tag list"
            return "COMPARE FAILED"
        }
        if {$idx == 0} {
            putsci "COMPARE FAILED: no previous tag exists before '$bad_tag'"
            return "COMPARE FAILED"
        }

        set good_tag [lindex $taglist [expr {$idx - 1}]]
    }

    set good_tag [string trim $good_tag]
    putsci "COMPARE PRECHECK -> bad=$bad_tag good=$good_tag"

    if {$good_tag eq ""} {
        putsci "COMPARE FAILED: could not determine baseline for '$bad_tag'"
        return "COMPARE FAILED"
    }

    hdbjobs eval {INSERT INTO JOBCI (refname,dbprefix,cidict,io_intensive) VALUES ($good_tag,$dbprefix,$cidict,$io_intensive)}
    set ci_id [hdbjobs eval {SELECT last_insert_rowid()}]
    if {$ci_id ne ""} {
        hdbjobs eval {UPDATE JOBCI SET status = 'BUILDING' WHERE ci_id = $ci_id}
        hdbjobs eval {UPDATE JOBCI SET profile_id = $good_pid WHERE ci_id = $ci_id}
        hdbjobs eval {UPDATE JOBCI SET pipeline = 'COMPARE' WHERE ci_id = $ci_id}
    }

    # baseline lives in separate worktree; leave original selected tree on bad_tag
    set abs_repo [file normalize $repo]
    set good_dir [file normalize [file join $build_root "ci_${ci_id}_${good_tag}"]]
    if {![file isdirectory $good_dir]} {
        putsci "Creating worktree for $good_tag"

        catch { hdbjobs eval { UPDATE JOBCI SET status='CLONING' WHERE ci_id=$ci_id } }
        set cmd "git -C \"$abs_repo\" worktree add -f --detach \"$good_dir\" \"$good_tag\" 2>&1"
        putsci "Running clone command..."
        putsci $cmd
        catch { hdbjobs eval { UPDATE JOBCI SET clone_cmd = $cmd WHERE ci_id = $ci_id } }

        set safe_cmd [string map {\" \\\"} $cmd]
        set pipe_output ""
        set clone_status "CLONE SUCCEEDED"

        if {[catch {
            set pipe [open "|bash -c \"$safe_cmd\"" "r"]
            fconfigure $pipe -blocking 1 -buffering line
            while {[gets $pipe line] >= 0} {
                append pipe_output "$line\n"
                putsci $line
                if {[regexp -nocase {fatal:|error:} $line]} {
                    set clone_status "CLONE FAILED"
                }
            }
            if {[catch {close $pipe} close_err]} {
                putsci "Warning: close pipe reported: $close_err"
            }
        } wt_err]} {
            set clone_status "CLONE FAILED"
            append pipe_output "Failed to start worktree add: $wt_err\n"
        }

        if {$clone_status eq "CLONE FAILED"} {
            putsci "Clone failed."
            putsci "Full clone output:"
            putsci $pipe_output
            catch {
                hdbjobs eval { UPDATE JOBCI SET status='CLONE FAILED', clone_output=$pipe_output WHERE ci_id = $ci_id }
            }
            return "COMPARE FAILED"
        } else {
            putsci "Clone succeeded."
            catch {
                hdbjobs eval { UPDATE JOBCI SET clone_output = $pipe_output WHERE ci_id = $ci_id }
            }
        }

        set cmd "git -C \"$good_dir\" reset --hard \"$good_tag\" 2>&1"
        putsci $cmd
        catch { hdbjobs eval { UPDATE JOBCI SET clone_cmd = $cmd WHERE ci_id = $ci_id } }
        set safe_cmd [string map {\" \\\"} $cmd]
        set pipe_output ""
        set clone_status "CLONE SUCCEEDED"
        if {[catch {
            set pipe [open "|bash -c \"$safe_cmd\"" "r"]
            fconfigure $pipe -blocking 1 -buffering line
            while {[gets $pipe line] >= 0} {
                append pipe_output "$line\n"
                putsci $line
                if {[regexp -nocase {fatal:|error:} $line]} {
                    set clone_status "CLONE FAILED"
                }
            }
            if {[catch {close $pipe} close_err]} {
                putsci "Warning: close pipe reported: $close_err"
            }
        } rst_err]} {
            set clone_status "CLONE FAILED"
            append pipe_output "Failed to start reset: $rst_err\n"
        }
        if {$clone_status eq "CLONE FAILED"} {
            catch { hdbjobs eval { UPDATE JOBCI SET status='CLONE FAILED', clone_output=$pipe_output WHERE ci_id=$ci_id } }
            return "COMPARE FAILED"
        } else {
            catch { hdbjobs eval { UPDATE JOBCI SET clone_output=$pipe_output WHERE ci_id=$ci_id } }
        }

        set cmd "git -C \"$good_dir\" submodule update --init --recursive 2>&1"
        putsci $cmd
        catch { hdbjobs eval { UPDATE JOBCI SET clone_cmd = $cmd WHERE ci_id = $ci_id } }
        set safe_cmd [string map {\" \\\"} $cmd]
        set pipe_output ""
        set clone_status "CLONE SUCCEEDED"
        if {[catch {
            set pipe [open "|bash -c \"$safe_cmd\"" "r"]
            fconfigure $pipe -blocking 1 -buffering line
            while {[gets $pipe line] >= 0} {
                append pipe_output "$line\n"
                putsci $line
                if {[regexp -nocase {fatal:|error:} $line]} {
                    set clone_status "CLONE FAILED"
                }
            }
            if {[catch {close $pipe} close_err]} {
                putsci "Warning: close pipe reported: $close_err"
            }
        } sub_err]} {
            set clone_status "CLONE FAILED"
            append pipe_output "Failed to start submodule update: $sub_err\n"
        }
        if {$clone_status eq "CLONE FAILED"} {
            catch { hdbjobs eval { UPDATE JOBCI SET status='CLONE FAILED', clone_output=$pipe_output WHERE ci_id=$ci_id } }
            return "COMPARE FAILED"
        } else {
            catch { hdbjobs eval { UPDATE JOBCI SET clone_output=$pipe_output WHERE ci_id=$ci_id } }
        }
    } else {
        putsci "Using existing worktree for $good_tag"
        catch { hdbjobs eval { UPDATE JOBCI SET clone_output='Using existing worktree' WHERE ci_id=$ci_id } }
    }

    catch { hdbjobs eval { UPDATE JOBCI SET status='COMMIT MSG' WHERE ci_id=$ci_id } }
    set cmst [mysql_commit_msg $cidict $good_tag]
    if {$cmst eq "COMMIT_MSG FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='BUILDING' WHERE ci_id=$ci_id } }
    set bst [mysql_build $cidict $good_tag]
    if {$bst eq "BUILD FAILED"}   { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='PACKAGING' WHERE ci_id=$ci_id } }
    set pst [mysql_package $cidict $good_tag]
    if {$pst eq "PACKAGE FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='INSTALLING' WHERE ci_id=$ci_id } }
    set ist [mysql_install $cidict $good_tag]
    if {$ist eq "INSTALL FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='INIT' WHERE ci_id=$ci_id } }
    set int [mysql_init $cidict $good_tag]
    if {$int eq "INIT FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='STOPPING' WHERE ci_id=$ci_id } }
    set stop_st [mysql_run_sql $cidict $good_tag shutdown]
    if {$stop_st ne "SHUTDOWN SUCCEEDED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='STARTING' WHERE ci_id=$ci_id } }
    set sst [mysql_start $cidict $good_tag]
    if {$sst eq "START FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='PING' WHERE ci_id=$ci_id } }
    set pst [mysql_ping $cidict $good_tag]
    if {$pst eq "PING FAILED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='RUNNING' WHERE ci_id=$ci_id } }
    set rsy [mysql_run_sql $cidict $good_tag change_password]
    if {$rsy eq "CHANGE_PASSWORD FAILED"} { return "COMPARE FAILED" }

    if {![_compare_run_once $ham_root $runner_abs $good_tag $good_pid $ci_id $uaw]} {
        return "COMPARE FAILED"
    }

    set stop_st [mysql_run_sql $cidict $good_tag shutdown]
    putsci $stop_st
    if {$stop_st ne "SHUTDOWN SUCCEEDED"} {
        putsci "COMPARE FAILED: shutdown failed after diff"
        return "COMPARE FAILED"
    }

    putsci "COMPARE PROFILEIDS  $bad_pid $good_pid"
    if {[catch { set du [job diff $good_pid $bad_pid false] } dErr]} {
        putsci $dErr
        putsci "COMPARE DONE"
        return "COMPARE DONE"
    }
    putsci "Compare summary:"
    putsci "  unweighted = $du"
    putsci "COMPARE DONE"
    return "COMPARE DONE"
}
