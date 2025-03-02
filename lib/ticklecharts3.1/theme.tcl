# Copyright (c) 2022-2023 Nicolas ROBERT.
# Distributed under MIT license. Please see LICENSE for details.
#
namespace eval ticklecharts {}

proc ticklecharts::setTheme {value} {
    # Set default value for theme. (https://echarts.apache.org/en/theme-builder.html)
    # An error exception is raised if name of theme is not found
    # 
    # value - dict
    #
    # set global theme ticklecharts
    variable theme
    variable opts_theme

    if {[dict exists $value -theme]} {
        set theme [dict get $value -theme]
    }

    set opts_theme [dict create]
    
    switch -exact -- $theme {
        dark {
            set contrastColor   "#B9B8CE"
            set backgroundColor "#100C2A"
            set colorPalette    [list {#4992ff #7cffb2 #fddd60 #ff6e76 #58d9f9 #05c091 #ff8a45 #8d48e3 #dd79ff}]
            
            dict set opts_theme darkMode                                        "True"
            dict set opts_theme color                                           $colorPalette
            dict set opts_theme backgroundColor                                 $backgroundColor
                                                       
            dict set opts_theme tooltip.axisPointer.lineStyle.color             "nothing"
            dict set opts_theme tooltip.axisPointer.crossStyle.color            "nothing"
            dict set opts_theme tooltip.axisPointer.label.color                 "nothing"

            dict set opts_theme axisPointerGlobal.lineStyle.color               "#817f91"
            dict set opts_theme axisPointerGlobal.crossStyle.color              "#817f91"
            dict set opts_theme axisPointerGlobal.label.color                   "#fff"
                                                                                                                                                                
            dict set opts_theme legend.textStyle.color                          $contrastColor
            dict set opts_theme legend.textStyle.fontSize                       "nothing"
            dict set opts_theme legend.textStyle.fontWeight                     "nothing"
            
            dict set opts_theme textStyle.color                                 $contrastColor
                                                                                
            dict set opts_theme title.textStyle.color                           "#EEF1FA"
            dict set opts_theme title.textStyle.fontSize                        "nothing"
            dict set opts_theme title.textStyle.fontWeight                      "nothing"
            dict set opts_theme title.subtextStyle.color                        "#B9B8CE"
            dict set opts_theme title.subtextStyle.fontSize                     "nothing"
            dict set opts_theme title.subtextStyle.fontWeight                   "nothing"
                                                                                
            dict set opts_theme toolbox.iconStyle.borderColor                   $contrastColor
                                                                                                                                        
            dict set opts_theme dataZoom.borderColor                            "#71708A"
            dict set opts_theme dataZoom.backgroundColor                        "rgba(47,69,84,0)"
            dict set opts_theme dataZoom.textStyle.color                        $contrastColor
            dict set opts_theme dataZoom.textStyle.fontSize                     "nothing"
            dict set opts_theme dataZoom.textStyle.fontWeight                   "nothing"
            dict set opts_theme dataZoom.brushStyle.color                       "rgba(135,163,206,0.3)"
            dict set opts_theme dataZoom.handleStyle.color                      "#353450"
            dict set opts_theme dataZoom.handleStyle.borderColor                "#C5CBE3"
            dict set opts_theme dataZoom.moveHandleStyle.color                  "#B0B6C3"
            dict set opts_theme dataZoom.moveHandleStyle.opacity                0.3
            dict set opts_theme dataZoom.fillerColor                            "rgba(135,163,206,0.2)"
            dict set opts_theme dataZoom.emphasis.handleStyle.borderColor       "#91B7F2"
            dict set opts_theme dataZoom.emphasis.handleStyle.color             "#4D587D"
            dict set opts_theme dataZoom.emphasis.moveHandleStyle.color         "#636D9A"
            dict set opts_theme dataZoom.emphasis.moveHandleStyle.opacity       0.7
            dict set opts_theme dataZoom.dataBackground.lineStyle.color         "#71708A"
            dict set opts_theme dataZoom.dataBackground.lineStyle.width         1
            dict set opts_theme dataZoom.dataBackground.areaStyle.color         "#71708A"
            dict set opts_theme dataZoom.selectedDataBackground.lineStyle.color "#87A3CE"
            dict set opts_theme dataZoom.selectedDataBackground.areaStyle.color "#87A3CE"
            
            dict set opts_theme visualMap.textStyle.color                       $contrastColor
            dict set opts_theme visualMap.textStyle.fontSize                    "nothing"
            dict set opts_theme visualMap.textStyle.fontWeight                  "nothing"
            
            dict set opts_theme timelineOpts.lineStyle.color                    $contrastColor
            dict set opts_theme timelineOpts.label.color                        $contrastColor
            dict set opts_theme timelineOpts.controlStyle.color                 $contrastColor
            dict set opts_theme timelineOpts.controlStyle.borderColor           $contrastColor
            dict set opts_theme timelineOpts.checkPointStyle.color              "#e43c59"
            dict set opts_theme timelineOpts.checkPointStyle.borderColor        "#c23531"
            dict set opts_theme timelineOpts.progress.label.color               "nothing"
            dict set opts_theme timelineOpts.progress.itemStyle.color           "nothing"
            dict set opts_theme timelineOpts.progress.lineStyle.color           "nothing"
            
            dict set opts_theme calendar.itemStyle.color                        $backgroundColor
            dict set opts_theme calendar.dayLabel.color                         $contrastColor
            dict set opts_theme calendar.monthLabel.color                       $contrastColor
            dict set opts_theme calendar.yearLabel.color                        $contrastColor
            
            dict set opts_theme lineSeries.symbol                               "circle"
            dict set opts_theme lineSeries.symbolSize                           4
            dict set opts_theme lineSeries.smooth                               "False"

            dict set opts_theme graphSeries.color                               $colorPalette

            dict set opts_theme gaugeSeries.title.color                         $contrastColor
            dict set opts_theme gaugeSeries.axisTick.show                       "True"

            dict set opts_theme candlestickSeries.itemStyle.color               "#FD1050"
            dict set opts_theme candlestickSeries.itemStyle.color0              "#0CF49B"
            dict set opts_theme candlestickSeries.itemStyle.borderColor         "#FD1050"
            dict set opts_theme candlestickSeries.itemStyle.borderColor0        "#0CF49B"
            
            dict set opts_theme treeSeries.symbol                               "circle"
            dict set opts_theme treeSeries.symbolSize                           4

            dict set opts_theme linesSeries.symbol                              "circle"
            dict set opts_theme linesSeries.symbolSize                          4

            dict set opts_theme radarSeries.symbol                              "circle"
            
            dict set opts_theme xAxis.splitLine.show                            "False"
            dict set opts_theme yAxis.splitLine.show                            "False"
            
            dict set opts_theme xAxis3D.splitLine.show                          "True"
            dict set opts_theme yAxis3D.splitLine.show                          "True"
            dict set opts_theme zAxis3D.splitLine.show                          "True"
            
            dict set opts_theme radiusAxis.axisTick.show                        "True"
            dict set opts_theme radiusAxis.axisLabel.color                      $contrastColor

            dict set opts_theme radarCoordinate.axisTick.show                   "True"
            dict set opts_theme radarCoordinate.axisLabel.color                 $contrastColor

            dict set opts_theme angleAxis.axisTick.show                         "True"
            dict set opts_theme angleAxis.axisLabel.color                       $contrastColor

            dict set opts_theme singleAxis.axisTick.show                        "True"
            dict set opts_theme singleAxis.axisLabel.color                      $contrastColor

            dict set opts_theme parallelAxis.axisTick.show                      "True"
            dict set opts_theme parallelAxis.axisLabel.color                    $contrastColor

            dict set opts_theme xAxis.axisTick.show                             "True"
            dict set opts_theme yAxis.axisTick.show                             "True"
            dict set opts_theme xAxis3D.axisTick.show                           "True"
            dict set opts_theme yAxis3D.axisTick.show                           "True"
            dict set opts_theme zAxis3D.axisTick.show                           "True"
            
            foreach axis {xAxis yAxis xAxis3D yAxis3D zAxis3D} {
                dict set opts_theme ${axis}.axisLabel.color                 $contrastColor
                dict set opts_theme ${axis}.axisLine.show                   "True"
                dict set opts_theme ${axis}.axisLine.lineStyle.color        $contrastColor
                dict set opts_theme ${axis}.axisLine.lineStyle.width        1
                dict set opts_theme ${axis}.splitLine.lineStyle.color       "#484753"
                dict set opts_theme ${axis}.splitLine.lineStyle.width       1
                dict set opts_theme ${axis}.splitArea.areaStyle.color       [list {"rgba(255,255,255,0.02)" "rgba(255,255,255,0.05)"}]
                dict set opts_theme ${axis}.minorSplitLine.lineStyle.color  "#20203B"
                dict set opts_theme ${axis}.minorSplitLine.lineStyle.width  1
            }
 
        }

        vintage {
            set backgroundColor "rgba(254,248,239,1)"
            set colorPalette    [list {#d87c7c #919e8b #d7ab82 #6e7074 #61a0a8 #efa18d #787464 #cc7e63 #724e58 #4b565b}]

            dict set opts_theme darkMode                                        "nothing"
            dict set opts_theme color                                           $colorPalette
            dict set opts_theme backgroundColor                                 $backgroundColor
                                                       
            dict set opts_theme tooltip.axisPointer.lineStyle.color             "nothing"
            dict set opts_theme tooltip.axisPointer.crossStyle.color            "nothing"
            dict set opts_theme tooltip.axisPointer.label.color                 "nothing"

            dict set opts_theme axisPointerGlobal.lineStyle.color               "nothing"
            dict set opts_theme axisPointerGlobal.crossStyle.color              "nothing"
            dict set opts_theme axisPointerGlobal.label.color                   "nothing"
                                                                                                                                                                
            dict set opts_theme legend.textStyle.color                          "#333333"
            dict set opts_theme legend.textStyle.fontSize                       "nothing"
            dict set opts_theme legend.textStyle.fontWeight                     "nothing"
            
            dict set opts_theme textStyle.color                                 "#333333"
                                                                                
            dict set opts_theme title.textStyle.color                           "#333333"
            dict set opts_theme title.textStyle.fontSize                        "nothing"
            dict set opts_theme title.textStyle.fontWeight                      "nothing"
            dict set opts_theme title.subtextStyle.color                        "#aaaaaa"
            dict set opts_theme title.subtextStyle.fontSize                     "nothing"
            dict set opts_theme title.subtextStyle.fontWeight                   "nothing"
                                                                                
            dict set opts_theme toolbox.iconStyle.borderColor                   "#666"
                                                                                                                                        
            dict set opts_theme dataZoom.borderColor                            "#ddd"
            dict set opts_theme dataZoom.backgroundColor                        "rgba(47,69,84,0)"
            dict set opts_theme dataZoom.textStyle.color                        "nothing"
            dict set opts_theme dataZoom.textStyle.fontSize                     "nothing"
            dict set opts_theme dataZoom.textStyle.fontWeight                   "nothing"
            dict set opts_theme dataZoom.brushStyle.color                       "nothing"
            dict set opts_theme dataZoom.handleStyle.color                      "nothing"
            dict set opts_theme dataZoom.handleStyle.borderColor                "nothing"
            dict set opts_theme dataZoom.moveHandleStyle.color                  "nothing"
            dict set opts_theme dataZoom.moveHandleStyle.opacity                "nothing"
            dict set opts_theme dataZoom.fillerColor                            "nothing"
            dict set opts_theme dataZoom.emphasis.handleStyle.borderColor       "nothing"
            dict set opts_theme dataZoom.emphasis.handleStyle.color             "nothing"
            dict set opts_theme dataZoom.emphasis.moveHandleStyle.color         "nothing"
            dict set opts_theme dataZoom.emphasis.moveHandleStyle.opacity       "nothing"
            dict set opts_theme dataZoom.dataBackground.lineStyle.color         "nothing"
            dict set opts_theme dataZoom.dataBackground.lineStyle.width         "nothing"
            dict set opts_theme dataZoom.dataBackground.areaStyle.color         "nothing"
            dict set opts_theme dataZoom.selectedDataBackground.lineStyle.color "nothing"
            dict set opts_theme dataZoom.selectedDataBackground.areaStyle.color "nothing"
            
            dict set opts_theme visualMap.textStyle.color                       "#333333"
            dict set opts_theme visualMap.textStyle.fontSize                    "nothing"
            dict set opts_theme visualMap.textStyle.fontWeight                  "nothing"
            
            dict set opts_theme timelineOpts.itemStyle.color                    "#293c55"
            dict set opts_theme timelineOpts.lineStyle.color                    "#293c55"
            dict set opts_theme timelineOpts.label.color                        "#293c55"
            dict set opts_theme timelineOpts.controlStyle.color                 "#293c55"
            dict set opts_theme timelineOpts.controlStyle.borderColor           "#293c55"
            dict set opts_theme timelineOpts.checkPointStyle.color              "#e43c59"
            dict set opts_theme timelineOpts.checkPointStyle.borderColor        "#c23531"
            dict set opts_theme timelineOpts.progress.label.color               "nothing"
            dict set opts_theme timelineOpts.progress.itemStyle.color           "nothing"
            dict set opts_theme timelineOpts.progress.lineStyle.color           "nothing"
            
            dict set opts_theme calendar.itemStyle.color                        "nothing"
            dict set opts_theme calendar.dayLabel.color                         "nothing"
            dict set opts_theme calendar.monthLabel.color                       "nothing"
            dict set opts_theme calendar.yearLabel.color                        "nothing"
            
            dict set opts_theme lineSeries.symbol                               "emptyCircle"
            dict set opts_theme lineSeries.symbolSize                           3
            dict set opts_theme lineSeries.smooth                               "False"

            dict set opts_theme graphSeries.color                               "#aaa"

            dict set opts_theme gaugeSeries.title.color                         "nothing"
            dict set opts_theme gaugeSeries.axisTick.show                       "True"

            dict set opts_theme candlestickSeries.itemStyle.color               "#c23531"
            dict set opts_theme candlestickSeries.itemStyle.color0              "#314656"
            dict set opts_theme candlestickSeries.itemStyle.borderColor         "#c23531"
            dict set opts_theme candlestickSeries.itemStyle.borderColor0        "#314656"

            dict set opts_theme treeSeries.symbol                               "emptyCircle"
            dict set opts_theme treeSeries.symbolSize                           3

            dict set opts_theme linesSeries.symbol                              "emptyCircle"
            dict set opts_theme linesSeries.symbolSize                          3

            dict set opts_theme radarSeries.symbol                              "emptyCircle"
            
            dict set opts_theme xAxis.splitLine.show                            "True"
            dict set opts_theme yAxis.splitLine.show                            "True"
            
            dict set opts_theme xAxis3D.splitLine.show                          "True"
            dict set opts_theme yAxis3D.splitLine.show                          "True"
            dict set opts_theme zAxis3D.splitLine.show                          "True"
            
            dict set opts_theme radiusAxis.axisTick.show                        "True"
            dict set opts_theme radiusAxis.axisLabel.color                      "#333333"

            dict set opts_theme radarCoordinate.axisTick.show                   "True"
            dict set opts_theme radarCoordinate.axisLabel.color                 "#333333"

            dict set opts_theme angleAxis.axisTick.show                         "True"
            dict set opts_theme angleAxis.axisLabel.color                       "#333333"

            dict set opts_theme singleAxis.axisTick.show                        "True"
            dict set opts_theme singleAxis.axisLabel.color                      "#333333"

            dict set opts_theme parallelAxis.axisTick.show                      "True"
            dict set opts_theme parallelAxis.axisLabel.color                    "#333333"

            dict set opts_theme xAxis.axisTick.show                             "True"
            dict set opts_theme yAxis.axisTick.show                             "True"
            dict set opts_theme xAxis3D.axisTick.show                           "True"
            dict set opts_theme yAxis3D.axisTick.show                           "True"
            dict set opts_theme zAxis3D.axisTick.show                           "True"
            
            foreach axis {xAxis yAxis xAxis3D yAxis3D zAxis3D} {
                dict set opts_theme ${axis}.axisLabel.color                 "#333333"
                dict set opts_theme ${axis}.axisLine.show                   "True"
                dict set opts_theme ${axis}.axisLine.lineStyle.color        "#333333"
                dict set opts_theme ${axis}.axisLine.lineStyle.width        1
                dict set opts_theme ${axis}.splitLine.lineStyle.color       "#ccc"
                dict set opts_theme ${axis}.splitLine.lineStyle.width       0.5
                dict set opts_theme ${axis}.splitArea.areaStyle.color       [list {rgba(250,250,250,0.3) rgba(200,200,200,0.3)}]
                dict set opts_theme ${axis}.minorSplitLine.lineStyle.color  "nothing"
                dict set opts_theme ${axis}.minorSplitLine.lineStyle.width  1
            }
        }

        westeros {
            set backgroundColor "rgba(0,0,0,0)"
            set colorPalette    [list {#516b91 #59c4e6 #edafda #93b7e3 #a5e7f0 #cbb0e3}]

            dict set opts_theme darkMode                                        "nothing"
            dict set opts_theme color                                           $colorPalette
            dict set opts_theme backgroundColor                                 $backgroundColor
                                                       
            dict set opts_theme tooltip.axisPointer.lineStyle.color             "nothing"
            dict set opts_theme tooltip.axisPointer.crossStyle.color            "nothing"
            dict set opts_theme tooltip.axisPointer.label.color                 "nothing"

            dict set opts_theme axisPointerGlobal.lineStyle.color               "nothing"
            dict set opts_theme axisPointerGlobal.crossStyle.color              "nothing"
            dict set opts_theme axisPointerGlobal.label.color                   "nothing"
                                                                                                                                                                
            dict set opts_theme legend.textStyle.color                          "#999999"
            dict set opts_theme legend.textStyle.fontSize                       "nothing"
            dict set opts_theme legend.textStyle.fontWeight                     "nothing"
            
            dict set opts_theme textStyle.color                                 "#999999"
                                                                                
            dict set opts_theme title.textStyle.color                           "#516b91"
            dict set opts_theme title.textStyle.fontSize                        "nothing"
            dict set opts_theme title.textStyle.fontWeight                      "nothing"
            dict set opts_theme title.subtextStyle.color                        "#93b7e3"
            dict set opts_theme title.subtextStyle.fontSize                     "nothing"
            dict set opts_theme title.subtextStyle.fontWeight                   "nothing"
                                                                                
            dict set opts_theme toolbox.iconStyle.borderColor                   "#999999"
                                                                                                                                        
            dict set opts_theme dataZoom.borderColor                            "#ddd"
            dict set opts_theme dataZoom.backgroundColor                        "rgba(47,69,84,0)"
            dict set opts_theme dataZoom.textStyle.color                        "nothing"
            dict set opts_theme dataZoom.textStyle.fontSize                     "nothing"
            dict set opts_theme dataZoom.textStyle.fontWeight                   "nothing"
            dict set opts_theme dataZoom.brushStyle.color                       "nothing"
            dict set opts_theme dataZoom.handleStyle.color                      "nothing"
            dict set opts_theme dataZoom.handleStyle.borderColor                "nothing"
            dict set opts_theme dataZoom.moveHandleStyle.color                  "nothing"
            dict set opts_theme dataZoom.moveHandleStyle.opacity                "nothing"
            dict set opts_theme dataZoom.fillerColor                            "nothing"
            dict set opts_theme dataZoom.emphasis.handleStyle.borderColor       "nothing"
            dict set opts_theme dataZoom.emphasis.handleStyle.color             "nothing"
            dict set opts_theme dataZoom.emphasis.moveHandleStyle.color         "nothing"
            dict set opts_theme dataZoom.emphasis.moveHandleStyle.opacity       "nothing"
            dict set opts_theme dataZoom.dataBackground.lineStyle.color         "nothing"
            dict set opts_theme dataZoom.dataBackground.lineStyle.width         "nothing"
            dict set opts_theme dataZoom.dataBackground.areaStyle.color         "nothing"
            dict set opts_theme dataZoom.selectedDataBackground.lineStyle.color "nothing"
            dict set opts_theme dataZoom.selectedDataBackground.areaStyle.color "nothing"
            
            dict set opts_theme visualMap.textStyle.color                       "#999999"
            dict set opts_theme visualMap.textStyle.fontSize                    "nothing"
            dict set opts_theme visualMap.textStyle.fontWeight                  "nothing"
            
            dict set opts_theme timelineOpts.itemStyle.color                    "#8fd3e8"
            dict set opts_theme timelineOpts.lineStyle.color                    "#8fd3e8"
            dict set opts_theme timelineOpts.label.color                        "#8fd3e8"
            dict set opts_theme timelineOpts.controlStyle.color                 "#8fd3e8"
            dict set opts_theme timelineOpts.controlStyle.borderColor           "#8fd3e8"
            dict set opts_theme timelineOpts.checkPointStyle.color              "#8fd3e8"
            dict set opts_theme timelineOpts.checkPointStyle.borderColor        "#8a7ca8"
            dict set opts_theme timelineOpts.progress.label.color               "nothing"
            dict set opts_theme timelineOpts.progress.itemStyle.color           "nothing"
            dict set opts_theme timelineOpts.progress.lineStyle.color           "nothing"
            
            dict set opts_theme calendar.itemStyle.color                        "nothing"
            dict set opts_theme calendar.dayLabel.color                         "nothing"
            dict set opts_theme calendar.monthLabel.color                       "nothing"
            dict set opts_theme calendar.yearLabel.color                        "nothing"
            
            dict set opts_theme lineSeries.symbol                               "emptyCircle"
            dict set opts_theme lineSeries.symbolSize                           3
            dict set opts_theme lineSeries.smooth                               "True"

            dict set opts_theme graphSeries.color                               "#aaa"

            dict set opts_theme gaugeSeries.title.color                         "nothing"
            dict set opts_theme gaugeSeries.axisTick.show                       "True"

            dict set opts_theme candlestickSeries.itemStyle.color               "#edafda"
            dict set opts_theme candlestickSeries.itemStyle.color0              "#8fd3e8"
            dict set opts_theme candlestickSeries.itemStyle.borderColor         "#d680bc"
            dict set opts_theme candlestickSeries.itemStyle.borderColor0        "#8fd3e8"

            dict set opts_theme treeSeries.symbol                               "emptyCircle"
            dict set opts_theme treeSeries.symbolSize                           3

            dict set opts_theme linesSeries.symbol                              "emptyCircle"
            dict set opts_theme linesSeries.symbolSize                          3

            dict set opts_theme radarSeries.symbol                              "emptyCircle"
            
            dict set opts_theme xAxis.splitLine.show                            "True"
            dict set opts_theme yAxis.splitLine.show                            "True"
            
            dict set opts_theme xAxis3D.splitLine.show                          "True"
            dict set opts_theme yAxis3D.splitLine.show                          "True"
            dict set opts_theme zAxis3D.splitLine.show                          "True"
            
            dict set opts_theme radiusAxis.axisTick.show                        "True"
            dict set opts_theme radiusAxis.axisLabel.color                      "#999999"

            dict set opts_theme radarCoordinate.axisTick.show                   "True"
            dict set opts_theme radarCoordinate.axisLabel.color                 "#999999"

            dict set opts_theme angleAxis.axisTick.show                         "True"
            dict set opts_theme angleAxis.axisLabel.color                       "#999999"

            dict set opts_theme singleAxis.axisTick.show                        "True"
            dict set opts_theme singleAxis.axisLabel.color                      "#999999"

            dict set opts_theme parallelAxis.axisTick.show                      "True"
            dict set opts_theme parallelAxis.axisLabel.color                    "#999999"

            dict set opts_theme xAxis.axisTick.show                             "True"
            dict set opts_theme yAxis.axisTick.show                             "True"
            dict set opts_theme xAxis3D.axisTick.show                           "True"
            dict set opts_theme yAxis3D.axisTick.show                           "True"
            dict set opts_theme zAxis3D.axisTick.show                           "True"
            
            foreach axis {xAxis yAxis xAxis3D yAxis3D zAxis3D} {
                dict set opts_theme ${axis}.axisLabel.color                 "#999999"
                dict set opts_theme ${axis}.axisLine.show                   "True"
                dict set opts_theme ${axis}.axisLine.lineStyle.color        "#cccccc"
                dict set opts_theme ${axis}.axisLine.lineStyle.width        1
                dict set opts_theme ${axis}.splitLine.lineStyle.color       "#eeeeee"
                dict set opts_theme ${axis}.splitLine.lineStyle.width       1
                dict set opts_theme ${axis}.splitArea.areaStyle.color       [list {rgba(250,250,250,0.05) rgba(200,200,200,0.02)}]
                dict set opts_theme ${axis}.minorSplitLine.lineStyle.color  "nothing"
                dict set opts_theme ${axis}.minorSplitLine.lineStyle.width  1
            }
        }

        wonderland {
            set backgroundColor "rgba(255,255,255,0)"
            set colorPalette    [list {#4ea397 #22c3aa #7bd9a5 #d0648a #f58db2 #f2b3c9}]

            dict set opts_theme darkMode                                        "nothing"
            dict set opts_theme color                                           $colorPalette
            dict set opts_theme backgroundColor                                 $backgroundColor
                                                       
            dict set opts_theme tooltip.axisPointer.lineStyle.color             "nothing"
            dict set opts_theme tooltip.axisPointer.crossStyle.color            "nothing"
            dict set opts_theme tooltip.axisPointer.label.color                 "nothing"

            dict set opts_theme axisPointerGlobal.lineStyle.color               "nothing"
            dict set opts_theme axisPointerGlobal.crossStyle.color              "nothing"
            dict set opts_theme axisPointerGlobal.label.color                   "nothing"
                                                                                                                                                                
            dict set opts_theme legend.textStyle.color                          "#999999"
            dict set opts_theme legend.textStyle.fontSize                       "nothing"
            dict set opts_theme legend.textStyle.fontWeight                     "nothing"
            
            dict set opts_theme textStyle.color                                 "#999999"
                                                                                
            dict set opts_theme title.textStyle.color                           "#666666"
            dict set opts_theme title.textStyle.fontSize                        "nothing"
            dict set opts_theme title.textStyle.fontWeight                      "nothing"
            dict set opts_theme title.subtextStyle.color                        "#999999"
            dict set opts_theme title.subtextStyle.fontSize                     "nothing"
            dict set opts_theme title.subtextStyle.fontWeight                   "nothing"
                                                                                
            dict set opts_theme toolbox.iconStyle.borderColor                   "#999999"
                                                                                                                                        
            dict set opts_theme dataZoom.borderColor                            "#ddd"
            dict set opts_theme dataZoom.backgroundColor                        "#22c3aa"
            dict set opts_theme dataZoom.textStyle.color                        "nothing"
            dict set opts_theme dataZoom.textStyle.fontSize                     "nothing"
            dict set opts_theme dataZoom.textStyle.fontWeight                   "nothing"
            dict set opts_theme dataZoom.brushStyle.color                       "nothing"
            dict set opts_theme dataZoom.handleStyle.color                      "nothing"
            dict set opts_theme dataZoom.handleStyle.borderColor                "nothing"
            dict set opts_theme dataZoom.moveHandleStyle.color                  "nothing"
            dict set opts_theme dataZoom.moveHandleStyle.opacity                "nothing"
            dict set opts_theme dataZoom.fillerColor                            "nothing"
            dict set opts_theme dataZoom.emphasis.handleStyle.borderColor       "nothing"
            dict set opts_theme dataZoom.emphasis.handleStyle.color             "nothing"
            dict set opts_theme dataZoom.emphasis.moveHandleStyle.color         "nothing"
            dict set opts_theme dataZoom.emphasis.moveHandleStyle.opacity       "nothing"
            dict set opts_theme dataZoom.dataBackground.lineStyle.color         "nothing"
            dict set opts_theme dataZoom.dataBackground.lineStyle.width         "nothing"
            dict set opts_theme dataZoom.dataBackground.areaStyle.color         "nothing"
            dict set opts_theme dataZoom.selectedDataBackground.lineStyle.color "nothing"
            dict set opts_theme dataZoom.selectedDataBackground.areaStyle.color "nothing"
            
            dict set opts_theme visualMap.textStyle.color                       "#999999"
            dict set opts_theme visualMap.textStyle.fontSize                    "nothing"
            dict set opts_theme visualMap.textStyle.fontWeight                  "nothing"
            
            dict set opts_theme timelineOpts.itemStyle.color                    "#4ea397"
            dict set opts_theme timelineOpts.lineStyle.color                    "#4ea397"
            dict set opts_theme timelineOpts.label.color                        "#4ea397"
            dict set opts_theme timelineOpts.controlStyle.color                 "#4ea397"
            dict set opts_theme timelineOpts.controlStyle.borderColor           "#4ea397"
            dict set opts_theme timelineOpts.checkPointStyle.color              "#4ea397"
            dict set opts_theme timelineOpts.checkPointStyle.borderColor        "#3cebd2"
            dict set opts_theme timelineOpts.progress.label.color               "nothing"
            dict set opts_theme timelineOpts.progress.itemStyle.color           "nothing"
            dict set opts_theme timelineOpts.progress.lineStyle.color           "nothing"
            
            dict set opts_theme calendar.itemStyle.color                        "nothing"
            dict set opts_theme calendar.dayLabel.color                         "nothing"
            dict set opts_theme calendar.monthLabel.color                       "nothing"
            dict set opts_theme calendar.yearLabel.color                        "nothing"
            
            dict set opts_theme lineSeries.symbol                               "emptyCircle"
            dict set opts_theme lineSeries.symbolSize                           3
            dict set opts_theme lineSeries.smooth                               "True"

            dict set opts_theme graphSeries.color                               "#aaa"
            
            dict set opts_theme gaugeSeries.title.color                         "nothing"
            dict set opts_theme gaugeSeries.axisTick.show                       "True"

            dict set opts_theme candlestickSeries.itemStyle.color               "#d0648a"
            dict set opts_theme candlestickSeries.itemStyle.color0              "#22c3aa"
            dict set opts_theme candlestickSeries.itemStyle.borderColor         "#d0648a"
            dict set opts_theme candlestickSeries.itemStyle.borderColor0        "#22c3aa"

            dict set opts_theme treeSeries.symbol                               "emptyCircle"
            dict set opts_theme treeSeries.symbolSize                           3

            dict set opts_theme linesSeries.symbol                              "emptyCircle"
            dict set opts_theme linesSeries.symbolSize                          3

            dict set opts_theme radarSeries.symbol                              "emptyCircle"
            
            dict set opts_theme xAxis.splitLine.show                            "True"
            dict set opts_theme yAxis.splitLine.show                            "True"
            
            dict set opts_theme xAxis3D.splitLine.show                          "True"
            dict set opts_theme yAxis3D.splitLine.show                          "True"
            dict set opts_theme zAxis3D.splitLine.show                          "True"
            
            dict set opts_theme radiusAxis.axisTick.show                        "True"
            dict set opts_theme radiusAxis.axisLabel.color                      "#999999"

            dict set opts_theme radarCoordinate.axisTick.show                   "True"
            dict set opts_theme radarCoordinate.axisLabel.color                 "#999999"

            dict set opts_theme angleAxis.axisTick.show                         "True"
            dict set opts_theme angleAxis.axisLabel.color                       "#999999"

            dict set opts_theme singleAxis.axisTick.show                        "True"
            dict set opts_theme singleAxis.axisLabel.color                      "#999999"

            dict set opts_theme parallelAxis.axisTick.show                      "True"
            dict set opts_theme parallelAxis.axisLabel.color                    "#999999"

            dict set opts_theme xAxis.axisTick.show                             "True"
            dict set opts_theme yAxis.axisTick.show                             "True"
            dict set opts_theme xAxis3D.axisTick.show                           "True"
            dict set opts_theme yAxis3D.axisTick.show                           "True"
            dict set opts_theme zAxis3D.axisTick.show                           "True"
            
            foreach axis {xAxis yAxis xAxis3D yAxis3D zAxis3D} {
                dict set opts_theme ${axis}.axisLabel.color                 "#999999"
                dict set opts_theme ${axis}.axisLine.show                   "True"
                dict set opts_theme ${axis}.axisLine.lineStyle.color        "#cccccc"
                dict set opts_theme ${axis}.axisLine.lineStyle.width        1
                dict set opts_theme ${axis}.splitLine.lineStyle.color       "#eeeeee"
                dict set opts_theme ${axis}.splitLine.lineStyle.width       1
                dict set opts_theme ${axis}.splitArea.areaStyle.color       [list {rgba(250,250,250,0.05) rgba(200,200,200,0.02)}]
                dict set opts_theme ${axis}.minorSplitLine.lineStyle.color  "nothing"
                dict set opts_theme ${axis}.minorSplitLine.lineStyle.width  1
            }
        }

        custom {
            set backgroundColor "rgba(0,0,0,0)"
            set colorPalette    [list {#5470c6 #91cc75 #fac858 #ee6666 #73c0de #3ba272 #fc8452 #9a60b4 #ea7ccc}]

            dict set opts_theme darkMode                                        "nothing"
            dict set opts_theme color                                           $colorPalette
            dict set opts_theme backgroundColor                                 $backgroundColor
                                                       
            dict set opts_theme tooltip.axisPointer.lineStyle.color             "nothing"
            dict set opts_theme tooltip.axisPointer.crossStyle.color            "nothing"
            dict set opts_theme tooltip.axisPointer.label.color                 "nothing"

            dict set opts_theme axisPointerGlobal.lineStyle.color               "nothing"
            dict set opts_theme axisPointerGlobal.crossStyle.color              "nothing"
            dict set opts_theme axisPointerGlobal.label.color                   "nothing"
                                                                                                                                                                
            dict set opts_theme legend.textStyle.color                          "#333"
            dict set opts_theme legend.textStyle.fontSize                       "nothing"
            dict set opts_theme legend.textStyle.fontWeight                     "nothing"
            
            dict set opts_theme textStyle.color                                 "nothing"
                                                                                
            dict set opts_theme title.textStyle.color                           "#464646"
            dict set opts_theme title.textStyle.fontSize                        "nothing"
            dict set opts_theme title.textStyle.fontWeight                      "nothing"
            dict set opts_theme title.subtextStyle.color                        "#6E7079"
            dict set opts_theme title.subtextStyle.fontSize                     "nothing"
            dict set opts_theme title.subtextStyle.fontWeight                   "nothing"
                                                                                
            dict set opts_theme toolbox.iconStyle.borderColor                   "#666"
                                                                                                                                        
            dict set opts_theme dataZoom.borderColor                            "#ddd"
            dict set opts_theme dataZoom.backgroundColor                        "rgba(47,69,84,0)"
            dict set opts_theme dataZoom.textStyle.color                        "nothing"
            dict set opts_theme dataZoom.textStyle.fontSize                     "nothing"
            dict set opts_theme dataZoom.textStyle.fontWeight                   "nothing"
            dict set opts_theme dataZoom.brushStyle.color                       "nothing"
            dict set opts_theme dataZoom.handleStyle.color                      "nothing"
            dict set opts_theme dataZoom.handleStyle.borderColor                "nothing"
            dict set opts_theme dataZoom.moveHandleStyle.color                  "nothing"
            dict set opts_theme dataZoom.moveHandleStyle.opacity                "nothing"
            dict set opts_theme dataZoom.fillerColor                            "nothing"
            dict set opts_theme dataZoom.emphasis.handleStyle.borderColor       "nothing"
            dict set opts_theme dataZoom.emphasis.handleStyle.color             "nothing"
            dict set opts_theme dataZoom.emphasis.moveHandleStyle.color         "nothing"
            dict set opts_theme dataZoom.emphasis.moveHandleStyle.opacity       "nothing"
            dict set opts_theme dataZoom.dataBackground.lineStyle.color         "nothing"
            dict set opts_theme dataZoom.dataBackground.lineStyle.width         "nothing"
            dict set opts_theme dataZoom.dataBackground.areaStyle.color         "nothing"
            dict set opts_theme dataZoom.selectedDataBackground.lineStyle.color "nothing"
            dict set opts_theme dataZoom.selectedDataBackground.areaStyle.color "nothing"
            
            dict set opts_theme visualMap.textStyle.color                       "nothing"
            dict set opts_theme visualMap.textStyle.fontSize                    "nothing"
            dict set opts_theme visualMap.textStyle.fontWeight                  "nothing"
            
            dict set opts_theme timelineOpts.itemStyle.color                    "nothing"
            dict set opts_theme timelineOpts.lineStyle.color                    "#DAE1F5"
            dict set opts_theme timelineOpts.label.color                        "#A4B1D7"
            dict set opts_theme timelineOpts.controlStyle.color                 "#A4B1D7"
            dict set opts_theme timelineOpts.controlStyle.borderColor           "#A4B1D7"
            dict set opts_theme timelineOpts.checkPointStyle.color              "#316bf3"
            dict set opts_theme timelineOpts.checkPointStyle.borderColor        "#ffffff"
            dict set opts_theme timelineOpts.progress.label.color               "nothing"
            dict set opts_theme timelineOpts.progress.itemStyle.color           "nothing"
            dict set opts_theme timelineOpts.progress.lineStyle.color           "nothing"
            
            dict set opts_theme calendar.itemStyle.color                        "nothing"
            dict set opts_theme calendar.dayLabel.color                         "nothing"
            dict set opts_theme calendar.monthLabel.color                       "nothing"
            dict set opts_theme calendar.yearLabel.color                        "nothing"
            
            dict set opts_theme lineSeries.symbol                               "emptyCircle"
            dict set opts_theme lineSeries.symbolSize                           3
            dict set opts_theme lineSeries.smooth                               "False"

            dict set opts_theme graphSeries.color                               "#aaa"

            dict set opts_theme gaugeSeries.title.color                         "nothing"
            dict set opts_theme gaugeSeries.axisTick.show                       "True"

            dict set opts_theme candlestickSeries.itemStyle.color               "nothing"
            dict set opts_theme candlestickSeries.itemStyle.color0              "nothing"
            dict set opts_theme candlestickSeries.itemStyle.borderColor         "nothing"
            dict set opts_theme candlestickSeries.itemStyle.borderColor0        "nothing"

            dict set opts_theme treeSeries.symbol                               "emptyCircle"
            dict set opts_theme treeSeries.symbolSize                           3

            dict set opts_theme linesSeries.symbol                              "emptyCircle"
            dict set opts_theme linesSeries.symbolSize                          3

            dict set opts_theme radarSeries.symbol                              "circle"
            
            dict set opts_theme xAxis.splitLine.show                            "True"
            dict set opts_theme yAxis.splitLine.show                            "True"
            
            dict set opts_theme xAxis3D.splitLine.show                          "True"
            dict set opts_theme yAxis3D.splitLine.show                          "True"
            dict set opts_theme zAxis3D.splitLine.show                          "True"
            
            dict set opts_theme radiusAxis.axisTick.show                        "True"
            dict set opts_theme radiusAxis.axisLabel.color                      "nothing"

            dict set opts_theme radarCoordinate.axisTick.show                   "True"
            dict set opts_theme radarCoordinate.axisLabel.color                 "nothing"

            dict set opts_theme angleAxis.axisTick.show                         "True"
            dict set opts_theme angleAxis.axisLabel.color                       "nothing"

            dict set opts_theme singleAxis.axisTick.show                        "True"
            dict set opts_theme singleAxis.axisLabel.color                      "nothing"

            dict set opts_theme parallelAxis.axisTick.show                      "True"
            dict set opts_theme parallelAxis.axisLabel.color                    "nothing"

            dict set opts_theme xAxis.axisTick.show                             "True"
            dict set opts_theme yAxis.axisTick.show                             "True"
            dict set opts_theme xAxis3D.axisTick.show                           "True"
            dict set opts_theme yAxis3D.axisTick.show                           "True"
            dict set opts_theme zAxis3D.axisTick.show                           "True"
            
            foreach axis {xAxis yAxis xAxis3D yAxis3D zAxis3D} {
                dict set opts_theme ${axis}.axisLabel.color                 "nothing"
                dict set opts_theme ${axis}.axisLine.show                   "True"
                dict set opts_theme ${axis}.axisLine.lineStyle.color        "#6E7079"
                dict set opts_theme ${axis}.axisLine.lineStyle.width        1
                dict set opts_theme ${axis}.splitLine.lineStyle.color       "#E0E6F1"
                dict set opts_theme ${axis}.splitLine.lineStyle.width       1
                dict set opts_theme ${axis}.splitArea.areaStyle.color       [list {rgba(250,250,250,0.2) rgba(210,219,238,0.2)}]
                dict set opts_theme ${axis}.minorSplitLine.lineStyle.color  "nothing"
                dict set opts_theme ${axis}.minorSplitLine.lineStyle.width  1
            }
        }

        default {error "theme '$theme' not supported..."}
    }
}