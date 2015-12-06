proc ttk::toplevel {w args} {
    eval [linsert $args 0 ::toplevel $w]
    place [ttk::frame $w.tilebg] -x 0 -y 0 -relwidth 1 -relheight 1
    set w
 }

set tkcmdlist { tkCancelRepeat tkListboxBeginSelect tkCancelRepeat tkwait tkEntryInsert tkListboxMotion tkListboxUpDown tkEntryBackspace }
foreach tkcmd $tkcmdlist {
        if {![llength [ info commands $tkcmd]]} {
        tk::unsupported::ExposePrivateCommand $tkcmd
        }
}

proc ed_start_gui {} {
    global _ED ed_mainf tcl_platform new open save copy cut paste search test ctext lvuser runworld succ fail vus run tick cross oneuser running clock clo masterthread table opmode masterlist pencil distribute boxes autopilot apmode dashboard windock winundock defaultBackground defaultForeground rdbms

   set opmode "Local"
   ttk::toplevel .ed_mainFrame
   wm withdraw .ed_mainFrame
   wm title .ed_mainFrame "HammerDB"
   wm geometry .ed_mainFrame +100+100
   set Parent .ed_mainFrame
   set masterlist ""

   set Name $Parent.statusbar
   pack [ ttk::frame $Name ] -side bottom -anchor se
   pack [ ttk::sizegrip $Name.grip ] -side right -anchor se

   set Name $Parent.menuframe
   ttk::frame $Name 
   pack $Name -anchor nw -expand 0 -fill x -ipadx 0 -ipady 0 \
         -padx 0 -pady 2 -side top

   set Name $Parent.menuframe.file

   set Menu_string($Name) {
    {{command} {New}  {-command ed_edit_clear -underline 0}}
    {{command} {Open} {-command ed_file_load -underline 0}}
    {{command} {Save} {-command ed_file_save -underline 0}}
    {{separator} {} {}}
    {{command} {Exit} {-command ed_stop_gui -underline 1}}
    }

  construct_menu $Name File $Menu_string($Name)

   set Name $Parent.menuframe.edit
   set Menu_string($Name) {
     {{command} {Copy} {-command ed_edit_copy -underline 0}}
     {{command} {Cut} {-command "ed_edit_cut" -underline 2}}
     {{command} {Paste} {-command "ed_edit_paste" -underline 0}}
     {{separator} {} {}}
     {{command}  {Search} {-command "ed_edit_searchf" -underline 0}}
     {{command}  {Turn Word Wrap On} {-command "wrap_on" -underline 0}}
   {{separator} {} {}}
   {{command}  {Choose Font} {-command {catch {.ed_mainFrame.mainwin.textFrame.left.text configure -font "[choose_font "Arial 10"]"}} -underline 0}}
     {{command}  {Turn Highlighting Off} {-command "highlight_off_with_message" -underline 0}}
   {{separator} {} {}}
     {{command } {Test} {-command "ed_run_package" -underline 0}}
	}
proc wrap_on {} {
                  .ed_mainFrame.mainwin.textFrame.left.text configure -wrap word
                     .ed_mainFrame.menuframe.edit.m2 entryconfigure 6 -label "Turn Word Wrap Off"
                     .ed_mainFrame.menuframe.edit.m2 entryconfigure 6 -command "wrap_off"
}
proc wrap_off {} {
                 .ed_mainFrame.mainwin.textFrame.left.text configure -wrap none
                     .ed_mainFrame.menuframe.edit.m2 entryconfigure 6 -label "Turn Word Wrap On"
                     .ed_mainFrame.menuframe.edit.m2 entryconfigure 6 -command "wrap_on"
}
proc highlight_on {} {
#only called on startup
global highlight
set highlight "true"
                     .ed_mainFrame.menuframe.edit.m2 entryconfigure 9 -label "Turn Highlighting Off"
                     .ed_mainFrame.menuframe.edit.m2 entryconfigure 9 -command "highlight_off_with_message"
}
proc highlight_off {} {
#only called on startup
global highlight
set highlight "false"
                     .ed_mainFrame.menuframe.edit.m2 entryconfigure 9 -label "Turn Highlighting On"
                     .ed_mainFrame.menuframe.edit.m2 entryconfigure 9 -command "highlight_on_with_message"
}
proc highlight_on_with_message {} {
global highlight
set highlight "true"
                     .ed_mainFrame.menuframe.edit.m2 entryconfigure 9 -label "Turn Highlighting Off"
                     .ed_mainFrame.menuframe.edit.m2 entryconfigure 9 -command "highlight_off_with_message"
tk_messageBox -title Highlight -message "Highlighting of keywords and program control will be enabled at next script editor load"
}
proc highlight_off_with_message {} {
global highlight
set highlight "false"
                     .ed_mainFrame.menuframe.edit.m2 entryconfigure 9 -label "Turn Highlighting On"
                     .ed_mainFrame.menuframe.edit.m2 entryconfigure 9 -command "highlight_on_with_message"
tk_messageBox -title Highlight -message "Highlighting of keywords and program control will be disabled at next script editor load"
}

   construct_menu $Name Edit $Menu_string($Name)

   set Name $Parent.menuframe.tpcc
   set Menu_string($Name) {
	{{command}  {Benchmark} {-command "select_rdbms none" -underline 0}}
      {{cascade}  {TPC-C Schema} {{{command}  {Build and Driver} {-command "configtpcc all" -underline 6}} {{command}  {Load Driver Script} {-command "loadtpcc" -underline 6}}}}
      {{cascade}  {TPC-H Schema} {{{command}  {Build and Driver} {-command "configtpch all" -underline 6}} {{command}  {Load Driver Script} {-command "loadtpch" -underline 6}}}}
      {{command}  {Virtual User} {-command "vuser_options" -underline 1}}
	{{command}  {Autopilot} {-command "autopilot_options" -underline 0}}
	{{command}  {Transaction Counter} {-command "countopts" -underline 0}}
      {{command}  {Metrics} {-command "metricsopts" -underline 0}}
      {{command}  {Mode} {-command "select_mode" -underline 0}}
      {{tearoff}  {no} {}}
      }
construct_menu $Name Options\  $Menu_string($Name) 

   set Name $Parent.menuframe.help
   set Menu_string($Name) {
      {{command}  {About} {-command "about" -underline 0}}
      {{command}  {License} {-command "license" -underline 0}}
      {{tearoff}  {no} {}}
      }

   construct_menu $Name Help $Menu_string($Name)


   set Name $Parent.statusbar.l17
   ttk::label $Name -text "0.0" 
   pack $Name -anchor nw -side right -expand 0  -fill x 

   set Name $Parent.statusbar.l16
   ttk::label $Name -text "   Row.Col: " 
   pack $Name -anchor nw -side right -expand 0  -fill x    

   set Name $Parent.statusbar.l15
   ttk::label $Name -text "  Mode: $opmode"
   pack $Name -anchor nw -side right -expand 0  -fill x 

   set Name $Parent.statusbar.l14
   ttk::label $Name -text "  File: $_ED(packagekeyname)"
   pack $Name -anchor nw -side right -expand 0  -fill x 

   set Name $Parent.buttons
   ttk::frame $Name 
   pack $Name -anchor nw -side top -expand 0 -fill x -ipadx 0 -ipady 0  \
         -padx 0 -pady 0 

   construct_button $Parent.buttons.clear $new new.ppm "ed_edit_clear" \
      "Clear the screen"

   construct_button $Parent.buttons.load $open open.ppm "ed_file_load" \
       "Open an existing file"

   construct_button $Parent.buttons.save $save save.ppm "ed_file_save" \
       "Save current file"

   set Name $Parent.buttons.l8
   ttk::label $Name -text " " 
   pack $Name -anchor nw -side left -expand 0  -fill x 

   construct_button $Parent.buttons.copy $copy copy.ppm "ed_edit_copy"\
      "Copy selected object or text"

   construct_button $Parent.buttons.cut $cut cut.ppm "ed_edit_cut"\
       "Cut selected object or text"

   construct_button $Parent.buttons.paste $paste paste.ppm "ed_edit_paste" \
       "Paste selected object or text"

   construct_button $Parent.buttons.search $search search.ppm "ed_edit_searchf"\
       "Search for string in text"

   set Name $Parent.buttons.l15
   ttk::label $Name -text " " 
   pack $Name -anchor nw -side left -expand 0  -fill x 

construct_button $Parent.buttons.console $ctext console.gif "convert_to_oratcl" "Convert Trace to Oratcl" 

construct_button $Parent.buttons.test $test test.ppm "ed_run_package" \
       "Test Tcl code"

construct_button $Parent.buttons.lvuser $lvuser arrow.ppm "remote_command load_virtual; load_virtual" "Load Virtual Users" 

construct_button $Parent.buttons.runworld $runworld world.ppm "remote_command run_virtual; run_virtual" "Run Virtual Users" 

   set Name $Parent.buttons.l15a
   ttk::label $Name -text " " 
   pack $Name -anchor nw -side left -expand 0  -fill x 

construct_button $Parent.buttons.boxes $boxes boxes.ppm "check_which_bm" "Create TPC Schema" 

construct_button $Parent.buttons.pencil $pencil pencil.ppm "transcount" "Transaction Counter" 

construct_button $Parent.buttons.dashboard $dashboard dashboard.ppm "metrics" "Metrics" 

set Name $Parent.buttons.l15b
ttk::label $Name -text " " 
pack $Name -anchor nw -side left -expand 0  -fill x 

construct_button $Parent.buttons.autopilot $autopilot autopilot.ppm "start_autopilot" "Autopilot" 
.ed_mainFrame.buttons.autopilot configure -state disabled

construct_button $Parent.buttons.distribute $distribute distribute.ppm "distribute" "Master Distribution" 
$Parent.buttons.distribute configure -state disabled

set succ [image create photo -data $tick -gamma 1 -height 16 -width 16 -palette 5/5/4]
set fail [image create photo -data $cross -gamma 1 -height 16 -width 16 -palette 5/5/4]
set vus [image create photo -data $oneuser -gamma 1 -height 16 -width 16 -palette 5/5/4]
set run [image create photo -data $running -gamma 1 -height 16 -width 16 -palette 5/5/4]
set clo [image create photo -data $clock -gamma 1 -height 16 -width 16 -palette 5/5/4]

   set Name $Parent.panedwin
   if { $ttk::currentTheme eq "clam" || $ttk::currentTheme eq "black" } {
switch $ttk::currentTheme {
	clam { set pbckg $ttk::theme::clam::colors(-frame) }
	black { set pbckg $ttk::theme::black::colors(-frame) }
	}
   panedwindow $Name -orient vertical -handlesize 8 -background $pbckg } else {
   panedwindow $Name -orient vertical -showhandle true
	}
   pack $Name -expand yes -fill both

ttk::style configure Heading -font TkDefaultFont
set Name $Parent.panedwin.subpanedwin
   if { $ttk::currentTheme eq "clam" || $ttk::currentTheme eq "black" } {
switch $ttk::currentTheme {
	clam { set pbckg $ttk::theme::clam::colors(-frame) }
	black { set pbckg $ttk::theme::black::colors(-frame) }
	}
   panedwindow $Name -orient horizontal -handlesize 8 -background $pbckg } else {
   panedwindow $Name -orient horizontal -showhandle true
	}
   pack $Name -expand yes -fill both

set Name $Parent.treeframe
ttk::frame $Name
pack $Name -anchor sw -expand 1 -fill both -side bottom
$Parent.panedwin.subpanedwin add $Name
ttk::scrollbar $Parent.treeframe.vbar -orient vertical -command "$Parent.treeframe.treeview yview"
 pack $Parent.treeframe.vbar -anchor center -expand 0 -fill y -ipadx 0 -ipady 0 \
         -padx 0 -pady 0 -side right
set Name $Parent.treeframe.treeview
   if { $ttk::currentTheme eq "black" } {
ttk::style configure Treeview -background $defaultBackground
ttk::style configure Treeview -fieldbackground $defaultBackground
ttk::style map Treeview -background [ list selected #828282 ]
	}
ttk::treeview $Name -yscrollcommand "$Parent.treeframe.vbar set"
$Name column #0 -stretch 1 -minwidth 1 -width 161
$Name heading #0 -text "Benchmark"
$Name configure -padding {0 0 0 0}
pack $Name -side left -anchor w -expand 1 -fill both 
$Name insert {} end -id "Oracle" -text "Oracle" 
$Name item Oracle -tags {oraopt oraopt2}
$Name tag bind oraopt <Double-ButtonPress-1>  { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if { $rdbms != "Oracle" } { select_rdbms "Oracle" } } }
$Name tag bind oraopt2 <Double-ButtonPress-3>  { if { !([ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] || [ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled hover" ]) } { if { $rdbms eq "Oracle" } { 
.ed_mainFrame.treeframe.treeview selection set Oracle
select_rdbms "Oracle" } } }
$Name insert {} end -id "MSSQLServer" -text "SQL Server" 
$Name item MSSQLServer -tags {mssqlopt mssqlopt2}
$Name tag bind mssqlopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if { $rdbms != "MSSQLServer" } { select_rdbms "MSSQLServer" } } }
$Name tag bind mssqlopt2 <Double-ButtonPress-3>  { if { !([ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] || [ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled hover" ]) } { if { $rdbms eq "MSSQLServer" } {
.ed_mainFrame.treeframe.treeview selection set MSSQLServer
select_rdbms "MSSQLServer" } } }
$Name insert {} end -id "DB2" -text "DB2" 
$Name item DB2 -tags {db2opt db2opt2}
$Name tag bind db2opt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if { $rdbms != "DB2" } { select_rdbms "DB2" } } }
$Name tag bind db2opt2 <Double-ButtonPress-3>  { if { !([ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] || [ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled hover" ]) } { if { $rdbms eq "DB2" } {
.ed_mainFrame.treeframe.treeview selection set DB2
select_rdbms "DB2" } } }
$Name insert {} end -id "MySQL" -text "MySQL" 
$Name item MySQL -tags {mysqlopt mysqlopt2}
$Name tag bind mysqlopt <Double-ButtonPress-1>  { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if { $rdbms != "MySQL" } { select_rdbms "MySQL" } } }  
$Name tag bind mysqlopt2 <Double-ButtonPress-3>  { if { !([ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] || [ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled hover" ]) } { if { $rdbms eq "MySQL" } { .ed_mainFrame.treeframe.treeview selection set MySQL
select_rdbms "MySQL" } } }
$Name insert {} end -id "PostgreSQL" -text "PostgreSQL" 
$Name item PostgreSQL -tags {pgopt pgopt2}
$Name tag bind pgopt <Double-ButtonPress-1>  { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if { $rdbms != "PostgreSQL" } { select_rdbms "PostgreSQL" } } }  
$Name tag bind pgopt2 <Double-ButtonPress-3>  { if { !([ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] || [ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled hover" ]) } { if { $rdbms eq "PostgreSQL" } { .ed_mainFrame.treeframe.treeview selection set PostgreSQL
select_rdbms "PostgreSQL" } } }
$Name insert {} end -id "Redis" -text "Redis" 
$Name item Redis -tags {redopt redopt2}
$Name tag bind redopt <Double-ButtonPress-1>  { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if { $rdbms != "Redis" } { select_rdbms "Redis" } } }  
$Name tag bind redopt2 <Double-ButtonPress-3>  { if { !([ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] || [ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled hover" ]) } { if { $rdbms eq "Redis" } { .ed_mainFrame.treeframe.treeview selection set Redis
select_rdbms "Redis" } } }
$Name insert {} end -id "Trafodion" -text "Trafodion" 
$Name item Trafodion -tags {trafopt trafopt2}
$Name tag bind trafopt <Double-ButtonPress-1>  { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if { $rdbms != "Trafodion" } { select_rdbms "Trafodion" } } }  
$Name tag bind trafopt2 <Double-ButtonPress-3>  { if { !([ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] || [ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled hover" ]) } { if { $rdbms eq "Trafodion" } { .ed_mainFrame.treeframe.treeview selection set Trafodion
select_rdbms "Trafodion" } } }
proc Press {w x y} {
    set e [$w identify $x $y]
    if {[string match "*detach" $e]} {
        $w state pressed
    } else {
        upvar #0 [namespace current]::$w state
        set state(drag) 1
        set state(drag_index) [$w index @$x,$y]
        set state(drag_from_x) $x
        set state(draw_from_y) $y
    }
}
proc Release {w x y rootX rootY} {
    $w state !pressed
    set e [$w identify $x $y]
    set index [$w index @$x,$y]
    if {[string match "*detach" $e]} {
        Detach $w $index
    } else {
        upvar #0 [namespace current]::$w state
        if {[info exists state(drag)] && $state(drag)} {
            set dropwin [winfo containing $rootX $rootY]
            if {$dropwin eq {}} {
                Detach $w $state(drag_index)
            } 
            unset state
        }
    }
}
# Turn a tab into a toplevel (must be a tk::frame)
proc Detach {notebook index} { 
    set tabindex [lindex [$notebook tabs] $index]
    set tabname [ lindex [ split [ $notebook select ] "." ] end ]
if [ string match "*-state normal*" [ $notebook tab $index ] ] {  set tabactive "true" } else { set tabactive "false" }
if { $tabname eq "tc" || $tabname eq "me" } {
if { $tabactive } {
    set title [$notebook tab $index -text]
    $notebook forget $index
    wm manage $tabindex
    wm title $tabindex $title
    wm geometry $tabindex 640x320+30+30
    wm minsize $tabindex 640 320
if { $tabname eq "tc" } {
    wm maxsize $tabindex 640 320
	} else {
    wm resizable $tabindex true true
	}
    wm protocol $tabindex WM_DELETE_WINDOW \
        [namespace code [list Attach $notebook $tabindex $index]]
    event generate $tabindex <<DetachedTab>>
	} else {
#Only Transaction Counter tc and Metrics me can be Detached
	}
   }
}
# Attach a toplevel to the notebook
proc Attach {notebook tab {index end}} {
global windock winundock
set tabcount [ llength [ $notebook tabs ] ]
set tabname [ lindex [ split $tab "." ] end ]
#metrics window always goes one in from end
if { $tabname eq "me" } { set index [ expr $tabcount - 1 ] }
image create photo ::img::dock -data $windock 
image create photo ::img::undock -data $winundock
    set title [wm title $tab]
    wm forget $tab
    if {[catch {
        if {[catch {$notebook insert $index $tab -text $title -compound right -image [list ::img::dock \
                     {active pressed focus !disabled} ::img::dock \
                     {active !disabled} ::img::undock]
	} err]} {
            $notebook add $tab -text $title
        }
        $notebook select $tab
    } err]} {
        wm manage $w
        wm title $w $title
    }
}
image create photo ::img::dock -data $windock 
image create photo ::img::undock -data $winundock 
set Name $Parent.notebook
ttk::notebook $Name
    bind TNotebook <ButtonPress-1> {+Press %W %x %y}
    bind TNotebook <ButtonRelease-1> {+Release %W %x %y %X %Y}
   $Name add [ tk::frame $Parent.mainwin ] -text "Script Editor"
   $Name add [ tk::frame $Parent.tw ] -text "Virtual User Output" -state disabled
   $Name add [ tk::frame $Parent.tc ] -text "Transaction Counter" -state disabled -compound right -image [list ::img::dock \
                     {active pressed focus !disabled} ::img::dock \
                     {active !disabled} ::img::undock]
   $Name add [ tk::frame $Parent.me ] -text "Metrics" -state disabled -compound right -image [list ::img::dock \
                     {active pressed focus !disabled} ::img::dock \
                     {active !disabled} ::img::undock]
   $Name add [ tk::frame $Parent.ap ] -text "Autopilot" -state disabled
   ttk::notebook::enableTraversal $Name
   $Parent.panedwin.subpanedwin add $Name -minsize 5i
   $Parent.panedwin add $Parent.panedwin.subpanedwin  -minsize 3i

   set Name $Parent.vuserframe
   ttk::frame $Name
   $Parent.panedwin add $Name -minsize 1i
   set table [ tablist $Name ]
   tkcon show

   set Name $Parent.buttons.statl15
   ttk::label $Name -text " " 
   pack $Name -anchor nw -side left -expand 0  -fill x 

   set Name $Parent.buttons.statl15a
   ttk::label $Name -text "              " 
   pack $Name -anchor ne -side right -expand 0  -fill x 

 set Name $Parent.buttons.statusframe
if { $ttk::currentTheme eq "black" } {
   frame $Name  -background white -borderwidth 2 -relief flat 
	} else {
   frame $Name  -background LightYellow -borderwidth 2 -relief raised 
	}
   pack $Name -anchor e -fill both -expand 1

   set Name $Parent.buttons.statusframe.currentstatus
   set _ED(status_widget) $Name
if { $ttk::currentTheme eq "black" } {
   ttk::label $Name  -background white -foreground black \
         -justify left -textvariable _ED(status) -relief flat 
	} else {
   ttk::label $Name  -background LightYellow -foreground black \
         -justify left -textvariable _ED(status) -relief flat 
	}
   pack $Name -anchor center

foreach { db bn } { Oracle TPC-C Oracle TPC-H MSSQLServer TPC-C MSSQLServer TPC-H DB2 TPC-C MySQL TPC-C MySQL TPC-H PostgreSQL TPC-C PostgreSQL TPC-H Redis TPC-C Trafodion TPC-C } {
        populate_tree $db $bn 
        }

   wm geometry .ed_mainFrame 806x642+30+30
   if {$tcl_platform(platform) == "windows"} {set y 0}
   wm minsize .ed_mainFrame 330 320
   wm maxsize .ed_mainFrame 990 740
}

proc populate_tree {rdbms bm} {
global boxes runworld option lvuser autopilot pencil dashboard mode driveroptim driveroptlo vuseroptim
set Name .ed_mainFrame.treeframe.treeview
bind .ed_mainFrame.treeframe.treeview <Leave> { ed_status_message -perm }
$Name insert $rdbms end -id $rdbms.$bm -text  $bm
$Name insert $rdbms.$bm end -id $rdbms.$bm.build -text "Schema Build" -image [image create photo -data $boxes] 
$Name item $rdbms.$bm.build -tags {buildhlp}
$Name tag bind buildhlp <Motion> { ed_status_message -help "Build a TPC Schema" } 
$Name insert $rdbms.$bm.build end -id $rdbms.$bm.build.schema -text "Options" -image [image create photo -data $option] 
$Name item $rdbms.$bm.build.schema -tags {buildopt}
$Name tag bind buildopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if {$bm eq "TPC-C"} {configtpcc build } else {configtpch build } } }    
$Name insert $rdbms.$bm.build end -id $rdbms.$bm.build.go -text "Build" -image [image create photo -data $boxes ] 
$Name item $rdbms.$bm.build.go -tags builsch
$Name tag bind builsch <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } {check_which_bm } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.driver -text "Driver Script" -image [image create photo -data $driveroptim ]
$Name item $rdbms.$bm.driver -tags {drvhlp}
$Name tag bind drvhlp <Motion> { ed_status_message -help "Load a TPC Driver Script" } 
$Name insert $rdbms.$bm.driver end -id $rdbms.$bm.driver.schema -text "Options" -image [image create photo -data $option] 
$Name item $rdbms.$bm.driver.schema -tags drvopt
$Name tag bind drvopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if {$bm eq "TPC-C"} {configtpcc drive } else {configtpch drive} } }
$Name insert $rdbms.$bm.driver end -id $rdbms.$bm.driver.load -text "Load" -image [image create photo -data $driveroptlo] 
$Name item $rdbms.$bm.driver.load -tags drvscr
$Name tag bind drvscr <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if {$bm eq "TPC-C"} {loadtpcc} else {loadtpch} } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.vusers -text "Virtual User" -image [image create photo -data $vuseroptim ]
$Name item $rdbms.$bm.driver -tags {vuserhlp}
$Name tag bind vuserhlp <Motion> { ed_status_message -help "Configure Virtual Users" } 
$Name insert $rdbms.$bm.vusers end -id $rdbms.$bm.vusers.options -text "Options" -image [image create photo -data $option] 
$Name item $rdbms.$bm.vusers.options -tags vuseopt
$Name tag bind vuseopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } {vuser_options } }
$Name insert $rdbms.$bm.vusers end -id $rdbms.$bm.vusers.load -text "Create" -image [image create photo -data $lvuser] 
$Name item $rdbms.$bm.vusers.load -tags vuseload
$Name tag bind vuseload <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { .ed_mainFrame.buttons.lvuser invoke } }
$Name insert $rdbms.$bm.vusers end -id $rdbms.$bm.vusers.run -text "Run" -image [image create photo -data $runworld] 
$Name item $rdbms.$bm.vusers.run -tags vuserun
$Name tag bind vuserun <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { .ed_mainFrame.buttons.runworld invoke } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.autopilot -text "Autopilot" -image [image create photo -data $autopilot ]
$Name item $rdbms.$bm.autopilot -tags {autohlp}
$Name tag bind autohlp <Motion> { ed_status_message -help "Configure Automated Tests" } 
$Name insert $rdbms.$bm.autopilot end -id $rdbms.$bm.autopilot.options -text "Options" -image [image create photo -data $option] 
$Name item $rdbms.$bm.autopilot.options -tags autoopt
$Name tag bind autoopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } {autopilot_options } }
$Name insert $rdbms.$bm.autopilot end -id $rdbms.$bm.autopilot.start -text "Autopilot" -image [image create photo -data $autopilot] 
$Name item $rdbms.$bm.autopilot.start -tags autostart
$Name tag bind autostart <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { start_autopilot } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.txcounter -text "Transactions" -image [image create photo -data $pencil ]
$Name item $rdbms.$bm.txcounter -tags {txhlp}
$Name tag bind txhlp <Motion> { ed_status_message -help "Configure Transaction Counter" } 
$Name insert $rdbms.$bm.txcounter end -id $rdbms.$bm.txcounter.options -text "Options" -image [image create photo -data $option] 
$Name item $rdbms.$bm.txcounter.options -tags txopt
$Name tag bind txopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { countopts } }
$Name insert $rdbms.$bm.txcounter end -id $rdbms.$bm.txcounter.start -text "Counter" -image [image create photo -data $pencil] 
$Name item $rdbms.$bm.txcounter.start -tags txstart
$Name tag bind txstart <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { .ed_mainFrame.buttons.pencil invoke } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.metrics -text "Metrics" -image [image create photo -data $dashboard ]
$Name item $rdbms.$bm.metrics -tags {methlp}
$Name tag bind methlp <Motion> { ed_status_message -help "Configure Metrics" } 
$Name insert $rdbms.$bm.metrics end -id $rdbms.$bm.metrics.options -text "Options" -image [image create photo -data $option] 
$Name item $rdbms.$bm.metrics.options -tags metopt
$Name tag bind metopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { metricsopts } }
$Name insert $rdbms.$bm.metrics end -id $rdbms.$bm.metrics.start -text "Display" -image [image create photo -data $dashboard ] 
$Name item $rdbms.$bm.metrics.start -tags metstart
$Name tag bind metstart <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { .ed_mainFrame.buttons.dashboard invoke } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.mode -text "Mode" -image [image create photo -data $mode ]
$Name item $rdbms.$bm.mode -tags {modehlp}
$Name tag bind modehlp <Motion> { ed_status_message -help "Configure Connections" } 
$Name insert $rdbms.$bm.mode end -id $rdbms.$bm.mode.options -text "Options" -image [image create photo -data $option] 
$Name item $rdbms.$bm.mode.options -tags modeopt
$Name tag bind modeopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } {select_mode } }
}

