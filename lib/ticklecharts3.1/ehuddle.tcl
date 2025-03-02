# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

# add jsfunc huddle type
namespace eval ::huddle::types::jsfunc {
    variable settings 
    
    # type definition
    set settings {
                    publicMethods {jsfunc}
                    tag jsf
                    isContainer no
                }
            
    proc jsfunc {arg} {
        return [wrap [list jsf $arg]]
    }
    
    proc jsondump {huddle_object offset newline nextoff} {
        return [join [lindex $huddle_object 1 1]]
    }
}

oo::class create ticklecharts::ehuddle {
    variable _huddle ; # list huddle value
    variable _series ; # list type series

    constructor {} {
        # init variables.
        set _huddle {} ; set _series {}
    }
}

oo::define ticklecharts::ehuddle {

    method set {args} {
        # set dict option to huddle instance
        # 
        # args - dict options from chart class
        #
        # Returns huddle

        if {[llength $args] % 2} {
            error "args list must have an even number of elements..."
        }

        set lhuddle {}

        foreach {key info} $args {

            lassign [split $key "="] type keyvalue

            if {$info eq "nothing"} {continue}
            # Transform key to huddle type...
            #
            switch -exact -- $type {
                "@B"    {set value [huddle boolean $info]}
                "@S"    {set value [huddle string $info]}
                "@N"    {set value [huddle number $info]}
                "@NULL" {set value [huddle null]}
                "@LS"   {
                            set value [huddle list {*}[join $info]]
                        }
                "@LN"   {
                            set listv [ticklecharts::ehuddleListNum $info]
                            set value [format {HUDDLE {L {%s}}} $listv]
                        }
                "@LD"   {
                            if {[llength {*}$info] == 1} {
                                set listv [ticklecharts::ehuddleListInsert $info]
                            } else {
                                set listv [ticklecharts::ehuddleListMap $info]
                            }
                            set value [format {HUDDLE {L {%s}}} $listv]
                        }
                "@LJ"   {
                            set subH {}
                            foreach var {*}$info {
                                lassign $var k vvv 
                                lassign [split $k "="] type kk
                                switch -exact -- $type {
                                    "@LS"   {set h [huddle list {*}[join $vvv]]}
                                    "@L"    {lappend subH [huddle create {*}[my set {*}$vvv]]}
                                    default {error "no @LJ type '$type' specified for '$keyvalue'"}
                                }
                            }
                            set value [huddle append h {*}$subH]
                       }
                "@JS"  {set value [huddle jsfunc [$info get]]}
                "@D"   {set value [huddle list [huddle create {*}[my set {*}$info]]]}
                "@L"   {set value [huddle create {*}[my set {*}$info]]}
                "@AO"  {
                            foreach lvalue $info {
                                set subdata {}
                                foreach {k val} $lvalue {
                                    lassign [split $k "="] subtype subkeyvalue1

                                    switch -exact -- $subtype {
                                        "@L"    -
                                        "@DO"   -
                                        "@B"    -
                                        "@S"    -
                                        "@N"    -
                                        "@NULL" -
                                        "@JS"   -
                                        "@LS"   -
                                        "@LD"   -
                                        "@LN"  {lappend subdata {*}[my set $k $val]}
                                        default {error "(2) Unknown type '$subtype' specified for '$subkeyvalue1'"}
                                    }
                                }
                                lappend lhuddle [huddle create {*}$subdata]
                            }
                            continue
                        }
                "@DO"   {
                            set subdata {} ; set subdatalist {}
                            foreach {k val} $info  {
                                if {$k ne "@AO"} { error "key value must be @AO instead of '$k'"}
                                set suv {}
                                foreach vv $val {
                                    set subdatalist {}
                                    foreach {sk vk} $vv {
                                        lassign [split $sk "="] subtype _
                                        switch -exact -- $subtype {
                                            "@D"  {
                                                    set dlist {}
                                                    foreach vald $vk {
                                                        set llist {}
                                                        foreach {subkeyvald subvald} $vald {
                                                            set _subdata {}
                                                            lassign [split $subkeyvald "="] subtype subkeyvalue1
                                                            switch -exact -- $subtype {
                                                                "@L"    -
                                                                "@B"    -
                                                                "@S"    -
                                                                "@N"    -
                                                                "@NULL" -
                                                                "@JS"   -
                                                                "@LS"   -
                                                                "@LD"   -
                                                                "@LN"  {lappend _subdata {*}[my set $subkeyvald $subvald]}
                                                                default {error "(3) Unknown type '$subtype' specified for '$subkeyvalue1'"}
                                                            }

                                                            if {$_subdata ne ""} {append llist "$_subdata "}
                                                        }
                                                        lappend dlist [huddle create {*}$llist]
                                                    }
                                                    lappend suv [huddle list {*}$dlist]
                                            }
                                            default {lappend subdatalist {*}[my set $sk $vk]}
                                        }
                                    }
                                    if {[llength $subdatalist]} {
                                        lappend suv [huddle create {*}$subdatalist]
                                    }
                                }
                                lappend subdata {*}$suv
                            }
                            set value [huddle list {*}$subdata]
                        }

                default {error "(1) Unknown type '$type' specified for '$keyvalue'"}
            }

            lappend lhuddle $keyvalue $value
        }

        lassign [info level 0] obj

        if {[ticklecharts::isAObject $obj]} {
            lappend _huddle [huddle create {*}$lhuddle]
        }

        return $lhuddle
    }

    method extract {} {
        # Combine huddle
        if {[my llength] == 1} {
            return {*}$_huddle
        }

        return [huddle combine {*}$_huddle]
    }

    method append {key value} {
        # append dict option to huddle instance or
        # set huddle if key doesn't exist...
        # 
        # key   - dict key
        # value - dict value
        #
        # append huddle to global '_huddle'. 
    
        set _h [ticklecharts::ehuddle new]
        lassign [split $key "="] type valkey

        # special case for timeline class
        set infolevel2 [lindex [info level 2] 1]
        set timeline [expr {($infolevel2 eq "timelineToHuddle") ? 1 : 0}]

        set listk {}
        foreach {k val} $value {
            if {$timeline} {
                if {[string match {*@D=*} $k] && ($k in $listk)} {
                    $_h append $k $val
                } else {
                    $_h set $k $val
                }
                lappend listk $k
            } else {
                $_h set $k $val
            }
        }

        if {$valkey in [my keys]} {
            set h [my extract]
            set index [huddle llength [huddle get $h $valkey]]
            huddle set h $valkey $index [$_h extract]
        } else {
            [self] set $key {}
            set h [my extract]

            if {$type eq "@L"} {
                huddle set h $valkey [$_h extract]
            } else {
                huddle set h $valkey 0 [$_h extract]
            }
        }

        # Add series type...
        if {[string match {*=series*} $key]} {
            if {[dict exists $value "@S=type"]} {
                lappend _series [dict get $value "@S=type"]
            }
        }
        
        # destroy...
        $_h destroy

        # set new huddle list
        set _huddle [list $h]

        return {}
    }

    method llength {} {
        # Returns the length of huddle instance
        return [llength $_huddle]
    }
    
    method get {} {
        # Returns the value of huddle instance
        return $_huddle
    }

    method getTypeSeries {} {
        # Returns list type series.
        return [lsort -unique $_series]
    }

    method keys {} {
        # Returns the keys of huddle instance
        if {[my llength]} {
            return [huddle keys [my extract]]
        } else {
            return {}
        }
    }
    
    method toJSON {} {
        # Transform huddle to JSON
        # replace special chars by space... etc.
        # 
        # Returns JSON
        set lstringmap {
            <@!> " "
            <s!> ""
            <n?> "\\n"
            <0123> \{
            <0125> \}
            <091> \[
            <093> \]
            \\/ /
        }
        return [string map $lstringmap [huddle jsondump [my extract]]]
    }
}

