source base.tcl

set w .bar
set bltgr [bltBarGraph $w]

puts stderr "Testing Bar Graph..."

bltTest $bltgr -aspect 2 $dops
bltTest $bltgr -background red $dops
bltTest $bltgr -barmode stacked $dops
bltTest $bltgr -barmode aligned $dops
bltTest $bltgr -barmode overlap $dops
bltTest $bltgr -barwidth .15 $dops
#bltTest $bltgr -baseline $dops
bltTest $bltgr -bd 50 $dops
bltTest $bltgr -bg green $dops
bltTest $bltgr -bm 50 $dops
bltTest $bltgr -borderwidth 50 $dops
bltTest $bltgr -bottommargin 50 $dops
#bltTest $bltgr -bufferelements $dops
#bltTest $bltgr -buffergraph $dops
bltTest $bltgr -cursor cross $dops
bltTest $bltgr -fg blue $dops
bltTest $bltgr -font {times 36 bold italic} $dops
bltTest $bltgr -foreground cyan $dops
#bltTest $bltgr -halo $dops
bltTest $bltgr -height 300 $dops
#bltTest $bltgr -highlightbackground $dops
#bltTest $bltgr -highlightcolor $dops
#bltTest $bltgr -highlightthickness $dops
bltTest $bltgr -invertxy yes $dops
bltTest $bltgr -justify left $dops
bltTest $bltgr -justify center $dops
bltTest $bltgr -justify right $dops
bltTest $bltgr -leftmargin 50 $dops
bltTest $bltgr -lm 50 $dops
bltTest $bltgr -plotbackground cyan $dops
bltTest $bltgr -plotborderwidth 50 $dops
bltTest $bltgr -plotpadx 50 $dops
bltTest $bltgr -plotpady 50 $dops
bltTest $bltgr -plotrelief groove $dops
bltTest $bltgr -relief groove $dops
bltTest $bltgr -rightmargin 50 $dops
bltTest $bltgr -rm 50 $dops
#bltTest $bltgr -searchhalo $dops
#bltTest $bltgr -searchmode $dops
#bltTest $bltgr -searchalong $dops
#bltTest $bltgr -stackaxes $dops
#bltTest $bltgr -takefocus $dops
bltTest $bltgr -title "This is a Title" $dops
bltTest $bltgr -tm 50 $dops
bltTest $bltgr -topmargin 50 $dops
bltTest $bltgr -width 300 $dops
bltTest $bltgr -plotwidth 300 $dops
bltTest $bltgr -plotheight 300 $dops

##bltCmd $bltgr axis
bltCmd $bltgr cget -background
bltCmd $bltgr configure 
bltCmd $bltgr configure 
bltCmd $bltgr configure -background cyan
##bltCmd $bltgr crosshairs
##bltCmd $bltgr element
#bltCmd $bltgr extents
#bltCmd $bltgr inside
#bltCmd $bltgr invtransform
##bltCmd $bltgr legend
##bltCmd $bltgr marker
##bltCmd $bltgr pen
##bltCmd $bltgr postscript
#bltCmd $bltgr transform
##bltCmd $bltgr x2axis
##bltCmd $bltgr xaxis
##bltCmd $bltgr y2axis
##bltCmd $bltgr yaxis

puts stderr "done"
bltPlotDestroy $w