proc ed_stop_gui {} {
    ed_wait_if_blocked
    exit
}

proc construct_menu {Name label cmd_list} {
   global _ED defaultBackground defaultForeground

   ttk::menubutton $Name -text $label  -underline 0 -width [ string length $label ]
   incr _ED(menuCount);
   set newmenu $Name.m$_ED(menuCount)

   $Name configure -menu $newmenu

   catch "destroy $newmenu"
  
   eval "menu $newmenu"

   eval [list add_items_to_menu $newmenu $cmd_list]

if { $ttk::currentTheme eq "black" } {
 	$newmenu configure -background $defaultBackground -foreground $defaultForeground -activebackground #828282 -activeforeground $defaultForeground
	} else {
   $newmenu configure -background $defaultBackground
	}

pack $Name -anchor nw -expand 0 -ipadx 4 -ipady 0 -padx 0 \
         -pady 0 -side left

  }

proc add_items_to_menu {menubutton cmdList} {
  global _ED defaultBackground defaultForeground

  foreach cmd $cmdList {
    switch [lindex $cmd 0] {
      "separator" {
         set doit "$menubutton add separator [lindex $cmd 2]"
	 eval $doit
         }
      "tearoff"  {
         if {[string match [lindex $cmd 2] "no"]} {
	   $menubutton configure -tearoff no
	   }
         }
	"radio" {
 set doit "$menubutton add radio -label {[lindex $cmd 1]} \
	     -variable [lindex $cmd 2] -value on"
	 eval $doit
	   }
      "command"  {
         set doit "$menubutton add [lindex $cmd 0] -background $defaultBackground -label {[lindex $cmd 1]} \
	     [lindex $cmd 2]"
	 eval $doit
         }
      "cascade"  {
         incr _ED(menuCount);
	 set newmenu $menubutton.m$_ED(menuCount)
         set doit "$menubutton add cascade -label {[lindex $cmd 1]} \
	   -menu $newmenu"
	 eval $doit 
	 menu $newmenu
if { $ttk::currentTheme eq "black" } {
        $newmenu configure -background $defaultBackground -foreground $defaultForeground \
	-activebackground #828282 -activeforeground $defaultForeground
        }
	 add_items_to_menu $newmenu [lindex $cmd 2]
         }
      }
    }
  }

proc disable_tree { } {
    global rdbms bm
    set Name .ed_mainFrame.treeframe.treeview
    set databases [$Name children {}]
    foreach db $databases {
        set benchmarks [$Name children $db]
        foreach dbbn $benchmarks {
            $Name detach $dbbn
        }
    }
    $Name move $rdbms {} 0
    $Name move $rdbms.$bm $rdbms 0
    $Name see $rdbms.$bm
    $Name focus $rdbms.$bm
    $Name selection set $rdbms.$bm
}
  
proc disable_enable_options_menu { disoren } {
global rdbms bm
set Name .ed_mainFrame.menuframe.tpcc.m3
if { $disoren eq "disable" } {
for { set entry 0 } {$entry < 6 } {incr entry} {
#8 entries in menu leave last 3 always enabled
$Name entryconfigure $entry -state disabled
			}
set Name .ed_mainFrame.buttons.boxes
$Name configure -state disabled
set Name .ed_mainFrame.treeframe.treeview
$Name state disabled
	} else {
for { set entry 0 } {$entry < 6 } {incr entry} {
$Name entryconfigure $entry -state normal
				}
if {  [ info exists rdbms ] } { ; } else { set rdbms "Oracle" }
if { $rdbms eq "Redis" || $rdbms eq "Trafodion" } { set bm "TPC-C" }
if {  [ info exists bm ] } { ; } else { set bm "TPC-C" }
if { $bm eq "TPC-C" } {
$Name entryconfigure 2 -state normal
$Name entryconfigure 3 -state disabled
	} else {
$Name entryconfigure 3 -state normal
$Name entryconfigure 2 -state disabled
		}
set Name .ed_mainFrame.buttons.boxes
$Name configure -state normal
set Name .ed_mainFrame.treeframe.treeview
$Name state !disabled
	}
}

proc disable_bm_menu {} {
global rdbms bm tcl_platform highlight
if {$tcl_platform(platform) != "windows" && $rdbms == "MSSQLServer" } { 
	set rdbms "Oracle" 
	}
if {  [ info exists rdbms ] } { ; } else { set rdbms "Oracle" }
if { $rdbms eq "Redis" || $rdbms eq "Trafodion" || $rdbms eq "DB2" } { set bm "TPC-C" }
if {  [ info exists bm ] } { ; } else { set bm "TPC-C" }
if { $bm eq "TPC-C" } {
.ed_mainFrame.menuframe.tpcc.m3 entryconfigure 2 -state normal
.ed_mainFrame.menuframe.tpcc.m3 entryconfigure 3 -state disabled
	} else {
.ed_mainFrame.menuframe.tpcc.m3 entryconfigure 3 -state normal
.ed_mainFrame.menuframe.tpcc.m3 entryconfigure 2 -state disabled
		}
if {$rdbms == "Oracle"} { 
.ed_mainFrame.buttons.console configure -state normal 
	} else {
.ed_mainFrame.buttons.console configure -state disabled
       }
disable_tree
if { $highlight eq "true" } {
highlight_on
	} else {
highlight_off
	}
}

proc loadtpcc {} {
global _ED rdbms oradriver mysqldriver mssqlsdriver db2driver pg_driver redis_driver trafodion_driver
set _ED(packagekeyname) "TPC-C"
ed_status_message -show "TPC-C Driver Script"
if { [ info exists rdbms ] } { ; } else { set rdbms "Oracle" }
if { ![ info exists oradriver ] } { set oradriver "standard" }
if { ![ info exists mysqldriver ] } { set mysqldriver "standard" }
if { ![ info exists mssqlsdriver ] } { set mssqlsdriver "standard" }
if { ![ info exists db2driver ] } { set db2driver "standard" }
if { ![ info exists pg_driver ] } { set pg_driver "standard" }
if { ![ info exists redis_driver ] } { set redis_driver "standard" }
if { ![ info exists trafodion_driver ] } { set trafodion_driver "standard" }
switch $rdbms {
Oracle {
if {$oradriver == "standard"} {
loadoratpcc
	} else {
loadoraawrtpcc
     } 
}
MySQL {
if {$mysqldriver == "standard"} {
loadmytpcc
     } else {
loadtimedmytpcc
     }
}
MSSQLServer {
if {$mssqlsdriver == "standard"} {
loadmssqlstpcc
     } else {
loadtimedmssqlstpcc
     }
}
DB2 {
if {$db2driver == "standard"} {
loaddb2tpcc
     } else {
loadtimeddb2tpcc
     }
}
PostgreSQL {
if {$pg_driver == "standard"} {
loadpgtpcc
     } else {
loadtimedpgtpcc
     }
}
Redis {
if {$redis_driver == "standard"} {
loadredistpcc
     } else {
loadtimedredistpcc
     }
}
Trafodion {
if {$trafodion_driver == "standard"} {
loadtraftpcc
     } else {
loadtimedtraftpcc
     }
}
default {
if {$oradriver == "standard"} {
loadoratpcc
	} else {
loadoraawrtpcc
     		} 
	}
    }
applyctexthighlight .ed_mainFrame.mainwin.textFrame.left.text
}

proc loadtpch {} {
global _ED rdbms
set _ED(packagekeyname) "TPC-H"
ed_status_message -show "TPC-H Driver Script"
if { [ info exists rdbms ] } { ; } else { set rdbms "Oracle" }
switch $rdbms {
Oracle {
loadoratpch
} 
MySQL {
loadmytpch
}
MSSQLServer {
loadmssqlstpch
    	}
PostgreSQL {
loadpgtpch
	}
default {
loadoratpch
	}
   }
applyctexthighlight .ed_mainFrame.mainwin.textFrame.left.text
}

proc construct_button {Name data file cmd helpmsg} {

global tcl_version ctext 

set im [image create photo -data $data -gamma 1 -height 16 -width 16 -palette 5/5/4]

ttk::button $Name -image $im -command "$cmd"
   pack $Name -anchor nw -side left -expand 0  -fill x 
   bind $Name <Enter> [list ed_status_message -help $helpmsg]
   bind $Name <Leave> {ed_status_message -perm}   
  }

proc ed_file_load {} {
    global _ED ed_loadsave
 if { $autostart::autostartap == "true" } {
	global apmode
        set _ED(file) $autostart::autoloadscript
	set apmode "enabled"
    } else {
   set _ED(file) [ed_loadsave load]
	}
    if {$_ED(file) == ""} {return}
    if {![file readable $_ED(file)]} {
        ed_error "File \[$_ED(file)\] is not readable."
        return
    }
    ed_wait_if_blocked
    set _ED(blockflag) 1
    ed_status_message -show "loading file:  \"$_ED(file)\" ..."
    update
    if {[catch "open \"$_ED(file)\" r" fd]} {
      ed_error "Error while opening $_ED(file): \[$fd\]"
      ed_status_message -perm
      set _ED(blockflag) 0
      return
   }
    set _ED(package) "[read $fd]"
    close $fd
   set _ED(temppackage) $_ED(package)
   set _ED(packagekeyname) [file tail $_ED(file)]
   if {$_ED(packagekeyname) == ""} {set _ED(packagekeyname) $_ED(file)}
   if {$_ED(packagekeyname) == ""} {set _ED(packagekeyname) "UNKNOWN"}
 
    ed_edit
    ed_status_message -perm
    applyctexthighlight .ed_mainFrame.mainwin.textFrame.left.text
    update
    set _ED(blockflag) 0
}

proc ed_file_save {} {
    global _ED 
    ed_wait_if_blocked
    set _ED(blockflag) 1
    set _ED(package) "[.ed_mainFrame.mainwin.textFrame.left.text get 1.0 end]"
    set _ED(blockflag) 0
    set $_ED(file) [ed_loadsave save]
    if {$_ED(file) == ""} {return}
    if {[file exists $_ED(file)]} {
        if {![file writable $_ED(file)]} {
            ed_error "File \[$_ED(file)\] is not writable."
            return
        }
    }
    ed_wait_if_blocked
    set _ED(blockflag) 1
    ed_status_message -show "saving file:  \"$_ED(file)\" ..."
    update
    if {[catch "open \"$_ED(file)\" w" fd]} {
      ed_error "Error opening $_ED(file):  \[$fd\]"
      ed_status_message -perm
      update
      set _ED(blockflag) 0
      return
   }
    puts $fd "$_ED(package)"
    close $fd
    ed_status_message -perm
    update
    set _ED(blockflag) 0
}

proc ed_loadsave {loadflag} {
   global ed_loadsave _ED 
   if {![info exists ed_loadsave(pwd)]} {
      set ed_loadsave(pwd) [pwd]
      set ed_loadsave(filter) "*.tcl"
      set ed_loadsave(file) ""
   }
   set ed_loadsave(loadflag) $loadflag
   set ed_loadsave(path) ""
   set ed_loadsave(done) 0

   ttk::toplevel .ed_loadsave
   wm withdraw .ed_loadsave
   if {[string match $loadflag "load"]} {
      wm title .ed_loadsave "Open File"
   } else {
      wm title .ed_loadsave "Save File"
   }

   wm geometry .ed_loadsave +[expr  \
	([winfo screenwidth .]/2) - 173]+[expr ([winfo screenheight .]/2) - 148]
   
   set Parent .ed_loadsave
   
   set Name $Parent.dir
   ttk::frame $Name 
   pack $Name -anchor nw -side top 

   set Name $Parent.dir.e3
   ttk::entry $Name -width 35 -textvariable ed_loadsave(pwd)
   pack $Name -side right -anchor nw -padx 5
   bind $Name <Return> {ed_loadsavegetentries}
      bind $Name <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }

   set Name $Parent.dir.l1
   ttk::label $Name -text "Directory: "
   pack $Name -side right -anchor nw

   set Name $Parent.type
   ttk::frame $Name 
   pack $Name -anchor nw -side top -fill x

   set Name $Parent.type.e7
   ttk::entry $Name -width 35 -textvariable ed_loadsave(filter)
   pack $Name -side right -anchor nw -padx 5
   bind $Name <Return> {ed_loadsavegetentries}
       bind $Name <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }

   set Name $Parent.type.l5
   ttk::label $Name -text "File Type: "
   pack $Name -side right -anchor nw
   
   set Name $Parent.file
   ttk::frame $Name
   pack $Name -anchor nw -side top -fill x

   set Name $Parent.file.e11
   ttk::entry $Name -width 35 -textvariable ed_loadsave(file)
   pack $Name -side right -anchor nw -padx 5
   .ed_loadsave.file.e11 delete 0 end
   .ed_loadsave.file.e11 insert 0 $_ED(packagekeyname)
       bind $Name <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }
   bind $Name <Return> {if {[ed_loadsavevalentry]} {set ed_loadsave(done) 1}}
   
   set Name $Parent.file.l9
   ttk::label $Name -text "File: "
   pack $Name -side right -anchor nw

   set Name $Parent.list
   ttk::frame $Name -borderwidth 2 -height 50 \
         	-relief raised -width 50
   pack $Name -side top -anchor nw -expand yes -fill both
   
   set Name $Parent.list.lb1
   listbox $Name -background white -yscrollcommand "$Parent.list.sb2 set" -selectmode browse
   pack $Name -anchor center -expand 1 -fill both -ipadx 0 -ipady 0 \
         -padx 2 -pady 2 -side left
       bind $Name <Any-ButtonPress> {ed_loadsaveselbegin %W %y}
       bind $Name <Any-ButtonRelease> {ed_loadsaveselbegin2 %W}
       bind $Name <Any-Motion> {ed_loadsaveselbegin %W %y}
       bind $Name <Any-Double-ButtonPress> {ed_loadsaveselbegin %W %y}
       bind $Name <Any-Double-ButtonRelease> {set _ED(packagekeyname) \
			$seld_file; ed_loadsaveselend %W %y}
   bind $Name <Any-Triple-ButtonPress> {break}
   bind $Name <Any-Triple-ButtonRelease> {break}
      bind $Name <Return> {ed_loadsaveselend %W %y}
       bind $Name <Up> {
      tkCancelRepeat
      tkListboxBeginSelect %W [%W index active]
      %W activate [%W index active]
   }
   bind $Name <Down> {
      tkCancelRepeat
      tkListboxBeginSelect %W [%W index active]
      %W activate [%W index active]
   }
   
   set Name $Parent.list.sb2
   ttk::scrollbar $Name -command "$Parent.list.lb1 yview"
   pack $Name -anchor center -expand 0 -fill y -ipadx 0 -ipady 0 \
         -padx 2 -pady 2 -side left
   
   set Name $Parent.buttons
   ttk::frame $Name
   pack $Name -side top -anchor nw -fill x

   set Name $Parent.buttons.cancel
   ttk::button $Name -text Cancel \
         -command {destroy .ed_loadsave}
   pack $Name -side right -anchor nw -padx 3 -pady 3

   set Name $Parent.buttons.ok
   ttk::button $Name  -text OK \
         -command {set _ED(packagekeyname) [.ed_loadsave.file.e11 get]; if \
		{[ed_loadsavevalentry]} {set ed_loadsave(done) 1}}
   pack $Name -side right -anchor nw -padx 3 -pady 3
   
   ed_loadsavegetentries
   wm deiconify .ed_loadsave
   vwait ed_loadsave(done)
   destroy .ed_loadsave
   if {[file isdirectory $ed_loadsave(path)]} {set ed_loadsave(path) ""}
   return $ed_loadsave(path)
}

proc ed_loadsaveselbegin {win ypos} {
   $win select anchor [$win nearest $ypos]
}

proc ed_loadsaveselbegin2 {win} {

   global seld_file
        set seld_file [$win get [$win curselection]]  
        .ed_loadsave.file.e11 delete 0 end
        .ed_loadsave.file.e11 insert 0 $seld_file
   set _ED(packagekeyname) $seld_file
}

proc ed_loadsaveselend {win ypos} {
   global ed_loadsave
   $win select set anchor [$win nearest $ypos]
   set fil [.ed_loadsave.list.lb1 get [lindex [$win curselection] 0]]
   if {-1 == [string last "/" $fil]} {
      set ed_loadsave(file) $fil
      set ed_loadsave(path) \
	[ concat $ed_loadsave(pwd)\/$ed_loadsave(file) ]
        set ed_loadsave(done) 1
    cd [file dirname $ed_loadsave(path) ]
      return ""
   }
   set ed_loadsave(pwd) [ed_loadsavemergepaths \
         $ed_loadsave(pwd) [string trimright $fil "/"]]
   ed_loadsavegetentries
   return ""
}

proc ed_loadsavegetentries {} {
   global ed_loadsave tcl_version
   set e 0
   if {![file isdirectory $ed_loadsave(pwd)]} {
      gui_error "\"$ed_loadsave(pwd)\" is not a valid directory"
      .ed_loadsave configure -cursor {}
      set e 1
   }
   .ed_loadsave configure -cursor watch
   update

set sort_mode "-dictionary"  
if {[info exists tcl_version] == 0 || $tcl_version < 8.0} {
    set sort_mode "-ascii"
}

   if {$ed_loadsave(filter) == ""} {set ed_loadsave(filter) "*"}
   set files [lsort $sort_mode "[glob -nocomplain $ed_loadsave(pwd)/.*]  \
		[glob -nocomplain $ed_loadsave(pwd)/*]"]
   .ed_loadsave.list.lb1 delete 0 end
   if {$e} {
      .ed_loadsave configure -cursor {}
      update 
      return
   }
   set d "./ ../"
   set fils ""
   foreach f $files {
      set ff [file tail $f]
      if {$ff != "." && $ff != ".."} {
         if {[file isdirectory $f]} {
            lappend d "$ff/"
         } else {
            if {[string match $ed_loadsave(filter) $ff]} {
               lappend fils "$ff"
            }
         }
      }
   }
   set files "$d $fils"
   foreach f $files {
      .ed_loadsave.list.lb1 insert end $f
   }
   .ed_loadsave configure -cursor {}
   update 
}

proc ed_loadsavevalentry {} {
   global ed_loadsave _ED
   if {"." != [file dirname $ed_loadsave(file)]} {
      set path [ed_loadsavemergepaths \
            $ed_loadsave(pwd) $ed_loadsave(file)]
      set ed_loadsave(pwd) [file dirname $path]
      if {[file extension $path] != ""} {
         set ed_loadsave(filter) "*[file extension $path]"
      } else {
         set ed_loadsave(filter) "*"
      }
      set ed_loadsave(file) [file tail $path]
      ed_loadsavegetentries
      return 0
   }
   set fil [ed_loadsavemergepaths $ed_loadsave(pwd) $ed_loadsave(file)]
   if {[string match $ed_loadsave(loadflag) "load"]} {
      if {(![file exists $fil]) || (![file readable $fil])} {
         gui_error "\"$fil\" cannot be loaded."
         set ed_loadsave(path) ""
         return 0
      } else {
         set ed_loadsave(path) $fil
         set _ED(file) $fil
         set ed_loadsave(done) 1
         return 1
      }
   } else {
      set d [file dirname $fil]
      if {![file writable $d]} {
         gui_error "\"$d\" directory cannot be written to."
         set ed_loadsave(path) ""
         set _ED(file) ""
         return 0
      }
      if {[file exists $fil] && (![file writable $fil])} {
         gui_error "\"$file\" cannot be written to."
         set ed_loadsave(path) ""
         set _ED(file) ""
         return 0
      }
      set ed_loadsave(path) $fil
      set ed_loadsave(done) 1
      set _ED(file) $fil
      return 1
   }
}

proc ed_loadsavemergepaths {patha pathb} {
   set pa [file split $patha]
   set pb [file split $pathb]
   if {[string first ":" [lindex $pb 0]] != -1} {return [eval file join $pb]}
   if {[lindex $pb 0] == "/"} {return [eval file join $pb]}
   set i [expr [llength $pa] - 1]
   foreach item $pb {
      if {$item == ".."} {
         incr i -1
         set pa [lrange $pa 0 $i]
      } elseif {$item == "."} {
         # -- do nothing
      } else {
         lappend pa $item
      }
   }
   return [eval file join $pa]
}
   
proc gui_error {message} {
   tk_messageBox -icon error -message $message
}

if {[info procs bgerror] == ""} {
   proc bgerror {{message ""}} {
      global errorInfo
    if {[string match {*threadscreated*} $errorInfo]} {
      #puts stderr "Background Error ignored - Threads Killed"
	} else {
	puts stderr "Unmatched Background Error - $errorInfo"
	}
   }
}

proc ed_edit_searchf {} {
   global _ED
   catch "destroy .ed_edit_searchf"
   ttk::toplevel .ed_edit_searchf
   wm withdraw .ed_edit_searchf
   wm title .ed_edit_searchf {Search}

   set Parent .ed_edit_searchf

   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5

   set Name $Parent.f1.l1
   ttk::label $Name -text "Search for: "
   grid $Name -column 0 -row 0 -sticky e

   set Name $Parent.f1.e1
   ttk::entry $Name -width 30
   grid $Name -column 1 -row 0

   bind .ed_edit_searchf.f1.e1 <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }
   bind .ed_edit_searchf.f1.e1 <Return> {tk_focusNext %W}
   $Name delete 0 end

	set Name $Parent.f1.l2
	ttk::label $Name -text "Replace with: "
      grid $Name -column 0 -row 1 -sticky e

	set Name $Parent.f1.e2
	ttk::entry $Name -width 30
      grid $Name -column 1 -row 1
	global Procs
	set Procs($Name) { {bind .ed_edit_searchf.f1.e2 <BackSpace>} \
			{bind .ed_edit_searchf.f1.e2 <Delete>} \
			{bind .ed_edit_searchf.f1.e2 <Return>} \
			{bind .ed_ediy_searchf.f1.e2 <Enter>}}
	bind .ed_edit_searchf.f1.e2 <BackSpace> {tkEntryBackspace %W}
	bind .ed_edit_searchf.f1.e2 <Delete> {
		if [%W selection present] {
			%W delete sel.first sel.last
		} else {
			%W delete insert
		}
	}
	bind .ed_edit_searchf.f1.e2 <Return> {tk_focusNext %W}
	$Name delete 0 end

  set Name $Parent.mainwin
   ttk::frame $Name
   pack $Name -anchor nw -side top -fill x -padx 5 -pady 5

   set Name $Parent.mainwin.b3
   ttk::button $Name -command {destroy .ed_edit_searchf; if {[.ed_mainFrame.mainwin.textFrame.left.text tag ranges sel] != ""} {.ed_mainFrame.mainwin.textFrame.left.text tag remove sel 1.0 end}} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3

set Name $Parent.mainwin.b2
   ttk::button $Name -command {
		   if {[.ed_mainFrame.mainwin.textFrame.left.text get sel.first sel.last] != ""} {
             	set _ED(rplc_term) [.ed_edit_searchf.f1.e2 get]
			.ed_mainFrame.mainwin.textFrame.left.text insert $_ED(editcursor) $_ED(rplc_term)
			.ed_mainFrame.mainwin.textFrame.left.text  delete sel.first sel.last
			raise .ed_edit_searchf	
                 } 
		} -text {Replace}
   pack $Name -anchor nw -side right -padx 3 -pady 3

   set Name $Parent.mainwin.b1
   ttk::button $Name -command {
            set _ED(srch_new) [.ed_edit_searchf.f1.e1 get]
            if {[.ed_mainFrame.mainwin.textFrame.left.text tag ranges sel] != ""} {.ed_mainFrame.mainwin.textFrame.left.text tag remove sel 1.0 end}
            if {$_ED(srch_new) != $_ED(srch_old)} {set _ED(editcursor) 1.0}
            ed_edit_search .ed_mainFrame.mainwin.textFrame.left.text $_ED(srch_new)
            set _ED(srch_old) [.ed_edit_searchf.f1.e1 get]
            focus .ed_mainFrame.mainwin.textFrame.left.text 
            raise .ed_edit_searchf  
            }  -text {Search}
   pack $Name -anchor nw -side right -padx 3 -pady 3

   set x [expr [winfo rootx .ed_mainFrame] + 300]
   set y [expr [winfo rooty .ed_mainFrame] + [winfo height .ed_mainFrame] - 300]
   wm geometry .ed_edit_searchf +$x+$y
   wm deiconify .ed_edit_searchf
   raise .ed_edit_searchf
   update
   wm minsize .ed_edit_searchf [winfo width .ed_edit_searchf] \
		[winfo height .ed_edit_searchf]
   wm maxsize .ed_edit_searchf [winfo width .ed_edit_searchf] \
		[winfo height .ed_edit_searchf]
   
}

proc ed_edit_search {textwin srch_string} {
    global _ED

   if {$srch_string == ""} {set _ED(editcursor) 1.0; return}
   set length 0;

   set fail [catch {\
      $textwin search -regexp -count length $srch_string $_ED(editcursor) end} \
      _ED(editcursor) ]
   
   if { ($length != 0) && (!$fail) } {
     $textwin tag add sel $_ED(editcursor) "$_ED(editcursor) + $length char"
     set _ED(editcursor) [$textwin index "$_ED(editcursor) + $length char"]
        $textwin see $_ED(editcursor)
	} else {set _ED(editcursor) 1.0}

   if {$_ED(editcursor) == 1.0} {ed_error "No match for string"; return}
   if {$_ED(editcursor) == $_ED(editcurold)} {ed_error "End of search"}
        set _ED(editcurold) $_ED(editcursor)
}

proc ed_edit_clear {} {
   global _ED
   ed_wait_if_blocked
   set _ED(blockflag) 1
   set _ED(temppackage) ""
   set _ED(blockflag) 0
   if {[info commands .ed_mainFrame.mainwin.f1] != ""} {
      .ed_mainFrame.mainwin.textFrame.left.text delete 1.0 end
      set _ED(packagekeyname) [.ed_mainFrame.mainwin.f1.e5 get]
   }

   set _ED(package) ""
   set _ED(packagekeyname) ""
   ed_edit
}

proc ed_edit_commit {} {
    global _ED
    ed_wait_if_blocked
    set _ED(blockflag) 1
    set _ED(package) "[.ed_mainFrame.mainwin.textFrame.left.text get 1.0 end]"
    set _ED(blockflag) 0
   update
}

proc ed_edit_cut {} {

	tk_textCut  .ed_mainFrame.mainwin.textFrame.left.text

}

proc ed_edit_copy {} {
	tk_textCopy  .ed_mainFrame.mainwin.textFrame.left.text
}