proc ticklecharts::ehuddle_num val {
    # Returns format hudlle num
    if {![string is double -strict $val]} {
        error "Argument 'ehuddle' num '$val' is not a number"
    }

    return [list num $val]

}

proc ticklecharts::ehuddleListNum data {
    # Map tcl list to huddle format list number
    #
    # Returns huddle list
    set listv {}

    if {[llength {*}$data] == 1} {
        foreach val [lindex {*}$data 0] {
            lappend listv [ticklecharts::ehuddle_num $val]
        }
    } else {
        foreach val {*}$data {
            lappend listv [format {L {%s}} [lmap v $val {
                        ticklecharts::ehuddle_num $v
                    }
                ]
            ]
        }
    }

    return $listv
}

proc ticklecharts::ehuddleListMap data {
    # Map tcl list
    #
    # Returns huddle format list
    set listv {}

    foreach val {*}$data {
        lappend listv [format {L {%s}} [lmap v $val {
                    if {[string is double -strict $v]} {
                        list num $v
                    } elseif {$v eq "null"} {
                        list null
                    } else {
                        list s $v
                    }
                }
            ]
        ]
    }

    return $listv
}

proc ticklecharts::ehuddleListInsert data {
    # Transform tcl list
    #
    # Returns huddle list
    set listv {}

    foreach val [lindex {*}$data 0] {
        if {[string is double -strict $val]} {
            lappend listv [list num $val]
        } elseif {$val eq "null"} {
            lappend listv [list null]
        } else {
            lappend listv [list s $val]
        }
    }

    return $listv
}

