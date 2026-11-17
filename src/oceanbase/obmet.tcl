# Desktop presentation for OceanBase's native ASH connection.
if {[catch {package require oceanbaseash}]} {
    source [file join [file dirname [info script]] .. .. modules oceanbaseash-1.0.tm]
}
namespace eval obmet {
    namespace export obmetrics ob_post_kill_dbmon_cleanup
    variable panel {}
    variable generation 0
    variable state
    variable bucketSeconds 15
    variable historySeconds 7200
    variable colors {
        CPU #328552 User_IO #3876ad System_IO #43a6bf Concurrency #dd7458
        Application #8864ab Configuration #9d8257 Commit #cf9638
        Network #407c7c Scheduler #bd628a Cluster #6875b2 Other #8992a1
    }

    proc active {} {
        variable panel
        return [expr {$panel ne ""}]
    }

    proc obmetrics {} {
        variable panel
        variable generation
        variable state
        if {[active]} {return}

        set panel .ed_mainFrame.me.obash
        set revision [incr generation]
        array set state {
            timer {} followsLatest 1 selection {} dragStart {}
            selectedSQL {} overviewRange {} overviewData {} sqlRange {} sqlData {}
        }
        ttk::frame $panel -padding 8
        bind $panel <Destroy> [list ::obmet::panel_destroyed $revision %W]
        pack $panel -fill both -expand 1

        ttk::frame $panel.header
        ttk::label $panel.header.status -text "Connecting to OceanBase ASH..."
        ttk::label $panel.header.range -text {}
        ttk::button $panel.header.latest -text "Latest bucket" -command ::obmet::select_latest
        pack $panel.header.status $panel.header.range -side left -padx {0 12}
        pack $panel.header.latest -side right
        pack $panel.header -fill x -pady {0 6}

        set state(background) [ttk::style lookup TFrame -background]
        set state(foreground) [ttk::style lookup TLabel -foreground]
        if {$state(background) eq ""} {set state(background) white}
        if {$state(foreground) eq ""} {set state(foreground) black}
        set state(overviewCanvas) $panel.timeline
        make_chart $state(overviewCanvas) overview 180
        $state(overviewCanvas) configure -cursor crosshair
        pack $state(overviewCanvas) -fill x
        bind $state(overviewCanvas) <ButtonPress-1> {::obmet::begin_drag %x}
        bind $state(overviewCanvas) <B1-Motion> {::obmet::show_drag %x}
        bind $state(overviewCanvas) <ButtonRelease-1> {::obmet::end_drag %x}
        make_legend $panel.legend
        pack $panel.legend -fill x -pady {0 8}

        ttk::panedwindow $panel.panes -orient horizontal
        ttk::notebook $panel.panes.tables
        make_table $panel.panes.tables.sql sql "Top SQL" {id weight} {{SQL ID} {Sample weight}} {244 100}
        make_table $panel.panes.tables.sessions sessions "Sessions" {id account weight} \
            {{Session} {Account} {Sample weight}} {165 125 100}
        make_table $panel.panes.tables.waits waits "Wait events" {event category weight} \
            {{Event} {Wait group} {Sample weight}} {175 110 100}
        $panel.panes add $panel.panes.tables -weight 1

        set details $panel.panes.details
        ttk::frame $details
        ttk::label $details.title -text "Selected SQL activity"
        set state(sqlCanvas) $details.timeline
        make_chart $state(sqlCanvas) sql 110
        pack $details.title -anchor w
        pack $state(sqlCanvas) -fill x
        ttk::frame $details.buttons
        foreach {cursor caption} {ash_sqltxt {SQL text} ash_sqlstats {Cached stats} ash_sqlplan {Cached plan} sqlio {I/O waits}} {
            ttk::button $details.buttons.$cursor -text $caption -command [list ::obmet::show_detail $cursor]
            pack $details.buttons.$cursor -side left -padx {0 4}
        }
        pack $details.buttons -fill x -pady {4 6}

        ttk::frame $details.output
        set state(output) $details.output.text
        text $state(output) -height 7 -width 35 -wrap word -state disabled -font TkFixedFont \
            -background $state(background) -foreground $state(foreground) \
            -yscrollcommand [list $details.output.scroll set]
        ttk::scrollbar $details.output.scroll -command [list $state(output) yview]
        pack $details.output.scroll -side right -fill y
        pack $state(output) -side left -fill both -expand 1
        pack $details.output -fill both -expand 1
        $panel.panes add $details -weight 1
        pack $panel.panes -fill both -expand 1

        ::ed_stop_metrics
        .ed_mainFrame.notebook tab .ed_mainFrame.me -state normal
        .ed_mainFrame.notebook select .ed_mainFrame.me
        ::oceanbaseash::start $::configoceanbase $::bm [list ::obmet::receive $revision]
    }

