#!/usr/bin/tcl
# Simple Test file to test all mysqltcl commands and parameters
# up from version mysqltcl 3.0 and mysql 4.1
#
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

    catch {mysql::exec $handle {drop table transtest}}
    mysql::exec $handle {
      create table transtest (
         id int,
         name varchar(20)
      ) ENGINE=BerkeleyDB
    }

    catch {mysql::exec $handle {drop table Student}}
    mysql::exec $handle {
       	CREATE TABLE Student (
 		MatrNr int NOT NULL auto_increment,
		Name varchar(20),
		Semester int,
		PRIMARY KEY (MatrNr)
	)
    }
    mysql::exec $handle "INSERT INTO Student VALUES (1,'Sojka',4)"
    mysql::exec $handle "INSERT INTO Student VALUES (2,'Preisner',2)"
    mysql::exec $handle "INSERT INTO Student VALUES (3,'Killar',2)"
    mysql::exec $handle "INSERT INTO Student VALUES (4,'Penderecki',10)"
    mysql::exec $handle "INSERT INTO Student VALUES (5,'Turnau',2)"
    mysql::exec $handle "INSERT INTO Student VALUES (6,'Grechuta',3)"
    mysql::exec $handle "INSERT INTO Student VALUES (7,'Gorniak',1)"
    mysql::exec $handle "INSERT INTO Student VALUES (8,'Niemen',3)"
    mysql::exec $handle "INSERT INTO Student VALUES (9,'Bem',5)"
    mysql::close $handle
}

prepareTestDB
set conn [getConnection {-multistatement 1 -multiresult 1}]


tcltest::test {null-1.0} {creating of null} {
  set null [mysql::newnull]
  mysql::isnull $null
} {1}

tcltest::test {null-1.1} {null checking} {
  mysql::isnull blabla
} {0}

tcltest::test {null-1.2} {null checking} {
  mysql::isnull [mysql::newnull]
} {1}

tcltest::test {null-1.3} {null checking} {
  mysql::isnull {}
} {0}

tcltest::test {null-1.4} {null checking} {
  mysql::isnull [lindex [list [mysql::newnull]] 0]
} {1}


tcltest::test {autocommit} {setting autocommit} -body {
   mysql::autocommit $conn 0
}
tcltest::test {autocommit} {setting autocommit} -body {
   mysql::autocommit $conn 1
}
tcltest::test {autocommit} {setting false autocommit} -body {
   mysql::autocommit $conn nobool
} -returnCodes error -match glob -result "expected boolean value*"

mysql::autocommit $conn 0

tcltest::test {commit} {commit} -body {
   mysql::autocommit $conn 0
   mysqlexec $conn {delete from transtest where name='committest'}
   mysqlexec $conn {insert into transtest (name,id) values ('committest',2)}
   mysql::commit $conn
   set res [mysqlexec $conn {delete from transtest where name='committest'}]
   mysql::commit $conn
   return $res
} -result 1

tcltest::test {rollback-1.0} {roolback} -body {
   mysql::autocommit $conn 0
   mysqlexec $conn {delete from transtest where name='committest'}
   mysqlexec $conn {insert into transtest (name,id) values ('committest',2)}
   mysql::rollback $conn
   set res [mysqlexec $conn {delete from transtest where name='committest'}]
   mysql::commit $conn
   return $res
} -result 0

tcltest::test {rollback-1.1} {roolback by auto-commit 1} -body {
   mysql::autocommit $conn 1
   mysqlexec $conn {delete from transtest where name='committest'}
   mysqlexec $conn {insert into transtest (name,id) values ('committest',2)}
   # rollback should not affect
   mysql::rollback $conn
   set res [mysqlexec $conn {delete from transtest where name='committest'}]
   return $res
} -result 1


tcltest::test {warning-count-1.0} {check mysql::warningcount} -body {
   set list [mysql::sel $conn {select * from Student} -list]
   mysql::warningcount $conn
} -result 0