proc ed_edit_paste {} {
	tk_textPaste  .ed_mainFrame.mainwin.textFrame.left.text
}

proc tlines {text} {
return [expr [lindex [split [$text index end] .] 0] -1]
}

proc applyctexthighlight {w} {
global highlight
if { $highlight eq "true" } {
#force cursor change for windows
.ed_mainFrame conf -cursor watch
tk busy .ed_mainFrame
$w highlight 1.0 [ tlines $w ].0
tk busy forget .ed_mainFrame
.ed_mainFrame conf -cursor {}
ed_status_message -temp "Highlighting Complete"
update
	} else {
#Don't highlight
	;
		}
	}

proc setctexthighlight {w} {
         set colour(vars) green
         set colour(cmds) blue
         set colour(functions) magenta
         set colour(brackets) gray50
         set colour(comments) black
         set colour(strings) red
        ctext::addHighlightClassWithOnlyCharStart $w vars $colour(vars) "\$"
        ctext::addHighlightClass $w cmds $colour(cmds) [ list mysqlconnect oralogon tell socket subst open eof oraplexec pwd mysqlquery oraopen glob list mysqlnext pid exec oraexec auto_load_index time unknown eval lassign lrange fblocked lsearch oracols auto_import gets mysqlmap case lappend proc throw mysqlbaseinfo mysqlresult break mysqlseek variable llength orabind auto_execok return pkg_mkIndex linsert mysqlsel error oracommit catch mysqlping clock info split orainfo redis array if fconfigure coroutine concat join lreplace mysqlreceive source fcopy global orastmlist switch auto_qualify update mysqlcol tclPkgUnknown close orabreak cd for auto_load file append lreverse oramsg format lmap mysqlchangeuser mysqlendquery unload read package set namespace binary scan apply mysqlstate oralob oraldalist oralogoff trace oraconfig seek oradesc zlib while chan flush after mysqlexec mysqluse vwait orafetch dict uplevel continue try mysqlinsertid oraclose foreach lset rename oralong oraautocom fileevent yieldto regexp mysqlclose orabindexec lrepeat tclPkgSetup upvar tailcall mysqlescape encoding expr unset load regsub mysqlinfo orasql history interp exit oraroll puts incr lindex lsort oraparse tclLog string yield tsv::get tsv::set pg_backend_pid pg_blocking pg_cancelrequest pg_conndefaults pg_connect pg_disconnect pg_escape_bytea pg_escape_string pg_exec pg_exec_params pg_exec_prepared pg_execute pg_getresult pg_isbusy pg_listen pg_lo_close pg_lo_creat pg_lo_export pg_lo_import pg_lo_lseek pg_lo_open pg_lo_read pg_lo_tell pg_lo_unlink pg_lo_write pg_notice_handler pg_on_connection_loss pg_parameter_status pg_quote pg_result pg_result_callback pg_select pg_sendquery pg_sendquery_params pg_sendquery_prepared pg_server_version pg_transaction_status pg_unescape_bytea database ]

 	ctext::addHighlightClass $w functions $colour(functions) [ list abs acos asin atan atan2 bool ceil cos cosh double entier exp floor fmod hypot int isqrt log log10 max min pow rand round sin sinh sqrt srand tan tanh wide ]
         ctext::addHighlightClassForSpecialChars $w brackets $colour(brackets) {\{\}\[\]}
         ctext::addHighlightClassForRegexp $w comments $colour(comments) {\#[^\n\r]*} 
         ctext::addHighlightClassForRegexp $w strings $colour(strings) {"(\\"|[^"])*"} 
 }

proc ed_edit {} {
   global _ED defaultBackground defaultForeground
   global Menu_string
   global highlight

   catch "destroy .ed_mainFrame.mainwin.buttons"
   catch "destroy .ed_mainFrame.mainwin.f1"
   catch "destroy .ed_mainFrame.mainwin.textFrame"
   
   set Parent .ed_mainFrame.mainwin
   
   set Name $Parent.textFrame
   ttk::frame $Name
   pack $Name -anchor sw -expand 1 -fill both -side bottom

   set Name $Parent.textFrame.right
   ttk::frame $Name -height 10 -width 15
   pack $Name -anchor sw -expand 0 -fill x -ipadx 0 -ipady 0 -padx 0 \
         -pady 0 -side bottom

   set Name $Parent.textFrame.right.vertScrollbar
   ttk::scrollbar $Name -command "$Parent.textFrame.left.text xview" \
         -orient horizontal 
   pack $Name -anchor center -expand 1 -fill x -ipadx 0 -ipady 0 -padx "0 16" \
         -pady 0 -side left

   set Name $Parent.textFrame.left
   ttk::frame $Name 
   pack $Name -anchor center -expand 1 -fill both -ipadx 0 -ipady 0 \
         -padx 0 -pady 0 -side top
   
   set Name $Parent.textFrame.left.horizScrollbar
   ttk::scrollbar $Name -command "$Parent.textFrame.left.text yview" 
   pack $Name -anchor center -expand 0 -fill y -ipadx 0 -ipady 0 \
         -padx 0 -pady 0 -side right

   set Name $Parent.textFrame.left.text
if { $ttk::currentTheme eq "black" } { 
	set bwidth 0 
	set hbgrd LightGray
	} else { 
	set bwidth 2 
	set hbgrd $defaultBackground
	} 
if { $highlight eq "true" } {
   ctext $Name -background white  -borderwidth $bwidth -foreground black \
	-highlight 1 \
         -highlightbackground LightGray -insertbackground black \
         -selectbackground $hbgrd -selectforeground black \
         -wrap none \
         -font basic \
         -xscrollcommand "$Parent.textFrame.right.vertScrollbar set" \
         -yscrollcommand "$Parent.textFrame.left.horizScrollbar set" \
         -linemap 1 \
	 -linemap_markable 0
   setctexthighlight $Name
   easyCtextCommenting $Name
	} else {
   ctext $Name -background white  -borderwidth $bwidth -foreground black \
	-highlight 0 \
         -highlightbackground LightGray -insertbackground black \
         -selectbackground $hbgrd -selectforeground black \
         -wrap none \
         -font basic \
         -xscrollcommand "$Parent.textFrame.right.vertScrollbar set" \
         -yscrollcommand "$Parent.textFrame.left.horizScrollbar set" \
         -linemap 0 \
	 -linemap_markable 0
	}
   $Name fastinsert end { }
   pack $Name -anchor center -expand 1 -fill both -ipadx 0 -ipady 0 \
         -padx 0 -pady 0 -side top
   bind $Parent.textFrame.left.text <Any-ButtonRelease> \
{.ed_mainFrame.statusbar.l17 configure -text \
[.ed_mainFrame.mainwin.textFrame.left.text index insert]}
   bind $Parent.textFrame.left.text <Any-KeyRelease> \
{.ed_mainFrame.statusbar.l17 configure -text  \
[.ed_mainFrame.mainwin.textFrame.left.text index insert]}

   $Name delete 1.0 end
   $Name insert end $_ED(temppackage)
   ed_edit_commit
   update
}

proc ed_stop_button {} {
global _ED stop tcl_version
set Name .ed_mainFrame.buttons.test

set im [image create photo -data $stop -gamma 1 -height 16 -width 16 -palette 5/5/4]

$Name config -image $im -command "ed_kill_apps"
bind .ed_mainFrame.buttons.test <Enter> {ed_status_message -help \
		 "Stop running code"}   
}

proc ed_stop_vuser {} {
global _ED stop tcl_version
set Name .ed_mainFrame.buttons.lvuser
    set im [image create photo -data $stop -gamma 1 -height 16 -width 16 -palette 5/5/4]
$Name config -image $im -command "remote_command ed_kill_vusers; ed_kill_vusers" 
bind .ed_mainFrame.buttons.lvuser <Enter> {ed_status_message -help \
		 "Destroy Virtual Users"}   
}

proc ed_stop_transcount {} {
global _ED stop tcl_version
set Name .ed_mainFrame.buttons.pencil
    set im [image create photo -data $stop -gamma 1 -height 16 -width 16 -palette 5/5/4]
$Name config -image $im -command "ed_kill_transcount" 
bind .ed_mainFrame.buttons.pencil <Enter> {ed_status_message -help \
		 "Stop Transaction Counter"}   
}

proc ed_transcount_button {} {
global _ED pencil tcl_version
set Name .ed_mainFrame.buttons.pencil
set im [image create photo -data $pencil -gamma 1 -height 16 -width 16 -palette 5/5/4]
$Name config -image $im -command "transcount"
bind .ed_mainFrame.buttons.pencil <Enter> {ed_status_message -help \
		 "Transaction Counter"}
}

proc ed_metrics_button {} {
global _ED dashboard tcl_version
set Name .ed_mainFrame.buttons.dashboard
set im [image create photo -data $dashboard -gamma 1 -height 16 -width 16 -palette 5/5/4]
$Name config -image $im -command "metrics"
bind .ed_mainFrame.buttons.dashboard <Enter> {ed_status_message -help \
		 "Metrics"}
}

proc ed_test_button {} {
global _ED test tcl_version
set Name .ed_mainFrame.buttons.test

    set im [image create photo -data $test -gamma 1 -height 16 -width 16 -palette 5/5/4]

$Name config -image $im -command "ed_run_package"
bind .ed_mainFrame.buttons.test <Enter> {ed_status_message -help \
		 "Test current code"}
}

proc ed_lvuser_button {} {
global _ED lvuser tcl_version
set Name .ed_mainFrame.buttons.lvuser
set im [image create photo -data $lvuser -gamma 1 -height 16 -width 16 -palette 5/5/4]
$Name config -image $im -command "remote_command load_virtual; load_virtual"
bind .ed_mainFrame.buttons.lvuser <Enter> {ed_status_message -help \
		 "Create Virtual Users"}
}

proc ed_stop_autopilot {} {
global _ED stop tcl_version
set Name .ed_mainFrame.buttons.autopilot
    set im [image create photo -data $stop -gamma 1 -height 16 -width 16 -palette 5/5/4]
$Name config -image $im -command "ed_kill_autopilot" 
bind .ed_mainFrame.buttons.autopilot <Enter> {ed_status_message -help \
		 "Stop Autopilot"}   
}

proc ed_autopilot_button {} {
global _ED autopilot tcl_version
set Name .ed_mainFrame.buttons.autopilot
set im [image create photo -data $autopilot -gamma 1 -height 16 -width 16 -palette 5/5/4]
$Name config -image $im -command "start_autopilot"
bind .ed_mainFrame.buttons.autopilot <Enter> {ed_status_message -help \
		 "Start Autopilot"}
}

proc ed_stop_metrics {} {
global _ED stop tcl_version
set Name .ed_mainFrame.buttons.dashboard
    set im [image create photo -data $stop -gamma 1 -height 16 -width 16 -palette 5/5/4]
$Name config -image $im -command "ed_kill_metrics" 
bind .ed_mainFrame.buttons.dashboard <Enter> {ed_status_message -help \
		 "Stop Metrics"}   
}

proc ed_run_package {} {
global _ED maxvuser suppo ntimes
set maxvuser 1
set suppo 1
set ntimes 1
.ed_mainFrame.buttons.test configure -state disabled
    if {"$_ED(package)" == ""} {
        ed_status_message -alert "No code currently in run buffer."
        update
	set maxvuser $tmp_maxvuser 
	set suppo $tmp_suppo 
	set ntimes $tmp_ntimes 
	.ed_mainFrame.buttons.test configure -state normal
        return
    }
    ed_kill_apps
    ed_edit_commit
if { [catch {load_virtual} message]} {
puts "Failed to create virtaul user: $message"
        } else {
if { [catch {run_virtual} message]} {
puts "Failed to run TCL Code Test: $message"
        }
    }
return
}

proc ed_kill_apps {args} {
    global _ED ed_mainf 
    if {$_ED(runslave) == ""} {return}
   .ed_mainFrame configure -cursor watch
    ed_status_message -show "... closing down active GUI applications ..."
    update
    ed_wait_if_blocked
    set _ED(blockflag) 1
   catch "interp delete $_ED(runslave)"
   set _ED(blockflag) 0
   set _ED(runslave) ""
   .ed_mainFrame configure -cursor {}
   ed_status_message -perm
   ed_test_button
   update
}

proc vuser_options {} {
   global _ED
   global maxvuser
   global delayms
   global conpause
   global ntimes
   global suppo
   global optlog
   global lvuser
   global unique_log_name
   global no_log_buffer
   global threadscreated

if {  [ info exists maxvuser ] } { ; } else { set maxvuser 1 }
if {  [ info exists delayms ] } { ; } else { set delayms 500 }
if {  [ info exists conpause ] } { ; } else { set conpause 500 }
if {  [ info exists ntimes ] } { ; } else { set ntimes 1 }
if {  [ info exists suppo ] } { ; } else { set suppo 0 }
if {  [ info exists optlog ] } { ; } else { set optlog 0 }
if {  [ info exists unique_log_name ] } { ; } else { set unique_log_name 0 }
if {  [ info exists no_log_buffer ] } { ; } else { set no_log_buffer 0 }
#If window already exists then destroy
   catch "destroy .vuserop"
if { [ info exists threadscreated ] } { 
tk_messageBox -icon error -message "Virtual Users already created, destroy Virtual Users before changing Virtual User options"
return
	}
   ttk::toplevel .vuserop
   wm withdraw .vuserop
   wm title .vuserop {Virtual User Options}

   set Parent .vuserop

   set Name $Parent.f1
   ttk::frame $Name 
   pack $Name -anchor nw -fill x -side top -padx 5

set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $lvuser]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Virtual User Options"
grid $Prompt -column 1 -row 0 -sticky w

   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Virtual Users :"
   ttk::entry $Name -width 30 -textvariable maxvuser
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1

   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "User Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable conpause
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2

   set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "Repeat Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable delayms
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3

   set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "Iterations :"
   ttk::entry $Name -width 30 -textvariable ntimes
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4

   set Name $Parent.f1.e5
ttk::checkbutton $Name -text "Show Output" -variable suppo -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 5 -sticky w

bind .vuserop.f1.e5 <Button> { 
set opst [ .vuserop.f1.e5 cget -state ]
if {$suppo == 0} { 
.vuserop.f1.e6 configure -state active 
	} else {
set optlog 0
set unique_log_name 0
set no_log_buffer 0
.vuserop.f1.e6 configure -state disabled
.vuserop.f1.e7 configure -state disabled
.vuserop.f1.e8 configure -state disabled
			}
		}

   set Name $Parent.f1.e6
ttk::checkbutton $Name -text "Log Output to Temp" -variable optlog -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 6 -sticky w
	if {$suppo == 0} {
	$Name configure -state disabled
	}
bind .vuserop.f1.e6 <Button> { 
set opst [ .vuserop.f1.e6 cget -state ]
if {$opst != "disabled" && $optlog == 0} { 
.vuserop.f1.e7 configure -state active 
.vuserop.f1.e8 configure -state active
	} else {
set unique_log_name 0
set no_log_buffer 0
.vuserop.f1.e7 configure -state disabled
.vuserop.f1.e8 configure -state disabled
			}
		}

   set Name $Parent.f1.e7
ttk::checkbutton $Name -text "Use Unique Log Name" -variable unique_log_name -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 7 -sticky w
	if {$optlog == 0} {
	$Name configure -state disabled
	}

   set Name $Parent.f1.e8
ttk::checkbutton $Name -text "No Log Buffer" -variable no_log_buffer -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 8 -sticky w
	if {$optlog == 0} {
	$Name configure -state disabled
	}

   bind .vuserop.f1.e1 <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }

   set Name $Parent.b2
   ttk::button $Name -text Cancel -command {destroy .vuserop} 
   pack $Name -anchor nw -side right -padx 3 -pady 3

   set Name $Parent.b1
   ttk::button $Name \
         -command {
         set maxvuser [.vuserop.f1.e1 get]
if { ![string is integer -strict $maxvuser] } { 
	tk_messageBox -message "The number of virtual users must be an integer" 
	set maxvuser 1
	}
if { $maxvuser < 1 } { tk_messageBox -message "The number of virtual users must be 1 or greater" 
	set maxvuser 1
	}
         set conpause [.vuserop.f1.e2 get]
if { ![string is integer -strict $conpause] } { 
	tk_messageBox -message "Delay between users logons must be an integer" 
	set conpause 0
	}
if { $conpause < 0 } { tk_messageBox -message "Delay between users logons must be at least 0 milliseconds" 
	set conpause 0
	}
         set delayms  [.vuserop.f1.e3 get]
if { ![string is integer -strict $delayms] } { 
	tk_messageBox -message "Delay between iterations must be an integer" 
	set delayms 0
	}
if { $delayms < 0 } { tk_messageBox -message "Delay between iterations must be at least 0 milliseconds" 
	set delayms 0
	}
         set ntimes   [.vuserop.f1.e4 get]
if { ![string is integer -strict $ntimes] } { 
	tk_messageBox -message "The number of iterations must be an integer" 
	set ntimes 1
	}
if { $ntimes < 1 } { tk_messageBox -message "The number of iterations must be 1 or greater" 
	set ntimes 1
	}
	 remote_command [ concat vuser_slave_ops $maxvuser $delayms $conpause $ntimes $suppo $optlog ]
         destroy .vuserop
            } \
         -text OK
   pack $Name -anchor nw -side right -padx 3 -pady 3

   wm geometry .vuserop +50+50
   wm deiconify .vuserop
   raise .vuserop
   update
}

proc countopts {} {
global rdbms
global pencil
if {  [ info exists rdbms ] } { ; } else { set rdbms "Oracle" }
switch $rdbms {
Oracle {
countoraopts
}
MySQL {
countmyopts
}
PostgreSQL {
countpgopts
}
MSSQLServer {
countmssqlopts
}
DB2 {
countdb2opts
}
Redis {
countredisopts
}
Trafodion {
counttrafopts
}
default {
countoraopts
        }
    }
}

proc countoraopts {} {
   global _ED connectstr interval afval autor pencil tpcc_tt_compat tpch_tt_compat bm

if {  ![ info exists tpcc_tt_compat ] } { set tpcc_tt_compat "false" }
if {  ![ info exists tpch_tt_compat ] } { set tpch_tt_compat "false" }
if {  [ info exists bm ] } { ; } else { set bm "TPC-C" }
if { $bm eq "TPC-C" } { set bm_for_count "tpcc_tt_compat" } else { set bm_for_count "tpch_tt_compat" }

if { [ info exists afval ] } {
	after cancel $afval
	unset afval
}
if {  [ info exists connectstr ] } { ; } else { 
set connectstr "system/manager@oracle" }
if {  [ info exists interval ] } { ; } else { set interval 10 }
if {  [ info exists autor ] } { ; } else { set autor 1 }

   catch "destroy .countopt"
   ttk::toplevel .countopt
   wm withdraw .countopt
   wm title .countopt {Oracle TX Counter Options}

   set Parent .countopt

   set Name $Parent.f1
   ttk::frame $Name 
   pack $Name -anchor nw -fill x -side top -padx 5

set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $pencil]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Transaction Counter Options"
grid $Prompt -column 1 -row 0 -sticky w

   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Connect String :"
   ttk::entry $Name -width 30 -textvariable connectstr
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1

   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Refresh Rate(secs) :"
   ttk::entry $Name -width 30 -textvariable interval
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2

   set Name $Parent.f1.e3
ttk::checkbutton $Name -text "TimesTen Database Compatible" -variable $bm_for_count -onvalue "true" -offvalue "false"
   grid $Name -column 1 -row 3 -sticky w
bind .countopt.f1.e3 <Any-ButtonRelease> {
if { $bm eq "TPC-C" && $tpcc_tt_compat eq "false" || $bm eq "TPC-H" && $tpch_tt_compat eq "false" } {
set rac 0
.countopt.f1.e4 configure -state disabled
		} else {
.countopt.f1.e4 configure -state normal
		}
	}

   set Name $Parent.f1.e4
ttk::checkbutton $Name -text "RAC Global Transactions" -variable rac -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 4 -sticky w
if { $bm eq "TPC-C" && $tpcc_tt_compat eq "true" || $bm eq "TPC-H" && $tpch_tt_compat eq "true" } {
	$Name configure -state disabled
	}

set Name $Parent.f1.e5
ttk::checkbutton $Name -text "Autorange Data Points" -variable autor -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 5 -sticky w

   bind .countopt.f1.e1 <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }

 set Name $Parent.b2
 ttk::button $Name  -command {destroy .countopt} -text Cancel
 pack $Name -anchor nw -side right -padx 3 -pady 3

 set Name $Parent.b1
   ttk::button $Name -command {
         set connectstr [.countopt.f1.e1 get]
         set interval [.countopt.f1.e2 get]
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs" 
	set interval 10 }
         destroy .countopt
	   catch "destroy .tc"
            } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3

   wm geometry .countopt +50+50
   wm deiconify .countopt
   raise .countopt
   update
}

proc countmyopts {} {
global _ED interval afval autor mysql_host mysql_port mysql_user mysql_pass pencil

if { [ info exists afval ] } {
	after cancel $afval
	unset afval
}
if {  ![ info exists mysql_host ] } { set mysql_host "127.0.0.1" }
if {  ![ info exists mysql_port ] } { set mysql_port "3306" }
if {  ![ info exists mysql_user ] } { set mysql_user "root" }
if {  ![ info exists mysql_pass ] } { set mysql_pass "mysql" }

   catch "destroy .countopt"
   ttk::toplevel .countopt
   wm withdraw .countopt
   wm title .countopt {MySQL TX Counter Options}
   set Parent .countopt
   set Name $Parent.f1
   ttk::frame $Name 
   pack $Name -anchor nw -fill x -side top -padx 5
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $pencil]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Transaction Counter Options"
grid $Prompt -column 1 -row 0 -sticky w
set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "MySQL Host :"
   ttk::entry $Name -width 30 -textvariable mysql_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "MySQL Port :"   
   ttk::entry $Name  -width 30 -textvariable mysql_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "MySQL User :"
   ttk::entry $Name  -width 30 -textvariable mysql_user
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "MySQL User Password :"   
   ttk::entry $Name  -width 30 -textvariable mysql_pass
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
   set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "Refresh Rate(secs) :"
   ttk::entry $Name -width 30 -textvariable interval
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
set Name $Parent.f1.e6
ttk::checkbutton $Name -text "Autorange Data Points" -variable autor -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 6 -sticky w

   bind .countopt.f1.e1 <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }

 set Name $Parent.b2
 ttk::button $Name  -command {destroy .countopt} -text Cancel
 pack $Name -anchor nw -side right -padx 3 -pady 3

 set Name $Parent.b1
   ttk::button $Name -command {
         set mysql_host [.countopt.f1.e1 get]
         set mysql_port [.countopt.f1.e2 get]
         set mysql_user [.countopt.f1.e3 get]
         set mysql_pass [.countopt.f1.e4 get]
         set interval   [.countopt.f1.e5 get]
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs" 
	set interval 10 }
         destroy .countopt
	   catch "destroy .tc"
            } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3

   wm geometry .countopt +50+50
   wm deiconify .countopt
   raise .countopt
   update
}

proc countmssqlopts {} { 
global _ED interval afval autor pencil mssqls_server mssqls_port mssqls_authentication mssqls_odbc_driver mssqls_uid mssqls_pass

if { [ info exists afval ] } {
	after cancel $afval
	unset afval
}
if {  ![ info exists mssqls_server ] } { set mssqls_server "(local)" }
if {  ![ info exists mssqls_port ] } { set mssqls_port "1433" }
if {  ![ info exists mssqls_authentication ] } { set mssqls_authentication "wind
ows" }
if {  ![ info exists mssqls_odbc_driver ] } { set mssqls_odbc_driver "SQL Server
 Native Client 10.0" }
if {  ![ info exists mssqls_uid ] } { set mssqls_uid "sa" }
if {  ![ info exists mssqls_pass ] } { set mssqls_pass "admin" }

   catch "destroy .countopt"
   ttk::toplevel .countopt
   wm withdraw .countopt
   wm title .countopt {SQL Server TX Counter Options}
   set Parent .countopt
   set Name $Parent.f1
   ttk::frame $Name 
   pack $Name -anchor nw -fill x -side top -padx 5
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $pencil]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Transaction Counter Options"
grid $Prompt -column 1 -row 0 -sticky w
set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "SQL Server :"
   ttk::entry $Name -width 30 -textvariable mssqls_server
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "SQL Server Port :"   
   ttk::entry $Name  -width 30 -textvariable mssqls_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
   set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "SQL Server ODBC Driver :"   
   ttk::entry $Name  -width 30 -textvariable mssqls_odbc_driver
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Prompt $Parent.f1.pa
ttk::label $Prompt -text "Authentication :"
grid $Prompt -column 0 -row 4 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "windows" -text "Windows Authentication" -variable mssqls_authentication
grid $Name -column 1 -row 4 -sticky w
bind .countopt.f1.r1 <ButtonPress-1> {
.countopt.f1.e4 configure -state disabled
.countopt.f1.e5 configure -state disabled
}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "sql" -text "SQL Server Authentication" -variable mssqls_authentication
grid $Name -column 1 -row 5 -sticky w
bind .countopt.f1.r2 <ButtonPress-1> {
.countopt.f1.e4 configure -state normal
.countopt.f1.e5 configure -state normal
}
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "SQL Server User ID :"
   ttk::entry $Name  -width 30 -textvariable mssqls_uid
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
if {$mssqls_authentication == "windows" } {
        $Name configure -state disabled
        }
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "SQL Server User Password :"   
   ttk::entry $Name  -width 30 -textvariable mssqls_pass
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
if {$mssqls_authentication == "windows" } {
        $Name configure -state disabled
        }
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "Refresh Rate(secs) :"
   ttk::entry $Name -width 30 -textvariable interval
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky ew
set Name $Parent.f1.e7
ttk::checkbutton $Name -text "Autorange Data Points" -variable autor -onvalue 1 -offvalue 0 
   grid $Name -column 1 -row 9 -sticky w

   bind .countopt.f1.e1 <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }

 set Name $Parent.b2
 ttk::button $Name  -command {destroy .countopt} -text Cancel
 pack $Name -anchor nw -side right -padx 3 -pady 3

 set Name $Parent.b1
   ttk::button $Name -command {
   	 set mssqls_server [.countopt.f1.e1 get]
         set mssqls_port [.countopt.f1.e2 get]
	 set mssqls_odbc_driver [.countopt.f1.e3 get]
	 set mssqls_uid [.countopt.f1.e4 get]
   	 set mssqls_pass [.countopt.f1.e5 get]
         set interval [.countopt.f1.e6 get]
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs" 
	set interval 10 }
         destroy .countopt
	   catch "destroy .tc"
            } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3

   wm geometry .countopt +50+50
   wm deiconify .countopt
   raise .countopt
   update
}

