#
# Copyright (C) 1997-2000 Matt Newman <matt@novadigm.com> 
#
namespace eval tls {
    variable logcmd tclLog
    variable debug 0
 
    # Default flags passed to tls::import
    variable defaults {}

    # Maps UID to Server Socket
    variable srvmap
    variable srvuid 0

    # Over-ride this if you are using a different socket command
    variable socketCmd
    if {![info exists socketCmd]} {
        set socketCmd [info command ::socket]
    }

    # This is the possible arguments to tls::socket and tls::init
    # The format of this is a list of lists
    ## Each inner list contains the following elements
    ### Server (matched against "string match" for 0/1)
    ### Option name
    ### Variable to add the option to:
    #### sopts: [socket] option
    #### iopts: [tls::import] option
    ### How many arguments the following the option to consume
    variable socketOptionRules {
        {0 -async sopts 0}
        {* -myaddr sopts 1}
        {0 -myport sopts 1}
        {* -type sopts 1}
        {* -cadir iopts 1}
        {* -cafile iopts 1}
        {* -cert iopts 1}
        {* -certfile iopts 1}
        {* -cipher iopts 1}
        {* -command iopts 1}
        {* -dhparams iopts 1}
        {* -key iopts 1}
        {* -keyfile iopts 1}
        {* -password iopts 1}
        {* -request iopts 1}
        {* -require iopts 1}
        {* -autoservername discardOpts 1}
        {* -servername iopts 1}
        {* -ssl2 iopts 1}
        {* -ssl3 iopts 1}
        {* -tls1 iopts 1}
        {* -tls1.1 iopts 1}
        {* -tls1.2 iopts 1}
        {* -tls1.3 iopts 1}
    }

    # tls::socket and tls::init options as a humane readable string
    variable socketOptionsNoServer
    variable socketOptionsServer

    # Internal [switch] body to validate options
    variable socketOptionsSwitchBody
}

proc tls::_initsocketoptions {} {
    variable socketOptionRules
    variable socketOptionsNoServer
    variable socketOptionsServer
    variable socketOptionsSwitchBody

    # Do not re-run if we have already been initialized
    if {[info exists socketOptionsSwitchBody]} {
        return
    }

    # Create several structures from our list of options
    ## 1. options: a text representation of the valid options for the current
    ##             server type
    ## 2. argSwitchBody: Switch body for processing arguments
    set options(0) [list]
    set options(1) [list]
    set argSwitchBody [list]
    foreach optionRule $socketOptionRules {
        set ruleServer [lindex $optionRule 0]
        set ruleOption [lindex $optionRule 1]
        set ruleVarToUpdate [lindex $optionRule 2]
        set ruleVarArgsToConsume [lindex $optionRule 3]

        foreach server [list 0 1] {
            if {![string match $ruleServer $server]} {
                continue
            }

            lappend options($server) $ruleOption
        }

        switch -- $ruleVarArgsToConsume {
            0 {
                set argToExecute {
                    lappend @VAR@ $arg
                    set argsArray($arg) true
                } 
            }
            1 {
                set argToExecute {
                    incr idx
                    if {$idx >= [llength $args]} {
                        return -code error "\"$arg\" option must be followed by value"
                    }
                    set argValue [lindex $args $idx]
                    lappend @VAR@ $arg $argValue
                    set argsArray($arg) $argValue
                }
            }
            default {
                return -code error "Internal argument construction error"
            }
        }

        lappend argSwitchBody $ruleServer,$ruleOption [string map [list @VAR@ $ruleVarToUpdate] $argToExecute]
    }

    # Add in the final options
    lappend argSwitchBody {*,-*} {return -code error "bad option \"$arg\": must be one of $options"}
    lappend argSwitchBody default break

    # Set the final variables
    set socketOptionsNoServer   [join $options(0) {, }]
    set socketOptionsServer     [join $options(1) {, }]
    set socketOptionsSwitchBody $argSwitchBody
}

