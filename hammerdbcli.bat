@echo off
COLOR 07
cd /D "%~dp0"
set path=.\bin;%PATH%
CALL tclsh86t hammerdbcli %1 %2 %3 %4
exit
