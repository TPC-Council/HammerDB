@echo off
cd /D "%~dp0"
set path=.\bin;%PATH%
START wish86t -file .\hammerdb %1 %2
exit
