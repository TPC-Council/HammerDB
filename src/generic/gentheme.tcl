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
	
	toplevel $window_name 
	wm title $window_name $window_title
	
	ttk::frame $window_name.top_frame -padding 3

#Set icon data
set error_icon {
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4QcRChcQXuqfSQAAAnpJREFUWMPF1ztIVmEYB/Dfd7DB
shAi2rtBRPU2hOHoYGAtNekoaY5NgVNQDV0gaBUlJ3FsKmhwDKrpGNTkZRVpKMJKg2w472fHz+9y
vqPSHw4cOC/P/znP9f9WFETKYVxHHy7iBI7Ez9+wjHnM4VXgexG7lQLEZzCOQXQW9PcHZvE4sFDK
gTQje4g76FAOv/Ec9wK/CjuQchovcc7e4CNuBhZbOpByCW9wzN5iFf0hq5P6DsQ/f7sP5HknevOR
qOTID+LDHoa9WTp6qjWR5D48aEI+GZ+imMRUg28XcH9bBGKrfWpQ7ZMYi+8TGC1APpZ7v9WgO84G
FqsRGG9GHtgMbEbDk63Ic+dH8aLOuQORU5Jm02ywSFxbOLFFXlPkjWbNUEpXgmtNJtwoJtKckQZO
7CBPs/qawnAD24cw0BFnezOMRoNbBIHN9F+elSCvoq+SZq13uWBl1xJVclFplxzeVVK+4Ggb7VWb
ZyXJYTXJrdQi2FETuyCH7sR/RhLFhN2mIPAHI5huw97XJCoZJYswSXPjvIQTS4ma9dgOecz51C6c
mE+ihitLPhyfsk7MVaLYXJGt43bJ85jGSCQv0hlrOJ5E9TpbUBk3M7gjEi0wE1irruNT+By3VC2m
cDsulSJ9Ph3Dr8n5jbiOlzpizhbSTL3erXN4JLZrpeCQGW7wnsezwFKtJOvEe5zf59mT4kpgfZsk
C/zEjSgc9wsrUZ6v5ydhfpoton+fnFjB1VAz+JI6I3UevVG97mXYe0Mdm0kD6bWIHjyNArIsNvAo
5ny57OX0ZBSQQ1FGFcEaZvCkWu2lb8c5R7owUHM9765uNRlR9Xr+OmROtMRfGFXFuIlNVRUAAAAA
SUVORK5CYII=
}

set information_icon {
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4QcRDjITKBm2yAAAAd9JREFUWMPtl00obVEUgD+ujnrJ
TxQDBiZHRGSCMQMxkAyUoowwPJNr8qYKk10kDKREGUgmbyQzRZm8lxSbuZ/3blfiveyXmJzBbfXe
PZe7zx7ZdQZrr7XO+vba+6y1TwEWhucHjcAc0A28AgdA0mh1EeVbYCn4EVAmVPdAZxREoYUEzP0j
OEA5MBvlbAOgO4uuxwXAaz7ONgAOsuj2XQAkwwMnRxqYjnJO5Bv9JXWcSlR27QG14WOAb8Cw0eqS
z2GrEHl+UAxMASNAU7h9Z8AGsGK0MrEBeH5QF+5ry39MvgN9Rqtr6wDhyk+yBM+E6HhvJnL5DKdy
CA7QBkzEUYhGhLwLVAM1wJ7QjcYB0CQzYrS6M1rdApNC1/xegKIoA6NVSRZ1qZD/uu4FSSEfOgPw
/KABGBfTWy4zMCN6yTWw4wTA84N2YEhMq49Uw49m4KuQfwHLTi4knh/UAwNiet5o9ejqRjQm/H4C
Sy6vZP1CXjBa/XYJIKvdej6FpMgCtMk4H9XATYbuj9Hqi22Ac6A1Q171/GAybO2rwvYsji3YFvIg
cBuuXH4dm3EALAJXOdidAivWAYxWT0AvcBkRvM9o9RzLf8FL6jidqOxaAx6AKqAibMU/gHlgwmiV
zuVdbwLifUZl97GsAAAAAElFTkSuQmCC
}