tcltest::test {multistatement-1.0} {inserting multi rows} -body {
   mysql::exec $conn {
      insert into transtest (name,id) values ('row1',31);
      insert into transtest (name,id) values ('row2',32);
      insert into transtest (name,id) values ('row3',33),('row4',34);
   }

} -result {1 1 2}

tcltest::test {moreresult-1.3} {arg counts} -body {
   mysql::moreresult
} -returnCodes error -match glob -result "wrong # args:*"

tcltest::test {moreresult-1.0} {only one result} -body {
   mysql::ping $conn
   mysql::sel $conn {select * from transtest}
   mysql::moreresult $conn
} -result 0

tcltest::test {moreresult-1.1} {only one result} -body {
   mysql::ping $conn
   mysql::sel $conn {
      select * from transtest;
      select * from Student;
   }
   while {[llength [mysql::fetch $conn]]>0} {}
   if {[set ret [mysql::moreresult $conn]]} {
      # mysql::nextresult $conn
   }
   return $ret
} -result 1

tcltest::test {nextresult-1.0} {only one result} -body {
   mysql::ping $conn
   mysql::sel $conn {
      select * from transtest;
      select * from Student;
   }
   while {[llength [set row [mysql::fetch $conn]]]>0} {
   }
   mysql::nextresult $conn
   set hadRow 0
   while {[llength [set row [mysql::fetch $conn]]]>0} {
      set hadRow 1
   }
   return $hadRow
} -result 1 -returnCodes 2

tcltest::test {nextresult-rows-1.1} {rows number} -body {
   mysql::ping $conn
   mysql::sel $conn {
      select name from Student where name='Sojka';
      select name,semester from Student;
   }
   set r1 [mysql::result $conn cols]
   mysql::nextresult $conn
   set r2 [mysql::result $conn cols]
   expr {$r1+$r2}
} -result 3

tcltest::test {setserveroption-1.0} {set multistatment off} -body {
   mysql::setserveroption $conn -multi_statment_off
   mysql::exec $conn {
      insert into transtest (name,id) values ('row1',31);
      insert into transtest (name,id) values ('row2',32);
      insert into transtest (name,id) values ('row3',33);
   }
} -returnCodes error -match glob -result "mysql::exec/db server*"

tcltest::test {setserveroption-1.1} {set multistatment on} -body {
   mysql::setserveroption $conn -multi_statment_on
   mysql::exec $conn {
      insert into transtest (name,id) values ('row1',31);
      insert into transtest (name,id) values ('row2',32);
      insert into transtest (name,id) values ('row3',33);
   }
   return
}

tcltest::test {info-1.0} {asking about host} -body {
   set res [mysql::info $conn host]
   expr {[string length $res]>0}
} -result 1

tcltest::test {info-1.1} {serverversion} -body {
  mysql::info $conn serverversion
  expr {[mysql::info $conn serverversionid]>0}
} -result 1

tcltest::test {info-1.2} {sqlstate} -body {
  mysql::info $conn sqlstate
  return
}

tcltest::test {info-1.3} {sqlstate} -body {
  mysql::info $conn state
  return
}

tcltest::test {state-1.0} {reported bug in 3.51} -body {
  mysql::state nothandle -numeric
} -result 0

tcltest::test {state-1.1} {reported bug in 3.51} -body {
  mysql::state nothandle
} -result NOT_A_HANDLE

tcltest::test {null-2.0} {reading and checking null from database} -body {
  mysql::ping $conn
  mysql::autocommit $conn 1
  mysql::exec $conn {
       delete from transtest where name="nulltest"
  }
  mysql::exec $conn {
       insert into transtest (name,id) values ('nulltest',NULL);
  }
  mysql::sel $conn {select id from transtest where name='nulltest'}
  set res [lindex [mysql::fetch $conn] 0]
  mysql::isnull $res
} -result 1

tcltest::test {baseinfo-1.0} {clientversionid} -body {
  expr {[mysql::baseinfo clientversionid]>0}
} -result 1

tcltest::test {encoding-1.0} {read system encoding} -body {
  mysql::encoding $conn
} -result [encoding system]