proc ticklecharts::eHuddleCritcl {bool} {
    # Replaces some huddle procedures by C functions,
    # with help of critcl package https://andreas-kupries.github.io/critcl/
    #
    # bool - true or false 
    #
    # Returns Nothing
    variable edir

    if {$bool} {
        if {![catch {uplevel 1 [list source [file join $edir ehuddlecrit.tcl]]} infocrit]} {
            # Replace 'if {[isHuddle $key]} {...}' by 'if {[huddle::isHuddle $key]} {...}'
            # Problem if full namespace is not included... 
            proc ::huddle::types::dict::create {args} {
                if {[llength $args] % 2} {error {wrong # args: should be "huddle create ?key value ...?"}}
                set resultL [dict create]
                
                foreach {key value} $args {
                    if {[huddle::isHuddle $key]} {
                        foreach {tag src} [unwrap $key] break
                        if {$tag ne "string"} {error "The key '$key' must a string literal or huddle string" }
                        set key $src
                    }
                    dict set resultL $key [argument_to_node $value]
                }
                return [wrap [list D $resultL]]
            }

            # JsonDump
            rename ::huddle::jsondump "" ; # delete proc
            rename ticklecharts::critJsonDump ::huddle::jsondump
            # RetrieveHuddle
            rename ::huddle::retrieve_huddle "" ; # delete proc
            rename critRetrieveHuddle ::huddle::retrieve_huddle
            # IsHuddle
            rename ::huddle::isHuddle "" ; # delete proc
            rename critIsHuddle ::huddle::isHuddle
            # huddle list
            rename ::huddle::types::list::List "" ; # delete proc
            rename ticklecharts::critHList ::huddle::types::list::List

            # ehuddle procedures :
            rename ::ticklecharts::ehuddleListMap "" ; # delete proc
            rename critHuddleListMap ::ticklecharts::ehuddleListMap

            rename ::ticklecharts::ehuddleListInsert "" ; # delete proc
            rename critHuddleListInsert ::ticklecharts::ehuddleListInsert

        } else {
            puts "warning : $infocrit"
        }
    }

    return {}
}

# Add jsfunc as hudlle type
huddle addType ::huddle::types::jsfunc