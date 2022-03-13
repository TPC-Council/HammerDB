#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" "$@"

load "../src/.libs/libdb2tcl.so"

puts "Executing test3:"

puts "First connection to database SAMPLE..."
set conn1 [db2_connect SAMPLE]
puts "Second connection to database SAMPLE..."
set conn2 [db2_connect SAMPLE]
puts "Third connection to database SAMPLE..."
set conn3 [db2_connect SAMPLE]

puts "$conn1 $conn2 $conn3"


db2_disconnect $conn2

set conn2 [db2_connect SAMPLE]

puts "$conn1 $conn2 $conn3"

db2_disconnect $conn3

puts "$conn1 $conn2 $conn3"

db2_disconnect $conn1
db2_disconnect $conn2


