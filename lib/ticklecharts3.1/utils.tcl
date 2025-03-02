# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {
    namespace export setdef merge
}

proc ticklecharts::htmlMap {h htmloptions} {
    # Html options.
    #
    # h            - huddle object.
    # htmloptions  - Options described below.
    #
    # Returns list map html
    variable gapiscript ; variable keyGMAPI
    variable wcscript
    variable gmscript
    variable eGLscript

    lappend mapoptions [format {%%width%% %s}      [set width [lrange [dict get $htmloptions -width]  0 end-1]]]
    lappend mapoptions [format {%%height%% %s}     [set height [lrange [dict get $htmloptions -height] 0 end-1]]]
    lappend mapoptions [format {%%renderer%% %s}   [lrange [dict get $htmloptions -renderer] 0 end-1]]
    lappend mapoptions [format {%%jsecharts%% %s}  [lrange [dict get $htmloptions -jsecharts]  0 end-1]]
    lappend mapoptions [format {%%jschartvar%% %s} [lrange [dict get $htmloptions -jschartvar]  0 end-1]]
    lappend mapoptions [format {%%divid%% %s}      [lrange [dict get $htmloptions -divid]  0 end-1]]
    lappend mapoptions [format {%%title%% %s}      [lrange [dict get $htmloptions -title]  0 end-1]]
    lappend mapoptions [format {%%jsvar%% %s}      [lrange [dict get $htmloptions -jsvar]  0 end-1]]
    lappend mapoptions [format {%%class%% %s}      [lrange [dict get $htmloptions -class]  0 end-1]]

    # Add style in html template...
    if {[lindex [dict get $htmloptions -style] 0] eq "nothing"} {
        lappend mapoptions [format {%%style%% {width:%s; height:%s;}} $width $height]
    } else {
        lappend mapoptions [format {%%style%% %s} [lrange [dict get $htmloptions -style] 0 end-1]]
    }

    set frmt {<script type="text/javascript" src="%s"></script>} ; # base format...
    set jsScript {}

    # Add gmap script + Google maps API... if 'gmap' option is present.
    if {"gmap" in [$h keys]} {
        lappend jsScript [jsfunc new [format $frmt $gapiscript] -header]
        # Add comment in html template file if key API is not present...
        if {$keyGMAPI eq "??"} {
            lappend jsScript [jsfunc new {<!-- please replace '??' with your own API key -->} -header]
        }
        # Add echarts-extension-gmap.js
        lappend jsScript [jsfunc new [format $frmt $gmscript] -header]
    }

    # Get name series... with ehuddle class. 
    set series [$h getTypeSeries]

    # Add 'wordcloud' script if 'wordcloud' type is present.
    if {"wordCloud" in $series} {
        lappend jsScript [jsfunc new [format $frmt $wcscript] -header]
    }

    # Add 'GL' script if 'series 3D' type is present.
    foreach series3D {line3D scatter3D bar3D lines3D map3D surface polygons3D scatterGL graphGL flowGL} {
        if {$series3D in $series} {
            lappend jsScript [jsfunc new [format $frmt $eGLscript] -header]
            break
        }
    }

    if {[llength $jsScript]} {
        if {[lindex [dict get $htmloptions -script] 0] ne "nothing"} {
            set js [lindex [dict get $htmloptions -script] 0]
            dict set htmloptions -script [format {{{%s}} list.d} [linsert {*}$js end {*}$jsScript]]
        } else {
            dict set htmloptions -script [format "{{%s}} list.d" $jsScript]
        }
    }

    set html [ticklecharts::readHTMLTemplate]

    # add js script(s) in html template...
    if {[lindex [dict get $htmloptions -script] 0] ne "nothing"} {
        set html [ticklecharts::addJsScript $html [dict get $htmloptions -script]]
    }

    return [string map [join $mapoptions] $html]
}

