#
#  Compatability module.
#
#  In oratcl 4.0, there have been some backwardly incompatible changes
#  The most notable are the API changes to orafetch, the removal of
#  the oramsg array.  And the change in oraplexec to return the return
#  code instead of the data list.
#


#
#  purpose::
#
#  override the orafetch proc to work with the old API
#
#  usage::
#
#  orafetch handle command subspec varname column_no ... ...
#  orafetch handle command subspec {varname column_no} {varname col_no} ...
#

rename orafetch orafetchOrig
proc orafetch {args} {
	global oramsg

	set oramsg(rc) 0
	set loop false
	set argc [llength $args]

	if {$argc < 1} {
		return -code error
	}

	set handle [lindex $args 0]

	set jx 1
	for {set ix 3} {$ix < $argc} {incr ix} {

		set arg [lindex $args $ix]		

		if {[llength $arg] == 1} {
			set varname [lindex $args $ix]
			incr ix 1
			if {$ix < $argc} {	
				set colnumb [lindex $args $ix]
				upvar $varname $varname
				set evalArray($jx) "set $varname \$resArray($jx)"
			} else {
				break
			}
		}

		if {[llength $arg] == 2} {
			set varname [lindex $arg 0]
			set colnumb [lindex $arg 1]
			upvar $varname $varname
			set evalArray($jx) "set $varname \$resArray($jx)"
		}

		incr jx
	}

	set sub @
	if {$argc >= 3} {
		set sub [lindex $args 2]
	}

	if {$argc >= 2} {

		set command [lindex $args 1]
		if {! [string is space $command]} {
			set resList {}
			set loop true
			set pat ${sub}0
			regsub -all $pat $command \$resList command

			set colCount [llength [oracols $handle name]]
			for {set ix 1} {$ix <= $colCount} {incr ix} {
				set pat ${sub}$ix
				regsub -all $pat $command \$resArray($ix) command
			}

		}
	}
	
	if {$loop} {
		set res {}
		while {[::oratcl::orafetch $handle -datavariable resList -dataarray resArray -indexbynumber -command $command] == 0} {}
		set oramsg(rc) [oramsg $handle rc]
		set res $resList
		return $res
	} else {
		set res {}
		::oratcl::orafetch $handle -datavariable resList -dataarray resArray -indexbynumber
		set oramsg(rc) [oramsg $handle rc]

		if {[oramsg $handle rc] == 0} {
			set resArray(0) $resList
			foreach el [array names evalArray] {
				eval $evalArray($el)
			}
		} else {
			set resList {}
		}

		set res $resList
		return $res
	}
}
