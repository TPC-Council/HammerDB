@echo off
COLOR 07
set path=.\bin;%PATH%
CALL tclsh90 hammerdbcli %1 %2 %3 %4
exit
