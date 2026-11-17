# Public ASH controls shared by Tcl CLI, Python (via tclpy) and Desktop GUI.
# The collector is the one used by Pipelines; this file does not start a
# second sampler or alter the existing Desktop Metrics implementation.
namespace eval ::ashcmd {
    variable jobid ""
    variable lastjob ""
    variable starting 0
}

proc ::ashcmd::manual_active {} {
    variable jobid
    if {$jobid eq "" || ![llength [info commands ::ashcapture::active]]} {return 0}
    return [::ashcapture::active]
}

proc ::ashcmd::current_job {} {
    variable jobid
    return $jobid
}

proc ashstart {args} {
    if {[llength $args] > 1} {error {Usage: ashstart ?existing_jobid?}}
    if {$::ashcmd::starting} {error "ASH is already starting"}
    package require ashcapture 1.0
    if {[::ashcapture::active]} {
        error "ASH collection is already running; call ashstatus or ashstop"
    }
    if {[job_disable_check]} {
        error "ASH needs Jobs storage enabled"
    }
    # Browsing an archive in hammerdbws requires the same on-disk Jobs SQLite
    # file. Reject :memory: rather than silently losing all captured samples.
    # CLI starts on Oracle by default. Validate the current selection before
    # opening the collector so manual ASH gives an actionable error instead of
    # a generic stack trace from ::ashcapture::configuration.
    if {![info exists ::rdbms] || $::rdbms ni {PostgreSQL MySQL MariaDB VillageSQL}} {
        set selected "(none)"
        if {[info exists ::rdbms]} {set selected $::rdbms}
        error "ASH cannot start for database '$selected'. Select PostgreSQL (dbset db pg), MySQL (dbset db mysql), MariaDB (dbset db maria), or VillageSQL (dbset db vsql) first."
    }
    ::ashcapture::database_path
    ::ashcapture::configuration
    set ::ashcmd::starting 1
    try {
        if {[llength $args]} {
            set chosen [lindex $args 0]
            if {![regexp {^[A-Za-z0-9_-]{1,96}$} $chosen]} {
                error "Invalid ASH Job ID"
            }
            set existing [hdbjobs onecolumn {SELECT count(*) FROM JOBMAIN WHERE jobid=$chosen}]
            if {$existing != 1} {error "The specified Job ID does not exist"}
            set jobdb [hdbjobs onecolumn {SELECT db FROM JOBMAIN WHERE jobid=$chosen}]
            set jobbm [hdbjobs onecolumn {SELECT bm FROM JOBMAIN WHERE jobid=$chosen}]
            if {$jobdb ne $::rdbms || $jobbm ne $::bm} {
                error "The selected Job belongs to a different database or benchmark"
            }
        } elseif {[info exists ::inrun] && [info exists ::jobid] &&
                  [hdbjobs onecolumn {SELECT count(*) FROM JOBMAIN WHERE jobid=$::jobid}] == 1} {
            # Desktop Run has already registered its Job. Start capture for it
            # instead of creating a second unassociated Job.
            set chosen $::jobid
        } else {
            set chosen [guid]
            if {[jobmain $chosen run] != 0} {
                error "Unable to register a persistent ASH Job"
            }
        }
        # A newly initialized Jobs database has JOBMAIN but may not have
        # JOBASHINFO until the collector initializes its on-disk archive.
        # Probe sqlite_master first: otherwise the first manual ashstart
        # always raises "no such table: JOBASHINFO".
        if {[hdbjobs onecolumn {
            SELECT count(*) FROM sqlite_master
            WHERE type='table' AND name='JOBASHINFO'
        }] && [hdbjobs onecolumn {
            SELECT count(*) FROM JOBASHINFO WHERE jobid=$chosen
        }]} {
            error "ASH already has an archive for Job $chosen"
        }
        set ::ashcmd::lastjob $chosen
        ::ashcapture::start $chosen 1
        set ::ashcmd::jobid $chosen
        return "ASH running: Job $chosen. Open Jobs > $chosen > ASH in the Web Service."
    } finally {
        set ::ashcmd::starting 0
    }
}

proc ashstop {args} {
    if {[llength $args]} {error {Usage: ashstop}}
    if {$::ashcmd::starting} {error "ASH is still starting"}
    if {![::ashcmd::manual_active]} {
        if {[llength [info commands ::ashcapture::active]] && [::ashcapture::active]} {
            error "ASH was started by a benchmark and stops automatically with that run"
        }
        error "No manually started ASH capture is running"
    }
    set chosen $::ashcmd::jobid
    try {
        ::ashcapture::stop complete
    } finally {
        set ::ashcmd::jobid ""
    }
    return [ashstatus $chosen]
}

proc ashstatus {args} {
    if {[llength $args] > 1} {error {Usage: ashstatus ?jobid?}}
    if {$::ashcmd::starting} {return "ASH starting"}
    if {[llength $args]} {
        set chosen [lindex $args 0]
    } elseif {$::ashcmd::jobid ne ""} {
        set chosen $::ashcmd::jobid
    } elseif {[llength [info commands ::ashcapture::active]] && [::ashcapture::active]} {
        # Automatic Pipeline capture is active in this interpreter. Do not
        # accidentally report a previous manual ASH Job from lastjob.
        if {[info exists ::jobid] && $::jobid ne ""} {
            set chosen $::jobid
        } else {
            return "ASH running under automatic benchmark control"
        }
    } else {
        set chosen $::ashcmd::lastjob
    }
    if {$chosen eq ""} {
        if {[llength [info commands ::ashcapture::active]] && [::ashcapture::active]} {
            return "ASH running under automatic benchmark control"
        }
        return "ASH is not running"
    }
    if {![regexp {^[A-Za-z0-9_-]{1,96}$} $chosen]} {error "Invalid ASH Job ID"}
    if {[catch {set row [hdbjobs eval {
        SELECT state,error FROM JOBASHINFO WHERE jobid=$chosen
    }]}]} {return "ASH status unavailable for Job $chosen"}
    if {[llength $row] < 1} {return "No ASH archive found for Job $chosen"}
    set state [lindex $row 0]
    set failure [lindex $row 1]
    set samples [hdbjobs onecolumn {
        SELECT count(*) FROM JOBASH WHERE jobid=$chosen AND source='samples'
    }]
    set message "ASH $state: Job $chosen, $samples captured samples"
    if {$failure ne ""} {append message ", error: $failure"}
    return $message
}

