proc tilestyle { defaultBackground icons } {
#Set Tile styles common to both fixed and scaling
ttk::style configure TFrame -background $defaultBackground
ttk::style configure Heading -font TkDefaultFont
ttk::style configure Treeview -background white
ttk::style configure Treeview -fieldbackground white
ttk::style map Treeview -background [ list selected [ dict get $icons defaultBackground ] ]
ttk::style map Treeview -foreground [ list selected "#FF7900"]
ttk::style configure TProgressbar -troughcolor [ dict get $icons defaultBackground ]
ttk::style configure TProgressbar -lightcolor "#FF7900"
ttk::style configure TProgressbar -darkcolor "#FF7900"
ttk::style configure TProgressbar -bordercolor "#FF7900"
ttk::style configure TSpinbox -selectbackground [ dict get $icons defaultBackground ]
ttk::style configure TSpinbox -fieldbackground white
ttk::style configure TSpinbox -background [ dict get $icons defaultBackground ]
ttk::style configure TSpinbox -foreground black
ttk::style configure TSpinbox -selectforeground "#FF7900"
ttk::style configure TEntry -selectbackground [ dict get $icons defaultBackground ]
ttk::style configure TEntry -fieldbackground white
ttk::style configure TEntry -background [ dict get $icons defaultBackground ]
ttk::style configure TEntry -foreground black
ttk::style configure TEntry -selectforeground "#FF7900"
ttk::style configure TEntry -borderwidth 0
ttk::style configure TPanedwindow -background $defaultBackground
ttk::style configure TButton -relief flat
ttk::style map TButton -background [ list active "#FF7900" ]
}

proc framesizes { win_scale_fact } {
global tabix tabiy mainx mainy mainminx mainminy mainmaxx mainmaxy
set tabix [ expr {round(481.2 * $win_scale_fact)} ]
set tabiy [ expr {round(240.6 * $win_scale_fact)} ]
set mainx [ expr {round(610 * $win_scale_fact)} ]
set mainy [ expr {round(482.7 * $win_scale_fact)} ]
set mainminx [ expr {round(248.1 * $win_scale_fact)} ]
set mainminy [ expr {round(240.6 * $win_scale_fact)} ]
set mainmaxx [ expr {round(744.3 * $win_scale_fact)} ]
set mainmaxy [ expr {round(556.4 * $win_scale_fact)} ]
}

proc initfixedtheme { theme } {
global tcl_platform defaultForeground defaultBackground win_scale_fact treewidth
upvar #0 icons icons
upvar #0 iconalt iconalt
#Scaling factor for physical units to pixels with design default of 1.3333333
##Theme is fixed at clearlooks for Linux and xpnative for Windows
#Force scaling to 1.333333
   set win_scale_fact 1.333333
   tk scaling $win_scale_fact
   set treewidth 161
   framesizes $win_scale_fact
#Reset fonts to scaling
   font create basic -family arial -size 10
   foreach font [ font names ] {
   font configure $font -size [font configure $font -size ]
        }
ttk::setTheme $theme
configmessagebox $theme
set iconset iconicgray
set icons [ create_icon_images $iconset ]
set iconhighlight iconicorange 
set iconalt [ create_icon_images $iconhighlight ]
dict set icons defaultBackground $defaultBackground
dict set icons defaultForeground $defaultForeground
#set Tile Styles
tilestyle $defaultBackground $icons
}

