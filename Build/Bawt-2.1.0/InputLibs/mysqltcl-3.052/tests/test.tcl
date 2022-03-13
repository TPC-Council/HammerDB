#!/usr/bin/tcl
# Simple Test file to test all mysqltcl commands and parameters
# please create test database first
# from test.sql file
# >mysql -u root
# >create database uni;
#
# >mysql -u root <test.sql
# please adapt the parameters for mysqlconnect some lines above

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
proc prepareTestDB {} {
    global dbank
    set handle [getConnection {} 0]
    if {[lsearch [mysqlinfo $handle databases] $dbank]<0} {
        puts "Testdatabase $dbank does not exist. Create it"
        mysqlexec $handle "CREATE DATABASE $dbank"
    }
    mysqluse $handle $dbank
    
    catch {mysqlexec $handle {drop table Student}}

    mysqlexec $handle {
       	CREATE TABLE Student (
 		MatrNr int NOT NULL auto_increment,
		Name varchar(20),
		Semester int,
		PRIMARY KEY (MatrNr)
	)
    }
    mysqlexec $handle "INSERT INTO Student VALUES (1,'Sojka',4)"
    mysqlexec $handle "INSERT INTO Student VALUES (2,'Preisner',2)"
    mysqlexec $handle "INSERT INTO Student VALUES (3,'Killar',2)"
    mysqlexec $handle "INSERT INTO Student VALUES (4,'Penderecki',10)"
    mysqlexec $handle "INSERT INTO Student VALUES (5,'Turnau',2)"
    mysqlexec $handle "INSERT INTO Student VALUES (6,'Grechuta',3)"
    mysqlexec $handle "INSERT INTO Student VALUES (7,'Gorniak',1)"
    mysqlexec $handle "INSERT INTO Student VALUES (8,'Niemen',3)"
    mysqlexec $handle "INSERT INTO Student VALUES (9,'Bem',5)"
    mysqlclose $handle
}

prepareTestDB

tcltest::test {connect-1.1} {no encoding} -body {
	getConnection {-encoding nonexisting}
} -returnCodes error -match glob -result "*unknown encoding*"

tcltest::test {connect-1.2} {binary encoding} -body {
	set handle [getConnection {-encoding binary}]
	mysqlclose $handle
	return
}

tcltest::test {connect-1.3} {-ssl option} -body {
	set handle [getConnection {-ssl 1}]
	mysqlclose $handle
	return
}

tcltest::test {connect-1.4} {-noschema option 1} -body {
	set handle [getConnection {-noschema 1}]
	mysqlclose $handle
	return
}

tcltest::test {connect-1.5} {-noschema option 0} -body {
	set handle [getConnection {-noschema 0}]
	mysqlclose $handle
	return
}

tcltest::test {connect-1.6} {-comperss option} -body {
	set handle [getConnection {-compress 1}]
	mysqlclose $handle
	return
}

tcltest::test {connect-1.7} {-odbc option} -body {
	set handle [getConnection {-odbc 1}]
	mysqlclose $handle
	return
}

tcltest::test {connect-1.8} {Test of encondig option} -body {
	set handle [getConnection {-encoding iso8859-1}]
	set name {Artur Trzewik}
	mysqlexec $handle "INSERT INTO Student (Name,Semester) VALUES ('$name',11)"
	set newid [mysqlinsertid $handle]
	set rname [lindex [lindex [mysqlsel $handle "select Name from Student where MatrNr = $newid" -list] 0] 0]
	mysqlexec $handle "DELETE FROM Student WHERE MatrNr = $newid"
	mysqlclose $handle
	return $rname
} -result {Artur Trzewik}

tcltest::test {baseinfo-1.0} {base info} -body {
	mysqlbaseinfo connectparameters
	mysqlbaseinfo clientversion
	return
}

tcltest::test {select-1.0} {use implicit database notation} -body {
   set handle [getConnection {} 0]
   mysqlsel $handle "select * from $dbank.Student"
   mysqlcol $handle -current {name type length table non_null prim_key decimals numeric}
   mysqlnext $handle
   mysqlinfo $handle databases
   mysqlclose $handle
   return
}

set handle [getConnection]

tcltest::test {use-1.0} {false use} -body {
    mysqluse $handle notdb2
} -returnCodes error -match glob -result "mysqluse/db server: Unknown database 'notdb2'"


