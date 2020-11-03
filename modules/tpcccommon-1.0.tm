package provide tpcccommon 1.0
namespace eval tpcccommon {
namespace export chk_thread RandomNumber NURand Lastname MakeAlphaString Makezip MakeAddress MakeNumberString findchunk findvuposition randname keytime thinktime async_keytime async_thinktime async_time get_connect_xml
#gettimestamp not included as uses different formats per database
#TPCC BUILD PROCEDURES
proc chk_thread {} {
        set chk [package provide Thread]
        if {[string length $chk]} {
            return "TRUE"
            } else {
            return "FALSE"
        }
    }
#RANDOM NUMBER
proc RandomNumber {m M} {return [expr {int($m+rand()*($M+1-$m))}]}
#NON UNIFORM RANDOM NUMBER BUILD AND DRIVE
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#LAST NAME
proc Lastname { num namearr } {
set name [ concat [ lindex $namearr [ expr {( $num / 100 ) % 10 }] ][ lindex $namearr [ expr {( $num / 10 ) % 10 }] ][ lindex $namearr [ expr {( $num / 1 ) % 10 }]]]
return $name
}
#ALPHA STRING
proc MakeAlphaString { x y chArray chalen } {
set len [ RandomNumber $x $y ]
for {set i 0} {$i < $len } {incr i } {
append alphastring [lindex $chArray [ expr {int(rand()*$chalen)}]]
}
return $alphastring
}
#ZIP CODE
proc Makezip { } {
set zip "000011111"
set ranz [ RandomNumber 0 9999 ]
set len [ expr {[ string length $ranz ] - 1} ]
set zip [ string replace $zip 0 $len $ranz ]
return $zip
}
#ADDRESS
proc MakeAddress { chArray chalen } {
return [ list [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 10 20 $chArray $chalen ] [ MakeAlphaString 2 2 $chArray $chalen ] [ Makezip ] ]
}
#NUMBER STRING
proc MakeNumberString { } {
set zeroed "00000000"
set a [ RandomNumber 0 99999999 ]
set b [ RandomNumber 0 99999999 ]
set lena [ expr {[ string length $a ] - 1} ]
set lenb [ expr {[ string length $b ] - 1} ]
set c_pa [ string replace $zeroed 0 $lena $a ]
set c_pb [ string replace $zeroed 0 $lenb $b ]
set numberstring [ concat $c_pa$c_pb ]
return $numberstring
}
#CALCULATE BUILD CHUNK, START AND END
proc findchunk { num_vu count_ware myposition } {
if { [ expr $num_vu + 1 ] > $count_ware } { set num_vu $count_ware }
set chunk [ expr $count_ware / $num_vu ]
set rem [ expr $count_ware % $num_vu ]
if { $rem > $chunk } {
if { [ expr $myposition - 1 ] <= $rem } {
set chunk [ expr $chunk + 1 ]
set mystart [ expr ($chunk * ($myposition - 2)+1) + ($rem - ($rem - $myposition+$myposition)) ]
        } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) + $rem ]
  } } else {
set mystart [ expr ($chunk * ($myposition - 2)+1) ]
        }
set myend [ expr $mystart + $chunk - 1 ]
if  { $myposition eq $num_vu + 1 } { set myend $count_ware }
return [ list $chunk $mystart $myend ]
}
#TPCC DRIVER PROCEDURES
#FIND VIRTUAL USER POSITION
proc findvuposition {}  {
set mythread [thread::id]
set allthreads [split [thread::names]]
if {![catch {set masterthread [ tsv::get application themaster ]}]} {
set idx [lsearch -exact $allthreads $masterthread]
if { $idx != -1 } {
set allthreads [ lreplace $allthreads $idx $idx ]
	}
}
if {![catch {set timeout [tsv::get application timeout]}]} {
if { $timeout eq 0 } {
if {![catch {set countthread [ tsv::get application thecount ]}]} {
set idx [lsearch -exact $allthreads $countthread]
if { $idx != -1 } {
set allthreads [ lreplace $allthreads $idx $idx ]
	     }
          }
       }
    }
if {![catch {set monitorthread [ tsv::get application themonitor ]}]} {
set idx [lsearch -exact $allthreads $monitorthread]
if { $idx != -1 } {
set allthreads [ lreplace $allthreads $idx $idx ]
	}
}
set totalvirtualusers  [llength $allthreads]
set myposition [ expr $totalvirtualusers - [lsearch -exact $allthreads $mythread]]
return [ list $myposition $totalvirtualusers ]
}
#RANDOM NUMBER
proc NURand { iConst x y C } {return [ expr {((([RandomNumber 0 $iConst] | [RandomNumber $x $y]) + $C) % ($y - $x + 1)) + $x }]}
#RANDOM NAME
proc randname { num } {
array set namearr { 0 BAR 1 OUGHT 2 ABLE 3 PRI 4 PRES 5 ESE 6 ANTI 7 CALLY 8 ATION 9 EING }
set name [ concat $namearr([ expr {( $num / 100 ) % 10 }])$namearr([ expr {( $num / 10 ) % 10 }])$namearr([ expr {( $num / 1 ) % 10 }]) ]
return $name
}
#KEYING TIME
proc keytime { keying } {
after [ expr {$keying * 1000} ]
return
}
#THINK TIME
proc thinktime { thinking } {
set thinkingtime [ expr {abs(round(log(rand()) * $thinking))} ]
after [ expr {$thinkingtime * 1000} ]
return
}
#ASYNCH TIME
proc async_time { ast } {  
promise::await [promise::ptimer $ast]
	}
