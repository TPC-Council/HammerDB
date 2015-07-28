#Find Theme
global theme iconset defaultBackground defaultForeground
if {[catch {set xml_fd [open "config.xml" r]}]} {
     puts "Could not open XML config file using default values"
     return
                } else {
set xml "[read $xml_fd]"
close $xml_fd
    }
 ::XML::Init $xml
while {1} {
       foreach {type val attr etype} [::XML::NextToken] break
       if {$type == "XML" && $etype == "START"} {
	set myvariable $val
			}
       if {$type == "TXT" && $etype == "" && $myvariable == "theme" \
           && [info exists myvariable] } { 
       set [ set myvariable ] $val
	break
	}
       if {$type == "XML" && $etype == "END" && $val == "ttk_theme" } {
	break
	}
###In case no theme in config.xml
       if {$type == "XML" && $etype == "START" && $val == "benchmark" } {
	break
	}
       if {$type == "EOF"} break
	}
unset -nocomplain xml
#Verify theme and platform default is xpnative on Windows and clam on Linux
#Windows can be xpnative clam or black, Linux can be clam or black
###In case no theme in config.xml
if { ![ info exists theme ] } {  
set theme "classic" 
set iconset "default" 
	}
set acceptablethemes {classic modern xpnative clam black}
if {[lsearch $acceptablethemes $theme] >= 0} {
if {$theme == "modern"} { set theme "black" } 
if {$tcl_platform(platform) == "windows"} { 
if {$theme == "classic"} { set theme "xpnative" } 
	} else {
if {$theme == "classic" || $theme == "xpnative" } { set theme "clam" }
	}
} else {
if {$tcl_platform(platform) == "windows"} { 
set theme "xpnative" 
	} else {
set theme "clam" 
	}
}
#Apply theme defaults
ttk::setTheme $theme
switch $theme {
	xpnative { 
set defaultBackground [ eval format #%04X%04X%04X [winfo rgb . SystemButtonFace]]
set defaultForeground black
set iconset "default" 
	}
	clam {
set defaultBackground #dcdad5 
set defaultForeground black
set iconset "default"
	}
	black {
set defaultBackground #424242
set defaultForeground white
set iconset "iconic"
rename tk_messageBox _tk_messageBox
proc tk_messageBox {args} {
bell
ttk::messageBox {*}$args
	}
    }
}
