#Oracle Database Metrics based on Ashmon v2 by Kyle Hailey
#All code copied from Ashmon used with permission to modify and release open source under GPLv3 license
namespace eval oramet {
namespace export create_metrics_screen display_tile display_only colors1 colors2 colors getcolor getlcolor generic_time cur_time secs_fetch days_fetch ash_init reset_ticks ashtime_fetch ses_tbl sql_tbl emptyStr stat_tbl plan_tbl evt_tbl createSesFrame createSqlFrame createevtFrame create_ash_cpu_line ash_bars ash_displayx ash_fetch ash_details ash_sqldetails_fetch ash_sqlsessions_fetch ash_sqltxt ashrpt_fetch ash_sqltxt_fetch ash_sqlstats_fetch ash_sqlplan_fetch ash_sqlevents_fetch sqlovertime_fetch sqlovertime ashsetup vectorsetup addtabs graphsetup outputsetup waitbuttons_setup sqlbuttons_setup cbc_fetch sqlio_fetch io_fetch bbw_fetch hw_fetch txrlc_fetch wait_analysis connect_to_oracle putsm thread_init just_disconnect ora_logon ora_logoff callback_connect callback_set callback_fetch callback_err callback_mesg disconnect ora_exit connect test_connect lock unlock cpucount_fetch version_fetch mon_init mon_loop mon_execute mon_execute_1 set_ora_waits set_oracursors init_publics post_kill_dbmon_cleanup orametrics

variable firstconnect "true"

proc create_metrics_screen { } {
global public metframe win_scale_fact
upvar #0 env e
set metframe .ed_mainFrame.me
if {  [ info exists hostname ] } { ; } else { set hostname "localhost" }
if {  [ info exists id ] } { ; } else { set id 0 }
ed_stop_metrics
.ed_mainFrame.notebook tab .ed_mainFrame.me -state normal
.ed_mainFrame.notebook select .ed_mainFrame.me
   set main $public(main)
   set menu_frame $main.menu
   set public(menu_frame) $menu_frame
   set public(p_x) [ expr {round((600/1.333333)*$win_scale_fact)} ]
   set public(p_y) [ expr {round((654/1.333333)*$win_scale_fact)} ]
if { ![winfo exists .ed_mainFrame.me.m] } {
  frame $main -background  $public(bg) -borderwidth 0 
  frame $main.f -background  $public(bg) -borderwidth 0 ;# frame, use frame to put tiled windows
  pack $main                           -expand true -fill both 
  pack [ ttk::sizegrip $main.grip ] -side bottom -anchor se
  pack $main.f                         -expand true -fill both  
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
 } err ] } {  ;   }
}