    proc panel_destroyed {revision widget} {
        variable generation
        variable panel
        if {$revision == $generation && $widget eq $panel} {
            ob_post_kill_dbmon_cleanup
        }
    }

    proc ob_post_kill_dbmon_cleanup {} {
        variable panel
        variable generation
        variable state
        if {![active]} {return}
        set oldPanel $panel
        set panel {}
        incr generation
        if {$state(timer) ne ""} {after cancel $state(timer)}
        try {
            ::oceanbaseash::stop
        } finally {
            array unset state
            if {[winfo exists $oldPanel]} {destroy $oldPanel}
        }
    }

    proc make_table {frame kind title columns headings widths} {
        variable state
        ttk::frame $frame
        set tree $frame.list
        ttk::treeview $tree -columns $columns -show headings -selectmode browse -height 9 \
            -yscrollcommand [list $frame.scroll set]
        foreach column $columns heading $headings width $widths {
            $tree heading $column -text $heading
            $tree column $column -width $width -minwidth [expr {min($width, 72)}]
        }
        ttk::scrollbar $frame.scroll -command [list $tree yview]
        pack $frame.scroll -side right -fill y
        pack $tree -side left -fill both -expand 1
        [winfo parent $frame] add $frame -text $title
        bind $tree <<TreeviewSelect>> [list ::obmet::table_selected $kind]
        set state(tree,$kind) $tree
        set state(rows,$kind) {}
    }

    proc make_chart {chart kind height} {
        variable state
        canvas $chart -height $height -background $state(background) -highlightthickness 0 -borderwidth 0
        bind $chart <Configure> [list ::obmet::draw_chart $kind]
    }

    proc make_legend {legend} {
        variable colors
        ttk::frame $legend
        set index 0
        dict for {group color} $colors {
            set item $legend.item$index
            ttk::frame $item
            canvas $item.color -width 10 -height 10 -background $color -highlightthickness 0
            ttk::label $item.label -text [string map {_ { }} $group]
            pack $item.color $item.label -side left -padx {0 4}
            grid $item -row [expr {$index / 6}] -column [expr {$index % 6}] -sticky w -padx {0 8}
            incr index
        }
    }

    proc send {slot cursor params} {
        variable state
        unset -nocomplain state(request,$slot)
        set id [::oceanbaseash::request $cursor [dict replace $params tag $slot]]
        if {$id ne ""} {set state(request,$slot) $id}
    }

    proc receive {revision status args} {
        variable generation
        variable state
        variable panel
        if {$revision != $generation || ![active]} {return}
        if {$status eq "connected"} {
            $panel.header.status configure -text "OceanBase ASH"
            poll
            return
        }
        lassign $args cursor request payload rows
        if {$status eq "error" && $cursor eq "connect"} {
            $panel.header.status configure -text "OceanBase ASH unavailable"
            display_text $payload
            return
        }
        set slot [dict get $request tag]
        if {![info exists state(request,$slot)] || [dict get $request id] ne $state(request,$slot)} {return}
        unset state(request,$slot)
        if {$slot eq "timeline"} {
            set state(timer) [after 15000 [list ::obmet::poll]]
        }
        if {$status eq "error"} {
            if {$slot in {detail sqlchart}} {
                if {$slot eq "detail"} {
                    display_text $payload
                } else {
                    $panel.panes.details.title configure -text "Selected SQL activity unavailable"
                }
            } else {
                $panel.header.status configure -text "ASH query failed"
                if {$slot eq "sql" || ($slot eq "timeline" && $state(overviewRange) eq "")} {
                    display_text $payload
                }
            }
            return
        }
        switch -- $slot {
            timeline {
                $panel.header.status configure -text "OceanBase ASH"
                update_timeline $request $rows
            }
            sql {
                populate_table sql [::oceanbaseash::activity_rows sql $rows]
                set tree $state(tree,sql)
                set items [$tree children {}]
                set item [lindex $items 0]
                foreach candidate $items {
                    if {[lindex [dict get $state(rows,sql) $candidate] 0] eq $state(previousSQL)} {
                        set item $candidate
                        break
                    }
                }
                if {$item ne ""} {
                    $tree selection set $item
                    $tree see $item
                    select_sql [lindex [dict get $state(rows,sql) $item] 0]
                } else {
                    select_sql {}
                }
            }
            sessions {populate_table sessions [::oceanbaseash::activity_rows session $rows]}
            waits {populate_table waits $rows}
            detail {display_text [detail_text $cursor $request $payload $rows]}
            sqlchart {
                $panel.panes.details.title configure -text "Selected SQL activity"
                set state(sqlRange) [list [dict get $request begin] [dict get $request end]]
                set state(sqlData) [chart_data $rows]
                draw_chart sql
            }
        }
    }

