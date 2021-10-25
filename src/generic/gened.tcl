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

proc ed_start_gui { dbdict icons iconalt } {
global _ED rdbms bm ed_mainf tcl_platform succ fail vus repeat task run clo masterthread table opmode masterlist autopilot apmode win_scale_fact treewidth tabix tabiy mainx mainy mainminx mainminy mainmaxx mainmaxy treebuild pop_treel
   set opmode "Local"
   ttk::toplevel .ed_mainFrame
   wm withdraw .ed_mainFrame
   wm title .ed_mainFrame "HammerDB"
   wm geometry .ed_mainFrame +100+100
   set Parent .ed_mainFrame
   set masterlist ""
#SVG images in notebook causes segfault. Use manual png scaling
   if { $win_scale_fact <= 1.5 } {
   set dfx 1x
   	} elseif { $win_scale_fact <= 3.0 } {
   set dfx 2x
	} elseif { $win_scale_fact <= 4.0 } {
   set dfx 3x
	} else {
   set dfx 4x
	}
   set windock [ dict get $icons windock-$dfx ]
   image create photo ::img::dock -data $windock
   set winundock [ dict get $icons winundock-$dfx ]
   image create photo ::img::undock -data $winundock

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

proc pop_up_menu {} {
#toggle vertical edit menu
    global menu_state
set Name .ed_mainFrame.editbuttons
if { ![info exists menu_state] } { set menu_state 0}
    if {$menu_state == 1} {
        pack forget $Name
        set menu_state 0
    } else {
   pack $Name -anchor nw -side left -expand 0 -fill x -ipadx 0 -ipady 0  -padx 0 -pady {3 3} -after .ed_mainFrame.buttons
        set menu_state 1
raise $Name
update
    }
}

   construct_menu $Name Edit $Menu_string($Name)

   set Name $Parent.menuframe.tpcc
   set Menu_string($Name) {
	{{command}  {Benchmark} {-command "select_rdbms none" -underline 0}}
      {{cascade}  {TPROC-C Schema} {{{command}  {Build} {-command "configtpcc build" -underline 0}} {{command}  {Driver} {-command "configtpcc drive" -underline 0}} {{command}  {Load Driver} {-command "loadtpcc" -underline 0}}}}
      {{cascade}  {TPROC-H Schema} {{{command}  {Build} {-command "configtpch build" -underline 0}} {{command}  {Driver} {-command "configtpch drive" -underline 0}} {{command}  {Load Driver} {-command "loadtpch" -underline 0}}}}
      {{command}  {Virtual User} {-command "vuser_options" -underline 1}}
	{{command}  {Autopilot} {-command "autopilot_options" -underline 0}}
	{{command}  {Transaction Counter} {-command "countopts" -underline 0}}
      {{command}  {Metrics} {-command "metricsopts" -underline 0}}
      {{command}  {Mode} {-command "select_mode" -underline 0}}
      {{command}  {Datagen} {-command "dgopts" -underline 0}}
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

   set Name $Parent.editbuttons
   ttk::frame $Name 

construct_button $Parent.editbuttons.console edit ctext console.gif "convert_to_oratcl" "Convert Trace to Oratcl" 
construct_button $Parent.editbuttons.distribute edit distribute distribute.ppm "distribute" "Primary Distribution" 
$Parent.editbuttons.distribute configure -state disabled
#placeholder button for persistent saving of Xml options to database
#construct_button $Parent.editbuttons.savexml edit savexml savexml.ppm "xmlopts" "Save Configuration"
construct_button $Parent.editbuttons.test edit test test.ppm "ed_run_package" "Test Tcl code"
construct_button $Parent.editbuttons.search edit search search.ppm "ed_edit_searchf" "Search in text"
construct_button $Parent.editbuttons.paste edit paste paste.ppm "ed_edit_paste" "Paste selected text"
construct_button $Parent.editbuttons.copy edit copy copy.ppm "ed_edit_copy" "Copy selected text"
construct_button $Parent.editbuttons.cut edit cut cut.ppm "ed_edit_cut" "Cut selected text"
construct_button $Parent.editbuttons.save edit save save.ppm "ed_file_save" "Save current file"
construct_button $Parent.editbuttons.load edit open open.ppm "ed_file_load" "Open existing file"
construct_button $Parent.editbuttons.clear edit new new.ppm "ed_edit_clear" "Clear the screen"
set Parent .ed_mainFrame
construct_button $Parent.buttons.hmenu bar hmenu new.ppm "pop_up_menu"  "Open Edit Menu"
construct_button $Parent.buttons.boxes bar boxes boxes.ppm "build_schema" "Create TPROC Schema" 
construct_button $Parent.buttons.drive bar driveroptim drive.ppm {if {$bm eq "TPROC-C"} {loadtpcc} else {loadtpch} } "Load Driver Script" 
construct_button $Parent.buttons.lvuser bar lvuser arrow.ppm "remote_command load_virtual; load_virtual" "Create Virtual Users" 
construct_button $Parent.buttons.runworld bar runworld world.ppm "remote_command run_virtual; run_virtual" "Run Virtual Users" 
construct_button $Parent.buttons.autopilot bar autopilot autopilot.ppm "start_autopilot" "Start Autopilot" 
.ed_mainFrame.buttons.autopilot configure -state disabled
construct_button $Parent.buttons.pencil bar pencil pencil.ppm "transcount" "Start Transaction Counter" 
construct_button $Parent.buttons.dashboard bar dashboard dashboard.ppm "metrics" "Start Metrics" 
construct_button $Parent.buttons.mode bar mode mode.ppm "select_mode" "Mode" 
construct_button $Parent.buttons.datagen bar datagen datagen.ppm "run_datagen" "Generate TPROC Data" 
#bindtags to call to prevent highlighting of buttons when status changed
bind BreakTag <Enter> {break}
bind BreakTag2 <Leave> {break}

foreach { tbicname } { succ fail vus run clo repeat task } { tbicon } { tick cross oneuser running clock repeat task } { set $tbicname [ create_image $tbicon icons ] }

set Name $Parent.panedwin
   if { $ttk::currentTheme eq "clearlooks" } {
   panedwindow $Name -orient horizontal -handlesize 8 -background [ dict get $icons defaultBackground ] } else {
   if { $ttk::currentTheme in {arc breeze awlight} } {
   panedwindow $Name -orient horizontal -background [ dict get $icons defaultBackground ] } else {
   panedwindow $Name -orient horizontal -showhandle true
   	  }
	}
   pack $Name -expand yes -fill both

   set Name $Parent.panedwin.subpanedwin
   if { $ttk::currentTheme eq "clearlooks" } {
   panedwindow $Name -orient vertical -handlesize 8 -background [ dict get $icons defaultBackground ]} else {
   if { $ttk::currentTheme in {arc breeze awlight} } {
   panedwindow $Name -orient vertical -background [ dict get $icons defaultBackground ]} else {
   panedwindow $Name -orient vertical -showhandle true
   	  }
	}
   pack $Name -expand yes -fill both

set Name $Parent.treeframe
ttk::frame $Name
pack $Name -anchor sw -expand 1 -fill both -side left
$Parent.panedwin add $Name -minsize 1i
ttk::scrollbar $Parent.treeframe.vbar -orient vertical -command "$Parent.treeframe.treeview yview"
 pack $Parent.treeframe.vbar -anchor center -expand 0 -fill y -ipadx 0 -ipady 0 \
         -padx 0 -pady 0 -side right
set Name $Parent.treeframe.treeview
ttk::treeview $Name -yscrollcommand "$Parent.treeframe.vbar set" -selectmode browse -show [ list tree headings ] 
$Name column #0 -stretch 1 -minwidth 1 -width $treewidth
$Name heading #0 -text "Benchmark"
$Name configure -padding {0 0 0 0}
pack $Name -side left -anchor w -expand 1 -fill both 
#Extract list of databases passed from configuration file
dict for {database attributes} $dbdict {
dict with attributes {
lappend dbl $name
lappend txtl $description
lappend prefixl $prefix
foreach { wk } $workloads {
lappend pop_treel $name $wk
	}
    }
}
#set default database and bm
set rdbms [ lindex $pop_treel 0 ]
set bm [ lindex $pop_treel 1 ]
#Use list to make the command to build tree
set treebuild ""
foreach {db} $dbl {txt} $txtl {prefix} $prefixl {
set prefix [ join "$prefix opt" "" ]
set prefix2 [ join "$prefix 2" "" ]
append treebuild [ subst {$Name insert {} end -id $db -text "$txt"} ] "\n"
append treebuild [ subst {$Name item $db -tags {$prefix $prefix2}} ] "\n"
append treebuild [ subst -nocommands {$Name tag bind $prefix <Double-ButtonPress-1>  { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if { \$rdbms != "$db" } { select_rdbms "$db" } } }} ] "\n"
append treebuild [ subst -nocommands {$Name tag bind $prefix2 <Double-ButtonPress-3>  { if { !([ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] || [ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled hover" ]) } { if { \$rdbms eq "$db" } {\n.ed_mainFrame.treeframe.treeview selection set $db\nselect_rdbms "$db" } } } }] "\n"
}
#Build tree
eval $treebuild
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
global tabix tabiy
    set tabindex [lindex [$notebook tabs] $index]
    set tabname [ lindex [ split [ $notebook select ] "." ] end ]
if [ string match "*-state normal*" [ $notebook tab $index ] ] {  set tabactive "true" } else { set tabactive "false" }
if { $tabname eq "tc" || $tabname eq "me" } {
if { $tabactive } {
    set title [$notebook tab $index -text]
    $notebook forget $index
    wm manage $tabindex
    wm title $tabindex $title
    wm geometry $tabindex ${tabix}x${tabiy}+30+30
    wm minsize $tabindex $tabix $tabiy
if { $tabname eq "tc" } {
    wm maxsize $tabindex $tabix $tabiy
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
global win_scale_fact
upvar #0 icons icons
   if { $win_scale_fact <= 1.5 } {
   set dfx 1x
   	} elseif { $win_scale_fact <= 3.0 } {
   set dfx 2x
	} elseif { $win_scale_fact <= 4.0 } {
   set dfx 3x
	} else {
   set dfx 4x
	}
set windock [ dict get $icons windock-$dfx ]
image create photo ::img::dock -data $windock 
set winundock [ dict get $icons winundock-$dfx ]
image create photo ::img::undock -data $winundock
set tabcount [ llength [ $notebook tabs ] ]
set tabname [ lindex [ split $tab "." ] end ]
#metrics window always goes one in from end
if { $tabname eq "me" } { set index [ expr $tabcount - 1 ] }
    set title [wm title $tab]
    wm forget $tab
    if {[catch {
        if {[catch {$notebook insert $index $tab -text $title -compound right -image [list ::img::dock \
                     {active pressed focus !disabled} ::img::dock \
                     {active !disabled} ::img::undock] -compound right
	} err]} {
            $notebook add $tab -text $title
        }
        $notebook select $tab
    } err]} {
        wm manage $w
        wm title $w $title
    }
}
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
                     {active !disabled} ::img::undock] -compound right
   $Name add [ tk::frame $Parent.ap ] -text "Autopilot" -state disabled
   ttk::notebook::enableTraversal $Name
   set pminunit [ expr {$mainy / 10} ] 
   $Parent.panedwin.subpanedwin add $Name -minsize [ expr $pminunit * 4.60 ] -stretch always
   $Parent.panedwin add $Parent.panedwin.subpanedwin -minsize [ expr $pminunit * 4.60 ]

   set Name $Parent.vuserframe
   ttk::frame $Name
   $Parent.panedwin.subpanedwin add $Name -minsize [ expr $pminunit * 2.0 ] -stretch never
   set table [ tablist $Name ]
   #Sizing for the lowersubpanedwin is in the tkcon module
   tkcon show

   set Name $Parent.buttons.statl15
   ttk::label $Name -text " " 
   pack $Name -anchor nw -side left -expand 0  -fill x 

   set Name $Parent.buttons.statl15a
   ttk::label $Name -text "  " 
   pack $Name -anchor nw -side right -expand 0  -fill x

   set Name $Parent.buttons.statusframe
   frame $Name  -background [ dict get $icons defaultBackground ] -borderwidth 0 -relief flat 
   pack $Name -anchor nw -side right -expand 0  -fill x

   set Name $Parent.buttons.statusframe.currentstatus
   set _ED(status_widget) $Name
   ttk::label $Name  -background [ dict get $icons defaultBackground ] -foreground [ dict get $icons defaultForeground ] -justify right -textvariable _ED(status) -relief flat 
   pack $Name -anchor e

foreach { db bn } $pop_treel {
        populate_tree $db $bn $icons $iconalt
        }

   wm geometry .ed_mainFrame ${mainx}x${mainy}+30+30
   if {$tcl_platform(platform) == "windows"} {set y 0}
   wm minsize .ed_mainFrame $mainminx $mainminy
}

proc populate_tree {rdbms bm icons iconalt} {
set Name .ed_mainFrame.treeframe.treeview
global selected lastselected treeidicons
set lastselected [ .ed_mainFrame.treeframe.treeview selection ]
bind .ed_mainFrame.treeframe.treeview <<TreeviewSelect>> { 
set selected [ .ed_mainFrame.treeframe.treeview selection ] 
if { [ dict exists $treeidicons $lastselected ] } {
set unhighlighticon [ dict get $treeidicons $lastselected ]
.ed_mainFrame.treeframe.treeview item $lastselected -image [ create_image $unhighlighticon icons ]
	}
if { [ dict exists $treeidicons $selected ] } {
set highlighticon [ dict get $treeidicons $selected ]
.ed_mainFrame.treeframe.treeview item $selected -image  [ create_image $highlighticon iconalt ]
	}
set lastselected $selected
}
bind .ed_mainFrame.treeframe.treeview <Leave> { ed_status_message -perm }
$Name insert $rdbms end -id $rdbms.$bm -text [ regsub -all {(TP)(C)(-[CH])} $bm {\1RO\2\3} ] -image [ create_image hdbicon icons ]
dict set treeidicons $rdbms.$bm hdbicon
$Name insert $rdbms.$bm end -id $rdbms.$bm.build -text "Schema Build" -image [ create_image boxes icons ]
dict set treeidicons $rdbms.$bm.build boxes
$Name item $rdbms.$bm.build -tags $rdbms.$bm.buildhlp
tooltip::tooltip $Name -item $rdbms.$bm.build "Configure and Build $rdbms $bm Schema"
$Name insert $rdbms.$bm.build end -id $rdbms.$bm.build.schema -text "Options" -image [ create_image option icons ] 
dict set treeidicons $rdbms.$bm.build.schema option
$Name item $rdbms.$bm.build.schema -tags {buildopt}
tooltip::tooltip $Name -item $rdbms.$bm.build.schema "$rdbms $bm Schema Options"
$Name tag bind buildopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if {$bm eq "TPC-C"} {configtpcc build } else {configtpch build } } }    
$Name insert $rdbms.$bm.build end -id $rdbms.$bm.build.go -text "Build" -image [ create_image boxes icons ]
dict set treeidicons $rdbms.$bm.build.go boxes
$Name item $rdbms.$bm.build.go -tags builsch
tooltip::tooltip $Name -item $rdbms.$bm.build.go "Create $rdbms $bm Schema"
$Name tag bind builsch <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { build_schema } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.driver -text "Driver Script" -image [ create_image driveroptim icons ]
dict set treeidicons $rdbms.$bm.driver driveroptim
$Name item $rdbms.$bm.driver -tags {drvhlp}
tooltip::tooltip $Name -item $rdbms.$bm.driver "Configure and Load $rdbms $bm Driver Script"
$Name insert $rdbms.$bm.driver end -id $rdbms.$bm.driver.schema -text "Options" -image [ create_image option icons ] 
dict set treeidicons $rdbms.$bm.driver.schema option
$Name item $rdbms.$bm.driver.schema -tags drvopt
tooltip::tooltip $Name -item $rdbms.$bm.driver.schema "$rdbms $bm Driver Script Options"
$Name tag bind drvopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if {$bm eq "TPC-C"} {configtpcc drive } else {configtpch drive} } }
$Name insert $rdbms.$bm.driver end -id $rdbms.$bm.driver.load -text "Load" -image [ create_image driveroptlo icons ] 
dict set treeidicons $rdbms.$bm.driver.load driveroptlo
$Name item $rdbms.$bm.driver.load -tags drvscr
tooltip::tooltip $Name -item $rdbms.$bm.driver.load "Load $rdbms $bm Driver Script"
$Name tag bind drvscr <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { if {$bm eq "TPC-C"} {loadtpcc} else {loadtpch} } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.vusers -text "Virtual User" -image [ create_image vuseroptim icons ]
dict set treeidicons $rdbms.$bm.vusers vuseroptim
$Name item $rdbms.$bm.vusers -tags {vuserhlp}
tooltip::tooltip $Name -item $rdbms.$bm.vusers "Configure and Load Virtual Users"
$Name insert $rdbms.$bm.vusers end -id $rdbms.$bm.vusers.options -text "Options" -image [ create_image option icons ] 
dict set treeidicons $rdbms.$bm.vusers.options option
$Name item $rdbms.$bm.vusers.options -tags vuseopt
tooltip::tooltip $Name -item $rdbms.$bm.vusers.options "Virtual User Options"
$Name tag bind vuseopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } {vuser_options } }
$Name insert $rdbms.$bm.vusers end -id $rdbms.$bm.vusers.load -text "Create" -image [ create_image lvuser icons ]
dict set treeidicons $rdbms.$bm.vusers.load lvuser
$Name item $rdbms.$bm.vusers.load -tags vuseload
tooltip::tooltip $Name -item $rdbms.$bm.vusers.load "Create Virtual Users"
$Name tag bind vuseload <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { .ed_mainFrame.buttons.lvuser invoke } }
$Name insert $rdbms.$bm.vusers end -id $rdbms.$bm.vusers.run -text "Run" -image [ create_image runworld icons ] 
dict set treeidicons $rdbms.$bm.vusers.run runworld
$Name item $rdbms.$bm.vusers.run -tags vuserun
tooltip::tooltip $Name -item $rdbms.$bm.vusers.run "Run Virtual Users"
$Name tag bind vuserun <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { .ed_mainFrame.buttons.runworld invoke } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.autopilot -text "Autopilot" -image [ create_image autopilot icons ]
dict set treeidicons $rdbms.$bm.autopilot autopilot
$Name item $rdbms.$bm.autopilot -tags {autohlp}
tooltip::tooltip $Name -item $rdbms.$bm.autopilot "Configure and Run Autopilot"
$Name insert $rdbms.$bm.autopilot end -id $rdbms.$bm.autopilot.options -text "Options" -image [ create_image option icons ] 
dict set treeidicons $rdbms.$bm.autopilot.options option
$Name item $rdbms.$bm.autopilot.options -tags autoopt
tooltip::tooltip $Name -item $rdbms.$bm.autopilot.options "Autopilot Options"
$Name tag bind autoopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } {autopilot_options } }
$Name insert $rdbms.$bm.autopilot end -id $rdbms.$bm.autopilot.start -text "Autopilot" -image [ create_image autopilot icons ] 
dict set treeidicons $rdbms.$bm.autopilot.start autopilot
$Name item $rdbms.$bm.autopilot.start -tags autostart
tooltip::tooltip $Name -item $rdbms.$bm.autopilot.start "Start Autopilot"
$Name tag bind autostart <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { start_autopilot } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.txcounter -text "Transactions" -image [ create_image pencil icons ]
dict set treeidicons $rdbms.$bm.txcounter pencil
$Name item $rdbms.$bm.txcounter -tags {txhlp}
tooltip::tooltip $Name -item $rdbms.$bm.txcounter "Configure and Run Transaction Counter"
$Name insert $rdbms.$bm.txcounter end -id $rdbms.$bm.txcounter.options -text "Options" -image [ create_image option icons ] 
dict set treeidicons $rdbms.$bm.txcounter.options option
$Name item $rdbms.$bm.txcounter.options -tags txopt
tooltip::tooltip $Name -item $rdbms.$bm.txcounter.options "Transaction Counter Options"
$Name tag bind txopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { countopts } }
$Name insert $rdbms.$bm.txcounter end -id $rdbms.$bm.txcounter.start -text "Counter" -image [ create_image pencil icons ] 
dict set treeidicons $rdbms.$bm.txcounter.start pencil
$Name item $rdbms.$bm.txcounter.start -tags txstart
tooltip::tooltip $Name -item $rdbms.$bm.txcounter.start "Start Transaction Counter"
$Name tag bind txstart <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { .ed_mainFrame.buttons.pencil invoke } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.metrics -text "Metrics" -image [ create_image dashboard icons ]
dict set treeidicons $rdbms.$bm.metrics dashboard
$Name item $rdbms.$bm.metrics -tags {methlp}
tooltip::tooltip $Name -item $rdbms.$bm.metrics "Configure and Run Metrics"
$Name insert $rdbms.$bm.metrics end -id $rdbms.$bm.metrics.options -text "Options" -image [ create_image option icons ]
dict set treeidicons $rdbms.$bm.metrics.options option
$Name item $rdbms.$bm.metrics.options -tags metopt
tooltip::tooltip $Name -item $rdbms.$bm.metrics.options "Metrics Options"
$Name tag bind metopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { metricsopts } }
$Name insert $rdbms.$bm.metrics end -id $rdbms.$bm.metrics.start -text "Display" -image [ create_image dashboard icons ]
dict set treeidicons $rdbms.$bm.metrics.start dashboard
$Name item $rdbms.$bm.metrics.start -tags metstart
tooltip::tooltip $Name -item $rdbms.$bm.metrics.start "Start Metrics Display"
$Name tag bind metstart <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { .ed_mainFrame.buttons.dashboard invoke } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.mode -text "Mode" -image [ create_image mode icons ]
dict set treeidicons $rdbms.$bm.mode mode
$Name item $rdbms.$bm.mode -tags {modehlp}
tooltip::tooltip $Name -item $rdbms.$bm.mode "Configure and Run Remote Conection Modes"
$Name insert $rdbms.$bm.mode end -id $rdbms.$bm.mode.options -text "Options" -image [ create_image option icons ]
dict set treeidicons $rdbms.$bm.mode.options option
$Name item $rdbms.$bm.mode.options -tags modeopt
tooltip::tooltip $Name -item $rdbms.$bm.mode.options "Remote Conection Mode Options"
$Name tag bind modeopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } {select_mode } }
$Name insert $rdbms.$bm end -id $rdbms.$bm.datagen -text "Datagen" -image [ create_image datagen icons ]
dict set treeidicons $rdbms.$bm.datagen datagen
$Name item $rdbms.$bm.datagen -tags {dghlp}
tooltip::tooltip $Name -item $rdbms.$bm.datagen "Configure and Run Data Generation for Upload"
$Name insert $rdbms.$bm.datagen end -id $rdbms.$bm.datagen.options -text "Options" -image [ create_image option icons ]
dict set treeidicons $rdbms.$bm.datagen.options option 
$Name item $rdbms.$bm.datagen.options -tags dgopt
tooltip::tooltip $Name -item $rdbms.$bm.datagen.options "Data Generation Options"
$Name tag bind dgopt <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { dgopts } }
$Name insert $rdbms.$bm.datagen end -id $rdbms.$bm.datagen.start -text "Generate" -image [ create_image datagen icons ]
dict set treeidicons $rdbms.$bm.datagen.start datagen 
$Name item $rdbms.$bm.datagen.start -tags dgstart
tooltip::tooltip $Name -item $rdbms.$bm.datagen.start "Start Data Generation"
$Name tag bind dgstart <Double-ButtonPress-1> { if { ![ string match [ .ed_mainFrame.treeframe.treeview state ] "disabled focus hover" ] } { .ed_mainFrame.buttons.datagen invoke } }
}

