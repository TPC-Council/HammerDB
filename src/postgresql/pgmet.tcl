namespace eval pgmet {
namespace export create_metrics_screen display_tile display_only colors1 colors2 colors getcolor geteventcolor getlcolor generic_time cur_time secs_fetch days_fetch ash_init reset_ticks ashempty_fetch ashtime_fetch ses_tbl sql_tbl emptyStr stat_tbl plan_tbl evt_tbl createSesFrame createSqlFrame createevtFrame create_ash_cpu_line ash_bars ash_displayx ash_fetch ash_details ash_sqldetails_fetch ash_sqlsessions_fetch ash_sqltxt ashrpt_fetch ash_sqltxt_fetch ash_sqlstats_fetch ash_sqlplan_fetch ash_eventsqls_fetch ash_sqlevents_fetch sqlovertime_fetch sqlovertime ashsetup vectorsetup addtabs graphsetup outputsetup waitbuttons_setup sqlbuttons_setup cbc_fetch sqlio_fetch wait_analysis connect_to_postgresql putsm pg_dbmon_thread_init just_disconnect pg_logon pg_logoff ConnectToPostgres pg_sql pg_all callback_connect callback_set callback_fetch callback_err callback_mesg test_connect_pg lock unlock cpucount_fetch pg_HowManyProcessorsWindows pg_HowManyProcessorsLinux get_cpucount version_fetch mon_init mon_loop mon_execute set_pg_waits set_pg_events get_event_type get_event_desc set_pgcursors init_publics pg_post_kill_dbmon_cleanup pgmetrics

variable firstconnect "true"

proc create_metrics_screen { } {
  global public metframe win_scale_fact
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
    frame $main -background $public(bg) -borderwidth 0 
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
    $public(ash,sqltbl) configure -selectbackground #FF7900
    $public(ash,sqltbl) configure -selectforeground black 
    $public(ash,sqltbl) configure -activestyle none 
  #} err ] } { ; }
}

# For zooming in and out, resets the miminum point on X axis
proc reset_ticks { } {
  global x_w_ash
  global public
  # number of seconds to display on the graph, ie width
  # ash,xmin is a factor, ie sho 2x the number of seconds or 1/2 
  set secs [ expr $public(ash,xmin) * 3600 ]
  set max $x_w_ash(end)
  # take maximum dispaly point, in seconds and subtrct the width, this is min point
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

    set public(ash,starttime) "${day} ${secs}"
    set public(ash,startday) "${day}"
    # ash,time used just below in cursor where clause in variable ash,where
    set public(ash,time) "${day} ${secs}"
    set public(ash,day)  "$day"
    set public(ash,secs) "$secs"
    set public(ash,sample_id) "$sample_id"
    # secs is not needed here, gets set again and used in ash_fetch 
  } err] } { puts "call $cur_proc, err:$err"; } 
  unlock public(thread_actv) $cur_proc
  set public(ash,bucket_secs)
  set public(ash,where) "ash_time > to_timestamp('$public(ash,time)','J SSSS')"
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
         -background white \
         -columns " $collist " \
         -labelrelief flat \
         -font $public(medfont) -setgrid no \
         -yscrollcommand [list $vsb set] \
         -width $ncols  -height $nrows -stretch all
  bind [$tbl bodytag] <Button-1> {
    foreach {tablelist::W tablelist::x tablelist::y} [tablelist::convEventFields %W %x %y] {}
    if { [ $public(ash,sestbl) containing $tablelist::y] > -1 } {
      set id  [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],sid -text]

      set LWLock    [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],LWLock -text]
      set Lock      [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],Lock -text]
      set BufferPin [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],BufferPin -text]
      set Activity  [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],Activity -text]
      set Extension [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],Extension -text]
      set Client    [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],Client -text]
      set IPC       [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],IPC -text]
      set Timeout   [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],Timeout -text]
      set System_IO [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],System_IO -text]
      set IO        [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],IO -text]
      set CPU       [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],CPU -text]
      set BCPU      [ $public(ash,sestbl) cellcget [ $public(ash,sestbl) containing [subst $tablelist::y]],BCPU -text]
      #puts "call ses_tbl, CPU:$CPU, BCPU:$BCPU, LWLock:$LWLock"

      $public(ash,sestbl) cellselection clear 0,0 end,end
      $public(ash,sestbl) configure -selectbackground  white
      $public(ash,sestbl) configure -selectforeground  black 
      $public(ash,output) delete 0.0 end
      #$public(ash,output) insert  insert "   working ... "
      pack forget $public(ash,details_buttons).sql
      pack forget $public(ash,output_frame).f
      pack forget $public(ash,output_frame).sv
      pack forget $public(ash,output_frame).stats
      pack $public(ash,output_frame).txt -side left -anchor nw
      pack $public(ash,details_buttons).wait -side left

      $public(ash,output) insert  insert "Statistic of wait events for the process $id\n\n"
      $public(ash,output) insert  insert "CPU:\t\t$CPU \nBCPU:\t\t$BCPU \nIO:\t\t$IO \nSystem_IO:\t\t$System_IO \nTimeout:\t\t$Timeout \nLWLock:\t\t$LWLock \nLock:\t\t$Lock \nBufferPin:\t\t$BufferPin \nActivity:\t\t$Activity \nExtension:\t\t$Extension \nClient:\t\t$Client \nIPC:\t\t$IPC \n"
      update idletasks
      clipboard clear
      clipboard append $id
    } else {
      $public(ash,sestbl) cellselection clear 0,0 end,end
      $public(ash,sestbl) configure -selectbackground  white
      $public(ash,sestbl) configure -selectforeground  black
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
    -background white \
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
        $public(ash,sqltbl) configure -selectbackground #FF7900 
        $public(ash,sqltbl) configure -selectforeground black 
        update idletasks
        sqlovertime $id
        set public(ash,overtimeid) -1
      } else { 
        $public(ash,sqltbl) configure -selectbackground #FF7900
        $public(ash,sqltbl) configure -selectforeground black 
        update idletasks
        set public(ash,overtimeid) $id 
        sqlovertime clear
      }
    } else {
      $public(ash,sqltbl) cellselection clear 0,0 end,end
      $public(ash,sqltbl) configure -selectbackground white
      $public(ash,sqltbl) configure -selectforeground black 
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
    -background white \
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
    -background white \
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
    -background white \
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
      $public(ash,evttbl) configure -selectbackground  white
      $public(ash,evttbl) configure -selectforeground  black 
      $public(ash,output) delete 0.0 end
      #$public(ash,output) insert insert "   working ... "
      $public(ash,output) insert insert "   session id $id "
      wait_analysis $id
      update idletasks
      clipboard clear
      clipboard append $id
    } else {
      $public(ash,evttbl) cellselection clear 0,0 end,end
      $public(ash,evttbl) configure -selectbackground  white
      $public(ash,evttbl) configure -selectforeground  black
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
    frame $w -width 142 -height 14 -background white -borderwidth 0 -relief flat
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
    label $w.t$row -text $act -font $public(medfont)
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
    frame $w -width 142 -height 14 -background white -borderwidth 0 -relief flat
    bindtags $w [lreplace [bindtags $w] 1 1 TablelistBody]
    set total  [$tbl cellcget $row,activity -text]
    set colcnt [ $tbl columncount ] 
    for { set i 5 } { $i <  $colcnt  } { incr  i } {
      set sz [$tbl cellcget $row,$i -text]
      set name [ lindex [ $tbl columnconfigure $i -name ] end ]
      set szpct [ expr {$total * 100 / $public(sqltbl,maxActivity) }]
      frame $w.w$i -width $szpct -background $public(ashgroup,$name) -borderwidth 0 -relief flat
      place $w.w$i -relheight 1.0
      set total [ expr $total - $sz ]
    }
    set total [$tbl cellcget $row,activity -text]
    set aas [ format "%0.0f" [ expr 100 * ($total+0.0) / $public(sqltbl,maxActivity) ] ]
    label $w.t$row -text $aas -font $public(medfont) 
    # cell is 140 wide, the bars should all be under 100
    # put the activity value just above the bar
    set pc [ expr (($total + 0.0)/$public(sqltbl,maxActivity) * (100.0/142) )   ]
    place $w.t$row -relheight 1.0 -relx $pc
  } err ] } { ; }
}

