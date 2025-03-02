# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

oo::class create ticklecharts::chart {
    variable _echartshchart           ; # huddle
    variable _options                 ; # list options chart
    variable _opts_global             ; # list global options chart
    variable _dataset                 ; # dataset chart
    variable _indexlineseries         ; # index line series
    variable _indexbarseries          ; # index bar series
    variable _indexpieseries          ; # index pie series
    variable _indexfunnelseries       ; # index funnel series
    variable _indexradarseries        ; # index radar series
    variable _indexscatterseries      ; # index scatter series
    variable _indexheatmapseries      ; # index heatmap series
    variable _indexsunburstseries     ; # index sunburst series
    variable _indextreeseries         ; # index tree series
    variable _indexthemeriverseries   ; # index themeriver series
    variable _indexsankeyseries       ; # index sankey series
    variable _indexpictorialbarseries ; # index pictorialbar series
    variable _indexcandlestickseries  ; # index candlestick series
    variable _indexparallelseries     ; # index parallel series
    variable _indexgaugeseries        ; # index gauge series
    variable _indexgraphseries        ; # index graph series
    variable _indexwordCloudseries    ; # index wordCloud series
    variable _indexboxplotseries      ; # index boxplot series
    variable _indextreemapseries      ; # index treemap series
    variable _indexmapseries          ; # index map series
    variable _indexlinesseries        ; # index lines series

    constructor {args} {
        # Initializes a new Chart Class.
        #
        # args - Options described below.
        #
        # -theme  - name theme see : theme.tcl
        #
        ticklecharts::setTheme $args ; # theme options
        set _opts_global {}
        set _options     {}
        set _dataset     {}
        
        # Guess if current script has a 'Gridlayout' dataset.
        if {[ticklecharts::gridlayoutHasDataSetObj dataset]} {
            set _dataset $dataset
        }

        # shared _index* variable for chart class...
        if {[info exists ::argv0] && ([info script] eq "$::argv0")} {
            set ns [info object namespace [self class]]
            foreach var [info vars _index*] {
                my eval [list namespace upvar $ns $var $var]
            }
        }
    }
}

