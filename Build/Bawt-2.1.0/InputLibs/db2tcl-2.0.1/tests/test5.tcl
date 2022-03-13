#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

#lappend auto_path /usr/lib/tcl_local $env(RDS_TCL_SCRIPTS)/lib

load "../src/.libs/libdb2tcl.so"

puts "Executing test5:"

puts "Connect to database SAMPLE..."
set conn1 [db2 connect SAMPLE]

puts "Query table DB2TCL by operator select... "
set res [db2 select $conn1 "SELECT * FROM DB2TCL"]

puts "Fetch all rows from query result..."

while {[set line [db2_fetchrow $res]] != ""} {
  puts "$line"
}

db2 finish $res

db2_test $res

puts "Disconnect from database SAMPLE..."
db2 disconnect $conn1