proc createevtFrame {tbl row col w } { 
  global public
  set cur_proc  createevtFrame
  if { [ catch { 
    frame $w -width 142 -height 14 -background white -borderwidth 0 -relief flat
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
    label $w.w$i -text $width -font $public(medfont)
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
      set time     [ expr ( ( $end_day - 2450000 ) * 86400 ) + $end_secs ]  
      set end_time [ expr ( ( $end_day - 2450000 ) * 86400 ) + $end_secs ]  
      set beg_time [ expr ( ( $beg_day - 2450000 ) * 86400 ) + $beg_secs ]  
      set sid $sampid
      if { $public(ash,sample_id) < $sampid } { 
        set public(ash,sample_id) $sampid 
        set public(ash,where) "ceil(extract(epoch from ash_time)) > $public(ash,sample_id)"
      }
      
      # Valid Group (if group is like IDLE skip )
      #

      #if {  [ info exists public(waits,"$idx")  ]  } {
      #  set idx $public(waits,"$idx")  
      #} else {
      #  set idx "Other"
      #} 

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
      if { [ array size x_w_ash ] == 1 } { set x_w_ash(++end) [ expr ( ( $public(today) - 2450000 ) * 24 * 3600 ) + $public(secs) ] }
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
      set newtime [ expr ( ( $day - 2450000 ) * 24*3600 ) + $newsecs ]  
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
      set time [ expr ( ( $end_day - 2450000 ) * 24*3600 ) + $end_secs ]  
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
    set public(ash,beg) [ format "%06.0f %05.0f" $begday $begsec ]
    set public(ash,end) [ format "%06.0f %05.0f" $endday $endsec ]
    set public(ash,begcnt) [ format "%06.0f%05.0f" $begday $begsec ]
    set public(ash,endcnt) [ format "%06.0f%05.0f" $endday $endsec ]
    set public(ash,sesdelta)  [ expr [set public(ash,endcnt) ] - [ set public(ash,begcnt) ] ]
    #puts "call $cur_proc, begday:$begday, begsec:$begsec, endday:$endday, endsec:$endsec, public(ash,beg):$public(ash,beg), public(ash,end):$public(ash,end), sesdelta:$public(ash,sesdelta)"
    mon_execute ash_sqldetails
  } err] } { puts "call $cur_proc, err:$err"; } 
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
      if { [ lindex $row 1 ] != "" } {
        set IO        [lindex $row 0]
        set Lock      [lindex $row 1]
        set BufferPin [lindex $row 2] 
        set QueryID   [lindex $row 3]
        set System_IO [lindex $row 4] 
        set Total     [lindex $row 5] 
        set LWLock    [lindex $row 6]
        set Activity  [lindex $row 7] 
        set Extension [lindex $row 8] 
        set CPU       [lindex $row 9]
        set BCPU      [lindex $row 10]
        set IPC       [lindex $row 11] 
        set CmdType   [lindex $row 12]
        set Timeout   [lindex $row 13]
        set Client    [lindex $row 14] 

        set sum [ expr $sum + $Total ]
        set public(sqltbl,maxActivity) $sum
        set sqlid $QueryID
        $public(ash,sqltbl) insert end [concat \"$QueryID\"  $Total $Total \"$CmdType\" $LWLock $Lock $BufferPin $Activity $Extension $Client $IPC $Timeout $System_IO $IO $CPU ] 
        #puts "call $cur_proc, QueryID:$QueryID, Total:$Total, $CmdType, $LWLock $Lock $BufferPin $Activity $Extension $Client $IPC $Timeout $System_IO $IO $CPU"
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
      if { [ lindex $row 1 ] != "" } {
        set IO        [lindex $row 0]
        set Lock      [lindex $row 1]
        set BufferPin [lindex $row 2] 
        set System_IO [lindex $row 3] 
        set Total     [lindex $row 4] 
        set LWLock    [lindex $row 5]
        set PID       [lindex $row 6]
        set Activity  [lindex $row 7] 
        set Extension [lindex $row 8] 
        set CPU       [lindex $row 9]
        set BCPU      [lindex $row 10]
        set program   [lindex $row 11]
        set IPC       [lindex $row 12] 
        set user      [lindex $row 13]
        set Timeout   [lindex $row 14]
        set Client    [lindex $row 15] 

        if { $user == "" || $user == "{}"} { set user "postgres" }

        # program can be of the for "postgres.exe (smon)"
        # get rid of the "postgres.exe" part
        regsub {.*\(} $program "" program
        regsub {\)} $program "" program
        $public(ash,sestbl) insert end [concat \"$user $program\" $Total $Total $PID $LWLock $Lock $BufferPin $Activity $Extension $Client $IPC $Timeout $System_IO $IO $CPU $BCPU] 
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
    set public(ash,sqlid) " queryid is NULL "
  } else {
    set public(ash,sqlid) " queryid = \'$sqlid\' "
  }                                                                    
  mon_execute ash_sqltxt
  regsub {\..*} $public(version) "" t
  if { $t > 9 } { ; }
  mon_execute ash_sqlevents
  mon_execute ash_sqlsessions
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
    foreach row [ lindex $args 1 ] {
      if { [ lindex $row 0 ] != "" } {
        $public(ash,output) insert insert [lindex $row 0]
        set public(ash,sqltxt) [lindex $row 0]
      }
    }
  } err] } { puts "call $cur_proc, err:$err"; } 
  unlock public(thread_actv) $cur_proc
}

