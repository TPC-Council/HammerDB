# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

# timeline class, which provides functions like switching and playing
# between multiple ECharts options.

oo::class create ticklecharts::timeline {
    variable _base    ; # huddle
    variable _data    ; # list data value
    variable _charts  ; # list charts
    variable _opts    ; # list options timeline

    constructor {args} {
        # Initializes a new timeline Class.
        #
        # args - Options described below.
        #
        # -theme  - name theme see : theme.tcl
        #
        ticklecharts::setTheme $args ; # theme options
        set _data    {}
        set _charts  {}
        set _opts    {}
    }
}

oo::define ticklecharts::timeline {
    
    method getType {} {
        # Returns type
        return "timeline"
    }

    method get {} {
        # Gets huddle object
        return $_base
    }

    method SetOptions {args} {
        # options : https://echarts.apache.org/en/option.html#timeline
        #
        # args - Options described in proc ticklecharts::timelineOpts below.
        #
        # return nothing

        set _opts {}
        lappend _opts "@L=timeline" [ticklecharts::timelineOpts $args]

        return {}
    }

    method Add {chart args} {
        # Add data dict to timeline options
        #
        # return nothing

        if {[llength $args] == 0} {
            error "data should be present... for timeline option"
        }

        if {![expr {[$chart getType] eq "chart" || [$chart getType] eq "chart3D" ||
                    [$chart getType] eq "gridlayout"}]} {
            error "first argument for 'Add' method should be a 'chart', 'chart3D' or 'gridlayout' class."
        }

        lappend _data [ticklecharts::timelineItem $args]
        lappend _charts $chart

        return {}
    }

    method timelineToHuddle {} {
        # Transform list to ehudlle
        #
        # Returns nothing

        # init ehuddle.
        set _base [ticklecharts::ehuddle new]

        # timeline data
        set key      [lindex $_opts 0]
        set dataopts [lindex $_opts 1]

        # Insert data to timeline options
        lappend timeline_opts $key [linsert $dataopts end {*}[format "-data {{%s} list.o}" $_data]]

        # get keys from global options & remove...
        set optsglob [ticklecharts::globalOptions {}]
        set keysoptsglob [dict keys [ticklecharts::optsToEchartsHuddle [$optsglob get]]]

        # add keys from 'SetOptions' ticklecharts::chart*  method
        lappend infomethod [lindex [info class definition ticklecharts::chart   "SetOptions"] 1]
        lappend infomethod [lindex [info class definition ticklecharts::chart3D "SetOptions"] 1]
        foreach linebody [split $infomethod "\n"] {
            if {[string match {*@*} $linebody]} {
                set keyopts [lindex $linebody 2]
                if {[string range $keyopts 0 2] eq "@D=" || [string range $keyopts 0 2] eq "@L="} {
                    lappend keysoptsglob $keyopts
                }
            }
        }

        # get first chart
        set optschart [[lindex $_charts 0] options]

        # remove keys global for baseOption...
        foreach {key value} $optschart {
            if {$key in $keysoptsglob} {
                continue
            }
            lappend baseOption $key $value
        }

        # add timeline options to huddle baseOption.
        foreach {key value} $timeline_opts {
            set f [ticklecharts::optsToEchartsHuddle $value]
            lappend baseOption $key [list {*}$f]
        }
        # Add baseOption
        $_base append "@L=baseOption" $baseOption
        
        # add all charts to 'option' key
        foreach chart $_charts {
            set optschart [$chart options]
            set option {}

            foreach {key value} $optschart {
                lappend option $key $value
            }

            $_base append "@D=options" $option
        }

        return {}
    }

    method toJSON {} {
        # Returns json timeline data.
        my timelineToHuddle ; # transform to huddle
        
        # ehuddle jsondump
        return [[my get] toJSON]
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

        my timelineToHuddle ; # transform to huddle
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

    # export method
    export Add SetOptions Render

}

proc ticklecharts::timelineOpts {value} {
    # timeline options
    #
    # Returns dict options

    setdef options -show                -minversion 5  -validvalue {}                      -type bool                 -default "True"
    setdef options -type                -minversion 5  -validvalue formatTimelineType      -type str                  -default "slider"
    setdef options -axisType            -minversion 5  -validvalue formatTimelineAxisType  -type str                  -default "time"
    setdef options -currentIndex        -minversion 5  -validvalue {}                      -type num|null             -default "nothing"
    setdef options -autoPlay            -minversion 5  -validvalue {}                      -type bool|null            -default "nothing"
    setdef options -rewind              -minversion 5  -validvalue {}                      -type bool|null            -default "nothing"
    setdef options -loop                -minversion 5  -validvalue {}                      -type bool                 -default "True"
    setdef options -playInterval        -minversion 5  -validvalue {}                      -type num                  -default 1000
    setdef options -realtime            -minversion 5  -validvalue {}                      -type bool                 -default "True"
    setdef options -replaceMerge        -minversion 5  -validvalue formatTimelineMerge     -type str|list.s|null      -default "nothing"
    setdef options -controlPosition     -minversion 5  -validvalue formatTimelinePosition  -type str                  -default "left"
    setdef options -width               -minversion 5  -validvalue {}                      -type num|null             -default "nothing"
    setdef options -zlevel              -minversion 5  -validvalue {}                      -type num|null             -default "nothing"
    setdef options -z                   -minversion 5  -validvalue {}                      -type num                  -default 2
    setdef options -left                -minversion 5  -validvalue formatLeft              -type str|num|null         -default "nothing"
    setdef options -top                 -minversion 5  -validvalue formatTop               -type str|num|null         -default "nothing"
    setdef options -right               -minversion 5  -validvalue formatRight             -type str|num|null         -default "nothing"
    setdef options -bottom              -minversion 5  -validvalue formatBottom            -type str|num|null         -default "nothing"
    setdef options -padding             -minversion 5  -validvalue {}                      -type num|list.n           -default 5
    setdef options -orient              -minversion 5  -validvalue formatOrient            -type str                  -default "horizontal"
    setdef options -inverse             -minversion 5  -validvalue {}                      -type bool|null            -default "nothing"
    setdef options -itemSymbol          -minversion 5  -validvalue formatItemSymbol        -type str|null             -default "emptyCircle"
    setdef options -symbolSize          -minversion 5  -validvalue {}                      -type num|list.n           -default 10
    setdef options -symbolRotate        -minversion 5  -validvalue {}                      -type num|null             -default "nothing"
    setdef options -symbolKeepAspect    -minversion 5  -validvalue {}                      -type bool|null            -default "nothing"
    setdef options -symbolOffset        -minversion 5  -validvalue {}                      -type list.n|null          -default "nothing"
    setdef options -lineStyle           -minversion 5  -validvalue {}                      -type dict|null            -default [ticklecharts::lineStyle $value]
    setdef options -label               -minversion 5  -validvalue {}                      -type dict|null            -default [ticklecharts::label $value]
    setdef options -itemStyle           -minversion 5  -validvalue {}                      -type dict|null            -default [ticklecharts::itemStyle $value]
    setdef options -checkpointStyle     -minversion 5  -validvalue {}                      -type dict|null            -default [ticklecharts::checkPointStyle $value]
    setdef options -controlStyle        -minversion 5  -validvalue {}                      -type dict|null            -default [ticklecharts::controlStyle $value]
    setdef options -progress            -minversion 5  -validvalue {}                      -type dict|null            -default [ticklecharts::progress $value]
    setdef options -emphasis            -minversion 5  -validvalue {}                      -type dict|null            -default [ticklecharts::emphasis $value]
    #...
    
    # remove key(s)...
    if {[llength $value]} {
        set value [dict remove $value -lineStyle -label -itemStyle \
                                      -checkpointStyle -controlStyle \
                                      -progress -emphasis]
    }

    set options [merge $options $value]

    return $options
}
