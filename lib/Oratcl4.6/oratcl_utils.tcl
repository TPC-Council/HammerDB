package require Oratcl
package provide Oratcl::utils 4.6

#
# create a namespace
#
namespace eval ::Oratcl::utils {
	namespace export logonBox
	variable OraTcl 
}


#
#
#
proc ::Oratcl::utils::limitEntry {args} {
	if {[llength $args] == 4} {
		set wid [lindex $args 0]
		set var [lindex $args 1]
		set idx [lindex $args 2]
		global [set var]
		if {[string length $idx] > 0} {
			set str [lindex [array get [set var] $idx] 1]
			if {[string length $str] > $wid} {
				set str [string range $str 0 [expr {$wid - 1}]]
				array set [set var] [list $idx $str]
			}
		} else {
			set str [set [set var]]
			if {[string length $str] > $wid} {
				set str [string range $str 0 [expr {$wid - 1}]]
				set [set var] $str
			}
		}
	}
}


#
# logonBox : display a GUI database connection window
#
proc ::Oratcl::utils::logonBox args {
	variable OraTcl

	package require Tk

	if {! [info exists OraTcl(image)]} {
		Oratcl::utils::makeImage
	} 

	Oratcl::utils::parseArgs $args

	catch {destroy .oralogon}
	set OraTcl(top) [eval toplevel .oralogon]
	wm title $OraTcl(top) {Database Connect Information}

	if {$OraTcl(usetile)} {
		Oratcl::utils::ttk_display
	} else {
		Oratcl::utils::tk_display
	}

	if {[winfo exists $OraTcl(top)]} {

		# center the window
		wm withdraw $OraTcl(top)
		update idletasks

		set x [expr {[winfo screenwidth $OraTcl(top)]/2 \
			- [winfo reqwidth $OraTcl(top)]/2 \
			- [winfo vrootx [winfo parent $OraTcl(top)]]}]
		set y [expr {[winfo screenheight $OraTcl(top)]/2 \
			- [winfo reqheight $OraTcl(top)]/2 \
			- [winfo vrooty [winfo parent $OraTcl(top)]]}]
		wm geom $OraTcl(top) +$x+$y
		wm deiconify $OraTcl(top)
		wm resizable $OraTcl(top) 0 0
		catch {topmost $OraTcl(top) 1} res
	}

        grab $OraTcl(top)
	bind $OraTcl(top) <Key-Return> [namespace code do_login]

	tkwait variable [namespace current]::OraTcl(button)
	return $OraTcl(lhandle)
}