proc ash_sqlstats_fetch { args } {
  global public
  set cur_proc ash_sqlstats_fetch  
  #puts "call $cur_proc ======args:$args"
  if { [ catch {
    $public(ash,stattbl) delete 0 end
    set i 0
    foreach row [ lindex $args 1 ] {
      if { [ lindex $row 0 ] != "" } {
        set stats(wal_fpi)             [lindex $row 0]
        set stats(local_blks_written)  [lindex $row 1]
        set stats(local_blks_dirtied)  [lindex $row 2]
        set stats(rows)                [lindex $row 3]
        set stats(wal_records)         [lindex $row 4]
        set stats(shared_blks_dirtied) [lindex $row 5]
        set stats(shared_blks_written) [lindex $row 6]
        set stats(calls)               [lindex $row 7]
        set stats(blk_write_time)      [ format "%0.2f" [lindex $row 8] ]
        set stats(local_blks_read)     [lindex $row 9]
        set stats(wal_bytes)           [lindex $row 10]
        set stats(blk_read_time)       [ format "%0.2f" [lindex $row 11] ]
        set stats(local_blks_hit)      [lindex $row 12]
        set stats(total_plan_time)     [ format "%0.2f" [lindex $row 13] ]
        set stats(temp_blks_read)      [lindex $row 14]
        set stats(temp_blks_written)   [lindex $row 15]
        set stats(shared_blks_read)    [lindex $row 16]
        set stats(plans)               [lindex $row 17]
        set stats(total_exec_time)     [ format "%0.2f" [lindex $row 18] ]
        set stats(shared_blks_hit)     [lindex $row 19]

        foreach val {  
          total_exec_time
          calls
          rows
          shared_blks_hit
          shared_blks_read
          shared_blks_dirtied
          shared_blks_written
          local_blks_hit
          local_blks_read
          local_blks_dirtied
          local_blks_written
          temp_blks_read
          temp_blks_written
          wal_records
          wal_fpi
          wal_bytes
          plans
          total_plan_time
          blk_read_time
          blk_write_time
        } { 
          set val1 $stats($val)
          if { $stats(calls) == 0 } {
            set val2 0
          } else {
            set val2 [ format "%0.2f" [ expr $stats($val) / $stats(calls) ] ]
          }
          if { $stats(rows) == 0 } {
            set val3 0
          } else {
            set val3 [ format "%0.2f" [ expr $stats($val) / $stats(rows) ] ]
          }
          #while {[regsub {^([-+]?\d+)(\d{3})} $val1 {\1,\2} val1]} {}
          #while {[regsub {^([-+]?\d+)(\d{3})} $val2 {\1,\2} val2]} {}
          #while {[regsub {^([-+]?\d+)(\d{3})} $val3 {\1,\2} val3]} {}
          #while {[regsub {^([-+]?\d+)(\d{3})} $val4 {\1,\2} val4]} {}
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
        #set backend_type    [lindex $row 1]
        set wait_event      [lindex $row 1]
        set wait_event_type [lindex $row 2]
        set total [ expr $total + $activity ]
        if { $public(tbl,maxActivity) == 0 } {
          set public(tbl,maxActivity) $activity
        }
        $public(ash,evttbl) insert end [list $wait_event $activity $activity $wait_event_type]
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
      set time [ expr ( ( $day - 2450000 ) * 86400 ) + $secs ]  
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
        set public(ashsql,sqlovertimeid) " queryid is NULL "
      } else {
        #set public(ashsql,sqlovertimeid) " "
        set public(ashsql,sqlovertimeid) " queryid = \'$sqlid\' "
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
      { #F06EAA Pink }
      { #9F9371 light_brown }
      { #C02800 red }
      { #717354 medium_brown }
      { #882044 plum }
      { #5C440B dark_brown }
      { #FFD700 gold }
      { #E46800 orange }
      { #4080F0 light_blue }
      { #004AE7 blue }
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
      LWLock 
      Lock 
      BufferPin 
      Activity
      Extension 
      Client 
      IPC 
      Timeout 
      System_IO 
      IO 
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
    #set graph          .ash_graph
    set graph          .ed_mainFrame.me.m.f.a.gf.ash_graph
    set public(ash,graph) $graph
    
    barchart $public(ash,graph) \
      -relief flat      \
      -barmode overlap  \
      -bg $public(bgt)  \
      -borderwidth  0   \
      -plotbackground white
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
                              #
    $graph axis   configure x -minorticks 0  \
                              -stepsize $public(ash,ticksize)  \
                              -tickfont  $public(smallfont) -titlefont $public(smallfont) \
                              -background $public(bgt) \
                              -command cur_time      \
                              -bd 0      \
                              -color $public(fg)
                              #
    $graph axis   configure y -title "Active Sessions (AAS)" -min 0.0 -max {} \
                              -tickfont  $public(smallfont) -titlefont $public(smallfont) \
                              -background $public(bgt) \
                              -color $public(fg)
    
    pack $public(ash,graph) -in $public(ash,graph_frame) -expand yes -fill both -side top -ipadx 0 -ipady 0 -padx 0 -pady 0 
    
    set marker1 [$public(ash,graph) marker create polygon\
           -coords {-Inf Inf Inf Inf Inf -Inf -Inf -Inf} -fill {} \
           -fill #E0E0E0 \
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
    frame $output   -bd 0  -relief flat -bg $public(bgt)
    frame $output.f
    text $output.w  -background white \
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

proc connect_to_postgresql {} {
  global public masterthread dbmon_threadID bm
  upvar #0 configpostgresql configpostgresql
  setlocaltcountvars $configpostgresql 1
  set public(connected) 0
  set public(host) $pg_host
  set public(port) $pg_port
  set public(sslmode) $pg_sslmode
  if { $bm eq "TPC-C" } {
  set public(suser) $pg_superuser
  set public(suser_pw) $pg_superuserpass
  set public(default_db) $pg_defaultdbase
  set public(user) $pg_user
  set public(user_pw) $pg_pass
  set public(tproc_db) $pg_dbase
  } else {
  set public(suser) $pg_tpch_superuser
  set public(suser_pw) $pg_tpch_superuserpass
  set public(default_db) $pg_tpch_defaultdbase
  set public(user) $pg_tpch_user
  set public(user_pw) $pg_tpch_pass
  set public(tproc_db) $pg_tpch_dbase
  }

  if { ! [ info exists dbmon_threadID ] } {
    set public(parent) $masterthread
    pg_dbmon_thread_init 
  } else {
    return 1
  }

  #Do logon in thread
  set db_type "default"
  thread::send -async $dbmon_threadID "pg_logon $public(parent) $public(host) $public(port) $public(sslmode) $public(suser) $public(suser_pw) $public(default_db) $db_type"

  #Do logon for getting sql plan
  #set db_type "tproc"
  #thread::send -async $dbmon_threadID "pg_logon $public(parent) $pg_host $pg_port $pg_user $pg_pass $pg_dbase $db_type"

  test_connect_pg
  if { [ info exists dbmon_threadID ] } {
    tsv::set application themonitor $dbmon_threadID
  }
}

proc putsm { message } {
  puts "$message"
}

proc pg_dbmon_thread_init { } {
  global public dbmon_threadID

  set public(connected) 0
  set public(thread_actv) 0 ;# mutex, lock on this var for sq
  set dbmon_threadID [ thread::create {
    global tpublic
  
    proc just_disconnect { parent } {
      #thread::send $parent "putsm \"Metrics Closing down...\""
      catch {thread::release}
    }

    proc pg_logon { parent host port sslmode user password db db_type} {
      thread::send $parent "putsm \"Metrics Connecting to host:$host port:$port\""
      set cur_proc pg_logon 
      set handle none
      set err "unknown"

      if { [ catch { package require Pgtcl} err ] } {
        thread::send $parent "::callback_err \"Pgtcl load failed in Metrics\""
        just_disconnect $parent
        return
      }

      set handle [ ConnectToPostgres $parent $host $port $sslmode $user $password $db ]
      
      if { $handle eq "Failed" } {
        #set err "error, the database connection to $host could not be established"
        #thread::send $parent "::callback_err \"$err\""
        just_disconnect $parent
        return
      }
      
      # Check if pgsentinel is installed
      if { $db_type == "default" } {
        if { [ catch {
          pg_select $handle "select count(*) from pg_class where relname = 'pg_active_session_history';" arr { 
            set cnt [ expr $arr(count) ]
            if { $cnt == 0 } { 
              pg_disconnect $handle
              thread::send $parent "::callback_err \"Extension pgsentinel is not found\""
              just_disconnect $parent
              return
            }
          }
        } err ] } { 
          thread::send -async $parent "::callback_err \"$err\""
          thread::send -async $parent "::callback_mesg \"pg_disconnect $handle\""
        }
      }

      thread::send -async $parent "::callback_connect $db_type $handle"
    }
  
    proc pg_logoff { parent handle } {
      thread::send $parent "putsm \"Metrics Disconnect from PostgreSQL...\""
      set cur_proc pg_logoff 
      set err "unknown"
      if { [ catch { pg_disconnect $handle } err ] } { 
        set err  [ join $err ]
        thread::send -async $parent "::callback_err \"$err\""
      just_disconnect $parent
      } else {
      just_disconnect $parent
      	}
    }

    #POSTGRES CONNECTION
    proc ConnectToPostgres { parent host port sslmode user password dbname } {
	global tcl_platform public masterthread dbmon_threadID
	if {[catch {set handle [pg_connect -conninfo [list host = $host port = $port sslmode = $sslmode user = $user password = $password dbname = $dbname ]]} err]} {
	set handle "Failed" 
	thread::send -async $parent "::callback_err [ join $err ]"
 	} else {
	if {$tcl_platform(platform) == "windows"} {
	#Workaround for Bug #95 where first connection fails on Windows
	catch {pg_disconnect $handle}
	set lda [pg_connect -conninfo [list host = $host port = $port sslmode = $sslmode user = $user password = $password dbname = $dbname ]]
        }
	pg_notice_handler $handle puts
	set result [ pg_exec $handle "set CLIENT_MIN_MESSAGES TO 'ERROR'" ]
	pg_result $result -clear
        }
	return $handle
	}

    proc pg_sql {parent handle sql} {
      set cur_proc pg_sql 
      thread::send  $parent " ::callback_mesg $cur_proc "
      pg_exec $handle $sql
      #set result [ pg_exec $handle $sql ]
      #if {[pg_result $result -status] != "PGRES_COMMAND_OK"} {
      #  error "[pg_result $result -error]"
      #} else {
      #  pg_result $result -clear
      #}
      thread::send $parent " ::callback_mesg $cursor parsed"
    }
  
    proc pg_all { parent handle cursor sql fetch } {
      global tpublic
      set cur_proc pg_all
      #if {$fetch == "sqlovertime_fetch"} {thread::send $parent "putsm \"call pg_all handle:$handle, cursor:$cursor, fetch:$fetch, sql:$sql\""}
    
      set cur_proc pg_all
      thread::send -async $parent " ::callback_mesg $cur_proc "
    
      tsv::set fetched $cursor ""
      set result [tsv::object fetched $cursor]

      if {[catch {
        pg_select $handle $sql var {
          set rowcount [ expr $var(.tupno) ]
          set namelist ""
          set collist ""
          foreach index [array names var] {
            if { $index eq ".tupno" || $index eq ".headers" || $index eq ".numcols"} { continue }
            set namelist "$namelist $index "
            set collist "$collist \"$var($index)\" "
            #thread::send $parent "putsm \"call pg_all ===== $index $var($index) ===== \""
          }
          $result append " [ list $collist ]"
          #if { $rowcount == 0 } { thread::send $parent "putsm \"call pg_all, $fetch : namelist:$namelist\"" }
          #thread::send -async $parent " ::callback_mesg \"sql parsed: $result\""
        }
        thread::send -async $parent " ::callback_mesg \"sql parsed\""
      } message]} {
        #set f [open "/tmp/hm.log" w]
        #puts $f "Query Failed, sql:$sql err:$message"
        #close $f
        thread::send $parent "putsm \"call pg_all Query Failed, sql:$sql err:$message \""
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

proc test_connect_pg { } {
  global public dbmon_threadID
  variable firstconnect
  set cur_proc test_connect_pg
  if { $public(connected) == "err" } {
    puts "Metrics Connection Failed: Verify Metrics Options"
    tsv::set application themonitor "QUIT"
    .ed_mainFrame.buttons.dashboard configure -state normal
    return 1
  }
  if { $public(connected) == -1 } {
    set public(connected) 0
    connect_to_postgresql
    return
  }
  if { $public(connected) == 0 } {
    puts  "Waiting for Connection to PostgreSQL for Database Metrics..."
    if { [ info exists dbmon_threadID ] } {
      if { [ thread::exists $dbmon_threadID ] } {
        after 5000 test_connect_pg
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
        set_pg_waits
        set_pg_events
        set_pgcursors
        set firstconnect "false"
      }
      create_metrics_screen
      mon_init
      .ed_mainFrame.buttons.dashboard configure -state normal
    } else {
      set public(connected) 0
      connect_to_postgresql
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

proc pg_HowManyProcessorsWindows {} {
  global S cpu_model
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

proc pg_HowManyProcessorsLinux {} {
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
      pg_HowManyProcessorsWindows
      #global env
      #set public(cpucount) $env(NUMBER_OF_PROCESSORS)
    } else {
      pg_HowManyProcessorsLinux
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
  puts "Metrics Error: No rows found in pg_active_session_history,run a workload to populate metrics"
  #reset the GUI
  ed_kill_metrics
  ed_metrics_button
  #Deactive the metrics button
  .ed_mainFrame.buttons.dashboard config -image [ create_image dashboard icons ] -command "metrics"
  set public(run) 0
  return
  ########
  } else {
  puts "Starting Metrics, read [ join $public(ashrowcount) ] rows from pg_active_session_history"
  }
  #mon_execute cpucount
  #cpucount cannot be retrieved by PostgreSQL. Cpucount is limited to running in the client. 
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
        #  thread::send -async $dbmon_threadID "pg_all $public(parent) $public(tproc_handle) $crsr \"$sql\" $fetch"
        #} else {
          thread::send -async $dbmon_threadID "pg_all $public(parent) $public(handle) $crsr \"$sql\" $fetch"
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

proc set_pg_waits {} {
  global public
  #set public(waits,CPU) wait_event_type
  #set public(waits,BCPU) wait_event_type
  set public(waits,LWLock) wait_event_type
  set public(waits,Lock) wait_event_type
  set public(waits,BufferPin) wait_event_type
  set public(waits,Activity) wait_event_type
  set public(waits,Extension) wait_event_type
  set public(waits,Client) wait_event_type
  set public(waits,IPC) wait_event_type
  set public(waits,IO) wait_event_type
  set public(waits,Timeout) wait_event_type
  
  set public(waits,CPU) CPU
  set public(waits,BCPU) CPU

  set public(waits,ArchiverMain) Activity
  set public(waits,AutoVacuumMain) Activity
  set public(waits,BgWriterHibernate) Activity
  set public(waits,BgWriterMain) Activity
  set public(waits,CheckpointerMain) Activity
  set public(waits,LogicalApplyMain) Activity
  set public(waits,LogicalLauncherMain) Activity
  set public(waits,PgStatMain) Activity
  set public(waits,RecoveryWalAll) Activity
  set public(waits,RecoveryWalStream) Activity
  set public(waits,SysLoggerMain) Activity
  set public(waits,WalReceiverMain) Activity
  set public(waits,WalSenderMain) Activity
  set public(waits,WalWriterMain) Activity
  
  set public(waits,BufferPin) BufferPin
  
  set public(waits,ClientRead) Client
  set public(waits,ClientWrite) Client
  set public(waits,GSSOpenServer) Client
  set public(waits,LibPQWalReceiverConnect) Client
  set public(waits,LibPQWalReceiverReceive) Client
  set public(waits,SSLOpenServer) Client
  set public(waits,WalReceiverWaitStart) Client
  set public(waits,WalSenderWaitForWAL) Client
  set public(waits,WalSenderWriteData) Client
  
  set public(waits,Extension) Extension
  
  set public(waits,BaseBackupRead) IO
  set public(waits,BufFileRead) IO
  set public(waits,BufFileWrite) IO
  set public(waits,BufFileTruncate) IO
  set public(waits,ControlFileRead) IO
  set public(waits,ControlFileSync) IO
  set public(waits,ControlFileSyncUpdate) IO
  set public(waits,ControlFileWrite) IO
  set public(waits,ControlFileWriteUpdate) IO
  set public(waits,CopyFileRead) IO
  set public(waits,CopyFileWrite) IO
  set public(waits,DataFileExtend) IO
  set public(waits,DataFileFlush) IO
  set public(waits,DataFileImmediateSync) IO
  set public(waits,DataFilePrefetch) IO
  set public(waits,DataFileRead) IO
  set public(waits,DataFileSync) IO
  set public(waits,DataFileTruncate) IO
  set public(waits,DataFileWrite) IO
  set public(waits,DSMFillZeroWrite) IO
  set public(waits,LockFileAddToDataDirRead) IO
  set public(waits,LockFileAddToDataDirSync) IO
  set public(waits,LockFileAddToDataDirWrite) IO
  set public(waits,LockFileCreateRead) IO
  set public(waits,LockFileCreateSync) IO
  set public(waits,LockFileCreateWrite) IO
  set public(waits,LockFileReCheckDataDirRead) IO
  set public(waits,LogicalRewriteCheckpointSync) IO
  set public(waits,LogicalRewriteMappingSync) IO
  set public(waits,LogicalRewriteMappingWrite) IO
  set public(waits,LogicalRewriteSync) IO
  set public(waits,LogicalRewriteTruncate) IO
  set public(waits,LogicalRewriteWrite) IO
  set public(waits,RelationMapRead) IO
  set public(waits,RelationMapSync) IO
  set public(waits,RelationMapWrite) IO
  set public(waits,ReorderBufferRead) IO
  set public(waits,ReorderBufferWrite) IO
  set public(waits,ReorderLogicalMappingRead) IO
  set public(waits,ReplicationSlotRead) IO
  set public(waits,ReplicationSlotRestoreSync) IO
  set public(waits,ReplicationSlotSync) IO
  set public(waits,ReplicationSlotWrite) IO
  set public(waits,SLRUFlushSync) IO
  set public(waits,SLRURead) IO
  set public(waits,SLRUSync) IO
  set public(waits,SLRUWrite) IO
  set public(waits,SnapbuildRead) IO
  set public(waits,SnapbuildSync) IO
  set public(waits,SnapbuildWrite) IO
  set public(waits,TimelineHistoryFileSync) IO
  set public(waits,TimelineHistoryFileWrite) IO
  set public(waits,TimelineHistoryRead) IO
  set public(waits,TimelineHistorySync) IO
  set public(waits,TimelineHistoryWrite) IO
  set public(waits,TwophaseFileRead) IO
  set public(waits,TwophaseFileSync) IO
  set public(waits,TwophaseFileWrite) IO
  set public(waits,WALBootstrapSync) IO
  set public(waits,WALBootstrapWrite) IO
  set public(waits,WALCopyRead) IO
  set public(waits,WALCopySync) IO
  set public(waits,WALCopyWrite) IO
  set public(waits,WALInitSync) IO
  set public(waits,WALInitWrite) IO
  set public(waits,WALRead) IO
  set public(waits,WALSenderTimelineHistoryRead) IO
  set public(waits,WALSync) IO
  set public(waits,WALSyncMethodAssign) IO
  set public(waits,WALWrite) IO
  set public(waits,LogicalChangesRead) IO
  set public(waits,LogicalChangesWrite) IO
  set public(waits,LogicalSubxactRead) IO
  set public(waits,LogicalSubxactWrite) IO

  set public(waits,AppendReady) IPC
  set public(waits,BackendTermination) IPC
  set public(waits,BackupWaitWalArchive) IPC
  set public(waits,BgWorkerShutdown) IPC
  set public(waits,BgWorkerStartup) IPC
  set public(waits,BtreePage) IPC
  set public(waits,BufferIO) IPC
  set public(waits,CheckpointDone) IPC
  set public(waits,CheckpointStart) IPC
  set public(waits,ExecuteGather) IPC
  set public(waits,HashBatchAllocate) IPC
  set public(waits,HashBatchElect) IPC
  set public(waits,HashBatchLoad) IPC
  set public(waits,HashBuildAllocate) IPC
  set public(waits,HashBuildElect) IPC
  set public(waits,HashBuildHashInner) IPC
  set public(waits,HashBuildHashOuter) IPC
  set public(waits,HashGrowBatchesAllocate) IPC
  set public(waits,HashGrowBatchesDecide) IPC
  set public(waits,HashGrowBatchesElect) IPC
  set public(waits,HashGrowBatchesFinish) IPC
  set public(waits,HashGrowBatchesRepartition) IPC
  set public(waits,HashGrowBucketsAllocate) IPC
  set public(waits,HashGrowBucketsElect) IPC
  set public(waits,HashGrowBucketsReinsert) IPC
  set public(waits,LogicalSyncData) IPC
  set public(waits,LogicalSyncStateChange) IPC
  set public(waits,MessageQueueInternal) IPC
  set public(waits,MessageQueuePutMessage) IPC
  set public(waits,MessageQueueReceive) IPC
  set public(waits,MessageQueueSend) IPC
  set public(waits,ParallelBitmapScan) IPC
  set public(waits,ParallelCreateIndexScan) IPC
  set public(waits,ParallelFinish) IPC
  set public(waits,ProcArrayGroupUpdate) IPC
  set public(waits,ProcSignalBarrier) IPC
  set public(waits,Promote) IPC
  set public(waits,RecoveryConflictSnapshot) IPC
  set public(waits,RecoveryConflictTablespace) IPC
  set public(waits,RecoveryPause) IPC
  set public(waits,ReplicationOriginDrop) IPC
  set public(waits,ReplicationSlotDrop) IPC
  set public(waits,SafeSnapshot) IPC
  set public(waits,SyncRep) IPC
  set public(waits,WalReceiverExit) IPC
  set public(waits,WalReceiverWaitStart) IPC
  set public(waits,XactGroupUpdate) IPC

  set public(waits,advisory) Lock
  set public(waits,extend) Lock
  set public(waits,frozenid) Lock
  set public(waits,object) Lock
  set public(waits,page) Lock
  set public(waits,relation) Lock
  set public(waits,spectoken) Lock
  set public(waits,speculative_token) Lock
  set public(waits,transactionid) Lock
  set public(waits,tuple) Lock
  set public(waits,userlock) Lock
  set public(waits,virtualxid) Lock
  
  set public(waits,AddinShmemInit) LWLock
  set public(waits,async) LWLock
  set public(waits,AsyncCtlLock) LWLock
  set public(waits,AsyncQueueLock) LWLock
  set public(waits,AutoFile) LWLock
  set public(waits,AutoFileLock) LWLock
  set public(waits,Autovacuum) LWLock
  set public(waits,AutovacuumSchedule) LWLock
  set public(waits,AutovacuumScheduleLock) LWLock
  set public(waits,BackendRandomLock) LWLock
  set public(waits,BackgroundWorker) LWLock
  set public(waits,BackgroundWorkerLock) LWLock
  set public(waits,BtreeVacuum) LWLock
  set public(waits,BtreeVacuumLock) LWLock
  set public(waits,buffer_content) LWLock
  set public(waits,buffer_io) LWLock
  set public(waits,buffer_mapping) LWLock
  set public(waits,BufferContent) LWLock
  set public(waits,BufferMapping) LWLock
  set public(waits,CheckpointerComm) LWLock
  set public(waits,CheckpointerCommLock) LWLock
  set public(waits,CheckpointLock) LWLock
  set public(waits,clog) LWLock
  set public(waits,CLogControlLock) LWLock
  set public(waits,CLogTruncationLock) LWLock
  set public(waits,commit_timestamp) LWLock
  set public(waits,CommitTs) LWLock
  set public(waits,CommitTsBuffer) LWLock
  set public(waits,CommitTsControlLock) LWLock
  set public(waits,CommitTsLock) LWLock
  set public(waits,CommitTsSLRU) LWLock
  set public(waits,ControlFile) LWLock
  set public(waits,ControlFileLock) LWLock
  set public(waits,DynamicSharedMemoryControl) LWLock
  set public(waits,DynamicSharedMemoryControlLock) LWLock
  set public(waits,lock_manager) LWLock
  set public(waits,LockFastPath) LWLock
  set public(waits,LockManager) LWLock
  set public(waits,LogicalRepWorker) LWLock
  set public(waits,LogicalRepWorkerLock) LWLock
  set public(waits,multixact_member) LWLock
  set public(waits,multixact_offset) LWLock
  set public(waits,MultiXactGen) LWLock
  set public(waits,MultiXactGenLock) LWLock
  set public(waits,MultiXactMemberBuffer) LWLock
  set public(waits,MultiXactMemberControlLock) LWLock
  set public(waits,MultiXactMemberSLRU) LWLock
  set public(waits,MultiXactOffsetBuffer) LWLock
  set public(waits,MultiXactOffsetControlLock) LWLock
  set public(waits,MultiXactOffsetSLRU) LWLock
  set public(waits,MultiXactTruncation) LWLock
  set public(waits,MultiXactTruncationLock) LWLock
  set public(waits,NotifyBuffer) LWLock
  set public(waits,NotifyQueue) LWLock
  set public(waits,NotifyQueueTail) LWLock
  set public(waits,NotifyQueueTailLock) LWLock
  set public(waits,NotifySLRU) LWLock
  set public(waits,OidGen) LWLock
  set public(waits,OidGenLock) LWLock
  set public(waits,oldserxid) LWLock
  set public(waits,OldSerXidLock) LWLock
  set public(waits,OldSnapshotTimeMap) LWLock
  set public(waits,ProcArray) LWLock
  set public(waits,SharedTidBitMap) LWLock
  set public(waits,WALInsert) LWLock
  set public(waits,XactBuffer) LWLock
  set public(waits,XactSLRU) LWLock
  set public(waits,XactTruncation) LWLock
  set public(waits,XidGen) LWLock

  set public(waits,BaseBackupThrottle) Timeout
  set public(waits,PgSleep) Timeout
  set public(waits,RecoveryApplyDelay) Timeout
  set public(waits,RecoveryRetrieveRetryInterval) Timeout
  set public(waits,VacuumDelay) Timeout
}

proc set_pg_events {} {
  global public

  set public(events,CPU) "Waiting for CPU."
  set public(events,ArchiverMain) "Waiting in main loop of archiver process."
  set public(events,AutoVacuumMain) "Waiting in main loop of autovacuum launcher process."
  set public(events,BgWriterHibernate) "Waiting in background writer process, hibernating."
  set public(events,BgWriterMain) "Waiting in main loop of background writer process."
  set public(events,CheckpointerMain) "Waiting in main loop of checkpointer process."
  set public(events,LogicalApplyMain) "Waiting in main loop of logical replication apply process."
  set public(events,LogicalLauncherMain) "Waiting in main loop of logical replication launcher process."
  set public(events,PgStatMain) "Waiting in main loop of statistics collector process."
  set public(events,RecoveryWalAll) "Waiting for WAL from a stream at recovery."
  set public(events,RecoveryWalStream) "Waiting in main loop of startup process for WAL to arrive, during streaming recovery."
  set public(events,SysLoggerMain) "Waiting in main loop of syslogger process."
  set public(events,WalReceiverMain) "Waiting in main loop of WAL receiver process."
  set public(events,WalSenderMain) "Waiting in main loop of WAL sender process."
  set public(events,WalWriterMain) "Waiting in main loop of WAL writer process."

  set public(events,BufferPin) "Waiting to acquire an exclusive pin on a buffer."

  set public(events,ClientRead) "Waiting to read data from the client."
  set public(events,ClientWrite) "Waiting to write data to the client."
  set public(events,GSSOpenServer) "Waiting to read data from the client while establishing a GSSAPI session."
  set public(events,LibPQWalReceiverConnect) "Waiting in WAL receiver to establish connection to remote server."
  set public(events,LibPQWalReceiverReceive) "Waiting in WAL receiver to receive data from remote server."
  set public(events,SSLOpenServer) "Waiting for SSL while attempting connection."
  set public(events,WalReceiverWaitStart) "Waiting for startup process to send initial data for streaming replication."
  set public(events,WalSenderWaitForWAL) "Waiting for WAL to be flushed in WAL sender process."
  set public(events,WalSenderWriteData) "Waiting for any activity when processing replies from WAL receiver in WAL sender process."

  set public(events,Extension) "Waiting in an extension."

  set public(events,BaseBackupRead) "Waiting for base backup to read from a file."
  set public(events,BufFileRead) "Waiting for a read from a buffered file."
  set public(events,BufFileWrite) "Waiting for a write to a buffered file."
  set public(events,BufFileTruncate) "Waiting for a buffered file to be truncated."
  set public(events,ControlFileRead) "Waiting for a read from the pg_control file."
  set public(events,ControlFileSync) "Waiting for the pg_control file to reach durable storage."
  set public(events,ControlFileSyncUpdate) "Waiting for an update to the pg_control file to reach durable storage."
  set public(events,ControlFileWrite) "Waiting for a write to the pg_control file."
  set public(events,ControlFileWriteUpdate) "Waiting for a write to update the pg_control file."
  set public(events,CopyFileRead) "Waiting for a read during a file copy operation."
  set public(events,CopyFileWrite) "Waiting for a write during a file copy operation."
  set public(events,DSMFillZeroWrite) "Waiting to fill a dynamic shared memory backing file with zeroes."
  set public(events,DataFileExtend) "Waiting for a relation data file to be extended."
  set public(events,DataFileFlush) "Waiting for a relation data file to reach durable storage."
  set public(events,DataFileImmediateSync) "Waiting for an immediate synchronization of a relation data file to durable storage."
  set public(events,DataFilePrefetch) "Waiting for an asynchronous prefetch from a relation data file."
  set public(events,DataFileRead) "Waiting for a read from a relation data file."
  set public(events,DataFileSync) "Waiting for changes to a relation data file to reach durable storage."
  set public(events,DataFileTruncate) "Waiting for a relation data file to be truncated."
  set public(events,DataFileWrite) "Waiting for a write to a relation data file."
  set public(events,LockFileAddToDataDirRead) "Waiting for a read while adding a line to the data directory lock file."
  set public(events,LockFileAddToDataDirSync) "Waiting for data to reach durable storage while adding a line to the data directory lock file."
  set public(events,LockFileAddToDataDirWrite) "Waiting for a write while adding a line to the data directory lock file."
  set public(events,LockFileCreateRead) "Waiting to read while creating the data directory lock file."
  set public(events,LockFileCreateSync) "Waiting for data to reach durable storage while creating the data directory lock file."
  set public(events,LockFileCreateWrite) "Waiting for a write while creating the data directory lock file."
  set public(events,LockFileReCheckDataDirRead) "Waiting for a read during recheck of the data directory lock file."
  set public(events,LogicalRewriteCheckpointSync) "Waiting for logical rewrite mappings to reach durable storage during a checkpoint."
  set public(events,LogicalRewriteMappingSync) "Waiting for mapping data to reach durable storage during a logical rewrite."
  set public(events,LogicalRewriteMappingWrite) "Waiting for a write of mapping data during a logical rewrite."
  set public(events,LogicalRewriteSync) "Waiting for logical rewrite mappings to reach durable storage."
  set public(events,LogicalRewriteTruncate) "Waiting for truncate of mapping data during a logical rewrite."
  set public(events,LogicalRewriteWrite) "Waiting for a write of logical rewrite mappings."
  set public(events,RelationMapRead) "Waiting for a read of the relation map file."
  set public(events,RelationMapSync) "Waiting for the relation map file to reach durable storage."
  set public(events,RelationMapWrite) "Waiting for a write to the relation map file."
  set public(events,ReorderBufferRead) "Waiting for a read during reorder buffer management."
  set public(events,ReorderBufferWrite) "Waiting for a write during reorder buffer management."
  set public(events,ReorderLogicalMappingRead) "Waiting for a read of a logical mapping during reorder buffer management."
  set public(events,ReplicationSlotRead) "Waiting for a read from a replication slot control file."
  set public(events,ReplicationSlotRestoreSync) "Waiting for a replication slot control file to reach durable storage while restoring it to memory."
  set public(events,ReplicationSlotSync) "Waiting for a replication slot control file to reach durable storage."
  set public(events,ReplicationSlotWrite) "Waiting for a write to a replication slot control file."
  set public(events,SLRUFlushSync) "Waiting for SLRU data to reach durable storage during a checkpoint or database shutdown."
  set public(events,SLRURead) "Waiting for a read of an SLRU page."
  set public(events,SLRUSync) "Waiting for SLRU data to reach durable storage following a page write."
  set public(events,SLRUWrite) "Waiting for a write of an SLRU page."
  set public(events,SnapbuildRead) "Waiting for a read of a serialized historical catalog snapshot."
  set public(events,SnapbuildSync) "Waiting for a serialized historical catalog snapshot to reach durable storage."
  set public(events,SnapbuildWrite) "Waiting for a write of a serialized historical catalog snapshot."
  set public(events,TimelineHistoryFileSync) "Waiting for a timeline history file received via streaming replication to reach durable storage."
  set public(events,TimelineHistoryFileWrite) "Waiting for a write of a timeline history file received via streaming replication."
  set public(events,TimelineHistoryRead) "Waiting for a read of a timeline history file."
  set public(events,TimelineHistorySync) "Waiting for a newly created timeline history file to reach durable storage."
  set public(events,TimelineHistoryWrite) "Waiting for a write of a newly created timeline history file."
  set public(events,TwophaseFileRead) "Waiting for a read of a two phase state file."
  set public(events,TwophaseFileSync) "Waiting for a two phase state file to reach durable storage."
  set public(events,TwophaseFileWrite) "Waiting for a write of a two phase state file."
  set public(events,WALBootstrapSync) "Waiting for WAL to reach durable storage during bootstrapping."
  set public(events,WALBootstrapWrite) "Waiting for a write of a WAL page during bootstrapping."
  set public(events,WALCopyRead) "Waiting for a read when creating a new WAL segment by copying an existing one."
  set public(events,WALCopySync) "Waiting for a new WAL segment created by copying an existing one to reach durable storage."
  set public(events,WALCopyWrite) "Waiting for a write when creating a new WAL segment by copying an existing one."
  set public(events,WALInitSync) "Waiting for a newly initialized WAL file to reach durable storage."
  set public(events,WALInitWrite) "Waiting for a write while initializing a new WAL file."
  set public(events,WALRead) "Waiting for a read from a WAL file."
  set public(events,WALSenderTimelineHistoryRead) "Waiting for a read from a timeline history file during a walsender timeline command."
  set public(events,WALSync) "Waiting for a WAL file to reach durable storage."
  set public(events,WALSyncMethodAssign) "Waiting for data to reach durable storage while assigning a new WAL sync method."
  set public(events,WALWrite) "Waiting for a write to a WAL file."
  set public(events,LogicalChangesRead) "Waiting for a read from a logical changes file."
  set public(events,LogicalChangesWrite) "Waiting for a write to a logical changes file."
  set public(events,LogicalSubxactRead) "Waiting for a read from a logical subxact file."
  set public(events,LogicalSubxactWrite) "Waiting for a write to a logical subxact file."

  set public(events,AppendReady) "Waiting for subplan nodes of an Append plan node to be ready."
  set public(events,BackendTermination) "Waiting for the termination of another backend."
  set public(events,BackupWaitWalArchive) "Waiting for WAL files required for a backup to be successfully archived."
  set public(events,BgWorkerShutdown) "Waiting for background worker to shut down."
  set public(events,BgWorkerStartup) "Waiting for background worker to start up."
  set public(events,BtreePage) "Waiting for the page number needed to continue a parallel B-tree scan to become available."
  set public(events,BufferIO) "Waiting for buffer I/O to complete."
  set public(events,CheckpointDone) "Waiting for a checkpoint to complete."
  set public(events,CheckpointStart) "Waiting for a checkpoint to start."
  set public(events,ExecuteGather) "Waiting for activity from a child process while executing a Gather plan node."
  set public(events,HashBatchAllocate) "Waiting for an elected Parallel Hash participant to allocate a hash table."
  set public(events,HashBatchElect) "Waiting to elect a Parallel Hash participant to allocate a hash table."
  set public(events,HashBatchLoad) "Waiting for other Parallel Hash participants to finish loading a hash table."
  set public(events,HashBuildAllocate) "Waiting for an elected Parallel Hash participant to allocate the initial hash table."
  set public(events,HashBuildElect) "Waiting to elect a Parallel Hash participant to allocate the initial hash table."
  set public(events,HashBuildHashInner) "Waiting for other Parallel Hash participants to finish hashing the inner relation."
  set public(events,HashBuildHashOuter) "Waiting for other Parallel Hash participants to finish partitioning the outer relation."
  set public(events,HashGrowBatchesAllocate) "Waiting for an elected Parallel Hash participant to allocate more batches."
  set public(events,HashGrowBatchesDecide) "Waiting to elect a Parallel Hash participant to decide on future batch growth."
  set public(events,HashGrowBatchesElect) "Waiting to elect a Parallel Hash participant to allocate more batches."
  set public(events,HashGrowBatchesFinish) "Waiting for an elected Parallel Hash participant to decide on future batch growth."
  set public(events,HashGrowBatchesRepartition) "Waiting for other Parallel Hash participants to finish repartitioning."
  set public(events,HashGrowBucketsAllocate) "Waiting for an elected Parallel Hash participant to finish allocating more buckets."
  set public(events,HashGrowBucketsElect) "Waiting to elect a Parallel Hash participant to allocate more buckets."
  set public(events,HashGrowBucketsReinsert) "Waiting for other Parallel Hash participants to finish inserting tuples into new buckets."
  set public(events,LogicalSyncData) "Waiting for a logical replication remote server to send data for initial table synchronization."
  set public(events,LogicalSyncStateChange) "Waiting for a logical replication remote server to change state."
  set public(events,MessageQueueInternal) "Waiting for another process to be attached to a shared message queue."
  set public(events,MessageQueuePutMessage) "Waiting to write a protocol message to a shared message queue."
  set public(events,MessageQueueReceive) "Waiting to receive bytes from a shared message queue."
  set public(events,MessageQueueSend) "Waiting to send bytes to a shared message queue."
  set public(events,ParallelBitmapScan) "Waiting for parallel bitmap scan to become initialized."
  set public(events,ParallelCreateIndexScan) "Waiting for parallel CREATE INDEX workers to finish heap scan."
  set public(events,ParallelFinish) "Waiting for parallel workers to finish computing."
  set public(events,ProcArrayGroupUpdate) "Waiting for the group leader to clear the transaction ID at end of a parallel operation."
  set public(events,ProcSignalBarrier) "Waiting for a barrier event to be processed by all backends."
  set public(events,Promote) "Waiting for standby promotion."
  set public(events,RecoveryConflictSnapshot) "Waiting for recovery conflict resolution for a vacuum cleanup."
  set public(events,RecoveryConflictTablespace) "Waiting for recovery conflict resolution for dropping a tablespace."
  set public(events,RecoveryPause) "Waiting for recovery to be resumed."
  set public(events,ReplicationOriginDrop) "Waiting for a replication origin to become inactive so it can be dropped."
  set public(events,ReplicationSlotDrop) "Waiting for a replication slot to become inactive so it can be dropped."
  set public(events,SafeSnapshot) "Waiting to obtain a valid snapshot for a READ ONLY DEFERRABLE transaction."
  set public(events,SyncRep) "Waiting for confirmation from a remote server during synchronous replication."
  set public(events,WalReceiverExit) "Waiting for the WAL receiver to exit."
  set public(events,WalReceiverWaitStart) "Waiting for startup process to send initial data for streaming replication."
  set public(events,XactGroupUpdate) "Waiting for the group leader to update transaction status at end of a parallel operation."

  set public(events,advisory) "Waiting to acquire an advisory user lock."
  set public(events,extend) "Waiting to extend a relation."
  set public(events,frozenid) "Waiting to update pg_database.datfrozenxid and pg_database.datminmxid."
  set public(events,object) "Waiting to acquire a lock on a non-relation database object."
  set public(events,page) "Waiting to acquire a lock on a page of a relation."
  set public(events,relation) "Waiting to acquire a lock on a relation."
  set public(events,spectoken) "Waiting to acquire a speculative insertion lock."
  set public(events,speculative_token) "Waiting to acquire a speculative insertion lock."
  set public(events,transactionid) "Waiting for a transaction to finish."
  set public(events,tuple) "Waiting to acquire a lock on a tuple."
  set public(events,userlock) "Waiting to acquire a user lock."
  set public(events,virtualxid) "Waiting to acquire a virtual transaction ID lock."

  set public(events,AddinShmemInit) "Waiting to manage an extension's space allocation in shared memory."
  set public(events,async) "Waiting for I/O on an async (notify) buffer."
  set public(events,AsyncCtlLock) "Waiting to read or update shared notification state."
  set public(events,AsyncQueueLock) "Waiting to read or update notification messages."
  set public(events,AutoFile) "Waiting to update the postgresql.auto.conf file."
  set public(events,AutoFileLock) $public(events,AutoFile)
  set public(events,Autovacuum) "Waiting to read or update the current state of autovacuum workers."
  set public(events,AutovacuumSchedule) "Waiting to ensure that a table selected for autovacuum still needs vacuuming."
  set public(events,AutovacuumScheduleLock) $public(events,AutovacuumSchedule)
  set public(events,BackendRandomLock) "Waiting to generate a random number."
  set public(events,BackgroundWorker) "Waiting to read or update background worker state."
  set public(events,BackgroundWorkerLock) $public(events,BackgroundWorker)
  set public(events,BtreeVacuum) "Waiting to read or update vacuum-related information for a B-tree index."
  set public(events,BtreeVacuumLock) $public(events,BtreeVacuum)
  set public(events,buffer_content) "Waiting to read or write a data page in memory."
  set public(events,buffer_io) "Waiting for I/O on a data page."
  set public(events,buffer_mapping) "Waiting to associate a data block with a buffer in the buffer pool."
  set public(events,BufferContent) "Waiting to access a data page in memory."
  set public(events,BufferMapping) "Waiting to associate a data block with a buffer in the buffer pool."
  set public(events,CheckpointerComm) "Waiting to manage fsync requests."
  set public(events,CheckpointerCommLock) $public(events,CheckpointerComm)
  set public(events,CheckpointLock) "Waiting to perform checkpoint."
  set public(events,clog) "Waiting for I/O on a clog (transaction status) buffer."
  set public(events,CLogControlLock) "Waiting to read or update transaction status."
  set public(events,CLogTruncationLock) "Waiting to execute txid_status or update the oldest transaction id available to it."
  set public(events,commit_timestamp) "Waiting for I/O on commit timestamp buffer."
  set public(events,CommitTs) "Waiting to read or update the last value set for a transaction commit timestamp."
  set public(events,CommitTsBuffer) "Waiting for I/O on a commit timestamp SLRU buffer."
  set public(events,CommitTsControlLock) "Waiting to read or update transaction commit timestamps."
  set public(events,CommitTsLock) "Waiting to read or update the last value set for the transaction timestamp."
  set public(events,CommitTsSLRU) "Waiting to access the commit timestamp SLRU cache."
  set public(events,ControlFile) "Waiting to read or update the pg_control file or create a new WAL file."
  set public(events,ControlFileLock) $public(events,ControlFile)
  set public(events,DynamicSharedMemoryControl) "Waiting to read or update dynamic shared memory allocation information."
  set public(events,DynamicSharedMemoryControlLock) $public(events,DynamicSharedMemoryControl)
  set public(events,LockFastPath) "Waiting to read or update a process' fast-path lock information."
  set public(events,LockManager) "Waiting to read or update information about ¡°heavyweight¡± locks."
  set public(events,lock_manager) $public(events,LockManager)
  set public(events,LogicalRepWorker) "Waiting to read or update the state of logical replication workers."
  set public(events,LogicalRepWorkerLock) $public(events,LogicalRepWorker)
  set public(events,multixact_member) "Waiting for I/O on a multixact_member buffer."
  set public(events,multixact_offset) "Waiting for I/O on a multixact offset buffer."
  set public(events,MultiXactGen) "Waiting to read or update shared multixact state."
  set public(events,MultiXactGenLock) $public(events,MultiXactGen)
  set public(events,MultiXactMemberBuffer) "Waiting for I/O on a multixact member SLRU buffer."
  set public(events,MultiXactMemberControlLock) "	Waiting to read or update multixact member mappings."
  set public(events,MultiXactMemberSLRU) "Waiting to access the multixact member SLRU cache."
  set public(events,MultiXactOffsetBuffer) "Waiting for I/O on a multixact offset SLRU buffer."
  set public(events,MultiXactOffsetControlLock) "	Waiting to read or update multixact offset mappings."
  set public(events,MultiXactOffsetSLRU) "Waiting to access the multixact offset SLRU cache."
  set public(events,MultiXactTruncation) "Waiting to read or truncate multixact information."
  set public(events,MultiXactTruncationLock) $public(events,MultiXactTruncation)
  set public(events,NotifyBuffer) "Waiting for I/O on a NOTIFY message SLRU buffer."
  set public(events,NotifyQueue) "Waiting to read or update NOTIFY messages."
  set public(events,NotifyQueueTail) "Waiting to update limit on NOTIFY message storage."
  set public(events,NotifyQueueTailLock) $public(events,NotifyQueueTail)
  set public(events,NotifySLRU) "Waiting to access the NOTIFY message SLRU cache."
  set public(events,OidGen) "Waiting to allocate a new OID."
  set public(events,OidGenLock) $public(events,OidGen)
  set public(events,oldserxid) "Waiting to I/O on an oldserxid buffer."
  set public(events,OldSerXidLock) "	Waiting to read or record conflicting serializable transactions."
  set public(events,OldSnapshotTimeMap) "Waiting to read or update old snapshot control information."
  
  set public(events,BaseBackupThrottle) "Waiting during base backup when throttling activity."
  set public(events,PgSleep) "Waiting due to a call to pg_sleep or a sibling function."
  set public(events,RecoveryApplyDelay) "Waiting to apply WAL during recovery because of a delay setting."
  set public(events,RecoveryRetrieveRetryInterval) "Waiting during recovery when WAL data is not available from any source (pg_wal, archive or stream)."
  set public(events,VacuumDelay) "Waiting in a cost-based vacuum delay point."

  set public(events,WALInsert) "Waiting to insert WAL data into a memory buffer."
  set public(events,XactBuffer) "Waiting for I/O on a transaction status SLRU buffer."
  set public(events,XactSLRU) "Waiting to access the transaction status SLRU cache."
  set public(events,XactTruncation) "Waiting to execute pg_xact_status or update the oldest transaction ID available to it."
  set public(events,XidGen) "Waiting to allocate a new transaction ID."
  set public(events,ProcArray) "Waiting to access the shared per-process data structures (typically, to get a snapshot or report a session's transaction ID)."
  set public(events,SharedTidBitmap) "Waiting to access a shared TID bitmap during a parallel bitmap index scan."
}

proc get_event_type { event } {
  global public
  set cur_proc get_event_type
  set event_type "N/A"
  if { [ catch {
    set event_type $public(waits,$event)
  } err] } { puts "$cur_proc, err:$err"; } 
  return $event_type
}

proc get_event_desc { event } {
  global public
  set cur_proc get_event_desc  
  set event_desc "N/A"
  if { [ catch {
    set event_desc $public(events,$event)
  } err] } { puts "$cur_proc, err:$err"; }
  return $event_desc
}

proc set_pgcursors {} {
  global public

  set public(sql,cpucount) ""

  set public(sql,ashempty) "select count(*) from pg_active_session_history;"
  
  set public(sql,version) "SELECT version();"
  
  set public(sql,ashrpt) ""

  set public(sql,days) "select to_char(current_timestamp, 'J') as days;";
   
  set public(sql,secs) "select to_char(current_timestamp, 'SSSS') as secs;";

  set public(sql,ashtime) "select to_char((sample_time - interval '\$public(ash,loadhours) hours'),'J') as day, 
      to_char((sample_time - interval '\$public(ash,loadhours) hours'),'SSSS') as secs, 
      ceil(extract(epoch from sample_time)) as sample_id 
    from ( select max(ash_time) sample_time from pg_active_session_history) as st;"

  set public(sql,ash) "with ash as (select ash_time, 
        (case when wait_event_type='CPU' then 
          (case when backend_type='autovacuum launcher' then 'BCPU'
                when backend_type='autovacuum worker'   then 'BCPU'
                when backend_type='background worker'   then 'BCPU'
                when backend_type='background writer'   then 'BCPU'
                when backend_type='checkpointer' then 'BCPU'
                when backend_type='startup'      then 'BCPU'
                when backend_type='walreceiver'  then 'BCPU'
                when backend_type='walsender'    then 'BCPU'
                when backend_type='walwriter'    then 'BCPU'
                else 'CPU' end) else wait_event_type end), wait_event, 
        ceil(extract(epoch from max(ash_time)over()-min(ash_time)over()))::numeric samples, 
        ceil(extract(epoch from ash_time)) as sample_id, \$public(ash,bucket_secs) bucket 
      from pg_active_session_history where \$public(ash,where) and 
      ash_time >= current_timestamp - interval '\$public(ash,bucket_secs) seconds') 
    select max(to_char(ash_time,'SSSS')) as secs, sample_id, wait_event_type, 
      round(count(*)::numeric/(case when samples=0 then bucket else samples end),3) as AAS,
      CAST(to_char(ash_time,'SSSS') as INTEGER)/bucket*bucket as beg_secs, 
      (CAST(to_char(ash_time,'SSSS') as INTEGER)/bucket+1)*bucket as end_secs, 
      to_char(current_timestamp,'J') as last_day, to_char(min(ash_time),'J') as first_day 
    from ash group by samples,sample_id,wait_event_type,ash_time,bucket order by ash_time;"

    #set public(sql,ash_sqltxt) "select distinct query from pg_active_session_history where \$public(ash,sqlid);"
    #Query can have multiple rows for the same SQL with different predicates, limit to the most recent in the ASH
  set public(sql,ash_sqltxt) "select query from pg_active_session_history where \$public(ash,sqlid) order by xact_start desc limit 1;"

  set public(sql,ash_sqlplanx) ""
  
  set public(sql,ash_sqlplan) "explain \$public(ash,sqltxt);"

  set public(sql,ash_sqlstats) "select calls, total_exec_time, rows, 
      shared_blks_hit, shared_blks_read, shared_blks_dirtied, shared_blks_written, 
      local_blks_hit, local_blks_read, local_blks_dirtied, local_blks_written, 
      temp_blks_read, temp_blks_written, blk_read_time, blk_write_time, 
      coalesce(plans,0) as plans, coalesce(total_plan_time,0) as total_plan_time, 
      coalesce(wal_records,0) as wal_records, coalesce(wal_fpi,0) as wal_fpi, 
      coalesce(wal_bytes,0) as wal_bytes 
    from pg_stat_statements_history where \$public(ash,sqlid) order by calls desc limit 1;"
  
  set public(sql,ash_eventsqls) "select count(*) as total, query, wait_event, backend_type 
    from pg_active_session_history where \$public(ash,eventid) and
      ash_time >= to_timestamp('\$public(ash,beg)','J SSSS') and
      ash_time <= to_timestamp('\$public(ash,end)','J SSSS')
      group by query, wait_event, backend_type order by total desc limit 10;"
  
  set public(sql,ash_sqlevents) "select count(*) as total, wait_event_type, wait_event
    from pg_active_session_history 
    where ash_time >= to_timestamp('\$public(ash,beg)','J SSSS') and
          ash_time <= to_timestamp('\$public(ash,end)','J SSSS')
    group by wait_event_type, wait_event order by total desc;"
    #group by wait_event_type, wait_event, backend_type order by total desc;"
    #where ash_time>=current_timestamp - interval '\$public(ash,loadhours) hours' 

  set public(sql,ash_sqlsessions) "select pid, count(*) as Total,
      sum((case when wait_event_type = 'LWLock' then 1 else 0 end)) as LWLock, 
      sum((case when wait_event_type = 'Lock' then 1 else 0 end)) as Lock, 
      sum((case when wait_event_type = 'BufferPin' then 1 else 0 end)) as BufferPin, 
      sum((case when wait_event_type = 'Activity' then 1 else 0 end)) as Activity, 
      sum((case when wait_event_type = 'Extension' then 1 else 0 end)) as Extension, 
      sum((case when wait_event_type = 'Client' then 1 else 0 end)) as Client, 
      sum((case when wait_event_type = 'IPC' then 1 else 0 end)) as IPC, 
      sum((case when wait_event_type = 'Timeout' then 1 else 0 end)) as Timeout, 
      sum((case when wait_event_type = 'System_IO' then 1 else 0 end)) as System_IO, 
      sum((case when wait_event_type = 'IO' then 1 else 0 end)) as IO,
      sum((case when wait_event_type = 'CPU' and (backend_type='autovacuum launcher' 
        or backend_type='autovacuum worker' or backend_type='background worker' 
        or backend_type='background writer' or backend_type='checkpointer' 
        or backend_type='startup' or backend_type='walreceiver' 
        or backend_type='walsender' or backend_type='walwriter') then 1 else 0 end)) as BCPU,
      sum((case when wait_event_type = 'CPU' then 1 else 0 end)) as CPU, 
      usename, application_name
    from pg_active_session_history
    where ash_time >= to_timestamp('\$public(ash,beg)','J SSSS') and
          ash_time <= to_timestamp('\$public(ash,end)','J SSSS')
    group by pid, usename, application_name order by total desc;"
    #where ash_time>=current_timestamp - interval '15 seconds' 

  set public(sql,ash_sqldetails) "select QueryID, count(*) as Total,
      sum((case when wait_event_type = 'LWLock' then 1 else 0 end)) as LWLock, 
      sum((case when wait_event_type = 'Lock' then 1 else 0 end)) as Lock, 
      sum((case when wait_event_type = 'BufferPin' then 1 else 0 end)) as BufferPin, 
      sum((case when wait_event_type = 'Activity' then 1 else 0 end)) as Activity, 
      sum((case when wait_event_type = 'Extension' then 1 else 0 end)) as Extension, 
      sum((case when wait_event_type = 'Client' then 1 else 0 end)) as Client, 
      sum((case when wait_event_type = 'IPC' then 1 else 0 end)) as IPC, 
      sum((case when wait_event_type = 'Timeout' then 1 else 0 end)) as Timeout, 
      sum((case when wait_event_type = 'System_IO' then 1 else 0 end)) as System_IO, 
      sum((case when wait_event_type = 'IO' then 1 else 0 end)) as IO, 
      sum((case when wait_event_type = 'CPU' and (backend_type='autovacuum launcher' 
        or backend_type='autovacuum worker' or backend_type='background worker' 
        or backend_type='background writer' or backend_type='checkpointer' 
        or backend_type='startup' or backend_type='walreceiver' 
        or backend_type='walsender' or backend_type='walwriter') then 1 else 0 end)) as BCPU,
      sum((case when wait_event_type = 'CPU' then 1 else 0 end)) as CPU, 
      CmdType
    from pg_active_session_history
    where ash_time >= to_timestamp('\$public(ash,beg)','J SSSS') and
          ash_time <= to_timestamp('\$public(ash,end)','J SSSS')
    group by queryid, cmdtype order by total desc;"
    #where ash_time>=current_timestamp - interval '15 seconds' 

  set public(sql,sqlovertimeload) "select wait_event_type, last_secs, cnt, last_id, last_day 
    from (
      select distinct wait_event_type,
        to_char(LAST_VALUE(ash_time) OVER ( partition by modsecs ORDER BY sample_id
          ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),'SSSS') last_secs,
        count(wait_event_type) OVER (partition by wait_event_type, modsecs ORDER BY wait_event_type
          ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) cnt,
        LAST_VALUE(sample_id) OVER ( partition by modsecs ORDER BY sample_id
          ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) last_id,
        to_char(LAST_VALUE(ash_time) OVER ( partition by modsecs ORDER BY sample_id
          ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),'J') last_day,
        modsecs
      from (
        select
          ash_time,
          ceil(extract(epoch from ash_time)) as sample_id,
          trunc(CAST(to_char(ash_time,'SSSS') as INTEGER)/\$public(ashsql,bucket_secs)) modsecs,
          wait_event_type
        from pg_active_session_history
        where ash_time > to_timestamp('\$public(ash,starttime)','J SSSS') and \$public(ashsql,sqlovertimeid)
      ) ash 
      order by last_day, modsecs 
    ) as last;"

  set public(sql,stat) ""

  set public(sql,txrlc) ""
  
  set public(sql,bbw) ""
  
  set public(sql,hw) ""
  
  set public(sql,cbc) ""
  
  set public(sql,sqlio) "select wait_event, count(*) as total 
    from pg_active_session_history where wait_event_type = 'IO' and 
      ash_time>=current_timestamp - interval '\$public(ash,loadhours) hours' 
    group by wait_event order by total desc;"
  
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
  set public(fg)        black
  set public(bg)        $defaultBackground
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

proc pg_post_kill_dbmon_cleanup {} {
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
          thread::send -async $dbmon_threadID "pg_logoff $public(parent) $public(handle)"
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
      after 2000 pg_post_kill_dbmon_cleanup
    }
  }
}

proc pgmetrics { } {
  global env public pgmetrics_firstrun dbmon_threadID
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
          pg_post_kill_dbmon_cleanup
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
  connect_to_postgresql
}
}
