#!/bin/sh
# the next line restarts using tclsh \
exec tcl "$0" "$@"

#lappend auto_path /usr/lib/tcl_local $env(RDS_TCL_SCRIPTS)/lib

load "../src/.libs/libdb2tcl.so"

puts "Executing test1:"

puts "Connect to database SAMPLE..."

set conn1 [db2_connect SAMPLE]

puts "Drop table db2tcl if exist..."

if { [catch { db2_exec $conn1 "DROP TABLE db2tcl"}] } {
      puts stderr "Could not drop table db2tcl.\n"
}

puts "Create table db2tcl..."

db2_exec $conn1 "CREATE TABLE db2tcl (ID INTEGER NOT NULL PRIMARY KEY, NAME CHAR(25))"

puts "Insert data into table db2tcl..."

db2_exec $conn1 "INSERT INTO db2tcl VALUES (1,'West')" 
db2_exec $conn1 "INSERT INTO db2tcl VALUES (2,'Gour')" 
db2_exec $conn1 "INSERT INTO db2tcl VALUES (3,'Manger')" 
db2_exec $conn1 "INSERT INTO db2tcl VALUES (4,'Slava')" 

puts "Query table DB2TCL by operator select... "

set res [db2_select $conn1 "SELECT * FROM db2tcl" ]

puts "Fetch all rows from query result..."

while {[set line [db2_fetchrow $res]] != ""} {
  puts "$line"
}

# Test rollback
puts "Begin transaction..."

db2_begin_transaction $conn1

puts "Insert data into table db2tcl..."

db2_exec $conn1 "INSERT INTO db2tcl VALUES (5,'Pupkin')" 
db2_exec $conn1 "INSERT INTO db2tcl VALUES (6,'Dudkin')" 

puts "Rollback transaction..."

db2_rollback_transaction $conn1

puts "Query table DB2TCL by operator select... "

set res [db2_select $conn1 "SELECT * FROM db2tcl" ]

puts "Fetch all rows from query result..."

while {[set line [db2_fetchrow $res]] != ""} {
  puts "$line"
}

# Test commit
puts "Begin transaction..."

db2_begin_transaction $conn1

puts "Insert data into table db2tcl..."

db2_exec $conn1 "INSERT INTO db2tcl VALUES (5,'Pupkin')" 
db2_exec $conn1 "INSERT INTO db2tcl VALUES (6,'Dudkin')" 

puts "Commit transaction..."

db2_commit_transaction $conn1

puts "Query table DB2TCL by operator select... "

set res [db2_select $conn1 "SELECT * FROM db2tcl" ]

puts "Fetch all rows from query result..."

while {[set line [db2_fetchrow $res]] != ""} {
  puts "$line"
}

puts "Disconnect from database SAMPLE..."

db2_disconnect $conn1
