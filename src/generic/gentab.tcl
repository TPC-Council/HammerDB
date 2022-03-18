proc runninguser { threadid } {
global table threadscreated thvnum run
$table cellconfigure $thvnum($threadid),3 -image $run 
}

proc printresult { result threadid } {
global table threadscreated thvnum succ fail totrun totcount inrun
incr totcount
set c [ $table cellcget $thvnum($threadid),2 -text ]
incr c
$table cellconfigure $thvnum($threadid),2 -text $c
if { $result == 0 } {
$table cellconfigure $thvnum($threadid),3 -image $succ 
} else {
$table cellconfigure $thvnum($threadid),3 -image $fail
}
if { $totrun == $totcount } {
set Name .ed_mainFrame.buttons.runworld
$Name configure -state normal
if { [ info exists inrun ] } {
    unset inrun
    }
    ed_status_message -finish "COMPLETE"
    }
}

proc configtable { } {
global threadscreated virtual_users maxvuser table ntimes thvnum vus repeat task clo totrun 
upvar #0 icons icons
set benchmark [ create_image benchmark icons ]
for { set vuser 0} {$vuser < $maxvuser} {incr vuser} {
set thvnum($threadscreated($vuser)) $vuser
$table insert end "[expr $vuser + 1] $ntimes 0"
if { $virtual_users != $maxvuser && $vuser eq 0} { 
$table cellconfigure $vuser,0 -image $benchmark
 } else { 
$table cellconfigure $vuser,0 -image $vus
}
$table cellconfigure $vuser,1 -image $repeat
$table cellconfigure $vuser,2 -image $task
$table cellconfigure $vuser,3 -image $clo 
}
set totrun [ expr $maxvuser * $ntimes ]
}

proc tablist w {
upvar #0 icons icons
    if {![winfo exists $w]} {
	bell
	tk_messageBox -icon error -message "Bad window path name \"$w\"" \
		      -type ok
	return ""
    }
set top $w
    set tf $top.tf
    ttk::frame $tf
    set tbl $tf.tbl
    set vsb $tf.vsb
    set hsb $tf.hsb
    ::tablelist::tablelist $tbl \
	-columns {0 "Virtual User"
		  0 " Iterations "
		  0 "  Complete  "
		  0 "   Status   "} \
	-yscrollcommand [list $vsb set] \
	-height 10 -width 87 -stretch all \
	-background white \
	-borderwidth 0 \
	-labelrelief flat \
	-font basic
    ttk::scrollbar $vsb -orient vertical -command [list $tbl yview]
    grid $tbl -row 0 -column 0 -sticky news
    grid $vsb -row 0 -column 1 -sticky ns
    grid rowconfigure    $tf 0 -weight 1
    grid columnconfigure $tf 0 -weight 1
    pack $tf -side top -expand yes -fill both
	if { $ttk::currentTheme in {clearlooks arc breeze awlight}} {
	$tbl configure -labelforeground black
	$tbl configure -selectbackground #FF7900
	$tbl configure -stripebackground [ dict get $icons defaultBackground ]
	} else {
	$tbl configure -stripebackground [ dict get $icons defaultBackground ]
	}
	$tbl configure -spacing 2
	$tbl columnconfigure 0 -align center
	$tbl columnconfigure 1 -align center
	$tbl columnconfigure 2 -align center
	$tbl columnconfigure 3 -align center
    return $tbl
}