proc tls::initlib {dir dll} {
    # Package index cd's into the package directory for loading.
    # Irrelevant to unixoids, but for Windows this enables the OS to find
    # the dependent DLL's in the CWD, where they may be.
    set cwd [pwd]
    catch {cd $dir}
    if {[string equal $::tcl_platform(platform) "windows"] &&
	![string equal [lindex [file system $dir] 0] "native"]} {
	# If it is a wrapped executable running on windows, the openssl
	# dlls must be copied out of the virtual filesystem to the disk
	# where Windows will find them when resolving the dependency in
	# the tls dll. We choose to make them siblings of the executable.
	package require starkit
	set dst [file nativename [file dirname $starkit::topdir]]
	foreach sdll [glob -nocomplain -directory $dir -tails *eay32.dll] {
	    catch {file delete -force            $dst/$sdll}
	    catch {file copy   -force $dir/$sdll $dst/$sdll}
	}
    }
    set res [catch {uplevel #0 [list load [file join [pwd] $dll]]} err]
    catch {cd $cwd}
    if {$res} {
	namespace eval [namespace parent] {namespace delete tls}
	return -code $res $err
    }
    rename tls::initlib {}
}


#
# Backwards compatibility, also used to set the default
# context options
#
proc tls::init {args} {
    variable defaults
    variable socketOptionsNoServer
    variable socketOptionsServer
    variable socketOptionsSwitchBody

    tls::_initsocketoptions

    # Technically a third option should be used here: Options that are valid
    # only a both servers and non-servers
    set server -1
    set options $socketOptionsServer

    # Validate arguments passed
    set initialArgs $args
    set argc [llength $args]

    array set argsArray [list]
    for {set idx 0} {$idx < $argc} {incr idx} {
	set arg [lindex $args $idx]
	switch -glob -- $server,$arg $socketOptionsSwitchBody
    }

    set defaults $initialArgs
}
#
# Helper function - behaves exactly as the native socket command.
#
proc tls::socket {args} {
    variable socketCmd
    variable defaults
    variable socketOptionsNoServer
    variable socketOptionsServer
    variable socketOptionsSwitchBody

    tls::_initsocketoptions

    set idx [lsearch $args -server]
    if {$idx != -1} {
	set server 1
	set callback [lindex $args [expr {$idx+1}]]
	set args [lreplace $args $idx [expr {$idx+1}]]

	set usage "wrong # args: should be \"tls::socket -server command ?options? port\""
        set options $socketOptionsServer
    } else {
	set server 0

	set usage "wrong # args: should be \"tls::socket ?options? host port\""
        set options $socketOptionsNoServer
    }

    # Combine defaults with current options
    set args [concat $defaults $args]

    set argc [llength $args]
    set sopts {}
    set iopts [list -server $server]

    array set argsArray [list]
    for {set idx 0} {$idx < $argc} {incr idx} {
	set arg [lindex $args $idx]
	switch -glob -- $server,$arg $socketOptionsSwitchBody
    }

    if {$server} {
	if {($idx + 1) != $argc} {
	    return -code error $usage
	}
	set uid [incr ::tls::srvuid]

	set port [lindex $args [expr {$argc-1}]]
	lappend sopts $port
	#set sopts [linsert $sopts 0 -server $callback]
	set sopts [linsert $sopts 0 -server [list tls::_accept $iopts $callback]]
	#set sopts [linsert $sopts 0 -server [list tls::_accept $uid $callback]]
    } else {
	if {($idx + 2) != $argc} {
	    return -code error $usage
	}

	set host [lindex $args [expr {$argc-2}]]
	set port [lindex $args [expr {$argc-1}]]

        # If an "-autoservername" option is found, honor it
        if {[info exists argsArray(-autoservername)] && $argsArray(-autoservername)} {
            if {![info exists argsArray(-servername)]} {
                set argsArray(-servername) $host
                lappend iopts -servername $host
            }
        }

	lappend sopts $host $port
    }
    #
    # Create TCP/IP socket
    #
    set chan [eval $socketCmd $sopts]
    if {!$server && [catch {
	#
	# Push SSL layer onto socket
	#
	eval [list tls::import] $chan $iopts
    } err]} {
	set info ${::errorInfo}
	catch {close $chan}
	return -code error -errorinfo $info $err
    }
    return $chan
}

# tls::_accept --
#
#   This is the actual accept that TLS sockets use, which then calls
#   the callback registered by tls::socket.
#
# Arguments:
#   iopts	tls::import opts
#   callback	server callback to invoke
#   chan	socket channel to accept/deny
#   ipaddr	calling IP address
#   port	calling port
#
# Results:
#   Returns an error if the callback throws one.
#
proc tls::_accept { iopts callback chan ipaddr port } {
    log 2 [list tls::_accept $iopts $callback $chan $ipaddr $port]

    set chan [eval [list tls::import $chan] $iopts]

    lappend callback $chan $ipaddr $port
    if {[catch {
	uplevel #0 $callback
    } err]} {
	log 1 "tls::_accept error: ${::errorInfo}"
	close $chan
	error $err $::errorInfo $::errorCode
    } else {
	log 2 "tls::_accept - called \"$callback\" succeeded"
    }
}
#
# Sample callback for hooking: -
#
# error
# verify
# info
#
proc tls::callback {option args} {
    variable debug

    #log 2 [concat $option $args]

    switch -- $option {
	"error"	{
	    foreach {chan msg} $args break

	    log 0 "TLS/$chan: error: $msg"
	}
	"verify"	{
	    # poor man's lassign
	    foreach {chan depth cert rc err} $args break

	    array set c $cert

	    if {$rc != "1"} {
		log 1 "TLS/$chan: verify/$depth: Bad Cert: $err (rc = $rc)"
	    } else {
		log 2 "TLS/$chan: verify/$depth: $c(subject)"
	    }
	    if {$debug > 0} {
		return 1;	# FORCE OK
	    } else {
		return $rc
	    }
	}
	"info"	{
	    # poor man's lassign
	    foreach {chan major minor state msg} $args break

	    if {$msg != ""} {
		append state ": $msg"
	    }
	    # For tracing
	    upvar #0 tls::$chan cb
	    set cb($major) $minor

	    log 2 "TLS/$chan: $major/$minor: $state"
	}
	default	{
	    return -code error "bad option \"$option\":\
		    must be one of error, info, or verify"
	}
    }
}

proc tls::xhandshake {chan} {
    upvar #0 tls::$chan cb

    if {[info exists cb(handshake)] && \
	$cb(handshake) == "done"} {
	return 1
    }
    while {1} {
	vwait tls::${chan}(handshake)
	if {![info exists cb(handshake)]} {
	    return 0
	}
	if {$cb(handshake) == "done"} {
	    return 1
	}
    }
}

proc tls::password {} {
    log 0 "TLS/Password: did you forget to set your passwd!"
    # Return the worlds best kept secret password.
    return "secret"
}

proc tls::log {level msg} {
    variable debug
    variable logcmd

    if {$level > $debug || $logcmd == ""} {
	return
    }
    set cmd $logcmd
    lappend cmd $msg
    uplevel #0 $cmd
}