#ASYNCH KEYING TIME
proc async_keytime { keyt clientname callingproc async_verbose } {
if { $async_verbose } { 
set TIME_start [clock clicks -milliseconds]
async_time [ expr $keyt * 1000 ]
set TIME_taken [expr ([clock clicks -milliseconds] - $TIME_start) /1000 ]
puts "keytime:$callingproc:$clientname:$TIME_taken secs" 
	} else {
async_time [ expr $keyt * 1000 ]
	}
}
#ASYNCH THINK TIME
proc async_thinktime { thkt clientname callingproc async_verbose } {
set as_thkt [ expr {abs(round(log(rand()) * $thkt))} ]
if { $async_verbose } { 
set TIME_start [clock clicks -milliseconds]
async_time [ expr $as_thkt * 1000 ]
set TIME_taken [expr ([clock clicks -milliseconds] - $TIME_start) /1000 ]
puts "thinktime:$callingproc:$clientname:$TIME_taken secs"
	} else {
async_time [ expr $as_thkt * 1000 ]
        }
    }
#XML Connect Data
proc get_connect_xml { prefix } {
if [catch {package require xml} ] { error "Failed to load xml package in tpcccommon module" } 
set connect "config/connectpool/$prefix\cpool.xml"
if { [ file exists $connect ] } { 
	set cpool [ ::XML::To_Dict_Ml $connect ] 
	return $cpool
	} else { 
	error "Connect Pool specified but file $connect does not exist" 
	}
    }
}
#Choose a Cursor when using multiple connections
proc pick_cursor { policy cursors cnt len } {
#pick a cursor from the list according to the policy
#puts "input: $policy $cursors $cnt $len"
switch $policy {
#return first cursor
first_named {
return [ lindex $cursors 0 ] 
   }
#return last cursor
last_named {
return [ lindex $cursors end ] 
   } 
#return cursor at random
random {
return [ lindex $cursors [ expr {[ RandomNumber 1 $len ] - 1} ]]
   }
#return cursor in order cycling through the list
round_robin {
return [ lindex $cursors [ expr $cnt % $len ] ]  
   }
#if policy not found use the first cursor
default {
return [ lindex $cursors 0 ]
    }
  }
}

proc printclientcountsync {myposition nocnt pycnt dlcnt slcnt oscnt} {
tsv::keylset clientcount $myposition neworder $nocnt payment $pycnt delivery $dlcnt stocklevel $slcnt orderstatus $oscnt status true
puts "VU$myposition processed neworder $nocnt payment $pycnt delivery $dlcnt stocklevel $slcnt orderstatus $oscnt transactions"
}

proc printclientcountasync {clientname nocnt pycnt dlcnt slcnt oscnt} {
tsv::keylset clientcount $clientname neworder $nocnt payment $pycnt delivery $dlcnt stocklevel $slcnt orderstatus $oscnt status true
puts "$clientname processed neworder $nocnt payment $pycnt delivery $dlcnt stocklevel $slcnt orderstatus $oscnt transactions"
}

proc initializeclientcountsync {totalvirtualusers} {
upvar vu vu
for {set ccnt 2} {$ccnt <= $totalvirtualusers} {incr ccnt} {
tsv::keylset clientcount $ccnt neworder 0 payment 0 delivery 0 stocklevel 0 orderstatus 0 status false
set vu($ccnt) false
}
foreach spcnt {neworder payment delivery stocklevel orderstatus} {
dict set totalcnt $spcnt 0
        }
}

