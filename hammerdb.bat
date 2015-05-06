@echo off
set path=.\bin;%PATH%
START wish86t -file .\hammerdb.tcl %1 %2
exit
