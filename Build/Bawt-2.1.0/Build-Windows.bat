@echo off

rem Default values for some often used options.
set OUTROOTDIR=../BawtBuild
set TCLKIT=tclkit-win32.exe
set NUMJOBS=%NUMBER_OF_PROCESSORS%

rem First 4 parameters are mandatory.
if "%1" == "" goto ERROR
if "%2" == "" goto ERROR
if "%3" == "" goto ERROR
if "%4" == "" goto ERROR

set ARCH=%1
set COMPILER=%2
set SETUPFILE=%3
set ACTION=%4
shift
shift
shift
shift

rem If no target is given, use target "all".
if "%1"=="" goto BUILDALL

rem Loop through the rest of the parameter list for targets.
set TARGETS=
:PARAMLOOP
rem There is a trailing space in the next line. It's there for formatting.
set TARGETS=%TARGETS%%1 
shift
if not "%1"=="" goto PARAMLOOP
goto BUILD

:BUILDALL
if "%ACTION%"=="clean"    goto WARNING
if "%ACTION%"=="complete" goto WARNING

set TARGETS=all

:BUILD

set ACTION=--%ACTION%
set BAWTOPTS=--rootdir %OUTROOTDIR% ^
             --architecture %ARCH% ^
             --compiler %COMPILER% ^
             --numjobs %NUMJOBS% ^
             --url http://www.hammerdb.com/build ^
	     --finalizefile Setup\HammerDBFinalize.bawt ^
             --logviewer

rem Build all libraries as listed in Setup file.
CALL %TCLKIT% Bawt.tcl %BAWTOPTS% %ACTION% %SETUPFILE% %TARGETS%

goto EOF

:WARNING
echo Warning: This may clean or rebuild everything.
echo Use "clean all" or "complete all" to allow this operation.

:ERROR
echo.
echo Usage: %0 Architecture Compiler SetupFile Action [Target1] [TargetN]
echo   Architecture    : x86 x64
echo   Compiler        : gcc vs2008 vs2010 vs2013 vs2015 vs2017 vs2019 vs2022
echo                     gcc+vs20XX vs20XX+gcc
echo   Actions         : clean extract configure compile distribute finalize
echo                     list complete update simulate touch
echo   Default target  : all
echo   Output directory: %OUTROOTDIR%
echo.

:EOF