proc ticklecharts::addJsScript {html value} {
    # Add js script(s) in html template file...
    #
    # Returns html

    set h [split $html "\n"]
    lassign $value js type

    switch -exact -- $type {
        jsfunc  {
            set indent 0
            switch -exact -- [$js position] {
                start  {set item "%jschartvar%"}
                end    {set item "%json%"}
                header {set item "%jsecharts%" ; set indent 3}
                null   {set item "%jschartvar%"}
            }
            if {[set f [lsearch $h *$item*]] < 0} {
                error "Not possible to find `$item` string in the html template file..."
            }
            set listH [linsert $h [expr {$f + 1}] \
                      [format [list %-${indent}s %s] "" [join [$js get]]]]
        }
        list.d {
            set listH $h
            foreach script {*}[lreverse $js] {
                set indent 0
                # insert Jsfunc...
                if {[ticklecharts::typeOf $script] eq "jsfunc"} {
                    switch -exact -- [$script position] {
                        start  {set item "%jschartvar%"}
                        end    {set item "%json%"}
                        header {set item "%jsecharts%" ; set indent 3}
                        null   {set item "%jschartvar%"}
                    }
                    if {[set f [lsearch $listH *$item*]] < 0} {
                        error "Not possible to find `$item` string in the html template file..."
                    }
                    set listH [linsert $listH [expr {$f + 1}] \
                              [format [list %-${indent}s %s] "" [join [$script get]]]]
                } else {
                    error "should be a 'jsfunc' class... in list data script."
                }
            }
        }
    }

    return [join $listH "\n"]
}

proc ticklecharts::readHTMLTemplate {} {
    # Open and read html template.
    #
    # Returns html file list
    variable htmltemplate

    set fp [open $htmltemplate r]
    set html [read $fp]
    close $fp
    
    return $html
}

proc ticklecharts::ehuddleType {type} {
    # Transform dict type to huddle echarts type.
    #
    # type  - dict options type.
    #
    # Returns huddle echarts type

    switch -exact -- $type {
        str.t   -
        str     {set htype @S}
        num.t   -
        num     {set htype @N}
        bool.t  -
        bool    {set htype @B}
        list.st -
        list.s  {set htype @LS}
        list.nt -
        list.n  {set htype @LN}
        list.dt -
        list.d  {set htype @LD}
        list.j  {set htype @LJ}
        null    {set htype @NULL}
        e.color -
        dict    {set htype @L}
        list.o  {set htype @DO}
        dict.o  {set htype @LO}
        jsfunc  {set htype @JS}
        default {error "no type for '$type'"}
    }

    return $htype
}

proc ticklecharts::typeOfClass {obj} {
    # Name of class.
    #
    # obj  - Instance.
    #
    # Returns name of class or nothing.
    return [info object class $obj]
}

proc ticklecharts::isAObject {obj} {
    # Check if variable 'obj' is an object.
    #
    # obj  - Instance.
    #
    # Returns True or False.
    return [info object isa object $obj]
}

proc ticklecharts::typeOf {value} {
    # Guess the type of the value.
    # 
    # value - string (everything is string !!!)
    #
    # Returns type of value

    if {$value eq "nothing" || $value eq "null"} {
        return null
    }

    if {[string is double -strict $value] ||
        [string is integer -strict $value]} {
        return num
    }

    if {[string equal -nocase "true" $value] ||
        [string equal -nocase "false" $value]} {
        return bool
    }

    if {[ticklecharts::isListOfList $value]} {
        return list
    }

    if {[ticklecharts::isAObject $value]} {
        switch -glob -- [ticklecharts::typeOfClass $value] {
            "*::jsfunc" {return jsfunc}
            "*::eColor" {return e.color}
            "*::eList"  {return list}
            "*::eDict"  {return dict}
        }
    }

    return str
}