    proc poll {} {
        variable state
        if {![active]} {return}
        set state(timer) {}
        set begin [expr {$state(overviewRange) eq {} ? 0 : [lindex $state(overviewRange) 1]}]
        send timeline ash [dict create begin $begin]
    }

    proc chart_data {rows} {
        set data {}
        foreach row $rows {
            lassign $row timestamp sessionState waitClass weight
            if {$weight eq ""} {continue}
            set group [::oceanbaseash::group $sessionState $waitClass]
            set previous [expr {[dict exists $data $timestamp $group] ? [dict get $data $timestamp $group] : 0}]
            dict set data $timestamp $group [expr {$previous + double($weight)}]
        }
        return $data
    }

    proc update_timeline {request rows} {
        variable state
        variable historySeconds
        set begin [dict get $request begin]
        set end [dict get $request end]
        if {$begin >= $end} {return}
        set data $state(overviewData)
        if {$state(overviewRange) ne ""} {
            lassign $state(overviewRange) priorBegin priorEnd
            # A server clock adjustment can invalidate the previous window.
            if {$end < $priorEnd} {
                set data {}
            } else {
                set begin [expr {max($priorBegin, $end - $historySeconds)}]
            }
        }
        set data [dict merge $data [chart_data $rows]]
        foreach timestamp [dict keys $data] {
            if {$timestamp < $begin || $timestamp >= $end} {dict unset data $timestamp}
        }
        set state(overviewRange) [list $begin $end]
        set state(overviewData) $data
        draw_chart overview
        if {$state(followsLatest)} {select_latest}
    }

    proc select_latest {} {
        variable state
        variable bucketSeconds
        if {$state(overviewRange) eq ""} {return}
        lassign $state(overviewRange) begin end
        set state(followsLatest) 1
        select_range [expr {max($begin, $end - $bucketSeconds)}] $end
    }

    proc select_range {begin end} {
        variable state
        variable panel
        set range [list $begin $end]
        if {$range eq $state(selection)} {return}
        set state(selection) $range
        set state(previousSQL) $state(selectedSQL)
        set state(selectedSQL) {}
        foreach slot {sql sessions waits sqlchart detail} {
            unset -nocomplain state(request,$slot)
        }
        foreach kind {sql sessions waits} {populate_table $kind {}}
        set state(sqlRange) {}
        set state(sqlData) {}
        draw_chart overview
        draw_chart sql
        $panel.header.range configure -text "[time_label $begin] to [time_label $end] UTC"
        display_text "Loading selected interval..."
        send sql ash_sqldetails [selection_params]
    }

    proc selection_params {} {
        variable state
        lassign $state(selection) begin end
        return [dict create begin $begin end $end selected $state(selectedSQL)]
    }

    proc select_sql {id} {
        variable state
        variable panel
        set state(selectedSQL) $id
        foreach slot {sessions waits detail sqlchart} {unset -nocomplain state(request,$slot)}
        foreach kind {sessions waits} {populate_table $kind {}}
        set state(sqlRange) {}
        set state(sqlData) {}
        $panel.panes.details.title configure -text "Selected SQL activity"
        draw_chart sql
        set params [selection_params]
        send sessions ash_sqlsessions $params
        send waits ash_sqlevents $params
        if {$id eq ""} {
            display_text "No SQL ID was sampled in this interval."
        } else {
            lassign $state(overviewRange) begin end
            send sqlchart sqlovertime [dict create begin $begin end $end selected $id]
            show_detail ash_sqltxt
        }
    }