tcltest::test {encoding-1.1} {change to binary} -body {
  mysql::encoding $conn binary
  mysql::exec $conn "INSERT INTO Student (Name,Semester) VALUES ('Test',4)"
  mysql::encoding $conn
} -result binary

tcltest::test {encoding-1.2} {change to binary} -body {
  mysql::encoding $conn [encoding system]
  mysql::exec $conn "INSERT INTO Student (Name,Semester) VALUES ('Test',4)"
  mysql::encoding $conn
} -result [encoding system]

tcltest::test {encoding-1.3} {change to binary} -body {
  mysql::encoding $conn iso8859-1
  mysql::exec $conn "INSERT INTO Student (Name,Semester) VALUES ('Test',4)"
  mysql::encoding $conn
} -result iso8859-1

tcltest::test {encoding-1.4} {unknown encoding} -body {
  mysql::encoding $conn unknown
} -returnCodes error -match glob -result "unknown encoding*"

tcltest::test {encoding-1.5} {changing encoding of query handle} -body {
  set q [mysql::query $conn "select * from Student"]
  mysql::encoding $q iso8859-1
} -cleanup {
  mysql::endquery $q
} -returnCodes error -result "encoding set can be used only on connection handle"

tcltest::test {encoding-1.6} {changing encoding of handle} -body {
  mysql::encoding $conn iso8859-1
  set q [mysql::query $conn "select * from Student"]
  mysql::encoding $q
} -cleanup {
  mysql::endquery $q
} -result iso8859-1

tcltest::test {encoding-1.7} {changing encoding of handle} -body {
  set q [mysql::query $conn "select * from Student"]
  mysql::encoding $conn iso8859-1
  mysql::encoding $q
} -cleanup {
  mysql::endquery $q
} -result iso8859-1

tcltest::test {encoding-1.8} {changing encoding of handle} -body {
  mysql::encoding $conn utf-8
  set q [mysql::query $conn "select * from Student"]
  mysql::encoding $conn iso8859-1
  mysql::encoding $q
} -cleanup {
  mysql::endquery $q
} -result iso8859-1

tcltest::test {encoding-1.8} {changing encoding of handle} -body {
  mysql::encoding $conn iso8859-5
  set q [mysql::query $conn "select Name from Student"]
  mysql::encoding $conn utf-8
  mysql::fetch $q
  mysql::endquery $q
  return    
}

# no prepared statements in this version
if 0 {

tcltest::test {preparedstatment-1.0} {create test} -body {
  set phandle [mysql::prepare $conn {insert into transtest (id,name) values (?,?)}]
  mysql::close $phandle
  return
}

tcltest::test {preparedstatment-1.1} {create errortest} -body {
  set phandle [mysql::prepare $conn {nosql command ?,?}]
  mysql::close $phandle
  return
} -returnCodes error -match glob -result "*SQL*"

tcltest::test {preparedstatment-1.3} {select} -body {
  set phandle [mysql::prepare $conn {select id,name from transtest}]
  mysql::pselect $phandle
  set rowcount 0
  while {[llength [set row [mysql::fetch $phandle]]]>0} {
  	 incr rowcount
  }
  mysql::close $phandle
  return
}


tcltest::test {preparedstatment-1.2} {insert} -body {
  set phandle [mysql::prepare $conn {insert into transtest (id,name) values (?,?)}]
  set count [mysql::param $phandle count]
  mysql::param $phandle type 0
  mysql::param $phandle type 1
  mysql::param $phandle type
  mysql::pexecute $phandle 2 Artur
  mysql::close $phandle
  return $count
} -result 2


tcltest::test {preparedstatment-1.4} {select mit bind} -body {
  set phandle [mysql::prepare $conn {select id,name from transtest where id=?}]
  set countin [mysql::paramin $phandle count]
  set countout [mysql::paramin $phandle count]
  mysql::paramin $phandle type 0
  mysql::paramin $phandle type
  mysql::paramout $phandle type 0
  mysql::paramout $phandle type 1
  mysql::paramout $phandle type
  mysql::execute $phandle
  mysql::close $phandle
  list $countin $countout
} -result {1 2}

}

tcltest::cleanupTests

puts "End of test"