proc initscaletheme {theme pixelsperpoint} {
global tcl_platform defaultBackground defaultForeground win_scale_fact treewidth
upvar #0 icons icons
upvar #0 iconalt iconalt
upvar #0 iconssvg iconssvg
upvar #0 iconaltsvg iconaltsvg
package require tksvg
package require colorutils
package require awthemes 9.2
::themeutils::setHighlightColor $theme "#FF7900"
::themeutils::setThemeColors $theme graphics.color #FF7900 focus.color #FF7900
#Set scrollbar colors for awlight and breeze to the same as arc theme
::themeutils::setThemeColors $theme scrollbar.active #d3d4d8
::themeutils::setThemeColors $theme scrollbar.color #b8babf
::themeutils::setThemeColors $theme scrollbar.pressed #FF7900
::themeutils::setThemeColors $theme scrollbar.trough #eff0f1
::themeutils::setThemeColors $theme \
        style.progressbar rounded-line \
        style.scale circle-rev \
        style.scrollbar-grip none \
        scrollbar.has.arrows false
	#Window Scaling Factor
	if { $pixelsperpoint eq "auto" } {
	#Use system detect value
	set win_scale_fact [ tk scaling ]
	} else {
	#pixelsperpoint has been set to a floating point number
	#between 1.33 and 3.99 by the user
	#set scaling value to this user value
	set win_scale_fact $pixelsperpoint	
	tk scaling $win_scale_fact
	}
   	foreach font [ font names ] {
   	font configure $font -size [font actual $font -size ]
        }
#Create "basic" font used for the editor
if {$tcl_platform(platform) == "windows"} {
if {{Segoe UI} in [ font families ] } {
font create basic -family {Segoe UI}
	} else {
font create basic -family {TkDefaultFont}
	}
} else {
if {{Liberation Sans} in [ font families ] } {
font create basic -family {Liberation Sans}
	} else {
font create basic -family {TkDefaultFont}
	}
}
package require $theme
ttk::setTheme $theme
configmessagebox $theme
#png icons
set iconset iconicgray
set icons [ create_icon_images $iconset ]
set iconhighlight iconicorange
set iconalt [ create_icon_images $iconhighlight ]
#svg icons
set iconsetsvg iconicgraysvg
set iconssvg [ create_icon_images $iconsetsvg ]
set iconhighlightsvg iconicorangesvg
set iconaltsvg [ create_icon_images $iconhighlightsvg ]
set defaultBackground [ ttk::style lookup TFrame -background ]
set defaultForeground black
dict set icons defaultBackground $defaultBackground
dict set icons defaultForeground $defaultForeground
dict set iconssvg defaultBackground $defaultBackground
dict set iconssvg defaultForeground $defaultForeground
#Set Tile styles
tilestyle $defaultBackground $icons
if { [ winfo pixels . 1i ] eq 96 } {
font configure basic -size 10
set treewidth 161
	} else {
font configure basic -size [ font configure TkDefaultFont -size ]
ttk::style configure Treeview -rowheight [expr {[font metrics basic -linespace] + 8}]
set treewidth [ expr {round(1.677 * [ winfo pixels . 1i ])}]
	}
framesizes $win_scale_fact
}