proc countdb2opts {} {
global _ED interval afval autor db2_user db2_pass db2_dbase pencil
if { [ info exists afval ] } {
	after cancel $afval
	unset afval
}
if {  ![ info exists db2_user ] } { set db2_user "db2inst1" }
if {  ![ info exists db2_pass ] } { set db2_pass "ibmdb2" }
if {  ![ info exists db2_dbase ] } { set db2_dbase "tpcc" }
   catch "destroy .countopt"
   ttk::toplevel .countopt
   wm withdraw .countopt
   wm title .countopt {DB2 TX Counter Options}
   set Parent .countopt
   set Name $Parent.f1
   ttk::frame $Name 
   pack $Name -anchor nw -fill x -side top -padx 5
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $pencil]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Transaction Counter Options"
grid $Prompt -column 1 -row 0 -sticky w
set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "DB2 User :"
   ttk::entry $Name -width 30 -textvariable db2_user
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "DB2 User Password :"   
   ttk::entry $Name  -width 30 -textvariable db2_pass
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "DB2 Database :"
   ttk::entry $Name  -width 30 -textvariable db2_dbase
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
   set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "Refresh Rate(secs) :"
   ttk::entry $Name -width 30 -textvariable interval
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
ttk::checkbutton $Name -text "Autorange Data Points" -variable autor -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 5 -sticky w

   bind .countopt.f1.e1 <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }

 set Name $Parent.b2
 ttk::button $Name  -command {destroy .countopt} -text Cancel
 pack $Name -anchor nw -side right -padx 3 -pady 3

 set Name $Parent.b1
   ttk::button $Name -command {
         set db2_user [.countopt.f1.e1 get]
         set db2_pass [.countopt.f1.e2 get]
         set db2_dbase [.countopt.f1.e3 get]
         set interval   [.countopt.f1.e4 get]
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs" 
	set interval 10 }
         destroy .countopt
	   catch "destroy .tc"
            } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3

   wm geometry .countopt +50+50
   wm deiconify .countopt
   raise .countopt
   update
}

proc countpgopts {} { 
global _ED interval afval autor pg_host pg_port pg_superuser pg_superuserpass pg_defaultdbase pg_oracompat pencil

if { [ info exists afval ] } {
	after cancel $afval
	unset afval
}

if {  ![ info exists pg_host ] } { set pg_host "localhost" }
if {  ![ info exists pg_port ] } { set pg_port "5432" }
if {  ![ info exists pg_superuser ] } { set pg_superuser "postgres" }
if {  ![ info exists pg_superuserpass ] } { set pg_superuserpass "postgres" }
if {  ![ info exists pg_defaultdbase ] } { set pg_defaultdbase "postgres" }
if {  ![ info exists pg_oracompat ] } { set pg_oracompat "false" }
if { $pg_oracompat eq "true" } {
if { $pg_port eq "5432" } { set pg_port "5444" }
if { $pg_superuser eq "postgres" } { set pg_superuser "enterprisedb" }
if { $pg_defaultdbase eq "postgres" } { set pg_defaultdbase "edb" }
	} else {
if { $pg_port eq "5444" } { set pg_port "5432" }
if { $pg_superuser eq "enterprisedb" } { set pg_superuser "postgres" }
if { $pg_defaultdbase eq "edb" } { set pg_defaultdbase "postgres" }
	}

   catch "destroy .countopt"
   ttk::toplevel .countopt
   wm withdraw .countopt
   wm title .countopt {PostgreSQL TX Counter Options}
   set Parent .countopt
   set Name $Parent.f1
   ttk::frame $Name 
   pack $Name -anchor nw -fill x -side top -padx 5
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $pencil]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Transaction Counter Options"
grid $Prompt -column 1 -row 0 -sticky w
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "PostgreSQL Host :"
   ttk::entry $Name -width 30 -textvariable pg_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "PostgreSQL Port :"   
   ttk::entry $Name  -width 30 -textvariable pg_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "PostgreSQL Superuser :"
   ttk::entry $Name  -width 30 -textvariable pg_superuser
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "PostgreSQL Superuser Password :"   
   ttk::entry $Name  -width 30 -textvariable pg_superuserpass
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "PostgreSQL Default Database :"
   ttk::entry $Name -width 30 -textvariable pg_defaultdbase
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "Refresh Rate(secs) :"
   ttk::entry $Name -width 30 -textvariable interval
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Name $Parent.f1.e7
ttk::checkbutton $Name -text "Autorange Data Points" -variable autor -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 7 -sticky w

   bind .countopt.f1.e1 <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }

 set Name $Parent.b2
 ttk::button $Name  -command {destroy .countopt} -text Cancel
 pack $Name -anchor nw -side right -padx 3 -pady 3

 set Name $Parent.b1
   ttk::button $Name -command {
         set pg_host [.countopt.f1.e1 get]
         set pg_port [.countopt.f1.e2 get]
	 set pg_superuser [.countopt.f1.e3 get]
	 set pg_superuserpass [.countopt.f1.e4 get]
   	 set pg_defaultdbase [.countopt.f1.e5 get]
         set interval   [.countopt.f1.e6 get]
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs" 
	set interval 10 }
         destroy .countopt
	   catch "destroy .tc"
            } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3

   wm geometry .countopt +50+50
   wm deiconify .countopt
   raise .countopt
   update
}

proc countredisopts {} {
global _ED interval afval autor redis_host redis_port pencil

if { [ info exists afval ] } {
	after cancel $afval
	unset afval
}

if {  ![ info exists redis_host ] } { set redis_host "127.0.0.1" }
if {  ![ info exists redis_port ] } { set redis_port "6379" }

   catch "destroy .countopt"
   ttk::toplevel .countopt
   wm withdraw .countopt
   wm title .countopt {Redis TX Counter Options}
   set Parent .countopt
   set Name $Parent.f1
   ttk::frame $Name 
   pack $Name -anchor nw -fill x -side top -padx 5
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $pencil]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Transaction Counter Options"
grid $Prompt -column 1 -row 0 -sticky w
set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Redis Host :"
   ttk::entry $Name -width 30 -textvariable redis_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Redis Port :"   
   ttk::entry $Name  -width 30 -textvariable redis_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
   set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "Refresh Rate(secs) :"
   ttk::entry $Name -width 30 -textvariable interval
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
ttk::checkbutton $Name -text "Autorange Data Points" -variable autor -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 4 -sticky w

   bind .countopt.f1.e1 <Delete> {
      if [%W selection present] {
         %W delete sel.first sel.last
      } else {
         %W delete insert
      }
   }

 set Name $Parent.b2
 ttk::button $Name  -command {destroy .countopt} -text Cancel
 pack $Name -anchor nw -side right -padx 3 -pady 3

 set Name $Parent.b1
   ttk::button $Name -command {
         set redis_host [.countopt.f1.e1 get]
         set redis_port [.countopt.f1.e2 get]
         set interval   [.countopt.f1.e3 get]
if { ($interval >= 60) || ($interval <= 0)  } { tk_messageBox -message "Refresh rate must be more than 0 secs and less than 60 secs" 
	set interval 10 }
         destroy .countopt
	   catch "destroy .tc"
            } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3

   wm geometry .countopt +50+50
   wm deiconify .countopt
   raise .countopt
   update
}

proc counttrafopts {} {
tk_messageBox -title "No Statistics" -message "Trafodion does not have transaction statistics that can be queried at the current release"
}

proc about { } {
global hdb_version
tk_messageBox -title About -message "HammerDB $hdb_version
Copyright (C) 2003-2015
Steve Shaw\n" 
}

proc license { } {
tk_messageBox -title License -message "
Copyright (C) 2003-2015
Steve Shaw
This program is free software; 
you can redistribute it and/or modify it under the terms of the GNU General Public License 
as published by the Free Software Foundation; either version 2 of the License, 
or (at your option) any later version.\n
This copyright notice must be included in all distributions.\n
This program is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
or FITNESS FOR A PARTICULAR PURPOSE. 
See the GNU General Public License for more details."
}

proc ed_status_message {option {message ""}} {
    global _ED inrun opmode
if { [ info exists inrun ] } {
;
} else {
    set _ED(status) "$_ED(packagekeyname)"
    set _ED(permstatus) "$_ED(packagekeyname)"
    .ed_mainFrame.statusbar.l15 configure -text "  Mode: $opmode"
    .ed_mainFrame.statusbar.l14 configure -text "  File: $_ED(packagekeyname)"
    switch -glob -- $option {
        -setperm {
            set _ED(permstatus) "$message"
            set _ED(status) "$message"
        }
        -temp {
            set _ED(status) "$message"
            if {$_ED(permstatus) != ""} {
                after 1000 "set _ED(status) [list $_ED(permstatus)]"
            }
        }
        -show {
            set _ED(status) "$message"
   }
    -help {
       set _ED(status) "$message"
         }      
   -perm {
            set _ED(status) "$_ED(permstatus)"
        }
        -alert {
            set _ED(status) "$message"
            catch "$_ED(status_widget) configure -foreground red"
            update
            after 2000 
            catch "$_ED(status_widget) configure -foreground black"
            if {$_ED(permstatus) != ""} {
                set _ED(status) "$_ED(permstatus)"
            }
            update
        }
        -run {
            set _ED(status) "$message"
            catch "$_ED(status_widget) configure -foreground green"
            update
            set inrun 1
        }
        -finish {
            set _ED(status) "$message"
            catch "$_ED(status_widget) configure -foreground black"
        }
        default {ed_status_message -temp "$message"}
    }
 }
}

proc ed_wait_if_blocked {} {
    global _ED
   set _ED(blockflag) 0
   return
    set i 0
    while {$_ED(blockflag)} {
        incr i
        if {$i > 20} {
            set _ED(blockflag) 0
            return
        }
        after 500
    }
}

proc ed_error {message} {
      tk_messageBox -icon warning -message $message
}

if {[info exists tcl_version] == 0 || $tcl_version < 7.5} {
    error "Error -- Tcl Editor:  This program requires Tcl 8.4 or higher"
}

if {[info exists tk_version] == 0 || $tk_version < 4.1} {
    error "Error -- Tcl Editor:  This program requires Tk 4.1 or higher"
}

    foreach globalvar [info globals *ED*] {
        catch "unset $globalvar" dummy
    }
    foreach globalvar [info globals *ed*] {
        catch "unset $globalvar" dummy
    }
    set _ED(menuCount) 0;
    set _ED(pwd) [pwd]
    set _ED(editcursor) ""
    set _ED(editcurold) ""
    set _ED(srch_old) ""
    set _ED(srch_new) ""
    set _ED(file) ""
    set _ED(runslave) ""
    set _ED(package) ""
    set _ED(temppackage) ""
    set _ED(packagekeyname) ""
    set _ED(status) "$_ED(file)"
    set _ED(permstatus) "$_ED(file)"
    set _ED(blockflag) 0

   if {$tcl_platform(platform) == "windows"} {
      set _ED(courierfont) {{Courier New} 11 {normal}}
   } else {
      set _ED(courierfont) "-*-Helvetica-Medium-R-Normal--12-*-*-*-*-*-*-*"
   }

   catch "destroy .ed_mainFrame"

proc choose_font { { choose_init "Arial 10"} } {
  set w .choose_font
    global dxf
    set tmp [get_actual_font $choose_init]

    window.font $choose_init

    catch {.choose_font.view delete 0.0 end}
    catch {.choose_font.view insert 0.0 "[get_cur_font]"}

    grab $w
    focus -force $w    
    wm deiconify $w
    tkwait window $w
    grab release $w

    return  $dxf(tmp)
     
}

proc window.font { {init_font "Arial 10"} } {
    global dxf
    set dxf(tmp) ""
    catch {destroy .choose_font}
    set w .choose_font
    ttk::toplevel $w
    wm withdraw $w
    wm protocol $w WM_DELETE_WINDOW "set dxf(tmp) \"\"; destroy $w"
    catch {wm transient $w .appearance}
    wm title $w "Choose Font:"
    

    ttk::label $w.l1 -text "Choose Font:"


    combobox $w.cb_name "lsort \[font families\]" font_view_update dxf(choose_font_cb_name) 20
    bind $w.cb_name.e <Return> "font_view_update"

    combobox $w.cb_size  "lsort \[list 8 9 10 11 12 14 16 18 20 22 24 26 28 36 48 72\]" font_view_update dxf(choose_font_cb_size) 3
    bind $w.cb_size.e <Return> "font_view_update"
    ttk::checkbutton $w.c_bold -text "B" -onvalue bold -offvalue "" \
    	-command "font_view_update" -variable dxf(choose_font_c_bold)   
    ttk::checkbutton $w.c_italic -text "I" -onvalue italic -offvalue "" \
    	-command "font_view_update" -variable dxf(choose_font_c_italic)     
    ttk::checkbutton $w.c_underline -text "U" -onvalue underline -offvalue "" \
    	-command "font_view_update" -variable dxf(choose_font_c_underline)

    ttk::label $w.l2 -text "Preview:"
    text $w.view  -font "[get_cur_font]" -width 20 -height 1 -highlightthickness 0 -bd 0

    ttk::frame $w.f
    ttk::button $w.f.cancel -text "Cancel" -command "set dxf(tmp) \"\"; destroy $w"	
    ttk::button $w.f.ok -text "Ok" -command "set dxf(tmp) \"\[get_cur_font\]\"; destroy $w"	
    ttk::label $w.f.lab -text " "

   grid $w.l1 -row 0 -pady 10 -columnspan 5 -sticky we
   grid $w.cb_name $w.cb_size $w.c_bold $w.c_italic $w.c_underline -row 1 -padx 5 -sticky w
   grid $w.l2 -row 2 -columnspan 5 -sticky we -pady 5
   grid $w.view -row 3 -columnspan 5 -sticky we -pady 5
   grid $w.f -row 4 -columnspan 5 -sticky we -pady 5 -padx 5 
   grid $w.f.lab -column 3 -row 5 -padx 3 -ipadx 80 -sticky w
   grid $w.f.ok -column 4 -row 5 -padx 3 -sticky e
   grid $w.f.cancel -column 5 -row 5 -padx 3 -sticky e

   wm geometry $w +150+150
}


proc font_view_update { {font {}} } {
  global dxf

  set cur_font [get_cur_font]
  .choose_font.view delete 0.0 end
  .choose_font.view insert 0.0 "$cur_font"
  .choose_font.view configure -font "$cur_font" 
}

proc get_actual_font { font } {
  global dxf
  set dxf(choose_font_cb_name) "" 
  set dxf(choose_font_cb_size) ""
  set dxf(choose_font_c_bold) ""
  set dxf(choose_font_c_italic) ""
  set dxf(choose_font_c_underline) ""
  set new_font ""
  set lfont_opt [font actual $font]
  for { set i 1 } { $i < 10 } { incr i 2 } {
  	set opt_val [string trim [lindex $lfont_opt $i]]
  	if {$i == 1 } { set dxf(choose_font_cb_name) $opt_val }
  	if {$i == 3 } { set dxf(choose_font_cb_size) $opt_val }
  	if { $i == 5 } {
  		if { $opt_val == "normal" } { 
  			set opt_val ""
  	     	     } else {
			set dxf(choose_font_c_bold) $opt_val
  	           }
  	   }
  	   
   	if { $i == 7 } {
   		if { $opt_val == "roman" }  { 
   			set opt_val ""
   	     	     } else {
			set dxf(choose_font_c_italic) $opt_val
   	     	    }
   	   }
   	if { $i == 9 } {
   		if { $opt_val == "0" }  { 
   			set opt_val "" 
   		    } else { 
   		       set opt_val "underline" 
			set dxf(choose_font_c_underline) $opt_val
   		   }
           }

	if { [llength [split $opt_val " "]] <= 1 } {
 		append new_font " $opt_val"
	     } else {
 		append new_font " \{$opt_val\}"
	   }

      }
  return [string trim $new_font]

}

proc get_cur_font { } {
  global dxf
  set cur_font "" 
  foreach el [list $dxf(choose_font_cb_name) $dxf(choose_font_cb_size) \
  	$dxf(choose_font_c_bold) $dxf(choose_font_c_italic) $dxf(choose_font_c_underline)] {
	if { $el != "" } {
		set trim_el [string trim $el]
		if { [llength [split $trim_el " "]] <= 1 } {
			append cur_font " $trim_el"
		    } else {
			append cur_font " \{$trim_el\}"
		   }
	    }
    }
 
  return [string trim $cur_font]
}


proc incr_font { object incr_val } {
  set font [lindex [$object configure -font] 4]
  set size [lindex $font 1]
  if { $size != "" && [regexp {^[0-9]+$} $size]  && [regexp {^[+-]?[0-9]+$} $incr_val]} { 
  	set font [lreplace $font 1 1 [incr size $incr_val]]
     }
  return $font
}

proc combobox {window {listproc {}} {cmdproc {}} {cb_textvar c_var} {cb_width 15} args} {
    global tcl_platform tkPriv
    set tkPriv(relief) raised
    set result [frame $window -relief sunken -bd 0 -highlightthickness 0]
    rename $window _$window
    if {$result != {}} {
	if {[info comm down_bm] == {}} {
	    set down_bm {
		#define dwnarrow.icn_width 15
                #define dwnarrow.icn_height 15
		static unsigned char dwnarrow.icn_bits[] = {
		    0x00, 0x00, 0x00, 0x00, 0xe0, 0x07, 0xe0, 0x07, 0xe0, 0x07, 0xe0, 0x07,0xe0, 0x07, 0xfc, 0x3f, 0xf8, 0x1f, 0xf0, 0x0f, 0xe0, 0x07, 0xc0, 0x03,0x80, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
	    }
	    image create bitmap down_bm -data [set down_bm]
	    unset down_bm
	}
	
	ttk::entry ${window}.e -textvariable $cb_textvar -width $cb_width
        ttk::label ${window}.b -image down_bm
	bind ${window}.b <1> "combobox_drop ${window} [list $listproc];%W config -relief sunken"
	bind ${window}.b <ButtonRelease-1> "%W config -relief raised"

	ttk::toplevel ${window}_f

	
	wm overrideredirect ${window}_f 1
	wm transient ${window}_f

	
	wm withdraw ${window}_f

	listbox ${window}_f.lb -width $cb_width -yscrollc "${window}_f.sb set"
	ttk::scrollbar ${window}_f.sb -command "${window}_f.lb yview"
	
	grid ${window}.e -row 0 -column 0 -sticky {nsew}
	grid ${window}.b -row 0 -column 1 -sticky {e}
	grid columnconfig ${window} 0 -weight 5


	pack ${window}_f.lb -side left -fill both
	pack ${window}_f.sb -side left -fill y

	bind ${window}.e  <Insert> {
	    catch {tkEntryInsert %W [selection get -displayof %W]}
	    break
	}
	bind ${window}.e <Delete> {
	    if [%W selection present] {
		%W delete sel.first sel.last
	    } else {
		%W delete insert
	    }
	    break
	}
	bind ${window}_f.lb <Insert> {break}
	bind ${window}_f.lb <Delete> {break}

	set tagname [winfo name $window]_cbox
	foreach q "${window}_f ${window}_f.lb ${window}_f.sb" {
	    bindtags $q [concat ${tagname} [bindtags $q]]
	}

	bind ${window}_f.lb <Motion> "
	    set tkPriv(y) %y
	    tkListboxMotion %W \[%W index @%x,%y]
            combobox_export ${window}_f.lb ${window}.e
	"

	bind ${window}_f.lb <Leave> "
	    set tkPriv(x) %x
	    set tkPriv(y) %y
	    combobox_autoscan ${window}.e %W
            combobox_export ${window}_f.lb ${window}.e
	"
	bind ${window}_f.lb <Enter> {
	    tkCancelRepeat
	}
	
	bind $tagname <FocusIn> {}
	bind $tagname <Enter> {
	}
	bind $tagname <Leave> {
	}
	bind $tagname <Motion> {
	}
	bind $tagname <ButtonPress>  {
	    foreach q {rootx rooty width height} {
		set $q [winfo $q %W]
	    }
	    if {(%X < $rootx) || (%X > ($rootx+$width)) || (%Y < $rooty) || (($rooty+$height) < %Y)} {
		    combobox_release %W
	    }
	}
	bind $tagname <ButtonRelease> "
	    ${window}.b config -relief raised
	"
	bind $tagname <space> {
	    combobox_release %W
	}
	bind $tagname <Return> {
	    combobox_release %W
	}
	bind $tagname <Escape> {
	    combobox_release %W
	}
	bind $tagname <Up> "
	    tkListboxUpDown %W -1
	    combobox_export ${window}_f.lb ${window}.e
            break
	"
	bind $tagname <Down> "
	    tkListboxUpDown %W 1
	    combobox_export ${window}_f.lb ${window}.e
            break
	"
	bind $tagname <KeyPress> {
	    combobox_release %W
	}

	proc combobox_export {l e} {
	    if {[set idx [$l curselection ]] != ""} {
		$e delete 0 end
		$e insert 0 [$l get $idx]
	    }
	}

	proc combobox_autoscan {e w} {
	    global tkPriv
	    if {![winfo exists $w]} return
	    set x $tkPriv(x)
	    set y $tkPriv(y)
	    if {$y >= [winfo height $w]} {
		$w yview scroll 1 units
	    } elseif {$y < 0} {
		$w yview scroll -1 units
	    } elseif {$x >= [winfo width $w]} {
		$w xview scroll 2 units
	    } elseif {$x < 0} {
		$w xview scroll -2 units
	    } else {
		return
	    }
	    tkListboxMotion $w [$w index @$x,$y]
	    combobox_export $w $e
	    set tkPriv(afterId) [after 50 combobox_autoscan $e $w]
	}

	proc combobox_release {w} {
	    grab release $w
	    wm withdraw [winfo toplevel $w]
	}

	proc _${window}_ {args} "
	    eval \"combobox_command $window \$args\"
	"

	bind ${window}.e <Return> "break"

	proc combobox_command {window cmd args} {
	    if {$cmd == "append"} {
		eval "${window}_f.lb insert end $args"
	    } elseif {$cmd == "get"} {
		${window}.e get
	    } elseif {$cmd == "ecommand"} {
		bind ${window}.e <Return> "eval [concat $args];break"
	    } else {
		eval "${window}.e $cmd $args"
	    }
	}

	interp alias {} $window {} _${window}_
	
	proc combobox_drop {w listproc} {
	    if {[winfo ismapped ${w}_f]} {
		grab release ${w}_f
		wm withdraw ${w}_f
	    } else {
		if {$listproc != ""} {
		    ${w}_f.lb delete 0 end
		    foreach q [eval $listproc] {
			${w}_f.lb insert end $q
		    }
		}

    update idletasks
    set W [expr {[winfo width ${w}.e]+[winfo width ${w}.b]}]
    set H [winfo reqheight ${w}_f]
    set y [expr {[winfo rooty ${w}.e]+[winfo height ${w}.e]}]
    if {($y+$H)>[winfo screenheight $w]} {
	set y [expr {[winfo rooty ${w}.e]-$H}]
    }
    set x [winfo rootx ${w}.e]

    wm geometry ${w}_f ${W}x${H}+${x}+${y}
    update idletasks
		wm deiconify ${w}_f
		raise ${w}_f
		focus ${w}_f.lb
		update 
		grab -global ${w}_f
	    }
	}

	proc combobox_double {cmdproc window y} {
	    grab release ${window}_f
	    ${window}.e delete 0 end
	    ${window}.e insert 0 [${window}_f.lb get [${window}_f.lb nearest $y]]
	    focus ${window}.e
	    combobox_release ${window}_f
	    if {"$cmdproc" != {}} {
		eval $cmdproc $window
	    }
	}
	bind ${window}_f.lb <Double-1> "combobox_double [list $cmdproc] [list $window] %y"
	bind ${window}_f.lb <1> "combobox_double [list $cmdproc] [list $window] %y"
	bind ${window}_f.lb <ButtonRelease-1> "combobox_double [list $cmdproc] [list $window] %y"

	proc combobox_return {cmdproc window} {
	    combobox_export ${window}_f.lb ${window}.e
	    focus ${window}.e
	    combobox_release ${window}_f
	    if {"$cmdproc" != {}} {
		eval $cmdproc $window
	    }
	}
	bind ${window}_f.lb <Return> "combobox_return [list $cmdproc] [list $window]"

	bind ${window}.e <Down> "combobox_drop ${window} [list $listproc]"
	bind ${window} <Escape> "
	    focus ${window}.e
	    wm withdraw ${window}_f
            break
	"
	bind ${window}_f.lb <Escape> "
	    focus ${window}.e
	    wm withdraw ${window}_f
            break
	"
	bind ${window} <Destroy> "
            if \{\[winfo exists ${window}_f\]\} \{
                destroy ${window}_f
            \}
        "
	bind ${window}.e <Escape> "
            if \{\[place info ${window}_f\] != \{\}\} \{
                focus ${window}.e;
                wm withdraw ${window}_f
            \}
        "
	bind ${window} <Configure> "
            if \{\[winfo ismapped ${window}_f\]\} \{
                combobox_drop ${window} [list $listproc]
            \}
        "
	if {$listproc != ""} {
	    ${window}_f.lb delete 0 end
	    foreach q [eval $listproc] {
		${window}_f.lb insert end $q
	    }
	}

	if {$args != ""} {
	    foreach q $args {
		${window}_f.lb insert end $q
	    }
	}
    bind ${window}_f.lb <Configure> \
	    "combobox_config ${window}_f.lb ${window}_f.sb"
    }
}

proc combobox_config {listbox scrollbar} {
    set items [$listbox index end]
    set size [$listbox cget -height]
    if {$items <= $size} {
    	pack forget $scrollbar
    	$listbox configure -height $items
    } else {
	pack $scrollbar -side right -fill y
    }
}

proc remspace {sqltext} {
    regsub -all {[\ ]+} $sqltext " " spaced
    return $spaced
}

proc autopilot_options {} {
global opmode apmode apduration apsequence autopilot suppo optlog unique_log_name no_log_buffer
if {  [ info exists apmode ] } { ; } else { set apmode "disabled" }
if {  [ info exists apduration ] } { ; } else { set apduration 10 }
if {  [ info exists apsequence ] } { ; } else { set apsequence "2 3 5 9 13 17 21 25" }
if {  [ info exists suppo ] } { ; } else { set suppo 0 }
if {  [ info exists optlog ] } { ; } else { set optlog 0 }
if {  [ info exists unique_log_name ] } { ; } else { set unique_log_name 0 }
if {  [ info exists no_log_buffer ] } { ; } else { set no_log_buffer 0 }
   catch "destroy .apopt"
   ttk::toplevel .apopt
   wm withdraw .apopt
   wm title .apopt {Autopilot Options}
   set Parent .apopt
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5 
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $autopilot]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Autopilot Options"
grid $Prompt -column 1 -row 0 -sticky w
   set Name $Parent.f1.b1
ttk::radiobutton $Name -text "Autopilot Disabled" -variable apmode -value "disabled" 
grid $Name -column 0 -row 2 -sticky e                                    
bind $Parent.f1.b1 <Button> {
set suppo 0
set optlog 0
set unique_log_name 0
set no_log_buffer 0
.apopt.f1.e1 configure -state disabled 
.apopt.f1.e2 configure -state disabled 
.apopt.f1.e3 configure -state disabled
.apopt.f1.e4 configure -state disabled
.apopt.f1.e5 configure -state disabled
.apopt.f1.e6 configure -state disabled
                }
   set Name $Parent.f1.b2
ttk::radiobutton $Name -text "Autopilot Enabled" -variable apmode -value "enabled" 
grid $Name -column 0 -row 3 -sticky e                                          
bind $Parent.f1.b2 <Button> {
set suppo 1
.apopt.f1.e1 configure -state enabled 
.apopt.f1.e2 configure -state enabled
.apopt.f1.e3 configure -state enabled
.apopt.f1.e4 configure -state enabled
                }
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Minutes per Test in Virtual User Sequence :"
   ttk::entry $Name -width 30 -textvariable apduration
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5
if {$apmode != "enabled" } {
        $Name configure -state disabled
        }
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Virtual User Sequence (Space Separated Values) :"
   ttk::entry $Name -width 30 -textvariable apsequence
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7
if {$apmode != "enabled" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e3
ttk::checkbutton $Name -text "Show Virtual User Output" -variable suppo -onvalue 1 -offvalue 0
if {$apmode != "enabled" } {
	$Name configure -state disabled
	set suppo 0
	set optlog 0
	}
   grid $Name -column 1 -row 8 -sticky w

bind $Name <Button> { 
set opst [ .apopt.f1.e3 cget -state ]
if {$suppo == 0 && $apmode == "enabled" } { 
.apopt.f1.e4 configure -state active 
} else {
set optlog 0
set unique_log_name 0
set no_log_buffer 0
.apopt.f1.e4 configure -state disabled
.apopt.f1.e5 configure -state disabled
.apopt.f1.e6 configure -state disabled
			}
		}

   set Name $Parent.f1.e4
ttk::checkbutton $Name -text "Log Virtual User Output to Temp" -variable optlog -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 9 -sticky w
	if {$suppo == 0 || $apmode != "enabled" } {
	set unique_log_name 0
	set no_log_buffer 0
	$Name configure -state disabled
	}

bind .apopt.f1.e4 <Button> { 
set opst [ .apopt.f1.e4 cget -state ]
if {$optlog == 0 && $opst != "disabled"} { 
.apopt.f1.e5 configure -state active 
.apopt.f1.e6 configure -state active 
	} else {
set unique_log_name 0
set no_log_buffer 0
.apopt.f1.e5 configure -state disabled
.apopt.f1.e6 configure -state disabled
			}
		}

 set Name $Parent.f1.e5
ttk::checkbutton $Name -text "Use Unique Log Name" -variable unique_log_name -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 10 -sticky w
	if {$optlog == 0 || $apmode !=  "enabled" || $suppo == 0} {
	set unique_log_name 0
	.apopt.f1.e5 configure -state disabled
	}

 set Name $Parent.f1.e6
ttk::checkbutton $Name -text "No Log Buffer" -variable no_log_buffer -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 11 -sticky w
	if {$optlog == 0 || $apmode !=  "enabled" || $suppo == 0} {
	set no_log_buffer 0
	.apopt.f1.e6 configure -state disabled
	}

   set Name $Parent.b3
   ttk::button $Name -command {destroy .apopt} -text Cancel
   pack $Name -anchor w -side right -padx 3 -pady 3
   set Name $Parent.b4
   ttk::button $Name -command {
         set apduration [.apopt.f1.e1 get]
if { ![string is integer -strict $apduration] } { 
	tk_messageBox -message "The minutes for test duration must be an integer" 
	set apduration 10
	} elseif { $apduration > 600 } {
	tk_messageBox -message "The minutes for test duration must be less than 600" 
	set apduration 10
	}
	set apsequence [.apopt.f1.e2 get]
if { [ llength $apsequence ] > 60 || [ llength $apsequence ] eq 0 } {
	tk_messageBox -message "The virtual user sequence must contain between 1 and 60 integer values" 
set apsequence [ lreplace $apsequence 60 end ]
	}
foreach i "$apsequence" { 
if { ![string is integer -strict $i] } { 
	tk_messageBox -message "The virtual user sequence must contain one or more integers only" 
	set apsequence "2 3 5 9 13 17 21 25 29"
	break
	}
}
if { $apmode eq "enabled" } {
.ed_mainFrame.buttons.autopilot configure -state enabled
} else {
.ed_mainFrame.buttons.autopilot configure -state disabled
	}
	 remote_command [ concat auto_ops $suppo $optlog ]
	 catch "destroy .apopt"
           } -text {OK}     
   pack $Name -anchor w -side right -padx 3 -pady 3
   wm geometry .apopt +50+50
   wm deiconify .apopt
   raise .apopt
   update
}

proc metricsopts {} {
global agent_hostname agent_id
if {  [ info exists agent_hostname ] } { ; } else { set agent_hostname "localhost" }
if {  [ info exists agent_id ] } { ; } else { set agent_id 0 }
set old_agent $agent_hostname
set old_id $agent_id
   catch "destroy .metric"
   ttk::toplevel .metric
   wm withdraw .metric
   wm title .metric {Connect to Agent Options}
   set Parent .metric
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5                              
                                             
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Agent ID and Hostname"
grid $Prompt -column 1 -row 0 -sticky w

   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Agent ID :"
   ttk::entry $Name -width 30 -textvariable agent_id
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Agent Hostname :"
   ttk::entry $Name -width 30 -textvariable agent_hostname
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5
   set Name $Parent.b4
   ttk::button $Name -command { destroy .metric } -text Cancel
   pack $Name -anchor w -side right -padx 3 -pady 3
   set Name $Parent.b5
   ttk::button $Name -command {
         set agent_id [.metric.f1.e1 get]
         set agent_hostname [.metric.f1.e2 get]
	 catch "destroy .metric"
if { ![string is integer -strict $agent_id] } { 
tk_messageBox -message "Agent id must be an integer" 
set agent_id 0
	  } 
        } -text {OK}     
   pack $Name -anchor w -side right -padx 3 -pady 3
   wm geometry .metric +50+50
   wm deiconify .metric
   raise .metric
   update
}

proc select_mode {} {
global opmode hostname id masterlist apmode mode
upvar 1 oldmode oldmode
if {  [ info exists hostname ] } { ; } else { set hostname "localhost" }
if {  [ info exists id ] } { ; } else { set id 0 }
if {  [ info exists apmode ] } { ; } else { set apmode "disabled" }
   set oldmode $opmode
   catch "destroy .mode"
   ttk::toplevel .mode
   wm withdraw .mode
   wm title .mode {Mode Options}
   set Parent .mode
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5                                                                           
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $mode]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Mode Options"
grid $Prompt -column 1 -row 0 -sticky w

   set Name $Parent.f1.b1
ttk::radiobutton $Name -text "Local Mode" -variable opmode -value "Local" 
grid $Name -column 0 -row 1 -sticky w                                    
bind $Parent.f1.b1 <Button> {
.mode.f1.e1 configure -state disabled 
.mode.f1.e2 configure -state disabled 
                }
   set Name $Parent.f1.b2
ttk::radiobutton $Name -text "Master Mode" -variable opmode -value "Master" 
grid $Name -column 0 -row 2 -sticky w                                          
bind $Parent.f1.b2 <Button> {
.mode.f1.e1 configure -state disabled 
.mode.f1.e2 configure -state disabled 
                }
   set Name $Parent.f1.b3
ttk::radiobutton $Name -text "Slave Mode" -variable opmode -value "Slave"
grid $Name -column 0 -row 3 -sticky w
bind $Parent.f1.b3 <Button> {
.mode.f1.e1 configure -state normal 
.mode.f1.e2 configure -state normal 
                }
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Master ID :"
   ttk::entry $Name -width 30 -textvariable id
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4
if {$opmode != "Slave" } {
        $Name configure -state disabled
        }
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Master Hostname :"
   ttk::entry $Name -width 30 -textvariable hostname
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5
if {$opmode != "Slave" } {
        $Name configure -state disabled
        }
   set Name $Parent.b4
   ttk::button $Name -command {destroy .mode} -text Cancel
   pack $Name -anchor w -side right -padx 3 -pady 3
   set Name $Parent.b5
   ttk::button $Name -command {
         set id [.mode.f1.e1 get]
         set hostname [.mode.f1.e2 get]
	 catch "destroy .mode"
       if { $oldmode eq $opmode } { tk_messageBox -title "Confirm Mode" -message "Already in $opmode mode" } else { if {[ tk_messageBox -icon question -title "Confirm Mode" -message "Switch from $oldmode\nto $opmode mode?" -type yesno ] == yes} { set opmode [ switch_mode $opmode $hostname $id $masterlist ] }  else { set opmode $oldmode } } 
        } -text {OK}     
   pack $Name -anchor w -side right -padx 3 -pady 3
   wm geometry .mode +50+50
   wm deiconify .mode
   raise .mode
   update
}

