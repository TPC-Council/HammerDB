#
# Copyright (C) 1997-2000 Matt Newman <matt@novadigm.com>
#

set dir [file dirname [info script]]
cd $dir
source tls.tcl

proc fromServer {chan} {
    if {[catch {read $chan 10} data]} {
	catch {close $chan}
	tclLog "EOF ($data)"
	set ::/Exit 1
	return
    }
    if {[eof $chan]} {
	close $chan
	set ::/Exit 1
    }
    if {$data != ""} {
	puts -nonewline stderr "$data"
    }
}
proc doit {chan count {delay 1000}} {
    if {$count == 0} {
	close $chan
	set ::/Exit 0
	return
    }
    puts $chan line$count
    flush $chan

    incr count -1
    after $delay doit $chan $count $delay
}
proc done {chan bytes {error ""}} {
    set ::/Exit 1
    tclLog "fcopy done: $bytes ($error) eof=[eof $chan]"
}
#
# Initialize Context
#
tls::init -certfile client.pem -cafile server.pem
#
# Create and import socket
#
set chan [tls::socket -request 1 localhost 1234]

fconfigure $chan -buffering full

set fp [open [lindex $argv 0]]
fcopy $fp $chan -command [list done $chan]
#fileevent $chan readable [list fromServer $chan]
vwait /Exit
tclLog Exiting...
