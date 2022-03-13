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

set handle [mysqlconnect -user root]

# use implicit database notation
puts "1 rows [mysqlsel $handle {select * from uni.Student}]"
puts "1 Table-col [mysqlcol $handle -current {name type length table non_null prim_key decimals numeric}]"
puts "1 [mysqlnext $handle]"

# Test sel and next functions
mysqluse $handle uni
puts "rows [mysqlsel $handle {select * from Student} -list]"
