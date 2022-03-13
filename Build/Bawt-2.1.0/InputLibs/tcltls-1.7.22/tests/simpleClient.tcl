#!/bin/sh
# The next line is executed by /bin/sh, but not tcl \
exec tclsh8.3 "$0" ${1+"$@"}

package require tls

set dir			[file join [file dirname [info script]] ../tests/certs]
set OPTS(-cafile)	[file join $dir ca.pem]
set OPTS(-cert)		[file join $dir client.pem]
set OPTS(-key)		[file join $dir client.key]

set OPTS(-host)		lorax
set OPTS(-port)		2468
set OPTS(-debug)	1
set OPTS(-count)	8
set OPTS(-parallel)	1

foreach {key val} $argv {
    if {![info exists OPTS($key)]} {
	puts stderr "Usage: $argv0 ?options?\
		\n\t-debug     boolean   Debugging on or off ($OPTS(-debug))\
		\n\t-cafile    file      Cert. Auth. File ($OPTS(-cafile))\
		\n\t-client    file      Client Cert ($OPTS(-cert))\
		\n\t-ckey      file      Client Key ($OPTS(-key))\
		\n\t-count     num       No of sync. connections to make per client ($OPTS(-count))\
		\n\t-parallel  num       No of parallel clients to run ($OPTS(-parallel))\
		\n\t-host      hostname  Server hostname ($OPTS(-host))\
		\n\t-port      num       Server port ($OPTS(-port))"
	exit
    }
    set OPTS($key) $val
}

if {$OPTS(-parallel) > 1} {
    # If they wanted parallel, we just spawn ourselves several times
    # with the right args.

    set cmd	[info nameofexecutable]
    set script	[info script]
    for {set i 0} {$i < $OPTS(-parallel)} {incr i} {
	eval [list exec $cmd $script] [array get OPTS] [list -parallel 0] &
    }
    exit
}

# Local handler for any background errors.
proc bgerror {msg} { puts "BGERROR: $msg" }

# debugging helper code
proc shortstr {str} {
    return "[string replace $str 10 end ...] [string length $str]b"
}
proc dputs {msg} { if {$::OPTS(-debug)} { puts stderr $msg ; flush stderr } }

set OPTS(openports)	0

# Define what we want to feed down the pipe
set megadata [string repeat [string repeat A 76]\n 1000]

proc drain {chan} {
    global OPTS
    if {[catch {read $chan} data]} {
	#dputs "EOF $chan ([shortstr $data])"
	incr OPTS(openports) -1
	catch {close $chan}
	return
    }
    #if {$data != ""} { dputs "got $chan ([shortstr $data])" }
    if {[string match *CLOSE\n $data]} {
	dputs "CLOSE $chan"
	incr OPTS(openports) -1
	close $chan
	return
    } elseif {[eof $chan]} {
	# client gone or finished
	dputs "EOF $chan"
	incr OPTS(openports) -1
	close $chan
	return
    }
}

proc feed {sock} {
    dputs "feed $sock ([shortstr $::megadata])"
    puts $sock $::megadata
    flush $sock
    puts $sock CLOSE
    flush $sock
    fileevent $sock writable {}
}

proc go {} {
    global OPTS
    for {set num $OPTS(-count)} {$num > 0} {incr num -1} {
	set sock [tls::socket $OPTS(-host) $OPTS(-port)]
	incr OPTS(openports)
	fconfigure $sock -blocking 0 -buffersize 4096
	fileevent $sock writable [list feed $sock ]
	fileevent $sock readable [list drain $sock]
	dputs "created $sock"
    }
    while {1} {
	# Make sure to wait until all our sockets close down.
	vwait OPTS(openports)
	if {$OPTS(openports) == 0} {
	    exit 0
	}
    }
}

tls::init -cafile $OPTS(-cafile) -certfile $OPTS(-cert) -keyfile $OPTS(-key)

go