proc configmessagebox { theme } {
global tcl_platform
namespace import ::msgcat::*
set ::ttk_message_box_return_value "ok"
namespace eval ::ttk::dialog_module {
	variable invalid_default_button_error [mc "Invalid default button \"%s\"."]
	variable italic_font [font create ttk_message_dialog_Italic_font {*}[font actual TkDefaultFont] -slant italic]
	variable unrecognized_parameter [mc "Unrecognized parameter: %s"]
	variable unrecognized_parameter_input [mc "Unrecognized input for %s parameter."]
	variable window_icon ""
	variable window_name ""
}

proc ::ttk::centralize_window {window_widget} {

        wm withdraw $window_widget
        update

        set total_height [winfo screenheight .]
        set total_width [winfo screenwidth .]

        set window_height [winfo reqheight $window_widget]
        set window_width [winfo reqwidth $window_widget]


        set height_center [ expr ($total_height - $window_height) /2]
        set width_center [ expr ($total_width - $window_width) / 2]

        wm geometry  $window_widget ${window_width}x${window_height}+$width_center+$height_center
        wm deiconify $window_widget
}

proc ::ttk::messageBox args {
#Always call the Linux version even on Windows to override Windows defaults
	ttk::unix_messageBox {*}$args
}

proc ::ttk::unix_messageBox args {
	variable ::ttk::dialog_module::unrecognized_parameter
	variable ::ttk::dialog_module::unrecognized_parameter_input
	variable ::ttk::dialog_module::window_name
	
	set detail_string {}
	set message_string {}

	set symbolic_button_name {}
	set window_icon_type info
	set window_identifier [expr int(rand() * 10000)]
	set window_name .window_${window_identifier}
	set window_title {}
	
	#What kind of buttons will be grid?
	set grid_type ok
	set default_button {}
	set index 0
	set last_item [llength $args]
	
	for {set index 0} {$index < $last_item} {set index [expr $index + 2]} {
		set token [lindex $args $index]
		set parameter [lindex $args [expr $index + 1]]
		
		switch $token {
			-default {
				set default_button [validate_parameter $parameter {ok abort retry ignore yes no}]
			} 
			-detail {
				set detail_string $parameter
			} 
			-icon {
				set window_icon_type [validate_parameter $parameter {error info question warning}]
			} 
			-message {
				set message_string $parameter
			} 
			-parent {
				if {$parameter != "."} {
					set window_name ${parameter}.window_${window_identifier}
				}
			} 
			-title {
				set window_title $parameter
			} 
			-type {
				set grid_type [ \
					validate_parameter \
					$parameter \
					{abortretryignore ok okcancel retrycancel yesno yesnocancel}
				]
			} 
			default {
				error [format $unrecognized_argument $token]
			}
		}
	}
	
	if {$default_button != ""} {
		if {![::ttk::unix_messageBox_check_default_parameter $default_button]} {
			return
		}
	}
		
	::ttk::unix_messageBox_draw \
		$window_icon_type \
		$window_title \
		$message_string \
		$detail_string \
		$grid_type \
		$default_button 
		
	return ${::ttk_message_box_return_value}
}

#Checks if the -default parameter, if set, is set correctly
proc ::ttk::unix_messageBox_check_default_parameter {default_button} {
	variable ::ttk::dialog_module::invalid_default_button_error 
	set ok 1
	
	if {!($default_button in {ok yes no cancel ignore abort retry})} {
		return -code error [format  $invalid_default_button_error $default_button]
	}
	return $ok
}

proc ::ttk::unix_messageBox_draw { \
	window_icon_type \
	window_title \
	message_text \
	details_text \
	grid_type \
	default_focus \
} {
	variable ::ttk::dialog_module::window_icon
	variable ::ttk::dialog_module::window_name
	variable ::ttk::dialog_module::italic_font
	set vertical_padding {0i 0.20i}
	set horizontal_padding 4
	
	ttk::toplevel $window_name 
	wm transient $window_name .ed_mainFrame
	wm title $window_name $window_title
	
	ttk::frame $window_name.top_frame -padding 3
	#upvar #0 icons icons
	switch $window_icon_type {
		error {
			set window_icon [create_image error icons ]
		}
		info {
			set window_icon [create_image information icons ]
		}
		question {
			set window_icon [create_image question icons ]
		}
		warning {
			set window_icon [create_image warning icons ]
		}
		default {
			set window_icon [create_image information icons ]
		}
	}
	
	if {$details_text != ""} {
		label $window_name.top_frame.details_label -text "${details_text}\n" \
		-font $italic_font
	} \
	else {
		label $window_name.top_frame.details_label -text {}
	}
	
	ttk::label $window_name.top_frame.icon_label -image $window_icon
	ttk::label $window_name.top_frame.message_label -text $message_text
	ttk::frame $window_name.top_frame.button_frame 
	
	#First set of buttons: abort, retry and ignore.
	button $window_name.top_frame.button_frame.abort_button \
	-text [mc "Abort"] -width 10 -command {::ttk::unix_messageBox_quit "abort"}
	 
	
	button $window_name.top_frame.button_frame.ignore_button \
	-text [mc "Ignore"] -width 10 -command {::ttk::unix_messageBox_quit "ignore"}
	
	button $window_name.top_frame.button_frame.retry_button \
	-text [mc "Retry"] -width 10 -command {::ttk::unix_messageBox_quit "retry"}
	
	#Second set of buttons: yes and no.
	button $window_name.top_frame.button_frame.yes_button \
	-text [mc "Yes"] -width 10 -command {::ttk::unix_messageBox_quit "yes"}
	
	
	button $window_name.top_frame.button_frame.no_button \
	-text [mc "No"] -width 10 -command {::ttk::unix_messageBox_quit "no"}
	
	
	#Third set of buttons: ok and cancel.
	button $window_name.top_frame.button_frame.ok_button \
	-text [mc "Ok"] -width 10 -command {::ttk::unix_messageBox_quit "ok"}
	
	button $window_name.top_frame.button_frame.cancel_button \
	-text [mc "Cancel"] -width 10 -command  {::ttk::unix_messageBox_quit "cancel"}
	
	grid $window_name.top_frame -row 0 -column 0 -sticky news 
	grid $window_name.top_frame.icon_label -row 0 -column 0 
	grid $window_name.top_frame.message_label -row 0 -column 1
	grid $window_name.top_frame.details_label -row 1 -column 1 -sticky w
	grid $window_name.top_frame.button_frame -row 2 -column 0 -columnspan 2
	
	switch $grid_type {
		abortretryignore {
			grid $window_name.top_frame.button_frame.abort_button -row 0 -column 0  -pady $vertical_padding -padx $horizontal_padding 
			grid $window_name.top_frame.button_frame.retry_button -row 0 -column 1  -pady $vertical_padding -padx $horizontal_padding 
			grid $window_name.top_frame.button_frame.ignore_button -row 0 -column 2  -pady $vertical_padding -padx $horizontal_padding 
		} 
		ok {
			grid $window_name.top_frame.button_frame.ok_button -row 0 -column 0 \
			-sticky we -padx 5 -pady $vertical_padding
		} 
		okcancel {
			grid $window_name.top_frame.button_frame.ok_button -row 0 -column 0 -pady $vertical_padding -padx $horizontal_padding 
			grid $window_name.top_frame.button_frame.cancel_button -row 0 -column 1  -pady $vertical_padding -padx $horizontal_padding 
		} 
		retrycancel {
			grid $window_name.top_frame.button_frame.retry_button -row 0 -column 0  -pady $vertical_padding -padx $horizontal_padding 
			grid $window_name.top_frame.button_frame.cancel_button -row 0 -column 1  -pady $vertical_padding -padx $horizontal_padding 
		} 
		yesno {
			grid $window_name.top_frame.button_frame.yes_button -row 0 -column 0 -pady $vertical_padding -padx $horizontal_padding 
			grid $window_name.top_frame.button_frame.no_button -row 0 -column 1  -pady $vertical_padding -padx $horizontal_padding 
		} 
		yesnocancel {
			grid $window_name.top_frame.button_frame.yes_button -row 0 -column 0  -pady $vertical_padding -padx $horizontal_padding 
			grid $window_name.top_frame.button_frame.no_button -row 0 -column 1 -pady $vertical_padding -padx $horizontal_padding 
			grid $window_name.top_frame.button_frame.cancel_button -row 0 -column 2  -pady $vertical_padding -padx $horizontal_padding 
		}
	}
	
	switch $default_focus {
		ok {
			focus  $window_name.top_frame.button_frame.ok_button
		} 
		cancel {
			focus  $window_name.top_frame.button_frame.cancel_button
		} 
		abort {
			focus  $window_name.top_frame.button_frame.abort_button
		}
		retry {
			focus  $window_name.top_frame.button_frame.retry_button
		}
		ignore {
			focus  $window_name.top_frame.button_frame.ignore_button
		}
		yes {
			focus  $window_name.top_frame.button_frame.yes_button
		}
		no {
			focus  $window_name.top_frame.button_frame.no_button
		}
		cancel {
			focus  $window_name.top_frame.button_frame.cancel_button
		}
	}
	::ttk::centralize_window $window_name
	
	wm protocol $window_name WM_DELETE_WINDOW  {::ttk::unix_messageBox_quit "ok"}
	vwait ::ttk_message_box_return_value
}

#Check if parameter is any of the list, and if so, returns it.
proc ::ttk::validate_parameter {input_parameter input_list} {
	variable ::ttk::dialog_module::unrecognized_parameter_input 
	
	if {!($input_parameter in $input_list)} {
		return -code error [format $unrecognized_parameter_input $input_parameter]
	}
	
	return $input_parameter
}

proc ::ttk::unix_messageBox_quit {return_value} {
	variable ::ttk::dialog_module::window_name
	
	set ::ttk_message_box_return_value $return_value
	
	if {[info exist window_name]} {
		destroy $window_name
	}
	
	if {[info exist ${::ttk::dialog_module::window_icon}]} {
		image delete ${::ttk::dialog_module::window_icon}
	}
	return
}
}

