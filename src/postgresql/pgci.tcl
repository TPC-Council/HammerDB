#
# pgci.tcl — HammerDB CI/Pipeline procs for PostgreSQL (issue #871).
# Port of src/mariadb/mariaci.tcl. All procs are registered with the
# <rdbms>_<step> naming convention so genci.tcl's cisteps dispatcher can
# invoke them ("postgresql_<step>" because dbset db pg sets rdbms=PostgreSQL).
#
# Differences from MariaDB port:
#   * No tarball/package step — build + install is `./configure --prefix=<basedir>
#     && make && make install`. <package_cmd> runs but is a no-op (e.g. `true`).
#   * basedir is fixed ($install_root/ci_<id>_<ref>/pg) — no glob walk.
#   * All client calls use TCP (localhost:<port>) to stay consistent with the
#     stock pg_tprocc_*.tcl scripts (pg_host=localhost, pg_port=5432).
#   * key=shutdown in postgresql_run_sql dispatches to `pg_ctl stop -m fast`
#     (PostgreSQL has no SQL shutdown statement).
#   * postgresql_init/start use PG flags: --pgdata / --username / --auth etc.,
#     and pass -c shared_buffers / -c max_wal_size via pg_ctl's -o passthrough.
#   * profile/compare pipelines drop the pre-start run_sql:shutdown (initdb
#     never leaves a server running for PG).
#

proc postgresql_ci_id {cidict refname} {
    global rdbms
    set dbprefix [find_prefix $rdbms]
    set ci_id [ci_latest_id $refname]
    if {$ci_id eq ""} {
        hdbjobs eval {INSERT INTO JOBCI (refname,dbprefix,cidict) VALUES ($refname,$dbprefix,$cidict)}
        set ci_id [ci_latest_id $refname]
    }
    return $ci_id
}

proc postgresql_ci_safe_ref {refname} {
    return [string map {/ _} $refname]
}

