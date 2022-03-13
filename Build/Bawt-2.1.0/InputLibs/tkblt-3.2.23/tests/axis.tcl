source base.tcl

set w .line
set bltgr [bltLineGraph $w]

$bltgr axis configure x -bd 2 -background cyan -title "X\nAxis" -limitsformat "%g"
$bltgr axis configure y -bd 2 -background cyan -title "Y\nAxis"
bltCmd $bltgr axis activate y

puts stderr "Testing Axis..."

bltTest3 $bltgr axis y -activeforeground red $dops
bltTest3 $bltgr axis y -activerelief sunken $dops
#bltTest3 $bltgr axis x -autorange 10 $dops
bltTest3 $bltgr axis x -background yellow $dops
bltTest3 $bltgr axis x -bg blue $dops
bltTest3 $bltgr axis x -bindtags {aa} 0
bltTest3 $bltgr axis y -bd 4 $dops
bltTest3 $bltgr axis y -borderwidth 4 $dops
#bltTest3 $bltgr axis x -checklimits $dops
bltTest3 $bltgr axis x -color red $dops
#bltTest3 $bltgr axis x -command $dops
bltTest3 $bltgr axis x -descending yes $dops
bltTest3 $bltgr axis x -exterior no $dops
bltTest3 $bltgr axis x -fg magenta $dops
bltTest3 $bltgr axis x -foreground yellow $dops
bltTest3 $bltgr axis x -grid no $dops
bltTest3 $bltgr axis x -gridcolor blue $dops
bltTest3 $bltgr axis x -griddashes {8 3} $dops
bltTest3 $bltgr axis x -gridlinewidth 2 $dops
bltTest3 $bltgr axis x -gridminor no $dops
bltTest3 $bltgr axis x -gridminorcolor blue $dops
bltTest3 $bltgr axis x -gridminordashes {8 3} $dops
bltTest3 $bltgr axis x -gridminorlinewidth 2 $dops
bltTest3 $bltgr axis x -hide yes $dops
bltTest3 $bltgr axis x -justify left $dops
bltTest3 $bltgr axis x -justify center $dops
bltTest3 $bltgr axis x -justify right $dops
bltTest3 $bltgr axis x -labeloffset yes $dops
bltTest3 $bltgr axis x -limitscolor red $dops
bltTest3 $bltgr axis x -limitsfont {times 18 bold italic} $dops
bltTest3 $bltgr axis x -limitsformat "%e" $dops
bltTest3 $bltgr axis x -linewidth 2 $dops
bltTest3 $bltgr axis x -logscale yes $dops
#bltTest3 $bltgr axis x -loosemin $dops
#bltTest3 $bltgr axis x -loosemax $dops
#bltTest3 $bltgr axis x -majorticks $dops
#bltTest3 $bltgr axis x -max $dops
#bltTest3 $bltgr axis x -min $dops
#bltTest3 $bltgr axis x -minorticks $dops
bltTest3 $bltgr axis x -relief flat $dops
bltTest3 $bltgr axis x -relief groove $dops
bltTest3 $bltgr axis x -relief raised $dops
bltTest3 $bltgr axis x -relief ridge $dops
bltTest3 $bltgr axis x -relief solid $dops
bltTest3 $bltgr axis x -relief sunken $dops
bltTest3 $bltgr axis x -rotate 45 $dops
#bltTest3 $bltgr axis x -scrollcommand $dops
#bltTest3 $bltgr axis x -scrollincrement $dops
#bltTest3 $bltgr axis x -scrollmax $dops
#bltTest3 $bltgr axis x -scrollmin $dops
##bltTest3 $bltgr axis x -shiftby 10 $dops
bltTest3 $bltgr axis x -showticks no $dops
bltTest3 $bltgr axis x -stepsize 10 $dops
bltTest3 $bltgr axis x -subdivisions 4 $dops
##bltTest3 $bltgr axis x -tickanchor n $dops
bltTest3 $bltgr axis x -tickfont {times 12 bold italic} $dops
bltTest3 $bltgr axis x -ticklength 20 $dops
bltTest3 $bltgr axis x -tickdefault 10 $dops
bltTest3 $bltgr axis x -title {This is a Title} $dops
bltTest3 $bltgr axis x -titlealternate yes $dops
bltTest3 $bltgr axis x -titlecolor yellow $dops
bltTest3 $bltgr axis x -titlefont {times 24 bold italic} $dops

#bltCmd $bltgr axis activate foo
#bltCmd $bltgr axis bind x
bltCmd $bltgr axis cget x -color
bltCmd $bltgr axis configure x
bltCmd $bltgr axis configure x -color
#bltCmd $bltgr axis create foo
#bltCmd $bltgr axis deactivate foo
#bltCmd $bltgr axis delete foo
#bltCmd $bltgr axis invtransform x
#bltCmd $bltgr axis limits x
#bltCmd $bltgr axis margin x
#bltCmd $bltgr axis names x
#bltCmd $bltgr axis transform x
#bltCmd $bltgr axis type x
#bltCmd $bltgr axis view x

#bltCmd $bltgr xaxis activate
#bltCmd $bltgr xaxis bind
bltCmd $bltgr xaxis cget -color
bltCmd $bltgr xaxis configure
bltCmd $bltgr xaxis configure -color
#bltCmd $bltgr xaxis deactivate
#bltCmd $bltgr xaxis invtransform
#bltCmd $bltgr xaxis limits
#bltCmd $bltgr xaxis transform
#bltCmd $bltgr xaxis use
#bltCmd $bltgr xaxis view

puts stderr "done"
bltPlotDestroy $w

