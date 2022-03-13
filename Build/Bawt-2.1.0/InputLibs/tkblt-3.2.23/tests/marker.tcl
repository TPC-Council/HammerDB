source base.tcl

set w .line
set bltgr [bltLineGraph $w]

set mm [$bltgr marker create line tt -element data1 \
	    -coords {1 50 1.5 100 1 150} -linewidth 5 -bind {aa}]
set nn [$bltgr marker create line ss -element data1 \
	    -coords {1 150 .5 100 1 50} -linewidth 1 \
	    -outline green -dashes 4]

puts stderr "Testing Marker..."

#bltCmd $bltgr marker bind aa <Button-1> [list puts "%x %y"]
bltCmd $bltgr marker cget $mm -cap
bltCmd $bltgr marker configure $mm
bltCmd $bltgr marker configure $mm -cap
set foo [$bltgr marker create line]
bltCmd $bltgr marker delete $foo
set foo [$bltgr marker create line foo]
bltCmd $bltgr marker delete $foo
bltCmd $bltgr marker exists $mm
bltCmd $bltgr marker find enclosed 0 0 2 200
bltCmd $bltgr marker lower $mm
bltCmd $bltgr marker lower $mm $nn
bltCmd $bltgr marker names
bltCmd $bltgr marker raise $mm
bltCmd $bltgr marker raise $mm $nn
bltCmd $bltgr marker type $mm

puts stderr "done"
bltPlotDestroy $w

