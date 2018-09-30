package provide tpcccommon 1.0
namespace eval tpcccommon {
namespace export chk_thread RandomNumber NURand Lastname MakeAlphaString Makezip MakeAddress MakeNumberString findchunk findvuposition randname keytime thinktime
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
}
