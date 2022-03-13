source base.tcl

set w .line
set bltgr [bltLineGraph $w]

$bltgr legend selection set data2
$bltgr legend focus data1
$bltgr legend configure -selectrelief groove

puts stderr "Testing Legend..."

#bltTest2 $bltgr legend -activebackground $dops
#bltTest2 $bltgr legend -activeborderwidth $dops
#bltTest2 $bltgr legend -activeforeground $dops
#bltTest2 $bltgr legend -activerelief $dops
bltTest2 $bltgr legend -anchor nw $dops
bltTest2 $bltgr legend -anchor n $dops
bltTest2 $bltgr legend -anchor ne $dops
bltTest2 $bltgr legend -anchor e $dops
bltTest2 $bltgr legend -anchor se $dops
bltTest2 $bltgr legend -anchor s $dops
bltTest2 $bltgr legend -anchor sw $dops
bltTest2 $bltgr legend -anchor w $dops
bltTest2 $bltgr legend -bg pink $dops
bltTest2 $bltgr legend -background cyan $dops
bltTest2 $bltgr legend -borderwidth 20 $dops
bltTest2 $bltgr legend -bd 20 $dops
bltTest2 $bltgr legend -columns 2 $dops
#bltTest2 $bltgr legend -exportselection $dops
bltTest2 $bltgr legend -focusdashes "8 3" $dops
bltTest2 $bltgr legend -focusforeground red $dops
bltTest2 $bltgr legend -font {times 18 bold italic} $dops
bltTest2 $bltgr legend -fg yellow $dops
bltTest2 $bltgr legend -foreground purple $dops
bltTest2 $bltgr legend -hide yes $dops
bltTest2 $bltgr legend -ipadx 20 $dops
bltTest2 $bltgr legend -ipady 20 $dops
#bltTest2 $bltgr legend -nofocusselectbackground $dops
#bltTest2 $bltgr legend -nofocusselectforeground $dops
bltTest2 $bltgr legend -padx 20 $dops
bltTest2 $bltgr legend -pady 20 $dops
bltTest2 $bltgr legend -position rightmargin $dops
bltTest2 $bltgr legend -position leftmargin $dops
bltTest2 $bltgr legend -position topmargin $dops
bltTest2 $bltgr legend -position bottommargin $dops
bltTest2 $bltgr legend -position plotarea $dops
bltTest2 $bltgr legend -position xy $dops
bltTest2 $bltgr legend -x 250 $dops
bltTest2 $bltgr legend -y 100 $dops
bltTest2 $bltgr legend -raised yes $dops
bltTest2 $bltgr legend -relief flat $dops
bltTest2 $bltgr legend -relief groove $dops
bltTest2 $bltgr legend -relief raised $dops
bltTest2 $bltgr legend -relief ridge $dops
bltTest2 $bltgr legend -relief solid $dops
bltTest2 $bltgr legend -relief sunken $dops
bltTest2 $bltgr legend -rows 1 $dops
#bltTest2 $bltgr legend -selectbackground $dops
bltTest2 $bltgr legend -selectborderwidth 3 $dops
#bltTest2 $bltgr legend -selectcommand $dops
#bltTest2 $bltgr legend -selectforeground $dops
#bltTest2 $bltgr legend -selectmode $dops
bltTest2 $bltgr legend -selectrelief flat $dops
bltTest2 $bltgr legend -title "Hello World" $dops
bltTest2 $bltgr legend -titlecolor red $dops
bltTest2 $bltgr legend -titlefont {times 24 bold italic} $dops

#bltCmd $bltgr legend activate
#bltCmd $bltgr legend bind
bltCmd $bltgr legend cget -fg
bltCmd $bltgr legend configure
bltCmd $bltgr legend configure -fg
#bltCmd $bltgr legend curselection
#bltCmd $bltgr legend deactivate
bltCmd $bltgr legend focus data1
bltCmd $bltgr legend focus
#bltCmd $bltgr legend get anchor
#bltCmd $bltgr legend get current
#bltCmd $bltgr legend get first
#bltCmd $bltgr legend get last
#bltCmd $bltgr legend get end
#bltCmd $bltgr legend get next.row
#bltCmd $bltgr legend get next.column
#bltCmd $bltgr legend get previous.row
#bltCmd $bltgr legend get previous.column
#bltCmd $bltgr legend get @100,100
#bltCmd $bltgr legend get data1
bltCmd $bltgr legend selection anchor data1
bltCmd $bltgr legend selection mark data1
bltCmd $bltgr legend selection includes data2
bltCmd $bltgr legend selection present
bltCmd $bltgr legend selection set data1 data2
bltCmd $bltgr legend selection clear data1 data2
bltCmd $bltgr legend selection set data1 data2
bltCmd $bltgr legend selection toggle data1 data2
bltCmd $bltgr legend selection set data1 data2
bltCmd $bltgr legend selection clearall

puts stderr "done"
bltPlotDestroy $w

