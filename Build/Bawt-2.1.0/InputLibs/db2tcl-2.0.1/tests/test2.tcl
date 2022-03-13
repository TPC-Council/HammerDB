#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

load "../src/.libs/libdb2tcl.so"

puts "Executing test2:"

puts "Connect to database SAMPLE and query result..."
set res [db2_select [db2_connect SAMPLE] "SELECT * FROM db2tcl" ]

puts "Fetch 4 rows..."
puts [db2_fetchrow $res]
puts [db2_fetchrow $res]
puts [db2_fetchrow $res]
puts [db2_fetchrow $res]

puts "Disconnect from database SAMPLE..."
db2_disconnect $res

