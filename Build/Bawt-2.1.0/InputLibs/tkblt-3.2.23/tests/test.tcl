source base.tcl

set w .line
set bltgr [bltLineGraph $w]

puts stderr "done"
bltPlotDestroy $w