tcltest::test {select-1.1} {Test sel and next functions} -body {
   mysqluse $handle uni
   set allrows [mysqlsel $handle {select * from Student}]
   mysqlcol $handle -current {name type length table non_null prim_key decimals numeric}
   # result status
   mysqlresult $handle cols
   set rows [mysqlresult $handle rows]
   set rowsComp [expr {$allrows==$rows}]
   set fstcurrent [mysqlresult $handle current]
   set firstRow [mysqlnext $handle]
   set scdcurrent [mysqlresult $handle current]
   mysqlnext $handle
   mysqlnext $handle
   mysqlseek $handle 0
   set scdcurrent2 [mysqlresult $handle current]
   set isFirst [expr {[mysqlnext $handle] eq $firstRow}]
   mysqlnext $handle
   return [list $fstcurrent $scdcurrent $rowsComp $scdcurrent2 $isFirst]
} -result {0 1 1 0 1}

tcltest::test {map-1.0} {map function} -body {
    mysqlsel $handle {
       select MatrNr,Name from Student order by Name
    }
    mysqlmap $handle {nr name} {
        if {$nr == {}} continue
        set tempr [list $nr $name]
        set row [format  "nr %16s  name:%s"  $nr $name]
    }
    return
}
tcltest::test {map-1.1} {double map with seek} -body {
	#read after end by map
	mysqlsel $handle {select * from Student}
	mysqlmap $handle {nr name} {
    	set row [format  "nr %16s  name:%s"  $nr $name]
	}
	mysqlseek $handle 0
  	mysqlmap $handle {nr name} {
		set row [format  "nr %16s  name:%s"  $nr $name]
    }
	return
}


tcltest::test {receive-1.0} {base case} -body {
    mysqlreceive $handle {select MatrNr,Name from Student order by Name} {nr name} {
       set res [list $nr $name]
    }
    return
}

tcltest::test {receive-1.1} {with break} -body {
    set count 0
    mysqlreceive $handle {select MatrNr,Name from Student order by Name} {nr name} {
       set res [list $nr $name]
       if ($count>0) break
       incr count
    }
    return
}

tcltest::test {receive-1.2} {with error} -body {
    set count 0
    mysqlreceive $handle {select MatrNr,Name from Student order by Name} {nr name} {
       set res [list $nr $name]
       if ($count>0) {
           error "Test Error"
       }
       incr count
    }
    return
} -returnCodes error -result "Test Error"

tcltest::test {query-1.0} {base case} -body {
	set query1 [mysqlquery $handle {select MatrNr,Name From Student Order By Name}]
    mysqlnext $query1
    set query2 [mysqlquery $handle {select MatrNr,Name From Student Order By Name}]
	mysqlnext $query2
	mysqlendquery $query1
	mysqlnext $query2
	mysqlresult $query2 cols
    mysqlresult $query2 rows
    mysqlresult $query2 current
    mysqlseek $query2 0
	mysqlnext $query2
	mysqlresult $query2 current
	mysqlcol $query2 -current {name type length table non_null prim_key decimals numeric}
	mysqlendquery $query2
 	return
}

tcltest::test {query-1.1} {endquery on handle} -body {
	mysqlsel $handle {select * from Student}
    mysqlendquery $handle
    mysqlresult $handle current
} -returnCodes error -match glob -result "*no result*"

tcltest::test {status-1.0} {read status array} -body {
	set ret "code=$mysqlstatus(code) command=$mysqlstatus(command) message=$mysqlstatus(message) nullvalue=$mysqlstatus(nullvalue)"
	return
}

tcltest::test {insert-1.0} {new insert id check} -body {
	mysqlexec $handle {INSERT INTO Student (Name,Semester) VALUES ('Artur Trzewik',11)}
	set newid [mysqlinsertid $handle]
	mysqlexec $handle "UPDATE Student SET Semester=12 WHERE MatrNr=$newid"
	mysqlinfo $handle info
	mysqlexec $handle "DELETE FROM Student WHERE MatrNr=$newid"
} -result 1

tcltest::test {nullvalue-1.0} {null value handling} -body {
	# Test NULL Value setting
	mysqlexec $handle {INSERT INTO Student (Name) VALUES (Null)}
	set id [mysqlinsertid $handle]
	set mysqlstatus(nullvalue) NULL
	set res [lindex [mysqlsel $handle "select Name,Semester from Student where MatrNr=$id" -list] 0]
	lindex $res 1
} -result NULL

tcltest::test {schema-1.0} {querry on schema} -body {
	# Metadata querries
	mysqlcol $handle Student name
	mysqlcol $handle Student {name type length table non_null prim_key decimals numeric}
	return
}

tcltest::test {info-1.0} {info} -body {
	mysqlinfo $handle databases
	mysqlinfo $handle dbname
	mysqlinfo $handle host
	mysqlinfo $handle tables
	mysqlinfo $handle dbname?
	mysqlinfo $handle host?
	return
}

