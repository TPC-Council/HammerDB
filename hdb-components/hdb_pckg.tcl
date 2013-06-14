set will_exit 0
##Check TCL is thread enabled
if { ![ info exists tcl_platform(threaded) ] } {
puts "ERROR : This version of TCL is not thread enabled and will not work with with HammerDB"
parray tcl_platform
set will_exit 1
}

##Load Threads
if { [ catch { package require Thread } ] } {
puts "ERROR : Failed to load Threads package - this package is mandatory for HammerDB"
set will_exit 1
}
#Checks no longer made for Database packages on startup from 2.7
##Set Tile Theme
global defaultBackground
if {$tcl_platform(platform) == "windows"} { 
ttk::setTheme xpnative 
set defaultBackground [ eval format #%04X%04X%04X [winfo rgb . SystemButtonFace] ]
} else {
ttk::setTheme clam
set defaultBackground #dcdad5 
}
set masterthread [thread::names]

proc myerrorproc { id info } {
global threadsbytid
if { ![string match {*index*} $info] } {
if { [ string length $info ] == 0 } {
puts "Warning: a running Virtual User was terminated, any pending output has been discarded"
} else {
if { [ info exists threadsbytid($id) ] } {
puts "Error in Virtual User [expr $threadsbytid($id) + 1]: $info"
	}  else {
    if {[string match {*.tc*} $info]} {
puts "Warning: Transaction Counter stopped, connection message not displayed"
	} else {
		;
#Background Error from Virtual User suppressed
				}
			}
		}
     	}
}
thread::errorproc myerrorproc
