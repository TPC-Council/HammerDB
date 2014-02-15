proc convert_to_oratcl { } {
global _ED
set flbuff $_ED(package)
set match ""
set new_curs 0
set dep 0
set depzerobind 0
set currcur 0
set fetch 0
set in_bind -1
set bind_pos -1
set nbinds 0
set lastfetchedcursor 0
set donehead 0
set filelist [split $flbuff "\n"]

proc check_date_formats { bindmatch } {
set datecnt 0
while { 
[ regexp -indices -nocase {(?:to_)(?:date|char)\((?:.*)(\'[^\']+?:[^\']+?\')[^\']*?\)(?:\W*?|,)} $bindmatch match value ] eq 1 } {
set bindmatch [string replace $bindmatch [ lindex $value 0 ] [ lindex $value 1 ] ]
if { [ incr datecnt ] eq 50 } { 
puts "ERROR : Matched more than 50 date formats in a SQL Statement during conversion"; break 
		}
	}
return $bindmatch
}

foreach line $filelist {
    if {[string match {*Instance name*} $line]} {
	regexp {(:)\ (.*)} $line a b c
	if { $donehead == 0 } {
	append ora "#!/usr/local/bin/tclsh8.6\n"
	append ora "package require Oratcl\n"
	append ora "####UPDATE THE CONNECT STRING BELOW###\n"
	append ora "#set connect user/password@$c\n"
	append ora "set lda \[oralogon \$connect\]\n"
	set donehead 1
	}
    }

    if {[string match {END\ OF\ STMT*} $line]} {
	set new_curs 0
	set fetch 0
    }

    if {[string match {PARSING\ IN\ CURSOR*dep=0*} $line]} {
	regexp {PARSING\ IN\ CURSOR\ #([0-9]+)\ len=([0-9]+)\ dep=([0-9]+) uid=([0-9]+)\ oct=([0-9]+)\ lid=([0-9]+)\ tim=([0-9]+)\ hv=([0-9]+) ad=\'([0-9,a-z]+)\'} $line all cursor len dep uid oct lid tim hv ad
	if {[array exists cur2hash]} {
	    if {[array get cur2hash $cursor] != ""} {
	        append ora "oraclose \$curn$cursor\n"
	        unset -nocomplain cur2hash($cursor) plsql($cursor)
	    }
	}
	    set lastfetchedcursor $cursor
	    set new_curs 1
	    set hashvalue [concat $hv\_$ad]
	    set cur2hash($cursor) $hashvalue
	    append ora "set curn$cursor "
	    append ora "\[oraopen \$lda \]\n"
    }

    if {$new_curs != 0} {
	if {[string match {PARSING\ IN\ CURSOR*dep=0*} $line]} {
	    unset -nocomplain text($cur2hash($cursor))
		} {
	    append text($cur2hash($cursor)) $line " "
		if {[regexp {\-\-} $line match value]} {
	            append text($cur2hash($cursor)) "\n"
		   }
	}
    }
  if {[string match {PARSE*dep=0*} $line] && ![string match {*ERROR*} $line]} {
      regexp {PARSE\ \#([0-9]+)\:} $line all cursor
	if {  [ set ix [ lsearch $depzerobind $cursor ]] == -1 } {
	lappend depzerobind $cursor
        }
      unset -nocomplain exectype($cursor) bindvarlist($cursor) bindvarlist2 bindvarlength bindmatch plsql($cursor) preapp($cursor) errinexec($cursor)
      set text($cur2hash($cursor)) [remspace $text($cur2hash($cursor))]
      set bindmatch [ check_date_formats $text($cur2hash($cursor)) ]
if {[regexp {:\"?([[:alnum:]_]+)(?!\=)\"?|(?!\=)\"?:\"?([[:alnum:]_]+)} $bindmatch) match]} {
## BB: 7/25/13 - based on order of projection filtering in SQL , ie :1=ColumnName versus ColumnName=:1, handle bind variable setting...
      if {[regexp {:\"?([[:alnum:]_]+)(?!\=)\"?} $bindmatch) match]} {
      set bindvarlist($cursor) [split [regexp -inline -all --\
       {:\"?([[:alnum:]_]+)(?!\=)\"?} $bindmatch ]]
         } else {
      set bindvarlist($cursor) [split [regexp -inline -all --\
       {(?!\=)\"?:\"?([[:alnum:]_]+)} $bindmatch ]]
          }
      set bindvarlength [llength $bindvarlist($cursor)]
      set count 0
	    while {$count < $bindvarlength} {
		if {[expr fmod($count,2)] == 1.0} {
		    lappend bindvarlist2 [lindex $bindvarlist($cursor) $count]
		}
		incr count
	    }
	    set bindvarlist($cursor) $bindvarlist2
	    set bindvarlength [llength $bindvarlist($cursor)]
   regsub -all {\"}  $text($cur2hash($cursor)) {\\"} text($cur2hash($cursor))
   regsub -all {\$}  $text($cur2hash($cursor)) {\\$} text($cur2hash($cursor))
	    append ora "set sql$cursor \"$text($cur2hash($cursor))\"\n"
		set preapp($cursor) 1
	if { $oct == 47 } {
	set plsql($cursor) 1
	    append ora "oraparse \$curn$cursor \$sql$cursor\n"
		set preapp($cursor) 1
	} else {
	    append ora "orasql \$curn$cursor \$sql$cursor -parseonly\n"
		set preapp($cursor) 1
	  }
	} else {
   regsub -all {\"}  $text($cur2hash($cursor)) {\\"} text($cur2hash($cursor))
   regsub -all {\$}  $text($cur2hash($cursor)) {\\$} text($cur2hash($cursor))
	    append ora "set sql$cursor \"$text($cur2hash($cursor))\"\n"
		set preapp($cursor) 1
	if { $oct == 47 } {
	    set plsql($cursor) 1
	append ora "oraparse \$curn$cursor \$sql$cursor\n"
	append exectype($cursor) "oraplexec \$curn$cursor \$sql$cursor\n" 
		set preapp($cursor) 1	
	} else {
	    append exectype($cursor) "orasql \$curn$cursor \$sql$cursor\n"
		set preapp($cursor) 1
		}
	}
    }  else {
if {[string match {PARSE*dep=*} $line] && ![string match {*ERROR*} $line]} {
regexp {PARSE\ \#([0-9]+)\:} $line all cursor
if {  [ set ix [ lsearch $depzerobind $cursor ]] != -1 } {
       set depzerobind [ lreplace $depzerobind $ix $ix ]
        		}
                }
        }

    if {[string match {FETCH*dep=0*} $line]} {
	regexp {FETCH\ \#([0-9]+)\:} $line all cursor
if { [ info exists errinexec($cursor) ] && $errinexec($cursor) == 1 } {
if { [ info exists fetched($cursor) ] && $fetched($cursor) == 0 } {
	append ora "###CANNOT FETCH $cursor:Failed to convert corresponding execute\n"
	set fetched($cursor) 1
	set lastfetchedcursor $cursor
	unset errinexec($cursor)
		}
	} else {
if { [ info exists fetched($cursor) ] && $fetched($cursor) == 0 } {	
    append ora "set row \[orafetch \$curn$cursor -datavariable output \]\n"
    append ora "while \{ \[ oramsg  \$curn$cursor \] == 0 \} \{\n"
    append ora "puts \$output\n"
    append ora "set row \[orafetch  \$curn$cursor -datavariable output \]\n"
    append ora "\}\n"
	set fetched($cursor) 1
	    set lastfetchedcursor $cursor
		} 
	}
    }
    if {([string match {BINDS*} $line])} {
	regexp {BINDS\ \#([0-9]+)\:} $line all cursor
	set currcur $cursor
if { [ lsearch $depzerobind $cursor ] != -1 } {
	if {[array exists cur2hash]} {
	    if {[array get cur2hash $cursor] != ""} {
    		set in_bind $cursor
		unset -nocomplain bindexec
	    }
	}
   } else {  ;  } 
}
    if {$in_bind >= 0} {
if {[string match {kkscoacd} $line]} { 
#We are dealing with the new 10.2 trace file format
continue
	}
if {[string match {Dump\ of\ memory*} $line]} {
set errorlist($in_bind) "###CANNOT EXECUTE $in_bind:Memory Dump in tracefile instead of value\n"
	}
	if {[string match {\ bind\ [0-9]*:*} $line]} {
	    regexp {\ bind\ ([0-9]+)\:} $line all bind_pos
	    if {$nbinds == 0} {
		incr nbinds
	    }
	} 
if {[string match {\ Bind\#[0-9]*} $line]} {
	    regexp {\ Bind\#([0-9]+)} $line all bind_pos
	    if {$nbinds == 0} {
		incr nbinds
	    }
	} 
    	if {!([string match {BINDS*} $line])} {
	    if {![regexp {^[[:space:]]} $line match]}  {
		unset -nocomplain execlist($in_bind)
		if {$nbinds > 0} {
		    if {[array exists bindexec]} {
	if {[info exists plsql($in_bind)]} {
			if { $plsql($in_bind) == 1 } {
		append execlist($in_bind) "oraplexec \$curn$in_bind \$sql$in_bind " 	
			} else {
		puts "Error $plsql($in_bind) incorrect value"
		}
		} else {
			append execlist($in_bind) "orabindexec \$curn$in_bind "
			}
			foreach i [array names bindexec] {
			    append execlist($in_bind) ":$i \{$bindexec($i)\} "
				unset bindexec($i)
			}
			append execlist($in_bind) "\n"
		    }
		}
		set nbinds 0
		set bind_pos -1
		set in_bind -1
	    }
	}
	}
	if {$in_bind >= 0 && $in_bind == $currcur} {
	    if {$bind_pos >= 0} {
		if {[string match {*value=*} $line]} {
		    if {[regexp {value=\"?(.*[^\"])\"?} $line match value]} {
			if {[info exists bindvarlist($in_bind)]} {
			    set bindvar [lindex $bindvarlist($in_bind) $bind_pos]

	if {[string match {*[\\\}\{\;\#]*} $value] } {
regsub -all {([\\\}\{\;\#])} $value {\\\1} value
	set value
			}
			    set bindexec($bindvar) $value
			}
		    }
		} else { 
			if {[string match {*avl=00*} $line]} {
			set value  ""
			if {[info exists bindvarlist($in_bind)]} {
			    set bindvar [lindex $bindvarlist($in_bind) $bind_pos]
			    set bindexec($bindvar) $value
					}
				} 
			}
		}
	}

    if {[string match {EXEC*dep=0*} $line]} {
	regexp {EXEC\ \#([0-9]+)\:} $line all cursor
	set fetched($cursor) 0
	if { [info exists errorlist($cursor)] } {
    	append ora $errorlist($cursor)
	} else {
	if { [info exists exectype($cursor)] } {
    	append ora $exectype($cursor)
	} else {
	if { [info exists execlist($cursor)] } {
    	append ora $execlist($cursor)
	} else {
#EXECUTE HAS been called for a cursor without a PARSE line
if { [ info exists preapp($cursor) ] && $preapp($cursor) == 1 } {
if { [ info exists plsql($cursor) ] && $plsql($cursor) == 1 } {
append ora "###CANNOT EXECUTE $cursor:Failed to find expected bind variables in PL/SQL statement before execute\n"
set errinexec($cursor) 1
} else {
append ora "###CANNOT EXECUTE $cursor:Failed to find expected bind variables in statement before execute\n"
set errinexec($cursor) 1
	}
		} else {
set bindmatch [ check_date_formats $text($cur2hash($cursor)) ]	
if {[regexp {:\"?([[:alnum:]_]+)\"?} $bindmatch) match]} {
append ora "###CANNOT EXECUTE $cursor:Found bind variables in the following statement that has not been parsed before execute\n"
append ora "###\"$text($cur2hash($cursor))\"\n"
set errinexec($cursor) 1
		} else {
#Valid format for execute without previous PARSE
    append ora "set sql$cursor \"$text($cur2hash($cursor))\"\n"
    append ora "orasql \$curn$cursor \$sql$cursor\n"	
			}			
		    }
		}
	    }
	}
    }
}
if { [ info exists lastfetchedcursor ] } {
if {$lastfetchedcursor != 0} {
    append ora "oraclose \$curn$lastfetchedcursor\n"
	unset -nocomplain plsql($lastfetchedcursor) preapp($lastfetchedcursor) fetched($lastfetchedcursor)
	}
}
   append ora "oralogoff \$lda\n"
set _ED(package) $ora
   update
   set _ED(temppackage) $_ED(package)
   ed_status_message -perm
   set _ED(blockflag) 0
if { [ info exists c ] } { set _ED(packagekeyname) $c }
   ed_edit
   applyctexthighlight .ed_mainFrame.mainwin.textFrame.left.text
}
