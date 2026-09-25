namespace eval mysqlmet {
    namespace export create_metrics_screen display_tile display_only colors1 colors2 colors getcolor geteventcolor getlcolor generic_time cur_time secs_fetch days_fetch ash_init reset_ticks ashempty_fetch ashtime_fetch ses_tbl sql_tbl emptyStr stat_tbl plan_tbl evt_tbl createSesFrame createSqlFrame createevtFrame create_ash_cpu_line ash_bars ash_displayx ash_fetch ash_details ash_sqldetails_fetch ash_sqlsessions_fetch ash_sqltxt ashrpt_fetch ash_sqltxt_fetch ash_sqlstats_fetch ash_sqlplan_fetch ash_eventsqls_fetch ash_sqlevents_fetch sqlovertime_fetch sqlovertime ashsetup vectorsetup addtabs graphsetup outputsetup waitbuttons_setup sqlbuttons_setup cbc_fetch sqlio_fetch wait_analysis connect_to_mysql putsm mysql_dbmon_thread_init just_disconnect mysql_logon mysql_logoff ConnectToMySQL mysql_sql mysql_all callback_connect callback_set callback_fetch callback_err callback_mesg test_connect_mysql lock unlock cpucount_fetch mysql_HowManyProcessorsWindows mysql_HowManyProcessorsLinux get_cpucount version_fetch mon_init mon_loop mon_execute set_mysql_waits set_mysql_events get_event_type get_event_desc set_mysqlcursors init_publics mysql_post_kill_dbmon_cleanup mysqlmetrics

    variable firstconnect "true"

    proc create_metrics_screen { } {
        global public metframe win_scale_fact defaultBackground
        upvar #0 env e
        set metframe .ed_mainFrame.me
        if { [ info exists hostname ] } { ; } else { set hostname "localhost" }
        if { [ info exists id ] } { ; } else { set id 0 }
        ed_stop_metrics
        .ed_mainFrame.notebook tab .ed_mainFrame.me -state normal
        .ed_mainFrame.notebook select .ed_mainFrame.me
        set main $public(main)
        set menu_frame $main.menu
        set public(menu_frame) $menu_frame
        set public(p_x) [ expr {round((600/1.333333)*$win_scale_fact)} ]
        set public(p_y) [ expr {round((654/1.333333)*$win_scale_fact)} ]
        if { ![winfo exists .ed_mainFrame.me.m] } {
            frame $main -background $defaultBackground -borderwidth 0
            frame $main.f -background $public(bg) -borderwidth 0 ;# frame, use frame to put tiled windows
            pack $main                            -expand true -fill both
            pack [ ttk::sizegrip $main.grip ]     -side bottom -anchor se
            pack $main.f                          -expand true -fill both
        }
        update idletasks
    }

    proc display_tile { {name "" } {proc  "" }    } {
        global public
        set cur_proc display_tile ;
        if { [ catch {
                display_only $name $proc
                if { $name != "" } {
                    set public(visible) $proc
                }
        } err ] } { ; }
    }

    proc display_only { {name "" } {proc  "" }    } {
        global public
        set cur_proc display_only ;
        if { [ catch {
                foreach child [ winfo children $public(screen) ] {
                    pack forget $child
                }
                if { $name != "" } {
                    pack $name -expand true -fill both
                }
        } err ] } { ; }
    }

    proc colors1 { } {
        global public
        set num_colors 0
        foreach color { red orange yellow green blue purple } {
            incr num_colors
            set public(clr,$num_colors) $color
        }
        set public(colors,count) 1
        set public(clr,max) $num_colors
    }

    proc colors2 { } {
        global public
        set num_colors 0
        set range { 0 6 D }
        foreach r $range {
            foreach g $range {
                foreach b $range {
                    if { $r != $b || $b != $g } {
                        incr num_colors
                        set public(clr,$num_colors) #[set r]0[set g]0[set b]0
                    }
                }
            }
        }
        set public(colors,count) 1
        set public(clr,max) $num_colors
    }

    proc colors { } {
        global public
        set num_colors 0

        set colors { SeaGreen4 HotPink2 aquamarine3 purple4 cyan4 MediumPurple3 blue
            plum3  orange3  magenta3  goldenrod2 VioletRed4 yellow
            firebrick3 OliveDrab3   tomato1 SpringGreen3
        }
        set colors { aquamarine3  cyan4  blue purple4 MediumPurple3
            plum3 magenta3 HotPink2 VioletRed4 firebrick3 tomato1 orange3
            goldenrod2  yellow OliveDrab3 SpringGreen3 SeaGreen4
        }
        foreach color $colors {
            set public(clr,$num_colors) $color
            incr num_colors
        }
        set public(colors,count) 1
        set public(clr,max) $num_colors
        set lightcolors {
            #E0B0B0 #E0C0B0 #E0D0B0 #E0E0B0 #E0F0B0 #B0C0B0 #B0C0D0 #C0B0B0
        #D0B0B0 #E0B0B0 #D0D0B0 #E0D0B0 #D0C0D0 #D0D0F0 #C0C0F0 #E0D0F0 }

        set num_colors 0
        foreach color $lightcolors {
            set public(lclr,$num_colors) $color
            incr num_colors
        }
        set public(lcolors,count) 1
        set public(lclr,max) $num_colors
    }

    proc getcolor { event_type } {
        global public
        incr  public(colors,count)
        if { $public(colors,count) >= $public(clr,max) } { set public(colors,count) 0 }
        set   public(color,$event_type)      $public(clr,$public(colors,count))
        set   color $public(color,$event_type)
        return $color
    }

    proc geteventcolor { event } {
        global public
        set event_type [ get_event_type $event ]
        set color [ getcolor $event_type ]
        return $color
    }

    proc getlcolor { } {
        global public
        incr  public(lcolors,count)
        if { $public(lcolors,count) >= $public(lclr,max) } {
            set public(lcolors,count) 0
        }
        return $public(lclr,$public(lcolors,count))
    }

    proc generic_time { x } {
        global public
        set cur_proc generic_time
        set secs [ expr $x%60]
        set hour [ expr int($x/3600)]
        set mins [ expr int($x/60)-$hour*60]
        while { $hour > 24 } {
            set hour [ expr $hour - 24 ]
        }
        if { $mins < 10 } { set mins 0$mins }
        if { $secs < 10 } { set secs 0$secs }
        return  $hour:$mins:$secs
    }

    proc cur_time { x pts  } {
        global public
        set level 10
        set cur_proc cur_time
        set pts [ expr int($pts) ]
        if { $pts > 1 } {
            regsub {^0*} $pts "" pts
            if { $pts > 86400 } { set pts [ expr $pts%86400 ] }
            set secs [ expr $pts%60]
            set hour [ expr int($pts/3600) ]
            set mins [ expr int($pts/60)-$hour*60]
            set hour [ expr $hour%24 ]
            if { $mins < 10 } { set mins 0$mins }
        } else { set hour 0; set mins 0 ; set secs 0 }
        return  $hour:$mins
    }

    proc secs_fetch { args } {
        global public
        set cur_proc secs_fetch
        if { [ catch {
                foreach row [ lindex $args 1 ] {
                    set public(secs) [lindex $row 0]
                }
                unlock public(thread_actv) $cur_proc
        } err ] } { ; }
    }

    proc days_fetch { args } {
        global public
        set cur_proc days_fetch
        if { [ catch {
                foreach row [ lindex $args 1 ] {
                    set public(today) [lindex $row 0]
                }
                unlock public(thread_actv) $cur_proc
        } err ] } { ; }
    }

    option add *Tablelist.labelCommand tablelist::sortByColumn

    proc ash_init { { display  0 } } {
        upvar #0 env e
        global public
        set cur_proc ash_init
        if { [ catch {
                set ash_frame $public(main).f.a
                set public(type) ash
                if { [ winfo exists $ash_frame  ] } {
                    if { $display == 1 } {
                        display_tile $ash_frame ash
                        set public(collect,ash) 1
                    }
                    return
                }

                ttk::panedwindow $ash_frame -orient vertical
                set public(ash_frame) $ash_frame
                ttk::panedwindow .ed_mainFrame.me.m.f.a.topdetails -orient horizontal

                #===========================
                # contains 3 children
                # GRAPH
                # Row 1 - Graph
                set graph_frame $ash_frame.gf
                ttk::frame  $graph_frame -height [ expr int ( $public(p_y) / 1.2 ) ]
                $ash_frame add $graph_frame
                set public(ash,graph_frame) $graph_frame
                #$ash_frame add .topdetails
                $ash_frame add .ed_mainFrame.me.m.f.a.topdetails
                # Row 2 - container tabs and three column aggregates
                #set hold_details .hold_details
                set hold_details .ed_mainFrame.me.m.f.a.topdetails.hold_details
                ttk::frame $hold_details
                .ed_mainFrame.me.m.f.a.topdetails add $hold_details
                # Row 3 - text window, sql text, explain plan, ashrpt
                #set  public(ash,output_frame) .output
                set  public(ash,output_frame) .ed_mainFrame.me.m.f.a.topdetails.output
                ttk::frame $public(ash,output_frame)
                .ed_mainFrame.me.m.f.a.topdetails add  $public(ash,output_frame)
                #===========================

                # Row 2 subrow 1 - Tabs
                #set    buttons    .graph_buttons
                set    buttons    .ed_mainFrame.me.m.f.a.gf.graph_buttons
                ttk::frame  $buttons   -height 10
                pack  $buttons     -in $public(ash,graph_frame) -expand no -fill none -side bottom -ipadx 0 -ipady 0 -padx 0 -pady 0
                set public(ash,button_frame) $buttons
                # Row 2 child 1, add tabs
                #addtabs adds "+-" buttons so timescale can be increased or reduced
                #addtabs

                # Row 2 subrow 2 - three paned windows
                set    tops_frame    $hold_details.tf
                ttk::frame $tops_frame
                set public(ash,tops_frame) $tops_frame

                # Row 2 subrow 2 col 1 - top sql
                set    sql_frame    $tops_frame.sql
                ttk::frame  $sql_frame -width $public(p_x)
                set public(ash,sql_frame) $sql_frame

                # Row 2 subrow 2 col 2 - top event
                set   evt_frame    $tops_frame.evt
                ttk::frame  $evt_frame -width $public(p_x)
                set public(ash,evt_frame) $evt_frame

                # Row 2 subrow 2 col 3 - top session
                set   ses_frame    $tops_frame.ses
                ttk::frame  $ses_frame -width $public(p_x)
                set public(ash,ses_frame) $ses_frame

                # Row 3 subrow1  - buttons for SQLTXT, PLAN, STATS, ASHRPT
                set details_buttons $public(ash,output_frame).b
                ttk::frame $details_buttons -height 10
                set public(ash,details_buttons) $details_buttons

                # Row 3 -  sql text,plan,ashrpt
                pack $public(ash,details_buttons) -side top -expand no -fill none -anchor nw
                outputsetup $public(ash,output_frame)

                # Row 3
                set sqlstat_frame   $public(ash,output_frame).stats
                ttk::frame  $sqlstat_frame
                set public(ash,sqlstats_frame) $sqlstat_frame
                stat_tbl  $public(ash,sqlstats_frame) 100 32 "statistc total per_exec per_row"
                set public(ash,stattbl) $public(ash,sqlstats_frame).tbl

                graphsetup
                sqlbuttons_setup
                waitbuttons_setup

                pack $tops_frame -side top -expand no -fill none -anchor nw
                pack $sql_frame -in $tops_frame -side top -expand no -fill none -anchor nw
                pack $evt_frame -in $tops_frame -side top -expand no -fill none -anchor nw
                pack $ses_frame -in $tops_frame -side top -expand no -fill none -anchor nw

                # Session
                ses_tbl  $public(ash,ses_frame) 60 10  " user_name %Active Activity SID(PID)  $public(ash,groups) "
                set public(ash,sestbl) $public(ash,ses_frame).tbl

                # Wait events
                evt_tbl  $public(ash,evt_frame) 60 10 { "event" "%Total_Time" "Activity" "Group" }
                set public(ash,evttbl) $public(ash,evt_frame).tbl

                # Sql
                #sql_tbl  $public(ash,sql_frame) 60 10 "SQL_ID %Total_DB_Time Activity SQL_TYPE plan_hash $public(ash,groups)"
                sql_tbl  $public(ash,sql_frame) 60 10 "SQL_ID %Total_DB_Time Activity SQL_TYPE $public(ash,groups)"
                set public(ash,sqltbl) $public(ash,sql_frame).tbl

                display_tile $ash_frame ash

                mon_execute ashtime
                $public(ash,sqltbl) cellselection clear 0,0 end,end
                $public(ash,sqltbl) configure -selectbackground $public(bg)
                $public(ash,sqltbl) configure -selectforeground #FF7900
                $public(ash,sqltbl) configure -activestyle none
        #} err ] } { ; }
    }

    # For zooming in and out, resets the minimum point on X axis
    proc reset_ticks { } {
        global x_w_ash
        global public
        # number of seconds to display on the graph, i.e. width
        # ash,xmin is a factor, i.e. show 2x the number of seconds or 1/2
        set secs [ expr $public(ash,xmin) * 3600 ]
        set max $x_w_ash(end)
        # take maximum display point, in seconds and subtract the width, this is min point
        set min   [ expr $x_w_ash(end) - $secs ]
        set delta [ expr $max - $min ]
        if  { $min > 0 } {
            set public(ash,ticksize) [ expr $secs/$public(ash,ticks) ]
            set oldmin [ $public(ash,graph) axis configure x -min ]
            $public(ash,graph) axis configure x -min $min  -stepsize $public(ash,ticksize)
        }
    }

    proc ashempty_fetch { args } {
        global public
        set parent $public(parent)
        set cur_proc ashempty_fetch
        set public(ashrowcount) [ join [string map {\" {}} [ lindex $args 1 ]]]
        #uncomment toreport how many rows
        #thread::send $parent "putsm \"Ash has $public(ashrowcount) rows...\""
        unlock public(thread_actv) $cur_proc
    }

    proc ashtime_fetch { args } {
        global public
        set cur_proc ashtime_fetch
        #puts "call $cur_proc $args"
        if { [ catch {
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 0 ] != "" } {
                        set sample_id [ lindex $row 0 ]
                        set secs [ lindex $row 1 ]
                        set day  [ lindex $row 2 ]
                    }
                }

                # Derive absolute bounds from sample_id (CEILING(UNIX_TIMESTAMP(ash_time))) so the
                # comparison is timezone-independent. The "- 1" cushion keeps the first bucket
                # inclusive when FROM_UNIXTIME is applied to this value later.
                set public(ash,starttime) [expr {$sample_id - $public(ash,loadhours) * 3600 - 1}]
                set public(ash,startday) "${day}"
                # ash,time used just below in cursor where clause in variable ash,where
                set public(ash,time) [expr {$sample_id - $public(ash,loadhours) * 3600 - 1}]
                set public(ash,day)  "$day"
                set public(ash,secs) "$secs"
                set public(ash,sample_id) "$sample_id"
                # secs is not needed here, gets set again and used in ash_fetch
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
        set public(ash,bucket_secs)
        set public(ash,where) "ash_time > FROM_UNIXTIME($public(ash,time))"
        mon_execute ash
        set public(ash,bucket_secs) $public(sleep,fast)
        set public(cursor,ash) fast
    } ;# ashtime_fetch

    proc ses_tbl { win ncols nrows cols } {
        global public
        set cur_proc  ses_tbl
        set tbl ${win}.tbl
        set vsb ${win}.vsb
        set collist ""

        foreach  col $cols {
            set collist  "$collist  0 $col left "
        }

        tablelist::tablelist $tbl \
         -background $public(bg) \
         -foreground $public(fg) \
         -columns " $collist " \
         -labelrelief flat \
         -font $public(medfont) -setgrid no \
         -yscrollcommand [list $vsb set] \
         -width $ncols  -height $nrows -stretch all
        bind [$tbl bodytag] <Button-1> {
            foreach {tablelist::W tablelist::x tablelist::y} [tablelist::convEventFields %W %x %y] {}
            if { [ $public(ash,sestbl) containing $tablelist::y] > -1 } {
                set id  [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],sid -text]

                set Mutex     [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],Mutex -text]
                set RWLock    [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],RWLock -text]
                set Cond      [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],Cond -text]
                set SXLock    [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],SXLock -text]
                set File_IO   [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],File_IO -text]
                set Table_IO  [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],Table_IO -text]
                set Network   [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],Network -text]
                set Lock      [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],Lock -text]
                set Idle      [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],Idle -text]
                set CPU       [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],CPU -text]
                set BCPU      [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],BCPU -text]
                #puts "call ses_tbl, CPU:$CPU, BCPU:$BCPU, LWLock:$LWLock"

                $public(ash,sestbl) cellselection clear 0,0 end,end
                $public(ash,sestbl) configure -selectbackground $public(bg)
                $public(ash,sestbl) configure -selectforeground #FF7900
		$public(ash,sestbl) configure -activestyle none
                $public(ash,output) delete 0.0 end
                #$public(ash,output) insert  insert "   working ... "
                pack forget $public(ash,details_buttons).sql
                pack forget $public(ash,output_frame).f
                pack forget $public(ash,output_frame).sv
                pack forget $public(ash,output_frame).stats
                pack $public(ash,output_frame).txt -side left -anchor nw
                pack $public(ash,details_buttons).wait -side left

                $public(ash,output) insert  insert "Statistic of wait events for the process $id\n\n"
                $public(ash,output) insert  insert "CPU:\t\t$CPU \nBCPU:\t\t$BCPU \nMutex:\t\t$Mutex \nRWLock:\t\t$RWLock \nCond:\t\t$Cond \nSXLock:\t\t$SXLock \nFile_IO:\t\t$File_IO \nTable_IO:\t\t$Table_IO \nNetwork:\t\t$Network \nLock:\t\t$Lock \nIdle:\t\t$Idle \n"
                update idletasks
                clipboard clear
                clipboard append $id
            } else {
                $public(ash,sestbl) cellselection clear 0,0 end,end
                $public(ash,sestbl) configure -selectbackground $public(bg)
                $public(ash,sestbl) configure -selectforeground $public(fg)
            }
        }

        if {[$tbl cget -selectborderwidth] == 0} { $tbl configure -spacing 1 }

        set row 0
        foreach  col $cols {
            if { $row == 0 } { $tbl columnconfigure 0  -name id -width 13 -maxwidth 13}
            if { $row == 1 } { $tbl columnconfigure 1  -name asl \
                                               -width 20 \
                                               -formatcommand emptyStr \
                                               -sortmode integer }
            if { $row == 2 } { $tbl columnconfigure 2  -name activity -hide 1 -sortmode integer }
            if { $row == 3 } { $tbl columnconfigure 3  -name sid  -sortmode integer }
            if { $row >  3 } { $tbl columnconfigure $row  -name $col  -width 13 \
                                                  -maxwidth 13 \
                                                  -hide 1  \
                                                  -sortmode integer  \
                                                  -bg $public(ashgroup,$col) }
            incr row
        }
        ttk::scrollbar $vsb -orient vertical -command [list $tbl yview]
        set public(ash,sqltbl) $tbl
        grid $tbl -row 0 -column 0 -sticky nws
        grid $vsb -row 0 -column 1 -sticky ns
        grid rowconfigure    . 0 -weight 1
        grid columnconfigure . 0 -weight 1
    }

    proc sql_tbl { win ncols nrows cols } {
        global public
        set cur_proc  sql_tbl
        set tbl ${win}.tbl
        set vsb ${win}.vsb
        set collist ""

        foreach col $cols {
            set collist  "$collist  0 $col left "
        }

        tablelist::tablelist $tbl \
    -background $public(bg) \
    -foreground $public(fg) \
    -columns " $collist " \
    -labelrelief flat \
    -font $public(medfont) -setgrid no \
    -yscrollcommand [list $vsb set] \
    -width $ncols -height $nrows -stretch all
        set public(sqltbl,cell)  0,0
        bind [$tbl bodytag] <Button-1> {
            foreach {tablelist::W tablelist::x tablelist::y} [tablelist::convEventFields %W %x %y] {}
            # set up a function to handle the buttons displayed
            pack forget $public(ash,details_buttons).wait -side left
            pack        $public(ash,details_buttons).sql  -side left
            if { [ $public(ash,sqltbl) containing $tablelist::y] > -1 } {
                set id  [ $public(ash,sqltbl) cellcget [ $public(ash,sqltbl) containing [subst $tablelist::y]],id -text]
                set public(sqltbl,cell)  [ $public(ash,sqltbl) containing $tablelist::y],0
                $public(ash,sqltbl) cellselection clear 0,0 end,end
                $public(ash,sqltbl) cellselection set $public(sqltbl,cell)
                update idletasks
                clipboard clear
                clipboard append $id
                set public(ash,realsqlid) $id
                ash_sqltxt $id
                if { "$public(ash,overtimeid)" == "$id" } {
                    $public(ash,sqltbl) configure -selectbackground $public(bg)
                    $public(ash,sqltbl) configure -selectforeground #FF7900
                    update idletasks
                    sqlovertime $id
                    set public(ash,overtimeid) -1
                } else {
                    $public(ash,sqltbl) configure -selectbackground $public(bg)
                    $public(ash,sqltbl) configure -selectforeground #FF7900
                    update idletasks
                    set public(ash,overtimeid) $id
                    sqlovertime clear
                }
            } else {
                $public(ash,sqltbl) cellselection clear 0,0 end,end
                $public(ash,sqltbl) configure -selectbackground $public(bg)
                $public(ash,sqltbl) configure -selectforeground #FF7900
                sqlovertime clear
            }
        }

        if {[$tbl cget -selectborderwidth] == 0} { $tbl configure -spacing 1 }
        set row 0
        foreach  col $cols {
            if { $row == 0 } { $tbl columnconfigure 0  -name id -width 12}
            if { $row == 1 } { $tbl columnconfigure 1  -name asl \
                                               -width 20 \
                                               -formatcommand emptyStr \
                                               -sortmode integer }
            if { $row == 2 } { $tbl columnconfigure 2  -name "activity" -hide 1 -sortmode integer -width 0}
            if { $row == 3 } { $tbl columnconfigure 3  -name "sql_type" -sortmode integer -width 8}
            #if { $row == 4 } { $tbl columnconfigure 3  -name "plan_hash" -width 5}
            if { $row >  3 } { $tbl columnconfigure $row  -name $col  \
                                                  -hide 1  \
                                                  -sortmode integer  \
                                                  -bg $public(ashgroup,$col) }
            incr row
        }
        ttk::scrollbar $vsb -orient vertical -command [list $tbl yview]
        set public(ash,sqltbl) $tbl
        grid $tbl -row 0 -column 0 -sticky news
        grid $vsb -row 0 -column 1 -sticky ns
        grid rowconfigure    . 0 -weight 1
        grid columnconfigure . 0 -weight 1
    } ;# sql_tbl

    proc emptyStr val { return "" }

    proc stat_tbl { win ncols nrows cols } {
        global public
        set cur_proc  stat_tbl
        set tbl ${win}.tbl
        set vsb ${win}.vsb
        set hsb ${win}.hsb
        set collist ""
        foreach  col $cols {
            set collist "$collist 0 $col left "
        }
        tablelist::tablelist $tbl \
    -background $public(bg) \
    -foreground $public(fg) \
    -columns " $collist " \
    -labelrelief flat \
    -font $public(medfont) -setgrid no \
    -yscrollcommand [list $vsb set] \
    -xscrollcommand [list $hsb set] \
    -width $ncols  -height $nrows -stretch all
        if {[$tbl cget -selectborderwidth] == 0} { $tbl configure -spacing 1 }
        set row 0
        foreach  col $cols {
            if { $row == 0 } { $tbl columnconfigure $row  -name id -width 15 -align left }
            if { $row == 1 } { $tbl columnconfigure $row  -name id -width 10 -align right }
            if { $row == 2 } { $tbl columnconfigure $row  -name id -width 15 -align right }
            if { $row == 3 } { $tbl columnconfigure $row  -name id -width 15 -align right }
            if { $row >  3 } { $tbl columnconfigure $row  -name id -width 5 -align right }
            incr row
        }
        ttk::scrollbar $vsb -orient vertical -command [list $tbl yview]
        ttk::scrollbar $hsb -orient horizontal -command [list $tbl xview]
        grid $tbl -row 0 -column 0 -sticky news
        grid $vsb -row 0 -column 1 -sticky ns
        grid $hsb -row 0 -column 0 -sticky sew
        grid rowconfigure    . 0 -weight 1
        grid columnconfigure . 0 -weight 1
    }

    proc plan_tbl { win ncols nrows cols } {
        global public
        set cur_proc  plan_tbl
        set tbl ${win}.tbl
        set vsb ${win}.vsb
        set hsb ${win}.hsb
        set collist ""
        foreach  col $cols {
            set collist  "$collist  0 $col left "
        }
        tablelist::tablelist $tbl \
    -background $public(bg) \
    -foreground $public(fg) \
    -columns " $collist " \
    -labelrelief flat \
    -font $public(medfont) -setgrid no \
    -yscrollcommand [list $vsb set] \
    -xscrollcommand [list $hsb set] \
    -width $ncols  -height $nrows -stretch all
        if {[$tbl cget -selectborderwidth] == 0} { $tbl configure -spacing 1 }
        set row 0
        foreach  col $cols {
            if { $row == 0 } { $tbl columnconfigure $row  -name id -maxwidth 15  -width 15 }
            if { $row == 1 } { $tbl columnconfigure $row  -name id -maxwidth 5  -width 5 }
            if { $row == 2 } { $tbl columnconfigure $row  -name id -maxwidth 15  -width 15 }
            if { $row >  2 } { $tbl columnconfigure $row  -name id -maxwidth 5  -width 5 }
            incr row
        }
        ttk::scrollbar $vsb -orient vertical -command [list $tbl yview]
        ttk::scrollbar $hsb -orient horizontal -command [list $tbl xview]
        grid $tbl -row 0 -column 0 -sticky news
        grid $vsb -row 0 -column 1 -sticky ns
        grid $hsb -row 0 -column 0 -sticky sew
        grid rowconfigure    . 0 -weight 1
        grid columnconfigure . 0 -weight 1
    }

    proc evt_tbl { win ncols nrows cols } {
        global public
        set cur_proc  evt_tbl
        set tbl ${win}.tbl
        set vsb ${win}.vsb
        set collist ""
        foreach  col $cols {
            set collist  "$collist  0 $col left "
        }
        tablelist::tablelist $tbl \
    -background $public(bg) \
    -foreground $public(fg) \
    -columns " $collist " \
    -labelrelief flat \
    -font $public(medfont) -setgrid no \
    -yscrollcommand [list $vsb set] \
    -width $ncols  -height $nrows -stretch all
        bind [$tbl bodytag] <Button-1> {
            foreach {tablelist::W tablelist::x tablelist::y} [tablelist::convEventFields %W %x %y] {}
            if { [ $public(ash,evttbl) containing $tablelist::y] > -1 } {
                set id [ $public(ash,evttbl) cellcget [ $public(ash,evttbl) containing [subst $tablelist::y]],id -text]
                $public(ash,evttbl) cellselection clear 0,0 end,end
                $public(ash,evttbl) configure -selectbackground  $public(bg)
                $public(ash,evttbl) configure -selectforeground  #FF7900
                $public(ash,evttbl) configure -activestyle none
                $public(ash,output) delete 0.0 end
                #$public(ash,output) insert insert "   working ... "
                $public(ash,output) insert insert "   session id $id "
                wait_analysis $id
                update idletasks
                clipboard clear
                clipboard append $id
            } else {
                $public(ash,evttbl) cellselection clear 0,0 end,end
                $public(ash,evttbl) configure -selectbackground $public(bg)
                $public(ash,evttbl) configure -selectforeground $public(fg)
            }
        }
        if {[$tbl cget -selectborderwidth] == 0} { $tbl configure -spacing 1 }
        set row 0
        foreach  col $cols {
            if { $row == 0 } { $tbl columnconfigure 0  -name id -width 27}
            if { $row == 1 } { $tbl columnconfigure 1  -name asl -formatcommand emptyStr -sortmode integer -width 28}
            if { $row == 2 } { $tbl columnconfigure 2  -hide 1 -name activity }
            if { $row >  2 } { $tbl columnconfigure $row  -name $col -sortmode integer -hide 1}
            incr row
        }
        ttk::scrollbar $vsb -orient vertical -command [list $tbl yview]
        set public(ash,sqltbl) $tbl
        grid $tbl -row 0 -column 0 -sticky news
        grid $vsb -row 0 -column 1 -sticky ns
        grid rowconfigure    . 0 -weight 1
        grid columnconfigure . 0 -weight 1
    }

    proc createSesFrame {tbl row col w } {
        global public
        set cur_proc  createSesFrame
        if { [ catch {
                frame $w -width 142 -height 14 -background $public(bg) -borderwidth 0 -relief flat
                bindtags $w [lreplace [bindtags $w] 1 1 TablelistBody]
                set delta $public(ashtbl,delta)
                set total  [$tbl cellcget $row,activity -text]
                set colcnt [ $tbl columncount ]
                # 0 = type, 1 = act bar , 2 = act value , others are bar components
                for { set i 4 } { $i <  $colcnt  } { incr  i } {
                    set sz [$tbl cellcget $row,$i -text]
                    set name [ lindex [ $tbl columnconfigure $i -name ] end ]
                    set szpct [ expr {$total * 100 / $delta }]
                    frame $w.w$i -width $szpct -background $public(ashgroup,$name) -borderwidth 0 -relief flat
                    place $w.w$i -relheight 1.0
                    set total [ expr $total - $sz ]
                }
                set total [$tbl cellcget $row,activity -text]
                set act [ format "%3.0f" [ expr ceil(100 *  $total  / ($delta)) ] ]
                label $w.t$row -text $act -font $public(medfont) -background $public(bg) -foreground $public(fg)
                # cell is 140 wide, the bars should all be under 100
                # put the activity value just above the bar
                set pc [ expr (($total + 0.0)/($delta )) * (100.0/142) ]
                place $w.t$row -relheight 1.0 -relx $pc
        } err ] } { ; }
    }

    proc createSqlFrame {tbl row col w } {
        global public
        set cur_proc  createSqlFrame
        if { [ catch {
                frame $w -width 142 -height 14 -background $public(bg) -borderwidth 0 -relief flat
                bindtags $w [lreplace [bindtags $w] 1 1 TablelistBody]
                set total  [$tbl cellcget $row,activity -text]
		set originialtotal $total
                set colcnt [ $tbl columncount ]
                for { set i 4 } { $i <  $colcnt  } { incr  i } {
                    set sz [$tbl cellcget $row,$i -text]
                    set name [ lindex [ $tbl columnconfigure $i -name ] end ]
                    set szpct [ expr {$total * 100 / $public(sqltbl,maxActivity) }]
                    frame $w.w$i -width $szpct -background $public(ashgroup,$name) -borderwidth 0 -relief flat
                    place $w.w$i -relheight 1.0
		    #catch setting total in case sz invalid and prevents total showing over bar
                    catch {set total [ expr $total - $sz ]}
                }
                set total [$tbl cellcget $row,activity -text]
                set aas [ format "%0.0f" [ expr 100 * ($total+0.0) / $public(sqltbl,maxActivity) ] ]
                label $w.t$row -text $aas -font $public(medfont) -background $public(bg) -foreground $public(fg)
                # cell is 140 wide, the bars should all be under 100
                # put the activity value just above the bar
                set pc [ expr (($total+0.0)/$public(sqltbl,maxActivity) * (100.0/142) )   ]
                place $w.t$row -relheight 1.0 -relx $pc
        } err ] } { ; }
    }

    proc createevtFrame {tbl row col w } {
        global public
        set cur_proc  createevtFrame
        if { [ catch {
                frame $w -width 142 -height 14 -background $public(bg) -borderwidth 0 -relief flat
                bindtags $w [lreplace [bindtags $w] 1 1 TablelistBody]
                set activity [$tbl cellcget $row,activity -text]
                set total $public(ashevt,total)
                set width [ expr {$activity * 100.0 / $total }]
                set group [$tbl cellcget $row,Group -text]
                set i 0
                frame $w.w$i -width $width -background $public(ashgroup,$group) -borderwidth 0 -relief flat
                place $w.w$i -relheight 1.0
                set i 1
                set width [ format "%3.1f" $width ]
                label $w.w$i -text $width -font $public(medfont) -background $public(bg) -foreground $public(fg)
                # cell is 140 wide, the bars should all be under 100
                # put the activity value just above the bar
                set pc [ expr (($activity + 0.0)/$total * (100.0/142) )   ]
                place $w.w$i -relheight 1.0 -relx $pc
        } err ] } { ; }
    }

    proc create_ash_cpu_line { } {
        global public
        set cur_proc create_ash_cpu_line
        if { [ catch {
                set   yvec y_ash_maxcpu
                set   xvec x_ash_maxcpu
                global $xvec $yvec
                vector $xvec
                vector $yvec
                set  [set yvec](++end)  $public(cpucount)

                $public(ash,graph) line create linemaxcpu \
               -xdata $xvec \
               -ydata $yvec \
               -color red   \
               -label ""

        } err ] } { ; }
    }

    proc ash_bars { xvec yvec graph name idx  { color none } { display "show" } } {
        global public
        set public(ash,TYPE) bar
        upvar #0 env e
        set cur_proc ash_bars
        if { [ catch {
                global $yvec $xvec
                vector $xvec $yvec
                if { $public(ash,TYPE) == "bar" } {
                    $graph element create line$idx \
        -xdata $xvec \
        -ydata $yvec \
        -label $name \
        -relief flat \
        -bindtag $name \
        -barwidth 60 \
        -fg $color \
        -bg $color
                    if { $display == "hide" } {
                        $graph element configure line$idx  -label ""
                    }
                    #Binding commented as crosshairs functionality missing position
                    #$graph legend bind $name <Enter> "$graph element configure line$idx -fg yellow "
                    #$graph legend bind $name <Leave> "$graph element configure line$idx -fg $color "
                    #$graph element bind $name <Enter> "$graph element configure line$idx -fg yellow "
                    #$graph element bind $name <Leave> "$graph element configure line$idx -fg $color  "
                }
        } err ] } { ; }
    }

    proc ash_displayx { } {
        global public
        set cur_proc ash_display
        if { [ catch {
                set sum 0
                update idletasks
        } err ] } { ; }
    }

    proc ash_fetch { args } {
        global public
        set cur_proc ash_fetch
        #set arglist [ lindex $args 1 ]
        #set listnum [ llength $arglist ]
        #puts "call $cur_proc, num:$listnum"
        if { [ catch {
                set maxsecs 0
                set type bars
                set xvec x_w_ash
                global $xvec
                global sample_id
                global ash_sec
                global ash_day
                set cpu_vec y_ash_maxcpu
                global $cpu_vec
                foreach id $public(ash,bars) {
                    set id_vec y_w_$id
                    global $id_vec
                }
                set pts 0
                global aas_hwm
                global maxval2
                if { ![ info exists aas_hwm ] } {
                    set aas_hwm 0
                    set maxval2 0
                }
                foreach row [ lindex $args 1 ] {
                    set end_secs  [lindex $row 0]
                    set beg_day   [lindex $row 1]
                    set end_day   [lindex $row 2]
                    set aas       [lindex $row 3]
                    #PG doesn't have sample_id, use extract(epoch from ash_time)) to simulate sample_id
                    set sampid    [lindex $row 4]
                    set secs      [lindex $row 5]
                    set beg_secs  [lindex $row 6]
                    set idx       [lindex $row 7]
                    #puts "call $cur_proc, =====idx:$idx, aas:$aas, secs:$secs, end_day:$end_day, end_secs:$end_secs"
                    if { $end_secs > 86399 } {
                        set end_secs [ expr $end_secs - 86400 ]
                        set end_day [ expr $end_day + 1 ]
                    }
                    set time     [ expr ( ( $end_day - 719528 ) * 86400 ) + $end_secs ]
                    set end_time [ expr ( ( $end_day - 719528 ) * 86400 ) + $end_secs ]
                    set beg_time [ expr ( ( $beg_day - 719528 ) * 86400 ) + $beg_secs ]
                    set sid $sampid
                    if { $public(ash,sample_id) < $sampid } {
                        set public(ash,sample_id) $sampid
                        set public(ash,where) "CEILING(UNIX_TIMESTAMP(ash_time)) > $public(ash,sample_id)"
                    }

                    # Valid Group (if group is not recognized, fall back to Other)
                    # Missing wait groups can cause ash_fetch to fail and blank display
                    if { ![info exists public(ash,$idx)] } {
                        set idx "Other"
                    }

                    if { 1 == 1 } {
                        #
                        # CURRENT vector
                        #
                        set name $idx
                        set yvec y_w_$idx
                        #
                        # NEW POINT
                        #
                        set zbeg_idx [ lindex [ [set xvec] search $beg_time ] end ]
                        set zend_idx [ lindex [ [set xvec] search $end_time ] 0 ]
                        set beg_idx $zbeg_idx
                        set end_idx $zend_idx
                        # if bucket_secs gets smaller, then we'll have some over lap with the new points
                        if {  $end_idx == "" || $beg_idx == "" || $beg_idx > $end_idx } {
                            set public(ash,delta) $public(ash,bucket_secs)
                            if { $type == "bars" } { set npts { 1 2 3 4 } }
                            foreach j $npts  {
                                # 1  - new start zero         .
                                # 2  - new value start        |
                                # 3  - new value end          |-
                                # 4  - new end  zero          |-|
                                # Times & CPU
                                set sample_id(++end) $sampid
                                set [set cpu_vec](++end) $public(cpucount)
                                #  Secs & dates
                                if { $j == 1 || $j == 2 } {
                                    set [set xvec](++end)  $beg_time
                                    set ash_sec(++end)     $beg_secs
                                    set ash_day(++end)     $beg_day
                                }
                                if { $j == 3 || $j == 4 } {
                                    set [set xvec](++end)  $end_time
                                    set ash_sec(++end)     $end_secs
                                    set ash_day(++end)     $end_day
                                }
                                #  Values
                                foreach id $public(ash,bars) {
                                    set id_vec y_w_$id
                                    set val 0
                                    set [set id_vec](++end) $val
                                }
                            }
                            set len [ sample_id length ]
                            set beg_idx [ expr $len - 3 ]
                            set end_idx [ expr $len - 2 ]
                        } ;# NEW POINT
                        #
                        # pts is used later below, check if data was found, if no display a new 0 value
                        #
                        incr pts
                        #
                        # AAS
                        #
                        #
                        #set aas [ expr ( $cnt + 0.0 ) / $public(ash,delta) ]
                        #set aas [ format "%6.3f" $aas]
                        #
                        # AAS CURRENT - Set current Vector
                        #
                        set curval [ set [set yvec]($end_idx) ]
                        set total_aas [ expr $curval + $aas ]
                        set val [ expr $aas + $curval ]
                        #puts "call $cur_proc, curval:$curval, total_aas:$total_aas, val:$val, maxval2:$maxval2, aas:$aas, end_idx:$end_idx"
                        #Calculate value for axis rounded up to next highest 10
                        if { $val > $maxval2 } {
                            set maxval2 $val
                            set axisaas [ expr ceil(($maxval2) / 5.0) ]
                            set axisaas [ expr $axisaas * 5 ]
                            if { $axisaas >= $aas_hwm } {
                                #Update axis before value - otherwise graph extends beyond top
                                set aas_hwm $axisaas
                                $public(ash,graph) axis configure y -max [ expr $aas_hwm + 2 ]
                                update idletasks
                            }
                        }
                        if { $type == "bars" } {
                            set [set yvec]($beg_idx) $val
                        }
                        set [set yvec]($end_idx) $val
                    } else {
                    };# exists public(ashgroup,$idx)
                } ;# for each row
                #
                # no data collected, update graph with zero values and new time point
                #
                if { $pts == 0 } {
                    #set asize [ array size sample_id ]
                    #puts "call $cur_proc, sample_id(end) size is $asize, $public(today), $public(secs), $public(ash,day)"
                    if { [ array size ash_day ] == 1 } { set ash_day(++end) $public(today) }
                    if { [ array size ash_sec ] == 1 } { set ash_sec(++end) $public(secs) }
                    if { [ array size x_w_ash ] == 1 } { set x_w_ash(++end) [ expr ( ( $public(today) - 719528 ) * 24 * 3600 ) + $public(secs) ] }
                    if { [ array size sample_id ] == 1 } { set sample_id(++end) $public(ash,sample_id) }
                    #set asize [ array size x_w_ash ]
                    #puts "call $cur_proc, sample_id(end) size is $asize, $ash_day(end), $ash_sec(end), $x_w_ash(end)"
                    set day     [ set ash_day(end) ]
                    set vecsecs [ set ash_sec(end) ]
                    set newsecs [ expr $vecsecs  + $public(ash,bucket_secs) ]
                    if { $newsecs > 86399 } {
                        set newsecs 0
                        set day [ expr $day + 1 ]
                    }
                    set oldtime [ set [ set xvec](end) ]
                    set newtime [ expr ( ( $day - 719528 ) * 24*3600 ) + $newsecs ]
                    set oldsample_id $sample_id(end)
                    set newsample_id [ expr $oldsample_id + $public(ash,bucket_secs) ]
                    if { $type == "bars" } { set npts { 1 2 3 4 } }
                    foreach j $npts  {
                        # Times
                        set sample_id(++end)  $newsample_id
                        set [set xvec](++end) $newtime
                        set ash_sec(++end) $newsecs
                        set ash_day(++end) $day
                        # CPU line
                        set cpu_vec y_ash_maxcpu
                        set [set cpu_vec](++end) $public(cpucount)
                        # Values
                        foreach id $public(ash,bars) {
                            set id_vec y_w_$id
                            set val 0
                            set [set id_vec](++end) $val
                        }
                    }
                    set len [ sample_id length ]
                }
                #
                # if sampling rate changes
                #
                set public(ash,bucket_secs) $public(sleep,fast)
                set public($cur_proc) 0; unlock public(thread_actv) $cur_proc
                #
                # cascade
                #
                # update the top sql list
                set hide [ lindex [ $public(ash,graph) marker configure marker1 -hide ] 4 ]
                if { $hide == 1 } {
                    incr public(ash,cascade)
                    set end [ [set xvec] length ]
                    set end [ expr $end - 1 ]
                    set beg [ expr $end - 3 ]
                    set coords " \$[set xvec]($beg) 0
                   \$[set xvec]($beg) Inf
                   \$[set xvec](end)  Inf
                   \$[set xvec](end)  0   "
                    $public(ash,graph) marker configure marker1 -coords [ subst $coords ] -hide 0
                    $public(ash,graph) marker configure marker2 -coords [ subst $coords ] -hide 0
                    ash_details $beg $end
                }
                # patch up time just after load, so second pass with smaller bucket_secs
                # doesn't back track
                if { $public(ash,first) == -1 } {
                    if { ![ info exists end_day ]  || $end_day  == "" } { set end_day $public(today) }
                    if { ![ info exists end_secs ] || $end_secs == "" } { set end_secs $public(secs) }
                    if { ![ info exists end_idx ]  || $end_idx == ""  } { set end_idx 2 }
                    set time [ expr ( ( $end_day - 719528 ) * 24*3600 ) + $end_secs ]
                    set [set xvec](end) $time
                    set [set xvec]($end_idx) $time
                    set public(ash,first) 0
                }
                # resets the ticks
                reset_ticks
        } err] } { puts "call $cur_proc, error:$err"; }
    }

    proc ash_details { beg end } {
        global public
        global sample_id
        global x_w_ash
        global ash_sec
        global ash_day
        set cur_proc ash_details
        #puts "call $cur_proc, beg:$beg, end:$end"
        set beg [ expr $beg - 0 ]
        set end [ expr $end - 0 ]
        if { [ catch {
                set public(ash,begid) [ set sample_id($beg)]
                set public(ash,endid) [ set sample_id($end)]
                set begday [ set ash_day($beg)]
                set begsec [ expr [ set ash_sec($beg)] - 0 ]
                set endday [ set ash_day($end)]
                set endsec [ expr [ set ash_sec($end)] + 0 ]
                # Use sample_id-derived bounds (true Unix timestamps) so FROM_UNIXTIME in the
                # drill-down queries compares correctly regardless of session time_zone.
                # sample_id is CEILING(UNIX_TIMESTAMP(ash_time)), so subtract 1 on the lower
                # bound to keep the first selected bucket inclusive.
                set public(ash,beg) [ expr {$public(ash,begid) - 1} ]
                set public(ash,end) $public(ash,endid)
                set public(ash,begcnt) [ format "%06.0f%05.0f" $begday $begsec ]
                set public(ash,endcnt) [ format "%06.0f%05.0f" $endday $endsec ]
                set public(ash,sesdelta)  [ expr [set public(ash,endcnt) ] - [ set public(ash,begcnt) ] ]
                #puts "call $cur_proc, begday:$begday, begsec:$begsec, endday:$endday, endsec:$endsec, public(ash,beg):$public(ash,beg), public(ash,end):$public(ash,end), sesdelta:$public(ash,sesdelta)"
                mon_execute ash_sqldetails
        } err] } {
            catch {
                $public(ash,sqltbl) delete 0 end
                $public(ash,evttbl) delete 0 end
                $public(ash,sestbl) delete 0 end
                $public(ash,output) delete 0.0 end
                $public(ash,stattbl) delete 0 end
            }
        }
    }

    proc ash_sqldetails_fetch { args } {
        global public
        set cur_proc ash_sqldetails_fetch
        if { [ catch {
                set public(sqltbl,maxActivity)  0
                $public(ash,sqltbl) delete 0 end
                $public(ash,output) delete 0.0 end
                $public(ash,evttbl) delete 0 end
                $public(ash,sestbl) delete 0 end
                #$public(ash,output) insert  insert "   working ... "
                set public(ashtbl,delta) [ expr $public(ash,endid) - $public(ash,begid) ]
                if { $public(ashtbl,delta) == 0 } {
                    set public(ashtbl,delta) $public(ash,bucket_secs)
                }
                set sqlid ""
                set sum 0
                update idletasks
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 3 ] != "" } {
                        set Lock      [lindex $row 0]
                        set QueryID   [lindex $row 1]
                        set Mutex     [lindex $row 2]
                        set Total     [lindex $row 3]
                        set SXLock    [lindex $row 4]
                        set Idle      [lindex $row 5]
                        set CPU       [lindex $row 6]
                        set RWLock    [lindex $row 7]
                        set Network   [lindex $row 8]
                        set Cond      [lindex $row 9]
                        set CmdType   [lindex $row 10]
                        set File_IO   [lindex $row 11]
                        set Table_IO  [lindex $row 12]
                        set Other     [expr {$Total - $Mutex - $RWLock - $Cond - $SXLock - $File_IO - $Table_IO - $Network - $Lock - $Idle - $CPU}]
                        if { $Other < 0 } { set Other 0 }

                        set sum [ expr $sum + $Total ]
                        set public(sqltbl,maxActivity) $sum
                        set sqlid $QueryID
                        $public(ash,sqltbl) insert end [concat \"$QueryID\"  $Total $Total \"$CmdType\" $Other $Mutex $RWLock $Cond $SXLock $File_IO $Table_IO $Network $Lock $Idle $CPU ]
                    }
                }
                set rowCount [$public(ash,sqltbl) size]
                for { set row 0 } { $row < $rowCount } { incr row } {
                    $public(ash,sqltbl) cellconfigure $row,1 -window createSqlFrame
                }
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
        if { [ catch {
                $public(ash,output) delete 0.0 end

                # cascade - fill in others
                ash_sqltxt $sqlid

                $public(ash,sqltbl) cellselection clear 0,0 end,end
                $public(ash,sqltbl) cellselection set 0,0
        } err] } { puts "call $cur_proc, err:$err"; }
    }

    proc ash_sqlsessions_fetch { args } {
        global public
        set cur_proc ash_sqlsessions_fetch
        #puts "call $cur_proc,args:$args"
        if { [ catch {
                set public(tbl,maxActivity)  0
                set delta $public(ash,sesdelta)
                $public(ash,sestbl) delete 0 end
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 2 ] != "" } {
                        set Lock      [lindex $row 0]
                        set Mutex     [lindex $row 1]
                        set Total     [lindex $row 2]
                        set SXLock    [lindex $row 3]
                        set PID       [lindex $row 4]
                        set host      [lindex $row 5]
                        set Idle      [lindex $row 6]
                        set CPU       [lindex $row 7]
                        set RWLock    [lindex $row 8]
                        set Network   [lindex $row 9]
                        set Cond      [lindex $row 10]
                        set user      [lindex $row 11]
                        set File_IO   [lindex $row 12]
                        set Table_IO  [lindex $row 13]
                        set Other     [expr {$Total - $Mutex - $RWLock - $Cond - $SXLock - $File_IO - $Table_IO - $Network - $Lock - $Idle - $CPU}]
                        if { $Other < 0 } { set Other 0 }

                        if { $user == "" || $user == "{}"} { set user "mysql" }

                        $public(ash,sestbl) insert end [concat \"$user $host\" $Total $Total $PID $Other $Mutex $RWLock $Cond $SXLock $File_IO $Table_IO $Network $Lock $Idle $CPU $CPU]
                    }
                }
                set rowCount [$public(ash,sestbl) size]
                for { set row 0 } { $row < $rowCount } { incr row } {
                    $public(ash,sestbl) cellconfigure $row,1 -window createSesFrame
                }
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
    }

    proc ash_sqltxt { sqlid } {
        global public
        set cur_proc ash_sqltxt
        if { $sqlid == "{}" } { set sqlid "" }
        if { $sqlid == "" } {
            set public(ash,sqlid) " digest is NULL "
        } else {
            set public(ash,sqlid) " digest = \'$sqlid\' "
        }
        # Clear any stale content (e.g. event info from wait_analysis) synchronously so the
        # panel never appears "blank" if the async query callback is skipped or returns
        # NULL sql_text.
        catch {
            $public(ash,output) delete 0.0 end
            $public(ash,output) insert insert "-- Loading SQL text ... --\n"
        }
        mon_execute ash_sqltxt
        regsub {\..*} $public(version) "" t
        if { $t > 5 } { ; }
        mon_execute ash_sqlevents
        mon_execute ash_sqlsessions
        if { [info exists public(ash,sqldetails)] && $public(ash,sqldetails) eq "stats" } {
            mon_execute ash_sqlstats
        }
    }

    proc ashrpt_fetch { args } {
        global public
        set cur_proc ashrpt_fetch
        if { [ catch {
                $public(ash,output) delete 0.0 end
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 0 ] != "" } {
                        #puts "call $cur_proc row:$row"
                        $public(ash,output) insert insert [lindex $row 0]
                        $public(ash,output) insert insert "\n"
                    }
                }
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
    }

    proc ash_sqltxt_fetch { args } {
        global public
        set cur_proc ash_sqltxt_fetch
        if { [ catch {
                $public(ash,output) delete 0.0 end
                set inserted 0
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 0 ] != "" } {
                        $public(ash,output) insert insert [lindex $row 0]
                        set public(ash,sqltxt) [lindex $row 0]
                        incr inserted
                    }
                }
                if { $inserted == 0 } {
                    $public(ash,output) insert insert "-- No SQL text recorded for this digest --"
                    set public(ash,sqltxt) ""
                }
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
    }

    proc ash_sqlstats_fetch { args } {
        global public
        set cur_proc ash_sqlstats_fetch
        if { [ catch {
                $public(ash,stattbl) delete 0 end
                set i 0
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 0 ] != "" } {
                        # Hash order: no_index_used select_scan rows_sent rows_affected
                        # select_full_join tmp_disk_tables rows_examined sort_rows
                        # total_exec_time tmp_tables calls
                        set stats(no_index_used)    [lindex $row 0]
                        set stats(select_scan)      [lindex $row 1]
                        set stats(rows_sent)        [lindex $row 2]
                        set stats(rows_affected)    [lindex $row 3]
                        set stats(select_full_join) [lindex $row 4]
                        set stats(tmp_disk_tables)  [lindex $row 5]
                        set stats(rows_examined)    [lindex $row 6]
                        set stats(sort_rows)        [lindex $row 7]
                        set stats(total_exec_time)  [ format "%0.2f" [lindex $row 8] ]
                        set stats(tmp_tables)       [lindex $row 9]
                        set stats(calls)            [lindex $row 10]

                        foreach val {
                            total_exec_time
                            calls
                            rows_affected
                            rows_sent
                            rows_examined
                            tmp_tables
                            tmp_disk_tables
                            select_scan
                            select_full_join
                            sort_rows
                            no_index_used
                        } {
                            set val1 $stats($val)
                            if { $stats(calls) == 0 } {
                                set val2 0
                            } else {
                                set val2 [ format "%0.2f" [ expr $stats($val) / $stats(calls) ] ]
                            }
                            if { $stats(rows_affected) == 0 } {
                                set val3 0
                            } else {
                                set val3 [ format "%0.2f" [ expr $stats($val) / $stats(rows_affected) ] ]
                            }
                            $public(ash,stattbl) insert end [ list $val $val1 $val2 $val3 ]
                        }
                    }
                }
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
    }

    proc ash_sqlplan_fetch { args } {
        global public
        set cur_proc ash_sqlplan_fetch
        if { [ catch {
                $public(ash,output) delete 0.0 end
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 0 ] != "" } {
                        regsub "{" $row "\n" row
                        regsub "}" $row "" row
                        $public(ash,output) insert end $row
                    }
                }
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
    }

    proc ash_eventsqls_fetch { args } {
        global public
        set cur_proc ash_eventsqls_fetch
        #puts "call $cur_proc, args:$args"
        if { [ catch {
                set cnt 0
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 0 ] != "" } {
                        set total        [lindex $row 0]
                        set backend_type [lindex $row 1]
                        set wait_event   [lindex $row 2]
                        set sql          [lindex $row 3]
                        incr cnt
                        if { $sql == "" } { set sql "Empty SQL" }
                        $public(ash,output) insert insert "\n-- No.$cnt --------------------------\n"
                        $public(ash,output) insert insert "Event Backend Type: $backend_type \n"
                        $public(ash,output) insert insert "SQL that caused $total times $wait_event wait event\n$sql \n"
                    }
                }
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
    }

    proc ash_sqlevents_fetch { args } {
        global public
        set cur_proc ash_sqlevents_fetch
        #puts "call $cur_proc $args"
        $public(ash,evttbl) delete 0 end
        set total 0
        if { [ catch {
                set  public(tbl,maxActivity)  0
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 0 ] != "" } {
                        set activity        [lindex $row 0]
                        set wait_event      [lindex $row 1]
                        set wait_event_type [lindex $row 2]
                        # Classify raw wait_event_type to display group
                        if { [string match "wait/synch/mutex*" $wait_event_type] } {
                            set group "Mutex"
                        } elseif { [string match "wait/synch/rwlock*" $wait_event_type] } {
                            set group "RWLock"
                        } elseif { [string match "wait/synch/cond*" $wait_event_type] } {
                            set group "Cond"
                        } elseif { [string match "wait/synch/sxlock*" $wait_event_type] } {
                            set group "SXLock"
                        } elseif { [string match "wait/io/file*" $wait_event_type] } {
                            set group "File_IO"
                        } elseif { [string match "wait/io/table*" $wait_event_type] } {
                            set group "Table_IO"
                        } elseif { [string match "wait/io/socket*" $wait_event_type] } {
                            set group "Network"
                        } elseif { [string match "wait/lock*" $wait_event_type] } {
                            set group "Lock"
                        } elseif { [string match "idle*" $wait_event_type] } {
                            set group "Idle"
                        } elseif { $wait_event_type eq "CPU" } {
                            set group "CPU"
                        } else {
                            set group "Other"
                        }
                        set total [ expr $total + $activity ]
                        if { $public(tbl,maxActivity) == 0 } {
                            set public(tbl,maxActivity) $activity
                        }
                        $public(ash,evttbl) insert end [list $wait_event $activity $activity $group]
                    }
                }
                set rowCount [$public(ash,evttbl) size]
                set public(ashevt,total) $total
                for { set row 0 } { $row < $rowCount } { incr row } {
                    $public(ash,evttbl) cellconfigure $row,1 -window createevtFrame
                }
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
    }

    proc sqlovertime_fetch { args } {
        global public
        set cur_proc sqlovertime_fetch
        #puts "call $cur_proc ======args:$args"
        if { [ catch {
                set xvec x_ashsql
                global $xvec
                set pts 0
                set maxid 0
                set maxtime 0
                foreach row [ lindex $args 1 ] {
                    set id   [lindex $row 0]
                    set day  [lindex $row 1]
                    set cnt  [lindex $row 2]
                    set secs [lindex $row 3]
                    set idx  [lindex $row 4]
                    set time [ expr ( ( $day - 719528 ) * 86400 ) + $secs ]
                    if {  [ info exists public(ashgroup,$idx) ] } {
                        if { $pts == 0 } {
                            incr pts
                            set [set xvec](++end) $time
                            foreach tmp_idx $public(ashsql,bars) {
                                set vec y_ashsql_$tmp_idx
                                global $vec
                                set [set vec](++end)  0
                            }
                        }
                        #
                        if { $id > $maxid } {
                            # if it's the first row, make the delta reasonable not bignumber - 0
                            if { $maxid == 0 } {
                                set delta $public(ashsql,bucket_secs)
                            } else {
                                set newdelta [ expr $id - $maxid ]
                                if { $newdelta != 0 } { set delta $newdelta }
                            }
                            set maxid $id
                        }
                        # CURRENT vector
                        set name $idx
                        set yvec y_ashsql_$idx
                        global $yvec
                        #
                        # NEW POINT
                        #
                        if { "$time" > "$maxtime" } {
                            while { [ expr $time - $maxtime ] > [ expr 1.5 *$public(ashsql,bucket_secs) ] && $maxtime > 0} {
                                set maxtime [ expr $maxtime + $public(ashsql,bucket_secs) ]
                                set [set xvec](++end) $maxtime
                                foreach tmp_idx $public(ashsql,bars) {
                                    set vec y_ashsql_$tmp_idx
                                    global $vec
                                    set [set vec](++end) 0
                                }
                            }
                            set maxtime $time
                            # NEW POINT y axis & sample_id
                            set [set xvec](++end) $time
                            # NEW POINT
                            # add a new point to each vector for the new bar
                            foreach tmp_id $public(ashsql,bars) {
                                set vec y_ashsql_$tmp_id
                                global $vec
                                set [set vec](++end) 0
                            }
                        } ;# NEW POINT
                        # AAS
                        set aas [ expr ( $cnt + 0.0 ) / $delta ]
                        set aas [ format "%6.3f" $aas]
                        # AAS CURRENT
                        # Set current Vector
                        set curval [ set [set yvec](end) ]
                        set total_aas [ expr $curval + $aas ]
                        set [set yvec](end) [ expr $aas + $curval ]
                        # the last point doesn't seem to get drawn, adding a dummy extra point
                    } else {
                    } ;# exists public(ashgroup,$idx)
                } ;# for each row
        } err] } { puts "call $cur_proc, err:$err"; }
        set  public($cur_proc) 0; unlock public(thread_actv) $cur_proc
    };#sqlovertime_fetch

    proc sqlovertime { sqlid } {
        global public
        set cur_proc sqlovertime
        #puts "call $cur_proc ======sqlid:$sqlid"
        if { [ catch {
                set id_vec x_ashsql
                global $id_vec
                [set id_vec] length  0
                foreach id $public(ashsql,bars) {
                    set id_vec y_ashsql_$id
                    global $id_vec
                    [set id_vec] length 0
                }
                if { $sqlid == "clear" } {
                    foreach idx $public(ash,bars) {
                        set color [ set public(ashgroup,$idx)  ]
                        if { $idx != "black" } {
                            $public(ash,graph) element configure line$idx -fg $color
                            $public(ash,graph) element configure linesql$idx  -hide 1
                            $public(ash,graph) element configure line$idx  -hide 0
                        }
                    }
                } else {
                    foreach idx $public(ash,bars) {
                        if { $idx != "black" } {
                            $public(ash,graph) element configure linesql$idx   -hide 0
                            $public(ash,graph) element configure linesql$idx   -barwidth $public(ash,bucket_secs)
                        }
                    }
                    foreach idx $public(ash,bars) {
                        if { $idx != "black" } {
                            $public(ash,graph) element configure line$idx -fg #D0D0D0 -hide 1
                        }
                    }
                    if { $sqlid == "{}" } { set sqlid "" }
                    if { $sqlid == "" || $sqlid == "{}" } {
                        set public(ashsql,sqlovertimeid) " digest is NULL "
                    } else {
                        set public(ashsql,sqlovertimeid) " digest = \'$sqlid\' "
                    }
                    set public(ashsql,bucket_secs) $public(ash,load_bucket_secs)
                    set public(sql,sqlovertime) $public(sql,sqlovertimeload)
                    mon_execute sqlovertime
                }
        } err] } { puts "call $cur_proc, err:$err"; }
    }

    proc ashsetup { newtab } {
        global public
        upvar #0 env e
        set cur_proc   ashsetup
        if { [ catch {
                if { $newtab != $public(ash,view) } {
                    set sqlid  [ $public(ash,sqltbl) cellcget 0,0 -text]
                    if { $newtab == "overview" } {
                        set public(ash,view) overview
                        update idletasks
                        $public(ash,sqltbl) cellselection clear 0,0 end,end
                    }
                    if { $newtab == "sql" } {
                        pack $public(ash,details_buttons)  -side top -expand yes -fill x
                        pack $public(ash,sqltxt_frame) -side top -expand yes -fill both
                    }
                    ash_sqltxt $sqlid
                }
        } err] } { puts "call $cur_proc, err:$err"; }
    }

    proc vectorsetup { } {
        global public
        upvar #0 env e
        set cur_proc   vectorsetup
        if { [ catch {
                set i 0
                foreach color {
                    { #808080 grey }
                    { #F06EAA Pink }
                    { #9F9371 light_brown }
                    { #C02800 red }
                    { #717354 medium_brown }
                    { #882044 plum }
                    { #5C440B dark_brown }
                    { #FFD700 gold }
                    { #E46800 orange }
                    { #4080F0 light_blue }
                    { #00FF00 bright_green }
                    { #00CC00 green }
                    { #FFFFFF black }
                } {
                    set public(ashcolor,$i) [ lindex $color 0 ]
                    incr i
                }
                #
                #  Wait Groups to Display Setup
                #
                set public(ash,groups) {
                    Other
                    Mutex
                    RWLock
                    Cond
                    SXLock
                    File_IO
                    Table_IO
                    Network
                    Lock
                    Idle
                    CPU
                BCPU }
                # list of id# of the wait groups
                set public(ashgroups) ""
                #
                # ID # list for Wait Groups
                #
                set wcn 0
                foreach wc "$public(ash,groups) "  {
                    lappend public(ashgroups) $wcn
                    set public(ashwc,$wcn) $wc
                    incr wcn
                }
                lappend public(ashgroups) $wcn
                set public(ashwc,$wcn) black
                #
                # SQL overtime Vectors
                #
                set public(sqlash,bars) {}
                set groups [ expr [ llength $public(ashgroups) ]  - 1 ]
                #create_ash_cpu_line
                for { set i $groups } { $i >= 0 } { incr  i -1 } {
                    set idx    $public(ashwc,$i)
                    set color  $public(ashcolor,$i)
                    set public(ashgroup,$idx) $color
                    set public(ash,$idx) $i
                    set xvec x_ashsql
                    set yvec y_ashsql_$idx
                    global  $xvec $yvec
                    ash_bars $xvec $yvec $public(ash,graph) "sql$idx" "sql$idx" $color hide
                    lappend public(ashsql,bars) "$idx"
                }
                #
                # WAIT group vectors
                #
                set public(ash,bars) {}
                set groups [ expr [ llength $public(ashgroups) ] - 1 ]
                for { set i $groups } { $i >= 0 } { incr  i -1 } {
                    set idx    $public(ashwc,$i)
                    set color  $public(ashcolor,$i)
                    set public(ashgroup,$idx) $color
                    set public(ash,$idx) $i
                    set xvec x_w_ash
                    set yvec y_w_$idx
                    ash_bars $xvec $yvec $public(ash,graph) $idx $idx $color
                    lappend public(ash,bars) "$idx"
                }
                $public(ash,graph) element configure lineblack  -label ""
                #
                global ash_day
                vector ash_day
                global ash_sec
                vector ash_sec
                global sample_id
                vector sample_id
        } err] } { puts "call $cur_proc, err:$err"; }
    }

    proc addtabs { } {
        global public defaultBackground
        upvar #0 env e
        set cur_proc   addtabs
        if { [ catch {
                set buttons $public(ash,button_frame)
                set public(ash,xminentry) $buttons
                button $public(ash,xminentry).minus -bg $defaultBackground -text "+" -font $public(smallfont) -command  {
                    set public(ash,xmin) [ expr $public(ash,xmin)/1.2 ]
                    if { $public(ash,xmin) == 0 } { set $public(ash,xmin) 1 }
                    reset_ticks
                } -padx 10 -pady 0
                button $public(ash,xminentry).plus -bg $defaultBackground -text "-" -font $public(smallfont) -command  {
                    set public(ash,xmin) [ expr $public(ash,xmin)*1.2 ]
                    reset_ticks
                }  -padx 10 -pady 0
                pack $public(ash,xminentry).minus -side right -ipadx 0 -ipady 0 -padx 0 -pady 0
                pack $public(ash,xminentry).plus -side right -ipadx 0 -ipady 0 -padx 0 -pady 0
        } err] } { puts "call $cur_proc, err:$err"; }
    }

    proc graphsetup { } {
        global public
        upvar #0 env e
        set cur_proc graphsetup
        if { [ catch {
                set graph          .ed_mainFrame.me.m.f.a.gf.ash_graph
                set public(ash,graph) $graph

       barchart $public(ash,graph) \
      -title "Active Session History"  \
      -background $public(bg) -foreground $public(fg) \
      -font $public(medfont)  \
      -relief flat      \
      -barmode overlap  \
      -bg $public(bgt)  \
      -borderwidth  0   \
      -plotbackground $public(bg)
                Blt_ActiveLegend $graph
                #Crosshairs errors with position error
                #Blt_Crosshairs $graph
                Blt_ClosestPoint $graph

                vectorsetup

                $graph legend configure   -font $public(smallfont) \
                              -fg $public(fg) \
                              -bg $public(bgt) \
                              -anchor nw \
                              -position right \
                              -ipady 0 -ipadx 0 -padx 0 -pady 0 \
                              -relief flat -borderwidth 0

                $graph axis   configure x -minorticks 0  \
                              -stepsize $public(ash,ticksize)  \
                              -tickfont  $public(smallfont) \
		              -titlefont $public(smallfont) \
		              -titlecolor $public(fg) \
                              -background $public(bgt) \
                              -command cur_time      \
                              -bd 0      \
                              -color $public(fg)

                $graph axis   configure y -title "AS" -titlefont $public(smallfont) -min 0.0 -max {} \
                              -tickfont  $public(smallfont) -titlefont $public(smallfont) -titlecolor $public(fg) \
                              -background $public(bgt) \
                              -color $public(fg)

                pack $public(ash,graph) -in $public(ash,graph_frame) -expand yes -fill both -side top -ipadx 0 -ipady 0 -padx 0 -pady 0

                set marker1 [$public(ash,graph) marker create polygon\
           -coords {-Inf Inf Inf Inf Inf -Inf -Inf -Inf} -fill {} \
           -fill $public(graphselect) \
           -under 1  \
           -hide 1
                ]
                set marker2 [$public(ash,graph) marker create polygon\
           -coords {-Inf Inf Inf Inf Inf -Inf -Inf -Inf} -fill {} \
           -linewidth 1 \
           -outline black  \
           -hide 1
                ]

                bind $public(ash,graph)  <ButtonRelease-1> {
                    set cur_proc graphsetupbind
                    if { [ catch {
                            set end  [%W axis invtransform x %x]
                            set beg_x $public(ash,beg_x)
                            global x_w_ash
                            set first  $x_w_ash(0)
                            if { $start < $first || $end < $first } {
                                if { $start > $end } {
                                } else { ; }
                                return
                            }
                            if { $start == $end } {
                                $public(ash,graph) marker configure marker1 -hide 1
                                $public(ash,graph) marker configure marker2 -hide 1
                            } else {
                                set ys  [ lindex [ $public(ash,graph) transform 0 0 ] 1 ]
                                set beg_x $public(ash,beg_x)
                                set end_x %x
                                array set beg_array [ $public(ash,graph) bar closest $beg_x $ys ]
                                array set end_array [ $public(ash,graph) bar closest $end_x $ys ]
                                if {  ![ info exists beg_array(x) ]  } { array set begarray {}
                                set beg_array(x) 0.0 } else { set beg $beg_array(x) }
                                if {  ![ info exists end_array(x) ]  } { array set end_array {}
                                set end_array(x) 0.0 } else { set end $end_array(x) }
                                if {  ![ info exists beg_array(index) ]  } { set beg_array(index) 0.0
                                set public(ash,pt2)  $beg_array(index) } else { set public(ash,pt2)  $beg_array(index) }
                                if {  ![ info exists end_array(index) ]  } { set end_array(index) 0.0
                                set public(ash,pt1)  $end_array(index) } else { set public(ash,pt1)  $end_array(index) }
                                set public(ash,pt1)  $end_array(index)
                                set public(ash,pt2)  $beg_array(index)
                                if {  $public(ash,pt1) == $public(ash,pt2) } {
                                    $public(ash,graph) marker configure marker1 -hide 1
                                    $public(ash,graph) marker configure marker2 -hide 1
                                } else {
                                    if {  $public(ash,pt1) > $public(ash,pt2) } {
                                        ash_details $public(ash,pt2) $public(ash,pt1)
                                    } else {
                                        ash_details $public(ash,pt1) $public(ash,pt2)
                                    }
                                }
                                if {  ![ info exists beg ]  } { set beg 0.0 }
                                $public(ash,graph) marker configure marker1 -coords [ subst { $beg 0  $beg Inf  $end Inf  $end 0 } ]
                                $public(ash,graph) marker configure marker2 -coords [ subst { $beg 0  $beg Inf  $end Inf  $end 0 } ]
                            }
                    } err] } { #puts "call $cur_proc, err:$err"; }
                }

                bind $public(ash,graph)  <ButtonPress-1> {
                    if { [ catch {
                            set start  [%W axis invtransform x %x]
                            set public(ash,beg_x) %x
                            $public(ash,graph) marker configure marker1 -hide 0
                            $public(ash,graph) marker configure marker2 -hide 0
                            $public(ash,graph) marker configure marker1 -coords [ subst { $start 0  $start Inf  $start Inf  $start 0 } ]
                            $public(ash,graph) marker configure marker2 -coords [ subst { $start 0  $start Inf  $start Inf  $start 0 } ]
                    } err] } { puts "call $cur_proc, err:$err"; }
                }

                bind $public(ash,graph)  <B1-Motion> {
                    if { [ catch {
                            set end  [%W axis invtransform x %x]
                            $public(ash,graph) marker configure marker1 -coords [ subst { $start 0  $start Inf  $end Inf  $end 0 } ]
                            $public(ash,graph) marker configure marker2 -coords [ subst { $start 0  $start Inf  $end Inf  $end 0 } ]
                    } err] } { puts "call $cur_proc, err:$err"; }
                }
        } err] } { puts "call $cur_proc, err:$err"; }
    }

    proc outputsetup { output } {
        global public
        upvar #0 env e
        set cur_proc   outputsetup
        if { [ catch {
                set   output    $public(ash,output_frame).txt
                frame $output   -bd 0  -relief flat -bg $public(bg)
                frame $output.f
                text $output.w  -background $public(bg) \
			    -yscrollcommand "$output.scrolly set" \
                    -xscrollcommand "$output.scrollx set" \
                    -width $public(cols) -height 26    \
                    -wrap word \
                    -font {basic}
                ttk::scrollbar $output.scrolly -command "$output.w yview"
                ttk::scrollbar $output.scrollx -command "$output.w xview"  \
                                    -orient horizontal
                pack  $output.f  -expand yes -fill both
                pack  $output.scrolly -in $output.f -side right -fill y
                pack  $output.scrollx -in $output.f -side bottom -fill x
                pack  $output.w  -in $output.f -expand yes -fill both
                set public(ash,output) $output.w
                $public(ash,output) insert insert "Monitor Active"
                pack $output -expand yes -fill both
                # SQL TEXT  - END
        } err] } { puts "call $cur_proc, err:$err"; }
    }

    proc waitbuttons_setup { } {
        global public
        upvar #0 env e
        set cur_proc   waitbuttons_setup
        #puts "call $cur_proc ====="
        if { [ catch {
                set waitbuttons $public(ash,details_buttons).wait
                frame $waitbuttons -bd 0 -relief flat -bg $public(bgt) -height 10

                ttk::button $waitbuttons.wait1 -text "Clear" -command {
                    $public(ash,output) delete 0.0 end
                    #$public(ash,output) insert  insert "   waitbutton ... \n"
                }
                pack  $waitbuttons.wait1 -side left
        } err] } { puts "call $cur_proc, err:$err"; }
    }

    proc sqlbuttons_setup { } {
        global public
        upvar #0 env e
        set cur_proc   sqlbuttons_setup
        if { [ catch {

                set sqlbuttons $public(ash,details_buttons).sql
                frame $sqlbuttons -bd 0 -relief flat -bg $public(bgt) -height 10
                pack  $sqlbuttons -side left -anchor nw

                ttk::button $sqlbuttons.stats -text "sql stats" -command {
                    set public(ash,sqldetails)  stats
                    if { ![ info exists public(ash,realsqlid) ] } {  set public(ash,realsqlid) "" }
                    ash_sqltxt $public(ash,realsqlid)
                    pack   forget $public(ash,output_frame).f
                    pack   forget $public(ash,output_frame).sv
                    pack   forget $public(ash,output_frame).txt
                    pack          $public(ash,output_frame).stats -side left -anchor nw
                    mon_execute ash_sqlstats
                }
                ttk::button $sqlbuttons.txt -text "sql text" -command {
                    set public(ash,sqldetails)  txt
                    pack   forget $public(ash,output_frame).f
                    pack   forget $public(ash,output_frame).sv
                    pack   forget $public(ash,output_frame).stats
                    pack   $public(ash,output_frame).txt -side left -anchor nw
                    if { ![ info exists public(ash,realsqlid) ] } {  set public(ash,realsqlid) "" }
                    ash_sqltxt $public(ash,realsqlid)
                }
                ttk::button $sqlbuttons.ashrpt -text "ashrpt" -command {
                    set public(ash,sqldetails)  ashrpt
                    pack   forget $public(ash,output_frame).f
                    pack   forget $public(ash,output_frame).sv
                    pack   forget $public(ash,output_frame).stats
                    pack   $public(ash,output_frame).txt -side left -anchor nw
                    mon_execute ashrpt
                }
                ttk::button $sqlbuttons.sqlio -text "sql io" -command {
                    set public(ash,sqldetails)  sqlio
                    pack   forget $public(ash,output_frame).f
                    pack   forget $public(ash,output_frame).sv
                    pack   forget $public(ash,output_frame).stats
                    pack   $public(ash,output_frame).txt -side left -anchor nw
                    mon_execute sqlio
                }
                #ttk::button $sqlbuttons.plan -text "sql plan" -command {
                    #  set public(ash,sqldetails) plan
                    #  pack   forget $public(ash,output_frame).f
                    #  pack   forget $public(ash,output_frame).sv
                    #  pack   forget $public(ash,output_frame).stats
                    #  pack   $public(ash,output_frame).txt -side left -anchor nw
                    #  mon_execute ash_sqlplan
                #}
                ttk::button $sqlbuttons.cpu -text "CPU" -command {
                    set previous $public(ash,sqldetails)
                    set public(ash,sqldetails) cpu
                    pack   forget $public(ash,output_frame).stats
                    pack   forget $public(ash,output_frame).txt
                    #cpu frame and scrollbar is packed in metrics  $public(ash,output_frame).f
                    #run cpumetrics embedded
                    cpumetrics $previous
                }

                pack  $sqlbuttons.txt -side left
                #pack  $sqlbuttons.plan -side left
                pack  $sqlbuttons.sqlio -side left
                pack  $sqlbuttons.stats -side left
                pack  $sqlbuttons.cpu -side left
                # don't pack ashrpt as too slow to respond and causes lockup
                # pack  $sqlbuttons.ashrpt -side left
        } err] } { puts "call $cur_proc, err:$err"; }
    }

    proc cbc_fetch { args } {
        global public
        set cur_proc cbc_fetch
        if { [ catch {
                $public(ash,output) delete 0.0 end
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 0 ] != "" } {
                        regsub "{" $row "" row
                        regsub "}" $row "" row
                        $public(ash,output) insert end "$row\n"
                    }
                }
                $public(ash,output) insert end "\n"
                $public(ash,output) insert end "\n"
                $public(ash,output) insert end "[ subst $public(sql,cbc) ] \n"
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
    }

    proc sqlio_fetch { args } {
        global public
        set cur_proc sqlio_fetch
        if { [ catch {
                $public(ash,output) delete 0.0 end
                $public(ash,output) insert end "IO wait events in the past 2 hours:\n"
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 0 ] != "" } {
                        set Total     [lindex $row 0]
                        set WaitEvent [lindex $row 1]
                        $public(ash,output) insert end "  $WaitEvent\t\t$Total\n"
                    }
                }
                $public(ash,output) insert end "\nQuery SQL:\n"
                $public(ash,output) insert end "[ subst $public(sql,sqlio) ] \n"
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
    }

    proc wait_analysis { id } {
        global public
        set cur_proc wait_analysis
        if { [ catch {
                pack forget $public(ash,details_buttons).sql
                pack forget $public(ash,output_frame).f
                pack forget $public(ash,output_frame).sv
                pack forget $public(ash,output_frame).stats
                pack $public(ash,output_frame).txt -side left -anchor nw
                pack $public(ash,details_buttons).wait -side left
                $public(ash,output) delete 0.0 end
                $public(ash,output) insert insert "Event: ${id} \n"
                set event_type [ get_event_type $id ]
                $public(ash,output) insert insert "Event Type: $event_type \n"
                set event_desc [ get_event_desc $id ]
                $public(ash,output) insert insert "Event Description: $event_desc \n"

                set public(ash,eventid) " wait_event = \'$id\' "
                update idletasks
                mon_execute ash_eventsqls
        } err] } { puts "call $cur_proc, err:$err"; }
    }

    proc connect_to_mysql {} {
        global public masterthread dbmon_threadID bm rdbms
        # Provider-aware: resolve the config dict (configmysql / configvillagesql)
        # and variable prefix (mysql / vsql) from the active $rdbms, so Database
        # Metrics for a MySQL-compatible fork (e.g. VillageSQL) connects with that
        # provider's settings instead of MySQL's. Falls back to MySQL when $rdbms
        # is unset or unknown, so the stock MySQL path is unchanged.
        set cfgname "configmysql"
        set p "mysql"
        if { [ info exists rdbms ] && $rdbms ne "" } {
            set fc [ find_config $rdbms ]
            set fp [ find_prefix $rdbms ]
            if { $fc ne "" } { set cfgname $fc }
            if { $fp ne "" } { set p $fp }
        }
        upvar #0 $cfgname config
        global ${p}_ssl_options
        setlocaltcountvars $config 1
        if ![ info exists ${p}_ssl_options ] { check_${p}_ssl $config }
        set public(connected) 0
        set public(host)        [ set ${p}_host ]
        set public(port)        [ set ${p}_port ]
        set public(socket)      [ set ${p}_socket ]
        set public(ssl_options) [ set ${p}_ssl_options ]
        if { $bm eq "TPC-C" } {
            set public(user)     [ set ${p}_user ]
            set public(user_pw)  [ quotemeta [ set ${p}_pass ] ]
            set public(tproc_db) [ set ${p}_dbase ]
        } else {
            set public(user)     [ set ${p}_tpch_user ]
            set public(user_pw)  [ quotemeta [ set ${p}_tpch_pass ] ]
            set public(tproc_db) [ set ${p}_tpch_dbase ]
        }

        if { ! [ info exists dbmon_threadID ] } {
            set public(parent) $masterthread
            mysql_dbmon_thread_init
	    #add zipfs paths to thread
            catch {eval [ subst {thread::send $dbmon_threadID {lappend ::auto_path [zipfs root]app/lib}}]}
            catch {eval [ subst {thread::send $dbmon_threadID {::tcl::tm::path add [zipfs root]app/modules modules}}]}
        } else {
            return 1
        }

        #Do logon in thread
        set db_type "default"
        thread::send -async $dbmon_threadID "mysql_logon $public(parent) $public(host) $public(port) {$public(socket)} {$public(ssl_options)} $public(user) $public(user_pw) $public(tproc_db) $db_type"

        test_connect_mysql
        if { [ info exists dbmon_threadID ] } {
            tsv::set application themonitor $dbmon_threadID
        }
    }

    proc putsm { message } {
        puts "$message"
    }

    proc mysql_dbmon_thread_init { } {
        global public dbmon_threadID

        set public(connected) 0
        set public(thread_actv) 0 ;# mutex, lock on this var for sq
        set dbmon_threadID [ thread::create {
            global tpublic

            proc just_disconnect { parent } {
                catch {thread::release}
            }

            proc mysql_logon { parent host port socket ssl_options user password db db_type} {
                thread::send $parent "putsm \"Metrics Connecting to host:$host port:$port\""
                set cur_proc mysql_logon
                set handle none
                set err "unknown"

                if { [ catch { package require mysqltcl} err ] } {
                    thread::send $parent "::callback_err \"mysqltcl load failed in Metrics\""
                    just_disconnect $parent
                    return
                }

                set handle [ ConnectToMySQL $parent $host $port $socket $ssl_options $user $password $db ]

                if { $handle eq "Failed" } {
                    just_disconnect $parent
                    return
                }

                if { $db_type == "default" } {
                    set ps_enabled 0
                    if { [ catch {
                            #Verify performance_schema is enabled
                            set ps_check [ mysql::sel $handle "SELECT @@performance_schema" -flatlist ]
                            if { [lindex $ps_check 0] == 1 } { set ps_enabled 1 }
                        } err ] } {
                        catch { mysql::close $handle }
                        thread::send -async $parent "::callback_err \"$err\""
                        just_disconnect $parent
                        return
                    }
                    if { !$ps_enabled } {
                        catch { mysql::close $handle }
                        thread::send -async $parent "::callback_err \"performance_schema is not enabled on this MySQL instance. Enable with performance_schema=ON in my.cnf and restart the server.\""
                        just_disconnect $parent
                        return
                    }
                    if { [ catch {
                            #Create ASH sampling schema and table if not exists
                            mysql::exec $handle "CREATE DATABASE IF NOT EXISTS hammerdb_ash"
                            mysql::exec $handle "CREATE TABLE IF NOT EXISTS hammerdb_ash.active_session_history (
                                ash_id BIGINT AUTO_INCREMENT PRIMARY KEY,
                                ash_time DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
                                thread_id BIGINT,
                                processlist_id BIGINT,
                                user VARCHAR(128),
                                host VARCHAR(261),
                                db VARCHAR(64),
                                command VARCHAR(16),
                                state VARCHAR(64),
                                wait_event_type VARCHAR(64),
                                wait_event VARCHAR(128),
                                sql_text TEXT,
                                digest_text TEXT,
                                digest VARCHAR(64),
                                INDEX idx_ash_time (ash_time),
                                INDEX idx_wait_event_type (wait_event_type),
                                INDEX idx_digest (digest)
                            ) ENGINE=InnoDB"
                            #Enable required performance_schema consumers for ASH data collection
                            catch { mysql::exec $handle "UPDATE performance_schema.setup_consumers SET ENABLED='YES' WHERE NAME IN ('events_waits_current', 'events_statements_current')" }
                            catch { mysql::exec $handle "UPDATE performance_schema.setup_instruments SET ENABLED='YES', TIMED='YES' WHERE NAME LIKE 'wait/%'" }
                            catch { mysql::exec $handle "UPDATE performance_schema.setup_instruments SET ENABLED='YES', TIMED='YES' WHERE NAME LIKE 'statement/%'" }
                            #Drop and recreate sampling event so schedule/filter changes apply when upgrading an existing hammerdb_ash
                            catch { mysql::exec $handle "DROP EVENT IF EXISTS hammerdb_ash.ash_sampler" }
                            mysql::exec $handle "CREATE EVENT IF NOT EXISTS hammerdb_ash.ash_sampler
                                ON SCHEDULE EVERY 5 SECOND
                                DO
                                INSERT INTO hammerdb_ash.active_session_history
                                (thread_id, processlist_id, user, host, db, command, state,
                                 wait_event_type, wait_event, sql_text, digest_text, digest)
                                SELECT
                                  t.THREAD_ID,
                                  t.PROCESSLIST_ID,
                                  t.PROCESSLIST_USER,
                                  t.PROCESSLIST_HOST,
                                  t.PROCESSLIST_DB,
                                  t.PROCESSLIST_COMMAND,
                                  t.PROCESSLIST_STATE,
                                  COALESCE(w.EVENT_NAME, CASE WHEN t.PROCESSLIST_STATE IS NOT NULL AND t.PROCESSLIST_STATE != '' THEN 'CPU' ELSE 'idle' END),
                                  COALESCE(w.EVENT_NAME, CASE WHEN t.PROCESSLIST_STATE IS NOT NULL AND t.PROCESSLIST_STATE != '' THEN 'CPU' ELSE 'idle/waiting' END),
                                  LEFT(s.SQL_TEXT, 4096),
                                  COALESCE(s.DIGEST_TEXT, LEFT(s.SQL_TEXT, 4096)),
                                  s.DIGEST
                                FROM performance_schema.threads t
                                LEFT JOIN performance_schema.events_waits_current w
                                  ON t.THREAD_ID = w.THREAD_ID AND w.EVENT_NAME != 'idle' AND w.END_EVENT_ID IS NULL
                                LEFT JOIN performance_schema.events_statements_current s
                                  ON t.THREAD_ID = s.THREAD_ID
                                WHERE t.TYPE = 'FOREGROUND'
                                  AND t.PROCESSLIST_COMMAND != 'Sleep'
                                  AND t.PROCESSLIST_COMMAND != 'Daemon'
                                  AND t.PROCESSLIST_ID IS NOT NULL
                                  AND (s.SQL_TEXT IS NULL OR s.SQL_TEXT NOT LIKE '%hammerdb_ash%')"
                            #Enable event scheduler
                            catch { mysql::exec $handle "SET GLOBAL event_scheduler = ON" }
                        } err ] } {
                        catch { mysql::close $handle }
                        thread::send -async $parent "::callback_err \"$err\""
                        just_disconnect $parent
                        return
                    }
                }

                thread::send -async $parent "::callback_connect $db_type $handle"
            }

            proc mysql_logoff { parent handle } {
                thread::send $parent "putsm \"Metrics Disconnect from MySQL...\""
                set cur_proc mysql_logoff
                set err "unknown"
                if { [ catch { mysql::close $handle } err ] } {
                    set err  [ join $err ]
                    thread::send -async $parent "::callback_err \"$err\""
                    just_disconnect $parent
                } else {
                    just_disconnect $parent
                }
            }

            proc ConnectToMySQL { parent host port socket ssl_options user password dbname } {
                global tcl_platform
                #Build connect string
                set connectstring ""
                if { [ string tolower $socket ] ne "null" && $socket ne "" && ![string match windows $tcl_platform(platform)] && ($host eq "127.0.0.1" || [ string tolower $host ] eq "localhost") } {
                    append connectstring " -socket $socket"
                } else {
                    append connectstring " -host $host -port $port"
                }
                foreach key [ dict keys $ssl_options ] {
                    append connectstring " $key [ dict get $ssl_options $key ] "
                }
                append connectstring " -user $user -password $password"
                set login_command "mysqlconnect $connectstring"
                if {[catch {set handle [eval $login_command]}]} {
                    set handle "Failed"
                    thread::send -async $parent "::callback_err \"MySQL connection to $host:$port failed\""
                } else {
                    catch { mysql::use $handle $dbname }
                }
                return $handle
            }

            proc mysql_sql {parent handle sql} {
                set cur_proc mysql_sql
                thread::send  $parent " ::callback_mesg $cur_proc "
                mysql::exec $handle $sql
                thread::send $parent " ::callback_mesg $cursor parsed"
            }

            proc mysql_all { parent handle cursor sql fetch } {
                global tpublic
                set cur_proc mysql_all

                thread::send -async $parent " ::callback_mesg $cur_proc "

                tsv::set fetched $cursor ""
                set result [tsv::object fetched $cursor]

                if {[catch {
                        set nrows [mysql::sel $handle $sql]
                        if { $nrows > 0 } {
                            set colnames [mysql::col $handle -current name]
                            array set colhash {}
                            set ci 0
                            foreach cn $colnames {
                                set colhash($cn) $ci
                                incr ci
                            }
                            set hashorder {}
                            foreach hn [array names colhash] {
                                lappend hashorder $colhash($hn)
                            }
                            for {set r 0} {$r < $nrows} {incr r} {
                                set row [mysql::fetch $handle]
                                set collist ""
                                foreach hi $hashorder {
                                    set collist "$collist \"[lindex $row $hi]\" "
                                }
                                $result append " [ list $collist ]"
                            }
                        }
                        thread::send -async $parent " ::callback_mesg \"sql parsed\""
                    } message]} {
                    thread::send $parent "putsm \"call mysql_all Query Failed, sql:$sql err:$message \""
                }

                thread::send -async $parent " ::callback_fetch $cursor $fetch"
            }

            thread::wait
            tsv::set application themonitor "QUIT"
        }]
    }

    proc callback_connect { db_type handle } {
        set cur_proc callback_connect
        global public
        #puts "call callback_connect db_type:$db_type, handle:$handle"
        if { $handle == -1 } {
            if { $db_type == "default" } {
                set public(connected) -1
            } else {
                set public(tproc_connected) -1
            }
        } else {
            if { $db_type == "default" } {
                set public(connected) 1
                set public(handle) $handle
            } else {
                set public(tproc_connected) 1
                set public(tproc_handle) $handle
            }
        }
    }

    proc callback_set { var args } {
        set cur_proc callback_set
        global public
        set $var $args
    }

    proc callback_fetch { cursor fetch} {
        set cur_proc callback_fetch
        eval $fetch [ list 1 [tsv::set fetched  $cursor] ]
    }

    proc callback_err { args } {
        global public
        set public(connected) "err"
        set cur_proc callback_err
        if { [ catch {
                puts "Database Metrics Error: [join $args]"
            } err ] } {
            set a 1
        }
    }

    proc callback_mesg { args } {
        set cur_proc callback_mesg
        if { [ catch { ; } err ] } {
            set a 1
        }
    }

    proc test_connect_mysql { } {
        global public dbmon_threadID
        variable firstconnect
        set cur_proc test_connect_mysql
        if { $public(connected) == "err" } {
            puts "Metrics Connection Failed: Verify Metrics Options"
            tsv::set application themonitor "QUIT"
            .ed_mainFrame.buttons.dashboard configure -state normal
            return 1
        }
        if { $public(connected) == -1 } {
            set public(connected) 0
            connect_to_mysql
            return
        }
        if { $public(connected) == 0 } {
            puts  "Waiting for Connection to MySQL for Database Metrics..."
            if { [ info exists dbmon_threadID ] } {
                if { [ thread::exists $dbmon_threadID ] } {
                    after 5000 test_connect_mysql
                }
            } else {
                #Thread died
                set public(connected) "err"
            }
        } else {
            if { $public(connected) == 1 } {
                puts "Metrics Connected"
                if { $firstconnect eq "true" } {
                    colors
                    init_publics
                    set_mysql_waits
                    set_mysql_events
                    set_mysqlcursors
                    set firstconnect "false"
                }
                create_metrics_screen
                mon_init
                .ed_mainFrame.buttons.dashboard configure -state normal
            } else {
                set public(connected) 0
                connect_to_mysql
            }
        }
    }

    proc lock { var  { proc unknown } } {
        global public
        set cur_proc lock
        if { [set $var] == 1 } {
            return 0
        } else {
            incr [set var]
            if { [set $var] != 1 } {
                incr [set var] -1
                return 0
            }
            return 1
        }
    }

    proc unlock { var { proc unknown } } {
        global public
        set cur_proc unlock
        incr [set var] -1
        if { [set $var] < 0 } {
            set [set var]  0
        }
    }

    proc cpucount_fetch { args } {
        global public
        set cur_proc cpucount_fetch
        if { [ catch {
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 0 ] != "" } {
                        set public(cpucount) [lindex $row 0]
                    }
                }
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
    }

    proc mysql_HowManyProcessorsWindows {} {
        global S cpu_model
        if [catch {package require twapi} ] {
        set ::S(cpus) 1
        return
        }
        set cpu_model [lindex [twapi::get_processor_info 0 -processorname] 1]
        set ::S(cpus) [twapi::get_processor_count]
        set proc_groups [ twapi::get_processor_group_config ]
        set max_groups [ dict get $proc_groups -maxgroupcount ]
        set active_groups [ dict size [ dict get $proc_groups -activegroups ] ]
        if { $active_groups > 1 } {
            puts "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
            puts "Windows system with multiple processors groups\nMaximum groups on this system $max_groups active groups $active_groups"
            for {set i 0} {$i < $active_groups} {incr i} {
                dict set proc_group_map $i [ dict get [ dict get $proc_groups -activegroups ] $i -activeprocessorcount ]
                puts -nonewline "Group $i has "
                puts -nonewline [ dict get $proc_group_map $i ]
                puts " active processors"
            }
            set numa_nodes [ twapi::get_numa_config ]
            set numa_node_count [ dict size $numa_nodes ]
            set cpus_per_node [ expr $::S(cpus) / $numa_node_count ]
            puts "System has $numa_node_count NUMA nodes and $cpus_per_node CPUs per node"
            for {set i 0} {$i < $numa_node_count} {incr i} {
                dict set numa_group_map $i [ dict get $numa_nodes $i -group ]
                puts -nonewline "NUMA node $i is in processor group "
                puts [ dict get $numa_group_map $i ]
            }
            puts "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"
        }
    }

    proc mysql_HowManyProcessorsLinux {} {
        global S cpu_model
        set fin [open /proc/cpuinfo r]
        set data [read $fin]; list
        close $fin
        set ::S(cpus) [llength [regexp -all -inline processor $data]]
        set ::S(cpus,list) {}
        for {set i 0} {$i < $::S(cpus)} {incr i} {
            lappend ::S(cpus,list) $i
        }
        foreach line [ split $data "\n" ] {
            if {[string match {model name*} $line]} {
                regexp {(.*):\ (.*)} $line all header cpu_model
                break
            }
        }
    }

    proc get_cpucount { } {
        global tcl_platform
        global S cpu_model
        global public
        set cur_proc get_cpucount

        if { [ catch {
                if {$tcl_platform(platform) == "windows"} {
                    mysql_HowManyProcessorsWindows
                    #global env
                    #set public(cpucount) $env(NUMBER_OF_PROCESSORS)
                } else {
                    mysql_HowManyProcessorsLinux
                    #set public(cpucount) [ exec grep "processor" /proc/cpuinfo | wc -l ]
                }
                set public(cpucount) $S(cpus)
                #puts "call $cur_proc cpucount:$public(cpucount)"
        } err] } { ; }
        unlock public(thread_actv) $cur_proc
    }

    proc version_fetch { args } {
        global public
        set cur_proc version_fetch
        if { [ catch {
                foreach row [ lindex $args 1 ] {
                    if { [ lindex $row 0 ] != "" } {
                        set public(version) [lindex $row 0]
                        #set public(dbname)  [lindex $row 1]
                        #set public(machine) [lindex $row 2]
                    }
                    regsub {\..*} $public(version) "" version
                    if { $version < 10 } {
                    }
                }
        } err] } { puts "call $cur_proc, err:$err"; }
        unlock public(thread_actv) $cur_proc
    }

    proc mon_init { } {
        global public
        set cur_proc mon_init
        set public(visible) ""
        mon_execute days
        mon_execute version
        #####
        #Check to see if there is data in the ASH
        #Need to set public(run) here for mon_execute ash_empty
        #This is also set later
        set public(run) 1
        set public(ashrowcount) 0
        mon_execute ashempty
        if { [ concat $public(ashrowcount) ] eq 0  || $public(ashrowcount) eq "" } {
            #There is no data in the Active Session History
            puts "Metrics Error: No rows found in hammerdb_ash.active_session_history,run a workload to populate metrics"
            #reset the GUI
            ed_kill_metrics
            ed_metrics_button
            #Deactivate the metrics button
            .ed_mainFrame.buttons.dashboard config -image [ create_image dashboard icons ] -command "metrics"
            set public(run) 0
            return
            ########
        } else {
            puts "Starting Metrics, read [ join $public(ashrowcount) ] rows from hammerdb_ash.active_session_history"
        }
        #mon_execute cpucount
        #cpucount cannot be retrieved by MySQL. Cpucount is limited to running in the client.
        get_cpucount
        mon_loop
        ash_init 1
    }

    proc mon_loop { } {
        global public
        set cur_proc mon_loop
        set monstatus [ tsv::get application themonitor ]
        if { $monstatus eq "QUIT" || $monstatus eq "NOWVUSER" } {
            after cancel mon_loop
        }
        if { $public(run) == 1 } {
            set public(slow_cur) [ expr $public(sleep,fast) + $public(slow_cur) ]
            set slow ""
            set fast ""
            regsub  -all {cursor,}  [ array names public cursor,* ]  ""  cursors
            foreach i $cursors {
                if { $public(cursor,$i) == "slow" } { set slow "$slow $i" }
                if { $public(cursor,$i) == "fast" } { set fast "$fast $i" }
            }
            foreach i "secs $fast " { mon_execute $i }
            if { $public(slow_cur) >= $public(sleep,slow) } {
                set public(slow_cur) [ expr  $public(slow_cur) - $public(sleep,slow) ]
                foreach i $slow { mon_execute $i }
            }
            update idletasks
            after [ expr $public(sleep,fast) * 1000 ]  mon_loop
        } else {
            after cancel mon_loop
        }
    }

    proc mon_execute { i { backoff 1000 } } {
        global public dbmon_threadID
        set cur_proc mon_execute
        #puts "call $cur_proc $i"
        if { $public(run) == 1 } {
            if { [ lock public(thread_actv) $cur_proc:$i ] } {
                if { [ catch {
                        eval set sql \"$public(sql,$i)\"
                    } err ] } {
                    foreach sql [ array names public "sql,*" ] { ; }
                }
                set crsr "crsr,$i"
                if { [ catch {
                        set fetch [set i]_fetch
                        #if { $i == "ash_sqlplan" } {
                            #  thread::send -async $dbmon_threadID "mysql_all $public(parent) $public(tproc_handle) $crsr \"$sql\" $fetch"
                        #} else {
                            thread::send -async $dbmon_threadID "mysql_all $public(parent) $public(handle) $crsr \"$sql\" $fetch"
                        #}
                    } err ] } {
                    puts "call mon_execute error:$err"
                    unlock public(thread_actv) $cur_proc:$i
                    global errorInfo
                }
                vwait public(thread_actv)
                set public(wait,$cur_proc,$i) 0
            }
        }
    }

    proc set_mysql_waits {} {
        global public
        #MySQL performance_schema wait categories
        set public(waits,CPU) CPU
        set public(waits,BCPU) CPU

        #Wait class mappings for MySQL wait event names
        #idle waits
        set public(waits,idle) Idle
        set public(waits,idle/waiting) Idle

        #wait/synch/mutex
        set public(waits,wait/synch/mutex) Mutex

        #wait/synch/rwlock
        set public(waits,wait/synch/rwlock) RWLock

        #wait/synch/cond
        set public(waits,wait/synch/cond) Cond

        #wait/synch/sxlock
        set public(waits,wait/synch/sxlock) SXLock

        #wait/io/file
        set public(waits,wait/io/file) File_IO

        #wait/io/table
        set public(waits,wait/io/table) Table_IO

        #wait/io/socket
        set public(waits,wait/io/socket) Network

        #wait/lock/table
        set public(waits,wait/lock) Lock

        #wait/lock/metadata
        set public(waits,wait/lock/metadata) Lock

        #wait/lock/table/sql/handler
        set public(waits,wait/lock/table) Lock

        #Top-level category types
        set public(waits,Mutex) wait_event_type
        set public(waits,RWLock) wait_event_type
        set public(waits,Cond) wait_event_type
        set public(waits,SXLock) wait_event_type
        set public(waits,File_IO) wait_event_type
        set public(waits,Table_IO) wait_event_type
        set public(waits,Network) wait_event_type
        set public(waits,Lock) wait_event_type
        set public(waits,Idle) wait_event_type
        set public(waits,Other) wait_event_type
    }

    proc set_mysql_events {} {
        global public

        set public(events,CPU) "Session active on CPU."

        #Idle
        set public(events,idle) "Thread idle, waiting for next command."
        set public(events,idle/waiting) "Thread idle, waiting for next command."

        #Mutex
        set public(events,wait/synch/mutex) "Waiting on a mutex synchronization object."

        #RWLock
        set public(events,wait/synch/rwlock) "Waiting on a read/write lock."

        #Cond
        set public(events,wait/synch/cond) "Waiting on a condition variable."

        #SXLock
        set public(events,wait/synch/sxlock) "Waiting on a shared-exclusive lock."

        #File_IO
        set public(events,wait/io/file) "Waiting for a file I/O operation."

        #Table_IO
        set public(events,wait/io/table) "Waiting for a table I/O operation."

        #Network
        set public(events,wait/io/socket) "Waiting for a network socket operation."

        #Lock
        set public(events,wait/lock) "Waiting for a metadata or table lock."
        set public(events,wait/lock/metadata) "Waiting for a metadata lock."
        set public(events,wait/lock/table) "Waiting for a table lock."
    }

    proc get_event_type { event } {
        global public
        set event_type "N/A"
        #Direct match first
        if {[info exists public(waits,$event)]} {
            return $public(waits,$event)
        }
        #MySQL wait events are hierarchical (wait/io/file/innodb/...)
        #Try prefix matching for classification
        if { $event eq "CPU" || $event eq "cpu" } { return "CPU" }
        if { $event eq "BCPU" || $event eq "bcpu" } { return "BCPU" }
        if { [string match "idle*" $event] } { return "Idle" }
        if { [string match "wait/synch/mutex/*" $event] } { return "Mutex" }
        if { [string match "wait/synch/rwlock/*" $event] } { return "RWLock" }
        if { [string match "wait/synch/cond/*" $event] } { return "Cond" }
        if { [string match "wait/synch/sxlock/*" $event] } { return "SXLock" }
        if { [string match "wait/io/file/*" $event] } { return "File_IO" }
        if { [string match "wait/io/table/*" $event] } { return "Table_IO" }
        if { [string match "wait/io/socket/*" $event] } { return "Network" }
        if { [string match "wait/lock/*" $event] } { return "Lock" }
        if {![info exists public(unknown_waits,$event)]} {
            set public(unknown_waits,$event) 1
        }
        return $event_type
    }

    proc get_event_desc { event } {
        global public
        set event_desc "N/A"
        if {[info exists public(events,$event)]} {
            return $public(events,$event)
        }
        #Try prefix matching for MySQL hierarchical events
        if { $event eq "CPU" || $event eq "cpu" } { return "Session active on CPU." }
        if { [string match "idle*" $event] } { return "Thread idle, waiting for next command." }
        if { [string match "wait/synch/mutex/*" $event] } { return "Waiting on mutex: $event" }
        if { [string match "wait/synch/rwlock/*" $event] } { return "Waiting on read/write lock: $event" }
        if { [string match "wait/synch/cond/*" $event] } { return "Waiting on condition: $event" }
        if { [string match "wait/synch/sxlock/*" $event] } { return "Waiting on shared-exclusive lock: $event" }
        if { [string match "wait/io/file/*" $event] } { return "Waiting on file I/O: $event" }
        if { [string match "wait/io/table/*" $event] } { return "Waiting on table I/O: $event" }
        if { [string match "wait/io/socket/*" $event] } { return "Waiting on network socket: $event" }
        if { [string match "wait/lock/*" $event] } { return "Waiting on lock: $event" }
        if {![info exists public(unknown_events,$event)]} {
            set public(unknown_events,$event) 1
        }
        return $event_desc
    }

    proc set_mysqlcursors {} {
        global public

        set public(sql,cpucount) ""

        set public(sql,ashempty) "SELECT count(*) FROM hammerdb_ash.active_session_history;"

        set public(sql,version) "SELECT version();"

        set public(sql,ashrpt) ""

        set public(sql,days) "SELECT TO_DAYS(NOW()) as days;"

        set public(sql,secs) "SELECT TIME_TO_SEC(TIME(NOW())) as secs;"

        set public(sql,ashtime) "SELECT TO_DAYS(DATE_SUB(sample_time, INTERVAL \$public(ash,loadhours) HOUR)) as day,
      TIME_TO_SEC(TIME(DATE_SUB(sample_time, INTERVAL \$public(ash,loadhours) HOUR))) as secs,
      CEILING(UNIX_TIMESTAMP(sample_time)) as sample_id
    FROM ( SELECT MAX(ash_time) as sample_time FROM hammerdb_ash.active_session_history) as st;"

        set public(sql,ash) "SELECT MAX(TIME_TO_SEC(TIME(ash.ash_time))) as secs, ash.sample_id,
      ash.wait_event_type,
      ROUND(COUNT(*)/GREATEST(ash.samples,1),3) as AAS,
      FLOOR(TIME_TO_SEC(TIME(ash.ash_time))/ash.bucket)*ash.bucket as beg_secs,
      (FLOOR(TIME_TO_SEC(TIME(ash.ash_time))/ash.bucket)+1)*ash.bucket as end_secs,
      TO_DAYS(NOW()) as last_day, TO_DAYS(MIN(ash.ash_time)) as first_day
    FROM (SELECT ash_time,
        CASE
          WHEN wait_event_type LIKE 'wait/synch/mutex%' THEN 'Mutex'
          WHEN wait_event_type LIKE 'wait/synch/rwlock%' THEN 'RWLock'
          WHEN wait_event_type LIKE 'wait/synch/cond%' THEN 'Cond'
          WHEN wait_event_type LIKE 'wait/synch/sxlock%' THEN 'SXLock'
          WHEN wait_event_type LIKE 'wait/io/file%' THEN 'File_IO'
          WHEN wait_event_type LIKE 'wait/io/table%' THEN 'Table_IO'
          WHEN wait_event_type LIKE 'wait/io/socket%' THEN 'Network'
          WHEN wait_event_type LIKE 'wait/lock%' THEN 'Lock'
          WHEN wait_event_type LIKE 'idle%' THEN 'Idle'
          WHEN wait_event_type = 'CPU' THEN 'CPU'
          ELSE 'Other'
        END as wait_event_type, wait_event,
        CEILING(UNIX_TIMESTAMP(MAX(ash_time) OVER()) - UNIX_TIMESTAMP(MIN(ash_time) OVER())) as samples,
        CEILING(UNIX_TIMESTAMP(ash_time)) as sample_id, \$public(ash,bucket_secs) as bucket
      FROM hammerdb_ash.active_session_history WHERE \$public(ash,where) AND
      ash_time >= DATE_SUB(NOW(), INTERVAL \$public(ash,bucket_secs) SECOND)) ash
    GROUP BY ash.samples,ash.sample_id,ash.wait_event_type,ash.ash_time,ash.bucket ORDER BY ash.ash_time;"

        set public(sql,ash_sqltxt) "SELECT sql_text FROM hammerdb_ash.active_session_history WHERE \$public(ash,sqlid) ORDER BY ash_time DESC LIMIT 1;"

        set public(sql,ash_sqlplanx) ""

        set public(sql,ash_sqlplan) "EXPLAIN \$public(ash,sqltxt);"

        set public(sql,ash_sqlstats) "SELECT calls, total_exec_time,
      rows_affected, rows_sent, rows_examined, tmp_tables,
      tmp_disk_tables, select_scan, select_full_join, sort_rows,
      no_index_used FROM (
      SELECT COUNT_STAR as calls,
      SUM_TIMER_WAIT/1000000000 as total_exec_time,
      SUM_ROWS_AFFECTED as rows_affected,
      SUM_ROWS_SENT as rows_sent,
      SUM_ROWS_EXAMINED as rows_examined,
      SUM_CREATED_TMP_TABLES as tmp_tables,
      SUM_CREATED_TMP_DISK_TABLES as tmp_disk_tables,
      SUM_SELECT_SCAN as select_scan,
      SUM_SELECT_FULL_JOIN as select_full_join,
      SUM_SORT_ROWS as sort_rows,
      SUM_NO_INDEX_USED as no_index_used
    FROM performance_schema.events_statements_summary_by_digest WHERE DIGEST IN (
      SELECT DISTINCT digest FROM hammerdb_ash.active_session_history WHERE \$public(ash,sqlid) AND digest IS NOT NULL)
    OR DIGEST_TEXT IN (
      SELECT DISTINCT digest_text FROM hammerdb_ash.active_session_history WHERE \$public(ash,sqlid) AND digest_text IS NOT NULL)
    UNION ALL
      SELECT COUNT(*) as calls, 0 as total_exec_time,
      0 as rows_affected, 0 as rows_sent, 0 as rows_examined,
      0 as tmp_tables, 0 as tmp_disk_tables, 0 as select_scan,
      0 as select_full_join, 0 as sort_rows, 0 as no_index_used
    FROM hammerdb_ash.active_session_history WHERE \$public(ash,sqlid) AND sql_text IS NOT NULL
    ) combined ORDER BY calls DESC LIMIT 1;"

        set public(sql,ash_eventsqls) "SELECT count(*) as total, sql_text, wait_event, command
    FROM hammerdb_ash.active_session_history WHERE \$public(ash,eventid) AND
      ash_time >= FROM_UNIXTIME(\$public(ash,beg)) AND
      ash_time <= FROM_UNIXTIME(\$public(ash,end))
      GROUP BY sql_text, wait_event, command ORDER BY total DESC LIMIT 10;"

        set public(sql,ash_sqlevents) "SELECT count(*) as total, wait_event_type, wait_event
    FROM hammerdb_ash.active_session_history
    WHERE ash_time >= FROM_UNIXTIME(\$public(ash,beg)) AND
          ash_time <= FROM_UNIXTIME(\$public(ash,end))
    GROUP BY wait_event_type, wait_event ORDER BY total DESC;"

                    set public(sql,ash_sqlsessions) "SELECT processlist_id as pid, count(*) as Total,
        SUM(CASE WHEN wait_event_type LIKE 'wait/synch/mutex%' THEN 1 ELSE 0 END) as Mutex,
        SUM(CASE WHEN wait_event_type LIKE 'wait/synch/rwlock%' THEN 1 ELSE 0 END) as RWLock,
        SUM(CASE WHEN wait_event_type LIKE 'wait/synch/cond%' THEN 1 ELSE 0 END) as Cond,
        SUM(CASE WHEN wait_event_type LIKE 'wait/synch/sxlock%' THEN 1 ELSE 0 END) as SXLock,
        SUM(CASE WHEN wait_event_type LIKE 'wait/io/file%' THEN 1 ELSE 0 END) as File_IO,
        SUM(CASE WHEN wait_event_type LIKE 'wait/io/table%' THEN 1 ELSE 0 END) as Table_IO,
        SUM(CASE WHEN wait_event_type LIKE 'wait/io/socket%' THEN 1 ELSE 0 END) as Network,
        SUM(CASE WHEN wait_event_type LIKE 'wait/lock%' THEN 1 ELSE 0 END) as \`Lock\`,
        SUM(CASE WHEN wait_event_type LIKE 'idle%' THEN 1 ELSE 0 END) as Idle,
        SUM(CASE WHEN wait_event_type = 'CPU' THEN 1 ELSE 0 END) as CPU,
        user, host
        FROM hammerdb_ash.active_session_history
        WHERE ash_time >= FROM_UNIXTIME(\$public(ash,beg)) AND
        ash_time <= FROM_UNIXTIME(\$public(ash,end))
        GROUP BY processlist_id, user, host ORDER BY total DESC;"

                    set public(sql,ash_sqldetails) "SELECT digest as QueryID, count(*) as Total,
        SUM(CASE WHEN wait_event_type LIKE 'wait/synch/mutex%' THEN 1 ELSE 0 END) as Mutex,
        SUM(CASE WHEN wait_event_type LIKE 'wait/synch/rwlock%' THEN 1 ELSE 0 END) as RWLock,
        SUM(CASE WHEN wait_event_type LIKE 'wait/synch/cond%' THEN 1 ELSE 0 END) as Cond,
        SUM(CASE WHEN wait_event_type LIKE 'wait/synch/sxlock%' THEN 1 ELSE 0 END) as SXLock,
        SUM(CASE WHEN wait_event_type LIKE 'wait/io/file%' THEN 1 ELSE 0 END) as File_IO,
        SUM(CASE WHEN wait_event_type LIKE 'wait/io/table%' THEN 1 ELSE 0 END) as Table_IO,
        SUM(CASE WHEN wait_event_type LIKE 'wait/io/socket%' THEN 1 ELSE 0 END) as Network,
        SUM(CASE WHEN wait_event_type LIKE 'wait/lock%' THEN 1 ELSE 0 END) as \`Lock\`,
        SUM(CASE WHEN wait_event_type LIKE 'idle%' THEN 1 ELSE 0 END) as Idle,
        SUM(CASE WHEN wait_event_type = 'CPU' THEN 1 ELSE 0 END) as CPU,
        command as CmdType
        FROM hammerdb_ash.active_session_history
        WHERE digest IS NOT NULL AND
        ash_time >= FROM_UNIXTIME(\$public(ash,beg)) AND
        ash_time <= FROM_UNIXTIME(\$public(ash,end))
        GROUP BY digest, command ORDER BY total DESC;"

                    set public(sql,sqlovertimeload) "SELECT last_id,
        TO_DAYS(last_time) as last_day, cnt,
        TIME_TO_SEC(TIME(last_time)) as last_secs,
        wait_event_type
        FROM (
        SELECT wait_event_type,
        MAX(ash_time) as last_time,
        COUNT(*) as cnt,
        MAX(sample_id) as last_id,
        modsecs
        FROM (
        SELECT
        ash_time,
        CEILING(UNIX_TIMESTAMP(ash_time)) as sample_id,
        FLOOR(TIME_TO_SEC(TIME(ash_time))/\$public(ashsql,bucket_secs)) as modsecs,
        CASE
          WHEN wait_event_type LIKE 'wait/synch/mutex%' THEN 'Mutex'
          WHEN wait_event_type LIKE 'wait/synch/rwlock%' THEN 'RWLock'
          WHEN wait_event_type LIKE 'wait/synch/cond%' THEN 'Cond'
          WHEN wait_event_type LIKE 'wait/synch/sxlock%' THEN 'SXLock'
          WHEN wait_event_type LIKE 'wait/io/file%' THEN 'File_IO'
          WHEN wait_event_type LIKE 'wait/io/table%' THEN 'Table_IO'
          WHEN wait_event_type LIKE 'wait/io/socket%' THEN 'Network'
          WHEN wait_event_type LIKE 'wait/lock%' THEN 'Lock'
          WHEN wait_event_type LIKE 'idle%' THEN 'Idle'
          WHEN wait_event_type = 'CPU' THEN 'CPU'
          ELSE 'Other'
        END as wait_event_type
        FROM hammerdb_ash.active_session_history
        WHERE ash_time > FROM_UNIXTIME(\$public(ash,starttime)) AND \$public(ashsql,sqlovertimeid)
        ) ash
        GROUP BY wait_event_type, modsecs
        ORDER BY last_time, modsecs
        ) as last;"

                    set public(sql,stat) ""

                    set public(sql,txrlc) ""

                    set public(sql,bbw) ""

                    set public(sql,hw) ""

                    set public(sql,cbc) ""

                    set public(sql,sqlio) "SELECT wait_event, count(*) as total
        FROM hammerdb_ash.active_session_history WHERE wait_event_type LIKE 'wait/io%' AND
        ash_time>=DATE_SUB(NOW(), INTERVAL \$public(ash,loadhours) HOUR)
        GROUP BY wait_event ORDER BY total DESC;"

                    set public(sql,io) ""
                }

                proc init_publics {} {
                    global env public defaultBackground
                    set PWD [ pwd ]
                    regsub -all {/bin}  $PWD   ""  env(MON_HOME)

                    set public(debug_level)          0
                    set public(debug_to_file)        0
                    set public(debug_thread_to_file) 0
                    set public(sleep,fast) 15
                    set public(sleep,med)  15
                    set public(sleep,slow) 60
                    set public(slow_cur)   0
                    set public(OS)         NT
                    set public(logdir)          [set env(MON_HOME)]/log
                    set env(FUNCS)              [set env(MON_HOME)]/src/generic
                    set env(MON_BIN)            [set env(MON_HOME)]/bin
                    set env(MON_SHARED_LIB)     [set env(MON_HOME)]/bin
                    set env(BLT_LIBRARY)        [set env(MON_HOME)]/lib/blt3.2
                    set env(TCL_LIBRARY)        [set env(MON_HOME)]/lib/tcl8.6
                    set env(TK_LIBRARY)         [set env(MON_HOME)]/lib/tk8.6
                    set public(public) {
                        sleep,fast
                        sleep,slow
                        debug_level
                        debug_to_file
                        debug_thread_to_file
                        ash,bucket_secs
                        ash,keep_secs
                        [array names public collect* ]
                    }
                    set public(run)  1
                    set public(xdollar)   {x\\\\\\\$}
                    set public(vdollar)   {v\\\\\\\$}
                    set public(xdollar)   x
                    set public(vdollar)   v
                    set public(ashtable)  "v\\\\\\\$ash"
                    set public(versiontable)  "$public(vdollar)\\\\\\\$version"
                    set public(eventnamestable)  "$public(vdollar)\\\\\\\$version"
                    set public(ashtable)  sash
                    set public(versiontable)  sash_targets
                    set public(eventnamestable)  sash_eventnames
                    set public(rmargin)   25
                    set public(lmargin)   150
                    set public(error)  ""
                    set public(pale_burgundy)     #895D5B
                    set public(pale_blue)         #5D8894
                    set public(pale_green)        #96BE7A
                    set public(pale_grey)         #D8DDE5
                    set public(pale_warmgrey)     #ECE9E9
                    set public(pale_ochre)        #DEBA84
                    set public(pale_brown)        #EFD0B2
                    set public(pale_ochre)        #FECA58
                    set public(pale_brown)        #F0A06A
                    if { [ string match "*dark*" $::ttk::currentTheme ] } {
                    set public(fg)        white
                    set public(bg)        black
                    set public(graphselect) $defaultBackground
                    } else {
                    set public(fg)        black
                    set public(bg)        white
                    set public(graphselect) #E0E0E0
                    }
                    set public(bgt)       $defaultBackground
                    set public(fga)       yellow
                    set public(fgsm)      $public(pale_warmgrey)
                    set public(bgsm)      #A0B0D0
                    set public(smallfont) [ list basic [ expr [ font actual basic -size ] - 3 ] ]
                    set public(medfont) [ list basic [ expr [ font actual basic -size ] - 2 ] ]
                    if {[winfo depth .] > 1} {
                        set public(bold) "-background #43ce80 -relief raised -borderwidth 1"
                        set public(normal) "-background {} -relief flat"
                    } else {
                        set public(bold) "-foreground white -background black"
                        set public(normal) "-foreground {} -background {}"
                    }
                    set public(main)    .ed_mainFrame.me.m
                    set public(menu)     $public(main).menu
                    set public(screen)   $public(main).f
                    set public(type)    none
                    set public(rows) 100
                    set public(cols) 100
                    set public(ash,cascade) 0
                    set public(ash,load_bucket_secs) 15
                    set public(ashsql,bucket_secs) $public(ash,load_bucket_secs)
                    set public(ash,bucket_secs) $public(sleep,fast)
                    set public(ash,loadhours) 2
                    set public(public) "$public(public) ash,loadhours "
                    set public(ash,keep_secs) [ expr $public(ash,loadhours) * 3600 ]
                    set public(ash,ticks) 10
                    set public(ash,ticksize) [ expr $public(ash,keep_secs)/$public(ash,ticks) ]
                    set public(ash,overtimeid)  ""
                    set public(ash,view) overview
                    set public(ash,sqldetails)  txt
                    set public(ash,TYPE)  "bar"
                    set public(ash,xmin)  2
                    set public(p_x) 600
                    set public(p_y) 654
                    set public(ash,delta) -1
                    set public(ash,sample_id) -1
                    set public(ash,first) -1
                    set public(colors,count) 1
                }

                proc mysql_post_kill_dbmon_cleanup {} {
                    global public dbmon_threadID
                    .ed_mainFrame.buttons.dashboard configure -state disabled
                    set public(connected) "err"
                    set public(run) 0
                    if { [ tsv::get application themonitor ] eq "NOWVUSER" } {
    #threadid has already been grabbed by a vuser so does not need cleanup
                    } else {
                        if { [ info exists dbmon_threadID ]} {
                            if { [ thread::exists $dbmon_threadID ] } {
                                if { [ info exists public(handle) ] } {
          #logoff also calls just_disconnect so release thread inside and cancel from outside
                                    thread::send -async $dbmon_threadID "mysql_logoff $public(parent) $public(handle)"
                                    tsv::set application themonitor "QUIT"
                                    catch {thread::cancel $dbmon_threadID}
                                } else {
                                    thread::send -async $dbmon_threadID "just_disconnect $public(parent)"
                                    catch {thread::cancel $dbmon_threadID}
                                }
                            }
                        }
    #thread logoff and disconnect asynch so may not have closed by this point
                        if { ![ thread::exists $dbmon_threadID ] } {
                            puts "Metrics Closed\n"
                            unset -nocomplain dbmon_threadID
                            tsv::set application themonitor "READY"
                            .ed_mainFrame.buttons.dashboard configure -state normal
                        } else {
      #puts "Warning: Metrics connection remains active"
                            after 2000 mysql_post_kill_dbmon_cleanup
                        }
                    }
                }

                proc mysqlmetrics { } {
                    global env public mysqlmetrics_firstrun dbmon_threadID
                    set monlist [ thread::names ]
                    if { [ info exists dbmon_threadID ] } {
                        set monstatus [ tsv::get application themonitor ]
                        if { $monstatus eq "QUIT" || $monstatus eq "NOWVUSER" } {
                            .ed_mainFrame.buttons.dashboard configure -state normal
                            unset -nocomplain dbmon_threadID
                        } else {
                            set answer [tk_messageBox -type yesno -icon question -message "Database Monitor active in background\nWait for Monitor to finish?" -detail "Yes to remain active, No to terminate"]
                            switch $answer {
                                yes { return }
                                no {
                                    set public(connected) "err"
                                    mysql_post_kill_dbmon_cleanup
                                    return
                                }
                            }
                        }
                    } else {
    #dbmon_threadID doesn't exist
                        ;
                    }
                    ed_status_message -finish "... Starting Metrics ..."
                    ed_stop_metrics
                    .ed_mainFrame.buttons.dashboard configure -state disabled
                    connect_to_mysql
                }
            }