proc ed_stop_gui {} {
    ed_wait_if_blocked
#close outstanding threads
set thlist [ thread::names ]
foreach ij $thlist {
	catch {thread::cancel $ij}
#can only be used before final application exit
	catch {thread::exit $ij}
	      }
    exit
}

proc construct_menu {Name label cmd_list} {
upvar #0 icons icons
   global _ED 

ttk::menubutton $Name -text $label  -underline 0 -width [ string length $label ]
   incr _ED(menuCount);
   set newmenu $Name.m$_ED(menuCount)

   $Name configure -menu $newmenu

   catch "destroy $newmenu"
   eval "menu $newmenu"
   eval [list add_items_to_menu $newmenu $cmd_list]

$newmenu configure -background [ dict get $icons defaultBackground ] -foreground [ dict get $icons defaultForeground ] -activebackground  [ dict get $icons defaultBackground ] -activeforeground "#FF7900" -selectcolor "#FF7900"

pack $Name -anchor nw -expand 0 -ipadx 4 -ipady 0 -padx 0 \
         -pady 0 -side left
  }

proc add_items_to_menu {menubutton cmdList} {
upvar #0 icons icons
  global _ED 

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
         set doit "$menubutton add [lindex $cmd 0] -background [ dict get $icons defaultBackground ] -label {[lindex $cmd 1]} \
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
	$newmenu configure -background [ dict get $icons defaultBackground ] -foreground [ dict get $icons defaultForeground ] -activebackground  [ dict get $icons defaultBackground ] -activeforeground "#FF7900" -selectcolor "#FF7900"
	 add_items_to_menu $newmenu [lindex $cmd 2]
         }
      }
    }
  }