#
# create logonBox using tile (ttk) widgets
#
proc ::Oratcl::utils::ttk_display {} {

	variable OraTcl

	#puts $OraTcl(theme)
	#ttk::style theme use $OraTcl(theme)

	$OraTcl(top) configure -bg \
		[ttk::style lookup TFrame -background]

	set OraTcl(win) [ \
		ttk::labelframe $OraTcl(top).win \
			-text Oratcl \
	]
	set OraTcl(err) [ \
		ttk::entry $OraTcl(top).err \
			-justify center \
			-state readonly \
			-takefocus 0 \
			-textvariable [namespace current]::OraTcl(error) \
	]
	set OraTcl(btn) [ \
		ttk::frame $OraTcl(top).btn \
	]

	set OraTcl(sep1) [ttk::separator $OraTcl(top).sep1 -orient horizontal]
	set OraTcl(sep2) [ttk::separator $OraTcl(top).sep2 -orient horizontal]

	grid $OraTcl(win) -row 0 -column 0 -sticky news -pady [list 9 9] -ipadx 10 -ipady 5 -padx [list 8 8]
	grid $OraTcl(sep1) -row 1 -column 0 -sticky ew -pady [list 0 4]
	grid $OraTcl(err) -row 2 -column 0 -sticky ew -padx [list 9 9]
	grid $OraTcl(sep2) -row 3 -column 0 -sticky ew -pady [list 4 0]
	grid $OraTcl(btn) -row 4 -column 0 -sticky ew -pady 2
	grid columnconfigure $OraTcl(btn) [list 0 1] -weight 1

	set OraTcl(win.pict_c) [
		ttk::label $OraTcl(win).pict_c \
			-image $OraTcl(image) \
	]
	set OraTcl(win.user_l) [ \
		ttk::label $OraTcl(win).user_l \
			-width 11 \
			-text {Username:} \
	]
	set OraTcl(win.user_e) [ \
		ttk::entry $OraTcl(win).user_e \
			-width 30 \
			-textvariable [namespace current]::OraTcl(user) \
	]
	set OraTcl(win.pass_l) [ \
		ttk::label $OraTcl(win).pass_l  \
			-width 11 \
			-text {Password:} \
	]
	set OraTcl(win.pass_e) [ \
		ttk::entry $OraTcl(win).pass_e \
			-width 30 \
			-textvariable [namespace current]::OraTcl(pswd) \
			-show * \
	]

	grid $OraTcl(win.pict_c) -row 0 -column 0 -sticky w -rowspan 4 -padx [list 20 0] -pady [list 4 0]
	grid $OraTcl(win.user_l) -row 0 -column 1 -sticky e -padx [list 20 0] 
	grid $OraTcl(win.user_e) -row 0 -column 2 -sticky w -padx 0 -pady 6
	grid $OraTcl(win.pass_l) -row 1 -column 1 -sticky e -padx [list 20 0]
	grid $OraTcl(win.pass_e) -row 1 -column 2 -sticky w -padx 0

	if {$OraTcl(option,tns)} {
		set OraTcl(srvrlist) [parseTns]
		set OraTcl(win.data_l) [ \
			ttk::label $OraTcl(win).data_l  \
				-width 11 \
				-text {Service:} \
		]
		set OraTcl(win.data_e) [ \
			ttk::combobox $OraTcl(win).data_e \
				-width 30 \
				-textvariable [namespace current]::OraTcl(srvr) \
				-values $OraTcl(srvrlist) \
		]
		grid $OraTcl(win.data_l) -row 2 -column 1 -sticky e -padx [list 20 0]
		grid $OraTcl(win.data_e) -row 2 -column 2 -sticky w -padx 0 -pady 6
	}

	if {$OraTcl(option,url)} {
		set OraTcl(win.url) [
			ttk::frame $OraTcl(win).url \
		]
		grid $OraTcl(win.url) -row 2 -column 1 -columnspan 5 -pady 6

		set OraTcl(win.url.host_l) [ \
			ttk::label $OraTcl(win.url).host_l \
				-width 2 \
				-text {//} \
		]
		set OraTcl(win.url.host_e) [ \
			ttk::entry $OraTcl(win.url).host_e \
				-textvariable [namespace current]::OraTcl(host) \
		]
		set OraTcl(win.url.port_l) [ \
			ttk::label $OraTcl(win.url).port_l \
				-width 1 \
				-text {:} \
		]
		set OraTcl(win.url.port_e) [ \
			ttk::entry $OraTcl(win.url).port_e \
				-textvariable [namespace current]::OraTcl(port) \
				-width 6
		]

		set OraTcl(win.url.srvc_l) [ \
			ttk::label $OraTcl(win.url).srvc_l \
				-width 1 \
				-text {/} \
		]
		set OraTcl(win.url.srvc_e) [ \
			ttk::entry $OraTcl(win.url).srvc_e \
				-textvariable [namespace current]::OraTcl(srvc) \
		]
		grid $OraTcl(win.url.host_l) -row 0 -column 0
		grid $OraTcl(win.url.host_e) -row 0 -column 1
		grid $OraTcl(win.url.port_l) -row 0 -column 2
		grid $OraTcl(win.url.port_e) -row 0 -column 3
		grid $OraTcl(win.url.srvc_l) -row 0 -column 4
		grid $OraTcl(win.url.srvc_e) -row 0 -column 5

	}

	set OraTcl(win.cnas_l) [ \
		ttk::label $OraTcl(win).cnas_l  \
			-width 11 \
			-text {Connect as:} \
	]
	set OraTcl(cnaslist) [list Normal SYSOPER SYSDBA SYSASM]
	set OraTcl(win.cnas_e) [ \
		ttk::combobox $OraTcl(win).cnas_e \
			-width 30 \
			-textvariable [namespace current]::OraTcl(cnas) \
			-values $OraTcl(cnaslist) \
	]
	grid $OraTcl(win.cnas_l) -row 3 -column 1 -sticky e -padx [list 20 0]
	grid $OraTcl(win.cnas_e) -row 3 -column 2 -sticky w -padx 0

	set OraTcl(btn.login) [ \
		ttk::button $OraTcl(btn).login \
			-text Login \
			-command [namespace code do_login] \
	]

	set OraTcl(btn.close) [ \
		ttk::button $OraTcl(btn).close \
			-text Cancel \
			-command [namespace code do_close] \
	]

	grid $OraTcl(btn.login) -row 0 -column 0
	grid $OraTcl(btn.close) -row 0 -column 1

	trace variable [namespace current]::OraTcl(user) w {::Oratcl::utils::limitEntry 30}
	trace variable [namespace current]::OraTcl(pswd) w {::Oratcl::utils::limitEntry 30}

	focus $OraTcl(win.user_e)
}


#
# create logonBox using normal (tk) widgets
#
proc ::Oratcl::utils::tk_display {} {
	variable OraTcl

	set OraTcl(win) [ \
		 frame $OraTcl(top).win \
			-relief raised \
			-borderwidth 1 \
	]
	set OraTcl(err) [ \
		entry $OraTcl(top).err \
			-relief raised \
			-borderwidth 1 \
			-justify center \
			-state readonly \
			-takefocus 0 \
			-textvariable [namespace current]::OraTcl(error) \
	]
	set OraTcl(btn) [ \
		frame $OraTcl(top).btn \
			-relief raised \
			-borderwidth 1
	]

        grid $OraTcl(win) -row 0 -column 0 -sticky news -pady [list 9 9] -ipadx 10 -ipady 5 -padx [list 8 8]
        grid $OraTcl(err) -row 1 -column 0 -sticky ew -padx [list 9 9]
        grid $OraTcl(btn) -row 2 -column 0 -sticky ew -pady [list 9 9] -padx [list 8 8]
        grid columnconfigure $OraTcl(btn) [list 0 1] -weight 1

	set OraTcl(win.pict_c) [
		label $OraTcl(win).pict_c \
			-image $OraTcl(image) \
	]
	set OraTcl(win.user_l) [ \
		label $OraTcl(win).user_l \
			-background [$OraTcl(top) cget -background] \
			-text Username: \
	]
	set OraTcl(win.user_e) [ \
		entry $OraTcl(win).user_e \
			-width 30 \
			-textvariable [namespace current]::OraTcl(user) \
	]
	set OraTcl(win.pass_l) [ \
		label $OraTcl(win).pass_l \
			-background [$OraTcl(win) cget -background] \
			-text Password: \
	]
	set OraTcl(win.pass_e) [ \
		entry $OraTcl(win).pass_e \
			-show * \
			-width 30 \
			-textvariable [namespace current]::OraTcl(pswd) \
	]

	grid $OraTcl(win.pict_c) -row 0 -column 0 -sticky w -rowspan 4 -padx [list 20 0] -pady [list 4 0]
	grid $OraTcl(win.user_l) -row 0 -column 1 -sticky e -padx [list 20 0] 
	grid $OraTcl(win.user_e) -row 0 -column 2 -sticky ew -padx 5 -pady 6
	grid $OraTcl(win.pass_l) -row 1 -column 1 -sticky e -padx [list 20 0]
	grid $OraTcl(win.pass_e) -row 1 -column 2 -sticky ew -padx 5

	if {$OraTcl(option,tns)} {
		set OraTcl(win.data_l) [ \
			label $OraTcl(win).data_l \
				-background [$OraTcl(top) cget -background] \
				-text Service: \
		]
		set OraTcl(win.data_e) [ \
			entry $OraTcl(win).data_e \
				-width 30 \
				-textvariable [namespace current]::OraTcl(srvr) \
		]
		grid $OraTcl(win.data_l) -row 2 -column 1 -sticky e -padx [list 20 0]
		grid $OraTcl(win.data_e) -row 2 -column 2 -sticky ew -padx 5 -pady 6
	}

	if {$OraTcl(option,url)} {
		set OraTcl(win.url) [
			frame $OraTcl(win).url \
		]
		grid $OraTcl(win.url) -row 2 -column 1 -columnspan 5 -pady 6
		set OraTcl(win.url.host_l) [ \
			label $OraTcl(win.url).host_l \
				-width 2 \
				-text {//} \
		]
		set OraTcl(win.url.host_e) [ \
			entry $OraTcl(win.url).host_e \
				-textvariable [namespace current]::OraTcl(host) \
		]
		set OraTcl(win.url.port_l) [ \
			label $OraTcl(win.url).port_l \
				-width 1 \
				-text {:} \
		]
		set OraTcl(win.url.port_e) [ \
			entry $OraTcl(win.url).port_e \
				-textvariable [namespace current]::OraTcl(port) \
				-width 6
		]
		set OraTcl(win.url.srvc_l) [ \
			label $OraTcl(win.url).srvc_l \
				-width 1 \
				-text {/} \
		]
		set OraTcl(win.url.srvc_e) [ \
			entry $OraTcl(win.url).srvc_e \
				-textvariable [namespace current]::OraTcl(srvc) \
		]
		grid $OraTcl(win.url.host_l) -row 0 -column 0
		grid $OraTcl(win.url.host_e) -row 0 -column 1
		grid $OraTcl(win.url.port_l) -row 0 -column 2
		grid $OraTcl(win.url.port_e) -row 0 -column 3
		grid $OraTcl(win.url.srvc_l) -row 0 -column 4
		grid $OraTcl(win.url.srvc_e) -row 0 -column 5
	}

	set OraTcl(win.cnas_l) [ \
		label $OraTcl(win).cnas_l) \
		-text {Connect as:} \
	]
	set OraTcl(win.cnas_f) [ \
		frame $OraTcl(win).cnas_f  \
			-relief sunken \
			-borderwidth 1 \
	]
	grid $OraTcl(win.cnas_l) -row 3 -column 1 -sticky e -padx [list 20 0]
	grid $OraTcl(win.cnas_f) -row 3 -column 2 -sticky ew -padx 5

	radiobutton $OraTcl(win.cnas_f).r1 -text Normal -value Normal -variable [namespace current]::OraTcl(cnas)
	radiobutton $OraTcl(win.cnas_f).r2 -text SYSDBA -value SYSDBA -variable [namespace current]::OraTcl(cnas)
	radiobutton $OraTcl(win.cnas_f).r3 -text SYSOPER -value SYSOPER -variable [namespace current]::OraTcl(cnas)
	radiobutton $OraTcl(win.cnas_f).r4 -text SYSASM -value SYSASM -variable [namespace current]::OraTcl(cnas)
	grid $OraTcl(win.cnas_f).r1 -row 1 -column 1 -sticky w
	grid $OraTcl(win.cnas_f).r2 -row 2 -column 1 -sticky w
	grid $OraTcl(win.cnas_f).r3 -row 3 -column 1 -sticky w
	grid $OraTcl(win.cnas_f).r4 -row 4 -column 1 -sticky w


	# create command buttons
	set OraTcl(btn.login) [ \
		button $OraTcl(btn).login \
			-text Login \
			-borderwidth 1 \
			-command [namespace code do_login] \
	]
	set OraTcl(btn.close) [ \
		button $OraTcl(btn).close \
			-text Cancel \
			-borderwidth 1 \
			-command [namespace code do_close] \
	]


	grid $OraTcl(btn.login) -row 0 -column 0 -padx 20 -pady 5 -sticky ew
	grid $OraTcl(btn.close) -row 0 -column 1 -padx 20 -pady 5 -sticky ew
 
	trace variable [namespace current]::OraTcl(user) w {::Oratcl::utils::limitEntry 30}
	trace variable [namespace current]::OraTcl(pswd) w {::Oratcl::utils::limitEntry 30}

	focus $OraTcl(win.user_e)
}


proc ::Oratcl::utils::signon {} {

	variable OraTcl

	set rval 0

	if {$OraTcl(option,tns)} {
		if {! [string is space $OraTcl(srvr)]} {
			set connect [format %s/%s@%s \
					    $OraTcl(user) \
					    $OraTcl(pswd) \
					    $OraTcl(srvr)]
		} else {
			set connect [format %s/%s \
					    $OraTcl(user) \
					    $OraTcl(pswd)]
		}
	}

	if {$OraTcl(option,url)} {
		set connect [format "%s/%s@//%s:%s/%s" \
				    $OraTcl(user) \
				    $OraTcl(pswd) \
				    $OraTcl(host) \
				    $OraTcl(port) \
				    $OraTcl(srvc)]
	}

	set logonCmd "oralogon $connect "
	switch -- $OraTcl(cnas) {
		SYSDBA  {set logonCmd [append logonCmd {-sysdba}]}
		SYSOPER  {set logonCmd [append logonCmd {-sysoper}]}
		SYSASM  {set logonCmd [append logonCmd {-sysasm}]}
	}

	set tcl_rc [catch {set lda [eval $logonCmd]} tcl_res ]

	if {$tcl_rc} {
		set [namespace current]::OraTcl(error) "$tcl_res" 
	} else {
		set rval 1
		set OraTcl(lhandle) $lda
		destroy $OraTcl(top)
	}
	return $rval
}


proc ::Oratcl::utils::do_login {} {
	variable OraTcl
	if {[::Oratcl::utils::signon]} {
		destroy $OraTcl(top)
		set OraTcl(button) 1
	}
}

proc ::Oratcl::utils::do_close {} {
	variable OraTcl

	set OraTcl(lhandle) {} 
	set OraTcl(error) {}
	destroy $OraTcl(top)
	set OraTcl(button) 0
}

proc ::Oratcl::utils::parseArgs args {
	variable OraTcl

	set OraTcl(user) {}
	set OraTcl(pswd) {}
	set OraTcl(srvr) {}
	set OraTcl(host) hostname
	set OraTcl(port) 1521
	set OraTcl(srvc) service
	set OraTcl(cnas) Normal
	set OraTcl(usetile) false
	set OraTcl(theme) default
	set OraTcl(option,url) false
	set OraTcl(option,tns) true

	foreach {opt arg} [lindex $args 0] {
		switch -- $opt {
			-tw -
			-tilewidgets {
				set OraTcl(usetile) true
				set OraTcl(theme) $arg
			}
			-type {
				if {[string equal $arg url]} {
					set OraTcl(option,url) true
					set OraTcl(option,tns) false
				}
				if {[string equal $arg tns]} {
					set OraTcl(option,url) false
					set OraTcl(option,tns) true
				}
			}
			-u -
			-user {
				set OraTcl(user) $arg
			}
			-p -
			-password {
				set OraTcl(pswd) $arg
			}
			-s -
			-service {
				set OraTcl(srvr) $arg
				set OraTcl(srvc) $arg
			}
			-host {
				set OraTcl(host) $arg
			}
			-port {
				set OraTcl(port) $arg
			}
			-ft -
			-frametitle { }
			default { puts "$arg unknown" }
		}
	}


	if {$OraTcl(usetile)} {
		if {! [string equal [info commands ::ttk::style] ::ttk::style]} {
			package require tile
			if {! [string equal [info commands ::ttk::style] ::ttk::style]} {
				rename ::style ::ttk::style
			}
		}
		ttk::style theme use $OraTcl(theme)
	}

}

proc ::Oratcl::utils::parseTns {} {

	global env

	set fL {}

	if {[info exists env(ORACLE_HOME)]} {
		lappend fL [file join $env(ORACLE_HOME) network admin tnsnames.ora]
	}

	if {[info exists env(ORACLE_HOME)]} {
		lappend fL [file join / var opt oracle tnsnames.ora]
	}

	if {[info exists env(HOME)]} {
		lappend fL [file join $env(HOME) .tnsnames.ora]
	}

	if {[info exists env(TNS_ADMIN)]} {
		lappend fL [file join $env(TNS_ADMIN) tnsnames.ora]
	}

	set sidlist {}
	foreach f $fL {

		set tcl_ok [catch {set fd [open $f r]} tcl_res]
		if {$tcl_ok != 0} {
			continue
		}
		set data [split [read $fd] \n]
		close $fd

		foreach line $data {
			if {[string is space $line]} {
				continue
			}
			if {[string is alnum [string range $line 0 0]]} {
				lappend sidlist [lindex $line 0]
			}
		}
	}

	return [lsort -unique $sidlist]
}

proc ::Oratcl::utils::makeImage {} {

	variable OraTcl 

	set img {}

	append img 4749463839615a005700f700006300006318006b00007300007b00007b100 \
	           07b18006b000863001877080873140c6300216300316318317308317b0831 \
	           811b058a1c0e8a1c248331239925169c3121ad3110ae2d1d7b31318431318 \
	           4393190312d943131943d299c3520ad4125c63100ce3100bd3108c63108bd \
	           3110ce3118ce3900ce3908d63908ce3910ce3921ce4200d64200d64208ce4 \
	           210d64210ce4a00ce5200ce5a00ce6300d65200d65a00ce4a10ce4218bd4a \
	           29c64a21ce4a18ce4e1cd64a18d64a29d05623d6522900319408318c08319 \
	           410318418317b18318410318c14319029316b36316029317331316f21317b \
	           20338531317b36398300319c0039a508319c08399c10319c10399c0839a50 \
	           a3fa21839a014449e104aa51e4cad2d4caa3152b52b5aad3761ad42315a55 \
	           31524f315d48366e6e273e65375e7932438d363a9c3131a92d31a23e39b13 \
	           d35c03b39ce3931ce4137ce4a3da35f4ec06e4fce5c37ce5650d65235d357 \
	           4fce6363ce7b50626b945e7dbfaf83768f8da78da5a8b6bba587a5d4b6c3e \
	           0de5200d66300e26300d75b32de7100e77f00de7820dc653fd8624ce1684c \
	           dc734ce7704cdf7e4ae08356e77b5ade885aef5a5af75a5ad66363de6363e \
	           76363f76363ff6363ef6b63de7b63da7f6be77b63de886be78463f97767ef \
	           8473e78c5ae79400e49f00e7944ae79c4ad6a056e49a54db9f65e49e60ebb \
	           700f5d600ffeb00fffb00e7af60debd6befad5aefad63e78c6be19278e794 \
	           77f59876e9a27be8b574e9aa8eefad94e4c47bedc783f7c576f8cd86edde8 \
	           9f8e68affe68afff78cd6a5a5d6adadde9c9ce7a49cdeb59ce7bd9ce7b5a5 \
	           e7b9a9efad9cefb59cefb5a5efb5adefb5b5efbda5efbdadf7b5adefc6adf \
	           fe794d6e7a5f7ef94ffef94e7ef9cdeefa5e7efa5f7f794fff794eff79cf7 \
	           f79cfff79cffff94f7ff9cffff9cdec5cbf2c7bef7cac1f7d2c6fcc8c0f7d \
	           6d6ffdecef7ded6d6e7e7dedef7e7e7e7f4e1e1ffdbd8ffe7def7e7e7ffe7 \
	           e7dee7efe7e7eff7efdeffefe7deefefefefeff7efefffefefe7effffff7e \
	           ff7f7f7fff7f7f7f7fffffff7f7ffffffffff21fe05202d646c2d0021f904 \
	           010000a8002c000000005a0057000008fe0051091c48b0a0c18308132a5cc \
	           8b0a143873e769c001122040813172d6aa44831c4215ebf1e8a1c99f02247 \
	           8b182daea81122250d503050564cd992a28b520271e162c54a94cf9f72e49 \
	           01c5ad044458a463bd6581548230d55ab54753ca971e3d1ab274d12dd8a8a \
	           664794a9527d858a2ac68aaf29d3caac8a14a945ae448f266d194206538da \
	           056110231752edbab3503570d017728e08d8254a55ca10a54dfaa34057b95 \
	           abd144619233db5624842a2328b132a7563ca16222d6cc15d9eeb83cf22f4 \
	           a41a034aa2a245ae60959ecfe95db913134ea9a42593fa4fc3590a08a81a4 \
	           5e9dab639c3f7de8d085abedba2323e1c3079b94318362a850823bfefa58a \
	           7cf4f162842f6c8a1ab39e9dc51d81da2f62aa3a52a1acb2dea3887ee0b14 \
	           28400088476a5f5107027cf13174436d1d61548362b59d100e3ae70568211 \
	           904cea521450822440a29776c420a2d0c91d20105147080c61b766c620a41 \
	           3af8a61628a81017822ce85cf19f85508011998147b172501c10002080016 \
	           770c0a224893c82d000004409818a74d83109256e0ca403906fd1e61722f0 \
	           9c07e0984d8cd0a05b18adb0827b077d10a594687050e5956d20621005510 \
	           a00000471b248271b02c941535a1da5c252652694f38514630208041a82ad \
	           100a2a87c2904a281d1d84a7910018d0a79594b4b186411f10a067a771ce4 \
	           9091b69043a5781fef69d75d5267e4811e098409441e051798592525e2915 \
	           0144167c0cf4c605091c20009f72da61c71b686460d01b6eb02a410571b2b \
	           1861a1238808140a3b89551478c9d79823a15e2da8408f38520c82ab15194 \
	           5c47b602d1c7406ebc51092470bcb10607694480c0020c485bd01b7358628 \
	           91d71b481061a011c40f0b7a88ce29a469652d5881fb8eed8c1682e5445c8 \
	           2a3424458863168d4910c2952cdc709c01088040c1d3bea130c30e7310000 \
	           0331b1cee6f29c180e955e170c163806084908327e1aca308afca594488ac \
	           24a86caccd0b23d2868a3bf73c6dc2596f0db1cc34574c9568307869910b7 \
	           f00c123806588f1451e7ee8634ba69d1d256bfe081700f8054138808d33d7 \
	           6453bc32d68343cc73d93f57a61921732592c714b75a683910e01883942a3 \
	           1fc76110700163b101d88bfac33d906af2cb8e931cf4cb1c59ab1b5825cb2 \
	           f877f48e0022118e3116c9904a784765103a416e08ae35d78ba73e500f73b \
	           46cc7f18a7b6df6ae1b12680be58dde1e063bb450040a6dcb21450680f75e \
	           7d73c3844b7ff8f962b75e76de5cf6d6c7ed6f03a1c63f895084caecb1531 \
	           406e5075b5dcedc67387c091066a81b487bc405983db82d7bb8020226fa31 \
	           1118a08c2d46098118865510e6390f7a5d7b9ff9c2863cf5c52f8314c1831 \
	           06e87ab2518a31915b9606fa6320620e4e160a56b1fd934f035f6a58f01fe \
	           675060ec7c43173844814759789b19f671088a74c72fe25a0210443790461 \
	           cf0743383c34110c13e042e800c04a9cd8f92028232600f0853d042c7f4c0 \
	           0c426568304d98a24168d1894e48027a0a500006f490905dcc22138a90831 \
	           a0609075214842f50fc4d4bce80bd26e001774028c2330601981952260850 \
	           485043f8f2460685c003630a830379f4044f78c52fa1010114a6a049869ce \
	           98d28a164d500c4813dfc074053d0c3086c14189a5c00087f6ba542fe3299 \
	           8a9cc30720b0d0073876ab3198099554a98c07e428cc84f03276ff50c71e8 \
	           210c9394c0e40472041783278ca8a6c809ac231c51de2c0ce4698a216bc28 \
	           88e712f90f3f2caa4799fec8838534c0831fecc073bc145ef90a62a20944c \
	           0031c60831cec000b2121a40345ea948a96340945f4622018cc2808feb1a8 \
	           009541185fc05e12f0300f4141065628c14026ef94270020340d88b04325e \
	           6f08636bd0955cda2531d04a28d4a2a1204f7f0c29832b08c2e58680a4fb8 \
	           c709aa83c2a498210b07b9a94bd1b08638d8c1127368c3412aa0273d31cb4 \
	           fa16a152afa80020666f41d53189307cab1051ee1e11c0b3c0c473080074d \
	           1180532f8de925de20d6835d20020950400454543c3bac4102411c2b7bdad \
	           591721c614c17a84712c7b4076230752d17c9001509d2863ab08a031ea0ea \
	           1ad0d0ad061c8465338583d81420b1b2f5a1933e25fec7127634827fbccd0 \
	           fb2001a4a29c281cd0ea40d94b0c4249e35da09448901a6ad99252af13c1d \
	           ba4e207ac8e04951538c31a455083af8470483c189b351662d6840481b266 \
	           1094a3c2b0d68302e00907b5a0196b06cd11d94276951862b00810838a847 \
	           e5a0400c46cc074820f08078c96b5e7fa5f7b8c9c56117b1085ffe01462d2 \
	           0e0841e02440439a8035743b0857fb5f3df96e460c0e53def81d79b60d5dd \
	           0c84c983ae7b4e5315394c180a4e80833a78b4044e68625c8be5b00e406c5 \
	           e39a057bdec55aecb9ccb008a9142047e81f0686c112027c461c663128323 \
	           1c71311c27c5053c26ee88831cc005bbcf607ae024f0b0420b23c058c63c3 \
	           203fe2d7a10d762bee520e30d315fb75ce2e5358f84d12b5b19bc5bbd10c0 \
	           4209307e328f3470b7ea10278359f61707805c6781bc21873f34981800fa6 \
	           01034620c5020029a012484382053b7bbaa4aa27f8ce0f67a996c66100819 \
	           ca69498ae8000ff78d033c2c34861db8800e86563261e01cdc1e939ac4083 \
	           15efb16c7c73ee8caacafb4081cd0a3067e8ca9039c280727303b668d24e4 \
	           12c2d5b2710fd0002d22641676441f1a047b8617a1820f66c0f19839a286f \
	           fdc0f404cb8001cfe40e5e9cae8cd0999452c18210738f8fb32e8f6642f43 \
	           b0a0bed9cf1f550082111eeb8726529a3ab8a82642f06086a6b29822b4784 \
	           40e74b4017c4c36407ed84122fedd48935a48fc205ec840ff50781445e883 \
	           0f5580c206d2c1055c816332c5148d434f4e902960a0d2dfbd4838c484017 \
	           0f807404d28c610cd9a969df35c2040c84022c78c097d42210cc1b03a10f0 \
	           d0ddf0015d233879fa40a0e081643f0629c2f0021096108b6f0a011829709 \
	           cd72b63910e3d9d0f53a0404a92fd971408430b45b8831f28f704473068ea \
	           5fb13bcff900040fa406e70c04c108f4908537b40d0a7030cdba579c11c59 \
	           fdc8116009e9b5322823274001d406082e64593f3ab785ee25f00c2052c7e \
	           f64a9a6004e73043d9075ea03e1f48ec0249a23805feca574123073ee5654 \
	           68323f6ffac3834884f4d2c9e66112b67d43735053e8000fee382eebb60a9 \
	           a126d42260c111be981ffce637fb0d80df072804e1cadddf87fcbb5f11fa9 \
	           be004dfaf880d86811110c8ffffdd977efbe01a25007c8c570433117f1391 \
	           02fb1032f2370f21a00f12a80f210302cf507dfbe07f2ed080f3d0817cb10 \
	           ff2856f8b775f34b1811dd18021308021f3037ca10f1a710c27b0770dd87d \
	           f32080c9077c7830054c50151b183229581103581113e88215210bd4f781d \
	           e5783e697819cb76b4fa7764f30151b981a413880ffa40f2d78143e506848 \
	           e80220a0841f581dda07044e9019f1377f0e487029f87f21b05426200c47e \
	           17f7ce102131886920102c017204b5082de677b6b711576101ee667151723 \
	           76d60020fe49c077fde387ea66491a027d4e787278070449e05326200224e \
	           0011b90016660066200064830066000066110066510069dd88967b08a1b30 \
	           011be00116e00124600124c02ea276777ab80118708a6030064a600446200 \
	           4dcb44290d428111420f5b24241b08c42108cc0e85b3c374a6ef340f5d331 \
	           f4d331d6988d16028d27177bb8a38d10b45fe2088ee2884e62f77150f07f3 \
	           b227fffb10f1de38e40207f01f27f16c28e6ec38ed93350cdc723ee088fee \
	           988ef3988e57008f00d98ef13826ff788fe9d831faf874d9a38e075990fd9 \
	           805fb508fff488ff3b80f58a090ff6835ec0749ee9856115991ed9805f060 \
	           3406398ff1388dee78041cd931c0277f108c872bfb209269257f1b0920fb4 \
	           09167248f007990f19890f8d82831796ed4588cc8783468048ed67839f453 \
	           947db0077bc00778c00753f9055cd0055c90955cd90509878dd7588ee3589 \
	           45bd10756b9075b7046e1b896b74296c2210d5149955ea096e318206e594d \
	           70399578d0568da20577199366c907dcb815010100003b

        image create photo picture -data [binary format H* $img]
	set OraTcl(image) picture
}


proc ::Oratcl::utils::prettyDesc {lh tb} {
	puts {}
	set l [oradesc $lh $tb]
	set namelen 41
	set nulllen 8
	set typelen 28
	set namesep [string repeat {_} $namelen]
	set nullsep [string repeat {_} $nulllen]
	set typesep [string repeat {_} $typelen]
	puts {}
	puts [format " %-${namelen}s %-${nulllen}s %-${typelen}s" Name Null? Type]
	puts [format " %-${namelen}s %-${nulllen}s %-${typelen}s" $namesep $nullsep $typesep]
	foreach e $l {
		set colname [lindex $e 0]
		set colnull {}
		if {! [lindex $e 5]} {
			set colnull {NOT NULL}
		}
		set coltype {}
		set t [lindex $e 2]
		switch -exact $t {
			CHAR -
			NCHAR -
			VARCHAR2 -
			NVARCHAR2 {
				set coltype ${t}([lindex $e 1])
			}
			NUMBER {
				set coltype $t
				set pr [lindex $e 3]
				if {$pr != 0} {
					set sc [lindex $e 4]
					if {$sc} {
						set coltype ${t}(${pr},${sc})
					} else {
						set coltype ${t}(${pr})
					}
				}
			}
			default	{
				set coltype $t
			}
		}
	
		puts [format " %-${namelen}s %-${nulllen}s %-${typelen}s" $colname $colnull $coltype]
	}
}
