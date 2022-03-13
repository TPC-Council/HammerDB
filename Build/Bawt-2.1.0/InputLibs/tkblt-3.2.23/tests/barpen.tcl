source base.tcl

set w .bar
set bltgr [bltBarGraph $w]

$bltgr pen create foo -color red -showvalues y
$bltgr element configure data2 -pen foo

puts stderr "Testing Bar Pen..."

bltTest3 $bltgr pen foo -background yellow $dops
bltTest3 $bltgr pen foo -bd 4 $dops
bltTest3 $bltgr pen foo -bg yellow $dops
bltTest3 $bltgr pen foo -borderwidth 4 $dops
bltTest3 $bltgr pen foo -color yellow $dops
bltTest3 $bltgr pen foo -errorbarcolor green $dops
bltTest3 $bltgr pen foo -errorbarwidth 2 $dops
bltTest3 $bltgr pen foo -errorbarcap 10 $dops
bltTest3 $bltgr pen foo -fg yellow $dops
bltTest3 $bltgr pen foo -fill cyan $dops
bltTest3 $bltgr pen foo -foreground green $dops
bltTest3 $bltgr pen foo -outline red $dops
bltTest3 $bltgr pen foo -relief flat $dops
bltTest3 $bltgr pen foo -showerrorbars no $dops
bltTest3 $bltgr pen foo -showvalues none $dops
bltTest3 $bltgr pen foo -showvalues x $dops
bltTest3 $bltgr pen foo -showvalues both $dops
bltTest3 $bltgr pen foo -valueanchor nw $dops
bltTest3 $bltgr pen foo -valueanchor n $dops
bltTest3 $bltgr pen foo -valueanchor ne $dops
bltTest3 $bltgr pen foo -valueanchor e $dops
bltTest3 $bltgr pen foo -valueanchor se $dops
bltTest3 $bltgr pen foo -valueanchor s $dops
bltTest3 $bltgr pen foo -valueanchor sw $dops
bltTest3 $bltgr pen foo -valueanchor w $dops
bltTest3 $bltgr pen foo -valuecolor cyan $dops
bltTest3 $bltgr pen foo -valuefont {times 18 bold italic} $dops
bltTest3 $bltgr pen foo -valueformat "%e" $dops
bltTest3 $bltgr pen foo -valuerotate 45 $dops

bltCmd $bltgr pen cget foo -color
bltCmd $bltgr pen configure foo
bltCmd $bltgr pen configure foo -color
bltCmd $bltgr pen create bar
bltCmd $bltgr pen delete bar
bltCmd $bltgr pen names 
bltCmd $bltgr pen type foo

puts stderr "done"
bltPlotDestroy $w

