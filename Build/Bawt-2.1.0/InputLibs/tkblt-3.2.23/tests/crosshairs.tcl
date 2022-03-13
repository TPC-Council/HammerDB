source base.tcl

set w .line
set bltgr [bltLineGraph $w]

$bltgr crosshairs on
$bltgr crosshairs configure -x 200 -y 200

puts stderr "Testing Crosshairs..."

bltTest2 $bltgr crosshairs -color green
bltTest2 $bltgr crosshairs -dashes "8 3"
bltTest2 $bltgr crosshairs -linewidth 3
bltTest2 $bltgr crosshairs -x 100
bltTest2 $bltgr crosshairs -y 100

bltCmd $bltgr crosshairs cget -color
bltCmd $bltgr crosshairs configure
bltCmd $bltgr crosshairs configure -color
bltCmd $bltgr crosshairs on
bltCmd $bltgr crosshairs off
bltCmd $bltgr crosshairs toggle

puts stderr "done"
bltPlotDestroy $w