proc ticklecharts::optsToEchartsHuddle {options} {
    # Transform a dict to echartshuddle format...
    # Level one.
    # 
    # options - dict options
    #
    # Returns list (echartshuddle)
    
    set opts {}

    dict for {key info} $options {
        lassign $info value type
        
        set key   [string map {- ""} $key]
        set htype [ticklecharts::ehuddleType $type]

        switch -exact -- $type {
            dict -
            dict.o {
                if {![ticklecharts::iseDictClass $value]} {
                    error "should be a eDict class..."
                }
                append opts [format " ${htype}=$key {%s}" \
                            [ticklecharts::dictToEchartsHuddle [$value get]] \
                            ]
            }
            list.o {
                set l {}
                foreach val $value {
                    if {[ticklecharts::iseDictClass $val] || [ticklecharts::iseListClass $val]} {
                        lappend l [ticklecharts::dictToEchartsHuddle [$val get]]
                    } else {
                        lappend l [ticklecharts::dictToEchartsHuddle $val]
                    }
                }
                append opts [format " ${htype}=$key {%s}" [list @AO $l]]
            }
            list.st -
            list.s {
                if {[ticklecharts::iseListClass $value]} {
                    append opts [format " ${htype}=$key %s" [$value get]]
                } else {
                    append opts [format " ${htype}=$key {%s}" $value]
                }
            }
            list.dt -
            list.d  -
            list.nt -
            list.n {
                if {[ticklecharts::iseListClass $value]} {
                    append opts [format " ${htype}=$key {%s}" [$value get]]
                } else {
                    append opts [format " ${htype}=$key {%s}" [list $value]]
                }
            }
            list.j {
                set l {}
                foreach val $value {
                    lappend l [ticklecharts::dictToEchartsHuddle [dict create $key $val]]
                }
                append opts [format " ${htype}=$key {%s}" [list $l]]
            }
            e.color {
                append opts [format " ${htype}=$key {%s}" \
                            [ticklecharts::dictToEchartsHuddle [$value get]] \
                            ]
            }
            default {
                append opts [format " ${htype}=$key %s" $value]
            }
        }
    }

    return $opts
}

proc ticklecharts::dictToEchartsHuddle {options} {
    # Transform a dict to echartshuddle format...
    # Level two.
    # 
    # options - dict options
    #
    # Returns list (echartshuddle)

    set d [dict create {*}$options]
    set opts {}
    
    dict for {subkey subinfo} $options {
        lassign $subinfo value type
        
        set htype [ticklecharts::ehuddleType $type]
       
        switch -exact -- $type {
            dict {
                if {![ticklecharts::iseDictClass $value]} {
                    error "should be a eDict class..."
                }
                append opts [format " ${htype}=$subkey %s" \
                            [list [ticklecharts::dictToEchartsHuddle [$value get]]] \
                            ]
            }
            dict.o {
                if {![ticklecharts::iseDictClass $value]} {
                    error "should be a eDict class..."
                }
                append opts [format " ${htype}=$subkey {%s}" \ 
                            [list [ticklecharts::dictToEchartsHuddle [$value get]]] \
                            ]
            }
            list.st -
            list.s {
                if {[ticklecharts::iseListClass $value]} {
                    append opts [format " ${htype}=$subkey %s" [$value get]]
                } else {
                    append opts [format " ${htype}=$subkey {%s}" $value]
                }
            }
            list.dt -
            list.d  -
            list.nt -
            list.n {
                if {[ticklecharts::iseListClass $value]} {
                    append opts [format " ${htype}=$subkey {%s}" [$value get]]
                } else {
                    append opts [format " ${htype}=$subkey {%s}" [list $value]]
                }
            }
            list.o {
                set l {}
                foreach val $value {
                    if {[lindex $val end] eq "list.o"} {
                        set tt {}
                        foreach vv [join [lrange $val 0 end-1]] {
                            if {[ticklecharts::iseDictClass $vv] || [ticklecharts::iseListClass $vv]} {
                                lappend tt [ticklecharts::dictToEchartsHuddle [$vv get]]
                            } else {
                                lappend tt [ticklecharts::dictToEchartsHuddle $vv]
                            }
                        }
                        lappend l [list @D $tt]
                        continue
                    }
                    
                    lappend l [ticklecharts::dictToEchartsHuddle $val]
                }
                append opts [format " ${htype}=$subkey {%s}" [list @AO $l]]
            }
            e.color {
                append opts [format " ${htype}=$subkey {%s}" \
                            [ticklecharts::dictToEchartsHuddle [$value get]] \
                            ]
            }
            default {
                append opts [format " ${htype}=$subkey %s" $value]
            }
        }
        
    }

    return $opts
}