set question_icon {
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4QcRDjIrABsOVgAAAfBJREFUWMPtlj9oFEEUxn93OUcb
MRfFgCicEUYSECsrGwsLA4GA1sEYSWG5aBOIIDZJE0bbpBH/lBb+gSSoIFcJITkEQZkikhRBCQZi
pXNetNli8rhcZm/Xre6DLd5789737Zs3O1sgIZSOuoArwDBwAagAh4ECsA2sAzVgAXjhrPnVql4h
IfkQ8BDoC0zZBCadNbOpBSgd3QXu0x4eAzecNTsy0BVIPhq/ebs4DzQaPz5UE3dA6agMrALdnnsH
eAI8BT4CW7H/GHAOuAaMAcrL+Q30OWs2/PqlAPU3BXkduOqsed1k7ff4eat0NAe883IPAteBKT+h
GCBgWNhmD/JdcNasAPeE+5JcFyKgCPz07EcJ9v6NsCtyQSngTS7Gs9ADnAa+JBBQ32/mSqGVnDVb
3rCF4qSwv7WzBWlwWdi13AQoHfUCt4T7VS4ClI6OxGRlz/05Ppb/V4DS0QmgGl9UPm47a/62PYSB
5P3AInBKhB44a+ab5ZQyJD8LvAeOi9Bz4E4m1/E+e74MnBGhZ8Cos+ZPq69cFphpQj4NjLQiz6QD
SkcDwCdRa8JZMx2Sn0UHxgX5y1DyrAQMCnsqSXIxZfsPAVr8dCzlJgA4Ktq/6axp5CnggLAbdNBB
QhRSHsMK8NVzrTlrKnmegtToCPgH2+Z6vsSYaGIAAAAASUVORK5CYII=
}

set warning_icon {
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH4QcRChkZubUKYwAAAZ5JREFUWMPFl79KA0EQxn8bY2GC
EtDSoGIUomBtqWAK0/gAwWBQm/y5gN0+wRW+kYiVz6AgKBbaKaYxWDk2h5h4Hru3t/Erd2Z3vv1m
buZWYQHRbAPXwFS0NATWVcgzKZGz9D/7ERygALRxgLK4fRl4APJjphegrEI+fCvQjgkOsAA0vKZA
NDPAaYJL4LsGGsB8gn1LNDs+CQQZ+dgXoWh2gSuDsz6BVRXymLUCgcVZ3UwVEM0ycG+RqgGwqELe
s1Kga/mploBmJgqIpgg8RYfa4BbYVCFi4pxPsDXjgqtwlLToX4GqQA24SJ0C0Sig59DiA9caqEU3
SYu6aNZcCPRxg7GCuRj5K8A+7jgSzVwaBXo2YzoBs0DLioBos00W6IpO7iPjxlbEPCtUgLpRI4o+
vbtoU5a4VCE1EwXqHoID7Ilmw4RAH38IElMgmipw45HAMJqSb3/NAuPWaTAL4lAAToDzXykQTQk4
xD86okfeFN81cAwUJ0BgCTiII9BhcujE1cCK5ftQHAhUXd+Grsj9N4HYX7IBMD2heK/jC19a1VBp
7vgA2QAAAABJRU5ErkJggg==
}

	switch $window_icon_type {
		error {
			set window_icon [image create photo -data $error_icon]
		}
		info {
			set window_icon [image create photo -data $information_icon]
		}
		question {
			set window_icon [image create photo -data $question_icon]
		}
		warning {
			set window_icon [image create photo -data $warning_icon]
		}
		default {
			set window_icon [image create photo -data $information_icon]
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
			grid $window_name.top_frame.button_frame.abort_button -row 0 -column 0  -pady $vertical_padding
			grid $window_name.top_frame.button_frame.retry_button -row 0 -column 1  -pady $vertical_padding
			grid $window_name.top_frame.button_frame.ignore_button -row 0 -column 2  -pady $vertical_padding
		} 
		ok {
			grid $window_name.top_frame.button_frame.ok_button -row 0 -column 0 \
			-sticky we -padx 5 -pady $vertical_padding
		} 
		okcancel {
			grid $window_name.top_frame.button_frame.ok_button -row 0 -column 0 -pady $vertical_padding
			grid $window_name.top_frame.button_frame.cancel_button -row 0 -column 1  -pady $vertical_padding
		} 
		retrycancel {
			grid $window_name.top_frame.button_frame.retry_button -row 0 -column 0  -pady $vertical_padding
			grid $window_name.top_frame.button_frame.cancel_button -row 0 -column 1  -pady $vertical_padding
		} 
		yesno {
			grid $window_name.top_frame.button_frame.yes_button -row 0 -column 0 -pady $vertical_padding
			grid $window_name.top_frame.button_frame.no_button -row 0 -column 1  -pady $vertical_padding
		} 
		yesnocancel {
			grid $window_name.top_frame.button_frame.yes_button -row 0 -column 0  -pady $vertical_padding
			grid $window_name.top_frame.button_frame.no_button -row 0 -column 1 -pady $vertical_padding
			grid $window_name.top_frame.button_frame.cancel_button -row 0 -column 2  -pady $vertical_padding
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
if {$tcl_platform(platform) == "windows"} { 
set theme "xpnative" 
	} else {
set theme "clearlooks" 
	}
#Apply theme defaults
ttk::setTheme $theme
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
set iconset iconicgray
set icons [ create_icon_images $iconset ]
set iconhighlight iconicorange 
set iconalt [ create_icon_images $iconhighlight ]
dict set icons defaultBackground $defaultBackground
dict set icons defaultForeground $defaultForeground
#set Tile Styles
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