proc select_rdbms { preselect } {
global rdbms bm benchmark tcl_platform
upvar 1 oldrdbms oldrdbms
upvar 1 oldbm oldbm
if {  [ info exists rdbms ] } { ; } else { set rdbms "Oracle" }
if {  [ info exists bm ] } { ; } else { set bm "TPC-C" }
   set oldrdbms $rdbms
   set oldbm $bm
	switch $preselect {
	"Oracle" { set rdbms Oracle }
	"MSSQLServer" { 
	if {$tcl_platform(platform) != "windows" } { 
		  set rdbms $oldrdbms 
		} else {
		  set rdbms MSSQLServer 
		} 
	     }
	"DB2" { set rdbms DB2 }
	"MySQL" { set rdbms MySQL }
	"PostgreSQL" { set rdbms PostgreSQL }
	"Redis" { set rdbms Redis }
	"Trafodion" { set rdbms Trafodion }
	default { ; }
	}
   catch "destroy .rdbms"
   ttk::toplevel .rdbms
   wm withdraw .rdbms
   wm title .rdbms {Benchmark Options}
   set Parent .rdbms
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5                                                                            
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $benchmark]
grid $Prompt -column 1 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Benchmark Options"
grid $Prompt -column 2 -row 0 -sticky w

   set Name $Parent.f1.b1
ttk::radiobutton $Name -text "Oracle" -variable rdbms -value "Oracle" -command { if { $oldrdbms != $rdbms } { set rdbms "Oracle" }
.rdbms.f1.b4 configure -state enabled
}
 grid $Name -column 1 -row 1 -sticky w                                                                              
   set Name $Parent.f1.b2
ttk::radiobutton $Name -text "MySQL" -variable rdbms -value "MySQL" -command { if { $oldrdbms != $rdbms } { set rdbms "MySQL" } 
.rdbms.f1.b4 configure -state enabled
}
 grid $Name -column 1 -row 4 -sticky w 

   set Name $Parent.f1.b2a
ttk::radiobutton $Name -text "MSSQL Server" -variable rdbms -value "MSSQLServer" -command { if { $oldrdbms != $rdbms } { set rdbms "MSSQLServer" } 
.rdbms.f1.b4 configure -state enabled
}
 grid $Name -column 1 -row 2 -sticky w 

   set Name $Parent.f1.b2e
ttk::radiobutton $Name -text "DB2" -variable rdbms -value "DB2" -command { if { $oldrdbms != $rdbms } { set rdbms "DB2" } 
.rdbms.f1.b4 configure -state disabled
set bm "TPC-C"
}
 grid $Name -column 1 -row 3 -sticky w 

   set Name $Parent.f1.b2b
ttk::radiobutton $Name -text "PostgreSQL" -variable rdbms -value "PostgreSQL" -command { if { $oldrdbms != $rdbms } { set rdbms "PostgreSQL" } 
.rdbms.f1.b4 configure -state enabled
}
 grid $Name -column 1 -row 5 -sticky w 
   set Name $Parent.f1.b2c
ttk::radiobutton $Name -text "Redis" -variable rdbms -value "Redis" -command { if { $oldrdbms != $rdbms } { set rdbms "Redis" } 
.rdbms.f1.b4 configure -state disabled
set bm "TPC-C"
}
 grid $Name -column 1 -row 6 -sticky w 
   set Name $Parent.f1.b2d
ttk::radiobutton $Name -text "Trafodion" -variable rdbms -value "Trafodion" -command { if { $oldrdbms != $rdbms } { set rdbms "Trafodion" } 
.rdbms.f1.b4 configure -state disabled
set bm "TPC-C"
}
 grid $Name -column 1 -row 7 -sticky w 

   set Name $Parent.f1.b3
ttk::radiobutton $Name -text "TPC-C" -variable bm -value "TPC-C" -command { if { $oldbm != $bm } { set bm "TPC-C" } 
}
 grid $Name -column 2 -row 1 -sticky w                                                                               
   set Name $Parent.f1.b4 
ttk::radiobutton $Name -text "TPC-H" -variable bm -value "TPC-H" -command { if { $oldbm != $bm } { set bm "TPC-H" } 
}
 grid $Name -column 2 -row 2 -sticky w
 if { $rdbms eq "Redis" || $rdbms eq "Trafodion" || $rdbms eq "DB2" } { $Name configure -state disabled ; set bm "TPC-C" }
   set Name $Parent.f1.ok
   ttk::button $Name -command { 
catch "destroy .rdbms"
if { $oldbm eq $bm && $oldrdbms eq $rdbms } { 
tk_messageBox -title "Confirm Benchmark" -message "No Change Made : $bm for $rdbms" 
} else {
if { $rdbms eq "Trafodion" } {
.ed_mainFrame.buttons.pencil configure -state disabled 
	} else {
.ed_mainFrame.buttons.pencil configure -state normal 
	}
set oldbm $bm
set oldrdbms $rdbms
disable_bm_menu
tk_messageBox -title "Confirm Benchmark" -message "$bm for $rdbms" 
remote_command [ concat vuser_bench_ops $rdbms $bm ]
remote_command disable_bm_menu
	}
} -text OK
   grid $Parent.f1.ok -column 2 -row 8 -padx 3 -pady 3 -sticky w
  
   set Name $Parent.f1.cancel
   ttk::button $Name -command {
catch "destroy .rdbms"
set bm $oldbm
set rdbms $oldrdbms
} -text Cancel
   grid $Parent.f1.cancel -column 3 -row 8 -padx 3 -pady 3 -sticky w
   if {$tcl_platform(platform) != "windows" } { 
       .rdbms.f1.b2a configure -state disabled	
      }
   wm geometry .rdbms +50+50
   wm deiconify .rdbms
   raise .rdbms
   update
}

proc check_which_bm {} {
global _ED bm rdbms threadscreated
if {  [ info exists bm ] } { ; } else { set bm "TPC-C" }
if {  [ info exists rdbms ] } { ; } else { set rdbms "Oracle" }
#Clear the Script Editor first to make sure a genuine schema build is run
ed_edit_clear
if { [ info exists threadscreated ] } {
tk_messageBox -icon error -message "Cannot build schema with Virtual Users active, destroy Virtual Users first"
#clear script editor so cannot be re-run with incorrect v user count
return 1
        }
switch $rdbms {
Oracle {
if { $bm == "TPC-C" } { check_oratpcc } else { check_oratpch }
}
MSSQLServer {
if { $bm == "TPC-C" } { check_mssqltpcc } else { check_mssqltpch }
}
DB2 {
 	check_db2tpcc 
}
MySQL {
if { $bm == "TPC-C" } { check_mytpcc } else { check_mytpch }
}
PostgreSQL {
if { $bm == "TPC-C" } { check_pgtpcc } else { check_pgtpch }
}
Redis {
 	check_redistpcc 
}
Trafodion {
 	check_traftpcc 
}
default {
if { $bm == "TPC-C" } { check_oratpcc } else { check_oratpch }
	}
    }
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
applyctexthighlight .ed_mainFrame.mainwin.textFrame.left.text
.ed_mainFrame.notebook select .ed_mainFrame.tw
#Commit to update values in script editor
ed_edit_commit
if { [ string length $_ED(package)] eq 1 } {
#No was pressed at schema creation and editor is empty do not run
return
	} else {
#Yes was pressed at schema creation run
run_virtual
	}
}

proc configtpcc { option } {
global rdbms
if {  [ info exists rdbms ] } { ; } else { set rdbms "Oracle" }
switch $rdbms {
Oracle {
configoratpcc $option
	}
MSSQLServer {
configmssqlstpcc $option
	}
DB2 {
configdb2tpcc $option
	}
MySQL {
configmytpcc $option
	}
PostgreSQL {
configpgtpcc $option
	}
Redis {
configredistpcc $option
	}
Trafodion {
configtraftpcc $option
	}
default {
configoratpcc $option
	}
    }	
}

proc configtpch { option } {
global rdbms
if {  [ info exists rdbms ] } { ; } else { set rdbms "Oracle" }
switch $rdbms {
Oracle {
configoratpch $option
	}
MySQL {
configmytpch $option
	}
MSSQLServer {
configmssqlstpch $option
	}
PostgreSQL {
configpgtpch $option
	}
default {
configoratpch $option
		}
	}
}

proc configoratpcc {option} {
global instance system_user system_password count_ware tpcc_user tpcc_pass tpcc_def_tab tpcc_ol_tab tpcc_def_temp count_ware plsql directory partition tpcc_tt_compat num_threads boxes driveroptlo total_iterations raiseerror keyandthink oradriver checkpoint rampup duration defaultBackground defaultForeground
if {  ![ info exists system_user ] } { set system_user "system" }
if {  ![ info exists system_password ] } { set system_password "manager" }
if {  ![ info exists instance ] } { set instance "oracle" }
if {  ![ info exists count_ware ] } { set count_ware "1" }
if {  ![ info exists tpcc_user ] } { set tpcc_user "tpcc" }
if {  ![ info exists tpcc_pass ] } { set tpcc_pass "tpcc" }
if {  ![ info exists tpcc_def_tab ] } { set tpcc_def_tab "tpcctab" }
if {  ![ info exists tpcc_ol_tab ] } { set tpcc_ol_tab $tpcc_def_tab }
if {  ![ info exists tpcc_def_temp ] } { set tpcc_def_temp "temp" }
if {  ![ info exists plsql ] } { set plsql 0 }
if {  ![ info exists directory ] } { set directory [ findtempdir ] }
if {  ![ info exists partition ] } { set partition "false" }
if {  ![ info exists tpcc_tt_compat ] } { set tpcc_tt_compat "false" }
if {  ![ info exists num_threads ] } { set num_threads 1 }
if {  ![ info exists total_iterations ] } { set total_iterations 1000000 }
if {  ![ info exists raiseerror ] } { set raiseerror "false" }
if {  ![ info exists keyandthink ] } { set keyandthink "false" }
if {  ![ info exists checkpoint ] } { set checkpoint "false" }
if {  ![ info exists oradriver ] } { set oradriver "standard" }
if {  ![ info exists rampup ] } { set rampup "2" }
if {  ![ info exists duration ] } { set duration "5" }
global _ED
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {Oracle TPC-C Schema Options} }
"build" { wm title .tpc {Oracle TPC-C Build Options} }
"drive" {  wm title .tpc {Oracle TPC-C Driver Options} }
	}
   set Parent .tpc
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5  
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $boxes]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Oracle Service Name :"
   ttk::entry $Name -width 30 -textvariable instance
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "System User :"   
   ttk::entry $Name  -width 30 -textvariable system_user
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
   set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "System User Password :"   
   ttk::entry $Name  -width 30 -textvariable system_password
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "TPC-C User :"
   ttk::entry $Name  -width 30 -textvariable tpcc_user
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "TPC-C User Password :"   
   ttk::entry $Name  -width 30 -textvariable tpcc_pass
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "TPC-C Default Tablespace :"
   ttk::entry $Name -width 30 -textvariable tpcc_def_tab
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Name $Parent.f1.e6a
   set Prompt $Parent.f1.p6a
   ttk::label $Prompt -text "Order Line Tablespace :"
   ttk::entry $Name -width 30 -textvariable tpcc_ol_tab
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7
   ttk::label $Prompt -text "TPC-C Temporary Tablespace :"    
   ttk::entry $Name -width 30 -textvariable tpcc_def_temp
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky ew
	}
   set Prompt $Parent.f1.p8
ttk::label $Prompt -text "TimesTen Database Compatible :"
   set Name $Parent.f1.e8
ttk::checkbutton $Name -text "" -variable tpcc_tt_compat -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 9 -sticky e
   grid $Name -column 1 -row 9 -sticky w
if { $tpcc_tt_compat eq "false" } {
foreach field {e2 e3 e6 e7} {
catch {.tpc.f1.$field configure -state normal}
if { $partition eq "true" } {
catch {.tpc.f1.6a configure -state normal}
		}
	}
   } else {
set plsql 0
foreach field {e2 e3 e6 e6a e7} {
catch {.tpc.f1.$field configure -state disabled}
	}
	}
bind .tpc.f1.e8 <ButtonPress-1> {
if { $tpcc_tt_compat eq "true" } {
foreach field {e2 e3 e6 e7} {
catch {.tpc.f1.$field configure -state normal}
	}
if { $partition eq "true" } {
catch {.tpc.f1.e6a configure -state normal}
	}
if {$count_ware < 200 } {
catch {.tpc.f1.e9 configure -state disabled}
catch {.tpc.f1.6a configure -state disabled}
set partition "false"
	}
if {$num_threads eq 1 } {
catch {.tpc.f1.e12 configure -state normal}
	}
	} else {
set plsql 0
foreach field {e2 e3 e6 e6a e7 e12 e13} {
catch {.tpc.f1.$field configure -state disabled}
   	}
catch {.tpc.f1.e9 configure -state normal}
	}
}
if { $option eq "all" || $option eq "build" } {
 set Prompt $Parent.f1.p9
ttk::label $Prompt -text "Partition Order Line Table :"
  set Name $Parent.f1.e9
ttk::checkbutton $Name -text "" -variable partition -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
if {$count_ware < 200 && $tpcc_tt_compat eq "false" } {
	set partition false
	$Name configure -state disabled
	.tpc.f1.e6a configure -state disabled
	}
if { $partition eq "false" } {
	.tpc.f1.e6a configure -state disabled
	}
bind .tpc.f1.e9 <Any-ButtonRelease> {
if { $partition eq "true" && $plsql eq "false" } {
set plsql 0
.tpc.f1.e13 configure -state disabled
.tpc.f1.e12 configure -state disabled
			} else {
if { $partition eq "false" && $count_ware >= 200 } {
set plsql 0
.tpc.f1.e13 configure -state disabled
.tpc.f1.e12 configure -state disabled
			}
	}
if { $partition eq "true" && $num_threads eq 1 && $tpcc_tt_compat eq "false" } {
.tpc.f1.e12 configure -state normal
		} 
if { $partition eq "true" && $tpcc_tt_compat eq "false" } {
.tpc.f1.e6a configure -state disabled
			} else {
if { $partition eq "false" && $count_ware >= 200 && $tpcc_tt_compat eq "false" } {
.tpc.f1.e6a configure -state normal
			}
			}
	}
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e10
	scale $Name -orient horizontal -variable count_ware -from 1 -to 5000 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground 
bind .tpc.f1.e10 <Any-ButtonRelease> {
if {$num_threads > $count_ware} {
set num_threads $count_ware
if { $num_threads eq 1 && $tpcc_tt_compat eq "false" } {
.tpc.f1.e12 configure -state normal
} else {
.tpc.f1.e13 configure -state disabled
.tpc.f1.e12 configure -state disabled
set plsql 0
		}
	}
if {$count_ware < 200 && $tpcc_tt_compat eq "false" } {
.tpc.f1.e9 configure -state disabled
.tpc.f1.e6a configure -state disabled
set partition "false"
	} else {
.tpc.f1.e9 configure -state enabled
	}
}
	grid $Prompt -column 0 -row 11 -sticky e
	grid $Name -column 1 -row 11 -sticky ew
set Prompt $Parent.f1.p11
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e11
	scale $Name -orient horizontal -variable num_threads -from 1 -to 256 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground 
bind .tpc.f1.e11 <Any-ButtonRelease> {
if {$num_threads > $count_ware} {
set num_threads $count_ware
		}
if {$num_threads eq 1 && $partition eq "false" && $tpcc_tt_compat eq "false"} {
.tpc.f1.e12 configure -state normal
} else {
.tpc.f1.e13 configure -state disabled
.tpc.f1.e12 configure -state disabled
set plsql 0
	}
}
	grid $Prompt -column 0 -row 12 -sticky e
	grid $Name -column 1 -row 12 -sticky ew
set Prompt $Parent.f1.p12
ttk::label $Prompt -text "Use PL/SQL Server Side Load :"
set Name $Parent.f1.e12
ttk::checkbutton $Name -text "" -variable plsql -onvalue 1 -offvalue 0
   grid $Prompt -column 0 -row 13 -sticky e
   grid $Name -column 1 -row 13 -sticky w
if { $num_threads eq 1 && $tpcc_tt_compat eq "false" } { 
.tpc.f1.e12 configure -state normal } else { .tpc.f1.e12 configure -state disabled }
bind .tpc.f1.e12 <Any-ButtonRelease> {
if {$num_threads eq 1 && $plsql eq 0 && $tpcc_tt_compat eq "false" && $partition eq "false" } { 
.tpc.f1.e13 configure -state normal 
set partition "false"
} else {.tpc.f1.e13 configure -state disabled
                        }
                }
   set Name $Parent.f1.e13
   set Prompt $Parent.f1.p13
   ttk::label $Prompt -text "Server Side Log Directory :"
   ttk::entry $Name -width 30 -textvariable directory
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky ew
if {$plsql == 0} {
	$Name configure -state disabled
	}
}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 15 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 15 -sticky w
	}
set Prompt $Parent.f1.p15
ttk::label $Prompt -text "TPC-C Driver Script :"
grid $Prompt -column 0 -row 16 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "standard" -text "Standard Driver Script" -variable oradriver
grid $Name -column 1 -row 16 -sticky w
bind .tpc.f1.r1 <ButtonPress-1> {
set checkpoint "false"
.tpc.f1.e20 configure -state disabled
.tpc.f1.e21 configure -state disabled
.tpc.f1.e22 configure -state disabled
}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "awr" -text "AWR Snapshot Driver Script" -variable oradriver
grid $Name -column 1 -row 17 -sticky w
bind .tpc.f1.r2 <ButtonPress-1> {
.tpc.f1.e20 configure -state normal
.tpc.f1.e21 configure -state normal
.tpc.f1.e22 configure -state normal
}
set Name $Parent.f1.e17
   set Prompt $Parent.f1.p17
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable total_iterations
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky ew
 set Prompt $Parent.f1.p18
ttk::label $Prompt -text "Exit on Oracle Error :"
  set Name $Parent.f1.e18
ttk::checkbutton $Name -text "" -variable raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky w
 set Prompt $Parent.f1.p19
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.e19
ttk::checkbutton $Name -text "" -variable keyandthink -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky w
 set Prompt $Parent.f1.p20