proc disable_tree { } {
    #Up to v3.3 we could detach and move tree nodes around
    #In v4.0 with SVG themes, moving tree nodes left a trailing column header from the previously seleted database
    #This version entirely deletes all tree nodes and rebuilds the tree just to remove the trailing column header
    #This is not the best way to select a new database from a treeview but works around the trailing header
    global rdbms bm treebuild pop_treel 
    upvar #0 icons icons
    upvar #0 iconalt iconalt
    set Name .ed_mainFrame.treeframe.treeview
    #Delete all of the nodes in the treeview for all of the databases
    foreach { db bn } $pop_treel {
	catch {$Name delete $db\.$bn}
	catch {$Name delete $db}
	}
	#Rebuild the basic treeview
	eval $treebuild
	#Repopulate the treeview
    foreach { db bn } $pop_treel {
        populate_tree $db $bn $icons $iconalt
        }
	#At this point,all nodes in the treeview are active, disable them all
    set databases [$Name children {}]
    foreach db $databases {
	    set benchmarks [$Name children $db]
        foreach dbbn $benchmarks {
            $Name detach $dbbn
        }
     }
       #Move the chosen database and workload to the top, re-enable it
    $Name move $rdbms {} 0
    $Name move $rdbms.$bm $rdbms 0
    $Name selection set $rdbms.$bm
    $Name see $rdbms.$bm
    $Name focus $rdbms.$bm
}
  