proc ticklecharts::setdef {d key args} {
    # Set dict definition with value type and default value.
    # An error exception is raised if args value is not found.
    # 
    # d    - dict
    # key  - dict key
    # args - type, default, version, validvalue
    #
    # Returns dictionary
    variable echarts_version
    variable wc_version
    variable gmap_version

    upvar 1 $d _dict

    # distinguishes between the 3 libraries.
    set versionLib $echarts_version ; # for Echarts see ticklecharts.tcl

    foreach {k value} $args {
        switch -exact -- $k {
            "-minWCversion" {set minversion $value ; set versionLib $wc_version}
            "-minGMversion" {set minversion $value ; set versionLib $gmap_version}
            "-minversion"   {set minversion $value}
            "-validvalue"   {set validvalue $value}
            "-type"         {set type       $value}
            "-default"      {set default    $value}
            default         {error "Unknown key '$k' specified"}
        }
    }

    dict set _dict $key [list $default $type $validvalue $minversion $versionLib]
}

proc ticklecharts::matchTypeOf {mytype type keyt} {
    # Guess type, follow optional list.
    # 
    # mytype - type
    # type   - list default type
    # keyt   - upvar key type 
    #
    # Returns true if mytype is found, false otherwise

    upvar 1 $keyt typekey
    
    foreach valtype [split $type "|"] {
        if {[string match *$mytype* "$valtype"]} {
            set typekey $valtype
            return 1
        }
    }
    
    return 0
}

proc ticklecharts::keyCompare {d other} {
    # Compare keys... Output warning message if key name doesn't exist, 
    # in key default option...
    #
    # d      - dict
    # other  - list values
    #
    # Returns nothing

    if {![ticklecharts::isDict $other] || $other eq ""} {
        return {}
    }

    set infoproc [ticklecharts::getLevelProperties [expr {[info level] - 1}]]
    set keys1 [dict keys $d]

    foreach k [dict keys $other] {
        # special case : insert 'dummy' as name of key for theming...
        if {[string match -nocase *item $k] || 
            [string match -nocase *dummy $k]} {
            continue
        }
        if {$k ni $keys1} {
            puts "warning ($infoproc): '$k' flag is not in\
                '[join $keys1 ", "]' or not supported..."
        }
    }

    return {}
}

proc ticklecharts::merge {d other} {
    # Merge 2 dictionaries and control the type of value.
    # An error exception is raised if type of value doesn't match.
    #
    # d      - dict (default option(s))
    # other  - list values
    #
    # Returns a new dictionary

    # Compare keys... output warning message if key name doesn't exist 
    # in key default option...
    variable minProperties

    ticklecharts::keyCompare $d $other

    set _dict [dict create]
    
    dict for {key info} $d {
        lassign $info value type validvalue minversion versionLib

        # force string value for this keys below
        # if value is boolean or double...
        if {$key in {-id id -name name}} {
            if {[dict exists $other $key]} {
                set namevalue [dict get $other $key]
                # Force string representation.
                if {[ticklecharts::typeOf $namevalue] ne "str"} {
                    dict set other $key [string cat $namevalue "<s!>"]
                }
            }
        }

        # Several versions for same key...
        set multiversions 0
        if {[string match {*:*} $minversion]} {
            set multiversions 1
            set lenversion [llength [split $minversion ":"]]
            set lentype    [llength [split $type ":"]]

            if {$lenversion != $lentype} {
                error "Each versions must matched with a type of keys..."
            }
            set i 0
            set save_v "0.0.0"
            set _t [split $type ":"]
            foreach v [split $minversion ":"] {
                if {[ticklecharts::vCompare $v $versionLib] <= 0} {
                    # replaces the type of key according to echarts key version
                    if {[ticklecharts::vCompare $v $save_v] >= 0} {
                        set version $v
                        set type [lindex $_t $i]
                    }
                }
                set save_v $v
                incr i
            }

            set minversion $version
        }

        set vcompare [ticklecharts::vCompare $minversion $versionLib]

        if {[dict exists $other $key]} {

            if {$vcompare > 0} {
                puts "warning (version): '$key' is not supported... in\
                     '$versionLib' (minimum version = '$minversion')"
                continue
            }
        
            set mytype [ticklecharts::typeOf [dict get $other $key]]
            
            # check type in default list
            if {![ticklecharts::matchTypeOf $mytype $type typekey]} {
                set type [string map {.t "" .st ".s" .dt ".d" .nt ".n"} $type]
                if {$multiversions} {
                    error "bad type(set) for this key '$key'= $mytype\
                           should be :$type for $minversion version"
                } else {
                    error "bad type(set) for this key '$key'= $mytype\
                           should be :$type"
                }
            }

            # REMINDER ME: use 'dict remove' for this...
            if {$typekey in {dict dict.o list.o}} {
                error "type key : dict, dict.o, list.o shouldn't\
                       not be present\ in 'other' dict... for this '$key'"
            }

            set value [dict get $other $key]

            # Verification of certain values (especially for string types)
            ticklecharts::formatEcharts $validvalue $value $key

        } else {
            # Does not take this key, depending on the version used.
            if {$vcompare > 0} {continue}
        
            set mytype [ticklecharts::typeOf $value]
            
            # check type in default list
            if {![ticklecharts::matchTypeOf $mytype $type typekey]} {
                set type [string map {.t "" .st ".s" .dt ".d" .nt ".n"} $type]
                if {$multiversions} {
                    error "bad type(default) for this key '$key'= $mytype\
                           should be :$type for $minversion version"
                } else {
                    error "bad type(default) for this key '$key'= $mytype\
                           should be :$type"
                }
            }
            # Minimum properties...
            # Only write values that are defined in the *.tcl file.
            # Be careful, properties in the *.tcl file must be implicitly marked.
            if {$minProperties} {
                if {$key ni {-type -name} && $typekey ni {
                    dict list.o list.j str.t list.st list.dt list.nt bool.t num.t
                    }} {
                    continue
                }
            }
        }

        if {$typekey in {str str.t}} {
            set value [ticklecharts::mapSpaceString $value]
        }

        dict set _dict $key $value $typekey
    }
    
    return $_dict
}