ttk::label $Prompt -text "Checkpoint when complete :"
  set Name $Parent.f1.e20
ttk::checkbutton $Name -text "" -variable checkpoint -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21 -sticky w
if {$oradriver == "standard" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e21
   set Prompt $Parent.f1.p21
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable rampup
   grid $Prompt -column 0 -row 22 -sticky e
   grid $Name -column 1 -row 22 -sticky ew
if {$oradriver == "standard" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e22
   set Prompt $Parent.f1.p22
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable duration
   grid $Prompt -column 0 -row 23 -sticky e
   grid $Name -column 1 -row 23 -sticky ew
if {$oradriver == "standard" } {
	$Name configure -state disabled
	}
}
set Name $Parent.b2
   ttk::button $Name -command {destroy .tpc} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
set Name $Parent.b1
   ttk::button $Name -command {
          set instance [.tpc.f1.e1 get]
          set system_user [.tpc.f1.e2 get]
          set system_password [.tpc.f1.e3 get]
	  set tpcc_user [.tpc.f1.e4 get]
	  set tpcc_pass [.tpc.f1.e5 get]
if { $option eq "all" || $option eq "build" } {
   	  set tpcc_def_tab [.tpc.f1.e6 get]
   	  set tpcc_ol_tab [.tpc.f1.e6a get]
	  set tpcc_def_temp [.tpc.f1.e7 get]
	}
if { $option eq "all" || $option eq "drive" } {
	  set total_iterations [ .tpc.f1.e17 get]
	  set rampup [ .tpc.f1.e21 get]
	  set duration [ .tpc.f1.e22 get]
	}
         destroy .tpc 
        } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3
   
   wm geometry .tpc +50+50
   wm deiconify .tpc
   raise .tpc
   update
}

proc configmytpcc {option} {
global mysql_host mysql_port my_count_ware mysql_user mysql_pass mysql_dbase storage_engine mysql_partition mysql_num_threads my_total_iterations my_raiseerror my_keyandthink boxes driveroptlo mysqldriver my_rampup my_duration storage_engine defaultBackground defaultForeground

if {  ![ info exists mysql_host ] } { set mysql_host "127.0.0.1" }
if {  ![ info exists mysql_port ] } { set mysql_port "3306" }
if {  ![ info exists my_count_ware ] } { set my_count_ware "1" }
if {  ![ info exists mysql_user ] } { set mysql_user "root" }
if {  ![ info exists mysql_pass ] } { set mysql_pass "mysql" }
if {  ![ info exists mysql_dbase ] } { set mysql_dbase "tpcc" }
if {  ![ info exists storage_engine ] } { set storage_engine "innodb" }
if {  ![ info exists mysql_partition ] } { set mysql_partition "false" }
if {  ![ info exists mysql_num_threads ] } { set mysql_num_threads "1" }
if {  ![ info exists my_total_iterations ] } { set my_total_iterations 1000000 }
if {  ![ info exists my_raiseerror ] } { set my_raiseerror "false" }
if {  ![ info exists my_keyandthink ] } { set my_keyandthink "false" }
if {  ![ info exists mysqldriver ] } { set mysqldriver "standard" }
if {  ![ info exists my_rampup ] } { set my_rampup "2" }
if {  ![ info exists my_duration ] } { set my_duration "5" }
global _ED
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {MySQL TPC-C Schema Options} }
"build" { wm title .tpc {MySQL TPC-C Build Options} }
"drive" {  wm title .tpc {MySQL TPC-C Driver Options} }
	}
   set Parent .tpc
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $boxes]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "MySQL Host :"
   ttk::entry $Name -width 30 -textvariable mysql_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "MySQL Port :"   
   ttk::entry $Name  -width 30 -textvariable mysql_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "MySQL User :"
   ttk::entry $Name  -width 30 -textvariable mysql_user
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "MySQL User Password :"   
   ttk::entry $Name  -width 30 -textvariable mysql_pass
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "MySQL Database :"
   ttk::entry $Name -width 30 -textvariable mysql_dbase
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "Transactional Storage Engine :"
   ttk::entry $Name -width 30 -textvariable storage_engine
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Prompt $Parent.f1.p8
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e8
	scale $Name -orient horizontal -variable my_count_ware -from 1 -to 5000 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
bind .tpc.f1.e8 <Any-ButtonRelease> {
if {$mysql_num_threads > $my_count_ware} {
set mysql_num_threads $my_count_ware
		}
if {$my_count_ware < 200} {
.tpc.f1.e10 configure -state disabled
set mysql_partition "false"
        } else {
.tpc.f1.e10 configure -state enabled
        }
}
	grid $Prompt -column 0 -row 8 -sticky e
	grid $Name -column 1 -row 8 -sticky ew
set Prompt $Parent.f1.p9
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e9
        scale $Name -orient horizontal -variable mysql_num_threads -from 1 -to 256 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
bind .tpc.f1.e9 <Any-ButtonRelease> {
if {$mysql_num_threads > $my_count_ware} {
set mysql_num_threads $my_count_ware
                }
        }
grid $Prompt -column 0 -row 9 -sticky e
grid $Name -column 1 -row 9 -sticky ew
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Partition Order Line Table :"
set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable mysql_partition -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
if {$my_count_ware <= 200 } {
        $Name configure -state disabled
        }
}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 11 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 11 -sticky w
	}
set Prompt $Parent.f1.p12
ttk::label $Prompt -text "TPC-C Driver Script :"
grid $Prompt -column 0 -row 12 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "standard" -text "Standard Driver Script" -variable mysqldriver
grid $Name -column 1 -row 12 -sticky w
bind .tpc.f1.r1 <ButtonPress-1> {
.tpc.f1.e17 configure -state disabled
.tpc.f1.e18 configure -state disabled
}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "timed" -text "Timed Test Driver Script" -variable mysqldriver
grid $Name -column 1 -row 13 -sticky w
bind .tpc.f1.r2 <ButtonPress-1> {
.tpc.f1.e17 configure -state normal
.tpc.f1.e18 configure -state normal
}
set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable my_total_iterations
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky ew
 set Prompt $Parent.f1.p15
ttk::label $Prompt -text "Exit on MySQL Error :"
  set Name $Parent.f1.e15
ttk::checkbutton $Name -text "" -variable my_raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky w
 set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable my_keyandthink -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16 -sticky w
set Name $Parent.f1.e17
   set Prompt $Parent.f1.p17
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable my_rampup
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17 -sticky ew
if {$mysqldriver == "standard" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e18
   set Prompt $Parent.f1.p18
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable my_duration
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky ew
if {$mysqldriver == "standard" } {
	$Name configure -state disabled
	}
}
set Name $Parent.b2
   ttk::button $Name -command {destroy .tpc} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
set Name $Parent.b1
   ttk::button $Name -command {
         set mysql_host [.tpc.f1.e1 get]
         set mysql_port [.tpc.f1.e2 get]
	 set mysql_user [.tpc.f1.e3 get]
	 set mysql_pass [.tpc.f1.e4 get]
   	 set mysql_dbase [.tpc.f1.e5 get]
if { $option eq "all" || $option eq "build" } {
   	 set storage_engine [.tpc.f1.e6 get]
 }
if { $option eq "all" || $option eq "drive" } {
	 set my_total_iterations [ .tpc.f1.e14 get]
	 set my_rampup [ .tpc.f1.e17 get]
	 set my_duration [ .tpc.f1.e18 get]
 }
         destroy .tpc 
        } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3   
   wm geometry .tpc +50+50
   wm deiconify .tpc
   raise .tpc
   update
}

proc configmssqlstpcc {option} {
global mssqls_server mssqls_port mssqls_authentication mssqls_odbc_driver mssqls_count_ware mssqls_schema mssqls_num_threads mssqls_uid mssqls_pass mssqls_dbase mssqls_total_iterations mssqls_raiseerror mssqls_keyandthink mssqlsdriver mssqls_rampup mssqls_duration mssqls_checkpoint boxes driveroptlo defaultBackground defaultForeground
if {  ![ info exists mssqls_server ] } { set mssqls_server "(local)" }
if {  ![ info exists mssqls_port ] } { set mssqls_port "1433" }
if {  ![ info exists mssqls_count_ware ] } { set mssqls_count_ware "1" }
if {  ![ info exists mssqls_authentication ] } { set mssqls_authentication "windows" }
if {  ![ info exists mssqls_odbc_driver ] } { set mssqls_odbc_driver "SQL Server Native Client 10.0" }
if {  ![ info exists mssqls_uid ] } { set mssqls_uid "sa" }
if {  ![ info exists mssqls_pass ] } { set mssqls_pass "admin" }
if {  ![ info exists mssqls_dbase ] } { set mssqls_dbase "tpcc" }
if {  ![ info exists mssqls_schema ] } { set mssqls_schema "updated" }
if {  ![ info exists mssqls_num_threads ] } { set mssqls_num_threads "1" }
if {  ![ info exists mssqls_total_iterations ] } { set mssqls_total_iterations 1000000 }
if {  ![ info exists mssqls_raiseerror ] } { set mssqls_raiseerror "false" }
if {  ![ info exists mssqls_keyandthink ] } { set mssqls_keyandthink "false" }
if {  ![ info exists mssqlsdriver ] } { set mssqlsdriver "standard" }
if {  ![ info exists mssqls_rampup ] } { set mssqls_rampup "2" }
if {  ![ info exists mssqls_duration ] } { set mssqls_duration "5" }
if {  ![ info exists mssqls_checkpoint ] } { set mssqls_checkpoint "false" }
global _ED
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm withdraw .tpc
	switch $option {
	"all" { wm title .tpc {Microsoft SQL Server TPC-C Schema Options} }
	"build" { wm title .tpc {Microsoft SQL Server TPC-C Build Options} }
	"drive" { wm title .tpc {Microsoft SQL Server TPC-C Driver Options} }
	}
   set Parent .tpc
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $boxes]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "SQL Server :"
   ttk::entry $Name -width 30 -textvariable mssqls_server
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "SQL Server Port :"   
   ttk::entry $Name  -width 30 -textvariable mssqls_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
   set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "SQL Server ODBC Driver :"   
   ttk::entry $Name  -width 30 -textvariable mssqls_odbc_driver
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Prompt $Parent.f1.pa
ttk::label $Prompt -text "Authentication :"
grid $Prompt -column 0 -row 4 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "windows" -text "Windows Authentication" -variable mssqls_authentication
grid $Name -column 1 -row 4 -sticky w
bind .tpc.f1.r1 <ButtonPress-1> {
.tpc.f1.e4 configure -state disabled
.tpc.f1.e5 configure -state disabled
}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "sql" -text "SQL Server Authentication" -variable mssqls_authentication
grid $Name -column 1 -row 5 -sticky w
bind .tpc.f1.r2 <ButtonPress-1> {
.tpc.f1.e4 configure -state normal
.tpc.f1.e5 configure -state normal
}
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "SQL Server User ID :"
   ttk::entry $Name  -width 30 -textvariable mssqls_uid
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
if {$mssqls_authentication == "windows" } {
        $Name configure -state disabled
        }
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "SQL Server User Password :"   
   ttk::entry $Name  -width 30 -textvariable mssqls_pass
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
if {$mssqls_authentication == "windows" } {
        $Name configure -state disabled
        }
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "SQL Server Database :"
   ttk::entry $Name -width 30 -textvariable mssqls_dbase
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.pb
ttk::label $Prompt -text "Schema :"
grid $Prompt -column 0 -row 9 -sticky e
set Name $Parent.f1.r5
ttk::radiobutton $Name -value "original" -text "Original" -variable mssqls_schema
grid $Name -column 1 -row 9 -sticky w
set Name $Parent.f1.r6
ttk::radiobutton $Name -value "updated" -text "Updated" -variable mssqls_schema
grid $Name -column 1 -row 10 -sticky w
set Prompt $Parent.f1.p7
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e7
	scale $Name -orient horizontal -variable mssqls_count_ware -from 1 -to 5000 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
bind .tpc.f1.e7 <Any-ButtonRelease> {
if {$mssqls_num_threads > $mssqls_count_ware} {
set mssqls_num_threads $mssqls_count_ware
		}
}
	grid $Prompt -column 0 -row 11 -sticky e
	grid $Name -column 1 -row 11 -sticky ew
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e10
        scale $Name -orient horizontal -variable mssqls_num_threads -from 1 -to 256 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
bind .tpc.f1.e10 <Any-ButtonRelease> {
if {$mssqls_num_threads > $mssqls_count_ware} {
set mssqls_num_threads $mssqls_count_ware
                }
        }
grid $Prompt -column 0 -row 12 -sticky e
grid $Name -column 1 -row 12 -sticky ew
	}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 13 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 13 -sticky w
	}
set Prompt $Parent.f1.p12
ttk::label $Prompt -text "TPC-C Driver Script :"
grid $Prompt -column 0 -row 14 -sticky e
set Name $Parent.f1.r3
ttk::radiobutton $Name -value "standard" -text "Standard Driver Script" -variable mssqlsdriver
grid $Name -column 1 -row 14 -sticky w
bind .tpc.f1.r3 <ButtonPress-1> {
set mssqls_checkpoint "false"
.tpc.f1.e17 configure -state disabled
.tpc.f1.e18 configure -state disabled
.tpc.f1.e19 configure -state disabled
}
set Name $Parent.f1.r4
ttk::radiobutton $Name -value "timed" -text "Timed Test Driver Script" -variable mssqlsdriver
grid $Name -column 1 -row 15 -sticky w
bind .tpc.f1.r4 <ButtonPress-1> {
.tpc.f1.e17 configure -state normal
.tpc.f1.e18 configure -state normal
.tpc.f1.e19 configure -state normal
}
set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable mssqls_total_iterations
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16 -sticky ew
 set Prompt $Parent.f1.p15
ttk::label $Prompt -text "Exit on SQL Server Error :"
  set Name $Parent.f1.e15
ttk::checkbutton $Name -text "" -variable mssqls_raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17 -sticky w
 set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable mssqls_keyandthink -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky w
set Prompt $Parent.f1.p17
ttk::label $Prompt -text "Checkpoint when complete :"
  set Name $Parent.f1.e17
ttk::checkbutton $Name -text "" -variable mssqls_checkpoint -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky w
if {$mssqlsdriver == "standard" } {
        $Name configure -state disabled
        }
set Name $Parent.f1.e18
   set Prompt $Parent.f1.p18
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable mssqls_rampup
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky ew
if {$mssqlsdriver == "standard" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e19
   set Prompt $Parent.f1.p19
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable mssqls_duration
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21 -sticky ew
if {$mssqlsdriver == "standard" } {
	$Name configure -state disabled
	}
}
set Name $Parent.b2
   ttk::button $Name -command {destroy .tpc} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
set Name $Parent.b1
   ttk::button $Name -command {
         set mssqls_server [.tpc.f1.e1 get]
         set mssqls_port [.tpc.f1.e2 get]
	 set mssqls_odbc_driver [.tpc.f1.e3 get]
	 set mssqls_uid [.tpc.f1.e4 get]
   	 set mssqls_pass [.tpc.f1.e5 get]
   	 set mssqls_dbase [.tpc.f1.e6 get]
if { $option eq "all" || $option eq "drive" } {
	 set mssqls_total_iterations [.tpc.f1.e14 get]
	 set mssqls_rampup [.tpc.f1.e18 get]
	 set mssqls_duration [.tpc.f1.e19 get]
 	 }
         destroy .tpc 
        } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3   
   wm geometry .tpc +50+50
   wm deiconify .tpc
   raise .tpc
   update
}

proc configdb2tpcc {option} {
global db2_count_ware db2_num_threads db2_user db2_pass db2_dbase db2_def_tab  db2_tab_list db2_partition db2_total_iterations db2_raiseerror db2_keyandthink db2driver db2_rampup db2_duration db2_monreport boxes driveroptlo defaultBackground defaultForeground
if {  ![ info exists db2_count_ware ] } { set db2_count_ware "1" }
if {  ![ info exists db2_user ] } { set db2_user "db2inst1" }
if {  ![ info exists db2_pass ] } { set db2_pass "ibmdb2" }
if {  ![ info exists db2_dbase ] } { set db2_dbase "tpcc" }
if {  ![ info exists db2_def_tab ] } { set db2_def_tab "userspace1" }
if {  ![ info exists db2_tab_list ] } { set db2_tab_list {C "" D "" H "" I "" W "" S "" NO "" OR "" OL ""}}
if {  ![ info exists db2_partition ] } { set db2_partition "false" }
if {  ![ info exists db2_num_threads ] } { set db2_num_threads "1" }
if {  ![ info exists db2_total_iterations ] } { set db2_total_iterations 1000000 }
if {  ![ info exists db2_raiseerror ] } { set db2_raiseerror "false" }
if {  ![ info exists db2_keyandthink ] } { set db2_keyandthink "false" }
if {  ![ info exists db2driver ] } { set db2driver "standard" }
if {  ![ info exists db2_rampup ] } { set db2_rampup "2" }
if {  ![ info exists db2_duration ] } { set db2_duration "5" }
if {  ![ info exists db2_monreport ] } { set db2_monreport "0" }
global _ED
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {DB2 TPC-C Schema Options} }
"build" { wm title .tpc {DB2 TPC-C Build Options} }
"drive" {  wm title .tpc {DB2 TPC-C Driver Options} }
	}
   set Parent .tpc
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $boxes]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "DB2 User :"
   ttk::entry $Name -width 30 -textvariable db2_user
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "DB2 User Password :"   
   ttk::entry $Name  -width 30 -textvariable db2_pass
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "DB2 Database :"
   ttk::entry $Name  -width 30 -textvariable db2_dbase
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "DB2 Default Tablespace :"
   ttk::entry $Name -width 30 -textvariable db2_def_tab
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "DB2 Tablespace List (Space Separated Values) :"
   ttk::entry $Name -width 30 -textvariable db2_tab_list
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
set Prompt $Parent.f1.p8
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e8
	scale $Name -orient horizontal -variable db2_count_ware -from 1 -to 5000 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
bind .tpc.f1.e8 <Any-ButtonRelease> {
if {$db2_num_threads > $db2_count_ware} {
set db2_num_threads $db2_count_ware
		}
if {$db2_count_ware < 10} {
.tpc.f1.e10 configure -state disabled
set db2_partition "false"
        } else {
.tpc.f1.e10 configure -state enabled
        }
}
	grid $Prompt -column 0 -row 8 -sticky e
	grid $Name -column 1 -row 8 -sticky ew
set Prompt $Parent.f1.p9
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e9
        scale $Name -orient horizontal -variable db2_num_threads -from 1 -to 256 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
bind .tpc.f1.e9 <Any-ButtonRelease> {
if {$db2_num_threads > $db2_count_ware} {
set db2_num_threads $db2_count_ware
                }
        }
grid $Prompt -column 0 -row 9 -sticky e
grid $Name -column 1 -row 9 -sticky ew
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Partition Tables :"
set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable db2_partition -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
if {$db2_count_ware <= 10 } {
        $Name configure -state disabled
        }
}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 11 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 11 -sticky w
	}
set Prompt $Parent.f1.p12
ttk::label $Prompt -text "TPC-C Driver Script :"
grid $Prompt -column 0 -row 12 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "standard" -text "Standard Driver Script" -variable db2driver
grid $Name -column 1 -row 12 -sticky w
bind .tpc.f1.r1 <ButtonPress-1> {
.tpc.f1.e17 configure -state disabled
.tpc.f1.e18 configure -state disabled
.tpc.f1.e19 configure -state disabled
if {$db2_monreport >= $db2_duration} {
set db2_monreport 0
                }
}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "timed" -text "Timed Test Driver Script" -variable db2driver
grid $Name -column 1 -row 13 -sticky w
bind .tpc.f1.r2 <ButtonPress-1> {
.tpc.f1.e17 configure -state normal
.tpc.f1.e18 configure -state normal
.tpc.f1.e19 configure -state normal
if {$db2_monreport >= $db2_duration} {
set db2_monreport 0
                }
}
set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable db2_total_iterations
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky ew
 set Prompt $Parent.f1.p15
ttk::label $Prompt -text "Exit on DB2 Error :"
  set Name $Parent.f1.e15
ttk::checkbutton $Name -text "" -variable db2_raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky w
 set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable db2_keyandthink -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16 -sticky w
set Name $Parent.f1.e17
   set Prompt $Parent.f1.p17
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable db2_rampup
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17 -sticky ew
if {$db2driver == "standard" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e18
   set Prompt $Parent.f1.p18
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable db2_duration
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky ew
if {$db2driver == "standard" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e19
   set Prompt $Parent.f1.p19
   ttk::label $Prompt -text "Minutes for MONREPORT :"
   ttk::entry $Name -width 30 -textvariable db2_monreport
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky ew
if {$db2driver == "standard" } {
	$Name configure -state disabled
	}
if {$db2_monreport >= $db2_duration} {
set db2_monreport 0
                }
}
set Name $Parent.b2
   ttk::button $Name -command {destroy .tpc} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
set Name $Parent.b1
   ttk::button $Name -command {
         set db2_user [.tpc.f1.e1 get]
         set db2_pass [.tpc.f1.e2 get]
	 set db2_dbase [.tpc.f1.e3 get]
if { $option eq "all" || $option eq "build" } {
	 set db2_def_tab [.tpc.f1.e4 get]
   	 set db2_tab_list [.tpc.f1.e5 get]
 }
if { $option eq "all" || $option eq "drive" } {
	 set db2_total_iterations [ .tpc.f1.e14 get]
	 set db2_rampup [ .tpc.f1.e17 get]
	 set db2_duration [ .tpc.f1.e18 get]
	 set db2_monreport [ .tpc.f1.e19 get]
if {$db2_monreport >= $db2_duration} {
set db2_monreport 0
                }
 }
         destroy .tpc 
        } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3   
   wm geometry .tpc +50+50
   wm deiconify .tpc
   raise .tpc
   update
}

proc configpgtpcc {option} {
global pg_host pg_port pg_count_ware pg_superuser pg_superuserpass pg_defaultdbase pg_user pg_pass pg_dbase pg_vacuum pg_dritasnap pg_oracompat pg_num_threads pg_total_iterations pg_raiseerror pg_keyandthink pg_driver pg_rampup pg_duration boxes driveroptlo defaultBackground defaultForeground
if {  ![ info exists pg_host ] } { set pg_host "localhost" }
if {  ![ info exists pg_port ] } { set pg_port "5432" }
if {  ![ info exists pg_count_ware ] } { set pg_count_ware "1" }
if {  ![ info exists pg_superuser ] } { set pg_superuser "postgres" }
if {  ![ info exists pg_superuserpass ] } { set pg_superuserpass "postgres" }
if {  ![ info exists pg_defaultdbase ] } { set pg_defaultdbase "postgres" }
if {  ![ info exists pg_user ] } { set pg_user "tpcc" }
if {  ![ info exists pg_pass ] } { set pg_pass "tpcc" }
if {  ![ info exists pg_dbase ] } { set pg_dbase "tpcc" }
if {  ![ info exists pg_vacuum ] } { set pg_vacuum "false" }
if {  ![ info exists pg_dritasnap ] } { set pg_dritasnap "false" }
if {  ![ info exists pg_oracompat ] } { set pg_oracompat "false" }
if {  ![ info exists pg_num_threads ] } { set pg_num_threads "1" }
if {  ![ info exists pg_total_iterations ] } { set pg_total_iterations 1000000 }
if {  ![ info exists pg_raiseerror ] } { set pg_raiseerror "false" }
if {  ![ info exists pg_keyandthink ] } { set pg_keyandthink "false" }
if {  ![ info exists pg_driver ] } { set pg_driver "standard" }
if {  ![ info exists pg_rampup ] } { set pg_rampup "2" }
if {  ![ info exists pg_duration ] } { set pg_duration "5" }
if { $pg_oracompat eq "true" } {
if { $pg_port eq "5432" } { set pg_port "5444" }
if { $pg_superuser eq "postgres" } { set pg_superuser "enterprisedb" }
if { $pg_defaultdbase eq "postgres" } { set pg_defaultdbase "edb" }
	} else {
if { $pg_port eq "5444" } { set pg_port "5432" }
if { $pg_superuser eq "enterprisedb" } { set pg_superuser "postgres" }
if { $pg_defaultdbase eq "edb" } { set pg_defaultdbase "postgres" }
	}
global _ED
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {PostgreSQL TPC-C Schema Options} }
"build" { wm title .tpc {PostgreSQL TPC-C Build Options} }
"drive" {  wm title .tpc {PostgreSQL TPC-C Driver Options} }
	}
   set Parent .tpc
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $boxes]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "PostgreSQL Host :"
   ttk::entry $Name -width 30 -textvariable pg_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "PostgreSQL Port :"   
   ttk::entry $Name  -width 30 -textvariable pg_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "PostgreSQL Superuser :"
   ttk::entry $Name  -width 30 -textvariable pg_superuser
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "PostgreSQL Superuser Password :"   
   ttk::entry $Name  -width 30 -textvariable pg_superuserpass
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "PostgreSQL Default Database :"
   ttk::entry $Name -width 30 -textvariable pg_defaultdbase
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "PostgreSQL User :"
   ttk::entry $Name  -width 30 -textvariable pg_user
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7
   ttk::label $Prompt -text "PostgreSQL User Password :"   
   ttk::entry $Name  -width 30 -textvariable pg_pass
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
set Name $Parent.f1.e8
   set Prompt $Parent.f1.p8
   ttk::label $Prompt -text "PostgreSQL Database :"
   ttk::entry $Name -width 30 -textvariable pg_dbase
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky ew
set Prompt $Parent.f1.p9
ttk::label $Prompt -text "EnterpriseDB Oracle Compatible :"
set Name $Parent.f1.e9
ttk::checkbutton $Name -text "" -variable pg_oracompat -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 9 -sticky e
   grid $Name -column 1 -row 9 -sticky w
bind .tpc.f1.e9 <Button> { 
if { $pg_oracompat != "true" } {
if { $pg_port eq "5432" } { set pg_port "5444" }
if { $pg_superuser eq "postgres" } { set pg_superuser "enterprisedb" }
if { $pg_defaultdbase eq "postgres" } { set pg_defaultdbase "edb" }
	} else {
if { $pg_port eq "5444" } { set pg_port "5432" }
if { $pg_superuser eq "enterprisedb" } { set pg_superuser "postgres" }
if { $pg_defaultdbase eq "edb" } { set pg_defaultdbase "postgres" }
	}
}
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e10
	scale $Name -orient horizontal -variable pg_count_ware -from 1 -to 5000 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
bind .tpc.f1.e10 <Any-ButtonRelease> {
if {$pg_num_threads > $pg_count_ware} {
set pg_num_threads $pg_count_ware
		}
}
	grid $Prompt -column 0 -row 10 -sticky e
	grid $Name -column 1 -row 10 -sticky ew
set Prompt $Parent.f1.p11
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e11
        scale $Name -orient horizontal -variable pg_num_threads -from 1 -to 256 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
