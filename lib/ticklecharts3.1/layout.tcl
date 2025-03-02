# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

# This class allows you to add multiple charts on the same div...
# The charts are not necessarily of the same type.
# The first chart needs to be a graph with an x/y axis.

oo::class create ticklecharts::Gridlayout {
    variable _layout       ; # huddle
    variable _indexchart2D ; # grid index chart2D
    variable _indexchart3D ; # grid index chart3D
    variable _options      ; # list options chart
    variable _charts2D     ; # list charts 2D
    variable _charts3D     ; # list charts 3D
    variable _keyglob      ; # global key options
    variable _dataset

    constructor {args} {
        # Initializes a new layout Class.
        #
        # args - Options described below.
        #
        # -theme  - name theme see : theme.tcl
        #
        ticklecharts::setTheme $args ; # theme options
        set _options   {}
        set _keyglob   {}
        set _dataset   {}
        set _charts2D  {}
        set _charts3D  {}
        set _indexchart2D -1
        set _indexchart3D -1
    }
}

oo::define ticklecharts::Gridlayout {

    method get {} {
        # Gets huddle object
        return $_layout
    }

    method options {} {
        # Gets options object
        return $_options
    }

    method globalKeyOptions {} {
        # Gets global key options
        return $_keyglob
    }

    method dataset {} {
        # Gets dataset
        return $_dataset
    }

    method getType {} {
        # Returns type of class
        return "gridlayout"
    }

    method Add {chart {args ""}} {
        # Add charts to layout
        #
        # chart - chart object
        # args  - Options described below (optional).
        #
        # -top    - Distance between grid component and the top side of the container. (% or number)
        # -bottom - Distance between grid component and the bottom side of the container. (% or number)
        # -left   - Distance between grid component and the left side of the container. (% or number)
        # -right  - Distance between grid component and the right side of the container. (% or number)
        # -width  - Width of grid component. Adaptive by default. (% or number)
        # -height - Height of grid component. Adaptive by default. (% or number)
        # -center - Center position of Polar coordinate, the first of which is the horizontal position, 
        #           and the second is the vertical position. (array)
        #
        # Returns nothing
        foreach {key value} $args {

            if {$value eq ""} {
                error "No value specified for key '$key'"
            }

            if {[llength $value] != [llength $chart]} {
                error "llength charts must be equal with values of $key"
            }

            switch -exact -- $key {
                "-top"    {set top $value}
                "-bottom" {set bottom $value}
                "-left"   {set left $value}
                "-right"  {set right $value}
                "-width"  {set width $value}
                "-height" {set height $value}
                "-center" {set center $value}
                default {error "Unknown key '$key' specified"}
            }
        }

        set keys      [$chart keys]
        set chartType [$chart getType]

        if {"series" ni $keys} {
            error "charts must have a key 'series'"
        }

        # not supported yet...
        if {"graphic" in $keys} {
            error "graphic not supported..."
        }

        if {([lsearch $keys grid*] == -1) && ($args eq "")} {
            error "charts must have a grid key if no options..."
        }

        switch -exact -- $chartType {
            "chart"   {incr _indexchart2D ; lappend _charts2D $chart}
            "chart3D" {incr _indexchart3D ; lappend _charts3D $chart}
            default {error "class chart not supported..."}
        }

        set g 0 ; # variable for grid*
        # Gets global options...
        set optsg [ticklecharts::globalOptions {}]
        set gopts [string map {- ""} [dict keys [$optsg get]]]

        foreach {key opts} [$chart options] {

            switch -glob -- $key {
                *legend  {
                    # Find data name in series if data legend is not specified...
                    if {[lsearch [dict keys $opts] *data] == -1 || [lsearch [dict keys $opts] @NULL=data] > -1} {
                        set data_name {}
                        foreach series_opts [lsearch -all [$chart options] *=series] {
                            set myserie [lindex [$chart options] [expr {$series_opts + 1}]]

                            # if item data...
                            if {[dict exists $myserie @DO=data @AO]} {
                                foreach data_item [dict get $myserie @DO=data @AO] {
                                    if {[dict exists $data_item @S=name]} {
                                        lappend data_name [dict get $data_item @S=name]
                                    } else {
                                        if {[dict get $myserie @S=name] ni $data_name} {
                                            lappend data_name [dict get $myserie @S=name]
                                        }
                                    }
                                }
                            } else {
                                lappend data_name [dict get $myserie @S=name]
                            }

                        }
                        # add data name in legend...
                        dict set opts @LS=data [list $data_name]
                    }
                }
                *series  {
                    # force index axis chart if exists or not...
                    # 2D
                    if {[dict get $opts @S=type] in {bar line scatter effectScatter heatmap pictorialBar candlestick graph boxplot lines}} {

                        set xindex [lsearch -inline [dict keys $opts] *xAxisIndex]
                        set yindex [lsearch -inline [dict keys $opts] *yAxisIndex]

                        if {[dict exists $opts $xindex]} {
                            if {[dict get $opts $xindex] eq "nothing"} {dict set opts @N=xAxisIndex $_indexchart2D} 
                        } else {
                            dict set opts @N=xAxisIndex $_indexchart2D
                        }

                        if {[dict exists $opts $yindex]} {
                            if {[dict get $opts $yindex] eq "nothing"} {dict set opts @N=yAxisIndex $_indexchart2D}
                        } else {
                            dict set opts @N=yAxisIndex $_indexchart2D
                        }
                    }

                    # 3D
                    if {[dict get $opts @S=type] in {bar3D line3D surface}} {

                        set gridindex [lsearch -inline [dict keys $opts] *grid3DIndex]

                        if {[dict exists $opts $gridindex]} {
                            if {[dict get $opts $gridindex] eq "nothing"} {dict set opts @N=grid3DIndex $_indexchart3D} 
                        } else {
                            dict set opts @N=grid3DIndex $_indexchart3D
                        }
                    }

                    set stack [lsearch -inline [dict keys $opts] *stack]
                    if {[dict exists $opts $stack] && [dict get $opts $stack] ne "null"} {
                        set value [dict get $opts $stack]
                        if {[$chart getType] eq "chart3D"} {
                            dict set opts $stack [ticklecharts::mapSpaceString "$value $_indexchart3D"]
                        } else {
                            dict set opts $stack [ticklecharts::mapSpaceString "$value $_indexchart2D"]
                        }
                    }

                    # replace 'center' flag if exists by the one in args if exists...
                    if {[dict get $opts @S=type] in {pie sunburst gauge}} {
                        if {[info exists center]} {
                            set mytype [ticklecharts::typeOf $center]
                            if {$mytype ne "list"} {
                                error "'center' flag must be a list"
                            }
                            dict set opts @LD=center [list $center]
                        }
                    }

                    # set position in series instead of grid... 
                    # For 'funnel', 'sankey', 'treemap', 'map' or 'wordCloud' chart
                    if {[dict get $opts @S=type] in {sankey funnel wordCloud treemap map}} {
                        set g 1
                        foreach val {top bottom left right width height} {
                            if {[info exists [set val]]} {
                                set myvalue [expr $[set val]]
                                set mytype [ticklecharts::typeOf $myvalue]

                                switch -- $mytype {
                                    "str"   {dict set opts @S=$val $myvalue}
                                    "num"   {dict set opts @N=$val $myvalue}
                                    default {error "$val must be a str or a float... now is $mytype"}
                                }
                            }
                        }
                    }
                }
                *radar -
                *polar {
                    set coordinatecenter [lsearch -inline [dict keys $opts] *center]
                    if {[info exists center]} {
                        set mytype [ticklecharts::typeOf $center]
                        if {$mytype ne "list"} {
                            error "'center' flag must be a list"
                        }
                        dict set opts @LD=center [list $center]
                    }
                }
                *visualMap {
                    dict set opts @N=seriesIndex $_indexchart2D
                }
                *xAxis3D -
                *yAxis3D -
                *zAxis3D {
                    dict set opts @N=grid3DIndex $_indexchart3D
                }
                *xAxis -
                *yAxis  {
                    dict set opts @N=gridIndex $_indexchart2D
                }
                *singleAxis -
                *grid3D -
                *grid  {
                    set g 1
                    foreach val {top bottom left right width height} {
                        if {[info exists [set val]]} {
                            set myvalue [expr $[set val]]
                            set mytype [ticklecharts::typeOf $myvalue]

                            switch -- $mytype {
                                "str"   {dict set opts @S=$val $myvalue}
                                "num"   {dict set opts @N=$val $myvalue}
                                default {error "$val must be a str or a float... now is $mytype"}
                            }
                        }
                    }
                }
            }

            # remove key global options 
            lassign [split $key "="] _ k
            if {$k in $gopts} {continue}

            if {$key in [my globalKeyOptions]} {
                puts "warning(ticklecharts::Gridlayout): '$key' in chart class is already\
                     activated with 'SetGlobalOptions' method\
                     it is not taken into account..."
                continue
            }

            lappend _options $key $opts
        }

        # Check if grid is present
        # add grid option if no...
        if {!$g} {
            set f {}
            foreach val {top bottom left right width height} {
                if {[info exists [set val]]} {
                    set myvalue [expr $[set val]]
                    set mytype [ticklecharts::typeOf $myvalue]

                    switch -- $mytype {
                        "str"   {lappend f @S=$val $myvalue}
                        "num"   {lappend f @N=$val $myvalue}
                        default {error "$val must be a str or a float... now is $mytype"}
                    }
                }
            }
            if {[llength $f]} {
                switch -exact -- $chartType {
                    "chart"   {lappend _options @D=grid [list {*}$f]}
                    "chart3D" {lappend _options @D=grid3D [list {*}$f]}
                }
            }
        }

        # Check if polar key exists in first place
        # Error if yes , not possible.
        set keypolar [lsearch [dict keys $_options] *polar]
        if {!$_indexchart2D && $keypolar > -1} {
            error "'Polar' mode should not be added first..."
        }

        # Check if radar key exists in first place
        # Error if yes , not possible.
        set keyradar [lsearch [dict keys $_options] *radar]
        if {!$_indexchart2D && $keyradar > -1} {
            error "'Radar' mode should not be added first..."
        }

        # Check if pie, sunburst, themeriver, sankey... chart type exists in first place
        # Error if yes, not possible.
        if {[dict exists $_options @D=series @S=type]} {
            if {!$_indexchart2D} {
                switch -exact -- [dict get $_options @D=series @S=type]  {
                    pie        {error "'Pie' chart should not be added first..."}
                    sunburst   {error "'Sunburst' chart should not be added first..."}
                    themeRiver {error "'ThemeRiver' chart should not be added first..."}
                    sankey     {error "'Sankey' chart should not be added first..."}
                    gauge      {error "'Gauge' chart should not be added first..."}
                    wordCloud  {error "'wordCloud' should not be added first..."}
                    treemap    {error "'treemap' should not be added first..."}
                    map        {error "'map' should not be added first..."}
                    lines      {error "'lines' should not be added first..."}
                }
            }
        }

        return {}
    }

    method layoutToHuddle {} {
        # Transform list layout to hudlle
        #
        # Returns nothing

        # Bug when several 'tooltip' < 5.3.0
        if {([ticklecharts::vCompare $::ticklecharts::echarts_version "5.3.0"] == -1) && 
            ([llength [lsearch -all -exact $_options @D=tooltip]] > 1)} {
            error "Several 'tooltip' not supported..."
        }

        # Insert or not global options in the top of list.
        set match2D 0 ; set match3D 0
        if {![llength [my globalKeyOptions]]} {
            # priority chart 2D for global options
            foreach chart $_charts2D {
                if {[$chart globalOptions] ne ""} {
                    set _options [linsert $_options 0 {*}[$chart globalOptions]]
                    set match2D 1 ; break
                }
            }
            if {!$match2D} {
                foreach chart $_charts3D {
                    if {[$chart globalOptions] ne ""} {
                        set _options [linsert $_options 0 {*}[$chart globalOptions]]
                        set match3D 1 ; break
                    }
                }
            }
        }

        set opts $_options

        # no global options adds if need.
        if {![llength [my globalKeyOptions]] && !$match2D && !$match3D} {
            set optsg  [ticklecharts::globalOptions {}]
            set optsEH [ticklecharts::optsToEchartsHuddle [$optsg get]]
            set opts   [linsert $opts 0 {*}$optsEH]
        }

        # init ehuddle.
        set _layout [ticklecharts::ehuddle new]

        foreach {key value} $opts {
            lassign [split $key "="] type _
            if {($type eq "@D" || $type eq "@L") && $value ne ""} {
                $_layout append $key $value
            } else {
                $_layout set $key $value
            }
        }

        return {}
    }
    
    method Render {args} {
        # Export chart to html.
        #
        # args - Options described below.
        #
        # -title      - header title html
        # -width      - size html canvas
        # -height     - size html canvas
        # -renderer   - 'canvas' or 'svg'
        # -jschartvar - name chart var
        # -divid      - name id var
        # -outfile    - full path html (by default in [info script]/render.html)
        # -jsecharts  - full path echarts.min.js (by default cdn script)
        # -jsvar      - name js var
        # -script     - list data (jsfunc), jsfunc.
        # -class      - container.
        # -style      - css style.
        #
        # Returns full path html file.

        my layoutToHuddle ; # transform to huddle
        set myhuddle [my get]
        set json     [$myhuddle toJSON] ; # jsondump

        set opts_html  [ticklecharts::htmlOptions $args]
        set newhtml    [ticklecharts::htmlMap $myhuddle $opts_html]
        set outputFile [lindex [dict get $opts_html -outfile] 0]
        set jsvar      [lindex [dict get $opts_html -jsvar] 0]

        set fp [open $outputFile w+]
        puts $fp [string map [list %json% "var $jsvar = $json"] $newhtml]
        close $fp

        if {$::ticklecharts::htmlstdout} {
            puts [format {html:%s} [file nativename $outputFile]]
        }

        return $outputFile
    }

    method toJSON {} {
        # Returns json chart data.
        my layoutToHuddle ; # transform to huddle
        
        # ehuddle jsondump
        return [[my get] toJSON]
    }

    method SetGlobalOptions {args} {
        # Set global options for all charts (2D + 3D) class
        #
        # Returns nothing
        set c [ticklecharts::chart new]
        $c SetOptions {*}$args

        lappend _options {*}[$c options]
        lappend _keyglob {*}[dict keys [$c options]]

        # check if chart has dataset.
        # save is yes...
        if {[$c dataset] ne ""} {
            set _dataset [$c dataset]
        }

        # destroy...
        $c destroy

        # doesn't support 3D options
        set keys [dict keys $args]
        foreach opts3D {-grid3D -globe -geo3D -mapbox3D} {
            if {$opts3D in $keys} {
                error "$opts3D (options 3D) not supported...\
                with 'SetGlobalOptions' method"
            }
        }

        return {}
    }

    # export method
    export Add Render SetGlobalOptions
    
}

proc ticklecharts::gridlayoutHasDataSetObj {dts} {
    # Check if gridlayout has dataset class
    # only for chart class
    #
    # dts - upvar
    #
    # Returns True if 'dataset' class is present, False otherwise.
    upvar 1 $dts dataset

    foreach obj [concat [ticklecharts::listNs] "::"] {
        if {[ticklecharts::isAObject $obj]} {
            if {[ticklecharts::typeOfClass $obj] eq "::ticklecharts::Gridlayout"} {
                if {[$obj dataset] ne ""} {
                    set dataset [$obj dataset]
                    return 1
                }
            }
        }
    } 

    return 0
}