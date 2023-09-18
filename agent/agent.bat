@echo off
cd /D "%~dp0"
set path=..\.\bin;%PATH%
START tclsh86t .\agent
