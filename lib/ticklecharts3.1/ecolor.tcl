# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

# From 'Apache echarts documentation' :
# (https://echarts.apache.org/en/option.html#color) :
#
# Don't use this Class for string or list representation...

oo::class create ticklecharts::eColor {
    variable _ecolor

    constructor {args} {
        # Initializes a new eColor Class.
        #
        # args - Options described below.

        set _ecolor [ticklecharts::colorItem {*}$args]
    }
}

oo::define ticklecharts::eColor {
    method get {} {
        # Returns color list
        return $_ecolor
    }
    
    method getType {} {
        # Returns type
        return "eColor"
    }
}

proc ticklecharts::colorItem {value} {

    if {[llength $value] % 2} {
        error "item list for '[ticklecharts::getLevelProperties [info level]]' must have an even number of elements..."
    }

    setdef options type        -minversion 5  -validvalue formatTypeColor    -type str|null         -default "nothing"
    setdef options x           -minversion 5  -validvalue {}                 -type num|null         -default "nothing"
    setdef options y           -minversion 5  -validvalue {}                 -type num|null         -default "nothing"
    setdef options x2          -minversion 5  -validvalue {}                 -type num|null         -default "nothing"
    setdef options y2          -minversion 5  -validvalue {}                 -type num|null         -default "nothing"
    setdef options colorStops  -minversion 5  -validvalue {}                 -type list.o|null      -default [ticklecharts::colorStops $value]
    setdef options r           -minversion 5  -validvalue {}                 -type num|null         -default "nothing"
    setdef options global      -minversion 5  -validvalue {}                 -type bool|null        -default "nothing"
    setdef options image       -minversion 5  -validvalue {}                 -type str|jsfunc|null  -default "nothing"
    setdef options repeat      -minversion 5  -validvalue formatColorRepeat  -type str|null         -default "nothing"
    #...

    # remove key(s)
    set value [dict remove $value colorStops]

    set options [merge $options $value]

    return $options
}


proc ticklecharts::colorStops {value} {

    if {![ticklecharts::keyDictExists "colorStops" $value key]} {
        return "nothing"
    }

    foreach item [dict get $value $key] {

        if {[llength $item] % 2} {
            error "item list for '[ticklecharts::getLevelProperties [info level]]' must have an even number of elements..."
        }

        setdef options offset  -minversion 5  -validvalue {}           -type num|null         -default "nothing"
        setdef options color   -minversion 5  -validvalue formatColor  -type str|jsfunc|null  -default "nothing"
        #...

        lappend opts [merge $options $item]
        set options {}

    }

    return [list {*}$opts]
}