    proc populate_table {kind rows} {
        variable state
        set tree $state(tree,$kind)
        $tree delete [$tree children {}]
        set state(rows,$kind) {}
        foreach row $rows {
            switch -- $kind {
                sql {set values [list [lindex $row 0] [format %.4g [lindex $row 1]]]}
                sessions {set values [list [lindex $row 3] [lindex $row 0] [format %.4g [lindex $row 1]]]}
                waits {
                    lassign $row event sessionState waitClass weight
                    set values [list $event [::oceanbaseash::group $sessionState $waitClass] [format %.4g $weight]]
                }
            }
            set item [$tree insert {} end -values $values]
            dict set state(rows,$kind) $item $row
        }
    }

    proc table_selected {kind} {
        variable state
        set item [lindex [$state(tree,$kind) selection] 0]
        if {![dict exists $state(rows,$kind) $item]} {return}
        set row [dict get $state(rows,$kind) $item]
        switch -- $kind {
            sql {
                set id [lindex $row 0]
                if {$id ne $state(selectedSQL)} {select_sql $id}
            }
            sessions {
                unset -nocomplain state(request,detail)
                set text "Session [lindex $row 3]\nASH sample weights in selected interval:\n"
                foreach group [::oceanbaseash::groups] weight [lrange $row 4 end] {
                    append text "$group: $weight\n"
                }
                display_text $text
            }
            waits {
                set event [lindex $row 0]
                display_text "Loading SQL IDs for $event..."
                send detail ash_eventsqls [dict replace [selection_params] event $event]
            }
        }
    }

    proc show_detail {cursor} {
        variable state
        unset -nocomplain state(request,detail)
        if {$cursor eq "sqlio"} {
            display_text "Loading I/O waits..."
            send detail $cursor {}
        } elseif {$state(selectedSQL) eq ""} {
            display_text "Select a SQL ID first."
        } else {
            display_text "Loading $state(selectedSQL)..."
            send detail $cursor [selection_params]
        }
    }

    proc detail_text {cursor request names rows} {
        switch -- $cursor {
            ash_sqltxt - ash_sqlstats - ash_sqlplan {
                if {![llength $rows]} {return "This SQL is no longer present in the tenant plan cache."}
                if {$cursor eq "ash_sqltxt"} {return [lindex $rows 0 0]}
                set text {}
                if {$cursor eq "ash_sqlstats"} {
                    append text "Plan-cache lifetime totals. Time columns are in microseconds.\n\n"
                }
                foreach row $rows {
                    foreach name $names value $row {append text "$name: $value\n"}
                    append text "\n"
                }
            }
            sqlio {
                set text "I/O ASH sample weights in the last two hours:\n"
                foreach row $rows {
                    lassign $row event sessionState waitClass weight
                    append text "$event ($waitClass): $weight\n"
                }
            }
            ash_eventsqls {
                set text "SQL IDs sampled for [dict get $request event]:\n"
                foreach row $rows {append text "[lindex $row 0]: [lindex $row 1] sample weight\n"}
            }
        }
        return $text
    }

    proc display_text {value} {
        variable state
        set widget $state(output)
        $widget configure -state normal
        $widget delete 1.0 end
        $widget insert end $value
        $widget configure -state disabled
    }

    proc time_label {timestamp} {
        clock format $timestamp -format {%H:%M:%S} -gmt 1
    }

    proc chart_bounds {canvas} {
        list 50 8 [expr {max(51, [winfo width $canvas] - 12)}] \
            [expr {max(9, [winfo height $canvas] - 25)}]
    }

    proc chart_x {timestamp begin end left right} {
        expr {$left + ($right - $left) * double($timestamp - $begin) / ($end - $begin)}
    }

