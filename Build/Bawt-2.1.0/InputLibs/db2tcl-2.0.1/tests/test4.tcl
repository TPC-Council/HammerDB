#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

#lappend auto_path /usr/lib/tcl_local $env(RDS_TCL_SCRIPTS)/lib

load "../src/.libs/libdb2tcl.so"

puts "Executing test4:"


puts "Connect to database SAMPLE..."
set conn1 [db2_connect SAMPLE]

puts "Query table DB2TCL by operator select... "
set res [db2_select $conn1 "SELECT * FROM db2tcl WHERE ID=1" ]

puts "Fetch all rows from query result..."

while {[set line [db2_fetchrow $res]] != ""} {
  puts "$line"
}

db2_finish $res

puts "Disconnect from database SAMPLE..."
db2_disconnect $conn1

