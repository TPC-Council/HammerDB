source base.tcl

set w .line
set bltgr [bltLineGraph $w]

set mm [$bltgr marker create text tt -element data2 \
	    -coords {1. 112} -text "Text\nMarker" -font {helvetica 24}]
$bltgr element configure data1 -hide yes

puts stderr "Testing Text Marker..."

bltTest3 $bltgr marker $mm -anchor nw $dops
bltTest3 $bltgr marker $mm -anchor n $dops
bltTest3 $bltgr marker $mm -anchor ne $dops
bltTest3 $bltgr marker $mm -anchor e $dops
bltTest3 $bltgr marker $mm -anchor se $dops
bltTest3 $bltgr marker $mm -anchor s $dops
bltTest3 $bltgr marker $mm -anchor sw $dops
bltTest3 $bltgr marker $mm -anchor w $dops
bltTest3 $bltgr marker $mm -background yellow $dops
bltTest3 $bltgr marker $mm -bg red $dops
bltTest3 $bltgr marker $mm -bindtags {aa} 0
bltTest3 $bltgr marker $mm -coords {1 50} $dops
bltTest3 $bltgr marker $mm -element data1 $dops
bltTest3 $bltgr marker $mm -fg cyan $dops
bltTest3 $bltgr marker $mm -fill yellow $dops
bltTest3 $bltgr marker $mm -font {times 24 bold italic} $dops
bltTest3 $bltgr marker $mm -foreground blue $dops
bltTest3 $bltgr marker $mm -justify left $dops
bltTest3 $bltgr marker $mm -justify center $dops
bltTest3 $bltgr marker $mm -justify right $dops
bltTest3 $bltgr marker $mm -hide yes $dops
bltTest3 $bltgr marker $mm -mapx x2 $dops
bltTest3 $bltgr marker $mm -mapy y2 $dops
bltTest3 $bltgr marker $mm -outline green $dops
bltTest3 $bltgr marker $mm -rotate 45 $dops
bltTest3 $bltgr marker $mm -text {Hello World} $dops
bltTest3 $bltgr marker $mm -under yes $dops
bltTest3 $bltgr marker $mm -xoffset 20 $dops
bltTest3 $bltgr marker $mm -yoffset 20 $dops

puts stderr "done"
bltPlotDestroy $w