bind .tpc.f1.e11 <Any-ButtonRelease> {
if {$pg_num_threads > $pg_count_ware} {
set pg_num_threads $pg_count_ware
                }
        }
grid $Prompt -column 0 -row 12 -sticky e
grid $Name -column 1 -row 12 -sticky ew
}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 13 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 13 -sticky w
	}
set Prompt $Parent.f1.p14
ttk::label $Prompt -text "TPC-C Driver Script :"
grid $Prompt -column 0 -row 13 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "standard" -text "Standard Driver Script" -variable pg_driver
grid $Name -column 1 -row 13 -sticky w
bind .tpc.f1.r1 <ButtonPress-1> {
set pg_vacuum "false"
set pg_dritasnap "false"
.tpc.f1.e19 configure -state disabled
.tpc.f1.e20 configure -state disabled
.tpc.f1.e21 configure -state disabled
.tpc.f1.e22 configure -state disabled
}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "timed" -text "Timed Test Driver Script" -variable pg_driver
grid $Name -column 1 -row 14 -sticky w
bind .tpc.f1.r2 <ButtonPress-1> {
.tpc.f1.e19 configure -state normal
.tpc.f1.e20 configure -state normal
.tpc.f1.e21 configure -state normal
.tpc.f1.e22 configure -state normal
}
set Name $Parent.f1.e15
   set Prompt $Parent.f1.p15
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable pg_total_iterations
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky ew
 set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Exit on PostgreSQL Error :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable pg_raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16 -sticky w
 set Prompt $Parent.f1.p17
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.e17
ttk::checkbutton $Name -text "" -variable pg_keyandthink -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky w
set Prompt $Parent.f1.p19
ttk::label $Prompt -text "Vacuum when complete :"
set Name $Parent.f1.e19
ttk::checkbutton $Name -text "" -variable pg_vacuum -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky w
if {$pg_driver == "standard" } {
	$Name configure -state disabled
	}
set Prompt $Parent.f1.p20
ttk::label $Prompt -text "EnterpriseDB DRITA Snapshots :"
set Name $Parent.f1.e20
ttk::checkbutton $Name -text "" -variable pg_dritasnap -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky w
if {$pg_driver == "standard" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e21
   set Prompt $Parent.f1.p21
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable pg_rampup
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21 -sticky ew
if {$pg_driver == "standard" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e22
   set Prompt $Parent.f1.p22
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable pg_duration
   grid $Prompt -column 0 -row 22 -sticky e
   grid $Name -column 1 -row 22 -sticky ew
if {$pg_driver == "standard" } {
	$Name configure -state disabled
	}
}
set Name $Parent.b2
   ttk::button $Name -command {destroy .tpc} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
set Name $Parent.b1
   ttk::button $Name -command {
         set pg_host [.tpc.f1.e1 get]
         set pg_port [.tpc.f1.e2 get]
	 set pg_superuser [.tpc.f1.e3 get]
	 set pg_superuserpass [.tpc.f1.e4 get]
   	 set pg_defaultdbase [.tpc.f1.e5 get]
	 set pg_user [.tpc.f1.e6 get]
	 set pg_pass [.tpc.f1.e7 get]
   	 set pg_dbase [.tpc.f1.e8 get]
if { $option eq "all" || $option eq "drive" } {
	 set pg_total_iterations [ .tpc.f1.e15 get]
	 set pg_rampup [ .tpc.f1.e21 get]
	 set pg_duration [ .tpc.f1.e22 get]
 	}
         destroy .tpc 
        } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3   
   wm geometry .tpc +50+50
   wm deiconify .tpc
   raise .tpc
   update
}

proc configredistpcc { option } {
global redis_host redis_port redis_namespace redis_count_ware redis_num_threads redis_total_iterations redis_raiseerror redis_keyandthink redis_driver redis_rampup redis_duration boxes driveroptlo defaultBackground defaultForeground
if {  ![ info exists redis_host ] } { set redis_host "127.0.0.1" }
if {  ![ info exists redis_port ] } { set redis_port "6379" }
if {  ![ info exists redis_namespace ] } { set redis_namespace "1" }
if {  ![ info exists redis_count_ware ] } { set redis_count_ware "1" }
if {  ![ info exists redis_num_threads ] } { set redis_num_threads "1" }
if {  ![ info exists redis_total_iterations ] } { set redis_total_iterations 1000000 }
if {  ![ info exists redis_raiseerror ] } { set redis_raiseerror "false" }
if {  ![ info exists redis_keyandthink ] } { set redis_keyandthink "false" }
if {  ![ info exists redis_driver ] } { set redis_driver "standard" }
if {  ![ info exists redis_rampup ] } { set redis_rampup "2" }
if {  ![ info exists redis_duration ] } { set redis_duration "5" }
global _ED
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {Redis TPC-C Schema Options} }
"build" { wm title .tpc {Redis TPC-C Build Options} }
"drive" {  wm title .tpc {Redis TPC-C Driver Options} }
	}
   set Parent .tpc
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $boxes]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Redis Host :"
   ttk::entry $Name -width 30 -textvariable redis_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Redis Port :"   
   ttk::entry $Name  -width 30 -textvariable redis_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "Redis Namespace :"
   ttk::entry $Name  -width 30 -textvariable redis_namespace
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.p4
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e4
	scale $Name -orient horizontal -variable redis_count_ware -from 1 -to 5000 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
bind .tpc.f1.e4 <Any-ButtonRelease> {
if {$redis_num_threads > $redis_count_ware} {
set redis_num_threads $redis_count_ware
		}
	}
	grid $Prompt -column 0 -row 4 -sticky e
	grid $Name -column 1 -row 4 -sticky ew
set Prompt $Parent.f1.p5
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e5
        scale $Name -orient horizontal -variable redis_num_threads -from 1 -to 256 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
bind .tpc.f1.e5 <Any-ButtonRelease> {
if {$redis_num_threads > $redis_count_ware} {
set redis_num_threads $redis_count_ware
                }
        }
grid $Prompt -column 0 -row 5 -sticky e
grid $Name -column 1 -row 5 -sticky ew
}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 6 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 6 -sticky w
	}
set Prompt $Parent.f1.p6
ttk::label $Prompt -text "TPC-C Driver Script :"
grid $Prompt -column 0 -row 7 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "standard" -text "Standard Driver Script" -variable redis_driver
grid $Name -column 1 -row 7 -sticky w
bind .tpc.f1.r1 <ButtonPress-1> {
.tpc.f1.e11 configure -state disabled
.tpc.f1.e12 configure -state disabled
}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "timed" -text "Timed Test Driver Script" -variable redis_driver
grid $Name -column 1 -row 8 -sticky w
bind .tpc.f1.r2 <ButtonPress-1> {
.tpc.f1.e11 configure -state normal
.tpc.f1.e12 configure -state normal
}
set Name $Parent.f1.e8
   set Prompt $Parent.f1.p8
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable redis_total_iterations
   grid $Prompt -column 0 -row 9 -sticky e
   grid $Name -column 1 -row 9 -sticky ew
 set Prompt $Parent.f1.p9
ttk::label $Prompt -text "Exit on Redis Error :"
  set Name $Parent.f1.e9
ttk::checkbutton $Name -text "" -variable redis_raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
 set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable redis_keyandthink -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 11 -sticky e
   grid $Name -column 1 -row 11 -sticky w
set Name $Parent.f1.e11
   set Prompt $Parent.f1.p11
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable redis_rampup
   grid $Prompt -column 0 -row 12 -sticky e
   grid $Name -column 1 -row 12 -sticky ew
if {$redis_driver == "standard" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e12
   set Prompt $Parent.f1.p12
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable redis_duration
   grid $Prompt -column 0 -row 13 -sticky e
   grid $Name -column 1 -row 13 -sticky ew
if {$redis_driver == "standard" } {
	$Name configure -state disabled
	}
}
set Name $Parent.b2
   ttk::button $Name -command {destroy .tpc} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
set Name $Parent.b1
   ttk::button $Name -command {
         set redis_host [.tpc.f1.e1 get]
         set redis_port [.tpc.f1.e2 get]
	 set redis_namespace [.tpc.f1.e3 get]
if { $option eq "all" || $option eq "drive" } {
	 set redis_total_iterations [ .tpc.f1.e9 get]
	 set redis_rampup [ .tpc.f1.e12 get]
	 set redis_duration [ .tpc.f1.e13 get]
 }
         destroy .tpc 
        } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3   
   wm geometry .tpc +50+50
   wm deiconify .tpc
   raise .tpc
   update
}

proc configtraftpcc { option } {
global trafodion_dsn trafodion_odbc_driver trafodion_server trafodion_port trafodion_userid trafodion_password trafodion_schema trafodion_count_ware trafodion_num_threads trafodion_load_type trafodion_load_data trafodion_node_list trafodion_copy_remote trafodion_build_jsps trafodion_total_iterations trafodion_raiseerror trafodion_keyandthink trafodion_driver trafodion_rampup trafodion_duration boxes driveroptlo defaultBackground defaultForeground
if {  ![ info exists trafodion_dsn ] } { set trafodion_dsn "Default_DataSource" }
if {  ![ info exists trafodion_odbc_driver ] } { set trafodion_odbc_driver "Trafodion" }
if {  ![ info exists trafodion_server ] } { set trafodion_server "sandbox" }
if {  ![ info exists trafodion_port ] } { set trafodion_port "37800" }
if {  ![ info exists trafodion_userid ] } { set trafodion_userid "trafodion" }
if {  ![ info exists trafodion_password ] } { set trafodion_password "traf123" }
if {  ![ info exists trafodion_schema ] } { set trafodion_schema "tpcc" }
if {  ![ info exists trafodion_count_ware ] } { set trafodion_count_ware "1" }
if {  ![ info exists trafodion_num_threads ] } { set trafodion_num_threads "1" }
if {  ![ info exists trafodion_load_type ] } { set trafodion_load_type "upsert" }
if {  ![ info exists trafodion_load_data ] } { set trafodion_load_data "true" }
if {  ![ info exists trafodion_build_jsps ] } { set trafodion_build_jsps "true" }
if {  ![ info exists trafodion_copy_remote ] } { set trafodion_copy_remote "false" }
if {  ![ info exists trafodion_node_list ] } { set trafodion_load_type "sandbox" }
if {  ![ info exists trafodion_total_iterations ] } { set trafodion_total_iterations 1000000 }
if {  ![ info exists trafodion_raiseerror ] } { set trafodion_raiseerror "false" }
if {  ![ info exists trafodion_keyandthink ] } { set trafodion_keyandthink "false" }
if {  ![ info exists trafodion_driver ] } { set trafodion_driver "standard" }
if {  ![ info exists trafodion_rampup ] } { set trafodion_rampup "2" }
if {  ![ info exists trafodion_duration ] } { set trafodion_duration "5" }
global _ED
   catch "destroy .tpc"
   ttk::toplevel .tpc
   wm withdraw .tpc
switch $option {
"all" { wm title .tpc {Trafodion TPC-C Schema Options} }
"build" { wm title .tpc {Trafodion TPC-C Build Options} }
"drive" {  wm title .tpc {Trafodion TPC-C Driver Options} }
	}
   set Parent .tpc
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $boxes]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Trafodion DSN :"
   ttk::entry $Name -width 30 -textvariable trafodion_dsn
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Trafodion ODBC Driver :"   
   ttk::entry $Name  -width 30 -textvariable trafodion_odbc_driver
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "Trafodion Server :"
   ttk::entry $Name  -width 30 -textvariable trafodion_server
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "Trafodion Port :"
   ttk::entry $Name  -width 30 -textvariable trafodion_port
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "Trafodion User ID :"
   ttk::entry $Name  -width 30 -textvariable trafodion_userid
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "Trafodion Password :"
   ttk::entry $Name  -width 30 -textvariable trafodion_password
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7
   ttk::label $Prompt -text "Trafodion Schema :"
   ttk::entry $Name  -width 30 -textvariable trafodion_schema
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.p8
ttk::label $Prompt -text "Load Data into Tables :"
set Name $Parent.f1.e8
ttk::checkbutton $Name -text "" -variable trafodion_load_data -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky w
bind .tpc.f1.e8 <Any-ButtonRelease> {
if { $trafodion_load_data == "false" } {
.tpc.f1.r1 configure -state normal
.tpc.f1.r2 configure -state normal
	} else {
.tpc.f1.r1 configure -state disabled
.tpc.f1.r2 configure -state disabled
set trafodion_num_threads 1
set trafodion_count_ware 1
	}
 }
set Prompt $Parent.f1.pa
ttk::label $Prompt -text "Load Type :"
grid $Prompt -column 0 -row 9 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "upsert" -text "Upsert" -variable trafodion_load_type
grid $Name -column 1 -row 9 -sticky w
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "insert" -text "Insert" -variable trafodion_load_type 
grid $Name -column 1 -row 10 -sticky w
if { $trafodion_load_data == "false" } {
set trafodion_num_threads 1
set trafodion_count_ware 1
.tpc.f1.r1 configure -state disabled
.tpc.f1.r2 configure -state disabled
	} else {
.tpc.f1.r1 configure -state normal
.tpc.f1.r2 configure -state normal
	}
set Prompt $Parent.f1.p11
ttk::label $Prompt -text "Number of Warehouses :"
set Name $Parent.f1.e11
	scale $Name -orient horizontal -variable trafodion_count_ware -from 1 -to 5000 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
bind .tpc.f1.e11 <Any-ButtonRelease> {
if {$trafodion_num_threads > $trafodion_count_ware} {
set trafodion_num_threads $trafodion_count_ware
		}
if { $trafodion_load_data == "false" } {
set trafodion_num_threads 1
set trafodion_count_ware 1
		}
	}
	grid $Prompt -column 0 -row 11 -sticky e
	grid $Name -column 1 -row 11 -sticky ew
set Prompt $Parent.f1.p12
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e12
        scale $Name -orient horizontal -variable trafodion_num_threads -from 1 -to 256 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
bind .tpc.f1.e12 <Any-ButtonRelease> {
if {$trafodion_num_threads > $trafodion_count_ware} {
set trafodion_num_threads $trafodion_count_ware
                }
if { $trafodion_load_data == "false" } {
set trafodion_num_threads 1
set trafodion_count_ware 1
		}
        }
grid $Prompt -column 0 -row 12 -sticky e
grid $Name -column 1 -row 12 -sticky ew
set Prompt $Parent.f1.p13
ttk::label $Prompt -text "Build Java Stored Procedures Locally:"
set Name $Parent.f1.e13
ttk::checkbutton $Name -text "" -variable trafodion_build_jsps -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 13 -sticky e
   grid $Name -column 1 -row 13 -sticky w
bind .tpc.f1.e13 <Any-ButtonRelease> {
if { $trafodion_build_jsps == "false" } {
.tpc.f1.e14 configure -state normal
if { $trafodion_copy_remote == "true" } {
.tpc.f1.e15 configure -state normal
	}
} else {
.tpc.f1.e14 configure -state disabled
.tpc.f1.e15 configure -state disabled
set trafodion_copy_remote "false"
                        }
                }
set Prompt $Parent.f1.p14
ttk::label $Prompt -text "Copy Stored Procedures to Remote Nodes :"
set Name $Parent.f1.e14
ttk::checkbutton $Name -text "" -variable trafodion_copy_remote -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky w
if { $trafodion_copy_remote == "false" && $trafodion_build_jsps == "false" } {
.tpc.f1.e14 configure -state disabled
	}
bind .tpc.f1.e14 <Any-ButtonRelease> {
if { $trafodion_copy_remote == "false" } { 
if { $trafodion_build_jsps == "true" } {
.tpc.f1.e15 configure -state normal
	}
} else {
.tpc.f1.e15 configure -state disabled
                        }
                }
   set Name $Parent.f1.e15
   set Prompt $Parent.f1.p15
   ttk::label $Prompt -text "Node List (Space Separated Values) :"
   ttk::entry $Name -width 30 -textvariable trafodion_node_list
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky ew
if {$trafodion_build_jsps == "true" && $trafodion_copy_remote == "true"} {
        $Name configure -state normal
        } else {
        $Name configure -state disabled
	}
}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 16 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 16 -sticky w
	}
set Prompt $Parent.f1.p17
ttk::label $Prompt -text "TPC-C Driver Script :"
grid $Prompt -column 0 -row 17 -sticky e
set Name $Parent.f1.r3
ttk::radiobutton $Name -value "standard" -text "Standard Driver Script" -variable trafodion_driver
grid $Name -column 1 -row 17 -sticky w
bind .tpc.f1.r3 <ButtonPress-1> {
.tpc.f1.e22 configure -state disabled
.tpc.f1.e23 configure -state disabled
}
set Name $Parent.f1.r4
ttk::radiobutton $Name -value "timed" -text "Timed Test Driver Script" -variable trafodion_driver
grid $Name -column 1 -row 18 -sticky w
bind .tpc.f1.r4 <ButtonPress-1> {
.tpc.f1.e22 configure -state normal
.tpc.f1.e23 configure -state normal
}
set Name $Parent.f1.e19
   set Prompt $Parent.f1.p19
   ttk::label $Prompt -text "Total Transactions per User :"
   ttk::entry $Name -width 30 -textvariable trafodion_total_iterations
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky ew
 set Prompt $Parent.f1.p20
ttk::label $Prompt -text "Exit on Trafodion Error :"
  set Name $Parent.f1.e20
ttk::checkbutton $Name -text "" -variable trafodion_raiseerror -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky w
 set Prompt $Parent.f1.p21
ttk::label $Prompt -text "Keying and Thinking Time :"
  set Name $Parent.f1.21
ttk::checkbutton $Name -text "" -variable trafodion_keyandthink -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 21 -sticky e
   grid $Name -column 1 -row 21 -sticky w
set Name $Parent.f1.e22
   set Prompt $Parent.f1.p22
   ttk::label $Prompt -text "Minutes of Rampup Time :"
   ttk::entry $Name -width 30 -textvariable trafodion_rampup
   grid $Prompt -column 0 -row 22 -sticky e
   grid $Name -column 1 -row 22 -sticky ew
if {$trafodion_driver == "standard" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e23
   set Prompt $Parent.f1.p23
   ttk::label $Prompt -text "Minutes for Test Duration :"
   ttk::entry $Name -width 30 -textvariable trafodion_duration
   grid $Prompt -column 0 -row 23 -sticky e
   grid $Name -column 1 -row 23 -sticky ew
if {$trafodion_driver == "standard" } {
	$Name configure -state disabled
	}
}
set Name $Parent.b2
   ttk::button $Name -command {destroy .tpc} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
set Name $Parent.b1
   ttk::button $Name -command {
         set trafodion_dsn [.tpc.f1.e1 get]
         set trafodion_odbc_driver [.tpc.f1.e2 get]
         set trafodion_server [.tpc.f1.e3 get]
         set trafodion_port [.tpc.f1.e4 get]
         set trafodion_userid [.tpc.f1.e5 get]
         set trafodion_password [.tpc.f1.e6 get]
         set trafodion_schema [.tpc.f1.e7 get]
if { $option eq "all" || $option eq "build" } {
         set trafodion_node_list [.tpc.f1.e15 get]
 }
if { $option eq "all" || $option eq "drive" } {
	 set redis_total_iterations [ .tpc.f1.e19 get]
	 set redis_rampup [ .tpc.f1.e22 get]
	 set redis_duration [ .tpc.f1.e23 get]
 }
         destroy .tpc 
        } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3   
   wm geometry .tpc +50+50
   wm deiconify .tpc
   raise .tpc
   update
}

proc configoratpch {option} {
global instance system_password scale_fact tpch_user tpch_pass tpch_def_tab tpch_def_temp tpch_tt_compat boxes driveroptlo num_tpch_threads refresh_on total_querysets raise_query_error verbose degree_of_parallel refresh_on update_sets trickle_refresh refresh_verbose defaultBackground defaultForeground
if {  ![ info exists system_password ] } { set system_password "manager" }
if {  ![ info exists instance ] } { set instance "oracle" }
if {  ![ info exists scale_fact ] } { set scale_fact "1" }
if {  ![ info exists num_tpch_threads ] } { set num_tpch_threads "1" }
if {  ![ info exists tpch_user ] } { set tpch_user "tpch" }
if {  ![ info exists tpch_pass ] } { set tpch_pass "tpch" }
if {  ![ info exists tpch_def_tab ] } { set tpch_def_tab "tpchtab" }
if {  ![ info exists tpch-def_temp ] } { set tpch_def_temp "temp" }
if {  ![ info exists tpch_tt_compat ] } { set tpch_tt_compat "false" }
global _ED
   catch "destroy .tpch"
   ttk::toplevel .tpch
   wm withdraw .tpch
	switch $option {
	"all" { wm title .tpch {Oracle TPC-H Schema Options} }
	"build" { wm title .tpch {Oracle TPC-H Build Options} }
	"drive" {  wm title .tpch {Oracle TPC-H Driver Options} }
	}
   set Parent .tpch
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
   if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $boxes]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Oracle Service Name :"
   ttk::entry $Name -width 30 -textvariable instance
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -columnspan 4 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "System User Password :"
   ttk::entry $Name -width 30 -textvariable system_password
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -columnspan 4 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "TPC-H User :"
   ttk::entry $Name -width 30 -textvariable tpch_user
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -columnspan 4 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "TPC-H User Password :"
   ttk::entry $Name  -width 30 -textvariable tpch_pass
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -columnspan 4 -sticky ew
   if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "TPC-H Default Tablespace :"
   ttk::entry $Name -width 30 -textvariable tpch_def_tab
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -columnspan 4 -sticky ew
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "TPC-H Temporary Tablespace :"
   ttk::entry $Name -width 30 -textvariable tpch_def_temp
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -columnspan 4 -sticky ew
	}
set Prompt $Parent.f1.p7
ttk::label $Prompt -text "TimesTen Database Compatible :"
   set Name $Parent.f1.e7
ttk::checkbutton $Name -text "" -variable tpch_tt_compat -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky w
if { $tpch_tt_compat eq "false" } {
foreach field {e2 e5 e6} {
catch {.tpch.f1.$field configure -state normal}
        }
        } else {
foreach field {e2 e5 e6} {
catch {.tpch.f1.$field configure -state disabled}
        }
        }
bind .tpch.f1.e7 <ButtonPress-1> {
if { $tpch_tt_compat eq "true" } {
foreach field {e2 e5 e6 e13} {
catch {.tpch.f1.$field configure -state normal}
        }
    } else {
foreach field {e2 e5 e6 e13} {
catch {.tpch.f1.$field configure -state disabled}
        } }
}
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e8
   set Prompt $Parent.f1.p8 
   ttk::label $Prompt -text "Scale Factor :"
   grid $Prompt -column 0 -row 8 -sticky e
   set Name $Parent.f1.f2
   ttk::frame $Name -width 30
   grid $Name -column 1 -row 8 -sticky ew
	set rcnt 1
	foreach item {1} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable scale_fact -text $item -value $item -width 1
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 2
	foreach item {10 30} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable scale_fact -text $item -value $item -width 2
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 4
	foreach item {100 300} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable scale_fact -text $item -value $item -width 3
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 6
	foreach item {1000} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable scale_fact -text $item -value $item -width 4
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
set Prompt $Parent.f1.p9
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e9
	scale $Name -orient horizontal -variable num_tpch_threads -from 1 -to 256 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
	grid $Prompt -column 0 -row 9 -sticky e
	grid $Name -column 1 -row 9 -sticky ew
	}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 12 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 12 -sticky w
	}
   set Name $Parent.f1.e10
   set Prompt $Parent.f1.p10
   ttk::label $Prompt -text "Total Query Sets per User :"
   ttk::entry $Name -width 30 -textvariable total_querysets
   grid $Prompt -column 0 -row 13 -sticky e
   grid $Name -column 1 -row 13  -columnspan 4 -sticky ew
 set Prompt $Parent.f1.p11
ttk::label $Prompt -text "Exit on Oracle Error :"
  set Name $Parent.f1.e11
ttk::checkbutton $Name -text "" -variable raise_query_error -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky w
 set Prompt $Parent.f1.p12
ttk::label $Prompt -text "Verbose Output :"
  set Name $Parent.f1.e12
ttk::checkbutton $Name -text "" -variable verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky w
   set Name $Parent.f1.e13
   set Prompt $Parent.f1.p13
   ttk::label $Prompt -text "Degree of Parallelism :"
   ttk::entry $Name -width 30 -textvariable degree_of_parallel
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16  -columnspan 4 -sticky ew
if { $tpch_tt_compat eq "false" } {
catch {.tpch.f1.e13 configure -state normal}
        } else {
catch {.tpch.f1.e13 configure -state disabled}
        }
 set Prompt $Parent.f1.p14
ttk::label $Prompt -text "Refresh Function :"
  set Name $Parent.f1.e14
ttk::checkbutton $Name -text "" -variable refresh_on -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17 -sticky w
bind $Parent.f1.e14 <Button> {
if {$refresh_on eq "true"} { 
set refresh_verbose "false"
foreach field {e15 e16 e17} {
.tpch.f1.$field configure -state disabled 
		}
} else {
foreach field {e15 e16 e17} {
.tpch.f1.$field configure -state normal
                        }
                }
	}
   set Name $Parent.f1.e15
   set Prompt $Parent.f1.p15
   ttk::label $Prompt -text "Number of Update Sets :"
   ttk::entry $Name -width 30 -textvariable update_sets
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18  -columnspan 4 -sticky ew
if {$refresh_on == "false" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e16
   set Prompt $Parent.f1.p16
   ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable trickle_refresh
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19  -columnspan 4 -sticky ew
if {$refresh_on == "false" } {
	$Name configure -state disabled
	}
 set Prompt $Parent.f1.p17
ttk::label $Prompt -text "Refresh Verbose :"
  set Name $Parent.f1.e17
ttk::checkbutton $Name -text "" -variable refresh_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky w
if {$refresh_on == "false" } {
	$Name configure -state disabled
	}
}
   set Name $Parent.b2
   ttk::button $Name -command {destroy .tpch} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3

   set Name $Parent.b1
   ttk::button $Name -command {
         set instance [.tpch.f1.e1 get]
         set system_password [.tpch.f1.e2 get]
	 set tpch_user [.tpch.f1.e3 get]
	 set tpch_pass [.tpch.f1.e4 get]
if { $option eq "all" || $option eq "build" } {
   	 set tpch_def_tab [.tpch.f1.e5 get]
	 set tpch_def_temp [.tpch.f1.e6 get]
   	}
if { $option eq "all" || $option eq "drive" } {
   	 set total_querysets [ .tpch.f1.e10 get ]
   	 set degree_of_parallel [ .tpch.f1.e13 get ]
   	 set update_sets [ .tpch.f1.e15 get ]
   	 set trickle_refresh [ .tpch.f1.e16 get ]
	}
         destroy .tpch 
        } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3
   wm geometry .tpch +50+50
   wm deiconify .tpch
   raise .tpch
   update
}

