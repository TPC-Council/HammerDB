source base.tcl

set w .line
set bltgr [bltLineGraph $w]

$bltgr axis configure x -title "X\nAxis" -limitsformat "%g"
$bltgr axis configure y -title "Y\nAxis"

$bltgr element configure data1 -dash {8 3} -showvalues y -smooth step -symbol circle -outline yellow -outlinewidth 3 -pixels 10 -valuefont "times 14 italic" -valuerotate 45

$bltgr legend configure -relief raised
$bltgr xaxis configure -bg cyan -relief raised
$bltgr configure -relief raised
$bltgr configure -plotrelief raised

$bltgr legend selection set data2
$bltgr legend focus data1
$bltgr legend configure -selectrelief groove

$bltgr postscript configure -decorations yes
$bltgr postscript output foo.ps
$bltgr postscript configure -decorations no
$bltgr postscript output bar.ps

#set graph [bltBarGraph $w]

#puts stderr "done"
#bltPlotDestroy $w

