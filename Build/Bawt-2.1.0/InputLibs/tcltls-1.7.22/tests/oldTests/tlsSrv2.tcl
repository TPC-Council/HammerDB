#
# Copyright (C) 1997-2000 Matt Newman <matt@novadigm.com>
#
# Sample Tls-enabled server
#
set dir [file dirname [info script]]
cd $dir
source tls.tcl
#lappend auto_path d:/tcl80/lib
#package require tls

#
# Sample callback - just reflect data back to client
#
proc reflectCB {chan {verbose 0}} {
    if {[catch {read $chan 1024} data]} {
	puts stderr "EOF ($data)"
	catch {close $chan}
	return
    }
	
    if {$verbose && $data != ""} {
	puts -nonewline stderr $data
    }
    if {[eof $chan]} {    ;# client gone or finished
	puts stderr "EOF"
	close $chan        ;# release the servers client channel
	return
    }
    puts -nonewline $chan $data
    flush $chan
}
proc acceptCB { chan ip port } {
    puts "accept: $chan $ip $port"

    if {![tls::handshake $chan]} {
	puts stderr "Handshake pending"
	return
    }
    array set cert [tls::status $chan]
    parray cert

    fconfigure $chan -buffering none -blocking 0
    fileevent $chan readable [list reflectCB $chan 1]
}
tls::init -certfile server.pem -tls1 1 ;#-cipher RC4-SHA

set chan [tls::socket -server acceptCB \
		-request 1 -require 0 -command tls::callback 1234]

puts "Server waiting connection on $chan (1234)"

# Go into the eventloop
vwait /Exit
