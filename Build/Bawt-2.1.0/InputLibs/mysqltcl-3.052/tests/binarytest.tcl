#!/usr/bin/tcl
# Write and read file into database
# using 
# binarytest.tcl file
# The output file will be written with file.bin

if {[file exists libload.tcl]} {
    source libload.tcl
} else {
    source [file join [file dirname [info script]] libload.tcl]
}


if {[llength $argv]==0} {
    puts "usage. binarytest.tcl filename. File name should be binary test file that will be put in Datebase read from it and save als filename.bin"
    exit
}

set file [lindex $argv 0]
set fhandle [open $file r]
fconfigure $fhandle -translation binary -encoding binary
set binary [read $fhandle]
close $fhandle

puts "test conection without encoding option"

# What is saved in mysql is dependend from your system encoding
# if system encoding is not utf-8 then data could not be safed correctly
# It is also not so good idea to safe binary data as utf-8.
# I recommend always to use -encoding binary if you handle binary data
# You can alway build multiple handles if you want handle binary and utf-8 data.

set handle [mysqlconnect -user root -db uni]
mysqlexec $handle "INSERT INTO Binarytest (data) VALUES ('[mysqlescape $binary]')"
set id [mysqlinsertid $handle]

set nfile [file tail $file].bin
set fhandle [open $nfile w]
fconfigure $fhandle -translation binary -encoding binary
#set nbinary [lindex [lindex [mysqlsel $handle "SELECT data from Binarytest where id=$id" -list] 0] 0]
mysqlsel $handle "SELECT data from Binarytest where id=$id"
#set nbinary [encoding convertfrom [encoding system] [lindex [mysqlnext $handle] 0]]
set nbinary [lindex [mysqlnext $handle] 0]
puts "primary length [string bytelength $binary] new length [string bytelength $nbinary] - [string length $binary]  [string length $nbinary]"
puts -nonewline $fhandle $nbinary
close $fhandle
if {[catch {exec cmp $file $nfile}]} {
   puts "binary comparing failed primary length [file size $file] new length [file size $nfile]"
} else {
   puts "binary comparing ok"
}
puts "Length in Mysql [mysqlsel $handle "SELECT LENGTH(data) from Binarytest where id=$id" -flatlist]"


puts "test with -encoding binary"
set handle2 [mysqlconnect -user root -db uni -encoding binary]
mysqlexec $handle2 "Update Binarytest set data = '[mysqlescape $binary]' where id=$id"
mysqlsel $handle2 "SELECT data from Binarytest where id=$id"
set nbinary [lindex [mysqlnext $handle2] 0]

set nfile [file tail $file].bin
set fhandle [open $nfile w]
fconfigure $fhandle -translation binary -encoding binary
puts "primary length [string bytelength $binary] new length [string bytelength $nbinary] - [string length $binary]  [string length $nbinary]"
puts -nonewline $fhandle $nbinary
close $fhandle
if {[catch {exec cmp $file $nfile}]} {
   puts "binary comparing failed primary length [file size $file] new length [file size $nfile]"
} else {
   puts "binary comparing ok"
}
puts "Length in Mysql [mysqlsel $handle2 "SELECT LENGTH(data) from Binarytest where id=$id" -flatlist]"


puts "test reading binary data but do not use -binary option but iso8859-1"
# please do not try to read binary data if your system encoding is set to
# utf-8. The converting from it will crash system
set handle2 [mysqlconnect -user root -db uni -encoding iso8859-1]
mysqlsel $handle2 "SELECT data from Binarytest where id=$id"
set nbinary [lindex [mysqlnext $handle2] 0]
set nfile [file tail $file].bin
set fhandle [open $nfile w]
fconfigure $fhandle -translation binary -encoding binary
puts "primary length [string bytelength $binary] new length [string bytelength $nbinary] - [string length $binary]  [string length $nbinary]"
puts -nonewline $fhandle $nbinary
close $fhandle
if {[catch {exec cmp $file $nfile}]} {
   puts "binary comparing failed primary length [file size $file] new length [file size $nfile]"
} else {
   puts "binary comparing ok"
}


puts "test with -encoding iso8859-15"
set handle3 [mysqlconnect -user root -db uni -encoding iso8859-15]
# iso8859-1]
set umlaute "ÄÖ äö ß Deutsch Umlaute 26"
mysqlexec $handle3 "Update Binarytest set data = '$umlaute' where id=$id"
mysqlsel $handle3 "SELECT data from Binarytest where id=$id"
set umlauteOut [lindex [mysqlnext $handle3] 0]

puts "$umlaute $umlauteOut"
if {$umlaute!=$umlauteOut} {
    puts "Umlaut Test Failed"
}

puts "Length in Mysql [mysqlsel $handle3 "SELECT LENGTH(data) from Binarytest where id=$id" -flatlist]"



puts "Testing finished"