proc disable_enable_options_menu { disoren } {
#Enable or disable top level menu based on benchmark
global rdbms bm
upvar #0 dbdict dbdict
set validrdbms false
set validbm false
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
dict for {database attributes} $dbdict  {
dict with attributes {
if {$name eq $rdbms} { set validrdbms true
foreach { wk } $workloads {
if {$wk eq $bm} { set validbm true }
           }
        }
    }
}
if { $validrdbms eq false } { set rdbms "Oracle" }
if { $validbm eq false } { set bm "TPC-C" }
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
upvar #0 dbdict dbdict
set validrdbms false
set validbm false
dict for {database attributes} $dbdict  {
dict with attributes {
if {$name eq $rdbms} { set validrdbms true
foreach { wk } $workloads {
if {$wk eq $bm} { set validbm true }
           }
        }
    }
}
if { $validrdbms eq false } { set rdbms "Oracle" }
if { $validbm eq false } { set bm "TPC-C" }
if { $bm eq "TPC-C" } {
.ed_mainFrame.menuframe.tpcc.m3 entryconfigure 2 -state normal
.ed_mainFrame.menuframe.tpcc.m3 entryconfigure 3 -state disabled
	} else {
.ed_mainFrame.menuframe.tpcc.m3 entryconfigure 3 -state normal
.ed_mainFrame.menuframe.tpcc.m3 entryconfigure 2 -state disabled
		}
#Oracle has the option to convert trace files
if {$rdbms == "Oracle"} { 
.ed_mainFrame.editbuttons.console configure -state normal 
	} else {
.ed_mainFrame.editbuttons.console configure -state disabled
       }
disable_tree
if { $highlight eq "true" } {
highlight_on
	} else {
highlight_off
	}
}

proc construct_button {Name button_type iconname file cmd helpmsg} {
upvar #0 iconssvg iconssvg 
if { [ info exists iconssvg ] } {
if {[dict exists $iconssvg $iconname\svg ]} {
construct_button_svg $Name $button_type $iconname\svg $file $cmd $helpmsg
	} else {
construct_button_png $Name $button_type $iconname $file $cmd $helpmsg
		}
	} else { 
construct_button_png $Name $button_type $iconname $file $cmd $helpmsg
	}
}

proc construct_button_png {Name button_type iconname file cmd helpmsg} {
#If called with button type of bar buttons are packed in the button bar along the top
#edit buttons are packed along the left hand side visible when the menu button is pressed
#all butons are bound to show an alternative icon when entered and original when left
global tcl_version ctext
upvar #0 icons icons
upvar #0 iconalt iconalt
set im [image create photo -data [ dict get $icons $iconname ] -gamma 1 -height 16 -width 16 -palette 5/5/4]
button $Name -image $im -command "$cmd" -highlightthickness 0 -borderwidth 0 -width 32 -background [ dict get $icons defaultBackground ] -activebackground [ dict get $icons defaultBackground ]
tooltip::tooltip $Name $helpmsg
if { $button_type eq "bar" } {
   pack $Name -anchor nw -side left -expand 0  -fill x -padx {4 4} -pady {4 4}
        } else {
   pack $Name -anchor sw -side bottom -expand 0  -fill y -pady {4 4} -padx {4 4}
        }
   bind $Name <Enter> [
list $Name config -image [image create photo -data [ dict get $iconalt $iconname ] -gamma 1 -height 16 -width 16 -palette 5/5/4] -command "$cmd"
]
bind $Name <Leave> [
list $Name config -image [image create photo -data [ dict get $icons $iconname ] -gamma 1 -height 16 -width 16 -palette 5/5/4] -command "$cmd"
        ]
  }

