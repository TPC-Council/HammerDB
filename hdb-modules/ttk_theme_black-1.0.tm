# ttk::messageBox for consistent look and feel under black theme
# Copyright (C) Carlos A. R. de Souza, 12/27/2008,12/28/2008
# This file can be distributed under the ISC license.
namespace import ::msgcat::*
package provide ttk_theme_black 1.0
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
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH3wUaEg8H3qbCowAAAd9JREFUWMPFl79O3TAYxY+zQFtA
vAKEsiBxxSswItYiOvIo7YBU1AcAcsmGeALYmJFYEKgzHRGUgaoXJOjw6+KgcIkdJ84tR/LkTz7H
3z9/NgoEMClpVdKypJ6kWUlTdvu3pJ+SziUdSzo0xvxRFwDmgRx4IBz3QB+YiyF+B3wH/tIeT8AW
MN6U/CPwg+5wDqSh5EvADd3jGuiF3HwU5GURqYv8fcdu94XjOSeSkoavkhYczsnsCkUmqe/YW5T0
parUXNm+Cxi7dgNuWLbve6ojLQvIfYeV7OpEVNnvOWyzwmjK02ReHFgjoso28VxuAEwI+Bzi0hoR
TckLrAnIQuPqENGWHGBbwGlg+bhEtCUHOBFw26CGX4mIIAe4li0JYkW0IAd4TPTWAH69dQhikjAB
ktgkzCLIc7uSmDJcjyAv0FbEJwGTdoYjsr02FTEAPiR2ej0ITNjEPrMbFdsbkvrDIjzYN8bcFwfP
efpBZjteaFzzIjk99o/A7PDttjyH7jUsr7zGftM1hl/8h5HsDBhzxTi1g+OocAXM1CVab0QiroDF
0Pac2um1S7fPNH0jxoFvLV7L4WzfdMa8gTcy2zhCMQB2XpVaBUwDIROSVoa+59N2+07SZel7fvTc
ZGrwD+VvMJ9x2VzAAAAAAElFTkSuQmCC
}
set information_icon {
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH3wUaEg84aMDvngAAAWBJREFUWMPllr9KA0EQxndFEjij
ZYKohYgctj6O76BJY7AI+Bx5B03QVuysTlEICKK9hYIKXk7wDz+bFY7R3OXM7Vj4wRXDMPd9szt/
1pgSAKwBh8AQiIEDIDQacORPfMejigiX+Sj08+JtCQKGxphghDu21s5mxU+VcQiTBJch4DjDd6RR
A6ErOIkHYFWrE0KgDzy7r6dG/n8AVIEWELlp9wKcAVtAxTf5EjDIGDgXwLzPzLPI0yIqPgS0GB+b
PgREgmQfqAMN13ppRD4ExIKknvI1hC8p+v/p3G1lbS3DPSfsN+1d0Bb2ieZcCIF3cQUbmgL2BPmt
94GUIl//oQW3NbPvCfJ7oKZFvgx8/GX2u4L8Dgg0BcjJ2NFey4kQsKD9KJUxr5OM5t8IuBJ292s5
GWO6wnfp4wp2Cqznpg8BM8DNGOQDoOqrEFeA6xzyRd/dEABt4Nw9UBPgFGgWyfwTdNvqDoIl1WcA
AAAASUVORK5CYII=
}
set question_icon {
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH3wUaEhAd7p41RwAAAW1JREFUWMPtla9LQ1EUx793m2AR
URFhGGYSjYIgWBcUBv4LplWLQcOymBYthglGy5pitFmGRRYUZMkf8ETTVObH8sI4PHD3vXkt+8IL
53LP+Xzvu+fe6+QpIC9pQ9KWpFVJJUkTkpykN0kdSS1J55KazrmuhiWgAtwzuJ6B6rDgNdLrBMhl
gW+TXbW08Cng1RTrAQ2gDMwC+fibi8eOgA+T0wWKaQzsmkKfQGWAvJUE4/tpDFyZIoceuTsm98LO
GaQxcpLe++KGh/9LE5fshMJvFZxz6/FqpiUtSGp7GPiy5bwN9BmJJEWeOzhv4sc0W5BFZRO3FErx
kYxME5ZDwSeBawO/BVwIeBG4SbgJN0PAl4BOArweAr4IPCXAz+In/M/3/C4BfgoUQqz+OAF+EKrp
loFvA98Led7rBt5USAFtY2AtJHzc/P6ub8dnfQtmzAv34pzrhTQwZuKeRhop8B1QMnfAg2+N3H8v
YmTgBxPSkOm+IHVoAAAAAElFTkSuQmCC
}
set warning_icon {
iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAYAAABzenr0AAAABmJLR0QA/wD/AP+gvaeTAAAACXBI
WXMAAAsTAAALEwEAmpwYAAAAB3RJTUUH3wUaEhEDDYo5ZQAAAXJJREFUWMO9lz1KQ0EUhc+ECGqI
pLDyBwPGQldgqU0KLVyAIATTKPlZhZuxsLITF6FFmoAgCBYqiqCNxs/mgfCc6MybmXzl8N6955y5
MzCSB8Am8MkPb8CiJgVwym9OJtV8GfiwCHgApovWLXl8eyypbFmfl7Sf2v0M8Mh4rlILaPM/WykF
XDsIOEvVfBs3RkA9xRD2PGp1YruvZ85ceQYqMRPoeB7VmqSDWO4rmSNfBoCJIeDIVt3ynY1maHOT
OSkq4DxUQHNcvo4CvoC1kCHsB+6gkdQt6r6ROQhJAOAVmCuSQDdzEEpVUsvXfTVTToQEAIZAySeB
VqY8Fg1JOz5Hb0h8LlwF7JKODZct6Csdvb/Oq4B1SYOEAt4lLRljnscl0HO+YXI4/jYrqW2tB9Qk
3UmquArIH0NHEbeSVo0xo3wCh67NA1mRtGeb/hufcfa8iPJc2rYATY57Y8xC0ZdRDEohT7MklCW9
SJqaUL+n/MI3cqSue+cOKdMAAAAASUVORK5CYII=
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
# Black Theme Copyright (c) 2007-2008 Mats Bengtsson
namespace eval ttk { namespace eval theme { namespace eval black { variable version 0.0.1 } } }
namespace eval ttk::theme::black {
#variable imgdir [file join [file dirname [info script]] black]
#variable I
#array set I [tile::LoadImages $imgdir *.png]
variable dir [file dirname [info script]]
# NB: These colors must be in sync with the ones in black.rdb
variable colors
array set colors {
-disabledfg "DarkGrey"
-frame "#424242"
-dark "#222222"
-darker "#121212"
-darkest "black"
-lighter "#828282"
-lightest "#ffffff"
-selectbg "#4a6984"
-selectfg "#ffffff"
}
if {[info commands ::ttk::style] ne ""} {
set styleCmd ttk::style
} else {
set styleCmd style
}
$styleCmd theme create black -parent clam -settings {
# -----------------------------------------------------------------
# Theme defaults
#
$styleCmd configure "." \
-background $colors(-frame) \
-foreground white \
-bordercolor $colors(-darkest) \
-darkcolor $colors(-dark) \
-lightcolor $colors(-lighter) \
-troughcolor $colors(-darker) \
-selectbackground $colors(-selectbg) \
-selectforeground $colors(-selectfg) \
-selectborderwidth 0 \
-font TkDefaultFont \
;
$styleCmd map "." \
-background [list disabled $colors(-frame) \
active $colors(-lighter)] \
-foreground [list disabled $colors(-disabledfg)] \
-selectbackground [list !focus $colors(-darkest)] \
-selectforeground [list !focus white] \
;
# ttk widgets.
$styleCmd configure TButton \
-width -8 -padding {5 1} -relief raised
$styleCmd configure TMenubutton \
-width -11 -padding {5 1} -relief raised
$styleCmd configure TCheckbutton \
-indicatorbackground "#ffffff" -indicatormargin {1 1 4 1}
$styleCmd configure TRadiobutton \
-indicatorbackground "#ffffff" -indicatormargin {1 1 4 1}
$styleCmd configure TEntry \
-fieldbackground white -foreground black \
-padding {2 0}
$styleCmd configure TCombobox \
-fieldbackground white -foreground black \
-padding {2 0}
$styleCmd configure TNotebook.Tab \
-padding {6 2 6 2}
# tk widgets.
$styleCmd map Menu \
-background [list active $colors(-lighter)] \
-foreground [list disabled $colors(-disabledfg)]
$styleCmd configure TreeCtrl \
-background gray30 -itembackground {gray60 gray50} \
-itemfill white -itemaccentfill yellow
}
}
# A few tricks for Tablelist.
namespace eval ::tablelist:: {
proc blackTheme {} {
variable themeDefaults
array set colors [array get ttk::theme::black::colors]
array set themeDefaults [list \
-background "White" \
-foreground "Black" \
-disabledforeground $colors(-disabledfg) \
-stripebackground "#191919" \
-selectbackground "#4a6984" \
-selectforeground "DarkRed" \
-selectborderwidth 0 \
-font TkTextFont \
-labelbackground $colors(-frame) \
-labeldisabledBg "#dcdad5" \
-labelactiveBg "#eeebe7" \
-labelpressedBg "#eeebe7" \
-labelforeground white \
-labeldisabledFg "#999999" \
-labelactiveFg white \
-labelpressedFg white \
-labelfont TkDefaultFont \
-labelborderwidth 2 \
-labelpady 1 \
-arrowcolor "" \
-arrowstyle sunken10x9 \
]
}
}
package provide ttk::theme::black $::ttk::theme::black::version
