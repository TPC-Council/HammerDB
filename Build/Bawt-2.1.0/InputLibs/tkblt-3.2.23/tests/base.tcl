package require tkblt

#set sleep 1000
set sleep 500
if {![info exists dops]} {
    set dops 0
}

proc bltPlot {w title} {
    toplevel $w
    wm title $w $title
    wm protocol $w WM_DELETE_WINDOW [list bltPlotDestroy $w]

    set mb ${w}mb
    menu $mb
    $w configure -menu $mb
}

proc bltPlotDestroy {w} {
    destroy ${w}mb
    destroy $w
}

proc bltTest {graph option value {dops 0}} {
    global sleep

    puts stderr "  $option $value"
    set org [$graph cget $option]
    $graph configure $option $value
    update
    if {$dops} {
	$graph postscript output foo.ps
	exec open /Applications/Preview.app/ foo.ps
    }
    after $sleep
#    read stdin 1
    $graph configure $option $org
    update
    after $sleep
}

proc bltTest2 {graph which option value {dops 0}} {
    global sleep

    puts stderr "  $option $value"
    set org [$graph $which cget $option]
    $graph $which configure $option $value
    update
    if {$dops} {
	$graph postscript output foo.ps
	exec open /Applications/Preview.app/ foo.ps
    }
    after $sleep
#    read stdin 1
    $graph $which configure $option $org
    update
    after $sleep
}

proc bltTest3 {graph which item option value {dops 0}} {
    global sleep

    puts stderr "  $item $option $value"
    set org [$graph $which cget $item $option]
    $graph $which configure $item $option $value
    update
    if {$dops} {
	$graph postscript output foo.ps
	exec open /Applications/Preview.app/ foo.ps
    }
    after $sleep
#    read stdin 1
    $graph $which configure $item $option $org
    update
    after $sleep
}

proc bltCmd {graph args} {
    global sleep

    puts stderr " $graph $args"
    eval $graph $args
    update
    after $sleep
#    read stdin 1
}

proc bltElements {graph} {
    blt::vector create xv(10)
    blt::vector create yv(10)
    xv set { 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 }
    yv set { 5 10 10 15 15 10 20 25 30 35 }

    $graph element create data1 -data {0.2 13 0.4 25 0.6 36 0.8 46 1.0 55 1.2 64 1.4 70 1.6 75 1.8 80 2.0 90}

    $graph element create data2 \
	-xdata {0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0} \
	-ydata {26 50 72 92 110 128 140 150 160 180} \
	-xerror {.05 .05 .05 .05 .05 .05 .05 .05 .05 .05} \
 	-yerror {10 10 10 10 10 10 10 10 10 10 10}  \
	-color red

    $graph element create data3 -xdata xv -ydata yv -color green

    $graph legend configure -title "Legend"
}

proc bltBarGraph {w} {
    global sleep

    bltPlot $w "Bar Graph"
    set graph [blt::barchart ${w}.gr \
		   -width 600 \
		   -height 500 \
		   -title "Bar\nGraph" \
		   -barwidth .2 \
		   -barmode aligned \
		  ]
    pack $graph -expand yes -fill both
    bltElements $graph

    update
    after $sleep
    return $graph
}

proc bltLineGraph {w} {
    global sleep

    bltPlot $w "Line Graph"
    set graph [blt::graph ${w}.gr \
		   -width 600 \
		   -height 500 \
		   -title "Line\nGraph" \
		  ]
    pack $graph -expand yes -fill both
    bltElements $graph

    update
    after $sleep
    return $graph
}
