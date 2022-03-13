#!/bin/sh
# The next line is executed by /bin/sh, but not tcl \
exec tclsh8.3 "$0" ${1+"$@"}

package require tls

set dir			[file join [file dirname [info script]] ../tests/certs]
set OPTS(-cafile)	[file join $dir ca.pem]
set OPTS(-cert)		[file join $dir server.pem]
set OPTS(-key)		[file join $dir server.key]

set OPTS(-port)	2468
set OPTS(-debug) 1
set OPTS(-require) 1

foreach {key val} $argv {
    if {![info exists OPTS($key)]} {
	puts stderr "Usage: $argv0 ?options?\
		\n\t-debug    boolean  Debugging on or off ($OPTS(-debug))\
		\n\t-cafile   file     Cert. Auth. File ($OPTS(-cafile))\
		\n\t-cert     file     Server Cert ($OPTS(-cert))\
		\n\t-key      file     Server Key ($OPTS(-key))\
		\n\t-require  boolean  Require Certification ($OPTS(-require))\
		\n\t-port     num      Port to listen on ($OPTS(-port))"
	exit
    }
    set OPTS($key) $val
}

# Catch  any background errors.
proc bgerror {msg} { puts stderr "BGERROR: $msg" }

# debugging helper code
proc shortstr {str} {
    return "[string replace $str 10 end ...] [string length $str]b"
}
proc dputs {msg} { if {$::OPTS(-debug)} { puts stderr $msg ; flush stderr } }

# As a response we just echo the data sent to us.
#
proc respond {chan} {
    if {[catch {read $chan} data]} {
	#dputs "EOF $chan ([shortstr $data)"
	catch {close $chan}
	return
    }
    #if {$data != ""} { dputs "got $chan ([shortstr $data])" }
    if {[eof $chan]} {
	# client gone or finished
	dputs "EOF $chan"
	close $chan		;#  release the port
	return
    }
    puts -nonewline $chan $data
    flush $chan
    #dputs "sent $chan ([shortstr $data])"
}

# Once connection is established, we need to ensure handshake.
#
proc handshake {s cmd} {
    if {[eof $s]} {
	dputs "handshake eof $s"
	close $s
    } elseif {[catch {tls::handshake $s} result]} {
	# Some errors are normal.  Specifically, I (hobbs) believe that
	# TLS throws EAGAINs when it may not need to (or is inappropriate).
	dputs "handshake error $s: $result"
    } elseif {$result == 1} {
	# Handshake complete
	dputs "handshake complete $s"
	fileevent $s readable [list $cmd $s]
    }
}

# Callback proc to accept a connection from a client.
#
proc accept { chan ip port } {
    dputs "[info level 0] [fconfigure $chan]"
    fconfigure $chan -blocking 0
    fileevent $chan readable [list handshake $chan respond]
}

tls::init -cafile $OPTS(-cafile) -certfile $OPTS(-cert) -keyfile $OPTS(-key)
set chan [tls::socket -server accept -require $OPTS(-require) $OPTS(-port)]

puts "Server waiting connection on $chan ($OPTS(-port))"
puts [fconfigure $chan]

vwait __forever__