proc ticklecharts::vCompare {version1 version2} {
    # Checking the version used, compared to the minimum version.
    #
    # version1 - num version
    # version2 - num version
    #
    # Returns -1 if 'version1' is an earlier version than 'version2',
    # 0 if they are equal, and 1 if 'version1' is later than 'version2'.

    if {$version1 eq ""} {
        return 0
    }

    return [package vcompare $version1 $version2]
}

proc ticklecharts::mapSpaceString {value} {
    # Replace 'spaces' by symbol '<@!>' if present.
    # Use for string type values.
    #
    # value - string
    #
    # Returns mapped string
    return [string map {" " <@!>} $value]
}

proc ticklecharts::isDict {value} {
    # Check if the value is a dictionary.
    #
    # value - dict
    #
    # Returns true if 'value' is a dictionary, otherwise false.
    return [expr {![catch {dict size $value}]}]
}


proc ticklecharts::infoOptions {key {indent 0}} {
    # Gets default options according to key procedure.
    #
    # key    - dict
    # indent - format stdout
    #
    # Returns default value and type to stdout.

    set key  [string map {"-" ""} $key]
    set body [split [info body ticklecharts::$key] "\n"]
    set listmap {"setdef" "" "options" ""}
    set buffer "" ; set info 0
    set ifnP "" ; set copyifnP ""
    set dataInfo {}

    foreach val $body {
        # find command in body...
        if {[string match {*infoNameProc*} $val]} {
            set info 1 ; set cmd {}
            set map [string map [list \{ "" \} "" \] "" \[ ""] $val]
            foreach index [lsearch -all $map "*infoNameProc*"] {
                lappend cmd [lindex $map [expr {$index  + 2}]]
            }
            set ifnP "**[join $cmd " || "]**"
        }

        # append line body if command
        if {$info} {append buffer $val}

        # Guess if command is over...
        if {[info complete $buffer] && $buffer ne ""} {
            # omit if 'setdef' is not present
            if {[lsearch $buffer *setdef*] > -1} {
                lappend dataInfo [format "%${indent}s \}" ""]
            }
            set buffer "" ; set info 0
            set ifnP ""   ; set copyifnP ""
        }

        if {[string match {*setdef*} $val]} {
            if {[string first "#" [string trim $val]] == -1 && [string match {*\[ticklecharts::*} $val]} {
                set str [string range $val 0 [expr {[string first "-default" $val] - 1}]]

                if {$ifnP ne ""} {
                    if {$ifnP ne $copyifnP} {lappend dataInfo [format "%${indent}s %s \{" "" $ifnP]}
                    set newIndent [expr {$indent - 4}]
                    lappend dataInfo [format "%${newIndent}s %s" "" [string trim [string map $listmap $str]]]
                } else {
                    lappend dataInfo [format "%${indent}s %s" "" [string trim [string map $listmap $str]]]
                }

                # bug 'infinite loop?'. Add test to get if $match is not equal to current $key (name proc)
                if {[regexp {ticklecharts::([A-Za-z0-9]+)\s} $val -> match] && $match ne $key} {
                    lappend dataInfo [ticklecharts::infoOptions $match [expr {$indent - 2}]]
                }
            } else {
                if {$ifnP ne ""} {
                    if {$ifnP ne $copyifnP} {lappend dataInfo [format "%${indent}s %s \{" "" $ifnP]}
                    set newIndent [expr {$indent - 4}]
                    lappend dataInfo [format "%${newIndent}s %s" "" [string trim [string map $listmap $val]]]
                } else {
                    lappend dataInfo [format "%${indent}s %s" "" [string trim [string map $listmap $val]]]
                }
            }

            set copyifnP $ifnP
        }
    }

    return [join $dataInfo "\n"]
}

proc ticklecharts::infoNameProc {level name} {
    # Gets name of proc follow level.
    #
    # level  - level number or list level numbers
    # name   - name proc without namespace
    #
    # Returns True if name match with current level, False otherwise.

    set lnum 0

    foreach num $level {
        lassign [info level $num] infonameproc
        incr lnum [string match *$name $infonameproc]
    }

    return $lnum
}

proc ticklecharts::echartsOptsTheme {name} {
    # Gets default theme value
    #
    # name   - name theme option
    #
    # Returns value.
    variable opts_theme

    return [dict get $opts_theme $name]
}

proc ticklecharts::keysOptsThemeExists {name} {
    # Gets if key theme exists.
    #
    # name   - name theme option
    #
    # Returns true , false otherwise.
    variable opts_theme

    return [dict exists $opts_theme $name]
}

proc ticklecharts::dictIsNotNothing {d} {
    # Check if the dictionary contains only 'null' values.
    #
    # d   - dict
    #
    # Returns True if all values are null, False otherwise.

    dict for {key info} $d {
        if {$info ne "null"} {
            return 0
        }
    }

    return 1
}

proc ticklecharts::keyDictExists {basekey d key} {
    # Check if keyname exists in dict.
    #
    # d   - dict
    # key - upvar name
    #
    # Returns True if key name match, False otherwise.

    upvar 1 $key name

    foreach bkey [list $basekey [format {-%s} $basekey]] {
        if {[dict exists $d $bkey]} {
            set name $bkey
            return 1
        }
    }

    return 0
}

proc ticklecharts::listNs {{parentns ::}} {
    # From https://wiki.tcl-lang.org/page/namespace
    #
    # Returns list of all namespaces.

    set result {}
    foreach ns [namespace children $parentns] {
        lappend result {*}[listNs $ns] $ns
    }

    return $result
}

proc ticklecharts::keyValueIsListOfList {value key} {
    # Check if key 'value' is a list of list...
    #
    # value - list options
    # key   - key option
    #
    # Returns True if key value is a list of list, False otherwise.

    set lflag [lsearch $value "*$key*"]
    set range [lindex $value [expr {$lflag + 1}]]

    return [ticklecharts::isListOfList $range]
}

proc ticklecharts::isListOfList {args} {
    # Check if 'value' is a list of list...
    #
    # args - list
    #
    # Returns True if value is a list of list, False otherwise.

    # clean up the list... (spaces, \n...)
    regsub -all -line {(^\s+)|(\s+$)|\n} $args {} str

    if {[string range $str 0 1] eq "\{\{" && [string range $str end-1 end] eq "\}\}"} {
        return 1
    } 

    return 0
}

proc ticklecharts::traceEchartsVersion {args} {
    # Changes the script Echarts version variable.
    #
    # args   - not used...
    #
    # Returns nothing.
    variable escript ; variable echarts_version

    if {[regexp {@([0-9.]+)|@(latest)} $escript -> match]} {
        set vMap [list $match $echarts_version]
        set escript [string map $vMap $escript]
    } else {
        puts "warning: Num version (@X.X.X) should be present in 'Echarts' path js.\
              If no pattern matches, the script path is left unchanged."
    }

    return {}
}

proc ticklecharts::traceEchartsGLVersion {args} {
    # Changes the script Echarts GL version variable.
    #
    # args   - not used...
    #
    # Returns nothing.
    variable eGLscript ; variable gl_version

    if {[regexp {@([0-9.]+)|@(latest)} $eGLscript -> match]} {
        set vMap [list $match $gl_version]
        set eGLscript [string map $vMap $eGLscript]
    } else {
        puts "warning: Num version (@X.X.X) should be present in 'Echarts' path js.\
              If no pattern matches, the script path is left unchanged."
    }

    return {}
}

proc ticklecharts::traceGmapVersion {args} {
    # Changes the script Gmap version variable.
    #
    # args   - not used...
    #
    # Returns nothing.
    variable gmscript ; variable gmap_version

    if {[regexp {@([0-9.]+)|@(latest)} $gmscript -> match]} {
        set vMap [list $match $gmap_version]
        set gmscript [string map $vMap $gmscript]
    } else {
        puts "warning: Num version (@X.X.X) should be present in 'gmap' path js.\
              If no pattern matches, the script path is left unchanged."
    }

    return {}
}

proc ticklecharts::traceWCVersion {args} {
    # Changes the script echarts-wordcloud version variable.
    #
    # args   - not used...
    #
    # Returns nothing.
    variable wcscript ; variable wc_version

    if {[regexp {@([0-9.]+)} $wcscript -> match]} {
        set WCMap [list $match $wc_version]
        set wcscript [string map $WCMap $wcscript]
    } else {
        puts "warning: Num version (@X.X.X) should be present in 'wordcloud' path js.\
              If no pattern matches, the script path is left unchanged."
    }

    return {}
}

proc ticklecharts::traceKeyGMAPI {args} {
    # Changes the API key in Google script js.
    #
    # args   - not used...
    #
    # Returns nothing.
    variable gapiscript ; variable keyGMAPI

    if {[regexp {key=([a-zA-Z0-9?_-]+)} $gapiscript -> match]} {
        set vMap [list $match $keyGMAPI]
        set gapiscript [string map $vMap $gapiscript]
    } else {
        puts "warning: 'key=' should be present in Google script path js.\
              If no pattern matches, the script path is left unchanged."
    }

    return {}
}

proc ticklecharts::uuid {} {
    # source : https://stackoverflow.com/questions/105034/how-do-i-create-a-guid-uuid
    #
    # Returns a Universally Unique IDentifier.
    set d    [clock seconds]
    set d2   [clock microseconds]
    set uuid {}

    set template "xxxxxxxxxxxx4xxxyxxxxxxxxxxxxxxx"

    foreach c [split $template ""] {
        if {$c == "4"} {
            append uuid $c ; continue
        }
        set r [ticklecharts::random 16]
        if {$d > 0} {
            set r [expr {($d + $r) % 16 | 0}]
            set d [expr {int($d / 16.)}]
        } else {
            set r  [expr {($d2 + $r) % 16 | 0}]
            set d2 [expr {int($d2 / 16.)}]
        }

        if {$c eq "x"} {
            append uuid [format %x $r]
        } else {
            append uuid [format %x [expr {$r & 0x3 | 0x8}]]
        }
    }

    return $uuid
}

proc ticklecharts::random {val} {
    # Returns random number.
    #
    # val - num
    return [expr {int(rand() * $val)}]
}

proc ticklecharts::getLevelProperties {level} {
    # Gets name level procedure
    #
    # level - num
    #
    # Returns list name of procs...
    
    set properties {}

    for {set i $level} {$i > 0} {incr i -1} {
        set name [lindex [info level $i] 0]
        if {[string match {ticklecharts::*} $name] && 
            $name ne "ticklecharts::formatEcharts"} {
            set property [string map {ticklecharts:: ""} $name]
            if {$property ni $properties} {
                lappend properties $property
            }
        }
    }
    
    return [join [lreverse $properties] "."]
}