proc initializeclientcountasync {totalvirtualusers async_client} {
upvar vu vu
for {set ccnt 2} {$ccnt <= $totalvirtualusers} {incr ccnt} {
for {set vucnt 1} {$vucnt <= $async_client} {incr vucnt} {
set clientdesc "vuser$ccnt:ac$vucnt"
tsv::keylset clientcount $clientdesc neworder 0 payment 0 delivery 0 stocklevel 0 orderstatus 0 status false
set vu($clientdesc) false
        }
}
foreach spcnt {neworder payment delivery stocklevel orderstatus} {
dict set totalcnt $spcnt 0
        }
}

proc getclienttpmsync {rampup duration totalvirtualusers} {
upvar vu vu
set totalmin [ expr ($rampup + $duration)/60000 ]
#attempt to fetch client data for 2 minutes
for {set clnt 1} { $clnt <=120} {incr clnt} {
set alldone true
for {set ccnt 2} {$ccnt <= $totalvirtualusers} {incr ccnt} {
if [ tsv::keylget clientcount $ccnt status ] {
#data for vuser now available
if $vu($ccnt) {
#data for vuser already captured
        ;
        } else {
#add data to totals
foreach spcnt {neworder payment delivery stocklevel orderstatus} {
dict incr totalcnt $spcnt [ tsv::keylget clientcount $ccnt $spcnt ]
               }
set vu($ccnt) true
        }
      } else {
#VU has not reported
set alldone false
          }
      }
if $alldone {
#all VUs reported, divide all TPM by time duration
puts "CLIENT SIDE TPM : [ dict map {ccnt spcnt} $totalcnt { set spcnt [ expr $spcnt / $totalmin ] } ]"
break
   } else { after 1000 }
}
if !$alldone {
#not all VUs reported
puts "WARNING CLIENT TPM INCOMPLETE : [ dict map {ccnt spcnt} $totalcnt { set spcnt [ expr $spcnt / $totalmin ] } ]"
        }
}

proc getclienttpmasync {rampup duration totalvirtualusers async_client} {
upvar vu vu
set totalmin [ expr ($rampup + $duration)/60000 ]
#attempt to fetch client data for 10 minutes
for {set clnt 1} { $clnt <=600} {incr clnt} {
set alldone true
for {set ccnt 2} {$ccnt <= $totalvirtualusers} {incr ccnt} {
for {set vucnt 1} {$vucnt <= $async_client} {incr vucnt} {
set clientdesc "vuser$ccnt:ac$vucnt"
if [ tsv::keylget clientcount $clientdesc status ] {
#data for vuser now available
if $vu($clientdesc) {
#data for vuser already captured
        ;
        } else {
#add data to totals
foreach spcnt {neworder payment delivery stocklevel orderstatus} {
dict incr totalcnt $spcnt [ tsv::keylget clientcount $clientdesc $spcnt ]
               }
set vu($clientdesc) true
        }
      } else {
#VU has not reported
set alldone false
          }
      }
  }
if $alldone {
#all VUs reported, divide all TPM by time duration
puts "CLIENT SIDE TPM : [ dict map {clientdesc spcnt} $totalcnt { set spcnt [ expr $spcnt / $totalmin ] } ]"
break
   } else { after 1000 }
}
if !$alldone {
#not all VUs reported
puts "WARNING CLIENT TPM INCOMPLETE : [ dict map {clientdesc spcnt} $totalcnt { set spcnt [ expr $spcnt / $totalmin ] } ]"
        }
}
#Check genericdict on loading to define test result format
#Need to use the genericdict tsv as defining in virtual user threads
catch {set genericdict [ tsv::get application genericdict ]}
if { [ info exists genericdict ] } {
if {[dict exists $genericdict benchmark first_result]} {
set res_format [ dict get $genericdict benchmark first_result ]
	} else { set res_format "NOPM" }
} else { set res_format "NOPM" }
if { $res_format eq "TPM" } {
proc testresult { nopm tpm db } {
return "TEST RESULT : System achieved $tpm $db TPM at $nopm NOPM"
	}
	} else {
proc testresult { nopm tpm db } {
return "TEST RESULT : System achieved $nopm NOPM from $tpm $db TPM"
	}
	}
