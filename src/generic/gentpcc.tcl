proc shared_tpcc_functions { tpccfunc db_async_scale } {
switch $tpccfunc {
allwarehouse {
#set additional text for all warehouses
set allwt(1) {set allwarehouses "true";# Use all warehouses to increase I/O
}
set allwt(2) {#2.4.1.1 does not apply when allwarehouses is true
if { $allwarehouses == "true" } {
set loadUserCount [expr $totalvirtualusers - 1]
set myWarehouses {}
set addMore 0
set whRequiredCount [expr ceil(double($w_id_input)/double($loadUserCount))]
while {$addMore >= 0} {
set wh [expr ((($myposition - 2) + ($addMore * $loadUserCount))%$w_id_input)+1]
if {$addMore >= $whRequiredCount} {
set addMore -1
} else {
puts "VU $myposition : Assigning WID=$wh based on VU count $loadUserCount, Warehouses = $w_id_input ([expr $addMore + 1] out of [ expr int($whRequiredCount)])"
lappend myWarehouses $wh
set addMore [expr $addMore + 1]
}
}
set myWhCount [llength $myWarehouses]
}
}
set allwt(3) {if { $allwarehouses == "true" } {
set w_id [lindex $myWarehouses [expr [RandomNumber 1 $myWhCount] -1]]
}
}
set allwt(4) {global allwarehouses myposition totalvirtualusers
}
#search for insert points and insert functions
set allwi(1) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "#EDITABLE OPTIONS##################################################" end ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $allwi(1) $allwt(1)
set allwi(2) [.ed_mainFrame.mainwin.textFrame.left.text search -forwards "#2.4.1.1" $allwi(1) ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $allwi(2) $allwt(2)
set allwi(3) [.ed_mainFrame.mainwin.textFrame.left.text search -forwards "set choice" $allwi(2) ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $allwi(3) $allwt(3)
if { $db_async_scale } {
set allwi(4) [.ed_mainFrame.mainwin.textFrame.left.text search -forwards "#EDITABLE OPTIONS##################################################" end ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $allwi(4)+1l $allwt(4)
set allwi(5) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "promise::async" end ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $allwi(5)+1l $allwt(4)
	}
   }
ettimeprofile {
#set additional text for all warehouses
set timept(1) {set timeprofile "true";# Output virtual user response times
}
set timept(2) {if {$timeprofile eq "true" && $myposition eq 2} {package require etprof}
}
set timept(3) {if {$timeprofile eq "true" && $myposition eq 2} {::etprof::printLiveInfo}
}
#search for insert points and insert functions
set timepi(1) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "#EDITABLE OPTIONS##################################################" end ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $timepi(1) $timept(1)
set timepi(2) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "default \{" end ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $timepi(2)+1l $timept(2)
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end-2l $timept(3)
  }
xttimeprofile {
#set additional text for all warehouses
set timept(1) {if [catch {package require xtprof} ] { error "Failed to load extended time profile functions" } else { namespace import xtprof::* }
}
set timept(2) {xttimeproflog $totalvirtualusers $library
}
set timept(3) {xtreport $myposition
}
#search for insert points and insert functions
set timepi(1) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "if \[catch \{package require tpcccommon\} \]" end ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $timepi(1)+1l $timept(1)
set timepi(2) [.ed_mainFrame.mainwin.textFrame.left.text search -backwards "tsv::set application abort 1" end ]
.ed_mainFrame.mainwin.textFrame.left.text fastinsert $timepi(2)+1l $timept(2)
.ed_mainFrame.mainwin.textFrame.left.text fastinsert end-2l $timept(3)
  }
 }
}
proc setlocaltpccvars { configdict } {
#set variables to values in dict
dict for {descriptor attributes} $configdict  {
if {$descriptor eq "connection" || $descriptor eq "tpcc" } {
foreach { val } [ dict keys $attributes ] {
uplevel "variable $val"
upvar 1 $val $val
if {[dict exists $attributes $val]} {
set $val [ dict get $attributes $val ]
}}}}
}
