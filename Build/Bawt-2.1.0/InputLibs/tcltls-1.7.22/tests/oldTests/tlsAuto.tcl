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
array set opts {
    -port	1234
    -host	localhost
}
array set opts $argv
#
# Initialize context
#
#tls::init -certfile client.pem -cafile server.pem ;#-cipher RC4-MD5
tls::init
#
# Create socket and import SSL layer
#
#set chan [tls::socket -async -request 0 $opts(-host) $opts(-port)]
set chan [tls::socket -request 0 $opts(-host) $opts(-port)]

fconfigure $chan -buffering none -blocking 0 -translation binary
fileevent $chan readable [list fromServer $chan]

doit $chan 1000 100
vwait /Exit