proc postgresql_get_io_intensive {ci_id} {
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

proc postgresql_set_uaw_env {cidict refname} {
    set ci_id [postgresql_ci_id $cidict $refname]
    set io_intensive [postgresql_get_io_intensive $ci_id]
    if {$io_intensive == 1} {
        set ::env(UAW) 1
        putsci "HammerDB UAW enabled for $refname"
    } else {
        set ::env(UAW) 0
        putsci "HammerDB UAW disabled for $refname"
    }
}

proc postgresql_normpath {p} {
    if {$p eq ""} {
        return ""
    }
    return [file join {*}[file split $p]]
}

# Return the final PG base directory (= configure --prefix target) for (ci_id, ref).
proc postgresql_basedir {cidict refname} {
    global rdbms
    set install_root [postgresql_normpath [dict get $cidict $rdbms install install_dir]]
    set ci_id   [postgresql_ci_id $cidict $refname]
    set safe_ref [postgresql_ci_safe_ref $refname]
    return [file join $install_root "ci_${ci_id}_${safe_ref}" "pg"]
}

# ---------------------------------------------------------------------------
# clone
# ---------------------------------------------------------------------------
proc postgresql_clone {cidict refname} {
    global rdbms
    set build_dir [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set repo_url  [string map {\" {}} [dict get $cidict $rdbms build repo_url]]
    set ci_id     [postgresql_ci_id $cidict $refname]
    set safe_ref  [postgresql_ci_safe_ref $refname]
    set local_dir "$build_dir/ci_${ci_id}_${safe_ref}"
    file mkdir $local_dir

    set ref_trim [string trim $refname]
    set is_commit 0
    if {[regexp {^[0-9a-fA-F]{7,40}$} $ref_trim]} { set is_commit 1 }

    if {$is_commit} {
        putsci "Cloning repository for commit $ref_trim into $local_dir"
    } else {
        putsci "Cloning branch [file tail $ref_trim] into $local_dir"
    }
    putsci "repo_url is $repo_url"

    if {$is_commit} {
        set shell_cmd "cd \"$local_dir\" && git clone \"$repo_url\" . && git checkout $ref_trim 2>&1"
    } else {
        set raw_cmd  [dict get $cidict common clone_cmd]
        set raw_args [dict get $cidict common clone_cmd_args]
        set branch   [file tail $ref_trim]
        set args_sub [string map [list ":branch" $branch ":repo_url" $repo_url] $raw_args]
        set shell_cmd "cd \"$local_dir\" && $raw_cmd $args_sub 2>&1"
    }

    catch {
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval { UPDATE JOBCI SET clone_cmd = $shell_cmd WHERE ci_id = $ci_id }
        }
    }

    putsci "Running clone command..."
    putsci $shell_cmd

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

# ---------------------------------------------------------------------------
# build — ./configure --prefix=<basedir> ... && make
# ---------------------------------------------------------------------------
proc postgresql_build {cidict refname} {
    global rdbms
    set build_dir [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set ci_id     [postgresql_ci_id $cidict $refname]
    set safe_ref  [postgresql_ci_safe_ref $refname]
    set local_dir "$build_dir/ci_${ci_id}_${safe_ref}"

    # Compute PG prefix (= final basedir) and make sure parent exists.
    set prefix [postgresql_basedir $cidict $refname]
    file mkdir [file dirname $prefix]

    set raw_cmd [dict get $cidict $rdbms build build_cmd]

    # Inject --prefix=<basedir> into the configure invocation. If the XML
    # command does not mention ./configure, prepend the configure step.
    if {[string first "./configure" $raw_cmd] >= 0} {
        set raw_cmd [regsub {\./configure} $raw_cmd "./configure --prefix=\"$prefix\""]
    } else {
        set raw_cmd "./configure --prefix=\"$prefix\" && $raw_cmd"
    }

    # Parallelism: tune -j N based on vCPUs if args omitted or default.
    set raw_args ""
    if {[dict exists $cidict $rdbms build build_cmd_args]} {
        set raw_args [string trim [dict get $cidict $rdbms build build_cmd_args]]
    }
    if {[info commands numberOfCPUs] ne ""} {
        set cpu ""
        catch { set cpu [numberOfCPUs] }
        set cpu [string trim $cpu]
        if {[string is integer -strict $cpu] && $cpu > 0} {
            if {$raw_args eq "" || $raw_args eq "-j 8"} {
                if {$cpu <= 2} {
                    set raw_args ""
                } elseif {$cpu <= 4} {
                    set raw_args "-j 2"
                } elseif {$cpu <= 8} {
                    set raw_args "-j 4"
                } else {
                    set p [expr {$cpu - 4}]
                    if {$p < 1}  { set p 1 }
                    if {$p > 64} { set p 64 }
                    set raw_args "-j $p"
                }
            }
        }
    }

    # Only append -j N to the trailing `make` portion if make is present.
    if {[string first "make" $raw_cmd] >= 0 && $raw_args ne ""} {
        set raw_cmd [regsub {make(\s|$)} $raw_cmd "make $raw_args\\1"]
    }

    set shell_cmd "cd \"$local_dir\" && $raw_cmd 2>&1"

    catch {
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval { UPDATE JOBCI SET build_cmd = $shell_cmd WHERE ci_id = $ci_id }
        }
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

# ---------------------------------------------------------------------------
# package — PostgreSQL has no separate package step; XML <package_cmd> is a
# no-op (e.g. `true`) but we run it for JOBCI bookkeeping parity with Maria.
# ---------------------------------------------------------------------------
proc postgresql_package {cidict refname} {
    global rdbms
    set build_dir [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set ci_id     [postgresql_ci_id $cidict $refname]
    set safe_ref  [postgresql_ci_safe_ref $refname]
    set local_dir "$build_dir/ci_${ci_id}_${safe_ref}"

    set raw_cmd   [dict get $cidict $rdbms build package_cmd]
    set shell_cmd "cd \"$local_dir\" && $raw_cmd 2>&1"

    catch {
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval { UPDATE JOBCI SET package_cmd = $shell_cmd WHERE ci_id = $ci_id }
        }
    }

    putsci "Running package command (no-op for PostgreSQL)..."
    putsci $shell_cmd

    set safe_cmd [string map {\" \\\"} $shell_cmd]
    set pipe_output ""
    set package_status "PACKAGE SUCCEEDED"
    set failed_line ""

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

# ---------------------------------------------------------------------------
# commit_msg — identical to MariaDB port (git log -1 --pretty=%B).
# ---------------------------------------------------------------------------
proc postgresql_commit_msg {cidict refname} {
    global rdbms
    set build_dir [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set ci_id     [postgresql_ci_id $cidict $refname]
    set safe_ref  [postgresql_ci_safe_ref $refname]
    set local_dir "$build_dir/ci_${ci_id}_${safe_ref}"

    set raw_commit_cmd [dict get $cidict common commit_msg_cmd]
    set shell_cmd "cd \"$local_dir\" && $raw_commit_cmd 2>&1"

    catch {
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval { UPDATE JOBCI SET commit_msg_cmd = $shell_cmd WHERE ci_id = $ci_id }
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

    if {$status eq "COMMIT_MSG SUCCEEDED"} {
        set commit_msg [string trim $pipe_output]
        if {$commit_msg eq ""} {
            set status "COMMIT_MSG FAILED"
        }
    }

    if {$status eq "COMMIT_MSG FAILED"} {
        putsci "Commit message fetch failed."
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
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

# ---------------------------------------------------------------------------
# install — `make install` populates the --prefix from postgresql_build.
# ---------------------------------------------------------------------------
proc postgresql_install {cidict refname} {
    global rdbms
    set build_dir [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set ci_id     [postgresql_ci_id $cidict $refname]
    set safe_ref  [postgresql_ci_safe_ref $refname]
    set local_dir "$build_dir/ci_${ci_id}_${safe_ref}"

    set install_root [postgresql_normpath [dict get $cidict $rdbms install install_dir]]
    set install_dir  [file join $install_root "ci_${ci_id}_${safe_ref}"]
    if {![file exists $install_root] || ![file isdirectory $install_root] || ![file writable $install_root]} {
        putsci "Error: $install_root missing, not a directory, or not writable"
        return "INSTALL FAILED"
    }
    file mkdir $install_dir

    set raw_cmd ""
    if {[dict exists $cidict $rdbms install install_package]} {
        set raw_cmd [string trim [dict get $cidict $rdbms install install_package]]
    }
    if {$raw_cmd eq ""} { set raw_cmd "make install" }

    set shell_cmd "cd \"$local_dir\" && $raw_cmd 2>&1"
    set safe_cmd  [string map {\" \\\"} $shell_cmd]

    putsci "Installing PostgreSQL into [postgresql_basedir $cidict $refname]"

    catch {
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval { UPDATE JOBCI SET install_cmd = $shell_cmd WHERE ci_id = $ci_id }
        }
    }

    putsci "Running install command..."
    putsci $shell_cmd

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
    }

    # Verify the prefix actually contains bin/postgres now.
    set basedir [postgresql_basedir $cidict $refname]
    if {![file exists [file join $basedir bin postgres]]} {
        putsci "Install failed: expected binary not found: [file join $basedir bin postgres]"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval { UPDATE JOBCI SET status = 'INSTALL FAILED', install_output = $::pipe_output WHERE ci_id = $ci_id }
            }
        }
        return "INSTALL FAILED"
    }

    catch {
        set ci_id [ci_latest_id $refname]
        if {$ci_id ne ""} {
            hdbjobs eval { UPDATE JOBCI SET status = 'INSTALLED', install_output = $::pipe_output WHERE ci_id = $ci_id }
        }
    }
    return "INSTALL SUCCEEDED"
}

# ---------------------------------------------------------------------------
# init — run initdb and stage the postgresql.conf template into datadir.
# ---------------------------------------------------------------------------
proc postgresql_init {cidict refname} {
    global rdbms
    set install_section [dict get $cidict $rdbms install]
    set basedir [postgresql_basedir $cidict $refname]

    if {![file isdirectory $basedir]} {
        putsci "DB init failed: basedir missing: $basedir"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'INIT FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "INIT FAILED"
    }

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

    # datadir (under basedir by default).
    set datadir_val "data"
    if {[dict exists $install_section datadir]} {
        set datadir_val [dict get $install_section datadir]
    }
    if {[file pathtype $datadir_val] ne "absolute"} {
        set datadir_val [file join $basedir $datadir_val]
    }
    # PG requires datadir parent exist but datadir itself empty or absent.
    catch {file mkdir [file dirname $datadir_val]}

    # initdb flags.
    set arglist {}
    lappend arglist "--pgdata=\"$datadir_val\""
    lappend arglist "--username=postgres"
    lappend arglist "--auth=trust"
    lappend arglist "--encoding=UTF8"
    lappend arglist "--locale=C"

    set args_str [join $arglist " "]
    set init_cmd "cd \"$basedir\" && ./$installer $args_str 2>&1"
    set safe_cmd [string map {\" \\\"} $init_cmd]

    putsci "Initializing PostgreSQL with command:"
    putsci $init_cmd

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

    # Stage postgresql.conf / postgresqlio.conf into datadir (PG reads it from $PGDATA).
    if {$init_status eq "INIT SUCCEEDED"} {
        if {[dict exists $install_section defaults_file]} {
            set defaults_src [dict get $install_section defaults_file]
            if {[file exists $defaults_src]} {
                set defaults_dst [file join $datadir_val "postgresql.conf"]
                if {[catch {file copy -force $defaults_src $defaults_dst} err]} {
                    putsci "INIT WARNING: could not copy defaults file $defaults_src to $defaults_dst : $err"
                } else {
                    putsci "Copied defaults file $defaults_src to $defaults_dst"
                }
            } else {
                putsci "INIT WARNING: defaults file not found: $defaults_src (using initdb defaults)"
            }
        }
        if {[dict exists $install_section io_config_file]} {
            set io_src [dict get $install_section io_config_file]
            if {[file exists $io_src]} {
                set io_dst [file join $basedir [file tail $io_src]]
                catch {file copy -force $io_src $io_dst}
                putsci "Copied IO config file $io_src to $io_dst"
            }
        }
    }

    if {$init_status eq "INIT FAILED"} {
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'INIT FAILED' WHERE ci_id = $ci_id}
            }
        }
    } else {
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval { UPDATE JOBCI SET status = 'INITIALIZED' WHERE ci_id = $ci_id }
            }
        }
    }
    return $init_status
}

# ---------------------------------------------------------------------------
# start — pg_ctl start -D datadir -l logfile -o "-p <port> -c shared_buffers=..."
# ---------------------------------------------------------------------------
proc postgresql_start {cidict refname} {
    global rdbms
    set install [dict get $cidict $rdbms install]
    set ci_id   [postgresql_ci_id $cidict $refname]
    set io_intensive [postgresql_get_io_intensive $ci_id]
    set basedir [postgresql_basedir $cidict $refname]

    if {![file isdirectory $basedir]} {
        putsci "DB start failed: basedir missing: $basedir"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status = 'START FAILED' WHERE ci_id = $ci_id}
            }
        }
        return "START FAILED"
    }

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

    # Pick active config file for recording in JOBCI.
    set defaults_src ""
    if {$io_intensive == 1 && [dict exists $install io_config_file]} {
        set defaults_src [dict get $install io_config_file]
        putsci "Using Durable / I/O intensive config: $defaults_src"
    } elseif {[dict exists $install defaults_file]} {
        set defaults_src [dict get $install defaults_file]
        putsci "Using default config: $defaults_src"
    }

    set datadir_val "data"
    if {[dict exists $install datadir]} {
        set datadir_val [dict get $install datadir]
    }
    if {[file pathtype $datadir_val] ne "absolute"} {
        set datadir_val [file join $basedir $datadir_val]
    }

    # For I/O intensive runs, re-stage the io config file over datadir's postgresql.conf
    # so the server picks up the durable settings at start time.
    if {$io_intensive == 1 && $defaults_src ne "" && [file exists $defaults_src]} {
        set dst [file join $datadir_val "postgresql.conf"]
        catch {file copy -force $defaults_src $dst}
    }

    set port 5432
    if {[dict exists $install port]} {
        set p [dict get $install port]
        if {[string is integer -strict $p]} { set port $p }
    }

    set socket_dir "/tmp"
    if {[dict exists $install socket]} {
        set socket_dir [dict get $install socket]
    }

    # Tuning — shared_buffers from generic calc, max_wal_size from calc_redo_mb.
    set bp_cfg ""
    if {[dict exists $install shared_buffers]} {
        set bp_cfg [string trim [dict get $install shared_buffers]]
    }
    set bp_mb 1000
    if {$bp_cfg eq "" || [string equal -nocase $bp_cfg "auto"]} {
        set bp_mb [calc_buffer_pool_mb]
        if {$bp_mb > 0} { putsci "Auto-tune: shared_buffers=${bp_mb}MB" }
    } elseif {[string is integer -strict $bp_cfg]} {
        set bp_mb $bp_cfg
        putsci "User override: shared_buffers=${bp_mb}MB"
    } else {
        putsci "WARNING: invalid shared_buffers='$bp_cfg' (expected auto or MB integer)"
    }
    if {$bp_mb <= 0} { set bp_mb 128 }

    set wal_mb [calc_redo_mb]

    set listen_addrs "localhost"
    if {[dict exists $install listen_addresses]} {
        set la [string trim [dict get $install listen_addresses]]
        if {$la ne ""} { set listen_addrs $la }
    }

    set server_opts [list]
    lappend server_opts "-p $port"
    lappend server_opts "-k $socket_dir"
    lappend server_opts "-c shared_buffers=${bp_mb}MB"
    lappend server_opts "-c max_wal_size=${wal_mb}MB"
    lappend server_opts "-c listen_addresses=$listen_addrs"
    set opts_str [join $server_opts " "]

    set logfile [file join $basedir "postgres.log"]

    set full_cmd "cd \"$basedir\" && $start_cmd -D \"$datadir_val\" -l \"$logfile\" -w -t 60 -o \"$opts_str\" start"

    putsci "Starting PostgreSQL:"
    putsci $full_cmd

    # Save config_file + start_cmd for JOBCI.
    set config_file ""
    if {$defaults_src ne "" && [file exists $defaults_src]} {
        if {[catch {
            set fh [open $defaults_src r]
            set config_file [read $fh]
            close $fh
        } err]} {
            putsci "WARNING: could not read config file $defaults_src : $err"
            set config_file ""
        }
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
    set shell_safe_cmd [string map {\" \\\"} $full_cmd]
    if {[catch {
        set pipe [open "|bash -c \"$shell_safe_cmd\"" "r"]
        fconfigure $pipe -blocking 0 -buffering line
        fileevent $pipe readable [list handle_output $pipe]
        after 30000 {set ::pipe_done 1}
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

# ---------------------------------------------------------------------------
# run_sql — dispatches by key. key=shutdown runs pg_ctl stop -m fast;
# all other keys run `psql -h localhost -p <port> -U postgres -c "<sql>"`.
# ---------------------------------------------------------------------------
proc postgresql_run_sql {cidict refname key} {
    global rdbms
    set install [dict get $cidict $rdbms install]

    set KEY    [string toupper $key]
    set FAILED "${KEY} FAILED"
    set OK     "${KEY} SUCCEEDED"

    set basedir [postgresql_basedir $cidict $refname]
    if {![file isdirectory $basedir]} {
        putsci "RUN_SQL $key: basedir missing: $basedir"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status=$FAILED WHERE ci_id=$ci_id}
            }
        }
        return $FAILED
    }

    set port 5432
    if {[dict exists $install port]} {
        set p [dict get $install port]
        if {[string is integer -strict $p]} { set port $p }
    }

    # Shutdown is a pg_ctl invocation, not SQL.
    if {[string equal -nocase $key "shutdown"]} {
        set datadir_val "data"
        if {[dict exists $install datadir]} {
            set datadir_val [dict get $install datadir]
        }
        if {[file pathtype $datadir_val] ne "absolute"} {
            set datadir_val [file join $basedir $datadir_val]
        }
        set stop_cmd "cd \"$basedir\" && ./bin/pg_ctl -D \"$datadir_val\" stop -m fast -w 2>&1"
        putsci "RUN_SQL shutdown:"
        putsci $stop_cmd

        set ::pipe_output ""
        set close_status OK
        if {[catch {
            set pipe [open "|bash -c \"[string map {\" \\\"} $stop_cmd]\"" "r"]
            fconfigure $pipe -blocking 1 -buffering line
            while {[gets $pipe line] >= 0} {
                append ::pipe_output "$line\n"
                putsci $line
            }
            if {[catch {close $pipe} errMsg]} { set close_status $errMsg }
        } errMsg]} {
            putsci "RUN_SQL shutdown failed to spawn: $errMsg"
            catch {
                set ci_id [ci_latest_id $refname]
                if {$ci_id ne ""} {
                    hdbjobs eval {UPDATE JOBCI SET status='SHUTDOWN FAILED' WHERE ci_id=$ci_id}
                }
            }
            return "SHUTDOWN FAILED"
        }
        if {$close_status ne "OK"} {
            putsci "RUN_SQL shutdown error: $close_status"
            # pg_ctl stop against an already-stopped server returns non-zero;
            # treat that as success if the output suggests no server was running.
            if {[regexp -nocase {no server running|PID file .* does not exist} $::pipe_output]} {
                putsci "RUN_SQL shutdown: server already stopped — treating as success"
                return "SHUTDOWN SUCCEEDED"
            }
            catch {
                set ci_id [ci_latest_id $refname]
                if {$ci_id ne ""} {
                    hdbjobs eval {UPDATE JOBCI SET status='SHUTDOWN FAILED' WHERE ci_id=$ci_id}
                }
            }
            return "SHUTDOWN FAILED"
        }
        return "SHUTDOWN SUCCEEDED"
    }

    # All other keys are SQL statements passed to psql via -c.
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

    set sql     [dict get $install $key]
    set sql_esc [string map {\" \\\"} $sql]
    set sql_cmd "./bin/psql -h localhost -p $port -U postgres -d postgres -v ON_ERROR_STOP=1 -c \\\"$sql_esc\\\""

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
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status=$FAILED WHERE ci_id=$ci_id}
            }
        }
        return $FAILED
    }

    if {$close_status ne "OK"} {
        putsci "RUN_SQL $key error: $close_status"
        catch {
            set ci_id [ci_latest_id $refname]
            if {$ci_id ne ""} {
                hdbjobs eval {UPDATE JOBCI SET status=$FAILED WHERE ci_id=$ci_id}
            }
        }
        return $FAILED
    }

    return $OK
}

# ---------------------------------------------------------------------------
# ping — psql SELECT version() retry loop.
# ---------------------------------------------------------------------------
proc _postgresql_ping_capture {pipe} {
    if {[eof $pipe]} {
        set ::pipe_done 1
        return
    }
    if {[gets $pipe line] >= 0} {
        putsci $line
        append ::_postgresql_ping_output $line "\n"
    }
}

proc postgresql_ping {cidict refname} {
    global rdbms
    set install [dict get $cidict $rdbms install]

    set basedir [postgresql_basedir $cidict $refname]
    if {![file isdirectory $basedir]} {
        putsci "PING: basedir missing: $basedir"
        return "PING FAILED"
    }

    set port 5432
    if {[dict exists $install port]} {
        set p [dict get $install port]
        if {[string is integer -strict $p]} { set port $p }
    }

    set sql "SELECT version()"
    if {[dict exists $install ping]} {
        set sql [string trim [dict get $install ping]]
    }
    set sql_esc [string map {\" \\\"} $sql]
    set sql_cmd "./bin/psql -h localhost -p $port -U postgres -d postgres -t -c \\\"$sql_esc\\\""

    putsci "PING:"
    putsci $sql_cmd

    set attempts 30
    set wait_ms 2000

    for {set attempt 1} {$attempt <= $attempts} {incr attempt} {
        set ::_postgresql_ping_output ""
        set close_status OK

        if {[catch {
            set cmd "cd \"$basedir\" && $sql_cmd 2>&1"
            set pipe [open "|bash -c {$cmd}" "r"]
            fconfigure $pipe -blocking 1
            set ::_postgresql_ping_output [read $pipe]

            if {[catch {close $pipe} errMsg]} {
                set close_status $errMsg
            }
        } errMsg]} {
            set close_status $errMsg
            set ::_postgresql_ping_output $errMsg
        }

        set output_trim [string trim [string map {\r ""} $::_postgresql_ping_output]]
        if {$close_status eq "OK" && [regexp -nocase {postgresql} $output_trim]} {
            foreach line [split $output_trim "\n"] {
                putsci $line
            }
            return "PING SUCCEEDED"
        }

        putsci "PING attempt $attempt failed"
        putsci "PING close_status: $close_status"
        putsci "PING output:"
        foreach line [split $output_trim "\n"] {
            putsci $line
        }

        if {$attempt < $attempts} {
            after $wait_ms
        }
    }

    putsci "PING FAILED: no version returned"
    return "PING FAILED"
}

# ---------------------------------------------------------------------------
# start_tests — invokes shell runner (oltp/olap) from ci.xml.
# ---------------------------------------------------------------------------
proc postgresql_start_tests {cidict refname workload} {
    global rdbms
    set ci_id [ci_latest_id $refname]
    set ::env(UAW) [postgresql_get_io_intensive $ci_id]

    hdbjobs eval {UPDATE JOBCI SET status = 'RUNNING' WHERE ci_id = $ci_id}
    putsci "PostgreSQL is up and running for $refname"

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

# ---------------------------------------------------------------------------
# profile — run a single tag/commit through the full pipeline + profile runner.
# ---------------------------------------------------------------------------
proc postgresql_profile {cidict refname} {
    global rdbms
    if {(![info exists ::env(TMP)] || $::env(TMP) eq "") &&
        [info exists ::env(TMPDIR)] && $::env(TMPDIR) ne ""} {
        set ::env(TMP) $::env(TMPDIR)
    }
    ci_check_tmp

    if {![dict exists $cidict $rdbms build build_dir]} {
        putsci "PROFILE FAILED: <$rdbms>/<build>/<build_dir> missing"
        return "PROFILE FAILED"
    }
    set build_root [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set bad_tag [expr {[string match "refs/tags/*" $refname] ? [file tail $refname] : $refname}]

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
    set io_intensive [postgresql_get_io_intensive $ci_id]
    set uaw [expr {$io_intensive == 1 ? 1 : 0}]

    set repo [file join $build_root "ci_${ci_id}_${bad_tag}"]
    if {[file isdirectory $repo]} {
        putsci "PROFILE FAILED: repo already exists: $repo"
        return "PROFILE FAILED"
    }

    if {![dict exists $cidict $rdbms test profile]} {
        putsci "PROFILE FAILED: <$rdbms>/<test>/<profile> missing in XML"
        return "PROFILE FAILED"
    }
    set runner_raw [string map {\" {}} [dict get $cidict $rdbms test profile]]
    set ham_root [pwd]
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

    set pipeline_mode ""
    catch {
        set pipeline_mode [string trim [hdbjobs eval \
            "SELECT pipeline FROM JOBCI WHERE ci_id=$ci_id LIMIT 1"]]
    }
    set pipeline_mode [string tolower $pipeline_mode]

    if {$pipeline_mode in {"single" "single_c" "single_h"}} {
        set bad_pid 0
        set ::jobs_profile_id 0
        catch { hdbjobs eval "UPDATE JOBCI SET profile_id=0 WHERE ci_id=$ci_id" }
        putsci "PROFILEIDS 0"
    } else {
        set pid_base 1000
        if {[dict exists $cidict $rdbms pipeline profileid]} {
            set pid_base [dict get $cidict $rdbms pipeline profileid]
        }
        if {$pid_base < 1000} { set pid_base 1000 }
        set bad_pid $pid_base
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

    proc _pg_profile_run_once {ham_root runner_abs tag pid uaw} {
        set run "cd $ham_root && env REFNAME=$tag PROFILEID=$pid UAW=$uaw $runner_abs"
        putsci "RUNNING BENCHMARK: $run"
        set ci_id [ci_latest_id $tag]
        if {$ci_id ne ""} {
            hdbjobs eval {UPDATE JOBCI SET status = 'RUNNING' WHERE ci_id = $ci_id}
        }
        set doneVar "::pg_profile_run_done_[clock milliseconds]"
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

    catch { hdbjobs eval { UPDATE JOBCI SET status='CLONING' WHERE ci_id=$ci_id } }
    set cst [postgresql_clone $cidict $bad_tag]
    if {$cst eq "CLONE FAILED"}   { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='COMMIT MSG' WHERE ci_id=$ci_id } }
    set cmst [postgresql_commit_msg $cidict $bad_tag]
    if {$cmst eq "COMMIT_MSG FAILED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='BUILDING' WHERE ci_id=$ci_id } }
    set bst [postgresql_build $cidict $bad_tag]
    if {$bst eq "BUILD FAILED"}   { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='PACKAGING' WHERE ci_id=$ci_id } }
    set pst [postgresql_package $cidict $bad_tag]
    if {$pst eq "PACKAGE FAILED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='INSTALLING' WHERE ci_id=$ci_id } }
    set ist [postgresql_install $cidict $bad_tag]
    if {$ist eq "INSTALL FAILED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='INIT' WHERE ci_id=$ci_id } }
    set int [postgresql_init $cidict $bad_tag]
    if {$int eq "INIT FAILED"} { return "PROFILE FAILED" }
    # NOTE: no pre-start shutdown — initdb never leaves a PG server running.
    catch { hdbjobs eval { UPDATE JOBCI SET status='STARTING' WHERE ci_id=$ci_id } }
    set sst [postgresql_start $cidict $bad_tag]
    if {$sst eq "START FAILED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='PING' WHERE ci_id=$ci_id } }
    set pst [postgresql_ping $cidict $bad_tag]
    if {$pst eq "PING FAILED"} { return "PROFILE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='RUNNING' WHERE ci_id=$ci_id } }
    set rsy [postgresql_run_sql $cidict $bad_tag change_password]
    if {$rsy eq "CHANGE_PASSWORD FAILED"} { return "PROFILE FAILED" }
    if {![_pg_profile_run_once $ham_root $runner_abs $bad_tag $bad_pid $uaw]} {
        return "PROFILE FAILED"
    }

    set stop_st [postgresql_run_sql $cidict $bad_tag shutdown]
    putsci $stop_st
    if {$stop_st ne "SHUTDOWN SUCCEEDED"} {
        putsci "PROFILE FAILED: shutdown failed after profile"
        return "PROFILE FAILED"
    }
    return "PROFILE DONE"
}

# ---------------------------------------------------------------------------
# compare — run two tags (bad + baseline) back-to-back and diff profiles.
# ---------------------------------------------------------------------------
proc postgresql_compare {cidict refname} {
    global rdbms
    if {(![info exists ::env(TMP)] || $::env(TMP) eq "") &&
        [info exists ::env(TMPDIR)] && $::env(TMPDIR) ne ""} {
        set ::env(TMP) $::env(TMPDIR)
    }
    ci_check_tmp

    set dbprefix [find_prefix $rdbms]

    if {![dict exists $cidict $rdbms build build_dir]} {
        putsci "COMPARE FAILED: <$rdbms>/<build>/<build_dir> missing"
        return "COMPARE FAILED"
    }
    set build_root [string map {\" {}} [dict get $cidict $rdbms build build_dir]]
    set bad_tag [expr {[string match "refs/tags/*" $refname] ? [file tail $refname] : $refname}]

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

    set io_intensive [postgresql_get_io_intensive $ci_id]
    set uaw [expr {$io_intensive == 1 ? 1 : 0}]

    set repo [file join $build_root "ci_${ci_id}_${bad_tag}"]
    if {[file isdirectory $repo]} {
        putsci "COMPARE FAILED: repo already exists: $repo"
        return "COMPARE FAILED"
    }

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

    set pid_base 1000
    if {[dict exists $cidict $rdbms pipeline compare_profileid]} {
        set pid_base [dict get $cidict $rdbms pipeline compare_profileid]
    }
    set bad_pid  $pid_base
    set good_pid [expr {$pid_base + 1}]

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

    proc _pg_compare_run_once {ham_root runner_abs tag pid ci_id uaw} {
        set run "cd $ham_root && env REFNAME=$tag PROFILEID=$pid UAW=$uaw $runner_abs"
        putsci "RUNNING BENCHMARK: $run"
        if {$ci_id ne ""} {
            hdbjobs eval {UPDATE JOBCI SET status = 'RUNNING' WHERE ci_id = $ci_id}
        }
        set doneVar "::pg_compare_run_done_[clock milliseconds]"
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

    # 1) Run bad_tag through full pipeline + profile runner.
    catch { hdbjobs eval { UPDATE JOBCI SET status='CLONING' WHERE ci_id=$ci_id } }
    set cst [postgresql_clone $cidict $bad_tag]
    if {$cst eq "CLONE FAILED"}   { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='COMMIT MSG' WHERE ci_id=$ci_id } }
    set cmst [postgresql_commit_msg $cidict $bad_tag]
    if {$cmst eq "COMMIT_MSG FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='BUILDING' WHERE ci_id=$ci_id } }
    set bst [postgresql_build $cidict $bad_tag]
    if {$bst eq "BUILD FAILED"}   { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='PACKAGING' WHERE ci_id=$ci_id } }
    set pst [postgresql_package $cidict $bad_tag]
    if {$pst eq "PACKAGE FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='INSTALLING' WHERE ci_id=$ci_id } }
    set ist [postgresql_install $cidict $bad_tag]
    if {$ist eq "INSTALL FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='INIT' WHERE ci_id=$ci_id } }
    set int [postgresql_init $cidict $bad_tag]
    if {$int eq "INIT FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='STARTING' WHERE ci_id=$ci_id } }
    set sst [postgresql_start $cidict $bad_tag]
    if {$sst eq "START FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='PING' WHERE ci_id=$ci_id } }
    set pst [postgresql_ping $cidict $bad_tag]
    if {$pst eq "PING FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='RUNNING' WHERE ci_id=$ci_id } }
    set rsy [postgresql_run_sql $cidict $bad_tag change_password]
    if {$rsy eq "CHANGE_PASSWORD FAILED"} { return "COMPARE FAILED" }
    if {![_pg_compare_run_once $ham_root $runner_abs $bad_tag $bad_pid $ci_id $uaw]} {
        return "COMPARE FAILED"
    }

    set stop_st [postgresql_run_sql $cidict $bad_tag shutdown]
    if {$stop_st ne "SHUTDOWN SUCCEEDED"} {
        putsci "COMPARE FAILED: shutdown failed before switching binaries"
        return "COMPARE FAILED"
    }

    # 2) Determine baseline tag (good_tag): previous commit for commit-ref, else previous tag.
    set is_commit 0
    if {[regexp {^[0-9a-f]{7,40}$} $bad_tag]} {
        set is_commit 1
    }

    catch {cd $ham_root}

    if {$is_commit} {
        set desc_cmd "cd $repo && git rev-list --max-count=1 $bad_tag^"
        putsci "COMPARE PRECHECK: $desc_cmd"
        if {[catch { set good_tag [exec bash -c "$desc_cmd"] } derr]} {
            putsci "COMPARE FAILED: could not find previous commit of $bad_tag: $derr"
            return "COMPARE FAILED"
        }
        set good_tag [string trim $good_tag]
    } else {
        if {[catch { set alltags [exec git -C $repo tag -l "REL_*" --sort=v:refname] } derr]} {
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

    # 3) Build+run baseline through its own JOBCI row.
    hdbjobs eval {INSERT INTO JOBCI (refname,dbprefix,cidict,io_intensive) VALUES ($good_tag,$dbprefix,$cidict,$io_intensive)}
    set ci_id [hdbjobs eval {SELECT last_insert_rowid()}]
    if {$ci_id ne ""} {
        hdbjobs eval {UPDATE JOBCI SET status = 'BUILDING' WHERE ci_id = $ci_id}
        hdbjobs eval {UPDATE JOBCI SET profile_id = $good_pid WHERE ci_id = $ci_id}
        hdbjobs eval {UPDATE JOBCI SET pipeline = 'COMPARE' WHERE ci_id = $ci_id}
    }

    # Baseline clone via git worktree from bad_tag's repo (avoids full re-clone).
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
                if {[regexp -nocase {fatal:|error:} $line]} { set clone_status "CLONE FAILED" }
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
            putsci $pipe_output
            catch { hdbjobs eval { UPDATE JOBCI SET status='CLONE FAILED', clone_output=$pipe_output WHERE ci_id=$ci_id } }
            return "COMPARE FAILED"
        }
        catch { hdbjobs eval { UPDATE JOBCI SET clone_output = $pipe_output WHERE ci_id = $ci_id } }
    } else {
        putsci "Using existing worktree for $good_tag"
        catch { hdbjobs eval { UPDATE JOBCI SET clone_output='Using existing worktree' WHERE ci_id=$ci_id } }
    }

    catch { hdbjobs eval { UPDATE JOBCI SET status='COMMIT MSG' WHERE ci_id=$ci_id } }
    set cmst [postgresql_commit_msg $cidict $good_tag]
    if {$cmst eq "COMMIT_MSG FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='BUILDING' WHERE ci_id=$ci_id } }
    set bst [postgresql_build $cidict $good_tag]
    if {$bst eq "BUILD FAILED"}   { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='PACKAGING' WHERE ci_id=$ci_id } }
    set pst [postgresql_package $cidict $good_tag]
    if {$pst eq "PACKAGE FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='INSTALLING' WHERE ci_id=$ci_id } }
    set ist [postgresql_install $cidict $good_tag]
    if {$ist eq "INSTALL FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='INIT' WHERE ci_id=$ci_id } }
    set int [postgresql_init $cidict $good_tag]
    if {$int eq "INIT FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='STARTING' WHERE ci_id=$ci_id } }
    set sst [postgresql_start $cidict $good_tag]
    if {$sst eq "START FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='PING' WHERE ci_id=$ci_id } }
    set pst [postgresql_ping $cidict $good_tag]
    if {$pst eq "PING FAILED"} { return "COMPARE FAILED" }
    catch { hdbjobs eval { UPDATE JOBCI SET status='RUNNING' WHERE ci_id=$ci_id } }
    set rsy [postgresql_run_sql $cidict $good_tag change_password]
    if {$rsy eq "CHANGE_PASSWORD FAILED"} { return "COMPARE FAILED" }

    if {![_pg_compare_run_once $ham_root $runner_abs $good_tag $good_pid $ci_id $uaw]} {
        return "COMPARE FAILED"
    }

    set stop_st [postgresql_run_sql $cidict $good_tag shutdown]
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