    proc draw_chart {kind} {
        variable state
        variable bucketSeconds
        variable colors
        if {![active]} {return}
        set canvas $state(${kind}Canvas)
        $canvas delete all
        lassign $state(${kind}Range) begin end
        if {$begin eq "" || $begin >= $end} {
            set text [expr {$kind eq "overview" ? "Waiting for a completed 15-second bucket" : "Select a SQL ID to plot its activity"}]
            $canvas create text [expr {[winfo width $canvas] / 2}] [expr {[winfo height $canvas] / 2}] \
                -text $text -fill $state(foreground)
            return
        }
        lassign [chart_bounds $canvas] left top right bottom
        set limit 1.0
        set data $state(${kind}Data)
        dict for {timestamp groups} $data {
            set total 0.0
            foreach weight [dict values $groups] {set total [expr {$total + $weight}]}
            set limit [expr {max($limit, $total / $bucketSeconds)}]
        }
        foreach fraction {0 0.5 1} {
            set y [expr {$bottom - ($bottom - $top) * $fraction}]
            $canvas create line $left $y $right $y -fill #8992a1 -dash {2 4}
            $canvas create text [expr {$left - 5}] $y -anchor e -fill $state(foreground) \
                -text [format %.3g [expr {$limit * $fraction}]]
        }
        $canvas create text 2 $top -text AAS -anchor nw -fill $state(foreground)
        dict for {timestamp groups} $data {
            set x1 [chart_x $timestamp $begin $end $left $right]
            set x2 [chart_x [expr {min($timestamp + $bucketSeconds, $end)}] $begin $end $left $right]
            set y1 $bottom
            dict for {group color} $colors {
                if {![dict exists $groups $group]} {continue}
                set value [dict get $groups $group]
                if {$value <= 0} {continue}
                set y2 [expr {$y1 - ($bottom - $top) * $value / ($bucketSeconds * $limit)}]
                $canvas create rectangle $x1 $y2 $x2 $y1 -outline {} -fill $color
                set y1 $y2
            }
        }
        $canvas create text $left [expr {$bottom + 4}] -anchor nw -fill $state(foreground) -text [time_label $begin]
        $canvas create text $right [expr {$bottom + 4}] -anchor ne -fill $state(foreground) -text "[time_label $end] UTC"
        if {$kind eq "overview" && $state(selection) ne ""} {
            lassign $state(selection) rangeBegin rangeEnd
            mark_range selected $rangeBegin $rangeEnd
        }
    }

    proc time_at {x} {
        variable state
        lassign $state(overviewRange) begin end
        lassign [chart_bounds $state(overviewCanvas)] left top right bottom
        expr {$begin + ($end - $begin) * max(0.0, min(1.0, double($x - $left) / ($right - $left)))}
    }

    proc mark_range {tag first last} {
        variable state
        set canvas $state(overviewCanvas)
        $canvas delete $tag
        lassign $state(overviewRange) begin end
        lassign [chart_bounds $canvas] left top right bottom
        set first [expr {max($first, $begin)}]
        set last [expr {min($last, $end)}]
        if {$first > $last} {return}
        set x1 [chart_x $first $begin $end $left $right]
        set x2 [chart_x $last $begin $end $left $right]
        $canvas create rectangle $x1 $top [expr {max($x1 + 1, $x2)}] $bottom -outline #6827a0 -width 2 -tags $tag
    }

    proc begin_drag {x} {
        variable state
        if {$state(overviewRange) ne ""} {set state(dragStart) [time_at $x]}
    }

    proc show_drag {x} {
        variable state
        if {$state(dragStart) eq ""} {return}
        set current [time_at $x]
        mark_range dragging [expr {min($state(dragStart), $current)}] [expr {max($state(dragStart), $current)}]
    }

    proc end_drag {x} {
        variable state
        variable bucketSeconds
        if {$state(dragStart) eq ""} {return}
        set first $state(dragStart)
        set state(dragStart) {}
        $state(overviewCanvas) delete dragging
        set last [time_at $x]
        lassign $state(overviewRange) begin end
        set left [expr {wide(floor(min($first, $last) / $bucketSeconds)) * $bucketSeconds}]
        set right [expr {wide(ceil(max($first, $last) / $bucketSeconds)) * $bucketSeconds}]
        set left [expr {max($begin, min($left, $end - $bucketSeconds))}]
        set right [expr {min($end, max($right, $left + $bucketSeconds))}]
        set state(followsLatest) 0
        select_range $left $right
    }
}
