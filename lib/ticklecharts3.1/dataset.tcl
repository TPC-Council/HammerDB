# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

# From 'Apache echarts documentation' :
# (https://echarts.apache.org/handbook/en/concepts/dataset/) :
#
# 'dataset' is a component dedicated to manage data. Although you can set
# the data in series.data for every series, we recommend you use the 'dataset'
# to manage the data since ECharts 4 so that the data can be reused by multiple 
# components and convenient for the separation of "data and configs". 
# After all, data is the most common part to be changed while other
# configurations will mostly not change at runtime.

oo::class create ticklecharts::dataset {
    variable _dataset
    variable _dimension

    constructor {args} {
        # Initializes a new dataset Class.
        #
        # args - dataset args.
        #
        set _dimension "nothing"

        if {[llength $args] != 1} {
            error "args should be a list of 1 element for 'dataset' constructor..."
        }

        foreach item {*}$args {

            if {[llength $item] % 2} {
                error "item list must have an even number of elements..."
            }

            setdef options -id                   -minversion 5  -validvalue {}                 -type str|null          -default "nothing"
            setdef options -sourceHeader         -minversion 5  -validvalue formatSourceHeader -type str|bool|num|null -default "nothing"
            setdef options -dimensions           -minversion 5  -validvalue {}                 -type list.j|null       -default [my dimensions $item]
            setdef options -source               -minversion 5  -validvalue {}                 -type list.d|null       -default [my source $item]
            setdef options -transform            -minversion 5  -validvalue {}                 -type list.o|null       -default [my transform $item]
            setdef options -fromDatasetIndex     -minversion 5  -validvalue {}                 -type num|null          -default "nothing"
            setdef options -fromDatasetId        -minversion 5  -validvalue {}                 -type str|null          -default "nothing"
            setdef options -fromTransformResult  -minversion 5  -validvalue {}                 -type num|null          -default "nothing"

            set item  [dict remove $item -transform -dimensions]

            # set dataset...
            lappend opts [merge $options $item]
            set options {}
        }

        set _dataset [list {*}$opts]
    }
}

oo::define ticklecharts::dataset {
    method get {} {
        # Returns dataset
        return $_dataset
    }

    method getType {} {
        # Returns type
        return "dataset"
    }

    method dim {} {
        # Returns data dim
        return $_dimension
    }

    method dimensions {value} {
        # Set dimension
        #
        # value - dict
        #
        # Returns dimension

        if {![ticklecharts::keyDictExists "-dimensions" $value key]} {
            return "nothing"
        }

        set d {}

        foreach dim [dict get $value $key] {
            if {[ticklecharts::isDict $dim] && [llength $dim] > 2 && 
               ([dict exists $dim value] || [dict exists $dim name] || [dict exists $dim type])} {

                setdef options name   -minversion 5  -validvalue {}            -type str|null  -default "nothing"
                setdef options value  -minversion 5  -validvalue {}            -type num|null  -default "nothing"
                setdef options type   -minversion 5  -validvalue formatDimType -type str|null  -default "nothing"

                lappend d [list [new edict [merge $options $dim]] dict] ; continue

            }
            lappend vald [ticklecharts::mapSpaceString $dim]
        }

        if {[llength $d] == 0} {
            set _dimension [list [list $vald list.s]]
        } else {
            set _dimension [join [list [list [list $vald list.s]] $d]]
        }

        return $_dimension
    }

    method transform {value} {
        # Transform dataset
        #
        # value - dict
        #
        # Returns list transform value(s)

        if {![ticklecharts::keyDictExists "-transform" $value key]} {
            return "nothing"
        }

        foreach item [dict get $value $key] {

            setdef options type   -minversion 5  -validvalue formatTransform -type str       -default "filter"
            setdef options config -minversion 5  -validvalue {}              -type dict|null -default [ticklecharts::config $item]
            setdef options print  -minversion 5  -validvalue {}              -type bool      -default "False"

            # Remove key(s)
            set item [dict remove $item config]

            lappend opts [merge $options $item]
            set options {}

        }

        return [list {*}$opts]

    }

    method source {value} {
        # source dataset
        #
        # value - dict
        #
        # Returns 'source' data value

        if {![ticklecharts::keyDictExists "-source" $value key]} {
            return "nothing"
        }

        return [dict get $value $key]
    }

}