proc configmytpch {option} {
global mysql_host mysql_port mysql_scale_fact mysql_tpch_user mysql_tpch_pass mysql_tpch_dbase mysql_num_tpch_threads boxes driveroptlo mysql_tpch_storage_engine mysql_refresh_on mysql_total_querysets mysql_raise_query_error mysql_verbose mysql_update_sets mysql_trickle_refresh mysql_refresh_verbose defaultBackground defaultForeground
if {  ![ info exists mysql_host ] } { set mysql_host "127.0.0.1" }
if {  ![ info exists mysql_port ] } { set mysql_port "3306" }
if {  ![ info exists mysql_scale_fact ] } { set mysql_scale_fact "1" }
if {  ![ info exists mysql_tpch_user ] } { set mysql_tpch_user "root" }
if {  ![ info exists mysql_tpch_pass ] } { set mysql_tpch_pass "mysql" }
if {  ![ info exists mysql_tpch_dbase ] } { set mysql_tpch_dbase "tpch" }
if {  ![ info exists mysql_num_tpch_threads ] } { set mysql_num_tpch_threads "1" }
if {  ![ info exists mysql_tpch_storage_engine ] } { set mysql_tpch_storage_engine "myisam" }
if {  ![ info exists mysql_refresh_on ] } { set  mysql_refresh_on "false" }
if {  ![ info exists mysql_total_querysets ] } { set mysql_total_querysets "1" }
if {  ![ info exists mysql_raise_query_error ] } { set mysql_raise_query_error "false" }
if {  ![ info exists mysql_verbose ] } { set mysql_verbose "false" }
if {  ![ info exists mysql_update_sets ] } { set mysql_update_sets "1" }
if {  ![ info exists mysql_trickle_refresh ] } { set mysql_trickle_refresh "1000" }
if {  ![ info exists mysql_refresh_verbose ] } { set mysql_refresh_verbose "fals
e" }
global _ED
   catch "destroy .mytpch"
   ttk::toplevel .mytpch
   wm withdraw .mytpch
switch $option {
"all" { wm title .mytpch {MySQL TPC-H Schema Options} }
"build" { wm title .mytpch {MySQL TPC-H Build Options} }
"drive" {  wm title .mytpch {MySQL TPC-H Driver Options} }
	}
   set Parent .mytpch
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $boxes]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "MySQL Host :"
   ttk::entry $Name -width 30 -textvariable mysql_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "MySQL Port :"   
   ttk::entry $Name  -width 30 -textvariable mysql_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "MySQL User :"
   ttk::entry $Name  -width 30 -textvariable mysql_tpch_user
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "MySQL User Password :"   
   ttk::entry $Name  -width 30 -textvariable mysql_tpch_pass
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "MySQL Database :"
   ttk::entry $Name -width 30 -textvariable mysql_tpch_dbase
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "Data Warehouse Storage Engine :"
   ttk::entry $Name -width 30 -textvariable mysql_tpch_storage_engine
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7 
   ttk::label $Prompt -text "Scale Factor :"
   grid $Prompt -column 0 -row 7 -sticky e
   set Name $Parent.f1.f2
   ttk::frame $Name -width 30
   grid $Name -column 1 -row 7 -sticky ew
	set rcnt 1
	foreach item {1} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable mysql_scale_fact -text $item -value $item -width 1
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 2
	foreach item {10 30} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable mysql_scale_fact -text $item -value $item -width 2
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 4
	foreach item {100 300} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable mysql_scale_fact -text $item -value $item -width 3
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 6
	foreach item {1000} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable mysql_scale_fact -text $item -value $item -width 4
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
set Prompt $Parent.f1.p8
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e8
	scale $Name -orient horizontal -variable mysql_num_tpch_threads -from 1 -to 256 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
	grid $Prompt -column 0 -row 8 -sticky e
	grid $Name -column 1 -row 8 -sticky ew
	}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 11 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 11 -sticky w
	}
   set Name $Parent.f1.e9
   set Prompt $Parent.f1.p9
   ttk::label $Prompt -text "Total Query Sets per User :"
   ttk::entry $Name -width 30 -textvariable mysql_total_querysets
   grid $Prompt -column 0 -row 12 -sticky e
   grid $Name -column 1 -row 12  -columnspan 4 -sticky ew
 set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Exit on MySQL Error :"
  set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable mysql_raise_query_error -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 13 -sticky e
   grid $Name -column 1 -row 13 -sticky w
 set Prompt $Parent.f1.p11
ttk::label $Prompt -text "Verbose Output :"
  set Name $Parent.f1.e11
ttk::checkbutton $Name -text "" -variable mysql_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky w
 set Prompt $Parent.f1.p12
ttk::label $Prompt -text "Refresh Function :"
  set Name $Parent.f1.e12
ttk::checkbutton $Name -text "" -variable mysql_refresh_on -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky w
bind $Parent.f1.e12 <Button> {
if {$mysql_refresh_on eq "true"} { 
set mysql_refresh_verbose "false"
foreach field {e13 e14 e15} {
.mytpch.f1.$field configure -state disabled 
		}
} else {
foreach field {e13 e14 e15} {
.mytpch.f1.$field configure -state normal
                        }
                }
	}
   set Name $Parent.f1.e13
   set Prompt $Parent.f1.p13
   ttk::label $Prompt -text "Number of Update Sets :"
   ttk::entry $Name -width 30 -textvariable mysql_update_sets
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16  -columnspan 4 -sticky ew
if {$mysql_refresh_on == "false" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable mysql_trickle_refresh
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17  -columnspan 4 -sticky ew
if {$mysql_refresh_on == "false" } {
	$Name configure -state disabled
	}
 set Prompt $Parent.f1.p15
ttk::label $Prompt -text "Refresh Verbose :"
  set Name $Parent.f1.e15
ttk::checkbutton $Name -text "" -variable mysql_refresh_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18 -sticky w
if {$mysql_refresh_on == "false" } {
	$Name configure -state disabled
	}
}
   set Name $Parent.b2
   ttk::button $Name -command {destroy .mytpch} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3

   set Name $Parent.b1
   ttk::button $Name -command {
         set mysql_host [.mytpch.f1.e1 get]
         set mysql_port [.mytpch.f1.e2 get]
	   set mysql_tpch_user [.mytpch.f1.e3 get]
	   set mysql_tpch_pass [.mytpch.f1.e4 get]
   	   set mysql_tpch_dbase [.mytpch.f1.e5 get]
if { $option eq "all" || $option eq "build" } {
	   set mysql_tpch_storage_engine [.mytpch.f1.e6 get]
   }
if { $option eq "all" || $option eq "drive" } {
   	    set mysql_total_querysets [.mytpch.f1.e9 get]
   	    set mysql_update_sets [.mytpch.f1.e13 get]
   	    set mysql_trickle_refresh [.mytpch.f1.e14 get]
     }	
         destroy .mytpch 
        } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3
   wm geometry .mytpch +50+50
   wm deiconify .mytpch
   raise .mytpch
   update
}

proc configmssqlstpch {option} {
global mssqls_server mssqls_port mssqls_scale_fact mssqls_maxdop mssqls_authentication mssqls_odbc_driver mssqls_uid mssqls_pass mssqls_tpch_dbase mssqls_num_tpch_threads mssqls_refresh_on mssqls_total_querysets mssqls_raise_query_error mssqls_verbose mssqls_update_sets mssqls_trickle_refresh mssqls_refresh_verbose boxes driveroptlo defaultBackground defaultForeground
if {  ![ info exists mssqls_server ] } { set mssqls_server "(local)" }
if {  ![ info exists mssqls_port ] } { set mssqls_port "1433" }
if {  ![ info exists mssqls_scale_fact ] } { set mssqls_scale_fact "1" }
if {  ![ info exists mssqls_maxdop ] } { set mssqls_maxdop "2" }
if {  ![ info exists mssqls_authentication ] } { set mssqls_authentication "windows" }
if {  ![ info exists mssqls_odbc_driver ] } { set mssqls_odbc_driver "SQL Server Native Client 10.0" }
if {  ![ info exists mssqls_uid ] } { set mssqls_uid "sa" }
if {  ![ info exists mssqls_pass ] } { set mssqls_pass "admin" }
if {  ![ info exists mssqls_tpch_dbase ] } { set mssqls_tpch_dbase "tpch" }
if {  ![ info exists mssqls_num_tpch_threads ] } { set mssqls_num_tpch_threads "1" }
if {  ![ info exists mssqls_refresh_on ] } { set  mssqls_refresh_on "false" }
if {  ![ info exists mssqls_total_querysets ] } { set mssqls_total_querysets "1" }
if {  ![ info exists mssqls_raise_query_error ] } { set mssqls_raise_query_error "false" }
if {  ![ info exists mssqls_verbose ] } { set mssqls_verbose "false" }
if {  ![ info exists mssqls_update_sets ] } { set mssqls_update_sets "1" }
if {  ![ info exists mssqls_trickle_refresh ] } { set mssqls_trickle_refresh "1000" }
if {  ![ info exists mssqls_refresh_verbose ] } { set mssqls_refresh_verbose "false" }
global _ED
   catch "destroy .mssqlstpch"
   ttk::toplevel .mssqlstpch
   wm withdraw .mssqlstpch
switch $option {
"all" { wm title .mssqlstpch {SQL Server TPC-H Schema Options} }
"build" { wm title .mssqlstpch {SQL Server TPC-H Build Options} }
"drive" {  wm title .mssqlstpch {SQL Server TPC-H Driver Options} }
	}
   set Parent .mssqlstpch
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $boxes]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
 set Name $Parent.f1.e1
 set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "SQL Server :"
   ttk::entry $Name -width 30 -textvariable mssqls_server
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "SQL Server Port :"
   ttk::entry $Name  -width 30 -textvariable mssqls_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
   set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "SQL Server ODBC Driver :"
   ttk::entry $Name  -width 30 -textvariable mssqls_odbc_driver
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Prompt $Parent.f1.pa
ttk::label $Prompt -text "Authentication :"
grid $Prompt -column 0 -row 4 -sticky e
set Name $Parent.f1.r1
ttk::radiobutton $Name -value "windows" -text "Windows Authentication" -variable mssqls_authentication
grid $Name -column 1 -row 4 -sticky w
bind .mssqlstpch.f1.r1 <ButtonPress-1> {
.mssqlstpch.f1.e4 configure -state disabled
.mssqlstpch.f1.e5 configure -state disabled
}
set Name $Parent.f1.r2
ttk::radiobutton $Name -value "sql" -text "SQL Server Authentication" -variable mssqls_authentication
grid $Name -column 1 -row 5 -sticky w
bind .mssqlstpch.f1.r2 <ButtonPress-1> {
.mssqlstpch.f1.e4 configure -state normal
.mssqlstpch.f1.e5 configure -state normal
}
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "SQL Server User ID :"
   ttk::entry $Name  -width 30 -textvariable mssqls_uid
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
if {$mssqls_authentication == "windows" } {
        $Name configure -state disabled
        }
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "SQL Server User Password :"
   ttk::entry $Name  -width 30 -textvariable mssqls_pass
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
if {$mssqls_authentication == "windows" } {
        $Name configure -state disabled
        }
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
   ttk::label $Prompt -text "SQL Server TPCH Database :"
   ttk::entry $Name -width 30 -textvariable mssqls_tpch_dbase
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky ew
 set Name $Parent.f1.e6a
   set Prompt $Parent.f1.p6a
   ttk::label $Prompt -text "MAXDOP :"
   ttk::entry $Name -width 30 -textvariable mssqls_maxdop
   grid $Prompt -column 0 -row 9 -sticky e
   grid $Name -column 1 -row 9  -columnspan 4 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7 
   ttk::label $Prompt -text "Scale Factor :"
   grid $Prompt -column 0 -row 10 -sticky e
   set Name $Parent.f1.f2
   ttk::frame $Name -width 30
   grid $Name -column 1 -row 10 -sticky ew
	set rcnt 1
	foreach item {1} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable mssqls_scale_fact -text $item -value $item -width 1
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 2
	foreach item {10 30} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable mssqls_scale_fact -text $item -value $item -width 2
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 4
	foreach item {100 300} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable mssqls_scale_fact -text $item -value $item -width 3
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 6
	foreach item {1000} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable mssqls_scale_fact -text $item -value $item -width 4
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
set Prompt $Parent.f1.p8
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e8
	scale $Name -orient horizontal -variable mssqls_num_tpch_threads -from 1 -to 256 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
	grid $Prompt -column 0 -row 11 -sticky e
	grid $Name -column 1 -row 11 -sticky ew
	}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 12 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 12 -sticky w
	}
   set Name $Parent.f1.e9
   set Prompt $Parent.f1.p9
   ttk::label $Prompt -text "Total Query Sets per User :"
   ttk::entry $Name -width 30 -textvariable mssqls_total_querysets
   grid $Prompt -column 0 -row 13 -sticky e
   grid $Name -column 1 -row 13  -columnspan 4 -sticky ew
 set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Exit on SQL Server Error :"
  set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable mssqls_raise_query_error -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14 -sticky w
 set Prompt $Parent.f1.p11
ttk::label $Prompt -text "Verbose Output :"
  set Name $Parent.f1.e11
ttk::checkbutton $Name -text "" -variable mssqls_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky w
 set Prompt $Parent.f1.p12
ttk::label $Prompt -text "Refresh Function :"
  set Name $Parent.f1.e12
ttk::checkbutton $Name -text "" -variable mssqls_refresh_on -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16 -sticky w
bind $Parent.f1.e12 <Button> {
if {$mssqls_refresh_on eq "true"} { 
set mssqls_refresh_verbose "false"
foreach field {e13 e14 e15} {
.mssqlstpch.f1.$field configure -state disabled 
		}
} else {
foreach field {e13 e14 e15} {
.mssqlstpch.f1.$field configure -state normal
                        }
                }
	}
   set Name $Parent.f1.e13
   set Prompt $Parent.f1.p13
   ttk::label $Prompt -text "Number of Update Sets :"
   ttk::entry $Name -width 30 -textvariable mssqls_update_sets
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17  -columnspan 4 -sticky ew
if {$mssqls_refresh_on == "false" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable mssqls_trickle_refresh
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18  -columnspan 4 -sticky ew
if {$mssqls_refresh_on == "false" } {
	$Name configure -state disabled
	}
 set Prompt $Parent.f1.p15
ttk::label $Prompt -text "Refresh Verbose :"
  set Name $Parent.f1.e15
ttk::checkbutton $Name -text "" -variable mssqls_refresh_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19 -sticky w
if {$mssqls_refresh_on == "false" } {
	$Name configure -state disabled
	}
}
   set Name $Parent.b2
   ttk::button $Name -command {destroy .mssqlstpch} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3

   set Name $Parent.b1
   ttk::button $Name -command {
         set mssqls_server [.mssqlstpch.f1.e1 get]
         set mssqls_port [.mssqlstpch.f1.e2 get]
	 set mssqls_odbc_driver [.mssqlstpch.f1.e3 get]
	 set mssqls_uid [.mssqlstpch.f1.e4 get]
   	 set mssqls_pass [.mssqlstpch.f1.e5 get]
   	 set mssqls_tpch_dbase [.mssqlstpch.f1.e6 get]
   	 set mssqls_maxdop [.mssqlstpch.f1.e6a get]
if { $option eq "all" || $option eq "drive" } {
   	    set mssqls_total_querysets [.mssqlstpch.f1.e9 get]
   	    set mssqls_update_sets [.mssqlstpch.f1.e13 get]
   	    set mssqls_trickle_refresh [.mssqlstpch.f1.e14 get]
     }	
         destroy .mssqlstpch 
        } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3
   wm geometry .mssqlstpch +50+50
   wm deiconify .mssqlstpch
   raise .mssqlstpch
   update
}

proc configpgtpch {option} {
global pg_host pg_port pg_scale_fact pg_tpch_superuser pg_tpch_superuserpass pg_tpch_defaultdbase pg_tpch_user pg_tpch_pass pg_tpch_dbase pg_tpch_gpcompat pg_tpch_gpcompress pg_num_tpch_threads pg_total_querysets pg_raise_query_error pg_verbose pg_refresh_on pg_update_sets pg_trickle_refresh pg_refresh_verbose boxes driveroptlo defaultBackground defaultForeground
if {  ![ info exists pg_host ] } { set pg_host "localhost" }
if {  ![ info exists pg_port ] } { set pg_port "5432" }
if {  ![ info exists pg_scale_fact ] } { set pg_scale_fact "1" }
if {  ![ info exists pg_tpch_superuser ] } { set pg_tpch_superuser "postgres" }
if {  ![ info exists pg_tpch_superuserpass ] } { set pg_tpch_superuserpass "postgres" }
if {  ![ info exists pg_tpch_defaultdbase ] } { set pg_tpch_defaultdbase "postgres" }
if {  ![ info exists pg_tpch_user ] } { set pg_tpch_user "tpch" }
if {  ![ info exists pg_tpch_pass ] } { set pg_tpch_pass "tpch" }
if {  ![ info exists pg_tpch_dbase ] } { set pg_tpch_dbase "tpch" }
if {  ![ info exists pg_tpch_gpcompat ] } { set pg_tpch_gpcompat "false" }
if {  ![ info exists pg_tpch_gpcompress ] } { set pg_tpch_gpcompress "false" }
if {  ![ info exists pg_num_tpch_threads ] } { set pg_num_tpch_threads "1" }
if {  ![ info exists pg_refresh_on ] } { set  pg_refresh_on "false" }
if {  ![ info exists pg_total_querysets ] } { set pg_total_querysets "1" }
if {  ![ info exists pg_raise_query_error ] } { set pg_raise_query_error "false" }
if {  ![ info exists pg_verbose ] } { set pg_verbose "false" }
if {  ![ info exists pg_update_sets ] } { set pg_update_sets "1" }
if {  ![ info exists pg_trickle_refresh ] } { set pg_trickle_refresh "1000" }
if {  ![ info exists pg_refresh_verbose ] } { set pg_refresh_verbose "false" }
global _ED
   catch "destroy .pgtpch"
   ttk::toplevel .pgtpch
   wm withdraw .pgtpch
switch $option {
"all" { wm title .pgtpch {PostgreSQL TPC-H Schema Options} }
"build" { wm title .pgtpch {PostgreSQL TPC-H Build Options} }
"drive" {  wm title .pgtpch {PostgreSQL TPC-H Driver Options} }
	}
   set Parent .pgtpch
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [image create photo -data $boxes]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Build Options"
grid $Prompt -column 1 -row 0 -sticky w
	} else {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 0 -sticky w
	}
 set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "PostgreSQL Host :"
   ttk::entry $Name -width 30 -textvariable pg_host
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "PostgreSQL Port :"
   ttk::entry $Name  -width 30 -textvariable pg_port
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "PostgreSQL Superuser :"
   ttk::entry $Name  -width 30 -textvariable pg_tpch_superuser
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew
set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "PostgreSQL Superuser Password :"
   ttk::entry $Name  -width 30 -textvariable pg_tpch_superuserpass
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew
set Name $Parent.f1.e5
   set Prompt $Parent.f1.p5
   ttk::label $Prompt -text "PostgreSQL Default Database :"
   ttk::entry $Name -width 30 -textvariable pg_tpch_defaultdbase
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5 -sticky ew
	}
set Name $Parent.f1.e6
   set Prompt $Parent.f1.p6
 ttk::label $Prompt -text "PostgreSQL User :"
   ttk::entry $Name  -width 30 -textvariable pg_tpch_user
   grid $Prompt -column 0 -row 6 -sticky e
   grid $Name -column 1 -row 6 -sticky ew
set Name $Parent.f1.e7
   set Prompt $Parent.f1.p7
   ttk::label $Prompt -text "PostgreSQL User Password :"
   ttk::entry $Name  -width 30 -textvariable pg_tpch_pass
   grid $Prompt -column 0 -row 7 -sticky e
   grid $Name -column 1 -row 7 -sticky ew
set Name $Parent.f1.e8
   set Prompt $Parent.f1.p8
   ttk::label $Prompt -text "PostgreSQL Database :"
   ttk::entry $Name -width 30 -textvariable pg_tpch_dbase
   grid $Prompt -column 0 -row 8 -sticky e
   grid $Name -column 1 -row 8 -sticky ew
if { $option eq "all" || $option eq "build" } {
set Prompt $Parent.f1.p9
ttk::label $Prompt -text "Greenplum Database Compatible :"
set Name $Parent.f1.e9
ttk::checkbutton $Name -text "" -variable pg_tpch_gpcompat -onvalue "true" -offvalue "false"
bind $Parent.f1.e9 <Button> {
if {$pg_tpch_gpcompat eq "true"} { 
.pgtpch.f1.e10 configure -state disabled 
set pg_tpch_gpcompress "false"
} else {
.pgtpch.f1.e10 configure -state normal
                }
	}
   grid $Prompt -column 0 -row 9 -sticky e
   grid $Name -column 1 -row 9 -sticky w
set Prompt $Parent.f1.p10
ttk::label $Prompt -text "Greenplum Compressed Columns :"
set Name $Parent.f1.e10
ttk::checkbutton $Name -text "" -variable pg_tpch_gpcompress -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 10 -sticky e
   grid $Name -column 1 -row 10 -sticky w
if {$pg_tpch_gpcompat == "false" } {
	$Name configure -state disabled
	}
set Name $Parent.f1.e11
   set Prompt $Parent.f1.p11
   ttk::label $Prompt -text "Scale Factor :"
   grid $Prompt -column 0 -row 11 -sticky e
   set Name $Parent.f1.f2
   ttk::frame $Name -width 30
   grid $Name -column 1 -row 11 -sticky ew
	set rcnt 1
	foreach item {1} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable pg_scale_fact -text $item -value $item -width 1
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 2
	foreach item {10 30} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable pg_scale_fact -text $item -value $item -width 2
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 4
	foreach item {100 300} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable pg_scale_fact -text $item -value $item -width 3
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 6
	foreach item {1000} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable pg_scale_fact -text $item -value $item -width 4
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
set Prompt $Parent.f1.p12
ttk::label $Prompt -text "Virtual Users to Build Schema :"
set Name $Parent.f1.e12
	scale $Name -orient horizontal -variable pg_num_tpch_threads -from 1 -to 256 -length 190 -highlightbackground $defaultBackground -background $defaultBackground -foreground $defaultForeground
	grid $Prompt -column 0 -row 12 -sticky e
	grid $Name -column 1 -row 12 -sticky ew
	}
if { $option eq "all" || $option eq "drive" } {
if { $option eq "all" } {
set Prompt $Parent.f1.h3
ttk::label $Prompt -image [image create photo -data $driveroptlo]
grid $Prompt -column 0 -row 13 -sticky e
set Prompt $Parent.f1.h4
ttk::label $Prompt -text "Driver Options"
grid $Prompt -column 1 -row 13 -sticky w
	}
   set Name $Parent.f1.e14
   set Prompt $Parent.f1.p14
   ttk::label $Prompt -text "Total Query Sets per User :"
   ttk::entry $Name -width 30 -textvariable pg_total_querysets
   grid $Prompt -column 0 -row 14 -sticky e
   grid $Name -column 1 -row 14  -columnspan 4 -sticky ew
 set Prompt $Parent.f1.p15
ttk::label $Prompt -text "Exit on PostgreSQL Error :"
  set Name $Parent.f1.e15
ttk::checkbutton $Name -text "" -variable pg_raise_query_error -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 15 -sticky e
   grid $Name -column 1 -row 15 -sticky w
 set Prompt $Parent.f1.p16
ttk::label $Prompt -text "Verbose Output :"
  set Name $Parent.f1.e16
ttk::checkbutton $Name -text "" -variable pg_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 16 -sticky e
   grid $Name -column 1 -row 16 -sticky w
 set Prompt $Parent.f1.p17
ttk::label $Prompt -text "Refresh Function :"
  set Name $Parent.f1.e17
ttk::checkbutton $Name -text "" -variable pg_refresh_on -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 17 -sticky e
   grid $Name -column 1 -row 17 -sticky w
bind $Parent.f1.e17 <Button> {
if {$pg_refresh_on eq "true"} { 
set pg_refresh_verbose "false"
foreach field {e18 e19 e20} {
.pgtpch.f1.$field configure -state disabled 
		}
} else {
foreach field {e18 e19 e20} {
.pgtpch.f1.$field configure -state normal
                        }
                }
	}
   set Name $Parent.f1.e18
   set Prompt $Parent.f1.p18
   ttk::label $Prompt -text "Number of Update Sets :"
   ttk::entry $Name -width 30 -textvariable pg_update_sets
   grid $Prompt -column 0 -row 18 -sticky e
   grid $Name -column 1 -row 18  -columnspan 4 -sticky ew
if {$pg_refresh_on == "false" } {
	$Name configure -state disabled
	}
   set Name $Parent.f1.e19
   set Prompt $Parent.f1.p19
   ttk::label $Prompt -text "Trickle Refresh Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable pg_trickle_refresh
   grid $Prompt -column 0 -row 19 -sticky e
   grid $Name -column 1 -row 19  -columnspan 4 -sticky ew
if {$pg_refresh_on == "false" } {
	$Name configure -state disabled
	}
 set Prompt $Parent.f1.p20
ttk::label $Prompt -text "Refresh Verbose :"
  set Name $Parent.f1.e20
ttk::checkbutton $Name -text "" -variable pg_refresh_verbose -onvalue "true" -offvalue "false"
   grid $Prompt -column 0 -row 20 -sticky e
   grid $Name -column 1 -row 20 -sticky w
if {$pg_refresh_on == "false" } {
	$Name configure -state disabled
	}
}
   set Name $Parent.b2
   ttk::button $Name -command {destroy .pgtpch} -text Cancel
   pack $Name -anchor nw -side right -padx 3 -pady 3
   set Name $Parent.b1
   ttk::button $Name -command {
         set pg_host [.pgtpch.f1.e1 get]
         set pg_port [.pgtpch.f1.e2 get]
if { $option eq "all" || $option eq "build" } {
	 set pg_tpch_superuser [.pgtpch.f1.e3 get]
 	 set pg_tpch_superuserpass [.pgtpch.f1.e4 get]
 	 set pg_tpch_defaultdbase [.pgtpch.f1.e5 get]
   }
	 set pg_tpch_user [.pgtpch.f1.e6 get]
	 set pg_tpch_pass [.pgtpch.f1.e7 get]
   	 set pg_tpch_dbase [.pgtpch.f1.e8 get]
if { $option eq "all" || $option eq "drive" } {
   	 set pg_total_querysets [.pgtpch.f1.e14 get]
   	 set pg_update_sets [.pgtpch.f1.e18 get]
   	 set pg_trickle_refresh [.pgtpch.f1.e19 get]
     }	
         destroy .pgtpch 
        } -text {OK}
   pack $Name -anchor nw -side right -padx 3 -pady 3
   wm geometry .pgtpch +50+50
   wm deiconify .pgtpch
   raise .pgtpch
   update
}

font create basic -family arial -size 10
bind Entry <BackSpace> {tkEntryBackspace %W}
