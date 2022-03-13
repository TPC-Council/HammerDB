if {[file exists libload.tcl]} {
    source libload.tcl
} else {
    source [file join [file dirname [info script]] libload.tcl]
}


# global connect variables
set dbuser root
set dbpassword ""
set dbank mysqltcltest

package require tcltest
variable SETUP {#common setup code}
variable CLEANUP {#common cleanup code}
tcltest::configure -verbose bet

proc getConnection {{addOptions {}} {withDB 1}} {
    global dbuser dbpassword dbank
    if {$withDB} {
        append addOptions " -db $dbank"
    }
    if {$dbpassword ne ""} {
	    append addOptions " -password $dbpassword"
    }
    return [eval mysqlconnect -user $dbuser $addOptions]
}

set c [getConnection]
proc t {} {mysql::sel $::c {select Name from Student}}
t
namespace eval :: {
	set n 3
        mysql::sel $c {select Name from Student}
	mysql::map $c n {
    		puts "$n"
	}
        mysql::receive $c {select Name from Student} { n } {
    		puts "$n"
	}
}

#0  0x08002220 in ?? ()
#1  0x00185ab4 in TclObjLookupVar () from /opt/tcl845-debug//lib/libtcl8.4.so
#2  0x001864f8 in Tcl_ObjSetVar2 () from /opt/tcl845-debug//lib/libtcl8.4.so
#3  0x008967d7 in Mysqltcl_Map () from /home/artur/programs/mysqltcl/libmysqltcl3.01.so
#4  0x001306db in TclEvalObjvInternal () from /opt/tcl845-debug//lib/libtcl8.4.so
#5  0x00151eba in TclExecuteByteCode () from /opt/tcl845-debug//lib/libtcl8.4.so
#6  0x001513c0 in TclCompEvalObj () from /opt/tcl845-debug//lib/libtcl8.4.so
#7  0x001315e6 in Tcl_EvalObjEx () from /opt/tcl845-debug//lib/libtcl8.4.so
#8  0x0015d65b in Tcl_RecordAndEvalObj () from /opt/tcl845-debug//lib/libtcl8.4.so
#9  0x0016fd39 in Tcl_Main () from /opt/tcl845-debug//lib/libtcl8.4.so
#10 0x080486e6 in main ()
