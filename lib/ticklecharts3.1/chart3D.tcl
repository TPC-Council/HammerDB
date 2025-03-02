# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

oo::class create ticklecharts::chart3D {
    variable _echartshchart3D         ; # huddle
    variable _options3D               ; # list options chart3D
    variable _opts3D_global           ; # list global options chart
    variable _dataset                 ; # dataset chart3D
    variable _indexline3Dseries       ; # index line3D series
    variable _indexbar3Dseries        ; # index bar3D series
    variable _indexsurfaceseries      ; # index surface series

    constructor {args} {
        # Initializes a new chart3D Class.
        #
        # args - Options described below.
        #
        # -theme  - name theme see : theme.tcl
        #
        ticklecharts::setTheme $args ; # theme options
        set _opts3D_global {}
        set _options3D     {}
        set _dataset       {}
    }
}

oo::define ticklecharts::chart3D {

    method get {} {
        # Gets huddle object
        return $_echartshchart3D
    }

    method options {} {
        # Gets chart3D list options
        return $_options3D
    }

    method globalOptions {} {
        # Returns if global options is present.
        return $_opts3D_global
    }

    method getType {} {
        # Gets type class
        return "chart3D"
    }

    method dataset {} {
        # Returns if chart3D instance 
        # includes dataset
        return $_dataset
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

        set methodClass [info class methods ticklecharts::chart3D]

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
                    return [ticklecharts::infoOptions "globalOptions3D"]
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
            if {[catch {info class definition ticklecharts::chart3D $method} infomethod]} {continue}
            foreach linebody [split $infomethod "\n"] {
                set linebody [string map [list \{ "" \} "" \] "" \[ ""] $linebody]
                set linebody [string trim $linebody]
                if {[string match -nocase "*ticklecharts::*$info*" $linebody]} {
                    if {[regexp {ticklecharts::([A-Za-z0-9]+)\s} $linebody -> match]} {
                        return [ticklecharts::infoOptions $match]
                    }
                }
            }
        }
    }

    method keys {} {
        # Returns keys without type.
        set k {}
        foreach {key opts} $_options3D {
            lappend k [lindex [split $key "="] 1]
        }

        return $k
    }

    method chart3DToHuddle {} {
        # Transform list to ehudlle
        #
        # Returns nothing

        # init ehuddle.

        set opts $_options3D

        # If globalOptions is not present, add first...
        if {![llength [my globalOptions]]} {
            set optsg  [ticklecharts::globalOptions3D {}]
            set optsEH [ticklecharts::optsToEchartsHuddle [$optsg get]]
            set opts   [linsert $opts 0 {*}$optsEH]
        }

        # init ehuddle.
        set _echartshchart3D [ticklecharts::ehuddle new]
        
        foreach {key value} $opts {

            if {[string match {*series} $key]} {
                $_echartshchart3D append $key $value
            } elseif {[string match {*dataZoom} $key]} {
                $_echartshchart3D append $key $value
            } elseif {[string match {*visualMap} $key]} {
                $_echartshchart3D append $key $value
            } elseif {[string match {*dataset} $key]} {
                $_echartshchart3D append $key $value
            } else {
                $_echartshchart3D set $key $value
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
        
        set opts_html [ticklecharts::htmlOptions $args]
        my chart3DToHuddle ; # transform to huddle
        set myhuddle [my get]
        set json     [$myhuddle toJSON] ; # jsondump

        set newhtml    [ticklecharts::htmlMap $myhuddle $opts_html]
        set outputfile [lindex [dict get $opts_html -outfile] 0]
        set jsvar      [lindex [dict get $opts_html -jsvar] 0]

        set fp [open $outputfile w+]
        puts $fp [string map [list %json% "var $jsvar = $json"] $newhtml]
        close $fp
        
        if {$::ticklecharts::htmlstdout} {
            puts [format {html:%s} $outputfile]
        }

        return $outputfile
    }

    method toJSON {} {
        # Returns json chart data.
        my chart3DToHuddle ; # transform to huddle
        
        # ehuddle jsondump
        return [[my get] toJSON]
    }

    method Xaxis3D {args} {
        # Init X axis chart3D
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -axis X
        # or
        # from doc : https://echarts.apache.org/en/option-gl.html#xAxis3D
        #
        # Returns nothing
    
        set options [ticklecharts::xAxis3D $args]
        set f [ticklecharts::optsToEchartsHuddle $options]
        
        lappend _options3D @D=xAxis3D [list {*}$f]

        return {}
    }

    method Yaxis3D {args} {
        # Init Y axis chart3D
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -axis Y
        # or
        # from doc : https://echarts.apache.org/en/option-gl.html#yAxis3D
        #
        # Returns nothing
    
        set options [ticklecharts::yAxis3D $args]
        set f [ticklecharts::optsToEchartsHuddle $options]
        
        lappend _options3D @D=yAxis3D [list {*}$f]

        return {}
    }

    method Zaxis3D {args} {
        # Init Z axis chart3D
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -axis Z
        # or
        # from doc : https://echarts.apache.org/en/option-gl.html#zAxis3D
        #
        # Returns nothing
    
        set options [ticklecharts::zAxis3D $args]
        set f [ticklecharts::optsToEchartsHuddle $options]
        
        lappend _options3D @D=zAxis3D [list {*}$f]

        return {}
    }

    method AddLine3DSeries {args} {
        # Add data series chart (use only for line3D chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series line
        # or
        # from doc : https://echarts.apache.org/en/option-gl.html#series-line3D
        #
        # Returns nothing     
        incr _indexline3Dseries

        set options [ticklecharts::line3DSeries $_indexline3Dseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options3D @D=series [list {*}$f]

        return {}
    }

    method AddBar3DSeries {args} {
        # Add data series chart (use only for bar3D chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series bar
        # or
        # from doc : https://echarts.apache.org/en/option-gl.html#series-bar3D
        #
        # Returns nothing     
        incr _indexbar3Dseries

        set options [ticklecharts::bar3DSeries $_indexbar3Dseries [self] $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options3D @D=series [list {*}$f]

        return {}
    }

    method AddSurfaceSeries {args} {
        # Add data series chart (use only for surface chart)
        #
        # args - Options described below.
        #
        # gets default option values : [self] getOptions -series surface
        # or
        # from doc : https://echarts.apache.org/en/option-gl.html#series-surface
        #
        # Returns nothing     
        incr _indexsurfaceseries

        set options [ticklecharts::surfaceSeries $_indexsurfaceseries $args]
        set f [ticklecharts::optsToEchartsHuddle $options]

        lappend _options3D @D=series [list {*}$f]

        return {}
    }

    method SetOptions {args} {
        # Add options chart3D (available for all charts 3D)
        #
        # gets default option values e.g : [self] getOptions -option toolbox
        #
        # args - Options described below.
        #
        # -grid3D        - grid3D options      https://echarts.apache.org/en/option-gl.html#grid3D
        #
        # Returns nothing    
        set opts {}

        # Set options from chart '2D' class...
        set c [ticklecharts::chart new]

        # remove options 3D even if this option is not present.
        set args2D [dict remove $args "-grid3D"]
        $c SetOptions {*}$args2D

        # get base keys
        set optsg [ticklecharts::globalOptions {}]
        set g2Dopts [string map {- ""} [dict keys [$optsg get]]]
        set key2d {}
        
        foreach {key info} [$c options] {
            lassign [split $key "="] _ k
            if {$k in $g2Dopts} {continue}
            lappend _options3D $key $info
            lappend key2d $key ;  # add keys 2D
        }

        if {[$c dataset] ne ""} {
            set _dataset [$c dataset]
        }

        $c destroy

        if {[dict exists $args -grid3D]} {
            lappend opts "@D=grid3D" [ticklecharts::grid3D $args]
        }

        # delete keys from args to avoid warning for global options
        set keyList [list {*}[dict keys $opts] {*}$key2d]
        set keyopts [lmap k $keyList {lassign [split $k "="] _ key ; format -%s $key}]
        set newDict [dict remove $args {*}$keyopts]
        # Adds global 3D options first
        if {![llength $_opts3D_global]} {
            set optsg          [ticklecharts::globalOptions3D $newDict]
            set _opts3D_global [ticklecharts::optsToEchartsHuddle [$optsg get]]
            set _options3D     [linsert $_options3D 0 {*}$_opts3D_global]
        }

        foreach {key value} $opts {
            if {![ticklecharts::isAObject $value]} {
                error "should be an object... eDict or eList"
            }
            set f [ticklecharts::optsToEchartsHuddle [$value get]]
            lappend _options3D $key [list {*}$f]
        }

        return {}
    }

    # export method
    export AddLine3DSeries AddBar3DSeries AddSurfaceSeries \
           Xaxis3D Yaxis3D Zaxis3D SetOptions Render

}