source base.tcl

set w .line
set bltgr [bltLineGraph $w]

$bltgr pen create foo -color red -showvalues y -symbol circle -dashes {4 4}
$bltgr element configure data2 -pen foo

puts stderr "Testing Line Pen..."

bltTest3 $bltgr pen foo -color yellow $dops
bltTest3 $bltgr pen foo -dashes {8 3} $dops
bltTest3 $bltgr pen foo -errorbarcolor green $dops
bltTest3 $bltgr pen foo -errorbarwidth 2 $dops
bltTest3 $bltgr pen foo -errorbarcap 10 $dops
bltTest3 $bltgr pen foo -fill cyan $dops
bltTest3 $bltgr pen foo -linewidth 3 $dops
bltTest3 $bltgr pen foo -offdash black $dops
bltTest3 $bltgr pen foo -outline green $dops
bltTest3 $bltgr pen foo -outlinewidth 5 $dops
bltTest3 $bltgr pen foo -pixels 20 $dops
bltTest3 $bltgr pen foo -showvalues none $dops
bltTest3 $bltgr pen foo -symbol arrow $dops
bltTest3 $bltgr pen foo -symbol cross $dops
bltTest3 $bltgr pen foo -symbol diamond $dops
bltTest3 $bltgr pen foo -symbol none $dops
bltTest3 $bltgr pen foo -symbol plus $dops
bltTest3 $bltgr pen foo -symbol scross $dops
bltTest3 $bltgr pen foo -symbol splus $dops
bltTest3 $bltgr pen foo -symbol square $dops
bltTest3 $bltgr pen foo -symbol triangle $dops
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

