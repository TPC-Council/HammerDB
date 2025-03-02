# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

proc ticklecharts::formatEcharts {formattype value key} {
    # Verification of certain values (especially for string types) 
    # In order to respect the values according to the Echarts documentation.
    #
    # formattype - format type of validation.
    # value      - value to be verified.
    # key        - key flag.
    #
    # Returns nothing.
    variable echarts_version

    if {$formattype eq ""} {return}
    if {$value eq "nothing" || $value eq "null"} {return}

    set nameproc [ticklecharts::getLevelProperties [expr {[info level] - 1}]]

    switch -exact -- $formattype {

        formatTarget {
            # possible values...
            set validvalue {self blank}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatTextAlign {
            # possible values...
            set validvalue {auto left right center}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                       for this key '$key' in $nameproc"
            }
        }

        formatVerticalTextAlign {
            # possible values...
            set validvalue {auto top bottom middle}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                       for this key '$key' in $nameproc"
            }
        }

        formatBarCategoryGap -
        formatBarGap {
            # possible values...
            if {![regexp {^[-0-9.]+%$} $value]} {
                error "$key ($nameproc) : The gap between bars between different series,\
                      is a percent value like '30%', which means 30% of the bar width.\
                      Set barGap as '-100%' can overlap bars that belong to different series,\
                      which is useful when making a series of bar be background."
            }
        }

        formatLeft {
            # possible values...
            lappend validvalue {^auto$|^left$|^center$|^right$}
            lappend validvalue {^[0-9.]+%$}
            lappend validvalue {^[0-9.]+$}

            set match 0
            foreach re $validvalue {
                if {[regexp $re $value]} {
                    set match 1 ; break
                }
            }

            if {!$match} {
                error "$key ($nameproc) : value can be instant pixel value like 20;\
                       it can also be a percentage value relative to container width like '20%';\
                       and it can also be 'auto', left', 'center', or 'right'"
            }
        }

        formatERight -
        formatELeft {
            # possible values...
            lappend validvalue {^left$|^center$|^right$}
            lappend validvalue {^[0-9.]+%$}
            lappend validvalue {^[0-9.]+$}

            set match 0
            foreach re $validvalue {
                if {[regexp $re $value]} {
                    set match 1 ; break
                }
            }

            if {!$match} {
                error "$key ($nameproc) : Pixel value. For example, can be a number 30, means 30px.\
                       Percent value: For example, can be a string '33%', means the final result\
                       should be calculated by this value and the height of its parent.\
                       'center': means position the element in the middle of according to its parent.\
                       Only one between left and right can work."
            }
        }

        formatETop -
        formatEBottom {
            # possible values...
            lappend validvalue {^top$|^middle$|^bottom$}
            lappend validvalue {^[0-9.]+%$}
            lappend validvalue {^[0-9.]+$}

            set match 0
            foreach re $validvalue {
                if {[regexp $re $value]} {
                    set match 1 ; break
                }
            }

            if {!$match} {
                error "$key ($nameproc) : Pixel value. For example, can be a number 30, means 30px.\
                       Percent value: For example, can be a string '33%', means the final result\
                       should be calculated by this value and the height of its parent.\
                       'middle': means position the element in the middle of according to its parent.\
                       Only one between top and bottom can work."
            }
        }

        formatTop {
            # possible values...
            lappend validvalue {^auto$|^top$|^middle$|^bottom$}
            lappend validvalue {^[0-9.]+%$}
            lappend validvalue {^[0-9.]+$}

            set match 0
            foreach re $validvalue {
                if {[regexp $re $value]} {
                    set match 1 ; break
                }
            }

            if {!$match} {
                error "$key ($nameproc) value can be instant pixel value like 20;\
                       it can also be a percentage value relative to container width like '20%';\
                       and it can also be 'auto', top', 'middle', or 'bottom'"
            }
        }

        formatBottom - 
        formatRight {
            # possible values...
            lappend validvalue {^[0-9.]+%$}
            lappend validvalue {^[0-9.]+$}

            set match 0
            foreach re $validvalue {
                if {[regexp $re $value]} {
                    set match 1 ; break
                }
            }

            if {!$match} {
                error "$key ($nameproc) value can be instant pixel value like 20;\
                       it can also be a percentage value relative to container width like '20%'."
            }
        }

        formatColor {
            set type [ticklecharts::typeOf $value]

            if {$type eq "list"} {
                if {[ticklecharts::iseListClass $value]} {
                    if {[ticklecharts::isListOfList [$value get]]} {
                        set value {*}[$value get]
                    } else {
                        set value [$value get]
                    }
                }
                foreach val {*}$value {
                    ticklecharts::formatEcharts formatColor $val $key
                }
            }
            if {$type eq "str"} {
                # possible values...
                lappend validvalue {^white$|^black$|^red$|^blue$|^green$|^transparent$|^inherit$|^source$|^gradient$}
                lappend validvalue {^#[a-zA-Z0-9]{3,6}$}
                lappend validvalue {^rgb\(\s*([0-9]+),\s*([0-9]+),\s*([0-9]+)\)$}
                lappend validvalue {^rgba\(\s*([0-9]+),\s*([0-9]+),\s*([0-9]+),\s*(?:1|0?\.[0-9]+)\)$}
                lappend validvalue {^hsl\(\s*(\d+)\s*,\s*(\d+(?:\.\d+)?%)\s*,\s*(\d+(?:\.\d+)?%)\)$}
                lappend validvalue {^auto$}

                set match 0
                foreach re $validvalue {
                    if {[regexp $re $value]} {
                        set match 1 ; break
                    }
                }

                if {!$match} {
                    error "$key ($nameproc). Color can be represented in RGB, for example 'rgb(128, 128, 128)'.\
                        RGBA can be used when you need alpha channel, for example 'rgba(128, 128, 128, 0.5)'.\
                        You may also use hexadecimal format, for example '#ccc'"
                }
            }
        }

        formatFontStyle {
            # possible values...
            set validvalue {normal italic oblique}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatFontWeight {
            # possible values...
            if {![string is double -strict $value]} {
                set validvalue {normal bold bolder lighter}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatBorderType    -
        formatCrossStyle    -
        formatLineStyleType -
        formatTextBorderType {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {inherit solid dashed dotted}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatOverflow {
            # possible values...
            set validvalue {truncate break breakAll none}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatTrigger {
            # possible values...
            set validvalue {item axis none}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatExpandTriggerOn {
            # possible values...
            set validvalue {mousemove click}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }
        formatTriggerOn {
            # possible values...
            set validvalue {mousemove click mousemove|click none}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatRenderMode {
            # possible values...
            set validvalue {html richText}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatConfine {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {inside top left right bottom}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatOrder {
            # possible values...
            set validvalue {seriesAsc seriesDesc valueAsc valueDesc}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatAxisPointerType {
            # possible values...
            set validvalue {line shadow none cross}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatAxisPointerAxis {
            # possible values...
            set validvalue {auto x y radius angle}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatAEasing {
            # possible values...
            # see https://echarts.apache.org/examples/en/editor.html?c=line-easing
            set validvalue {
                            linear quadraticIn quadraticOut quadraticInOut cubicIn
                            cubicOut cubicInOut quarticIn quarticOut quarticInOut
                            quinticIn quinticOut quinticInOut sinusoidalIn sinusoidalOut
                            sinusoidalInOut exponentialIn exponentialOut exponentialInOut
                            circularIn circularOut circularInOut elasticIn elasticOut
                            elasticInOut backIn backOut backInOut bounceIn bounceOut
                            bounceInOut
                            }
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatCap {
            # possible values...
            set validvalue {inherit butt round square}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatJoin {
            # possible values...
            set validvalue {bevel round miter}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatOpacity {
            # possible values...
            if {[string is double -strict $value]} {
                if {![expr {$value >= 0 && $value <= 1}]} {
                    error "'$value' should be between '0' and '1'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatLegendType {
            # possible values...
            set validvalue {plain scroll}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatOrient {
            # possible values...
            set validvalue {horizontal vertical}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatAlign -
        formatVisualMapAlign {
            # possible values...
            set validvalue {auto left right}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatSelectedMode {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                if {[ticklecharts::vCompare $echarts_version "5.3.0"] >= 0} {
                    set validvalue {multiple single series}
                } else {
                    set validvalue {multiple single}
                }

                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatItemSymbol {
            set type [ticklecharts::typeOf $value]

            if {$type eq "list"} {
                if {[ticklecharts::iseListClass $value]} {
                    if {[ticklecharts::isListOfList [$value get]]} {
                        set value {*}[$value get]
                    } else {
                        set value [$value get]
                    }
                }
                foreach val {*}$value {
                    ticklecharts::formatEcharts formatItemSymbol $val $key
                }
            }
            # possible values...
            if {$type eq "str"} {
                set validvalue {emptyCircle circle rect roundRect triangle diamond pin arrow none image://* path://*}
                set match 0
                foreach val $validvalue {
                    if {[string match $val $value]} {
                        set match 1 ; break
                    }
                }
                if {!$match} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatColorBy {
            # possible values...
            set validvalue {series data}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatCSYS {
            # possible values...
            set validvalue {cartesian2d polar geo}

            if {[infoNameProc 2 "themeRiverSeries"]} {
                set validvalue {single}
            }

            if {[infoNameProc 2 "parallelSeries"]} {
                set validvalue {parallel}
            }
        
            if {[infoNameProc 2 "graphSeries"]} {
                append validvalue " calendar none"
            }

            if {[infoNameProc 2 "pieSeries"]} {
                append validvalue " calendar none gmap"
            }

            if {[infoNameProc 2 "heatmapSeries"]} {
                append validvalue " calendar gmap"
            }

            if {[infoNameProc 2 "graphSeries"]} {
                lappend validvalue calendar
            }

            if {[infoNameProc 2 "scatterSeries"]} {
                append validvalue " calendar gmap"
            }

            if {[infoNameProc 2 "linesSeries"]} {
                lappend validvalue gmap
            }

            if {[infoNameProc 2 "line3DSeries"]} {
                set validvalue cartesian3D
            }

            if {[infoNameProc 2 "bar3DSeries"]} {
                set validvalue {cartesian3D geo3D globe}
            }

            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatSampling {
            # possible values...
            set validvalue {lttb average max min sum}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatPChunkMode {
            # possible values...
            set validvalue {sequential mod}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatSMonotone {
            # possible values...
            set validvalue {x y}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatStartangle {
            # possible values...
            if {![expr {$value >= 0 && $value <= 360}]} {
                error "'$value' should be between '0' and '360'\
                        for this key '$key' in $nameproc"
            }
        }

        formatEndangle {
            # possible values...
            if {![expr {$value <= 0 && $value >= -360}]} {
                error "'$value' should be between '0' and '-360'\
                        for this key '$key' in $nameproc"
            }
        }

        formatAType {
            # possible values...
            set validvalue {expansion scale}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatATypeUpdate {
            # possible values...
            set validvalue {expansion transition}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatSort {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {descending ascending none desc asc}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatFunnelAlign {
            # possible values...
            set validvalue {center left right right}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatPosition {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {
                        top left right bottom inside insideLeft insideRight insideTop
                        insideBottom insideTopLeft insideBottomLeft insideTopRight insideBottomRight
                    }

                if {[infoNameProc 2 "barSeries"] && [ticklecharts::vCompare $echarts_version "5.2.0"] >= 0} {
                    append validvalue " start insideStart middle insideEnd end"
                }

                if {[infoNameProc 2 "sunburstSeries"]} {
                    append validvalue " outside"
                }

                if {[infoNameProc 2 "pieSeries"]} {
                    set validvalue {outside inside inner center outer}
                }

                if {[infoNameProc 3 "calendar"]} {
                    set validvalue {start end}
                }

                if {[infoNameProc 3 "markLine"]} {
                    set validvalue {
                            start middle end insideStart insideStartTop insideStartBottom insideMiddle insideMiddleTop insideMiddleBottom
                            insideEnd insideEndTop insideEndBottom
                        }
                }

                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatMoveOverlap {
            # possible values...
            set validvalue {shiftX shiftY}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatBlurScope {
            # possible values...
            set validvalue {none coordinateSystem series global}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatType {
            # possible values...
            set validvalue {value category time log}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatNameLocation {
            # possible values...
            set validvalue {start middle center end}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatShape {
            # possible values...
            set validvalue {polygon circle}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatEdgeShape {
            # possible values...
            set validvalue {curve polyline}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatXAxisPosition {
            # possible values...
            set validvalue {top bottom}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatYAxisPosition {
            # possible values...
            set validvalue {left right}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatShowAllSymbol {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {auto}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatCursor {
            # possible values...
            set validvalue {
                pointer crosshair help move progress text wait e-resize
                ne-resize nw-resize n-resize se-resize sw-resize s-resize w-resize
            }
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatBounding {
            # possible values...
            set validvalue {all raw}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }
    
        formatFocus {
            # possible values...
            set validvalue {none self series ancestor descendant adjacency}

            if {[infoNameProc 2 "treeSeries"]} {
                if {[ticklecharts::vCompare $echarts_version "5.3.3"] >= 0} {
                    set validvalue {none ancestor descendant relative}
                } else {
                    set validvalue {none ancestor descendant}
                }
            }
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatShapeSmooth {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {spline}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatDivideShape {
            # possible values...
            set validvalue {split clone}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatInterval {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {auto}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatAlignTo {
            # possible values...
            set validvalue {none labelLine edge}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatRoseType {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {radius area}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatStep {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {start middle end}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatEdgeLabelPosition {
            # possible values...
            set validvalue {start middle end}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatEbrushType {
            # possible values...
            set validvalue {stroke fill}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatRenderer {
            # possible values...
            set validvalue {canvas svg}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatSaveAsImg {
            # possible values...
            set validvalue {png jpg svg}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatFilterMode {
            # possible values...
            set validvalue {filter weakFilter empty none}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatTextPosition {
            # possible values...
            set validvalue {left right top bottom}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatNodeClick {
            # possible values...
            set validvalue {rootToNode link}

            if {[infoNameProc 2 "treemapSeries"]} {
                set validvalue {link zoomToNode}
            }

            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatRotate {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {radial tangential}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            } elseif {[ticklecharts::typeOf $value] eq "num"} {
                if {![expr {$value >= -90 && $value <= 90}]} {
                    error "'$value' should be between '-90' and '90'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatLayout {
            # possible values...
            set validvalue {orthogonal radial}

            if {[infoNameProc 2 "graphSeries"]} {
                set validvalue {none circular force}
            }

            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatTreeOrient {
            # possible values...
            set validvalue {LR RL TB BT}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatEForkPosition  {
            # possible values...
            if {![regexp {^[0-9.]+%$} $value]} {
                error "'$value' should be be between\['0%', '100%'\]"
            }
        }

        formatRoam {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {scale move}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatNodeAlign {
            # possible values...
            set validvalue {left right justify}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                       for this key '$key' in $nameproc"
            }
        }

        formatMaxMin {
            # possible values...
            if {![expr {$value >= 0 && $value <= 100}]} {
                error "'$value' should be between '0' and '100'\
                        for this key '$key' in $nameproc"
            }
        }

        formatZoomMW {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {shift ctrl alt}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatTransform {
            # possible values...
            set validvalue {filter sort ecSimpleTransform:aggregate boxplot}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatDimType {
            # possible values...
            set validvalue {number float int ordinal time}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatSeriesLayout {
            # possible values...
            set validvalue {row column}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatSourceHeader {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {undefined auto}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatSymbolPosition {
            # possible values...
            set validvalue {start end center}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatSymbolRepeat {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {fixed}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatSelectorPos -
        formatsymbolRepeatDirs {
            # possible values...
            set validvalue {start end}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatBrushIndex -
        formatToolBox {
            # possible values...
            set type [ticklecharts::typeOf $value]
            set validvalue {rect polygon keep clear}

            if {$type eq "list"} {
                if {[ticklecharts::iseListClass $value]} {
                    if {[ticklecharts::isListOfList [$value get]]} {
                        set value {*}[$value get]
                    } else {
                        set value [$value get]
                    }
                }
                foreach val {*}$value {
                    if {$val ni $validvalue} {
                        error "'$value' should be '[join $validvalue "' or '"]'\
                                for this key '$key' in $nameproc"
                    }
                }
            }
        }

        formatBrushLink {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {all none}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatBrushTypes {
            # possible values...
            set validvalue {rect polygon lineX lineY}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatBrushMode {
            # possible values...
            set validvalue {single multiple}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatBrushMode {
            # possible values...
            set validvalue {debounces fixRate}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatTimelineType {
            # possible values...
            set validvalue {slider}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatTimelineAxisType {
            # possible values...
            set validvalue {time category value}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatTimelineMerge {
            set type [ticklecharts::typeOf $value]

            if {$type eq "list"} {
                if {[ticklecharts::iseListClass $value]} {
                    if {[ticklecharts::isListOfList [$value get]]} {
                        set value {*}[$value get]
                    } else {
                        set value [$value get]
                    }
                }
                foreach val {*}$value {
                    ticklecharts::formatEcharts formatTimelineMerge $val $key
                }
            }
            if {$type eq "str"} {
                # possible values...
                set validvalue {xAxis series}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatTimelinePosition {
            # possible values...
            set validvalue {left right}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatTimelineIcon {
            set validvalue {image://* path://*}
            set match 0
            foreach val $validvalue {
                if {[string match $val $value]} {
                    set match 1 ; break
                }
            }
            if {!$match} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatWCshape {
            # possible values...
            set validvalue {circle cardioid diamond triangle-forward triangle
                            pentagon triangle-upright star square}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatDataBox {
            foreach val $value {
                if {[llength $val] != 5} {
                    error "'val' should be a list of 5 elements :\[min,  Q1,  median (or Q2),  Q3,  max\]"
                }
            }
        }

        formatColorMapping {
            # possible values...
            set validvalue {value index id}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatStackStrategy {
            # possible values...
            set validvalue {samesign all positive negative}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatAreaStyleOrigin {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {auto start end}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatBRadius {
            # possible values...
            set type [ticklecharts::typeOf $value]

            if {$type eq "list"} {
                if {[ticklecharts::iseListClass $value]} {
                    if {[ticklecharts::isListOfList [$value get]]} {
                        set value {*}[$value get]
                    } else {
                        set value [$value get]
                    }
                }
                if {[ticklecharts::vCompare $echarts_version "5.3.0"] < 0} {
                    set len [llength {*}$value]
                    if {$len != 2} {
                        error "length of list should be equal to 2."
                    }
                }
                if {[ticklecharts::vCompare $echarts_version "5.3.0"] >= 0} {
                    set len [llength {*}$value]
                    if {![expr {$len == 2 || $len == 4}]} {
                        error "length of list should be equal to 2 or 4"
                    }
                }
            }
        }

        formatSEffectOn {
            # possible values...
            set validvalue {render emphasis}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatGaugeALrotate {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {radial tangential}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
            if {[ticklecharts::typeOf $value] eq "num"} {
                if {![expr {$value >= -90 && $value <= 90}]} {
                    error "'$value' should be between '-90' and '90'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatAPStatus {
            # possible values...
            set validvalue {show hide}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatTypeScatter {
            # possible values...
            set validvalue {scatter effectScatter}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatNameMap {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                if {[ticklecharts::vCompare $echarts_version "5.2.2"] >= 0} {
                    if {[string toupper $value] ne $value} {
                        error "Case sensitive is not respected for '$value'"
                    }
                }
                if {[ticklecharts::vCompare $echarts_version "5.2.2"] < 0} {
                    if {[string tolower $value] ne $value} {
                        error "Case sensitive is not respected for '$value'"
                    }
                }
            }
        }

        formatTypeColor {
            # possible values...
            set validvalue {linear radial}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatColorRepeat {
            # possible values...
            set validvalue {repeat-x repeat-y no-repeat repeat}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatBevelSize -
        formatRangeTrailLength - 
        formatRangeSymbolSize {
            # possible values...
            if {![expr {$value >= 0 && $value <= 1}]} {
                error "'$value' should be between '0' and '1'\
                        for this key '$key' in $nameproc"
            }
        }

        formatRangeRotation {
            # possible values... (in radians)
            if {![expr {$value >= -3.141592 && $value <= 3.141592}]} {
                error "'$value' should be between '-Pi()' and 'Pi()'\
                        for this key '$key' in $nameproc"
            }
        }

        formatMapTypeID {
            # possible values...
            if {[ticklecharts::typeOf $value] eq "str"} {
                set validvalue {roadmap satellite hybrid terrain}
                if {$value ni $validvalue} {
                    error "'$value' should be '[join $validvalue "' or '"]'\
                            for this key '$key' in $nameproc"
                }
            }
        }

        formatBlendM {
            # possible values...
            set validvalue {source-over lighter}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatSSAOQuality -
        formatShadowQuality {
            # possible values...
            set validvalue {low medium high ultra}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatProjection3D {
            # possible values...
            set validvalue {perspective orthogonal orthographic}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatDirection3D {
            # possible values...
            set validvalue {cw ccw}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatMouseButton {
            # possible values...
            set validvalue {left middle right}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }

        formatShading3D {
            # possible values...
            set validvalue {color lambert realistic}
            if {$value ni $validvalue} {
                error "'$value' should be '[join $validvalue "' or '"]'\
                        for this key '$key' in $nameproc"
            }
        }
    }

    return {}
}