tcltest::test {state-1.0} {state} -body {
	mysqlstate $handle
	mysqlstate $handle -numeric
	return
}

tcltest::test {errorhandling-1.0} {not a handle} -body {
	mysqlsel bad0 {select * from Student}
} -returnCodes error -match glob -result "*not mysqltcl handle*"

tcltest::test {errorhandling-1.1} {error in sql select, no table} -body {
	mysqlsel $handle {select * from Unknown}
} -returnCodes error -match glob -result "*Table*"

tcltest::test {errorhandling-1.2} {error in sql} -body {
	mysqlexec $handle {unknown command}
} -returnCodes error -match glob -result "*SQL syntax*"

tcltest::test {errorhandling-1.3} {read after end} -body {
	set rows [mysqlsel $handle {select * from Student}]
	for {set x 0} {$x<$rows} {incr x} {
    	set res  [mysqlnext $handle]
	    set nr [lindex $res 0]
	    set name [lindex $res 1]
	    set sem [lindex $res 2]
	}
	mysqlnext $handle
} -result {}


tcltest::test {errorhandling-1.4} {false map binding} -body {
	#read after end by map
	mysqlsel $handle {select * from Student}
	mysqlmap $handle {nr name} {
    	set row [format  "nr %16s  name:%s"  $nr $name]
	}
	mysqlseek $handle 0
  	mysqlmap $handle {nr name err err2} {
		set row [format  "nr %16s  name:%s"  $nr $name]
    }
	return
} -returnCodes error -match glob -result "*too many variables*"

tcltest::test {sel-1.2} {-list option} -body {
	mysqlsel $handle {select * from Student} -list
	return
}

tcltest::test {sel-1.3} {-flatlist option} -body {
	mysqlsel $handle {select * from Student} -flatlist
	return
}

tcltest::test {handle-1.0} {interanl finding handle} -body {
	set shandle [string trim " $handle "]
	mysqlinfo $shandle databases
	return
}

mysqlclose $handle

tcltest::test {handle-1.1} {operation on closed handle} -body {
	mysqlinfo $handle tables
	return
} -returnCodes error -match glob -result "*handle already closed*"

tcltest::test {handle-1.2} {operation on closed handle} -body {
	set a " $handle "
	unset handle
	set a [string trim $a]
	mysqlinfo $a tables
} -returnCodes error -match glob -result "*not mysqltcl handle*"


tcltest::test {handle-1.2} {open 20 connection, close all} -body {
	for {set x 0} {$x<20} {incr x} {
    	lappend handles [getConnection]
	}
	foreach h $handles {
	    mysqlsel $h {select * from Student}
	}
	mysqlclose
	return
}

tcltest::test {handle-1.3} {10 queries, close all} -body {
	set handle [getConnection]
	for {set x 0} {$x<10} {incr x} {
    	lappend queries [mysqlquery $handle {select * from Student}]
	}
	for {set x 0} {$x<10} {incr x} {
		mysqlquery $handle {select * from Student}
	}
	mysqlclose $handle
	mysqlnext [lindex $queries 0]
} -returnCodes error -match glob -result "*handle already closed*"

tcltest::test {handle-1.4} {10 queries, close all} -body {
	set handle [getConnection]
	mysqlquery $handle {select * from Student}
	mysqlclose
	return
}

tcltest::test {handle-1.5} {Testing false connecting} -body {
	mysqlconnect -user nouser -db nodb
} -returnCodes error -match glob -result "*Unknown database*"


set handle [getConnection]

tcltest::test {escape-1.0} {escaping} -body {
	mysqlescape "art\"ur"
	mysqlescape $handle "art\"ur"
	return
}

tcltest::test {ping-1.0} {escaping} -body {
	mysqlping $handle
	return
}

tcltest::test {changeuser-1.0} {escaping} -body {
	mysqlchangeuser $handle root {}
	mysqlchangeuser $handle root {} uni
	return
}

# does not work for mysql4.1
tcltest::test {changeuser-1.1} {no such user} -body {
	mysqlchangeuser $handle root {} nodb
} -returnCodes error -match glob -result "*Unknown database*"

tcltest::test {interpreter-1.0} {mysqltcl in slave interpreter} -body {
	set handle [getConnection]
	set i1 [interp create]
	$i1 eval "
	  package require mysqltcl
	  set hdl [mysqlconnect -user $dbuser -db $dbank]
	"
	interp delete $i1
	mysqlinfo $handle databases
	mysqlclose $handle
	return
}

tcltest::test {mysql::state-1.0} {wrong parameter length} -body {
	mysql::state
	return
} -returnCodes error -match glob -result "*wrong*"

tcltest::cleanupTests
puts "End of test"