oo::define ticklecharts::chart {

    method get {} {
        # Gets huddle object
        return $_echartshchart
    }

    method options {} {
        # Gets chart list options
        return $_options
    }

    method globalOptions {} {
        # Returns if global options is present.
        return $_opts_global
    }

    method getType {} {
        # Gets type class
        return "chart"
    }

    method dataset {} {
        # Returns if chart instance 
        # includes dataset
        return $_dataset
    }
    
    method isMixed {} {
        # Check if series options there is severals types (line, bar...)
        #
        # Returns true if severals types, otherwise false.
        set ktype {}
    
        foreach {key opts} $_options {
            if {[string match {*series} $key]} {
                if {[dict exists $opts @S=type]} {
                    lappend ktype [dict get $opts @S=type]
                }
            }
        }
        return [expr {([llength $ktype] > 1) ? 1 : 0}]
    }

    method getOptions {args} {
        # args - Options described below.
        #
        # -series  - name of series
        # -option  - name of option
        # -axis    - name of axis
        #
        # Returns default and options type according to a key (name of procedure)
        # to stdout.

        set methodClass [info class methods ticklecharts::chart]

        foreach {key value} $args {
            switch -exact -- $key {
                "-series" {
                    set methods [lsearch -all -inline -nocase $methodClass *series*]
                    lappend methods [lsearch -all -inline -nocase $methodClass *graphic*]
                }
                "-option" {
                    set methods {SetOptions}
                }
                "-globalOptions" {
                    # no value required...
                    return [ticklecharts::infoOptions "globalOptions"]
                }
                "-axis" {
                    set methods [lsearch -all -inline -nocase $methodClass *axis*]
                    lappend methods [lsearch -all -inline -nocase $methodClass *coordinate*]
                }
                default {error "Unknown key '$key' specified"}
            }

            if {$value eq ""} {
                error "A value should be specified..."
            }

            set info $value
        }

        foreach method $methods {
            if {[catch {info class definition ticklecharts::chart $method} infomethod]} {continue}
            foreach linebody [split $infomethod "\n"] {
                set linebody [string map [list \{ "" \} "" \] "" \[ ""] $linebody]
                set linebody [string trim $linebody]
                if {[string match -nocase "*ticklecharts::*$info*" $linebody]} {
                    if {[regexp {ticklecharts::([A-Za-z]+)\s} $linebody -> match]} {
                        return [ticklecharts::infoOptions $match]
                    }
                }
            }
        }
    }

    method keys {} {
        # Returns keys without type.
        set k {}
        foreach {key opts} $_options {
            lappend k [lindex [split $key "="] 1]
        }

        return $k
    }

    method deleteSeries {index} {
        # Delete series by index.
        #
        # Returns nothing
        set i -1 ; set j 0 ; set k 0
        foreach {key opts} $_options {
            if {[string match {*series} $key]} {
                if {[incr i] == $index} {
                    set k 1 ; break
                }
            }
            incr j 2
        }

        if {$k} {set _options [lreplace $_options $j [expr {$j + 1}]]}

        return {}
    }

    method chartToHuddle {} {
        # Transform list to ehudlle
        #
        # Returns nothing

        set opts $_options

        # If globalOptions is not present, add first...
        if {![llength [my globalOptions]]} {
            set optsg  [ticklecharts::globalOptions {}]
            set optsEH [ticklecharts::optsToEchartsHuddle [$optsg get]]
            set opts   [linsert $opts 0 {*}$optsEH]
        }

        set mixed [my isMixed]

        # init ehuddle.
        set _echartshchart [ticklecharts::ehuddle new]
        
        foreach {key value} $opts {

            if {[string match {*series} $key]} {
                $_echartshchart append $key $value
            } elseif {[string match {*dataZoom} $key]} {
                $_echartshchart append $key $value
            } elseif {[string match {*calendar} $key]} {
                $_echartshchart append $key $value
            } elseif {[string match {*visualMap} $key]} {
                $_echartshchart append $key $value
            } elseif {[string match {*parallelAxis} $key]} {
                $_echartshchart append $key $value
            } elseif {[string match {*dataset} $key]} {
                $_echartshchart append $key $value
            } elseif {[regexp {xAxis|yAxis|radar} $key] && $mixed} {
                $_echartshchart append $key $value
            } else {
                $_echartshchart set $key $value
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

        my chartToHuddle ; # transform to huddle
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
    
    method RenderX {args} {
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
        # -jsecharts  - full path echarts.min.js (by default cdn script)
        # -jsvar      - name js var
        # -script     - list data (jsfunc), jsfunc.
        # -class      - container.
        # -style      - css style.
        #
        # Returns full path html file.

        my chartToHuddle ; # transform to huddle
        set myhuddle [my get]
        set json     [$myhuddle toJSON] ; # jsondump

        set opts_html  [ticklecharts::htmlOptions $args]
        set newhtml    [ticklecharts::htmlMap $myhuddle $opts_html]
        set jsvar      [lindex [dict get $opts_html -jsvar] 0]

        set  html [string map [list %json% "var $jsvar = $json"] $newhtml]
        return $html
    }

    method toJSON {} {
        # Returns json chart data.
        my chartToHuddle ; # transform to huddle
        
        # ehuddle jsondump
        return [[my get] toJSON]
    }

    method Xaxis {args} {
        # Init X axis chart
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -axis X
        # or
        # from doc : https://echarts.apache.org/en/option.html#xAxis
        #
        # Returns nothing
        set mykeys [my keys]

        if {"radiusAxis" in $mykeys || "angleAxis" in $mykeys} {
            error "radiusAxis or angleAxis not supported with 'Xaxis'"
        }
    
        set options [ticklecharts::xAxis [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]
        
        lappend _options @D=xAxis [list {*}$f]

        return {}
    }

    method Yaxis {args} {
        # Init Y axis chart
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -axis Y
        # or
        # from doc : https://echarts.apache.org/en/option.html#yAxis
        #
        # Returns nothing
        set mykeys [my keys]

        if {"radiusAxis" in $mykeys || "angleAxis" in $mykeys} {
            error "radiusAxis or angleAxis not supported with 'Yaxis'"
        }
    
        set options [ticklecharts::yAxis [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]
        
        lappend _options @D=yAxis [list {*}$f]

        return {}        
    }
    
    method RadiusAxis {args} {
        # Init Radius axis chart (available only for polar chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -axis Radius
        # or
        # from doc : https://echarts.apache.org/en/option.html#radiusAxis
        #
        # Returns nothing    
        set mykeys [my keys]
    
        if {"xAxis" in $mykeys || "yAxis" in $mykeys} {
            error "xAxis or yAxis not supported with 'radiusAxis'"
        }
        
        set options [ticklecharts::radiusAxis $args]
        set f [ticklecharts::optsToEchartsHuddle $options]
        
        lappend _options @L=radiusAxis [list {*}$f]

        return {}
    }
    
    method AngleAxis {args} {
        # Init Angle axis chart (available only for polar chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -axis Angle
        # or
        # from doc : https://echarts.apache.org/en/option.html#angleAxis
        #
        # Returns nothing      
        set mykeys [my keys]
    
        if {"xAxis" in $mykeys || "yAxis" in $mykeys} {
            error "xAxis or yAxis not supported with 'angleAxis'"
        }
        
        set options [ticklecharts::angleAxis $args]
        set f [ticklecharts::optsToEchartsHuddle $options]
        
        lappend _options @L=angleAxis [list {*}$f]

        return {}
    }

    method AddGraphic {args} {
        # Add elements (text, rect, circle...) to chart
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -serie Graphic
        # or
        # from doc : https://echarts.apache.org/en/option.html#graphic
        #
        # Returns nothing      
        
        set options [ticklecharts::setGraphic $args]
        set f [ticklecharts::optsToEchartsHuddle $options]
        
        lappend _options @L=graphic [list {*}$f]

        return {}
    }

    method RadarCoordinate {args} {
        # Init Radar coordinate (available only for radar chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -axis RadarCoordinate
        # or
        # from doc : https://echarts.apache.org/en/option.html#radar
        #
        # Returns nothing      
        set mykeys [my keys]
    
        if {"xAxis" in $mykeys || "yAxis" in $mykeys} {
            error "xAxis or yAxis not supported with 'Radar coordinate'"
        }
        
        set options [ticklecharts::radarCoordinate $args]
        set f [ticklecharts::optsToEchartsHuddle $options]
        
        lappend _options @D=radar [list {*}$f]

        return {}
    }

    method SingleAxis {args} {
        # Init singleAxis
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -axis Single
        # or
        # from doc : https://echarts.apache.org/en/option.html#singleAxis
        #
        # Returns nothing      
        set mykeys [my keys]
    
        if {"xAxis" in $mykeys || "yAxis" in $mykeys} {
            error "xAxis or yAxis not supported with 'SingleAxis'"
        }
        
        set options [ticklecharts::singleAxis $args]
        set f [ticklecharts::optsToEchartsHuddle $options]
        
        lappend _options @D=singleAxis [list {*}$f]

        return {}
    }

    method ParallelAxis {args} {
        # Init ParallelAxis (available only for parallel chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -axis Parallel
        # or
        # from doc : https://echarts.apache.org/en/option.html#parallelAxis
        #
        # Returns nothing    
        set mykeys [my keys]
    
        if {"xAxis" in $mykeys || "yAxis" in $mykeys} {
            error "xAxis or yAxis not supported with 'parallelAxis'"
        }
        
        set options [ticklecharts::parallelAxis $args]
        foreach axis $options {
            set f [ticklecharts::optsToEchartsHuddle $axis]
            lappend _options @D=parallelAxis [list {*}$f]
        }

        return {}
    }

    method AddBarSeries {args} {
        # Add data series chart (use only for bar chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series bar
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-bar
        #
        # Returns nothing      
        incr _indexbarseries

        set options [ticklecharts::barSeries $_indexbarseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }
    
    method AddLineSeries {args} {
        # Add data series chart (use only for line chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series line
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-line
        #
        # Returns nothing     
        incr _indexlineseries

        set options [ticklecharts::lineSeries $_indexlineseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddPieSeries {args} {
        # Add data series chart (use only for pie chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series pie
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-pie
        #
        # Returns nothing     
        incr _indexpieseries

        set options [ticklecharts::pieSeries $_indexpieseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddFunnelSeries {args} {
        # Add data series chart (use only for funnel chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series funnel
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-funnel
        #
        # Returns nothing     
        incr _indexfunnelseries

        set options [ticklecharts::funnelSeries $_indexfunnelseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddRadarSeries {args} {
        # Add data series chart (use only for radar chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series radar
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-radar
        #
        # Returns nothing     
        incr _indexradarseries

        set options [ticklecharts::radarSeries $_indexradarseries $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }
    
    method AddScatterSeries {args} {
        # Add data series chart (use only for scatter chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series scatter
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-scatter
        #
        # Returns nothing     
        incr _indexscatterseries

        set options [ticklecharts::scatterSeries $_indexscatterseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddHeatmapSeries {args} {
        # Add data series chart (use only for heatmap chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series heatmap
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-heatmap
        #
        # Returns nothing     
        incr _indexheatmapseries

        set options [ticklecharts::heatmapSeries $_indexheatmapseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddSunburstSeries {args} {
        # Add data series chart (use only for sunburst chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series sunburst
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-sunburst
        #
        # Returns nothing     
        incr _indexsunburstseries

        set options [ticklecharts::sunburstSeries $_indexsunburstseries $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddTreeSeries {args} {
        # Add data series chart (use only for tree chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series tree
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-tree
        #
        # Returns nothing     
        incr _indextreeseries

        set options [ticklecharts::treeSeries $_indextreeseries $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddThemeRiverSeries {args} {
        # Add data series chart (use only for themeRiver chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series themeRiver
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-themeriver
        #
        # Returns nothing     
        incr _indexthemeriverseries

        set options [ticklecharts::themeRiverSeries $_indexthemeriverseries $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddSankeySeries {args} {
        # Add data series chart (use only for Sankey chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series sankey
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-sankey
        #
        # Returns nothing     
        incr _indexsankeyseries

        set options [ticklecharts::sankeySeries $_indexsankeyseries $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddPictorialBarSeries {args} {
        # Add data series chart (use only for pictorialBar chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series pictorialBar
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-pictorialBar
        #
        # Returns nothing     
        incr _indexpictorialbarseries

        set options [ticklecharts::pictorialBarSeries $_indexpictorialbarseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddCandlestickSeries {args} {
        # Add data series chart (use only for candlestick chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series candlestick
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-candlesticks
        #
        # Returns nothing     
        incr _indexcandlestickseries

        set options [ticklecharts::candlestickSeries $_indexcandlestickseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddParallelSeries {args} {
        # Add data series chart (use only for parallel chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series parallel
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-parallel
        #
        # Returns nothing     
        incr _indexparallelseries

        set options [ticklecharts::parallelSeries $_indexparallelseries $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddGaugeSeries {args} {
        # Add data series chart (use only for gauge chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series gauge
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-gauge
        #
        # Returns nothing     
        incr _indexgaugeseries

        set options [ticklecharts::gaugeSeries $_indexgaugeseries $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddGraphSeries {args} {
        # Add data series chart (use only for graph chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series graph
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-graph
        #
        # Returns nothing     
        incr _indexgraphseries

        set options [ticklecharts::graphSeries $_indexgraphseries $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddWordCloudSeries {args} {
        # Add data series chart (use only for wordCloud chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series wordcloud
        # or
        # from doc : https://github.com/ecomfe/echarts-wordcloud
        #
        # Returns nothing     
        incr _indexwordCloudseries

        set options [ticklecharts::wordcloudSeries $_indexwordCloudseries $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddBoxPlotSeries {args} {
        # Add data series chart (use only for boxplot chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series boxplot
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-boxplot
        #
        # Returns nothing     
        incr _indexboxplotseries

        set options [ticklecharts::boxplotSeries $_indexboxplotseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddTreeMapSeries {args} {
        # Add data series chart (use only for treemap chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series treemap
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-treemap
        #
        # Returns nothing     
        incr _indextreemapseries

        set options [ticklecharts::treemapSeries $_indextreemapseries $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddMapSeries {args} {
        # Add data series chart (use only for map chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series map
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-map
        #
        # Returns nothing     
        incr _indexmapseries

        set options [ticklecharts::mapSeries $_indexmapseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }

    method AddLinesSeries {args} {
        # Add data series chart (use only for lines chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series lines
        # or
        # from doc : https://echarts.apache.org/en/option.html#series-lines
        #
        # Returns nothing     
        incr _indexlinesseries

        set options [ticklecharts::linesSeries $_indexlinesseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options @D=series [list {*}$f]

        return {}
    }
    
    method SetOptions {args} {
        # Add options chart (available for all charts)
        #
        # gets default option values e.g : [self] getOptions -option toolbox
        #
        # args - Options described below.
        # 
        # Global options :
        # -darkMode                - https://echarts.apache.org/en/option.html#darkMode
        # -backgroundColor         - https://echarts.apache.org/en/option.html#backgroundColor
        # -backgroundColorItem     - https://echarts.apache.org/en/option.html#color
        # -color                   - https://echarts.apache.org/en/option.html#color
        # -animation               - https://echarts.apache.org/en/option.html#animation
        # -animationDuration       - https://echarts.apache.org/en/option.html#animationDuration
        # -animationDurationUpdate - https://echarts.apache.org/en/option.html#animationDurationUpdate
        # -animationDelayUpdate    - https://echarts.apache.org/en/option.html#animationDelayUpdate
        # -animationEasing         - https://echarts.apache.org/en/option.html#animationEasing
        # -animationEasingUpdate   - https://echarts.apache.org/en/option.html#animationEasingUpdate
        # -animationThreshold      - https://echarts.apache.org/en/option.html#animationThreshold
        # -progressiveThreshold    - https://echarts.apache.org/en/option.html#progressiveThreshold
        # -hoverLayerThreshold     - https://echarts.apache.org/en/option.html#hoverLayerThreshold
        # -useUTC                  - https://echarts.apache.org/en/option.html#useUTC
        # -blendMode               - https://echarts.apache.org/en/option.html#blendMode
        # Options :
        # -dataset                 - https://echarts.apache.org/en/option.html#dataset
        # -title                   - https://echarts.apache.org/en/option.html#title
        # -polar                   - https://echarts.apache.org/en/option.html#polar
        # -legend                  - https://echarts.apache.org/en/option.html#legend
        # -tooltip                 - https://echarts.apache.org/en/option.html#tooltip
        # -grid                    - https://echarts.apache.org/en/option.html#grid
        # -visualMap               - https://echarts.apache.org/en/option.html#visualMap
        # -toolbox                 - https://echarts.apache.org/en/option.html#toolbox
        # -dataZoom                - https://echarts.apache.org/en/option.html#dataZoom
        # -parallel                - https://echarts.apache.org/en/option.html#parallel
        # -brush                   - https://echarts.apache.org/en/option.html#brush
        # -axisPointer             - https://echarts.apache.org/en/option.html#axisPointer
        # -geo                     - https://echarts.apache.org/en/option.html#geo
        # -calendar                - https://echarts.apache.org/en/option.html#calendar
        # -aria                    - https://echarts.apache.org/en/option.html#aria
        # -gmap                    - https://github.com/plainheart/echarts-extension-gmap
        #
        # Returns nothing    
        set opts {}

        if {[dict exists $args -dataset]} {
            set dts [dict get $args -dataset]
            if {![ticklecharts::isAObject $dts] || [$dts getType] ne "dataset"} {
                error "key value -dataset should be a 'dataset' Class..."
            }

            foreach itemD [$dts get] {
                lappend opts "@D=dataset" [new edict $itemD]
            }

            # set dataset chart instance.
            set _dataset $dts
        }
    
        if {[dict exists $args -title]} {
            lappend opts "@D=title" [ticklecharts::title $args]
        }
        
        if {[dict exists $args -polar]} {
            lappend opts "@L=polar" [ticklecharts::polar $args]
        }
        
        if {[dict exists $args -legend]} {
            lappend opts "@D=legend" [ticklecharts::legend $args]
        }
        
        if {[dict exists $args -tooltip]} {
            lappend opts "@D=tooltip" [ticklecharts::tooltip $args]
        }

        if {[dict exists $args -grid]} {
            lappend opts "@D=grid" [ticklecharts::grid $args]
        }
        
        if {[dict exists $args -visualMap]} {
            # v2.8.1
            # keep compatibility with previous versions...
            # 'visualMap' now accepts 'multiple' lists or 'one' like before...
            set key "-visualMap"
            if {![ticklecharts::keyValueIsListOfList $args $key]} {
                dict set args $key [list [dict get $args $key]]
            }
            foreach mapValue [dict get $args $key] {
                lappend opts "@D=visualMap" [ticklecharts::visualMap [list $key $mapValue]]
            }
        }

        if {[dict exists $args -toolbox]} {
            lappend opts "@L=toolbox" [ticklecharts::toolbox $args]
        }

        if {[dict exists $args -dataZoom]} {
            # v3.0.1
            # keep compatibility with previous versions...
            # 'dataZoom' now accepts 'one' list or 'multiple' lists like before...
            set key "-dataZoom"
            if {![ticklecharts::keyValueIsListOfList $args $key]} {
                dict set args $key [list [dict get $args $key]]
            }
            foreach itemZ [dict get $args $key] {
                lappend opts "@D=dataZoom" [ticklecharts::dataZoom [list $key $itemZ]]
            }
        }

        if {[dict exists $args -parallel]} {
            lappend opts "@D=parallel" [ticklecharts::parallel $args]
        }

        if {[dict exists $args -brush]} {
            lappend opts "@L=brush" [ticklecharts::brush $args]
        }
    
        if {[dict exists $args -axisPointer]} {
            lappend opts "@L=axisPointer" [ticklecharts::axisPointerGlobal $args]
        }

        if {[dict exists $args -geo]} {
            lappend opts "@L=geo" [ticklecharts::geo $args]
        }

        if {[dict exists $args -calendar]} {
            set key "-calendar"
            if {![ticklecharts::keyValueIsListOfList $args $key]} {
                dict set args $key [list [dict get $args $key]]
            }
            foreach cValue [dict get $args $key] {
                lappend opts "@D=calendar" [ticklecharts::calendar [list $key $cValue]]
            }
        }

        if {[dict exists $args -aria]} {
            lappend opts "@L=aria" [ticklecharts::aria $args]
        }

        if {[dict exists $args -gmap]} {
            lappend opts "@L=gmap" [ticklecharts::gmap $args]
        }

        # delete keys from args to avoid warning for global options
        set keyopts [lmap k [dict keys $opts] {lassign [split $k "="] _ key ; format -%s $key}]
        set args [dict remove $args {*}$keyopts]
        # Adds global options first 
        if {![llength $_opts_global]} {
            set optsg        [ticklecharts::globalOptions $args]
            set _opts_global [ticklecharts::optsToEchartsHuddle [$optsg get]]
            lappend _options {*}$_opts_global
        }

        foreach {key value} $opts {
            if {![ticklecharts::isAObject $value]} {
                error "should be an object... eDict or eList"
            }
            set f [ticklecharts::optsToEchartsHuddle [$value get]]
            lappend _options $key [list {*}$f]
        }

        return {}
    }

    # export method
    export AddBarSeries AddLineSeries AddPieSeries AddFunnelSeries AddRadarSeries AddScatterSeries \
           AddHeatmapSeries AddGraphic AddSunburstSeries AddTreeSeries AddThemeRiverSeries AddSankeySeries \
           Xaxis Yaxis RadiusAxis RadarCoordinate AngleAxis SetOptions SingleAxis Render RenderX AddPictorialBarSeries \
           AddCandlestickSeries AddParallelSeries ParallelAxis AddGaugeSeries AddGraphSeries AddWordCloudSeries \
           AddBoxPlotSeries AddTreeMapSeries AddMapSeries AddLinesSeries
}