proc construct_button_svg {Name button_type iconname file cmd helpmsg} {
#If called with button type of bar buttons are packed in the button bar along the top
#edit buttons are packed along the left hand side visible when the menu button is pressed
#all butons are bound to show an alternative icon when entered and original when left
global tcl_version ctext win_scale_fact
upvar #0 iconssvg iconssvg 
upvar #0 iconaltsvg iconaltsvg 
set buttonscale [ expr {round(16 / 1.333333 * $win_scale_fact)} ]
set im [image create photo -data [ dict get $iconssvg $iconname ] -format "svg -scaletoheight $buttonscale"]
button $Name -image $im -command "$cmd" -highlightthickness 0 -borderwidth 0 -width [ expr {round($buttonscale * 2)} ] -background [ dict get $iconssvg defaultBackground ] -activebackground [ dict get $iconssvg defaultBackground ]
tooltip::tooltip $Name $helpmsg
set padding [ expr {round($buttonscale / 4)} ]
if { $button_type eq "bar" } {
   pack $Name -anchor nw -side left -expand 0  -fill x -padx "$padding $padding" -pady "$padding $padding"
	} else {
   pack $Name -anchor sw -side bottom -expand 0  -fill y -pady "$padding $padding" -padx "$padding $padding"
	}
   bind $Name <Enter> [
list $Name config -image [image create photo -data [ dict get $iconaltsvg $iconname ] -format "svg -scaletoheight $buttonscale"] -command "$cmd"
]
bind $Name <Leave> [
list $Name config -image [image create photo -data [ dict get $iconssvg $iconname ] -format "svg -scaletoheight $buttonscale"] -command "$cmd"
	]
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
   wm transient .ed_loadsave .ed_mainFrame
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
   ttk::frame $Name -borderwidth 2 -height 50 -width 50
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
   wm transient .ed_edit_searchf .ed_mainFrame
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
   global _ED lprefix
   if {[ lindex [ split [ join [ stacktrace ] ] ] end ] eq "ed_edit_clear" } {
	set lprefix "load"	
   }
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
upvar #0 dbdict dbdict
         set colour(vars) green
         set colour(cmds) blue
         set colour(functions) magenta
         set colour(brackets) gray50
         set colour(comments) black
         set colour(strings) red
#Extract list of commands provided by each database for highlighting	 
dict for {database attributes} $dbdict {
dict with attributes {
lappend commandl $commands
    }
}
#Add Tcl commands to highlighting
lappend commandl [ info commands ]
#set default database and bm
        ctext::addHighlightClassWithOnlyCharStart $w vars $colour(vars) "\$"
        ctext::addHighlightClass $w cmds $colour(cmds) [join $commandl ]
 	ctext::addHighlightClass $w functions $colour(functions) [ list abs acos asin atan atan2 bool ceil cos cosh double entier exp floor fmod hypot int isqrt log log10 max min pow rand round sin sinh sqrt srand tan tanh wide ]
        ctext::addHighlightClassForSpecialChars $w brackets $colour(brackets) {\{\}\[\]}
        ctext::addHighlightClassForRegexp $w comments $colour(comments) {\#[^\n\r]*} 
        ctext::addHighlightClassForRegexp $w strings $colour(strings) {"(\\"|[^"])*"} 
 }

proc ed_edit {} {
upvar #0 icons icons
   global _ED 
   global Menu_string
   global highlight
   global defaultBackground

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
	set hbgrd [ dict get $icons defaultBackground ]
	} 
if { $highlight eq "true" } {
   ctext $Name -relief flat -background white -borderwidth $bwidth -foreground black \
	-highlight 1 \
         -highlightbackground LightGray -insertbackground black \
         -selectbackground $hbgrd -selectforeground black \
         -wrap none \
         -font basic \
         -xscrollcommand "$Parent.textFrame.right.vertScrollbar set" \
         -yscrollcommand "$Parent.textFrame.left.horizScrollbar set" \
         -linemap 1 \
	 -linemapbg $defaultBackground \
	 -linemap_markable 0
   setctexthighlight $Name
   easyCtextCommenting $Name
	} else {
   ctext $Name -relief flat -background white -borderwidth $bwidth -foreground black \
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

#proc ed_stop_button {} {
#global _ED tcl_version
#upvar #0 icons icons
#set Name .ed_mainFrame.editbuttons.test
#
#set im [image create photo -data [ dict get $icons stop ] -gamma 1 -height 16 -width 16 -palette 5/5/4]
#
#$Name config -image $im -command "ed_kill_apps"
#bind .ed_mainFrame.editbuttons.test <Enter> {ed_status_message -help \
#		 "Stop running code"}   
#}

proc create_image { iconname iconset } {
global win_scale_fact
foreach { imageset } { icons iconalt iconssvg iconaltsvg } { upvar #0 $imageset $imageset }
set buttonscale [ expr {round(16 / 1.333333 * $win_scale_fact)} ]
if { [ info exists iconssvg ] } {
if { $iconset eq "iconalt" } {
set im [image create photo -data [ dict get $iconaltsvg $iconname\svg ] -format "svg -scaletoheight $buttonscale"]
	} else {
if { $iconname in {error information question warning ban graph} } {
#Larger Icon used in dialog and transaction counter
if { $iconname in {ban graph} } {
set buttonscale [ expr {$buttonscale * 4} ]
	} else {
set buttonscale [ expr {$buttonscale * 2} ]
	}
	}
set im [image create photo -data [ dict get $iconssvg $iconname\svg ] -format "svg -scaletoheight $buttonscale"]
	}
	} else {
if { $iconset eq "iconalt" } {
set im [image create photo -data [ dict get $iconalt $iconname ] -gamma 1 -height 16 -width 16 -palette 5/5/4]
	} else {
if { $iconname in {error information question warning ban graph} } {
#Larger Icon used in dialog and transaction counter
set im [ image create photo -data [ dict get $icons $iconname ] ]
	} else {
set im [image create photo -data [ dict get $icons $iconname ] -gamma 1 -height 16 -width 16 -palette 5/5/4]
	}
	}
	}
return $im
}

proc ed_stop_transcount {} {
global _ED tcl_version
set Name .ed_mainFrame.buttons.pencil
    set im [ create_image stop icons ]
$Name config -image $im -command "ed_kill_transcount" 
#bindtags command sets a break to prevent highlighting of button
bindtags $Name [ list Button .ed_mainFrame all BreakTag2 .ed_mainFrame.buttons.pencil ]
tooltip::tooltip .ed_mainFrame.buttons.pencil "Stop Transaction Counter"
bind .ed_mainFrame.buttons.pencil <Enter> {}   
}

proc ed_transcount_button {} {
global _ED tcl_version
set Name .ed_mainFrame.buttons.pencil
#button is pressed so show highlight
    set im [ create_image pencil iconalt ]
$Name config -image $im -command "transcount" 
#return bind order as before so highlights shown
bindtags $Name [ list .ed_mainFrame.buttons.pencil Button .ed_mainFrame all ]
tooltip::tooltip .ed_mainFrame.buttons.pencil "Start Transaction Counter"
  bind $Name <Enter> [
list $Name config -image [ create_image pencil iconalt ] -command "transcount"
]
bind $Name <Leave> [
list $Name config -image [ create_image pencil icons ] -command "transcount"
        ]
}

proc ed_stop_metrics {} {
global _ED tcl_version
set Name .ed_mainFrame.buttons.dashboard
    set im [ create_image stop icons ]
$Name config -image $im -command "ed_kill_metrics" 
#bindtags command sets a break to prevent highlighting of button
bindtags $Name [ list Button .ed_mainFrame all BreakTag2 .ed_mainFrame.buttons.dashboard ]
tooltip::tooltip .ed_mainFrame.buttons.dashboard "Stop Metrics"
bind .ed_mainFrame.buttons.dashboard <Enter> {}   
}

proc ed_metrics_button {} {
global _ED tcl_version
set Name .ed_mainFrame.buttons.dashboard
#button is pressed so show highlight
set im [ create_image dashboard iconalt ]
$Name config -image $im -command "metrics"
#return bind order as before so highlights shown
bindtags $Name [ list .ed_mainFrame.buttons.dashboard Button .ed_mainFrame all ]
tooltip::tooltip .ed_mainFrame.buttons.dashboard "Start Metrics"
  bind $Name <Enter> [
list $Name config -image [ create_image dashboard iconalt ] -command "metrics"
]
bind $Name <Leave> [
list $Name config -image [ create_image dashboard icons ] -command "metrics"
        ]
}

#proc ed_test_button {} {
#global _ED tcl_version
#upvar #0 icons icons
#set Name .ed_mainFrame.editbuttons.test
#
#    set im [image create photo -data [ dict get $icons test ] -gamma 1 -height 16 -width 16 -palette 5/5/4]
#
#$Name config -image $im -command "ed_run_package"
#bind .ed_mainFrame.editbuttons.test <Enter> {ed_status_message -help \
#		 "Test current code"}
#}

proc ed_stop_vuser {} {
global _ED tcl_version
set Name .ed_mainFrame.buttons.lvuser
    set im [ create_image stop icons ]
$Name config -image $im -command "remote_command ed_kill_vusers; ed_kill_vusers" 
#bindtags command sets a break to prevent highlighting of button
bindtags $Name [ list Button .ed_mainFrame all BreakTag2 .ed_mainFrame.buttons.lvuser ]
tooltip::tooltip .ed_mainFrame.buttons.lvuser "Destroy Virtual Users"
bind .ed_mainFrame.buttons.lvuser <Enter> {}   
set Name .ed_mainFrame.buttons.runworld
    set im [ create_image rungreen icons ]
$Name config -image $im -command "remote_command run_virtual; run_virtual" 
#bindtags command sets a break to prevent highlighting of button
bindtags $Name [ list Button .ed_mainFrame all BreakTag2 .ed_mainFrame.buttons.runworld ]
tooltip::tooltip .ed_mainFrame.buttons.runworld "Run Virtual Users"
bind .ed_mainFrame.buttons.runworld <Enter> {}   
}

proc ed_lvuser_button {} {
global _ED tcl_version
set Name .ed_mainFrame.buttons.lvuser
#button is pressed so show highlight
    set im [ create_image lvuser iconalt ]
$Name config -image $im -command "remote_command load_virtual; load_virtual"
#return bind order as before so highlights shown
bindtags $Name [ list .ed_mainFrame.buttons.lvuser Button .ed_mainFrame all ]
tooltip::tooltip .ed_mainFrame.buttons.lvuser "Create Virtual Users"
   bind $Name <Enter> [
list $Name config -image [ create_image lvuser iconalt ] -command "remote_command load_virtual; load_virtual"
]
bind $Name <Leave> [
list $Name config -image [ create_image lvuser icons ] -command "remote_command load_virtual; load_virtual"
	]
set Name .ed_mainFrame.buttons.runworld
#button is not pressed so show normal
set im [ create_image runworld icons ]
$Name config -image $im -command "remote_command run_virtual; run_virtual"
#return bind order as before so highlights shown
bindtags $Name [ list .ed_mainFrame.buttons.runworld Button .ed_mainFrame all ]
tooltip::tooltip .ed_mainFrame.buttons.runworld "Run Virtual Users"
   bind $Name <Enter> [
list $Name config -image [ create_image runworld iconalt ] -command "remote_command run_virtual; run_virtual"
]
bind $Name <Leave> [
list $Name config -image [ create_image runworld icons ] -command "remote_command run_virtual; run_virtual"
	]
}

proc ed_stop_autopilot {} {
global _ED tcl_version
set Name .ed_mainFrame.buttons.autopilot
set im [ create_image stop icons ]
$Name config -image $im -command "ed_kill_autopilot" 
#bindtags command sets a break to prevent highlighting of button
bindtags $Name [ list Button .ed_mainFrame all BreakTag2 .ed_mainFrame.buttons.autopilot ]
tooltip::tooltip .ed_mainFrame.buttons.autopilot "Stop Autopilot"
bind .ed_mainFrame.buttons.autopilot <Enter> {}   
}

proc ed_autopilot_button {} {
global _ED tcl_version
set Name .ed_mainFrame.buttons.autopilot
#button is pressed so show highlight
set im [ create_image autopilot iconalt ]
$Name config -image $im -command "start_autopilot"
#return bind order as before so highlights shown
bindtags $Name [ list .ed_mainFrame.buttons.autopilot Button .ed_mainFrame all ]
tooltip::tooltip .ed_mainFrame.buttons.autopilot "Start Autopilot"
  bind $Name <Enter> [
list $Name config -image [ create_image autopilot iconalt ] -command "start_autopilot"
]
bind $Name <Leave> [
list $Name config -image [ create_image autopilot icons ] -command "start_autopilot"
        ]
}

proc ed_run_package {} {
global _ED maxvuser suppo ntimes
set maxvuser 1
set suppo 1
set ntimes 1
.ed_mainFrame.editbuttons.test configure -state disabled
    if {"$_ED(package)" == ""} {
        ed_status_message -alert "No code currently in run buffer."
        update
	set maxvuser $tmp_maxvuser 
	set suppo $tmp_suppo 
	set ntimes $tmp_ntimes 
	.ed_mainFrame.editbuttons.test configure -state normal
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
   #ed_test_button
   update
}

proc vuser_options {} {
global _ED maxvuser virtual_users delayms conpause ntimes suppo optlog lvuser unique_log_name no_log_buffer log_timestamps threadscreated
upvar #0 icons icons
if {  [ info exists virtual_users ] } { ; } else { set virtual_users 1 }
if {  [ info exists maxvuser ] } { ; } else { set maxvuser $virtual_users }
if {  [ info exists delayms ] } { ; } else { set delayms 500 }
if {  [ info exists conpause ] } { ; } else { set conpause 500 }
if {  [ info exists ntimes ] } { ; } else { set ntimes 1 }
if {  [ info exists suppo ] } { ; } else { set suppo 0 }
if {  [ info exists optlog ] } { ; } else { set optlog 0 }
if {  [ info exists unique_log_name ] } { ; } else { set unique_log_name 0 }
if {  [ info exists no_log_buffer ] } { ; } else { set no_log_buffer 0 }
if {  [ info exists log_timestamps ] } { ; } else { set log_timestamps 0 }
#If window already exists then destroy
   catch "destroy .vuserop"
if { [ info exists threadscreated ] } { 
tk_messageBox -icon error -message "Virtual Users already created, destroy Virtual Users before changing Virtual User options"
return
	}
   ttk::toplevel .vuserop
   wm transient .vuserop .ed_mainFrame
   wm withdraw .vuserop
   wm title .vuserop {Virtual User Options}

   set Parent .vuserop

   set Name $Parent.f1
   ttk::frame $Name 
   pack $Name -anchor nw -fill x -side top -padx 5

set Prompt $Parent.f1.h1
ttk::label $Prompt -image [ create_image lvuser icons ]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Virtual User Options"
grid $Prompt -column 1 -row 0 -sticky w

   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Virtual Users :"
   ttk::spinbox $Name -width 30 -from 1 -to 10000 -textvariable virtual_users
   grid $Prompt -column 0 -row 1 -sticky e
   grid $Name -column 1 -row 1 -sticky ew

   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "User Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable delayms
   grid $Prompt -column 0 -row 2 -sticky e
   grid $Name -column 1 -row 2 -sticky ew

   set Name $Parent.f1.e3
   set Prompt $Parent.f1.p3
   ttk::label $Prompt -text "Repeat Delay(ms) :"
   ttk::entry $Name -width 30 -textvariable conpause
   grid $Prompt -column 0 -row 3 -sticky e
   grid $Name -column 1 -row 3 -sticky ew

   set Name $Parent.f1.e4
   set Prompt $Parent.f1.p4
   ttk::label $Prompt -text "Iterations :"
   ttk::entry $Name -width 30 -textvariable ntimes
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4 -sticky ew

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
set log_timestamps 0
.vuserop.f1.e6 configure -state disabled
.vuserop.f1.e7 configure -state disabled
.vuserop.f1.e8 configure -state disabled
.vuserop.f1.e9 configure -state disabled
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
.vuserop.f1.e9 configure -state active
	} else {
set unique_log_name 0
set no_log_buffer 0
set log_timestamps 0
.vuserop.f1.e7 configure -state disabled
.vuserop.f1.e8 configure -state disabled
.vuserop.f1.e9 configure -state disabled
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

   set Name $Parent.f1.e9
ttk::checkbutton $Name -text "Log Timestamps" -variable log_timestamps -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 9 -sticky w
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
# global rdbms bm
         set virtual_users [.vuserop.f1.e1 get]
if { ![string is integer -strict $virtual_users] } { 
	tk_messageBox -message "The number of virtual users must be an integer" 
	set virtual_users 1
	} else { 
if { $virtual_users < 1 } { tk_messageBox -message "The number of virtual users must be 1 or greater" 
	set virtual_users 1
	} 
	
#Find if workload test or timed
#upvar #0 dbdict dbdict
foreach { key } [ dict keys $dbdict ] {
if { [ dict get $dbdict $key name ] eq $rdbms } {
set prefix [ dict get $dbdict $key prefix ]
set name [ string tolower [ dict get $dbdict $key name ] ]
#upvar #0 config$name config$name
break
        }
}
if { $bm eq "TPC-C" } {
setlocaltpccvars [ subst \$config$name ]
set timedwkl [ set $prefix\_driver ]
} else {
#No timed workloads in TPC-H
#setlocaltpchvars [ subst \$config$name ] 
set timedwkl "false"
}
	if { $timedwkl eq "timed" } {
        set maxvuser [expr {$virtual_users + 1}]
	set suppo 1
        } else {
        set maxvuser $virtual_users
        }
}	
         set delayms [.vuserop.f1.e2 get]
if { ![string is integer -strict $delayms] } { 
	tk_messageBox -message "Delay between users logons must be an integer" 
	set delayms 0
	}
if { $delayms < 0 } { tk_messageBox -message "Delay between users logons must be at least 0 milliseconds" 
	set delayms 0
	}
         set conpause [.vuserop.f1.e3 get]
if { ![string is integer -strict $conpause] } { 
	tk_messageBox -message "Delay between iterations must be an integer" 
	set conpause 0
	}
if { $conpause < 0 } { tk_messageBox -message "Delay between iterations must be at least 0 milliseconds" 
	set conpause 0
	}
         set ntimes   [.vuserop.f1.e4 get]
if { ![string is integer -strict $ntimes] } { 
	tk_messageBox -message "The number of iterations must be an integer" 
	set ntimes 1
	}
if { $ntimes < 1 } { tk_messageBox -message "The number of iterations must be 1 or greater" 
	set ntimes 1
	}
	 remote_command [ concat vuser_slave_ops $maxvuser $virtual_users $delayms $conpause $ntimes $suppo $optlog ]
         destroy .vuserop
            } \
         -text OK
   pack $Name -anchor nw -side right -padx 3 -pady 3

   wm geometry .vuserop +50+50
   wm deiconify .vuserop
   raise .vuserop
   update
}

proc about { } {
global hdb_version
tk_messageBox -title About -message "HammerDB $hdb_version
Copyright (C) 2003-2021
Steve Shaw\n" 
}

proc license { } {
tk_messageBox -title License -message "
This copyright notice must be included in all distributions.
Copyright (C) 2003-2021 Steve Shaw

This program is free software: you can redistribute it and/or modify it under the terms
of the GNU General Public License as published by the Free Software Foundation,
either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
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
            catch "$_ED(status_widget) configure -foreground \#D00000"
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
            catch "$_ED(status_widget) configure -foreground \#00CC00"
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
    wm transient $w .ed_mainFrame
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
upvar #0 icons icons
global opmode apmode apduration apsequence autopilot suppo optlog unique_log_name no_log_buffer log_timestamps
if {  [ info exists apmode ] } { ; } else { set apmode "disabled" }
if {  [ info exists apduration ] } { ; } else { set apduration 10 }
if {  [ info exists apsequence ] } { ; } else { set apsequence "1 2 4 8 12 16 20 24" }
if {  [ info exists suppo ] } { ; } else { set suppo 0 }
if {  [ info exists optlog ] } { ; } else { set optlog 0 }
if {  [ info exists unique_log_name ] } { ; } else { set unique_log_name 0 }
if {  [ info exists no_log_buffer ] } { ; } else { set no_log_buffer 0 }
if {  [ info exists log_timestamps ] } { ; } else { set log_timestamps 0 }
   catch "destroy .apopt"
   ttk::toplevel .apopt
   wm transient .apopt .ed_mainFrame
   wm withdraw .apopt
   wm title .apopt {Autopilot Options}
   set Parent .apopt
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5 
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [ create_image autopilot icons ]
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
set log_timestamps 0
.apopt.f1.e1 configure -state disabled 
.apopt.f1.e2 configure -state disabled 
.apopt.f1.e3 configure -state disabled
.apopt.f1.e4 configure -state disabled
.apopt.f1.e5 configure -state disabled
.apopt.f1.e6 configure -state disabled
.apopt.f1.e7 configure -state disabled
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
   ttk::label $Prompt -text "Active Virtual User Sequence (Space Separated) :"
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
set log_timestamps 0
.apopt.f1.e4 configure -state disabled
.apopt.f1.e5 configure -state disabled
.apopt.f1.e6 configure -state disabled
.apopt.f1.e7 configure -state disabled
			}
		}

   set Name $Parent.f1.e4
ttk::checkbutton $Name -text "Log Virtual User Output to Temp" -variable optlog -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 9 -sticky w
	if {$suppo == 0 || $apmode != "enabled" } {
	set unique_log_name 0
	set no_log_buffer 0
	set log_timestamps 0
	$Name configure -state disabled
	}

bind .apopt.f1.e4 <Button> { 
set opst [ .apopt.f1.e4 cget -state ]
if {$optlog == 0 && $opst != "disabled"} { 
.apopt.f1.e5 configure -state active 
.apopt.f1.e6 configure -state active 
.apopt.f1.e7 configure -state active
	} else {
set unique_log_name 0
set no_log_buffer 0
set log_timestamps 0
.apopt.f1.e5 configure -state disabled
.apopt.f1.e6 configure -state disabled
.apopt.f1.e7 configure -state disabled
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

 set Name $Parent.f1.e7
ttk::checkbutton $Name -text "Log Timestamps" -variable log_timestamps -onvalue 1 -offvalue 0
   grid $Name -column 1 -row 12 -sticky w
	if {$optlog == 0 || $apmode !=  "enabled" || $suppo == 0} {
	set log_timestamps 0
	.apopt.f1.e7 configure -state disabled
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
	set apsequence "1 2 4 8 12 16 20 24 28"
	break
	}
}
if { $apmode eq "enabled" } {
.ed_mainFrame.buttons.autopilot configure -state normal
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
#Introduced new option for Database metrics initially Oracle only
global rdbms
if { $rdbms eq "Oracle" } {
metoraopts
	} elseif { $rdbms eq "PostgreSQL" } {
metpgopts
	} else {
metgenopts
		}
	}

proc metgenopts {} {
global agent_hostname agent_id
upvar #0 icons icons
if {  [ info exists agent_hostname ] } { ; } else { set agent_hostname "localhost" }
if {  [ info exists agent_id ] } { ; } else { set agent_id 0 }
set old_agent $agent_hostname
set old_id $agent_id
   catch "destroy .metric"
   ttk::toplevel .metric
   wm transient .metric .ed_mainFrame
   wm withdraw .metric
   wm title .metric {Metrics Agent Options}
   set Parent .metric
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5                              
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [ create_image dashboard icons ]
grid $Prompt -column 0 -row 0 -sticky e
                                             
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

proc dgopts {} {
global datagen bm gen_count_ware gen_scale_fact gen_directory gen_num_vu defaultBackground defaultForeground
upvar #0 icons icons
if {  ![ info exists gen_count_ware ] } { set gen_count_ware "1" }
if {  ![ info exists gen_scale_fact ] } { set gen_scale_fact "1" }
if {  ![ info exists gen_directory ] } { set gen_directory [ findtempdir ] }
if {  ![ info exists gen_num_vu ] } { set gen_num_vu "1" }
if {  ![ info exists bm ] } { set bm "TPC-C" }
#generate list of warehouses for spinbox
set whlist ""
set i 1
foreach j {10 100 1000 10000 110000} k {1 10 100 1000 10000} {
while {$i < $j} {
lappend whlist $i 
incr i $k
}}
 catch "destroy .dgopt"
   ttk::toplevel .dgopt
   wm transient .dgopt .ed_mainFrame
   wm withdraw .dgopt
   wm title .dgopt "[ regsub -all {(TP)(C)(-[CH])} $bm {\1RO\2\3} ] Data Generation Options"
   set Parent .dgopt
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [ create_image datagen icons ]
grid $Prompt -column 0 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "[ regsub -all {(TP)(C)(-[CH])} $bm {\1RO\2\3} ] Data Generation Options"
grid $Prompt -column 1 -row 0 -sticky w
if { $bm eq "TPC-C" } {
set Prompt $Parent.f1.p1
set Name $Parent.f1.e1
ttk::label $Prompt -text "Number of Warehouses :"
ttk::spinbox $Name -value $whlist -textvariable gen_count_ware
        grid $Prompt -column 0 -row 1 -sticky e
        grid $Name -column 1 -row 1 -sticky ew
#Display Count Ware or Scale Factor
	} else {
set Name $Parent.f1.p1
   set Prompt $Parent.f1.p1 
   ttk::label $Prompt -text "Scale Factor :"
   grid $Prompt -column 0 -row 1 -sticky e
   set Name $Parent.f1.f2
   ttk::frame $Name -width 30
   grid $Name -column 1 -row 1 -sticky ew
	set rcnt 1
	foreach item {1} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable gen_scale_fact -text $item -value $item -width 4
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 2
	foreach item {10 30} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable gen_scale_fact -text $item -value $item -width 3
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 4
	foreach item {100 300 1000} {
	set Name $Parent.f1.f2.r$rcnt
	ttk::radiobutton $Name -variable gen_scale_fact -text $item -value $item -width 5
   	grid $Name -column $rcnt -row 0 
	incr rcnt
	}
	set rcnt 2
	foreach item {3000 10000} {
	set Name $Parent.f1.f2.ra$rcnt
	ttk::radiobutton $Name -variable gen_scale_fact -text $item -value $item -width 6
   	grid $Name -column $rcnt -row 1 
	incr rcnt
	}
	set rcnt 4
	foreach item {30000 100000} {
	set Name $Parent.f1.f2.ra$rcnt
	ttk::radiobutton $Name -variable gen_scale_fact -text $item -value $item -width 7
   	grid $Name -column $rcnt -row 1 
	incr rcnt
	}
	}
set Name $Parent.f1.e3
set Prompt $Parent.f1.p3
ttk::label $Prompt -text "Directory for File Generation :"
ttk::entry $Name -width 30 -textvariable gen_directory
grid $Prompt -column 0 -row 4 -sticky e
grid $Name -column 1 -row 4 -sticky ew
set Prompt $Parent.f1.p4
ttk::label $Prompt -text "Virtual Users to Generate Data :"
set Name $Parent.f1.e4
ttk::spinbox $Name -from 1 -to 1024 -textvariable gen_num_vu
bind .dgopt.f1.e4 <Any-ButtonRelease> {
if { $bm eq "TPC-C" } {
if {$gen_num_vu > $gen_count_ware} {
set gen_num_vu $gen_count_ware
                }
  } else {
if {($gen_num_vu > 32 && $gen_scale_fact eq 1)||($gen_num_vu > 64 && $gen_scale_fact eq 10)} { 
switch $gen_scale_fact {
1 { set gen_num_vu 32 }
10 { set gen_num_vu 64 }
			}
		}
         }
}
grid $Prompt -column 0 -row 3 -sticky e
grid $Name -column 1 -row 3 -sticky ew
   set Name $Parent.b5
   ttk::button $Name -command {destroy .dgopt} -text Cancel
   pack $Name -anchor w -side right -padx 3 -pady 3
   set Name $Parent.b6
   ttk::button $Name -command {
if { $bm eq "TPC-C" } {
	if { ![string is integer -strict $gen_count_ware] || $gen_count_ware < 1 || $gen_count_ware > 100000 } {
        tk_messageBox -message "The number of warehouses must be a positive integer less than or equal to 100000"
	set gen_count_ware 1
	}
if {$gen_num_vu > $gen_count_ware} {
set gen_num_vu $gen_count_ware
                }
}
if { ![string is integer -strict $gen_num_vu] || $gen_num_vu < 1 || $gen_num_vu > 1024 } { 
	tk_messageBox -message "The number of virtual users must be a positive integer less than 1024" 
	set gen_num_vu 1
	}
         set gen_directory [.dgopt.f1.e3 get]
	 catch "destroy .dgopt"
      if {![file writable $gen_directory]} {
tk_messageBox -title "Directory Warning" -icon warning -message "Files cannot be written to chosen directory you must create $gen_directory before generating data" 
	}
        } -text {OK}     
   pack $Name -anchor w -side right -padx 3 -pady 3
   wm geometry .dgopt +50+50
   wm deiconify .dgopt
   update
}

proc select_mode {} {
global opmode hostname id masterlist apmode mode
upvar 1 oldmode oldmode
upvar #0 icons icons
if {  [ info exists hostname ] } { ; } else { set hostname "localhost" }
if {  [ info exists id ] } { ; } else { set id 0 }
if {  [ info exists apmode ] } { ; } else { set apmode "disabled" }
   set oldmode $opmode
   catch "destroy .mode"
   ttk::toplevel .mode
   wm transient .mode .ed_mainFrame
   wm withdraw .mode
   wm title .mode {Mode Options}
   set Parent .mode
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5                                                                           
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [ create_image mode icons ]
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
ttk::radiobutton $Name -text "Primary Mode" -variable opmode -value "Primary" 
grid $Name -column 0 -row 2 -sticky w                                          
bind $Parent.f1.b2 <Button> {
.mode.f1.e1 configure -state disabled 
.mode.f1.e2 configure -state disabled 
                }
   set Name $Parent.f1.b3
ttk::radiobutton $Name -text "Replica Mode" -variable opmode -value "Replica"
grid $Name -column 0 -row 3 -sticky w
bind $Parent.f1.b3 <Button> {
.mode.f1.e1 configure -state normal 
.mode.f1.e2 configure -state normal 
                }
   set Name $Parent.f1.e1
   set Prompt $Parent.f1.p1
   ttk::label $Prompt -text "Primary ID :"
   ttk::entry $Name -width 30 -textvariable id
   grid $Prompt -column 0 -row 4 -sticky e
   grid $Name -column 1 -row 4
if {$opmode != "Replica" } {
        $Name configure -state disabled
        }
   set Name $Parent.f1.e2
   set Prompt $Parent.f1.p2
   ttk::label $Prompt -text "Primary Hostname :"
   ttk::entry $Name -width 30 -textvariable hostname
   grid $Prompt -column 0 -row 5 -sticky e
   grid $Name -column 1 -row 5
if {$opmode != "Replica" } {
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
global rdbms bm tcl_platform
upvar #0 icons icons
upvar #0 dbdict dbdict
upvar 1 oldrdbms oldrdbms
upvar 1 oldbm oldbm
set validrdbms false
set oldrdbms $rdbms
set oldbm $bm
if { $preselect eq "none" } { set preselect $rdbms }
dict for {database attributes} $dbdict  {
dict with attributes {
set wkcnt 0
if {$name eq $rdbms} { set validrdbms true }
foreach { wk } $workloads {
incr wkcnt
#if there are 2 workloads then DB supports TPC-C and TPC-H
if { $wkcnt eq 2 } { lappend fullwkl $name }
         }
      }
   }
if { $validrdbms eq false } { set rdbms "Oracle" }
set rdbms $preselect 
   catch "destroy .rdbms"
   ttk::toplevel .rdbms
   wm transient .rdbms .ed_mainFrame
   wm withdraw .rdbms
   wm title .rdbms {Benchmark Options}
   set Parent .rdbms
   set Name $Parent.f1
   ttk::frame $Name
   pack $Name -anchor nw -fill x -side top -padx 5                                                                            
set Prompt $Parent.f1.h1
ttk::label $Prompt -image [ create_image benchmark icons ]
grid $Prompt -column 1 -row 0 -sticky e
set Prompt $Parent.f1.h2
ttk::label $Prompt -text "Benchmark Options"
grid $Prompt -column 2 -row 0 -sticky w
set rowind 0
dict for {database attributes} $dbdict  {
incr rowind
set Name $Parent.f1.b$rowind
dict with attributes {
append bmbuild [ subst {set Name $Name} ] "\n"
if { [ lsearch $fullwkl $name ] eq -1 } {  
append bmbuild [ subst {ttk::radiobutton $Name -text "$description" -variable rdbms -value "$name" -command { if { \$oldrdbms != \$rdbms } {set rdbms "$name"}\n.rdbms.f1.bm2 configure -state disabled\n set bm "TPC-C" } } ] "\n"
} else {
append bmbuild [ subst {ttk::radiobutton $Name -text "$description" -variable rdbms -value "$name" -command { if { \$oldrdbms != \$rdbms } {set rdbms "$name"}\n.rdbms.f1.bm2 configure -state enabled } } ] "\n"
}
append bmbuild [ subst {grid $Name -column 1 -row $rowind -sticky w} ] "\n"
}}
eval $bmbuild
   set Name $Parent.f1.bm1
ttk::radiobutton $Name -text "TPROC-C" -image [ create_image hdbicon icons ] -compound left -variable bm -value "TPC-C" -command { if { $oldbm != $bm } { set bm "TPC-C" } 
}
 grid $Name -column 2 -row 1 -sticky w                                                                               
   set Name $Parent.f1.bm2
ttk::radiobutton $Name -text "TPROC-H" -image [ create_image hdbicon icons ] -compound left -variable bm -value "TPC-H" -command { if { $oldbm != $bm } { set bm "TPC-H" } 
}
 grid $Name -column 2 -row 2 -sticky w
if { [ lsearch $fullwkl $rdbms ] eq -1 } { $Name configure -state disabled ; set bm "TPC-C" }
   set Name $Parent.f1.ok
   ttk::button $Name -command { 
catch "destroy .rdbms"
if { $oldbm eq $bm && $oldrdbms eq $rdbms } { 
tk_messageBox -title "Confirm Benchmark" -message "No Change Made : [ regsub -all {(TP)(C)(-[CH])} $bm {\1RO\2\3} ] for $rdbms" 
} else {
if { $rdbms eq "Trafodion" } {
.ed_mainFrame.buttons.pencil configure -state disabled 
	} else {
.ed_mainFrame.buttons.pencil configure -state normal 
	}
set oldbm $bm
set oldrdbms $rdbms
disable_bm_menu
tk_messageBox -title "Confirm Benchmark" -message "[ regsub -all {(TP)(C)(-[CH])} $bm {\1RO\2\3} ] for $rdbms" 
remote_command [ concat vuser_bench_ops $rdbms $bm ]
remote_command disable_bm_menu
	}
} -text OK
   grid $Parent.f1.ok -column 2 -row 8 -padx 3 -pady 3 -sticky e
  
   set Name $Parent.f1.cancel
   ttk::button $Name -command {
catch "destroy .rdbms"
set bm $oldbm
set rdbms $oldrdbms
} -text Cancel
   grid $Parent.f1.cancel -column 3 -row 8 -padx 3 -pady 3 -sticky w
   wm geometry .rdbms +50+50
   wm deiconify .rdbms
   raise .rdbms
   update
}

proc build_schema {} {
#This runs the schema creation
upvar #0 dbdict dbdict
global _ED bm rdbms threadscreated 
#Clear the Script Editor first to make sure a genuine schema build is run
ed_edit_clear
if { [ info exists threadscreated ] } {
tk_messageBox -icon error -message "Cannot build schema with Virtual Users active, destroy Virtual Users first"
#clear script editor so cannot be re-run with incorrect v user count
return 1
        }
foreach { key } [ dict keys $dbdict ] {
if { [ dict get $dbdict $key name ] eq $rdbms } {
set prefix [ dict get $dbdict $key prefix ]
if { $bm == "TPC-C" }  {
set command [ concat [subst {build_$prefix}]tpcc ]
	} else {
set command [ concat [subst {build_$prefix}]tpch ]
	}
eval $command
break
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

proc run_datagen {} {
global _ED bm rdbms threadscreated
#Clear the Script Editor first to make sure a genuine schema build is run
ed_edit_clear
if { [ info exists threadscreated ] } {
tk_messageBox -icon error -message "Cannot generate data with Virtual Users active, destroy Virtual Users first"
#clear script editor so cannot be re-run with incorrect v user count
return 1
        }
if { $bm == "TPC-C" } { 
gendata_tpcc 
} else { 
gendata_tpch 
}
.ed_mainFrame.notebook select .ed_mainFrame.mainwin
applyctexthighlight .ed_mainFrame.mainwin.textFrame.left.text
.ed_mainFrame.notebook select .ed_mainFrame.tw
#Commit to update values in script editor
ed_edit_commit
if { [ string length $_ED(package)] eq 1 } {
#No was pressed at data generation and editor is empty do not run
return
	} else {
#Yes was pressed at schema creation run
run_virtual
	}
}

proc configtpcc { option } {
upvar #0 dbdict dbdict
global rdbms
foreach { key } [ dict keys $dbdict ] {
if { [ dict get $dbdict $key name ] eq $rdbms } { 
set prefix [ dict get $dbdict $key prefix ]
set command [ concat [subst {config$prefix}]tpcc $option ]
eval $command
break
	}
    }
}

proc configtpch { option } {
upvar #0 dbdict dbdict
global rdbms
foreach { key } [ dict keys $dbdict ] {
if { [ dict get $dbdict $key name ] eq $rdbms } { 
set prefix [ dict get $dbdict $key prefix ]
set command [ concat [subst {config$prefix}]tpch $option ]
eval $command
break
	}
    }
}

proc countopts {} {
upvar #0 dbdict dbdict
global rdbms bm
foreach { key } [ dict keys $dbdict ] {
if { [ dict get $dbdict $key name ] eq $rdbms } { 
set prefix [ dict get $dbdict $key prefix ]
set command [ concat [subst {count$prefix}]opts $bm ]
eval $command
break
	}
    }
}

proc loadtpcc {} {
upvar #0 dbdict dbdict
global _ED rdbms lprefix
set _ED(packagekeyname) "TPROC-C"
ed_status_message -show "TPROC-C Driver Script"
foreach { key } [ dict keys $dbdict ] {
if { [ dict get $dbdict $key name ] eq $rdbms } { 
set dictname config$key
upvar #0 $dictname $dictname
set prefix [ dict get $dbdict $key prefix ]
set drivername [ concat [subst {$prefix}]_driver ]
set drivertype [ dict get [ set $dictname ] tpcc $drivername ]
if { $drivertype eq "test" } { set lprefix "load" } else { set lprefix "loadtimed" } 
set command [ concat [subst {$lprefix$prefix}]tpcc ]
eval $command
set allw [ lsearch -inline [ dict get [ set $dictname ] tpcc ] *allwarehouse ]
if { $allw != "" } {
set db_allwarehouse [ dict get [ set $dictname ] tpcc $allw ]
set asyscl [ lsearch -inline [ dict get [ set $dictname ] tpcc ] *async_scale ]
if { $asyscl != "" } {
set db_async_scale [ dict get [ set $dictname ] tpcc $asyscl ]
	} else {
set db_async_scale "false"
	}
if { $db_allwarehouse } { shared_tpcc_functions "allwarehouse" $db_async_scale }
	}
upvar #0 genericdict genericdict
if {[dict exists $genericdict timeprofile profiler]} {
set profiler [ dict get $genericdict timeprofile profiler]
        }
if { $profiler eq "xtprof" } { set profile_func "xttimeprofile" }  else { set profile_func "ettimeprofile" }
set timep [ lsearch -inline [ dict get [ set $dictname ] tpcc ] *timeprofile ]
if { $timep != "" } {
set db_timeprofile [ dict get [ set $dictname ] tpcc $timep ]
if { $db_timeprofile } { shared_tpcc_functions $profile_func "false" }
	}
break
    }
  }
applyctexthighlight .ed_mainFrame.mainwin.textFrame.left.text
}

proc loadtpch {} {
upvar #0 dbdict dbdict
global _ED rdbms lprefix
if {  [ info exists lprefix ] } { ; } else { set lprefix "load" }
global cloud_query mysql_cloud_query pg_cloud_query
set _ED(packagekeyname) "TPROC-H"
ed_status_message -show "TPROC-H Driver Script"
foreach { key } [ dict keys $dbdict ] {
if { [ dict get $dbdict $key name ] eq $rdbms } {
set dictname config$key
upvar #0 $dictname $dictname
set prefix [ dict get $dbdict $key prefix ]
set command [ concat [subst {load$prefix}]tpch ]
set cloudq [ lsearch -inline [ dict get [ set $dictname ] tpch ] *cloud_query ]
if { $cloudq != "" } {
set db_cloud_query [ dict get [ set $dictname ] tpch $cloudq ]
if { $db_cloud_query } { set command [ concat [subst {load$prefix}]cloud ] }
        }
eval $command
set lprefix "load"
break
    }
 }
applyctexthighlight .ed_mainFrame.mainwin.textFrame.left.text
}

proc get_warehouse_list_for_spinbox {} {
set whlist ""
set i 1
foreach j {10 100 1000 10000 110000} k {1 10 100 1000 10000} {
while {$i < $j} {
lappend whlist $i
incr i $k
}}
return $whlist
}

proc verify_warehouse { count_ware maximum } {
if { ![string is integer -strict $count_ware] || $count_ware < 1 || $count_ware > $maximum } {
        tk_messageBox -message "The number of warehouses must be a positive integer less than or equal to $maximum"
        set count_ware 1
        }
return $count_ware
}

proc verify_build_threads { num_vu count_ware maximum } {
if { ![string is integer -strict $num_vu] || $num_vu < 1 || $num_vu > $maximum } {
        tk_messageBox -message "The number of virtual users must be a positive integer less than or equal to $maximum"
        set num_vu 1
        }
if { $num_vu > $count_ware } { set num_vu $count_ware }
return $num_vu
}

#A temporary dict is used to hold modified data before 
#the user presses OK in an options dialog this procedure
#copies this temporary data back into the database dict
proc copyfieldstoconfig { configdict fieldsdict wkload } {
upvar #0 $configdict $configdict
dict for {descriptor attributes} [ set $configdict ]  {
if {$descriptor eq "connection" || $descriptor eq "$wkload" } {
foreach { val } [ dict keys $attributes ] {
if {[dict exists $attributes $val ]} {
if {[dict exists $fieldsdict $descriptor $val ]} {
#uncomment line below for debug field settings in dialogs
#puts -nonewline "var is $val"
set field [ dict get $fieldsdict $descriptor $val ]
#uncomment line below for debug field settings in dialogs
#puts " field is $field"
if {[string match "*get" $field]} {
#some fields may not exist depending on option of build or drive
catch {dict set $configdict $descriptor $val [ eval $field ]}
} else {
catch {dict set $configdict $descriptor $val $field}
}}}}}}
}
bind Entry <BackSpace> {tkEntryBackspace %W}