proc display_only { {name "" } {proc  "" }    } {
global public
  set cur_proc display_only ; 
  if { [ catch {
    foreach child [ winfo children $public(screen) ] {
           pack forget $child 
    }
    if { $name != "" } { 
      pack    $name   -expand true -fill both 
    }
 } err ] } {  ;  }
}
proc colors1 { } {
global public
set num_colors 0
foreach color {  red orange yellow green blue purple 
             } {
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

  set colors { SeaGreen4 HotPink2  aquamarine3  purple4  cyan4 MediumPurple3   blue 
                 plum3  Orange3  magenta3  goldenrod2   VioletRed4 yellow  
		  firebrick3 OliveDrab3   tomato1 SpringGreen3   
             } 
  set colors { aquamarine3  cyan4  blue purple4 MediumPurple3 
                 plum3 magenta3 HotPink2 VioletRed4 firebrick3  tomato1 Orange3 
                 goldenrod2  yellow OliveDrab3 SpringGreen3 
                 SeaGreen4
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

proc getcolor { idx } {
global public
 incr  public(colors,count)
 if { $public(colors,count) >= $public(clr,max) } { set public(colors,count) 0 }
 set   public(color,$idx)      $public(clr,$public(colors,count))
 set   color $public(color,$idx)
 return $color
}

proc getlcolor { } {
global public
 incr  public(lcolors,count)
 if { $public(lcolors,count) >= $public(lclr,max) } { 
       set public(lcolors,count) 0 }
 return    $public(lclr,$public(lcolors,count))
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
    if { $pts > 1 }  {
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
     set public(secs) [ lindex $args 1 ] 
     unlock public(thread_actv) $cur_proc
   } err ] } { ; }
}

proc days_fetch { args }  {
global public
   set cur_proc days_fetch 
   if { [ catch {
     set public(today)  [ lindex $args 1 ]
     unlock public(thread_actv) $cur_proc
  } err ] } { ; }
}

   option add *Tablelist.labelCommand        tablelist::sortByColumn

proc ash_init { { display  0 } } {
upvar #0 env e
global public
   set cur_proc ash_init 
    if { [ catch {
   set ash_frame     $public(main).f.a
   set public(type)  ash
   if { [ winfo exists $ash_frame  ] } {
          if { $display == 1 } {  
                                 display_tile $ash_frame ash
                                 set public(collect,ash) 1
                               }
          return
   }

   ttk::panedwindow  $ash_frame  -orient vertical
   set public(ash_frame) $ash_frame
   ttk::panedwindow .ed_mainFrame.me.m.f.a.topdetails  -orient horizontal 
  
   #===========================
   # contains 3 children
   # GRAPH
   # Row 1 - Graph
   set    graph_frame    $ash_frame.gf
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
   set   sqlstat_frame   $public(ash,output_frame).stats
   ttk::frame  $sqlstat_frame
   set public(ash,sqlstats_frame) $sqlstat_frame
   stat_tbl  $public(ash,sqlstats_frame) 100 32 "statistc total per_exec per_row delta"
   set public(ash,stattbl) $public(ash,sqlstats_frame).tbl

   graphsetup
   sqlbuttons_setup 
   waitbuttons_setup 

    pack $tops_frame -side top -expand no -fill none -anchor nw 
    pack $sql_frame -in $tops_frame -side top -expand no -fill none -anchor nw 
    pack $evt_frame -in $tops_frame -side top -expand no -fill none -anchor nw 
    pack $ses_frame -in $tops_frame -side top -expand no -fill none -anchor nw 

   # Session 
   ses_tbl  $public(ash,ses_frame) 60 10  " user_name %Active Activity SID  $public(ash,groups) "
   set public(ash,sestbl) $public(ash,ses_frame).tbl

   # Wait events
   evt_tbl  $public(ash,evt_frame) 60 10 { "event" "%Total_Time" "Activity" "Group" }
   set public(ash,evttbl) $public(ash,evt_frame).tbl

   # Sql                     
   sql_tbl  $public(ash,sql_frame) 60 10 "SQL_ID %Total_DB_Time Activity SQL_TYPE plan_hash $public(ash,groups)"
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

proc ashtime_fetch { args }  {
global public
   set cur_proc ashtime_fetch  
   if { [ catch {
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           set day   [lindex $row 0]   
           set secs  [lindex $row 1]   
        }
     }
     set public(ash,starttime) "${day}${secs}"
     set public(ash,startday) "${day}"
     # ash,time used just below in cursor where clause in variable ash,where
     set public(ash,time) "${day}${secs}"
     set public(ash,day)  "$day"
    # secs is not needed here, gets set again and used in ash_fetch 
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
  set public(ash,bucket_secs) $public(ash,load_bucket_secs)
  set public(ash,where) "sample_time > to_date('$public(ash,time)','JSSSSS')"
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

          $public(ash,output) insert  insert "   session id $id "
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
     foreach  col $cols {
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
          pack  forget $public(ash,details_buttons).wait -side left
          pack         $public(ash,details_buttons).sql -side left
          if { [ $public(ash,sqltbl) containing $tablelist::y] > -1 } {
            set id  [ $public(ash,sqltbl) cellcget [ $public(ash,sqltbl) containing [subst $tablelist::y]],id -text]
            set public(sqltbl,cell)  [ $public(ash,sqltbl) containing $tablelist::y],0 
            $public(ash,sqltbl) cellselection clear 0,0 end,end
            $public(ash,sqltbl) cellselection set $public(sqltbl,cell)
            update idletasks
            clipboard clear
            clipboard append $id
            set public(ash,realsqlid) $id
            ash_sqltxt  $id
            if { "$public(ash,overtimeid)" == "$id" } {
                 $public(ash,sqltbl) configure -selectbackground  #FF7900 
                 $public(ash,sqltbl) configure -selectforeground  black 
                 update idletasks
                 sqlovertime $id
                 set public(ash,overtimeid) -1
            } else { 
                 $public(ash,sqltbl) configure -selectbackground #FF7900
                 $public(ash,sqltbl) configure -selectforeground  black 
                 update idletasks
                 set public(ash,overtimeid) $id 
                 sqlovertime clear
            }
          } else {
            $public(ash,sqltbl) cellselection clear 0,0 end,end
            $public(ash,sqltbl) configure -selectbackground  white
            $public(ash,sqltbl) configure -selectforeground  black 
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
         if { $row == 4 } { $tbl columnconfigure 3  -name "plan_hash" -width 5}
         if { $row >  4 } { $tbl columnconfigure $row  -name $col  \
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
          set id  [ $public(ash,evttbl) cellcget [ $public(ash,evttbl) containing [subst $tablelist::y]],id -text]
          $public(ash,evttbl) cellselection clear 0,0 end,end
          $public(ash,evttbl) configure -selectbackground  white
          $public(ash,evttbl) configure -selectforeground  black 


          $public(ash,output) delete 0.0 end
          #$public(ash,output) insert  insert "   working ... "
          $public(ash,output) insert  insert "   session id $id "
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
    for { set i 4 } { $i <  $colcnt  } { incr  i }  {
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
    set pc [ expr (($total + 0.0)/($delta )) * (100.0/142)     ]
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
    for { set i 5 } { $i <  $colcnt  } { incr  i }  {
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
    set width [ format "%3.0f" $width ] 
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
               -color red     \
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
      set sum   0
     update idletasks
   } err ] } { ; }
}

proc ash_fetch { args }  {
global public
   set cur_proc ash_fetch  
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
     foreach  row [ lindex $args 1 ]  {
           set idx          [lindex $row 0]   
           set secs         [lindex $row 1]
           set cnt          [lindex $row 2]
           set sampid       [lindex $row 3]  
           set end_day      [lindex $row 4] 
           set beg_secs     [lindex $row 5] 
           set end_secs     [lindex $row 6] 
           set beg_day      [lindex $row 7] 
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
	      set public(ash,where)  "sample_id > $public(ash,sample_id)"
        }
     #
     # Valid Group (if group is like IDLE skip )
     #
     if {  [ info exists public(waits,"$idx")  ]  } {
	     set idx $public(waits,"$idx")  
     } else {
             set idx "Other"
     } 
     if {  1 == 1  } {
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
              set  sample_id(++end)   $sampid 
              set  [set cpu_vec](++end)  $public(cpucount)
              #  Secs & dates
              if {  $j == 1  || $j == 2  } {
                set  [set xvec](++end)  $beg_time
                set ash_sec(++end)      $beg_secs
                set ash_day(++end)      $beg_day
              } 
              if { $j == 3 || $j == 4 } {
                set  [set xvec](++end)  $end_time
                set ash_sec(++end)      $end_secs
                set ash_day(++end)      $end_day
              }
              #  Values
              foreach id $public(ash,bars) {
                set id_vec y_w_$id
		set val 0
                set [set id_vec](++end)  $val
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
          set aas [ expr ( $cnt + 0.0 )  / $public(ash,delta)   ]
          set aas [ format "%6.3f" $aas]
          # 
          # AAS CURRENT - Set current Vector
          # 
          set curval  [ set [set yvec]($end_idx) ]
          set total_aas [ expr $curval + $aas ]
	  set val  [ expr $aas + $curval ]
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
           set  [set yvec]($beg_idx)   $val
          }
          set  [set yvec]($end_idx)   $val
        } else {
        };# exists public(ashgroup,$idx)
    } ;# for each row
    # 
    # no data collected, update graph with zero values and new time point
    # 
    if { $pts == 0 } {
            set day     [ set ash_day(end) ] 
            set vecsecs  [ set ash_sec(end) ] 
            set newsecs [ expr $vecsecs  + $public(ash,bucket_secs)  ]
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
              set  sample_id(++end)   $newsample_id
              set  [set xvec](++end)  $newtime 
              set ash_sec(++end) $newsecs
              set ash_day(++end) $day
              # CPU line 
              set cpu_vec y_ash_maxcpu
              set  [set cpu_vec](++end)  $public(cpucount)
              #  Values
              foreach id $public(ash,bars) {
                set id_vec y_w_$id
		set val 0
                set [set id_vec](++end)  $val
              }
            }
	    set len [ sample_id length ]
    }
    # 
    # if sampling rate changes
    # 
    set public(ash,bucket_secs) $public(sleep,fast) 
    set  public($cur_proc) 0; unlock public(thread_actv) $cur_proc
    # 
    # cascade
    # 
    # update the top sql list
    set hide [ lindex [ $public(ash,graph) marker configure marker1 -hide ]  4 ]
    if { $hide == 1 } {
       incr public(ash,cascade) 
       set end [ [set xvec] length ]
       set end [ expr $end - 1 ]
       set beg [ expr $end - 4 ]
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
        set time [ expr ( ( $end_day - 2450000 ) * 24*3600 ) + $end_secs ]  
        set  [set xvec](end)  $time 
        set  [set xvec]($end_idx)  $time 
        set public(ash,first) 0 
     }
     # resets the ticks
     reset_ticks
  } err] } { ; } 
}

proc ash_details { beg end } {
global public
   global sample_id
   global x_w_ash
   global ash_sec
   global ash_day
   set cur_proc ash_details  
   set beg [ expr $beg - 0 ]
   set end [ expr $end - 0 ]
   if { [ catch {
     set public(ash,begid) [ set sample_id($beg)]
     set public(ash,endid) [ set sample_id($end)]
     set begday [ set ash_day($beg)]
     set begsec [ expr [ set ash_sec($beg)] - 0 ]
     set endday [ set ash_day($end)]
     set endsec [ expr [ set ash_sec($end)] + 0 ]
     set public(ash,beg) [ format "%06.0f%05.0f" $begday $begsec ]
     set public(ash,end) [ format "%06.0f%05.0f" $endday $endsec ]
     set public(ash,sesdelta)  [ expr [set public(ash,end) ] - [ set public(ash,beg) ] ]
     mon_execute  ash_sqldetails
   } err] } { ; } 
}

proc ash_sqldetails_fetch { args }  {
global public
   set cur_proc ash_sqldetails_fetch  
   if { [ catch {
     set public(sqltbl,maxActivity)  0
     $public(ash,sqltbl) delete 0 end 
     $public(ash,output) delete 0.0 end
     $public(ash,evttbl) delete 0 end 
     $public(ash,sestbl) delete 0 end
     #$public(ash,output) insert  insert "   working ... "
     set public(ashtbl,delta) [ expr $public(ash,endid)  - $public(ash,begid) ]
     if { $public(ashtbl,delta) == 0 } {
        set public(ashtbl,delta) $public(ash,bucket_secs)
     }
     set sqlid "" 
     set sum 0 
     update idletasks
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 1 ] != "" } {
             set idx            [lindex $row 0]   ;# event number
             set activity       [lindex $row 1] 
             set i 2
             set wg ""
             foreach wc $public(ash,groups) {
                   lappend wg [ lindex $row $i ]
                   incr i
             }
             set opcode         [lindex $row $i] 
             incr i
             set plan_hash      [lindex $row $i] 
           
             set sum [ expr $sum + $activity ]
             set public(sqltbl,maxActivity) $sum
              set sqlid $idx
             $public(ash,sqltbl) insert end [concat \"$idx\"  $activity $activity \"$opcode\" $plan_hash $wg ] 
         }
     } 
     set rowCount [$public(ash,sqltbl) size]
     for { set row 0 } { $row < $rowCount } { incr row } {
         $public(ash,sqltbl) cellconfigure $row,1 -window createSqlFrame 
     }
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
  if { [ catch {
      $public(ash,output) delete 0.0 end

   # cascade - fill in others
      ash_sqltxt $sqlid

      $public(ash,sqltbl) cellselection clear 0,0 end,end
      $public(ash,sqltbl) cellselection set 0,0 
  } err] } { ; } 
} 

proc ash_sqlsessions_fetch { args }  {
global public
   set cur_proc ash_sqlsessions_fetch  
   if { [ catch {
     set public(tbl,maxActivity)  0
     set delta $public(ash,sesdelta)
     $public(ash,sestbl) delete 0 end 
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 1 ] != "" } {
             set idx            [lindex $row 0]   ;# event number
             set activity       [lindex $row 1]
             set i 2
             set wg ""
             foreach wc $public(ash,groups) {
                   lappend wg [ lindex $row $i ]
                   incr i
             }
             set user           [lindex $row $i]
             incr i
             set program        [lindex $row $i]
             # program can be of the for "oracle.exe (smon)"
             # get rid of the "oracle.exe" part
             regsub {.*\(} $program "" program
             regsub {\)} $program "" program
             $public(ash,sestbl) insert end [concat \"$user $program\" $activity $activity $idx $wg ] 
         }
     } 
     set rowCount [$public(ash,sestbl) size]
     for { set row 0 } { $row < $rowCount } { incr row } {
         $public(ash,sestbl) cellconfigure $row,1 -window createSesFrame 
     }
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}

proc ash_sqltxt { sqlid }  {
global public
   set cur_proc ash_sqltxt  
   if { $sqlid == "{}" } {  set sqlid "" }
   if { $sqlid == "" } {
      set public(ash,sqlid) " sql_id is NULL "
   } else {
      set public(ash,sqlid) " sql_id = \'$sqlid\' "
   }                                                                    
        mon_execute  ash_sqltxt
     regsub {\..*} $public(version) "" t
     if { $t > 9 } { ; }
   mon_execute  ash_sqlevents
   mon_execute  ash_sqlsessions
}

proc ashrpt_fetch { args }  {
global public
   set cur_proc ashrpt_fetch  
   if { [ catch {
     $public(ash,output) delete 0.0 end
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           $public(ash,output) insert insert [lindex $row 0]   
           $public(ash,output) insert insert "\n"
        }
     }
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}

proc ash_sqltxt_fetch { args }  {
global public
   set cur_proc ash_sqltxt_fetch  
   if { [ catch {
     $public(ash,output) delete 0.0 end
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           $public(ash,output) insert insert [lindex $row 0]   
        }
     }
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}

proc ash_sqlstats_fetch { args }  {
global public
   set cur_proc ash_sqlstats_fetch  
   if { [ catch {
     $public(ash,stattbl) delete 0 end
     set i 0
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
                foreach val {  
                        executes  
                        cpu_time  
                        elapsed_time  
                        buffer_gets  
                        disk_reads  
                        direct_writes  
                        rows 
                        fetches 
                } { 
                     set val1 [ lindex $row $i ]
                     set val2 [ format "%0.2f" [ lindex $row [ expr $i + 8  ]  ] ]
                     set val3 [ format "%0.2f" [ lindex $row [ expr $i + 16 ]  ] ]
                     set val4 [  lindex $row [ expr $i + 24 ]  ] 
                     while {[regsub {^([-+]?\d+)(\d{3})} $val1 {\1,\2} val1]} {}
                     while {[regsub {^([-+]?\d+)(\d{3})} $val2 {\1,\2} val2]} {}
                     while {[regsub {^([-+]?\d+)(\d{3})} $val3 {\1,\2} val3]} {}
                     while {[regsub {^([-+]?\d+)(\d{3})} $val4 {\1,\2} val4]} {}
                     $public(ash,stattbl) insert end [ list  $val $val1 $val2 $val3 $val4 ]
                     incr i
                }
        }
     }
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}

proc ash_sqlplan_fetch { args }  {
global public
   set cur_proc ash_sqlplan_fetch  
   if { [ catch {
   $public(ash,output) delete 0.0 end
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           regsub "{" $row "\n" row
           regsub "}" $row "" row
           $public(ash,output) insert end $row
        }
     }
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}

proc ash_sqlevents_fetch { args }  {
global public
   set cur_proc ash_sqlevent_fetch  
   $public(ash,evttbl) delete 0 end 
   set total 0
   if { [ catch {
     set  public(tbl,maxActivity)  0 
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           set idx       [lindex $row 0]   
           set activity  [lindex $row 1]
           set group  [lindex $row 2]
           set total [ expr $total + $activity ]
          if { $public(tbl,maxActivity) == 0 } {
                set public(tbl,maxActivity) $activity
          }
             $public(ash,evttbl) insert end [list $idx $activity $activity $group]
         }
     } 
     set rowCount [$public(ash,evttbl) size]
     set public(ashevt,total) $total
     for { set row 0 } { $row < $rowCount } { incr row } {
         $public(ash,evttbl) cellconfigure $row,1 -window createevtFrame 
     }
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}

proc sqlovertime_fetch { args }  {
global public
   set cur_proc sqlovertime_fetch  
   if { [ catch {
     set xvec x_ashsql
     global $xvec
     set pts 0
     set maxid 0
     set maxtime 0
     foreach  row [ lindex $args 1 ]  {
           set idx          [lindex $row 0]   
           set secs         [lindex $row 1]
           set cnt          [lindex $row 2]
           set id           [lindex $row 3]  
           set day          [lindex $row 4] 
           set time     [ expr ( ( $day - 2450000 ) * 86400 ) + $secs ]  
        if {  [ info exists public(ashgroup,$idx)  ]   } {
          if { $pts == 0 } {
             incr pts
             set  [set xvec](++end)  $time
             foreach tmp_idx $public(ashsql,bars) {
                    set vec y_ashsql_$tmp_idx
                    global $vec
                    set [set vec](++end)  0
             }
        }
        #
        if { $id  >  $maxid  } { 
            # if it's the first row, make the delta reasonable not bignumber - 0
            if { $maxid == 0 } {
                 set delta $public(ashsql,bucket_secs) 
            } else {
               set newdelta [ expr $id - $maxid ]
               if { $newdelta != 0 }  { set delta $newdelta }
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
            while { [ expr $time - $maxtime  ] >  [ expr 1.5 *$public(ashsql,bucket_secs) ] && $maxtime > 0} {
              set maxtime [ expr $maxtime +  $public(ashsql,bucket_secs) ]
              set  [set xvec](++end)  $maxtime 
              foreach tmp_idx $public(ashsql,bars) {
                  set vec y_ashsql_$tmp_idx
                      global $vec
                  set [set vec](++end)  0
              }
            }
            set maxtime $time
            # NEW POINT y axis & sample_id
            set  [set xvec](++end)  $time
            # NEW POINT
            # add a new point to each vector for the new bar
            foreach tmp_id $public(ashsql,bars) {
              set vec y_ashsql_$tmp_id
              global $vec
              set [set vec](++end)  0
            }
          } ;# NEW POINT
          # AAS 
          set aas [ expr ( $cnt + 0.0 )  / $delta   ]
          set aas [ format "%6.3f" $aas]
          # AAS CURRENT
          # Set current Vector
          set curval  [ set [set yvec](end) ]
          set total_aas [ expr $curval + $aas ]
          set  [set yvec](end)   [ expr $aas + $curval ]
          # the last point doesn't seem to get drawn, adding a dummy extra point
      } else {
      } ;# exists public(ashgroup,$idx)
    } ;# for each row
  } err] } { ; } 
   set  public($cur_proc) 0; unlock public(thread_actv) $cur_proc
};#sqlovertime_fetch 

proc sqlovertime { sqlid }  {
global public
   set cur_proc sqlovertime  
   if { [ catch {

        set id_vec x_ashsql
        global $id_vec
        [set id_vec] length  0
        foreach id $public(ashsql,bars) {
            set id_vec y_ashsql_$id
            global $id_vec
            [set id_vec] length  0
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
            if { $sqlid == "{}" } {  set sqlid "" }
            if { $sqlid == "" || $sqlid == "{}" } {
              set public(ashsql,sqlovertimeid) " sql_id is NULL "
            } else {
              set public(ashsql,sqlovertimeid) " sql_id = \'$sqlid\' "
            }
            set public(ashsql,bucket_secs) $public(ash,load_bucket_secs)
            set public(sql,sqlovertime) $public(sql,sqlovertimeload)
            mon_execute sqlovertime
         }
  } err] } { ; } 
} 

proc ashsetup { newtab }  {
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
  } err] } { ; } 
} 

proc vectorsetup { }  {
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
                     { #8B1A00 dark_red }
                     { #5C440B dark_brown }
                     { #E46800 orange }
                     { #4080F0 light_blue }
                     { #004AE7 blue }
                     { #00CC00 green }
                     { #00FF00 bright_green }
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
               Network 
               Application 
               Administrative 
	       Cluster
               Concurrency 
               Configuration 
               Commit 
               System_IO 
               User_IO 
               CPU 
               BCPU }
      # list of id# of the wait groups
      set public(ashgroups) "" 
      #                                    
      #  ID # list for Wait Groups
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
      create_ash_cpu_line 
      for { set i $groups } { $i >= 0 } { incr  i -1 }  {
          set idx    $public(ashwc,$i)
          set color  $public(ashcolor,$i)
          set public(ashgroup,$idx)  $color
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
      set groups [ expr [ llength $public(ashgroups) ]  - 1 ]
      for { set i $groups } { $i >= 0 } { incr  i -1 }  {
          set idx    $public(ashwc,$i)
          set color  $public(ashcolor,$i)
          set public(ashgroup,$idx)  $color
          set public(ash,$idx) $i
          set xvec x_w_ash
          set yvec y_w_$idx
          ash_bars $xvec $yvec $public(ash,graph) $idx $idx  $color
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
  } err] } { ; } 
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
			     reset_ticks }  -padx 10 -pady 0 
  pack $public(ash,xminentry).minus -side right -ipadx 0 -ipady 0 -padx 0 -pady 0 
  pack $public(ash,xminentry).plus -side right -ipadx 0 -ipady 0 -padx 0 -pady 0 
  } err] } { ; } 
}

proc graphsetup { } {
global public
upvar #0 env e
   set cur_proc   graphsetup
   if { [ catch {
   #set graph          .ash_graph
   set graph          .ed_mainFrame.me.m.f.a.gf.ash_graph
   set public(ash,graph) $graph

   barchart $public(ash,graph)   \
        -relief flat                   \
        -barmode overlap               \
        -bg $public(bgt)                \
	-borderwidth  0 \
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
   $graph axis   configure x  -minorticks 0  \
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

   pack $public(ash,graph)     -in $public(ash,graph_frame) -expand yes -fill both -side top -ipadx 0 -ipady 0 -padx 0 -pady 0 

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
  } err] } { ; } 
   } 
   
   bind $public(ash,graph)  <ButtonPress-1> {
   if { [ catch {
      set start  [%W axis invtransform x %x] 
      set public(ash,beg_x) %x
      $public(ash,graph) marker configure marker1 -hide 0
      $public(ash,graph) marker configure marker2 -hide 0
      $public(ash,graph) marker configure marker1 -coords [ subst { $start 0  $start Inf  $start Inf  $start 0 } ]
      $public(ash,graph) marker configure marker2 -coords [ subst { $start 0  $start Inf  $start Inf  $start 0 } ]
  } err] } { ; } 
   } 
   
   bind $public(ash,graph)  <B1-Motion> {
   if { [ catch {
      set end  [%W axis invtransform x %x] 
      $public(ash,graph) marker configure marker1 -coords [ subst { $start 0  $start Inf  $end Inf  $end 0 } ]
      $public(ash,graph) marker configure marker2 -coords [ subst { $start 0  $start Inf  $end Inf  $end 0 } ]
  } err] } { ; } 
   } 
  } err] } { ; } 
}

proc outputsetup { output } {
global public
upvar #0 env e
   set cur_proc   outputsetup
   if { [ catch {
    set   output    $public(ash,output_frame).txt
    frame $output   -bd 0  -relief flat -bg $public(bgt)
    frame $output.f
    text $output.w  -yscrollcommand "$output.scrolly set" \
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
    pack  $output.w -in $output.f -expand yes -fill both
    set public(ash,output) $output.w
    $public(ash,output) insert insert "Monitor Active"
    pack $output -expand yes -fill both
  # SQL TEXT  - END
  } err] } { ; } 
}
proc waitbuttons_setup { } {
global public
upvar #0 env e
   set cur_proc   waitbuttons_setup
   if { [ catch {

   set waitbuttons $public(ash,details_buttons).wait 
   frame $waitbuttons -bd 0 -relief flat -bg $public(bgt) -height 10

   ttk::button $waitbuttons.wait1 -text "Clear" -command {
      $public(ash,output) delete 0.0 end
      #$public(ash,output) insert  insert "   waitbutton ... \n"
   }
   pack  $waitbuttons.wait1 -side left

  } err] } { ; } 
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
           mon_execute  sqlio
  }
  ttk::button $sqlbuttons.plan -text "sql plan" -command {
           set public(ash,sqldetails)  plan
           pack   forget $public(ash,output_frame).f
           pack   forget $public(ash,output_frame).sv
           pack   forget $public(ash,output_frame).stats
           pack   $public(ash,output_frame).txt -side left -anchor nw
           mon_execute  ash_sqlplan
  }
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
  pack  $sqlbuttons.plan -side left
  pack  $sqlbuttons.sqlio -side left
  pack  $sqlbuttons.stats -side left
  pack  $sqlbuttons.cpu -side left
 # don't pack ashrpt as too slow to respond and causes lockup
 # pack  $sqlbuttons.ashrpt -side left
  } err] } { ; } 
}

proc cbc_fetch { args }  {
global public
   set cur_proc cbc_fetch  
   if { [ catch {
   $public(ash,output) delete 0.0 end
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           regsub "{" $row "" row
           regsub "}" $row "" row
           $public(ash,output) insert end "$row\n"
        }
     }
    $public(ash,output) insert end "\n"
    $public(ash,output) insert end "\n"
    $public(ash,output) insert end "[ subst $public(sql,cbc) ] \n"
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}


proc sqlio_fetch { args }  {
global public
   set cur_proc sqlio_fetch  
   if { [ catch {
   $public(ash,output) delete 0.0 end
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           regsub "{" $row "" row
           regsub "}" $row "" row
           $public(ash,output) insert end "$row\n"
        }
     }
    $public(ash,output) insert end "\n"
    $public(ash,output) insert end "\n"
    $public(ash,output) insert end "[ subst $public(sql,sqlio) ] \n"
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}


proc io_fetch { args }  {
global public
   set cur_proc io_fetch  
   if { [ catch {
   $public(ash,output) delete 0.0 end
   $public(ash,output) insert end " \n"
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           regsub "{" $row "" row
           regsub "}" $row "" row
           $public(ash,output) insert end "$row\n"
        }
     }
    $public(ash,output) insert end " \n"
    $public(ash,output) insert end " \n"
    $public(ash,output) insert end "[ subst $public(sql,io) ] \n"
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}


proc bbw_fetch { args }  {
global public
   set cur_proc bbw_fetch  
   if { [ catch {
    $public(ash,output) insert end "\n SID  BSID         P1         P2 OBJ                  OTYPE           FILEN   BLOCKN SQL_ID        BLOCK_TYPE\n"
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           regsub "{" $row "" row
           regsub "}" $row "" row
           $public(ash,output) insert end "$row\n"
        }
     }
         $public(ash,output) insert  insert "   $cur_proc: mon_execute bbw finished\n"
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}


proc hw_fetch { args }  {
global public
   set cur_proc hw_fetch  
   if { [ catch {
    $public(ash,output) insert end "TIME   EVENT                SID LM P2 P3 OBJ TYPE FILE BLOCK SQL BSID\n" 
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           regsub "{" $row "" row
           regsub "}" $row "" row
           $public(ash,output) insert end "$row\n"
        }
     }
         $public(ash,output) insert  insert "   $cur_proc: mon_execute hw finished\n"
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}


proc txrlc_fetch { args }  {
global public
   set cur_proc txrlc_fetch  
   if { [ catch {
    $public(ash,output) insert end "TIME   EVENT                SID LM P2 P3 OBJ TYPE FILE BLOCK SQL BSID\n" 
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           regsub "{" $row "" row
           regsub "}" $row "" row
           $public(ash,output) insert end "$row\n"
        }
     }
       $public(ash,output) insert end "\n"
       $public(ash,output) insert end "\n"
       $public(ash,output) insert end "[ subst $public(sql,txrlc) ] \n"
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}


proc wait_analysis { id } {
global public
   set cur_proc   wait_analysis
   if { [ catch {
      pack forget $public(ash,details_buttons).sql 
      pack forget $public(ash,output_frame).f
      pack forget $public(ash,output_frame).sv
      pack forget $public(ash,output_frame).stats
      pack $public(ash,output_frame).txt -side left -anchor nw
      pack        $public(ash,details_buttons).wait -side left
      $public(ash,output) delete 0.0 end
      #$public(ash,output) insert  insert "   working ... \n"
      $public(ash,output) insert  insert "   $cur_proc: event :${id}: \n"
      $public(ash,output) insert  insert "   $cur_proc:  id $id \n"
      set toto [ string range $id 0 8 ] 
      $public(ash,output) insert  insert "   $cur_proc:toto $toto\n"
      if { [ string range $id 0 8 ] == "db file s" } {  
         $public(ash,output) insert  insert "   $cur_proc: mon_execute io\n"
	 update idletasks
	 mon_execute io
      }
      if { [ string range $id 0 6 ] == "enq: TX" } {  
         $public(ash,output) insert  insert "   $cur_proc: enq: TX - row lock contention  id $id \n"
         $public(ash,output) insert  insert "   $cur_proc: mon_execute txrlc\n"
	 update idletasks
	 mon_execute txrlc
      }
      if { $id == "buffer busy waits" } {  
         $public(ash,output) insert  insert "   $cur_proc: buffer busy wait id $id "
	 update idletasks
	 mon_execute bbw
      }
      if { $id == "enq: HW - contention" } {  
         $public(ash,output) insert  insert "   $cur_proc: buffer busy wait id $id "
	 update idletasks
	 mon_execute hw
      }
      if { $id == "latch: cache buffers chains" } {  
         $public(ash,output) insert  insert "   $cur_proc: latch: cache buffers chain $id "
	 mon_execute cbc
      }
  } err] } { ; } 
}

proc connect_to_oracle {} {
global public masterthread dbmon_threadID

upvar #0 configoracle configoracle
setlocaltcountvars $configoracle 0
set public(connected) 0
set public(un) $system_user
set public(pw) $system_password
set public(db) $instance
set remote "@$public(db)"
set con $public(un)/$public(pw)$remote
if { ! [ info exists dbmon_threadID ] } {
       set public(parent) $masterthread
       thread_init 
   } else {
return 1
	}
#Do logon in thread
thread::send  -async $dbmon_threadID "ora_logon $public(parent) $con public(handle)"
   test_connect
if { [ info exists dbmon_threadID ] } {
tsv::set application themonitor $dbmon_threadID
        }
}

proc putsm { message } {
puts "$message"
	}

proc thread_init { } {
global public dbmon_threadID
  set env(ORACLE_HOME) $public(ORACLE_HOME)

  set public(connected) 0
  set public(thread_actv) 0 ;# mutex, lock on this var for sq
  set dbmon_threadID [ thread::create {

     global tpublic

proc just_disconnect { parent } {
   thread::send $parent "putsm \"Metrics closing down...\""
   catch {thread::release}
}
proc ora_logon { parent unpw var } {
   thread::send $parent "putsm \"Metrics connecting to $unpw\""
       set cur_proc ora_logon 
       set handle none
       set err "unknown"

 if { [ catch { package require Oratcl} err ] } {
 thread::send $parent "::callback_err \"Oratcl load failed in Metrics\""
 just_disconnect $parent
 return
 	}

       set cmd [ list  oralogon $unpw ]
       if { [ catch {
             set handle [ eval $cmd  ]
       } err ] } { 
           set err  [ join $err ]
           thread::send $parent "::callback_err \"$err\""
           thread::send $parent "::callback_mesg \"$cmd\""
 	   just_disconnect $parent
           return
       }

   thread::send -async $parent "::callback_connect $var $handle"
     }

proc ora_logoff { parent handle } {
   thread::send $parent "putsm \"Metrics logging off from Oracle...\""
       set cur_proc ora_logoff 
       set err "unknown"
       set cmd [ list  oralogoff $handle ]
       if { [ catch {
             set output [ eval $cmd  ]
       } err ] } { 
           set err  [ join $err ]
           thread::send -async $parent "::callback_err \"$err\""
           thread::send -async $parent "::callback_mesg \"$cmd\""
       }
just_disconnect $parent
     }

     proc ora_cursor { parent handle var  } {
       set cur_proc   ora_cursor   
       thread::send -async $parent  " ::callback_mesg $cur_proc  "
       set cursor [ oraopen $handle ]
       thread::send -async $parent  " ::callback_set $var $cursor"
     }
     proc ora_sql {parent  cursor sql } {
       set cur_proc ora_sql 
       thread::send  $parent  " ::callback_mesg $cur_proc  "
       orasql  $cursor $sql
       thread::send $parent  " ::callback_mesg $cursor parsed"
     }
     proc ora_fetch { parent cursor var } {
       set cur_proc ora_fetch 
       thread::send -async $parent  " ::callback_mesg $cur_proc  "
       set indx 0
       tsv::set fetched  $cursor  ""
       set result [tsv::object fetched $cursor ]

       while { [ orafetch $cursor -datavariable row] == 0 } {
          $result append  $row
          incr indx
       }
       thread::send -async $parent " ::callback_fetch $var $cursor"
     }

    proc ora_all { parent handle cursor sql fetch } {
    global tpublic
       set cur_proc   ora_all
       thread::send -async $parent  " ::callback_mesg $cur_proc  " 

       if { ! [ info exists tpublic($cursor,open) ] } {
         set tpublic($cursor) [ oraopen $handle ]
         set tpublic($cursor,open) 1
        }

       set cur_proc ora_sql 
       thread::send  -async $parent  " ::callback_mesg $cur_proc  "

       orasql  $tpublic($cursor) $sql

       thread::send  -async $parent  " ::callback_mesg \"$cursor  parsed\""

       set cur_proc ora_fetch 
       thread::send -async $parent  " ::callback_mesg $cur_proc  "
       set indx 0
       tsv::set fetched  $cursor  ""
       set result [tsv::object fetched $cursor ]

       while { [ orafetch $tpublic($cursor) -datavariable row] == 0 } {
          $result append " [ list $row ]"
          incr indx
       }
       thread::send -async $parent " ::callback_fetch  $cursor $fetch"

     }
     thread::wait
     tsv::set application themonitor "QUIT"
  }]
}

proc callback_connect { var handle } {
set cur_proc callback_connect 
global public
 if { $handle == -1 } {
    set public(connected) -1
 } else {
    set $var $handle
    set public(connected) 1
 }
} 


proc callback_set { var args } {
set cur_proc callback_set 
global public
 set $var $args
} 

proc callback_fetch { cursor fetch} {
set cur_proc callback_fetch 
 eval $fetch  [ list 1 [tsv::set fetched  $cursor] ]
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

proc disconnect { } {
global public
}

proc ora_exit { } {
global public
 set cur_proc ora_exit 
 thread_out "$cur_proc:entering"
}


proc connect { } {
global public
global oramsg
global  env
    set cur_proc connect 

   if { $public(db) != "" } {
         set remote "@$public(db)"
   } else {
         set remote ""
   }
   if { ! [ info exists dbmon_threadID ] } {
       set public(parent) [ thread::names ]
       thread_init    
   }
   set con $public(un)/$public(pw)$remote

   puts "ora_logon $public(parent) $con public(handle)"

   display_tile $public(output)
   test_connect
}

proc test_connect { } {
global public dbmon_threadID
variable firstconnect
set cur_proc test_connect 
  if { $public(connected) == "err" } {
puts "Metrics Connection Failed: Verify Metrics Options"
tsv::set application themonitor "QUIT"
.ed_mainFrame.buttons.dashboard configure -state normal
return 1
	}
  if { $public(connected) == -1 } {
       set public(connected) 0
       connect_to_oracle
       return
  }
  if { $public(connected) == 0 } {
puts  "Waiting for Connection to Oracle for Database Metrics..."
if { [ info exists dbmon_threadID ] } {
if { [ thread::exists $dbmon_threadID ] } {
       after 5000 test_connect
	}} else {
#Thread died
set public(connected) "err"
	}
  } else {
      if { $public(connected) == 1 } {
puts "Metrics Connected"
if { $firstconnect eq "true" } {
       colors
       init_publics
       set_ora_waits
       set_oracursors
set firstconnect "false"
	}
       create_metrics_screen
       mon_init
.ed_mainFrame.buttons.dashboard configure -state normal
      } else {
       set public(connected) 0
       connect_to_oracle
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

proc cpucount_fetch { args }  {
global public
   set cur_proc cpucount_fetch  
   if { [ catch {
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           set public(cpucount) [lindex $row 0]   
        }
     }
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}

proc version_fetch { args }  {
global public
   set cur_proc version_fetch  
   if { [ catch {
     foreach  row [ lindex $args 1 ]  {
        if { [ lindex $row 0 ] != "" } {
           set public(version) [lindex $row 0]   
           set public(dbname)  [lindex $row 1]   
           set public(machine) [lindex $row 2]   
        }
        regsub {\..*} $public(version) "" version
	if { $version < 10 } {
	}
     }
  } err] } { ; } 
  unlock public(thread_actv) $cur_proc
}

proc mon_init { } {
global public loop_count
  set cur_proc mon_init 
    set public(visible)  ""
      mon_execute days
      mon_execute version
      mon_execute cpucount
      set public(run) 1
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
  if  { $public(run) == 1 } {
      set public(slow_cur) [ expr $public(sleep,fast) + $public(slow_cur) ]
      set slow ""
      set fast ""
      regsub  -all {cursor,}  [ array names public cursor,* ]  ""  cursors
      foreach i $cursors { 
          if { $public(cursor,$i) == "slow" } { set slow "$slow $i" }
          if { $public(cursor,$i) == "fast" } { set fast "$fast $i" }
      }
      foreach i "secs  $fast " { mon_execute $i  }
     if { $public(slow_cur) >= $public(sleep,slow) } {
         set public(slow_cur) [ expr  $public(slow_cur) - $public(sleep,slow) ]
         foreach i  $slow {  mon_execute $i }
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
          thread::send $dbmon_threadID "ora_all $public(parent) $public(handle) $crsr \"$sql\" $fetch" 
        } err ] } { 
          unlock public(thread_actv) $cur_proc:$i 
          global errorInfo
        }
       vwait public(thread_actv)  
       set public(wait,$cur_proc,$i) 0 
    } 
  }
}

proc mon_execute_1 { i { backoff 200 } } {
global public
  set cur_proc mon_execute  
  if { $public(run) == 1 } {
    if { [ lock public(thread_actv_1) $cur_proc:$i ] } { 
        if { [ catch {
           eval set sql \"$public(sql,$i)\"
        } err ] } { 
             foreach sql [ array names public "sql,*" ] { ; } 
        }
        set crsr "crsr,$i"
        if { [ catch {
          set fetch [set i]_fetch
          thread::send $public(thread1) "ora_all $public(parent1) $public(handle) $crsr \"$sql\" $fetch" 
        } err ] } { 
          unlock public(thread_actv1) $cur_proc:$i 
          global errorInfo
          tk_messageBox  -type ok -message "$cur_proc:ERROR:$err  $errorInfo $sql"
        }
       vwait public(thread_actv1)  
       set public(wait,$cur_proc,$i) 0 
    } else {
          after $backoff mon_execute $i [expr 200 + $backoff ] ; 
          vwait public(wait,$cur_proc,$i)
    }
  }
}

proc set_ora_waits {} {
global public
set public(waits,"CPU") CPU
set public(waits,"BCPU") BCPU
set public(waits,"ARCH_random_i/o") System_IO
set public(waits,"ARCH_sequential_i/o") System_IO
set public(waits,"ARCH_wait_for_flow-control") Network
set public(waits,"ARCH_wait_for_net_re-connect") Network
set public(waits,"ARCH_wait_for_netserver_detach") Network
set public(waits,"ARCH_wait_for_netserver_init_1") Network
set public(waits,"ARCH_wait_for_netserver_init_2") Network
set public(waits,"ARCH_wait_for_netserver_start") Network
set public(waits,"ARCH_wait_for_pending_I/Os") System_IO
set public(waits,"ARCH_wait_on_ATTACH") Network
set public(waits,"ARCH_wait_on_DETACH") Network
set public(waits,"ARCH_wait_on_SENDREQ") Network
set public(waits,"ASM_COD_rollback_operation_completion") Administrative
set public(waits,"ASM_PST_query_:_wait_for_\[PM\]\[grp\]\[0\]_grant") Cluster
set public(waits,"ASM_mount_:_wait_for_heartbeat") Administrative
set public(waits,"BFILE_read") User_IO
set public(waits,"Backup:_sbtbackup") Administrative
set public(waits,"Backup:_sbtclose") Administrative
set public(waits,"Backup:_sbtclose2") Administrative
set public(waits,"Backup:_sbtcommand") Administrative
set public(waits,"Backup:_sbtend") Administrative
set public(waits,"Backup:_sbterror") Administrative
set public(waits,"Backup:_sbtinfo") Administrative
set public(waits,"Backup:_sbtinfo2") Administrative
set public(waits,"Backup:_sbtinit") Administrative
set public(waits,"Backup:_sbtinit2") Administrative
set public(waits,"Backup:_sbtopen") Administrative
set public(waits,"Backup:_sbtpcbackup") Administrative
set public(waits,"Backup:_sbtpccancel") Administrative
set public(waits,"Backup:_sbtpccommit") Administrative
set public(waits,"Backup:_sbtpcend") Administrative
set public(waits,"Backup:_sbtpcquerybackup") Administrative
set public(waits,"Backup:_sbtpcqueryrestore") Administrative
set public(waits,"Backup:_sbtpcrestore") Administrative
set public(waits,"Backup:_sbtpcstart") Administrative
set public(waits,"Backup:_sbtpcstatus") Administrative
set public(waits,"Backup:_sbtpcvalidate") Administrative
set public(waits,"Backup:_sbtread") Administrative
set public(waits,"Backup:_sbtread2") Administrative
set public(waits,"Backup:_sbtremove") Administrative
set public(waits,"Backup:_sbtremove2") Administrative
set public(waits,"Backup:_sbtrestore") Administrative
set public(waits,"Backup:_sbtwrite") Administrative
set public(waits,"Backup:_sbtwrite2") Administrative
set public(waits,"DG_Broker_configuration_file_I/O") User_IO
set public(waits,"Data_file_init_write") User_IO
set public(waits,"Datapump_dump_file_I/O") User_IO
set public(waits,"JS_coord_start_wait") Administrative
set public(waits,"JS_kgl_get_object_wait") Administrative
set public(waits,"JS_kill_job_wait") Administrative
set public(waits,"LGWR_random_i/o") System_IO
set public(waits,"LGWR_sequential_i/o") System_IO
set public(waits,"LGWR_wait_on_ATTACH") Network
set public(waits,"LGWR_wait_on_DETACH") Network
set public(waits,"LGWR_wait_on_LNS") Network
set public(waits,"LGWR_wait_on_SENDREQ") Network
set public(waits,"LNS_ASYNC_control_file_txn") System_IO
set public(waits,"LNS_wait_on_ATTACH") Network
set public(waits,"LNS_wait_on_DETACH") Network
set public(waits,"LNS_wait_on_LGWR") Network
set public(waits,"LNS_wait_on_SENDREQ") Network
set public(waits,"Log_archive_I/O") System_IO
set public(waits,"Log_file_init_write") User_IO
set public(waits,"RFS_random_i/o") System_IO
set public(waits,"RFS_sequential_i/o") System_IO
set public(waits,"RFS_write") System_IO
set public(waits,"RMAN_backup_&_recovery_I/O") System_IO
set public(waits,"SQL*Net_break/reset_to_client") Application
set public(waits,"SQL*Net_break/reset_to_dblink") Application
set public(waits,"SQL*Net_message_to_client") Network
set public(waits,"SQL*Net_message_to_dblink") Network
set public(waits,"SQL*Net_more_data_from_client") Network
set public(waits,"SQL*Net_more_data_from_dblink") Network
set public(waits,"SQL*Net_more_data_to_client") Network
set public(waits,"SQL*Net_more_data_to_dblink") Network
set public(waits,"Standby_redo_I/O") System_IO
set public(waits,"Streams_AQ:_enqueue_blocked_on_low_memory") Configuration
set public(waits,"Streams_capture:_filter_callback_waiting_for_ruleset") Application
set public(waits,"Streams_capture:_resolve_low_memory_condition") Configuration
set public(waits,"Streams_capture:_waiting_for_subscribers_to_catch_up") Configuration
set public(waits,"Streams:_RAC_waiting_for_inter_instance_ack") Cluster
set public(waits,"Streams:_apply_reader_waiting_for_DDL_to_apply") Application
set public(waits,"TCP_Socket_(KGAS)") Network
set public(waits,"TEXT:_URL_DATASTORE_network_wait") Network
set public(waits,"Wait_for_Table_Lock") Application
set public(waits,"alter_rbs_offline") Administrative
set public(waits,"alter_system_set_dispatcher") Administrative
set public(waits,"buffer_busy_waits") Concurrency
set public(waits,"buffer_pool_resize") Administrative
set public(waits,"buffer_read_retry") User_IO
set public(waits,"checkpoint_completed") Configuration
set public(waits,"control_file_parallel_write") System_IO
set public(waits,"control_file_sequential_read") System_IO
set public(waits,"control_file_single_write") System_IO
set public(waits,"cursor:_mutex_S") Concurrency
set public(waits,"cursor:_mutex_X") Concurrency
set public(waits,"cursor:_pin_S_wait_on_X") Concurrency
set public(waits,"db_file_parallel_read") User_IO
set public(waits,"db_file_parallel_write") System_IO
set public(waits,"db_file_scattered_read") User_IO
set public(waits,"db_file_sequential_read") User_IO
set public(waits,"db_file_single_write") User_IO
set public(waits,"dbms_file_transfer_I/O") User_IO
set public(waits,"dedicated_server_timer") Network
set public(waits,"direct_path_read") User_IO
set public(waits,"direct_path_read_temp") User_IO
set public(waits,"direct_path_write") User_IO
set public(waits,"direct_path_write_temp") User_IO
set public(waits,"dispatcher_listen_timer") Network
set public(waits,"enq:_DB_-_contention") Administrative
set public(waits,"enq:_HW_-_contention") Configuration
set public(waits,"enq:_KO_-_fast_object_checkpoint") Application
set public(waits,"enq:_PW_-_flush_prewarm_buffers") Application
set public(waits,"enq:_RO_-_contention") Application
set public(waits,"enq:_RO_-_fast_object_reuse") Application
set public(waits,"enq:_SQ_-_contention") Configuration
set public(waits,"enq:_SS_-_contention") Configuration
set public(waits,"enq:_ST_-_contention") Configuration
set public(waits,"enq:_TM_-_contention") Application
set public(waits,"enq:_TW_-_contention") Administrative
set public(waits,"enq:_TX_-_allocate_ITL_entry") Configuration
set public(waits,"enq:_TX_-_index_contention") Concurrency
set public(waits,"enq:_TX_-_row_lock_contention") Application
set public(waits,"enq:_UL_-_contention") Application
set public(waits,"enq:_ZG_-_contention") Administrative
set public(waits,"free_buffer_waits") Configuration
set public(waits,"gc_assume") Cluster
set public(waits,"gc_block_recovery_request") Cluster
set public(waits,"gc_buffer_busy") Cluster
set public(waits,"gc_claim") Cluster
set public(waits,"gc_cr_block_2-way") Cluster
set public(waits,"gc_cr_block_3-way") Cluster
set public(waits,"gc_cr_block_busy") Cluster
set public(waits,"gc_cr_block_congested") Cluster
set public(waits,"gc_cr_block_lost") Cluster
set public(waits,"gc_cr_block_unknown") Cluster
set public(waits,"gc_cr_cancel") Cluster
set public(waits,"gc_cr_disk_read") Cluster
set public(waits,"gc_cr_disk_request") Cluster
set public(waits,"gc_cr_failure") Cluster
set public(waits,"gc_cr_grant_2-way") Cluster
set public(waits,"gc_cr_grant_busy") Cluster
set public(waits,"gc_cr_grant_congested") Cluster
set public(waits,"gc_cr_grant_unknown") Cluster
set public(waits,"gc_cr_multi_block_request") Cluster
set public(waits,"gc_cr_request") Cluster
set public(waits,"gc_current_block_2-way") Cluster
set public(waits,"gc_current_block_3-way") Cluster
set public(waits,"gc_current_block_busy") Cluster
set public(waits,"gc_current_block_congested") Cluster
set public(waits,"gc_current_block_lost") Cluster
set public(waits,"gc_current_block_unknown") Cluster
set public(waits,"gc_current_cancel") Cluster
set public(waits,"gc_current_grant_2-way") Cluster
set public(waits,"gc_current_grant_busy") Cluster
set public(waits,"gc_current_grant_congested") Cluster
set public(waits,"gc_current_grant_unknown") Cluster
set public(waits,"gc_current_multi_block_request") Cluster
set public(waits,"gc_current_request") Cluster
set public(waits,"gc_current_retry") Cluster
set public(waits,"gc_current_split") Cluster
set public(waits,"gc_domain_validation") Cluster
set public(waits,"gc_freelist") Cluster
set public(waits,"gc_prepare") Cluster
set public(waits,"gc_quiesce_wait") Cluster
set public(waits,"gc_recovery_free") Cluster
set public(waits,"gc_recovery_quiesce") Cluster
set public(waits,"gc_remaster") Cluster
set public(waits,"index_(re)build_online_cleanup") Administrative
set public(waits,"index_(re)build_online_merge") Administrative
set public(waits,"index_(re)build_online_start") Administrative
set public(waits,"io_done") System_IO
set public(waits,"kfk:_async_disk_IO") System_IO
set public(waits,"ksfd:_async_disk_IO") System_IO
set public(waits,"kst:_async_disk_IO") System_IO
set public(waits,"latch:_In_memory_undo_latch") Concurrency
set public(waits,"latch:_MQL_Tracking_Latch") Concurrency
set public(waits,"latch:_Undo_Hint_Latch") Concurrency
set public(waits,"latch:_cache_buffers_chains") Concurrency
set public(waits,"latch:_library_cache") Concurrency
set public(waits,"latch:_library_cache_lock") Concurrency
set public(waits,"latch:_library_cache_pin") Concurrency
set public(waits,"latch:_redo_copy") Configuration
set public(waits,"latch:_redo_writing") Configuration
set public(waits,"latch:_row_cache_objects") Concurrency
set public(waits,"latch:_shared_pool") Concurrency
set public(waits,"library_cache_load_lock") Concurrency
set public(waits,"library_cache_lock") Concurrency
set public(waits,"library_cache_pin") Concurrency
set public(waits,"local_write_wait") User_IO
set public(waits,"lock_remastering") Cluster
set public(waits,"log_buffer_space") Configuration
set public(waits,"log_file_parallel_write") System_IO
set public(waits,"log_file_sequential_read") System_IO
set public(waits,"log_file_single_write") System_IO
set public(waits,"log_file_switch_(archiving_needed)") Configuration
set public(waits,"log_file_switch_(checkpoint_incomplete)") Configuration
set public(waits,"log_file_switch_(private_strand_flush_incomplete)") Configuration
set public(waits,"log_file_switch_completion") Configuration
set public(waits,"log_file_sync") Commit
set public(waits,"logout_restrictor") Concurrency
set public(waits,"multiple_dbwriter_suspend/resume_for_file_offline") Administrative
set public(waits,"os_thread_startup") Concurrency
set public(waits,"pi_renounce_write_complete") Cluster
set public(waits,"pipe_put") Concurrency
set public(waits,"read_by_other_session") User_IO
set public(waits,"recovery_read") System_IO
set public(waits,"resmgr:become_active") Scheduler
set public(waits,"resmgr:cpu_quantum") Scheduler
set public(waits,"resmgr:internal_state_change") Concurrency
set public(waits,"resmgr:internal_state_cleanup") Concurrency
set public(waits,"resmgr:sessions_to_exit") Concurrency
set public(waits,"retry_contact_SCN_lock_master") Cluster
set public(waits,"row_cache_lock") Concurrency
set public(waits,"row_cache_read") Concurrency
set public(waits,"sort_segment_request") Configuration
set public(waits,"statement_suspended,_wait_error_to_be_cleared") Configuration
set public(waits,"switch_logfile_command") Administrative
set public(waits,"switch_undo_-_offline") Administrative
set public(waits,"undo_segment_extension") Configuration
set public(waits,"undo_segment_tx_slot") Configuration
set public(waits,"wait_for_EMON_to_process_ntfns") Configuration
set public(waits,"wait_for_possible_quiesce_finish") Administrative
set public(waits,"write_complete_waits") Configuration
	}

proc set_oracursors {} {
global public
  set public(sql,cpucount) " --metrics
      select value from v\\\\\\\$parameter 
      where name='cpu_count'"

  set public(sql,version) " --metrics
      select  version,
              instance_name,
	      host_name from  v\\\\\\\$instance" 

  set public(sql,ashrpt) " --metrics
          select output 
	  from table(dbms_workload_repository.ash_report_text( 
	                     (select dbid from v\\\\\\\$database),
                             1,
                             to_date('\$public(ash,beg)','JSSSSS'),
                             to_date('\$public(ash,end)','JSSSSS'),
                             0)) "

# execute once in mon_init
# date.tcl
# day_fetch {}  
# public(today) 
  set public(sql,days) " --metrics
     select to_char(sysdate,'J') from dual " 

# execte every public(sleep,fast) in mon_loop
# date.tcl 
# secs_fetch
# public(secs)
  set public(sql,secs) " --metrics
     select  to_char(sysdate,'SSSSS') +
     (to_char(sysdate,'J')-\$public(today))*86400 
     from dual"

# what is indexing like on ash in order to get the max quickly
# ash itself selects news point first but for the repository it doesn't 
# running a quick test on ASH, the max is faster !

   set public(sql,ashtime) " --metrics
      select
	    to_char((sample_time-(\$public(ash,loadhours)/24)),'J') ,
	    to_char((sample_time-(\$public(ash,loadhours)/24)),'SSSSS') 
	    --to_char((sample_time-16/24),'SSSSS') ,
            --to_char(sample_time,'J')
       from ( select max(sample_time) sample_time
              from v\\\\\\\$active_session_history ) "

   set public(sql,ash) " --metrics
     select
          event#
          ,max(to_char(sample_time,'SSSSS'))
          ,sum(decode(type,'ash',1,'hist',10)) cnt
          ,max(sample_id) sample_id
          , max(to_char(sample_time,'J')) last_day
          , trunc(to_char(sample_time,'SSSSS')/bucket)*bucket     beg_secs
          ,(trunc(to_char(sample_time,'SSSSS')/bucket)+1)*bucket  end_secs
          , min(to_char(sample_time,'J')) first_day,
	  session_type
       from
          (
            select
                \$public(ash,bucket_secs) bucket,
                sample_time,
                sample_id,
                translate(
                     decode(session_state,'ON CPU',
                                           decode(session_type,'BACKGROUND','BCPU','CPU')
                     ,event)
                    ,' []$/','____') /* replace first characters with undescore, get rid of / */
                event#,
		'ash' type,
		session_type
            from v\\\\\\\$active_session_history
            --from ash_dump
            where
 	        \$public(ash,where)
     union all
            select
                \$public(ash,bucket_secs) bucket,
                sample_time,
                sample_id,
                translate(
                     decode(session_state,'ON CPU',
                      decode(session_type,'BACKGROUND','BCPU','CPU')
                     ,event)
                    ,' []$/','____')
                event#,
		'hist' type,
		session_type
            from  dba_hist_active_sess_history
            where
 	        \$public(ash,where) and
		sample_time < (select min(sample_time) from v\\\\\\\$active_session_history)
            )
       group by
          (trunc(to_char(sample_time,'SSSSS')/bucket)+1)*bucket ,
           trunc(to_char(sample_time,'SSSSS')/bucket)*bucket  ,
          event#, session_type
       order by last_day,end_secs"

	
   set public(sql,ash_sqltxt)   "--metrics
      select
	     sql_text 
      from
	  v\\\\\\\$SQLTEXT_WITH_NEWLINES
       where \$public(ash,sqlid)
       order by piece
	 "
   set public(sql,ash_sqlplanx)   "--metrics
      SELECT   LPAD (' ', DEPTH) || operation operation,
         object_owner, object_name, cardinality ,
         bytes ,
         cost
      FROM     
	  v\\\\\\\$sql_plan_statistics_all
       where \$public(ash,sqlid)
      ORDER BY id"


   set public(sql,ash_sqlplan)   "--metrics
       select * 
       from TABLE(DBMS_XPLAN.DISPLAY_CURSOR('\$public(ash,realsqlid)'))
      "

   set public(sql,ash_sqlstats)   "--metrics
      SELECT   
         executions,
         cpu_time,
         elapsed_time,
         buffer_gets,
         disk_reads,
         Direct_writes,
         rows_processed,
	 fetches
	 ,
         nvl(executions/nullif(executions,0),0),
         nvl(cpu_time/nullif(executions,0),0),
         nvl(elapsed_time/nullif(executions,0),0),
         nvl(buffer_gets/nullif(executions,0),0),
         nvl(disk_reads/nullif(executions,0),0),
         nvl(Direct_writes/nullif(executions,0),0),
         nvl(rows_processed/nullif(executions,0),0),
	 nvl(fetches/nullif(executions,0),0)
	 ,
         nvl(executions/nullif(rows_processed,0),0),
         nvl(cpu_time/nullif(rows_processed,0),0),
         nvl(elapsed_time/nullif(rows_processed,0),0),
         nvl(buffer_gets/nullif(rows_processed,0),0),
         nvl(disk_reads/nullif(rows_processed,0),0),
         nvl(Direct_writes/nullif(rows_processed,0),0),
         nvl(rows_processed/nullif(rows_processed,0),0),
	 nvl(fetches/nullif(rows_processed,0),0)
	 ,
         '',
         '',
         '',
         '',
         '',
         '',
         '',
	 ''
      FROM     
	  v\\\\\\\$sqlstats
       where \$public(ash,sqlid) "

   set public(sql,ash_sqlstatsx)   "--metrics
      SELECT   
         executions,
         cpu_time,
         elapsed_time,
         buffer_gets,
         disk_reads,
         Direct_writes,
         rows_processed,
	 fetches
	 ,
         nvl(executions/nullif(executions,0),0),
         nvl(cpu_time/nullif(executions,0),0),
         nvl(elapsed_time/nullif(executions,0),0),
         nvl(buffer_gets/nullif(executions,0),0),
         nvl(disk_reads/nullif(executions,0),0),
         nvl(Direct_writes/nullif(executions,0),0),
         nvl(rows_processed/nullif(executions,0),0),
	 nvl(fetches/nullif(executions,0),0)
	 ,
         nvl(executions/nullif(rows_processed,0),0),
         nvl(cpu_time/nullif(rows_processed,0),0),
         nvl(elapsed_time/nullif(rows_processed,0),0),
         nvl(buffer_gets/nullif(rows_processed,0),0),
         nvl(disk_reads/nullif(rows_processed,0),0),
         nvl(Direct_writes/nullif(rows_processed,0),0),
         nvl(rows_processed/nullif(rows_processed,0),0),
	 nvl(fetches/nullif(rows_processed,0),0)
	 ,
         delta_execution_count,
         delta_cpu_time,
         delta_elapsed_time,
         delta_buffer_gets,
         delta_disk_reads,
         delta_Direct_writes,
         delta_rows_processed,
	 delta_fetch_count
      FROM     
	  sys.x\\\\\\\$kkssqlstat
       where \$public(ash,sqlid) "

   set public(sql,ash_sqlevents)   "--metrics
       select
             event,
             count(*) total,
             wait_class
       from (
                select
                          decode(session_state,'ON CPU',
                             decode(session_type,'BACKGROUND','BCPU','CPU')
                          ,event)
                    event,
                      replace(translate(
                            decode(session_state,
                                  'ON CPU',decode(session_type,'BACKGROUND','BCPU','CPU'),
                                              wait_class)
                             ,' []$','____'),'/')
                    wait_class
         from v\\\\\\\$active_session_history
         --from ash_dump
         where 
               sample_time >= to_date('\$public(ash,beg)','JSSSSS') and
               sample_time <= to_date('\$public(ash,end)','JSSSSS') 
                  -- and \$public(ash,sqlid)
       union all
                select
                          decode(session_state,'ON CPU',
                             decode(session_type,'BACKGROUND','BCPU','CPU')
                          ,event)
                    event,
                      replace(translate(
                            decode(session_state,
                                  'ON CPU',decode(session_type,'BACKGROUND','BCPU','CPU'),
                                              wait_class)
                             ,' []$','____'),'/')
                    wait_class
	 from  dba_hist_active_sess_history
         where 
               sample_time >= to_date('\$public(ash,beg)','JSSSSS') and
               sample_time <= to_date('\$public(ash,end)','JSSSSS') 
                  -- and \$public(ash,sqlid)
               )
       group by event, wait_class
       order by total desc"

   set public(sql,ash_sqlsessions)   "--metrics
     select * from (
         select 
          ash.session_id||','||ash.SESSION_SERIAL#         event,
          count(*)    total,
	  sum(decode(ash.wait_class,'Other',1,0))            other,
	  sum(decode(ash.wait_class,'Network',1,0))          net,
	  sum(decode(ash.wait_class,'Application',1,0))      app,
	  sum(decode(ash.wait_class,'Administration',1,0))   admin,
	  sum(decode(ash.wait_class,'Cluster',1,0))      clust,
	  sum(decode(ash.wait_class,'Concurrency',1,0))      concur,
	  sum(decode(ash.wait_class,'Configuration',1,0))    config,
	  sum(decode(ash.wait_class,'Commit',1,0))           commit,
	  sum(decode(ash.wait_class,'System I/O',1,0))       s_io,
	  sum(decode(ash.wait_class,'User I/O',1,0))         uio,
	  sum(decode(ash.wait_class,'ON CPU',1,0))        cpu,
	  sum(decode(ash.wait_class,'BCPU',1,0))        bcpu,
	  nvl(u.username,ash.session_id||'#'||ash.SESSION_SERIAL#),
	  ash.program
         from 
              ( select
                  sql_id,
                  user_id,
                  session_id,
                  sample_id,
                  session_serial#,
                  program,
                  decode(session_state,'ON CPU',
                      decode(session_type,'BACKGROUND','BCPU','ON CPU')
		  , wait_class)  wait_class
	         from  v\\\\\\\$active_session_history 
	         --from  ash_dump
		 where
                   sample_time >= to_date('\$public(ash,beg)','JSSSSS') and
                   sample_time <= to_date('\$public(ash,end)','JSSSSS') 
	   union all
               select
                  sql_id,
                  user_id,
                  session_id,
                  sample_id,
                  session_serial#,
                  program,
                  decode(session_state,'ON CPU',
                      decode(session_type,'BACKGROUND','BCPU','ON CPU')
		  , wait_class)  wait_class
	         from  dba_hist_active_sess_history
		 where
                   sample_time >= to_date('\$public(ash,beg)','JSSSSS') and
                   sample_time <= to_date('\$public(ash,end)','JSSSSS') 
		 )  ash,
	      dba_users u
         where 
	       u.user_id(+)=ash.user_id  
                 -- and \$public(ash,sqlid)
	       /* public(ash,sql) contains sql_id = 
                 and public(ash,sqlid)
		*/
	  group by ash.session_id, ash.session_serial#,ash.program, u.username
	) 
	order by total desc
          "

   set public(sql,ash_sqldetails)   "--metrics
     select * from (
       select 
          sql_id,
          count(*)                                       total,
	  sum(decode(wait_class,'Other',1,0))            other,
	  sum(decode(wait_class,'Network',1,0))          net,
	  sum(decode(wait_class,'Application',1,0))      app,
	  sum(decode(wait_class,'Administration',1,0))   admin,
	  sum(decode(wait_class,'Cluster',1,0))      clust,
	  sum(decode(wait_class,'Concurrency',1,0))      concur,
	  sum(decode(wait_class,'Configuration',1,0))    config,
	  sum(decode(wait_class,'Commit',1,0))           commit,
	  sum(decode(wait_class,'System I/O',1,0))       s_io,
	  sum(decode(wait_class,'User I/O',1,0))         uio,
	  sum(decode(wait_class,'ON CPU',1,0))        cpu,
	  sum(decode(wait_class,'BCPU',1,0))        bcpu,
	  decode(max(sql_opcode),1,'DDL',
	                    2,'INSERT',
			    3,'Query',
			    6,'UPDATE',
			    7,'DELETE',
			   47,'PL/SQL_package_call',
			   50,'Explain Plan',
			  170,'CALL',
			  189,'MERGE',to_char(max(sql_opcode)))  opcode,
	   sql_plan_hash_value
          from 
             (select 
	            sql_id,
		    sample_id,
		    /* opcode for sql_id null and 0 can be different */
                    decode(nvl(sql_id,'0'),'0',0,sql_opcode) sql_opcode,
		    decode(session_state,'ON CPU',
                      decode(session_type,'BACKGROUND','BCPU','ON CPU')
		    , wait_class)  wait_class ,
	            sql_plan_hash_value 
		    from v\\\\\\\$active_session_history 
		    --from ash_dump
		 where 
                    sample_time >= to_date('\$public(ash,beg)','JSSSSS') and
                    sample_time <= to_date('\$public(ash,end)','JSSSSS')
	union all
             select 
	            sql_id,
		    sample_id,
		    /* opcode for sql_id null and 0 can be different */
                    decode(nvl(sql_id,'0'),'0',0,sql_opcode) sql_opcode,
		    decode(session_state,'ON CPU',
                      decode(session_type,'BACKGROUND','BCPU','ON CPU')
		    , wait_class)  wait_class ,
	            sql_plan_hash_value 
		    from  dba_hist_active_sess_history
		 where 
                    sample_time >= to_date('\$public(ash,beg)','JSSSSS') and
                    sample_time <= to_date('\$public(ash,end)','JSSSSS')
               ) ash
	        -- select aud.name
	        -- sys.audit_actions aud
		--where aud.action = ash.sql_ocode 
	   group by sql_id,sql_plan_hash_value
	   order by total desc
      ) where rownum < 20 
      "

   set public(sql,sqlovertimeload) " --metrics
   select  event#,
           last_secs ,
	   cnt,
	   last_id,
	   last_day from (
     select
        distinct event# ,
          to_char(LAST_VALUE(sample_time)
          OVER ( partition by modsecs ORDER BY sample_id
          ROWS BETWEEN UNBOUNDED PRECEDING 
          AND UNBOUNDED FOLLOWING),'SSSSS')  
        last_secs,
           count(event#)
           OVER (partition by event#, modsecs ORDER BY event#
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) 
         cnt,
           LAST_VALUE(sample_id)
           OVER ( partition by modsecs ORDER BY sample_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) 
         last_id,
           to_char(LAST_VALUE(sample_time)
           OVER ( partition by modsecs ORDER BY sample_id
           ROWS BETWEEN UNBOUNDED PRECEDING 
           AND UNBOUNDED FOLLOWING),'J') 
         last_day,
         modsecs
       from
          ( select
                sample_time,
                sample_id,
                   trunc(to_char(sample_time,'SSSSS')/\$public(ashsql,bucket_secs)) 
		modsecs,
                   replace(replace(
                     decode(session_state,'ON CPU',
                      decode(session_type,'BACKGROUND','BCPU','CPU')
		     ,wait_class) 
                    ,' ','_'),'/') 
		event#
            from v\\\\\\\$active_session_history
            where
	         sample_time > to_date('\$public(ash,starttime)','JSSSSS') 
                and   \$public(ashsql,sqlovertimeid)
            ) ash
           order by   last_day,modsecs )
         " 

set public(sql,stat)     "--metrics
       select
              STATISTIC#      , value 
       from 
               $public(vdollar)\\\\\\\$sysstat
       where 
               value > 0"

set public(sql,statname) "select 
                                   statistic#,
                                    replace(lower(name),' ','_') 
                           from $public(vdollar)\\\\\\\$statname"

set public(sql,sevt_names) "select event#,
                                      replace(lower(name),' ','_') 
                                from $public(vdollar)\\\\\\\$event_name"

set public(sql,sevt)  "--metrics
      select 
            w.event#,
            total_waits,
            time_waited 
      from $public(vdollar)\\\\\\\$system_event s,
           $public(vdollar)\\\\\\\$event_name w
      where total_waits > 0 and w.name=s.event
           and s.wait_class!='Idle'"  

 set public(sql,waiters) "--metrics
     select  s.sid,        /* sid */
	--decode(s.wait_time,0,w.event#,'CPU'),    /* wait event # */
	w.event#,    /* wait event # */
 	sw.p1,   /* p1r */
  	sw.p2,   /* p2r */
 	sw.p3,   /* p3r */
	sw.wait_time,   /* time waited */
 	sw.seq#,    /* seq */
        s.sql_address,
        s.sql_hash_value
      from
	$public(vdollar)\\\\\\\$session_wait sw /* session waits */,
	$public(vdollar)\\\\\\\$session   s  /* v_session */                
	$public(vdollar)\\\\\\\$event_name   w  /* v_session */                
     where
        s.sid =  sw.sid and 
        sw.event =  w.name and 
	sw.status ='ACTIVE'   and
        sw.event != 'SQL*Net_message_from_client'"


set public(sql,txrlc) " --metrics
 select ash.* ,
       nvl(o.object_name,ash.current_obj#) objn,
       substr(o.object_type,0,10) otype
  from 
  (select
        -- /*+ gather_plan_statistics */
       to_char(sample_time,'HH:MI') sample_time,
       substr(event,0,20) event,
       ash.session_id sid,
       mod(ash.p1,16)  lm,
       ash.p2,
       ash.p3, 
       CURRENT_FILE# fn,
       CURRENT_BLOCK# blockn, 
       CURRENT_obj# , 
       ash.SQL_ID,
       BLOCKING_SESSION bsid
       --,ash.xid
from v\\\\\\\$active_session_history ash
where event like 'enq: TX %'
   and sample_time >= to_date('\$public(ash,beg)','JSSSSS') 
   and sample_time <= to_date('\$public(ash,end)','JSSSSS')
   and rownum < 20 
Order by sample_time 
) ash,
  all_objects o
where
  o.object_id (+)= ash.CURRENT_OBJ#"

set public(sql,bbw) " --metrics
select 
       ash.sql_id,
       ash.p1,
       ash.p2,
       ash.current_file#,
       ash.current_block#,
       nvl(o.object_name,ash.CURRENT_OBJ#),
       o.object_type otype,
       nvl(w.class,to_char(ash.p3)) block_type
from
(select
       p1,
       p2,
       p3,
       CURRENT_OBJ#,
       CURRENT_FILE# ,
       CURRENT_BLOCK# ,
       SQL_ID
from v\\\\\\\$active_session_history 
where event='buffer busy waits'
   and session_state='WAITING'
   and sample_time >= to_date('\$public(ash,beg)','JSSSSS') 
   and sample_time <= to_date('\$public(ash,end)','JSSSSS')
   and rownum < 20 
Order by sample_time ) ash,
    ( select rownum class#, class from v\\\\\\\$waitstat ) w,
      all_objects o
where
    o.object_id (+)= ash.CURRENT_OBJ#
   and w.class#(+)=ash.p3"


set public(sql,hw) " --metrics
 select ash.* ,
       nvl(o.object_name,ash.current_obj#) objn,
       substr(o.object_type,0,10) otype
  from 
  (select
        -- /*+ gather_plan_statistics */
       to_char(sample_time,'HH:MI') sample_time,
       substr(event,0,20) event,
       ash.session_id sid,
       mod(ash.p1,16)  lm,
       ash.p2,
       ash.p3, 
       CURRENT_FILE# fn,
       CURRENT_BLOCK# blockn, 
       CURRENT_obj# , 
       ash.SQL_ID,
       BLOCKING_SESSION bsid
       --,ash.xid
from v\\\\\\\$active_session_history ash
where event like 'enq: HW - contention'
   and sample_time >= to_date('\$public(ash,beg)','JSSSSS') 
   and sample_time <= to_date('\$public(ash,end)','JSSSSS')
   and rownum < 20 
Order by sample_time 
) ash,
  all_objects o
where
  o.object_id (+)= ash.CURRENT_OBJ#"

set public(sql,cbc) " --metrics
select 
       ash.cnt,
       ash.sql_id,
       nvl(o.object_name,'obj?:'||ash.current_obj#) obj,
       substr(nvl(object_type,'type?'),0,10) otype,
       ash.CURRENT_FILE# fn,
       ash.CURRENT_BLOCK# blockn
from
(select
       count(*) cnt,
       sql_id,
       current_obj#,
       CURRENT_FILE# ,
       CURRENT_BLOCK# 
from v\\\\\\\$active_session_history 
where event='latch: cache buffers chains'
   and session_state='WAITING'
   and sample_time >= to_date('\$public(ash,beg)','JSSSSS') 
   and sample_time <= to_date('\$public(ash,end)','JSSSSS')
   group by sql_id, current_obj#,CURRENT_FILE#,
   CURRENT_BLOCK#
order by count(*)
) ash,
      all_objects o
where
    o.object_id (+)= ash.CURRENT_OBJ#"

set public(sql,sqlio) " --metrics
    select
       --sum(cnt) over ( partition by ash.sql_id order by sql_id ) tcnt,
       ash.cnt cnt,
       ash.event ,
       --ash.sql_id,
       ash.aas aas,
       nvl(o.object_name,decode(ash.CURRENT_OBJ#,-1,0,ash.CURRENT_OBJ#)) obj,
       ash.CURRENT_OBJ# obj#,
       o.object_type otype,
       ash.p1 p1,
       f.tablespace_name tablespace_name
from 
(
  select
        sql_id,
        count(*) cnt,
        round(count(*)/(
      (to_date('\$public(ash,end)','JSSSSS') -
       to_date('\$public(ash,beg)','JSSSSS') ) * 24*60*60
	),2) aas,
        CURRENT_OBJ# ,
	event,
        p1
   from v\\\\\\\$active_session_history 
   where ( event like 'db file s%' or event like 'direct%' )
      and sample_time >= to_date('\$public(ash,beg)','JSSSSS') 
      and sample_time <= to_date('\$public(ash,end)','JSSSSS')
      and session_state= 'WAITING'
       and  \$public(ash,sqlid)
   group by 
        CURRENT_OBJ#, 
        p1,
        sql_id,
	event
)       ash,
        all_objects o,
        dba_data_files f
where
       f.file_id(+) = ash.p1
   and o.object_id (+)= ash.CURRENT_OBJ#
Order by 
         --tcnt, 
	 --ash.sql_id, 
	 ash.cnt"

set public(sql,io) " --metrics
select
       sum(cnt) over ( partition by ash.sql_id order by sql_id ) tcnt,
       ash.sql_id,
       ash.cnt cnt,
       ash.aas aas,
       --ash.event event,
       nvl(o.object_name,decode(ash.CURRENT_OBJ#,-1,0,ash.CURRENT_OBJ#)) obj,
       o.object_type otype,
       ash.p1 p1,
       f.tablespace_name tablespace_name
from 
(
  select
        sql_id,
        count(*) cnt,
        round(count(*)/(
      (to_date('\$public(ash,end)','JSSSSS') -
       to_date('\$public(ash,beg)','JSSSSS') ) * 24*60*60
	),2) aas,
        CURRENT_OBJ# ,
        p1
   from v\\\\\\\$active_session_history ash
   where ( event like 'db file s%' or event like 'direct%' )
      and sample_time >= to_date('\$public(ash,beg)','JSSSSS') 
      and sample_time <= to_date('\$public(ash,end)','JSSSSS')
      and session_state= 'WAITING'
      --and sql_id !=  ''
      --and sql_id is not null
   group by 
       CURRENT_OBJ#, 
       p1,
       sql_id
)  ash,
    dba_data_files f
   ,all_objects o
where
       f.file_id = ash.p1
  and o.object_id (+)= ash.CURRENT_OBJ#
   --and ash.sql_id is not null
Order by tcnt, ash.sql_id, ash.cnt
"
}

proc init_publics {} {
global env public defaultBackground
  set PWD [ pwd ]
  regsub  -all {/bin}  $PWD   ""  env(MON_HOME)    
if { [info exists env(ORACLE_HOME)] } {
  set public(ORACLE_HOME) $env(ORACLE_HOME)
        } else {
  set public(ORACLE_HOME) $env(HOME)
        }
  set public(debug_level)          0
  set public(debug_to_file)        0
  set public(debug_thread_to_file) 0
  set public(sleep,fast)  15
  set public(sleep,med)  15
  set public(sleep,slow) 60
  set public(slow_cur)   0
  set public(OS)        NT
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

proc post_kill_dbmon_cleanup {} {
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
#logoff also calls just_disconnect
thread::send  -async $dbmon_threadID "ora_logoff $public(parent) $public(handle)"
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
      puts "Warning: Metrics connection remains active"
      after 2000 post_kill_dbmon_cleanup
    }
}}

proc orametrics { } {
global env public orametrics_firstrun dbmon_threadID
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
post_kill_dbmon_cleanup
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
if { [info exists env(ORACLE_HOME)] } {
  set public(ORACLE_HOME) $env(ORACLE_HOME)
        } else {
  set public(ORACLE_HOME) $env(HOME)
        }
connect_to_oracle
}
}
