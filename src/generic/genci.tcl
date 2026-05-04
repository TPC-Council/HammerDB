# load ci.xml
# escape quotes
proc CI_SQLEscape {s} {
    # escape '
    return [string map {' ''} $s]
}

# write ci.db
proc CIDict2SQLite {dbname dbdict} {
    set sqlitedb [CheckSQLiteDB $dbname]

    if {[catch {sqlite3 hdb $sqlitedb} message]} {
        putscli "CI CONFIG: error initializing SQLite database: $message"
        return 0
    }

    catch {hdb timeout 30000}

    if {$sqlitedb eq ""} {
        putscli "CI CONFIG: empty SQLite DB path"
        return 0
    }

    # quote table names
    dict for {key attributes} $dbdict {
        set tablename $key

        # recreate table
        set sqlcmd "DROP TABLE IF EXISTS \"$tablename\""
        catch {hdb eval $sqlcmd}

        set sqlcmd "CREATE TABLE \"$tablename\"(key TEXT, val TEXT)"
        if {[catch {hdb eval $sqlcmd} message]} {
            putscli "CI CONFIG: error creating table $tablename in $sqlitedb : $message"
            return 0
        }

        # insert rows
        dict for {subkey subattributes} $attributes {
            set k [CI_SQLEscape $subkey]
            set v [CI_SQLEscape $subattributes]
            set sqlcmd "INSERT INTO \"$tablename\"(key, val) VALUES('$k', '$v')"
            if {[catch {hdb eval $sqlcmd} message]} {
                putscli "CI CONFIG: error inserting into $tablename in $sqlitedb : $message"
                return 0
            }
        }
    }

    return 1
}

# read ci.db
proc SQLite2Dict_ci {dbname} {
    set sqlitedb [CheckSQLiteDB $dbname]

    if {$sqlitedb eq "" || ![file exists $sqlitedb]} {
        return ""
    }

    if {[catch {sqlite3 cih $sqlitedb} message]} {
        putscli "CI ERROR: Cannot open SQLite database $sqlitedb : $message"
        return ""
    }

    catch {cih timeout 30000}

    set overrides [dict create]

    if {[catch {set tbllist [cih eval {SELECT name FROM sqlite_master WHERE type='table'}]} err]} {
        putscli "CI ERROR: Failed to read CI table list from $sqlitedb : $err"
        catch {cih close}
        return ""
    }

    foreach tbl $tbllist {
        # common overrides
        if {$tbl eq "common"} {
            set subdict [dict create]
            if {[catch {
                cih eval "SELECT key, val FROM \"$tbl\"" {
                    dict set subdict $key $val
                }
            } qerr]} {
                putscli "CI WARN: Skipping table '$tbl' in CI SQLite: $qerr"
                continue
            }
            dict set overrides common $subdict
            continue
        }

        # Top_section
        if {![regexp {^([^_]+)_(.+)$} $tbl -> top section]} {
            # ignore other tables
            continue
        }

        set secdict [dict create]
        if {[catch {
            cih eval "SELECT key, val FROM \"$tbl\"" {
                dict set secdict $key $val
            }
        } qerr]} {
            putscli "CI WARN: Skipping table '$tbl' in CI SQLite: $qerr"
            continue
        }

        dict set overrides $top $section $secdict
    }

    catch {cih close}

    if {[dict size $overrides] == 0} {
        return ""
    }
    return $overrides
}

proc find_ciplan_dir {} {
    if {[catch {
        set ISConfigDir [file join {*}[lrange [file split [file normalize [file dirname [info script]]]] 0 end-2] config]
    }]} {
        set ISConfigDir ""
    }
    set PWConfigDir [file join [pwd] config]
    foreach CD {ISConfigDir PWConfigDir} {
        if {[file isdirectory [set $CD]]} {
            if {[file exists [file join [set $CD] ci.xml]]} {
                return [set $CD]
            }
        }
    }
    return "FNF"
}

proc get_ciplan_xml {} {
    if {[catch {package require xml}]} {
        error "Failed to load xml package in CI"
    }
    set ciplandir [find_ciplan_dir]
    if {$ciplandir eq "FNF"} {
        error "Cannot find config directory or ci.xml"
    }
    set ciplanxml "$ciplandir/ci.xml"
    if {![file exists $ciplanxml]} {
        error "CI plan specified but file $ciplanxml does not exist"
    }
    set ciplan [::XML::To_Dict_Ml $ciplanxml]
    return $ciplan
}

# CI config
global cidict
set cidict [dict create]

# init CI config
proc ci_init_config {} {
    global cidict

    # XML base
    if {[catch { set xml_cfg [get_ciplan_xml] } err]} {
        putscli "CI CONFIG: could not load ci.xml ($err)"
        set cidict [dict create]
        return
    }

    # load overrides
    set override_cfg [SQLite2Dict_ci "ci"]

    if {$override_cfg eq ""} {
        # seed ci.db
        set cidict $xml_cfg
        if {[catch { CIDict2SQLite "ci" $cidict } derr]} {
            putscli "CI CONFIG: failed to save CI config to SQLite ($derr)"
        }
        return
    }

    # merge config
    set merged $xml_cfg

    foreach top [dict keys $override_cfg] {
        if {$top eq "common"} {
            # common
            set sub [dict get $override_cfg common]
            foreach k [dict keys $sub] {
                dict set merged common $k [dict get $sub $k]
            }
        } else {
            # per-db sections
            set topdict [dict get $override_cfg $top]
            foreach section [dict keys $topdict] {
                set secdict [dict get $topdict $section]
                foreach k [dict keys $secdict] {
                    dict set merged $top $section $k [dict get $secdict $k]
                }
            }
        }
    }

    set cidict $merged
}

# update ci.db
proc SQLiteUpdateKeyValue_ci {dbname table keyname value} {
    # ci.db path
    set sqlitedb [CheckSQLiteDB $dbname]

    if {$sqlitedb eq ""} {
        putscli "CI ERROR: SQLite DB path for '$dbname' is empty"
        return
    }

    # separate handle
    if {[catch {sqlite3 hci $sqlitedb} err]} {
        putscli "CI ERROR: Failed to open SQLite DB '$sqlitedb': $err"
        return
    }
    catch {hci timeout 30000}

    # ensure table
    set create_sql [format {CREATE TABLE IF NOT EXISTS "%s"(key TEXT, val TEXT)} $table]
    if {[catch {hci eval $create_sql} err]} {
        putscli "CI ERROR: Failed to ensure table '$table' in '$sqlitedb': $err"
        catch {hci close}
        return
    }

    # escape key/value
    set esckey [string map {' ''} $keyname]
    set escval [string map {' ''} $value]

    # UPDATE first
    set update_sql [format {UPDATE "%s" SET val = '%s' WHERE key = '%s'} \
                        $table $escval $esckey]
    if {[catch {hci eval $update_sql} err]} {
        putscli "CI ERROR: Failed to update SQLite: $err"
        catch {hci close}
        return
    }

    # row updated?
    set changed 0
    catch { set changed [hci eval {SELECT changes()}] }

    # else INSERT
    if {$changed == 0} {
        set insert_sql [format {INSERT INTO "%s"(key,val) VALUES('%s','%s')} \
                            $table $esckey $escval]
        if {[catch {hci eval $insert_sql} err]} {
            putscli "CI ERROR: Failed to insert into SQLite: $err"
            catch {hci close}
            return
        }
    }

    catch {hci close}
}

proc ciset {args} {
    global cidict

    # ciset top section key value
    # ciset top key value
    set argc [llength $args]
    if {$argc != 4 && $argc != 3} {
        putscli "Error: Invalid number of arguments"
        putscli "Usage: ciset top section key value"
        putscli "   or: ciset top key value"
        putscli "Example: ciset MariaDB build repo_url https://github.com/new/repo.git"
        putscli "Example: ciset common diff_threshold 0.03"
        return
    }

    if {$argc == 4} {
        set top     [lindex $args 0]
        set section [lindex $args 1]
        set key     [lindex $args 2]
        set val     [lindex $args 3]
    } else {
        # 3 args
        set top     [lindex $args 0]
        set section ""
        set key     [lindex $args 1]
        set val     [lindex $args 2]
    }

    # match top-level
    set matchTop ""
    foreach k [dict keys $cidict] {
        if {[string equal -nocase $k $top]} {
            set matchTop $k
            break
        }
    }

    if {$matchTop eq ""} {
        putscli "CI ERROR: Top-level '$top' does not exist"
        putscli "Available: [join [dict keys $cidict] ,]"
        return
    }

    # canonical key
    set top $matchTop

    if {$argc == 3} {
        # validate key
        if {![dict exists $cidict $top $key]} {
            putscli "CI ERROR: Key '$key' not found under '$top'"
            putscli "Available: [join [dict keys [dict get $cidict $top]] ,]"
            return
        }

        set previous [dict get $cidict $top $key]
        if {$previous eq $val} {
            putscli "Value unchanged ($val) — no update needed."
            return
        }

        dict set cidict $top $key $val
        putscli "Changed $top/$key from \"$previous\" to \"$val\""

        # save top
        if {[catch {
            SQLiteUpdateKeyValue_ci "ci" $top $key $val
        } err]} {
            putscli "CI ERROR: Failed to update SQLite: $err"
        }

        remote_command [concat ciset $top $key [list \{$val\}]]
        return
    }

    # 4 args

    # validate level 2
    if {![dict exists $cidict $top $section]} {
        putscli "CI ERROR: Section '$section' not found under '$top'"
        putscli "Available: [join [dict keys [dict get $cidict $top]] ,]"
        return
    }

    # validate level 3
    if {![dict exists $cidict $top $section $key]} {
        putscli "CI ERROR: Key '$key' not found under '$top/$section'"
        putscli "Available: [join [dict keys [dict get $cidict $top $section]] ,]"
        return
    }

    set previous [dict get $cidict $top $section $key]
    if {$previous eq $val} {
        putscli "Value unchanged ($val) — no update needed."
        return
    }

    dict set cidict $top $section $key $val
    putscli "Changed $top/$section/$key from \"$previous\" to \"$val\""

    if {[catch {
        SQLiteUpdateKeyValue_ci "ci" "${top}_${section}" $key $val

        set secdict_str [dict get $cidict $top $section]
        SQLiteUpdateKeyValue_ci "ci" $top $section $secdict_str
    } err]} {
        putscli "CI ERROR: Failed to update SQLite: $err"
    }

    remote_command [concat ciset $top $section $key [list \{$val\}]]
}

# init on load
if {![info exists ::ci_config_inited]} {
    set ::ci_config_inited 1
    ci_init_config
}

proc ci_check_tmp {} {
    if {![info exists ::env(TMP)] || $::env(TMP) eq ""} {
        putscli "CI TMP WARNING: ::env(TMP) not set; jobs DB will default to /tmp/hammer.DB"
    } else {
        putscli "CI TMP INFO: ::env(TMP) = $::env(TMP)"
        putscli "CI TMP INFO: Jobs on-disk DB = $::env(TMP)/hammer.DB"
    }
}

proc citmp {} {
    if {[info exists ::env(TMP)] && $::env(TMP) ne ""} {
        putscli "TMP = $::env(TMP)"
        putscli "Jobs DB file = $::env(TMP)/hammer.DB"
    } else {
        putscli "TMP not set; default jobs DB = /tmp/hammer.DB"
    }
}

proc ci_latest_id {refname} {
    set ci_id ""
    if {[catch {
        set ci_id [hdbjobs eval {
            SELECT ci_id
            FROM JOBCI
            WHERE refname=$refname
              AND status != 'PENDING'
            ORDER BY ci_id DESC
            LIMIT 1
        }]
    } err]} {
        putscli "Warning: failed to query latest ci_id for refname $refname: $err"
        return ""
    }
    return $ci_id
}

proc ci_validate {cidict {verbose 0}} {

    set say [list {msg verbose} {
        if {$verbose} {
            putsci $msg
        }
    }]

    set check_dir [list {label path} {
        if {$path eq ""} {
            putsci "CI VALIDATE ERROR: $label is empty"
            return 1
        }
        if {![file exists $path]} {
            putsci "CI VALIDATE ERROR: missing directory: $path ($label)"
            return 1
        }
        if {![file isdirectory $path]} {
            putsci "CI VALIDATE ERROR: not a directory: $path ($label)"
            return 1
        }
        if {![file readable $path]} {
            putsci "CI VALIDATE ERROR: directory not readable: $path ($label)"
            return 1
        }
        if {![file writable $path]} {
            putsci "CI VALIDATE ERROR: directory not writable: $path ($label)"
            return 1
        }
        return 0
    }]

    set check_file [list {label path} {
        if {$path eq ""} {
            putsci "CI VALIDATE ERROR: $label is empty"
            return 1
        }
        if {![file exists $path]} {
            putsci "CI VALIDATE ERROR: missing file: $path ($label)"
            return 1
        }
        if {[file isdirectory $path]} {
            putsci "CI VALIDATE ERROR: expected file but found directory: $path ($label)"
            return 1
        }
        if {![file readable $path]} {
            putsci "CI VALIDATE ERROR: file not readable: $path ($label)"
            return 1
        }
        return 0
    }]

    set under_root [list {child parent} {
        set child  [file normalize $child]
        set parent [file normalize $parent]
        return [expr {[string first "${parent}/" "${child}/"] == 0 || $child eq $parent}]
    }]

    set cfg $cidict
    if {[dict exists $cfg ci]} {
        set cfg [dict get $cfg ci]
    }

    if {$cfg eq ""} {
        putsci "CI VALIDATE ERROR: no configuration loaded"
        return 1
    }

    set errs 0
    set pwd_here [pwd]

    apply $say "CI VALIDATE: starting" $verbose

    set common_root ""
    if {[dict exists $cfg common root]} {
        set common_root [string trim [dict get $cfg common root]]
        if {$common_root ne ""} {
            incr errs [apply $check_dir "common/root" $common_root]
        }
    }

    if {[dict exists $cfg common tmp]} {
        set tmpdir [string trim [dict get $cfg common tmp]]
        if {$tmpdir ne ""} {
            incr errs [apply $check_dir "common/tmp" $tmpdir]
        set runtime_tmp "/tmp"
        if {[info exists ::env(TMP)] && [string trim $::env(TMP)] ne ""} {
            set runtime_tmp [string trim $::env(TMP)]
        }
        
        if {[file normalize $runtime_tmp] ne [file normalize $tmpdir]} {
            putsci "CI VALIDATE WARNING: current TMP ($runtime_tmp) does not match common/tmp ($tmpdir)"
            putsci "CI VALIDATE WARNING: export TMP=$tmpdir and restart HammerDB recommended"
        }
            if {$common_root ne "" && ![apply $under_root $tmpdir $common_root]} {
                putsci "CI VALIDATE ERROR: common/tmp not under common/root ($tmpdir)"
                incr errs
            }
        }
    }

    dict for {provider pdata} $cfg {
        if {$provider eq "common"} {
            continue
        }
        if {[catch {dict size $pdata}]} {
            continue
        }

        apply $say "CI VALIDATE: provider $provider" $verbose

        set provider_root ""
        if {[dict exists $pdata build local_dir_root]} {
            set provider_root [string trim [dict get $pdata build local_dir_root]]
            if {$provider_root ne ""} {
                incr errs [apply $check_dir "$provider/build/local_dir_root" $provider_root]
                if {$common_root ne "" && ![apply $under_root $provider_root $common_root]} {
                    putsci "CI VALIDATE ERROR: $provider/build/local_dir_root not under common/root ($provider_root)"
                    incr errs
                }
            }
        }

        if {[dict exists $pdata build build_dir]} {
            set build_dir [string trim [dict get $pdata build build_dir]]
            if {$build_dir ne ""} {
                incr errs [apply $check_dir "$provider/build/build_dir" $build_dir]
                if {$provider_root ne "" && ![apply $under_root $build_dir $provider_root]} {
                    putsci "CI VALIDATE ERROR: $provider/build/build_dir not under $provider/build/local_dir_root ($build_dir)"
                    incr errs
                }
            }
        }

        set install_dir ""
        if {[dict exists $pdata install install_dir]} {
            set install_dir [string trim [dict get $pdata install install_dir]]
            if {$install_dir ne ""} {
                incr errs [apply $check_dir "$provider/install/install_dir" $install_dir]
                if {$provider_root ne "" && ![apply $under_root $install_dir $provider_root]} {
                    putsci "CI VALIDATE ERROR: $provider/install/install_dir not under $provider/build/local_dir_root ($install_dir)"
                    incr errs
                }
            }
        }

        if {[dict exists $pdata install basedir]} {
            set basedir [string trim [dict get $pdata install basedir]]
            if {$basedir ne ""} {
                incr errs [apply $check_dir "$provider/install/basedir" $basedir]
                if {$provider_root ne "" && ![apply $under_root $basedir $provider_root]} {
                    putsci "CI VALIDATE ERROR: $provider/install/basedir not under $provider/build/local_dir_root ($basedir)"
                    incr errs
                }
            }
        }

        set config_dir ""
        if {[dict exists $pdata install config_dir]} {
            set config_dir [string trim [dict get $pdata install config_dir]]
            if {$config_dir ne ""} {
                incr errs [apply $check_dir "$provider/install/config_dir" $config_dir]
                if {$provider_root ne "" && ![apply $under_root $config_dir $provider_root]} {
                    putsci "CI VALIDATE ERROR: $provider/install/config_dir not under $provider/build/local_dir_root ($config_dir)"
                    incr errs
                }
            }
        }

        if {[dict exists $pdata install defaults_file]} {
            set path [string trim [dict get $pdata install defaults_file]]
            if {$path ne ""} {
                if {[file pathtype $path] ne "absolute"} {
                    set path [file join $pwd_here $path]
                }
                incr errs [apply $check_file "$provider/install/defaults_file" $path]
                if {$config_dir ne "" && ![apply $under_root $path $config_dir]} {
                    putsci "CI VALIDATE ERROR: $provider/install/defaults_file not under $provider/install/config_dir ($path)"
                    incr errs
                }
            }
        }

        if {[dict exists $pdata install io_config_file]} {
            set path [string trim [dict get $pdata install io_config_file]]
            if {$path ne ""} {
                if {[file pathtype $path] ne "absolute"} {
                    set path [file join $pwd_here $path]
                }
                incr errs [apply $check_file "$provider/install/io_config_file" $path]
                if {$config_dir ne "" && ![apply $under_root $path $config_dir]} {
                    putsci "CI VALIDATE ERROR: $provider/install/io_config_file not under $provider/install/config_dir ($path)"
                    incr errs
                }
            }
        }

        if {[dict exists $pdata test]} {
            set tdict [dict get $pdata test]
            dict for {tkey tval} $tdict {
                set path [string trim $tval]
                if {$path eq ""} {
                    continue
                }
                if {[file pathtype $path] ne "absolute"} {
                    set path [file join $pwd_here $path]
                }
                incr errs [apply $check_file "$provider/test/$tkey" $path]
            }
        }
    }

    if {$errs > 0} {
        putsci "CI VALIDATE: FAILED ($errs errors)"
        return 1
    }

    apply $say "CI VALIDATE: PASSED" $verbose
    return 0
}

proc cifix {} {
    global cidict

    putscli "Running cifix..."
    putsci "CI FIX: starting"

    if {![info exists cidict] || $cidict eq ""} {
        putsci "CI FIX ERROR: global cidict is empty"
        return 1
    }

    set cfg $cidict
    if {[dict exists $cfg ci]} {
        set cfg [dict get $cfg ci]
    }

    if {[catch {dict keys $cfg}]} {
        putsci "CI FIX ERROR: invalid cidict"
        return 1
    }

    if {[catch {exec curl --version}]} {
        putsci "CI FIX ERROR: curl not available"
        return 1
    }

    set dirs {}
    set files {}

    if {[dict exists $cfg common root]} {
        set p [string trim [dict get $cfg common root]]
        if {$p ne ""} { lappend dirs $p }
    }

    if {[dict exists $cfg common tmp]} {
        set p [string trim [dict get $cfg common tmp]]
        if {$p ne ""} { lappend dirs $p }
    }

    dict for {provider pdata} $cfg {
        if {$provider eq "common"} continue
        if {[catch {dict size $pdata}]} continue

        putsci "CI FIX: provider $provider"

        if {[dict exists $pdata build local_dir_root]} {
            set p [string trim [dict get $pdata build local_dir_root]]
            if {$p ne ""} { lappend dirs $p }
        }

        if {[dict exists $pdata build build_dir]} {
            set p [string trim [dict get $pdata build build_dir]]
            if {$p ne ""} { lappend dirs $p }
        }

        if {[dict exists $pdata install install_dir]} {
            set p [string trim [dict get $pdata install install_dir]]
            if {$p ne ""} { lappend dirs $p }
        }

        if {[dict exists $pdata install basedir]} {
            set p [string trim [dict get $pdata install basedir]]
            if {$p ne ""} { lappend dirs $p }
        }

        if {[dict exists $pdata install config_dir]} {
            set p [string trim [dict get $pdata install config_dir]]
            if {$p ne ""} { lappend dirs $p }
        }

        foreach key {defaults_file io_config_file} {
            if {[dict exists $pdata install $key]} {
                set p [string trim [dict get $pdata install $key]]
                if {$p ne ""} {
                    lappend files $p
                    lappend dirs [file dirname $p]
                }
            }
        }
    }

    set dirs  [lsort -unique $dirs]
    set files [lsort -unique $files]

    if {[llength $dirs] == 0 && [llength $files] == 0} {
        putsci "CI FIX ERROR: no fix targets found in CI configuration"
        return 1
    }

    foreach d $dirs {
        if {[file exists $d]} {
            if {![file isdirectory $d]} {
                putsci "CI FIX ERROR: path exists but is not a directory: $d"
                return 1
            }
            putsci "CI FIX: directory exists $d"
        } else {
            putsci "CI FIX: creating directory $d"
            if {[catch {file mkdir $d} err]} {
                putsci "CI FIX ERROR: failed to create directory $d : $err"
                return 1
            }
        }
    }

    if {[dict exists $cfg common root]} {
        set rootdir [string trim [dict get $cfg common root]]
        if {$rootdir ne ""} {
            if {![catch {exec df -Pk $rootdir} out]} {
                set lines [split [string trim $out] "\n"]
                if {[llength $lines] >= 2} {
                    set fields [regexp -inline -all {\S+} [lindex $lines end]]
                    if {[llength $fields] >= 4} {
                        set avail_kb [lindex $fields 3]
                        if {[string is integer -strict $avail_kb]} {
                            set gb [expr {$avail_kb / 1024 / 1024}]
                            if {$gb < 100} {
                                putsci "CI FIX WARNING: less than 100GB free under $rootdir (${gb}GB)"
                            }
                        }
                    }
                }
            }
        }
    }

    foreach f $files {
        if {[file exists $f]} {
            putsci "CI FIX: file exists $f"
            continue
        }

        set name [file tail $f]
        if {$name ni {"maria.cnf" "mariaio.cnf" "my.cnf" "myio.cnf" "postgresql.conf" "postgresqlio.conf"}} {
            putsci "CI FIX ERROR: no download rule for missing file $f"
            return 1
        }

        set base_url "https://www.hammerdb.com/ci-config"
        set file_url "$base_url/$name"
        set ts_url "$base_url/$name.timestamp"
        set sum_url "$base_url/$name.checksum"

        set ts_tmp  "${f}.timestamp.tmp"
        set sum_tmp "${f}.checksum.tmp"

        catch {file delete -force $ts_tmp $sum_tmp}

        putsci "CI FIX: fetching $name.timestamp"
        if {[catch {exec curl -L -s $ts_url -o $ts_tmp} err]} {
            putsci "CI FIX ERROR: failed to fetch $ts_url : $err"
            return 1
        }

        putsci "CI FIX: fetching $name.checksum"
        if {[catch {exec curl -L -s $sum_url -o $sum_tmp} err]} {
            putsci "CI FIX ERROR: failed to fetch $sum_url : $err"
            return 1
        }

        putsci "CI FIX: downloading $name"
        if {[catch {exec curl -L -s $file_url -o $f} err]} {
            catch {file delete -force $f}
            putsci "CI FIX ERROR: failed to download $file_url : $err"
            return 1
        }

        set fh [open $ts_tmp r]
        set remote_ts [string trim [read $fh]]
        close $fh

        set fh [open $sum_tmp r]
        set remote_sum_text [string trim [read $fh]]
        close $fh

        catch {file delete -force $ts_tmp $sum_tmp}

        if {![regexp {([0-9A-Fa-f]{64})} $remote_sum_text -> remote_sum]} {
            catch {file delete -force $f}
            putsci "CI FIX ERROR: invalid checksum content for $name"
            return 1
        }
        set remote_sum [string tolower $remote_sum]

        set local_sum ""
        if {![catch {exec sha256sum $f} out]} {
            set local_sum [string tolower [lindex [regexp -inline -all {\S+} [string trim $out]] 0]]
        } elseif {![catch {exec shasum -a 256 $f} out]} {
            set local_sum [string tolower [lindex [regexp -inline -all {\S+} [string trim $out]] 0]]
        } elseif {![catch {exec openssl dgst -sha256 $f} out]} {
            if {[regexp {=\s*([0-9A-Fa-f]+)} $out -> hex]} {
                set local_sum [string tolower $hex]
            }
        }

        if {$local_sum eq ""} {
            catch {file delete -force $f}
            putsci "CI FIX ERROR: unable to compute sha256 for $f"
            return 1
        }

        if {$local_sum ne $remote_sum} {
            catch {file delete -force $f}
            putsci "CI FIX ERROR: checksum mismatch for $name"
            return 1
        }

        set fh [open "${f}.timestamp" w]
        puts $fh $remote_ts
        close $fh

        set fh [open "${f}.checksum" w]
        puts $fh $remote_sum
        close $fh

        putsci "CI FIX: downloaded and verified $name"
    }

    putsci "CI FIX: validating"
    if {[ci_validate $cfg 1]} {
        putsci "CI FIX: FAILED"
        return
    }

    putsci "CI FIX: COMPLETE"
        exit
}

proc cilisten {args} {
    global cidict ci_optlog ci_flog ci_logfile
    set ci_optlog 1
    set ci_flog ""
    set ci_logfile ""

    if {[llength $args] != 0} {
        putscli "Usage: cilisten"
        return
    }

    if {[info exists ::listen_socket]} {
        putscli "CI listener already running; run cistop to stop"
        return
    }

    if {[catch {package require json}]} {
        error "Failed to load json package"
        return
    }

    if {![dict exists $cidict common listen_port]} {
        ci_init_config
    }
    if {![dict exists $cidict common listen_port]} {
        putscli "CI CONFIG: <common>/<listen_port> missing in CI config"
        return
    }

    if {[ci_validate $cidict]} {
        putsci "CI listener not started due to validation errors"
        return
    }

    putsci "CI validation passed"

    if {[dict exists $cidict common tmp]} {
        set tmpdir [string trim [dict get $cidict common tmp]]
        if {$tmpdir ne ""} {
            if {[file exists $tmpdir] && [file isdirectory $tmpdir]} {
                set ::env(TMP) $tmpdir
                putsci "CI TMP: $tmpdir"
            } else {
                putsci "CI WARNING: TMP directory not found: $tmpdir"
            }
        }
    }

    if {[catch {
        set ci_optlog [dict get $cidict common ci_log_to_temp]
    }]} {
        set ci_optlog 1
    }

    if {![string is integer -strict $ci_optlog] || $ci_optlog < 0 || $ci_optlog > 1} {
        set ci_optlog 1
    }

    set port [dict get $cidict common listen_port]

    proc handle_connection {sock addr port} {
        global cidict
        fconfigure $sock -translation crlf -buffering line -blocking 1
        fileevent $sock readable [list read_request $sock $cidict]
    }

    proc read_request {sock cidict} {
        variable headers
        variable body
        variable state
        variable content_length

        if {[eof $sock]} {
            close $sock
            return
        }

        if {![info exists state]} {
            set state headers
            set headers {}
            set body ""
            set content_length 0
        }

        if {$state eq "headers"} {
            while {[gets $sock line] >= 0} {
                if {$line eq ""} {
                    set state body
                    break
                }
                lappend headers $line
                if {[regexp -nocase {Content-Length:\s*(\d+)} $line -> cl]} {
                    set content_length $cl
                }
            }
        }

        if {$state eq "body"} {
            set body [read $sock $content_length]
            process_request $sock $headers $body $cidict
            unset state headers body content_length
        }
    }

    proc http_reply {sock code body} {
        if {[lsearch -exact [chan names] $sock] == -1} { return }
        puts $sock "HTTP/1.1 $code"
        puts $sock "Content-Type: text/plain"
        puts $sock "Content-Length: [string length $body]"
        puts $sock "Connection: close"
        puts $sock ""
        puts $sock $body
        flush $sock
        close $sock
    }

    proc process_request {sock headers body cidict} {
        global rdbms

        if {[catch {set json_data [json::json2dict $body]} err]} {
            putscli "Invalid JSON payload: $err"
            http_reply $sock "400 Bad Request" "Invalid JSON"
            return
        }

        if {![dict exists $json_data database]} {
            putscli "CI payload missing database"
            http_reply $sock "400 Bad Request" "Missing database"
            return
        }

        set dbprefix [string tolower [string trim [dict get $json_data database]]]
        if {$dbprefix eq ""} {
            putscli "CI payload database empty"
            http_reply $sock "400 Bad Request" "Empty database"
            return
        }

        upvar #0 dbdict dbdict
        set dbl {}
        set prefixl {}
        dict for {database attributes} $dbdict {
            dict with attributes {
                lappend dbl $name
                lappend prefixl $prefix
            }
        }

        set ind [lsearch -exact $prefixl $dbprefix]
        if {$ind eq -1} {
            putscli "Unknown prefix $dbprefix (valid: $prefixl)"
            http_reply $sock "400 Bad Request" "Unknown database prefix"
            return
        }

        set resolved_rdbms [lindex $dbl $ind]

        set enabled_dbs {}
        foreach k [dict keys $cidict] {
            if {$k eq "common"} continue
            lappend enabled_dbs $k
        }

        if {[lsearch -exact $enabled_dbs $resolved_rdbms] == -1} {
            putscli "$resolved_rdbms not enabled for CI"
            http_reply $sock "400 Bad Request" "Database not enabled"
            return
        }

        unset -nocomplain rdbms
        dbset db $dbprefix
        if {![info exists rdbms] || $rdbms eq ""} {
            putscli "Failed to dbset db $dbprefix"
            http_reply $sock "500 Internal Server Error" "Failed to set database context"
            return
        }

        set pipeline "single"
        if {[dict exists $json_data pipeline]} {
            set pipeline [string tolower [string trim [dict get $json_data pipeline]]]
        }

        set workload "C"
        if {[dict exists $json_data workload]} {
            set workload [string toupper [string trim [dict get $json_data workload]]]
        }

        set io_intensive 0
        if {[dict exists $json_data io_intensive]} {
            set io_intensive [dict get $json_data io_intensive]
        }
        if {$io_intensive ni {0 1 "0" "1"}} {
            set io_intensive 0
        }

        if {$pipeline eq "single"} {
            if {$workload eq "H"} {
                set pipeline "single_h"
            } else {
                set pipeline "single_c"
            }
        }

        if {![dict exists $json_data ref]} {
            putscli "CI payload missing ref"
            http_reply $sock "400 Bad Request" "Missing ref"
            return
        }

        set ref [dict get $json_data ref]

        set ref_regexp [string map {\" {}} [dict get $cidict $rdbms build ref_regexp]]
        set overwrite  [dict get $cidict $rdbms build overwrite]

        set matched 0
        if {[regexp [subst {$ref_regexp}] $ref -> type name]} {
            set matched 1
        } elseif {[regexp {^[0-9a-fA-F]{7,40}$} $ref]} {
            set type "sha"
            set name $ref
            set matched 1
        }

        if {!$matched} {
            putscli "Ref did not match CI rules: $ref"
            http_reply $sock "400 Bad Request" "Invalid ref"
            return
        }

        if {$overwrite} {
            catch {hdbjobs eval {DELETE FROM JOBCI WHERE refname=$name}}
        }

        if {[catch {
            hdbjobs eval {INSERT INTO JOBCI (refname,dbprefix,pipeline,io_intensive,cidict)
                          VALUES ($name,$dbprefix,$pipeline,$io_intensive,$cidict)}
        } err]} {
            putscli "Error inserting JOBCI row: $err"
            http_reply $sock "500 Internal Server Error" "Insert failed"
            return
        }

        putscli "Recorded: $name db=$dbprefix pipeline=$pipeline io_intensive=$io_intensive"

        if {[lsearch -exact [chan names] $sock] != -1} {
            puts $sock "HTTP/1.1 200 OK"
            puts $sock "Content-Type: text/plain"
            puts $sock "Content-Length: 2"
            puts $sock "Connection: close"
            puts $sock ""
            puts $sock "OK"
            flush $sock
            close $sock
        }
    }

    set listen_socket [socket -server handle_connection $port]
    ci_open_logfile

    putsci "CI listener: port $port"
    if {$ci_logfile ne ""} {
        putsci "CI log: $ci_logfile"
    }
    putsci "CI watcher: initializing"

    initwatcher $listen_socket
}

proc cistop {} {
    if {![info exists ::listen_socket]} {
        putscli "CI listener not running; run cilisten"
        return
    }
    putscli "Stopping CI webhook listener"
    ci_close_logfile
    if {[lsearch -exact [chan names] $::listen_socket] != -1} {
        catch {close $::listen_socket}
        unset -nocomplain ::listen_socket
        stopwatcher
    }
}

proc cistatus {} {
    if {![info exists ::listen_socket]} {
        putscli "CI listener not running"
    } else {
        putscli "CI listener running"
        if {$::watcher_running} {
            putscli "CI watcher running"
        } else {
            putscli "CI watcher not running"
        }
    }
}

proc ci_open_logfile {} {
    global ci_optlog
    global ci_flog
    global ci_logfile

    if {!$ci_optlog} {
        return
    }

    set tmpdir [findtempdir]
    if {$tmpdir eq "notmpdir"} {
        putscli "CI ERROR: No temporary directory found"
        return
    }

    set ci_logfile [file join $tmpdir hammerdbci.log]

    if {[catch {set ci_flog [open $ci_logfile w]} err]} {
        set ci_flog ""
        putscli "CI ERROR: Could not open logfile $ci_logfile : $err"
        return
    }

    if {[catch {fconfigure $ci_flog -buffering none} err]} {
        catch {close $ci_flog}
        set ci_flog ""
        putscli "CI ERROR: Could not disable buffering on $ci_logfile : $err"
        return
    }

    puts $ci_flog "HammerDB Pipeline Log"
    puts $ci_flog "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
}

proc ci_close_logfile {} {
    global ci_flog

    if {[info exists ci_flog] && $ci_flog ne ""} {
        catch {close $ci_flog}
        set ci_flog ""
    }
}

proc putsci {output} {
    global ci_flog

    puts $output
    catch {TclReadLine::print "\r"}

    if {[info exists ci_flog] && $ci_flog ne ""} {
        catch {
            puts $ci_flog $output
            flush $ci_flog
        }
    }
}

proc cipush {refname {pipeline single} {workload C} {dbprefix ""} {io_intensive 0}} {
    global rdbms cidict

    if {$dbprefix eq ""} {
        if {![info exists rdbms]} {
            putscli "Error: RDBMS not set (pass dbprefix or run: dbset db <prefix>)"
            return
        }
        set dbprefix [find_prefix $rdbms]
    }

    set dbprefix [string tolower [string trim $dbprefix]]
    if {$dbprefix eq ""} {
        putscli "Error: dbprefix empty"
        return
    }

    if {![info exists ::listen_socket]} {
        putscli "CI listener not running; starting listener"
        cilisten
    }

    if {![dict exists $cidict common listen_port]} {
        putscli "Error: CI config missing required keys"
        return
    }

    if {[string match "refs/tags/*" $refname]} {
        set ref_type "tag"
    } elseif {[string match "refs/heads/*" $refname]} {
        set ref_type "branch"
    } elseif {[regexp {^[0-9a-fA-F]{7,40}$} $refname]} {
        set ref_type "sha"
    } else {
        putscli "Error: refname must start with 'refs/tags/' or 'refs/heads/' or be a commit SHA"
        return
    }

    set pipeline [string tolower [string trim $pipeline]]
    if {$pipeline eq ""} { set pipeline "single" }

    set workload [string toupper [string trim $workload]]
    if {$workload ni {"C" "H"}} {
        putscli "Error: workload must be C or H"
        return
    }

    if {$io_intensive ni {0 1 "0" "1"}} {
        putscli "Error: io_intensive must be 0 or 1"
        return
    }

    set body "{\"ref\":\"$refname\",\"database\":\"$dbprefix\",\"pipeline\":\"$pipeline\",\"workload\":\"$workload\",\"io_intensive\":$io_intensive}"

    set headers [dict create X-GitHub-Event "create"]

    # dispatch
    process_request dummy_sock $headers $body $cidict

    putscli "Simulated webhook for $refname db=$dbprefix pipeline=$pipeline workload=$workload io_intensive=$io_intensive"
}

# line reader
proc handle_output {pipe} {
    if {[eof $pipe]} {
        fileevent $pipe readable {}
        putscli "command complete."
        set ::pipe_done 1
        return
    }

    if {[gets $pipe line] >= 0} {
        putscli $line
        if {[info exists ::pipe_output]} { append ::pipe_output "$line\n" }
    }
}

# test output reader
proc handle_test_output {pipe doneVar} {
    # EOF
    if {[eof $pipe]} {
        fileevent $pipe readable {}
        upvar #0 $doneVar done
        set done 1
        return
    }

    # line mode
    fconfigure $pipe -translation lf -buffering line -blocking 0

    # drain lines
    while {[gets $pipe line] >= 0} {
        putscli $line
    }
}

proc system_memory_mb {} {
    set mem_kb 0
    if {[catch {
        set f [open "/proc/meminfo" r]
        while {[gets $f line] >= 0} {
            if {[regexp {^MemTotal:\s+(\d+)\s+kB} $line -> kb]} {
                set mem_kb $kb
                break
            }
        }
        close $f
    }]} {
        return 0
    }
    return [expr {$mem_kb / 1024}]
}

proc calc_buffer_pool_mb {} {
    set mem_mb [system_memory_mb]
    if {$mem_mb <= 0} { return 0 }

    set bp_mb [expr {int($mem_mb / 2)}]

    if {$bp_mb < 1024}   { set bp_mb 1024 }
    if {$bp_mb > 262144} { set bp_mb 262144 }

    return $bp_mb
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

# watcher
proc job_watcher {} {
    if {$::watcher_running} {
        run_next_pending_job
        if {$::watcher_running} {
            catch { after 10000 job_watcher }
        }
    } else {
        set ::watcher_running 0
    }
}

proc stopwatcher {} {
    putscli "CI watcher stop."
    set ::watcher_running 0
    return
}

proc startwatcher {} {
    putscli "CI watcher started."
    set ::watcher_running 1
    job_watcher
    return
}

proc initwatcher {listen_socket} {
    set ::listen_socket $listen_socket
    startwatcher
    return
}

# next job
proc run_next_pending_job {} {
    global rdbms cidict

    set ci_id        ""
    set refname      ""
    set pipeline     ""
    set dbprefix     ""
    set io_intensive 0

    if {[catch {
        set ci_id [hdbjobs eval {
            SELECT ci_id
            FROM JOBCI
            WHERE status = 'PENDING'
            ORDER BY timestamp ASC
            LIMIT 1
        }]

        if {$ci_id ne ""} {
        set refname ""
        set pipeline ""
        set dbprefix ""
        set io_intensive 0

        hdbjobs eval {
            SELECT refname,pipeline,dbprefix,io_intensive
            FROM JOBCI
            WHERE ci_id = $ci_id
        } row {
            set refname      $row(refname)
            set pipeline     $row(pipeline)
            set dbprefix     $row(dbprefix)
            set io_intensive $row(io_intensive)
        }
        }
    } err]} {
        putsci "Error querying JOBCI: $err"
        return
    }

    if {$ci_id eq "" || $refname eq ""} {
        return
    }

    if {$dbprefix eq ""} {
        putsci "Job $ci_id missing dbprefix"
        return
    }

    if {$io_intensive ni {0 1 "0" "1"}} {
        set io_intensive 0
    }

    upvar #0 dbdict dbdict
    set dbl {}
    set prefixl {}
    dict for {database attributes} $dbdict {
        dict with attributes {
            lappend dbl $name
            lappend prefixl $prefix
        }
    }

    set ind [lsearch -exact $prefixl $dbprefix]
    if {$ind eq -1} {
        putsci "Job $ci_id has invalid dbprefix '$dbprefix'"
        return
    }

    unset -nocomplain rdbms
    dbset db $dbprefix

    if {![info exists rdbms] || $rdbms eq ""} {
        putsci "Failed to dbset db $dbprefix for job $ci_id"
        return
    }

    putsci "Found pending job: $refname (db=$dbprefix io_intensive=$io_intensive)"
    putsci "Pausing watcher for run"
    stopwatcher

    if {[catch {
        hdbjobs eval { UPDATE JOBCI SET status = 'BUILDING', timestamp = datetime(CURRENT_TIMESTAMP, 'localtime') WHERE ci_id = $ci_id }
    } err]} {
        putsci "Error updating status to BUILDING: $err"
        startwatcher
        return
    }

    switch -exact -- [string toupper $pipeline] {

        PROFILE {
            putsci "Dispatching pipeline='profile' for $refname"
            if {[catch {
                cisteps $cidict $refname profile $io_intensive
            } err]} {
                putsci "CI PROFILE pipeline failed: $err"
            }
            startwatcher
            return
        }

        COMPARE {
            putsci "Dispatching pipeline='compare' for $refname"
            if {[catch {
                cisteps $cidict $refname compare $io_intensive
            } err]} {
                putsci "CI COMPARE pipeline failed: $err"
            }
            startwatcher
            return
        }

        default {
            putsci "Dispatching pipeline='$pipeline' for $refname"
            if {[catch {
                cisteps $cidict $refname [string tolower $pipeline] $io_intensive
            } err]} {
                putsci "CI pipeline '$pipeline' failed: $err"
            }
            startwatcher
            return
        }
    }
}

# run pipeline
proc cisteps {cidict refname pipeline_name io_intensive} {
    global rdbms
    set r [string tolower $rdbms]

    if {![dict exists $cidict $rdbms pipeline $pipeline_name]} {
        putsci "CI: unknown pipeline '$pipeline_name' under <$rdbms>/<pipeline>"
        return
    }

    set steps     [dict get $cidict $rdbms pipeline $pipeline_name]
    set step_list [split $steps " "]

    putsci "CI: running pipeline '$pipeline_name' io_intensive=$io_intensive → $steps"

    foreach step $step_list {
        if {$step eq ""} continue
        switch -glob -- $step {
            clone {
                set cmd "${r}_clone"
                set st [$cmd $cidict $refname]
                putsci $st
                if {$st eq "CLONE FAILED"} { return }
            }
            build {
                set cmd "${r}_build"
                set st [$cmd $cidict $refname]
                putsci $st
                if {$st eq "BUILD FAILED"} { return }
            }
            package {
                set cmd "${r}_package"
                set st [$cmd $cidict $refname]
                putsci $st
                if {$st eq "PACKAGE FAILED"} { return }
            }
            commit_msg {
                set cmd "${r}_commit_msg"
                putsci [$cmd $cidict $refname]
            }
            install {
                set cmd "${r}_install"
                set st [$cmd $cidict $refname]
                putsci $st
                if {$st eq "INSTALL FAILED"} { return }
            }
            init {
                set cmd "${r}_init"
                set st [$cmd $cidict $refname]
                putsci $st
                if {$st eq "INIT FAILED"} { return }
            }
            start {
                set cmd "${r}_start"
                set st [$cmd $cidict $refname]
                putsci $st
                if {$st eq "START FAILED"} { return }
            }
            ping {
                set cmd "${r}_ping"
                set st [$cmd $cidict $refname]
                putsci $st
                if {$st eq "PING FAILED"} { return }
            }
            run_sql:* {
                set arg [lindex [split $step ":"] 1]
                if {$arg eq ""} { putsci "CI: run_sql missing argument"; return }
                set cmd "${r}_run_sql"
                set st [$cmd $cidict $refname $arg]
                putsci $st
                if {$st eq "[string toupper $arg] FAILED"} { return }
            }
            start_tests:* {
                set workload [lindex [split $step ":"] 1]
                if {$workload eq ""} { putsci "CI: start_tests missing workload"; return }
                set cmd "${r}_start_tests"
                set st  [$cmd $cidict $refname $workload]
                putsci $st
                if {$st eq "TEST FAILED"} { return }
            }
            profile {
                set cmd "[string tolower $rdbms]_profile"
                set st  [$cmd $cidict $refname]
                putsci $st
                if {$st eq "PROFILE FAILED"} { return }
            }
            compare {
                set cmd "[string tolower $rdbms]_compare"
                set st  [$cmd $cidict $refname]
                putsci $st
                if {$st eq "COMPARE FAILED"} { return }
            }
            default {
                putsci "CI: unknown step token '$step' — skipping"
            }
        }
    }

    putsci "CI: pipeline '$pipeline_name' completed"
}

# Unix only at this release
if {![info exists ::tcl_platform(platform)] || $::tcl_platform(platform) ne "unix"} {
    foreach p {citmp cilisten cistop cistatus cipush cistep ciset} {
        if {[info procs $p] ne ""} {
            if {[info procs _$p] eq ""} {
                rename $p _$p
            }
            proc $p {args} {
                putscli "CI WARNING: CI commands are only supported on Linux/Unix platforms in this release."
            }
        }
    }
}