#Get a temporary copy of the generic settings to configure the display
set tmpgendict [ ::XML::To_Dict config/generic.xml ]
if {[dict exists $tmpgendict theme scaling ]} {
set scaling [dict get $tmpgendict theme scaling ]
if { $scaling eq "auto" } {
#Using a scaling theme default is awlight on Linux and breeze on Windows
#alternative themes are "arc breeze awlight"
set theme [dict get $tmpgendict theme scaletheme ]
if { $theme ni {arc breeze awlight} } { 
#Options for Windows and Linux in case default is changed in future awtheme
if {$tcl_platform(platform) == "windows"} {
	set theme "breeze"
		} else {
	set theme "awlight"
		}
}
set pixelsperpoint [dict get $tmpgendict theme pixelsperpoint ]
if { $pixelsperpoint eq "auto" } {
;# Use detected value of tk scaling
} else {
if {![string is double $pixelsperpoint] } {
#pixelsperpoint is not a floating point number
set pixelsperpoint "auto"
} else {
if { $pixelsperpoint < 1.33 || $pixelsperpoint > 3.99 } {
#pixelsperpoint set to invalid value
set pixelsperpoint "auto"
	}
    }
}
rename tk_messageBox _tk_messageBox
proc tk_messageBox {args} {
bell
ttk::messageBox {*}$args
        }
initscaletheme $theme $pixelsperpoint
} else {
#Using a theme fixed to scaling of 1.33
if {$tcl_platform(platform) == "windows"} { 
set theme "xpnative" 
	} else {
set theme "clearlooks" 
	}
switch $theme {
	xpnative {
set defaultBackground [ eval format #%04X%04X%04X [winfo rgb . SystemButtonFace]]
set defaultForeground black
        }
        clearlooks {
set defaultBackground #efebe7
set defaultForeground black
rename tk_messageBox _tk_messageBox
proc tk_messageBox {args} {
bell
ttk::messageBox {*}$args
        }
        }
}
initfixedtheme $theme
}
unset -nocomplain tmpgendict
}
