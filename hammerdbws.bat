@echo off
COLOR 07
set path=.\bin;%PATH%
CALL tclsh86t hammerdbws %1 %2
exit
