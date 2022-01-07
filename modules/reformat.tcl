# Largely based on code from the TCL wiki:
# https://wiki.tcl-lang.org/page/Reformatting+Tcl+code+indentation
proc reformat {tclcode {pad 2}} {

    set lines [split $tclcode \n]
    set out ""
    set nquot 0   ;# count of quotes
    set ncont 0   ;# count of continued strings
    set line [lindex $lines 0]
    set indent [expr {([string length $line]-[string length [string trimleft $line \ \t]])/$pad}]
    set fastinsert_indent -1;
    set padst [string repeat " " $pad]
    foreach orig $lines {
        incr lineindex
        if {$lineindex>1} {append out \n}
        set newline [string trimleft $orig]
        if {$newline==""} continue
        set is_quoted $nquot
        set is_continued $ncont
        if {[string index $orig end] eq "\\"} {
            incr ncont
        } else {
            set ncont 0
        }
        # if { [string index $newline 0]=="#" } {
            #   set line $orig   ;# don't touch comments
        # } else {
            if {$fastinsert_indent > -1} {
                set used_indent $fastinsert_indent
            } else {
                set used_indent $indent
            }
            set npad [expr {$used_indent * $pad}]
            set line [string repeat $padst $used_indent]$newline
            set i [set ns [set nl [set nr [set body 0]]]]
            for {set n [string length $newline]} {$i<$n} {incr i} {
                set ch [string index $newline $i]
                if {$ch=="\\"} {
                    set ns [expr {[incr ns] % 2}]
                } elseif {$ns} {
                    set ns 0
                } elseif {$ch=="\""} {
                    set nquot [expr {[incr nquot] % 2}]
                } elseif {$nquot} {
                    # anything in quotes doesn't impact indendation
                } elseif {$ch=="\{"} {
                    if {[string range $newline $i $i+2]=="\{\"\}"} {
                        incr i 2  ;# quote in braces - correct (though tricky)
                    } else {
                        incr nl
                        if {[string range $newline $i-15 $i]=="fastinsert end \{" || $fastinsert_indent > -1} {
                            incr fastinsert_indent
                        }
                        set body -1
                    }
                } elseif {$ch=="\}"} {
                    incr nr
                    if {$fastinsert_indent > -1} {
                        incr fastinsert_indent -1
                    }
                    set body 0
                }
            }
            set nbbraces [expr {$nl - $nr}]
            incr totalbraces $nbbraces
            if {$totalbraces<0} {
                error "Line $lineindex: unbalanced braces!"
            }
            incr indent $nbbraces
            if {$nbbraces==0} { set nbbraces $body }
            if {$is_quoted || $is_continued} {
                set line $orig     ;# don't touch quoted and continued strings
            } else {
                set np [expr {- $nbbraces * $pad}]
                if {$np>$npad} {   ;# for safety too
                    set np $npad
                }
                set line [string range $line $np end]
            }
        # }
        append out $line
    }
    return $out
}

proc eol {} {
    switch -- $::tcl_platform(platform) {
        windows {return \r\n}
        unix {return \n}
        macintosh {return \r}
        default {error "no such platform: $::tc_platform(platform)"}
    }
}

proc count {string char} {
    set count 0
    while {[set idx [string first $char $string]]>=0} {
        set backslashes 0
        set nidx $idx
        while {[string equal [string index $string [incr nidx -1]] \\]} {
            incr backslashes
        }
        if {$backslashes % 2 == 0} {
            incr count
        }
        set string [string range $string [incr idx] end]
    }
    return $count
}

set usage "reformat.tcl ?-indent number? filename"

if {[llength $argv]!=0} {
    if {[lindex $argv 0] eq "-indent"} {
        set indent [lindex $argv 1]
        set argv [lrange $argv 2 end]
    } else  {
        set indent 4
    }
    if {[llength $argv]>1} {
        error $usage
    }
    set f [open $argv r]
    set data [read $f]
    close $f
    set permissions [file attributes $argv -permissions]

    set filename "$argv.tmp"
    set f [open $filename  w]

    puts -nonewline $f [reformat [string map [list [eol] \n] $data] $indent]
    close $f
    file copy -force $filename  $argv
    file delete -force $filename
    file attributes $argv -permissions $permissions
}
