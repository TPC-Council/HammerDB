@echo off
COLOR 07
set path=.\bin;%PATH%
CALL tclsh90 hammerdbws %1 %2
exit
