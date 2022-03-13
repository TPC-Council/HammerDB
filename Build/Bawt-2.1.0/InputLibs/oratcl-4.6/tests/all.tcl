# all.tcl --
#
# This file is sourced by the 'make test' target to execute the
# Oratcl test suite
#
# Copyright (c) 2017 by Todd M. Helfter
# All rights reserved.
#
# RCS: @(#) $Id: all.tcl,v 1.13 2017/09/21 17:37:11 tmh Exp $

global ora_lda

source [file join [file dirname [info script]] defs.tcl]
source [file join [file dirname [info script]] startup.tcl]

set testlist [list \
		oralogon.test \
		oraopen.test \
		orainfo.test \
		oraparse.test \
		orabind.test \
		oraexec.test \
		orafetch.test \
		oracols.test \
		oradesc.test \
		oracommit.test \
		oralob.test \
		oralong.test \
		slaveinterps.test \
		orasql.test \
		orabindexec.test \
		oraplexec.test \
		codes.test \
		async.test \
		usertype.test \
		merge.test \
		unicode.test \
		arraydml.test \
	]

#	This test hasn't worked right in ages
#		 i18n.test

foreach test $testlist {
	lappend tests [file join [file dirname [info script]] $test]
}

set testtimes {}
foreach test $tests {
	#puts stdout \n$test
	flush stdout
	set t0 [clock clicks -milliseconds]
	if {[catch {source $test} msg]} {
		puts $msg
	}
	set tD [clock clicks -milliseconds]
	set times "$test :: [expr {$tD - $t0}] ms"
	#puts stdout $times
	lappend testtimes $times
}     

source [file join [file dirname [info script]] cleanup.tcl]

puts stderr "\ntest timings\n"
foreach times $testtimes {
	puts stdout $times
}

unset t0
unset tD
unset test
unset times
unset testlist
unset testtimes
unset ora_server
unset ora_pw
unset ora_userid 
unset ora_constr
