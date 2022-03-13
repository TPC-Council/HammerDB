#!/bin/sh
# the next line restarts using wish \
exec tclsh8.4 "$0" "$@" 

package require Oratcl

source  $env(HOME)/work/oratcl-head/library/oralob.tcl


proc convert_function {procname} {

	set a [info args $procname]
	set b [info body $procname]

	puts stdout "\t/*"
	puts stdout "\t *  Create the $procname proc."
	puts stdout "\t */"
	puts stdout "\tproc = \"proc $procname {$a} { \""
	foreach l [split $b \n] {
		putline $l
	}
	puts stdout "\t\t\"} \";"
	puts stdout {}
	puts stdout "\tTcl_Eval(interp, proc);"
	puts stdout {}
}

proc putline {line} {

	if {[string is space $line]} {
		return
	}
	set l1 [string trim $line]
	if {[string equal [string range $l1 0 0] #]} {
		return
	}

	regsub -all \" $line \\\\" line
	if {[info complete $line]} {
		puts stdout [format "\t\t\"%s; \"" $line]
	} else {
		puts stdout [format "\t\t\"%s \"" $line]
	}
}

proc ::oratcl::export_variable {args} {
	set name [lindex $args 0]
	puts [format \
		"\tTcl_SetVar(interp, \n\t\t   \"%s\", \n\t\t   \"%s\", \n\t\t   0);\n" \
		$name \
		[string trim [set [set name]]]]
}

proc ::oratcl::export_array {args} {

	set name [lindex $args 0]
	foreach idx [array names $name] {
		set y "${name}(${idx})"
		puts [format \
			"\tTcl_SetVar2(interp, \n\t\t   \"%s\", \n\t\t   \"%s\", \n\t\t   \"%s\", \n\t\t   0);\n" \
			$name \
			$idx \
			[string trim [set [set y]]]]
	}
}

proc build_namespace {args} {
	set variables [lindex $args 0]
	foreach var $variables {
		::oratcl::export_variable $var
	}

	set arrays [lindex $args 1]
	foreach var $arrays {
		::oratcl::export_array $var
	}

#puts "var = $var"
}

puts stdout {#include "oratclInt.h"}
puts stdout {#include "oratcl.h"}
puts stdout {#include <tcl.h>}
puts stdout {}
puts stdout int
puts stdout {Oralob_Init (interp)}
puts stdout "\tTcl_Interp\t*interp;"
puts stdout "\{"
puts stdout "\tchar\t\t*proc;"
puts stdout "\tint\t\ttcl_return = TCL_OK;"
puts stdout "\tint\t\ttcl_rc;"
puts stdout {}

build_namespace [list ::oratcl::lobidx] [list ::oratcl::plsql ::oratcl::oralob]
convert_function oralob
foreach procname [list parse_lob_args lob_alloc lob_free lob_read lob_write lob_length lob_trim lob_erase lob_substr lob_instr lob_append lob_compare] {
	convert_function ::oratcl::$procname
}

puts "\treturn tcl_return;";
puts "\}"
