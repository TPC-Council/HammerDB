source base.tcl

set w .line
set bltgr [bltLineGraph $w]

$bltgr element configure data1 -dash {8 3} -showvalues y -smooth step -symbol circle -outline yellow -outlinewidth 3 -pixels 10

$bltgr pen create foo -showvalues y -symbol circle -dashes {8 3} -color purple -linewidth 2
$bltgr element activate data3

puts stderr "Testing Line Element.."

bltTest3 $bltgr element data3 -activepen foo $dops
bltTest3 $bltgr element data2 -areabackground yellow $dops
bltTest3 $bltgr element data2 -bindtags {aa}
bltTest3 $bltgr element data2 -color yellow $dops
bltTest3 $bltgr element data2 -dashes {8 3} $dops
bltTest3 $bltgr element data1 -data {0.2 8 0.4 20 0.6 31 0.8 41 1.0 50 1.2 59 1.4 65 1.6 70 1.8 75 2.0 85} $dops
bltTest3 $bltgr element data2 -errorbarcolor green $dops
bltTest3 $bltgr element data2 -errorbarwidth 2 $dops
bltTest3 $bltgr element data2 -errorbarcap 10 $dops
bltTest3 $bltgr element data1 -fill cyan $dops
bltTest3 $bltgr element data2 -hide yes $dops
bltTest3 $bltgr element data2 -label "This is a test" $dops
bltTest3 $bltgr element data2 -legendrelief groove $dops
bltTest3 $bltgr element data2 -linewidth 3 $dops
bltTest3 $bltgr element data2 -mapx x2 $dops
bltTest3 $bltgr element data2 -mapy y2 $dops
bltTest3 $bltgr element data1 -maxsymbols 4 $dops
bltTest3 $bltgr element data1 -offdash black $dops
bltTest3 $bltgr element data1 -outline green $dops
bltTest3 $bltgr element data1 -outlinewidth 5 $dops
bltTest3 $bltgr element data2 -pen foo $dops
bltTest3 $bltgr element data1 -pixels 20 $dops
#bltTest3 $bltgr element data2 -reduce $dops
bltTest3 $bltgr element data1 -scalesymbols no $dops
bltTest3 $bltgr element data2 -showerrorbars no $dops
bltTest3 $bltgr element data1 -showvalues none $dops
bltTest3 $bltgr element data1 -showvalues x $dops
bltTest3 $bltgr element data1 -showvalues both $dops
bltTest3 $bltgr element data1 -smooth linear $dops
bltTest3 $bltgr element data1 -smooth cubic $dops
bltTest3 $bltgr element data1 -smooth quadratic $dops
bltTest3 $bltgr element data1 -smooth catrom $dops
#bltTest3 $bltgr element data2 -styles $dops
bltTest3 $bltgr element data1 -symbol arrow $dops
bltTest3 $bltgr element data1 -symbol cross $dops
bltTest3 $bltgr element data1 -symbol diamond $dops
bltTest3 $bltgr element data1 -symbol none $dops
bltTest3 $bltgr element data1 -symbol plus $dops
bltTest3 $bltgr element data1 -symbol scross $dops
bltTest3 $bltgr element data1 -symbol splus $dops
bltTest3 $bltgr element data1 -symbol square $dops
bltTest3 $bltgr element data1 -symbol triangle $dops
bltTest3 $bltgr element data2 -trace both $dops
bltTest3 $bltgr element data1 -valueanchor nw $dops
bltTest3 $bltgr element data1 -valueanchor n $dops
bltTest3 $bltgr element data1 -valueanchor ne $dops
bltTest3 $bltgr element data1 -valueanchor e $dops
bltTest3 $bltgr element data1 -valueanchor se $dops
bltTest3 $bltgr element data1 -valueanchor s $dops
bltTest3 $bltgr element data1 -valueanchor sw $dops
bltTest3 $bltgr element data1 -valueanchor w $dops
bltTest3 $bltgr element data1 -valuecolor cyan $dops
bltTest3 $bltgr element data1 -valuefont {times 18 bold italic} $dops
bltTest3 $bltgr element data1 -valueformat "%e" $dops
bltTest3 $bltgr element data1 -valuerotate 45 $dops
#bltTest3 $bltgr element data2 -weights $dops
bltTest3 $bltgr element data1 -x {0 .2 .4 .6 .8 1 1.2 1.4 1.6 1.8} $dops
bltTest3 $bltgr element data1 -xdata {0 .2 .4 .6 .8 1 1.2 1.4 1.6 1.8} $dops
bltTest3 $bltgr element data2 -xerror {.1 .1 .1 .1 .1 .1 .1 .1 .1 .1 .1} $dops
#bltTest3 $bltgr element data2 -xhigh $dops
#bltTest3 $bltgr element data2 -xlow $dops
bltTest3 $bltgr element data1 -y {8 20 31 41 50 59 65 70 75 85}  $dops
bltTest3 $bltgr element data1 -ydata {8 20 31 41 50 59 65 70 75 85} $dops
bltTest3 $bltgr element data2 -yerror {5 5 5 5 5 5 5 5 5 5 5} $dops
#bltTest3 $bltgr element data2 -yhigh $dops
#bltTest3 $bltgr element data2 -ylow $dops

bltCmd $bltgr element activate data2
bltCmd $bltgr element deactivate data2
#bltCmd $bltgr element bind data1 <Button-1> [list puts "%x %y"]
bltCmd $bltgr element cget data1 -smooth
bltCmd $bltgr element configure data1
bltCmd $bltgr element configure data1 -smooth
#bltCmd $bltgr element closest 50 50
#bltCmd $bltgr element closest 50 50 data1 data2
bltCmd $bltgr element create data4
bltCmd $bltgr element create data5
bltCmd $bltgr element delete data4 data5
bltCmd $bltgr element exists data1
bltCmd $bltgr element lower data1
bltCmd $bltgr element lower data2 data3
bltCmd $bltgr element names
bltCmd $bltgr element names data1
bltCmd $bltgr element raise data2
bltCmd $bltgr element raise data2 data3
bltCmd $bltgr element raise data1
bltCmd $bltgr element show data2
bltCmd $bltgr element show {data1 data2 data3}
bltCmd $bltgr element type data1

puts stderr "done"
bltPlotDestroy $w

